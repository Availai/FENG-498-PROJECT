import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../data/app_database.dart';
import 'local_data_repository.dart';
import 'repositories/calendar_repository.dart';
import 'repositories/field_repository.dart';
import 'repositories/weather_repository.dart';
import 'repositories/sync_repository.dart';
import 'repositories/auth_repository.dart';
import 'sync_service.dart';
import 'api/sync_api_client.dart';

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  throw UnimplementedError('AppDatabase override edilmedi.');
});

final localDataRepositoryProvider = Provider<LocalDataRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final uid = ref.watch(authStateChangesProvider).valueOrNull?.uid;
  return LocalDataRepository(database: db, currentUid: uid);
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

