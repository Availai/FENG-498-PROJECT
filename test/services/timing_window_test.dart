import 'package:flutter_test/flutter_test.dart';

import 'package:feng_498/services/rules/timing_window.dart';
import 'package:feng_498/services/weather_soil_service.dart'
    show HourlyForecast, HourlySlot;

void main() {
  HourlyForecast forecast({
    required DateTime startHour,
    required List<({double t, double r, double h})> slots,
  }) {
    return HourlyForecast(
      slots: [
        for (int i = 0; i < slots.length; i++)
          HourlySlot(
            hour: startHour.add(Duration(hours: i)),
            tempC: slots[i].t,
            rainMm: slots[i].r,
            humidity: slots[i].h,
          ),
      ],
      fetchedAt: startHour,
    );
  }

  group('forIrrigation', () {
    test('forecast yok → agronomic descriptor (sabah)', () {
      final timing = TimingWindow.forIrrigation(now: DateTime(2026, 6, 1));
      expect(timing, isNotNull);
      expect(timing!.source, 'agronomic');
      expect(timing.descriptor, contains('06:00'));
    });

    test('sabah saatlerinde uygun pencere → forecast source', () {
      // Saat 6'dan başlayan tamamen kuru/normal forecast
      final start = DateTime(2026, 6, 1, 6);
      final f = forecast(
        startHour: start,
        slots: List.generate(12, (_) => (t: 22.0, r: 0.0, h: 60.0)),
      );
      final timing = TimingWindow.forIrrigation(now: start, hourly: f);
      expect(timing, isNotNull);
      expect(timing!.source, 'forecast');
      expect(timing.descriptor, contains('06:'));
    });

    test('yağmur eşiği aşan forecast → agronomic fallback', () {
      final start = DateTime(2026, 6, 1, 6);
      final f = forecast(
        startHour: start,
        slots: List.generate(12, (_) => (t: 22.0, r: 5.0, h: 60.0)),
      );
      final timing = TimingWindow.forIrrigation(now: start, hourly: f);
      expect(timing, isNotNull);
      expect(timing!.source, 'agronomic');
    });
  });

  group('forSpraying', () {
    test('uygun sıcaklık + kuru → forecast pencere', () {
      final start = DateTime(2026, 6, 1, 7);
      final f = forecast(
        startHour: start,
        slots: List.generate(12, (_) => (t: 22.0, r: 0.0, h: 55.0)),
      );
      final timing = TimingWindow.forSpraying(now: start, hourly: f);
      expect(timing, isNotNull);
      expect(timing!.source, 'forecast');
      expect(timing.descriptor, contains('rüzgâr'));
    });

    test('aşırı sıcak (>28°C) → fallback agronomic', () {
      final start = DateTime(2026, 6, 1, 12);
      final f = forecast(
        startHour: start,
        slots: List.generate(12, (_) => (t: 32.0, r: 0.0, h: 40.0)),
      );
      final timing = TimingWindow.forSpraying(now: start, hourly: f);
      expect(timing, isNotNull);
      expect(timing!.source, 'agronomic');
    });
  });

  group('forHarvest', () {
    test('24h yağış 0 → uygun', () {
      final start = DateTime(2026, 9, 1, 8);
      final f = forecast(
        startHour: start,
        slots: List.generate(24, (_) => (t: 25.0, r: 0.0, h: 50.0)),
      );
      final timing = TimingWindow.forHarvest(now: start, hourly: f);
      expect(timing, isNotNull);
      expect(timing!.source, 'forecast');
      expect(timing.hasWindow, isTrue);
    });

    test('24h yağış >5 mm → erteleme uyarısı', () {
      final start = DateTime(2026, 9, 1, 8);
      final f = forecast(
        startHour: start,
        slots: List.generate(24, (_) => (t: 22.0, r: 1.0, h: 70.0)),
      );
      final timing = TimingWindow.forHarvest(now: start, hourly: f);
      expect(timing, isNotNull);
      expect(timing!.source, 'forecast');
      expect(timing.hasWindow, isFalse);
      expect(timing.descriptor, contains('mm yağış'));
    });

    test('forecast yok → agronomic', () {
      final timing = TimingWindow.forHarvest(now: DateTime(2026, 9, 1));
      expect(timing!.source, 'agronomic');
    });
  });

  group('forFertilizing', () {
    test('48h içinde 5-15 mm yağış → forecast (kaplama gübre)', () {
      final start = DateTime(2026, 6, 1, 8);
      final f = forecast(
        startHour: start,
        slots: [
          for (int i = 0; i < 48; i++)
            (t: 20.0, r: i < 8 ? 1.0 : 0.0, h: 60.0),
        ],
      );
      // 8 saat × 1 mm = 8 mm — pencere içinde
      final timing = TimingWindow.forFertilizing(now: start, hourly: f);
      expect(timing, isNotNull);
      expect(timing!.source, 'forecast');
    });

    test('48h yağış 0 → agronomic', () {
      final start = DateTime(2026, 6, 1, 8);
      final f = forecast(
        startHour: start,
        slots: List.generate(48, (_) => (t: 20.0, r: 0.0, h: 60.0)),
      );
      final timing = TimingWindow.forFertilizing(now: start, hourly: f);
      expect(timing, isNotNull);
      expect(timing!.source, 'agronomic');
    });
  });

  test('forScouting → her zaman agronomic descriptor', () {
    final timing = TimingWindow.forScouting();
    expect(timing.source, 'agronomic');
    expect(timing.descriptor, contains('07:00'));
  });
}
