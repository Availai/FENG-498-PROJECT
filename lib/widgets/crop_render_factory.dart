import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../data/verified_agri_database.dart';

// ═══════════════════════════════════════════════════════════════════
// ÜRÜN BAZLI RENDER FABRİKASI
// Her ürün ailesi için farklı CustomPainter ve büyüme fazı sistemi.
// ═══════════════════════════════════════════════════════════════════

/// Büyüme fazı — olgunluk yüzdesinden hesaplanır.
enum GrowthPhase { seedling, growing, mature, harvest }

GrowthPhase getGrowthPhase(double maturityPercent) {
  if (maturityPercent < 25) return GrowthPhase.seedling;
  if (maturityPercent < 75) return GrowthPhase.growing;
  if (maturityPercent < 90) return GrowthPhase.mature;
  return GrowthPhase.harvest;
}

/// Faz bazlı boyut ve renk çözümleyici.
double phaseSize(GrowthPhase phase) {
  switch (phase) {
    case GrowthPhase.seedling:
      return 8.0;
    case GrowthPhase.growing:
      return 14.0;
    case GrowthPhase.mature:
      return 20.0;
    case GrowthPhase.harvest:
      return 22.0;
  }
}

Color phaseBaseColor(GrowthPhase phase, Color cropColor) {
  switch (phase) {
    case GrowthPhase.seedling:
      return const Color(0xFFA5D6A7); // açık yeşil
    case GrowthPhase.growing:
      return const Color(0xFF388E3C); // koyu yeşil
    case GrowthPhase.mature:
      return cropColor;
    case GrowthPhase.harvest:
      return cropColor;
  }
}

// ─────────────────────────────────────────────────────────
// ANA FABRİKA — renderType'a göre doğru widget döndürür
// ─────────────────────────────────────────────────────────

/// Ürün tipi ve büyüme fazına göre harita marker widget'ı üretir.
/// [harvestPulse]: 0.0–1.0 arası animasyon değeri (hasat animasyonu için).
Widget buildCropMarkerWidget({
  required String cropName,
  required Color cropColor,
  required double maturityPercent,
  double harvestPulse = 0.0,
  VoidCallback? onTap,
}) {
  // RenderType'ı AgriPlant veritabanından bul
  String renderType = PlantRenderType.bush;
  for (final p in VerifiedAgriDatabase.plants) {
    if (p.nameTr.toLowerCase() == cropName.toLowerCase()) {
      renderType = p.renderType;
      break;
    }
  }

  final phase = getGrowthPhase(maturityPercent);
  final size = phaseSize(phase);
  final baseColor = phaseBaseColor(phase, cropColor);

  Widget marker;
  switch (renderType) {
    case PlantRenderType.stalk:
      marker = _StalkCropWidget(
          size: size, color: baseColor, phase: phase, pulse: harvestPulse);
      break;
    case PlantRenderType.tree:
      marker = _TreeCropWidget(
          size: size, color: baseColor, phase: phase, pulse: harvestPulse);
      break;
    case PlantRenderType.bush:
      marker = _BushCropWidget(
          size: size, color: baseColor, phase: phase, pulse: harvestPulse);
      break;
    case PlantRenderType.root:
      marker = _RootCropWidget(
          size: size, color: baseColor, phase: phase, pulse: harvestPulse);
      break;
    case PlantRenderType.vine:
      marker = _VineCropWidget(
          size: size, color: baseColor, phase: phase, pulse: harvestPulse);
      break;
    case PlantRenderType.broadleaf:
      marker = _BroadleafCropWidget(
          size: size, color: baseColor, phase: phase, pulse: harvestPulse);
      break;
    case PlantRenderType.dense:
      marker = _DenseCropWidget(
          size: size, color: baseColor, phase: phase, pulse: harvestPulse);
      break;
    default:
      marker = _BushCropWidget(
          size: size, color: baseColor, phase: phase, pulse: harvestPulse);
  }

  if (onTap != null) {
    return GestureDetector(onTap: onTap, child: marker);
  }
  return marker;
}

