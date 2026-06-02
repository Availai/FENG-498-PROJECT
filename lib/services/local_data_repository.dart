import 'dart:convert';
import 'dart:math';

import 'package:drift/drift.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;

import '../data/activity_types.dart';
import '../data/app_database.dart';
import 'crop_protocol_service.dart';

class LocalDataRepository {
  LocalDataRepository({
    required AppDatabase database,
    this.currentUid,
  }) : _db = database;

  final AppDatabase _db;
  final String? currentUid;

  Box get _legacyFieldsBox => Hive.box('user_crops');
  Box get _settingsBox => Hive.box('settingsBox');

  Future<void> bootstrapFromLegacyHive() async {
    // Kullanıcı girişi olmadan bootstrap yapma — tarlalar hesaba özel.
    if (currentUid == null) return;

    // Global migration flag — pre-Drift Hive verisi TEK SEFER migrate edilir.
    // Bu flag set edildikten sonra user_crops box'ı artık veri kaynağı değil;
    // sadece UI reaktivitesi için aynalama (mirror) amacıyla kullanılır.
    const globalMigrationKey = 'drift_legacy_hive_migrated_v2';
    final alreadyMigratedGlobally =
        _settingsBox.get(globalMigrationKey) == true;

    if (!alreadyMigratedGlobally) {
      // İlk Drift migrasyonu — Hive user_crops'taki pre-existing veriyi
      // mevcut kullanıcıya atfederek Drift'e aktar. Tüm upsert'leri tek bir
      // Drift transaction'ına sararak N×fsync yerine tek commit yapıyoruz;
      // 50+ tarlada fark edilir hızlanma.
      if (_legacyFieldsBox.isNotEmpty) {
        await _db.transaction(() async {
          for (int i = 0; i < _legacyFieldsBox.length; i++) {
            final raw = _legacyFieldsBox.getAt(i);
            if (raw is! Map) continue;
            final legacy = Map<String, dynamic>.from(raw);
            final fieldId = await upsertFieldFromLegacyMap(
              legacy,
              enqueueSync: false,
              mirrorLegacy: false,
            );

            final planted = legacy['planted_crops'];
            if (planted is List) {
              final crops = planted
                  .whereType<Map>()
                  .map((item) => Map<String, dynamic>.from(item))
                  .toList();
              await replaceFieldCrops(
                fieldId: fieldId,
                crops: crops,
                enqueueSync: false,
                mirrorLegacy: false,
              );
            }
          }
        });
      }
      await _settingsBox.put(globalMigrationKey, true);
    }

    // Aktif kullanıcı değiştiğinde Hive mirror'ı temizle — önceki kullanıcının
    // aynasındaki kayıtlar yeni kullanıcıya sızmasın.
    await _legacyFieldsBox.clear();
    await _mirrorActiveFieldsToHive();
  }

  Stream<List<Map<String, dynamic>>> watchFieldMaps() {
    final query = _activeFieldsQuery();
    return query.watch().asyncMap((_) => loadFieldMaps());
  }

  Future<List<Map<String, dynamic>>> loadFieldMaps() async {
    final rows = await _activeFieldsQuery().get();
    final result = <Map<String, dynamic>>[];
    for (final row in rows) {
      result.add(await _buildLegacyFieldMap(row));
    }
    result.sort((a, b) =>
        (b['updated_at'] as String).compareTo(a['updated_at'] as String));
    return result;
  }

  Future<Map<String, dynamic>?> loadFieldById(String fieldId) async {
    final row = await (_db.select(_db.fields)
          ..where((tbl) => tbl.id.equals(fieldId) & tbl.deletedAt.isNull()))
        .getSingleOrNull();
    if (row == null) return null;
    return _buildLegacyFieldMap(row);
  }

  Future<String> createManualField({
    required String name,
    double? latitude,
    double? longitude,
  }) async {
    return upsertFieldFromLegacyMap({
      'name': name,
      'crop': 'Belirtilmedi',
      'date': _formatDate(DateTime.now()),
      'latitude': latitude,
      'longitude': longitude,
    });
  }

  Future<String> upsertFieldFromLegacyMap(
    Map<String, dynamic> raw, {
    bool enqueueSync = true,
    bool mirrorLegacy = true,
  }) async {
    final now = DateTime.now().toUtc();
    final isNewField = !(raw['id']?.toString().trim().isNotEmpty ?? false);
    final fieldId = isNewField ? _newId('field') : raw['id'].toString();
    final createdAt = _parseTimestamp(raw['created_at']) ?? now;

    await _db.into(_db.fields).insertOnConflictUpdate(
          FieldsCompanion(
            id: Value(fieldId),
            farmerUid: Value(currentUid),
            name: Value((raw['name'] ?? 'İsimsiz Tarla').toString()),
            crop: Value(raw['crop']?.toString()),
            date:
                Value((raw['date'] ?? _formatDate(DateTime.now())).toString()),
            latitude: Value(_asDouble(raw['latitude'])),
            longitude: Value(_asDouble(raw['longitude'])),
            areaDekar: Value(_asDouble(raw['area_dekar'])),
            areaSqm: Value(_asDouble(raw['area_sqm'])),
            polygonJson: Value(_encodeJson(raw['polygon'])),
            createdAt: Value(createdAt),
            updatedAt: Value(now),
            deletedAt: const Value(null),
          ),
        );

    // Yeni tarla oluşturulursa takvime ekim kaydı düş
    if (isNewField) {
      await _db.into(_db.calendarEvents).insert(
            CalendarEventsCompanion.insert(
              id: _newId('event'),
              fieldId: Value(fieldId),
              title: 'Tarla oluşturuldu',
              eventType: 'planting',
              eventDate: DateTime.now().toUtc(),
              createdAt: now,
              updatedAt: now,
            ),
          );
    }

    if (enqueueSync) {
      await _enqueueSyncJob(
        entityType: 'fields',
        entityId: fieldId,
        operation: 'upsert',
        payload: {
          ...Map<String, dynamic>.from(raw),
          'id': fieldId,
          'updated_at': now.toIso8601String(),
        },
        updatedAt: now,
      );
    }

    if (mirrorLegacy) {
      await _mirrorActiveFieldsToHive();
    }
    return fieldId;
  }

  /// Tarlayı ve ilgili TÜM geçmiş kayıtlarını siler:
  ///   - Fields (hard-delete)
  ///   - FieldCrops (hard-delete)
  ///   - IrrigationPlans (hard-delete)
  ///   - CalendarEvents (hard-delete) — ekim/hasat/sulama/gübreleme/ilaçlama geçmişi
  ///   - SuitabilityReports (hard-delete) — bitki uygunluk raporları
  ///   - CropGrowthStates (hard-delete) — FK yok; silinen ekine ait büyüme
  ///     durumu hayaleti kalmasın.
  ///
  /// Silme sonrasında her entity için sync outbox'a `delete` job'u düşer;
  /// bulutta da aynı temizlik yayılır.
  Future<void> deleteField(String fieldId) async {
    final now = DateTime.now().toUtc();

    // Silmeden önce ekin kayıtlarını + ilişkili id'leri topla
    // (sync outbox + crop_protocol_state temizliği için gerek var).
    final cropsToClear = await (_db.select(_db.fieldCrops)
          ..where(
              (tbl) => tbl.fieldId.equals(fieldId) & tbl.deletedAt.isNull()))
        .get();
    final cropIds = cropsToClear.map((c) => c.id).toList();
    final irrigationIds = (await (_db.select(_db.irrigationPlans)
              ..where((tbl) =>
                  tbl.fieldId.equals(fieldId) & tbl.deletedAt.isNull()))
            .get())
        .map((p) => p.id)
        .toList();
    final calendarIds = (await (_db.select(_db.calendarEvents)
              ..where((tbl) =>
                  tbl.fieldId.equals(fieldId) & tbl.deletedAt.isNull()))
            .get())
        .map((e) => e.id)
        .toList();
    final suitabilityIds = (await (_db.select(_db.suitabilityReports)
              ..where((tbl) =>
                  tbl.fieldId.equals(fieldId) & tbl.deletedAt.isNull()))
            .get())
        .map((r) => r.id)
        .toList();
    final soilTestIds = (await (_db.select(_db.soilTests)
              ..where((tbl) =>
                  tbl.fieldId.equals(fieldId) & tbl.deletedAt.isNull()))
            .get())
        .map((s) => s.id)
        .toList();

    await _db.transaction(() async {
      // Kalıcı temizlik: tarla ve ilişkili geçmiş kayıtları fiziksel olarak sil.
      await (_db.delete(_db.calendarEvents)
            ..where((tbl) => tbl.fieldId.equals(fieldId)))
          .go();
      // Ek: fieldId null olup cropId ile bağlı günlük kayıtlarını da sil
      if (cropIds.isNotEmpty) {
        await (_db.delete(_db.calendarEvents)
              ..where((tbl) => tbl.cropId.isIn(cropIds)))
            .go();
      }
      // v5: tarlanın tekil bitki kayıtlarını da temizle
      await (_db.delete(_db.fieldPlantInstances)
            ..where((tbl) => tbl.fieldId.equals(fieldId)))
          .go();
      await (_db.delete(_db.irrigationPlans)
            ..where((tbl) => tbl.fieldId.equals(fieldId)))
          .go();
      await (_db.delete(_db.suitabilityReports)
            ..where((tbl) => tbl.fieldId.equals(fieldId)))
          .go();
      // v12: tarlanın toprak analizi kayıtlarını da temizle.
      await (_db.delete(_db.soilTests)
            ..where((tbl) => tbl.fieldId.equals(fieldId)))
          .go();

      // CropGrowthStates — fieldId ile bağlı satırları temizle.
      await (_db.delete(_db.cropGrowthStates)
            ..where((tbl) => tbl.fieldId.equals(fieldId)))
          .go();

      await (_db.delete(_db.fieldCrops)
            ..where((tbl) => tbl.fieldId.equals(fieldId)))
          .go();
      await (_db.delete(_db.fields)..where((tbl) => tbl.id.equals(fieldId)))
          .go();
    });

    // Sync outbox — her entity için ayrı delete job
    await _enqueueSyncJob(
      entityType: 'fields',
      entityId: fieldId,
      operation: 'delete',
      payload: {'id': fieldId},
      updatedAt: now,
    );
    for (final id in cropIds) {
      await _enqueueSyncJob(
        entityType: 'field_crops',
        entityId: id,
        operation: 'delete',
        payload: {'id': id, 'field_id': fieldId},
        updatedAt: now,
      );
    }
    for (final id in irrigationIds) {
      await _enqueueSyncJob(
        entityType: 'irrigation_plans',
        entityId: id,
        operation: 'delete',
        payload: {'id': id, 'field_id': fieldId},
        updatedAt: now,
      );
    }
    for (final id in calendarIds) {
      await _enqueueSyncJob(
        entityType: 'calendar_events',
        entityId: id,
        operation: 'delete',
        payload: {
          'id': id,
          'field_id': fieldId,
          'deleted_at': now.toIso8601String()
        },
        updatedAt: now,
      );
    }
    for (final id in suitabilityIds) {
      await _enqueueSyncJob(
        entityType: 'suitability_reports',
        entityId: id,
        operation: 'delete',
        payload: {'id': id, 'field_id': fieldId},
        updatedAt: now,
      );
    }
    for (final id in soilTestIds) {
      await _enqueueSyncJob(
        entityType: 'soil_tests',
        entityId: id,
        operation: 'delete',
        payload: {'id': id, 'field_id': fieldId},
        updatedAt: now,
      );
    }

    // Crop protocol state'lerini de temizle — her ekin için ayrı kayıt.
    for (final crop in cropsToClear) {
      await CropProtocolService.clearStateFor(
        fieldId: fieldId,
        cropId: crop.id,
        cropName: crop.name,
      );
    }

    // Tarlaya bağlı tüm Hive kayıtlarını da temizle — uygulamanın hiçbir
    // köşesinde silinmiş tarlaya ait artık veri kalmasın.
    await _purgeFieldFromHiveBoxes(fieldId);

    await _mirrorActiveFieldsToHive();
  }

