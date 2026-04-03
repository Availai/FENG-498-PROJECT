/// Agri-Matrix — Anadolu Tohum Kütüphanesi Modelleri
/// Türkiye'ye özgü bitki çeşitleri ve fenolojik büyüme verileri
library;

// ─────────────────────────────────────────────────────────────────────────────
// BÖLGE SINIFLANDIRMASI
// ─────────────────────────────────────────────────────────────────────────────

enum TurkishRegion {
  trakya,
  icAnadolu,
  ege,
  akdeniz,
  karadeniz,
  doguAnadolu,
  guneydoguAnadolu,
}

extension TurkishRegionLabel on TurkishRegion {
  String get label {
    switch (this) {
      case TurkishRegion.trakya:           return 'Trakya';
      case TurkishRegion.icAnadolu:        return 'İç Anadolu';
      case TurkishRegion.ege:              return 'Ege';
      case TurkishRegion.akdeniz:          return 'Akdeniz';
      case TurkishRegion.karadeniz:        return 'Karadeniz';
      case TurkishRegion.doguAnadolu:      return 'Doğu Anadolu';
      case TurkishRegion.guneydoguAnadolu: return 'Güneydoğu Anadolu';
    }
  }

  double yieldMultiplier(String cropTr) {
    const table = <String, Map<String, double>>{
      'trakya':           {'buğday':1.15,'ayçiçeği':1.20,'mısır':0.95,'arpa':1.10},
      'icAnadolu':        {'buğday':1.00,'ayçiçeği':1.00,'mısır':1.05,'arpa':1.00,'nohut':1.15},
      'ege':              {'pamuk':1.20,'mısır':1.10,'buğday':0.95},
      'akdeniz':          {'pamuk':1.25,'mısır':1.15,'buğday':0.90},
      'karadeniz':        {'fındık':1.40,'mısır':1.05,'buğday':0.85},
      'doguAnadolu':      {'buğday':0.80,'arpa':0.85},
      'guneydoguAnadolu': {'buğday':0.90,'pamuk':1.10,'kırmızı mercimek':1.20},
    };
    return table[name]?[cropTr] ?? 1.0;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FENOLOJİ EVRELERİ
// ─────────────────────────────────────────────────────────────────────────────

enum PhenologyStage {
  cimlenme,     // Çimlenme — Germination
  cikis,        // Çıkış — Emergence
  vejetatif,    // Vejetatif büyüme — Vegetative
  ciceklenme,   // Çiçeklenme — Flowering
  dolum,        // Dolum (Süt/hamur) — Grain/fruit fill
  olgunluk,     // Fizyolojik olgunluk — Physiological maturity
  hasat,        // Hasat olgunluğu — Harvest readiness
}

extension PhenologyStageMeta on PhenologyStage {
  String get labelTr {
    const m = {
      PhenologyStage.cimlenme:   'Çimlenme',
      PhenologyStage.cikis:      'Çıkış',
      PhenologyStage.vejetatif:  'Vejetatif',
      PhenologyStage.ciceklenme: 'Çiçeklenme',
      PhenologyStage.dolum:      'Dolum',
      PhenologyStage.olgunluk:   'Olgunluk',
      PhenologyStage.hasat:      'Hasat',
    };
    return m[this]!;
  }

  String get icon {
    const m = {
      PhenologyStage.cimlenme:   '🌱',
      PhenologyStage.cikis:      '🌿',
      PhenologyStage.vejetatif:  '🌾',
      PhenologyStage.ciceklenme: '🌸',
      PhenologyStage.dolum:      '🍃',
      PhenologyStage.olgunluk:   '🌾',
      PhenologyStage.hasat:      '🚜',
    };
    return m[this]!;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FENOLOJİ EVRE TANIMI
// ─────────────────────────────────────────────────────────────────────────────

class PhenologyStageDef {
  final PhenologyStage stage;
  final int baseDurationDays;    // Optimum koşulda süre
  final double minTempC;         // Bu evreye geçiş için min sıcaklık
  final double maxTempC;
  final double optTempC;         // Optimum sıcaklık
  final double requiredGdd;      // Bu evre için gerekli GDD (büyüme gün-derece)
  final String careNote;         // Bakım notu

  const PhenologyStageDef({
    required this.stage,
    required this.baseDurationDays,
    required this.minTempC,
    required this.maxTempC,
    required this.optTempC,
    required this.requiredGdd,
    required this.careNote,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// TOHUM ÇEŞİDİ
// ─────────────────────────────────────────────────────────────────────────────

class SeedVariety {
  final String id;
  final String nameTr;
  final String cropTr;
  final String breeder;                      // Islahçı kuruluş
  final int registrationYear;
  final List<TurkishRegion> suitableRegions;
  final List<PhenologyStageDef> phenology;
  final double avgYieldKgDekar;
  final double maxYieldKgDekar;
  final double droughtTolerance;             // 0.0–1.0
  final double frostTolerance;               // 0.0–1.0
  final double diseaseResistance;            // 0.0–1.0 (genel)
  final double salinityTolerance;            // 0.0–1.0
  final String soilSuitability;              // 'Killi-tınlı, drenajlı...'
  final double idealPhMin;
  final double idealPhMax;
  final String notes;                        // Özellikler / avantajlar
  final String? imageAsset;                  // assets path

  const SeedVariety({
    required this.id,
    required this.nameTr,
    required this.cropTr,
    required this.breeder,
    required this.registrationYear,
    required this.suitableRegions,
    required this.phenology,
    required this.avgYieldKgDekar,
    required this.maxYieldKgDekar,
    required this.droughtTolerance,
    required this.frostTolerance,
    required this.diseaseResistance,
    required this.salinityTolerance,
    required this.soilSuitability,
    required this.idealPhMin,
    required this.idealPhMax,
    required this.notes,
    this.imageAsset,
  });

  int get totalDaysToHarvest =>
      phenology.fold(0, (sum, s) => sum + s.baseDurationDays);

  double get totalGddRequired =>
      phenology.fold(0.0, (sum, s) => sum + s.requiredGdd);

  /// Kümülatif gün sayısı — belirli evreye kadar
  int daysUntilStageStart(PhenologyStage target) {
    int days = 0;
    for (final s in phenology) {
      if (s.stage == target) return days;
      days += s.baseDurationDays;
    }
    return days;
  }

  String get resistanceLabel {
    final avg = (droughtTolerance + frostTolerance + diseaseResistance) / 3;
    if (avg >= 0.8) return 'Çok Yüksek';
    if (avg >= 0.65) return 'Yüksek';
    if (avg >= 0.50) return 'Orta';
    return 'Düşük';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SİMÜLASYON ÇIKTILARI
// ─────────────────────────────────────────────────────────────────────────────

class GrowthDayRecord {
  final int dayNumber;
  final PhenologyStage stage;
  final double accumulatedGdd;
  final double heightCm;           // Tahmini boy (cm)
  final double biomassRelative;    // 0.0–1.0
  final double stressIndex;        // 0.0 (stres yok) → 1.0 (kritik stres)
  final String? event;             // 'İlk çiçek açtı', 'Don riski!' vs.

  const GrowthDayRecord({
    required this.dayNumber,
    required this.stage,
    required this.accumulatedGdd,
    required this.heightCm,
    required this.biomassRelative,
    required this.stressIndex,
    this.event,
  });
}

class SimulationResult {
  final SeedVariety variety;
  final DateTime sowDate;
  final DateTime estimatedHarvestDate;
  final List<GrowthDayRecord> dailyRecords;
  final Map<PhenologyStage, DateTime> stageDates;
  final double predictedYieldKgDekar;   // Gerçek hava verisine göre ayarlı verim

  const SimulationResult({
    required this.variety,
    required this.sowDate,
    required this.estimatedHarvestDate,
    required this.dailyRecords,
    required this.stageDates,
    required this.predictedYieldKgDekar,
  });

  PhenologyStage get currentStage {
    final today = DateTime.now();
    PhenologyStage last = PhenologyStage.cimlenme;
    stageDates.forEach((stage, date) {
      if (!today.isBefore(date)) last = stage;
    });
    return last;
  }

  int get daysFromSow => DateTime.now().difference(sowDate).inDays;

  double get progressPercent =>
      (daysFromSow / variety.totalDaysToHarvest).clamp(0.0, 1.0);
}
