import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../data/activity_types.dart';
import '../data/crop_protocols.dart';
import '../services/agri_service.dart';
import '../services/app_providers.dart';
import '../services/crop_daily_plan.dart';
import '../services/crop_protocol_service.dart';
import '../services/field_state_service.dart';
import '../services/task_directive_service.dart';
import '../theme/app_theme.dart';
import '../widgets/activity_quick_log.dart';
import '../widgets/floating_toast.dart';
import '../widgets/live_crop_growth.dart';
import '../widgets/particle_background.dart';
import '../widgets/season_summary_card.dart';
import '../widgets/tap_scale.dart';

/// Tarladaki tek bir bitki için gün-gün rehber + canlı su muhasebesi.
///
/// Üç akışı birleştirir:
/// - `fieldActivityLogProvider`   (çiftçi logları)
/// - `fieldScheduledAutoSeedProvider` (sezonluk planlanmış görevler)
/// - `fieldGrowthStatesProvider`  (GDD/evre/su açığı — canlı)
///
/// Yağmur verisi `AgriService.getFieldAnalysis` ile bir kez yüklenir; tarla
/// detay ekranı yağmuru zaten cache'lediği için bu çağrı çoğunlukla saniyenin
/// altında döner.
class CropDailyPlanScreen extends ConsumerStatefulWidget {
  final String fieldId;
  final String cropId;
  final String fieldName;
  final double? latitude;
  final double? longitude;
  final double? areaDekar;

  const CropDailyPlanScreen({
    super.key,
    required this.fieldId,
    required this.cropId,
    required this.fieldName,
    this.latitude,
    this.longitude,
    this.areaDekar,
  });

  @override
  ConsumerState<CropDailyPlanScreen> createState() =>
      _CropDailyPlanScreenState();
}

class _CropDailyPlanScreenState extends ConsumerState<CropDailyPlanScreen> {
  List<dynamic> _dailyForecast = const [];
  bool _forecastLoading = true;

  @override
  void initState() {
    super.initState();
    _loadForecast();
  }

