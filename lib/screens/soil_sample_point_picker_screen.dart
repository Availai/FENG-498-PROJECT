import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:maps_toolkit/maps_toolkit.dart' as toolkit;

import '../theme/app_theme.dart';

/// Daha önce alınmış bir örnek noktası — haritada gri işaretle gösterilir.
class SoilSamplePastPoint {
  final LatLng point;
  final String label;
  const SoilSamplePastPoint({required this.point, required this.label});
}

/// Bir alan seçiminin sonucu — merkez nokta + temsil ettiği yarıçap (metre).
///
/// Geriye dönük uyumluluk: çağıranlar yalnızca [center]'ı (LatLng) kullanabilir;
/// [radiusMeters] alanı temsil eden dairenin yarıçapıdır.
class SoilSampleArea {
  final LatLng center;
  final double radiusMeters;
  const SoilSampleArea({required this.center, required this.radiusMeters});
}

/// Toprak örneğinin alındığı tarla kısmını harita üzerinde seçtirir.
///
/// Çiftçi tarlaya dokunarak örnek **alanının** merkezini işaretler; alt çubuktaki
/// kaydırıcıyla alanı (daire) büyütüp küçültür. Tek bir nokta yerine bir alanı
/// temsil eder. Sonuç [SoilSampleArea] (merkez + yarıçap) olarak döner
/// (`Navigator.pop(SoilSampleArea)` — iptalde `null`).
class SoilSamplePointPickerScreen extends StatefulWidget {
  final List<LatLng> fieldPolygon;
  final String fieldName;
  final LatLng? initialPoint;
  final List<SoilSamplePastPoint> pastPoints;

  /// Başlangıç alan yarıçapı (metre). Varsayılan 25 m.
  final double initialRadiusMeters;

  const SoilSamplePointPickerScreen({
    super.key,
    required this.fieldPolygon,
    required this.fieldName,
    this.initialPoint,
    this.pastPoints = const [],
    this.initialRadiusMeters = 25,
  });

  @override
  State<SoilSamplePointPickerScreen> createState() =>
      _SoilSamplePointPickerScreenState();
}

