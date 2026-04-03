import 'package:hive/hive.dart';

import '../agri_service.dart';

class SatelliteWeatherResult {
  const SatelliteWeatherResult({
    required this.data,
    required this.fromCache,
    required this.isStale,
    this.lastUpdated,
  });

  final Map<String, dynamic> data;
  final bool fromCache;
  final bool isStale;
  final DateTime? lastUpdated;
}

class WeatherRepository {
  WeatherRepository({
    required Box settingsBox,
  }) : _settingsBox = settingsBox;

  final Box _settingsBox;

  Future<SatelliteWeatherResult> getSatelliteWeather({
    required double latitude,
    required double longitude,
  }) async {
    final cacheKey = _cacheKey(latitude, longitude);

    try {
      final result = await AgriService.getSatelliteWeather(latitude, longitude);
      final now = DateTime.now().toUtc();
      await _settingsBox.put(cacheKey, {
        'data': result,
        'updated_at': now.toIso8601String(),
      });
      return SatelliteWeatherResult(
        data: result,
        fromCache: false,
        isStale: false,
        lastUpdated: now,
      );
    } catch (_) {
      final cachedRaw = _settingsBox.get(cacheKey);
      if (cachedRaw is! Map) rethrow;

      final cached = Map<String, dynamic>.from(cachedRaw);
      final rawData = cached['data'];
      if (rawData is! Map) rethrow;

      final updatedAt = DateTime.tryParse(cached['updated_at']?.toString() ?? '');
      return SatelliteWeatherResult(
        data: Map<String, dynamic>.from(rawData),
        fromCache: true,
        isStale: true,
        lastUpdated: updatedAt,
      );
    }
  }

  String _cacheKey(double latitude, double longitude) {
    final lat = latitude.toStringAsFixed(4);
    final lon = longitude.toStringAsFixed(4);
    return 'sat_weather_cache_v1_${lat}_$lon';
  }
}
