import 'dart:io';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';

import '../data/app_database.dart';
import 'api/sync_api_client.dart';
import 'repositories/sync_repository.dart';
import 'sync_models.dart';

class SyncService {
  SyncService({
    required SyncRepository syncRepository,
    AppDatabase? database,
  })  : _syncRepository = syncRepository,
        _db = database;

  final SyncRepository _syncRepository;
  final AppDatabase? _db;

  /// Senkronizasyon devam ediyor mu?
  bool _running = false;

  // ── Network kontrolü ───────────────────────────────────────────────────

  /// Basit DNS lookup ile internet bağlantısını kontrol et.
  /// Harici paket gerektirmez; çevrimdışıysa `false` döner.
  static Future<bool> hasNetwork() async {
    try {
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 3));
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  // ── Foreground orchestrator ────────────────────────────────────────────

  /// Uygulama foreground'da iken çağrılır.
  /// 1. Network yoksa sessizce atla.
  /// 2. Başarısız (failed) job'ları pending'e geri al.
  /// 3. Push cycle'ı çalıştır.
  /// 4. Pull cycle'ı çalıştır.
  /// 5. Son başarılı sync zamanını kaydet.
  ///
  /// Ardışık çağrılara karşı korumalıdır (_running guard).
  Future<SyncRunReport> runForegroundSync({
    required SyncApiClient apiClient,
    int batchSize = 25,
  }) async {
    if (_running) {
      return const SyncRunReport(picked: 0, completed: 0, failed: 0);
    }
    _running = true;

    try {
      // 1. Network kontrolü
      final online = await hasNetwork();
      if (!online) {
        debugPrint('[Sync] Çevrimdışı — senkronizasyon atlanıyor.');
        return const SyncRunReport(picked: 0, completed: 0, failed: 0);
      }

      // 2. Başarısız job'ları tekrar dene
      final retriedCount = await _syncRepository.retryFailedJobs(limit: batchSize);
      if (retriedCount > 0) {
        debugPrint('[Sync] $retriedCount başarısız iş yeniden kuyruğa alındı.');
      }

      // 3. Push cycle
      final report = await runPushCycleWithApi(
        apiClient: apiClient,
        batchSize: batchSize,
      );

      // 4. Başarılıysa zamanı kaydet
      if (report.completed > 0) {
        await _syncRepository.setLastSyncAt(
          key: 'last_push_at',
          timestamp: DateTime.now().toUtc(),
        );
      }

      // 5. Pull cycle — sunucudan güncel verileri çek
      try {
        final pullCount = await runPullCycle(apiClient: apiClient);
        debugPrint('[Sync] Pull: $pullCount kayıt uygulandı.');
      } catch (e) {
        debugPrint('[Sync] Pull hatası (push başarılı): $e');
      }

      debugPrint(
        '[Sync] Sonuç: ${report.completed} push başarılı, '
        '${report.failed} başarısız / ${report.picked} toplam',
      );
      return report;
    } catch (e) {
      debugPrint('[Sync] Foreground sync hatası: $e');
      return const SyncRunReport(picked: 0, completed: 0, failed: 0);
    } finally {
      _running = false;
    }
  }

  // ── Pull cycle ─────────────────────────────────────────────────────────

  /// Sunucudan son pull zamanından sonraki kayıtları çeker ve
  /// yerel Drift tablolarına LWW ile uygular.
  /// Dönen değer: uygulanan kayıt sayısı.
  Future<int> runPullCycle({required SyncApiClient apiClient}) async {
    if (_db == null) {
      debugPrint('[Sync] Pull atlandı — veritabanı referansı yok.');
      return 0;
    }

    // 1. Son pull zamanını al
    final lastPullAt = await _syncRepository.getLastSyncAt('last_pull_at');

    // 2. Sunucudan çek
    final pullResult = await apiClient.pullChanges(since: lastPullAt);
    if (pullResult.items.isEmpty) {
      debugPrint('[Sync] Sunucuda yeni kayıt yok.');
      // Yine de server_time'ı güncelle (boş cevaplarla senkron kalması için)
      if (pullResult.serverTime != null) {
        await _syncRepository.setLastSyncAt(
          key: 'last_pull_at',
          timestamp: pullResult.serverTime!,
        );
      }
      return 0;
    }

    // 3. Her kayıdı entity_type'a göre LWW ile uygula
    int applied = 0;
    for (final item in pullResult.items) {
      try {
        final didApply = await _applyPullItem(item);
        if (didApply) applied++;
      } catch (e) {
        debugPrint('[Sync] Pull item uygulama hatası '
            '(${item.entityType}/${item.entityId}): $e');
      }
    }

    // 4. Son pull zamanını kaydet
    final newPullAt = pullResult.serverTime ?? DateTime.now().toUtc();
    await _syncRepository.setLastSyncAt(
      key: 'last_pull_at',
      timestamp: newPullAt,
    );

    return applied;
  }

