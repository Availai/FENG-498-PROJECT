import 'package:feng_498/data/crop_protocols.dart';
import 'package:feng_498/data/crop_setup_scenario.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CropSetupScenarioEngine', () {
    test('aynı seçimlerden kaynaklı ve deterministik senaryo üretir', () {
      final a = CropSetupScenarioEngine.build(
        cropName: 'Ayçiçeği',
        soilType: SoilType.sandy,
        irrigationMethod: IrrigationMethod.drip,
        productionSystem: ProductionSystem.openField,
        fieldAreaDekar: 2,
        rowSpacingCm: 70,
        plantSpacingCm: 30,
      );
      final b = CropSetupScenarioEngine.build(
        cropName: 'Ayçiçeği',
        soilType: SoilType.sandy,
        irrigationMethod: IrrigationMethod.drip,
        productionSystem: ProductionSystem.openField,
        fieldAreaDekar: 2,
        rowSpacingCm: 70,
        plantSpacingCm: 30,
      );

      expect(a.toMetadata(), b.toMetadata());
      expect(a.hasOfficialGuide, isTrue);
      expect(a.sourceRefs, isNotEmpty);
      expect(a.missingInformation.join(' '), contains('Toprak analizi'));
    });

    test('toprak, sulama ve üretim seçimi sulama sürecini değiştirir', () {
      final sandyDrip = CropSetupScenarioEngine.build(
        cropName: 'Domates',
        soilType: SoilType.sandy,
        irrigationMethod: IrrigationMethod.drip,
        productionSystem: ProductionSystem.greenhouse,
        fieldAreaDekar: 1,
        rowSpacingCm: 100,
        plantSpacingCm: 50,
      );
      final clayFurrow = CropSetupScenarioEngine.build(
        cropName: 'Domates',
        soilType: SoilType.clay,
        irrigationMethod: IrrigationMethod.furrow,
        productionSystem: ProductionSystem.openField,
        fieldAreaDekar: 1,
        rowSpacingCm: 100,
        plantSpacingCm: 50,
      );

      expect(sandyDrip.waterIntervalDays, isNot(clayFurrow.waterIntervalDays));
      expect(
        sandyDrip.waterNeedMultiplier,
        isNot(clayFurrow.waterNeedMultiplier),
      );
      expect(
        sandyDrip.summary,
        contains('Kimyasal mücadele yalnız gözlem'),
      );
    });
  });
}
