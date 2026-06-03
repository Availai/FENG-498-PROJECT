import 'package:flutter_test/flutter_test.dart';

import 'package:feng_498/services/guardrails/guardrail_limit.dart';
import 'package:feng_498/services/guardrails/intake_guardrail_engine.dart';

void main() {
  // Domates haftalık hedef ~34 mm (FieldStateService ile aynı kaynak).
  // softMax = 34 × 1.2 = 40.8 · hardMax = 34 × 1.8 = 61.2.
  const tomatoWeeklyTarget = 34.0;

  group('checkWater — iki kademeli su seti', () {
    test('limit altında → ok, hiç uyarı yok', () {
      final v = IntakeGuardrailEngine.checkWater(
        currentWeeklyMm: 10,
        attemptMm: 15,
        weeklyTargetMm: tomatoWeeklyTarget,
      );
      expect(v.level, GuardrailLevel.ok);
      expect(v.reasonTr, isEmpty);
    });

    test('softMax ile hardMax arası → warn (kayıt serbest)', () {
      // 30 + 18 = 48 mm → softMax(40.8) üstü, hardMax(61.2) altı.
      final v = IntakeGuardrailEngine.checkWater(
        currentWeeklyMm: 30,
        attemptMm: 18,
        weeklyTargetMm: tomatoWeeklyTarget,
      );
      expect(v.level, GuardrailLevel.warn);
      expect(v.requiresConfirm, isFalse);
      expect(v.reasonTr, isNotEmpty);
    });

    test('hardMax üstü → block (onay zorunlu)', () {
      // 40 + 30 = 70 mm → hardMax(61.2) üstü.
      final v = IntakeGuardrailEngine.checkWater(
        currentWeeklyMm: 40,
        attemptMm: 30,
        weeklyTargetMm: tomatoWeeklyTarget,
      );
      expect(v.level, GuardrailLevel.block);
      expect(v.requiresConfirm, isTrue);
      expect(v.recommendationTr, isNotEmpty);
    });
  });

  group('checkNitrogen — §16 toprak analizi guardrail', () {
    test('analiz YOK + aşırı azot → block DEĞİL, sadece warn', () {
      // domates standart 22 kg/da; hardMax = 33. Projected 40 > hardMax
      // ama analiz yok → advisory → warn.
      final v = IntakeGuardrailEngine.checkNitrogen(
        cropName: 'Domates',
        seasonalNkgDa: 30,
        attemptNkgDa: 10,
        hasSoilTest: false,
      );
      expect(v.level, GuardrailLevel.warn);
      expect(v.requiresConfirm, isFalse);
      // §16: analiz yokken "kesin" dili kullanılmamalı.
      expect(v.reasonTr, contains('toprak analizi'));
    });

    test('analiz VAR + aşırı azot → block', () {
      final v = IntakeGuardrailEngine.checkNitrogen(
        cropName: 'Domates',
        seasonalNkgDa: 30,
        attemptNkgDa: 10,
        hasSoilTest: true,
      );
      expect(v.level, GuardrailLevel.block);
      expect(v.requiresConfirm, isTrue);
    });

    test('analiz VAR + normal azot → ok', () {
      final v = IntakeGuardrailEngine.checkNitrogen(
        cropName: 'Domates',
        seasonalNkgDa: 8,
        attemptNkgDa: 6,
        hasSoilTest: true,
      );
      expect(v.level, GuardrailLevel.ok);
    });
  });

  group('checkSalinity — ölçülen EC eşiği', () {
    test('EC ölçülmemiş (null) → ok, sessiz', () {
      final v = IntakeGuardrailEngine.checkSalinity(measuredEcDsM: null);
      expect(v.level, GuardrailLevel.ok);
    });

    test('EC > 4 dS/m → block', () {
      final v = IntakeGuardrailEngine.checkSalinity(measuredEcDsM: 4.5);
      expect(v.level, GuardrailLevel.block);
    });

    test('EC 2-4 dS/m → warn', () {
      final v = IntakeGuardrailEngine.checkSalinity(measuredEcDsM: 3.0);
      expect(v.level, GuardrailLevel.warn);
    });
  });

  group('checkPesticideReentry — §17 BKÜ', () {
    test('REI penceresinde → block + BKÜ yönlendirmesi', () {
      final v = IntakeGuardrailEngine.checkPesticideReentry(
        hoursSinceLastSpray: 10,
        reiHours: 24,
      );
      expect(v.level, GuardrailLevel.block);
      expect(v.recommendationTr, contains('bku.tarim.gov.tr'));
    });

    test('REI doldu → ok', () {
      final v = IntakeGuardrailEngine.checkPesticideReentry(
        hoursSinceLastSpray: 30,
        reiHours: 24,
      );
      expect(v.level, GuardrailLevel.ok);
    });

    test('ilaçlama kaydı yok (null) → ok', () {
      final v = IntakeGuardrailEngine.checkPesticideReentry(
        hoursSinceLastSpray: null,
        reiHours: 24,
      );
      expect(v.level, GuardrailLevel.ok);
    });
  });

  group('determinizm — aynı girdi aynı çıktı (§22)', () {
    test('su ekseni iki çağrı aynı verdict', () {
      GuardrailVerdict call() => IntakeGuardrailEngine.checkWater(
            currentWeeklyMm: 40,
            attemptMm: 30,
            weeklyTargetMm: tomatoWeeklyTarget,
          );
      final a = call();
      final b = call();
      expect(a.level, b.level);
      expect(a.projectedTotal, b.projectedTotal);
      expect(a.limitValue, b.limitValue);
      expect(a.reasonTr, b.reasonTr);
    });
  });
}
