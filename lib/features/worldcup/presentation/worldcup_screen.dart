import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class WorldCupScreen extends StatelessWidget {
  const WorldCupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080F0C),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.emoji_events_outlined,
              size: 48,
              color: Color(0xFF4CB572),
            ),
            const SizedBox(height: 16),
            Text(
              'WORLD CUP',
              style: GoogleFonts.spaceGrotesk(
                fontWeight: FontWeight.bold,
                fontSize: 24,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Schedule, food, safety, rides',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.white.withValues(alpha: 0.4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
