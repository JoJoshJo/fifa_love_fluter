import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
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

    Widget card = _buildCard(context, size);

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
              placeholder: (_, __) => Container(
                color: const Color(0xFF152B1E),
                child: const Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFF4CB572),
                    strokeWidth: 2,
                  ),
                ),
              ),
              errorWidget: (_, __, ___) => _defaultBackground(nationality),
            )
          else
            _defaultBackground(nationality),

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
                    const Color(0xFF080F0C).withValues(alpha: 0.5),
                    const Color(0xFF080F0C).withValues(alpha: 0.98),
                  ],
                  stops: const [0.0, 0.45, 0.70, 1.0],
                ),
              ),
            ),
          ),

          // Layer 3 — Profile info
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    const Color(0xFF0D1A13).withValues(alpha: 0.92),
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
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
                                color: const Color(0xFFEBF2EE),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              age?.toString() ?? '',
                              style: GoogleFonts.inter(
                                fontSize: 22,
                                color: const Color(0xFFEBF2EE).withValues(alpha: 0.6),
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
                                color: const Color(0xFF9BB3AF),
                              ),
                            ),
                            if (city != null) ...[
                              Text(
                                ' · ',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: const Color(0xFF9BB3AF),
                                ),
                              ),
                              Text(
                                city,
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: const Color(0xFFEBF2EE).withValues(alpha: 0.4),
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
                                color: const Color(0xFF4CB572).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(13),
                                border: Border.all(
                                  color: const Color(0xFF4CB572).withValues(alpha: 0.25),
                                ),
                              ),
                              child: Text(
                                interest,
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: const Color(0xFFA1D8B5),
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

          // Layer 4 — Verified badge
          if (isVerified)
            Positioned(
              top: 16,
              right: 16,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF135E4B),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF4CB572)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check,
                        size: 12, color: Color(0xFF4CB572)),
                    const SizedBox(width: 4),
                    Text(
                      'VERIFIED',
                      style: GoogleFonts.spaceMono(
                        fontSize: 9,
                        color: const Color(0xFF4CB572),
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
                          color: const Color(0xFF4CB572), width: 3),
                    ),
                    child: Text(
                      'LIKE',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF4CB572),
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
                          color: const Color(0xFFE83535), width: 3),
                    ),
                    child: Text(
                      'NOPE',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFFE83535),
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
                          color: const Color(0xFFF2C233), width: 3),
                    ),
                    child: Text(
                      'SUPER ⚡',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFFF2C233),
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

  Widget _defaultBackground(String? nationality) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF135E4B), Color(0xFF0D1A13)],
        ),
      ),
      child: Center(
        child: Text(
          _flagEmoji(nationality),
          style: const TextStyle(fontSize: 80),
        ),
      ),
    );
  }
}
