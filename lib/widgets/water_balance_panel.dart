/// Sulama planı için su bilançosu özet panosu.
///
/// `WaterBalanceEngine.compute()` çıktısını çiftçi diliyle gösterir:
///   - Toprakta kullanılabilir su (bar)
///   - Bugünkü buharlaşma + 7 günlük yağış kazancı
///   - Sonraki sulama tarihi + miktar
library;

import 'package:flutter/material.dart';

import '../services/water_balance_engine.dart';
import '../theme/app_theme.dart';

class WaterBalancePanel extends StatelessWidget {
  final WaterBalanceResult result;
  final String cropName;
  final String method;
  const WaterBalancePanel({
    super.key,
    required this.result,
    required this.cropName,
    required this.method,
  });

  static String _vol(double l) {
    if (l >= 1000) return '${(l / 1000).toStringAsFixed(1)} m³';
    return '${l.toStringAsFixed(0)} L';
  }

  static const _days = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];
  static String _dayLabel(DateTime d) => _days[d.weekday - 1];

  String _whenLabel(int? daysUntil) {
    if (daysUntil == null) return 'Hesaplanamadı';
    if (daysUntil <= 0) return 'Bugün';
    if (daysUntil == 1) return 'Yarın';
    return '$daysUntil gün sonra';
  }

  @override
  Widget build(BuildContext context) {
    final soilPct = (result.currentSoilMm / result.fieldCapacityMm).clamp(0.0, 1.0);
    final rawPct = (result.rawThresholdMm / result.fieldCapacityMm).clamp(0.0, 1.0);
    final daysUntil = result.daysUntilIrrigation;
    final urgency = daysUntil != null && daysUntil <= 0
        ? AppColors.error
        : (daysUntil != null && daysUntil <= 2)
            ? AppColors.warning
            : AppColors.emerald;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.science_outlined,
                  color: AppColors.frost, size: 18),
              const SizedBox(width: 6),
              const Text(
                'SU BİLANÇOSU',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                    color: AppColors.textSecondary),
              ),
              const Spacer(),
              Text(result.stageLabel,
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textTertiary)),
            ],
          ),
          const SizedBox(height: 10),

          // Sonraki sulama büyük başlık
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: urgency.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: urgency.withValues(alpha: 0.35)),
            ),
            child: Row(
              children: [
                Icon(Icons.water_drop_rounded, color: urgency, size: 28),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Sonraki sulama',
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary)),
                      Text(
                        result.nextIrrigationDate == null
                            ? 'Şu an gerekmiyor'
                            : '${_whenLabel(daysUntil)} (${_dayLabel(result.nextIrrigationDate!)} ${result.nextIrrigationDate!.day}.${result.nextIrrigationDate!.month})',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: urgency),
                      ),
                      if (result.recommendedDoseMm > 0)
                        Text(
                          'Önerilen: ${result.recommendedDoseMm.toStringAsFixed(0)} mm • ${_vol(result.recommendedGrossLiters)} ($method ile)',
                          style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textPrimary),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Toprak nem barı
          Row(
            children: [
              const Text('Toprakta su',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary)),
              const Spacer(),
              Text(
                '${result.currentSoilMm.toStringAsFixed(0)} / ${result.fieldCapacityMm.toStringAsFixed(0)} mm',
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Stack(
              children: [
                LinearProgressIndicator(
                  value: soilPct,
                  minHeight: 10,
                  backgroundColor: AppColors.border,
                  valueColor: AlwaysStoppedAnimation(
                      soilPct > rawPct ? AppColors.emerald : AppColors.warning),
                ),
                // Kritik eşik çizgisi
                Positioned(
                  left: rawPct * MediaQuery.of(context).size.width * 0.85,
                  top: 0,
                  bottom: 0,
                  child:
                      Container(width: 2, color: AppColors.error),
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(top: 4),
            child: Text(
              'Kırmızı çizgi: bu seviyenin altında bitki stres yaşamaya başlar.',
              style: TextStyle(fontSize: 10, color: AppColors.textTertiary),
            ),
          ),

          const SizedBox(height: 12),
          // İki metrik yan yana
          Row(
            children: [
              Expanded(
                child: _Mini(
                  icon: Icons.wb_sunny_outlined,
                  color: AppColors.warning,
                  label: 'Bugünkü buharlaşma',
                  value: '${result.todayEtcMm.toStringAsFixed(1)} mm',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _Mini(
                  icon: Icons.umbrella_outlined,
                  color: AppColors.info,
                  label: '7 gün etkili yağış',
                  value:
                      '${result.effectiveRainNext7DaysMm.toStringAsFixed(0)} mm',
                ),
              ),
            ],
          ),

          if (result.projections.isNotEmpty) ...[
            const SizedBox(height: 14),
            const _BalanceChart(),
            const SizedBox(height: 6),
            const _ChartLegend(),
          ],
        ],
      ),
    );
  }
}

class _BalanceChart extends StatelessWidget {
  const _BalanceChart();

