/// AgriMatrixPainter — Digital Twin CustomPainter
///
/// Katmanlar (arkadan öne):
///   1. Hex grid arka plan (koyu)
///   2. Tarla polygon + NDVI renk zonu
///   3. Risk sektörleri (arc dilimler)
///   4. İklim ısı haritası (radial gradient)
///   5. Fiyat tiker (kayan metin simülasyonu)
///   6. Neon parlaklık efekti (BlurMaskFilter)
library;

import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../services/rule_engine.dart' show RiskLevel;

// ─────────────────────────────────────────────────────────────────────────────
// VERİ MODELLERİ
// ─────────────────────────────────────────────────────────────────────────────

class RiskSector {
  final String labelTr;
  final double value; // 0-1
  final RiskLevel level;
  const RiskSector({
    required this.labelTr,
    required this.value,
    required this.level,
  });

  Color get color {
    switch (level) {
      case RiskLevel.critical:
        return const Color(0xFFFF1744);
      case RiskLevel.warning:
        return const Color(0xFFFFAB00);
      case RiskLevel.info:
        return const Color(0xFF00B0FF);
      case RiskLevel.ok:
        return const Color(0xFF00E676);
    }
  }
}

class PriceTick {
  final String symbol;
  final double priceTl;
  final double changePct; // pozitif = artış
  const PriceTick({
    required this.symbol,
    required this.priceTl,
    required this.changePct,
  });
}

class NdviZone {
  final Offset center; // 0-1 normalized
  final double radius; // 0-1 normalized
  final double ndvi;  // -1 to 1 (>0.4 = sağlıklı)
  const NdviZone({
    required this.center,
    required this.radius,
    required this.ndvi,
  });

  Color get color {
    if (ndvi > 0.6) return const Color(0xFF00E676); // canlı yeşil
    if (ndvi > 0.4) return const Color(0xFF76FF03); // açık yeşil
    if (ndvi > 0.2) return const Color(0xFFFFEA00); // sarı
    if (ndvi > 0.0) return const Color(0xFFFF6D00); // turuncu
    return const Color(0xFFDD2C00);                 // kırmızı (stres)
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PAINTER
// ─────────────────────────────────────────────────────────────────────────────

class AgriMatrixPainter extends CustomPainter {
  final List<RiskSector> sectors;
  final List<PriceTick> ticks;
  final List<NdviZone> ndviZones;
  final List<Offset> fieldPolygon; // 0-1 normalized
  final double animValue;          // 0-1 loop animation
  final double tempC;
  final double humidityPct;
  final bool showHexGrid;
  final bool showNdvi;
  final bool showRiskArcs;
  final bool showPriceTicker;

  const AgriMatrixPainter({
    required this.sectors,
    required this.ticks,
    this.ndviZones = const [],
    this.fieldPolygon = const [],
    this.animValue = 0.0,
    this.tempC = 20.0,
    this.humidityPct = 60.0,
    this.showHexGrid = true,
    this.showNdvi = true,
    this.showRiskArcs = true,
    this.showPriceTicker = true,
  });

  static const Color _bg = Color(0xFF0A0E1A);
  static const Color _neonGreen = Color(0xFF00E676);
  static const Color _neonCyan = Color(0xFF00E5FF);
  static const Color _gridLine = Color(0x1A00E676);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height),
        Paint()..color = _bg);

