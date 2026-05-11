/// Türkiye koşullarına göre hazırlanmış çevrimdışı ürün rehberleri.
///
/// Bu veri katmanı, mobil rehber ekranının internet olmadan da ayçiçeği,
/// domates, mısır, portakal ve çay için teknik, ürün özelinde ve Türkiye standartlarına
/// yakın bilgi gösterebilmesi için kullanılır.
library;

import 'sunflower_source_refs.dart';

class GuideStage {
  final String title;
  final String timing;
  final String action;
  final String risk;

  const GuideStage({
    required this.title,
    required this.timing,
    required this.action,
    required this.risk,
  });

  Map<String, dynamic> toJson() => {
        'title': title,
        'timing': timing,
        'action': action,
        'risk': risk,
      };
}

class PestDiseaseGuide {
  final String name;
  final String type;
  final String symptoms;
  final String monitoring;
  final String integratedControl;
  final String escalation;
  final String? samplingMethod;
  final String? economicThreshold;
  final String? chemicalGate;

  const PestDiseaseGuide({
    required this.name,
    required this.type,
    required this.symptoms,
    required this.monitoring,
    required this.integratedControl,
    required this.escalation,
    this.samplingMethod,
    this.economicThreshold,
    this.chemicalGate,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'type': type,
        'symptoms': symptoms,
        'monitoring': monitoring,
        'integratedControl': integratedControl,
        'escalation': escalation,
        if (samplingMethod != null) 'samplingMethod': samplingMethod,
        if (economicThreshold != null) 'economicThreshold': economicThreshold,
        if (chemicalGate != null) 'chemicalGate': chemicalGate,
      };
}

class RegionalCropCalendar {
  final String region;
  final String plantingWindow;
  final String harvestWindow;
  final String notes;

  const RegionalCropCalendar({
    required this.region,
    required this.plantingWindow,
    required this.harvestWindow,
    required this.notes,
  });

  Map<String, dynamic> toJson() => {
        'region': region,
        'plantingWindow': plantingWindow,
        'harvestWindow': harvestWindow,
        'notes': notes,
      };
}

class NutritionGuide {
  final String phase;
  final String timing;
  final String recommendation;

  const NutritionGuide({
    required this.phase,
    required this.timing,
    required this.recommendation,
  });

  Map<String, dynamic> toJson() => {
        'phase': phase,
        'timing': timing,
        'recommendation': recommendation,
      };
}

class TurkiyeCropGuide {
  final String id;
  final String cropName;
  final List<String> aliases;
  final String scientificName;
  final String category;
  final String summary;
  final String lifeCycle;
  final String sunlight;
  final String growthSpeed;
  final String careLevel;
  final List<String> sourceRefs;
  final String sowingWindow;
  final String harvestWindow;
  final double sowingDepthCm;
  final double rowSpacingCm;
  final double plantSpacingCm;
  final String seedOrSeedlingRate;
  final int plantPopulationPerDekar;
  final double idealPhMin;
  final double idealPhMax;
  final double idealTempMin;
  final double idealTempMax;
  final int harvestDays;
  final double seasonalWaterMm;
  final String irrigationSummary;
  final String fertilizerSummary;
  final String fertilizerType;
  final double dailyWaterLitersPerPlant;
  final String companionPlants;
  final String avoidPlants;
  final String pruning;
  final bool droughtTolerant;
  final String plantingTip;
  final String regionNote;
  final String integratedPestManagementNote;
  final String rotationNotes;
  final String harvestQualityNotes;
  final String yieldExpectation;
  final List<GuideStage> stages;
  final List<PestDiseaseGuide> pests;
  final List<RegionalCropCalendar> regionalCalendar;
  final List<NutritionGuide> nutritionPlan;

  const TurkiyeCropGuide({
    required this.id,
    required this.cropName,
    required this.aliases,
    required this.scientificName,
    required this.category,
    required this.summary,
    this.lifeCycle = 'Tek yıllık',
    this.sunlight = 'Tam güneş',
    this.growthSpeed = 'Orta-Hızlı',
    this.careLevel = 'Orta',
    required this.sourceRefs,
    required this.sowingWindow,
    required this.harvestWindow,
    required this.sowingDepthCm,
    required this.rowSpacingCm,
    required this.plantSpacingCm,
    required this.seedOrSeedlingRate,
    required this.plantPopulationPerDekar,
    required this.idealPhMin,
    required this.idealPhMax,
    required this.idealTempMin,
    required this.idealTempMax,
    required this.harvestDays,
    required this.seasonalWaterMm,
    required this.irrigationSummary,
    required this.fertilizerSummary,
    required this.fertilizerType,
    required this.dailyWaterLitersPerPlant,
    required this.companionPlants,
    required this.avoidPlants,
    required this.pruning,
    required this.droughtTolerant,
    required this.plantingTip,
    required this.regionNote,
    required this.integratedPestManagementNote,
    required this.rotationNotes,
    required this.harvestQualityNotes,
    required this.yieldExpectation,
    required this.stages,
    required this.pests,
    required this.regionalCalendar,
    required this.nutritionPlan,
  });

  Map<String, dynamic> get technicalMetrics => {
        'Ekim aralığı': sowingWindow,
        'Hasat aralığı': harvestWindow,
        'Ekim derinliği': '${_fmt(sowingDepthCm)} cm',
        'Sıra arası': '${_fmt(rowSpacingCm)} cm',
        'Sıra üzeri': '${_fmt(plantSpacingCm)} cm',
        'Tohum/Fide': seedOrSeedlingRate,
        'Bitki/dekar': plantPopulationPerDekar,
        'pH': '${_fmt(idealPhMin)}-${_fmt(idealPhMax)}',
        'Sıcaklık': '${_fmt(idealTempMin)}-${_fmt(idealTempMax)} °C',
        'Sezon suyu': '${_fmt(seasonalWaterMm)} mm',
        'Verim notu': yieldExpectation,
      };

  Map<String, dynamic> get cropDataOverrides => {
        'scientific': scientificName,
        'desc': summary,
        'cycle': lifeCycle,
        'sunlight': sunlight,
        'growth': growthSpeed,
        'care': careLevel,
        'indoor': false,
        'drought': droughtTolerant,
        'pruning': pruning,
        'pests': pests.map((p) => p.name).join(', '),
        'ideal_temp_min': idealTempMin,
        'ideal_temp_max': idealTempMax,
        'ideal_ph_min': idealPhMin,
        'ideal_ph_max': idealPhMax,
        'sunlight_hours': 8,
        'harvest_days': harvestDays,
        'best_planting_months': sowingWindow,
        'companion_plants': companionPlants,
        'avoid_plants': avoidPlants,
        'pest_prevention': integratedPestManagementNote,
        'region_uygunluk': 82,
        'region_note': regionNote,
        'daily_water_liters_per_plant': dailyWaterLitersPerPlant,
        'fertilizer_schedule': fertilizerSummary,
        'planting_tip': plantingTip,
      };

  Map<String, dynamic> get plantingDataOverrides => {
        'depth_cm': sowingDepthCm,
        'row_spacing_cm': rowSpacingCm,
        'plant_spacing_cm': plantSpacingCm,
        'seeds_per_dekar': plantPopulationPerDekar,
        'irrigation_type': 'Damla Sulama',
        'irrigation_line_spacing_cm': rowSpacingCm,
        'irrigation_dripper_spacing_cm': plantSpacingCm,
        'fertilizer_band_cm': 10,
        'fertilizer_depth_cm': 8,
        'fertilizer_type': fertilizerType,
        'daily_water_liters': dailyWaterLitersPerPlant,
        'fertilizer_schedule': fertilizerSummary,
      };

  Map<String, dynamic> toJson() => {
        'id': id,
        'cropName': cropName,
        'aliases': aliases,
        'scientificName': scientificName,
        'category': category,
        'summary': summary,
        'sourceRefs': sourceRefs,
        'technicalMetrics': technicalMetrics,
        'irrigationSummary': irrigationSummary,
        'fertilizerSummary': fertilizerSummary,
        'integratedPestManagementNote': integratedPestManagementNote,
        'rotationNotes': rotationNotes,
        'harvestQualityNotes': harvestQualityNotes,
        'stages': stages.map((s) => s.toJson()).toList(),
        'pests': pests.map((p) => p.toJson()).toList(),
        'regionalCalendar': regionalCalendar.map((r) => r.toJson()).toList(),
        'nutritionPlan': nutritionPlan.map((n) => n.toJson()).toList(),
      };

