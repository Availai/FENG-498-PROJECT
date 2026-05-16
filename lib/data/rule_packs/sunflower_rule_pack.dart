import '../../core/rule_engine/rule.dart';
import '../../core/rule_engine/rule_condition.dart';
import 'fact_keys.dart';
import 'rule_pack_dsl.dart';
import 'rule_pack_sources.dart';

/// CLAUDE.md sec 11 — `crop.sunflower` için kapsamlı deterministik kural
/// paketi. ~250 kural, 16 agronomik boyut. Hedef: çiftçi tarlada
/// herhangi bir koşul kombinasyonu girdiğinde uygulanabilir, açıklanabilir
/// Türkçe tavsiye üretmek.
///
/// **CLAUDE.md sec 28 kırmızı çizgisi**: Her kuralda `evidence` placeholder
/// olarak `pendingEvidence(SourceIds.xxx)` ile işaretlenir; üretime
/// alınmadan önce TAGEM/üniversite kaynak metni `validate-rule-pack`
/// skill'i ile doldurulur.
///
/// **CLAUDE.md sec 17 BKÜ kırmızı çizgisi**: Hiçbir kural ticari ürün
/// adı vermez. Kimyasal öneri içeren kurallar `bku: true` taşır → adapter
/// `gate: observeFirst` olarak işler ve kullanıcıyı BKÜ veritabanına
/// yönlendirir.
///
/// **CLAUDE.md sec 16 gübre kırmızı çizgisi**: Toprak analizi yokken
/// (`soil_n_level` vs. missing) kesin doz önerilmez; sadece "önce toprak
/// analizi" tavsiyesi tetiklenir.
///
/// ## Boyutlar
/// 1. Suitability             (15)
/// 2. Soil preparation        (12)
/// 3. Sowing calendar         (15)
/// 4. Sowing technique        (10)
/// 5. Emergence & seedling    (12)
/// 6. Vegetative              (12)
/// 7. Pre-flowering           (10)
/// 8. Flowering               (20)
/// 9. Grain filling           (15)
/// 10. Harvest                (10)
/// 11. Disease                (40)
/// 12. Pest                   (30)
/// 13. Weed (incl. orobanche) (12)
/// 14. Fertilization NPK      (25)
/// 15. Irrigation             (15)
/// 16. Post-harvest           (8)
/// 17. Weather warnings       (15)
/// 18. Unique (fototropizm…)  (10)
/// **Toplam:** ~286 kural
class SunflowerRulePack {
  SunflowerRulePack._();

  static const _cropId = 'crop.sunflower';
  static const _cropFact = FactKeys.cropId;

  /// Tüm paket — UI/adapter `RuleEngine.evaluate` ile tüketir.
  static List<Rule> all() => [
        ..._suitability(),
        ..._soilPreparation(),
        ..._sowingCalendar(),
        ..._sowingTechnique(),
        ..._emergenceSeedling(),
        ..._vegetative(),
        ..._preFlowering(),
        ..._flowering(),
        ..._grainFilling(),
        ..._harvest(),
        ..._disease(),
        ..._pest(),
        ..._weed(),
        ..._fertilization(),
        ..._irrigation(),
        ..._postHarvest(),
        ..._weatherWarnings(),
        ..._uniqueTraits(),
      ];

  // ════════════════════════════════════════════════════════════════════
  // 1) SUITABILITY — Ürün × bölge × toprak uygunluğu
  // ════════════════════════════════════════════════════════════════════
  static List<Rule> _suitability() {
    const cat = RuleCategories.suitability;
    final ev = pendingEvidence(SourceIds.sunflowerAgronomy);
    final c = eq(_cropFact, _cropId);
    return [
      rule(
        id: 'rule.sunflower.suit.ph_optimal',
        category: cat,
        priority: 50,
        when: [c, between(FactKeys.soilPh, 6.0, 7.5)],
        recs: ['Toprak pH değeri ayçiçeği için ideal aralıkta (6.0-7.5).'],
        confidence: 'medium',
        evidence: ev,
        explain: 'pH 6.0-7.5 ayçiçeği için optimal yetişme aralığıdır.',
      ),
      rule(
        id: 'rule.sunflower.suit.ph_acidic',
        category: cat,
        priority: 70,
        risk: 'medium',
        when: [c, lt(FactKeys.soilPh, 5.8)],
        recs: [
          'Toprak asidik (pH < 5.8). Ekim öncesi kireçleme ile pH 6.0-7.0 aralığına getirilmesi önerilir.',
          'Tarımsal kirecin etkisi 6-12 ayda görülür; bu sezon yerine gelecek sezon için planlayın.'
        ],
        confidence: 'medium',
        evidence: ev,
        explain: 'pH 5.8 altında besin alımı (özellikle P, Mo) düşer.',
      ),
      rule(
        id: 'rule.sunflower.suit.ph_alkaline',
        category: cat,
        priority: 70,
        risk: 'medium',
        when: [c, gt(FactKeys.soilPh, 8.0)],
        recs: [
          'Toprak alkali (pH > 8.0). Demir, çinko ve manganez eksikliği riski artar.',
          'Yaprak gübresi ile mikrobesin desteği planlayın.'
        ],
        confidence: 'medium',
        evidence: ev,
      ),
      rule(
        id: 'rule.sunflower.suit.ec_high',
        category: cat,
        priority: 75,
        risk: 'high',
        when: [c, gt(FactKeys.soilEc, 2.0)],
        recs: [
          'Toprak tuzluluğu yüksek (EC > 2.0 dS/m). Ayçiçeği orta tuzluluk toleranslıdır ancak çıkış ve fide döneminde verim kaybı görülür.',
          'Yıkama sulaması ve drenaj iyileştirmesi düşünün.'
        ],
        confidence: 'medium',
        evidence: ev,
      ),
      rule(
        id: 'rule.sunflower.suit.om_low',
        category: cat,
        priority: 55,
        when: [c, lt(FactKeys.organicMatterPct, 1.5)],
        recs: [
          'Toprak organik maddesi düşük (< %1.5). Yeşil gübreleme veya yanmış ahır gübresi ile iyileştirin.'
        ],
        confidence: 'medium',
        evidence: ev,
      ),
      rule(
        id: 'rule.sunflower.suit.soil_type_clay_heavy',
        category: cat,
        priority: 50,
        when: [c, eq(FactKeys.soilType, 'clay')],
        recs: [
          'Ağır killi topraklarda drenaj zayıf olabilir; ekim öncesi pulluk ve çiziyle profil derinleştirin.'
        ],
        confidence: 'low',
        evidence: ev,
      ),
      rule(
        id: 'rule.sunflower.suit.soil_type_sandy',
        category: cat,
        priority: 50,
        when: [c, eq(FactKeys.soilType, 'sandy')],
        recs: [
          'Kumlu topraklarda su tutma düşüktür; dane dolumunda sulama planı kritik. Organik madde artırın.'
        ],
        confidence: 'low',
        evidence: ev,
      ),
      rule(
        id: 'rule.sunflower.suit.soil_type_loam_ideal',
        category: cat,
        priority: 45,
        when: [c, isIn(FactKeys.soilType, ['loam', 'sandy_loam', 'clay_loam'])],
        recs: ['Tınlı topraklar ayçiçeği için ideal — su tutma ve havalanma dengeli.'],
        confidence: 'medium',
        evidence: ev,
      ),
      rule(
        id: 'rule.sunflower.suit.dryland_low_rain',
        category: cat,
        priority: 70,
        risk: 'medium',
        when: [c, eq(FactKeys.waterRegime, 'dryland'), lt(FactKeys.weeklyRainMm, 5)],
        recs: [
          'Kuru tarımda haftalık yağış 5 mm altında — tohumun çimlenme penceresinde stres riski yüksek. Ekim tarihini yağış sonrasına alın.'
        ],
        confidence: 'medium',
        evidence: ev,
      ),
      rule(
        id: 'rule.sunflower.suit.calcareous',
        category: cat,
        priority: 55,
        when: [c, eq(FactKeys.soilType, 'calcareous')],
        recs: [
          'Kireçli topraklarda demir/çinko alımı azalır. Çiçeklenme öncesinde yaprak gübresi ile mikrobesin desteği planlayın.'
        ],
        confidence: 'low',
        evidence: ev,
      ),
      rule(
        id: 'rule.sunflower.suit.region_trakya',
        category: cat,
        priority: 40,
        when: [c, eq(FactKeys.region, 'trakya')],
        recs: ['Trakya — ayçiçeği için Türkiye\'nin en uygun bölgelerinden biri.'],
        confidence: 'high',
        evidence: pendingEvidence(SourceIds.sunflowerTrakya),
      ),
      rule(
        id: 'rule.sunflower.suit.region_ic_anadolu',
        category: cat,
        priority: 40,
        when: [c, eq(FactKeys.region, 'ic_anadolu')],
        recs: [
          'İç Anadolu — kuru tarım hâkim. Çiçeklenmede yağış olmazsa verim kaybı kritik; uygunsa destek sulama planlayın.'
        ],
        confidence: 'medium',
        evidence: ev,
      ),
      rule(
        id: 'rule.sunflower.suit.region_gap',
        category: cat,
        priority: 40,
        when: [c, eq(FactKeys.region, 'gap')],
        recs: [
          'GAP bölgesi — sıcaklık stresi yüksek. İkinci ürün penceresinde dane dolumu için sulama zorunlu.'
        ],
        confidence: 'medium',
        evidence: ev,
      ),
      rule(
        id: 'rule.sunflower.suit.region_karadeniz_humid',
        category: cat,
        priority: 50,
        risk: 'medium',
        when: [c, eq(FactKeys.region, 'karadeniz')],
        recs: [
          'Karadeniz — yüksek nem mantari hastalık (mildiyö, Sclerotinia) riskini artırır. Sık scouting planlayın.'
        ],
        confidence: 'medium',
        evidence: ev,
      ),
      rule(
        id: 'rule.sunflower.suit.region_dogu_anadolu_cold',
        category: cat,
        priority: 60,
        risk: 'medium',
        when: [c, eq(FactKeys.region, 'dogu_anadolu')],
        recs: [
          'Doğu Anadolu — vejetasyon süresi kısa. Erken hasatlı çeşit seçin; geç ekimde olgunlaşma riski.'
        ],
        confidence: 'medium',
        evidence: ev,
      ),
    ];
  }

  // ════════════════════════════════════════════════════════════════════
  // 2) SOIL PREPARATION — Toprak hazırlığı
  // ════════════════════════════════════════════════════════════════════
  static List<Rule> _soilPreparation() {
    const cat = RuleCategories.soilAnalysis;
    final ev = pendingEvidence(SourceIds.soilFertilizerGeneral);
    final c = eq(_cropFact, _cropId);
    final prep = pendingEvidence(SourceIds.sunflowerAgronomy);
    return [
      rule(
        id: 'rule.sunflower.soil.no_analysis',
        category: cat,
        priority: 80,
        risk: 'medium',
        when: [c, missing(FactKeys.soilPh)],
        recs: [
          'Toprak analizi yapılmamış. Ekim öncesi pH, EC, organik madde, N-P-K değerleri için analiz yaptırın.',
          'Analiz olmadan kesin gübre miktarı önerilemez (CLAUDE.md sec 16).'
        ],
        confidence: 'high',
        evidence: ev,
        explain: 'CLAUDE.md sec 16 — toprak analizi yoksa net gübre dozu önerilmez.',
      ),
      rule(
        id: 'rule.sunflower.soil.ph_correction_lime',
        category: cat,
        priority: 65,
        when: [c, between(FactKeys.soilPh, 4.5, 5.8)],
        recs: [
          'Asidik toprağa kireçleme önerilir. Doz toprak analizi ve toprağın tampon kapasitesine göre belirlenmeli — uzmana danışın.'
        ],
        confidence: 'medium',
        evidence: ev,
        expert: true,
      ),
      rule(
        id: 'rule.sunflower.soil.gypsum_alkaline',
        category: cat,
        priority: 55,
        when: [c, gt(FactKeys.soilPh, 8.2), gt(FactKeys.soilEc, 1.5)],
        recs: [
          'Sodik/tuzlu-alkali toprakta jips uygulaması ve yıkama sulaması düşünülmelidir. Uzman önerisi alın.'
        ],
        confidence: 'low',
        evidence: ev,
        expert: true,
      ),
      rule(
        id: 'rule.sunflower.soil.deep_tillage_clay',
        category: cat,
        priority: 50,
        when: [c, eq(FactKeys.soilType, 'clay'), missing(FactKeys.lastTillageDaysAgo)],
        recs: [
          'Killi toprakta sonbaharda derin sürüm (chisel/pulluk) köklenme derinliğini artırır.'
        ],
        confidence: 'medium',
        evidence: prep,
      ),
      rule(
        id: 'rule.sunflower.soil.crust_risk_after_rain',
        category: cat,
        priority: 70,
        risk: 'medium',
        when: [c, eq(FactKeys.soilType, 'clay'), gt(FactKeys.forecastRain24hMm, 15)],
        recs: [
          'Killi toprakta yağmur sonrası yüzey kabuğu çimlenmeyi engelleyebilir. Yağış sonrası 24 saat içinde tırmık ile yüzey kabuğunu kırın.'
        ],
        confidence: 'medium',
        evidence: prep,
      ),
      rule(
        id: 'rule.sunflower.soil.drainage_check_clay',
        category: cat,
        priority: 50,
        when: [c, eq(FactKeys.soilType, 'clay'), gt(FactKeys.soilMoisture, 0.45)],
        recs: ['Ağır killi toprakta su göllenmesi gözlemleniyor — drenaj kanallarını kontrol edin.'],
        confidence: 'low',
        evidence: prep,
      ),
      rule(
        id: 'rule.sunflower.soil.organic_amend',
        category: cat,
        priority: 45,
        when: [c, lt(FactKeys.organicMatterPct, 1.2)],
        recs: [
          'Organik madde %1.2\'nin altında — yanmış ahır gübresi (2-3 ton/dekar) veya yeşil gübreleme planlayın.'
        ],
        confidence: 'medium',
        evidence: ev,
      ),
      rule(
        id: 'rule.sunflower.soil.salinity_emergence',
        category: cat,
        priority: 80,
        risk: 'high',
        when: [c, gt(FactKeys.soilEc, 2.5), isIn(FactKeys.growthStage, ['germination', 'emergence'])],
        recs: [
          'Yüksek tuzluluk + çıkış evresi = fide kaybı çok yüksek. Yıkama sulaması veya tuzdan etkilenmemiş alanda yeniden ekim düşünün.'
        ],
        confidence: 'medium',
        evidence: ev,
      ),
      rule(
        id: 'rule.sunflower.soil.cold_for_sowing',
        category: cat,
        priority: 70,
        risk: 'medium',
        when: [c, lt(FactKeys.soilTempC, 8.0), isIn(FactKeys.growthStage, ['germination'])],
        recs: [
          'Toprak sıcaklığı 8 °C altında — çimlenme yavaş, kabuk bağlama ve hastalık riski artar. Toprak 10-12 °C\'ye ulaştığında ekim yapın.'
        ],
        confidence: 'medium',
        evidence: prep,
      ),
      rule(
        id: 'rule.sunflower.soil.warm_optimal',
        category: cat,
        priority: 40,
        when: [c, between(FactKeys.soilTempC, 10, 18), isIn(FactKeys.growthStage, ['germination'])],
        recs: ['Toprak sıcaklığı ayçiçeği çimlenmesi için ideal aralıkta.'],
        confidence: 'medium',
        evidence: prep,
      ),
      rule(
        id: 'rule.sunflower.soil.wet_at_sowing',
        category: cat,
        priority: 60,
        when: [c, gt(FactKeys.soilMoisture, 0.40), isIn(FactKeys.growthStage, ['germination', 'pre_planting' as Object])],
        recs: ['Toprak çok ıslak; ekim ekipmanı sıkıştırma yapabilir, ekim 2-3 gün ertelensin.'],
        confidence: 'low',
        evidence: prep,
      ),
      rule(
        id: 'rule.sunflower.soil.previous_sunflower_warning',
        category: cat,
        priority: 75,
        risk: 'medium',
        when: [c, gt(FactKeys.lastTillageDaysAgo, 0)],
        recs: [
          'Önceki yıl aynı tarlada ayçiçeği ekildi mi kontrol edin — ayçiçeği için en az 4 yıllık ekim nöbeti zorunludur (orobanş ve Sclerotinia riski).'
        ],
        confidence: 'medium',
        evidence: pendingEvidence(SourceIds.sunflowerOrobanche),
      ),
    ];
  }

