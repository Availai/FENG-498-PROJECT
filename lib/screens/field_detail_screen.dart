import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import '../services/agri_service.dart';
import '../services/app_providers.dart';
import '../data/verified_agri_database.dart';
import '../widgets/glass_panel.dart';
import 'seed_selector_screen.dart';
import 'harvest_oracle_screen.dart';

class FieldDetailScreen extends ConsumerStatefulWidget {
  final dynamic fieldData;
  const FieldDetailScreen({super.key, required this.fieldData});
  @override
  ConsumerState<FieldDetailScreen> createState() => _FieldDetailScreenState();
}

class _FieldDetailScreenState extends ConsumerState<FieldDetailScreen>
    with SingleTickerProviderStateMixin {
  Map<String, dynamic>? _analysis;
  Map<String, dynamic>? _latestSuitabilityReport;
  List<Map<String, dynamic>> _fieldCrops = [];
  bool _isLoading = true;
  bool _isRefreshingSuitability = false;
  String? _error;

  late AnimationController _animCtrl;
  late Animation<double> _uiFadeAnim;
  late Animation<Offset> _uiSlideAnim;

  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2500));

    _uiFadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(
        parent: _animCtrl,
        curve: const Interval(0.2, 1.0, curve: Curves.easeOut)));
    _uiSlideAnim = Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero)
        .animate(CurvedAnimation(
            parent: _animCtrl,
            curve: const Interval(0.2, 1.0, curve: Curves.easeOutBack)));

    _animCtrl.forward();

    _loadLatestSuitabilityReport();
    _loadAnalysis();
    _loadFieldCrops();
  }

  Future<void> _loadFieldCrops() async {
    final fieldId = widget.fieldData['id']?.toString();
    if (fieldId == null || fieldId.isEmpty) return;
    final crops =
        await ref.read(localDataRepositoryProvider).loadFieldCrops(fieldId);
    if (!mounted) return;
    setState(() => _fieldCrops = crops);
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadAnalysis() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final d = widget.fieldData;
      final result = await AgriService.getFieldAnalysis(
        (d['latitude'] as num).toDouble(),
        (d['longitude'] as num).toDouble(),
        d['name'] ?? 'Tarla',
        (d['area_dekar'] as num?)?.toDouble() ?? 1.0,
      );
      if (result['success'] == true) {
        await _persistSuitabilityReport(result);
      }
      if (mounted) {
        setState(() {
          if (result['success'] == true) {
            _analysis = result;
          } else {
            _error = result['error'] ?? 'Bilinmeyen hata';
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Bağlantı Hatası: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadLatestSuitabilityReport() async {
    final fieldId = widget.fieldData['id']?.toString();
    if (fieldId == null || fieldId.isEmpty) return;

    final report = await ref
        .read(localDataRepositoryProvider)
        .loadLatestSuitabilityReport(fieldId);
    if (!mounted) return;

    setState(() => _latestSuitabilityReport = report);
  }

  Future<void> _persistSuitabilityReport(
    Map<String, dynamic> analysis,
  ) async {
    final fieldId = widget.fieldData['id']?.toString();
    if (fieldId == null || fieldId.isEmpty) return;

    final recommendedCrops = (analysis['crops'] as List? ?? const [])
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();

    final topCrop =
        recommendedCrops.isNotEmpty ? recommendedCrops.first : <String, dynamic>{};
    final rawCropName = topCrop['name']?.toString().trim();
    final cropName = (rawCropName == null || rawCropName.isEmpty)
        ? (widget.fieldData['crop']?.toString() ?? 'Belirtilmedi')
        : rawCropName
            .replaceAll(
              RegExp(r'[\u{1F300}-\u{1FAFF}]', unicode: true),
              '',
            )
            .trim();

    final score = (topCrop['uygunluk'] as num?)?.toDouble() ?? 0.0;
    final now = DateTime.now().toUtc();

    final reportPayload = <String, dynamic>{
      'field_name': widget.fieldData['name']?.toString() ?? 'Tarla',
      'recommended_crop': cropName,
      'refreshed_at': now.toIso8601String(),
      'weekly_comment': analysis['ai_weekly_comment']?.toString() ?? '',
      'weather_snapshot': {
        'temp': (analysis['temp'] as num?)?.toDouble() ?? 0.0,
        'humidity': (analysis['humidity'] as num?)?.toDouble() ?? 0.0,
        'wind': (analysis['wind'] as num?)?.toDouble() ?? 0.0,
        'avg_weekly_temp': (analysis['avg_weekly_temp'] as num?)?.toDouble() ?? 0.0,
        'total_weekly_rain':
            (analysis['total_weekly_rain'] as num?)?.toDouble() ?? 0.0,
      },
      'soil_snapshot': {
        'ph': (analysis['ph'] as num?)?.toDouble() ?? 6.5,
        'soil_moisture': (analysis['soil_moisture'] as num?)?.toDouble() ?? 0.0,
        'soil_temp_c': (analysis['soil_temp_c'] as num?)?.toDouble() ?? 0.0,
      },
      'top_recommendations': recommendedCrops.take(3).toList(),
    };

    await ref.read(localDataRepositoryProvider).saveSuitabilityReport(
          fieldId: fieldId,
          cropName: cropName,
          score: score,
          report: reportPayload,
        );

    await _loadLatestSuitabilityReport();
  }

  Future<void> _refreshSuitability() async {
    if (_analysis == null) return;

    setState(() => _isRefreshingSuitability = true);
    try {
      await _persistSuitabilityReport(_analysis!);
    } finally {
      if (mounted) {
        setState(() => _isRefreshingSuitability = false);
      }
    }
  }


  Future<void> _showSyncQueueDialog() async {
    final syncRepository = ref.read(syncRepositoryProvider);
    final stats = await syncRepository.getQueueStats();
    if (!mounted) return;

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Senkron Kuyruğu'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Bekleyen: ${stats['pending'] ?? 0}'),
            Text('İşleniyor: ${stats['in_progress'] ?? 0}'),
            Text('Hatalı: ${stats['failed'] ?? 0}'),
            const SizedBox(height: 8),
            Text('Toplam: ${stats['total'] ?? 0}'),
            const SizedBox(height: 8),
            const Text(
              'Not: Bu adım yalnızca yerel outbox kuyruğunu yönetir.',
              style: TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Kapat'),
          ),
          FilledButton(
            onPressed: () async {
              final moved = await syncRepository.retryFailedJobs();
              final report = await ref.read(syncServiceProvider).runPushCycleWithApi(
                    apiClient: ref.read(syncApiClientProvider),
                  );
              if (!mounted) return;
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    '$moved kayıt tekrar kuyruğa alındı • '
                    'Push: ${report.completed}/${report.picked} başarılı',
                  ),
                ),
              );
            },
            child: const Text('Hatalıları Tekrar Dene'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.fieldData;
    final a = _analysis;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: const Color(0xFF0D1811), // Deep premium dark green
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF00E676)),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: AnimatedOpacity(
          opacity: _uiFadeAnim.value,
          duration: const Duration(milliseconds: 300),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.architecture_rounded, color: Color(0xFF00E676)),
              const SizedBox(width: 8),
              Text(d['name']?.toUpperCase() ?? 'AGRI-FARM AR',
                  style: GoogleFonts.outfit(
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2.0,
                      color: Colors.white,
                      fontSize: 18)),
              const SizedBox(width: 12),
              const Text('3D TECH VIEW',
                  style: TextStyle(
                      color: Colors.white54, fontSize: 12, letterSpacing: 1.0)),
            ],
          ),
        ),
        actions: [
          IconButton(
              icon: const Icon(Icons.sync, color: Color(0xFF00E676)),
              onPressed: _showSyncQueueDialog),
        ],
      ),
      body: Stack(
        children: [
          // 1. Gerçek tarla haritası — yalnızca seçilen polygon'a kilitli
          Positioned.fill(child: _build3DFieldMap(d)),

          // 2. Zoom kontrolleri
          Positioned(
            left: 16,
            bottom: 120,
            child: FadeTransition(
              opacity: _uiFadeAnim,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _zoomBtn(Icons.add, () {
                    final z = _mapController.camera.zoom;
                    _mapController.move(
                        _mapController.camera.center, (z + 1).clamp(14.0, 21.0));
                  }),
                  const SizedBox(height: 8),
                  _zoomBtn(Icons.remove, () {
                    final z = _mapController.camera.zoom;
                    _mapController.move(
                        _mapController.camera.center, (z - 1).clamp(14.0, 21.0));
                  }),
                  const SizedBox(height: 8),
                  _zoomBtn(Icons.center_focus_strong, () => _fitToField(d)),
                ],
              ),
            ),
          ),

          // 4. Center Top/Sides stats
          if (!_isLoading && _error == null)
            Positioned(
              right: 16,
              top: MediaQuery.of(context).padding.top + 60,
              child: FadeTransition(
                opacity: _uiFadeAnim,
                child: SlideTransition(
                  position: _uiSlideAnim,
                  child: _buildHUDRightSidebar(a),
                ),
              ),
            ),
          if (!_isLoading && _error == null)
            Positioned(
              left: 16,
              top: MediaQuery.of(context).padding.top + 60,
              child: FadeTransition(
                opacity: _uiFadeAnim,
                child: SlideTransition(
                  position: _uiSlideAnim,
                  child: _buildSuitabilityCard(),
                ),
              ),
            ),

          // 5. Bottom System Nav
          if (!_isLoading && _error == null)
            Positioned(
              left: 16,
              right: 16,
              bottom: MediaQuery.of(context).padding.bottom + 20,
              child: FadeTransition(
                opacity: _uiFadeAnim,
                child: SlideTransition(
                  position: _uiSlideAnim,
                  child: _buildHUDBottomBar(),
                ),
              ),
            ),

          if (_isLoading)
            const Center(child: CircularProgressIndicator(color: Color(0xFF00E676))),
          if (_error != null)
            Center(
                child: GlassPanel(
                    child: Text(_error!, style: const TextStyle(color: Colors.white)))),
        ],
      ),
    );
  }

  Widget _buildHUDRightSidebar(Map<String, dynamic>? a) {
    String temp = '--°C';
    String humid = '--';

    if (a != null) {
      temp = '${(a['temp'] as num?)?.round() ?? '--'}°C';
      humid = '%${(a['humidity'] as num?)?.round() ?? '--'}';
    }

    final fieldName = widget.fieldData['name'] ?? 'Tarla';

    return GlassPanel(
      baseColor: const Color(0xFF1B5E20),
      borderRadius: 16,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.lens_blur_rounded, color: Color(0xFF00E676), size: 14),
            const SizedBox(width: 6),
            Text(fieldName,
                style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
          ]),
          const SizedBox(height: 12),
          _buildStatItem(Icons.thermostat_outlined, 'Env. Temp', temp, const Color(0xFFFFCC80)),
          _buildStatItem(Icons.opacity_outlined, 'Humidity', humid, const Color(0xFFA5D6A7)),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String label, String value, Color iconColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10, fontFamily: 'monospace')),
              Text(value, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSuitabilityCard() {
    final report = _latestSuitabilityReport;
    final reportBody = report?['report'];
    final refreshedAtRaw =
        (reportBody is Map ? reportBody['refreshed_at'] : null)?.toString();
    final refreshedAt = DateTime.tryParse(refreshedAtRaw ?? '')?.toLocal();
    final topCrop = report?['crop_name']?.toString() ?? 'Henüz yok';
    final score = (report?['score'] as num?)?.toDouble() ?? 0.0;

    return GlassPanel(
      baseColor: const Color(0xFF1B5E20),
      borderRadius: 16,
      padding: const EdgeInsets.all(12),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 220),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.verified_rounded, color: Color(0xFF00E676), size: 16),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Uygunluk Raporu',
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Raporu yenile',
                  onPressed: _isRefreshingSuitability ? null : _refreshSuitability,
                  icon: _isRefreshingSuitability
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFF00E676),
                          ),
                        )
                      : const Icon(Icons.refresh, color: Color(0xFF00E676), size: 16),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Önerilen Ürün: $topCrop',
              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              'Skor: %${score.toStringAsFixed(0)}',
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
            const SizedBox(height: 4),
            Text(
              refreshedAt == null
                  ? 'Durum: Henüz rapor oluşturulmadı'
                  : 'Son Güncelleme: ${DateFormat('dd.MM.yyyy HH:mm', 'tr_TR').format(refreshedAt)}',
              style: const TextStyle(color: Colors.white70, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHUDBottomBar() {
    return GlassPanel(
      baseColor: Colors.white,
      borderRadius: 20,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildNavBtn(Icons.add_circle_rounded, 'Bitki Ekle', _showPlantPicker, primary: true),
          _buildNavBtn(Icons.eco_rounded, 'Nöbetleşe', _showCropRecommendations),
          _buildNavBtn(Icons.grain_rounded, 'Tohum DB', () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const SeedSelectorScreen()))),
          _buildNavBtn(Icons.wb_cloudy_rounded, 'Hasat', () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const HarvestOracleScreen()))),
        ],
      ),
    );
  }

  Widget _buildNavBtn(IconData icon, String text, VoidCallback onTap, {bool primary = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: primary ? BoxDecoration(
          color: const Color(0xFF1B5E20),
          borderRadius: BorderRadius.circular(16),
        ) : null,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: primary ? Colors.white : const Color(0xFF2E7D32), size: 22),
            const SizedBox(height: 4),
            Text(text, style: GoogleFonts.inter(
              color: primary ? Colors.white : const Color(0xFF2E7D32),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            )),
          ],
        ),
      ),
    );
  }

  void _showCropRecommendations() {
    double currentT = 20.0;
    double currentPh = 6.5;
    double totalRain = 400.0;

    if (_analysis != null) {
      currentT = (_analysis!['avg_weekly_temp'] as num?)?.toDouble() ??
          (_analysis!['temp'] as num?)?.toDouble() ??
          20.0;
      currentPh = (_analysis!['ph'] as num?)?.toDouble() ?? 6.5;
      totalRain =
          ((_analysis!['total_weekly_rain'] as num?)?.toDouble() ?? 12.0) * 52;
    }

    // Use Verified Database perfectly 
    List<Map<String, dynamic>> scoredPlants = [];
    for (var plant in VerifiedAgriDatabase.plants) {
       int score = plant.evaluateSuitability(currentPh, currentT, totalRain);
       scoredPlants.add({
         'plant': plant,
         'score': score
       });
    }

    scoredPlants.sort((a,b) => (b['score'] as int).compareTo(a['score'] as int));

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _VerifiedRecommendationSheet(recommendations: scoredPlants),
    );
  }

  // ---------------------------------------------------------------
  // BİTKİ EKLE — uygunluk skorlu seçim + Drift kaydı
  // ---------------------------------------------------------------

  ({double ph, double temp, double annualRain}) _envForSuitability() {
    double t = 20.0, ph = 6.5, rain = 400.0;
    if (_analysis != null) {
      t = (_analysis!['avg_weekly_temp'] as num?)?.toDouble() ??
          (_analysis!['temp'] as num?)?.toDouble() ??
          20.0;
      ph = (_analysis!['ph'] as num?)?.toDouble() ?? 6.5;
      rain = ((_analysis!['total_weekly_rain'] as num?)?.toDouble() ?? 12.0) * 52;
    }
    return (ph: ph, temp: t, annualRain: rain);
  }

  void _showPlantPicker() {
    final env = _envForSuitability();
    final scored = VerifiedAgriDatabase.plants.map((p) {
      final score = p.evaluateSuitability(env.ph, env.temp, env.annualRain);
      final reasons = <String>[];
      if (env.temp < p.minTemp || env.temp > p.maxTemp) {
        reasons.add(
            'Sıcaklık ${env.temp.toStringAsFixed(0)}°C — ideal ${p.minTemp.toInt()}–${p.maxTemp.toInt()}°C dışında');
      }
      if (env.ph < p.minPh || env.ph > p.maxPh) {
        reasons.add(
            'Toprak pH ${env.ph.toStringAsFixed(1)} — ideal ${p.minPh}–${p.maxPh} dışında');
      }
      if (env.annualRain < p.waterReqMmPerSeason * 0.4) {
        reasons.add(
            'Yıllık yağış ${env.annualRain.toStringAsFixed(0)}mm — ${p.nameTr} için ${p.waterReqMmPerSeason.toStringAsFixed(0)}mm gerek');
      }
      return {'plant': p, 'score': score, 'reasons': reasons};
    }).toList()
      ..sort((a, b) => (b['score'] as int).compareTo(a['score'] as int));

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _PlantPickerSheet(
        scored: scored,
        onPick: (plant) async {
          Navigator.pop(context);
          await _plantCrop(plant);
        },
      ),
    );
  }

  Future<void> _plantCrop(AgriPlant plant) async {
    final fieldId = widget.fieldData['id']?.toString();
    if (fieldId == null || fieldId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tarla kimliği bulunamadı.')),
      );
      return;
    }

    final repo = ref.read(localDataRepositoryProvider);
    final existing = await repo.loadFieldCrops(fieldId);
    final newCrop = <String, dynamic>{
      'name': plant.nameTr,
      'zone_start': 0.0,
      'zone_end': 1.0,
      'row_spacing_cm': 50.0,
      'plant_spacing_cm': 40.0,
      'color_value': plant.renderColor.toARGB32(),
      'planted_date':
          '${DateTime.now().day.toString().padLeft(2, '0')}.${DateTime.now().month.toString().padLeft(2, '0')}.${DateTime.now().year}',
      'harvest_days': plant.daysToHarvest,
      'water_interval_days': 7,
    };

    await repo.replaceFieldCrops(
      fieldId: fieldId,
      crops: [...existing, newCrop],
    );

    await _loadFieldCrops();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${plant.nameTr} tarlaya eklendi.')),
    );
  }

  // ---------------------------------------------------------------
  // 3D harita render — gerçek polygon + ekili bitki markerları
  // ---------------------------------------------------------------

  List<LatLng> _polygonPoints(Map<String, dynamic> d) {
    final raw = d['polygon'];
    if (raw is List) {
      return raw
          .whereType<Map>()
          .map((e) => LatLng(
                (e['lat'] as num).toDouble(),
                (e['lng'] as num).toDouble(),
              ))
          .toList();
    }
    return const [];
  }

  LatLng _fieldCenter(Map<String, dynamic> d, List<LatLng> polygon) {
    if (polygon.isNotEmpty) {
      double lat = 0, lng = 0;
      for (final p in polygon) {
        lat += p.latitude;
        lng += p.longitude;
      }
      return LatLng(lat / polygon.length, lng / polygon.length);
    }
    final lat = (d['latitude'] as num?)?.toDouble() ?? 39.0;
    final lng = (d['longitude'] as num?)?.toDouble() ?? 35.0;
    return LatLng(lat, lng);
  }

  /// Polygon iç bölgesi için axis-aligned bbox üzerinde grid noktaları üret,
  /// yalnız polygon içine düşenleri tut. Ray-casting point-in-polygon.
  List<LatLng> _gridInsidePolygon(List<LatLng> polygon, int targetCount) {
    if (polygon.length < 3 || targetCount <= 0) return const [];
    double minLat = polygon.first.latitude, maxLat = polygon.first.latitude;
    double minLng = polygon.first.longitude, maxLng = polygon.first.longitude;
    for (final p in polygon) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }
    final steps = math.max(3, math.sqrt(targetCount).ceil() + 1);
    final result = <LatLng>[];
    for (int i = 1; i < steps; i++) {
      for (int j = 1; j < steps; j++) {
        final lat = minLat + (maxLat - minLat) * (i / steps);
        final lng = minLng + (maxLng - minLng) * (j / steps);
        if (_pointInPolygon(lat, lng, polygon)) {
          result.add(LatLng(lat, lng));
          if (result.length >= targetCount) return result;
        }
      }
    }
    return result;
  }

  bool _pointInPolygon(double lat, double lng, List<LatLng> polygon) {
    bool inside = false;
    for (int i = 0, j = polygon.length - 1; i < polygon.length; j = i++) {
      final yi = polygon[i].latitude, xi = polygon[i].longitude;
      final yj = polygon[j].latitude, xj = polygon[j].longitude;
      final intersect = ((yi > lat) != (yj > lat)) &&
          (lng < (xj - xi) * (lat - yi) / ((yj - yi) == 0 ? 1e-12 : (yj - yi)) + xi);
      if (intersect) inside = !inside;
    }
    return inside;
  }

  List<Map<String, dynamic>> _plantedCrops(Map<String, dynamic> d) {
    if (_fieldCrops.isNotEmpty) return _fieldCrops;
    final raw = d['planted_crops'];
    if (raw is List) {
      return raw
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    final main = d['crop']?.toString();
    if (main != null && main.isNotEmpty && main != 'Belirtilmedi') {
      return [
        {
          'name': main,
          'color_value': const Color(0xFF66BB6A).toARGB32(),
        }
      ];
    }
    return const [];
  }

  String _cropEmoji(String name) {
    final n = name.toLowerCase();
    if (n.contains('buğday') || n.contains('arpa')) return '🌾';
    if (n.contains('mısır')) return '🌽';
    if (n.contains('domates')) return '🍅';
    if (n.contains('biber')) return '🌶️';
    if (n.contains('üzüm')) return '🍇';
    if (n.contains('zeytin')) return '🫒';
    if (n.contains('elma')) return '🍎';
    if (n.contains('ayçiçek')) return '🌻';
    if (n.contains('pamuk')) return '☁️';
    if (n.contains('marul') || n.contains('lahana')) return '🥬';
    if (n.contains('havuç')) return '🥕';
    if (n.contains('soğan')) return '🧅';
    if (n.contains('patates')) return '🥔';
    return '🌱';
  }

  Color _cropColor(Map<String, dynamic> crop) {
    final v = crop['color_value'];
    if (v is int) return Color(v);
    return const Color(0xFF66BB6A);
  }

  Widget _build3DFieldMap(Map<String, dynamic> d) {
    final polygon = _polygonPoints(d);
    final center = _fieldCenter(d, polygon);
    final crops = _plantedCrops(d);

    // Polygon iç markerları (toplam ~36 nokta) — ekili ekinler arasında dağıt.
    final positions = _gridInsidePolygon(polygon, 36);
    final markers = <Marker>[];
    if (crops.isNotEmpty && positions.isNotEmpty) {
      for (int i = 0; i < positions.length; i++) {
        final crop = crops[i % crops.length];
        markers.add(
          Marker(
            point: positions[i],
            width: 28,
            height: 28,
            child: Text(
              _cropEmoji(crop['name']?.toString() ?? ''),
              style: const TextStyle(fontSize: 20),
              textAlign: TextAlign.center,
            ),
          ),
        );
      }
    }

    final polygonColor = crops.isNotEmpty
        ? _cropColor(crops.first).withValues(alpha: 0.30)
        : const Color(0xFF00E676).withValues(alpha: 0.25);
    const borderColor = Color(0xFF00E676);

    // Polygon bounds — kameranın sınırları ve initial fit için.
    LatLngBounds? bounds;
    if (polygon.length >= 3) {
      bounds = LatLngBounds.fromPoints(polygon);
    }

    // Köşe etiketleri (A, B, C, D ...) — referans görseldeki gibi.
    final cornerMarkers = <Marker>[];
    for (int i = 0; i < polygon.length && i < 26; i++) {
      cornerMarkers.add(
        Marker(
          point: polygon[i],
          width: 26,
          height: 26,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.65),
              border: Border.all(color: borderColor, width: 1.5),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              String.fromCharCode(65 + i),
              style: const TextStyle(
                color: borderColor,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ),
      );
    }

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: center,
        initialZoom: 18.0,
        minZoom: 16,
        maxZoom: 21,
        initialCameraFit: bounds != null
            ? CameraFit.bounds(
                bounds: bounds,
                padding: const EdgeInsets.all(80),
              )
            : null,
        cameraConstraint: bounds != null
            ? CameraConstraint.containCenter(bounds: bounds)
            : const CameraConstraint.unconstrained(),
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.pinchZoom |
              InteractiveFlag.drag |
              InteractiveFlag.doubleTapZoom,
        ),
      ),
      children: [
        TileLayer(
          urlTemplate:
              'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
          userAgentPackageName: 'com.example.feng_498',
          maxZoom: 21,
        ),
        if (polygon.length >= 3)
          PolygonLayer(
            polygons: [
              // Dış halo (kalın yumuşak çizgi)
              Polygon(
                points: polygon,
                color: Colors.transparent,
                borderColor: borderColor.withValues(alpha: 0.35),
                borderStrokeWidth: 8.0,
              ),
              // Ana sınır + dolgu
              Polygon(
                points: polygon,
                color: polygonColor,
                borderColor: borderColor,
                borderStrokeWidth: 3.0,
              ),
            ],
          ),
        if (markers.isNotEmpty) MarkerLayer(markers: markers),
        if (cornerMarkers.isNotEmpty) MarkerLayer(markers: cornerMarkers),
      ],
    );
  }

  void _fitToField(Map<String, dynamic> d) {
    final polygon = _polygonPoints(d);
    if (polygon.length < 3) return;
    final bounds = LatLngBounds.fromPoints(polygon);
    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: bounds,
        padding: const EdgeInsets.all(80),
      ),
    );
  }

  Widget _zoomBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.6),
          border: Border.all(color: const Color(0xFF00E676), width: 1.4),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: const Color(0xFF00E676), size: 22),
      ),
    );
  }
}

