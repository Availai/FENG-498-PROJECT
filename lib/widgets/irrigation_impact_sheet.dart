/// Sulama kaydı sonrası gösterilen etki özeti.
///
/// Çiftçinin az önce kaydettiği sulamanın:
///   - Verilen toplam suyu,
///   - Yöntem verimine göre etkili kullanımı (mm + L),
///   - Buharlaşma + sızma kaybı,
///   - Karık/salma ile karşılaştırması (ne kadarı boşa giderdi?),
///   - SDI/damla alternatifiyle karşılaştırması (ne kadarını kurtarırdı?),
///   - Sonraki sulama kabaca ne zaman gerekecek?
/// gibi bilgileri Türkçe ve sahada okunaklı şekilde sunar.
///
/// Kaynak: `assets/data/irrigation_methods.json` (TAGEM, SYGM).
/// Hesap: `WaterAccounting.methodEfficiency()` deterministik fonksiyonu.
library;

import 'package:flutter/material.dart';

import '../services/water_accounting.dart';
import '../theme/app_theme.dart';

class IrrigationImpactData {
  final String method;
  final double givenLiters;
  final double effectiveLiters;
  final double effectiveMm;
  final double areaSqm;
  final double? weeklyTargetMm;
  final String? stageLabel;

  const IrrigationImpactData({
    required this.method,
    required this.givenLiters,
    required this.effectiveLiters,
    required this.effectiveMm,
    required this.areaSqm,
    this.weeklyTargetMm,
    this.stageLabel,
  });

  double get lostLiters => (givenLiters - effectiveLiters).clamp(0, double.infinity);
  double get efficiency =>
      givenLiters > 0 ? (effectiveLiters / givenLiters) : 0;
}

Future<void> showIrrigationImpactSheet({
  required BuildContext context,
  required IrrigationImpactData data,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _ImpactSheet(data: data),
  );
}

class _ImpactSheet extends StatelessWidget {
  final IrrigationImpactData data;
  const _ImpactSheet({required this.data});

  static String _vol(double liters) {
    if (liters >= 1000) return '${(liters / 1000).toStringAsFixed(1)} m³';
    return '${liters.toStringAsFixed(0)} L';
  }

  static String _pct(double v) => '%${(v * 100).toStringAsFixed(0)}';

