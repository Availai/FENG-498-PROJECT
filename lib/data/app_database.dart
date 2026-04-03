import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'app_database.g.dart';

class Fields extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get crop => text().nullable()();
  TextColumn get date => text()();
  RealColumn get latitude => real().nullable()();
  RealColumn get longitude => real().nullable()();
  RealColumn get areaDekar => real().nullable()();
  RealColumn get areaSqm => real().nullable()();
  TextColumn get polygonJson => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class FieldCrops extends Table {
  TextColumn get id => text()();
  TextColumn get fieldId => text().references(Fields, #id)();
  TextColumn get name => text()();
  RealColumn get zoneStart => real()();
  RealColumn get zoneEnd => real()();
  RealColumn get rowSpacingCm => real()();
  RealColumn get plantSpacingCm => real()();
  IntColumn get colorValue => integer().nullable()();
  TextColumn get plantedDate => text().nullable()();
  IntColumn get harvestDays => integer().nullable()();
  IntColumn get waterIntervalDays => integer().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class CalendarEvents extends Table {
  TextColumn get id => text()();
  TextColumn get fieldId => text().nullable().references(Fields, #id)();
  TextColumn get cropId => text().nullable().references(FieldCrops, #id)();
  TextColumn get title => text()();
  TextColumn get eventType => text()();
  DateTimeColumn get eventDate => dateTime()();
  TextColumn get source => text().withDefault(const Constant('manual'))();
  TextColumn get metadataJson => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class IrrigationPlans extends Table {
  TextColumn get id => text()();
  TextColumn get fieldId => text().references(Fields, #id)();
  TextColumn get cropId => text().nullable().references(FieldCrops, #id)();
  DateTimeColumn get scheduledDate => dateTime()();
  BoolColumn get shouldIrrigate => boolean().withDefault(const Constant(true))();
  TextColumn get reason => text()();
  TextColumn get recommendation => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class SuitabilityReports extends Table {
  TextColumn get id => text()();
  TextColumn get fieldId => text().references(Fields, #id)();
  TextColumn get cropName => text()();
  RealColumn get score => real().nullable()();
  TextColumn get reportJson => text()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class SyncJobs extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get entityType => text()();
  TextColumn get entityId => text()();
  TextColumn get operation => text()();
  TextColumn get payloadJson => text()();
  DateTimeColumn get updatedAt => dateTime()();
  IntColumn get attemptCount => integer().withDefault(const Constant(0))();
  TextColumn get lastError => text().nullable()();
  TextColumn get status => text().withDefault(const Constant('pending'))();
}

class SyncState extends Table {
  TextColumn get key => text()();
  TextColumn get value => text().nullable()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {key};
}

@DriftDatabase(
  tables: [
    Fields,
    FieldCrops,
    CalendarEvents,
    IrrigationPlans,
    SuitabilityReports,
    SyncJobs,
    SyncState,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          await _createIndexes();
        },
        onUpgrade: (m, from, to) async {
          // Şimdilik şema v1; gelecekte sürüm yükseltmelerinde adımlı migration eklenecek.
          await _createIndexes();
        },
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );

  Future<void> _createIndexes() async {
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_sync_jobs_status_updated_at '
      'ON sync_jobs (status, updated_at)'
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_sync_jobs_entity '
      'ON sync_jobs (entity_type, entity_id)'
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_calendar_events_date '
      'ON calendar_events (event_date)'
    );
  }

}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    File file;
    try {
      final dir = await getApplicationDocumentsDirectory();
      file = File(p.join(dir.path, 'smart_agri_local.sqlite'));
    } catch (_) {
      final fallbackDir = Directory.systemTemp;
      file = File(p.join(fallbackDir.path, 'smart_agri_local.sqlite'));
    }
    return NativeDatabase.createInBackground(file);
  });
}
