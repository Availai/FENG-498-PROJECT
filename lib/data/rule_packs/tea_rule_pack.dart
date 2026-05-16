import '../../core/rule_engine/rule.dart';
import 'fact_keys.dart';
import 'rule_pack_dsl.dart';
import 'rule_pack_sources.dart';

/// CLAUDE.md sec 11 — `crop.tea` için deterministik kural paketi.
///
/// Çay (Camellia sinensis) Türkiye'de tek bir üretim kuşağında yetişir:
/// Doğu Karadeniz (Rize, Trabzon, Artvin, Giresun, Ordu). Bu kısıt,
/// pack'in iklim/bölge boyutunu son derece daraltır.
///
/// **Bu pack'in özgün noktaları:**
///   - **Asidik toprak zorunlu (pH 4.5-6.0)**; kireçleme YASAKTIR.
///     pH düşükse dolomit (kalsiyum + magnezyum karbonat) ile düzeltilir.
///   - ÇAYKUR materyallerine göre ekonomik düzeyde hastalık/zararlı yok;
///     bu yüzden kimyasal mücadele kuralları minimal, kültürel kontrol
///     baskın.
///   - Çok yıllık ürün: takvim adımları değil, yıllık döngü +
///     3 sürgün hasat penceresi modeli.
///   - Hasat standardı: tepe tomurcuğu + ilk iki körpe yaprak ("iki buçuk
///     yapraklı kısım"). Daha kart yaprak hasadı kalite düşürür.
///
/// **CLAUDE.md sec 17 BKÜ kırmızı çizgisi**: Çayda kimyasal mücadele
/// son çare; her kimyasal öneri `bku: true` taşır ve "BKÜ veritabanı +
/// uzman onayı" yönlendirmesi içerir.
///
/// **CLAUDE.md sec 16 gübre kırmızı çizgisi**: Toprak analizi yokken
/// kesin doz önerilmez.
class TeaRulePack {
  TeaRulePack._();

  static const _cropId = 'crop.tea';
  static const _cropFact = FactKeys.cropId;

  static List<Rule> all() => [
        ..._suitability(),
        ..._soilAcidityManagement(),
        ..._climateAndRegion(),
        ..._fertilization(),
        ..._pruningAndShaping(),
        ..._harvest(),
        ..._pestAndDisease(),
        ..._weatherWarnings(),
      ];

