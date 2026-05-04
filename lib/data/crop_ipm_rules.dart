import 'sunflower_source_refs.dart';
import 'supported_crops.dart';

enum IpmDecisionStatus {
  belowThreshold,
  followUp,
  chemicalAllowed,
  criticalNoChemical,
}

extension IpmDecisionStatusLabel on IpmDecisionStatus {
  String get label => switch (this) {
        IpmDecisionStatus.belowThreshold => 'Eşik altında',
        IpmDecisionStatus.followUp => 'Takip gerekli',
        IpmDecisionStatus.chemicalAllowed => 'Eşik aşıldı',
        IpmDecisionStatus.criticalNoChemical => 'Kritik uyarı',
      };
}

class CropIpmRule {
  final String cropKey;
  final String pestKey;
  final String pestName;
  final String type;
  final String observationWindow;
  final String symptoms;
  final String monitoringMethod;
  final String economicThreshold;
  final String culturalControl;
  final String chemicalGate;
  final List<String> sourceRefs;

  const CropIpmRule({
    required this.cropKey,
    required this.pestKey,
    required this.pestName,
    required this.type,
    required this.observationWindow,
    required this.symptoms,
    required this.monitoringMethod,
    required this.economicThreshold,
    required this.culturalControl,
    required this.chemicalGate,
    this.sourceRefs = const [],
  });

  Map<String, dynamic> toJson() => {
        'cropKey': cropKey,
        'pestKey': pestKey,
        'pestName': pestName,
        'type': type,
        'observationWindow': observationWindow,
        'symptoms': symptoms,
        'monitoringMethod': monitoringMethod,
        'economicThreshold': economicThreshold,
        'culturalControl': culturalControl,
        'chemicalGate': chemicalGate,
        'sourceRefs': sourceRefs,
      };
}

class IpmObservationInput {
  final String cropName;
  final String pestKey;
  final int? sampledPlants;
  final int? affectedPlants;
  final double? larvaePerSquareMeter;
  final double? trapAverage;
  final double? diseasePercent;

  const IpmObservationInput({
    required this.cropName,
    required this.pestKey,
    this.sampledPlants,
    this.affectedPlants,
    this.larvaePerSquareMeter,
    this.trapAverage,
    this.diseasePercent,
  });

  Map<String, dynamic> toJson() => {
        'crop_name': cropName,
        'pest_key': pestKey,
        if (sampledPlants != null) 'sampled_plants': sampledPlants,
        if (affectedPlants != null) 'affected_plants': affectedPlants,
        if (larvaePerSquareMeter != null)
          'larvae_per_square_meter': larvaePerSquareMeter,
        if (trapAverage != null) 'trap_average': trapAverage,
        if (diseasePercent != null) 'disease_percent': diseasePercent,
      };
}

class IpmDecision {
  final CropIpmRule rule;
  final IpmDecisionStatus status;
  final String headline;
  final String message;
  final List<String> nextSteps;

  const IpmDecision({
    required this.rule,
    required this.status,
    required this.headline,
    required this.message,
    required this.nextSteps,
  });

  bool get allowsChemical => status == IpmDecisionStatus.chemicalAllowed;

  Map<String, dynamic> toJson() => {
        'pest_key': rule.pestKey,
        'pest_name': rule.pestName,
        'status': status.name,
        'status_label': status.label,
        'allows_chemical': allowsChemical,
        'headline': headline,
        'message': message,
        'next_steps': nextSteps,
        'threshold': rule.economicThreshold,
        'monitoring_method': rule.monitoringMethod,
        'chemical_gate': rule.chemicalGate,
      };
}

class IpmScoutingWindow {
  final int dayOffset;
  final List<String> pestKeys;
  final String title;

  const IpmScoutingWindow({
    required this.dayOffset,
    required this.pestKeys,
    required this.title,
  });
}

class SunflowerIpmRules {
  SunflowerIpmRules._();

  static const sourceRefs = [
    SunflowerSources.tagemIpm2022,
    SunflowerSources.bkuDatabase,
  ];
  static const meadowMothSourceRefs = [
    SunflowerSources.tagemIpm2022,
    SunflowerSources.meadowMothInstruction,
    SunflowerSources.bkuDatabase,
  ];
  static const cropKey = 'aycicegi';