  static String _fmt(double value) => value == value.roundToDouble()
      ? value.toStringAsFixed(0)
      : value.toStringAsFixed(1);
}

class TurkiyeCropGuides {
  TurkiyeCropGuides._();

  static const List<TurkiyeCropGuide> guides = [
    TurkiyeCropGuide(
      id: 'aycicegi',
      cropName: 'Ayçiçeği',
      aliases: ['aycicegi', 'ayçiçek', 'aycicek', 'günebakan', 'sunflower'],
      scientificName: 'Helianthus annuus L.',
      category: 'Yağlı tohum',
      summary:
          'Ayçiçeği Türkiye’de özellikle Trakya, Marmara, İç Anadolu, Konya ve Adana havzalarında yetiştirilen stratejik yağlı tohum bitkisidir. Derin köklüdür; kuraklığa mısıra göre daha dayanıklıdır fakat tabla oluşumu ve çiçeklenme döneminde susuz bırakılırsa verim hızla düşer.',
      sourceRefs: [
        SunflowerSources.tagemTechnicalSpec,
        SunflowerSources.tagemIpm2022,
        SunflowerSources.trakyaYalcinKaya,
        SunflowerSources.trakyaSamiSuzer,
        SunflowerSources.bkuDatabase,
      ],
      sowingWindow: 'Mart sonu-Mayıs; ana hedef toprak 8-10 °C üstü',
      harvestWindow: 'Ağustos-Eylül; tabla arkası sararıp daneler sertleşince',
      sowingDepthCm: 5,
      rowSpacingCm: 70,
      plantSpacingCm: 30,
      seedOrSeedlingRate: '300-500 g/da sertifikalı hibrit tohum',
      plantPopulationPerDekar: 5000,
      idealPhMin: 6,
      idealPhMax: 7.5,
      idealTempMin: 18,
      idealTempMax: 30,
      harvestDays: 120,
      seasonalWaterMm: 550,
      irrigationSummary:
          'Kurak koşullarda en kritik su dönemleri tabla oluşumu, çiçeklenme ve dane dolumudur. Yağış yetersizse bu üç dönemde derin sulama verim kaybını azaltır.',
      fertilizerSummary:
          'Toprak analizine göre planlanmalı. Analiz yoksa kuru koşullarda yaklaşık 8 kg/da, sulu koşullarda 10 kg/da saf azot ve 6-8 kg/da P2O5 hedeflenir; azotun yarısı ekimle, yarısı 25-30 cm boyda verilmelidir.',
      fertilizerType: 'Taban P + bölünmüş azot',
      dailyWaterLitersPerPlant: 2,
      companionPlants: 'Buğday, arpa, baklagil münavebesi',
      avoidPlants:
          'Ayçiçeği üst üste ekim, yoğun canavar otu geçmişi olan parsel',
      pruning: 'Yok',
      droughtTolerant: true,
      plantingTip:
          'Pnömatik mibzerle 70 cm sıra arası kur; kurak ve zayıf toprakta sıra üzerini 35-40 cm’ye aç, verimli ve sulanan tarlada 25-30 cm tut.',
      regionNote:
          'Trakya ve Marmara ana üretim bölgesidir. İç Anadolu’da erken ekim ilkbahar yağışından yararlanmayı artırır; Güneyde sulama ve orobanş dayanımı daha kritiktir.',
      integratedPestManagementNote:
          'TAGEM entegre mücadele yaklaşımına göre önce dayanıklı çeşit, temiz tarla, münavebe, yabancı ot kontrolü ve düzenli sayım uygulanır. Kimyasal mücadele yalnız eşik aşıldığında, etiket dozu ve il/ilçe müdürlüğü önerisiyle yapılmalıdır.',
      rotationNotes:
          'Sclerotinia, mildiyö ve canavar otu baskısını azaltmak için aynı tarlaya en az 3-4 yıl ayçiçeği ekilmemelidir. Buğday-arpa-baklagil-ayçiçeği sıralaması güvenli bir temel münavebedir.',
      harvestQualityNotes:
          'Hasat için tabla arkası sarı-kahverengi olmalı, daneler sertleşmeli ve nem düşmelidir. Çok geç hasat kuş zararı, dane dökümü ve tabla çürüklüğü riskini artırır.',
      yieldExpectation: 'Yağlık üretimde yaklaşık 200-300 kg/da hedeflenir',
      stages: [
        GuideStage(
          title: 'Ekim yatağı ve ekim',
          timing: '0. gün',
          action:
              'Tavlı toprağa 5 cm derinlikte sertifikalı, bölgeye uyumlu ve gerekirse orobanş/mildiyö toleranslı hibrit tohum ek.',
          risk:
              'Kuru toprağa veya çok derine ekim çıkışı geciktirir; seyrek çıkışta tarla homojenliği bozulur.',
        ),
        GuideStage(
          title: 'Çıkış ve tekleme kontrolü',
          timing: '7-18 gün',
          action:
              'Sıra üzeri boşlukları, kabuk bağlama ve telkurdu/bozkurt zararını kontrol et; hedef 4.000-5.500 bitki/da.',
          risk:
              'Erken dönem bozkurt ve telkurdu zararında boş alanlar kalırsa verim potansiyeli geri gelmez.',
        ),
        GuideStage(
          title: 'Ara çapa ve üst azot',
          timing: '25-35 cm bitki boyu',
          action:
              'Yabancı otları bastır, boğazı hafif doldur ve kalan azotu sıra yanına verip toprağa karıştır.',
          risk:
              'Geç yabancı ot kontrolü, ayçiçeğinin ilk gelişim döneminde su ve besin rekabetini artırır.',
        ),
        GuideStage(
          title: 'Tabla oluşumu ve çiçeklenme',
          timing: '55-80 gün',
          action:
              'Su stresi yaşatma; tabla, yeşilkurt, çayır tırtılı ve mildiyö belirtilerini düzenli izle.',
          risk:
              'Bu dönemde kuraklık ve zararlı baskısı tabla çapını, tane sayısını ve yağ oranını düşürür.',
        ),
        GuideStage(
          title: 'Dane dolumu ve hasat',
          timing: '90-120 gün',
          action:
              'Dane sertliği, tabla arkası rengi ve nem durumuna göre hasadı planla; biçerdöver ayarını dane kırmayacak şekilde yap.',
          risk:
              'Geç kalmak kuş zararı, dökülme ve yağ kalitesinde düşüş yaratır.',
        ),
      ],
      pests: [
        PestDiseaseGuide(
          name: 'Bozkurt',
          type: 'Zararlı',
          symptoms:
              'Genç bitkiler kök boğazından kesilir veya kemirilir; sıra üzerinde boşluklar oluşur.',
          monitoring:
              '2 gerçek yapraklı dönemde kesik bitki ve metrekare larva sayısı kontrol edilir.',
          samplingMethod:
              'Tarlada köşegen veya zikzak yürüyerek kesik bitki varlığı ve m² larva sayımı yapılır.',
          economicThreshold: 'Metrekarede 1-3 larva',
          integratedControl:
              'Sonbahar sürümü ve ilkbahar başından itibaren yabancı ot temizliği temel önlemdir.',
          chemicalGate:
              'Eşik aşılmadan ilaç önerilmez; eşik aşılırsa etiket ve il/ilçe teknik önerisi esas alınır.',
          escalation:
              'Eşik üstünde akşam saatleri ve toprak tavı dikkate alınarak resmi teknik öneriyle ilerlenmelidir.',
        ),
        PestDiseaseGuide(
          name: 'Yeşilkurt',
          type: 'Zararlı',
          symptoms:
              'Yapraklarda damar kalacak şekilde yenik, tomurcuk/tabla zararları ve tane kaybı.',
          monitoring:
              'R1 döneminden itibaren feromon takibi ve 100 bitki kontrolü yapılır.',
          samplingMethod:
              'Her 20 dekarlık alan bir ünite kabul edilerek zikzak yürüyüşle toplam 100 bitkide yumurta, birinci dönem larva veya ilk zarar aranır.',
          economicThreshold:
              '100 bitkinin 5’inde yumurta, birinci dönem larva veya ilk zarar belirtisi',
          integratedControl:
              'Baharda iyi toprak işleme ile kışlayan pupalar azaltılır; doğal düşmanları koruyan uygulamalar önceliklidir.',
          chemicalGate:
              'Yalnız eşik doğrulanırsa kontrollü kimyasal kapısı açılır.',
          escalation:
              'Eşik aşılırsa etiket, son ilaçlama-hasat arası süre ve il/ilçe teknik önerisi birlikte kontrol edilmelidir.',
        ),
        PestDiseaseGuide(
          name: 'Çayır tırtılı',
          type: 'Zararlı',
          symptoms:
              'Yaprak, tomurcuk ve çiçeklerde oburca beslenme; yoğunlukta yeşil aksamın hızla kaybolması.',
          monitoring:
              'Vejetatif gelişme döneminde bitkiler gözle kontrol edilir ve m² larva sayısı kaydedilir.',
          samplingMethod:
              'Tarla genelinde gözle larva sayımı yapılır; yoğunluk metrekareye çevrilir.',
          economicThreshold: 'Metrekarede 10 larva',
          integratedControl:
              'Erken gözlem ve yabancı ot temizliği uygulanır; müdahale gerekiyorsa en geç üçüncü dönem larvalara karşı planlanır.',
          chemicalGate:
              'Eşik altında kimyasal yok; eşik aşılırsa etiket ve teknik öneri ile ilerlenir.',
          escalation:
              'Eşik üstünde uygulama zamanı larva dönemi ve resmi teknik öneriyle birlikte değerlendirilmelidir.',
        ),
        PestDiseaseGuide(
          name: 'Ayçiçeği güvesi',
          type: 'Zararlı',
          symptoms:
              'Çiçeklenmeden sonra polen, taç yaprak ve tablada tohum zararı.',
          monitoring:
              'Çiçeklenmeden itibaren feromon tuzakları ve 100 bitkide tabla kontrolü birlikte yapılır.',
          samplingMethod:
              'Tarla kenarı ve merkeze feromon tuzağı asılır; tuzak ortalaması 10+ erginse 7-10 gün sonra 100 bitkide yumurta, larva veya ilk zarar aranır.',
          economicThreshold:
              '100 bitkinin 5’inde yumurta, larva veya ilk zarar; sadece tuzak artışı ilaç kararı değildir.',
          integratedControl:
              'Ekim öncesi derin sürüm ve Asteraceae yabancı ot temizliği önceliklidir.',
          chemicalGate:
              'Sadece tuzak artışı kimyasal için yeterli değildir; bitki kontrolünde eşik doğrulanmalıdır.',
          escalation:
              'Eşik doğrulanırsa etiket ve il/ilçe teknik önerisiyle kontrollü uygulama değerlendirilir.',
        ),
        PestDiseaseGuide(
          name: 'Telkurtları',
          type: 'Zararlı',
          symptoms:
              'Köklerde ve toprak altı bitki kısımlarında beslenme; yeni çıkan bitkilerde ölüm.',
          monitoring:
              '2 gerçek yaprak döneminden itibaren 1/4 m² çerçeve ve 20 cm toprak kontrolü yapılır.',
          samplingMethod:
              'Köşegen yürüyüşle 10-20 m aralıklarla en az 12 noktada çerçeve atılır; larvalar m² yoğunluğuna çevrilir.',
          economicThreshold: 'Metrekarede en az 6 larva',
          integratedControl:
              'Geçmiş bulaşık tarlada münavebe, yabancı ot temizliği ve şubat-mart sürümü uygulanır.',
          chemicalGate:
              'Eşik aşılmadan kimyasal önerilmez; geçmiş yoğun bulaşıklık resmi teknik destekle değerlendirilir.',
          escalation:
              'Yoğun bulaşıklıkta ürün seçimi ve toprak işlemesi uzman desteğiyle planlanmalıdır.',
        ),
        PestDiseaseGuide(
          name: 'Ayçiçeği mildiyösü',
          type: 'Hastalık',
          symptoms:
              'Bodur bitki, yaprak üstünde sararma, yaprak altında beyazımsı küf görünümü.',
          monitoring:
              '2 gerçek yaprak döneminden itibaren zayıf ve bodur ocaklar gezilerek kontrol edilir.',
          samplingMethod:
              'Köşegen veya zikzak yürüyüşle enfeksiyon belirtileri aranır; hastalıklı bitki oranı yüzde olarak kaydedilir.',
          economicThreshold:
              'İki yapraklı dönemde hastalık oranı %30’un üzerine çıkarsa kritik uyarı',
          integratedControl:
              'Dayanıklı çeşit, temiz sertifikalı tohum, münavebe ve hastalıklı bitki artıklarının tarladan uzaklaştırılması esastır.',
          chemicalGate:
              'Yeşil aksam ilaç kapısı açılmaz; %30 üstünde resmi teknik destek ve tarla sürümü uyarısı verilir.',
          escalation:
              'Hastalık oranı %30’u aşarsa il/ilçe müdürlüğü veya yetkili uzmanla görüşülmeli, ağır bulaşık alanda sürüm kararı değerlendirilmelidir.',
        ),
        PestDiseaseGuide(
          name: 'Canavar otu',
          type: 'Parazit yabancı ot',
          symptoms:
              'Bitki dibinde mor-kahverengi sürgünler, ayçiçeğinde bodurluk ve tabla küçülmesi.',
          monitoring:
              'Geçmiş yıllarda bulaşık tarlalar kayıt altına alınır; çiçeklenme öncesi sıra dipleri gezilir.',
          integratedControl:
              'Dayanıklı çeşit, uzun münavebe ve bulaşık tarladan tohum/toprak taşımama temel önlemdir.',
          escalation:
              'Herbisit kullanımı yalnız çeşit teknolojisi ve ruhsatlı etiket koşulları uygunsa yapılmalıdır.',
        ),
      ],
      regionalCalendar: [
        RegionalCropCalendar(
          region: 'Marmara-Trakya',
          plantingWindow: 'Mart sonu-Nisan',
          harvestWindow: 'Ağustos sonu-Eylül',
          notes:
              'Ana üretim bölgesi; orobanş ve mildiyö dayanımı çeşit seçiminde kritiktir.',
        ),
        RegionalCropCalendar(
          region: 'İç Anadolu',
          plantingWindow: 'Nisan',
          harvestWindow: 'Eylül',
          notes:
              'İlkbahar yağışından yararlanmak için tav yakalanınca gecikmeden ekim yapılır.',
        ),
        RegionalCropCalendar(
          region: 'Akdeniz-Güneydoğu',
          plantingWindow: 'Mart-Nisan',
          harvestWindow: 'Ağustos',
          notes:
              'Sıcak ve sulanan alanlarda tabla dönemi sulaması ve yabancı ot yönetimi öne çıkar.',
        ),
      ],
      nutritionPlan: [
        NutritionGuide(
          phase: 'Taban',
          timing: 'Ekimle birlikte',
          recommendation:
              'Fosforun tamamı ve azotun yarısı banda verilir; gübre tohumla direkt temas ettirilmez.',
        ),
        NutritionGuide(
          phase: 'Üst gübre',
          timing: '25-30 cm bitki boyu',
          recommendation:
              'Kalan azot sıra yanına verilip çapa veya sulama ile kök bölgesine taşınır.',
        ),
      ],
    ),
    TurkiyeCropGuide(
      id: 'domates',
      cropName: 'Domates',
      aliases: ['tomates', 'domat', 'tomato', 'solanum'],
      scientificName: 'Solanum lycopersicum L.',
      category: 'Sebze',
      summary:
          'Domates açık tarla ve örtü altı üretimde yüksek bakım isteyen, sıcak-ılıman iklim bitkisidir. Don, düzensiz sulama, aşırı nem ve kalsiyum dengesizliği kaliteyi hızla bozar; verim için fide kalitesi, destek, havalanma, dengeli sulama ve entegre zararlı takibi birlikte yürütülmelidir.',
      careLevel: 'Orta-Yüksek',
      sourceRefs: [
        'TAGEM Açık Alan Domates Entegre Mücadele Teknik Talimatı, 2022',
        'TAGEM Örtüaltı Sebze Entegre Mücadele Teknik Talimatı',
        'Tarım ve Orman Bakanlığı Merkez Kütüphanesi, Domates yetiştiriciliği kaynak kayıtları',
        'Tarım ve Orman Bakanlığı il müdürlükleri açıkta domates yetiştiriciliği broşürleri',
      ],
      sowingWindow:
          'Fide: Mart-Nisan; tarlaya dikim: don riski geçince Nisan-Mayıs',
      harvestWindow: 'Haziran-Ekim; çeşit ve bölgeye göre kademeli hasat',
      sowingDepthCm: 1,
      rowSpacingCm: 100,
      plantSpacingCm: 50,
      seedOrSeedlingRate: 'Açık tarla yaklaşık 2.000-2.500 fide/da',
      plantPopulationPerDekar: 2200,
      idealPhMin: 6,
      idealPhMax: 6.8,
      idealTempMin: 18,
      idealTempMax: 30,
      harvestDays: 110,
      seasonalWaterMm: 600,
      irrigationSummary:
          'Dikimden sonra can suyu verilir. Çiçeklenme, meyve tutumu ve meyve irileşme döneminde toprak nemi dalgalanmamalıdır; düzensiz sulama çatlama ve çiçek burnu çürüklüğünü artırır.',
      fertilizerSummary:
          'Toprak analizine göre planlanmalı. Genel hedef 20-25 kg/da saf azot, 10-12 kg/da P2O5 ve 25-30 kg/da K2O’dur; azot ve potasyum çiçeklenme-meyve döneminde bölünerek verilmelidir.',
      fertilizerType: 'Dengeli NPK + meyvede potasyum/kalsiyum',
      dailyWaterLitersPerPlant: 2.5,
      companionPlants: 'Fesleğen, kadife çiçeği, soğan, sarımsak',
      avoidPlants:
          'Patates, biber, patlıcan ardışık ekim; sık ve havasız dikim',
      pruning:
          'Sırık çeşitlerde koltuk alma, bağlama ve gerektiğinde alt yaprak temizliği',
      droughtTolerant: false,
      plantingTip:
          'Fideleri serin saatte dik; kök boğazını çok derine gömme, hemen can suyu ver ve sırık çeşitte erken destek sistemini kur.',
      regionNote:
          'Akdeniz ve Ege’de erken üretim, Marmara ve İç Anadolu’da don sonrası açık tarla üretimi uygundur. Karadeniz’de nem yüksek olduğu için havalanma ve mantari hastalık takibi daha önemlidir.',
      integratedPestManagementNote:
          'TAGEM yaklaşımıyla sarı yapışkan tuzak, düzenli yaprak altı kontrolü, temiz fide, münavebe ve hastalıklı artıkların uzaklaştırılması önceliklidir. Kimyasal mücadele yalnız eşik ve teşhis sonrası, etiket dozu ve il/ilçe müdürlüğü önerisiyle yapılmalıdır.',
      rotationNotes:
          'Solanaceae bitkileriyle üst üste ekimden kaçın. Domates sonrası aynı tarlaya 3 yıl patates, biber, patlıcan veya domates getirmemek kök hastalıkları ve nematod riskini azaltır.',
      harvestQualityNotes:
          'Sofralık hasatta renk dönümü-pembe dönem, sanayilikte tam kırmızı dönem hedeflenir. Hasat sabah serinliğinde yapılmalı; meyve ıslak veya çok sıcak iken kasaya alınmamalıdır.',
      yieldExpectation: 'Açık tarlada bakım ve çeşide göre yaklaşık 5-8 ton/da',
      stages: [
        GuideStage(
          title: 'Fide hazırlığı',
          timing: 'Dikimden 30-45 gün önce',
          action:
              'Sağlıklı, 4-6 gerçek yapraklı, kök sistemi güçlü fide kullan; dikimden önce fideleri dış koşula alıştır.',
          risk:
              'Zayıf fide, kök hastalığı ve dikim şoku sezon boyu gelişimi geriletir.',
        ),
        GuideStage(
          title: 'Tarla dikimi ve can suyu',
          timing: 'Don riski geçince',
          action:
              '100 x 50 cm ana aralığı koru; serin saatte dik, can suyu ver ve sırık çeşitte destek planını hazırla.',
          risk: 'Sıcak saatte dikim ve yetersiz can suyu fide kaybı yapar.',
        ),
        GuideStage(
          title: 'Köklenme ve ilk çapa',
          timing: 'Dikimden 10-20 gün sonra',
          action:
              'İlk çapayı yap, yabancı otları temizle, kök boğazını havalandır ve damla hattını kontrol et.',
          risk: 'Kabuk bağlayan veya otlu toprak kök gelişimini zayıflatır.',
        ),
        GuideStage(
          title: 'Çiçeklenme ve meyve tutumu',
          timing: '35-65 gün',
          action:
              'Sulamayı düzenli tut, potasyum-kalsiyum dengesini izle, sırık çeşitlerde koltuk al ve bağla.',
          risk:
              'Aşırı azot ve düzensiz su çiçek dökümü, çatlama ve çiçek burnu çürüklüğü yapar.',
        ),
        GuideStage(
          title: 'Hasat ve sürekli bakım',
          timing: '70-110+ gün',
          action:
              'Meyveleri 3-4 günde bir topla; Tuta, beyazsinek, mildiyö ve erken yaprak yanıklığını izlemeye devam et.',
          risk:
              'Aşırı olgun meyve bitkiyi yorar, pazar kalitesini ve sonraki salkım gelişimini düşürür.',
        ),
      ],
      pests: [
        PestDiseaseGuide(
          name: 'Domates güvesi',
          type: 'Zararlı',
          symptoms:
              'Yaprakta galeriler, sürgün ve meyvede giriş delikleri, meyve içinde beslenme izi.',
          monitoring:
              'Feromon tuzakları ve yaprak-meyve kontrolü birlikte yapılır; bulaşık meyveler tarlada bırakılmaz.',
          integratedControl:
              'Temiz fide, hasat artıklarını yok etme, tuzak takibi, ağ/örtü ve doğal düşmanları koruma önceliklidir.',
          escalation:
              'Yoğunluk eşik üstüne çıkarsa etiketli ürünler, etiket dozu ve il/ilçe müdürlüğü önerisiyle dönüşümlü uygulanır.',
        ),
        PestDiseaseGuide(
          name: 'Mildiyö ve erken yaprak yanıklığı',
          type: 'Hastalık',
          symptoms:
              'Yaprakta koyu lekeler, sararma, nemli havada hızlı yayılma; alt yapraklardan başlayan kuruma.',
          monitoring:
              'Yağışlı/nemli dönemlerde alt yapraklar ve sıra içi hava akımı kontrol edilir.',
          integratedControl:
              'Sık dikimden kaçın, sabah sulama yap, yaprak ıslaklığını azalt, hastalıklı artıkları uzaklaştır.',
          escalation:
              'Koruyucu/tedavi edici ürün seçimi teşhis sonrası, etiket ve yerel teknik öneriye göre yapılmalıdır.',
        ),
        PestDiseaseGuide(
          name: 'Beyazsinek ve virüs riski',
          type: 'Zararlı/Virüs taşıyıcısı',
          symptoms:
              'Yaprak altında beyaz erginler, yapışkan salgı, sararma, sarı yaprak kıvırcıklığı belirtileri.',
          monitoring:
              'Sarı yapışkan tuzak ve haftalık yaprak altı kontrolü yapılır.',
          integratedControl:
              'Yabancı ot temizliği, temiz fide, tül/örtü, bulaşık bitkiyi sökme ve doğal düşmanları koruma uygulanır.',
          escalation:
              'Vektör yoğunluğu artarsa ruhsatlı ürünler etiket dozu ve uzman önerisiyle kullanılmalıdır.',
        ),
      ],
      regionalCalendar: [
        RegionalCropCalendar(
          region: 'Akdeniz',
          plantingWindow: 'Şubat-Nisan; örtü altında daha erken',
          harvestWindow: 'Haziran-Ekim',
          notes:
              'Erken üretim avantajlıdır; yaz sıcaklarında gölgeleme ve düzenli sulama gerekir.',
        ),
        RegionalCropCalendar(
          region: 'Ege-Marmara',
          plantingWindow: 'Mart-Mayıs',
          harvestWindow: 'Temmuz-Ekim',
          notes:
              'Açık tarla için don sonrası dikim ve sırık çeşitlerde destek önemlidir.',
        ),
        RegionalCropCalendar(
          region: 'İç Anadolu',
          plantingWindow: 'Mayıs',
          harvestWindow: 'Ağustos-Eylül',
          notes: 'Geç don ve gece-gündüz sıcaklık farkı dikkate alınmalıdır.',
        ),
        RegionalCropCalendar(
          region: 'Karadeniz',
          plantingWindow: 'Nisan-Mayıs',
          harvestWindow: 'Temmuz-Eylül',
          notes:
              'Nemli iklim nedeniyle sıra havalanması ve mantari hastalık takibi kritik olur.',
        ),
      ],
      nutritionPlan: [
        NutritionGuide(
          phase: 'Taban',
          timing: 'Dikim öncesi',
          recommendation:
              'Fosforun tamamı, azot ve potasyumun bir bölümü toprak analizine göre verilir; organik madde düşükse yanmış çiftlik gübresi tercih edilir.',
        ),
        NutritionGuide(
          phase: 'Çiçeklenme',
          timing: 'İlk salkımlar görünürken',
          recommendation:
              'Azotu abartmadan potasyum ve kalsiyum dengesine dikkat edilir; düzensiz su verilmez.',
        ),
        NutritionGuide(
          phase: 'Meyve irileşme',
          timing: 'Hasat boyunca',
          recommendation:
              'Potasyum ağırlığı artırılır; yaprak analizi yoksa yüksek doz uygulamadan kaçınılır.',
        ),
      ],
    ),
    TurkiyeCropGuide(
      id: 'misir',
      cropName: 'Mısır',
      aliases: ['misir', 'corn', 'maize', 'zea'],
      scientificName: 'Zea mays L.',
      category: 'Tahıl',
      summary:
          'Mısır Türkiye’nin hemen her bölgesinde yetiştirilebilen, sıcak isteyen ve su-besin talebi yüksek bir tahıldır. Tepe püskülü, koçan bağlama ve tane dolumu dönemlerinde su stresi verimi doğrudan düşürür; düzgün bitki sıklığı, çinko takibi ve bölünmüş azot yönetimi ana başarı noktalarıdır.',
      sourceRefs: [
        'TAGEM Mısır Entegre Mücadele Teknik Talimatı, 2022',
        'Tarım ve Orman Bakanlığı Eğitim, Yayım ve Yayınlar Dairesi, Mısır Yetiştiriciliği, 2012',
        'Tohumluk Tescil ve Sertifikasyon Merkez Müdürlüğü Mısır Teknik Talimatı',
        'Trakya Tarımsal Araştırma Enstitüsü Mısır Tarımı notları',
      ],
      sowingWindow:
          'Nisan-Mayıs ana ürün; güneyde Haziran sonuna kadar II. ürün',
      harvestWindow: 'Silaj: süt-hamur olum; dane: Eylül-Ekim',
      sowingDepthCm: 5,
      rowSpacingCm: 70,
      plantSpacingCm: 20,
      seedOrSeedlingRate: 'Dane için 2-3 kg/da hibrit tohum',
      plantPopulationPerDekar: 7000,
      idealPhMin: 5.8,
      idealPhMax: 7,
      idealTempMin: 18,
      idealTempMax: 32,
      harvestDays: 130,
      seasonalWaterMm: 700,
      irrigationSummary:
          'En kritik dönemler V8 sonrası hızlı büyüme, tepe püskülü, koçan püskülü ve tane dolumudur. Bu dönemlerde susuzluk koçan bağlamayı ve dane sayısını düşürür.',
      fertilizerSummary:
          'Toprak analizine göre planlanmalı. Genel dane mısır hedefi yaklaşık 22-25 kg/da saf azot, 8-10 kg/da P2O5 ve 6-8 kg/da K2O’dur; azot ekim, V6 ve V10-V12 dönemlerine bölünmelidir.',
      fertilizerType: 'Taban P-K + bölünmüş azot + çinko takibi',
      dailyWaterLitersPerPlant: 3.5,
      companionPlants: 'Baklagil ve buğday münavebesi',
      avoidPlants:
          'Üst üste mısır, yoğun mısır kurdu geçmişi ve kötü parçalanmış sap artığı',
      pruning: 'Yok',
      droughtTolerant: false,
      plantingTip:
          'Dane mısırda 70 x 20-25 cm, silajda daha sık ekim kullanılabilir. Toprak sıcaklığı 10-12 °C altındaysa ekimi geciktir.',
      regionNote:
          'Akdeniz, Ege ve Güneydoğu’da ana ve ikinci ürün; Marmara ve Karadeniz’de ana ürün ve silajlık üretim yaygındır. Trakya’da II. ürün dane riski yüksektir, silaj daha güvenlidir.',
      integratedPestManagementNote:
          'TAGEM entegre mücadele yaklaşımında dayanıklı/uygun çeşit, ekim nöbeti, hasat sonrası sap artıklarının parçalanması, tarla sayımı ve doğal düşmanların korunması önceliklidir. Kimyasal mücadele yalnız eşik aşımı ve etiketli ürünle yapılmalıdır.',
      rotationNotes:
          'Mısır kurdu, kök çürüklüğü ve azot yorgunluğunu azaltmak için baklagil veya kışlık tahıl ile münavebe uygulanmalıdır. Sap artıkları sonbaharda parçalanıp toprağa karıştırılmalıdır.',
      harvestQualityNotes:
          'Silajda kuru madde yaklaşık %30-35, dane mısırda depolama için düşük tane nemi hedeflenir. Nemli ürün depolanırsa küf ve aflatoksin riski yükselir.',
      yieldExpectation: 'Dane üretimde iyi koşullarda yaklaşık 900-1.300 kg/da',
      stages: [
        GuideStage(
          title: 'Ekim ve çıkış',
          timing: '0-12 gün',
          action:
              'Tavlı toprağa 5-6 cm derinlikte ek; 70 cm sıra arası ve hedef bitki sayısını koru.',
          risk:
              'Soğuk ve ıslak toprak çimlenmeyi geciktirir, fide hastalıklarını artırır.',
        ),
        GuideStage(
          title: 'V3-V6 dönemi',
          timing: '3-6 yaprak',
          action:
              'Yabancı ot mücadelesi, ilk üst azot, çinko eksikliği ve boşluk kontrolü yapılır.',
          risk:
              'Bu dönemde yabancı ot rekabeti ve çinko eksikliği sezon verimini sınırlar.',
        ),
        GuideStage(
          title: 'Hızlı vejetatif büyüme',
          timing: 'V8-V12',
          action:
              'Boğaz doldurma, ikinci azot ve düzenli sulama yapılır; bitki devrilmesine karşı köklenme desteklenir.',
          risk:
              'Azot veya su eksikliği koçan potansiyelini daha püskül öncesi düşürür.',
        ),
        GuideStage(
          title: 'Tepe püskülü ve koçan püskülü',
          timing: 'Püskül dönemi',
          action:
              'En yoğun sulama dönemi olarak yönet; rüzgar ve aşırı sıcak günlerde stres takibi yap.',
          risk:
              'Püskül döneminde susuzluk döllenmeyi bozar, koçanda boş dane bırakır.',
        ),
        GuideStage(
          title: 'Tane dolumu ve hasat',
          timing: 'Süt olum-hasat',
          action:
              'Silaj ve dane amacına göre hasat zamanını ayır; depolanacak danede nemi düşür.',
          risk: 'Nemli depolama küf ve aflatoksin riskini artırır.',
        ),
      ],
      pests: [
        PestDiseaseGuide(
          name: 'Mısır kurdu ve koçankurdu',
          type: 'Zararlı',
          symptoms:
              'Gövde ve koçanda delikler, kırılma, koçanda beslenme ve ikincil küf gelişimi.',
          monitoring:
              'Püskül öncesinden itibaren yaprak, gövde ve koçan çevresi düzenli kontrol edilir.',
          integratedControl:
              'Münavebe, sap artıklarını parçalama, uygun ekim zamanı ve doğal düşmanları koruma temel önlemdir.',
          escalation:
              'Eşik aşılırsa uygulama zamanlaması larva bitkiye girmeden, etiket dozu ve uzman önerisiyle yapılmalıdır.',
        ),
        PestDiseaseGuide(
          name: 'Yaprak yanıklıkları ve pas',
          type: 'Hastalık',
          symptoms:
              'Yapraklarda uzun kahverengi lekeler veya pas püstülleri, fotosentez alanında azalma.',
          monitoring:
              'Nemli ve sıcak dönemlerde alt-orta yapraklar kontrol edilir.',
          integratedControl:
              'Dayanıklı çeşit, dengeli azot, sık ekimden kaçınma ve artıkları yönetme uygulanır.',
          escalation:
              'Kimyasal uygulama teşhis ve ekonomik eşik değerlendirmesi sonrası yapılmalıdır.',
        ),
        PestDiseaseGuide(
          name: 'Telkurdu, bozkurt ve danaburnu',
          type: 'Toprak zararlısı',
          symptoms:
              'Kesilmiş fide, boş sıra, kök ve boğaz bölgesinde kemirme zararı.',
          monitoring:
              'Ekim öncesi geçmiş parsel kaydı, çıkış sonrası boşluk ve kesik fide sayımı yapılır.',
          integratedControl:
              'Temiz tarla, münavebe, iyi toprak hazırlığı ve çıkış sonrası hızlı kontrol önceliklidir.',
          escalation:
              'Yoğun geçmiş olan alanlarda tohum/yüzey uygulamaları yalnız ruhsat ve etiket koşuluyla değerlendirilir.',
        ),
      ],
      regionalCalendar: [
        RegionalCropCalendar(
          region: 'Akdeniz-Güneydoğu',
          plantingWindow: 'Mart-Nisan ana ürün; Haziran II. ürün',
          harvestWindow: 'Ağustos-Ekim',
          notes:
              'Sulama planı yüksek sıcaklık ve ikinci ürün takvimine göre sıkı tutulmalıdır.',
        ),
        RegionalCropCalendar(
          region: 'Ege-Marmara',
          plantingWindow: 'Nisan-Mayıs',
          harvestWindow: 'Eylül-Ekim',
          notes:
              'Dane ve silaj için uygun; Trakya’da geç II. ürün dane riski taşır.',
        ),
        RegionalCropCalendar(
          region: 'Karadeniz',
          plantingWindow: 'Nisan-Mayıs',
          harvestWindow: 'Ağustos-Eylül',
          notes:
              'Nemli koşullarda yaprak hastalıkları ve hasat nemi yakından izlenmelidir.',
        ),
      ],
      nutritionPlan: [
        NutritionGuide(
          phase: 'Taban',
          timing: 'Ekimle birlikte',
          recommendation:
              'Fosfor ve potasyumun tamamı, azotun yaklaşık üçte biri verilir; çinko eksikliği olan alanlarda çinko planlanır.',
        ),
        NutritionGuide(
          phase: 'V6',
          timing: '6 yapraklı dönem',
          recommendation:
              'İkinci azot dozu sıra yanına verilir; yabancı ot ve su durumu aynı anda kontrol edilir.',
        ),
        NutritionGuide(
          phase: 'V10-V12',
          timing: 'Püskül öncesi',
          recommendation:
              'Kalan azot ve kritik sulama tamamlanır; bu dönem verim potansiyeli için belirleyicidir.',
        ),
      ],
    ),
    TurkiyeCropGuide(
      id: 'portakal',
      cropName: 'Portakal',
      aliases: [
        'orange',
        'citrus',
        'turuncgil',
        'turunçgil',
        'narenciye',
        'washington navel',
        'valencia'
      ],
      scientificName: 'Citrus sinensis (L.) Osbeck',
      category: 'Meyve',
      lifeCycle: 'Çok yıllık ağaç',
      sunlight: 'Tam güneş',
      growthSpeed: 'Yavaş-Orta',
      careLevel: 'Orta-Yüksek',
      summary:
          'Portakal Türkiye’de ağırlıkla Akdeniz ve Ege kıyı kuşağında yetişen çok yıllık turunçgil ağacıdır. Verim ve kalite; don riskinden korunmuş bahçe yeri, derin ve iyi drene toprak, uygun anaç, düzenli yaz sulaması, dengeli besleme ve hasatta çeşide göre doğru zamanlama ile korunur.',
      sourceRefs: [
        'BATEM Portakal Yetiştiriciliği, 2020',
        'TAGEM Turunçgil Entegre Mücadele Teknik Talimatı',
        'Tarım ve Orman Bakanlığı GKGM Turunçgil Üretici Bilgi Köşesi',
        'TAGEM Turunçgil Sektör Politika Belgesi 2025-2029',
      ],
      sowingWindow:
          'Aşılı fidan: don riski geçince Şubat-Mart; ılıman sahilde Ekim-Kasım',
      harvestWindow:
          'Kasım-Mayıs; Washington Navel kış, Valencia Late geç dönem',
      sowingDepthCm: 60,
      rowSpacingCm: 600,
      plantSpacingCm: 500,
      seedOrSeedlingRate: '5 x 6 m dikimde yaklaşık 33 ağaç/da aşılı fidan',
      plantPopulationPerDekar: 33,
      idealPhMin: 6,
      idealPhMax: 6.5,
      idealTempMin: 13,
      idealTempMax: 32,
      harvestDays: 1460,
      seasonalWaterMm: 750,
      irrigationSummary:
          'Yaz kuraklığında düzenli ve derin sulama gerekir. Su kök boğazına değil taç izdüşümüne verilmeli; taban suyu yüksek veya ağır toprakta drenaj kurulmadan bahçe tesis edilmemelidir.',
      fertilizerSummary:
          'Toprak ve yaprak analizine göre planlanmalı. Genç ağaçta kök yakmayacak hafif besleme, verime yatmış ağaçta azotun bölünmesi, meyve büyüme döneminde potasyum ve mikro besin takibi öne çıkar.',
      fertilizerType: 'Toprak/yaprak analizine göre N-K + mikro besin',
      dailyWaterLitersPerPlant: 35,
      companionPlants:
          'Bahçe kenarında rüzgar kıran, örtü bitkisi ve yabancı otla rekabeti azaltan ara yönetim',
      avoidPlants:
          'Don çukuru, drenajı zayıf taban arazi, tuzlu su etkisi ve sert rüzgara açık parsel',
      pruning:
          'Hasat sonrası ve don riski geçince kuru, hasta, içe bakan ve çapraz dallar çıkarılır',
      droughtTolerant: false,
      plantingTip:
          'Dikimden önce 0-30, 30-60 ve 60-90 cm toprak katmanlarından analiz yaptır; anaç seçimini kireç, tuzluluk, drenaj ve hastalık geçmişine göre yap.',
      regionNote:
          'Akdeniz sahil kuşağı ana üretim alanıdır. Ege’nin don riski düşük sahil kesimleri uygundur; iç kesimlerde düşük sıcaklık ve geç don kaliteyi ve ağaç sağlığını sınırlayabilir.',
      integratedPestManagementNote:
          'Turunçgilde kültürel önlem, sağlıklı fidan, budama-havalanma, tuzakla izleme ve doğal düşmanların korunması önceliklidir. Kimyasal mücadele yalnız teşhis, eşik ve güncel BKÜ etiketi kontrolüyle yapılmalıdır.',
      rotationNotes:
          'Çok yıllık bahçede münavebe yerine bahçe yenileme hijyeni önemlidir: eski kökler temizlenmeli, Phytophthora veya nematod geçmişi olan yerde drenaj ve anaç seçimi uzmanla planlanmalıdır.',
      harvestQualityNotes:
          'Meyve çeşide özgü renk, irilik, tat-asit dengesi ve pazar talebine göre toplanır. Islak meyve hasadı, yere düşürme ve güneşte bekletme depo çürüklüğü ve kabuk zararı riskini artırır.',
      yieldExpectation:
          'Verime yatmış sağlıklı bahçede çeşit, yaş ve bakım durumuna göre değişir',
      stages: [
        GuideStage(
          title: 'Bahçe yeri ve fidan seçimi',
          timing: 'Dikim öncesi',
          action:
              'Don çukuru olmayan, drenajı iyi, rüzgardan korunmuş parsel seç; sertifikalı aşılı fidan ve uygun anaç kullan.',
          risk:
              'Yanlış bahçe yeri ve anaç seçimi yıllarca süren sararma, kök çürüklüğü ve verim düşüklüğü oluşturur.',
        ),
        GuideStage(
          title: 'Dikim ve ilk bakım',
          timing: 'Şubat-Mart veya Ekim-Kasım',
          action:
              'Fidanı aşı yeri toprak üstünde kalacak şekilde dik, can suyu ver, fidan çanağını kök boğazında su biriktirmeyecek biçimde düzenle.',
          risk:
              'Derin dikim, kök boğazı ıslaklığı ve rüzgar sallanması fidan kaybını artırır.',
        ),
        GuideStage(
          title: 'Çiçeklenme ve meyve tutumu',
          timing: 'İlkbahar',
          action:
              'Aşırı su ve azot dalgalanmasından kaçın; arı faaliyeti, rüzgar ve sıcaklık stresini izle.',
          risk:
              'Şiddetli soğuk, sıcak-kuru rüzgar ve su stresi çiçek ve küçük meyve dökümünü artırabilir.',
        ),
        GuideStage(
          title: 'Meyve büyümesi',
          timing: 'Yaz',
          action:
              'Sulamayı düzenli tut, yaprak sararması ve tuzluluk belirtisi varsa analizle besleme planını düzelt.',
          risk:
              'Yaz susuzluğu meyve iriliğini düşürür; aşırı sulama kök havasızlığı ve Phytophthora riskini yükseltir.',
        ),
        GuideStage(
          title: 'Renklenme ve hasat',
          timing: 'Kasım-Mayıs',
          action:
              'Çeşide göre renklenme, irilik ve pazar dönemini izle; meyveyi zedelemeden kasaya al.',
          risk:
              'Geç hasat kabuk bozulması, meyve dökümü ve depo çürüklüğü riskini artırabilir.',
        ),
      ],
      pests: [
        PestDiseaseGuide(
          name: 'Akdeniz meyve sineği',
          type: 'Zararlı',
          symptoms:
              'Meyvede vuruk, yumuşama, dökülme ve pazarlanamaz hale gelen çürüme görülür.',
          monitoring:
              'Bahçe ve çevresinde tuzakla ergin çıkışı izlenir; yere dökülen meyveler düzenli toplanır.',
          integratedControl:
              'Erken uyarı tuzakları, yere düşen meyvenin imhası, hasadı geciktirmeme ve bahçe hijyeni uygulanır.',
          escalation:
              'Tuzak ve meyve kontrolü risk gösterirse güncel BKÜ etiketi ve il/ilçe teknik önerisiyle karar verilir.',
        ),
        PestDiseaseGuide(
          name: 'Turunçgil unlubiti ve kabuklu bitler',
          type: 'Zararlı',
          symptoms:
              'Dal, yaprak ve meyvede pamuksu kümeler, kabuklu yapışık bireyler, fumajin ve kalite kaybı.',
          monitoring:
              'İlkbahar-yaz döneminde iç taç, meyve sap çukuru ve yaprak altları kontrol edilir.',
          integratedControl:
              'Budama ile havalanma, karınca kontrolü, doğal düşmanları koruma ve bulaşık dalların uzaklaştırılması önceliklidir.',
          escalation:
              'Yoğunluk yayılıyorsa uygulama zamanı ve ürün seçimi BKÜ etiketiyle uzman tarafından netleştirilmelidir.',
        ),
        PestDiseaseGuide(
          name: 'Phytophthora kök ve gövde zamklanması',
          type: 'Hastalık',
          symptoms:
              'Kök boğazında zamk akıntısı, kabukta çökme, yaprak sararması ve zayıf sürgün gelişimi.',
          monitoring:
              'Kök boğazı, sulama noktası ve drenaj sorunu olan ocaklar yağış sonrası kontrol edilir.',
          integratedControl:
              'Kök boğazını kuru tut, drenajı düzelt, yaralanmayı azalt ve dayanıklı anaç seçimini önemse.',
          escalation:
              'Gövde belirtisi ilerliyorsa kimyasal karar öncesi hastalık teşhisi ve BKÜ kontrolü gerekir.',
        ),
      ],
      regionalCalendar: [
        RegionalCropCalendar(
          region: 'Akdeniz',
          plantingWindow: 'Şubat-Mart veya Ekim-Kasım',
          harvestWindow: 'Kasım-Mayıs',
          notes:
              'Ana üretim kuşağıdır; yaz sulaması, tuzluluk ve Akdeniz meyve sineği takibi önemlidir.',
        ),
        RegionalCropCalendar(
          region: 'Ege sahil',
          plantingWindow: 'Mart veya Ekim-Kasım',
          harvestWindow: 'Aralık-Nisan',
          notes:
              'Don riski düşük sahil ilçeleri uygundur; rüzgar kıran ve sulama suyu kalitesi izlenmelidir.',
        ),
        RegionalCropCalendar(
          region: 'Doğu Akdeniz-Çukurova',
          plantingWindow: 'Şubat-Mart',
          harvestWindow: 'Kasım-Nisan',
          notes:
              'Sıcaklık ve yüksek verim potansiyeli vardır; yaz su stresi ve kabuklu bit takibi öne çıkar.',
        ),
      ],
      nutritionPlan: [
        NutritionGuide(
          phase: 'Analiz ve organik madde',
          timing: 'Kış sonu',
          recommendation:
              'Toprak ve yaprak analizi olmadan kesin doz verme; organik madde düşükse iyi yanmış organik materyal taç izdüşümüne yayılır.',
        ),
        NutritionGuide(
          phase: 'Uyanma-çiçeklenme',
          timing: 'İlkbahar',
          recommendation:
              'Azot bölünerek verilir; aşırı azot meyve kabuğu ve sürgün dengesini bozabileceği için analizle dengelenir.',
        ),
        NutritionGuide(
          phase: 'Meyve büyümesi',
          timing: 'Yaz',
          recommendation:
              'Potasyum, kalsiyum ve mikro besinler yaprak belirtisi ve analiz sonucuna göre planlanır.',
        ),
      ],
    ),
    TurkiyeCropGuide(
      id: 'cay',
      cropName: 'Çay',
      aliases: ['cay', 'tea', 'camellia', 'siyah çay', 'yeşil çay'],
      scientificName: 'Camellia sinensis (L.) Kuntze',
      category: 'Endüstri bitkisi',
      lifeCycle: 'Çok yıllık çalı',
      sunlight: 'Nemli ışık, yarı gölgeye dayanıklı',
      growthSpeed: 'Yavaş',
      careLevel: 'Orta',
      summary:
          'Çay Türkiye’de Doğu Karadeniz’in nemli, bol yağışlı ve asit topraklı mikroklimasına bağlı çok yıllık bir endüstri bitkisidir. Başarılı üretimde derin-asit toprak, düzenli sürgün hasadı, yenileyici budama, pH takibi ve toprak analizine dayalı dengeli besleme temel rol oynar.',
      sourceRefs: [
        'ÇAYKUR Çay Tarımı Ders Notları, 2025',
        'ÇAYKUR Çay Üreticisi El Kitabı, 1983',
        'Tarım Bakanlığı Çay Yetiştiriciliği Çiftçi Broşürü, 1962',
        'Tarım ve Orman Bakanlığı Rize İl Müdürlüğü sürdürülebilir çay tarımı pH notları',
      ],
      sowingWindow:
          'Tohumla tesis: Kasım-Aralık; çelik alma/köklendirme: Temmuz-Ağustos',
      harvestWindow: 'Mayıs-Ekim; bölgeye göre 3-4 sürgün hasadı',
      sowingDepthCm: 4,
      rowSpacingCm: 110,
      plantSpacingCm: 55,
      seedOrSeedlingRate:
          '100-120 cm sıra arası, 50-60 cm sıra üzeri; 3-5 tohum/ocak veya klonal fidan',
      plantPopulationPerDekar: 1650,
      idealPhMin: 4.5,
      idealPhMax: 6,
      idealTempMin: 14,
      idealTempMax: 30,
      harvestDays: 1095,
      seasonalWaterMm: 1800,
      irrigationSummary:
          'Çay yüksek ve düzenli yağış ister. Yıllık yağış düşükse veya yaz kuraklığı uzarsa sürgün kalitesi düşer; buna karşı sulama, malç ve gölge-rüzgar yönetimi birlikte düşünülmelidir.',
      fertilizerSummary:
          'Toprak analizine göre yapılmalı. ÇAYKUR kaynaklarında 25:5:10 N:P:K bileşimli özel çay gübresi ve çiftlik gübresi öne çıkar; tek yönlü azot pH düşüşü ve besin dengesizliği yaratabilir.',
      fertilizerType: 'Toprak analizine göre özel çay gübresi + organik madde',
      dailyWaterLitersPerPlant: 1.5,
      companionPlants:
          'Bahçe kenarında rüzgarı kesen yerel bitki örtüsü ve erozyonu azaltan örtü yönetimi',
      avoidPlants:
          'Kireçli toprak, suya doygun kök bölgesi, kurutucu rüzgar ve plansız yeni tesis',
      pruning:
          'İlk şekil budaması 3 yaş sonrası; ürün budaması ocak tablasını yenileyecek şekilde kademeli yapılır',
      droughtTolerant: false,
      plantingTip:
          'Köklerin rahat gelişeceği derin asit toprak seç; 90 cm kök bölgesinde sürekli su doygunluğu bırakma ve eğimli arazide erozyon-su yollarını tesis öncesi planla.',
      regionNote:
          'Ana üretim Rize, Trabzon ve Artvin’de; Ordu ve Giresun tali çay alanlarıdır. Uygunluk yağış, bağıl nem, asit toprak ve don riskinin birlikte değerlendirilmesine bağlıdır.',
      integratedPestManagementNote:
          'ÇAYKUR kaynaklarında ülke koşullarında kültürel ve teknik uygulamalar önceliklidir. Hasat, budama, bahçe kenarı temizliği ve doğal düşmanların korunması; kimyasal uygulamadan önce değerlendirilir.',
      rotationNotes:
          'Çay çok yıllık olduğundan klasik münavebe yoktur. Bahçe yenilemede yaşlı ocak, kök ve drenaj sorunları temizlenmeli; pH ve organik madde yeni tesis öncesi düzeltilmelidir.',
      harvestQualityNotes:
          'Kaliteli yaş çayda tepe tomurcuğu ile ilk iki körpe yaprak hedeflenir. Odunlaşmış, lifli, yaşlı yaprak ve ıslak-kirli hasat kaliteyi düşürür.',
      yieldExpectation:
          'Türkiye koşullarında verim bölge, ocak yaşı, budama ve bakım düzenine göre büyük değişir',
      stages: [
        GuideStage(
          title: 'Bahçe tesisi',
          timing: 'Kasım-Aralık veya uygun fidan dönemi',
          action:
              'Asit, derin ve iyi drene toprakta ocak aralıklarını kur; eğimli arazide su yollarını ve erozyon önlemini baştan planla.',
          risk:
              'Kireçli veya suya doygun toprakta kök gelişimi zayıflar, ocaklar uzun yıllar düşük verim verir.',
        ),
        GuideStage(
          title: 'Şekil budaması',
          timing: '3 yaş sonrası Kasım-Aralık veya Mart',
          action:
              'Fidanı ocak haline getirmek için alçak şekil budaması yap; sürgünler yeterli boya gelmeden hasada girme.',
          risk:
              'Erken ve hatalı hasat, toplama tablasının oluşmasını geciktirir.',
        ),
        GuideStage(
          title: 'İlk sürgün hasadı',
          timing: 'Mayıs-Haziran',
          action:
              'Tepe tomurcuğu ve ilk iki körpe yaprağı hedefle; kör ve lifli sürgünleri kalite için ayır.',
          risk:
              'Yaşlı yaprak ve kaba hasat fabrika randımanını ve kuru çay kalitesini düşürür.',
        ),
        GuideStage(
          title: 'Yaz sürgünleri',
          timing: 'Temmuz-Ağustos',
          action:
              'Yabancı ot, sarı çay akarı, koşnil ve kuraklık stresini izle; hasat sonrası ocak altını temiz tut.',
          risk:
              'Sıcak-nemli dönemde akar ve koşnil baskısı sürgün kalitesini bozabilir.',
        ),
        GuideStage(
          title: 'Son sürgün ve kış hazırlığı',
          timing: 'Eylül-Ekim',
          action:
              'Son hasattan sonra ocak altı artıklarını düzenle, pH ve besin planını toprak analizine göre yenile.',
          risk:
              'Dengesiz azot ve düşük pH, gelecek yıl sürgün gücünü ve kök sağlığını zayıflatır.',
        ),
      ],
      pests: [
        PestDiseaseGuide(
          name: 'Çay filiz güvesi',
          type: 'Zararlı',
          symptoms:
              'Yaprak ve sürgünde galeri, yaprak dökümü ve taze sürgünde kalite kaybı.',
          monitoring:
              'Sürgün dönemlerinde genç yapraklar ve galeri sayısı düzenli kontrol edilir.',
          integratedControl:
              'Zamanında hasat, bahçe hijyeni ve doğal düşmanların korunması önceliklidir.',
          escalation:
              'Yoğunluk artarsa kimyasal karar vermeden önce ÇAYKUR/Bakanlık güncel teknik yaklaşımı ve uzman görüşü kontrol edilmelidir.',
        ),
        PestDiseaseGuide(
          name: 'Çay koşnili',
          type: 'Zararlı',
          symptoms:
              'Yaprak ve dallarda fumajin, siyah-isli görünüm, ocakta zayıflama ve verim düşüşü.',
          monitoring:
              'İç kısımdaki dallar, yaprak altları ve hava almayan ocaklar kontrol edilir.',
          integratedControl:
              'Tekniğine uygun budama, hava sirkülasyonu, bahçe kenarı temizliği ve doğal düşmanları koruma uygulanır.',
          escalation:
              'Yayılım büyürse uygulama kararı güncel resmi teknik öneri ve uzman incelemesiyle verilmelidir.',
        ),
        PestDiseaseGuide(
          name: 'Sarı çay akarı',
          type: 'Zararlı',
          symptoms:
              'Genç yapraklarda bronzlaşma, alt yüzeyde tırnaklanma, uç sürgünlerde kurumaya varan zarar.',
          monitoring:
              'Temmuz-Ağustos başta olmak üzere genç sürgünler ve yaprak altları büyüteçle kontrol edilir.',
          integratedControl:
              'Bulaşık yapraklar uzaklaştırılır, yabancı ot ve tozlu alanlar yönetilir, avcı akarları korumak için gereksiz ilaçlamadan kaçınılır.',
          escalation:
              'ÇAYKUR kaynaklarında kültürel-biyolojik yaklaşım öne çıkar; kimyasal uygulama için güncel resmi kayıt ve uzman onayı gerekir.',
        ),
        PestDiseaseGuide(
          name: 'Ricania simulans',
          type: 'Zararlı',
          symptoms:
              'Nimf ve ergin yoğunluğu, sürgünlerde beslenme stresi ve bahçe kenarı bitkilerinde yumurta varlığı.',
          monitoring:
              'Mayıs öncesi bahçe kenarındaki çit, çalı, böğürtlen ve çok yıllık otsu bitkiler kontrol edilir.',
          integratedControl:
              'Yumurta bırakılmış kenar bitkileri nimf çıkışından önce temizlenir; hasat popülasyonu baskılamaya yardımcı olur.',
          escalation:
              'Yoğun alanlarda komşu bahçelerle birlikte mekanik-kültürel mücadele planlanmalıdır.',
        ),
      ],
      regionalCalendar: [
        RegionalCropCalendar(
          region: 'Rize-Trabzon-Artvin',
          plantingWindow: 'Kasım-Aralık tohum; fidan dikimi yerel koşula göre',
          harvestWindow: 'Mayıs-Ekim',
          notes:
              'Ana üretim kuşağıdır; yağış, nem ve asit toprak isteği en iyi bu mikroklimada karşılanır.',
        ),
        RegionalCropCalendar(
          region: 'Ordu-Giresun',
          plantingWindow: 'Yerel izin ve mikroklima uygunluğuna göre',
          harvestWindow: 'Mayıs-Eylül',
          notes:
              'Tali üretim alanlarıdır; yağış dağılımı, pH ve kış zararları ayrıca değerlendirilir.',
        ),
        RegionalCropCalendar(
          region: 'Yüksek rakım ve iç kesim',
          plantingWindow: 'Genel öneri verilmez',
          harvestWindow: 'Riskli',
          notes:
              'ÇAYKUR notlarına göre rakım arttıkça gelişme geriler; yeni tesis uzman ve resmi uygunluk değerlendirmesi gerektirir.',
        ),
      ],
      nutritionPlan: [
        NutritionGuide(
          phase: 'Toprak analizi',
          timing: 'Kış sonu-Şubat',
          recommendation:
              'pH, organik madde ve temel besinler ölçülmeden kesin gübre miktarı verme; çayda hedef asit aralık korunmalıdır.',
        ),
        NutritionGuide(
          phase: 'Özel çay gübresi',
          timing: 'Şubat-Mart',
          recommendation:
              'ÇAYKUR kaynaklarında 25:5:10 N:P:K özel çay gübresi öne çıkar; miktar toprak analizine ve ocak durumuna göre ayarlanır.',
        ),
        NutritionGuide(
          phase: 'Organik madde ve pH dengesi',
          timing: 'Budama yılı ve hasat sonrası',
          recommendation:
              'Çiftlik gübresi, budama artığı ve yabancı otların yönetimi organik maddeyi destekler; tek yönlü amonyumlu gübre pH düşüşü yaratabileceği için takip edilmelidir.',
        ),
      ],
    ),
  ];

  static TurkiyeCropGuide? lookup(String query) {
    final key = _normalize(query);
    if (key.isEmpty) return null;

    for (final guide in guides) {
      final names = [guide.id, guide.cropName, ...guide.aliases];
      if (names.any((name) {
        final normalizedName = _normalize(name);
        return key == normalizedName ||
            key.contains(normalizedName) ||
            normalizedName.contains(key);
      })) {
        return guide;
      }
    }
    return null;
  }

  static String normalizeForTest(String input) => _normalize(input);

  static String _normalize(String input) {
    return input
        .toLowerCase()
        .replaceAll('ı', 'i')
        .replaceAll('İ', 'i')
        .replaceAll('ğ', 'g')
        .replaceAll('ü', 'u')
        .replaceAll('ş', 's')
        .replaceAll('ö', 'o')
        .replaceAll('ç', 'c')
        .replaceAll(RegExp(r'[^a-z0-9]'), '');
  }
}