class _VerifiedRecommendationSheet extends StatelessWidget {
  final List<Map<String, dynamic>> recommendations;
  const _VerifiedRecommendationSheet({required this.recommendations});


  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      child: Column(
        children: [
          Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.verified_user_rounded, color: Color(0xFF2E7D32), size: 20),
            ),
            const SizedBox(width: 12),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Doğrulanmış Algoritma Önerileri', style: GoogleFonts.outfit(fontSize: 17, fontWeight: FontWeight.w700, color: const Color(0xFF1B5E20))),
              Text('%100 Çevresel Uyum Garantisi', style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade500)),
            ]),
          ]),
          const SizedBox(height: 16),
          const Divider(),
          Expanded(
            child: ListView.builder(
              itemCount: recommendations.length,
              itemBuilder: (context, i) {
                AgriPlant p = recommendations[i]['plant'];
                int score = recommendations[i]['score'];
                Color sColor = score >= 80 ? Colors.green : score >= 50 ? Colors.orange : Colors.red;
                return ListTile(
                  leading: CircleAvatar(backgroundColor: p.renderColor, child: const Icon(Icons.eco, color: Colors.white, size: 16)),
                  title: Text(p.nameTr, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('Süre: ${p.daysToHarvest} gün | Cinsi: ${p.category}'),
                  trailing: Text('%$score', style: TextStyle(color: sColor, fontWeight: FontWeight.bold, fontSize: 16)),
                );
              },
            ),
          )
        ],
      ),
    );
  }
}

