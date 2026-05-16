import 'package:flutter_test/flutter_test.dart';

import 'package:feng_498/services/crop_general_rules.dart';

void main() {
  group('CropGeneralRules.forCropName', () {
    test('5 ana ürünün hepsi için en az bir genel kural döner', () {
      for (final name in ['domates', 'mısır', 'portakal', 'çay', 'ayçiçeği']) {
        final rules = CropGeneralRules.forCropName(name);
        expect(rules, isNotEmpty,
            reason:
                '$name için genel kural beklenir (suitability/pre_planting/soil_analysis)');
      }
    });

    test('tanınmayan ürün → boş liste', () {
      expect(CropGeneralRules.forCropName('marul'), isEmpty);
    });

    test('yalnız informational kategoriler döner', () {
      final rules = CropGeneralRules.forCropName('domates');
      for (final r in rules) {
        expect(
          CropGeneralRules.informationalCategories.contains(r.category),
          isTrue,
          reason:
              'kural ${r.id} kategorisi (${r.category}) informational olmalı',
        );
      }
    });

    test('disabled kurallar listeye girmez', () {
      final rules = CropGeneralRules.forCropName('domates');
      for (final r in rules) {
        expect(r.enabled, isTrue);
      }
    });
  });

  group('CropGeneralRules.categoryLabel', () {
    test('Türkçe etiketler doğru', () {
      expect(CropGeneralRules.categoryLabel('suitability'), 'Uygunluk');
      expect(CropGeneralRules.categoryLabel('pre_planting'), 'Ekim Öncesi');
      expect(CropGeneralRules.categoryLabel('soil_analysis'), 'Toprak Analizi');
    });

    test('bilinmeyen kategori → ham değer', () {
      expect(CropGeneralRules.categoryLabel('unknown_cat'), 'unknown_cat');
    });
  });
}
