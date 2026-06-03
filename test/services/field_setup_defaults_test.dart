import 'package:flutter_test/flutter_test.dart';

import 'package:feng_498/data/app_database.dart';
import 'package:feng_498/data/crop_protocols.dart';
import 'package:feng_498/services/field_setup_defaults.dart';

/// FieldSetupDefaults — tarladan toprak türü + sulama yöntemi türetici.
/// CLAUDE.md §6 (mevcut veriyi yeniden kullan, uydurma yok) + §29.
void main() {
  group('mapTexture — lab doku → SoilType', () {
    test('kumlu → sandy', () {
      expect(FieldSetupDefaultsBuilder.mapTexture('Kumlu'), SoilType.sandy);
    });
    test('tınlı → loamy', () {
      expect(FieldSetupDefaultsBuilder.mapTexture('Tınlı'), SoilType.loamy);
    });
    test('killi varyantları → clay', () {
      expect(FieldSetupDefaultsBuilder.mapTexture('Killi'), SoilType.clay);
      expect(
          FieldSetupDefaultsBuilder.mapTexture('Killi-Tınlı'), SoilType.clay);
      expect(FieldSetupDefaultsBuilder.mapTexture('Ağır Killi'), SoilType.clay);
    });
    test('null/boş/bilinmeyen → null (uydurma yok)', () {
      expect(FieldSetupDefaultsBuilder.mapTexture(null), isNull);
      expect(FieldSetupDefaultsBuilder.mapTexture(''), isNull);
      expect(FieldSetupDefaultsBuilder.mapTexture('Mermer'), isNull);
    });
  });

  group('mapIrrigation — metadata anahtarı → IrrigationMethod', () {
    test('bilinen yöntemler', () {
      expect(FieldSetupDefaultsBuilder.mapIrrigation('drip'),
          IrrigationMethod.drip);
      expect(FieldSetupDefaultsBuilder.mapIrrigation('furrow'),
          IrrigationMethod.furrow);
      expect(FieldSetupDefaultsBuilder.mapIrrigation('sprinkler'),
          IrrigationMethod.sprinkler);
      expect(FieldSetupDefaultsBuilder.mapIrrigation('hand'),
          IrrigationMethod.hand);
    });
    test('null/bilinmeyen → null', () {
      expect(FieldSetupDefaultsBuilder.mapIrrigation(null), isNull);
      expect(FieldSetupDefaultsBuilder.mapIrrigation('hortum'), isNull);
    });
  });

  group('build — aktivite log türetme', () {
    test('boş veri → hiçbir öneri yok', () {
      final r = FieldSetupDefaultsBuilder.build(
        soilTests: const <SoilTest>[],
        activityLog: const [],
      );
      expect(r.hasAny, isFalse);
      expect(r.soilType, isNull);
      expect(r.irrigationMethod, isNull);
      expect(r.irrigationSource, FieldDefaultSource.none);
    });

    test('son (ilk) sulama yöntemi seçilir; kaynak activity işaretlenir', () {
      final r = FieldSetupDefaultsBuilder.build(
        soilTests: const <SoilTest>[],
        activityLog: [
          {
            'type': 'watering',
            'metadata': {'irrigation_method': 'drip'},
          },
          {
            'type': 'watering',
            'metadata': {'irrigation_method': 'furrow'},
          },
        ],
      );
      // Liste yeni → eski; ilk eşleşen (drip) seçilir.
      expect(r.irrigationMethod, IrrigationMethod.drip);
      expect(r.irrigationSource, FieldDefaultSource.activity);
    });

    test('application_method anahtarı da okunur', () {
      final r = FieldSetupDefaultsBuilder.build(
        soilTests: const <SoilTest>[],
        activityLog: [
          {
            'type': 'planting',
            'metadata': {'application_method': 'sprinkler'},
          },
        ],
      );
      expect(r.irrigationMethod, IrrigationMethod.sprinkler);
    });

    test('metadata yöntem içermiyorsa öneri üretilmez', () {
      final r = FieldSetupDefaultsBuilder.build(
        soilTests: const <SoilTest>[],
        activityLog: [
          {
            'type': 'fertilizing',
            'metadata': {'fertilizer_name': 'DAP'},
          },
        ],
      );
      expect(r.irrigationMethod, isNull);
    });
  });
}
