/// Hava + toprak koşulları servisi.
///
/// Üç-katmanlı strateji (jet hızında ana ekran için):
///   1. Hive cache'den **anlık** okuma — UI ilk frame'de değer görür.
///   2. Backend `/api/proxy/environment/field` (6s timeout)
///   3. Backend yetişmezse doğrudan Open-Meteo (4s timeout) — offline-first
///   4. Yeni veri Hive'a yazılır, cache 30 dk'ya kadar geçerli sayılır.
library;

import 'dart:async';
import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;

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

  bool get isEmpty =>
      temperatureC == null && humidity == null && windSpeedMs == null;

  Map<String, dynamic> toJson() => {
        'temp': temperatureC,
        'humidity': humidity,
        'wind': windSpeedMs,
        'weather_desc': weatherDescriptionTr,
        'ph': phH2O,
      };

  factory DashboardConditions.fromJson(Map<String, dynamic> j) {
    return DashboardConditions(
      temperatureC: (j['temp'] as num?)?.toDouble(),
      humidity: (j['humidity'] as num?)?.toInt(),
      windSpeedMs: (j['wind'] as num?)?.toDouble(),
      weatherDescriptionTr: j['weather_desc']?.toString() ?? '',
      phH2O: (j['ph'] as num?)?.toDouble() ?? 6.8,
    );
  }
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

/// 48 saatlik saatlik forecast — don/aşırı sıcak/aşırı yağmur tespiti için.
class HourlyForecast {
  /// Saatlik veriler — her giriş bir saat. İlk giriş "şu an"a en yakın saat.
  final List<HourlySlot> slots;
  final DateTime fetchedAt;

  const HourlyForecast({required this.slots, required this.fetchedAt});

  bool get isEmpty => slots.isEmpty;

  /// Önümüzdeki [hours] saat içinde min sıcaklık (°C). Boşsa null.
  double? minTempNext(int hours) {
    if (slots.isEmpty) return null;
    final n = slots.length < hours ? slots.length : hours;
    double m = slots.first.tempC;
    for (int i = 0; i < n; i++) {
      if (slots[i].tempC < m) m = slots[i].tempC;
    }
    return m;
  }

  /// Önümüzdeki [hours] saat içinde max sıcaklık (°C). Boşsa null.
  double? maxTempNext(int hours) {
    if (slots.isEmpty) return null;
    final n = slots.length < hours ? slots.length : hours;
    double m = slots.first.tempC;
    for (int i = 0; i < n; i++) {
      if (slots[i].tempC > m) m = slots[i].tempC;
    }
    return m;
  }

  /// Önümüzdeki [hours] saat boyunca toplam yağmur (mm).
  double rainSumNext(int hours) {
    if (slots.isEmpty) return 0;
    final n = slots.length < hours ? slots.length : hours;
    double sum = 0;
    for (int i = 0; i < n; i++) {
      sum += slots[i].rainMm;
    }
    return sum;
  }
}

class HourlySlot {
  final DateTime hour;
  final double tempC;
  final double rainMm;
  final double humidity;

  const HourlySlot({
    required this.hour,
    required this.tempC,
    required this.rainMm,
    required this.humidity,
  });

  Map<String, dynamic> toJson() => {
        't': hour.toIso8601String(),
        'c': tempC,
        'r': rainMm,
        'h': humidity,
      };

  factory HourlySlot.fromJson(Map<String, dynamic> j) => HourlySlot(
        hour: DateTime.tryParse(j['t']?.toString() ?? '') ?? DateTime.now(),
        tempC: (j['c'] as num?)?.toDouble() ?? 0,
        rainMm: (j['r'] as num?)?.toDouble() ?? 0,
        humidity: (j['h'] as num?)?.toDouble() ?? 0,
      );
}

class WeatherSoilService {
  const WeatherSoilService();

  static const _cacheBox = 'settingsBox';
  static const _cachePrefix = 'weather_cache_';
  // Forecast 10 dakika cache: hava değişikliği rehbere hızlı yansır.
  // Eski 30 dk değerinde yağmur tahmini değişince direktif geç fark ediyordu.
  static const _cacheTtl = Duration(minutes: 10);
  static const _hourlyCachePrefix = 'weather_hourly_cache_';
  static const _hourlyCacheTtl = Duration(minutes: 30);

  static String _cacheKey(double lat, double lng) =>
      '$_cachePrefix${lat.toStringAsFixed(2)}_${lng.toStringAsFixed(2)}';

