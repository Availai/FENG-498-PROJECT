import '../../core/rule_engine/rule.dart';
import 'fact_keys.dart';
import 'rule_pack_dsl.dart';
import 'rule_pack_sources.dart';

/// CLAUDE.md sec 11 — `crop.corn` için deterministik kural paketi.
///
/// Mısır (Zea mays) Türkiye'de GAP, Çukurova, Ege ve Karadeniz
/// bölgelerinde yaygındır. Tek yıllık, ana ekim Nisan-Mayıs;
/// II. ürün ekim Temmuz (Çukurova-GAP).
///
/// **Pack özellikleri:**
///   - Sulama dane dolumunda kritik (pürşel + tabla + dane dolumu).
///   - Ana zararlılar: koçan kurdu (Sesamia), mısır kurdu (Ostrinia),
///     yaprak biti, tel kurtları.
///   - Ana hastalıklar: yaprak yanıklığı (NCLB), pas, rastık, Fusarium.
///
/// **CLAUDE.md sec 17 BKÜ kırmızı çizgisi**: Kimyasal mücadele kuralları
/// `bku: true` taşır.
/// **CLAUDE.md sec 16 gübre kırmızı çizgisi**: Toprak analizi yoksa
/// kesin doz önerilmez.
class CornRulePack {
  CornRulePack._();

  static const _cropId = 'crop.corn';
  static const _cropFact = FactKeys.cropId;

  static List<Rule> all() => [
        ..._suitability(),
        ..._soilAndSowing(),
        ..._growthStages(),
        ..._fertilization(),
        ..._irrigation(),
        ..._harvest(),
        ..._diseases(),
        ..._pests(),
        ..._weatherWarnings(),
      ];

  // ════════════════════════════════════════════════════════════════════
  // 1) SUITABILITY
  // ════════════════════════════════════════════════════════════════════
  static List<Rule> _suitability() {
    const cat = RuleCategories.suitability;
    final ev = pendingEvidence(SourceIds.cornAgronomy);
    final c = eq(_cropFact, _cropId);
    return [
      rule(
        id: 'rule.corn.suit.region_gap',
        category: cat,
        priority: 60,
        when: [c, eq(FactKeys.region, 'gap')],
        recs: [
          'GAP bölgesi mısır için yüksek verim potansiyelli — sulu tarım, sıcak yetiştirme dönemi.',
        ],
        confidence: 'high',
        evidence: pendingEvidence(SourceIds.cornGap),
      ),
      rule(
        id: 'rule.corn.suit.region_irrigated',
        category: cat,
        priority: 55,
        when: [
          c,
          isIn(FactKeys.region, ['ege', 'akdeniz', 'karadeniz']),
        ],
        recs: [
          'Ege/Akdeniz/Karadeniz mısır için uygun — sulama planı hazır olsun.'
        ],
        confidence: 'high',
        evidence: ev,
      ),
      rule(
        id: 'rule.corn.suit.region_cold',
        category: cat,
        priority: 70,
        risk: 'medium',
        when: [
          c,
          isIn(FactKeys.region, ['dogu_anadolu']),
        ],
        recs: [
          'Doğu Anadolu mısır için sınırlı — kısa sezon, kısa boylu erken çeşit seçimi gerekir.',
        ],
        confidence: 'medium',
        evidence: ev,
      ),
      rule(
        id: 'rule.corn.suit.ph_optimal',
        category: cat,
        priority: 50,
        when: [c, between(FactKeys.soilPh, 6.0, 7.5)],
        recs: ['Toprak pH değeri mısır için ideal aralıkta (6.0-7.5).'],
        confidence: 'high',
        evidence: ev,
      ),
      rule(
        id: 'rule.corn.suit.ph_acidic',
        category: cat,
        priority: 65,
        risk: 'medium',
        when: [c, lt(FactKeys.soilPh, 5.5)],
        recs: [
          'Toprak asidik (pH < 5.5). Mısırda fosfor ve molibden alımı düşer; kireçleme önerilir.',
        ],
        confidence: 'medium',
        evidence: ev,
        expert: true,
      ),
      rule(
        id: 'rule.corn.suit.ph_alkaline',
        category: cat,
        priority: 60,
        risk: 'medium',
        when: [c, gt(FactKeys.soilPh, 8.0)],
        recs: [
          'Toprak alkali (pH > 8.0). Çinko + demir + mangan eksikliği riski. Çinko sülfat (yaprak) takviyesi düşünün.',
        ],
        confidence: 'medium',
        evidence: ev,
      ),
      rule(
        id: 'rule.corn.suit.soil_type_loam_ideal',
        category: cat,
        priority: 50,
        when: [
          c,
          isIn(FactKeys.soilType, ['loam', 'sandy_loam', 'clay_loam']),
        ],
        recs: ['Tınlı topraklar mısır için ideal.'],
        confidence: 'medium',
        evidence: ev,
      ),
      rule(
        id: 'rule.corn.suit.dryland_low_rain',
        category: cat,
        priority: 80,
        risk: 'high',
        when: [
          c,
          eq(FactKeys.waterRegime, 'dryland'),
          lt(FactKeys.weeklyRainMm, 10),
        ],
        recs: [
          'Kuru tarım + düşük yağış mısır için riskli. Mısır yüksek su isteğine sahiptir; sulama planı şart.',
        ],
        confidence: 'high',
        evidence: ev,
      ),
    ];
  }

