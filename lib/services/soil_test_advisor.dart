/// Modül — Laboratuvar Toprak Analizi Değerlendirmesi.
///
/// Çiftçinin akredite bir laboratuvardan aldığı **gerçek** toprak analizi
/// sonuçlarını deterministik olarak yorumlar ve kaynaklı, açıklanabilir
/// Türkçe öneriler üretir.
///
/// Tasarım ilkeleri (CLAUDE.md §16, §22, §29):
///   • Saf fonksiyon — IO yok, ağ yok, rastgelelik yok. Aynı girdi → aynı çıktı.
///   • Uydurma yok: değer girilmemişse (null) o parametre yorumlanmaz.
///   • Yorum sınıfları yayınlanmış TAGEM / Toprak-Gübre-Su standart
///     değerlendirme tablolarına dayanır (referans aşağıda her bulguda).
///   • İlaç / BKÜ önerisi YOK. Kesin gübre cinsi ve dozu laboratuvar
///     raporundaki ziraat mühendisi önerisine / güncel resmî kaynağa
///     bırakılır; burada yalnızca yön + konservatif aralık verilir.
library;

import 'soil_fertilization_service.dart';

/// Standart yorum tablolarının ortak kaynak etiketi.
const String _kSource =
    'TAGEM / Toprak Gübre ve Su Kaynakları Merkez Araştırma Enstitüsü — '
    'Toprak ve Bitki Analizlerinin Değerlendirilmesi';

/// Bir bulgunun önem derecesi. Dahili enum (İngilizce) — kullanıcıya
/// görünmez; UI renk + etiket eşler.
enum SoilSeverity { ideal, info, warning, critical }

/// Tek bir toprak parametresinin değerlendirmesi.
class SoilFinding {
  /// Kullanıcıya görünen parametre adı, ör. 'pH', 'Fosfor (P₂O₅)'.
  final String parameter;

  /// Ölçülen değer + birim, ör. '5.2', '4.0 kg/dekar'.
  final String measured;

  /// Standart sınıf etiketi, ör. 'Orta asit', 'Az', 'Yeterli'.
  final String level;

  final SoilSeverity severity;

  /// Değerin ne anlama geldiği (Türkçe, kısa).
  final String interpretation;

  /// Önerilen aksiyon — yoksa null (değer ideal aralıkta).
  final String? action;

  /// Bu yorumun dayandığı kaynak.
  final String source;

  const SoilFinding({
    required this.parameter,
    required this.measured,
    required this.level,
    required this.severity,
    required this.interpretation,
    this.action,
    this.source = _kSource,
  });
}

/// `SoilTestAdvisor.analyze` çıktısı.
class SoilTestAdvice {
  /// Önem sırasına göre (kritik → ideal) sıralı bulgular.
  final List<SoilFinding> findings;

  /// Genel özet (kaç parametre dikkat gerektiriyor vb.).
  final String summary;

  /// Opsiyonel ürün bazlı dönemsel gübre takvimi (genel rehber).
  final List<FertilizationStep> fertilizationPlan;

  /// Her zaman gösterilmesi gereken uyarılar (CLAUDE.md §16 / §28).
  final List<String> disclaimers;

  /// En az bir ölçülen değer girilmiş mi.
  final bool hasInput;

  const SoilTestAdvice({
    required this.findings,
    required this.summary,
    required this.fertilizationPlan,
    required this.disclaimers,
    required this.hasInput,
  });

  /// Dikkat (warning) veya kritik bulgu sayısı.
  int get attentionCount => findings
      .where((f) => f.severity.index >= SoilSeverity.warning.index)
      .length;
}

/// Laboratuvar analizi için kullanıcı girdisi. Tüm alanlar nullable —
/// raporda olmayan değer `null` bırakılır ve yorumlanmaz.
class SoilTestInput {
  final double? ph;

  /// % Toplam tuz (satüre çamur).
  final double? saltPct;

