import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:page_transition/page_transition.dart';

import '../../../core/widgets/particle_background.dart';
import '../../../core/constants/colors.dart';
import 'signup_screen.dart';
import 'signin_screen.dart';

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          // LAYER 1 — Background
          _heroBackground(context),
          
          // LAYER 1.5 — Particles
          const Positioned.fill(
            child: ParticleBackground(),
          ),
          
          // LAYER 2 — Content
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 48, left: 24, right: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // A) Eyebrow label
                    Text(
                      'FIFA WORLD CUP 2026',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.spaceMono(
                        fontSize: 10,
                        color: isLight ? FifaColors.emeraldForest : const Color(0xFFA1D8B5),
                        letterSpacing: 4.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // B) App name
                    Text(
                      'FIFA LOVE',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 52,
                        fontWeight: FontWeight.bold,
                        color: isLight ? FifaColors.emeraldForest : const Color(0xFFF2C233),
                        letterSpacing: 2.0,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // C) Subtitle
                    Text(
                      'Match Across Borders',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.55),
                      ),
                    ),

                    // D) Spacer 40px
                    const SizedBox(height: 40),

                    // E) Create Account button
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          PageTransition(
                            type: PageTransitionType.fade,
                            child: const SignupScreen(),
                          ),
                        );
                      },
                      child: const Text('Create Account'),
                    ),

                    // F) Gap 12px
                    const SizedBox(height: 12),

                    // G) Sign In button
                    OutlinedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          PageTransition(
                            type: PageTransitionType.fade,
                            child: const SignInScreen(),
                          ),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: isLight ? FifaColors.emeraldForest.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.2),
                        ),
                        foregroundColor: theme.textTheme.bodyLarge?.color,
                        minimumSize: const Size(double.infinity, 56),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text('Sign In'),
                    ),

                    // H) Gap 32px
                    const SizedBox(height: 32),

                    // I) Safety badge row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '🔒 18+ · ID Verified · Safe',
                          style: GoogleFonts.spaceMono(
                            fontSize: 10,
                            color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.3),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _heroBackground(BuildContext context) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;
    
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topCenter,
            radius: 1.2,
            colors: [
              FifaColors.emeraldSpring.withValues(alpha: isLight ? 0.1 : 0.3),
              theme.scaffoldBackgroundColor,
            ],
          ),
        ),
      ),
    );
  }
}
