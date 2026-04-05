import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/constants/colors.dart';

class SwipeCard extends StatefulWidget {
  final Map<String, dynamic> profile;
  final bool isFront;
  final int stackPosition; // 0 = front, 1 = middle, 2 = back
  final Offset dragOffset; // drag amount in pixels

  const SwipeCard({
    super.key,
    required this.profile,
    required this.isFront,
    this.stackPosition = 0,
    this.dragOffset = Offset.zero,
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
    return const Color(0xFFE8F5EE); // Default
  }

  Color _tagText(String tag) {
    final t = tag.toLowerCase();
    const sportTags = ['football', 'soccer', 'sports', 'gym', 'running', 'basketball', 'fitness', 'cycling'];
    const cultureTags = ['samba', 'music', 'nightlife', 'dancing', 'art', 'photography', 'cooking', 'travel', 'fashion'];
    const outdoorTags = ['beach', 'hiking', 'nature', 'surfing', 'yoga', 'gardening', 'camping'];

    if (sportTags.contains(t)) return const Color(0xFF004B3A);
    if (cultureTags.contains(t)) return const Color(0xFF8A3058);
    if (outdoorTags.contains(t)) return const Color(0xFF5A4500);
    return const Color(0xFF135E4B); // Default
  }

  String? _flag(String nationality) {
    const flags = {
      'Brazil': '🇧🇷',
      'France': '🇫🇷',
      'Argentina': '🇦🇷',
      'United States': '🇺🇸',
      'England': '🏴',
      'Germany': '🇩🇪',
      'Spain': '🇪🇸',
      'Portugal': '🇵🇹',
      'Morocco': '🇲🇦',
      'Japan': '🇯🇵',
      'Nigeria': '🇳🇬',
      'Mexico': '🇲🇽',
      'Benin': '🇧🇯',
      'Ghana': '🇬🇭',
      'Senegal': '🇸🇳',
      'Australia': '🇦🇺',
      'South Korea': '🇰🇷',
    };
    return flags[nationality];
  }

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final profile = widget.profile;
    final name = profile['name'] as String? ?? '';
    final age = profile['age'] as int? ?? 0;
    final nationality = profile['nationality'] as String? ?? '';
    final city = profile['city'] as String?;
    final interests = List<String>.from(profile['interests'] ?? []);
    final score = (profile['match_score'] as num?)?.toInt() ?? 0;
    final isVerified = profile['is_verified'] as bool? ?? false;
    final photos = (profile['photo_urls'] as List? ?? [profile['avatar_url']]).whereType<String>().toList();
    final createdAtStr = profile['created_at'] as String?;
    final createdAt = createdAtStr != null ? DateTime.tryParse(createdAtStr) : null;
    final isNew = createdAt != null && DateTime.now().difference(createdAt).inDays <= 7;

    Widget card = Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(
          children: [
            // ── PHOTO SECTION ──────────────────
            Expanded(
              flex: 60,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Photo PageView
                  PageView.builder(
                    itemCount: photos.length,
                    onPageChanged: (i) => setState(() => _currentPhotoIndex = i),
                    itemBuilder: (context, index) {
                      return CachedNetworkImage(
                        imageUrl: photos[index],
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
                          child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                        ),
                      );
                    },
                  ),

                  // PHOTO GRADIENT OVERLAY
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.4),
                          ],
                          stops: const [0.0, 0.5, 1.0],
                        ),
                      ),
                    ),
                  ),

                  // PHOTO CAROUSEL DOTS
                  if (photos.length > 1)
                    Positioned(
                      bottom: 12,
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

                  // Match Score Ring Gauge (Top Right)
                  Positioned(
                    top: 12,
                    right: 12,
                    child: _buildMatchGauge(score),
                  ),

                  // Swipe Labels (LIKE/NOPE) based on drag
                  if (widget.isFront && widget.dragOffset.dx > 20)
                    Positioned(
                      top: 24,
                      left: 20,
                      child: Transform.rotate(
                        angle: -0.1,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            border: Border.all(color: const Color(0xFF4CB572), width: 2.5),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text('LIKE',
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF4CB572),
                                letterSpacing: 2,
                              )),
                        ),
                      ),
                    ),

                  if (widget.isFront && widget.dragOffset.dx < -20)
                    Positioned(
                      top: 24,
                      right: 20,
                      child: Transform.rotate(
                        angle: 0.1,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            border: Border.all(color: const Color(0xFFE8437A), width: 2.5),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text('NOPE',
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFFE8437A),
                                letterSpacing: 2,
                              )),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // INFO PANEL — bottom 40%
            Expanded(
              flex: 40,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
                color: isLight ? const Color(0xFFF5F0E8) : const Color(0xFF0D1A13),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name + verified
                    Row(
                      children: [
                        Text(name,
                            style: GoogleFonts.playfairDisplay(
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              color: isLight ? FifaColors.textPrimaryLight : Colors.white,
                              height: 1.1,
                            )),
                        if (isVerified) ...[
                          const SizedBox(width: 8),
                          const _VerifiedPulse(),
                        ],
                      ],
                    ),
                    const SizedBox(height: 6),
                    // Age + nationality
                    Row(children: [
                      if (_flag(nationality) != null) ...[
                        Text(_flag(nationality)!, style: const TextStyle(fontSize: 14)),
                        const SizedBox(width: 4),
                      ] else ...[
                        const Icon(LucideIcons.globe, size: 14, color: FifaColors.accent),
                        const SizedBox(width: 4),
                      ],
                      Text(
                          '$age  ·  $nationality',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: isLight ? FifaColors.emeraldSpring : FifaColors.accent,
                          )),
                    ]),
                    if (city != null && city.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Row(children: [
                        Icon(Icons.location_on_outlined,
                            size: 12,
                            color: isLight ? const Color(0xFF9BB3AF) : Colors.white.withValues(alpha: 0.3)),
                        const SizedBox(width: 3),
                        Text(city,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: isLight ? const Color(0xFF9BB3AF) : Colors.white.withValues(alpha: 0.35),
                            )),
                      ]),
                    ],
                    const SizedBox(height: 12),
                    // Interests Row
                    if (interests.isNotEmpty)
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        child: Row(
                          children: interests.map((tag) => Container(
                            margin: const EdgeInsets.only(right: 6),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );

    // Apply stack transforms
    if (widget.stackPosition == 1) {
      card = Transform.scale(
        scale: 0.95,
        child: Transform.translate(
          offset: const Offset(0, -12),
          child: Opacity(opacity: 0.8, child: card),
        ),
      );
    } else if (widget.stackPosition == 2) {
      card = Transform.scale(
        scale: 0.90,
        child: Transform.translate(
          offset: const Offset(0, -24),
          child: Opacity(opacity: 0.5, child: card),
        ),
      );
    }

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

    return RepaintBoundary(child: card);
  }

  Widget _buildMatchGauge(int score) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: score / 100),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            // Background ring
            SizedBox(
              width: 44,
              height: 44,
              child: CircularProgressIndicator(
                value: 1.0,
                strokeWidth: 3,
                color: const Color(0xFFF2C233).withValues(alpha: 0.2),
              ),
            ),
            // Foreground ring
            SizedBox(
              width: 44,
              height: 44,
              child: CircularProgressIndicator(
                value: value,
                strokeWidth: 3,
                color: const Color(0xFFF2C233),
              ),
            ),
            Text(
              score.toString(),
              style: GoogleFonts.spaceMono(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.white, // Changed to white for readability on dark photo gradient
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