  // ════════════════════════════════════════════════════════════════════
  // 2) SOIL & SOWING — Toprak hazırlığı + ekim
  // ════════════════════════════════════════════════════════════════════
  static List<Rule> _soilAndSowing() {
    const cat = RuleCategories.sowingOrPlanting;
    final ev = pendingEvidence(SourceIds.cornAgronomy);
    final c = eq(_cropFact, _cropId);
    return [
      rule(
        id: 'rule.corn.soil.no_analysis',
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
        id: 'rule.corn.sowing.season_main',
        category: cat,
        priority: 60,
        when: [
          c,
          isIn(FactKeys.month, [4, 5]),
        ],
        recs: [
          'Ana ürün mısır ekimi Nisan-Mayıs (toprak sıcaklığı 10-12 °C üstü). Geç ekim verim kaybı yapar.',
        ],
        confidence: 'high',
        evidence: ev,
      ),
      rule(
        id: 'rule.corn.sowing.season_second',
        category: cat,
        priority: 60,
        when: [
          c,
          isIn(FactKeys.month, [6, 7]),
          isIn(FactKeys.region, ['gap', 'akdeniz']),
        ],
        recs: [
          'II. ürün mısır ekimi Haziran sonu-Temmuz (GAP/Çukurova). Erken çeşitler tercih edilir.',
        ],
        confidence: 'high',
        evidence: pendingEvidence(SourceIds.cornGap),
      ),
      rule(
        id: 'rule.corn.sowing.cold_soil',
        category: cat,
        priority: 75,
        risk: 'medium',
        when: [
          c,
          lt(FactKeys.soilTempC, 10),
          isIn(FactKeys.growthStage, ['germination']),
        ],
        recs: [
          'Toprak sıcaklığı 10 °C altında — mısır tohumu çimlenmez veya yavaş çimlenir, tohum çürüme riski artar.',
        ],
        confidence: 'high',
        evidence: ev,
      ),
      rule(
        id: 'rule.corn.sowing.depth_crust',
        category: cat,
        priority: 55,
        when: [
          c,
          eq(FactKeys.soilType, 'clay'),
          gt(FactKeys.forecastRain24hMm, 15)
        ],
        recs: [
          'Killi toprakta yağmur sonrası yüzey kabuğu çıkışı engelleyebilir. Tırmık ile yüzey kabuğunu kırın.',
        ],
        confidence: 'medium',
        evidence: ev,
      ),
    ];
  }

