import 'package:flutter_test/flutter_test.dart';

import 'package:feng_498/services/disease_diagnosis_service.dart';

void main() {
  group('StubDiseaseDiagnosisService', () {
    test('AI kapali iken manuel girise yonlendiren bos sonuc dondurur',
        () async {
      final service = const StubDiseaseDiagnosisService();
      final before = DateTime.now();

      final diagnosis = await service.diagnose(
        imagePath: 'offline/photo.webp',
        cropName: 'domates',
        lat: 39.9,
        lng: 32.8,
      );
      final after = DateTime.now();

      expect(diagnosis.diseaseType, isNull);
      expect(diagnosis.confidence, isNull);
      expect(diagnosis.recommendation, isNull);
      expect(diagnosis.source, 'stub');
      expect(diagnosis.diagnosedAt.isBefore(before), isFalse);
      expect(diagnosis.diagnosedAt.isAfter(after), isFalse);
    });
  });
}
