import 'package:feng_498/services/guide_engine.dart' show AlertSeverity;
import 'package:feng_498/services/rules/recommendation.dart';
import 'package:feng_498/services/rules/recommendation_triage.dart';
import 'package:flutter_test/flutter_test.dart';

Recommendation _rec({
  required String key,
  required AlertSeverity severity,
}) {
  return Recommendation(
    ruleKey: key,
    severity: severity,
    target: RecommendationTarget.field('field-1'),
    title: key,
    reasonText: 'test',
    actionHint: 'test',
    gate: RecommendationGate.actionable,
  );
}

void main() {
  group('RecommendationTriage.apply', () {
    test('boş liste → boş sonuç', () {
      final result = RecommendationTriage.apply(const []);
      expect(result.visible, isEmpty);
      expect(result.hidden, 0);
      expect(result.hasHidden, isFalse);
    });

    test('default policy: 3 critical + 5 warning + 3 info uygular', () {
      final input = [
        for (int i = 0; i < 5; i++)
          _rec(key: 'crit.$i', severity: AlertSeverity.critical),
        for (int i = 0; i < 8; i++)
          _rec(key: 'warn.$i', severity: AlertSeverity.warning),
        for (int i = 0; i < 6; i++)
          _rec(key: 'info.$i', severity: AlertSeverity.info),
      ];
      final result = RecommendationTriage.apply(input);
      final critCount =
          result.visible.where((r) => r.severity == AlertSeverity.critical).length;
      final warnCount =
          result.visible.where((r) => r.severity == AlertSeverity.warning).length;
      final infoCount =
          result.visible.where((r) => r.severity == AlertSeverity.info).length;
      expect(critCount, 3);
      expect(warnCount, 5);
      expect(infoCount, 3);
      expect(result.visible.length, 11);
      expect(result.hidden, 19 - 11);
    });

    test('hardCap aşılmaz', () {
      final input = [
        for (int i = 0; i < 30; i++)
          _rec(key: 'crit.$i', severity: AlertSeverity.critical),
      ];
      // Default policy hardCap=12, maxCritical=3 → 3 görünür
      final result = RecommendationTriage.apply(input);
      expect(result.visible.length, 3);
      expect(result.hidden, 27);
    });

    test('compactPolicy 5 maks ile çalışır', () {
      final input = [
        for (int i = 0; i < 5; i++)
          _rec(key: 'warn.$i', severity: AlertSeverity.warning),
        for (int i = 0; i < 5; i++)
          _rec(key: 'info.$i', severity: AlertSeverity.info),
      ];
      final result = RecommendationTriage.apply(
        input,
        policy: RecommendationTriage.compactPolicy,
      );
      expect(result.visible.length, 3); // 2 warn + 1 info
      expect(result.hidden, 7);
    });

    test('expandedPolicy 20 maks ile çalışır', () {
      final input = [
        for (int i = 0; i < 8; i++)
          _rec(key: 'crit.$i', severity: AlertSeverity.critical),
        for (int i = 0; i < 15; i++)
          _rec(key: 'warn.$i', severity: AlertSeverity.warning),
        for (int i = 0; i < 10; i++)
          _rec(key: 'info.$i', severity: AlertSeverity.info),
      ];
      final result = RecommendationTriage.apply(
        input,
        policy: RecommendationTriage.expandedPolicy,
      );
      expect(result.visible.length, 20); // 5 + 10 + 5
      expect(result.hidden, 33 - 20);
    });

    test('sıralama korunur — giriş sıralı ise çıktı da sıralı', () {
      // generate() çıktısı zaten sıralı (severity → gate → ...).
      // Triage yalnız kırpar; ilişkileri değiştirmez.
      final input = [
        _rec(key: 'crit.0', severity: AlertSeverity.critical),
        _rec(key: 'warn.0', severity: AlertSeverity.warning),
        _rec(key: 'crit.1', severity: AlertSeverity.critical),
        _rec(key: 'info.0', severity: AlertSeverity.info),
        _rec(key: 'warn.1', severity: AlertSeverity.warning),
      ];
      final result = RecommendationTriage.apply(input);
      expect(result.visible.map((r) => r.ruleKey).toList(),
          ['crit.0', 'warn.0', 'crit.1', 'info.0', 'warn.1']);
      expect(result.hidden, 0);
    });

    test('hasHidden bayrağı doğru ayarlanır', () {
      final none = RecommendationTriage.apply([
        _rec(key: 'crit.0', severity: AlertSeverity.critical),
      ]);
      expect(none.hasHidden, isFalse);

      final some = RecommendationTriage.apply([
        for (int i = 0; i < 10; i++)
          _rec(key: 'crit.$i', severity: AlertSeverity.critical),
      ]);
      expect(some.hasHidden, isTrue);
    });
  });
}