  // ════════════════════════════════════════════════════════════════════
  // 1) SUITABILITY — Bölge, iklim, toprak uygunluğu
  // ════════════════════════════════════════════════════════════════════
  static List<Rule> _suitability() {
    const cat = RuleCategories.suitability;
    final ev = pendingEvidence(SourceIds.teaAgronomy);
    final c = eq(_cropFact, _cropId);
    return [
      rule(
        id: 'rule.tea.suit.region_karadeniz',
        category: cat,
        priority: 80,
        when: [c, eq(FactKeys.region, 'karadeniz')],
        recs: [
          'Doğu Karadeniz çayın tek üretim kuşağıdır — bölge uygun.',
        ],
        confidence: 'high',
        evidence: ev,
      ),
      rule(
        id: 'rule.tea.suit.region_unsuitable',
        category: cat,
        priority: 95,
        risk: 'high',
        when: [
          c,
          notIn(FactKeys.region, ['karadeniz']),
        ],
        recs: [
          'Çay yalnız Doğu Karadeniz iklim kuşağında ekonomik düzeyde yetişir. Seçili bölge çay yetiştiriciliği için uygun değil; başka ürün düşünün.',
        ],
        confidence: 'high',
        evidence: ev,
        explain:
            'ÇAYKUR ve TAGEM kayıtlarına göre çay yetiştiriciliği yalnız Rize, Trabzon, Artvin, Giresun, Ordu illerinde yapılır.',
      ),
      rule(
        id: 'rule.tea.suit.ph_optimal',
        category: cat,
        priority: 60,
        when: [c, between(FactKeys.soilPh, 4.5, 6.0)],
        recs: ['Toprak pH değeri çay için ideal aralıkta (4.5-6.0, asidik).'],
        confidence: 'high',
        evidence: ev,
        explain:
            'Çay asidik toprakta yetişir; pH 5.0-5.5 hedef aralıktır (ÇAYKUR).',
      ),
      rule(
        id: 'rule.tea.suit.ph_too_acidic',
        category: cat,
        priority: 75,
        risk: 'medium',
        when: [c, lt(FactKeys.soilPh, 4.2)],
        recs: [
          'Toprak çok asidik (pH < 4.2). Bu seviyede alüminyum toksisitesi ve fosfor alımı düşer.',
          'Dolomit kalsiyum oksit (granül) ile pH 5.0-5.5 aralığına çekin.',
          'KESİNLİKLE kireç (CaCO3) kullanmayın — çay için zararlı; yalnız dolomit (CaMg karbonat).',
        ],
        confidence: 'high',
        evidence: pendingEvidence(SourceIds.teaAgronomy),
        expert: true,
      ),
      rule(
        id: 'rule.tea.suit.ph_too_alkaline',
        category: cat,
        priority: 90,
        risk: 'high',
        when: [c, gt(FactKeys.soilPh, 6.5)],
        recs: [
          'Toprak çay için fazla alkali (pH > 6.5). Çay alkali toprakta sararır, gelişme durur.',
          'Bu toprakta çay tesisi önerilmez. Asidik düzeltme (sülfat formu gübre) ile zaman içinde pH düşürülebilir ama büyük masraflıdır.',
        ],
        confidence: 'high',
        evidence: ev,
        explain: 'Çay asidofil — pH 6.5 üstü kalıcı verim kaybı yaratır.',
      ),
      rule(
        id: 'rule.tea.suit.rainfall_high',
        category: cat,
        priority: 55,
        when: [c, gte(FactKeys.weeklyRainMm, 30)],
        recs: ['Yağışlı bölge çay için ideal — yıllık 2000+ mm yağış istenir.'],
        confidence: 'high',
        evidence: ev,
      ),
      rule(
        id: 'rule.tea.suit.rainfall_low_dryland',
        category: cat,
        priority: 85,
        risk: 'high',
        when: [c, lt(FactKeys.weeklyRainMm, 8)],
        recs: [
          'Çay için haftalık yağış 8 mm altı kritik düşük. Yıllık 2000 mm altına düşerse sürgün verimi ve kalite ciddi şekilde düşer.',
          'Karadeniz dışı bölgelerde çay ekonomik değildir.',
        ],
        confidence: 'high',
        evidence: ev,
      ),
      rule(
        id: 'rule.tea.suit.humidity_low',
        category: cat,
        priority: 70,
        risk: 'medium',
        when: [c, eq(FactKeys.humidityLevel, 'low')],
        recs: [
          'Düşük bağıl nem çay için olumsuz. Çay bağıl nemin en az %70 olduğu mikro-iklimlerde yetişir.',
        ],
        confidence: 'medium',
        evidence: ev,
      ),
      rule(
        id: 'rule.tea.suit.soil_drained_humus',
        category: cat,
        priority: 50,
        when: [
          c,
          isIn(FactKeys.soilType, ['loam', 'sandy_loam']),
        ],
        recs: [
          'Tınlı ve humuslu, iyi drenajlı toprak çay için ideal. Su tutar ama göllenmez.',
        ],
        confidence: 'medium',
        evidence: ev,
      ),
      rule(
        id: 'rule.tea.suit.soil_heavy_clay_drainage',
        category: cat,
        priority: 70,
        risk: 'medium',
        when: [c, eq(FactKeys.soilType, 'clay')],
        recs: [
          'Ağır killi toprakta çay kök çürüklüğüne girer. Drenaj kanalları açın ve organik madde ile toprağı gevşetin.',
        ],
        confidence: 'medium',
        evidence: ev,
      ),
    ];
  }