  // ════════════════════════════════════════════════════════════════════
  // 3) SOWING CALENDAR — Ekim takvimi (bölge × ay)
  // ════════════════════════════════════════════════════════════════════
  static List<Rule> _sowingCalendar() {
    const cat = RuleCategories.sowingOrPlanting;
    final ev = pendingEvidence(SourceIds.sunflowerAgronomy);
    final c = eq(_cropFact, _cropId);
    return [
      // Trakya: Mart sonu - Nisan
      rule(
        id: 'rule.sunflower.sow.trakya_optimal',
        category: cat,
        priority: 60,
        when: [c, eq(FactKeys.region, 'trakya'), isIn(FactKeys.month, [3, 4])],
        recs: ['Trakya için ayçiçeği ekim penceresi: Mart sonu - Nisan ortası. Toprak 10 °C\'ye ulaştığında ekin.'],
        confidence: 'medium',
        evidence: ev,
      ),
      rule(
        id: 'rule.sunflower.sow.trakya_late',
        category: cat,
        priority: 60,
        risk: 'medium',
        when: [c, eq(FactKeys.region, 'trakya'), gte(FactKeys.month, 5)],
        recs: ['Trakya için ekim geç kaldı — verim potansiyeli düşer. Geç çeşit veya farklı ürün düşünün.'],
        confidence: 'medium',
        evidence: ev,
      ),
      // Ege: Mart - Nisan başı
      rule(
        id: 'rule.sunflower.sow.ege_optimal',
        category: cat,
        priority: 60,
        when: [c, eq(FactKeys.region, 'ege'), isIn(FactKeys.month, [3, 4])],
        recs: ['Ege için ekim penceresi: Mart ortası - Nisan başı.'],
        confidence: 'medium',
        evidence: ev,
      ),
      // İç Anadolu: Nisan - Mayıs başı (toprak geç ısınır)
      rule(
        id: 'rule.sunflower.sow.ic_anadolu_optimal',
        category: cat,
        priority: 60,
        when: [c, eq(FactKeys.region, 'ic_anadolu'), isIn(FactKeys.month, [4, 5])],
        recs: ['İç Anadolu için ekim penceresi: Nisan ortası - Mayıs başı.'],
        confidence: 'medium',
        evidence: ev,
      ),
      rule(
        id: 'rule.sunflower.sow.ic_anadolu_too_early',
        category: cat,
        priority: 65,
        risk: 'medium',
        when: [c, eq(FactKeys.region, 'ic_anadolu'), lte(FactKeys.month, 3)],
        recs: ['İç Anadolu\'da Mart sonundan önce toprak yeterince ısınmamış — geç don ve yavaş çıkış riski.'],
        confidence: 'medium',
        evidence: ev,
      ),
      // GAP: ikinci ürün için Haziran-Temmuz
      rule(
        id: 'rule.sunflower.sow.gap_second_crop',
        category: cat,
        priority: 60,
        when: [c, eq(FactKeys.region, 'gap'), isIn(FactKeys.month, [6, 7])],
        recs: ['GAP\'ta ikinci ürün penceresi: Haziran - Temmuz başı. Sulama zorunlu.'],
        confidence: 'medium',
        evidence: ev,
      ),
      // Karadeniz
      rule(
        id: 'rule.sunflower.sow.karadeniz_optimal',
        category: cat,
        priority: 60,
        when: [c, eq(FactKeys.region, 'karadeniz'), isIn(FactKeys.month, [4, 5])],
        recs: ['Karadeniz için ekim penceresi: Nisan ortası - Mayıs ortası. Nem yüksek olduğundan iyi havalanan tarla seçin.'],
        confidence: 'medium',
        evidence: ev,
      ),
      // Doğu Anadolu
      rule(
        id: 'rule.sunflower.sow.dogu_anadolu_optimal',
        category: cat,
        priority: 60,
        when: [c, eq(FactKeys.region, 'dogu_anadolu'), isIn(FactKeys.month, [5, 6])],
        recs: ['Doğu Anadolu için ekim penceresi: Mayıs ortası - Haziran. Erken hasatlı çeşit seçin.'],
        confidence: 'medium',
        evidence: ev,
      ),
      // Akdeniz
      rule(
        id: 'rule.sunflower.sow.akdeniz_optimal',
        category: cat,
        priority: 60,
        when: [c, eq(FactKeys.region, 'akdeniz'), isIn(FactKeys.month, [2, 3])],
        recs: ['Akdeniz için ekim penceresi: Şubat sonu - Mart. Erken ekimle yazın sıcak stresinden kaçınılır.'],
        confidence: 'medium',
        evidence: ev,
      ),
      // Genel ekim koşulları
      rule(
        id: 'rule.sunflower.sow.rain_block',
        category: cat,
        priority: 70,
        risk: 'medium',
        when: [c, isIn(FactKeys.growthStage, ['germination']), gt(FactKeys.forecastRain24hMm, 20)],
        recs: ['Önümüzdeki 24 saatte 20 mm üzerinde yağış bekleniyor — ekim sonrası kabuk bağlama riski. Ekimi yağış sonrasına alın.'],
        confidence: 'medium',
        evidence: ev,
      ),
      rule(
        id: 'rule.sunflower.sow.wind_block',
        category: cat,
        priority: 60,
        when: [c, isIn(FactKeys.growthStage, ['germination']), gt(FactKeys.windSpeedMs, 8)],
        recs: ['Rüzgar > 8 m/s — mibzer kalibrasyonu bozulabilir, tohum dağılımı eşitsiz olur. Sakin saatlerde ekin.'],
        confidence: 'low',
        evidence: ev,
      ),
      rule(
        id: 'rule.sunflower.sow.frost_block',
        category: cat,
        priority: 90,
        risk: 'high',
        when: [c, isIn(FactKeys.growthStage, ['germination']), eq(FactKeys.frostRiskNext48h, true)],
        recs: ['Önümüzdeki 48 saatte don riski — ekimi don tehlikesi geçtikten sonraya alın.'],
        confidence: 'high',
        evidence: pendingEvidence(SourceIds.meteorologyMgm),
      ),
      rule(
        id: 'rule.sunflower.sow.too_dry_topsoil',
        category: cat,
        priority: 65,
        risk: 'medium',
        when: [c, isIn(FactKeys.growthStage, ['germination']), lt(FactKeys.soilMoisture, 0.18)],
        recs: ['Yüzey toprağı çok kuru — tohum çimlenme için yetersiz nem. Çıkış sulaması düşünün veya yağış sonrasına ekin.'],
        confidence: 'medium',
        evidence: ev,
      ),
      rule(
        id: 'rule.sunflower.sow.month_too_late_general',
        category: cat,
        priority: 70,
        risk: 'medium',
        when: [c, gt(FactKeys.month, 7)],
        recs: ['Temmuz sonrası ekim — çoğu bölgede vejetasyon süresi yetmez; ürün riski yüksek.'],
        confidence: 'medium',
        evidence: ev,
      ),
      rule(
        id: 'rule.sunflower.sow.month_too_early_general',
        category: cat,
        priority: 70,
        risk: 'medium',
        when: [c, lt(FactKeys.month, 2)],
        recs: ['Ocak ekimi — toprak çok soğuk, ayçiçeği için uygun değil. Bölgenize uygun ekim ayını bekleyin.'],
        confidence: 'medium',
        evidence: ev,
      ),
    ];
  }

  // ════════════════════════════════════════════════════════════════════
  // 4) SOWING TECHNIQUE — Ekim tekniği
  // ════════════════════════════════════════════════════════════════════
  static List<Rule> _sowingTechnique() {
    const cat = RuleCategories.sowingOrPlanting;
    final ev = pendingEvidence(SourceIds.sunflowerAgronomy);
    final c = eq(_cropFact, _cropId);
    final germ = isIn(FactKeys.growthStage, ['germination', 'emergence']);
    return [
      rule(
        id: 'rule.sunflower.tech.row_spacing',
        category: cat,
        priority: 40,
        when: [c, germ],
        recs: [
          'Standart sıra arası 70 cm, bitki arası 25-30 cm — sulu tarımda 60×20\'a kadar inilebilir.'
        ],
        confidence: 'medium',
        evidence: ev,
      ),
      rule(
        id: 'rule.sunflower.tech.depth_dry',
        category: cat,
        priority: 45,
        when: [c, germ, lt(FactKeys.soilMoisture, 0.22)],
        recs: ['Kuru toprakta tohum derinliği 5-6 cm — neme ulaşması için.'],
        confidence: 'medium',
        evidence: ev,
      ),
      rule(
        id: 'rule.sunflower.tech.depth_moist',
        category: cat,
        priority: 45,
        when: [c, germ, gte(FactKeys.soilMoisture, 0.22)],
        recs: ['Nemli toprakta tohum derinliği 3-4 cm yeterlidir.'],
        confidence: 'medium',
        evidence: ev,
      ),
      rule(
        id: 'rule.sunflower.tech.plant_density_dryland',
        category: cat,
        priority: 50,
        when: [c, germ, eq(FactKeys.waterRegime, 'dryland')],
        recs: ['Kuru tarımda hedef yoğunluk 5-6 bin bitki/dekar (su rekabetini azaltmak için).'],
        confidence: 'medium',
        evidence: ev,
      ),
      rule(
        id: 'rule.sunflower.tech.plant_density_irrigated',
        category: cat,
        priority: 50,
        when: [c, germ, eq(FactKeys.waterRegime, 'irrigated')],
        recs: ['Sulu tarımda hedef yoğunluk 6-7 bin bitki/dekar.'],
        confidence: 'medium',
        evidence: ev,
      ),
      rule(
        id: 'rule.sunflower.tech.too_dense',
        category: cat,
        priority: 55,
        risk: 'medium',
        when: [c, gt(FactKeys.estimatedPlantCount, 8000)],
        recs: [
          'Bitki yoğunluğu 8 bin/dekar üstünde — birim alana fazla bitki, küçük baş ve düşük dane ağırlığı riski.'
        ],
        confidence: 'low',
        evidence: ev,
      ),
      rule(
        id: 'rule.sunflower.tech.calibrate_seeder',
        category: cat,
        priority: 40,
        when: [c, germ],
        recs: ['Mibzeri sahada test ekimle kalibre edin: hedef bitki sayısının ±%5 toleransında olmalı.'],
        confidence: 'low',
        evidence: ev,
      ),
      rule(
        id: 'rule.sunflower.tech.seed_treatment_check',
        category: cat,
        priority: 55,
        when: [c, germ],
        recs: [
          'Tohum mantar/zararlı için ilaçlanmış (treated) mı kontrol edin — değilse tarla koşullarına göre tohum koruma planlanmalıdır. BKÜ veritabanında güncel ruhsat kontrolü gerekir.'
        ],
        confidence: 'medium',
        evidence: pendingEvidence(SourceIds.bkuRegistry),
        bku: true,
      ),
      rule(
        id: 'rule.sunflower.tech.contour_planting_slope',
        category: cat,
        priority: 45,
        when: [c, germ, eq(FactKeys.region, 'dogu_anadolu')],
        recs: ['Eğimli arazide kontur ekimi erozyonu azaltır.'],
        confidence: 'low',
        evidence: ev,
      ),
      rule(
        id: 'rule.sunflower.tech.precision_seeder_advice',
        category: cat,
        priority: 35,
        when: [c, germ, gte(FactKeys.fieldAreaDekar, 30)],
        recs: ['Geniş alanlarda hassas mibzer (pnömatik) sıra arası ve derinlik tutarlılığı için tavsiye edilir.'],
        confidence: 'low',
        evidence: ev,
      ),
    ];
  }

