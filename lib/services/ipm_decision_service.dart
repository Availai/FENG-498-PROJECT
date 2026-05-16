import '../data/crop_ipm_rules.dart';

class IpmDecisionService {
  IpmDecisionService._();

  static List<CropIpmRule> rulesForCrop(String? cropName) {
    if (SunflowerIpmRules.supports(cropName)) {
      return SunflowerIpmRules.rules;
    }
    if (TeaIpmRules.supports(cropName)) {
      return TeaIpmRules.rules;
    }
    if (OrangeIpmRules.supports(cropName)) {
      return OrangeIpmRules.rules;
    }
    if (CornIpmRules.supports(cropName)) {
      return CornIpmRules.rules;
    }
    if (TomatoIpmRules.supports(cropName)) {
      return TomatoIpmRules.rules;
    }
    return const [];
  }

  static bool supports(String? cropName) => rulesForCrop(cropName).isNotEmpty;

  static CropIpmRule? ruleFor({
    required String cropName,
    required String pestKey,
  }) {
    for (final rule in rulesForCrop(cropName)) {
      if (rule.pestKey == pestKey) return rule;
    }
    return null;
  }

  static List<IpmScoutingWindow> scoutingWindowsFor(String? cropName) {
    if (SunflowerIpmRules.supports(cropName)) {
      return SunflowerIpmRules.scoutingWindows;
    }
    if (TeaIpmRules.supports(cropName)) {
      return TeaIpmRules.scoutingWindows;
    }
    if (OrangeIpmRules.supports(cropName)) {
      return OrangeIpmRules.scoutingWindows;
    }
    if (CornIpmRules.supports(cropName)) {
      return CornIpmRules.scoutingWindows;
    }
    if (TomatoIpmRules.supports(cropName)) {
      return TomatoIpmRules.scoutingWindows;
    }
    return const [];
  }

