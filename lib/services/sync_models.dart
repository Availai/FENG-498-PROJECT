import '../data/app_database.dart';

class SyncPushResult {
  const SyncPushResult({
    this.completedIds = const <int>{},
    this.failedById = const <int, String>{},
  });

  final Set<int> completedIds;
  final Map<int, String> failedById;
}

class SyncRunReport {
  const SyncRunReport({
    required this.picked,
    required this.completed,
    required this.failed,
  });

  final int picked;
  final int completed;
  final int failed;
}

typedef SyncPushHandler = Future<SyncPushResult> Function(List<SyncJob> jobs);

// ── Pull modelleri ─────────────────────────────────────────────────────

/// Sunucudan çekilen tek bir kayıt.
class SyncPullItem {
  const SyncPullItem({
    required this.entityType,
    required this.entityId,
    required this.operation,
    required this.payload,
    required this.updatedAt,
  });

  final String entityType;
  final String entityId;
  final String operation; // 'upsert' | 'delete'
  final Map<String, dynamic> payload;
  final DateTime updatedAt;

  factory SyncPullItem.fromJson(Map<String, dynamic> json) {
    return SyncPullItem(
      entityType: json['entity_type'] as String? ?? '',
      entityId: json['entity_id'] as String? ?? '',
      operation: json['operation'] as String? ?? 'upsert',
      payload: (json['payload'] is Map)
          ? Map<String, dynamic>.from(json['payload'] as Map)
          : const <String, dynamic>{},
      updatedAt: DateTime.tryParse(json['updated_at']?.toString() ?? '')
              ?.toUtc() ??
          DateTime.now().toUtc(),
    );
  }
}

/// Sunucudan çekme sonucu.
class SyncPullResult {
  const SyncPullResult({
    this.items = const [],
    this.serverTime,
  });

  final List<SyncPullItem> items;
  final DateTime? serverTime;
}

