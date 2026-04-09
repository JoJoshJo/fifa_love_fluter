import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/supabase/supabase_config.dart';
import '../../../core/notifications/notification_service.dart';

class DiscoverRepository {
  /// Fetches profiles to display in the swipe feed.
  Future<List<Map<String, dynamic>>> fetchProfiles({
    required String userId,
    required List<String> countriesToMatch,
  }) async {
    try {
      // 1. Get ranked profiles + scores from the smart matching algorithm
      final response = await SupabaseConfig.client.rpc(
        'calculate_smart_match_score',
        params: {
          'p_user_id': userId,
          'p_limit': 40,
        },
      );

      final List<dynamic> rankedData = response as List<dynamic>;
      if (rankedData.isEmpty) return [];

      final profileIds = rankedData.map((d) => d['profile_id'] as String).toList();

      // 2. Fetch full profile details for these IDs
      final profilesResponse = await SupabaseConfig.client
          .from('profiles')
          .select('id, name, age, nationality, avatar_url, bio, interests, city, is_local, team_supported, languages, is_verified, last_active_at, created_at, countries_to_match')
          .inFilter('id', profileIds);

      final List<dynamic> rawProfiles = profilesResponse as List<dynamic>;
      
      // 3. Re-assemble with scores and sort by the rank provided by RPC
      final List<Map<String, dynamic>> finalProfiles = [];
      for (var ranked in rankedData) {
        final profile = rawProfiles.firstWhere(
          (p) => p['id'] == ranked['profile_id'],
          orElse: () => null,
        );
        
        if (profile != null) {
          final profileMap = Map<String, dynamic>.from(profile);
          profileMap['match_score'] = (ranked['score'] as num).toInt();
          
          // Apply filters (e.g. countriesToMatch) if they weren't handled by RPC
          if (countriesToMatch.isNotEmpty && !countriesToMatch.contains(profileMap['nationality'])) {
            continue;
          }
          
          finalProfiles.add(profileMap);
        }
      }

      return finalProfiles;
    } catch (e) {
      debugPrint('Error fetching profiles via smart match: $e');
      // Only use mock profiles in debug/development — never show fake data to real users
      assert(() {
        // ignore: avoid_print
        print('[DISCOVER] Using mock profiles (debug only)');
        return true;
      }());
      return const bool.fromEnvironment('dart.vm.product') ? [] : _mockProfiles();
    }
  }

  /// Records a swipe action and checks for mutual match.
  /// Returns the matched profile if a mutual like occurred, else null.
  Future<Map<String, dynamic>?> recordSwipe({
    required String swiperId,
    required String swipedId,
    required String action, // 'like', 'nope', 'superlike'
    int matchScore = 20,
  }) async {
    try {
      // 1. Insert swipe action (Trigger in DB will handle match creation)
      await SupabaseConfig.client.from('swipe_actions').insert({
        'swiper_id': swiperId,
        'swiped_id': swipedId,
        'action': action,
        'created_at': DateTime.now().toIso8601String(),
      });

      // 2. Fire and forget behavioral learning + ELO updates
      final isLike = action == 'like' || action == 'superlike';
      
      unawaited(SupabaseConfig.client.rpc('update_elo_after_swipe', params: {
        'p_swiper_id': swiperId,
        'p_swiped_id': swipedId,
        'p_action': isLike ? 'like' : 'skip',
      }).catchError((e) => debugPrint('ELO update error: $e')));

      unawaited(SupabaseConfig.client.rpc('learn_from_swipe', params: {
        'p_swiper_id': swiperId,
        'p_swiped_id': swipedId,
        'p_action': isLike ? 'like' : 'skip',
      }).catchError((e) => debugPrint('Behavioral learning error: $e')));

      // 3. Only check for match on likes
      if (action == 'nope') return null;

      // 4. Check for just-created match in the matches table
      final ids = [swiperId, swipedId]..sort();
      final match = await SupabaseConfig.client
          .from('matches')
          .select('id')
          .eq('user_a', ids[0])
          .eq('user_b', ids[1])
          .eq('status', 'active')
          .maybeSingle();

      if (match != null) {
        // Notification logic
        try {
          final matchedProfile = await SupabaseConfig.client.from('profiles').select('name').eq('id', swipedId).single();
          await NotificationService()
            .showMatchNotification(
              matchName: matchedProfile['name'],
              matchId: match['id'],
            );
        } catch (_) {}
        
        return {
          'matched': true,
          'match_id': match['id']
        };
      }
      return null;
    } catch (e) {
      debugPrint('Error recording swipe: $e');
      return null;
    }
  }

