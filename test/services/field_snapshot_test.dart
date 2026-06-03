import 'package:flutter_test/flutter_test.dart';

import 'package:feng_498/services/guardrails/field_snapshot.dart';

void main() {
  final now = DateTime(2026, 6, 1, 12);

  Map<String, dynamic> activity(
    String type,
    DateTime date, {
    Map<String, dynamic>? metadata,
  }) =>
      {'type': type, 'date': date, 'metadata': metadata ?? {}};

  group('FieldSnapshotBuilder.build — sezonluk azot', () {
    test('üre kg → saf N (%46) ve alana bölme', () {
      final snap = FieldSnapshotBuilder.build(
        cropName: 'Domates',
        areaDekar: 2,
        weeklyWaterMm: 0,
        now: now,
        activities: [
          activity('fertilizing', now.subtract(const Duration(days: 10)),
              metadata: {'fertilizer_name': 'Üre', 'fertilizer_kg': 20}),
        ],
      );
      // 20 kg üre × 0.46 = 9.2 kg N; / 2 da = 4.6 kg N/da
      expect(snap.seasonalNitrogenKgDa, closeTo(4.6, 0.001));
    });

    test('birden fazla gübreleme toplanır', () {
      final snap = FieldSnapshotBuilder.build(
        cropName: 'Mısır',
        areaDekar: 1,
        weeklyWaterMm: 0,
        now: now,
        activities: [
          activity('fertilizing', now.subtract(const Duration(days: 20)),
              metadata: {'fertilizer_name': '15-15-15', 'fertilizer_kg': 30}),
          activity('fertilizing', now.subtract(const Duration(days: 5)),
              metadata: {'fertilizer_name': 'Üre', 'fertilizer_kg': 10}),
        ],
      );
      // 30×0.15 + 10×0.46 = 4.5 + 4.6 = 9.1 kg N/da
      expect(snap.seasonalNitrogenKgDa, closeTo(9.1, 0.001));
    });

    test('potasyum sülfat azot eklemez', () {
      final snap = FieldSnapshotBuilder.build(
        cropName: 'Domates',
        areaDekar: 1,
        weeklyWaterMm: 0,
        now: now,
        activities: [
          activity('fertilizing', now.subtract(const Duration(days: 3)),
              metadata: {
                'fertilizer_name': 'Potasyum Sülfat',
                'fertilizer_kg': 15
              }),
        ],
      );
      expect(snap.seasonalNitrogenKgDa, 0);
    });
  });

  group('FieldSnapshotBuilder.build — ilaç REI', () {
    test('son ilaçlamadan geçen saat hesaplanır', () {
      final snap = FieldSnapshotBuilder.build(
        cropName: 'Domates',
        areaDekar: 1,
        weeklyWaterMm: 0,
        now: now,
        activities: [
          activity('spraying', now.subtract(const Duration(hours: 6)),
              metadata: {'pesticide_name': 'Mancozeb'}),
        ],
      );
      expect(snap.hoursSinceLastSpray, closeTo(6, 0.01));
      expect(snap.lastPesticideName, 'Mancozeb');
    });

    test('ilaçlama kaydı yok → null', () {
      final snap = FieldSnapshotBuilder.build(
        cropName: 'Domates',
        areaDekar: 1,
        weeklyWaterMm: 0,
        now: now,
        activities: const [],
      );
      expect(snap.hoursSinceLastSpray, isNull);
      expect(snap.lastPesticideName, isNull);
    });
  });

  group('FieldSnapshotBuilder.build — toprak analizi', () {
    test('lab kaydı yok → hasSoilTest false, EC null', () {
      final snap = FieldSnapshotBuilder.build(
        cropName: 'Domates',
        areaDekar: 1,
        weeklyWaterMm: 0,
        now: now,
        activities: const [],
        soilTest: null,
      );
      expect(snap.hasSoilTest, isFalse);
      expect(snap.measuredEcDsM, isNull);
    });

    test('lab kaydı var → hasSoilTest true, EC okunur', () {
      final snap = FieldSnapshotBuilder.build(
        cropName: 'Domates',
        areaDekar: 1,
        weeklyWaterMm: 0,
        now: now,
        activities: const [],
        soilTest: {'ec_ds_m': 3.2},
      );
      expect(snap.hasSoilTest, isTrue);
      expect(snap.measuredEcDsM, 3.2);
    });
  });

  group('nitrogenAttemptKgDa — kayıt öncesi attempt', () {
    test('üre 20 kg / 2 da → 4.6 kg N/da', () {
      final n = FieldSnapshotBuilder.nitrogenAttemptKgDa(
        fertilizerName: 'Üre',
        rawKg: 20,
        areaDekar: 2,
      );
      expect(n, closeTo(4.6, 0.001));
    });

    test('miktar yok → 0', () {
      final n = FieldSnapshotBuilder.nitrogenAttemptKgDa(
        fertilizerName: 'Üre',
        rawKg: null,
        areaDekar: 2,
      );
      expect(n, 0);
    });
  });
}