  // ════════════════════════════════════════════════════════════════════
  // 5) EMERGENCE & SEEDLING — Çıkış ve fide
  // ════════════════════════════════════════════════════════════════════
  static List<Rule> _emergenceSeedling() {
    const cat = RuleCategories.taskGeneration;
    final ev = pendingEvidence(SourceIds.sunflowerAgronomy);
    final c = eq(_cropFact, _cropId);
    final stage = isIn(FactKeys.growthStage, ['emergence', 'seedling']);
    return [
      rule(
        id: 'rule.sunflower.seed.crusting_break',
        category: cat,
        priority: 75,
        risk: 'medium',
        when: [c, stage, eq(FactKeys.soilType, 'clay'), gt(FactKeys.forecastRain24hMm, 10)],
        recs: ['Yağış sonrası 24 saat içinde yüzey kabuğunu tırmıkla kırın — fide çıkışını engellememesi için.'],
        confidence: 'medium',
        evidence: ev,
      ),
      rule(
        id: 'rule.sunflower.seed.cold_stress',
        category: cat,
        priority: 70,
        risk: 'medium',
        when: [c, stage, lt(FactKeys.tempMin24hC, 4)],
        recs: ['Gece minimum sıcaklığı 4 °C altında — fide soğuk stresi. Don olmazsa çıkış yavaşlar; don olursa fide kaybı kritik.'],
        confidence: 'medium',
        evidence: ev,
      ),
      rule(
        id: 'rule.sunflower.seed.frost_warn',
        category: cat,
        priority: 95,
        risk: 'high',
        when: [c, stage, eq(FactKeys.frostRiskNext48h, true)],
        recs: ['48 saatte don riski + fide dönemi — fide kaybı çok yüksek. Kuvvetli rüzgarda örtü mümkün değilse alanı izleyin, ölü fideler için yeniden ekim planlayın.'],
        confidence: 'high',
        evidence: pendingEvidence(SourceIds.meteorologyMgm),
      ),
      rule(
        id: 'rule.sunflower.seed.bird_damage_warn',
        category: cat,
        priority: 65,
        when: [c, stage],
        recs: [
          'Çıkış evresinde kuş zararı yaygındır. Bostan korkuluğu, ses tabancası veya net kullanımı planlayın.'
        ],
        confidence: 'low',
        evidence: ev,
      ),
      rule(
        id: 'rule.sunflower.seed.cutworm_scouting',
        category: cat,
        priority: 60,
        when: [c, stage],
        recs: [
          'Fide kıyımı (Agrotis, bozkurt) için tarlayı haftada 1 kez gözlemleyin — gece aktif zararlı, fideyi tabandan keser.'
        ],
        confidence: 'medium',
        evidence: pendingEvidence(SourceIds.sunflowerIpm),
      ),
      rule(
        id: 'rule.sunflower.seed.thinning_check',
        category: cat,
        priority: 40,
        when: [c, stage],
        recs: ['Çıkış tamamlandığında bitki sayımı yapın — hedef yoğunluğun ±%15 dışındaysa elle seyreltme planlayın.'],
        confidence: 'low',
        evidence: ev,
      ),
      rule(
        id: 'rule.sunflower.seed.weed_pre_emergence',
        category: cat,
        priority: 60,
        when: [c, stage, missing(FactKeys.lastSprayedDaysAgo)],
        recs: [
          'Çıkış öncesi veya çıkış sonrası erken yabancı ot kontrolü kritik — ayçiçeği rekabete duyarlıdır. Etken madde seçimi için BKÜ kontrolü yapın.'
        ],
        confidence: 'medium',
        evidence: pendingEvidence(SourceIds.bkuRegistry),
        bku: true,
      ),
      rule(
        id: 'rule.sunflower.seed.uneven_stand',
        category: cat,
        priority: 50,
        when: [c, stage, lt(FactKeys.estimatedPlantCount, 3500)],
        recs: ['Çıkış zayıf görünüyor (< 3500 bitki/dekar). Sebep belirleyin: kabuk, böcek, tohum kalitesi.'],
        confidence: 'low',
        evidence: ev,
      ),
      rule(
        id: 'rule.sunflower.seed.replant_consider',
        category: cat,
        priority: 70,
        risk: 'medium',
        when: [c, stage, lt(FactKeys.estimatedPlantCount, 2000)],
        recs: ['Çıkış çok zayıf (< 2000 bitki/dekar) — yeniden ekim ekonomik mi değerlendirin.'],
        confidence: 'low',
        evidence: ev,
      ),
      rule(
        id: 'rule.sunflower.seed.early_n_starter',
        category: cat,
        priority: 45,
        when: [c, stage, eq(FactKeys.nLevel, 'low')],
        recs: ['Toprak N düşük + erken evre — starter N gübresi (yaklaşık ekimle birlikte) düşünün; toprak analizine göre miktar belirleyin.'],
        confidence: 'low',
        evidence: pendingEvidence(SourceIds.soilFertilizerGeneral),
      ),
      rule(
        id: 'rule.sunflower.seed.hot_wind_drying',
        category: cat,
        priority: 60,
        when: [c, stage, gt(FactKeys.tempMax24hC, 32), lt(FactKeys.soilMoisture, 0.20)],
        recs: ['Yüksek sıcaklık + kuru toprak — fide su stresine girer. Çıkış sulaması düşünün.'],
        confidence: 'medium',
        evidence: ev,
      ),
      rule(
        id: 'rule.sunflower.seed.flea_beetle',
        category: cat,
        priority: 50,
        when: [c, stage, eq(FactKeys.observedPest, 'flea_beetle')],
        recs: [
          'Pire/yaprak böceği gözlemi — eşik ekonomik düzeyde değilse mücadele gerekmez. Eşik üzerinde ise BKÜ kontrolüyle önerilmiş etken madde uygulanır.'
        ],
        confidence: 'low',
        evidence: pendingEvidence(SourceIds.sunflowerIpm),
        expert: true,
        bku: true,
      ),
    ];
  }

  // ════════════════════════════════════════════════════════════════════
  // 6) VEGETATIVE — Vejetatif dönem
  // ════════════════════════════════════════════════════════════════════
  static List<Rule> _vegetative() {
    const cat = RuleCategories.taskGeneration;
    final ev = pendingEvidence(SourceIds.sunflowerAgronomy);
    final c = eq(_cropFact, _cropId);
    final stage = eq(FactKeys.growthStage, 'vegetative');
    return [
      rule(
        id: 'rule.sunflower.veg.weed_window',
        category: RuleCategories.weedManagement,
        priority: 70,
        when: [c, stage, between(FactKeys.daysAfterPlanting, 14, 35)],
        recs: [
          '14-35. günler arası kritik yabancı ot rekabeti penceresi. Kapuz öncesi mücadele bu pencerede yapılmalı; BKÜ kontrolü gerekir.'
        ],
        confidence: 'medium',
        evidence: pendingEvidence(SourceIds.sunflowerIpm),
        bku: true,
      ),
      rule(
        id: 'rule.sunflower.veg.n_top_dress',
        category: RuleCategories.fertilization,
        priority: 55,
        when: [c, stage, eq(FactKeys.nLevel, 'low'), between(FactKeys.daysAfterPlanting, 20, 40)],
        recs: ['Vejetatif evrede N üst gübresi — toprak analizine göre kalan miktar verilir. Hızlı büyüme için kritik.'],
        confidence: 'medium',
        evidence: pendingEvidence(SourceIds.soilFertilizerGeneral),
      ),
      rule(
        id: 'rule.sunflower.veg.cultivation_inter_row',
        category: cat,
        priority: 45,
        when: [c, stage, between(FactKeys.daysAfterPlanting, 25, 45)],
        recs: ['Sıra arası çapa ile yabancı ot kontrolü ve toprak havalanması — bitkiye toprak çekme dahil.'],
        confidence: 'low',
        evidence: ev,
      ),
      rule(
        id: 'rule.sunflower.veg.water_deficit_early',
        category: RuleCategories.irrigation,
        priority: 50,
        when: [c, stage, lt(FactKeys.weeklyWaterRatio, 0.6)],
        recs: ['Haftalık su hedefin %60\'ı altında — vejetatif evrede orta düzey su stresi. Sulamayı artırın.'],
        confidence: 'low',
        evidence: ev,
      ),
      rule(
        id: 'rule.sunflower.veg.scout_disease',
        category: RuleCategories.diseaseRisk,
        priority: 50,
        when: [c, stage, between(FactKeys.daysAfterPlanting, 30, 60)],
        recs: ['Yaprak hastalıkları için haftalık scouting başlatın — özellikle Alternaria, septoria erken belirtileri.'],
        confidence: 'low',
        evidence: pendingEvidence(SourceIds.sunflowerIpm),
      ),
      rule(
        id: 'rule.sunflower.veg.lush_growth_warn',
        category: cat,
        priority: 50,
        when: [c, stage, eq(FactKeys.nLevel, 'high')],
        recs: ['Aşırı N — yumuşak vejetatif büyüme, hastalık ve yatış (lodging) riskini artırır.'],
        confidence: 'low',
        evidence: ev,
      ),
      rule(
        id: 'rule.sunflower.veg.iron_deficiency',
        category: RuleCategories.fertilization,
        priority: 55,
        when: [c, stage, gt(FactKeys.soilPh, 8.0)],
        recs: [
          'Alkali toprak + vejetatif — demir kloroz riski. Yaprak sararması görülürse şelatlı demir yaprak gübresi düşünün.'
        ],
        confidence: 'low',
        evidence: ev,
      ),
      rule(
        id: 'rule.sunflower.veg.heat_stress_check',
        category: RuleCategories.weatherWarning,
        priority: 60,
        when: [c, stage, gt(FactKeys.tempMax24hC, 35)],
        recs: ['35 °C üstü sıcaklık — fotosentez verimliliği düşer. Sulama varsa öğleden önce/sonra uygula.'],
        confidence: 'medium',
        evidence: ev,
      ),
      rule(
        id: 'rule.sunflower.veg.boron_check',
        category: RuleCategories.fertilization,
        priority: 50,
        when: [c, stage, between(FactKeys.daysAfterPlanting, 30, 50)],
        recs: [
          'Ayçiçeği bor için duyarlıdır. Toprak bor seviyesi düşükse çiçeklenme öncesi yaprak gübresi düşünülmelidir; doz uzmana danışılarak belirlenir.'
        ],
        confidence: 'low',
        evidence: ev,
        expert: true,
      ),
      rule(
        id: 'rule.sunflower.veg.uniform_canopy_check',
        category: cat,
        priority: 40,
        when: [c, stage, gte(FactKeys.daysAfterPlanting, 35)],
        recs: ['Bitki örtüsü tarla genelinde eşit mi kontrol edin — eşitsizlik sulama veya toprak farkına işaret eder.'],
        confidence: 'low',
        evidence: ev,
      ),
      rule(
        id: 'rule.sunflower.veg.bud_initiation_signal',
        category: cat,
        priority: 35,
        when: [c, stage, gte(FactKeys.daysAfterPlanting, 45)],
        recs: ['Tomurcuk başlangıcı (R1) yaklaşıyor — sulama planını çiçeklenme talebine göre ayarlayın.'],
        confidence: 'medium',
        evidence: ev,
      ),
      rule(
        id: 'rule.sunflower.veg.diseased_majority_alert',
        category: RuleCategories.diseaseRisk,
        priority: 80,
        risk: 'high',
        when: [c, stage, eq(FactKeys.plantHealthSummary, 'diseased_majority')],
        recs: [
          'Tarlada hastalıklı bitki oranı yüksek — uzmana danışın; izole edilen örnekler tanı için ilçe tarım müdürlüğüne götürülebilir.'
        ],
        confidence: 'medium',
        evidence: pendingEvidence(SourceIds.sunflowerIpm),
        expert: true,
      ),
    ];
  }

  // ════════════════════════════════════════════════════════════════════
  // 7) PRE-FLOWERING — Çiçeklenme öncesi (R1-R4)
  // ════════════════════════════════════════════════════════════════════
  static List<Rule> _preFlowering() {
    const cat = RuleCategories.taskGeneration;
    final ev = pendingEvidence(SourceIds.sunflowerAgronomy);
    final c = eq(_cropFact, _cropId);
    final stage = eq(FactKeys.growthStage, 'pre_flowering');
    return [
      rule(
        id: 'rule.sunflower.preflower.water_target_raise',
        category: RuleCategories.irrigation,
        priority: 60,
        when: [c, stage],
        recs: ['Çiçeklenme öncesi su talebi artıyor — haftalık sulama hedefini %25-30 artırın.'],
        confidence: 'medium',
        evidence: ev,
      ),
      rule(
        id: 'rule.sunflower.preflower.boron_critical',
        category: RuleCategories.fertilization,
        priority: 65,
        when: [c, stage],
        recs: [
          'Çiçeklenme öncesi bor talebi en yüksek. Eksiklik belirtisi (deforme baş, boş çiçek) görülürse uzman önerisiyle yaprak bor uygulayın.'
        ],
        confidence: 'medium',
        evidence: ev,
        expert: true,
      ),
      rule(
        id: 'rule.sunflower.preflower.lodging_wind_warn',
        category: RuleCategories.weatherWarning,
        priority: 70,
        risk: 'medium',
        when: [c, stage, gt(FactKeys.windSpeedMs, 12)],
        recs: ['Yüksek rüzgar + çiçeklenme öncesi — yüksek bitki yatış (lodging) riski. Bitkiye toprak çekildi mi kontrol edin.'],
        confidence: 'medium',
        evidence: ev,
      ),
      rule(
        id: 'rule.sunflower.preflower.scout_sclerotinia',
        category: RuleCategories.diseaseRisk,
        priority: 65,
        when: [c, stage, eq(FactKeys.humidityLevel, 'high')],
        recs: ['Yüksek nem + çiçeklenme öncesi — Sclerotinia baş ve sap çürüklüğü riski artar. Haftalık scouting.'],
        confidence: 'medium',
        evidence: pendingEvidence(SourceIds.sunflowerIpm),
      ),
      rule(
        id: 'rule.sunflower.preflower.no_late_n',
        category: RuleCategories.fertilization,
        priority: 55,
        when: [c, stage, eq(FactKeys.nLevel, 'high')],
        recs: ['Çiçeklenmeye yakın geç N gübresi vermeyin — yatış ve gecikmiş olgunlaşma riski.'],
        confidence: 'low',
        evidence: ev,
      ),
      rule(
        id: 'rule.sunflower.preflower.last_pesticide_window',
        category: RuleCategories.safetyWarning,
        priority: 75,
        when: [c, stage],
        recs: [
          'Çiçeklenme yaklaşıyor — arı dostu yönetim kritik. Bu evrede ve sonrasında insektisit uygulamaları arı için riskli; BKÜ kontrolü + akşam saatlerinde uygulama gerekir.'
        ],
        confidence: 'medium',
        evidence: pendingEvidence(SourceIds.bkuRegistry),
        bku: true,
      ),
      rule(
        id: 'rule.sunflower.preflower.helicoverpa_scout',
        category: RuleCategories.pestRisk,
        priority: 60,
        when: [c, stage],
        recs: ['Helicoverpa (yeşil kurt) tomurcuk-baş zarar verir. Tarlayı haftada 2 kez gözlemleyin.'],
        confidence: 'medium',
        evidence: pendingEvidence(SourceIds.sunflowerIpm),
      ),
      rule(
        id: 'rule.sunflower.preflower.height_uniform',
        category: cat,
        priority: 35,
        when: [c, stage],
        recs: ['Bitki boyu eşit mi kontrol edin — eşitsizlik su/besin stresinin işareti.'],
        confidence: 'low',
        evidence: ev,
      ),
      rule(
        id: 'rule.sunflower.preflower.rust_scout',
        category: RuleCategories.diseaseRisk,
        priority: 55,
        when: [c, stage, eq(FactKeys.humidityLevel, 'high')],
        recs: ['Yaprak alt yüzeyinde turuncu pas püstülleri kontrol edin — pas çiçeklenmeye yakın hızla yayılır.'],
        confidence: 'low',
        evidence: pendingEvidence(SourceIds.sunflowerIpm),
      ),
      rule(
        id: 'rule.sunflower.preflower.water_check_pre_flower',
        category: RuleCategories.irrigation,
        priority: 65,
        when: [c, stage, lt(FactKeys.soilMoisture, 0.22)],
        recs: ['Toprak nemi düşük + çiçeklenme öncesi — sulama önceliği yüksek; sulama yapılmazsa baş büyüklüğü düşer.'],
        confidence: 'medium',
        evidence: ev,
      ),
    ];
  }

