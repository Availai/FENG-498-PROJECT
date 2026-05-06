import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import '../services/agri_service.dart';
import 'crop_daily_plan_screen.dart';
import '../services/app_providers.dart';
import '../services/crop_placement.dart';
import '../services/crop_protocol_service.dart';
import '../services/crop_schedule_seeder.dart';
import '../services/growth_engine.dart';
import '../services/notification_service.dart';
import '../services/task_directive_service.dart';
import '../data/activity_types.dart';
import '../data/app_database.dart';
import '../data/crop_protocols.dart';
import '../data/supported_crops.dart';
import '../data/turkiye_crop_guides.dart';
import '../data/verified_agri_database.dart';
import '../data/turkish_crops_repository.dart';
import '../widgets/activity_quick_log.dart';
import '../widgets/contextual_tip.dart';
import '../widgets/floating_toast.dart';
import '../widgets/glass_panel.dart';
import '../widgets/season_summary_card.dart';
import '../widgets/help_panel.dart';
import '../widgets/zone_drawing_toolbar.dart';
import '../widgets/crop_zone_tooltip.dart';
import '../widgets/crop_render_factory.dart';
import '../widgets/disease_picker_sheet.dart';
import '../widgets/disease_advice_sheet.dart';
import '../data/disease_types.dart';
import 'cost_ledger_screen.dart';
import 'disease_capture_screen.dart';
import 'farm_journal_screen.dart';
import 'field_quick_guide_sheet.dart';
import 'plant_zone_drawing_screen.dart';
import 'turkish_crops_search_screen.dart';
import '../widgets/animated_route.dart';
import '../theme/app_theme.dart';

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
  bool _fieldCropsLoaded = false;
  bool _isLoading = true;
  bool _isRefreshingSuitability = false;
  String? _error;

  // ═══ Bölge çizme modu state ═══
  bool _isZoneDrawingMode = false;
  List<LatLng> _zoneDrawingPoints = [];
  AgriPlant? _pendingPlant;
  Map<String, dynamic>? _selectedCropForTooltip;
  String? _hoveredPlantMarkerKey;
  String? _selectedPlantMarkerKey;
  bool _isPlantMultiSelectMode = false;
  final Map<String, _PlantDeleteTarget> _multiSelectedPlantTargets = {};
  static const String _removedPlantStatus = 'removed';
  // Görsel marker tavanı — agronomik gerçek bitki sayısından bağımsız.
  // Eski değerler (160 zone + 120 grid + 1.25 m aralık) tarlada 280+
  // animasyonlu widget üretiyordu; bu hem performans (kasma) hem de
  // "çok sık görünme" şikayetinin temel nedeniydi. Yarıya indirildi ve
  // minimum görsel mesafe 3 m'ye çekildi.
  static const int _maxZonePlantMarkers = 64;
  static const int _maxGridPlantMarkers = 64;
  static const double _minCropMarkerSpacingM = 3.0;

  // ═══ Tekil bitki yerleştirme modu state ═══
  bool _isPlacingSinglePlantMode = false;

  late AnimationController _animCtrl;
  late Animation<double> _uiFadeAnim;
  late Animation<Offset> _uiSlideAnim;

  // Hasat halosu animasyonu
  late AnimationController _harvestPulseCtrl;

  final MapController _mapController = MapController();
  double _fieldViewAngleDegrees = 0.0;

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
    setState(() {
      _fieldCrops = crops;
      _fieldCropsLoaded = true;
    });
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
      final d = widget.fieldData as Map<dynamic, dynamic>;
      final latitude = _readFieldDouble(d, const ['latitude', 'lat']);
      final longitude = _readFieldDouble(d, const ['longitude', 'lng', 'lon']);
      if (latitude == null || longitude == null) {
        if (!mounted) return;
        setState(() {
          _error = 'Tarla konumu bulunamadı; analiz hazırlanamadı.';
          _isLoading = false;
        });
        return;
      }

      final areaDekar =
          _readFieldDouble(d, const ['area_dekar', 'areaDekar']) ?? 1.0;
      final fieldName = d['name']?.toString() ?? 'Tarla';
      // Sıkı timeout: servis yerel fallback üretse de UI sonsuza kadar beklemesin.
      final result = await AgriService.getFieldAnalysis(
        latitude,
        longitude,
        fieldName,
        areaDekar,
      ).timeout(
        const Duration(seconds: 14),
        onTimeout: () => {'success': false, 'error': 'Analiz zaman aşımı.'},
      );
      if (result['success'] == true) {
        await _persistSuitabilityReport(result);
      }
      if (mounted) {
        setState(() {
          if (result['success'] == true) {
            _analysis = result;
          } else {
            _error = result['error']?.toString() ?? 'Bilinmeyen hata';
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Analiz yüklenemedi (çevrimdışı modu). '
              'Hava ve toprak verisi alınamadı: $e';
          _isLoading = false;
        });
      }
    }
  }

  double? _readFieldDouble(Map<dynamic, dynamic> data, List<String> keys) {
    for (final key in keys) {
      final value = data[key];
      if (value is num) return value.toDouble();
      if (value is String) {
        final parsed = double.tryParse(value.replaceAll(',', '.'));
        if (parsed != null) return parsed;
      }
    }
    return null;
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
              fieldName: widget.fieldData['name']?.toString(),
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
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFF00E676),
              ),
              child:
                  const Icon(Icons.eco_rounded, color: Colors.black, size: 16),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                widget.fieldData['name']?.toString() ?? 'Tarla Haritası',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline_rounded, color: Colors.white70),
            tooltip: 'Yardım',
            onPressed: () => HelpPanel.show(context, HelpContent.fieldDetail),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          // 1. Gerçek tarla haritası — yalnızca seçilen polygon'a kilitli
          Positioned.fill(child: _build3DFieldMap(d)),

          if (_isPlantMultiSelectMode)
            Positioned(
              left: 12,
              right: 12,
              top: MediaQuery.of(context).padding.top + 68,
              child: _buildPlantMultiSelectBar(),
            ),

          if (!_isPlantMultiSelectMode &&
              !_isZoneDrawingMode &&
              !_isPlacingSinglePlantMode &&
              _fieldCropsLoaded &&
              _fieldCrops.isEmpty &&
              !_isLoading &&
              _error == null)
            Positioned(
              left: 16,
              right: 16,
              top: MediaQuery.of(context).padding.top + 68,
              child: ActionTipCard(
                id: 'field_detail_first_crop_tip',
                icon: Icons.add_location_alt_rounded,
                color: AppColors.emerald,
                title: 'Bu tarlaya ürün ekleyin',
                message:
                    'Alt bardaki "Ekle" düğmesiyle ürünü seçin ve ekim bölgesini tarlanın üstüne çizin. Kayıtlar sonra rehber, takvim ve sulama planında görünür.',
                actionLabel: 'Ekle',
                onAction: _showPlantPicker,
                dark: true,
                compact: true,
              ),
            ),

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

          // 4d. Alert badges (sol taraf, harita üstü) — analiz hazırsa.
          if (_analysis != null && !_isZoneDrawingMode)
            Positioned(
              left: 12,
              top: MediaQuery.of(context).size.height * 0.15,
              child: FadeTransition(
                opacity: _uiFadeAnim,
                child: _buildAlertBadges(),
              ),
            ),

          // 5. Bottom System Nav — analiz hazır olmasa da göster.
          // Bu menü statik navigasyon; analize bağlı değil.
          if (!_isZoneDrawingMode)
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
              bottom: MediaQuery.of(context).padding.bottom + 158,
              child: ActionTipCard(
                icon: _zoneDrawingPoints.length >= 3
                    ? Icons.check_circle_outline_rounded
                    : Icons.gesture_rounded,
                color: _pendingPlant?.renderColor ?? AppColors.emerald,
                title: _zoneDrawingPoints.length >= 3
                    ? '${_zoneDrawingPoints.length} köşe hazır'
                    : 'Ekim bölgesini çizin',
                message: _zoneDrawingPoints.length >= 3
                    ? 'Tamamla dediğinizde bu bölge ürüne bağlanır; takvim, sulama ve rehber kayıtları buradan hesaplanır.'
                    : 'Haritada ürünün ekileceği alanın köşelerine dokunun. En az 3 köşe seçince tamamlayabilirsiniz.',
                actionLabel: _zoneDrawingPoints.length >= 3 ? 'Tamamla' : null,
                onAction: _zoneDrawingPoints.length >= 3
                    ? () {
                        _completeZoneDrawing();
                      }
                    : null,
                dark: true,
                compact: true,
                dismissible: false,
              ),
            ),

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

          // 5c. Bottom — tekil bitki yerleştirme modu banner'ı + iptal
          if (_isPlacingSinglePlantMode)
            Positioned(
              left: 16,
              right: 16,
              bottom: MediaQuery.of(context).padding.bottom + 20,
              child: ActionTipCard(
                icon: Icons.eco_rounded,
                color: AppColors.emerald,
                title: 'Tekil bitki yerleştirme',
                message:
                    'Tarlanın içinde boş bir noktaya dokunun. Eklenen bitki marker olarak görünür; sağlık durumunu daha sonra marker menüsünden değiştirebilirsiniz.',
                actionLabel: 'İptal',
                onAction: () =>
                    setState(() => _isPlacingSinglePlantMode = false),
                dark: true,
                compact: true,
                dismissible: false,
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

          // Analiz yükleniyorken küçük, blok etmeyen pill göstergesi.
          if (_isLoading)
            Positioned(
              top: MediaQuery.of(context).padding.top + 60,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(20),
                    border:
                        Border.all(color: Colors.white.withValues(alpha: 0.15)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFF00E676),
                        ),
                      ),
                      SizedBox(width: 10),
                      Text(
                        'Analiz hazırlanıyor...',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          if (_error != null && !_isZoneDrawingMode)
            Positioned(
              top: MediaQuery.of(context).padding.top + 60,
              left: 16,
              right: 16,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.red.shade900.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.red.shade400),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded,
                        color: Colors.white, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _error!,
                        style:
                            const TextStyle(color: Colors.white, fontSize: 12),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    TextButton(
                      onPressed: _loadAnalysis,
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white,
                        minimumSize: const Size(0, 32),
                      ),
                      child: const Text('Tekrar Dene'),
                    ),
                  ],
                ),
              ),
            ),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderDark.withValues(alpha: 0.8)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x26000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildNavBtn(
              Icons.add_location_alt_rounded,
              'Ekle',
              _showPlantPicker,
              color: AppColors.emerald,
              primary: true,
              onLongPress: _showPlacementMenu,
            ),
          ),
          Expanded(
            child: _buildNavBtn(
              Icons.check_circle_outline_rounded,
              'Kayıt',
              _showActivityQuickLog,
              color: AppColors.warning,
            ),
          ),
          Expanded(
            child: _buildNavBtn(
              Icons.lightbulb_rounded,
              'Rehber',
              _showDetailModal,
              color: AppColors.info,
            ),
          ),
          Expanded(
            child: _buildNavBtn(
              Icons.more_horiz_rounded,
              'Diğer',
              _showFieldMoreActions,
              color: AppColors.soil,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlantMultiSelectBar() {
    final count = _multiSelectedPlantTargets.length;
    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF14241B).withValues(alpha: 0.94),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.emerald, width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.playlist_add_check_rounded,
                color: AppColors.emerald, size: 22),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '$count bitki seçildi',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            TextButton(
              onPressed: _clearPlantMultiSelection,
              child: const Text('İptal'),
            ),
            const SizedBox(width: 4),
            FilledButton.icon(
              onPressed: count == 0 ? null : _bulkSetHealth,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.emeraldDark,
                foregroundColor: Colors.white,
                visualDensity: VisualDensity.compact,
              ),
              icon: const Icon(Icons.healing_rounded, size: 18),
              label: const Text('Sağlık'),
            ),
            const SizedBox(width: 6),
            FilledButton.icon(
              onPressed: count == 0 ? null : _deleteSelectedPlants,
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red.shade600,
                foregroundColor: Colors.white,
                visualDensity: VisualDensity.compact,
              ),
              icon: const Icon(Icons.delete_outline_rounded, size: 18),
              label: const Text('Sil'),
            ),
          ],
        ),
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
          areaDekar: (d['area_dekar'] as num?)?.toDouble(),
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

  void _showFieldMoreActions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: AppColors.borderDark,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading:
                    const Icon(Icons.event_note_rounded, color: AppColors.info),
                title: const Text('Tarla Günlüğü'),
                subtitle: const Text('Sulama, gübreleme ve hasat geçmişi'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.pop(ctx);
                  _openFarmJournal();
                },
              ),
              const Divider(),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.account_balance_wallet_rounded,
                    color: AppColors.soil),
                title: const Text('ÇKS Cüzdanı'),
                subtitle: const Text('Maliyet, satış ve kâr takibi'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.pop(ctx);
                  _openCostLedger();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavBtn(IconData icon, String text, VoidCallback onTap,
      {required Color color, bool primary = false, VoidCallback? onLongPress}) {
    final Color bg = primary ? color : color.withValues(alpha: 0.14);
    final Color border = primary ? color : color.withValues(alpha: 0.38);
    final Color iconColor = primary ? Colors.white : color;
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      behavior: HitTestBehavior.opaque,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 58),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: bg,
                shape: BoxShape.circle,
                border: Border.all(color: border, width: 1),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(height: 5),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                text,
                maxLines: 1,
                style: GoogleFonts.outfit(
                  color: primary ? color : AppColors.textSecondary,
                  fontSize: 11,
                  fontWeight: primary ? FontWeight.w800 : FontWeight.w600,
                  letterSpacing: 0,
                ),
              ),
            ),
          ],
        ),
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
      final fieldArea =
          (widget.fieldData['area_dekar'] as num?)?.toDouble() ?? 1.0;
      final config = await showModalBottomSheet<CropConfig>(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (_) => _CropSetupSheet(
          protocol: protocol,
          fieldAreaDekar: fieldArea,
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
          initialTargetDekar:
              selectedConfig?.targetAreaDekar ?? selectedConfig?.areaDekar,
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
    final waterIntervalDays =
        CropScheduleSeeder.intervalForMethod(config?.irrigationMethod);
    final plantedDate =
        '${DateTime.now().day.toString().padLeft(2, '0')}.${DateTime.now().month.toString().padLeft(2, '0')}.${DateTime.now().year}';

    // Yön seçimi — protocollü/protocolsüz tüm bitkiler için her zaman sor.
    // Setup sheet sadece 3 protocollü bitkide açılıyor; yön seçimini ondan
    // ayırarak tüm bitkilerde tutarlı bir akış sağlıyoruz.
    String? facingDirection = config?.facingDirection?.name;
    if (mounted) {
      facingDirection = await _askFacingDirection(
        context,
        plantName: plant.nameTr,
        initialRaw: facingDirection,
      );
    }
    if (!mounted) return;

    // Her ekleme yeni bir kayıt oluşturur — kullanıcı aynı bitki türünden
    // birden fazla bölge ekleyebilir. (Eski "aynı isim varsa replant" davranışı
    // farklı alanları üst üste yazıyordu.)
    final cropId = await repo.addSingleCropToField(
      fieldId: fieldId,
      name: plant.nameTr,
      colorValue: plant.renderColor.toARGB32(),
      plantedDate: plantedDate,
      harvestDays: plant.daysToHarvest,
      waterIntervalDays: waterIntervalDays,
      rowSpacingCm: rowSpacingCm,
      plantSpacingCm: plantSpacingCm,
      zonePolygonJson: zonePolygonJson,
      facingDirection: facingDirection,
    );
    const bool isReplant = false;

    await ref.read(activityLoggerProvider).log(
      fieldId: fieldId,
      type: ActivityType.planting,
      cropId: cropId,
      note: '${plant.nameTr} tarlaya eklendi',
      metadata: {
        'setup_version': 1,
        'replant': isReplant,
        if (config != null) 'area_dekar': config.effectiveAreaDekar,
        if (config != null) 'field_area_dekar': config.areaDekar,
        if (config != null) 'irrigation_method': config.irrigationMethod.name,
        if (config != null) 'soil_type': config.soilType.name,
        if (config != null) 'production_system': config.productionSystem.name,
        if (config?.targetPlantCount != null)
          'target_plant_count': config!.targetPlantCount,
        if (facingDirection != null) 'facing_direction': facingDirection,
        'water_interval_days': waterIntervalDays,
        'row_spacing_cm': rowSpacingCm,
        'plant_spacing_cm': plantSpacingCm,
      },
    );

    // Sezonluk takvim programını yaz — sulama + gübre + koruyucu ilaç.
    // Bitki playbook'u yoksa (3 vitrin dışı) yalnızca sulama programı yazılır.
    await ref.read(cropScheduleSeederProvider).seedForCrop(
          fieldId: fieldId,
          cropId: cropId,
          cropName: plant.nameTr,
          plantedDate: DateTime.now(),
          harvestDays: plant.daysToHarvest,
          waterIntervalDays: waterIntervalDays,
          areaDekar: config?.effectiveAreaDekar,
          irrigationMethod: config?.irrigationMethod,
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
        payload:
            _fieldNotifPayload(fieldId, widget.fieldData['name']?.toString()),
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
          fieldName: widget.fieldData['name']?.toString(),
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

  // ═══════════════════════════════════════════════════════════════
  // Tekil bitki yerleştirme + per-bitki sağlık takibi
  // ═══════════════════════════════════════════════════════════════

  /// Bir crop zone marker'ına dokunulduğunda — DiseasePickerSheet açar.
  /// Var olan instance varsa onun durumu önceden seçili gelir; yoksa
  /// kullanıcı seçim yaptığında yeni instance oluşturulur.
  bool _isPlantMarkerHighlighted(String key) {
    return _hoveredPlantMarkerKey == key ||
        _selectedPlantMarkerKey == key ||
        _multiSelectedPlantTargets.containsKey(key);
  }

  void _setHoveredPlantMarker(String key, bool isHovered) {
    if (!mounted) return;
    if (isHovered) {
      if (_hoveredPlantMarkerKey == key) return;
      setState(() => _hoveredPlantMarkerKey = key);
      return;
    }
    if (_hoveredPlantMarkerKey == key) {
      setState(() => _hoveredPlantMarkerKey = null);
    }
  }

  void _selectPlantMarker(String key) {
    if (_selectedPlantMarkerKey == key) return;
    setState(() => _selectedPlantMarkerKey = key);
  }

  void _clearPlantMarkerSelection() {
    if (_selectedPlantMarkerKey == null && _hoveredPlantMarkerKey == null) {
      return;
    }
    setState(() {
      _selectedPlantMarkerKey = null;
      _hoveredPlantMarkerKey = null;
    });
  }

  Future<void> _onPlantMarkerTap({
    required Map<String, dynamic> crop,
    required int? plantIndex,
    required LatLng pos,
    required FieldPlantInstance? existing,
  }) async {
    if (_isZoneDrawingMode || _isPlacingSinglePlantMode) return;

    final fieldId = widget.fieldData['id']?.toString();
    if (fieldId == null || fieldId.isEmpty) return;
    final cropId = crop['id']?.toString();
    final cropName = crop['name']?.toString() ?? 'Bitki';

    final result = await DiseasePickerSheet.show(
      context,
      cropName: cropName,
      currentStatus: existing?.healthStatus,
      currentDiseaseType: existing?.diseaseType,
      currentPhotoPath: existing?.diseasePhotoPath,
      onCapturePhoto: () async {
        final captured = await DiseaseCaptureScreen.show(
          context,
          cropName: cropName,
          lat: pos.latitude,
          lng: pos.longitude,
        );
        return captured?.photoPath;
      },
    );
    if (result == null || !mounted) return;

    final repo = ref.read(localDataRepositoryProvider);
    String instanceId;
    if (existing != null) {
      instanceId = existing.id;
    } else {
      // Yeni instance oluştur — zone'a bağlı override
      instanceId = await repo.insertPlantInstance(
        fieldId: fieldId,
        cropId: cropId,
        plantIndex: plantIndex,
        cropName: cropName,
        lat: pos.latitude,
        lng: pos.longitude,
        healthStatus: result.status,
      );
    }

    await repo.setPlantHealth(
      instanceId: instanceId,
      healthStatus: result.status,
      diseaseType: result.diseaseType,
      diseasePhotoPath: result.photoPath,
      writeActivityLog: false,
    );

    // TARLAM GÜNLÜĞÜ: Kullanıcıya anlamlı tek kayıt.
    // setPlantHealth bitki durumunu günceller; günlük kaydı burada tek elden
    // yazılır ki aynı hastalık hem tekil hem toplu satır olarak çoğalmasın.
    if (result.status == DiseaseTypes.statusDiseased) {
      await ref.read(activityLoggerProvider).log(
        fieldId: fieldId,
        type: ActivityType.scouting,
        cropId: cropId,
        note: '${result.diseaseType ?? 'Bilinmeyen hastalık'} tespit edildi',
        metadata: {
          'scouting_target': 'Hastalık Taraması',
          'target_pest': result.diseaseType ?? 'Bilinmeyen',
          'threshold_status': 'criticalNoChemical',
          'crop_name': cropName,
        },
      );
    } else if (result.status == DiseaseTypes.statusDead) {
      await ref.read(activityLoggerProvider).log(
        fieldId: fieldId,
        type: ActivityType.scouting,
        cropId: cropId,
        note: 'Bitki ölü olarak işaretlendi',
        metadata: {
          'scouting_target': 'Bitki Sağlık Kontrolü',
          'health_status': result.status,
          'crop_name': cropName,
        },
      );
    } else if (result.status == DiseaseTypes.statusHealthy) {
      await ref.read(activityLoggerProvider).log(
        fieldId: fieldId,
        type: ActivityType.scouting,
        cropId: cropId,
        note: 'Bitki iyileşti, sağlıklı olarak işaretlendi',
        metadata: {
          'crop_name': cropName,
        },
      );
    }

    if (!mounted) return;
    AppToast.show(
      context,
      message: result.status == DiseaseTypes.statusDiseased
          ? 'Bitki hasta olarak işaretlendi.'
          : result.status == DiseaseTypes.statusDead
              ? 'Bitki ölü olarak işaretlendi.'
              : 'Bitki sağlıklı olarak işaretlendi.',
      type: ToastType.success,
    );

    // Hasta veya ölü işaretlendiyse — Tarım Bakanlığı/TAGEM bültenleri
    // tabanlı tavsiye panelini aç. Sağlıklı durumda gösterme.
    if (mounted &&
        (result.status == DiseaseTypes.statusDiseased ||
            result.status == DiseaseTypes.statusDead)) {
      await DiseaseAdviceSheet.show(
        context,
        cropName: cropName,
        healthStatus: result.status,
        diseaseType: result.diseaseType,
      );
    }
  }

  _PlantDeleteTarget _plantTargetForMarker({
    required String markerKey,
    required Map<String, dynamic> crop,
    required int? plantIndex,
    required LatLng pos,
    required FieldPlantInstance? existing,
  }) {
    final cropId = crop['id']?.toString();
    return _PlantDeleteTarget(
      markerKey: markerKey,
      cropId: cropId,
      plantIndex: plantIndex,
      cropName: crop['name']?.toString() ?? existing?.cropName ?? 'Bitki',
      pos: pos,
      existing: existing,
      isStandalone: cropId == null,
    );
  }

  Future<void> _handlePlantMarkerTap({
    required String markerKey,
    required Map<String, dynamic> crop,
    required int? plantIndex,
    required LatLng pos,
    required FieldPlantInstance? existing,
  }) async {
    if (_isZoneDrawingMode || _isPlacingSinglePlantMode) return;

    final target = _plantTargetForMarker(
      markerKey: markerKey,
      crop: crop,
      plantIndex: plantIndex,
      pos: pos,
      existing: existing,
    );

    if (_isPlantMultiSelectMode) {
      _togglePlantMultiSelection(target);
      return;
    }

    _selectPlantMarker(markerKey);
    final action = await _showPlantActionSheet(crop: crop, target: target);
    if (action == null || !mounted) return;

    switch (action) {
      case _PlantAction.editHealth:
        await _onPlantMarkerTap(
          crop: crop,
          plantIndex: plantIndex,
          pos: pos,
          existing: existing,
        );
        break;
      case _PlantAction.editFacingDirection:
        await _editCropFacingDirection(crop);
        break;
      case _PlantAction.deletePlant:
        await _confirmDeletePlantTarget(target);
        break;
      case _PlantAction.deleteArea:
        await _deleteCropZone(crop);
        break;
      case _PlantAction.multiSelect:
        _togglePlantMultiSelection(target);
        break;
    }
  }

  /// Bir bitkinin baktığı yönü düzenler — sheet açar, seçimi DB'ye kaydeder
  /// ve listeyi yeniler. Toast ile kullanıcıya geri bildirim verir.
  Future<void> _editCropFacingDirection(Map<String, dynamic> crop) async {
    final cropId = crop['id']?.toString();
    if (cropId == null || cropId.isEmpty) return;
    final cropName = crop['name']?.toString() ?? 'Bitki';
    final currentRaw = crop['facing_direction']?.toString();

    final result = await _showFacingDirectionSheet(
      context,
      plantName: cropName,
      initialRaw: currentRaw,
    );
    if (!mounted) return;
    if (result == null) return;

    final picked = result is String ? result : null;

    await ref.read(localDataRepositoryProvider).updateCropFacingDirection(
          cropId: cropId,
          facingDirection: picked,
        );
    await _loadFieldCrops();
    if (!mounted) return;
    AppToast.show(
      context,
      message: picked == null
          ? 'Yön bilgisi temizlendi.'
          : '$cropName → ${_facingDirectionLabel(picked)}',
      type: ToastType.success,
    );
  }

  void _handlePlantMarkerLongPress({
    required String markerKey,
    required Map<String, dynamic> crop,
    required int? plantIndex,
    required LatLng pos,
    required FieldPlantInstance? existing,
  }) {
    if (_isZoneDrawingMode || _isPlacingSinglePlantMode) return;
    _togglePlantMultiSelection(
      _plantTargetForMarker(
        markerKey: markerKey,
        crop: crop,
        plantIndex: plantIndex,
        pos: pos,
        existing: existing,
      ),
    );
  }

  Future<_PlantAction?> _showPlantActionSheet({
    required Map<String, dynamic> crop,
    required _PlantDeleteTarget target,
  }) {
    final cropId = crop['id']?.toString();
    return showModalBottomSheet<_PlantAction>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading:
                    const Icon(Icons.eco_rounded, color: AppColors.emerald),
                title: Text(target.cropName, style: AppText.h3(context)),
                subtitle: Text(
                  target.isStandalone ? 'Tekil bitki' : 'Ekim alanı bitkisi',
                ),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.healing_rounded,
                    color: AppColors.emeraldDark),
                title: const Text('Sağlık durumunu düzenle'),
                onTap: () => Navigator.pop(ctx, _PlantAction.editHealth),
              ),
              if (cropId != null && cropId.isNotEmpty)
                Builder(builder: (_) {
                  final raw = crop['facing_direction']?.toString();
                  return ListTile(
                    leading: const Icon(Icons.explore_rounded,
                        color: AppColors.emerald),
                    title: const Text('Baktığı yönü değiştir'),
                    subtitle: Text(raw == null || raw.isEmpty
                        ? 'Yön belirlenmedi'
                        : _facingDirectionLabel(raw)),
                    onTap: () =>
                        Navigator.pop(ctx, _PlantAction.editFacingDirection),
                  );
                }),
              ListTile(
                leading:
                    const Icon(Icons.delete_outline_rounded, color: Colors.red),
                title: const Text('Bu bitkiyi sil'),
                subtitle: Text(target.isStandalone
                    ? 'Haritadan kaldırılır'
                    : 'Bu alandaki yalnız bu bitki kaldırılır'),
                onTap: () => Navigator.pop(ctx, _PlantAction.deletePlant),
              ),
              if (cropId != null && cropId.isNotEmpty)
                ListTile(
                  leading:
                      const Icon(Icons.layers_clear_rounded, color: Colors.red),
                  title: const Text('Bu ekim alanının tümünü sil'),
                  subtitle: const Text(
                    'Alan, takvim ve sulama planları birlikte kaldırılır',
                  ),
                  onTap: () => Navigator.pop(ctx, _PlantAction.deleteArea),
                ),
              ListTile(
                leading: const Icon(Icons.playlist_add_check_rounded,
                    color: AppColors.emerald),
                title: const Text('Çoklu seçim başlat'),
                subtitle: const Text('Birden fazla bitki seçip işlem yap'),
                onTap: () => Navigator.pop(ctx, _PlantAction.multiSelect),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _togglePlantMultiSelection(_PlantDeleteTarget target) {
    setState(() {
      _selectedPlantMarkerKey = null;
      _isPlantMultiSelectMode = true;
      if (_multiSelectedPlantTargets.containsKey(target.markerKey)) {
        _multiSelectedPlantTargets.remove(target.markerKey);
      } else {
        _multiSelectedPlantTargets[target.markerKey] = target;
      }
      if (_multiSelectedPlantTargets.isEmpty) {
        _isPlantMultiSelectMode = false;
      }
    });
  }

  void _clearPlantMultiSelection() {
    if (!_isPlantMultiSelectMode && _multiSelectedPlantTargets.isEmpty) return;
    setState(() {
      _isPlantMultiSelectMode = false;
      _multiSelectedPlantTargets.clear();
    });
  }

  Future<void> _confirmDeletePlantTarget(_PlantDeleteTarget target) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Bitkiyi Sil'),
        content: Text(
          '"${target.cropName}" haritadan silinsin mi? Bu işlem çevrimdışı kuyruğa alınır.',
        ),
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
    if (ok != true || !mounted) return;
    await _deletePlantTarget(target);
    if (!mounted) return;
    setState(() {
      _selectedPlantMarkerKey = null;
      _multiSelectedPlantTargets.remove(target.markerKey);
      if (_multiSelectedPlantTargets.isEmpty) {
        _isPlantMultiSelectMode = false;
      }
    });
    AppToast.show(
      context,
      message: '${target.cropName} silindi.',
      type: ToastType.info,
    );
  }

  Future<void> _deleteSelectedPlants() async {
    final targets = _multiSelectedPlantTargets.values.toList(growable: false);
    if (targets.isEmpty) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Seçili Bitkileri Sil'),
        content: Text(
          '${targets.length} bitki haritadan silinsin mi? Bu işlem çevrimdışı kuyruğa alınır.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('İptal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Seçilileri Sil'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    for (final target in targets) {
      await _deletePlantTarget(target);
    }
    if (!mounted) return;
    setState(() {
      _isPlantMultiSelectMode = false;
      _multiSelectedPlantTargets.clear();
      _selectedPlantMarkerKey = null;
      _hoveredPlantMarkerKey = null;
    });
    AppToast.show(
      context,
      message: '${targets.length} bitki silindi.',
      type: ToastType.info,
    );
  }

  Future<void> _bulkSetHealth() async {
    final targets = _multiSelectedPlantTargets.values.toList(growable: false);
    if (targets.isEmpty) return;

    final count = targets.length;
    final fieldId = widget.fieldData['id']?.toString();
    if (fieldId == null || fieldId.isEmpty) return;

    final result = await DiseasePickerSheet.show(
      context,
      cropName: '$count bitki',
      onCapturePhoto: null,
    );
    if (result == null || !mounted) return;

    final repo = ref.read(localDataRepositoryProvider);
    for (final target in targets) {
      String instanceId;
      if (target.existing != null) {
        instanceId = target.existing!.id;
      } else if (!target.isStandalone &&
          target.cropId != null &&
          target.plantIndex != null) {
        instanceId = await repo.insertPlantInstance(
          fieldId: fieldId,
          cropId: target.cropId,
          plantIndex: target.plantIndex,
          cropName: target.cropName,
          lat: target.pos.latitude,
          lng: target.pos.longitude,
          healthStatus: result.status,
        );
      } else {
        continue;
      }
      await repo.setPlantHealth(
        instanceId: instanceId,
        healthStatus: result.status,
        diseaseType: result.diseaseType,
        diseasePhotoPath: result.photoPath,
        writeActivityLog: false,
      );
    }

    // TARLAM GÜNLÜĞÜ: Toplu işlem tek satır görünür. Bitki başı sağlık
    // güncellemeleri haritada kalır, günlükte ayrı ayrı tekrarlanmaz.
    if (result.status == DiseaseTypes.statusDiseased) {
      await ref.read(activityLoggerProvider).log(
        fieldId: fieldId,
        type: ActivityType.scouting,
        note:
            '$count adet bitkide ${result.diseaseType ?? 'hastalık'} tespit edildi',
        metadata: {
          'scouting_target': 'Çoklu Hastalık Taraması',
          'target_pest': result.diseaseType ?? 'Bilinmeyen',
          'quantity': count,
          'threshold_status': 'criticalNoChemical',
        },
      );
    } else if (result.status == DiseaseTypes.statusDead) {
      await ref.read(activityLoggerProvider).log(
        fieldId: fieldId,
        type: ActivityType.scouting,
        note: '$count adet bitki ölü olarak işaretlendi',
        metadata: {
          'scouting_target': 'Çoklu Bitki Sağlık Kontrolü',
          'quantity': count,
          'health_status': result.status,
        },
      );
    } else if (result.status == DiseaseTypes.statusHealthy) {
      await ref.read(activityLoggerProvider).log(
        fieldId: fieldId,
        type: ActivityType.scouting,
        note: '$count adet bitki iyileşti, sağlıklı işaretlendi',
        metadata: {
          'quantity': count,
        },
      );
    }

    if (!mounted) return;
    setState(() {
      _isPlantMultiSelectMode = false;
      _multiSelectedPlantTargets.clear();
      _selectedPlantMarkerKey = null;
    });

    final statusLabel = result.status == DiseaseTypes.statusDiseased
        ? 'hasta'
        : result.status == DiseaseTypes.statusDead
            ? 'ölü'
            : 'sağlıklı';
    AppToast.show(
      context,
      message: '$count bitki $statusLabel olarak işaretlendi.',
      type: ToastType.success,
    );

    // Toplu işaretlemede de hasta/ölü için tavsiye sheet'i göster.
    if (mounted &&
        (result.status == DiseaseTypes.statusDiseased ||
            result.status == DiseaseTypes.statusDead)) {
      await DiseaseAdviceSheet.show(
        context,
        cropName: '$count bitki',
        healthStatus: result.status,
        diseaseType: result.diseaseType,
      );
    }
  }

  Future<void> _deletePlantTarget(_PlantDeleteTarget target) async {
    final fieldId = widget.fieldData['id']?.toString();
    if (fieldId == null || fieldId.isEmpty) return;
    final repo = ref.read(localDataRepositoryProvider);

    if (target.isStandalone) {
      final existingId = target.existing?.id;
      if (existingId == null) return;
      await repo.deletePlantInstance(existingId);
      return;
    }

    final cropId = target.cropId;
    final plantIndex = target.plantIndex;
    if (cropId == null || cropId.isEmpty || plantIndex == null) return;

    final existingId = target.existing?.id;
    if (existingId != null) {
      await repo.setPlantHealth(
        instanceId: existingId,
        healthStatus: _removedPlantStatus,
      );
    } else {
      await repo.insertPlantInstance(
        fieldId: fieldId,
        cropId: cropId,
        plantIndex: plantIndex,
        cropName: target.cropName,
        lat: target.pos.latitude,
        lng: target.pos.longitude,
        healthStatus: _removedPlantStatus,
      );
    }
  }

  /// Bildirim payload'ı — `type:"field"` tarla harita ekranına gider.
  static String _fieldNotifPayload(String fieldId, String? fieldName) =>
      jsonEncode(
          {'type': 'field', 'fieldId': fieldId, 'fieldName': fieldName ?? ''});

  /// Normal modda boş bir alana dokunulduğunda — kullanıcıya bitkiye
  /// dokunması veya tekil bitki ekleme moduna geçmesi gerektiğini hatırlat.
  /// Hastalık/sağlık kaydı per-bitki olduğundan bos toprağa kayıt girilemez.
  void _onMapTapEmpty(LatLng point) {
    if (_isZoneDrawingMode || _isPlacingSinglePlantMode) return;
    _clearPlantMarkerSelection();
    _clearPlantMultiSelection();
    final polygon = _polygonPoints(widget.fieldData);
    final inside = polygon.length >= 3 &&
        _pointInPolygon(point.latitude, point.longitude, polygon);
    AppToast.show(
      context,
      message: inside
          ? 'Burada herhangi bir bitki yok. Bir bitkiye dokunarak aktivite kaydı yapabilirsiniz.'
          : 'Tarla sınırları dışına dokundunuz. İşlem yapmak için tarla '
              'içindeki bir bitkiye dokunun.',
      type: ToastType.warning,
      duration: const Duration(seconds: 3),
    );
  }

  /// Tekil bitki yerleştirme modunda map tap — TurkishCrop picker açıp
  /// seçilen bitki türü için yeni bir standalone instance oluşturur.
  Future<void> _onMapTapForSinglePlant(LatLng point) async {
    if (!_isPlacingSinglePlantMode) return;

    final polygon = _polygonPoints(widget.fieldData);
    if (polygon.length >= 3 &&
        !_pointInPolygon(point.latitude, point.longitude, polygon)) {
      AppToast.show(
        context,
        message: 'Bu nokta tarla sınırları dışında.',
        type: ToastType.warning,
      );
      return;
    }

    final fieldId = widget.fieldData['id']?.toString();
    if (fieldId == null || fieldId.isEmpty) return;

    final picked = await Navigator.of(context).push<TurkishCrop>(
      MaterialPageRoute(
        builder: (_) => const TurkishCropsSearchScreen(pickerMode: true),
      ),
    );
    if (picked == null || !mounted) return;

    await ref.read(localDataRepositoryProvider).insertPlantInstance(
          fieldId: fieldId,
          cropId: null,
          plantIndex: null,
          cropName: picked.nameTr,
          lat: point.latitude,
          lng: point.longitude,
        );

    if (!mounted) return;
    setState(() => _isPlacingSinglePlantMode = false);
    AppToast.show(
      context,
      message: '${picked.nameTr} eklendi.',
      type: ToastType.success,
    );
  }

  /// "Ekle" uzun basışı bölge çizme ve tekil bitki ekleme seçeneklerini açar.
  void _showPlacementMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.crop_free_rounded,
                    color: AppColors.emerald),
                title: const Text('Bölge Çiz'),
                subtitle: const Text(
                    'Toplu ekim için bitki seç ve ekilecek alanı çiz'),
                onTap: () {
                  Navigator.pop(ctx);
                  _showPlantPicker();
                },
              ),
              const Divider(),
              ListTile(
                leading:
                    const Icon(Icons.eco_rounded, color: AppColors.emeraldDark),
                title: const Text('Tekil Bitki Ekle'),
                subtitle: const Text(
                    'Boş bir noktaya dokunarak tek bir bitki yerleştir'),
                onTap: () {
                  Navigator.pop(ctx);
                  setState(() => _isPlacingSinglePlantMode = true);
                  AppToast.show(
                    context,
                    message: 'Bitkiyi yerleştirmek istediğin noktaya dokun.',
                    type: ToastType.info,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
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
    final rowSpacingCm = protocol?.defaultRowSpacingCm ?? 50.0;
    final plantSpacingCm = protocol?.defaultPlantSpacingCm ?? 40.0;
    const waterIntervalDays =
        7; // Yöntem seçimi yok — varsayılan karık aralığı.
    final plantedDateStr =
        '${DateTime.now().day.toString().padLeft(2, '0')}.${DateTime.now().month.toString().padLeft(2, '0')}.${DateTime.now().year}';

    // Yön seçimi — kullanıcıya bitkinin baktığı yönü sor.
    String? facingDirection;
    if (mounted) {
      facingDirection =
          await _askFacingDirection(context, plantName: plant.nameTr);
    }
    if (!mounted) return;

    // Her ekleme yeni bir kayıt oluşturur — aynı bitki türünden farklı bölgeler
    // birbirini ezmesin diye replant kısa-yolu kaldırıldı.
    final cropId = await repo.addSingleCropToField(
      fieldId: fieldId,
      name: plant.nameTr,
      colorValue: plant.renderColor.toARGB32(),
      plantedDate: plantedDateStr,
      harvestDays: plant.daysToHarvest,
      waterIntervalDays: waterIntervalDays,
      rowSpacingCm: rowSpacingCm,
      plantSpacingCm: plantSpacingCm,
      zonePolygonJson: zoneJson,
      facingDirection: facingDirection,
    );

    await ref.read(activityLoggerProvider).log(
      fieldId: fieldId,
      type: ActivityType.planting,
      cropId: cropId,
      note: '${plant.nameTr} seçilen bölgeye eklendi',
      metadata: {
        'setup_version': 1,
        if (facingDirection != null) 'facing_direction': facingDirection,
        'replant': false,
        'row_spacing_cm': rowSpacingCm,
        'plant_spacing_cm': plantSpacingCm,
        'water_interval_days': waterIntervalDays,
      },
    );

    await ref.read(cropScheduleSeederProvider).seedForCrop(
          fieldId: fieldId,
          cropId: cropId,
          cropName: plant.nameTr,
          plantedDate: DateTime.now(),
          harvestDays: plant.daysToHarvest,
          waterIntervalDays: waterIntervalDays,
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

  /// Bölgeye dokunulduğunda tooltip göster.
  /// Marker tap'leri artık `_onPlantMarkerTap`'e gidiyor; bu metot zone
  /// polygon hit'lerinde tooltip göstermek için yedek olarak duruyor.
  // ignore: unused_element
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
    if (cropId == null || cropId.isEmpty) {
      _closeTooltip();
      AppToast.show(
        context,
        message:
            'Bu bitkinin yerel kaydı bulunamadı. Liste yenilendiğinde tekrar deneyin.',
        type: ToastType.warning,
      );
      return;
    }

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
      try {
        await ref.read(localDataRepositoryProvider).deleteSingleCrop(cropId);
        if (!mounted) return;
        setState(() {
          _selectedCropForTooltip = null;
          _selectedPlantMarkerKey = null;
          _hoveredPlantMarkerKey = null;
          _isPlantMultiSelectMode = false;
          _multiSelectedPlantTargets.clear();
          _fieldCropsLoaded = true;
          _fieldCrops = _fieldCrops
              .where((item) => item['id']?.toString() != cropId)
              .toList();
        });
        await _loadFieldCrops();
        await _loadIrrigationPlans();
        if (!mounted) return;
        AppToast.show(
          context,
          message: '${crop['name']} bölgesi silindi.',
          type: ToastType.info,
        );
      } catch (e) {
        if (!mounted) return;
        AppToast.show(
          context,
          message: 'Bitki silinemedi: $e',
          type: ToastType.error,
        );
      }
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
    if (_fieldCropsLoaded) return _fieldCrops;
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

  LatLng _polygonCenter(List<LatLng> poly) {
    if (poly.isEmpty) return const LatLng(39.0, 35.0);
    double lat = 0;
    double lng = 0;
    for (final p in poly) {
      lat += p.latitude;
      lng += p.longitude;
    }
    return LatLng(lat / poly.length, lng / poly.length);
  }

  double _normalizeFieldViewAngle(double degrees) {
    final normalized = degrees % 360.0;
    return normalized < 0 ? normalized + 360.0 : normalized;
  }

  double _angleDistance(double a, double b) {
    final raw =
        (_normalizeFieldViewAngle(a) - _normalizeFieldViewAngle(b)).abs();
    return raw > 180.0 ? 360.0 - raw : raw;
  }

  void _onFieldMapPositionChanged(MapCamera camera, bool hasGesture) {
    if (!hasGesture) return;
    final rotation = _normalizeFieldViewAngle(camera.rotation);
    if (_angleDistance(rotation, _fieldViewAngleDegrees) < 0.5) return;
    setState(() => _fieldViewAngleDegrees = rotation);
  }

  double _fieldViewDepth(LatLng point, LatLng center) {
    final latScale = 111320.0;
    final lngScale = latScale *
        math
            .cos(center.latitude * math.pi / 180.0)
            .abs()
            .clamp(0.2, 1.0)
            .toDouble();
    final x = (point.longitude - center.longitude) * lngScale;
    final y = (point.latitude - center.latitude) * latScale;
    final angleRad = _fieldViewAngleDegrees * math.pi / 180.0;
    return (y * math.cos(angleRad)) - (x * math.sin(angleRad));
  }

  void _sortPositionsForFieldView(List<LatLng> positions, LatLng center) {
    positions.sort(
      (a, b) =>
          _fieldViewDepth(b, center).compareTo(_fieldViewDepth(a, center)),
    );
  }

  void _sortMarkersForFieldView(List<Marker> markers, LatLng center) {
    markers.sort(
      (a, b) => _fieldViewDepth(b.point, center).compareTo(
        _fieldViewDepth(a.point, center),
      ),
    );
  }

  Widget _buildFieldCropMarker({
    required String cropName,
    required Color cropColor,
    required double maturityPercent,
    required String markerKey,
    String? healthStatus,
    String? diseaseType,
    String? facingDirection,
    required VoidCallback onTap,
    required VoidCallback onLongPress,
  }) {
    Widget marker({required double harvestPulse}) => buildCropMarkerWidget(
          cropName: cropName,
          cropColor: cropColor,
          maturityPercent: maturityPercent,
          harvestPulse: harvestPulse,
          healthStatus: healthStatus,
          diseaseType: diseaseType,
          isHighlighted: _isPlantMarkerHighlighted(markerKey),
          facingDirection: facingDirection,
          onHover: (hovering) => _setHoveredPlantMarker(markerKey, hovering),
          onTap: onTap,
          onLongPress: onLongPress,
        );

    if (maturityPercent < 90) {
      return marker(harvestPulse: 0);
    }
    return AnimatedBuilder(
      animation: _harvestPulseCtrl,
      builder: (_, __) => marker(harvestPulse: _harvestPulseCtrl.value),
    );
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

    // ── Bitki sağlık override'ları + standalone tekil bitkiler ──
    // Crop+plantIndex → instance map (zone marker'larının sağlığını boyamak için)
    // Standalone (cropId=null) instance'lar → ayrı marker olarak çizilir.
    final allInstances = fieldId == null || fieldId.isEmpty
        ? const <FieldPlantInstance>[]
        : ref.watch(fieldPlantInstancesProvider(fieldId)).valueOrNull ??
            const <FieldPlantInstance>[];
    final instancesByCrop = <String, Map<int, FieldPlantInstance>>{};
    final standaloneInstances = <FieldPlantInstance>[];
    for (final inst in allInstances) {
      if (inst.cropId == null || inst.plantIndex == null) {
        if (inst.cropId == null) standaloneInstances.add(inst);
      } else {
        instancesByCrop.putIfAbsent(inst.cropId!,
            () => <int, FieldPlantInstance>{})[inst.plantIndex!] = inst;
      }
    }
    standaloneInstances.sort(
      (a, b) => _fieldViewDepth(LatLng(b.lat, b.lng), center).compareTo(
        _fieldViewDepth(LatLng(a.lat, a.lng), center),
      ),
    );

    const borderColor = Color(0xFF00E676);

    // Polygon bounds — kameranın sınırları ve initial fit için.
    LatLngBounds? bounds;
    if (polygon.length >= 3) {
      bounds = LatLngBounds.fromPoints(polygon);
    }

    // ── Ekili bölge poligonları (zonePolygonJson olanlar) ──
    // Tıklanabilir bölge poligonları (her biri hitValue ile crop'a bağlı)
    final zoneHitPolygons = <Polygon<Map<String, dynamic>>>[];
    final zoneMarkers = <Marker>[];
    final highlightedPlantMarkers = <Marker>[];
    final greenhousePolygons = <Polygon>[];
    final greenhouseMarkers = <Marker>[];
    // Zone olmayan bitkiler için eski grid markerlar
    final gridCrops = <Map<String, dynamic>>[];

    for (final crop in crops) {
      final zoneJson = crop['zone_polygon_json']?.toString();
      final zonePoly = _parseZonePolygon(zoneJson);

      if (zonePoly.length >= 3) {
        final color = _cropColor(crop);
        final cropName = crop['name']?.toString() ?? '';
        final config = fieldId == null || fieldId.isEmpty
            ? null
            : CropProtocolService.loadConfig(
                fieldId: fieldId,
                cropName: cropName,
              );
        final targetCount = config?.targetPlantCount;
        // hitValue ile polygonu direkt crop'a bağlıyoruz — tıklama
        // marker'lara değil polygonun kendisine düşüyor.
        zoneHitPolygons.add(Polygon<Map<String, dynamic>>(
          points: zonePoly,
          color: color.withValues(alpha: 0.15),
          borderColor: color,
          borderStrokeWidth: 4.0,
          hitValue: crop,
        ));

        if (config?.productionSystem.isGreenhouse == true) {
          greenhousePolygons.add(Polygon(
            points: zonePoly,
            color: const Color(0xFFB3E5FC).withValues(alpha: 0.12),
            borderColor: Colors.white.withValues(alpha: 0.85),
            borderStrokeWidth: 6.0,
          ));
          greenhouseMarkers.add(Marker(
            point: _polygonCenter(zonePoly),
            width: 110,
            height: 34,
            child: IgnorePointer(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFF0D1811).withValues(alpha: 0.78),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white70, width: 1.2),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.roofing_rounded,
                        color: Color(0xFFB3E5FC), size: 15),
                    SizedBox(width: 5),
                    Text(
                      'Sera',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ));
        }

        // Bölgeyi tamamen dolduran marker ağı oluştur — dokunulabilir
        final maturity = _computeMaturityPercent(
          crop,
          growthState: growthByCrop[crop['id']?.toString()],
        );
        final positions = plantPlacementInPolygon(
          polygon: zonePoly,
          cropName: cropName,
          rowSpacingCm: (crop['row_spacing_cm'] as num?)?.toDouble(),
          plantSpacingCm: (crop['plant_spacing_cm'] as num?)?.toDouble(),
          // Gerçek adet ayrı tutulur; haritada temsili ve sınırlı marker çizilir.
          exactCount: targetCount,
          maxCount: _maxZonePlantMarkers,
          minVisualSpacingM: _minCropMarkerSpacingM,
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
        _sortPositionsForFieldView(positions, center);

        final cropId = crop['id']?.toString();
        final cropOverrides = (cropId != null)
            ? instancesByCrop[cropId] ?? const <int, FieldPlantInstance>{}
            : const <int, FieldPlantInstance>{};

        for (int i = 0; i < positions.length; i++) {
          final pos = positions[i];
          final instance = cropOverrides[i];
          if (instance?.healthStatus == _removedPlantStatus) continue;
          final plantIndex = i;
          final markerKey = 'zone:${cropId ?? cropName}:$plantIndex';
          final marker = Marker(
            point: pos,
            width: 180,
            height: 220,
            alignment: Alignment.topCenter,
            child: KeyedSubtree(
              key: ValueKey(markerKey),
              child: _buildFieldCropMarker(
                cropName: crop['name']?.toString() ?? '',
                cropColor: color,
                maturityPercent: maturity,
                markerKey: markerKey,
                healthStatus: instance?.healthStatus,
                diseaseType: instance?.diseaseType,
                facingDirection: crop['facing_direction']?.toString(),
                onTap: () {
                  _handlePlantMarkerTap(
                    markerKey: markerKey,
                    crop: crop,
                    plantIndex: plantIndex,
                    pos: pos,
                    existing: instance,
                  );
                },
                onLongPress: () => _handlePlantMarkerLongPress(
                  markerKey: markerKey,
                  crop: crop,
                  plantIndex: plantIndex,
                  pos: pos,
                  existing: instance,
                ),
              ),
            ),
          );
          (_selectedPlantMarkerKey == markerKey ||
                      _multiSelectedPlantTargets.containsKey(markerKey)
                  ? highlightedPlantMarkers
                  : zoneMarkers)
              .add(marker);
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
        maxCount: _maxGridPlantMarkers,
        minVisualSpacingM: _minCropMarkerSpacingM,
      );
      _sortPositionsForFieldView(positions, center);

      // Fallback: polygon çok küçükse ya da yerleştirme boş dönerse merkeze tek marker
      if (positions.isEmpty) {
        if (polygon.isNotEmpty) {
          double cLat = 0, cLng = 0;
          for (final p in polygon) {
            cLat += p.latitude;
            cLng += p.longitude;
          }
          positions.add(LatLng(cLat / polygon.length, cLng / polygon.length));
        } else {
          positions.add(center);
        }
      }

      for (int i = 0; i < positions.length; i++) {
        final crop = gridCrops[i % gridCrops.length];
        final maturity = _computeMaturityPercent(
          crop,
          growthState: growthByCrop[crop['id']?.toString()],
        );
        final cropId = crop['id']?.toString();
        final cropOverrides = (cropId != null)
            ? instancesByCrop[cropId] ?? const <int, FieldPlantInstance>{}
            : const <int, FieldPlantInstance>{};
        final instance = cropOverrides[i];
        if (instance?.healthStatus == _removedPlantStatus) continue;
        final pos = positions[i];
        final cropName = crop['name']?.toString() ?? '';
        final plantIndex = i;
        final markerKey = 'grid:${cropId ?? cropName}:$plantIndex';
        final marker = Marker(
          point: pos,
          width: 180,
          height: 220,
          alignment: Alignment.topCenter,
          child: KeyedSubtree(
            key: ValueKey(markerKey),
            child: _buildFieldCropMarker(
              cropName: cropName,
              cropColor: _cropColor(crop),
              maturityPercent: maturity,
              markerKey: markerKey,
              healthStatus: instance?.healthStatus,
              diseaseType: instance?.diseaseType,
              facingDirection: crop['facing_direction']?.toString(),
              onTap: () {
                _handlePlantMarkerTap(
                  markerKey: markerKey,
                  crop: crop,
                  plantIndex: plantIndex,
                  pos: pos,
                  existing: instance,
                );
              },
              onLongPress: () => _handlePlantMarkerLongPress(
                markerKey: markerKey,
                crop: crop,
                plantIndex: plantIndex,
                pos: pos,
                existing: instance,
              ),
            ),
          ),
        );
        (_selectedPlantMarkerKey == markerKey ||
                    _multiSelectedPlantTargets.containsKey(markerKey)
                ? highlightedPlantMarkers
                : markers)
            .add(marker);
      }
    }

    // Standalone tekil bitki marker'ları (cropId=null instance'lar) —
    // kullanıcının "Tekil Bitki Ekle" ile haritaya yerleştirdiği bitkiler.
    for (final inst in standaloneInstances) {
      final pos = LatLng(inst.lat, inst.lng);
      final markerKey = 'single:${inst.id}';
      final marker = Marker(
        point: pos,
        width: 180,
        height: 220,
        alignment: Alignment.topCenter,
        child: KeyedSubtree(
          key: ValueKey(markerKey),
          child: _buildFieldCropMarker(
            cropName: inst.cropName,
            cropColor: const Color(0xFF66BB6A),
            maturityPercent: 0,
            markerKey: markerKey,
            healthStatus: inst.healthStatus,
            diseaseType: inst.diseaseType,
            onTap: () {
              _handlePlantMarkerTap(
                markerKey: markerKey,
                crop: {
                  'id': null,
                  'name': inst.cropName,
                },
                plantIndex: null,
                pos: pos,
                existing: inst,
              );
            },
            onLongPress: () => _handlePlantMarkerLongPress(
              markerKey: markerKey,
              crop: {
                'id': null,
                'name': inst.cropName,
              },
              plantIndex: null,
              pos: pos,
              existing: inst,
            ),
          ),
        ),
      );
      (_selectedPlantMarkerKey == markerKey ||
                  _multiSelectedPlantTargets.containsKey(markerKey)
              ? highlightedPlantMarkers
              : markers)
          .add(marker);
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
    _sortMarkersForFieldView(markers, center);
    _sortMarkersForFieldView(zoneMarkers, center);
    _sortMarkersForFieldView(highlightedPlantMarkers, center);

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
          initialRotation: _fieldViewAngleDegrees,
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
            flags: (_isZoneDrawingMode || _isPlacingSinglePlantMode)
                ? InteractiveFlag.pinchZoom | InteractiveFlag.drag
                : InteractiveFlag.pinchZoom |
                    InteractiveFlag.drag |
                    InteractiveFlag.doubleTapZoom |
                    InteractiveFlag.rotate,
            enableMultiFingerGestureRace:
                !_isZoneDrawingMode && !_isPlacingSinglePlantMode,
            rotationThreshold: 8.0,
          ),
          onPositionChanged: _onFieldMapPositionChanged,
          onTap: _isZoneDrawingMode
              ? (tapPos, point) => _onMapTapForZone(point)
              : _isPlacingSinglePlantMode
                  ? (tapPos, point) => _onMapTapForSinglePlant(point)
                  : (tapPos, point) => _onMapTapEmpty(point),
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
                // Çizilmekte olan polygon
                ...drawingPolygons,
              ],
            ),
          if (markers.isNotEmpty) MarkerLayer(markers: markers, rotate: true),
          if (greenhousePolygons.isNotEmpty)
            PolygonLayer(polygons: greenhousePolygons),
          if (greenhouseMarkers.isNotEmpty)
            MarkerLayer(markers: greenhouseMarkers, rotate: true),
          if (zoneMarkers.isNotEmpty)
            MarkerLayer(markers: zoneMarkers, rotate: true),
          if (highlightedPlantMarkers.isNotEmpty)
            MarkerLayer(markers: highlightedPlantMarkers, rotate: true),
          if (drawingMarkers.isNotEmpty)
            MarkerLayer(markers: drawingMarkers, rotate: true),
          if (cornerMarkers.isNotEmpty)
            MarkerLayer(markers: cornerMarkers, rotate: true),
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
  /// "Rehber" akıllı yönlendirme.
  ///
  /// Tek "Bugünün Rehberi" ekranını açar. Eski bottom-sheet modal + 5 paralel
  /// UI yüzeyi yerine tek `DailyGuideScreen` — alerts/today/thisWeek/insights
  /// tek tutarlı yerden gelir. Aktivite kaydedildikçe canlı güncellenir.
  void _showDetailModal() {
    final fieldId = widget.fieldData['id']?.toString() ?? '';
    if (fieldId.isEmpty) {
      AppToast.show(context,
          message: 'Rehber açmak için tarla kimliği bulunamadı.',
          type: ToastType.warning);
      return;
    }
    // Açılış öncesi ekinler için recompute — stale veriyle açılmasın.
    for (final crop in _fieldCrops) {
      final cropId = crop['id']?.toString();
      if (cropId != null && cropId.isNotEmpty) {
        ref.read(growthEngineProvider).recompute(cropId: cropId);
      }
    }
    FieldQuickGuideSheet.show(
      context,
      fieldId: fieldId,
      fieldName: widget.fieldData['name']?.toString() ?? 'Tarla',
    );
  }

  // ignore: unused_element
  void _openCropGuide(Map<String, dynamic> crop) {
    final fieldId = widget.fieldData['id']?.toString() ?? '';
    final cropId = crop['id']?.toString();
    if (fieldId.isEmpty || cropId == null || cropId.isEmpty) {
      AppToast.show(context,
          message: 'Rehber açmak için kayıtlı bitki bulunamadı.',
          type: ToastType.warning);
      return;
    }
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => CropDailyPlanScreen(
        fieldId: fieldId,
        cropId: cropId,
        fieldName: widget.fieldData['name']?.toString() ?? 'Tarla',
        latitude: (widget.fieldData['latitude'] as num?)?.toDouble(),
        longitude: (widget.fieldData['longitude'] as num?)?.toDouble(),
        areaDekar: (widget.fieldData['area_dekar'] as num?)?.toDouble() ?? 1.0,
      ),
    ));
  }

  // ignore: unused_element
  Future<void> _showGuideCropPicker(
    List<Map<String, dynamic>> guideCrops,
  ) async {
    final fieldId = widget.fieldData['id']?.toString() ?? '';
    List<Map<String, dynamic>> activities = const [];
    List<dynamic> growthStates = const [];
    try {
      activities = await ref.read(fieldActivityLogProvider(fieldId).future);
      growthStates = await ref.read(fieldGrowthStatesProvider(fieldId).future);
    } catch (_) {}

    final fieldStates = ref.read(fieldStateServiceProvider).compute(
          field: Map<String, dynamic>.from(widget.fieldData as Map),
          fieldCrops: _fieldCrops,
          activities: activities,
        );
    final fieldStateByCrop = {
      for (final state in fieldStates) state.cropId: state,
    };
    final growthByCrop = <String, dynamic>{};
    for (final state in growthStates) {
      try {
        final dyn = state as dynamic;
        final cropId = dyn.cropId as String?;
        if (cropId != null) growthByCrop[cropId] = state;
      } catch (_) {}
    }
    final directives = ref.read(taskDirectiveServiceProvider).generate(
          fieldCrops: _fieldCrops,
          activities: activities,
          dailyForecast: _analysis?['daily_forecast'] as List?,
        );

    if (!mounted) return;
    await showModalBottomSheet<void>(
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
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(ctx).size.height * 0.72,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFF14241B),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
              const SizedBox(height: 14),
              Text(
                'Hangi bitkinin rehberi?',
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Seçtiğin bitkinin günlük rehberi buradan açılır.',
                style: TextStyle(color: Colors.white70, fontSize: 12.5),
              ),
              const SizedBox(height: 12),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: guideCrops.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) {
                    final crop = guideCrops[i];
                    final cropId = crop['id']?.toString() ?? '';
                    final activeCount = directives
                        .where((d) => d.cropId == cropId && d.urgency >= 1)
                        .length;
                    final fieldState = fieldStateByCrop[cropId];
                    final growth = growthByCrop[cropId];
                    final stage = _guideStageLabel(growth);
                    final planted =
                        _parseDmYDate(crop['planted_date']?.toString());
                    return InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () {
                        Navigator.pop(ctx);
                        _openCropGuide(crop);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(13),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.10),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: const Color(0xFF00E676)
                                    .withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.eco_rounded,
                                  color: Color(0xFF00E676)),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    crop['name']?.toString() ?? 'Bitki',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    [
                                      if (planted != null)
                                        '${DateFormat('d MMM', 'tr_TR').format(planted)} ekildi',
                                      if (stage != null) stage,
                                      if (fieldState != null)
                                        'Su: ${fieldState.waterSummary}',
                                    ].join(' • '),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 11.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            if (activeCount > 0)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFB74D)
                                      .withValues(alpha: 0.16),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  '$activeCount iş',
                                  style: const TextStyle(
                                    color: Color(0xFFFFB74D),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            const Icon(Icons.chevron_right_rounded,
                                color: Colors.white54),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String? _guideStageLabel(dynamic growth) {
    if (growth == null) return null;
    try {
      final key = (growth as dynamic).currentStageKey as String?;
      switch (key) {
        case 'cimlenme':
          return 'Çimlenme';
        case 'vejetatif':
          return 'Vejetatif';
        case 'ciceklenme':
          return 'Çiçeklenme';
        case 'meyve_dolumu':
          return 'Meyve dolumu';
        case 'olgunlasma':
          return 'Olgunlaşma';
      }
    } catch (_) {}
    return null;
  }

  static DateTime? _parseDmYDate(String? raw) {
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
}

enum _PlantAction {
  editHealth,
  editFacingDirection,
  deletePlant,
  deleteArea,
  multiSelect,
}

class _PlantDeleteTarget {
  const _PlantDeleteTarget({
    required this.markerKey,
    required this.cropId,
    required this.plantIndex,
    required this.cropName,
    required this.pos,
    required this.existing,
    required this.isStandalone,
  });

  final String markerKey;
  final String? cropId;
  final int? plantIndex;
  final String cropName;
  final LatLng pos;
  final FieldPlantInstance? existing;
  final bool isStandalone;
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
// ignore: unused_element
class _DirectivesModalContent extends ConsumerWidget {
  const _DirectivesModalContent({
    required this.fieldId,
    required this.fieldData,
    required this.analysis,
    required this.latestSuitabilityReport,
    required this.fieldCrops,
    required this.fieldAreaDekar,
    // ignore: unused_element_parameter
    this.onCropSetupChanged,
  });

  final String fieldId;
  final Map<String, dynamic> fieldData;
  final Map<String, dynamic>? analysis;
  final Map<String, dynamic>? latestSuitabilityReport;
  final List<Map<String, dynamic>> fieldCrops;
  final double fieldAreaDekar;
  final Future<void> Function()? onCropSetupChanged;

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

  ({double? ph, double? temp, double? weeklyRain}) _setupEnv() {
    final report = latestSuitabilityReport?['report'];
    final reportMap = report is Map ? Map<String, dynamic>.from(report) : null;
    final soil = reportMap?['soil_snapshot'];
    final soilMap = soil is Map ? Map<String, dynamic>.from(soil) : null;
    final weather = reportMap?['weather_snapshot'];
    final weatherMap =
        weather is Map ? Map<String, dynamic>.from(weather) : null;

    return (
      ph: (analysis?['ph'] as num?)?.toDouble() ??
          (soilMap?['ph'] as num?)?.toDouble(),
      temp: (analysis?['avg_weekly_temp'] as num?)?.toDouble() ??
          (analysis?['temp'] as num?)?.toDouble() ??
          (weatherMap?['avg_weekly_temp'] as num?)?.toDouble() ??
          (weatherMap?['temp'] as num?)?.toDouble(),
      weeklyRain: (analysis?['total_weekly_rain'] as num?)?.toDouble() ??
          (weatherMap?['total_weekly_rain'] as num?)?.toDouble(),
    );
  }

  List<_SetupCropCandidate> _setupCropCandidates() {
    final out = <_SetupCropCandidate>[];

    void addCandidates(Object? raw) {
      if (raw is! List) return;
      for (final item in raw) {
        if (item is! Map) continue;
        final map = Map<String, dynamic>.from(item);
        final name = map['name']?.toString().trim();
        if (name == null || name.isEmpty) continue;
        final score = (map['uygunluk'] as num?)?.toDouble() ??
            (map['score'] as num?)?.toDouble();
        out.add(_SetupCropCandidate(name: name, score: score));
      }
    }

    final report = latestSuitabilityReport?['report'];
    if (report is Map) {
      addCandidates(report['top_recommendations']);
    }
    addCandidates(analysis?['crops']);

    if (out.isEmpty) {
      final env = _setupEnv();
      final ph = env.ph ?? 6.8;
      final temp = env.temp ?? 20.0;
      final annualRain = (env.weeklyRain ?? 10.0) * 52;
      for (final plant in VerifiedAgriDatabase.plants) {
        out.add(_SetupCropCandidate(
          name: plant.nameTr,
          score: plant.evaluateSuitability(ph, temp, annualRain).toDouble(),
        ));
      }
    }

    final byName = <String, _SetupCropCandidate>{};
    for (final item in out) {
      final key = item.name.toLowerCase();
      final current = byName[key];
      if (current == null || (item.score ?? 0) > (current.score ?? 0)) {
        byName[key] = item;
      }
    }
    final list = byName.values.toList()
      ..sort((a, b) => (b.score ?? -1).compareTo(a.score ?? -1));
    return list.take(3).toList();
  }

  List<_SetupAction> _setupActions() {
    final env = _setupEnv();
    final topCrops = _setupCropCandidates();
    final firstCrop = topCrops.isNotEmpty ? topCrops.first.name : null;
    final guide =
        firstCrop == null ? null : TurkiyeCropGuides.lookup(firstCrop);
    AgriPlant? verified;
    if (firstCrop != null) {
      final normalized = firstCrop.toLowerCase();
      for (final plant in VerifiedAgriDatabase.plants) {
        final plantName = plant.nameTr.toLowerCase();
        if (plantName == normalized ||
            plantName.contains(normalized) ||
            normalized.contains(plantName)) {
          verified = plant;
          break;
        }
      }
    }
    final rawPolygon = fieldData['polygon'];
    final hasBoundary = rawPolygon is List && rawPolygon.length >= 3;
    final area = fieldAreaDekar > 0
        ? fieldAreaDekar
        : (fieldData['area_dekar'] as num?)?.toDouble();
    final areaText =
        area == null ? 'alan bilinmiyor' : '${area.toStringAsFixed(1)} da';
    final ph = env.ph;
    final weeklyRain = env.weeklyRain;
    final cropLine = topCrops.isEmpty
        ? 'Uygun ürün listesi oluşmadı; önce toprak ve hava verisini yenile.'
        : topCrops
            .map((c) =>
                c.score == null ? c.name : '${c.name} %${c.score!.round()}')
            .join(', ');
    final cropCalendar = guide != null
        ? '${guide.cropName}: ekim ${guide.sowingWindow}, hasat ${guide.harvestWindow}. ${guide.regionNote}'
        : verified != null
            ? '${verified.nameTr}: pH ${verified.minPh}-${verified.maxPh}, yaklaşık ${verified.daysToHarvest} gün.'
            : 'Ekim zamanı için yerel ürün rehberindeki bölge takvimini esas al.';
    final phLine = ph == null
        ? 'pH yok. İl/ilçe tarım ya da laboratuvar analizi girilmeden gübre ve kireç kararını kesinleştirme.'
        : guide != null && (ph < guide.idealPhMin || ph > guide.idealPhMax)
            ? 'pH ${ph.toStringAsFixed(1)}. $firstCrop için hedef ${guide.idealPhMin}-${guide.idealPhMax}; düzeltmeyi analiz sonucuna göre planla.'
            : verified != null && (ph < verified.minPh || ph > verified.maxPh)
                ? 'pH ${ph.toStringAsFixed(1)}. $firstCrop için uygun aralık ${verified.minPh}-${verified.maxPh}; ekimden önce toprak düzenlemesi gerekebilir.'
                : 'pH ${ph.toStringAsFixed(1)}. Seçilecek ürün için sorun görünmüyorsa taban gübreyi yine analiz sonucuna göre ver.';
    final waterLine = weeklyRain == null
        ? 'Yağış tahmini yok. İlk sulama planını toprak nemine bakarak kısa aralıklarla kontrol et.'
        : weeklyRain >= 20
            ? 'Bu hafta ${weeklyRain.toStringAsFixed(0)} mm yağış görünüyor. Ağır tavlı toprağa ekipman sokma; sıkışma yapar.'
            : weeklyRain < 8
                ? 'Bu hafta yağış ${weeklyRain.toStringAsFixed(0)} mm. Ekimden sonra can suyu ve damla/yağmurlama planı hazır olsun.'
                : 'Bu hafta ${weeklyRain.toStringAsFixed(0)} mm yağış var. Sulamayı sabah erken saate al, yağıştan sonra toprağı kontrol et.';

    return [
      _SetupAction(
        icon: hasBoundary ? Icons.task_alt_rounded : Icons.polyline_rounded,
        color: hasBoundary ? const Color(0xFF00E676) : const Color(0xFFFFB74D),
        label: hasBoundary ? 'Sınır hazır' : 'Öncelik',
        title: hasBoundary
            ? 'Sınırı ve alanı son kez kontrol et'
            : 'Tarla sınırını tamamla',
        body: hasBoundary
            ? '$areaText üzerinden tohum, fide, su ve gübre hesabı yapılacak. Köşe noktası hatalıysa bütün hesap sapar.'
            : 'Haritada en az 3 köşe ile tarlayı kapat. Alan netleşmeden ekim ve sulama hesabına geçme.',
      ),
      _SetupAction(
        icon: Icons.agriculture_rounded,
        color: const Color(0xFF64B5F6),
        label: 'Ürün seçimi',
        title: 'Türkiye takvimine göre ürünü seç',
        body: '$cropLine. $cropCalendar',
      ),
      _SetupAction(
        icon: Icons.science_rounded,
        color: const Color(0xFFCE93D8),
        label: 'Toprak',
        title: 'Toprak kararını pH ve analizle ver',
        body: phLine,
      ),
      _SetupAction(
        icon: Icons.water_drop_rounded,
        color: const Color(0xFF4DD0E1),
        label: 'Sulama',
        title: 'İlk su planını yağışa göre kur',
        body: waterLine,
      ),
      _SetupAction(
        icon: Icons.grid_on_rounded,
        color: const Color(0xFFAED581),
        label: 'Yerleşim',
        title: 'Ekim bölgesini tarlanın üstüne çiz',
        body: guide != null
            ? 'Sıra arası ${guide.rowSpacingCm.toStringAsFixed(0)} cm, bitki arası ${guide.plantSpacingCm.toStringAsFixed(0)} cm rehber değeridir. Bölgeyi çizince kayıtlar bu plana bağlanır.'
            : 'Ekle düğmesiyle ürünü seç, bölgeyi çiz ve sıra aralığını kaydet. Böylece sulama, günlük ve hasat uyarıları aynı bitkiye bağlanır.',
      ),
    ];
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activityAsync = ref.watch(fieldActivityLogProvider(fieldId));
    final growthAsync = ref.watch(fieldGrowthStatesProvider(fieldId));
    final service = ref.watch(taskDirectiveServiceProvider);

    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 8),
          Container(
            width: 44,
            height: 4,
            decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(height: 14),
          // Yeşil hero başlık
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.fromLTRB(16, 14, 10, 14),
            decoration: BoxDecoration(
              gradient: AppGradients.forestHero,
              borderRadius: AppRadius.md,
              boxShadow: AppShadows.md,
            ),
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
                icon: const Icon(Icons.close, color: Colors.white),
              ),
            ]),
          ),
          const SizedBox(height: 14),
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
                final scheduledAsync = ref.watch(
                  fieldScheduledAutoSeedProvider(fieldData['id'].toString()),
                );
                final directives = service.generate(
                  fieldCrops: fieldCrops,
                  activities: activities,
                  dailyForecast: analysis?['daily_forecast'] as List?,
                  currentTemp: (analysis?['temp'] as num?)?.toDouble(),
                  soilMoisture:
                      (analysis?['soil_moisture'] as num?)?.toDouble(),
                  growthStates: growthMap,
                  fieldStates: fieldStateMap,
                  scheduledEvents: scheduledAsync.valueOrNull,
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
                  if (cropId != null) {
                    summaryCards.add(Padding(
                      padding: const EdgeInsets.only(top: 8, bottom: 4),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.of(context).push(MaterialPageRoute(
                              builder: (_) => CropDailyPlanScreen(
                                fieldId: fieldId,
                                cropId: cropId,
                                fieldName:
                                    fieldData['name']?.toString() ?? 'Tarla',
                                latitude:
                                    (fieldData['latitude'] as num?)?.toDouble(),
                                longitude: (fieldData['longitude'] as num?)
                                    ?.toDouble(),
                                areaDekar: fieldAreaDekar,
                              ),
                            ));
                          },
                          icon: const Icon(Icons.event_available_rounded),
                          label: Text(
                            '${crop['name']} — Gün-Gün Rehber',
                          ),
                        ),
                      ),
                    ));
                  }
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
                      crop: crop,
                      fieldAreaDekar: fieldAreaDekar,
                      onChanged: onCropSetupChanged,
                    ));
                  }
                }

                final setupEnv = _setupEnv();
                final setupCard = _FieldSetupPlanCard(
                  actions: _setupActions(),
                  hasCrops: fieldCrops.isNotEmpty,
                  ph: setupEnv.ph,
                  temp: setupEnv.temp,
                  weeklyRain: setupEnv.weeklyRain,
                );
                final totalCount = 1 +
                    summaryCards.length +
                    roadmaps.length +
                    directives.length;
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
                  itemCount: totalCount,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) {
                    if (i == 0) return setupCard;
                    final setupOffset = i - 1;
                    if (setupOffset < summaryCards.length) {
                      return summaryCards[setupOffset];
                    }
                    final j = setupOffset - summaryCards.length;
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

class _SetupCropCandidate {
  const _SetupCropCandidate({required this.name, this.score});

  final String name;
  final double? score;
}

class _SetupAction {
  const _SetupAction({
    required this.icon,
    required this.color,
    required this.label,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final Color color;
  final String label;
  final String title;
  final String body;
}

class _FieldSetupPlanCard extends StatelessWidget {
  const _FieldSetupPlanCard({
    required this.actions,
    required this.hasCrops,
    required this.ph,
    required this.temp,
    required this.weeklyRain,
  });

  final List<_SetupAction> actions;
  final bool hasCrops;
  final double? ph;
  final double? temp;
  final double? weeklyRain;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF183523), Color(0xFF102016)],
        ),
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: const Color(0xFF00E676).withValues(alpha: 0.28)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x66000000),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFF00E676).withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF00E676).withValues(alpha: 0.35),
                  ),
                ),
                child: const Icon(
                  Icons.assignment_turned_in_rounded,
                  color: Color(0xFF00E676),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hasCrops ? 'Tarla Takip Planı' : 'Tarla Kurulum Planı',
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      hasCrops
                          ? 'Kayıtlı bitkilere göre sulama, bakım ve hasat işleri burada sıraya girer.'
                          : 'Yeni tarlada önce bu işleri bitir; sonra ekim ve bakım kayıtları düzgün çalışır.',
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 12.5),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _SetupMetricChip(
                icon: Icons.science_rounded,
                text: ph == null ? 'pH yok' : 'pH ${ph!.toStringAsFixed(1)}',
              ),
              _SetupMetricChip(
                icon: Icons.thermostat_rounded,
                text: temp == null
                    ? 'Sıcaklık yok'
                    : '${temp!.toStringAsFixed(0)}°C',
              ),
              _SetupMetricChip(
                icon: Icons.water_drop_rounded,
                text: weeklyRain == null
                    ? 'Yağış yok'
                    : '${weeklyRain!.toStringAsFixed(0)} mm/hafta',
              ),
            ],
          ),
          const SizedBox(height: 14),
          for (int i = 0; i < actions.length; i++) ...[
            _SetupActionRow(number: i + 1, action: actions[i]),
            if (i != actions.length - 1)
              Divider(
                color: Colors.white.withValues(alpha: 0.08),
                height: 16,
              ),
          ],
        ],
      ),
    );
  }
}

