import 'package:flutter_test/flutter_test.dart';

import 'package:feng_498/services/weather_soil_service.dart';

void main() {
  group('DashboardConditions', () {
    test('JSON round-trip sicaklik, nem, ruzgar ve pH degerlerini korur', () {
      const conditions = DashboardConditions(
        temperatureC: 24.5,
        humidity: 62,
        windSpeedMs: 3.4,
        weatherDescriptionTr: 'A\u00e7\u0131k',
        phH2O: 7.1,
      );

      final parsed = DashboardConditions.fromJson(conditions.toJson());

      expect(parsed.temperatureC, 24.5);
      expect(parsed.humidity, 62);
      expect(parsed.windSpeedMs, 3.4);
      expect(parsed.weatherDescriptionTr, 'A\u00e7\u0131k');
      expect(parsed.phH2O, 7.1);
      expect(parsed.isEmpty, isFalse);
    });

    test('eksik pH null kalir — sessiz varsayim uretmez (B1)', () {
      // Hava-yalniz kaynaklarda (Open-Meteo) toprak pH'i yoktur. Sessiz 6.8
      // sabiti cifticiyi yanlis toprak degerine inandirir; bu yuzden null
      // kalmali ve tuketici degeri "tahmini" olarak gostermeli.
      final parsed = DashboardConditions.fromJson(const {});

      expect(parsed.isEmpty, isTrue);
      expect(parsed.phH2O, isNull);
    });
  });

  group('HourlyForecast', () {
    test(
        'istenen saat araligi veri uzunlugunu assa da min max ve yagmur toplar',
        () {
      final now = DateTime(2026, 5, 6, 10);
      final forecast = HourlyForecast(
        fetchedAt: now,
        slots: [
          HourlySlot(hour: now, tempC: 12, rainMm: 1.5, humidity: 70),
          HourlySlot(
            hour: now.add(const Duration(hours: 1)),
            tempC: -1,
            rainMm: 0,
            humidity: 80,
          ),
          HourlySlot(
            hour: now.add(const Duration(hours: 2)),
            tempC: 30,
            rainMm: 4,
            humidity: 55,
          ),
        ],
      );

      expect(forecast.minTempNext(48), -1);
      expect(forecast.maxTempNext(48), 30);
      expect(forecast.rainSumNext(48), 5.5);
    });

    test('bos forecast null ve sifir degerlerle guvenli doner', () {
      final forecast = HourlyForecast(
        fetchedAt: DateTime(2026, 5, 6),
        slots: const [],
      );

      expect(forecast.isEmpty, isTrue);
      expect(forecast.minTempNext(24), isNull);
      expect(forecast.maxTempNext(24), isNull);
      expect(forecast.rainSumNext(24), 0);
    });
  });

  test('HourlySlot JSON round-trip tarih ve olcumleri korur', () {
    final hour = DateTime(2026, 5, 6, 12);
    final slot = HourlySlot(hour: hour, tempC: 18, rainMm: 2, humidity: 65);

    final parsed = HourlySlot.fromJson(slot.toJson());

    expect(parsed.hour, hour);
    expect(parsed.tempC, 18);
    expect(parsed.rainMm, 2);
    expect(parsed.humidity, 65);
  });
}
