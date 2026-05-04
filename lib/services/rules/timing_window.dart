import '../weather_soil_service.dart' show HourlyForecast, HourlySlot;
import 'recommendation.dart';

/// Tavsiye türüne göre uygun zaman penceresi üreten saf fonksiyon kümesi.
///
/// Üç katmanlı strateji:
///   1. Saatlik forecast varsa: ilk 12 saat içinde uygun **ardışık** pencere
///      ara (yağış sağladığı eşiğin altı, sıcaklık aralığı vb.).
///   2. Forecast yoksa: agronomik pencere (örn. sulama için sabah 06-10)
///      tarihsiz "descriptor only" döner.
///   3. Hiçbiri uygun değilse `null` — UI rozet çizmez.
class TimingWindow {
  TimingWindow._();

  /// Sulama: önümüzdeki 12 saatte yağmur <2 mm; sabah 06-10 öncelikli.
  static RecommendationTiming? forIrrigation({
    required DateTime now,
    HourlyForecast? hourly,
  }) {
    final slot = _findCalmSlot(
      hourly: hourly,
      now: now,
      maxRainMmPerHour: 1.5,
      preferStartHour: 6,
      preferEndHour: 10,
      lengthHours: 4,
    );
    if (slot != null) {
      return RecommendationTiming(
        windowStart: slot.start,
        windowEnd: slot.end,
        descriptor: _formatHourRange(slot.start, slot.end),
        source: 'forecast',
      );
    }
    return const RecommendationTiming(
      descriptor: 'Sabah 06:00–10:00 arası ideal',
      source: 'agronomic',
    );
  }

  /// İlaçlama: yağmur <0.5 mm, sıcaklık 16-28°C; rüzgâr verisi snapshotta —
  /// burada sadece forecast bazlı yağış/sıcaklık kontrolü yapılır. Rüzgâr
  /// kontrolünü çağıran kural [RuleEnvironmentSnapshot] ile yapar.
  static RecommendationTiming? forSpraying({
    required DateTime now,
    HourlyForecast? hourly,
  }) {
    final slot = _findCalmSlot(
      hourly: hourly,
      now: now,
      maxRainMmPerHour: 0.5,
      minTempC: 16,
      maxTempC: 28,
      preferStartHour: 6,
      preferEndHour: 10,
      lengthHours: 3,
    );
    if (slot != null) {
      return RecommendationTiming(
        windowStart: slot.start,
        windowEnd: slot.end,
        descriptor:
            '${_formatHourRange(slot.start, slot.end)} (rüzgâr <4 m/s)',
        source: 'forecast',
      );
    }
    return const RecommendationTiming(
      descriptor: 'Rüzgâr <4 m/s, sıcaklık 16–28°C, sakin saatte',
      source: 'agronomic',
    );
  }

  /// Hasat: önümüzdeki 24 saatte toplam yağmur <5 mm.
  static RecommendationTiming? forHarvest({
    required DateTime now,
    HourlyForecast? hourly,
  }) {
    if (hourly != null && !hourly.isEmpty) {
      final rain24 = hourly.rainSumNext(24);
      if (rain24 < 5) {
        return RecommendationTiming(
          windowStart: now,
          windowEnd: now.add(const Duration(hours: 24)),
          descriptor: '24 saat içinde uygun (yağış <5 mm)',
          source: 'forecast',
        );
      }
      return RecommendationTiming(
        descriptor:
            '24 saatte ${rain24.toStringAsFixed(0)} mm yağış var — hasat ertelenebilir',
        source: 'forecast',
      );
    }
    return const RecommendationTiming(
      descriptor: 'Yağışsız, kuru güne planlayın',
      source: 'agronomic',
    );
  }

  /// Scouting: gün ışığında, sabah çiy kalktıktan sonra (07-11) veya akşam
  /// serini (16-19). Forecast'a gerek yok.
  static RecommendationTiming forScouting() {
    return const RecommendationTiming(
      descriptor: 'Sabah 07:00–11:00 veya akşam 16:00–19:00',
      source: 'agronomic',
    );
  }

  /// Gübreleme: 24-48 saat içinde 5-15 mm yağış varsa "kaplama gübresi"
  /// için ideal pencere; yoksa generic agronomik öneri.
  static RecommendationTiming? forFertilizing({
    required DateTime now,
    HourlyForecast? hourly,
  }) {
    if (hourly != null && !hourly.isEmpty) {
      final rain48 = hourly.rainSumNext(48);
      if (rain48 >= 5 && rain48 <= 15) {
        return RecommendationTiming(
          windowStart: now,
          windowEnd: now.add(const Duration(hours: 24)),
          descriptor:
              '48 saatte ${rain48.toStringAsFixed(0)} mm yağış bekleniyor — gübreleme öncesi ideal',
          source: 'forecast',
        );
      }
    }
    return const RecommendationTiming(
      descriptor: 'Sulama veya hafif yağıştan önce uygulayın',
      source: 'agronomic',
    );
  }

  /// Forecast içinde [lengthHours] uzunluğunda yağışın eşiğin altında
  /// olduğu, opsiyonel sıcaklık aralığında ardışık ilk pencereyi bulur.
  /// `preferStartHour..preferEndHour` saatleri içinde başlayan pencere
  /// önceliklidir; bulunamazsa eşit kriterli ilk pencere döner.
  static _SlotRange? _findCalmSlot({
    required HourlyForecast? hourly,
    required DateTime now,
    required double maxRainMmPerHour,
    double? minTempC,
    double? maxTempC,
    int? preferStartHour,
    int? preferEndHour,
    required int lengthHours,
  }) {
    if (hourly == null || hourly.isEmpty) return null;
    final slots = hourly.slots;
    final cutoff = slots.length < 12 ? slots.length : 12;
    bool ok(HourlySlot s) {
      if (s.rainMm > maxRainMmPerHour) return false;
      if (minTempC != null && s.tempC < minTempC) return false;
      if (maxTempC != null && s.tempC > maxTempC) return false;
      return true;
    }

    _SlotRange? best;
    for (int i = 0; i + lengthHours <= cutoff; i++) {
      bool windowOk = true;
      for (int j = i; j < i + lengthHours; j++) {
        if (!ok(slots[j])) {
          windowOk = false;
          i = j; // skip ahead
          break;
        }
      }
      if (!windowOk) continue;
      final start = slots[i].hour;
      final end = slots[i + lengthHours - 1]
          .hour
          .add(const Duration(hours: 1));
      final candidate = _SlotRange(start: start, end: end);
      if (preferStartHour != null && preferEndHour != null) {
        final hr = start.hour;
        if (hr >= preferStartHour && hr <= preferEndHour) return candidate;
      }
      best ??= candidate;
    }
    return best;
  }

  static String _formatHourRange(DateTime start, DateTime end) {
    String fmt(DateTime t) =>
        '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
    return '${fmt(start)}–${fmt(end)}';
  }
}

class _SlotRange {
  final DateTime start;
  final DateTime end;
  const _SlotRange({required this.start, required this.end});
}
