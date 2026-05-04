import '../../data/activity_types.dart';
import '../../models/plant_condition.dart';
import '../guide_engine.dart' show AlertSeverity;
import 'crop_rule_set.dart';
import 'recommendation.dart';

/// Ayçiçeği için MVP-1 kural seti — 5 kritik kural.
///
/// Tasarım:
///   • Her kural saf bir `_ruleX(ctx)` fonksiyonu, null/Recommendation döner.
///   • `evaluate` sırayla çağırır; null olmayanlar listeye düşer.
///   • Kurallar veri yokluğuna karşı **defansif** — `growth` veya `hourly`
///     null ise kural tetiklenmez; çiftçi yanlış uyarı görmez.
///   • Şiddet sıralaması: critical → warning → info.
class SunflowerRules extends CropRuleSet {
  const SunflowerRules();

  @override
  Set<String> get supportedCropNames => const {
        'aycicek',
        'aycicegi',
        'sunflower',
      };

  @override
  List<Recommendation> evaluate(RuleEvaluationContext ctx) {
    if (!matches(ctx.crop.name)) return const [];
    final out = <Recommendation>[];
    final r1 = _emergenceCrustingRisk(ctx);
    if (r1 != null) out.add(r1);
    final r4 = _waterStressFlowering(ctx);
    if (r4 != null) out.add(r4);
    final r5 = _waterStressGrainFilling(ctx);
    if (r5 != null) out.add(r5);
    final r11 = _pestHelicoverpa(ctx);
    if (r11 != null) out.addAll(r11);
    final r13 = _harvestReady(ctx);
    if (r13 != null) out.add(r13);
    return out;
  }

  // ── Kural #1 — Çıkış sonrası kabuk riski ────────────────────────────
  /// Ekim sonrası ilk 14 gün; sulama yapılmış veya ileride ağır yağmur
  /// bekleniyor; son 5 gün çapalama yok → yüzey kabuk riski.
  Recommendation? _emergenceCrustingRisk(RuleEvaluationContext ctx) {
    final days = ctx.crop.daysSincePlanted(ctx.now);
    if (days == null || days < 3 || days > 14) return null;
    // Çimlenme evresinde ya da growth bilgisi yoksa kural devrede.
    final stage = ctx.growth?.stageKey;
    if (stage != null && stage != 'cimlenme' && stage != 'vejetatif') {
      return null;
    }
    final wateredRecently = ctx.hasActivityWithin(
      type: ActivityType.watering,
      window: const Duration(hours: 48),
    );
    final heavyRainAhead =
        (ctx.hourly?.rainSumNext(24) ?? 0) > 12.0;
    if (!wateredRecently && !heavyRainAhead) return null;
    final hoedRecently = ctx.hasActivityWithin(
      type: ActivityType.hoeing,
      window: const Duration(days: 5),
    );
    if (hoedRecently) return null;
    return Recommendation(
      ruleKey: 'sunflower.emergence.crusting.v1',
      severity: AlertSeverity.warning,
      target: RecommendationTarget.crop(
        fieldId: ctx.fieldId,
        cropId: ctx.crop.id,
      ),
      title: 'Toprak kabuk riski',
      reasonText:
          'Ekimden $days gün geçti; sulama veya yağışla yüzey sertleşebilir.',
      reasonBullets: [
        'Çimlenme/erken vejetatif evrede',
        if (wateredRecently) 'Son 48 saatte sulama kaydı var',
        if (heavyRainAhead) '24 saat içinde 12 mm üzeri yağış bekleniyor',
        'Son 5 gündür çapalama kaydı yok',
      ],
      actionHint:
          'Sıra üstünde kabuk varsa hafif çapalama yapın; fideler kolay çıksın.',
      clearOnActivities: const [
        ClearOnActivity(
          activityType: ActivityType.hoeing,
          withinHours: 24,
        ),
      ],
      cooldownHours: 48,
    );
  }