  static IpmDecision evaluate(IpmObservationInput input) {
    final rule = ruleFor(cropName: input.cropName, pestKey: input.pestKey);
    if (rule == null) {
      throw ArgumentError('Bu ürün için entegre mücadele kuralı yok.');
    }

    return switch (rule.pestKey) {
      'bozkurt' => _larvaeDecision(
          input,
          rule,
          threshold: 1,
          below:
              'Bozkurt için ekonomik eşik doğrulanmadı. Yabancı ot temizliği ve akşam kontrollerini sürdür.',
        ),
      'yesilkurt' => _affectedPlantDecision(
          input,
          rule,
          thresholdPct: 5,
          below:
              'Yeşilkurt eşiği aşılmadı. Feromon/göz kontrolünü 3-4 gün içinde tekrarla.',
        ),
      'cayir_tirtili' => _larvaeDecision(
          input,
          rule,
          threshold: 10,
          below:
              'Çayır tırtılı sayımı eşik altında. Larva dönemini izlemeye devam et.',
        ),
      'aycicegi_guvesi' => _sunflowerMothDecision(input, rule),
      'telkurtlari' => _larvaeDecision(
          input,
          rule,
          threshold: 6,
          below:
              'Telkurt sayımı eşik altında. Çıkış boşluklarını ve toprak altı larvaları izlemeye devam et.',
        ),
      'mildiyo' => _mildewDecision(input, rule),
      // Çay kuralları — ÇAYKUR'a göre öncelik kültürel
      'cay_kosnili' => _teaCulturalFirstDecision(input, rule, thresholdPct: 20),
      'cay_akari' => _teaCulturalFirstDecision(input, rule, thresholdPct: 20),
      'cay_yaprak_biti' =>
        _teaCulturalFirstDecision(input, rule, thresholdPct: 30),
      'kok_govde_curuklugu' => _teaRootRotDecision(input, rule),
      // Portakal kuralları — TAGEM Turunçgil IPM
      'med_fruit_fly' => _medFruitFlyDecision(input, rule),
      'mealybug' => _affectedPlantDecision(input, rule,
          thresholdPct: 20,
          below:
              'Turunçgil unlubiti eşik altında. Doğal düşman varlığını gözle ve karınca kontrolüne devam et.'),
      'red_scale' => _affectedPlantDecision(input, rule,
          thresholdPct: 25,
          below:
              'Kırmızı kabuklu bit eşik altında. Kış yazlık madeni yağ programını ve doğal parazitoid takibini sürdür.'),
      'spider_mite' => _citrusSpiderMiteDecision(input, rule),
      'aphid' => _affectedPlantDecision(input, rule,
          thresholdPct: 25,
          below:
              'Yaprak biti eşik altında. Doğal düşman aktif; geniş etkili insektisitten kaçın.'),
      'phytophthora_root_rot' => _citrusRootRotDecision(input, rule),
      // Mısır kuralları
      'stem_borer' => _cornStemBorerDecision(input, rule),
      'cutworm' => _larvaeDecision(
          input,
          rule,
          threshold: 1,
          below:
              'Bozkurt eşik altında. Yabancı ot temizliği ve akşam kontrollerini sürdür.',
        ),
      'wireworm' => _larvaeDecision(
          input,
          rule,
          threshold: 4,
          below:
              'Tel kurdu sayımı eşik altında. Çıkış boşluklarını ve toprak altı larvaları izlemeye devam et.',
        ),
      'nclb' => _diseaseGenericDecision(input, rule, thresholdPct: 15),
      'fusarium_ear_rot' => _diseaseGenericDecision(input, rule,
          thresholdPct: 5, criticalAtThreshold: true),
      // Domates kuralları
      'tuta_absoluta' => _tutaAbsolutaDecision(input, rule),
      'whitefly' => _affectedPlantDecision(input, rule,
          thresholdPct: 15,
          below:
              'Beyaz sinek eşik altında. Sarı yapışkan tuzak ve biyolojik mücadele ile izlemeyi sürdür.'),
      'thrips' => _affectedPlantDecision(input, rule,
          thresholdPct: 10,
          below:
              'Trips eşik altında. Mavi yapışkan tuzak ile izlemeyi sürdür.'),
      'botrytis' => _diseaseGenericDecision(input, rule, thresholdPct: 10),
      'late_blight' => _diseaseGenericDecision(input, rule,
          thresholdPct: 5, criticalAtThreshold: true),
      'early_blight' => _diseaseGenericDecision(input, rule, thresholdPct: 15),
      _ => _below(rule, 'Eşik değerlendirmesi için yeterli kayıt yok.'),
    };
  }

  /// Tuta absoluta — feromon + bitki gözlem hibridi.
  /// Bitki başına 1+ aktif galeri eşik kapısını açar.
  static IpmDecision _tutaAbsolutaDecision(
    IpmObservationInput input,
    CropIpmRule rule,
  ) {
    final affected = input.affectedPlants;
    final sampled = input.sampledPlants;
    if (affected != null && sampled != null && sampled > 0) {
      final pct = affected / sampled * 100;
      if (pct >= 5) {
        return _chemicalAllowed(
          rule,
          'Tuta absoluta bitki eşiği aşıldı: $sampled bitkide $affected aktif galeri (%${_fmt(pct)}).',
        );
      }
    }
    final trap = input.trapAverage;
    if (trap != null && trap >= 30) {
      return IpmDecision(
        rule: rule,
        status: IpmDecisionStatus.followUp,
        headline: 'Tuzakta yoğun ergin var, bitki kontrolü yap',
        message:
            'Tuzak ortalaması ${_fmt(trap)} ergin/hafta. Bitki üzerinde aktif galeri kontrolü yap.',
        nextSteps: [
          rule.monitoringMethod,
          'Bitki başına 1+ aktif galeri görülürse kimyasal kapı açılır.',
          rule.culturalControl,
        ],
      );
    }
    return _below(
      rule,
      'Tuta absoluta için bitki eşiği doğrulanmadı. Feromon tuzak + biyolojik mücadele izlemesini sürdür.',
    );
  }

