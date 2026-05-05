import 'package:flutter_test/flutter_test.dart';

import 'package:feng_498/data/activity_types.dart';
import 'package:feng_498/services/guide_engine.dart';
import 'package:feng_498/services/weather_soil_service.dart';

HourlyForecast _forecast({
  required DateTime start,
  required List<double> temps,
  required List<double> rains,
  double humidity = 60,
}) {
  final count = temps.length > rains.length ? temps.length : rains.length;
  return HourlyForecast(
    fetchedAt: start,
    slots: [
      for (var i = 0; i < count; i++)
        HourlySlot(
          hour: start.add(Duration(hours: i)),
          tempC: i < temps.length ? temps[i] : temps.last,
          rainMm: i < rains.length ? rains[i] : 0,
          humidity: humidity,
        ),
    ],
  );
}

void main() {
  const engine = GuideEngine();

  test('24 saatlik yağmur sulama görevini bastırıp yağmur uyarısı üretir',
      () async {
    final now = DateTime(2026, 5, 5, 6);
    final result = await engine.generate(
      now: now,
      fieldCrops: [
        {
          'id': 'crop-1',
          'name': 'Fasulye',
          'planted_date': '15.04.2026',
          'water_interval_days': 7,
          'harvest_days': 90,
        },
      ],
      activities: const [],
      hourly: _forecast(
        start: now,
        temps: List.filled(24, 22),
        rains: [for (var i = 0; i < 8; i++) 1.5, ...List.filled(16, 0)],
      ),
    );

    expect(
      result.alerts.any((a) => a.kind == AlertKind.rainExpected),
      isTrue,
    );
    expect(
      result.today.any((t) => t.actionType == ActivityType.watering),
      isFalse,
    );
  });

  test('don eşiği kritik uyarı üretir', () async {
    final now = DateTime(2026, 1, 10, 20);
    final result = await engine.generate(
      now: now,
      fieldCrops: const [],
      activities: const [],
      hourly: _forecast(
        start: now,
        temps: [-1, 1, 3, ...List.filled(21, 6)],
        rains: List.filled(24, 0),
      ),
    );

    final frost = result.alerts.firstWhere((a) => a.kind == AlertKind.frost);
    expect(frost.severity, AlertSeverity.critical);
    expect(frost.message, contains('°C'));
  });

  test('aşırı sıcak kritik uyarı üretir', () async {
    final now = DateTime(2026, 7, 20, 9);
    final result = await engine.generate(
      now: now,
      fieldCrops: const [],
      activities: const [],
      hourly: _forecast(
        start: now,
        temps: [for (var i = 0; i < 24; i++) i == 6 ? 41 : 34],
        rains: List.filled(24, 0),
      ),
    );

    final heat = result.alerts.firstWhere((a) => a.kind == AlertKind.heat);
    expect(heat.severity, AlertSeverity.critical);
    expect(heat.title, contains('Sıcak'));
  });

  test('24 saatlik ağır yağış tarlaya ekipman sokma uyarısı üretir', () async {
    final now = DateTime(2026, 5, 5, 8);
    final result = await engine.generate(
      now: now,
      fieldCrops: const [],
      activities: const [],
      hourly: _forecast(
        start: now,
        temps: List.filled(24, 18),
        rains: [for (var i = 0; i < 12; i++) 2.6, ...List.filled(12, 0)],
      ),
    );

    final unsafe =
        result.alerts.firstWhere((a) => a.kind == AlertKind.fieldUnsafe);
    expect(unsafe.severity, AlertSeverity.warning);
    expect(unsafe.message, contains('Ağır makineler'));
  });
}
