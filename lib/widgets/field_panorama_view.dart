import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart' hide Path;
import '../data/verified_agri_database.dart';

/// 360° döndürülebilir, pseudo-3D perspektif tarla görünümü.
///
/// CustomPainter tabanlı izometrik projeksiyon ile tarla poligonunu bir düzlem
/// üzerinde çizer. Parmak sürükleme veya slider ile 0°–360° döndürme destekler.
/// Her ürün tipi (tahıl, sebze, meyve, kök, vb.) farklı görsel stille render edilir.
class FieldPanoramaView extends StatefulWidget {
  final List<LatLng> polygon;
  final List<Map<String, dynamic>> crops;
  final double areaDekar;
  final String fieldName;

  const FieldPanoramaView({
    super.key,
    required this.polygon,
    required this.crops,
    required this.areaDekar,
    required this.fieldName,
  });

  @override
  State<FieldPanoramaView> createState() => _FieldPanoramaViewState();
}

class _FieldPanoramaViewState extends State<FieldPanoramaView>
    with SingleTickerProviderStateMixin {
  double _rotationAngle = 30.0; // derece (0–360)
  double _tiltAngle = 55.0; // perspektif eğimi (30–75)
  double _zoom = 1.0;
  late AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A120E),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF00E676)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.view_in_ar_rounded,
                color: Color(0xFF00E676), size: 22),
            const SizedBox(width: 8),
            Text(
              '360° ${widget.fieldName}',
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 16,
                letterSpacing: 1.0,
              ),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // ─── Ana 3D görünüm ───
          Expanded(
            child: GestureDetector(
              onPanUpdate: (details) {
                setState(() {
                  _rotationAngle =
                      (_rotationAngle + details.delta.dx * 0.5) % 360;
                  _tiltAngle =
                      (_tiltAngle - details.delta.dy * 0.3).clamp(25.0, 75.0);
                });
              },
              onScaleUpdate: (details) {
                if (details.scale != 1.0) {
                  setState(() {
                    _zoom = (_zoom * details.scale).clamp(0.5, 3.0);
                  });
                }
              },
              child: AnimatedBuilder(
                animation: _pulseCtrl,
                builder: (context, _) {
                  return CustomPaint(
                    painter: _FieldPanoramaPainter(
                      polygon: widget.polygon,
                      crops: widget.crops,
                      rotationDeg: _rotationAngle,
                      tiltDeg: _tiltAngle,
                      zoom: _zoom,
                      pulseValue: _pulseCtrl.value,
                    ),
                    size: Size.infinite,
                  );
                },
              ),
            ),
          ),

          // ─── Kontrol paneli ───
          _buildControlPanel(),
        ],
      ),
    );
  }

  Widget _buildControlPanel() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1811).withValues(alpha: 0.95),
        border: const Border(
          top: BorderSide(color: Color(0xFF00E676), width: 0.5),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Açı göstergesi
            Row(
              children: [
                const Icon(Icons.rotate_right_rounded,
                    color: Color(0xFF00E676), size: 16),
                const SizedBox(width: 6),
                Text(
                  'Döndürme: ${_rotationAngle.toStringAsFixed(0)}°',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                const Icon(Icons.flip_rounded,
                    color: Color(0xFF00E676), size: 16),
                const SizedBox(width: 6),
                Text(
                  'Eğim: ${_tiltAngle.toStringAsFixed(0)}°',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),

            // Döndürme slider'ı
            Row(
              children: [
                const Text('0°',
                    style: TextStyle(color: Colors.white38, fontSize: 10)),
                Expanded(
                  child: SliderTheme(
                    data: SliderThemeData(
                      activeTrackColor: const Color(0xFF00E676),
                      inactiveTrackColor:
                          const Color(0xFF00E676).withValues(alpha: 0.2),
                      thumbColor: const Color(0xFF00E676),
                      thumbShape:
                          const RoundSliderThumbShape(enabledThumbRadius: 7),
                      trackHeight: 3,
                      overlayShape:
                          const RoundSliderOverlayShape(overlayRadius: 14),
                    ),
                    child: Slider(
                      value: _rotationAngle,
                      min: 0,
                      max: 360,
                      onChanged: (v) => setState(() => _rotationAngle = v),
                    ),
                  ),
                ),
                const Text('360°',
                    style: TextStyle(color: Colors.white38, fontSize: 10)),
              ],
            ),

            const SizedBox(height: 4),

            // Bilgi çizelgesi — lejand
            _buildLegend(),
          ],
        ),
      ),
    );
  }

  Widget _buildLegend() {
    final uniqueCrops = <String, Color>{};
    for (final crop in widget.crops) {
      final name = crop['name']?.toString() ?? 'Bitki';
      final v = crop['color_value'];
      final color = v is int ? Color(v) : const Color(0xFF66BB6A);
      uniqueCrops[name] = color;
    }

    if (uniqueCrops.isEmpty) {
      return const Text(
        'Bu tarlada henüz ürün ekilmemiş.',
        style: TextStyle(color: Colors.white38, fontSize: 11),
      );
    }

    return Wrap(
      spacing: 12,
      runSpacing: 6,
      children: uniqueCrops.entries.map((e) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: e.value,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(width: 4),
            Text(
              e.key,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 11,
              ),
            ),
          ],
        );
      }).toList(),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// CUSTOM PAINTER — Pseudo-3D perspektif tarla render
