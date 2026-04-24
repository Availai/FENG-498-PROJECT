import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:feng_498/data/app_database.dart';
import 'package:feng_498/services/api/sync_api_client.dart';

void main() {
  late AppDatabase database;

  String? headerValue(Map<String, String> headers, String name) {
    final lowerName = name.toLowerCase();
    for (final entry in headers.entries) {
      if (entry.key.toLowerCase() == lowerName) {
        return entry.value;
      }
    }
    return null;
  }

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await database.close();
  });

  test('pushJobs sends bearer token and parses completed/failed ids', () async {
    final id = await database.into(database.syncJobs).insert(
          SyncJobsCompanion.insert(
            entityType: 'fields',
            entityId: 'f-1',
            operation: 'upsert',
            payloadJson: '{"name":"Deneme"}',
            updatedAt: DateTime.utc(2026, 4, 3, 10, 0, 0),
            status: const Value('pending'),
          ),
        );

    final job = await (database.select(database.syncJobs)
          ..where((tbl) => tbl.id.equals(id)))
        .getSingle();

    late http.Request captured;
    final client = MockClient((request) async {
      captured = request;
      return http.Response(
        jsonEncode({
          'completed_ids': [id],
          'failed_by_id': {'999': 'remote validation error'},
        }),
        200,
      );
    });

    final apiClient = SyncApiClient(
      baseUrl: 'https://example.test',
      authTokenProvider: () async => 'token-123',
      httpClient: client,
    );

    final result = await apiClient.pushJobs([job]);

    expect(captured.url.toString(), 'https://example.test/api/sync/push');
    expect(headerValue(captured.headers, 'Authorization'), 'Bearer token-123');

    final body = jsonDecode(captured.body) as Map<String, dynamic>;
    expect((body['items'] as List).length, 1);

    expect(result.completedIds.contains(id), isTrue);
    expect(result.failedById[999], 'remote validation error');
  });
}
