import 'package:flutter/material.dart';

import '../data/activity_types.dart';
import '../services/guide_engine.dart' show AlertSeverity;
import '../services/rules/recommendation.dart';
import '../theme/app_theme.dart';

/// Deterministik kural motorundan gelen tek bir tavsiyeyi gösteren kart.
///
/// Yapı:
///   • Sol şerit + severity rozet ("Acil"/"Önemli"/"Bilgi")
///   • Başlık + 1 satır neden metni
///   • "Neden ▾" expander → reasonBullets madde madde
///   • Alt satırda actionHint + scope rozet (tarla/bölge/bitki)
class RecommendationCard extends StatefulWidget {
  final Recommendation recommendation;

  /// Kart kullanıcıya görünür hale geldiğinde çağrılır — ledger.markShown
  /// çağrısı için. Aynı build içinde defalarca tetiklenmesin diye
  /// `initState` zamanında bir kez fırlatılır.
  final VoidCallback? onShown;

  const RecommendationCard({
    super.key,
    required this.recommendation,
    this.onShown,
  });

  @override
  State<RecommendationCard> createState() => _RecommendationCardState();
}

class _RecommendationCardState extends State<RecommendationCard> {
  bool _expanded = false;

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
                          onTap: () =>
                              setState(() => _expanded = !_expanded),
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
                                    padding:
                                        const EdgeInsets.only(bottom: 3),
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
                                            style: AppText.sm(context)
                                                .copyWith(
                                                    color: AppColors
                                                        .textSecondary),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
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
                          border: Border.all(
                              color: color.withValues(alpha: 0.25)),
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
