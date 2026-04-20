import 'dart:math';
import 'package:flutter/material.dart';

/// Hafifçe yükselen yeşil partikül arka planı — performans için
/// tek bir [Ticker] üzerinden sürdürülür, [RepaintBoundary] ile izole edilir.
class ParticleBackground extends StatefulWidget {
  const ParticleBackground({
    super.key,
    this.particleCount = 28,
    this.baseColor = const Color(0xFF81C784),
    this.child,
  });

  final int particleCount;
  final Color baseColor;
  final Widget? child;

  @override
  State<ParticleBackground> createState() => _ParticleBackgroundState();
}

class _ParticleBackgroundState extends State<ParticleBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<_Particle> _particles;

  @override
  void initState() {
    super.initState();
    final rand = Random(42);
    _particles = List.generate(
      widget.particleCount,
      (i) => _Particle.random(rand),
    );
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        RepaintBoundary(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              return CustomPaint(
                painter: _ParticlePainter(
                  progress: _controller.value,
                  particles: _particles,
                  color: widget.baseColor,
                ),
              );
            },
          ),
        ),
        if (widget.child != null) widget.child!,
      ],
    );
  }
}

class _Particle {
  _Particle({
    required this.x,
    required this.seed,
    required this.size,
    required this.speed,
    required this.opacity,
    required this.offsetY,
  });

  final double x;          // 0..1 normalized
  final double seed;       // sway phase
  final double size;       // px
  final double speed;      // rise multiplier
  final double opacity;    // 0..1
  final double offsetY;    // initial offset 0..1

  factory _Particle.random(Random rand) {
    return _Particle(
      x: rand.nextDouble(),
      seed: rand.nextDouble() * 2 * pi,
      size: 2.0 + rand.nextDouble() * 4.0,
      speed: 0.3 + rand.nextDouble() * 0.8,
      opacity: 0.25 + rand.nextDouble() * 0.5,
      offsetY: rand.nextDouble(),
    );
  }
}

class _ParticlePainter extends CustomPainter {
  _ParticlePainter({
    required this.progress,
    required this.particles,
    required this.color,
  });

  final double progress;
  final List<_Particle> particles;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    for (final p in particles) {
      // Dikey konum — bottom'dan top'a doğru yükseliş
      final t = (progress * p.speed + p.offsetY) % 1.0;
      final y = size.height * (1.0 - t);

      // Yatay salınım (sway)
      final sway = sin((progress * 2 * pi) + p.seed) * 18.0;
      final x = p.x * size.width + sway;

      // Yukarı çıktıkça fade-out
      final fade = (1.0 - t) * p.opacity;
      paint.color = color.withValues(alpha: fade.clamp(0.0, 1.0));

      canvas.drawCircle(Offset(x, y), p.size, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter old) => old.progress != progress;
}
