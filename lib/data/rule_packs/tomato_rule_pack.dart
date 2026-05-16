import '../../core/rule_engine/rule.dart';
import 'fact_keys.dart';
import 'rule_pack_dsl.dart';
import 'rule_pack_sources.dart';

/// CLAUDE.md sec 11 — `crop.tomato` için deterministik kural paketi.
///
/// Domates Türkiye'de hem **açık alan** hem **sera** koşullarında yaygın.
/// Bu pack iki üretim sistemini `cultivation_type` fact'i üzerinden ayırır:
///   - `open_field`: yağış + nem hastalık riskini doğal koşulla belirler.
///   - `greenhouse`: havalandırma + nem yönetimi kullanıcı sorumluluğunda;
///     Botrytis ve külleme riski yüksek.
///
/// **Bu pack'in özgün noktaları:**
///   - **Botrytis (kurşuni küf) sera + yüksek nem** — CLAUDE.md sec 14 örnek
///     kuralının uygulaması.
///   - **Tuta absoluta (domates güvesi)** Türkiye'de en yıkıcı zararlı —
///     feromon izleme + biyolojik mücadele öncelikli.
///   - **Mildiyö** açık alanda yağışlı dönemde kritik.
///
/// **CLAUDE.md sec 17 BKÜ kırmızı çizgisi**: Kimyasal mücadele kuralları
/// `bku: true` taşır.
/// **CLAUDE.md sec 16 gübre kırmızı çizgisi**: Toprak analizi yoksa
/// kesin doz önerilmez.
class TomatoRulePack {
  TomatoRulePack._();

  static const _cropId = 'crop.tomato';
  static const _cropFact = FactKeys.cropId;

  static List<Rule> all() => [
        ..._suitability(),
        ..._soilAndSowing(),
        ..._growthStages(),
        ..._fertilization(),
        ..._irrigation(),
        ..._harvest(),
        ..._diseasesGeneral(),
        ..._diseasesGreenhouse(),
        ..._pests(),
        ..._weatherWarnings(),
      ];

  // ════════════════════════════════════════════════════════════════════
  // 1) SUITABILITY
  // ════════════════════════════════════════════════════════════════════
  static List<Rule> _suitability() {
    const cat = RuleCategories.suitability;
    final ev = pendingEvidence(SourceIds.tomatoAgronomy);
    final c = eq(_cropFact, _cropId);
    return [
      rule(
        id: 'rule.tomato.suit.region_mediterranean',
        category: cat,
        priority: 60,
        when: [
          c,
          isIn(FactKeys.region, ['akdeniz', 'ege']),
        ],
        recs: ['Akdeniz/Ege domates için ideal — uzun yetiştirme sezonu.'],
        confidence: 'high',
        evidence: ev,
      ),
      rule(
        id: 'rule.tomato.suit.region_open_field_cold',
        category: cat,
        priority: 65,
        risk: 'medium',
        when: [
          c,
          eq(FactKeys.cultivationType, 'open_field'),
          isIn(FactKeys.region, ['ic_anadolu', 'dogu_anadolu']),
        ],
        recs: [
          'Bu bölgede açık alan domates kısa sezonda yetişir — erken çeşit + örtü/tünel ile uzatma düşünün.',
        ],
        confidence: 'medium',
        evidence: ev,
      ),
      rule(
        id: 'rule.tomato.suit.greenhouse_year_round',
        category: cat,
        priority: 55,
        when: [c, eq(FactKeys.cultivationType, 'greenhouse')],
        recs: [
          'Sera koşulu yıl boyu üretime imkân verir — havalandırma + nem yönetimi kritik.',
        ],
        confidence: 'high',
        evidence: ev,
      ),
      rule(
        id: 'rule.tomato.suit.ph_optimal',
        category: cat,
        priority: 50,
        when: [c, between(FactKeys.soilPh, 6.0, 6.8)],
        recs: ['Toprak pH değeri domates için ideal (6.0-6.8).'],
        confidence: 'high',
        evidence: ev,
      ),
      rule(
        id: 'rule.tomato.suit.ph_acidic',
        category: cat,
        priority: 65,
        risk: 'medium',
        when: [c, lt(FactKeys.soilPh, 5.5)],
        recs: [
          'Toprak asidik (pH < 5.5) — fosfor + kalsiyum alımı düşer; çiçek burnu çürüklüğü riski.',
        ],
        confidence: 'medium',
        evidence: ev,
        expert: true,
      ),
      rule(
        id: 'rule.tomato.suit.ph_alkaline',
        category: cat,
        priority: 60,
        risk: 'medium',
        when: [c, gt(FactKeys.soilPh, 7.5)],
        recs: [
          'Toprak alkali (pH > 7.5) — demir, çinko, mangan kloroz riski.',
        ],
        confidence: 'medium',
        evidence: ev,
      ),
      rule(
        id: 'rule.tomato.suit.salinity_high',
        category: cat,
        priority: 75,
        risk: 'high',
        when: [c, gt(FactKeys.soilEc, 2.5)],
        recs: [
          'EC > 2.5 dS/m — domates orta-yüksek tuzluluk hassaslığı, verim ve kalite düşer.',
          'Yıkama sulaması + organik madde takviyesi gerekir.',
        ],
        confidence: 'medium',
        evidence: ev,
      ),
    ];
  }

