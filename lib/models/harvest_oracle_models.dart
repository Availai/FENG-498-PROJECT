/// Agri-Matrix — Hasat Zamanlayıcı Modelleri
library;

import '../services/offline_rule_engine.dart' show RiskLevel;

// ─────────────────────────────────────────────────────────────────────────────
// TÜRK HAVA OLAYLARI
// ─────────────────────────────────────────────────────────────────────────────

enum TurkishWeatherEvent {
  lodos, // Trakya'ya özgü — GB rüzgar >6 m/s + sıcaklık artışı
  don, // <3°C gece sıcaklığı
  dolu, // Konvektif yağış + ani temp düşüşü
  asiriSicaklik, // >38°C
  kuvvetliYagis, // >30 mm / 6 saat
  kuvvetliRuzgar, // >10 m/s
  sisli, // Görüş mesafesi <200 m (hasat makinesi çalışamaz)
  yuksekNem, // >90% nem — mantar riski + hasat güçlüğü
}

extension TurkishWeatherEventMeta on TurkishWeatherEvent {
  String get labelTr {
    const m = {
      TurkishWeatherEvent.lodos: 'Lodos',
      TurkishWeatherEvent.don: 'Don Riski',
      TurkishWeatherEvent.dolu: 'Dolu',
      TurkishWeatherEvent.asiriSicaklik: 'Aşırı Sıcaklık',
      TurkishWeatherEvent.kuvvetliYagis: 'Kuvvetli Yağış',
      TurkishWeatherEvent.kuvvetliRuzgar: 'Kuvvetli Rüzgar',
      TurkishWeatherEvent.sisli: 'Sis',
      TurkishWeatherEvent.yuksekNem: 'Yüksek Nem',
    };
    return m[this]!;
  }

  String get emoji {
    const m = {
      TurkishWeatherEvent.lodos: '🌬️',
      TurkishWeatherEvent.don: '❄️',
      TurkishWeatherEvent.dolu: '⛈️',
      TurkishWeatherEvent.asiriSicaklik: '🔥',
      TurkishWeatherEvent.kuvvetliYagis: '🌧️',
      TurkishWeatherEvent.kuvvetliRuzgar: '💨',
      TurkishWeatherEvent.sisli: '🌫️',
      TurkishWeatherEvent.yuksekNem: '💧',
    };
    return m[this]!;
  }

  RiskLevel get defaultRisk {
    switch (this) {
      case TurkishWeatherEvent.lodos:
      case TurkishWeatherEvent.don:
      case TurkishWeatherEvent.dolu:
      case TurkishWeatherEvent.asiriSicaklik:
        return RiskLevel.critical;
      case TurkishWeatherEvent.kuvvetliYagis:
      case TurkishWeatherEvent.kuvvetliRuzgar:
      case TurkishWeatherEvent.yuksekNem:
        return RiskLevel.warning;
      case TurkishWeatherEvent.sisli:
        return RiskLevel.info;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HAVA OLAYI UYARISI
// ─────────────────────────────────────────────────────────────────────────────

class WeatherEventAlert {
  final TurkishWeatherEvent event;
  final DateTime detectedAt; // Olayın başlangıç saati (tahmin)
  final String descriptionTr; // 'Lodos: 225° / 8.4 m/s, sıcaklık 5°C artıyor'
  final String actionTr; // 'Hasadı 2 gün öne çek'
  final RiskLevel riskLevel;
  final int hoursAhead; // Kaç saat sonra bekleniyor

  const WeatherEventAlert({
    required this.event,
    required this.detectedAt,
    required this.descriptionTr,
    required this.actionTr,
    required this.riskLevel,
    required this.hoursAhead,
  });

  String get urgencyLabel {
    if (hoursAhead <= 6) return '⚠️ ACİL — ${hoursAhead}s içinde';
    if (hoursAhead <= 24) return '🟡 Bugün — ${hoursAhead}s içinde';
    final days = (hoursAhead / 24).ceil();
    return '🔵 $days gün içinde';
  }

  Map<String, dynamic> toMap() => {
        'event': event.labelTr,
        'at': detectedAt.toIso8601String(),
        'description': descriptionTr,
        'action': actionTr,
        'risk': riskLevel.name,
        'hours_ahead': hoursAhead,
      };
}

// ─────────────────────────────────────────────────────────────────────────────
// HASAT PENCERESİ
// ─────────────────────────────────────────────────────────────────────────────

class HarvestWindow {
  final DateTime windowStart;
  final DateTime windowEnd;
  final double confidenceScore; // 0.0–1.0
  final double avgTempC;
  final double totalRainMm;
  final double avgWindMs;
  final double avgHumidityPct;
  final List<WeatherEventAlert> alerts;
  final String recommendationTr;

  const HarvestWindow({
    required this.windowStart,
    required this.windowEnd,
    required this.confidenceScore,
    required this.avgTempC,
    required this.totalRainMm,
    required this.avgWindMs,
    required this.avgHumidityPct,
    required this.alerts,
    required this.recommendationTr,
  });

  bool get isOptimal => confidenceScore >= 0.72 && alerts.isEmpty;
  bool get hasRisk => alerts.any((a) => a.riskLevel == RiskLevel.critical);

  String get confidenceLabel {
    if (confidenceScore >= 0.80) return 'Mükemmel';
    if (confidenceScore >= 0.65) return 'İyi';
    if (confidenceScore >= 0.50) return 'Orta';
    return 'Riskli';
  }

  String get daysLabel {
    final diff = windowStart.difference(DateTime.now()).inDays;
    if (diff <= 0) return 'Bugün';
    if (diff == 1) return 'Yarın';
    return '$diff gün sonra';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SAATLİK TAHMİN KAYDI
// ─────────────────────────────────────────────────────────────────────────────

class HourlyForecastRecord {
  final DateTime time;
  final double tempC;
  final double precipMm;
  final double windSpeedMs;
  final double windDirDeg;
  final double precipProbPct;
  final double humidityPct;

  const HourlyForecastRecord({
    required this.time,
    required this.tempC,
    required this.precipMm,
    required this.windSpeedMs,
    required this.windDirDeg,
    required this.precipProbPct,
    required this.humidityPct,
  });
}
