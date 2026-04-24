import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import '../services/agri_service.dart';
import '../services/app_providers.dart';
import '../services/crop_placement.dart';
import '../services/crop_protocol_service.dart';
import '../services/growth_engine.dart';
import '../services/notification_service.dart';
import '../services/task_directive_service.dart';
import '../data/activity_types.dart';
import '../data/app_database.dart';
import '../data/crop_protocols.dart';
import '../data/supported_crops.dart';
import '../data/verified_agri_database.dart';
import '../data/turkish_crops_repository.dart';
import '../widgets/activity_quick_log.dart';
import '../widgets/floating_toast.dart';
import '../widgets/glass_panel.dart';
import '../widgets/season_summary_card.dart';
import '../widgets/zone_drawing_toolbar.dart';
import '../widgets/crop_zone_tooltip.dart';
import '../widgets/crop_render_factory.dart';
import 'cost_ledger_screen.dart';
import 'farm_journal_screen.dart';
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
    for (final crop in crops) {
      final cropId = crop['id']?.toString();
      if (cropId != null && cropId.isNotEmpty) {
        await ref.read(growthEngineProvider).recompute(cropId: cropId);
      }
    }
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

    final topCrop = recommendedCrops.isNotEmpty
        ? recommendedCrops.first
        : <String, dynamic>{};
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
        'avg_weekly_temp':
            (analysis['avg_weekly_temp'] as num?)?.toDouble() ?? 0.0,
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
              final report =
                  await ref.read(syncServiceProvider).runPushCycleWithApi(
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
    final fieldId = d['id']?.toString();

    // ── Aktivite log'u değiştiğinde 3 vitrin bitki için adım ilerlemesi ──
    // kontrol et; yeni adım açıldıysa lokal bildirim at. Saf yan etki —
    // listener async, build hızını etkilemez.
    if (fieldId != null && fieldId.isNotEmpty) {
      ref.listen<AsyncValue<List<Map<String, dynamic>>>>(
        fieldActivityLogProvider(fieldId),
        (prev, next) {
          final activities = next.valueOrNull;
          if (activities == null) return;
          for (final crop in _fieldCrops) {
            CropProtocolService.checkAndNotifyStepAdvanced(
              fieldId: fieldId,
              crop: crop,
              activities: activities,
            );
          }
        },
      );
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: const Color(0xFF0D1811), // Deep premium dark green
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 60,
        leadingWidth: 48,
        leading: IconButton(
          icon:
              const Icon(Icons.arrow_back, color: Color(0xFF00E676), size: 24),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                  shape: BoxShape.circle, color: Color(0xFF00E676)),
              child:
                  const Icon(Icons.eco_rounded, color: Colors.black, size: 16),
            ),
            const SizedBox(width: 8),
            Text('Agri-Farm ',
                style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white)),
            Text('AR',
                style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF00E676))),
          ],
        ),
        centerTitle: false,
        actions: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('AKTİF',
                  style: TextStyle(
                      color: Colors.white70, fontSize: 10, letterSpacing: 1.2)),
              const SizedBox(width: 6),
              Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFF00E676),
                      boxShadow: [
                        BoxShadow(color: Color(0xFF00E676), blurRadius: 4)
                      ])),
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
                    _mapController.move(_mapController.camera.center,
                        (z + 1).clamp(14.0, 21.0));
                  }),
                  const SizedBox(height: 8),
                  _zoomBtn(Icons.remove, () {
                    final z = _mapController.camera.zoom;
                    _mapController.move(_mapController.camera.center,
                        (z - 1).clamp(14.0, 21.0));
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
                plantColor:
                    _pendingPlant?.renderColor ?? const Color(0xFF00E676),
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
                  cropName:
                      _selectedCropForTooltip!['name']?.toString() ?? 'Bitki',
                  cropColor: _cropColor(_selectedCropForTooltip!),
                  plantedDate:
                      _selectedCropForTooltip!['planted_date']?.toString(),
                  harvestDays:
                      (_selectedCropForTooltip!['harvest_days'] as num?)
                              ?.toInt() ??
                          90,
                  maturityPercent:
                      _computeMaturityPercent(_selectedCropForTooltip!),
                  onDelete: () => _deleteCropZone(_selectedCropForTooltip!),
                  onClose: _closeTooltip,
                ),
              ),
            ),

          if (_isLoading)
            const Center(
                child: CircularProgressIndicator(color: Color(0xFF00E676))),
          if (_error != null)
            Center(
                child: GlassPanel(
                    child: Text(_error!,
                        style: const TextStyle(color: Colors.white)))),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════
  // LIVE STATS PANEL — 4 ana canli metrik (AR Tarzı)
  // ═══════════════════════════════════════════════════
  // ignore: unused_element
  Widget _buildLiveStatsPanel(Map<String, dynamic>? a) {
    final soilTemp = a != null
        ? '${(a['soil_temp_c'] as num?)?.toStringAsFixed(0) ?? '--'}°C'
        : '--°C';
    final rain = a != null
        ? '${(a['total_weekly_rain'] as num?)?.toStringAsFixed(1) ?? '--'} mm'
        : '-- mm';

    final tempVal = (a?['temp'] as num?)?.toDouble() ?? 20.0;
    final humidVal = (a?['humidity'] as num?)?.toDouble() ?? 50.0;
    String pestLevel = 'Düşük';
    Color pestColor = const Color(0xFF00E676);
    if (humidVal > 70 && tempVal > 25) {
      pestLevel = 'Yüksek';
      pestColor = const Color(0xFFEF5350);
    } else if (humidVal > 60) {
      pestLevel = 'Orta';
      pestColor = const Color(0xFFFFA726);
    }

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
        border: Border.all(
            color: const Color(0xFF00E676).withValues(alpha: 0.7), width: 1.5),
        boxShadow: [
          BoxShadow(
              color: const Color(0xFF00E676).withValues(alpha: 0.15),
              blurRadius: 10)
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Canlı Veriler',
                  style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.white)),
              const Icon(Icons.more_horiz, color: Colors.white54, size: 16),
            ],
          ),
          const SizedBox(height: 12),
          _arStatCard(Icons.monitor_heart_rounded, 'Tarla Sağlığı', healthScore,
              const Color(0xFF00E676)),
          _arStatCard(Icons.thermostat_rounded, 'Toprak Sıcaklık', soilTemp,
              const Color(0xFFFFB74D)),
          _arStatCard(
              Icons.water_drop_rounded, 'Yağış', rain, const Color(0xFF4FC3F7)),
          _arStatCard(
              Icons.bug_report_rounded, 'Zararlı Seviye', pestLevel, pestColor),
        ],
      ),
    );
  }

  Widget _arStatCard(
      IconData icon, String label, String value, Color accentColor) {
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
                Text(label,
                    style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 10,
                        fontWeight: FontWeight.w500)),
                Text(value,
                    style: TextStyle(
                        color: accentColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5)),
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
            ? const Color(0xFF00E676)
            : const Color(0xFFEF5350);
        nextIrrDate = DateFormat('dd/MM').format(date.toLocal());
        break;
      }
    }

    return Container(
      width: 170,
      decoration: BoxDecoration(
        color: const Color(0xFF0D1811).withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: const Color(0xFF00E676).withValues(alpha: 0.5), width: 1.5),
        boxShadow: [
          BoxShadow(
              color: const Color(0xFF00E676).withValues(alpha: 0.1),
              blurRadius: 8)
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$fieldName Detayları',
              style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.white)),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(_cropEmoji(cropName), style: const TextStyle(fontSize: 14)),
              const SizedBox(width: 8),
              Expanded(
                  child: Text(cropName,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600))),
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
          Text(label,
              style: const TextStyle(color: Colors.white54, fontSize: 11)),
          Text(value,
              style: TextStyle(
                  color: valueColor ?? Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  double _computeMaturityPercent(
    Map<String, dynamic> crop, {
    CropGrowthState? growthState,
  }) {
    if (growthState != null) {
      final canonical = SupportedCrops.canonicalName(crop['name']?.toString());
      if (canonical != null) {
        final key = SupportedCrops.normalize(canonical);
        if (GrowthEngine.isSupported(key)) {
          return (GrowthEngine.overallProgressFor(
                    key,
                    growthState.accumulatedGdd,
                  ) *
                  100)
              .clamp(0, 100)
              .toDouble();
        }
      }
    }
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
      alerts.add({
        'icon': Icons.ac_unit_rounded,
        'title': 'DON TEHLİKESİ',
        'sub': '${temp.toStringAsFixed(0)}°C — koruma gerekli',
        'color': const Color(0xFF42A5F5)
      });
    }
    if (temp >= 35) {
      alerts.add({
        'icon': Icons.whatshot_rounded,
        'title': 'AŞIRI SICAK',
        'sub': '${temp.toStringAsFixed(0)}°C — gölgeleme önerilir',
        'color': const Color(0xFFEF5350)
      });
    }
    if (soilMoisture > 0 && soilMoisture < 0.15) {
      alerts.add({
        'icon': Icons.water_drop_outlined,
        'title': 'DÜŞÜK SU',
        'sub': '%${(soilMoisture * 100).toStringAsFixed(0)} toprak nemi',
        'color': const Color(0xFFFF9800)
      });
    }
    if (totalRain > 30) {
      alerts.add({
        'icon': Icons.thunderstorm_rounded,
        'title': 'YÜKSEK YAĞIŞ',
        'sub': '${totalRain.toStringAsFixed(1)} mm — drenaj kontrol',
        'color': const Color(0xFF42A5F5)
      });
    }
    if (humidity > 80 && temp > 25) {
      alerts.add({
        'icon': Icons.bug_report_rounded,
        'title': 'ZARARLI RİSKİ',
        'sub':
            'Nem %${humidity.toStringAsFixed(0)} + ${temp.toStringAsFixed(0)}°C',
        'color': const Color(0xFFFFA726)
      });
    }
    for (final crop in _fieldCrops) {
      final m = _computeMaturityPercent(crop);
      if (m >= 90) {
        alerts.add({
          'icon': Icons.agriculture_rounded,
          'title': 'HASAT ZAMANI',
          'sub': '${crop['name']} — %${m.toStringAsFixed(0)} olgunluk',
          'color': const Color(0xFF66BB6A)
        });
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
              border:
                  Border.all(color: color, width: 2), // Kalın parlak çerçeve
              boxShadow: [
                BoxShadow(
                    color: color.withValues(alpha: 0.4),
                    blurRadius: 15,
                    spreadRadius: 2)
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
                    Text(alert['title'] as String,
                        style: GoogleFonts.outfit(
                            color: color,
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2)),
                    Text(alert['sub'] as String,
                        style:
                            const TextStyle(color: Colors.white, fontSize: 10)),
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
                const Icon(Icons.verified_rounded,
                    color: Color(0xFF00E676), size: 16),
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
                  onPressed:
                      _isRefreshingSuitability ? null : _refreshSuitability,
                  icon: _isRefreshingSuitability
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFF00E676),
                          ),
                        )
                      : const Icon(Icons.refresh,
                          color: Color(0xFF00E676), size: 16),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Önerilen Ürün: $topCrop',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600),
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
    // Matte forest-green bar; her buton kendi tematik rengiyle öne çıkar.
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF14241B), // matte forest
        borderRadius: BorderRadius.circular(22),
        border:
            Border.all(color: Colors.white.withValues(alpha: 0.06), width: 1),
        boxShadow: const [
          BoxShadow(
              color: Color(0x66000000), blurRadius: 18, offset: Offset(0, 6)),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildNavBtn(Icons.radar_rounded, 'Tarlayı Tara', _showPlantPicker,
              color: const Color(0xFF2ECC71), primary: true),
          _buildNavBtn(Icons.check_circle_outline_rounded, 'Aktivite',
              _showActivityQuickLog,
              color: const Color(0xFFF2B84B)),
          _buildNavBtn(Icons.event_note_rounded, 'Günlük', _openFarmJournal,
              color: const Color(0xFF4DB6AC)),
          _buildNavBtn(
              Icons.account_balance_wallet_rounded, 'Cüzdan', _openCostLedger,
              color: const Color(0xFFB388FF)),
          _buildNavBtn(
              Icons.checklist_rtl_rounded, 'Görevler', _showDetailModal,
              color: const Color(0xFF64B5F6)),
        ],
      ),
    );
  }

  void _showActivityQuickLog() {
    final fieldId = widget.fieldData['id']?.toString();
    if (fieldId == null || fieldId.isEmpty) {
      AppToast.show(context,
          message: 'Tarla henüz kaydedilmedi.', type: ToastType.warning);
      return;
    }
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 12,
          bottom: MediaQuery.of(ctx).padding.bottom + 16,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF14241B),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 12),
              ActivityQuickLog(
                fieldId: fieldId,
                fieldCrops: _fieldCrops,
                fieldAreaDekar:
                    (widget.fieldData['area_dekar'] as num?)?.toDouble() ?? 1.0,
              ),
            ],
          ),
        ),
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

  void _openFarmJournal() {
    final id = widget.fieldData['id']?.toString();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FarmJournalScreen(fieldId: id),
      ),
    );
  }

  Widget _buildNavBtn(IconData icon, String text, VoidCallback onTap,
      {required Color color, bool primary = false}) {
    // Primary: doygun renk dolgulu; diğerleri: matte tonlu daire + renkli ikon.
    final Color bg = primary ? color : color.withValues(alpha: 0.14);
    final Color border = primary ? color : color.withValues(alpha: 0.38);
    final Color iconColor = primary ? const Color(0xFF0D1811) : color;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: bg,
              shape: BoxShape.circle,
              border: Border.all(color: border, width: 1),
              boxShadow: primary
                  ? [
                      BoxShadow(
                        color: color.withValues(alpha: 0.35),
                        blurRadius: 14,
                        spreadRadius: -2,
                      ),
                    ]
                  : null,
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(height: 6),
          Text(
            text,
            style: GoogleFonts.outfit(
              color: primary ? color : Colors.white.withValues(alpha: 0.78),
              fontSize: 10,
              fontWeight: primary ? FontWeight.w700 : FontWeight.w500,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
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
      rain =
          ((_analysis!['total_weekly_rain'] as num?)?.toDouble() ?? 12.0) * 52;
    }
    return (ph: ph, temp: t, annualRain: rain);
  }

  void _showPlantPicker() async {
    final env = _envForSuitability();
    final month = DateTime.now().month;

    // Ağır skorlama isolate'da; UI jank olmadan döner.
    final ranked = await ref.read(cropScoringServiceProvider).rankForEnv(
          temperature: env.temp,
          soilPh: env.ph,
          weeklyRain: env.annualRain / 52.0,
          month: month,
        );

    final scored = ranked
        .where((r) => SupportedCrops.isSupported(r.crop.nameTr))
        .map((r) => {
              'plant': _turkishCropToAgriPlant(r.crop),
              'tcrop': r.crop,
              'score': r.score,
              'reasons': r.reasons,
            })
        .toList();

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

    // 3 vitrin bitki için çiftçi setup sayfası göster.
    final protocol = CropProtocols.resolveByName(plant.nameTr);
    CropConfig? selectedConfig;
    if (protocol != null && mounted) {
      final fieldId = widget.fieldData['id']?.toString() ?? '';
      final existingConfig = CropProtocolService.loadConfig(
        fieldId: fieldId,
        cropName: plant.nameTr,
      );
      selectedConfig = existingConfig;
      final config = await showModalBottomSheet<CropConfig>(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (_) => _CropSetupSheet(
          protocol: protocol,
          initialConfig: existingConfig,
        ),
      );
      if (!mounted) return;
      if (config != null) {
        selectedConfig = config;
        await CropProtocolService.saveConfig(
          fieldId: fieldId,
          cropName: plant.nameTr,
          config: config,
        );
      }
      // Kullanıcı setup sayfasını kapattıysa (config null) yine devam et.
    }

    // Mevcut ekili bölgeleri topla — yeni çizimde kalan alanı görmek için
    final existingZones = <ExistingPlantZone>[];
    for (final crop in _fieldCrops) {
      final zPoly = _parseZonePolygon(crop['zone_polygon_json']?.toString());
      if (zPoly.length >= 3) {
        existingZones.add(ExistingPlantZone(
          name: crop['name']?.toString() ?? '',
          color: _cropColor(crop),
          polygon: zPoly,
        ));
      }
    }

    if (!mounted) return;
    final zoneJson = await Navigator.of(context).push<String>(
      AnimatedRoute.slideUp(
        PlantZoneDrawingScreen(
          plantName: plant.nameTr,
          plantColor: plant.renderColor,
          fieldPolygon: polygon,
          existingZones: existingZones,
          initialTargetDekar: selectedConfig?.areaDekar,
        ),
      ),
    );

    if (zoneJson == null || !mounted) return;
    await _addCropWithZone(plant, zoneJson, config: selectedConfig);
  }

  Future<void> _addCropWithZone(
    AgriPlant plant,
    String zonePolygonJson, {
    CropConfig? config,
  }) async {
    final fieldId = widget.fieldData['id']?.toString();
    if (fieldId == null || fieldId.isEmpty) return;

    final repo = ref.read(localDataRepositoryProvider);
    final protocol = CropProtocols.resolveByName(plant.nameTr);
    final rowSpacingCm =
        config?.rowSpacingCm ?? protocol?.defaultRowSpacingCm ?? 50.0;
    final plantSpacingCm =
        config?.plantSpacingCm ?? protocol?.defaultPlantSpacingCm ?? 40.0;
    final cropId = await repo.addSingleCropToField(
      fieldId: fieldId,
      name: plant.nameTr,
      colorValue: plant.renderColor.toARGB32(),
      plantedDate:
          '${DateTime.now().day.toString().padLeft(2, '0')}.${DateTime.now().month.toString().padLeft(2, '0')}.${DateTime.now().year}',
      harvestDays: plant.daysToHarvest,
      waterIntervalDays: 7,
      rowSpacingCm: rowSpacingCm,
      plantSpacingCm: plantSpacingCm,
      zonePolygonJson: zonePolygonJson,
    );

    await repo.logActivity(
      fieldId: fieldId,
      type: ActivityType.planting,
      cropId: cropId,
      note: '${plant.nameTr} tarlaya eklendi',
      metadata: {
        'setup_version': 1,
        if (config != null) 'area_dekar': config.areaDekar,
        'row_spacing_cm': rowSpacingCm,
        'plant_spacing_cm': plantSpacingCm,
      },
    );
    await ref.read(growthEngineProvider).recompute(cropId: cropId);

    await _loadFieldCrops();
    if (!mounted) return;

    // ── 3 vitrin bitki için yetiştirme yol haritası bildirimi ──
    final resolvedProtocol = CropProtocols.resolveByName(plant.nameTr);
    if (resolvedProtocol != null) {
      await NotificationService.show(
        id: resolvedProtocol.cropKey.hashCode & 0x7fffffff,
        title:
            '${resolvedProtocol.emoji} ${resolvedProtocol.displayName} eklendi',
        body:
            '${resolvedProtocol.displayName} yetiştirmek için detaylı yönergeye Görevler\'den ulaşabilirsiniz.',
      );
      // İlk adım bildirimini de ata — son yüklenen aktivite/ekin verisiyle.
      final latestCrops = await repo.loadFieldCrops(fieldId);
      final activities = await ref
          .read(localDataRepositoryProvider)
          .watchActivityLog(fieldId: fieldId, limit: 200)
          .first;
      final addedCrop = latestCrops.firstWhere(
        (c) => c['name']?.toString() == plant.nameTr,
        orElse: () => <String, dynamic>{},
      );
      if (addedCrop.isNotEmpty) {
        await CropProtocolService.checkAndNotifyStepAdvanced(
          fieldId: fieldId,
          crop: addedCrop,
          activities: activities,
        );
      }
    }

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
      'Tahıl' ||
      'Yağlı Tohum' ||
      'Yem Bitkisi' ||
      'Bahçe Otu' ||
      'Tıbbi Bitki' =>
        PlantRenderType.stalk,
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
      case 'Tahıl':
        return const Color(0xFFF59E0B);
      case 'Baklagil':
        return const Color(0xFF84CC16);
      case 'Yağlı Tohum':
        return const Color(0xFFFCD34D);
      case 'Endüstri Bitkisi':
        return const Color(0xFFE5E7EB);
      case 'Yem Bitkisi':
        return const Color(0xFF65A30D);
      case 'Sebze':
        return const Color(0xFFEF4444);
      case 'Meyve':
        return const Color(0xFFEC4899);
      case 'Sert Kabuklu':
        return const Color(0xFF92400E);
      case 'Bahçe Otu':
        return const Color(0xFF16A34A);
      case 'Tıbbi Bitki':
        return const Color(0xFF8B5CF6);
      case 'Süs Bitkisi':
        return const Color(0xFFF472B6);
      default:
        return const Color(0xFF43A047);
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
    final protocol = CropProtocols.resolveByName(plant.nameTr);
    final cropId = await repo.addSingleCropToField(
      fieldId: fieldId,
      name: plant.nameTr,
      colorValue: plant.renderColor.toARGB32(),
      plantedDate:
          '${DateTime.now().day.toString().padLeft(2, '0')}.${DateTime.now().month.toString().padLeft(2, '0')}.${DateTime.now().year}',
      harvestDays: plant.daysToHarvest,
      waterIntervalDays: 7,
      rowSpacingCm: protocol?.defaultRowSpacingCm ?? 50.0,
      plantSpacingCm: protocol?.defaultPlantSpacingCm ?? 40.0,
      zonePolygonJson: zoneJson,
    );
    await repo.logActivity(
      fieldId: fieldId,
      type: ActivityType.planting,
      cropId: cropId,
      note: '${plant.nameTr} seçilen bölgeye eklendi',
      metadata: {
        'setup_version': 1,
        'row_spacing_cm': protocol?.defaultRowSpacingCm ?? 50.0,
        'plant_spacing_cm': protocol?.defaultPlantSpacingCm ?? 40.0,
      },
    );
    await ref.read(growthEngineProvider).recompute(cropId: cropId);

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
    final protocol = CropProtocols.resolveByName(plant.nameTr);
    final cropId = await repo.addSingleCropToField(
      fieldId: fieldId,
      name: plant.nameTr,
      colorValue: plant.renderColor.toARGB32(),
      plantedDate:
          '${DateTime.now().day.toString().padLeft(2, '0')}.${DateTime.now().month.toString().padLeft(2, '0')}.${DateTime.now().year}',
      harvestDays: plant.daysToHarvest,
      waterIntervalDays: 7,
      rowSpacingCm: protocol?.defaultRowSpacingCm ?? 50.0,
      plantSpacingCm: protocol?.defaultPlantSpacingCm ?? 40.0,
    );
    await ref.read(growthEngineProvider).recompute(cropId: cropId);

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

  bool _pointInPolygon(double lat, double lng, List<LatLng> polygon) {
    bool inside = false;
    for (int i = 0, j = polygon.length - 1; i < polygon.length; j = i++) {
      final yi = polygon[i].latitude, xi = polygon[i].longitude;
      final yj = polygon[j].latitude, xj = polygon[j].longitude;
      final intersect = ((yi > lat) != (yj > lat)) &&
          (lng <
              (xj - xi) * (lat - yi) / ((yj - yi) == 0 ? 1e-12 : (yj - yi)) +
                  xi);
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
    final fieldId = d['id']?.toString();
    final growthRows = fieldId == null || fieldId.isEmpty
        ? const <CropGrowthState>[]
        : ref.watch(fieldGrowthStatesProvider(fieldId)).valueOrNull ??
            const <CropGrowthState>[];
    final growthByCrop = {
      for (final state in growthRows) state.cropId: state,
    };

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
        final maturity = _computeMaturityPercent(
          crop,
          growthState: growthByCrop[crop['id']?.toString()],
        );
        final cropName = crop['name']?.toString() ?? '';
        // Bitkinin gerçek sıra × bitki aralığına göre (cm cinsinden) yerleşim
        final positions = plantPlacementInPolygon(
          polygon: zonePoly,
          cropName: cropName,
          rowSpacingCm: (crop['row_spacing_cm'] as num?)?.toDouble(),
          plantSpacingCm: (crop['plant_spacing_cm'] as num?)?.toDouble(),
          maxCount: 35,
          minVisualSpacingM: 3.0,
        );
        if (positions.isEmpty) {
          double cLat = 0, cLng = 0;
          for (final p in zonePoly) {
            cLat += p.latitude;
            cLng += p.longitude;
          }
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

    // Zone olmayan bitkiler için — ana tarla polygonuna ilk bitkinin aralığına göre diz
    final markers = <Marker>[];
    if (gridCrops.isNotEmpty) {
      final firstName = gridCrops.first['name']?.toString() ?? '';
      final positions = plantPlacementInPolygon(
        polygon: polygon,
        cropName: firstName,
        rowSpacingCm: (gridCrops.first['row_spacing_cm'] as num?)?.toDouble(),
        plantSpacingCm:
            (gridCrops.first['plant_spacing_cm'] as num?)?.toDouble(),
        maxCount: 30,
        minVisualSpacingM: 3.5,
      );
      positions.sort((a, b) => b.latitude.compareTo(a.latitude));

      for (int i = 0; i < positions.length; i++) {
        final crop = gridCrops[i % gridCrops.length];
        final maturity = _computeMaturityPercent(
          crop,
          growthState: growthByCrop[crop['id']?.toString()],
        );
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
                  Shadow(
                      color: const Color(0xFF00E676).withValues(alpha: 0.8),
                      blurRadius: 12),
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
        ..rotateX(
            -0.85), // Tarlayı geriye doğru 45 derece yatırır (doğru izometrik bakış)
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
    final fieldId = widget.fieldData['id']?.toString() ?? '';
    for (final crop in _fieldCrops) {
      final cropId = crop['id']?.toString();
      if (cropId != null && cropId.isNotEmpty) {
        ref.read(growthEngineProvider).recompute(cropId: cropId);
      }
    }
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _DirectivesModalContent(
        fieldId: fieldId,
        fieldData: Map<String, dynamic>.from(
          widget.fieldData as Map<dynamic, dynamic>,
        ),
        analysis: _analysis,
        fieldCrops: _fieldCrops,
        fieldAreaDekar:
            (widget.fieldData['area_dekar'] as num?)?.toDouble() ?? 1.0,
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
                    Text('Hava + toprak verisine göre uygunluk skoru',
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
              prefixIcon:
                  const Icon(Icons.search_rounded, color: Color(0xFF2E7D32)),
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
                      final int score =
                          (filtered[i]['score'] as double).round();
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
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
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
                                                padding: const EdgeInsets.only(
                                                    top: 2),
                                                child: Row(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    const Icon(
                                                        Icons
                                                            .warning_amber_rounded,
                                                        size: 12,
                                                        color: Colors.orange),
                                                    const SizedBox(width: 4),
                                                    Expanded(
                                                      child: Text(r,
                                                          style: const TextStyle(
                                                              fontSize: 11,
                                                              color: Colors
                                                                  .black87)),
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
// GÖREVLER MODALI — "BUGÜN NE YAPMALIYIM?" yönergeleri
// Kural motoru TaskDirectiveService'te; bu widget sadece render eder.
// Aktivite stream'i (watchActivityLog) sayesinde her "Suladım/Gübreledim"
// kaydı yönergeleri anında tazeler — canlı çiftçi kaynağı.
// ═══════════════════════════════════════════════════════════════════════
class _DirectivesModalContent extends ConsumerWidget {
  const _DirectivesModalContent({
    required this.fieldId,
    required this.fieldData,
    required this.analysis,
    required this.fieldCrops,
    required this.fieldAreaDekar,
  });

  final String fieldId;
  final Map<String, dynamic> fieldData;
  final Map<String, dynamic>? analysis;
  final List<Map<String, dynamic>> fieldCrops;
  final double fieldAreaDekar;

  static DateTime? _parsePlantedDate(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    final parts = raw.split('.');
    if (parts.length == 3) {
      final iso =
          '${parts[2]}-${parts[1].padLeft(2, '0')}-${parts[0].padLeft(2, '0')}';
      final dt = DateTime.tryParse(iso);
      if (dt != null) return dt;
    }
    return DateTime.tryParse(raw);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activityAsync = ref.watch(fieldActivityLogProvider(fieldId));
    final growthAsync = ref.watch(fieldGrowthStatesProvider(fieldId));
    final service = ref.watch(taskDirectiveServiceProvider);

    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: Color(0xFF0D1811),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 8),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(children: [
              const Icon(Icons.checklist_rtl_rounded,
                  color: Color(0xFF00E676), size: 22),
              const SizedBox(width: 10),
              Text('Bugün Ne Yapmalıyım?',
                  style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.white)),
              const Spacer(),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close, color: Colors.white54),
              ),
            ]),
          ),
          const Divider(color: Colors.white12, height: 20),
          Expanded(
            child: activityAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: Color(0xFF00E676)),
              ),
              error: (e, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    'Yönergeler yüklenemedi: $e',
                    style: const TextStyle(color: Colors.white70),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              data: (activities) {
                final fieldStates = ref.read(fieldStateServiceProvider).compute(
                      field: fieldData,
                      fieldCrops: fieldCrops,
                      activities: activities,
                    );
                final fieldStateMap = {
                  for (final state in fieldStates) state.cropId: state,
                };
                final growthMap = {
                  for (final state
                      in growthAsync.valueOrNull ?? const <CropGrowthState>[])
                    state.cropId: GrowthSnapshot(
                      stageKey: state.currentStageKey,
                      stageProgress: state.stageProgress,
                      accumulatedGdd: state.accumulatedGdd,
                      waterDeficitMm: state.waterDeficitMm,
                      nStressIdx: state.nStressIdx,
                      diseasePressure: state.diseasePressure,
                      yieldMultiplier: state.yieldMultiplier,
                    ),
                };
                final directives = service.generate(
                  fieldCrops: fieldCrops,
                  activities: activities,
                  dailyForecast: analysis?['daily_forecast'] as List?,
                  currentTemp: (analysis?['temp'] as num?)?.toDouble(),
                  soilMoisture:
                      (analysis?['soil_moisture'] as num?)?.toDouble(),
                  growthStates: growthMap,
                  fieldStates: fieldStateMap,
                );
                // Sezon özet kartları (her ekili 3-vitrin bitki için).
                final summaryCards = <Widget>[];
                for (final crop in fieldCrops) {
                  if (!SupportedCrops.isSupported(crop['name']?.toString())) {
                    continue;
                  }
                  final planted =
                      _parsePlantedDate(crop['planted_date']?.toString());
                  if (planted == null) continue;
                  final cropId = crop['id']?.toString();
                  final summary = computeSeasonSummary(
                    activities: activities,
                    cropId: cropId,
                    since: planted,
                  );
                  summaryCards.add(SeasonSummaryCard(
                    cropName: crop['name']?.toString() ?? 'Bitki',
                    plantedDate: planted,
                    areaDekar: fieldAreaDekar,
                    summary: summary,
                    harvestDays: (crop['harvest_days'] as num?)?.toInt(),
                    cropId: cropId,
                  ));
                }

                // 3 vitrin bitkiden ekili olanlar için yol haritası kartları.
                final roadmaps = <Widget>[];
                for (final crop in fieldCrops) {
                  final progress = CropProtocolService.computeProgress(
                    crop: crop,
                    activities: activities,
                    fieldId: fieldId,
                  );
                  if (progress != null) {
                    roadmaps.add(_CropRoadmapCard(
                      progress: progress,
                      fieldId: fieldId,
                    ));
                  }
                }

                final totalCount =
                    summaryCards.length + roadmaps.length + directives.length;
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
                  itemCount: totalCount,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) {
                    if (i < summaryCards.length) return summaryCards[i];
                    final j = i - summaryCards.length;
                    if (j < roadmaps.length) return roadmaps[j];
                    return _DirectiveCard(
                      directive: directives[j - roadmaps.length],
                      fieldId: fieldId,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _DirectiveCard extends ConsumerStatefulWidget {
  const _DirectiveCard({required this.directive, required this.fieldId});

  final FieldDirective directive;
  final String fieldId;

  @override
  ConsumerState<_DirectiveCard> createState() => _DirectiveCardState();
}

class _DirectiveCardState extends ConsumerState<_DirectiveCard> {
  bool _logging = false;

  Color get _accent {
    switch (widget.directive.urgency) {
      case 2:
        return const Color(0xFFFF5252);
      case 1:
        return const Color(0xFFFFB74D);
      default:
        return const Color(0xFF00E676);
    }
  }

  IconData get _icon {
    switch (widget.directive.kind) {
      case 'water_now':
      case 'water_soon':
        return Icons.water_drop_rounded;
      case 'rain_wait':
        return Icons.cloudy_snowing;
      case 'fertilize':
        return Icons.grass_rounded;
      case 'spray':
        return Icons.science_rounded;
      case 'harvest':
        return Icons.agriculture_rounded;
      case 'frost':
        return Icons.ac_unit_rounded;
      case 'heat':
        return Icons.wb_sunny_rounded;
      case 'empty':
        return Icons.add_circle_outline_rounded;
      default:
        return Icons.check_circle_outline_rounded;
    }
  }

  String get _urgencyLabel {
    switch (widget.directive.urgency) {
      case 2:
        return 'BUGÜN';
      case 1:
        return 'YAKINDA';
      default:
        return 'BİLGİ';
    }
  }

  Future<void> _onAction() async {
    final d = widget.directive;
    final type = d.actionType;
    if (type == null || _logging) return;
    setState(() => _logging = true);
    try {
      await ref.read(localDataRepositoryProvider).logActivity(
        fieldId: widget.fieldId,
        type: type,
        cropId: d.cropId,
        quantity: d.suggestedQuantity,
        quantityUnit: d.quantityUnit,
        recommendedQuantity: d.recommendedQuantity ?? d.suggestedQuantity,
        metadata: {
          if (d.areaDekar != null) 'area_dekar': d.areaDekar,
          if (d.plantCount != null) 'plant_count': d.plantCount,
          if (d.steps.isNotEmpty) 'directive_steps': d.steps,
          if (d.sourceRefs.isNotEmpty) 'source_refs': d.sourceRefs,
        },
      );
      if (d.cropId != null && d.cropId!.isNotEmpty) {
        await ref.read(growthEngineProvider).recompute(cropId: d.cropId!);
      }
      if (!mounted) return;
      AppToast.show(
        context,
        message: '${ActivityType.actionLabel(type)} kaydedildi',
        type: ToastType.success,
      );
      // Stream provider otomatik tazelenecek; yönergeler anında güncellenir.
    } catch (e) {
      if (!mounted) return;
      AppToast.show(
        context,
        message: 'Kayıt başarısız: $e',
        type: ToastType.error,
      );
    } finally {
      if (mounted) setState(() => _logging = false);
    }
  }

  String _shortSource(String source) {
    final s = source.toLowerCase();
    if (s.contains('tagem')) return 'TAGEM';
    if (s.contains('tarım ve orman') || s.contains('tarim ve orman')) {
      return 'Tarım ve Orman';
    }
    if (s.contains('trakya')) return 'Trakya TAE';
    if (s.contains('yalova')) return 'Yalova Bahçe';
    if (s.contains('bakan')) return 'Bakanlık';
    return source.length <= 22 ? source : '${source.substring(0, 22)}...';
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.directive;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _accent.withValues(alpha: 0.45), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _accent.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                ),
                child: Icon(_icon, color: _accent, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: _accent.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        _urgencyLabel,
                        style: TextStyle(
                          color: _accent,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      d.headline,
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            d.reason,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
              height: 1.45,
            ),
          ),
          if (d.steps.isNotEmpty) ...[
            const SizedBox(height: 10),
            ...d.steps.take(4).map(
                  (step) => Padding(
                    padding: const EdgeInsets.only(bottom: 5),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.check_circle_rounded,
                            color: Color(0xFF00E676), size: 14),
                        const SizedBox(width: 7),
                        Expanded(
                          child: Text(
                            step,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                              height: 1.35,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
          ],
          if (d.sourceRefs.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: d.sourceRefs.take(3).map((source) {
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00E676).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFF00E676).withValues(alpha: 0.35),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.verified_rounded,
                          color: Color(0xFF00E676), size: 12),
                      const SizedBox(width: 4),
                      Text(
                        _shortSource(source),
                        style: const TextStyle(
                          color: Color(0xFFB9F6CA),
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
          if (d.actionType != null) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _logging ? null : _onAction,
                icon: _logging
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.check_rounded, size: 18),
                label: Text(
                  _logging
                      ? 'Kaydediliyor...'
                      : '${ActivityType.actionLabel(d.actionType!)} — Tamamlandı',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _accent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// YETİŞTİRME YOL HARİTASI KARTI
// 3 vitrin bitki için tüm adımları progress bar + checklist olarak gösterir.
// Aktivite log'u her güncellendiğinde provider tazelenir → bu widget yeniden
// build olur → tamamlanan adımlar otomatik ✓ alır.
// ═══════════════════════════════════════════════════════════════════════
// ═══════════════════════════════════════════════════════════════════════
// YETİŞTİRME YOL HARİTASI KARTI — config-aware zengin UI
// ═══════════════════════════════════════════════════════════════════════
class _CropRoadmapCard extends StatefulWidget {
  const _CropRoadmapCard({required this.progress, required this.fieldId});

  final CropProtocolProgress progress;
  final String fieldId;

  @override
  State<_CropRoadmapCard> createState() => _CropRoadmapCardState();
}

class _CropRoadmapCardState extends State<_CropRoadmapCard> {
  bool _expanded = true;
  int? _expandedStep; // adım detayı açık mı (order değeri)

  static const _accent = Color(0xFF00E676);
  static const _warn = Color(0xFFFF5252);
  static const _tip = Color(0xFF00E676);
  static const _mistake = Color(0xFFFFB74D);
  static const _info = Color(0xFF40C4FF);

  String _formatArea(double area) => area == area.roundToDouble()
      ? '${area.round()}'
      : area.toStringAsFixed(1);

  // Miktarı alana göre ölçekle ve okunabilir göster
  String _scaleToArea(String spec, double area) {
    if (area == 1) return spec;
    // "X kg/da" → "X*area kg"
    return spec.replaceAllMapped(
      RegExp(r'(\d+(?:\.\d+)?)\s*(?:kg|mL|L|g|adet)\/da'),
      (m) {
        final val = double.tryParse(m.group(1) ?? '');
        if (val == null) return m.group(0)!;
        final scaled = val * area;
        final unit = m
            .group(0)!
            .replaceAll(m.group(1)!, '')
            .replaceAll('/da', '')
            .trim();
        final display = scaled == scaled.roundToDouble()
            ? '${scaled.round()}'
            : scaled.toStringAsFixed(1);
        return '$display $unit (${_formatArea(area)} da için)';
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.progress;
    final cfg = p.config;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _accent.withValues(alpha: 0.15),
            Colors.white.withValues(alpha: 0.03),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _accent.withValues(alpha: 0.4), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Başlık + progress ──
          InkWell(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Text(p.protocol.emoji,
                        style: const TextStyle(fontSize: 28)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${p.protocol.displayName} — Yetiştirme Rehberi',
                            style: GoogleFonts.outfit(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: Colors.white),
                          ),
                          const SizedBox(height: 2),
                          if (cfg != null)
                            Wrap(
                              spacing: 6,
                              children: [
                                _cfgChip(
                                    cfg.soilType.emoji, cfg.soilType.label),
                                _cfgChip(
                                    const Icon(Icons.water_drop_rounded,
                                            size: 11, color: _info)
                                        .toString(),
                                    cfg.irrigationMethod.label,
                                    isIcon: true,
                                    icon: cfg.irrigationMethod.icon),
                                _cfgChip(
                                    '📐', '${_formatArea(cfg.areaDekar)} da'),
                              ],
                            )
                          else
                            const Text(
                              'Kurulum yapılmadı — tarla detayı giriniz',
                              style: TextStyle(
                                  color: Colors.white54, fontSize: 11),
                            ),
                        ],
                      ),
                    ),
                    Icon(
                      _expanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      color: Colors.white54,
                    ),
                  ]),
                  const SizedBox(height: 10),
                  // Progress bar + sayaç
                  Row(children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: p.ratio,
                          minHeight: 7,
                          backgroundColor: Colors.white12,
                          valueColor: const AlwaysStoppedAnimation(_accent),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      p.isFinished
                          ? '✓ Tamamlandı'
                          : '${p.completedCount}/${p.totalCount}',
                      style: GoogleFonts.outfit(
                        color: _accent,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ]),
                ],
              ),
            ),
          ),

          if (_expanded) ...[
            const Divider(color: Colors.white12, height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
              child: Column(
                children: p.protocol.steps.map((step) {
                  final isDone = p.completedOrders.contains(step.order);
                  final isActive = p.activeStep?.order == step.order;
                  final isOpen = isActive || _expandedStep == step.order;
                  return _RoadmapStepTile(
                    step: step,
                    isCompleted: isDone,
                    isActive: isActive,
                    isOpen: isOpen,
                    config: cfg,
                    area: cfg?.areaDekar ?? 1,
                    accent: _accent,
                    warnColor: _warn,
                    tipColor: _tip,
                    mistakeColor: _mistake,
                    infoColor: _info,
                    scaleToArea: _scaleToArea,
                    onTap: () {
                      if (isActive) return;
                      setState(() {
                        _expandedStep =
                            _expandedStep == step.order ? null : step.order;
                      });
                    },
                  );
                }).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _cfgChip(String emoji, String label,
          {bool isIcon = false, IconData? icon}) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (isIcon && icon != null)
            Icon(icon, size: 10, color: _info)
          else
            Text(emoji, style: const TextStyle(fontSize: 10)),
          const SizedBox(width: 4),
          Text(label,
              style: const TextStyle(color: Colors.white70, fontSize: 10)),
        ]),
      );
}

class _RoadmapStepTile extends StatelessWidget {
  const _RoadmapStepTile({
    required this.step,
    required this.isCompleted,
    required this.isActive,
    required this.isOpen,
    required this.config,
    required this.area,
    required this.accent,
    required this.warnColor,
    required this.tipColor,
    required this.mistakeColor,
    required this.infoColor,
    required this.scaleToArea,
    required this.onTap,
  });

  final ProtocolStep step;
  final bool isCompleted;
  final bool isActive;
  final bool isOpen;
  final CropConfig? config;
  final double area;
  final Color accent;
  final Color warnColor;
  final Color tipColor;
  final Color mistakeColor;
  final Color infoColor;
  final String Function(String, double) scaleToArea;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final icon = isCompleted
        ? Icons.check_circle_rounded
        : (isActive
            ? Icons.play_circle_fill_rounded
            : Icons.radio_button_unchecked_rounded);
    final iconColor = isCompleted
        ? accent
        : (isActive ? const Color(0xFFFFB74D) : Colors.white24);
    final titleColor = isCompleted
        ? Colors.white54
        : (isActive ? Colors.white : Colors.white70);

    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Adım başlık satırı ──
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 7),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(icon, color: iconColor, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Row(children: [
                      // Gün badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isActive
                              ? const Color(0xFFFFB74D).withValues(alpha: 0.2)
                              : Colors.white.withValues(alpha: 0.07),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(
                          'G${step.dayOffset}',
                          style: TextStyle(
                            color: isActive
                                ? const Color(0xFFFFB74D)
                                : Colors.white54,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(step.stageEmoji,
                          style: const TextStyle(fontSize: 15)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          step.title,
                          style: TextStyle(
                            color: titleColor,
                            fontSize: 13,
                            fontWeight: isActive || isOpen
                                ? FontWeight.w700
                                : FontWeight.w500,
                            decoration:
                                isCompleted ? TextDecoration.lineThrough : null,
                            decorationColor: Colors.white30,
                          ),
                        ),
                      ),
                    ]),
                  ),
                  if (!isCompleted && !isActive)
                    Icon(
                      isOpen
                          ? Icons.expand_less_rounded
                          : Icons.expand_more_rounded,
                      size: 16,
                      color: Colors.white30,
                    ),
                ],
              ),
            ),

            // ── Detay paneli (aktif + tıklanmış) ──
            if (isOpen && !isCompleted) ...[
              Container(
                margin: const EdgeInsets.only(left: 32, bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isActive
                        ? const Color(0xFFFFB74D).withValues(alpha: 0.3)
                        : Colors.white12,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Ana açıklama
                    Text(step.description,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          height: 1.5,
                        )),

                    // Toprak tipi notu
                    if (config != null &&
                        step.soilNote(config!.soilType) != null) ...[
                      const SizedBox(height: 10),
                      _infoBox(
                        icon: Icons.landscape_rounded,
                        color: const Color(0xFF8D6E63),
                        label:
                            '${config!.soilType.emoji} ${config!.soilType.label} Toprağı',
                        body: step.soilNote(config!.soilType)!,
                      ),
                    ],

                    // Sulama yöntemi notu
                    if (config != null &&
                        step.irrigationNote(config!.irrigationMethod) !=
                            null) ...[
                      const SizedBox(height: 8),
                      _infoBox(
                        icon: config!.irrigationMethod.icon,
                        color: infoColor,
                        label: config!.irrigationMethod.label,
                        body: step.irrigationNote(config!.irrigationMethod)!,
                      ),
                    ],

                    // Gübre spesifikasyonu
                    if (step.fertilizerSpec != null) ...[
                      const SizedBox(height: 8),
                      _infoBox(
                        icon: Icons.grass_rounded,
                        color: const Color(0xFF81C784),
                        label: 'Gübre',
                        body: config != null && area > 0
                            ? scaleToArea(step.fertilizerSpec!, area)
                            : step.fertilizerSpec!,
                      ),
                    ],

                    // İlaç spesifikasyonu
                    if (step.pesticideSpec != null) ...[
                      const SizedBox(height: 8),
                      _infoBox(
                        icon: Icons.science_rounded,
                        color: const Color(0xFFCE93D8),
                        label: 'İlaçlama',
                        body: step.pesticideSpec!,
                      ),
                    ],

                    // Su miktarı
                    if (step.waterSpec != null) ...[
                      const SizedBox(height: 8),
                      _infoBox(
                        icon: Icons.water_drop_rounded,
                        color: infoColor,
                        label: 'Su Miktarı',
                        body: step.waterSpec!,
                      ),
                    ],

                    // Maliyet
                    if (step.estimatedCostPerDekar != null &&
                        step.estimatedCostPerDekar! > 0) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 7),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFD54F).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: const Color(0xFFFFD54F)
                                  .withValues(alpha: 0.3)),
                        ),
                        child: Row(children: [
                          const Text('₺',
                              style: TextStyle(
                                color: Color(0xFFFFD54F),
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                              )),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              config != null && area > 0
                                  ? 'Bu adım tahmini maliyet: '
                                      '~₺${(step.estimatedCostPerDekar! * area).round()} '
                                      '(${_formatArea(area)} da × ₺${step.estimatedCostPerDekar!.round()}/da)'
                                  : '~₺${step.estimatedCostPerDekar!.round()}/da',
                              style: const TextStyle(
                                color: Color(0xFFFFD54F),
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ]),
                      ),
                    ],

                    // Kritik uyarı
                    if (step.criticalWarning != null) ...[
                      const SizedBox(height: 8),
                      _alertBox(
                        icon: Icons.warning_rounded,
                        color: warnColor,
                        label: 'KRİTİK UYARI',
                        body: step.criticalWarning!,
                      ),
                    ],

                    // Çiftçi ipucu
                    if (step.farmerTip != null) ...[
                      const SizedBox(height: 8),
                      _alertBox(
                        icon: Icons.lightbulb_rounded,
                        color: tipColor,
                        label: 'Çiftçi İpucu',
                        body: step.farmerTip!,
                      ),
                    ],

                    // Sık yapılan hata
                    if (step.commonMistake != null) ...[
                      const SizedBox(height: 8),
                      _alertBox(
                        icon: Icons.cancel_rounded,
                        color: mistakeColor,
                        label: 'Sık Yapılan Hata',
                        body: step.commonMistake!,
                      ),
                    ],
                  ],
                ),
              ),
            ],

            if (!isCompleted && isOpen)
              Divider(color: Colors.white.withValues(alpha: 0.06), height: 1),
          ],
        ),
      ),
    );
  }

  String _formatArea(double area) => area == area.roundToDouble()
      ? '${area.round()}'
      : area.toStringAsFixed(1);

  Widget _infoBox({
    required IconData icon,
    required Color color,
    required String label,
    required String body,
  }) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(icon, size: 13, color: color),
              const SizedBox(width: 5),
              Text(label,
                  style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  )),
            ]),
            const SizedBox(height: 5),
            Text(body,
                style: TextStyle(
                    color: color.withValues(alpha: 0.85),
                    fontSize: 11,
                    height: 1.5)),
          ],
        ),
      );

  Widget _alertBox({
    required IconData icon,
    required Color color,
    required String label,
    required String body,
  }) =>
      Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.35), width: 1.2),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: TextStyle(
                        color: color,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.3,
                      )),
                  const SizedBox(height: 3),
                  Text(body,
                      style: TextStyle(
                        color: color.withValues(alpha: 0.9),
                        fontSize: 11,
                        height: 1.5,
                      )),
                ],
              ),
            ),
          ],
        ),
      );
}