  @override
  Widget build(BuildContext context) {
    // Karşılaştırma: aynı verilen suyu farklı yöntemlerle vermiş olsaydık.
    final furrowEff = WaterAccounting.methodEfficiency('Karık sulama');
    final dripEff = WaterAccounting.methodEfficiency('Damla sulama');
    final sdiEff = WaterAccounting.methodEfficiency('Yüzey altı damla (SDI)');

    final furrowEffective = data.givenLiters * furrowEff;
    final dripEffective = data.givenLiters * dripEff;
    final sdiEffective = data.givenLiters * sdiEff;

    final dripDelta = dripEffective - data.effectiveLiters;
    final sdiDelta = sdiEffective - data.effectiveLiters;
    final furrowDelta = data.effectiveLiters - furrowEffective;

    final targetPct = data.weeklyTargetMm != null && data.weeklyTargetMm! > 0
        ? (data.effectiveMm / data.weeklyTargetMm! * 100).clamp(0, 999)
        : null;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      minChildSize: 0.45,
      builder: (_, scroll) => Container(
        decoration: const BoxDecoration(
          color: AppColors.bg,
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        ),
        child: ListView(
          controller: scroll,
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Başlık
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: AppColors.frostBg,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.water_drop_rounded,
                      color: AppColors.frost, size: 22),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Sulama Kaydedildi',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${data.method} • ${_vol(data.givenLiters)} verildi',
              style: const TextStyle(
                  fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 18),

            // Ana metrikler
            _BigMetric(
              label: 'Etkili kullanım',
              value: _vol(data.effectiveLiters),
              sub: '${data.effectiveMm.toStringAsFixed(1)} mm • verim ${_pct(data.efficiency)}',
              color: AppColors.emerald,
              icon: Icons.check_circle_rounded,
            ),
            const SizedBox(height: 10),
            _BigMetric(
              label: 'Buharlaşma + sızma kaybı',
              value: _vol(data.lostLiters),
              sub: data.lostLiters > 0
                  ? 'Yöntemin doğal kaybı — düşük verimli yöntemlerde daha yüksek olur'
                  : 'Bu yöntemde kayıp ihmal edilebilir',
              color: data.lostLiters / (data.givenLiters == 0 ? 1 : data.givenLiters) >
                      0.3
                  ? AppColors.warning
                  : AppColors.textTertiary,
              icon: Icons.cloud_outlined,
            ),

            if (targetPct != null) ...[
              const SizedBox(height: 10),
              _BigMetric(
                label: 'Haftalık hedef karşılama',
                value: '%${targetPct.toStringAsFixed(0)}',
                sub: data.stageLabel != null
                    ? '${data.stageLabel} • hedef ${data.weeklyTargetMm!.toStringAsFixed(0)} mm/hafta'
                    : 'Bu sulamayla haftalık hedefin bu kadarı karşılandı',
                color: targetPct < 50
                    ? AppColors.warning
                    : (targetPct > 130
                        ? AppColors.error
                        : AppColors.emerald),
                icon: targetPct < 50
                    ? Icons.trending_down_rounded
                    : (targetPct > 130
                        ? Icons.warning_amber_rounded
                        : Icons.trending_flat_rounded),
              ),
            ],

            const SizedBox(height: 22),
            _SectionLabel('Diğer Yöntemlerle Karşılaştırma'),
            const SizedBox(height: 4),
            const Text(
              'Aynı miktar suyu farklı yöntemlerle verseydiniz tarlaya ne kadar etkili su geçerdi?',
              style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  height: 1.4),
            ),
            const SizedBox(height: 12),

            _ComparisonRow(
              label: 'Karık / salma',
              effective: furrowEffective,
              efficiency: furrowEff,
              isCurrent: data.method.toLowerCase().contains('karık') ||
                  data.method.toLowerCase().contains('salma'),
              deltaVsCurrent: -furrowDelta,
            ),
            _ComparisonRow(
              label: 'Yağmurlama',
              effective: data.givenLiters * 0.75,
              efficiency: 0.75,
              isCurrent: data.method.toLowerCase().contains('yağmurlama') &&
                  !data.method.toLowerCase().contains('mikro'),
              deltaVsCurrent: (data.givenLiters * 0.75) - data.effectiveLiters,
            ),
            _ComparisonRow(
              label: 'Mikro yağmurlama',
              effective: data.givenLiters * 0.85,
              efficiency: 0.85,
              isCurrent: data.method.toLowerCase().contains('mikro'),
              deltaVsCurrent: (data.givenLiters * 0.85) - data.effectiveLiters,
            ),
            _ComparisonRow(
              label: 'Damla sulama',
              effective: dripEffective,
              efficiency: dripEff,
              isCurrent: data.method.toLowerCase().contains('damla') &&
                  !data.method.toLowerCase().contains('alt'),
              deltaVsCurrent: dripDelta,
            ),
            _ComparisonRow(
              label: 'Yüzey altı damla (SDI)',
              effective: sdiEffective,
              efficiency: sdiEff,
              isCurrent: data.method.toLowerCase().contains('alt') ||
                  data.method.toLowerCase().contains('sdi'),
              deltaVsCurrent: sdiDelta,
            ),

            const SizedBox(height: 18),
            if (sdiDelta > 0)
              _AdviceCard(
                color: AppColors.emerald,
                icon: Icons.savings_rounded,
                text:
                    'SDI (yüzey altı damla) ile aynı suyla ~${_vol(sdiDelta)} '
                    'daha fazla etkili su sağlanabilirdi. Geçiş için KKYDP '
                    'hibe desteği ve DSİ modernizasyon programları mevcuttur.',
              )
            else
              _AdviceCard(
                color: AppColors.emeraldDark,
                icon: Icons.verified_rounded,
                text:
                    'Bu yöntem en yüksek verim grubunda. Damlatıcı filtrasyonu '
                    've sezon başı bakım ihmal edilmezse verim korunur.',
              ),

            const SizedBox(height: 10),
            _AdviceCard(
              color: AppColors.info,
              icon: Icons.schedule_rounded,
              text:
                  'Sonraki sulama için: günlük plana göz atın. Sıcak ve rüzgârlı '
                  'günlerde aralık kısalır; yağışlı günlerde uzar.',
            ),

            const SizedBox(height: 10),
            _AdviceCard(
              color: AppColors.textTertiary,
              icon: Icons.lightbulb_outline_rounded,
              text:
                  'Sahada 06:00-09:00 ve 18:00 sonrası en az buharlaşma; '
                  'öğle saatlerinde verimliliği düşürür. Malçlama topraktaki '
                  'nemi daha uzun korur.',
            ),

            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.infoBg,
                borderRadius: BorderRadius.circular(10),
                border:
                    Border.all(color: AppColors.info.withValues(alpha: 0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline,
                      size: 16, color: AppColors.info),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Verim katsayıları TAGEM ve suverimliligi.gov.tr aralıklarının ortalamasıdır. Tarla bazlı kesin değer için DSİ/ziraat odası ile görüşün.',
                      style: TextStyle(
                          fontSize: 11, color: AppColors.textSecondary, height: 1.35),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.emerald,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Anladım',
                    style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BigMetric extends StatelessWidget {
  final String label;
  final String value;
  final String sub;
  final Color color;
  final IconData icon;
  const _BigMetric({
    required this.label,
    required this.value,
    required this.sub,
    required this.color,
    required this.icon,
  });
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.30)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                          letterSpacing: 0.3)),
                  const SizedBox(height: 2),
                  Text(value,
                      style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: color)),
                  const SizedBox(height: 2),
                  Text(sub,
                      style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                          height: 1.3)),
                ],
              ),
            ),
          ],
        ),
      );
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);
  @override
  Widget build(BuildContext context) => Text(text.toUpperCase(),
      style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: AppColors.textSecondary,
          letterSpacing: 0.6));
}

