import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:page_transition/page_transition.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/widgets/particle_background.dart';
import 'signup_screen.dart';
import 'signin_screen.dart';

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late int _daysLeft;

  @override
  void initState() {
    super.initState();
    _daysLeft = DateTime(2026, 6, 11).difference(DateTime.now()).inDays;
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _animatedElement({
    required Widget child,
    required double startPercent,
    required double endPercent,
    bool isScale = false,
    double slideOffset = 0.3,
  }) {
    final animation = CurvedAnimation(
      parent: _controller,
      curve: Interval(startPercent, endPercent, curve: Curves.easeOutCubic),
    );

    Widget widget = child;

    if (isScale) {
      widget = ScaleTransition(
        scale: Tween<double>(begin: 0.5, end: 1.0).animate(animation),
        child: widget,
      );
    } else {
      widget = SlideTransition(
        position: Tween<Offset>(
          begin: Offset(0, slideOffset),
          end: Offset.zero,
        ).animate(animation),
        child: widget,
      );
    }

    return FadeTransition(
      opacity: animation,
      child: widget,
    );
  }

  Widget _statDot(Color color) => Container(
        width: 6,
        height: 6,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080F0C),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // LAYER 1: Full bleed background image
          Positioned.fill(
            child: Image.asset(
              'assets/images/hero_couple.png',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(color: Colors.black),
            ),
          ),

          // LAYER 2: Dark gradient overlay so text is readable
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF080F0C).withValues(alpha: 0.3),  // slight dark top
                    const Color(0xFF080F0C).withValues(alpha: 0.0),  // clear middle (show the couple)
                    const Color(0xFF080F0C).withValues(alpha: 0.7),  // darken below couple
                    const Color(0xFF080F0C).withValues(alpha: 0.95), // near solid at bottom for buttons
                  ],
                  stops: const [0.0, 0.25, 0.55, 0.75],
                ),
              ),
            ),
          ),          // 2. PARTICLE SYSTEM (Sitting on image)
          const ParticleBackground(),

          // 3. FOREGROUND CONTENT — Proportional Layout
          Positioned.fill(
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    // --- TOP SECTION ---
                    const SizedBox(height: 12),
                    _animatedElement(
                      startPercent: 0.0,
                      endPercent: 0.3,
                      slideOffset: -0.3,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: const Color(0xFFF2C233).withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(LucideIcons.trophy,
                                size: 12, color: Color(0xFFF2C233)),
                            const SizedBox(width: 6),
                            Text(
                              'World Cup 2026 · $_daysLeft days',
                              style: GoogleFonts.spaceMono(
                                fontSize: 10,
                                color: const Color(0xFFF2C233),
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Spacer(flex: 2),

                    // --- CENTER SECTION ---
                    _animatedElement(
                      startPercent: 0.25,
                      endPercent: 0.55,
                      slideOffset: 0.2,
                      child: Column(
                        children: [
                          Text(
                            'Turf&Ardor',
                            style: GoogleFonts.playfairDisplay(
                              fontSize: 38,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: -1,
                              shadows: [
                                Shadow(
                                  color: Colors.black.withValues(alpha: 0.5),
                                  blurRadius: 30,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Find your match\nthis World Cup.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.w400,
                              color: Colors.white.withValues(alpha: 0.8),
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _statDot(const Color(0xFF4CB572)),
                              Text(
                                '  16 cities  ·  48 nations  ·  1 summer',
                                style: GoogleFonts.spaceMono(
                                  fontSize: 8,
                                  color: Colors.white.withValues(alpha: 0.5),
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const Spacer(flex: 3),

                    // --- BOTTOM SECTION ---
                    _animatedElement(
                      startPercent: 0.55,
                      endPercent: 0.9,
                      slideOffset: 0.5,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _actionButton(
                            onTap: () => Navigator.push(
                              context,
                              PageTransition(
                                type: PageTransitionType.rightToLeft,
                                child: const SignupScreen(),
                              ),
                            ),
                            margin: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              'Create Account',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            gradient: const LinearGradient(
                              colors: [Color(0xFFE8437A), Color(0xFFF8BBD0)],
                            ),
                            showShadow: true,
                          ),
                          const SizedBox(height: 8),
                          _actionButton(
                            onTap: () => Navigator.push(
                              context,
                              PageTransition(
                                type: PageTransitionType.rightToLeft,
                                child: const SignInScreen(),
                              ),
                            ),
                            margin: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              'Sign In',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Colors.white.withValues(alpha: 0.9),
                              ),
                            ),
                            border: Border.all(
                                color: Colors.white.withValues(alpha: 0.2)),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(LucideIcons.users,
                                  size: 10, color: Color(0xFF4CB572)),
                              const SizedBox(width: 8),
                              Text(
                                'JOIN 1,248 FANS TODAY',
                                style: GoogleFonts.spaceMono(
                                  fontSize: 8,
                                  color: const Color(0xFF4CB572),
                                  letterSpacing: 1.2,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Terms & Privacy Policy',
                            style: GoogleFonts.inter(
                              fontSize: 9,
                              color: Colors.white.withValues(alpha: 0.25),
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                      ),
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

  // Refactored Button Widget for cleanliness
  Widget _actionButton({
    required VoidCallback onTap,
    required Widget child,
    Gradient? gradient,
    BoxBorder? border,
    bool showShadow = false,
    EdgeInsetsGeometry? margin,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 52, // Slightly more compact
        margin: margin ?? const EdgeInsets.symmetric(horizontal: 24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(26),
          gradient: gradient,
          border: border,
          boxShadow: showShadow
              ? [
                  BoxShadow(
                    color: const Color(0xFFE8437A).withValues(alpha: 0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ]
              : null,
        ),
        child: Center(child: child),
      ),
    );
  }
}