  /// Cache'den hızlı okuma — UI ilk frame'de boş kalmasın diye.
  /// Tazelik kontrolü yapılmaz; caller arka planda yenisini ister.
  DashboardConditions? readCachedConditions({
    required double latitude,
    required double longitude,
  }) {
    if (!Hive.isBoxOpen(_cacheBox)) return null;
    final box = Hive.box(_cacheBox);
    final raw = box.get(_cacheKey(latitude, longitude));
    if (raw is! Map) return null;
    try {
      return DashboardConditions.fromJson(Map<String, dynamic>.from(raw));
    } catch (_) {
      return null;
    }
  }

  bool isCacheFresh({required double latitude, required double longitude}) {
    if (!Hive.isBoxOpen(_cacheBox)) return false;
    final box = Hive.box(_cacheBox);
    final tsRaw = box.get('${_cacheKey(latitude, longitude)}_ts');
    if (tsRaw is! int) return false;
    final age = DateTime.now().millisecondsSinceEpoch - tsRaw;
    return age < _cacheTtl.inMilliseconds;
  }

  Future<void> _writeCache(
    double latitude,
    double longitude,
    DashboardConditions cond,
  ) async {
    if (!Hive.isBoxOpen(_cacheBox)) return;
    final box = Hive.box(_cacheBox);
    final key = _cacheKey(latitude, longitude);
    await box.put(key, cond.toJson());
    await box.put('${key}_ts', DateTime.now().millisecondsSinceEpoch);
  }

  Future<DashboardConditions> fetchDashboardConditions({
    required double latitude,
    required double longitude,
  }) async {
    // 1) Backend ile direkt Open-Meteo'yu **yarıştır** — hangisi önce
    //    bitirirse onu kullan. Backend açıksa zenginleşmiş veri (toprak pH
    //    dahil) gelir; kapalıysa direkt Open-Meteo en geç 4s'de döner.
    DashboardConditions? backendResult;
    DashboardConditions? directResult;

    final backendFuture = BackendService.fieldEnvironment(
      lat: latitude,
      lng: longitude,
    ).then((env) {
      if (env == null) return;
      backendResult = DashboardConditions(
        temperatureC: (env['temp'] as num?)?.toDouble(),
        humidity: (env['humidity'] as num?)?.round(),
        windSpeedMs: (env['wind'] as num?)?.toDouble(),
        weatherDescriptionTr: env['weather_desc']?.toString() ?? '',
        phH2O: (env['ph'] as num?)?.toDouble() ?? 6.8,
      );
    });

    final directFuture = _fetchOpenMeteoDirect(latitude, longitude).then((d) {
      directResult = d;
    });

    // İlk biten cevabı kullan; backend daha zenginse onu tercih ederiz ama
    // 4s'den fazla beklemiyoruz.
    try {
      await Future.any([
        backendFuture,
        // Direkt cevap geldiğinde backend hala bekliyor olabilir; max
        // 4 saniye bekledikten sonra direkt sonuca düşeriz.
        directFuture.then(
            (_) => Future<void>.delayed(const Duration(milliseconds: 100))),
        Future<void>.delayed(const Duration(seconds: 4)),
      ]);
    } catch (_) {}

    final result = backendResult ?? directResult ?? const DashboardConditions();
    if (!result.isEmpty) {
      // Cache'le — sonraki açılışlar instant.
      unawaited(_writeCache(latitude, longitude, result));
    }

    // Backend hala bitmediyse arka planda bitsin, gelecek için cache'lensin.
    unawaited(backendFuture.then((_) {
      if (backendResult != null && !backendResult!.isEmpty) {
        unawaited(_writeCache(latitude, longitude, backendResult!));
      }
    }).catchError((_) {}));

    return result;
  }

  /// Doğrudan Open-Meteo — backend kapalıyken offline-first fallback.
  Future<DashboardConditions?> _fetchOpenMeteoDirect(
    double lat,
    double lng,
  ) async {
    try {
      final uri = Uri.parse(
        'https://api.open-meteo.com/v1/forecast'
        '?latitude=$lat&longitude=$lng'
        '&current=temperature_2m,relative_humidity_2m,wind_speed_10m,weather_code'
        '&wind_speed_unit=ms&timezone=auto',
      );
      final resp = await http.get(uri).timeout(const Duration(seconds: 4));
      if (resp.statusCode != 200) return null;

      final body = jsonDecode(resp.body) as Map<String, dynamic>;
      final cur = (body['current'] as Map?)?.cast<String, dynamic>() ?? {};
      final code = (cur['weather_code'] as num?)?.toInt() ?? 0;

      return DashboardConditions(
        temperatureC: (cur['temperature_2m'] as num?)?.toDouble(),
        humidity: (cur['relative_humidity_2m'] as num?)?.round(),
        windSpeedMs: (cur['wind_speed_10m'] as num?)?.toDouble(),
        weatherDescriptionTr: _wmoTr(code),
      );
    } catch (_) {
      return null;
    }
  }