  /// EC — elektriksel iletkenlik (dS/m, satürasyon ekstraktı).
  final double? ecDsM;

  /// Kireç CaCO₃ %.
  final double? limePct;

  /// Organik madde %.
  final double? organicMatterPct;

  /// Fosfor P₂O₅ kg/dekar (Olsen).
  final double? phosphorusKgDa;

  /// Potasyum K₂O kg/dekar.
  final double? potassiumKgDa;

  /// Toplam azot %.
  final double? nitrogenPct;

  /// Suyla doygunluk % (doku sınıfı türetmek için).
  final double? saturationPct;

  /// Doğrudan girilen/bilinen doku sınıfı (varsa saturationPct'e öncelikli).
  final String? textureClass;

  /// Tarlanın aktif ürünü — gübre takvimi için (opsiyonel).
  final String? cropName;

  const SoilTestInput({
    this.ph,
    this.saltPct,
    this.ecDsM,
    this.limePct,
    this.organicMatterPct,
    this.phosphorusKgDa,
    this.potassiumKgDa,
    this.nitrogenPct,
    this.saturationPct,
    this.textureClass,
    this.cropName,
  });

  bool get hasAnyMeasurement =>
      ph != null ||
      saltPct != null ||
      ecDsM != null ||
      limePct != null ||
      organicMatterPct != null ||
      phosphorusKgDa != null ||
      potassiumKgDa != null ||
      nitrogenPct != null ||
      saturationPct != null;
}

class SoilTestAdvisor {
  SoilTestAdvisor._();

  /// Verilen lab girdisini deterministik olarak değerlendirir.
  static SoilTestAdvice analyze(SoilTestInput input) {
    final findings = <SoilFinding>[];

    final texture =
        input.textureClass ?? textureFromSaturation(input.saturationPct);

    // ── Doku (suyla doygunluk) ──────────────────────────────────────────
    if (texture != null) {
      findings.add(SoilFinding(
        parameter: 'Bünye (Doku)',
        measured: input.saturationPct != null
            ? '%${_fmt(input.saturationPct!)} doygunluk → $texture'
            : texture,
        level: texture,
        severity: SoilSeverity.info,
        interpretation:
            'Toprak dokusu su tutma, havalanma ve gübre tutma kapasitesini belirler.',
        action:
            'Bu doku için uygun ürünler: ${SoilFertilizationService.suitableCropsForTexture(texture)}',
      ));
    }

    // ── pH ──────────────────────────────────────────────────────────────
    if (input.ph != null) {
      findings.add(_phFinding(input.ph!, texture, input.limePct));
    }

    // ── Tuzluluk (% toplam tuz) ─────────────────────────────────────────
    if (input.saltPct != null) {
      findings.add(_saltPctFinding(input.saltPct!));
    }

    // ── Tuzluluk (EC dS/m) ──────────────────────────────────────────────
    if (input.ecDsM != null) {
      findings.add(_ecFinding(input.ecDsM!));
    }

    // ── Kireç (CaCO₃ %) ─────────────────────────────────────────────────
    if (input.limePct != null) {
      findings.add(_limeFinding(input.limePct!));
    }

    // ── Organik madde % ─────────────────────────────────────────────────
    if (input.organicMatterPct != null) {
      findings.add(_organicMatterFinding(input.organicMatterPct!));
    }

    // ── Fosfor (P₂O₅ kg/da) ─────────────────────────────────────────────
    if (input.phosphorusKgDa != null) {
      findings.add(_phosphorusFinding(input.phosphorusKgDa!));
    }

    // ── Potasyum (K₂O kg/da) ────────────────────────────────────────────
    if (input.potassiumKgDa != null) {
      findings.add(_potassiumFinding(input.potassiumKgDa!));
    }

    // ── Toplam azot % ───────────────────────────────────────────────────
    if (input.nitrogenPct != null) {
      findings.add(_nitrogenFinding(input.nitrogenPct!));
    }

    // Önem sırasına göre sırala (kritik → ideal), giriş sırası eşitlikte korunur.
    final ordered = List<SoilFinding>.from(findings);
    _stableSortBySeverity(ordered);

    // ── Ürün gübre takvimi — laboratuvar değerlerine göre ayarlanır ──────
    // Taban takvim üründen gelir; N/P/K seviyesine göre dozlar ölçeklenir.
    // Analiz değeri yoksa adjustPlanForSoil planı aynen döndürür (§16).
    final crop = input.cropName?.trim();
    final basePlan =
        (crop != null && crop.isNotEmpty && input.hasAnyMeasurement)
            ? SoilFertilizationService.fertilizationPlan(crop)
            : const <FertilizationStep>[];
    final plan = SoilFertilizationService.adjustPlanForSoil(
      basePlan,
      nitrogenPct: input.nitrogenPct,
      phosphorusKgDa: input.phosphorusKgDa,
      potassiumKgDa: input.potassiumKgDa,
    );

    return SoilTestAdvice(
      findings: ordered,
      summary: _summary(ordered, input),
      fertilizationPlan: plan,
      disclaimers: _disclaimers(),
      hasInput: input.hasAnyMeasurement,
    );
  }

