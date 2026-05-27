/// Tarla detay ekranı için "son sulama" özet kartı.
///
/// Pure widget — aktivite listesinden son sulamayı bulup,
/// kullanılan yöntem, miktar ve etkili kullanımla, bu sezon
/// toplam sulamayı gösterir. Veri kaynağı: `Activities` (Drift)
/// metadata alanı (`activity_quick_log` tarafından doldurulur).
library;

import 'package:flutter/material.dart';

import '../data/activity_types.dart';
import '../theme/app_theme.dart';

class LastIrrigationCard extends StatelessWidget {
  final List<Map<String, dynamic>> activities;
  final DateTime? seasonStart;
  final double fieldAreaDekar;
  final VoidCallback? onTap;

  const LastIrrigationCard({
    super.key,
    required this.activities,
    this.seasonStart,
    this.fieldAreaDekar = 1.0,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final waterings = activities
        .where((a) => a['type'] == ActivityType.watering)
        .toList()
      ..sort((a, b) {
        final da = a['date'];
        final db = b['date'];
        if (da is DateTime && db is DateTime) return db.compareTo(da);
        return 0;
      });

    if (waterings.isEmpty) return const _EmptyState();

    final last = waterings.first;
    final lastDate = last['date'] is DateTime
        ? last['date'] as DateTime
        : DateTime.tryParse(last['date']?.toString() ?? '') ?? DateTime.now();
    final lastMeta =
        (last['metadata'] as Map?)?.cast<String, dynamic>() ?? const {};
    final method = (lastMeta['irrigation_method'] as String?) ?? 'Bilinmiyor';
    final givenLiters = (lastMeta['water_liters'] as num?)?.toDouble() ?? 0;
    final effectiveMm =
        (lastMeta['effective_water_mm'] as num?)?.toDouble() ?? 0;

    final since = seasonStart ?? DateTime(lastDate.year, 1, 1);
    double seasonTotalLiters = 0;
    double seasonTotalMm = 0;
    int seasonCount = 0;
    for (final w in waterings) {
      final d = w['date'];
      if (d is DateTime && d.isAfter(since)) {
        final m =
            (w['metadata'] as Map?)?.cast<String, dynamic>() ?? const {};
        seasonTotalLiters += (m['water_liters'] as num?)?.toDouble() ?? 0;
        seasonTotalMm += (m['effective_water_mm'] as num?)?.toDouble() ?? 0;
        seasonCount += 1;
      }
    }

    final daysSince = DateTime.now().difference(lastDate).inDays;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.frostBg,
          borderRadius: BorderRadius.circular(14),
          border:
              Border.all(color: AppColors.frost.withValues(alpha: 0.35)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.water_drop_rounded,
                    color: AppColors.frost, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Son Sulama',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: AppColors.frost,
                      letterSpacing: 0.3),
                ),
                const Spacer(),
                Text(
                  _whenLabel(daysSince),
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              method,
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary),
            ),
            const SizedBox(height: 4),
            Text(
              givenLiters > 0
                  ? '${_vol(givenLiters)} verildi • ${effectiveMm.toStringAsFixed(1)} mm etkili'
                  : 'Miktar girilmedi',
              style: const TextStyle(
                  fontSize: 12, color: AppColors.textSecondary),
            ),
            const Divider(height: 18),
            Row(
              children: [
                Expanded(
                  child: _MiniStat(
                    label: 'Bu sezon',
                    value: _vol(seasonTotalLiters),
                    sub: '$seasonCount sulama',
                  ),
                ),
                Container(
                    width: 1, height: 36, color: AppColors.frost.withValues(alpha: 0.2)),
                Expanded(
                  child: _MiniStat(
                    label: 'Toplam etkili',
                    value: '${seasonTotalMm.toStringAsFixed(0)} mm',
                    sub: '${fieldAreaDekar.toStringAsFixed(1)} da için',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static String _whenLabel(int daysSince) {
    if (daysSince <= 0) return 'Bugün';
    if (daysSince == 1) return 'Dün';
    if (daysSince < 7) return '$daysSince gün önce';
    if (daysSince < 30) return '${(daysSince / 7).floor()} hafta önce';
    return '${(daysSince / 30).floor()} ay önce';
  }

  static String _vol(double liters) {
    if (liters >= 1000) return '${(liters / 1000).toStringAsFixed(1)} m³';
    return '${liters.toStringAsFixed(0)} L';
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: const Row(
          children: [
            Icon(Icons.water_drop_outlined,
                color: AppColors.textTertiary, size: 20),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Henüz sulama kaydı yok. "Sulama yaptım" diyerek başlayın — her kayıt yöntem ve etkili kullanımı tarlanıza özel hesaplar.',
                style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    height: 1.35),
              ),
            ),
          ],
        ),
      );
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final String sub;
  const _MiniStat(
      {required this.label, required this.value, required this.sub});
  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(label.toUpperCase(),
              style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textTertiary,
                  letterSpacing: 0.4)),
          const SizedBox(height: 2),
          Text(value,
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.frost)),
          Text(sub,
              style: const TextStyle(
                  fontSize: 10, color: AppColors.textTertiary)),
        ],
      );
}
