import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/app_database.dart';
import '../services/app_providers.dart';
import '../services/task_directive_service.dart';
import '../theme/app_theme.dart';
import '../widgets/animated_route.dart';
import '../widgets/shimmer_loader.dart';
import '../widgets/tap_scale.dart';
import 'field_detail_screen.dart';

/// "Tarla Durumum" — her tarlada ne yetiştirildiğini, hangi işleme kaç gün
/// kaldığını ve o işlemin nasıl yapılacağını tek bir yerde gösteren reaktif
/// menü. `fieldDirectivesSummaryProvider` ile canlı bağlıdır: çiftçi sulama
/// kaydı girer girmez liste tazelenir.
class FieldStatusScreen extends ConsumerWidget {
  const FieldStatusScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fieldsAsync = ref.watch(fieldMapsProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text('Tarla Durumum', style: AppText.h2(context)),
        backgroundColor: AppColors.surface,
        elevation: 0,
        centerTitle: false,
      ),
      body: fieldsAsync.when(
        loading: () => ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
          itemCount: 3,
          itemBuilder: (_, __) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: ShimmerBox(
              width: double.infinity,
              height: 180,
              borderRadius: 16,
            ),
          ),
        ),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Tarla durumu yüklenemedi: $err',
              style: AppText.body(context),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        data: (fields) {
          if (fields.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppColors.emerald.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.agriculture,
                          size: 64, color: AppColors.emerald),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Henüz Tarla Kaydınız Yok',
                      textAlign: TextAlign.center,
                      style: AppText.h2(context),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Önce "Tarlalarım" ekranından bir alan ekleyin; bu menü '
                      'her tarlada ne yetiştirildiğini, hangi işleme kaç gün '
                      'kaldığını ve nasıl yapılacağını özetleyecek.',
                      textAlign: TextAlign.center,
                      style: AppText.body(context),
                    ),
                  ],
                ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              // Provider'lar autoDispose + stream/future — pull-to-refresh
              // Riverpod'da invalidate ile yeniden kurulur.
              ref.invalidate(fieldMapsProvider);
            },
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
              itemCount: fields.length,
              itemBuilder: (context, i) {
                final field = fields[i];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: _FieldStatusCard(fieldData: field),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────
// Tek tarla kartı — kendi direktif + büyüme stream'lerini izler
// ────────────────────────────────────────────────────────────────────

class _FieldStatusCard extends ConsumerWidget {
  final Map<String, dynamic> fieldData;
  const _FieldStatusCard({required this.fieldData});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fieldId = fieldData['id']?.toString() ?? '';
    final fieldName = (fieldData['name'] ?? 'İsimsiz Tarla').toString();
    final areaDekar = fieldData['area_dekar'];
    final crops = (fieldData['planted_crops'] as List?)
            ?.whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList() ??
        const [];

    final directivesAsync = ref.watch(fieldDirectivesSummaryProvider(fieldId));
    final growthStatesAsync = ref.watch(fieldGrowthStatesProvider(fieldId));

    return TapScale(
      scale: 0.98,
      onTap: () {
        Navigator.of(context).push(
          AnimatedRoute.scaleFade(FieldDetailScreen(fieldData: fieldData)),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.md,
          boxShadow: AppShadows.sm,
          border: Border.all(color: AppColors.border),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Başlık satırı ──
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.emeraldLight.withValues(alpha: 0.2),
                    borderRadius: AppRadius.sm,
                  ),
                  child: const Icon(Icons.landscape,
                      color: AppColors.emerald, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(fieldName, style: AppText.h3(context)),
                      const SizedBox(height: 2),
                      Text(
                        areaDekar == null
                            ? '${crops.length} bitki kaydı'
                            : '${(areaDekar as num).toStringAsFixed(1)} da • ${crops.length} bitki',
                        style: AppText.xs(context),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: AppColors.textTertiary),
              ],
            ),

            // ── Ekili bitkiler (kaç gün kaldı) ──
            if (crops.isEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.08),
                  borderRadius: AppRadius.sm,
                  border: Border.all(
                      color: AppColors.warning.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline,
                        size: 16, color: AppColors.warning),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Bu tarlaya henüz bitki eklenmemiş.',
                        style: AppText.xs(context),
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              const SizedBox(height: 14),
              ...crops.map((c) => _CropProgressRow(
                    crop: c,
                    growthStates: growthStatesAsync.valueOrNull ?? const [],
                  )),
            ],

            // ── Direktifler (sonraki işlem + nasıl yapılır) ──
            const SizedBox(height: 14),
            const Divider(height: 1),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.task_alt, size: 16, color: Colors.teal.shade700),
                const SizedBox(width: 6),
                Text(
                  'Sonraki İşlemler',
                  style: AppText.label(context)
                      .copyWith(color: Colors.teal.shade800),
                ),
              ],
            ),
            const SizedBox(height: 8),
            directivesAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Row(children: [
                  SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 8),
                  Text('Yönergeler hesaplanıyor…',
                      style: TextStyle(fontSize: 12)),
                ]),
              ),
              error: (err, _) => Text(
                'Yönergeler yüklenemedi: $err',
                style: AppText.xs(context),
              ),
              data: (directives) {
                if (directives.isEmpty) {
                  return Text(
                    'Bu tarla için önerilen bir işlem yok.',
                    style: AppText.xs(context),
                  );
                }
                // En fazla 4 öneri — en acilden sıralı
                final top = directives.take(4).toList();
                return Column(
                  children: top.map(_buildDirective).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDirective(FieldDirective d) {
    Color urgencyColor;
    IconData urgencyIcon;
    String urgencyLabel;
    switch (d.urgency) {
      case 2:
        urgencyColor = AppColors.error;
        urgencyIcon = Icons.priority_high;
        urgencyLabel = 'BUGÜN';
        break;
      case 1:
        urgencyColor = AppColors.warning;
        urgencyIcon = Icons.schedule;
        urgencyLabel = 'BU HAFTA';
        break;
      default:
        urgencyColor = Colors.blueGrey;
        urgencyIcon = Icons.info_outline;
        urgencyLabel = 'BİLGİ';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: urgencyColor.withValues(alpha: 0.06),
        borderRadius: AppRadius.sm,
        border: Border.all(color: urgencyColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(urgencyIcon, size: 14, color: urgencyColor),
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: urgencyColor,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  urgencyLabel,
                  style: const TextStyle(
                      fontSize: 9,
                      color: Colors.white,
                      fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  d.headline,
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            d.reason,
            style: const TextStyle(fontSize: 11, height: 1.35),
          ),
          if (d.steps.isNotEmpty) ...[
            const SizedBox(height: 6),
            ...d.steps.take(3).map(
                  (s) => Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('•  ',
                            style: TextStyle(
                                fontSize: 11, fontWeight: FontWeight.bold)),
                        Expanded(
                          child: Text(s,
                              style:
                                  const TextStyle(fontSize: 11, height: 1.3)),
                        ),
                      ],
                    ),
                  ),
                ),
          ],
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────
// Bir bitki için ilerleme çubuğu + kalan gün bilgisi
// ────────────────────────────────────────────────────────────────────

class _CropProgressRow extends StatelessWidget {
  final Map<String, dynamic> crop;
  final List<CropGrowthState> growthStates;

  const _CropProgressRow({required this.crop, required this.growthStates});

  @override
  Widget build(BuildContext context) {
    final cropId = crop['id']?.toString() ?? '';
    final name = (crop['name'] ?? 'Bitki').toString();
    final harvestDays = (crop['harvest_days'] as num?)?.toInt() ?? 90;
    final waterIntervalDays =
        (crop['water_interval_days'] as num?)?.toInt() ?? 7;
    final plantedDate = _parseDate(crop['planted_date']?.toString());

    CropGrowthState? growth;
    for (final g in growthStates) {
      if (g.cropId == cropId) {
        growth = g;
        break;
      }
    }

    final now = DateTime.now();
    final daysSincePlanting =
        plantedDate == null ? null : now.difference(plantedDate).inDays;
    final daysToHarvest =
        daysSincePlanting == null ? null : (harvestDays - daysSincePlanting);
    final progress = daysSincePlanting == null
        ? 0.0
        : (daysSincePlanting / harvestDays).clamp(0.0, 1.0).toDouble();

    String harvestLabel;
    Color harvestColor;
    if (daysToHarvest == null) {
      harvestLabel = 'Ekim tarihi girilmemiş';
      harvestColor = AppColors.textTertiary;
    } else if (daysToHarvest < 0) {
      harvestLabel = 'Hasat gecikti (${-daysToHarvest} gün)';
      harvestColor = AppColors.error;
    } else if (daysToHarvest == 0) {
      harvestLabel = 'Bugün hasat zamanı';
      harvestColor = AppColors.emerald;
    } else {
      harvestLabel = 'Hasada $daysToHarvest gün';
      harvestColor = daysToHarvest <= 7 ? AppColors.warning : AppColors.emerald;
    }

    final stageLabel = _stageLabel(growth?.currentStageKey);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(_emojiFor(name), style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  name,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w700),
                ),
              ),
              if (stageLabel != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.teal.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    stageLabel,
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Colors.teal.shade800),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: Colors.grey.shade200,
              color: harvestColor,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.event, size: 12, color: harvestColor),
              const SizedBox(width: 4),
              Text(
                harvestLabel,
                style: TextStyle(
                    fontSize: 11,
                    color: harvestColor,
                    fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              Icon(Icons.water_drop, size: 12, color: Colors.blue.shade600),
              const SizedBox(width: 4),
              Text(
                'Sulama her $waterIntervalDays gün',
                style: const TextStyle(fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String? _stageLabel(String? key) {
    switch (key) {
      case 'cimlenme':
        return 'Çimlenme';
      case 'vejetatif':
        return 'Vejetatif';
      case 'ciceklenme':
        return 'Çiçeklenme';
      case 'meyve_dolumu':
        return 'Meyve dolumu';
      case 'olgunlasma':
        return 'Olgunlaşma';
      case 'hasat':
        return 'Hasat';
      default:
        return null;
    }
  }

  static String _emojiFor(String name) {
    final n = name.toLowerCase();
    if (n.contains('domates')) return '🍅';
    if (n.contains('mısır') || n.contains('misir')) return '🌽';
    if (n.contains('ayçiçeği') ||
        n.contains('aycicegi') ||
        n.contains('ayçiçek') ||
        n.contains('aycicek')) {
      return '🌻';
    }
    return '🌱';
  }

  static DateTime? _parseDate(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    final parts = raw.split('.');
    if (parts.length == 3) {
      final d = int.tryParse(parts[0]);
      final m = int.tryParse(parts[1]);
      final y = int.tryParse(parts[2]);
      if (d != null && m != null && y != null) return DateTime(y, m, d);
    }
    return DateTime.tryParse(raw);
  }
}
