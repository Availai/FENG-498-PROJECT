import 'package:flutter_test/flutter_test.dart';

import 'package:feng_498/data/activity_types.dart';
import 'package:feng_498/services/guide_engine.dart' show AlertSeverity;
import 'package:feng_498/services/rules/crop_rule_set.dart';
import 'package:feng_498/services/rules/recommendation.dart';
import 'package:feng_498/services/rules/wheat_rules.dart';
import 'package:feng_498/services/task_directive_service.dart'
    show GrowthSnapshot;

void main() {
  final rules = const WheatRules();
  const fieldId = 'f1';
  const cropId = 'c1';

  RuleEvaluationContext build({
    String cropName = 'Buğday',
    DateTime? plantedDate,
    GrowthSnapshot? growth,
    List<ActivityRecord> activities = const [],
    RuleEnvironmentSnapshot? environment,
    RuleFieldStateSnapshot? fieldState,
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
      environment: environment,
      fieldState: fieldState,
      now: now ?? DateTime(2026, 5, 1),
    );
  }

  group('matches', () {
    test('Türkçe + ASCII varyantları yakalar', () {
      expect(rules.matches('Buğday'), isTrue);
      expect(rules.matches('BUGDAY'), isTrue);
      expect(rules.matches('wheat'), isTrue);
      expect(rules.matches('Durum buğday'), isTrue);
    });
    test('alakasız ürünleri reddeder', () {
      expect(rules.matches('Ayçiçeği'), isFalse);
      expect(rules.matches('Mısır'), isFalse);
    });
  });

  test('non-wheat → boş liste', () {
    final out = rules.evaluate(build(cropName: 'Mısır'));
    expect(out, isEmpty);
  });

  group('emergence', () {
    test('toprak nemi yüksek + hoeing yok → uyarı', () {
      final now = DateTime(2026, 11, 5);
      final ctx = build(
        plantedDate: now.subtract(const Duration(days: 10)),
        environment: const RuleEnvironmentSnapshot(soilMoisture: 0.55),
        now: now,
      );
      final hits = rules
          .evaluate(ctx)
          .where((r) => r.ruleKey == 'wheat.emergence.crusting.v1');
      expect(hits, hasLength(1));
      expect(hits.first.severity, AlertSeverity.warning);
    });

    test('hoeing yapıldıysa düşer', () {
      final now = DateTime(2026, 11, 5);
      final ctx = build(
        plantedDate: now.subtract(const Duration(days: 10)),
        environment: const RuleEnvironmentSnapshot(soilMoisture: 0.55),
        activities: [
          ActivityRecord(
            type: ActivityType.hoeing,
            at: now.subtract(const Duration(days: 2)),
          ),
        ],
        now: now,
      );
      expect(
        rules
            .evaluate(ctx)
            .where((r) => r.ruleKey == 'wheat.emergence.crusting.v1'),
        isEmpty,
      );
    });
  });

  group('tillering nitrogen', () {
    test('vejetatif + N stresi 0.4 → critical değil ama warning', () {
      final ctx = build(
        growth: const GrowthSnapshot(
          stageKey: 'kardeslenme',
          stageProgress: 0.5,
          accumulatedGdd: 400,
          waterDeficitMm: 0,
          nStressIdx: 0.40,
          diseasePressure: 0,
          yieldMultiplier: 0.9,
        ),
      );
      final hit = rules
          .evaluate(ctx)
          .firstWhere((r) => r.ruleKey == 'wheat.tillering.nitrogen.v1');
      expect(hit.severity, AlertSeverity.warning);
      expect(hit.command?.activityType, ActivityType.fertilizing);
    });

    test('son 14 günde gübreleme varsa düşer', () {
      final now = DateTime(2026, 4, 1);
      final ctx = build(
        now: now,
        growth: const GrowthSnapshot(
          stageKey: 'kardeslenme',
          stageProgress: 0.5,
          accumulatedGdd: 400,
          waterDeficitMm: 0,
          nStressIdx: 0.40,
          diseasePressure: 0,
          yieldMultiplier: 0.9,
        ),
        activities: [
          ActivityRecord(
            type: ActivityType.fertilizing,
            at: now.subtract(const Duration(days: 5)),
          ),
        ],
      );
      expect(
        rules
            .evaluate(ctx)
            .where((r) => r.ruleKey == 'wheat.tillering.nitrogen.v1'),
        isEmpty,
      );
    });
  });

  group('stem elongation water', () {
    test('su açığı 30 mm + sapakalkma → critical', () {
      final ctx = build(
        growth: const GrowthSnapshot(
          stageKey: 'sapakalkma',
          stageProgress: 0.5,
          accumulatedGdd: 800,
          waterDeficitMm: 32,
          nStressIdx: 0,
          diseasePressure: 0,
          yieldMultiplier: 0.85,
        ),
      );
      final hit = rules
          .evaluate(ctx)
          .firstWhere((r) => r.ruleKey == 'wheat.stem_elongation.water.v1');
      expect(hit.severity, AlertSeverity.critical);
      expect(hit.command?.activityType, ActivityType.watering);
    });
  });

  group('rust scouting', () {
    test('yüksek nem + hastalık baskısı → observeFirst', () {
      final ctx = build(
        growth: const GrowthSnapshot(
          stageKey: 'baslanma',
          stageProgress: 0.5,
          accumulatedGdd: 1100,
          waterDeficitMm: 0,
          nStressIdx: 0,
          diseasePressure: 0.45,
          yieldMultiplier: 0.95,
        ),
        environment: const RuleEnvironmentSnapshot(humidityPct: 78),
      );
      final hit = rules
          .evaluate(ctx)
          .firstWhere((r) => r.ruleKey == 'wheat.disease.rust_scouting.v1');
      expect(hit.gate, RecommendationGate.observeFirst);
      expect(hit.command?.subtype, ActivitySubtype.diseaseObservation);
    });

    test('son 5 gün içinde gözlem varsa düşer', () {
      final now = DateTime(2026, 5, 1);
      final ctx = build(
        now: now,
        growth: const GrowthSnapshot(
          stageKey: 'baslanma',
          stageProgress: 0.5,
          accumulatedGdd: 1100,
          waterDeficitMm: 0,
          nStressIdx: 0,
          diseasePressure: 0.45,
          yieldMultiplier: 0.95,
        ),
        environment: const RuleEnvironmentSnapshot(humidityPct: 78),
        activities: [
          ActivityRecord(
            type: ActivityType.scouting,
            subtype: ActivitySubtype.diseaseObservation,
            at: now.subtract(const Duration(days: 2)),
          ),
        ],
      );
      expect(
        rules
            .evaluate(ctx)
            .where((r) => r.ruleKey == 'wheat.disease.rust_scouting.v1'),
        isEmpty,
      );
    });
  });

  group('harvest ready', () {
    test('olgunlasma + 7 gün hasat yok → critical', () {
      final ctx = build(
        growth: const GrowthSnapshot(
          stageKey: 'olgunlasma',
          stageProgress: 0.95,
          accumulatedGdd: 2200,
          waterDeficitMm: 0,
          nStressIdx: 0,
          diseasePressure: 0,
          yieldMultiplier: 1.0,
        ),
      );
      final hit = rules
          .evaluate(ctx)
          .firstWhere((r) => r.ruleKey == 'wheat.harvest.ready.v1');
      expect(hit.severity, AlertSeverity.critical);
    });
  });

  test('üretilen her buğday tavsiyesinde kaynak referansı + evidence var', () {
    final scenarios = [
      build(
        plantedDate: DateTime(2026, 11, 1),
        environment: const RuleEnvironmentSnapshot(soilMoisture: 0.55),
        now: DateTime(2026, 11, 10),
      ),
      build(
        growth: const GrowthSnapshot(
          stageKey: 'kardeslenme',
          stageProgress: 0.5,
          accumulatedGdd: 400,
          waterDeficitMm: 0,
          nStressIdx: 0.40,
          diseasePressure: 0,
          yieldMultiplier: 0.9,
        ),
      ),
      build(
        growth: const GrowthSnapshot(
          stageKey: 'sapakalkma',
          stageProgress: 0.5,
          accumulatedGdd: 800,
          waterDeficitMm: 32,
          nStressIdx: 0,
          diseasePressure: 0,
          yieldMultiplier: 0.85,
        ),
      ),
      build(
        growth: const GrowthSnapshot(
          stageKey: 'baslanma',
          stageProgress: 0.5,
          accumulatedGdd: 1100,
          waterDeficitMm: 0,
          nStressIdx: 0,
          diseasePressure: 0.45,
          yieldMultiplier: 0.95,
        ),
        environment: const RuleEnvironmentSnapshot(humidityPct: 78),
      ),
      build(
        growth: const GrowthSnapshot(
          stageKey: 'olgunlasma',
          stageProgress: 0.95,
          accumulatedGdd: 2200,
          waterDeficitMm: 0,
          nStressIdx: 0,
          diseasePressure: 0,
          yieldMultiplier: 1.0,
        ),
      ),
    ];
    final allRecs = scenarios.expand(rules.evaluate).toList();
    expect(allRecs, isNotEmpty);
    for (final rec in allRecs) {
      expect(rec.sourceRefs, isNotEmpty, reason: rec.ruleKey);
      expect(rec.evidence, isNotEmpty, reason: rec.ruleKey);
      expect(rec.command, isNotNull, reason: rec.ruleKey);
    }
  });
}