  /// Records a liked with an attached comment (Hinge-style).
  Future<Map<String, dynamic>?> recordCommentedLike({
    required String swiperId,
    required String swipedId,
    required String comment,
    int matchScore = 20,
  }) async {
    try {
      // 1. Insert swipe action with comment
      await SupabaseConfig.client.from('swipe_actions').insert({
        'swiper_id': swiperId,
        'swiped_id': swipedId,
        'action': 'like',
        'comment': comment,
        'created_at': DateTime.now().toIso8601String(),
      });

      // 2. Behavioral learning + ELO
      unawaited(SupabaseConfig.client.rpc('update_elo_after_swipe', params: {
        'p_swiper_id': swiperId,
        'p_swiped_id': swipedId,
        'p_action': 'like',
      }).catchError((e) => debugPrint('ELO update error: $e')));

      unawaited(SupabaseConfig.client.rpc('learn_from_swipe', params: {
        'p_swiper_id': swiperId,
        'p_swiped_id': swipedId,
        'p_action': 'like',
      }).catchError((e) => debugPrint('Behavioral learning error: $e')));

      // 3. Check for match
      final ids = [swiperId, swipedId]..sort();
      final match = await SupabaseConfig.client
          .from('matches')
          .select('id')
          .eq('user_a', ids[0])
          .eq('user_b', ids[1])
          .eq('status', 'active')
          .maybeSingle();

      if (match != null) {
        return {
          'matched': true,
          'match_id': match['id']
        };
      }
      return null;
    } catch (e) {
      debugPrint('Error recording commented like: $e');
      return null;
    }
  }

  /// Undoes the last swipe.
  Future<void> undoSwipe({
    required String swiperId,
    required String swipedId,
  }) async {
    await SupabaseConfig.client
        .from('swipe_actions')
        .delete()
        .eq('swiper_id', swiperId)
        .eq('swiped_id', swipedId);
  }

  /// Returns mock profiles for testing without a live DB.
  List<Map<String, dynamic>> _mockProfiles() {
    return [
      {
        'id': 'mock-1',
        'name': 'Camila',
        'age': 26,
        'nationality': 'Brazil',
        'avatar_url': 'https://images.unsplash.com/photo-1531746020798-e6953c6e8e04?w=400&h=500&fit=crop&crop=face',
        'bio': 'Massive Seleção fan! Living for the World Cup.',
        'interests': ['Football', 'Samba', 'Beach', 'Travel'],
        'city': 'Rio de Janeiro',
        'is_local': false,
        'team_supported': 'Brazil',
        'is_verified': true,
        'match_score': 87,
        'last_active_at': DateTime.now().toIso8601String(),
        'created_at': DateTime.now().subtract(const Duration(days: 2)).toIso8601String(),
      },
      {
        'id': 'mock-2',
        'name': 'Sofia',
        'age': 28,
        'nationality': 'Portugal',
        'avatar_url': 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=400&h=500&fit=crop&crop=face',
        'bio': 'Porto girl exploring LA for the Cup. Big Benfica fan!',
        'interests': ['Football', 'Culture', 'Foodie', 'Travel'],
        'city': 'Los Angeles',
        'is_local': false,
        'team_supported': 'Portugal',
        'is_verified': true,
        'match_score': 74,
        'last_active_at': DateTime.now().toIso8601String(),
        'created_at': DateTime.now().subtract(const Duration(days: 10)).toIso8601String(),
      },
      {
        'id': 'mock-3',
        'name': 'Marcus',
        'age': 24,
        'nationality': 'Nigeria',
        'avatar_url': 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=400&h=500&fit=crop&crop=face',
        'bio': 'Super Eagles supporter. Atlanta based.',
        'interests': ['Football', 'Afrobeats', 'Fashion', 'Art'],
        'city': 'Atlanta',
        'is_local': false,
        'team_supported': 'Nigeria',
        'is_verified': true,
        'match_score': 62,
        'last_active_at': DateTime.now().toIso8601String(),
        'created_at': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
      },
      {
        'id': 'mock-4',
        'name': 'Yuki',
        'age': 25,
        'nationality': 'Japan',
        'avatar_url': 'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=400&h=500&fit=crop&crop=face',
        'bio': 'Samurai Blue until I die. Food and photography.',
        'interests': ['Football', 'Photography', 'Art', 'Foodie'],
        'city': 'Miami',
        'is_local': false,
        'team_supported': 'Japan',
        'is_verified': false,
        'match_score': 55,
        'last_active_at': DateTime.now().toIso8601String(),
        'created_at': DateTime.now().subtract(const Duration(days: 15)).toIso8601String(),
      },
      {
        'id': 'mock-5',
        'name': 'Antoine',
        'age': 29,
        'nationality': 'France',
        'avatar_url': 'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=400&h=500&fit=crop&crop=face',
        'bio': 'Parisien in New York for Les Bleus. Football is art.',
        'interests': ['Football', 'Art', 'History', 'Foodie'],
        'city': 'New York',
        'is_local': false,
        'team_supported': 'France',
        'is_verified': true,
        'match_score': 91,
        'last_active_at': DateTime.now().toIso8601String(),
        'created_at': DateTime.now().subtract(const Duration(days: 4)).toIso8601String(),
      },
    ];
  }
}
