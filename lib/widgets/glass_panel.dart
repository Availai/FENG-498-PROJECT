import 'dart:ui';
import 'package:flutter/material.dart';

class GlassPanel extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final double sigmaX;
  final double sigmaY;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final Color baseColor;

  const GlassPanel({
    super.key,
    required this.child,
    this.borderRadius = 16.0,
    this.sigmaX = 10.0,
    this.sigmaY = 10.0,
    this.padding = const EdgeInsets.all(16.0),
    this.margin = EdgeInsets.zero,
    this.baseColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: margin,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: sigmaX, sigmaY: sigmaY),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: baseColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(
                color: baseColor.withValues(alpha: 0.15),
                width: 1.0,
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
