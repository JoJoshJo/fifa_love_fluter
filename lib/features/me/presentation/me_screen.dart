import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/supabase/supabase_config.dart';

class MeScreen extends StatelessWidget {
  const MeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080F0C),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.person_outline,
              size: 48,
              color: Color(0xFF4CB572),
            ),
            const SizedBox(height: 16),
            Text(
              'ME',
              style: GoogleFonts.spaceGrotesk(
                fontWeight: FontWeight.bold,
                fontSize: 24,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your profile and settings',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.white.withValues(alpha: 0.4),
              ),
            ),
            const SizedBox(height: 48),
            TextButton(
              onPressed: () async {
                await SupabaseConfig.client.auth.signOut();
              },
              child: Text(
                'SIGN OUT',
                style: GoogleFonts.spaceMono(
                  fontSize: 12,
                  color: Colors.white.withValues(alpha: 0.6),
                  letterSpacing: 2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
