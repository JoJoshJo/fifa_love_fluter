import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/router/auth_gate.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeCtrl;
  late AnimationController _pulseCtrl;
  late Animation<double> _logoFade;
  late Animation<double> _textFade;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();

    // Main fade-in sequence
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _logoFade = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _fadeCtrl,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    _textFade = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _fadeCtrl,
        curve: const Interval(0.4, 0.8, curve: Curves.easeOut),
      ),
    );

    // Subtle pulse on logo
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);

    _pulse = Tween(begin: 0.97, end: 1.03).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );

    _fadeCtrl.forward();

    // Navigate to AuthGate after 3 seconds so the user can enjoy the animation
    Future.delayed(const Duration(milliseconds: 3000), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            transitionDuration: const Duration(milliseconds: 1000),
            pageBuilder: (_, __, ___) => const AuthGate(),
            transitionsBuilder: (_, animation, __, child) {
              return FadeTransition(opacity: animation, child: child);
            },
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final bg = isLight ? const Color(0xFFF5F0E8) : const Color(0xFF080F0C);

    return Scaffold(
      backgroundColor: bg,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // === BACKGROUND: Logo image, blended ===
          // This makes the logo PART of the background, not sitting on it
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _pulse,
              builder: (_, child) => Transform.scale(
                scale: _pulse.value,
                child: child,
              ),
              child: FadeTransition(
                opacity: _logoFade,
                child: Container(
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: const AssetImage('assets/splash/splash_logo.png'), // Using the correct transparent logo
                      fit: BoxFit.contain,
                      // KEY: This blends the image into the background
                      colorFilter: ColorFilter.mode(
                        bg.withValues(alpha: 0.15),
                        BlendMode.dstATop,
                      ),
                    ),
                  ),
                  // Radial fade so edges dissolve into background
                  foregroundDecoration: BoxDecoration(
                    gradient: RadialGradient(
                      colors: [
                        bg.withValues(alpha: 0.0),  // clear center
                        bg.withValues(alpha: 0.4),  // soft mid
                        bg.withValues(alpha: 0.95), // near-solid edges
                      ],
                      stops: const [0.2, 0.55, 1.0],
                      radius: 0.75,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // === FOREGROUND: Text ===
          SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                FadeTransition(
                  opacity: _textFade,
                  child: Column(
                    children: [
                      Text(
                        'TURF&ARDOR',
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 32,
                          fontWeight: FontWeight.w700,
                          color: isLight
                              ? const Color(0xFF0D2B1E)
                              : const Color(0xFFEBF2EE),
                          letterSpacing: 3.0,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'WORLD CUP 2026',
                        style: GoogleFonts.spaceMono(
                          fontSize: 10,
                          color: const Color(0xFFF2C233),
                          letterSpacing: 2.0,
                        ),
                      ),
                      const SizedBox(height: 40),
                      // Subtle loading indicator
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: const Color(0xFF4CB572).withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 60),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