  /// Silinen tarlanın Hive box'lardaki tüm izlerini siler.
  /// - cost_ledger : 'field_id' eşleşen tüm maliyet kayıtları
  Future<void> _purgeFieldFromHiveBoxes(String fieldId) async {
    Future<void> purge(String boxName, String key) async {
      if (!Hive.isBoxOpen(boxName)) return;
      final box = Hive.box(boxName);
      final keysToDelete = <dynamic>[];
      for (final k in box.keys) {
        final raw = box.get(k);
        if (raw is Map && raw[key] == fieldId) {
          keysToDelete.add(k);
        }
      }
      if (keysToDelete.isNotEmpty) {
        await box.deleteAll(keysToDelete);
      }
    }

    await purge('cost_ledger', 'field_id');
  }

  Future<List<Map<String, dynamic>>> loadFieldCrops(String fieldId) async {
    final crops = await (_db.select(_db.fieldCrops)
          ..where((tbl) => tbl.fieldId.equals(fieldId) & tbl.deletedAt.isNull())
          ..orderBy([(tbl) => OrderingTerm.asc(tbl.createdAt)]))
        .get();
    return crops.map(_cropToMap).toList();
  }

  /// Tarladaki ürün/zon kayıtlarını canlı dinler — soft-delete'siz, ekim
  /// tarihine göre eski → yeni. Canlı tavsiye motoru ürün düzenlemesinde
  /// (su aralığı, ekim tarihi, polygon) anında yenilensin diye kullanır.
  Stream<List<Map<String, dynamic>>> watchFieldCrops(String fieldId) {
    final query = _db.select(_db.fieldCrops)
      ..where((tbl) => tbl.fieldId.equals(fieldId) & tbl.deletedAt.isNull())
      ..orderBy([(tbl) => OrderingTerm.asc(tbl.createdAt)]);
    return query.watch().map((rows) => rows.map(_cropToMap).toList());
  }

  /// Akıllı Sulama Programı: backend'den gelen 7 günlük planı yerel Drift'e
  /// yazar ve outbox'a sync job ekler. Aynı tarlanın eski (silinmemiş)
  /// kayıtları tombstone ile soft-delete edilir.
  Future<void> saveSmartIrrigationSchedule({
    required String fieldId,
    String? cropId,
    required List<Map<String, dynamic>> dailyPlan,
  }) async {
    final now = DateTime.now().toUtc();

    // Eski planları tombstone et + her birine delete sync job
    final existing = await (_db.select(_db.irrigationPlans)
          ..where(
              (tbl) => tbl.fieldId.equals(fieldId) & tbl.deletedAt.isNull()))
        .get();
    for (final old in existing) {
      await (_db.update(_db.irrigationPlans)
            ..where((tbl) => tbl.id.equals(old.id)))
          .write(IrrigationPlansCompanion(
        updatedAt: Value(now),
        deletedAt: Value(now),
      ));
      await _enqueueSyncJob(
        entityType: 'irrigation_plans',
        entityId: old.id,
        operation: 'delete',
        payload: {'id': old.id},
        updatedAt: now,
      );
    }

    // Yeni günlük kayıtları ekle
    for (final day in dailyPlan) {
      final id = _newId('irrigation');
      final scheduled = day['date'] is DateTime
          ? day['date'] as DateTime
          : DateTime.tryParse(day['date'].toString()) ?? now;
      final shouldIrrigate = day['should_irrigate'] as bool? ?? false;
      final reason = (day['reason'] ?? day['title'] ?? '').toString();
      final recommendation = day['recommendation']?.toString();

      await _db.into(_db.irrigationPlans).insert(
            IrrigationPlansCompanion.insert(
              id: id,
              fieldId: fieldId,
              cropId: Value(cropId),
              scheduledDate: scheduled.toUtc(),
              shouldIrrigate: Value(shouldIrrigate),
              reason: reason,
              recommendation: Value(recommendation),
              createdAt: now,
              updatedAt: now,
            ),
          );

      await _enqueueSyncJob(
        entityType: 'irrigation_plans',
        entityId: id,
        operation: 'upsert',
        payload: {
          'id': id,
          'field_id': fieldId,
          'crop_id': cropId,
          'scheduled_date': scheduled.toUtc().toIso8601String(),
          'should_irrigate': shouldIrrigate,
          'reason': reason,
          'recommendation': recommendation,
          'source': 'smart_schedule',
        },
        updatedAt: now,
      );
    }
  }

  /// Belirli bir tarlanın sulama planlarını yükler (tarihe göre sıralı).
  Future<List<Map<String, dynamic>>> loadFieldIrrigationPlans(
      String fieldId) async {
    final plans = await (_db.select(_db.irrigationPlans)
          ..where((tbl) => tbl.fieldId.equals(fieldId) & tbl.deletedAt.isNull())
          ..orderBy([(tbl) => OrderingTerm.asc(tbl.scheduledDate)]))
        .get();
    return plans
        .map((p) => <String, dynamic>{
              'id': p.id,
              'field_id': p.fieldId,
              'crop_id': p.cropId,
              'scheduled_date': p.scheduledDate,
              'should_irrigate': p.shouldIrrigate,
              'reason': p.reason,
              'recommendation': p.recommendation,
            })
        .toList();
  }

  Future<void> replaceFieldCrops({
    required String fieldId,
    required List<Map<String, dynamic>> crops,
    bool enqueueSync = true,
    bool mirrorLegacy = true,
  }) async {
    final now = DateTime.now().toUtc();

    await (_db.update(_db.fieldCrops)
          ..where(
              (tbl) => tbl.fieldId.equals(fieldId) & tbl.deletedAt.isNull()))
        .write(
      FieldCropsCompanion(
        updatedAt: Value(now),
        deletedAt: Value(now),
      ),
    );
    await (_db.update(_db.irrigationPlans)
          ..where(
              (tbl) => tbl.fieldId.equals(fieldId) & tbl.deletedAt.isNull()))
        .write(
      IrrigationPlansCompanion(
        updatedAt: Value(now),
        deletedAt: Value(now),
      ),
    );

    for (final crop in crops) {
      final cropId = (crop['id']?.toString().trim().isNotEmpty ?? false)
          ? crop['id'].toString()
          : _newId('crop');
      final plantedDate = crop['planted_date']?.toString();
      final harvestDays = _asInt(crop['harvest_days']) ?? 90;
      final waterIntervalDays = _asInt(crop['water_interval_days']) ?? 7;

      await _db.into(_db.fieldCrops).insertOnConflictUpdate(
            FieldCropsCompanion(
              id: Value(cropId),
              fieldId: Value(fieldId),
              name: Value((crop['name'] ?? 'Bitki').toString()),
              zoneStart: Value(_asDouble(crop['zone_start']) ?? 0.0),
              zoneEnd: Value(_asDouble(crop['zone_end']) ?? 1.0),
              rowSpacingCm: Value(_asDouble(crop['row_spacing_cm']) ?? 50.0),
              plantSpacingCm:
                  Value(_asDouble(crop['plant_spacing_cm']) ?? 40.0),
              colorValue: Value(_asInt(crop['color_value'])),
              plantedDate: Value(plantedDate),
              harvestDays: Value(harvestDays),
              waterIntervalDays: Value(waterIntervalDays),
              zonePolygonJson: Value(crop['zone_polygon_json']?.toString()),
              facingDirection: Value(crop['facing_direction']?.toString()),
              createdAt: Value(_parseTimestamp(crop['created_at']) ?? now),
              updatedAt: Value(now),
              deletedAt: const Value(null),
            ),
          );

      if (enqueueSync) {
        await _enqueueSyncJob(
          entityType: 'field_crops',
          entityId: cropId,
          operation: 'upsert',
          payload: {
            ...Map<String, dynamic>.from(crop),
            'id': cropId,
            'field_id': fieldId,
          },
          updatedAt: now,
        );
      }
    }

    await _regenerateIrrigationPlans(fieldId: fieldId, referenceTime: now);
    await _touchFieldUpdatedAt(fieldId, now);
    if (mirrorLegacy) {
      await _mirrorActiveFieldsToHive();
    }
  }

