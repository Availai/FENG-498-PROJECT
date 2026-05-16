import '../../core/rule_engine/rule.dart';
import 'fact_keys.dart';
import 'rule_pack_dsl.dart';
import 'rule_pack_sources.dart';

/// CLAUDE.md sec 11 — `crop.orange` için deterministik kural paketi.
///
/// Portakal (Citrus sinensis) Türkiye'de Akdeniz ve Ege bölgelerinde
/// yetişir. Tarlam'da bu pack:
///   - Aşılı fidan + çok yıllık döngü modelidir (ilk hasat ~3 yıl,
///     tam verim 4-5 yaş, ekonomik ömür 40-50 yıl).
///   - Hasat penceresi Kasım-Nisan (yılbaşı sarmalayan tek dönem).
///   - Don ve aşırı sıcak hassasiyeti yüksek (-3 °C kritik, 38-39 °C üstü
///     gelişme durdurur).
///   - Akdeniz meyve sineği zararlılar arasında en kritik konu.
///
/// **CLAUDE.md sec 17 BKÜ kırmızı çizgisi**: Hiçbir kural ticari ürün
/// adı vermez. Kimyasal mücadele kuralları `bku: true` taşır.
///
/// **CLAUDE.md sec 16 gübre kırmızı çizgisi**: Toprak ve yaprak analizi
/// yoksa kesin doz önerilmez.
class OrangeRulePack {
  OrangeRulePack._();

  static const _cropId = 'crop.orange';
  static const _cropFact = FactKeys.cropId;

  static List<Rule> all() => [
        ..._suitability(),
        ..._soilAndOrchard(),
        ..._climateFrostHeat(),
        ..._fertilization(),
        ..._irrigation(),
        ..._harvest(),
        ..._diseases(),
        ..._pests(),
        ..._weatherWarnings(),
      ];

  // ════════════════════════════════════════════════════════════════════
  // 1) SUITABILITY — Bölge, iklim, toprak uygunluğu
  // ════════════════════════════════════════════════════════════════════
  static List<Rule> _suitability() {
    const cat = RuleCategories.suitability;
    final ev = pendingEvidence(SourceIds.orangeAgronomy);
    final c = eq(_cropFact, _cropId);
    return [
      rule(
        id: 'rule.orange.suit.region_mediterranean',
        category: cat,
        priority: 80,
        when: [
          c,
          isIn(FactKeys.region, ['akdeniz', 'ege']),
        ],
        recs: [
          'Akdeniz/Ege bölgesi turunçgil için ideal — sıcak yazlar, ılıman kışlar.',
        ],
        confidence: 'high',
        evidence: ev,
      ),
      rule(
        id: 'rule.orange.suit.region_unsuitable',
        category: cat,
        priority: 95,
        risk: 'high',
        when: [
          c,
          isIn(FactKeys.region, ['ic_anadolu', 'dogu_anadolu', 'karadeniz']),
        ],
        recs: [
          'Bu bölgenin kış sıcaklıkları portakal için riskli (-3 °C altı kalıcı zarar verir). Açık alanda tesis önerilmez.',
        ],
        confidence: 'high',
        evidence: ev,
      ),
      rule(
        id: 'rule.orange.suit.ph_optimal',
        category: cat,
        priority: 60,
        when: [c, between(FactKeys.soilPh, 6.0, 6.5)],
        recs: ['Toprak pH değeri portakal için ideal (6.0-6.5).'],
        confidence: 'high',
        evidence: ev,
      ),
      rule(
        id: 'rule.orange.suit.ph_alkaline',
        category: cat,
        priority: 75,
        risk: 'medium',
        when: [c, gt(FactKeys.soilPh, 7.5)],
        recs: [
          'Toprak pH > 7.5 — turunçgilde demir/çinko/mangan kloroz riski yüksek. Sülfat formlu mikro-besin uygulayın.',
        ],
        confidence: 'medium',
        evidence: ev,
      ),
      rule(
        id: 'rule.orange.suit.ph_acidic',
        category: cat,
        priority: 65,
        when: [c, lt(FactKeys.soilPh, 5.5)],
        recs: [
          'Toprak pH < 5.5 — turunçgil için fazla asidik. Bahçe tesisi öncesi kireçleme ile pH 6.0-6.5 hedeflenir.',
        ],
        confidence: 'medium',
        evidence: ev,
        expert: true,
      ),
      rule(
        id: 'rule.orange.suit.soil_deep_loam',
        category: cat,
        priority: 55,
        when: [
          c,
          isIn(FactKeys.soilType, ['loam', 'sandy_loam']),
        ],
        recs: [
          'Derin, drenajlı, kumlu-tınlı toprak portakal için ideal — kök sistemi rahat gelişir.',
        ],
        confidence: 'high',
        evidence: ev,
      ),
      rule(
        id: 'rule.orange.suit.soil_clay_heavy',
        category: cat,
        priority: 80,
        risk: 'high',
        when: [c, eq(FactKeys.soilType, 'clay')],
        recs: [
          'Ağır killi toprakta turunçgil kök çürüklüğü (phytophthora) riski yüksek. Bahçe tesisi öncesi drenaj kanalları + organik madde takviyesi şart.',
        ],
        confidence: 'high',
        evidence: ev,
      ),
      rule(
        id: 'rule.orange.suit.ec_high',
        category: cat,
        priority: 75,
        risk: 'medium',
        when: [c, gt(FactKeys.soilEc, 1.5)],
        recs: [
          'Toprak tuzluluğu yüksek (EC > 1.5 dS/m). Turunçgil orta-düşük tuzluluk toleranslıdır; yıkama sulaması ve drenaj iyileştirmesi gerekir.',
        ],
        confidence: 'medium',
        evidence: ev,
      ),
    ];
  }

