import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:maps_toolkit/maps_toolkit.dart' as toolkit;
import 'package:intl/intl.dart';
import '../data/turkish_crops_repository.dart';
import '../services/app_providers.dart';
import '../theme/app_theme.dart';
import '../widgets/floating_toast.dart';
import '../widgets/glass_panel.dart';
import 'turkish_crops_search_screen.dart';

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
  TurkishCrop? _selectedCrop;
  String? _selectedCropName;
  double _calculatedAreaSqm = 0.0;

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
        _selectedCropName = widget.existingField!['crop'] as String;
        _hydrateCropFromName(_selectedCropName!);
      }
    }
  }

  Future<void> _hydrateCropFromName(String name) async {
    final repo = TurkishCropsRepository.instance;
    await repo.ensureReady();
    final crop = repo.findByName(name);
    if (crop != null && mounted) {
      setState(() => _selectedCrop = crop);
    }
  }

  Future<void> _openCropPicker() async {
    final picked = await Navigator.of(context).push<TurkishCrop>(
      MaterialPageRoute(
        builder: (_) => const TurkishCropsSearchScreen(pickerMode: true),
      ),
    );
    if (picked != null && mounted) {
      setState(() {
        _selectedCrop = picked;
        _selectedCropName = picked.nameTr;
      });
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
      AppToast.show(
        context,
        message: 'En az 3 nokta işaretleyip alan oluşturun.',
        type: ToastType.warning,
      );
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
            helperText: '${dekar.toStringAsFixed(1)} Dekar ${_selectedCropName ?? "(bitki seçilmedi)"} alanı eklenecek',
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
                  'crop': _selectedCropName ?? '',
                  'date': DateFormat('dd.MM.yyyy').format(DateTime.now()),
                  'latitude': centerLat,
                  'longitude': centerLng,
                  'area_dekar': dekar,
                  'area_sqm': _calculatedAreaSqm,
                  'polygon': _points.map((p) => {'lat': p.latitude, 'lng': p.longitude}).toList(),
                  'planted_crops': widget.existingField?['planted_crops'] ?? const [],
                };

                await ref.read(localDataRepositoryProvider).upsertFieldFromLegacyMap(data);

                if (!ctx.mounted) return;
                Navigator.pop(ctx);
                if (!mounted) return;
                Navigator.pop(context);
                if (!mounted) return;
                AppToast.show(
                  context,
                  message: 'Ekim alanı başarıyla kaydedildi!',
                  type: ToastType.success,
                );
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
    
    final cropColor = _colorForCategory(_selectedCrop?.category);

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
  
  Color _colorForCategory(String? category) {
    switch (category) {
      case 'Tahıl': return const Color(0xFFF59E0B); // Amber
      case 'Baklagil': return const Color(0xFF84CC16); // Lime
      case 'Yağlı Tohum': return const Color(0xFFFCD34D); // Yellow
      case 'Endüstri Bitkisi': return const Color(0xFFE5E7EB); // Gray
      case 'Yem Bitkisi': return const Color(0xFF65A30D); // Dark lime
      case 'Sebze': return const Color(0xFFEF4444); // Red
      case 'Meyve': return const Color(0xFFEC4899); // Pink
      case 'Sert Kabuklu': return const Color(0xFF92400E); // Brown
      case 'Bahçe Otu': return const Color(0xFF16A34A); // Green
      case 'Tıbbi Bitki': return const Color(0xFF8B5CF6); // Purple
      case 'Süs Bitkisi': return const Color(0xFFF472B6); // Light pink
      default: return AppColors.emerald;
    }
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
    final harvestDays = _selectedCrop?.daysToHarvest;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
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
          
          // TOP GLASS PANEL (Crop picker)
          Positioned(
            top: 100,
            left: 16,
            right: 16,
            child: GlassPanel(
              borderRadius: 16,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: InkWell(
                onTap: _openCropPicker,
                borderRadius: BorderRadius.circular(12),
                child: Row(
                  children: [
                    Icon(Icons.grass, color: AppColors.emerald, size: 24),
                    const SizedBox(width: 12),
                    Text('Ekim Planı:', style: AppText.body(context).copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _selectedCropName ?? 'Bitki seç (292 çeşit)',
                        style: AppText.body(context).copyWith(
                          color: _selectedCropName == null ? AppColors.textSecondary : AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Icon(Icons.search_rounded, color: AppColors.emerald, size: 22),
                  ],
                ),
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
                        _buildStatBox(
                          'Hasat',
                          harvestDays == null ? '—' : harvestDays.toString(),
                          harvestDays == null ? 'Bitki seç' : 'Gün',
                        ),
                        Container(width: 1, height: 40, color: AppColors.border),
                        _buildStatBox('Kategori', _selectedCrop?.category ?? '—', _selectedCrop?.waterNeed ?? ''),
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
