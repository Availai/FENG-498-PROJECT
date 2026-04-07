import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../data/app_database.dart';
import '../sync_models.dart';

typedef AuthTokenProvider = Future<String?> Function();

class SyncApiClient {
  SyncApiClient({
    required String baseUrl,
    required AuthTokenProvider authTokenProvider,
    http.Client? httpClient,
  })  : _baseUrl = baseUrl,
        _authTokenProvider = authTokenProvider,
        _httpClient = httpClient ?? http.Client();

  final String _baseUrl;
  final AuthTokenProvider _authTokenProvider;
  final http.Client _httpClient;

  Future<SyncPushResult> pushJobs(List<SyncJob> jobs) async {
    if (jobs.isEmpty) {
      return const SyncPushResult();
    }

    final token = await _authTokenProvider();
    if (token == null || token.isEmpty) {
      throw StateError('Kimlik doğrulaması bulunamadı.');
    }

    final uri = Uri.parse('$_baseUrl/api/sync/push');
    final payload = {
      'items': jobs.map(_jobToWire).toList(),
      'client_time': DateTime.now().toUtc().toIso8601String(),
    };

    final response = await _httpClient.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(payload),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Push başarısız: HTTP ${response.statusCode}');
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final completedIds = (decoded['completed_ids'] as List? ?? const [])
        .whereType<num>()
        .map((id) => id.toInt())
        .toSet();

    final failedByIdRaw =
        (decoded['failed_by_id'] as Map?)?.cast<String, dynamic>() ?? {};
    final failedById = <int, String>{};
    for (final entry in failedByIdRaw.entries) {
      final id = int.tryParse(entry.key);
      if (id == null) continue;
      failedById[id] = entry.value?.toString() ?? 'Bilinmeyen push hatası';
    }

    return SyncPushResult(
      completedIds: completedIds,
      failedById: failedById,
    );
  }

  Map<String, dynamic> _jobToWire(SyncJob job) {
    return {
      'id': job.id,
      'entity_type': job.entityType,
      'entity_id': job.entityId,
      'operation': job.operation,
      'payload': _safeDecodePayload(job.payloadJson),
      'updated_at': job.updatedAt.toUtc().toIso8601String(),
      'attempt_count': job.attemptCount,
    };
  }

  Object _safeDecodePayload(String payloadJson) {
    try {
      return jsonDecode(payloadJson);
    } catch (_) {
      return {'_raw': payloadJson};
    }
  }

  // ── Pull ──────────────────────────────────────────────────────────────

  /// Sunucudan [since] zamanından sonra güncellenen kayıtları çeker.
  /// [since] null ise tüm kayıtlar döner.
  Future<SyncPullResult> pullChanges({DateTime? since}) async {
    final token = await _authTokenProvider();
    if (token == null || token.isEmpty) {
      throw StateError('Kimlik doğrulaması bulunamadı.');
    }

    final queryParams = <String, String>{};
    if (since != null) {
      queryParams['since'] = since.toUtc().toIso8601String();
    }

    final uri = Uri.parse('$_baseUrl/api/sync/pull')
        .replace(queryParameters: queryParams.isNotEmpty ? queryParams : null);

    final response = await _httpClient.get(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
      },
    ).timeout(const Duration(seconds: 15));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Pull başarısız: HTTP ${response.statusCode}');
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final rawItems = decoded['items'] as List? ?? const [];
    final items = rawItems
        .whereType<Map<String, dynamic>>()
        .map(SyncPullItem.fromJson)
        .toList();

    DateTime? serverTime;
    final serverTimeStr = decoded['server_time']?.toString();
    if (serverTimeStr != null && serverTimeStr.isNotEmpty) {
      serverTime = DateTime.tryParse(serverTimeStr)?.toUtc();
    }

    return SyncPullResult(items: items, serverTime: serverTime);
  }
}