  // ════════════════════════════════════════════════════════════════════
  // 2) SOIL & ORCHARD — Toprak analizi + bahçe tesisi
  // ════════════════════════════════════════════════════════════════════
  static List<Rule> _soilAndOrchard() {
    const cat = RuleCategories.soilAnalysis;
    final ev = pendingEvidence(SourceIds.orangeAgronomy);
    final c = eq(_cropFact, _cropId);
    return [
      rule(
        id: 'rule.orange.soil.no_analysis',
        category: cat,
        priority: 90,
        risk: 'medium',
        when: [c, missing(FactKeys.soilPh)],
        recs: [
          'Toprak analizi yapılmamış. Bahçe tesisi öncesi 0-30, 30-60 ve 60-90 cm derinliklerden ayrı örnekler alın; pH, EC, organik madde, N-P-K kayıt edilmeli.',
          'Analiz olmadan kesin gübre miktarı önerilemez (CLAUDE.md sec 16).',
        ],
        confidence: 'high',
        evidence: ev,
      ),
      rule(
        id: 'rule.orange.soil.drainage_check_clay',
        category: cat,
        priority: 75,
        risk: 'medium',
        when: [
          c,
          eq(FactKeys.soilType, 'clay'),
          gt(FactKeys.soilMoisture, 0.45)
        ],
        recs: [
          'Killi toprakta su göllenmesi gözlemleniyor — drenaj kanallarını kontrol edin; göllenme phytophthora kök çürüklüğüne yol açar.',
        ],
        confidence: 'high',
        evidence: ev,
      ),
      rule(
        id: 'rule.orange.soil.organic_matter_low',
        category: cat,
        priority: 50,
        when: [c, lt(FactKeys.organicMatterPct, 1.5)],
        recs: [
          'Organik madde %1.5 altında. Yanmış ahır gübresi + yeşil gübre rotasyonu önerilir.',
        ],
        confidence: 'medium',
        evidence: ev,
      ),
    ];
  }

