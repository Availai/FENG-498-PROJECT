import 'sunflower_source_refs.dart';
import 'supported_crops.dart';
import 'tea_source_refs.dart';
import 'orange_source_refs.dart';
import 'corn_source_refs.dart';
import 'tomato_source_refs.dart';

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

/// Çay (Camellia sinensis) IPM kuralları — ÇAYKUR materyallerine göre
/// Türkiye çay plantasyonlarında ekonomik düzeyde hastalık/zararlı
/// tespit edilmemiştir. Aşağıdaki kayıtlar gözlem ve takip içindir;
/// kimyasal kapısı yalnız uzman onayı + BKÜ etiket kontrolü ile açılır.
class TeaIpmRules {
  TeaIpmRules._();

  static const sourceRefs = [
    TeaSources.caykurAgronomy,
    TeaSources.bkuDatabase,
  ];
  static const cropKey = 'cay';

  static const rules = <CropIpmRule>[
    CropIpmRule(
      cropKey: cropKey,
      pestKey: 'cay_kosnili',
      pestName: 'Çay koşnili',
      type: 'Zararlı',
      observationWindow: 'Mart-Ekim arası vejetatif dönem',
      symptoms:
          'Dal ve gövdede kahverengi kabuğa benzer örtü; bitki zayıflar, sürgün gelişimi yavaşlar.',
      monitoringMethod:
          'Dal ve gövdede kabuk benzeri zararlı varlığı kontrol edilir; yoğun olan ocaklar işaretlenir.',
      economicThreshold:
          'Ekonomik düzeyde nadir; yoğun bulaşıklı dal oranı kayıt altına alınır.',
      culturalControl:
          'Enfekte dalların temizliği ve bahçe içi hava akımının iyileştirilmesi önceliklidir; doğal düşmanlar genellikle yeterlidir.',
      chemicalGate:
          'Eşik aşılırsa yalnız uzman onayı ve BKÜ etiketi ile mücadele kararı verilir; öncelik kültürel.',
      sourceRefs: sourceRefs,
    ),
    CropIpmRule(
      cropKey: cropKey,
      pestKey: 'cay_akari',
      pestName: 'Çay akarı',
      type: 'Zararlı',
      observationWindow: 'Sıcak ve kuru dönemler (Temmuz-Ağustos)',
      symptoms:
          'Yaprakların alt yüzünde noktasal sararma, gümüşi-bronz renk değişimi; yoğun zarar sürgün kayıplarına yol açar.',
      monitoringMethod:
          'Sürgün uçlarındaki körpe yaprakların alt yüzü gözle ve büyüteçle kontrol edilir; etkilenen sürgün oranı kaydedilir.',
      economicThreshold:
          'Sürgünlerin %20\'sinde noktasal lekeleşme görülmesi takip kapısı açar.',
      culturalControl:
          'Yaprak hijyeni, dengeli sulama ve dengeli azot kullanımı akar populasyonunu sınırlar.',
      chemicalGate:
          'Yoğun zarar belirtisi varsa uzman onayı + BKÜ etiket kontrolü ile karar verilir; öncelik kültürel.',
      sourceRefs: sourceRefs,
    ),
    CropIpmRule(
      cropKey: cropKey,
      pestKey: 'cay_yaprak_biti',
      pestName: 'Çayda yaprak biti',
      type: 'Zararlı',
      observationWindow: 'İlkbahar erken sürgün dönemi (Nisan-Mayıs)',
      symptoms:
          'Yeni sürgünlerin uç yapraklarında küçük yeşil/siyah böcekler; yaprak kıvrılması ve bal özü yapışıklığı.',
      monitoringMethod:
          'Yeni sürgün uçlarında 50-100 bitki gözle kontrol edilir; bulaşık sürgün oranı kaydedilir.',
      economicThreshold:
          'Sürgün uçlarının %30\'unda yaprak biti yoğunluğu takip kapısı açar; daha düşük yoğunlukta doğal düşmanlar yeterlidir.',
      culturalControl:
          'Uğur böceği gibi doğal düşmanları koruyun; geniş etkili insektisitten kaçının.',
      chemicalGate:
          'Yoğun bulaşma + verim kaybı riski varsa uzman onayı + BKÜ etiket kontrolü gerekir.',
      sourceRefs: sourceRefs,
    ),
    CropIpmRule(
      cropKey: cropKey,
      pestKey: 'kok_govde_curuklugu',
      pestName: 'Kök ve gövde çürüklüğü',
      type: 'Hastalık',
      observationWindow: 'Drenaj zayıf bahçelerde, yaz sonu-sonbahar başı',
      symptoms:
          'Bitki tepe yapraklarında sararma + solma; gövde tabanında siyah/kahverengi çürük doku.',
      monitoringMethod:
          'Etkilenen bitki ocaklarının dağılımı haritalanır; drenaj profili kontrol edilir.',
      economicThreshold:
          'Etkilenen bitki sayısı %5\'i geçerse kritik uyarı; uzmana danışın.',
      culturalControl:
          'Drenaj kanallarını açın, etkilenen bitkileri imha edin, aşırı sulama yapmayın.',
      chemicalGate:
          'Bu hastalıkta öncelik drenaj + kültürel; kimyasal mücadele uzman onayı + BKÜ etiket kontrolü gerektirir.',
      sourceRefs: sourceRefs,
    ),
  ];

