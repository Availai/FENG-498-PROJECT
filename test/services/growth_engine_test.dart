import 'package:drift/drift.dart' hide isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:feng_498/data/activity_types.dart';
import 'package:feng_498/data/app_database.dart';
import 'package:feng_498/services/growth_engine.dart';

void main() {
  late AppDatabase database;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await database.close();
  });

  Future<void> seedCrop(String cropId, {required double fertilizerKg}) async {
    final now = DateTime.utc(2026, 4, 24);
    await database.into(database.fields).insert(
          FieldsCompanion.insert(
            id: 'field-$cropId',
            name: 'Test tarlası',
            date: '24.04.2026',
            createdAt: now,
            updatedAt: now,
            areaDekar: const Value(1.0),
            areaSqm: const Value(1000.0),
          ),
        );
    await database.into(database.fieldCrops).insert(
          FieldCropsCompanion.insert(
            id: cropId,
            fieldId: 'field-$cropId',
            name: 'Mısır',
            zoneStart: 0,
            zoneEnd: 1,
            rowSpacingCm: 70,
            plantSpacingCm: 20,
            plantedDate: const Value('01.04.2026'),
            harvestDays: const Value(110),
            waterIntervalDays: const Value(7),
            createdAt: now,
            updatedAt: now,
          ),
        );
    await database.into(database.calendarEvents).insert(
          CalendarEventsCompanion.insert(
            id: 'event-$cropId',
            fieldId: Value('field-$cropId'),
            cropId: Value(cropId),
            title: 'Gübreleme',
            eventType: ActivityType.fertilizing,
            eventDate: DateTime(2026, 4, 12),
            quantity: Value(fertilizerKg),
            unit: const Value('kg'),
            recommendedQuantity: const Value(10),
            createdAt: now,
            updatedAt: now,
          ),
        );
  }

  Future<void> addWaterLiters(
    String cropId,
    DateTime date,
    double liters, {
    String source = 'manual',
  }) async {
    final now = DateTime.utc(2026, 4, 24);
    await database.into(database.calendarEvents).insert(
          CalendarEventsCompanion.insert(
            id: 'water-$cropId-${date.day}',
            fieldId: Value('field-$cropId'),
            cropId: Value(cropId),
            title: 'Sulama',
            eventType: ActivityType.watering,
            eventDate: date,
            source: Value(source),
            unit: const Value('L'),
            metadataJson: Value(
                '{"water_liters":$liters,"irrigation_method":"Damla sulama"}'),
            createdAt: now,
            updatedAt: now,
          ),
        );
  }

  Future<void> seedSoilTest(
    String cropId, {
    double? nitrogenPct,
    double? potassiumKgDa,
    double? organicMatterPct,
  }) async {
    final now = DateTime.utc(2026, 4, 24);
    await database.into(database.soilTests).insert(
          SoilTestsCompanion.insert(
            id: 'soil-$cropId',
            fieldId: 'field-$cropId',
            nitrogenPct: Value(nitrogenPct),
            potassiumKgDa: Value(potassiumKgDa),
            organicMatterPct: Value(organicMatterPct),
            createdAt: now,
            updatedAt: now,
          ),
        );
  }

  group('soilBaselineStressFrom (saf)', () {
    test('analiz yoksa (tüm null) → none / 0', () {
      final b = soilBaselineStressFrom();
      expect(b.isZero, isTrue);
      expect(b.nStress, 0.0);
      expect(b.kStress, 0.0);
    });

    test('çok düşük azot → yüksek başlangıç N stresi', () {
      final poor = soilBaselineStressFrom(nitrogenPct: 0.03);
      final good = soilBaselineStressFrom(nitrogenPct: 0.20);
      expect(poor.nStress, greaterThan(good.nStress));
      expect(good.nStress, 0.0);
    });

    test('düşük organik madde azot stresine ek katkı yapar', () {
      final base = soilBaselineStressFrom(nitrogenPct: 0.10); // orta
      final withLowOm =
          soilBaselineStressFrom(nitrogenPct: 0.10, organicMatterPct: 0.8);
      expect(withLowOm.nStress, greaterThan(base.nStress));
    });

    test('düşük potasyum → yüksek başlangıç K stresi', () {
      final poor = soilBaselineStressFrom(potassiumKgDa: 12);
      final good = soilBaselineStressFrom(potassiumKgDa: 35);
      expect(poor.kStress, greaterThan(good.kStress));
      expect(good.kStress, 0.0);
    });

    test('determinizm: aynı girdi → aynı çıktı', () {
      final a = soilBaselineStressFrom(
          nitrogenPct: 0.04, potassiumKgDa: 18, organicMatterPct: 1.5);
      final b = soilBaselineStressFrom(
          nitrogenPct: 0.04, potassiumKgDa: 18, organicMatterPct: 1.5);
      expect(a.nStress, b.nStress);
      expect(a.kStress, b.kStress);
    });
  });

  test('fakir toprak analizi başlangıç stresini ve verim kaybını artırır',
      () async {
    // Aynı gübreleme + aynı koşullar; tek fark toprak analizi.
    await seedCrop('poor', fertilizerKg: 10);
    await seedCrop('rich', fertilizerKg: 10);
    await seedSoilTest('poor',
        nitrogenPct: 0.03, potassiumKgDa: 12, organicMatterPct: 0.8);
    await seedSoilTest('rich',
        nitrogenPct: 0.20, potassiumKgDa: 40, organicMatterPct: 3.5);

    final engine = GrowthEngine(database);
    final poor = await engine.recompute(
      cropId: 'poor',
      now: DateTime(2026, 4, 24),
    );
    final rich = await engine.recompute(
      cropId: 'rich',
      now: DateTime(2026, 4, 24),
    );

    expect(poor, isNotNull);
    expect(rich, isNotNull);
    expect(poor!.nStressIdx, greaterThan(rich!.nStressIdx));
    expect(poor.kStressIdx, greaterThan(rich.kStressIdx));
    expect(poor.yieldMultiplier, lessThan(rich.yieldMultiplier));
  });

  test('toprak analizi yokken davranış değişmez (geriye dönük güvenli)',
      () async {
    // Analiz olmayan tarla = eski davranış; baseline 0 olmalı.
    await seedCrop('noanalysis', fertilizerKg: 10);
    await seedCrop('zeroanalysis', fertilizerKg: 10);
    // İkincisine besin değerleri "iyi" analiz → yine 0 baseline beklenir.
    await seedSoilTest('zeroanalysis',
        nitrogenPct: 0.25, potassiumKgDa: 45, organicMatterPct: 4.0);

    final engine = GrowthEngine(database);
    final noAnalysis = await engine.recompute(
      cropId: 'noanalysis',
      now: DateTime(2026, 4, 24),
    );
    final zeroAnalysis = await engine.recompute(
      cropId: 'zeroanalysis',
      now: DateTime(2026, 4, 24),
    );

    expect(noAnalysis, isNotNull);
    expect(zeroAnalysis, isNotNull);
    // İyi analiz baseline'ı 0 üretir → analizsizle aynı sonuç.
    expect(zeroAnalysis!.nStressIdx, closeTo(noAnalysis!.nStressIdx, 0.001));
    expect(zeroAnalysis.yieldMultiplier,
        closeTo(noAnalysis.yieldMultiplier, 0.001));
  });

  test('eksik gubreleme azot stresini ve verim carpani etkisini artirir',
      () async {
    await seedCrop('low', fertilizerKg: 2);
    await seedCrop('ok', fertilizerKg: 10);

    final engine = GrowthEngine(database);
    final low = await engine.recompute(
      cropId: 'low',
      now: DateTime(2026, 4, 24),
    );
    final ok = await engine.recompute(
      cropId: 'ok',
      now: DateTime(2026, 4, 24),
    );

    expect(low, isNotNull);
    expect(ok, isNotNull);
    expect(low!.nStressIdx, greaterThan(ok!.nStressIdx));
    expect(low.yieldMultiplier, lessThan(ok.yieldMultiplier));
  });

  test('litreyle girilen sulama su acigini dakika gibi yorumlamaz', () async {
    await seedCrop('dry', fertilizerKg: 10);
    await seedCrop('wet', fertilizerKg: 10);
    for (final day in [3, 6, 9, 12, 15, 18, 21]) {
      await addWaterLiters('wet', DateTime(2026, 4, day), 6000);
    }

    final engine = GrowthEngine(database);
    final dry = await engine.recompute(
      cropId: 'dry',
      now: DateTime(2026, 4, 24),
    );
    final wet = await engine.recompute(
      cropId: 'wet',
      now: DateTime(2026, 4, 24),
    );

    expect(dry, isNotNull);
    expect(wet, isNotNull);
    expect(wet!.waterDeficitMm, lessThan(dry!.waterDeficitMm));
  });

  test('gelecek ve auto_seed sulama kayitlarini su etkisine katmaz', () async {
    await seedCrop('dry2', fertilizerKg: 10);
    await seedCrop('planned', fertilizerKg: 10);
    await addWaterLiters('planned', DateTime(2026, 8, 14), 6000);
    await addWaterLiters(
      'planned',
      DateTime(2026, 4, 20),
      6000,
      source: 'auto_seed',
    );

    final engine = GrowthEngine(database);
    final dry = await engine.recompute(
      cropId: 'dry2',
      now: DateTime(2026, 4, 24),
    );
    final planned = await engine.recompute(
      cropId: 'planned',
      now: DateTime(2026, 4, 24),
    );

    expect(dry, isNotNull);
    expect(planned, isNotNull);
    expect(planned!.waterDeficitMm, closeTo(dry!.waterDeficitMm, 0.001));
  });
}
