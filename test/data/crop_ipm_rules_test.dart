import 'package:feng_498/data/crop_ipm_rules.dart';
import 'package:feng_498/services/ipm_decision_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Ayçiçeği IPM kararları', () {
    test('bozkurt eşik altı ve üstü kararlarını ayırır', () {
      final below = IpmDecisionService.evaluate(
        const IpmObservationInput(
          cropName: 'Ayçiçeği',
          pestKey: 'bozkurt',
          larvaePerSquareMeter: 0.5,
        ),
      );
      final above = IpmDecisionService.evaluate(
        const IpmObservationInput(
          cropName: 'Ayçiçeği',
          pestKey: 'bozkurt',
          larvaePerSquareMeter: 1,
        ),
      );

      expect(below.allowsChemical, isFalse);
      expect(below.status, IpmDecisionStatus.belowThreshold);
      expect(above.allowsChemical, isTrue);
      expect(above.status, IpmDecisionStatus.chemicalAllowed);
    });

    test('ayçiçeği güvesinde sadece tuzak artışı takip kararı üretir', () {
      final decision = IpmDecisionService.evaluate(
        const IpmObservationInput(
          cropName: 'Ayçiçeği',
          pestKey: 'aycicegi_guvesi',
          trapAverage: 12,
          sampledPlants: 100,
          affectedPlants: 2,
        ),
      );

      expect(decision.allowsChemical, isFalse);
      expect(decision.status, IpmDecisionStatus.followUp);
      expect(decision.message, contains('7-10 gün'));
    });

    test('ayçiçeği güvesinde bitki eşiği kimyasal kapıyı açar', () {
      final decision = IpmDecisionService.evaluate(
        const IpmObservationInput(
          cropName: 'Ayçiçeği',
          pestKey: 'aycicegi_guvesi',
          sampledPlants: 100,
          affectedPlants: 5,
        ),
      );

      expect(decision.allowsChemical, isTrue);
      expect(decision.status, IpmDecisionStatus.chemicalAllowed);
    });

    test('mildiyö yüzde 30 üstünde ilaç değil kritik resmi destek döner', () {
      final decision = IpmDecisionService.evaluate(
        const IpmObservationInput(
          cropName: 'Ayçiçeği',
          pestKey: 'mildiyo',
          diseasePercent: 31,
        ),
      );

      expect(decision.allowsChemical, isFalse);
      expect(decision.status, IpmDecisionStatus.criticalNoChemical);
      expect(decision.message, contains('resmi teknik destek'));
    });
  });
}
