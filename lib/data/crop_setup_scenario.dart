library;

import 'dart:math' as math;

import 'crop_protocols.dart';
import 'turkiye_crop_guides.dart';

class CropSetupScenarioLine {
  final String title;
  final String body;

  const CropSetupScenarioLine({
    required this.title,
    required this.body,
  });

  Map<String, dynamic> toJson() => {
        'title': title,
        'body': body,
      };
}

class CropSetupScenario {
  final String cropName;
  final String title;
  final String summary;
  final int waterIntervalDays;
  final double waterNeedMultiplier;
  final double effectiveAreaDekar;
  final double requiredAreaDekar;
  final int estimatedPlantCount;
  final double rowSpacingCm;
  final double plantSpacingCm;
  final bool hasOfficialGuide;
  final List<CropSetupScenarioLine> lines;
  final List<String> warnings;
  final List<String> missingInformation;
  final List<String> sourceRefs;

  const CropSetupScenario({
    required this.cropName,
    required this.title,
    required this.summary,
    required this.waterIntervalDays,
    required this.waterNeedMultiplier,
    required this.effectiveAreaDekar,
    required this.requiredAreaDekar,
    required this.estimatedPlantCount,
    required this.rowSpacingCm,
    required this.plantSpacingCm,
    required this.hasOfficialGuide,
    required this.lines,
    required this.warnings,
    required this.missingInformation,
    required this.sourceRefs,
  });

  Map<String, dynamic> toMetadata() => {
        'crop_name': cropName,
        'title': title,
        'summary': summary,
        'water_interval_days': waterIntervalDays,
        'water_need_multiplier': waterNeedMultiplier,
        'effective_area_dekar': effectiveAreaDekar,
        'required_area_dekar': requiredAreaDekar,
        'estimated_plant_count': estimatedPlantCount,
        'row_spacing_cm': rowSpacingCm,
        'plant_spacing_cm': plantSpacingCm,
        'has_official_guide': hasOfficialGuide,
        'lines': lines.map((line) => line.toJson()).toList(),
        'warnings': warnings,
        'missing_information': missingInformation,
        'source_refs': sourceRefs,
      };
}

class CropSetupScenarioEngine {
  CropSetupScenarioEngine._();

  static CropSetupScenario build({
    required String cropName,
    required SoilType soilType,
    required IrrigationMethod irrigationMethod,
    required ProductionSystem productionSystem,
    required double fieldAreaDekar,
    required double rowSpacingCm,
    required double plantSpacingCm,
    int? targetPlantCount,
  }) {
    final guide = TurkiyeCropGuides.lookup(cropName);
    final cleanRow = rowSpacingCm.clamp(20.0, 200.0).toDouble();
    final cleanPlant = plantSpacingCm.clamp(5.0, 200.0).toDouble();
    final cleanArea = fieldAreaDekar.clamp(0.1, 10000.0).toDouble();
    final requiredDekar = _requiredDekar(
      plantCount: targetPlantCount,
      rowSpacingCm: cleanRow,
      plantSpacingCm: cleanPlant,
    );
    final effectiveArea = requiredDekar == null
        ? cleanArea
        : math.min(cleanArea, math.max(0.01, requiredDekar));
    final estimatedPlantCount = targetPlantCount != null &&
            targetPlantCount > 0 &&
            requiredDekar != null &&
            requiredDekar <= cleanArea + 0.01
        ? targetPlantCount
        : _estimatePlantCount(
            areaDekar: effectiveArea,
            rowSpacingCm: cleanRow,
            plantSpacingCm: cleanPlant,
          );
    final interval = waterIntervalDaysFor(
      soilType: soilType,
      irrigationMethod: irrigationMethod,
      productionSystem: productionSystem,
    );
    final waterMultiplier = waterNeedMultiplierFor(
      soilType: soilType,
      irrigationMethod: irrigationMethod,
      productionSystem: productionSystem,
    );
    final lines = <CropSetupScenarioLine>[
      if (guide != null)
        CropSetupScenarioLine(
          title: 'Kaynaklı ürün profili',
          body:
              '${guide.cropName} için sıra arası ${_fmt(guide.rowSpacingCm)} cm, sıra üzeri ${_fmt(guide.plantSpacingCm)} cm, sezon suyu yaklaşık ${_fmt(guide.seasonalWaterMm)} mm ve hasat süresi ${guide.harvestDays} gün olarak izlenir.',
        )
      else
        const CropSetupScenarioLine(
          title: 'Kaynaklı ürün profili',
          body:
              'Bu ürün için yerel Türkiye rehberi bulunamadı; yalnız kayıt ve temel sulama planı oluşturulur.',
        ),
      CropSetupScenarioLine(
        title: '${soilType.label} toprak senaryosu',
        body: _soilScenario(soilType),
      ),
      CropSetupScenarioLine(
        title: '${irrigationMethod.label} senaryosu',
        body: _irrigationScenario(irrigationMethod),
      ),
      CropSetupScenarioLine(
        title: '${productionSystem.label} üretim senaryosu',
        body: _productionScenario(productionSystem),
      ),
      CropSetupScenarioLine(
        title: 'Takvim sonucu',
        body:
            'Sulama hatırlatma aralığı $interval gün; su miktarı hesabı seçimlere göre x${waterMultiplier.toStringAsFixed(2)} katsayısıyla işaretlenir.',
      ),
      CropSetupScenarioLine(
        title: 'Ekim yoğunluğu',
        body:
            '${_fmt(effectiveArea)} da alanda yaklaşık $estimatedPlantCount bitki; sıra arası ${_fmt(cleanRow)} cm, sıra üzeri ${_fmt(cleanPlant)} cm.',
      ),
    ];

    final warnings = <String>[
      ..._spacingWarnings(
        guide: guide,
        rowSpacingCm: cleanRow,
        plantSpacingCm: cleanPlant,
      ),
      ..._riskWarnings(
        cropName: guide?.cropName ?? cropName,
        soilType: soilType,
        irrigationMethod: irrigationMethod,
        productionSystem: productionSystem,
      ),
    ];
    final missing = <String>[
      'Toprak analizi girilmediği için net gübre miktarı bu ekranda üretilmez.',
      'İl/ilçe ve çeşit bilgisi yoksa bölgesel takvim genel Türkiye rehberi olarak kalır.',
      if (guide == null)
        'Bu ürün için kaynak kanıtlı Türkiye ürün rehberi eksik.',
    ];
    final sourceRefs = guide?.sourceRefs ?? const <String>[];
    final title = '${guide?.cropName ?? cropName} · ${productionSystem.label}';
    final summary =
        '${soilType.label} toprak + ${irrigationMethod.label}: $interval günlük bakım akışı. Kimyasal mücadele yalnız gözlem, eşik ve BKÜ kontrolüyle açılır.';

    return CropSetupScenario(
      cropName: guide?.cropName ?? cropName,
      title: title,
      summary: summary,
      waterIntervalDays: interval,
      waterNeedMultiplier: waterMultiplier,
      effectiveAreaDekar: effectiveArea,
      requiredAreaDekar: requiredDekar ?? effectiveArea,
      estimatedPlantCount: estimatedPlantCount,
      rowSpacingCm: cleanRow,
      plantSpacingCm: cleanPlant,
      hasOfficialGuide: guide != null,
      lines: lines,
      warnings: warnings,
      missingInformation: missing,
      sourceRefs: sourceRefs,
    );
  }

