import 'package:flutter_test/flutter_test.dart';

import 'package:feng_498/services/crop_rotation_advisor.dart';

void main() {
  group('CropRotationAdvisor', () {
    test('uc yil tahil monokulturu baklagil ve alternatif onerir', () {
      final advice = CropRotationAdvisor.analyze(
        history: const ['arpa', 'yulaf', 'tritikale'],
      );

      expect(advice, hasLength(1));
      expect(advice.single.severity, 'warning');
      expect(advice.single.suggestedCrops, contains('nohut'));
    });

    test('patlicangiller ardışık ekimini uyarir ve ham adlari mesajda korur',
        () {
      final advice = CropRotationAdvisor.analyze(
        history: const ['Domates'],
        next: 'Biber',
      );

      expect(advice, hasLength(1));
      expect(advice.single.title, contains('Tekrar'));
      expect(advice.single.message, contains('Domates'));
      expect(advice.single.message, contains('Biber'));
    });

    test('aycicegi kendini izlerse kritik munavebe uyarisi verir', () {
      const sunflower = 'ay\u00e7i\u00e7e\u011fi';

      final advice = CropRotationAdvisor.analyze(
        history: const [sunflower],
        next: sunflower,
      );

      expect(advice, hasLength(1));
      expect(advice.single.severity, 'critical');
      expect(advice.single.suggestedCrops, contains('nohut'));
    });

    test('ASCII tahil adlarini da Turkce adlar gibi eslestirir', () {
      final advice = CropRotationAdvisor.analyze(
        history: const ['bugday', 'misir', 'cavdar'],
      );

      expect(advice.single.title, contains('Monok'));
    });

    test('familya riski olmayan rotasyonda bos liste dondurur', () {
      final advice = CropRotationAdvisor.analyze(
        history: const ['domates', 'bugday', 'nohut'],
        next: 'arpa',
      );

      expect(advice, isEmpty);
    });
  });
}
