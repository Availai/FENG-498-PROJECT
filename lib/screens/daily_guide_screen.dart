import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/activity_types.dart';
import '../data/turkiye_crop_guides.dart';
import '../services/app_providers.dart';
import '../services/crop_daily_plan.dart';
import '../services/crop_protocol_service.dart';
import '../services/guide_engine.dart';
import '../services/notification_service.dart';
import '../services/rules/recommendation.dart';
import '../theme/app_theme.dart';
import '../widgets/help_panel.dart';
import '../widgets/recommendation_card.dart';
import 'crop_daily_plan_screen.dart';

final _dailyGuideFieldContextProvider = FutureProvider.family
    .autoDispose<_DailyGuideFieldContext, String>((ref, fieldId) async {
  final repo = ref.watch(localDataRepositoryProvider);
  final field = await repo.loadFieldById(fieldId);
  final latest = await repo.loadLatestSuitabilityReport(fieldId);
  final report = latest?['report'];
  return _DailyGuideFieldContext(
    field: field,
    dailyForecast: _extractDailyForecast(report),
  );
});

class _DailyGuideFieldContext {
  const _DailyGuideFieldContext({
    required this.field,
    required this.dailyForecast,
  });

  final Map<String, dynamic>? field;
  final List<dynamic> dailyForecast;

  double? get latitude => (field?['latitude'] as num?)?.toDouble();
  double? get longitude => (field?['longitude'] as num?)?.toDouble();
  double get areaDekar => (field?['area_dekar'] as num?)?.toDouble() ?? 1.0;
  String get name => field?['name']?.toString() ?? 'Tarla';
}

List<dynamic> _extractDailyForecast(dynamic report) {
  if (report is! Map) return const [];
  final direct = report['daily_forecast'];
  if (direct is List) return direct;
  final weather = report['weather_snapshot'];
  if (weather is Map && weather['daily_forecast'] is List) {
    return weather['daily_forecast'] as List;
  }
  return const [];
}

/// Tek "Bugünün Rehberi" ekranı — eski 5 paralel UI yüzeyini değiştirir.
///
/// Tasarım kararları:
/// - Üstte alerts banner (don / sıcak / yağmur / aşırı sulama / REI)
/// - Sonra BUGÜN — max 3 action card
/// - BU HAFTA — kompakt liste
/// - DURUM — tek bakışta stres göstergeleri
/// - BİLMENİZ GEREKENLER — playbook insights
/// - Alt linkler: 14 günlük plan + yetiştirme detayı
///
/// Tüm veri tek `fieldGuideProvider` üzerinden gelir; çakışma yok.
class DailyGuideScreen extends ConsumerWidget {
  final String fieldId;
  final String? fieldName;

  const DailyGuideScreen({
    super.key,
    required this.fieldId,
    this.fieldName,
  });

  // Oturum + gün bazlı dedup: aynı tarla için günde en fazla bir kez bildirim.
  static final _notifiedKeys = <String>{};

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final guideAsync = ref.watch(fieldGuideProvider(fieldId));
    final growthAsync = ref.watch(fieldGrowthStatesProvider(fieldId));