// ═══════════════════════════════════════════════════════════════════════
// ÇİFTÇİ KURULUM SAYFASI — bitki seçimi ile bölge çizimi arasında açılır.
// Toprak türü, sulama yöntemi, alan ve sıra/bitki aralığını alır;
// CropConfig nesnesi döndürür.
// ═══════════════════════════════════════════════════════════════════════
class _CropSetupSheet extends StatefulWidget {
  const _CropSetupSheet({required this.protocol, this.initialConfig});

  final CropProtocol protocol;
  final CropConfig? initialConfig;

  @override
  State<_CropSetupSheet> createState() => _CropSetupSheetState();
}

class _CropSetupSheetState extends State<_CropSetupSheet> {
  late SoilType _soil;
  late IrrigationMethod _irrigation;
  late final TextEditingController _areaCtrl;
  late final TextEditingController _rowCtrl;
  late final TextEditingController _plantCtrl;

  static const _bg = Color(0xFF0D1811);
  static const _accent = Color(0xFF00E676);
  static const _card = Color(0xFF152018);

  @override
  void initState() {
    super.initState();
    final cfg = widget.initialConfig;
    _soil = cfg?.soilType ?? SoilType.loamy;
    _irrigation = cfg?.irrigationMethod ?? IrrigationMethod.furrow;
    _areaCtrl =
        TextEditingController(text: (cfg?.areaDekar ?? 10).toStringAsFixed(0));
    _rowCtrl = TextEditingController(
        text: (cfg?.rowSpacingCm ?? widget.protocol.defaultRowSpacingCm)
            .toStringAsFixed(0));
    _plantCtrl = TextEditingController(
        text: (cfg?.plantSpacingCm ?? widget.protocol.defaultPlantSpacingCm)
            .toStringAsFixed(0));
  }

