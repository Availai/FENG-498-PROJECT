import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:feng_498/services/repositories/weather_repository.dart';

void main() {
  late Directory tempDir;
  late Box box;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('weather_repo_test_');
    Hive.init(tempDir.path);
    box = await Hive.openBox('settingsBox');
  });

  tearDown(() async {
    await box.close();
    await Hive.deleteFromDisk();
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('network success caches payload and returns fresh data', () async {
    final repository = WeatherRepository(
      settingsBox: box,
      satelliteWeatherFetcher: (lat, lon) async => {
        'current_temp': 24.5,
        'daily_forecast': <Map<String, dynamic>>[],
      },
    );

    final result = await repository.getSatelliteWeather(
      latitude: 40.1234,
      longitude: 29.9876,
    );

    expect(result.isStale, isFalse);
    expect(result.fromCache, isFalse);
    expect(result.data['current_temp'], 24.5);
    expect(result.lastUpdated, isNotNull);
  });

  test('network failure returns stale cache if present', () async {
    var shouldFail = false;
    final repository = WeatherRepository(
      settingsBox: box,
      satelliteWeatherFetcher: (lat, lon) async {
        if (shouldFail) {
          throw Exception('offline');
        }
        return {
          'current_temp': 20.0,
          'daily_forecast': <Map<String, dynamic>>[],
        };
      },
    );

    await repository.getSatelliteWeather(latitude: 41.0, longitude: 28.9);
    shouldFail = true;

    final staleResult = await repository.getSatelliteWeather(
      latitude: 41.0,
      longitude: 28.9,
    );

    expect(staleResult.isStale, isTrue);
    expect(staleResult.fromCache, isTrue);
    expect(staleResult.data['current_temp'], 20.0);
  });

  test('network failure without cache rethrows', () async {
    final repository = WeatherRepository(
      settingsBox: box,
      satelliteWeatherFetcher: (lat, lon) async {
        throw Exception('no network and no cache');
      },
    );

    expect(
      () => repository.getSatelliteWeather(latitude: 39.0, longitude: 27.0),
      throwsA(isA<Exception>()),
    );
  });
}
