import 'dart:convert';
import 'dart:math';

import 'package:drift/drift.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../data/app_database.dart';

class LocalDataRepository {
  LocalDataRepository({
    required AppDatabase database,
  }) : _db = database;

  final AppDatabase _db;

  Box get _legacyFieldsBox => Hive.box('user_crops');
  Box get _settingsBox => Hive.box('settingsBox');

  Future<void> bootstrapFromLegacyHive() async {
    final migrated = _settingsBox.get('drift_user_crops_bootstrap_v1') == true;
    if (migrated) {
      await _mirrorActiveFieldsToHive();
      return;
    }

    final fieldCount = await _db.select(_db.fields).get().then((rows) => rows.length);
    if (fieldCount == 0 && _legacyFieldsBox.isNotEmpty) {
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
    }

    await _settingsBox.put('drift_user_crops_bootstrap_v1', true);
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
  }) async {
    final now = DateTime.now().toUtc();
    final id = _newId('event');
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
            metadataJson: const Value(null),
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
      },
      updatedAt: now,
    );
  }

  Future<void> _regenerateIrrigationPlans({
    required String fieldId,
    required DateTime referenceTime,
  }) async {
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
          final irrigationId = _newId('irrigation');
          await _db.into(_db.irrigationPlans).insert(
                IrrigationPlansCompanion.insert(
                  id: irrigationId,
                  fieldId: fieldId,
                  scheduledDate: current.toUtc(),
                  shouldIrrigate: const Value(true),
                  reason: 'Varsayılan sulama döngüsüne göre üretildi.',
                  recommendation: Value('${crop.name} için planlanan sulama'),
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
              'should_irrigate': true,
              'reason': 'Varsayılan sulama döngüsüne göre üretildi.',
            },
            updatedAt: referenceTime,
          );
        }
        current = current.add(Duration(days: waterInterval));
      }
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
      'created_at': crop.createdAt.toIso8601String(),
      'updated_at': crop.updatedAt.toIso8601String(),
    };
  }

  SimpleSelectStatement<$FieldsTable, Field> _activeFieldsQuery() {
    return _db.select(_db.fields)
      ..where((tbl) => tbl.deletedAt.isNull())
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
