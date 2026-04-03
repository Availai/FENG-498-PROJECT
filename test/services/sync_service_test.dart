import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:feng_498/data/app_database.dart';
import 'package:feng_498/services/repositories/sync_repository.dart';
import 'package:feng_498/services/sync_service.dart';

void main() {
  late AppDatabase database;
  late SyncRepository repository;
  late SyncService service;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    repository = SyncRepository(database: database);
    service = SyncService(syncRepository: repository);
  });

  tearDown(() async {
    await database.close();
  });

  Future<int> seedPending(String entityId) {
    return database.into(database.syncJobs).insert(
          SyncJobsCompanion.insert(
            entityType: 'fields',
            entityId: entityId,
            operation: 'upsert',
            payloadJson: '{}',
            updatedAt: DateTime.now().toUtc(),
            status: const Value('pending'),
          ),
        );
  }

  test('runPushCycle completes successful jobs', () async {
    final id1 = await seedPending('f-1');
    final id2 = await seedPending('f-2');

    final report = await service.runPushCycle(
      pushHandler: (jobs) async {
        return SyncPushResult(completedIds: {id1, id2});
      },
    );

    expect(report.picked, 2);
    expect(report.completed, 2);
    expect(report.failed, 0);

    final remaining = await database.select(database.syncJobs).get();
    expect(remaining, isEmpty);
  });

  test('runPushCycle marks unresolved jobs as failed', () async {
    await seedPending('f-1');
    await seedPending('f-2');

    final report = await service.runPushCycle(
      pushHandler: (_) async => const SyncPushResult(),
    );

    expect(report.picked, 2);
    expect(report.completed, 0);
    expect(report.failed, 2);

    final failedRows = await (database.select(database.syncJobs)
          ..where((tbl) => tbl.status.equals('failed')))
        .get();
    expect(failedRows.length, 2);
    expect(failedRows.first.lastError, isNotNull);
  });

  test('runPushCycle marks all picked jobs failed on handler exception', () async {
    await seedPending('f-1');

    final report = await service.runPushCycle(
      pushHandler: (_) async {
        throw Exception('network down');
      },
    );

    expect(report.picked, 1);
    expect(report.completed, 0);
    expect(report.failed, 1);

    final failed = await (database.select(database.syncJobs)
          ..where((tbl) => tbl.entityId.equals('f-1')))
        .getSingle();
    expect(failed.status, 'failed');
    expect(failed.attemptCount, 1);
    expect(failed.lastError, contains('Push hatası'));
  });
}