  /// Tek bir pull item'ı yerel DB'ye uygula.
  /// LWW: yerel updated_at > gelen updated_at ise atla.
  Future<bool> _applyPullItem(SyncPullItem item) async {
    final db = _db!;

    switch (item.entityType) {
      case 'fields':
        return _applyFieldItem(db, item);
      case 'field_crops':
        return _applyFieldCropItem(db, item);
      case 'calendar_events':
        return _applyCalendarEventItem(db, item);
      case 'irrigation_plans':
        return _applyIrrigationPlanItem(db, item);
      case 'suitability_reports':
        return _applySuitabilityReportItem(db, item);
      default:
        debugPrint('[Sync] Bilinmeyen entity_type: ${item.entityType}');
        return false;
    }
  }

  Future<bool> _applyFieldItem(AppDatabase db, SyncPullItem item) async {
    final existing = await (db.select(db.fields)
          ..where((tbl) => tbl.id.equals(item.entityId)))
        .getSingleOrNull();

    // LWW kontrolü: yerel daha yeni ise atla
    if (existing != null && existing.updatedAt.isAfter(item.updatedAt)) {
      return false;
    }

    if (item.operation == 'delete') {
      await (db.update(db.fields)
            ..where((tbl) => tbl.id.equals(item.entityId)))
          .write(FieldsCompanion(
        updatedAt: Value(item.updatedAt),
        deletedAt: Value(item.updatedAt),
      ));
      return true;
    }

    // Upsert
    final p = item.payload;
    await db.into(db.fields).insertOnConflictUpdate(FieldsCompanion(
      id: Value(item.entityId),
      name: Value((p['name'] ?? existing?.name ?? 'İsimsiz').toString()),
      crop: Value(p['crop']?.toString() ?? existing?.crop),
      date: Value((p['date'] ?? existing?.date ?? '').toString()),
      latitude: Value(_toDouble(p['latitude']) ?? existing?.latitude),
      longitude: Value(_toDouble(p['longitude']) ?? existing?.longitude),
      areaDekar: Value(_toDouble(p['area_dekar']) ?? existing?.areaDekar),
      areaSqm: Value(_toDouble(p['area_sqm']) ?? existing?.areaSqm),
      polygonJson: Value(p['polygon']?.toString() ?? existing?.polygonJson),
      createdAt: Value(existing?.createdAt ?? item.updatedAt),
      updatedAt: Value(item.updatedAt),
      deletedAt: const Value(null),
    ));
    return true;
  }