  // ── Kural #4 — Çiçeklenmede su stresi ───────────────────────────────
  /// Çiçeklenme evresi en kritik dönem; su açığı 30 mm üzerinde veya 5+
  /// gün sulama yok ve yağmur gelmiyorsa acil sulama.
  Recommendation? _waterStressFlowering(RuleEvaluationContext ctx) {
    final stage = ctx.growth?.stageKey;
    final days = ctx.crop.daysSincePlanted(ctx.now);
    final inFlower = stage == 'ciceklenme' ||
        (stage == null && days != null && days >= 60 && days <= 95);
    if (!inFlower) return null;
    final deficit = ctx.growth?.waterDeficitMm ?? 0;
    final lastWater = ctx.lastActivityAt(type: ActivityType.watering);
    final hoursSinceWater = lastWater == null
        ? double.infinity
        : ctx.now.difference(lastWater).inHours.toDouble();
    final dryStreak = hoursSinceWater >= 5 * 24;
    if (deficit < 30 && !dryStreak) return null;
    // Yağmur geliyor → kural tetiklenmesin (forecast varsa).
    final rainAhead = ctx.hourly?.rainSumNext(24);
    if (rainAhead != null && rainAhead > 8) return null;
    return Recommendation(
      ruleKey: 'sunflower.water_stress.flower.v1',
      severity: AlertSeverity.critical,
      target: RecommendationTarget.crop(
        fieldId: ctx.fieldId,
        cropId: ctx.crop.id,
      ),
      title: 'Çiçeklenmede su stresi',
      reasonText:
          'Ayçiçeğinin en kritik döneminde su açığı verim kaybına yol açıyor.',
      reasonBullets: [
        if (deficit >= 30)
          'Su açığı yaklaşık ${deficit.round()} mm',
        if (dryStreak)
          'Son sulama 5+ gün önce',
        if (rainAhead == null)
          'Yağış tahmini alınamadı (çevrimdışı)',
        'Çiçeklenme döneminde stres, dane bağlamayı düşürür',
      ],
      actionHint:
          'Bugün dekara 30–35 mm sulama yapın; sabah 06:00–10:00 arası ideal.',
      clearOnActivities: const [
        ClearOnActivity(
          activityType: ActivityType.watering,
          withinHours: 36,
        ),
      ],
      cooldownHours: 24,
    );
  }

  // ── Kural #5 — Dane dolumunda su stresi ─────────────────────────────
  /// Dane dolumu evresi; su açığı 25 mm üzerinde → verim çarpanı düşüyor.
  Recommendation? _waterStressGrainFilling(RuleEvaluationContext ctx) {
    final stage = ctx.growth?.stageKey;
    if (stage != 'meyve_dolumu') return null;
    final deficit = ctx.growth?.waterDeficitMm ?? 0;
    if (deficit < 25) return null;
    final rainAhead = ctx.hourly?.rainSumNext(24);
    if (rainAhead != null && rainAhead > 8) return null;
    final yieldLoss = ctx.growth?.yieldLossPct ?? 0;
    return Recommendation(
      ruleKey: 'sunflower.water_stress.grain.v1',
      severity: AlertSeverity.critical,
      target: RecommendationTarget.crop(
        fieldId: ctx.fieldId,
        cropId: ctx.crop.id,
      ),
      title: 'Dane dolumunda su stresi',
      reasonText:
          'Su açığı ${deficit.round()} mm — danelerin dolumunu engelliyor.',
      reasonBullets: [
        'Dane dolumu (R6) evresinde',
        'Su açığı ${deficit.round()} mm',
        if (yieldLoss > 0) 'Tahmini verim kaybı %$yieldLoss',
      ],
      actionHint:
          '24 saat içinde dekara 25–30 mm sulama yapın; gecikmeden uygulayın.',
      clearOnActivities: const [
        ClearOnActivity(
          activityType: ActivityType.watering,
          withinHours: 36,
        ),
      ],
      cooldownHours: 24,
    );
  }

