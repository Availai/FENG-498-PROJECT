import '../../data/activity_types.dart';
import '../../data/wheat_source_refs.dart';
import '../guide_engine.dart' show AlertSeverity;
import 'crop_rule_set.dart';
import 'recommendation.dart';

/// Buğday için MVP kural seti — 4 deterministik kural.
///
/// Tasarım ayçiçeği setini izler: saf fonksiyonlar, defansif null kontrolü,
/// her tavsiyede kaynak referansı. Eşik değerleri **konservatif** seçilmiş
/// (yıl/bölge varyasyonuna toleranslı; gereksiz tetiklenme < kaçırılan
/// tetiklenme).
///
/// Kaynak: TAGEM Buğday Tarımı, Bahri Dağdaş Buğday Rehberleri, Trakya TAE.
class WheatRules extends CropRuleSet {
  const WheatRules();

  @override
  Set<String> get supportedCropNames => const {
        'bugday',
        'wheat',
        'durum',
      };

  @override
  List<Recommendation> evaluate(RuleEvaluationContext ctx) {
    if (!matches(ctx.crop.name)) return const [];
    final out = <Recommendation>[];
    final r1 = _emergence(ctx);
    if (r1 != null) out.add(r1);
    final r2 = _tilleringNitrogen(ctx);
    if (r2 != null) out.add(r2);
    final r3 = _stemElongationWater(ctx);
    if (r3 != null) out.add(r3);
    final r4 = _rustScouting(ctx);
    if (r4 != null) out.add(r4);
    final r5 = _harvestReady(ctx);
    if (r5 != null) out.add(r5);
    return out;
  }

  String? _envSource(RuleEvaluationContext ctx) {
    final source = ctx.environment?.source.trim();
    if (source == null || source.isEmpty || source == 'bilinmiyor') {
      return null;
    }
    return 'Çevre verisi: $source';
  }

  String? _scaleBullet(RuleEvaluationContext ctx) {
    final f = ctx.fieldState;
    if (f == null) return null;
    return '${f.areaDekar.toStringAsFixed(2)} da / ${f.estimatedPlantCount} tahmini bitki hesabı';
  }

  List<RecommendationEvidence> _evidence(RuleEvaluationContext ctx) {
    final out = <RecommendationEvidence>[];
    final days = ctx.crop.daysSincePlanted(ctx.now);
    if (days != null) {
      out.add(RecommendationEvidence(label: 'Ekimden gün', value: '$days'));
    }
    final stage = ctx.growth?.stageKey;
    if (stage != null) {
      out.add(RecommendationEvidence(label: 'Evre', value: stage));
    }
    final env = ctx.environment;
    if (env?.temperatureC != null) {
      out.add(RecommendationEvidence(
        label: 'Sıcaklık',
        value: '${env!.temperatureC!.toStringAsFixed(0)}°C',
      ));
    }
    if (env?.humidityPct != null) {
      out.add(RecommendationEvidence(
        label: 'Hava nemi',
        value: '%${env!.humidityPct!.round()}',
      ));
    }
    if (env?.soilMoisture != null) {
      out.add(RecommendationEvidence(
        label: 'Toprak nemi',
        value: '%${(env!.soilMoisture! * 100).round()}',
      ));
    }
    if (env?.weeklyRainMm != null) {
      out.add(RecommendationEvidence(
        label: 'Haftalık yağış',
        value: '${env!.weeklyRainMm!.toStringAsFixed(1)} mm',
      ));
    }
    final f = ctx.fieldState;
    if (f != null) {
      out.add(RecommendationEvidence(
        label: 'Alan',
        value: '${f.areaDekar.toStringAsFixed(2)} da',
      ));
      if (f.weeklyWaterTargetMm > 0) {
        out.add(RecommendationEvidence(
          label: 'Haftalık su',
          value:
              '${f.weeklyWaterMm.toStringAsFixed(1)} / ${f.weeklyWaterTargetMm.toStringAsFixed(1)} mm',
        ));
      }
    }
    final source = ctx.environment?.source;
    if (source != null && source.trim().isNotEmpty) {
      out.add(RecommendationEvidence(label: 'Veri kaynağı', value: source));
    }
    return out;
  }

