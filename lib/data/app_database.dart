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

  /// Bitkinin baktığı yön — PlantFacingDirection.name değeri (ör. 'south').
  /// null ise belirsiz/girilmemiş.
  TextColumn get facingDirection => text().nullable()();

  /// Çok yıllık ürünler (portakal, çay) için: kullanıcı bu kaydı yeni
  /// fidan olarak mı, yoksa olgun ağaç olarak mı diktiğini belirtir.
  ///   - true  → yeni fidan; CropStateService 'perennialSeedling' modu.
  ///   - false → olgun ağaç/bahçe; 'perennialMature' modu.
  ///   - null  → bilinmiyor; tarih + bitki tipi üzerinden tahmin edilir
  ///            (3+ yaş varsayılan olarak mature).
  ///
  /// Tek yıllık bitkilerde (domates, mısır vb.) anlamı yok — null kalır.
  /// CLAUDE.md sec 11 + CropStateService.modeFor() ile eşleşir.
  BoolColumn get isSeedling => boolean().nullable()();

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

  /// Aktivite kapsamı: 'field' | 'zone' | 'plant'. null → field varsayılır. (v8)
  TextColumn get targetScope => text().nullable()();

  /// Tekil bitkiye iliştirilen aktivite — FieldPlantInstances.id ile eşleşir.
  /// FK constraint yok (Drift forward-reference riskinden kaçınmak için);
  /// referans bütünlüğü uygulama katmanında korunur. (v8)
  TextColumn get plantInstanceId => text().nullable()();

  /// Aktivite alt-tipi: 'disease_observation' | 'pest_observation' |
  /// 'hoeing' | 'thinning' | 'note'. eventType ile birlikte kullanılır;
  /// alt-tip null ise eventType tek başına yeterlidir. (v8)
  TextColumn get subtype => text().nullable()();

  /// Aktivite fotoğrafı yerel yolu (app docs altında, WebP). (v8)
  TextColumn get photoPath => text().nullable()();

  /// Çiftçi serbest metin notu — subtype='note' kayıtlarında zorunlu,
  /// diğer aktivitelerde opsiyonel açıklama. (v8)
  TextColumn get noteText => text().nullable()();
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
  /// 7-day moving average ile yumuşatılır → günlük oynaklık bastırılır.
  RealColumn get nStressIdx => real().withDefault(const Constant(0))();

  /// Potasyum (K) stresi 0..1 — NPK gübre tipinden K oranı toplanarak
  /// hesaplanır. Çiçek/meyve evrelerinde verim çarpanı düşürür. (v6)
  RealColumn get kStressIdx => real().withDefault(const Constant(0))();

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