  // ════════════════════════════════════════════════════════════════════
  // 3) GROWTH STAGES — Vejetatif + pürşel + dane dolumu
  // ════════════════════════════════════════════════════════════════════
  static List<Rule> _growthStages() {
    const cat = RuleCategories.taskGeneration;
    final ev = pendingEvidence(SourceIds.cornAgronomy);
    final c = eq(_cropFact, _cropId);
    return [
      rule(
        id: 'rule.corn.stage.vegetative_v6',
        category: cat,
        priority: 55,
        when: [c, between(FactKeys.daysAfterPlanting, 30, 50)],
        recs: [
          'V6 evresi (6 yapraklı) — kök sistemi tam gelişir, ikinci azot dozu uygulama dönemi.',
        ],
        confidence: 'medium',
        evidence: ev,
      ),
      rule(
        id: 'rule.corn.stage.tassel_pollen',
        category: cat,
        priority: 70,
        when: [c, between(FactKeys.daysAfterPlanting, 60, 80)],
        recs: [
          'Pürşel (tassel) + ipek (silk) dönemi — polinasyon kritik. Su stresi bu dönemde dane oluşumunu doğrudan etkiler.',
        ],
        confidence: 'high',
        evidence: ev,
      ),
      rule(
        id: 'rule.corn.stage.grain_filling',
        category: cat,
        priority: 65,
        when: [c, between(FactKeys.daysAfterPlanting, 80, 110)],
        recs: [
          'Dane dolumu — verim için en kritik dönem. Sulama kesintisiz, gübre eksikliği yok olmalı.',
        ],
        confidence: 'high',
        evidence: ev,
      ),
    ];
  }

  // ════════════════════════════════════════════════════════════════════
  // 4) FERTILIZATION
  // ════════════════════════════════════════════════════════════════════
  static List<Rule> _fertilization() {
    const cat = RuleCategories.fertilization;
    final ev = pendingEvidence(SourceIds.cornAgronomy);
    final c = eq(_cropFact, _cropId);
    return [
      rule(
        id: 'rule.corn.fert.no_analysis_no_dose',
        category: cat,
        priority: 95,
        risk: 'high',
        when: [c, missing(FactKeys.soilPh)],
        recs: [
          'Toprak analizi yok — kesin gübre dozu önerilemez (CLAUDE.md sec 16).',
          'Genel: Mısır yüksek azot ister; bölünmüş uygulama (ekim + V6 + pürşel öncesi) standarttır.',
        ],
        confidence: 'high',
        evidence: ev,
      ),
      rule(
        id: 'rule.corn.fert.nitrogen_split',
        category: cat,
        priority: 60,
        when: [
          c,
          exists(FactKeys.soilPh),
          isIn(FactKeys.growthStage, ['emergence', 'vegetative']),
        ],
        recs: [
          'Azot bölünmüş dozda: ekim + V6 (6 yaprak) + pürşel öncesi olmak üzere 3 aşamada.',
          'Tek seferde aşırı azot yıkanma + kalite düşüşü.',
        ],
        confidence: 'medium',
        evidence: ev,
      ),
      rule(
        id: 'rule.corn.fert.phosphorus_starter',
        category: cat,
        priority: 55,
        when: [
          c,
          exists(FactKeys.soilPh),
          isIn(FactKeys.growthStage, ['germination', 'emergence']),
        ],
        recs: [
          'Fosfor (DAP veya TSP) ekimle birlikte taban gübre olarak verilir — kök gelişimi için kritik.',
        ],
        confidence: 'medium',
        evidence: ev,
      ),
      rule(
        id: 'rule.corn.fert.zinc_alkaline',
        category: cat,
        priority: 60,
        when: [c, gt(FactKeys.soilPh, 7.5)],
        recs: [
          'Alkali toprakta çinko eksikliği yaygın — yaprak gübresi (Çinko sülfat) V4-V6 evrede uygulayın.',
        ],
        confidence: 'medium',
        evidence: ev,
      ),
    ];
  }