  Future<List<Map<String, dynamic>>> loadCalendarEntries() async {
    final fields = await _activeFieldsQuery().get();
    final customEvents = await (_db.select(_db.calendarEvents)
          ..where((tbl) => tbl.deletedAt.isNull())
          ..orderBy([(tbl) => OrderingTerm.asc(tbl.eventDate)]))
        .get();
    final irrigationPlans = await (_db.select(_db.irrigationPlans)
          ..where(
              (tbl) => tbl.deletedAt.isNull() & tbl.shouldIrrigate.equals(true))
          ..orderBy([(tbl) => OrderingTerm.asc(tbl.scheduledDate)]))
        .get();

    final entries = <Map<String, dynamic>>[];
    final fieldNames = <String, String>{};

    for (final field in fields) {
      fieldNames[field.id] = field.name;
      final regDate = _parseLegacyDate(field.date);
      if (regDate != null) {
        entries.add({
          'id': 'registration_${field.id}',
          'title': '${field.name} — Tarla Kaydı',
          'type': 'registration',
          'date': regDate,
          'field_id': field.id,
          'crop_id': null,
        });
      }

      final crops = await (_db.select(_db.fieldCrops)
            ..where(
                (tbl) => tbl.fieldId.equals(field.id) & tbl.deletedAt.isNull()))
          .get();
      for (final crop in crops) {
        final plantedDate = _parseLegacyDate(crop.plantedDate);
        if (plantedDate == null) continue;
        entries.add({
          'id': 'planting_${crop.id}',
          'title': '${crop.name} — ${field.name} Ekimi',
          'type': 'planting',
          'date': plantedDate,
          'field_id': field.id,
          'crop_id': crop.id,
        });
        entries.add({
          'id': 'harvest_${crop.id}',
          'title': '${crop.name} — ${field.name} Hasat',
          'type': 'harvest',
          'date': plantedDate.add(Duration(days: crop.harvestDays ?? 90)),
          'field_id': field.id,
          'crop_id': crop.id,
        });
      }
    }

    for (final plan in irrigationPlans) {
      final fieldName = fieldNames[plan.fieldId];
      if (fieldName == null) {
        continue; // skip orphaned plans (field hard-deleted)
      }
      entries.add({
        'id': plan.id,
        'title': '$fieldName — Sulama',
        'type': 'watering',
        'date': plan.scheduledDate.toLocal(),
        'field_id': plan.fieldId,
        'crop_id': plan.cropId,
      });
    }

    for (final event in customEvents) {
      entries.add({
        'id': event.id,
        'title': event.title,
        'type': event.eventType,
        'date': event.eventDate.toLocal(),
        'field_id': event.fieldId,
        'crop_id': event.cropId,
      });
    }

    entries.sort(
        (a, b) => (a['date'] as DateTime).compareTo(b['date'] as DateTime));
    return entries;
  }

  Future<void> addCalendarEvent({
    String? fieldId,
    String? cropId,
    required String title,
    required String eventType,
    required DateTime eventDate,
    Map<String, dynamic>? metadata,
    double? quantity,
    String? unit,
    double? recommendedQuantity,
    String source = 'manual',
    // v8 — aktivite kapsamı + plant scope + alt-tip + foto + not.
    // Hepsi opsiyonel; çağıranların eski imzası geriye dönük çalışır.
    String? targetScope,
    String? plantInstanceId,
    String? subtype,
    String? photoPath,
    String? noteText,
  }) async {
    final now = DateTime.now().toUtc();
    final id = _newId('event');
    final metaJson = metadata == null ? null : jsonEncode(metadata);
    await _db.into(_db.calendarEvents).insert(
          CalendarEventsCompanion.insert(
            id: id,
            title: title,
            eventType: eventType,
            eventDate: eventDate.toUtc(),
            createdAt: now,
            updatedAt: now,
            fieldId: Value(fieldId),
            cropId: Value(cropId),
            source: Value(source),
            metadataJson: Value(metaJson),
            quantity: Value(quantity),
            unit: Value(unit),
            recommendedQuantity: Value(recommendedQuantity),
            targetScope: Value(targetScope),
            plantInstanceId: Value(plantInstanceId),
            subtype: Value(subtype),
            photoPath: Value(photoPath),
            noteText: Value(noteText),
          ),
        );

    await _enqueueSyncJob(
      entityType: 'calendar_events',
      entityId: id,
      operation: 'upsert',
      payload: {
        'id': id,
        'field_id': fieldId,
        'crop_id': cropId,
        'title': title,
        'event_type': eventType,
        'event_date': eventDate.toUtc().toIso8601String(),
        'source': source,
        'metadata': metadata,
        'quantity': quantity,
        'unit': unit,
        'recommended_quantity': recommendedQuantity,
        'target_scope': targetScope,
        'plant_instance_id': plantInstanceId,
        'subtype': subtype,
        'photo_path': photoPath,
        'note_text': noteText,
      },
      updatedAt: now,
    );
  }

  /// Çiftçi dostu aktivite kaydı. Tek çağrıda Calendar event + sync outbox.
  /// [type] için [ActivityType] sabitlerini kullan.
  ///
  /// [recommendedQuantity]: direktif motorunun aynı anda önerdiği miktar
  /// (ör. `TaskDirectiveService` "22 dk sula" diyorsa 22). `GrowthEngine`
  /// uygulanan/önerilen oranını bu kolondan okuyarak su açığı + azot stresini
  /// hesaplar. Null ise çiftçinin manuel-keyfî kaydı.
  Future<void> logActivity({
    required String fieldId,
    required String type,
    String? cropId,
    String? note,
    double? quantity,
    String? quantityUnit,
    double? recommendedQuantity,
    Map<String, dynamic>? metadata,
    DateTime? at,
    // v8 — aktivite kapsamı + plant scope + alt-tip + foto.
    // `scope` null geçilirse cropId/plantInstanceId varlığına göre türetilir.
    ActivityScope? scope,
    String? plantInstanceId,
    String? subtype,
    String? photoPath,
  }) async {
    final field = await (_db.select(_db.fields)
          ..where((tbl) => tbl.id.equals(fieldId))
          ..limit(1))
        .getSingleOrNull();
    final fieldName = field?.name ?? 'Tarla';
    final title = _composeActivityTitle(fieldName, type);
    final meta = <String, dynamic>{...?metadata};
    final trimmedNote = note?.trim();
    if (trimmedNote != null && trimmedNote.isNotEmpty) {
      meta['note'] = trimmedNote;
    }
    if (quantity != null) meta['quantity'] = quantity;
    if (quantityUnit != null) meta['quantity_unit'] = quantityUnit;
    if (recommendedQuantity != null) {
      meta['recommended_quantity'] = recommendedQuantity;
    }
    // Scope geçilmediyse parametrelerden makul varsayılan türet.
    final effectiveScope = scope ??
        (plantInstanceId != null
            ? ActivityScope.plant
            : (cropId != null ? ActivityScope.zone : ActivityScope.field));
    await addCalendarEvent(
      fieldId: fieldId,
      cropId: cropId,
      title: title,
      eventType: type,
      eventDate: at ?? DateTime.now(),
      metadata: meta.isEmpty ? null : meta,
      quantity: quantity,
      unit: quantityUnit,
      recommendedQuantity: recommendedQuantity,
      targetScope: effectiveScope.name,
      plantInstanceId: plantInstanceId,
      subtype: subtype,
      photoPath: photoPath,
      noteText:
          (trimmedNote != null && trimmedNote.isNotEmpty) ? trimmedNote : null,
    );

    // Sulama log'u → bekleyen sulama planını "tamamlandı" olarak işaretle.
    // Yöntem: 3 gün içindeki bir sonraki should_irrigate=true planı bul,
    // shouldIrrigate=false yap ve sebebi güncelle. Plan tarihi olduğu gibi
    // kalır (geçmiş kayıt). Bu sayede _DirectiveCard "sulama gerekiyor"
    // direktifini düşürür ve sezon özeti hesabı doğru çalışır.
    if (type == ActivityType.watering) {
      await _consumeNextIrrigationPlan(fieldId: fieldId, cropId: cropId);
    }

    // Auto-seed takvim programı (sulama/gübreleme/gözlem/ilaçlama) — eşleşen en yakın
    // planlı kaydı soft-delete ederek "tamamlandı" olarak işaretle. Böylece
    // takvim temizlenir, TaskDirectiveService "yapılmadı" senaryosu üretmez.
    if (type == ActivityType.watering ||
        type == ActivityType.fertilizing ||
        type == ActivityType.scouting ||
        type == ActivityType.spraying) {
      await _consumeNextAutoSeedEvent(
        fieldId: fieldId,
        cropId: cropId,
        type: type,
        loggedAt: at ?? DateTime.now(),
      );
    }
  }

  /// Tarla + bitki + tip için en yakın auto_seed CalendarEvent'i soft-delete
  /// eder. "En yakın" = bugüne ±10 gün penceresinde tarih farkı en az olan.
  /// Daha uzak planlar çiftçinin başka bir uygulaması kabul edilip
  /// dokunulmaz — böylece sezon sonundaki gelecek planlar yanlışlıkla
  /// tüketilmez.
  Future<void> _consumeNextAutoSeedEvent({
    required String fieldId,
    required String? cropId,
    required String type,
    required DateTime loggedAt,
  }) async {
    final logUtc = loggedAt.toUtc();
    final windowStart = logUtc.subtract(const Duration(days: 10));
    final windowEnd = logUtc.add(const Duration(days: 10));

    final query = _db.select(_db.calendarEvents)
      ..where((tbl) =>
          tbl.fieldId.equals(fieldId) &
          tbl.eventType.equals(type) &
          tbl.source.equals('auto_seed') &
          tbl.deletedAt.isNull() &
          tbl.eventDate.isBiggerOrEqualValue(windowStart) &
          tbl.eventDate.isSmallerOrEqualValue(windowEnd));
    if (cropId != null) {
      query.where((tbl) => tbl.cropId.equals(cropId));
    }
    final candidates = await query.get();
    if (candidates.isEmpty) return;

    CalendarEvent best = candidates.first;
    int bestDistance = _absDays(best.eventDate, logUtc);
    for (final c in candidates.skip(1)) {
      final d = _absDays(c.eventDate, logUtc);
      if (d < bestDistance) {
        best = c;
        bestDistance = d;
      }
    }

    final now = DateTime.now().toUtc();
    await (_db.update(_db.calendarEvents)
          ..where((tbl) => tbl.id.equals(best.id)))
        .write(CalendarEventsCompanion(
      deletedAt: Value(now),
      updatedAt: Value(now),
    ));
  }

  static int _absDays(DateTime a, DateTime b) {
    final diff = a.difference(b).inDays;
    return diff < 0 ? -diff : diff;
  }

  /// Tarlada aynı (veya eş) isimde aktif bir `FieldCrop` varsa döner.
  /// İsim karşılaştırması case-insensitive + trim.
  Future<FieldCrop?> findActiveCropByName({
    required String fieldId,
    required String name,
  }) async {
    final target = name.trim().toLowerCase();
    if (target.isEmpty) return null;
    final rows = await (_db.select(_db.fieldCrops)
          ..where(
              (tbl) => tbl.fieldId.equals(fieldId) & tbl.deletedAt.isNull()))
        .get();
    for (final c in rows) {
      if (c.name.trim().toLowerCase() == target) return c;
    }
    return null;
  }

