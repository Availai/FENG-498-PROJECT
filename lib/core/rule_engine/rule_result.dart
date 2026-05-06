import 'rule.dart';

/// Bir kural eşleşmesinin UI'a sunulan sonucu (CLAUDE.md sec 22).
class RuleMatch {
  final Rule rule;
  final RuleActionResult result;
  final List<String> matchedConditions;

  const RuleMatch({
    required this.rule,
    required this.result,
    required this.matchedConditions,
  });

  String? get explanation => rule.explanation;
  String get id => rule.id;
  int get priority => rule.priority;
  String get category => rule.category;
  String? get cropId => rule.cropId;
  String? get confidence => rule.confidence;
  List<RuleEvidence> get evidence => rule.evidence;
}
