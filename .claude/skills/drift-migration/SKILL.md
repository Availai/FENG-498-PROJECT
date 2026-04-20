---
name: drift-migration
description: Use when the user wants to add a new Drift table, column, or index to lib/data/app_database.dart. Triggers like "Drift tablosuna kolon ekle", "yeni Drift tablosu oluştur", "schema bump". Handles schemaVersion increment, migration block, and build_runner regeneration.
---

# drift-migration — Drift Şema Değişikliği

## Amaç
`lib/data/app_database.dart` üzerinde güvenli schema değişikliği yapar: yeni kolon/tablo ekler, `schemaVersion`'u bir artırır, `migration` block'unu günceller, codegen'i tetikler.

## Ön Hazırlık
Dosyayı oku: `lib/data/app_database.dart`. Bul:
- Mevcut `schemaVersion` (örn: `int get schemaVersion => 3;`)
- `MigrationStrategy` tanımı
- Değiştirilecek tablo sınıfı (`Fields`, `FieldCrops`, ...)

## Senaryo A — Mevcut Tabloya Kolon Ekleme

### 1. Tablo Sınıfını Güncelle
Örnek: `Fields` tablosuna `altitude` ekle.
```dart
class Fields extends Table {
  IntColumn get id => integer().autoIncrement()();
  // ... mevcut kolonlar ...
  RealColumn get altitude => real().nullable()();  // ← YENİ
}
```
Kolon nullable olmalı (mevcut satırlar için default değer gerekir yoksa).

### 2. schemaVersion Artır
```dart
int get schemaVersion => 4;  // önce 3'tü
```

### 3. Migration Block'una Ekle
```dart
MigrationStrategy get migration => MigrationStrategy(
  onCreate: (Migrator m) => m.createAll(),
  onUpgrade: (Migrator m, int from, int to) async {
    if (from < 2) { /* önceki */ }
    if (from < 3) { /* önceki */ }
    if (from < 4) {
      await m.addColumn(fields, fields.altitude);  // ← YENİ
    }
  },
);
```

## Senaryo B — Yeni Tablo

### 1. Tablo Sınıfını Tanımla
```dart
class WeatherLogs extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get farmerUid => text()();  // per-user isolation!
  IntColumn get fieldId => integer().references(Fields, #id)();
  DateTimeColumn get recordedAt => dateTime()();
  RealColumn get tempC => real()();
  // ...
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
}
```

**Per-user isolation zorunluluğu**: Yeni ana entity tablolarında `farmerUid TEXT NOT NULL` olmalı. Join tabloları bu şarttan muaftır.

### 2. `@DriftDatabase` listesine ekle
```dart
@DriftDatabase(tables: [
  Fields, FieldCrops, CalendarEvents, IrrigationPlans,
  SuitabilityReports, SyncJobs, SyncState,
  WeatherLogs,  // ← YENİ
])
```

### 3. schemaVersion Artır ve Migration Ekle
```dart
if (from < 4) {
  await m.createTable(weatherLogs);
}
```

## Codegen

```bash
dart run build_runner build --delete-conflicting-outputs
```

Çıktıda `[INFO] Succeeded after Xs with N outputs` bekle.

`lib/data/app_database.g.dart` güncellenmiş olmalı — ValidateEdit ile dosya boyutu değiştiğini doğrula.

## Doğrulama

```bash
flutter analyze lib/data/
```

0 issue beklenir. Hata varsa muhtemel sebepler:
- `schemaVersion` artırılmadı
- `migration` block'unda `if (from < N)` eklenmedi
- Tablo sınıfı `@DriftDatabase` listesinde değil

## Uyarılar
- **SQLite downgrade yoktur**: schemaVersion geri gidilemez. Yeni sürüm çıkmadan önce migration'ı iyi test et.
- **Production veri kaybı riski**: `dropTable` asla kullanma; gerekirse yeni tablo + veri kopyalama yap.
- **Per-user isolation**: Yeni entity `farmerUid` taşımıyorsa, `SyncRepository` ve `LocalDataRepository` filtreleri eklenmeli (yoksa kullanıcılar birbirinin verisini görür).
- **SyncJobs entegrasyonu**: Yeni tablo sync edilecekse, `SyncService` outbox'a ekleme çağrıları ilgili repository'ye eklenmeli.
