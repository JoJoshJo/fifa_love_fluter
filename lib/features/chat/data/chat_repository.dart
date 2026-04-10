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

      if ((matchesRaw as List).isEmpty) return [];

      final List<Map<String, dynamic>> matches = 
          (matchesRaw as List).map((m) => Map<String, dynamic>.from(m as Map)).toList();
      
      final List<String> matchIds = matches.map((m) => m['id'] as String).toList();
      final List<String> otherIds = matches.map((m) {
        return m['user_a'] == userId ? m['user_b'] as String : m['user_a'] as String;
      }).toList();

      // 1. Batch fetch all other user profiles
      final profilesRaw = await _client
          .from('profiles')
          .select('id, name, avatar_url, nationality, is_verified, interests, languages, countries_to_match, last_active_at')
          .inFilter('id', otherIds);
      
      final Map<String, dynamic> profilesMap = {
        for (var p in (profilesRaw as List)) p['id']: p
      };

      // 2. Batch fetch unread counts
      // We fetch all unread messages for these matches where sender is NOT the current user
      final unreadRaw = await _client
          .from('messages')
          .select('match_id')
          .inFilter('match_id', matchIds)
          .neq('sender_id', userId)
          .isFilter('read_at', null);
      
      final Map<String, int> unreadCounts = {};
      for (var msg in (unreadRaw as List)) {
        final mid = msg['match_id'] as String;
        unreadCounts[mid] = (unreadCounts[mid] ?? 0) + 1;
      }

      // 3. Batch fetch last messages
      // This is tricky in Supabase without RPC. A common trick is to fetch the last 100 messages 
      // of the user and group them, or just fetch the latest for each in parallel (better than sequential).
      // However, we can also use a "order by created_at desc" on a view if we had one.
      // For now, we'll fetch the most recent 1 message for EACH match in parallel to avoid the N+1 blocking.
      final lastMessagesResults = await Future.wait(matchIds.map((mid) => _client
          .from('messages')
          .select('content, created_at, sender_id, read_at')
          .eq('match_id', mid)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle()));

      final Map<String, dynamic> lastMessagesMap = {};
      for (int i = 0; i < matchIds.length; i++) {
        if (lastMessagesResults[i] != null) {
          lastMessagesMap[matchIds[i]] = lastMessagesResults[i];
        }
      }

      final List<Map<String, dynamic>> enriched = [];
      for (var m in matches) {
        final otherId = m['user_a'] == userId ? m['user_b'] : m['user_a'];
        
        m['other_user'] = profilesMap[otherId] ?? {
          'id': otherId,
          'name': 'Unknown',
          'avatar_url': null,
          'nationality': 'Unknown',
          'is_verified': false,
          'interests': <String>[],
          'languages': <String>[],
          'countries_to_match': <String>[],
        };

        m['last_message'] = lastMessagesMap[m['id']];
        m['unread_count'] = unreadCounts[m['id']] ?? 0;
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
        reasons.add('You wanted to meet $otherNationality fans');
      }

      final myInterests =
          List<String>.from(myProfile['interests'] ?? []);
      final otherInterests =
          List<String>.from(otherUser['interests'] ?? []);
      final sharedInterests =
          myInterests.where((i) => otherInterests.contains(i)).toList();
      if (sharedInterests.isNotEmpty) {
        reasons.add('You both love ${sharedInterests.first}');
      }

      final myLangs =
          List<String>.from(myProfile['languages'] ?? []);
      final otherLangs =
          List<String>.from(otherUser['languages'] ?? []);
      final sharedLangs =
          myLangs.where((l) => otherLangs.contains(l)).toList();
      if (sharedLangs.isNotEmpty) {
        reasons.add('You both speak ${sharedLangs.first}');
      }
    } catch (_) {}

    return reasons.take(3).toList();
  }

}
