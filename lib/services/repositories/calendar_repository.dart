import '../local_data_repository.dart';

class CalendarRepository {
  CalendarRepository({required LocalDataRepository localDataRepository})
      : _localDataRepository = localDataRepository;

  final LocalDataRepository _localDataRepository;

  Future<List<Map<String, dynamic>>> loadCalendarEntries() {
    return _localDataRepository.loadCalendarEntries();
  }

  Future<void> addEvent({
    required String title,
    required String eventType,
    required DateTime eventDate,
  }) {
    return _localDataRepository.addCalendarEvent(
      title: title,
      eventType: eventType,
      eventDate: eventDate,
    );
  }
}
