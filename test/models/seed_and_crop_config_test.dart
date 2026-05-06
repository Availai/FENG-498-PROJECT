import 'package:flutter_test/flutter_test.dart';

import 'package:feng_498/data/crop_protocols.dart';
import 'package:feng_498/models/seed_models.dart';

void main() {
  group('SeedVariety hesaplanan alanlari', () {
    test('toplam hasat gunu, GDD ve evre baslangiclarini toplar', () {
      final variety = _seedVariety(
        droughtTolerance: 0.9,
        frostTolerance: 0.8,
        diseaseResistance: 0.7,
      );

      expect(variety.totalDaysToHarvest, 35);
      expect(variety.totalGddRequired, 150);
      expect(variety.daysUntilStageStart(PhenologyStage.ciceklenme), 10);
      expect(variety.daysUntilStageStart(PhenologyStage.hasat), 25);
      expect(variety.resistanceLabel, isNotEmpty);
    });

    test('dusuk tolerans ortalamasi dusuk direnclilik etiketi verir', () {
      final variety = _seedVariety(
        droughtTolerance: 0.2,
        frostTolerance: 0.3,
        diseaseResistance: 0.4,
      );

      expect(variety.resistanceLabel, contains('D'));
    });
  });

  group('CropConfig', () {
    test('hedef bitki sayisi varsa etkili alani tarla alanina kadar kisar', () {
      const config = CropConfig(
        soilType: SoilType.loamy,
        irrigationMethod: IrrigationMethod.drip,
        areaDekar: 10,
        rowSpacingCm: 50,
        plantSpacingCm: 20,
        targetPlantCount: 1000,
      );

      expect(config.plantFootprintSqm, closeTo(0.10, 0.001));
      expect(config.targetAreaDekar, closeTo(0.10, 0.001));
      expect(config.effectiveAreaDekar, closeTo(0.10, 0.001));
      expect(config.estimatedPlantCount, 1000);
    });

    test('hedef yoksa alan ve araliktan bitki sayisi hesaplar', () {
      const config = CropConfig(
        soilType: SoilType.loamy,
        irrigationMethod: IrrigationMethod.furrow,
        areaDekar: 1,
        rowSpacingCm: 60,
        plantSpacingCm: 40,
      );

      expect(config.targetAreaDekar, isNull);
      expect(config.effectiveAreaDekar, 1);
      expect(config.estimatedPlantCount, 4167);
    });

    test('JSON round-trip yon ve uretim sistemi bilgisini korur', () {
      const config = CropConfig(
        soilType: SoilType.sandy,
        irrigationMethod: IrrigationMethod.sprinkler,
        productionSystem: ProductionSystem.organic,
        areaDekar: 3,
        rowSpacingCm: 70,
        plantSpacingCm: 25,
        targetPlantCount: 1200,
        facingDirection: PlantFacingDirection.southeast,
      );

      final parsed = CropConfig.fromJson(config.toJson());

      expect(parsed.soilType, SoilType.sandy);
      expect(parsed.irrigationMethod, IrrigationMethod.sprinkler);
      expect(parsed.productionSystem, ProductionSystem.organic);
      expect(parsed.facingDirection, PlantFacingDirection.southeast);
      expect(parsed.targetPlantCount, 1200);
    });
  });
}

SeedVariety _seedVariety({
  required double droughtTolerance,
  required double frostTolerance,
  required double diseaseResistance,
}) {
  return SeedVariety(
    id: 'seed-test',
    nameTr: 'Test Tohum',
    cropTr: 'arpa',
    breeder: 'Test',
    registrationYear: 2026,
    suitableRegions: const [TurkishRegion.icAnadolu],
    phenology: const [
      PhenologyStageDef(
        stage: PhenologyStage.cimlenme,
        baseDurationDays: 10,
        minTempC: 0,
        maxTempC: 30,
        optTempC: 18,
        requiredGdd: 30,
        careNote: 'Cimlenme',
      ),
      PhenologyStageDef(
        stage: PhenologyStage.ciceklenme,
        baseDurationDays: 15,
        minTempC: 8,
        maxTempC: 32,
        optTempC: 20,
        requiredGdd: 50,
        careNote: 'Ciceklenme',
      ),
      PhenologyStageDef(
        stage: PhenologyStage.hasat,
        baseDurationDays: 10,
        minTempC: 10,
        maxTempC: 35,
        optTempC: 22,
        requiredGdd: 70,
        careNote: 'Hasat',
      ),
    ],
    avgYieldKgDekar: 400,
    maxYieldKgDekar: 600,
    droughtTolerance: droughtTolerance,
    frostTolerance: frostTolerance,
    diseaseResistance: diseaseResistance,
    salinityTolerance: 0.5,
    soilSuitability: 'Tinli',
    idealPhMin: 6,
    idealPhMax: 7.5,
    notes: 'Test',
  );
}