// ═══════════════════════════════════════════════════════════════════════

class _FieldPanoramaPainter extends CustomPainter {
  final List<LatLng> polygon;
  final List<Map<String, dynamic>> crops;
  final double rotationDeg;
  final double tiltDeg;
  final double zoom;
  final double pulseValue;

  _FieldPanoramaPainter({
    required this.polygon,
    required this.crops,
    required this.rotationDeg,
    required this.tiltDeg,
    required this.zoom,
    required this.pulseValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (polygon.length < 3) return;

    final cx = size.width / 2;
    final cy = size.height / 2;

    // 1. Polygon noktalarını normalize et (merkez 0,0)
    final normalized = _normalizePolygon();

    // 2. Ölçek hesapla (tarlayı ekrana sığdır)
    final scale = _computeScale(normalized, size) * zoom;

    // 3. Rotation ve tilt radyan
    final rotRad = rotationDeg * math.pi / 180;
    final tiltFactor = math.cos(tiltDeg * math.pi / 180);

    // 4. Perspektif projeksiyon uygula
    final projected = normalized.map((p) {
      return _project(p, rotRad, tiltFactor, scale, cx, cy);
    }).toList();

    // ── Arka plan grid ──
    _drawGrid(canvas, size, rotRad, tiltFactor, scale, cx, cy, normalized);

    // ── Tarla gölgesi ──
    _drawFieldShadow(canvas, projected);

    // ── Topografik simülasyon (basit sinüs dalgası) ──
    _drawTopography(canvas, size, rotRad, tiltFactor, scale, cx, cy, normalized);

    // ── Tarla poligonu ──
    _drawFieldPolygon(canvas, projected);

    // ── Ekili bölgeler ──
    _drawCrops(canvas, size, rotRad, tiltFactor, scale, cx, cy, normalized);

    // ── N/S/E/W pusula ──
    _drawCompass(canvas, size, rotRad);

    // ── Köşe etiketleri ──
    _drawCornerLabels(canvas, projected);
  }

  List<Offset> _normalizePolygon() {
    if (polygon.isEmpty) return [];
    double cLat = 0, cLng = 0;
    for (final p in polygon) {
      cLat += p.latitude;
      cLng += p.longitude;
    }
    cLat /= polygon.length;
    cLng /= polygon.length;

    // lat/lng farkını metre-benzeri birimlere çevir
    // 1 derece lat ≈ 111320 m, 1 derece lng ≈ cos(lat)*111320 m
    final cosLat = math.cos(cLat * math.pi / 180);
    return polygon.map((p) {
      final dx = (p.longitude - cLng) * 111320 * cosLat;
      final dy = (p.latitude - cLat) * 111320;
      return Offset(dx, dy);
    }).toList();
  }

  double _computeScale(List<Offset> points, Size size) {
    if (points.isEmpty) return 1.0;
    double maxR = 0;
    for (final p in points) {
      maxR = math.max(maxR, p.distance);
    }
    if (maxR < 1) return 1.0;
    return (math.min(size.width, size.height) * 0.35) / maxR;
  }

  Offset _project(
      Offset p, double rotRad, double tiltFactor, double scale, double cx, double cy) {
    // Döndür
    final rx = p.dx * math.cos(rotRad) - p.dy * math.sin(rotRad);
    final ry = p.dx * math.sin(rotRad) + p.dy * math.cos(rotRad);
    // Perspektif (tilt)
    final px = rx * scale + cx;
    final py = -ry * tiltFactor * scale + cy;
    return Offset(px, py);
  }

  void _drawGrid(Canvas canvas, Size size, double rotRad, double tiltFactor,
      double scale, double cx, double cy, List<Offset> normalized) {
    if (normalized.isEmpty) return;
    double maxR = 0;
    for (final p in normalized) maxR = math.max(maxR, p.distance);
    maxR *= 1.5;

    final gridPaint = Paint()
      ..color = const Color(0xFF00E676).withValues(alpha: 0.06)
      ..strokeWidth = 0.5;

    final gridSpacing = maxR / 5;
    for (double g = -maxR; g <= maxR; g += gridSpacing) {
      final p1 = _project(Offset(-maxR, g), rotRad, tiltFactor, scale, cx, cy);
      final p2 = _project(Offset(maxR, g), rotRad, tiltFactor, scale, cx, cy);
      canvas.drawLine(p1, p2, gridPaint);

      final p3 = _project(Offset(g, -maxR), rotRad, tiltFactor, scale, cx, cy);
      final p4 = _project(Offset(g, maxR), rotRad, tiltFactor, scale, cx, cy);
      canvas.drawLine(p3, p4, gridPaint);
    }
  }

  void _drawFieldShadow(Canvas canvas, List<Offset> projected) {
    if (projected.length < 3) return;
    final shadowPath = Path()..moveTo(projected[0].dx + 6, projected[0].dy + 6);
    for (int i = 1; i < projected.length; i++) {
      shadowPath.lineTo(projected[i].dx + 6, projected[i].dy + 6);
    }
    shadowPath.close();
    canvas.drawPath(
      shadowPath,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
  }

  void _drawTopography(Canvas canvas, Size size, double rotRad,
      double tiltFactor, double scale, double cx, double cy, List<Offset> normalized) {
    if (normalized.length < 3) return;

    // Polygon bounding box
    double minX = double.infinity, maxX = double.negativeInfinity;
    double minY = double.infinity, maxY = double.negativeInfinity;
    for (final p in normalized) {
      minX = math.min(minX, p.dx);
      maxX = math.max(maxX, p.dx);
      minY = math.min(minY, p.dy);
      maxY = math.max(maxY, p.dy);
    }

    final linePaint = Paint()
      ..color = const Color(0xFF00E676).withValues(alpha: 0.08)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;

    final steps = 8;
    for (int i = 0; i <= steps; i++) {
      final t = i / steps;
      final y = minY + (maxY - minY) * t;
      final path = Path();
      bool started = false;

      for (double x = minX; x <= maxX; x += (maxX - minX) / 40) {
        // Basit sinüs yükseklik simülasyonu
        final elevation =
            math.sin(x * 0.05 + y * 0.03) * (maxY - minY) * 0.04;
        final pt = Offset(x, y + elevation);

        // point-in-polygon check (basit)
        if (_isInsideNormalized(pt, normalized)) {
          final proj =
              _project(pt, rotRad, tiltFactor, scale, cx, cy);
          if (!started) {
            path.moveTo(proj.dx, proj.dy);
            started = true;
          } else {
            path.lineTo(proj.dx, proj.dy);
          }
        }
      }
      if (started) canvas.drawPath(path, linePaint);
    }
  }

  bool _isInsideNormalized(Offset point, List<Offset> poly) {
    bool inside = false;
    for (int i = 0, j = poly.length - 1; i < poly.length; j = i++) {
      if ((poly[i].dy > point.dy) != (poly[j].dy > point.dy) &&
          point.dx <
              (poly[j].dx - poly[i].dx) *
                      (point.dy - poly[i].dy) /
                      (poly[j].dy - poly[i].dy == 0
                          ? 1e-12
                          : poly[j].dy - poly[i].dy) +
                  poly[i].dx) {
        inside = !inside;
      }
    }
    return inside;
  }

  void _drawFieldPolygon(Canvas canvas, List<Offset> projected) {
    if (projected.length < 3) return;
    final path = Path()..moveTo(projected[0].dx, projected[0].dy);
    for (int i = 1; i < projected.length; i++) {
      path.lineTo(projected[i].dx, projected[i].dy);
    }
    path.close();

    // Dolgu gradyanı
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFF1B5E20).withValues(alpha: 0.4)
        ..style = PaintingStyle.fill,
    );

    // Halo
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFF00E676).withValues(alpha: 0.25)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6,
    );

    // Sınır
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFF00E676)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  void _drawCrops(Canvas canvas, Size size, double rotRad, double tiltFactor,
      double scale, double cx, double cy, List<Offset> normalized) {
    if (crops.isEmpty || normalized.length < 3) return;

    // Bounding box
    double minX = double.infinity, maxX = double.negativeInfinity;
    double minY = double.infinity, maxY = double.negativeInfinity;
    for (final p in normalized) {
      minX = math.min(minX, p.dx);
      maxX = math.max(maxX, p.dx);
      minY = math.min(minY, p.dy);
      maxY = math.max(maxY, p.dy);
    }

    final rangeX = maxX - minX;
    final rangeY = maxY - minY;
    if (rangeX < 1 || rangeY < 1) return;

    for (final crop in crops) {
      final name = crop['name']?.toString() ?? '';
      final colorVal = crop['color_value'];
      final color = colorVal is int ? Color(colorVal) : const Color(0xFF66BB6A);

      // RenderType belirle
      String renderType = PlantRenderType.bush;
      double maxHeight = 10.0;
      for (final p in VerifiedAgriDatabase.plants) {
        if (p.nameTr.toLowerCase() == name.toLowerCase()) {
          renderType = p.renderType;
          maxHeight = p.maxVisualHeight; 
          break;
        }
      }

      // Büyüme fazı (0.0–1.0)
      double growthFactor = _computeGrowthFactor(crop);
      final heightScale = 0.3 + growthFactor * 0.7; // fide=0.3x, olgun=1.0x

      // Sub-polygon varsa onu, yoksa tüm alanı kullan
      final zoneJson = crop['zone_polygon_json']?.toString();
      List<Offset>? zoneNorm;
      if (zoneJson != null && zoneJson.isNotEmpty) {
        try {
          final parsed = _parseZoneJsonToNormalized(zoneJson);
          if (parsed.length >= 3) zoneNorm = parsed;
        } catch (_) {}
      }
      final areaPoints = zoneNorm ?? normalized;

      // Bounding box of area
      double aMinX = double.infinity, aMaxX = double.negativeInfinity;
      double aMinY = double.infinity, aMaxY = double.negativeInfinity;
      for (final p in areaPoints) {
        aMinX = math.min(aMinX, p.dx);
        aMaxX = math.max(aMaxX, p.dx);
        aMinY = math.min(aMinY, p.dy);
        aMaxY = math.max(aMaxY, p.dy);
      }

      switch (renderType) {
        case PlantRenderType.stalk:
          _drawStalks(canvas, areaPoints, aMinX, aMaxX, aMinY, aMaxY, rotRad,
              tiltFactor, scale, cx, cy, color, heightScale, maxHeight);
          break;
        case PlantRenderType.tree:
          _drawTrees(canvas, areaPoints, aMinX, aMaxX, aMinY, aMaxY, rotRad,
              tiltFactor, scale, cx, cy, color, heightScale, maxHeight);
          break;
        case PlantRenderType.bush:
          _drawBushes(canvas, areaPoints, aMinX, aMaxX, aMinY, aMaxY, rotRad,
              tiltFactor, scale, cx, cy, color, heightScale);
          break;
        case PlantRenderType.root:
          _drawRoots(canvas, areaPoints, aMinX, aMaxX, aMinY, aMaxY, rotRad,
              tiltFactor, scale, cx, cy, color, heightScale);
          break;
        case PlantRenderType.vine:
          _drawVines(canvas, areaPoints, aMinX, aMaxX, aMinY, aMaxY, rotRad,
              tiltFactor, scale, cx, cy, color, heightScale);
          break;
        case PlantRenderType.broadleaf:
          _drawBroadleaf(canvas, areaPoints, aMinX, aMaxX, aMinY, aMaxY, rotRad,
              tiltFactor, scale, cx, cy, color, heightScale);
          break;
        case PlantRenderType.dense:
          _drawDense(canvas, areaPoints, aMinX, aMaxX, aMinY, aMaxY, rotRad,
              tiltFactor, scale, cx, cy, color, heightScale);
          break;
        default:
          _drawBushes(canvas, areaPoints, aMinX, aMaxX, aMinY, aMaxY, rotRad,
              tiltFactor, scale, cx, cy, color, heightScale);
      }
    }
  }

  double _computeGrowthFactor(Map<String, dynamic> crop) {
    final plantedDateStr = crop['planted_date']?.toString();
    if (plantedDateStr == null) return 0.5;
    DateTime? planted;
    final parts = plantedDateStr.split('.');
    if (parts.length == 3) {
      planted = DateTime.tryParse('${parts[2]}-${parts[1]}-${parts[0]}');
    }
    planted ??= DateTime.tryParse(plantedDateStr);
    if (planted == null) return 0.5;
    final harvestDays = (crop['harvest_days'] as num?)?.toInt() ?? 90;
    final elapsed = DateTime.now().difference(planted).inDays;
    return (elapsed / harvestDays).clamp(0.0, 1.0);
  }

  // ── TAHIL: paralel dikey çizgiler (sap) ──
  void _drawStalks(
      Canvas canvas,
      List<Offset> area,
      double minX, double maxX, double minY, double maxY,
      double rotRad, double tiltFactor, double scale, double cx, double cy,
      Color color, double heightScale, double maxHeight) {
    final stalkPaint = Paint()
      ..color = color.withValues(alpha: 0.8)
      ..strokeWidth = 1.5;
    final headPaint = Paint()..color = color;

    final spacing = (maxX - minX) / 12;
    if (spacing < 0.5) return;
    for (double x = minX + spacing / 2; x < maxX; x += spacing) {
      for (double y = minY + spacing / 2; y < maxY; y += spacing) {
        final pt = Offset(x, y);
        if (!_isInsideNormalized(pt, area)) continue;

        final base = _project(pt, rotRad, tiltFactor, scale, cx, cy);
        final h = maxHeight * heightScale * scale * 0.08;
        final top = Offset(base.dx, base.dy - h);
        canvas.drawLine(base, top, stalkPaint);

        // Başak
        canvas.drawCircle(top, 2.5 * heightScale, headPaint);
      }
    }
  }

  // ── AĞAÇ: daire taç + dikey gövde ──
  void _drawTrees(
      Canvas canvas,
      List<Offset> area,
      double minX, double maxX, double minY, double maxY,
      double rotRad, double tiltFactor, double scale, double cx, double cy,
      Color color, double heightScale, double maxHeight) {
    final trunkPaint = Paint()
      ..color = const Color(0xFF5D4037)
      ..strokeWidth = 2.5;
    final canopyPaint = Paint()..color = color.withValues(alpha: 0.75);

    final spacing = (maxX - minX) / 5;
    if (spacing < 0.5) return;
    for (double x = minX + spacing / 2; x < maxX; x += spacing) {
      for (double y = minY + spacing / 2; y < maxY; y += spacing) {
        final pt = Offset(x, y);
        if (!_isInsideNormalized(pt, area)) continue;

        final base = _project(pt, rotRad, tiltFactor, scale, cx, cy);
        final h = maxHeight * heightScale * scale * 0.06;
        final top = Offset(base.dx, base.dy - h);
        canvas.drawLine(base, top, trunkPaint);

        // Taç (yaprak küresi)
        final canopyR = 6.0 * heightScale + pulseValue;
        canvas.drawCircle(top, canopyR, canopyPaint);

        // Taç highlight
        canvas.drawCircle(
          Offset(top.dx - canopyR * 0.25, top.dy - canopyR * 0.25),
          canopyR * 0.4,
          Paint()..color = Colors.white.withValues(alpha: 0.12),
        );
      }
    }
  }

  // ── ÇALI/SEBZE: küçük dolu daireler ──
  void _drawBushes(
      Canvas canvas,
      List<Offset> area,
      double minX, double maxX, double minY, double maxY,
      double rotRad, double tiltFactor, double scale, double cx, double cy,
      Color color, double heightScale) {
    final bushPaint = Paint()..color = color.withValues(alpha: 0.7);
    final stemPaint = Paint()
      ..color = const Color(0xFF2E7D32)
      ..strokeWidth = 1;

    final spacing = (maxX - minX) / 8;
    if (spacing < 0.5) return;
    for (double x = minX + spacing / 2; x < maxX; x += spacing) {
      for (double y = minY + spacing / 2; y < maxY; y += spacing) {
        final pt = Offset(x, y);
        if (!_isInsideNormalized(pt, area)) continue;

        final base = _project(pt, rotRad, tiltFactor, scale, cx, cy);
        final h = 6.0 * heightScale * scale * 0.06;
        final top = Offset(base.dx, base.dy - h);
        canvas.drawLine(base, top, stemPaint);
        canvas.drawCircle(top, 3.5 * heightScale, bushPaint);
      }
    }
  }

  // ── KÖK: toprak altı simgesi (yarım daire + yaprak) ──
  void _drawRoots(
      Canvas canvas,
      List<Offset> area,
      double minX, double maxX, double minY, double maxY,
      double rotRad, double tiltFactor, double scale, double cx, double cy,
      Color color, double heightScale) {
    final rootPaint = Paint()..color = color.withValues(alpha: 0.6);
    final leafPaint = Paint()..color = const Color(0xFF66BB6A);

    final spacing = (maxX - minX) / 10;
    if (spacing < 0.5) return;
    for (double x = minX + spacing / 2; x < maxX; x += spacing) {
      for (double y = minY + spacing / 2; y < maxY; y += spacing) {
        final pt = Offset(x, y);
        if (!_isInsideNormalized(pt, area)) continue;

        final base = _project(pt, rotRad, tiltFactor, scale, cx, cy);
        // Kök gövdesi (yere gömülü)
        canvas.drawOval(
          Rect.fromCenter(center: base, width: 4 * heightScale, height: 3 * heightScale),
          rootPaint,
        );
        // Üstte küçük yaprak
        final topLeaf = Offset(base.dx, base.dy - 3 * heightScale);
        canvas.drawCircle(topLeaf, 2 * heightScale, leafPaint);
      }
    }
  }

  // ── SARILICI/ASMA: yatay eğri çizgiler ──
  void _drawVines(
      Canvas canvas,
      List<Offset> area,
      double minX, double maxX, double minY, double maxY,
      double rotRad, double tiltFactor, double scale, double cx, double cy,
      Color color, double heightScale) {
    final vinePaint = Paint()
      ..color = color.withValues(alpha: 0.6)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final spacing = (maxY - minY) / 8;
    if (spacing < 0.5) return;
    for (double y = minY + spacing; y < maxY; y += spacing) {
      final path = Path();
      bool started = false;
      for (double x = minX; x <= maxX; x += (maxX - minX) / 20) {
        final pt = Offset(x, y + math.sin(x * 0.1) * spacing * 0.2 * heightScale);
        if (!_isInsideNormalized(Offset(x, y), area)) continue;
        final proj = _project(pt, rotRad, tiltFactor, scale, cx, cy);
        if (!started) {
          path.moveTo(proj.dx, proj.dy);
          started = true;
        } else {
          path.lineTo(proj.dx, proj.dy);
        }
      }
      if (started) canvas.drawPath(path, vinePaint);
    }
  }

  // ── GENİŞ YAPRAK: dikdörtgen parçalar ──
  void _drawBroadleaf(
      Canvas canvas,
      List<Offset> area,
      double minX, double maxX, double minY, double maxY,
      double rotRad, double tiltFactor, double scale, double cx, double cy,
      Color color, double heightScale) {
    final leafPaint = Paint()..color = color.withValues(alpha: 0.55);

    final spacing = (maxX - minX) / 8;
    if (spacing < 0.5) return;
    for (double x = minX + spacing / 2; x < maxX; x += spacing) {
      for (double y = minY + spacing / 2; y < maxY; y += spacing) {
        final pt = Offset(x, y);
        if (!_isInsideNormalized(pt, area)) continue;
        final pos = _project(pt, rotRad, tiltFactor, scale, cx, cy);
        final s = 4.0 * heightScale;
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: pos, width: s * 1.5, height: s),
            Radius.circular(s * 0.3),
          ),
          leafPaint,
        );
      }
    }
  }

  // ── YOĞUN: küçük nokta grid ──
  void _drawDense(
      Canvas canvas,
      List<Offset> area,
      double minX, double maxX, double minY, double maxY,
      double rotRad, double tiltFactor, double scale, double cx, double cy,
      Color color, double heightScale) {
    final dotPaint = Paint()..color = color.withValues(alpha: 0.5);

    final spacing = (maxX - minX) / 16;
    if (spacing < 0.3) return;
    for (double x = minX; x < maxX; x += spacing) {
      for (double y = minY; y < maxY; y += spacing) {
        final pt = Offset(x, y);
        if (!_isInsideNormalized(pt, area)) continue;
        final pos = _project(pt, rotRad, tiltFactor, scale, cx, cy);
        canvas.drawCircle(pos, 1.5 * heightScale, dotPaint);
      }
    }
  }

  // ── PUSULA ──
  void _drawCompass(Canvas canvas, Size size, double rotRad) {
    final compassX = size.width - 45.0;
    final compassY = 50.0;
    final compassR = 18.0;

    // Daire
    canvas.drawCircle(
      Offset(compassX, compassY),
      compassR,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.6)
        ..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      Offset(compassX, compassY),
      compassR,
      Paint()
        ..color = const Color(0xFF00E676).withValues(alpha: 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    // Kuzey oku
    final nAngle = -rotRad - math.pi / 2;
    final nX = compassX + math.cos(nAngle) * (compassR - 4);
    final nY = compassY + math.sin(nAngle) * (compassR - 4);
    final sX = compassX - math.cos(nAngle) * (compassR - 6);
    final sY = compassY - math.sin(nAngle) * (compassR - 6);

    canvas.drawLine(
      Offset(sX, sY),
      Offset(nX, nY),
      Paint()
        ..color = const Color(0xFF00E676)
        ..strokeWidth = 2,
    );

    _drawTextCentered(canvas, 'K', Offset(nX, nY - 3),
        const Color(0xFF00E676), 8, FontWeight.bold);
  }

  // ── KÖŞE ETİKETLERİ ──
  void _drawCornerLabels(Canvas canvas, List<Offset> projected) {
    for (int i = 0; i < projected.length && i < 26; i++) {
      final pt = projected[i];
      // Köşe noktası dairesi
      canvas.drawCircle(
        pt,
        8,
        Paint()..color = Colors.black.withValues(alpha: 0.7),
      );
      canvas.drawCircle(
        pt,
        8,
        Paint()
          ..color = const Color(0xFF00E676)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
      _drawTextCentered(
          canvas, String.fromCharCode(65 + i), pt, const Color(0xFF00E676), 10, FontWeight.bold);
    }
  }

  void _drawTextCentered(Canvas canvas, String text, Offset pos, Color color,
      double fontSize, FontWeight weight) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: weight,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(pos.dx - tp.width / 2, pos.dy - tp.height / 2));
  }

  /// Zone polygon JSON'ı normalize koordinatlara çevirir.
  List<Offset> _parseZoneJsonToNormalized(String json) {
    // Sub-polygon koordinatlarını ana polygon merkezi referanslı normalize eder
    if (polygon.isEmpty) return [];

    double cLat = 0, cLng = 0;
    for (final p in polygon) {
      cLat += p.latitude;
      cLng += p.longitude;
    }
    cLat /= polygon.length;
    cLng /= polygon.length;
    final cosLat = math.cos(cLat * math.pi / 180);

    // JSON parse
    try {
      // json format: [{"lat":..,"lng":..}, ...]
      // Manuel parse çünkü dart:convert import yok
      final result = <Offset>[];
      final regex = RegExp(r'"lat"\s*:\s*([-\d.]+).*?"lng"\s*:\s*([-\d.]+)');
      for (final match in regex.allMatches(json)) {
        final lat = double.tryParse(match.group(1)!);
        final lng = double.tryParse(match.group(2)!);
        if (lat != null && lng != null) {
          final dx = (lng - cLng) * 111320 * cosLat;
          final dy = (lat - cLat) * 111320;
          result.add(Offset(dx, dy));
        }
      }
      return result;
    } catch (_) {
      return [];
    }
  }

  @override
  bool shouldRepaint(covariant _FieldPanoramaPainter old) =>
      old.rotationDeg != rotationDeg ||
      old.tiltDeg != tiltDeg ||
      old.zoom != zoom ||
      old.pulseValue != pulseValue;
}