  @override
  void dispose() {
    _areaCtrl.dispose();
    _rowCtrl.dispose();
    _plantCtrl.dispose();
    super.dispose();
  }

  void _confirm() {
    final area = double.tryParse(_areaCtrl.text.trim()) ?? 10.0;
    final row = double.tryParse(_rowCtrl.text.trim()) ??
        widget.protocol.defaultRowSpacingCm;
    final plant = double.tryParse(_plantCtrl.text.trim()) ??
        widget.protocol.defaultPlantSpacingCm;
    Navigator.pop(
      context,
      CropConfig(
        soilType: _soil,
        irrigationMethod: _irrigation,
        areaDekar: area.clamp(0.1, 10000),
        rowSpacingCm: row.clamp(20, 200),
        plantSpacingCm: plant.clamp(5, 200),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        left: 20,
        right: 20,
        top: 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Tutamaç ──
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ── Başlık ──
            Row(children: [
              Text(widget.protocol.emoji, style: const TextStyle(fontSize: 30)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${widget.protocol.displayName} Tarlası Kurulumu',
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Bilgilerini gir — rehber sana özel hesaplansın',
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ]),
            const SizedBox(height: 20),

            // ── Toprak Türü ──
            _sectionLabel('🌍 Toprak Türü'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: SoilType.values.map((s) {
                final selected = _soil == s;
                return GestureDetector(
                  onTap: () => setState(() => _soil = s),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: selected ? _accent.withValues(alpha: 0.18) : _card,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: selected ? _accent : Colors.white12,
                        width: selected ? 1.5 : 1,
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(s.emoji, style: const TextStyle(fontSize: 22)),
                        const SizedBox(height: 4),
                        Text(s.label,
                            style: TextStyle(
                              color: selected ? _accent : Colors.white70,
                              fontSize: 12,
                              fontWeight: selected
                                  ? FontWeight.w700
                                  : FontWeight.normal,
                            )),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            // Seçilen toprak tipi açıklaması
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                _soil.description,
                style: const TextStyle(
                    color: Colors.white54, fontSize: 11, height: 1.4),
              ),
            ),
            const SizedBox(height: 20),

            // ── Sulama Yöntemi ──
            _sectionLabel('💧 Sulama Yöntemi'),
            const SizedBox(height: 8),
            ...IrrigationMethod.values.map((m) {
              final selected = _irrigation == m;
              return GestureDetector(
                onTap: () => setState(() => _irrigation = m),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  margin: const EdgeInsets.only(bottom: 8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: selected ? _accent.withValues(alpha: 0.15) : _card,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: selected ? _accent : Colors.white12,
                      width: selected ? 1.5 : 1,
                    ),
                  ),
                  child: Row(children: [
                    Icon(m.icon,
                        color: selected ? _accent : Colors.white38, size: 22),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(m.label,
                              style: TextStyle(
                                color: selected ? _accent : Colors.white,
                                fontSize: 14,
                                fontWeight: selected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                              )),
                          Text(m.description,
                              style: const TextStyle(
                                  color: Colors.white54, fontSize: 11)),
                        ],
                      ),
                    ),
                    if (selected)
                      const Icon(Icons.check_circle_rounded,
                          color: _accent, size: 20),
                  ]),
                ),
              );
            }),
            const SizedBox(height: 20),

            // ── Tarla Alanı ──
            _sectionLabel('📐 Tarla Alanı'),
            const SizedBox(height: 8),
            _inputField(
              controller: _areaCtrl,
              label: 'Dekar',
              hint: 'ör. 10',
              suffix: 'da',
            ),
            const SizedBox(height: 16),

            // ── Ekim Aralıkları ──
            _sectionLabel('📏 Ekim Aralıkları'),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(
                child: _inputField(
                  controller: _rowCtrl,
                  label: 'Sıra arası',
                  hint: widget.protocol.defaultRowSpacingCm.toStringAsFixed(0),
                  suffix: 'cm',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _inputField(
                  controller: _plantCtrl,
                  label: 'Bitki arası',
                  hint:
                      widget.protocol.defaultPlantSpacingCm.toStringAsFixed(0),
                  suffix: 'cm',
                ),
              ),
            ]),

