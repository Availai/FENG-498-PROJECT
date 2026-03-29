import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
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
  final List<LatLng> _polygonPoints = [];
  final Set<Marker> _markers = {};
  Set<Polygon> _polygons = {};
  String _calculatedArea = "Alanı Görmek İçin Tarlanın Köşelerini Çizin";
  double _calculatedDekar = 0.0; // Kaydetmek için dekarı hafızada tutuyoruz

  void _onMapTapped(LatLng point) {
    setState(() {
      _polygonPoints.add(point);
      _markers.add(
        Marker(markerId: MarkerId(point.toString()), position: point),
      );
      _updatePolygon();
    });
  }

  void _undoLastPoint() {
    if (_polygonPoints.isNotEmpty) {
      setState(() {
        final lastPoint = _polygonPoints.removeLast();
        _markers.removeWhere((m) => m.position == lastPoint);
        _updatePolygon();
      });
    }
  }

  void _updatePolygon() {
    if (_polygonPoints.length >= 3) {
      _polygons = {
        Polygon(
          polygonId: const PolygonId('field_polygon'),
          points: _polygonPoints,
          strokeWidth: 3,
          strokeColor: Colors.green,
          fillColor: Colors.green.withValues(alpha: 0.3),
        ),
      };
    } else {
      _polygons.clear();
      _calculatedArea = "Alanı Görmek İçin Tarlanın Köşelerini Çizin";
      _calculatedDekar = 0.0;
    }
  }

  void _calculateArea() {
    if (_polygonPoints.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Alan hesaplamak için en az 3 nokta seçmelisiniz!'),
        ),
      );
      return;
    }

    List<toolkit.LatLng> toolkitPoints = _polygonPoints
        .map((p) => toolkit.LatLng(p.latitude, p.longitude))
        .toList();
    double areaSqMeters =
        toolkit.SphericalUtil.computeArea(toolkitPoints).toDouble();

    _calculatedDekar = areaSqMeters / 1000;
    double hektar = areaSqMeters / 10000;

    setState(() {
      _calculatedArea =
          '''
M²: ${areaSqMeters.toStringAsFixed(2)} m²
Dekar (Dönüm): ${_calculatedDekar.toStringAsFixed(2)}
Hektar: ${hektar.toStringAsFixed(3)}
''';
    });
  }

  void _clearMap() {
    setState(() {
      _polygonPoints.clear();
      _markers.clear();
      _polygons.clear();
      _calculatedArea = "Alanı Görmek İçin Tarlanın Köşelerini Çizin";
      _calculatedDekar = 0.0;
    });
  }

  void _saveToMyCrops() {
    if (_calculatedDekar == 0.0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Önce tarlayı çizip ALANI HESAPLA butonuna basın!'),
        ),
      );
      return;
    }

    // Poligonun orta noktasını hesapla
    double centerLat = 0, centerLng = 0;
    for (final p in _polygonPoints) {
      centerLat += p.latitude;
      centerLng += p.longitude;
    }
    centerLat /= _polygonPoints.length;
    centerLng /= _polygonPoints.length;

    String name = '';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Bu Tarlayı Kaydet'),
        content: TextField(
          onChanged: (v) => name = v,
          decoration: InputDecoration(
            hintText: 'Örn: Arka Bahçe',
            helperText:
                'Otomatik olarak ${_calculatedDekar.toStringAsFixed(1)} Dekar eklenecek',
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('İptal'),
          ),
          FilledButton(
            onPressed: () {
              if (name.isNotEmpty) {
                final box = Hive.box('user_crops');
                box.add({
                  'name':
                      '$name (${_calculatedDekar.toStringAsFixed(1)} Dekar)',
                  'date': DateFormat('dd.MM.yyyy').format(DateTime.now()),
                  'latitude': centerLat,
                  'longitude': centerLng,
                  'area_dekar': _calculatedDekar,
                });
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Tarla ölçüsüyle birlikte Tarlalarım sekmesine kaydedildi!',
                    ),
                  ),
                );
              }
            },
            child: const Text('Tarlalarıma Kaydet'),
          ),
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tarla Hektar Hesaplayıcı'),
        actions: [
          IconButton(
            icon: const Icon(Icons.undo),
            onPressed: _undoLastPoint,
            tooltip: 'Son Noktayı Sil',
          ),
          IconButton(
            icon: const Icon(Icons.cleaning_services),
            onPressed: _clearMap,
            tooltip: 'Haritayı Temizle',
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.blue.shade50,
            width: double.infinity,
            child: Text(
              _calculatedArea,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blueAccent,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: LatLng(widget.initialLat, widget.initialLng),
                zoom: 18.0,
              ),
              mapType: MapType.satellite,
              markers: _markers,
              polygons: _polygons,
              onTap: _onMapTapped,
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _calculateArea,
                    icon: const Icon(Icons.calculate),
                    label: const Text('ALANI HESAPLA'),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.amber.shade900,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _saveToMyCrops,
                    icon: const Icon(Icons.save),
                    label: const Text('KAYDET'),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.green.shade700,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
