import 'package:flutter_test/flutter_test.dart';

import 'package:feng_498/services/harvest_shift_estimator.dart';

void main() {
  group('HarvestShiftEstimator.estimate', () {
    test('su ve sicaklik dengedeyse hasat tarihini oynatmaz', () {
      final planted = DateTime(2026, 4, 1);

      final estimate = HarvestShiftEstimator.estimate(
        baseHarvestDays: 100,
        plantedDate: planted,
        weeklyRainMm: 24,
        idealWeeklyRainMm: 25,
        avgTempC: 23,
        idealTempC: 22,
      );

      expect(estimate.daysShift, 0);
      expect(estimate.baseHarvestDate, DateTime(2026, 7, 10));
      expect(estimate.estimatedHarvestDate, estimate.baseHarvestDate);
      expect(estimate.factors.map((f) => f.deltaDays), everyElement(0));
    });

    test('kuraklik ve soguk toplam gecikme uretir ama 15 gunu asmaz', () {
      final estimate = HarvestShiftEstimator.estimate(
        baseHarvestDays: 100,
        plantedDate: DateTime(2026, 4, 1),
        weeklyRainMm: 0,
        idealWeeklyRainMm: 100,
        avgTempC: 0,
        idealTempC: 22,
      );

      expect(estimate.daysShift, 13);
      expect(estimate.estimatedHarvestDate, DateTime(2026, 7, 23));
      expect(estimate.factors.where((f) => f.deltaDays > 0), hasLength(2));
    });

    test('sicak hava GDD birikimini hizlandirip hasadi one ceker', () {
      final estimate = HarvestShiftEstimator.estimate(
        baseHarvestDays: 100,
        plantedDate: DateTime(2026, 4, 1),
        weeklyRainMm: 25,
        idealWeeklyRainMm: 25,
        avgTempC: 34,
        idealTempC: 22,
      );

      expect(estimate.daysShift, -6);
      expect(estimate.estimatedHarvestDate, DateTime(2026, 7, 4));
      expect(estimate.summary, contains('6'));
    });

    test('asiri yagis mantar ve kok riskiyle gecikme faktoru ekler', () {
      final estimate = HarvestShiftEstimator.estimate(
        baseHarvestDays: 90,
        plantedDate: DateTime(2026, 5, 1),
        weeklyRainMm: 70,
        idealWeeklyRainMm: 25,
      );

      expect(estimate.daysShift, 3);
      expect(estimate.factors.single.deltaDays, 3);
    });
  });

  group('HarvestShiftEstimator.timelineFor', () {
    test('bilinen urunde protokol adimlarini tarihli timelinea cevirir', () {
      final planted = DateTime(2026, 4, 1);

      final timeline = HarvestShiftEstimator.timelineFor(
        cropName: 'domates',
        plantedDate: planted,
      );

      expect(timeline, isNotEmpty);
      expect(timeline.first.estimatedDate, planted);
      expect(
        timeline.map((s) => s.dayOffset).toList(),
        orderedEquals(timeline.map((s) => s.dayOffset).toList()..sort()),
      );
    });

    test('bilinmeyen urunde bos timeline dondurur', () {
      expect(
        HarvestShiftEstimator.timelineFor(
          cropName: 'bilinmeyen',
          plantedDate: DateTime(2026, 4, 1),
        ),
        isEmpty,
      );
    });
  });
}
