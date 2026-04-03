import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/app_database.dart';
import 'local_data_repository.dart';
import 'repositories/calendar_repository.dart';
import 'repositories/field_repository.dart';
import 'repositories/auth_repository.dart';

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  throw UnimplementedError('AppDatabase override edilmedi.');
});

final localDataRepositoryProvider = Provider<LocalDataRepository>((ref) {
  return LocalDataRepository(database: ref.watch(appDatabaseProvider));
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

final fieldMapsProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  return ref.watch(fieldRepositoryProvider).watchFields();
});