  // ════════════════════════════════════════════════════════════════════
  // 2) SOIL ACIDITY MANAGEMENT — Asidite yönetimi (çaya özel)
  // ════════════════════════════════════════════════════════════════════
  static List<Rule> _soilAcidityManagement() {
    const cat = RuleCategories.soilAnalysis;
    final ev = pendingEvidence(SourceIds.teaAgronomy);
    final c = eq(_cropFact, _cropId);
    return [
      rule(
        id: 'rule.tea.soil.no_analysis',
        category: cat,
        priority: 90,
        risk: 'medium',
        when: [c, missing(FactKeys.soilPh)],
        recs: [
          'Toprak analizi yapılmamış. Çayda pH, organik madde ve N-P-K değerleri kritiktir; ekim/gübreleme öncesi mutlaka analiz yaptırın.',
          'Analiz olmadan kesin gübre miktarı önerilemez (CLAUDE.md sec 16).',
        ],
        confidence: 'high',
        evidence: ev,
        explain:
            'CLAUDE.md sec 16 — toprak analizi yoksa net gübre dozu önerilmez.',
      ),
      rule(
        id: 'rule.tea.soil.dolomite_correction',
        category: cat,
        priority: 70,
        when: [c, between(FactKeys.soilPh, 4.0, 4.8)],
        recs: [
          'pH 4.0-4.8 aralığında dolomit (granül oksit formunda) ile pH 5.0-5.5 hedeflenir.',
          'Doz toprak analizine ve bahçe yaşına göre uzman tarafından belirlenmelidir.',
          'KESİNLİKLE adi kireç (CaCO3) kullanmayın — yalnız dolomit.',
        ],
        confidence: 'high',
        evidence: pendingEvidence(SourceIds.teaAgronomy),
        expert: true,
      ),
      rule(
        id: 'rule.tea.soil.organic_matter_low',
        category: cat,
        priority: 50,
        when: [c, lt(FactKeys.organicMatterPct, 2.0)],
        recs: [
          'Organik madde %2 altında. Yanmış ahır gübresi veya çay budama atıkları ile takviye yapın.',
        ],
        confidence: 'medium',
        evidence: ev,
      ),
      rule(
        id: 'rule.tea.soil.salinity_warning',
        category: cat,
        priority: 75,
        risk: 'high',
        when: [c, gt(FactKeys.soilEc, 1.0)],
        recs: [
          'Çay tuzluluğa hassastır; EC > 1.0 dS/m zaten yüksek. Su kaynağını kontrol edin, drenajı iyileştirin.',
        ],
        confidence: 'medium',
        evidence: ev,
      ),
    ];
  }

  // ════════════════════════════════════════════════════════════════════
  // 3) CLIMATE & REGION — İklim duyarlı uyarılar
  // ════════════════════════════════════════════════════════════════════
  static List<Rule> _climateAndRegion() {
    const cat = RuleCategories.weatherWarning;
    final ev = pendingEvidence(SourceIds.teaAgronomy);
    final c = eq(_cropFact, _cropId);
    return [
      rule(
        id: 'rule.tea.weather.frost_risk_spring',
        category: cat,
        priority: 90,
        risk: 'high',
        when: [
          c,
          eq(FactKeys.frostRiskNext48h, true),
          isIn(FactKeys.month, [3, 4, 5]),
        ],
        recs: [
          'İlkbahar donu — yeni sürgünlerde çok ciddi zarar verir. -2 °C altı yeni sürgünleri kavurur.',
          'Düşük çalı örtüsü, makineli budama sonrası kalkan yaprak ve hava akımı için dağılım kanalları riski azaltır.',
        ],
        confidence: 'high',
        evidence: ev,
      ),
      rule(
        id: 'rule.tea.weather.heat_stress_summer',
        category: cat,
        priority: 70,
        risk: 'medium',
        when: [
          c,
          eq(FactKeys.heatStressNext48h, true),
          isIn(FactKeys.month, [7, 8]),
        ],
        recs: [
          'Yaz sıcaklığı + düşük yağış çayda sürgün durmasına yol açabilir. Sulama kanallarını ve gölge bitki örtüsünü kontrol edin.',
        ],
        confidence: 'medium',
        evidence: ev,
      ),
      rule(
        id: 'rule.tea.weather.hail_risk',
        category: cat,
        priority: 85,
        risk: 'high',
        when: [c, eq(FactKeys.hailRiskNext24h, true)],
        recs: [
          'Dolu çayda hasat öncesi sürgün kaybı ve dal kırılması yapar. Hasat hazır parsellerde mümkünse erken toplama planlayın.',
        ],
        confidence: 'medium',
        evidence: ev,
      ),
      rule(
        id: 'rule.tea.weather.heavy_rain_quality',
        category: cat,
        priority: 60,
        risk: 'medium',
        when: [c, gt(FactKeys.forecastRain48hMm, 80)],
        recs: [
          'Aşırı yağış (48 saat içinde >80 mm) hasat kalitesini düşürür ve mantar hastalık riski artırır. Mümkünse hasadı yağış öncesi tamamlayın.',
        ],
        confidence: 'medium',
        evidence: ev,
      ),
    ];
  }

