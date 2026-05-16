import '../../data/activity_types.dart';
import '../../data/rule_packs/disease_type_mapping.dart';
import '../../data/rule_packs/fact_keys.dart';
import '../../models/plant_condition.dart';
import '../../services/rules/crop_rule_set.dart';

/// CLAUDE.md sec 15 — `RuleEvaluationContext` → `facts` haritası.
///
/// Tek tipte: null değerler haritaya hiç konulmaz; `missing` operatörü
/// onu doğru raporlasın diye. Auto-derivation yapar:
///   • `growth.stageKey` (TR) → `growth_stage` (EN) çevirir
///   • `recentActivities` → `last_*_days_ago` saatlerini hesaplar
///   • `plantInstances.conditionFlags` → `plant_health_summary` ve
///     `observed_symptom` türetir
///   • `ctx.cultivationType/region/soilType/...` doğrudan facts'e işler
class FactBuilder {
  FactBuilder._();

  /// CLAUDE.md sec 14 — saf fonksiyon; aynı `ctx` + aynı `extra` her zaman
  /// aynı facts haritasını üretir.
  static Map<String, Object?> build({
    required RuleEvaluationContext ctx,
    Map<String, Object?> extra = const {},
  }) {
    final f = <String, Object?>{};
    f[FactKeys.cropId] = ctx.crop.id;
    f[FactKeys.cropName] = ctx.crop.name;

    final dap = ctx.crop.daysSincePlanted(ctx.now);
    if (dap != null) f[FactKeys.daysAfterPlanting] = dap;
    f[FactKeys.month] = ctx.now.month;

    // ── Meta alanları (ctx üzerinden gelir) ──────────────────────────
    if (ctx.cultivationType != null) {
      f[FactKeys.cultivationType] = ctx.cultivationType;
    }
    if (ctx.waterRegime != null) f[FactKeys.waterRegime] = ctx.waterRegime;
    if (ctx.region != null) f[FactKeys.region] = ctx.region;
    if (ctx.soilType != null) f[FactKeys.soilType] = ctx.soilType;
    if (ctx.nLevel != null) f[FactKeys.nLevel] = ctx.nLevel;
    if (ctx.pLevel != null) f[FactKeys.pLevel] = ctx.pLevel;
    if (ctx.kLevel != null) f[FactKeys.kLevel] = ctx.kLevel;

    // ── Fenoloji evresi: TR → EN ─────────────────────────────────────
    final stageEn = _mapStageKey(ctx.growth?.stageKey);
    if (stageEn != null) f[FactKeys.growthStage] = stageEn;
    if (ctx.growth?.accumulatedGdd != null) {
      f[FactKeys.gddAccumulated] = ctx.growth!.accumulatedGdd;
    }

    // ── Toprak / NPK / hava (ctx.environment) ────────────────────────
    final env = ctx.environment;
    if (env != null) {
      if (env.soilPh != null) f[FactKeys.soilPh] = env.soilPh;
      if (env.soilMoisture != null) f[FactKeys.soilMoisture] = env.soilMoisture;
      if (env.soilTempC != null) f[FactKeys.soilTempC] = env.soilTempC;
      if (env.nitrogenKgDekar != null) f[FactKeys.npkN] = env.nitrogenKgDekar;
      if (env.phosphorusKgDekar != null) {
        f[FactKeys.npkP] = env.phosphorusKgDekar;
      }
      if (env.potassiumKgDekar != null) {
        f[FactKeys.npkK] = env.potassiumKgDekar;
      }
      if (env.temperatureC != null) f[FactKeys.tempC] = env.temperatureC;
      if (env.humidityPct != null) {
        f[FactKeys.humidityPct] = env.humidityPct;
        f[FactKeys.humidityLevel] = _humidityLevel(env.humidityPct!);
      }
      if (env.windSpeedMs != null) f[FactKeys.windSpeedMs] = env.windSpeedMs;
      if (env.weeklyRainMm != null) f[FactKeys.weeklyRainMm] = env.weeklyRainMm;
    }

    // NPK kategorileri otomatik türet — analiz raporu kg/dekar varsa.
    f[FactKeys.nLevel] ??= _nutrientLevel(env?.nitrogenKgDekar, n: true);
    f[FactKeys.pLevel] ??= _nutrientLevel(env?.phosphorusKgDekar, p: true);
    f[FactKeys.kLevel] ??= _nutrientLevel(env?.potassiumKgDekar, k: true);
    // null değerleri kaldır
    if (f[FactKeys.nLevel] == null) f.remove(FactKeys.nLevel);
    if (f[FactKeys.pLevel] == null) f.remove(FactKeys.pLevel);
    if (f[FactKeys.kLevel] == null) f.remove(FactKeys.kLevel);

    // ── Hava tahmini ─────────────────────────────────────────────────
    final hourly = ctx.hourly;
    if (hourly != null) {
      f[FactKeys.forecastRain24hMm] = hourly.rainSumNext(24);
      f[FactKeys.forecastRain48hMm] = hourly.rainSumNext(48);
      final tMax = hourly.maxTempNext(24);
      if (tMax != null) f[FactKeys.tempMax24hC] = tMax;
      final tMin = hourly.minTempNext(24);
      if (tMin != null) f[FactKeys.tempMin24hC] = tMin;
      if (tMin != null && tMin <= 1.0) f[FactKeys.frostRiskNext48h] = true;
      if (tMax != null && tMax >= 35.0) f[FactKeys.heatStressNext48h] = true;
    }

    // ── Tarla durumu ─────────────────────────────────────────────────
    final fs = ctx.fieldState;
    if (fs != null) {
      f[FactKeys.fieldAreaDekar] = fs.areaDekar;
      f[FactKeys.estimatedPlantCount] = fs.estimatedPlantCount;
      f[FactKeys.weeklyWaterMm] = fs.weeklyWaterMm;
      f[FactKeys.weeklyWaterTargetMm] = fs.weeklyWaterTargetMm;
      f[FactKeys.weeklyWaterRatio] = fs.weeklyWaterRatio;
      f[FactKeys.weeklyWaterMissingMm] = fs.weeklyWaterMissingMm;
    }

    // ── Aktivite geçmişi → "ago" facts ───────────────────────────────
    final lastWatered = ctx.lastActivityAt(type: ActivityType.watering);
    if (lastWatered != null) {
      f[FactKeys.lastWateredHoursAgo] =
          ctx.now.difference(lastWatered).inHours;
    }
    final lastFert = ctx.lastActivityAt(type: ActivityType.fertilizing);
    if (lastFert != null) {
      f[FactKeys.lastFertilizedDaysAgo] =
          ctx.now.difference(lastFert).inDays;
    }
    final lastSpray = ctx.lastActivityAt(type: ActivityType.spraying);
    if (lastSpray != null) {
      f[FactKeys.lastSprayedDaysAgo] =
          ctx.now.difference(lastSpray).inDays;
    }
    final lastScout = ctx.lastActivityAt(type: ActivityType.scouting);
    if (lastScout != null) {
      f[FactKeys.lastScoutingDaysAgo] =
          ctx.now.difference(lastScout).inDays;
    }

    // ── Bitki sağlığı özeti + gözlem ─────────────────────────────────
    final healthSummary = _summarizeHealth(ctx.plantInstances);
    if (healthSummary != null) {
      f[FactKeys.plantHealthSummary] = healthSummary;
    }
    final symptom = _dominantSymptom(ctx.plantInstances);
    if (symptom != null) f[FactKeys.observedSymptom] = symptom;
    final pest = _dominantPest(ctx.plantInstances);
    if (pest != null) f[FactKeys.observedPest] = pest;
    final incidence = _diseaseIncidence(ctx.plantInstances);
    if (incidence != null) f[FactKeys.diseaseIncidencePct] = incidence;

    // ── Çağıran tarafın eklediği facts (override yapabilir) ──────────
    for (final entry in extra.entries) {
      if (entry.value == null) {
        f.remove(entry.key);
      } else {
        f[entry.key] = entry.value;
      }
    }

    return f;
  }

