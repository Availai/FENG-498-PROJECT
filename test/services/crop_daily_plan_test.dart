import 'package:flutter_test/flutter_test.dart';

import 'package:feng_498/data/activity_types.dart';
import 'package:feng_498/services/crop_daily_plan.dart';

void main() {
  test('gunluk plan litre sulama ve yagmuru su muhasebesine katar', () {
    final result = const CropDailyPlanService().build(
      now: DateTime(2026, 4, 24),
      fieldId: 'field-1',
      areaDekar: 1.5,
      crop: const {
        'id': 'crop-1',
        'name': 'Misir',
        'planted_date': '01.04.2026',
        'harvest_days': 110,
        'row_spacing_cm': 100,
        'plant_spacing_cm': 50,
      },
      activities: [
        {
          'crop_id': 'crop-1',
          'type': ActivityType.watering,
          'date': DateTime(2026, 4, 24),
          'metadata': const {
            'water_liters': 1200,
            'irrigation_method': 'Damla sulama',
          },
        },
      ],
      scheduledEvents: const [],
      dailyForecast: const [
        {'date': '2026-04-24', 'rain': 4.0},
      ],
    );

    expect(result, isNotNull);
    expect(result!.appliedIrrigationMm, closeTo(0.736, 0.001));
    expect(result.accountedRainMm, closeTo(4.0, 0.001));
    expect(result.today, isNotNull);
    expect(result.today!.waterIrrigatedMm, closeTo(0.736, 0.001));
    expect(result.today!.waterRainMm, closeTo(4.0, 0.001));
  });

  test('auto_seed ve gelecek sulama kayitlarini gercek su saymaz', () {
    final result = const CropDailyPlanService().build(
      now: DateTime(2026, 4, 24, 9),
      fieldId: 'field-1',
      areaDekar: 1,
      crop: const {
        'id': 'crop-1',
        'name': 'Ayçiçeği',
        'planted_date': '24.04.2026',
        'harvest_days': 120,
      },
      activities: [
        {
          'crop_id': 'crop-1',
          'type': ActivityType.watering,
          'date': DateTime(2026, 4, 24, 8),
          'source': 'auto_seed',
          'metadata': const {
            'water_liters': 5000,
            'irrigation_method': 'Damla sulama',
          },
        },
        {
          'crop_id': 'crop-1',
          'type': ActivityType.watering,
          'date': DateTime(2026, 4, 25),
          'source': 'manual',
          'metadata': const {
            'water_liters': 5000,
            'irrigation_method': 'Damla sulama',
          },
        },
      ],
      scheduledEvents: const [],
      dailyForecast: const [
        {'date': '2026-04-24', 'rain': 0.0},
      ],
    );

    expect(result, isNotNull);
    expect(result!.appliedIrrigationMm, 0);
    expect(result.today!.waterIrrigatedMm, 0);
  });
}
