import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../data/activity_types.dart';
import '../data/app_database.dart';
import '../services/app_providers.dart';
import '../services/task_directive_service.dart';
import '../theme/app_theme.dart';
import '../widgets/animated_route.dart';
import '../widgets/shimmer_loader.dart';
import '../widgets/tap_scale.dart';
import 'daily_guide_screen.dart';
import 'farm_journal_screen.dart';
import 'field_detail_screen.dart';

/// "Tarla Durumum" — her tarlada ne yetiştirildiğini, hangi işleme kaç gün
/// kaldığını ve o işlemin nasıl yapılacağını tek bir yerde gösteren reaktif
/// menü. `fieldDirectivesSummaryProvider` ile canlı bağlıdır: çiftçi sulama
/// kaydı girer girmez liste tazelenir.
class FieldStatusScreen extends ConsumerWidget {
  /// Belirli bir tarlanın durumunu göstermek için [fieldId] verilebilir.
  /// Verilmezse tüm tarlalar listelenir.
  final String? fieldId;
  const FieldStatusScreen({super.key, this.fieldId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fieldsAsync = ref.watch(fieldMapsProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text('Tarla Durumu', style: AppText.h2(context)),
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
        data: (allFields) {
          final fields = fieldId == null
              ? allFields
              : allFields.where((f) => f['id']?.toString() == fieldId).toList();
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
                      'Önce "Tarlalarım" ekranından bir tarla ekleyin; bu menü '
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
    final activityLogAsync = ref.watch(fieldActivityLogProvider(fieldId));

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

            // ── Bugünün Rehberi linki ─────────────────────────────────
            // Direktif listesi artık burada gösterilmiyor; tek "Bugünün
            // Rehberi" ekranında alerts + today + thisWeek + insights
            // tutarlı şekilde toplanır (çakışma yok).
            const SizedBox(height: 14),
            const Divider(height: 1),
            const SizedBox(height: 10),
            _GuideLinkCard(
              fieldId: fieldId,
              fieldName: fieldName,
              alertCount: directivesAsync.maybeWhen(
                data: (d) => d.where((x) => x.urgency >= 2).length,
                orElse: () => 0,
              ),
            ),

            // ── Son Aktiviteler — kullanıcının kendi kayıtları (DB) ──
            // auto_seed planları (sistem önerisi) hariç; sadece çiftçinin
            // "Suladım/Gübreledim/İlaçladım" diye işaretlediği gerçek kayıtlar.
            const SizedBox(height: 14),
            const Divider(height: 1),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.history_rounded,
                    size: 16, color: Colors.indigo.shade700),
                const SizedBox(width: 6),
                Text(
                  'Son Aktiviteler',
                  style: AppText.label(context)
                      .copyWith(color: Colors.indigo.shade800),
                ),
                const Spacer(),
                TapScale(
                  onTap: () {
                    Navigator.of(context).push(
                      AnimatedRoute.slideX(
                        FarmJournalScreen(fieldId: fieldId),
                      ),
                    );
                  },
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    child: Text(
                      'Tümü →',
                      style: AppText.xs(context).copyWith(
                        color: Colors.indigo.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            activityLogAsync.when(
              loading: () => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Text('Geçmiş yükleniyor…', style: AppText.xs(context)),
              ),
              error: (err, _) => Text(
                'Geçmiş yüklenemedi.',
                style: AppText.xs(context),
              ),
              data: (entries) {
                final userEntries = entries
                    .where((e) => e['source']?.toString() != 'auto_seed')
                    .take(3)
                    .toList();
                if (userEntries.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Text(
                      'Henüz aktivite kaydı yok. Suladığında veya gübrelediğinde '
                      '"Aktivite" butonundan kaydet, geçmiş burada birikir.',
                      style: AppText.xs(context),
                    ),
                  );
                }
                return Column(
                  children: userEntries.map(_buildActivityRow).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityRow(Map<String, dynamic> entry) {
    final type = entry['type']?.toString() ?? ActivityType.other;
    final date = entry['date'];
    final qty = (entry['quantity'] as num?)?.toDouble();
    final unit = entry['unit']?.toString();
    final cropName = entry['crop_name']?.toString();
    final color = ActivityType.color(type);
    final icon = ActivityType.icon(type);
    final label = ActivityType.label(type);

    String timeAgo = '';
    if (date is DateTime) {
      final diff = DateTime.now().difference(date);
      if (diff.isNegative) {
        // Gelecek tarihli plan kaydı (auto_seed vb.) — gösterme
        timeAgo = 'Planlandı';
      } else if (diff.inDays >= 1) {
        timeAgo = '${diff.inDays} gün önce';
      } else if (diff.inHours >= 1) {
        timeAgo = '${diff.inHours} saat önce';
      } else if (diff.inMinutes >= 1) {
        timeAgo = '${diff.inMinutes} dk önce';
      } else {
        timeAgo = 'Az önce';
      }
    }

    // "Domates · Sulama · 5 L"  veya  "Domates · Sulama"  veya  "Sulama · 5 L"
    final parts = <String>[
      if (cropName != null && cropName.isNotEmpty) cropName,
      if (qty != null && unit != null)
        '$label · ${qty.toStringAsFixed(qty == qty.roundToDouble() ? 0 : 1)} $unit'
      else
        label,
    ];
    final qtyStr = parts.join(' · ');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, size: 14, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  qtyStr,
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w600),
                ),
                if (date is DateTime)
                  Text(
                    '$timeAgo · ${DateFormat('d MMM', 'tr_TR').format(date)}',
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textTertiary),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ignore: unused_element
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

/// Tarla kartında gösterilen "Bugünün Rehberi" linki — direktif/alert sayısı
/// rozet olarak görünür. Tıklanırsa tek `DailyGuideScreen` push olur.
class _GuideLinkCard extends StatelessWidget {
  final String fieldId;
  final String fieldName;
  final int alertCount;

  const _GuideLinkCard({
    required this.fieldId,
    required this.fieldName,
    required this.alertCount,
  });

  @override
  Widget build(BuildContext context) {
    return TapScale(
      onTap: () {
        if (fieldId.isEmpty) return;
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => DailyGuideScreen(
            fieldId: fieldId,
            fieldName: fieldName,
          ),
        ));
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          gradient: AppGradients.emeraldCard,
          borderRadius: AppRadius.sm,
        ),
        child: Row(
          children: [
            const Icon(Icons.lightbulb_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bugünün Rehberi',
                    style: AppText.bodyMd(context).copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    alertCount > 0
                        ? '$alertCount acil iş seni bekliyor'
                        : 'Bugünün önerileri ve uyarıları',
                    style: AppText.xs(context).copyWith(
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                  ),
                ],
              ),
            ),
            if (alertCount > 0)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$alertCount',
                  style: AppText.xs(context).copyWith(
                    color: AppColors.emeraldDark,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            const SizedBox(width: 6),
            const Icon(Icons.arrow_forward_ios_rounded,
                color: Colors.white, size: 14),
          ],
        ),
      ),
    );
  }
}
