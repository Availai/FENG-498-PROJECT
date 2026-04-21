import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

/// Cihaz saati manipulasyonuna karşı dirençli "sunucu-güvenli" saat.
///
/// `DateTime.now()` kullanıcı tarafından ileri/geri alınabilir; LWW sync
/// bu durumda stale güncellemeyi geçerli sayabilir. [TrustedClock] sunucudan
/// çektiği zaman ile cihaz saati arasındaki delta'yı Hive'da kalıcı tutar:
///
/// ```
/// trusted_now = device_now + delta
/// delta       = server_now - device_now  (round-trip yarısı ile düzeltilir)
/// ```
///
/// Delta çevrimdışı bile korunur; internet gelene kadar son bilinen delta
/// kullanılır. Bu, "ev içinde saat ileri alınıp sync'e bağlanılsa bile"
/// senaryosunda bile yakın bir tahmin verir.
class TrustedClock {
  TrustedClock._();

  static const String _boxName = 'settingsBox';
  static const String _deltaKey = 'server_time_delta_micros';
  static const String _lastSyncKey = 'server_time_last_sync_at';

  static Duration _delta = Duration.zero;
  static bool _hydrated = false;

  /// Uygulama açılışında Hive hazır olduktan sonra bir kez çağrılır.
  /// Daha önce kaydedilmiş delta varsa belleğe yükler.
  static Future<void> hydrate() async {
    if (_hydrated) return;
    try {
      final box = Hive.isBoxOpen(_boxName) ? Hive.box(_boxName) : await Hive.openBox(_boxName);
      final micros = box.get(_deltaKey);
      if (micros is int) {
        _delta = Duration(microseconds: micros);
      }
    } catch (e) {
      debugPrint('[TrustedClock] hydrate hatası: $e');
    } finally {
      _hydrated = true;
    }
  }

  /// Şu anki sunucu-güvenli UTC zamanı.
  ///
  /// Delta bilinmiyorsa cihaz saatini döner (başlangıç fallback'i).
  /// Zaman yazımının sync path'inde kritik olduğu her yerde
  /// `DateTime.now().toUtc()` yerine bunu kullan.
  static DateTime now() {
    return DateTime.now().toUtc().add(_delta);
  }

  /// Mevcut delta — debug / log amaçlı.
  static Duration get delta => _delta;

  /// Delta daha önce ayarlandı mı?
  static bool get isSynced => _delta != Duration.zero || _hydrated;

  /// Round-trip ölçümlü delta uygulama.
  ///
  /// [deviceBefore]: istek gönderilmeden hemen önce cihaz UTC
  /// [deviceAfter]: yanıt alındığında cihaz UTC
  /// [server]: sunucudan dönen UTC
  ///
  /// Round-trip gecikmesi yarıya bölünerek sunucu zamanına eklenir;
  /// delta = server_now_at_receipt - device_now_at_receipt olarak hesaplanır.
  static Future<void> applyServerTime({
    required DateTime deviceBefore,
    required DateTime deviceAfter,
    required DateTime server,
  }) async {
    final deviceBeforeUtc = deviceBefore.toUtc();
    final deviceAfterUtc = deviceAfter.toUtc();
    final serverUtc = server.toUtc();

    final roundTrip = deviceAfterUtc.difference(deviceBeforeUtc);
    // Yanıt alındığı anda sunucu saati ≈ server + roundTrip/2
    final estimatedServerAtReceipt =
        serverUtc.add(Duration(microseconds: roundTrip.inMicroseconds ~/ 2));
    final newDelta = estimatedServerAtReceipt.difference(deviceAfterUtc);

    _delta = newDelta;
    try {
      final box = Hive.isBoxOpen(_boxName) ? Hive.box(_boxName) : await Hive.openBox(_boxName);
      await box.put(_deltaKey, newDelta.inMicroseconds);
      await box.put(_lastSyncKey, deviceAfterUtc.toIso8601String());
    } catch (e) {
      debugPrint('[TrustedClock] persist hatası: $e');
    }

    debugPrint(
      '[TrustedClock] delta güncellendi: ${newDelta.inMilliseconds}ms '
      '(round-trip: ${roundTrip.inMilliseconds}ms)',
    );
  }
}