  Future<void> _loadForecast() async {
    final lat = widget.latitude;
    final lng = widget.longitude;
    if (lat == null || lng == null) {
      if (mounted) setState(() => _forecastLoading = false);
      return;
    }
    try {
      final analysis = await AgriService.getFieldAnalysis(
        lat,
        lng,
        widget.fieldName,
        widget.areaDekar ?? 1.0,
      );
      if (!mounted) return;
      setState(() {
        _dailyForecast = (analysis['daily_forecast'] as List?) ?? const [];
        _forecastLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _forecastLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final activitiesAsync = ref.watch(fieldActivityLogProvider(widget.fieldId));
    final scheduledAsync =
        ref.watch(fieldScheduledAutoSeedProvider(widget.fieldId));
    final growthAsync = ref.watch(fieldGrowthStatesProvider(widget.fieldId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Günlük Rehber'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Yağmur ve plan tahminini yenile',
            onPressed: () {
              setState(() => _forecastLoading = true);
              _loadForecast();
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          const Positioned.fill(child: ParticleBackground()),
          if (_forecastLoading)
            const Center(child: CircularProgressIndicator())
          else
            _buildBody(activitiesAsync, scheduledAsync, growthAsync),
        ],
      ),
    );
  }

  Widget _buildBody(
    AsyncValue<List<Map<String, dynamic>>> activitiesAsync,
    AsyncValue<List<Map<String, dynamic>>> scheduledAsync,
    AsyncValue<List<dynamic>> growthAsync,
  ) {
    final activities = activitiesAsync.valueOrNull ?? const [];
    final scheduled = scheduledAsync.valueOrNull ?? const [];
    final growthList = growthAsync.valueOrNull ?? const [];

    final repo = ref.read(localDataRepositoryProvider);
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: repo.loadFieldCrops(widget.fieldId),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        Map<String, dynamic>? cropMap;
        for (final c in snap.data!) {
          if (c['id']?.toString() == widget.cropId) {
            cropMap = c;
            break;
          }
        }
        if (cropMap == null) {
          return _emptyState('Bitki bulunamadı.');
        }
        Map<String, dynamic>? growthMap;
        for (final g in growthList) {
          if (_extractCropId(g) == widget.cropId) {
            growthMap = _growthToMap(g);
            break;
          }
        }
        final result = ref.read(cropDailyPlanServiceProvider).build(
              crop: cropMap,
              fieldId: widget.fieldId,
              areaDekar: widget.areaDekar,
              activities: activities,
              scheduledEvents: scheduled,
              dailyForecast: _dailyForecast,
              growthState: growthMap,
            );
        if (result == null) {
          return _emptyState(
            'Gün-gün rehber yalnızca Ayçiçeği, Mısır ve Domates için '
            'üretilir. Ekim tarihinin de girilmiş olması gerekir.',
          );
        }

        // Tüm tarla için yönergeler — bu ekine ait olanlar süzülür.
        final fieldStateMap = <String, CropFieldState>{
          for (final s in ref.read(fieldStateServiceProvider).compute(
            field: {'id': widget.fieldId, 'name': widget.fieldName},
            fieldCrops: snap.data!,
            activities: activities,
          ))
            s.cropId: s,
        };
        final growthSnapshots = <String, GrowthSnapshot>{};
        for (final g in growthList) {
          final id = _extractCropId(g);
          if (id == null) continue;
          try {
            final dyn = g as dynamic;
            growthSnapshots[id] = GrowthSnapshot(
              stageKey: dyn.currentStageKey as String? ?? '',
              stageProgress: (dyn.stageProgress as num?)?.toDouble() ?? 0,
              accumulatedGdd: (dyn.accumulatedGdd as num?)?.toDouble() ?? 0,
              waterDeficitMm: (dyn.waterDeficitMm as num?)?.toDouble() ?? 0,
              nStressIdx: (dyn.nStressIdx as num?)?.toDouble() ?? 0,
              diseasePressure: (dyn.diseasePressure as num?)?.toDouble() ?? 0,
              yieldMultiplier: (dyn.yieldMultiplier as num?)?.toDouble() ?? 1.0,
            );
          } catch (_) {}
        }
        final allDirectives = const TaskDirectiveService().generate(
          fieldCrops: snap.data!,
          activities: activities,
          dailyForecast: _dailyForecast,
          growthStates: growthSnapshots,
          fieldStates: fieldStateMap,
          scheduledEvents: scheduled,
        );
        // Bu ekine ait + tarla geneli (cropId null) olan + acil olanlar.
        final cropDirectives = allDirectives.where((d) {
          if (d.cropId == null) return d.urgency >= 1;
          return d.cropId == widget.cropId;
        }).toList();

        // Yetiştirme protokolü (3 vitrin bitki için yol haritası).
        final progress = CropProtocolService.computeProgress(
          crop: cropMap,
          activities: activities,
          fieldId: widget.fieldId,
        );

        return _buildContent(
          r: result,
          directives: cropDirectives,
          progress: progress,
          fieldCrops: snap.data!,
          seasonSummary: computeSeasonSummary(
            activities: activities,
            cropId: widget.cropId,
            since: result.plantedDate,
          ),
        );
      },
    );
  }

  Widget _buildContent({
    required CropDailyPlanResult r,
    required List<FieldDirective> directives,
    required CropProtocolProgress? progress,
    required List<Map<String, dynamic>> fieldCrops,
    required Map<String, dynamic> seasonSummary,
  }) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      children: [
        _HeaderCard(result: r),
        const SizedBox(height: 16),
        LiveCropGuideScene(
          cropId: r.cropId,
          cropName: r.cropName,
          plantedDate: r.plantedDate,
          harvestDate: r.harvestDate,
          fallbackStageKey: r.currentStageKey,
          fallbackWaterDeficitMm: r.waterDeficitMm,
          yieldLossPct: r.yieldLossPct,
        ),
        const SizedBox(height: 16),
        _WaterAccountingCard(result: r),
        if (directives.isNotEmpty) ...[
          const SizedBox(height: 20),
          _SectionTitle('Bugünün yönergeleri'),
          const SizedBox(height: 8),
          for (final d in directives)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _DirectiveTile(
                directive: d,
                onLog: d.actionType == null
                    ? null
                    : () => _logDirective(d, fieldCrops),
              ),
            ),
        ],
        const SizedBox(height: 20),
        _SectionTitle('Bugün ne yapmalıyım?'),
        const SizedBox(height: 8),
        if (r.today != null)
          _TodayCard(
            day: r.today!,
            cropName: r.cropName,
            onTaskTap: (task) => _onTaskTap(r, r.today!, task, fieldCrops),
          )
        else
          _emptyMessage('Bugün ekim aralığı dışında.'),
        const SizedBox(height: 20),
        _SectionTitle('Sezon özeti'),
        const SizedBox(height: 8),
        SeasonSummaryCard(
          cropName: r.cropName,
          plantedDate: r.plantedDate,
          areaDekar: r.areaDekar,
          summary: seasonSummary,
          harvestDays: r.harvestDays,
          cropId: r.cropId,
        ),
        if (progress != null) ...[
          const SizedBox(height: 20),
          _SectionTitle('Yetiştirme rehberi'),
          const SizedBox(height: 8),
          _RoadmapMiniCard(progress: progress),
        ],
        const SizedBox(height: 20),
        _SectionTitle('14 günlük zaman çizelgesi'),
        const SizedBox(height: 8),
        for (final d in r.days)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _DayTile(
              day: d,
              cropName: r.cropName,
              onTaskTap: (task) => _onTaskTap(r, d, task, fieldCrops),
            ),
          ),
        const SizedBox(height: 12),
        Center(
          child: Text(
            'Hasat: ${DateFormat('d MMMM y', 'tr_TR').format(r.harvestDate)}',
            style: AppText.xs(context),
          ),
        ),
      ],
    );
  }

  Future<void> _logDirective(
    FieldDirective d,
    List<Map<String, dynamic>> fieldCrops,
  ) async {
    final type = d.actionType;
    if (type == null) return;
    await showActivityQuickLogSheet(
      context: context,
      ref: ref,
      fieldId: widget.fieldId,
      type: type,
      cropId: d.cropId,
      fieldCrops: fieldCrops,
      fieldAreaDekar: widget.areaDekar ?? d.areaDekar ?? 1.0,
      recommendedQuantity: d.recommendedQuantity ?? d.suggestedQuantity,
      quantityUnit: d.quantityUnit,
      note: d.reason,
    );
  }

  Future<void> _onTaskTap(
    CropDailyPlanResult r,
    DayPlan day,
    DayTask task,
    List<Map<String, dynamic>> fieldCrops,
  ) async {
    if (task.done) {
      AppToast.show(context, message: 'Bu görev zaten kaydedildi.');
      return;
    }
    if (!day.isToday && !day.isPast) {
      AppToast.show(context,
          message: 'Sadece bugünün veya geçmişin görevleri loglanabilir.');
      return;
    }
    await showActivityQuickLogSheet(
      context: context,
      ref: ref,
      fieldId: r.fieldId,
      type: task.type,
      cropId: r.cropId,
      fieldCrops: fieldCrops,
      fieldAreaDekar: r.areaDekar,
      recommendedQuantity: task.recommendedQuantity,
      quantityUnit: task.unit,
      note: task.detail,
    );
  }

  Widget _emptyState(String msg) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(msg,
              textAlign: TextAlign.center, style: AppText.body(context)),
        ),
      );

  Widget _emptyMessage(String msg) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.md,
        ),
        child: Text(msg, style: AppText.body(context)),
      );

  static String? _extractCropId(dynamic g) {
    try {
      final dyn = g as dynamic;
      return dyn.cropId as String?;
    } catch (_) {
      if (g is Map) return g['crop_id']?.toString() ?? g['cropId']?.toString();
      return null;
    }
  }

  static Map<String, dynamic>? _growthToMap(dynamic g) {
    try {
      final dyn = g as dynamic;
      return {
        'crop_id': dyn.cropId,
        'current_stage_key': dyn.currentStageKey,
        'stage_progress': dyn.stageProgress,
        'accumulated_gdd': dyn.accumulatedGdd,
        'water_deficit_mm': dyn.waterDeficitMm,
        'yield_multiplier': dyn.yieldMultiplier,
      };
    } catch (_) {
      return g is Map ? Map<String, dynamic>.from(g) : null;
    }
  }
}

