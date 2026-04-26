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
      String cropId, DateTime date, double liters) async {
    final now = DateTime.utc(2026, 4, 24);
    await database.into(database.calendarEvents).insert(
          CalendarEventsCompanion.insert(
            id: 'water-$cropId-${date.day}',
            fieldId: Value('field-$cropId'),
            cropId: Value(cropId),
            title: 'Sulama',
            eventType: ActivityType.watering,
            eventDate: date,
            unit: const Value('L'),
            metadataJson: Value(
                '{"water_liters":$liters,"irrigation_method":"Damla sulama"}'),
            createdAt: now,
            updatedAt: now,
          ),
        );
  }

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
}
