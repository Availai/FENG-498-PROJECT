import 'package:flutter_test/flutter_test.dart';

import 'package:feng_498/services/soil_test_advisor.dart';

/// SoilTestAdvisor — saf, deterministik laboratuvar analizi yorumlayıcısı.
/// CLAUDE.md §16 (gübre güvenlik) + §25 (guardrail testleri).
void main() {
  SoilFinding? byParam(SoilTestAdvice a, String contains) {
    for (final f in a.findings) {
      if (f.parameter.toLowerCase().contains(contains.toLowerCase())) return f;
    }
    return null;
  }

  group('pH sınıflandırması', () {
    test('kuvvetli asit (4.0) → critical + kireçleme aksiyonu', () {
      final a = SoilTestAdvisor.analyze(const SoilTestInput(ph: 4.0));
      final f = byParam(a, 'pH')!;
      expect(f.level, 'Kuvvetli asit');
      expect(f.severity, SoilSeverity.critical);
      expect(f.action, isNotNull);
      expect(f.action!.toLowerCase(), contains('kireci'));
    });

    test('nötr (7.0) → ideal, aksiyon yok', () {
      final a = SoilTestAdvisor.analyze(const SoilTestInput(ph: 7.0));
      final f = byParam(a, 'pH')!;
      expect(f.level, 'Nötr');
      expect(f.severity, SoilSeverity.ideal);
      expect(f.action, isNull);
    });

    test('kuvvetli alkali (9.0) → warning', () {
      final a = SoilTestAdvisor.analyze(const SoilTestInput(ph: 9.0));
      final f = byParam(a, 'pH')!;
      expect(f.level, 'Kuvvetli alkali');
      expect(f.severity, SoilSeverity.warning);
    });

    test('yüksek pH + yüksek kireç → kükürt önerilmez, asitleyici gübre', () {
      final a =
          SoilTestAdvisor.analyze(const SoilTestInput(ph: 8.2, limePct: 30));
      final f = byParam(a, 'pH')!;
      expect(f.action!.toLowerCase(), contains('pratik değildir'));
      expect(f.action!.toLowerCase(), contains('amonyum sülfat'));
    });
  });

  group('Tuzluluk', () {
    test('yüksek % tuz (0.8) → critical + yıkama/drenaj aksiyonu', () {
      final a = SoilTestAdvisor.analyze(const SoilTestInput(saltPct: 0.8));
      final f = byParam(a, 'toplam tuz')!;
      expect(f.severity, SoilSeverity.critical);
      expect(f.action!.toLowerCase(), contains('yıkama'));
      expect(f.action!.toLowerCase(), contains('drenaj'));
    });

    test('yüksek EC (10) → critical', () {
      final a = SoilTestAdvisor.analyze(const SoilTestInput(ecDsM: 10));
      final f = byParam(a, 'EC')!;
      expect(f.severity, SoilSeverity.critical);
    });

    test('hem % tuz hem EC girilirse iki ayrı bulgu üretir', () {
      final a = SoilTestAdvisor.analyze(
          const SoilTestInput(saltPct: 0.2, ecDsM: 1.0));
      expect(byParam(a, 'toplam tuz'), isNotNull);
      expect(byParam(a, 'EC'), isNotNull);
    });
  });

  group('Fosfor / Potasyum', () {
    test('düşük fosfor (2) → warning + taban gübre aksiyonu', () {
      final a = SoilTestAdvisor.analyze(const SoilTestInput(phosphorusKgDa: 2));
      final f = byParam(a, 'Fosfor')!;
      expect(f.severity, SoilSeverity.warning);
      expect(f.action!.toLowerCase(), contains('taban gübre'));
    });

    test('çok yüksek fosfor (15) → warning + "vermeyin"', () {
      final a =
          SoilTestAdvisor.analyze(const SoilTestInput(phosphorusKgDa: 15));
      final f = byParam(a, 'Fosfor')!;
      expect(f.level, 'Çok yüksek');
      expect(f.severity, SoilSeverity.warning);
      expect(f.action!.toLowerCase(), contains('vermeyin'));
    });

    test('düşük potasyum (10) → warning; yeterli (35) → ideal', () {
      final low =
          SoilTestAdvisor.analyze(const SoilTestInput(potassiumKgDa: 10));
      expect(byParam(low, 'Potasyum')!.severity, SoilSeverity.warning);
      final ok =
          SoilTestAdvisor.analyze(const SoilTestInput(potassiumKgDa: 35));
      expect(byParam(ok, 'Potasyum')!.level, 'Yeterli');
      expect(byParam(ok, 'Potasyum')!.severity, SoilSeverity.ideal);
    });
  });

  group('Organik madde', () {
    test('çok az (0.8) → warning + organik girdi aksiyonu', () {
      final a =
          SoilTestAdvisor.analyze(const SoilTestInput(organicMatterPct: 0.8));
      final f = byParam(a, 'Organik')!;
      expect(f.severity, SoilSeverity.warning);
      expect(f.action!.toLowerCase(), contains('ahır gübresi'));
    });
  });

  group('Doku (suyla doygunluk)', () {
    test('düşük doygunluk (25) → Kumlu doku bulgusu', () {
      final a = SoilTestAdvisor.analyze(const SoilTestInput(saturationPct: 25));
      final f = byParam(a, 'Bünye')!;
      expect(f.level, 'Kumlu');
    });
  });

  group('Eksik girdi davranışı', () {
    test('boş girdi → hasInput false, bulgu yok', () {
      final a = SoilTestAdvisor.analyze(const SoilTestInput());
      expect(a.hasInput, isFalse);
      expect(a.findings, isEmpty);
    });

    test('sadece pH girilirse yalnız pH bulgusu üretilir', () {
      final a = SoilTestAdvisor.analyze(const SoilTestInput(ph: 6.0));
      expect(a.findings.length, 1);
      expect(a.findings.first.parameter, contains('pH'));
      expect(a.hasInput, isTrue);
    });
  });

  group('Ürün gübre takvimi', () {
    test('ürün adı + ölçüm varsa takvim eklenir', () {
      final a = SoilTestAdvisor.analyze(
          const SoilTestInput(ph: 6.5, cropName: 'Domates'));
      expect(a.fertilizationPlan, isNotEmpty);
    });

    test('ürün adı yoksa takvim boştur', () {
      final a = SoilTestAdvisor.analyze(const SoilTestInput(ph: 6.5));
      expect(a.fertilizationPlan, isEmpty);
    });
  });

  group('Guardrail (CLAUDE.md §16/§28)', () {
    test('zorunlu uyarılar her zaman gösterilir (lab + BKÜ yönlendirmesi)', () {
      final a = SoilTestAdvisor.analyze(const SoilTestInput(ph: 5.0));
      expect(a.disclaimers, isNotEmpty);
      final joined = a.disclaimers.join(' ').toLowerCase();
      expect(joined, contains('laboratuvar'));
      expect(joined, contains('bkü'));
    });

    test('hiçbir aksiyon belirli ticari ürün/aktif madde reçetesi vermez', () {
      // Birçok kritik değer ver; tüm aksiyon metinlerini topla.
      final a = SoilTestAdvisor.analyze(const SoilTestInput(
        ph: 4.2,
        saltPct: 0.9,
        limePct: 30,
        organicMatterPct: 0.5,
        phosphorusKgDa: 1,
        potassiumKgDa: 5,
        nitrogenPct: 0.02,
      ));
      final blob = [
        for (final f in a.findings) ...[f.interpretation, f.action ?? ''],
      ].join(' ').toLowerCase();
      // BKÜ marka adı / aktif madde reçetesi içermemeli (örnek yasaklı kelimeler).
      for (final banned in ['mancozeb', 'metalaksil', 'imidakloprid']) {
        expect(blob.contains(banned), isFalse,
            reason: '$banned gibi pestisit aktif maddesi önerilmemeli');
      }
    });
  });

  group('Determinizm', () {
    test('aynı girdi iki kez → aynı çıktı', () {
      const input = SoilTestInput(
        ph: 5.4,
        ecDsM: 6,
        limePct: 18,
        organicMatterPct: 1.1,
        phosphorusKgDa: 4,
        potassiumKgDa: 22,
        cropName: 'Mısır',
      );
      final a = SoilTestAdvisor.analyze(input);
      final b = SoilTestAdvisor.analyze(input);
      expect(a.findings.length, b.findings.length);
      for (var i = 0; i < a.findings.length; i++) {
        expect(a.findings[i].parameter, b.findings[i].parameter);
        expect(a.findings[i].level, b.findings[i].level);
        expect(a.findings[i].severity, b.findings[i].severity);
        expect(a.findings[i].measured, b.findings[i].measured);
        expect(a.findings[i].action, b.findings[i].action);
      }
      expect(a.summary, b.summary);
    });
  });
}
