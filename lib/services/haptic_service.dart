import 'package:flutter/services.dart';

/// Singleton — tüm uygulama boyunca haptik geri bildirim tek noktadan yönetilir.
/// Strategy pattern: farklı haptik "seviye" stratejileri (light/medium/heavy/selection).
class HapticService {
  HapticService._();
  static final HapticService instance = HapticService._();

  bool enabled = true;

  Future<void> light() async {
    if (!enabled) return;
    await HapticFeedback.lightImpact();
  }

  Future<void> medium() async {
    if (!enabled) return;
    await HapticFeedback.mediumImpact();
  }

  Future<void> heavy() async {
    if (!enabled) return;
    await HapticFeedback.heavyImpact();
  }

  Future<void> selection() async {
    if (!enabled) return;
    await HapticFeedback.selectionClick();
  }

  Future<void> success() async {
    if (!enabled) return;
    await HapticFeedback.mediumImpact();
    await Future.delayed(const Duration(milliseconds: 90));
    await HapticFeedback.lightImpact();
  }
}
