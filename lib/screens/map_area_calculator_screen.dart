import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:maps_toolkit/maps_toolkit.dart' as toolkit;
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';

class MapAreaCalculatorScreen extends StatefulWidget {
  final double initialLat;
  final double initialLng;

  const MapAreaCalculatorScreen({
    super.key,
    required this.initialLat,
    required this.initialLng,
  });

  @override
  State<MapAreaCalculatorScreen> createState() =>
      _MapAreaCalculatorScreenState();
}

class _MapAreaCalculatorScreenState extends State<MapAreaCalculatorScreen> {
  final MapController _mapController = MapController();
  final List<LatLng> _points = [];

  String _areaLabel = 'Tarlanın köşelerini dokunarak çizin (min. 4 nokta)';
  double _calculatedDekar = 0.0;

  // Katman seçimi: true = uydu, false = sokak
  bool _satellite = true;

  void _onMapTap(TapPosition _, LatLng latlng) {
    setState(() {
      _points.add(latlng);
      _areaLabel = '${_points.length} nokta işaretlendi'
          '${_points.length < 4 ? ' — daha ${4 - _points.length} nokta gerekli' : ''}';
    });
    if (_points.length >= 4) _calculateArea();
  }

  void _calculateArea() {
    final toolkitPts = _points
        .map((p) => toolkit.LatLng(p.latitude, p.longitude))
        .toList();
    final sqm = toolkit.SphericalUtil.computeArea(toolkitPts).toDouble();
    _calculatedDekar = sqm / 1000;
    final hektar = sqm / 10000;
    setState(() {
      _areaLabel =
          '${sqm.toStringAsFixed(0)} m²  •  ${_calculatedDekar.toStringAsFixed(2)} Dekar  •  ${hektar.toStringAsFixed(3)} ha';
    });
  }

  void _undoLastPoint() {
    if (_points.isEmpty) return;
    setState(() {
      _points.removeLast();
      _calculatedDekar = 0;
      _areaLabel = _points.isEmpty
          ? 'Tarlanın köşelerini dokunarak çizin (min. 4 nokta)'
          : '${_points.length} nokta işaretlendi'
              '${_points.length < 4 ? ' — daha ${4 - _points.length} nokta gerekli' : ''}';
    });
    if (_points.length >= 4) _calculateArea();
  }

  void _clearMap() {
    setState(() {
      _points.clear();
      _calculatedDekar = 0;
      _areaLabel = 'Tarlanın köşelerini dokunarak çizin (min. 4 nokta)';
    });
  }

