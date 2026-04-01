import 'dart:math';
import 'package:flutter/material.dart';

class Particle {
  double x, y, vx, vy, opacity, size;
  
  Particle(double width, double height) 
    : x = Random().nextDouble() * width,
      y = Random().nextDouble() * height,
      vx = (Random().nextDouble() - 0.5) * 0.8,
      vy = (Random().nextDouble() - 0.5) * 0.8,
      opacity = Random().nextDouble() * 0.6 + 0.1,
      size = Random().nextDouble() * 2.5;

  void move(double width, double height) {
    x += vx;
    y += vy;
    if (x < 0 || x > width) vx *= -1;
    if (y < 0 || y > height) vy *= -1;
  }
}

class ParticlePainter extends CustomPainter {
  final List<Particle> particles;
  final Color color;

  ParticlePainter(this.particles, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    for (var p in particles) {
      paint.color = color.withValues(alpha: p.opacity);
      canvas.drawCircle(Offset(p.x, p.y), p.size, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class ParticleBackground extends StatefulWidget {
  final Widget child;
  final Color? particleColor;

  const ParticleBackground({
    super.key, 
    this.child = const SizedBox.shrink(),
    this.particleColor,
  });

  @override
  State<ParticleBackground> createState() => _ParticleBackgroundState();
}

class _ParticleBackgroundState extends State<ParticleBackground> with SingleTickerProviderStateMixin {
  late List<Particle> _particles;
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _particles = List.generate(40, (_) => Particle(0, 0));
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..addListener(() {
        for (var p in _particles) {
          p.move(MediaQuery.of(context).size.width, MediaQuery.of(context).size.height);
        }
        setState(() {});
      })..repeat();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_particles.first.x == 0) {
      final size = MediaQuery.of(context).size;
      _particles = List.generate(45, (_) => Particle(size.width, size.height));
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
        CustomPaint(
          painter: ParticlePainter(
            _particles, 
            widget.particleColor ?? Colors.white.withValues(alpha: 0.2),
          ),
          size: Size.infinite,
        ),
        widget.child,
      ],
    );
  }
}
