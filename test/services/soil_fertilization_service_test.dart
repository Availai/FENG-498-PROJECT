import 'package:flutter_test/flutter_test.dart';

import 'package:feng_498/services/api/soilgrids_api.dart';
import 'package:feng_498/services/soil_fertilization_service.dart';

void main() {
  group('SoilFertilizationService.estimateNpk', () {
    test('dusuk organik madde ve CEC degerlerini alt sinira sikistirir', () {
      final estimate = SoilFertilizationService.estimateNpk(
        _profile(
          nitrogenGKg: 1,
          organicCarbonGKg: 2,
          clayGKg: 50,
          cecMmolKg: 20,
        ),
      );

      expect(estimate.nitrogenKgDekar, closeTo(0.28, 0.001));
      expect(estimate.phosphorusKgDekar, 2);
      expect(estimate.potassiumKgDekar, 5);
      expect(estimate.nLevel, NutrientLevel.dusuk);
      expect(estimate.pLevel, NutrientLevel.dusuk);
      expect(estimate.kLevel, NutrientLevel.dusuk);
    });

    test('zengin toprakta NPK seviyelerini yuksek siniflar', () {
      final estimate = SoilFertilizationService.estimateNpk(
        _profile(
          nitrogenGKg: 20,
          organicCarbonGKg: 80,
          clayGKg: 600,
          cecMmolKg: 500,
        ),
      );

      expect(estimate.nLevel, NutrientLevel.yuksek);
      expect(estimate.pLevel, NutrientLevel.yuksek);
      expect(estimate.kLevel, NutrientLevel.yuksek);
      expect(estimate.kLabel, isNotEmpty);
    });
  });

  group('SoilFertilizationService.amendmentFor', () {
    test('0.2 pH altindaki farkta gereksiz uygulama onermez', () {
      final result = SoilFertilizationService.amendmentFor(
        profile: _profile(phH2o: 66),
        targetPh: 6.7,
      );

      expect(result, isNull);
    });

    test('asitli kumlu toprak icin kirec dozu hesaplar', () {
      final result = SoilFertilizationService.amendmentFor(
        profile: _profile(phH2o: 54, clayGKg: 100),
        targetPh: 6.6,
      );

      expect(result, isNotNull);
      expect(result!.materialName, contains('Kire'));
      expect(result.doseKgDekar, closeTo(240, 0.01));
    });

    test('bazik agir killi toprakta kukurt dozunu tampon faktore gore artirir',
        () {
      final result = SoilFertilizationService.amendmentFor(
        profile: _profile(phH2o: 82, clayGKg: 500),
        targetPh: 6.8,
      );

      expect(result, isNotNull);
      expect(result!.materialName, contains('K'));
      expect(result.doseKgDekar, closeTo(179.2, 0.01));
    });
  });

  group('SoilFertilizationService.fertilizationPlan', () {
    test('ASCII ve Turkce urun adlari dogru gubreleme dalina gider', () {
      final wheat = SoilFertilizationService.fertilizationPlan('bugday');
      final maize =
          SoilFertilizationService.fertilizationPlan('m\u0131s\u0131r');
      final tomato = SoilFertilizationService.fertilizationPlan('domates');
      final orchard = SoilFertilizationService.fertilizationPlan('uzum');
      final root = SoilFertilizationService.fertilizationPlan('sogan');

      expect(wheat.map((s) => s.doseKgDekar), containsAll([20, 15, 12]));
      expect(maize.length, 3);
      expect(tomato.length, 4);
      expect(orchard.first.doseKgDekar, 1500);
      expect(root.any((s) => s.fertilizer.contains('15-15-15')), isTrue);
    });

    test('bilinmeyen urunde genel ama dengeli plan dondurur', () {
      final generic = SoilFertilizationService.fertilizationPlan('kinoa');

      expect(generic.length, 3);
      expect(generic.first.fertilizer, contains('15-15-15'));
    });
  });

  test('toprak dokusuna gore uygun urun metni dalini secer', () {
    expect(
      SoilFertilizationService.suitableCropsForTexture('Kumlu'),
      contains('Havu'),
    );
    expect(
      SoilFertilizationService.suitableCropsForTexture('Bilinmeyen'),
      contains('bitki'),
    );
  });
}

SoilProfile _profile({
  double phH2o = 68,
  double organicCarbonGKg = 20,
  double clayGKg = 300,
  double sandGKg = 400,
  double siltGKg = 300,
  double bulkDensityKgM3 = 1400,
  double cecMmolKg = 200,
  double nitrogenGKg = 5,
}) {
  return SoilProfile(
    phH2o: phH2o,
    organicCarbonGKg: organicCarbonGKg,
    clayGKg: clayGKg,
    sandGKg: sandGKg,
    siltGKg: siltGKg,
    bulkDensityKgM3: bulkDensityKgM3,
    cecMmolKg: cecMmolKg,
    nitrogenGKg: nitrogenGKg,
  );
}
