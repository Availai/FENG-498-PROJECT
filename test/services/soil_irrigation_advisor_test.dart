import 'package:flutter_test/flutter_test.dart';

import 'package:feng_498/data/crop_protocols.dart' show SoilType;
import 'package:feng_498/services/soil_irrigation_advisor.dart';
import 'package:feng_498/services/soil_test_advisor.dart' show SoilSeverity;

/// SoilIrrigationAdvisor — saf, deterministik toprak→sulama yorumlayıcısı.
/// CLAUDE.md §22 (saf fonksiyon) + §16/§29 (uydurma yok, değer yoksa etki yok).
void main() {
  group('boş girdi → nötr profil (uydurma yok)', () {
    test('hiç değer yoksa nötr döner, davranış değişmez', () {
      final p = SoilIrrigationAdvisor.analyze();
      expect(p.hasInput, isFalse);
      expect(p.intervalFactor, 1.0);
      expect(p.leachingFraction, 0.0);
      expect(p.grossWaterMultiplier, 1.0);
      expect(p.fieldCapacityMultiplier, 1.0);
      expect(p.notes, isEmpty);
      expect(identical(p, SoilIrrigationProfile.neutral), isTrue);
    });
  });

  group('doku → sulama sıklığı (FAO-56)', () {
    test('kumlu (doygunluk 25%) → daha sık (intervalFactor < 1)', () {
      final p = SoilIrrigationAdvisor.analyze(saturationPct: 25);
      expect(p.soilType, SoilType.sandy);
      expect(p.textureLabel, 'Kumlu');
      expect(p.intervalFactor, lessThan(1.0));
      expect(p.notes, isNotEmpty);
    });

    test('killi (doygunluk 80%) → daha seyrek (intervalFactor > 1)', () {
      final p = SoilIrrigationAdvisor.analyze(saturationPct: 80);
      expect(p.soilType, SoilType.clay);
      expect(p.intervalFactor, greaterThan(1.0));
    });

    test('tınlı (doygunluk 40%) → dengeli (intervalFactor = 1)', () {
      final p = SoilIrrigationAdvisor.analyze(saturationPct: 40);
      expect(p.soilType, SoilType.loamy);
      expect(p.intervalFactor, 1.0);
    });

    test('doğrudan girilen doku, doygunluğa öncelikli', () {
      final p = SoilIrrigationAdvisor.analyze(
        textureClass: 'Kumlu',
        saturationPct: 80, // killi sınıfı; ama textureClass öncelikli
      );
      expect(p.soilType, SoilType.sandy);
      expect(p.textureLabel, 'Kumlu');
    });
  });

  group('tuzluluk → yıkama suyu (FAO-29 Ayers & Westcot)', () {
    test('tuzsuz EC (1.0) → yıkama gerekmez', () {
      final p = SoilIrrigationAdvisor.analyze(ecDsM: 1.0);
      expect(p.leachingFraction, 0.0);
      expect(p.grossWaterMultiplier, 1.0);
    });

    test('orta tuzlu EC (5.0) → leaching 0.20, ek su ~%25', () {
      final p = SoilIrrigationAdvisor.analyze(ecDsM: 5.0);
      expect(p.leachingFraction, closeTo(0.20, 1e-9));
      expect(p.grossWaterMultiplier, closeTo(1 / 0.8, 1e-9));
      final note = p.notes.firstWhere((n) => n.title.contains('Tuzluluk'));
      expect(note.severity, SoilSeverity.warning);
    });

    test('kuvvetli tuzlu EC (10.0) → leaching 0.30 + drenaj uyarısı (critical)',
        () {
      final p = SoilIrrigationAdvisor.analyze(ecDsM: 10.0);
      expect(p.leachingFraction, closeTo(0.30, 1e-9));
      expect(
        p.notes.any((n) => n.severity == SoilSeverity.critical),
        isTrue,
      );
    });

    test('EC yoksa % toplam tuz fallback olur', () {
      final p = SoilIrrigationAdvisor.analyze(saltPct: 0.5); // orta tuzlu
      expect(p.leachingFraction, closeTo(0.20, 1e-9));
    });

    test('EC, % tuza göre önceliklidir', () {
      final p = SoilIrrigationAdvisor.analyze(ecDsM: 1.0, saltPct: 0.9);
      expect(p.leachingFraction, 0.0); // EC tuzsuz → yıkama yok
    });
  });

  group('organik madde → su tutma (tarla kapasitesi çarpanı)', () {
    test('çok düşük OM (0.5%) → kapasite çarpanı < 1', () {
      final p = SoilIrrigationAdvisor.analyze(organicMatterPct: 0.5);
      expect(p.fieldCapacityMultiplier, lessThan(1.0));
    });

    test('yüksek OM (5%) → kapasite çarpanı > 1', () {
      final p = SoilIrrigationAdvisor.analyze(organicMatterPct: 5.0);
      expect(p.fieldCapacityMultiplier, greaterThan(1.0));
    });
  });

  test('aynı girdi aynı çıktı (deterministik)', () {
    final a = SoilIrrigationAdvisor.analyze(
        saturationPct: 25, ecDsM: 8, organicMatterPct: 1.2);
    final b = SoilIrrigationAdvisor.analyze(
        saturationPct: 25, ecDsM: 8, organicMatterPct: 1.2);
    expect(a.intervalFactor, b.intervalFactor);
    expect(a.leachingFraction, b.leachingFraction);
    expect(a.grossWaterMultiplier, b.grossWaterMultiplier);
    expect(a.fieldCapacityMultiplier, b.fieldCapacityMultiplier);
    expect(a.notes.length, b.notes.length);
  });

  test('her not bir kaynak etiketi taşır', () {
    final p = SoilIrrigationAdvisor.analyze(
        saturationPct: 25, ecDsM: 8, organicMatterPct: 1.0);
    expect(p.notes, isNotEmpty);
    for (final n in p.notes) {
      expect(n.source.trim(), isNotEmpty);
    }
  });
}
