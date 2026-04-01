import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
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
    _currentUserId = SupabaseConfig.client.auth.currentUser?.id;
    if (_currentUserId == null) return;
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
      final userId = _currentUserId ?? '';
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

    final isLight = Theme.of(context).brightness == Brightness.light;
    final backgroundColor = isLight
        ? const Color(0xFFF5F0E8)
        : const Color(0xFF080F0C);

    return Scaffold(
      backgroundColor: backgroundColor,
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
                  // HEADER — No AppBar. Custom header.
                  Container(
                    padding: EdgeInsets.only(
                      top: MediaQuery.of(context).padding.top + 16,
                      left: 24,
                      right: 24,
                      bottom: 16,
                    ),
                    color: isLight
                        ? const Color(0xFFF5F0E8)
                        : const Color(0xFF080F0C),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'YOUR CONNECTIONS',
                          style: GoogleFonts.spaceMono(
                            fontSize: 9,
                            color: const Color(0xFF4CB572),
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${_matches.length} Matches.',
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 32,
                            fontWeight: FontWeight.w700,
                            fontStyle: FontStyle.italic,
                            color: isLight ? Colors.black : Colors.white,
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
                            ? _buildEmptyState(context)
                            : RefreshIndicator(
                                color: const Color(0xFF135E4B),
                                backgroundColor: isLight ? Colors.white : const Color(0xFF080F0C),
                                onRefresh: _loadMatches,
                                child: ListView(
                                  padding: EdgeInsets.zero,
                                  physics: const BouncingScrollPhysics(
                                    parent: AlwaysScrollableScrollPhysics()),
                                  children: [
                                    const SizedBox(height: 12),
                                    
                                    // PHOTO STRIP
                                    SizedBox(
                                      height: 125,
                                      child: ListView.builder(
                                        scrollDirection: Axis.horizontal,
                                        padding: const EdgeInsets.symmetric(horizontal: 24),
                                        itemCount: _matches.length + 1,
                                        itemBuilder: (context, index) {
                                          if (index == 0) {
                                            // Add placeholder
                                            return Container(
                                              width: 68,
                                              margin: const EdgeInsets.only(right: 18),
                                              child: Column(
                                                children: [
                                                  Container(
                                                    width: 68, height: 84,
                                                    decoration: BoxDecoration(
                                                      borderRadius: BorderRadius.circular(12),
                                                      border: Border.all(
                                                        color: isLight 
                                                          ? const Color(0xFFD4EBE0)
                                                          : Colors.white10,
                                                        width: 1,
                                                      ),
                                                      color: isLight 
                                                        ? Colors.white 
                                                        : Colors.white.withValues(alpha: 0.05),
                                                    ),
                                                    child: Center(
                                                      child: Icon(
                                                        Icons.add_rounded,
                                                        color: const Color(0xFF4CB572)
                                                          .withValues(alpha: 0.6),
                                                        size: 28)),
                                                  ),
                                                  const SizedBox(height: 8),
                                                  Text('NEW',
                                                    style: GoogleFonts.spaceMono(
                                                      fontSize: 10,
                                                      fontWeight: FontWeight.bold,
                                                      color: const Color(0xFF4CB572))),
                                                ],
                                              ),
                                            );
                                          }

                                          final match = _matches[index - 1];
                                          final other = match['other_user'] as Map<String, dynamic>;
                                          final avatarUrl = other['avatar_url'] as String?;
                                          final name = other['name'] as String? ?? 'Match';

                                          return GestureDetector(
                                            onTap: () => setState(() => _selectedMatch = match),
                                            child: Container(
                                              width: 68,
                                              margin: const EdgeInsets.only(right: 18),
                                              child: Column(
                                                children: [
                                                  Container(
                                                    width: 68, height: 84,
                                                    decoration: BoxDecoration(
                                                      borderRadius: BorderRadius.circular(12),
                                                      border: Border.all(
                                                        color: isLight 
                                                          ? const Color(0xFFE5E0D8)
                                                          : Colors.white10,
                                                        width: 1,
                                                      ),
                                                      image: avatarUrl != null
                                                          ? DecorationImage(
                                                              image: CachedNetworkImageProvider(avatarUrl),
                                                              fit: BoxFit.cover,
                                                            )
                                                          : null,
                                                      color: isLight 
                                                        ? Colors.white 
                                                        : Colors.white12,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 8),
                                                  Text(
                                                    name.split(' ').first.toUpperCase(),
                                                    style: GoogleFonts.spaceMono(
                                                      fontSize: 10,
                                                      fontWeight: FontWeight.w600,
                                                      color: isLight ? const Color(0xFF333333) : Colors.white70,
                                                      letterSpacing: 0.5,
                                                    ),
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),

                                    const SizedBox(height: 12),

                                    // MESSAGES LABEL
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                      child: Row(
                                        children: [
                                          Text('MESSAGES',
                                            style: GoogleFonts.spaceMono(
                                              fontSize: 9,
                                              color: const Color(0xFF9BB3AF),
                                              letterSpacing: 1.5)),
                                          const Spacer(),
                                          Text('FILTER',
                                            style: GoogleFonts.spaceMono(
                                              fontSize: 9,
                                              color: const Color(0xFF4CB572),
                                              fontWeight: FontWeight.bold)),
                                        ],
                                      ),
                                    ),

                                    ListView.builder(
                                      padding: EdgeInsets.zero,
                                      physics: const NeverScrollableScrollPhysics(),
                                      shrinkWrap: true,
                                      itemCount: _matches.length,
                                      itemBuilder: (context, index) {
                                        return MatchListItem(
                                          match: _matches[index],
                                          currentUserId:
                                              _currentUserId ?? '',
                                          onTap: () {
                                            final match = _matches[index];
                                            if (match['id'] == null) {
                                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                                                content: Text('Match ID missing'),
                                                backgroundColor: Color(0xFFE83535),
                                              ));
                                              return;
                                            }
                                            setState(() => _selectedMatch = match);
                                          },
                                        );
                                      },
                                    ),
                                    const SizedBox(height: 100),
                                  ],
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
                    currentUserId: _currentUserId ?? '',
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

  Widget _buildEmptyState(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 40),
          Text(
            'YOU HAVEN\'T CONNECTED YET',
            style: GoogleFonts.spaceMono(
              fontSize: 10,
              color: const Color(0xFF4CB572),
              letterSpacing: 1.5,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Find your match\nthis World Cup.',
            textAlign: TextAlign.center,
            style: GoogleFonts.playfairDisplay(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              color: isLight ? const Color(0xFF0D2B1E) : Colors.white,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 32),
          GestureDetector(
            onTap: () {
              // Navigate to Discover or perform action
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF135E4B),
                    Color(0xFF4CB572),
                  ],
                ),
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF135E4B).withValues(alpha: 0.2),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Text(
                'Go to Discover',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