    // Rehber sonucu her değiştiğinde bildirim gönder (günde 1 kez / tarla).
    ref.listen(fieldGuideProvider(fieldId), (_, next) {
      next.whenData((result) {
        final today = DateTime.now();
        final key =
            '$fieldId-${today.year}${today.month.toString().padLeft(2, '0')}${today.day.toString().padLeft(2, '0')}';
        if (_notifiedKeys.contains(key)) return;
        _notifiedKeys.add(key);
        NotificationService.sendGuideNotifications(
          result,
          fieldName ?? 'Tarla',
          fieldId: fieldId,
          notificationIdSeed: fieldId.hashCode.abs() % 100,
          alertJournal: ref.read(alertJournalServiceProvider),
        );
      });
    });

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text(
          fieldName != null ? '$fieldName · Rehber' : 'Bugünün Rehberi',
          style: AppText.h2(context),
        ),
        backgroundColor: AppColors.surface,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Yenile',
            onPressed: () => ref.invalidate(fieldGuideProvider(fieldId)),
          ),
          IconButton(
            icon: const Icon(Icons.help_outline_rounded),
            tooltip: 'Yardım',
            onPressed: () => HelpPanel.show(context, HelpContent.dailyGuide),
          ),
        ],
      ),
      body: guideAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline,
                    size: 48, color: AppColors.error),
                const SizedBox(height: 12),
                Text('Rehber yüklenemedi: $e',
                    textAlign: TextAlign.center, style: AppText.body(context)),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () => ref.invalidate(fieldGuideProvider(fieldId)),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Tekrar Dene'),
                ),
              ],
            ),
          ),
        ),
        data: (result) => _buildBody(context, ref, result, growthAsync),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    WidgetRef ref,
    GuideResult result,
    AsyncValue<List<dynamic>> growthAsync,
  ) {
    final liveTodosAsync = ref.watch(fieldLiveTodosProvider(fieldId));

    return RefreshIndicator(
      onRefresh: () async {
        ref.read(recomputeNowProvider(fieldId))();
        ref.invalidate(fieldGuideProvider(fieldId));
        ref.invalidate(_dailyGuideFieldContextProvider(fieldId));
        ref.invalidate(fieldCropsStreamProvider(fieldId));
        ref.invalidate(fieldScheduledAutoSeedProvider(fieldId));
        ref.invalidate(fieldGrowthStatesProvider(fieldId));
        // Yeni futures resolve olana kadar bekle — kullanıcı spinner görür.
        await ref.read(fieldLiveTodosProvider(fieldId).future);
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Son güncelleme çubuğu — kullanıcı tavsiyenin ne zaman hesaplandığını görür.
          _FreshnessBar(
            asyncValue: liveTodosAsync,
            onRefresh: () => ref.read(recomputeNowProvider(fieldId))(),
          ),
          // Alerts banner
          if (result.alerts.isNotEmpty) ...[
            for (final alert in result.alerts) _AlertBanner(alert: alert),
            const SizedBox(height: 8),
          ],

          liveTodosAsync.maybeWhen(
            data: (recs) {
              if (recs.isEmpty && result.isEmpty) {
                return const _EmptyGuideState();
              }
              return _LiveTodoSections(
                recommendations: recs,
                onShown: (r) {
                  ref
                      .read(recommendationLedgerProvider)
                      .markShown(ruleKey: r.ruleKey, target: r.target);
                },
                onLogged: () {
                  ref.invalidate(fieldLiveTodosProvider(fieldId));
                  ref.invalidate(fieldGuideProvider(fieldId));
                },
              );
            },
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator()),
            ),
            orElse: () => const SizedBox.shrink(),
          ),

          _CropDailyGuideSection(
            fieldId: fieldId,
            fieldName: fieldName,
          ),

          // DURUM (tek bakış)
          growthAsync.maybeWhen(
            data: (states) => states.isEmpty
                ? const SizedBox.shrink()
                : _StatusCard(states: states),
            orElse: () => const SizedBox.shrink(),
          ),

          // BİLMENİZ GEREKENLER
          if (result.insights.isNotEmpty) ...[
            const SizedBox(height: 16),
            _SectionHeader(label: 'BİLMENİZ GEREKENLER', count: null),
            for (final insight in result.insights)
              _InsightCard(insight: insight),
          ],
        ],
      ),
    );
  }
}

/// Ekili bitki bazlı gün-gün rehber özeti.
class _CropDailyGuideSection extends ConsumerWidget {
  final String fieldId;
  final String? fieldName;

