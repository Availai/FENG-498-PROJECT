import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Gerçek zamanlı büyüyen bitki görseli — ayçiçeği / mısır / domates için
/// CustomPainter tabanlı vektör sprite.
///
/// Girdi:
///  - [cropKey]: 'aycicegi' | 'misir' | 'domates' (desteklenmeyen anahtar →
///    boş canvas)
///  - [stageKey]: 'cimlenme' | 'vejetatif' | 'ciceklenme' | 'meyve_dolumu' |
///    'olgunlasma'
///  - [overallProgress]: 0..1 — boy ve yaprak yoğunluğu bu değerden türetilir
///  - [stressIndex]: 0..1 — yüksekse yaprak rengi sarıya kayar, rüzgâr eğimi
///    küçülür
///
/// Hiçbir asset / SVG bağımlılığı yok; tamamen Canvas çizimi. Yeniden çizim
/// sadece parametreler veya salınım fazı değişince tetiklenir.
class CropGrowthSprite extends StatefulWidget {
  final String cropKey;
  final String stageKey;
  final double overallProgress;
  final double stressIndex;
  final bool animateSway;

  const CropGrowthSprite({
    super.key,
    required this.cropKey,
    required this.stageKey,
    required this.overallProgress,
    this.stressIndex = 0.0,
    this.animateSway = true,
  });

  @override
  State<CropGrowthSprite> createState() => _CropGrowthSpriteState();
}

class _CropGrowthSpriteState extends State<CropGrowthSprite>
    with SingleTickerProviderStateMixin {
  late final AnimationController _sway;

  @override
  void initState() {
    super.initState();
    _sway = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4200),
    );
    if (widget.animateSway) _sway.repeat();
  }

  @override
  void didUpdateWidget(covariant CropGrowthSprite oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animateSway && !_sway.isAnimating) {
      _sway.repeat();
    } else if (!widget.animateSway && _sway.isAnimating) {
      _sway.stop();
    }
  }

  @override
  void dispose() {
    _sway.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _sway,
      builder: (context, _) => CustomPaint(
        painter: _CropPainter(
          cropKey: widget.cropKey,
          stageKey: widget.stageKey,
          overallProgress: widget.overallProgress.clamp(0.0, 1.0),
          stressIndex: widget.stressIndex.clamp(0.0, 1.0),
          swayPhase: _sway.value * 2 * math.pi,
        ),
      ),
    );
  }
}

class _CropPainter extends CustomPainter {
  _CropPainter({
    required this.cropKey,
    required this.stageKey,
    required this.overallProgress,
    required this.stressIndex,
    required this.swayPhase,
  });

  final String cropKey;
  final String stageKey;
  final double overallProgress;
  final double stressIndex;
  final double swayPhase;

  static const _ripeStages = {'olgunlasma'};
  static const _fruitingStages = {'meyve_dolumu', 'olgunlasma'};
  static const _floweringStages = {
    'ciceklenme',
    'meyve_dolumu',
    'olgunlasma'
  };

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final groundY = size.height * 0.94;
    final centerX = size.width / 2;

    _drawGround(canvas, size, groundY);

    // Bitki yüksekliği — overallProgress ile büyür. Minimum fide boyu
    // görünür olsun diye %15 tabandan başlar.
    final minH = size.height * 0.15;
    final maxH = size.height * 0.88;
    final height = minH + (maxH - minH) * overallProgress;

    // Rüzgar salınımı — boy arttıkça artar, stres artınca söner.
    final swayAmp = size.width * 0.04 * overallProgress * (1 - stressIndex * 0.6);
    final leanX = math.sin(swayPhase) * swayAmp;

    final leafColor = _leafColor();

