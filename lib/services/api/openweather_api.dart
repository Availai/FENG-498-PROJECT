/// OpenWeather API — Current weather + 5-day/3-hour forecast
///
/// Requires OPENWEATHER_API_KEY in .env
/// Endpoint docs: https://openweathermap.org/api/one-call-3
library;

import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

// ─────────────────────────────────────────────────────────────────────────────
// MODELLER
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
  final double rainMm1h;   // may be 0
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

  factory OWCurrentWeather.fromJson(Map<String, dynamic> j) {
    final weather = (j['weather'] as List).first as Map<String, dynamic>;
    final rain = j['rain'] as Map<String, dynamic>?;
    return OWCurrentWeather(
      tempC: (j['main']['temp'] as num).toDouble() - 273.15,
      feelsLikeC: (j['main']['feels_like'] as num).toDouble() - 273.15,
      humidityPct: (j['main']['humidity'] as num).toDouble(),
      windSpeedMs: (j['wind']['speed'] as num).toDouble(),
      windDirDeg: (j['wind']['deg'] as num?)?.toDouble() ?? 0,
      pressureHpa: (j['main']['pressure'] as num).toDouble(),
      visibilityKm: ((j['visibility'] as num?)?.toDouble() ?? 0) / 1000,
      uvIndex: 0, // not in current endpoint — needs One Call
      rainMm1h: (rain?['1h'] as num?)?.toDouble() ?? 0,
      description: weather['description'] as String,
      iconCode: weather['icon'] as String,
      observedAt: DateTime.fromMillisecondsSinceEpoch((j['dt'] as int) * 1000),
    );
  }

  /// Agronomic summary string (Turkish)
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

  factory OWForecastPoint.fromJson(Map<String, dynamic> j) {
    final weather = (j['weather'] as List).first as Map<String, dynamic>;
    final rain = j['rain'] as Map<String, dynamic>?;
    return OWForecastPoint(
      time: DateTime.fromMillisecondsSinceEpoch((j['dt'] as int) * 1000),
      tempC: (j['main']['temp'] as num).toDouble() - 273.15,
      precipMm: (rain?['3h'] as num?)?.toDouble() ?? 0,
      windSpeedMs: (j['wind']['speed'] as num).toDouble(),
      windDirDeg: (j['wind']['deg'] as num?)?.toDouble() ?? 0,
      humidityPct: (j['main']['humidity'] as num).toDouble(),
      precipProbPct: ((j['pop'] as num?)?.toDouble() ?? 0 * 100).round(),
      description: weather['description'] as String,
    );
  }
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
// SERVİS
// ─────────────────────────────────────────────────────────────────────────────

class OpenWeatherApi {
  static const _baseUrl = 'https://api.openweathermap.org/data/2.5';
  static const _timeout = Duration(seconds: 10);

  static String get _key {
    final k = dotenv.env['OPENWEATHER_API_KEY'] ?? '';
    if (k.isEmpty) throw Exception('OPENWEATHER_API_KEY not set in .env');
    return k;
  }

  /// Anlık hava durumu
  static Future<OWCurrentWeather> current({
    required double lat,
    required double lon,
  }) async {
    final uri = Uri.parse('$_baseUrl/weather?lat=$lat&lon=$lon&appid=$_key');
    final resp = await http.get(uri).timeout(_timeout);
    if (resp.statusCode != 200) {
      throw Exception('OpenWeather current: HTTP ${resp.statusCode}');
    }
    return OWCurrentWeather.fromJson(jsonDecode(resp.body) as Map<String, dynamic>);
  }

  /// 5 günlük / 3 saatlik tahmin (40 nokta)
  static Future<List<OWForecastPoint>> forecast5Day({
    required double lat,
    required double lon,
  }) async {
    final uri = Uri.parse('$_baseUrl/forecast?lat=$lat&lon=$lon&appid=$_key');
    final resp = await http.get(uri).timeout(_timeout);
    if (resp.statusCode != 200) {
      throw Exception('OpenWeather forecast: HTTP ${resp.statusCode}');
    }
    final body = jsonDecode(resp.body) as Map<String, dynamic>;
    final list = (body['list'] as List).cast<Map<String, dynamic>>();
    return list.map(OWForecastPoint.fromJson).toList();
  }

  /// 5 günlük tahmini günlük özete dönüştür
  static List<OWDailyAggregation> aggregateDaily(List<OWForecastPoint> pts) {
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

  /// Sulama kararı: gerçek veriye dayalı
  /// Returns: (shouldIrrigate, reasonTr)
  static (bool, String) irrigationDecision({
    required OWCurrentWeather current,
    required List<OWDailyAggregation> forecast,
    required double soilMoisturePct,
    required String cropTr,
  }) {
    // Son 3 günde yağış var mı?
    final recent3 = forecast.take(3).map((d) => d.totalPrecipMm).fold(0.0, (a, b) => a + b);
    // Önümüzdeki 24s yağış var mı?
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