// ═════════════════════════════════════════════════════════
// TAHIL — paralel dikey çizgiler + başak noktası
// ═════════════════════════════════════════════════════════
class _StalkCropWidget extends StatelessWidget {
  final double size;
  final Color color;
  final GrowthPhase phase;
  final double pulse;
  const _StalkCropWidget(
      {required this.size,
      required this.color,
      required this.phase,
      required this.pulse});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size * 1.3, size * 1.6),
      painter: _StalkPainter(color: color, phase: phase, pulse: pulse),
    );
  }
}

class _StalkPainter extends CustomPainter {
  final Color color;
  final GrowthPhase phase;
  final double pulse;
  _StalkPainter({required this.color, required this.phase, required this.pulse});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final bottom = size.height;

    final stalkPaint = Paint()
      ..color = color.withValues(alpha: 0.85)
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;

    final headPaint = Paint()..color = color;

    // Ana sap
    final topY = size.height * 0.15;
    canvas.drawLine(Offset(cx, bottom), Offset(cx, topY), stalkPaint);

    // Yan saplar (büyümüşse)
    if (phase != GrowthPhase.seedling) {
      canvas.drawLine(
          Offset(cx, bottom * 0.55),
          Offset(cx - size.width * 0.3, bottom * 0.35),
          stalkPaint..strokeWidth = 1.2);
      canvas.drawLine(
          Offset(cx, bottom * 0.45),
          Offset(cx + size.width * 0.3, bottom * 0.28),
          stalkPaint..strokeWidth = 1.2);
    }

    // Başak
    final headR = phase == GrowthPhase.seedling ? 1.5 : 3.0;
    canvas.drawCircle(Offset(cx, topY), headR, headPaint);

    // Hasat halosu
    if (phase == GrowthPhase.harvest) {
      _drawHarvestHalo(canvas, Offset(cx, topY), headR + 3 + pulse * 3);
    }
  }

  void _drawHarvestHalo(Canvas canvas, Offset center, double radius) {
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = const Color(0xFFFFD700).withValues(alpha: 0.35 - pulse * 0.15)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  @override
  bool shouldRepaint(covariant _StalkPainter old) =>
      old.pulse != pulse || old.phase != phase || old.color != color;
}

// ═════════════════════════════════════════════════════════
// AĞAÇ — daire gövde + yaprak taç küresi
// ═════════════════════════════════════════════════════════
class _TreeCropWidget extends StatelessWidget {
  final double size;
  final Color color;
  final GrowthPhase phase;
  final double pulse;
  const _TreeCropWidget(
      {required this.size,
      required this.color,
      required this.phase,
      required this.pulse});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size * 1.4, size * 1.8),
      painter: _TreePainter(color: color, phase: phase, pulse: pulse),
    );
  }
}

class _TreePainter extends CustomPainter {
  final Color color;
  final GrowthPhase phase;
  final double pulse;
  _TreePainter({required this.color, required this.phase, required this.pulse});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final bottom = size.height;

    // Gövde
    final trunkPaint = Paint()
      ..color = const Color(0xFF5D4037)
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    final trunkTop = size.height * 0.42;
    canvas.drawLine(Offset(cx, bottom), Offset(cx, trunkTop), trunkPaint);

    // Taç
    final canopyR = phase == GrowthPhase.seedling
        ? size.width * 0.18
        : size.width * 0.38 + pulse * 0.8;
    final canopyCenter = Offset(cx, trunkTop - canopyR * 0.3);

    canvas.drawCircle(
      canopyCenter,
      canopyR,
      Paint()..color = color.withValues(alpha: 0.75),
    );

    // Highlight
    canvas.drawCircle(
      Offset(canopyCenter.dx - canopyR * 0.25, canopyCenter.dy - canopyR * 0.25),
      canopyR * 0.35,
      Paint()..color = Colors.white.withValues(alpha: 0.15),
    );

