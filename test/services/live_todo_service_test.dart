import 'package:flutter_test/flutter_test.dart';

import 'package:feng_498/data/activity_types.dart';
import 'package:feng_498/models/plant_condition.dart';
import 'package:feng_498/services/field_state_service.dart';
import 'package:feng_498/services/live_todo_service.dart';
import 'package:feng_498/services/rules/crop_rule_set.dart';
import 'package:feng_498/services/rules/recommendation.dart';
import 'package:feng_498/services/rules/sunflower_rules.dart';
import 'package:feng_498/services/task_directive_service.dart';
import 'package:feng_498/services/weather_soil_service.dart';

void main() {
  const service = LiveTodoService();
  const fieldId = 'field-1';
  const cropId = 'crop-1';

  RuleFieldStateSnapshot ruleFieldState({
    double weeklyWaterMm = 0,
    double weeklyWaterTargetMm = 35,
  }) =>
      RuleFieldStateSnapshot(
        areaDekar: 2,
        areaSqm: 2000,
        estimatedPlantCount: 9500,
        weeklyWaterMm: weeklyWaterMm,
        weeklyWaterLiters: weeklyWaterMm * 2000,
        weeklyWaterTargetMm: weeklyWaterTargetMm,
        seasonalWaterMm: 80,
        seasonalWaterLiters: 160000,
      );

  CropFieldState cropFieldState({
    double weeklyWaterMm = 0,
    double weeklyWaterTargetMm = 35,
  }) =>
      CropFieldState(
        cropId: cropId,
        cropName: 'Ayçiçeği',
        areaDekar: 2,
        areaSqm: 2000,
        estimatedPlantCount: 9500,
        weeklyWaterMm: weeklyWaterMm,
        weeklyWaterLiters: weeklyWaterMm * 2000,
        seasonalWaterMm: 80,
        seasonalWaterLiters: 160000,
        weeklyWaterTargetMm: weeklyWaterTargetMm,
        harvestedKg: 0,
        yieldKgPerDekar: 0,
      );

  LiveDecisionContext build({
    DateTime? now,
    DateTime? plantedDate,
    GrowthSnapshot? growth,
    List<ActivityRecord> activities = const [],
    List<PlantInstanceSnapshot> plants = const [],
    RuleEnvironmentSnapshot? environment,
    RuleFieldStateSnapshot? fieldState,
    CropFieldState? rawFieldState,
    HourlyForecast? hourly,
  }) {
    final t = now ?? DateTime(2026, 7, 15);
    final planted = plantedDate ?? DateTime(2026, 5, 1);
    return LiveDecisionContext(
      fieldId: fieldId,
      fieldCrops: [
        {
          'id': cropId,
          'name': 'Ayçiçeği',
          'planted_date': planted.toIso8601String(),
          'harvest_days': 120,
          'water_interval_days': 7,
        },
      ],
      activities: [
        for (final a in activities)
          {
            'type': a.type,
            'date': a.at,
            if (a.subtype != null) 'subtype': a.subtype,
            if (a.plantInstanceId != null)
              'plant_instance_id': a.plantInstanceId,
            if (a.quantity != null) 'quantity': a.quantity,
            'crop_id': cropId,
          },
      ],
      scheduledEvents: const [],
      growthStates: {
        if (growth != null) cropId: growth,
      },
      cropFieldStates: {
        cropId: rawFieldState ?? cropFieldState(),
      },
      fieldStates: {
        cropId: fieldState ?? ruleFieldState(),
      },
      activityRecords: activities,
      plantInstances: plants,
      ruleSets: const [SunflowerRules()],
      hourly: hourly,
      environment: environment,
      now: t,
    );
  }

  test('hasat tavsiyesi aynı ekindeki sulama/gübre işlerini bastırır', () {
    final recs = service.generate(build(
      now: DateTime(2026, 9, 1),
      plantedDate: DateTime(2026, 4, 20),
      growth: const GrowthSnapshot(
        stageKey: 'olgunlasma',
        stageProgress: 0.9,
        accumulatedGdd: 1750,
        waterDeficitMm: 35,
        nStressIdx: 0.4,
        diseasePressure: 0,
        yieldMultiplier: 0.9,
      ),
      environment: const RuleEnvironmentSnapshot(soilMoisture: 0.18),
    ));

    expect(
      recs.any((r) => r.command?.activityType == ActivityType.harvest),
      isTrue,
    );
    expect(
      recs.any((r) => r.command?.activityType == ActivityType.watering),
      isFalse,
    );
    expect(
      recs.any((r) => r.command?.activityType == ActivityType.fertilizing),
      isFalse,
    );
  });

  test('zararlı riski ilaç yerine gözlem komutu üretir', () {
    final recs = service.generate(build(
      growth: const GrowthSnapshot(
        stageKey: 'tomurcuklanma',
        stageProgress: 0.6,
        accumulatedGdd: 700,
        waterDeficitMm: 0,
        nStressIdx: 0,
        diseasePressure: 0,
        yieldMultiplier: 1,
      ),
      plants: const [
        PlantInstanceSnapshot(
          id: 'p1',
          cropId: cropId,
          healthStatus: 'healthy',
          conditionFlags: [PlantCondition.pestRisk],
        ),
      ],
    ));

    final pest = recs.firstWhere(
      (r) => r.ruleKey == 'sunflower.pest.helicoverpa.v1',
    );
    expect(pest.gate, RecommendationGate.observeFirst);
    expect(pest.command?.activityType, ActivityType.scouting);
    expect(pest.command?.subtype, ActivitySubtype.pestObservation);
    expect(pest.actionHint, isNot(contains('spinosad')));
  });

  test('24 saatlik yağış normal sulama direktifini bastırır', () {
    final now = DateTime(2026, 6, 1);
    final hourly = HourlyForecast(
      fetchedAt: now,
      slots: [
        for (var i = 0; i < 24; i++)
          HourlySlot(
            hour: now.add(Duration(hours: i)),
            tempC: 24,
            rainMm: i < 4 ? 2.5 : 0,
            humidity: 70,
          ),
      ],
    );

    final recs = service.generate(build(
      now: now,
      plantedDate: now.subtract(const Duration(days: 30)),
      fieldState: ruleFieldState(weeklyWaterMm: 30, weeklyWaterTargetMm: 35),
      rawFieldState: cropFieldState(weeklyWaterMm: 30, weeklyWaterTargetMm: 35),
      hourly: hourly,
      growth: const GrowthSnapshot(
        stageKey: 'vejetatif',
        stageProgress: 0.4,
        accumulatedGdd: 450,
        waterDeficitMm: 0,
        nStressIdx: 0,
        diseasePressure: 0,
        yieldMultiplier: 1,
      ),
    ));

    expect(
      recs.where((r) => r.command?.activityType == ActivityType.watering),
      isEmpty,
    );
  });

  test('her canlı ayçiçeği tavsiyesi kaynak ve kanıt taşır', () {
    final recs = service.generate(build(
      growth: const GrowthSnapshot(
        stageKey: 'ciceklenme',
        stageProgress: 0.5,
        accumulatedGdd: 1000,
        waterDeficitMm: 32,
        nStressIdx: 0,
        diseasePressure: 0,
        yieldMultiplier: 0.85,
      ),
      environment: const RuleEnvironmentSnapshot(
        soilMoisture: 0.18,
        source: 'test çevre',
      ),
    ));

    final sunflowerRules =
        recs.where((r) => r.ruleKey.startsWith('sunflower.'));
    expect(sunflowerRules, isNotEmpty);
    for (final rec in sunflowerRules) {
      expect(rec.sourceRefs, isNotEmpty, reason: rec.ruleKey);
      expect(rec.evidence, isNotEmpty, reason: rec.ruleKey);
    }
  });
}
