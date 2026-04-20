import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:maps_toolkit/maps_toolkit.dart' as toolkit;

import '../theme/app_theme.dart';
import '../widgets/zone_drawing_toolbar.dart';

/// Seçilen bitki için tarla içinde tam-uydu haritası üstünde
/// tap-to-place ile poligon çizme ekranı.
///
/// Sonuç: `Navigator.pop(zonePolygonJson)` — iptal durumunda `null`.
class PlantZoneDrawingScreen extends StatefulWidget {
  final String plantName;
  final Color plantColor;
  final List<LatLng> fieldPolygon;

  const PlantZoneDrawingScreen({
    super.key,
    required this.plantName,
    required this.plantColor,
    required this.fieldPolygon,
  });

  @override
  State<PlantZoneDrawingScreen> createState() => _PlantZoneDrawingScreenState();
}

class _PlantZoneDrawingScreenState extends State<PlantZoneDrawingScreen>
    with SingleTickerProviderStateMixin {
  final MapController _mapController = MapController();
  final List<LatLng> _zonePoints = [];
  double _zoneAreaSqm = 0.0;

  late final AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
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

          // Üstte alan göstergesi (çizim varsa)
          if (_zonePoints.length >= 3)
            Positioned(
              top: MediaQuery.of(context).padding.top + kToolbarHeight + 8,
              left: 16,
              right: 16,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: widget.plantColor.withValues(alpha: 0.6),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.square_foot_rounded,
                          color: widget.plantColor, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        '$dekar dekar',
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
}
