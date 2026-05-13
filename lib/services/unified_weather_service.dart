/// Birleşik Hava Veri Kaynağı (MGM öncelikli, Open-Meteo fallback).
///
/// Türkiye için T.C. MGM gerçek istasyon ölçümleri global modellerden
/// çok daha doğrudur. MGM istasyon bulunamazsa **ücretsiz, key gerektirmeyen**
/// Open-Meteo servisine düşer.
///
/// Kullanım:
///   final w = await UnifiedWeatherService.fetchCurrent(lat: 39.9, lon: 32.8);
///   // w.source == 'MGM' veya 'Open-Meteo'
///
///   final hourly = await UnifiedWeatherService.fetchHourly(
///     lat: 39.9, lon: 32.8,
///   );
///   // hourly.source == 'MGM' / 'MGM + Open-Meteo' / 'Open-Meteo'
library;

import 'api/mgm_api.dart';
import 'api/openweather_api.dart';

class UnifiedCurrentWeather {
  final double tempC;
  final double humidityPct;
  final double windMs;
  final double rainLast1hMm;
  final String description;
  final String source; // 'MGM' veya 'Open-Meteo'
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
        source: 'Open-Meteo',
        stationLabel: '${lat.toStringAsFixed(2)}, ${lon.toStringAsFixed(2)}',
      );
}

/// Saatlik tahmin tek noktası (kaynak bağımsız).
class UnifiedHourlyPoint {
  final DateTime time;
  final double tempC;
  final double apparentC;
  final double humidityPct;
  final double windMs;
  final double windDirDeg;
  final double precipMm;

  /// Yağış olasılığı (%). MGM saatlik bunu vermez → null olabilir.
  final int? precipProbPct;
  final String description;

  const UnifiedHourlyPoint({
    required this.time,
    required this.tempC,
    required this.apparentC,
    required this.humidityPct,
    required this.windMs,
    required this.windDirDeg,
    required this.precipMm,
    required this.description,
    this.precipProbPct,
  });

  factory UnifiedHourlyPoint.fromMgm(MgmHourlyPoint p) => UnifiedHourlyPoint(
        time: p.time,
        tempC: p.tempC,
        apparentC: p.apparentC,
        humidityPct: p.humidityPct,
        windMs: p.windSpeedMs,
        windDirDeg: p.windDirDeg,
        precipMm: p.precipMm,
        description: p.description,
        precipProbPct: null,
      );

  factory UnifiedHourlyPoint.fromOpenWeather(OWForecastPoint p) =>
      UnifiedHourlyPoint(
        time: p.time,
        tempC: p.tempC,
        apparentC: p.tempC,
        humidityPct: p.humidityPct,
        windMs: p.windSpeedMs,
        windDirDeg: p.windDirDeg,
        precipMm: p.precipMm,
        description: p.description,
        precipProbPct: p.precipProbPct,
      );
}

/// Saatlik tahmin sonucu — meta + nokta listesi.
class UnifiedHourlyForecast {
  /// 'MGM', 'Open-Meteo' veya 'MGM + Open-Meteo' (MGM ~3 gün, OM kalan günler).
  final String source;
  final String stationLabel;
  final List<UnifiedHourlyPoint> points;
  final DateTime fetchedAt;

  const UnifiedHourlyForecast({
    required this.source,
    required this.stationLabel,
    required this.points,
    required this.fetchedAt,
  });

  bool get isEmpty => points.isEmpty;

  /// Gün-bazlı gruplandırma (tarihe göre sıralı).
  Map<DateTime, List<UnifiedHourlyPoint>> groupedByDay() {
    final map = <DateTime, List<UnifiedHourlyPoint>>{};
    for (final p in points) {
      final key = DateTime(p.time.year, p.time.month, p.time.day);
      (map[key] ??= []).add(p);
    }
    return Map.fromEntries(
      map.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
    );
  }
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

    // 2) Open-Meteo fallback (key gerektirmez)
    final ow = await OpenWeatherApi.current(lat: lat, lon: lon);
    return UnifiedCurrentWeather.fromOpenWeather(ow, lat, lon);
  }

  /// 7 günlük saatlik tahmin.
  ///
  /// Strateji:
  ///  1) MGM en yakın istasyon → saatlik tahmin (genellikle ~3 gün).
  ///  2) Open-Meteo 7 gün saatlik tahmin alınır.
  ///  3) MGM noktaları korunur; Open-Meteo'dan yalnız MGM'in son
  ///     örneğinden sonraki saatler eklenir → "MGM + Open-Meteo" birleşik.
  ///  4) MGM hiç veri vermezse saf Open-Meteo döner.
  static Future<UnifiedHourlyForecast> fetchHourly({
    required double lat,
    required double lon,
  }) async {
    final fetchedAt = DateTime.now();
    List<UnifiedHourlyPoint> mgmPoints = const [];
    String stationLabel =
        '${lat.toStringAsFixed(2)}, ${lon.toStringAsFixed(2)}';

    // 1) MGM'i dene
    try {
      final station = await MgmApi.nearestStation(lat: lat, lon: lon);
      if (station != null) {
        stationLabel = '${station.il} / ${station.ilce}';
        final hourly = await MgmApi.hourlyForecast(station);
        mgmPoints = hourly.map(UnifiedHourlyPoint.fromMgm).toList();
      }
    } catch (_) {}

    // 2) Open-Meteo 7 gün saatlik (her zaman alınır — MGM kısa kapsamlı)
    List<UnifiedHourlyPoint> omPoints = const [];
    try {
      final om = await OpenWeatherApi.forecast5Day(lat: lat, lon: lon);
      omPoints = om.map(UnifiedHourlyPoint.fromOpenWeather).toList();
    } catch (_) {}

    if (mgmPoints.isEmpty && omPoints.isEmpty) {
      return UnifiedHourlyForecast(
        source: 'yok',
        stationLabel: stationLabel,
        points: const [],
        fetchedAt: fetchedAt,
      );
    }

    if (mgmPoints.isEmpty) {
      return UnifiedHourlyForecast(
        source: 'Open-Meteo',
        stationLabel: stationLabel,
        points: omPoints,
        fetchedAt: fetchedAt,
      );
    }

    if (omPoints.isEmpty) {
      return UnifiedHourlyForecast(
        source: 'MGM',
        stationLabel: stationLabel,
        points: mgmPoints,
        fetchedAt: fetchedAt,
      );
    }

    // 3) Birleştir: MGM'in son saatinden sonrasını Open-Meteo'dan ekle
    final mgmLast = mgmPoints.last.time;
    final merged = <UnifiedHourlyPoint>[
      ...mgmPoints,
      ...omPoints.where((p) => p.time.isAfter(mgmLast)),
    ];
    return UnifiedHourlyForecast(
      source: 'MGM + Open-Meteo',
      stationLabel: stationLabel,
      points: merged,
      fetchedAt: fetchedAt,
    );
  }
}
