import 'package:drift/drift.dart';

import '../../data/app_database.dart';

class SyncRepository {
  SyncRepository({required AppDatabase database}) : _db = database;

  final AppDatabase _db;

  Future<List<SyncJob>> loadPendingJobs({int limit = 50}) {
    final query = _db.select(_db.syncJobs)
      ..where((tbl) => tbl.status.equals('pending'))
      ..orderBy([
        (tbl) => OrderingTerm.asc(tbl.updatedAt),
        (tbl) => OrderingTerm.asc(tbl.id),
      ])
      ..limit(limit);
    return query.get();
  }

  Future<void> markInProgress(List<int> ids) async {
    if (ids.isEmpty) return;
    await (_db.update(_db.syncJobs)..where((tbl) => tbl.id.isIn(ids))).write(
      const SyncJobsCompanion(
        status: Value('in_progress'),
      ),
    );
  }

  Future<void> markCompleted(int id) async {
    await (_db.delete(_db.syncJobs)..where((tbl) => tbl.id.equals(id))).go();
  }

  Future<void> markFailed({
    required int id,
    required String error,
  }) async {
    await _db.transaction(() async {
      final current = await (_db.select(_db.syncJobs)
            ..where((tbl) => tbl.id.equals(id)))
          .getSingleOrNull();
      if (current == null) return;

      await (_db.update(_db.syncJobs)..where((tbl) => tbl.id.equals(id))).write(
        SyncJobsCompanion(
          status: const Value('failed'),
          attemptCount: Value(current.attemptCount + 1),
          lastError: Value(error),
        ),
      );
    });
  }

  Future<DateTime?> getLastSyncAt(String key) async {
    final row = await (_db.select(_db.syncState)
          ..where((tbl) => tbl.key.equals(key)))
        .getSingleOrNull();

    if (row == null || row.value == null || row.value!.isEmpty) {
      return null;
    }
    return DateTime.tryParse(row.value!);
  }

  Future<void> setLastSyncAt({
    required String key,
    required DateTime timestamp,
  }) async {
    await _db.into(_db.syncState).insertOnConflictUpdate(
          SyncStateCompanion(
            key: Value(key),
            value: Value(timestamp.toUtc().toIso8601String()),
            updatedAt: Value(DateTime.now().toUtc()),
          ),
        );
  }
}
