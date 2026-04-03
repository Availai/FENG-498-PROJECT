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
