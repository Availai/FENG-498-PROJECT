import 'operators.dart';

/// CLAUDE.md sec 14 — tek bir kural koşulu.
class RuleCondition {
  final String field;
  final RuleOperator operator;
  final Object? value;

  const RuleCondition({
    required this.field,
    required this.operator,
    this.value,
  });

  factory RuleCondition.fromJson(Map<String, dynamic> j) {
    final opRaw = j['operator'] as String? ?? 'equals';
    final op = RuleOperatorParse.tryParse(opRaw) ?? RuleOperator.equals;
    return RuleCondition(
      field: j['field'] as String? ?? '',
      operator: op,
      value: j['value'],
    );
  }

  bool evaluate(Map<String, Object?> facts) {
    return Operators.evaluate(
      op: operator,
      factValue: facts[field],
      conditionValue: value,
    );
  }
}