class _SetupMetricChip extends StatelessWidget {
  const _SetupMetricChip({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white70, size: 14),
          const SizedBox(width: 5),
          Text(
            text,
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _SetupActionRow extends StatelessWidget {
  const _SetupActionRow({required this.number, required this.action});

  final int number;
  final _SetupAction action;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: action.color.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: action.color.withValues(alpha: 0.38)),
          ),
          child: Icon(action.icon, color: action.color, size: 18),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '$number. ${action.title}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      action.label,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: action.color,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                action.body,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12.2,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
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
      case 'ipm_scouting':
      case 'overdue_scouting':
        return Icons.manage_search_rounded;
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
      if (type == ActivityType.watering) {
        final repo = ref.read(localDataRepositoryProvider);
        final field = await repo.loadFieldById(widget.fieldId);
        final crops = await repo.loadFieldCrops(widget.fieldId);
        if (!mounted) return;
        await showActivityQuickLogSheet(
          context: context,
          ref: ref,
          fieldId: widget.fieldId,
          type: type,
          cropId: d.cropId,
          fieldCrops: crops,
          fieldAreaDekar:
              (field?['area_dekar'] as num?)?.toDouble() ?? d.areaDekar ?? 1.0,
          recommendedQuantity: d.recommendedQuantity ?? d.suggestedQuantity,
          quantityUnit: d.quantityUnit,
          note: [
            d.reason,
            if (d.steps.isNotEmpty) d.steps.join('\n'),
          ].join('\n'),
        );
        return;
      }
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
    if (s.contains('bku') || s.contains('bitki koruma')) return 'BKÜ';
    if (s.contains('fao')) return 'FAO-56';
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
class _CropRoadmapCard extends ConsumerStatefulWidget {
  const _CropRoadmapCard({
    required this.progress,
    required this.fieldId,
    required this.crop,
    required this.fieldAreaDekar,
    this.onChanged,
  });

  final CropProtocolProgress progress;
  final String fieldId;
  final Map<String, dynamic> crop;
  final double fieldAreaDekar;
  final Future<void> Function()? onChanged;

  @override
  ConsumerState<_CropRoadmapCard> createState() => _CropRoadmapCardState();
}

class _CropRoadmapCardState extends ConsumerState<_CropRoadmapCard> {
  bool _expanded = true;
  int? _expandedStep; // adım detayı açık mı (order değeri)
  CropConfig? _configOverride;

  static const _accent = Color(0xFF00E676);
  static const _warn = Color(0xFFFF5252);
  static const _tip = Color(0xFF00E676);
  static const _mistake = Color(0xFFFFB74D);
  static const _info = Color(0xFF40C4FF);

  String _formatArea(double area) => area == area.roundToDouble()
      ? '${area.round()}'
      : area.toStringAsFixed(1);

  static DateTime? _parsePlantedDate(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    final parts = raw.split('.');
    if (parts.length == 3) {
      return DateTime.tryParse(
        '${parts[2]}-${parts[1].padLeft(2, '0')}-${parts[0].padLeft(2, '0')}',
      );
    }
    return DateTime.tryParse(raw);
  }

  Future<void> _editConfig() async {
    final current = _configOverride ?? widget.progress.config;
    final config = await showModalBottomSheet<CropConfig>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _CropSetupSheet(
        protocol: widget.progress.protocol,
        fieldAreaDekar: widget.fieldAreaDekar,
        initialConfig: current,
      ),
    );
    if (config == null || !mounted) return;

    final cropId = widget.crop['id']?.toString();
    final cropName =
        widget.crop['name']?.toString() ?? widget.progress.protocol.displayName;
    if (cropId == null || cropId.isEmpty) return;

    await CropProtocolService.saveConfig(
      fieldId: widget.fieldId,
      cropName: cropName,
      config: config,
    );

    final waterIntervalDays =
        CropScheduleSeeder.intervalForMethod(config.irrigationMethod);
    final repo = ref.read(localDataRepositoryProvider);
    await repo.updateCropSetup(
      cropId: cropId,
      waterIntervalDays: waterIntervalDays,
      rowSpacingCm: config.rowSpacingCm,
      plantSpacingCm: config.plantSpacingCm,
    );

    await ref.read(cropScheduleSeederProvider).seedForCrop(
          fieldId: widget.fieldId,
          cropId: cropId,
          cropName: cropName,
          plantedDate:
              _parsePlantedDate(widget.crop['planted_date']?.toString()) ??
                  DateTime.now(),
          harvestDays: (widget.crop['harvest_days'] as num?)?.toInt() ??
              widget.progress.protocol.totalDays,
          waterIntervalDays: waterIntervalDays,
          areaDekar: config.effectiveAreaDekar,
          irrigationMethod: config.irrigationMethod,
        );

    await ref.read(growthEngineProvider).recompute(cropId: cropId);
    await widget.onChanged?.call();
    if (!mounted) return;
    setState(() => _configOverride = config);
    AppToast.show(
      context,
      message: 'Kurulum bilgileri güncellendi',
      type: ToastType.success,
    );
  }

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
    final cfg = _configOverride ?? p.config;

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
                              runSpacing: 6,
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
                                _cfgChip('🏛️', cfg.productionSystem.label,
                                    isIcon: true,
                                    icon: cfg.productionSystem.icon),
                                _cfgChip('📐',
                                    '${_formatArea(cfg.effectiveAreaDekar)} da'),
                                _cfgChip(
                                    '🌱', '${cfg.estimatedPlantCount} bitki'),
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
                    IconButton(
                      tooltip: 'Kurulumu düzenle',
                      onPressed: _editConfig,
                      icon: const Icon(Icons.tune_rounded,
                          color: Color(0xFF00E676), size: 20),
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
                    area: cfg?.effectiveAreaDekar ?? 1,
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
  const _CropSetupSheet({
    required this.protocol,
    required this.fieldAreaDekar,
    this.initialConfig,
  });

  final CropProtocol protocol;
  final CropConfig? initialConfig;

  /// Tarla poligonundan ölçülen alan. Çiftçi manuel olarak tekrar girmiyor;
  /// `_CropSetupSheet` bu değeri rehber not'larında ve ekim hesabında kullanır.
  /// Manuel input UX'i karışıktı: kullanıcı 50 da yazsa bile poligon 5 da
  /// olduğunda gerçek alan poligondan geliyordu.
  final double fieldAreaDekar;

  @override
  State<_CropSetupSheet> createState() => _CropSetupSheetState();
}

class _CropSetupSheetState extends State<_CropSetupSheet> {
  late SoilType _soil;
  late IrrigationMethod _irrigation;
  late ProductionSystem _productionSystem;
  late final TextEditingController _rowCtrl;
  late final TextEditingController _plantCtrl;
  late final TextEditingController _plantCountCtrl;

  static const _bg = Color(0xFF0D1811);
  static const _accent = Color(0xFF00E676);
  static const _card = Color(0xFF152018);

  @override
  void initState() {
    super.initState();
    final cfg = widget.initialConfig;
    _soil = cfg?.soilType ?? SoilType.loamy;
    _irrigation = cfg?.irrigationMethod ?? IrrigationMethod.furrow;
    _productionSystem = cfg?.productionSystem ?? ProductionSystem.openField;
    _rowCtrl = TextEditingController(
        text: (cfg?.rowSpacingCm ?? widget.protocol.defaultRowSpacingCm)
            .toStringAsFixed(0));
    _plantCtrl = TextEditingController(
        text: (cfg?.plantSpacingCm ?? widget.protocol.defaultPlantSpacingCm)
            .toStringAsFixed(0));
    _plantCountCtrl = TextEditingController(
      text: cfg?.targetPlantCount == null ? '' : '${cfg!.targetPlantCount}',
    );
  }

  @override
  void dispose() {
    _rowCtrl.dispose();
    _plantCtrl.dispose();
    _plantCountCtrl.dispose();
    super.dispose();
  }

  void _confirm() {
    final row = double.tryParse(_rowCtrl.text.trim()) ??
        widget.protocol.defaultRowSpacingCm;
    final plant = double.tryParse(_plantCtrl.text.trim()) ??
        widget.protocol.defaultPlantSpacingCm;
    // Alan tarladan otomatik geliyor — manuel input kaldırıldı.
    // Bir alt sınır koruyoruz ki bozuk poligon (0 da) hesabı patlatmasın.
    final area = widget.fieldAreaDekar.clamp(0.1, 10000).toDouble();
    final plantCountRaw = _plantCountCtrl.text.trim();
    final plantCount =
        plantCountRaw.isEmpty ? null : int.tryParse(plantCountRaw);
    if (plantCountRaw.isNotEmpty && (plantCount == null || plantCount <= 0)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bitki adedi pozitif bir sayı olmalı.')),
      );
      return;
    }
    final cleanRow = row.clamp(20, 200).toDouble();
    final cleanPlant = plant.clamp(5, 200).toDouble();
    if (plantCount != null) {
      final requiredDekar = _requiredDekarFor(
        plantCount: plantCount,
        rowSpacingCm: cleanRow,
        plantSpacingCm: cleanPlant,
      );
      if (requiredDekar > area + 0.01) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '$plantCount bitki için yaklaşık ${requiredDekar.toStringAsFixed(2)} da gerekir. Tarlada ${area.toStringAsFixed(2)} da var.',
            ),
          ),
        );
        return;
      }
    }
    Navigator.pop(
      context,
      CropConfig(
        soilType: _soil,
        irrigationMethod: _irrigation,
        productionSystem: _productionSystem,
        areaDekar: area,
        rowSpacingCm: cleanRow,
        plantSpacingCm: cleanPlant,
        targetPlantCount: plantCount,
      ),
    );
  }

  double _requiredDekarFor({
    required int plantCount,
    required double rowSpacingCm,
    required double plantSpacingCm,
  }) {
    final footprintSqm = (rowSpacingCm / 100) * (plantSpacingCm / 100);
    return (plantCount * footprintSqm) / 1000;
  }

  int _estimatedCountForCurrentSpacing() {
    final row = double.tryParse(_rowCtrl.text.trim()) ??
        widget.protocol.defaultRowSpacingCm;
    final plant = double.tryParse(_plantCtrl.text.trim()) ??
        widget.protocol.defaultPlantSpacingCm;
    final footprintSqm =
        (row.clamp(20, 200) / 100) * (plant.clamp(5, 200) / 100);
    if (footprintSqm <= 0) return 0;
    return ((widget.fieldAreaDekar * 1000) / footprintSqm).round();
  }

  double? _targetDekarPreview() {
    final plantCountRaw = _plantCountCtrl.text.trim();
    if (plantCountRaw.isEmpty) return null;
    final plantCount = int.tryParse(plantCountRaw);
    if (plantCount == null || plantCount <= 0) return null;
    final row = double.tryParse(_rowCtrl.text.trim()) ??
        widget.protocol.defaultRowSpacingCm;
    final plant = double.tryParse(_plantCtrl.text.trim()) ??
        widget.protocol.defaultPlantSpacingCm;
    return _requiredDekarFor(
      plantCount: plantCount,
      rowSpacingCm: row.clamp(20, 200).toDouble(),
      plantSpacingCm: plant.clamp(5, 200).toDouble(),
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
                      'Kurulum bilgisi bakım planını hesaplar; sulama kaydı oluşturmaz',
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
            const SizedBox(height: 4),
            const Text(
              'Bu seçim nasıl sulanacağını ve takvim aralığını belirler; Tarlam Günlüğü’ne sulama yapılmış gibi kayıt düşmez.',
              style:
                  TextStyle(color: Colors.white54, fontSize: 11, height: 1.35),
            ),
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

            // ── Tarım Şekli ──
            _sectionLabel('🏛️ Tarım Şekli'),
            const SizedBox(height: 4),
            const Text(
              'Seçenekler T.C. Tarım ve Orman Bakanlığı destek/uygulama başlıkları esas alınarak sadeleştirildi.',
              style:
                  TextStyle(color: Colors.white54, fontSize: 11, height: 1.35),
            ),
            const SizedBox(height: 8),
            ...ProductionSystem.values.map((system) {
              final selected = _productionSystem == system;
              return GestureDetector(
                onTap: () => setState(() => _productionSystem = system),
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
                    Icon(system.icon,
                        color: selected ? _accent : Colors.white38, size: 22),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(system.label,
                              style: TextStyle(
                                color: selected ? _accent : Colors.white,
                                fontSize: 14,
                                fontWeight: selected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                              )),
                          Text(system.description,
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

            // ── Tarla Alanı (otomatik, salt-okunur) ──
            // Eskiden manuel "Dekar" input'u vardı; tarla poligonu zaten alanı
            // belirlediği için kullanıcının yazdığı sayı geçersiz kalıyordu.
            // Şimdi alanı bilgi olarak gösteriyoruz; gerçek değer poligondan.
            _sectionLabel('📐 Tarla Alanı'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: _card,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white12),
              ),
              child: Row(children: [
                const Icon(Icons.straighten_rounded,
                    color: Colors.white54, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '${widget.fieldAreaDekar.toStringAsFixed(1)} da · tarladan otomatik alındı',
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 13, height: 1.3),
                  ),
                ),
              ]),
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
                  onChanged: (_) => setState(() {}),
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
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ]),
            const SizedBox(height: 8),
            const Text(
              'Bu aralıklar ekim bölgesindeki bitki dizilimine, bitki sayısı hesabına ve sonraki bakım planına uygulanır.',
              style:
                  TextStyle(color: Colors.white54, fontSize: 11, height: 1.35),
            ),
            const SizedBox(height: 16),

            // ── Opsiyonel hedef bitki adedi ──
            _sectionLabel('🌱 Kaç Adet Ekeceksin?'),
            const SizedBox(height: 8),
            _inputField(
              controller: _plantCountCtrl,
              label: 'Bitki adedi',
              hint: 'Boş bırakılabilir',
              suffix: 'adet',
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 8),
            Builder(builder: (_) {
              final targetDekar = _targetDekarPreview();
              final estimatedCount = _estimatedCountForCurrentSpacing();
              final targetText = targetDekar == null
                  ? 'Adet girmezsen tüm ekim alanı için yaklaşık $estimatedCount bitki hesaplanır.'
                  : 'Bu adet için yaklaşık ${targetDekar.toStringAsFixed(2)} da ekim alanı gerekir.';
              final overLimit =
                  targetDekar != null && targetDekar > widget.fieldAreaDekar;
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: overLimit
                      ? Colors.red.withValues(alpha: 0.10)
                      : _accent.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: overLimit
                        ? Colors.red.withValues(alpha: 0.35)
                        : _accent.withValues(alpha: 0.20),
                  ),
                ),
                child: Text(
                  targetText,
                  style: TextStyle(
                    color: overLimit ? Colors.red.shade200 : Colors.white70,
                    fontSize: 11,
                    height: 1.35,
                  ),
                ),
              );
            }),

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
    ValueChanged<String>? onChanged,
  }) =>
      TextField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        onChanged: onChanged,
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