  /// Mısır kurdu — feromon + bitki gözlem hibridi.
  static IpmDecision _cornStemBorerDecision(
    IpmObservationInput input,
    CropIpmRule rule,
  ) {
    final affected = input.affectedPlants;
    final sampled = input.sampledPlants;
    if (affected != null && sampled != null && sampled > 0) {
      final pct = affected / sampled * 100;
      if (pct >= 5) {
        return _chemicalAllowed(
          rule,
          'Mısır kurdu bitki eşiği aşıldı: $sampled bitkide $affected belirti (%${_fmt(pct)}).',
        );
      }
    }
    final trap = input.trapAverage;
    if (trap != null && trap >= 10) {
      return IpmDecision(
        rule: rule,
        status: IpmDecisionStatus.followUp,
        headline: 'Tuzakta ergin var, bitki kontrolü yap',
        message:
            'Tuzak ortalaması ${_fmt(trap)} ergin. 7-10 gün içinde 100 bitkide larva/zarar gözlemi yap.',
        nextSteps: [
          rule.monitoringMethod,
          '100 bitkinin 5\'inde larva veya zarar görülürse kimyasal kapı açılır.',
          rule.culturalControl,
        ],
      );
    }
    return _below(
      rule,
      'Mısır kurdu için kimyasal eşik doğrulanmadı. Feromon ve sap kontrollerini sürdür.',
    );
  }

  /// Genel hastalık eşik değerlendirmesi — yüzde temelli.
  /// criticalAtThreshold true ise eşik üstünde "criticalNoChemical" döner
  /// (kimyasal etkisiz, kültürel önlem ve hasat yönetimi gerekir).
  static IpmDecision _diseaseGenericDecision(
    IpmObservationInput input,
    CropIpmRule rule, {
    required double thresholdPct,
    bool criticalAtThreshold = false,
  }) {
    final pct = input.diseasePercent;
    if (pct == null) {
      return _followUp(
        rule,
        'Hastalık oranını (%) kaydetmeden karar verme.',
      );
    }
    if (pct >= thresholdPct) {
      if (criticalAtThreshold) {
        return IpmDecision(
          rule: rule,
          status: IpmDecisionStatus.criticalNoChemical,
          headline: '${rule.pestName}: kritik seviye',
          message:
              'Hastalık oranı %${_fmt(pct)}. Kültürel ve hasat yönetimi öncelikli; resmi teknik destek alın.',
          nextSteps: [
            rule.culturalControl,
            'Etkilenen bitki/koçanları ayır, gıda/yem zincirinden çıkar.',
            'Resmi teknik destek almadan kimyasal uygulama kaydı açma.',
          ],
        );
      }
      return _chemicalAllowed(
        rule,
        '${rule.pestName} eşiği aşıldı: hastalık oranı %${_fmt(pct)}.',
      );
    }
    if (pct > 0) {
      return IpmDecision(
        rule: rule,
        status: IpmDecisionStatus.followUp,
        headline: '${rule.pestName}: belirti var, takip et',
        message:
            'Hastalık oranı %${_fmt(pct)}. Eşik kritik seviyede değil; izlemeye devam et.',
        nextSteps: [
          rule.monitoringMethod,
          rule.culturalControl,
          'Kimyasal kapı bu kayıtla açılmaz.',
        ],
      );
    }
    return _below(
      rule,
      '${rule.pestName} belirtisi kaydedilmedi. Kültürel önlemleri sürdür.',
    );
  }

  /// Akdeniz meyve sineği — feromon tuzak temelli, eşik aşıldığında
  /// kontrollü kimyasal kapısı açılır.
  static IpmDecision _medFruitFlyDecision(
    IpmObservationInput input,
    CropIpmRule rule,
  ) {
    final trap = input.trapAverage;
    if (trap == null) {
      return _followUp(
        rule,
        'Tuzak başına ergin sineği sayısını kaydetmeden karar verilmez.',
      );
    }
    if (trap >= 5) {
      return _chemicalAllowed(
        rule,
        'Akdeniz meyve sineği eşiği aşıldı: tuzakta ortalama ${_fmt(trap)} ergin.',
      );
    }
    if (trap > 0) {
      return IpmDecision(
        rule: rule,
        status: IpmDecisionStatus.followUp,
        headline: 'Tuzakta ergin var, takip artır',
        message:
            'Tuzak ortalaması ${_fmt(trap)} ergin. Eşik aşılmadı; haftalık tuzak kontrolüne devam et ve kalıntı meyveleri yerden topla.',
        nextSteps: [
          rule.monitoringMethod,
          rule.culturalControl,
          'Eşik aşılırsa BKÜ etiketinde belirtilen zehirli yem cezbedici uygulanır.',
        ],
      );
    }
    return _below(
      rule,
      'Tuzakta yakalanma yok. Kalıntı meyve temizliği ve tuzak takibine devam et.',
    );
  }

