import 'package:flutter/material.dart';

class CropLayer {
  final String name;
  final Color color;
  final double rowSpacingCm;
  final double plantSpacingCm;
  final double startPercent; // tarlanın kaçıncı %'sinden başlıyor (0.0–1.0)
  final double endPercent; // tarlanın kaçıncı %'sine kadar (0.0–1.0)

  const CropLayer({
    required this.name,
    required this.color,
    required this.rowSpacingCm,
    required this.plantSpacingCm,
    this.startPercent = 0.0,
    this.endPercent = 1.0,
  });
}