  /// Mevcut bitkiyi "yeniden ekim" ile günceller: plantedDate + hasat süresi +
  /// sulama aralığı + spacing + zone (varsa). Yeni satır oluşturmaz; aynı
  /// cropId'yi koruyarak büyüme geçmişinin sürekliliğini sağlar. Eski
  /// auto_seed takvim kayıtları çağıran servis tarafından temizlenmelidir.
  Future<void> updateCropReplanting({
    required String cropId,
    required String plantedDate,
    required int harvestDays,
    required int waterIntervalDays,
    double? rowSpacingCm,
    double? plantSpacingCm,
    int? colorValue,
    String? zonePolygonJson,
    bool replaceZone = false,
    String? facingDirection,
  }) async {
    final now = DateTime.now().toUtc();
    final existing = await (_db.select(_db.fieldCrops)
          ..where((tbl) => tbl.id.equals(cropId)))
        .getSingleOrNull();
    if (existing == null) return;

    String? zoneJson = existing.zonePolygonJson;
    if (replaceZone) {
      zoneJson = zonePolygonJson;
    } else if (zonePolygonJson != null && zonePolygonJson.isNotEmpty) {
      zoneJson = _mergeZonePolygons(existing.zonePolygonJson, zonePolygonJson);
    }

    await (_db.update(_db.fieldCrops)..where((tbl) => tbl.id.equals(cropId)))
        .write(FieldCropsCompanion(
      plantedDate: Value(plantedDate),
      harvestDays: Value(harvestDays),
      waterIntervalDays: Value(waterIntervalDays),
      rowSpacingCm:
          rowSpacingCm == null ? const Value.absent() : Value(rowSpacingCm),
      plantSpacingCm:
          plantSpacingCm == null ? const Value.absent() : Value(plantSpacingCm),
      colorValue: colorValue == null ? const Value.absent() : Value(colorValue),
      zonePolygonJson: Value(zoneJson),
      facingDirection: facingDirection == null
          ? const Value.absent()
          : Value(facingDirection),
      updatedAt: Value(now),
    ));

    // Eski büyüme durumunu (GrowthEngine sonucu) sıfırla — yeniden ekimde
    // GDD kümülasyonu baştan başlamalı. GrowthEngine.recompute() tekrar
    // çağrıldığında uyumlu satırı üretir, ama önce mevcut kaydı silmek
    // gerek; aksi halde `insertOnConflictUpdate` eski alanları koruyabilir.
    await (_db.delete(_db.cropGrowthStates)
          ..where((tbl) => tbl.cropId.equals(cropId)))
        .go();

    await _enqueueSyncJob(
      entityType: 'field_crops',
      entityId: cropId,
      operation: 'upsert',
      payload: {
        'id': cropId,
        'field_id': existing.fieldId,
        'name': existing.name,
        'zone_start': existing.zoneStart,
        'zone_end': existing.zoneEnd,
        'row_spacing_cm': rowSpacingCm ?? existing.rowSpacingCm,
        'plant_spacing_cm': plantSpacingCm ?? existing.plantSpacingCm,
        'color_value': colorValue ?? existing.colorValue,
        'planted_date': plantedDate,
        'harvest_days': harvestDays,
        'water_interval_days': waterIntervalDays,
        'zone_polygon_json': zoneJson,
        'facing_direction': facingDirection ?? existing.facingDirection,
        'replant': true,
      },
      updatedAt: now,
    );

    await _regenerateIrrigationPlans(
        fieldId: existing.fieldId, referenceTime: now);
    await _mirrorActiveFieldsToHive();
  }

  /// Ekim kurulumundaki aralık/sulama ayarlarını yeniden ekim gibi
  /// davranmadan günceller. Kullanıcı toprak türü veya sulama yöntemini
  /// düzeltirken ekim tarihi ve büyüme geçmişi korunur.
  Future<void> updateCropSetup({
    required String cropId,
    int? waterIntervalDays,
    double? rowSpacingCm,
    double? plantSpacingCm,
  }) async {
    final now = DateTime.now().toUtc();
    final existing = await (_db.select(_db.fieldCrops)
          ..where((tbl) => tbl.id.equals(cropId)))
        .getSingleOrNull();
    if (existing == null) return;

    await (_db.update(_db.fieldCrops)..where((tbl) => tbl.id.equals(cropId)))
        .write(FieldCropsCompanion(
      waterIntervalDays: waterIntervalDays == null
          ? const Value.absent()
          : Value(waterIntervalDays),
      rowSpacingCm:
          rowSpacingCm == null ? const Value.absent() : Value(rowSpacingCm),
      plantSpacingCm:
          plantSpacingCm == null ? const Value.absent() : Value(plantSpacingCm),
      updatedAt: Value(now),
    ));

    await _enqueueSyncJob(
      entityType: 'field_crops',
      entityId: cropId,
      operation: 'upsert',
      payload: {
        'id': cropId,
        'field_id': existing.fieldId,
        'name': existing.name,
        'zone_start': existing.zoneStart,
        'zone_end': existing.zoneEnd,
        'row_spacing_cm': rowSpacingCm ?? existing.rowSpacingCm,
        'plant_spacing_cm': plantSpacingCm ?? existing.plantSpacingCm,
        'color_value': existing.colorValue,
        'planted_date': existing.plantedDate,
        'harvest_days': existing.harvestDays,
        'water_interval_days': waterIntervalDays ?? existing.waterIntervalDays,
        'zone_polygon_json': existing.zonePolygonJson,
        'facing_direction': existing.facingDirection,
      },
      updatedAt: now,
    );

    await _regenerateIrrigationPlans(
        fieldId: existing.fieldId, referenceTime: now);
    await _touchFieldUpdatedAt(existing.fieldId, now);
    await _mirrorActiveFieldsToHive();
  }

  /// Bir bitkinin baktığı yönü günceller. Sadece `facing_direction` kolonunu
  /// değiştirir; takvim/sulama planları yeniden üretilmez.
  Future<void> updateCropFacingDirection({
    required String cropId,
    String? facingDirection,
  }) async {
    final now = DateTime.now().toUtc();
    final existing = await (_db.select(_db.fieldCrops)
          ..where((tbl) => tbl.id.equals(cropId)))
        .getSingleOrNull();
    if (existing == null) return;

    await (_db.update(_db.fieldCrops)..where((tbl) => tbl.id.equals(cropId)))
        .write(FieldCropsCompanion(
      facingDirection: Value(facingDirection),
      updatedAt: Value(now),
    ));

    await _enqueueSyncJob(
      entityType: 'field_crops',
      entityId: cropId,
      operation: 'upsert',
      payload: {
        'id': cropId,
        'field_id': existing.fieldId,
        'name': existing.name,
        'zone_start': existing.zoneStart,
        'zone_end': existing.zoneEnd,
        'row_spacing_cm': existing.rowSpacingCm,
        'plant_spacing_cm': existing.plantSpacingCm,
        'color_value': existing.colorValue,
        'planted_date': existing.plantedDate,
        'harvest_days': existing.harvestDays,
        'water_interval_days': existing.waterIntervalDays,
        'zone_polygon_json': existing.zonePolygonJson,
        'facing_direction': facingDirection,
      },
      updatedAt: now,
    );
    await _touchFieldUpdatedAt(existing.fieldId, now);
    await _mirrorActiveFieldsToHive();
  }

  /// İki bölge poligonunu birleştirir — basit yaklaşım: noktaları arka arkaya
  /// ekler. Aynı bölgeye tekrar ekim senaryosunda kullanıcı genelde aynı
  /// poligonu tekrar çizdiği için `replaceZone=true` tercih edilmeli.
  String? _mergeZonePolygons(String? existing, String newJson) {
    if (existing == null || existing.isEmpty) return newJson;
    try {
      final a = jsonDecode(existing);
      final b = jsonDecode(newJson);
      if (a is List && b is List) {
        return jsonEncode([...a, ...b]);
      }
    } catch (_) {}
    return newJson;
  }

  Future<void> _consumeNextIrrigationPlan({
    required String fieldId,
    String? cropId,
  }) async {
    final now = DateTime.now().toUtc();
    final windowEnd = now.add(const Duration(days: 3));
    final query = _db.select(_db.irrigationPlans)
      ..where((tbl) =>
          tbl.fieldId.equals(fieldId) &
          tbl.deletedAt.isNull() &
          tbl.shouldIrrigate.equals(true) &
          tbl.scheduledDate.isSmallerOrEqualValue(windowEnd))
      ..orderBy([(tbl) => OrderingTerm.asc(tbl.scheduledDate)])
      ..limit(1);
    final next = await query.getSingleOrNull();
    if (next == null) return;

    // Eğer cropId verildiyse sadece o ekinin planını tüket
    if (cropId != null && next.cropId != null && next.cropId != cropId) {
      return;
    }

    await (_db.update(_db.irrigationPlans)
          ..where((tbl) => tbl.id.equals(next.id)))
        .write(IrrigationPlansCompanion(
      shouldIrrigate: const Value(false),
      reason: Value('Çiftçi suladı (loglandı ${_formatDate(now.toLocal())}).'),
      updatedAt: Value(now),
    ));

    await _enqueueSyncJob(
      entityType: 'irrigation_plans',
      entityId: next.id,
      operation: 'upsert',
      payload: {
        'id': next.id,
        'should_irrigate': false,
        'reason': 'Çiftçi suladı',
        'consumed_at': now.toIso8601String(),
      },
      updatedAt: now,
    );
  }