  // ───────────────────────────────────────────────────────────────────────
  // PARAMETRE SINIFLAYICILARI
  // ───────────────────────────────────────────────────────────────────────

  static SoilFinding _phFinding(double ph, String? texture, double? limePct) {
    String level;
    SoilSeverity sev;
    String interp;
    String? action;

    if (ph < 4.5) {
      level = 'Kuvvetli asit';
      sev = SoilSeverity.critical;
      interp =
          'pH çok düşük. Besin alımı ciddi kısıtlanır; alüminyum/manganez toksisitesi riski vardır.';
      action = _limingAction(ph, texture);
    } else if (ph < 5.5) {
      level = 'Orta asit';
      sev = SoilSeverity.warning;
      interp =
          'Asitlik birçok kültür bitkisinde verimi düşürür; fosfor elverişliliği azalır.';
      action = _limingAction(ph, texture);
    } else if (ph < 6.5) {
      level = 'Hafif asit';
      sev = SoilSeverity.info;
      interp =
          'Çoğu kültür bitkisi için uygun aralığa yakın; asit seven ürünlerde idealdir.';
      action = null;
    } else if (ph <= 7.5) {
      level = 'Nötr';
      sev = SoilSeverity.ideal;
      interp =
          'İdeal aralık. Besin maddelerinin elverişliliği en yüksek seviyededir.';
      action = null;
    } else if (ph <= 8.5) {
      level = 'Hafif alkali';
      sev = SoilSeverity.info;
      interp =
          'Yüksek pH demir (Fe), çinko (Zn) ve fosfor elverişliliğini azaltabilir.';
      action = _highPhAction(limePct);
    } else {
      level = 'Kuvvetli alkali';
      sev = SoilSeverity.warning;
      interp =
          'Sodiklik/aşırı kireç olasılığı; mikro element noksanlığı (özellikle demir klorozu) riski yüksek.';
      action = _highPhAction(limePct);
    }

    return SoilFinding(
      parameter: 'pH (reaksiyon)',
      measured: _fmt(ph),
      level: level,
      severity: sev,
      interpretation: interp,
      action: action,
    );
  }

  static SoilFinding _saltPctFinding(double salt) {
    String level;
    SoilSeverity sev;
    String interp;
    String? action;

    if (salt < 0.15) {
      level = 'Tuzsuz';
      sev = SoilSeverity.ideal;
      interp = 'Tuzluluk sorunu yok.';
    } else if (salt < 0.35) {
      level = 'Hafif tuzlu';
      sev = SoilSeverity.info;
      interp = 'Tuza hassas bitkilerde hafif verim kaybı görülebilir.';
      action = _salinityAction;
    } else if (salt <= 0.65) {
      level = 'Orta tuzlu';
      sev = SoilSeverity.warning;
      interp = 'Birçok bitkide çimlenme ve verim olumsuz etkilenir.';
      action = _salinityAction;
    } else {
      level = 'Çok tuzlu';
      sev = SoilSeverity.critical;
      interp =
          'Yalnızca tuza dayanıklı bitkiler yetişebilir; köklerde su alımı engellenir.';
      action = _salinityAction;
    }

    return SoilFinding(
      parameter: 'Tuzluluk (% toplam tuz)',
      measured: '%${_fmt(salt)}',
      level: level,
      severity: sev,
      interpretation: interp,
      action: action,
    );
  }

