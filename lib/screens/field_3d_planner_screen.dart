import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:maps_toolkit/maps_toolkit.dart' as toolkit;
import 'package:intl/intl.dart';
import '../services/app_providers.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_panel.dart';

class Field3DPlannerScreen extends ConsumerStatefulWidget {
  final double initialLat;
  final double initialLng;
  final Map<String, dynamic>? existingField; // If editing an existing field
  final int? fieldIndex;

  const Field3DPlannerScreen({
    super.key,
    required this.initialLat,
    required this.initialLng,
    this.existingField,
    this.fieldIndex,
  });

  @override
  ConsumerState<Field3DPlannerScreen> createState() => _Field3DPlannerScreenState();
}

class _Field3DPlannerScreenState extends ConsumerState<Field3DPlannerScreen> {
  final MapController _mapController = MapController();
  List<LatLng> _points = [];
  String _selectedCrop = 'Buğday';
  double _calculatedAreaSqm = 0.0;
  
  // Tohum hesaplama sabitleri (dekara kg veya bitki başı)
  final Map<String, double> _cropDensity = {
    'Buğday': 20.0, // dekara 20 kg
    'Mısır': 7.0, // dekara 7000 tohum ~ 7 kg
    'Ayçiçeği': 0.5, // dekara 0.5 kg
    'Pamuk': 2.5, // dekara 2.5 kg
    'Domates': 3000.0, // dekara 3000 kök
  };

  @override
  void initState() {
    super.initState();
    if (widget.existingField != null) {
      if (widget.existingField!['polygon'] != null) {
        _points = (widget.existingField!['polygon'] as List)
            .map((e) => LatLng(e['lat'], e['lng']))
            .toList();
        _calculateArea();
      }
      if (widget.existingField!['crop'] != null) {
        _selectedCrop = widget.existingField!['crop'];
      }
    }
  }

  void _onMapTap(TapPosition _, LatLng latlng) {
    setState(() {
      _points.add(latlng);
    });
    if (_points.length >= 3) _calculateArea();
  }

  void _calculateArea() {
    final toolkitPts = _points
        .map((p) => toolkit.LatLng(p.latitude, p.longitude))
        .toList();
    _calculatedAreaSqm = toolkit.SphericalUtil.computeArea(toolkitPts).toDouble();
    setState(() {});
  }

  void _undoLastPoint() {
    if (_points.isEmpty) return;
    setState(() {
      _points.removeLast();
      if (_points.length < 3) {
        _calculatedAreaSqm = 0;
      } else {
        _calculateArea();
      }
    });
  }

  void _clearMap() {
    setState(() {
      _points.clear();
      _calculatedAreaSqm = 0;
    });
  }

