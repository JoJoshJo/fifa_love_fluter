import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/constants/colors.dart';
import 'package:fifalove_mobile/core/utils/url_helper.dart';


class SwipeCard extends StatefulWidget {
  final Map<String, dynamic> profile;
  final bool isFront;
  final int stackPosition; // 0 = front, 1 = middle, 2 = back
  final Offset dragOffset; // drag amount in pixels
  final bool isMostCompatible; // Shows gold crown banner when true

  const SwipeCard({
    super.key,
    required this.profile,
    required this.isFront,
    this.stackPosition = 0,
    this.dragOffset = Offset.zero,
    this.isMostCompatible = false,
  });

  @override
  State<SwipeCard> createState() => _SwipeCardState();
}

class _SwipeCardState extends State<SwipeCard> {
  int _currentPhotoIndex = 0;

  Color _tagBackground(String tag) {
    final t = tag.toLowerCase();
    const sportTags = ['football', 'soccer', 'sports', 'gym', 'running', 'basketball', 'fitness', 'cycling'];
    const cultureTags = ['samba', 'music', 'nightlife', 'dancing', 'art', 'photography', 'cooking', 'travel', 'fashion'];
    const outdoorTags = ['beach', 'hiking', 'nature', 'surfing', 'yoga', 'gardening', 'camping'];

    if (sportTags.contains(t)) return const Color(0xFFA4E4C1);
    if (cultureTags.contains(t)) return const Color(0xFFFFF0F5);
    if (outdoorTags.contains(t)) return const Color(0xFFFFF8E1);
    return const Color(0xFFE8F5EE);
  }

  Color _tagText(String tag) {
    final t = tag.toLowerCase();
    const sportTags = ['football', 'soccer', 'sports', 'gym', 'running', 'basketball', 'fitness', 'cycling'];
    const cultureTags = ['samba', 'music', 'nightlife', 'dancing', 'art', 'photography', 'cooking', 'travel', 'fashion'];
    const outdoorTags = ['beach', 'hiking', 'nature', 'surfing', 'yoga', 'gardening', 'camping'];

    if (sportTags.contains(t)) return const Color(0xFF004B3A);
    if (cultureTags.contains(t)) return const Color(0xFF8A3058);
    if (outdoorTags.contains(t)) return const Color(0xFF5A4500);
    return const Color(0xFF135E4B);
  }

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final profile = widget.profile;
    final name = profile['name'] as String? ?? '';
    final age = profile['age'] as int? ?? 0;
    final nationality = profile['nationality'] as String? ?? '';
    final city = profile['city'] as String? ?? '';
    final bio = profile['bio'] as String?;
    final interests = List<String>.from(profile['interests'] ?? []);
    final score = (profile['match_score'] as num?)?.toInt() ?? 0;
    final isVerified = profile['is_verified'] as bool? ?? false;
    final rawAvatarUrl = profile['avatar_url'] as String?;
    final photos = rawAvatarUrl != null ? [rawAvatarUrl] : <String>[];

    final createdAtStr = profile['created_at'] as String?;
    final createdAt = createdAtStr != null ? DateTime.tryParse(createdAtStr) : null;
    final isNew = createdAt != null && DateTime.now().difference(createdAt).inDays <= 7;

    // Location string: "Country · City"
    final locationParts = <String>[
      if (nationality.isNotEmpty) nationality,
      if (city.isNotEmpty) city,
    ];
    final locationLine = locationParts.join(' · ');

    // Muted color
    final muted = isLight
        ? const Color(0xFF9BB3AF)
        : Colors.white.withValues(alpha: 0.35);

