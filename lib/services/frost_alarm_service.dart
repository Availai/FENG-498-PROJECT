import 'backend_service.dart';
import 'notification_service.dart';

class FrostAlarmResult {
  final bool shouldAlert;
  final double min3DayC;
  final String message;
  final String? actionHint;

  const FrostAlarmResult({
    required this.shouldAlert,
    required this.min3DayC,
    required this.message,
    this.actionHint,
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
    final env = await BackendService.fieldEnvironment(lat: lat, lng: lon);
    if (env == null) {
      return const FrostAlarmResult(
        shouldAlert: false,
        min3DayC: 99,
        message: 'Tahmin verisi alınamadı.',
      );
    }

    double min3Day = 99;
    final days = (env['daily_forecast'] as List?) ?? const [];
    for (final day in days.take(3)) {
      if (day is Map && day['min'] is num) {
        final value = (day['min'] as num).toDouble();
        if (value < min3Day) min3Day = value;
      }
    }

    final isSensitiveSeason =
        month == 4 || month == 5 || month == 10 || month == 11;
    if (min3Day <= 0 && isSensitiveSeason) {
      return FrostAlarmResult(
        shouldAlert: true,
        min3DayC: min3Day,
        message:
            '3 gün içinde ${min3Day.toStringAsFixed(1)}°C don olayı bekleniyor.',
        actionHint:
            'Meyve ağaçlarında yağmurlama sulama, sera ısıtma ve örtü bezi hazırlayın.',
      );
    }
    if (min3Day <= 2 && isSensitiveSeason) {
      return FrostAlarmResult(
        shouldAlert: true,
        min3DayC: min3Day,
        message:
            '3 gün içinde ${min3Day.toStringAsFixed(1)}°C MGM don riski eşiği görüldü.',
        actionHint: 'Gece sabahına doğru hassas ürünleri örtü altına alın.',
      );
    }

    return FrostAlarmResult(
      shouldAlert: false,
      min3DayC: min3Day,
      message: 'Önümüzdeki 3 günde don riski tespit edilmedi.',
    );
  }

  static Future<void> checkAndNotify({
    required double lat,
    required double lon,
    String? fieldName,
  }) async {
    final result = await check(lat: lat, lon: lon);
    if (!result.shouldAlert) return;
    final title = fieldName != null
        ? 'Zirai Don Alarmı - $fieldName'
        : 'Zirai Don Alarmı';
    try {
      await NotificationService.show(
        id: 3001,
        title: title,
        body: result.message +
            (result.actionHint != null ? ' ${result.actionHint}' : ''),
      );
    } catch (_) {}
  }
}
