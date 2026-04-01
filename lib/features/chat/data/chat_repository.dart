import 'package:supabase_flutter/supabase_flutter.dart';

class ChatRepository {
  final SupabaseClient _client;

  ChatRepository(this._client);

  // ─── Fetch all active matches with profiles + last message ───
  Future<List<Map<String, dynamic>>> fetchMatches(String userId) async {
    try {
      final matchesRaw = await _client
          .from('matches')
          .select('id, user_a, user_b, match_score, created_at, status')
          .or('user_a.eq.$userId,user_b.eq.$userId')
          .eq('status', 'active');

      final List<Map<String, dynamic>> enriched = [];

      for (final match in (matchesRaw as List)) {
        final m = Map<String, dynamic>.from(match as Map);
        final otherId =
            m['user_a'] == userId ? m['user_b'] : m['user_a'];

        // Fetch other user's profile
        try {
          final profile = await _client
              .from('profiles')
              .select(
                  'id, name, avatar_url, nationality, is_verified, interests, languages, countries_to_match')
              .eq('id', otherId)
              .single();
          m['other_user'] = Map<String, dynamic>.from(profile as Map);
        } catch (_) {
          m['other_user'] = {
            'id': otherId,
            'name': 'Unknown',
            'avatar_url': null,
            'nationality': 'Unknown',
            'is_verified': false,
            'interests': <String>[],
            'languages': <String>[],
            'countries_to_match': <String>[],
          };
        }

        // Fetch last message
        try {
          final lastMsg = await _client
              .from('messages')
              .select('content, created_at, sender_id, read_at')
              .eq('match_id', m['id'])
              .order('created_at', ascending: false)
              .limit(1)
              .maybeSingle();
          m['last_message'] =
              lastMsg != null ? Map<String, dynamic>.from(lastMsg as Map) : null;
        } catch (_) {
          m['last_message'] = null;
        }

        // Count unread messages
        try {
          final unreadRes = await _client
              .from('messages')
              .select('id')
              .eq('match_id', m['id'])
              .neq('sender_id', userId)
              .isFilter('read_at', null);
          m['unread_count'] = (unreadRes as List).length;
        } catch (_) {
          m['unread_count'] = 0;
        }

        enriched.add(m);
      }

      // Sort by last message time descending
      enriched.sort((a, b) {
        final aTime = a['last_message']?['created_at'] ?? a['created_at'];
        final bTime = b['last_message']?['created_at'] ?? b['created_at'];
        return (bTime as String).compareTo(aTime as String);
      });

      return enriched;
    } catch (e) {
      return [];
    }
  }

  // ─── Real-time message stream ───
  Stream<List<Map<String, dynamic>>> messagesStream(String matchId) {
    // Return empty stream if matchId is empty
    if (matchId.isEmpty) {
      return Stream.value([]);
    }

    try {
      return _client
          .from('messages')
          .stream(primaryKey: ['id'])
          .eq('match_id', matchId)
          .order('created_at', ascending: true)
          .map((list) =>
              list.map((e) => Map<String, dynamic>.from(e)).toList());
    } catch (_) {
      return Stream.value([]);
    }
  }

  // ─── Send a message ───
  Future<void> sendMessage({
    required String matchId,
    required String senderId,
    required String content,
  }) async {
    await _client.from('messages').insert({
      'match_id': matchId,
      'sender_id': senderId,
      'content': content.trim(),
    });
  }

  // ─── Mark messages as read ───
  Future<void> markAsRead(String matchId, String userId) async {
    try {
      await _client
          .from('messages')
          .update({'read_at': DateTime.now().toIso8601String()})
          .eq('match_id', matchId)
          .neq('sender_id', userId)
          .isFilter('read_at', null);
    } catch (_) {}
  }

  // ─── Unmatch ───
  Future<void> unmatch(String matchId) async {
    await _client
        .from('matches')
        .update({'status': 'unmatched'})
        .eq('id', matchId);
  }

  // ─── Build "why you matched" reasons ───
  List<String> getMatchReasons(
    Map<String, dynamic> otherUser,
    Map<String, dynamic> myProfile,
  ) {
    final List<String> reasons = [];

    try {
      final myCountries =
          List<String>.from(myProfile['countries_to_match'] ?? []);
      final otherNationality = otherUser['nationality'] as String? ?? '';
      if (myCountries.contains(otherNationality)) {
        reasons.add('🌍 You wanted to meet $otherNationality fans');
      }

      final myInterests =
          List<String>.from(myProfile['interests'] ?? []);
      final otherInterests =
          List<String>.from(otherUser['interests'] ?? []);
      final sharedInterests =
          myInterests.where((i) => otherInterests.contains(i)).toList();
      if (sharedInterests.isNotEmpty) {
        reasons.add('⚽ You both love ${sharedInterests.first}');
      }

      final myLangs =
          List<String>.from(myProfile['languages'] ?? []);
      final otherLangs =
          List<String>.from(otherUser['languages'] ?? []);
      final sharedLangs =
          myLangs.where((l) => otherLangs.contains(l)).toList();
      if (sharedLangs.isNotEmpty) {
        reasons.add('🗣️ You both speak ${sharedLangs.first}');
      }
    } catch (_) {}

    return reasons.take(3).toList();
  }

}