class _PlantPickerSheet extends StatelessWidget {
  final List<Map<String, dynamic>> scored;
  final void Function(AgriPlant plant) onPick;
  const _PlantPickerSheet({required this.scored, required this.onPick});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.82,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      child: Column(
        children: [
          Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 12),
          Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.add_circle_rounded,
                  color: Color(0xFF2E7D32), size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Tarlaya Bitki Ekle',
                        style: GoogleFonts.outfit(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1B5E20))),
                    Text(
                        'Hava + toprak verisine göre uygunluk skoru',
                        style: GoogleFonts.inter(
                            fontSize: 12, color: Colors.grey.shade600)),
                  ]),
            ),
          ]),
          const SizedBox(height: 12),
          const Divider(height: 1),
          Expanded(
            child: ListView.builder(
              itemCount: scored.length,
              itemBuilder: (context, i) {
                final AgriPlant p = scored[i]['plant'] as AgriPlant;
                final int score = scored[i]['score'] as int;
                final List<String> reasons =
                    (scored[i]['reasons'] as List).cast<String>();
                final Color sColor = score >= 75
                    ? const Color(0xFF2E7D32)
                    : score >= 50
                        ? Colors.orange.shade700
                        : Colors.red.shade700;
                final String label = score >= 75
                    ? 'UYGUN'
                    : score >= 50
                        ? 'KOŞULLU'
                        : 'UYGUN DEĞİL';
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Material(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => onPick(p),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              backgroundColor: p.renderColor,
                              radius: 20,
                              child: const Icon(Icons.eco,
                                  color: Colors.white, size: 18),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(p.nameTr,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15)),
                                  const SizedBox(height: 2),
                                  Text(
                                      'Hasat: ${p.daysToHarvest} gün • pH ${p.minPh}-${p.maxPh} • ${p.minTemp.toInt()}-${p.maxTemp.toInt()}°C',
                                      style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey.shade700)),
                                  if (reasons.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    ...reasons.map((r) => Padding(
                                          padding: const EdgeInsets.only(top: 2),
                                          child: Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              const Icon(Icons.warning_amber_rounded,
                                                  size: 12, color: Colors.orange),
                                              const SizedBox(width: 4),
                                              Expanded(
                                                child: Text(r,
                                                    style: const TextStyle(
                                                        fontSize: 11,
                                                        color: Colors.black87)),
                                              ),
                                            ],
                                          ),
                                        )),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text('%$score',
                                    style: TextStyle(
                                        color: sColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18)),
                                Text(label,
                                    style: TextStyle(
                                        color: sColor,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 10)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
