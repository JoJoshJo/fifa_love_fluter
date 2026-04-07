import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:fifalove_mobile/core/constants/colors.dart';

class MatchOverlay extends StatefulWidget {
  final Map<String, dynamic> matchedProfile;
  final String? myAvatarUrl;
  final VoidCallback onMessage;
  final VoidCallback onKeepSwiping;

  const MatchOverlay({
    super.key,
    required this.matchedProfile,
    required this.myAvatarUrl,
    required this.onMessage,
    required this.onKeepSwiping,
  });

  @override
  State<MatchOverlay> createState() => _MatchOverlayState();
}

class _MatchOverlayState extends State<MatchOverlay>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _confettiController;
  late AnimationController _heartbeatController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _heartbeatAnimation;
  late List<_ConfettiDot> _dots;
  Timer? _autoDismiss;

  @override
  void initState() {
    super.initState();

    // Pulse animation for heart icon
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _pulseAnimation =
        Tween<double>(begin: 0.9, end: 1.1).animate(_pulseController);

    // Heartbeat animation for avatars
    _heartbeatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat();
    _heartbeatAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.15), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 1.15, end: 1.0), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.2), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 1.2, end: 1.0), weight: 40),
    ]).animate(CurvedAnimation(
      parent: _heartbeatController,
      curve: Curves.easeInOut,
    ));

    // Confetti animation
    _confettiController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    // Generate confetti dots
    final rand = Random();
    _dots = List.generate(40, (i) {
      final colors = [
        TurfArdorColors.gold,
        Colors.white,
        const Color(0xFFF8BBD0), // faint pink
      ];
      return _ConfettiDot(
        x: rand.nextDouble(),
        startY: -0.1 - rand.nextDouble() * 0.5,
        size: 4 + rand.nextDouble() * 6,
        color: colors[i % colors.length],
        speed: 0.3 + rand.nextDouble() * 0.7,
      );
    });

    // Auto dismiss after 8 seconds
    _autoDismiss = Timer(const Duration(seconds: 8), () {
      if (mounted) widget.onKeepSwiping();
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _confettiController.dispose();
    _heartbeatController.dispose();
    _autoDismiss?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final matchedName = widget.matchedProfile['name'] ?? 'your match';
    final matchedAvatarUrl = widget.matchedProfile['avatar_url'] as String?;

    return Material(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFC62828), // Deep Red
              Color(0xFFE8437A), // Pink
            ],
          ),
        ),
      child: Stack(
        children: [
          // Confetti layer
          AnimatedBuilder(
            animation: _confettiController,
            builder: (_, __) {
              return CustomPaint(
                size: Size(size.width, size.height),
                painter: _ConfettiPainter(
                  dots: _dots,
                  progress: _confettiController.value,
                ),
              );
            },
          ),

          // Main content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Overlapping Avatar pair
                  SizedBox(
                    height: 80,
                    width: 140,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Positioned(
                          left: 0,
                          child: ScaleTransition(
                            scale: _heartbeatAnimation,
                            child: _buildAvatar(widget.myAvatarUrl),
                          ),
                        ),
                        Positioned(
                          right: 0,
                          child: ScaleTransition(
                            scale: _heartbeatAnimation,
                            child: _buildAvatar(matchedAvatarUrl),
                          ),
                        ),
                        // Small floating heart in middle
                        Center(
                          child: ScaleTransition(
                            scale: _pulseAnimation,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                LucideIcons.heart,
                                size: 16,
                                color: Color(0xFFE8437A),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // "IT'S A MATCH!" heading with gradient text (Heartbeat)
                  ScaleTransition(
                    scale: _heartbeatAnimation,
                    child: Column(
                      children: [
                        Text(
                          "IT'S A MATCH!",
                          textAlign: TextAlign.center,
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 32,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            height: 1.0,
                            letterSpacing: -1,
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Compatibility score badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: TurfArdorColors.gold,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(LucideIcons.star,
                                  size: 14, color: Color(0xFF5A4500)),
                              const SizedBox(width: 8),
                              Text(
                                '${widget.matchedProfile['match_score'] ?? 80}% COMPATIBILITY',
                                style: GoogleFonts.spaceMono(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF5A4500),
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Subtext
                  Text(
                    'You and $matchedName both want to connect!',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                  ),
                  const SizedBox(height: 40),

                  GestureDetector(
                    onTap: widget.onMessage,
                    child: Container(
                      width: double.infinity,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          "SEND A MESSAGE",
                          style: GoogleFonts.spaceMono(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFFE8437A),
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Keep Swiping button
                  GestureDetector(
                    onTap: widget.onKeepSwiping,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Text(
                        'Keep Swiping',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withValues(alpha: 0.7),
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
        ),
      ),
    );
  }

  Widget _buildAvatar(String? url) {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        color: const Color(0xFF152B1E),
      ),
      child: ClipOval(
        child: url != null
            ? CachedNetworkImage(
                imageUrl: url,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => const Icon(
                  LucideIcons.user,
                  size: 36,
                  color: TurfArdorColors.gold,
                ),
              )
            : const Icon(
                LucideIcons.user,
                size: 36,
                color: TurfArdorColors.gold,
              ),
      ),
    );
  }
}

class _ConfettiDot {
  final double x;
  final double startY;
  final double size;
  final Color color;
  final double speed;
  _ConfettiDot(
      {required this.x,
      required this.startY,
      required this.size,
      required this.color,
      required this.speed});
}

class _ConfettiPainter extends CustomPainter {
  final List<_ConfettiDot> dots;
  final double progress;

  _ConfettiPainter({required this.dots, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    for (final dot in dots) {
      final y = (dot.startY + progress * dot.speed * 1.3) % 1.1;
      final paint = Paint()..color = dot.color.withValues(alpha: 0.7);
      canvas.drawCircle(
        Offset(dot.x * size.width, y * size.height),
        dot.size,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter old) =>
      old.progress != progress;
}
