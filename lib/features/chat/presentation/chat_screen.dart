import 'package:lucide_icons/lucide_icons.dart';
import '../../../shared/widgets/gradient_button.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/supabase/supabase_config.dart';
import '../../../shared/providers/navigation_provider.dart';
import '../data/chat_repository.dart';
import 'widgets/match_list_item.dart';
import 'widgets/conversation_view.dart';
import '../../../core/utils/url_helper.dart';

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
                        RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: '${_matches.length} ',
                                style: GoogleFonts.inter(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w700,
                                  color: isLight ? Colors.black : Colors.white,
                                ),
                              ),
                              TextSpan(
                                text: 'Matches.',
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
                                                      border: isLight 
                                                          ? Border.all(
                                                              color: const Color(0xFFD4EBE0),
                                                              width: 1,
                                                            )
                                                          : null,
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
                                                      border: isLight 
                                                          ? Border.all(
                                                              color: const Color(0xFFE5E0D8),
                                                              width: 1,
                                                            )
                                                          : null,
                                                      image: avatarUrl != null && avatarUrl.isNotEmpty
                                                          ? DecorationImage(
                                                              image: CachedNetworkImageProvider(
                                                                UrlHelper.resolveImageUrl(avatarUrl),
                                                              ),
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
                                                    name.split(' ').first,
                                                    style: GoogleFonts.playfairDisplay(
                                                      fontSize: 12,
                                                      fontWeight: FontWeight.w500,
                                                      fontStyle: FontStyle.italic,
                                                      color: isLight ? FifaColors.textPrimaryLight : Colors.white70,
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
          Icon(
            LucideIcons.messageSquare,
            size: 56,
            color: const Color(0xFF9BB3AF).withValues(alpha: 0.5),
          ),
          const SizedBox(height: 24),
          Text(
            'YOU HAVEN\'T CONNECTED YET',
            style: GoogleFonts.spaceMono(
              fontSize: 10,
              color: const Color(0xFF4CB572),
              letterSpacing: 1.5,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          // Decorative dots
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(width: 4, height: 4, decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFFF48C4))),
              const SizedBox(width: 8),
              Container(width: 4, height: 4, decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFF2C233))),
              const SizedBox(width: 8),
              Container(width: 4, height: 4, decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF4CB572))),
            ],
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
          Padding(
            padding: const EdgeInsets.fromLTRB(40, 0, 40, 20),
            child: GradientButton(
              text: 'Go to Discover',
              height: 52, // radius 26
              colors: const [Color(0xFF004B3A), Color(0xFF4CB572)],
              onPressed: () {
                ref.read(currentTabProvider.notifier).state = 0;
              },
            ),
          ),
        ],
      ),
    );
  }
}
