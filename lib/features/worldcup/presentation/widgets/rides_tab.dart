import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/constants/colors.dart';

class RidesTab extends StatefulWidget {
  const RidesTab({super.key});

  @override
  State<RidesTab> createState() => _RidesTabState();
}

class _RidesTabState extends State<RidesTab> {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              LucideIcons.car,
              size: 56,
              color: FifaColors.accent.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 24),
            Text(
              'Rides & Transport',
              style: GoogleFonts.playfairDisplay(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                fontStyle: FontStyle.italic,
                color: Theme.of(context).textTheme.titleLarge?.color?.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'COMING SOON',
              style: GoogleFonts.spaceMono(
                fontSize: 11,
                color: FifaColors.accent,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              "We're building partnerships with local transport providers in all 16 host cities.",
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.35),
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