String _fmtNum(double v) =>
    v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(1);

String _stageLabel(String? key) {
  switch (key) {
    case 'cimlenme':
      return 'Çimlenme';
    case 'vejetatif':
      return 'Vejetatif';
    case 'ciceklenme':
      return 'Çiçeklenme';
    case 'meyve_dolumu':
      return 'Meyve Dolumu';
    case 'olgunlasma':
      return 'Olgunlaşma';
    case 'hasat':
      return 'Hasat';
    default:
      return '—';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Header — bitki adı, evre, GDD ilerlemesi, ekim/hasat tarihleri
// ─────────────────────────────────────────────────────────────────────────────
class _HeaderCard extends StatelessWidget {
  final CropDailyPlanResult result;
  const _HeaderCard({required this.result});

  @override
  Widget build(BuildContext context) {
    final r = result;
    final daysSince = DateTime.now().difference(r.plantedDate).inDays;
    final progress =
        r.totalGdd <= 0 ? 0.0 : (r.accumulatedGdd / r.totalGdd).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppGradients.emeraldCard,
        borderRadius: AppRadius.md,
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.eco_rounded, color: Colors.white, size: 28),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      r.cropName,
                      style: AppText.h2(context).copyWith(color: Colors.white),
                    ),
                    Text(
                      'Ekim: ${DateFormat('d MMM y', 'tr_TR').format(r.plantedDate)}'
                      ' • $daysSince. gün',
                      style: AppText.xs(context)
                          .copyWith(color: Colors.white.withOpacity(0.85)),
                    ),
                  ],
                ),
              ),
              if (r.yieldLossPct > 0)
                _Pill(
                  label: 'Verim −%${r.yieldLossPct}',
                  background: AppColors.warning,
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _Pill(
                  icon: Icons.spa_rounded,
                  label: _stageLabel(r.currentStageKey),
                  background: Colors.white.withOpacity(0.2),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _Pill(
                  icon: Icons.local_fire_department_rounded,
                  label:
                      'GDD ${r.accumulatedGdd.round()}/${r.totalGdd.round()}',
                  background: Colors.white.withOpacity(0.2),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: Colors.white.withOpacity(0.25),
              valueColor: const AlwaysStoppedAnimation(Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color background;
  const _Pill({required this.label, required this.background, this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: AppRadius.full,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, color: Colors.white, size: 16),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: AppText.xs(context).copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Toplam su muhasebesi — sulama + yağmur birikiyor, hedefe doğru gidiyor.
// ─────────────────────────────────────────────────────────────────────────────
class _WaterAccountingCard extends StatelessWidget {
  final CropDailyPlanResult result;
  const _WaterAccountingCard({required this.result});

  @override
  Widget build(BuildContext context) {
    final r = result;
    final coverage = r.coverageFraction;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.md,
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.water_drop_rounded,
                  color: AppColors.frost, size: 22),
              const SizedBox(width: 8),
              Text('Toplam Su Muhasebesi', style: AppText.bodyMd(context)),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Stack(
              children: [
                Container(
                  height: 14,
                  color: AppColors.surfaceAlt,
                ),
                FractionallySizedBox(
                  widthFactor: coverage,
                  child: Container(
                    height: 14,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(colors: [
                        AppColors.frost,
                        AppColors.emerald,
                      ]),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          _MetricRow(
            label: 'Sezon hedefi',
            value: '${r.seasonTargetMm.round()} mm',
            color: AppColors.textSecondary,
          ),
          _MetricRow(
            label: 'Sulamadan',
            value: '+${r.appliedIrrigationMm.round()} mm',
            color: AppColors.frost,
          ),
          _MetricRow(
            label: 'Yağmurdan',
            value: '+${r.accountedRainMm.round()} mm',
            color: AppColors.emerald,
          ),
          const Divider(height: 18),
          _MetricRow(
            label: 'Kalan ihtiyaç',
            value: '${r.remainingSeasonMm.round()} mm',
            color: r.remainingSeasonMm > 0
                ? AppColors.warning
                : AppColors.emeraldDark,
            bold: true,
          ),
          if (r.waterDeficitMm > 2) ...[
            const SizedBox(height: 8),
            Text(
              'Anlık stres: ${r.waterDeficitMm.toStringAsFixed(1)} mm açık. '
              'Bugün sulama önerilir.',
              style: AppText.xs(context).copyWith(color: AppColors.warning),
            ),
          ],
        ],
      ),
    );
  }
}

class _MetricRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool bold;
  const _MetricRow({
    required this.label,
    required this.value,
    required this.color,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(child: Text(label, style: AppText.body(context))),
          Text(
            value,
            style: (bold ? AppText.bodyMd(context) : AppText.body(context))
                .copyWith(color: color),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text, style: AppText.h2(context));
  }
}

class _DirectiveTile extends StatelessWidget {
  final FieldDirective directive;
  final VoidCallback? onLog;

  const _DirectiveTile({
    required this.directive,
    this.onLog,
  });

  @override
  Widget build(BuildContext context) {
    final actionType = directive.actionType;
    final color = actionType == null
        ? (directive.urgency >= 2 ? AppColors.warning : AppColors.emerald)
        : ActivityType.color(actionType);
    final icon = actionType == null
        ? (directive.urgency >= 2
            ? Icons.warning_rounded
            : Icons.info_outline_rounded)
        : ActivityType.icon(actionType);
    final qty = directive.suggestedQuantity ?? directive.recommendedQuantity;
    final qtyText = qty != null && directive.quantityUnit != null
        ? '${_fmtNum(qty)} ${directive.quantityUnit}'
        : null;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.md,
        border: Border.all(color: color.withValues(alpha: 0.28)),
        boxShadow: AppShadows.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: AppRadius.sm,
                ),
                child: Icon(icon, color: color, size: 21),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      directive.headline,
                      style: AppText.bodyMd(context)
                          .copyWith(color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      directive.reason,
                      style: AppText.body(context)
                          .copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              if (qtyText != null)
                _Pill(
                  label: qtyText,
                  background: color.withValues(alpha: 0.75),
                ),
            ],
          ),
          if (directive.steps.isNotEmpty) ...[
            const SizedBox(height: 10),
            for (final step in directive.steps.take(3))
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.check_rounded, size: 15, color: color),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        step,
                        style: AppText.xs(context)
                            .copyWith(color: AppColors.textSecondary),
                      ),
                    ),
                  ],
                ),
              ),
          ],
          if (onLog != null) ...[
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: onLog,
                icon: Icon(ActivityType.icon(actionType!), size: 18),
                label: Text(ActivityType.actionLabel(actionType)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _RoadmapMiniCard extends StatelessWidget {
  final CropProtocolProgress progress;

  const _RoadmapMiniCard({required this.progress});

  @override
  Widget build(BuildContext context) {
    final p = progress;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.md,
        border: Border.all(color: AppColors.emerald.withValues(alpha: 0.28)),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(p.protocol.emoji, style: const TextStyle(fontSize: 26)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${p.protocol.displayName} yetiştirme adımları',
                      style: AppText.bodyMd(context),
                    ),
                    Text(
                      p.isFinished
                          ? 'Tüm adımlar tamamlandı.'
                          : '${p.completedCount}/${p.totalCount} adım tamam',
                      style: AppText.xs(context),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: p.ratio,
              minHeight: 8,
              backgroundColor: AppColors.surfaceAlt,
              valueColor: const AlwaysStoppedAnimation(AppColors.emerald),
            ),
          ),
          const SizedBox(height: 10),
          if (p.config != null)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _GuideChip(
                  icon: Icons.landscape_rounded,
                  label: p.config!.soilType.label,
                ),
                _GuideChip(
                  icon: p.config!.irrigationMethod.icon,
                  label: p.config!.irrigationMethod.label,
                ),
                _GuideChip(
                  icon: Icons.straighten_rounded,
                  label: '${_fmtNum(p.config!.areaDekar)} da',
                ),
              ],
            ),
          const SizedBox(height: 8),
          for (final step in p.protocol.steps)
            _RoadmapStepCard(
              step: step,
              isCompleted: p.completedOrders.contains(step.order),
              isActive: p.activeStep?.order == step.order,
              config: p.config,
            ),
        ],
      ),
    );
  }
}

