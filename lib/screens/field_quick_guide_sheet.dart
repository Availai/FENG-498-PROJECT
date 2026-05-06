import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/rule_engine/rule.dart';
import '../data/activity_types.dart';
import '../data/app_database.dart';
import '../data/disease_advice.dart';
import '../data/turkish_crops_repository.dart';
import '../services/app_providers.dart';
import '../services/guide_engine.dart' show AlertSeverity;
import '../services/notification_service.dart';
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
    final growthAsync = ref.watch(fieldGrowthStatesProvider(widget.fieldId));
    final plantsAsync = ref.watch(fieldPlantInstancesProvider(widget.fieldId));

    final crops = cropsAsync.valueOrNull ?? const <Map<String, dynamic>>[];
    final growthList = growthAsync.valueOrNull ?? const <CropGrowthState>[];
    final plants = plantsAsync.valueOrNull ?? const <FieldPlantInstance>[];

    final diseasedCount =
        plants.where((p) => p.healthStatus == 'diseased').length;
    final deadCount = plants.where((p) => p.healthStatus == 'dead').length;

    return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => Navigator.of(context).pop(),
        child: DraggableScrollableSheet(
          initialChildSize: 0.55,
          minChildSize: 0.35,
          maxChildSize: 0.9,
          builder: (_, ctrl) {
            return GestureDetector(
                onTap: () {}, // İçeriğe tıklamayı yut ki dışarıya taşmasın
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(20)),
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
                            // Hasta / ölü / tedavi gören bitkileri ismine göre grupla
                            ...() {
                              final problematic = plants
                                  .where((p) =>
                                      p.healthStatus != 'healthy' &&
                                      p.healthStatus != 'removed')
                                  .toList();
                              if (problematic.isEmpty) return <Widget>[];

                              final grouped =
                                  <String, List<FieldPlantInstance>>{};
                              for (final p in problematic) {
                                grouped
                                    .putIfAbsent(p.cropName, () => [])
                                    .add(p);
                              }

                              final widgets = <Widget>[];
                              for (final entry in grouped.entries) {
                                final cropName = entry.key;
                                final cropPlants = entry.value;
                                final activePlants = cropPlants
                                    .where((p) => p.healthStatus != 'dead')
                                    .toList(growable: false);
                                final deadPlants = cropPlants
                                    .where((p) => p.healthStatus == 'dead')
                                    .toList(growable: false);
                                final dCount = cropPlants
                                    .where((p) => p.healthStatus == 'diseased')
                                    .length;
                                final tCount = cropPlants
                                    .where((p) => p.healthStatus == 'treating')
                                    .length;
                                final ddCount = cropPlants
                                    .where((p) => p.healthStatus == 'dead')
                                    .length;

                                if (dCount > 0 || tCount > 0) {
                                  widgets.add(_PlantHealthAlert(
                                    fieldId: widget.fieldId,
                                    fieldName: widget.fieldName,
                                    cropName: cropName,
                                    diseasedCount: dCount,
                                    treatingCount: tCount,
                                    deadCount: 0,
                                    plants: activePlants,
                                  ));
                                }
                                if (ddCount > 0) {
                                  for (final plant in deadPlants) {
                                    widgets.add(_DeadPlantRemovalAlert(
                                      fieldId: widget.fieldId,
                                      cropName: cropName,
                                      plants: [plant],
                                    ));
                                  }
                                }
                              }
                              return widgets;
                            }(),
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
                ));
          },
        ));
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
      return day != null && day >= 0 ? '$stageLabel · $day. gün' : stageLabel;
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
// Hasta / ölü bitki uyarısı + tedavi önerisi + ilaçlama akışı
// ─────────────────────────────────────────────────────────────────────────────

class _DeadPlantRemovalAlert extends ConsumerStatefulWidget {
  final String fieldId;
  final String cropName;
  final List<FieldPlantInstance> plants;

  const _DeadPlantRemovalAlert({
    required this.fieldId,
    required this.cropName,
    required this.plants,
  });

  @override
  ConsumerState<_DeadPlantRemovalAlert> createState() =>
      _DeadPlantRemovalAlertState();
}

