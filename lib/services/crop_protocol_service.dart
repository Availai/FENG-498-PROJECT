import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';

import '../data/crop_protocols.dart';
import 'notification_service.dart';

/// Bir bitkinin protokol içindeki anlık durumu.
class CropProtocolProgress {
  final CropProtocol protocol;
  final CropConfig? config;
  final Set<int> completedOrders;
  final ProtocolStep? activeStep;
  final List<ProtocolStep> upcomingSteps;

  const CropProtocolProgress({
    required this.protocol,
    required this.config,
    required this.completedOrders,
    required this.activeStep,
    required this.upcomingSteps,
  });

  int get completedCount => completedOrders.length;
  int get totalCount => protocol.steps.length;
  double get ratio => totalCount == 0 ? 0 : completedCount / totalCount;
  bool get isFinished => activeStep == null && upcomingSteps.isEmpty;
}

/// 3 vitrin bitki için yetiştirme yol haritası servisi.
///
/// Sorumluluklar:
///   1. [computeProgress] — ekim tarihi + aktivite + konfigürasyona göre
///      hangi adım aktif, tamam, geliyor.
///   2. [checkAndNotifyStepAdvanced] — yeni adım açılınca bildirim + Hive persist.
///   3. [saveConfig] / [loadConfig] — çiftçi konfigürasyonunu sakla/yükle.
class CropProtocolService {
  static const _hiveBoxName = 'crop_protocol_state';
  static const _sep = '::';

  static String _stateKey(String fieldId, String cropId, String protocolKey) =>
      '$fieldId$_sep$cropId$_sep$protocolKey';

  static String _configKey(String fieldId, String cropName) =>
      '$fieldId${_sep}cfg$_sep$cropName';

  static int _notifId(String fieldId, String cropId, int order) {
    final hash = '$fieldId|$cropId|$order'.hashCode;
    return 5000000 + (hash.abs() % 1000000);
  }

  static Future<void> initialize() async {
    if (!Hive.isBoxOpen(_hiveBoxName)) {
      await Hive.openBox(_hiveBoxName);
    }
  }

  // ─── Config persistence ────────────────────────────────────────────

  static Future<void> saveConfig({
    required String fieldId,
    required String cropName,
    required CropConfig config,
  }) async {
    final box = Hive.box(_hiveBoxName);
    await box.put(_configKey(fieldId, cropName), jsonEncode(config.toJson()));
  }

