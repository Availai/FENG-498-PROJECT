import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/activity_types.dart';
import '../services/app_providers.dart';
import '../services/guide_engine.dart' show AlertSeverity;
import '../services/rules/recommendation.dart';
import '../theme/app_theme.dart';
import 'floating_toast.dart';

/// Deterministik kural motorundan gelen tek bir tavsiyeyi gösteren kart.
///
/// Yapı:
///   • Sol şerit + severity rozet ("Acil"/"Önemli"/"Bilgi")
///   • Başlık + 1 satır neden metni
///   • "Neden ▾" expander → reasonBullets madde madde
///   • Alt satırda actionHint + scope rozet (tarla/bölge/bitki)
class RecommendationCard extends ConsumerStatefulWidget {
  final Recommendation recommendation;

  /// Kart kullanıcıya görünür hale geldiğinde çağrılır — ledger.markShown
  /// çağrısı için. Aynı build içinde defalarca tetiklenmesin diye
  /// `initState` zamanında bir kez fırlatılır.
  final VoidCallback? onShown;
  final VoidCallback? onLogged;

  const RecommendationCard({
    super.key,
    required this.recommendation,
    this.onShown,
    this.onLogged,
  });

  @override
  ConsumerState<RecommendationCard> createState() =>
      _RecommendationCardState();
}

class _RecommendationCardState extends ConsumerState<RecommendationCard> {
  bool _expanded = false;
  bool _logging = false;

