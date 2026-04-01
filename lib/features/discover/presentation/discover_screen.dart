import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fifalove_mobile/core/constants/colors.dart';
import '../../../core/supabase/supabase_config.dart';
import '../../../shared/providers/navigation_provider.dart';
import '../data/discover_repository.dart';
import 'widgets/swipe_card.dart';
import 'widgets/match_overlay.dart';
import 'widgets/country_filter_sheet.dart';
import '../../../core/notifications/notification_service.dart';
import '../../../core/widgets/shimmer_card.dart';

class DiscoverScreen extends ConsumerStatefulWidget {
  const DiscoverScreen({super.key});

  @override
  ConsumerState<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends ConsumerState<DiscoverScreen> {
  final _repo = DiscoverRepository();
  final _swiperController = CardSwiperController();

  List<Map<String, dynamic>> _profiles = [];
  int _currentIndex = 0;
  bool _loading = true;
  bool _showMatch = false;
  Map<String, dynamic>? _matchedProfile;
  String? _myAvatarUrl;
  List<String> _selectedCountries = [];
  int _dailySwipes = 0;

  static const int _freeLimit = 20;
  static const int _hardLimit = 25;

  String get _swipePrefsKey =>
      'swipes_${DateTime.now().toIso8601String().substring(0, 10)}';

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _swiperController.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    _dailySwipes = prefs.getInt(_swipePrefsKey) ?? 0;

    final raw = prefs.getStringList('selected_countries');
    if (raw != null) _selectedCountries = raw;

    await _fetchMyAvatar();
    await _loadProfiles();
  }

  Future<void> _fetchMyAvatar() async {
    final user = SupabaseConfig.client.auth.currentUser;
    if (user == null) return;
    try {
      final profile = await SupabaseConfig.client
          .from('profiles')
          .select('avatar_url')
          .eq('id', user.id)
          .single();
      if (mounted) {
        setState(() => _myAvatarUrl = profile['avatar_url'] as String?);
      }
    } catch (_) {}
  }

  Future<void> _loadProfiles() async {
    if (!mounted) return;
    setState(() => _loading = true);

    final user = SupabaseConfig.client.auth.currentUser;
    if (user?.id == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    final userId = user!.id;

    final profiles = await _repo.fetchProfiles(
      userId: userId,
      countriesToMatch: _selectedCountries,
    );

    if (mounted) {
      setState(() {
        _profiles = profiles;
        _currentIndex = 0;
        _loading = false;
      });
    }
  }

  Future<void> _handleSwipe(String action, Map<String, dynamic> profile) async {
    if (_dailySwipes >= _hardLimit) {
      _showPremiumSheet();
      return;
    }

    _dailySwipes++;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_swipePrefsKey, _dailySwipes);

    final user = SupabaseConfig.client.auth.currentUser;
    final swiperId = user?.id;
    if (swiperId == null) return;
    final swipedId = profile['id'] as String;

    final result = await _repo.recordSwipe(
      swiperId: swiperId,
      swipedId: swipedId,
      action: action,
      matchScore: (profile['match_score'] as int?) ?? 20,
    );

    if (!mounted) return;

    if (result != null) {
      setState(() {
        _matchedProfile = profile;
        _showMatch = true;
      });
    }

    setState(() => _currentIndex++);

    if (_currentIndex >= _profiles.length - 3) {
      _loadProfiles();
    }
  }

