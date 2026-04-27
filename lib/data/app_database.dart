import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'app_database.g.dart';

class Fields extends Table {
  TextColumn get id => text()();
  TextColumn get farmerUid => text().nullable()();
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

  /// Sub-polygon JSON: [{"lat":..., "lng":...}, ...]
  /// null ise bitki tüm tarla alanına ekilmiş kabul edilir.
  TextColumn get zonePolygonJson => text().nullable()();
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

  /// Çiftçinin gerçekten uyguladığı miktar (ör. sulama dk, gübre kg, ilaç mL).
  /// metadata_json içinde de tutulur; bu kolon GrowthEngine sorguları için
  /// indekslenebilir hızlı erişim sağlar (v4).
  RealColumn get quantity => real().nullable()();

  /// Miktar birimi — 'dk', 'kg', 'L', 'g', 'mL'. (v4)
  TextColumn get unit => text().nullable()();

  /// Direktif motorunun aynı anda önerdiği miktar — eksik/fazla oranını
  /// hesaplamak için. Null ise öneri-dışı manuel kayıt. (v4)
  RealColumn get recommendedQuantity => real().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Bir ekinin anlık büyüme durumu — GrowthEngine günde bir overwrite eder.
/// Her FieldCrop için tek satır (primary key = cropId). UI "gerçek zamanlı
/// büyüyen bitki" görsellemesinde bu tek kaydı okur; tarihsel seri gerekmez.
class CropGrowthStates extends Table {
  /// FieldCrops.id ile aynı — 1:1 ilişki.
  TextColumn get cropId => text()();
  TextColumn get fieldId => text()();

  /// Son hesaplama tarihi (local midnight).
  DateTimeColumn get asOfDate => dateTime()();

  /// Ekimden bu yana biriken GDD (gün-derece). Tbase bitkiye göre değişir.
  RealColumn get accumulatedGdd => real().withDefault(const Constant(0))();

  /// Aktif fenoloji evresi: 'cimlenme' | 'vejetatif' | 'ciceklenme' |
  /// 'meyve_dolumu' | 'olgunlasma' | 'hasat'.
  TextColumn get currentStageKey =>
      text().withDefault(const Constant('cimlenme'))();

  /// Aktif evre içindeki ilerleme (0..1). Büyüme animasyonu bu değeri okur.
  RealColumn get stageProgress => real().withDefault(const Constant(0))();

  /// Sulama açığı (mm) — öneriye göre eksik veren toplam. 0 = ideal, >0 stres.
  RealColumn get waterDeficitMm => real().withDefault(const Constant(0))();

  /// Azot (N) stresi 0..1 — gübreleme eksikliğinin kümülatif etkisi.
  RealColumn get nStressIdx => real().withDefault(const Constant(0))();

  /// Hastalık baskısı 0..1 — yağmur + eksik ilaçlama kombinasyonu.
  RealColumn get diseasePressure => real().withDefault(const Constant(0))();

  /// Tahmin edilen boy (cm) — görsel büyüme için.
  RealColumn get heightCm => real().withDefault(const Constant(0))();

  /// Göreceli biyokütle 0..1 (sigmoid).
  RealColumn get biomassRel => real().withDefault(const Constant(0))();

  /// Verim çarpanı — 0.5..1.15 aralığında; her stres zinciri bunu aşağı çeker.
  RealColumn get yieldMultiplier => real().withDefault(const Constant(1.0))();
  DateTimeColumn get lastComputedAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {cropId};
}

class IrrigationPlans extends Table {
  TextColumn get id => text()();
  TextColumn get fieldId => text().references(Fields, #id)();
  TextColumn get cropId => text().nullable().references(FieldCrops, #id)();
  DateTimeColumn get scheduledDate => dateTime()();
  BoolColumn get shouldIrrigate =>
      boolean().withDefault(const Constant(true))();
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
    CropGrowthStates,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
        },
        onUpgrade: (m, from, to) async {
          // Migration hatası app'i fatal çökertmesin — log + sessiz geçiş.
          // Tek bir sütun eklenemezse, eksik veri ile devam etmek beyaz
          // ekranda donmaktan iyi; sonraki sürümde yeniden denenebilir.
          try {
            if (from < 2) {
              await m.addColumn(fieldCrops, fieldCrops.zonePolygonJson);
            }
            if (from < 3) {
              // v3: Fields tablosuna farmerUid TEXT nullable sütun ekle
              await customStatement(
                  'ALTER TABLE fields ADD COLUMN farmer_uid TEXT;');
            }
            if (from < 4) {
              // v4: CalendarEvents'e miktar/birim/önerilen-miktar kolonları +
              // yeni CropGrowthStates tablosu.
              await m.addColumn(calendarEvents, calendarEvents.quantity);
              await m.addColumn(calendarEvents, calendarEvents.unit);
              await m.addColumn(
                  calendarEvents, calendarEvents.recommendedQuantity);
              await m.createTable(cropGrowthStates);
            }
          } catch (e, st) {
            debugPrint('Drift migration $from→$to hata: $e\n$st');
          }
        },
      );
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

    // WAL (Write-Ahead Logging) modu: okuma ve yazma birbirini kilitlemez.
    // busy_timeout: başka bir işlem DB'yi tutarken 5s bekleyip yeniden dener
    // → SqliteException(5) "database is locked" hatasını ortadan kaldırır.
    // synchronous=NORMAL: WAL ile birlikte yeterli güvenlik + daha hızlı commit.
    return NativeDatabase(
      file,
      setup: (db) {
        db.execute('PRAGMA journal_mode=WAL;');
        db.execute('PRAGMA busy_timeout=5000;');
        db.execute('PRAGMA synchronous=NORMAL;');
        db.execute('PRAGMA foreign_keys=ON;');
        db.execute('PRAGMA cache_size=-4096;'); // 4MB sayfa önbelleği
      },
    );
  });
}