  // ════════════════════════════════════════════════════════════════════
  // 3) CLIMATE — Don ve aşırı sıcak kritik
  // ════════════════════════════════════════════════════════════════════
  static List<Rule> _climateFrostHeat() {
    const cat = RuleCategories.weatherWarning;
    final ev = pendingEvidence(SourceIds.citrusFrostProtection);
    final c = eq(_cropFact, _cropId);
    return [
      rule(
        id: 'rule.orange.weather.frost_critical',
        category: cat,
        priority: 95,
        risk: 'high',
        when: [
          c,
          eq(FactKeys.frostRiskNext48h, true),
          isIn(FactKeys.month, [11, 12, 1, 2]),
        ],
        recs: [
          'KRİTİK don uyarısı — turunçgilde -3 °C altı yaprak/dal/meyve kaybı; -5 °C altı ağaç kaybı.',
          'Don önlemi: rüzgârlama vantilatörü, soba/duman bandı, sulama (su buzlanırken ısı verir), don örtüsü.',
        ],
        confidence: 'high',
        evidence: ev,
        explain: '-3 °C civarı don turunçgil için kritik eşik (BATEM).',
      ),
      rule(
        id: 'rule.orange.weather.frost_early_warning',
        category: cat,
        priority: 80,
        risk: 'medium',
        when: [
          c,
          lt(FactKeys.tempMin24hC, 2.0),
          isIn(FactKeys.month, [11, 12, 1, 2]),
        ],
        recs: [
          'Gece sıcaklığı 2 °C\'ye yaklaşıyor — don ekipmanını hazır tutun.',
        ],
        confidence: 'medium',
        evidence: ev,
      ),
      rule(
        id: 'rule.orange.weather.heat_stress',
        category: cat,
        priority: 80,
        risk: 'high',
        when: [
          c,
          eq(FactKeys.heatStressNext48h, true),
          isIn(FactKeys.month, [6, 7, 8]),
        ],
        recs: [
          'Yaz aşırı sıcağı (38-39 °C üstü) çiçek dökümü + meyve düşmesine yol açar.',
          'Damla sulama frekansını artırın; gölgeleme ağı düşünün; günün en sıcak saatinde işlem yapmayın.',
        ],
        confidence: 'high',
        evidence: ev,
      ),
    ];
  }

  // ════════════════════════════════════════════════════════════════════
  // 4) FERTILIZATION — Toprak + yaprak analizi temelli
  // ════════════════════════════════════════════════════════════════════
  static List<Rule> _fertilization() {
    const cat = RuleCategories.fertilization;
    final ev = pendingEvidence(SourceIds.orangeAgronomy);
    final c = eq(_cropFact, _cropId);
    return [
      rule(
        id: 'rule.orange.fert.no_analysis_no_dose',
        category: cat,
        priority: 95,
        risk: 'high',
        when: [c, missing(FactKeys.soilPh)],
        recs: [
          'Toprak/yaprak analizi yok — kesin gübre dozu önerilemez (CLAUDE.md sec 16).',
          'Genel kural: yaprak örneklemesi haziran-eylül-ekim arası yapılır, 100 yaprak/50 g yaş ağırlık/20 da örnek.',
        ],
        confidence: 'high',
        evidence: ev,
      ),
      rule(
        id: 'rule.orange.fert.nitrogen_split_dose',
        category: cat,
        priority: 60,
        when: [
          c,
          exists(FactKeys.soilPh),
          isIn(FactKeys.growthStage, ['pre_flowering', 'flowering']),
        ],
        recs: [
          'Azot bölünmüş dozlarda — Mart (çiçeklenme öncesi) ve Eylül (meyve dolumu) en kritik. Geç azot meyve kabuğunu yeşil tutar; dozu aşmayın.',
        ],
        confidence: 'medium',
        evidence: ev,
      ),
      rule(
        id: 'rule.orange.fert.potassium_fruit_growth',
        category: cat,
        priority: 55,
        when: [
          c,
          exists(FactKeys.soilPh),
          isIn(FactKeys.month, [6, 7]),
        ],
        recs: [
          'Haziran-Temmuz meyve büyümesinde potasyum kritik — şeker/asit dengesi ve meyve kalitesini belirler.',
        ],
        confidence: 'medium',
        evidence: ev,
      ),
      rule(
        id: 'rule.orange.fert.micro_nutrient_alkaline',
        category: cat,
        priority: 60,
        when: [c, gt(FactKeys.soilPh, 7.5)],
        recs: [
          'Alkali toprakta demir + çinko + mangan eksikliği yaygındır. Çinko + demir yaprak gübresi (şelat formu) Nisan-Mayıs uygulayın.',
        ],
        confidence: 'medium',
        evidence: ev,
      ),
      rule(
        id: 'rule.orange.fert.organic_amendment_winter',
        category: cat,
        priority: 50,
        when: [
          c,
          isIn(FactKeys.month, [2]),
        ],
        recs: [
          'Şubat ayında (uyanma öncesi) taç altına yanmış ahır gübresi (ağaç başına 30-40 kg) hafif toprağa karıştırarak uygulanır.',
        ],
        confidence: 'medium',
        evidence: ev,
      ),
    ];
  }