  // ════════════════════════════════════════════════════════════════════
  // 4) FERTILIZATION — Çaya özel azot ağırlıklı program
  // ════════════════════════════════════════════════════════════════════
  static List<Rule> _fertilization() {
    const cat = RuleCategories.fertilization;
    final ev = pendingEvidence(SourceIds.teaAgronomy);
    final c = eq(_cropFact, _cropId);
    return [
      rule(
        id: 'rule.tea.fert.no_soil_analysis_no_dose',
        category: cat,
        priority: 95,
        risk: 'high',
        when: [c, missing(FactKeys.soilPh)],
        recs: [
          'Toprak analizi yok — kesin gübre dozu önerilemez (CLAUDE.md sec 16).',
          'Yalnız genel öneri: ÇAYKUR 25-5-10 NPK çay gübresi, toprak analizinden sonra dekara 60-80 kg dolayında bölünmüş dozlarla uygulanır.',
        ],
        confidence: 'high',
        evidence: ev,
      ),
      rule(
        id: 'rule.tea.fert.npk_25_5_10',
        category: cat,
        priority: 55,
        when: [
          c,
          exists(FactKeys.soilPh),
          isIn(FactKeys.growthStage, ['vegetative', 'flowering']),
        ],
        recs: [
          'ÇAYKUR 25-5-10 NPK çay gübresi azot ağırlıklı dengeli karışımdır.',
          'Mart-Nisan ve Haziran-Temmuz olmak üzere bölünmüş uygulayın; toprak analizine göre dekara 60-80 kg arası.',
        ],
        confidence: 'medium',
        evidence: pendingEvidence(SourceIds.teaAgronomy),
      ),
      rule(
        id: 'rule.tea.fert.excess_nitrogen_warning',
        category: cat,
        priority: 70,
        risk: 'medium',
        when: [c, eq(FactKeys.nLevel, 'high')],
        recs: [
          'Aşırı azot çayda pH düşüşü, besin dengesizliği ve kalitesiz sürgün üretir. Bu sezon azotu azaltın, K ve mikro-besin kontrolü yapın.',
        ],
        confidence: 'medium',
        evidence: ev,
      ),
      rule(
        id: 'rule.tea.fert.organic_amendment',
        category: cat,
        priority: 45,
        when: [c, lt(FactKeys.organicMatterPct, 3.0)],
        recs: [
          'Organik madde takviyesi (yanmış ahır gübresi, çay budama atıkları) toprak yapısı ve mikro-besin için faydalı.',
        ],
        confidence: 'low',
        evidence: ev,
      ),
      rule(
        id: 'rule.tea.fert.timing_after_pruning',
        category: cat,
        priority: 60,
        when: [
          c,
          isIn(FactKeys.month, [3, 4]),
        ],
        recs: [
          'Budama sonrası ve yeni sürgün başlangıcında azot uygulaması verim için kritiktir (Mart-Nisan).',
        ],
        confidence: 'medium',
        evidence: ev,
      ),
    ];
  }

  // ════════════════════════════════════════════════════════════════════
  // 5) PRUNING & SHAPING — Çaya özel budama
  // ════════════════════════════════════════════════════════════════════
  static List<Rule> _pruningAndShaping() {
    const cat = RuleCategories.taskGeneration;
    final ev = pendingEvidence(SourceIds.teaPruning);
    final c = eq(_cropFact, _cropId);
    return [
      rule(
        id: 'rule.tea.prune.annual_form',
        category: cat,
        priority: 55,
        when: [
          c,
          isIn(FactKeys.month, [2, 3]),
        ],
        recs: [
          'Şubat-Mart şekil budaması zamanıdır. Yeni sürgünlerin uniform yetişmesi için bahçe kotunun aynı yükseklikte olması gerekir.',
        ],
        confidence: 'medium',
        evidence: ev,
      ),
      rule(
        id: 'rule.tea.prune.rejuvenation_old_bush',
        category: cat,
        priority: 45,
        when: [
          c,
          isIn(FactKeys.month, [12, 1, 2]),
        ],
        recs: [
          'Yaşlı bahçelerde (8-10 yıllık) ağır budama (yeniden gençleştirme) gerekebilir. Uygulama uzman gözetiminde, kış sonu yapılır.',
        ],
        confidence: 'low',
        evidence: ev,
        expert: true,
      ),
    ];
  }

