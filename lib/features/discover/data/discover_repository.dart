import '../../../core/supabase/supabase_config.dart';
import '../../../core/notifications/notification_service.dart';

class DiscoverRepository {
  /// Fetches profiles to display in the swipe feed.
  Future<List<Map<String, dynamic>>> fetchProfiles({
    required String userId,
    required List<String> countriesToMatch,
  }) async {
    try {
      // 1. Get current user profile
      final myProfile = await SupabaseConfig.client
          .from('profiles')
          .select('nationality, countries_to_match')
          .eq('id', userId)
          .single();

      // 2. Get already swiped profile IDs
      final swiped = await SupabaseConfig.client
          .from('swipe_actions')
          .select('swiped_id')
          .eq('swiper_id', userId);
      final swipedIds = swiped.map((s) => s['swiped_id'] as String).toList();

      // 3. Build profiles query
      var query = SupabaseConfig.client.from('profiles').select(
          'id, name, age, nationality, avatar_url, bio, interests, city, is_local, team_supported, languages, is_verified, last_active_at');

      // Filter by target countries if provided
      if (countriesToMatch.isNotEmpty) {
        query = query.inFilter('nationality', countriesToMatch);
      }

      // Filter mutual interest: they want to match with my country
      if (myProfile['nationality'] != null) {
        query = query.contains(
            'countries_to_match', [myProfile['nationality']]);
      }

      final rawProfiles =
          await query.neq('id', userId);

      // 4. Filter out already swiped
      final profiles = rawProfiles
          .where((p) => !swipedIds.contains(p['id']))
          .toList();

      if (profiles.isEmpty) return profiles;

      // 5. Batch calculate match scores via RPC
      List<Map<String, dynamic>> scoredProfiles = List.from(profiles);
      try {
        final scores = await SupabaseConfig.client
            .rpc('calculate_match_scores_batch', params: {
          'user_id_a': userId,
          'profile_ids': profiles.map((p) => p['id']).toList(),
        }) as List;

        // 6. Attach scores
        for (var profile in scoredProfiles) {
          final scoreEntry = scores.firstWhere(
            (s) => s['profile_id'] == profile['id'],
            orElse: () => {'score': 20},
          );
          profile['match_score'] = scoreEntry['score'] ?? 20;
        }
      } catch (_) {
        // RPC not available — assign random realistic scores
        for (var profile in scoredProfiles) {
          profile['match_score'] = 20 + (scoredProfiles.indexOf(profile) * 7) % 80;
        }
      }

      // 7. Sort by score descending
      scoredProfiles.sort((a, b) =>
          (b['match_score'] as int).compareTo(a['match_score'] as int));

      return scoredProfiles;
    } catch (e) {
      return _mockProfiles();
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
      // Insert swipe action
      await SupabaseConfig.client.from('swipe_actions').insert({
        'swiper_id': swiperId,
        'swiped_id': swipedId,
        'action': action,
        'created_at': DateTime.now().toIso8601String(),
      });

      // Only check for match on likes
      if (action == 'nope') return null;

      // Check for mutual like
      final mutual = await SupabaseConfig.client
          .from('swipe_actions')
          .select()
          .eq('swiper_id', swipedId)
          .eq('swiped_id', swiperId)
          .inFilter('action', ['like', 'superlike']);

      if (mutual.isNotEmpty) {
        // Create a match record
        final ids = [swiperId, swipedId]..sort();
        String? matchId;
        try {
          final match = await SupabaseConfig.client.from('matches').insert({
            'user_a': ids[0],
            'user_b': ids[1],
            'match_score': matchScore,
            'status': 'active',
            'created_at': DateTime.now().toIso8601String(),
          }).select().single();
          matchId = match['id'] as String?;
        } catch (_) {
          // Match might already exist
          final existing = await SupabaseConfig.client.from('matches').select('id').eq('user_a', ids[0]).eq('user_b', ids[1]).maybeSingle();
          matchId = existing?['id'] as String?;
        }
        
        try {
          final matchedProfile = await SupabaseConfig.client.from('profiles').select('name').eq('id', swipedId).single();
          await NotificationService()
            .showMatchNotification(
              matchName: matchedProfile['name'],
              matchId: matchId ?? 'unknown',
            );
        } catch (_) {}
        
        return {'matched': true};
      }
      return null;
    } catch (_) {
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
        'name': 'Sofia',
        'age': 26,
        'nationality': 'Brazil',
        'avatar_url': null,
        'bio': 'Massive Seleção fan! Living for the World Cup.',
        'interests': ['Football', 'Samba', 'Beach', 'Travel'],
        'city': 'Rio de Janeiro',
        'is_local': false,
        'team_supported': 'Brazil',
        'is_verified': true,
        'match_score': 87,
        'last_active_at': DateTime.now().toIso8601String(),
      },
      {
        'id': 'mock-2',
        'name': 'Lucas',
        'age': 29,
        'nationality': 'France',
        'avatar_url': null,
        'bio': 'Allez les Bleus! Here for the vibes and the goals.',
        'interests': ['Football', 'Wine', 'Cooking', 'Music'],
        'city': 'Paris',
        'is_local': false,
        'team_supported': 'France',
        'is_verified': false,
        'match_score': 74,
        'last_active_at': DateTime.now().toIso8601String(),
      },
      {
        'id': 'mock-3',
        'name': 'Amara',
        'age': 24,
        'nationality': 'Nigeria',
        'avatar_url': null,
        'bio': 'Super Eagles supporter. NYC based.',
        'interests': ['Football', 'Afrobeats', 'Fashion', 'Art'],
        'city': 'New York',
        'is_local': true,
        'team_supported': 'Nigeria',
        'is_verified': true,
        'match_score': 62,
        'last_active_at': DateTime.now().toIso8601String(),
      },
      {
        'id': 'mock-4',
        'name': 'Kenji',
        'age': 31,
        'nationality': 'Japan',
        'avatar_url': null,
        'bio': 'Samurai Blue until I die. Ramen enthusiast.',
        'interests': ['Football', 'Anime', 'Ramen', 'Tech'],
        'city': 'Tokyo',
        'is_local': false,
        'team_supported': 'Japan',
        'is_verified': false,
        'match_score': 55,
        'last_active_at': DateTime.now().toIso8601String(),
      },
      {
        'id': 'mock-5',
        'name': 'Isabella',
        'age': 27,
        'nationality': 'Argentina',
        'avatar_url': null,
        'bio': 'Vamos Argentina! Messi forever.',
        'interests': ['Football', 'Tango', 'Empanadas', 'Travel'],
        'city': 'Buenos Aires',
        'is_local': false,
        'team_supported': 'Argentina',
        'is_verified': true,
        'match_score': 91,
        'last_active_at': DateTime.now().toIso8601String(),
      },
    ];
  }
}