    Widget card = Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(
          children: [
            // ── PHOTO SECTION (60%) — name overlaid at bottom  ──────────
            Expanded(
              flex: 60,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Photo PageView
                  PageView.builder(
                    itemCount: photos.isEmpty ? 1 : photos.length,
                    onPageChanged: (i) => setState(() => _currentPhotoIndex = i),
                    itemBuilder: (context, index) {
                      if (photos.isEmpty) {
                        return _buildPhotoPlaceholder(name, nationality);
                      }
                      final resolvedUrl = UrlHelper.resolveImageUrl(photos[index]);
                      if (resolvedUrl.isEmpty) {
                        return _buildPhotoPlaceholder(name, nationality);
                      }
                      return CachedNetworkImage(
                        imageUrl: resolvedUrl,
                        fit: BoxFit.cover,
                        memCacheWidth: 400,
                        memCacheHeight: 600,
                        placeholder: (context, url) => Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Color(0xFF1E4A33), Color(0xFF0D1A13)],
                            ),
                          ),
                          child: const Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFF4CB572),
                            ),
                          ),
                        ),
                        errorWidget: (context, url, error) =>
                            _buildPhotoPlaceholder(name, nationality),
                      );
                    },
                  ),

                  // Deep gradient at bottom (for name overlay legibility)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.15),
                            Colors.black.withValues(alpha: 0.72),
                          ],
                          stops: const [0.0, 0.45, 0.65, 1.0],
                        ),
                      ),
                    ),
                  ),

                  // ── NAME / AGE / LOCATION overlaid on photo ──
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Name + age + verified badge
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                '$name, $age',
                                style: GoogleFonts.playfairDisplay(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                  height: 1.1,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black.withValues(alpha: 0.4),
                                      offset: const Offset(0, 2),
                                      blurRadius: 6,
                                    ),
                                  ],
                                ),
                              ),
                              if (isVerified) ...[
                                const SizedBox(width: 7),
                                const _VerifiedPulse(),
                              ],
                            ],
                          ),
                          const SizedBox(height: 3),
                          // Flag · Country · City
                          Text(
                            locationLine,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: Colors.white.withValues(alpha: 0.88),
                              shadows: [
                                Shadow(
                                  color: Colors.black.withValues(alpha: 0.4),
                                  offset: const Offset(0, 1),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Photo carousel dots (above name overlay)
                  if (photos.length > 1)
                    Positioned(
                      bottom: 72,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          photos.length,
                          (index) => Container(
                            margin: const EdgeInsets.symmetric(horizontal: 2),
                            width: _currentPhotoIndex == index ? 8 : 6,
                            height: 3,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(
                                alpha: _currentPhotoIndex == index ? 1.0 : 0.5,
                              ),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      ),
                    ),

                  // "NEW" Badge
                  if (isNew)
                    Positioned(
                      top: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFA4E4C1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'NEW',
                          style: GoogleFonts.spaceMono(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF004B3A),
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                    ),

                  // Match Score Ring (top right)
                  Positioned(
                    top: 12,
                    right: 12,
                    child: _buildMatchGauge(score),
                  ),

                  // ── SOCIAL PROOF: RECENTLY ACTIVE ──
                  Positioned(
                    top: isNew ? 44 : 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.2),
                          width: 0.5,
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _ActivePillPulse(),
                          SizedBox(width: 4),
                          Text(
                            'RECENTLY ACTIVE',
                            style: TextStyle(
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ── SOCIAL PROOF: HIGH MATCH PROBABILITY ──
                  if (score >= 88)
                    Positioned(
                      bottom: 84, // slightly above photo indicator dots
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF2C233),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(LucideIcons.sparkles,
                                size: 10, color: Colors.black),
                            const SizedBox(width: 4),
                            Text(
                              'HIGH MATCH PROBABILITY',
                              style: GoogleFonts.spaceMono(
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // ── DYNAMIC SWIPE OVERLAYS ──
                  if (widget.isFront && widget.dragOffset.dx != 0)
                    Positioned.fill(
                      child: AnimatedContainer(
                        duration: Duration.zero,
                        decoration: BoxDecoration(
                          color: widget.dragOffset.dx > 0 
                            ? const Color(0xFF4CB572).withValues(alpha: (widget.dragOffset.dx / 150).clamp(0.0, 0.4)) // Green tint for LIKE
                            : const Color(0xFFE8437A).withValues(alpha: (widget.dragOffset.dx.abs() / 150).clamp(0.0, 0.4)), // Pink tint for NOPE
                        ),
                      ),
                    ),

                  // LIKE label on right drag
                  if (widget.isFront && widget.dragOffset.dx > 12)
                    Positioned(
                      top: 40,
                      left: 24,
                      child: Transform.rotate(
                        angle: -0.15,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            border: Border.all(color: const Color(0xFF4CB572), width: 3.5),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text('LIKE',
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 32,
                                fontWeight: FontWeight.w900,
                                color: const Color(0xFF4CB572),
                                letterSpacing: 3,
                              )),
                        ),
                      ),
                    ),

                  // NOPE label on left drag
                  if (widget.isFront && widget.dragOffset.dx < -12)
                    Positioned(
                      top: 40,
                      right: 24,
                      child: Transform.rotate(
                        angle: 0.15,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            border: Border.all(color: const Color(0xFFE8437A), width: 3.5),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text('NOPE',
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 32,
                                fontWeight: FontWeight.w900,
                                color: const Color(0xFFE8437A),
                                letterSpacing: 3,
                              )),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // ── INFO PANEL (40%) — personality-forward  ──────────
            Expanded(
              flex: 40,
              child: Container(
                width: double.infinity,
                color: isLight ? const Color(0xFFF5F0E8) : const Color(0xFF0D1A13),
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ── HOT MATCH INDICATOR ──
                    if (score >= 90)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          children: [
                            const Icon(LucideIcons.flame, size: 14, color: Color(0xFFF2C233)),
                            const SizedBox(width: 6),
                            Text(
                              'HOT MATCH',
                              style: GoogleFonts.spaceMono(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFFF2C233),
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                        ),
                      ),

                    // ── CONVERSATION STARTER / BIO CARD ──
                    if (bio != null && bio.isNotEmpty)
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                          decoration: BoxDecoration(
                            color: isLight
                                ? const Color(0xFFFFF8E1).withValues(alpha: 0.7)
                                : const Color(0xFF1A1A0F),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isLight
                                  ? const Color(0xFFF2C233).withValues(alpha: 0.4)
                                  : const Color(0xFF3A3520),
                              width: 0.5,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    LucideIcons.trophy,
                                    size: 10,
                                    color: Color(0xFFF2C233),
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    'WORLD CUP DREAM',
                                    style: GoogleFonts.spaceMono(
                                      fontSize: 9,
                                      color: const Color(0xFFF2C233),
                                      letterSpacing: 1.5,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                bio,
                                style: GoogleFonts.inter(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w400,
                                  color: isLight
                                      ? TurfArdorColors.textPrimaryLight
                                      : Colors.white.withValues(alpha: 0.88),
                                  height: 1.45,
                                ),
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      // Empty bio prompt
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                        decoration: BoxDecoration(
                          color: isLight ? const Color(0xFFF0EBE3) : const Color(0xFF152B1E),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(LucideIcons.sparkles, size: 14, color: Color(0xFFF2C233)),
                            const SizedBox(width: 8),
                            Text(
                              'New fan — no bio yet',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontStyle: FontStyle.italic,
                                color: muted,
                              ),
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 8),

                    // ── INTEREST TAGS ──
                    if (interests.isNotEmpty)
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        child: Row(
                          children: interests.map((tag) => Container(
                            margin: const EdgeInsets.only(right: 6),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: _tagBackground(tag),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              tag.toUpperCase(),
                              style: GoogleFonts.spaceMono(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: _tagText(tag),
                                letterSpacing: 0.5,
                              ),
                            ),
                          )).toList(),
                        ),
                      ),

                    // ── SOCIAL PROOF (FOMO) — for higher scores ──
                    if (score >= 75) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(LucideIcons.flame,
                              size: 14, color: Color(0xFFC62828)),
                          const SizedBox(width: 6),
                          Text(
                            'Popular — ${3 + (score ~/ 20)} fans liked this profile',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color:
                                  const Color(0xFFC62828).withValues(alpha: 0.7),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );

    // Apply parallax tilt on drag (only for front card)
    if (widget.isFront && widget.dragOffset != Offset.zero) {
      card = Transform(
        alignment: Alignment.center,
        transform: Matrix4.identity()
          ..setEntry(3, 2, 0.001) // perspective
          ..rotateZ(widget.dragOffset.dx * 0.0002), // subtle tilt
        child: card,
      );
    }

    // Wrap with gold Most Compatible treatment
    if (widget.isMostCompatible) {
      card = Stack(
        children: [
          // Gold border outer container
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: const Color(0xFFF2C233),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFF2C233).withValues(alpha: 0.25),
                  blurRadius: 20,
                  spreadRadius: 2,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: card,
            ),
          ),
          // Crown banner overlay at top of card
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 14),
              decoration: BoxDecoration(
                color: const Color(0xFFF2C233).withValues(alpha: 0.15),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(22),
                  topRight: Radius.circular(22),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    LucideIcons.crown,
                    size: 13,
                    color: Color(0xFFF2C233),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'MOST COMPATIBLE',
                    style: GoogleFonts.spaceMono(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFFF2C233),
                      letterSpacing: 2.0,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return RepaintBoundary(child: card);
  }

  Widget _buildPhotoPlaceholder(String name, String nationality) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1E4A33), Color(0xFF0D1A13)],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF4CB572).withValues(alpha: 0.2),
                border: Border.all(color: const Color(0xFF4CB572), width: 2),
              ),
              child: Center(
                child: Text(
                  initial,
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMatchGauge(int score) {
    final isHighMatch = score >= 80;
    final gaugeColor = isHighMatch ? const Color(0xFFF2C233) : const Color(0xFFD1E8E2);
    
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: score / 100),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 44,
              height: 44,
              child: CircularProgressIndicator(
                value: 1.0,
                strokeWidth: 3,
                color: gaugeColor.withValues(alpha: 0.2),
              ),
            ),
            SizedBox(
              width: 44,
              height: 44,
              child: CircularProgressIndicator(
                value: value,
                strokeWidth: 3,
                color: gaugeColor,
              ),
            ),
            Text(
              score.toString(),
              style: GoogleFonts.spaceMono(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                shadows: [
                  Shadow(
                    color: Colors.black.withValues(alpha: 0.5),
                    offset: const Offset(0, 1),
                    blurRadius: 2,
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _VerifiedPulse extends StatefulWidget {
  const _VerifiedPulse();

  @override
  State<_VerifiedPulse> createState() => _VerifiedPulseState();
}

class _VerifiedPulseState extends State<_VerifiedPulse> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.7, end: 1.0).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animation,
      child: const Icon(LucideIcons.badgeCheck, size: 20, color: Color(0xFF4CB572)),
    );
  }
}

class _ActivePillPulse extends StatefulWidget {
  const _ActivePillPulse();

  @override
  State<_ActivePillPulse> createState() => _ActivePillPulseState();
}

class _ActivePillPulseState extends State<_ActivePillPulse>
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
          width: 6,
          height: 6,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Color(0xFF4CB572),
          ),
        ),
      ),
    );
  }
}
