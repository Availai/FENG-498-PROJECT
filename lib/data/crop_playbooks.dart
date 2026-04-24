/// Üç vitrin bitki için yapısal ilaç + gübre kataloğu.
///
/// `crop_protocols.dart` tam reçete prose'u içerir (adım adım yetiştirme). Bu
/// dosya ise çiftçinin "İlaçladım/Gübreledim" loglarında gerçek ticari ürün
/// + etken madde + doz bilgisiyle hızlı seçim yapabilmesi için strüktüre
/// edilmiş bir API sunar. Protokol prose'unda geçen ürünler buraya kalem kalem
/// aktarıldı — tek kaynak ama iki format.
library;

import 'supported_crops.dart';

// ═══════════════════════════════════════════════════════════════════════════
// GÜBRE KATALOĞU
// ═══════════════════════════════════════════════════════════════════════════

/// Gübre ürünü — çiftçinin log'una düşürebileceği seçenek.
class FertilizerProduct {
  /// Ticari / genel ad (ör. "DAP 18-46-0", "Üre %46 N", "Kalsiyum Nitrat").
  final String name;

  /// Kimyasal formül / NPK oranı — UI'da etiket olarak gösterilir.
  final String formula;

  /// Önerilen doz (kg veya L / dekar). Çiftçi dialog'da ayarlayabilir.
  final double defaultDosePerDa;

  /// Birim — 'kg' veya 'L'.
  final String unit;

  /// Uygulama aşaması (kullanıcıya rehber amaçlı).
  final String stage;

  /// Çiftçiye kısa pratik not.
  final String? tip;

  const FertilizerProduct({
    required this.name,
    required this.formula,
    required this.defaultDosePerDa,
    required this.unit,
    required this.stage,
    this.tip,
  });
}

// ═══════════════════════════════════════════════════════════════════════════
// İLAÇ KATALOĞU
// ═══════════════════════════════════════════════════════════════════════════

/// İlaç kategorisi — filtre amaçlı.
enum PesticideCategory { herbicide, fungicide, insecticide, acaricide }

extension PesticideCategoryLabel on PesticideCategory {
  String get label => switch (this) {
        PesticideCategory.herbicide => 'Herbisit (yabancı ot)',
        PesticideCategory.fungicide => 'Fungusit (mantar)',
        PesticideCategory.insecticide => 'İnsektisit (böcek)',
        PesticideCategory.acaricide => 'Akarisit (akar/örümcek)',
      };
}

/// İlaç ürünü — çiftçinin log'una düşürebileceği seçenek.
class PesticideProduct {
  /// Ticari veya jenerik ad (ör. "Fusilade Forte", "Bakır Oksiklorür").
  final String name;

  /// Etken madde — rotasyon için kritik (aynı etken arka arkaya kullanılmaz).
  final String activeIngredient;

  final PesticideCategory category;

  /// Hedef zararlı/hastalık listesi (Türkçe).
  final List<String> targets;

  /// Önerilen doz (mL veya g / dekar).
  final double defaultDosePerDa;

  /// Birim — 'mL' veya 'g'.
  final String unit;

  /// Tavsiye edilen 200 L su / dekar çözeltisi — standart sulandırma.
  final double dilutionWaterLPerDa;

  /// Son ilaçlama ile hasat arası zorunlu gün (preharvest interval).
  final int preharvestIntervalDays;

  /// Çiftçiye kısa pratik not.
  final String? tip;

  const PesticideProduct({
    required this.name,
    required this.activeIngredient,
    required this.category,
    required this.targets,
    required this.defaultDosePerDa,
    required this.unit,
    this.dilutionWaterLPerDa = 200,
    this.preharvestIntervalDays = 14,
    this.tip,
  });
}

// ═══════════════════════════════════════════════════════════════════════════
// SULAMA REHBERİ — evreye göre mm/hafta
// ═══════════════════════════════════════════════════════════════════════════

class WaterGuideBand {
  /// Ekimden itibaren gün aralığı (dahil).
  final int dayFrom;
  final int dayTo;

  /// Haftalık toplam mm (tarla bazında, dekar nötr).
  final int weeklyMm;

  /// Faz adı — UI etiketi.
  final String stage;

