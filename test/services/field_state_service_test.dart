import 'package:flutter_test/flutter_test.dart';

import 'package:feng_498/data/activity_types.dart';
import 'package:feng_498/services/field_state_service.dart';

void main() {
  test('ekim metaverisinden alan, bitki sayisi ve su etkisini hesaplar', () {
    final service = const FieldStateService();
    final now = DateTime(2026, 4, 24);

    final states = service.compute(
      now: now,
      field: const {
        'id': 'field-1',
        'area_sqm': 3000,
      },
      fieldCrops: const [
        {
          'id': 'crop-1',
          'name': 'Domates',
          'row_spacing_cm': 100,
          'plant_spacing_cm': 50,
          'planted_date': '01.04.2026',
        },
      ],
      activities: [
        {
          'crop_id': 'crop-1',
          'type': ActivityType.planting,
          'date': DateTime(2026, 4, 1),
          'metadata': const {
            'setup_version': 1,
            'area_dekar': 1.5,
            'row_spacing_cm': 100,
            'plant_spacing_cm': 50,
            'irrigation_method': 'Damla sulama',
          },
        },
        {
          'crop_id': 'crop-1',
          'type': ActivityType.watering,
          'date': DateTime(2026, 4, 23),
          'metadata': const {
            'quantity': 60,
            'quantity_unit': 'dk',
            'irrigation_method': 'Damla sulama',
          },
        },
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
    );

    expect(states, hasLength(1));
    expect(states.single.areaDekar, closeTo(1.5, 0.001));
    expect(states.single.estimatedPlantCount, 3000);
    expect(states.single.weeklyWaterMm, closeTo(4.0, 0.001));
    expect(states.single.weeklyWaterLiters, closeTo(6000, 0.001));
  });
}