  // ════════════════════════════════════════════════════════════════════
  // 8) FLOWERING — Çiçeklenme (R5)
  // ════════════════════════════════════════════════════════════════════
  static List<Rule> _flowering() {
    const cat = RuleCategories.taskGeneration;
    final ev = pendingEvidence(SourceIds.sunflowerAgronomy);
    final c = eq(_cropFact, _cropId);
    final stage = eq(FactKeys.growthStage, 'flowering');
    return [
      rule(
        id: 'rule.sunflower.flower.water_peak',
        category: RuleCategories.irrigation,
        priority: 85,
        risk: 'high',
        when: [c, stage, lt(FactKeys.weeklyWaterRatio, 0.7)],
        recs: ['Çiçeklenme + su açığı — verim için en kritik dönem. Sulamayı acil tamamlayın.'],
        confidence: 'high',
        evidence: ev,
      ),
      rule(
        id: 'rule.sunflower.flower.heat_stress',
        category: RuleCategories.weatherWarning,
        priority: 75,
        risk: 'high',
        when: [c, stage, gt(FactKeys.tempMax24hC, 35)],
        recs: ['35 °C üstü + çiçeklenme — polen sterilitesi, boş tabla riski. Sulama varsa toprağı serin tutmaya çalışın.'],
        confidence: 'medium',
        evidence: ev,
      ),
      rule(
        id: 'rule.sunflower.flower.bee_protection',
        category: RuleCategories.safetyWarning,
        priority: 90,
        risk: 'high',
        when: [c, stage],
        recs: [
          'Çiçeklenme = arı dönemi. Bu evrede insektisit uygulanması arı kolonilerini ciddi tehdit eder; zorunluysa akşam saatlerinde, arı dostu (kontak değil) etken madde, BKÜ kontrolü, ilçe tarım müdürlüğü bilgilendirmesi gerekir.'
        ],
        confidence: 'high',
        evidence: pendingEvidence(SourceIds.bkuRegistry),
        bku: true,
        expert: true,
      ),
      rule(
        id: 'rule.sunflower.flower.sclerotinia_high_risk',
        category: RuleCategories.diseaseRisk,
        priority: 80,
        risk: 'high',
        when: [c, stage, eq(FactKeys.humidityLevel, 'high'), gt(FactKeys.forecastRain48hMm, 15)],
        recs: [
          'Yüksek nem + 48 saatte yağış + çiçeklenme — Sclerotinia (kurşuni küf) baş çürüklüğü riski çok yüksek. Tarlayı yakın izleyin; mücadele için BKÜ kontrolüyle koruyucu fungisit düşünülebilir, uzman onayı gerekir.'
        ],
        confidence: 'medium',
        evidence: pendingEvidence(SourceIds.sunflowerIpm),
        bku: true,
        expert: true,
      ),
      rule(
        id: 'rule.sunflower.flower.alternaria_risk',
        category: RuleCategories.diseaseRisk,
        priority: 70,
        when: [c, stage, eq(FactKeys.observedSymptom, 'leaf_spot')],
        recs: [
          'Yaprak leke + çiçeklenme — olası Alternaria. Uzman onayıyla tanı doğrulayın, BKÜ kontrolü ile koruyucu fungisit değerlendirin.'
        ],
        confidence: 'low',
        evidence: pendingEvidence(SourceIds.sunflowerIpm),
        expert: true,
        bku: true,
      ),
      rule(
        id: 'rule.sunflower.flower.head_facing_check',
        category: RuleCategories.cropUnique,
        priority: 30,
        when: [c, stage],
        recs: ['Genç başlar fototropik (heliotropik) hareketle güneşi takip eder; olgunlaştıkça doğu yönünde sabitlenir. Bu doğal davranıştır.'],
        confidence: 'high',
        evidence: ev,
      ),
      rule(
        id: 'rule.sunflower.flower.helicoverpa_threshold',
        category: RuleCategories.pestRisk,
        priority: 70,
        risk: 'medium',
        when: [c, stage, eq(FactKeys.pestPopulationLevel, 'above_threshold'), eq(FactKeys.observedPest, 'helicoverpa')],
        recs: [
          'Helicoverpa eşiğin üstünde — başa zarar veriyor. BKÜ kontrolü ile arıya en az zararlı etken madde seçin; akşam uygulayın.'
        ],
        confidence: 'medium',
        evidence: pendingEvidence(SourceIds.sunflowerIpm),
        bku: true,
        expert: true,
      ),
      rule(
        id: 'rule.sunflower.flower.head_rot_alert',
        category: RuleCategories.diseaseRisk,
        priority: 85,
        risk: 'high',
        when: [c, stage, eq(FactKeys.observedSymptom, 'head_rot')],
        recs: ['Baş çürüklüğü gözlemi — Sclerotinia veya Rhizopus olabilir. Uzman onayı; hastalıklı başları tarladan uzaklaştırın.'],
        confidence: 'medium',
        evidence: pendingEvidence(SourceIds.sunflowerIpm),
        expert: true,
      ),
      rule(
        id: 'rule.sunflower.flower.downy_mildew',
        category: RuleCategories.diseaseRisk,
        priority: 70,
        when: [c, stage, eq(FactKeys.observedSymptom, 'downy_mildew')],
        recs: [
          'Mildiyö belirtisi — yaprak alt yüzünde beyaz örtü. Sistemik koruma için BKÜ kontrolüyle etken madde, uzman onayı.'
        ],
        confidence: 'medium',
        evidence: pendingEvidence(SourceIds.sunflowerIpm),
        bku: true,
        expert: true,
      ),
      rule(
        id: 'rule.sunflower.flower.wind_pollination_aid',
        category: cat,
        priority: 25,
        when: [c, stage, lt(FactKeys.windSpeedMs, 1)],
        recs: ['Çok durgun hava — ayçiçeği büyük ölçüde böcek tozlaşmasıyla döllenir; arı varlığı verimi artırır.'],
        confidence: 'low',
        evidence: ev,
      ),
      rule(
        id: 'rule.sunflower.flower.water_excess_drowning',
        category: RuleCategories.weatherWarning,
        priority: 65,
        risk: 'medium',
        when: [c, stage, gt(FactKeys.forecastRain48hMm, 50)],
        recs: ['48 saatte 50+ mm yağış — kök bölgesinde su göllenmesi ve baş çürüklüğü riski. Drenajı kontrol edin.'],
        confidence: 'medium',
        evidence: ev,
      ),
      rule(
        id: 'rule.sunflower.flower.hot_wind_drying',
        category: RuleCategories.weatherWarning,
        priority: 70,
        risk: 'medium',
        when: [c, stage, gt(FactKeys.tempMax24hC, 38), lt(FactKeys.humidityPct, 30)],
        recs: ['Sıcak + kuru rüzgar — polen kuruması ve baş yanığı riski. Mümkünse akşam sulaması ile mikroklima yumuşatın.'],
        confidence: 'low',
        evidence: ev,
      ),
      rule(
        id: 'rule.sunflower.flower.lodging_after_storm',
        category: RuleCategories.weatherWarning,
        priority: 60,
        when: [c, stage, gt(FactKeys.windSpeedMs, 15)],
        recs: ['Şiddetli rüzgar sonrası bitki yatışı olabilir — tarlayı dolaşarak yatık başları işaretleyin.'],
        confidence: 'low',
        evidence: ev,
      ),
      rule(
        id: 'rule.sunflower.flower.late_n_blocked',
        category: RuleCategories.fertilization,
        priority: 55,
        when: [c, stage],
        recs: ['Çiçeklenmede N gübresi vermeyin — yağ oranını düşürür, vejetatif uzar.'],
        confidence: 'medium',
        evidence: ev,
      ),
      rule(
        id: 'rule.sunflower.flower.diseased_inspect_general',
        category: RuleCategories.diseaseRisk,
        priority: 60,
        when: [c, stage, eq(FactKeys.plantHealthSummary, 'mixed')],
        recs: ['Karışık sağlık durumu — hastalıklı/sağlıklı bölge haritalandırın; lokal müdahale daha ekonomik.'],
        confidence: 'low',
        evidence: pendingEvidence(SourceIds.sunflowerIpm),
      ),
      rule(
        id: 'rule.sunflower.flower.no_chemical_during_bloom_general',
        category: RuleCategories.safetyWarning,
        priority: 80,
        when: [c, stage, gt(FactKeys.lastSprayedDaysAgo, -1)],
        recs: [
          'Çiçeklenmede genel ilaçlama kuralı: kesin gereklilik varsa, akşam saatlerinde, arıya en az zararlı sınıfta, BKÜ etiketindeki çiçeklenme uyarısı okunmuş şekilde uygulayın.'
        ],
        confidence: 'high',
        evidence: pendingEvidence(SourceIds.bkuRegistry),
        bku: true,
      ),
      rule(
        id: 'rule.sunflower.flower.water_excess_disease_combo',
        category: RuleCategories.diseaseRisk,
        priority: 75,
        risk: 'high',
        when: [c, stage, eq(FactKeys.humidityLevel, 'high'), gt(FactKeys.weeklyWaterRatio, 1.3)],
        recs: ['Yüksek nem + aşırı sulama + çiçeklenme — mantari hastalık kompleks riski. Sulamayı azaltın, drenaj iyileştirin.'],
        confidence: 'medium',
        evidence: pendingEvidence(SourceIds.sunflowerIpm),
      ),
      rule(
        id: 'rule.sunflower.flower.short_window_advice',
        category: cat,
        priority: 30,
        when: [c, stage],
        recs: ['Tek bir tarlanın çiçeklenmesi 1-2 hafta sürer — gözlem sıklığını bu evrede en yükseğe çıkarın.'],
        confidence: 'medium',
        evidence: ev,
      ),
      rule(
        id: 'rule.sunflower.flower.iron_late_yellowing',
        category: RuleCategories.fertilization,
        priority: 50,
        when: [c, stage, gt(FactKeys.soilPh, 8.0), eq(FactKeys.observedSymptom, 'leaf_spot')],
        recs: ['Alkali toprakta yaprak sararması + çiçeklenme — demir kloroz olası. Şelatlı demir yaprak gübresi düşünün.'],
        confidence: 'low',
        evidence: ev,
      ),
    ];
  }

  // ════════════════════════════════════════════════════════════════════
  // 9) GRAIN FILLING — Dane dolumu (R6-R8)
  // ════════════════════════════════════════════════════════════════════
  static List<Rule> _grainFilling() {
    const cat = RuleCategories.taskGeneration;
    final ev = pendingEvidence(SourceIds.sunflowerAgronomy);
    final c = eq(_cropFact, _cropId);
    final stage = eq(FactKeys.growthStage, 'grain_filling');
    return [
      rule(
        id: 'rule.sunflower.fill.water_critical',
        category: RuleCategories.irrigation,
        priority: 80,
        risk: 'high',
        when: [c, stage, lt(FactKeys.weeklyWaterRatio, 0.75)],
        recs: ['Dane dolumunda su açığı — yağ oranı ve dane ağırlığı düşer. Sulamayı tamamlayın.'],
        confidence: 'medium',
        evidence: ev,
      ),
      rule(
        id: 'rule.sunflower.fill.late_pest_alternaria',
        category: RuleCategories.diseaseRisk,
        priority: 65,
        when: [c, stage, eq(FactKeys.observedSymptom, 'leaf_spot'), eq(FactKeys.humidityLevel, 'high')],
        recs: [
          'Yaprak leke + yüksek nem + dane dolumu — Alternaria yaprak yanıklığı. BKÜ kontrolüyle koruyucu fungisit ve uzman onayı.'
        ],
        confidence: 'medium',
        evidence: pendingEvidence(SourceIds.sunflowerIpm),
        bku: true,
        expert: true,
      ),
      rule(
        id: 'rule.sunflower.fill.bird_damage_high',
        category: RuleCategories.pestRisk,
        priority: 70,
        when: [c, stage],
        recs: ['Dane dolumu = kuş zararı zirvesi. Net, görsel/ses caydırıcı veya etrafa ekilen yem alanı düşünün.'],
        confidence: 'low',
        evidence: pendingEvidence(SourceIds.sunflowerIpm),
      ),
      rule(
        id: 'rule.sunflower.fill.no_irrigation_after_physical_mat',
        category: RuleCategories.irrigation,
        priority: 50,
        when: [c, stage, gte(FactKeys.daysAfterPlanting, 100)],
        recs: ['Fiziksel olgunlaşma yaklaşırken sulamayı kademeli azaltın — hasat öncesi kurutmayı kolaylaştırır.'],
        confidence: 'low',
        evidence: ev,
      ),
      rule(
        id: 'rule.sunflower.fill.head_droop_normal',
        category: RuleCategories.cropUnique,
        priority: 30,
        when: [c, stage],
        recs: ['Başın doğuya bakıp aşağı eğilmesi normaldir — fototropizm sona erer, dane ağırlığıyla baş döner.'],
        confidence: 'high',
        evidence: ev,
      ),
      rule(
        id: 'rule.sunflower.fill.lodging_after_rain',
        category: RuleCategories.weatherWarning,
        priority: 70,
        risk: 'medium',
        when: [c, stage, gt(FactKeys.forecastRain48hMm, 30), gt(FactKeys.windSpeedMs, 10)],
        recs: ['Yağış + rüzgar + dolu baş = yatış riski yüksek. Tarlayı yakın izleyin, yatık alanlarda erken hasat planlayın.'],
        confidence: 'medium',
        evidence: ev,
      ),
      rule(
        id: 'rule.sunflower.fill.phomopsis_stem',
        category: RuleCategories.diseaseRisk,
        priority: 65,
        when: [c, stage, eq(FactKeys.observedSymptom, 'stem_rot')],
        recs: ['Sap çürüklüğü gözlemi — Phomopsis veya kömür çürüklüğü olabilir. Tanı için uzman; etkilenmiş bitki sayısı haritalayın.'],
        confidence: 'low',
        evidence: pendingEvidence(SourceIds.sunflowerIpm),
        expert: true,
      ),
      rule(
        id: 'rule.sunflower.fill.charcoal_rot_hot_dry',
        category: RuleCategories.diseaseRisk,
        priority: 70,
        risk: 'medium',
        when: [c, stage, gt(FactKeys.tempMax24hC, 35), lt(FactKeys.soilMoisture, 0.18)],
        recs: ['Sıcak + kuru toprak + dane dolumu — kömür çürüklüğü (Macrophomina) riski artar. Sulama varsa devam, yoksa bitki sağlığı yakın izlensin.'],
        confidence: 'medium',
        evidence: pendingEvidence(SourceIds.sunflowerIpm),
      ),
      rule(
        id: 'rule.sunflower.fill.boron_seed_set',
        category: RuleCategories.fertilization,
        priority: 45,
        when: [c, stage, eq(FactKeys.observedSymptom, 'wilt')],
        recs: ['Baş içinde dane oluşmamış bölgeler bor eksikliğinin işareti olabilir — toprak analizi planlayın.'],
        confidence: 'low',
        evidence: ev,
      ),
      rule(
        id: 'rule.sunflower.fill.scout_phoma',
        category: RuleCategories.diseaseRisk,
        priority: 50,
        when: [c, stage, eq(FactKeys.humidityLevel, 'high')],
        recs: ['Phoma sap kararması için sap dibi kontrol edin — yüksek nemde yayılır.'],
        confidence: 'low',
        evidence: pendingEvidence(SourceIds.sunflowerIpm),
      ),
      rule(
        id: 'rule.sunflower.fill.head_size_low',
        category: cat,
        priority: 40,
        when: [c, stage, eq(FactKeys.observedSymptom, 'wilt')],
        recs: ['Başların küçük kalması — su, bor veya tozlaşma sorunlarının sonradan göstergesi. Sonraki sezon için not edin.'],
        confidence: 'low',
        evidence: ev,
      ),
      rule(
        id: 'rule.sunflower.fill.early_maturity_signal',
        category: cat,
        priority: 40,
        when: [c, stage, gte(FactKeys.daysAfterPlanting, 95)],
        recs: ['Olgunlaşma yaklaşıyor — baş arka rengini izlemeye başlayın; sarıdan kahverengiye dönüş hasat sinyalidir.'],
        confidence: 'medium',
        evidence: ev,
      ),
      rule(
        id: 'rule.sunflower.fill.no_insecticide_phi',
        category: RuleCategories.safetyWarning,
        priority: 65,
        when: [c, stage],
        recs: ['Hasada bekleme süreleri (PHI) kritik — BKÜ etiketindeki PHI tamamlanmadan hasat yapılmaz.'],
        confidence: 'high',
        evidence: pendingEvidence(SourceIds.bkuRegistry),
        bku: true,
      ),
      rule(
        id: 'rule.sunflower.fill.water_excess_oil_dilution',
        category: RuleCategories.irrigation,
        priority: 50,
        when: [c, stage, gt(FactKeys.weeklyWaterRatio, 1.4)],
        recs: ['Aşırı sulama dane dolumunda yağ oranını seyrekleştirebilir — son sulamayı kontrollü yapın.'],
        confidence: 'low',
        evidence: ev,
      ),
      rule(
        id: 'rule.sunflower.fill.scouting_freq_high',
        category: cat,
        priority: 35,
        when: [c, stage],
        recs: ['Dane dolumunda scouting sıklığı haftada en az 2 kez — hastalık ve kuş zararı hızlı gelişir.'],
        confidence: 'medium',
        evidence: ev,
      ),
    ];
  }

