import 'package:hive_flutter/hive_flutter.dart';

/// Kullanıcının kalıcı tercihleri için ince bir Hive sarmalayıcısı.
/// `settingsBox` zaten main.dart içinde açılır.
class UserPrefs {
  UserPrefs._();
  static final UserPrefs instance = UserPrefs._();

  static const _kAskFacingDirection = 'pref.ask_facing_direction';

  Box? get _box =>
      Hive.isBoxOpen('settingsBox') ? Hive.box('settingsBox') : null;

  /// Bitki ekleme sırasında yön seçim sheet'inin açılıp açılmayacağı.
  /// Varsayılan: kapalı — kullanıcı isterse Ayarlar'dan açar.
  bool get askFacingDirection {
    final v = _box?.get(_kAskFacingDirection);
    if (v is bool) return v;
    return false;
  }

  Future<void> setAskFacingDirection(bool value) async {
    await _box?.put(_kAskFacingDirection, value);
  }
}