  /// Tarlaya ait sezon (ekim sonrası) aktivite özeti.
  ///
  /// Dönen alanlar:
  /// - watering_count, watering_total_liters, watering_last_at
  /// - fertilizing_count, fertilizing_total_kg, fertilizing_last_name, fertilizing_last_at
  /// - spraying_count, spraying_last_name, spraying_last_active, spraying_last_at
  /// - harvest_count, harvest_total_kg, harvest_last_at
  Future<Map<String, dynamic>> loadSeasonSummary({
    required String fieldId,
    DateTime? since,
  }) async {
    final query = _db.select(_db.calendarEvents)
      ..where((tbl) => tbl.fieldId.equals(fieldId) & tbl.deletedAt.isNull());
    if (since != null) {
      query.where((tbl) => tbl.eventDate.isBiggerOrEqualValue(since.toUtc()));
    }
    final rows = await query.get();

    int wCount = 0, fCount = 0, sCount = 0, hCount = 0;
    double wLitersTotal = 0, fKgTotal = 0, hKgTotal = 0;
    DateTime? wLast, fLast, sLast, hLast;
    String? fLastName, sLastName, sLastActive;
    int? lastRecommendedWeeklyMm;

    for (final ev in rows) {
      Map<String, dynamic> meta = const {};
      final raw = ev.metadataJson;
      if (raw != null && raw.isNotEmpty) {
        try {
          final decoded = jsonDecode(raw);
          if (decoded is Map) meta = Map<String, dynamic>.from(decoded);
        } catch (_) {}
      }
      final date = ev.eventDate.toLocal();
      switch (ev.eventType) {
        case 'watering':
          wCount++;
          final liters = (meta['effective_water_liters'] as num?)?.toDouble() ??
              (meta['water_liters'] as num?)?.toDouble();
          if (liters != null) wLitersTotal += liters;
          if (wLast == null || date.isAfter(wLast)) {
            wLast = date;
            final rec = (meta['recommended_weekly_mm'] as num?)?.toInt();
            if (rec != null) lastRecommendedWeeklyMm = rec;
          }
          break;
        case 'fertilizing':
          fCount++;
          final kg = (meta['fertilizer_kg'] as num?)?.toDouble();
          if (kg != null) fKgTotal += kg;
          if (fLast == null || date.isAfter(fLast)) {
            fLast = date;
            fLastName = meta['fertilizer_name'] as String?;
          }
          break;
        case 'spraying':
          sCount++;
          if (sLast == null || date.isAfter(sLast)) {
            sLast = date;
            sLastName = meta['pesticide_name'] as String?;
            sLastActive = meta['active_ingredient'] as String?;
          }
          break;
        case 'harvest':
          hCount++;
          final kg = (meta['harvest_kg'] as num?)?.toDouble();
          if (kg != null) hKgTotal += kg;
          if (hLast == null || date.isAfter(hLast)) hLast = date;
          break;
      }
    }

    return {
      'watering_count': wCount,
      'watering_total_liters': wLitersTotal,
      'watering_last_at': wLast,
      'watering_last_recommended_weekly_mm': lastRecommendedWeeklyMm,
      'fertilizing_count': fCount,
      'fertilizing_total_kg': fKgTotal,
      'fertilizing_last_name': fLastName,
      'fertilizing_last_at': fLast,
      'spraying_count': sCount,
      'spraying_last_name': sLastName,
      'spraying_last_active': sLastActive,
      'spraying_last_at': sLast,
      'harvest_count': hCount,
      'harvest_total_kg': hKgTotal,
      'harvest_last_at': hLast,
    };
  }

  String _composeActivityTitle(String fieldName, String type) {
    switch (type) {
      case 'watering':
        return '$fieldName — Sulama';
      case 'fertilizing':
        return '$fieldName — Gübreleme';
      case 'spraying':
        return '$fieldName — İlaçlama';
      case 'scouting':
        return '$fieldName — Gözlem';
      case 'harvest':
        return '$fieldName — Hasat';
      case 'planting':
        return '$fieldName — Ekim';
      default:
        return '$fieldName — Aktivite';
    }
  }

  /// Takvim olaylarını tarla/tipe göre watch eder.
  /// UI StreamBuilder ile dinler; yeni `addCalendarEvent` anında stream'e düşer.
  Stream<List<Map<String, dynamic>>> watchActivityLog({
    String? fieldId,
    Set<String>? types,
    int limit = 500,
  }) {
    final query = _db.select(_db.calendarEvents)
      ..where((tbl) =>
          tbl.deletedAt.isNull() & tbl.source.equals('auto_seed').not());
    if (fieldId != null) {
      query.where((tbl) => tbl.fieldId.equals(fieldId));
    }
    query
      ..orderBy([(tbl) => OrderingTerm.desc(tbl.eventDate)])
      ..limit(limit);
    return query.watch().asyncMap((rows) async {
      final now = DateTime.now();
      final realRows = rows
          .where((row) => !row.eventDate.toLocal().isAfter(now))
          .toList(growable: false);
      final fields = await _activeFieldsQuery().get();
      final names = {for (final f in fields) f.id: f.name};
      final cropRows = await (_db.select(_db.fieldCrops)
            ..where((tbl) => tbl.deletedAt.isNull()))
          .get();
      final cropNames = {for (final c in cropRows) c.id: c.name};
      final filtered = types == null || types.isEmpty
          ? realRows
          : realRows.where((r) => types.contains(r.eventType)).toList();
      return filtered.map((ev) {
        Map<String, dynamic>? meta;
        final raw = ev.metadataJson;
        if (raw != null && raw.isNotEmpty) {
          try {
            final decoded = jsonDecode(raw);
            if (decoded is Map) meta = Map<String, dynamic>.from(decoded);
          } catch (_) {}
        }
        // Yeni kolonları (v4) kolay erişim için aç — fallback olarak
        // metadata JSON'u da destekle (eski kayıtlar için geriye uyumluluk).
        final qty = ev.quantity ?? (meta?['quantity'] as num?)?.toDouble();
        final unit = ev.unit ?? meta?['quantity_unit']?.toString();
        final recQty = ev.recommendedQuantity ??
            (meta?['recommended_quantity'] as num?)?.toDouble();
        return <String, dynamic>{
          'id': ev.id,
          'field_id': ev.fieldId,
          'field_name': ev.fieldId == null ? null : names[ev.fieldId],
          'crop_id': ev.cropId,
          'crop_name': ev.cropId == null ? null : cropNames[ev.cropId],
          'title': ev.title,
          'type': ev.eventType,
          'date': ev.eventDate.toLocal(),
          'source': ev.source,
          'subtype': ev.subtype,
          'note_text': ev.noteText,
          'photo_path': ev.photoPath,
          'quantity': qty,
          'unit': unit,
          'recommended_quantity': recQty,
          'metadata': meta,
        };
      }).toList();
    });
  }

  /// `AlertJournalService` dedup'ı için: belirli tarla + alertKey kombosunun
  /// son [within] içinde sistem uyarısı olarak yazılıp yazılmadığını tespit
  /// eder. alertKey, CalendarEvent.subtype kolonuna eşitlenir.
  Future<bool> hasRecentSystemAlert({
    required String fieldId,
    required String alertKey,
    Duration within = const Duration(hours: 24),
  }) async {
    final cutoff = DateTime.now().subtract(within);
    final rows = await (_db.select(_db.calendarEvents)
          ..where((tbl) =>
              tbl.fieldId.equals(fieldId) &
              tbl.eventType.equals(ActivityType.systemAlert) &
              tbl.subtype.equals(alertKey) &
              tbl.eventDate.isBiggerThanValue(cutoff) &
              tbl.deletedAt.isNull())
          ..limit(1))
        .get();
    return rows.isNotEmpty;
  }

  /// Takvimde auto_seed kaynaklı, tamamlanmamış (soft-delete'siz) planları
  /// döner. TaskDirectiveService "yapılmadı" senaryosu üretmek için tüketir.
  /// [fieldId] null ise tüm tarlaları kapsar.
  Stream<List<Map<String, dynamic>>> watchScheduledAutoSeedEvents({
    String? fieldId,
  }) {
    final query = _db.select(_db.calendarEvents)
      ..where((tbl) => tbl.deletedAt.isNull() & tbl.source.equals('auto_seed'));
    if (fieldId != null) {
      query.where((tbl) => tbl.fieldId.equals(fieldId));
    }
    query.orderBy([(tbl) => OrderingTerm.asc(tbl.eventDate)]);
    return query.watch().map((rows) {
      return rows.map((ev) {
        Map<String, dynamic>? meta;
        final raw = ev.metadataJson;
        if (raw != null && raw.isNotEmpty) {
          try {
            final decoded = jsonDecode(raw);
            if (decoded is Map) meta = Map<String, dynamic>.from(decoded);
          } catch (_) {}
        }
        return <String, dynamic>{
          'id': ev.id,
          'field_id': ev.fieldId,
          'crop_id': ev.cropId,
          'title': ev.title,
          'type': ev.eventType,
          'date': ev.eventDate.toLocal(),
          'source': ev.source,
          'quantity': ev.quantity,
          'unit': ev.unit,
          'recommended_quantity': ev.recommendedQuantity,
          'metadata': meta,
        };
      }).toList();
    });
  }

  /// Aktivite kaydını soft-delete yapar.
  Future<void> deleteActivity(String id) async {
    final now = DateTime.now().toUtc();
    await (_db.update(_db.calendarEvents)..where((tbl) => tbl.id.equals(id)))
        .write(CalendarEventsCompanion(
      deletedAt: Value(now),
      updatedAt: Value(now),
    ));
    await _enqueueSyncJob(
      entityType: 'calendar_events',
      entityId: id,
      operation: 'delete',
      payload: {'id': id, 'deleted_at': now.toIso8601String()},
      updatedAt: now,
    );
  }

  Future<void> saveSuitabilityReport({
    required String fieldId,
    required String cropName,
    required double score,
    required Map<String, dynamic> report,
  }) async {
    final now = DateTime.now().toUtc();
    final reportId = _newId('suitability');
    await _db.into(_db.suitabilityReports).insert(
          SuitabilityReportsCompanion.insert(
            id: reportId,
            fieldId: fieldId,
            cropName: cropName,
            score: Value(score),
            reportJson: jsonEncode(report),
            createdAt: now,
            updatedAt: now,
          ),
        );

    await _enqueueSyncJob(
      entityType: 'suitability_reports',
      entityId: reportId,
      operation: 'upsert',
      payload: {
        'id': reportId,
        'field_id': fieldId,
        'crop_name': cropName,
        'score': score,
        'report': report,
        'updated_at': now.toIso8601String(),
      },
      updatedAt: now,
    );
  }

  Future<Map<String, dynamic>?> loadLatestSuitabilityReport(
      String fieldId) async {
    final report = await (_db.select(_db.suitabilityReports)
          ..where((tbl) => tbl.fieldId.equals(fieldId) & tbl.deletedAt.isNull())
          ..orderBy([(tbl) => OrderingTerm.desc(tbl.updatedAt)])
          ..limit(1))
        .getSingleOrNull();
    if (report == null) return null;

    Map<String, dynamic> decodedReport = const {};
    try {
      final parsed = jsonDecode(report.reportJson);
      if (parsed is Map) {
        decodedReport = Map<String, dynamic>.from(parsed);
      }
    } catch (_) {}

    return {
      'id': report.id,
      'field_id': report.fieldId,
      'crop_name': report.cropName,
      'score': report.score ?? 0.0,
      'report': decodedReport,
      'created_at': report.createdAt,
      'updated_at': report.updatedAt,
    };
  }

  // ───────────────────────────────────────────────────────────────────────
  // TOPRAK ANALİZİ (laboratuvar sonuçları)
  // Kullanıcıya ait kayıt — farmerUid izolasyonu (CLAUDE.md §5.5). Çiftçi
  // tarlanın istediği kısmından aldığı örneği laboratuvarda analiz ettirip
  // sonuçları buraya girer; deterministik öneri SoilTestAdvisor'da üretilir.
  // ───────────────────────────────────────────────────────────────────────

