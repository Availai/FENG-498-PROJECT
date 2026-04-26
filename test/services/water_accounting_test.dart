import 'package:flutter_test/flutter_test.dart';

import 'package:feng_498/services/water_accounting.dart';

void main() {
  test('litre kaydini alan uzerinden mm etkisine cevirir', () {
    final impact = WaterAccounting.calculate(
      metadata: const {'water_liters': 1200},
      areaSqm: 1500,
      plantCount: 3000,
    );

    expect(impact.mm, closeTo(0.8, 0.001));
    expect(impact.liters, closeTo(1200, 0.001));
    expect(impact.source, 'liters');
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
