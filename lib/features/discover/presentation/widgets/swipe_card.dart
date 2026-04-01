import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:fifalove_mobile/core/constants/colors.dart';
import 'score_gauge.dart';

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

  String _flagEmoji(String? nationality) {
    const flags = {
      'Brazil': '🇧🇷',
      'France': '🇫🇷',
      'Argentina': '🇦🇷',
      'Nigeria': '🇳🇬',
      'Japan': '🇯🇵',
      'Spain': '🇪🇸',
      'Germany': '🇩🇪',
      'England': '🏴󠁧󠁢󠁥󠁮󠁧󠁿',
      'USA': '🇺🇸',
      'Mexico': '🇲🇽',
      'Portugal': '🇵🇹',
      'Morocco': '🇲🇦',
      'Senegal': '🇸🇳',
      'Canada': '🇨🇦',
      'Australia': '🇦🇺',
      'Netherlands': '🇳🇱',
      'Italy': '🇮🇹',
      'South Korea': '🇰🇷',
      'Ecuador': '🇪🇨',
      'Ghana': '🇬🇭',
    };
    return flags[nationality] ?? '🌍';
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    Widget card = RepaintBoundary(
      child: _buildCard(context, size),
    );

    // Apply stack position transforms for back cards
    if (stackPosition == 1) {
      card = Transform.scale(
        scale: 0.95,
        child: Transform.translate(
          offset: const Offset(0, -12),
          child: Opacity(opacity: 0.7, child: card),
        ),
      );
    } else if (stackPosition == 2) {
      card = Transform.scale(
        scale: 0.90,
        child: Transform.translate(
          offset: const Offset(0, -24),
          child: Opacity(opacity: 0.4, child: card),
        ),
      );
    }

    return card;
  }

  Widget _buildCard(BuildContext context, Size size) {
    final avatarUrl = profile['avatar_url'] as String?;
    final name = profile['name'] as String? ?? 'Unknown';
    final age = profile['age'];
    final nationality = profile['nationality'] as String?;
    final city = profile['city'] as String?;
    final interests = (profile['interests'] as List?)?.cast<String>() ?? [];
    final isVerified = profile['is_verified'] == true;
    final score = (profile['match_score'] as int?) ?? 20;

    // Labels opacity based on drag
    final likeOpacity = isFront ? dragOffset.clamp(0.0, 1.0) : 0.0;
    final nopeOpacity = isFront ? (-dragOffset).clamp(0.0, 1.0) : 0.0;
    final superOpacity = isFront ? (-dragVertical).clamp(0.0, 1.0) : 0.0;

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Layer 1 — Photo or gradient background
          if (avatarUrl != null)
            CachedNetworkImage(
              imageUrl: avatarUrl,
              fit: BoxFit.cover,
              memCacheWidth: 600,
              memCacheHeight: 900,
              maxWidthDiskCache: 800,
              maxHeightDiskCache: 1200,
              placeholder: (_, __) => Container(
                color: Theme.of(context).cardColor,
                child: Center(
                  child: CircularProgressIndicator(
                    color: Theme.of(context).primaryColor,
                    strokeWidth: 2,
                  ),
                ),
              ),
              errorWidget: (context, url, error) => _defaultBackground(context, nationality),
            )
          else
            _defaultBackground(context, nationality),

          // Layer 2 — Bottom gradient overlay
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.transparent,
                    Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.5),
                    Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.98),
                  ],
                  stops: const [0.0, 0.45, 0.70, 1.0],
                ),
              ),
            ),
          ),

          // Layer 3 — Profile info (Glassmorphism)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Theme.of(context).cardColor.withValues(alpha: 0.4),
                        Theme.of(context).cardColor.withValues(alpha: 0.85),
                      ],
                    ),
                    border: Border(
                      top: BorderSide(
                        color: Theme.of(context).dividerColor,
                        width: 0.5,
                      ),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Name + age
                            Row(
                              children: [
                                Text(
                                  name,
                                  style: GoogleFonts.spaceGrotesk(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).textTheme.titleLarge?.color,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  age?.toString() ?? '',
                                  style: GoogleFonts.inter(
                                    fontSize: 22,
                                    color: Theme.of(context).textTheme.titleLarge?.color?.withValues(alpha: 0.6),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            // Nationality + city
                            Row(
                              children: [
                                Text(
                                  '${_flagEmoji(nationality)} ${nationality ?? ''}',
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    color: Theme.of(context).textTheme.bodySmall?.color,
                                  ),
                                ),
                                if (city != null) ...[
                                  Text(
                                    ' · ',
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      color: Theme.of(context).textTheme.bodySmall?.color,
                                    ),
                                  ),
                                  Text(
                                    city,
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.4),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 10),
                            // Interest chips (max 3)
                            Row(
                              children: interests.take(3).map((interest) {
                                return Container(
                                  margin: const EdgeInsets.only(right: 6),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).primaryColor.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(13),
                                    border: Border.all(
                                      color: Theme.of(context).primaryColor.withValues(alpha: 0.25),
                                    ),
                                  ),
                                  child: Text(
                                    interest,
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      color: Theme.of(context).primaryColor,
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Score gauge
                      Column(
                        children: [
                          SizedBox(
                            width: 64,
                            child: ScoreGauge(
                              score: score,
                              size: 64,
                              profile: isFront ? profile : null,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Layer 4 — Verified badge
          if (isVerified)
            Positioned(
              top: 16,
              right: 16,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Theme.of(context).primaryColor),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check,
                        size: 12, color: Theme.of(context).primaryColor),
                    const SizedBox(width: 4),
                    Text(
                      'VERIFIED',
                      style: GoogleFonts.spaceMono(
                        fontSize: 9,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Layer 5 — LIKE label
          if (isFront)
            Positioned(
              top: 48,
              left: 24,
              child: Opacity(
                opacity: likeOpacity,
                child: Transform.rotate(
                  angle: -0.1,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: Theme.of(context).primaryColor, width: 3),
                    ),
                    child: Text(
                      'LIKE',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                ),
              ),
            ),

          // Layer 6 — NOPE label
          if (isFront)
            Positioned(
              top: 48,
              right: 24,
              child: Opacity(
                opacity: nopeOpacity,
                child: Transform.rotate(
                  angle: 0.1,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: FifaColors.pink, width: 3),
                    ),
                    child: Text(
                      'NOPE',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: FifaColors.pink,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                ),
              ),
            ),

          // Layer 7 — SUPER label
          if (isFront)
            Positioned(
              top: 80,
              left: 0,
              right: 0,
              child: Opacity(
                opacity: superOpacity,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: FifaColors.gold, width: 3),
                    ),
                    child: Text(
                      'SUPER ⚡',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: FifaColors.deepBackground,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _defaultBackground(BuildContext context, String? nationality) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).primaryColor.withValues(alpha: 0.8),
            Theme.of(context).scaffoldBackgroundColor,
            Theme.of(context).cardColor,
          ],
          stops: const [0.0, 0.5, 1.0],
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: Opacity(
              opacity: 0.05,
              child: Image.asset(
                'assets/images/grass_pattern.png', // Assuming this exists or using a generic placeholder if not
                repeat: ImageRepeat.repeat,
                errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context).primaryColor.withValues(alpha: 0.2),
                        blurRadius: 40,
                        spreadRadius: 10,
                      ),
                    ],
                  ),
                  child: Text(
                    _flagEmoji(nationality),
                    style: const TextStyle(fontSize: 100),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