    // Hasat halosu
    if (phase == GrowthPhase.harvest) {
      canvas.drawCircle(
        canopyCenter,
        canopyR + 3 + pulse * 3,
        Paint()
          ..color = const Color(0xFFFFD700).withValues(alpha: 0.3 - pulse * 0.12)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _TreePainter old) =>
      old.pulse != pulse || old.phase != phase || old.color != color;
}

// ═════════════════════════════════════════════════════════
// SEBZE/ÇALI — küçük yuvarlak bitki + sap
// ═════════════════════════════════════════════════════════
class _BushCropWidget extends StatelessWidget {
  final double size;
  final Color color;
  final GrowthPhase phase;
  final double pulse;
  const _BushCropWidget(
      {required this.size,
      required this.color,
      required this.phase,
      required this.pulse});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size * 1.2, size * 1.4),
      painter: _BushPainter(color: color, phase: phase, pulse: pulse),
    );
  }
}

class _BushPainter extends CustomPainter {
  final Color color;
  final GrowthPhase phase;
  final double pulse;
  _BushPainter({required this.color, required this.phase, required this.pulse});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final bottom = size.height;

    // Sap
    final stemPaint = Paint()
      ..color = const Color(0xFF2E7D32)
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    final topY = size.height * 0.35;
    canvas.drawLine(Offset(cx, bottom), Offset(cx, topY), stemPaint);

    // Ana küre
    final r = phase == GrowthPhase.seedling
        ? size.width * 0.15
        : size.width * 0.3;
    final bushCenter = Offset(cx, topY);
    canvas.drawCircle(bushCenter, r, Paint()..color = color.withValues(alpha: 0.8));

    // Yan yapraklar (büyümüşse)
    if (phase == GrowthPhase.mature || phase == GrowthPhase.harvest) {
      canvas.drawCircle(
        Offset(cx - r * 0.8, topY + r * 0.3),
        r * 0.55,
        Paint()..color = color.withValues(alpha: 0.5),
      );
      canvas.drawCircle(
        Offset(cx + r * 0.8, topY + r * 0.3),
        r * 0.55,
        Paint()..color = color.withValues(alpha: 0.5),
      );
    }

    // Hasat halosu
    if (phase == GrowthPhase.harvest) {
      canvas.drawCircle(
        bushCenter,
        r + 3 + pulse * 3,
        Paint()
          ..color = const Color(0xFFFFD700).withValues(alpha: 0.35 - pulse * 0.15)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BushPainter old) =>
      old.pulse != pulse || old.phase != phase || old.color != color;
}

// ═════════════════════════════════════════════════════════
// KÖK BİTKİSİ — toprak altı kök + üstte yaprak
// ═════════════════════════════════════════════════════════
class _RootCropWidget extends StatelessWidget {
  final double size;
  final Color color;
  final GrowthPhase phase;
  final double pulse;
  const _RootCropWidget(
      {required this.size,
      required this.color,
      required this.phase,
      required this.pulse});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size * 1.2, size * 1.6),
      painter: _RootPainter(color: color, phase: phase, pulse: pulse),
    );
  }
}

class _RootPainter extends CustomPainter {
  final Color color;
  final GrowthPhase phase;
  final double pulse;
  _RootPainter({required this.color, required this.phase, required this.pulse});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final mid = size.height * 0.45;

    // Toprak çizgisi
    canvas.drawLine(
      Offset(0, mid),
      Offset(size.width, mid),
      Paint()
        ..color = const Color(0xFF5D4037).withValues(alpha: 0.4)
        ..strokeWidth = 1,
    );