    switch (cropKey) {
      case 'aycicegi':
        _drawSunflower(canvas, centerX, groundY, height, leanX, leafColor);
        break;
      case 'misir':
        _drawCorn(canvas, centerX, groundY, height, leanX, leafColor);
        break;
      case 'domates':
        _drawTomato(canvas, centerX, groundY, height, leanX, leafColor);
        break;
    }
  }

  // ── Renk yardımcıları ─────────────────────────────────────────────

  Color _leafColor() {
    // Sağlıklı: hue 120 (yeşil). Stres: hue 55 (hardal/sarı).
    final hue = 120.0 - 65.0 * stressIndex;
    final saturation = (0.55 - 0.15 * stressIndex).clamp(0.2, 0.8);
    final lightness = (0.32 + 0.08 * stressIndex).clamp(0.2, 0.6);
    return HSLColor.fromAHSL(1.0, hue, saturation, lightness).toColor();
  }

  void _drawGround(Canvas canvas, Size size, double groundY) {
    final paint = Paint()..color = AppColors.soilLight.withValues(alpha: 0.45);
    canvas.drawRect(
      Rect.fromLTRB(0, groundY, size.width, size.height),
      paint,
    );
    // İnce bir toprak çizgisi
    final line = Paint()
      ..color = AppColors.soil.withValues(alpha: 0.5)
      ..strokeWidth = 1.5;
    canvas.drawLine(Offset(0, groundY), Offset(size.width, groundY), line);
  }

  // ── Ortak yaprak çizici ───────────────────────────────────────────

  void _drawLeaf(
    Canvas canvas,
    Offset anchor,
    double length,
    double angleRad,
    Color color,
  ) {
    final tip = Offset(
      anchor.dx + math.cos(angleRad) * length,
      anchor.dy + math.sin(angleRad) * length,
    );
    final ctrl1Angle = angleRad - 0.6;
    final ctrl2Angle = angleRad + 0.6;
    final ctrl1 = Offset(
      anchor.dx + math.cos(ctrl1Angle) * length * 0.6,
      anchor.dy + math.sin(ctrl1Angle) * length * 0.6,
    );
    final ctrl2 = Offset(
      anchor.dx + math.cos(ctrl2Angle) * length * 0.6,
      anchor.dy + math.sin(ctrl2Angle) * length * 0.6,
    );
    final path = Path()
      ..moveTo(anchor.dx, anchor.dy)
      ..quadraticBezierTo(ctrl1.dx, ctrl1.dy, tip.dx, tip.dy)
      ..quadraticBezierTo(ctrl2.dx, ctrl2.dy, anchor.dx, anchor.dy)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  // ── AYÇİÇEĞİ ──────────────────────────────────────────────────────

  void _drawSunflower(
    Canvas canvas,
    double cx,
    double groundY,
    double height,
    double leanX,
    Color leafColor,
  ) {
    final topX = cx + leanX;
    final topY = groundY - height;
    final stemWidth = 2.2 + 2.8 * overallProgress;

    // Gövde — hafif kavisli
    final stemPaint = Paint()
      ..color = leafColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = stemWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(
      Path()
        ..moveTo(cx, groundY)
        ..quadraticBezierTo(
          cx + leanX * 0.4, groundY - height * 0.5,
          topX, topY,
        ),
      stemPaint,
    );

    // Yapraklar — boy arttıkça sayı artar, boy 6 çift max
    final leafPairs = (1 + 5 * overallProgress).round();
    final leafColorDark = HSLColor.fromColor(leafColor)
        .withLightness((HSLColor.fromColor(leafColor).lightness - 0.08).clamp(0.1, 0.9))
        .toColor();
    for (int i = 1; i <= leafPairs; i++) {
      final t = i / (leafPairs + 1);
      final ax = cx + leanX * t * 0.4;
      final ay = groundY - height * t;
      final len = height * (0.15 - t * 0.05);
      _drawLeaf(canvas, Offset(ax, ay), len, math.pi + 0.2 + t * 0.3, leafColorDark);
      _drawLeaf(canvas, Offset(ax, ay), len, -0.2 - t * 0.3, leafColorDark);
    }

    // Tabla / çiçek — çiçeklenme ve sonrası
    if (_floweringStages.contains(stageKey)) {
      final flowerR = height * 0.09 + height * 0.05 * (overallProgress - 0.4).clamp(0.0, 0.6);
      final isRipe = _ripeStages.contains(stageKey);
      final petalColor = isRipe
          ? const Color(0xFFB8860B)
          : const Color(0xFFFFC107);
      final centerColor =
          isRipe ? const Color(0xFF3E2A14) : const Color(0xFF5D3A1F);

      // Taç yaprakları — 14 tane
      final petalPaint = Paint()..color = petalColor;
      for (int i = 0; i < 14; i++) {
        final angle = (i / 14) * 2 * math.pi;
        final px = topX + math.cos(angle) * flowerR * 1.35;
        final py = topY + math.sin(angle) * flowerR * 1.35;
        canvas.save();
        canvas.translate(px, py);
        canvas.rotate(angle + math.pi / 2);
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset.zero,
            width: flowerR * 0.55,
            height: flowerR * 0.95,
          ),
          petalPaint,
        );
        canvas.restore();
      }
      // Merkez
      canvas.drawCircle(
        Offset(topX, topY),
        flowerR,
        Paint()..color = centerColor,
      );
      // Olgunlukta başı aşağı düşür
      if (isRipe) {
        canvas.drawLine(
          Offset(topX, topY),
          Offset(topX - flowerR * 0.2, topY + flowerR * 0.4),
          Paint()
            ..color = centerColor
            ..strokeWidth = flowerR * 0.2,
        );
      }
    }
  }

  // ── MISIR ─────────────────────────────────────────────────────────

  void _drawCorn(
    Canvas canvas,
    double cx,
    double groundY,
    double height,
    double leanX,
    Color leafColor,
  ) {
    final topX = cx + leanX;
    final topY = groundY - height;
    final stemWidth = 2.5 + 2.5 * overallProgress;

    // Dik gövde
    final stemPaint = Paint()
      ..color = leafColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = stemWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(
      Path()
        ..moveTo(cx, groundY)
        ..quadraticBezierTo(
          cx + leanX * 0.3, groundY - height * 0.5,
          topX, topY,
        ),
      stemPaint,
    );

    // Uzun sarkık yapraklar — alternatif
    final leafCount = (2 + 6 * overallProgress).round();
    for (int i = 1; i <= leafCount; i++) {
      final t = i / (leafCount + 1);
      final ax = cx + leanX * t * 0.3;
      final ay = groundY - height * t;
      final side = i.isEven ? 1.0 : -1.0;
      final len = height * 0.22 * (1 - t * 0.3);
      // Yaprak yay gibi — hafifçe aşağı eğimli
      _drawLeaf(
        canvas,
        Offset(ax, ay),
        len,
        side > 0 ? -0.1 : math.pi + 0.1,
        leafColor,
      );
    }

    // Püskül (tassel) — çiçeklenme+
    if (_floweringStages.contains(stageKey)) {
      final tasselColor = _ripeStages.contains(stageKey)
          ? const Color(0xFF8B7D3A)
          : const Color(0xFFBFA96E);
      final tasselPaint = Paint()
        ..color = tasselColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8
        ..strokeCap = StrokeCap.round;
      for (int i = -3; i <= 3; i++) {
        canvas.drawLine(
          Offset(topX, topY),
          Offset(topX + i * 2.2, topY - height * 0.08),
          tasselPaint,
        );
      }
    }

    // Koçan — meyve_dolumu ve olgunlaşma
    if (_fruitingStages.contains(stageKey)) {
      final isRipe = _ripeStages.contains(stageKey);
      final cobY = groundY - height * 0.45;
      final cobX = cx + leanX * 0.2 + stemWidth + 3;
      final cobColor =
          isRipe ? const Color(0xFFE8B64B) : const Color(0xFFC9D87E);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(cobX, cobY),
            width: height * 0.07,
            height: height * 0.18,
          ),
          const Radius.circular(4),
        ),
        Paint()..color = cobColor,
      );
      // Kabuk yaprakları
      _drawLeaf(
        canvas,
        Offset(cobX, cobY - height * 0.09),
        height * 0.14,
        -math.pi / 2 + 0.35,
        leafColor,
      );
    }
  }

  // ── DOMATES ───────────────────────────────────────────────────────

  void _drawTomato(
    Canvas canvas,
    double cx,
    double groundY,
    double height,
    double leanX,
    Color leafColor,
  ) {
    final topX = cx + leanX;
    final topY = groundY - height;
    final stemWidth = 2.0 + 2.0 * overallProgress;

    // Ana gövde — çalı formu, hafif S eğrisi
    final stemPaint = Paint()
      ..color = leafColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = stemWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(
      Path()
        ..moveTo(cx, groundY)
        ..cubicTo(
          cx - leanX * 0.3, groundY - height * 0.3,
          cx + leanX * 0.8, groundY - height * 0.65,
          topX, topY,
        ),
      stemPaint,
    );

    // Yan dallar — çalı hissi
    final branchCount = (2 + 4 * overallProgress).round();
    for (int i = 1; i <= branchCount; i++) {
      final t = i / (branchCount + 1);
      final ax = cx + leanX * t * 0.5;
      final ay = groundY - height * t;
      final side = i.isEven ? 1.0 : -1.0;
      final branchLen = height * 0.18 * (1 - t * 0.2);
      canvas.drawLine(
        Offset(ax, ay),
        Offset(ax + side * branchLen, ay - branchLen * 0.3),
        stemPaint,
      );
      // Küçük yaprakları uçlara dağıt
      final tipX = ax + side * branchLen;
      final tipY = ay - branchLen * 0.3;
      _drawLeaf(
        canvas,
        Offset(tipX, tipY),
        height * 0.09,
        side > 0 ? -0.3 : math.pi + 0.3,
        leafColor,
      );
      _drawLeaf(
        canvas,
        Offset(tipX, tipY),
        height * 0.08,
        side > 0 ? -0.9 : math.pi + 0.9,
        leafColor,
      );
    }

    // Çiçekler — çiçeklenme evresinde küçük sarı noktalar
    if (stageKey == 'ciceklenme') {
      final flowerPaint = Paint()..color = const Color(0xFFFFE082);
      for (int i = 1; i <= 3; i++) {
        final t = 0.3 + i * 0.2;
        final fx = cx + leanX * t * 0.5 + (i.isEven ? 6 : -6);
        final fy = groundY - height * t;
        canvas.drawCircle(Offset(fx, fy), 2.0, flowerPaint);
      }
    }

    // Meyveler — meyve_dolumu ve olgunlaşma
    if (_fruitingStages.contains(stageKey)) {
      final isRipe = _ripeStages.contains(stageKey);
      final fruitColor =
          isRipe ? const Color(0xFFD32F2F) : const Color(0xFFC9D87E);
      final fruitHighlight = isRipe
          ? const Color(0xFFFF6B6B)
          : const Color(0xFFDDE79E);
      // 3 meyve kümesi
      final positions = [
        Offset(cx - height * 0.12, groundY - height * 0.35),
        Offset(cx + height * 0.10, groundY - height * 0.50),
        Offset(cx - height * 0.05, groundY - height * 0.62),
      ];
      final r = height * 0.05;
      for (final p in positions) {
        canvas.drawCircle(p, r, Paint()..color = fruitColor);
        canvas.drawCircle(
          Offset(p.dx - r * 0.3, p.dy - r * 0.3),
          r * 0.35,
          Paint()..color = fruitHighlight,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _CropPainter old) =>
      old.cropKey != cropKey ||
      old.stageKey != stageKey ||
      old.overallProgress != overallProgress ||
      old.stressIndex != stressIndex ||
      old.swayPhase != swayPhase;
}