  static int waterIntervalDaysFor({
    required SoilType soilType,
    required IrrigationMethod irrigationMethod,
    required ProductionSystem productionSystem,
  }) {
    final base = switch (irrigationMethod) {
      IrrigationMethod.drip => 3,
      IrrigationMethod.sprinkler => 5,
      IrrigationMethod.hand => 5,
      IrrigationMethod.furrow => 7,
    };
    final soilDelta = switch (soilType) {
      SoilType.sandy => -1,
      SoilType.volcanic => -1,
      SoilType.loamy => 0,
      SoilType.clay => 2,
    };
    final productionDelta = switch (productionSystem) {
      ProductionSystem.greenhouse => -1,
      ProductionSystem.dryFarming => 7,
      ProductionSystem.openField ||
      ProductionSystem.goodAgriculture ||
      ProductionSystem.organic =>
        0,
    };
    return (base + soilDelta + productionDelta).clamp(2, 14).toInt();
  }

  static double waterNeedMultiplierFor({
    required SoilType soilType,
    required IrrigationMethod irrigationMethod,
    required ProductionSystem productionSystem,
  }) {
    final soil = switch (soilType) {
      SoilType.sandy => 1.15,
      SoilType.volcanic => 1.05,
      SoilType.loamy => 1.0,
      SoilType.clay => 0.9,
    };
    final method = switch (irrigationMethod) {
      IrrigationMethod.drip => 0.85,
      IrrigationMethod.furrow => 1.1,
      IrrigationMethod.sprinkler => 1.0,
      IrrigationMethod.hand => 1.05,
    };
    final production = switch (productionSystem) {
      ProductionSystem.greenhouse => 0.9,
      ProductionSystem.dryFarming => 0.6,
      ProductionSystem.openField ||
      ProductionSystem.goodAgriculture ||
      ProductionSystem.organic =>
        1.0,
    };
    return soil * method * production;
  }

  static double? _requiredDekar({
    required int? plantCount,
    required double rowSpacingCm,
    required double plantSpacingCm,
  }) {
    if (plantCount == null || plantCount <= 0) return null;
    final footprintSqm = (rowSpacingCm / 100) * (plantSpacingCm / 100);
    if (footprintSqm <= 0) return null;
    return (plantCount * footprintSqm) / 1000;
  }

  static int _estimatePlantCount({
    required double areaDekar,
    required double rowSpacingCm,
    required double plantSpacingCm,
  }) {
    final footprintSqm = (rowSpacingCm / 100) * (plantSpacingCm / 100);
    if (footprintSqm <= 0 || areaDekar <= 0) return 0;
    return ((areaDekar * 1000) / footprintSqm).round();
  }