  // ════════════════════════════════════════════════════════════════════
  // 2) SOIL & SOWING
  // ════════════════════════════════════════════════════════════════════
  static List<Rule> _soilAndSowing() {
    const cat = RuleCategories.sowingOrPlanting;
    final ev = pendingEvidence(SourceIds.tomatoAgronomy);
    final c = eq(_cropFact, _cropId);
    return [
      rule(
        id: 'rule.tomato.soil.no_analysis',
        category: RuleCategories.soilAnalysis,
        priority: 90,
        risk: 'medium',
        when: [c, missing(FactKeys.soilPh)],
        recs: [
          'Toprak analizi yapılmamış. Ekim öncesi pH, EC, organik madde, N-P-K analizi yaptırın.',
          'Analiz olmadan kesin gübre miktarı önerilemez (CLAUDE.md sec 16).',
        ],
        confidence: 'high',
        evidence: ev,
      ),
      rule(
        id: 'rule.tomato.sowing.season_open_field',
        category: cat,
        priority: 60,
        when: [
          c,
          eq(FactKeys.cultivationType, 'open_field'),
          isIn(FactKeys.month, [3, 4, 5]),
        ],
        recs: [
          'Açık alan domates dikim dönemi (Mart-Mayıs). Don riski geçtikten sonra fide şaşırtın.',
        ],
        confidence: 'high',
        evidence: ev,
      ),
      rule(
        id: 'rule.tomato.sowing.cold_soil_warning',
        category: cat,
        priority: 75,
        risk: 'medium',
        when: [
          c,
          eq(FactKeys.cultivationType, 'open_field'),
          lt(FactKeys.soilTempC, 12),
        ],
        recs: [
          'Toprak sıcaklığı 12 °C altında — domates fidesi gelişmez, kök çürüme riski. Daha sıcak güne bekleyin.',
        ],
        confidence: 'high',
        evidence: ev,
      ),
    ];
  }

  // ════════════════════════════════════════════════════════════════════
  // 3) GROWTH STAGES
  // ════════════════════════════════════════════════════════════════════
  static List<Rule> _growthStages() {
    const cat = RuleCategories.taskGeneration;
    final ev = pendingEvidence(SourceIds.tomatoAgronomy);
    final c = eq(_cropFact, _cropId);
    return [
      rule(
        id: 'rule.tomato.stage.flowering_start',
        category: cat,
        priority: 70,
        when: [
          c,
          isIn(FactKeys.growthStage, ['flowering'])
        ],
        recs: [
          'Çiçeklenme döneminde sulama + kalsiyum kritik — çiçek burnu çürüklüğü (BER) önlenir.',
        ],
        confidence: 'high',
        evidence: ev,
      ),
      rule(
        id: 'rule.tomato.stage.fruit_set',
        category: cat,
        priority: 65,
        when: [
          c,
          isIn(FactKeys.growthStage, ['flowering']),
          gt(FactKeys.tempMax24hC, 32),
        ],
        recs: [
          'Sıcaklık 32 °C üstüne çıkarsa polenler döllenmez — çiçek dökümü artar.',
          'Sera ise havalandır ve gölgele; açık alanda mümkünse gölgeleme.',
        ],
        confidence: 'medium',
        evidence: ev,
      ),
      rule(
        id: 'rule.tomato.stage.koltuk_alma',
        category: cat,
        priority: 55,
        when: [
          c,
          isIn(FactKeys.growthStage, ['vegetative', 'flowering'])
        ],
        recs: [
          'Düzenli koltuk alma (yan sürgün temizliği) bitkinin enerjisini meyveye yönlendirir.',
          'Koltuklar yağışlı havada kesilmemeli — yaranın kurumasına izin verin.',
        ],
        confidence: 'medium',
        evidence: ev,
      ),
    ];
  }

