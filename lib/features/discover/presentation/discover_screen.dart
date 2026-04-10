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
import '../../me/presentation/edit_profile_screen.dart';

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
  bool _showTutorial = false;
  bool _showSwipeHint = false;
  int _likesRemaining = 10;
  String? _mostCompatibleId; // ID of the daily Most Compatible card
  String? _matchComment; // Track comment to show in match overlay
  String? _commentForNextSwipe; // Pending comment from bottom sheet
  bool _needsPhoto = false;

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

    final user = SupabaseConfig.client.auth.currentUser;
    if (user != null) {
      final likesCount = await _repo.getLikesTodayCount(user.id);
      if (mounted) {
        setState(() => _likesRemaining = max(0, 10 - likesCount));
      }
    }

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

    final hasSeenHint = prefs.getBool('has_seen_swipe_hint') ?? false;
    if (!hasSeenHint) {
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted && _profiles.isNotEmpty) {
          setState(() => _showSwipeHint = true);
          prefs.setBool('has_seen_swipe_hint', true);
        }
      });
    }

    
    final hasSeenTutorial = prefs.getBool('has_seen_tutorial_v1') ?? false;
    if (!hasSeenTutorial && mounted) {
      setState(() => _showTutorial = true);
    }

    await _checkPhotoRequirement();
    await _fetchMyAvatar();
    await _loadProfiles();
  }

  Future<void> _checkPhotoRequirement() async {
    final user = SupabaseConfig.client.auth.currentUser;
    if (user == null) return;
    
    try {
      final profile = await SupabaseConfig.client
          .from('profiles')
          .select('avatar_url')
          .eq('id', user.id)
          .maybeSingle();
      
      final avatarUrl = profile?['avatar_url'] as String?;
      if (mounted) {
        setState(() => _needsPhoto = avatarUrl == null || avatarUrl.isEmpty);
      }
    } catch (e) {
      debugPrint('[DISCOVER] Photo check error: $e');
    }
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
    setState(() {
      _loading = true;
      _profiles.clear();
      _currentIndex = 0;
    });

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

    // ── Most Compatible daily injection ──────────────────────────
    String? compatibleId;
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final lastShown = prefs.getString('most_compatible_date');

    if (profiles.isNotEmpty) {
      if (lastShown == today) {
        // Already determined today — reuse the saved ID
        compatibleId = prefs.getString('most_compatible_id');
      } else {
        // Ask the algorithm for today's pick
        try {
          final result = await SupabaseConfig.client.rpc(
            'get_most_compatible',
            params: {'p_user_id': userId},
          );
          compatibleId = result as String?;

          // If RPC returns nothing, fall back to top-ranked from feed
          compatibleId ??= profiles.first['id'] as String?;

          if (compatibleId != null) {
            await prefs.setString('most_compatible_date', today);
            await prefs.setString('most_compatible_id', compatibleId);
          }
        } catch (e) {
          debugPrint('[DISCOVER] get_most_compatible error: $e');
          compatibleId = profiles.isNotEmpty ? profiles.first['id'] as String? : null;
        }
      }

      // Inject the most compatible profile at index 0
      if (compatibleId != null) {
        final existingIndex = profiles.indexWhere((p) => p['id'] == compatibleId);
        if (existingIndex > 0) {
          // Move it to front
          final pick = profiles.removeAt(existingIndex);
          profiles.insert(0, pick);
        } else if (existingIndex < 0) {
          // Not in feed — fetch it directly and prepend
          try {
            final fetched = await SupabaseConfig.client
                .from('profiles')
                .select('id, name, age, nationality, avatar_url, bio, interests, city, is_local, team_supported, languages, is_verified, last_active_at, created_at, countries_to_match')
                .eq('id', compatibleId)
                .maybeSingle();
            if (fetched != null) {
              final profileMap = Map<String, dynamic>.from(fetched);
              profileMap['match_score'] = 99; // Top score for most compatible
              profiles.insert(0, profileMap);
            }
          } catch (e) {
            debugPrint('[DISCOVER] Failed to fetch most compatible profile: $e');
          }
        }
        // If existingIndex == 0, already at front — nothing to do
      }
    }
    // ─────────────────────────────────────────────────────────────

    if (mounted) {
      setState(() {
        _profiles = profiles;
        _currentIndex = 0;
        _loading = false;
        _mostCompatibleId = compatibleId;
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
      // Already picked today — find in loaded profiles
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
    } else {
      // Ask the algorithm for today's best match
      final userId = SupabaseConfig.client.auth.currentUser?.id;
      Map<String, dynamic>? newPick;

      if (userId != null) {
        try {
          final result = await SupabaseConfig.client.rpc(
            'get_most_compatible',
            params: {'p_user_id': userId},
          );
          // RPC returns a UUID string of the most compatible user
          final compatibleId = result as String?;
          if (compatibleId != null) {
            newPick = _profiles.cast<Map<String, dynamic>?>().firstWhere(
              (p) => p?['id'] == compatibleId,
              orElse: () => null,
            );
          }
        } catch (e) {
          debugPrint('get_most_compatible error: $e');
        }
      }

      // Fall back to top-ranked profile from smart score if RPC fails
      newPick ??= _profiles.first;

      await prefs.setString('daily_pick_id', newPick['id']);
      await prefs.setString('daily_pick_date', today);
      if (mounted) {
        setState(() {
          _dailyPick = newPick;
        });
      }
    }
  }

  void _onLikeTapped(Map<String, dynamic> profile) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _CommentLikeSheet(
        profile: profile,
        onSend: (String? comment) {
          Navigator.pop(context);
          _commentForNextSwipe = comment;
          _swiperController.swipe(CardSwiperDirection.right);
        },
      ),
    );
  }

  Future<void> _handleSwipe(String action, Map<String, dynamic> profile, {String? comment}) async {
    if (action == 'like' || action == 'superlike') {
      if (_likesRemaining <= 0) {
        _showLikeLimitOverlay();
        return;
      }
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
      comment: comment,
    );

    if (result != null && result['matched'] == true && mounted) {
      _showMatchReveal(profile, comment: comment);
    }

    if (action == 'like' || action == 'superlike') {
      setState(() => _likesRemaining = max(0, _likesRemaining - 1));
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

  void _showLikeLimitOverlay() {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.85),
      builder: (_) => Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            margin: const EdgeInsets.all(32),
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: const Color(0xFF080F0C),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: const Color(0xFFF2C233).withValues(alpha: 0.2)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(LucideIcons.heart, size: 64, color: Color(0xFFF2C233)),
                const SizedBox(height: 32),
                Text(
                  "You've used all\nyour likes today",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  "Come back tomorrow or upgrade\nfor unlimited likes.",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    color: Colors.white.withValues(alpha: 0.6),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 40),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF2C233),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Center(
                      child: Text(
                        'GO PREMIUM',
                        style: GoogleFonts.spaceMono(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Maybe Later',
                    style: GoogleFonts.inter(
                      color: Colors.white24,
                      fontSize: 13,
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
      body: _needsPhoto ? _buildPhotoPrompt(isLight) : Stack(
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
                        const SizedBox(height: 4),
                        Text(
                          '$_likesRemaining LIKES REMAINING TODAY',
                          style: GoogleFonts.spaceMono(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFFF2C233),
                            letterSpacing: 0.5,
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
                                  child: CardSwiper(
                                    key: ValueKey('swiper_${_selectedCountries.join('_')}'),
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
                                      final currentComment = _commentForNextSwipe;
                                      _commentForNextSwipe = null; // Clear it immediately

                                      Future.delayed(const Duration(milliseconds: 250), () {
                                        if (mounted) {
                                          _handleSwipe(action, profile, comment: currentComment);
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
                                      final cardProfile = _profiles[profileIndex];
                                      final cardWidth = MediaQuery.of(context).size.width - 32;
                                      // First card shown today == Most Compatible
                                      final isMC = _mostCompatibleId != null &&
                                          cardProfile['id'] == _mostCompatibleId &&
                                          profileIndex == 0;
                                      return RepaintBoundary(
                                        child: SwipeCard(
                                          profile: cardProfile,
                                          isFront: index == 0,
                                          stackPosition: index,
                                          isMostCompatible: isMC,
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
                          onTap: () => _onLikeTapped(_profiles[_currentIndex]),
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
              comment: _matchComment,
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

          if (_showSwipeHint)
            Positioned.fill(
              child: _SwipeHintOverlay(
                onDismiss: () => setState(() => _showSwipeHint = false),
              ),
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
                  ? 'No more fans in ${_selectedCountries.length == 1 ? _selectedCountries.first : "these countries"}.\nTry expanding your search.'
                  : 'You\'ve seen everyone for now.\nSkipped profiles return in 48 hours.',
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
                      : 'New fans arrive daily as the tournament approaches!',
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

  void _showMatchReveal(Map<String, dynamic> profile, {String? comment}) {
    if (!mounted) return;
    setState(() {
      _matchedProfile = profile;
      _showMatch = true;
      _matchComment = comment;
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
                      const Icon(LucideIcons.crown, size: 14, color: Colors.white),
                      const SizedBox(width: 6),
                      Text(
                        'MOST COMPATIBLE',
                        style: GoogleFonts.spaceMono(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 2.0,
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

class _CommentLikeSheet extends StatefulWidget {
  final Map<String, dynamic> profile;
  final Function(String?) onSend;
  const _CommentLikeSheet({required this.profile, required this.onSend});
  
  @override
  State<_CommentLikeSheet> createState() => _CommentLikeSheetState();
}

class _CommentLikeSheetState extends State<_CommentLikeSheet> {
  final _commentController = TextEditingController();
  
  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: isLight ? Colors.white : const Color(0xFF0D1A13),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        padding: const EdgeInsets.fromLTRB(28, 16, 28, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 24),
            Row(
              children: [
                Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    image: DecorationImage(image: NetworkImage(widget.profile['avatar_url'] ?? ''), fit: BoxFit.cover),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    'Liked ${widget.profile['name']}',
                    style: GoogleFonts.playfairDisplay(fontSize: 24, fontWeight: FontWeight.bold, color: isLight ? TurfArdorColors.textPrimaryLight : Colors.white),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Container(
              decoration: BoxDecoration(
                color: isLight ? const Color(0xFFF5F0E8) : const Color(0xFF152B1E),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isLight ? const Color(0xFFE8DDD0) : const Color(0xFF1E4A33)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: TextField(
                controller: _commentController,
                autofocus: true,
                maxLength: 150,
                maxLines: 3,
                style: GoogleFonts.inter(fontSize: 15, color: isLight ? TurfArdorColors.textPrimaryLight : Colors.white),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Add a note...',
                  counterStyle: GoogleFonts.spaceMono(fontSize: 10, color: Colors.white24),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => widget.onSend(null),
                    child: Text('Just Like', style: GoogleFonts.spaceMono(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white54, letterSpacing: 1)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: () => widget.onSend(_commentController.text.trim().isEmpty ? null : _commentController.text.trim()),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: TurfArdorColors.pink,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text('SEND NOTE', style: GoogleFonts.spaceMono(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 2)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SwipeHintOverlay extends StatefulWidget {
  final VoidCallback onDismiss;
  const _SwipeHintOverlay({required this.onDismiss});
  
  @override
  State<_SwipeHintOverlay> createState() => _SwipeHintOverlayState();
}

class _SwipeHintOverlayState extends State<_SwipeHintOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<Offset> _slideRight;
  late Animation<double> _fade;
  
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );
    
    // Slide right then left
    _slideRight = TweenSequence<Offset>([
      TweenSequenceItem(
        tween: Tween(begin: Offset.zero, end: const Offset(0.15, 0))
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 25,
      ),
      TweenSequenceItem(
        tween: Tween(begin: const Offset(0.15, 0), end: Offset.zero)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 25,
      ),
      TweenSequenceItem(
        tween: Tween(begin: Offset.zero, end: const Offset(-0.15, 0))
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 25,
      ),
      TweenSequenceItem(
        tween: Tween(begin: const Offset(-0.15, 0), end: Offset.zero)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 25,
      ),
    ]).animate(_ctrl);
    
    _fade = Tween(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _ctrl, curve: const Interval(0.85, 1.0)),
    );
    
    _ctrl.forward().then((_) {
      if (mounted) widget.onDismiss();
    });
  }
  
  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    // Wrap the whole overlay in a GestureDetector to dismiss immediately on tap
    return GestureDetector(
      onTap: widget.onDismiss,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, __) => FadeTransition(
          opacity: _fade,
          child: Container(
            color: const Color(0xFF080F0C).withValues(alpha: 0.6),
            child: Center(
              child: SlideTransition(
                position: _slideRight,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(LucideIcons.moveHorizontal, 
                      size: 48, color: Colors.white.withValues(alpha: 0.8)),
                    const SizedBox(height: 16),
                    Text('Swipe right to like',
                      style: GoogleFonts.inter(
                        fontSize: 16, fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text('Swipe left to pass',
                      style: GoogleFonts.inter(
                        fontSize: 14, color: const Color(0xFF9BB3AF),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoPrompt(bool isLight) {
    final textColor = isLight ? const Color(0xFF0D1410) : Colors.white;
    final mutedColor = isLight ? Colors.black54 : Colors.white60;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(LucideIcons.camera, size: 48, color: Color(0xFFE8437A)),
            const SizedBox(height: 24),
            Text(
              'Add a photo to start matching',
              style: GoogleFonts.playfairDisplay(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: textColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Profiles with photos get 10x more matches',
              style: GoogleFonts.inter(
                fontSize: 14, 
                color: mutedColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            GestureDetector(
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const EditProfileScreen()),
                );
                _checkPhotoRequirement();
              },
              child: Container(
                height: 52,
                width: 220,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(26),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF135E4B), Color(0xFF4CB572)],
                  ),
                ),
                child: Center(
                  child: Text(
                    'Upload Photo',
                    style: GoogleFonts.inter(
                      fontSize: 16, 
                      fontWeight: FontWeight.w600, 
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
