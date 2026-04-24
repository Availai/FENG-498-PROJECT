import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/app_database.dart';
import '../data/supported_crops.dart';
import '../services/app_providers.dart';
import '../services/growth_engine.dart';
import 'crop_growth_sprite.dart';

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
        final waterStressUnit =
            (state.waterDeficitMm / 20.0).clamp(0.0, 1.0);
        final stress = (waterStressUnit * 0.35 +
                state.nStressIdx * 0.35 +
                state.diseasePressure * 0.30)
            .clamp(0.0, 1.0);

        return CropGrowthSprite(
          cropKey: key,
          stageKey: state.currentStageKey,
          overallProgress: overall,
          stressIndex: stress,
          animateSway: widget.animateSway,
        );
      },
    );
  }
}
