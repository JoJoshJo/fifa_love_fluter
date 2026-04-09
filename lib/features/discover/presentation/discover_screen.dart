import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../shared/widgets/gradient_button.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:flutter/services.dart';
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

class _DiscoverScreenState extends ConsumerState<DiscoverScreen> with TickerProviderStateMixin {
  final _repo = DiscoverRepository();
  final _swiperController = CardSwiperController();

  List<Map<String, dynamic>> _profiles = [];
  int _currentIndex = 0;
  bool _loading = true;
  bool _showMatch = false;
  Map<String, dynamic>? _matchedProfile;
  String? _myAvatarUrl;
  Map<String, dynamic>? _dailyPick;
  bool _dailyPickSwiped = false;
  List<String> _selectedCountries = [];
  int _dailySwipes = 0;
  late AnimationController _hintController;
  late Animation<Offset> _hintAnimation;
  bool _showTutorial = false;

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
    _hintController.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    _dailySwipes = prefs.getInt(_swipePrefsKey) ?? 0;

    // Load countries from DB profile as the source of truth.
    // SharedPreferences only stores user's explicit filter-sheet overrides.
    try {
      final user = SupabaseConfig.client.auth.currentUser;
      if (user != null) {
        final profile = await SupabaseConfig.client
            .from('profiles')
            .select('countries_to_match')
            .eq('id', user.id)
            .single();
        final dbCountries =
            List<String>.from(profile['countries_to_match'] ?? []);
        if (dbCountries.isNotEmpty) {
          _selectedCountries = dbCountries;
          // Keep SharedPreferences in sync
          await prefs.setStringList('selected_countries', dbCountries);
        } else {
          // Fall back to locally saved countries
          final raw = prefs.getStringList('selected_countries');
          if (raw != null) _selectedCountries = raw;
        }
      }
    } catch (_) {
      // Fall back to locally saved countries on any error
      final raw = prefs.getStringList('selected_countries');
      if (raw != null) _selectedCountries = raw;
    }

    // Initialize swipe hint
    _hintController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _hintAnimation = TweenSequence<Offset>([
      TweenSequenceItem(
        tween: Tween<Offset>(begin: Offset.zero, end: const Offset(30, 0))
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 20, // Slide right (300ms)
      ),
      TweenSequenceItem(
        tween: ConstantTween<Offset>(const Offset(30, 0)),
        weight: 20, // Pause (300ms)
      ),
      TweenSequenceItem(
        tween: Tween<Offset>(begin: const Offset(30, 0), end: const Offset(-30, 0))
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 20, // Slide left (300ms - goes to -30 relative to center)
      ),
      TweenSequenceItem(
        tween: ConstantTween<Offset>(const Offset(-30, 0)),
        weight: 20, // Pause (300ms)
      ),
      TweenSequenceItem(
        tween: Tween<Offset>(begin: const Offset(-30, 0), end: Offset.zero)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 20, // Return to center (300ms)
      ),
    ]).animate(_hintController);