class _GuideChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _GuideChip({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.emerald.withValues(alpha: 0.08),
        borderRadius: AppRadius.full,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.emeraldDark),
          const SizedBox(width: 5),
          Text(label, style: AppText.xs(context)),
        ],
      ),
    );
  }
}

class _RoadmapStepCard extends StatelessWidget {
  final ProtocolStep step;
  final bool isCompleted;
  final bool isActive;
  final CropConfig? config;

  const _RoadmapStepCard({
    required this.step,
    required this.isCompleted,
    required this.isActive,
    required this.config,
  });

  @override
  Widget build(BuildContext context) {
    final color = isCompleted
        ? AppColors.emeraldDark
        : (isActive ? AppColors.warning : AppColors.textTertiary);
    final details = <String>[
      step.description,
      if (config != null && step.soilNote(config!.soilType) != null)
        step.soilNote(config!.soilType)!,
      if (config != null &&
          step.irrigationNote(config!.irrigationMethod) != null)
        step.irrigationNote(config!.irrigationMethod)!,
      if (step.fertilizerSpec != null) step.fertilizerSpec!,
      if (step.waterSpec != null) step.waterSpec!,
      if (step.pesticideSpec != null) step.pesticideSpec!,
      if (step.criticalWarning != null) step.criticalWarning!,
      if (step.farmerTip != null) step.farmerTip!,
      if (step.commonMistake != null) step.commonMistake!,
    ];

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        childrenPadding: const EdgeInsets.fromLTRB(32, 0, 0, 8),
        initiallyExpanded: isActive,
        leading: Icon(
          isCompleted
              ? Icons.check_circle_rounded
              : (isActive
                  ? Icons.play_circle_fill_rounded
                  : Icons.radio_button_unchecked_rounded),
          color: color,
        ),
        title: Text(
          'G${step.dayOffset} · ${step.stageEmoji} ${step.title}',
          style: AppText.body(context).copyWith(
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
            color:
                isCompleted ? AppColors.textSecondary : AppColors.textPrimary,
            decoration: isCompleted ? TextDecoration.lineThrough : null,
          ),
        ),
        children: [
          for (final detail in details)
            Padding(
              padding: const EdgeInsets.only(bottom: 7),
              child: Text(
                detail,
                style: AppText.xs(context).copyWith(height: 1.35),
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Bugün — büyük kart
// ─────────────────────────────────────────────────────────────────────────────
class _TodayCard extends StatelessWidget {
  final DayPlan day;
  final String cropName;
  final ValueChanged<DayTask> onTaskTap;
  const _TodayCard({
    required this.day,
    required this.cropName,
    required this.onTaskTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.md,
        border: Border.all(color: AppColors.emerald, width: 1.5),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('${day.dayIndex}. gün', style: AppText.bodyMd(context)),
              const SizedBox(width: 8),
              _Pill(
                label: day.stageLabel,
                background: AppColors.emerald,
              ),
              const Spacer(),
              Text(
                DateFormat('EEEE, d MMM', 'tr_TR').format(day.date),
                style: AppText.xs(context),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _DayWaterBar(day: day),
          const SizedBox(height: 12),
          if (day.tasks.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Text(
                'Bugün için planlanmış görev yok. Bitki dinleniyor.',
                style: AppText.body(context),
              ),
            )
          else
            ...day.tasks.map((t) => _TaskTile(
                  task: t,
                  onTap: () => onTaskTap(t),
                )),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 14 günlük timeline kartı
// ─────────────────────────────────────────────────────────────────────────────
class _DayTile extends StatelessWidget {
  final DayPlan day;
  final String cropName;
  final ValueChanged<DayTask> onTaskTap;
  const _DayTile({
    required this.day,
    required this.cropName,
    required this.onTaskTap,
  });

  @override
  Widget build(BuildContext context) {
    final faded = day.isPast;
    final highlight = day.isToday;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color:
            highlight ? AppColors.emerald.withOpacity(0.07) : AppColors.surface,
        borderRadius: AppRadius.md,
        border: Border.all(
          color: highlight ? AppColors.emerald : AppColors.border,
          width: highlight ? 1.4 : 1,
        ),
      ),
      child: Opacity(
        opacity: faded ? 0.85 : 1.0,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _DateChip(date: day.date, isToday: day.isToday),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '${day.dayIndex}. gün • ${day.stageLabel}',
                    style: AppText.bodyMd(context),
                  ),
                ),
                if (day.tasks.where((t) => !t.done).isNotEmpty)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withOpacity(0.15),
                      borderRadius: AppRadius.full,
                    ),
                    child: Text(
                      '${day.tasks.where((t) => !t.done).length} görev',
                      style: AppText.xs(context)
                          .copyWith(color: AppColors.warning),
                    ),
                  ),
              ],
            ),
            if (day.waterTargetMm > 0) ...[
              const SizedBox(height: 8),
              _DayWaterBar(day: day, compact: true),
            ],
            if (day.tasks.isNotEmpty) ...[
              const SizedBox(height: 8),
              ...day.tasks.map((t) => _TaskTile(
                    task: t,
                    compact: true,
                    onTap: () => onTaskTap(t),
                  )),
            ],
          ],
        ),
      ),
    );
  }
}