  // ── Kural #1 — Çıkış sonrası kabuk/nem riski (ekim+5..15 gün) ───────
  Recommendation? _emergence(RuleEvaluationContext ctx) {
    final days = ctx.crop.daysSincePlanted(ctx.now);
    if (days == null || days < 5 || days > 18) return null;
    final env = ctx.environment;
    final wetSurface = env?.isWetSoil == true;
    final coldSoil = env?.isColdSoil == true;
    final hoedRecently = ctx.hasActivityWithin(
      type: ActivityType.hoeing,
      window: const Duration(days: 7),
    );
    if (!wetSurface && !coldSoil) return null;
    if (hoedRecently) return null;
    final scale = _scaleBullet(ctx);
    final src = _envSource(ctx);
    return Recommendation(
      ruleKey: 'wheat.emergence.crusting.v1',
      severity: AlertSeverity.warning,
      target: RecommendationTarget.crop(
        fieldId: ctx.fieldId,
        cropId: ctx.crop.id,
      ),
      title: 'Çıkış sonrası yüzey kontrolü',
      reasonText:
          'Buğday çıkışı kritik dönemde — yüzey kabuğu/soğuk toprak fideyi yavaşlatır.',
      reasonBullets: [
        if (wetSurface)
          'Toprak nemi %${(env!.soilMoisture! * 100).round()} ile yüksek',
        if (coldSoil) 'Toprak ${env!.soilTempC!.toStringAsFixed(1)}°C',
        'Ekimden $days gün geçti',
        if (scale != null) scale,
        if (src != null) src,
      ],
      actionHint:
          'Sıra üstünde kabuk varsa yüzeysel çapalama yapın; çıkışı tamamlatmak için aşırı sulamaktan kaçının.',
      gate: RecommendationGate.actionable,
      evidence: _evidence(ctx),
      command: const RecommendationCommand(
        activityType: ActivityType.hoeing,
        buttonLabel: 'Yüzey çapaladım',
      ),
      sourceRefs: WheatRuleSourceRefs.emergence,
      clearOnActivities: const [
        ClearOnActivity(
          activityType: ActivityType.hoeing,
          withinHours: 24 * 7,
        ),
      ],
      cooldownHours: 72,
    );
  }

  // ── Kural #2 — Kardeşlenme dönemi azot stresi ───────────────────────
  Recommendation? _tilleringNitrogen(RuleEvaluationContext ctx) {
    final stage = ctx.growth?.stageKey;
    final days = ctx.crop.daysSincePlanted(ctx.now);
    final inWindow = stage == 'kardeslenme' ||
        stage == 'vejetatif' ||
        (stage == null && days != null && days >= 60 && days <= 130);
    if (!inWindow) return null;
    final env = ctx.environment;
    final nStress = ctx.growth?.nStressIdx ?? 0;
    final nLow = env?.nitrogenKgDekar != null && env!.nitrogenKgDekar! < 1.5;
    if (nStress < 0.25 && !nLow) return null;
    final fertilizedRecently = ctx.hasActivityWithin(
      type: ActivityType.fertilizing,
      window: const Duration(days: 14),
    );
    if (fertilizedRecently) return null;
    final scale = _scaleBullet(ctx);
    final src = _envSource(ctx);
    return Recommendation(
      ruleKey: 'wheat.tillering.nitrogen.v1',
      severity:
          nStress > 0.45 ? AlertSeverity.critical : AlertSeverity.warning,
      target: RecommendationTarget.crop(
        fieldId: ctx.fieldId,
        cropId: ctx.crop.id,
      ),
      title: 'Kardeşlenmede üst gübreleme',
      reasonText:
          'Buğdayda kardeşlenme döneminde azot eksikliği başak sayısını düşürür.',
      reasonBullets: [
        if (nStress > 0.25) 'Azot stresi %${(nStress * 100).round()}',
        if (nLow)
          'Tahmini azot ${env.nitrogenKgDekar!.toStringAsFixed(1)} kg/da',
        'Son 14 günde gübreleme kaydı yok',
        if (scale != null) scale,
        if (src != null) src,
      ],
      actionHint:
          'Üst gübreleme: 6-8 kg N/da bölünerek, hafif yağış öncesinde uygulayın; üreyi toprağa karıştırın.',
      gate: RecommendationGate.actionable,
      evidence: _evidence(ctx),
      command: const RecommendationCommand(
        activityType: ActivityType.fertilizing,
        buttonLabel: 'Gübreledim',
        metadata: {
          'fertilizer_type': 'Üst gübre',
          'split_window': 'ust',
        },
      ),
      sourceRefs: WheatRuleSourceRefs.tilleringNitrogen,
      clearOnActivities: const [
        ClearOnActivity(
          activityType: ActivityType.fertilizing,
          withinHours: 24 * 14,
        ),
      ],
      cooldownHours: 72,
    );
  }