    // Kök (aşağıda)
    final rootH = phase == GrowthPhase.seedling
        ? size.height * 0.15
        : size.height * 0.4;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx, mid + rootH * 0.4),
        width: size.width * 0.45,
        height: rootH,
      ),
      Paint()..color = color.withValues(alpha: 0.7),
    );

    // Saçak kökler (olgunsa)
    if (phase == GrowthPhase.mature || phase == GrowthPhase.harvest) {
      final rootPaint = Paint()
        ..color = color.withValues(alpha: 0.4)
        ..strokeWidth = 0.8;
      canvas.drawLine(
          Offset(cx - 3, mid + rootH * 0.7), Offset(cx - 6, mid + rootH * 0.95), rootPaint);
      canvas.drawLine(
          Offset(cx + 3, mid + rootH * 0.7), Offset(cx + 6, mid + rootH * 0.95), rootPaint);
    }

    // Üst yaprak
    final leafR = phase == GrowthPhase.seedling
        ? size.width * 0.1
        : size.width * 0.22;
    canvas.drawLine(
      Offset(cx, mid),
      Offset(cx, mid - size.height * 0.2),
      Paint()
        ..color = const Color(0xFF388E3C)
        ..strokeWidth = 1.5,
    );
    canvas.drawCircle(
      Offset(cx, mid - size.height * 0.2 - leafR * 0.3),
      leafR,
      Paint()..color = const Color(0xFF66BB6A).withValues(alpha: 0.8),
    );

    // Hasat halosu
    if (phase == GrowthPhase.harvest) {
      canvas.drawCircle(
        Offset(cx, mid),
        size.width * 0.4 + pulse * 3,
        Paint()
          ..color = const Color(0xFFFFD700).withValues(alpha: 0.3 - pulse * 0.12)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RootPainter old) =>
      old.pulse != pulse || old.phase != phase || old.color != color;
}

// ═════════════════════════════════════════════════════════
// ASMA/SARILICI — yatay eğri dallar
// ═════════════════════════════════════════════════════════
class _VineCropWidget extends StatelessWidget {
  final double size;
  final Color color;
  final GrowthPhase phase;
  final double pulse;
  const _VineCropWidget(
      {required this.size,
      required this.color,
      required this.phase,
      required this.pulse});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size * 1.4, size * 1.2),
      painter: _VinePainter(color: color, phase: phase, pulse: pulse),
    );
  }
}

class _VinePainter extends CustomPainter {
  final Color color;
  final GrowthPhase phase;
  final double pulse;
  _VinePainter({required this.color, required this.phase, required this.pulse});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    final vinePaint = Paint()
      ..color = const Color(0xFF2E7D32).withValues(alpha: 0.7)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Ana dal (yatay sinüs)
    final path = Path();
    path.moveTo(size.width * 0.1, cy);
    for (double x = size.width * 0.1; x <= size.width * 0.9; x += 2) {
      final y = cy + math.sin((x / size.width) * math.pi * 2.5) * size.height * 0.15;
      path.lineTo(x, y);
    }
    canvas.drawPath(path, vinePaint);

    // Meyve/üzüm toplulukları
    if (phase != GrowthPhase.seedling) {
      final fruitR = phase == GrowthPhase.growing ? 2.0 : 3.5;
      final fruitPaint = Paint()..color = color.withValues(alpha: 0.8);
      canvas.drawCircle(Offset(cx - size.width * 0.2, cy - 3), fruitR, fruitPaint);
      canvas.drawCircle(Offset(cx + size.width * 0.15, cy + 2), fruitR, fruitPaint);
      if (phase == GrowthPhase.mature || phase == GrowthPhase.harvest) {
        canvas.drawCircle(Offset(cx, cy - 4), fruitR * 0.8, fruitPaint);
      }
    }

    // Yapraklar
    final leafPaint = Paint()..color = const Color(0xFF66BB6A).withValues(alpha: 0.6);
    canvas.drawCircle(Offset(cx - size.width * 0.1, cy - size.height * 0.2), 2.5, leafPaint);
    canvas.drawCircle(Offset(cx + size.width * 0.2, cy - size.height * 0.15), 2.5, leafPaint);