  // ════════════════════════════════════════════════════════════════════
  // 10) HARVEST — Hasat (R9)
  // ════════════════════════════════════════════════════════════════════
  static List<Rule> _harvest() {
    const cat = RuleCategories.harvest;
    final ev = pendingEvidence(SourceIds.sunflowerAgronomy);
    final c = eq(_cropFact, _cropId);
    final stage = isIn(FactKeys.growthStage, ['maturity', 'harvest']);
    return [
      rule(
        id: 'rule.sunflower.harvest.moisture_window',
        category: cat,
        priority: 65,
        when: [c, stage],
        recs: ['İdeal hasat nemi %9-11. Daha yüksek nemde kurutma gerekir, daha düşükte dane kaybı (silkme) artar.'],
        confidence: 'medium',
        evidence: ev,
      ),
      rule(
        id: 'rule.sunflower.harvest.rain_before_harvest',
        category: cat,
        priority: 70,
        risk: 'medium',
        when: [c, stage, gt(FactKeys.forecastRain24hMm, 10)],
        recs: ['Hasat öncesi yağış bekleniyor — biçerdöver kayıpları ve baş çürüklüğü riski. Hasadı yağmurdan önceye alın.'],
        confidence: 'medium',
        evidence: ev,
      ),
      rule(
        id: 'rule.sunflower.harvest.combine_speed',
        category: cat,
        priority: 40,
        when: [c, stage],
        recs: ['Biçerdöver hızı 5-6 km/s, tabla uçları çürük başları taramayacak şekilde ayarlanmalı.'],
        confidence: 'low',
        evidence: ev,
      ),
      rule(
        id: 'rule.sunflower.harvest.head_back_color',
        category: cat,
        priority: 50,
        when: [c, stage],
        recs: ['Baş sırtının %75-85 kahverengi olması hasat zamanı sinyalidir.'],
        confidence: 'medium',
        evidence: ev,
      ),
      rule(
        id: 'rule.sunflower.harvest.delay_lodging',
        category: cat,
        priority: 60,
        when: [c, stage, gte(FactKeys.daysAfterPlanting, 130)],
        recs: ['Hasat gecikmesi yatış ve dane kaybı riskini artırır — uygun ilk pencerede başlayın.'],
        confidence: 'medium',
        evidence: ev,
      ),
      rule(
        id: 'rule.sunflower.harvest.bird_late_damage',
        category: cat,
        priority: 55,
        when: [c, stage],
        recs: ['Geç hasatta kuş zararı artar — hasada öncelik verin.'],
        confidence: 'low',
        evidence: ev,
      ),
      rule(
        id: 'rule.sunflower.harvest.storage_moisture',
        category: cat,
        priority: 60,
        when: [c, stage],
        recs: ['Depolama için dane nemi %9 altında olmalı — yüksek nem küflenme yapar.'],
        confidence: 'medium',
        evidence: ev,
      ),
      rule(
        id: 'rule.sunflower.harvest.windrowing_for_uneven',
        category: cat,
        priority: 40,
        when: [c, stage],
        recs: ['Eşit olgunlaşmayan tarlalarda biçim sonrası kurutma (windrow) düşünülebilir.'],
        confidence: 'low',
        evidence: ev,
      ),
      rule(
        id: 'rule.sunflower.harvest.sample_test_pre_combine',
        category: cat,
        priority: 35,
        when: [c, stage],
        recs: ['Hasattan önce 5-10 baştan örnek alıp nemli kontrol edin — biçerdöver kalibrasyonu için.'],
        confidence: 'low',
        evidence: ev,
      ),
      rule(
        id: 'rule.sunflower.harvest.no_phi_violation',
        category: RuleCategories.safetyWarning,
        priority: 80,
        risk: 'high',
        when: [c, stage, lt(FactKeys.lastSprayedDaysAgo, 21)],
        recs: ['Son ilaçlamadan 21 günden az süre geçti — PHI tamamlanmamış olabilir. BKÜ etiketindeki süreyi kontrol etmeden hasat yapmayın.'],
        confidence: 'high',
        evidence: pendingEvidence(SourceIds.bkuRegistry),
        bku: true,
      ),
    ];
  }

  // ════════════════════════════════════════════════════════════════════
  // 11) DISEASE — Hastalık (her hastalık × evre × ortam)
  // ════════════════════════════════════════════════════════════════════
  static List<Rule> _disease() {
    const cat = RuleCategories.diseaseRisk;
    final ev = pendingEvidence(SourceIds.sunflowerIpm);
    final c = eq(_cropFact, _cropId);

    Rule mk(String diseaseKey, String? stage, String? symptom, String? humidity, int prio, String? risk, String advice) {
      final conds = <RuleCondition>[c];
      if (stage != null) conds.add(eq(FactKeys.growthStage, stage));
      if (symptom != null) conds.add(eq(FactKeys.observedSymptom, symptom));
      if (humidity != null) conds.add(eq(FactKeys.humidityLevel, humidity));
      return rule(
        id: 'rule.sunflower.dis.${diseaseKey}_${stage ?? 'any'}_${humidity ?? 'any'}',
        category: cat,
        priority: prio,
        risk: risk,
        when: conds,
        recs: [advice],
        confidence: 'low',
        evidence: ev,
        expert: true,
        bku: true,
        problemId: 'disease.sunflower.$diseaseKey',
      );
    }

    return [
      // Sclerotinia — kök/sap/baş çürüklüğü
      mk('sclerotinia', 'pre_flowering', 'stem_rot', 'high', 80, 'high',
          'Sclerotinia sap çürüklüğü riski (yüksek nem + çiçeklenme öncesi). Hastalıklı bitkileri uzaklaştırın; BKÜ kontrolü + uzman onayıyla koruyucu fungisit.'),
      mk('sclerotinia', 'flowering', 'head_rot', 'high', 85, 'high',
          'Sclerotinia baş çürüklüğü — çiçek bazından başlayan beyaz misel. Etkilenmiş başları tarladan uzaklaştırın; rotasyon zorunlu.'),
      mk('sclerotinia', 'grain_filling', 'stem_rot', 'medium', 70, 'medium',
          'Dane dolumunda sap çürüklüğü — Sclerotinia kalıntısı toprakta kalır; 4 yıllık rotasyon planlayın.'),
      mk('sclerotinia', 'maturity', 'head_rot', null, 65, 'medium',
          'Olgunlukta baş çürüklüğü — etkilenmiş başlar hasat öncesi temizlenmeli.'),

      // Mildiyö (Plasmopara halstedii)
      mk('downy_mildew', 'seedling', 'downy_mildew', 'high', 80, 'high',
          'Fide mildiyösü — sistemik hastalık, bitki çıkışsız kalır; etkilenen bitkiler tarladan çıkarılır.'),
      mk('downy_mildew', 'vegetative', 'downy_mildew', 'high', 75, 'medium',
          'Vejetatif mildiyö — yaprak alt yüzünde beyaz örtü, üst yüzde sararma. Dirençli çeşit seçimi en etkili.'),
      mk('downy_mildew', 'pre_flowering', 'downy_mildew', 'high', 70, 'medium',
          'Mildiyö + çiçeklenme öncesi — kalıcı toprak sporları riski; rotasyon zorunlu.'),
      mk('downy_mildew', 'flowering', 'downy_mildew', null, 65, 'medium',
          'Çiçeklenmede mildiyö belirtisi — uzman tanı + BKÜ kontrolü.'),

      // Alternaria yaprak yanıklığı
      mk('alternaria', 'vegetative', 'leaf_spot', 'high', 60, 'medium',
          'Alternaria yaprak lekesi — yuvarlak/kahverengi lekeler; nemli koşulda hızla yayılır.'),
      mk('alternaria', 'pre_flowering', 'leaf_spot', 'high', 65, 'medium',
          'Pre-flowering Alternaria — BKÜ kontrolüyle koruyucu fungisit düşünün.'),
      mk('alternaria', 'flowering', 'leaf_spot', null, 65, 'medium',
          'Çiçeklenmede Alternaria — yaprak alanı kaybı verim düşürür.'),
      mk('alternaria', 'grain_filling', 'leaf_spot', 'high', 70, 'medium',
          'Dane dolumunda Alternaria — yağ oranını düşürür.'),

      // Phomopsis sap kararması
      mk('phomopsis', 'pre_flowering', 'stem_rot', 'high', 65, 'medium',
          'Phomopsis sap kararması — sap dibinde kahverengi lezyonlar; yüksek nemde gelişir.'),
      mk('phomopsis', 'flowering', 'stem_rot', 'high', 70, 'medium',
          'Çiçeklenmede Phomopsis — yatış riski artar.'),
      mk('phomopsis', 'grain_filling', 'stem_rot', null, 65, 'medium',
          'Geç Phomopsis — sap kırılması; hasada öncelik.'),
      mk('phomopsis', 'maturity', 'stem_rot', null, 60, 'medium',
          'Olgunlukta Phomopsis sapları — yatış öncesi hasat planı.'),

      // Phoma siyah leke
      mk('phoma', 'vegetative', 'leaf_spot', 'high', 55, null,
          'Phoma siyah leke — yaprak sap bağlantısında siyah çürük lekeler.'),
      mk('phoma', 'pre_flowering', 'stem_rot', 'high', 60, 'medium',
          'Pre-flowering Phoma — sap dibinde siyahlaşma.'),
      mk('phoma', 'flowering', 'stem_rot', 'high', 65, 'medium',
          'Çiçeklenmede Phoma — diğer sap hastalıklarıyla karışabilir; uzman tanı.'),
      mk('phoma', 'grain_filling', 'stem_rot', null, 60, 'medium',
          'Dane dolumunda Phoma — geç dönem sap çürüklüğü.'),

      // Kömür çürüklüğü (Macrophomina)
      mk('charcoal_rot', 'pre_flowering', 'wilt', 'low', 65, 'medium',
          'Kömür çürüklüğü erken belirtisi — kuru/sıcakta solgun bitkiler; sap kesilince siyah noktalar.'),
      mk('charcoal_rot', 'flowering', 'wilt', 'low', 70, 'medium',
          'Çiçeklenmede kömür çürüklüğü — sıcak kuru periyot tetikler.'),
      mk('charcoal_rot', 'grain_filling', 'wilt', 'low', 75, 'high',
          'Dane dolumunda kömür çürüklüğü — yağ oranı ve dane ağırlığı ciddi düşer.'),
      mk('charcoal_rot', 'maturity', 'stem_rot', null, 60, 'medium',
          'Olgunlukta kömür çürüklüğü — yatış riski; erken hasat.'),

      // Pas (Puccinia helianthi)
      mk('rust', 'vegetative', 'rust', 'high', 55, null,
          'Pas erken belirtisi — yaprak altında turuncu püstüller.'),
      mk('rust', 'pre_flowering', 'rust', 'high', 65, 'medium',
          'Pre-flowering pas — hızla yayılır; dirençli çeşit en etkili çözüm.'),
      mk('rust', 'flowering', 'rust', null, 70, 'medium',
          'Çiçeklenmede pas — yaprak alanı kaybı verimi düşürür.'),
      mk('rust', 'grain_filling', 'rust', 'high', 65, 'medium',
          'Dane dolumunda pas — yağ oranı düşer.'),

      // Septoria yaprak lekesi
      mk('septoria', 'vegetative', 'leaf_spot', 'high', 50, null,
          'Septoria yaprak lekesi — küçük yuvarlak lekeler, alt yapraklardan başlar.'),
      mk('septoria', 'pre_flowering', 'leaf_spot', 'high', 55, null,
          'Pre-flowering Septoria — alt yaprak ölümü; yine alttan başlar.'),
      mk('septoria', 'flowering', 'leaf_spot', null, 60, 'medium',
          'Çiçeklenmede Septoria — yaprak fotosenteze etkisi.'),
      mk('septoria', 'grain_filling', 'leaf_spot', 'high', 60, 'medium',
          'Dane dolumunda Septoria — yaprak yanıklığı.'),

      // Verticillium solgunluğu
      mk('verticillium', 'vegetative', 'wilt', null, 60, 'medium',
          'Verticillium solgunluğu — yaprak damar arası sararma, sap kesilince koyu damar.'),
      mk('verticillium', 'pre_flowering', 'wilt', null, 65, 'medium',
          'Pre-flowering Verticillium — kalıcı toprak hastalığı; rotasyon zorunlu.'),
      mk('verticillium', 'flowering', 'wilt', null, 70, 'medium',
          'Çiçeklenmede Verticillium — kısmi solgunluk, dirençli çeşit.'),

      // Bakteriyel hastalıklar
      mk('bacterial_stalk_rot', 'flowering', 'stem_rot', 'high', 60, 'medium',
          'Bakteriyel sap çürüklüğü — yüksek nem + sıcaklık; pis koku yaygın.'),
      mk('bacterial_stalk_rot', 'grain_filling', 'stem_rot', 'high', 60, 'medium',
          'Geç bakteriyel sap çürüklüğü — drenaj ve havalandırma kritik.'),

      // Nematod
      mk('root_knot_nematode', 'vegetative', 'wilt', null, 50, null,
          'Kök ur nematodu — sebep belirsiz solgunluk; toprak örneklemesi gerekir.'),
      mk('root_knot_nematode', 'pre_flowering', 'wilt', null, 55, null,
          'Pre-flowering kök ur nematodu şüphesi — sap kesim üst dilimi izleyin.'),
    ];
  }