  // ── Kural #3 — Sapa kalkma / başaklanma su stresi ────────────────────
  Recommendation? _stemElongationWater(RuleEvaluationContext ctx) {
    final stage = ctx.growth?.stageKey;
    final days = ctx.crop.daysSincePlanted(ctx.now);
    final inWindow = stage == 'sapakalkma' ||
        stage == 'baslanma' ||
        stage == 'ciceklenme' ||
        (stage == null && days != null && days >= 130 && days <= 180);
    if (!inWindow) return null;
    final deficit = ctx.growth?.waterDeficitMm ?? 0;
    final env = ctx.environment;
    final field = ctx.fieldState;
    final drySoil = env?.isDrySoil == true;
    final weeklyBehind = field?.waterBehind == true;
    if (deficit < 25 && !drySoil && !weeklyBehind) return null;
    final rainAhead = ctx.hourly?.rainSumNext(24) ?? 0;
    if (rainAhead > 8 && deficit < 30 && !drySoil) return null;
    final scale = _scaleBullet(ctx);
    final src = _envSource(ctx);
    return Recommendation(
      ruleKey: 'wheat.stem_elongation.water.v1',
      severity:
          deficit >= 30 || drySoil ? AlertSeverity.critical : AlertSeverity.warning,
      target: RecommendationTarget.crop(
        fieldId: ctx.fieldId,
        cropId: ctx.crop.id,
      ),
      title: 'Sapa kalkma / başaklanmada sulama',
      reasonText:
          'Bu dönemdeki su stresi başak boyu ve dane sayısını doğrudan düşürür.',
      reasonBullets: [
        if (deficit >= 25) 'Su açığı yaklaşık ${deficit.round()} mm',
        if (drySoil)
          'Toprak nemi %${(env!.soilMoisture! * 100).round()} ile düşük',
        if (weeklyBehind &&
            field != null &&
            field.weeklyWaterTargetMm > 0)
          'Bu hafta ${field.weeklyWaterMm.toStringAsFixed(1)} / '
              '${field.weeklyWaterTargetMm.toStringAsFixed(1)} mm su verilmiş',
        if (scale != null) scale,
        if (src != null) src,
      ],
      actionHint:
          'Tarla kapasitesini kapatacak şekilde sulayın; gece-sabah saatlerinde uygulayın.',
      gate: RecommendationGate.actionable,
      evidence: _evidence(ctx),
      command: const RecommendationCommand(
        activityType: ActivityType.watering,
        buttonLabel: 'Suladım',
      ),
      sourceRefs: WheatRuleSourceRefs.stemElongationWater,
      clearOnActivities: const [
        ClearOnActivity(
          activityType: ActivityType.watering,
          withinHours: 36,
        ),
      ],
      cooldownHours: 24,
    );
  }

