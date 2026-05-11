/// Tarla Takip Ekranı — yönerge merkezli, dört sekmeli canlı görünüm.
///
/// Geçmiş kayıt listeleri burada gösterilmez (kayıt geçmişi tarlam günlüğü
/// ekranındadır). Her sekme bugünün yönergesini ve canlı tavsiyeleri
/// gösterir; bir aktivite eklendiğinde `clearOnActivities` mekanizması
/// (live_todo_service.dart) ilgili tavsiyeyi düşürür ve yerine bir
/// sonraki adım yönergesi çıkar.
///
///   • Genel: bitki sağlık durumu özeti + tüm canlı tavsiyeler.
///   • Sulama: her ekili bitki için bugünün su hedefi (mm + L/bitki) ve
///     uygulama prensipleri.
///   • Gübreleme: dönem bazlı gübreleme yönergesi + canlı tavsiyeler.
///   • Hastalık: tedavi gereken bitkiler → tedavi protokolü kısayolu;
///     hasta bitki yoksa önleyici kontrol listesi.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/activity_types.dart';
import '../data/app_database.dart';
import '../data/disease_advice.dart';
import '../data/turkiye_crop_guides.dart';
import '../services/app_providers.dart';
import '../services/crop_daily_plan.dart';
import '../services/rules/recommendation.dart';
import '../theme/app_theme.dart';
import '../widgets/activity_quick_log.dart';
import '../widgets/floating_toast.dart';
import '../widgets/recommendation_card.dart';
import 'treatment_protocol_screen.dart';

class FieldTrackingScreen extends ConsumerStatefulWidget {
  const FieldTrackingScreen({
    super.key,
    required this.fieldId,
    required this.fieldName,
    this.initialTab = 0,
  });

  final String fieldId;
  final String fieldName;
  final int initialTab;

  @override
  ConsumerState<FieldTrackingScreen> createState() =>
      _FieldTrackingScreenState();
}

enum _CategoryKind { watering, fertilizing, disease }