  static CropConfig? loadConfig({
    required String fieldId,
    required String cropName,
  }) {
    if (!Hive.isBoxOpen(_hiveBoxName)) return null;
    final box = Hive.box(_hiveBoxName);
    final raw = box.get(_configKey(fieldId, cropName));
    if (raw == null) return null;
    try {
      return CropConfig.fromJson(
          jsonDecode(raw as String) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  // ─── Progress computation ──────────────────────────────────────────

  static DateTime? _parsePlantedDate(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    final parts = raw.split('.');
    if (parts.length == 3) {
      final iso =
          '${parts[2]}-${parts[1].padLeft(2, '0')}-${parts[0].padLeft(2, '0')}';
      final dt = DateTime.tryParse(iso);
      if (dt != null) return dt;
    }
    return DateTime.tryParse(raw);
  }

  /// Bitkinin anlık protokol durumunu hesaplar.
  static CropProtocolProgress? computeProgress({
    required Map<String, dynamic> crop,
    required List<Map<String, dynamic>> activities,
    String? fieldId,
    DateTime? now,
  }) {
    final protocol = CropProtocols.resolveByName(crop['name']?.toString());
    if (protocol == null) return null;

    final t = now ?? DateTime.now();
    final planted = _parsePlantedDate(crop['planted_date']?.toString());
    if (planted == null) return null;

    final daysSincePlanting = t.difference(planted).inDays;
    final cropId = crop['id']?.toString();

    // Config yükle (fieldId varsa)
    CropConfig? config;
    if (fieldId != null && cropId != null) {
      config = loadConfig(
          fieldId: fieldId, cropName: crop['name']?.toString() ?? '');
    }

    final relevantActs = activities.where((a) {
      final fid = a['crop_id']?.toString();
      final actDate = a['date'];
      if (actDate is! DateTime) return false;
      if (actDate.isBefore(planted.subtract(const Duration(days: 1))))
        return false;
      return fid == null || fid.isEmpty || fid == cropId;
    }).toList();

    final completed = <int>{};
    ProtocolStep? active;
    final upcoming = <ProtocolStep>[];

    for (final step in protocol.steps) {
      final stepOpen = daysSincePlanting >= step.dayOffset;

      if (!stepOpen) {
        upcoming.add(step);
        continue;
      }

      bool isCompleted;
      if (step.expectedActivity == null) {
        final nextOffset = _nextOffset(protocol, step.order);
        isCompleted = nextOffset != null && daysSincePlanting >= nextOffset;
      } else {
        isCompleted = relevantActs.any(
          (a) => a['type']?.toString() == step.expectedActivity,
        );
      }

      if (isCompleted) {
        completed.add(step.order);
      } else {
        active ??= step;
      }
    }

    return CropProtocolProgress(
      protocol: protocol,
      config: config,
      completedOrders: completed,
      activeStep: active,
      upcomingSteps: upcoming,
    );
  }

  static int? _nextOffset(CropProtocol p, int currentOrder) {
    for (final s in p.steps) {
      if (s.order > currentOrder) return s.dayOffset;
    }
    return null;
  }

  // ─── Bildirim motoru ───────────────────────────────────────────────

  /// Aktif adım son bildirimden farklıysa lokal bildirim atar, Hive'a yazar.
  static Future<void> checkAndNotifyStepAdvanced({
    required String fieldId,
    required Map<String, dynamic> crop,
    required List<Map<String, dynamic>> activities,
    DateTime? now,
  }) async {
    final progress = computeProgress(
      crop: crop,
      activities: activities,
      fieldId: fieldId,
      now: now,
    );
    if (progress == null) return;
    final cropId = crop['id']?.toString();
    if (cropId == null || cropId.isEmpty) return;

    final box = Hive.box(_hiveBoxName);
    final key = _stateKey(fieldId, cropId, progress.protocol.cropKey);
    final lastNotifiedOrder = (box.get(key) as int?) ?? 0;

    if (progress.isFinished) {
      if (lastNotifiedOrder != -1) {
        await NotificationService.show(
          id: _notifId(fieldId, cropId, 999),
          title:
              '${progress.protocol.emoji} ${progress.protocol.displayName} — Yetiştirme tamamlandı!',
          body: 'Tüm adımlar tamamlandı. Hasadın bereketli olsun.',
        );
        await box.put(key, -1);
      }
      return;
    }

    final activeOrder = progress.activeStep?.order ?? 0;
    if (activeOrder > lastNotifiedOrder) {
      final step = progress.activeStep!;
      await NotificationService.show(
        id: _notifId(fieldId, cropId, activeOrder),
        title: '${progress.protocol.emoji} ${progress.protocol.displayName} — '
            'Adım ${step.order}/${progress.totalCount}: ${step.stageEmoji}',
        body: '${step.title}. Detay için Görevler sekmesine bakın.',
      );
      await box.put(key, activeOrder);
    }
  }

  /// Bitki silindiğinde state + config temizliği.
  static Future<void> clearStateFor({
    required String fieldId,
    required String cropId,
    String? cropName,
  }) async {
    if (!Hive.isBoxOpen(_hiveBoxName)) return;
    final box = Hive.box(_hiveBoxName);
    final prefix = '$fieldId$_sep$cropId$_sep';
    final toRemove =
        box.keys.where((k) => k.toString().startsWith(prefix)).toList();
    for (final k in toRemove) {
      await box.delete(k);
    }
    if (cropName != null) {
      await box.delete(_configKey(fieldId, cropName));
    }
  }
}