  // ════════════════════════════════════════════════════════════════════
  // 5) IRRIGATION — Pürşel + dane dolumu kritik
  // ════════════════════════════════════════════════════════════════════
  static List<Rule> _irrigation() {
    const cat = RuleCategories.irrigation;
    final ev = pendingEvidence(SourceIds.cornAgronomy);
    final c = eq(_cropFact, _cropId);
    return [
      rule(
        id: 'rule.corn.irrig.tassel_critical',
        category: cat,
        priority: 90,
        risk: 'high',
        when: [
          c,
          between(FactKeys.daysAfterPlanting, 60, 80),
          lt(FactKeys.weeklyRainMm, 15),
        ],
        recs: [
          'Pürşel + ipek dönemi su stresi → polinasyon başarısız, dane sayısı düşer.',
          'Acil sulama yapın; haftalık 30-40 mm hedef.',
        ],
        confidence: 'high',
        evidence: ev,
      ),
      rule(
        id: 'rule.corn.irrig.grain_filling',
        category: cat,
        priority: 80,
        when: [
          c,
          between(FactKeys.daysAfterPlanting, 80, 110),
          lt(FactKeys.weeklyRainMm, 20),
        ],
        recs: [
          'Dane dolumu döneminde su stresi dane ağırlığını düşürür. Sulamaya devam edin.',
        ],
        confidence: 'high',
        evidence: ev,
      ),
      rule(
        id: 'rule.corn.irrig.harvest_dry_off',
        category: cat,
        priority: 55,
        when: [c, gt(FactKeys.daysAfterPlanting, 115)],
        recs: [
          'Hasada yaklaşıldığı için sulamayı kesin — tane nemi %25 altına inmeli.',
        ],
        confidence: 'medium',
        evidence: ev,
      ),
    ];
  }

  // ════════════════════════════════════════════════════════════════════
  // 6) HARVEST
  // ════════════════════════════════════════════════════════════════════
  static List<Rule> _harvest() {
    const cat = RuleCategories.harvest;
    final ev = pendingEvidence(SourceIds.cornAgronomy);
    final c = eq(_cropFact, _cropId);
    return [
      rule(
        id: 'rule.corn.harvest.ready_grain',
        category: cat,
        priority: 70,
        when: [c, between(FactKeys.daysAfterPlanting, 120, 140)],
        recs: [
          'Tane mısır hasat dönemi — tane nemi %20-25 hedef. Daha yüksek nem → depolama riski (küflenme).',
        ],
        confidence: 'high',
        evidence: ev,
      ),
      rule(
        id: 'rule.corn.harvest.silage_window',
        category: cat,
        priority: 60,
        when: [c, between(FactKeys.daysAfterPlanting, 85, 110)],
        recs: [
          'Silajlık mısır hasat penceresi — bitki nem oranı %65-70 ideal. Süt çizgisi koçanın 1/2-2/3 ulaştığında biçim.',
        ],
        confidence: 'medium',
        evidence: ev,
      ),
    ];
  }

