import '../data/app_database.dart';
import 'repositories/sync_repository.dart';

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

class SyncService {
  SyncService({required SyncRepository syncRepository})
      : _syncRepository = syncRepository;

  final SyncRepository _syncRepository;

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
}