  @override
  void initState() {
    super.initState();
    // İlk frame sonrası "shown" event — markShown async + yan etkili.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onShown?.call();
    });
  }

  Color _severityColor(AlertSeverity s) {
    switch (s) {
      case AlertSeverity.critical:
        return AppColors.error;
      case AlertSeverity.warning:
        return AppColors.warning;
      case AlertSeverity.info:
        return AppColors.frost;
    }
  }

  IconData _severityIcon(AlertSeverity s) {
    switch (s) {
      case AlertSeverity.critical:
        return Icons.priority_high_rounded;
      case AlertSeverity.warning:
        return Icons.warning_amber_rounded;
      case AlertSeverity.info:
        return Icons.info_outline_rounded;
    }
  }

  String _scopeLabel(ActivityScope scope) {
    switch (scope) {
      case ActivityScope.field:
        return 'Tarla';
      case ActivityScope.zone:
        return 'Bölge';
      case ActivityScope.plant:
        return 'Bitki';
    }
  }

  IconData _scopeIcon(ActivityScope scope) {
    switch (scope) {
      case ActivityScope.field:
        return Icons.crop_landscape_rounded;
      case ActivityScope.zone:
        return Icons.dashboard_rounded;
      case ActivityScope.plant:
        return Icons.local_florist_rounded;
    }
  }

  String _shortSource(String source) {
    final s = source.toLowerCase();
    if (s.contains('bku') || s.contains('bitki koruma')) return 'BKÜ';
    if (s.contains('fao')) return 'FAO-56';
    if (s.contains('tagem')) return 'TAGEM';
    if (s.contains('trakya')) return 'Trakya TAE';
    if (s.contains('tarim ve orman') || s.contains('tarım ve orman')) {
      return 'Bakanlık';
    }
    return source.length <= 22 ? source : '${source.substring(0, 22)}...';
  }

  String _buttonLabel(Recommendation r) {
    final command = r.command;
    if (command?.buttonLabel != null && command!.buttonLabel!.isNotEmpty) {
      return command.buttonLabel!;
    }
    if (command == null) return 'Kaydet';
    if (r.gate == RecommendationGate.observeFirst) {
      return 'Gözlem kaydet';
    }
    return ActivityType.actionLabel(command.activityType);
  }

  Future<void> _runCommand() async {
    final r = widget.recommendation;
    final command = r.command;
    if (command == null ||
        r.gate == RecommendationGate.blocked ||
        _logging) {
      return;
    }
    setState(() => _logging = true);
    try {
      await ref.read(activityLoggerProvider).log(
        fieldId: r.target.fieldId,
        type: command.activityType,
        cropId: r.target.cropId,
        plantInstanceId: r.target.plantInstanceId,
        scope: r.target.scope,
        subtype: command.subtype,
        note: command.note,
        quantity: command.quantity,
        quantityUnit:
            command.quantityUnit ?? ActivityType.quantityUnit(command.activityType),
        recommendedQuantity:
            command.recommendedQuantity ?? command.quantity,
        metadata: {
          ...command.metadata,
          'recommendation_rule_key': r.ruleKey,
          'recommendation_gate': r.gate.name,
          'recommendation_sources': r.sourceRefs,
          'recommendation_evidence':
              r.evidence.map((e) => e.toJson()).toList(growable: false),
          'recommendation_title': r.title,
        },
      );
      widget.onLogged?.call();
      if (!mounted) return;
      AppToast.show(
        context,
        message: '${ActivityType.actionLabel(command.activityType)} kaydedildi',
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
      if (mounted) setState(() => _logging = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.recommendation;
    final color = _severityColor(r.severity);
    final hasBullets = r.reasonBullets.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.md,
        border: Border.all(color: AppColors.border),
      ),
      child: ClipRRect(
        borderRadius: AppRadius.md,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Sol severity şeridi
              Container(width: 4, color: color),
              // İçerik
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Severity rozet + başlık
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.12),
                              borderRadius: AppRadius.sm,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(_severityIcon(r.severity),
                                    size: 12, color: color),
                                const SizedBox(width: 4),
                                Text(
                                  Recommendation.severityLabel(r.severity),
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: color,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Scope rozet
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceAlt,
                              borderRadius: AppRadius.sm,
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(_scopeIcon(r.target.scope),
                                    size: 12, color: AppColors.textSecondary),
                                const SizedBox(width: 4),
                                Text(
                                  _scopeLabel(r.target.scope),
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (r.timing != null) ...[
                            const SizedBox(width: 8),
                            _TimingChip(timing: r.timing!),
                          ],
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Başlık
                      Text(
                        r.title,
                        style: AppText.bodyMd(context).copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Tek satır neden
                      Text(
                        r.reasonText,
                        style: AppText.sm(context)
                            .copyWith(color: AppColors.textSecondary),
                      ),
                      // Neden ▾ expander
                      if (hasBullets) ...[
                        const SizedBox(height: 6),
                        InkWell(
                          onTap: () => setState(() => _expanded = !_expanded),
                          borderRadius: AppRadius.sm,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                Text(
                                  _expanded ? 'Neden gizle' : 'Neden',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.emeraldDark,
                                  ),
                                ),
                                Icon(
                                  _expanded
                                      ? Icons.expand_less_rounded
                                      : Icons.expand_more_rounded,
                                  size: 16,
                                  color: AppColors.emeraldDark,
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (_expanded)
                          Padding(
                            padding: const EdgeInsets.only(
                                left: 4, top: 2, bottom: 4),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                for (final b in r.reasonBullets)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 3),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(top: 6),
                                          child: Container(
                                            width: 4,
                                            height: 4,
                                            decoration: BoxDecoration(
                                              color: AppColors.textTertiary,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            b,
                                            style: AppText.sm(context).copyWith(
                                                color: AppColors.textSecondary),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                      ],
                      // Miktar / doz vurgusu (varsa) — büyük rakam + birim
                      if (r.command?.quantity != null &&
                          r.command!.quantityUnit != null) ...[
                        const SizedBox(height: 8),
                        _QuantityBadge(
                          quantity: r.command!.quantity!,
                          unit: r.command!.quantityUnit!,
                          color: color,
                        ),
                      ],
                      // Bağımlı kural ipucu — "Önce: ..." rozeti
                      if (r.dependsOn.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        _DependsOnNotice(
                          dependsOn: r.dependsOn,
                          color: color,
                        ),
                      ],
                      const SizedBox(height: 8),
                      // Action hint kutusu
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.08),
                          borderRadius: AppRadius.sm,
                          border:
                              Border.all(color: color.withValues(alpha: 0.25)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.task_alt_rounded,
                                size: 14, color: color),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                r.actionHint,
                                style: AppText.sm(context).copyWith(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (r.sourceRefs.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            for (final source in r.sourceRefs.take(3))
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.emerald.withValues(
                                    alpha: 0.10,
                                  ),
                                  borderRadius: AppRadius.sm,
                                  border: Border.all(
                                    color: AppColors.emerald.withValues(
                                      alpha: 0.25,
                                    ),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.verified_rounded,
                                      size: 12,
                                      color: AppColors.emeraldDark,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      _shortSource(source),
                                      style: AppText.xs(context).copyWith(
                                        color: AppColors.emeraldDark,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ],
                      if (r.gate == RecommendationGate.blocked) ...[
                        const SizedBox(height: 8),
                        _GateNotice(
                          text:
                              'Bu işlem veri veya etiket doğrulanmadan uygulanamaz.',
                          color: color,
                        ),
                      ] else if (r.command != null) ...[
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: _logging ? null : _runCommand,
                            icon: _logging
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Icon(
                                    r.gate == RecommendationGate.observeFirst
                                        ? Icons.manage_search_rounded
                                        : Icons.check_rounded,
                                    size: 18,
                                  ),
                            label: Text(_buttonLabel(r)),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TimingChip extends StatelessWidget {
  final RecommendationTiming timing;
  const _TimingChip({required this.timing});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.frost.withValues(alpha: 0.12),
        borderRadius: AppRadius.sm,
        border: Border.all(color: AppColors.frost.withValues(alpha: 0.30)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.schedule_rounded, size: 12, color: AppColors.frost),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              timing.descriptor,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.frost,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuantityBadge extends StatelessWidget {
  final double quantity;
  final String unit;
  final Color color;
  const _QuantityBadge({
    required this.quantity,
    required this.unit,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: AppRadius.sm,
        border: Border.all(color: color.withValues(alpha: 0.30)),
      ),
      child: Row(
        children: [
          Icon(Icons.straighten_rounded, size: 16, color: color),
          const SizedBox(width: 8),
          Text(
            quantity >= 100
                ? quantity.toStringAsFixed(0)
                : quantity.toStringAsFixed(1),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            unit,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'tavsiye edilen miktar',
            style: AppText.xs(context).copyWith(color: AppColors.textTertiary),
          ),
        ],
      ),
    );
  }
}

class _DependsOnNotice extends StatelessWidget {
  final List<String> dependsOn;
  final Color color;
  const _DependsOnNotice({required this.dependsOn, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.link_rounded, size: 12, color: color),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            'Önce yapılması gereken: ${_summarize(dependsOn)}',
            style: AppText.xs(context).copyWith(
              color: AppColors.textSecondary,
              fontStyle: FontStyle.italic,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  String _summarize(List<String> keys) {
    if (keys.isEmpty) return '-';
    final first = keys.first;
    if (first.contains('.scout')) return 'Tarla gözlemi';
    if (first.contains('.followup')) return 'Takip gözlemi';
    if (first.contains('.observation')) return 'Gözlem';
    return first;
  }
}

class _GateNotice extends StatelessWidget {
  final String text;
  final Color color;

  const _GateNotice({
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: AppRadius.sm,
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(Icons.lock_outline_rounded, size: 14, color: color),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: AppText.sm(context).copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
