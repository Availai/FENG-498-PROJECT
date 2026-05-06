import 'package:flutter_test/flutter_test.dart';

import 'package:feng_498/services/irrigation_service.dart';

void main() {
  group('IrrigationDayPlan.fromJson', () {
    test('backend alanlarini Dart modeline dogru cevirir', () {
      final plan = IrrigationDayPlan.fromJson(const {
        'date': '2026-05-06',
        'should_irrigate': true,
        'level': 'critical',
        'title': 'Sulama gerekli',
        'reason': 'Toprak nemi dusuk',
        'recommendation': 'Sabah sulama yap',
        'estimated_mm': 14,
        'eto_mm': 6.2,
        'etc_mm': 7.1,
        'kc': 1.15,
      });

      expect(plan.date, DateTime(2026, 5, 6));
      expect(plan.shouldIrrigate, isTrue);
      expect(plan.level, 'critical');
      expect(plan.estimatedMm, 14);
      expect(plan.etoMm, 6.2);
      expect(plan.etcMm, 7.1);
      expect(plan.kc, 1.15);
    });

    test('eksik opsiyonel alanlarda guvenli varsayilanlari kullanir', () {
      final plan = IrrigationDayPlan.fromJson(const {'date': '2026-05-06'});

      expect(plan.shouldIrrigate, isFalse);
      expect(plan.level, 'ok');
      expect(plan.title, isEmpty);
      expect(plan.estimatedMm, 0);
      expect(plan.kc, 1);
    });
  });
}
