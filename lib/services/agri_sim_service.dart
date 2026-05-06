/// AgriSimService — Büyüme Gün-Derece (GDD) Tabanlı Bitki Büyüme Simülatörü
///
/// Algoritma: GDD = max(0, ((Tmax + Tmin) / 2) - Tbase)
/// Her evre için gerekli GDD birikince sonraki evreye geçilir.
/// Gerçek hava verisi yoksa bölgesel klimatoloji ortalamaları kullanılır.
library;

import 'dart:math' as math;
import '../models/seed_models.dart';

class AgriSimService {
  // ─────────────────────────────────────────────────────────────────────────
  // TABANLAR VE KLİMATOLOJİ
  // ─────────────────────────────────────────────────────────────────────────

  static const Map<String, double> _tBase = {
    'bugday': 0.0,
    'arpa': 0.0,
    'misir': 10.0,
    'aycicegi': 6.0,
    'pamuk': 15.5,
    'celtik': 10.0,
    'kolza': 0.0,
    'nohut': 0.0,
    'mercimek': 0.0,
  };

  /// Bölgesel aylık ortalama sıcaklık tahmini (°C)
  static const Map<TurkishRegion, List<double>> _monthlyAvgTemp = {
    TurkishRegion.trakya: [
      3.5,
      4.5,
      7.5,
      13.0,
      18.0,
      23.0,
      26.0,
      25.5,
      21.0,
      15.5,
      9.5,
      5.0
    ],
    TurkishRegion.icAnadolu: [
      0.0,
      1.5,
      5.5,
      11.5,
      16.5,
      21.5,
      25.0,
      24.5,
      19.5,
      13.0,
      6.0,
      1.5
    ],
    TurkishRegion.ege: [
      7.5,
      8.5,
      11.5,
      16.5,
      21.5,
      26.5,
      29.5,
      29.0,
      24.5,
      18.5,
      13.0,
      9.0
    ],
    TurkishRegion.akdeniz: [
      9.0,
      10.0,
      13.5,
      18.0,
      23.0,
      28.0,
      31.0,
      31.0,
      26.5,
      20.5,
      15.0,
      10.5
    ],
    TurkishRegion.karadeniz: [
      5.0,
      5.5,
      8.0,
      12.5,
      17.0,
      21.0,
      24.0,
      24.0,
      19.5,
      14.5,
      10.0,
      6.5
    ],
    TurkishRegion.doguAnadolu: [
      -7.0,
      -5.5,
      -1.5,
      7.0,
      12.5,
      17.5,
      22.0,
      21.5,
      16.5,
      9.5,
      2.5,
      -3.5
    ],
    TurkishRegion.guneydoguAnadolu: [
      4.0,
      6.0,
      10.5,
      17.0,
      23.0,
      29.5,
      34.0,
      33.5,
      28.5,
      21.0,
      12.5,
      6.0
    ],
  };

  // ─────────────────────────────────────────────────────────────────────────
  // ANA SİMÜLASYON
  // ─────────────────────────────────────────────────────────────────────────