  static String _soilScenario(SoilType soilType) {
    return switch (soilType) {
      SoilType.loamy =>
        'Tınlı yapı temel senaryo kabul edilir; su ve besin tutumu dengeli olduğu için takvim normal aralıkta kalır.',
      SoilType.clay =>
        'Killi toprak su tuttuğu için aralık uzar; drenaj ve kök boğazı havasızlığı ayrıca izlenir.',
      SoilType.sandy =>
        'Kumlu toprak hızlı süzdüğü için aralık kısalır; küçük dozlu ve sık kontrol öne çıkar.',
      SoilType.volcanic =>
        'Volkanik toprakta mineral ve pH değişkenliği izlenir; kısa aralıklı nem kontrolü tercih edilir.',
    };
  }

  static String _irrigationScenario(IrrigationMethod method) {
    return switch (method) {
      IrrigationMethod.drip =>
        'Damla sulamada kök bölgesi hedeflenir; hatırlatma daha sık ama düşük kayıplı kabul edilir.',
      IrrigationMethod.furrow =>
        'Karık sulamada su dağılımı yavaş ve kayıp yüksek olabilir; aralık daha uzun, uygulama süresi daha dikkatli izlenir.',
      IrrigationMethod.sprinkler =>
        'Yağmurlamada yaprak ıslaklığı hastalık riskini artırabileceği için sabah uygulaması ve gözlem notu eklenir.',
      IrrigationMethod.hand =>
        'El ile sulamada parsel küçük kabul edilir; miktar mutlaka kayıt ekranında gerçek verilen suya göre netleştirilir.',
    };
  }

  static String _productionScenario(ProductionSystem system) {
    return switch (system) {
      ProductionSystem.openField =>
        'Açık tarla genel Türkiye takvimidir; hava uyarıları ve yağış ertelemesi süreçte belirleyicidir.',
      ProductionSystem.greenhouse =>
        'Örtüaltında nem ve havalandırma riski öne çıkar; kimyasal karar değil önce gözlem ve teşhis kapısı gösterilir.',
      ProductionSystem.goodAgriculture =>
        'İyi Tarım seçimi kayıt, izlenebilirlik ve etiket/BKÜ kontrolünü zorunlu güvenlik kapısı olarak vurgular.',
      ProductionSystem.organic =>
        'Organik üretimde kimyasal kapı varsayılan kapalıdır; kültürel ve mekanik önlem önce gelir.',
      ProductionSystem.dryFarming =>
        'Kuru tarımda sulama hatırlatması seyrelir; uygulama yerine kritik evre ve kuraklık stresi takibi öne çıkar.',
    };
  }

  static List<String> _spacingWarnings({
    required TurkiyeCropGuide? guide,
    required double rowSpacingCm,
    required double plantSpacingCm,
  }) {
    if (guide == null) return const [];
    final out = <String>[];
    if (_diffPct(rowSpacingCm, guide.rowSpacingCm) > 0.25) {
      out.add(
        'Sıra arası kaynak değerinden belirgin farklı: kaynak ${_fmt(guide.rowSpacingCm)} cm, seçilen ${_fmt(rowSpacingCm)} cm.',
      );
    }
    if (_diffPct(plantSpacingCm, guide.plantSpacingCm) > 0.25) {
      out.add(
        'Sıra üzeri kaynak değerinden belirgin farklı: kaynak ${_fmt(guide.plantSpacingCm)} cm, seçilen ${_fmt(plantSpacingCm)} cm.',
      );
    }
    return out;
  }

  static List<String> _riskWarnings({
    required String cropName,
    required SoilType soilType,
    required IrrigationMethod irrigationMethod,
    required ProductionSystem productionSystem,
  }) {
    final normalized = _normalize(cropName);
    final out = <String>[];
    if (productionSystem == ProductionSystem.greenhouse &&
        normalized != 'domates') {
      out.add(
        '$cropName için örtüaltı ana senaryo değildir; alan uygunsa yerel ziraat mühendisiyle doğrulayın.',
      );
    }
    if (productionSystem == ProductionSystem.dryFarming &&
        (normalized == 'domates' || normalized == 'misir')) {
      out.add(
        '$cropName yüksek su hassasiyetine sahiptir; kuru tarım seçimi verim riski taşır.',
      );
    }
    if (irrigationMethod == IrrigationMethod.sprinkler &&
        (productionSystem == ProductionSystem.greenhouse ||
            normalized == 'domates')) {
      out.add(
        'Yağmurlama yaprak ıslaklığını artırır; domates ve örtüaltında mantari hastalık gözlemi sıklaştırılmalıdır.',
      );
    }
    if (soilType == SoilType.clay &&
        irrigationMethod == IrrigationMethod.furrow) {
      out.add(
        'Killi toprak + karık sulama drenaj riski taşır; su birikmesi görülürse uygulama süresi kısaltılmalıdır.',
      );
    }
    return out;
  }

  static double _diffPct(double actual, double baseline) {
    if (baseline <= 0) return 0;
    return (actual - baseline).abs() / baseline;
  }

  static String _fmt(double value) => value == value.roundToDouble()
      ? value.toStringAsFixed(0)
      : value.toStringAsFixed(1);

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