// ═══════════════════════════════════════════════════════════════════════
// PUSULA YÖN SEÇİCİ — 3x3 ızgara, ortada boşluk
// ═══════════════════════════════════════════════════════════════════════
double _directionDegrees(PlantFacingDirection direction) {
  return switch (direction) {
    PlantFacingDirection.north => 0.0,
    PlantFacingDirection.northeast => 45.0,
    PlantFacingDirection.east => 90.0,
    PlantFacingDirection.southeast => 135.0,
    PlantFacingDirection.south => 180.0,
    PlantFacingDirection.southwest => 225.0,
    PlantFacingDirection.west => 270.0,
    PlantFacingDirection.northwest => 315.0,
  };
}

double _degreesFromFacingRaw(String? raw) {
  final value = raw?.trim();
  if (value == null || value.isEmpty) return 180.0;
  if (value.startsWith('deg:')) {
    final parsed = double.tryParse(value.substring(4));
    if (parsed != null) return parsed % 360.0;
  }
  for (final direction in PlantFacingDirection.values) {
    if (direction.name == value) return _directionDegrees(direction);
  }
  return 180.0;
}

String _facingRawFromDegrees(double degrees) {
  final clean = degrees.round() % 360;
  return 'deg:$clean';
}

String _facingDirectionLabel(String raw) {
  final degrees = _degreesFromFacingRaw(raw).round() % 360;
  for (final direction in PlantFacingDirection.values) {
    if (direction.name == raw) {
      return '${direction.label} ${direction.arrow} ($degrees°)';
    }
  }
  return '$degrees° açı';
}

