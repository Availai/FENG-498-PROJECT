import 'dart:convert';
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
import '../data/turkish_crops_repository.dart';
import '../widgets/floating_toast.dart';
import '../widgets/glass_panel.dart';
import '../widgets/zone_drawing_toolbar.dart';
import '../widgets/crop_zone_tooltip.dart';
import '../widgets/crop_render_factory.dart';
import 'cost_ledger_screen.dart';
import 'plant_zone_drawing_screen.dart';
import '../widgets/animated_route.dart';

class FieldDetailScreen extends ConsumerStatefulWidget {
  final dynamic fieldData;
  const FieldDetailScreen({super.key, required this.fieldData});
  @override
  ConsumerState<FieldDetailScreen> createState() => _FieldDetailScreenState();
}

class _FieldDetailScreenState extends ConsumerState<FieldDetailScreen>
    with TickerProviderStateMixin {
  Map<String, dynamic>? _analysis;
  Map<String, dynamic>? _latestSuitabilityReport;
  List<Map<String, dynamic>> _fieldCrops = [];
  List<Map<String, dynamic>> _irrigationPlans = [];
  bool _isLoading = true;
  bool _isRefreshingSuitability = false;
  String? _error;

  // ═══ Bölge çizme modu state ═══
  bool _isZoneDrawingMode = false;
  List<LatLng> _zoneDrawingPoints = [];
  AgriPlant? _pendingPlant;
  Map<String, dynamic>? _selectedCropForTooltip;

  late AnimationController _animCtrl;
  late Animation<double> _uiFadeAnim;
  late Animation<Offset> _uiSlideAnim;

  // Hasat halosu animasyonu
  late AnimationController _harvestPulseCtrl;

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

    _harvestPulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _loadLatestSuitabilityReport();
    _loadAnalysis();
    _loadFieldCrops();
    _loadIrrigationPlans();
  }

  Future<void> _loadFieldCrops() async {
    final fieldId = widget.fieldData['id']?.toString();
    if (fieldId == null || fieldId.isEmpty) return;
    final crops =
        await ref.read(localDataRepositoryProvider).loadFieldCrops(fieldId);
    if (!mounted) return;
    setState(() => _fieldCrops = crops);
  }

  Future<void> _loadIrrigationPlans() async {
    final fieldId = widget.fieldData['id']?.toString();
    if (fieldId == null || fieldId.isEmpty) return;
    final plans = await ref
        .read(localDataRepositoryProvider)
        .loadFieldIrrigationPlans(fieldId);
    if (!mounted) return;
    setState(() => _irrigationPlans = plans);
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _harvestPulseCtrl.dispose();
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


  // ignore: unused_element
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
              if (!ctx.mounted) return;
              Navigator.pop(ctx);
              if (!mounted) return;
              AppToast.show(
                context,
                message:
                    '$moved kayıt tekrar kuyruğa alındı • Push: ${report.completed}/${report.picked} başarılı',
                type: ToastType.info,
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

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: const Color(0xFF0D1811), // Deep premium dark green
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 60,
        leadingWidth: 48,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF00E676), size: 24),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF00E676)),
              child: const Icon(Icons.eco_rounded, color: Colors.black, size: 16),
            ),
            const SizedBox(width: 8),
            Text('Agri-Farm ', 
              style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)
            ),
            Text('AR', 
              style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF00E676))
            ),
          ],
        ),
        centerTitle: false,
        actions: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('AKTİF', style: TextStyle(color: Colors.white70, fontSize: 10, letterSpacing: 1.2)),
              const SizedBox(width: 6),
              Container(width: 8, height: 8, decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF00E676), boxShadow: [BoxShadow(color: Color(0xFF00E676), blurRadius: 4)])),
              const SizedBox(width: 16),
            ],
          )
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
          // 4. Karmaşık yüzer pencereler The user requested to simplify the screen and hide these blocks:
          // Live Stats, Uygunluk Raporu, Field Details, Bölge Lejandı
          // Bunların detaylarına alt kısımdaki Bottom Navigasyon barından (Görevler, Veri Trendleri vb.) ulaşılabilir.

          // 4d. Alert badges (sol taraf, harita üstü)
          if (!_isLoading && _error == null && !_isZoneDrawingMode)
            Positioned(
              left: 12,
              top: MediaQuery.of(context).size.height * 0.15,
              child: FadeTransition(
                opacity: _uiFadeAnim,
                child: _buildAlertBadges(),
              ),
            ),

          // 5. Bottom System Nav — normal mod
          if (!_isLoading && _error == null && !_isZoneDrawingMode)
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

          // 5b. Bottom — bölge çizme modu toolbar
          if (_isZoneDrawingMode)
            Positioned(
              left: 16,
              right: 16,
              bottom: MediaQuery.of(context).padding.bottom + 20,
              child: ZoneDrawingToolbar(
                plantName: _pendingPlant?.nameTr ?? 'Bitki',
                plantColor: _pendingPlant?.renderColor ?? const Color(0xFF00E676),
                pointCount: _zoneDrawingPoints.length,
                onUndo: _undoLastZonePoint,
                onComplete: _completeZoneDrawing,
                onCancel: _cancelZoneDrawing,
              ),
            ),

          // 6. Crop Zone Tooltip overlay
          if (_selectedCropForTooltip != null)
            Positioned(
              left: 0,
              right: 0,
              top: MediaQuery.of(context).size.height * 0.25,
              child: Center(
                child: CropZoneTooltip(
                  cropName: _selectedCropForTooltip!['name']?.toString() ?? 'Bitki',
                  cropColor: _cropColor(_selectedCropForTooltip!),
                  plantedDate: _selectedCropForTooltip!['planted_date']?.toString(),
                  harvestDays: (_selectedCropForTooltip!['harvest_days'] as num?)?.toInt() ?? 90,
                  maturityPercent: _computeMaturityPercent(_selectedCropForTooltip!),
                  onDelete: () => _deleteCropZone(_selectedCropForTooltip!),
                  onClose: _closeTooltip,
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

  // ═══════════════════════════════════════════════════
  // LIVE STATS PANEL — 4 ana canli metrik (AR Tarzı)
  // ═══════════════════════════════════════════════════
  // ignore: unused_element
  Widget _buildLiveStatsPanel(Map<String, dynamic>? a) {
    final soilTemp = a != null ? '${(a['soil_temp_c'] as num?)?.toStringAsFixed(0) ?? '--'}°C' : '--°C';
    final rain = a != null ? '${(a['total_weekly_rain'] as num?)?.toStringAsFixed(1) ?? '--'} mm' : '-- mm';
    
    final tempVal = (a?['temp'] as num?)?.toDouble() ?? 20.0;
    final humidVal = (a?['humidity'] as num?)?.toDouble() ?? 50.0;
    String pestLevel = 'Düşük';
    Color pestColor = const Color(0xFF00E676);
    if (humidVal > 70 && tempVal > 25) { pestLevel = 'Yüksek'; pestColor = const Color(0xFFEF5350); }
    else if (humidVal > 60) { pestLevel = 'Orta'; pestColor = const Color(0xFFFFA726); }

    // Bitki sağlığı skoru
    String healthScore = '--';
    if (_fieldCrops.isNotEmpty && a != null) {
      final env = _envForSuitability();
      double total = 0;
      int count = 0;
      for (final crop in _fieldCrops) {
        final name = crop['name']?.toString().toLowerCase() ?? '';
        for (final p in VerifiedAgriDatabase.plants) {
          if (p.nameTr.toLowerCase() == name) {
            total += p.evaluateSuitability(env.ph, env.temp, env.annualRain);
            count++;
            break;
          }
        }
      }
      if (count > 0) healthScore = '%${(total / count).round()}';
    }

    return Container(
      width: 170,
      decoration: BoxDecoration(
        color: const Color(0xFF0D1811).withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF00E676).withValues(alpha: 0.7), width: 1.5),
        boxShadow: [BoxShadow(color: const Color(0xFF00E676).withValues(alpha: 0.15), blurRadius: 10)],
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Canlı Veriler', style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
              const Icon(Icons.more_horiz, color: Colors.white54, size: 16),
            ],
          ),
          const SizedBox(height: 12),
          _arStatCard(Icons.monitor_heart_rounded, 'Tarla Sağlığı', healthScore, const Color(0xFF00E676)),
          _arStatCard(Icons.thermostat_rounded, 'Toprak Sıcaklık', soilTemp, const Color(0xFFFFB74D)),
          _arStatCard(Icons.water_drop_rounded, 'Yağış', rain, const Color(0xFF4FC3F7)),
          _arStatCard(Icons.bug_report_rounded, 'Zararlı Seviye', pestLevel, pestColor),
        ],
      ),
    );
  }

  Widget _arStatCard(IconData icon, String label, String value, Color accentColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1B5E20).withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: accentColor.withValues(alpha: 0.5), width: 1),
      ),
      child: Row(
        children: [
          Icon(icon, color: accentColor, size: 24),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w500)),
                Text(value, style: TextStyle(color: accentColor, fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════
  // FIELD DETAILS CARD — ekili bitki bilgileri
  // ═══════════════════════════════════════════════════
  // ignore: unused_element
  Widget _buildFieldDetailsCard() {
    final d = widget.fieldData;
    final area = (d['area_dekar'] as num?)?.toStringAsFixed(1) ?? '--';
    final crop = _fieldCrops.isNotEmpty ? _fieldCrops.first : null;
    final cropName = crop?['name']?.toString() ?? 'Ekilmedi';
    final fieldName = d['name']?.toString() ?? 'Tarla';

    // Sulama durumu
    String irrigationStatus = 'KAPALI';
    Color irrigationColor = const Color(0xFFEF5350);
    String nextIrrDate = '--';
    final now = DateTime.now();
    for (final plan in _irrigationPlans) {
      final date = plan['scheduled_date'] as DateTime?;
      if (date != null && date.isAfter(now)) {
        irrigationStatus = plan['should_irrigate'] == true ? 'AKTİF' : 'KAPALI';
        irrigationColor = plan['should_irrigate'] == true
            ? const Color(0xFF00E676) : const Color(0xFFEF5350);
        nextIrrDate = DateFormat('dd/MM').format(date.toLocal());
        break;
      }
    }

    return Container(
      width: 170,
      decoration: BoxDecoration(
        color: const Color(0xFF0D1811).withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF00E676).withValues(alpha: 0.5), width: 1.5),
        boxShadow: [BoxShadow(color: const Color(0xFF00E676).withValues(alpha: 0.1), blurRadius: 8)],
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$fieldName Detayları', style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(_cropEmoji(cropName), style: const TextStyle(fontSize: 14)),
              const SizedBox(width: 8),
              Expanded(child: Text(cropName, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600))),
            ],
          ),
          const SizedBox(height: 10),
          _detailRow('Alan:', '$area Dönüm'),
          _detailRow('Sulama:', irrigationStatus, valueColor: irrigationColor),
          _detailRow('Snr Kontrol:', nextIrrDate),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white54, fontSize: 11)),
          Text(value, style: TextStyle(
            color: valueColor ?? Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  double _computeMaturityPercent(Map<String, dynamic> crop) {
    final plantedDateStr = crop['planted_date']?.toString();
    if (plantedDateStr == null) return 0;
    DateTime? plantedDate;
    final parts = plantedDateStr.split('.');
    if (parts.length == 3) {
      plantedDate = DateTime.tryParse('${parts[2]}-${parts[1]}-${parts[0]}');
    }
    plantedDate ??= DateTime.tryParse(plantedDateStr);
    if (plantedDate == null) return 0;
    final harvestDays = (crop['harvest_days'] as num?)?.toInt() ?? 90;
    final elapsed = DateTime.now().difference(plantedDate).inDays;
    return ((elapsed / harvestDays) * 100).clamp(0, 100);
  }

  // ignore: unused_element
  DateTime? _computeHarvestDate(Map<String, dynamic>? crop) {
    if (crop == null) return null;
    final plantedDateStr = crop['planted_date']?.toString();
    if (plantedDateStr == null) return null;
    DateTime? plantedDate;
    final parts = plantedDateStr.split('.');
    if (parts.length == 3) {
      plantedDate = DateTime.tryParse('${parts[2]}-${parts[1]}-${parts[0]}');
    }
    plantedDate ??= DateTime.tryParse(plantedDateStr);
    if (plantedDate == null) return null;
    final harvestDays = (crop['harvest_days'] as num?)?.toInt() ?? 90;
    return plantedDate.add(Duration(days: harvestDays));
  }

  // ═══════════════════════════════════════════════════
  // ALERT BADGES — harita üstü uyarılar
  // ═══════════════════════════════════════════════════
  List<Map<String, dynamic>> _computeAlerts() {
    final alerts = <Map<String, dynamic>>[];
    final a = _analysis;
    if (a == null) return alerts;

    final temp = (a['temp'] as num?)?.toDouble() ?? 20.0;
    final humidity = (a['humidity'] as num?)?.toDouble() ?? 50.0;
    final totalRain = (a['total_weekly_rain'] as num?)?.toDouble() ?? 0.0;
    final soilMoisture = (a['soil_moisture'] as num?)?.toDouble() ?? 0.0;

    if (temp <= 5) {
      alerts.add({'icon': Icons.ac_unit_rounded, 'title': 'DON TEHLİKESİ',
        'sub': '${temp.toStringAsFixed(0)}°C — koruma gerekli', 'color': const Color(0xFF42A5F5)});
    }
    if (temp >= 35) {
      alerts.add({'icon': Icons.whatshot_rounded, 'title': 'AŞIRI SICAK',
        'sub': '${temp.toStringAsFixed(0)}°C — gölgeleme önerilir', 'color': const Color(0xFFEF5350)});
    }
    if (soilMoisture > 0 && soilMoisture < 0.15) {
      alerts.add({'icon': Icons.water_drop_outlined, 'title': 'DÜŞÜK SU',
        'sub': '%${(soilMoisture * 100).toStringAsFixed(0)} toprak nemi', 'color': const Color(0xFFFF9800)});
    }
    if (totalRain > 30) {
      alerts.add({'icon': Icons.thunderstorm_rounded, 'title': 'YÜKSEK YAĞIŞ',
        'sub': '${totalRain.toStringAsFixed(1)} mm — drenaj kontrol', 'color': const Color(0xFF42A5F5)});
    }
    if (humidity > 80 && temp > 25) {
      alerts.add({'icon': Icons.bug_report_rounded, 'title': 'ZARARLI RİSKİ',
        'sub': 'Nem %${humidity.toStringAsFixed(0)} + ${temp.toStringAsFixed(0)}°C', 'color': const Color(0xFFFFA726)});
    }
    for (final crop in _fieldCrops) {
      final m = _computeMaturityPercent(crop);
      if (m >= 90) {
        alerts.add({'icon': Icons.agriculture_rounded, 'title': 'HASAT ZAMANI',
          'sub': '${crop['name']} — %${m.toStringAsFixed(0)} olgunluk', 'color': const Color(0xFF66BB6A)});
      }
    }
    return alerts;
  }

  Widget _buildAlertBadges() {
    final alerts = _computeAlerts();
    if (alerts.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: alerts.take(3).map((alert) {
        final color = alert['color'] as Color;
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(4), // Keskin AR tarzı köşe
              border: Border.all(color: color, width: 2), // Kalın parlak çerçeve
              boxShadow: [
                BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 15, spreadRadius: 2)
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(alert['icon'] as IconData, color: color, size: 20),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(alert['title'] as String, style: GoogleFonts.outfit(
                      color: color, fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
                    Text(alert['sub'] as String, style: const TextStyle(
                      color: Colors.white, fontSize: 10)),
                  ],
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // ignore: unused_element
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1811).withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF00E676).withValues(alpha: 0.5), width: 1),
        boxShadow: [
          BoxShadow(color: const Color(0xFF00E676).withValues(alpha: 0.2), blurRadius: 20, spreadRadius: -5),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildNavBtn(Icons.radar_rounded, 'Tarlayı Tara', _showPlantPicker, primary: true),
          _buildNavBtn(Icons.stacked_line_chart_rounded, 'Veri Trendleri', _showCropRecommendations),
          _buildNavBtn(Icons.account_balance_wallet_rounded, 'Cüzdan', _openCostLedger),
          _buildNavBtn(Icons.checklist_rtl_rounded, 'Görevler', _showDetailModal),
        ],
      ),
    );
  }

  void _openCostLedger() {
    final d = widget.fieldData;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CostLedgerScreen(
          fieldId: d['id']?.toString(),
          fieldName: d['name']?.toString(),
        ),
      ),
    );
  }

  Widget _buildNavBtn(IconData icon, String text, VoidCallback onTap, {bool primary = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: primary ? const Color(0xFF00E676) : Colors.transparent,
              shape: BoxShape.circle,
              border: primary ? null : Border.all(color: Colors.white24, width: 1),
            ),
            child: Icon(icon, color: primary ? Colors.black : Colors.white, size: 22),
          ),
          const SizedBox(height: 6),
          Text(text, style: GoogleFonts.outfit(
            color: primary ? const Color(0xFF00E676) : Colors.white70,
            fontSize: 10,
            fontWeight: primary ? FontWeight.w700 : FontWeight.w500,
          )),
        ],
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

  void _showPlantPicker() async {
    final env = _envForSuitability();
    final repo = TurkishCropsRepository.instance;
    await repo.ensureReady();
    final month = DateTime.now().month;

    final scored = repo.search(query: '', limit: 500).map((tc) {
      final result = tc.scoreFor(
        temperature: env.temp,
        soilPh: env.ph,
        weeklyRain: env.annualRain / 52.0,
        month: month,
      );
      return {
        'plant': _turkishCropToAgriPlant(tc),
        'tcrop': tc,
        'score': result.score,
        'reasons': result.reasons,
      };
    }).toList()
      ..sort((a, b) => (b['score'] as double).compareTo(a['score'] as double));

    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _PlantPickerSheet(
        scored: scored,
        onPick: (plant) async {
          Navigator.pop(context);
          await _startZoneDrawingForPlant(plant);
        },
      ),
    );
  }

  Future<void> _startZoneDrawingForPlant(AgriPlant plant) async {
    final polygon = _polygonPoints(widget.fieldData);
    if (polygon.length < 3) {
      AppToast.show(
        context,
        message: 'Önce tarla sınırlarını çizmeniz gerekiyor.',
        type: ToastType.warning,
      );
      return;
    }

    final zoneJson = await Navigator.of(context).push<String>(
      AnimatedRoute.slideUp(
        PlantZoneDrawingScreen(
          plantName: plant.nameTr,
          plantColor: plant.renderColor,
          fieldPolygon: polygon,
        ),
      ),
    );

    if (zoneJson == null || !mounted) return;
    await _addCropWithZone(plant, zoneJson);
  }

  Future<void> _addCropWithZone(AgriPlant plant, String zonePolygonJson) async {
    final fieldId = widget.fieldData['id']?.toString();
    if (fieldId == null || fieldId.isEmpty) return;

    final repo = ref.read(localDataRepositoryProvider);
    await repo.addSingleCropToField(
      fieldId: fieldId,
      name: plant.nameTr,
      colorValue: plant.renderColor.toARGB32(),
      plantedDate:
          '${DateTime.now().day.toString().padLeft(2, '0')}.${DateTime.now().month.toString().padLeft(2, '0')}.${DateTime.now().year}',
      harvestDays: plant.daysToHarvest,
      waterIntervalDays: 7,
      zonePolygonJson: zonePolygonJson,
    );

    await _loadFieldCrops();
    if (!mounted) return;
    AppToast.show(
      context,
      message: '${plant.nameTr} tarlaya eklendi',
      type: ToastType.success,
    );
  }

  AgriPlant _turkishCropToAgriPlant(TurkishCrop tc) {
    final waterReq = switch (tc.waterNeed) {
      'low' => 300.0,
      'high' => 800.0,
      _ => 500.0,
    };
    final renderType = switch (tc.category) {
      'Tahıl' || 'Yağlı Tohum' || 'Yem Bitkisi' || 'Bahçe Otu' || 'Tıbbi Bitki' => PlantRenderType.stalk,
      'Sebze' || 'Baklagil' => PlantRenderType.bush,
      'Meyve' || 'Sert Kabuklu' || 'Süs Bitkisi' => PlantRenderType.broadleaf,
      _ => PlantRenderType.broadleaf,
    };
    final categoryEnum = switch (tc.category) {
      'Tahıl' => PlantDbCategory.grain,
      'Baklagil' => PlantDbCategory.legume,
      'Yağlı Tohum' || 'Endüstri Bitkisi' => PlantDbCategory.industrial,
      'Sebze' => PlantDbCategory.vegetable,
      'Meyve' || 'Sert Kabuklu' => PlantDbCategory.fruit,
      _ => PlantDbCategory.vegetable,
    };
    return AgriPlant(
      id: 'tc_${tc.id}',
      nameTr: tc.nameTr,
      category: categoryEnum,
      cycle: (tc.daysToHarvest ?? 120) > 365 ? 'Çok Yıllık' : 'Yıllık',
      minPh: tc.soilPhMin ?? 5.5,
      maxPh: tc.soilPhMax ?? 7.5,
      optimalTemp: tc.optimalTempC ?? 22,
      minTemp: tc.tempMinC ?? 5,
      maxTemp: tc.tempMaxC ?? 35,
      waterReqMmPerSeason: waterReq,
      daysToHarvest: tc.daysToHarvest ?? 120,
      plantDensityPerDekar: 5000,
      maxVisualHeight: 20.0,
      renderColor: _colorForCategory(tc.category),
      renderType: renderType,
    );
  }

  Color _colorForCategory(String category) {
    switch (category) {
      case 'Tahıl': return const Color(0xFFF59E0B);
      case 'Baklagil': return const Color(0xFF84CC16);
      case 'Yağlı Tohum': return const Color(0xFFFCD34D);
      case 'Endüstri Bitkisi': return const Color(0xFFE5E7EB);
      case 'Yem Bitkisi': return const Color(0xFF65A30D);
      case 'Sebze': return const Color(0xFFEF4444);
      case 'Meyve': return const Color(0xFFEC4899);
      case 'Sert Kabuklu': return const Color(0xFF92400E);
      case 'Bahçe Otu': return const Color(0xFF16A34A);
      case 'Tıbbi Bitki': return const Color(0xFF8B5CF6);
      case 'Süs Bitkisi': return const Color(0xFFF472B6);
      default: return const Color(0xFF43A047);
    }
  }

  // ═════════════════════════════════════════════════
  // BÖLGE ÇİZME MODU — İnteraktif ürün yerleştirme
  // ═════════════════════════════════════════════════

  void _cancelZoneDrawing() {
    setState(() {
      _isZoneDrawingMode = false;
      _zoneDrawingPoints = [];
      _pendingPlant = null;
    });
  }

  void _undoLastZonePoint() {
    if (_zoneDrawingPoints.isNotEmpty) {
      setState(() {
        _zoneDrawingPoints = List.from(_zoneDrawingPoints)..removeLast();
      });
    }
  }

  void _onMapTapForZone(LatLng point) {
    if (!_isZoneDrawingMode) return;

    final polygon = _polygonPoints(widget.fieldData);
    if (polygon.length < 3) return;

    // Nokta tarla poligonu içinde mi kontrol et
    if (!_pointInPolygon(point.latitude, point.longitude, polygon)) {
      AppToast.show(
        context,
        message: 'Bu nokta tarla sınırları dışında.',
        type: ToastType.warning,
        duration: const Duration(seconds: 2),
      );
      return;
    }

    setState(() {
      _zoneDrawingPoints = [..._zoneDrawingPoints, point];
    });
  }

  Future<void> _completeZoneDrawing() async {
    if (_pendingPlant == null || _zoneDrawingPoints.length < 3) return;

    final plant = _pendingPlant!;
    final fieldId = widget.fieldData['id']?.toString();
    if (fieldId == null || fieldId.isEmpty) return;

    // Zone polygon'u JSON'a çevir
    final zoneJson = jsonEncode(
      _zoneDrawingPoints
          .map((p) => {'lat': p.latitude, 'lng': p.longitude})
          .toList(),
    );

    final repo = ref.read(localDataRepositoryProvider);
    await repo.addSingleCropToField(
      fieldId: fieldId,
      name: plant.nameTr,
      colorValue: plant.renderColor.toARGB32(),
      plantedDate:
          '${DateTime.now().day.toString().padLeft(2, '0')}.${DateTime.now().month.toString().padLeft(2, '0')}.${DateTime.now().year}',
      harvestDays: plant.daysToHarvest,
      waterIntervalDays: 7,
      zonePolygonJson: zoneJson,
    );

    setState(() {
      _isZoneDrawingMode = false;
      _zoneDrawingPoints = [];
      _pendingPlant = null;
    });

    await _loadFieldCrops();
    if (!mounted) return;
    AppToast.show(
      context,
      message: '${plant.nameTr} seçilen bölgeye yerleştirildi.',
      type: ToastType.success,
    );
  }

  /// Bölgeye dokunulduğunda tooltip göster
  void _onCropZoneTap(Map<String, dynamic> crop) {
    if (_isZoneDrawingMode) return;
    setState(() {
      _selectedCropForTooltip = crop;
    });
  }

  void _closeTooltip() {
    setState(() => _selectedCropForTooltip = null);
  }

  Future<void> _deleteCropZone(Map<String, dynamic> crop) async {
    final cropId = crop['id']?.toString();
    if (cropId == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Bölgeyi Sil'),
        content: Text('"${crop['name']}" bölgesi silinecek. Emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('İptal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sil'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(localDataRepositoryProvider).deleteSingleCrop(cropId);
      _closeTooltip();
      await _loadFieldCrops();
      if (!mounted) return;
      AppToast.show(
        context,
        message: '${crop['name']} bölgesi silindi.',
        type: ToastType.info,
      );
    }
  }

  // Eski _plantCrop uyumluluk için (zone olmadan ekleme)
  // ignore: unused_element
  Future<void> _plantCrop(AgriPlant plant) async {
    final fieldId = widget.fieldData['id']?.toString();
    if (fieldId == null || fieldId.isEmpty) {
      AppToast.show(
        context,
        message: 'Tarla kimliği bulunamadı.',
        type: ToastType.error,
      );
      return;
    }

    final repo = ref.read(localDataRepositoryProvider);
    await repo.addSingleCropToField(
      fieldId: fieldId,
      name: plant.nameTr,
      colorValue: plant.renderColor.toARGB32(),
      plantedDate:
          '${DateTime.now().day.toString().padLeft(2, '0')}.${DateTime.now().month.toString().padLeft(2, '0')}.${DateTime.now().year}',
      harvestDays: plant.daysToHarvest,
      waterIntervalDays: 7,
    );

    await _loadFieldCrops();
    if (!mounted) return;
    AppToast.show(
      context,
      message: '${plant.nameTr} tarlaya eklendi.',
      type: ToastType.success,
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

  /// Polygon iç bölgesi için, kullanıcının çizdiği "İLK KENAR" referans alınarak (row-aligned) 
  /// düzgün sıralar halinde (setlere bölünmüş) grid noktaları üretir.
  List<LatLng> _gridInsidePolygon(List<LatLng> polygon, int targetCount) {
    if (polygon.length < 3 || targetCount <= 0) return const [];
    
    // Anlamlı Çekim (Row Alignment): Set'in ilk kenarı (A -> B) sıra yönü olarak kabul edilir.
    final origin = polygon[0];
    final double dx = polygon[1].longitude - polygon[0].longitude;
    final double dy = polygon[1].latitude - polygon[0].latitude;
    final double angle = math.atan2(dy, dx);
    
    // Döndürme yardımcı fonksiyonu
    LatLng rotate(LatLng p, double a, LatLng center) {
      final x = p.longitude - center.longitude;
      final y = p.latitude - center.latitude;
      final rx = x * math.cos(a) - y * math.sin(a);
      final ry = x * math.sin(a) + y * math.cos(a);
      return LatLng(center.latitude + ry, center.longitude + rx);
    }
    
    // Poligonu -angle ile döndürerek ilk kenarı düz (X) eksenine hizala
    final rotatedPoly = polygon.map((p) => rotate(p, -angle, origin)).toList();

    double minLat = rotatedPoly.first.latitude, maxLat = rotatedPoly.first.latitude;
    double minLng = rotatedPoly.first.longitude, maxLng = rotatedPoly.first.longitude;
    for (final p in rotatedPoly) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }
    
    final steps = math.max(3, math.sqrt(targetCount).ceil() + 2);
    final result = <LatLng>[];
    
    for (int i = 0; i <= steps; i++) {
      for (int j = 0; j <= steps; j++) {
        final lat = minLat + (maxLat - minLat) * (i / steps);
        final lng = minLng + (maxLng - minLng) * (j / steps);
        
        // Döndürülmüş poligon içinde mi?
        if (_pointInPolygon(lat, lng, rotatedPoly)) {
          // Noktayı tekrar orjinal açısına geri döndür! (Sıraları çapraz tarlaya oturt)
          final originalPoint = rotate(LatLng(lat, lng), angle, origin);
          result.add(originalPoint);
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

  /// Sub-polygon JSON'dan LatLng listesi çıkar
  List<LatLng> _parseZonePolygon(String? json) {
    if (json == null || json.isEmpty) return const [];
    try {
      final decoded = jsonDecode(json);
      if (decoded is List) {
        return decoded
            .whereType<Map>()
            .map((e) => LatLng(
                  (e['lat'] as num).toDouble(),
                  (e['lng'] as num).toDouble(),
                ))
            .toList();
      }
    } catch (_) {}
    return const [];
  }

  Widget _build3DFieldMap(Map<String, dynamic> d) {
    final polygon = _polygonPoints(d);
    final center = _fieldCenter(d, polygon);
    final crops = _plantedCrops(d);

    const borderColor = Color(0xFF00E676);

    // Polygon bounds — kameranın sınırları ve initial fit için.
    LatLngBounds? bounds;
    if (polygon.length >= 3) {
      bounds = LatLngBounds.fromPoints(polygon);
    }

    // ── Ekili bölge poligonları (zonePolygonJson olanlar) ──
    final zonePolygons = <Polygon>[];
    final zoneMarkers = <Marker>[];
    // Zone olmayan bitkiler için eski grid markerlar
    final gridCrops = <Map<String, dynamic>>[];

    for (final crop in crops) {
      final zoneJson = crop['zone_polygon_json']?.toString();
      final zonePoly = _parseZonePolygon(zoneJson);

      if (zonePoly.length >= 3) {
        final color = _cropColor(crop);
        zonePolygons.add(Polygon(
          points: zonePoly,
          color: color.withValues(alpha: 0.15),
          borderColor: color,
          borderStrokeWidth: 4.0,
        ));

        // Bölgeyi tamamen dolduran marker ağı oluştur — dokunulabilir
        final maturity = _computeMaturityPercent(crop);
        final positions = _gridInsidePolygon(zonePoly, 80); // Yoğun grid
        if (positions.isEmpty) {
          double cLat = 0, cLng = 0;
          for (final p in zonePoly) { cLat += p.latitude; cLng += p.longitude; }
          positions.add(LatLng(cLat / zonePoly.length, cLng / zonePoly.length));
        }

        // Z-Index Sorting: Painter's Algorithm (Kuzeyden Güneye doğru sırala)
        positions.sort((a, b) => b.latitude.compareTo(a.latitude));

        for (final pos in positions) {
          zoneMarkers.add(Marker(
            point: pos,
            width: 240,
            height: 280,
            child: AnimatedBuilder(
              animation: _harvestPulseCtrl,
              builder: (_, __) => buildCropMarkerWidget(
                cropName: crop['name']?.toString() ?? '',
                cropColor: color,
                maturityPercent: maturity,
                harvestPulse: _harvestPulseCtrl.value,
                onTap: () => _onCropZoneTap(crop),
              ),
            ),
          ));
        }
      } else {
        gridCrops.add(crop);
      }
    }

    // Zone olmayan bitkiler için eski grid markerlar
    final positions = _gridInsidePolygon(polygon, 60);
    // Z-Index Sorting
    positions.sort((a, b) => b.latitude.compareTo(a.latitude));

    final markers = <Marker>[];
    if (gridCrops.isNotEmpty && positions.isNotEmpty) {
      for (int i = 0; i < positions.length; i++) {
        final crop = gridCrops[i % gridCrops.length];
        final maturity = _computeMaturityPercent(crop);
        markers.add(
          Marker(
            point: positions[i],
            width: 240,
            height: 280,
            child: AnimatedBuilder(
              animation: _harvestPulseCtrl,
              builder: (_, __) => buildCropMarkerWidget(
                cropName: crop['name']?.toString() ?? '',
                cropColor: _cropColor(crop),
                maturityPercent: maturity,
                harvestPulse: _harvestPulseCtrl.value,
                onTap: () => _onCropZoneTap(crop),
              ),
            ),
          ),
        );
      }
    }

    // ── Bölge çizme modu — çizilmekte olan polygon ──
    final drawingPolygons = <Polygon>[];
    final drawingMarkers = <Marker>[];
    if (_isZoneDrawingMode && _zoneDrawingPoints.isNotEmpty) {
      // Çizilmekte olan polygon
      if (_zoneDrawingPoints.length >= 3) {
        final drawColor = _pendingPlant?.renderColor ?? const Color(0xFF00E676);
        drawingPolygons.add(Polygon(
          points: _zoneDrawingPoints,
          color: drawColor.withValues(alpha: 0.20),
          borderColor: drawColor,
          borderStrokeWidth: 3.0,
        ));
      }

      // Nokta markerları (numaralı)
      for (int i = 0; i < _zoneDrawingPoints.length; i++) {
        drawingMarkers.add(Marker(
          point: _zoneDrawingPoints[i],
          width: 28,
          height: 28,
          child: Container(
            decoration: BoxDecoration(
              color: (_pendingPlant?.renderColor ?? const Color(0xFF00E676))
                  .withValues(alpha: 0.85),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
            alignment: Alignment.center,
            child: Text(
              '${i + 1}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ));
      }
    }

    // Köşe etiketleri (A, B, C, D ...)
    final cornerMarkers = <Marker>[];
    for (int i = 0; i < polygon.length && i < 26; i++) {
      cornerMarkers.add(
        Marker(
          point: polygon[i],
          width: 36,
          height: 36,
          child: Container(
            alignment: Alignment.center,
            child: Text(
              String.fromCharCode(65 + i),
              style: GoogleFonts.outfit(
                color: const Color(0xFF00E676),
                fontWeight: FontWeight.w900,
                fontSize: 24,
                shadows: [
                  Shadow(color: const Color(0xFF00E676).withValues(alpha: 0.8), blurRadius: 12),
                  const Shadow(color: Colors.black, blurRadius: 4),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Transform(
      transform: Matrix4.identity()
        ..scaleByDouble(1.5, 1.5, 1.0, 1.0)
        ..setEntry(3, 2, 0.001)
        ..rotateX(-0.85), // Tarlayı geriye doğru 45 derece yatırır (doğru izometrik bakış)
      alignment: FractionalOffset.center,
      child: FlutterMap(
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
        interactionOptions: InteractionOptions(
          flags: _isZoneDrawingMode
              ? InteractiveFlag.pinchZoom | InteractiveFlag.drag
              : InteractiveFlag.pinchZoom |
                  InteractiveFlag.drag |
                  InteractiveFlag.doubleTapZoom,
        ),
        onTap: _isZoneDrawingMode
            ? (tapPos, point) => _onMapTapForZone(point)
            : null,
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
                borderColor: borderColor.withValues(alpha: 0.5),
                borderStrokeWidth: 12.0,
              ),
              // Ana sınır + dolgu
              Polygon(
                points: polygon,
                color: Colors.black.withValues(alpha: 0.2),
                borderColor: borderColor,
                borderStrokeWidth: 4.0,
              ),
              // Ekili bölge poligonları
              ...zonePolygons,
              // Çizilmekte olan polygon
              ...drawingPolygons,
            ],
          ),
        if (markers.isNotEmpty) MarkerLayer(markers: markers),
        if (zoneMarkers.isNotEmpty) MarkerLayer(markers: zoneMarkers),
        if (drawingMarkers.isNotEmpty) MarkerLayer(markers: drawingMarkers),
        if (cornerMarkers.isNotEmpty) MarkerLayer(markers: cornerMarkers),
      ],
    ),
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

  // ═══════════════════════════════════════════════════
  // DETAY MODAL — Kapsamlı yetiştirme bilgileri
  // ═══════════════════════════════════════════════════
  void _showDetailModal() {
    final a = _analysis;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _DetailModalContent(
        analysis: a,
        fieldData: widget.fieldData,
        fieldCrops: _fieldCrops,
        irrigationPlans: _irrigationPlans,
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

class _PlantPickerSheet extends StatefulWidget {
  final List<Map<String, dynamic>> scored;
  final void Function(AgriPlant plant) onPick;
  const _PlantPickerSheet({required this.scored, required this.onPick});

  @override
  State<_PlantPickerSheet> createState() => _PlantPickerSheetState();
}

class _PlantPickerSheetState extends State<_PlantPickerSheet> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  String _normalize(String s) => s
      .toLowerCase()
      .replaceAll('ı', 'i')
      .replaceAll('ğ', 'g')
      .replaceAll('ü', 'u')
      .replaceAll('ş', 's')
      .replaceAll('ö', 'o')
      .replaceAll('ç', 'c');

  List<Map<String, dynamic>> get _filtered {
    if (_query.trim().isEmpty) return widget.scored;
    final q = _normalize(_query.trim());
    return widget.scored.where((e) {
      final p = e['plant'] as AgriPlant;
      return _normalize(p.nameTr).contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
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
          TextField(
            controller: _searchCtrl,
            onChanged: (v) => setState(() => _query = v),
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Bitki ara (ör. buğday, domates)',
              prefixIcon: const Icon(Icons.search_rounded,
                  color: Color(0xFF2E7D32)),
              suffixIcon: _query.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () {
                        _searchCtrl.clear();
                        setState(() => _query = '');
                      },
                    ),
              filled: true,
              fillColor: const Color(0xFFF5F7F5),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Divider(height: 1),
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'Sonuç bulunamadı.\nFarklı bir isim deneyin.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                            fontSize: 13, color: Colors.grey.shade600),
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (context, i) {
                      final AgriPlant p = filtered[i]['plant'] as AgriPlant;
                      final int score = (filtered[i]['score'] as double).round();
                      final List<String> reasons =
                          (filtered[i]['reasons'] as List).cast<String>();
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
                      onTap: () => widget.onPick(p),
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

// ═══════════════════════════════════════════════════════════════════════
// DETAY MODAL — Kapsamlı yetiştirme bilgileri
// ═══════════════════════════════════════════════════════════════════════
class _DetailModalContent extends StatelessWidget {
  final Map<String, dynamic>? analysis;
  final dynamic fieldData;
  final List<Map<String, dynamic>> fieldCrops;
  final List<Map<String, dynamic>> irrigationPlans;

  const _DetailModalContent({
    required this.analysis,
    required this.fieldData,
    required this.fieldCrops,
    required this.irrigationPlans,
  });

  @override
  Widget build(BuildContext context) {
    final a = analysis;
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Color(0xFF0D1811),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle bar
          const SizedBox(height: 8),
          Container(width: 40, height: 4,
              decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(children: [
              const Icon(Icons.article_rounded, color: Color(0xFF00E676), size: 22),
              const SizedBox(width: 10),
              Text('Tarla Detay Raporu',
                  style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
              const Spacer(),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close, color: Colors.white54),
              ),
            ]),
          ),
          const Divider(color: Colors.white12, height: 20),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
              children: [
                // 1. Haftalık Hava Yorumu
                if (a?['ai_weekly_comment'] != null) ...[
                  _sectionHeader('📊 Haftalık Değerlendirme'),
                  const SizedBox(height: 8),
                  _textCard(a!['ai_weekly_comment'].toString()),
                  const SizedBox(height: 20),
                ],

                // 2. Ekili Bitkiler
                if (fieldCrops.isNotEmpty) ...[
                  _sectionHeader('🌱 Ekili Bitkiler'),
                  const SizedBox(height: 8),
                  ...fieldCrops.map((crop) => _buildCropInfoCard(crop)),
                  const SizedBox(height: 20),
                ],

                // 3. 7 Günlük Hava Tahmini
                if (a?['daily_forecast'] is List && (a!['daily_forecast'] as List).isNotEmpty) ...[
                  _sectionHeader('🌤️ 7 Günlük Hava Tahmini'),
                  const SizedBox(height: 8),
                  _buildForecastTable(a['daily_forecast'] as List),
                  const SizedBox(height: 20),
                ],

                // 4. Gübreleme Önerisi
                if (a != null) ...[
                  _sectionHeader('🧪 Gübreleme Önerisi'),
                  const SizedBox(height: 8),
                  _textCard(_getFertilizerAdvice((a['ph'] as num?)?.toDouble() ?? 6.5)),
                  const SizedBox(height: 20),
                ],

                // 6. Çevre Özeti
                if (a != null) ...[
                  _sectionHeader('🌍 Çevre Özeti'),
                  const SizedBox(height: 8),
                  _buildEnvironmentSummary(a),
                  const SizedBox(height: 20),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Text(title, style: GoogleFonts.outfit(
      fontSize: 15, fontWeight: FontWeight.w700, color: const Color(0xFF00E676)));
  }

  Widget _textCard(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Text(text, style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.5)),
    );
  }

  // ── Ekili bitki kartı ────────────────────────────────────────
  Widget _buildCropInfoCard(Map<String, dynamic> crop) {
    final name = crop['name']?.toString() ?? 'Bilinmeyen';
    final plantedStr = crop['planted_date']?.toString();
    final harvestDays = (crop['harvest_days'] as num?)?.toInt() ?? 90;
    final waterInterval = (crop['water_interval_days'] as num?)?.toInt() ?? 7;

    DateTime? plantedDate;
    if (plantedStr != null) {
      final parts = plantedStr.split('.');
      if (parts.length == 3) {
        plantedDate = DateTime.tryParse('${parts[2]}-${parts[1]}-${parts[0]}');
      }
      plantedDate ??= DateTime.tryParse(plantedStr);
    }

    final elapsed = plantedDate != null ? DateTime.now().difference(plantedDate).inDays : 0;
    final maturity = ((elapsed / harvestDays) * 100).clamp(0.0, 100.0);
    final harvestDate = plantedDate?.add(Duration(days: harvestDays));
    final remaining = harvestDate != null ? harvestDate.difference(DateTime.now()).inDays : 0;

    // Verified DB'den ideal koşulları bul
    String idealConditions = '';
    for (final p in VerifiedAgriDatabase.plants) {
      if (p.nameTr.toLowerCase() == name.toLowerCase()) {
        idealConditions = 'pH ${p.minPh}-${p.maxPh} • '
            '${p.minTemp.toInt()}-${p.maxTemp.toInt()}°C • '
            'Su: ${p.waterReqMmPerSeason.toInt()} mm/sezon • '
            'Yoğunluk: ${p.plantDensityPerDekar}/dönüm';
        break;
      }
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF00E676).withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Text(name, style: const TextStyle(
                  color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: maturity >= 90
                      ? const Color(0xFF00E676).withValues(alpha: 0.2)
                      : Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  maturity >= 90 ? 'HASAT ZAMANI' : '%${maturity.toStringAsFixed(0)} olgun',
                  style: TextStyle(
                    color: maturity >= 90 ? const Color(0xFF00E676) : Colors.white70,
                    fontSize: 11, fontWeight: FontWeight.w700),
                ),
              ),
            ]),
            const SizedBox(height: 8),
            if (plantedDate != null)
              _infoLine('📅 Ekim', DateFormat('dd.MM.yyyy').format(plantedDate)),
            if (harvestDate != null) ...[
              _infoLine('🗓️ Tahmini Hasat', DateFormat('dd.MM.yyyy').format(harvestDate)),
              _infoLine('⏳ Kalan', remaining > 0 ? '$remaining gün' : 'Hasat zamanı!'),
            ],
            _infoLine('📆 Geçen', '$elapsed / $harvestDays gün'),
            _infoLine('💧 Sulama Aralığı', 'Her $waterInterval günde bir'),
            // Olgunluk barı
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: maturity / 100,
                minHeight: 6,
                backgroundColor: Colors.white.withValues(alpha: 0.1),
                valueColor: AlwaysStoppedAnimation(
                  maturity >= 90 ? const Color(0xFF00E676) : const Color(0xFF4CAF50)),
              ),
            ),
            if (idealConditions.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('📋 İdeal Koşullar: $idealConditions',
                  style: const TextStyle(color: Colors.white38, fontSize: 10)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _infoLine(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Row(
        children: [
          Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12)),
          const Spacer(),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  // ── 7 Günlük Tahmin Tablosu ──────────────────────────────────
  Widget _buildForecastTable(List forecast) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          // Başlık satırı
          const Row(children: [
            Expanded(flex: 2, child: Text('Tarih', style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.w600))),
            Expanded(child: Text('Max', style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.w600), textAlign: TextAlign.center)),
            Expanded(child: Text('Min', style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.w600), textAlign: TextAlign.center)),
            Expanded(child: Text('Yağış', style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.w600), textAlign: TextAlign.center)),
          ]),
          const Divider(color: Colors.white12, height: 12),
          ...forecast.take(7).map((day) {
            final date = day['date']?.toString() ?? '--';
            final max = (day['max'] as num?)?.toStringAsFixed(0) ?? '--';
            final min = (day['min'] as num?)?.toStringAsFixed(0) ?? '--';
            final rain = (day['rain'] as num?)?.toStringAsFixed(1) ?? '0';
            final hasRain = ((day['rain'] as num?)?.toDouble() ?? 0) > 1;
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(children: [
                Expanded(flex: 2, child: Text(date, style: const TextStyle(color: Colors.white70, fontSize: 11))),
                Expanded(child: Text('$max°', style: const TextStyle(color: Color(0xFFFFCC80), fontSize: 11, fontWeight: FontWeight.w600), textAlign: TextAlign.center)),
                Expanded(child: Text('$min°', style: const TextStyle(color: Color(0xFF90CAF9), fontSize: 11, fontWeight: FontWeight.w600), textAlign: TextAlign.center)),
                Expanded(child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (hasRain) const Icon(Icons.water_drop, color: Color(0xFF42A5F5), size: 10),
                    Text(rain, style: TextStyle(color: hasRain ? const Color(0xFF42A5F5) : Colors.white54, fontSize: 11), textAlign: TextAlign.center),
                  ],
                )),
              ]),
            );
          }),
        ],
      ),
    );
  }

  // ── Gübreleme Önerisi ────────────────────────────────────────
  String _getFertilizerAdvice(double ph) {
    final sb = StringBuffer();

    if (ph < 5.5) {
      sb.writeln('⚠️ Toprak çok asidik (pH ${ph.toStringAsFixed(1)}):');
      sb.writeln('• Dekara 200-300 kg tarım kireci uygulayın');
      sb.writeln('• Kireçleme sonbahar/kış aylarında yapılmalı');
      sb.writeln('• 6 ay sonra pH kontrolü yapın');
    } else if (ph > 7.5) {
      sb.writeln('⚠️ Toprak bazik (pH ${ph.toStringAsFixed(1)}):');
      sb.writeln('• Dekara 20-30 kg elementel kükürt uygulayın');
      sb.writeln('• Asidik gübreler tercih edin (Amonyum Sülfat)');
      sb.writeln('• Demir ve çinko yaprak gübresi takviyesi yapın');
    } else {
      sb.writeln('✅ pH uygun aralıkta (${ph.toStringAsFixed(1)}):');
      sb.writeln('• Dengeli NPK (15-15-15) gübresi kullanın');
      sb.writeln('• İlkbahar: Dekara 20 kg taban gübresi');
      sb.writeln('• Gelişim dönemi: Dekara 10 kg Amonyum Nitrat');
    }

    sb.writeln();
    sb.writeln('ℹ️ Genel Öneriler:');
    sb.writeln('• Gübrelemeyi sabah erken saatlerde yapın');
    sb.writeln('• Sulama öncesi gübreleme daha etkilidir');
    sb.writeln('• Organik gübre (çiftlik gübresi) toprak yapısını iyileştirir');

    return sb.toString().trim();
  }

  // ── Çevre Özeti ──────────────────────────────────────────────
  Widget _buildEnvironmentSummary(Map<String, dynamic> a) {
    final temp = (a['temp'] as num?)?.toDouble() ?? 0;
    final humidity = (a['humidity'] as num?)?.toDouble() ?? 0;
    final wind = (a['wind'] as num?)?.toDouble() ?? 0;
    final ph = (a['ph'] as num?)?.toDouble() ?? 6.5;
    final avgTemp = (a['avg_weekly_temp'] as num?)?.toDouble() ?? 0;
    final rain = (a['total_weekly_rain'] as num?)?.toDouble() ?? 0;
    final soilMoisture = (a['soil_moisture'] as num?)?.toDouble() ?? 0;
    final soilTemp = (a['soil_temp_c'] as num?)?.toDouble() ?? 0;
    final weatherDesc = a['weather_desc']?.toString() ?? '';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (weatherDesc.isNotEmpty)
            _envLine('☁️ Hava', weatherDesc),
          _envLine('🌡️ Anlık Sıcaklık', '${temp.toStringAsFixed(1)}°C'),
          _envLine('📊 Haftalık Ort.', '${avgTemp.toStringAsFixed(1)}°C'),
          _envLine('💧 Nem', '%${humidity.toStringAsFixed(0)}'),
          _envLine('💨 Rüzgar', '${wind.toStringAsFixed(1)} m/s'),
          _envLine('🌧️ Hft. Yağış', '${rain.toStringAsFixed(1)} mm'),
          _envLine('🌿 Toprak pH', ph.toStringAsFixed(1)),
          if (soilMoisture > 0)
            _envLine('💧 Toprak Nem', '%${(soilMoisture * 100).toStringAsFixed(1)}'),
          if (soilTemp > 0)
            _envLine('🌡️ Toprak Sıc.', '${soilTemp.toStringAsFixed(1)}°C'),
        ],
      ),
    );
  }

  Widget _envLine(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12)),
          const Spacer(),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
