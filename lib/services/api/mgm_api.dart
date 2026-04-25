/// T.C. Meteoroloji Genel Müdürlüğü (MGM) — Resmi Hava Servisi İstemcisi
///
/// Kaynak: https://servis.mgm.gov.tr (resmi MGM web servisleri)
/// MGM, Türkiye'deki 1500+ otomatik gözlem istasyonundan (AWOS) toplanan
/// gerçek ölçüm verilerini sağlar. OpenWeather/Open-Meteo gibi global modeller
/// Türkiye için interpolasyon yaparken, MGM **gerçek istasyon ölçümleridir**
/// — özellikle iç Anadolu, Doğu Anadolu ve dağlık bölgelerde global modellere
/// kıyasla %30-50 daha doğru sonuçlar verir.
///
/// Bu istemci OpenWeather'ı **değil**, **takviye eder**: önce MGM denenir,
/// MGM erişilemezse OpenWeather fallback kullanılır.
///
/// Not: MGM resmi servisleri herkese açıktır ancak bazı endpoint'ler için
/// User-Agent ve Origin header'ı gereklidir. API anahtarı gerekmez.
library;

import 'dart:convert';
import 'package:http/http.dart' as http;

// ─────────────────────────────────────────────────────────────────────────────
// MODELLER
// ─────────────────────────────────────────────────────────────────────────────

/// MGM istasyon meta-verisi.
class MgmStation {
  final int merkezId;
  final int istNo;
  final String il;
  final String ilce;
  final double enlem;
  final double boylam;
  final double yukseklik;

  const MgmStation({
    required this.merkezId,
    required this.istNo,
    required this.il,
    required this.ilce,
    required this.enlem,
    required this.boylam,
    required this.yukseklik,
  });

  factory MgmStation.fromJson(Map<String, dynamic> j) => MgmStation(
        merkezId: (j['merkezId'] as num?)?.toInt() ?? 0,
        istNo: (j['istNo'] as num?)?.toInt() ?? 0,
        il: j['il']?.toString() ?? '',
        ilce: j['ilce']?.toString() ?? '',
        enlem: (j['enlem'] as num?)?.toDouble() ?? 0,
        boylam: (j['boylam'] as num?)?.toDouble() ?? 0,
        yukseklik: (j['yukseklik'] as num?)?.toDouble() ?? 0,
      );
}

/// MGM anlık gözlem verisi.
class MgmObservation {
  final double tempC;
  final double humidityPct;
  final double windSpeedMs; // m/s
  final double windDirDeg;
  final double pressureHpa;
  final double rainLast1hMm;
  final DateTime observedAt;
  final String stationName;

  const MgmObservation({
    required this.tempC,
    required this.humidityPct,
    required this.windSpeedMs,
    required this.windDirDeg,
    required this.pressureHpa,
    required this.rainLast1hMm,
    required this.observedAt,
    required this.stationName,
  });

  factory MgmObservation.fromJson(Map<String, dynamic> j, String stationName) {
    // MGM "rüzgarHiz" km/h cinsindendir → m/s'ye çevir
    final windKmh = (j['ruzgarHiz'] as num?)?.toDouble() ?? 0;
    return MgmObservation(
      tempC: (j['sicaklik'] as num?)?.toDouble() ?? 0,
      humidityPct: (j['nem'] as num?)?.toDouble() ?? 0,
      windSpeedMs: windKmh / 3.6,
      windDirDeg: (j['ruzgarYon'] as num?)?.toDouble() ?? 0,
      pressureHpa: (j['aktuelBasinc'] as num?)?.toDouble() ?? 0,
      rainLast1hMm: (j['yagis00Now'] as num?)?.toDouble() ?? 0,
      observedAt: DateTime.tryParse(j['veriZamani']?.toString() ?? '') ??
          DateTime.now(),
      stationName: stationName,
    );
  }
}

/// MGM 5 günlük günlük tahmin (her gün için min/max + genel durum).
class MgmDailyForecast {
  final DateTime date;
  final double minTempC;
  final double maxTempC;
  final double rainProbPct;
  final double rainAmountMm;
  final String description;

