/// CLAUDE.md sec 14 — desteklenen operatörler.
///
/// Yeni operatör eklenirse:
///   1) Bu dosya güncellenir.
///   2) backend/rule_engine.py paralel güncellenir.
///   3) test_cases eklenir.
///   4) Eski rule_pack'lerin kırılmadığı doğrulanır.
library;

enum RuleOperator {
  equals,
  notEquals,
  greaterThan,
  lessThan,
  greaterOrEqual,
  lessOrEqual,
  between,
  contains,
  isIn,
  notIn,
  exists,
  missing,
}

class RuleOperatorParse {
  static const _map = <String, RuleOperator>{
    'equals': RuleOperator.equals,
    'not_equals': RuleOperator.notEquals,
    'greater_than': RuleOperator.greaterThan,
    'less_than': RuleOperator.lessThan,
    'greater_or_equal': RuleOperator.greaterOrEqual,
    'less_or_equal': RuleOperator.lessOrEqual,
    'between': RuleOperator.between,
    'contains': RuleOperator.contains,
    'in': RuleOperator.isIn,
    'not_in': RuleOperator.notIn,
    'exists': RuleOperator.exists,
    'missing': RuleOperator.missing,
  };

  static RuleOperator? tryParse(String raw) => _map[raw];
}

class Operators {
  /// Tek bir koşulu deterministik biçimde değerlendir.
  ///
  /// Bilinmeyen operatör veya tip uyuşmazlığı `false` döner — kural
  /// pasif kabul edilir. Bunu hata gibi atmıyoruz çünkü farklı facts
  /// eksik alanlara sahip olabilir; missing/exists kontrolü bunu
  /// açıkça karşılar.
  static bool evaluate({
    required RuleOperator op,
    required Object? factValue,
    required Object? conditionValue,
  }) {
    switch (op) {
      case RuleOperator.exists:
        return factValue != null;
      case RuleOperator.missing:
        return factValue == null;
      case RuleOperator.equals:
        return factValue == conditionValue;
      case RuleOperator.notEquals:
        return factValue != conditionValue;
      case RuleOperator.greaterThan:
        return _asNum(factValue) != null &&
            _asNum(conditionValue) != null &&
            _asNum(factValue)! > _asNum(conditionValue)!;
      case RuleOperator.lessThan:
        return _asNum(factValue) != null &&
            _asNum(conditionValue) != null &&
            _asNum(factValue)! < _asNum(conditionValue)!;
      case RuleOperator.greaterOrEqual:
        return _asNum(factValue) != null &&
            _asNum(conditionValue) != null &&
            _asNum(factValue)! >= _asNum(conditionValue)!;
      case RuleOperator.lessOrEqual:
        return _asNum(factValue) != null &&
            _asNum(conditionValue) != null &&
            _asNum(factValue)! <= _asNum(conditionValue)!;
      case RuleOperator.between:
        if (conditionValue is! List || conditionValue.length != 2) return false;
        final v = _asNum(factValue);
        final lo = _asNum(conditionValue[0]);
        final hi = _asNum(conditionValue[1]);
        if (v == null || lo == null || hi == null) return false;
        return v >= lo && v <= hi;
      case RuleOperator.contains:
        if (factValue is List) return factValue.contains(conditionValue);
        if (factValue is String && conditionValue is String) {
          return factValue.contains(conditionValue);
        }
        return false;
      case RuleOperator.isIn:
        if (conditionValue is! List) return false;
        return conditionValue.contains(factValue);
      case RuleOperator.notIn:
        if (conditionValue is! List) return false;
        return !conditionValue.contains(factValue);
    }
  }

  static num? _asNum(Object? v) {
    if (v is num) return v;
    if (v is bool) return v ? 1 : 0;
    if (v is String) return num.tryParse(v);
    return null;
  }
}
