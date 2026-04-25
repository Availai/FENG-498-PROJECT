/// HarvestOracle — Tahmine Dayalı Hasat Zamanlayıcı
///
/// API: Open-Meteo (ücretsiz, anahtar gerektirmez)
/// https://api.open-meteo.com/v1/forecast
///
/// Türkiye'ye özgü hava olayı tespiti:
///   • Lodos  — GB rüzgar (180-250°), >6 m/s, Trakya'ya özgü
///   • Don    — <3°C
///   • Dolu   — yağış +konvektif koşul
///   • AşırıSıcaklık, KuvvetliYağış, KuvvetliRüzgar, Sis, YüksekNem
library;

import '../models/harvest_oracle_models.dart';
import '../models/seed_models.dart';
import 'offline_rule_engine.dart' show RiskLevel;
import 'backend_service.dart';

class HarvestOracle {
  // ─────────────────────────────────────────────────────────────────────────
  // VERİ ÇEKME — OpenWeather önce, Open-Meteo fallback
  // ─────────────────────────────────────────────────────────────────────────

  static Future<List<HourlyForecastRecord>> fetchForecast({
    required double lat,
    required double lon,
  }) async {
    return _fetchBackendForecast(lat: lat, lon: lon);
  }

  static Future<List<HourlyForecastRecord>> _fetchBackendForecast({
    required double lat,
    required double lon,
  }) async {
    final hours = await BackendService.hourlyWeather(lat: lat, lng: lon);
    return hours.map((h) {
      return HourlyForecastRecord(
        time: DateTime.tryParse(h['time']?.toString() ?? '') ?? DateTime.now(),
        tempC: (h['temp'] as num?)?.toDouble() ?? 0.0,
        precipMm: (h['precip_mm'] as num?)?.toDouble() ?? 0.0,
        windSpeedMs: (h['wind'] as num?)?.toDouble() ?? 0.0,
        windDirDeg: (h['wind_dir'] as num?)?.toDouble() ?? 0.0,
        precipProbPct: (h['precip_prob'] as num?)?.toDouble() ?? 0.0,
        humidityPct: (h['humidity'] as num?)?.toDouble() ?? 0.0,
      );
    }).toList();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // TÜRK HAVA OLAYI TESPİTİ
  // ─────────────────────────────────────────────────────────────────────────

  static List<WeatherEventAlert> detectEvents({
    required List<HourlyForecastRecord> forecast,
    TurkishRegion region = TurkishRegion.trakya,
  }) {
    final alerts = <WeatherEventAlert>[];
    final now = DateTime.now();

    // Lodos penceresi: art arda 3+ saatte lodos koşulları
    if (region == TurkishRegion.trakya) {
      _detectLodos(forecast, now, alerts);
    }

    for (int i = 0; i < forecast.length; i++) {
      final h = forecast[i];
      final hoursAhead = h.time.difference(now).inHours;
      if (hoursAhead < 0) continue;

      // DON
      if (h.tempC <= 3.0 && (h.time.hour >= 22 || h.time.hour <= 7)) {
        if (!alerts.any((a) => a.event == TurkishWeatherEvent.don)) {
          alerts.add(WeatherEventAlert(
            event: TurkishWeatherEvent.don,
            detectedAt: h.time,
            descriptionTr: 'Gece sıcaklığı ${h.tempC.toStringAsFixed(1)}°C — don riski.',
            actionTr: 'Hassas bitkilerinizi örtün. Sulamayı sabah erken yapın.',
            riskLevel: RiskLevel.critical,
            hoursAhead: hoursAhead,
          ));
        }
      }

      // AŞIRI SICAKLIK
      if (h.tempC >= 38.0) {
        if (!alerts.any((a) => a.event == TurkishWeatherEvent.asiriSicaklik)) {
          alerts.add(WeatherEventAlert(
            event: TurkishWeatherEvent.asiriSicaklik,
            detectedAt: h.time,
            descriptionTr: '${h.tempC.toStringAsFixed(1)}°C — aşırı sıcaklık.',
            actionTr: 'Hasadı serin saatlere (06:00-09:00) alın. Sulama artırın.',
            riskLevel: RiskLevel.critical,
            hoursAhead: hoursAhead,
          ));
        }
      }

      // KUVVETLİ RÜZGAR (lodos değil)
      if (h.windSpeedMs >= 10.0 &&
          !(h.windDirDeg >= 180 && h.windDirDeg <= 250)) {
        if (!alerts.any((a) => a.event == TurkishWeatherEvent.kuvvetliRuzgar)) {
          alerts.add(WeatherEventAlert(
            event: TurkishWeatherEvent.kuvvetliRuzgar,
            detectedAt: h.time,
            descriptionTr: '${h.windSpeedMs.toStringAsFixed(1)} m/s rüzgar.',
            actionTr: 'Hasat makinesi çalışmasını erteleyin. Hasat döküntüsü artar.',
            riskLevel: RiskLevel.warning,
            hoursAhead: hoursAhead,
          ));
        }
      }

      // YÜKSEK NEM
      if (h.humidityPct >= 90.0 && h.tempC >= 15) {
        if (!alerts.any((a) => a.event == TurkishWeatherEvent.yuksekNem)) {
          alerts.add(WeatherEventAlert(
            event: TurkishWeatherEvent.yuksekNem,
            detectedAt: h.time,
            descriptionTr: 'Nem %${h.humidityPct.round()} — hasat sonrası kurutma maliyeti artar.',
            actionTr: 'Hasat öncesi 24s bekleyin. Tarlada havalandırma artırın.',
            riskLevel: RiskLevel.warning,
            hoursAhead: hoursAhead,
          ));
        }
      }
    }

    // KUVVETLİ YAĞIŞ — 6 saatlik pencerede >30 mm
    _detectHeavyRain(forecast, now, alerts);

    // DOLU tahmini (basit heuristic: yüksek precip_prob + temp <15 + summer)
    _detectHail(forecast, now, alerts);

    alerts.sort((a, b) => a.hoursAhead.compareTo(b.hoursAhead));
    return alerts;
  }

  static void _detectLodos(
    List<HourlyForecastRecord> forecast,
    DateTime now,
    List<WeatherEventAlert> alerts,
  ) {
    int consecutiveHours = 0;
    HourlyForecastRecord? firstHour;
    double maxWind = 0;

    for (final h in forecast) {
      if (h.time.isBefore(now)) continue;
      final isLodos = h.windDirDeg >= 175 &&
          h.windDirDeg <= 255 &&
          h.windSpeedMs >= 6.0;
      if (isLodos) {
        consecutiveHours++;
        firstHour ??= h;
        if (h.windSpeedMs > maxWind) maxWind = h.windSpeedMs;
        if (consecutiveHours >= 3) {
          final hoursAhead = firstHour.time.difference(now).inHours;
          alerts.add(WeatherEventAlert(
            event: TurkishWeatherEvent.lodos,
            detectedAt: firstHour.time,
            descriptionTr: 'Lodos: ${firstHour.windDirDeg.round()}° / '
                '${maxWind.toStringAsFixed(1)} m/s — Trakya\'ya yaklaşıyor.',
            actionTr: 'Hasadı ${hoursAhead < 12 ? "acilen" : "2 gün"} öne çekmeyi değerlendirin. '
                'Seri ürün tablalarda dökülme riski yüksek.',
            riskLevel: maxWind > 10 ? RiskLevel.critical : RiskLevel.warning,
            hoursAhead: hoursAhead,
          ));
          return;
        }
      } else {
        consecutiveHours = 0;
        firstHour = null;
      }
    }
  }

  static void _detectHeavyRain(
    List<HourlyForecastRecord> forecast,
    DateTime now,
    List<WeatherEventAlert> alerts,
  ) {
    for (int i = 0; i < forecast.length - 6; i++) {
      if (forecast[i].time.isBefore(now)) continue;
      double sum6h = 0;
      for (int j = i; j < i + 6 && j < forecast.length; j++) {
        sum6h += forecast[j].precipMm;
      }
      if (sum6h >= 30.0) {
        final hoursAhead = forecast[i].time.difference(now).inHours;
        alerts.add(WeatherEventAlert(
          event: TurkishWeatherEvent.kuvvetliYagis,
          detectedAt: forecast[i].time,
          descriptionTr: '6 saatte ${sum6h.toStringAsFixed(1)} mm yağış bekleniyor.',
          actionTr: 'Hasat ertelensin. Tarla araçları çamurda mahsur kalabilir.',
          riskLevel: RiskLevel.critical,
          hoursAhead: hoursAhead,
        ));
        return;
      }
    }
  }

  static void _detectHail(
    List<HourlyForecastRecord> forecast,
    DateTime now,
    List<WeatherEventAlert> alerts,
  ) {
    final month = now.month;
    if (month < 4 || month > 9) return; // Kış aylarında dolu nadir

    for (final h in forecast) {
      if (h.time.isBefore(now)) continue;
      // Heuristic: yüksek yağış olasılığı + gün içi sıcaklık yüksek + nemli
      if (h.precipProbPct >= 70 &&
          h.tempC >= 20 &&
          h.humidityPct >= 65 &&
          (h.time.hour >= 12 && h.time.hour <= 18)) {
        final hoursAhead = h.time.difference(now).inHours;
        if (!alerts.any((a) => a.event == TurkishWeatherEvent.dolu)) {
          alerts.add(WeatherEventAlert(
            event: TurkishWeatherEvent.dolu,
            detectedAt: h.time,
            descriptionTr: 'Konvektif koşullar: dolu riski yüksek.',
            actionTr: 'Hasat makinesini korumaya alın. Açık alanlardaki ürünleri örtün.',
            riskLevel: RiskLevel.critical,
            hoursAhead: hoursAhead,
          ));
        }
        return;
      }
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // HASAT PENCERESİ HESAPLAMA
  // ─────────────────────────────────────────────────────────────────────────

  static List<HarvestWindow> findOptimalWindows({
    required List<HourlyForecastRecord> forecast,
    required int remainingDays,
    required SeedVariety variety,
  }) {
    if (forecast.isEmpty) return [];
    final windows = <HarvestWindow>[];
    final now = DateTime.now();
    final windowHours = 72; // 3 günlük pencere

    for (int start = 0; start + windowHours <= forecast.length; start += 24) {
      final slice = forecast.sublist(start, start + windowHours);
      if (slice.first.time.isBefore(now)) continue;

      double totalRain = 0, totalTemp = 0, totalWind = 0, totalHum = 0;
      for (final h in slice) {
        totalRain += h.precipMm;
        totalTemp += h.tempC;
        totalWind += h.windSpeedMs;
        totalHum  += h.humidityPct;
      }
      final avgTemp = totalTemp / windowHours;
      final avgWind = totalWind / windowHours;
      final avgHum  = totalHum  / windowHours;

      // Skor hesabı (0-1)
      double score = 0.70;
      if (totalRain < 5)    score += 0.15;
      if (totalRain < 1)    score += 0.05;
      if (avgTemp >= 18 && avgTemp <= 30) score += 0.08;
      if (avgWind < 4)      score += 0.05;
      if (avgHum < 70)      score += 0.05;
      if (avgHum > 85)      score -= 0.15;
      if (totalRain > 20)   score -= 0.20;
      if (avgTemp > 38)     score -= 0.25;
      score = score.clamp(0.0, 1.0);

      final windowAlerts = detectEvents(
        forecast: slice,
        region: variety.suitableRegions.isNotEmpty
            ? variety.suitableRegions.first
            : TurkishRegion.icAnadolu,
      ).where((a) => a.riskLevel == RiskLevel.critical).toList();

      final daysLabel = slice.first.time.difference(now).inDays;
      String rec;
      if (score >= 0.80 && windowAlerts.isEmpty) {
        rec = '✅ Mükemmel pencere. $daysLabel gün sonra hasat başlatılabilir.';
      } else if (score >= 0.65 && windowAlerts.isEmpty) {
        rec = '🟡 İyi pencere. Yağış riski düşük. $daysLabel gün sonra başlayın.';
      } else if (windowAlerts.isNotEmpty) {
        rec = '⚠️ ${windowAlerts.first.actionTr}';
      } else {
        rec = '🔴 Riskli pencere. Alternatif tarih arayın.';
      }

      windows.add(HarvestWindow(
        windowStart:      slice.first.time,
        windowEnd:        slice.last.time,
        confidenceScore:  score,
        avgTempC:         avgTemp,
        totalRainMm:      totalRain,
        avgWindMs:        avgWind,
        avgHumidityPct:   avgHum,
        alerts:           windowAlerts,
        recommendationTr: rec,
      ));

      if (windows.length >= 5) break; // En fazla 5 pencere sun
    }

    windows.sort((a, b) => b.confidenceScore.compareTo(a.confidenceScore));
    return windows;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // TAM ANALİZ (tek çağrı)
  // ─────────────────────────────────────────────────────────────────────────

  static Future<({
    List<WeatherEventAlert> alerts,
    List<HarvestWindow> windows,
    List<HourlyForecastRecord> forecast,
  })> analyze({
    required double lat,
    required double lon,
    required SeedVariety variety,
    required int remainingDays,
    TurkishRegion region = TurkishRegion.trakya,
  }) async {
    final forecast = await fetchForecast(lat: lat, lon: lon);
    final alerts  = detectEvents(forecast: forecast, region: region);
    final windows = findOptimalWindows(
      forecast: forecast,
      remainingDays: remainingDays,
      variety: variety,
    );
    return (alerts: alerts, windows: windows, forecast: forecast);
  }
}