  /// Turunçgil kırmızı örümceği — yaprak başına akar sayısı temelli.
  static IpmDecision _citrusSpiderMiteDecision(
    IpmObservationInput input,
    CropIpmRule rule,
  ) {
    final count = input.larvaePerSquareMeter;
    if (count == null) {
      return _followUp(
        rule,
        'Yaprak başına akar sayısını kaydetmeden karar verilmez.',
      );
    }
    if (count >= 5) {
      return _chemicalAllowed(
        rule,
        'Kırmızı örümcek eşiği aşıldı: yaprak başına ${_fmt(count)} hareketli akar.',
      );
    }
    return _below(
      rule,
      'Kırmızı örümcek eşik altında. Sulama düzeni ve yaprak hijyeni ile populasyonu sınırla.',
    );
  }

  /// Portakal kök çürüklüğü — kimyasal değil, drenaj + kültürel.
  static IpmDecision _citrusRootRotDecision(
    IpmObservationInput input,
    CropIpmRule rule,
  ) {
    final affected = input.affectedPlants;
    final sampled = input.sampledPlants;
    if (affected == null || sampled == null || sampled <= 0) {
      return _followUp(
        rule,
        'Etkilenen + örneklenen ağaç sayısı kaydedilmeden karar verilmez.',
      );
    }
    final pct = affected / sampled * 100;
    if (pct >= 5) {
      return IpmDecision(
        rule: rule,
        status: IpmDecisionStatus.criticalNoChemical,
        headline: 'Phytophthora kök çürüklüğü kritik',
        message:
            'Etkilenen ağaç oranı %${_fmt(pct)}. Bu seviyede öncelik drenaj iyileştirmesi + kültürel önlem.',
        nextSteps: [
          'Drenaj kanallarını açın, etkilenen ağaçları sökün ve imha edin.',
          'Aşırı sulamadan kaçının; toprak nem profilini izleyin.',
          'Bakırlı koruyucu + ruhsatlı fungisit yalnız uzman onayı + BKÜ etiket kontrolü ile uygulanır.',
        ],
      );
    }
    return _below(
      rule,
      'Kök çürüklüğü belirtisi eşik altında. Drenaj profilini ve sulama düzenini izlemeye devam et.',
    );
  }

  /// Çayda öncelik kültürel; eşik aşılsa bile uzman onayı + BKÜ
  /// gerektiren karar yolu.
  static IpmDecision _teaCulturalFirstDecision(
    IpmObservationInput input,
    CropIpmRule rule, {
    required double thresholdPct,
  }) {
    final affected = input.affectedPlants;
    final sampled = input.sampledPlants;
    if (affected == null || sampled == null || sampled <= 0) {
      return _followUp(
        rule,
        'Örneklenen sürgün ve etkilenen sürgün sayısı kaydedilmeden karar verilmez.',
      );
    }
    final pct = affected / sampled * 100;
    if (pct >= thresholdPct) {
      return IpmDecision(
        rule: rule,
        status: IpmDecisionStatus.followUp,
        headline: '${rule.pestName}: yoğunluk artıyor',
        message:
            '${rule.pestName} yoğunluğu eşik üstünde: $sampled sürgünde $affected belirti (%${_fmt(pct)}). Çayda öncelik kültürel mücadeledir; kimyasal kararı uzman onayı + BKÜ etiket kontrolü gerektirir.',
        nextSteps: [
          rule.culturalControl,
          'Bahçenin hava akımını ve sulama düzenini değerlendir.',
          'İl/ilçe tarım müdürlüğü veya yetkili uzman ile görüş; tek başına kimyasal karar verme.',
        ],
      );
    }
    return _below(
      rule,
      '${rule.pestName} eşik altında. Doğal düşman + kültürel kontrol yeterli, izlemeye devam et.',
    );
  }