  static const scoutingWindows = <IpmScoutingWindow>[
    IpmScoutingWindow(
      dayOffset: 60,
      pestKeys: ['cay_yaprak_biti'],
      title: 'İlkbahar erken sürgün gözlemi',
    ),
    IpmScoutingWindow(
      dayOffset: 180,
      pestKeys: ['cay_akari', 'cay_kosnili'],
      title: 'Yaz dönemi zararlı gözlemi',
    ),
    IpmScoutingWindow(
      dayOffset: 270,
      pestKeys: ['kok_govde_curuklugu'],
      title: 'Sonbahar drenaj ve kök gözlemi',
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

/// Portakal (Citrus sinensis) IPM kuralları — TAGEM Turunçgil Entegre
/// Mücadele Teknik Talimatı temelli. Akdeniz meyve sineği zararlılar
/// arasında en kritik konudur; feromon izleme şart.
class OrangeIpmRules {
  OrangeIpmRules._();

  static const sourceRefs = [
    OrangeSources.tagemCitrusIpm,
    OrangeSources.zmmaeFruitGuide,
    OrangeSources.bkuDatabase,
  ];
  static const cropKey = 'portakal';

  static const rules = <CropIpmRule>[
    CropIpmRule(
      cropKey: cropKey,
      pestKey: 'med_fruit_fly',
      pestName: 'Akdeniz meyve sineği',
      type: 'Zararlı',
      observationWindow: 'Meyve renk dönüşümünden hasada (Eylül-Aralık)',
      symptoms:
          'Olgunlaşan meyvede iğne deliği büyüklüğünde yumurta bırakma izleri; içte larva tüneli ve çürüme.',
      monitoringMethod:
          'Bahçeye sarı yapışkan + feromon (Trimedlure) tuzakları asılır; tuzakta haftalık ergin sayımı kaydedilir.',
      economicThreshold:
          'Tuzak başına haftada 5+ ergin sineği sonrası hızlı eylem; düzenli yakalanma kimyasal kapıyı açar.',
      culturalControl:
          'Hasat sonrası kalıntı meyveleri toplayıp imha edin; düşen meyveleri yerde bırakmayın.',
      chemicalGate:
          'Eşik aşıldığında ruhsatlı zehirli yem cezbedici (Spinosad gibi) uygulanır; BKÜ etiket + PHI ve uzman önerisi şart.',
      sourceRefs: sourceRefs,
    ),
    CropIpmRule(
      cropKey: cropKey,
      pestKey: 'mealybug',
      pestName: 'Turunçgil unlubiti',
      type: 'Zararlı',
      observationWindow: 'İlkbahar-yaz vejetatif dönem',
      symptoms:
          'Dal, yaprak ve meyve saplarında beyaz pamuksu örtü; bal özü yapışıklığı ve ardından siyah is fumajini.',
      monitoringMethod:
          'Bahçenin köşegen yürüyüşle 50-100 ağacı kontrol edilir; bulaşık dal/yaprak sayısı kaydedilir.',
      economicThreshold:
          'Bulaşık ağaç oranı %15-20 üstünde takip kapısı açar; doğal düşman varlığı da gözlenir.',
      culturalControl:
          'Bahçe içi hava akımı için budama; karıncaları kontrol et (unlubit-karınca simbiyozu).',
      chemicalGate:
          'Yazlık madeni yağ (mineral oil) ana seçenek; 25 °C üstünde uygulamayın. BKÜ etiket kontrolü ile karar verilir.',
      sourceRefs: sourceRefs,
    ),
    CropIpmRule(
      cropKey: cropKey,
      pestKey: 'red_scale',
      pestName: 'Kırmızı kabuklu bit',
      type: 'Zararlı',
      observationWindow: 'Tüm yıl, özellikle kış-erken ilkbahar',
      symptoms:
          'Dal, yaprak ve meyve yüzeyinde küçük kırmızı/kahverengi kabuklar; yoğun bulaşma yapraklarda sararma.',
      monitoringMethod:
          'Bahçeye sarı yapışkan tuzaklar; yaprakta görsel bulaşıklık sınıfı kaydedilir.',
      economicThreshold:
          'Yaprakta orta-yoğun bulaşıklık sınıfı takip kapısı açar; doğal parazitoid varlığı da değerlendirilir.',
      culturalControl:
          'Doğal düşmanları (Aphytis spp.) korumak için geniş etkili insektisitten kaçının.',
      chemicalGate:
          'Kış uygulaması olarak yazlık madeni yağ önceliklidir; BKÜ etiket kontrolü + uzman önerisi gerekir.',
      sourceRefs: sourceRefs,
    ),
    CropIpmRule(
      cropKey: cropKey,
      pestKey: 'spider_mite',
      pestName: 'Turunçgil kırmızı örümceği',
      type: 'Zararlı',
      observationWindow: 'Yaz dönemi (Haziran-Eylül)',
      symptoms:
          'Yaprak yüzeyinde gümüşi-bronz lekeleşme; yoğun zarar yaprak dökümüne yol açar.',
      monitoringMethod:
          'Yaprak alt yüzü büyüteçle kontrol edilir; metrekare/yaprak başına akar sayısı kaydedilir.',
      economicThreshold:
          'Yaprak başına 5-10 hareketli akar genelde eşik; uzman ile doğrulanır.',
      culturalControl:
          'Düzenli sulama + yaprak yıkama populasyonu sınırlar; toz birikimini önleyin.',
      chemicalGate:
          'Yoğun zarar varsa BKÜ etiket kontrolü + uzman önerisi ile akarisit uygulanır; doğal düşmanları koruyun.',
      sourceRefs: sourceRefs,
    ),
    CropIpmRule(
      cropKey: cropKey,
      pestKey: 'aphid',
      pestName: 'Yaprak bitleri',
      type: 'Zararlı',
      observationWindow: 'İlkbahar yeni sürgün dönemi',
      symptoms:
          'Yeni sürgün uçlarında yeşil/siyah böcekler; yaprak kıvrılması ve bal özü.',
      monitoringMethod:
          'Sürgün uçları gözle kontrol edilir; bulaşık sürgün oranı kaydedilir.',
      economicThreshold:
          'Bulaşık sürgün oranı %20-30 üstünde takip kapısı açar; doğal düşman da değerlendirilir.',
      culturalControl:
          'Uğur böceği gibi doğal düşmanları koruyun; geniş etkili insektisitten kaçının.',
      chemicalGate:
          'Yoğun zarar + verim kaybı varsa BKÜ etiket kontrolü + uzman önerisi gerekir.',
      sourceRefs: sourceRefs,
    ),
    CropIpmRule(
      cropKey: cropKey,
      pestKey: 'phytophthora_root_rot',
      pestName: 'Kök çürüklüğü (Phytophthora)',
      type: 'Hastalık',
      observationWindow: 'Drenaj zayıf bahçelerde, yaz sonu-sonbahar',
      symptoms:
          'Bitki tepe yapraklarında sararma + solma; gövde tabanında zamklanma ve çürüme.',
      monitoringMethod:
          'Etkilenen ağaçların dağılımı haritalanır; drenaj profili ve sulama düzeni kontrol edilir.',
      economicThreshold:
          'Bahçede etkilenen ağaç oranı %5\'i geçerse kritik uyarı.',
      culturalControl:
          'Drenaj kanallarını açın, etkilenen ağaçları sökün ve imha edin, aşırı sulamayı önleyin.',
      chemicalGate:
          'Bakırlı koruyucu + ruhsatlı fungisit yalnız uzman önerisi + BKÜ etiket kontrolü ile uygulanır.',
      sourceRefs: sourceRefs,
    ),
  ];

  static const scoutingWindows = <IpmScoutingWindow>[
    IpmScoutingWindow(
      dayOffset: 30,
      pestKeys: ['red_scale'],
      title: 'Kış erken ilkbahar kabuk böceği gözlemi',
    ),
    IpmScoutingWindow(
      dayOffset: 90,
      pestKeys: ['aphid'],
      title: 'İlkbahar yeni sürgün gözlemi',
    ),
    IpmScoutingWindow(
      dayOffset: 180,
      pestKeys: ['mealybug', 'spider_mite'],
      title: 'Yaz dönemi zararlı gözlemi',
    ),
    IpmScoutingWindow(
      dayOffset: 270,
      pestKeys: ['med_fruit_fly', 'phytophthora_root_rot'],
      title: 'Hasat öncesi izleme ve drenaj kontrolü',
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

/// Mısır (Zea mays) IPM kuralları — TAGEM Mısır Entegre Mücadele
/// Teknik Talimatı temelli. Koçan/sap kurdu ve tel kurtları öncelikli.
class CornIpmRules {
  CornIpmRules._();

  static const sourceRefs = [
    CornSources.tagemCornIpm,
    CornSources.bkuDatabase,
  ];
  static const cropKey = 'misir';

  static const rules = <CropIpmRule>[
    CropIpmRule(
      cropKey: cropKey,
      pestKey: 'stem_borer',
      pestName: 'Mısır kurdu (Ostrinia / Sesamia)',
      type: 'Zararlı',
      observationWindow: 'Pürşel öncesi (V8) ve dane dolumu (Temmuz-Ağustos)',
      symptoms:
          'Gövde içinde larva tüneli, gövde kırılması; koçan dibinde girişler ve dane çürümesi.',
      monitoringMethod:
          'Feromon tuzaklarla ergin sayımı; bitki ucuna doğru sap içi gözlemlenir, bulaşık bitki oranı kaydedilir.',
      economicThreshold:
          '100 bitkide 5+ bitkide larva veya zarar belirtisi kimyasal kapıyı açar.',
      culturalControl:
          'Hasat sonrası sap parçalama + derin sürüm kışlayan larvaları azaltır; erken çeşit + erken ekim popülasyonu azaltır.',
      chemicalGate:
          'Eşik aşılırsa BKÜ etiketinde ruhsatlı piretroid grubu insektisit; uzman önerisi + PHI kontrolü şart.',
      sourceRefs: sourceRefs,
    ),
    CropIpmRule(
      cropKey: cropKey,
      pestKey: 'cutworm',
      pestName: 'Bozkurt',
      type: 'Zararlı',
      observationWindow: 'Çıkış sonrası - vejetatif erken dönem',
      symptoms:
          'Genç bitkiler kök boğazından kesilir veya kemirilir; sabah saatlerinde kesilmiş bitkiler.',
      monitoringMethod:
          'Tarla içi gözlemle kesilmiş bitki sayısı kaydedilir; metrekare larva sayısı kontrol edilir.',
      economicThreshold:
          'Metrekarede 1-3 larva veya sıra başına 1+ kesilmiş bitki eşik kapısını açar.',
      culturalControl:
          'Sonbahar sürümü + ilkbahar başında yabancı ot temizliği önceliklidir.',
      chemicalGate:
          'Eşik aşılırsa BKÜ etiketinde ruhsatlı insektisit; uzman önerisi + PHI kontrolü şart.',
      sourceRefs: sourceRefs,
    ),
    CropIpmRule(
      cropKey: cropKey,
      pestKey: 'wireworm',
      pestName: 'Tel kurtları (Elateridae)',
      type: 'Zararlı',
      observationWindow: 'Ekim - çıkış dönemi',
      symptoms:
          'Toprak altı larva fideleri keser; çıkışta düzensiz boşluklar görülür.',
      monitoringMethod:
          'Köşegen yürüyüşle 12+ noktada 1/4 m² çerçeve ve 20 cm derinlikte toprak kontrolü yapılır.',
      economicThreshold: 'Metrekarede 4-6 larva eşik kapısını açar.',
      culturalControl:
          'Geçmiş bulaşık tarlada münavebe + Şubat-Mart sürümü; yabancı ot temizliği popülasyonu azaltır.',
      chemicalGate:
          'Eşik aşılırsa tohum kaplama veya toprak insektisidi düşünülür; BKÜ etiket + uzman önerisi şart.',
      sourceRefs: sourceRefs,
    ),
    CropIpmRule(
      cropKey: cropKey,
      pestKey: 'aphid',
      pestName: 'Mısır yaprak biti',
      type: 'Zararlı',
      observationWindow: 'Vejetatif - pürşel dönemi',
      symptoms:
          'Yaprak alt yüzünde kolonyel beslenme; bal özü + virüs taşıyıcılığı (sarı cüceleşme).',
      monitoringMethod:
          'Yaprak alt yüzü gözle kontrol edilir; bulaşık yaprak ve doğal düşman varlığı kaydedilir.',
      economicThreshold:
          'Bulaşık yaprak oranı %25 üstünde + doğal düşman yetersizliği takip kapısı açar.',
      culturalControl:
          'Doğal düşmanları (uğur böceği) koruyun; geniş etkili insektisitten kaçının.',
      chemicalGate:
          'Yoğun bulaşma + virüs riski varsa BKÜ etiket + uzman önerisi ile karar verilir.',
      sourceRefs: sourceRefs,
    ),
    CropIpmRule(
      cropKey: cropKey,
      pestKey: 'nclb',
      pestName: 'Kuzey yaprak yanıklığı (NCLB)',
      type: 'Hastalık',
      observationWindow: 'Vejetatif sonrası, nem yüksek dönemler',
      symptoms:
          'Yaprakta puro şekli gri-kahverengi lekeler; yoğun bulaşmada yaprak ölümü.',
      monitoringMethod: 'Köşegen yürüyüşle hastalıklı yaprak oranı kaydedilir.',
      economicThreshold:
          'Hastalık oranı %15-20 üstünde fungisit değerlendirme kapısı açar.',
      culturalControl:
          'Direnç gösteren çeşit, münavebe, hasat sonrası sap parçalama.',
      chemicalGate:
          'Yoğun bulaşmada BKÜ etiket + uzman önerisi ile fungisit uygulanabilir.',
      sourceRefs: sourceRefs,
    ),
    CropIpmRule(
      cropKey: cropKey,
      pestKey: 'fusarium_ear_rot',
      pestName: 'Fusarium koçan çürüklüğü',
      type: 'Hastalık',
      observationWindow: 'Dane dolumu - hasat öncesi',
      symptoms:
          'Koçanda beyaz-pembe küf, dane çürümesi. Mikotoksin riski (gıda/yem güvenliği).',
      monitoringMethod:
          'Hasat öncesi koçan açma kontrolleri; bulaşık koçan oranı kaydedilir.',
      economicThreshold:
          'Bulaşık koçan oranı %5 üstünde mikotoksin risk uyarısı verilir.',
      culturalControl:
          'Erken hasat (uygun nem), iyi havalandırma, böcek zararı kontrolü (Fusarium giriş kapısı).',
      chemicalGate:
          'Hasat sonrası kuru depolama + ayrı saklama; kimyasal tedavi etkili değil.',
      sourceRefs: sourceRefs,
    ),
  ];

  static const scoutingWindows = <IpmScoutingWindow>[
    IpmScoutingWindow(
      dayOffset: 14,
      pestKeys: ['cutworm', 'wireworm'],
      title: 'Çıkış sonrası erken gözlem',
    ),
    IpmScoutingWindow(
      dayOffset: 50,
      pestKeys: ['aphid', 'stem_borer'],
      title: 'Vejetatif dönem zararlı gözlemi',
    ),
    IpmScoutingWindow(
      dayOffset: 75,
      pestKeys: ['stem_borer', 'nclb'],
      title: 'Pürşel öncesi izleme',
    ),
    IpmScoutingWindow(
      dayOffset: 110,
      pestKeys: ['fusarium_ear_rot'],
      title: 'Dane dolumu koçan kontrolü',
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

/// Domates (Solanum lycopersicum) IPM kuralları — TAGEM Açık Alan ve
/// Örtüaltı Domates Entegre Mücadele Teknik Talimatları temelli.
/// Tuta absoluta + Botrytis öncelikli.
class TomatoIpmRules {
  TomatoIpmRules._();

  static const sourceRefs = [
    TomatoSources.tagemOpenFieldIpm,
    TomatoSources.tagemGreenhouseIpm,
    TomatoSources.bkuDatabase,
  ];
  static const cropKey = 'domates';

  static const rules = <CropIpmRule>[
    CropIpmRule(
      cropKey: cropKey,
      pestKey: 'tuta_absoluta',
      pestName: 'Tuta absoluta (Domates güvesi)',
      type: 'Zararlı',
      observationWindow: 'Fide şaşırtmadan hasat sonuna kadar',
      symptoms:
          'Yaprakta gümüşi galeri tüneli; meyvede giriş deliği + iç çürüme; yoğun bulaşmada bitki yapraksız kalır.',
      monitoringMethod:
          'Feromon tuzaklarla haftalık ergin sayımı; bitki üzerinde yaprak ve meyve gözlemi yapılır.',
      economicThreshold:
          'Tuzak başına haftada 30+ ergin sonrası bitki kontrolü; bitki başına 1+ aktif galeri kimyasal kapıyı açar.',
      culturalControl:
          'Feromon tuzakla kütle yakalama + biyolojik mücadele (Bt, Nesidiocoris tenuis predatör) öncelikli; sera giriş ağı + bitki artıklarının imhası.',
      chemicalGate:
          'Eşik aşıldığında BKÜ etiketinde ruhsatlı ve PHI uygun ürün; uzman önerisi + direnç yönetimi için aktif madde rotasyonu şart.',
      sourceRefs: [
        TomatoSources.tutaAbsoluta,
        TomatoSources.bkuDatabase,
      ],
    ),
    CropIpmRule(
      cropKey: cropKey,
      pestKey: 'whitefly',
      pestName: 'Beyaz sinek',
      type: 'Zararlı',
      observationWindow: 'Tüm sezon, özellikle sera',
      symptoms:
          'Yaprak alt yüzünde beyaz erginler ve nimfler; bal özü + is fumajini; sarı kıvrılma virüsü (TYLCV) taşıyıcılığı.',
      monitoringMethod:
          'Sarı yapışkan tuzakla haftalık ergin sayımı; yaprak başına nimf sayısı kontrol edilir.',
      economicThreshold:
          'Yaprak başına 5+ nimf veya tuzakta yüksek ergin yoğunluğu kimyasal kapıyı açar.',
      culturalControl:
          'Sera girişinde böcek koruyucu ağ + biyolojik mücadele (Encarsia formosa); yabancı ot temizliği.',
      chemicalGate:
          'Eşik aşılırsa BKÜ etiket + uzman önerisi şart; doğal düşmanlara zarar vermeyen aktif madde tercih edilir.',
      sourceRefs: sourceRefs,
    ),
    CropIpmRule(
      cropKey: cropKey,
      pestKey: 'aphid',
      pestName: 'Yaprak biti',
      type: 'Zararlı',
      observationWindow: 'İlkbahar-yaz vejetatif dönem',
      symptoms:
          'Yeni sürgün uçlarında yeşil/siyah böcekler; yaprak kıvrılması, virüs taşıyıcılığı (CMV).',
      monitoringMethod:
          'Sürgün uçları gözle kontrol edilir; bulaşık sürgün oranı kaydedilir.',
      economicThreshold:
          'Bulaşık sürgün oranı %25 üstünde + doğal düşman yetersizliği takip kapısı açar.',
      culturalControl:
          'Doğal düşmanları (uğur böceği, parazitoid) koruyun; geniş etkili insektisitten kaçının.',
      chemicalGate:
          'Yoğun bulaşma + virüs riski varsa BKÜ etiket + uzman önerisi şart.',
      sourceRefs: sourceRefs,
    ),
    CropIpmRule(
      cropKey: cropKey,
      pestKey: 'spider_mite',
      pestName: 'Kırmızı örümcek',
      type: 'Zararlı',
      observationWindow: 'Sıcak/kuru dönemler',
      symptoms:
          'Yaprak alt yüzünde noktasal sararma + gümüşi lekeleşme; yoğun zarar yaprak kuruması.',
      monitoringMethod:
          'Yaprak alt yüzü büyüteçle kontrol edilir; yaprak başına akar sayısı kaydedilir.',
      economicThreshold:
          'Yaprak başına 5-10 hareketli akar genelde eşik; uzman ile doğrulanır.',
      culturalControl: 'Yaprak yıkama + nem dengeleme; toz birikimini önleyin.',
      chemicalGate:
          'Yoğun zarar varsa BKÜ etiket + uzman önerisi ile akarisit; doğal düşman koruyun.',
      sourceRefs: sourceRefs,
    ),
    CropIpmRule(
      cropKey: cropKey,
      pestKey: 'thrips',
      pestName: 'Trips',
      type: 'Zararlı',
      observationWindow: 'Çiçeklenme + meyve oluşum dönemi',
      symptoms:
          'Yaprak ve meyvede gümüşi lekeleşme + siyah nokta gübre; TSWV virüs taşıyıcısı.',
      monitoringMethod:
          'Mavi yapışkan tuzakla izleme; çiçek/yaprak sallama testi ile birey sayımı.',
      economicThreshold:
          'Çiçek başına 1+ birey veya tuzak yoğunluğu eşik kapısını açar.',
      culturalControl:
          'Yabancı ot temizliği + biyolojik mücadele (Orius spp.).',
      chemicalGate:
          'Yoğun zarar varsa BKÜ etiket + uzman önerisi; doğal düşman koruyun.',
      sourceRefs: sourceRefs,
    ),
    CropIpmRule(
      cropKey: cropKey,
      pestKey: 'botrytis',
      pestName: 'Botrytis (Kurşuni küf)',
      type: 'Hastalık',
      observationWindow: 'Sera + yüksek nem dönemler',
      symptoms:
          'Yaprakta gri-kahverengi yumuşak çürüme + tipik gri sporlu örtü; meyvede yumuşak çürüklük.',
      monitoringMethod:
          'Köşegen yürüyüşle bitki kontrolü; etkilenen bitki ve yaprak oranı kaydedilir.',
      economicThreshold:
          'Bulaşık bitki oranı %5-10 üstünde kritik uyarı verilir.',
      culturalControl:
          'Havalandırmayı artır, yaprak ıslaklığını azalt, hastalıklı bitki parçalarını uzaklaştır.',
      chemicalGate:
          'Yoğun bulaşmada BKÜ etiket + uzman önerisi ile fungisit; aktif madde rotasyonu şart.',
      sourceRefs: [
        TomatoSources.tagemGreenhouseIpm,
        TomatoSources.bkuDatabase,
      ],
    ),
    CropIpmRule(
      cropKey: cropKey,
      pestKey: 'late_blight',
      pestName: 'Mildiyö (Phytophthora infestans)',
      type: 'Hastalık',
      observationWindow: 'Açık alan + yağışlı/serin dönemler',
      symptoms:
          'Yaprakta sulu yağ lekeleri → kahverengi nekroz; yaprak alt yüzünde beyaz fungal örtü; meyvede kahverengi sert leke.',
      monitoringMethod:
          'Köşegen yürüyüşle yaprak kontrolü; hastalıklı yaprak/bitki oranı kaydedilir.',
      economicThreshold:
          'Hastalık oranı %5 üstünde kritik uyarı + acil müdahale.',
      culturalControl:
          'Yaprak ıslaklığını azalt (alttan sulama, damla); direnç gösteren çeşit + münavebe.',
      chemicalGate:
          'Eşik aşılırsa BKÜ etiket + uzman önerisi ile koruyucu fungisit; sistemik+koruyucu kombinasyonu rotasyonlu uygulanır.',
      sourceRefs: [
        TomatoSources.tagemOpenFieldIpm,
        TomatoSources.bkuDatabase,
      ],
    ),
    CropIpmRule(
      cropKey: cropKey,
      pestKey: 'early_blight',
      pestName: 'Erken yaprak yanıklığı (Alternaria)',
      type: 'Hastalık',
      observationWindow: 'Vejetatif - meyve oluşum dönemi',
      symptoms:
          'Alt yapraklarda halkalı kahverengi lekeler; ilerleyince yaprak sararması ve düşmesi.',
      monitoringMethod:
          'Alt yapraklarda haftalık kontrol; bulaşık yaprak oranı kaydedilir.',
      economicThreshold:
          'Bulaşık yaprak oranı %15 üstünde fungisit değerlendirme kapısı açar.',
      culturalControl:
          'Alt yaprakları temizle, havalandırma + alttan sulama; münavebe.',
      chemicalGate: 'Eşik aşılırsa BKÜ etiket + uzman önerisi ile fungisit.',
      sourceRefs: [
        TomatoSources.tagemOpenFieldIpm,
        TomatoSources.bkuDatabase,
      ],
    ),
  ];

  static const scoutingWindows = <IpmScoutingWindow>[
    IpmScoutingWindow(
      dayOffset: 20,
      pestKeys: ['whitefly', 'aphid'],
      title: 'Fide şaşırtma sonrası erken gözlem',
    ),
    IpmScoutingWindow(
      dayOffset: 45,
      pestKeys: ['tuta_absoluta', 'thrips', 'early_blight'],
      title: 'Vejetatif dönem zararlı/hastalık gözlemi',
    ),
    IpmScoutingWindow(
      dayOffset: 70,
      pestKeys: ['tuta_absoluta', 'botrytis', 'late_blight', 'spider_mite'],
      title: 'Çiçeklenme + meyve oluşum izleme',
    ),
    IpmScoutingWindow(
      dayOffset: 100,
      pestKeys: ['tuta_absoluta', 'botrytis', 'late_blight'],
      title: 'Hasat dönemi yoğun gözlem',
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
