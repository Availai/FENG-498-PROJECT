import 'package:flutter/material.dart';

import '../services/field_state_service.dart';
import '../services/guardrails/guardrail_limit.dart';
import '../theme/app_theme.dart';

/// Yaşlı çiftçi için tek bakışlık tarla durum kartı.
///
/// "Alınan her karar, yapılan her eylem kendini hissettirmeli" hedefinin
/// görsel tarafı: son sulamadan beri geçen süre, bu haftanın su durumu (renk
/// + yüzde), ve varsa aşırı girdi (guardrail) uyarısı tek kartta toplanır.
///
/// Saf presentational widget (CLAUDE.md §22 ruhu): durum dışarıdan
/// [CropFieldState] + opsiyonel guardrail verdict listesiyle gelir; widget
/// hesap yapmaz, yalnızca gösterir. UI kit (§5.3) ve erişilebilirlik (§5.4:
/// min 13px, yüksek kontrast) kurallarına uyar.
class FieldStatusBadge extends StatelessWidget {
  const FieldStatusBadge({
    super.key,
    required this.state,
    this.activeVerdicts = const [],
    this.now,
  });

  final CropFieldState state;

  /// O an geçerli olan guardrail uyarıları (warn/block). Boşsa "her şey yolunda"
  /// yeşil durum gösterilir. `ok` seviyesindekiler çağıran tarafça filtrelenir.
  final List<GuardrailVerdict> activeVerdicts;

  final DateTime? now;

  @override
  Widget build(BuildContext context) {
    final t = now ?? DateTime.now();
    final worst = _worstLevel();
    final accent = _accentFor(worst);
    final bg = _bgFor(worst);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: AppRadius.lg,
        border: Border.all(color: accent.withValues(alpha: 0.35)),
        boxShadow: AppShadows.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(_iconFor(worst), color: accent, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _headlineFor(worst),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: accent,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Su durumu satırı — renk + yüzde + son sulama.
          _waterRow(),
          if (state.lastFertilizedAt != null) ...[
            const SizedBox(height: 8),
            _infoRow(
              icon: Icons.grass_rounded,
              color: AppColors.emeraldDark,
              label: 'Son gübreleme',
              value: '${state.fertilizerSummary} • '
                  '${_relativeDays(state.lastFertilizedAt!, t)}',
            ),
          ],
          if (state.lastSprayedAt != null) ...[
            const SizedBox(height: 8),
            _infoRow(
              icon: Icons.science_rounded,
              color: AppColors.warning,
              label: 'Son ilaçlama',
              value: '${state.spraySummary} • '
                  '${_relativeDays(state.lastSprayedAt!, t)}',
            ),
          ],
          // Aktif guardrail uyarıları — gerekçe + öneri.
          if (activeVerdicts.isNotEmpty) ...[
            const SizedBox(height: 12),
            ...activeVerdicts.map(_verdictTile),
          ],
        ],
      ),
    );
  }

  Widget _waterRow() {
    final ratio = state.weeklyWaterRatio;
    final pct = (ratio * 100).round();
    final waterColor = _waterColorFor(ratio);
    final lastWater = state.lastWateredAt;
    final t = now ?? DateTime.now();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.water_drop_rounded,
                color: AppColors.frost, size: 18),
            const SizedBox(width: 6),
            Text(
              'Bu hafta su',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: waterColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '%$pct',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: waterColor,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: ratio.clamp(0.0, 1.0).toDouble(),
            minHeight: 8,
            backgroundColor: AppColors.border,
            valueColor: AlwaysStoppedAnimation(waterColor),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          lastWater == null
              ? 'Henüz sulama kaydı yok'
              : 'Son sulama: ${_relativeDays(lastWater, t)} • ${state.waterSummary}',
          style: TextStyle(
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _infoRow({
    required IconData icon,
    required Color color,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 6),
        Expanded(
          child: RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: '$label: ',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                TextSpan(
                  text: value,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _verdictTile(GuardrailVerdict v) {
    final color =
        v.level == GuardrailLevel.block ? AppColors.error : AppColors.warning;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: AppRadius.md,
        border: Border.all(color: color.withValues(alpha: 0.30)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                v.level == GuardrailLevel.block
                    ? Icons.report_problem_rounded
                    : Icons.warning_amber_rounded,
                color: color,
                size: 16,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  v.reasonTr,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
          if (v.recommendationTr.isNotEmpty) ...[
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(left: 22),
              child: Text(
                v.recommendationTr,
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  height: 1.35,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Durum seviyesi yardımcıları ─────────────────────────────────────
  GuardrailLevel _worstLevel() {
    var worst = GuardrailLevel.ok;
    for (final v in activeVerdicts) {
      if (v.level == GuardrailLevel.block) return GuardrailLevel.block;
      if (v.level == GuardrailLevel.warn) worst = GuardrailLevel.warn;
    }
    return worst;
  }

  Color _accentFor(GuardrailLevel level) {
    switch (level) {
      case GuardrailLevel.block:
        return AppColors.error;
      case GuardrailLevel.warn:
        return AppColors.warning;
      case GuardrailLevel.ok:
        return AppColors.emeraldDark;
    }
  }

  Color _bgFor(GuardrailLevel level) {
    switch (level) {
      case GuardrailLevel.block:
        return AppColors.errorBg;
      case GuardrailLevel.warn:
        return AppColors.warningBg;
      case GuardrailLevel.ok:
        return AppColors.surface;
    }
  }

  IconData _iconFor(GuardrailLevel level) {
    switch (level) {
      case GuardrailLevel.block:
        return Icons.report_problem_rounded;
      case GuardrailLevel.warn:
        return Icons.warning_amber_rounded;
      case GuardrailLevel.ok:
        return Icons.check_circle_rounded;
    }
  }

  String _headlineFor(GuardrailLevel level) {
    switch (level) {
      case GuardrailLevel.block:
        return '${state.cropName} • Dikkat gerekiyor';
      case GuardrailLevel.warn:
        return '${state.cropName} • Göz atın';
      case GuardrailLevel.ok:
        return '${state.cropName} • Durum iyi';
    }
  }

  /// Su oranına göre renk: çok az/çok fazla → uyarı; ideal bant → yeşil.
  Color _waterColorFor(double ratio) {
    if (ratio >= 1.2) return AppColors.error; // aşırı su
    if (ratio >= 0.85) return AppColors.emerald; // ideal
    if (ratio >= 0.5) return AppColors.warning; // yetersiz
    return AppColors.frost; // çok az / yeni başlangıç
  }

  /// "Bugün" / "Dün" / "3 gün önce" şeklinde sade Türkçe görece zaman.
  static String _relativeDays(DateTime past, DateTime now) {
    final base = DateTime(now.year, now.month, now.day);
    final day = DateTime(past.year, past.month, past.day);
    final diff = base.difference(day).inDays;
    if (diff <= 0) return 'bugün';
    if (diff == 1) return 'dün';
    return '$diff gün önce';
  }
}
