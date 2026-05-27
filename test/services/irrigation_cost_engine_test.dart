import 'package:flutter_test/flutter_test.dart';

import 'package:feng_498/services/irrigation_cost_engine.dart';

void main() {
  const engine = IrrigationCostEngine();

  CostFacts facts({
    String current = 'Karık sulama',
    String alt = 'Damla sulama',
    double? investTlPerDa,
  }) {
    return CostFacts(
      areaDekar: 5.0,
      seasonNetMmTotal: 400, // sezon boyu ~400 mm net ihtiyaç
      currentMethod: current,
      alternativeMethod: alt,
      waterTlPerM3: 1.20,
      electricityTlPerKwh: 2.45,
      pumpKwhPerM3: 0.5,
      estimatedInvestmentTlPerDecare: investTlPerDa,
    );
  }

  test('karik->damla gecisi pozitif tasarruf uretir', () {
    final r = engine.compute(facts());
    expect(r.savedTlPerSeason, greaterThan(0));
    expect(r.savedM3, greaterThan(0));
    expect(r.isWorthIt, isTrue);
    // Damla daha az gross su gerektirir.
    expect(r.alternative.grossM3, lessThan(r.current.grossM3));
  });

  test('ayni yontemle kiyas sifir tasarruf verir', () {
    final r = engine.compute(facts(current: 'Damla sulama', alt: 'Damla sulama'));
    expect(r.savedM3, closeTo(0, 0.001));
    expect(r.savedTlPerSeason, closeTo(0, 0.001));
  });

  test('yatirim verilirse geri odeme yili hesaplanir', () {
    final r = engine.compute(facts(investTlPerDa: 25000));
    expect(r.investmentTl, closeTo(125000, 0.001)); // 5 da × 25K
    expect(r.investmentAfterSubsidyTl, closeTo(62500, 0.001)); // %50 hibe
    expect(r.paybackYears, isNotNull);
    expect(r.paybackYearsWithSubsidy, isNotNull);
    expect(r.paybackYearsWithSubsidy!,
        lessThan(r.paybackYears!)); // hibe payback'i kısaltır
  });

  test('su+enerji maliyeti gross m3 ile dogru orantili', () {
    final r = engine.compute(facts());
    final c = r.current;
    final expectedWater = c.grossM3 * 1.20;
    final expectedEnergy = c.grossM3 * 0.5 * 2.45;
    expect(c.waterCostTl, closeTo(expectedWater, 0.001));
    expect(c.energyCostTl, closeTo(expectedEnergy, 0.001));
    expect(c.totalCostTl, closeTo(expectedWater + expectedEnergy, 0.001));
  });

  test('ayni girdi ayni cikti uretir (deterministik)', () {
    final f = facts(investTlPerDa: 25000);
    final a = engine.compute(f);
    final b = engine.compute(f);
    expect(a.savedTlPerSeason, b.savedTlPerSeason);
    expect(a.paybackYears, b.paybackYears);
  });

  test('SDI ile damla arasinda kucuk fark da hesaplanir', () {
    final r = engine.compute(facts(
      current: 'Damla sulama',
      alt: 'Yüzey altı damla (SDI)',
    ));
    expect(r.savedM3, greaterThan(0));
    expect(r.alternative.efficiency, greaterThan(r.current.efficiency));
  });
}
