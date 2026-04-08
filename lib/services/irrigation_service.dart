/// Akıllı Sulama Programı servisi.
///
/// OpenWeather'dan 5 günlük tahmini çeker, backend'deki
/// /api/irrigation/schedule endpoint'ine gönderir ve günlük
/// sulama planını döndürür. Karar mantığı backend'deki
/// rule_engine.py üzerinden çalışır.
library;

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api/openweather_api.dart';

class IrrigationDayPlan {
  final DateTime date;
  final bool shouldIrrigate;
  final String level; // critical | warning | info | ok
  final String title;
  final String reason;
  final String recommendation;
  final double estimatedMm;
  final double etoMm;
  final double etcMm;
  final double kc;

  const IrrigationDayPlan({
    required this.date,
    required this.shouldIrrigate,
    required this.level,
    required this.title,
    required this.reason,
    required this.recommendation,
    required this.estimatedMm,
    required this.etoMm,
    required this.etcMm,
    required this.kc,
  });

  factory IrrigationDayPlan.fromJson(Map<String, dynamic> j) {
    return IrrigationDayPlan(
      date: DateTime.parse(j['date'] as String),
      shouldIrrigate: j['should_irrigate'] as bool? ?? false,
      level: j['level'] as String? ?? 'ok',
      title: j['title'] as String? ?? '',
      reason: j['reason'] as String? ?? '',
      recommendation: j['recommendation'] as String? ?? '',
      estimatedMm: ((j['estimated_mm'] as num?) ?? 0).toDouble(),
      etoMm: ((j['eto_mm'] as num?) ?? 0).toDouble(),
      etcMm: ((j['etc_mm'] as num?) ?? 0).toDouble(),
      kc: ((j['kc'] as num?) ?? 1).toDouble(),
    );
  }
}

class IrrigationSchedule {
  final int totalDays;
  final int irrigationDays;
  final double totalWaterMm;
  final double totalCropDemandMm;
  final double kcUsed;
  final String method;
  final List<IrrigationDayPlan> plan;

  const IrrigationSchedule({
    required this.totalDays,
    required this.irrigationDays,
    required this.totalWaterMm,
    required this.totalCropDemandMm,
    required this.kcUsed,
    required this.method,
    required this.plan,
  });
}

class IrrigationService {
  // Background sync ile aynı emülatör adresi.
  static const String _backendBase = 'http://10.0.2.2:8000';
  static const Duration _timeout = Duration(seconds: 15);

  /// Belirli bir tarla ve bitki için 7 günlük akıllı sulama programı üret.
  ///
  /// [soilMoisturePct] 0-100 aralığında.
  static Future<IrrigationSchedule> buildSchedule({
    required double lat,
    required double lon,
    required String cropTr,
    Map<String, dynamic>? plantDetails,
    double soilPh = 6.8,
    double soilMoisturePct = 25,
    double soilTempC = 15,
    double ndvi = 0.6,
  }) async {
    // 1) OpenWeather 5 günlük tahmini çek (3 saatlik noktalar) ve günlük özete dönüştür.
    final pts = await OpenWeatherApi.forecast5Day(lat: lat, lon: lon);
    final daily = OpenWeatherApi.aggregateDaily(pts);

    // 2) Backend payload'u hazırla.
    final days = daily.take(7).map((d) {
      final iso =
          '${d.date.year}-${d.date.month.toString().padLeft(2, '0')}-${d.date.day.toString().padLeft(2, '0')}';
      return {
        'date': iso,
        'temp_c': d.avgTempC,
        'humidity': d.avgHumidityPct,
        'precip_mm': d.totalPrecipMm,
        'precip_prob_pct': 0.0,
        'wind_speed_ms': d.maxWindMs,
      };
    }).toList();

    final body = {
      'common_name': cropTr,
      'plant_details': plantDetails ?? {},
      'soil_ph': soilPh,
      'soil_moisture': soilMoisturePct / 100.0,
      'soil_temp_c': soilTempC,
      'ndvi': ndvi,
      'days': days,
    };

    final uri = Uri.parse('$_backendBase/api/irrigation/schedule');
    final resp = await http
        .post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(body),
        )
        .timeout(_timeout);

    if (resp.statusCode != 200) {
      throw Exception('Sulama programı alınamadı (HTTP ${resp.statusCode}).');
    }

    final json = jsonDecode(resp.body) as Map<String, dynamic>;
    final summary = (json['summary'] as Map<String, dynamic>?) ?? {};
    final planList = (json['plan'] as List? ?? [])
        .cast<Map<String, dynamic>>()
        .map(IrrigationDayPlan.fromJson)
        .toList();

    return IrrigationSchedule(
      totalDays: (summary['total_days'] as num?)?.toInt() ?? planList.length,
      irrigationDays: (summary['irrigation_days'] as num?)?.toInt() ?? 0,
      totalWaterMm: ((summary['total_water_mm'] as num?) ?? 0).toDouble(),
      totalCropDemandMm:
          ((summary['total_crop_demand_mm'] as num?) ?? 0).toDouble(),
      kcUsed: ((summary['kc_used'] as num?) ?? 1).toDouble(),
      method: (summary['method'] as String?) ?? '',
      plan: planList,
    );
  }
}
