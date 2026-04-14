import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Legacy adı korunuyor; artık glass/blur yok — sade krem bir karttır.
/// Çiftçi dostu tema gereği tüm "cam" efektleri kaldırıldı.
class GlassPanel extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  // sigmaX/sigmaY artık kullanılmıyor; geriye dönük uyumluluk için tutuluyor.
  final double sigmaX;
  final double sigmaY;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final Color baseColor;

  const GlassPanel({
    super.key,
    required this.child,
    this.borderRadius = 16.0,
    this.sigmaX = 0,
    this.sigmaY = 0,
    this.padding = const EdgeInsets.all(16.0),
    this.margin = EdgeInsets.zero,
    this.baseColor = AppColors.surface,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: margin,
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          color: baseColor,
          borderRadius: BorderRadius.circular(borderRadius),
          border: Border.all(color: AppColors.border, width: 1),
        ),
        child: child,
      ),
    );
  }
}
