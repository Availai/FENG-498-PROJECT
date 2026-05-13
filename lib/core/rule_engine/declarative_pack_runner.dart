import '../../data/rule_packs/crop_registry.dart';
import '../../data/rule_packs/fact_keys.dart';
import '../../services/guide_engine.dart' show AlertSeverity;
import '../../services/rules/crop_rule_set.dart';
import '../../services/rules/recommendation.dart';
import 'fact_builder.dart';
import 'rule.dart';
import 'rule_engine.dart';
import 'rule_result.dart';

/// Declarative `Rule` pack'lerini mevcut `Recommendation` formatına çevirir.
///
/// Mimari: rule pack (200-300 declarative kural) + facts haritası →
/// `RuleEngine.evaluate` → `RuleMatch[]` → her kategoriden en yüksek
/// öncelikli N tanesi → `Recommendation[]`.
///
/// CLAUDE.md sec 22 — saf fonksiyon, IO yok. Aynı input → aynı output.
class DeclarativePackRunner {
  const DeclarativePackRunner();

  static const _engine = RuleEngine();

  /// Her kategoriden en fazla bu kadar tavsiye üretilir — UI'da bir
  /// hastalık kategorisinin 20+ varyantıyla listeyi boğmamak için.
  /// Daha düşük öncelikli olanlar sessizce düşer; öncelik sıralaması
  /// kullanıcıya en kritik olanı önde bırakır.
  static const _maxPerCategory = 3;

  /// Toplam pack çıktısı bu sayıyı aşmaz. 5 ürün × 18 kategori × 3 cap
  /// = teorik 270; gerçekte 20-40 aktif tavsiye normaldir.
  static const _maxTotal = 25;

  /// Generic crop-aware runner.
  ///
  /// **Yeni ürün eklerken bu metot kullanılır** — pack ve `CropDefinition`
  /// veriliyor, geri kalan (fact override, adapter, cap) otomatik.
  static List<Recommendation> runFor({
    required RuleEvaluationContext ctx,
    required CropDefinition crop,
    required Iterable<Rule> pack,
  }) {
    return const DeclarativePackRunner().run(
      ctx: ctx,
      pack: pack,
      facts: FactBuilder.build(
        ctx: ctx,
        extra: {FactKeys.cropId: crop.stableId},
      ),
    );
  }

  /// Düşük seviyeli runner — facts'i çağıran taraf hazırlar. Testlerde
  /// veya özel fact enjeksiyonunda işe yarar.
  List<Recommendation> run({
    required RuleEvaluationContext ctx,
    required Iterable<Rule> pack,
    required Map<String, Object?> facts,
  }) {
    final matches = _engine.evaluate(facts: facts, rules: pack);
    if (matches.isEmpty) return const [];

    // Kategori bazlı cap — her kategoriden en yüksek öncelikli ilk N.
    // `RuleEngine.evaluate` zaten priority desc + id asc sıralı döner;
    // burada sadece her kategoriden ilk _maxPerCategory'yi tutuyoruz.
    final countByCategory = <String, int>{};
    final kept = <RuleMatch>[];
    for (final m in matches) {
      final c = m.category;
      final n = countByCategory[c] ?? 0;
      if (n >= _maxPerCategory) continue;
      countByCategory[c] = n + 1;
      kept.add(m);
      if (kept.length >= _maxTotal) break;
    }

    return kept.map((m) => _toRecommendation(ctx: ctx, match: m)).toList();
  }

  Recommendation _toRecommendation({
    required RuleEvaluationContext ctx,
    required RuleMatch match,
  }) {
    final severity = _mapSeverity(match.result.riskLevel, match.priority);
    final title = match.explanation ?? _titleFromCategory(match.category);
    final actionHint = match.result.recommendations.isNotEmpty
        ? match.result.recommendations.first
        : 'Detayları kontrol edin.';
    final reasonBullets = <String>[
      if (match.explanation != null && match.explanation!.isNotEmpty)
        match.explanation!,
      ...match.matchedConditions.map((c) => 'Eşleşen koşul: $c'),
    ];
    final reasonText = match.explanation ?? match.matchedConditions.join(', ');

    final evidence = <RecommendationEvidence>[];
    for (final e in match.evidence) {
      evidence.add(RecommendationEvidence(
        label: 'Kaynak',
        value: e.sourceId,
      ));
    }
    final sourceRefs = match.evidence.map((e) => e.sourceId).toList();

    final target = ctx.crop.id.isNotEmpty
        ? RecommendationTarget.crop(fieldId: ctx.fieldId, cropId: ctx.crop.id)
        : RecommendationTarget.field(ctx.fieldId);

    // CLAUDE.md sec 17 — kimyasal/uzman onay gerekiyorsa gözleme yönlendir.
    final gate = (match.result.requiresBkuCheck ||
            match.result.requiresExpertConfirmation)
        ? RecommendationGate.observeFirst
        : RecommendationGate.actionable;

    final extraRecs = match.result.recommendations.length > 1
        ? match.result.recommendations.sublist(1)
        : const <String>[];

    return Recommendation(
      ruleKey: 'pack:${match.id}:v1',
      severity: severity,
      target: target,
      title: title,
      reasonText: reasonText,
      reasonBullets: [...reasonBullets, ...extraRecs],
      actionHint: actionHint,
      gate: gate,
      evidence: evidence,
      sourceRefs: sourceRefs,
      cooldownHours: 12,
    );
  }

  AlertSeverity _mapSeverity(String? risk, int priority) {
    if (risk == 'high' || priority >= 90) return AlertSeverity.critical;
    if (risk == 'medium' || priority >= 60) return AlertSeverity.warning;
    return AlertSeverity.info;
  }

  String _titleFromCategory(String category) {
    return switch (category) {
      'suitability' => 'Uygunluk değerlendirmesi',
      'soil_analysis' => 'Toprak analizi uyarısı',
      'pre_planting' => 'Ekim öncesi hazırlık',
      'sowing_or_planting' => 'Ekim önerisi',
      'fertilization' => 'Gübreleme önerisi',
      'irrigation' => 'Sulama önerisi',
      'disease_risk' => 'Hastalık riski',
      'pest_risk' => 'Zararlı riski',
      'weed_management' => 'Yabancı ot yönetimi',
      'harvest' => 'Hasat önerisi',
      'weather_warning' => 'Hava uyarısı',
      'task_generation' => 'Görev önerisi',
      'safety_warning' => 'Güvenlik uyarısı',
      'crop_unique' => 'Bitkiye özel not',
      _ => 'Tavsiye',
    };
  }
}
