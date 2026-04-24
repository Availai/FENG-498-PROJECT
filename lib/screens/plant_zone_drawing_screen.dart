import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:maps_toolkit/maps_toolkit.dart' as toolkit;

import '../theme/app_theme.dart';
import '../widgets/zone_drawing_toolbar.dart';

/// Mevcut ekili bir bölgeyi haritada gösterirken kullanılır.
class ExistingPlantZone {
  final String name;
  final Color color;
  final List<LatLng> polygon;

  const ExistingPlantZone({
    required this.name,
    required this.color,
    required this.polygon,
  });
}

/// Seçilen bitki için tarla içinde tam-uydu haritası üstünde
/// tap-to-place ile poligon çizme ekranı.
///
/// Sonuç: `Navigator.pop(zonePolygonJson)` — iptal durumunda `null`.
class PlantZoneDrawingScreen extends StatefulWidget {
  final String plantName;
  final Color plantColor;
  final List<LatLng> fieldPolygon;
  final List<ExistingPlantZone> existingZones;
  final double? initialTargetDekar;

  const PlantZoneDrawingScreen({
    super.key,
    required this.plantName,
    required this.plantColor,
    required this.fieldPolygon,
    this.existingZones = const [],
    this.initialTargetDekar,
  });

  @override
  State<PlantZoneDrawingScreen> createState() => _PlantZoneDrawingScreenState();
}