    final hasSeenHint = prefs.getBool('has_seen_swipe_hint') ?? false;
    if (!hasSeenHint) {
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted && _profiles.isNotEmpty) {
          _hintController.forward().then((_) {
            prefs.setBool('has_seen_swipe_hint', true);
          });
        }
      });
    }

    
    final hasSeenTutorial = prefs.getBool('has_seen_tutorial_v1') ?? false;
    if (!hasSeenTutorial && mounted) {
      setState(() => _showTutorial = true);
    }

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
      _handleDailyPickSelection();
    }
  }

  Future<void> _handleDailyPickSelection() async {
    if (_profiles.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final savedDate = prefs.getString('daily_pick_date');
    final savedId = prefs.getString('daily_pick_id');
    final wasSwiped = prefs.getBool('daily_pick_swiped_$today') ?? false;

    if (savedDate == today && savedId != null) {
      // Find the pick in the loaded profiles or fetch it specifically if needed
      // For now, if it's in the current feed, we highlight it
      final pick = _profiles.cast<Map<String, dynamic>?>().firstWhere(
        (p) => p?['id'] == savedId,
        orElse: () => null,
      );
      if (mounted) {
        setState(() {
          _dailyPick = pick;
          _dailyPickSwiped = wasSwiped;
        });
      }
    } else if (_profiles.isNotEmpty) {
      // Pick the top one as the daily most compatible
      final newPick = _profiles.first;
      await prefs.setString('daily_pick_id', newPick['id']);
      await prefs.setString('daily_pick_date', today);
      if (mounted) {
        setState(() {
          _dailyPick = newPick;
        });
      }
    }
  }

  void _showCommentedLikeSheet() {
    if (_currentIndex >= _profiles.length) return;
    final profile = _profiles[_currentIndex];
    final isLight = Theme.of(context).brightness == Brightness.light;
    final TextEditingController commentController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: isLight ? Colors.white : const Color(0xFF0D1A13),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          ),
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isLight ? Colors.black12 : Colors.white10,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      image: DecorationImage(
                        image: NetworkImage(profile['avatar_url'] ?? ''),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'SEND A NOTE TO ${profile['name']?.toUpperCase()}',
                          style: GoogleFonts.spaceMono(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFFE8437A),
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'They\'ll see this when you show up in their likes.',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: isLight ? Colors.black54 : Colors.white54,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Container(
                decoration: BoxDecoration(
                  color: isLight ? const Color(0xFFF5F0E8) : const Color(0xFF152B1E),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isLight ? const Color(0xFFE8DDD0) : const Color(0xFF1E4A33),
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: TextField(
                  controller: commentController,
                  autofocus: true,
                  maxLines: 4,
                  style: GoogleFonts.inter(fontSize: 15),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Say something about their team or bio...',
                    hintStyle: GoogleFonts.inter(
                      fontSize: 14,
                      color: isLight ? Colors.black26 : Colors.white24,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () async {
                    final comment = commentController.text.trim();
                    if (comment.isEmpty) return;
                    
                    Navigator.pop(context);
                    
                    final result = await _repo.recordCommentedLike(
                      swiperId: SupabaseConfig.client.auth.currentUser?.id ?? '',
                      swipedId: profile['id'],
                      comment: comment,
                    );
                    
                    if (result != null && result['matched'] == true) {
                      _showMatchReveal(profile);
                    }
                    
                    _swiperController.swipe(CardSwiperDirection.right);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE8437A),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'SEND LIKE',
                    style: GoogleFonts.spaceMono(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 2.0,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
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

    if (result != null && result['matched'] == true && mounted) {
      _showMatchReveal(profile);
    }

    setState(() => _currentIndex++);

    // If this was the daily pick, mark it as swiped
    if (_dailyPick != null && swipedId == _dailyPick!['id']) {
      final prefs = await SharedPreferences.getInstance();
      final today = DateTime.now().toIso8601String().substring(0, 10);
      await prefs.setBool('daily_pick_swiped_$today', true);
      setState(() => _dailyPickSwiped = true);
    }

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
              'Upgrade to Turf&Ardor Premium for unlimited swipes.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 24),
            GradientButton(
              text: 'GO PREMIUM',
              onPressed: () => Navigator.pop(context),
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
    final random = Random(DateTime.now().day);
    final swipeCount = 340 + random.nextInt(200);
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
                            fontSize: 10,
                            color: const Color(0xFFE8437A),
                            letterSpacing: 2,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Discover',
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                            color: isLight ? const Color(0xFF0D1410) : Colors.white,
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
                        height: 36,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: isLight
                              ? const Color(0xFFFDF2F5) // Soft pink tint
                              : const Color(0xFF2B151E),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: const Color(0xFFE8437A).withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Stack(
                              clipBehavior: Clip.none,
                              children: [
                                const Icon(
                                  LucideIcons.globe,
                                  size: 16,
                                  color: Color(0xFFE8437A),
                                ),
                                if (_selectedCountries.isNotEmpty)
                                  Positioned(
                                    top: -2,
                                    right: -2,
                                    child: Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFE8437A),
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: isLight
                                              ? const Color(0xFFF5F0E8)
                                              : const Color(0xFF080F0C),
                                          width: 1.5,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _selectedCountries.isEmpty
                                  ? 'WORLD'
                                  : (_selectedCountries.length == 1
                                      ? _selectedCountries.first.toUpperCase()
                                      : '${_selectedCountries.length}'),
                              style: GoogleFonts.spaceMono(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFFE8437A),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              _buildDailyPickCard(isLight),

              // ── Social Proof Bar ──
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 12),
                child: Row(
                  children: [
                    const PulsingDot(color: Color(0xFF4CB572)),
                    const SizedBox(width: 8),
                    Text(
                      '${1400 + DateTime.now().second * 7} FANS ONLINE',
                      style: GoogleFonts.spaceMono(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF4CB572),
                        letterSpacing: 1.2,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8437A).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${320 + swipeCount} MATCHES TODAY',
                        style: GoogleFonts.spaceMono(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFFE8437A),
                          letterSpacing: 0.5,
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
                      color: TurfArdorColors.gold.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: TurfArdorColors.gold.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.star,
                            size: 16, color: TurfArdorColors.gold),
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
                              color: TurfArdorColors.gold,
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
                                  child: SlideTransition(
                                    position: _hintAnimation,
                                    child: CardSwiper(
                                      controller: _swiperController,
                                      cardsCount: min(3, remaining),
                                      numberOfCardsDisplayed: 2,
                                      backCardOffset: const Offset(0, -20),
                                      scale: 0.94,
                                      isLoop: false,
                                      duration: const Duration(milliseconds: 200),
                                      padding: EdgeInsets.zero,
                                      onSwipe: (prevIndex, currentIndex, direction) {
                                        String action = 'nope';
                                        if (direction ==
                                            CardSwiperDirection.right) {
                                          action = 'like';
                                          HapticFeedback.mediumImpact();
                                        } else if (direction ==
                                            CardSwiperDirection.left) {
                                          action = 'nope';
                                          HapticFeedback.lightImpact();
                                        } else if (direction ==
                                            CardSwiperDirection.top) {
                                          action = 'superlike';
                                          HapticFeedback.heavyImpact();
                                        }
                                        
                                        // Defer heavier logic to let animation run
                                        final profile = _profiles[_currentIndex + prevIndex];
                                        Future.delayed(const Duration(milliseconds: 250), () {
                                          if (mounted) {
                                            _handleSwipe(action, profile);
                                          }
                                        });
                                        return true;
                                      },
                                      cardBuilder: (context, index,
                                          percentThresholdX, percentThresholdY) {
                                        final profileIndex = _currentIndex + index;
                                        if (profileIndex >= _profiles.length) {
                                          return const SizedBox.shrink();
                                        }
                                        final cardWidth = MediaQuery.of(context).size.width - 32;
                                        return RepaintBoundary(
                                          child: SwipeCard(
                                            profile: _profiles[profileIndex],
                                            isFront: index == 0,
                                            stackPosition: index,
                                            dragOffset: index == 0
                                                ? Offset(percentThresholdX / 100 * cardWidth,
                                                    percentThresholdY / 100 * cardWidth)
                                                : Offset.zero,
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                            ),
                          ),
                ),

                if (!_loading && remaining > 0) ...[
                  // ACTION BUTTONS BELOW CARD
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // SKIP (X)
                        _ActionButton(
                          icon: LucideIcons.x,
                          color: isLight ? TurfArdorColors.textPrimaryLight : Colors.white,
                          size: 48,
                          iconSize: 22,
                          hasBorder: true,
                          borderColor: isLight ? const Color(0xFFE8DDD0) : const Color(0xFF1E4A33),
                          onTap: () => _swiperController.swipe(CardSwiperDirection.left),
                        ),
                        const SizedBox(width: 16),
                        // LIKE (Hero)
                        _ActionButton(
                          icon: Icons.favorite, // Using Material favorite for filled heart look as requested
                          color: Colors.white,
                          size: 60,
                          iconSize: 26,
                          isHero: true,
                          backgroundColor: TurfArdorColors.pink,
                          boxShadow: [
                            BoxShadow(
                              color: TurfArdorColors.pink.withValues(alpha: 0.35),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                          offset: const Offset(0, -4),
                          onTap: () => _swiperController.swipe(CardSwiperDirection.right),
                        ),
                        const SizedBox(width: 12),
                        // COMMENTED LIKE (Heart + Msg)
                        _ActionButton(
                          icon: LucideIcons.messageSquare,
                          color: TurfArdorColors.pink,
                          size: 48,
                          iconSize: 22,
                          hasBorder: true,
                          borderColor: TurfArdorColors.pink.withValues(alpha: 0.3),
                          onTap: _showCommentedLikeSheet,
                        ),
                        const SizedBox(width: 12),
                        // SUPER LIKE (Star)
                        _ActionButton(
                          icon: LucideIcons.star,
                          color: TurfArdorColors.gold,
                          size: 48,
                          iconSize: 22,
                          hasBorder: true,
                          borderColor: TurfArdorColors.gold,
                          backgroundColor: Colors.transparent,
                          onTap: () => _swiperController.swipe(CardSwiperDirection.top),
                        ),
                      ],
                    ),
                  ),

                  // ACTIVE USER BADGES BELOW BUTTONS
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
                    child: Row(
                      children: [
                        const _ActivePillPulse(),
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
                              const Icon(LucideIcons.checkCircle2,
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

          if (_showTutorial)
            _TutorialOverlay(
              onDismiss: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setBool('has_seen_tutorial_v1', true);
                if (mounted) {
                  setState(() => _showTutorial = false);
                }
              },
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final daysLeft = DateTime(2026, 6, 11).difference(DateTime.now()).inDays;
    final hasFilters = _selectedCountries.isNotEmpty;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Animated heart + globe icon combo
          Stack(
            alignment: Alignment.center,
            children: [
              Icon(
                hasFilters ? LucideIcons.searchX : LucideIcons.globe,
                size: 64,
                color: const Color(0xFFE8437A).withValues(alpha: 0.15),
              ),
              if (!hasFilters)
                const Icon(
                  LucideIcons.heart,
                  size: 32,
                  color: Color(0xFFE8437A),
                ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            hasFilters ? 'NO MATCHES FOUND' : 'KEEP EXPLORING',
            style: GoogleFonts.spaceMono(
              fontSize: 10,
              color: const Color(0xFFE8437A),
              letterSpacing: 2.0,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              hasFilters
                  ? 'No fans from these\ncountries yet.'
                  : 'You\'ve seen everyone\nnearby. Expand your search.',
              textAlign: TextAlign.center,
              style: GoogleFonts.playfairDisplay(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: isLight ? const Color(0xFF0D2B1E) : Colors.white,
                height: 1.2,
              ),
            ),
          ),
          const SizedBox(height: 32),
          
          // 2026 World Cup Countdown Teaser
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.symmetric(horizontal: 40),
            decoration: BoxDecoration(
              color: const Color(0xFFF2C233).withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFFF2C233).withValues(alpha: 0.1),
              ),
            ),
            child: Column(
              children: [
                Text(
                  '$daysLeft DAYS UNTIL THE WORLD CUP',
                  style: GoogleFonts.spaceMono(
                    fontSize: 9,
                    color: const Color(0xFFF2C233),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  hasFilters
                      ? 'Fans from all over the world are joining every hour.'
                      : 'New fans arrive every day as the tournament approaches.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: isLight ? const Color(0xFF8B7355) : Colors.white.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 48),

          // ACTION BUTTON
          GestureDetector(
            onTap: _showCountryFilter,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFE8437A), Color(0xFFF2C233)],
                ),
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFE8437A).withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Text(
                hasFilters ? 'CHANGE COUNTRIES' : 'EXPLORE MORE COUNTRIES',
                style: GoogleFonts.spaceMono(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1,
                ),
              ),
            ),
          ),
          if (hasFilters)
            TextButton(
              onPressed: () {
                setState(() {
                  _selectedCountries = [];
                  _currentIndex = 0;
                });
                _loadProfiles();
              },
              child: Text(
                'Clear all filters',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: isLight ? const Color(0xFF8B7355) : Colors.white54,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildShimmer() {
    return const Center(child: ShimmerSwipeCard());
  }

  void _showMatchReveal(Map<String, dynamic> profile) {
    if (!mounted) return;
    setState(() {
      _matchedProfile = profile;
      _showMatch = true;
    });
  }

  Widget _buildDailyPickCard(bool isLight) {
    if (_dailyPick == null || _dailyPickSwiped) return const SizedBox.shrink();

    return GestureDetector(
      onTap: () {
        // Find pick index in profiles and jump to it or show a highlight
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFF2C233), Color(0xFFD4AF37)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFF2C233).withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                image: DecorationImage(
                  image: NetworkImage(_dailyPick!['avatar_url'] ?? ''),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(LucideIcons.sparkles, size: 14, color: Colors.white),
                      const SizedBox(width: 6),
                      Text(
                        'MOST COMPATIBLE',
                        style: GoogleFonts.spaceMono(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_dailyPick!['name']} is your perfect fan match today!',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            Icon(LucideIcons.chevronRight, color: Colors.white.withValues(alpha: 0.7)),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatefulWidget {
  final IconData icon;
  final Color color;
  final double size;
  final double iconSize;
  final VoidCallback onTap;
  final bool hasBorder;
  final Color? borderColor;
  final Color? backgroundColor;
  final List<BoxShadow>? boxShadow;
  final Offset offset;
  final bool isHero;

  const _ActionButton({
    required this.icon,
    required this.color,
    required this.size,
    required this.iconSize,
    required this.onTap,
    this.hasBorder = false,
    this.borderColor,
    this.backgroundColor,
    this.boxShadow,
    this.offset = Offset.zero,
    this.isHero = false,
  });

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.3).chain(CurveTween(curve: Curves.easeOut)),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.3, end: 1.0).chain(CurveTween(curve: Curves.elasticOut)),
        weight: 60,
      ),
    ]).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTap() {
    if (widget.isHero) {
      _controller.forward(from: 0.0);
      HapticFeedback.mediumImpact();
    }
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    return Transform.translate(
      offset: widget.offset,
      child: GestureDetector(
        onTap: _onTap,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.backgroundColor ?? (isLight ? Colors.white : const Color(0xFF0D1A13)),
              border: widget.hasBorder ? Border.all(color: widget.borderColor ?? Colors.transparent, width: 1) : null,
              boxShadow: widget.boxShadow ?? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isLight ? 0.08 : 0.2),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Icon(widget.icon, size: widget.iconSize, color: widget.color),
            ),
          ),
        ),
      ),
    );
  }
}

class _ActivePillPulse extends StatefulWidget {
  const _ActivePillPulse();

  @override
  State<_ActivePillPulse> createState() => _ActivePillPulseState();
}

class _ActivePillPulseState extends State<_ActivePillPulse> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _opacityAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.8, end: 1.0), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.8), weight: 50),
    ]).animate(_pulseController);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Opacity(
            opacity: _opacityAnimation.value,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFFD4EBE0), // Mint background
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFE8437A).withValues(alpha: 0.15),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: Color(0xFFE8437A), // Pink indicator
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'ACTIVE NOW',
                    style: GoogleFonts.spaceMono(
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF004B3A),
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class PulsingDot extends StatefulWidget {
  final Color color;
  const PulsingDot({super.key, required this.color});

  @override
  State<PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<PulsingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1500))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => Opacity(
        opacity: 0.4 + (_ctrl.value * 0.6),
        child: Container(
          width: 8,
          height: 8,
          decoration:
              BoxDecoration(shape: BoxShape.circle, color: widget.color),
        ),
      ),
    );
  }
}