  Future<String> saveSoilTest({
    required String fieldId,
    String? sampleLabel,
    String? labName,
    DateTime? sampledAt,
    double? ph,
    double? saltPct,
    double? ecDsM,
    double? limePct,
    double? organicMatterPct,
    double? phosphorusKgDa,
    double? potassiumKgDa,
    double? nitrogenPct,
    double? saturationPct,
    String? textureClass,
    double? sampleLat,
    double? sampleLng,
    String? notes,
  }) async {
    final now = DateTime.now().toUtc();
    final id = _newId('soiltest');
    await _db.into(_db.soilTests).insert(
          SoilTestsCompanion.insert(
            id: id,
            fieldId: fieldId,
            farmerUid: Value(currentUid),
            sampleLabel: Value(sampleLabel),
            labName: Value(labName),
            sampledAt: Value(sampledAt?.toUtc()),
            ph: Value(ph),
            saltPct: Value(saltPct),
            ecDsM: Value(ecDsM),
            limePct: Value(limePct),
            organicMatterPct: Value(organicMatterPct),
            phosphorusKgDa: Value(phosphorusKgDa),
            potassiumKgDa: Value(potassiumKgDa),
            nitrogenPct: Value(nitrogenPct),
            saturationPct: Value(saturationPct),
            textureClass: Value(textureClass),
            sampleLat: Value(sampleLat),
            sampleLng: Value(sampleLng),
            notes: Value(notes),
            createdAt: now,
            updatedAt: now,
          ),
        );

    await _enqueueSyncJob(
      entityType: 'soil_tests',
      entityId: id,
      operation: 'upsert',
      payload: {
        'id': id,
        'field_id': fieldId,
        'sample_label': sampleLabel,
        'lab_name': labName,
        'sampled_at': sampledAt?.toUtc().toIso8601String(),
        'ph': ph,
        'salt_pct': saltPct,
        'ec_ds_m': ecDsM,
        'lime_pct': limePct,
        'organic_matter_pct': organicMatterPct,
        'phosphorus_kg_da': phosphorusKgDa,
        'potassium_kg_da': potassiumKgDa,
        'nitrogen_pct': nitrogenPct,
        'saturation_pct': saturationPct,
        'texture_class': textureClass,
        'sample_lat': sampleLat,
        'sample_lng': sampleLng,
        'notes': notes,
        'updated_at': now.toIso8601String(),
      },
      updatedAt: now,
    );
    return id;
  }

  /// Tarlanın toprak analizlerini canlı dinler (yeni → eski).
  Stream<List<SoilTest>> watchSoilTests(String fieldId) {
    return (_db.select(_db.soilTests)
          ..where((tbl) => tbl.fieldId.equals(fieldId) & tbl.deletedAt.isNull())
          ..orderBy([(tbl) => OrderingTerm.desc(tbl.createdAt)]))
        .watch();
  }

  /// Tarlanın toprak analizlerini tek seferlik yükler (yeni → eski).
  Future<List<SoilTest>> loadSoilTests(String fieldId) {
    return (_db.select(_db.soilTests)
          ..where((tbl) => tbl.fieldId.equals(fieldId) & tbl.deletedAt.isNull())
          ..orderBy([(tbl) => OrderingTerm.desc(tbl.createdAt)]))
        .get();
  }

  /// Toprak analizi kaydını soft-delete yapar.
  Future<void> deleteSoilTest(String id) async {
    final now = DateTime.now().toUtc();
    await (_db.update(_db.soilTests)..where((tbl) => tbl.id.equals(id)))
        .write(SoilTestsCompanion(
      deletedAt: Value(now),
      updatedAt: Value(now),
    ));
    await _enqueueSyncJob(
      entityType: 'soil_tests',
      entityId: id,
      operation: 'delete',
      payload: {'id': id, 'deleted_at': now.toIso8601String()},
      updatedAt: now,
    );
  }

  Future<void> _regenerateIrrigationPlans({
    required String fieldId,
    required DateTime referenceTime,
  }) async {
    // Tarla koordinatlarını al (yağış tahminini çekmek için gerekli)
    final field = await (_db.select(_db.fields)
          ..where((tbl) => tbl.id.equals(fieldId)))
        .getSingleOrNull();
    final lat = field?.latitude;
    final lng = field?.longitude;

    // Yağış tahminini çekmeyi dene (7 günlük, günlük yağış olasılığı)
    // Offline durumda boş map kalır — tüm planlar varsayılan olarak sulama yapar
    final dailyPrecipProb = await _fetchDailyPrecipForecast(lat, lng);

    final crops = await (_db.select(_db.fieldCrops)
          ..where(
              (tbl) => tbl.fieldId.equals(fieldId) & tbl.deletedAt.isNull()))
        .get();
    final horizon = referenceTime.add(const Duration(days: 60));

    for (final crop in crops) {
      final plantedDate = _parseLegacyDate(crop.plantedDate) ?? DateTime.now();
      final waterInterval = crop.waterIntervalDays ?? 7;
      final harvestDate =
          plantedDate.add(Duration(days: crop.harvestDays ?? 90));
      var current = plantedDate;

      while (current.isBefore(harvestDate) && current.isBefore(horizon)) {
        if (!current.isBefore(
            referenceTime.toLocal().subtract(const Duration(days: 1)))) {
          // Sulama günü için yağış kontrolü
          final dateKey =
              '${current.year}-${current.month.toString().padLeft(2, '0')}-${current.day.toString().padLeft(2, '0')}';
          final precipProb = dailyPrecipProb[dateKey];
          final rainExpected = precipProb != null && precipProb >= 60;

          final shouldIrrigate = !rainExpected;
          final reason = rainExpected
              ? 'Yağış bekleniyor (%${precipProb.toStringAsFixed(0)} olasılık). Sulama önerilmez.'
              : 'Varsayılan sulama döngüsüne göre üretildi.';
          final recommendation = rainExpected
              ? '🌧️ ${crop.name} — yağış nedeniyle sulama ertelendi'
              : '${crop.name} için planlanan sulama';

          final irrigationId = _newId('irrigation');
          await _db.into(_db.irrigationPlans).insert(
                IrrigationPlansCompanion.insert(
                  id: irrigationId,
                  fieldId: fieldId,
                  scheduledDate: current.toUtc(),
                  shouldIrrigate: Value(shouldIrrigate),
                  reason: reason,
                  recommendation: Value(recommendation),
                  cropId: Value(crop.id),
                  createdAt: referenceTime,
                  updatedAt: referenceTime,
                ),
              );
          await _enqueueSyncJob(
            entityType: 'irrigation_plans',
            entityId: irrigationId,
            operation: 'upsert',
            payload: {
              'id': irrigationId,
              'field_id': fieldId,
              'crop_id': crop.id,
              'scheduled_date': current.toUtc().toIso8601String(),
              'should_irrigate': shouldIrrigate,
              'reason': reason,
            },
            updatedAt: referenceTime,
          );
        }
        current = current.add(Duration(days: waterInterval));
      }
    }
  }