  Future<bool> _applyFieldCropItem(AppDatabase db, SyncPullItem item) async {
    final existing = await (db.select(db.fieldCrops)
          ..where((tbl) => tbl.id.equals(item.entityId)))
        .getSingleOrNull();

    if (existing != null && existing.updatedAt.isAfter(item.updatedAt)) {
      return false;
    }

    if (item.operation == 'delete') {
      await (db.update(db.fieldCrops)
            ..where((tbl) => tbl.id.equals(item.entityId)))
          .write(FieldCropsCompanion(
        updatedAt: Value(item.updatedAt),
        deletedAt: Value(item.updatedAt),
      ));
      return true;
    }

    final p = item.payload;
    await db.into(db.fieldCrops).insertOnConflictUpdate(FieldCropsCompanion(
      id: Value(item.entityId),
      fieldId: Value((p['field_id'] ?? existing?.fieldId ?? '').toString()),
      name: Value((p['name'] ?? existing?.name ?? 'Bitki').toString()),
      zoneStart: Value(_toDouble(p['zone_start']) ?? existing?.zoneStart ?? 0.0),
      zoneEnd: Value(_toDouble(p['zone_end']) ?? existing?.zoneEnd ?? 1.0),
      rowSpacingCm: Value(_toDouble(p['row_spacing_cm']) ?? existing?.rowSpacingCm ?? 50.0),
      plantSpacingCm: Value(_toDouble(p['plant_spacing_cm']) ?? existing?.plantSpacingCm ?? 40.0),
      colorValue: Value(_toInt(p['color_value']) ?? existing?.colorValue),
      plantedDate: Value(p['planted_date']?.toString() ?? existing?.plantedDate),
      harvestDays: Value(_toInt(p['harvest_days']) ?? existing?.harvestDays ?? 90),
      waterIntervalDays: Value(_toInt(p['water_interval_days']) ?? existing?.waterIntervalDays ?? 7),
      createdAt: Value(existing?.createdAt ?? item.updatedAt),
      updatedAt: Value(item.updatedAt),
      deletedAt: const Value(null),
    ));
    return true;
  }

  Future<bool> _applyCalendarEventItem(AppDatabase db, SyncPullItem item) async {
    final existing = await (db.select(db.calendarEvents)
          ..where((tbl) => tbl.id.equals(item.entityId)))
        .getSingleOrNull();

    if (existing != null && existing.updatedAt.isAfter(item.updatedAt)) {
      return false;
    }

    if (item.operation == 'delete') {
      await (db.update(db.calendarEvents)
            ..where((tbl) => tbl.id.equals(item.entityId)))
          .write(CalendarEventsCompanion(
        updatedAt: Value(item.updatedAt),
        deletedAt: Value(item.updatedAt),
      ));
      return true;
    }

    final p = item.payload;
    final eventDateStr = p['event_date']?.toString();
    final eventDate = (eventDateStr != null ? DateTime.tryParse(eventDateStr) : null)
        ?? existing?.eventDate
        ?? DateTime.now().toUtc();

    await db.into(db.calendarEvents).insertOnConflictUpdate(CalendarEventsCompanion(
      id: Value(item.entityId),
      fieldId: Value(p['field_id']?.toString() ?? existing?.fieldId),
      cropId: Value(p['crop_id']?.toString() ?? existing?.cropId),
      title: Value((p['title'] ?? existing?.title ?? '').toString()),
      eventType: Value((p['event_type'] ?? existing?.eventType ?? 'manual').toString()),
      eventDate: Value(eventDate),
      createdAt: Value(existing?.createdAt ?? item.updatedAt),
      updatedAt: Value(item.updatedAt),
      deletedAt: const Value(null),
    ));
    return true;
  }

  Future<bool> _applyIrrigationPlanItem(AppDatabase db, SyncPullItem item) async {
    final existing = await (db.select(db.irrigationPlans)
          ..where((tbl) => tbl.id.equals(item.entityId)))
        .getSingleOrNull();

    if (existing != null && existing.updatedAt.isAfter(item.updatedAt)) {
      return false;
    }

    if (item.operation == 'delete') {
      await (db.update(db.irrigationPlans)
            ..where((tbl) => tbl.id.equals(item.entityId)))
          .write(IrrigationPlansCompanion(
        updatedAt: Value(item.updatedAt),
        deletedAt: Value(item.updatedAt),
      ));
      return true;
    }

    final p = item.payload;
    final scheduledDateStr = p['scheduled_date']?.toString();
    final scheduledDate = (scheduledDateStr != null ? DateTime.tryParse(scheduledDateStr) : null)
        ?? existing?.scheduledDate
        ?? DateTime.now().toUtc();

    await db.into(db.irrigationPlans).insertOnConflictUpdate(IrrigationPlansCompanion(
      id: Value(item.entityId),
      fieldId: Value((p['field_id'] ?? existing?.fieldId ?? '').toString()),
      cropId: Value(p['crop_id']?.toString() ?? existing?.cropId),
      scheduledDate: Value(scheduledDate),
      shouldIrrigate: Value(p['should_irrigate'] as bool? ?? existing?.shouldIrrigate ?? true),
      reason: Value((p['reason'] ?? existing?.reason ?? '').toString()),
      recommendation: Value(p['recommendation']?.toString() ?? existing?.recommendation),
      createdAt: Value(existing?.createdAt ?? item.updatedAt),
      updatedAt: Value(item.updatedAt),
      deletedAt: const Value(null),
    ));
    return true;
  }

