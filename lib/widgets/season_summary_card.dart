import 'package:flutter/material.dart';

import '../data/crop_playbooks.dart';
import '../theme/app_theme.dart';

/// Aktivite log listesinden sezon özeti map'i türetir.
/// `LocalDataRepository.loadSeasonSummary` ile aynı shape'i üretir; ama burada
/// in-memory yapılır (ekstra DB roundtrip yok). Aktivite stream'i zaten
/// modal'da mevcut olduğu için bunu kullanmak daha ucuz.
Map<String, dynamic> computeSeasonSummary({
  required List<Map<String, dynamic>> activities,
  required String? cropId,
  DateTime? since,
}) {
  int wCount = 0, fCount = 0, sCount = 0, hCount = 0;
  double wLitersTotal = 0, fKgTotal = 0, hKgTotal = 0;
  DateTime? wLast, fLast, sLast, hLast;
  String? fLastName, sLastName, sLastActive;
  int? lastRecMm;

  for (final a in activities) {
    final aCrop = a['crop_id']?.toString();
    if (cropId != null && aCrop != null && aCrop.isNotEmpty && aCrop != cropId) {
      continue;
    }
    final date = a['date'];
    if (date is! DateTime) continue;
    if (since != null && date.isBefore(since)) continue;
    final type = a['type']?.toString();
    final meta = (a['metadata'] as Map?)?.cast<String, dynamic>() ?? const {};

    switch (type) {
      case 'watering':
        wCount++;
        final liters = (meta['water_liters'] as num?)?.toDouble();
        if (liters != null) wLitersTotal += liters;
        if (wLast == null || date.isAfter(wLast)) {
          wLast = date;
          final rec = (meta['recommended_weekly_mm'] as num?)?.toInt();
          if (rec != null) lastRecMm = rec;
        }
        break;
      case 'fertilizing':
        fCount++;
        final kg = (meta['fertilizer_kg'] as num?)?.toDouble();
        if (kg != null) fKgTotal += kg;
        if (fLast == null || date.isAfter(fLast)) {
          fLast = date;
          fLastName = meta['fertilizer_name'] as String?;
        }
        break;
      case 'spraying':
        sCount++;
        if (sLast == null || date.isAfter(sLast)) {
          sLast = date;
          sLastName = meta['pesticide_name'] as String?;
          sLastActive = meta['active_ingredient'] as String?;
        }
        break;
      case 'harvest':
        hCount++;
        final kg = (meta['harvest_kg'] as num?)?.toDouble();
        if (kg != null) hKgTotal += kg;
        if (hLast == null || date.isAfter(hLast)) hLast = date;
        break;
    }
  }

  return {
    'watering_count': wCount,
    'watering_total_liters': wLitersTotal,
    'watering_last_at': wLast,
    'watering_last_recommended_weekly_mm': lastRecMm,
    'fertilizing_count': fCount,
    'fertilizing_total_kg': fKgTotal,
    'fertilizing_last_name': fLastName,
    'fertilizing_last_at': fLast,
    'spraying_count': sCount,
    'spraying_last_name': sLastName,
    'spraying_last_active': sLastActive,
    'spraying_last_at': sLast,
    'harvest_count': hCount,
    'harvest_total_kg': hKgTotal,
    'harvest_last_at': hLast,
  };
}

/// Tarla detayında ekili bir bitki için sezon ortası özet kartı.
///
/// Tarla başında girilen bilgiler (bitki, ekim tarihi, alan) ile çiftçinin
/// tarlada yaptığı aktiviteler (sulama/gübreleme/ilaçlama/hasat) burada
/// birleşip "anlamlı" hale gelir. Soğuk veri ekrana itmek yerine son işlem
/// + kümülatif + öneri formatında sunulur.
class SeasonSummaryCard extends StatelessWidget {
  const SeasonSummaryCard({
    super.key,
    required this.cropName,
    required this.plantedDate,
    required this.areaDekar,
    required this.summary,
    this.harvestDays,
  });

  final String cropName;
  final DateTime plantedDate;
  final double areaDekar;
  final Map<String, dynamic> summary;

  /// Bitkinin toplam yetişme süresi (CropProtocol.totalDays). Hasata kalan
  /// gün sayısı için kullanılır. Null ise gizlenir.
  final int? harvestDays;

