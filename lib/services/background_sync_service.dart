import 'package:flutter/foundation.dart';
import 'package:workmanager/workmanager.dart';

import 'package:geolocator/geolocator.dart';

import 'notification_service.dart';
import '../data/app_database.dart';
import 'repositories/sync_repository.dart';
import 'sync_service.dart';
import 'api/sync_api_client.dart';

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
            await NotificationService.initialize();

            // Kayıtlı tüm tarlaları tara — her birinin koordinatına göre uyarı.
            final db = AppDatabase();
            try {
              final fields = await (db.select(db.fields)
                    ..where((f) => f.deletedAt.isNull()))
                  .get();

              if (fields.isEmpty) {
                // Hiç kayıtlı tarla yoksa cihazın mevcut konumuna düş.
                final pos = await Geolocator.getLastKnownPosition() ??
                    await Geolocator.getCurrentPosition(
                      desiredAccuracy: LocationAccuracy.low,
                      timeLimit: const Duration(seconds: 20),
                    );
                await NotificationService.checkWeatherAndAlert(
                    pos.latitude, pos.longitude);
              } else {
                int seed = 0;
                for (final f in fields) {
                  if (f.latitude == null || f.longitude == null) continue;
                  await NotificationService.checkWeatherAndAlert(
                    f.latitude!,
                    f.longitude!,
                    fieldName: f.name,
                    // Her tarlaya benzersiz id seed'i ver — bildirimler birbirini ezmesin.
                    notificationIdSeed: seed,
                  );
                  seed += 100;
                }
              }
            } finally {
              await db.close();
            }
          } catch (e) {
            debugPrint('Weather check skipped: $e');
          }
          return true;
        case BackgroundTasks.periodicSyncFlush:
          // Headless isolate'da sync flush: Drift DB'yi ayrı aç,
          // push cycle'ı çalıştır, kapat.
          try {
            final db = AppDatabase();
            final syncRepo = SyncRepository(database: db);
            final syncService = SyncService(syncRepository: syncRepo);
            final apiClient = SyncApiClient(
              baseUrl: 'http://10.0.2.2:8000', // Emulator localhost
              authTokenProvider: () async => null, // Background'da token yok — best-effort
            );

            // Token olmadan push başarısız olur ama job'lar pending kalır.
            // Foreground'da tekrar denenir.
            final online = await SyncService.hasNetwork();
            if (online) {
              await syncService.runForegroundSync(apiClient: apiClient);
            }
            await db.close();
          } catch (e) {
            debugPrint('Sync flush skipped: $e');
          }
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

