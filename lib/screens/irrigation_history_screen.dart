/// Sulama Geçmişi ekranı.
///
/// Bir tarla için yapılmış tüm sulamaları gösterir:
///   - Sezon özeti: toplam verilen su, toplam etkili kullanım, ortalama verim
///   - Yöntem dağılımı: hangi yöntem kaç kez, hangi oranda kullanılmış
///   - Zaman çizelgesi: her sulama (en yenisi üstte) yöntem, miktar, etki ile
///
/// Veri kaynağı: `Activities` (Drift) — `activity_quick_log` metadata'sı.
/// Pure widget; karar mantığı yok (CLAUDE.md §22).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/activity_types.dart';
import '../services/app_providers.dart';
import '../services/water_accounting.dart';
import '../theme/app_theme.dart';

class IrrigationHistoryScreen extends ConsumerWidget {
  final String fieldId;
  final String fieldName;
  final double fieldAreaDekar;
  final DateTime? seasonStart;

  const IrrigationHistoryScreen({
    super.key,
    required this.fieldId,
    required this.fieldName,
    this.fieldAreaDekar = 1.0,
    this.seasonStart,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(fieldActivityLogProvider(fieldId));
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Sulama Geçmişi'),
        backgroundColor: AppColors.frost,
        foregroundColor: Colors.white,
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Geçmiş yüklenemedi: $e',
                textAlign: TextAlign.center),
          ),
        ),
        data: (activities) => _Body(
          activities: activities,
          fieldName: fieldName,
          fieldAreaDekar: fieldAreaDekar,
          seasonStart: seasonStart,
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  final List<Map<String, dynamic>> activities;
  final String fieldName;
  final double fieldAreaDekar;
  final DateTime? seasonStart;

  const _Body({
    required this.activities,
    required this.fieldName,
    required this.fieldAreaDekar,
    required this.seasonStart,
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

    if (waterings.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.water_drop_outlined,
                  size: 64, color: AppColors.textTertiary),
              SizedBox(height: 12),
              Text(
                'Henüz sulama kaydı yok',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary),
              ),
              SizedBox(height: 6),
              Text(
                'Tarla detayından "Sulama yaptım" diyerek ilk kaydı oluştur.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 13, color: AppColors.textTertiary),
              ),
            ],
          ),
        ),
      );
    }

    final since = seasonStart ?? DateTime(DateTime.now().year, 1, 1);
    final seasonRows = waterings.where((w) {
      final d = w['date'];
      return d is DateTime && d.isAfter(since);
    }).toList();

    double totalGiven = 0;
    double totalEffectiveMm = 0;
    double totalEffectiveLiters = 0;
    final methodCount = <String, int>{};
    final methodLiters = <String, double>{};
    for (final w in seasonRows) {
      final meta =
          (w['metadata'] as Map?)?.cast<String, dynamic>() ?? const {};
      final method =
          (meta['irrigation_method'] as String?) ?? 'Bilinmiyor';
      final given = (meta['water_liters'] as num?)?.toDouble() ?? 0;
      final effL =
          (meta['effective_water_liters'] as num?)?.toDouble() ?? 0;
      final effMm = (meta['effective_water_mm'] as num?)?.toDouble() ?? 0;
      totalGiven += given;
      totalEffectiveLiters += effL;
      totalEffectiveMm += effMm;
      methodCount[method] = (methodCount[method] ?? 0) + 1;
      methodLiters[method] = (methodLiters[method] ?? 0) + given;
    }
    final avgEfficiency =
        totalGiven > 0 ? totalEffectiveLiters / totalGiven : 0;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _SeasonSummary(
          fieldName: fieldName,
          fieldAreaDekar: fieldAreaDekar,
          count: seasonRows.length,
          totalGivenLiters: totalGiven,
          totalEffectiveMm: totalEffectiveMm,
          avgEfficiency: avgEfficiency.toDouble(),
        ),
        const SizedBox(height: 16),
        if (methodCount.isNotEmpty) ...[
          _MethodDistribution(
            methodCount: methodCount,
            methodLiters: methodLiters,
            totalLiters: totalGiven,
          ),
          const SizedBox(height: 16),
        ],
        const _SectionLabel('Zaman Çizelgesi'),
        const SizedBox(height: 8),
        for (int i = 0; i < waterings.length; i++)
          _TimelineRow(
            entry: waterings[i],
            isFirst: i == 0,
            isLast: i == waterings.length - 1,
          ),
      ],
    );
  }
}

// ─── Sezon özet kartı ──────────────────────────────────────────────────────

class _SeasonSummary extends StatelessWidget {
  final String fieldName;
  final double fieldAreaDekar;
  final int count;
  final double totalGivenLiters;
  final double totalEffectiveMm;
  final double avgEfficiency;

  const _SeasonSummary({
    required this.fieldName,
    required this.fieldAreaDekar,
    required this.count,
    required this.totalGivenLiters,
    required this.totalEffectiveMm,
    required this.avgEfficiency,
  });

  static String _vol(double l) {
    if (l >= 1000) return '${(l / 1000).toStringAsFixed(1)} m³';
    return '${l.toStringAsFixed(0)} L';
  }