  void _saveField() {
    if (_calculatedAreaSqm == 0.0 || _points.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('En az 3 nokta işaretleyip alan oluşturun.'),
        backgroundColor: AppColors.error,
      ));
      return;
    }

    double centerLat = 0, centerLng = 0;
    for (final p in _points) {
      centerLat += p.latitude;
      centerLng += p.longitude;
    }
    centerLat /= _points.length;
    centerLng /= _points.length;
    final dekar = _calculatedAreaSqm / 1000;

    String name = widget.existingField?['name']?.split(' ').first ?? '';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('Ekim Alanını Kaydet', style: AppText.h2(context)),
        content: TextField(
          onChanged: (v) => name = v,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Örn: Kuzey Tarlası',
            helperText: '${dekar.toStringAsFixed(1)} Dekar $_selectedCrop alanı eklenecek',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('İptal', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (name.trim().isNotEmpty) {
                final data = {
                  'id': widget.existingField?['id'],
                  'name': '${name.trim()} (${dekar.toStringAsFixed(1)} da)',
                  'crop': _selectedCrop,
                  'date': DateFormat('dd.MM.yyyy').format(DateTime.now()),
                  'latitude': centerLat,
                  'longitude': centerLng,
                  'area_dekar': dekar,
                  'area_sqm': _calculatedAreaSqm,
                  'polygon': _points.map((p) => {'lat': p.latitude, 'lng': p.longitude}).toList(),
                  'planted_crops': widget.existingField?['planted_crops'] ?? const [],
                };

                await ref.read(localDataRepositoryProvider).upsertFieldFromLegacyMap(data);
                
                if (!mounted) return;
                Navigator.pop(ctx);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                  content: const Text('Ekim alanı başarıyla kaydedildi!'),
                  backgroundColor: AppColors.success,
                ));
              }
            },
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
  }

  // Tarla içi bitki yerleşimi paterni
  List<Polygon> _buildCropPattern() {
    if (_points.length < 3) return [];
    
    // Pseudo-3D effect: using an image overlay or a pattern fill
    // Since flutter_map doesn't support 3D natively, we use multiple semitransparent layers
    // to give a volumetric feel to the crop.
    
    Color cropColor;
    switch (_selectedCrop) {
      case 'Buğday': cropColor = const Color(0xFFF59E0B); break; // Amber
      case 'Mısır': cropColor = const Color(0xFF10B981); break; // Emerald
      case 'Ayçiçeği': cropColor = const Color(0xFFFCD34D); break; // Yellow
      case 'Pamuk': cropColor = const Color(0xFFE5E7EB); break; // Gray/White
      default: cropColor = AppColors.emerald;
    }

    return [
      // Base shadow layer
      Polygon(
        points: _points,
        color: Colors.black.withValues(alpha: 0.3),
        borderStrokeWidth: 0,
      ),
      // Base solid crop color
      Polygon(
        points: _points,
        color: cropColor.withValues(alpha: 0.6),
        borderColor: cropColor,
        borderStrokeWidth: 2.0,
      ),
      // Overlay pattern: In a real app we'd use a PatternBuilder or ImageProvider overlay.
      // We simulate volume with an inner border layer.
      Polygon(
        points: _calculateInnerPolygon(),
        color: Colors.white.withValues(alpha: 0.1),
        borderColor: Colors.white.withValues(alpha: 0.3),
        borderStrokeWidth: 1.0,
      ),
    ];
  }
  
  // Shrinks polygon to create a pseudo 3d 'top' surface
  List<LatLng> _calculateInnerPolygon() {
    if (_points.length < 3) return [];
    // Calculate centroid
    double clat = 0, clng = 0;
    for (var p in _points) { clat += p.latitude; clng += p.longitude; }
    clat /= _points.length;
    clng /= _points.length;
    
    // Scale towards center by 5%
    return _points.map((p) => LatLng(
      p.latitude + (clat - p.latitude) * 0.05,
      p.longitude + (clng - p.longitude) * 0.05,
    )).toList();
  }

  @override
  Widget build(BuildContext context) {
    double dekar = _calculatedAreaSqm / 1000;
    double density = _cropDensity[_selectedCrop] ?? 0.0;
    double requiredAmount = dekar * density;
    String unit = _selectedCrop == 'Domates' ? 'Kök' : 'Kg Tohum';

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text('3D Tarla Yerleşimi', style: AppText.h3Dark(context)),
        actions: [
          IconButton(icon: const Icon(Icons.undo), onPressed: _undoLastPoint),
          IconButton(icon: const Icon(Icons.cleaning_services), onPressed: _clearMap),
        ],
      ),
      body: Stack(
        children: [
          // MAP
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: LatLng(widget.initialLat, widget.initialLng),
              initialZoom: 18.0,
              onTap: _onMapTap,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
                userAgentPackageName: 'com.example.feng_498',
                maxZoom: 21,
              ),
              if (_points.length >= 3)
                PolygonLayer(polygons: _buildCropPattern()),
              if (_points.isNotEmpty)
                PolylineLayer<Object>(polylines: [
                  Polyline(
                    points: _points.length >= 3 ? [..._points, _points.first] : [..._points],
                    color: Colors.white,
                    strokeWidth: 2.0,
                  ),
                ]),
              MarkerLayer(markers: _points.map((p) => Marker(
                point: p,
                width: 12,
                height: 12,
                child: Container(decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: AppShadows.md)),
              )).toList()),
            ],
          ),
          
          // TOP GLASS PANEL (Crop selector)
          Positioned(
            top: 100,
            left: 16,
            right: 16,
            child: GlassPanel(
              borderRadius: 16,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Icon(Icons.grass, color: AppColors.emerald, size: 24),
                  const SizedBox(width: 12),
                  Text('Ekim Planı:', style: AppText.body(context).copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedCrop,
                        isExpanded: true,
                        dropdownColor: AppColors.surface.withValues(alpha: 0.9),
                        borderRadius: AppRadius.md,
                        style: AppText.body(context),
                        items: _cropDensity.keys.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                        onChanged: (v) => setState(() => _selectedCrop = v!),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // BOTTOM GLASS PANELS (Stats & Save)
          Positioned(
            bottom: 30,
            left: 16,
            right: 16,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_calculatedAreaSqm > 0)
                  GlassPanel(
                    borderRadius: 20,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatBox('Alan', dekar.toStringAsFixed(2), 'Dekar'),
                        Container(width: 1, height: 40, color: AppColors.border),
                        _buildStatBox('Miktar', requiredAmount.toStringAsFixed(0), unit),
                        Container(width: 1, height: 40, color: AppColors.border),
                        _buildStatBox('Verim', (dekar * 400).toStringAsFixed(0), 'Tahmini Kg'),
                      ],
                    ),
                  ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: _points.length >= 3 ? _saveField : null,
                    icon: const Icon(Icons.check_circle_outline),
                    label: Text(
                      _points.length >= 3 ? 'EKİM PLANINI KAYDET' : 'KÖŞELERİ İŞARETLEYİN',
                      style: const TextStyle(letterSpacing: 1.2),
                    ),
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: AppRadius.lg),
                      backgroundColor: AppColors.emerald,
                      disabledBackgroundColor: AppColors.textTertiary,
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

  Widget _buildStatBox(String label, String value, String unit) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.bold)),
        Text(unit, style: const TextStyle(color: AppColors.emerald, fontSize: 11, fontWeight: FontWeight.w600)),
      ],
    );
  }
}