  // ════════════════════════════════════════════════════════════════════
  // 12) PEST — Zararlı
  // ════════════════════════════════════════════════════════════════════
  static List<Rule> _pest() {
    const cat = RuleCategories.pestRisk;
    final ev = pendingEvidence(SourceIds.sunflowerIpm);
    final c = eq(_cropFact, _cropId);

    Rule mk(String pestKey, String? stage, String level, int prio, String? risk, String advice, {bool bku = false}) {
      final conds = <RuleCondition>[c, eq(FactKeys.observedPest, pestKey)];
      if (stage != null) conds.add(eq(FactKeys.growthStage, stage));
      conds.add(eq(FactKeys.pestPopulationLevel, level));
      return rule(
        id: 'rule.sunflower.pest.${pestKey}_${stage ?? 'any'}_$level',
        category: cat,
        priority: prio,
        risk: risk,
        when: conds,
        recs: [advice],
        confidence: 'low',
        evidence: ev,
        expert: true,
        bku: bku,
        problemId: 'pest.sunflower.$pestKey',
      );
    }

    return [
      // Helicoverpa (yeşil kurt)
      mk('helicoverpa', 'pre_flowering', 'below_threshold', 40, null,
          'Helicoverpa gözlemi var ama eşik altı — gözlem sürdürün, mücadele gerekmez.'),
      mk('helicoverpa', 'pre_flowering', 'at_threshold', 60, 'medium',
          'Helicoverpa eşikte — Bacillus thuringiensis veya BKÜ etiketli etken madde, akşam uygulaması; arı dostu seçim.', bku: true),
      mk('helicoverpa', 'pre_flowering', 'above_threshold', 75, 'high',
          'Helicoverpa eşik üstü — acil müdahale; BKÜ kontrolüyle etken madde, akşam uygulama, arı bilgilendirmesi.', bku: true),
      mk('helicoverpa', 'flowering', 'at_threshold', 65, 'medium',
          'Çiçeklenmede Helicoverpa eşikte — kimyasal son çare; biyolojik (Bt) önerilir.', bku: true),
      mk('helicoverpa', 'flowering', 'above_threshold', 80, 'high',
          'Çiçeklenmede Helicoverpa kritik — arıya en az zararlı sınıf, akşam, BKÜ etiketi.', bku: true),
      mk('helicoverpa', 'grain_filling', 'above_threshold', 75, 'high',
          'Dane dolumunda Helicoverpa — baş zararı ekonomik; PHI dikkat.', bku: true),

      // Sap delici
      mk('stem_borer', 'vegetative', 'below_threshold', 35, null,
          'Sap delici gözlemi eşik altı — feromon tuzak ile popülasyon izleme.'),
      mk('stem_borer', 'vegetative', 'at_threshold', 55, 'medium',
          'Sap delici eşikte — kültürel (bitki artığı temizliği) + biyolojik seçeneklere öncelik.', bku: true),
      mk('stem_borer', 'flowering', 'above_threshold', 70, 'high',
          'Çiçeklenmede sap delici eşik üstü — yatış ve baş ağırlığı kaybı.', bku: true),
      mk('stem_borer', 'grain_filling', 'above_threshold', 70, 'high',
          'Dane dolumunda sap delici — sap kırılma riski; erken hasat alternatifi.', bku: true),

      // Kömür akrebi (Spodoptera)
      mk('spodoptera', 'seedling', 'above_threshold', 70, 'medium',
          'Fide döneminde Spodoptera — fide kayıpları; gece aktif, BKÜ kontrolü.', bku: true),
      mk('spodoptera', 'vegetative', 'above_threshold', 65, 'medium',
          'Vejetatif Spodoptera — yaprak alanı kaybı; eşiğe dikkat.', bku: true),

      // Çayır tırtılı
      mk('meadow_moth', 'vegetative', 'above_threshold', 65, 'medium',
          'Çayır tırtılı eşik üstü — yaprak ve büyüme noktası zararı; BKÜ kontrolü.', bku: true),
      mk('meadow_moth', 'pre_flowering', 'at_threshold', 55, 'medium',
          'Pre-flowering çayır tırtılı eşikte — biyolojik seçenekler.', bku: true),

      // Yaprak biti (afidler)
      mk('aphid', 'vegetative', 'below_threshold', 30, null,
          'Yaprak biti var ama eşik altı — doğal düşmanlar (uğur böceği) varsa mücadeleye gerek yok.'),
      mk('aphid', 'vegetative', 'at_threshold', 50, null,
          'Yaprak biti eşikte — sabun bazlı veya yağ püskürtme (biyolojik); kimyasal son çare.', bku: true),
      mk('aphid', 'pre_flowering', 'above_threshold', 65, 'medium',
          'Pre-flowering yüksek afid — vektör virüs riski; BKÜ kontrolü, arı bilgilendir.', bku: true),

      // Kuş zararı
      mk('bird', 'flowering', 'at_threshold', 45, null,
          'Çiçeklenmede kuş zararı — caydırıcı ses/görsel sistem; vurma yasaktır.'),
      mk('bird', 'grain_filling', 'above_threshold', 65, 'medium',
          'Dane dolumunda kuş zararı yüksek — net, ses tabancası, koruma alanları.'),
      mk('bird', 'maturity', 'above_threshold', 70, 'high',
          'Olgunlukta kuş zararı — hasada öncelik; tarla küçük ise ağ.'),

      // Fare/küçük memeli
      mk('field_mouse', 'maturity', 'above_threshold', 50, null,
          'Tarla faresi olgunlukta — yere düşmüş dane azaltılmalı.'),
      mk('field_mouse', 'grain_filling', 'at_threshold', 45, null,
          'Tarla faresi gözlemi — depo ve sınır temizliği.'),

      // Tel kurdu (Agriotes)
      mk('wireworm', 'germination', 'above_threshold', 70, 'medium',
          'Tel kurdu fide kayıpları — kontrol tohum ilaçlama veya alternatif tarla; BKÜ kontrolü.', bku: true),
      mk('wireworm', 'emergence', 'at_threshold', 55, 'medium',
          'Tel kurdu eşikte + çıkış evresi — fide kıyımı; uzman görüş.', bku: true),

      // Salyangoz (Heliciculture)
      mk('snail', 'seedling', 'above_threshold', 50, null,
          'Salyangoz fide yiyor — fiziksel tuzak, BKÜ kontrolü.', bku: true),

      // Tripsler
      mk('thrips', 'flowering', 'above_threshold', 55, 'medium',
          'Tripsler çiçeklenmede — virüs vektörü olabilir; BKÜ kontrolü.', bku: true),
    ];
  }

  // ════════════════════════════════════════════════════════════════════
  // 13) WEED — Yabancı ot (özellikle orobanş)
  // ════════════════════════════════════════════════════════════════════
  static List<Rule> _weed() {
    const cat = RuleCategories.weedManagement;
    final ev = pendingEvidence(SourceIds.sunflowerOrobanche);
    final c = eq(_cropFact, _cropId);
    return [
      // Orobanş (canavar otu) — ayçiçeği için en kritik parazit
      rule(
        id: 'rule.sunflower.weed.orobanche_history',
        category: cat,
        priority: 90,
        risk: 'high',
        when: [c, eq(FactKeys.observedWeed, 'orobanche')],
        recs: [
          'Canavar otu (orobanş) — ayçiçeğine en zararlı parazit yabancı ot. Bu tarlada orobanş varsa en az 4-5 yıl ayçiçeği ekmeyin, dayanıklı çeşit (IMI veya orobanş-dayanıklı) seçin.',
          'Çıkış sonrası orobanş çiçeklenmeden mücadele edilmeli; tarlada çiçeklenmiş bitkileri tohum bırakmadan uzaklaştırın.'
        ],
        confidence: 'high',
        evidence: ev,
        expert: true,
        problemId: 'weed.sunflower.orobanche',
      ),
      rule(
        id: 'rule.sunflower.weed.orobanche_rotation',
        category: cat,
        priority: 75,
        when: [c, eq(FactKeys.observedWeed, 'orobanche'), gte(FactKeys.lastTillageDaysAgo, 365)],
        recs: ['Orobanş bulaşık tarlada rotasyon: buğday, arpa, mısır, baklagil — orobanş ayçiçeği dışında çoğu ürüne girmez.'],
        confidence: 'medium',
        evidence: ev,
      ),
      rule(
        id: 'rule.sunflower.weed.orobanche_resistant_cultivar',
        category: cat,
        priority: 80,
        when: [c, eq(FactKeys.observedWeed, 'orobanche'), isIn(FactKeys.growthStage, ['germination'])],
        recs: ['Orobanş riski yüksek bölgede dayanıklı çeşit (IMI hattı + imidazolinone uyumlu) seçimi ile entegre mücadele.'],
        confidence: 'medium',
        evidence: ev,
        bku: true,
      ),
      // Diğer yabancı otlar
      rule(
        id: 'rule.sunflower.weed.amaranthus',
        category: cat,
        priority: 55,
        when: [c, eq(FactKeys.observedWeed, 'amaranthus')],
        recs: ['Horoz ibiği (Amaranthus) — ayçiçeğine kuvvetli rakip; çıkış sonrası dar yapraklı/geniş yapraklı seçici herbisitler için BKÜ kontrolü.'],
        confidence: 'low',
        evidence: pendingEvidence(SourceIds.sunflowerIpm),
        bku: true,
      ),
      rule(
        id: 'rule.sunflower.weed.chenopodium',
        category: cat,
        priority: 50,
        when: [c, eq(FactKeys.observedWeed, 'chenopodium')],
        recs: ['Sirken (Chenopodium) — erken kapuz öncesinde mücadele kritik.'],
        confidence: 'low',
        evidence: pendingEvidence(SourceIds.sunflowerIpm),
        bku: true,
      ),
      rule(
        id: 'rule.sunflower.weed.sorghum_halepense',
        category: cat,
        priority: 60,
        when: [c, eq(FactKeys.observedWeed, 'sorghum_halepense')],
        recs: ['Kanyaş (Sorghum halepense) — köklü çok yıllık, mekanik+kimyasal entegre; BKÜ kontrolü.'],
        confidence: 'low',
        evidence: pendingEvidence(SourceIds.sunflowerIpm),
        bku: true,
      ),
      rule(
        id: 'rule.sunflower.weed.xanthium',
        category: cat,
        priority: 55,
        when: [c, eq(FactKeys.observedWeed, 'xanthium')],
        recs: ['Domuz pıtrağı (Xanthium) — ayçiçeği akrabası, mücadele zor; el ile uzaklaştırma + uzman önerisi.'],
        confidence: 'low',
        evidence: pendingEvidence(SourceIds.sunflowerIpm),
        expert: true,
      ),
      rule(
        id: 'rule.sunflower.weed.pre_emergence_window',
        category: cat,
        priority: 65,
        when: [c, isIn(FactKeys.growthStage, ['germination', 'emergence'])],
        recs: ['Çıkış öncesi/erken sonrası yabancı ot mücadele penceresi en kritik dönem — BKÜ kontrolü.'],
        confidence: 'medium',
        evidence: ev,
        bku: true,
      ),
      rule(
        id: 'rule.sunflower.weed.late_window_blocked',
        category: cat,
        priority: 50,
        when: [c, isIn(FactKeys.growthStage, ['flowering', 'grain_filling'])],
        recs: ['Çiçeklenme ve sonrasında herbisit uygulaması büyük risk — bitki + arı zararı; el ile mücadele.'],
        confidence: 'high',
        evidence: ev,
      ),
      rule(
        id: 'rule.sunflower.weed.cultivation_timing',
        category: cat,
        priority: 50,
        when: [c, between(FactKeys.daysAfterPlanting, 20, 40)],
        recs: ['Sıra arası çapalama 20-40. günler arası — bitki örtüsü kapanmadan önce.'],
        confidence: 'low',
        evidence: ev,
      ),
      rule(
        id: 'rule.sunflower.weed.cover_crop_post_harvest',
        category: cat,
        priority: 35,
        when: [c, eq(FactKeys.growthStage, 'harvest')],
        recs: ['Hasat sonrası örtü bitkisi (örn. fiğ) yabancı ot ve erozyonu azaltır.'],
        confidence: 'low',
        evidence: ev,
      ),
      rule(
        id: 'rule.sunflower.weed.early_mapping',
        category: cat,
        priority: 40,
        when: [c, eq(FactKeys.growthStage, 'vegetative')],
        recs: ['Yabancı ot türleri ve yoğunluk haritası çıkarın — lokal müdahale daha ekonomik.'],
        confidence: 'low',
        evidence: ev,
      ),
    ];
  }

