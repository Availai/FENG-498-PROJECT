import 'package:feng_498/services/offline_rule_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('offline rule engine direct kimyasal ve analizsiz gubre dozu donmez', () {
    final results = OfflineRuleEngine.analyze(
      commonName: 'Domates',
      temperature: 22,
      avgWeeklyTemp: 22,
      humidity: 90,
      weeklyRain: 55,
      soilPh: 4.8,
      month: 6,
    );

    final text = results.map((r) => r.recommendation).join('\n').toLowerCase();
    const banned = [
      'fungisit',
      'insektisit',
      'akarisit',
      'mancozeb',
      'metalaksil',
      'spinosad',
      'triazol',
      'dekara 300',
      'dekara 200',
      'dekara 30',
      'kg/da',
      'ml/da',
    ];

    expect(banned.where(text.contains), isEmpty);
    expect(text, contains('bkü'));
    expect(text, contains('uzman'));
  });
}
