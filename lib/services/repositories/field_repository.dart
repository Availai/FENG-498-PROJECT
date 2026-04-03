import '../local_data_repository.dart';

class FieldRepository {
  FieldRepository({required LocalDataRepository localDataRepository})
      : _localDataRepository = localDataRepository;

  final LocalDataRepository _localDataRepository;

  Stream<List<Map<String, dynamic>>> watchFields() {
    return _localDataRepository.watchFieldMaps();
  }

  Future<String> createManualField({
    required String name,
    double? latitude,
    double? longitude,
  }) {
    return _localDataRepository.createManualField(
      name: name,
      latitude: latitude,
      longitude: longitude,
    );
  }

  Future<void> deleteField(String fieldId) {
    return _localDataRepository.deleteField(fieldId);
  }
}
