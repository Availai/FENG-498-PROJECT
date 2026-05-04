import 'package:flutter_test/flutter_test.dart';

import 'package:feng_498/data/activity_types.dart';
import 'package:feng_498/data/crop_ipm_rules.dart';
import 'package:feng_498/services/guide_engine.dart' show AlertSeverity;
import 'package:feng_498/services/rules/crop_rule_set.dart';
import 'package:feng_498/services/rules/ipm_rule_runner.dart';
import 'package:feng_498/services/rules/recommendation.dart';

void main() {
  RuleEvaluationContext build({
    DateTime? plantedDate,
    List<ActivityRecord> activities = const [],
    DateTime? now,
  }) {
    return RuleEvaluationContext(
      fieldId: 'f1',
      crop: FieldCropSnapshot(
        id: 'c1',
        name: 'Ayçiçeği',
        plantedDate: plantedDate,
      ),
      recentActivities: activities,
      now: now ?? DateTime(2026, 6, 1),
    );
  }

  group('IpmRuleRunner — pencere kontrolü', () {
    test('plantedDate yok → boş döner', () {
      final ctx = build();
      expect(
        IpmRuleRunner.run(
          ctx: ctx,
          rules: SunflowerIpmRules.rules,
          windows: SunflowerIpmRules.scoutingWindows,
        ),
        isEmpty,
      );
    });

    test('aktif pencere dışındaki günde tetiklenmez', () {
      // Day 200 — hiçbir scouting penceresine düşmez (offsets: 14, 50, 75)
      final now = DateTime(2026, 6, 1);
      final ctx = build(
        plantedDate: now.subtract(const Duration(days: 200)),
        now: now,
      );
      expect(
        IpmRuleRunner.run(
          ctx: ctx,
          rules: SunflowerIpmRules.rules,
          windows: SunflowerIpmRules.scoutingWindows,
        ),
        isEmpty,
      );
    });

    test('son 7 gün içinde ilaçlama varsa kural bastırılır', () {
      final now = DateTime(2026, 6, 1);
      final ctx = build(
        plantedDate: now.subtract(const Duration(days: 14)),
        activities: [
          ActivityRecord(
            type: ActivityType.spraying,
            at: now.subtract(const Duration(days: 3)),
          ),
        ],
        now: now,
      );
      expect(
        IpmRuleRunner.run(
          ctx: ctx,
          rules: SunflowerIpmRules.rules,
          windows: SunflowerIpmRules.scoutingWindows,
        ),
        isEmpty,
      );
    });
  });

  group('IpmRuleRunner — senaryo A (gözlem yok)', () {
    test('day 14 → bozkurt/telkurtlari/mildiyö için scouting tavsiyesi', () {
      final now = DateTime(2026, 6, 1);
      final ctx = build(
        plantedDate: now.subtract(const Duration(days: 14)),
        now: now,
      );
      final out = IpmRuleRunner.run(
        ctx: ctx,
        rules: SunflowerIpmRules.rules,
        windows: SunflowerIpmRules.scoutingWindows,
      );
      // Pencere 0 → 3 zararlı/hastalık
      expect(out.length, 3);
      for (final r in out) {
        expect(r.gate, RecommendationGate.actionable);
        expect(r.command?.activityType, ActivityType.scouting);
        expect(r.ruleKey, endsWith('.scout'));
        expect(r.evidence, isNotEmpty);
        expect(r.sourceRefs, isNotEmpty);
      }
      final keys = out.map((r) => r.ruleKey).toSet();
      expect(
        keys,
        containsAll({
          'ipm.aycicegi.bozkurt.v1.scout',
          'ipm.aycicegi.telkurtlari.v1.scout',
          'ipm.aycicegi.mildiyo.v1.scout',
        }),
      );
    });
  });

  group('IpmRuleRunner — senaryo B (gözlem var, eşik altı)', () {
    test('son 3 gün içinde scouting + threshold flag yok → followup', () {
      final now = DateTime(2026, 6, 1);
      final ctx = build(
        plantedDate: now.subtract(const Duration(days: 14)),
        activities: [
          ActivityRecord(
            type: ActivityType.scouting,
            subtype: ActivitySubtype.pestObservation,
            at: now.subtract(const Duration(days: 1)),
          ),
        ],
        now: now,
      );
      final out = IpmRuleRunner.run(
        ctx: ctx,
        rules: SunflowerIpmRules.rules,
        windows: SunflowerIpmRules.scoutingWindows,
        extractMetadata: (_) => const {},
      );
      // Bozkurt + telkurtlari (Zararlı tipi) → followup; mildiyo (Hastalık)
      // → disease subtype scouting yok → senaryo A.
      final pestRecs = out
          .where((r) => r.ruleKey.contains('bozkurt') ||
              r.ruleKey.contains('telkurtlari'))
          .toList();
      for (final r in pestRecs) {
        expect(r.ruleKey, endsWith('.followup'));
        expect(r.gate, RecommendationGate.observeFirst);
        expect(r.severity, AlertSeverity.info);
      }
    });
  });

  group('IpmRuleRunner — senaryo C (eşik aşıldı)', () {
    test('threshold_exceeded=true → kimyasal kapısı açık, doz YOK', () {
      final now = DateTime(2026, 6, 1);
      final ctx = build(
        plantedDate: now.subtract(const Duration(days: 14)),
        activities: [
          ActivityRecord(
            type: ActivityType.scouting,
            subtype: ActivitySubtype.pestObservation,
            at: now.subtract(const Duration(days: 1)),
          ),
        ],
        now: now,
      );
      final out = IpmRuleRunner.run(
        ctx: ctx,
        rules: SunflowerIpmRules.rules,
        windows: SunflowerIpmRules.scoutingWindows,
        extractMetadata: (rec) => {'threshold_exceeded': true},
      );
      final chemicalRecs =
          out.where((r) => r.ruleKey.endsWith('.chemical')).toList();
      expect(chemicalRecs, isNotEmpty);
      for (final r in chemicalRecs) {
        expect(r.gate, RecommendationGate.actionable);
        expect(r.severity, AlertSeverity.critical);
        // Kimyasal tavsiyenin command'ı var ama miktar (doz) YOK — sadece
        // kategori ipucu metadata'da.
        expect(r.command, isNotNull);
        expect(r.command?.quantity, isNull);
        expect(
          r.command?.metadata[RecommendationMetadataKeys.productCategoryHint],
          isNotNull,
        );
        // Cascade: kimyasal scouting kuralına bağımlı
        expect(r.dependsOn, isNotEmpty);
        expect(r.dependsOn.first, endsWith('.scout'));
      }
    });
  });

  test('windows null → tüm kurallar her zaman değerlendirilir', () {
    final now = DateTime(2026, 6, 1);
    final ctx = build(
      plantedDate: now.subtract(const Duration(days: 200)),
      now: now,
    );
    final out = IpmRuleRunner.run(
      ctx: ctx,
      rules: SunflowerIpmRules.rules,
      windows: null,
    );
    expect(out.length, SunflowerIpmRules.rules.length);
  });
}
