import 'package:flutter/foundation.dart';
import 'package:workmanager/workmanager.dart';

import 'package:geolocator/geolocator.dart';

import 'notification_service.dart';

/// Background görev anahtarları.
class BackgroundTasks {
  static const String periodicWeatherCheck = 'periodic_weather_check';
  static const String periodicSyncFlush = 'periodic_sync_flush';
}

/// WorkManager üst soyutlaması.
///
/// Android'de gerçek periyodik görevleri çalıştırır; iOS/Windows/diğer
/// platformlarda sessizce no-op davranır (offline-first foreground sync hâlâ
/// çalışmaya devam eder).
class BackgroundSyncService {
  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) return;
    if (!_isAndroid) return;
    try {
      await Workmanager().initialize(backgroundDispatcher);

      // Periyodik hava kontrolü — her ~3 saatte bir.
      await Workmanager().registerPeriodicTask(
        BackgroundTasks.periodicWeatherCheck,
        BackgroundTasks.periodicWeatherCheck,
        frequency: const Duration(hours: 3),
        constraints: Constraints(
          networkType: NetworkType.connected,
        ),
        existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
      );

      // Periyodik outbox flush — her ~1 saatte bir.
      await Workmanager().registerPeriodicTask(
        BackgroundTasks.periodicSyncFlush,
        BackgroundTasks.periodicSyncFlush,
        frequency: const Duration(hours: 1),
        constraints: Constraints(
          networkType: NetworkType.connected,
        ),
        existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
      );

      _initialized = true;
    } catch (e) {
      // WorkManager kayıt hatası uygulamayı çökmemeli — sessiz fallback.
      debugPrint('BackgroundSyncService init failed: $e');
    }
  }

  static bool get _isAndroid {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.android;
  }
}

/// WorkManager dispatcher — top-level fonksiyon olmak zorunda.
@pragma('vm:entry-point')
void backgroundDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      switch (task) {
        case BackgroundTasks.periodicWeatherCheck:
          try {
            final pos = await Geolocator.getLastKnownPosition() ??
                await Geolocator.getCurrentPosition(
                  desiredAccuracy: LocationAccuracy.low,
                  timeLimit: const Duration(seconds: 20),
                );
            await NotificationService.initialize();
            await NotificationService.checkWeatherAndAlert(
                pos.latitude, pos.longitude);
          } catch (e) {
            debugPrint('Weather check skipped: $e');
          }
          return true;
        case BackgroundTasks.periodicSyncFlush:
          // Sync flush için gerçek tetikleme uygulama foreground açıldığında
          // SyncService tarafından yapılır. Background dispatcher yalnızca bir
          // bildirim noktası olarak yer tutar; gerçek I/O Drift+HTTP gerektirir
          // ve isolate açılışında ayrı init şart koşar. Bu yer tutucu, ileride
          // headless sync isolate'ı için imza sağlar.
          return true;
        default:
          return true;
      }
    } catch (e) {
      debugPrint('Background task $task failed: $e');
      return false;
    }
  });
}
