import 'package:flutter_test/flutter_test.dart';

import 'package:feng_498/data/activity_types.dart';
import 'package:feng_498/services/guide_engine.dart' show AlertSeverity;
import 'package:feng_498/services/rules/recommendation.dart';

Recommendation _rec({
  required String ruleKey,
  required String? category,
  AlertSeverity severity = AlertSeverity.info,
}) {
  return Recommendation(
    ruleKey: ruleKey,
    severity: severity,
    target: RecommendationTarget(
      fieldId: 'field-1',
      scope: ActivityScope.field,
    ),
    title: 'X',
    reasonText: 'r',
    actionHint: 'a',
    category: category,
  );
}

void main() {
  group('Recommendation.isInformational', () {
    test('suitability → bilgi notu', () {
      expect(
          _rec(ruleKey: 'r1', category: 'suitability').isInformational, isTrue);
    });

    test('pre_planting → bilgi notu', () {
      expect(_rec(ruleKey: 'r1', category: 'pre_planting').isInformational,
          isTrue);
    });

    test('soil_analysis → bilgi notu', () {
      expect(_rec(ruleKey: 'r1', category: 'soil_analysis').isInformational,
          isTrue);
    });

    test('disease_risk → aksiyon kanalı', () {
      expect(_rec(ruleKey: 'r1', category: 'disease_risk').isInformational,
          isFalse);
    });

    test('irrigation → aksiyon kanalı', () {
      expect(
          _rec(ruleKey: 'r1', category: 'irrigation').isInformational, isFalse);
    });

    test('category null → aksiyon kanalı (geri uyumluluk)', () {
      expect(_rec(ruleKey: 'r1', category: null).isInformational, isFalse);
    });
  });

  group('RecommendationChannels.split', () {
    test('boş liste → boş kanallar', () {
      final ch = RecommendationChannels.split(const <Recommendation>[]);
      expect(ch.actionable, isEmpty);
      expect(ch.informational, isEmpty);
    });

    test('kategorilere göre ayırır, sıra korunur', () {
      final input = [
        _rec(ruleKey: 'r1', category: 'irrigation'),
        _rec(ruleKey: 'r2', category: 'suitability'),
        _rec(ruleKey: 'r3', category: 'disease_risk'),
        _rec(ruleKey: 'r4', category: 'pre_planting'),
        _rec(ruleKey: 'r5', category: 'soil_analysis'),
        _rec(ruleKey: 'r6', category: null),
      ];
      final ch = RecommendationChannels.split(input);
      expect(ch.actionable.map((r) => r.ruleKey).toList(), ['r1', 'r3', 'r6']);
      expect(
          ch.informational.map((r) => r.ruleKey).toList(), ['r2', 'r4', 'r5']);
    });

    test('aksiyon ve bilgi kategorilerinin tamamı toplamı korunur', () {
      final input = [
        _rec(ruleKey: 'r1', category: 'fertilization'),
        _rec(ruleKey: 'r2', category: 'suitability'),
        _rec(ruleKey: 'r3', category: 'harvest'),
        _rec(ruleKey: 'r4', category: 'pre_planting'),
      ];
      final ch = RecommendationChannels.split(input);
      expect(ch.actionable.length + ch.informational.length, input.length);
    });
  });
}
