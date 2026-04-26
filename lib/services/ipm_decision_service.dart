import '../data/crop_ipm_rules.dart';

class IpmDecisionService {
  IpmDecisionService._();

  static List<CropIpmRule> rulesForCrop(String? cropName) {
    if (SunflowerIpmRules.supports(cropName)) {
      return SunflowerIpmRules.rules;
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
      _ => _below(rule, 'Eşik değerlendirmesi için yeterli kayıt yok.'),
    };
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
        message:
            'Hastalık oranı %${_fmt(pct)}. Bu durumda uygulama içi ilaç kapısı açılmaz; il/ilçe müdürlüğü veya yetkili uzmanla görüş ve ağır bulaşık alanda sürüm kararını değerlendir.',
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
