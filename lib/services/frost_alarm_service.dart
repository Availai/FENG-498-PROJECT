import 'backend_service.dart';
import 'notification_service.dart';
import 'weather_soil_service.dart';

class FrostAlarmResult {
  final bool shouldAlert;
  final double min3DayC;
  final String message;
  final String? actionHint;
  /// Min sıcaklığa kaç saat var (saatlik forecast'tan). Null = günlük veri.
  final int? hoursToMin;

  const FrostAlarmResult({
    required this.shouldAlert,
    required this.min3DayC,
    required this.message,
    this.actionHint,
    this.hoursToMin,
  });
}

class FrostAlarmService {
  static Future<FrostAlarmResult> check({
    required double lat,
    required double lon,
    DateTime? now,
  }) async {
    final when = now ?? DateTime.now();
    final month = when.month;

    // Önce saatlik forecast dene — daha hassas (gece tepe yakalar).
    int? hoursToMin;
    double min3Day = 99;
    try {
      final hourly = const WeatherSoilService()
          .fetchHourlyForecast(latitude: lat, longitude: lon);
      final hf = await hourly;
      if (!hf.isEmpty) {
        final m = hf.minTempNext(48);
        if (m != null) {
          min3Day = m;
          // Min sıcaklığın hangi saatte olduğunu bul
          for (int i = 0; i < hf.slots.length && i < 48; i++) {
            if (hf.slots[i].tempC == m) {
              hoursToMin = hf.slots[i].hour.difference(when).inHours;
              break;
            }
          }
        }
      }
    } catch (_) {}

    // Saatlik başarısızsa backend daily fallback
    if (min3Day == 99) {
      final env = await BackendService.fieldEnvironment(lat: lat, lng: lon);
      if (env == null) {
        return const FrostAlarmResult(
          shouldAlert: false,
          min3DayC: 99,
          message: 'Tahmin verisi alınamadı.',
        );
      }
      final days = (env['daily_forecast'] as List?) ?? const [];
      for (final day in days.take(3)) {
        if (day is Map && day['min'] is num) {
          final value = (day['min'] as num).toDouble();
          if (value < min3Day) min3Day = value;
        }
      }
    }

    final isSensitiveSeason =
        month == 4 || month == 5 || month == 10 || month == 11;
    final whenStr = hoursToMin != null
        ? (hoursToMin < 24
            ? '$hoursToMin saat içinde'
            : '${(hoursToMin / 24).floor()} gün içinde')
        : '3 gün içinde';
    if (min3Day <= 0 && isSensitiveSeason) {
      return FrostAlarmResult(
        shouldAlert: true,
        min3DayC: min3Day,
        hoursToMin: hoursToMin,
        message:
            '$whenStr ${min3Day.toStringAsFixed(1)}°C don olayı bekleniyor.',
        actionHint:
            'Meyve ağaçlarında yağmurlama sulama, sera ısıtma ve örtü bezi hazırlayın.',
      );
    }
    if (min3Day <= 2 && isSensitiveSeason) {
      return FrostAlarmResult(
        shouldAlert: true,
        min3DayC: min3Day,
        hoursToMin: hoursToMin,
        message:
            '$whenStr ${min3Day.toStringAsFixed(1)}°C MGM don riski eşiği görüldü.',
        actionHint: 'Gece sabahına doğru hassas ürünleri örtü altına alın.',
      );
    }

    return FrostAlarmResult(
      shouldAlert: false,
      min3DayC: min3Day,
      hoursToMin: hoursToMin,
      message: 'Önümüzdeki 48 saatte don riski tespit edilmedi.',
    );
  }

  static Future<void> checkAndNotify({
    required double lat,
    required double lon,
    String? fieldName,
    String? fieldId,
  }) async {
    final result = await check(lat: lat, lon: lon);
    if (!result.shouldAlert) return;
    final title = fieldName != null
        ? 'Zirai Don Alarmı - $fieldName'
        : 'Zirai Don Alarmı';
    final payload = (fieldId != null && fieldId.isNotEmpty)
        ? '{"type":"guide","fieldId":"$fieldId","fieldName":"${fieldName ?? ''}"}'
        : null;
    try {
      await NotificationService.show(
        id: 3001,
        title: title,
        body: result.message +
            (result.actionHint != null ? ' ${result.actionHint}' : ''),
        payload: payload,
      );
    } catch (_) {}
  }
}
