/// Tarla bazlı su bilançosu motoru — sonraki sulama kararı.
///
/// FAO-56 (Allen et al., 1998) toprak su bilançosu yaklaşımı ile:
///   Soil(i+1) = Soil(i) + EffRain(i) - ETc(i)
///
/// Sonraki sulamayı, toprakta kullanılabilir suyun (RAW = p × TAW) tükendiği
/// gün olarak hesaplar. Pure function; aynı girdi → aynı çıktı (CLAUDE.md §22).
///
/// Kaynaklar:
///   - FAO-56 Crop evapotranspiration (Allen et al., 1998)
///   - USDA-SCS efektif yağış metodu
///   - `FaoEtoService` (mevcut)
///   - `WaterAccounting.methodEfficiency` (mevcut, kaynaklı)
library;

import '../data/crop_protocols.dart' show SoilType;
import 'fao_eto_service.dart';
import 'soil_irrigation_advisor.dart';
import 'water_accounting.dart';

class DailyForecast {
  final DateTime date;
  final double tMaxC;
  final double tMinC;
  final double rhMaxPct;
  final double rhMinPct;
  final double windMs;
  final double precipMm;

  const DailyForecast({
    required this.date,
    required this.tMaxC,
    required this.tMinC,
    required this.rhMaxPct,
    required this.rhMinPct,
    required this.windMs,
    required this.precipMm,
  });
}

class WaterBalanceFacts {
  final String cropNameTr;
  final DateTime? plantedDate;
  final int? totalSeasonDays;
  final double areaDekar;
  final SoilType soilType;
  final String irrigationMethod;
  final double currentSoilMoistureMm; // null/0 → varsayılan: FC'nin yarısı
  final List<DailyForecast> forecast;
  final double latitudeDeg;
  final double elevationM;

  /// Laboratuvar toprak analizinden türetilen sulama profili (opsiyonel).
  /// Verilirse: organik madde → tarla su kapasitesi düzeltmesi, tuzluluk →
  /// yıkama (leaching) suyu brüt litreye eklenir. **null ise çıktı bugünküyle
  /// birebir aynıdır** (geriye dönük uyumlu, regresyon güvenli).
  final SoilIrrigationProfile? soilProfile;

  const WaterBalanceFacts({
    required this.cropNameTr,
    required this.plantedDate,
    required this.totalSeasonDays,
    required this.areaDekar,
    required this.soilType,
    required this.irrigationMethod,
    required this.currentSoilMoistureMm,
    required this.forecast,
    required this.latitudeDeg,
    required this.elevationM,
    this.soilProfile,
  });
}

class DayProjection {
  final DateTime date;
  final double etoMm;
  final double etcMm;
  final double effectiveRainMm;
  final double precipMm;
  final double soilStartMm;
  final double soilEndMm;
  final bool needsIrrigation;
  final double recommendedDoseMm;

  const DayProjection({
    required this.date,
    required this.etoMm,
    required this.etcMm,
    required this.effectiveRainMm,
    required this.precipMm,
    required this.soilStartMm,
    required this.soilEndMm,
    required this.needsIrrigation,
    required this.recommendedDoseMm,
  });
}

class WaterBalanceResult {
  final double currentSoilMm;
  final double fieldCapacityMm;
  final double rawThresholdMm; // bu seviyenin altına düşerse sula
  final double todayEtcMm;
  final double effectiveRainNext7DaysMm;
  final DateTime? nextIrrigationDate;
  final double recommendedDoseMm;
  final double recommendedDoseLiters; // mm × m² alan
  final double recommendedGrossLiters; // yöntem verimine bölünmüş
  final String stageLabel;
  final double kcUsed;
  final List<DayProjection> projections;

  const WaterBalanceResult({
    required this.currentSoilMm,
    required this.fieldCapacityMm,
    required this.rawThresholdMm,
    required this.todayEtcMm,
    required this.effectiveRainNext7DaysMm,
    required this.nextIrrigationDate,
    required this.recommendedDoseMm,
    required this.recommendedDoseLiters,
    required this.recommendedGrossLiters,
    required this.stageLabel,
    required this.kcUsed,
    required this.projections,
  });