  // ════════════════════════════════════════════════════════════════════
  // 5) IRRIGATION — Yaz kritik
  // ════════════════════════════════════════════════════════════════════
  static List<Rule> _irrigation() {
    const cat = RuleCategories.irrigation;
    final ev = pendingEvidence(SourceIds.orangeAgronomy);
    final c = eq(_cropFact, _cropId);
    return [
      rule(
        id: 'rule.orange.irrig.summer_critical',
        category: cat,
        priority: 70,
        when: [
          c,
          isIn(FactKeys.month, [6, 7, 8]),
        ],
        recs: [
          'Yaz dönemi (Haziran-Ağustos) sulama kritik — haftalık 45-55 mm hedef.',
          'Su kök boğazına değil taç izdüşümüne verilmeli; damla sulama tercih edilir.',
        ],
        confidence: 'medium',
        evidence: ev,
      ),
      rule(
        id: 'rule.orange.irrig.winter_low',
        category: cat,
        priority: 50,
        when: [
          c,
          isIn(FactKeys.month, [12, 1, 2]),
        ],
        recs: [
          'Hasat ve dinlenme döneminde sulama minimal (haftalık ~12 mm). Aşırı sulama meyve çatlaması ve mantar hastalığı yapar.',
        ],
        confidence: 'medium',
        evidence: ev,
      ),
      rule(
        id: 'rule.orange.irrig.water_deficit_flowering',
        category: cat,
        priority: 80,
        risk: 'high',
        when: [
          c,
          lt(FactKeys.weeklyRainMm, 5),
          isIn(FactKeys.growthStage, ['flowering', 'pre_flowering']),
        ],
        recs: [
          'Çiçeklenme döneminde su stresi → çiçek + erken meyve dökümü. Acil sulama yapın.',
        ],
        confidence: 'high',
        evidence: ev,
      ),
    ];
  }

  // ════════════════════════════════════════════════════════════════════
  // 6) HARVEST — Kasım-Nisan (yılbaşı sarmalayan)
  // ════════════════════════════════════════════════════════════════════
  static List<Rule> _harvest() {
    const cat = RuleCategories.harvest;
    final ev = pendingEvidence(SourceIds.orangeAgronomy);
    final c = eq(_cropFact, _cropId);
    return [
      rule(
        id: 'rule.orange.harvest.season_winter',
        category: cat,
        priority: 70,
        when: [
          c,
          isIn(FactKeys.month, [11, 12, 1, 2, 3, 4]),
        ],
        recs: [
          'Portakal hasat dönemi (Kasım-Nisan). Çeşide göre erken-orta-geç çeşitler peş peşe olgunlaşır.',
          'Hasat öncesi meyve şeker/asit oranını kontrol edin; çok erken hasat depolama ömrünü düşürür.',
        ],
        confidence: 'high',
        evidence: ev,
      ),
      rule(
        id: 'rule.orange.harvest.too_young_tree',
        category: cat,
        priority: 75,
        risk: 'medium',
        when: [c, lt(FactKeys.daysAfterPlanting, 730)],
        recs: [
          'Aşılı fidan 2 yaşından küçük — meyve verme erken; ilk meyvelerin koparılması ağacın gelişimini destekler.',
        ],
        confidence: 'medium',
        evidence: ev,
      ),
      rule(
        id: 'rule.orange.harvest.frost_emergency',
        category: cat,
        priority: 90,
        risk: 'high',
        when: [
          c,
          eq(FactKeys.frostRiskNext48h, true),
          isIn(FactKeys.month, [11, 12, 1, 2]),
        ],
        recs: [
          'Don bekleniyor — hasat hazır meyveleri öncelikle toplayın; donmuş meyveler depo dayanıksızdır.',
        ],
        confidence: 'high',
        evidence: ev,
      ),
    ];
  }