  const WaterGuideBand({
    required this.dayFrom,
    required this.dayTo,
    required this.weeklyMm,
    required this.stage,
  });
}

// ═══════════════════════════════════════════════════════════════════════════
// AYÇIÇEĞİ
// ═══════════════════════════════════════════════════════════════════════════

const _aycicegiFertilizers = <FertilizerProduct>[
  FertilizerProduct(
    name: 'DAP (Taban)',
    formula: '18-46-0',
    defaultDosePerDa: 15,
    unit: 'kg',
    stage: 'Ekim (taban gübre)',
    tip: 'Tohumun 5 cm yanına ve altına uygula — teması kökü yakar.',
  ),
  FertilizerProduct(
    name: 'Potasyum Sülfat',
    formula: 'K₂SO₄',
    defaultDosePerDa: 5,
    unit: 'kg',
    stage: 'Ekim (taban gübre)',
  ),
  FertilizerProduct(
    name: 'Üre (1. Üst Gübre)',
    formula: '%46 N',
    defaultDosePerDa: 12,
    unit: 'kg',
    stage: '25. gün — ilk çapa',
    tip: 'Serpimden sonra 6 saat içinde sula, yoksa %30 azot uçar.',
  ),
  FertilizerProduct(
    name: 'DAP (2. Üst Gübre)',
    formula: '18-46-0',
    defaultDosePerDa: 8,
    unit: 'kg',
    stage: '60. gün — tabla oluşumu',
    tip: 'MAP (12-61-0) 6 kg/da alternatif kullanılabilir.',
  ),
];

const _aycicegiPesticides = <PesticideProduct>[
  PesticideProduct(
    name: 'Fusilade Forte',
    activeIngredient: 'Fluazifop-P-butyl',
    category: PesticideCategory.herbicide,
    targets: ['Dar yapraklı yabancı ot', 'Ayrık otu', 'Yabani yulaf'],
    defaultDosePerDa: 112, // 100–125 mL ortalaması
    unit: 'mL',
    preharvestIntervalDays: 60,
    tip: 'Sabah çiğ kalktıktan 2 saat sonra, 08:00–11:00 arası uygula.',
  ),
  PesticideProduct(
    name: 'Scepter O.T.',
    activeIngredient: 'Imazethapyr',
    category: PesticideCategory.herbicide,
    targets: ['Geniş yapraklı yabancı ot', 'Sirken', 'Horoz ibiği'],
    defaultDosePerDa: 50,
    unit: 'mL',
    preharvestIntervalDays: 60,
  ),
  PesticideProduct(
    name: 'Tebuconazole SC',
    activeIngredient: 'Tebuconazole %25',
    category: PesticideCategory.fungicide,
    targets: ['Mildiyö', 'Pas'],
    defaultDosePerDa: 70, // 60–80
    unit: 'mL',
    preharvestIntervalDays: 30,
    tip: 'Bitki 30–40 cm boyunda, yağmur sonrası 48 saat içinde uygula.',
  ),
  PesticideProduct(
    name: 'Propiconazole EC',
    activeIngredient: 'Propiconazole %25',
    category: PesticideCategory.fungicide,
    targets: ['Kurşuni küf', 'Tabla çürüklüğü'],
    defaultDosePerDa: 55, // 50–60
    unit: 'mL',
    preharvestIntervalDays: 30,
  ),
  PesticideProduct(
    name: 'Iprodione WP',
    activeIngredient: 'Iprodione %50',
    category: PesticideCategory.fungicide,
    targets: ['Botrytis (tabla çürüklüğü)'],
    defaultDosePerDa: 125, // 100–150
    unit: 'g',
    preharvestIntervalDays: 21,
    tip: 'Çiçeklenme döneminde 10 günde bir, tablayı da ıslat.',
  ),
];

const _aycicegiWater = <WaterGuideBand>[
  WaterGuideBand(dayFrom: 0, dayTo: 14, weeklyMm: 20, stage: 'Çimlenme'),
  WaterGuideBand(dayFrom: 15, dayTo: 44, weeklyMm: 35, stage: 'İlk gelişme'),
  WaterGuideBand(dayFrom: 45, dayTo: 74, weeklyMm: 55, stage: 'Vejetatif'),
  WaterGuideBand(dayFrom: 75, dayTo: 99, weeklyMm: 65, stage: 'Çiçeklenme'),
  WaterGuideBand(dayFrom: 100, dayTo: 120, weeklyMm: 15, stage: 'Olgunlaşma (suyu kes)'),
];

