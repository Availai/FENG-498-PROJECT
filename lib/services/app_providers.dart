import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/app_database.dart';
import 'local_data_repository.dart';
import 'repositories/calendar_repository.dart';
import 'repositories/field_repository.dart';

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  throw UnimplementedError('AppDatabase override edilmedi.');
});

final localDataRepositoryProvider = Provider<LocalDataRepository>((ref) {
  return LocalDataRepository(database: ref.watch(appDatabaseProvider));
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