class _TutorialOverlay extends StatelessWidget {
  final VoidCallback onDismiss;

  const _TutorialOverlay({required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Material(
        color: Colors.transparent,
        child: GestureDetector(
          onTap: onDismiss,
          child: Container(
            color: Colors.black.withValues(alpha: 0.9),
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'WELCOME TO TURF&ARDOR',
                  style: GoogleFonts.spaceMono(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFF2C233),
                    letterSpacing: 3,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'How to score a match',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 60),
                _TutorialRow(
                  icon: LucideIcons.arrowRight,
                  label: 'SWIPE RIGHT',
                  sub: 'to like a fan',
                  color: const Color(0xFF4CB572),
                ),
                const SizedBox(height: 48),
                _TutorialRow(
                  icon: LucideIcons.arrowLeft,
                  label: 'SWIPE LEFT',
                  sub: 'to pass',
                  color: const Color(0xFFE8437A),
                ),
                const SizedBox(height: 48),
                _TutorialRow(
                  icon: LucideIcons.mousePointer2,
                  label: 'TAP CARDS',
                  sub: 'to see more photos',
                  color: Colors.white,
                ),
                const SizedBox(height: 80),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 42, vertical: 16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white30),
                    borderRadius: BorderRadius.circular(32),
                  ),
                  child: Text(
                    'GOT IT',
                    style: GoogleFonts.spaceMono(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 2,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TutorialRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sub;
  final Color color;

  const _TutorialRow({
    required this.icon,
    required this.label,
    required this.sub,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: 0.15),
            border: Border.all(color: color.withValues(alpha: 0.5)),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(width: 20),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.spaceMono(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: color,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              sub,
              style: GoogleFonts.inter(
                fontSize: 15,
                color: Colors.white.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