    if (showHexGrid) _drawHexGrid(canvas, size);
    _drawClimateHeatmap(canvas, size);
    if (fieldPolygon.length >= 3) _drawFieldPolygon(canvas, size);
    if (showNdvi && ndviZones.isNotEmpty) _drawNdviZones(canvas, size);
    if (showRiskArcs && sectors.isNotEmpty) _drawRiskArcs(canvas, size);
    if (showPriceTicker && ticks.isNotEmpty) _drawPriceTicker(canvas, size);
    _drawScanLine(canvas, size);
  }

  // ── 1. HEX GRID ──────────────────────────────────────────────────────────

  void _drawHexGrid(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = _gridLine
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.6;

    const hexR = 22.0;
    const w = hexR * 2;
    final h = hexR * math.sqrt(3);
    int col = 0;
    for (double x = -hexR; x < size.width + hexR; x += w * 0.75) {
      final yOffset = (col % 2 == 0) ? 0.0 : h / 2;
      for (double y = -h + yOffset; y < size.height + h; y += h) {
        _drawHex(canvas, Offset(x, y), hexR, paint);
      }
      col++;
    }
  }

  void _drawHex(Canvas canvas, Offset center, double r, Paint paint) {
    final path = Path();
    for (int i = 0; i < 6; i++) {
      final angle = math.pi / 180 * (60 * i - 30);
      final pt = Offset(
        center.dx + r * math.cos(angle),
        center.dy + r * math.sin(angle),
      );
      if (i == 0) {
        path.moveTo(pt.dx, pt.dy);
      } else {
        path.lineTo(pt.dx, pt.dy);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  // ── 2. İKLİM ISI HARİTASI ────────────────────────────────────────────────

  void _drawClimateHeatmap(Canvas canvas, Size size) {
    // Sıcaklık → renk tonu (mavi=soğuk, kırmızı=sıcak)
    final t = ((tempC - 0) / 45).clamp(0.0, 1.0);
    final hot = Color.lerp(
      const Color(0x1A0055FF),
      const Color(0x1AFF1744),
      t,
    )!;

    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final gradient = ui.Gradient.radial(
      Offset(size.width * 0.5, size.height * 0.4),
      size.width * 0.7,
      [hot, _bg.withValues(alpha: 0.0)],
    );
    canvas.drawRect(rect, Paint()..shader = gradient);

    // Nem → hafif mavi katman
    final h = (humidityPct / 100).clamp(0.0, 1.0);
    final humid = Color(0x0800B0FF).withValues(alpha: h * 0.12);
    canvas.drawRect(rect, Paint()..color = humid);
  }

  // ── 3. TARLA POLYGON ─────────────────────────────────────────────────────

  void _drawFieldPolygon(Canvas canvas, Size size) {
    final pts = fieldPolygon
        .map((n) => Offset(n.dx * size.width, n.dy * size.height))
        .toList();

    final fillPath = Path()..addPolygon(pts, true);

    // Dolgu — yarı saydam yeşil
    canvas.drawPath(
      fillPath,
      Paint()
        ..color = _neonGreen.withValues(alpha: 0.08)
        ..style = PaintingStyle.fill,
    );

    // Neon kenar
    final strokePaint = Paint()
      ..color = _neonGreen.withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 6);
    canvas.drawPath(fillPath, strokePaint);

    // Köşe noktaları
    final dotPaint = Paint()
      ..color = _neonGreen
      ..style = PaintingStyle.fill;
    for (final p in pts) {
      canvas.drawCircle(p, 4, dotPaint);
    }
  }

  // ── 4. NDVI ZONLARI ──────────────────────────────────────────────────────

  void _drawNdviZones(Canvas canvas, Size size) {
    for (final zone in ndviZones) {
      final center = Offset(
        zone.center.dx * size.width,
        zone.center.dy * size.height,
      );
      final r = zone.radius * math.min(size.width, size.height);
      final c = zone.color;

      canvas.drawCircle(
        center,
        r,
        Paint()
          ..color = c.withValues(alpha: 0.25)
          ..style = PaintingStyle.fill,
      );
      canvas.drawCircle(
        center,
        r,
        Paint()
          ..color = c.withValues(alpha: 0.6)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2,
      );

      // NDVI değer etiketi
      final tp = TextPainter(
        text: TextSpan(
          text: zone.ndvi.toStringAsFixed(2),
          style: TextStyle(
            color: c,
            fontSize: 9,
            fontFamily: 'monospace',
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
    }
  }

  // ── 5. RİSK ARKLARI ──────────────────────────────────────────────────────

  void _drawRiskArcs(Canvas canvas, Size size) {
    final cx = size.width * 0.5;
    final cy = size.height * 0.55;
    const baseR = 60.0;
    const gapDeg = 4.0;
    const totalDeg = 360.0 - (gapDeg * 1); // tüm çember
    final perSector = totalDeg / sectors.length;

    for (int i = 0; i < sectors.length; i++) {
      final sector = sectors[i];
      final startDeg = -90.0 + i * perSector + gapDeg / 2;
      final sweepDeg = perSector - gapDeg;
      final r = baseR + i * 14.0;

      // Arka plan ray (karanlık)
      canvas.drawArc(
        Rect.fromCircle(center: Offset(cx, cy), radius: r),
        _deg2rad(startDeg),
        _deg2rad(sweepDeg),
        false,
        Paint()
          ..color = sector.color.withValues(alpha: 0.12)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 10
          ..strokeCap = StrokeCap.round,
      );

      // Değer dolgu
      canvas.drawArc(
        Rect.fromCircle(center: Offset(cx, cy), radius: r),
        _deg2rad(startDeg),
        _deg2rad(sweepDeg * sector.value),
        false,
        Paint()
          ..color = sector.color.withValues(alpha: 0.85)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 10
          ..strokeCap = StrokeCap.round
          ..maskFilter = MaskFilter.blur(BlurStyle.outer, sector.level == RiskLevel.critical ? 6 : 3),
      );

      // Etiket
      final labelAngle = _deg2rad(startDeg + sweepDeg / 2);
      final labelR = r + 16.0;
      final lx = cx + labelR * math.cos(labelAngle);
      final ly = cy + labelR * math.sin(labelAngle);
      final tp = TextPainter(
        text: TextSpan(
          text: sector.labelTr,
          style: TextStyle(
            color: sector.color.withValues(alpha: 0.9),
            fontSize: 8.5,
            fontFamily: 'monospace',
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(lx - tp.width / 2, ly - tp.height / 2));
    }

    // Merkez daire
    canvas.drawCircle(
      Offset(cx, cy),
      baseR - 12,
      Paint()
        ..color = _neonGreen.withValues(alpha: 0.05)
        ..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      Offset(cx, cy),
      baseR - 12,
      Paint()
        ..color = _neonGreen.withValues(alpha: 0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );
  }

  // ── 6. FİYAT TİKER ───────────────────────────────────────────────────────

  void _drawPriceTicker(Canvas canvas, Size size) {
    const tickH = 22.0;
    final y = size.height - tickH;

    // Arkaplan band
    canvas.drawRect(
      Rect.fromLTWH(0, y, size.width, tickH),
      Paint()..color = const Color(0xFF050810),
    );
    canvas.drawLine(
      Offset(0, y),
      Offset(size.width, y),
      Paint()
        ..color = _neonCyan.withValues(alpha: 0.3)
        ..strokeWidth = 0.8,
    );

    // Kayan metin
    final offset = -(animValue * size.width * 2) % (size.width + 400);

    final tp = TextPainter(
      text: TextSpan(
        children: ticks.map((t) {
          final sign = t.changePct >= 0 ? '▲' : '▼';
          final color = t.changePct >= 0 ? _neonGreen : const Color(0xFFFF1744);
          return TextSpan(
            text: ' ${t.symbol} ${t.priceTl.toStringAsFixed(1)}₺ $sign${t.changePct.abs().toStringAsFixed(1)}%   |',
            style: TextStyle(
              color: color,
              fontSize: 9.5,
              fontFamily: 'monospace',
              fontWeight: FontWeight.w600,
            ),
          );
        }).toList(),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: double.infinity);

    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, y, size.width, tickH));
    tp.paint(canvas, Offset(offset, y + (tickH - tp.height) / 2));
    // Wrap around
    if (offset + tp.width < size.width) {
      tp.paint(canvas, Offset(offset + tp.width + 8, y + (tickH - tp.height) / 2));
    }
    canvas.restore();

    // "MARKET" etiketi
    final label = TextPainter(
      text: const TextSpan(
        text: ' ◈ MARKET ',
        style: TextStyle(
          color: _neonCyan,
          fontSize: 8,
          fontFamily: 'monospace',
          letterSpacing: 1.5,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    canvas.drawRect(
      Rect.fromLTWH(0, y, label.width + 4, tickH),
      Paint()..color = const Color(0xFF0A1628),
    );
    label.paint(canvas, Offset(2, y + (tickH - label.height) / 2));
  }

  // ── 7. TARAMA ÇİZGİSİ (scan line) ────────────────────────────────────────

  void _drawScanLine(Canvas canvas, Size size) {
    final scanY = animValue * size.height;
    canvas.drawLine(
      Offset(0, scanY),
      Offset(size.width, scanY),
      Paint()
        ..color = _neonCyan.withValues(alpha: 0.08)
        ..strokeWidth = 1.5
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────

  double _deg2rad(double deg) => deg * math.pi / 180;

  @override
  bool shouldRepaint(AgriMatrixPainter old) =>
      old.animValue != animValue ||
      old.sectors != sectors ||
      old.ticks != ticks ||
      old.ndviZones != ndviZones ||
      old.tempC != tempC ||
      old.humidityPct != humidityPct;
}

// ─────────────────────────────────────────────────────────────────────────────
// WIDGET SARICI (animasyon döngüsü dahil)
// ─────────────────────────────────────────────────────────────────────────────

class AgriMatrixView extends StatefulWidget {
  final List<RiskSector> sectors;
  final List<PriceTick> ticks;
  final List<NdviZone> ndviZones;
  final List<Offset> fieldPolygon;
  final double tempC;
  final double humidityPct;
  final double height;
  final bool showHexGrid;
  final bool showNdvi;
  final bool showRiskArcs;
  final bool showPriceTicker;

  const AgriMatrixView({
    super.key,
    required this.sectors,
    required this.ticks,
    this.ndviZones = const [],
    this.fieldPolygon = const [],
    this.tempC = 20.0,
    this.humidityPct = 60.0,
    this.height = 280,
    this.showHexGrid = true,
    this.showNdvi = true,
    this.showRiskArcs = true,
    this.showPriceTicker = true,
  });

  @override
  State<AgriMatrixView> createState() => _AgriMatrixViewState();
}

class _AgriMatrixViewState extends State<AgriMatrixView>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => CustomPaint(
        painter: AgriMatrixPainter(
          sectors: widget.sectors,
          ticks: widget.ticks,
          ndviZones: widget.ndviZones,
          fieldPolygon: widget.fieldPolygon,
          animValue: _ctrl.value,
          tempC: widget.tempC,
          humidityPct: widget.humidityPct,
          showHexGrid: widget.showHexGrid,
          showNdvi: widget.showNdvi,
          showRiskArcs: widget.showRiskArcs,
          showPriceTicker: widget.showPriceTicker,
        ),
        size: Size(double.infinity, widget.height),
        child: const SizedBox.expand(),
      ),
    );
  }
}

