import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../models/crop_layer.dart';

class TopDownFieldPainter extends CustomPainter {
  final double phase; // 0.0–1.0
  final double rowSpacingCm;
  final double plantSpacingCm;
  final double irrigationLineSpacingCm;
  final double irrigationDripperSpacingCm;
  final double fertilizerBandCm;
  final double fieldWidthM; // gerçek tarla genişliği (metre)
  final double fieldHeightM; // gerçek tarla yüksekliği (metre)
  final bool showPlanting, showIrrigation, showFertilizer;
  final List<CropLayer> crops; // çoklu ürün desteği

  TopDownFieldPainter({
    required this.phase,
    required this.rowSpacingCm,
    required this.plantSpacingCm,
    required this.irrigationLineSpacingCm,
    required this.irrigationDripperSpacingCm,
    required this.fertilizerBandCm,
    this.fieldWidthM = 10,
    this.fieldHeightM = 10,
    this.showPlanting = true,
    this.showIrrigation = true,
    this.showFertilizer = true,
    this.crops = const [],
  });

  @override
  void paint(Canvas canvas, Size size) {
    // ── Gerçek tarla boyutlarını cm'ye çevir ──
    final fieldW = fieldWidthM * 100; // cm
    final fieldH = fieldHeightM * 100; // cm
    const margin = 40.0; // px kenar boşluğu
    final drawW = size.width - margin * 2;
    final drawH = size.height - margin * 2;
    final scaleX = drawW / fieldW;
    final ox = margin; // origin x
    final oy = margin; // origin y

    // Faz hesaplamaları
    final fieldPhase = (phase / 0.15).clamp(0.0, 1.0);
    final rowPhase = ((phase - 0.15) / 0.20).clamp(0.0, 1.0);
    final plantPhase = ((phase - 0.35) / 0.25).clamp(0.0, 1.0);
    final irrPhase = ((phase - 0.60) / 0.20).clamp(0.0, 1.0);
    final fertPhase = ((phase - 0.80) / 0.20).clamp(0.0, 1.0);

    // ── FAZ 1: Tarla çerçevesi ──
    if (fieldPhase > 0) {
      final borderPaint = Paint()
        ..color = Colors.brown.shade400.withValues(alpha: fieldPhase)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5;
      final fillPaint = Paint()
        ..color = Colors.brown.shade50.withValues(alpha: fieldPhase * 0.5);
      final fieldRect = Rect.fromLTWH(ox, oy, drawW, drawH);
      final rrect = RRect.fromRectAndRadius(fieldRect, const Radius.circular(6));
      canvas.drawRRect(rrect, fillPaint);
      canvas.drawRRect(rrect, borderPaint);

      // Ölçek etiketi
      if (fieldPhase > 0.5) {
        _drawLabel(canvas, '${fieldWidthM.toStringAsFixed(0)}m x ${fieldHeightM.toStringAsFixed(0)}m',
            Offset(ox + drawW / 2, oy + drawH + 16), Colors.brown.shade600, 10, true);
      }
    }

    // Sıra konumlarını hesapla
    final rowCount = (fieldH / rowSpacingCm).floor().clamp(1, 10);
    final List<double> rowYs = [];
    for (int r = 0; r < rowCount; r++) {
      rowYs.add(oy + (r + 0.5) * (drawH / rowCount));
    }

    // ── FAZ 2: Sıra çizgileri ──
    if (showPlanting && rowPhase > 0) {
      final rowPaint = Paint()
        ..color = Colors.green.shade200.withValues(alpha: rowPhase * 0.7)
        ..strokeWidth = 1
        ..style = PaintingStyle.stroke;

      for (int r = 0; r < rowYs.length; r++) {
        final animLen = drawW * rowPhase;
        // Kesikli çizgi
        double dx = ox;
        while (dx < ox + animLen) {
          final end = (dx + 8).clamp(0.0, ox + animLen);
          canvas.drawLine(Offset(dx, rowYs[r]), Offset(end, rowYs[r]), rowPaint);
          dx += 14;
        }
      }

      // Sıra arası ölçü oku (ilk iki sıra arası)
      if (rowPhase > 0.8 && rowYs.length >= 2) {
        _drawDimensionArrow(canvas, Offset(ox - 8, rowYs[0]), Offset(ox - 8, rowYs[1]),
            '${rowSpacingCm.round()}cm', Colors.green.shade700);
      }
    }

    // ── FAZ 3: Bitkiler ──
    if (showPlanting && plantPhase > 0) {
      final plantsPerRow = (fieldW / plantSpacingCm).floor().clamp(1, 15);
      final totalPlants = rowCount * plantsPerRow;
      final visiblePlants = (totalPlants * plantPhase).round();

      int plantIdx = 0;
      for (int r = 0; r < rowCount && plantIdx < visiblePlants; r++) {
        for (int p = 0; p < plantsPerRow && plantIdx < visiblePlants; p++) {
          final px = ox + (p + 0.5) * (drawW / plantsPerRow);
          final py = rowYs[r];
          final scale = ((plantIdx < visiblePlants) ? 1.0 : 0.0);

          final plantPaint = Paint()
            ..color = Colors.green.shade600.withValues(alpha: scale)
            ..style = PaintingStyle.fill;
          canvas.drawCircle(Offset(px, py), 4.5 * scale, plantPaint);

          // Küçük yaprak
          final leafPaint = Paint()
            ..color = Colors.green.shade400.withValues(alpha: scale * 0.8)
            ..style = PaintingStyle.fill;
          canvas.drawCircle(Offset(px + 3, py - 3), 2.5 * scale, leafPaint);

          plantIdx++;
        }
      }

      // Bitki arası ölçü oku (ilk sırada ilk iki bitki arası)
      if (plantPhase > 0.8 && plantsPerRow >= 2) {
        final px1 = ox + 0.5 * (drawW / plantsPerRow);
        final px2 = ox + 1.5 * (drawW / plantsPerRow);
        _drawDimensionArrow(canvas, Offset(px1, rowYs[0] - 16), Offset(px2, rowYs[0] - 16),
            '${plantSpacingCm.round()}cm', Colors.green.shade800);
      }
    }

    // ── Çoklu Ürün Katmanları (FAZ 3 ile beraber) ──
    if (showPlanting && plantPhase > 0 && crops.isNotEmpty) {
      for (final crop in crops) {
        final cropStartX = ox + drawW * crop.startPercent;
        final cropEndX = ox + drawW * crop.endPercent;
        final cropW = cropEndX - cropStartX;

        // Bölge sınır çizgisi
        final borderPaint = Paint()
          ..color = crop.color.withValues(alpha: plantPhase * 0.5)
          ..strokeWidth = 1.5
          ..style = PaintingStyle.stroke;
        canvas.drawLine(Offset(cropStartX, oy), Offset(cropStartX, oy + drawH), borderPaint);

        // Etiket
        if (plantPhase > 0.5) {
          _drawLabel(canvas, crop.name, Offset(cropStartX + cropW / 2, oy - 12),
              crop.color, 9, true);
        }

        // Bu ürünün bitkileri
        final cropRowSpacing = crop.rowSpacingCm;
        final cropPlantSpacing = crop.plantSpacingCm;
        final cropRowCount = (fieldH / cropRowSpacing).floor().clamp(1, 10);
        final cropPlantsPerRow = (cropW / (drawW / fieldW) / cropPlantSpacing).floor().clamp(1, 12);

        for (int r = 0; r < cropRowCount; r++) {
          final ry = oy + (r + 0.5) * (drawH / cropRowCount);
          for (int p = 0; p < (cropPlantsPerRow * plantPhase).round(); p++) {
            final px = cropStartX + (p + 0.5) * (cropW / cropPlantsPerRow);
            if (px >= cropEndX) break;
            canvas.drawCircle(
              Offset(px, ry), 4,
              Paint()..color = crop.color.withValues(alpha: 0.8)..style = PaintingStyle.fill,
            );
          }
        }
      }
    }

    // ── FAZ 4: Sulama hatları ──
    if (showIrrigation && irrPhase > 0) {
      final irrLineCount = (fieldH / irrigationLineSpacingCm).floor().clamp(1, 10);
      final irrPaint = Paint()
        ..color = Colors.blue.shade500.withValues(alpha: irrPhase * 0.8)
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      final dripPaint = Paint()
        ..color = Colors.blue.shade300.withValues(alpha: irrPhase)
        ..style = PaintingStyle.fill;

      for (int i = 0; i < irrLineCount; i++) {
        final ly = oy + (i + 0.5) * (drawH / irrLineCount);
        final animLen = drawW * irrPhase;

        // Ana sulama hattı
        canvas.drawLine(Offset(ox, ly), Offset(ox + animLen, ly), irrPaint);

        // Damlatıcı noktaları
        final dripCount = (animLen / (irrigationDripperSpacingCm * scaleX)).floor();
        for (int d = 0; d < dripCount; d++) {
          final dx = ox + (d + 0.5) * irrigationDripperSpacingCm * scaleX;
          if (dx < ox + animLen) {
            canvas.drawCircle(Offset(dx, ly), 3, dripPaint);
            // Su damlası efekti
            final dropPaint = Paint()
              ..color = Colors.blue.shade200.withValues(alpha: irrPhase * 0.4)
              ..style = PaintingStyle.fill;
            canvas.drawCircle(Offset(dx, ly + 6), 5, dropPaint);
          }
        }
      }

      // Sulama hattı arası ölçü oku
      if (irrPhase > 0.8 && irrLineCount >= 2) {
        final ly1 = oy + 0.5 * (drawH / irrLineCount);
        final ly2 = oy + 1.5 * (drawH / irrLineCount);
        _drawDimensionArrow(canvas, Offset(ox + drawW + 8, ly1), Offset(ox + drawW + 8, ly2),
            '${irrigationLineSpacingCm.round()}cm', Colors.blue.shade700);
      }

      // Damlatıcı arası ölçü oku
      if (irrPhase > 0.8) {
        final ly = oy + 0.5 * (drawH / irrLineCount);
        final dx1 = ox + 0.5 * irrigationDripperSpacingCm * scaleX;
        final dx2 = ox + 1.5 * irrigationDripperSpacingCm * scaleX;
        if (dx2 < ox + drawW) {
          _drawDimensionArrow(canvas, Offset(dx1, ly + 14), Offset(dx2, ly + 14),
              '${irrigationDripperSpacingCm.round()}cm', Colors.blue.shade600);
        }
      }
    }

    // ── FAZ 5: Gübre bantları ──
    if (showFertilizer && fertPhase > 0) {
      final fertPaint = Paint()
        ..color = Colors.orange.shade300.withValues(alpha: fertPhase * 0.35)
        ..style = PaintingStyle.fill;
      final fertBorderPaint = Paint()
        ..color = Colors.orange.shade400.withValues(alpha: fertPhase * 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1;

      final bandPx = fertilizerBandCm * scaleX;

      for (final ry in rowYs) {
        // Bitki sırasının her iki yanında gübre bandı
        final bandRect = Rect.fromLTWH(ox, ry - bandPx, drawW * fertPhase, bandPx * 2);
        final rrect = RRect.fromRectAndRadius(bandRect, const Radius.circular(3));
        canvas.drawRRect(rrect, fertPaint);
        canvas.drawRRect(rrect, fertBorderPaint);
      }

      // Gübre bandı genişlik ölçüsü
      if (fertPhase > 0.8 && rowYs.isNotEmpty) {
        final ry = rowYs.last;
        _drawDimensionArrow(
            canvas,
            Offset(ox + drawW * 0.7, ry - bandPx),
            Offset(ox + drawW * 0.7, ry + bandPx),
            '${(fertilizerBandCm * 2).round()}cm',
            Colors.orange.shade700);
      }
    }
  }

  void _drawDimensionArrow(Canvas canvas, Offset p1, Offset p2, String label, Color color) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    // Ana çizgi
    canvas.drawLine(p1, p2, paint);

    // Ok uçları
    final isVertical = (p1.dx - p2.dx).abs() < 2;
    final arrowSize = 5.0;
    if (isVertical) {
      // Üst ok
      canvas.drawLine(p1, Offset(p1.dx - arrowSize, p1.dy + arrowSize), paint);
      canvas.drawLine(p1, Offset(p1.dx + arrowSize, p1.dy + arrowSize), paint);
      // Alt ok
      canvas.drawLine(p2, Offset(p2.dx - arrowSize, p2.dy - arrowSize), paint);
      canvas.drawLine(p2, Offset(p2.dx + arrowSize, p2.dy - arrowSize), paint);
      // Etiket
      _drawLabel(canvas, label, Offset((p1.dx + p2.dx) / 2 + 12, (p1.dy + p2.dy) / 2), color, 10, false);
    } else {
      // Sol ok
      canvas.drawLine(p1, Offset(p1.dx + arrowSize, p1.dy - arrowSize), paint);
      canvas.drawLine(p1, Offset(p1.dx + arrowSize, p1.dy + arrowSize), paint);
      // Sağ ok
      canvas.drawLine(p2, Offset(p2.dx - arrowSize, p2.dy - arrowSize), paint);
      canvas.drawLine(p2, Offset(p2.dx - arrowSize, p2.dy + arrowSize), paint);
      // Etiket
      _drawLabel(canvas, label, Offset((p1.dx + p2.dx) / 2, p1.dy - 10), color, 10, true);
    }
  }

  void _drawLabel(Canvas canvas, String text, Offset pos, Color color, double fontSize, bool center) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(color: color, fontSize: fontSize, fontWeight: FontWeight.bold),
      ),
      textDirection: ui.TextDirection.ltr,
    )..layout();
    final offset = center ? Offset(pos.dx - tp.width / 2, pos.dy - tp.height / 2) : pos;
    tp.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant TopDownFieldPainter old) =>
      old.phase != phase ||
      old.showPlanting != showPlanting ||
      old.showIrrigation != showIrrigation ||
      old.showFertilizer != showFertilizer;
}
