/// MGM tarzı Zirai Don Alarmı (yerel).
///
/// Open-Meteo 3 günlük min sıcaklık tahminini çeker; Türkiye'nin geç ilkbahar
/// ve erken sonbahar don dönemlerinde (Nis-May + Eki-Kas) eşik altına iniş
/// varsa bildirim tetikler. Key gerektirmez.
library;

import 'dart:convert';
import 'package:http/http.dart' as http;
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
  /// Verilen koordinat için 3 günlük min sıcaklığı kontrol eder.
  /// Türkiye'nin hassas aylarında (4,5,10,11) düşük sıcaklık yakalanırsa
  /// uyarı döner. Dışarıdan takvime bağımlılık yok; testlenebilir.
  static Future<FrostAlarmResult> check({
    required double lat,
    required double lon,
    DateTime? now,
  }) async {
    final when = now ?? DateTime.now();
    final month = when.month;

    double min3Day = 99;
    try {
      final uri = Uri.parse(
        'https://api.open-meteo.com/v1/forecast?latitude=$lat&longitude=$lon'
        '&daily=temperature_2m_min&forecast_days=3&timezone=auto',
      );
      final resp = await http.get(uri).timeout(const Duration(seconds: 8));
      if (resp.statusCode == 200) {
        final mins = jsonDecode(resp.body)['daily']?['temperature_2m_min'];
        if (mins is List) {
          for (final v in mins) {
            if (v is num && v.toDouble() < min3Day) {
              min3Day = v.toDouble();
            }
          }
        }
      }
    } catch (_) {
      return const FrostAlarmResult(
        shouldAlert: false,
        min3DayC: 99,
        message: 'Tahmin verisi alınamadı.',
      );
    }

    final isSpringLate = month == 4 || month == 5;
    final isAutumnEarly = month == 10 || month == 11;
    final isSensitiveSeason = isSpringLate || isAutumnEarly;

    // MGM eşikleri: ≤0 don olayı, 0–2 don riski
    if (min3Day <= 0 && isSensitiveSeason) {
      return FrostAlarmResult(
        shouldAlert: true,
        min3DayC: min3Day,
        message:
            '3 gün içinde ${min3Day.toStringAsFixed(1)}°C don olayı bekleniyor. '
            '${isSpringLate ? "İlkbahar geç donu" : "Sonbahar erken donu"} — '
            'hassas bitkiler tehlikede.',
        actionHint:
            'Meyve ağaçlarında yağmurlama sulama, sera ısıtma ve örtü bezi hazırlayın.',
      );
    }
    if (min3Day <= 2 && isSensitiveSeason) {
      return FrostAlarmResult(
        shouldAlert: true,
        min3DayC: min3Day,
        message:
            '3 gün içinde ${min3Day.toStringAsFixed(1)}°C — MGM don riski eşiği (0-2°C).',
        actionHint:
            'Gece sabahına doğru 04:00-06:00 radyasyon donu gelebilir. '
            'Hassas ürünleri örtü altına alın.',
      );
    }

    return FrostAlarmResult(
      shouldAlert: false,
      min3DayC: min3Day,
      message: 'Önümüzdeki 3 günde don riski tespit edilmedi.',
    );
  }

  /// Bildirim göndererek uyarıyı çiftçiye iletir (fire-and-forget).
  static Future<void> checkAndNotify({
    required double lat,
    required double lon,
    String? fieldName,
  }) async {
    final r = await check(lat: lat, lon: lon);
    if (!r.shouldAlert) return;
    final title = fieldName != null
        ? 'Zirai Don Alarmı — $fieldName'
        : 'Zirai Don Alarmı';
    try {
      await NotificationService.show(
        id: 3001,
        title: title,
        body: r.message + (r.actionHint != null ? ' ${r.actionHint}' : ''),
      );
    } catch (_) {}
  }
}