  // ════════════════════════════════════════════════════════════════════
  // 6) HARVEST — 3 sürgün yıllık döngü
  // ════════════════════════════════════════════════════════════════════
  static List<Rule> _harvest() {
    const cat = RuleCategories.harvest;
    final ev = pendingEvidence(SourceIds.teaAgronomy);
    final c = eq(_cropFact, _cropId);
    return [
      rule(
        id: 'rule.tea.harvest.first_flush',
        category: cat,
        priority: 70,
        when: [
          c,
          isIn(FactKeys.month, [5, 6]),
        ],
        recs: [
          'Birinci sürgün hasadı (Mayıs-Haziran). En kaliteli sürgün — tepe tomurcuğu + ilk iki körpe yaprak ("iki buçuk yapraklı kısım") alınır.',
          'Daha kart yaprakların alınması kalite ve fiyat düşürür.',
        ],
        confidence: 'high',
        evidence: pendingEvidence(SourceIds.teaAgronomy),
      ),
      rule(
        id: 'rule.tea.harvest.second_flush',
        category: cat,
        priority: 65,
        when: [
          c,
          isIn(FactKeys.month, [7, 8]),
        ],
        recs: [
          'İkinci sürgün hasadı (Temmuz-Ağustos). Sıcaklık+nem ile gelişme hızlı, 7-10 gün aralık ile hasat planlayın.',
        ],
        confidence: 'high',
        evidence: ev,
      ),
      rule(
        id: 'rule.tea.harvest.third_flush',
        category: cat,
        priority: 60,
        when: [
          c,
          isIn(FactKeys.month, [9, 10]),
        ],
        recs: [
          'Üçüncü sürgün hasadı (Eylül-Ekim). Mevsim sonu, sürgün yavaşlar; Ekim ortasından sonra hasat durur.',
        ],
        confidence: 'high',
        evidence: ev,
      ),
      rule(
        id: 'rule.tea.harvest.too_young_bush',
        category: cat,
        priority: 75,
        risk: 'medium',
        when: [c, lt(FactKeys.daysAfterPlanting, 1095)],
        recs: [
          'Bahçe 3 yaşından küçük — fidan kök sistemi yeterince gelişmedi. Hasat erken yapılırsa bitkilerin kalıcı zayıflamasına yol açar.',
        ],
        confidence: 'high',
        evidence: ev,
      ),
      rule(
        id: 'rule.tea.harvest.no_winter',
        category: cat,
        priority: 40,
        when: [
          c,
          isIn(FactKeys.month, [11, 12, 1, 2, 3, 4]),
        ],
        recs: [
          'Bu dönemde hasat yok — çay dinlenme + budama dönemindedir.',
        ],
        confidence: 'high',
        evidence: ev,
      ),
    ];
  }