  // ════════════════════════════════════════════════════════════════════
  // 14) FERTILIZATION — Gübreleme NPK
  // ════════════════════════════════════════════════════════════════════
  static List<Rule> _fertilization() {
    const cat = RuleCategories.fertilization;
    final ev = pendingEvidence(SourceIds.soilFertilizerGeneral);
    final c = eq(_cropFact, _cropId);
    // CLAUDE.md sec 16 — toprak analizi yoksa kesin doz vermez.
    return [
      rule(
        id: 'rule.sunflower.fert.no_analysis_block',
        category: cat,
        priority: 85,
        risk: 'medium',
        when: [c, missing(FactKeys.soilPh)],
        recs: ['Toprak analizi yok — kesin gübre miktarı önerilemez. Önce pH, EC, organik madde, N-P-K analizi yaptırın.'],
        confidence: 'high',
        evidence: ev,
      ),
      // N (azot) seviyeleri × evre
      rule(
        id: 'rule.sunflower.fert.n_low_pre',
        category: cat,
        priority: 60,
        when: [c, eq(FactKeys.nLevel, 'low'), isIn(FactKeys.growthStage, ['germination', 'emergence'])],
        recs: ['N düşük + erken evre — toprak analiz raporundaki tavsiyeye göre starter N uygulayın (genelde 4-8 kg/dekar saf N).'],
        confidence: 'low',
        evidence: ev,
        expert: true,
      ),
      rule(
        id: 'rule.sunflower.fert.n_low_veg',
        category: cat,
        priority: 65,
        when: [c, eq(FactKeys.nLevel, 'low'), eq(FactKeys.growthStage, 'vegetative')],
        recs: ['Vejetatif evrede N eksikliği — sararma + zayıf büyüme. Üst gübre uygulaması, doz toprak analizine göre.'],
        confidence: 'medium',
        evidence: ev,
        expert: true,
      ),
      rule(
        id: 'rule.sunflower.fert.n_high_warn',
        category: cat,
        priority: 60,
        when: [c, eq(FactKeys.nLevel, 'high')],
        recs: ['Toprak N yüksek — ek N vermeyin; aşırı N yatış ve hastalığı tetikler.'],
        confidence: 'medium',
        evidence: ev,
      ),
      rule(
        id: 'rule.sunflower.fert.n_late_block',
        category: cat,
        priority: 70,
        when: [c, isIn(FactKeys.growthStage, ['flowering', 'grain_filling']), eq(FactKeys.nLevel, 'low')],
        recs: ['Geç dönem N eksikliği — düzeltme şansı düşük; sonraki sezona toprak analizi planlayın.'],
        confidence: 'medium',
        evidence: ev,
      ),
      // P (fosfor)
      rule(
        id: 'rule.sunflower.fert.p_low_pre',
        category: cat,
        priority: 60,
        when: [c, eq(FactKeys.pLevel, 'low'), isIn(FactKeys.growthStage, ['germination', 'pre_planting' as Object])],
        recs: ['P düşük — ekim öncesi/ekimle DAP/TSP gübresi düşünün; doz toprak analizine göre.'],
        confidence: 'medium',
        evidence: ev,
        expert: true,
      ),
      rule(
        id: 'rule.sunflower.fert.p_low_veg',
        category: cat,
        priority: 55,
        when: [c, eq(FactKeys.pLevel, 'low'), eq(FactKeys.growthStage, 'vegetative')],
        recs: ['Vejetatif P eksikliği — köklenme zayıf, mor renklenme; düzeltme zor.'],
        confidence: 'medium',
        evidence: ev,
      ),
      rule(
        id: 'rule.sunflower.fert.p_alkaline_low_avail',
        category: cat,
        priority: 55,
        when: [c, eq(FactKeys.pLevel, 'low'), gt(FactKeys.soilPh, 8.0)],
        recs: ['Alkali toprakta P alımı zaten zor — yaprak gübresi veya banda P uygulama düşünülmelidir.'],
        confidence: 'low',
        evidence: ev,
        expert: true,
      ),
      // K (potasyum)
      rule(
        id: 'rule.sunflower.fert.k_low_pre',
        category: cat,
        priority: 55,
        when: [c, eq(FactKeys.kLevel, 'low'), isIn(FactKeys.growthStage, ['germination'])],
        recs: ['K düşük — ekim öncesi K2SO4 veya KCl düşünün; tuzlu topraklarda K2SO4 tercih edilir.'],
        confidence: 'medium',
        evidence: ev,
        expert: true,
      ),
      rule(
        id: 'rule.sunflower.fert.k_low_grain_filling',
        category: cat,
        priority: 65,
        when: [c, eq(FactKeys.kLevel, 'low'), eq(FactKeys.growthStage, 'grain_filling')],
        recs: ['Dane dolumunda K eksikliği — yağ oranı ve dane ağırlığı düşer. Bu sezon için geç; sonraki sezona not.'],
        confidence: 'medium',
        evidence: ev,
      ),
      // OM (organik madde)
      rule(
        id: 'rule.sunflower.fert.om_supplement',
        category: cat,
        priority: 45,
        when: [c, lt(FactKeys.organicMatterPct, 1.2)],
        recs: ['Organik madde düşük — yanmış ahır gübresi 2-3 ton/dekar veya yeşil gübreleme planlayın.'],
        confidence: 'medium',
        evidence: ev,
      ),
      // Mikro besinler
      rule(
        id: 'rule.sunflower.fert.boron_pre_flower',
        category: cat,
        priority: 50,
        when: [c, isIn(FactKeys.growthStage, ['pre_flowering', 'flowering'])],
        recs: [
          'Çiçeklenme öncesi-sırası bor talebi yüksek. Eksiklik belirtisi (deforme baş, boş çiçek) görülürse uzman önerisiyle yaprak bor.'
        ],
        confidence: 'low',
        evidence: ev,
        expert: true,
      ),
      rule(
        id: 'rule.sunflower.fert.iron_alkaline',
        category: cat,
        priority: 50,
        when: [c, gt(FactKeys.soilPh, 8.0), eq(FactKeys.observedSymptom, 'leaf_spot')],
        recs: ['Alkali toprakta yaprak sararması — şelatlı demir yaprak gübresi (Fe-EDDHA) önerilebilir.'],
        confidence: 'low',
        evidence: ev,
      ),
      rule(
        id: 'rule.sunflower.fert.zinc_check',
        category: cat,
        priority: 45,
        when: [c, gt(FactKeys.soilPh, 8.0)],
        recs: ['Alkali toprakta çinko eksikliği yaygın — yaprak Zn analizi yaptırın.'],
        confidence: 'low',
        evidence: ev,
      ),
      rule(
        id: 'rule.sunflower.fert.fertilizer_safety',
        category: RuleCategories.safetyWarning,
        priority: 50,
        when: [c, exists(FactKeys.nLevel)],
        recs: ['Gübre uygulamasında koruyucu eldiven, gözlük; rüzgarlı havada uygulamadan kaçının.'],
        confidence: 'medium',
        evidence: ev,
      ),
      rule(
        id: 'rule.sunflower.fert.no_burn',
        category: cat,
        priority: 50,
        when: [c, exists(FactKeys.nLevel)],
        recs: ['Üst gübreyi yapraklara temas ettirmeyin — yanma yapar. Tohum/kök bölgesine 5-7 cm uzaklıkta verin.'],
        confidence: 'medium',
        evidence: ev,
      ),
      rule(
        id: 'rule.sunflower.fert.fertigation_check',
        category: cat,
        priority: 40,
        when: [c, eq(FactKeys.waterRegime, 'irrigated')],
        recs: ['Damla sulama varsa fertigasyon planlayın — daha verimli N kullanımı.'],
        confidence: 'low',
        evidence: ev,
      ),
      rule(
        id: 'rule.sunflower.fert.recent_fert_block',
        category: cat,
        priority: 55,
        when: [c, lt(FactKeys.lastFertilizedDaysAgo, 14)],
        recs: ['Son 14 gün içinde gübreleme yapılmış — kısa aralıkla tekrar etmeyin.'],
        confidence: 'medium',
        evidence: ev,
      ),
      rule(
        id: 'rule.sunflower.fert.ec_high_block',
        category: cat,
        priority: 70,
        risk: 'medium',
        when: [c, gt(FactKeys.soilEc, 2.0)],
        recs: ['Toprak tuzluluğu yüksek — gübre tuz yükünü artırır; yıkama sulaması olmadan gübreleme yapmayın.'],
        confidence: 'medium',
        evidence: ev,
      ),
      rule(
        id: 'rule.sunflower.fert.split_n_recommend',
        category: cat,
        priority: 45,
        when: [c, eq(FactKeys.nLevel, 'low'), eq(FactKeys.waterRegime, 'irrigated')],
        recs: ['N\'yi tek seferde değil 2-3 parçada uygulayın — yıkanma kaybını azaltır.'],
        confidence: 'medium',
        evidence: ev,
      ),
      rule(
        id: 'rule.sunflower.fert.foliar_caution',
        category: cat,
        priority: 40,
        when: [c, eq(FactKeys.observedSymptom, 'leaf_spot')],
        recs: ['Yaprak gübresi sıcak/güneşli saatlerde uygulanmaz — yanma yapar; sabah erken/akşam tercih.'],
        confidence: 'medium',
        evidence: ev,
      ),
      rule(
        id: 'rule.sunflower.fert.no_p_irrigation_combo',
        category: cat,
        priority: 40,
        when: [c, eq(FactKeys.pLevel, 'low'), eq(FactKeys.waterRegime, 'irrigated')],
        recs: ['Damla sulamada P çözünürlüğü düşük olduğundan banda uygulama daha verimli.'],
        confidence: 'low',
        evidence: ev,
      ),
      rule(
        id: 'rule.sunflower.fert.sulfur_oilseed',
        category: cat,
        priority: 45,
        when: [c, eq(FactKeys.nLevel, 'medium')],
        recs: ['Ayçiçeği yağlı tohum olarak kükürt talebi yüksektir — sülfat formlu gübre (Amonyum sülfat) düşünün.'],
        confidence: 'low',
        evidence: ev,
      ),
    ];
  }

  // ════════════════════════════════════════════════════════════════════
  // 15) IRRIGATION — Sulama
  // ════════════════════════════════════════════════════════════════════
  static List<Rule> _irrigation() {
    const cat = RuleCategories.irrigation;
    final ev = pendingEvidence(SourceIds.sunflowerAgronomy);
    final c = eq(_cropFact, _cropId);
    return [
      rule(
        id: 'rule.sunflower.irr.rain_skip',
        category: cat,
        priority: 75,
        when: [c, gt(FactKeys.forecastRain24hMm, 8)],
        recs: ['Önümüzdeki 24 saatte 8 mm+ yağış bekleniyor — bugün sulama yapmayın.'],
        confidence: 'high',
        evidence: pendingEvidence(SourceIds.meteorologyMgm),
      ),
      rule(
        id: 'rule.sunflower.irr.deep_root_priority',
        category: cat,
        priority: 50,
        when: [c, isIn(FactKeys.growthStage, ['pre_flowering', 'flowering', 'grain_filling'])],
        recs: ['Ayçiçeği derin köklenir (1.5-2 m). Az ve sık değil, derin ve seyrek sulama yapın.'],
        confidence: 'medium',
        evidence: ev,
      ),
      rule(
        id: 'rule.sunflower.irr.flowering_priority',
        category: cat,
        priority: 80,
        risk: 'high',
        when: [c, eq(FactKeys.growthStage, 'flowering'), lt(FactKeys.weeklyWaterRatio, 0.7)],
        recs: ['Çiçeklenme — su talebi zirvesinde. Sulama açığını acil tamamlayın.'],
        confidence: 'high',
        evidence: ev,
      ),
      rule(
        id: 'rule.sunflower.irr.grain_filling_priority',
        category: cat,
        priority: 75,
        when: [c, eq(FactKeys.growthStage, 'grain_filling'), lt(FactKeys.weeklyWaterRatio, 0.75)],
        recs: ['Dane dolumunda su açığı — yağ oranı ve dane ağırlığı düşer.'],
        confidence: 'high',
        evidence: ev,
      ),
      rule(
        id: 'rule.sunflower.irr.evening_to_morning',
        category: cat,
        priority: 35,
        when: [c, gt(FactKeys.tempMax24hC, 30)],
        recs: ['Sıcak günlerde sulamayı akşam/sabah erken yapın — gündüz buharlaşma yüksek.'],
        confidence: 'medium',
        evidence: ev,
      ),
      rule(
        id: 'rule.sunflower.irr.drip_efficiency',
        category: cat,
        priority: 30,
        when: [c, eq(FactKeys.waterRegime, 'irrigated')],
        recs: ['Damla sulama yağmurlamaya göre %30-50 daha az su tüketir.'],
        confidence: 'medium',
        evidence: ev,
      ),
      rule(
        id: 'rule.sunflower.irr.over_irrigation',
        category: cat,
        priority: 55,
        when: [c, gt(FactKeys.weeklyWaterRatio, 1.4)],
        recs: ['Aşırı sulama — kök bölgesi havalanamaz, mantari hastalık riski artar. Sulamayı azaltın.'],
        confidence: 'medium',
        evidence: ev,
      ),
      rule(
        id: 'rule.sunflower.irr.dry_pre_flower',
        category: cat,
        priority: 65,
        when: [c, eq(FactKeys.growthStage, 'pre_flowering'), lt(FactKeys.weeklyWaterRatio, 0.7)],
        recs: ['Çiçeklenme öncesi su açığı — baş büyüklüğü düşer; sulamayı tamamlayın.'],
        confidence: 'medium',
        evidence: ev,
      ),
      rule(
        id: 'rule.sunflower.irr.maturity_taper',
        category: cat,
        priority: 50,
        when: [c, isIn(FactKeys.growthStage, ['maturity']), gte(FactKeys.weeklyWaterRatio, 0.5)],
        recs: ['Olgunlukta sulamayı kademeli azaltın — hasat öncesi kurutmayı kolaylaştırır.'],
        confidence: 'medium',
        evidence: ev,
      ),
      rule(
        id: 'rule.sunflower.irr.deep_check_dryland',
        category: cat,
        priority: 40,
        when: [c, eq(FactKeys.waterRegime, 'dryland')],
        recs: ['Kuru tarım — toprak profilinde nem kapasitesini ekim öncesi koruyun (yaz nadası, anız korunumu).'],
        confidence: 'medium',
        evidence: ev,
      ),
      rule(
        id: 'rule.sunflower.irr.wind_block_sprinkler',
        category: cat,
        priority: 50,
        when: [c, gt(FactKeys.windSpeedMs, 6), eq(FactKeys.waterRegime, 'irrigated')],
        recs: ['Rüzgar > 6 m/s — yağmurlama sulamasında dağılım bozulur, sakin saatleri bekleyin.'],
        confidence: 'medium',
        evidence: ev,
      ),
      rule(
        id: 'rule.sunflower.irr.salinity_leach',
        category: cat,
        priority: 60,
        when: [c, gt(FactKeys.soilEc, 2.0), eq(FactKeys.waterRegime, 'irrigated')],
        recs: ['Tuzluluk yüksek — periyodik yıkama sulaması ile kök bölgesi tuz birikimini azaltın.'],
        confidence: 'medium',
        evidence: ev,
      ),
      rule(
        id: 'rule.sunflower.irr.water_balance_default',
        category: cat,
        priority: 35,
        when: [c],
        recs: ['Tipik sezonluk su talebi 400-600 mm; bölge ve çeşide göre değişir.'],
        confidence: 'medium',
        evidence: ev,
      ),
      rule(
        id: 'rule.sunflower.irr.last_watered_too_recent',
        category: cat,
        priority: 45,
        when: [c, lt(FactKeys.lastWateredHoursAgo, 12)],
        recs: ['12 saat içinde sulanmış — toprak henüz nemli, ek sulama önerilmez.'],
        confidence: 'medium',
        evidence: ev,
      ),
      rule(
        id: 'rule.sunflower.irr.scheduled_irrigation_check',
        category: cat,
        priority: 30,
        when: [c, eq(FactKeys.waterRegime, 'irrigated')],
        recs: ['Sulama planını GDD birikimine göre güncelleyin; sabit takvim yerine ürün talebi.'],
        confidence: 'medium',
        evidence: ev,
      ),
    ];
  }