  // ════════════════════════════════════════════════════════════════════
  // 4) FERTILIZATION
  // ════════════════════════════════════════════════════════════════════
  static List<Rule> _fertilization() {
    const cat = RuleCategories.fertilization;
    final ev = pendingEvidence(SourceIds.tomatoAgronomy);
    final c = eq(_cropFact, _cropId);
    return [
      rule(
        id: 'rule.tomato.fert.no_analysis_no_dose',
        category: cat,
        priority: 95,
        risk: 'high',
        when: [c, missing(FactKeys.soilPh)],
        recs: [
          'Toprak analizi yok — kesin gübre dozu önerilemez (CLAUDE.md sec 16).',
          'Genel: domates yüksek N + K, orta P ister; sera + fertigasyonda azot bölünmüş uygulanır.',
        ],
        confidence: 'high',
        evidence: ev,
      ),
      rule(
        id: 'rule.tomato.fert.calcium_ber_prevention',
        category: cat,
        priority: 75,
        risk: 'medium',
        when: [
          c,
          exists(FactKeys.soilPh),
          isIn(FactKeys.growthStage, ['flowering']),
        ],
        recs: [
          'Çiçek burnu çürüklüğü (BER) — kalsiyum eksikliği + dengesiz sulama. Düzenli sulama + Ca(NO3)2 yaprak gübresi önler.',
        ],
        confidence: 'high',
        evidence: ev,
      ),
      rule(
        id: 'rule.tomato.fert.potassium_fruit_growth',
        category: cat,
        priority: 60,
        when: [
          c,
          exists(FactKeys.soilPh),
          isIn(FactKeys.growthStage, ['flowering']),
        ],
        recs: [
          'Meyve büyümesi döneminde potasyum kritik — meyve şekli, rengi ve raf ömrü için.',
        ],
        confidence: 'medium',
        evidence: ev,
      ),
      rule(
        id: 'rule.tomato.fert.excess_nitrogen',
        category: cat,
        priority: 65,
        risk: 'medium',
        when: [c, eq(FactKeys.nLevel, 'high')],
        recs: [
          'Aşırı azot vejetatif aşırı büyüme + çiçeklenme gecikmesi + hastalık duyarlılığı yapar. Bu sezon azotu azaltın.',
        ],
        confidence: 'medium',
        evidence: ev,
      ),
    ];
  }

  // ════════════════════════════════════════════════════════════════════
  // 5) IRRIGATION
  // ════════════════════════════════════════════════════════════════════
  static List<Rule> _irrigation() {
    const cat = RuleCategories.irrigation;
    final ev = pendingEvidence(SourceIds.tomatoAgronomy);
    final c = eq(_cropFact, _cropId);
    return [
      rule(
        id: 'rule.tomato.irrig.drip_preferred',
        category: cat,
        priority: 55,
        when: [c],
        recs: [
          'Damla sulama tercih edilir — yaprak ıslaklığı (mildiyö/Botrytis riski) düşer, su verimi artar.',
        ],
        confidence: 'high',
        evidence: ev,
      ),
      rule(
        id: 'rule.tomato.irrig.uneven_water_ber',
        category: cat,
        priority: 80,
        risk: 'high',
        when: [
          c,
          isIn(FactKeys.growthStage, ['flowering']),
          gt(FactKeys.weeklyWaterMissingMm, 15),
        ],
        recs: [
          'Çiçeklenme + meyve oluşum döneminde su eksikliği → çiçek burnu çürüklüğü (BER) kapısı açılır.',
          'Düzenli (her gün veya 2 günde 1) sulama yapın; uzun aralık + ani bol su BER tetikler.',
        ],
        confidence: 'high',
        evidence: ev,
      ),
    ];
  }

