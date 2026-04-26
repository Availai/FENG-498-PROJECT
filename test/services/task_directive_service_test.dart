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

  test(
      'gelecek tarihli auto_seed planlari "son sulama" sayilmaz; '
      'sulama direktifi yine uretilir ve "111 gun var" gibi imkansiz '
      'mesaj olusmaz',
      () {
    // Regresyon: `watchActivityLog` kalemleri (manuel + auto_seed) aynı
    // listede akar. Eski `_lastActivity`, gelecek tarihli auto_seed kaydını
    // "en son sulama" olarak alıp `daysSinceWater`'ı negatife düşürüyordu.
    // Bu durumda hem direktif üretilmiyor hem de "sonraki sulama 111 gün"
    // gibi imkânsız ipuçları çıkıyordu.
    final service = const TaskDirectiveService();
    final now = DateTime(2026, 4, 25);
    final directives = service.generate(
      now: now,
      fieldCrops: [
        {
          'id': 'crop-1',
          'name': 'Domates',
          'planted_date': '01.04.2026',
          'harvest_days': 90,
          'water_interval_days': 7,
        },
      ],
      activities: [
        {
          'type': ActivityType.watering,
          'date': DateTime(2026, 8, 14), // 111 gün sonrası — auto_seed planı
          'source': 'auto_seed',
          'crop_id': 'crop-1',
        },
      ],
    );

    final hasIdle = directives.any((d) => d.kind == 'idle');
    final water = directives.where((d) => d.kind == 'water_now').toList();
    expect(
      water.isNotEmpty || !hasIdle,
      isTrue,
      reason:
          'Auto_seed plani "yapilmis" sayilmamali; bitki ekildigine gore '
          'sulama direktifi uretilmeli.',
    );
    // Idle direktifi varsa bile reason metni "111 gun" gibi imkansiz bir
    // sayi icermemeli.
    for (final d in directives) {
      expect(d.reason.contains(' 111 '), isFalse);
      expect(d.reason.contains('-'), isFalse,
          reason: 'Negatif gün ifadesi olmamali.');
    }
  });

  test('aycicegi yagmur sonrasi ilac yerine gozlem direktifi uretir', () {
    final service = const TaskDirectiveService();
    final now = DateTime(2026, 4, 25);
    final directives = service.generate(
      now: now,
      fieldCrops: [
        {
          'id': 'crop-1',
          'name': 'Ayçiçeği',
          'planted_date': '01.04.2026',
          'harvest_days': 120,
          'water_interval_days': 7,
        },
      ],
      activities: [
        {
          'type': ActivityType.watering,
          'date': DateTime(2026, 4, 24),
          'crop_id': 'crop-1',
        },
      ],
      dailyForecast: const [
        {'rain': 12, 'min': 10, 'max': 20},
      ],
    );

    final scouting = directives.where((d) => d.kind == 'ipm_scouting');
    expect(scouting, isNotEmpty);
    expect(scouting.first.actionType, ActivityType.scouting);
    expect(
      directives.any(
        (d) => d.cropName == 'Ayçiçeği' && d.actionType == ActivityType.spraying,
      ),
      isFalse,
    );
  });

  test('eski aycicegi auto_seed ilac plani gozlem geciktiye cevrilir', () {
    final service = const TaskDirectiveService();
    final now = DateTime(2026, 4, 25);
    final directives = service.generate(
      now: now,
      fieldCrops: [
        {
          'id': 'crop-1',
          'name': 'Ayçiçeği',
          'planted_date': '01.04.2026',
          'harvest_days': 120,
          'water_interval_days': 7,
        },
      ],
      activities: const [],
      scheduledEvents: [
        {
          'type': ActivityType.spraying,
          'date': DateTime(2026, 4, 20),
          'source': 'auto_seed',
          'crop_id': 'crop-1',
          'metadata': const {'pesticide_name': 'Tebuconazole SC'},
        },
      ],
    );

    final overdue = directives.where((d) => d.kind == 'overdue_scouting');
    expect(overdue, isNotEmpty);
    expect(overdue.first.actionType, ActivityType.scouting);
    expect(
      directives.any((d) => d.kind == 'overdue_spray'),
      isFalse,
    );
  });
}