class _PlantZoneDrawingScreenState extends State<PlantZoneDrawingScreen>
    with SingleTickerProviderStateMixin {
  final MapController _mapController = MapController();
  final List<LatLng> _zonePoints = [];
  late final TextEditingController _targetDekarCtrl;
  double _zoneAreaSqm = 0.0;

  /// Tarla toplam alanı (m²)
  double get _fieldAreaSqm {
    if (widget.fieldPolygon.length < 3) return 0;
    final pts = widget.fieldPolygon
        .map((p) => toolkit.LatLng(p.latitude, p.longitude))
        .toList();
    return toolkit.SphericalUtil.computeArea(pts).toDouble();
  }

  /// Mevcut ekili bölgelerin toplam alanı (m²)
  double get _usedAreaSqm {
    double total = 0;
    for (final zone in widget.existingZones) {
      if (zone.polygon.length >= 3) {
        final pts = zone.polygon
            .map((p) => toolkit.LatLng(p.latitude, p.longitude))
            .toList();
        total += toolkit.SphericalUtil.computeArea(pts).toDouble();
      }
    }
    return total;
  }

  /// Kalan boş alan (m²) = tarla toplam - ekili - aktif çizim
  double get _remainingAreaSqm {
    return (_fieldAreaSqm - _usedAreaSqm - _zoneAreaSqm).clamp(0, double.infinity);
  }

  late final AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _targetDekarCtrl = TextEditingController(
      text: widget.initialTargetDekar == null
          ? ''
          : widget.initialTargetDekar!.toStringAsFixed(2),
    );
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _targetDekarCtrl.dispose();
    super.dispose();
  }

  LatLng get _fieldCenter {
    if (widget.fieldPolygon.isEmpty) return const LatLng(39.0, 35.0);
    double lat = 0, lng = 0;
    for (final p in widget.fieldPolygon) {
      lat += p.latitude;
      lng += p.longitude;
    }
    return LatLng(
      lat / widget.fieldPolygon.length,
      lng / widget.fieldPolygon.length,
    );
  }

  bool _pointInField(LatLng p) {
    if (widget.fieldPolygon.length < 3) return true;
    return toolkit.PolygonUtil.containsLocation(
      toolkit.LatLng(p.latitude, p.longitude),
      widget.fieldPolygon
          .map((e) => toolkit.LatLng(e.latitude, e.longitude))
          .toList(),
      true,
    );
  }

  void _onTap(TapPosition _, LatLng latlng) {
    if (!_pointInField(latlng)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red.shade600,
          content: const Text('Köşe tarla sınırı içinde olmalı'),
          duration: const Duration(milliseconds: 1200),
        ),
      );
      return;
    }
    setState(() => _zonePoints.add(latlng));
    if (_zonePoints.length >= 3) _recalcArea();
  }

  void _recalcArea() {
    final pts = _zonePoints
        .map((p) => toolkit.LatLng(p.latitude, p.longitude))
        .toList();
    _zoneAreaSqm = toolkit.SphericalUtil.computeArea(pts).toDouble();
  }

  void _undo() {
    if (_zonePoints.isEmpty) return;
    setState(() {
      _zonePoints.removeLast();
      if (_zonePoints.length < 3) {
        _zoneAreaSqm = 0;
      } else {
        _recalcArea();
      }
    });
  }

  void _cancel() => Navigator.of(context).pop();

  void _suggestByDekar() {
    final targetDekar =
        double.tryParse(_targetDekarCtrl.text.trim().replaceAll(',', '.'));
    if (targetDekar == null || targetDekar <= 0 || widget.fieldPolygon.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Geçerli bir dekar değeri girin.')),
      );
      return;
    }

    final targetSqm = targetDekar * 1000.0;
    final availableSqm = (_fieldAreaSqm - _usedAreaSqm).clamp(0.0, double.infinity);
    if (targetSqm > availableSqm + 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Kalan alan ${(_remainingAreaSqm / 1000).toStringAsFixed(2)} dekar. Daha küçük bir değer girin.',
          ),
        ),
      );
      return;
    }

    if (_fieldAreaSqm <= 0) return;
    final scale = math.sqrt((targetSqm / _fieldAreaSqm).clamp(0.02, 1.0));
    final center = _fieldCenter;
    final suggested = widget.fieldPolygon.map((p) {
      final lat = center.latitude + (p.latitude - center.latitude) * scale;
      final lng = center.longitude + (p.longitude - center.longitude) * scale;
      return LatLng(lat, lng);
    }).toList();

    setState(() {
      _zonePoints
        ..clear()
        ..addAll(suggested);
      _recalcArea();
    });
  }

  void _complete() {
    if (_zonePoints.length < 3) return;
    final json = jsonEncode(
      _zonePoints
          .map((p) => {'lat': p.latitude, 'lng': p.longitude})
          .toList(),
    );
    Navigator.of(context).pop(json);
  }

  void _useWholeField() {
    if (widget.fieldPolygon.length < 3) return;
    final json = jsonEncode(
      widget.fieldPolygon
          .map((p) => {'lat': p.latitude, 'lng': p.longitude})
          .toList(),
    );
    Navigator.of(context).pop(json);
  }

  @override
  Widget build(BuildContext context) {
    final dekar = (_zoneAreaSqm / 1000).toStringAsFixed(2);

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black.withValues(alpha: 0.35),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.plantName,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const Text(
              'ekim bölgesi çiz',
              style: TextStyle(fontSize: 11, color: Colors.white70),
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: _useWholeField,
            icon: const Icon(Icons.select_all_rounded,
                color: Colors.white, size: 18),
            label: const Text(
              'Tarlanın tamamı',
              style: TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _fieldCenter,
              initialZoom: 19.0,
              maxZoom: 21,
              onTap: _onTap,
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
                userAgentPackageName: 'com.example.feng_498',
                maxZoom: 21,
              ),
              // Field outline — kullanıcıya sınırı gösterir
              if (widget.fieldPolygon.length >= 3)
                PolygonLayer(
                  polygons: [
                    Polygon(
                      points: widget.fieldPolygon,
                      color: Colors.white.withValues(alpha: 0.05),
                      borderColor: Colors.white.withValues(alpha: 0.9),
                      borderStrokeWidth: 2.5,
                    ),
                  ],
                ),
              // ── Mevcut ekili bölgeler (daha önce eklenen bitkiler) ──
              if (widget.existingZones.isNotEmpty)
                PolygonLayer(
                  polygons: [
                    for (final zone in widget.existingZones)
                      if (zone.polygon.length >= 3)
                        Polygon(
                          points: zone.polygon,
                          color: zone.color.withValues(alpha: 0.35),
                          borderColor: zone.color,
                          borderStrokeWidth: 2.5,
                        ),
                  ],
                ),
              // ── Mevcut bölge isim etiketleri ──
              if (widget.existingZones.isNotEmpty)
                MarkerLayer(
                  markers: [
                    for (final zone in widget.existingZones)
                      if (zone.polygon.length >= 3)
                        Marker(
                          point: _polygonCenter(zone.polygon),
                          width: 120,
                          height: 32,
                          child: IgnorePointer(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.75),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: zone.color.withValues(alpha: 0.8),
                                  width: 1.5,
                                ),
                              ),
                              child: Text(
                                zone.name,
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.outfit(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ),
                  ],
                ),
              // Aktif çizim polygon'u
              if (_zonePoints.length >= 3)
                PolygonLayer(
                  polygons: [
                    Polygon(
                      points: _zonePoints,
                      color: widget.plantColor.withValues(alpha: 0.45),
                      borderColor: widget.plantColor,
                      borderStrokeWidth: 2.5,
                    ),
                  ],
                ),
              // Çizim sırasında çizgi önizlemesi
              if (_zonePoints.isNotEmpty)
                PolylineLayer<Object>(
                  polylines: [
                    Polyline(
                      points: _zonePoints.length >= 3
                          ? [..._zonePoints, _zonePoints.first]
                          : [..._zonePoints],
                      color: widget.plantColor,
                      strokeWidth: 2.5,
                    ),
                  ],
                ),
              // Köşe marker'ları + son noktada pulse animasyonu
              MarkerLayer(
                markers: [
                  for (int i = 0; i < _zonePoints.length; i++)
                    Marker(
                      point: _zonePoints[i],
                      width: 22,
                      height: 22,
                      child: AnimatedBuilder(
                        animation: _pulseCtrl,
                        builder: (_, __) {
                          final isLast = i == _zonePoints.length - 1;
                          final scale =
                              isLast ? 1.0 + 0.25 * _pulseCtrl.value : 1.0;
                          return Transform.scale(
                            scale: scale,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: widget.plantColor,
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: widget.plantColor
                                        .withValues(alpha: 0.6),
                                    blurRadius: 8,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ],
          ),

          // Üstte alan göstergesi — her zaman göster (ekili alan bilgisi)
          Positioned(
            top: MediaQuery.of(context).padding.top + kToolbarHeight + 8,
            left: 16,
            right: 16,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: widget.plantColor.withValues(alpha: 0.5),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 92,
                          child: TextField(
                            key: const Key('zone_target_dekar_field'),
                            controller: _targetDekarCtrl,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                            decoration: InputDecoration(
                              isDense: true,
                              hintText: 'Dekar',
                              hintStyle: const TextStyle(color: Colors.white54),
                              suffixText: 'da',
                              suffixStyle: const TextStyle(color: Colors.white70),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 8,
                              ),
                              filled: true,
                              fillColor: Colors.white.withValues(alpha: 0.08),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(
                                  color: Colors.white.withValues(alpha: 0.18),
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(
                                  color: Colors.white.withValues(alpha: 0.18),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        FilledButton.icon(
                          key: const Key('zone_auto_suggest_button'),
                          onPressed: _suggestByDekar,
                          icon: const Icon(Icons.auto_fix_high_rounded, size: 15),
                          label: const Text('Öner'),
                          style: FilledButton.styleFrom(
                            backgroundColor: widget.plantColor,
                            foregroundColor: Colors.black,
                            visualDensity: VisualDensity.compact,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    // Aktif çizim alanı
                    if (_zonePoints.length >= 3)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.square_foot_rounded,
                                color: widget.plantColor, size: 16),
                            const SizedBox(width: 6),
                            Text(
                              '$dekar dönüm',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Container(
                                width: 1, height: 14, color: Colors.white24),
                            const SizedBox(width: 10),
                            Text(
                              '${_zonePoints.length} köşe',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    // Alan özeti — ekili + kalan
                    if (widget.existingZones.isNotEmpty || _zonePoints.length >= 3)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Mevcut ekili
                          if (widget.existingZones.isNotEmpty) ...[
                            const Icon(Icons.check_circle_outline,
                                color: Color(0xFF66BB6A), size: 13),
                            const SizedBox(width: 4),
                            Text(
                              'Ekili: ${(_usedAreaSqm / 1000).toStringAsFixed(2)} dönüm',
                              style: const TextStyle(
                                color: Color(0xFF66BB6A),
                                fontWeight: FontWeight.w600,
                                fontSize: 11,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Container(
                                width: 1, height: 12, color: Colors.white24),
                            const SizedBox(width: 10),
                          ],
                          // Kalan alan
                          const Icon(Icons.crop_free_rounded,
                              color: Color(0xFF42A5F5), size: 13),
                          const SizedBox(width: 4),
                          Text(
                            'Kalan: ${(_remainingAreaSqm / 1000).toStringAsFixed(2)} dönüm',
                            style: const TextStyle(
                              color: Color(0xFF42A5F5),
                              fontWeight: FontWeight.w600,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ),

          // Alt çizim araç çubuğu
          Positioned(
            left: 12,
            right: 12,
            bottom: MediaQuery.of(context).padding.bottom + 16,
            child: ZoneDrawingToolbar(
              plantName: widget.plantName,
              plantColor: widget.plantColor,
              pointCount: _zonePoints.length,
              onUndo: _undo,
              onComplete: _complete,
              onCancel: _cancel,
            ),
          ),

          // Boş durumda merkez ipucu
          if (_zonePoints.isEmpty)
            IgnorePointer(
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 18, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.55),
                    borderRadius: AppRadius.lg,
                  ),
                  child: const Text(
                    'Tarla içinde köşe noktalarına dokunun',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Poligonun merkez noktasını hesapla (etiket konumu için)
  LatLng _polygonCenter(List<LatLng> poly) {
    double lat = 0, lng = 0;
    for (final p in poly) {
      lat += p.latitude;
      lng += p.longitude;
    }
    return LatLng(lat / poly.length, lng / poly.length);
  }
}