  Future<bool> _applySuitabilityReportItem(AppDatabase db, SyncPullItem item) async {
    final existing = await (db.select(db.suitabilityReports)
          ..where((tbl) => tbl.id.equals(item.entityId)))
        .getSingleOrNull();

    if (existing != null && existing.updatedAt.isAfter(item.updatedAt)) {
      return false;
    }

    if (item.operation == 'delete') {
      await (db.update(db.suitabilityReports)
            ..where((tbl) => tbl.id.equals(item.entityId)))
          .write(SuitabilityReportsCompanion(
        updatedAt: Value(item.updatedAt),
        deletedAt: Value(item.updatedAt),
      ));
      return true;
    }

    final p = item.payload;
    final reportJson = p['report'] is Map
        ? p['report'] as Map<String, dynamic>
        : const <String, dynamic>{};

    await db.into(db.suitabilityReports).insertOnConflictUpdate(SuitabilityReportsCompanion(
      id: Value(item.entityId),
      fieldId: Value((p['field_id'] ?? existing?.fieldId ?? '').toString()),
      cropName: Value((p['crop_name'] ?? existing?.cropName ?? '').toString()),
      score: Value(_toDouble(p['score']) ?? existing?.score),
      reportJson: Value(reportJson.toString()),
      createdAt: Value(existing?.createdAt ?? item.updatedAt),
      updatedAt: Value(item.updatedAt),
      deletedAt: const Value(null),
    ));
    return true;
  }

  // ── Yardımcılar ────────────────────────────────────────────────────────

  static double? _toDouble(Object? raw) {
    if (raw == null) return null;
    if (raw is num) return raw.toDouble();
    return double.tryParse(raw.toString());
  }

  static int? _toInt(Object? raw) {
    if (raw == null) return null;
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    return int.tryParse(raw.toString());
  }

  // ── Core push cycle ────────────────────────────────────────────────────

  Future<SyncRunReport> runPushCycle({
    required SyncPushHandler pushHandler,
    int batchSize = 25,
  }) async {
    final pending = await _syncRepository.loadPendingJobs(limit: batchSize);
    if (pending.isEmpty) {
      return const SyncRunReport(picked: 0, completed: 0, failed: 0);
    }

    final ids = pending.map((job) => job.id).toList();
    await _syncRepository.markInProgress(ids);

    try {
      final result = await pushHandler(pending);

      final completedIds = <int>{};
      for (final id in result.completedIds) {
        if (!ids.contains(id)) continue;
        await _syncRepository.markCompleted(id);
        completedIds.add(id);
      }

      final failedIds = <int>{};
      for (final entry in result.failedById.entries) {
        if (!ids.contains(entry.key)) continue;
        await _syncRepository.markFailed(id: entry.key, error: entry.value);
        failedIds.add(entry.key);
      }

      final unresolved = ids.where((id) =>
          !completedIds.contains(id) && !failedIds.contains(id));
      for (final id in unresolved) {
        await _syncRepository.markFailed(
          id: id,
          error: 'Senkron sonucu belirsiz: yanıt kaydı eksik.',
        );
      }

      return SyncRunReport(
        picked: ids.length,
        completed: completedIds.length,
        failed: ids.length - completedIds.length,
      );
    } catch (e) {
      for (final id in ids) {
        await _syncRepository.markFailed(id: id, error: 'Push hatası: $e');
      }
      return SyncRunReport(
        picked: ids.length,
        completed: 0,
        failed: ids.length,
      );
    }
  }

  Future<SyncRunReport> runPushCycleWithApi({
    required SyncApiClient apiClient,
    int batchSize = 25,
  }) {
    return runPushCycle(
      batchSize: batchSize,
      pushHandler: apiClient.pushJobs,
    );
  }
}