  // ════════════════════════════════════════════════════════════════════
  // 6) HARVEST
  // ════════════════════════════════════════════════════════════════════
  static List<Rule> _harvest() {
    const cat = RuleCategories.harvest;
    final ev = pendingEvidence(SourceIds.tomatoAgronomy);
    final c = eq(_cropFact, _cropId);
    return [
      rule(
        id: 'rule.tomato.harvest.ready_color',
        category: cat,
        priority: 70,
        when: [c, gt(FactKeys.daysAfterPlanting, 70)],
        recs: [
          'Hasat olgunluğu: hedeflenen kullanıma göre — uzak pazar için pembe (turning), yerel için kırmızı (ripe).',
          'Erken hasat raf ömrünü uzatır ama tat-aromayı azaltır.',
        ],
        confidence: 'high',
        evidence: ev,
      ),
      rule(
        id: 'rule.tomato.harvest.frost_emergency',
        category: cat,
        priority: 90,
        risk: 'high',
        when: [
          c,
          eq(FactKeys.frostRiskNext48h, true),
          eq(FactKeys.cultivationType, 'open_field'),
        ],
        recs: [
          'Açık alanda don bekleniyor — hasat hazır meyveleri öncelikle toplayın; donmuş meyve tüketilemez.',
        ],
        confidence: 'high',
        evidence: ev,
      ),
    ];
  }

  // ════════════════════════════════════════════════════════════════════
  // 7) DISEASES (GENERAL) — Açık alan ve sera ortak
  // ════════════════════════════════════════════════════════════════════
  static List<Rule> _diseasesGeneral() {
    const cat = RuleCategories.diseaseRisk;
    final c = eq(_cropFact, _cropId);
    return [
      rule(
        id: 'rule.tomato.disease.mildew_open_field',
        category: cat,
        priority: 85,
        risk: 'high',
        when: [
          c,
          eq(FactKeys.cultivationType, 'open_field'),
          gt(FactKeys.forecastRain48hMm, 30),
          eq(FactKeys.humidityLevel, 'high'),
        ],
        recs: [
          'Mildiyö (Phytophthora infestans) için ideal koşul — sürekli yaprak ıslaklığı + serin nem.',
          'Yaprak ıslaklığını azalt (alttan sulama); BKÜ etiketinde ruhsatlı koruyucu fungisit önleyici uygulanabilir.',
        ],
        confidence: 'high',
        evidence: pendingEvidence(SourceIds.tomatoOpenFieldIpm),
        expert: true,
        bku: true,
        problemId: 'disease.tomato.late_blight',
      ),
      rule(
        id: 'rule.tomato.disease.early_blight',
        category: cat,
        priority: 70,
        risk: 'medium',
        when: [
          c,
          eq(FactKeys.observedSymptom, 'leaf_spot'),
        ],
        recs: [
          'Erken yaprak yanıklığı (Alternaria) — alt yapraklardan başlayan halkalı kahverengi lekeler.',
          'Hastalıklı yaprakları temizleyin; havalandırma + alttan sulama yapın. BKÜ etiket kontrolü ile fungisit.',
        ],
        confidence: 'medium',
        evidence: pendingEvidence(SourceIds.tomatoOpenFieldIpm),
        expert: true,
        bku: true,
        problemId: 'disease.tomato.early_blight',
      ),
      rule(
        id: 'rule.tomato.disease.ber',
        category: cat,
        priority: 75,
        risk: 'medium',
        when: [c, eq(FactKeys.observedSymptom, 'fruit')],
        recs: [
          'Çiçek burnu çürüklüğü (BER) — fizyolojik bozukluk, mantar değil. Kalsiyum eksikliği + dengesiz sulama.',
          'Düzenli sulama + Ca(NO3)2 yaprak gübresi. Etkilenen meyveler tüketilebilir ama yan büyüme kalitesizdir.',
        ],
        confidence: 'high',
        evidence: pendingEvidence(SourceIds.tomatoAgronomy),
        problemId: 'disease.tomato.ber',
      ),
    ];
  }