  void _showPremiumSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.star, size: 48, color: Color(0xFFF2C233)),
            const SizedBox(height: 16),
            Text(
              'Daily limit reached',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).textTheme.titleLarge?.color,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Upgrade to FIFA LOVE Premium for unlimited swipes.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text(
                  'GO PREMIUM',
                  style: GoogleFonts.spaceGrotesk(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    letterSpacing: 2,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCountryFilter() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CountryFilterSheet(
        selected: _selectedCountries,
        onApply: (countries) async {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setStringList('selected_countries', countries);
          setState(() => _selectedCountries = countries);
          _loadProfiles();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final remaining = _profiles.length - _currentIndex;
    final isLight = Theme.of(context).brightness == Brightness.light;
    return Scaffold(
      backgroundColor: isLight
          ? const Color(0xFFF5F0E8)
          : const Color(0xFF080F0C),
      body: Stack(
        children: [
          Column(
            children: [
              // DISCOVER SCREEN HEADER
              Container(
                padding: EdgeInsets.only(
                    top: MediaQuery.of(context).padding.top + 12,
                    left: 24,
                    right: 24,
                    bottom: 12),
                color: isLight
                    ? const Color(0xFFF5F0E8)
                    : const Color(0xFF080F0C),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Left — screen label
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'CURATED FOR YOU',
                          style: GoogleFonts.spaceMono(
                            fontSize: 9,
                            color: const Color(0xFF4CB572),
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Discover',
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                            color: isLight
                                ? const Color(0xFF0D2B1E)
                                : Colors.white,
                            height: 1.1,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    // Right — country filter pill
                    GestureDetector(
                      onTap: _showCountryFilter,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          color: isLight
                              ? Colors.white
                              : const Color(0xFF152B1E),
                          border: Border.all(
                            color: isLight
                                ? const Color(0xFFD4EBE0)
                                : const Color(0xFF1E4A33),
                          ),
                          boxShadow: isLight
                              ? [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.06),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  )
                                ]
                              : null,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('🌍', style: TextStyle(fontSize: 14)),
                            const SizedBox(width: 6),
                            Text(
                              _selectedCountries.isEmpty
                                  ? 'ALL'
                                  : '${_selectedCountries.length}',
                              style: GoogleFonts.spaceMono(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF135E4B),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

                if (_dailySwipes >= _freeLimit && _dailySwipes < _hardLimit)
                  Container(
                    margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: FifaColors.gold.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: FifaColors.gold.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.star,
                            size: 16, color: FifaColors.gold),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            "You've used your free swipes today",
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: _showPremiumSheet,
                          child: Text(
                            'Go Premium',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: FifaColors.gold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                Expanded(
                  child: _loading
                      ? _buildShimmer()
                      : remaining <= 0
                          ? _buildEmptyState()
                          : Center(
                              child: SizedBox(
                                height: MediaQuery.of(context).size.height * 0.68,
                                width: MediaQuery.of(context).size.width - 32,
                                  child: CardSwiper(
                                    controller: _swiperController,
                                    cardsCount: min(3, remaining),
                                    numberOfCardsDisplayed: 2,
                                    backCardOffset: const Offset(0, -16),
                                    scale: 0.95,
                                    isLoop: false,
                                    duration: const Duration(milliseconds: 200),
                                    padding: EdgeInsets.zero,
                                  onSwipe: (prevIndex, currentIndex, direction) {
                                    String action = 'nope';
                                    if (direction ==
                                        CardSwiperDirection.right) {
                                      action = 'like';
                                    } else if (direction ==
                                        CardSwiperDirection.top) {
                                      action = 'superlike';
                                    }
                                    _handleSwipe(
                                        action, _profiles[_currentIndex + prevIndex]);
                                    return true;
                                  },
                                  cardBuilder: (context, index,
                                      percentThresholdX, percentThresholdY) {
                                    final profileIndex = _currentIndex + index;
                                    if (profileIndex >= _profiles.length) {
                                      return const SizedBox.shrink();
                                    }
                                    return SwipeCard(
                                      profile: _profiles[profileIndex],
                                      isFront: index == 0,
                                      stackPosition: index,
                                      dragOffset:
                                          index == 0 ? percentThresholdX / 100 : 0,
                                      dragVertical:
                                          index == 0 ? percentThresholdY / 100 : 0,
                                    );
                                  },
                                ),
                              ),
                            ),
                ),

                if (!_loading && remaining > 0) ...[
                  // ACTION BUTTONS BELOW CARD
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                    child: Row(
                      children: [
                        // SKIP
                        Expanded(
                          child: GestureDetector(
                            onTap: () => _swiperController.swipe(CardSwiperDirection.left),
                            child: Container(
                              height: 58,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(29),
                                color: isLight
                                    ? Colors.white
                                    : const Color(0xFF0D1A13),
                                border: Border.all(
                                  color: isLight
                                      ? const Color(0xFFD4EBE0)
                                      : const Color(0xFF1E4A33),
                                  width: 1.5,
                                ),
                                boxShadow: isLight
                                    ? [
                                        BoxShadow(
                                          color: Colors.black
                                              .withValues(alpha: 0.06),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        )
                                      ]
                                    : null,
                              ),
                              child: Center(
                                child: Icon(
                                  Icons.close_rounded,
                                  size: 28,
                                  color: isLight
                                      ? const Color(0xFFADB5BD)
                                      : Colors.white.withValues(alpha: 0.3),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // SUPER LIKE — smaller center
                        GestureDetector(
                          onTap: () => _swiperController.swipe(CardSwiperDirection.top),
                          child: Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isLight
                                  ? Colors.white
                                  : const Color(0xFF0D1A13),
                              border: Border.all(
                                color: const Color(0xFFF2C233)
                                    .withValues(alpha: 0.6),
                                width: 1.5,
                              ),
                              boxShadow: isLight
                                  ? [
                                      BoxShadow(
                                        color: Colors.black
                                            .withValues(alpha: 0.06),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      )
                                    ]
                                  : null,
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.star_outline_rounded,
                                size: 24,
                                color: Color(0xFFF2C233),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // LIKE
                        Expanded(
                          child: GestureDetector(
                            onTap: () => _swiperController.swipe(CardSwiperDirection.right),
                            child: Container(
                              height: 58,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(29),
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF135E4B),
                                    Color(0xFF1E7A5A),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF135E4B)
                                        .withValues(alpha: 0.4),
                                    blurRadius: 16,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.favorite_rounded,
                                  size: 28,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ACTIVE USER BADGES BELOW BUTTONS
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: isLight
                                ? Colors.white
                                : const Color(0xFF0D1A13),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isLight
                                  ? const Color(0xFFD4EBE0)
                                  : const Color(0xFF1E4A33),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 7,
                                height: 7,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF4CB572),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'ACTIVE NOW',
                                style: GoogleFonts.spaceMono(
                                  fontSize: 9,
                                  color: const Color(0xFF4CB572),
                                  letterSpacing: 1,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: isLight
                                ? Colors.white
                                : const Color(0xFF0D1A13),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isLight
                                  ? const Color(0xFFD4EBE0)
                                  : const Color(0xFF1E4A33),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.verified,
                                  size: 12, color: Color(0xFF4CB572)),
                              const SizedBox(width: 6),
                              Text(
                                'ID VERIFIED',
                                style: GoogleFonts.spaceMono(
                                  fontSize: 9,
                                  color: const Color(0xFF4CB572),
                                  letterSpacing: 1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),

          // ── Match overlay layer ──────────────────────────────
          if (_showMatch && _matchedProfile != null)
            MatchOverlay(
              matchedProfile: _matchedProfile!,
              myAvatarUrl: _myAvatarUrl,
              onMessage: () async {
                await NotificationService().requestPermissions();
                // Pre-select the conversation and switch to Chat tab
                ref.read(selectedMatchProvider.notifier).state = {
                  'id': 'new-match-${_matchedProfile!['id']}',
                  'user_a': SupabaseConfig.client.auth.currentUser?.id ?? 'me',
                  'user_b': _matchedProfile!['id'],
                  'created_at': DateTime.now().toIso8601String(),
                  'status': 'active',
                  'match_score': _matchedProfile!['match_score'] ?? 80,
                  'other_user': _matchedProfile,
                  'last_message': null,
                  'unread_count': 0,
                };
                ref.read(currentTabProvider.notifier).state = 1;
                setState(() => _showMatch = false);
              },
              onKeepSwiping: () => setState(() => _showMatch = false),
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
            Icons.explore_outlined,
            size: 64,
            color: Theme.of(context).primaryColor.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 16),
          Text(
            'No more profiles',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).textTheme.bodyLarge?.color?.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adding more countries',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.35),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _showCountryFilter,
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              padding: const EdgeInsets.symmetric(
                  horizontal: 24, vertical: 12),
            ),
            child: Text(
              'Change Countries',
              style: GoogleFonts.inter(
                  fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmer() {
    return const Center(child: ShimmerSwipeCard());
  }
}