            // ── Ekme mevsimi ve bölge ipucu ──
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _accent.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _accent.withValues(alpha: 0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    const Icon(Icons.calendar_today_rounded,
                        color: _accent, size: 14),
                    const SizedBox(width: 6),
                    Text(
                      'Ekim Zamanı (Türkiye)',
                      style: GoogleFonts.outfit(
                          color: _accent,
                          fontSize: 12,
                          fontWeight: FontWeight.w700),
                    ),
                  ]),
                  const SizedBox(height: 4),
                  Text(widget.protocol.sowingSeasonTR,
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 11, height: 1.3)),
                  const SizedBox(height: 6),
                  Row(children: [
                    const Icon(Icons.location_on_rounded,
                        color: _accent, size: 14),
                    const SizedBox(width: 6),
                    Text(
                      'İdeal Bölgeler',
                      style: GoogleFonts.outfit(
                          color: _accent,
                          fontSize: 12,
                          fontWeight: FontWeight.w700),
                    ),
                  ]),
                  const SizedBox(height: 4),
                  Text(widget.protocol.idealRegionsTR,
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 11, height: 1.3)),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── Onayla butonu ──
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _confirm,
                icon: const Icon(Icons.check_rounded, size: 20),
                label: Text(
                  'Kurulumu Tamamla ve Devam Et',
                  style: GoogleFonts.outfit(
                      fontSize: 15, fontWeight: FontWeight.w700),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _accent,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) => Text(
        text,
        style: GoogleFonts.outfit(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
      );

  Widget _inputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required String suffix,
  }) =>
      TextField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        style: const TextStyle(color: Colors.white, fontSize: 15),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white54, fontSize: 13),
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.white24),
          suffixText: suffix,
          suffixStyle: const TextStyle(color: Colors.white54),
          filled: true,
          fillColor: const Color(0xFF152018),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Colors.white12),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Colors.white12),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: _accent, width: 1.5),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
      );
}