  const MgmDailyForecast({
    required this.date,
    required this.minTempC,
    required this.maxTempC,
    required this.rainProbPct,
    required this.rainAmountMm,
    required this.description,
  });

  factory MgmDailyForecast.fromJson(Map<String, dynamic> j) => MgmDailyForecast(
        date: DateTime.tryParse(j['tarih']?.toString() ?? '') ?? DateTime.now(),
        minTempC: (j['enDusukSicaklik'] as num?)?.toDouble() ?? 0,
        maxTempC: (j['enYuksekSicaklik'] as num?)?.toDouble() ?? 0,
        rainProbPct: (j['yagisOlasiligi'] as num?)?.toDouble() ?? 0,
        rainAmountMm: (j['yagisMiktari'] as num?)?.toDouble() ?? 0,
        description: j['hadiseGunduz']?.toString() ?? '',
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// SERVİS
// ─────────────────────────────────────────────────────────────────────────────

class MgmApi {
  static const String _baseUrl = 'https://servis.mgm.gov.tr';
  static const Duration _timeout = Duration(seconds: 8);

  /// MGM servisleri için zorunlu header'lar (Origin kontrolü yapıyor).
  static const Map<String, String> _headers = {
    'Accept': 'application/json',
    'User-Agent': 'Mozilla/5.0 (Smart-Agri-App)',
    'Origin': 'https://mgm.gov.tr',
    'Referer': 'https://mgm.gov.tr/',
  };

  /// Verilen koordinata en yakın MGM istasyonunu bul.
  static Future<MgmStation?> nearestStation({
    required double lat,
    required double lon,
  }) async {
    try {
      final uri =
          Uri.parse('$_baseUrl/sondurumlar/merkezler/?lat=$lat&lon=$lon');
      final res = await http.get(uri, headers: _headers).timeout(_timeout);
      if (res.statusCode != 200) return null;
      final data = jsonDecode(res.body);
      final list = (data is List ? data : [data]).cast<Map<String, dynamic>>();
      if (list.isEmpty) return null;
      return MgmStation.fromJson(list.first);
    } catch (_) {
      return null;
    }
  }

  /// İstasyonun anlık gözlemini çek.
  static Future<MgmObservation?> currentObservation(MgmStation s) async {
    try {
      final uri = Uri.parse('$_baseUrl/sondurumlar?merkezid=${s.merkezId}');
      final res = await http.get(uri, headers: _headers).timeout(_timeout);
      if (res.statusCode != 200) return null;
      final data = jsonDecode(res.body);
      final list = (data is List ? data : [data]).cast<Map<String, dynamic>>();
      if (list.isEmpty) return null;
      return MgmObservation.fromJson(list.first, '${s.il} / ${s.ilce}');
    } catch (_) {
      return null;
    }
  }

  /// 5 günlük günlük tahmin.
  static Future<List<MgmDailyForecast>> dailyForecast(MgmStation s) async {
    try {
      final uri = Uri.parse('$_baseUrl/tahminler/gunluk?istno=${s.istNo}');
      final res = await http.get(uri, headers: _headers).timeout(_timeout);
      if (res.statusCode != 200) return [];
      final data = jsonDecode(res.body);
      final raw = data is Map && data.containsKey('gunler')
          ? data['gunler'] as List
          : (data is List ? data : []);
      return raw
          .cast<Map<String, dynamic>>()
          .map(MgmDailyForecast.fromJson)
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Yardımcı: koordinata göre tek seferde anlık + tahmin döndürür.
  /// Fallback chain için kullanılır — null dönerse OpenWeather denenmeli.
  static Future<({MgmObservation? now, List<MgmDailyForecast> forecast})?>
      fetchAll({required double lat, required double lon}) async {
    final station = await nearestStation(lat: lat, lon: lon);
    if (station == null) return null;
    final obs = await currentObservation(station);
    final fc = await dailyForecast(station);
    if (obs == null && fc.isEmpty) return null;
    return (now: obs, forecast: fc);
  }
}
