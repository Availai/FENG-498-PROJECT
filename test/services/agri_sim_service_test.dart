import 'package:flutter_test/flutter_test.dart';

import 'package:feng_498/models/seed_models.dart';
import 'package:feng_498/services/agri_sim_service.dart';

void main() {
  group('AgriSimService.simulate', () {
    test('sicak gunlerde GDD biriktirip evreleri ilerletir', () {
      final variety = _variety(cropTr: 'm\u0131s\u0131r');
      final result = AgriSimService.simulate(
        variety: variety,
        sowDate: DateTime(2026, 4, 1),
        dailyTemps: List.generate(
          80,
          (_) => const {'tmax': 32.0, 'tmin': 20.0},
        ),
      );

      expect(result.dailyRecords, isNotEmpty);
      expect(result.stageDates.keys, contains(PhenologyStage.ciceklenme));
      expect(result.estimatedHarvestDate.isAfter(result.sowDate), isTrue);
      expect(result.predictedYieldKgDekar, inInclusiveRange(400, 500));
    });

    test('asiri soguk stres verimi dusurur', () {
      final variety = _variety(cropTr: 'arpa');
      final warm = AgriSimService.simulate(
        variety: variety,
        sowDate: DateTime(2026, 3, 1),
        dailyTemps: List.generate(
          80,
          (_) => const {'tmax': 22.0, 'tmin': 12.0},
        ),
      );
      final cold = AgriSimService.simulate(
        variety: variety,
        sowDate: DateTime(2026, 3, 1),
        dailyTemps: List.generate(
          80,
          (_) => const {'tmax': -5.0, 'tmin': -12.0},
        ),
      );

      expect(cold.predictedYieldKgDekar, lessThan(warm.predictedYieldKgDekar));
      expect(cold.predictedYieldKgDekar, greaterThanOrEqualTo(200));
    });

    test('gun sayisi yardimcisi hasat evresinde negatif donmez', () {
      final variety = _variety(cropTr: 'arpa');

      final days = AgriSimService.daysUntilNextStage(
        variety: variety,
        sowDate: DateTime.now().subtract(const Duration(days: 365)),
        dailyTemps: List.generate(
          80,
          (_) => const {'tmax': 22.0, 'tmin': 12.0},
        ),
      );

      expect(days, inInclusiveRange(0, 365));
    });
  });
}

SeedVariety _variety({required String cropTr}) {
  return SeedVariety(
    id: 'test-$cropTr',
    nameTr: 'Test',
    cropTr: cropTr,
    breeder: 'Test',
    registrationYear: 2026,
    suitableRegions: const [TurkishRegion.icAnadolu],
    phenology: const [
      PhenologyStageDef(
        stage: PhenologyStage.cimlenme,
        baseDurationDays: 5,
        minTempC: 5,
        maxTempC: 35,
        optTempC: 22,
        requiredGdd: 25,
        careNote: 'Cimlenme',
      ),
      PhenologyStageDef(
        stage: PhenologyStage.ciceklenme,
        baseDurationDays: 20,
        minTempC: 10,
        maxTempC: 35,
        optTempC: 24,
        requiredGdd: 80,
        careNote: 'Ciceklenme',
      ),
      PhenologyStageDef(
        stage: PhenologyStage.hasat,
        baseDurationDays: 20,
        minTempC: 10,
        maxTempC: 35,
        optTempC: 24,
        requiredGdd: 80,
        careNote: 'Hasat',
      ),
    ],
    avgYieldKgDekar: 400,
    maxYieldKgDekar: 600,
    droughtTolerance: 0.7,
    frostTolerance: 0.5,
    diseaseResistance: 0.6,
    salinityTolerance: 0.4,
    soilSuitability: 'Tinli',
    idealPhMin: 6,
    idealPhMax: 7.5,
    notes: 'Test cesidi',
  );
}
