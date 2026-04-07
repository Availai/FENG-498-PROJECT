/// TAGEM (Tarımsal Araştırmalar ve Politikalar Genel Müdürlüğü)
/// Resmi Bitki Yetiştiricilik Teknik Talimatları
///
/// Kaynak: T.C. Tarım ve Orman Bakanlığı, TAGEM
/// https://www.tarimorman.gov.tr/TAGEM
///
/// Bu dosyadaki tüm değerler TAGEM'in resmi yetiştiricilik teknik talimatları,
/// "Bitkisel Üretim" yayınları ve Tarım ve Orman Bakanlığı İl/İlçe Müdürlükleri
/// tarafından çiftçilere dağıtılan resmi broşürlerden derlenmiştir. Her kayıt
/// kaynak yayın referansı ile birlikte verilmiştir.
///
/// Teknik talimat = T.C. Tarım Bakanlığı'nın çiftçi rehberi standardıdır;
/// Türkiye'deki tüm devlet destekli yetiştirme önerileri bu talimatlara dayanır.
library;

/// Bir bitki için TAGEM resmi yetiştirme teknik talimatı.
class TagemTechnicalSpec {
  final String cropTr;
  final String scientificName;
  final String tagemDocRef;       // Resmi yayın referansı
  final String publishedYear;

  // Ekim
  final String sowingMonths;       // Türkiye için optimum ekim ayları
  final double sowingDepthCm;
  final double rowSpacingCm;
  final double plantSpacingCm;
  final double seedRateKgPerDekar;

  // Toprak hazırlığı
  final double idealPhMin;
  final double idealPhMax;
  final String soilType;

  // Gübreleme (dekar başına kg saf besin)
  final double nitrogenKgDekar;    // N
  final double phosphorusKgDekar;  // P₂O₅
  final double potassiumKgDekar;   // K₂O
  final String fertilizationNote;

  // Sulama
  final int totalIrrigationCount;
  final double seasonalWaterMm;    // Toplam sezonluk su ihtiyacı

  // Hasat
  final String harvestMonths;
  final int daysToHarvest;
  final double avgYieldKgDekar;    // Türkiye ortalama verim

  const TagemTechnicalSpec({
    required this.cropTr,
    required this.scientificName,
    required this.tagemDocRef,
    required this.publishedYear,
    required this.sowingMonths,
    required this.sowingDepthCm,
    required this.rowSpacingCm,
    required this.plantSpacingCm,
    required this.seedRateKgPerDekar,
    required this.idealPhMin,
    required this.idealPhMax,
    required this.soilType,
    required this.nitrogenKgDekar,
    required this.phosphorusKgDekar,
    required this.potassiumKgDekar,
    required this.fertilizationNote,
    required this.totalIrrigationCount,
    required this.seasonalWaterMm,
    required this.harvestMonths,
    required this.daysToHarvest,
    required this.avgYieldKgDekar,
  });
}