// ═══════════════════════════════════════════════════════════════════════════
// MISIR
// ═══════════════════════════════════════════════════════════════════════════

const _misirFertilizers = <FertilizerProduct>[
  FertilizerProduct(
    name: 'DAP (Taban)',
    formula: '18-46-0',
    defaultDosePerDa: 20,
    unit: 'kg',
    stage: 'Ekim (taban gübre)',
    tip: 'Mısırın fosfor talebi yüksek — DAP atlanmaz.',
  ),
  FertilizerProduct(
    name: 'Potasyum Sülfat',
    formula: 'K₂SO₄',
    defaultDosePerDa: 8,
    unit: 'kg',
    stage: 'Ekim (taban gübre)',
  ),
  FertilizerProduct(
    name: 'Çinko Sülfat',
    formula: 'ZnSO₄',
    defaultDosePerDa: 2,
    unit: 'kg',
    stage: 'Ekim (taban gübre)',
    tip: 'Mısır çinko eksikliğine çok duyarlı — solgun beyaz şerit belirtisi.',
  ),
  FertilizerProduct(
    name: 'Üre (1. Üst Gübre)',
    formula: '%46 N',
    defaultDosePerDa: 18,
    unit: 'kg',
    stage: '25–30. gün — 6–8 yaprak',
    tip: 'Toplam azotun %40\'ı bu dönem, kalanı püsküllenmede.',
  ),
  FertilizerProduct(
    name: 'Üre (2. Üst Gübre)',
    formula: '%46 N',
    defaultDosePerDa: 22,
    unit: 'kg',
    stage: '55. gün — püsküllenme öncesi',
    tip: 'Su ile ver — gazlaşma kaybı önlenir.',
  ),
];

const _misirPesticides = <PesticideProduct>[
  PesticideProduct(
    name: 'Adengo',
    activeIngredient: 'Thiencarbazone-methyl + Isoxaflutole',
    category: PesticideCategory.herbicide,
    targets: ['Geniş yapraklı otlar', 'Tek yıllık dar yapraklılar'],
    defaultDosePerDa: 30,
    unit: 'mL',
    preharvestIntervalDays: 90,
    tip: 'Ekim sonrası çıkış öncesi uygulama (pre-emergence).',
  ),
  PesticideProduct(
    name: 'Callisto',
    activeIngredient: 'Mesotrione %48',
    category: PesticideCategory.herbicide,
    targets: ['Horoz ibiği', 'Sirken', 'Köpek dişi'],
    defaultDosePerDa: 25,
    unit: 'mL',
    preharvestIntervalDays: 60,
  ),
  PesticideProduct(
    name: 'Coragen',
    activeIngredient: 'Chlorantraniliprole %20',
    category: PesticideCategory.insecticide,
    targets: ['Mısır koçan kurdu', 'Çizgili yaprak kurdu', 'Sonbahar ordu kurdu'],
    defaultDosePerDa: 15,
    unit: 'mL',
    preharvestIntervalDays: 14,
    tip: 'Püsküllenme başında püskürt — larva koçana girmeden önce.',
  ),
  PesticideProduct(
    name: 'Karate Zeon',
    activeIngredient: 'Lambda-cyhalothrin %5',
    category: PesticideCategory.insecticide,
    targets: ['Yaprak biti', 'Thrips', 'Yeşil kurt'],
    defaultDosePerDa: 25,
    unit: 'mL',
    preharvestIntervalDays: 14,
  ),
  PesticideProduct(
    name: 'Ridomil Gold',
    activeIngredient: 'Mancozeb + Metalaxyl',
    category: PesticideCategory.fungicide,
    targets: ['Yaprak yanıklığı', 'Koçan çürüklüğü'],
    defaultDosePerDa: 250,
    unit: 'g',
    preharvestIntervalDays: 21,
  ),
];

