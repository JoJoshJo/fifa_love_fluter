import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/supabase/supabase_config.dart';
import '../../../shared/providers/navigation_provider.dart';
import '../data/chat_repository.dart';
import 'widgets/match_list_item.dart';
import 'widgets/conversation_view.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final ChatRepository _repo = ChatRepository(SupabaseConfig.client);

  List<Map<String, dynamic>> _matches = [];
  Map<String, dynamic>? _selectedMatch;
  Map<String, dynamic>? _myProfile;
  bool _loading = true;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _currentUserId = SupabaseConfig.client.auth.currentUser?.id ?? 'mock-user';
    _loadMatches();
    _fetchMyProfile();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Watch for a match being set from Discover screen
    final preselected = ref.read(selectedMatchProvider);
    if (preselected != null && _selectedMatch == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() => _selectedMatch = preselected);
          ref.read(selectedMatchProvider.notifier).state = null;
        }
      });
    }
  }

  Future<void> _fetchMyProfile() async {
    try {
      final uid = SupabaseConfig.client.auth.currentUser?.id;
      if (uid == null) return;
      final profile = await SupabaseConfig.client
          .from('profiles')
          .select(
              'id, name, avatar_url, nationality, interests, languages, countries_to_match')
          .eq('id', uid)
          .single();
      if (mounted) {
        setState(() => _myProfile = Map<String, dynamic>.from(profile as Map));
      }
    } catch (_) {
      // No profile yet — match reasons will be empty
    }
  }

  Future<void> _loadMatches() async {
    setState(() => _loading = true);
    try {
      final userId = _currentUserId ?? 'mock-user';
      final matches = await _repo.fetchMatches(userId);
      if (mounted) {
        setState(() {
          _matches = matches;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch selectedMatchProvider so we react when Discover sets a new match
    ref.listen<Map<String, dynamic>?>(selectedMatchProvider, (_, next) {
      if (next != null && mounted) {
        setState(() => _selectedMatch = next);
        ref.read(selectedMatchProvider.notifier).state = null;
      }
    });

    final topPad = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: const Color(0xFF080F0C),
      body: Stack(
        children: [
          // ─── View 1: Match list ───
          AnimatedOpacity(
            opacity: _selectedMatch == null ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 200),
            child: AnimatedSlide(
              offset:
                  _selectedMatch == null ? Offset.zero : const Offset(-1, 0),
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              child: Column(
                children: [
                  // Header
                  Container(
                    padding: EdgeInsets.fromLTRB(16, topPad + 12, 16, 12),
                    child: Row(
                      children: [
                        Text(
                          'CHAT',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const Spacer(),
                        if (_matches.isNotEmpty)
                          Text(
                            '${_matches.length} MATCHES',
                            style: GoogleFonts.spaceMono(
                              fontSize: 10,
                              color: Colors.white.withValues(alpha: 0.25),
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Content
                  Expanded(
                    child: _loading
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFF4CB572),
                              strokeWidth: 2,
                            ),
                          )
                        : _matches.isEmpty
                            ? _buildEmptyState()
                            : RefreshIndicator(
                                color: const Color(0xFF4CB572),
                                backgroundColor: const Color(0xFF0D1A13),
                                onRefresh: _loadMatches,
                                child: ListView.builder(
                                  physics:
                                      const AlwaysScrollableScrollPhysics(),
                                  itemCount: _matches.length,
                                  itemBuilder: (context, index) {
                                    return MatchListItem(
                                      match: _matches[index],
                                      currentUserId:
                                          _currentUserId ?? 'mock-user',
                                      onTap: () {
                                        setState(() => _selectedMatch =
                                            _matches[index]);
                                      },
                                    );
                                  },
                                ),
                              ),
                  ),
                ],
              ),
            ),
          ),

          // ─── View 2: Conversation ───
          if (_selectedMatch != null)
            AnimatedOpacity(
              opacity: _selectedMatch != null ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: AnimatedSlide(
                offset: _selectedMatch != null
                    ? Offset.zero
                    : const Offset(1, 0),
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                child: SafeArea(
                  bottom: false,
                  child: ConversationView(
                    match: _selectedMatch!,
                    currentUserId: _currentUserId ?? 'mock-user',
                    myProfile: _myProfile ?? {},
                    onBack: () {
                      setState(() => _selectedMatch = null);
                      _loadMatches(); // Refresh unread counts
                    },
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 64,
            color: const Color(0xFF4CB572).withValues(alpha: 0.30),
          ),
          const SizedBox(height: 16),
          Text(
            'No matches yet',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white.withValues(alpha: 0.50),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start swiping to find your first match',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.30),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              // Switch to Discover tab
              ref.read(currentTabProvider.notifier).state = 0;
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF135E4B),
              foregroundColor: Colors.white,
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(
              'Go to Discover',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
