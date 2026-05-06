import 'rule_condition.dart';

/// CLAUDE.md sec 14 — tek bir deterministik kural.
class Rule {
  final String id;
  final String? cropId;
  final String category;
  final int priority;
  final bool enabled;
  final List<RuleCondition> conditions;
  final RuleActionResult result;
  final String? explanation;
  final String? confidence;
  final List<RuleEvidence> evidence;

  const Rule({
    required this.id,
    required this.category,
    required this.priority,
    required this.enabled,
    required this.conditions,
    required this.result,
    this.cropId,
    this.explanation,
    this.confidence,
    this.evidence = const [],
  });

  factory Rule.fromJson(Map<String, dynamic> j) {
    final conditionsRaw = (j['conditions'] as List?) ?? const [];
    final evidenceRaw = (j['evidence'] as List?) ?? const [];
    return Rule(
      id: j['id'] as String? ?? '',
      cropId: j['crop_id'] as String?,
      category: j['category'] as String? ?? 'unknown',
      priority: (j['priority'] as num?)?.toInt() ?? 0,
      enabled: j['enabled'] as bool? ?? true,
      conditions: conditionsRaw
          .whereType<Map>()
          .map((c) => RuleCondition.fromJson(Map<String, dynamic>.from(c)))
          .toList(growable: false),
      result: j['result'] is Map
          ? RuleActionResult.fromJson(
              Map<String, dynamic>.from(j['result'] as Map))
          : const RuleActionResult.empty(),
      explanation: j['explanation'] as String?,
      confidence: j['confidence'] as String?,
      evidence: evidenceRaw
          .whereType<Map>()
          .map((e) => RuleEvidence.fromJson(Map<String, dynamic>.from(e)))
          .toList(growable: false),
    );
  }
}

class RuleActionResult {
  final String? riskLevel;
  final String? possibleProblemId;
  final List<String> recommendations;
  final bool requiresExpertConfirmation;
  final bool requiresBkuCheck;

  const RuleActionResult({
    required this.recommendations,
    required this.requiresExpertConfirmation,
    required this.requiresBkuCheck,
    this.riskLevel,
    this.possibleProblemId,
  });

  const RuleActionResult.empty()
      : riskLevel = null,
        possibleProblemId = null,
        recommendations = const [],
        requiresExpertConfirmation = false,
        requiresBkuCheck = false;

  factory RuleActionResult.fromJson(Map<String, dynamic> j) {
    final recsRaw = (j['recommendations'] as List?) ?? const [];
    return RuleActionResult(
      riskLevel: j['risk_level'] as String?,
      possibleProblemId: j['possible_problem_id'] as String?,
      recommendations:
          recsRaw.map((r) => r?.toString() ?? '').toList(growable: false),
      requiresExpertConfirmation:
          j['requires_expert_confirmation'] as bool? ?? false,
      requiresBkuCheck: j['requires_bku_check'] as bool? ?? false,
    );
  }
}

class RuleEvidence {
  final String sourceId;
  final int? page;
  final String? section;
  final String evidenceText;

  const RuleEvidence({
    required this.sourceId,
    required this.evidenceText,
    this.page,
    this.section,
  });

  factory RuleEvidence.fromJson(Map<String, dynamic> j) => RuleEvidence(
        sourceId: j['source_id'] as String? ?? '',
        page: (j['page'] as num?)?.toInt(),
        section: j['section'] as String?,
        evidenceText: j['evidence_text'] as String? ?? '',
      );
}
