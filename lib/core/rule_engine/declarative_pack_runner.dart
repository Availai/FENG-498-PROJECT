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
    final recs = match.result.recommendations;
    final explain = match.explanation?.trim();
    final firstRec = recs.isNotEmpty ? recs.first.trim() : null;

    // ── Sharp, human-friendly content (CLAUDE.md sec 5.1 / sec 22) ────────
    // Hiçbir zaman ham koşul (`crop_id=crop.tea`, `weekly_rain_mm=0.0`)
    // kullanıcıya gösterilmez. Başlık ve gerekçe yalnız kaynaklı, Türkçe
    // cümlelerden üretilir.
    //
    // Başlık önceliği:
    //   1) kuralın `explain` cümlesi (kısa gerekçe)
    //   2) ilk öneri cümlesi (asıl aksiyon mesajı) — kısaltılmış
    //   3) kategori etiketi (son çare)
    final title = (explain != null && explain.isNotEmpty)
        ? explain
        : (firstRec != null && firstRec.isNotEmpty
            ? _shorten(firstRec)
            : _titleFromCategory(match.category));

    final actionHint = (firstRec != null && firstRec.isNotEmpty)
        ? firstRec
        : 'Detayları kontrol edin.';

    // Tek satır gerekçe: explain başlık olarak kullanıldıysa tekrar etmesin.
    // Başlık ilk öneriden türetildiyse explain gerekçe satırına düşer.
    // Aksi halde boş bırakılır (kart neden satırını tamamen gizler).
    final reasonText =
        (explain != null && explain.isNotEmpty && explain != title)
            ? explain
            : '';

    // "Neden" listesi: explain + 1. öneriden sonraki öneri cümleleri.
    // Ham eşleşen koşullar ARTIK eklenmez.
    final extraRecs = recs.length > 1
        ? recs.sublist(1).map((r) => r.trim()).where((r) => r.isNotEmpty)
        : const <String>[];
    final reasonBullets = <String>[
      if (explain != null && explain.isNotEmpty && explain != title) explain,
      ...extraRecs,
    ];

    // Kaynak rozetleri: ham `source.caykur.tea_agronomy_guide` yerine
    // okunabilir kurum adı ("ÇAYKUR", "TAGEM" ...).
    final evidence = <RecommendationEvidence>[];
    for (final e in match.evidence) {
      evidence.add(RecommendationEvidence(
        label: 'Kaynak',
        value: _sourceLabel(e.sourceId),
      ));
    }
    final sourceRefs = match.evidence
        .map((e) => _sourceLabel(e.sourceId))
        .toSet()
        .toList(growable: false);

    final target = ctx.crop.id.isNotEmpty
        ? RecommendationTarget.crop(fieldId: ctx.fieldId, cropId: ctx.crop.id)
        : RecommendationTarget.field(ctx.fieldId);

    // CLAUDE.md sec 17 — kimyasal/uzman onay gerekiyorsa gözleme yönlendir.
    final gate = (match.result.requiresBkuCheck ||
            match.result.requiresExpertConfirmation)
        ? RecommendationGate.observeFirst
        : RecommendationGate.actionable;

    return Recommendation(
      ruleKey: 'pack:${match.id}:v1',
      severity: severity,
      target: target,
      title: title,
      reasonText: reasonText,
      reasonBullets: reasonBullets,
      actionHint: actionHint,
      gate: gate,
      evidence: evidence,
      sourceRefs: sourceRefs,
      cooldownHours: 12,
      category: match.category,
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

  /// Uzun bir öneri cümlesini başlık olarak kullanılabilecek kısa, keskin
  /// bir ifadeye indirger. İlk cümleyi (nokta/iki nokta'ya kadar) alır,
  /// gerekiyorsa kelime sınırından kırpar — kelime ortasında kesmez.
  static String _shorten(String text, {int maxLen = 70}) {
    var s = text.trim();
    // İlk cümle: ilk nokta veya ' — ' ayıracına kadar.
    final dot = s.indexOf('. ');
    if (dot > 0 && dot <= maxLen) {
      s = s.substring(0, dot).trim();
    }
    final dash = s.indexOf(' — ');
    if (dash > 0 && dash <= maxLen) {
      s = s.substring(0, dash).trim();
    }
    if (s.length <= maxLen) return s;
    final cut = s.substring(0, maxLen);
    final lastSpace = cut.lastIndexOf(' ');
    return '${(lastSpace > 40 ? cut.substring(0, lastSpace) : cut).trim()}…';
  }

  /// Ham kaynak ID'sini (`source.caykur.tea_agronomy_guide`) kullanıcıya
  /// gösterilebilir kısa kurum etiketine çevirir. CLAUDE.md sec 10 öncelik
  /// sırasındaki kurum adları kullanılır; bilinmeyen ID'ler için son ek
  /// temizlenerek okunabilir bir karşılık üretilir (ham ID asla sızmaz).
  static String _sourceLabel(String sourceId) {
    final id = sourceId.toLowerCase();
    if (id.contains('caykur')) return 'ÇAYKUR';
    if (id.contains('.bku')) return 'BKÜ Veritabanı';
    if (id.contains('.mgm')) return 'MGM';
    if (id.contains('tagem')) return 'TAGEM';
    if (id.contains('trakya')) return 'Trakya Tarımsal Araştırma';
    if (id.contains('gap')) return 'GAP Tarımsal Araştırma';
    if (id.contains('tarim') || id.contains('orman')) {
      return 'Tarım ve Orman Bakanlığı';
    }
    if (id.contains('universite') || id.contains('univ')) return 'Üniversite';
    return 'Resmî kaynak';
  }
}