  static SoilFinding _ecFinding(double ec) {
    String level;
    SoilSeverity sev;
    String interp;
    String? action;

    if (ec < 2) {
      level = 'Tuzsuz';
      sev = SoilSeverity.ideal;
      interp = 'Tuzluluğun bitki üzerinde etkisi ihmal edilebilir.';
    } else if (ec < 4) {
      level = 'Çok hafif tuzlu';
      sev = SoilSeverity.info;
      interp = 'Yalnızca tuza çok hassas bitkilerde verim sınırlanır.';
      action = _salinityAction;
    } else if (ec < 8) {
      level = 'Orta tuzlu';
      sev = SoilSeverity.warning;
      interp = 'Birçok bitkide verim belirgin şekilde düşer.';
      action = _salinityAction;
    } else if (ec <= 15) {
      level = 'Kuvvetli tuzlu';
      sev = SoilSeverity.critical;
      interp = 'Yalnızca tuza dayanıklı bitkiler tatmin edici verir.';
      action = _salinityAction;
    } else {
      level = 'Çok kuvvetli tuzlu';
      sev = SoilSeverity.critical;
      interp = 'Çok az sayıda dayanıklı bitki yetişebilir; ıslah gerekir.';
      action = _salinityAction;
    }

    return SoilFinding(
      parameter: 'Tuzluluk (EC)',
      measured: '${_fmt(ec)} dS/m',
      level: level,
      severity: sev,
      interpretation: interp,
      action: action,
    );
  }

  static SoilFinding _limeFinding(double lime) {
    String level;
    SoilSeverity sev;
    String interp;
    String? action;

    if (lime < 1) {
      level = 'Az kireçli';
      sev = SoilSeverity.info;
      interp =
          'Kireç düşük; toprak asit olabilir. pH değeriyle birlikte değerlendirin.';
    } else if (lime < 5) {
      level = 'Kireçli';
      sev = SoilSeverity.ideal;
      interp = 'Kireç düzeyi genel tarım için uygun aralıkta.';
    } else if (lime < 15) {
      level = 'Orta kireçli';
      sev = SoilSeverity.info;
      interp = 'Çoğu bitki için sorun oluşturmaz.';
    } else if (lime <= 25) {
      level = 'Fazla kireçli';
      sev = SoilSeverity.warning;
      interp =
          'Yüksek kireç fosfor ile demir/çinko fiksasyonunu artırır; kloroz riski.';
      action =
          'Fosforlu gübreyi bölerek (band) uygulayın; demir/çinko için şelatlı (EDDHA/EDTA) mikro besin tercih edin.';
    } else {
      level = 'Çok fazla kireçli';
      sev = SoilSeverity.warning;
      interp = 'Demir klorozu ve mikro element noksanlığı riski yüksektir.';
      action =
          'Fosforu bölerek band uygulayın; şelatlı demir/çinko verin; asitleyici gübre (amonyum sülfat) tercih edin.';
    }

    return SoilFinding(
      parameter: 'Kireç (CaCO₃)',
      measured: '%${_fmt(lime)}',
      level: level,
      severity: sev,
      interpretation: interp,
      action: action,
    );
  }

