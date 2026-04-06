import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

class RidesTab extends StatefulWidget {
  const RidesTab({super.key});

  @override
  State<RidesTab> createState() => _RidesTabState();
}

class _RidesTabState extends State<RidesTab> {
  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final daysLeft = DateTime(2026, 6, 11).difference(DateTime.now()).inDays;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).padding.bottom + 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          // Globe + Car icon combo
          Stack(
            alignment: Alignment.center,
            children: [
              Icon(
                LucideIcons.globe,
                size: 64,
                color: const Color(0xFFF2C233).withValues(alpha: 0.15),
              ),
              const Icon(
                LucideIcons.car,
                size: 32,
                color: Color(0xFFF2C233),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'COMING SOON',
            style: GoogleFonts.spaceMono(
              fontSize: 10,
              color: const Color(0xFFF2C233),
              letterSpacing: 2.0,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Rides & Transport',
            textAlign: TextAlign.center,
            style: GoogleFonts.playfairDisplay(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: isLight ? const Color(0xFF0D2B1E) : Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              "We're building partnerships with local transport providers in all 16 host cities.",
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: isLight ? const Color(0xFF8B7355) : Colors.white.withValues(alpha: 0.5),
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 32),
          
          // 2026 World Cup Countdown Teaser
          Container(
            padding: const EdgeInsets.all(20),
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
                const SizedBox(height: 8),
                Text(
                  'Transport booking will open 30 days before kickoff.',
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
          
          // Decorative dots
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(width: 4, height: 4, decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFE8437A))),
              const SizedBox(width: 8),
              Container(width: 4, height: 4, decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFF2C233))),
              const SizedBox(width: 8),
              Container(width: 4, height: 4, decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF4CB572))),
            ],
          ),
        ],
      ),
    );
  }
}
