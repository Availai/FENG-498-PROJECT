/// Agromonitoring API — Satellite NDVI + soil sensor data
///
/// Requires AGROMONITORING_API_KEY in .env
/// Docs: https://agromonitoring.com/api
library;

import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

// ─────────────────────────────────────────────────────────────────────────────
// MODELLER
// ─────────────────────────────────────────────────────────────────────────────

class AgroPolygon {
  final String id;
  final String name;
  final List<List<double>> coordinates; // [[lon,lat], ...]

  const AgroPolygon({required this.id, required this.name, required this.coordinates});

  factory AgroPolygon.fromJson(Map<String, dynamic> j) {
    final coords = ((j['geo_json']['geometry']['coordinates'] as List).first as List)
        .map((c) => (c as List).cast<double>())
        .toList();
    return AgroPolygon(
      id: j['id'] as String,
      name: j['name'] as String? ?? '',
      coordinates: coords,
    );
  }
}

class NdviRecord {
  final DateTime date;
  final double ndviMean;
  final double ndviMin;
  final double ndviMax;
  final String? imageUrl;

  const NdviRecord({
    required this.date,
    required this.ndviMean,
    required this.ndviMin,
    required this.ndviMax,
    this.imageUrl,
  });

  factory NdviRecord.fromJson(Map<String, dynamic> j) {
    final stats = j['data'] as Map<String, dynamic>?;
    return NdviRecord(
      date: DateTime.fromMillisecondsSinceEpoch((j['dt'] as int) * 1000),
      ndviMean: (stats?['mean'] as num?)?.toDouble() ?? 0,
      ndviMin: (stats?['min'] as num?)?.toDouble() ?? 0,
      ndviMax: (stats?['max'] as num?)?.toDouble() ?? 0,
      imageUrl: j['image']?['ndvi'] as String?,
    );
  }

  String get healthLabel {
    if (ndviMean > 0.6) return 'Çok İyi';
    if (ndviMean > 0.4) return 'İyi';
    if (ndviMean > 0.2) return 'Orta';
    if (ndviMean > 0.0) return 'Zayıf';
    return 'Bitki Örtüsü Yok';
  }

  String get actionTr {
    if (ndviMean < 0.2) return 'Kritik: Sulama, gübreleme veya hastalık kontrolü yapın.';
    if (ndviMean < 0.4) return 'Uyarı: Azot gübrelemesi veya sulama değerlendirin.';
    return 'Bitki örtüsü sağlıklı — rutin bakım yeterli.';
  }
}

class SoilSensorData {
  final DateTime measuredAt;
  final double t0;   // surface temp °C
  final double t10;  // 10 cm depth temp °C
  final double moisture;  // 0-1
  final double conductivity; // S/m

  const SoilSensorData({
    required this.measuredAt,
    required this.t0,
    required this.t10,
    required this.moisture,
    required this.conductivity,
  });

  factory SoilSensorData.fromJson(Map<String, dynamic> j) {
    return SoilSensorData(
      measuredAt: DateTime.fromMillisecondsSinceEpoch((j['dt'] as int) * 1000),
      t0: (j['t0'] as num?)?.toDouble() ?? 0,
      t10: (j['t10'] as num?)?.toDouble() ?? 0,
      moisture: (j['moisture'] as num?)?.toDouble() ?? 0,
      conductivity: (j['c0'] as num?)?.toDouble() ?? 0,
    );
  }

  double get moisturePct => moisture * 100;