  const _CropDailyGuideSection({
    required this.fieldId,
    required this.fieldName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contextAsync = ref.watch(_dailyGuideFieldContextProvider(fieldId));
    final cropsAsync = ref.watch(fieldCropsStreamProvider(fieldId));
    final activitiesAsync = ref.watch(fieldActivityLogProvider(fieldId));
    final scheduledAsync = ref.watch(fieldScheduledAutoSeedProvider(fieldId));
    final growthAsync = ref.watch(fieldGrowthStatesProvider(fieldId));
    final recsAsync = ref.watch(fieldLiveTodosProvider(fieldId));

    final isLoading = [
      contextAsync,
      cropsAsync,
      activitiesAsync,
      scheduledAsync,
      growthAsync,
      recsAsync,
    ].any((value) => value.isLoading && !value.hasValue);

    final crops = cropsAsync.valueOrNull ?? const <Map<String, dynamic>>[];
    if (isLoading && crops.isEmpty) {
      return const _CropGuideInfoCard(
        icon: Icons.eco_rounded,
        title: 'Ekili bitkiler hazırlanıyor',
        body: 'Canlı rehber tarladaki ekim kayıtlarını kontrol ediyor.',
      );
    }

    if (crops.isEmpty) {
      return const _CropGuideInfoCard(
        icon: Icons.add_location_alt_rounded,
        title: 'Bu tarlada ekili bitki yok',
        body:
            'Ekle düğmesiyle toplu ekim bölgesi çizince gün gün bitki rehberi burada görünür.',
      );
    }

    final fieldContext = contextAsync.valueOrNull ??
        const _DailyGuideFieldContext(field: null, dailyForecast: []);
    final activities =
        activitiesAsync.valueOrNull ?? const <Map<String, dynamic>>[];
    final scheduled =
        scheduledAsync.valueOrNull ?? const <Map<String, dynamic>>[];
    final growthList = growthAsync.valueOrNull ?? const <dynamic>[];
    final recommendations = recsAsync.valueOrNull ?? const <Recommendation>[];
    final planService = ref.read(cropDailyPlanServiceProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 4),
        _SectionHeader(label: 'EKİLİ BİTKİLER', count: crops.length),
        for (final crop in crops)
          _CropDailyGuideCard(
            fieldId: fieldId,
            fieldName: fieldName ?? fieldContext.name,
            fieldContext: fieldContext,
            crop: crop,
            plan: planService.build(
              crop: crop,
              fieldId: fieldId,
              areaDekar: fieldContext.areaDekar,
              activities: activities,
              scheduledEvents: scheduled,
              dailyForecast: fieldContext.dailyForecast,
              growthState: _growthToMap(
                _findGrowthForCrop(growthList, crop['id']?.toString()),
              ),
            ),
            guide: TurkiyeCropGuides.lookup(crop['name']?.toString() ?? ''),
            progress: CropProtocolService.computeProgress(
              crop: crop,
              activities:
                  _activitiesForCrop(activities, crop['id']?.toString()),
              fieldId: fieldId,
            ),
            recommendations: _recommendationsForCrop(
              recommendations,
              crop['id']?.toString(),
            ),
          ),
      ],
    );
  }
}

class _CropDailyGuideCard extends StatelessWidget {
  final String fieldId;
  final String fieldName;
  final _DailyGuideFieldContext fieldContext;
  final Map<String, dynamic> crop;
  final CropDailyPlanResult? plan;
  final TurkiyeCropGuide? guide;
  final CropProtocolProgress? progress;
  final List<Recommendation> recommendations;

  const _CropDailyGuideCard({
    required this.fieldId,
    required this.fieldName,
    required this.fieldContext,
    required this.crop,
    required this.plan,
    required this.guide,
    required this.progress,
    required this.recommendations,
  });

