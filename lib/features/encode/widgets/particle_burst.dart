import 'dart:math' as math;
import 'package:flutter/material.dart';

class ParticleBurst extends StatefulWidget {
  final Color color;
  const ParticleBurst({super.key, required this.color});

  @override
  State<ParticleBurst> createState() => _ParticleBurstState();
}

class _ParticleBurstState extends State<ParticleBurst> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_Particle> _particles = [];
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _generateParticles();
    _controller.forward();
  }

  void _generateParticles() {
    for (int i = 0; i < 24; i++) {
      final angle = _random.nextDouble() * 2 * math.pi;
      final speed = 1.5 + _random.nextDouble() * 2.5;
      _particles.add(_Particle(
        angle: angle,
        speed: speed,
        size: 2 + _random.nextDouble() * 4,
      ));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: _ParticlePainter(
            particles: _particles,
            progress: _controller.value,
            color: widget.color,
          ),
          size: const Size(200, 200),
        );
      },
    );
  }
}

class _Particle {
  final double angle;
  final double speed;
  final double size;

  _Particle({required this.angle, required this.speed, required this.size});
}

class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final double progress;
  final Color color;

  _ParticlePainter({required this.particles, required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()..color = color.withValues(alpha: 1.0 - progress);

    for (final particle in particles) {
      final distance = particle.speed * progress * 60;
      final x = center.dx + math.cos(particle.angle) * distance;
      final y = center.dy + math.sin(particle.angle) * distance;
      
      canvas.drawCircle(Offset(x, y), particle.size * (1.0 - progress), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