  // ════════════════════════════════════════════════════════════════════
  // 7) DISEASES — Phytophthora ve diğerleri
  // ════════════════════════════════════════════════════════════════════
  static List<Rule> _diseases() {
    const cat = RuleCategories.diseaseRisk;
    final ev = pendingEvidence(SourceIds.orangeIpm);
    final c = eq(_cropFact, _cropId);
    return [
      rule(
        id: 'rule.orange.disease.phytophthora_root_rot',
        category: cat,
        priority: 80,
        risk: 'high',
        when: [c, eq(FactKeys.observedSymptom, 'stem_rot')],
        recs: [
          'Kök çürüklüğü (Phytophthora spp.) tipik olarak ağır toprak + drenaj zayıflığı + aşırı sulama sonucudur.',
          'Drenaj kanallarını açın; gövde tabanını sıcak hava akımı için temizleyin.',
          'Kimyasal mücadele uzman onayı + BKÜ etiket kontrolü gerektirir.',
        ],
        confidence: 'high',
        evidence: ev,
        expert: true,
        bku: true,
        problemId: 'disease.orange.phytophthora_root_rot',
      ),
      rule(
        id: 'rule.orange.disease.gommose',
        category: cat,
        priority: 75,
        risk: 'medium',
        when: [c, eq(FactKeys.observedSymptom, 'wilt')],
        recs: [
          'Zamklanma (gommose) — gövde tabanında zamk çıkışı ve yarıklar.',
          'Bakır oksiklorür gibi koruyucu uygulamalar kış dinlenme döneminde gövdeye fırça ile yapılır; BKÜ etiket kontrolü gerekir.',
        ],
        confidence: 'medium',
        evidence: ev,
        expert: true,
        bku: true,
        problemId: 'disease.orange.gommose',
      ),
      rule(
        id: 'rule.orange.disease.fruit_rot',
        category: cat,
        priority: 65,
        risk: 'medium',
        when: [
          c,
          eq(FactKeys.observedSymptom, 'head_rot'),
          isIn(FactKeys.month, [10, 11, 12, 1]),
        ],
        recs: [
          'Meyve çürüklüğü — hasat öncesi/sırası kalıntı meyveleri toplayıp imha edin.',
          'Bakırlı koruyucu kış uygulaması düşünülebilir; BKÜ etiket kontrolü ile uygulayın.',
        ],
        confidence: 'medium',
        evidence: ev,
        expert: true,
        bku: true,
        problemId: 'disease.orange.fruit_rot',
      ),
    ];
  }