  /// Çayda kök/gövde çürüklüğü — drenaj temelli, kimyasal son çare.
  static IpmDecision _teaRootRotDecision(
    IpmObservationInput input,
    CropIpmRule rule,
  ) {
    final affected = input.affectedPlants;
    final sampled = input.sampledPlants;
    if (affected == null || sampled == null || sampled <= 0) {
      return _followUp(
        rule,
        'Etkilenen bitki sayısı + örneklenen bitki sayısı kaydedilmeden karar verilmez.',
      );
    }
    final pct = affected / sampled * 100;
    if (pct >= 5) {
      return IpmDecision(
        rule: rule,
        status: IpmDecisionStatus.criticalNoChemical,
        headline: 'Kök çürüklüğü kritik — drenaj sorunu var',
        message:
            'Etkilenen bitki oranı %${_fmt(pct)}. Çayda kök/gövde çürüklüğü kimyasal ile değil drenaj + kültürel önlemlerle çözülür.',
        nextSteps: [
          'Drenaj kanallarını aç, su göllenmesini önle.',
          'Etkilenen bitkileri sök ve imha et.',
          'Aşırı sulamadan kaçın; toprak nem profilini gözlemle.',
          'Resmi teknik destek almadan kimyasal uygulama kararı verme.',
        ],
      );
    }
    return _below(
      rule,
      'Kök/gövde çürüklüğü belirtisi eşik altında. Drenaj profilini ve sulama düzenini izlemeye devam et.',
    );
  }

  static IpmDecision _larvaeDecision(
    IpmObservationInput input,
    CropIpmRule rule, {
    required double threshold,
    required String below,
  }) {
    final count = input.larvaePerSquareMeter;
    if (count == null) {
      return _followUp(
        rule,
        'Metrekare larva sayısını kaydetmeden kimyasal kapı açılmaz.',
      );
    }
    if (count >= threshold) {
      return _chemicalAllowed(
        rule,
        '${rule.pestName} eşiği aşıldı: ${_fmt(count)} larva/m².',
      );
    }
    return _below(rule, below);
  }

  static IpmDecision _affectedPlantDecision(
    IpmObservationInput input,
    CropIpmRule rule, {
    required double thresholdPct,
    required String below,
  }) {
    final affected = input.affectedPlants;
    final sampled = input.sampledPlants;
    if (affected == null || sampled == null || sampled <= 0) {
      return _followUp(
        rule,
        'Örneklenen bitki ve belirti görülen bitki sayısı kaydedilmeden kimyasal kapı açılmaz.',
      );
    }
    final pct = affected / sampled * 100;
    if (pct >= thresholdPct) {
      return _chemicalAllowed(
        rule,
        '${rule.pestName} eşiği aşıldı: $sampled bitkide $affected belirti (%${_fmt(pct)}).',
      );
    }
    return _below(rule, below);
  }

  static IpmDecision _sunflowerMothDecision(
    IpmObservationInput input,
    CropIpmRule rule,
  ) {
    final affected = input.affectedPlants;
    final sampled = input.sampledPlants;
    if (affected != null && sampled != null && sampled > 0) {
      final pct = affected / sampled * 100;
      if (pct >= 5) {
        return _chemicalAllowed(
          rule,
          'Ayçiçeği güvesi bitki eşiği aşıldı: $sampled bitkide $affected belirti (%${_fmt(pct)}).',
        );
      }
    }

    final trap = input.trapAverage;
    if (trap != null && trap >= 10) {
      return IpmDecision(
        rule: rule,
        status: IpmDecisionStatus.followUp,
        headline: 'Tuzak artışı var, bitki kontrolü şart',
        message:
            'Tuzak ortalaması ${_fmt(trap)} ergin. Bu tek başına ilaç kararı değildir; 7-10 gün içinde 100 bitkide yumurta, larva veya ilk zarar kontrolü yap.',
        nextSteps: [
          rule.monitoringMethod,
          '100 bitkinin 5’inde yumurta, larva veya ilk zarar görülürse kimyasal kapı açılır.',
          rule.culturalControl,
        ],
      );
    }

    return _below(
      rule,
      'Ayçiçeği güvesi için kimyasal eşik doğrulanmadı. Feromon ve tabla kontrollerini sürdür.',
    );
  }