  // ════════════════════════════════════════════════════════════════════
  // 8) DISEASES (GREENHOUSE) — Sera ortamı özel
  // CLAUDE.md sec 14 örnek kuralının uygulaması: Botrytis × yüksek nem × sera
  // ════════════════════════════════════════════════════════════════════
  static List<Rule> _diseasesGreenhouse() {
    const cat = RuleCategories.diseaseRisk;
    final ev = pendingEvidence(SourceIds.tomatoGreenhouseIpm);
    final c = eq(_cropFact, _cropId);
    return [
      rule(
        id: 'rule.tomato.disease.botrytis_greenhouse_high_humidity',
        category: cat,
        priority: 90,
        risk: 'high',
        when: [
          c,
          eq(FactKeys.cultivationType, 'greenhouse'),
          eq(FactKeys.humidityLevel, 'high'),
        ],
        recs: [
          'Sera + yüksek nem = Botrytis (kurşuni küf) kritik risk.',
          'Havalandırmayı artır; hastalıklı bitki parçalarını uzaklaştır; yaprak ıslaklığını azalt.',
          'Kimyasal mücadele gerekiyorsa BKÜ veritabanı ile güncel ruhsat kontrolü + uzman onayı şart.',
        ],
        confidence: 'high',
        evidence: ev,
        explain:
            'CLAUDE.md sec 14 — sera + yüksek nem Botrytis riskini artırır (TAGEM örtüaltı IPM).',
        expert: true,
        bku: true,
        problemId: 'disease.tomato.botrytis',
      ),
      rule(
        id: 'rule.tomato.disease.powdery_mildew_greenhouse',
        category: cat,
        priority: 75,
        risk: 'medium',
        when: [
          c,
          eq(FactKeys.cultivationType, 'greenhouse'),
          eq(FactKeys.observedSymptom, 'powdery_mildew'),
        ],
        recs: [
          'Külleme — yaprak yüzeyinde beyaz pudra örtüsü. Sera ortamı + sıcak/kuru hava etkili.',
          'Havalandırma + nem dengesi. BKÜ etiket kontrolü ile sülfür/biyolojik fungisit değerlendirilir.',
        ],
        confidence: 'medium',
        evidence: ev,
        expert: true,
        bku: true,
        problemId: 'disease.tomato.powdery_mildew',
      ),
      rule(
        id: 'rule.tomato.greenhouse.ventilation_low',
        category: RuleCategories.weatherWarning,
        priority: 70,
        risk: 'medium',
        when: [
          c,
          eq(FactKeys.cultivationType, 'greenhouse'),
          eq(FactKeys.greenhouseVentilation, 'low'),
          eq(FactKeys.humidityLevel, 'high'),
        ],
        recs: [
          'Sera havalandırması düşük + nem yüksek — Botrytis, külleme ve yaprak hastalıkları için ideal koşul.',
          'Havalandırma pencerelerini açın, sirkülasyon fanı çalıştırın.',
        ],
        confidence: 'high',
        evidence: ev,
      ),
    ];
  }