  String get moistureLabel {
    if (moisturePct > 70) return 'Yüksek — sulama gerekmiyor';
    if (moisturePct > 40) return 'Yeterli';
    if (moisturePct > 20) return 'Düşük — sulama planlayın';
    return 'Kritik — acil sulama';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SERVİS
// ─────────────────────────────────────────────────────────────────────────────

class AgromonitoringApi {
  static const _base = 'https://agromonitoring.com/agro/1.0';
  static const _timeout = Duration(seconds: 12);

  static String get _key {
    final k = dotenv.env['AGROMONITORING_API_KEY'] ?? '';
    if (k.isEmpty) throw Exception('AGROMONITORING_API_KEY not set in .env');
    return k;
  }

  // ── Tarla Yönetimi ────────────────────────────────────────────────────────

  /// Mevcut tarlaları listele
  static Future<List<AgroPolygon>> listPolygons() async {
    final uri = Uri.parse('$_base/polygons?appid=$_key');
    final resp = await http.get(uri).timeout(_timeout);
    if (resp.statusCode != 200) throw Exception('Agromonitoring polygons: HTTP ${resp.statusCode}');
    final list = (jsonDecode(resp.body) as List).cast<Map<String, dynamic>>();
    return list.map(AgroPolygon.fromJson).toList();
  }

  /// Yeni tarla oluştur (koordinat listesi: [[lon,lat], ...])
  static Future<String> createPolygon({
    required String name,
    required List<List<double>> coords,
  }) async {
    final uri = Uri.parse('$_base/polygons?appid=$_key');
    final body = {
      'name': name,
      'geo_json': {
        'type': 'Feature',
        'properties': <String, dynamic>{},
        'geometry': {
          'type': 'Polygon',
          'coordinates': [coords],
        },
      },
    };
    final resp = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    ).timeout(_timeout);
    if (resp.statusCode != 201) throw Exception('Agromonitoring createPolygon: HTTP ${resp.statusCode}');
    return (jsonDecode(resp.body) as Map<String, dynamic>)['id'] as String;
  }

  // ── NDVI ─────────────────────────────────────────────────────────────────

  /// Son 30 günün NDVI geçmişini getir
  static Future<List<NdviRecord>> ndviHistory({
    required String polygonId,
    int daysBack = 30,
  }) async {
    final end = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final start = DateTime.now().subtract(Duration(days: daysBack)).millisecondsSinceEpoch ~/ 1000;
    final uri = Uri.parse(
      '$_base/ndvi/history?polyid=$polygonId&start=$start&end=$end&appid=$_key',
    );
    final resp = await http.get(uri).timeout(_timeout);
    if (resp.statusCode != 200) throw Exception('Agromonitoring NDVI: HTTP ${resp.statusCode}');
    final list = (jsonDecode(resp.body) as List).cast<Map<String, dynamic>>();
    return list.map(NdviRecord.fromJson).toList()..sort((a, b) => a.date.compareTo(b.date));
  }

  /// En son NDVI değerini getir
  static Future<NdviRecord?> latestNdvi(String polygonId) async {
    final records = await ndviHistory(polygonId: polygonId, daysBack: 15);
    return records.isEmpty ? null : records.last;
  }

  // ── Toprak Sensörü ────────────────────────────────────────────────────────

  /// Uydu tabanlı toprak nem/sıcaklık tahmini
  static Future<SoilSensorData?> soilData({
    required double lat,
    required double lon,
  }) async {
    final uri = Uri.parse('$_base/soil?lon=$lon&lat=$lat&appid=$_key');
    final resp = await http.get(uri).timeout(_timeout);
    if (resp.statusCode != 200) return null;
    return SoilSensorData.fromJson(jsonDecode(resp.body) as Map<String, dynamic>);
  }

  // ── Çapraz Analiz ─────────────────────────────────────────────────────────

  /// NDVI + Soil kombinasyonu → Türkçe öneri üret
  static String crossAnalysisTr({
    required NdviRecord ndvi,
    required SoilSensorData soil,
  }) {
    final parts = <String>[];

    // NDVI sağlık kontrolü
    if (ndvi.ndviMean < 0.3) {
      parts.add('🚨 NDVI düşük (${ndvi.ndviMean.toStringAsFixed(2)}) — Bitki stresi var.');
    }

    // Toprak nemi + NDVI çapraz kontrol
    if (soil.moisturePct < 25 && ndvi.ndviMean < 0.4) {
      parts.add('⚠️ Hem toprak kuru hem bitki örtüsü zayıf — sulama kritik.');
    } else if (soil.moisturePct > 75 && ndvi.ndviMean < 0.3) {
      parts.add('🔎 Toprak nemli ama bitki zayıf — hastalık veya kök çürümesi olabilir.');
    }

    // Toprak sıcaklığı
    if (soil.t10 < 8) {
      parts.add('❄️ Toprak sıcaklığı düşük (${soil.t10.toStringAsFixed(0)}°C) — çimlenme yavaşlayabilir.');
    } else if (soil.t10 > 35) {
      parts.add('🔥 Toprak aşırı sıcak (${soil.t10.toStringAsFixed(0)}°C) — kök yanması riski.');
    }

    if (parts.isEmpty) {
      return '✅ Toprak ve bitki örtüsü normal seyirde.';
    }
    return parts.join('\n');
  }
}