class _DeadPlantRemovalAlertState
    extends ConsumerState<_DeadPlantRemovalAlert> {
  bool _logging = false;

  Future<void> _removeDeadPlants() async {
    if (_logging) return;
    setState(() => _logging = true);
    try {
      final repo = ref.read(localDataRepositoryProvider);
      final logger = ref.read(activityLoggerProvider);
      for (final plant in widget.plants) {
        await logger.log(
          fieldId: widget.fieldId,
          type: ActivityType.scouting,
          cropId: plant.cropId,
          plantInstanceId: plant.id,
          scope: ActivityScope.plant,
          subtype: ActivitySubtype.note,
          note:
              '${widget.cropName} cansız bitki söküldü ve tarladan uzaklaştırıldı',
          metadata: {
            'dead_plant_removal': true,
            'remove_plant_instance_after_log': true,
            'health_status': 'dead',
            'crop_name': widget.cropName,
            'spread_warning': true,
          },
        );
        await repo.setPlantHealth(
          instanceId: plant.id,
          healthStatus: 'removed',
          diseaseType: plant.diseaseType,
          diseasePhotoPath: plant.diseasePhotoPath,
          notes: 'Cansız bitki söküldü ve haritadan kaldırıldı',
          writeActivityLog: false,
        );
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sökme işlemi günlüğe kaydedildi.')),
      );
    } finally {
      if (mounted) setState(() => _logging = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final count = widget.plants.length;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0B0B0B),
        borderRadius: AppRadius.sm,
        border: Border.all(color: Colors.black),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.delete_forever_rounded,
                  color: Colors.white, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  count == 1
                      ? '${widget.cropName} cansız bitki: sökme işlemi'
                      : '${widget.cropName}: $count cansız bitki sökülecek',
                  style: AppText.bodyMd(context).copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Bitkiyi köküyle birlikte söküp tarladan uzaklaştırın. Belirti çevresine yayıldıysa yakın çevrede gözlem yapın; yayılım doğrulanırsa BKÜ etiketi ve uzman onayıyla çevresel ilaçlama gerekebilir.',
            style: AppText.sm(context).copyWith(
              color: Colors.white.withValues(alpha: 0.82),
              height: 1.35,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _logging ? null : _removeDeadPlants,
            icon: _logging
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check_rounded),
            label: Text(_logging
                ? 'Kaydediliyor...'
                : 'Söktüm, haritadan kaldır'),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: const RoundedRectangleBorder(
                borderRadius: AppRadius.sm,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlantHealthAlert extends ConsumerStatefulWidget {
  final String fieldId;
  final String fieldName;
  final String cropName;
  final int diseasedCount;
  final int treatingCount;
  final int deadCount;
  final List<FieldPlantInstance> plants;

  const _PlantHealthAlert({
    required this.fieldId,
    required this.fieldName,
    required this.cropName,
    required this.diseasedCount,
    required this.treatingCount,
    required this.deadCount,
    required this.plants,
  });

  @override
  ConsumerState<_PlantHealthAlert> createState() => _PlantHealthAlertState();
}

enum _TreatmentPhase { alert, guide, treating }

class _PlantHealthAlertState extends ConsumerState<_PlantHealthAlert> {
  _TreatmentPhase _phase = _TreatmentPhase.alert;
  bool _logging = false;

  CropV2Bundle? get _trustedV2 {
    final repo = TurkishCropsRepository.instance;
    if (!repo.isReady) return null;
    final crop = repo.findByName(widget.cropName);
    final stableId = crop?.stableId;
    if (stableId == null || stableId.isEmpty) return null;
    return repo.findV2ByStableId(stableId);
  }

  List<Rule> _matchingRules(CropV2Bundle v2, Map<String, dynamic>? disease) {
    final problemId = disease?['id']?.toString();
    if (problemId == null || problemId.isEmpty) return const [];
    return v2.rules
        .where((r) => r.enabled && r.result.possibleProblemId == problemId)
        .toList(growable: false);
  }

  Map<String, dynamic>? _trustedDiseaseRecord(CropV2Bundle v2) {
    final counts = <String, int>{};
    for (final p in widget.plants) {
      if (p.healthStatus != 'diseased') continue;
      final name = p.diseaseType?.trim();
      if (name == null || name.isEmpty) continue;
      counts[name] = (counts[name] ?? 0) + 1;
    }
    if (counts.isEmpty) return null;
    final top = counts.entries.reduce((a, b) => a.value >= b.value ? a : b);
    for (final disease in v2.diseases) {
      if (disease['name_tr']?.toString().trim() == top.key) return disease;
    }
    return null;
  }

  Widget _trustedDiseaseCard(
    BuildContext context,
    CropV2Bundle v2,
    Map<String, dynamic>? disease,
  ) {
    final title = disease?['name_tr']?.toString() ?? 'Kaynaklı hastalık gözlemi';
    final summary = disease?['summary']?.toString();
    final controls = ((disease?['control_methods_cultural'] as List?) ??
            const [])
        .map((e) => e?.toString() ?? '')
        .where((e) => e.isNotEmpty)
        .take(4)
        .toList(growable: false);
    final requiresBku = disease?['requires_bku_check'] == true;
    final requiresExpert = disease?['requires_expert_confirmation'] == true;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.08),
        borderRadius: AppRadius.sm,
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.verified_rounded,
                  color: AppColors.error, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '${widget.diseasedCount} ${widget.cropName} hasta — $title',
                  style: AppText.bodyMd(context).copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.error,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            summary ??
                'Bu kart yalnızca kaynaklı JSON kaydındaki hastalık adlarıyla çalışır; kaynakta olmayan hastalık adı uydurulmaz.',
            style: AppText.sm(context).copyWith(
              color: AppColors.textSecondary,
              height: 1.35,
              fontWeight: FontWeight.w600,
            ),
          ),
          ...() {
            final matched = _matchingRules(v2, disease);
            if (matched.isEmpty) return <Widget>[];
            final explanation = matched.first.explanation;
            if (explanation == null || explanation.isEmpty) return <Widget>[];
            return [
              const SizedBox(height: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.07),
                  borderRadius: AppRadius.xs,
                  border: Border.all(
                      color: AppColors.warning.withValues(alpha: 0.22)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      const Icon(Icons.biotech_rounded,
                          size: 12, color: AppColors.warning),
                      const SizedBox(width: 5),
                      Text('TAGEM koşul eşiği',
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppColors.warning)),
                    ]),
                    const SizedBox(height: 4),
                    Text(
                      explanation,
                      style: AppText.sm(context).copyWith(
                        color: AppColors.textSecondary,
                        fontStyle: FontStyle.italic,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ];
          }(),
          if (controls.isNotEmpty) ...[
            const SizedBox(height: 10),
            ...controls.map((text) => Padding(
                  padding: const EdgeInsets.only(bottom: 5),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(top: 7),
                        child: Icon(Icons.circle,
                            size: 5, color: AppColors.error),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          text,
                          style: AppText.sm(context).copyWith(
                            color: AppColors.textPrimary,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
          ],
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _Pill(label: 'Kaynaklı JSON', color: AppColors.emeraldDark),
              if (requiresBku) _Pill(label: 'BKÜ kontrolü', color: AppColors.error),
              if (requiresExpert)
                _Pill(label: 'Uzman onayı', color: Colors.indigo),
              if (v2.confidence != null)
                _Pill(label: 'Güven: ${v2.confidence}', color: Colors.blueGrey),
            ],
          ),
        ],
      ),
    );
  }

  /// Hastalık dağılımını hesapla — öncelikle 'diseased' ve 'dead' olanlara odaklan.
  /// Eğer onlardan hiç yoksa, 'treating' olanlara bak.
  DiseaseAdvice get _primaryAdvice {
    var relevant = widget.plants
        .where((p) => p.healthStatus == 'diseased' || p.healthStatus == 'dead')
        .toList();
    if (relevant.isEmpty) {
      relevant =
          widget.plants.where((p) => p.healthStatus == 'treating').toList();
    }

    final counts = <String, int>{};
    for (final p in relevant) {
      final d = p.diseaseType?.trim();
      if (d != null && d.isNotEmpty) {
        counts[d] = (counts[d] ?? 0) + 1;
      }
    }
    if (counts.isEmpty) return DiseaseAdvice.forName(null);
    final top = counts.entries.reduce((a, b) => a.value >= b.value ? a : b);
    return DiseaseAdvice.forName(top.key);
  }

  /// İlk kimyasal tedavi önerisinden kısa doz bilgisi çıkar.
  String _shortDoseGuide(DiseaseAdvice advice) {
    for (final t in advice.chemicalTreatments) {
      final stripped = t.trim();
      if (stripped.isEmpty || stripped.toLowerCase().startsWith('not')) {
        continue;
      }
      // "Mancozeb (%80 WP) — 250 g / 100 L su, koruyucu olarak 10 gün arayla"
      // → tamamını döndür, kısa olsun diye ilk 120 karakter
      return stripped.length > 120
          ? '${stripped.substring(0, 117)}…'
          : stripped;
    }
    return 'Etiketteki doz talimatına uygun uygulama yapın.';
  }

  /// Tedavi tavsiyesinden gün sayısını çıkar (ör. "10 gün arayla" → 10).
  int _parseTreatmentDays(DiseaseAdvice advice) {
    for (final t in advice.chemicalTreatments) {
      final match = RegExp(r'(\d+)\s*gün').firstMatch(t);
      if (match != null) {
        final days = int.tryParse(match.group(1)!);
        if (days != null && days > 0 && days <= 30) return days;
      }
    }
    return 7; // Varsayılan tedavi süresi
  }

  Future<void> _logSpraying() async {
    if (_logging) return;
    setState(() => _logging = true);
    try {
      final advice = _primaryAdvice;
      final logger = ref.read(activityLoggerProvider);
      // Tarlaya ilaçlama aktivitesi log'la (Tarlam Günlüğünde zengin görünüm için)
      await logger.log(
        fieldId: widget.fieldId,
        type: ActivityType.spraying,
        note:
            '${widget.cropName} bitkilerinde tespit edilen ${advice.name} için tedavi ve ilaçlama başlatıldı',
        metadata: {
          'pesticide_name': advice.chemicalTreatments.isNotEmpty
              ? advice.chemicalTreatments.first.split('—').first.trim()
              : 'Sistem Tavsiyesi İlaç',
          'active_ingredient': advice.chemicalTreatments.isNotEmpty
              ? advice.chemicalTreatments.first
              : 'Belirtilmedi',
          'target_pest': advice.name,
          'crop_name': widget.cropName,
          'treatment_days': _parseTreatmentDays(advice),
        },
      );

      // Hasta bitkileri "tedavi ediliyor" durumuna çevir (kırmızı → turuncu)
      final repo = ref.read(localDataRepositoryProvider);
      final diseased = widget.plants.where((p) => p.healthStatus == 'diseased');
      for (final p in diseased) {
        await repo.setPlantHealth(
          instanceId: p.id,
          healthStatus: 'treating',
          diseaseType: p.diseaseType,
          notes: 'İlaçlama uygulandı, tedavi devam ediyor',
        );
      }

      // Tedavi hatırlatıcı bildirimlerini planla
      final treatmentDays = _parseTreatmentDays(advice);
      final doseGuide = _shortDoseGuide(advice);
      await NotificationService.scheduleTreatmentReminders(
        fieldId: widget.fieldId,
        fieldName: widget.fieldName,
        diseaseName: advice.name,
        treatmentDays: treatmentDays,
        doseGuide: doseGuide.length > 60
            ? '${doseGuide.substring(0, 57)}…'
            : doseGuide,
      );

      if (mounted) setState(() => _phase = _TreatmentPhase.treating);
    } catch (_) {
      // Hata olsa bile UI kırılmasın
    } finally {
      if (mounted) setState(() => _logging = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cropName = widget.cropName;
    final advice = _primaryAdvice;

    // ── Faz 3: Tedavi başladı ──
    if (_phase == _TreatmentPhase.treating) {
      final days = _parseTreatmentDays(advice);
      return Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.warning.withValues(alpha: 0.1),
          borderRadius: AppRadius.sm,
          border: Border.all(color: AppColors.warning.withValues(alpha: 0.35)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.medication_rounded,
                    color: AppColors.warning, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '$cropName Tedavisi Başladı — $days günlük plan (${advice.name})',
                    style: AppText.bodyMd(context).copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.warning,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.7),
                borderRadius: AppRadius.xs,
              ),
              child: Row(
                children: [
                  const Icon(Icons.notifications_active_rounded,
                      color: AppColors.warning, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Her gün sabah 08:00 ve akşam 18:00\'de hatırlatıcı bildirim gelecek.',
                      style: AppText.sm(context).copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Eğer sadece tedavi ediliyor durumunda bitkiler varsa (reopen sonrası)
    if (widget.diseasedCount == 0 &&
        widget.deadCount == 0 &&
        widget.treatingCount > 0) {
      return Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.warning.withValues(alpha: 0.1),
          borderRadius: AppRadius.sm,
          border: Border.all(color: AppColors.warning.withValues(alpha: 0.35)),
        ),
        child: Row(
          children: [
            const Icon(Icons.medication_rounded,
                color: AppColors.warning, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '${widget.treatingCount} $cropName tedavi ediliyor (${advice.name})',
                style: AppText.bodyMd(context).copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.warning,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final trustedV2 = _trustedV2;
    if (trustedV2 != null && widget.diseasedCount > 0) {
      return _trustedDiseaseCard(
        context,
        trustedV2,
        _trustedDiseaseRecord(trustedV2),
      );
    }

    final parts = <String>[];
    if (widget.diseasedCount > 0) parts.add('${widget.diseasedCount} hasta');
    if (widget.deadCount > 0) parts.add('${widget.deadCount} ölü');
    final msg = parts.join(', ');

    // İlk 2 aktif maddeyi çıkar
    final topChemicals = <String>[];
    for (final t in advice.chemicalTreatments) {
      final s = t.trim();
      if (s.isEmpty || s.toLowerCase().startsWith('not')) continue;
      final head = s.split('—').first.trim();
      if (head.isNotEmpty) topChemicals.add(head);
      if (topChemicals.length >= 2) break;
    }

    // ── Faz 2: Kullanım rehberi (ilaçladım'a bastıktan sonra doz göster) ──
    if (_phase == _TreatmentPhase.guide) {
      final doseText = _shortDoseGuide(advice);
      return Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.warning.withValues(alpha: 0.08),
          borderRadius: AppRadius.sm,
          border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.medication_rounded,
                    color: AppColors.warning, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '$cropName Uygulama Rehberi — ${advice.name}',
                    style: AppText.bodyMd(context).copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.warning,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.7),
                borderRadius: AppRadius.xs,
              ),
              child: Text(
                doseText,
                style: AppText.body(context).copyWith(
                  fontSize: 13,
                  height: 1.4,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (advice.chemicalTreatments.length > 1) ...[
              const SizedBox(height: 6),
              Text(
                '⚠️ Aynı aktif maddeyi üst üste kullanmayın — direnç gelişir.',
                style: AppText.xs(context).copyWith(
                  color: AppColors.textSecondary,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _logging ? null : _logSpraying,
                icon: _logging
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.check_rounded, size: 18),
                label: Text(_logging ? 'Kaydediliyor…' : 'Uyguladım, kaydet'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.emerald,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: const RoundedRectangleBorder(
                    borderRadius: AppRadius.sm,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // ── Faz 1: Uyarı + tedavi önerisi + İlaçla butonu ──
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.08),
        borderRadius: AppRadius.sm,
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Üst satır: uyarı mesajı
          Row(
            children: [
              const Icon(Icons.warning_rounded,
                  color: AppColors.error, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '$msg $cropName — ${advice.name} tedavisi',
                  style: AppText.bodyMd(context).copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.error,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Hastalık adı + önerilen aktif maddeler
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3E0).withValues(alpha: 0.6),
              borderRadius: AppRadius.xs,
              border: Border.all(
                color: AppColors.warning.withValues(alpha: 0.2),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.healing_rounded,
                        color: AppColors.warning, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      advice.name == 'Bilinmiyor'
                          ? 'Genel koruyucu tedavi'
                          : advice.name,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: AppColors.warning,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        advice.urgency,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppColors.warning,
                        ),
                      ),
                    ),
                  ],
                ),
                if (topChemicals.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Önerilen: ${topChemicals.join(', ')}',
                    style: AppText.sm(context).copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => setState(() => _phase = _TreatmentPhase.guide),
              icon: const Icon(Icons.science_rounded, size: 18),
              label: const Text('İlaçla'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: const RoundedRectangleBorder(
                  borderRadius: AppRadius.sm,
                ),
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
              style:
                  AppText.bodyMd(context).copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(
              'Bugün aksiyon gerektiren bir şey yok.',
              style:
                  AppText.sm(context).copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    // Kritikler önce, max 5
    final sorted = recs!
        .where((r) => !r.ruleKey.startsWith('plant.dead.remove.'))
        .toList()
      ..sort((a, b) => b.severity.index.compareTo(a.severity.index));
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
        border: Border.all(color: AppColors.frost.withValues(alpha: 0.3)),
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