  // ════════════════════════════════════════════════════════════════════
  // 9) PESTS — Tuta absoluta en kritik
  // ════════════════════════════════════════════════════════════════════
  static List<Rule> _pests() {
    const cat = RuleCategories.pestRisk;
    final c = eq(_cropFact, _cropId);
    return [
      rule(
        id: 'rule.tomato.pest.tuta_absoluta',
        category: cat,
        priority: 90,
        risk: 'high',
        when: [c, eq(FactKeys.observedPest, 'tuta_absoluta')],
        recs: [
          'Tuta absoluta (domates güvesi) — yaprak galerileri ve meyve içinde larva tünelleri.',
          'Feromon tuzakla izleme şart; biyolojik mücadele (Bt, Nesidiocoris tenuis) öncelikli.',
          'Kimyasal gerekliyse BKÜ etiketinde ruhsatlı ve PHI uygun ürün; uzman önerisi şart.',
        ],
        confidence: 'high',
        evidence: pendingEvidence(SourceIds.tomatoOpenFieldIpm),
        expert: true,
        bku: true,
        problemId: 'pest.tomato.tuta_absoluta',
      ),
      rule(
        id: 'rule.tomato.pest.whitefly',
        category: cat,
        priority: 80,
        risk: 'high',
        when: [c, eq(FactKeys.observedPest, 'whitefly')],
        recs: [
          'Beyaz sinek — yaprak alt yüzünde beyaz erginler; bal özü + virüs taşıyıcılığı (TYLCV).',
          'Sera giriş kapısında yapışkan tuzak; biyolojik mücadele (Encarsia formosa).',
          'Kimyasal gerekliyse BKÜ etiket + uzman önerisi şart.',
        ],
        confidence: 'high',
        evidence: pendingEvidence(SourceIds.tomatoGreenhouseIpm),
        expert: true,
        bku: true,
        problemId: 'pest.tomato.whitefly',
      ),
      rule(
        id: 'rule.tomato.pest.aphid',
        category: cat,
        priority: 60,
        when: [c, eq(FactKeys.observedPest, 'aphid')],
        recs: [
          'Yaprak biti — virüs taşıyıcı. Yoğun bulaşmada uzman + BKÜ ile karar.',
          'Doğal düşmanları (uğur böceği, parazitoid) koruyun.',
        ],
        confidence: 'medium',
        evidence: pendingEvidence(SourceIds.tomatoOpenFieldIpm),
        expert: true,
        problemId: 'pest.tomato.aphid',
      ),
      rule(
        id: 'rule.tomato.pest.spider_mite',
        category: cat,
        priority: 70,
        when: [
          c,
          eq(FactKeys.observedPest, 'mite'),
        ],
        recs: [
          'Kırmızı örümcek — sıcak/kuru ortamda popülasyon hızla artar; yaprak alt yüzünde gümüşi lekeleşme.',
          'Yaprak yıkama + nem dengeleme. Yoğun zarar varsa uzman + BKÜ.',
        ],
        confidence: 'medium',
        evidence: pendingEvidence(SourceIds.tomatoOpenFieldIpm),
        expert: true,
        bku: true,
        problemId: 'pest.tomato.spider_mite',
      ),
      rule(
        id: 'rule.tomato.pest.thrips',
        category: cat,
        priority: 65,
        when: [c, eq(FactKeys.observedPest, 'thrips')],
        recs: [
          'Trips — yaprak ve meyvede gümüşi lekeler + TSWV virüs taşıyıcılığı riski.',
          'Mavi yapışkan tuzak ile izleme; biyolojik (Orius spp.) öncelikli.',
          'Yoğun zarar varsa BKÜ etiket + uzman önerisi.',
        ],
        confidence: 'medium',
        evidence: pendingEvidence(SourceIds.tomatoGreenhouseIpm),
        expert: true,
        bku: true,
        problemId: 'pest.tomato.thrips',
      ),
    ];
  }

  // ════════════════════════════════════════════════════════════════════
  // 10) WEATHER WARNINGS
  // ════════════════════════════════════════════════════════════════════
  static List<Rule> _weatherWarnings() {
    const cat = RuleCategories.weatherWarning;
    final ev = pendingEvidence(SourceIds.tomatoAgronomy);
    final c = eq(_cropFact, _cropId);
    return [
      rule(
        id: 'rule.tomato.weather.frost_open_field',
        category: cat,
        priority: 90,
        risk: 'high',
        when: [
          c,
          eq(FactKeys.cultivationType, 'open_field'),
          eq(FactKeys.frostRiskNext48h, true),
        ],
        recs: [
          'Açık alan + don riski → bitki ölümü. Hasat hazır meyveleri topla; örtüleme/duman bandı ile koruma.',
        ],
        confidence: 'high',
        evidence: ev,
      ),
      rule(
        id: 'rule.tomato.weather.heat_stress_open_field',
        category: cat,
        priority: 75,
        risk: 'medium',
        when: [
          c,
          eq(FactKeys.cultivationType, 'open_field'),
          eq(FactKeys.heatStressNext48h, true),
        ],
        recs: [
          'Aşırı sıcak + açık alan → polinasyon başarısız, çiçek dökümü. Sulama frekansını artır; gölgeleme düşün.',
        ],
        confidence: 'medium',
        evidence: ev,
      ),
      rule(
        id: 'rule.tomato.weather.hail_risk',
        category: cat,
        priority: 85,
        risk: 'high',
        when: [c, eq(FactKeys.hailRiskNext24h, true)],
        recs: [
          'Dolu domateste yaprak ve meyve hasarı + hastalık giriş kapısı. Açık alanda doğrudan yara açar.',
        ],
        confidence: 'medium',
        evidence: ev,
      ),
    ];
  }
}