  // ════════════════════════════════════════════════════════════════════
  // 7) DISEASES — Yaprak yanıklığı, pas, rastık, Fusarium
  // ════════════════════════════════════════════════════════════════════
  static List<Rule> _diseases() {
    const cat = RuleCategories.diseaseRisk;
    final ev = pendingEvidence(SourceIds.cornIpm);
    final c = eq(_cropFact, _cropId);
    return [
      rule(
        id: 'rule.corn.disease.nclb_leaf_blight',
        category: cat,
        priority: 70,
        risk: 'medium',
        when: [
          c,
          eq(FactKeys.observedSymptom, 'leaf_spot'),
          eq(FactKeys.humidityLevel, 'high'),
        ],
        recs: [
          'Kuzey yaprak yanıklığı (NCLB) — yaprakta gri-kahverengi puro şekli lekeler.',
          'Direnç gösteren çeşit, münavebe ve hasat sonrası sap parçalama temel önlem.',
          'Yoğun bulaşmada uzman onayı + BKÜ etiket kontrolü ile fungisit uygulanabilir.',
        ],
        confidence: 'medium',
        evidence: ev,
        expert: true,
        bku: true,
        problemId: 'disease.corn.nclb',
      ),
      rule(
        id: 'rule.corn.disease.common_rust',
        category: cat,
        priority: 65,
        when: [c, eq(FactKeys.observedSymptom, 'rust')],
        recs: [
          'Yaprak pası — yaprak yüzeyinde kırmızı-kahverengi püstüller.',
          'Direnç gösteren çeşit + erken hasat ana önlem.',
          'Yoğun bulaşmada uzman + BKÜ ile fungisit değerlendirilir.',
        ],
        confidence: 'medium',
        evidence: ev,
        expert: true,
        bku: true,
        problemId: 'disease.corn.common_rust',
      ),
      rule(
        id: 'rule.corn.disease.smut',
        category: cat,
        priority: 60,
        when: [c, eq(FactKeys.observedSymptom, 'head_rot')],
        recs: [
          'Mısır rastığı — koçan, pürşel veya sürgün üzerinde gri-siyah galler.',
          'Bulaşık bitki parçalarını topla ve imha et; yaralanmadan kaçın.',
          'Kimyasal mücadele etkili değil; direnç gösteren çeşit + münavebe önemli.',
        ],
        confidence: 'medium',
        evidence: ev,
        expert: true,
        problemId: 'disease.corn.smut',
      ),
      rule(
        id: 'rule.corn.disease.fusarium_ear_rot',
        category: cat,
        priority: 75,
        risk: 'medium',
        when: [
          c,
          eq(FactKeys.observedSymptom, 'head_rot'),
          gt(FactKeys.forecastRain48hMm, 40),
        ],
        recs: [
          'Fusarium koçan çürüklüğü — koçanda beyaz-pembe küf, dane çürümesi. Mikotoksin riski (insan/hayvan sağlığı).',
          'Etkilenen koçanları hasat sonrası ayırın; hayvan yemine kullanmayın.',
          'Hasadı en uygun nem oranında yapın, geç bırakmayın.',
        ],
        confidence: 'high',
        evidence: ev,
        expert: true,
        bku: true,
        problemId: 'disease.corn.fusarium_ear_rot',
      ),
    ];
  }