class _FieldTrackingScreenState extends ConsumerState<FieldTrackingScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(
      length: 4,
      vsync: this,
      initialIndex: widget.initialTab.clamp(0, 3),
    );
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Takip'),
            Text(
              widget.fieldName,
              style: AppText.xs(context),
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tab,
          isScrollable: true,
          labelColor: AppColors.emeraldDark,
          unselectedLabelColor: AppColors.textTertiary,
          indicatorColor: AppColors.emerald,
          tabs: const [
            Tab(icon: Icon(Icons.monitor_heart_rounded), text: 'Genel'),
            Tab(icon: Icon(Icons.water_drop_rounded), text: 'Sulama'),
            Tab(icon: Icon(Icons.grass_rounded), text: 'Gübreleme'),
            Tab(icon: Icon(Icons.coronavirus_rounded), text: 'Hastalık'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: [
          _GeneralTab(fieldId: widget.fieldId, fieldName: widget.fieldName),
          _CategoryTab(
            fieldId: widget.fieldId,
            fieldName: widget.fieldName,
            title: 'Sulama',
            emptyText:
                'Bugün için açık sulama tavsiyesi yok. Yağış, toprak nemi ve son sulama kayıtları hedefi karşılıyor.',
            recommendationTypes: const {ActivityType.watering},
            accentColor: AppColors.frost,
            kind: _CategoryKind.watering,
          ),
          _CategoryTab(
            fieldId: widget.fieldId,
            fieldName: widget.fieldName,
            title: 'Gübreleme',
            emptyText:
                'Bugün için açık gübreleme tavsiyesi yok. Bir sonraki gübreleme dönemi yaklaştığında otomatik yönerge çıkar.',
            recommendationTypes: const {ActivityType.fertilizing},
            accentColor: AppColors.emeraldDark,
            kind: _CategoryKind.fertilizing,
          ),
          _CategoryTab(
            fieldId: widget.fieldId,
            fieldName: widget.fieldName,
            title: 'Hastalık ve Zararlı',
            emptyText:
                'Bugün için açık hastalık/zararlı tavsiyesi yok. Yine de yapraklar haftada bir gözle kontrol edilmelidir.',
            recommendationTypes: const {
              ActivityType.spraying,
              ActivityType.scouting,
            },
            accentColor: AppColors.warning,
            kind: _CategoryKind.disease,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// GENEL — bitki sağlık + tüm tavsiyeler
// ─────────────────────────────────────────────────────────────────────────────

class _GeneralTab extends ConsumerStatefulWidget {
  const _GeneralTab({required this.fieldId, required this.fieldName});
  final String fieldId;
  final String fieldName;

  @override
  ConsumerState<_GeneralTab> createState() => _GeneralTabState();
}

class _GeneralTabState extends ConsumerState<_GeneralTab> {
  List<Recommendation>? _recs;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _loadRecs();
  }

  Future<void> _loadRecs() async {
    _timer = Timer(const Duration(seconds: 3), () {
      if (mounted && _recs == null) setState(() => _recs = []);
    });
    try {
      final recs =
          await ref.read(fieldLiveTodosProvider(widget.fieldId).future);
      if (mounted) {
        _timer?.cancel();
        setState(() => _recs = recs);
      }
    } catch (_) {
      if (mounted) setState(() => _recs = []);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final growthAsync = ref.watch(fieldGrowthStatesProvider(widget.fieldId));
    final plantsAsync = ref.watch(fieldPlantInstancesProvider(widget.fieldId));

    final growthList = growthAsync.valueOrNull ?? const <CropGrowthState>[];
    final plants = plantsAsync.valueOrNull ?? const <FieldPlantInstance>[];

    final diseasedCount =
        plants.where((p) => p.healthStatus == 'diseased').length;
    final treatingCount =
        plants.where((p) => p.healthStatus == 'treating').length;
    final recs = _recs;

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(fieldLiveTodosProvider(widget.fieldId));
        await _loadRecs();
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          _StatusStripCompact(
            growthList: growthList,
            diseasedCount: diseasedCount,
            treatingCount: treatingCount,
          ),
          const SizedBox(height: 12),
          _ActivityLinkBanner(),
          const SizedBox(height: 12),
          _SectionLabel('CANLI TAVSİYELER'),
          const SizedBox(height: 8),
          if (recs == null)
            const _LoadingCard()
          else if (recs.isEmpty)
            _EmptyCard(
              icon: Icons.check_circle_outline_rounded,
              text:
                  'Şu an açık tavsiye yok. Sulama, gübreleme ve hastalık sekmelerinden bugünün yönergesini gözden geçirebilirsin.',
            )
          else
            for (final r in recs) ...[
              RecommendationCard(recommendation: r),
              const SizedBox(height: 8),
            ],
          const SizedBox(height: 18),
          _QuickLogButton(
            fieldId: widget.fieldId,
            label: 'Aktivite ekle',
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// KATEGORİ — Sulama / Gübreleme / Hastalık ortak şablon
// ─────────────────────────────────────────────────────────────────────────────

class _CategoryTab extends ConsumerWidget {
  const _CategoryTab({
    required this.fieldId,
    required this.fieldName,
    required this.title,
    required this.emptyText,
    required this.recommendationTypes,
    required this.accentColor,
    required this.kind,
  });

  final String fieldId;
  final String fieldName;
  final String title;
  final String emptyText;
  final Set<String> recommendationTypes;
  final Color accentColor;
  final _CategoryKind kind;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recsAsync = ref.watch(fieldLiveTodosProvider(fieldId));
    final plantsAsync = ref.watch(fieldPlantInstancesProvider(fieldId));

    final allRecs = recsAsync.valueOrNull ?? const <Recommendation>[];
    final filteredRecs = allRecs.where((r) {
      final cmdType = r.command?.activityType;
      return cmdType != null && recommendationTypes.contains(cmdType);
    }).toList();

    final plants = plantsAsync.valueOrNull ?? const <FieldPlantInstance>[];
    final diseased =
        plants.where((p) => p.healthStatus == 'diseased').toList();
    final treating =
        plants.where((p) => p.healthStatus == 'treating').toList();

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(fieldLiveTodosProvider(fieldId));
        ref.invalidate(fieldActivityLogProvider(fieldId));
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          _CategoryHeader(
            title: title,
            color: accentColor,
            recCount: filteredRecs.length,
          ),
          const SizedBox(height: 14),
          if (kind == _CategoryKind.watering) ...[
            _SectionLabel('BUGÜNÜN SULAMA YÖNERGESİ'),
            const SizedBox(height: 8),
            _WateringGuidanceSection(fieldId: fieldId),
            const SizedBox(height: 14),
          ],
          if (kind == _CategoryKind.fertilizing) ...[
            _SectionLabel('GÜBRELEME YÖNERGESİ'),
            const SizedBox(height: 8),
            _FertilizationGuidanceSection(fieldId: fieldId),
            const SizedBox(height: 14),
          ],
          if (kind == _CategoryKind.disease) ...[
            if (diseased.isNotEmpty || treating.isNotEmpty) ...[
              _HealthSummaryCard(
                diseased: diseased.length,
                treating: treating.length,
              ),
              const SizedBox(height: 14),
              _SectionLabel('TEDAVİ GEREKEN BİTKİLER'),
              const SizedBox(height: 8),
              for (final plant in [...diseased, ...treating])
                _DiseasedPlantCard(
                  plant: plant,
                  fieldId: fieldId,
                  fieldName: fieldName,
                ),
            ] else ...[
              _SectionLabel('ÖNLEYİCİ KONTROL LİSTESİ'),
              const SizedBox(height: 8),
              _HealthPreventiveCard(),
            ],
            const SizedBox(height: 14),
          ],
          _SectionLabel('CANLI TAVSİYELER'),
          const SizedBox(height: 8),
          if (recsAsync.isLoading)
            const _LoadingCard()
          else if (filteredRecs.isEmpty)
            _EmptyCard(icon: Icons.check_circle_outline_rounded, text: emptyText)
          else
            for (final r in filteredRecs) ...[
              RecommendationCard(recommendation: r),
              const SizedBox(height: 8),
            ],
          const SizedBox(height: 18),
          _QuickLogButton(
            fieldId: fieldId,
            label: 'Aktivite ekle',
            color: accentColor,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ALT BİLEŞENLER
// ─────────────────────────────────────────────────────────────────────────────

class _CategoryHeader extends StatelessWidget {
  const _CategoryHeader({
    required this.title,
    required this.color,
    required this.recCount,
  });

  final String title;
  final Color color;
  final int recCount;

  @override
  Widget build(BuildContext context) {
    final label = recCount == 0
        ? 'Aktif yönerge yok · kayıt geçmişi Tarlam Günlüğü\'nde'
        : '$recCount canlı tavsiye · kayıt geçmişi Tarlam Günlüğü\'nde';
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: AppRadius.md,
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppText.h3(context).copyWith(color: color)),
                const SizedBox(height: 4),
                Text(label, style: AppText.sm(context)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Hasta veya tedavi sürecindeki bitki için tam tedavi yönetim kartı.
///
/// Durum makinesi:
///   'diseased'  → kırmızı kart, aktif madde listesi, "Tedaviyi Başlat"
///   'treating'  → turuncu kart, N. gün / toplam, bir sonraki uygulama sayacı
///
/// CLAUDE.md §17: aktif maddeler disease_advice.dart'tan (TAGEM kaynaklı).
/// Doz/PHI için BKÜ doğrulama kapısı her zaman görünür.
class _DiseaseTreatmentCard extends ConsumerStatefulWidget {
  const _DiseaseTreatmentCard({
    required this.plant,
    required this.fieldId,
    required this.fieldName,
  });

  final FieldPlantInstance plant;
  final String fieldId;
  final String fieldName;

  @override
  ConsumerState<_DiseaseTreatmentCard> createState() =>
      _DiseaseTreatmentCardState();
}

class _DiseaseTreatmentCardState
    extends ConsumerState<_DiseaseTreatmentCard> {
  bool _busy = false;

  String get _diseaseLabel =>
      widget.plant.diseaseType?.trim().isNotEmpty == true
          ? widget.plant.diseaseType!.trim()
          : 'Belirti gözlendi';

  bool get _isTreating => widget.plant.healthStatus == 'treating';

  // TAGEM Zirai Mücadele Teknik Talimatları kaynaklı genel uygulama aralıkları
  // (disease_advice.dart'taki chemicalTreatments metinleriyle tutarlı)
  static int _intervalDays(String name) {
    final n = name.toLowerCase();
    if (n.contains('mildiyö')) return 7;
    if (n.contains('külleme')) return 7;
    if (n.contains('pas')) return 7;
    if (n.contains('yaprak lekesi')) return 10;
    if (n.contains('antraknoz')) return 7;
    if (n.contains('bakteriyel')) return 10;
    if (n.contains('kök çürüklüğü')) return 14;
    return 10;
  }

  static int _totalApplications(String name) {
    final n = name.toLowerCase();
    if (n.contains('mozaik') || n.contains('virüs')) return 0; // no chemical
    if (n.contains('mildiyö') || n.contains('külleme')) return 3;
    if (n.contains('pas') || n.contains('antraknoz')) return 2;
    return 2;
  }

  // Son ilaçlama tarihini ve başlangıç tarihini aktivite logdan çek
  DateTime? _treatmentStart(List<Map<String, dynamic>> activities) {
    final sprays = activities
        .where((a) =>
            a['type'] == ActivityType.spraying &&
            (a['crop_id'] == null ||
                a['crop_id'] == widget.plant.cropId))
        .toList();
    if (sprays.isEmpty) return null;
    final last = sprays.first; // en yeni en başta
    final raw = last['date'];
    if (raw is DateTime) return raw;
    if (raw is String) return DateTime.tryParse(raw);
    return null;
  }

  // Tedaviyi başlat: spraying log + healthStatus → 'treating'
  Future<void> _startTreatment() async {
    setState(() => _busy = true);
    try {
      final repo = ref.read(localDataRepositoryProvider);
      final field = await repo.loadFieldById(widget.fieldId);
      final areaDekar = (field?['area_dekar'] as num?)?.toDouble() ?? 1.0;
      if (!mounted) return;

      // Aktivite log
      await ref.read(activityLoggerProvider).log(
        fieldId: widget.fieldId,
        type: ActivityType.spraying,
        cropId: widget.plant.cropId,
        plantInstanceId: widget.plant.id,
        note: '${_diseaseLabel} tedavisi — 1. uygulama',
        metadata: {
          'disease_name': _diseaseLabel,
          'treatment_start': true,
          'interval_days': _intervalDays(_diseaseLabel),
          'total_applications': _totalApplications(_diseaseLabel),
          'bku_check_required': true,
          'expert_confirmation_required': true,
        },
      );

      // Sağlık durumunu 'treating' yap
      await repo.setPlantHealth(
        instanceId: widget.plant.id,
        healthStatus: 'treating',
        diseaseType: _diseaseLabel,
        notes: 'Tedavi başlatıldı — ${DateTime.now().toLocal()}',
        writeActivityLog: false,
      );

      if (!mounted) return;
      AppToast.show(
        context,
        message: 'Tedavi başlatıldı. 1. uygulama kaydedildi.',
        type: ToastType.success,
      );
    } catch (e) {
      if (!mounted) return;
      AppToast.show(
        context,
        message: 'Kayıt başarısız: $e',
        type: ToastType.error,
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  // Sonraki uygulamayı kaydet
  Future<void> _logNextApplication(int appNumber) async {
    setState(() => _busy = true);
    try {
      await ref.read(activityLoggerProvider).log(
        fieldId: widget.fieldId,
        type: ActivityType.spraying,
        cropId: widget.plant.cropId,
        plantInstanceId: widget.plant.id,
        note: '$_diseaseLabel tedavisi — $appNumber. uygulama',
        metadata: {
          'disease_name': _diseaseLabel,
          'application_number': appNumber,
          'bku_check_required': true,
        },
      );
      if (!mounted) return;
      AppToast.show(
        context,
        message: '$appNumber. uygulama kaydedildi.',
        type: ToastType.success,
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  // Tedaviyi tamamla: sağlık durumunu 'healthy' yap
  Future<void> _completeTreatment() async {
    setState(() => _busy = true);
    try {
      await ref.read(localDataRepositoryProvider).setPlantHealth(
        instanceId: widget.plant.id,
        healthStatus: 'healthy',
        notes: 'Tedavi tamamlandı',
      );
      if (!mounted) return;
      AppToast.show(
        context,
        message: 'Bitki sağlıklı olarak işaretlendi.',
        type: ToastType.success,
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final activitiesAsync = ref.watch(fieldActivityLogProvider(widget.fieldId));
    final activities = activitiesAsync.valueOrNull ?? const [];
    final advice = DiseaseAdvice.forName(_diseaseLabel);
    final intervalDays = _intervalDays(_diseaseLabel);
    final totalApps = _totalApplications(_diseaseLabel);
    final totalDays = intervalDays * (totalApps > 0 ? totalApps - 1 : 1);

    final treatStart = _treatmentStart(activities);
    final daysSinceStart = treatStart != null
        ? DateTime.now().difference(treatStart).inDays
        : null;
    final sprayCount = activities
        .where((a) =>
            a['type'] == ActivityType.spraying &&
            (a['crop_id'] == null || a['crop_id'] == widget.plant.cropId))
        .length;
    final nextAppDaysLeft = treatStart != null
        ? intervalDays - DateTime.now().difference(treatStart).inDays % intervalDays
        : null;
    final isOverdue = nextAppDaysLeft != null && nextAppDaysLeft <= 0;

    final headerColor = _isTreating ? AppColors.warning : AppColors.error;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.md,
        border: Border.all(color: headerColor.withValues(alpha: 0.4), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Başlık şeridi ──────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: headerColor.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                Icon(
                  _isTreating ? Icons.healing_rounded : Icons.coronavirus_rounded,
                  color: headerColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.plant.cropName,
                        style: AppText.bodyMd(context),
                      ),
                      Text(
                        _diseaseLabel,
                        style: AppText.sm(context).copyWith(color: headerColor),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: headerColor,
                    borderRadius: AppRadius.full,
                  ),
                  child: Text(
                    _isTreating ? 'TEDAVİDE' : 'HASTA',
                    style: AppText.xs(context)
                        .copyWith(color: AppColors.textOnDark),
                  ),
                ),
              ],
            ),
          ),
          // ── Gövde ──────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_isTreating) ...[
                  _TreatmentProgressBar(
                    daysSince: daysSinceStart ?? 0,
                    totalDays: totalDays,
                    sprayCount: sprayCount,
                    totalApps: totalApps,
                    intervalDays: intervalDays,
                    nextAppDaysLeft: nextAppDaysLeft ?? intervalDays,
                    isOverdue: isOverdue,
                  ),
                  const SizedBox(height: 14),
                ] else ...[
                  _UrgencyNote(advice: advice),
                  const SizedBox(height: 10),
                  _ActiveIngredientsCard(advice: advice),
                  const SizedBox(height: 10),
                  _IsolationStepsCard(advice: advice),
                  const SizedBox(height: 4),
                ],
                // ── BKÜ doğrulama uyarısı (her zaman) ─────────────────
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.errorBg,
                    borderRadius: AppRadius.sm,
                    border: Border.all(
                        color: AppColors.error.withValues(alpha: 0.35)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.policy_rounded,
                          color: AppColors.error, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Ruhsatlı ürün adı, etiket dozu ve PHI için '
                          'bku.tarim.gov.tr\'yi kontrol et. '
                          'Teşhis ve uygulama kararı için ziraat mühendisi onayı şart.',
                          style: AppText.xs(context),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                // ── Aksiyon butonları ───────────────────────────────────
                if (!_isTreating)
                  _ActionButton(
                    label: 'Tedaviyi Başlat — 1. uygulamayı kaydet',
                    icon: Icons.play_circle_fill_rounded,
                    color: AppColors.error,
                    busy: _busy,
                    onPressed: _startTreatment,
                  )
                else ...[
                  if (sprayCount < totalApps || isOverdue)
                    _ActionButton(
                      label: isOverdue
                          ? 'Gecikmiş uygulama — ${sprayCount + 1}. uygulamayı kaydet'
                          : '${sprayCount + 1}. uygulamayı kaydet'
                              '${nextAppDaysLeft != null && nextAppDaysLeft > 0 ? ' ($nextAppDaysLeft gün sonra)' : ''}',
                      icon: Icons.science_rounded,
                      color: isOverdue ? AppColors.error : AppColors.warning,
                      busy: _busy,
                      onPressed: isOverdue || nextAppDaysLeft == null || nextAppDaysLeft <= 0
                          ? () => _logNextApplication(sprayCount + 1)
                          : null,
                    ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _busy
                              ? null
                              : () => Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => TreatmentProtocolScreen(
                                        fieldId: widget.fieldId,
                                        fieldName: widget.fieldName,
                                        cropName: widget.plant.cropName,
                                        diseaseName: _diseaseLabel,
                                        plantInstanceId: widget.plant.id,
                                      ),
                                    ),
                                  ),
                          icon: const Icon(Icons.menu_book_rounded, size: 16),
                          label: const Text('Tam protokol'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.success,
                          ),
                          onPressed: _busy ? null : _completeTreatment,
                          icon: const Icon(Icons.check_circle_outline_rounded,
                              size: 16),
                          label: const Text('İyileşti'),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Tedavi ilerleme çubuğu ──────────────────────────────────────────────────

class _TreatmentProgressBar extends StatelessWidget {
  const _TreatmentProgressBar({
    required this.daysSince,
    required this.totalDays,
    required this.sprayCount,
    required this.totalApps,
    required this.intervalDays,
    required this.nextAppDaysLeft,
    required this.isOverdue,
  });

  final int daysSince;
  final int totalDays;
  final int sprayCount;
  final int totalApps;
  final int intervalDays;
  final int nextAppDaysLeft;
  final bool isOverdue;

  @override
  Widget build(BuildContext context) {
    final progress =
        totalDays > 0 ? (daysSince / totalDays).clamp(0.0, 1.0) : 0.0;
    final nextLabel = isOverdue
        ? 'Bir sonraki uygulama gecikmiş!'
        : nextAppDaysLeft == 0
            ? 'Bugün ilaçlama günü!'
            : '$nextAppDaysLeft gün sonra ${sprayCount + 1}. uygulama';
    final barColor = isOverdue ? AppColors.error : AppColors.warning;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                '${daysSince}. gün / ~$totalDays gün tedavi',
                style: AppText.bodyMd(context),
              ),
            ),
            Text(
              '$sprayCount/$totalApps uygulama',
              style: AppText.xs(context)
                  .copyWith(color: AppColors.warning),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: AppRadius.full,
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            backgroundColor: AppColors.warning.withValues(alpha: 0.15),
            valueColor: AlwaysStoppedAnimation<Color>(barColor),
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: barColor.withValues(alpha: 0.1),
            borderRadius: AppRadius.sm,
            border: Border.all(color: barColor.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Icon(Icons.schedule_rounded, color: barColor, size: 14),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  nextLabel,
                  style: AppText.sm(context).copyWith(color: barColor),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Her $intervalDays günde bir uygulama (TAGEM/Zirai Mücadele Teknik Talimatı). '
          'Etikette farklı süre varsa etiket geçerlidir.',
          style: AppText.xs(context),
        ),
      ],
    );
  }
}

// ── Aciliyet notu ────────────────────────────────────────────────────────────

class _UrgencyNote extends StatelessWidget {
  const _UrgencyNote({required this.advice});
  final DiseaseAdvice advice;

  @override
  Widget build(BuildContext context) {
    final color = switch (advice.urgency) {
      'Çok Yüksek' => AppColors.error,
      'Yüksek' => const Color(0xFFD32F2F),
      'Orta' => AppColors.warning,
      _ => AppColors.info,
    };
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: AppRadius.sm,
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: color, size: 16),
              const SizedBox(width: 6),
              Text(
                'Aciliyet: ${advice.urgency} · ${advice.pathogenType}'
                '${advice.contagious ? ' · BULAŞICI' : ''}',
                style: AppText.xs(context).copyWith(color: color),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(advice.spreadMechanism, style: AppText.xs(context)),
        ],
      ),
    );
  }
}

// ── Aktif madde listesi (TAGEM kaynaklı, BKÜ kapısı ile) ───────────────────

class _ActiveIngredientsCard extends StatelessWidget {
  const _ActiveIngredientsCard({required this.advice});
  final DiseaseAdvice advice;

  @override
  Widget build(BuildContext context) {
    final chems = advice.chemicalTreatments;
    if (chems.isEmpty ||
        (chems.length == 1 && chems.first.toUpperCase().startsWith('VİRÜS'))) {
      return Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.infoBg,
          borderRadius: AppRadius.sm,
        ),
        child: Text(
          chems.isEmpty
              ? 'Bu hastalık için kimyasal mücadele bilgisi mevcut değil. Kültürel önlemler uygulanmalı.'
              : chems.first,
          style: AppText.sm(context),
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E0),
        borderRadius: AppRadius.sm,
        border: Border.all(
            color: const Color(0xFFEF6C00).withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.medication_rounded,
                  color: Color(0xFFEF6C00), size: 16),
              const SizedBox(width: 6),
              Text(
                'Aktif madde referansları (TAGEM)',
                style: AppText.label(context)
                    .copyWith(color: const Color(0xFFEF6C00)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          for (final c in chems)
            if (!c.toUpperCase().startsWith('NOT'))
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('→ ',
                        style: TextStyle(
                            color: Color(0xFFEF6C00),
                            fontWeight: FontWeight.bold)),
                    Expanded(
                        child: Text(c, style: AppText.sm(context))),
                  ],
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(c,
                    style: AppText.xs(context)
                        .copyWith(color: AppColors.textSecondary)),
              ),
        ],
      ),
    );
  }
}

// ── Acil izolasyon adımları ──────────────────────────────────────────────────

class _IsolationStepsCard extends StatelessWidget {
  const _IsolationStepsCard({required this.advice});
  final DiseaseAdvice advice;

  @override
  Widget build(BuildContext context) {
    final steps = advice.isolationSteps.take(3).toList();
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.errorBg,
        borderRadius: AppRadius.sm,
        border:
            Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.report_problem_rounded,
                  color: AppColors.error, size: 16),
              const SizedBox(width: 6),
              Text('Önce bunları yap (acil izolasyon)',
                  style: AppText.label(context)
                      .copyWith(color: AppColors.error)),
            ],
          ),
          const SizedBox(height: 6),
          for (final s in steps)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('• ',
                      style: TextStyle(color: AppColors.error)),
                  Expanded(child: Text(s, style: AppText.sm(context))),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ── Aksiyon butonu ───────────────────────────────────────────────────────────

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.busy,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final Color color;
  final bool busy;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        style: FilledButton.styleFrom(
          backgroundColor: onPressed == null ? AppColors.textTertiary : color,
          foregroundColor: AppColors.textOnDark,
          minimumSize: const Size.fromHeight(48),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.sm),
        ),
        onPressed: busy ? null : onPressed,
        icon: busy
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white))
            : Icon(icon, size: 18),
        label: Text(label, textAlign: TextAlign.center),
      ),
    );
  }
}

class _HealthSummaryCard extends StatelessWidget {
  const _HealthSummaryCard({required this.diseased, required this.treating});
  final int diseased;
  final int treating;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.errorBg,
        borderRadius: AppRadius.sm,
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.coronavirus_rounded,
              color: AppColors.error, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bitki sağlığı dikkat istiyor',
                  style: AppText.bodyMd(context),
                ),
                const SizedBox(height: 2),
                Text(
                  '$diseased hasta, $treating tedavi sürecinde bitki var. '
                  'Kimyasal mücadele kararı için BKÜ ve uzman önerisi şart.',
                  style: AppText.sm(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusStripCompact extends StatelessWidget {
  const _StatusStripCompact({
    required this.growthList,
    required this.diseasedCount,
    required this.treatingCount,
  });

  final List<CropGrowthState> growthList;
  final int diseasedCount;
  final int treatingCount;

  @override
  Widget build(BuildContext context) {
    double avgWater = 0, avgDisease = 0, avgN = 0;
    if (growthList.isNotEmpty) {
      for (final g in growthList) {
        avgWater += g.waterDeficitMm;
        avgDisease += g.diseasePressure;
        avgN += g.nStressIdx;
      }
      avgWater /= growthList.length;
      avgDisease /= growthList.length;
      avgN /= growthList.length;
    }
    final hasHealthIssue = diseasedCount > 0 || treatingCount > 0;

    return Row(
      children: [
        _StatusDot(
          icon: Icons.water_drop_rounded,
          label: 'Su',
          value: _waterLabel(avgWater),
          color: _waterColor(avgWater),
        ),
        const SizedBox(width: 8),
        _StatusDot(
          icon: Icons.coronavirus_rounded,
          label: 'Sağlık',
          value: hasHealthIssue
              ? 'Riskli'
              : (avgDisease > 0.5 ? 'Gözle' : 'İyi'),
          color: hasHealthIssue || avgDisease > 0.5
              ? AppColors.error
              : AppColors.success,
        ),
        const SizedBox(width: 8),
        _StatusDot(
          icon: Icons.grass_rounded,
          label: 'Besin',
          value: avgN > 0.5 ? 'Düşük' : 'İyi',
          color: avgN > 0.5 ? AppColors.warning : AppColors.success,
        ),
      ],
    );
  }

  static String _waterLabel(double mm) {
    if (mm < 10) return 'İyi';
    if (mm < 25) return 'Açık';
    return 'Kritik';
  }

  static Color _waterColor(double mm) {
    if (mm < 10) return AppColors.success;
    if (mm < 25) return AppColors.warning;
    return AppColors.error;
  }
}

class _StatusDot extends StatelessWidget {
  const _StatusDot({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: AppRadius.sm,
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 14, color: color),
                const SizedBox(width: 4),
                Text(label, style: AppText.label(context)),
              ],
            ),
            const SizedBox(height: 2),
            Text(value,
                style: AppText.bodyMd(context)
                    .copyWith(fontSize: 14, color: color)),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SULAMA YÖNERGE BÖLÜMÜ — Her ekili bitki için bugünün su hedefi + L/bitki
// ─────────────────────────────────────────────────────────────────────────────

class _WateringGuidanceSection extends ConsumerWidget {
  const _WateringGuidanceSection({required this.fieldId});
  final String fieldId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cropsAsync = ref.watch(fieldCropsStreamProvider(fieldId));
    final activitiesAsync = ref.watch(fieldActivityLogProvider(fieldId));
    final growthAsync = ref.watch(fieldGrowthStatesProvider(fieldId));

    final crops = cropsAsync.valueOrNull ?? const <Map<String, dynamic>>[];
    final activities =
        activitiesAsync.valueOrNull ?? const <Map<String, dynamic>>[];
    final growthList = growthAsync.valueOrNull ?? const <CropGrowthState>[];

    if (crops.isEmpty) {
      return _EmptyCard(
        icon: Icons.eco_outlined,
        text:
            'Tarlaya henüz bitki eklenmemiş. Bitki eklediğinde günlük su hedefi burada görünür.',
      );
    }

    return FutureBuilder<double>(
      future: _loadAreaDekar(ref),
      builder: (context, snap) {
        final areaDekar = snap.data ?? 1.0;
        final planService = ref.read(cropDailyPlanServiceProvider);
        final cards = <Widget>[];
        for (final crop in crops) {
          CropGrowthState? growth;
          for (final g in growthList) {
            if (g.cropId == crop['id']?.toString()) {
              growth = g;
              break;
            }
          }
          final plan = planService.build(
            crop: crop,
            fieldId: fieldId,
            areaDekar: areaDekar,
            activities: activities,
            scheduledEvents: const [],
            dailyForecast: const [],
            growthState: _growthMap(growth),
          );
          cards.add(_WateringCropCard(
            crop: crop,
            plan: plan,
            areaDekar: areaDekar,
          ));
        }
        return Column(children: cards);
      },
    );
  }

  Future<double> _loadAreaDekar(WidgetRef ref) async {
    final field =
        await ref.read(localDataRepositoryProvider).loadFieldById(fieldId);
    return (field?['area_dekar'] as num?)?.toDouble() ?? 1.0;
  }

  Map<String, dynamic>? _growthMap(CropGrowthState? g) {
    if (g == null) return null;
    return {
      'stage_key': g.currentStageKey,
      'stage_progress': g.stageProgress,
      'accumulated_gdd': g.accumulatedGdd,
      'water_deficit_mm': g.waterDeficitMm,
    };
  }
}

class _WateringCropCard extends StatelessWidget {
  const _WateringCropCard({
    required this.crop,
    required this.plan,
    required this.areaDekar,
  });

  final Map<String, dynamic> crop;
  final CropDailyPlanResult? plan;
  final double areaDekar;

  @override
  Widget build(BuildContext context) {
    final cropName = crop['name']?.toString() ?? 'Bitki';
    final guide = TurkiyeCropGuides.lookup(cropName);
    final today = plan?.today;
    final targetMm = today?.waterTargetMm ?? 0;
    final remainingMm = today?.waterRemainingMm ?? 0;
    final coveredMm = today?.waterCoverageMm ?? 0;
    final covered = targetMm > 0 ? (coveredMm / targetMm).clamp(0.0, 1.0) : 0.0;
    final totalLiters = remainingMm * areaDekar * 1000.0;
    final lPerPlant = guide?.dailyWaterLitersPerPlant;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.md,
        border: Border.all(color: AppColors.frost.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.water_drop_rounded,
                  color: AppColors.frost, size: 18),
              const SizedBox(width: 6),
              Expanded(
                child: Text(cropName, style: AppText.bodyMd(context)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (plan == null || targetMm <= 0)
            Text(
              'Bu bitki için günlük su hedefi henüz hesaplanamadı. Ekim tarihi ve ürün türü tamamlanmış olmalı.',
              style: AppText.sm(context),
            )
          else ...[
            LinearProgressIndicator(
              value: covered,
              backgroundColor: AppColors.frost.withValues(alpha: 0.15),
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppColors.frost),
              minHeight: 6,
            ),
            const SizedBox(height: 8),
            Text(
              'Bugün hedef: ${_fmtMm(targetMm)} · Karşılanan: ${_fmtMm(coveredMm)} · Açık: ${_fmtMm(remainingMm)}',
              style: AppText.sm(context),
            ),
            const SizedBox(height: 4),
            Text(
              remainingMm > 0
                  ? 'Açığı kapamak için tarla geneline yaklaşık ${_fmtLiters(totalLiters)} L gerekiyor (${_fmtMm(areaDekar * 1)} da × ${_fmtMm(remainingMm)} mm).'
                  : 'Bugünün su hedefi karşılandı. Yağış sonrası toprak nemini kontrol et.',
              style: AppText.xs(context),
            ),
            if (lPerPlant != null) ...[
              const SizedBox(height: 4),
              Text(
                'Bitki başına yönerge: yaklaşık ${lPerPlant.toStringAsFixed(1)} L/gün (TAGEM rehberinden, çeşit/dönem ile değişir).',
                style: AppText.xs(context),
              ),
            ],
          ],
          if (guide?.irrigationSummary != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.frost.withValues(alpha: 0.06),
                borderRadius: AppRadius.sm,
              ),
              child: Text(guide!.irrigationSummary, style: AppText.sm(context)),
            ),
          ],
          const SizedBox(height: 8),
          Text('Uygulama prensipleri', style: AppText.label(context)),
          const SizedBox(height: 4),
          ..._principles.map((p) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• ', style: TextStyle(color: AppColors.frost)),
                    Expanded(child: Text(p, style: AppText.xs(context))),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  static const _principles = <String>[
    'Sabah 06:00–10:00 veya akşam 17:00 sonrası uygula; gün ortası buharlaşmayı artırır.',
    'Damla sulamada sıra yanına, yağmurlamada bitki üstüne değil zemine yönelt.',
    'Sulama bitince ilk 30 dk toprak ıslaklığı kök bölgesine inmiş mi diye kontrol et.',
    'Yağış 8 mm üzerine çıkacaksa sulama planını ertele.',
  ];

  static String _fmtMm(double v) => '${v.toStringAsFixed(1)} mm';
  static String _fmtLiters(double v) {
    if (v >= 1000) return v.toStringAsFixed(0);
    return v.toStringAsFixed(1);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// GÜBRELEME YÖNERGE BÖLÜMÜ
// ─────────────────────────────────────────────────────────────────────────────

class _FertilizationGuidanceSection extends ConsumerWidget {
  const _FertilizationGuidanceSection({required this.fieldId});
  final String fieldId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cropsAsync = ref.watch(fieldCropsStreamProvider(fieldId));
    final crops = cropsAsync.valueOrNull ?? const <Map<String, dynamic>>[];
    if (crops.isEmpty) {
      return _EmptyCard(
        icon: Icons.eco_outlined,
        text:
            'Tarlaya henüz bitki eklenmemiş. Bitki eklediğinde gübreleme yönergesi burada görünür.',
      );
    }
    final cards = <Widget>[];
    for (final crop in crops) {
      final guide = TurkiyeCropGuides.lookup(crop['name']?.toString() ?? '');
      cards.add(_FertilizationCropCard(crop: crop, guide: guide));
    }
    return Column(children: cards);
  }
}

class _FertilizationCropCard extends StatelessWidget {
  const _FertilizationCropCard({required this.crop, required this.guide});
  final Map<String, dynamic> crop;
  final TurkiyeCropGuide? guide;

  @override
  Widget build(BuildContext context) {
    final cropName = crop['name']?.toString() ?? 'Bitki';
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.md,
        border:
            Border.all(color: AppColors.emeraldDark.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.grass_rounded,
                  color: AppColors.emeraldDark, size: 18),
              const SizedBox(width: 6),
              Expanded(
                child: Text(cropName, style: AppText.bodyMd(context)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (guide == null)
            Text(
              'Bu bitki için detaylı gübreleme yönergesi rehberde yok. Toprak analizi sonucuna göre ilçe Tarım Müdürlüğü teknik önerisi ile ilerle.',
              style: AppText.sm(context),
            )
          else ...[
            Text(guide!.fertilizerSummary, style: AppText.sm(context)),
            const SizedBox(height: 8),
            Text('Dönem bazlı plan', style: AppText.label(context)),
            const SizedBox(height: 6),
            for (final phase in guide!.nutritionPlan)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.only(top: 6),
                      decoration: const BoxDecoration(
                        color: AppColors.emerald,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${phase.phase} · ${phase.timing}',
                            style: AppText.bodyMd(context).copyWith(fontSize: 13),
                          ),
                          Text(phase.recommendation,
                              style: AppText.xs(context)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          ],
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.warningBg,
              borderRadius: AppRadius.sm,
              border:
                  Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.science_outlined,
                    color: AppColors.warning, size: 16),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Net gübre miktarı için toprak analizi (N-P-K + organik madde + pH) zorunludur. Analiz yoksa il/ilçe Tarım Müdürlüğü laboratuvarına başvur.',
                    style: AppText.xs(context),
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

// ─────────────────────────────────────────────────────────────────────────────
// HASTALIK — ÖNLEYİCİ KONTROL LİSTESİ
// ─────────────────────────────────────────────────────────────────────────────

class _HealthPreventiveCard extends StatelessWidget {
  static const _checks = <String>[
    'Yaprakları haftada en az bir kez, sabah ışığında alttan ve üstten incele.',
    'Sararma, leke, kıvrılma, bodur kalma gibi belirtileri görür görmez "Aktivite → Gözlem" ile kaydet.',
    'Tarlada yabancı ot bırakma; bunlar zararlı vektörlerine konukçuluk eder.',
    'Sulama saatini sabaha kaydır; gece ıslak yaprak mantari hastalıkları davet eder.',
    'Aletleri (makas, kürek) parselden çıkarken %70 alkol veya 1/9 çamaşır suyu ile sil.',
    'Hava nem ve sıcaklık tahmininde mildiyö/külleme uygun koşulu varsa koruyucu önlem planla.',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.md,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.check_circle_outline_rounded,
                  color: AppColors.success, size: 18),
              const SizedBox(width: 6),
              Expanded(
                child: Text('Hasta bitki yok — önleme öne çıkar',
                    style: AppText.bodyMd(context)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          for (final c in _checks)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('• ',
                      style: TextStyle(color: AppColors.success)),
                  Expanded(child: Text(c, style: AppText.sm(context))),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _ActivityLinkBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.mint,
        borderRadius: AppRadius.sm,
        border: Border.all(color: AppColors.emerald.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.bolt_rounded,
              color: AppColors.emeraldDark, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Aktivite kaydı tavsiyeleri canlı kapatır',
                  style: AppText.bodyMd(context)
                      .copyWith(color: AppColors.emeraldDark, fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  'Bir tavsiyenin üstündeki "Suladım/Gübreledim" butonuna basın '
                  'ya da alttan "Aktivite" girin. Aynı tipte kayıt, ilgili '
                  'tavsiyeyi hemen listeden düşürür ve büyüme/su açığı '
                  'göstergelerini günceller.',
                  style: AppText.sm(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(text, style: AppText.label(context)),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: AppRadius.sm,
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.textSecondary, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text, style: AppText.sm(context)),
          ),
        ],
      ),
    );
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      alignment: Alignment.center,
      child: const SizedBox(
        width: 22,
        height: 22,
        child: CircularProgressIndicator(strokeWidth: 2.2),
      ),
    );
  }
}

class _QuickLogButton extends ConsumerWidget {
  const _QuickLogButton({
    required this.fieldId,
    required this.label,
    this.color,
  });

  final String fieldId;
  final String label;
  final Color? color;

  Future<void> _open(BuildContext context, WidgetRef ref) async {
    final crops =
        ref.read(fieldCropsStreamProvider(fieldId)).valueOrNull ?? const [];
    final fieldData = await ref
        .read(localDataRepositoryProvider)
        .loadFieldById(fieldId);
    final areaDekar =
        (fieldData?['area_dekar'] as num?)?.toDouble() ?? 1.0;
    if (!context.mounted) return;
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
            color: AppColors.surface,
            borderRadius: AppRadius.lg,
            border: Border.all(color: AppColors.border),
          ),
          padding: const EdgeInsets.all(12),
          child: ActivityQuickLog(
            fieldId: fieldId,
            fieldCrops: crops,
            fieldAreaDekar: areaDekar,
            onLogged: () => Navigator.of(ctx).maybePop(),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = color ?? AppColors.emerald;
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        style: FilledButton.styleFrom(
          backgroundColor: c,
          foregroundColor: AppColors.textOnDark,
          minimumSize: const Size.fromHeight(48),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.md),
        ),
        onPressed: () => _open(context, ref),
        icon: const Icon(Icons.add_rounded),
        label: Text(label),
      ),
    );
  }
}

