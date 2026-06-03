import 'package:flutter_test/flutter_test.dart';

import 'package:feng_498/services/cost_service.dart';
import 'package:feng_498/services/price_book.dart';

/// CostService — saf, deterministik ürün bazlı maliyet motoru.
void main() {
  PriceBook pb() => PriceBook(
        fertilizerPerKg: const {
          'dap': 50,
          'ure': 40,
          'npk': 30,
          'amonyum': 20,
          'can': 25,
        },
        seedPerKg: 100,
        laborPerDay: 1000,
        cropSalePerKg: const {'misir': 10, 'aycicegi': 20},
        dieselPerL: 30,
        gasolinePerL: 35,
        updatedAt: DateTime(2026, 1, 1),
        fuelFromLive: false,
      );

  ManualCost manual(String? cropId, String kind, double amount) => ManualCost(
        id: '$kind-${cropId ?? 'shared'}-$amount',
        cropId: cropId,
        kind: kind,
        amountTry: amount,
        date: DateTime(2026, 1, 1),
      );

  group('Fiyat defteri — gübre adı eşleme', () {
    test('bilinen tipler doğru fiyata eşlenir', () {
      final p = pb();
      expect(p.fertilizerForName('DAP (18-46-0)'), 50);
      expect(p.fertilizerForName('Üre (%46 N)'), 40);
      expect(p.fertilizerForName('NPK 15-15-15'), 30);
      expect(p.fertilizerForName('Amonyum Sülfat'), 20);
    });

    test('bilinmeyen ad → genel ortalama', () {
      final p = pb();
      // (50+40+30+20+25)/5 = 33
      expect(p.fertilizerForName('Bilinmeyen Gübre'), closeTo(33, 0.01));
      expect(p.fertilizerForName(null), closeTo(33, 0.01));
    });

    test('ürün satış fiyatı normalize + kısmi eşleşme', () {
      final p = pb();
      expect(p.saleForCrop('Mısır'), 10);
      expect(p.saleForCrop('Ayçiçeği (yağlık)'), 20);
      expect(p.saleForCrop('Bilinmeyen'), 0);
    });
  });

  group('Otomatik gübre gideri (veritabanı aktivitesi)', () {
    test('kg × fiyat doğru hesaplanır ve ürüne atfedilir', () {
      final report = CostService.build(
        crops: const [CostCrop(id: 'c1', name: 'Buğday')],
        activities: const [
          CostActivity(
              type: 'fertilizing',
              cropId: 'c1',
              fertilizerKg: 20,
              fertilizerName: 'Üre'),
        ],
        manualEntries: const [],
        prices: pb(),
      );
      expect(report.crops.length, 1);
      final c = report.crops.first;
      expect(c.total, 20 * 40); // 800
      expect(c.items.length, 1);
      expect(c.items.first.kind, CostKinds.fertilizer);
      expect(c.items.first.source, CostSource.auto);
    });

    test('gübreleme dışı aktiviteler maliyete katılmaz', () {
      final report = CostService.build(
        crops: const [CostCrop(id: 'c1', name: 'Buğday')],
        activities: const [
          CostActivity(type: 'watering', cropId: 'c1', fertilizerKg: null),
          CostActivity(type: 'harvest', cropId: 'c1', fertilizerKg: null),
        ],
        manualEntries: const [],
        prices: pb(),
      );
      expect(report.grandTotal, 0);
    });
  });

  group('Ürün bazlı gruplama + manuel giderler', () {
    test('iki ürün ayrı toplanır; manuel + otomatik birleşir', () {
      final report = CostService.build(
        crops: const [
          CostCrop(id: 'c1', name: 'Buğday'),
          CostCrop(id: 'c2', name: 'Mısır'),
        ],
        activities: const [
          CostActivity(
              type: 'fertilizing',
              cropId: 'c1',
              fertilizerKg: 10,
              fertilizerName: 'DAP'), // 10*50 = 500
        ],
        manualEntries: [
          manual('c1', CostKinds.fuel, 200),
          manual('c2', CostKinds.seed, 300),
        ],
        prices: pb(),
      );
      final c1 = report.crops.firstWhere((c) => c.cropId == 'c1');
      final c2 = report.crops.firstWhere((c) => c.cropId == 'c2');
      expect(c1.total, 500 + 200);
      expect(c2.total, 300);
      expect(report.grandTotal, 1000);
      expect(report.byCategory[CostKinds.fertilizer], 500);
      expect(report.byCategory[CostKinds.fuel], 200);
      expect(report.byCategory[CostKinds.seed], 300);
    });

    test('cropId null → tarla geneli (shared) kovasına', () {
      final report = CostService.build(
        crops: const [CostCrop(id: 'c1', name: 'Buğday')],
        activities: const [],
        manualEntries: [manual(null, CostKinds.other, 150)],
        prices: pb(),
      );
      expect(report.shared, isNotNull);
      expect(report.shared!.total, 150);
      expect(report.crops.first.total, 0);
      expect(report.grandTotal, 150);
    });
  });

  group('Kâr tahmini', () {
    test('alan + satış fiyatı varsa rekolte/gelir/kâr hesaplanır', () {
      final report = CostService.build(
        crops: const [CostCrop(id: 'c1', name: 'Mısır', areaDekar: 5)],
        activities: const [
          CostActivity(
              type: 'fertilizing',
              cropId: 'c1',
              fertilizerKg: 10,
              fertilizerName: 'Üre'), // 10*40 = 400
        ],
        manualEntries: const [],
        prices: pb(),
      );
      final c = report.crops.first;
      // Mısır ideal 800 kg/da × 5 da × (1×1×1) = 4000 kg.
      expect(c.estimatedYieldKg, closeTo(4000, 0.5));
      expect(c.estimatedRevenue, closeTo(40000, 1)); // 4000 × 10
      expect(c.estimatedProfit, closeTo(40000 - 400, 1));
    });

    test('alan yoksa kâr atlanır (yalnız gider)', () {
      final report = CostService.build(
        crops: const [CostCrop(id: 'c1', name: 'Mısır')],
        activities: const [],
        manualEntries: [manual('c1', CostKinds.fuel, 100)],
        prices: pb(),
      );
      expect(report.crops.first.estimatedProfit, isNull);
      expect(report.crops.first.total, 100);
    });
  });

  group('Determinizm', () {
    test('aynı girdi iki kez → aynı çıktı', () {
      final crops = const [
        CostCrop(id: 'c1', name: 'Mısır', areaDekar: 3),
        CostCrop(id: 'c2', name: 'Buğday', areaDekar: 2),
      ];
      final acts = const [
        CostActivity(
            type: 'fertilizing',
            cropId: 'c1',
            fertilizerKg: 12,
            fertilizerName: 'NPK'),
      ];
      final man = [manual('c2', CostKinds.labor, 750)];
      final a = CostService.build(
          crops: crops, activities: acts, manualEntries: man, prices: pb());
      final b = CostService.build(
          crops: crops, activities: acts, manualEntries: man, prices: pb());
      expect(a.grandTotal, b.grandTotal);
      expect(a.crops.length, b.crops.length);
      for (var i = 0; i < a.crops.length; i++) {
        expect(a.crops[i].total, b.crops[i].total);
        expect(a.crops[i].estimatedProfit, b.crops[i].estimatedProfit);
      }
    });
  });
}