  static SoilFinding _organicMatterFinding(double om) {
    String level;
    SoilSeverity sev;
    String interp;
    String? action;

    if (om < 1) {
      level = 'Çok az';
      sev = SoilSeverity.warning;
      interp =
          'Organik madde kritik derecede düşük; toprak yapısı, su tutma ve besin sağlama zayıf.';
      action = _organicMatterAction;
    } else if (om < 2) {
      level = 'Az';
      sev = SoilSeverity.warning;
      interp = 'Organik madde yetersiz; verim ve toprak sağlığı sınırlanır.';
      action = _organicMatterAction;
    } else if (om < 3) {
      level = 'Orta';
      sev = SoilSeverity.info;
      interp =
          'Organik madde kabul edilebilir; korumak için organik girdi sürdürün.';
    } else if (om <= 4) {
      level = 'İyi';
      sev = SoilSeverity.ideal;
      interp = 'Organik madde düzeyi iyi; toprak verimliliği yüksek.';
    } else {
      level = 'Yüksek';
      sev = SoilSeverity.ideal;
      interp = 'Organik madde yüksek; toprak sağlığı açısından olumlu.';
    }

    return SoilFinding(
      parameter: 'Organik madde',
      measured: '%${_fmt(om)}',
      level: level,
      severity: sev,
      interpretation: interp,
      action: action,
    );
  }

  static SoilFinding _phosphorusFinding(double p) {
    String level;
    SoilSeverity sev;
    String interp;
    String? action;

    if (p < 3) {
      level = 'Çok az';
      sev = SoilSeverity.warning;
      interp = 'Fosfor çok düşük; kök gelişimi ve verim ciddi kısıtlanır.';
      action = _phosphorusAction;
    } else if (p < 6) {
      level = 'Az';
      sev = SoilSeverity.warning;
      interp = 'Fosfor yetersiz; taban gübresiyle desteklenmeli.';
      action = _phosphorusAction;
    } else if (p < 9) {
      level = 'Orta (yeterli)';
      sev = SoilSeverity.ideal;
      interp = 'Fosfor düzeyi çoğu ürün için yeterli aralıkta.';
    } else if (p <= 12) {
      level = 'Yüksek';
      sev = SoilSeverity.info;
      interp = 'Fosfor yüksek; bu sezon fosforlu gübre ihtiyacı düşüktür.';
      action = 'Fosforlu taban gübre miktarını azaltın veya bu sezon atlayın.';
    } else {
      level = 'Çok yüksek';
      sev = SoilSeverity.warning;
      interp =
          'Aşırı fosfor çinko alımını engeller ve çevresel (su) risk oluşturur.';
      action =
          'Fosforlu gübre vermeyin; çinko noksanlığı belirtilerini izleyin.';
    }

    return SoilFinding(
      parameter: 'Fosfor (P₂O₅)',
      measured: '${_fmt(p)} kg/dekar',
      level: level,
      severity: sev,
      interpretation: interp,
      action: action,
    );
  }

  static SoilFinding _potassiumFinding(double k) {
    String level;
    SoilSeverity sev;
    String interp;
    String? action;

    if (k < 20) {
      level = 'Az';
      sev = SoilSeverity.warning;
      interp =
          'Potasyum yetersiz; meyve/tane kalitesi ve strese dayanıklılık düşer.';
      action = _potassiumAction;
    } else if (k < 30) {
      level = 'Orta';
      sev = SoilSeverity.info;
      interp =
          'Potasyum orta düzeyde; talep yüksek ürünlerde takviye gerekebilir.';
      action = _potassiumAction;
    } else if (k <= 40) {
      level = 'Yeterli';
      sev = SoilSeverity.ideal;
      interp = 'Potasyum çoğu ürün için yeterli aralıkta.';
    } else {
      level = 'Yüksek';
      sev = SoilSeverity.info;
      interp = 'Potasyum yüksek; aşırısı magnezyum alımını baskılayabilir.';
      action = 'Potasyumlu gübreyi azaltın; magnezyum durumunu izleyin.';
    }

    return SoilFinding(
      parameter: 'Potasyum (K₂O)',
      measured: '${_fmt(k)} kg/dekar',
      level: level,
      severity: sev,
      interpretation: interp,
      action: action,
    );
  }