    // Hasat halosu
    if (phase == GrowthPhase.harvest) {
      canvas.drawCircle(
        Offset(cx, cy),
        size.width * 0.35 + pulse * 3,
        Paint()
          ..color = const Color(0xFFFFD700).withValues(alpha: 0.3 - pulse * 0.12)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _VinePainter old) =>
      old.pulse != pulse || old.phase != phase || old.color != color;
}

// ═════════════════════════════════════════════════════════
// GENİŞ YAPRAK — lahana/marul gibi yuvarlak yaprak kümesi
// ═════════════════════════════════════════════════════════
class _BroadleafCropWidget extends StatelessWidget {
  final double size;
  final Color color;
  final GrowthPhase phase;
  final double pulse;
  const _BroadleafCropWidget(
      {required this.size,
      required this.color,
      required this.phase,
      required this.pulse});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size * 1.3, size * 1.2),
      painter: _BroadleafPainter(color: color, phase: phase, pulse: pulse),
    );
  }
}

class _BroadleafPainter extends CustomPainter {
  final Color color;
  final GrowthPhase phase;
  final double pulse;
  _BroadleafPainter(
      {required this.color, required this.phase, required this.pulse});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    // Merkez büyük yaprak
    final mainR = phase == GrowthPhase.seedling
        ? size.width * 0.15
        : size.width * 0.3;
    canvas.drawCircle(
      Offset(cx, cy),
      mainR,
      Paint()..color = color.withValues(alpha: 0.7),
    );

    // Çevredeki yapraklar (büyümüşse)
    if (phase != GrowthPhase.seedling) {
      final outerR = mainR * 0.65;
      for (int i = 0; i < 5; i++) {
        final angle = (i * 72 + 36) * math.pi / 180;
        final lx = cx + math.cos(angle) * mainR * 0.85;
        final ly = cy + math.sin(angle) * mainR * 0.85;
        canvas.drawCircle(
          Offset(lx, ly),
          outerR,
          Paint()..color = color.withValues(alpha: 0.4),
        );
      }
    }

    // Highlight
    canvas.drawCircle(
      Offset(cx - mainR * 0.2, cy - mainR * 0.2),
      mainR * 0.3,
      Paint()..color = Colors.white.withValues(alpha: 0.12),
    );

    // Hasat halosu
    if (phase == GrowthPhase.harvest) {
      canvas.drawCircle(
        Offset(cx, cy),
        mainR + 4 + pulse * 3,
        Paint()
          ..color = const Color(0xFFFFD700).withValues(alpha: 0.35 - pulse * 0.15)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BroadleafPainter old) =>
      old.pulse != pulse || old.phase != phase || old.color != color;
}

// ═════════════════════════════════════════════════════════
// YOĞUN — çeltik/yonca gibi sık doku
// ═════════════════════════════════════════════════════════
class _DenseCropWidget extends StatelessWidget {
  final double size;
  final Color color;
  final GrowthPhase phase;
  final double pulse;
  const _DenseCropWidget(
      {required this.size,
      required this.color,
      required this.phase,
      required this.pulse});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size * 1.2, size * 1.2),
      painter: _DensePainter(color: color, phase: phase, pulse: pulse),
    );
  }
}

class _DensePainter extends CustomPainter {
  final Color color;
  final GrowthPhase phase;
  final double pulse;
  _DensePainter(
      {required this.color, required this.phase, required this.pulse});

  @override
  void paint(Canvas canvas, Size size) {
    final dotPaint = Paint()..color = color.withValues(alpha: 0.65);
    final dotR = phase == GrowthPhase.seedling ? 1.2 : 2.0;
    final spacing = size.width / (phase == GrowthPhase.seedling ? 3 : 5);

    for (double x = spacing / 2; x < size.width; x += spacing) {
      for (double y = spacing / 2; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), dotR, dotPaint);
      }
    }

    // Hasat halosu
    if (phase == GrowthPhase.harvest) {
      canvas.drawCircle(
        Offset(size.width / 2, size.height / 2),
        size.width * 0.4 + pulse * 2,
        Paint()
          ..color = const Color(0xFFFFD700).withValues(alpha: 0.3 - pulse * 0.12)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _DensePainter old) =>
      old.pulse != pulse || old.phase != phase || old.color != color;
}
