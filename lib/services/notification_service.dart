import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;

/// FCM + Local notification service.
/// Fulfills: "Proactive Notification Engine: FCM-based push notifications
/// for extreme weather events" (Proposal Section 6.1.1).
///
/// Smart alerts:
///  - Rain expected in 3h → "Sulama yapmayın"
///  - Frost risk (< 3°C) → "Bitkilerinizi koruyun"
///  - Heat stress (> 36°C) → "Sulama saatini ayarlayın"
///  - Strong wind (> 10 m/s) → "Sera perdelerini kapatın"
class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();

  static const _channelId = 'agri_alerts';
  static const _channelName = 'Tarım Uyarıları';
  static const _channelDesc = 'Hava durumu ve tarımsal uyarılar';

  // ── Init ─────────────────────────────────────────────────────────────────

  static Future<void> initialize() async {
    // 1. Local notifications
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    await _plugin.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
    );

    // Create Android notification channel
    if (Platform.isAndroid) {
      await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(
            const AndroidNotificationChannel(
              _channelId,
              _channelName,
              description: _channelDesc,
              importance: Importance.high,
            ),
          );
    }

    // 2. FCM — request permission & set up handlers
    try {
      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      // Handle FCM messages when app is in foreground
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        final notification = message.notification;
        if (notification != null) {
          show(
            title: notification.title ?? 'Tarım Uyarısı',
            body: notification.body ?? '',
          );
        }
      });

      // Subscribe to topic for broadcast alerts
      await messaging.subscribeToTopic('agri_alerts');
    } catch (_) {
      // FCM may not be configured on all platforms; local notifications still work
    }
  }

  // ── Weather-Triggered Smart Alerts ───────────────────────────────────────

  /// Fetches hourly forecast for the given coordinates and sends local
  /// notifications if any agricultural thresholds are breached.
  static Future<void> checkWeatherAndAlert(double lat, double lng) async {
    try {
      final url = Uri.parse(
        'https://api.open-meteo.com/v1/forecast'
        '?latitude=$lat&longitude=$lng'
        '&hourly=temperature_2m,precipitation_probability,windspeed_10m,weathercode'
        '&forecast_days=1&timezone=auto',
      );
      final res = await http.get(url).timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) return;

      final data = jsonDecode(res.body)['hourly'] as Map<String, dynamic>;
      final List<int> codes = List<int>.from(data['weathercode'] ?? []);
      final List<double> temps =
          (data['temperature_2m'] as List).map((e) => (e as num).toDouble()).toList();
      final List<int> precipProb =
          (data['precipitation_probability'] as List).map((e) => (e as num).toInt()).toList();
      final List<double> winds =
          (data['windspeed_10m'] as List).map((e) => (e as num).toDouble()).toList();

      final now = DateTime.now();
      // Check next 6 hours
      final limit = (codes.length < 6 ? codes.length : 6);

      bool rainAlertSent = false;
      bool frostAlertSent = false;
      bool heatAlertSent = false;
      bool windAlertSent = false;

      for (int i = 0; i < limit; i++) {
        final hour = now.add(Duration(hours: i));

        // Rain / thunderstorm (WMO codes 51-99)
        if (!rainAlertSent &&
            (precipProb[i] >= 70 || (codes[i] >= 51 && codes[i] <= 99))) {
          final hoursAway = i == 0 ? 'şu an' : '$i saat içinde';
          await show(
            id: 1001,
            title: '🌧️ Yağmur Uyarısı',
            body:
                'Yağış bekleniyor ($hoursAway, %${precipProb[i]} olasılık). Sulama yapmayın, tarımsal ilaçlama erteleyiniz.',
          );
          rainAlertSent = true;
        }

        // Frost risk
        if (!frostAlertSent && temps[i] <= 3.0 && (hour.hour >= 22 || hour.hour <= 7)) {
          await show(
            id: 1002,
            title: '🥶 Don Riski!',
            body:
                '${temps[i].toStringAsFixed(1)}°C bekleniyor. Hassas bitkilerinizi örtün, sera perdelerini kapatın.',
          );
          frostAlertSent = true;
        }

        // Heat stress
        if (!heatAlertSent && temps[i] >= 36.0) {
          await show(
            id: 1003,
            title: '🌡️ Aşırı Sıcaklık Uyarısı',
            body:
                '${temps[i].toStringAsFixed(1)}°C bekleniyor. Sulamayı sabah erken veya akşam üstü yapın. Bitkileri gölgeleyin.',
          );
          heatAlertSent = true;
        }

        // Strong wind
        if (!windAlertSent && winds[i] >= 10.0) {
          await show(
            id: 1004,
            title: '💨 Şiddetli Rüzgar Uyarısı',
            body:
                '${winds[i].toStringAsFixed(1)} m/s rüzgar bekleniyor. Sera branda ve perdelerini kapatın, hassas bitkileri destekleyin.',
          );
          windAlertSent = true;
        }
      }
    } catch (_) {
      // Silently ignore — notifications are a best-effort feature
    }
  }

  // ── Manual Notifications ─────────────────────────────────────────────────

  static Future<void> show({
    int id = 0,
    required String title,
    required String body,
  }) async {
    try {
      final androidDetails = AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDesc,
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      );
      const iosDetails = DarwinNotificationDetails();
      await _plugin.show(
        id,
        title,
        body,
        NotificationDetails(android: androidDetails, iOS: iosDetails),
      );
    } catch (e) {
      debugPrint('Notification error: $e');
    }
  }

  /// Send a "good time to water" notification when conditions are ideal.
  static Future<void> sendWateringReminderIfIdeal(
    double lat,
    double lng,
    String fieldName,
  ) async {
    try {
      final url = Uri.parse(
        'https://api.open-meteo.com/v1/forecast'
        '?latitude=$lat&longitude=$lng'
        '&hourly=temperature_2m,precipitation_probability'
        '&forecast_days=1&timezone=auto',
      );
      final res = await http.get(url).timeout(const Duration(seconds: 8));
      if (res.statusCode != 200) return;
      final data = jsonDecode(res.body)['hourly'];
      final double tempNow =
          ((data['temperature_2m'] as List)[6] as num).toDouble(); // ~6AM
      final int precipNow =
          ((data['precipitation_probability'] as List)[6] as num).toInt();

      if (tempNow >= 15 && tempNow <= 28 && precipNow < 30) {
        await show(
          id: 2000,
          title: '💧 Sulama Zamanı — $fieldName',
          body:
              'Şu an ideal sulama koşulları: ${tempNow.toStringAsFixed(0)}°C, yağış olasılığı %$precipNow. Sabah erken sulamayı unutmayın.',
        );
      }
    } catch (_) {}
  }
}