  @override
  Widget build(BuildContext context) {
    final cropName = crop['name']?.toString() ?? 'Bitki';
    final cropId = crop['id']?.toString() ?? '';
    final today = plan?.today;
    final openTasks =
        today?.tasks.where((task) => !task.done).take(3).toList() ??
            const <DayTask>[];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.md,
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.mint,
                  borderRadius: AppRadius.sm,
                ),
                child: Text(
                  _cropEmoji(cropName),
                  style: const TextStyle(fontSize: 22),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cropName,
                      style: AppText.bodyMd(context).copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      today == null
                          ? 'Türkiye rehberi ve canlı tarla notları'
                          : '${today.stageLabel} · ${today.dayIndex}. gün',
                      style: AppText.xs(context)
                          .copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              _TinyPill(
                label: plan == null ? 'Türkiye' : 'Gün gün',
                color: plan == null ? AppColors.soil : AppColors.emeraldDark,
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (plan != null && today != null) ...[
            _WaterLine(day: today, remainingSeasonMm: plan!.remainingSeasonMm),
            const SizedBox(height: 10),
            if (openTasks.isEmpty)
              _MutedLine(
                icon: Icons.check_circle_rounded,
                text: today.hasOpenTask
                    ? 'Açık iş kalmadı; kayıtlar güncellenmiş görünüyor.'
                    : 'Bugün sakin takip günü. Gözlem ve hava değişimini izle.',
              )
            else
              for (final task in openTasks) _TaskLine(task: task),
            if (recommendations.isNotEmpty) ...[
              const SizedBox(height: 10),
              _RecommendationLine(recommendation: recommendations.first),
            ],
          ] else
            _FallbackGuideBlock(
              guide: guide,
              progress: progress,
              recommendations: recommendations,
            ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: cropId.isEmpty
                  ? null
                  : () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => CropDailyPlanScreen(
                            fieldId: fieldId,
                            cropId: cropId,
                            fieldName: fieldName,
                            latitude: fieldContext.latitude,
                            longitude: fieldContext.longitude,
                            areaDekar: fieldContext.areaDekar,
                          ),
                        ),
                      );
                    },
              icon: const Icon(Icons.calendar_month_rounded, size: 18),
              label: const Text('Tam Günlük Rehber'),
            ),
          ),
        ],
      ),
    );
  }
}

class _WaterLine extends StatelessWidget {
  final DayPlan day;
  final double remainingSeasonMm;

  const _WaterLine({
    required this.day,
    required this.remainingSeasonMm,
  });

  @override
  Widget build(BuildContext context) {
    final rainText = day.waterRainMm > 0
        ? ', yağış ${_fmtMm(day.waterRainMm)}'
        : ', yağış beklenmiyor';
    return _MutedLine(
      icon: Icons.water_drop_rounded,
      text:
          'Bugün hedef ${_fmtMm(day.waterTargetMm)}, kalan ${_fmtMm(day.waterRemainingMm)}$rainText. Sezon kalan ${_fmtMm(remainingSeasonMm)}.',
    );
  }
}

class _TaskLine extends StatelessWidget {
  final DayTask task;

  const _TaskLine({required this.task});

