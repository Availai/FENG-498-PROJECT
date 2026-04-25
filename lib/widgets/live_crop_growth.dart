import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/app_database.dart';
import '../data/supported_crops.dart';
import '../services/app_providers.dart';
import '../services/growth_engine.dart';
import '../theme/app_theme.dart';
import 'crop_growth_sprite.dart';

class CropVisualState {
  final String cropKey;
  final String stageKey;
  final double overallProgress;
  final double waterStress;
  final double nitrogenStress;
  final double diseasePressure;
  final double yieldMultiplier;
  final bool harvestReady;

  const CropVisualState({
    required this.cropKey,
    required this.stageKey,
    required this.overallProgress,
    required this.waterStress,
    required this.nitrogenStress,
    required this.diseasePressure,
    required this.yieldMultiplier,
    required this.harvestReady,
  });

  double get stressIndex =>
      (waterStress * 0.35 + nitrogenStress * 0.35 + diseasePressure * 0.30)
          .clamp(0.0, 1.0);

  int get yieldLossPct => ((1.0 - yieldMultiplier) * 100).round().clamp(0, 50);

  String get stageLabel => switch (stageKey) {
        'cimlenme' => 'Çimlenme',
        'vejetatif' => 'Vejetatif büyüme',
        'ciceklenme' => 'Çiçeklenme',
        'meyve_dolumu' => 'Meyve dolumu',
        'olgunlasma' => 'Olgunlaşma',
        _ => 'Ekim sonrası',
      };

  String get mainStatus {
    if (harvestReady) return 'Hasat penceresi açıldı';
    if (waterStress > 0.55) return 'Su stresi yüksek';
    if (nitrogenStress > 0.45) return 'Azot desteği gerekebilir';
    if (diseasePressure > 0.40) return 'Hastalık baskısı izlenmeli';
    if (stressIndex < 0.20) return 'Gelişim dengeli';
    return 'Yakından takip et';
  }
}

CropVisualState cropVisualStateFromGrowth({
  required String cropKey,
  required CropGrowthState? state,
  required String fallbackStageKey,
  required double fallbackWaterDeficitMm,
  required int daysToHarvest,
  required int yieldLossPct,
}) {
  final stageKey = state?.currentStageKey ?? fallbackStageKey;
  final overall = state == null
      ? 0.03
      : GrowthEngine.overallProgressFor(cropKey, state.accumulatedGdd);
  final waterDeficit = state?.waterDeficitMm ?? fallbackWaterDeficitMm;
  final yieldMultiplier =
      state?.yieldMultiplier ?? (1.0 - yieldLossPct / 100.0);
  return CropVisualState(
    cropKey: cropKey,
    stageKey: stageKey,
    overallProgress: overall,
    waterStress: (waterDeficit / 24.0).clamp(0.0, 1.0),
    nitrogenStress: (state?.nStressIdx ?? 0).clamp(0.0, 1.0),
    diseasePressure: (state?.diseasePressure ?? 0).clamp(0.0, 1.0),
    yieldMultiplier: yieldMultiplier.clamp(0.5, 1.15),
    harvestReady: daysToHarvest <= 0 || stageKey == 'olgunlasma',
  );
}

/// `CropGrowthStates` stream'ine bağlı canlı bitki büyüme görseli.
///
/// `GrowthEngine` aynı ekin için satır üretmemişse (ilk açılış veya desteklenen
/// bitki eklendi ama henüz hesaplama yok) arka planda tek seferlik
/// `recompute(cropId)` tetiklenir; sonraki sorgu Drift stream üzerinden
/// otomatik akar. Desteklenmeyen bitki (3 vitrin dışı) için `fallback` döner.
class LiveCropGrowth extends ConsumerStatefulWidget {
  final String cropId;

  /// Bitki adı — desteklenip desteklenmediğini (3 vitrin) belirlemek için.
  final String cropName;

  /// Henüz kayıt yoksa veya desteklenen bitki değilse gösterilecek widget.
  /// Null ise boş `SizedBox.shrink` döner.
  final Widget? fallback;

