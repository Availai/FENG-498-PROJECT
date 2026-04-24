import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../data/app_database.dart';
import '../data/turkish_crops_repository.dart';
import 'crop_scoring_service.dart';
import 'local_data_repository.dart';
import 'repositories/calendar_repository.dart';
import 'repositories/field_repository.dart';
import 'repositories/history_repository.dart';
import 'repositories/weather_repository.dart';
import 'repositories/sync_repository.dart';
import 'repositories/auth_repository.dart';
import 'sync_service.dart';
import 'task_directive_service.dart';
import 'field_state_service.dart';
import 'growth_engine.dart';
import 'weather_soil_service.dart';
import 'api/sync_api_client.dart';

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  throw UnimplementedError('AppDatabase override edilmedi.');
});

final localDataRepositoryProvider = Provider<LocalDataRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final uid = ref.watch(authStateChangesProvider).valueOrNull?.uid;
  return LocalDataRepository(database: db, currentUid: uid);
});

/// GDD + aktivite delta → CropGrowthStates üreten singleton. Tek bir
/// AppDatabase üstünde çalışır; UI katmanı `watch(cropId)` ile canlı okur.
final growthEngineProvider = Provider<GrowthEngine>((ref) {
  return GrowthEngine(ref.watch(appDatabaseProvider));
});


final settingsBoxProvider = Provider<Box>((ref) {
  return Hive.box('settingsBox');
});

final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(firebaseAuth: ref.watch(firebaseAuthProvider));
});

final authStateChangesProvider = StreamProvider<User?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges();
});

final fieldRepositoryProvider = Provider<FieldRepository>((ref) {
  return FieldRepository(localDataRepository: ref.watch(localDataRepositoryProvider));
});

final calendarRepositoryProvider = Provider<CalendarRepository>((ref) {
  return CalendarRepository(localDataRepository: ref.watch(localDataRepositoryProvider));
});

final weatherRepositoryProvider = Provider<WeatherRepository>((ref) {
  return WeatherRepository(settingsBox: ref.watch(settingsBoxProvider));
});

final syncRepositoryProvider = Provider<SyncRepository>((ref) {
  return SyncRepository(database: ref.watch(appDatabaseProvider));
});

final syncServiceProvider = Provider<SyncService>((ref) {
  return SyncService(
    syncRepository: ref.watch(syncRepositoryProvider),
    database: ref.watch(appDatabaseProvider),
  );
});

final backendBaseUrlProvider = Provider<String>((ref) {
  return dotenv.env['BACKEND_BASE_URL'] ?? 'http://10.0.2.2:8000';
});

final syncApiClientProvider = Provider<SyncApiClient>((ref) {
  return SyncApiClient(
    baseUrl: ref.watch(backendBaseUrlProvider),
    authTokenProvider: () => ref.read(authRepositoryProvider).getIdToken(),
  );
});

final fieldMapsProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  return ref.watch(fieldRepositoryProvider).watchFields();
});

/// Uygulama foreground'a geldiğinde otomatik senkronizasyon çalıştır.
/// Bu provider ilk kez okunduğunda push cycle'ı tetikler.
final foregroundSyncProvider = FutureProvider<void>((ref) async {
  final syncService = ref.read(syncServiceProvider);
  final apiClient = ref.read(syncApiClientProvider);
  await syncService.runForegroundSync(apiClient: apiClient);
});

/// AI analiz + anlık çevre geçmişi için Hive facade repository.
final historyRepositoryProvider = Provider<HistoryRepository>((ref) {
  return HistoryRepository();
});

/// 292 Türk bitkisi SQLite asset singleton'unu Riverpod grafiğine bağlar.
/// Yeni kod .instance yerine bu provider'ı okumalı (singleton backing kalır).
final turkishCropsRepositoryProvider = Provider<TurkishCropsRepository>((ref) {
  return TurkishCropsRepository.instance;
});

/// Hava + toprak pH çevre-verisi servisi (Open-Meteo + SoilGrids).
/// Widget'lar doğrudan http.get kullanmamalı; bu servisi çağırmalı.
final weatherSoilServiceProvider = Provider<WeatherSoilService>((ref) {
  return const WeatherSoilService();
});

/// 292 bitki skorlama döngüsünü background isolate'a taşır.
/// Widget'lar `TurkishCrop.scoreFor`'u döngüde çağırmak yerine bu servisi
/// kullanmalı — UI thread frame drop yaşamaz.
final cropScoringServiceProvider = Provider<CropScoringService>((ref) {
  return CropScoringService(ref.watch(turkishCropsRepositoryProvider));
});

/// Tarla bazında son aktiviteleri (sulama/gübre/ilaç/hasat) Drift stream
/// olarak sağlar. Görevler modalı bunu dinler → her log sonrası yönergeler
/// anında tazelenir.
final fieldActivityLogProvider = StreamProvider.family
    .autoDispose<List<Map<String, dynamic>>, String>((ref, fieldId) {
  return ref
      .watch(localDataRepositoryProvider)
      .watchActivityLog(fieldId: fieldId, limit: 200);
});

/// Tarla bazında canlı büyüme durumları. Görev modalı ve harita aynı
/// `CropGrowthStates` kaynağını okur; böylece görsel büyüme ile öneriler ayrışmaz.
final fieldGrowthStatesProvider = StreamProvider.family
    .autoDispose<List<CropGrowthState>, String>((ref, fieldId) {
  return ref.watch(growthEngineProvider).watchForField(fieldId);
});

/// Kural tabanlı "bugün ne yapmalıyım?" yönerge motoru. Saf servis; widget
/// katmanı sadece `generate()` çıktısını render eder.
final taskDirectiveServiceProvider = Provider<TaskDirectiveService>((ref) {
  return const TaskDirectiveService();
});

final fieldStateServiceProvider = Provider<FieldStateService>((ref) {
  return const FieldStateService();
});

/// Dashboard'da tarla başına hızlı yönerge özeti — hava tahmini yüklenmez
/// (o online iştir, detail ekranında çalışır). Burada ekim + aktivite log'u
/// yeter: sulama aralığı doldu mu, hasat zamanı geldi mi, gübre gecikti mi.
/// Aktivite stream'i tazelendikçe FutureProvider otomatik yeniden koşar —
/// "Suladım" dedikten sonra dashboard da anında güncellenir.
final fieldDirectivesSummaryProvider = FutureProvider.family
    .autoDispose<List<FieldDirective>, String>((ref, fieldId) async {
  final repo = ref.watch(localDataRepositoryProvider);
  final activities = await ref.watch(fieldActivityLogProvider(fieldId).future);
  final crops = await repo.loadFieldCrops(fieldId);
  return ref
      .watch(taskDirectiveServiceProvider)
      .generate(fieldCrops: crops, activities: activities);
});

