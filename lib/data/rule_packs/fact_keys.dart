/// CLAUDE.md sec 15 — Kural motoruna verilen `facts` haritası için
/// stabil alan anahtarları. Tek tipte string sabitler; üretici/tüketici
/// aynı string'lere bağlanır, typo'yu derleme zamanında yakalar.
///
/// Yeni alan eklendiğinde:
///   1) Buraya sabit ekle.
///   2) `lib/core/rule_engine/fact_builder.dart` içine map et.
///   3) Test case ekle.
///   4) Geriye dönük kırılma olmadığını doğrula.
class FactKeys {
  FactKeys._();

  // ─── Bitki kimliği ───────────────────────────────────────────────
  static const cropId = 'crop_id';
  static const cropName = 'crop_name';

  // ─── Bölge / yetiştirme tipi ──────────────────────────────────────
  // Değerler: 'trakya'|'ege'|'akdeniz'|'ic_anadolu'|'gap'|'karadeniz'|'dogu_anadolu'
  static const region = 'region';
  // 'open_field'|'greenhouse'|'tunnel'|'orchard'
  static const cultivationType = 'cultivation_type';
  // 'dryland'|'irrigated'
  static const waterRegime = 'water_regime';

  // ─── Zaman / fenoloji ─────────────────────────────────────────────
  static const month = 'month'; // 1..12
  static const daysAfterPlanting = 'days_after_planting';
  // 'germination'|'emergence'|'vegetative'|'pre_flowering'|'flowering'|
  // 'grain_filling'|'maturity'|'harvest'|'dormant'
  static const growthStage = 'growth_stage';
  static const gddAccumulated = 'gdd_accumulated';

  // ─── Toprak ──────────────────────────────────────────────────────
  static const soilPh = 'soil_ph';
  static const soilEc = 'soil_ec_ds_m';
  static const organicMatterPct = 'organic_matter_pct';
  static const soilMoisture = 'soil_moisture'; // 0..1
  static const soilTempC = 'soil_temp_c';
  // 'sandy'|'sandy_loam'|'loam'|'clay_loam'|'clay'|'silt'|'calcareous'
  static const soilType = 'soil_type';
  static const npkN = 'npk_n_kg_dekar';
  static const npkP = 'npk_p_kg_dekar';
  static const npkK = 'npk_k_kg_dekar';
  // 'low'|'medium'|'high' — toprak analizine göre sınıf
  static const nLevel = 'soil_n_level';
  static const pLevel = 'soil_p_level';
  static const kLevel = 'soil_k_level';

  // ─── Hava / iklim ────────────────────────────────────────────────
  static const tempC = 'temperature_c';
  static const tempMin24hC = 'temp_min_24h_c';
  static const tempMax24hC = 'temp_max_24h_c';
  static const humidityPct = 'humidity_pct';
  // 'low'|'medium'|'high' — UI/sensor tarafından bağlanır
  static const humidityLevel = 'humidity_level';
  static const weeklyRainMm = 'weekly_rain_mm';
  static const forecastRain24hMm = 'forecast_rain_24h_mm';
  static const forecastRain48hMm = 'forecast_rain_48h_mm';
  static const windSpeedMs = 'wind_speed_ms';
  static const frostRiskNext48h = 'frost_risk_next_48h'; // bool
  static const hailRiskNext24h = 'hail_risk_next_24h'; // bool
  static const heatStressNext48h = 'heat_stress_next_48h'; // bool

  // ─── Tarla durumu ────────────────────────────────────────────────
  static const fieldAreaDekar = 'field_area_dekar';
  static const estimatedPlantCount = 'estimated_plant_count';
  static const weeklyWaterMm = 'weekly_water_mm';
  static const weeklyWaterTargetMm = 'weekly_water_target_mm';
  static const weeklyWaterRatio = 'weekly_water_ratio';
  static const weeklyWaterMissingMm = 'weekly_water_missing_mm';

  // ─── Aktivite zamanları ───────────────────────────────────────────
  static const lastWateredHoursAgo = 'last_watered_hours_ago';
  static const lastFertilizedDaysAgo = 'last_fertilized_days_ago';
  static const lastSprayedDaysAgo = 'last_sprayed_days_ago';
  static const lastTillageDaysAgo = 'last_tillage_days_ago';
  static const lastScoutingDaysAgo = 'last_scouting_days_ago';

  // ─── Gözlem / belirti ─────────────────────────────────────────────
  // Hastalık belirti kodu: 'grey_mold'|'leaf_spot'|'downy_mildew'|
  // 'powdery_mildew'|'stem_rot'|'head_rot'|'rust'|'wilt'|'anthracnose'
  static const observedSymptom = 'observed_symptom';
  // Zararlı kodu: 'aphid'|'whitefly'|'helicoverpa'|'thrips'|'mite'|'stem_borer'
  static const observedPest = 'observed_pest';
  // Yabani ot: 'orobanche'|'amaranthus'|'chenopodium'|'sorghum_halepense'
  static const observedWeed = 'observed_weed';
  // Belirti konumu: 'leaf'|'stem'|'root'|'head'|'fruit'
  static const symptomLocation = 'symptom_location';
  // 'healthy'|'mixed'|'diseased_majority'|'dead'
  static const plantHealthSummary = 'plant_health_summary';
  static const diseaseIncidencePct = 'disease_incidence_pct'; // 0..100
  static const pestPopulationLevel = 'pest_population_level'; // 'below_threshold'|'at_threshold'|'above_threshold'

  // ─── Sera özel ───────────────────────────────────────────────────
  static const greenhouseVentilation = 'greenhouse_ventilation'; // 'low'|'medium'|'high'
  static const leafWetnessHours = 'leaf_wetness_hours';
}
