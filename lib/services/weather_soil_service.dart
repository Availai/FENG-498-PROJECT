import 'backend_service.dart';

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

  Future<DashboardConditions> fetchDashboardConditions({
    required double latitude,
    required double longitude,
  }) async {
    final env = await BackendService.fieldEnvironment(
      lat: latitude,
      lng: longitude,
    );
    if (env == null) return const DashboardConditions();

    return DashboardConditions(
      temperatureC: (env['temp'] as num?)?.toDouble(),
      humidity: (env['humidity'] as num?)?.round(),
      windSpeedMs: (env['wind'] as num?)?.toDouble(),
      weatherDescriptionTr: env['weather_desc']?.toString() ?? '',
      phH2O: (env['ph'] as num?)?.toDouble() ?? 6.8,
    );
  }

  Future<FieldEnvData> fetchFieldEnv({
    required double latitude,
    required double longitude,
  }) async {
    final env = await BackendService.fieldEnvironment(
      lat: latitude,
      lng: longitude,
    );
    if (env == null) return const FieldEnvData();

    return FieldEnvData(
      temperatureC: (env['temp'] as num?)?.toDouble() ?? 20.0,
      phH2O: (env['ph'] as num?)?.toDouble() ?? 6.5,
      weeklyRainMm: (env['total_weekly_rain'] as num?)?.toDouble() ?? 0.0,
      humidity: (env['humidity'] as num?)?.toDouble() ?? 50.0,
    );
  }
}
