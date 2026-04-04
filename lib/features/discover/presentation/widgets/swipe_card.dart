import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/constants/colors.dart';

class SwipeCard extends StatelessWidget {
  final Map<String, dynamic> profile;
  final bool isFront;
  final int stackPosition; // 0 = front, 1 = middle, 2 = back
  final double dragOffset; // horizontal drag amount (-1 to 1)
  final double dragVertical; // vertical drag amount
  const SwipeCard({
    super.key,
    required this.profile,
    required this.isFront,
    this.stackPosition = 0,
    this.dragOffset = 0,
    this.dragVertical = 0,
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

                      // Verified badge
                      if (isVerified)
                        Positioned(
                          top: 14,
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

                      // Match Score badge
                      Positioned(
                        top: 14,
                        right: 14,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: FifaColors.champagneGlow,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: FifaColors.gold,
                              width: 1,
                            ),
                          ),
                          child: Text(
                            '$score% MATCH',
                            style: GoogleFonts.spaceMono(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF5A4500),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),

                      // Swipe Labels (LIKE/NOPE) based on drag
                      if (isFront && dragOffset > 0.1)
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

                      if (isFront && dragOffset < -0.1)
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
                                        const Icon(LucideIcons.badgeCheck, size: 16, color: Color(0xFF4CB572)),
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
