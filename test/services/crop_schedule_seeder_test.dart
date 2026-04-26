import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:feng_498/data/activity_types.dart';
import 'package:feng_498/data/app_database.dart';
import 'package:feng_498/services/crop_schedule_seeder.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    final now = DateTime(2026, 4, 25);
    await db.into(db.fields).insert(
          FieldsCompanion.insert(
            id: 'field-1',
            name: 'Deneme tarlası',
            crop: const Value('Ayçiçeği'),
            date: '25.04.2026',
            areaDekar: const Value(2),
            areaSqm: const Value(2000),
            createdAt: now,
            updatedAt: now,
          ),
        );
    await db.into(db.fieldCrops).insert(
          FieldCropsCompanion.insert(
            id: 'crop-1',
            fieldId: 'field-1',
            name: 'Ayçiçeği',
            zoneStart: 0,
            zoneEnd: 1,
            rowSpacingCm: 70,
            plantSpacingCm: 30,
            plantedDate: const Value('01.04.2026'),
            harvestDays: const Value(120),
            waterIntervalDays: const Value(7),
            createdAt: now,
            updatedAt: now,
          ),
        );
  });

  tearDown(() async {
    await db.close();
  });

  test('aycicegi auto_seed ilaclama yerine gozlem etkinligi yazar', () async {
    final seeder = CropScheduleSeeder(db);

    await seeder.seedForCrop(
      fieldId: 'field-1',
      cropId: 'crop-1',
      cropName: 'Ayçiçeği',
      plantedDate: DateTime(2026, 4),
      harvestDays: 120,
      waterIntervalDays: 7,
      areaDekar: 2,
      now: DateTime(2026, 4, 25),
    );

    final rows = await (db.select(db.calendarEvents)
          ..where((tbl) => tbl.cropId.equals('crop-1')))
        .get();

    expect(
      rows.where((row) => row.eventType == ActivityType.spraying),
      isEmpty,
    );
    expect(
      rows.where((row) => row.eventType == ActivityType.scouting),
      isNotEmpty,
    );
  });
}
