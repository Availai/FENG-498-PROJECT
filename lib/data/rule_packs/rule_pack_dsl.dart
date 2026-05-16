import '../../core/rule_engine/operators.dart';
import '../../core/rule_engine/rule.dart';
import '../../core/rule_engine/rule_condition.dart';

/// Rule pack yazımı için kısa, okunabilir DSL. Tek bir kural genellikle
/// 5-10 satır olur — 200-300 kuralı tek dosyada okunaklı tutmak için
/// bu helper'lar zorunlu, "magic" değil.
///
/// Kullanım:
/// ```dart
/// rule(
///   id: 'rule.sunflower.suitability.ph_optimal',
///   category: 'suitability',
///   priority: 60,
///   when: [eq(FactKeys.cropId, 'crop.sunflower'), between(FactKeys.soilPh, 6.0, 7.5)],
///   recs: ['Toprak pH değeri ayçiçeği için uygun aralıkta.'],
///   confidence: 'medium',
/// );
/// ```

// ─── Condition helper'ları ────────────────────────────────────────────
RuleCondition eq(String field, Object? value) =>
    RuleCondition(field: field, operator: RuleOperator.equals, value: value);

RuleCondition neq(String field, Object? value) =>
    RuleCondition(field: field, operator: RuleOperator.notEquals, value: value);

RuleCondition gt(String field, num value) =>
    RuleCondition(field: field, operator: RuleOperator.greaterThan, value: value);

RuleCondition lt(String field, num value) =>
    RuleCondition(field: field, operator: RuleOperator.lessThan, value: value);

RuleCondition gte(String field, num value) => RuleCondition(
    field: field, operator: RuleOperator.greaterOrEqual, value: value);

RuleCondition lte(String field, num value) => RuleCondition(
    field: field, operator: RuleOperator.lessOrEqual, value: value);

RuleCondition between(String field, num lo, num hi) =>
    RuleCondition(field: field, operator: RuleOperator.between, value: [lo, hi]);

RuleCondition isIn(String field, List<Object> values) =>
    RuleCondition(field: field, operator: RuleOperator.isIn, value: values);

RuleCondition notIn(String field, List<Object> values) =>
    RuleCondition(field: field, operator: RuleOperator.notIn, value: values);

RuleCondition exists(String field) =>
    RuleCondition(field: field, operator: RuleOperator.exists);

RuleCondition missing(String field) =>
    RuleCondition(field: field, operator: RuleOperator.missing);

RuleCondition has(String field, Object value) =>
    RuleCondition(field: field, operator: RuleOperator.contains, value: value);

// ─── Rule builder ─────────────────────────────────────────────────────
/// Tek bir deterministik kural. `recs` Türkçe tek-satır eylem cümleleri.
///
/// - `risk`: 'high'|'medium'|'low'|null (UI rozeti için)
/// - `expert`: hastalık/zararlı tanısı uzman onayı gerektiriyorsa true
/// - `bku`: kimyasal mücadele önerisi varsa true (CLAUDE.md sec 17)
/// - `confidence`: 'high'|'medium'|'low' — evidence güçlü değilse 'low'
/// - `evidence`: SourceIds + pendingEvidence helper'ı ile doldurulur
Rule rule({
  required String id,
  required String category,
  int priority = 50,
  required List<RuleCondition> when,
  String? cropId,
  String? risk,
  String? problemId,
  required List<String> recs,
  bool expert = false,
  bool bku = false,
  String? explain,
  String confidence = 'low',
  List<RuleEvidence> evidence = const [],
  bool enabled = true,
}) {
  return Rule(
    id: id,
    cropId: cropId,
    category: category,
    priority: priority,
    enabled: enabled,
    conditions: when,
    result: RuleActionResult(
      riskLevel: risk,
      possibleProblemId: problemId,
      recommendations: recs,
      requiresExpertConfirmation: expert,
      requiresBkuCheck: bku,
    ),
    explanation: explain,
    confidence: confidence,
    evidence: evidence,
  );
}

/// Bir kuralın varyasyonlarını üretir (örn. her büyüme evresi için tekrar).
/// `id` template'inde `{0}` yerine her variant değeri konur.
List<Rule> variants({
  required String idTemplate,
  required String category,
  required List<List<Object>> variantsList, // her satır: [variantId, conditions..., recs..]
  required Rule Function(Map<String, Object> ctx) build,
}) {
  return variantsList.map((v) => build({'id': v[0], 'extra': v})).toList();
}

// ─── Rule kategorileri (CLAUDE.md sec 14) ─────────────────────────────
class RuleCategories {
  RuleCategories._();
  static const suitability = 'suitability';
  static const soilAnalysis = 'soil_analysis';
  static const prePlanting = 'pre_planting';
  static const sowingOrPlanting = 'sowing_or_planting';
  static const fertilization = 'fertilization';
  static const irrigation = 'irrigation';
  static const diseaseRisk = 'disease_risk';
  static const pestRisk = 'pest_risk';
  static const weedManagement = 'weed_management';
  static const harvest = 'harvest';
  static const weatherWarning = 'weather_warning';
  static const taskGeneration = 'task_generation';
  static const safetyWarning = 'safety_warning';
  // Tarlam'a özel: bitkinin biyolojik unique özelliği (allelopati, fototropizm)
  static const cropUnique = 'crop_unique';
}