  // ════════════════════════════════════════════════════════════════════
  // 8) PESTS — Akdeniz meyve sineği en kritik
  // ════════════════════════════════════════════════════════════════════
  static List<Rule> _pests() {
    const cat = RuleCategories.pestRisk;
    final ev = pendingEvidence(SourceIds.orangeIpm);
    final c = eq(_cropFact, _cropId);
    return [
      rule(
        id: 'rule.orange.pest.med_fruit_fly',
        category: cat,
        priority: 85,
        risk: 'high',
        when: [
          c,
          eq(FactKeys.observedPest, 'med_fruit_fly'),
        ],
        recs: [
          'Akdeniz meyve sineği — turunçgilin en kritik zararlısı. Feromon tuzakla izleme şart.',
          'Tuzakta ergin görüldüğünde 7-10 gün arayla zehirli yem cezbedici (Spinosad gibi) uygulanır; BKÜ etiket kontrolü + PHI 7 gün.',
          'Hasat sonrası kalıntı meyveler toplanıp imha edilmelidir.',
        ],
        confidence: 'high',
        evidence: ev,
        expert: true,
        bku: true,
        problemId: 'pest.orange.med_fruit_fly',
      ),
      rule(
        id: 'rule.orange.pest.mealybug',
        category: cat,
        priority: 70,
        when: [c, eq(FactKeys.observedPest, 'mealybug')],
        recs: [
          'Turunçgil unlubiti — dal/yaprak/meyve sapında beyaz pamuksu örtü.',
          'Yazlık madeni yağ (mineral oil) doğal düşmanları koruyarak etkili; 25 °C üstünde uygulamayın (yaprak yanığı).',
          'BKÜ etiket kontrolü ile karar verilir.',
        ],
        confidence: 'medium',
        evidence: ev,
        expert: true,
        bku: true,
        problemId: 'pest.orange.mealybug',
      ),
      rule(
        id: 'rule.orange.pest.red_scale',
        category: cat,
        priority: 70,
        when: [c, eq(FactKeys.observedPest, 'red_scale')],
        recs: [
          'Kırmızı kabuklu bit — dal ve meyve üzerinde küçük kırmızı kabuklar.',
          'Kış-erken ilkbahar yazlık madeni yağ uygulaması temel önlem.',
          'Doğal düşmanları (parazitoidler) korumak için geniş etkili insektisitten kaçının.',
        ],
        confidence: 'medium',
        evidence: ev,
        expert: true,
        bku: true,
        problemId: 'pest.orange.red_scale',
      ),
      rule(
        id: 'rule.orange.pest.spider_mite',
        category: cat,
        priority: 65,
        when: [
          c,
          eq(FactKeys.observedPest, 'mite'),
          isIn(FactKeys.month, [6, 7, 8]),
        ],
        recs: [
          'Turunçgil kırmızı örümceği — sıcak/kuru yaz aylarında popülasyon hızla artar.',
          'Düzenli sulama + yaprak yıkama populasyonu sınırlar. Yoğun zarar varsa uzman + BKÜ ile karar verilir.',
        ],
        confidence: 'medium',
        evidence: ev,
        expert: true,
        bku: true,
        problemId: 'pest.orange.spider_mite',
      ),
      rule(
        id: 'rule.orange.pest.aphid',
        category: cat,
        priority: 55,
        when: [c, eq(FactKeys.observedPest, 'aphid')],
        recs: [
          'Yaprak biti — yeni sürgün uçlarında. Doğal düşmanlar genelde kontrol altında tutar.',
          'Yoğun bulaşma varsa uzman + BKÜ etiket kontrolü ile karar verilir.',
        ],
        confidence: 'medium',
        evidence: ev,
        expert: true,
        problemId: 'pest.orange.aphid',
      ),
    ];
  }

  // ════════════════════════════════════════════════════════════════════
  // 9) WEATHER WARNINGS — Hasat/çiçeklenme dönemi
  // ════════════════════════════════════════════════════════════════════
  static List<Rule> _weatherWarnings() {
    const cat = RuleCategories.weatherWarning;
    final ev = pendingEvidence(SourceIds.orangeAgronomy);
    final c = eq(_cropFact, _cropId);
    return [
      rule(
        id: 'rule.orange.weather.hail_risk',
        category: cat,
        priority: 85,
        risk: 'high',
        when: [c, eq(FactKeys.hailRiskNext24h, true)],
        recs: [
          'Dolu turunçgilde meyve hasarına yol açar — sonra meyve çürüklüğü kapısı açılır.',
        ],
        confidence: 'medium',
        evidence: ev,
      ),
      rule(
        id: 'rule.orange.weather.heavy_rain_flower_drop',
        category: cat,
        priority: 60,
        risk: 'medium',
        when: [
          c,
          gt(FactKeys.forecastRain48hMm, 60),
          isIn(FactKeys.month, [3, 4]),
        ],
        recs: [
          'Çiçeklenme döneminde aşırı yağış → polinasyon düşer, çiçek dökümü artar. Drenajı kontrol edin.',
        ],
        confidence: 'medium',
        evidence: ev,
      ),
    ];
  }
}