class _DirectionPicker extends StatelessWidget {
  const _DirectionPicker({
    required this.selectedDegrees,
    required this.hasSelection,
    required this.onChanged,
    required this.accent,
    required this.card,
  });

  final double selectedDegrees;
  final bool hasSelection;
  final ValueChanged<double?> onChanged;
  final Color accent;
  final Color card;

  // 3x3 ızgara sırası: [KK, K, KD, B, null(merkez), D, GB, G, GD]
  static const _grid = [
    PlantFacingDirection.northwest,
    PlantFacingDirection.north,
    PlantFacingDirection.northeast,
    PlantFacingDirection.west,
    null, // merkez — boş
    PlantFacingDirection.east,
    PlantFacingDirection.southwest,
    PlantFacingDirection.south,
    PlantFacingDirection.southeast,
  ];

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 6,
      crossAxisSpacing: 6,
      childAspectRatio: 1.6,
      children: _grid.map((dir) {
        if (dir == null) {
          // Merkez hücre — pusula simgesi
          return GestureDetector(
            onTap: () => onChanged(null),
            child: Center(
              child:
                  Icon(Icons.explore_rounded, color: Colors.white24, size: 28),
            ),
          );
        }
        final degrees = _directionDegrees(dir);
        final isSelected =
            hasSelection && (selectedDegrees.round() % 360) == degrees.round();
        return GestureDetector(
          onTap: () => onChanged(isSelected ? null : degrees),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            decoration: BoxDecoration(
              color: isSelected ? accent.withValues(alpha: 0.18) : card,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected ? accent : Colors.white12,
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  dir.arrow,
                  style: TextStyle(
                    fontSize: 16,
                    color: isSelected ? accent : Colors.white54,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  dir.shortLabel,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight:
                        isSelected ? FontWeight.w700 : FontWeight.normal,
                    color: isSelected ? accent : Colors.white54,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// BAKAN YÖN SEÇİM SAYFASI — her bitki ekleme akışında ayrı olarak açılır
// ═══════════════════════════════════════════════════════════════════════
class _AngleSlider extends StatelessWidget {
  const _AngleSlider({
    required this.angleDegrees,
    required this.hasSelection,
    required this.accent,
    required this.onChanged,
  });

  final double angleDegrees;
  final bool hasSelection;
  final Color accent;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final rounded = angleDegrees.round() % 360;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
      decoration: BoxDecoration(
        color: const Color(0xFF101A14),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.threesixty_rounded,
                  color: Colors.white70, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  hasSelection ? 'Serbest açı: $rounded°' : 'Serbest açı',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                'K 0°',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.55),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: accent,
              inactiveTrackColor: Colors.white12,
              thumbColor: accent,
              overlayColor: accent.withValues(alpha: 0.16),
              valueIndicatorColor: accent,
              valueIndicatorTextStyle: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w800,
              ),
            ),
            child: Slider(
              min: 0,
              max: 359,
              divisions: 359,
              value: angleDegrees.clamp(0.0, 359.0).toDouble(),
              label: '$rounded°',
              onChanged: onChanged,
            ),
          ),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Kuzey',
                  style: TextStyle(color: Colors.white54, fontSize: 11)),
              Text('Doğu',
                  style: TextStyle(color: Colors.white54, fontSize: 11)),
              Text('Güney',
                  style: TextStyle(color: Colors.white54, fontSize: 11)),
              Text('Batı',
                  style: TextStyle(color: Colors.white54, fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }
}

class _FacingDirectionPreview extends StatelessWidget {
  const _FacingDirectionPreview({
    required this.plantName,
    required this.rawDirection,
    required this.angleDegrees,
    required this.hasSelection,
    required this.accent,
    required this.card,
  });

  final String plantName;
  final String? rawDirection;
  final double angleDegrees;
  final bool hasSelection;
  final Color accent;
  final Color card;

  @override
  Widget build(BuildContext context) {
    final resolvedRaw = rawDirection ?? _facingRawFromDegrees(angleDegrees);
    final label =
        hasSelection ? _facingDirectionLabel(resolvedRaw) : 'Yön seçilmedi';
    return Container(
      height: 118,
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            height: 118,
            child: Center(
              child: SizedBox(
                width: 88,
                height: 104,
                child: buildCropMarkerWidget(
                  cropName: plantName,
                  cropColor: accent,
                  maturityPercent: 82,
                  facingDirection: hasSelection ? resolvedRaw : null,
                ),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(right: 14),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Bu ekim grubundaki tüm bitkiler aynı yöne döner.',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white60,
                      fontSize: 12,
                      height: 1.25,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FacingDirectionSheet extends StatefulWidget {
  const _FacingDirectionSheet({
    required this.plantName,
    this.initialRaw,
  });

  final String plantName;
  final String? initialRaw;

  @override
  State<_FacingDirectionSheet> createState() => _FacingDirectionSheetState();
}

class _FacingDirectionSheetState extends State<_FacingDirectionSheet> {
  late double _angleDegrees;
  late bool _hasSelection;

  static const _bg = Color(0xFF0D1811);
  static const _accent = Color(0xFF00E676);
  static const _card = Color(0xFF152018);

  @override
  void initState() {
    super.initState();
    _angleDegrees = _degreesFromFacingRaw(widget.initialRaw);
    _hasSelection = widget.initialRaw != null && widget.initialRaw!.isNotEmpty;
  }

  String? get _selectedRaw =>
      _hasSelection ? _facingRawFromDegrees(_angleDegrees) : null;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
            Row(children: [
              const Icon(Icons.explore_rounded, color: _accent, size: 26),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${widget.plantName} hangi yöne baksın?',
                      style: GoogleFonts.outfit(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Güneş maruziyeti ve mikro-iklim için kullanılır.',
                      style: TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ]),
            const SizedBox(height: 18),
            _DirectionPicker(
              selectedDegrees: _angleDegrees,
              hasSelection: _hasSelection,
              onChanged: (degrees) => setState(() {
                if (degrees == null) {
                  _hasSelection = false;
                  return;
                }
                _angleDegrees = degrees;
                _hasSelection = true;
              }),
              accent: _accent,
              card: _card,
            ),
            const SizedBox(height: 14),
            _AngleSlider(
              angleDegrees: _angleDegrees,
              hasSelection: _hasSelection,
              accent: _accent,
              onChanged: (degrees) => setState(() {
                _angleDegrees = degrees;
                _hasSelection = true;
              }),
            ),
            const SizedBox(height: 14),
            _FacingDirectionPreview(
              plantName: widget.plantName,
              rawDirection: _selectedRaw,
              angleDegrees: _angleDegrees,
              hasSelection: _hasSelection,
              accent: _accent,
              card: _card,
            ),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context, _SkipDirection()),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white24),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Atla',
                      style: TextStyle(color: Colors.white70)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context, _selectedRaw),
                  icon: const Icon(Icons.check_rounded, size: 18),
                  label: Text(
                    _hasSelection ? 'Onayla' : 'Devam Et',
                    style: GoogleFonts.outfit(
                        fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _accent,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }
}

// "Atla" sentinel — kullanıcı yön belirtmek istemediğinde döner.
class _SkipDirection {}

/// Yön seçim diyaloğunu gösterir. Dönüş değeri:
///   - String: kullanıcı derece tabanlı bir yön seçti
///   - null: kullanıcı sheet'i swipe-to-dismiss ile kapattı (iptal)
///   - _SkipDirection: "Atla" — yön kaydedilmeyecek (null olarak gönder)
Future<String?> _askFacingDirection(
  BuildContext context, {
  required String plantName,
  String? initialRaw,
}) async {
  final result = await _showFacingDirectionSheet(
    context,
    plantName: plantName,
    initialRaw: initialRaw,
  );
  if (result is String) return result;
  return null;
}

Future<Object?> _showFacingDirectionSheet(
  BuildContext context, {
  required String plantName,
  String? initialRaw,
}) {
  return showModalBottomSheet<Object?>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) =>
        _FacingDirectionSheet(plantName: plantName, initialRaw: initialRaw),
  );
}
