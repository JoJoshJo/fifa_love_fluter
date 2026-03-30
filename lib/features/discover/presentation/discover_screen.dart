import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/supabase/supabase_config.dart';
import '../../../shared/providers/navigation_provider.dart';
import '../data/discover_repository.dart';
import 'widgets/swipe_card.dart';
import 'widgets/match_overlay.dart';
import 'widgets/country_filter_sheet.dart';

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
    final userId = user?.id ?? 'mock-user';

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
    // Hard limit check
    if (_dailySwipes >= _hardLimit) {
      _showPremiumSheet();
      return;
    }

    // Increment counter
    _dailySwipes++;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_swipePrefsKey, _dailySwipes);

    final user = SupabaseConfig.client.auth.currentUser;
    final swiperId = user?.id ?? 'mock-user';
    final swipedId = profile['id'] as String;

    // Record swipe & check for match
    final result = await _repo.recordSwipe(
      swiperId: swiperId,
      swipedId: swipedId,
      action: action,
      matchScore: (profile['match_score'] as int?) ?? 20,
    );

    if (!mounted) return;

    // Mutual match
    if (result != null) {
      setState(() {
        _matchedProfile = profile;
        _showMatch = true;
      });
    }

    // Advance index
    setState(() => _currentIndex++);

    // Reload when near the end
    if (_currentIndex >= _profiles.length - 3) {
      _loadProfiles();
    }
  }

  void _showPremiumSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0D1A13),
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
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Upgrade to FIFA LOVE Premium for unlimited swipes.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.white.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF2C233),
                  foregroundColor: Colors.black,
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

  void _openCountryFilter() {
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

    return Scaffold(
      backgroundColor: const Color(0xFF080F0C),
      body: Stack(
        children: [
          // Main content
          SafeArea(
            child: Column(
              children: [
                // ── Top bar ──────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      // App name
                      Text(
                        'FIFA LOVE',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFFF2C233),
                        ),
                      ),
                      const Spacer(),
                      // Daily counter
                      if (_dailySwipes > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${_freeLimit - _dailySwipes < 0 ? 0 : _freeLimit - _dailySwipes} left',
                            style: GoogleFonts.spaceMono(
                              fontSize: 10,
                              color: Colors.white.withValues(alpha: 0.4),
                            ),
                          ),
                        ),
                      const SizedBox(width: 8),
                      // Country filter button
                      GestureDetector(
                        onTap: _openCountryFilter,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF152B1E),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: const Color(0xFF4CB572)
                                  .withValues(alpha: 0.6),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('🌍', style: TextStyle(fontSize: 14)),
                              const SizedBox(width: 4),
                              Text(
                                _selectedCountries.isEmpty
                                    ? 'ALL'
                                    : '${_selectedCountries.length}',
                                style: GoogleFonts.spaceMono(
                                  fontSize: 10,
                                  color: const Color(0xFF4CB572),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Free limit warning banner ───────────────────
                if (_dailySwipes >= _freeLimit && _dailySwipes < _hardLimit)
                  Container(
                    margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF2C233).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFFF2C233).withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.star,
                            size: 16, color: Color(0xFFF2C233)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            "You've used your free swipes today",
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: Colors.white.withValues(alpha: 0.7),
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
                              color: const Color(0xFFF2C233),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // ── Card stack ──────────────────────────────────
                Expanded(
                  child: _loading
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF4CB572),
                            strokeWidth: 2,
                          ),
                        )
                      : remaining <= 0
                          ? _buildEmptyState()
                          : Center(
                              child: SizedBox(
                                height: MediaQuery.of(context).size.height * 0.68,
                                width: MediaQuery.of(context).size.width - 32,
                                child: CardSwiper(
                                  controller: _swiperController,
                                  cardsCount: min(3, remaining),
                                  numberOfCardsDisplayed: min(3, remaining),
                                  backCardOffset: const Offset(0, -16),
                                  scale: 0.95,
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

                // ── Action buttons ──────────────────────────────
                if (!_loading && remaining > 0)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(48, 8, 48, 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // NOPE
                        GestureDetector(
                          onTap: () => _swiperController.swipe(CardSwiperDirection.left),
                          child: Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: const Color(0xFF152B1E),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFFE8437A).withValues(alpha: 0.5),
                                width: 1.5,
                              ),
                            ),
                            child: const Icon(Icons.close, size: 24, color: Color(0xFFE8437A)),
                          ),
                        ),
                        // SUPERLIKE
                        GestureDetector(
                          onTap: () => _swiperController.swipe(CardSwiperDirection.top),
                          child: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: const Color(0xFF152B1E),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFFF2C233).withValues(alpha: 0.5),
                                width: 1.5,
                              ),
                            ),
                            child: const Icon(Icons.star_outline, size: 22, color: Color(0xFFF2C233)),
                          ),
                        ),
                        // LIKE
                        GestureDetector(
                          onTap: () => _swiperController.swipe(CardSwiperDirection.right),
                          child: Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: const Color(0xFF135E4B),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFF4CB572),
                                width: 1.5,
                              ),
                            ),
                            child: const Icon(Icons.favorite_outline, size: 24, color: Color(0xFF4CB572)),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          // ── Match overlay layer ──────────────────────────────
          if (_showMatch && _matchedProfile != null)
            MatchOverlay(
              matchedProfile: _matchedProfile!,
              myAvatarUrl: _myAvatarUrl,
              onMessage: () {
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
            color: const Color(0xFF4CB572).withValues(alpha: 0.4),
          ),
          const SizedBox(height: 16),
          Text(
            'No more profiles',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adding more countries',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.35),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _openCountryFilter,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF135E4B),
              foregroundColor: const Color(0xFF4CB572),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: const BorderSide(color: Color(0xFF4CB572)),
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
}
