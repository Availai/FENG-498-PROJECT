import 'package:flutter_test/flutter_test.dart';

import 'package:feng_498/data/crop_protocols.dart' show SoilType;
import 'package:feng_498/services/water_balance_engine.dart';

/// Pure-function engine — aynı girdiyle aynı çıktı, deterministik.
void main() {
  const engine = WaterBalanceEngine();

  WaterBalanceFacts buildFacts({
    required List<DailyForecast> forecast,
    SoilType soil = SoilType.loamy,
    String method = 'Damla sulama',
    double soilMoistureMm = 0,
    DateTime? planted,
  }) {
    return WaterBalanceFacts(
      cropNameTr: 'Domates',
      plantedDate: planted ?? DateTime.now().subtract(const Duration(days: 60)),
      totalSeasonDays: 135,
      areaDekar: 5.0,
      soilType: soil,
      irrigationMethod: method,
      currentSoilMoistureMm: soilMoistureMm,
      forecast: forecast,
      latitudeDeg: 37.0,
      elevationM: 100,
    );
  }

  DailyForecast day({
    required int dayOffset,
    double tMax = 32,
    double tMin = 18,
    double rhMax = 70,
    double rhMin = 30,
    double wind = 2.5,
    double precip = 0,
  }) =>
      DailyForecast(
        date: DateTime.now().add(Duration(days: dayOffset)),
        tMaxC: tMax,
        tMinC: tMin,
        rhMaxPct: rhMax,
        rhMinPct: rhMin,
        windMs: wind,
        precipMm: precip,
      );

  test('yagissiz sicak hafta sonraki sulamayi 7 gun icinde onerir', () {
    final result = engine.compute(buildFacts(
      forecast: [for (int i = 0; i < 7; i++) day(dayOffset: i)],
    ));
    expect(result.nextIrrigationDate, isNotNull);
    expect(result.daysUntilIrrigation, lessThanOrEqualTo(7));
    expect(result.recommendedDoseMm, greaterThan(0));
    expect(result.todayEtcMm, greaterThan(0));
  });

  test('yagisli gunler yagisin etkili kismini hesaba katar', () {
    final dry = engine.compute(buildFacts(
      forecast: [for (int i = 0; i < 7; i++) day(dayOffset: i)],
    ));
    final wet = engine.compute(buildFacts(
      forecast: [
        for (int i = 0; i < 7; i++)
          day(dayOffset: i, precip: i == 1 ? 25 : 0),
      ],
    ));
    // Yağışlı senaryoda sonraki sulama daha sonraya öteleniyor.
    final dryDays = dry.daysUntilIrrigation ?? 0;
    final wetDays = wet.daysUntilIrrigation ?? 0;
    expect(wetDays, greaterThan(dryDays));
    expect(wet.effectiveRainNext7DaysMm, greaterThan(0));
  });

  test('USDA-SCS efektif yagis ilk 2mm ihmal ve geri kalanin %80i', () {
    expect(WaterBalanceEngine.effectiveRain(0), 0);
    expect(WaterBalanceEngine.effectiveRain(1.5), 0);
    expect(
      WaterBalanceEngine.effectiveRain(12),
      closeTo((12 - 2) * 0.80, 0.001),
    );
  });

  test('toprak tipi tarla kapasitesini dogru dondurur', () {
    expect(WaterBalanceEngine.fieldCapacityMm(SoilType.sandy), 60);
    expect(WaterBalanceEngine.fieldCapacityMm(SoilType.loamy), 120);
    expect(WaterBalanceEngine.fieldCapacityMm(SoilType.clay), 180);
    expect(WaterBalanceEngine.fieldCapacityMm(SoilType.volcanic), 132);
  });

  test('ayni girdi ayni cikti uretir (deterministik)', () {
    final facts = buildFacts(
      forecast: [for (int i = 0; i < 7; i++) day(dayOffset: i, precip: 3)],
    );
    final a = engine.compute(facts);
    final b = engine.compute(facts);
    expect(a.recommendedDoseMm, b.recommendedDoseMm);
    expect(a.todayEtcMm, b.todayEtcMm);
    expect(a.nextIrrigationDate, b.nextIrrigationDate);
  });

  test('yontem verimi gross litre hesabini etkiler', () {
    final dripFacts = buildFacts(
      forecast: [for (int i = 0; i < 7; i++) day(dayOffset: i)],
      method: 'Damla sulama',
    );
    final furrowFacts = buildFacts(
      forecast: [for (int i = 0; i < 7; i++) day(dayOffset: i)],
      method: 'Karık sulama',
    );
    final drip = engine.compute(dripFacts);
    final furrow = engine.compute(furrowFacts);
    // Aynı net mm için karık çok daha fazla litre ister (%50 vs %92 verim).
    expect(furrow.recommendedGrossLiters,
        greaterThan(drip.recommendedGrossLiters));
  });

  test('proje 7 gunluk her gun icin tahmin uretir', () {
    final r = engine.compute(buildFacts(
      forecast: [for (int i = 0; i < 7; i++) day(dayOffset: i)],
    ));
    expect(r.projections, hasLength(7));
    for (final p in r.projections) {
      expect(p.etcMm, greaterThanOrEqualTo(0));
      expect(p.soilEndMm, lessThanOrEqualTo(r.fieldCapacityMm));
    }
  });

  test('kumlu toprak killi topraga gore daha sik sulama gerektirir', () {
    final dryWeek = [for (int i = 0; i < 7; i++) day(dayOffset: i)];
    final sandy = engine.compute(buildFacts(
      forecast: dryWeek,
      soil: SoilType.sandy,
    ));
    final clay = engine.compute(buildFacts(
      forecast: dryWeek,
      soil: SoilType.clay,
    ));
    // Kumlu toprakta sonraki sulama daha erken gelir.
    final sandyDays = sandy.daysUntilIrrigation ?? 99;
    final clayDays = clay.daysUntilIrrigation ?? 99;
    expect(sandyDays, lessThanOrEqualTo(clayDays));
  });
}