  static IpmDecision _mildewDecision(
    IpmObservationInput input,
    CropIpmRule rule,
  ) {
    final pct = input.diseasePercent;
    if (pct == null) {
      return _followUp(
        rule,
        'Hastalıklı bitki oranını (%) kaydetmeden karar verme.',
      );
    }
    if (pct > 30) {
      return IpmDecision(
        rule: rule,
        status: IpmDecisionStatus.criticalNoChemical,
        headline: 'Mildiyö kritik seviyede',
        // Mesaj çiftçiye somut adres veriyor (il/ilçe müdürlüğü, uzman) ama
        // başlangıçta "resmi teknik destek" anahtar kavramı geçiyor — hem
        // konseptin altını çiziyor hem de test bunu doğruluyor.
        message:
            'Hastalık oranı %${_fmt(pct)}. Bu seviye için resmi teknik destek şart: il/ilçe tarım müdürlüğü veya yetkili uzmanla görüş; uygulama içi ilaç kapısı açılmaz, ağır bulaşık alanda sürüm kararını birlikte değerlendir.',
        nextSteps: [
          'Hastalıklı bitkileri ve hasat sonrası artıkları imha et.',
          'Ağır bulaşık alanda uzun münavebe ve tolerant çeşit planla.',
          'Resmi teknik destek almadan kimyasal uygulama kaydı açma.',
        ],
      );
    }
    if (pct > 0) {
      return IpmDecision(
        rule: rule,
        status: IpmDecisionStatus.followUp,
        headline: 'Mildiyö belirtisi var',
        message:
            'Hastalık oranı %${_fmt(pct)}. Eşik kritik seviyede değil; belirtili ocakları işaretle, yayılımı izle ve teknik destekle doğrula.',
        nextSteps: [
          rule.monitoringMethod,
          rule.culturalControl,
          'Kimyasal kapı bu kayıtla açılmaz.',
        ],
      );
    }
    return _below(
      rule,
      'Mildiyö belirtisi kaydedilmedi. Sertifikalı tohum, tolerant çeşit ve yabancı ot kontrolüyle izlemeyi sürdür.',
    );
  }

  static IpmDecision _chemicalAllowed(CropIpmRule rule, String message) {
    return IpmDecision(
      rule: rule,
      status: IpmDecisionStatus.chemicalAllowed,
      headline: 'Eşik aşıldı, kontrollü kimyasal kapısı açık',
      message: message,
      nextSteps: [
        rule.chemicalGate,
        'Etiket bilgisi, son ilaçlama-hasat arası süre ve il/ilçe teknik önerisi esas alınır.',
        rule.culturalControl,
      ],
    );
  }

  static IpmDecision _followUp(CropIpmRule rule, String message) {
    return IpmDecision(
      rule: rule,
      status: IpmDecisionStatus.followUp,
      headline: 'Önce gözlem kaydını tamamla',
      message: message,
      nextSteps: [
        rule.monitoringMethod,
        rule.economicThreshold,
        rule.culturalControl,
      ],
    );
  }

  static IpmDecision _below(CropIpmRule rule, String message) {
    return IpmDecision(
      rule: rule,
      status: IpmDecisionStatus.belowThreshold,
      headline: 'Eşik aşılmadı',
      message: message,
      nextSteps: [
        'Kimyasal uygulama önerilmez.',
        rule.monitoringMethod,
        rule.culturalControl,
      ],
    );
  }

  static String _fmt(double value) {
    if (value == value.roundToDouble()) return value.toStringAsFixed(0);
    return value.toStringAsFixed(1);
  }
}
