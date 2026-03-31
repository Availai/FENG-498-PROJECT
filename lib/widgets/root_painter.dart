import 'package:flutter/material.dart';

class RootPainter extends CustomPainter {
  final double progress;
  RootPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.brown.shade600
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final cx = size.width / 2;

    // Ana kök
    final mainLen = size.height * 0.8 * progress;
    canvas.drawLine(Offset(cx, 0), Offset(cx, mainLen), paint);

    // Sol yan kök
    if (progress > 0.3) {
      final side = (progress - 0.3) / 0.7;
      canvas.drawLine(
        Offset(cx, mainLen * 0.3),
        Offset(cx - 20 * side, mainLen * 0.3 + 15 * side),
        paint..strokeWidth = 1.5,
      );
    }
    // Sağ yan kök
    if (progress > 0.5) {
      final side = (progress - 0.5) / 0.5;
      canvas.drawLine(
        Offset(cx, mainLen * 0.55),
        Offset(cx + 18 * side, mainLen * 0.55 + 12 * side),
        paint..strokeWidth = 1.5,
      );
    }
    // Sol alt kök
    if (progress > 0.7) {
      final side = (progress - 0.7) / 0.3;
      canvas.drawLine(
        Offset(cx, mainLen * 0.7),
        Offset(cx - 14 * side, mainLen * 0.7 + 10 * side),
        paint..strokeWidth = 1,
      );
    }
  }

  @override
  bool shouldRepaint(covariant RootPainter old) => old.progress != progress;
}
