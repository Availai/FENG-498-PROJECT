/// Backend Service Façade — Tüm paralı/secret 3rd-party API çağrıları
/// için tek giriş noktası. API anahtarları sadece backend ortamında kalır.
///
/// Çevrimdışı-öncelikli ilke: Bu sınıf yalnızca dış servisler için kullanılır.
/// Çağrı başarısız olursa istemci tarafı [OfflineRuleEngine] gibi yerel
/// fallback'lere düşmelidir; bu sınıf sessiz fallback YAPMAZ.
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

typedef BackendAuthTokenProvider = Future<String?> Function();

class BackendException implements Exception {
  final int? statusCode;
  final String message;
  const BackendException(this.message, {this.statusCode});
  @override
  String toString() => 'BackendException($statusCode): $message';
}

class BackendService {
  // Background sync ile aynı emülatör adresi.
  // Üretimde flutter_dotenv üzerinden override edilebilir.
  static BackendAuthTokenProvider? _authTokenProvider;

  static void configure({BackendAuthTokenProvider? authTokenProvider}) {
    _authTokenProvider = authTokenProvider;
  }

  static String get _baseUrl =>
      dotenv.env['BACKEND_BASE_URL'] ?? 'http://10.0.2.2:8000';
  static const Duration _timeout = Duration(seconds: 25);

  static Uri _u(String path, [Map<String, dynamic>? query]) {
    final qp = query?.map((k, v) => MapEntry(k, v?.toString() ?? ''));
    return Uri.parse('$_baseUrl$path').replace(
      queryParameters: qp == null || qp.isEmpty ? null : qp,
    );
  }