/// Tarla içindeki tekil bitkiler — hem kullanıcının manuel eklediği standalone
/// bitkiler hem de zone içindeki "hasta/ölü" override'ları için tek tablo.
///
/// Üç kullanım senaryosu:
///   • cropId=null + plantIndex=null → Standalone tekil bitki
///     (kullanıcı haritada boş bir noktaya tıkladığında oluşturulur)
///   • cropId=set + plantIndex=set → Zone içindeki belirli bir bitkinin
///     sağlık durumu override'ı (zone marker'ının üstüne badge)
///   • cropId=set + plantIndex=null → Tüm zone'a uygulanan genel not
///     (şu an kullanılmıyor; ileride genişlemeye açık)
class FieldPlantInstances extends Table {
  TextColumn get id => text()();
  TextColumn get fieldId => text().references(Fields, #id)();
  TextColumn get cropId => text().nullable().references(FieldCrops, #id)();
  IntColumn get plantIndex => integer().nullable()();
  TextColumn get cropName => text()();
  RealColumn get lat => real()();
  RealColumn get lng => real()();

  /// 'healthy' | 'diseased' | 'dead'
  TextColumn get healthStatus =>
      text().withDefault(const Constant('healthy'))();

  /// 'Mildiyö', 'Pas', 'Yaprak Lekesi', vb. (manuel veya AI sonucu)
  TextColumn get diseaseType => text().nullable()();

  /// Hastalık fotoğrafı yerel yolu (app docs altında).
  TextColumn get diseasePhotoPath => text().nullable()();

  /// 'manual' | 'ai_pending' | 'ai_completed'
  TextColumn get diagnosisSource =>
      text().withDefault(const Constant('manual'))();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get plantedAt => dateTime()();
  DateTimeColumn get healthChangedAt => dateTime().nullable()();

  /// Çoklu nüans bayrağı JSON — ['water_stress','nutrient_deficiency','flowering'].
  /// healthStatus üç-değerli kaba durumu tutarken bu liste niteliksel
  /// detayları taşır; tavsiye motoru her ikisini de okur. (v8)
  TextColumn get conditionFlagsJson => text().nullable()();

  /// Tekil bitki için fenoloji evresi override'ı. null ise zone'un
  /// CropGrowthStates.currentStageKey değerinden miras alınır. (v8)
  TextColumn get phenologyStageKey => text().nullable()();

  /// Tekil bitkinin baktığı yön. Toplu ekimlerde FieldCrops.facingDirection
  /// kullanılır; standalone bitkiler kendi yönünü burada tutar. (v10)
  TextColumn get facingDirection => text().nullable()();

  /// Son kullanıcı/AI gözlem tarihi — durum geçmişi sıralaması için. (v8)
  DateTimeColumn get lastObservedAt => dateTime().nullable()();
  TextColumn get farmerUid => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Tekil bitki bazında durum gözlem geçmişi — audit log.
/// FieldPlantInstances 1:1 "şu anki durum" satırı tutarken bu tablo
/// "hangi tarihte hangi durum kaydedildi" sorusunu cevaplar. UI'daki durum
/// geçmişi paneli ve tavsiye motorunun "son N gün" pencereleri buradan okur.
class PlantConditionEvents extends Table {
  TextColumn get id => text()();
  TextColumn get plantInstanceId => text()();
  TextColumn get fieldId => text()();
  TextColumn get cropId => text().nullable()();

  /// 'healthy' | 'disease_symptom' | 'pest_risk' | 'water_stress' |
  /// 'nutrient_deficiency' | 'stunted' | 'flowering' | 'grain_filling' |
  /// 'near_harvest' | 'dead' | 'removed_by_user'
  TextColumn get condition => text()();

  /// 'manual' | 'auto' | 'ai'
  TextColumn get sourceType => text().withDefault(const Constant('manual'))();
  TextColumn get notes => text().nullable()();
  TextColumn get photoPath => text().nullable()();
  DateTimeColumn get observedAt => dateTime()();
  TextColumn get farmerUid => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Çiftçinin akredite laboratuvardan aldığı GERÇEK toprak analizi sonuçları.
/// Örnek, tarlanın istediği bir kısmından alınır; `sampleLabel` o kısmı
/// (ör. "Kuzey köşe", "dere kenarı") serbest metin olarak tutar. Tüm ölçüm
/// alanları nullable — raporda olmayan değer girilmez ve yorumlanmaz.
/// Kullanıcıya ait kayıt (CLAUDE.md §5.5) → `farmerUid` taşır.
class SoilTests extends Table {
  TextColumn get id => text()();
  TextColumn get farmerUid => text().nullable()();
  TextColumn get fieldId => text().references(Fields, #id)();

  /// Örneğin alındığı tarla kısmı (serbest metin).
  TextColumn get sampleLabel => text().nullable()();

  /// Analizi yapan laboratuvar/kurum adı.
  TextColumn get labName => text().nullable()();

  /// Örneğin alındığı/analiz tarihi.
  DateTimeColumn get sampledAt => dateTime().nullable()();

  RealColumn get ph => real().nullable()();

  /// % toplam tuz (satüre çamur).
  RealColumn get saltPct => real().nullable()();

  /// EC — elektriksel iletkenlik (dS/m).
  RealColumn get ecDsM => real().nullable()();

  /// Kireç CaCO₃ %.
  RealColumn get limePct => real().nullable()();

  /// Organik madde %.
  RealColumn get organicMatterPct => real().nullable()();

  /// Fosfor P₂O₅ kg/dekar.
  RealColumn get phosphorusKgDa => real().nullable()();

  /// Potasyum K₂O kg/dekar.
  RealColumn get potassiumKgDa => real().nullable()();

  /// Toplam azot %.
  RealColumn get nitrogenPct => real().nullable()();

  /// Suyla doygunluk %.
  RealColumn get saturationPct => real().nullable()();

  /// Doku sınıfı (girilen veya doygunluktan türetilen).
  TextColumn get textureClass => text().nullable()();

  /// Örneğin haritadan seçilen noktası (tarla içi). null → harita seçimi yok.
  RealColumn get sampleLat => real().nullable()();
  RealColumn get sampleLng => real().nullable()();

  /// Örnek alanının yarıçapı (metre). Haritadan alan seçilince yazılır;
  /// null → yarıçap belirtilmemiş (eski kayıt veya yalnızca nokta).
  RealColumn get sampleRadius => real().nullable()();

  TextColumn get notes => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Çiftçinin masraf (gider) kayıtları — ürün bazlı maliyet için.
/// Yalnızca MANUEL giderler burada tutulur (mazot, tohum, işçilik, ilaç,
/// "diğer"). Gübre gideri ayrıca loglanan aktivitelerden anlık türetilir
/// (CostService) — burada da manuel gübre eklenebilir. `cropId` null ise
/// gider tarla geneli/paylaşılan kabul edilir. Kullanıcıya ait kayıt →
/// `farmerUid` taşır (CLAUDE.md §5.5).
class CostEntries extends Table {
  TextColumn get id => text()();
  TextColumn get farmerUid => text().nullable()();
  TextColumn get fieldId => text().references(Fields, #id)();

  /// Giderin atandığı ürün (FieldCrops.id). null → tarla geneli.
  TextColumn get cropId => text().nullable()();

  /// Gider türü: 'fertilizer'|'fuel'|'seed'|'labor'|'pesticide'|'irrigation'|'other'.
  TextColumn get kind => text()();

  /// Toplam tutar (₺).
  RealColumn get amountTry => real()();

  /// İsteğe bağlı miktar + birim + birim fiyat (kırılım/şeffaflık için).
  RealColumn get quantity => real().nullable()();
  TextColumn get unit => text().nullable()();
  RealColumn get unitPriceTry => real().nullable()();

  TextColumn get note => text().nullable()();
  DateTimeColumn get date => dateTime()();
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
    FieldPlantInstances,
    PlantConditionEvents,
    SoilTests,
    CostEntries,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 14;
  int get schemaVersion => 14;

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
            if (from < 5) {
              // v5: Per-bitki sağlık takibi + tekil bitki yerleştirme.
              await m.createTable(fieldPlantInstances);
            }
            if (from < 6) {
              // v6: K (potasyum) stresi kolonu — NPK ayrımı için.
              await m.addColumn(cropGrowthStates, cropGrowthStates.kStressIdx);
            }
            if (from < 7) {
              // v7: Bitki yön bilgisi — güneş maruziyeti ve mikro-iklim için.
              await customStatement(
                  'ALTER TABLE field_crops ADD COLUMN facing_direction TEXT;');
            }
            if (from < 8) {
              // v8: aktivite kapsamı + tekil-bitki scope + alt-tip + foto + not.
              await m.addColumn(calendarEvents, calendarEvents.targetScope);
              await m.addColumn(calendarEvents, calendarEvents.plantInstanceId);
              await m.addColumn(calendarEvents, calendarEvents.subtype);
              await m.addColumn(calendarEvents, calendarEvents.photoPath);
              await m.addColumn(calendarEvents, calendarEvents.noteText);
              // v8: tekil bitki nüans bayrakları + fenoloji override + son
              // gözlem zamanı.
              await m.addColumn(
                  fieldPlantInstances, fieldPlantInstances.conditionFlagsJson);
              await m.addColumn(
                  fieldPlantInstances, fieldPlantInstances.phenologyStageKey);
              await m.addColumn(
                  fieldPlantInstances, fieldPlantInstances.lastObservedAt);
            }
            if (from < 9) {
              // v9: tekil bitki durum gözlem geçmişi tablosu.
              await m.createTable(plantConditionEvents);
            }
            if (from < 10) {
              // v10: standalone tekil bitkiler için baktığı yön oku.
              await m.addColumn(
                  fieldPlantInstances, fieldPlantInstances.facingDirection);
            }
            if (from < 11) {
              // v11: çok yıllık ürünler için 'yeni fidan mı / olgun mu?'
              // ayrımı. CropStateService bunu okur ve doğru % state +
              // disclaimer üretir. Diğer migration'lardaki örüntüye
              // uygun olarak customStatement ile eklenir (build_runner
              // regenerate gerektirmez).
              await customStatement(
                  'ALTER TABLE field_crops ADD COLUMN is_seedling INTEGER;');
            }
            if (from < 12) {
              // v12: çiftçinin laboratuvardan aldığı gerçek toprak analizi
              // sonuçları için yeni tablo (lab girişi + deterministik öneri).
              await m.createTable(soilTests);
            }
            if (from < 13) {
              // v13: toprak analizi örnek noktası koordinatları (haritadan
              // seçim). v12'de soil_tests tablosunu lat/lng'siz oluşturmuş
              // cihazlara kolonları ekler. from<12 yolunda tablo zaten güncel
              // tanımla (lat/lng dahil) oluştuğundan tekrar-ekleme hatasını
              // tek tek yutarız (yoksa tüm migration aborte olurdu).
              try {
                await customStatement(
                    'ALTER TABLE soil_tests ADD COLUMN sample_lat REAL;');
              } catch (_) {}
              try {
                await customStatement(
                    'ALTER TABLE soil_tests ADD COLUMN sample_lng REAL;');
              } catch (_) {}
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
