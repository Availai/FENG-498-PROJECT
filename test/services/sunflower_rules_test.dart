import 'package:flutter_test/flutter_test.dart';

import 'package:feng_498/data/activity_types.dart';
import 'package:feng_498/models/plant_condition.dart';
import 'package:feng_498/services/guide_engine.dart' show AlertSeverity;
import 'package:feng_498/services/rules/crop_rule_set.dart';
import 'package:feng_498/services/rules/sunflower_rules.dart';
import 'package:feng_498/services/task_directive_service.dart' show GrowthSnapshot;

void main() {
  final rules = const SunflowerRules();
  final fieldId = 'field-1';
  final cropId = 'crop-1';

  RuleEvaluationContext build({
    String cropName = 'Ayçiçeği',
    DateTime? plantedDate,
    GrowthSnapshot? growth,
    List<ActivityRecord> activities = const [],
    List<PlantInstanceSnapshot> plants = const [],
    DateTime? now,
  }) {
    return RuleEvaluationContext(
      fieldId: fieldId,
      crop: FieldCropSnapshot(
        id: cropId,
        name: cropName,
        plantedDate: plantedDate,
      ),
      growth: growth,
      recentActivities: activities,
      plantInstances: plants,
      now: now ?? DateTime(2026, 7, 15),
    );
  }

  group('matches', () {
    test('Türkçe ve ASCII varyantlarını yakalar', () {
      expect(rules.matches('Ayçiçeği'), isTrue);
      expect(rules.matches('AYCICEGI'), isTrue);
      expect(rules.matches('sunflower'), isTrue);
    });

    test('alakasız ürünleri reddeder', () {
      expect(rules.matches('Mısır'), isFalse);
      expect(rules.matches('Buğday'), isFalse);
    });
  });

  test('non-sunflower → boş liste', () {
    final out = rules.evaluate(build(cropName: 'Mısır'));
    expect(out, isEmpty);
  });

  group('emergence_crusting (#1)', () {
    test('sulama + 7 gün → uyarı; çapalama yapıldıysa düşer', () {
      final now = DateTime(2026, 5, 10);
      final ctx = build(
        plantedDate: now.subtract(const Duration(days: 7)),
        activities: [
          ActivityRecord(
            type: ActivityType.watering,
            at: now.subtract(const Duration(hours: 6)),
          ),
        ],
        now: now,
      );
      final out = rules.evaluate(ctx);
      expect(out.any((r) => r.ruleKey.startsWith('sunflower.emergence')),
          isTrue);

      // Çapalama eklendiğinde tetiklenmemeli
      final ctx2 = build(
        plantedDate: now.subtract(const Duration(days: 7)),
        activities: [
          ActivityRecord(
            type: ActivityType.watering,
            at: now.subtract(const Duration(hours: 6)),
          ),
          ActivityRecord(
            type: ActivityType.hoeing,
            at: now.subtract(const Duration(hours: 12)),
          ),
        ],
        now: now,
      );
      final out2 = rules.evaluate(ctx2);
      expect(out2.any((r) => r.ruleKey.startsWith('sunflower.emergence')),
          isFalse);
    });

    test('plantedDate yok → tetiklenmez', () {
      final out = rules.evaluate(build());
      expect(out.where((r) => r.ruleKey.startsWith('sunflower.emergence')),
          isEmpty);
    });
  });

  group('water_stress.flower (#4)', () {
    test('çiçeklenme + 32 mm açık → critical', () {
      final ctx = build(
        growth: const GrowthSnapshot(
          stageKey: 'ciceklenme',
          stageProgress: 0.5,
          accumulatedGdd: 950,
          waterDeficitMm: 32,
          nStressIdx: 0.1,
          diseasePressure: 0.0,
          yieldMultiplier: 0.85,
        ),
      );
      final hit = rules.evaluate(ctx).where(
          (r) => r.ruleKey == 'sunflower.water_stress.flower.v1');
      expect(hit, hasLength(1));
      expect(hit.first.severity, AlertSeverity.critical);
    });

    test('su açığı düşük + yakın zamanda sulama → tetiklenmez', () {
      final now = DateTime(2026, 7, 15);
      final ctx = build(
        now: now,
        growth: const GrowthSnapshot(
          stageKey: 'ciceklenme',
          stageProgress: 0.5,
          accumulatedGdd: 950,
          waterDeficitMm: 10,
          nStressIdx: 0.0,
          diseasePressure: 0.0,
          yieldMultiplier: 0.95,
        ),
        activities: [
          ActivityRecord(
            type: ActivityType.watering,
            at: now.subtract(const Duration(days: 2)),
          ),
        ],
      );
      expect(
        rules
            .evaluate(ctx)
            .where((r) => r.ruleKey == 'sunflower.water_stress.flower.v1'),
        isEmpty,
      );
    });

    test('clearOnActivities suluyu içerir', () {
      final ctx = build(
        growth: const GrowthSnapshot(
          stageKey: 'ciceklenme',
          stageProgress: 0.5,
          accumulatedGdd: 950,
          waterDeficitMm: 35,
          nStressIdx: 0.0,
          diseasePressure: 0.0,
          yieldMultiplier: 0.8,
        ),
      );
      final hit = rules
          .evaluate(ctx)
          .firstWhere(
              (r) => r.ruleKey == 'sunflower.water_stress.flower.v1');
      expect(hit.clearOnActivities.first.activityType,
          ActivityType.watering);
    });
  });

  group('water_stress.grain (#5)', () {
    test('dane dolumu + 28 mm → critical', () {
      final ctx = build(
        growth: const GrowthSnapshot(
          stageKey: 'meyve_dolumu',
          stageProgress: 0.4,
          accumulatedGdd: 1300,
          waterDeficitMm: 28,
          nStressIdx: 0.1,
          diseasePressure: 0.0,
          yieldMultiplier: 0.78,
        ),
      );
      final hit = rules.evaluate(ctx).where(
          (r) => r.ruleKey == 'sunflower.water_stress.grain.v1');
      expect(hit, hasLength(1));
    });
  });

  group('pest.helicoverpa (#11)', () {
    test('tomurcuk + pest_risk bayrağı → her bitki için ayrı tavsiye', () {
      final ctx = build(
        growth: const GrowthSnapshot(
          stageKey: 'tomurcuklanma',
          stageProgress: 0.6,
          accumulatedGdd: 700,
          waterDeficitMm: 5,
          nStressIdx: 0.0,
          diseasePressure: 0.2,
          yieldMultiplier: 1.0,
        ),
        plants: const [
          PlantInstanceSnapshot(
            id: 'p1',
            cropId: 'crop-1',
            healthStatus: 'healthy',
            conditionFlags: [PlantCondition.pestRisk],
          ),
          PlantInstanceSnapshot(
            id: 'p2',
            cropId: 'crop-1',
            healthStatus: 'healthy',
            conditionFlags: [PlantCondition.pestRisk],
          ),
        ],
      );
      final hits = rules
          .evaluate(ctx)
          .where((r) => r.ruleKey == 'sunflower.pest.helicoverpa.v1')
          .toList();
      expect(hits, hasLength(2));
      expect(hits.map((r) => r.target.plantInstanceId).toSet(),
          {'p1', 'p2'});
    });

    test('son 3 gün ilaçlama yapıldıysa düşer', () {
      final now = DateTime(2026, 7, 10);
      final ctx = build(
        now: now,
        growth: const GrowthSnapshot(
          stageKey: 'tomurcuklanma',
          stageProgress: 0.6,
          accumulatedGdd: 700,
          waterDeficitMm: 5,
          nStressIdx: 0.0,
          diseasePressure: 0.2,
          yieldMultiplier: 1.0,
        ),
        activities: [
          ActivityRecord(
            type: ActivityType.spraying,
            at: now.subtract(const Duration(days: 3)),
          ),
        ],
        plants: const [
          PlantInstanceSnapshot(
            id: 'p1',
            cropId: 'crop-1',
            healthStatus: 'healthy',
            conditionFlags: [PlantCondition.pestRisk],
          ),
        ],
      );
      expect(
        rules
            .evaluate(ctx)
            .where((r) => r.ruleKey == 'sunflower.pest.helicoverpa.v1'),
        isEmpty,
      );
    });
  });

  group('harvest.ready (#13)', () {
    test('GDD 1700+ → critical', () {
      final ctx = build(
        growth: const GrowthSnapshot(
          stageKey: 'olgunlasma',
          stageProgress: 0.9,
          accumulatedGdd: 1750,
          waterDeficitMm: 0,
          nStressIdx: 0.0,
          diseasePressure: 0.0,
          yieldMultiplier: 0.95,
        ),
      );
      final hit = rules
          .evaluate(ctx)
          .firstWhere((r) => r.ruleKey == 'sunflower.harvest.ready.v1');
      expect(hit.severity, AlertSeverity.critical);
    });

    test('hasat aktivitesi son 7 günde varsa düşer', () {
      final now = DateTime(2026, 9, 1);
      final ctx = build(
        now: now,
        growth: const GrowthSnapshot(
          stageKey: 'olgunlasma',
          stageProgress: 0.9,
          accumulatedGdd: 1750,
          waterDeficitMm: 0,
          nStressIdx: 0.0,
          diseasePressure: 0.0,
          yieldMultiplier: 0.95,
        ),
        activities: [
          ActivityRecord(
            type: ActivityType.harvest,
            at: now.subtract(const Duration(days: 2)),
          ),
        ],
      );
      expect(
        rules
            .evaluate(ctx)
            .where((r) => r.ruleKey == 'sunflower.harvest.ready.v1'),
        isEmpty,
      );
    });
  });
}