  static Future<Map<String, String>> _headers({bool json = false}) async {
    final headers = <String, String>{};
    if (json) headers['Content-Type'] = 'application/json';
    final token = await _authTokenProvider?.call();
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  static Future<void> _addAuth(http.BaseRequest req) async {
    final token = await _authTokenProvider?.call();
    if (token != null && token.isNotEmpty) {
      req.headers['Authorization'] = 'Bearer $token';
    }
  }

  // ── PERENUAL — bitki türü detayı ────────────────────────────────────────
  static Future<Map<String, dynamic>> plantDetails({
    required String commonName,
    String scientificName = '',
  }) async {
    final resp = await http
        .get(
            _u('/api/proxy/plants/details', {
              'common_name': commonName,
              'scientific_name': scientificName,
            }),
            headers: await _headers())
        .timeout(_timeout);
    return _expectJson(resp)['data'] as Map<String, dynamic>? ?? {};
  }

  // ── IMAGGA — görüntü etiketleme ─────────────────────────────────────────
  static Future<List<String>> imaggaTags(File imageFile) async {
    final req = http.MultipartRequest('POST', _u('/api/proxy/vision/imagga'));
    await _addAuth(req);
    req.files.add(await http.MultipartFile.fromPath('image', imageFile.path));
    final streamed = await req.send().timeout(_timeout);
    final body = await streamed.stream.bytesToString();
    if (streamed.statusCode != 200) {
      throw BackendException('Imagga proxy hatası',
          statusCode: streamed.statusCode);
    }
    final json = jsonDecode(body) as Map<String, dynamic>;
    return (json['tags'] as List? ?? const []).cast<String>();
  }

  // ── PLANTNET — tür tanıma ───────────────────────────────────────────────
  /// Hata durumunda human-readable etiket ile [BackendException] fırlatır.
  static Future<Map<String, dynamic>> plantNetIdentify(File imageFile) async {
    final req = http.MultipartRequest('POST', _u('/api/proxy/vision/plantnet'));
    await _addAuth(req);
    req.files.add(await http.MultipartFile.fromPath('image', imageFile.path));
    final streamed = await req.send().timeout(_timeout);
    final body = await streamed.stream.bytesToString();
    if (streamed.statusCode == 429) {
      throw const BackendException('PlantNet günlük kota dolu',
          statusCode: 429);
    }
    if (streamed.statusCode != 200) {
      try {
        final errJson = jsonDecode(body) as Map<String, dynamic>;
        throw BackendException(
            errJson['detail']?.toString() ?? 'PlantNet hatası',
            statusCode: streamed.statusCode);
      } catch (_) {
        throw BackendException('PlantNet HTTP ${streamed.statusCode}',
            statusCode: streamed.statusCode);
      }
    }
    final json = jsonDecode(body) as Map<String, dynamic>;
    return (json['data'] as Map<String, dynamic>?) ?? {};
  }

  // ── GEMINI — hastalık tanısı ────────────────────────────────────────────
  static Future<Map<String, dynamic>> geminiDiagnose({
    required List<int> imageBytes,
    String commonName = '',
    String scientificName = '',
  }) async {
    final resp = await http
        .post(
          _u('/api/proxy/vision/diagnose'),
          headers: await _headers(json: true),
          body: jsonEncode({
            'image_b64': base64Encode(imageBytes),
            'common_name': commonName,
            'scientific_name': scientificName,
          }),
        )
        .timeout(_timeout);
    return _expectJson(resp);
  }

  // ── AGROMONITORING — toprak verisi ──────────────────────────────────────
  // Opsiyonel veri; dashboard'ı tutmasın — 6s'de gelmezse null dön.
  static Future<Map<String, double>?> satelliteSoil({
    required double lat,
    required double lng,
  }) async {
    try {
      final resp = await http
          .get(
              _u('/api/proxy/satellite/soil', {
                'lat': lat,
                'lng': lng,
              }),
              headers: await _headers())
          .timeout(const Duration(seconds: 6));
      if (resp.statusCode != 200) return null;
      final j = jsonDecode(resp.body) as Map<String, dynamic>;
      return {
        'soil_temp_c': (j['soil_temp_c'] as num).toDouble(),
        'moisture': (j['moisture'] as num).toDouble(),
      };
    } catch (_) {
      return null;
    }
  }

  // ── NASA POWER — tarihi iklim ───────────────────────────────────────────
  static Future<Map<String, dynamic>?> nasaPowerHistorical({
    required double lat,
    required double lng,
    required String startYyyymmdd,
    required String endYyyymmdd,
    String parameters = 'T2M,PRECTOTCORR,RH2M,WS2M',
  }) async {
    try {
      final resp = await http
          .get(
              _u('/api/proxy/climate/historical', {
                'lat': lat,
                'lng': lng,
                'start': startYyyymmdd,
                'end': endYyyymmdd,
                'parameters': parameters,
              }),
              headers: await _headers())
          .timeout(_timeout);
      if (resp.statusCode != 200) return null;
      final j = jsonDecode(resp.body) as Map<String, dynamic>;
      return j['data'] as Map<String, dynamic>?;
    } catch (_) {
      return null;
    }
  }

  // ── ANALYZE — deterministik metin üreticiler (offline fallback'li) ──────
  static Future<String?> analyzeFieldPlan(Map<String, dynamic> body) async {
    return _postText('/api/analyze/field_plan', body);
  }

  static Future<String?> analyzeWeeklyComment(Map<String, dynamic> body) async {
    return _postText('/api/analyze/weekly_comment', body);
  }

  static Future<String?> analyzeEnvironmentalReport(
      Map<String, dynamic> body) async {
    return _postText('/api/analyze/environmental_report', body);
  }

  // HAVA + TOPRAK — backend proxy. UI bu veriyi sadece cache/fallback olarak kullanır.
  // Dashboard'ı yavaşlatmamak için 6s sınırı; başarısızlıkta caller direkt
  // Open-Meteo'ya düşer (WeatherSoilService).
  static Future<Map<String, dynamic>?> fieldEnvironment({
    required double lat,
    required double lng,
  }) async {
    try {
      final resp = await http
          .get(
              _u('/api/proxy/environment/field', {
                'lat': lat,
                'lng': lng,
              }),
              headers: await _headers())
          .timeout(const Duration(seconds: 6));
      if (resp.statusCode != 200) return null;
      return jsonDecode(resp.body) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  static Future<List<Map<String, dynamic>>> hourlyWeather({
    required double lat,
    required double lng,
  }) async {
    try {
      final resp = await http
          .get(
              _u('/api/proxy/weather/hourly', {
                'lat': lat,
                'lng': lng,
              }),
              headers: await _headers())
          .timeout(_timeout);
      if (resp.statusCode != 200) return const [];
      final decoded = jsonDecode(resp.body) as Map<String, dynamic>;
      final items = (decoded['hours'] as List?) ??
          (decoded['hourly_forecast'] as List?) ??
          const [];
      return items
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  static Future<Map<String, dynamic>?> soilProfile({
    required double lat,
    required double lng,
  }) async {
    try {
      final resp = await http
          .get(
              _u('/api/proxy/soil/profile', {
                'lat': lat,
                'lng': lng,
              }),
              headers: await _headers())
          .timeout(_timeout);
      if (resp.statusCode != 200) return null;
      return jsonDecode(resp.body) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  static Future<Map<String, dynamic>?> fuelPrices({
    String city = 'ISTANBUL',
  }) async {
    try {
      final resp = await http
          .get(_u('/api/proxy/fuel/prices', {'city': city}),
              headers: await _headers())
          .timeout(_timeout);
      if (resp.statusCode != 200) return null;
      return jsonDecode(resp.body) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  static Future<List<Map<String, dynamic>>?> cropRecommendations(
    Map<String, dynamic> body,
  ) async {
    try {
      final resp = await http
          .post(
            _u('/api/analyze/crop_recommendations'),
            headers: await _headers(json: true),
            body: jsonEncode(body),
          )
          .timeout(_timeout);
      if (resp.statusCode != 200) return null;
      final decoded = jsonDecode(resp.body) as Map<String, dynamic>;
      final items = (decoded['recommendations'] as List?) ??
          (decoded['crops'] as List?) ??
          const [];
      return items
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    } catch (_) {
      return null;
    }
  }

  /// Risk analizi (rule engine). Çevrimdışı için çağıran taraf
  /// [OfflineRuleEngine.analyze]'a düşmelidir.
  static Future<List<Map<String, dynamic>>?> analyzeRisks(
      Map<String, dynamic> body) async {
    try {
      final resp = await http
          .post(
            _u('/api/analyze/risks'),
            headers: await _headers(json: true),
            body: jsonEncode(body),
          )
          .timeout(_timeout);
      if (resp.statusCode != 200) return null;
      final j = jsonDecode(resp.body) as Map<String, dynamic>;
      final results = (j['results'] as List?) ?? const [];
      return results.cast<Map<String, dynamic>>();
    } catch (_) {
      return null;
    }
  }

  // ── helpers ─────────────────────────────────────────────────────────────
  static Future<String?> _postText(
      String path, Map<String, dynamic> body) async {
    try {
      final resp = await http
          .post(
            _u(path),
            headers: await _headers(json: true),
            body: jsonEncode(body),
          )
          .timeout(_timeout);
      if (resp.statusCode != 200) return null;
      final j = jsonDecode(resp.body) as Map<String, dynamic>;
      return j['text']?.toString();
    } catch (_) {
      return null;
    }
  }

  static Map<String, dynamic> _expectJson(http.Response r) {
    if (r.statusCode != 200) {
      throw BackendException('Backend hatası', statusCode: r.statusCode);
    }
    return jsonDecode(r.body) as Map<String, dynamic>;
  }
}