  int? get daysUntilIrrigation {
    if (nextIrrigationDate == null) return null;
    final today = DateTime.now();
    final base = DateTime(today.year, today.month, today.day);
    return nextIrrigationDate!.difference(base).inDays;
  }
}

class WaterBalanceEngine {
  const WaterBalanceEngine();

  /// Toprak su tutma kapasitesi (mm) — kök derinliği ~600 mm varsayımıyla.
  /// FAO-56 Tablo 19 değerleri × kök derinliği.
  ///   loamy  ≈ 0.20 mm/mm × 600 = 120 mm
  ///   clay   ≈ 0.30 mm/mm × 600 = 180 mm (ama bitkinin alabileceği daha az)
  ///   sandy  ≈ 0.10 mm/mm × 600 =  60 mm
  ///   volcanic≈ 0.22 mm/mm × 600 = 132 mm
  static double fieldCapacityMm(SoilType soil) {
    switch (soil) {
      case SoilType.sandy:
        return 60;
      case SoilType.loamy:
        return 120;
      case SoilType.clay:
        return 180;
      case SoilType.volcanic:
        return 132;
    }
  }

  /// FAO-56 p faktörü — bitkinin stres yaşamadan tüketebileceği TAW oranı.
  /// Tipik 0.4-0.65. Sebze 0.40, mısır 0.55, ayçiçeği 0.45.
  /// Burada ortalama 0.50 kullanıyoruz; ileride bitki bazlı tablo eklenebilir.
  static const double _depletionFraction = 0.50;

  /// USDA-SCS efektif yağış: ilk 2mm yüzeyden buharlaşır, kalanın %80'i kök
  /// bölgesine ulaşır. Backend ile aynı varsayım (main.py).
  static double effectiveRain(double precipMm) {
    if (precipMm <= 2) return 0;
    return (precipMm - 2) * 0.80;
  }

  /// Bitki gelişim evresi etiketi (Türkçe) — Kc seçimi için.
  static ({String label, double kc}) _stageAndKc({
    required String cropNameTr,
    required DateTime? planted,
    required int? totalDays,
  }) {
    final coeffs = FaoCropCoefficients.lookup(cropNameTr);
    if (coeffs == null) {
      return (label: 'Genel', kc: 0.85);
    }
    final today = DateTime.now();
    if (planted == null) {
      return (label: 'Orta gelişim', kc: coeffs.kcMid);
    }
    final days = today.difference(planted).inDays;
    final season = totalDays ?? coeffs.totalLengthDays;
    final initFrac = 0.20;
    final midFrac = 0.70;
    final progress = (days / season).clamp(0.0, 1.0);
    if (progress < initFrac) {
      return (label: 'Başlangıç dönemi', kc: coeffs.kcInit);
    } else if (progress < midFrac) {
      return (label: 'Hızlı gelişim / orta dönem', kc: coeffs.kcMid);
    } else {
      return (label: 'Olgunlaşma / hasat sonu', kc: coeffs.kcEnd);
    }
  }