  @override
  Widget build(BuildContext context) {
    final color = ActivityType.color(task.type);
    final detail = task.detail == null || task.detail!.isEmpty
        ? null
        : ' · ${task.detail}';
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(ActivityType.icon(task.type), color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${task.label}${detail ?? ''}',
              style: AppText.sm(context).copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FallbackGuideBlock extends StatelessWidget {
  final TurkiyeCropGuide? guide;
  final CropProtocolProgress? progress;
  final List<Recommendation> recommendations;

  const _FallbackGuideBlock({
    required this.guide,
    required this.progress,
    required this.recommendations,
  });

  @override
  Widget build(BuildContext context) {
    final lines = <Widget>[];
    final active = progress?.activeStep;
    if (active != null) {
      lines.add(_MutedLine(
        icon: Icons.route_rounded,
        text: '${active.stageEmoji} ${active.title}: ${active.description}',
      ));
    }
    if (guide != null) {
      lines.addAll([
        _MutedLine(
          icon: Icons.event_available_rounded,
          text:
              'Türkiye ekim aralığı: ${guide!.sowingWindow}. Hasat: ${guide!.harvestWindow}.',
        ),
        _MutedLine(
          icon: Icons.water_drop_rounded,
          text: guide!.irrigationSummary,
        ),
        _MutedLine(
          icon: Icons.spa_rounded,
          text: guide!.fertilizerSummary,
        ),
      ]);
      if (guide!.regionalCalendar.isNotEmpty) {
        final regional = guide!.regionalCalendar.first;
        lines.add(_MutedLine(
          icon: Icons.map_rounded,
          text:
              '${regional.region}: ${regional.plantingWindow}; ${regional.notes}',
        ));
      }
    }
    if (recommendations.isNotEmpty) {
      lines.add(_RecommendationLine(recommendation: recommendations.first));
    }
    if (lines.isEmpty) {
      lines.add(const _MutedLine(
        icon: Icons.info_outline_rounded,
        text:
            'Aktivite kaydı, ekim tarihi ve hava değişimi geldikçe canlı tavsiyeler burada netleşir.',
      ));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final line in lines.take(4)) ...[
          line,
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _RecommendationLine extends StatelessWidget {
  final Recommendation recommendation;

  const _RecommendationLine({required this.recommendation});

  @override
  Widget build(BuildContext context) {
    return _MutedLine(
      icon: Icons.lightbulb_rounded,
      text: '${recommendation.title}: ${recommendation.actionHint}',
      color: AppColors.emeraldDark,
    );
  }
}

class _MutedLine extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color? color;

  const _MutedLine({
    required this.icon,
    required this.text,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.textSecondary;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: c),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: AppText.sm(context).copyWith(color: AppColors.textPrimary),
          ),
        ),
      ],
    );
  }
}

class _TinyPill extends StatelessWidget {
  final String label;
  final Color color;