class _DateChip extends StatelessWidget {
  final DateTime date;
  final bool isToday;
  const _DateChip({required this.date, required this.isToday});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 50,
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: isToday ? AppColors.emerald : AppColors.surfaceAlt,
        borderRadius: AppRadius.sm,
      ),
      child: Column(
        children: [
          Text(
            DateFormat('d', 'tr_TR').format(date),
            style: AppText.bodyMd(context).copyWith(
              color: isToday ? Colors.white : AppColors.textPrimary,
              fontSize: 18,
            ),
          ),
          Text(
            DateFormat('MMM', 'tr_TR').format(date),
            style: AppText.xs(context).copyWith(
              color: isToday ? Colors.white : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _DayWaterBar extends StatelessWidget {
  final DayPlan day;
  final bool compact;
  const _DayWaterBar({required this.day, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final target = day.waterTargetMm;
    if (target <= 0) {
      return Text(
        'Bugün için sulama hedefi yok.',
        style: AppText.xs(context),
      );
    }
    final irrFrac =
        target <= 0 ? 0.0 : (day.waterIrrigatedMm / target).clamp(0.0, 1.0);
    final rainFrac = target <= 0
        ? 0.0
        : (day.waterRainMm / target).clamp(0.0, 1.0 - irrFrac);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Stack(
            children: [
              Container(
                height: compact ? 8 : 12,
                color: AppColors.surfaceAlt,
              ),
              Row(
                children: [
                  Expanded(
                    flex: (irrFrac * 100).round(),
                    child: Container(
                      height: compact ? 8 : 12,
                      color: AppColors.frost,
                    ),
                  ),
                  Expanded(
                    flex: (rainFrac * 100).round(),
                    child: Container(
                      height: compact ? 8 : 12,
                      color: AppColors.emerald,
                    ),
                  ),
                  Expanded(
                    flex: (100 -
                            (irrFrac * 100).round() -
                            (rainFrac * 100).round())
                        .clamp(0, 100),
                    child: const SizedBox(),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (!compact) const SizedBox(height: 6),
        if (!compact)
          Text(
            'Hedef ${target.toStringAsFixed(1)} mm  •  '
            'Sulama ${day.waterIrrigatedMm.toStringAsFixed(1)} mm  •  '
            'Yağmur ${day.waterRainMm.toStringAsFixed(1)} mm  •  '
            'Açık ${day.waterRemainingMm.toStringAsFixed(1)} mm',
            style: AppText.xs(context),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Görev satırı (tek tıkla loglanabilir)
// ─────────────────────────────────────────────────────────────────────────────
class _TaskTile extends StatelessWidget {
  final DayTask task;
  final VoidCallback onTap;
  final bool compact;
  const _TaskTile({
    required this.task,
    required this.onTap,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = ActivityType.color(task.type);
    final icon =
        task.done ? Icons.check_circle_rounded : ActivityType.icon(task.type);
    final qty = task.recommendedQuantity;
    final unit = task.unit;
    final qtySuffix =
        qty != null && unit != null ? ' • ${_fmtNum(qty)} $unit' : '';
    return Padding(
      padding: EdgeInsets.symmetric(vertical: compact ? 3 : 6),
      child: TapScale(
        onTap: task.done ? null : onTap,
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: 10,
            vertical: compact ? 8 : 10,
          ),
          decoration: BoxDecoration(
            color: task.done
                ? AppColors.emeraldDark.withOpacity(0.08)
                : color.withOpacity(0.08),
            borderRadius: AppRadius.sm,
            border: Border.all(
              color: task.done
                  ? AppColors.emeraldDark.withOpacity(0.3)
                  : color.withOpacity(0.3),
            ),
          ),
          child: Row(
            children: [
              Icon(icon,
                  color: task.done ? AppColors.emeraldDark : color,
                  size: compact ? 18 : 20),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${task.label}$qtySuffix',
                      style: (compact
                              ? AppText.body(context)
                              : AppText.bodyMd(context))
                          .copyWith(
                        decoration:
                            task.done ? TextDecoration.lineThrough : null,
                        color: task.done
                            ? AppColors.textSecondary
                            : AppColors.textPrimary,
                      ),
                    ),
                    if (task.detail != null && task.detail!.isNotEmpty)
                      Text(
                        task.detail!,
                        style: AppText.xs(context),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              if (!task.done)
                const Icon(Icons.chevron_right_rounded,
                    color: AppColors.textTertiary),
            ],
          ),
        ),
      ),
    );
  }
}