  @override
  Widget build(BuildContext context) {
    final lostLiters = totalGivenLiters * (1 - avgEfficiency);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.frost, AppColors.info],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$fieldName • ${fieldAreaDekar.toStringAsFixed(1)} da',
            style: const TextStyle(
                fontSize: 13,
                color: Colors.white70,
                fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          const Text(
            'Bu Sezon Sulama Özeti',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Colors.white),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _SummaryStat(
                  label: 'Sulama sayısı',
                  value: '$count',
                  sub: 'kayıt',
                ),
              ),
              Expanded(
                child: _SummaryStat(
                  label: 'Toplam verilen',
                  value: _vol(totalGivenLiters),
                  sub: '${totalEffectiveMm.toStringAsFixed(0)} mm etkili',
                ),
              ),
              Expanded(
                child: _SummaryStat(
                  label: 'Ortalama verim',
                  value: '%${(avgEfficiency * 100).toStringAsFixed(0)}',
                  sub: '${_vol(lostLiters)} kayıp',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryStat extends StatelessWidget {
  final String label;
  final String value;
  final String sub;
  const _SummaryStat(
      {required this.label, required this.value, required this.sub});
  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Colors.white70,
                  letterSpacing: 0.4)),
          const SizedBox(height: 4),
          Text(value,
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Colors.white)),
          Text(sub,
              style: const TextStyle(
                  fontSize: 10, color: Colors.white70, height: 1.2)),
        ],
      );
}

// ─── Yöntem dağılımı ────────────────────────────────────────────────────────

class _MethodDistribution extends StatelessWidget {
  final Map<String, int> methodCount;
  final Map<String, double> methodLiters;
  final double totalLiters;

  const _MethodDistribution({
    required this.methodCount,
    required this.methodLiters,
    required this.totalLiters,
  });

  @override
  Widget build(BuildContext context) {
    final entries = methodCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionLabel('Yöntem Dağılımı'),
          const SizedBox(height: 10),
          for (final e in entries)
            _MethodBar(
              method: e.key,
              count: e.value,
              liters: methodLiters[e.key] ?? 0,
              totalLiters: totalLiters,
            ),
        ],
      ),
    );
  }
}

class _MethodBar extends StatelessWidget {
  final String method;
  final int count;
  final double liters;
  final double totalLiters;

  const _MethodBar({
    required this.method,
    required this.count,
    required this.liters,
    required this.totalLiters,
  });

  @override
  Widget build(BuildContext context) {
    final ratio = totalLiters > 0 ? liters / totalLiters : 0.0;
    final eff = WaterAccounting.methodEfficiency(method);
    final color = _colorFor(eff);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.circle, size: 8, color: color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(method,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary)),
              ),
              Text('$count kez',
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textTertiary)),
              const SizedBox(width: 8),
              Text('%${(ratio * 100).toStringAsFixed(0)}',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: color)),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: ratio.clamp(0, 1).toDouble(),
              minHeight: 6,
              backgroundColor: AppColors.border,
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ],
      ),
    );
  }

  static Color _colorFor(double efficiency) {
    if (efficiency >= 0.9) return AppColors.emerald;
    if (efficiency >= 0.75) return AppColors.info;
    if (efficiency >= 0.6) return AppColors.warning;
    return AppColors.error;
  }
}

// ─── Zaman çizelgesi satırı ────────────────────────────────────────────────

class _TimelineRow extends StatelessWidget {
  final Map<String, dynamic> entry;
  final bool isFirst;
  final bool isLast;
  const _TimelineRow({
    required this.entry,
    required this.isFirst,
    required this.isLast,
  });

  static const _months = [
    'Oca', 'Şub', 'Mar', 'Nis', 'May', 'Haz',
    'Tem', 'Ağu', 'Eyl', 'Eki', 'Kas', 'Ara',
  ];

  static String _vol(double l) {
    if (l >= 1000) return '${(l / 1000).toStringAsFixed(1)} m³';
    return '${l.toStringAsFixed(0)} L';
  }

  @override
  Widget build(BuildContext context) {
    final date =
        entry['date'] is DateTime ? entry['date'] as DateTime : DateTime.now();
    final meta =
        (entry['metadata'] as Map?)?.cast<String, dynamic>() ?? const {};
    final method = (meta['irrigation_method'] as String?) ?? 'Sulama';
    final given = (meta['water_liters'] as num?)?.toDouble() ?? 0;
    final effMm = (meta['effective_water_mm'] as num?)?.toDouble() ?? 0;
    final eff = WaterAccounting.methodEfficiency(method);
    final note = (entry['note'] as String?)?.trim();
    final dotColor = eff >= 0.9
        ? AppColors.emerald
        : (eff >= 0.75
            ? AppColors.info
            : (eff >= 0.6 ? AppColors.warning : AppColors.error));

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Sol: tarih + çizgi + nokta
          SizedBox(
            width: 56,
            child: Column(
              children: [
                Text('${date.day}',
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary)),
                Text(_months[date.month - 1],
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textTertiary)),
                const SizedBox(height: 6),
                Expanded(
                  child: Stack(
                    alignment: Alignment.topCenter,
                    children: [
                      Positioned.fill(
                        child: Padding(
                          padding: EdgeInsets.only(
                              top: isFirst ? 6 : 0,
                              bottom: isLast ? 12 : 0),
                          child: Container(
                              width: 2, color: AppColors.border),
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.only(top: 2),
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: dotColor,
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: AppColors.bg, width: 2),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Sağ: içerik kartı
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(method,
                            style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary)),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: dotColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '%${(eff * 100).toStringAsFixed(0)} verim',
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: dotColor),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    given > 0
                        ? '${_vol(given)} verildi • ${effMm.toStringAsFixed(1)} mm etkili'
                        : 'Miktar girilmedi',
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textSecondary),
                  ),
                  if (note != null && note.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text('"$note"',
                        style: const TextStyle(
                            fontSize: 11,
                            fontStyle: FontStyle.italic,
                            color: AppColors.textTertiary)),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);
  @override
  Widget build(BuildContext context) => Text(text.toUpperCase(),
      style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: AppColors.textSecondary,
          letterSpacing: 0.5));
}
