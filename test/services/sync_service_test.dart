import 'dart:convert';

import 'package:drift/drift.dart' hide isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:feng_498/data/app_database.dart';
import 'package:feng_498/services/api/sync_api_client.dart';
import 'package:feng_498/services/repositories/sync_repository.dart';
import 'package:feng_498/services/sync_service.dart';
import 'package:feng_498/services/sync_models.dart';

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
    expect(failed.lastError, isNotNull);
    expect(failed.lastError, contains('network down'));
  });

  test('runPullCycle keeps field crop zone and spacing payload', () async {
    final now = DateTime.utc(2026, 4, 24);
    await database.into(database.fields).insert(
          FieldsCompanion.insert(
            id: 'field-1',
            name: 'Tarla',
            date: '24.04.2026',
            createdAt: now,
            updatedAt: now,
          ),
        );

    final serviceWithDb = SyncService(
      syncRepository: repository,
      database: database,
    );
    final client = SyncApiClient(
      baseUrl: 'http://sync.test',
      authTokenProvider: () async => 'user-token',
      httpClient: MockClient((request) async {
        expect(request.url.path, '/api/sync/pull');
        return http.Response(
          jsonEncode({
            'items': [
              {
                'entity_type': 'field_crops',
                'entity_id': 'crop-1',
                'operation': 'upsert',
                'updated_at': now.toIso8601String(),
                'payload': {
                  'field_id': 'field-1',
                  'name': 'Mısır',
                  'zone_start': 0,
                  'zone_end': 1,
                  'row_spacing_cm': 70,
                  'plant_spacing_cm': 20,
                  'planted_date': '01.04.2026',
                  'harvest_days': 110,
                  'water_interval_days': 7,
                  'color_value': 4280391411,
                  'zone_polygon_json':
                      '[{"lat":39.0,"lng":35.0},{"lat":39.0,"lng":35.1},{"lat":39.1,"lng":35.1}]',
                },
              },
            ],
            'server_time': now.add(const Duration(minutes: 1)).toIso8601String(),
          }),
          200,
        );
      }),
    );

    final applied = await serviceWithDb.runPullCycle(apiClient: client);
    final crop = await (database.select(database.fieldCrops)
          ..where((tbl) => tbl.id.equals('crop-1')))
        .getSingle();

    expect(applied, 1);
    expect(crop.rowSpacingCm, 70);
    expect(crop.plantSpacingCm, 20);
    expect(crop.zonePolygonJson, contains('"lat":39.0'));
  });
}
