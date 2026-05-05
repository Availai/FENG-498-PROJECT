import 'package:flutter_test/flutter_test.dart';

import 'package:feng_498/services/water_accounting.dart';

void main() {
  test('litre kaydini yontem verimiyle efektif mm etkisine cevirir', () {
    final impact = WaterAccounting.calculate(
      metadata: const {
        'water_liters': 1200,
        'irrigation_method': 'Damla sulama',
      },
      areaSqm: 1500,
      plantCount: 3000,
    );

    expect(impact.mm, closeTo(0.72, 0.001));
    expect(impact.liters, closeTo(1080, 0.001));
    expect(impact.source, 'liters');
  });

  test('ayni litre farkli sulama yontemlerinde farkli etki uretir', () {
    WaterImpact impact(String method) => WaterAccounting.calculate(
          metadata: {
            'water_liters': 1000,
            'irrigation_method': method,
          },
          areaSqm: 1000,
        );

    expect(impact('Damla sulama').mm, closeTo(0.90, 0.001));
    expect(impact('Yağmurlama').mm, closeTo(0.75, 0.001));
    expect(impact('Karık sulama').mm, closeTo(0.65, 0.001));
    expect(impact('Elle sulama').mm, closeTo(0.80, 0.001));
  });

  test('damla sulama suresini bitki sayisina gore mm etkisine cevirir', () {
    final impact = WaterAccounting.calculate(
      metadata: const {'irrigation_method': 'Damla sulama'},
      quantity: 60,
      quantityUnit: 'dk',
      areaSqm: 1500,
      plantCount: 3000,
    );

    expect(impact.mm, closeTo(3.2, 0.001));
    expect(impact.liters, closeTo(4800, 0.001));
    expect(impact.source, 'duration');
  });

  test('acik mm degeri litre ve sure bilgisinden once gelir', () {
    final impact = WaterAccounting.calculate(
      metadata: const {
        'effective_water_mm': 12,
        'water_liters': 1200,
        'duration_minutes': 60,
      },
      areaSqm: 1500,
      plantCount: 3000,
    );

    expect(impact.mm, closeTo(12, 0.001));
    expect(impact.liters, closeTo(18000, 0.001));
    expect(impact.source, 'mm');
  });
}