  void _saveField() {
    if (_calculatedDekar == 0.0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content:
              Text('Önce 4 nokta işaretleyip alan hesaplanmalıdır!')));
      return;
    }

    double centerLat = 0, centerLng = 0;
    for (final p in _points) {
      centerLat += p.latitude;
      centerLng += p.longitude;
    }
    centerLat /= _points.length;
    centerLng /= _points.length;

    String name = '';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Bu Tarlayı Kaydet'),
        content: TextField(
          onChanged: (v) => name = v,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Örn: Kuzey Tarlası',
            helperText:
                '${_calculatedDekar.toStringAsFixed(1)} Dekar otomatik eklenecek',
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('İptal')),
          FilledButton(
            onPressed: () {
              if (name.trim().isNotEmpty) {
                final box = Hive.box('user_crops');
                box.add({
                  'name':
                      '${name.trim()} (${_calculatedDekar.toStringAsFixed(1)} Dekar)',
                  'date': DateFormat('dd.MM.yyyy').format(DateTime.now()),
                  'latitude': centerLat,
                  'longitude': centerLng,
                  'area_dekar': _calculatedDekar,
                });
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Tarla başarıyla kaydedildi!')));
              }
            },
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
  }

  List<Marker> _buildMarkers() {
    return List.generate(_points.length, (i) {
      final p = _points[i];
      return Marker(
        point: p,
        width: 28,
        height: 28,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.green.shade700,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: const [
              BoxShadow(color: Colors.black38, blurRadius: 4)
            ],
          ),
          child: Center(
            child: Text(
              '${i + 1}',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold),
            ),
          ),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    // Kapalı polygon için son nokta = ilk nokta
    final closedPoints =
        _points.length >= 3 ? [..._points, _points.first] : <LatLng>[];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tarla Hektar Hesaplayıcı'),
        actions: [
          // Katman değiştir
          IconButton(
            icon: Icon(
              _satellite ? Icons.map_outlined : Icons.satellite_alt,
              color: Colors.white,
            ),
            onPressed: () => setState(() => _satellite = !_satellite),
            tooltip: _satellite ? 'Sokak görünümü' : 'Uydu görünümü',
          ),
          IconButton(
              icon: const Icon(Icons.undo),
              onPressed: _undoLastPoint,
              tooltip: 'Son Noktayı Sil'),
          IconButton(
              icon: const Icon(Icons.cleaning_services),
              onPressed: _clearMap,
              tooltip: 'Haritayı Temizle'),
        ],
      ),
      body: Column(children: [
        // ── ALAN GÖSTERGESİ ──
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          color: _calculatedDekar > 0
              ? Colors.green.shade700
              : Colors.blueGrey.shade800,
          width: double.infinity,
          child: Text(
            _areaLabel,
            style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colors.white),
            textAlign: TextAlign.center,
          ),
        ),

        // ── HARİTA ──
        Expanded(
          child: FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter:
                  LatLng(widget.initialLat, widget.initialLng),
              initialZoom: 17.0,
              onTap: _onMapTap,
            ),
            children: [
              // Uydu katmanı (ESRI — ücretsiz, anahtar yok)
              if (_satellite)
                TileLayer(
                  urlTemplate:
                      'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
                  userAgentPackageName: 'com.example.feng_498',
                  maxZoom: 21,
                ),
              // Sokak katmanı (OpenStreetMap — ücretsiz)
              if (!_satellite)
                TileLayer(
                  urlTemplate:
                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.feng_498',
                  maxZoom: 19,
                ),
              // Uydu üstü yer adı katmanı
              if (_satellite)
                TileLayer(
                  urlTemplate:
                      'https://services.arcgisonline.com/ArcGIS/rest/services/Reference/World_Boundaries_and_Places/MapServer/tile/{z}/{y}/{x}',
                  userAgentPackageName: 'com.example.feng_498',
                  maxZoom: 21,
                ),
              // Polygon dolgusu
              if (closedPoints.length >= 3)
                PolygonLayer(polygons: [
                  Polygon(
                    points: closedPoints,
                    color: Colors.green.withValues(alpha: 0.3),
                    borderColor: Colors.greenAccent,
                    borderStrokeWidth: 2.5,
                  ),
                ]),
              // Noktalar arası çizgi
              if (_points.length >= 2)
                PolylineLayer(polylines: [
                  Polyline(
                    points: [..._points, if (_points.length >= 3) _points.first],
                    color: Colors.greenAccent,
                    strokeWidth: 2.0,
                  ),
                ]),
              // Nokta numaraları
              MarkerLayer(markers: _buildMarkers()),
            ],
          ),
        ),

        // ── ALT BUTONLAR ──
        Container(
          color: Colors.grey.shade900,
          padding: const EdgeInsets.all(12),
          child: Row(children: [
            Expanded(
              child: FilledButton.icon(
                onPressed:
                    _points.length >= 4 ? _calculateArea : null,
                icon: const Icon(Icons.calculate),
                label: const Text('ALANI HESAPLA'),
                style: FilledButton.styleFrom(
                    backgroundColor: Colors.amber.shade800,
                    padding:
                        const EdgeInsets.symmetric(vertical: 14)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton.icon(
                onPressed: _calculatedDekar > 0 ? _saveField : null,
                icon: const Icon(Icons.save),
                label: const Text('KAYDET'),
                style: FilledButton.styleFrom(
                    backgroundColor: Colors.green.shade700,
                    padding:
                        const EdgeInsets.symmetric(vertical: 14)),
              ),
            ),
          ]),
        ),
      ]),
    );
  }
}
