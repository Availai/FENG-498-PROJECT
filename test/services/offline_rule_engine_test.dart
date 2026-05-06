import 'package:flutter_test/flutter_test.dart';

import 'package:feng_498/services/offline_rule_engine.dart';

void main() {
  group('OfflineRuleEngine.analyze', () {
    test('kritik kosullarda farkli kategorileri calistirir ve oncelige siralar',
        () {
      final results = OfflineRuleEngine.analyze(
        commonName: 'domates',
        plantDetails: const {
          'watering': 'Frequent',
          'sunlight': ['full sun'],
          'pruning_month': 'Haziran',
        },
        temperature: 41,
        avgWeeklyTemp: 34,
        humidity: 92,
        weeklyRain: 2,
        soilPh: 5.1,
        soilMoisture: 0.05,
        soilTempC: 9,
        ndvi: 0.2,
        windSpeed: 16,
        month: 7,
        precipProbNext3h: 80,
      );

      expect(results, isNotEmpty);
      expect(results.first.level, RiskLevel.critical);
      expect(results.map((r) => r.category), contains(RuleCategory.weather));
      expect(results.map((r) => r.category), contains(RuleCategory.irrigation));
      expect(results.map((r) => r.category), contains(RuleCategory.soil));
      expect(results.map((r) => r.title), everyElement(isNotEmpty));

      final order = results.map((r) => r.level.index).toList();
      expect(order, orderedEquals(order.toList()..sort()));
    });

    test('hasat ipucu yalniz ilgili kavun karpuz urunlerinde gelir', () {
      final melon = OfflineRuleEngine.analyze(commonName: 'karpuz');
      final tomato = OfflineRuleEngine.analyze(commonName: 'domates');

      expect(melon.map((r) => r.category), contains(RuleCategory.harvest));
      expect(
          tomato.map((r) => r.category), isNot(contains(RuleCategory.harvest)));
    });
  });

  test('RuleResult.toMap UI icin gerekli etiketleri ve enum adlarini tasir',
      () {
    const result = RuleResult(
      level: RiskLevel.warning,
      category: RuleCategory.soil,
      title: 'pH uyarisi',
      message: 'Toprak bazik',
      recommendation: 'Analiz yaptir',
    );

    final map = result.toMap();

    expect(map['level'], 'warning');
    expect(map['category'], 'soil');
    expect(map['category_label'], isNotEmpty);
    expect(map['emoji'], isNotEmpty);
  });

  group('OfflineRuleEngine metin ureticileri', () {
    test('tarla planinda bitki sayisini cm araligini m2ye cevirerek hesaplar',
        () {
      final plan = OfflineRuleEngine.generateFieldPlan(
        plantName: 'Domates',
        fieldName: 'Deneme Tarlasi',
        ph: 6.4,
        avgTemp: 24,
        totalRain: 12,
        areaDekar: 1,
        month: 5,
        plantDetails: const {
          'row_spacing_cm': 60,
          'plant_spacing_cm': 40,
          'depth_cm': 2,
          'seeds_per_dekar': 2500,
          'harvest_days': 90,
        },
      );

      expect(plan, contains('Deneme Tarlasi'));
      expect(plan, contains('Toplam 4167 bitki'));
    });

    test('haftalik yorum kuraklik ve urun onerilerini ayni metinde verir', () {
      final comment = OfflineRuleEngine.generateWeeklyComment(
        fieldName: 'Kuzey Parsel',
        temp: 33,
        avgTemp: 25,
        humidity: 30,
        wind: 3,
        ph: 5.2,
        soilMoisture: 0.12,
        soilTempC: 18,
        totalWeeklyRain: 3,
        crops: const [
          {'name': 'Domates'},
          {'name': 'Biber'},
        ],
        month: 4,
      );

      expect(comment, contains('Kuzey Parsel'));
      expect(comment, contains('Sulama'));
      expect(comment, contains('Domates'));
      expect(comment, contains('pH 5.2'));
    });

    test('cevre raporu tarimsal olmayan fotograf icin riskleri ozetler', () {
      final report = OfflineRuleEngine.generateEnvironmentalReport(
        temp: 2,
        humidity: 75,
        weeklyRain: 20,
        ph: 6.5,
        soilMoisture: 0.3,
        soilTempC: 8,
        month: 1,
      );

      expect(report, contains('pH'));
      expect(report, contains('6.5'));
      expect(report, contains('So'));
    });
  });
}
