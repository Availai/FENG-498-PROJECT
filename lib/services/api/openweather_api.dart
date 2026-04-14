/// Ücretsiz hava servisi (Open-Meteo tabanlı).
///
/// Eski ad `OpenWeatherApi` geriye dönük uyumluluk için korunuyor ama
/// iç implementasyon tamamen Open-Meteo'ya geçti. API key **gerektirmez**.
///
/// Endpoint: https://api.open-meteo.com/v1/forecast
library;

import 'dart:convert';
import 'package:http/http.dart' as http;

// ─────────────────────────────────────────────────────────────────────────────
// MODELLER — isimler (OW*) geriye dönük uyum için korunuyor
// ─────────────────────────────────────────────────────────────────────────────

class OWCurrentWeather {
  final double tempC;
  final double feelsLikeC;
  final double humidityPct;
  final double windSpeedMs;
  final double windDirDeg;
  final double pressureHpa;
  final double visibilityKm;
  final double uvIndex;
  final double rainMm1h;
  final String description;
  final String iconCode;
  final DateTime observedAt;

  const OWCurrentWeather({
    required this.tempC,
    required this.feelsLikeC,
    required this.humidityPct,
    required this.windSpeedMs,
    required this.windDirDeg,
    required this.pressureHpa,
    required this.visibilityKm,
    required this.uvIndex,
    required this.rainMm1h,
    required this.description,
    required this.iconCode,
    required this.observedAt,
  });