const _misirWater = <WaterGuideBand>[
  WaterGuideBand(dayFrom: 0, dayTo: 14, weeklyMm: 25, stage: 'Çimlenme'),
  WaterGuideBand(dayFrom: 15, dayTo: 39, weeklyMm: 35, stage: 'Fide'),
  WaterGuideBand(dayFrom: 40, dayTo: 59, weeklyMm: 50, stage: 'Hızlı vejetatif'),
  WaterGuideBand(dayFrom: 60, dayTo: 79, weeklyMm: 75, stage: 'Püsküllenme + koçan (KRİTİK)'),
  WaterGuideBand(dayFrom: 80, dayTo: 99, weeklyMm: 55, stage: 'Dane dolumu'),
  WaterGuideBand(dayFrom: 100, dayTo: 110, weeklyMm: 15, stage: 'Olgunlaşma (suyu kes)'),
];

// ═══════════════════════════════════════════════════════════════════════════
// DOMATES
// ═══════════════════════════════════════════════════════════════════════════

const _domatesFertilizers = <FertilizerProduct>[
  FertilizerProduct(
    name: 'Yanmış Ahır Gübresi',
    formula: 'Organik',
    defaultDosePerDa: 2000, // 2 ton = 2000 kg
    unit: 'kg',
    stage: 'Dikim öncesi (toprağa karıştır)',
    tip: 'Taze gübre kök yakar — en az 6 ay yanmış olmalı.',
  ),
  FertilizerProduct(
    name: 'Kompoze 15-15-15 (Dikim)',
    formula: '15-15-15',
    defaultDosePerDa: 10,
    unit: 'kg',
    stage: 'Dikim çukuru (kökten 5 cm altına)',
  ),
  FertilizerProduct(
    name: 'Kompoze 15-15-15 (1. Üst)',
    formula: '15-15-15',
    defaultDosePerDa: 15,
    unit: 'kg',
    stage: '21. gün — ilk çapa',
    tip: 'Bitki başına ≈ 25–30 g, kök boğazından 10 cm uzağa.',
  ),
  FertilizerProduct(
    name: 'Kalsiyum Nitrat',
    formula: 'Ca(NO₃)₂',
    defaultDosePerDa: 10,
    unit: 'kg',
    stage: 'Çiçeklenme boyunca haftalık',
    tip: 'Çiçek burnu çürüklüğü (BER) önleyici — atlatma!',
  ),
  FertilizerProduct(
    name: 'Potasyum Nitrat',
    formula: 'KNO₃',
    defaultDosePerDa: 8,
    unit: 'kg',
    stage: 'Meyve dolumu',
    tip: 'Meyve kalitesi + Brix değeri için.',
  ),
];

const _domatesPesticides = <PesticideProduct>[
  PesticideProduct(
    name: 'Ridomil Gold',
    activeIngredient: 'Mancozeb + Metalaxyl',
    category: PesticideCategory.fungicide,
    targets: ['Mildiyö (Phytophthora infestans)', 'Erken yaprak yanıklığı'],
    defaultDosePerDa: 225, // 200–250
    unit: 'g',
    preharvestIntervalDays: 14,
    tip: 'Yağmurdan 48 saat önce koruyucu olarak uygula.',
  ),
  PesticideProduct(
    name: 'Bakır Oksiklorür WP',
    activeIngredient: 'Bakır Oksiklorür %50',
    category: PesticideCategory.fungicide,
    targets: ['Mildiyö', 'Bakteriyel leke', 'Siyah çürüklük'],
    defaultDosePerDa: 275, // 250–300
    unit: 'g',
    preharvestIntervalDays: 7,
    tip: 'Organik tarımda da izinli — 7–10 günde bir.',
  ),
  PesticideProduct(
    name: 'Ortiva',
    activeIngredient: 'Azoxystrobin %25',
    category: PesticideCategory.fungicide,
    targets: ['Külleme', 'Alternaria', 'Antraknoz'],
    defaultDosePerDa: 80,
    unit: 'mL',
    preharvestIntervalDays: 3,
    tip: 'Erken külleme belirtisinde 10 günde bir.',
  ),
  PesticideProduct(
    name: 'Abamectin EC',
    activeIngredient: 'Abamectin %1.8',
    category: PesticideCategory.acaricide,
    targets: ['Kırmızı örümcek', 'Yaprak galeri sineği'],
    defaultDosePerDa: 75,
    unit: 'mL',
    preharvestIntervalDays: 7,
  ),
  PesticideProduct(
    name: 'Movento',
    activeIngredient: 'Spirotetramat %15',
    category: PesticideCategory.insecticide,
    targets: ['Beyaz sinek', 'Yaprak biti', 'Trips'],
    defaultDosePerDa: 60,
    unit: 'mL',
    preharvestIntervalDays: 3,
  ),
  PesticideProduct(
    name: 'Floramite',
    activeIngredient: 'Bifenazate %24',
    category: PesticideCategory.acaricide,
    targets: ['Kırmızı örümcek', 'İki noktalı örümcek'],
    defaultDosePerDa: 70, // 60–80
    unit: 'mL',
    preharvestIntervalDays: 3,
  ),
  PesticideProduct(
    name: 'Metalaxyl Drench',
    activeIngredient: 'Metalaxyl %25',
    category: PesticideCategory.fungicide,
    targets: ['Kök çürüklüğü (Pythium)', 'Phytophthora'],
    defaultDosePerDa: 100,
    unit: 'g',
    preharvestIntervalDays: 21,
    tip: 'Dikim sonrası sulama suyuna karıştırıp kök bölgesine ver.',
  ),
];