class _ComparisonRow extends StatelessWidget {
  final String label;
  final double effective;
  final double efficiency;
  final bool isCurrent;
  final double deltaVsCurrent;
  const _ComparisonRow({
    required this.label,
    required this.effective,
    required this.efficiency,
    required this.isCurrent,
    required this.deltaVsCurrent,
  });

  String _vol(double liters) {
    if (liters >= 1000) return '${(liters / 1000).toStringAsFixed(1)} m³';
    return '${liters.toStringAsFixed(0)} L';
  }

  @override
  Widget build(BuildContext context) {
    final bg = isCurrent ? AppColors.frostBg : AppColors.surface;
    final accent = isCurrent ? AppColors.frost : AppColors.textTertiary;
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        border:
            Border.all(color: accent.withValues(alpha: isCurrent ? 0.5 : 0.2)),
      ),
      child: Row(
        children: [
          if (isCurrent)
            const Padding(
              padding: EdgeInsets.only(right: 6),
              child: Icon(Icons.radio_button_checked,
                  size: 14, color: AppColors.frost),
            ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: isCurrent
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: AppColors.textPrimary)),
                Text('Verim: %${(efficiency * 100).toStringAsFixed(0)}',
                    style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textTertiary)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(_vol(effective),
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary)),
              if (!isCurrent)
                Text(
                  deltaVsCurrent > 0
                      ? '+${_vol(deltaVsCurrent)} daha iyi'
                      : '${_vol(deltaVsCurrent.abs())} daha kötü',
                  style: TextStyle(
                      fontSize: 10,
                      color: deltaVsCurrent > 0
                          ? AppColors.emerald
                          : AppColors.warning,
                      fontWeight: FontWeight.w600),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AdviceCard extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String text;
  const _AdviceCard(
      {required this.color, required this.icon, required this.text});
  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(text,
                  style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textPrimary,
                      height: 1.4)),
            ),
          ],
        ),
      );
}
