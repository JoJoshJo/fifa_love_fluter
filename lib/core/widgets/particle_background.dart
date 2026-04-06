import 'dart:math';
import 'package:flutter/material.dart';

class Particle {
  double x, y, vx, vy, opacity, size;
  final Color color;

  Particle(double width, double height, this.color)
      : x = Random().nextDouble() * width,
        y = Random().nextDouble() * height,
        vx = (Random().nextDouble() - 0.5) * 0.3, // Slower velocity
        vy = (Random().nextDouble() - 0.5) * 0.3, // Slower velocity
        opacity = Random().nextDouble() * 0.5 + 0.1,
        size = Random().nextDouble() * 2.0; // Slightly smaller

  void move(double width, double height) {
    x += vx;
    y += vy;
    if (x < 0) x = width;
    if (x > width) x = 0;
    if (y < 0) y = height;
    if (y > height) y = 0;
  }
}

class ParticlePainter extends CustomPainter {
  final List<Particle> particles;
  final _paint = Paint();

  ParticlePainter(this.particles, {required Listenable repaint})
      : super(repaint: repaint);

  @override
  void paint(Canvas canvas, Size size) {
    for (var p in particles) {
      _paint.color = p.color.withValues(alpha: p.opacity);
      canvas.drawCircle(Offset(p.x, p.y), p.size, _paint);
    }
  }

  @override
  bool shouldRepaint(covariant ParticlePainter oldDelegate) => false;
}

class ParticleBackground extends StatefulWidget {
  final Widget child;

  const ParticleBackground({
    super.key,
    this.child = const SizedBox.shrink(),
  });

  @override
  State<ParticleBackground> createState() => _ParticleBackgroundState();
}

class _ParticleBackgroundState extends State<ParticleBackground>
    with SingleTickerProviderStateMixin {
  late List<Particle> _particles;
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _particles = List.generate(30, (_) {
      final rand = Random().nextDouble();
      Color color;
      if (rand < 0.4) {
        color = const Color(0xFFF2C233); // Gold 40%
      } else if (rand < 0.7) {
        color = const Color(0xFFE8437A); // Pink 30%
      } else if (rand < 0.9) {
        color = Colors.white; // White 20%
      } else {
        color = const Color(0xFFA4E4C1); // Mint 10%
      }
      return Particle(0, 0, color);
    });

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )
      ..addListener(() {
        final size = MediaQuery.maybeOf(context)?.size ?? Size.zero;
        if (size != Size.zero) {
          for (var p in _particles) {
            p.move(size.width, size.height);
          }
        }
      })
      ..repeat();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_particles.isNotEmpty && _particles.first.x == 0) {
      final size = MediaQuery.of(context).size;
      for (var p in _particles) {
        p.x = Random().nextDouble() * size.width;
        p.y = Random().nextDouble() * size.height;
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        RepaintBoundary(
          child: CustomPaint(
            painter: ParticlePainter(
              _particles,
              repaint: _controller,
            ),
            size: Size.infinite,
          ),
        ),
        widget.child,
      ],
    );
  }
}