  /// Tam büyüme döngüsünü simüle eder.
  /// [dailyTemps]: {date: DateTime, tmax: double, tmin: double} listesi (opsiyonel)
  ///   yoksa klimatoloji ortalamaları kullanılır.
  static SimulationResult simulate({
    required SeedVariety variety,
    required DateTime sowDate,
    TurkishRegion region = TurkishRegion.icAnadolu,
    List<Map<String, dynamic>> dailyTemps = const [],
  }) {
    final cropKey = _normalizeCropName(variety.cropTr);
    final tBase = _tBase[cropKey] ?? 0.0;
    final monthlyAvg =
        _monthlyAvgTemp[region] ?? _monthlyAvgTemp[TurkishRegion.icAnadolu]!;

    double accGdd = 0.0;
    int stageIdx = 0;
    final stageDates = <PhenologyStage, DateTime>{
      PhenologyStage.cimlenme: sowDate,
    };
    final records = <GrowthDayRecord>[];
    DateTime current = sowDate;
    double heightCm = 0.0;
    double biomass = 0.0;
    double yieldMultiplier = 1.0;

    for (int day = 0; day < variety.totalDaysToHarvest + 30; day++) {
      if (stageIdx >= variety.phenology.length) break;

      final stageDef = variety.phenology[stageIdx];
      final monthIdx = (current.month - 1) % 12;

      // Günlük sıcaklık: gerçek veri varsa kullan, yoksa klimatoloji
      double tmax, tmin;
      if (day < dailyTemps.length) {
        tmax = (dailyTemps[day]['tmax'] as num).toDouble();
        tmin = (dailyTemps[day]['tmin'] as num).toDouble();
      } else {
        final avgT = monthlyAvg[monthIdx];
        tmax = avgT + 6.0;
        tmin = avgT - 6.0;
      }

      // GDD hesabı
      final tmean = (tmax + tmin) / 2;
      final gdd = math.max(0.0, tmean - tBase);
      accGdd += gdd;

      // Sıcaklık stresi hesabı
      double stressIdx = 0.0;
      if (tmean < stageDef.minTempC) {
        stressIdx = ((stageDef.minTempC - tmean) / 10).clamp(0.0, 1.0);
      } else if (tmean > stageDef.maxTempC) {
        stressIdx = ((tmean - stageDef.maxTempC) / 10).clamp(0.0, 1.0);
      }
      yieldMultiplier *= (1.0 - stressIdx * 0.03);

      // Boyu ve biyokütleyi tahmin et (sigmoid büyüme modeli)
      final progress = (day / variety.totalDaysToHarvest).clamp(0.0, 1.0);
      biomass = 1.0 / (1.0 + math.exp(-10 * (progress - 0.5)));
      heightCm = _estimateHeight(cropKey, progress);

      // Evre geçiş kontrolü
      String? event;
      if (accGdd >= stageDef.requiredGdd &&
          stageIdx < variety.phenology.length - 1) {
        stageIdx++;
        final nextStage = variety.phenology[stageIdx].stage;
        stageDates[nextStage] = current;
        event = '${nextStage.icon} ${nextStage.labelTr} başladı';
        accGdd = 0.0; // Her evre için GDD sıfırlanır
      }

      // Özel olaylar
      if (cropKey == 'bugday' &&
          day == variety.daysUntilStageStart(PhenologyStage.ciceklenme)) {
        event = '🌾 Başak çıkışı — üst gübre zamanı';
      }
      if (cropKey == 'aycicegi' &&
          day == variety.daysUntilStageStart(PhenologyStage.ciceklenme)) {
        event = '🌻 İlk çiçek açtı — ilaçlama durdurun';
      }

      records.add(GrowthDayRecord(
        dayNumber: day + 1,
        stage: variety
            .phenology[stageIdx < variety.phenology.length
                ? stageIdx
                : variety.phenology.length - 1]
            .stage,
        accumulatedGdd: accGdd,
        heightCm: heightCm,
        biomassRelative: biomass,
        stressIndex: stressIdx,
        event: event,
      ));

      current = current.add(const Duration(days: 1));
    }

    final harvestDate = stageDates[PhenologyStage.hasat] ??
        sowDate.add(Duration(days: variety.totalDaysToHarvest));

    final predictedYield = variety.avgYieldKgDekar *
        yieldMultiplier.clamp(0.5, 1.15); // max %15 verim bonusu

    return SimulationResult(
      variety: variety,
      sowDate: sowDate,
      estimatedHarvestDate: harvestDate,
      dailyRecords: records,
      stageDates: stageDates,
      predictedYieldKgDekar: predictedYield,
    );
  }

  static double _estimateHeight(String cropTr, double progress) {
    final maxH = {
      'bugday': 90.0,
      'arpa': 80.0,
      'misir': 250.0,
      'aycicegi': 200.0,
      'pamuk': 120.0,
      'celtik': 100.0,
      'kolza': 150.0,
      'nohut': 60.0,
    };
    final max = maxH[cropTr] ?? 100.0;
    // Sigmoid büyüme; olgunlukta hafif azalma
    if (progress > 0.85) return max * (1.0 - (progress - 0.85) * 0.5);
    return max / (1.0 + math.exp(-12 * (progress - 0.4)));
  }

  // ─────────────────────────────────────────────────────────────────────────
  // YARDIMCI
  // ─────────────────────────────────────────────────────────────────────────

  static PhenologyStage currentStage({
    required SeedVariety variety,
    required DateTime sowDate,
    required List<Map<String, dynamic>> dailyTemps,
    TurkishRegion region = TurkishRegion.icAnadolu,
  }) {
    final result = simulate(
      variety: variety,
      sowDate: sowDate,
      region: region,
      dailyTemps: dailyTemps,
    );
    return result.currentStage;
  }

  static int daysUntilNextStage({
    required SeedVariety variety,
    required DateTime sowDate,
    required List<Map<String, dynamic>> dailyTemps,
    TurkishRegion region = TurkishRegion.icAnadolu,
  }) {
    final result = simulate(
      variety: variety,
      sowDate: sowDate,
      region: region,
      dailyTemps: dailyTemps,
    );
    final current = result.currentStage;
    final stageList = PhenologyStage.values;
    final nextIdx = stageList.indexOf(current) + 1;
    if (nextIdx >= stageList.length) return 0;

    final nextStage = stageList[nextIdx];
    final nextDate = result.stageDates[nextStage];
    if (nextDate == null) return variety.phenology.last.baseDurationDays;
    return nextDate.difference(DateTime.now()).inDays.clamp(0, 365);
  }

  static String _normalizeCropName(String value) => value
      .toLowerCase()
      .trim()
      .replaceAll('\u011f', 'g')
      .replaceAll('\u00fc', 'u')
      .replaceAll('\u015f', 's')
      .replaceAll('\u0131', 'i')
      .replaceAll('\u00f6', 'o')
      .replaceAll('\u00e7', 'c');
}