class _SoilSamplePointPickerScreenState
    extends State<SoilSamplePointPickerScreen> {
  final MapController _mapController = MapController();
  LatLng? _selected;
  late double _radiusMeters;

  static const double _minZoom = 14.0;
  static const double _maxZoom = 21.0;
  static const double _minRadius = 5.0;
  static const double _maxRadius = 200.0;

  @override
  void initState() {
    super.initState();
    _selected = widget.initialPoint;
    _radiusMeters =
        widget.initialRadiusMeters.clamp(_minRadius, _maxRadius).toDouble();
  }

  LatLng get _fieldCenter {
    if (widget.fieldPolygon.isEmpty) {
      return widget.initialPoint ?? const LatLng(39.0, 35.0);
    }
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
          backgroundColor: AppColors.error,
          content: const Text('Nokta tarla sınırı içinde olmalı.'),
          duration: const Duration(milliseconds: 1200),
        ),
      );
      return;
    }
    setState(() => _selected = latlng);
  }

  void _useCenter() => setState(() => _selected = _fieldCenter);

  void _complete() {
    if (_selected == null) return;
    Navigator.of(context).pop(
      SoilSampleArea(center: _selected!, radiusMeters: _radiusMeters),
    );
  }

  void _zoomIn() {
    final z = _mapController.camera.zoom;
    _mapController.move(
        _mapController.camera.center, (z + 1).clamp(_minZoom, _maxZoom));
  }

  void _zoomOut() {
    final z = _mapController.camera.zoom;
    _mapController.move(
        _mapController.camera.center, (z - 1).clamp(_minZoom, _maxZoom));
  }

  void _fitToField() {
    if (widget.fieldPolygon.length < 2) {
      _mapController.move(_fieldCenter, 19.0);
      return;
    }
    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: LatLngBounds.fromPoints(widget.fieldPolygon),
        padding: const EdgeInsets.all(60),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
              widget.fieldName,
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white),
            ),
            const Text('örnek alanını seç',
                style: TextStyle(fontSize: 11, color: Colors.white70)),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: _useCenter,
            icon: const Icon(Icons.center_focus_weak_rounded,
                color: Colors.white, size: 18),
            label: const Text('Tarla merkezi',
                style: TextStyle(color: Colors.white, fontSize: 12)),
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _selected ?? _fieldCenter,
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
              // Geçmiş örnek noktaları (gri)
              if (widget.pastPoints.isNotEmpty)
                MarkerLayer(
                  markers: [
                    for (final p in widget.pastPoints)
                      Marker(
                        point: p.point,
                        width: 26,
                        height: 26,
                        child: const IgnorePointer(
                          child: Icon(Icons.circle,
                              size: 14, color: Colors.white70),
                        ),
                      ),
                  ],
                ),
              // Seçilen alan (yeşil daire)
              if (_selected != null)
                CircleLayer(
                  circles: [
                    CircleMarker(
                      point: _selected!,
                      radius: _radiusMeters,
                      useRadiusInMeter: true,
                      color: AppColors.emerald.withValues(alpha: 0.18),
                      borderColor: AppColors.emerald.withValues(alpha: 0.9),
                      borderStrokeWidth: 2,
                    ),
                  ],
                ),
              // Seçilen nokta (yeşil pin)
              if (_selected != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _selected!,
                      width: 44,
                      height: 44,
                      alignment: Alignment.topCenter,
                      child: const Icon(Icons.location_on,
                          size: 44, color: AppColors.emerald),
                    ),
                  ],
                ),
            ],
          ),

          // Bilgi kartı
          Positioned(
            top: MediaQuery.of(context).padding.top + kToolbarHeight + 8,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(14),
                border:
                    Border.all(color: AppColors.emerald.withValues(alpha: 0.5)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.touch_app_rounded,
                      color: AppColors.emeraldLight, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _selected == null
                          ? 'Örneği aldığınız tarla kısmına dokunun.'
                          : 'Alan seçildi: ${_selected!.latitude.toStringAsFixed(5)}, ${_selected!.longitude.toStringAsFixed(5)} • yarıçap ${_radiusMeters.toStringAsFixed(0)} m',
                      style:
                          const TextStyle(color: Colors.white, fontSize: 12.5),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Zoom kontrolleri
          Positioned(
            right: 12,
            top: MediaQuery.of(context).padding.top + kToolbarHeight + 78,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _zoomBtn(Icons.add, _zoomIn, 'Yakınlaştır'),
                const SizedBox(height: 8),
                _zoomBtn(Icons.remove, _zoomOut, 'Uzaklaştır'),
                const SizedBox(height: 8),
                _zoomBtn(
                    Icons.center_focus_strong, _fitToField, 'Tarlaya sığdır'),
              ],
            ),
          ),

          // Alt panel: yarıçap kaydırıcısı + aksiyon çubuğu
          Positioned(
            left: 16,
            right: 16,
            bottom: MediaQuery.of(context).padding.bottom + 16,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_selected != null) _radiusPanel(),
                if (_selected != null) const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: BorderSide(
                              color: Colors.white.withValues(alpha: 0.5)),
                          minimumSize: const Size.fromHeight(50),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                        child: const Text('İptal'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: FilledButton.icon(
                        onPressed: _selected == null ? null : _complete,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.emerald,
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(50),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                        icon: const Icon(Icons.check_rounded),
                        label: Text('Alanı kullan',
                            style: GoogleFonts.outfit(
                                fontWeight: FontWeight.w700, fontSize: 15)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _radiusPanel() {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.emerald.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.adjust_rounded,
                  color: AppColors.emeraldLight, size: 18),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Örnek alanı (yarıçap)',
                  style: TextStyle(color: Colors.white, fontSize: 12.5),
                ),
              ),
              Text(
                '${_radiusMeters.toStringAsFixed(0)} m',
                style: const TextStyle(
                    color: AppColors.emeraldLight,
                    fontSize: 13,
                    fontWeight: FontWeight.w700),
              ),
            ],
          ),
          SliderTheme(
            data: SliderThemeData(
              trackHeight: 3,
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
            ),
            child: Slider(
              value: _radiusMeters,
              min: _minRadius,
              max: _maxRadius,
              divisions: 39,
              label: '${_radiusMeters.toStringAsFixed(0)} m',
              activeColor: AppColors.emerald,
              inactiveColor: Colors.white24,
              onChanged: (v) => setState(() => _radiusMeters = v),
            ),
          ),
        ],
      ),
    );
  }

  Widget _zoomBtn(IconData icon, VoidCallback onTap, String tooltip) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.black.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: AppColors.emerald.withValues(alpha: 0.6), width: 1.2),
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
        ),
      ),
    );
  }
}
