import 'package:flutter/foundation.dart';

import 'backend_service.dart';

class CropRules {
  static const Duration _optionalBackendTimeout = Duration(seconds: 3);

  /// Deterministik ürün öneri motoru — Gemini kaldırıldı.
  /// Çevresel koşullara göre en uygun 5 ürünü sıralar.
  static Future<List<Map<String, dynamic>>> getDynamicRecommendations(
    double currentTemp,
    double ph,
    double avgWeeklyTemp,
    double totalWeeklyRain, {
    double soilMoisture = 0.0,
    double soilTempC = 0.0,
  }) async {
    final backendRecommendations = await BackendService.cropRecommendations({
      'temp': currentTemp,
      'ph': ph,
      'avg_weekly_temp': avgWeeklyTemp,
      'total_weekly_rain': totalWeeklyRain,
      'soil_moisture': soilMoisture,
      'soil_temp_c': soilTempC,
    }).timeout(_optionalBackendTimeout, onTimeout: () => null);
    if (backendRecommendations != null && backendRecommendations.isNotEmpty) {
      debugPrint('CropRules: backend önerileri kullanılıyor');
      return backendRecommendations;
    }

    debugPrint('CropRules: deterministik öneri hesaplanıyor');

    // Tüm aday bitkiler: [ad, minTemp, maxTemp, minPh, maxPh, minRain, maxRain, mevsim]
    final candidates = <Map<String, dynamic>>[
      _c('🍅 Domates', 15, 32, 5.5, 7.0, 10, 50, 'İlkbahar-Yaz'),
      _c('🌶️ Biber', 18, 32, 5.5, 7.0, 10, 45, 'İlkbahar-Yaz'),
      _c('🍆 Patlıcan', 18, 35, 5.5, 7.0, 10, 45, 'İlkbahar-Yaz'),
      _c('🥒 Salatalık', 18, 30, 6.0, 7.0, 15, 50, 'İlkbahar-Yaz'),
      _c('🌽 Mısır', 18, 35, 5.8, 7.0, 15, 60, 'Yaz'),
      _c('🥔 Patates', 10, 22, 5.0, 6.5, 20, 60, 'İlkbahar-Sonbahar'),
      _c('🧅 Soğan', 10, 28, 6.0, 7.5, 10, 40, 'İlkbahar-Sonbahar'),
      _c('🧄 Sarımsak', 5, 25, 6.0, 7.5, 10, 35, 'Sonbahar-İlkbahar'),
      _c('🥕 Havuç', 10, 24, 6.0, 7.0, 15, 45, 'İlkbahar-Sonbahar'),
      _c('🌾 Buğday', 5, 22, 6.0, 7.5, 10, 40, 'Sonbahar-İlkbahar'),
      _c('🫘 Fasulye', 16, 30, 6.0, 7.0, 15, 50, 'Yaz'),
      _c('🍓 Çilek', 10, 26, 5.5, 6.5, 20, 60, 'İlkbahar'),
      _c('🍉 Karpuz', 20, 35, 6.0, 7.0, 10, 35, 'Yaz'),
      _c('🍈 Kavun', 20, 35, 6.0, 7.5, 10, 35, 'Yaz'),
      _c('🥬 Ispanak', 5, 18, 6.0, 7.5, 15, 50, 'İlkbahar-Sonbahar'),
      _c('🥗 Marul', 8, 22, 6.0, 7.0, 15, 50, 'İlkbahar-Sonbahar'),
      _c('🎃 Kabak', 18, 32, 6.0, 7.5, 15, 50, 'Yaz'),
      _c('🌻 Ayçiçeği', 18, 35, 6.0, 7.5, 10, 40, 'Yaz'),
    ];

    for (final crop in candidates) {
      final double score = _score(
        crop,
        avgWeeklyTemp,
        ph,
        totalWeeklyRain,
        soilMoisture,
        soilTempC,
      );
      crop['uygunluk'] = score;

      final pHNote = ph < 5.5
          ? 'Acil: pH ${ph.toStringAsFixed(1)} çok asidik — ekimden önce dekara 200 kg tarım kireci uygulayın.'
          : ph > 7.5
              ? 'Acil: pH ${ph.toStringAsFixed(1)} bazik — dekara 30 kg kükürt uygulayın.'
              : 'pH ${ph.toStringAsFixed(1)} uygun aralıkta.';

      final rainNote = totalWeeklyRain > 50
          ? 'Bu hafta aşırı yağış (${totalWeeklyRain.round()} mm) — sulama durdurun, fungisit planlayın.'
          : totalWeeklyRain < 5
              ? 'Yağış çok az (${totalWeeklyRain.round()} mm) — sulama gerekli.'
              : 'Haftalık yağış (${totalWeeklyRain.round()} mm) yeterli.';

      crop['info'] =
          'Ort. ${avgWeeklyTemp.toStringAsFixed(1)}°C + pH ${ph.toStringAsFixed(1)} koşullarında '
          '${crop['name']} için uygunluk skoru %${score.round()}.';
      crop['fertilizer'] =
          '$pHNote Taban gübresi olarak dekara 20 kg 15-15-15 NPK önerilir.';
      crop['weather_impact'] = rainNote;
      crop['care_details'] =
          'Sıra arası 50-60 cm, bitki arası 30-40 cm. Sabah erken sulama önerilir.';
    }

    candidates.sort(
        (a, b) => (b['uygunluk'] as double).compareTo(a['uygunluk'] as double));

    return candidates.take(5).toList();
  }

  static Map<String, dynamic> _c(
    String name,
    double minT,
    double maxT,
    double minPh,
    double maxPh,
    double minRain,
    double maxRain,
    String season,
  ) =>
      {
        'name': name,
        'season': season,
        '_minT': minT,
        '_maxT': maxT,
        '_minPh': minPh,
        '_maxPh': maxPh,
        '_minRain': minRain,
        '_maxRain': maxRain,
        'uygunluk': 0.0,
        'info': '',
        'fertilizer': '',
        'weather_impact': '',
        'care_details': '',
      };

  static double _score(
    Map<String, dynamic> c,
    double temp,
    double ph,
    double rain,
    double soilMoisture,
    double soilTempC,
  ) {
    double s = 100.0;

    final minT = c['_minT'] as double;
    final maxT = c['_maxT'] as double;
    final minPh = c['_minPh'] as double;
    final maxPh = c['_maxPh'] as double;
    final minR = c['_minRain'] as double;
    final maxR = c['_maxRain'] as double;

    // Sıcaklık penaltısı
    if (temp < minT) s -= (minT - temp) * 4;
    if (temp > maxT) s -= (temp - maxT) * 4;

    // pH penaltısı
    if (ph < minPh) s -= (minPh - ph) * 12;
    if (ph > maxPh) s -= (ph - maxPh) * 12;

    // Yağış penaltısı
    if (rain < minR) s -= (minR - rain) * 1.5;
    if (rain > maxR) s -= (rain - maxR) * 1.5;

    // Toprak nemi bonusu/penaltısı
    if (soilMoisture > 0.45) s -= 10;
    if (soilMoisture < 0.10 && rain < 10) s -= 8;

    return s.clamp(0.0, 100.0);
  }
}