  // ════════════════════════════════════════════════════════════════════
  // 16) POST-HARVEST — Hasat sonrası
  // ════════════════════════════════════════════════════════════════════
  static List<Rule> _postHarvest() {
    const cat = RuleCategories.taskGeneration;
    final ev = pendingEvidence(SourceIds.sunflowerAgronomy);
    final c = eq(_cropFact, _cropId);
    final stage = eq(FactKeys.growthStage, 'harvest');
    return [
      rule(
        id: 'rule.sunflower.post.rotation_minimum',
        category: cat,
        priority: 75,
        when: [c, stage],
        recs: ['Aynı tarlada ayçiçeği için en az 4 yıllık ekim nöbeti zorunludur — Sclerotinia, orobanş ve toprak hastalıkları için.'],
        confidence: 'high',
        evidence: pendingEvidence(SourceIds.sunflowerOrobanche),
      ),
      rule(
        id: 'rule.sunflower.post.residue_burning_avoid',
        category: cat,
        priority: 60,
        when: [c, stage],
        recs: ['Anız yakma yasaktır ve organik madde kaybına yol açar — anızı parçalayıp toprağa karıştırın.'],
        confidence: 'high',
        evidence: ev,
      ),
      rule(
        id: 'rule.sunflower.post.sclerotinia_residue',
        category: cat,
        priority: 65,
        when: [c, stage, eq(FactKeys.observedSymptom, 'head_rot')],
        recs: ['Sclerotinia gözlendiyse hastalıklı bitki artıkları tarladan uzaklaştırılır — toprakta sklerot kalmasın.'],
        confidence: 'medium',
        evidence: pendingEvidence(SourceIds.sunflowerIpm),
      ),
      rule(
        id: 'rule.sunflower.post.cover_crop',
        category: cat,
        priority: 40,
        when: [c, stage],
        recs: ['Hasat sonrası örtü bitkisi (fiğ, çavdar) toprak yapısını korur, yabancı ot baskılar.'],
        confidence: 'medium',
        evidence: ev,
      ),
      rule(
        id: 'rule.sunflower.post.soil_sample_next_season',
        category: cat,
        priority: 50,
        when: [c, stage],
        recs: ['Sonraki sezon için hasat sonrası toprak örneklemesi planlayın — gübreleme planının temeli.'],
        confidence: 'high',
        evidence: ev,
      ),
      rule(
        id: 'rule.sunflower.post.yield_log',
        category: cat,
        priority: 35,
        when: [c, stage],
        recs: ['Verim, nem, yağ oranı, hastalık notlarını kayıt altına alın — sonraki sezon kararları için.'],
        confidence: 'medium',
        evidence: ev,
      ),
      rule(
        id: 'rule.sunflower.post.storage_check',
        category: cat,
        priority: 50,
        when: [c, stage],
        recs: ['Depolama nem < %9; havalı, kuru, kemirgensiz depo.'],
        confidence: 'medium',
        evidence: ev,
      ),
      rule(
        id: 'rule.sunflower.post.deep_tillage_residue',
        category: cat,
        priority: 40,
        when: [c, stage],
        recs: ['Hasat sonrası derin sürüm artıkları ve toprak yapısını iyileştirir.'],
        confidence: 'low',
        evidence: ev,
      ),
    ];
  }

  // ════════════════════════════════════════════════════════════════════
  // 17) WEATHER WARNINGS — Hava uyarıları (don, dolu, sıcak rüzgar)
  // ════════════════════════════════════════════════════════════════════
  static List<Rule> _weatherWarnings() {
    const cat = RuleCategories.weatherWarning;
    final ev = pendingEvidence(SourceIds.meteorologyMgm);
    final c = eq(_cropFact, _cropId);
    return [
      rule(
        id: 'rule.sunflower.wea.frost_seedling',
        category: cat,
        priority: 90,
        risk: 'high',
        when: [c, eq(FactKeys.frostRiskNext48h, true), isIn(FactKeys.growthStage, ['emergence', 'seedling'])],
        recs: ['Fide dönemi + don riski — kayıplara karşı alanı izleyin, ölü fideler için yeniden ekim planı.'],
        confidence: 'high',
        evidence: ev,
      ),
      rule(
        id: 'rule.sunflower.wea.frost_general',
        category: cat,
        priority: 70,
        risk: 'medium',
        when: [c, eq(FactKeys.frostRiskNext48h, true)],
        recs: ['Don riski — bitki gelişim evresine göre kayıp olabilir; tarlayı yakın izleyin.'],
        confidence: 'medium',
        evidence: ev,
      ),
      rule(
        id: 'rule.sunflower.wea.hail_warn',
        category: cat,
        priority: 85,
        risk: 'high',
        when: [c, eq(FactKeys.hailRiskNext24h, true)],
        recs: ['Dolu riski — büyük baş zararı olabilir; sigorta poliçesini ve önlemleri kontrol edin.'],
        confidence: 'high',
        evidence: ev,
      ),
      rule(
        id: 'rule.sunflower.wea.heat_wave',
        category: cat,
        priority: 70,
        risk: 'medium',
        when: [c, gt(FactKeys.tempMax24hC, 38)],
        recs: ['38 °C üstü sıcaklık dalgası — sulamayı önceleyin, kritik evrede polen sterilitesi riski.'],
        confidence: 'medium',
        evidence: ev,
      ),
      rule(
        id: 'rule.sunflower.wea.cold_snap',
        category: cat,
        priority: 65,
        risk: 'medium',
        when: [c, lt(FactKeys.tempMin24hC, 5)],
        recs: ['Soğuk dalgası — gelişim yavaşlar; fide ise risk yüksek.'],
        confidence: 'medium',
        evidence: ev,
      ),
      rule(
        id: 'rule.sunflower.wea.high_wind',
        category: cat,
        priority: 60,
        when: [c, gt(FactKeys.windSpeedMs, 15)],
        recs: ['Yüksek rüzgar — yatış ve baş kırılma riski; uygulama planlarını iptal edin.'],
        confidence: 'medium',
        evidence: ev,
      ),
      rule(
        id: 'rule.sunflower.wea.heavy_rain',
        category: cat,
        priority: 65,
        risk: 'medium',
        when: [c, gt(FactKeys.forecastRain24hMm, 30)],
        recs: ['24 saatte 30 mm+ yağış — drenajı kontrol edin, su göllenmesi kök hastalıklarını tetikler.'],
        confidence: 'medium',
        evidence: ev,
      ),
      rule(
        id: 'rule.sunflower.wea.dry_streak',
        category: cat,
        priority: 55,
        when: [c, lt(FactKeys.weeklyRainMm, 3), gt(FactKeys.tempMax24hC, 32)],
        recs: ['Kurak + sıcak — su talebi yüksek; sulu tarımda sulama, kuru tarımda gözlem.'],
        confidence: 'medium',
        evidence: ev,
      ),
      rule(
        id: 'rule.sunflower.wea.fog_disease_trigger',
        category: RuleCategories.diseaseRisk,
        priority: 55,
        when: [c, gte(FactKeys.humidityPct, 90)],
        recs: ['Yüksek nem/sis — yaprak ıslaklığı uzar, mantari hastalık riski artar.'],
        confidence: 'medium',
        evidence: pendingEvidence(SourceIds.sunflowerIpm),
      ),
      rule(
        id: 'rule.sunflower.wea.spraying_block_rain',
        category: cat,
        priority: 65,
        when: [c, gt(FactKeys.forecastRain24hMm, 5)],
        recs: ['24 saatte yağış bekleniyor — kimyasal uygulama yıkanır; uygulamayı erteleyin.'],
        confidence: 'high',
        evidence: ev,
      ),
      rule(
        id: 'rule.sunflower.wea.spraying_block_wind',
        category: cat,
        priority: 65,
        when: [c, gt(FactKeys.windSpeedMs, 4)],
        recs: ['Rüzgar > 4 m/s — kimyasal sürüklenme (drift) riski; sakin saatleri bekleyin.'],
        confidence: 'high',
        evidence: ev,
      ),
      rule(
        id: 'rule.sunflower.wea.fohn_warning',
        category: cat,
        priority: 60,
        when: [c, gt(FactKeys.windSpeedMs, 10), lt(FactKeys.humidityPct, 25), gt(FactKeys.tempMax24hC, 30)],
        recs: ['Fön/kuru sıcak rüzgar — polen kuruması, yaprak yanığı; sulamayla mikroklima yumuşatın.'],
        confidence: 'low',
        evidence: ev,
      ),
      rule(
        id: 'rule.sunflower.wea.early_frost_maturity',
        category: cat,
        priority: 75,
        risk: 'high',
        when: [c, eq(FactKeys.frostRiskNext48h, true), eq(FactKeys.growthStage, 'maturity')],
        recs: ['Olgunlukta don riski — yağ oranı düşer, hasada öncelik.'],
        confidence: 'medium',
        evidence: ev,
      ),
      rule(
        id: 'rule.sunflower.wea.thunderstorm_lodging',
        category: cat,
        priority: 65,
        risk: 'medium',
        when: [c, gt(FactKeys.forecastRain24hMm, 25), gt(FactKeys.windSpeedMs, 12)],
        recs: ['Şiddetli yağış + rüzgar — yatış riski; geç dönemde olduğumuzda erken hasat alternatifi.'],
        confidence: 'medium',
        evidence: ev,
      ),
      rule(
        id: 'rule.sunflower.wea.uv_high_advice',
        category: RuleCategories.safetyWarning,
        priority: 30,
        when: [c, gt(FactKeys.tempMax24hC, 35)],
        recs: ['Yüksek sıcaklık — uygulayıcı için UV ve sıcak çarpması riski; öğle saatlerinde tarlaya çıkmayın.'],
        confidence: 'high',
        evidence: ev,
      ),
    ];
  }

  // ════════════════════════════════════════════════════════════════════
  // 18) UNIQUE TRAITS — Ayçiçeğine özgü özellikler
  // ════════════════════════════════════════════════════════════════════
  static List<Rule> _uniqueTraits() {
    const cat = RuleCategories.cropUnique;
    final ev = pendingEvidence(SourceIds.sunflowerAgronomy);
    final c = eq(_cropFact, _cropId);
    return [
      rule(
        id: 'rule.sunflower.unique.heliotropism',
        category: cat,
        priority: 25,
        when: [c, eq(FactKeys.growthStage, 'pre_flowering')],
        recs: ['Genç bitkilerde fototropizm/heliotropizm normaldir — başlar gün boyunca güneşi takip eder, geceleri doğuya döner.'],
        confidence: 'high',
        evidence: ev,
      ),
      rule(
        id: 'rule.sunflower.unique.east_facing_mature',
        category: cat,
        priority: 25,
        when: [c, isIn(FactKeys.growthStage, ['grain_filling', 'maturity'])],
        recs: ['Olgun başlar doğuya bakar ve hareket etmez — bu doğal davranış, hastalık değildir.'],
        confidence: 'high',
        evidence: ev,
      ),
      rule(
        id: 'rule.sunflower.unique.deep_taproot',
        category: cat,
        priority: 30,
        when: [c],
        recs: ['Ayçiçeği derin saçaklı kök yapar (1.5-2 m) — bu yüzden ekim derin işlenmiş toprakta verim verir.'],
        confidence: 'high',
        evidence: ev,
      ),
      rule(
        id: 'rule.sunflower.unique.allelopathy_warning',
        category: cat,
        priority: 35,
        when: [c, eq(FactKeys.growthStage, 'harvest')],
        recs: ['Ayçiçeği bitki artıkları allelopatik etki taşır — sonraki ürün ekiminde aralık veya iyi parçalama gerekir.'],
        confidence: 'medium',
        evidence: ev,
      ),
      rule(
        id: 'rule.sunflower.unique.orobanche_host_specificity',
        category: cat,
        priority: 70,
        when: [c, eq(FactKeys.observedWeed, 'orobanche')],
        recs: ['Orobanş özelleşmiş bir konaktır — ayçiçeği dışında çoğu kültür bitkisine girmez, rotasyon en etkili çözüm.'],
        confidence: 'high',
        evidence: pendingEvidence(SourceIds.sunflowerOrobanche),
      ),
      rule(
        id: 'rule.sunflower.unique.oil_vs_confection',
        category: cat,
        priority: 30,
        when: [c],
        recs: ['Yağlık (siyah dane) ve çerezlik (çizgili dane) çeşitler farklı pazardır — çeşit seçimi pazarınıza göre.'],
        confidence: 'high',
        evidence: ev,
      ),
      rule(
        id: 'rule.sunflower.unique.no_self_rotation',
        category: cat,
        priority: 70,
        when: [c, eq(FactKeys.growthStage, 'harvest')],
        recs: ['Aynı tarlaya art arda ayçiçeği ekmek toprak yorgunluğu, hastalık birikimi ve orobanş çoğalmasına yol açar — minimum 4 yıl bekleyin.'],
        confidence: 'high',
        evidence: pendingEvidence(SourceIds.sunflowerOrobanche),
      ),
      rule(
        id: 'rule.sunflower.unique.bee_attraction',
        category: cat,
        priority: 30,
        when: [c, eq(FactKeys.growthStage, 'flowering')],
        recs: ['Ayçiçeği bal arıları için önemli nektar kaynağıdır — yöre arıcılarla iletişim verimi artırır.'],
        confidence: 'high',
        evidence: ev,
      ),
      rule(
        id: 'rule.sunflower.unique.head_diameter_target',
        category: cat,
        priority: 25,
        when: [c, isIn(FactKeys.growthStage, ['grain_filling', 'maturity'])],
        recs: ['Sağlıklı baş çapı 18-25 cm tipiktir; çok büyük başlar (>30 cm) genelde dolum kalitesi düşüktür.'],
        confidence: 'medium',
        evidence: ev,
      ),
      rule(
        id: 'rule.sunflower.unique.c3_metabolism_hot_dry',
        category: cat,
        priority: 25,
        when: [c, gt(FactKeys.tempMax24hC, 36)],
        recs: ['Ayçiçeği C3 bitkisidir — yüksek sıcak + kuru havada fotosentez verimi düşer; sulama ile yaprak sıcaklığını düşürmek önerilir.'],
        confidence: 'medium',
        evidence: ev,
      ),
    ];
  }
}
