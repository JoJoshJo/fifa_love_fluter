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

    final topPad = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
                    padding: EdgeInsets.fromLTRB(16, topPad + 20, 16, 0),
                    width: double.infinity,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'YOUR CONNECTIONS',
                          style: GoogleFonts.spaceMono(
                            fontSize: 10,
                            letterSpacing: 2,
                            color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            RichText(
                              text: TextSpan(
                                text: '${_matches.length} MATCHES',
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).textTheme.bodyLarge?.color,
                                ),
                                children: [
                                  TextSpan(
                                    text: ' .',
                                    style: GoogleFonts.spaceGrotesk(
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context).primaryColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Spacer(),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Start a conversation',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.35),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Content
                  Expanded(
                    child: _loading
                        ? Center(
                            child: CircularProgressIndicator(
                              color: Theme.of(context).primaryColor,
                              strokeWidth: 2,
                            ),
                          )
                        : _matches.isEmpty
                            ? _buildEmptyState(context)
                            : RefreshIndicator(
                                color: Theme.of(context).primaryColor,
                                backgroundColor: Theme.of(context).cardColor,
                                onRefresh: _loadMatches,
                                child: ListView(
                                  padding: EdgeInsets.zero,
                                  physics: const AlwaysScrollableScrollPhysics(),
                                  children: [
                                    const SizedBox(height: 20),
                                    SizedBox(
                                      height: 100,
                                      child: ListView(
                                        scrollDirection: Axis.horizontal,
                                        padding: const EdgeInsets.symmetric(horizontal: 16),
                                        children: [
                                          ..._matches.take(3).map((match) {
                                            final other = match['other_user'] as Map<String, dynamic>;
                                            final avatarUrl = other['avatar_url'] as String?;
                                            final name = other['name'] as String? ?? 'Unknown';
                                            return Container(
                                              margin: const EdgeInsets.only(right: 12),
                                              width: 80,
                                              height: 100,
                                              decoration: BoxDecoration(
                                                borderRadius: BorderRadius.circular(16),
                                              ),
                                              child: ClipRRect(
                                                borderRadius: BorderRadius.circular(16),
                                                child: Stack(
                                                  fit: StackFit.expand,
                                                  children: [
                                                    if (avatarUrl != null)
                                                      CachedNetworkImage(
                                                        imageUrl: avatarUrl,
                                                        fit: BoxFit.cover,
                                                      )
                                                    else
                                                      Container(color: Theme.of(context).cardColor),
                                                    Positioned(
                                                      bottom: 0,
                                                      left: 0,
                                                      right: 0,
                                                      child: Container(
                                                        padding: const EdgeInsets.fromLTRB(6, 4, 6, 6),
                                                        decoration: BoxDecoration(
                                                          gradient: LinearGradient(
                                                            begin: Alignment.bottomCenter,
                                                            end: Alignment.topCenter,
                                                            colors: [
                                                              Theme.of(context).brightness == Brightness.light
                                                                ? Colors.black.withValues(alpha: 0.2)
                                                                : Colors.black.withValues(alpha: 0.8),
                                                              Colors.transparent,
                                                            ],
                                                          ),
                                                        ),
                                                        child: Text(
                                                          name.split(' ').first,
                                                          style: GoogleFonts.inter(
                                                            fontSize: 11,
                                                            fontWeight: FontWeight.w600,
                                                            color: Colors.white,
                                                          ),
                                                          maxLines: 1,
                                                          overflow: TextOverflow.ellipsis,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            );
                                          }),
                                          Container(
                                            margin: const EdgeInsets.only(right: 12),
                                            width: 80,
                                            height: 100,
                                            decoration: BoxDecoration(
                                              color: Theme.of(context).dividerColor.withValues(alpha: 0.05),
                                              borderRadius: BorderRadius.circular(16),
                                              border: Border.all(
                                                color: Theme.of(context).primaryColor.withValues(alpha: 0.3),
                                                width: 1,
                                              ),
                                            ),
                                            child: Center(
                                              child: Icon(Icons.add, size: 24, color: Theme.of(context).primaryColor),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Container(
                                      margin: const EdgeInsets.symmetric(horizontal: 16),
                                      height: 1,
                                      color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
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
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 60),
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(40),
            ),
            child: Center(
              child: Icon(
                Icons.chat_bubble_outline,
                size: 36,
                color: Theme.of(context).primaryColor.withValues(alpha: 0.4),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'No matches yet',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).textTheme.titleLarge?.color?.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start swiping to find\nyour first match',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.3),
            ),
          ),
          const SizedBox(height: 28),
          GestureDetector(
            onTap: () {
              ref.read(currentTabProvider.notifier).state = 0;
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  color: Theme.of(context).primaryColor,
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).primaryColor,
                      Theme.of(context).primaryColor.withValues(alpha: 0.8),
                    ],
                  ),
                ),
                child: Text(
                  'Go to Discover',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
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