  /// `GrowthSnapshot.stageKey` Türkçe → rule pack English (CLAUDE.md sec 22
  /// "saf fonksiyon" prensibi — aynı girdi aynı çıktı).
  /// Eşleşme yoksa null; declarative kurallar bu durumda evre içermez.
  static String? _mapStageKey(String? trStage) {
    if (trStage == null) return null;
    switch (trStage) {
      case 'cimlenme':
        return 'germination';
      case 'vejetatif':
        return 'vegetative';
      case 'ciceklenme':
        return 'flowering';
      case 'meyve_dolumu':
        return 'grain_filling';
      case 'olgunlasma':
        return 'maturity';
      default:
        return null;
    }
  }

  static String _humidityLevel(double pct) {
    if (pct >= 75) return 'high';
    if (pct >= 50) return 'medium';
    return 'low';
  }

  /// kg/dekar değerini 'low'|'medium'|'high'a böler.
  /// Eşikler genel referanstır; bölgesel kalibrasyon için tek noktadan
  /// güncellenmelidir. Toprak analizi yoksa null döner — CLAUDE.md sec
  /// 16 "kaynaksız doz" kuralını korumak için.
  static String? _nutrientLevel(double? kg,
      {bool n = false, bool p = false, bool k = false}) {
    if (kg == null || kg < 0) return null;
    if (n) {
      if (kg < 5) return 'low';
      if (kg < 12) return 'medium';
      return 'high';
    }
    if (p) {
      if (kg < 2) return 'low';
      if (kg < 6) return 'medium';
      return 'high';
    }
    if (k) {
      if (kg < 10) return 'low';
      if (kg < 25) return 'medium';
      return 'high';
    }
    return null;
  }

