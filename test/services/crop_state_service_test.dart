import 'package:flutter_test/flutter_test.dart';

import 'package:feng_498/services/crop_state_service.dart';

void main() {
  group('CropStateService.modeFor', () {
    test('tek yıllık ürün (domates) annual modunu döndürür', () {
      final mode = CropStateService.modeFor(cropName: 'domates');
      expect(mode, CropLifecycleMode.annual);
    });

    test('mısır ekim/hasat döngüsü annual', () {
      expect(
        CropStateService.modeFor(cropName: 'Mısır'),
        CropLifecycleMode.annual,
      );
    });

    test('çok yıllık + isSeedling=true → perennialSeedling', () {
      final mode = CropStateService.modeFor(
        cropName: 'portakal',
        isSeedling: true,
      );
      expect(mode, CropLifecycleMode.perennialSeedling);
    });

    test('çok yıllık + isSeedling=false → perennialMature', () {
      final mode = CropStateService.modeFor(
        cropName: 'çay',
        isSeedling: false,
      );
      expect(mode, CropLifecycleMode.perennialMature);
    });

    test('isSeedling null + dikim 1 yıl önce → fidan tahmini', () {
      final now = DateTime(2026, 5, 16);
      final planted = now.subtract(const Duration(days: 365));
      final mode = CropStateService.modeFor(
        cropName: 'portakal',
        plantedDate: planted,
        now: now,
      );
      expect(mode, CropLifecycleMode.perennialSeedling);
    });

    test('isSeedling null + dikim 5 yıl önce → olgun tahmini', () {
      final now = DateTime(2026, 5, 16);
      final planted = now.subtract(const Duration(days: 5 * 365));
      final mode = CropStateService.modeFor(
        cropName: 'portakal',
        plantedDate: planted,
        now: now,
      );
      expect(mode, CropLifecycleMode.perennialMature);
    });

    test('isSeedling null + dikim yok → varsayılan olgun', () {
      final mode = CropStateService.modeFor(cropName: 'çay');
      expect(mode, CropLifecycleMode.perennialMature);
    });

    test('Türkçe karakter ve büyük/küçük harf farkı önemli değil', () {
      expect(
        CropStateService.modeFor(cropName: 'AYÇİÇEĞİ'),
        CropLifecycleMode.annual,
      );
      expect(
        CropStateService.modeFor(cropName: 'AyCicegi'),
        CropLifecycleMode.annual,
      );
    });
  });

  group('CropStateService.percentFor', () {
    test('annual: ekimden geçen / hasat günleri × 100', () {
      final now = DateTime(2026, 5, 16);
      final planted = now.subtract(const Duration(days: 60));
      final pct = CropStateService.percentFor(
        cropName: 'domates',
        mode: CropLifecycleMode.annual,
        plantedDate: planted,
        harvestDays: 120,
        now: now,
      );
      expect(pct, closeTo(50.0, 0.5));
    });

    test('annual: harvestDays null → 0', () {
      final pct = CropStateService.percentFor(
        cropName: 'domates',
        mode: CropLifecycleMode.annual,
        plantedDate: DateTime(2026, 1, 1),
        harvestDays: null,
        now: DateTime(2026, 5, 16),
      );
      expect(pct, 0.0);
    });

    test('annual: 100 üstünde clamp edilir', () {
      final now = DateTime(2026, 5, 16);
      final planted = now.subtract(const Duration(days: 1000));
      final pct = CropStateService.percentFor(
        cropName: 'domates',
        mode: CropLifecycleMode.annual,
        plantedDate: planted,
        harvestDays: 90,
        now: now,
      );
      expect(pct, 100.0);
    });

    test('perennialSeedling: portakal 1.5 yıl → ~%50', () {
      final now = DateTime(2026, 5, 16);
      final planted = now.subtract(const Duration(days: 547)); // ≈ 1.5 yıl
      final pct = CropStateService.percentFor(
        cropName: 'portakal',
        mode: CropLifecycleMode.perennialSeedling,
        plantedDate: planted,
        now: now,
      );
      // hedef 1095 gün → 547/1095 ≈ %49.9
      expect(pct, closeTo(50.0, 1.0));
    });

    test('perennialMature: yılbaşı sarmalayan döngü', () {
      // Portakal döngü başı: Şubat (ay 2). Mayıs ortası → ~3.5 ay sonra → küçük %.
      final now = DateTime(2026, 5, 16);
      final pct = CropStateService.percentFor(
        cropName: 'portakal',
        mode: CropLifecycleMode.perennialMature,
        now: now,
      );
      expect(pct, greaterThan(0.0));
      expect(pct, lessThan(100.0));
    });
  });

  group('CropStateService.disclaimerFor', () {
    test('annual disclaimer "tek yıllık" geçer', () {
      final text = CropStateService.disclaimerFor(
        cropName: 'domates',
        mode: CropLifecycleMode.annual,
      );
      expect(text.toLowerCase(), contains('tek yıllık'));
    });

    test('perennialSeedling disclaimer "yeni fidan" geçer', () {
      final now = DateTime(2026, 5, 16);
      final planted = now.subtract(const Duration(days: 200));
      final text = CropStateService.disclaimerFor(
        cropName: 'portakal',
        mode: CropLifecycleMode.perennialSeedling,
        plantedDate: planted,
        now: now,
      );
      expect(text.toLowerCase(), contains('fidan'));
    });

    test('perennialMature disclaimer "olgun" geçer', () {
      final text = CropStateService.disclaimerFor(
        cropName: 'çay',
        mode: CropLifecycleMode.perennialMature,
      );
      expect(text.toLowerCase(), contains('olgun'));
    });

    test('seedling olgunluğa ulaştıysa metin uygun ifade taşır', () {
      final now = DateTime(2026, 5, 16);
      final planted = now.subtract(const Duration(days: 1200));
      final text = CropStateService.disclaimerFor(
        cropName: 'portakal',
        mode: CropLifecycleMode.perennialSeedling,
        plantedDate: planted,
        now: now,
      );
      // hedef 1095 gün, geçen 1200 → ulaştı
      expect(text.toLowerCase(), contains('olgunluğa'));
    });
  });

  group('CropStateService.shouldSuppressHarvestAdvice', () {
    test('annual modda hasat tavsiyesi gizlenmez', () {
      expect(
        CropStateService.shouldSuppressHarvestAdvice(
          mode: CropLifecycleMode.annual,
          plantedDate: DateTime(2026, 1, 1),
        ),
        isFalse,
      );
    });

    test('perennialMature modda hasat tavsiyesi gizlenmez', () {
      expect(
        CropStateService.shouldSuppressHarvestAdvice(
          mode: CropLifecycleMode.perennialMature,
          plantedDate: null,
        ),
        isFalse,
      );
    });

    test('fidan + olgunluğa erişmediyse hasat tavsiyesi gizlenir', () {
      final now = DateTime(2026, 5, 16);
      final planted = now.subtract(const Duration(days: 200));
      expect(
        CropStateService.shouldSuppressHarvestAdvice(
          mode: CropLifecycleMode.perennialSeedling,
          plantedDate: planted,
          cropName: 'portakal',
          now: now,
        ),
        isTrue,
      );
    });

    test('fidan + olgunluğa ulaştıysa hasat tavsiyesi açılır', () {
      final now = DateTime(2026, 5, 16);
      final planted = now.subtract(const Duration(days: 1500));
      expect(
        CropStateService.shouldSuppressHarvestAdvice(
          mode: CropLifecycleMode.perennialSeedling,
          plantedDate: planted,
          cropName: 'portakal',
          now: now,
        ),
        isFalse,
      );
    });
  });
}