  const _TinyPill({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: AppRadius.full,
      ),
      child: Text(
        label,
        style: AppText.xs(context).copyWith(
          color: color,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _CropGuideInfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;

  const _CropGuideInfoCard({
    required this.icon,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.md,
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.emeraldDark, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppText.bodyMd(context)
                      .copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(body, style: AppText.sm(context)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

dynamic _findGrowthForCrop(List<dynamic> growthList, String? cropId) {
  if (cropId == null || cropId.isEmpty) return null;
  for (final growth in growthList) {
    if (_extractCropId(growth) == cropId) return growth;
  }
  return null;
}

String? _extractCropId(dynamic growth) {
  try {
    final dyn = growth as dynamic;
    return dyn.cropId as String?;
  } catch (_) {
    if (growth is Map) {
      return growth['crop_id']?.toString() ?? growth['cropId']?.toString();
    }
    return null;
  }
}

Map<String, dynamic>? _growthToMap(dynamic growth) {
  if (growth == null) return null;
  try {
    final dyn = growth as dynamic;
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
    return growth is Map ? Map<String, dynamic>.from(growth) : null;
  }
}

List<Map<String, dynamic>> _activitiesForCrop(
  List<Map<String, dynamic>> activities,
  String? cropId,
) {
  if (cropId == null || cropId.isEmpty) return activities;
  return activities.where((activity) {
    final activityCropId = activity['crop_id']?.toString();
    return activityCropId == null ||
        activityCropId.isEmpty ||
        activityCropId == cropId;
  }).toList();
}

List<Recommendation> _recommendationsForCrop(
  List<Recommendation> recommendations,
  String? cropId,
) {
  if (cropId == null || cropId.isEmpty) return const [];
  return recommendations.where((r) => r.target.cropId == cropId).toList();
}

String _fmtMm(double value) => '${value.toStringAsFixed(0)} mm';

String _cropEmoji(String cropName) {
  final normalized = cropName.toLowerCase();
  if (normalized.contains('domates')) return '🍅';
  if (normalized.contains('mısır') || normalized.contains('misir')) return '🌽';
  if (normalized.contains('ayçiçek') || normalized.contains('aycicek')) {
    return '🌻';
  }
  if (normalized.contains('buğday') || normalized.contains('bugday')) {
    return '🌾';
  }
  return '🌱';
}

/// Üst çubuk — tavsiye listesinin "ne zaman hesaplandığı" + manuel yenile.
/// AsyncValue.loading durumunda küçük bir progress, ready durumunda
/// "şimdi hesaplandı" mesajı; manuel yenile butonu kullanılabilir.
class _FreshnessBar extends StatelessWidget {
  final AsyncValue<List<Recommendation>> asyncValue;
  final VoidCallback onRefresh;

  const _FreshnessBar({
    required this.asyncValue,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final isLoading = asyncValue.isLoading || asyncValue.isRefreshing;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          if (isLoading)
            const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            const Icon(
              Icons.bolt_rounded,
              size: 14,
              color: AppColors.emerald,
            ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              isLoading
                  ? 'Tavsiyeler yenileniyor...'
                  : 'Canlı — her aktivite/değişiklikten sonra otomatik güncellenir',
              style: AppText.xs(context).copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          InkWell(
            onTap: onRefresh,
            borderRadius: AppRadius.sm,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.refresh_rounded,
                      size: 14, color: AppColors.emeraldDark),
                  const SizedBox(width: 4),
                  Text(
                    'Yenile',
                    style: AppText.xs(context).copyWith(
                      color: AppColors.emeraldDark,
                      fontWeight: FontWeight.w700,
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

class _LiveTodoSections extends StatelessWidget {
  final List<Recommendation> recommendations;
  final ValueChanged<Recommendation> onShown;
  final VoidCallback onLogged;

  const _LiveTodoSections({
    required this.recommendations,
    required this.onShown,
    required this.onLogged,
  });

  @override
  Widget build(BuildContext context) {
    if (recommendations.isEmpty) return const SizedBox.shrink();
    final urgent = recommendations
        .where((r) => r.severity == AlertSeverity.critical)
        .toList();
    final today = recommendations
        .where((r) =>
            r.severity == AlertSeverity.warning &&
            r.gate == RecommendationGate.actionable)
        .toList();
    final week = recommendations
        .where((r) =>
            r.severity == AlertSeverity.info &&
            r.gate == RecommendationGate.actionable)
        .toList();
    final watch = recommendations
        .where((r) =>
            r.gate != RecommendationGate.actionable &&
            r.severity != AlertSeverity.critical)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (urgent.isNotEmpty) ...[
          _SectionHeader(label: 'ACİL', count: urgent.length),
          for (final r in urgent)
            RecommendationCard(
              recommendation: r,
              onShown: () => onShown(r),
              onLogged: onLogged,
            ),
          const SizedBox(height: 16),
        ],
        if (today.isNotEmpty) ...[
          _SectionHeader(label: 'BUGÜN', count: today.length),
          for (final r in today)
            RecommendationCard(
              recommendation: r,
              onShown: () => onShown(r),
              onLogged: onLogged,
            ),
          const SizedBox(height: 16),
        ],
        if (week.isNotEmpty) ...[
          _SectionHeader(label: 'BU HAFTA', count: week.length),
          for (final r in week)
            RecommendationCard(
              recommendation: r,
              onShown: () => onShown(r),
              onLogged: onLogged,
            ),
          const SizedBox(height: 16),
        ],
        if (watch.isNotEmpty) ...[
          _SectionHeader(label: 'İZLE', count: watch.length),
          for (final r in watch)
            RecommendationCard(
              recommendation: r,
              onShown: () => onShown(r),
              onLogged: onLogged,
            ),
          const SizedBox(height: 16),
        ],
      ],
    );
  }
}

class _EmptyGuideState extends StatelessWidget {
  const _EmptyGuideState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.check_circle_outline,
            size: 64,
            color: AppColors.emerald,
          ),
          const SizedBox(height: 16),
          Text(
            'Şu an yapılacak bir şey yok',
            style: AppText.h3(context),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Bitkilerin yolunda. Aktivite kaydı yaptıkça rehber tazelenir.',
            style: AppText.body(context),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Section header
// ─────────────────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String label;
  final int? count;
  const _SectionHeader({required this.label, this.count});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      child: Row(
        children: [
          Text(
            label,
            style: AppText.label(context).copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
              color: AppColors.textSecondary,
            ),
          ),
          if (count != null) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.mint,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text('$count',
                  style: AppText.xs(context)
                      .copyWith(color: AppColors.emeraldDark)),
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Alert banner
// ─────────────────────────────────────────────────────────────────────────────

class _AlertBanner extends StatelessWidget {
  final EnvAlert alert;
  const _AlertBanner({required this.alert});

  Color get _bg {
    switch (alert.severity) {
      case AlertSeverity.critical:
        return const Color(0xFFFFEBEE);
      case AlertSeverity.warning:
        return const Color(0xFFFFF8E1);
      case AlertSeverity.info:
        return const Color(0xFFE3F2FD);
    }
  }

  Color get _fg {
    switch (alert.severity) {
      case AlertSeverity.critical:
        return const Color(0xFFC62828);
      case AlertSeverity.warning:
        return const Color(0xFFE65100);
      case AlertSeverity.info:
        return const Color(0xFF1565C0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _bg,
        borderRadius: AppRadius.md,
        border: Border.all(color: _fg.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(alert.icon, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  alert.title,
                  style: AppText.bodyMd(context).copyWith(
                    fontWeight: FontWeight.w800,
                    color: _fg,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  alert.message,
                  style: AppText.sm(context).copyWith(color: _fg),
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
// DURUM card
// ─────────────────────────────────────────────────────────────────────────────

class _StatusCard extends StatelessWidget {
  final List<dynamic> states;
  const _StatusCard({required this.states});

  @override
  Widget build(BuildContext context) {
    if (states.isEmpty) return const SizedBox.shrink();
    // Tüm crop'ların ortalama stres göstergeleri
    double waterDef = 0, nStress = 0, kStress = 0, disease = 0, ymul = 0;
    for (final s in states) {
      waterDef += (s.waterDeficitMm as double? ?? 0);
      nStress += (s.nStressIdx as double? ?? 0);
      try {
        kStress += (s.kStressIdx as double? ?? 0);
      } catch (_) {}
      disease += (s.diseasePressure as double? ?? 0);
      ymul += (s.yieldMultiplier as double? ?? 1.0);
    }
    final n = states.length;
    waterDef /= n;
    nStress /= n;
    kStress /= n;
    disease /= n;
    ymul /= n;

    Widget metric(String label, String value, IconData icon, Color color) {
      return Expanded(
        child: Column(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 4),
            Text(value,
                style: AppText.bodyMd(context)
                    .copyWith(fontWeight: FontWeight.w800)),
            Text(label,
                style: AppText.xs(context)
                    .copyWith(color: AppColors.textSecondary)),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.md,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(children: [
            const Icon(Icons.insights_rounded,
                color: AppColors.emerald, size: 18),
            const SizedBox(width: 8),
            Text('Durum',
                style: AppText.bodyMd(context).copyWith(
                    fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          ]),
          const SizedBox(height: 12),
          Row(
            children: [
              metric('Su açığı', '${waterDef.toStringAsFixed(0)}mm',
                  Icons.water_drop_outlined, AppColors.frost),
              metric('N stres', '%${(nStress * 100).round()}',
                  Icons.grass_outlined, AppColors.emeraldDark),
              metric('K stres', '%${(kStress * 100).round()}',
                  Icons.spa_outlined, Colors.teal.shade700),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              metric('Hastalık', '%${(disease * 100).round()}',
                  Icons.coronavirus_outlined, AppColors.warning),
              metric('Verim çarpanı', ymul.toStringAsFixed(2),
                  Icons.trending_up_rounded, AppColors.emerald),
              const Expanded(child: SizedBox.shrink()),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Insight card
// ─────────────────────────────────────────────────────────────────────────────

class _InsightCard extends StatelessWidget {
  final Insight insight;
  const _InsightCard({required this.insight});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.mint.withValues(alpha: 0.4),
        borderRadius: AppRadius.sm,
        border: Border.all(color: AppColors.emerald.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(insight.icon, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  insight.title,
                  style: AppText.bodyMd(context).copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.emeraldDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(insight.body, style: AppText.sm(context)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