  @override
  Widget build(BuildContext context) {
    final pb = CropPlaybooks.resolveByName(cropName);
    final daysSince = DateTime.now().difference(plantedDate).inDays;
    final stage = pb?.bandForDay(daysSince)?.stage ?? 'Vejetatif';
    final daysToHarvest =
        harvestDays == null ? null : (harvestDays! - daysSince);

    final wCount = summary['watering_count'] as int? ?? 0;
    final wLast = summary['watering_last_at'] as DateTime?;
    final wTotalL = (summary['watering_total_liters'] as num?)?.toDouble() ?? 0;
    final wRecMm =
        summary['watering_last_recommended_weekly_mm'] as int?;

    final fCount = summary['fertilizing_count'] as int? ?? 0;
    final fLast = summary['fertilizing_last_at'] as DateTime?;
    final fTotalKg =
        (summary['fertilizing_total_kg'] as num?)?.toDouble() ?? 0;
    final fLastName = summary['fertilizing_last_name'] as String?;

    final sCount = summary['spraying_count'] as int? ?? 0;
    final sLast = summary['spraying_last_at'] as DateTime?;
    final sLastName = summary['spraying_last_name'] as String?;
    final sLastActive = summary['spraying_last_active'] as String?;

    final hCount = summary['harvest_count'] as int? ?? 0;
    final hTotalKg = (summary['harvest_total_kg'] as num?)?.toDouble() ?? 0;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF14241B),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.emerald.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _header(stage, daysSince, daysToHarvest),
          const SizedBox(height: 12),
          // 2x2 grid
          Row(
            children: [
              Expanded(
                child: _StatTile(
                  icon: Icons.water_drop_rounded,
                  color: AppColors.frost,
                  label: 'Sulama',
                  primary: wCount == 0
                      ? 'Henüz yok'
                      : '$wCount kez',
                  secondary: wTotalL > 0
                      ? '${_fmtLitre(wTotalL)} verildi'
                      : (wRecMm != null ? 'Öneri: $wRecMm mm/hafta' : '—'),
                  tertiary: _ago(wLast),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StatTile(
                  icon: Icons.grass_rounded,
                  color: AppColors.emeraldLight,
                  label: 'Gübreleme',
                  primary:
                      fCount == 0 ? 'Henüz yok' : '$fCount kez',
                  secondary: fTotalKg > 0
                      ? '${_fmtNum(fTotalKg)} kg toplam'
                      : '—',
                  tertiary: fLastName ?? _ago(fLast),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _StatTile(
                  icon: Icons.science_rounded,
                  color: AppColors.warning,
                  label: 'İlaçlama',
                  primary: sCount == 0 ? 'Henüz yok' : '$sCount kez',
                  secondary: sLastName ?? '—',
                  tertiary: sLastActive ?? _ago(sLast),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StatTile(
                  icon: Icons.agriculture_rounded,
                  color: AppColors.wheat,
                  label: 'Hasat',
                  primary: hCount == 0
                      ? (daysToHarvest != null && daysToHarvest > 0
                          ? '$daysToHarvest gün kaldı'
                          : '—')
                      : '$hCount parti',
                  secondary:
                      hTotalKg > 0 ? '${_fmtNum(hTotalKg)} kg' : '—',
                  tertiary: '${areaDekar.toStringAsFixed(1)} dekar',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _header(String stage, int daysSince, int? daysToHarvest) {
    final pb = CropPlaybooks.resolveByName(cropName);
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.emerald.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(8),
            border:
                Border.all(color: AppColors.emerald.withValues(alpha: 0.4)),
          ),
          child: Text(
            (pb?.displayName ?? cropName).toUpperCase(),
            style: const TextStyle(
              color: AppColors.emeraldLight,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            '$daysSince. gün · $stage',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        if (daysToHarvest != null && daysToHarvest > 0)
          Text(
            'Hasada $daysToHarvest gün',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.65),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
      ],
    );
  }

  static String _ago(DateTime? t) {
    if (t == null) return 'Henüz kayıt yok';
    final diff = DateTime.now().difference(t);
    if (diff.inMinutes < 60) return 'Az önce';
    if (diff.inHours < 24) return '${diff.inHours} saat önce';
    if (diff.inDays == 1) return 'Dün';
    if (diff.inDays < 7) return '${diff.inDays} gün önce';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()} hafta önce';
    return '${(diff.inDays / 30).floor()} ay önce';
  }

  static String _fmtNum(double v) {
    if (v == v.toInt()) return v.toInt().toString();
    return v.toStringAsFixed(1);
  }

  static String _fmtLitre(double v) {
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)} m³';
    return '${v.toStringAsFixed(0)} L';
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.color,
    required this.label,
    required this.primary,
    required this.secondary,
    required this.tertiary,
  });

  final IconData icon;
  final Color color;
  final String label;
  final String primary;
  final String secondary;
  final String tertiary;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.35), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(
                label.toUpperCase(),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: color,
                  letterSpacing: 0.6,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            primary,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            secondary,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.78),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 1),
          Text(
            tertiary,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.55),
              fontSize: 10,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