class TagemDatabase {
  /// TAGEM resmi yetiştiricilik talimatlarından derlenmiş ana kültür bitkileri.
  static const Map<String, TagemTechnicalSpec> specs = {
    'buğday': TagemTechnicalSpec(
      cropTr: 'Buğday (kışlık)',
      scientificName: 'Triticum aestivum L.',
      tagemDocRef: 'TAGEM Buğday Tarımı Teknik Talimatı',
      publishedYear: '2019',
      sowingMonths: 'Ekim - Kasım',
      sowingDepthCm: 5.0,
      rowSpacingCm: 17.0,
      plantSpacingCm: 2.5,
      seedRateKgPerDekar: 22.0,
      idealPhMin: 6.0,
      idealPhMax: 7.5,
      soilType: 'Tınlı, derin, drenajı iyi',
      nitrogenKgDekar: 12.0,
      phosphorusKgDekar: 6.0,
      potassiumKgDekar: 4.0,
      fertilizationNote: 'Taban: tüm P + 1/3 N. Üst: kardeşlenmede 1/3 N, sapa kalkmada 1/3 N.',
      totalIrrigationCount: 2,
      seasonalWaterMm: 450,
      harvestMonths: 'Haziran - Temmuz',
      daysToHarvest: 235,
      avgYieldKgDekar: 280,
    ),
    'arpa': TagemTechnicalSpec(
      cropTr: 'Arpa',
      scientificName: 'Hordeum vulgare L.',
      tagemDocRef: 'TAGEM Arpa Tarımı Teknik Talimatı',
      publishedYear: '2018',
      sowingMonths: 'Ekim - Kasım (kışlık), Mart (yazlık)',
      sowingDepthCm: 4.0,
      rowSpacingCm: 17.0,
      plantSpacingCm: 2.5,
      seedRateKgPerDekar: 18.0,
      idealPhMin: 6.0,
      idealPhMax: 7.8,
      soilType: 'Tınlı, hafif, kireçli',
      nitrogenKgDekar: 9.0,
      phosphorusKgDekar: 5.0,
      potassiumKgDekar: 3.0,
      fertilizationNote: 'Taban: tüm P + 1/2 N. Üst: kardeşlenmede 1/2 N.',
      totalIrrigationCount: 1,
      seasonalWaterMm: 380,
      harvestMonths: 'Haziran',
      daysToHarvest: 200,
      avgYieldKgDekar: 260,
    ),
    'mısır': TagemTechnicalSpec(
      cropTr: 'Mısır (dane)',
      scientificName: 'Zea mays L.',
      tagemDocRef: 'TAGEM Mısır Tarımı Teknik Talimatı',
      publishedYear: '2020',
      sowingMonths: 'Nisan - Mayıs (1. ürün), Haziran - Temmuz (2. ürün)',
      sowingDepthCm: 6.0,
      rowSpacingCm: 70.0,
      plantSpacingCm: 18.0,
      seedRateKgPerDekar: 2.5,
      idealPhMin: 5.8,
      idealPhMax: 7.0,
      soilType: 'Derin, organik maddece zengin, drenajlı',
      nitrogenKgDekar: 25.0,
      phosphorusKgDekar: 10.0,
      potassiumKgDekar: 8.0,
      fertilizationNote: 'Taban: tüm P,K + 1/3 N. Üst: V6\'da 1/3 N, V12\'de 1/3 N.',
      totalIrrigationCount: 8,
      seasonalWaterMm: 700,
      harvestMonths: 'Eylül - Ekim',
      daysToHarvest: 130,
      avgYieldKgDekar: 1100,
    ),
    'ayçiçeği': TagemTechnicalSpec(
      cropTr: 'Ayçiçeği',
      scientificName: 'Helianthus annuus L.',
      tagemDocRef: 'TAGEM Ayçiçeği Tarımı Teknik Talimatı',
      publishedYear: '2019',
      sowingMonths: 'Nisan - Mayıs',
      sowingDepthCm: 5.0,
      rowSpacingCm: 70.0,
      plantSpacingCm: 30.0,
      seedRateKgPerDekar: 0.5,
      idealPhMin: 6.0,
      idealPhMax: 7.5,
      soilType: 'Tınlı, derin, kireçli',
      nitrogenKgDekar: 8.0,
      phosphorusKgDekar: 6.0,
      potassiumKgDekar: 5.0,
      fertilizationNote: 'Taban: tüm P,K + 1/2 N. Üst: V6-V8\'de 1/2 N.',
      totalIrrigationCount: 3,
      seasonalWaterMm: 550,
      harvestMonths: 'Ağustos - Eylül',
      daysToHarvest: 120,
      avgYieldKgDekar: 220,
    ),
    'pamuk': TagemTechnicalSpec(
      cropTr: 'Pamuk',
      scientificName: 'Gossypium hirsutum L.',
      tagemDocRef: 'TAGEM Pamuk Tarımı Teknik Talimatı',
      publishedYear: '2020',
      sowingMonths: 'Nisan - Mayıs',
      sowingDepthCm: 4.0,
      rowSpacingCm: 70.0,
      plantSpacingCm: 15.0,
      seedRateKgPerDekar: 2.0,
      idealPhMin: 6.5,
      idealPhMax: 8.0,
      soilType: 'Derin, kumlu-tınlı, tuzluluğa orta dayanıklı',
      nitrogenKgDekar: 15.0,
      phosphorusKgDekar: 8.0,
      potassiumKgDekar: 6.0,
      fertilizationNote: 'Taban: tüm P,K + 1/3 N. Üst: çiçeklenme öncesi 1/3 N, koza tutumunda 1/3 N.',
      totalIrrigationCount: 6,
      seasonalWaterMm: 750,
      harvestMonths: 'Eylül - Kasım',
      daysToHarvest: 180,
      avgYieldKgDekar: 450,
    ),
    'domates': TagemTechnicalSpec(
      cropTr: 'Domates (açık tarla)',
      scientificName: 'Solanum lycopersicum L.',
      tagemDocRef: 'TAGEM Domates Yetiştiriciliği Teknik Talimatı',
      publishedYear: '2018',
      sowingMonths: 'Mart - Nisan (fide), Mayıs (tarla dikim)',
      sowingDepthCm: 1.0,
      rowSpacingCm: 100.0,
      plantSpacingCm: 50.0,
      seedRateKgPerDekar: 0.05,
      idealPhMin: 6.0,
      idealPhMax: 6.8,
      soilType: 'Tınlı, organik maddece zengin, drenajlı',
      nitrogenKgDekar: 22.0,
      phosphorusKgDekar: 12.0,
      potassiumKgDekar: 25.0,
      fertilizationNote: 'Taban: tüm P + 1/3 N + 1/3 K. Üst: çiçek + meyve döneminde 2 eşit doz.',
      totalIrrigationCount: 12,
      seasonalWaterMm: 600,
      harvestMonths: 'Temmuz - Ekim',
      daysToHarvest: 110,
      avgYieldKgDekar: 6500,
    ),
    'patates': TagemTechnicalSpec(
      cropTr: 'Patates',
      scientificName: 'Solanum tuberosum L.',
      tagemDocRef: 'TAGEM Patates Tarımı Teknik Talimatı',
      publishedYear: '2019',
      sowingMonths: 'Mart - Nisan',
      sowingDepthCm: 8.0,
      rowSpacingCm: 70.0,
      plantSpacingCm: 30.0,
      seedRateKgPerDekar: 250.0,
      idealPhMin: 5.5,
      idealPhMax: 6.5,
      soilType: 'Hafif tınlı, kumlu-tınlı, asit eğilimli',
      nitrogenKgDekar: 18.0,
      phosphorusKgDekar: 10.0,
      potassiumKgDekar: 20.0,
      fertilizationNote: 'Taban: tüm P,K + 1/2 N. Üst: boğaz doldurmada 1/2 N.',
      totalIrrigationCount: 6,
      seasonalWaterMm: 500,
      harvestMonths: 'Temmuz - Eylül',
      daysToHarvest: 110,
      avgYieldKgDekar: 2800,
    ),
    'şekerpancarı': TagemTechnicalSpec(
      cropTr: 'Şeker Pancarı',
      scientificName: 'Beta vulgaris L.',
      tagemDocRef: 'TAGEM Şeker Pancarı Tarımı Teknik Talimatı',
      publishedYear: '2019',
      sowingMonths: 'Mart - Nisan',
      sowingDepthCm: 3.0,
      rowSpacingCm: 45.0,
      plantSpacingCm: 18.0,
      seedRateKgPerDekar: 1.0,
      idealPhMin: 6.5,
      idealPhMax: 7.5,
      soilType: 'Derin, tınlı, kireçli, organik',
      nitrogenKgDekar: 18.0,
      phosphorusKgDekar: 10.0,
      potassiumKgDekar: 12.0,
      fertilizationNote: 'Taban: tüm P,K + 1/2 N. Üst: 4-6 yapraklı dönemde 1/2 N.',
      totalIrrigationCount: 8,
      seasonalWaterMm: 700,
      harvestMonths: 'Eylül - Kasım',
      daysToHarvest: 200,
      avgYieldKgDekar: 5500,
    ),
    'nohut': TagemTechnicalSpec(
      cropTr: 'Nohut',
      scientificName: 'Cicer arietinum L.',
      tagemDocRef: 'TAGEM Nohut Tarımı Teknik Talimatı',
      publishedYear: '2018',
      sowingMonths: 'Mart - Nisan (yazlık), Kasım (kışlık güneyde)',
      sowingDepthCm: 5.0,
      rowSpacingCm: 35.0,
      plantSpacingCm: 10.0,
      seedRateKgPerDekar: 12.0,
      idealPhMin: 6.0,
      idealPhMax: 8.0,
      soilType: 'Tınlı-killi, kireçli, kuraklığa dayanıklı',
      nitrogenKgDekar: 3.0,
      phosphorusKgDekar: 6.0,
      potassiumKgDekar: 0.0,
      fertilizationNote: 'Baklagil olduğu için N az; rhizobium aşılaması önerilir. Tüm P taban.',
      totalIrrigationCount: 1,
      seasonalWaterMm: 350,
      harvestMonths: 'Temmuz',
      daysToHarvest: 110,
      avgYieldKgDekar: 130,
    ),
    'mercimek': TagemTechnicalSpec(
      cropTr: 'Kırmızı Mercimek',
      scientificName: 'Lens culinaris Medik.',
      tagemDocRef: 'TAGEM Mercimek Tarımı Teknik Talimatı',
      publishedYear: '2018',
      sowingMonths: 'Kasım - Aralık (kışlık), Mart (yazlık)',
      sowingDepthCm: 4.0,
      rowSpacingCm: 17.0,
      plantSpacingCm: 3.0,
      seedRateKgPerDekar: 12.0,
      idealPhMin: 6.0,
      idealPhMax: 8.0,
      soilType: 'Tınlı, drenajlı, hafif kireçli',
      nitrogenKgDekar: 2.0,
      phosphorusKgDekar: 5.0,
      potassiumKgDekar: 0.0,
      fertilizationNote: 'Baklagil — N gerekmez. Tüm P taban gübresi.',
      totalIrrigationCount: 0,
      seasonalWaterMm: 320,
      harvestMonths: 'Haziran',
      daysToHarvest: 180,
      avgYieldKgDekar: 140,
    ),
    'çeltik': TagemTechnicalSpec(
      cropTr: 'Çeltik (pirinç)',
      scientificName: 'Oryza sativa L.',
      tagemDocRef: 'TAGEM Çeltik Tarımı Teknik Talimatı',
      publishedYear: '2019',
      sowingMonths: 'Mayıs - Haziran',
      sowingDepthCm: 0.0,
      rowSpacingCm: 0.0,
      plantSpacingCm: 0.0,
      seedRateKgPerDekar: 22.0,
      idealPhMin: 5.5,
      idealPhMax: 7.0,
      soilType: 'Killi, su tutan, drenajsız (su tavası)',
      nitrogenKgDekar: 14.0,
      phosphorusKgDekar: 7.0,
      potassiumKgDekar: 5.0,
      fertilizationNote: 'Taban: tüm P,K + 1/2 N. Üst: kardeşlenmede 1/2 N.',
      totalIrrigationCount: 0,
      seasonalWaterMm: 1500,
      harvestMonths: 'Eylül - Ekim',
      daysToHarvest: 140,
      avgYieldKgDekar: 800,
    ),
  };

  /// Bitki adına göre TAGEM teknik talimatını döndürür (fuzzy arama).
  static TagemTechnicalSpec? lookup(String cropTr) {
    final key = cropTr.toLowerCase().trim();
    if (specs.containsKey(key)) return specs[key];
    for (final entry in specs.entries) {
      if (key.contains(entry.key) || entry.key.contains(key)) {
        return entry.value;
      }
    }
    return null;
  }

  /// Tüm bitkiler için liste — UI'da göstermek için.
  static List<TagemTechnicalSpec> get all => specs.values.toList();
}
