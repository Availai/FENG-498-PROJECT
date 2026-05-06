import 'package:flutter_test/flutter_test.dart';

import 'package:feng_498/services/yield_calculation_service.dart';

void main() {
  group('YieldCalculationService', () {
    test('ideal kosulda teorik rekolteyi ve net kari korur', () {
      final result = YieldCalculationService().hesapla(
        bitkiTuru: 'domates',
        dekar: 2,
        haftalikSuIhtiyaciMm: 30,
        haftalikVerilenSuMm: 30,
        maksSicaklikLimitC: 34,
        asilanGunSayisi: 0,
        gubreVerildiMi: true,
        satisFiyatiPerKg: 6,
        toplamMasrafTl: 10000,
      );

      expect(result.idealVerimKgDekar, 6000);
      expect(result.teorikMaxRekolte, 12000);
      expect(result.tahminiRekolte, 12000);
      expect(result.tahminiKar, 62000);
      expect(result.basariOrani, 1);
      expect(result.uyarilar, isEmpty);
    });

    test('su, sicaklik ve gubre streslerini bilesik carpanla uygular', () {
      final result = YieldCalculationService().hesapla(
        bitkiTuru: 'arpa',
        dekar: 1,
        haftalikSuIhtiyaciMm: 100,
        haftalikVerilenSuMm: 50,
        maksSicaklikLimitC: 32,
        asilanGunSayisi: 10,
        gubreVerildiMi: false,
        satisFiyatiPerKg: 10,
        toplamMasrafTl: 100,
      );

      expect(result.carpanDetaylari['su'], closeTo(0.75, 0.001));
      expect(result.carpanDetaylari['sicaklik'], closeTo(0.80, 0.001));
      expect(result.carpanDetaylari['gubre'], closeTo(0.80, 0.001));
      expect(result.carpanDetaylari['bilesik'], closeTo(0.48, 0.001));
      expect(result.tahminiRekolte, closeTo(192, 0.001));
      expect(result.tahminiKar, closeTo(1820, 0.001));
      expect(result.uyarilar, hasLength(3));
    });

    test('bilinmeyen urunde varsayilan verim ve zarar uyarisi kullanir', () {
      final result = YieldCalculationService().hesapla(
        bitkiTuru: 'bilinmeyen',
        dekar: 1,
        haftalikSuIhtiyaciMm: 0,
        haftalikVerilenSuMm: 0,
        maksSicaklikLimitC: 30,
        asilanGunSayisi: 0,
        gubreVerildiMi: true,
        satisFiyatiPerKg: 1,
        toplamMasrafTl: 1000,
      );

      expect(result.idealVerimKgDekar, 250);
      expect(result.tahminiKar, -750);
      expect(result.uyarilar.first, contains('bilinmeyen'));
      expect(result.uyarilar.last, contains('Masraflar'));
    });

    test('registerCrop yeni urunu tabloya ekler', () {
      YieldCalculationService.registerCrop('deneme-test-bitkisi', 123);

      final result = YieldCalculationService().hesapla(
        bitkiTuru: 'deneme-test-bitkisi',
        dekar: 2,
        haftalikSuIhtiyaciMm: 10,
        haftalikVerilenSuMm: 10,
        maksSicaklikLimitC: 30,
        asilanGunSayisi: 0,
        gubreVerildiMi: true,
        satisFiyatiPerKg: 1,
        toplamMasrafTl: 0,
      );

      expect(YieldCalculationService.knownCrops(),
          contains('deneme-test-bitkisi'));
      expect(result.idealVerimKgDekar, 123);
      expect(result.tahminiRekolte, 246);
    });
  });
}
