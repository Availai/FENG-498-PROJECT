import 'package:flutter_test/flutter_test.dart';

import 'package:feng_498/data/activity_types.dart';
import 'package:feng_498/data/pesticide_rei.dart';
import 'package:feng_498/services/guardrails/field_snapshot.dart';
import 'package:feng_498/services/guardrails/guardrail_checker.dart';
import 'package:feng_498/services/guardrails/guardrail_limit.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    // REI tablosu asset'siz default (24 saat) ile çalışır.
    await PesticideRei.load();
  });

  FieldSnapshot snap({
    double weeklyWater = 0,
    double seasonalN = 0,
    bool hasSoilTest = false,
    double? ec,
    double? hoursSinceSpray,
    String? lastPesticide,
  }) =>
      FieldSnapshot(
        cropName: 'Domates',
        areaDekar: 1,
        currentWeeklyWaterMm: weeklyWater,
        seasonalNitrogenKgDa: seasonalN,
        measuredEcDsM: ec,
        hasSoilTest: hasSoilTest,
        hoursSinceLastSpray: hoursSinceSpray,
        lastPesticideName: lastPesticide,
      );

  group('checkForActivity — eksen yönlendirme', () {
    test('sulama → su ekseni, normal → ok', () {
      final v = GuardrailChecker.checkForActivity(
        activityType: ActivityType.watering,
        snapshot: snap(weeklyWater: 5),
        attemptMm: 10,
        weeklyTargetMm: 34,
      );
      expect(v.axis, GuardrailAxis.water);
      expect(v.level, GuardrailLevel.ok);
    });

    test('gübreleme + analiz var + aşırı → block', () {
      final v = GuardrailChecker.checkForActivity(
        activityType: ActivityType.fertilizing,
        snapshot: snap(seasonalN: 30, hasSoilTest: true),
        fertilizerName: 'Üre',
        rawKg: 20, // 20×0.46 = 9.2 kg N/da → toplam 39.2 > hardMax(33)
      );
      expect(v.axis, GuardrailAxis.nitrogen);
      expect(v.level, GuardrailLevel.block);
    });

    test('gözlem gibi ilgisiz tip → ok sessiz', () {
      final v = GuardrailChecker.checkForActivity(
        activityType: ActivityType.scouting,
        snapshot: snap(),
      );
      expect(v.level, GuardrailLevel.ok);
    });
  });

  group('checkSpraying — REI', () {
    test('REI penceresinde (default 24s, 5s geçmiş) → block', () {
      final v = GuardrailChecker.checkSpraying(
        snapshot: snap(hoursSinceSpray: 5, lastPesticide: 'Bilinmeyen'),
      );
      expect(v.level, GuardrailLevel.block);
    });
  });
}
