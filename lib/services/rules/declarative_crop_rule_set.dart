import '../../core/rule_engine/declarative_pack_runner.dart';
import '../../core/rule_engine/rule.dart';
import '../../data/rule_packs/crop_registry.dart';
import 'crop_rule_set.dart';
import 'recommendation.dart';

/// Pack-driven `CropRuleSet` — yeni ürünler için boilerplate'siz adapter.
///
/// Mevcut elle-yazılı kural setleri (`SunflowerRules` gibi) `CropRuleSet`'i
/// doğrudan extend ederek özel Dart fonksiyonları çalıştırırken,
/// **yeni ürünler** çoğunlukla bu sınıfı kullanır — `CropDefinition` ve
/// pack fonksiyonu yeterli.
///
/// ```dart
/// // app_providers.dart içinde:
/// DeclarativeCropRuleSet(
///   definition: CropRegistry.corn,
///   packBuilder: CornRulePack.all,
/// ),
/// ```
///
/// `CropRuleSet.matches()` aliases'tan otomatik çalışır; fact override
/// `crop.stableId` ile otomatik; cooldown ledger zaten `LiveTodoService`
/// içinden bağlı.
class DeclarativeCropRuleSet extends CropRuleSet {
  final CropDefinition definition;
  final List<Rule> Function() packBuilder;

  const DeclarativeCropRuleSet({
    required this.definition,
    required this.packBuilder,
  });

  @override
  Set<String> get supportedCropNames => definition.aliases;

  @override
  List<Recommendation> evaluate(RuleEvaluationContext context) {
    if (!matches(context.crop.name)) return const [];
    return DeclarativePackRunner.runFor(
      ctx: context,
      crop: definition,
      pack: packBuilder(),
    );
  }
}
