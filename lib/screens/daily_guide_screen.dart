import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/activity_types.dart';
import '../services/app_providers.dart';
import '../services/guide_engine.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';
import '../widgets/floating_toast.dart';
import '../widgets/help_panel.dart';
import '../widgets/recommendation_card.dart';

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
            '$fieldId-${today.year}${today.month.toString().padLeft(2,'0')}${today.day.toString().padLeft(2,'0')}';
        if (_notifiedKeys.contains(key)) return;
        _notifiedKeys.add(key);
        NotificationService.sendGuideNotifications(
          result,
          fieldName ?? 'Tarla',
          fieldId: fieldId,
          notificationIdSeed: fieldId.hashCode.abs() % 100,
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
                  onPressed: () =>
                      ref.invalidate(fieldGuideProvider(fieldId)),
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
    final recommendationsAsync =
        ref.watch(fieldRecommendationsProvider(fieldId));
    if (result.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle_outline,
                  size: 64, color: AppColors.emerald),
              const SizedBox(height: 16),
              Text('Şu an yapılacak bir şey yok',
                  style: AppText.h3(context), textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text(
                'Bitkilerin yolunda. Aktivite kaydı yaptıkça rehber tazelenir.',
                style: AppText.body(context),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Alerts banner
        if (result.alerts.isNotEmpty) ...[
          for (final alert in result.alerts) _AlertBanner(alert: alert),
          const SizedBox(height: 8),
        ],

        // ÜRÜN TAVSİYELERİ — deterministik kural motoru çıktısı
        // (şu an: ayçiçeği için 5 kural; ileride mısır/buğday için genişler)
        recommendationsAsync.maybeWhen(
          data: (recs) {
            if (recs.isEmpty) return const SizedBox.shrink();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _SectionHeader(label: 'ÜRÜN TAVSİYELERİ', count: recs.length),
                for (final r in recs)
                  RecommendationCard(
                    recommendation: r,
                    onShown: () {
                      // Cooldown başlat — aynı ruleKey + target kombinasyonu
                      // pencerede tekrar üst sıraya çıkmaz.
                      ref
                          .read(recommendationLedgerProvider)
                          .markShown(ruleKey: r.ruleKey, target: r.target);
                    },
                  ),
                const SizedBox(height: 16),
              ],
            );
          },
          orElse: () => const SizedBox.shrink(),
        ),

        // BUGÜN
        if (result.today.isNotEmpty) ...[
          _SectionHeader(label: 'BUGÜN', count: result.today.length),
          for (final task in result.today)
            _TodayCard(
              task: task,
              fieldId: fieldId,
              onLogged: () => ref.invalidate(fieldGuideProvider(fieldId)),
            ),
          const SizedBox(height: 16),
        ],

        // BU HAFTA
        if (result.thisWeek.isNotEmpty) ...[
          _SectionHeader(label: 'BU HAFTA', count: result.thisWeek.length),
          _ThisWeekList(tasks: result.thisWeek),
          const SizedBox(height: 16),
        ],

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
          for (final insight in result.insights) _InsightCard(insight: insight),
        ],
      ],
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
// BUGÜN action card
// ─────────────────────────────────────────────────────────────────────────────

class _TodayCard extends ConsumerWidget {
  final UrgentTask task;
  final String fieldId;
  final VoidCallback onLogged;
  const _TodayCard({
    required this.task,
    required this.fieldId,
    required this.onLogged,
  });

  IconData get _icon {
    switch (task.kind) {
      case 'water':
        return Icons.water_drop_rounded;
      case 'fertilizer':
        return Icons.grass_rounded;
      case 'spray':
      case 'ipm':
        return Icons.science_rounded;
      case 'harvest':
        return Icons.agriculture_rounded;
      default:
        return Icons.task_alt_rounded;
    }
  }

  Color get _accent {
    switch (task.kind) {
      case 'water':
        return AppColors.frost;
      case 'fertilizer':
        return AppColors.emeraldDark;
      case 'spray':
      case 'ipm':
        return AppColors.warning;
      case 'harvest':
        return AppColors.wheat;
      default:
        return AppColors.emerald;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.md,
        border: Border.all(color: _accent.withValues(alpha: 0.4), width: 1.5),
        boxShadow: AppShadows.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _accent.withValues(alpha: 0.12),
                  borderRadius: AppRadius.sm,
                ),
                child: Icon(_icon, color: _accent, size: 26),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.headline,
                      style: AppText.bodyMd(context).copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (task.cropName != null && task.cropName!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(task.cropName!,
                          style: AppText.xs(context)
                              .copyWith(color: AppColors.textSecondary)),
                    ],
                    const SizedBox(height: 6),
                    Text(task.reason, style: AppText.sm(context)),
                  ],
                ),
              ),
            ],
          ),
          if (task.actionType != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => _logAction(context, ref),
                    icon: const Icon(Icons.check_rounded),
                    label: Text(_actionLabel(task.actionType!)),
                    style: FilledButton.styleFrom(
                      backgroundColor: _accent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _actionLabel(String type) {
    switch (type) {
      case ActivityType.watering:
        return 'Suladım';
      case ActivityType.fertilizing:
        return 'Gübreledim';
      case ActivityType.spraying:
        return 'İlaçladım';
      case ActivityType.harvest:
        return 'Hasat ettim';
      case ActivityType.scouting:
        return 'Gözlemledim';
      default:
        return 'Yaptım';
    }
  }

  Future<void> _logAction(BuildContext context, WidgetRef ref) async {
    final logger = ref.read(activityLoggerProvider);
    try {
      await logger.log(
        fieldId: fieldId,
        type: task.actionType!,
        cropId: task.cropId,
        quantity: task.suggestedQuantity,
        quantityUnit: task.quantityUnit,
        recommendedQuantity: task.recommendedQuantity,
      );
      if (!context.mounted) return;
      AppToast.show(context,
          message: 'Kaydedildi — rehber güncelleniyor.',
          type: ToastType.success);
      onLogged();
    } catch (e) {
      if (!context.mounted) return;
      AppToast.show(context,
          message: 'Kayıt başarısız: $e', type: ToastType.error);
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BU HAFTA list
// ─────────────────────────────────────────────────────────────────────────────

class _ThisWeekList extends StatelessWidget {
  final List<UpcomingTask> tasks;
  const _ThisWeekList({required this.tasks});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.md,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          for (int i = 0; i < tasks.length; i++) ...[
            ListTile(
              dense: true,
              leading: const Icon(Icons.event_available_rounded,
                  color: AppColors.emerald, size: 20),
              title: Text(tasks[i].headline,
                  style: AppText.bodyMd(context)
                      .copyWith(fontWeight: FontWeight.w600)),
              subtitle: Text(
                tasks[i].cropName != null
                    ? '${tasks[i].cropName} · ${tasks[i].reason}'
                    : tasks[i].reason,
                style: AppText.xs(context),
              ),
            ),
            if (i < tasks.length - 1)
              const Divider(height: 1, indent: 50, endIndent: 12),
          ],
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
                style:
                    AppText.xs(context).copyWith(color: AppColors.textSecondary)),
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
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary)),
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