  // ════════════════════════════════════════════════════════════════════
  // 8) PESTS — Koçan kurdu, mısır kurdu, yaprak biti, tel kurtları
  // ════════════════════════════════════════════════════════════════════
  static List<Rule> _pests() {
    const cat = RuleCategories.pestRisk;
    final ev = pendingEvidence(SourceIds.cornIpm);
    final c = eq(_cropFact, _cropId);
    return [
      rule(
        id: 'rule.corn.pest.stem_borer',
        category: cat,
        priority: 80,
        risk: 'high',
        when: [c, eq(FactKeys.observedPest, 'stem_borer')],
        recs: [
          'Mısır kurdu (Ostrinia/Sesamia) — gövde ve koçan içinde larva tüneli.',
          'Feromon tuzak ile izleme; eşik aşılırsa BKÜ etiketinde ruhsatlı insektisit (piretroid grubu) ve uzman onayı.',
          'Hasat sonrası sap parçalama + derin sürüm kışlayan larvayı azaltır.',
        ],
        confidence: 'high',
        evidence: ev,
        expert: true,
        bku: true,
        problemId: 'pest.corn.stem_borer',
      ),
      rule(
        id: 'rule.corn.pest.aphid',
        category: cat,
        priority: 55,
        when: [c, eq(FactKeys.observedPest, 'aphid')],
        recs: [
          'Yaprak biti mısırda virüs taşıyıcısı olabilir. Yoğun bulaşma + doğal düşman yetersizliği durumunda uzman + BKÜ ile karar verilir.',
        ],
        confidence: 'medium',
        evidence: ev,
        expert: true,
        problemId: 'pest.corn.aphid',
      ),
      rule(
        id: 'rule.corn.pest.wireworm',
        category: cat,
        priority: 70,
        risk: 'medium',
        when: [
          c,
          eq(FactKeys.observedPest, 'helicoverpa'),
          isIn(FactKeys.growthStage, ['germination', 'emergence']),
        ],
        recs: [
          'Tel kurtları (Elateridae) — toprak altı larva, fideleri keser.',
          'Geçmiş bulaşık tarlada münavebe; Şubat-Mart sürümü kışlayan larvayı azaltır.',
          'Eşik aşılırsa BKÜ etiketinde ruhsatlı tohum kaplama veya toprak insektisidi düşünülür.',
        ],
        confidence: 'medium',
        evidence: ev,
        expert: true,
        bku: true,
        problemId: 'pest.corn.wireworm',
      ),
      rule(
        id: 'rule.corn.pest.cutworm',
        category: cat,
        priority: 65,
        when: [
          c,
          eq(FactKeys.observedPest, 'helicoverpa'),
          isIn(FactKeys.growthStage, ['emergence', 'vegetative']),
        ],
        recs: [
          'Bozkurt — genç bitkiler kök boğazından kesilir.',
          'Yabancı ot temizliği + akşam kontrolleri; eşik aşılırsa uzman + BKÜ.',
        ],
        confidence: 'medium',
        evidence: ev,
        expert: true,
        bku: true,
        problemId: 'pest.corn.cutworm',
      ),
    ];
  }

  // ════════════════════════════════════════════════════════════════════
  // 9) WEATHER WARNINGS
  // ════════════════════════════════════════════════════════════════════
  static List<Rule> _weatherWarnings() {
    const cat = RuleCategories.weatherWarning;
    final ev = pendingEvidence(SourceIds.cornAgronomy);
    final c = eq(_cropFact, _cropId);
    return [
      rule(
        id: 'rule.corn.weather.hail_risk',
        category: cat,
        priority: 85,
        risk: 'high',
        when: [c, eq(FactKeys.hailRiskNext24h, true)],
        recs: [
          'Dolu mısırda yaprak parçalanması + koçan zararı yapar. Çıkış sonrası dönemde verim kaybı ciddidir.',
        ],
        confidence: 'medium',
        evidence: ev,
      ),
      rule(
        id: 'rule.corn.weather.wind_lodging',
        category: cat,
        priority: 75,
        risk: 'medium',
        when: [
          c,
          gt(FactKeys.windSpeedMs, 15),
          between(FactKeys.daysAfterPlanting, 60, 110),
        ],
        recs: [
          'Şiddetli rüzgâr (>15 m/s) + uzun boylu bitki = yatma (lodging) riski. Aşırı azot, sığ ekim ve düzensiz sulama yatma duyarlılığını artırır.',
        ],
        confidence: 'medium',
        evidence: ev,
      ),
      rule(
        id: 'rule.corn.weather.heavy_rain_pollination',
        category: cat,
        priority: 65,
        risk: 'medium',
        when: [
          c,
          gt(FactKeys.forecastRain48hMm, 60),
          between(FactKeys.daysAfterPlanting, 60, 80),
        ],
        recs: [
          'Pürşel + ipek döneminde aşırı yağış → polenler yıkanır, polinasyon düşer. Hasta yapraklara da uygun ortam.',
        ],
        confidence: 'medium',
        evidence: ev,
      ),
    ];
  }
}
