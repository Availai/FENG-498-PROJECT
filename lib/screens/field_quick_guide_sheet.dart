import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/activity_types.dart';
import '../data/app_database.dart';
import '../services/app_providers.dart';
import '../services/guide_engine.dart' show AlertSeverity;
import '../services/rules/recommendation.dart';
import '../theme/app_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Giriş noktası — showModalBottomSheet ile açılır, navigator yok.
// ─────────────────────────────────────────────────────────────────────────────

class FieldQuickGuideSheet {
  static void show(
    BuildContext context, {
    required String fieldId,
    required String fieldName,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      enableDrag: true,
      builder: (_) => _QuickGuideBody(fieldId: fieldId, fieldName: fieldName),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Ana gövde — DraggableScrollableSheet içinde
// ─────────────────────────────────────────────────────────────────────────────

class _QuickGuideBody extends ConsumerStatefulWidget {
  final String fieldId;
  final String fieldName;

  const _QuickGuideBody({required this.fieldId, required this.fieldName});

  @override
  ConsumerState<_QuickGuideBody> createState() => _QuickGuideBodyState();
}

class _QuickGuideBodyState extends ConsumerState<_QuickGuideBody> {
  // Tavsiyeler yüklenene kadar skeleton göster. Timeout = 3 sn.
  List<Recommendation>? _recs;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _loadRecs();
  }

  Future<void> _loadRecs() async {
    _timer = Timer(const Duration(seconds: 3), () {
      if (mounted && _recs == null) setState(() => _recs = []);
    });
    try {
      final recs =
          await ref.read(fieldLiveTodosProvider(widget.fieldId).future);
      if (mounted) {
        _timer?.cancel();
        setState(() => _recs = recs);
      }
    } catch (_) {
      if (mounted) setState(() => _recs = []);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cropsAsync = ref.watch(fieldCropsStreamProvider(widget.fieldId));
    final activitiesAsync =
        ref.watch(fieldActivityLogProvider(widget.fieldId));
    final growthAsync =
        ref.watch(fieldGrowthStatesProvider(widget.fieldId));
    final plantsAsync =
        ref.watch(fieldPlantInstancesProvider(widget.fieldId));

    final crops =
        cropsAsync.valueOrNull ?? const <Map<String, dynamic>>[];
    final activities =
        activitiesAsync.valueOrNull ?? const <Map<String, dynamic>>[];
    final growthList = growthAsync.valueOrNull ?? const <CropGrowthState>[];
    final plants = plantsAsync.valueOrNull ?? const <FieldPlantInstance>[];

    final diseasedCount = plants.where((p) => p.healthStatus == 'diseased').length;
    final deadCount = plants.where((p) => p.healthStatus == 'dead').length;

    // Son 8 saat içindeki aktiviteler
    final cutoff = DateTime.now().subtract(const Duration(hours: 8));
    final recentActs = activities.where((a) {
      final d = a['date'];
      return d is DateTime && d.isAfter(cutoff);
    }).toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.55,
      minChildSize: 0.35,
      maxChildSize: 0.9,
      builder: (_, ctrl) {
        return Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            children: [
              // Tutma çubuğu
              Container(
                margin: const EdgeInsets.only(top: 10, bottom: 4),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Başlık
              _Header(
                fieldName: widget.fieldName,
                crops: crops,
                growthList: growthList,
              ),
              const Divider(height: 1, thickness: 1),
              // Durum şeridi
              _StatusStrip(
                growthList: growthList,
                diseasedCount: diseasedCount,
                deadCount: deadCount,
              ),
              const Divider(height: 1, thickness: 1),
              // Kaydırılabilir içerik
              Expanded(
                child: ListView(
                  controller: ctrl,
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  children: [
                    // Son aktiviteler
                    if (recentActs.isNotEmpty)
                      _RecentActivityBanner(activities: recentActs),
                    // Hasta / ölü bitki uyarısı
                    if (diseasedCount > 0 || deadCount > 0)
                      _PlantHealthAlert(
                          diseasedCount: diseasedCount,
                          deadCount: deadCount),
                    // Direktifler
                    _DirectiveList(
                      recs: _recs,
                      crops: crops,
                      growthList: growthList,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Başlık: tarla adı + bitki + gün
// ─────────────────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final String fieldName;
  final List<Map<String, dynamic>> crops;
  final List<CropGrowthState> growthList;

  const _Header({
    required this.fieldName,
    required this.crops,
    required this.growthList,
  });

  @override
  Widget build(BuildContext context) {
    final first = crops.isNotEmpty ? crops.first : null;
    final cropName = first?['name']?.toString() ?? '';
    final stage = _stageLabel(first, growthList);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: Row(
        children: [
          Text(_emoji(cropName), style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fieldName,
                  style: AppText.bodyMd(context)
                      .copyWith(fontWeight: FontWeight.w800),
                ),
                if (cropName.isNotEmpty)
                  Text(
                    stage.isNotEmpty ? '$cropName · $stage' : cropName,
                    style: AppText.sm(context)
                        .copyWith(color: AppColors.textSecondary),
                  ),
              ],
            ),
          ),
          if (crops.length > 1)
            _Pill(
              label: '${crops.length} bitki',
              color: AppColors.emeraldDark,
            ),
        ],
      ),
    );
  }

  String _stageLabel(
    Map<String, dynamic>? crop,
    List<CropGrowthState> growthList,
  ) {
    final cropId = crop?['id']?.toString();
    if (cropId == null) return '';
    try {
      final g = growthList.firstWhere((s) => s.cropId == cropId);
      final key = g.currentStageKey;
      final day = crop?['planted_date'] != null
          ? DateTime.now()
              .difference(_parseDate(crop!['planted_date'].toString()))
              .inDays
          : null;
      final stageLabel = _translateStage(key);
      return day != null && day >= 0
          ? '$stageLabel · $day. gün'
          : stageLabel;
    } catch (_) {}
    return '';
  }

  static DateTime _parseDate(String raw) {
    final parts = raw.split('.');
    if (parts.length == 3) {
      final iso =
          '${parts[2]}-${parts[1].padLeft(2, '0')}-${parts[0].padLeft(2, '0')}';
      return DateTime.tryParse(iso) ?? DateTime.now();
    }
    return DateTime.tryParse(raw) ?? DateTime.now();
  }

  static String _translateStage(String key) {
    const map = {
      'cimleme': 'Çimlenme',
      'fide': 'Fide',
      'vejetatif': 'Büyüme',
      'ciceklenme': 'Çiçeklenme',
      'meyve_dolumu': 'Meyve dolumu',
      'olgunlasma': 'Olgunlaşma',
      'hasat': 'Hasat',
    };
    return map[key] ?? key;
  }

  static String _emoji(String name) {
    final n = name.toLowerCase();
    if (n.contains('domates')) return '🍅';
    if (n.contains('mısır') || n.contains('misir')) return '🌽';
    if (n.contains('ayçiçek') || n.contains('aycicek')) return '🌻';
    if (n.contains('buğday') || n.contains('bugday')) return '🌾';
    if (n.contains('portakal')) return '🍊';
    if (n.contains('çay') || n.contains('cay')) return '🍵';
    return '🌱';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Durum şeridi — 3 dot: su / hastalık / besin
// ─────────────────────────────────────────────────────────────────────────────

class _StatusStrip extends StatelessWidget {
  final List<CropGrowthState> growthList;
  final int diseasedCount;
  final int deadCount;

  const _StatusStrip({
    required this.growthList,
    required this.diseasedCount,
    required this.deadCount,
  });

  @override
  Widget build(BuildContext context) {
    double avgWater = 0, avgDisease = 0, avgN = 0;
    if (growthList.isNotEmpty) {
      for (final g in growthList) {
        avgWater += g.waterDeficitMm;
        avgDisease += g.diseasePressure;
        avgN += g.nStressIdx;
      }
      avgWater /= growthList.length;
      avgDisease /= growthList.length;
      avgN /= growthList.length;
    }
    final hasDiseasedPlants = diseasedCount > 0 || deadCount > 0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      child: Row(
        children: [
          _StatusDot(
            icon: Icons.water_drop_rounded,
            label: 'Su',
            value: _waterLabel(avgWater),
            color: _waterColor(avgWater),
          ),
          const SizedBox(width: 8),
          _StatusDot(
            icon: Icons.coronavirus_outlined,
            label: 'Hastalık',
            value: hasDiseasedPlants
                ? '${diseasedCount + deadCount} bitki'
                : _diseaseLabel(avgDisease),
            color: hasDiseasedPlants || avgDisease > 0.4
                ? AppColors.error
                : avgDisease > 0.2
                    ? AppColors.warning
                    : AppColors.emerald,
          ),
          const SizedBox(width: 8),
          _StatusDot(
            icon: Icons.grass_rounded,
            label: 'Besin',
            value: _nLabel(avgN),
            color: _nColor(avgN),
          ),
        ],
      ),
    );
  }

  static String _waterLabel(double mm) {
    if (mm <= 5) return 'İyi';
    if (mm <= 15) return 'Dikkat';
    return 'Eksik';
  }

  static Color _waterColor(double mm) {
    if (mm <= 5) return AppColors.emerald;
    if (mm <= 15) return AppColors.warning;
    return AppColors.error;
  }

  static String _diseaseLabel(double d) {
    if (d <= 0.2) return 'Sağlıklı';
    if (d <= 0.4) return 'Takip et';
    return 'Risk var';
  }

  static String _nLabel(double n) {
    if (n <= 0.2) return 'Yeterli';
    if (n <= 0.5) return 'Az';
    return 'Eksik';
  }

  static Color _nColor(double n) {
    if (n <= 0.2) return AppColors.emerald;
    if (n <= 0.5) return AppColors.warning;
    return AppColors.error;
  }
}

class _StatusDot extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatusDot({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: AppRadius.sm,
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 3),
            Text(
              value,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Son aktivite bandı — "✅ Sulandı · 2s önce"
// ─────────────────────────────────────────────────────────────────────────────

class _RecentActivityBanner extends StatelessWidget {
  final List<Map<String, dynamic>> activities;

  const _RecentActivityBanner({required this.activities});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.emerald.withValues(alpha: 0.08),
        borderRadius: AppRadius.sm,
        border: Border.all(color: AppColors.emerald.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final a in activities.take(3))
            _ActivityLine(activity: a),
        ],
      ),
    );
  }
}

class _ActivityLine extends StatelessWidget {
  final Map<String, dynamic> activity;

  const _ActivityLine({required this.activity});

  @override
  Widget build(BuildContext context) {
    final type = activity['type']?.toString() ?? '';
    final date = activity['date'] as DateTime?;
    final ago = date != null ? _ago(date) : '';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(ActivityType.icon(type), color: AppColors.emerald, size: 16),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              '${ActivityType.label(type)} yapıldı',
              style: AppText.sm(context).copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.emeraldDark,
              ),
            ),
          ),
          Text(
            ago,
            style: AppText.xs(context).copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  static String _ago(DateTime d) {
    final diff = DateTime.now().difference(d);
    if (diff.inMinutes < 60) return '${diff.inMinutes}dk önce';
    if (diff.inHours < 24) return '${diff.inHours}s önce';
    return '${diff.inDays}g önce';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Hasta / ölü bitki uyarısı
// ─────────────────────────────────────────────────────────────────────────────

class _PlantHealthAlert extends StatelessWidget {
  final int diseasedCount;
  final int deadCount;

  const _PlantHealthAlert({
    required this.diseasedCount,
    required this.deadCount,
  });

  @override
  Widget build(BuildContext context) {
    final parts = <String>[];
    if (diseasedCount > 0) parts.add('$diseasedCount hasta');
    if (deadCount > 0) parts.add('$deadCount ölü');
    final msg = parts.join(', ');

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.08),
        borderRadius: AppRadius.sm,
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_rounded, color: AppColors.error, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '$msg bitki — ilaçlama zamanı',
              style: AppText.bodyMd(context).copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.error,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Direktif listesi — max 5 kart. Neden yok, sadece eylem.
// ─────────────────────────────────────────────────────────────────────────────

class _DirectiveList extends StatelessWidget {
  final List<Recommendation>? recs;
  final List<Map<String, dynamic>> crops;
  final List<CropGrowthState> growthList;

  const _DirectiveList({
    required this.recs,
    required this.crops,
    required this.growthList,
  });

  @override
  Widget build(BuildContext context) {
    // Henüz yüklenmedi
    if (recs == null) {
      return Column(
        children: List.generate(
          2,
          (_) => Container(
            margin: const EdgeInsets.only(bottom: 10),
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.border.withValues(alpha: 0.5),
              borderRadius: AppRadius.sm,
            ),
          ),
        ),
      );
    }

    if (recs!.isEmpty && crops.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          children: [
            const Icon(Icons.check_circle_rounded,
                color: AppColors.emerald, size: 40),
            const SizedBox(height: 10),
            Text(
              'Her şey yolunda',
              style: AppText.bodyMd(context)
                  .copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(
              'Bugün aksiyon gerektiren bir şey yok.',
              style: AppText.sm(context)
                  .copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    // Kritikler önce, max 5
    final sorted = [...recs!]..sort((a, b) => b.severity.index.compareTo(a.severity.index));
    final top = sorted.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final rec in top) _DirectiveCard(rec: rec),
        // Bugün ekili ama tavsiye çıkmadıysa su özeti
        if (top.isEmpty && crops.isNotEmpty)
          _WaterSummaryCard(crops: crops, growthList: growthList),
      ],
    );
  }
}

class _DirectiveCard extends StatelessWidget {
  final Recommendation rec;

  const _DirectiveCard({required this.rec});

  @override
  Widget build(BuildContext context) {
    final isUrgent = rec.severity == AlertSeverity.critical;
    final color = isUrgent ? AppColors.error : AppColors.warning;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: AppRadius.sm,
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _urgencyDot(isUrgent),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  rec.title,
                  style: AppText.bodyMd(context).copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (rec.actionHint.isNotEmpty)
                  Text(
                    rec.actionHint,
                    style: AppText.sm(context).copyWith(
                      color: color,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _urgencyDot(bool urgent) {
    return Container(
      width: 8,
      height: 8,
      margin: const EdgeInsets.only(top: 5),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: urgent ? AppColors.error : AppColors.warning,
      ),
    );
  }
}

class _WaterSummaryCard extends StatelessWidget {
  final List<Map<String, dynamic>> crops;
  final List<CropGrowthState> growthList;

  const _WaterSummaryCard({
    required this.crops,
    required this.growthList,
  });

  @override
  Widget build(BuildContext context) {
    double totalDeficit = 0;
    for (final g in growthList) {
      totalDeficit += g.waterDeficitMm;
    }

    if (totalDeficit < 5) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            const Icon(Icons.check_circle_rounded,
                color: AppColors.emerald, size: 20),
            const SizedBox(width: 8),
            Text(
              'Su dengesi iyi — bugün sulama gerekmez.',
              style: AppText.bodyMd(context),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.frost.withValues(alpha: 0.12),
        borderRadius: AppRadius.sm,
        border: Border.all(
            color: AppColors.frost.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.water_drop_rounded,
              color: AppColors.frost, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Sula — ${totalDeficit.toStringAsFixed(0)} mm eksik',
              style: AppText.bodyMd(context).copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.frost,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Yardımcılar
// ─────────────────────────────────────────────────────────────────────────────

class _Pill extends StatelessWidget {
  final String label;
  final Color color;

  const _Pill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: AppRadius.full,
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}