  // ── Kural #11 — Yeşilkurt (Helicoverpa) riski ───────────────────────
  /// Tomurcuklanma–çiçeklenme döneminde plant instance'da `pest_risk`
  /// bayrağı varsa her bitki için ayrı bir tavsiye üret. İlaçlama son 7
  /// gün içinde yapıldıysa kural devrede değil.
  List<Recommendation>? _pestHelicoverpa(RuleEvaluationContext ctx) {
    final stage = ctx.growth?.stageKey;
    final days = ctx.crop.daysSincePlanted(ctx.now);
    final inWindow = stage == 'tomurcuklanma' ||
        stage == 'ciceklenme' ||
        (stage == null && days != null && days >= 50 && days <= 95);
    if (!inWindow) return null;
    final sprayedRecently = ctx.hasActivityWithin(
      type: ActivityType.spraying,
      window: const Duration(days: 7),
    );
    if (sprayedRecently) return null;
    final atRisk = ctx.plantInstances
        .where((p) =>
            p.cropId == ctx.crop.id && p.hasCondition(PlantCondition.pestRisk))
        .toList();
    if (atRisk.isEmpty) return null;
    return atRisk
        .map((p) => Recommendation(
              ruleKey: 'sunflower.pest.helicoverpa.v1',
              severity: AlertSeverity.critical,
              target: RecommendationTarget.plant(
                fieldId: ctx.fieldId,
                cropId: ctx.crop.id,
                plantInstanceId: p.id,
              ),
              title: 'Yeşilkurt riski',
              reasonText:
                  'Tomurcuk/çiçek döneminde işaretlenen bitkide zararlı belirtisi var.',
              reasonBullets: const [
                'Bitki "zararlı riski" olarak işaretlenmiş',
                'Tomurcuklanma-çiçeklenme döneminde',
                'Son 7 gün içinde ilaçlama kaydı yok',
              ],
              actionHint:
                  'Tablada yumurta/tırtıl kontrolü yapın; gerekirse Bt veya '
                  'spinosad bazlı ürün uygulayın (etiket dozunda).',
              clearOnActivities: const [
                ClearOnActivity(
                  activityType: ActivityType.spraying,
                  withinHours: 24,
                ),
              ],
              cooldownHours: 48,
            ))
        .toList();
  }

  // ── Kural #13 — Hasada hazır ────────────────────────────────────────
  /// GDD ≥ 1700 (Tbase=8 °C) veya growth yoksa daysSincePlanted ≥ 110;
  /// veya en az bir bitkide `near_harvest` 7+ gündür duruyor → hasat.
  Recommendation? _harvestReady(RuleEvaluationContext ctx) {
    final gdd = ctx.growth?.accumulatedGdd ?? 0;
    final stage = ctx.growth?.stageKey;
    final days = ctx.crop.daysSincePlanted(ctx.now);
    final byGdd = gdd >= 1700 || stage == 'olgunlasma';
    final byDays = stage == null && days != null && days >= 110;
    final byPlantFlag = ctx.plantInstances.any((p) =>
        p.cropId == ctx.crop.id && p.hasCondition(PlantCondition.nearHarvest));
    if (!byGdd && !byDays && !byPlantFlag) return null;
    final harvestedRecently = ctx.hasActivityWithin(
      type: ActivityType.harvest,
      window: const Duration(days: 7),
    );
    if (harvestedRecently) return null;
    return Recommendation(
      ruleKey: 'sunflower.harvest.ready.v1',
      severity: AlertSeverity.critical,
      target: RecommendationTarget.crop(
        fieldId: ctx.fieldId,
        cropId: ctx.crop.id,
      ),
      title: 'Hasat zamanı geldi',
      reasonText:
          'Ayçiçeği olgunlaşma eşiğine ulaştı — gecikmek dane kaybı demek.',
      reasonBullets: [
        if (byGdd) 'Toplam GDD ${gdd.round()} ≥ 1700',
        if (byDays) 'Ekimden $days gün geçti',
        if (byPlantFlag) 'En az bir bitki "hasada yakın" işaretli',
        'Son 7 gün içinde hasat kaydı yok',
      ],
      actionHint:
          'Tablanın arkası sarı-kahverengi olduğunda 5–7 gün içinde hasat edin.',
      clearOnActivities: const [
        ClearOnActivity(
          activityType: ActivityType.harvest,
          withinHours: 24 * 7,
        ),
      ],
      cooldownHours: 48,
    );
  }
}