  /// Open-Meteo'dan 7 günlük yağış olasılığını çeker.
  /// Dönen map: {'2026-04-08': 75.0, '2026-04-09': 20.0, ...}
  /// Offline durumda veya hata durumunda boş map döner (graceful fallback).
  Future<Map<String, double>> _fetchDailyPrecipForecast(
    double? lat,
    double? lng,
  ) async {
    if (lat == null || lng == null) return const {};

    try {
      final url = Uri.parse(
        'https://api.open-meteo.com/v1/forecast'
        '?latitude=$lat&longitude=$lng'
        '&daily=precipitation_probability_max'
        '&forecast_days=7&timezone=auto',
      );

      final response = await http.get(url).timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) return const {};

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final daily = body['daily'] as Map<String, dynamic>?;
      if (daily == null) return const {};

      final dates = (daily['time'] as List?)?.cast<String>() ?? [];
      final probs = (daily['precipitation_probability_max'] as List?)
              ?.map((e) => (e as num?)?.toDouble() ?? 0.0)
              .toList() ??
          [];

      final result = <String, double>{};
      for (int i = 0; i < dates.length && i < probs.length; i++) {
        result[dates[i]] = probs[i];
      }
      return result;
    } catch (_) {
      // Offline / timeout — graceful fallback: boş map döner,
      // tüm sulama planları varsayılan (shouldIrrigate=true) olarak kalır.
      return const {};
    }
  }

  Future<void> _enqueueSyncJob({
    required String entityType,
    required String entityId,
    required String operation,
    required Map<String, dynamic> payload,
    required DateTime updatedAt,
  }) async {
    await _db.into(_db.syncJobs).insert(
          SyncJobsCompanion.insert(
            entityType: entityType,
            entityId: entityId,
            operation: operation,
            payloadJson: jsonEncode(payload),
            updatedAt: updatedAt,
          ),
        );
  }

  Future<void> _mirrorActiveFieldsToHive() async {
    final data = await loadFieldMaps();
    await _legacyFieldsBox.clear();
    for (final item in data) {
      await _legacyFieldsBox.add(item);
    }
  }

  Future<Map<String, dynamic>> _buildLegacyFieldMap(Field row) async {
    final crops = await loadFieldCrops(row.id);
    return {
      'id': row.id,
      'name': row.name,
      'crop': row.crop,
      'date': row.date,
      'latitude': row.latitude,
      'longitude': row.longitude,
      'area_dekar': row.areaDekar,
      'area_sqm': row.areaSqm,
      'polygon': _decodeJsonList(row.polygonJson),
      'planted_crops': crops,
      'created_at': row.createdAt.toIso8601String(),
      'updated_at': row.updatedAt.toIso8601String(),
    };
  }

  Map<String, dynamic> _cropToMap(FieldCrop crop) {
    return {
      'id': crop.id,
      'name': crop.name,
      'zone_start': crop.zoneStart,
      'zone_end': crop.zoneEnd,
      'row_spacing_cm': crop.rowSpacingCm,
      'plant_spacing_cm': crop.plantSpacingCm,
      'color_value': crop.colorValue,
      'planted_date': crop.plantedDate,
      'harvest_days': crop.harvestDays ?? 90,
      'water_interval_days': crop.waterIntervalDays ?? 7,
      'zone_polygon_json': crop.zonePolygonJson,
      'facing_direction': crop.facingDirection,
      'created_at': crop.createdAt.toIso8601String(),
      'updated_at': crop.updatedAt.toIso8601String(),
    };
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TEK BİTKİ CRUD — İnteraktif bölge yerleştirme sistemi için
  // ═══════════════════════════════════════════════════════════════════════════

  /// Mevcut bitkilere dokunmadan tarlaya tek bir bitki ekler.
  /// [zonePolygonJson]: JSON dizesi [{"lat":...,"lng":...}, ...]
  /// [isSeedling]: çok yıllık ürün (portakal, çay) için: true = yeni
  /// fidan, false = olgun ağaç/bahçe, null = bilinmiyor / tek yıllık.
  /// CropStateService.modeFor() bu değeri okur.
  Future<String> addSingleCropToField({
    required String fieldId,
    required String name,
    int? colorValue,
    String? plantedDate,
    int harvestDays = 90,
    int waterIntervalDays = 7,
    double rowSpacingCm = 50.0,
    double plantSpacingCm = 40.0,
    String? zonePolygonJson,
    String? facingDirection,
    bool? isSeedling,
  }) async {
    final now = DateTime.now().toUtc();
    final cropId = _newId('crop');

    await _db.into(_db.fieldCrops).insert(
          FieldCropsCompanion.insert(
            id: cropId,
            fieldId: fieldId,
            name: name,
            zoneStart: 0.0,
            zoneEnd: 1.0,
            rowSpacingCm: rowSpacingCm,
            plantSpacingCm: plantSpacingCm,
            colorValue: Value(colorValue),
            plantedDate: Value(plantedDate),
            harvestDays: Value(harvestDays),
            waterIntervalDays: Value(waterIntervalDays),
            zonePolygonJson: Value(zonePolygonJson),
            facingDirection: Value(facingDirection),
            isSeedling: Value(isSeedling),
            createdAt: now,
            updatedAt: now,
          ),
        );

    await _enqueueSyncJob(
      entityType: 'field_crops',
      entityId: cropId,
      operation: 'upsert',
      payload: {
        'id': cropId,
        'field_id': fieldId,
        'name': name,
        'zone_start': 0.0,
        'zone_end': 1.0,
        'row_spacing_cm': rowSpacingCm,
        'plant_spacing_cm': plantSpacingCm,
        'color_value': colorValue,
        'planted_date': plantedDate,
        'harvest_days': harvestDays,
        'water_interval_days': waterIntervalDays,
        'zone_polygon_json': zonePolygonJson,
        'facing_direction': facingDirection,
        'is_seedling': isSeedling,
      },
      updatedAt: now,
    );

    await _regenerateIrrigationPlans(fieldId: fieldId, referenceTime: now);
    await _touchFieldUpdatedAt(fieldId, now);
    await _mirrorActiveFieldsToHive();
    return cropId;
  }

  /// Tek bir bitkiyi soft-delete eder.
  Future<void> deleteSingleCrop(String cropId) async {
    final now = DateTime.now().toUtc();

    // 1. Transaction oncesi: iliskili kayitlarin ID'lerini topla
    // (sync outbox icin; transaction ici enqueue = nested transaction kilidi)
    final crop = await (_db.select(_db.fieldCrops)
          ..where((tbl) => tbl.id.equals(cropId)))
        .getSingleOrNull();
    if (crop == null) return;

    final relatedPlans = await (_db.select(_db.irrigationPlans)
          ..where((tbl) => tbl.cropId.equals(cropId) & tbl.deletedAt.isNull()))
        .get();
    final relatedEvents = await (_db.select(_db.calendarEvents)
          ..where((tbl) => tbl.cropId.equals(cropId) & tbl.deletedAt.isNull()))
        .get();
    final relatedPlantInstances = await (_db.select(_db.fieldPlantInstances)
          ..where((tbl) => tbl.cropId.equals(cropId) & tbl.deletedAt.isNull()))
        .get();

    // 2. Atomik write transaction - yalnizca DB guncelleme/silme
    await _db.transaction(() async {
      await (_db.update(_db.fieldCrops)..where((tbl) => tbl.id.equals(cropId)))
          .write(FieldCropsCompanion(
        updatedAt: Value(now),
        deletedAt: Value(now),
      ));

      await (_db.update(_db.irrigationPlans)
            ..where(
                (tbl) => tbl.cropId.equals(cropId) & tbl.deletedAt.isNull()))
          .write(IrrigationPlansCompanion(
        updatedAt: Value(now),
        deletedAt: Value(now),
      ));

      await (_db.update(_db.calendarEvents)
            ..where(
                (tbl) => tbl.cropId.equals(cropId) & tbl.deletedAt.isNull()))
          .write(CalendarEventsCompanion(
        updatedAt: Value(now),
        deletedAt: Value(now),
      ));

      await (_db.delete(_db.cropGrowthStates)
            ..where((tbl) => tbl.cropId.equals(cropId)))
          .go();

      await (_db.update(_db.fieldPlantInstances)
            ..where(
                (tbl) => tbl.cropId.equals(cropId) & tbl.deletedAt.isNull()))
          .write(FieldPlantInstancesCompanion(
        updatedAt: Value(now),
        deletedAt: Value(now),
      ));
    });

    // 3. Transaction disari: sync outbox kayitlari (kilit riski yok)
    for (final plan in relatedPlans) {
      await _enqueueSyncJob(
        entityType: 'irrigation_plans',
        entityId: plan.id,
        operation: 'delete',
        payload: {'id': plan.id, 'crop_id': cropId},
        updatedAt: now,
      );
    }
    for (final event in relatedEvents) {
      await _enqueueSyncJob(
        entityType: 'calendar_events',
        entityId: event.id,
        operation: 'delete',
        payload: {'id': event.id, 'crop_id': cropId},
        updatedAt: now,
      );
    }
    for (final plant in relatedPlantInstances) {
      await _enqueueSyncJob(
        entityType: 'field_plant_instances',
        entityId: plant.id,
        operation: 'delete',
        payload: {'id': plant.id, 'crop_id': cropId},
        updatedAt: now,
      );
    }
    await _enqueueSyncJob(
      entityType: 'field_crops',
      entityId: cropId,
      operation: 'delete',
      payload: {'id': cropId, 'field_id': crop.fieldId},
      updatedAt: now,
    );

    await CropProtocolService.clearStateFor(
      fieldId: crop.fieldId,
      cropId: cropId,
      cropName: crop.name,
    );

    await _mirrorActiveFieldsToHive();
  }

  /// Bir bitkinin bölge poligonunu günceller.
  Future<void> updateCropZone({
    required String cropId,
    required String? zonePolygonJson,
  }) async {
    final now = DateTime.now().toUtc();
    await (_db.update(_db.fieldCrops)..where((tbl) => tbl.id.equals(cropId)))
        .write(FieldCropsCompanion(
      zonePolygonJson: Value(zonePolygonJson),
      updatedAt: Value(now),
    ));

    final crop = await (_db.select(_db.fieldCrops)
          ..where((tbl) => tbl.id.equals(cropId)))
        .getSingleOrNull();

    await _enqueueSyncJob(
      entityType: 'field_crops',
      entityId: cropId,
      operation: 'upsert',
      payload: {
        'id': cropId,
        if (crop != null) 'field_id': crop.fieldId,
        if (crop != null) 'name': crop.name,
        if (crop != null) 'zone_start': crop.zoneStart,
        if (crop != null) 'zone_end': crop.zoneEnd,
        if (crop != null) 'row_spacing_cm': crop.rowSpacingCm,
        if (crop != null) 'plant_spacing_cm': crop.plantSpacingCm,
        if (crop != null) 'color_value': crop.colorValue,
        if (crop != null) 'planted_date': crop.plantedDate,
        if (crop != null) 'harvest_days': crop.harvestDays,
        if (crop != null) 'water_interval_days': crop.waterIntervalDays,
        'zone_polygon_json': zonePolygonJson,
      },
      updatedAt: now,
    );

    await _mirrorActiveFieldsToHive();
  }

  SimpleSelectStatement<$FieldsTable, Field> _activeFieldsQuery() {
    final uid = currentUid;
    return _db.select(_db.fields)
      ..where((tbl) =>
          tbl.deletedAt.isNull() &
          (uid != null ? tbl.farmerUid.equals(uid) : tbl.farmerUid.isNull()))
      ..orderBy([(tbl) => OrderingTerm.asc(tbl.createdAt)]);
  }

  Future<void> _touchFieldUpdatedAt(String fieldId, DateTime now) async {
    await (_db.update(_db.fields)..where((tbl) => tbl.id.equals(fieldId)))
        .write(FieldsCompanion(updatedAt: Value(now)));
  }

  String _newId(String prefix) {
    final now = DateTime.now().microsecondsSinceEpoch;
    final rand = Random().nextInt(1 << 32).toRadixString(16);
    return '${prefix}_$now$rand';
  }

  DateTime? _parseTimestamp(Object? raw) {
    if (raw == null) return null;
    if (raw is DateTime) return raw.toUtc();
    if (raw is String && raw.isNotEmpty) {
      return DateTime.tryParse(raw)?.toUtc();
    }
    return null;
  }

  DateTime? _parseLegacyDate(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    final parts = raw.split('.');
    if (parts.length == 3) {
      final day = int.tryParse(parts[0]);
      final month = int.tryParse(parts[1]);
      final year = int.tryParse(parts[2]);
      if (day != null && month != null && year != null) {
        return DateTime(year, month, day);
      }
    }
    return DateTime.tryParse(raw);
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }

  double? _asDouble(Object? raw) {
    if (raw == null) return null;
    if (raw is num) return raw.toDouble();
    return double.tryParse(raw.toString());
  }

  int? _asInt(Object? raw) {
    if (raw == null) return null;
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    return int.tryParse(raw.toString());
  }

  String? _encodeJson(Object? raw) {
    if (raw == null) return null;
    return jsonEncode(raw);
  }

  List<Map<String, dynamic>> _decodeJsonList(String? raw) {
    if (raw == null || raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
      }
    } catch (_) {}
    return const [];
  }

  // ─────────────────────────────────────────────────────────────────
  // FieldPlantInstances — per-bitki sağlık durumu + tekil bitki yerleştirme
  // ─────────────────────────────────────────────────────────────────

  /// Yeni bir tekil bitki kaydı oluşturur. Iki kullanım:
  ///  • Standalone tekil bitki: cropId=null + plantIndex=null
  ///  • Zone içi sağlık override: cropId=set + plantIndex=set
  Future<String> insertPlantInstance({
    required String fieldId,
    String? cropId,
    int? plantIndex,
    required String cropName,
    required double lat,
    required double lng,
    String healthStatus = 'healthy',
    String? facingDirection,
  }) async {
    final now = DateTime.now().toUtc();
    final id = _newId('plant');
    await _db.into(_db.fieldPlantInstances).insert(
          FieldPlantInstancesCompanion(
            id: Value(id),
            fieldId: Value(fieldId),
            cropId: Value(cropId),
            plantIndex: Value(plantIndex),
            cropName: Value(cropName),
            lat: Value(lat),
            lng: Value(lng),
            healthStatus: Value(healthStatus),
            facingDirection: Value(facingDirection),
            farmerUid: Value(currentUid),
            plantedAt: Value(now),
            createdAt: Value(now),
            updatedAt: Value(now),
          ),
        );
    await _enqueueSyncJob(
      entityType: 'field_plant_instances',
      entityId: id,
      operation: 'upsert',
      payload: {
        'id': id,
        'field_id': fieldId,
        'crop_id': cropId,
        'plant_index': plantIndex,
        'crop_name': cropName,
        'lat': lat,
        'lng': lng,
        'health_status': healthStatus,
        'facing_direction': facingDirection,
        'updated_at': now.toIso8601String(),
      },
      updatedAt: now,
    );
    return id;
  }

  /// Mevcut bir bitki kaydının sağlık durumunu günceller. Varsayılan olarak
  /// eski çağrılarla uyum için aktivite günlüğüne sağlık değişimi düşebilir.
  /// Ekran akışları kendi anlamlı tekil/toplu gözlem kaydını yazıyorsa
  /// [writeActivityLog] false geçilir; böylece Tarlam Günlüğü düşük seviye
  /// bitki başı kayıtlarla dolmaz.
  Future<void> setPlantHealth({
    required String instanceId,
    required String healthStatus,
    String? diseaseType,
    String? diseasePhotoPath,
    String diagnosisSource = 'manual',
    String? notes,
    bool writeActivityLog = true,
  }) async {
    final now = DateTime.now().toUtc();
    final inst = await (_db.select(_db.fieldPlantInstances)
          ..where((tbl) => tbl.id.equals(instanceId)))
        .getSingleOrNull();
    if (inst == null) return;

    await (_db.update(_db.fieldPlantInstances)
          ..where((tbl) => tbl.id.equals(instanceId)))
        .write(FieldPlantInstancesCompanion(
      healthStatus: Value(healthStatus),
      diseaseType: Value(diseaseType),
      diseasePhotoPath: Value(diseasePhotoPath),
      diagnosisSource: Value(diagnosisSource),
      notes: Value(notes),
      healthChangedAt: Value(now),
      updatedAt: Value(now),
    ));

    await _enqueueSyncJob(
      entityType: 'field_plant_instances',
      entityId: instanceId,
      operation: 'upsert',
      payload: {
        'id': instanceId,
        'field_id': inst.fieldId,
        'health_status': healthStatus,
        'disease_type': diseaseType,
        'disease_photo_path': diseasePhotoPath,
        'diagnosis_source': diagnosisSource,
        'updated_at': now.toIso8601String(),
      },
      updatedAt: now,
    );

    // Hasta/ölü işaretlendiğinde aktivite günlüğüne 'scouting' düş
    if (writeActivityLog &&
        (healthStatus == 'diseased' || healthStatus == 'dead')) {
      final note = healthStatus == 'dead'
          ? 'Bitki ölü olarak işaretlendi'
          : (diseaseType != null && diseaseType.isNotEmpty
              ? 'Hastalık: $diseaseType'
              : 'Hasta olarak işaretlendi');
      await logActivity(
        fieldId: inst.fieldId,
        type: 'scouting',
        cropId: inst.cropId,
        note: note,
        metadata: {
          'plant_instance_id': instanceId,
          'health_status': healthStatus,
          if (diseaseType != null) 'disease_type': diseaseType,
          if (diseasePhotoPath != null) 'photo_path': diseasePhotoPath,
          'diagnosis_source': diagnosisSource,
        },
      );
    }
  }

  /// Tarladaki tüm tekil bitki kayıtlarını canlı dinler (soft-delete'siz).
  Stream<List<FieldPlantInstance>> watchPlantInstances(String fieldId) {
    final query = _db.select(_db.fieldPlantInstances)
      ..where((tbl) => tbl.fieldId.equals(fieldId) & tbl.deletedAt.isNull());
    return query.watch();
  }

  /// Tekil bitki için yeni bir durum gözlemi ekler — PlantConditionEvents
  /// tablosuna audit log satırı düşer ve FieldPlantInstances.lastObservedAt
  /// güncellenir. v9 / MVP-1: lokal-only (sync outbox'a düşmez).
  Future<void> logPlantCondition({
    required String plantInstanceId,
    required String fieldId,
    String? cropId,
    required String condition,
    String sourceType = 'manual',
    String? notes,
    String? photoPath,
    DateTime? observedAt,
  }) async {
    final now = DateTime.now().toUtc();
    final at = (observedAt ?? now).toUtc();
    final id = _newId('pcond');
    await _db.into(_db.plantConditionEvents).insert(
          PlantConditionEventsCompanion(
            id: Value(id),
            plantInstanceId: Value(plantInstanceId),
            fieldId: Value(fieldId),
            cropId: Value(cropId),
            condition: Value(condition),
            sourceType: Value(sourceType),
            notes: Value(notes),
            photoPath: Value(photoPath),
            observedAt: Value(at),
            farmerUid: Value(currentUid),
            createdAt: Value(now),
            updatedAt: Value(now),
          ),
        );
    // FieldPlantInstance.lastObservedAt'ı güncel tut — geçmiş paneli ve
    // tavsiye motoru "son N gün" pencereleri bu alandan filtreler.
    await (_db.update(_db.fieldPlantInstances)
          ..where((tbl) => tbl.id.equals(plantInstanceId)))
        .write(FieldPlantInstancesCompanion(
      lastObservedAt: Value(at),
      updatedAt: Value(now),
    ));
  }

  /// Tekil bitki için aktif durum bayrak listesini değiştirir
  /// (FieldPlantInstances.conditionFlagsJson). Liste set semantiği taşır;
  /// duplicate'ler ayıklanır, sıra korunmaz. Boş liste null'a çevrilir.
  ///
  /// Bu metot sadece "şu anki durum" snapshot'ını yazar. Geçmiş için
  /// [logPlantCondition] çağırılması gerekir; iki çağrı genelde birlikte
  /// kullanılır (UI chip seçimi → her yeni bayrak için bir log + son liste).
  Future<void> setPlantConditionFlags({
    required String plantInstanceId,
    required List<String> flags,
  }) async {
    final now = DateTime.now().toUtc();
    final cleaned =
        flags.map((f) => f.trim()).where((f) => f.isNotEmpty).toSet().toList();
    final json = cleaned.isEmpty ? null : jsonEncode(cleaned);
    final inst = await (_db.select(_db.fieldPlantInstances)
          ..where((tbl) => tbl.id.equals(plantInstanceId)))
        .getSingleOrNull();
    if (inst == null) return;
    await (_db.update(_db.fieldPlantInstances)
          ..where((tbl) => tbl.id.equals(plantInstanceId)))
        .write(FieldPlantInstancesCompanion(
      conditionFlagsJson: Value(json),
      lastObservedAt: Value(now),
      updatedAt: Value(now),
    ));
    await _enqueueSyncJob(
      entityType: 'field_plant_instances',
      entityId: plantInstanceId,
      operation: 'upsert',
      payload: {
        'id': plantInstanceId,
        'field_id': inst.fieldId,
        'condition_flags': cleaned,
        'last_observed_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
      },
      updatedAt: now,
    );
  }

  /// Standalone tekil bitkinin baktığı yönünü günceller.
  Future<void> updatePlantInstanceFacingDirection({
    required String instanceId,
    String? facingDirection,
  }) async {
    final now = DateTime.now().toUtc();
    final inst = await (_db.select(_db.fieldPlantInstances)
          ..where((tbl) => tbl.id.equals(instanceId)))
        .getSingleOrNull();
    if (inst == null) return;

    await (_db.update(_db.fieldPlantInstances)
          ..where((tbl) => tbl.id.equals(instanceId)))
        .write(FieldPlantInstancesCompanion(
      facingDirection: Value(facingDirection),
      updatedAt: Value(now),
    ));

    await _enqueueSyncJob(
      entityType: 'field_plant_instances',
      entityId: instanceId,
      operation: 'upsert',
      payload: {
        'id': instanceId,
        'field_id': inst.fieldId,
        'facing_direction': facingDirection,
        'updated_at': now.toIso8601String(),
      },
      updatedAt: now,
    );
  }

  /// Tarladaki tüm bitki durum gözlemlerini (PlantConditionEvents) canlı
  /// dinler — yeni gözlem girildiğinde tavsiye motoru anında yenilenir.
  Stream<List<PlantConditionEvent>> watchPlantConditionEventsForField(
    String fieldId, {
    int limit = 200,
  }) {
    final query = _db.select(_db.plantConditionEvents)
      ..where((tbl) => tbl.fieldId.equals(fieldId) & tbl.deletedAt.isNull())
      ..orderBy([(t) => OrderingTerm.desc(t.observedAt)])
      ..limit(limit);
    return query.watch();
  }

  /// Bir tekil bitkinin durum gözlem geçmişini canlı dinler — yeni → eski.
  /// UI'daki "Durum geçmişi" paneli ve kural motorunun son-N-gün pencereleri
  /// bu stream'den okur.
  Stream<List<PlantConditionEvent>> watchPlantConditionHistory(
    String plantInstanceId, {
    int limit = 100,
  }) {
    final query = _db.select(_db.plantConditionEvents)
      ..where((tbl) =>
          tbl.plantInstanceId.equals(plantInstanceId) & tbl.deletedAt.isNull())
      ..orderBy([(t) => OrderingTerm.desc(t.observedAt)])
      ..limit(limit);
    return query.watch();
  }

  /// Bir zone'a (cropId) bağlı tüm sağlık override'larını plantIndex ile
  /// indekslenmiş haritada döner — marker render'ında hızlı lookup için.
  Future<Map<int, FieldPlantInstance>> instancesForCrop(String cropId) async {
    final rows = await (_db.select(_db.fieldPlantInstances)
          ..where((tbl) =>
              tbl.cropId.equals(cropId) &
              tbl.plantIndex.isNotNull() &
              tbl.deletedAt.isNull()))
        .get();
    return {for (final r in rows) r.plantIndex!: r};
  }

  /// Bir tekil bitki kaydını siler (soft-delete).
  Future<void> deletePlantInstance(String instanceId) async {
    final now = DateTime.now().toUtc();
    await (_db.update(_db.fieldPlantInstances)
          ..where((tbl) => tbl.id.equals(instanceId)))
        .write(FieldPlantInstancesCompanion(
      deletedAt: Value(now),
      updatedAt: Value(now),
    ));
    await _enqueueSyncJob(
      entityType: 'field_plant_instances',
      entityId: instanceId,
      operation: 'delete',
      payload: {'id': instanceId},
      updatedAt: now,
    );
  }
}