  final bool animateSway;

  const LiveCropGrowth({
    super.key,
    required this.cropId,
    required this.cropName,
    this.fallback,
    this.animateSway = true,
  });

  @override
  ConsumerState<LiveCropGrowth> createState() => _LiveCropGrowthState();
}

class _LiveCropGrowthState extends ConsumerState<LiveCropGrowth> {
  bool _kickedRecompute = false;

  String? get _cropKey {
    final canonical = SupportedCrops.canonicalName(widget.cropName);
    if (canonical == null) return null;
    final key = SupportedCrops.normalize(canonical);
    return GrowthEngine.isSupported(key) ? key : null;
  }

  @override
  Widget build(BuildContext context) {
    final key = _cropKey;
    if (key == null) {
      return widget.fallback ?? const SizedBox.shrink();
    }

    final engine = ref.watch(growthEngineProvider);
    return StreamBuilder<CropGrowthState?>(
      stream: engine.watch(widget.cropId),
      builder: (context, snap) {
        final state = snap.data;
        if (state == null) {
          // İlk defa görünüyor — arka planda tek seferlik hesap tetikle.
          if (!_kickedRecompute) {
            _kickedRecompute = true;
            Future.microtask(() => engine.recompute(cropId: widget.cropId));
          }
          // Placeholder: çimlenme aşamasında minik fide.
          return CropGrowthSprite(
            cropKey: key,
            stageKey: 'cimlenme',
            overallProgress: 0.02,
            stressIndex: 0.0,
            animateSway: widget.animateSway,
          );
        }

        final overall =
            GrowthEngine.overallProgressFor(key, state.accumulatedGdd);
        // Kombine stres — üç stresin ağırlıklı ortalaması (0..1).
        final waterStressUnit = (state.waterDeficitMm / 20.0).clamp(0.0, 1.0);
        final stress = (waterStressUnit * 0.35 +
                state.nStressIdx * 0.35 +
                state.diseasePressure * 0.30)
            .clamp(0.0, 1.0);

        return CropGrowthSprite(
          cropKey: key,
          stageKey: state.currentStageKey,
          overallProgress: overall,
          stressIndex: stress,
          waterStress: waterStressUnit,
          nitrogenStress: state.nStressIdx,
          diseasePressure: state.diseasePressure,
          harvestReady: state.currentStageKey == 'olgunlasma',
          animateSway: widget.animateSway,
        );
      },
    );
  }
}

class LiveCropGuideScene extends ConsumerStatefulWidget {
  final String cropId;
  final String cropName;
  final DateTime plantedDate;
  final DateTime harvestDate;
  final String? fallbackStageKey;
  final double fallbackWaterDeficitMm;
  final int yieldLossPct;

  const LiveCropGuideScene({
    super.key,
    required this.cropId,
    required this.cropName,
    required this.plantedDate,
    required this.harvestDate,
    this.fallbackStageKey,
    this.fallbackWaterDeficitMm = 0,
    this.yieldLossPct = 0,
  });

  @override
  ConsumerState<LiveCropGuideScene> createState() => _LiveCropGuideSceneState();
}

class _LiveCropGuideSceneState extends ConsumerState<LiveCropGuideScene> {
  bool _kickedRecompute = false;

  String? get _cropKey {
    final canonical = SupportedCrops.canonicalName(widget.cropName);
    if (canonical == null) return null;
    final key = SupportedCrops.normalize(canonical);
    return GrowthEngine.isSupported(key) ? key : null;
  }