  // ════════════════════════════════════════════════════════════════════
  // 7) PEST & DISEASE — ÇAYKUR materyallerine göre minimal
  // ════════════════════════════════════════════════════════════════════
  static List<Rule> _pestAndDisease() {
    const cat = RuleCategories.diseaseRisk;
    final ev = pendingEvidence(SourceIds.teaIpm);
    final c = eq(_cropFact, _cropId);
    return [
      rule(
        id: 'rule.tea.ipm.minimal_chemical',
        category: cat,
        priority: 50,
        when: [c],
        recs: [
          'ÇAYKUR verilerine göre Türkiye çay plantasyonlarında ekonomik düzeyde hastalık/zararlı tespit edilmemiştir. Kültürel ve teknik tedbirler genelde yeterlidir.',
        ],
        confidence: 'high',
        evidence: pendingEvidence(SourceIds.teaIpm),
        explain:
            'CLAUDE.md sec 17 — çayda kimyasal mücadele son çare; öncelik kültürel.',
      ),
      rule(
        id: 'rule.tea.ipm.root_rot_drainage',
        category: cat,
        priority: 75,
        risk: 'medium',
        when: [
          c,
          eq(FactKeys.observedSymptom, 'stem_rot'),
        ],
        recs: [
          'Kök ve gövde çürüklüğü tipik olarak drenaj zayıflığı + aşırı suya bağlıdır.',
          'Drenajı iyileştirin, hastalıklı bitki parçalarını imha edin.',
          'Kimyasal mücadele uzman onayı + BKÜ etiket kontrolü gerektirir.',
        ],
        confidence: 'medium',
        evidence: ev,
        expert: true,
        bku: true,
        problemId: 'disease.tea.root_stem_rot',
      ),
      rule(
        id: 'rule.tea.ipm.scale_insect_observation',
        category: RuleCategories.pestRisk,
        priority: 60,
        when: [c, eq(FactKeys.observedPest, 'scale_insect')],
        recs: [
          'Çay koşnili gözlemlendi. Gözlem yoğunluğu eşik üstündeyse mücadele kararı için uzman onayı + BKÜ kontrolü gerekir.',
          'Kültürel önlem: enfekte dalları temizleme + bahçe havalandırması.',
        ],
        confidence: 'medium',
        evidence: ev,
        expert: true,
        bku: true,
        problemId: 'pest.tea.scale_insect',
      ),
      rule(
        id: 'rule.tea.ipm.mite_observation',
        category: RuleCategories.pestRisk,
        priority: 60,
        when: [c, eq(FactKeys.observedPest, 'mite')],
        recs: [
          'Çay akarı gözlemlendi. Yaprakların alt yüzünde kontrol edin.',
          'Düşük yoğunlukta kültürel önlem (yaprak hijyeni, sulama düzeni) yeterli olabilir.',
          'Yoğun zarar görülürse uzman onayı + BKÜ etiket kontrolü ile karar verilir.',
        ],
        confidence: 'medium',
        evidence: ev,
        expert: true,
        bku: true,
        problemId: 'pest.tea.mite',
      ),
      rule(
        id: 'rule.tea.ipm.aphid_observation',
        category: RuleCategories.pestRisk,
        priority: 55,
        when: [c, eq(FactKeys.observedPest, 'aphid')],
        recs: [
          'Yaprak biti gözlemlendi. Çayda genelde doğal düşmanlar (uğur böceği) populasyonu kontrol altında tutar.',
          'Mücadele kararı yoğunluk + zarar oranına bakılarak uzman onayı ile verilir.',
        ],
        confidence: 'medium',
        evidence: ev,
        expert: true,
        problemId: 'pest.tea.aphid',
      ),
    ];
  }

  // ════════════════════════════════════════════════════════════════════
  // 8) WEATHER WARNINGS — Hasat döneminde özel
  // ════════════════════════════════════════════════════════════════════
  static List<Rule> _weatherWarnings() {
    const cat = RuleCategories.weatherWarning;
    final ev = pendingEvidence(SourceIds.teaAgronomy);
    final c = eq(_cropFact, _cropId);
    return [
      rule(
        id: 'rule.tea.weather.harvest_rain',
        category: cat,
        priority: 65,
        risk: 'medium',
        when: [
          c,
          gt(FactKeys.forecastRain24hMm, 30),
          isIn(FactKeys.month, [5, 6, 7, 8, 9, 10]),
        ],
        recs: [
          'Hasat dönemi yağmur — yaş yaprak kalitesi düşer ve teslimde fire artar. Mümkünse yağış öncesi hasadı tamamlayın veya 1-2 gün ertelenin.',
        ],
        confidence: 'medium',
        evidence: ev,
      ),
      rule(
        id: 'rule.tea.weather.wind_damage_young_shoots',
        category: cat,
        priority: 55,
        risk: 'medium',
        when: [c, gt(FactKeys.windSpeedMs, 12)],
        recs: [
          'Şiddetli rüzgâr (>12 m/s) yeni sürgünleri kırabilir. Açık parsellerde rüzgâr koruyucu örtü/şerit planlayın.',
        ],
        confidence: 'low',
        evidence: ev,
      ),
    ];
  }
}