  /// Ana hesap.
  WaterBalanceResult compute(WaterBalanceFacts f) {
    // Lab analizi varsa tarla su kapasitesini organik maddeye göre rafine et;
    // yoksa çarpan 1.0 → mevcut 4-kova SoilType değeri birebir korunur.
    final fcMultiplier = f.soilProfile?.fieldCapacityMultiplier ?? 1.0;
    final fc = fieldCapacityMm(f.soilType) * fcMultiplier;
    final raw = fc * _depletionFraction; // okunabilir su miktarı
    final criticalLevel = fc - raw; // bu seviyenin altına düşmemeli

    final stageInfo = _stageAndKc(
      cropNameTr: f.cropNameTr,
      planted: f.plantedDate,
      totalDays: f.totalSeasonDays,
    );
    final kc = stageInfo.kc;

    // Başlangıç toprak nemi: kullanıcı girmemişse FC'nin %75'i (iyi sulanmış kabul).
    double soil = f.currentSoilMoistureMm > 0
        ? f.currentSoilMoistureMm.clamp(0.0, fc).toDouble()
        : fc * 0.75;

    DateTime? nextIrrigation;
    double recommendedDose = 0;
    final projections = <DayProjection>[];
    double totalEffectiveRain = 0;
    double todayEtc = 0;

    for (int i = 0; i < f.forecast.length; i++) {
      final d = f.forecast[i];
      final eto = FaoEtoService.calculateDailyEto(EToInput(
        tMaxC: d.tMaxC,
        tMinC: d.tMinC,
        rhMaxPct: d.rhMaxPct,
        rhMinPct: d.rhMinPct,
        windMs: d.windMs,
        // Forecast'te solar radyasyon olmadığı için sıcaklık aralığından
        // yaklaşık çıkarım (Hargreaves-tipi). FAO-56 Eq. 50.
        solarRadMjM2Day: FaoEtoService.estimateSolarRad(
          tMaxC: d.tMaxC,
          tMinC: d.tMinC,
          latitudeDeg: f.latitudeDeg,
          dayOfYear: _dayOfYear(d.date),
        ),
        elevationM: f.elevationM,
        latitudeDeg: f.latitudeDeg,
        dayOfYear: _dayOfYear(d.date),
      ));
      final etc = eto * kc;
      final effRain = effectiveRain(d.precipMm);
      totalEffectiveRain += effRain;
      if (i == 0) todayEtc = etc;

      final start = soil;
      // Yağış toprağı FC'nin üzerine çıkaramaz (fazlası akar/sızar).
      soil = (soil + effRain).clamp(0.0, fc).toDouble();
      soil = (soil - etc).clamp(0.0, fc).toDouble();

      final needsIrrigation = soil <= criticalLevel && nextIrrigation == null;
      double dose = 0;
      if (needsIrrigation) {
        // Toprağı FC'ye geri getirecek net mm.
        dose = fc - soil;
        recommendedDose = dose;
        nextIrrigation = d.date;
      }

      projections.add(DayProjection(
        date: d.date,
        etoMm: eto,
        etcMm: etc,
        effectiveRainMm: effRain,
        precipMm: d.precipMm,
        soilStartMm: start,
        soilEndMm: soil,
        needsIrrigation: needsIrrigation,
        recommendedDoseMm: dose,
      ));
    }

    // Sonraki sulama tahmin penceresine sığmadıysa: tahmini bir tarih bul
    // (basit doğrusal extrapolasyon, son günkü etc hızıyla).
    if (nextIrrigation == null && projections.isNotEmpty) {
      final lastEtc = projections.last.etcMm;
      if (lastEtc > 0 && soil > criticalLevel) {
        final daysLeft = ((soil - criticalLevel) / lastEtc).ceil();
        nextIrrigation = projections.last.date.add(Duration(days: daysLeft));
        recommendedDose = fc - criticalLevel;
      }
    }

    // Litre dönüşümleri
    final areaSqm = (f.areaDekar <= 0 ? 1.0 : f.areaDekar) * 1000.0;
    final netLiters = recommendedDose * areaSqm;
    final eff = WaterAccounting.methodEfficiency(f.irrigationMethod);
    // Tuzlu toprakta kök bölgesini yıkamak için ek su (FAO-29). Lab analizi
    // yoksa çarpan 1.0 → değişmez.
    final leachMultiplier = f.soilProfile?.grossWaterMultiplier ?? 1.0;
    final grossLiters =
        (eff > 0 ? netLiters / eff : netLiters) * leachMultiplier;

    return WaterBalanceResult(
      currentSoilMm: f.currentSoilMoistureMm > 0
          ? f.currentSoilMoistureMm.clamp(0.0, fc).toDouble()
          : fc * 0.75,
      fieldCapacityMm: fc,
      rawThresholdMm: criticalLevel,
      todayEtcMm: todayEtc,
      effectiveRainNext7DaysMm: totalEffectiveRain,
      nextIrrigationDate: nextIrrigation,
      recommendedDoseMm: recommendedDose,
      recommendedDoseLiters: netLiters,
      recommendedGrossLiters: grossLiters,
      stageLabel: stageInfo.label,
      kcUsed: kc,
      projections: projections,
    );
  }

  static int _dayOfYear(DateTime d) {
    final start = DateTime(d.year, 1, 1);
    return d.difference(start).inDays + 1;
  }
}