  static const rules = <CropIpmRule>[
    CropIpmRule(
      cropKey: cropKey,
      pestKey: 'bozkurt',
      pestName: 'Bozkurt',
      type: 'Zararlı',
      observationWindow: '2 gerçek yapraklı dönem',
      symptoms: 'Genç bitkiler kök boğazından kesilir veya kemirilir.',
      monitoringMethod:
          'Bitkiler bozkurt larvası tarafından kesilmiş mi kontrol edilir; metrekare larva sayısı kaydedilir.',
      economicThreshold: 'Metrekarede 1-3 larva',
      culturalControl:
          'Sonbahar sürümü ve ilkbahar başından itibaren yabancı ot temizliği önceliklidir.',
      chemicalGate:
          'Eşik aşılmadan kimyasal önerilmez; eşik aşılırsa etiket ve il/ilçe teknik önerisi esas alınır.',
      sourceRefs: sourceRefs,
    ),
    CropIpmRule(
      cropKey: cropKey,
      pestKey: 'yesilkurt',
      pestName: 'Yeşilkurt',
      type: 'Zararlı',
      observationWindow: 'Vejetatif dönem sonu / R1 başlangıcı',
      symptoms: 'Yapraklarda damar kalacak şekilde yenik ve tablada zarar.',
      monitoringMethod:
          'Feromon takibi sonrası zikzak yürüyüşle 100 bitkide yumurta, birinci dönem larva veya ilk zarar belirtisi sayılır.',
      economicThreshold:
          '100 bitkinin 5’inde yumurta, birinci dönem larva veya ilk zarar belirtisi',
      culturalControl:
          'Baharda iyi toprak işleme ile kışlayan pupalar azaltılır.',
      chemicalGate:
          'Yalnız eşik doğrulanırsa kontrollü kimyasal kapısı açılır.',
      sourceRefs: sourceRefs,
    ),
    CropIpmRule(
      cropKey: cropKey,
      pestKey: 'cayir_tirtili',
      pestName: 'Çayır tırtılı',
      type: 'Zararlı',
      observationWindow: 'Vejetatif gelişme dönemi',
      symptoms:
          'Larvalar yaprak, tomurcuk ve çiçekleri yer; yoğunlukta yeşil aksam hızla kaybolur.',
      monitoringMethod:
          'Bitkiler gözle kontrol edilir ve metrekare larva yoğunluğu kaydedilir.',
      economicThreshold: 'Metrekarede 10 larva',
      culturalControl:
          'Mücadele gerekirse en geç üçüncü dönem larvalara karşı planlanır; erken gözlem esastır.',
      chemicalGate:
          'Eşik altında kimyasal yok; eşik aşılırsa etiket ve teknik öneri ile ilerlenir.',
      sourceRefs: meadowMothSourceRefs,
    ),
    CropIpmRule(
      cropKey: cropKey,
      pestKey: 'aycicegi_guvesi',
      pestName: 'Ayçiçeği güvesi',
      type: 'Zararlı',
      observationWindow: 'Çiçeklenme başlangıcından itibaren',
      symptoms: 'Larvalar polen, taç yaprak ve tablada tohumlara zarar verir.',
      monitoringMethod:
          'Tarla kenarı ve merkezde feromon tuzağı izlenir; ayrıca 100 tablaya yakın bitkide yumurta, larva ve ilk zarar aranır.',
      economicThreshold:
          'Tuzak başına ortalama 10+ ergin sonrası 7-10 gün takip; 100 bitkinin 5’inde yumurta, larva veya ilk zarar',
      culturalControl:
          'Ekim öncesi derin sürüm ve Asteraceae yabancı ot temizliği önceliklidir.',
      chemicalGate:
          'Sadece tuzak artışı kimyasal için yeterli değildir; bitki kontrolünde eşik doğrulanmalıdır.',
      sourceRefs: sourceRefs,
    ),
    CropIpmRule(
      cropKey: cropKey,
      pestKey: 'telkurtlari',
      pestName: 'Telkurtları',
      type: 'Zararlı',
      observationWindow: '2 gerçek yapraklı dönemden itibaren',
      symptoms:
          'Larvalar köklerde ve toprak altı bitki kısımlarında beslenir; yeni çıkan bitkiler ölebilir.',
      monitoringMethod:
          'Köşegen yürüyüşle en az 12 noktada 1/4 m² çerçeve ve 20 cm toprak kontrolü yapılır.',
      economicThreshold: 'Metrekarede en az 6 larva',
      culturalControl:
          'Geçmiş bulaşık tarlada münavebe, yabancı ot temizliği ve şubat-mart sürümü uygulanır.',
      chemicalGate:
          'Eşik aşılmadan kimyasal önerilmez; geçmiş yoğun bulaşıklık resmi teknik destekle değerlendirilir.',
      sourceRefs: sourceRefs,
    ),
    CropIpmRule(
      cropKey: cropKey,
      pestKey: 'mildiyo',
      pestName: 'Ayçiçeği mildiyösü',
      type: 'Hastalık',
      observationWindow: '2 gerçek yapraklı dönemden itibaren',
      symptoms:
          'Bodurlaşma, rozetleşme, damar boyunca sararma ve nemli havada yaprak altında beyaz fungal örtü.',
      monitoringMethod:
          'Köşegen veya zikzak yürüyüşle enfeksiyon belirtileri aranır; hastalıklı bitki oranı kaydedilir.',
      economicThreshold:
          'İki yapraklı dönemde hastalık oranı %30’un üzerine çıkarsa kritik uyarı',
      culturalControl:
          'Sertifikalı ilaçlı tohum, tolerant çeşit, yabancı ot savaşı, hastalıklı bitki ve artıkların imhası, ağır bulaşık alanda uzun münavebe.',
      chemicalGate:
          'Yeşil aksam ilaç kapısı açılmaz; %30 üstünde resmi teknik destek ve tarla sürümü uyarısı verilir.',
      sourceRefs: sourceRefs,
    ),
  ];

  static const scoutingWindows = <IpmScoutingWindow>[
    IpmScoutingWindow(
      dayOffset: 14,
      pestKeys: ['bozkurt', 'telkurtlari', 'mildiyo'],
      title: 'Çıkış sonrası erken gözlem',
    ),
    IpmScoutingWindow(
      dayOffset: 50,
      pestKeys: ['yesilkurt', 'cayir_tirtili'],
      title: 'Vejetatif dönem zararlı gözlemi',
    ),
    IpmScoutingWindow(
      dayOffset: 75,
      pestKeys: ['aycicegi_guvesi', 'mildiyo'],
      title: 'Çiçeklenme dönemi tabla ve hastalık gözlemi',
    ),
  ];

  static bool supports(String? cropName) {
    final canonical = SupportedCrops.canonicalName(cropName);
    return SupportedCrops.normalize(canonical ?? '') == cropKey;
  }

  static CropIpmRule? byKey(String pestKey) {
    for (final rule in rules) {
      if (rule.pestKey == pestKey) return rule;
    }
    return null;
  }
}
