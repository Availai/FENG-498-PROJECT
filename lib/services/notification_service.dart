import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;

import 'guide_engine.dart';

/// FCM + Local notification service.
/// Fulfills: "Proactive Notification Engine: FCM-based push notifications
/// for extreme weather events" (Proposal Section 6.1.1).
///
/// ─── PROFESYONEL UYARI EŞİKLERİ (kaynak doğrulamalı) ────────────────────────
///
/// DON (Frost):
///   FAO "Frost Protection: fundamentals, practice, and economics" (2005)
///   ve WMO ground-frost tanımı:
///     • ≤ 0°C  → kritik don (hassas bitkilerde hücre hasarı başlar)
///     • ≤ +2°C → uyarı (radyatif soğuma + tahmin belirsizliği marjı)
///
/// YAĞIŞ:
///   T.C. MGM resmi yağış sınıflandırması (https://mgm.gov.tr) + WMO-No. 407:
///     • > 50 mm/24h → şiddetli yağış (drenaj/kök çürüklüğü kritik)
///     • > 20 mm/24h → kuvvetli yağış (uyarı)
///
/// RÜZGAR:
///   Beaufort ölçeği (WMO standardı, WMO-No. 8 Guide to Met. Instruments):
///     • ≥ 17.2 m/s → Beaufort 8 fırtına (sera/yapısal hasar) — kritik
///     • ≥ 10.8 m/s → Beaufort 6 kuvvetli esinti — uyarı
///
/// AŞIRI SICAKLIK:
///   FAO Irrigation & Drainage Paper No. 66 "Crop Yield Response to Water"
///   ve C3 bitkilerde fotosentez tepe eğrisi:
///     • ≥ 40°C → kritik ısı stresi (geri dönüşsüz hasar riski)
///     • ≥ 35°C → uyarı (su stresi başlangıcı)
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

  // ─── Profesyonel uyarı eşikleri (yukarıdaki kaynak listesine bakınız) ──────
  static const double frostCriticalC = 0.0; // FAO/WMO
  static const double frostWarningC = 2.0;
  static const double heatCriticalC = 40.0; // FAO I&D Paper 66
  static const double heatWarningC = 35.0;
  static const double windCriticalMs = 17.2; // Beaufort 8 (fırtına)
  static const double windWarningMs = 10.8; // Beaufort 6
  static const double rainCriticalMm = 50.0; // MGM şiddetli yağış / 24h
  static const double rainWarningMm = 20.0; // MGM kuvvetli yağış / 24h

  /// Fetches forecast for the given coordinates and sends local notifications
  /// if any agricultural thresholds are breached. [fieldName] uyarı metninde
  /// gösterilir; null ise sadece koordinata göre uyarı verilir.
  ///
  /// [notificationIdSeed] aynı tarla için aynı id'lerin üst üste yazılmasını
  /// engeller — birden çok tarla taranırken her tarlaya farklı seed verilmeli.
  static Future<void> checkWeatherAndAlert(
    double lat,
    double lng, {
    String? fieldName,
    int notificationIdSeed = 0,
  }) async {
    try {
      // Hourly: don/sıcaklık/rüzgar tepelerini yakalamak için
      // Daily: 24h yağış toplamı (MGM eşiği günlük tabanlıdır)
      final url = Uri.parse(
        'https://api.open-meteo.com/v1/forecast'
        '?latitude=$lat&longitude=$lng'
        '&hourly=temperature_2m,precipitation_probability,windspeed_10m,weathercode'
        '&daily=precipitation_sum'
        '&forecast_days=2&timezone=auto',
      );
      final res = await http.get(url).timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) return;

      final body = jsonDecode(res.body) as Map<String, dynamic>;
      final hourly = body['hourly'] as Map<String, dynamic>;
      final daily = body['daily'] as Map<String, dynamic>?;

      final List<int> codes = List<int>.from(hourly['weathercode'] ?? []);
      final List<double> temps = (hourly['temperature_2m'] as List)
          .map((e) => (e as num).toDouble())
          .toList();
      final List<int> precipProb = (hourly['precipitation_probability'] as List)
          .map((e) => (e as num).toInt())
          .toList();
      final List<double> winds = (hourly['windspeed_10m'] as List)
          .map((e) => (e as num).toDouble())
          .toList();

      // 24h toplam yağış (yarın için)
      final dailyPrecip = (daily?['precipitation_sum'] as List?)
              ?.map((e) => (e as num).toDouble())
              .toList() ??
          const <double>[];
      final tomorrowRainMm = dailyPrecip.length > 1 ? dailyPrecip[1] : 0.0;

      // Önümüzdeki 12 saat içindeki tepe değerleri tara
      final limit = codes.length < 12 ? codes.length : 12;
      double minTemp = double.infinity;
      double maxTemp = -double.infinity;
      double maxWind = 0;
      int maxPrecipProb = 0;
      bool hasStorm = false;
      DateTime? minTempHour;

      final now = DateTime.now();
      for (int i = 0; i < limit; i++) {
        if (temps[i] < minTemp) {
          minTemp = temps[i];
          minTempHour = now.add(Duration(hours: i));
        }
        if (temps[i] > maxTemp) maxTemp = temps[i];
        if (winds[i] > maxWind) maxWind = winds[i];
        if (precipProb[i] > maxPrecipProb) maxPrecipProb = precipProb[i];
        if (codes[i] >= 95 && codes[i] <= 99) hasStorm = true;
      }

      final suffix = fieldName != null ? ' — $fieldName' : '';

      // ── DON (FAO/WMO) ────────────────────────────────────────────────────
      if (minTemp <= frostCriticalC) {
        await show(
          id: 1002 + notificationIdSeed,
          title: '🥶 KRİTİK Don Uyarısı$suffix',
          body:
              '${minTemp.toStringAsFixed(1)}°C bekleniyor (${_hh(minTempHour)}). Hassas bitkilerinizi örtün, sera ısıtmasını devreye alın. Sabah erken sulama yapmayın.',
        );
      } else if (minTemp <= frostWarningC) {
        await show(
          id: 1002 + notificationIdSeed,
          title: '❄️ Don Riski$suffix',
          body:
              '${minTemp.toStringAsFixed(1)}°C bekleniyor (${_hh(minTempHour)}). Örtü bezi hazırlayın, fideleri koruyun.',
        );
      }

      // ── AŞIRI SICAKLIK (FAO) ─────────────────────────────────────────────
      if (maxTemp >= heatCriticalC) {
        await show(
          id: 1003 + notificationIdSeed,
          title: '🔥 KRİTİK Sıcak Dalgası$suffix',
          body:
              '${maxTemp.toStringAsFixed(1)}°C — bitki ölüm riski. Sulamayı sabah 06:00 öncesi yapın, gölgeleme uygulayın.',
        );
      } else if (maxTemp >= heatWarningC) {
        await show(
          id: 1003 + notificationIdSeed,
          title: '🌡️ Yüksek Sıcaklık$suffix',
          body:
              '${maxTemp.toStringAsFixed(1)}°C bekleniyor. Sulama saatini sabah erken/akşam üstüne çekin.',
        );
      }

      // ── RÜZGAR (Beaufort/WMO) ────────────────────────────────────────────
      if (maxWind >= windCriticalMs) {
        await show(
          id: 1004 + notificationIdSeed,
          title: '🌪️ FIRTINA Uyarısı$suffix',
          body:
              '${maxWind.toStringAsFixed(1)} m/s (Beaufort 8+). Sera örtü/perdelerini sabitleyin, destek kazıkları kontrol edin, ilaçlama yapmayın.',
        );
      } else if (maxWind >= windWarningMs) {
        await show(
          id: 1004 + notificationIdSeed,
          title: '💨 Kuvvetli Rüzgar$suffix',
          body:
              '${maxWind.toStringAsFixed(1)} m/s rüzgar bekleniyor. İlaçlama erteleyin (drift riski), perdeleri kapatın.',
        );
      }

      // ── YAĞIŞ (MGM/WMO) ──────────────────────────────────────────────────
      if (tomorrowRainMm >= rainCriticalMm) {
        await show(
          id: 1001 + notificationIdSeed,
          title: '⛈️ ŞİDDETLİ Yağış$suffix',
          body:
              'Yarın ${tomorrowRainMm.toStringAsFixed(0)} mm yağış (MGM şiddetli sınıfı). Drenaj kanallarını açın, sulamayı tamamen durdurun, kök çürüklüğüne dikkat.',
        );
      } else if (tomorrowRainMm >= rainWarningMm) {
        await show(
          id: 1001 + notificationIdSeed,
          title: '🌧️ Kuvvetli Yağış$suffix',
          body:
              'Yarın ${tomorrowRainMm.toStringAsFixed(0)} mm yağış bekleniyor. Sulama ve ilaçlamayı erteleyin.',
        );
      } else if (hasStorm) {
        await show(
          id: 1005 + notificationIdSeed,
          title: '⚡ Gök Gürültülü Fırtına$suffix',
          body:
              'Önümüzdeki saatlerde fırtına bekleniyor. Tarla işlerini erteleyin, ekipmanı emniyete alın.',
        );
      }
    } catch (_) {
      // Silently ignore — notifications are a best-effort feature
    }
  }

  static String _hh(DateTime? d) {
    if (d == null) return '';
    return '${d.hour.toString().padLeft(2, '0')}:00';
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

  /// GuideResult tabanlı akıllı bildirimler — üç katman:
  ///
  /// 1. Yağmur nedeniyle sulama ertelendiyse → "Sulamana gerek yok" bildirimi.
  /// 2. Kritik uyarılar (don / aşırı sıcak) → hemen bildir.
  /// 3. Bugünkü görev özeti → yağmur yoksa toplu bildir.
  ///
  /// [notificationIdSeed] farklı tarlalar için ID çakışmasını önler.
  /// Her katman için ayrı ID aralığı: 5000-x yağmur, 5100-x kritik, 5200-x görev.
  static Future<void> sendGuideNotifications(
    GuideResult result,
    String fieldName, {
    int notificationIdSeed = 0,
  }) async {
    try {
      // 1. Yağmur bekleniyor → sulama ertele
      final rainAlert = result.alerts
          .where((a) => a.kind == AlertKind.rainExpected)
          .firstOrNull;
      if (rainAlert != null) {
        final mm = rainAlert.message.contains('mm')
            ? rainAlert.message.split('mm').first.split(' ').last
            : '';
        await show(
          id: 5000 + notificationIdSeed,
          title: '💧 Sulamana Gerek Yok — $fieldName',
          body: mm.isNotEmpty
              ? 'Bugün $mm mm yağmur bekleniyor. Sulama yarına ertelendi.'
              : rainAlert.message,
        );
      }

      // 2. Kritik uyarılar (don / aşırı sıcak)
      for (final alert in result.alerts) {
        if (alert.severity != AlertSeverity.critical) continue;
        await show(
          id: 5100 + alert.kind.index + notificationIdSeed,
          title: '${alert.icon} ${alert.title} — $fieldName',
          body: alert.message,
        );
      }

      // 3. Bugünkü görev özeti (yağmur yoksa — zaten yukarıda sulama bildirildi)
      if (result.today.isNotEmpty && rainAlert == null) {
        final labels =
            result.today.take(2).map((t) => t.headline).join(' • ');
        final extra =
            result.today.length > 2 ? ' +${result.today.length - 2}' : '';
        await show(
          id: 5200 + notificationIdSeed,
          title: '🌱 $fieldName — Bugün ${result.today.length} görev',
          body: '$labels$extra',
        );
      }
    } catch (_) {
      // Bildirimler best-effort; uygulama akışını engelleme.
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