  /// 48 saatlik saatlik forecast — Open-Meteo'dan doğrudan alınır.
  /// Cache TTL: 30 dakika (saatlik veri günde 1-2 kez yeterli).
  /// Don alarmı, aşırı yağmur, aşırı sıcak için kullanılır.
  Future<HourlyForecast> fetchHourlyForecast({
    required double latitude,
    required double longitude,
  }) async {
    final box = Hive.isBoxOpen(_cacheBox) ? Hive.box(_cacheBox) : null;
    final key = '$_hourlyCachePrefix${latitude.toStringAsFixed(2)}_${longitude.toStringAsFixed(2)}';

    // Cache fresh mi?
    if (box != null) {
      final tsRaw = box.get('${key}_ts');
      if (tsRaw is int) {
        final age = DateTime.now().millisecondsSinceEpoch - tsRaw;
        if (age < _hourlyCacheTtl.inMilliseconds) {
          final raw = box.get(key);
          if (raw is List) {
            final slots = raw
                .whereType<Map>()
                .map((e) => HourlySlot.fromJson(Map<String, dynamic>.from(e)))
                .toList();
            return HourlyForecast(
              slots: slots,
              fetchedAt: DateTime.fromMillisecondsSinceEpoch(tsRaw),
            );
          }
        }
      }
    }

    try {
      final uri = Uri.parse(
        'https://api.open-meteo.com/v1/forecast'
        '?latitude=$latitude&longitude=$longitude'
        '&hourly=temperature_2m,precipitation,relative_humidity_2m'
        '&forecast_days=2&timezone=auto',
      );
      final resp = await http.get(uri).timeout(const Duration(seconds: 6));
      if (resp.statusCode != 200) return _emptyForecast();

      final body = jsonDecode(resp.body) as Map<String, dynamic>;
      final hourly = (body['hourly'] as Map?)?.cast<String, dynamic>() ?? {};
      final times = (hourly['time'] as List?) ?? const [];
      final temps = (hourly['temperature_2m'] as List?) ?? const [];
      final rains = (hourly['precipitation'] as List?) ?? const [];
      final hums = (hourly['relative_humidity_2m'] as List?) ?? const [];

      final now = DateTime.now();
      final slots = <HourlySlot>[];
      for (int i = 0; i < times.length; i++) {
        final t = DateTime.tryParse(times[i].toString());
        if (t == null) continue;
        // Sadece şu an ve sonrası
        if (t.isBefore(now.subtract(const Duration(hours: 1)))) continue;
        slots.add(HourlySlot(
          hour: t,
          tempC: i < temps.length ? (temps[i] as num).toDouble() : 0,
          rainMm: i < rains.length ? (rains[i] as num).toDouble() : 0,
          humidity: i < hums.length ? (hums[i] as num).toDouble() : 0,
        ));
        if (slots.length >= 48) break;
      }

      if (box != null && slots.isNotEmpty) {
        await box.put(key, slots.map((s) => s.toJson()).toList());
        await box.put('${key}_ts', DateTime.now().millisecondsSinceEpoch);
      }

      return HourlyForecast(slots: slots, fetchedAt: DateTime.now());
    } catch (_) {
      return _emptyForecast();
    }
  }

  HourlyForecast _emptyForecast() =>
      HourlyForecast(slots: const [], fetchedAt: DateTime.now());

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

/// WMO Weather Code → Türkçe açıklama (özet).
/// Kaynak: https://open-meteo.com/en/docs (WMO 4677)
String _wmoTr(int code) {
  if (code == 0) return 'Açık';
  if (code <= 2) return 'Az bulutlu';
  if (code == 3) return 'Bulutlu';
  if (code == 45 || code == 48) return 'Sisli';
  if (code >= 51 && code <= 57) return 'Çiseleme';
  if (code >= 61 && code <= 67) return 'Yağmurlu';
  if (code >= 71 && code <= 77) return 'Karlı';
  if (code >= 80 && code <= 82) return 'Sağanak';
  if (code >= 85 && code <= 86) return 'Kar sağanağı';
  if (code >= 95 && code <= 99) return 'Fırtınalı';
  return '';
}
