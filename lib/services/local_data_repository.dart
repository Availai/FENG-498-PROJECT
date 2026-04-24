import 'dart:convert';
import 'dart:math';

import 'package:drift/drift.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;

import '../data/app_database.dart';

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
    final alreadyMigratedGlobally = _settingsBox.get(globalMigrationKey) == true;

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
    result.sort((a, b) => (b['updated_at'] as String).compareTo(a['updated_at'] as String));
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
    final fieldId = (raw['id']?.toString().trim().isNotEmpty ?? false)
        ? raw['id'].toString()
        : _newId('field');
    final createdAt = _parseTimestamp(raw['created_at']) ?? now;

    await _db.into(_db.fields).insertOnConflictUpdate(
          FieldsCompanion(
            id: Value(fieldId),
            farmerUid: Value(currentUid),
            name: Value((raw['name'] ?? 'İsimsiz Tarla').toString()),
            crop: Value(raw['crop']?.toString()),
            date: Value((raw['date'] ?? _formatDate(DateTime.now())).toString()),
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

  Future<void> deleteField(String fieldId) async {
    final now = DateTime.now().toUtc();
    await (_db.update(_db.fields)..where((tbl) => tbl.id.equals(fieldId))).write(
      FieldsCompanion(
        updatedAt: Value(now),
        deletedAt: Value(now),
      ),
    );
    await (_db.update(_db.fieldCrops)..where((tbl) => tbl.fieldId.equals(fieldId) & tbl.deletedAt.isNull())).write(
      FieldCropsCompanion(
        updatedAt: Value(now),
        deletedAt: Value(now),
      ),
    );
    await (_db.update(_db.irrigationPlans)..where((tbl) => tbl.fieldId.equals(fieldId) & tbl.deletedAt.isNull())).write(
      IrrigationPlansCompanion(
        updatedAt: Value(now),
        deletedAt: Value(now),
      ),
    );

    await _enqueueSyncJob(
      entityType: 'fields',
      entityId: fieldId,
      operation: 'delete',
      payload: {'id': fieldId},
      updatedAt: now,
    );
    await _mirrorActiveFieldsToHive();
  }

  Future<List<Map<String, dynamic>>> loadFieldCrops(String fieldId) async {
    final crops = await (_db.select(_db.fieldCrops)
          ..where((tbl) => tbl.fieldId.equals(fieldId) & tbl.deletedAt.isNull())
          ..orderBy([(tbl) => OrderingTerm.asc(tbl.createdAt)]))
        .get();
    return crops.map(_cropToMap).toList();
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
          ..where((tbl) => tbl.fieldId.equals(fieldId) & tbl.deletedAt.isNull()))
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
  Future<List<Map<String, dynamic>>> loadFieldIrrigationPlans(String fieldId) async {
    final plans = await (_db.select(_db.irrigationPlans)
          ..where((tbl) => tbl.fieldId.equals(fieldId) & tbl.deletedAt.isNull())
          ..orderBy([(tbl) => OrderingTerm.asc(tbl.scheduledDate)]))
        .get();
    return plans.map((p) => <String, dynamic>{
      'id': p.id,
      'field_id': p.fieldId,
      'crop_id': p.cropId,
      'scheduled_date': p.scheduledDate,
      'should_irrigate': p.shouldIrrigate,
      'reason': p.reason,
      'recommendation': p.recommendation,
    }).toList();
  }

  Future<void> replaceFieldCrops({
    required String fieldId,
    required List<Map<String, dynamic>> crops,
    bool enqueueSync = true,
    bool mirrorLegacy = true,
  }) async {
    final now = DateTime.now().toUtc();

    await (_db.update(_db.fieldCrops)..where((tbl) => tbl.fieldId.equals(fieldId) & tbl.deletedAt.isNull())).write(
      FieldCropsCompanion(
        updatedAt: Value(now),
        deletedAt: Value(now),
      ),
    );
    await (_db.update(_db.irrigationPlans)..where((tbl) => tbl.fieldId.equals(fieldId) & tbl.deletedAt.isNull())).write(
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
              plantSpacingCm: Value(_asDouble(crop['plant_spacing_cm']) ?? 40.0),
              colorValue: Value(_asInt(crop['color_value'])),
              plantedDate: Value(plantedDate),
              harvestDays: Value(harvestDays),
              waterIntervalDays: Value(waterIntervalDays),
              zonePolygonJson: Value(crop['zone_polygon_json']?.toString()),
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
          ..where((tbl) => tbl.deletedAt.isNull() & tbl.shouldIrrigate.equals(true))
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
        });
      }

      final crops = await (_db.select(_db.fieldCrops)
            ..where((tbl) => tbl.fieldId.equals(field.id) & tbl.deletedAt.isNull()))
          .get();
      for (final crop in crops) {
        final plantedDate = _parseLegacyDate(crop.plantedDate);
        if (plantedDate == null) continue;
        entries.add({
          'id': 'planting_${crop.id}',
          'title': '${crop.name} — ${field.name} Ekimi',
          'type': 'planting',
          'date': plantedDate,
        });
        entries.add({
          'id': 'harvest_${crop.id}',
          'title': '${crop.name} — ${field.name} Hasat',
          'type': 'harvest',
          'date': plantedDate.add(Duration(days: crop.harvestDays ?? 90)),
        });
      }
    }

    for (final plan in irrigationPlans) {
      final fieldName = fieldNames[plan.fieldId] ?? 'Tarla';
      entries.add({
        'id': plan.id,
        'title': '$fieldName — Sulama',
        'type': 'watering',
        'date': plan.scheduledDate.toLocal(),
      });
    }

    for (final event in customEvents) {
      entries.add({
        'id': event.id,
        'title': event.title,
        'type': event.eventType,
        'date': event.eventDate.toLocal(),
      });
    }

    entries.sort((a, b) => (a['date'] as DateTime).compareTo(b['date'] as DateTime));
    return entries;
  }

  Future<void> addCalendarEvent({
    String? fieldId,
    String? cropId,
    required String title,
    required String eventType,
    required DateTime eventDate,
    Map<String, dynamic>? metadata,
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
            metadataJson: Value(metaJson),
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
        'metadata': metadata,
      },
      updatedAt: now,
    );
  }

  /// Çiftçi dostu aktivite kaydı. Tek çağrıda Calendar event + sync outbox.
  /// [type] için [ActivityType] sabitlerini kullan.
  Future<void> logActivity({
    required String fieldId,
    required String type,
    String? cropId,
    String? note,
    double? quantity,
    String? quantityUnit,
    Map<String, dynamic>? metadata,
    DateTime? at,
  }) async {
    final field = await (_db.select(_db.fields)
          ..where((tbl) => tbl.id.equals(fieldId))
          ..limit(1))
        .getSingleOrNull();
    final fieldName = field?.name ?? 'Tarla';
    final title = _composeActivityTitle(fieldName, type);
    final meta = <String, dynamic>{...?metadata};
    if (note != null && note.trim().isNotEmpty) meta['note'] = note.trim();
    if (quantity != null) meta['quantity'] = quantity;
    if (quantityUnit != null) meta['quantity_unit'] = quantityUnit;
    await addCalendarEvent(
      fieldId: fieldId,
      cropId: cropId,
      title: title,
      eventType: type,
      eventDate: at ?? DateTime.now(),
      metadata: meta.isEmpty ? null : meta,
    );

    // Sulama log'u → bekleyen sulama planını "tamamlandı" olarak işaretle.
    // Yöntem: 3 gün içindeki bir sonraki should_irrigate=true planı bul,
    // shouldIrrigate=false yap ve sebebi güncelle. Plan tarihi olduğu gibi
    // kalır (geçmiş kayıt). Bu sayede _DirectiveCard "sulama gerekiyor"
    // direktifini düşürür ve sezon özeti hesabı doğru çalışır.
    if (type == 'watering') {
      await _consumeNextIrrigationPlan(fieldId: fieldId, cropId: cropId);
    }
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
          final liters = (meta['water_liters'] as num?)?.toDouble();
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
      ..where((tbl) => tbl.deletedAt.isNull());
    if (fieldId != null) {
      query.where((tbl) => tbl.fieldId.equals(fieldId));
    }
    query
      ..orderBy([(tbl) => OrderingTerm.desc(tbl.eventDate)])
      ..limit(limit);
    return query.watch().asyncMap((rows) async {
      final fields = await _activeFieldsQuery().get();
      final names = {for (final f in fields) f.id: f.name};
      final filtered = types == null || types.isEmpty
          ? rows
          : rows.where((r) => types.contains(r.eventType)).toList();
      return filtered.map((ev) {
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
          'field_name': ev.fieldId == null ? null : names[ev.fieldId],
          'crop_id': ev.cropId,
          'title': ev.title,
          'type': ev.eventType,
          'date': ev.eventDate.toLocal(),
          'source': ev.source,
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

  Future<Map<String, dynamic>?> loadLatestSuitabilityReport(String fieldId) async {
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
          ..where((tbl) => tbl.fieldId.equals(fieldId) & tbl.deletedAt.isNull()))
        .get();
    final horizon = referenceTime.add(const Duration(days: 60));

    for (final crop in crops) {
      final plantedDate = _parseLegacyDate(crop.plantedDate) ?? DateTime.now();
      final waterInterval = crop.waterIntervalDays ?? 7;
      final harvestDate = plantedDate.add(Duration(days: crop.harvestDays ?? 90));
      var current = plantedDate;

      while (current.isBefore(harvestDate) && current.isBefore(horizon)) {
        if (!current.isBefore(referenceTime.toLocal().subtract(const Duration(days: 1)))) {
          // Sulama günü için yağış kontrolü
          final dateKey = '${current.year}-${current.month.toString().padLeft(2, '0')}-${current.day.toString().padLeft(2, '0')}';
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
      'created_at': crop.createdAt.toIso8601String(),
      'updated_at': crop.updatedAt.toIso8601String(),
    };
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TEK BİTKİ CRUD — İnteraktif bölge yerleştirme sistemi için
  // ═══════════════════════════════════════════════════════════════════════════

  /// Mevcut bitkilere dokunmadan tarlaya tek bir bitki ekler.
  /// [zonePolygonJson]: JSON dizesi [{"lat":...,"lng":...}, ...]
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
        'zone_polygon_json': zonePolygonJson,
      },
      updatedAt: now,
    );

    await _regenerateIrrigationPlans(fieldId: fieldId, referenceTime: now);
    await _mirrorActiveFieldsToHive();
    return cropId;
  }

  /// Tek bir bitkiyi soft-delete eder.
  Future<void> deleteSingleCrop(String cropId) async {
    final now = DateTime.now().toUtc();

    final crop = await (_db.select(_db.fieldCrops)
          ..where((tbl) => tbl.id.equals(cropId)))
        .getSingleOrNull();
    if (crop == null) return;

    await (_db.update(_db.fieldCrops)..where((tbl) => tbl.id.equals(cropId)))
        .write(FieldCropsCompanion(
      updatedAt: Value(now),
      deletedAt: Value(now),
    ));

    // İlgili sulama planlarını da sil
    await (_db.update(_db.irrigationPlans)
          ..where((tbl) => tbl.cropId.equals(cropId) & tbl.deletedAt.isNull()))
        .write(IrrigationPlansCompanion(
      updatedAt: Value(now),
      deletedAt: Value(now),
    ));

    await _enqueueSyncJob(
      entityType: 'field_crops',
      entityId: cropId,
      operation: 'delete',
      payload: {'id': cropId},
      updatedAt: now,
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

    await _enqueueSyncJob(
      entityType: 'field_crops',
      entityId: cropId,
      operation: 'upsert',
      payload: {
        'id': cropId,
        'zone_polygon_json': zonePolygonJson,
      },
      updatedAt: now,
    );

    await _mirrorActiveFieldsToHive();
  }

  SimpleSelectStatement<$FieldsTable, Field> _activeFieldsQuery() {
    final uid = currentUid;
    return _db.select(_db.fields)
      ..where((tbl) => tbl.deletedAt.isNull() &
          (uid != null ? tbl.farmerUid.equals(uid) : tbl.farmerUid.isNull()))
      ..orderBy([(tbl) => OrderingTerm.asc(tbl.createdAt)]);
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
}
