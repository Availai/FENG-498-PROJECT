import 'package:flutter_test/flutter_test.dart';

import 'package:feng_498/services/fao_eto_service.dart';

void main() {
  group('FaoEtoService', () {
    test('Penman-Monteith sicak ve kuru gunde gercekci ETo uretir', () {
      final input = EToInput(
        tMaxC: 34,
        tMinC: 18,
        rhMaxPct: 65,
        rhMinPct: 25,
        windMs: 2.2,
        solarRadMjM2Day: 27,
        elevationM: 900,
        latitudeDeg: 39.9,
        dayOfYear: 196,
      );

      final eto = FaoEtoService.calculateDailyEto(input);

      expect(eto, inInclusiveRange(5.0, 9.0));
    });

    test('gecersiz radyasyon negatif sulama ihtiyaci uretmez', () {
      final eto = FaoEtoService.calculateDailyEto(
        const EToInput(
          tMaxC: 4,
          tMinC: 3,
          rhMaxPct: 100,
          rhMinPct: 100,
          windMs: 0,
          solarRadMjM2Day: -20,
          elevationM: 0,
          latitudeDeg: 40,
          dayOfYear: 20,
        ),
      );

      expect(eto, 0);
    });

    test('yaz radyasyonu kis radyasyonundan yuksektir', () {
      final summer = FaoEtoService.estimateSolarRad(
        tMaxC: 32,
        tMinC: 18,
        latitudeDeg: 39.9,
        dayOfYear: 196,
      );
      final winter = FaoEtoService.estimateSolarRad(
        tMaxC: 8,
        tMinC: 0,
        latitudeDeg: 39.9,
        dayOfYear: 20,
      );

      expect(summer, greaterThan(winter));
      expect(summer, greaterThan(20));
      expect(winter, greaterThan(0));
    });

    test('10 metre ruzgarini 2 metreye FAO katsayisiyla indirir', () {
      final wind2m = FaoEtoService.wind10mTo2m(4);

      expect(wind2m, closeTo(2.99, 0.05));
      expect(wind2m, lessThan(4));
    });

    test('bitki su ihtiyacini Kc ile carpar', () {
      expect(
        FaoEtoService.calculateCropWater(etoMmDay: 6.2, kc: 1.15),
        closeTo(7.13, 0.001),
      );
    });
  });

  group('FaoCropCoefficients', () {
    test('Turkce ve ASCII urun adlarini ayni katsayiya baglar', () {
      final direct = FaoCropCoefficients.lookup('domates');
      final ascii = FaoCropCoefficients.lookup('MISIR');
      final turkish = FaoCropCoefficients.lookup('m\u0131s\u0131r');

      expect(direct, isNotNull);
      expect(ascii, isNotNull);
      expect(turkish, isNotNull);
      expect(ascii!.kcMid, closeTo(turkish!.kcMid, 0.0001));
      expect(FaoCropCoefficients.lookup('bilinmeyen-urun'), isNull);
    });

    test('ekimden gecen orana gore baslangic, orta ve son Kc secer', () {
      final crop = FaoCropCoefficients.lookup('domates')!;
      final now = DateTime.now();

      final init = FaoCropCoefficients.kcForStage(
        crop: crop,
        plantedDate:
            now.subtract(Duration(days: (crop.totalLengthDays * 0.1).round())),
      );
      final mid = FaoCropCoefficients.kcForStage(
        crop: crop,
        plantedDate:
            now.subtract(Duration(days: (crop.totalLengthDays * 0.4).round())),
      );
      final end = FaoCropCoefficients.kcForStage(
        crop: crop,
        plantedDate:
            now.subtract(Duration(days: (crop.totalLengthDays * 0.9).round())),
      );

      expect(init, crop.kcInit);
      expect(mid, crop.kcMid);
      expect(end, crop.kcEnd);
    });
  });
}