const _domatesWater = <WaterGuideBand>[
  WaterGuideBand(dayFrom: 0, dayTo: 7, weeklyMm: 15, stage: 'Fide tutumu (can suyu)'),
  WaterGuideBand(dayFrom: 8, dayTo: 34, weeklyMm: 30, stage: 'Vejetatif başlangıç'),
  WaterGuideBand(dayFrom: 35, dayTo: 54, weeklyMm: 45, stage: 'Hızlı büyüme'),
  WaterGuideBand(dayFrom: 55, dayTo: 69, weeklyMm: 55, stage: 'Çiçeklenme + meyve tutumu'),
  WaterGuideBand(dayFrom: 70, dayTo: 84, weeklyMm: 40, stage: 'Meyve dolumu'),
  WaterGuideBand(dayFrom: 85, dayTo: 95, weeklyMm: 25, stage: 'Hasat (sulamayı azalt)'),
];

// ═══════════════════════════════════════════════════════════════════════════
// API
// ═══════════════════════════════════════════════════════════════════════════

class CropPlaybook {
  final String cropKey;
  final String displayName;
  final List<FertilizerProduct> fertilizers;
  final List<PesticideProduct> pesticides;
  final List<WaterGuideBand> waterGuide;

  const CropPlaybook({
    required this.cropKey,
    required this.displayName,
    required this.fertilizers,
    required this.pesticides,
    required this.waterGuide,
  });

  /// Ekimden itibaren [daysSincePlanting] için önerilen haftalık mm.
  WaterGuideBand? bandForDay(int daysSincePlanting) {
    for (final b in waterGuide) {
      if (daysSincePlanting >= b.dayFrom && daysSincePlanting <= b.dayTo) {
        return b;
      }
    }
    return null;
  }
}

const _aycicegi = CropPlaybook(
  cropKey: 'aycicegi',
  displayName: 'Ayçiçeği',
  fertilizers: _aycicegiFertilizers,
  pesticides: _aycicegiPesticides,
  waterGuide: _aycicegiWater,
);

const _misir = CropPlaybook(
  cropKey: 'misir',
  displayName: 'Mısır',
  fertilizers: _misirFertilizers,
  pesticides: _misirPesticides,
  waterGuide: _misirWater,
);

const _domates = CropPlaybook(
  cropKey: 'domates',
  displayName: 'Domates',
  fertilizers: _domatesFertilizers,
  pesticides: _domatesPesticides,
  waterGuide: _domatesWater,
);

class CropPlaybooks {
  CropPlaybooks._();

  static const all = <CropPlaybook>[_aycicegi, _misir, _domates];

  /// Bitki adından (serbest yazılmış olsa bile) playbook'u bulur.
  /// [SupportedCrops.canonicalName] kullanarak normalize eder.
  static CropPlaybook? resolveByName(String? name) {
    if (name == null || name.trim().isEmpty) return null;
    final canonical = SupportedCrops.canonicalName(name);
    if (canonical == null) return null;
    final key = SupportedCrops.normalize(canonical);
    for (final p in all) {
      if (p.cropKey == key) return p;
    }
    return null;
  }
}