  static SoilFinding _nitrogenFinding(double n) {
    String level;
    SoilSeverity sev;
    String interp;
    String? action;

    if (n < 0.045) {
      level = 'Çok az';
      sev = SoilSeverity.warning;
      interp = 'Toplam azot çok düşük; vejetatif gelişim sınırlı olur.';
      action = _nitrogenAction;
    } else if (n < 0.09) {
      level = 'Az';
      sev = SoilSeverity.warning;
      interp = 'Azot yetersiz; üst gübreleme planlanmalı.';
      action = _nitrogenAction;
    } else if (n < 0.17) {
      level = 'Orta';
      sev = SoilSeverity.info;
      interp =
          'Azot orta düzeyde; ürün talebine göre bölünmüş gübreleme uygun.';
    } else if (n <= 0.32) {
      level = 'İyi';
      sev = SoilSeverity.ideal;
      interp = 'Azot düzeyi iyi.';
    } else {
      level = 'Yüksek';
      sev = SoilSeverity.info;
      interp = 'Azot yüksek; aşırı azot yatma ve hastalık riskini artırabilir.';
      action = 'Azotlu gübreyi azaltın; aşırı azottan kaçının.';
    }

    return SoilFinding(
      parameter: 'Toplam azot',
      measured: '%${_fmt(n)}',
      level: level,
      severity: sev,
      interpretation: interp,
      action: action,
    );
  }

  // ───────────────────────────────────────────────────────────────────────
  // ORTAK AKSİYON METİNLERİ
  // ───────────────────────────────────────────────────────────────────────

  static const String _salinityAction =
      'Drenajı iyileştirin ve bol su ile yıkama (leaching) yapın; tuz indeksi yüksek '
      'gübrelerden ve aşırı azottan kaçının; mümkünse tuza dayanıklı ürün/çeşit seçin.';

  static const String _organicMatterAction =
      'Yanmış ahır gübresi (yaklaşık 2-4 ton/dekar), yeşil gübreleme veya kompost ile '
      'organik maddeyi kademeli artırın.';

  static const String _phosphorusAction =
      'Ekim öncesi fosforlu taban gübre (DAP veya TSP) planlayın. Kesin dozu ürün ve '
      'hedef verime göre laboratuvar raporundaki öneriyi esas alarak belirleyin.';

  static const String _potassiumAction =
      'Potasyumlu gübre (kireçli/tuzlu topraklarda potasyum sülfat tercih edilir) ile '
      'takviye edin; kesin dozu lab raporuna göre ayarlayın.';

  static const String _nitrogenAction =
      'Azotu tek seferde değil, bitkinin gelişim dönemlerine bölerek verin '
      '(taban + üst gübreleme). Toprak nemli ve yağıştan önce uygulayın.';

  /// pH yükseltmek için kireçleme dozu — konservatif aralık (doku tampona göre).
  static String _limingAction(double ph, String? texture) {
    const target = 6.5;
    final delta = (target - ph).clamp(0.0, 3.0);
    final buffer = _bufferFactor(texture);
    final mid = (delta * 250 * buffer).clamp(100.0, 800.0);
    final lo = (mid * 0.8).round();
    final hi = (mid * 1.2).round();
    return 'pH\'ı yükseltmek için sonbaharda ekim öncesi yaklaşık $lo-$hi kg/dekar tarım '
        'kireci (CaCO₃) yüzeye serpip 15-20 cm karıştırın. Bu aralık dokuya göre tahminîdir; '
        'kesin dozu laboratuvar raporundaki öneriyle teyit edin.';
  }

  /// Yüksek pH için aksiyon — kireç durumuna göre uyarlanır.
  static String _highPhAction(double? limePct) {
    if (limePct != null && limePct >= 15) {
      return 'Toprak kireçli olduğundan kükürtle pH düşürmek pratik değildir. Bunun yerine '
          'asitleyici gübre (amonyum sülfat) kullanın ve demir/çinko için şelatlı (EDDHA) '
          'mikro besin uygulayın.';
    }
    return 'Asit karakterli/amonyumlu gübreleri tercih edin. Belirgin kloroz görülürse '
        'şelatlı demir/çinko uygulayın; gerekirse kükürt dozunu lab raporuna göre planlayın.';
  }

