import 'package:flutter/foundation.dart';

import '../data/turkish_crops_repository.dart';

/// Skorlanmış bitki — widget'ların tükettiği sade view model.
class ScoredCrop {
  final TurkishCrop crop;
  final double score;
  final List<String> reasons;
  final String confidence;

  const ScoredCrop({
    required this.crop,
    required this.score,
    required this.reasons,
    required this.confidence,
  });
}

/// 292 bitki üzerinde `TurkishCrop.scoreFor` döngüsünü **background isolate**
/// içinde koşturur. UI thread jank'sız kalır; widget'lar `scoreFor` çağırmaz.
class CropScoringService {
  CropScoringService(this._repo);

  final TurkishCropsRepository _repo;

  /// Tarla çevre koşullarına göre tüm uygun bitkileri skorlayıp sıralar.
  /// `topN` verilirse en yüksek skorlu ilk N öğe döner.
  Future<List<ScoredCrop>> rankForEnv({
    double? temperature,
    double? soilPh,
    double? weeklyRain,
    int? month,
    String? region,
    int poolLimit = 500,
    int? topN,
  }) async {
    await _repo.ensureReady();
    final pool = _repo.search(query: '', limit: poolLimit);
    if (pool.isEmpty) return const <ScoredCrop>[];

    final input = _ScoringInput(
      crops: pool,
      temperature: temperature,
      soilPh: soilPh,
      weeklyRain: weeklyRain,
      month: month,
      region: region,
      topN: topN,
    );
    return compute(_scoreAndSort, input);
  }
}

class _ScoringInput {
  final List<TurkishCrop> crops;
  final double? temperature;
  final double? soilPh;
  final double? weeklyRain;
  final int? month;
  final String? region;
  final int? topN;

  const _ScoringInput({
    required this.crops,
    this.temperature,
    this.soilPh,
    this.weeklyRain,
    this.month,
    this.region,
    this.topN,
  });
}

List<ScoredCrop> _scoreAndSort(_ScoringInput input) {
  final out = <ScoredCrop>[];
  for (final tc in input.crops) {
    final s = tc.scoreFor(
      temperature: input.temperature,
      soilPh: input.soilPh,
      weeklyRain: input.weeklyRain,
      month: input.month,
      region: input.region,
    );
    out.add(ScoredCrop(
      crop: tc,
      score: s.score,
      reasons: s.reasons,
      confidence: s.confidence,
    ));
  }
  out.sort((a, b) => b.score.compareTo(a.score));
  final n = input.topN;
  if (n != null && out.length > n) {
    return out.sublist(0, n);
  }
  return out;
}
