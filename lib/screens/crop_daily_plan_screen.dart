import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../data/activity_types.dart';
import '../services/agri_service.dart';
import '../services/app_providers.dart';
import '../services/crop_daily_plan.dart';
import '../services/crop_protocol_service.dart';
import '../services/daily_guide_engine.dart';
import '../theme/app_theme.dart';
import '../widgets/activity_quick_log.dart';
import '../widgets/particle_background.dart';
import '../widgets/season_summary_card.dart';
import '../widgets/tap_scale.dart';

/// Tek bir bitki için yeniden tasarlanmış günlük rehber.
///
/// Yapı (yukarıdan aşağı):
///   1. Tarla sağlığı hero kartı (0-100 skor + 4 faktör çubuğu)
///   2. Tek-cümle akıllı özet
///   3. Risk şeritleri (sadece aktif olanlar)
///   4. Canlı aktivite etkisi (son 36 saat içindeyse)
///   5. Bugün yapılacaklar (öncelikli, tek-tap log)
///   6. 3 günlük tahmin şeridi
///   7. Sezon su muhasebesi (kompakt)
///   8. Yetiştirme adımları (özet, açılır)
///   9. Sezon özeti
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
  static const _engine = DailyGuideEngine();

  List<dynamic> _dailyForecast = const [];
  bool _forecastLoading = true;
  bool _roadmapExpanded = false;
  bool _waterExpanded = false;

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
    final activitiesAsync =
        ref.watch(fieldActivityLogProvider(widget.fieldId));
    final scheduledAsync =
        ref.watch(fieldScheduledAutoSeedProvider(widget.fieldId));
    final growthAsync = ref.watch(fieldGrowthStatesProvider(widget.fieldId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Günlük Rehber'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Hava verisini yenile',
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

        // Yetiştirme planı (Ayçiçeği/Mısır/Domates için zengin; diğerleri null).
        final plan = ref.read(cropDailyPlanServiceProvider).build(
              crop: cropMap,
              fieldId: widget.fieldId,
              areaDekar: widget.areaDekar,
              activities: activities,
              scheduledEvents: scheduled,
              dailyForecast: _dailyForecast,
              growthState: growthMap,
            );

        // Yeni motor — tüm faktörleri tek state'e indirger.
        final state = _engine.compute(
          crop: cropMap,
          activities: activities,
          dailyForecast: _dailyForecast,
          growthState: growthMap,
          plan: plan,
        );

        final progress = CropProtocolService.computeProgress(
          crop: cropMap,
          activities: activities,
          fieldId: widget.fieldId,
        );

        return _buildContent(
          state: state,
          plan: plan,
          progress: progress,
          fieldCrops: snap.data!,
          cropMap: cropMap,
          activities: activities,
        );
      },
    );
  }

  Widget _buildContent({
    required DailyGuideState state,
    required CropDailyPlanResult? plan,
    required CropProtocolProgress? progress,
    required List<Map<String, dynamic>> fieldCrops,
    required Map<String, dynamic> cropMap,
    required List<Map<String, dynamic>> activities,
  }) {
    final cropName = cropMap['name']?.toString() ?? 'Bitki';

    return RefreshIndicator(
      color: AppColors.emerald,
      onRefresh: () async {
        setState(() => _forecastLoading = true);
        await _loadForecast();
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 36),
        children: [
          _HealthHeroCard(state: state, cropName: cropName),
          const SizedBox(height: 14),
          _OneLinerStrip(state: state),
          const SizedBox(height: 16),
          if (state.lastImpact != null) ...[
            _LiveImpactCard(impact: state.lastImpact!),
            const SizedBox(height: 14),
          ],
          if (state.risks.isNotEmpty) ...[
            _SectionHeader(
              title: 'Risk uyarıları',
              count: state.risks.length,
              icon: Icons.warning_amber_rounded,
              accent: _severityColor(state.risks.first.severity),
            ),
            const SizedBox(height: 8),
            for (final r in state.risks) ...[
              _RiskBannerCard(
                risk: r,
                onAction: r.actionType == null
                    ? null
                    : () => _onRiskAction(r, plan, fieldCrops),
              ),
              const SizedBox(height: 8),
            ],
            const SizedBox(height: 6),
          ],
          if (state.actions.isNotEmpty) ...[
            _SectionHeader(
              title: 'Bugün yapılacaklar',
              count: state.actions.length,
              icon: Icons.check_circle_outline_rounded,
              accent: AppColors.emerald,
            ),
            const SizedBox(height: 8),
            for (final a in state.actions) ...[
              _ActionCard(
                action: a,
                onTap: () => _onActionTap(a, plan, fieldCrops),
              ),
              const SizedBox(height: 8),
            ],
            const SizedBox(height: 6),
          ],
          if (state.actions.isEmpty && state.risks.isEmpty)
            _IdleCard(stageLabel: state.stage?.stageLabel),
          const SizedBox(height: 16),
          if (state.forecast.isNotEmpty) ...[
            _SectionHeader(
              title: '3 günlük tahmin',
              icon: Icons.calendar_today_rounded,
              accent: AppColors.frost,
            ),
            const SizedBox(height: 8),
            _ForecastStrip(days: state.forecast),
            const SizedBox(height: 16),
          ],
          if (plan != null) ...[
            _SectionHeader(
              title: 'Sezon su muhasebesi',
              icon: Icons.water_drop_rounded,
              accent: AppColors.frost,
              trailing: TextButton(
                onPressed: () =>
                    setState(() => _waterExpanded = !_waterExpanded),
                child: Text(_waterExpanded ? 'Kapat' : 'Detay'),
              ),
            ),
            const SizedBox(height: 8),
            _WaterAccountingCard(plan: plan, expanded: _waterExpanded),
            const SizedBox(height: 16),
          ],
          if (progress != null) ...[
            _SectionHeader(
              title: 'Yetiştirme adımları',
              icon: Icons.timeline_rounded,
              accent: AppColors.emeraldDark,
              trailing: TextButton(
                onPressed: () =>
                    setState(() => _roadmapExpanded = !_roadmapExpanded),
                child: Text(_roadmapExpanded ? 'Kapat' : 'Detay'),
              ),
            ),
            const SizedBox(height: 8),
            _RoadmapSummaryCard(
              progress: progress,
              expanded: _roadmapExpanded,
            ),
            const SizedBox(height: 16),
          ],
          if (plan != null) ...[
            _SectionHeader(
              title: 'Sezon özeti',
              icon: Icons.bar_chart_rounded,
              accent: AppColors.emerald,
            ),
            const SizedBox(height: 8),
            SeasonSummaryCard(
              cropName: plan.cropName,
              plantedDate: plan.plantedDate,
              areaDekar: plan.areaDekar,
              summary: computeSeasonSummary(
                activities: activities,
                cropId: widget.cropId,
                since: plan.plantedDate,
              ),
              harvestDays: plan.harvestDays,
              cropId: plan.cropId,
            ),
            const SizedBox(height: 12),
            Center(
              child: Text(
                'Hedef hasat: ${DateFormat('d MMMM y', 'tr_TR').format(plan.harvestDate)}',
                style: AppText.xs(context),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _onActionTap(
    GuideAction action,
    CropDailyPlanResult? plan,
    List<Map<String, dynamic>> fieldCrops,
  ) async {
    final noteParts = [
      if (action.detail.isNotEmpty) action.detail,
      if (action.timingLabel != null) 'Uygun saat: ${action.timingLabel}',
    ];
    await showActivityQuickLogSheet(
      context: context,
      ref: ref,
      fieldId: widget.fieldId,
      type: action.actionType,
      cropId: widget.cropId,
      fieldCrops: fieldCrops,
      fieldAreaDekar: plan?.areaDekar ?? widget.areaDekar ?? 1.0,
      recommendedQuantity: action.recommendedQuantity,
      quantityUnit: action.unit,
      note: noteParts.isEmpty ? null : noteParts.join('\n'),
    );
  }

  Future<void> _onRiskAction(
    RiskBanner r,
    CropDailyPlanResult? plan,
    List<Map<String, dynamic>> fieldCrops,
  ) async {
    if (r.actionType == null) return;
    await showActivityQuickLogSheet(
      context: context,
      ref: ref,
      fieldId: widget.fieldId,
      type: r.actionType!,
      cropId: widget.cropId,
      fieldCrops: fieldCrops,
      fieldAreaDekar: plan?.areaDekar ?? widget.areaDekar ?? 1.0,
      recommendedQuantity: r.actionQuantity,
      quantityUnit: r.actionUnit,
      note: r.advice,
    );
  }

  Widget _emptyState(String msg) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(msg,
              textAlign: TextAlign.center, style: AppText.body(context)),
        ),
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
        'n_stress_idx': dyn.nStressIdx,
        'disease_pressure': dyn.diseasePressure,
        'yield_multiplier': dyn.yieldMultiplier,
      };
    } catch (_) {
      return g is Map ? Map<String, dynamic>.from(g) : null;
    }
  }
}

// ─── ortak yardımcılar ───────────────────────────────────────────────────────

Color _severityColor(RiskSeverity s) {
  switch (s) {
    case RiskSeverity.critical:
      return AppColors.error;
    case RiskSeverity.warning:
      return AppColors.warning;
    case RiskSeverity.info:
      return AppColors.info;
  }
}

Color _severityBg(RiskSeverity s) {
  switch (s) {
    case RiskSeverity.critical:
      return AppColors.errorBg;
    case RiskSeverity.warning:
      return AppColors.warningBg;
    case RiskSeverity.info:
      return AppColors.infoBg;
  }
}

IconData _iconFor(String key) {
  switch (key) {
    case 'water':
      return Icons.water_drop_rounded;
    case 'fertilizer':
      return Icons.grass_rounded;
    case 'spray':
      return Icons.sanitizer_rounded;
    case 'scout':
      return Icons.search_rounded;
    case 'harvest':
      return Icons.agriculture_rounded;
    case 'frost':
      return Icons.ac_unit_rounded;
    case 'heat':
      return Icons.local_fire_department_rounded;
    case 'storm':
      return Icons.thunderstorm_rounded;
    case 'rain':
      return Icons.umbrella_rounded;
    case 'drought':
      return Icons.dry_rounded;
    case 'saturation':
      return Icons.water_rounded;
    case 'disease':
      return Icons.bug_report_rounded;
    case 'climate':
      return Icons.thermostat_rounded;
    case 'yield':
      return Icons.trending_down_rounded;
    case 'task':
      return Icons.task_alt_rounded;
    default:
      return Icons.info_outline_rounded;
  }
}

// ─── Hero kart: tarla sağlığı skoru ──────────────────────────────────────────

class _HealthHeroCard extends StatelessWidget {
  final DailyGuideState state;
  final String cropName;

  const _HealthHeroCard({required this.state, required this.cropName});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: BoxDecoration(
        gradient: AppGradients.emeraldCard,
        borderRadius: AppRadius.md,
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ScoreRing(score: state.healthScore),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cropName,
                      style: AppText.h2(context).copyWith(
                        color: Colors.white,
                        height: 1.1,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tarla sağlığı: ${state.healthLabel}',
                      style: AppText.body(context).copyWith(
                        color: Colors.white.withValues(alpha: 0.92),
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (state.stage != null)
                      _StageMiniBar(stage: state.stage!),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              for (int i = 0; i < state.factors.length; i++) ...[
                Expanded(child: _FactorChip(bar: state.factors[i])),
                if (i < state.factors.length - 1) const SizedBox(width: 8),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _ScoreRing extends StatelessWidget {
  final int score;
  const _ScoreRing({required this.score});

  @override
  Widget build(BuildContext context) {
    final color = score >= 85
        ? Colors.white
        : score >= 70
            ? Colors.white
            : score >= 55
                ? AppColors.wheat
                : AppColors.warningBg;
    return SizedBox(
      width: 86,
      height: 86,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 86,
            height: 86,
            child: CircularProgressIndicator(
              value: score / 100.0,
              strokeWidth: 7,
              backgroundColor: Colors.white.withValues(alpha: 0.20),
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$score',
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  height: 1.0,
                ),
              ),
              Text(
                '/100',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.white.withValues(alpha: 0.85),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StageMiniBar extends StatelessWidget {
  final StageInfo stage;
  const _StageMiniBar({required this.stage});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          stage.oneLiner,
          style: AppText.xs(context).copyWith(
            color: Colors.white.withValues(alpha: 0.92),
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: stage.seasonProgress,
            minHeight: 4,
            backgroundColor: Colors.white.withValues(alpha: 0.20),
            valueColor: const AlwaysStoppedAnimation(Colors.white),
          ),
        ),
      ],
    );
  }
}

class _FactorChip extends StatelessWidget {
  final FactorBar bar;
  const _FactorChip({required this.bar});

  @override
  Widget build(BuildContext context) {
    final pct = (bar.value * 100).round();
    final tint = bar.value >= 0.85
        ? Colors.white
        : bar.value >= 0.65
            ? AppColors.wheat
            : AppColors.warningBg;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(_iconFor(bar.iconKey), color: tint, size: 14),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  bar.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withValues(alpha: 0.95),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '%$pct',
                style: TextStyle(
                  fontSize: 11,
                  color: tint,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: bar.value.clamp(0.0, 1.0),
              minHeight: 4,
              backgroundColor: Colors.white.withValues(alpha: 0.18),
              valueColor: AlwaysStoppedAnimation(tint),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── tek-cümle özet ──────────────────────────────────────────────────────────

class _OneLinerStrip extends StatelessWidget {
  final DailyGuideState state;
  const _OneLinerStrip({required this.state});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.md,
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const Icon(Icons.tips_and_updates_rounded,
              color: AppColors.emeraldDark, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _capFirst(state.oneLiner),
              style: AppText.body(context).copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _capFirst(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }
}

// ─── canlı aktivite etkisi ───────────────────────────────────────────────────

class _LiveImpactCard extends StatelessWidget {
  final ActivityImpact impact;
  const _LiveImpactCard({required this.impact});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutCubic,
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, t, _) {
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, (1 - t) * 8),
            child: Container(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFE8F5E9), Color(0xFFE3F2FD)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: AppRadius.md,
                border: Border.all(
                    color: AppColors.emerald.withValues(alpha: 0.30)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: AppShadows.sm,
                    ),
                    child: Icon(
                      _iconFor(impact.iconKey),
                      color: AppColors.emeraldDark,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Canlı etki: ${impact.activityLabel}',
                              style: AppText.xs(context).copyWith(
                                color: AppColors.emeraldDark,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          impact.summary,
                          style: AppText.bodyMd(context),
                        ),
                        Text(
                          impact.detail,
                          style: AppText.xs(context),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ─── bölüm başlığı ───────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color accent;
  final int? count;
  final Widget? trailing;

  const _SectionHeader({
    required this.title,
    required this.icon,
    required this.accent,
    this.count,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: accent, size: 18),
        const SizedBox(width: 8),
        Text(title, style: AppText.h2(context)),
        if (count != null && count! > 0) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.15),
              borderRadius: AppRadius.full,
            ),
            child: Text(
              '$count',
              style: AppText.xs(context).copyWith(
                color: accent,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
        const Spacer(),
        if (trailing != null) trailing!,
      ],
    );
  }
}

// ─── risk şeridi ─────────────────────────────────────────────────────────────

class _RiskBannerCard extends StatelessWidget {
  final RiskBanner risk;
  final VoidCallback? onAction;

  const _RiskBannerCard({required this.risk, this.onAction});

  @override
  Widget build(BuildContext context) {
    final color = _severityColor(risk.severity);
    final bg = _severityBg(risk.severity);
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: AppRadius.md,
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.16),
                  shape: BoxShape.circle,
                ),
                child: Icon(_iconFor(risk.iconKey), color: color, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      risk.title,
                      style: AppText.bodyMd(context).copyWith(
                        color: color,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(risk.message, style: AppText.body(context)),
                    const SizedBox(height: 4),
                    Text(
                      risk.advice,
                      style: AppText.xs(context).copyWith(
                        color: AppColors.textSecondary,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (onAction != null) ...[
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                onPressed: onAction,
                icon: Icon(_iconFor(risk.iconKey), size: 16),
                label: Text(_riskCtaLabel(risk)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: AppRadius.sm),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _riskCtaLabel(RiskBanner r) {
    switch (r.actionType) {
      case ActivityType.watering:
        final mins = r.actionQuantity?.round();
        return mins == null ? 'Sulamayı kaydet' : '$mins dk sula';
      case ActivityType.fertilizing:
        return 'Gübrelemeyi kaydet';
      case ActivityType.spraying:
        return 'İlaçlamayı kaydet';
      case ActivityType.scouting:
        return 'Gözlem kaydı';
      case ActivityType.harvest:
        return 'Hasadı kaydet';
      default:
        return 'Kaydet';
    }
  }
}

// ─── eylem kartı (bugün yapılacaklar) ───────────────────────────────────────

class _ActionCard extends StatelessWidget {
  final GuideAction action;
  final VoidCallback onTap;

  const _ActionCard({required this.action, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = _severityColor(action.priority);
    return TapScale(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.md,
          border: Border.all(color: color.withValues(alpha: 0.35)),
          boxShadow: AppShadows.sm,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.14),
                shape: BoxShape.circle,
              ),
              child: Icon(_iconFor(action.iconKey), color: color, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    action.headline,
                    style: AppText.bodyMd(context).copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (action.detail.isNotEmpty)
                    Text(
                      action.detail,
                      style: AppText.xs(context),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  if (action.timingLabel != null)
                    Text(
                      'Uygun saat: ${action.timingLabel}',
                      style: AppText.xs(context)
                          .copyWith(color: AppColors.textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Icon(Icons.chevron_right_rounded, color: color),
          ],
        ),
      ),
    );
  }
}

class _IdleCard extends StatelessWidget {
  final String? stageLabel;
  const _IdleCard({this.stageLabel});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.successBg,
        borderRadius: AppRadius.md,
        border: Border.all(color: AppColors.emerald.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_rounded,
              color: AppColors.emeraldDark, size: 24),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bugün acil iş yok',
                  style: AppText.bodyMd(context)
                      .copyWith(color: AppColors.emeraldDark),
                ),
                Text(
                  stageLabel == null
                      ? 'Bitki dinleniyor — yarın tekrar bak.'
                      : '$stageLabel evresi sürüyor. Yarın güncelleneriz.',
                  style: AppText.xs(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── 3 günlük tahmin şeridi ──────────────────────────────────────────────────

class _ForecastStrip extends StatelessWidget {
  final List<ForecastDay> days;
  const _ForecastStrip({required this.days});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.md,
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          for (int i = 0; i < days.length && i < 4; i++) ...[
            Expanded(child: _ForecastTile(day: days[i], index: i)),
            if (i < days.length - 1 && i < 3) const SizedBox(width: 6),
          ],
        ],
      ),
    );
  }
}

class _ForecastTile extends StatelessWidget {
  final ForecastDay day;
  final int index;
  const _ForecastTile({required this.day, required this.index});

  @override
  Widget build(BuildContext context) {
    final isToday = index == 0;
    final isTomorrow = index == 1;
    final dateLabel = isToday
        ? 'Bugün'
        : isTomorrow
            ? 'Yarın'
            : DateFormat('EEE', 'tr_TR').format(day.date);
    final hasFrost = day.tags.contains('frost');
    final hasHeat = day.tags.contains('heat');
    final hasStorm = day.tags.contains('storm');
    final hasRain = day.tags.contains('rain');
    final accent = hasFrost
        ? AppColors.frost
        : hasStorm
            ? AppColors.error
            : hasHeat
                ? AppColors.warning
                : hasRain
                    ? AppColors.info
                    : AppColors.emeraldDark;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
      decoration: BoxDecoration(
        color: isToday
            ? accent.withValues(alpha: 0.10)
            : AppColors.surfaceAlt,
        borderRadius: AppRadius.sm,
        border: Border.all(
          color: isToday ? accent.withValues(alpha: 0.45) : AppColors.border,
        ),
      ),
      child: Column(
        children: [
          Text(
            dateLabel,
            style: AppText.xs(context).copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Icon(
            hasFrost
                ? Icons.ac_unit_rounded
                : hasStorm
                    ? Icons.thunderstorm_rounded
                    : hasHeat
                        ? Icons.wb_sunny_rounded
                        : hasRain
                            ? Icons.umbrella_rounded
                            : Icons.wb_sunny_outlined,
            color: accent,
            size: 22,
          ),
          const SizedBox(height: 4),
          if (day.tempMin != null && day.tempMax != null)
            Text(
              '${day.tempMin!.round()}°/${day.tempMax!.round()}°',
              style: AppText.xs(context).copyWith(
                fontWeight: FontWeight.w700,
              ),
            )
          else
            Text('—°', style: AppText.xs(context)),
          const SizedBox(height: 2),
          Text(
            day.rainMm > 0 ? '${day.rainMm.round()} mm' : '—',
            style: AppText.xs(context).copyWith(
              color: hasRain ? accent : AppColors.textTertiary,
              fontWeight: hasRain ? FontWeight.w700 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── sezon su muhasebesi (kompakt + detay) ───────────────────────────────────

class _WaterAccountingCard extends StatelessWidget {
  final CropDailyPlanResult plan;
  final bool expanded;

  const _WaterAccountingCard({required this.plan, required this.expanded});

  @override
  Widget build(BuildContext context) {
    final coverage = plan.coverageFraction;
    final pct = (coverage * 100).round();
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.md,
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Sezon: %$pct karşılandı',
                  style: AppText.bodyMd(context),
                ),
              ),
              Text(
                '${plan.remainingSeasonMm.round()} mm açık',
                style: AppText.xs(context).copyWith(
                  color: plan.remainingSeasonMm > 0
                      ? AppColors.warning
                      : AppColors.emeraldDark,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Stack(
              children: [
                Container(height: 12, color: AppColors.surfaceAlt),
                FractionallySizedBox(
                  widthFactor: coverage,
                  child: Container(
                    height: 12,
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
          if (expanded) ...[
            const SizedBox(height: 12),
            _kv('Sezon hedefi', '${plan.seasonTargetMm.round()} mm',
                AppColors.textSecondary),
            _kv('Sulamadan', '+${plan.appliedIrrigationMm.round()} mm',
                AppColors.frost),
            _kv('Yağmurdan', '+${plan.accountedRainMm.round()} mm',
                AppColors.emerald),
            const Divider(height: 18),
            _kv(
              'Anlık açık',
              '${plan.waterDeficitMm.toStringAsFixed(1)} mm',
              plan.waterDeficitMm > 2
                  ? AppColors.warning
                  : AppColors.emeraldDark,
              bold: true,
            ),
          ],
        ],
      ),
    );
  }

  Widget _kv(String label, String value, Color color, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Builder(
        builder: (context) => Row(
          children: [
            Expanded(child: Text(label, style: AppText.body(context))),
            Text(
              value,
              style: (bold ? AppText.bodyMd(context) : AppText.body(context))
                  .copyWith(color: color),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── yetiştirme adımları özeti ───────────────────────────────────────────────

class _RoadmapSummaryCard extends StatelessWidget {
  final CropProtocolProgress progress;
  final bool expanded;

  const _RoadmapSummaryCard({
    required this.progress,
    required this.expanded,
  });

  @override
  Widget build(BuildContext context) {
    final p = progress;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.md,
        border: Border.all(color: AppColors.emerald.withValues(alpha: 0.28)),
        boxShadow: AppShadows.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(p.protocol.emoji, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.isFinished
                          ? 'Tüm adımlar tamamlandı'
                          : '${p.completedCount}/${p.totalCount} adım tamam',
                      style: AppText.bodyMd(context),
                    ),
                    if (p.activeStep != null && !p.isFinished)
                      Text(
                        'Aktif: ${p.activeStep!.title}',
                        style: AppText.xs(context).copyWith(
                          color: AppColors.warning,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: p.ratio,
              minHeight: 6,
              backgroundColor: AppColors.surfaceAlt,
              valueColor: const AlwaysStoppedAnimation(AppColors.emerald),
            ),
          ),
          if (expanded) ...[
            const SizedBox(height: 12),
            for (final step in p.protocol.steps)
              _RoadmapStepRow(
                step: step,
                isCompleted: p.completedOrders.contains(step.order),
                isActive: p.activeStep?.order == step.order,
              ),
          ],
        ],
      ),
    );
  }
}

class _RoadmapStepRow extends StatelessWidget {
  final dynamic step;
  final bool isCompleted;
  final bool isActive;

  const _RoadmapStepRow({
    required this.step,
    required this.isCompleted,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    final color = isCompleted
        ? AppColors.emeraldDark
        : (isActive ? AppColors.warning : AppColors.textTertiary);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isCompleted
                ? Icons.check_circle_rounded
                : (isActive
                    ? Icons.play_circle_fill_rounded
                    : Icons.radio_button_unchecked_rounded),
            color: color,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'G${step.dayOffset} · ${step.stageEmoji} ${step.title}',
                  style: AppText.body(context).copyWith(
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                    decoration:
                        isCompleted ? TextDecoration.lineThrough : null,
                    color: isCompleted
                        ? AppColors.textSecondary
                        : AppColors.textPrimary,
                  ),
                ),
                if (isActive && step.criticalWarning != null)
                  Text(
                    step.criticalWarning!.toString(),
                    style: AppText.xs(context).copyWith(
                      color: AppColors.warning,
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