  /// Bitki sağlık dağılımını özetler: tüm bitkilerin > %50'si "diseased"
  /// veya "dead" ise 'diseased_majority'; karışıksa 'mixed'; aksi halde
  /// 'healthy'. Boş listede null.
  static String? _summarizeHealth(List<PlantInstanceSnapshot> instances) {
    if (instances.isEmpty) return null;
    var healthy = 0, diseased = 0, dead = 0;
    for (final p in instances) {
      switch (p.healthStatus) {
        case 'healthy':
          healthy++;
          break;
        case 'diseased':
        case 'treating':
          diseased++;
          break;
        case 'dead':
          dead++;
          break;
      }
    }
    final total = healthy + diseased + dead;
    if (total == 0) return null;
    if ((diseased + dead) > total * 0.5) return 'diseased_majority';
    if (diseased + dead > 0) return 'mixed';
    return 'healthy';
  }

  /// Hastalık belirtisi gözlenen ilk bitkinin sembolünü `observed_symptom`
  /// fact'ine çevirir. Öncelik sırası:
  ///   1) `instance.diseaseType` (Türkçe) → `DiseaseTypeMapping.toSymptomKey`
  ///   2) `PlantCondition.diseaseSymptom` bayrağı + `healthStatus='diseased'`
  ///      → generic `leaf_spot` (en sık belirti)
  /// Hiçbiri yoksa null — kural tetiklenmez.
  static String? _dominantSymptom(List<PlantInstanceSnapshot> instances) {
    // 1) Önce spesifik diseaseType'ı olan bir bitki var mı?
    for (final p in instances) {
      final mapped = DiseaseTypeMapping.toSymptomKey(p.diseaseType);
      if (mapped != null) return mapped;
    }
    // 2) Spesifik tip yoksa flags/health üzerinden generic fallback.
    for (final p in instances) {
      if (p.hasCondition(PlantCondition.diseaseSymptom) ||
          p.healthStatus == 'diseased') {
        return 'leaf_spot';
      }
    }
    return null;
  }

  /// Zararlı bayrağı varsa generic 'helicoverpa' (en sık eşik üstü riskli
  /// zararlı). Spesifik tip extra map ile override edilir.
  static String? _dominantPest(List<PlantInstanceSnapshot> instances) {
    for (final p in instances) {
      if (p.hasCondition(PlantCondition.pestRisk)) {
        return 'helicoverpa';
      }
    }
    return null;
  }

  /// Tarlanın hastalık görülen bitkilerinin oranı (0-100).
  static double? _diseaseIncidence(List<PlantInstanceSnapshot> instances) {
    if (instances.isEmpty) return null;
    final affected = instances.where((p) {
      return p.healthStatus == 'diseased' ||
          p.healthStatus == 'dead' ||
          p.hasCondition(PlantCondition.diseaseSymptom);
    }).length;
    return (affected / instances.length) * 100.0;
  }
}