  @override
  Widget build(BuildContext context) {
    final cropKey = _cropKey;
    if (cropKey == null) return const SizedBox.shrink();

    final engine = ref.watch(growthEngineProvider);
    final daysSince = DateTime.now().difference(widget.plantedDate).inDays;
    final daysToHarvest = widget.harvestDate.difference(DateTime.now()).inDays;

    return StreamBuilder<CropGrowthState?>(
      stream: engine.watch(widget.cropId),
      builder: (context, snap) {
        final state = snap.data;
        if (state == null && !_kickedRecompute) {
          _kickedRecompute = true;
          Future.microtask(() => engine.recompute(cropId: widget.cropId));
        }

        final visual = cropVisualStateFromGrowth(
          cropKey: cropKey,
          state: state,
          fallbackStageKey: widget.fallbackStageKey ?? 'cimlenme',
          fallbackWaterDeficitMm: widget.fallbackWaterDeficitMm,
          daysToHarvest: daysToHarvest,
          yieldLossPct: widget.yieldLossPct,
        );

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppRadius.md,
            border:
                Border.all(color: AppColors.emerald.withValues(alpha: 0.24)),
            boxShadow: AppShadows.card,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 132,
                    height: 156,
                    child: CropGrowthSprite(
                      cropKey: visual.cropKey,
                      stageKey: visual.stageKey,
                      overallProgress: visual.overallProgress,
                      stressIndex: visual.stressIndex,
                      waterStress: visual.waterStress,
                      nitrogenStress: visual.nitrogenStress,
                      diseasePressure: visual.diseasePressure,
                      harvestReady: visual.harvestReady,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Canlı yetiştirme durumu',
                            style: AppText.bodyMd(context)),
                        const SizedBox(height: 4),
                        Text(
                          '${visual.stageLabel} • $daysSince. gün',
                          style: AppText.xs(context)
                              .copyWith(color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 10),
                        _StatusPill(visual.mainStatus, visual: visual),
                        const SizedBox(height: 12),
                        _VisualGauge(
                          label: 'Büyüme',
                          value: visual.overallProgress,
                          color: AppColors.emerald,
                        ),
                        _VisualGauge(
                          label: 'Su stresi',
                          value: visual.waterStress,
                          color: AppColors.frost,
                        ),
                        _VisualGauge(
                          label: 'Hastalık baskısı',
                          value: visual.diseasePressure,
                          color: AppColors.warning,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                _sceneHint(visual, daysToHarvest),
                style: AppText.xs(context).copyWith(height: 1.35),
              ),
            ],
          ),
        );
      },
    );
  }

  String _sceneHint(CropVisualState visual, int daysToHarvest) {
    if (visual.harvestReady) {
      return 'Bitki olgunluk sinyali veriyor. Hasat görevlerini ve son sulama kesme uyarılarını kontrol et.';
    }
    if (visual.waterStress > 0.55) {
      return 'Toprak kuru görünüyor; sulama kaydı girildiğinde açık mm azalır ve sahne toparlanır.';
    }
    if (visual.diseasePressure > 0.40) {
      return 'Yaprak lekeleri hastalık baskısını temsil eder; ilaçlama ve yağış sonrası kontrolleri aksatma.';
    }
    final harvestText =
        daysToHarvest > 0 ? 'Hasada yaklaşık $daysToHarvest gün var.' : '';
    return 'Sahne sulama, gübreleme ve hastalık kayıtlarına göre canlı güncellenir. $harvestText';
  }
}

class _StatusPill extends StatelessWidget {
  final String label;
  final CropVisualState visual;

  const _StatusPill(this.label, {required this.visual});

  @override
  Widget build(BuildContext context) {
    final color = visual.harvestReady
        ? AppColors.wheat
        : visual.stressIndex > 0.45
            ? AppColors.warning
            : AppColors.emerald;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: AppRadius.full,
        border: Border.all(color: color.withValues(alpha: 0.30)),
      ),
      child: Text(
        label,
        style: AppText.xs(context).copyWith(
          color: color,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _VisualGauge extends StatelessWidget {
  final String label;
  final double value;
  final Color color;

  const _VisualGauge({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(label, style: AppText.xs(context))),
              Text(
                '%${(value.clamp(0.0, 1.0) * 100).round()}',
                style: AppText.xs(context).copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: value.clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: AppColors.surfaceAlt,
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ],
      ),
    );
  }
}
