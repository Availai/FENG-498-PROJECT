import 'dart:convert';
import 'package:http/http.dart' as http;

class DashboardConditions {
  final double? temperatureC;
  final int? humidity;
  final double? windSpeedMs;
  final String weatherDescriptionTr;
  final double phH2O;

  const DashboardConditions({
    this.temperatureC,
    this.humidity,
    this.windSpeedMs,
    this.weatherDescriptionTr = '',
    this.phH2O = 6.8,
  });
}

class FieldEnvData {
  final double temperatureC;
  final double phH2O;
  final double weeklyRainMm;
  final double humidity;

  const FieldEnvData({
    this.temperatureC = 20.0,
    this.phH2O = 6.5,
    this.weeklyRainMm = 0.0,
    this.humidity = 50.0,
  });
}

class WeatherSoilService {
  const WeatherSoilService();

  static const _openMeteoTimeout = Duration(seconds: 8);
  static const _soilGridsTimeout = Duration(seconds: 10);

  static String _wmoCodeToTr(int code) {
    if (code == 0) return 'açık';
    if (code == 1) return 'az bulutlu';
    if (code == 2) return 'parçalı bulutlu';
    if (code == 3) return 'kapalı';
    if (code == 45 || code == 48) return 'sisli';
    if (code >= 51 && code <= 57) return 'çisenti';
    if (code >= 61 && code <= 67) return 'yağmurlu';
    if (code >= 71 && code <= 77) return 'karlı';
    if (code >= 80 && code <= 82) return 'sağanak';
    if (code >= 85 && code <= 86) return 'kar sağanağı';
    if (code >= 95) return 'gök gürültülü fırtına';
    return '';
  }

  Future<DashboardConditions> fetchDashboardConditions({
    required double latitude,
    required double longitude,
  }) async {
    List<http.Response?> results = [null, null];
    try {
      results = await Future.wait([
        http
            .get(Uri.parse(
              'https://api.open-meteo.com/v1/forecast?latitude=$latitude&longitude=$longitude&current=temperature_2m,relative_humidity_2m,wind_speed_10m,weather_code&wind_speed_unit=ms&timezone=auto',
            ))
            .timeout(_openMeteoTimeout),
        http
            .get(Uri.parse(
              'https://rest.isric.org/soilgrids/v2.0/properties/query?lon=$longitude&lat=$latitude&property=phh2o&depth=0-5cm&value=mean',
            ))
            .timeout(_soilGridsTimeout),
      ]);
    } catch (_) {
      return const DashboardConditions();
    }

    double? temp;
    int? humidity;
    double? wind;
    String desc = '';
    final weatherRes = results[0];
    if (weatherRes != null && weatherRes.statusCode == 200) {
      final cur = jsonDecode(weatherRes.body)['current'];
      temp = (cur['temperature_2m'] as num?)?.toDouble();
      humidity = (cur['relative_humidity_2m'] as num?)?.round();
      wind = (cur['wind_speed_10m'] as num?)?.toDouble();
      desc = _wmoCodeToTr((cur['weather_code'] as num?)?.toInt() ?? 0);
    }

    double ph = 6.8;
    final soilRes = results[1];
    if (soilRes != null && soilRes.statusCode == 200) {
      final data = jsonDecode(soilRes.body);
      final val = data['properties']?['layers']?[0]?['depths']?[0]?['values']?['mean'];
      if (val != null) ph = (val as num).toDouble() / 10.0;
    }

    return DashboardConditions(
      temperatureC: temp,
      humidity: humidity,
      windSpeedMs: wind,
      weatherDescriptionTr: desc,
      phH2O: ph,
    );
  }

  Future<FieldEnvData> fetchFieldEnv({
    required double latitude,
    required double longitude,
  }) async {
    double temp = 20, ph = 6.5, rain = 0, humidity = 50;

    await Future.wait([
      () async {
        try {
          final r = await http
              .get(Uri.parse(
                'https://api.open-meteo.com/v1/forecast?latitude=$latitude&longitude=$longitude&current=temperature_2m,relative_humidity_2m&timezone=auto',
              ))
              .timeout(_openMeteoTimeout);
          if (r.statusCode == 200) {
            final cur = jsonDecode(r.body)['current'];
            temp = (cur['temperature_2m'] as num?)?.toDouble() ?? temp;
            humidity = (cur['relative_humidity_2m'] as num?)?.toDouble() ?? humidity;
          }
        } catch (_) {}
      }(),
      () async {
        try {
          final r = await http
              .get(Uri.parse(
                'https://rest.isric.org/soilgrids/v2.0/properties/query?lon=$longitude&lat=$latitude&property=phh2o&depth=0-5cm&value=mean',
              ))
              .timeout(_soilGridsTimeout);
          if (r.statusCode == 200) {
            final v = jsonDecode(r.body)['properties']?['layers']?[0]?['depths']?[0]?['values']?['mean'];
            if (v != null) ph = (v as num).toDouble() / 10.0;
          }
        } catch (_) {}
      }(),
      () async {
        try {
          final r = await http
              .get(Uri.parse(
                'https://api.open-meteo.com/v1/forecast?latitude=$latitude&longitude=$longitude&daily=precipitation_sum&timezone=auto',
              ))
              .timeout(_openMeteoTimeout);
          if (r.statusCode == 200) {
            final rains = jsonDecode(r.body)['daily']['precipitation_sum'] as List;
            final len = rains.length < 7 ? rains.length : 7;
            for (int i = 0; i < len; i++) {
              rain += (rains[i] as num).toDouble();
            }
          }
        } catch (_) {}
      }(),
    ]);

    return FieldEnvData(
      temperatureC: temp,
      phH2O: ph,
      weeklyRainMm: rain,
      humidity: humidity,
    );
  }
}