  // ───────────────────────────────────────────────────────────────────────
  // YARDIMCILAR
  // ───────────────────────────────────────────────────────────────────────

  /// Suyla doygunluk %'sinden doku sınıfı türetir (standart aralıklar).
  /// Public — `SoilIrrigationAdvisor` aynı eşik tablosunu yeniden kullanır
  /// (tek doğruluk kaynağı; duplike edilmez).
  static String? textureFromSaturation(double? saturationPct) {
    if (saturationPct == null) return null;
    final s = saturationPct;
    if (s < 30) return 'Kumlu';
    if (s < 50) return 'Tınlı';
    if (s < 70) return 'Killi-Tınlı';
    if (s <= 110) return 'Killi';
    return 'Ağır Killi';
  }

  /// Kireçleme/kükürtleme dozu için doku tampon faktörü.
  static double _bufferFactor(String? texture) {
    switch (texture) {
      case 'Kumlu':
        return 0.8;
      case 'Tınlı':
        return 1.0;
      case 'Killi-Tınlı':
        return 1.3;
      case 'Killi':
        return 1.5;
      case 'Ağır Killi':
        return 1.7;
      default:
        return 1.0;
    }
  }

  static String _summary(List<SoilFinding> findings, SoilTestInput input) {
    if (!input.hasAnyMeasurement) {
      return 'Henüz analiz değeri girilmedi. Laboratuvar raporundaki değerleri girin.';
    }
    final attention = findings
        .where((f) => f.severity.index >= SoilSeverity.warning.index)
        .length;
    if (attention == 0) {
      return 'Girilen ${findings.length} parametre genel olarak uygun aralıkta görünüyor.';
    }
    return '$attention parametre dikkat/iyileştirme gerektiriyor. Önce kırmızı/turuncu '
        'işaretli maddeleri planlayın.';
  }

  static List<String> _disclaimers() => const [
        'Bu değerlendirme bir karar destek çıktısıdır; kesin gübre cinsi ve dozu için '
            'laboratuvar raporundaki ziraat mühendisi önerisini ve güncel resmî kaynakları esas alın.',
        'Öneriler yalnızca örnek alınan tarla kısmını temsil eder. Tarla genelinde toprak '
            'değişkenlik gösteriyorsa farklı kısımlardan ayrı örnek alıp ayrı analiz ettirin.',
        'İlaçlı (kimyasal) mücadele bu ekranın kapsamı dışındadır; gerekirse BKÜ kontrolü '
            've uzman onayı ile ayrıca planlayın.',
      ];

  static void _stableSortBySeverity(List<SoilFinding> list) {
    // index büyük = daha kritik. Kritik önce gelsin → azalan.
    // Dart'ın List.sort'u stabil değildir; index tabanlı stabilizasyon ekliyoruz.
    final indexed = <MapEntry<int, SoilFinding>>[
      for (var i = 0; i < list.length; i++) MapEntry(i, list[i]),
    ];
    indexed.sort((a, b) {
      final s = b.value.severity.index.compareTo(a.value.severity.index);
      if (s != 0) return s;
      return a.key.compareTo(b.key); // eşit önemde giriş sırasını koru
    });
    for (var i = 0; i < list.length; i++) {
      list[i] = indexed[i].value;
    }
  }

  /// Sayıyı gereksiz sıfır olmadan biçimlendirir (5.0 → '5', 5.20 → '5.2').
  static String _fmt(double v) {
    if (v == v.roundToDouble()) return v.toStringAsFixed(0);
    final s = v.toStringAsFixed(2);
    return s.endsWith('0') ? s.substring(0, s.length - 1) : s;
  }
}
