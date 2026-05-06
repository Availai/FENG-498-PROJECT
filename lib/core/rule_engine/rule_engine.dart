import 'rule.dart';
import 'rule_result.dart';

/// CLAUDE.md sec 22 — saf fonksiyon kural motoru.
///
/// Aynı facts + aynı kurallar her zaman aynı sıralı sonucu üretir.
/// UI içinde kural değerlendirme mantığı yazılmaz; bu sınıf çağrılır.
class RuleEngine {
  const RuleEngine();

  /// Verilen facts + rules için eşleşen kuralları öncelik sırasıyla döner.
  ///
  /// - `enabled: false` kurallar atlanır.
  /// - Tüm `conditions` true olmayan kurallar atlanır.
  /// - Aynı priority'de olan kurallar id'ye göre stable sıralanır.
  List<RuleMatch> evaluate({
    required Map<String, Object?> facts,
    required Iterable<Rule> rules,
  }) {
    final matched = <RuleMatch>[];
    for (final rule in rules) {
      if (!rule.enabled) continue;
      if (rule.conditions.isEmpty) continue;
      final matchedConditions = <String>[];
      var allOk = true;
      for (final c in rule.conditions) {
        if (c.evaluate(facts)) {
          matchedConditions.add(_describe(c.field, facts[c.field]));
        } else {
          allOk = false;
          break;
        }
      }
      if (!allOk) continue;
      matched.add(RuleMatch(
        rule: rule,
        result: rule.result,
        matchedConditions: matchedConditions,
      ));
    }
    matched.sort((a, b) {
      final byPrio = b.priority.compareTo(a.priority);
      if (byPrio != 0) return byPrio;
      return a.id.compareTo(b.id);
    });
    return List.unmodifiable(matched);
  }

  static String _describe(String field, Object? v) {
    if (v == null) return field;
    return '$field=$v';
  }
}
