import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CompletionBar extends StatelessWidget {
  final int score;
  final List<String> missing;

  const CompletionBar({
    super.key,
    required this.score,
    required this.missing,
  });

  Color _barColor() {
    if (score >= 100) return const Color(0xFF4CB572);
    if (score >= 60) return const Color(0xFFF2C233);
    return const Color(0xFFE83535);
  }

  @override
  Widget build(BuildContext context) {
    if (score >= 100) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: const Color(0xFF135E4B).withValues(alpha: 0.3),
          border: Border.all(
              color: const Color(0xFF4CB572).withValues(alpha: 0.5)),
        ),
        child: Row(
          children: [
            const Icon(Icons.check_circle_outline,
                size: 20, color: Color(0xFF4CB572)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                "Profile complete! You're getting more matches",
                style: GoogleFonts.inter(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.80)),
              ),
            ),
          ],
        ),
      );
    }

    final barColor = _barColor();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1A13),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF1E4A33)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'PROFILE STRENGTH',
                style: GoogleFonts.spaceMono(
                  fontSize: 9,
                  color: const Color(0xFF4CB572),
                  letterSpacing: 1.5,
                ),
              ),
              const Spacer(),
              Text(
                '$score%',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: barColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: score / 100,
              backgroundColor: Colors.white.withValues(alpha: 0.08),
              valueColor: AlwaysStoppedAnimation<Color>(barColor),
              minHeight: 6,
            ),
          ),
          if (missing.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              'Complete your profile to get more matches:',
              style: GoogleFonts.inter(
                  fontSize: 12,
                  color: Colors.white.withValues(alpha: 0.40)),
            ),
            const SizedBox(height: 6),
            ...missing.map((tip) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    children: [
                      Container(
                        width: 4, height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0xFF4CB572),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(tip,
                          style: GoogleFonts.inter(
                              fontSize: 12,
                              color: Colors.white.withValues(alpha: 0.60))),
                    ],
                  ),
                )),
          ],
        ],
      ),
    );
  }
}
