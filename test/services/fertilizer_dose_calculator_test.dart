import 'package:flutter_test/flutter_test.dart';

import 'package:feng_498/services/rules/crop_rule_set.dart';
import 'package:feng_498/services/rules/fertilizer_dose_calculator.dart';

void main() {
  group('FertilizerDoseCalculator.calculate', () {
    test('bilinmeyen ürün → null', () {
      final plan = FertilizerDoseCalculator.calculate(
        cropName: 'Acaipbitki',
        stageKey: 'vejetatif',
        areaDekar: 5,
      );
      expect(plan, isNull);
    });

    test('areaDekar <= 0 → null', () {
      final plan = FertilizerDoseCalculator.calculate(
        cropName: 'aycicegi',
        stageKey: 'vejetatif',
        areaDekar: 0,
      );
      expect(plan, isNull);
    });

    test('ayçiçeği taban gübresi (stage null)', () {
      final plan = FertilizerDoseCalculator.calculate(
        cropName: 'Ayçiçeği',
        stageKey: null,
        areaDekar: 2,
      );
      expect(plan, isNotNull);
      expect(plan!.splitWindow, 'taban');
      // 6 + 6 = 12 kg N/da × 2 = 24 kg N total
      expect(plan.recommendedNkg, 24);
      // Taban uygulamasında 6 kg/da × 2 = 12 kg
      expect(plan.thisApplicationNkg, 12);
      expect(plan.recommendedPkg, 14);
      expect(plan.recommendedKkg, 12);
    });

    test('buğday üst gübresi (kardeşlenme)', () {
      final plan = FertilizerDoseCalculator.calculate(
        cropName: 'Buğday',
        stageKey: 'kardeslenme',
        areaDekar: 10,
      );
      expect(plan, isNotNull);
      expect(plan!.splitWindow, 'ust');
      expect(plan.thisApplicationNkg, 80); // 8 kg/da × 10
    });

    test('mısır vejetatif → üst gübre tetiklenir', () {
      final plan = FertilizerDoseCalculator.calculate(
        cropName: 'Mısır',
        stageKey: 'vejetatif',
        areaDekar: 1,
      );
      expect(plan, isNotNull);
      expect(plan!.splitWindow, 'ust');
      expect(plan.thisApplicationNkg, 12);
    });

    test('Türkçe karakter normalize edilir (sunflower alias)', () {
      final plan = FertilizerDoseCalculator.calculate(
        cropName: 'AYCICEGI',
        stageKey: null,
        areaDekar: 1,
      );
      expect(plan, isNotNull);
    });
  });

  group('calculateFromDays', () {
    test('30-60 gün arası → vejetatif → üst gübre', () {
      final plan = FertilizerDoseCalculator.calculateFromDays(
        cropName: 'misir',
        daysSincePlanted: 45,
        areaDekar: 5,
      );
      expect(plan, isNotNull);
      expect(plan!.splitWindow, 'ust');
    });

    test('< 30 gün → taban', () {
      final plan = FertilizerDoseCalculator.calculateFromDays(
        cropName: 'misir',
        daysSincePlanted: 10,
        areaDekar: 5,
      );
      expect(plan, isNotNull);
      expect(plan!.splitWindow, 'taban');
    });

    test('null gün → taban', () {
      final plan = FertilizerDoseCalculator.calculateFromDays(
        cropName: 'misir',
        daysSincePlanted: null,
        areaDekar: 5,
      );
      expect(plan, isNotNull);
      expect(plan!.splitWindow, 'taban');
    });
  });

  group('fertilizedRecently helper', () {
    test('son 14 gün içinde gübreleme → true', () {
      final now = DateTime(2026, 6, 1);
      final result = FertilizerDoseCalculator.fertilizedRecently(
        recentActivities: [
          ActivityRecord(
            type: 'fertilizing',
            at: now.subtract(const Duration(days: 5)),
          ),
        ],
        now: now,
        withinDays: 14,
      );
      expect(result, isTrue);
    });

    test('son 14 gün içinde gübreleme yok → false', () {
      final now = DateTime(2026, 6, 1);
      final result = FertilizerDoseCalculator.fertilizedRecently(
        recentActivities: [
          ActivityRecord(
            type: 'fertilizing',
            at: now.subtract(const Duration(days: 30)),
          ),
        ],
        now: now,
        withinDays: 14,
      );
      expect(result, isFalse);
    });

    test('aktivite hiç yok → false', () {
      final result = FertilizerDoseCalculator.fertilizedRecently(
        recentActivities: const [],
        now: DateTime(2026, 6, 1),
        withinDays: 14,
      );
      expect(result, isFalse);
    });
  });
}