  factory OWCurrentWeather.fromOpenMeteo(Map<String, dynamic> j) {
    final cur = j['current'] as Map<String, dynamic>;
    final code = (cur['weather_code'] as num?)?.toInt() ?? 0;
    final (desc, icon) = _weatherCodeToTr(code);
    return OWCurrentWeather(
      tempC: (cur['temperature_2m'] as num?)?.toDouble() ?? 0,
      feelsLikeC: (cur['apparent_temperature'] as num?)?.toDouble() ?? 0,
      humidityPct: (cur['relative_humidity_2m'] as num?)?.toDouble() ?? 0,
      windSpeedMs: (cur['wind_speed_10m'] as num?)?.toDouble() ?? 0,
      windDirDeg: (cur['wind_direction_10m'] as num?)?.toDouble() ?? 0,
      pressureHpa: (cur['pressure_msl'] as num?)?.toDouble() ?? 0,
      visibilityKm: 0,
      uvIndex: 0,
      rainMm1h: (cur['precipitation'] as num?)?.toDouble() ?? 0,
      description: desc,
      iconCode: icon,
      observedAt: DateTime.tryParse(cur['time']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  String get agronomicSummary {
    final parts = <String>[];
    if (tempC > 35) parts.add('Aşırı sıcaklık riski (${tempC.toStringAsFixed(0)}°C)');
    if (tempC < 0) parts.add('Don riski (${tempC.toStringAsFixed(0)}°C)');
    if (humidityPct > 85) parts.add('Yüksek nem — mantar hastalığı riski');
    if (windSpeedMs > 10) parts.add('Kuvvetli rüzgar — ilaçlama yapma');
    if (rainMm1h > 5) parts.add('Yağış var — sulama gerekmiyor');
    if (parts.isEmpty) parts.add('Koşullar normal');
    return parts.join(' · ');
  }
}

class OWForecastPoint {
  final DateTime time;
  final double tempC;
  final double precipMm;
  final double windSpeedMs;
  final double windDirDeg;
  final double humidityPct;
  final int precipProbPct;
  final String description;

  const OWForecastPoint({
    required this.time,
    required this.tempC,
    required this.precipMm,
    required this.windSpeedMs,
    required this.windDirDeg,
    required this.humidityPct,
    required this.precipProbPct,
    required this.description,
  });
}

class OWDailyAggregation {
  final DateTime date;
  final double minTempC;
  final double maxTempC;
  final double avgTempC;
  final double totalPrecipMm;
  final double maxWindMs;
  final double avgHumidityPct;
  final String summary;

  const OWDailyAggregation({
    required this.date,
    required this.minTempC,
    required this.maxTempC,
    required this.avgTempC,
    required this.totalPrecipMm,
    required this.maxWindMs,
    required this.avgHumidityPct,
    required this.summary,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// WMO weather code → Türkçe özet + legacy icon kodu
// ─────────────────────────────────────────────────────────────────────────────

(String, String) _weatherCodeToTr(int code) {
  if (code == 0) return ('Açık', '01d');
  if (code == 1) return ('Az bulutlu', '02d');
  if (code == 2) return ('Parçalı bulutlu', '03d');
  if (code == 3) return ('Kapalı', '04d');
  if (code == 45 || code == 48) return ('Sisli', '50d');
  if (code >= 51 && code <= 57) return ('Çisenti', '09d');
  if (code >= 61 && code <= 67) return ('Yağmurlu', '10d');
  if (code >= 71 && code <= 77) return ('Karlı', '13d');
  if (code >= 80 && code <= 82) return ('Sağanak', '09d');
  if (code >= 85 && code <= 86) return ('Kar sağanağı', '13d');
  if (code >= 95) return ('Gök gürültülü fırtına', '11d');
  return ('Belirsiz', '01d');
}

// ─────────────────────────────────────────────────────────────────────────────
// SERVİS — Open-Meteo (ücretsiz, key yok)
// ─────────────────────────────────────────────────────────────────────────────

class OpenWeatherApi {
  static const _baseUrl = 'https://api.open-meteo.com/v1/forecast';
  static const _timeout = Duration(seconds: 10);

  /// Anlık hava durumu (Open-Meteo)
  static Future<OWCurrentWeather> current({
    required double lat,
    required double lon,
  }) async {
    final uri = Uri.parse(
      '$_baseUrl?latitude=$lat&longitude=$lon'
      '&current=temperature_2m,relative_humidity_2m,apparent_temperature,'
      'precipitation,weather_code,wind_speed_10m,wind_direction_10m,pressure_msl'
      '&wind_speed_unit=ms&timezone=auto',
    );
    final resp = await http.get(uri).timeout(_timeout);
    if (resp.statusCode != 200) {
      throw Exception('Open-Meteo current: HTTP ${resp.statusCode}');
    }
    return OWCurrentWeather.fromOpenMeteo(
      jsonDecode(resp.body) as Map<String, dynamic>,
    );
  }

  /// 7 günlük saatlik tahmin (56 nokta = her 3 saatte ~bir örnek)
  static Future<List<OWForecastPoint>> forecast5Day({
    required double lat,
    required double lon,
  }) async {
    final uri = Uri.parse(
      '$_baseUrl?latitude=$lat&longitude=$lon'
      '&hourly=temperature_2m,relative_humidity_2m,precipitation,'
      'precipitation_probability,wind_speed_10m,wind_direction_10m,weather_code'
      '&wind_speed_unit=ms&forecast_days=7&timezone=auto',
    );
    final resp = await http.get(uri).timeout(_timeout);
    if (resp.statusCode != 200) {
      throw Exception('Open-Meteo forecast: HTTP ${resp.statusCode}');
    }
    final body = jsonDecode(resp.body) as Map<String, dynamic>;
    final h = body['hourly'] as Map<String, dynamic>;
    final times = (h['time'] as List).cast<String>();
    final temps = (h['temperature_2m'] as List).cast<num>();
    final hums = (h['relative_humidity_2m'] as List).cast<num>();
    final precs = (h['precipitation'] as List).cast<num>();
    final probs = (h['precipitation_probability'] as List? ?? []).cast<num?>();
    final winds = (h['wind_speed_10m'] as List).cast<num>();
    final wdirs = (h['wind_direction_10m'] as List).cast<num>();
    final codes = (h['weather_code'] as List).cast<num>();

    final points = <OWForecastPoint>[];
    // 3 saatte bir örnekle (OpenWeather 5day/3h ile uyum)
    for (var i = 0; i < times.length; i += 3) {
      final (desc, _) = _weatherCodeToTr(codes[i].toInt());
      points.add(OWForecastPoint(
        time: DateTime.tryParse(times[i]) ?? DateTime.now(),
        tempC: temps[i].toDouble(),
        precipMm: precs[i].toDouble(),
        windSpeedMs: winds[i].toDouble(),
        windDirDeg: wdirs[i].toDouble(),
        humidityPct: hums[i].toDouble(),
        precipProbPct: (i < probs.length ? (probs[i]?.toInt() ?? 0) : 0),
        description: desc,
      ));
    }
    return points;
  }

  /// Saatlik noktaları günlük özete çevir
  static List<OWDailyAggregation> aggregateDaily(List<OWForecastPoint> pts) {
    if (pts.isEmpty) return [];
    final map = <String, List<OWForecastPoint>>{};
    for (final p in pts) {
      final key = '${p.time.year}-${p.time.month.toString().padLeft(2,'0')}-${p.time.day.toString().padLeft(2,'0')}';
      (map[key] ??= []).add(p);
    }
    return map.entries.map((e) {
      final day = e.value;
      final temps = day.map((p) => p.tempC).toList();
      return OWDailyAggregation(
        date: day.first.time,
        minTempC: temps.reduce((a, b) => a < b ? a : b),
        maxTempC: temps.reduce((a, b) => a > b ? a : b),
        avgTempC: temps.reduce((a, b) => a + b) / temps.length,
        totalPrecipMm: day.map((p) => p.precipMm).reduce((a, b) => a + b),
        maxWindMs: day.map((p) => p.windSpeedMs).reduce((a, b) => a > b ? a : b),
        avgHumidityPct: day.map((p) => p.humidityPct).reduce((a, b) => a + b) / day.length,
        summary: day.last.description,
      );
    }).toList()..sort((a, b) => a.date.compareTo(b.date));
  }

  /// Sulama kararı — Türkçe gerekçe
  static (bool, String) irrigationDecision({
    required OWCurrentWeather current,
    required List<OWDailyAggregation> forecast,
    required double soilMoisturePct,
    required String cropTr,
  }) {
    final recent3 = forecast.take(3).map((d) => d.totalPrecipMm).fold(0.0, (a, b) => a + b);
    final upcomingRain = forecast.isNotEmpty ? forecast.first.totalPrecipMm : 0.0;

    if (upcomingRain > 8) {
      return (false, 'Yarın ${upcomingRain.toStringAsFixed(0)} mm yağış bekleniyor — sulama gerekmiyor.');
    }
    if (recent3 > 15) {
      return (false, 'Son 3 günde ${recent3.toStringAsFixed(0)} mm yağış düştü — toprak nemli.');
    }
    if (soilMoisturePct > 70) {
      return (false, 'Toprak nemi yüksek (%${soilMoisturePct.round()}) — sulama gerekmiyor.');
    }
    if (current.tempC > 32 && soilMoisturePct < 40) {
      return (true, 'Sıcaklık ${current.tempC.toStringAsFixed(0)}°C, toprak nemi düşük — sabah erken sulama önerilir.');
    }
    if (soilMoisturePct < 30) {
      return (true, 'Toprak nemi kritik (%${soilMoisturePct.round()}) — acil sulama gerekli.');
    }
    return (false, 'Mevcut koşullarda sulama gerekmiyor.');
  }
}
