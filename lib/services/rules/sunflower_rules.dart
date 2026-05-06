import '../../data/activity_types.dart';
import '../../data/crop_ipm_rules.dart';
import '../../data/sunflower_source_refs.dart';
import '../../models/plant_condition.dart';
import '../guide_engine.dart' show AlertSeverity;
import 'crop_rule_set.dart';
import 'ipm_rule_runner.dart';
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
    final r6 = _nutrientAndPhStress(ctx);
    if (r6 != null) out.add(r6);
    final r8 = _diseaseScoutingRisk(ctx);
    if (r8 != null) out.add(r8);
    final r11 = _pestHelicoverpa(ctx);
    if (r11 != null) out.addAll(r11);
    final r13 = _harvestReady(ctx);
    if (r13 != null) out.add(r13);
    // Tarla düzeyinde IPM kuralları (scouting penceresi, eşik gate, kimyasal
    // kapısı). `_pestHelicoverpa` plant-instance düzeyinde çalışmaya devam
    // eder — anahtarlar farklı olduğundan dedup çakışmaz.
    out.addAll(IpmRuleRunner.run(
      ctx: ctx,
      rules: SunflowerIpmRules.rules,
      windows: SunflowerIpmRules.scoutingWindows,
    ));
    return out;
  }

  double? _rainNext24h(RuleEvaluationContext ctx) =>
      ctx.hourly?.rainSumNext(24);

  String? _envSource(RuleEvaluationContext ctx) {
    final source = ctx.environment?.source.trim();
    if (source == null || source.isEmpty || source == 'bilinmiyor') {
      return null;
    }
    return 'Çevre verisi: $source';
  }

  String? _fieldScaleBullet(RuleEvaluationContext ctx) {
    final f = ctx.fieldState;
    if (f == null) return null;
    return '${f.areaDekar.toStringAsFixed(2)} da / ${f.estimatedPlantCount} tahmini bitki hesabı kullanıldı';
  }

  String? _weeklyWaterBullet(RuleEvaluationContext ctx) {
    final f = ctx.fieldState;
    if (f == null || f.weeklyWaterTargetMm <= 0) return null;
    return 'Bu hafta ${f.weeklyWaterMm.toStringAsFixed(1)} / '
        '${f.weeklyWaterTargetMm.toStringAsFixed(1)} mm su verilmiş';
  }

  String _waterActionHint(
    RuleEvaluationContext ctx, {
    required String base,
  }) {
    final f = ctx.fieldState;
    if (f == null || f.areaSqm <= 0) return base;
    final missing = f.weeklyWaterMissingMm.clamp(0.0, 60.0).toDouble();
    final stress =
        (ctx.growth?.waterDeficitMm ?? 0).clamp(0.0, 60.0).toDouble();
    final targetMm = (missing + stress * 0.35).clamp(20.0, 40.0).toDouble();
    final liters = targetMm * f.areaSqm;
    return '$base ${targetMm.toStringAsFixed(0)} mm hedefle; yaklaşık '
        '${liters.round()} L su eder.';
  }

  RecommendationCommand? _waterCommand(RuleEvaluationContext ctx) {
    final f = ctx.fieldState;
    if (f == null || f.areaSqm <= 0) {
      return RecommendationCommand(
        activityType: ActivityType.watering,
        buttonLabel: ActivityType.actionLabel(ActivityType.watering),
        metadata: const {
          'irrigation_method': 'Tarla sulaması',
          'quantity_unavailable_reason': 'field_area_missing',
        },
      );
    }
    if (f == null || f.areaSqm <= 0) {
      return const RecommendationCommand(
        activityType: ActivityType.watering,
        buttonLabel: 'Suladım',
        metadata: {
          'irrigation_method': 'Tarla sulaması',
          'quantity_status': 'field_area_missing',
        },
      );
    }
    final missing = f.weeklyWaterMissingMm.clamp(0.0, 60.0).toDouble();
    final stress =
        (ctx.growth?.waterDeficitMm ?? 0).clamp(0.0, 60.0).toDouble();
    final targetMm = (missing + stress * 0.35).clamp(20.0, 40.0).toDouble();
    final liters = targetMm * f.areaSqm;
    return RecommendationCommand(
      activityType: ActivityType.watering,
      quantity: liters.roundToDouble(),
      quantityUnit: 'L',
      recommendedQuantity: liters.roundToDouble(),
      buttonLabel: 'Suladım',
      metadata: {
        'effective_water_mm': targetMm,
        'effective_water_liters': liters,
        'irrigation_method': 'Tarla sulaması',
      },
    );
  }

  List<RecommendationEvidence> _evidence(RuleEvaluationContext ctx) {
    final out = <RecommendationEvidence>[];
    final days = ctx.crop.daysSincePlanted(ctx.now);
    final env = ctx.environment;
    final field = ctx.fieldState;
    final growth = ctx.growth;
    if (days != null) {
      out.add(RecommendationEvidence(label: 'Ekimden gün', value: '$days'));
    }
    if (growth != null) {
      out.add(RecommendationEvidence(label: 'Evre', value: growth.stageKey));
      out.add(RecommendationEvidence(
        label: 'Su açığı',
        value: '${growth.waterDeficitMm.toStringAsFixed(1)} mm',
      ));
      out.add(RecommendationEvidence(
        label: 'Azot stresi',
        value: '%${(growth.nStressIdx * 100).round()}',
      ));
      out.add(RecommendationEvidence(
        label: 'Hastalık baskısı',
        value: '%${(growth.diseasePressure * 100).round()}',
      ));
    }
    if (env?.soilMoisture != null) {
      out.add(RecommendationEvidence(
        label: 'Toprak nemi',
        value: '%${(env!.soilMoisture! * 100).round()}',
      ));
    }
    if (env?.soilPh != null) {
      out.add(RecommendationEvidence(
        label: 'Toprak pH',
        value: env!.soilPh!.toStringAsFixed(1),
      ));
    }
    if (env?.nitrogenKgDekar != null) {
      out.add(RecommendationEvidence(
        label: 'Azot',
        value: '${env!.nitrogenKgDekar!.toStringAsFixed(1)} kg/da',
      ));
    }
    if (env?.phosphorusKgDekar != null) {
      out.add(RecommendationEvidence(
        label: 'Fosfor',
        value: '${env!.phosphorusKgDekar!.toStringAsFixed(1)} kg/da',
      ));
    }
    if (env?.potassiumKgDekar != null) {
      out.add(RecommendationEvidence(
        label: 'Potasyum',
        value: '${env!.potassiumKgDekar!.toStringAsFixed(1)} kg/da',
      ));
    }
    if (env?.humidityPct != null) {
      out.add(RecommendationEvidence(
        label: 'Hava nemi',
        value: '%${env!.humidityPct!.round()}',
      ));
    }
    if (env?.weeklyRainMm != null) {
      out.add(RecommendationEvidence(
        label: 'Haftalık yağış',
        value: '${env!.weeklyRainMm!.toStringAsFixed(1)} mm',
      ));
    }
    if (field != null) {
      out.add(RecommendationEvidence(
        label: 'Alan',
        value: '${field.areaDekar.toStringAsFixed(2)} da',
      ));
      out.add(RecommendationEvidence(
        label: 'Tahmini bitki',
        value: '${field.estimatedPlantCount}',
      ));
      if (field.weeklyWaterTargetMm > 0) {
        out.add(RecommendationEvidence(
          label: 'Haftalık su',
          value:
              '${field.weeklyWaterMm.toStringAsFixed(1)} / ${field.weeklyWaterTargetMm.toStringAsFixed(1)} mm',
        ));
      }
    }
    final source = ctx.environment?.source;
    if (source != null && source.trim().isNotEmpty) {
      out.add(RecommendationEvidence(label: 'Veri kaynağı', value: source));
    }
    return out;
  }

  bool _recentScouting(RuleEvaluationContext ctx, Duration window) =>
      ctx.hasActivityWithin(type: ActivityType.scouting, window: window);

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
    final env = ctx.environment;
    final heavyRainAhead = (_rainNext24h(ctx) ?? 0) > 12.0;
    final wetSurface = env?.isWetSoil == true;
    final coldEmergence = env?.isColdSoil == true;
    if (!wateredRecently && !heavyRainAhead && !wetSurface) return null;
    final hoedRecently = ctx.hasActivityWithin(
      type: ActivityType.hoeing,
      window: const Duration(days: 5),
    );
    if (hoedRecently) return null;
    final scaleBullet = _fieldScaleBullet(ctx);
    final sourceBullet = _envSource(ctx);
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
        if (wetSurface)
          'Toprak nemi %${(env!.soilMoisture! * 100).round()} seviyesinde',
        if (coldEmergence)
          'Toprak sıcaklığı ${env!.soilTempC!.toStringAsFixed(1)}°C; çıkış yavaşlayabilir',
        if (env?.soilPh != null)
          'pH ${env!.soilPh!.toStringAsFixed(1)} erken kök gelişimi hesabına katıldı',
        if (scaleBullet != null) scaleBullet,
        if (sourceBullet != null) sourceBullet,
        'Son 5 gündür çapalama kaydı yok',
      ],
      actionHint:
          'Sıra üstünde kabuk varsa hafif çapalama yapın; fideler kolay çıksın.',
      evidence: _evidence(ctx),
      command: const RecommendationCommand(
        activityType: ActivityType.hoeing,
        buttonLabel: 'Çapaladım',
      ),
      sourceRefs: SunflowerRuleSourceRefs.emergenceCrusting,
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
    final env = ctx.environment;
    final field = ctx.fieldState;
    final drySoil = env?.isDrySoil == true;
    final hotDryAir = env?.isHotDryAir == true;
    final weeklyBehind = field?.waterBehind == true;
    if (deficit < 30 && !dryStreak && !drySoil && !weeklyBehind && !hotDryAir) {
      return null;
    }
    // Yağmur geliyor → kural tetiklenmesin (forecast varsa).
    final rainAhead = _rainNext24h(ctx);
    if (rainAhead != null &&
        rainAhead > 8 &&
        deficit < 35 &&
        !drySoil &&
        !weeklyBehind) {
      return null;
    }
    final severity = deficit >= 30 || drySoil || weeklyBehind
        ? AlertSeverity.critical
        : AlertSeverity.warning;
    final weeklyWater = _weeklyWaterBullet(ctx);
    final scaleBullet = _fieldScaleBullet(ctx);
    final sourceBullet = _envSource(ctx);
    return Recommendation(
      ruleKey: 'sunflower.water_stress.flower.v1',
      severity: severity,
      target: RecommendationTarget.crop(
        fieldId: ctx.fieldId,
        cropId: ctx.crop.id,
      ),
      title: 'Çiçeklenmede su stresi',
      reasonText:
          'Ayçiçeğinin en kritik döneminde su açığı verim kaybına yol açıyor.',
      reasonBullets: [
        if (deficit >= 30) 'Su açığı yaklaşık ${deficit.round()} mm',
        if (dryStreak) 'Son sulama 5+ gün önce',
        if (drySoil)
          'Toprak nemi %${(env!.soilMoisture! * 100).round()} ile düşük',
        if (hotDryAir && env?.temperatureC != null)
          'Sıcak/kuru hava: ${env!.temperatureC!.toStringAsFixed(0)}°C',
        if (weeklyBehind && weeklyWater != null) weeklyWater,
        if (rainAhead == null) 'Yağış tahmini alınamadı (çevrimdışı)',
        if (scaleBullet != null) scaleBullet,
        if (sourceBullet != null) sourceBullet,
        'Çiçeklenme döneminde stres, dane bağlamayı düşürür',
      ],
      actionHint: _waterActionHint(
        ctx,
        base: 'Bugün sulama yapın; sabah 06:00–10:00 arası ideal.',
      ),
      evidence: _evidence(ctx),
      command: _waterCommand(ctx),
      sourceRefs: SunflowerRuleSourceRefs.floweringWaterStress,
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
    final env = ctx.environment;
    final field = ctx.fieldState;
    final drySoil = env?.isDrySoil == true;
    final weeklyBehind = field?.waterBehind == true;
    if (deficit < 25 && !drySoil && !weeklyBehind) return null;
    final rainAhead = _rainNext24h(ctx);
    if (rainAhead != null &&
        rainAhead > 8 &&
        deficit < 30 &&
        !drySoil &&
        !weeklyBehind) {
      return null;
    }
    final yieldLoss = ctx.growth?.yieldLossPct ?? 0;
    final weeklyWater = _weeklyWaterBullet(ctx);
    final scaleBullet = _fieldScaleBullet(ctx);
    final sourceBullet = _envSource(ctx);
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
        if (deficit > 0) 'Su açığı ${deficit.round()} mm',
        if (drySoil)
          'Toprak nemi %${(env!.soilMoisture! * 100).round()} ile düşük',
        if (weeklyBehind && weeklyWater != null) weeklyWater,
        if (yieldLoss > 0) 'Tahmini verim kaybı %$yieldLoss',
        if (scaleBullet != null) scaleBullet,
        if (sourceBullet != null) sourceBullet,
      ],
      actionHint: _waterActionHint(
        ctx,
        base: '24 saat içinde sulama yapın; gecikmeden uygulayın.',
      ),
      evidence: _evidence(ctx),
      command: _waterCommand(ctx),
      sourceRefs: SunflowerRuleSourceRefs.grainWaterStress,
      clearOnActivities: const [
        ClearOnActivity(
          activityType: ActivityType.watering,
          withinHours: 36,
        ),
      ],
      cooldownHours: 24,
    );
  }

  // ── Kural #6 — Besin + pH kaynaklı gelişme stresi ───────────────────
  /// Azot stresi, düşük NPK veya pH sınır dışıysa gübre/toprak düzenleme
  /// önerisi üretir. Son gübreleme tazeyse besin uyarısı bastırılır; pH
  /// problemi yine bilgi olarak kalır çünkü tek gübreleme ile temizlenmez.
  Recommendation? _nutrientAndPhStress(RuleEvaluationContext ctx) {
    final stage = ctx.growth?.stageKey;
    final days = ctx.crop.daysSincePlanted(ctx.now);
    final inSeason = stage == 'vejetatif' ||
        stage == 'tomurcuklanma' ||
        stage == 'ciceklenme' ||
        stage == 'meyve_dolumu' ||
        (stage == null && days != null && days >= 18 && days <= 105);
    if (!inSeason) return null;

    final env = ctx.environment;
    final nStress = ctx.growth?.nStressIdx ?? 0;
    final nLow = env?.nitrogenKgDekar != null && env!.nitrogenKgDekar! < 1.5;
    final pLow =
        env?.phosphorusKgDekar != null && env!.phosphorusKgDekar! < 4.0;
    final kLow = env?.potassiumKgDekar != null && env!.potassiumKgDekar! < 10.0;
    final ph = env?.soilPh;
    final phOut = ph != null && (ph < 6.0 || ph > 8.0);
    final hasNutrientSignal = nStress > 0.25 || nLow || pLow || kLow;
    if (!hasNutrientSignal && !phOut) return null;

    final fertilizedRecently = ctx.hasActivityWithin(
      type: ActivityType.fertilizing,
      window: const Duration(days: 14),
    );
    if (fertilizedRecently && !phOut) return null;

    final scaleBullet = _fieldScaleBullet(ctx);
    final sourceBullet = _envSource(ctx);
    final severity = nStress > 0.45 || (nLow && pLow)
        ? AlertSeverity.critical
        : AlertSeverity.warning;
    return Recommendation(
      ruleKey: 'sunflower.nutrition.ph_balance.v1',
      severity: severity,
      target: RecommendationTarget.crop(
        fieldId: ctx.fieldId,
        cropId: ctx.crop.id,
      ),
      title: 'Besin ve pH kontrolü',
      reasonText:
          'Ayçiçeğinde gelişme için besin/pH sinyalleri sınırda görünüyor.',
      reasonBullets: [
        if (nStress > 0.25) 'Azot stresi %${(nStress * 100).round()}',
        if (nLow)
          'Tahmini azot ${env.nitrogenKgDekar!.toStringAsFixed(1)} kg/da',
        if (pLow)
          'Tahmini fosfor ${env.phosphorusKgDekar!.toStringAsFixed(1)} kg/da',
        if (kLow)
          'Tahmini potasyum ${env.potassiumKgDekar!.toStringAsFixed(1)} kg/da',
        if (phOut) 'Toprak pH ${ph.toStringAsFixed(1)}; ideal aralık 6.0-8.0',
        if (fertilizedRecently)
          'Son 14 günde gübreleme kaydı var; doz tekrarı için gözlem gerekir',
        if (scaleBullet != null) scaleBullet,
        if (sourceBullet != null) sourceBullet,
      ],
      actionHint: phOut
          ? 'Yaprak rengi ve gelişmeyi kontrol edin; pH için toprak analiziyle kireç/kükürt planlayın, gübreyi bölerek uygulayın.'
          : 'Yaprak rengi soluksa üst gübrelemeyi bölerek yapın; dekara dozu alan ve bitki sayısına göre ayarlayın.',
      gate: phOut
          ? RecommendationGate.observeFirst
          : RecommendationGate.actionable,
      evidence: _evidence(ctx),
      command: RecommendationCommand(
        activityType: phOut ? ActivityType.scouting : ActivityType.fertilizing,
        subtype: phOut ? ActivitySubtype.note : null,
        buttonLabel: phOut ? 'Kontrol ettim' : 'Gübreledim',
        metadata: {
          if (!phOut) 'fertilizer_type': 'Üst gübre',
          if (phOut) 'control_reason': 'pH sınır dışı',
        },
      ),
      sourceRefs: SunflowerRuleSourceRefs.nutrientAndPhStress,
      clearOnActivities: const [
        ClearOnActivity(
          activityType: ActivityType.fertilizing,
          withinHours: 24 * 14,
        ),
      ],
      cooldownHours: 72,
    );
  }

  // ── Kural #8 — Nem/yağış + hastalık baskısı gözlemi ─────────────────
  /// Yağış, yüksek nem, ıslak toprak veya GrowthEngine hastalık baskısı
  /// aynı dönemde birleşirse önce gözlem önerir. Ayçiçeğinde kimyasal
  /// kararını eşik doğrulanmadan açmaz.
  Recommendation? _diseaseScoutingRisk(RuleEvaluationContext ctx) {
    final stage = ctx.growth?.stageKey;
    final days = ctx.crop.daysSincePlanted(ctx.now);
    final inWindow = stage == 'vejetatif' ||
        stage == 'tomurcuklanma' ||
        stage == 'ciceklenme' ||
        stage == 'meyve_dolumu' ||
        (stage == null && days != null && days >= 25 && days <= 105);
    if (!inWindow) return null;

    final env = ctx.environment;
    final pressure = ctx.growth?.diseasePressure ?? 0;
    final humid = env?.humidityPct != null && env!.humidityPct! >= 75;
    final wetSoil = env?.isWetSoil == true;
    final rainAhead = _rainNext24h(ctx) ?? 0;
    final rainyWeek = (env?.weeklyRainMm ?? 0) >= 20;
    if (pressure <= 0.35 && !humid && !wetSoil && rainAhead < 6 && !rainyWeek) {
      return null;
    }
    if (_recentScouting(ctx, const Duration(days: 4)) ||
        ctx.hasActivityWithin(
          type: ActivityType.spraying,
          window: const Duration(days: 7),
        )) {
      return null;
    }

    final scaleBullet = _fieldScaleBullet(ctx);
    final sourceBullet = _envSource(ctx);
    return Recommendation(
      ruleKey: 'sunflower.disease.scouting_env.v1',
      severity: pressure > 0.55 || (humid && wetSoil)
          ? AlertSeverity.critical
          : AlertSeverity.warning,
      target: RecommendationTarget.crop(
        fieldId: ctx.fieldId,
        cropId: ctx.crop.id,
      ),
      title: 'Hastalık gözlemi yap',
      reasonText:
          'Nem, yağış veya hastalık baskısı ayçiçeğinde risk oluşturuyor.',
      reasonBullets: [
        if (pressure > 0.35) 'Hastalık baskısı %${(pressure * 100).round()}',
        if (humid) 'Hava nemi %${env.humidityPct!.round()}',
        if (wetSoil)
          'Toprak nemi %${(env!.soilMoisture! * 100).round()} ile yüksek',
        if (rainAhead >= 6) '24 saat içinde ${rainAhead.round()} mm yağış',
        if (rainyWeek)
          'Haftalık yağış ${env!.weeklyRainMm!.toStringAsFixed(0)} mm',
        'Son 4 gün içinde gözlem kaydı yok',
        if (scaleBullet != null) scaleBullet,
        if (sourceBullet != null) sourceBullet,
      ],
      actionHint:
          'Alt yaprak, tabla arkası ve sapta leke/çürüme için gözlem yapın; eşik doğrulanmadan ilaçlama kaydı açmayın.',
      gate: RecommendationGate.observeFirst,
      evidence: _evidence(ctx),
      command: const RecommendationCommand(
        activityType: ActivityType.scouting,
        subtype: ActivitySubtype.diseaseObservation,
        buttonLabel: 'Gözlemledim',
        metadata: {'ipm_gate': 'observe_before_spray'},
      ),
      sourceRefs: SunflowerRuleSourceRefs.diseaseScouting,
      clearOnActivities: const [
        ClearOnActivity(
          activityType: ActivityType.scouting,
          withinHours: 24 * 4,
        ),
        ClearOnActivity(
          activityType: ActivityType.spraying,
          withinHours: 24 * 7,
        ),
      ],
      cooldownHours: 48,
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
    final env = ctx.environment;
    final tempC = env?.temperatureC;
    final windSpeed = env?.windSpeedMs;
    final pestWeather = tempC != null && tempC >= 20 && tempC <= 34;
    final windy = windSpeed != null && windSpeed >= 5;
    final scaleBullet = _fieldScaleBullet(ctx);
    final sourceBullet = _envSource(ctx);
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
                  ] +
                  [
                    if (pestWeather)
                      'Sıcaklık ${tempC.toStringAsFixed(0)}°C; zararlı aktivitesi için uygun',
                    if (windy)
                      'Rüzgar ${windSpeed.toStringAsFixed(1)} m/sn; ilaçlama penceresi sınırlı',
                    if (scaleBullet != null) scaleBullet,
                    if (sourceBullet != null) sourceBullet,
                  ],
              actionHint: windy
                  ? 'Tablada yumurta/tırtıl kontrolü yapın; rüzgar düşmeden ilaçlama yapmayın, sakin saatte etiket dozuna uyun.'
                  : 'Tablada yumurta/tırtıl kontrolü yapın; eşik doğrulanırsa yalnız ruhsatlı etiket ve il/ilçe teknik önerisiyle ilerleyin.',
              gate: RecommendationGate.observeFirst,
              evidence: _evidence(ctx),
              command: const RecommendationCommand(
                activityType: ActivityType.scouting,
                subtype: ActivitySubtype.pestObservation,
                buttonLabel: 'Zararlı gözlemi yaptım',
                metadata: {'ipm_gate': 'observe_before_spray'},
              ),
              sourceRefs: SunflowerRuleSourceRefs.pestHelicoverpa,
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
    final env = ctx.environment;
    final rainAhead = _rainNext24h(ctx) ?? 0;
    final humidHarvest = env?.humidityPct != null && env!.humidityPct! >= 75;
    final scaleBullet = _fieldScaleBullet(ctx);
    final sourceBullet = _envSource(ctx);
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
        if (rainAhead >= 5) '24 saat içinde ${rainAhead.round()} mm yağış var',
        if (humidHarvest) 'Hava nemi %${env.humidityPct!.round()}',
        if (scaleBullet != null) scaleBullet,
        if (sourceBullet != null) sourceBullet,
        'Son 7 gün içinde hasat kaydı yok',
      ],
      actionHint: rainAhead >= 5 || humidHarvest
          ? 'Tabla arkası sarı-kahverengiyse yağış/nem artmadan hasadı öne alın; nem yüksekse depolamadan önce kurutun.'
          : 'Tablanın arkası sarı-kahverengi olduğunda 5–7 gün içinde hasat edin.',
      evidence: _evidence(ctx),
      command: const RecommendationCommand(
        activityType: ActivityType.harvest,
        buttonLabel: 'Hasat ettim',
      ),
      sourceRefs: SunflowerRuleSourceRefs.harvestReady,
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
