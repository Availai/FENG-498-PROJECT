import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:feng_498/data/app_database.dart';
import 'package:feng_498/services/repositories/sync_repository.dart';

void main() {
  late AppDatabase database;
  late SyncRepository repository;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    repository = SyncRepository(database: database);
  });

  tearDown(() async {
    await database.close();
  });

  test('loadPendingJobs only returns pending rows ordered by updatedAt', () async {
    final now = DateTime.now().toUtc();

    await database.into(database.syncJobs).insert(
          SyncJobsCompanion.insert(
            entityType: 'fields',
            entityId: 'f-2',
            operation: 'upsert',
            payloadJson: '{}',
            updatedAt: now.add(const Duration(minutes: 5)),
            status: const Value('pending'),
          ),
        );

    await database.into(database.syncJobs).insert(
          SyncJobsCompanion.insert(
            entityType: 'fields',
            entityId: 'f-1',
            operation: 'upsert',
            payloadJson: '{}',
            updatedAt: now,
            status: const Value('pending'),
          ),
        );

    await database.into(database.syncJobs).insert(
          SyncJobsCompanion.insert(
            entityType: 'fields',
            entityId: 'f-x',
            operation: 'upsert',
            payloadJson: '{}',
            updatedAt: now,
            status: const Value('failed'),
          ),
        );

    final jobs = await repository.loadPendingJobs();

    expect(jobs.length, 2);
    expect(jobs.first.entityId, 'f-1');
    expect(jobs.last.entityId, 'f-2');
  });

  test('markFailed increments attemptCount and stores error', () async {
    final id = await database.into(database.syncJobs).insert(
          SyncJobsCompanion.insert(
            entityType: 'calendar_events',
            entityId: 'ev-1',
            operation: 'upsert',
            payloadJson: '{}',
            updatedAt: DateTime.now().toUtc(),
          ),
        );

    await repository.markFailed(id: id, error: 'timeout');

    final row = await (database.select(database.syncJobs)
          ..where((tbl) => tbl.id.equals(id)))
        .getSingle();

    expect(row.status, 'failed');
    expect(row.attemptCount, 1);
    expect(row.lastError, 'timeout');
  });

  test('setLastSyncAt and getLastSyncAt round-trip', () async {
    final stamp = DateTime.utc(2026, 4, 3, 12, 0, 0);

    await repository.setLastSyncAt(key: 'fields_pull', timestamp: stamp);
    final loaded = await repository.getLastSyncAt('fields_pull');

    expect(loaded, isNotNull);
    expect(loaded!.toUtc(), stamp);
  });
}