  // ── Kural #4 — Pas hastalıkları gözlem penceresi ─────────────────────
  /// Yüksek nem + 60+ gün buğdayda → sarı/kahverengi/kara pas izleme. Gate
  /// observeFirst — gözlem onaylanmadan kimyasal tavsiye edilmez.
  Recommendation? _rustScouting(RuleEvaluationContext ctx) {
    final days = ctx.crop.daysSincePlanted(ctx.now);
    final stage = ctx.growth?.stageKey;
    final inWindow = (stage != null &&
            (stage == 'sapakalkma' ||
                stage == 'baslanma' ||
                stage == 'ciceklenme')) ||
        (stage == null && days != null && days >= 110 && days <= 180);
    if (!inWindow) return null;
    final env = ctx.environment;
    final humid = env?.humidityPct != null && env!.humidityPct! >= 70;
    final pressure = ctx.growth?.diseasePressure ?? 0;
    if (!humid && pressure < 0.30) return null;
    final scoutedRecently = ctx.hasActivityWithin(
      type: ActivityType.scouting,
      subtype: ActivitySubtype.diseaseObservation,
      window: const Duration(days: 5),
    );
    if (scoutedRecently) return null;
    final scale = _scaleBullet(ctx);
    final src = _envSource(ctx);
    return Recommendation(
      ruleKey: 'wheat.disease.rust_scouting.v1',
      severity: pressure > 0.5 ? AlertSeverity.critical : AlertSeverity.warning,
      target: RecommendationTarget.crop(
        fieldId: ctx.fieldId,
        cropId: ctx.crop.id,
      ),
      title: 'Pas hastalığı gözlemi',
      reasonText:
          'Yüksek nem ve hastalık baskısı sarı/kahverengi pas için risk oluşturuyor.',
      reasonBullets: [
        if (humid) 'Hava nemi %${env.humidityPct!.round()}',
        if (pressure > 0.30)
          'Hastalık baskısı %${(pressure * 100).round()}',
        'Son 5 gün içinde gözlem kaydı yok',
        if (scale != null) scale,
        if (src != null) src,
      ],
      actionHint:
          'Yaprak alt yüzeyinde sarı/kahverengi püstüller için tarla kontrolü yapın; eşik doğrulanmadan ilaçlama açılmaz.',
      gate: RecommendationGate.observeFirst,
      evidence: _evidence(ctx),
      command: const RecommendationCommand(
        activityType: ActivityType.scouting,
        subtype: ActivitySubtype.diseaseObservation,
        buttonLabel: 'Gözlem yaptım',
        metadata: {
          RecommendationMetadataKeys.ipmGate: 'observe_before_spray',
          'pest_key': 'pas',
        },
      ),
      sourceRefs: WheatRuleSourceRefs.rustScouting,
      clearOnActivities: const [
        ClearOnActivity(
          activityType: ActivityType.scouting,
          subtype: ActivitySubtype.diseaseObservation,
          withinHours: 24 * 5,
        ),
      ],
      cooldownHours: 48,
      timing: const RecommendationTiming(
        descriptor: 'Sabah saatlerinde, çiy kalkmadan',
        source: 'agronomic',
      ),
    );
  }

  // ── Kural #5 — Hasada hazır ──────────────────────────────────────────
  Recommendation? _harvestReady(RuleEvaluationContext ctx) {
    final stage = ctx.growth?.stageKey;
    final days = ctx.crop.daysSincePlanted(ctx.now);
    final byStage = stage == 'olgunlasma' || stage == 'hasat';
    final byDays = stage == null && days != null && days >= 220;
    if (!byStage && !byDays) return null;
    final harvestedRecently = ctx.hasActivityWithin(
      type: ActivityType.harvest,
      window: const Duration(days: 7),
    );
    if (harvestedRecently) return null;
    final env = ctx.environment;
    final humid = env?.humidityPct != null && env!.humidityPct! >= 75;
    final scale = _scaleBullet(ctx);
    final src = _envSource(ctx);
    return Recommendation(
      ruleKey: 'wheat.harvest.ready.v1',
      severity: AlertSeverity.critical,
      target: RecommendationTarget.crop(
        fieldId: ctx.fieldId,
        cropId: ctx.crop.id,
      ),
      title: 'Buğday hasat zamanı',
      reasonText:
          'Buğday olgunlaştı — gecikme dane dökümü ve kalite kaybı demek.',
      reasonBullets: [
        if (byStage) 'Evre: $stage',
        if (byDays) 'Ekimden $days gün geçti',
        if (humid) 'Hava nemi %${env.humidityPct!.round()}',
        'Son 7 gün içinde hasat kaydı yok',
        if (scale != null) scale,
        if (src != null) src,
      ],
      actionHint: humid
          ? 'Nem yüksekse kuru günü bekleyin; hasat sonrası kurutma gerekirse yapın.'
          : 'Tane sertleşmiş ve dane kuruyken hasat edin (nem hedef <%13).',
      gate: RecommendationGate.actionable,
      evidence: _evidence(ctx),
      command: const RecommendationCommand(
        activityType: ActivityType.harvest,
        buttonLabel: 'Hasat ettim',
      ),
      sourceRefs: WheatRuleSourceRefs.harvestReady,
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
