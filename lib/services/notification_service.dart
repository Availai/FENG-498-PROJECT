import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;

import '../data/activity_types.dart';
import 'alert_journal_service.dart';
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

  /// Bildirime tıklandığında çağrılır. `main.dart` tarafından atanır;
  /// circular import olmadan navigasyon sağlar.
  static void Function(String payload)? onNotificationTap;

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
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload;
        if (payload != null && payload.isNotEmpty) {
          onNotificationTap?.call(payload);
        }
      },
    );

    // Uygulama kapalıyken bildirime tıklanarak açıldıysa payload'ı işle.
    final launchDetails = await _plugin.getNotificationAppLaunchDetails();
    if (launchDetails?.didNotificationLaunchApp == true) {
      final payload = launchDetails!.notificationResponse?.payload;
      if (payload != null && payload.isNotEmpty) {
        // Navigator henüz hazır değil; bir sonraki frame'e ertele.
        Future.delayed(const Duration(milliseconds: 600), () {
          onNotificationTap?.call(payload);
        });
      }
    }

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

      // FCM: uygulama arka planda iken bildirime tıklandı (resume)
      FirebaseMessaging.onMessageOpenedApp.listen((msg) {
        final payload = msg.data['payload']?.toString();
        if (payload != null && payload.isNotEmpty) {
          onNotificationTap?.call(payload);
        }
      });

      // FCM: uygulama tamamen kapalıyken bildirime tıklandı (terminated)
      final initial = await messaging.getInitialMessage();
      if (initial != null) {
        final payload = initial.data['payload']?.toString();
        if (payload != null && payload.isNotEmpty) {
          Future.delayed(const Duration(milliseconds: 600), () {
            onNotificationTap?.call(payload);
          });
        }
      }
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
    String? fieldId,
    String? fieldName,
    int notificationIdSeed = 0,
    AlertJournalService? alertJournal,
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
      final journalFieldName = fieldName ?? 'Tarla';

      Future<void> recordWeather({
        required String key,
        required String title,
        required String body,
        required String severity,
        String? icon,
        Map<String, dynamic>? metadata,
      }) async {
        final id = fieldId;
        if (id == null || id.isEmpty || alertJournal == null) return;
        await alertJournal.recordWeatherAlert(
          fieldId: id,
          fieldName: journalFieldName,
          alertKey: key,
          title: title,
          message: body,
          severity: severity,
          icon: icon,
          metadata: metadata,
        );
      }

      // ── DON (FAO/WMO) ────────────────────────────────────────────────────
      if (minTemp <= frostCriticalC) {
        final title = 'KRİTİK Don Uyarısı$suffix';
        final body =
            '${minTemp.toStringAsFixed(1)}°C bekleniyor (${_hh(minTempHour)}). Hassas bitkilerinizi örtün, sera ısıtmasını devreye alın. Sabah erken sulama yapmayın.';
        await show(
          id: 1002 + notificationIdSeed,
          title: '🥶 $title',
          body: body,
        );
        await recordWeather(
          key: 'frost_critical',
          title: title,
          body: body,
          severity: ActivityType.alertSeverityCritical,
          icon: '🥶',
          metadata: {
            'temperature_c': minTemp,
            'hour': _hh(minTempHour),
          },
        );
      } else if (minTemp <= frostWarningC) {
        final title = 'Don Riski$suffix';
        final body =
            '${minTemp.toStringAsFixed(1)}°C bekleniyor (${_hh(minTempHour)}). Örtü bezi hazırlayın, fideleri koruyun.';
        await show(
          id: 1002 + notificationIdSeed,
          title: '❄️ $title',
          body: body,
        );
        await recordWeather(
          key: 'frost_warning',
          title: title,
          body: body,
          severity: ActivityType.alertSeverityWarning,
          icon: '❄️',
          metadata: {
            'temperature_c': minTemp,
            'hour': _hh(minTempHour),
          },
        );
      }

      // ── AŞIRI SICAKLIK (FAO) ─────────────────────────────────────────────
      if (maxTemp >= heatCriticalC) {
        final title = 'KRİTİK Sıcak Dalgası$suffix';
        final body =
            '${maxTemp.toStringAsFixed(1)}°C — bitki ölüm riski. Sulamayı sabah 06:00 öncesi yapın, gölgeleme uygulayın.';
        await show(
          id: 1003 + notificationIdSeed,
          title: '🔥 $title',
          body: body,
        );
        await recordWeather(
          key: 'heat_critical',
          title: title,
          body: body,
          severity: ActivityType.alertSeverityCritical,
          icon: '🔥',
          metadata: {'temperature_c': maxTemp},
        );
      } else if (maxTemp >= heatWarningC) {
        final title = 'Yüksek Sıcaklık$suffix';
        final body =
            '${maxTemp.toStringAsFixed(1)}°C bekleniyor. Sulama saatini sabah erken/akşam üstüne çekin.';
        await show(
          id: 1003 + notificationIdSeed,
          title: '🌡️ $title',
          body: body,
        );
        await recordWeather(
          key: 'heat_warning',
          title: title,
          body: body,
          severity: ActivityType.alertSeverityWarning,
          icon: '🌡️',
          metadata: {'temperature_c': maxTemp},
        );
      }

      // ── RÜZGAR (Beaufort/WMO) ────────────────────────────────────────────
      if (maxWind >= windCriticalMs) {
        final title = 'FIRTINA Uyarısı$suffix';
        final body =
            '${maxWind.toStringAsFixed(1)} m/s (Beaufort 8+). Sera örtü/perdelerini sabitleyin, destek kazıkları kontrol edin, ilaçlama yapmayın.';
        await show(
          id: 1004 + notificationIdSeed,
          title: '🌪️ $title',
          body: body,
        );
        await recordWeather(
          key: 'wind_critical',
          title: title,
          body: body,
          severity: ActivityType.alertSeverityCritical,
          icon: '🌪️',
          metadata: {'wind_ms': maxWind},
        );
      } else if (maxWind >= windWarningMs) {
        final title = 'Kuvvetli Rüzgar$suffix';
        final body =
            '${maxWind.toStringAsFixed(1)} m/s rüzgar bekleniyor. İlaçlama erteleyin (drift riski), perdeleri kapatın.';
        await show(
          id: 1004 + notificationIdSeed,
          title: '💨 $title',
          body: body,
        );
        await recordWeather(
          key: 'wind_warning',
          title: title,
          body: body,
          severity: ActivityType.alertSeverityWarning,
          icon: '💨',
          metadata: {'wind_ms': maxWind},
        );
      }

      // ── YAĞIŞ (MGM/WMO) ──────────────────────────────────────────────────
      if (tomorrowRainMm >= rainCriticalMm) {
        final title = 'ŞİDDETLİ Yağış$suffix';
        final body =
            'Yarın ${tomorrowRainMm.toStringAsFixed(0)} mm yağış (MGM şiddetli sınıfı). Drenaj kanallarını açın, sulamayı tamamen durdurun, kök çürüklüğüne dikkat.';
        await show(
          id: 1001 + notificationIdSeed,
          title: '⛈️ $title',
          body: body,
        );
        await recordWeather(
          key: 'rain_critical',
          title: title,
          body: body,
          severity: ActivityType.alertSeverityCritical,
          icon: '⛈️',
          metadata: {'rain_mm': tomorrowRainMm},
        );
      } else if (tomorrowRainMm >= rainWarningMm) {
        final title = 'Kuvvetli Yağış$suffix';
        final body =
            'Yarın ${tomorrowRainMm.toStringAsFixed(0)} mm yağış bekleniyor. Sulama ve ilaçlamayı erteleyin.';
        await show(
          id: 1001 + notificationIdSeed,
          title: '🌧️ $title',
          body: body,
        );
        await recordWeather(
          key: 'rain_warning',
          title: title,
          body: body,
          severity: ActivityType.alertSeverityWarning,
          icon: '🌧️',
          metadata: {'rain_mm': tomorrowRainMm},
        );
      } else if (hasStorm) {
        final title = 'Gök Gürültülü Fırtına$suffix';
        const body =
            'Önümüzdeki saatlerde fırtına bekleniyor. Tarla işlerini erteleyin, ekipmanı emniyete alın.';
        await show(
          id: 1005 + notificationIdSeed,
          title: '⚡ $title',
          body: body,
        );
        await recordWeather(
          key: 'storm_warning',
          title: title,
          body: body,
          severity: ActivityType.alertSeverityWarning,
          icon: '⚡',
          metadata: {'weathercode_storm': true},
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
    String? payload,
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
        payload: payload,
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
    String? fieldId,
    int notificationIdSeed = 0,
    AlertJournalService? alertJournal,
  }) async {
    // Bildirime tıklandığında DailyGuideScreen'e gidilecek payload.
    final payload = fieldId != null && fieldId.isNotEmpty
        ? jsonEncode({
            'type': 'guide',
            'fieldId': fieldId,
            'fieldName': fieldName,
          })
        : null;

    try {
      if (fieldId != null && fieldId.isNotEmpty && alertJournal != null) {
        await alertJournal.recordGuideResult(
          fieldId: fieldId,
          fieldName: fieldName,
          result: result,
        );
      }

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
          payload: payload,
        );
      }

      // 2. Kritik uyarılar (don / aşırı sıcak)
      for (final alert in result.alerts) {
        if (alert.severity != AlertSeverity.critical) continue;
        await show(
          id: 5100 + alert.kind.index + notificationIdSeed,
          title: '${alert.icon} ${alert.title} — $fieldName',
          body: alert.message,
          payload: payload,
        );
      }

      // 3. Bugünkü görev özeti (yağmur yoksa — zaten yukarıda sulama bildirildi)
      if (result.today.isNotEmpty && rainAlert == null) {
        final labels = result.today.take(2).map((t) => t.headline).join(' • ');
        final extra =
            result.today.length > 2 ? ' +${result.today.length - 2}' : '';
        await show(
          id: 5200 + notificationIdSeed,
          title: '🌱 $fieldName — Bugün ${result.today.length} görev',
          body: '$labels$extra',
          payload: payload,
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

  // ── Tedavi Hatırlatıcı Bildirimleri ─────────────────────────────────────

  /// İlaçlama sonrası tedavi planı hatırlatıcılarını planlar.
  ///
  /// Tedavi planı her [intervalDays] günde bir, toplam [totalApplications]
  /// adet uygulama içerir; her uygulama günü [applicationHour] saatinde
  /// bildirim atılır. Ek olarak her uygulama gününün akşamı kısa bir gözlem
  /// hatırlatıcısı ve son uygulamadan [intervalDays] sonra "tedavi
  /// tamamlandı, bitkileri kontrol edin" bildirimi gelir.
  ///
  /// Aktif madde adı kullanıcıya görünür ama doz/PHI bilgileri için her
  /// bildirim BKÜ kontrolüne yönlendirir (CLAUDE.md §17).
  ///
  /// Mevcut altyapı [Future.delayed] kullandığı için bildirimler yalnız
  /// uygulama çalıştığı sürece atılır; uzun süreli persisting için
  /// zonedSchedule + timezone paketine geçiş gerekir (ileride).
  static Future<void> scheduleTreatmentReminders({
    required String fieldId,
    required String fieldName,
    required String diseaseName,
    required int intervalDays,
    required int totalApplications,
    int applicationHour = 7,
    int observationHour = 19,
    String? activeIngredient,
    int firstApplicationOffsetDays = 0,
  }) async {
    if (totalApplications <= 0 || intervalDays <= 0) return;
    try {
      final payload = jsonEncode({
        'type': 'treatment',
        'fieldId': fieldId,
        'fieldName': fieldName,
      });

      // Yeni planı kurmadan önce eski planı temizle ki bildirimler üst üste
      // birikmesin.
      await cancelTreatmentReminders(fieldId);

      final baseId = 6000 + (fieldId.hashCode.abs() % 1000);
      final now = DateTime.now();
      final activeLabel = (activeIngredient ?? '').trim();
      final activeSuffix = activeLabel.isEmpty ? '' : ' · $activeLabel';

      for (int app = 0; app < totalApplications; app++) {
        final dayOffset = firstApplicationOffsetDays + app * intervalDays;
        final target = now.add(Duration(days: dayOffset));

        final sprayAt = DateTime(
          target.year,
          target.month,
          target.day,
          applicationHour,
          0,
        );
        if (sprayAt.isAfter(now)) {
          _scheduleDelayed(
            id: baseId + (app * 3),
            delay: sprayAt.difference(now),
            title: '💊 ${app + 1}. Uygulama — $fieldName',
            body: '$diseaseName tedavisi$activeSuffix. '
                'Etiket dozu ve hasada bekleme süresi için bku.tarim.gov.tr.',
            payload: payload,
          );
        }

        final observeAt = DateTime(
          target.year,
          target.month,
          target.day,
          observationHour,
          0,
        );
        if (observeAt.isAfter(now)) {
          _scheduleDelayed(
            id: baseId + (app * 3) + 1,
            delay: observeAt.difference(now),
            title: '🔎 Uygulama Sonrası Kontrol — $fieldName',
            body: '$diseaseName: yapraklarda yanıklık/leke var mı? '
                'Bir sonraki uygulama $intervalDays gün sonra.',
            payload: payload,
          );
        }
      }

      // Tedavi sonu — son uygulamadan intervalDays sonra.
      final endOffset =
          firstApplicationOffsetDays + (totalApplications - 1) * intervalDays;
      final endTarget = now.add(Duration(days: endOffset + intervalDays));
      final endAt = DateTime(
        endTarget.year,
        endTarget.month,
        endTarget.day,
        applicationHour + 1,
        0,
      );
      if (endAt.isAfter(now)) {
        _scheduleDelayed(
          id: baseId + (totalApplications * 3) + 2,
          delay: endAt.difference(now),
          title: '✅ Tedavi Tamamlandı — $fieldName',
          body: '$diseaseName tedavi planı sona erdi. Bitkileri kontrol edin; '
              'belirti devam ediyorsa ziraat mühendisine danışın.',
          payload: payload,
        );
      }
    } catch (e) {
      debugPrint('Tedavi hatırlatıcı planlama hatası: $e');
    }
  }

  /// Bir tarla için tüm tedavi hatırlatıcılarını iptal eder.
  static Future<void> cancelTreatmentReminders(String fieldId) async {
    try {
      final baseId = 6000 + (fieldId.hashCode.abs() % 1000);
      for (int i = 0; i < 62; i++) {
        await _plugin.cancel(baseId + i);
      }
    } catch (_) {}
  }

  /// Geciktirilmiş bildirim — zonedSchedule yerine Future.delayed kullanır.
  static void _scheduleDelayed({
    required int id,
    required Duration delay,
    required String title,
    required String body,
    String? payload,
  }) {
    Future.delayed(delay, () async {
      await show(id: id, title: title, body: body, payload: payload);
    });
  }
}
