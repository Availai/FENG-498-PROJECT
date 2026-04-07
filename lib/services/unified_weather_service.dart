/// Birleşik Hava Veri Kaynağı (MGM öncelikli, OpenWeather fallback).
///
/// AGENTS.md "complete farming assistant" gereksinimi için:
/// Türkiye için T.C. MGM gerçek istasyon ölçümleri global modellerden
/// çok daha doğrudur. Ancak MGM bazı koordinatlarda istasyon bulamayabilir
/// veya servisi geçici erişilemez olabilir → OpenWeather fallback gerekir.
///
/// Kullanım:
///   final w = await UnifiedWeatherService.fetchCurrent(lat: 39.9, lon: 32.8);
///   // w.source == 'MGM' veya 'OpenWeather'
library;

import 'api/mgm_api.dart';
import 'api/openweather_api.dart';

class UnifiedCurrentWeather {
  final double tempC;
  final double humidityPct;
  final double windMs;
  final double rainLast1hMm;
  final String description;
  final String source;       // 'MGM' veya 'OpenWeather'
  final String stationLabel; // Örn: "Ankara / Etimesgut" veya koordinat

  const UnifiedCurrentWeather({
    required this.tempC,
    required this.humidityPct,
    required this.windMs,
    required this.rainLast1hMm,
    required this.description,
    required this.source,
    required this.stationLabel,
  });

  factory UnifiedCurrentWeather.fromMgm(MgmObservation o) =>
      UnifiedCurrentWeather(
        tempC: o.tempC,
        humidityPct: o.humidityPct,
        windMs: o.windSpeedMs,
        rainLast1hMm: o.rainLast1hMm,
        description: 'MGM gözlem',
        source: 'MGM',
        stationLabel: o.stationName,
      );

  factory UnifiedCurrentWeather.fromOpenWeather(
          OWCurrentWeather o, double lat, double lon) =>
      UnifiedCurrentWeather(
        tempC: o.tempC,
        humidityPct: o.humidityPct,
        windMs: o.windSpeedMs,
        rainLast1hMm: o.rainMm1h,
        description: o.description,
        source: 'OpenWeather',
        stationLabel:
            '${lat.toStringAsFixed(2)}, ${lon.toStringAsFixed(2)}',
      );
}

class UnifiedWeatherService {
  /// Anlık hava — MGM öncelikli, MGM yoksa OpenWeather.
  static Future<UnifiedCurrentWeather> fetchCurrent({
    required double lat,
    required double lon,
  }) async {
    // 1) MGM dene (Türkiye için en doğru kaynak)
    try {
      final mgm = await MgmApi.fetchAll(lat: lat, lon: lon);
      if (mgm != null && mgm.now != null) {
        return UnifiedCurrentWeather.fromMgm(mgm.now!);
      }
    } catch (_) {}

    // 2) OpenWeather fallback
    final ow = await OpenWeatherApi.current(lat: lat, lon: lon);
    return UnifiedCurrentWeather.fromOpenWeather(ow, lat, lon);
  }
}
