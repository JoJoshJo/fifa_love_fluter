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
      body: Stack(
        fit: StackFit.expand,
        children: [
          // BACKGROUND — Cinematic gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF0A1F14), // deep forest top
                  Color(0xFF061A0E), // darker middle
                  Color(0xFF0D0A1A), // hint of dark purple at bottom
                ],
                stops: [0.0, 0.5, 1.0],
              ),
            ),
          ),

          // PARTICLE SYSTEM
          const ParticleBackground(),

          Positioned.fill(
            child: SingleChildScrollView(
              child: SafeArea(
                child: Column(
                  children: [
                  const SizedBox(height: 60),

                  // TOP — Countdown Pill
                  _animatedElement(
                    startPercent: 0.0,
                    endPercent: 0.3, // 600ms
                    slideOffset: -0.3, // Slide down
                    child: Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                              size: 14, color: Color(0xFFF2C233)),
                          const SizedBox(width: 8),
                          Text(
                            'World Cup 2026 · $_daysLeft days',
                            style: GoogleFonts.spaceMono(
                              fontSize: 11,
                              color: const Color(0xFFF2C233),
                              letterSpacing: 1.0,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 48),

                  // CENTER — Icons
                  _animatedElement(
                    startPercent: 0.15,
                    endPercent: 0.4, // delay 300ms, duration 500ms
                    isScale: true,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(LucideIcons.heart,
                            size: 32, color: Color(0xFFE8437A)),
                        Transform.translate(
                          offset: const Offset(-8, 0),
                          child: const Icon(LucideIcons.trophy,
                              size: 28, color: Color(0xFFF2C233)),
                        ),
                      ],
                    ),
                  ),

                  // CENTER — Hero Image
                  _animatedElement(
                    startPercent: 0.2,
                    endPercent: 0.5,
                    isScale: true,
                    child: SizedBox(
                      height: 340,
                      width: double.infinity,
                      child: Stack(
                        children: [
                          // Image — full bleed, no border radius
                          Positioned.fill(
                            child: Image.asset(
                              'assets/images/hero_couple.png',
                              fit: BoxFit.cover,
                            ),
                          ),
                          // Gradient overlay — dissolves ALL edges into background
                          Positioned.fill(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    const Color(0xFF080F0C),           // solid top
                                    const Color(0xFF080F0C).withValues(alpha: 0.0), // clear
                                    const Color(0xFF080F0C).withValues(alpha: 0.0), // clear
                                    const Color(0xFF080F0C),           // solid bottom
                                  ],
                                  stops: const [0.0, 0.15, 0.75, 1.0],
                                ),
                              ),
                            ),
                          ),
                          // Left/right edge fade
                          Positioned.fill(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                  colors: [
                                    const Color(0xFF080F0C).withValues(alpha: 0.6),
                                    const Color(0xFF080F0C).withValues(alpha: 0.0),
                                    const Color(0xFF080F0C).withValues(alpha: 0.0),
                                    const Color(0xFF080F0C).withValues(alpha: 0.6),
                                  ],
                                  stops: const [0.0, 0.12, 0.88, 1.0],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // CENTER — Title
                  _animatedElement(
                    startPercent: 0.25,
                    endPercent: 0.55, // delay 500ms, duration 600ms
                    slideOffset: 0.2, // Slide up 20px (approx)
                    child: Text(
                      'Turf&Ardor',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 48,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: -1,
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // CENTER — Tagline
                  _animatedElement(
                    startPercent: 0.35,
                    endPercent: 0.65, // delay 700ms, duration 600ms
                    slideOffset: 0.2,
                    child: Text(
                      'Find your match this\nWorld Cup.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w400,
                        color: Colors.white.withValues(alpha: 0.75),
                        height: 1.5,
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // CENTER — Stat line
                  _animatedElement(
                    startPercent: 0.45,
                    endPercent: 0.7, // delay 900ms, duration 500ms
                    slideOffset: 0, // Fade only
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _statDot(const Color(0xFF4CB572)),
                        Text(
                          '  16 host cities  ·  48 nations  ·  1 summer',
                          style: GoogleFonts.spaceMono(
                            fontSize: 10,
                            color: Colors.white.withValues(alpha: 0.4),
                            letterSpacing: 1.0,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 48),

                // BOTTOM — Create Account Button
                _animatedElement(
                  startPercent: 0.55,
                  endPercent: 0.8, // delay 1100ms, duration 500ms
                  slideOffset: 0.5, // Slide up 30px (approx)
                  child: GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      PageTransition(
                        type: PageTransitionType.rightToLeft,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOutCubic,
                        child: const SignupScreen(),
                      ),
                    ),
                    child: Container(
                      width: double.infinity,
                      height: 56,
                      margin: const EdgeInsets.symmetric(horizontal: 24),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(28),
                        gradient: const LinearGradient(
                          colors: [Color(0xFFE8437A), Color(0xFFF8BBD0)],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color:
                                const Color(0xFFE8437A).withValues(alpha: 0.4),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          'Create Account',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // BOTTOM — Sign In Button
                _animatedElement(
                  startPercent: 0.6,
                  endPercent: 0.8, // delay 1200ms, duration 400ms
                  slideOffset: 0.5,
                  child: GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      PageTransition(
                        type: PageTransitionType.rightToLeft,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOutCubic,
                        child: const SignInScreen(),
                      ),
                    ),
                    child: Container(
                      width: double.infinity,
                      height: 56,
                      margin: const EdgeInsets.symmetric(horizontal: 24),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.2)),
                      ),
                      child: Center(
                        child: Text(
                          'Sign In',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // BOTTOM — Global Fan Count (Social Proof)
                _animatedElement(
                  startPercent: 0.65,
                  endPercent: 0.85,
                  slideOffset: 0.5,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(LucideIcons.users,
                          size: 14, color: Color(0xFF4CB572)),
                      const SizedBox(width: 8),
                      Text(
                        'JOIN 1,248 FANS ON TURF&ARDOR TODAY',
                        style: GoogleFonts.spaceMono(
                          fontSize: 9,
                          color: const Color(0xFF4CB572),
                          letterSpacing: 1.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // BOTTOM — Terms
                _animatedElement(
                  startPercent: 0.7,
                  endPercent: 0.9,
                  slideOffset: 0,
                  child: Text(
                    'By continuing, you agree to our Terms & Privacy Policy',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: Colors.white.withValues(alpha: 0.25),
                    ),
                  ),
                ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
}
