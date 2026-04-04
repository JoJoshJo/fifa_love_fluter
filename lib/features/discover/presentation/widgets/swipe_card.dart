import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/constants/colors.dart';

class SwipeCard extends StatelessWidget {
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

  static const _vignetteGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.center,
    colors: [
      Color(0x4D000000), // black 0.3
      Colors.transparent,
    ],
  );

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;

    final avatarUrl = profile['avatar_url'] as String?;
    final name = profile['name'] as String? ?? '';
    final age = profile['age'] as int? ?? 0;
    final nationality = profile['nationality'] as String? ?? '';
    final city = profile['city'] as String?;
    final interests = List<String>.from(profile['interests'] ?? []);
    final score = (profile['match_score'] as num?)?.toInt() ?? 0;
    final isVerified = profile['is_verified'] as bool? ?? false;
    final photoUrls = List<String>.from(profile['photo_urls'] ?? []);
    final createdAtStr = profile['created_at'] as String?;
    final createdAt = createdAtStr != null ? DateTime.tryParse(createdAtStr) : null;
    final isNew = createdAt != null && DateTime.now().difference(createdAt).inDays <= 7;

    // Stack transforms
    Widget card = Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isLight ? 0.12 : 0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // Main card content
            Column(
              children: [
                // PHOTO — top 60%
                Expanded(
                  flex: 60,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Photo or flag fallback
                      avatarUrl != null
                          ? CachedNetworkImage(
                              imageUrl: avatarUrl,
                              fit: BoxFit.cover,
                              memCacheWidth: 400,
                              memCacheHeight: 500,
                            )
                          : _FlagFallback(
                              nationality: nationality,
                              isLight: isLight,
                            ),

                      // Top vignette
                      const Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: _vignetteGradient,
                          ),
                        ),
                      ),

                      // NO PHOTO BOTTOM GRADIENT for readability
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

                      // Carousel Dots
                      if (photoUrls.length > 1)
                        Positioned(
                          bottom: 12,
                          left: 0,
                          right: 0,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(photoUrls.length, (index) {
                              final isActive = index == 0; // Simple fallback for now
                              return Container(
                                width: isActive ? 8 : 6,
                                height: 3,
                                margin: const EdgeInsets.symmetric(horizontal: 2),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(2),
                                  color: isActive
                                      ? Colors.white
                                      : Colors.white.withValues(alpha: 0.5),
                                ),
                              );
                            }),
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

                      // Verified label (original) - adjusted position if NEW badge exists
                      if (isVerified)
                        Positioned(
                          top: isNew ? 40 : 14,
                          left: 14,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: const Color(0xFF135E4B),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: const Color(0xFF4CB572), width: 1),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.check,
                                    size: 11, color: Color(0xFF4CB572)),
                                const SizedBox(width: 4),
                                Text('VERIFIED',
                                    style: GoogleFonts.spaceMono(
                                      fontSize: 9,
                                      color: const Color(0xFF4CB572),
                                    )),
                              ],
                            ),
                          ),
                        ),

                      // Match Score Ring Gauge
                      Positioned(
                        top: 12,
                        right: 12,
                        child: TweenAnimationBuilder<double>(
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
                                    color: const Color(0xFF5A4500),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),

                      // Swipe Labels (LIKE/NOPE) based on drag
                      if (isFront && dragOffset.dx > 20)
                        Positioned(
                          top: 24,
                          left: 20,
                          child: Transform.rotate(
                            angle: -0.1,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                border: Border.all(
                                    color: const Color(0xFF4CB572), width: 2.5),
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

                      if (isFront && dragOffset.dx < -20)
                        Positioned(
                          top: 24,
                          right: 20,
                          child: Transform.rotate(
                            angle: 0.1,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                border: Border.all(
                                    color: const Color(0xFFE8437A), width: 2.5),
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
                    color: isLight
                        ? const Color(0xFFF5F0E8)
                        : const Color(0xFF0D1A13),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Name + age + score
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Name
                                  Row(
                                    children: [
                                      Text(name,
                                          style: GoogleFonts.playfairDisplay(
                                            fontSize: 28,
                                            fontWeight: FontWeight.w700,
                                            color: isLight
                                                ? FifaColors.textPrimaryLight
                                                : Colors.white,
                                            height: 1.1,
                                          )),
                                      if (isVerified) ...[
                                        const SizedBox(width: 6),
                                        const _VerifiedPulse(),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 3),
                                  // Age + nationality
                                  Row(children: [
                                    Text(
                                        '$age  ·  '
                                        '${_flag(nationality)}'
                                        ' $nationality',
                                        style: GoogleFonts.inter(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          color: isLight
                                              ? FifaColors.emeraldSpring
                                              : FifaColors.accent,
                                        )),
                                  ]),
                                  if (city != null && city.isNotEmpty) ...[
                                    const SizedBox(height: 2),
                                    Row(children: [
                                      Icon(Icons.location_on_outlined,
                                          size: 12,
                                          color: isLight
                                              ? const Color(0xFF9BB3AF)
                                              : Colors.white
                                                  .withValues(alpha: 0.3)),
                                      const SizedBox(width: 3),
                                      Text(city,
                                          style: GoogleFonts.inter(
                                            fontSize: 12,
                                            color: isLight
                                                ? const Color(0xFF9BB3AF)
                                                : Colors.white
                                                    .withValues(alpha: 0.35),
                                          )),
                                    ]),
                                  ],
                                ],
                              ),
                            ),
                            // Premium Zap Score
                            Column(
                              children: [
                                const Icon(LucideIcons.zap, color: FifaColors.gold, size: 24),
                                const SizedBox(height: 4),
                                Text('$score%',
                                    style: GoogleFonts.spaceMono(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: FifaColors.gold)),
                              ],
                            ),
                          ],
                        ),
                        const Spacer(),
                        if (interests.isNotEmpty)
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: interests.take(3).map((interest) {
                              final isFootballTag = [
                                'STADIUM',
                                'MAN CITY',
                                'REAL MADRID',
                                'ARSENAL',
                                'CHELSEA',
                                'LIVERPOOL',
                                'FOOTBALL',
                                'FIFA',
                                'SOCCER',
                              ].contains(interest.toUpperCase());

                              return Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: isFootballTag
                                      ? FifaColors.mint
                                      : FifaColors.roseWhisper,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  interest.toUpperCase(),
                                  style: GoogleFonts.spaceMono(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w600,
                                    color: isFootballTag
                                        ? FifaColors.accentDark
                                        : const Color(0xFF8A3058),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    // Apply stack transforms
    if (stackPosition == 1) {
      card = Transform.scale(
        scale: 0.95,
        child: Transform.translate(
          offset: const Offset(0, -12),
          child: Opacity(opacity: 0.8, child: card),
        ),
      );
    } else if (stackPosition == 2) {
      card = Transform.scale(
        scale: 0.90,
        child: Transform.translate(
          offset: const Offset(0, -24),
          child: Opacity(opacity: 0.5, child: card),
        ),
      );
    }

    // Apply parallax tilt on drag (only for front card)
    if (isFront && dragOffset != Offset.zero) {
      card = Transform(
        alignment: Alignment.center,
        transform: Matrix4.identity()
          ..setEntry(3, 2, 0.001) // perspective
          ..rotateZ(dragOffset.dx * 0.0002), // subtle tilt
        child: card,
      );
    }

    return RepaintBoundary(child: card);
  }

  // Flag helper
  String _flag(String nationality) {
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
    return flags[nationality] ?? '🌍';
  }
}

class _FlagFallback extends StatelessWidget {
  final String nationality;
  final bool isLight;
  const _FlagFallback({
    required this.nationality,
    required this.isLight,
  });

  @override
  Widget build(BuildContext context) {
    final flags = {
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
      'Benin': '🇧🇯',
    };
    final flag = flags[nationality] ?? '🌍';

    return Container(
      decoration: const BoxDecoration(
        gradient: _flagGradient,
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(flag, style: const TextStyle(fontSize: 88)),
            const SizedBox(height: 12),
            Text(nationality,
                style: GoogleFonts.playfairDisplay(
                  fontSize: 18,
                  fontStyle: FontStyle.italic,
                  color: Colors.white.withValues(alpha: 0.5),
                )),
          ],
        ),
      ),
    );
  }

  static const _flagGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF135E4B),
      Color(0xFF0A2018),
    ],
  );
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
      child: const Icon(LucideIcons.badgeCheck, size: 16, color: Color(0xFF4CB572)),
    );
  }
}
