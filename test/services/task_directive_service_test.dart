import 'package:flutter_test/flutter_test.dart';

import 'package:feng_498/data/activity_types.dart';
import 'package:feng_498/services/field_state_service.dart';
import 'package:feng_498/services/task_directive_service.dart';

void main() {
  test('bugun sulama direktifi alan, bitki sayisi ve kaynak tasir', () {
    final service = const TaskDirectiveService();
    final now = DateTime(2026, 4, 24);

    final directives = service.generate(
      now: now,
      fieldCrops: [
        {
          'id': 'crop-1',
          'name': 'Mısır',
          'planted_date': '01.04.2026',
          'harvest_days': 110,
          'water_interval_days': 7,
        },
      ],
      activities: const [],
      growthStates: const {
        'crop-1': GrowthSnapshot(
          stageKey: 'vejetatif',
          stageProgress: 0.4,
          accumulatedGdd: 300,
          waterDeficitMm: 8,
          nStressIdx: 0.0,
          diseasePressure: 0.0,
          yieldMultiplier: 0.92,
        ),
      },
      fieldStates: {
        'crop-1': CropFieldState(
          cropId: 'crop-1',
          cropName: 'Mısır',
          areaDekar: 2.4,
          areaSqm: 2400,
          estimatedPlantCount: 17000,
          weeklyWaterMm: 0,
          weeklyWaterLiters: 0,
          seasonalWaterMm: 0,
          seasonalWaterLiters: 0,
          weeklyWaterTargetMm: 39,
          harvestedKg: 0,
          yieldKgPerDekar: 0,
        ),
      },
    );

    final water = directives.firstWhere(
      (d) => d.actionType == ActivityType.watering,
    );

    expect(water.recommendedQuantity, isNotNull);
    expect(water.steps, isNotEmpty);
    expect(water.sourceRefs, isNotEmpty);
    expect(water.areaDekar, 2.4);
    expect(water.plantCount, 17000);
  });
}