  @override
  Widget build(BuildContext context) {
    // Widget tree'de WaterBalancePanel'in result'ına erişmek için
    // InheritedWidget yerine basitlik: parent'tan widget ağacında geri yürüt.
    final panel = context.findAncestorWidgetOfExactType<WaterBalancePanel>();
    if (panel == null) return const SizedBox.shrink();
    return SizedBox(
      height: 120,
      child: CustomPaint(
        painter: _BalanceChartPainter(panel.result),
        size: Size.infinite,
      ),
    );
  }
}

class _BalanceChartPainter extends CustomPainter {
  final WaterBalanceResult result;
  _BalanceChartPainter(this.result);

  static const _days = ['Pz', 'St', 'Çr', 'Pr', 'Cu', 'Ct', 'Pa'];

  @override
  void paint(Canvas canvas, Size size) {
    final n = result.projections.length;
    if (n == 0) return;
    const labelHeight = 16.0;
    final chartHeight = size.height - labelHeight;
    final colWidth = size.width / n;
    final barWidth = colWidth * 0.55;
    final fc = result.fieldCapacityMm;

    final soilPaint = Paint()..color = AppColors.emerald;
    final criticalPaint = Paint()..color = AppColors.warning;
    final rainPaint = Paint()..color = AppColors.info;
    final etcPaint = Paint()..color = AppColors.warning.withValues(alpha: 0.55);
    final gridPaint = Paint()
      ..color = AppColors.border
      ..strokeWidth = 1;

    // Kritik eşik çizgisi (yatay).
    final criticalY = chartHeight * (1 - result.rawThresholdMm / fc);
    canvas.drawLine(
      Offset(0, criticalY),
      Offset(size.width, criticalY),
      Paint()
        ..color = AppColors.error.withValues(alpha: 0.4)
        ..strokeWidth = 1
        ..style = PaintingStyle.stroke,
    );

    // Taban çizgisi
    canvas.drawLine(
      Offset(0, chartHeight),
      Offset(size.width, chartHeight),
      gridPaint,
    );

    for (int i = 0; i < n; i++) {
      final p = result.projections[i];
      final x = i * colWidth + (colWidth - barWidth) / 2;

      // Toprak nem barı (gün sonu)
      final soilNorm = (p.soilEndMm / fc).clamp(0.0, 1.0);
      final barH = chartHeight * soilNorm;
      final rect = Rect.fromLTWH(x, chartHeight - barH, barWidth, barH);
      canvas.drawRRect(
        RRect.fromRectAndCorners(rect,
            topLeft: const Radius.circular(3),
            topRight: const Radius.circular(3)),
        p.soilEndMm <= result.rawThresholdMm ? criticalPaint : soilPaint,
      );

      // Yağış üst etiketi (mavi nokta)
      if (p.effectiveRainMm > 0) {
        canvas.drawCircle(
          Offset(x + barWidth / 2, 6),
          4,
          rainPaint,
        );
      }

      // ETc kayıp göstergesi (barın üstüne küçük çizgi)
      if (p.etcMm > 0 && barH < chartHeight - 4) {
        final lineY = chartHeight - barH - 4;
        canvas.drawLine(
          Offset(x, lineY),
          Offset(x + barWidth, lineY),
          etcPaint..strokeWidth = 2,
        );
      }

      // Sulama günü işareti (alta su damlası ikonu yerine küçük üçgen)
      if (p.needsIrrigation) {
        final path = Path()
          ..moveTo(x + barWidth / 2, chartHeight - 2)
          ..lineTo(x + barWidth / 2 - 4, chartHeight + 4)
          ..lineTo(x + barWidth / 2 + 4, chartHeight + 4)
          ..close();
        canvas.drawPath(path, Paint()..color = AppColors.info);
      }

      // Gün etiketi
      final label = _days[(p.date.weekday - 1) % 7];
      final tp = TextPainter(
        text: TextSpan(
          text: label,
          style: const TextStyle(
              fontSize: 10,
              color: AppColors.textTertiary,
              fontWeight: FontWeight.w600),
        ),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: colWidth);
      tp.paint(
          canvas,
          Offset(x + (barWidth - tp.width) / 2,
              chartHeight + 4));
    }
  }

  @override
  bool shouldRepaint(covariant _BalanceChartPainter old) =>
      old.result != result;
}

class _ChartLegend extends StatelessWidget {
  const _ChartLegend();
  @override
  Widget build(BuildContext context) => Wrap(
        spacing: 10,
        runSpacing: 4,
        children: const [
          _LegendItem(color: AppColors.emerald, label: 'Topraktaki su'),
          _LegendItem(color: AppColors.warning, label: 'Kritik altı'),
          _LegendItem(color: AppColors.info, label: 'Yağış / sulama günü'),
        ],
      );
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendItem({required this.color, required this.label});
  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
                color: color, borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(width: 4),
          Text(label,
              style: const TextStyle(
                  fontSize: 10, color: AppColors.textTertiary)),
        ],
      );
}

class _Mini extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;
  const _Mini(
      {required this.icon,
      required this.color,
      required this.label,
      required this.value});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(height: 4),
            Text(label,
                style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.textSecondary,
                    height: 1.2)),
            const SizedBox(height: 2),
            Text(value,
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: color)),
          ],
        ),
      );
}
