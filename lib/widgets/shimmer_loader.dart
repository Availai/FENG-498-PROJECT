import 'package:flutter/material.dart';

/// Yükleme iskeleti — plain CircularProgressIndicator'a göre çok daha modern
/// bir "içerik yükleniyor" hissi verir. CustomPainter ile çok hafif.
class ShimmerBox extends StatefulWidget {
  const ShimmerBox({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 12,
    this.baseColor = const Color(0xFFE5EAE7),
    this.highlightColor = const Color(0xFFF7FAF8),
  });

  final double width;
  final double height;
  final double borderRadius;
  final Color baseColor;
  final Color highlightColor;

  @override
  State<ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<ShimmerBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          return Container(
            width: widget.width,
            height: widget.height,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(widget.borderRadius),
              gradient: LinearGradient(
                begin: const Alignment(-1.0, -0.3),
                end: const Alignment(1.0, 0.3),
                stops: [
                  (_c.value - 0.3).clamp(0.0, 1.0),
                  _c.value.clamp(0.0, 1.0),
                  (_c.value + 0.3).clamp(0.0, 1.0),
                ],
                colors: [
                  widget.baseColor,
                  widget.highlightColor,
                  widget.baseColor,
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
