import 'dart:convert';
import 'package:flutter/services.dart';

/// Pestisit Re-Entry Interval tablosu — `assets/data/pesticide_rei.json`'dan
/// yüklenir. İlaçlama sonrası kaç saat boyunca sahaya girilemeyeceği bilgisi.
///
/// Kullanım:
///   await PesticideRei.load();
///   final hours = PesticideRei.lookup('mancozeb'); // 24
///   final hours = PesticideRei.lookup('Bilinmeyen'); // 24 (default)
class PesticideRei {
  static Map<String, int> _direct = {};
  static Map<String, String> _aliases = {};
  static int _defaultHours = 24;
  static bool _loaded = false;

  static Future<void> load() async {
    if (_loaded) return;
    try {
      final raw = await rootBundle.loadString('assets/data/pesticide_rei.json');
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        final map = Map<String, dynamic>.from(decoded);
        _defaultHours = (map['default'] as num?)?.toInt() ?? 24;

        final aliases = map['_aliases'];
        if (aliases is Map) {
          _aliases = aliases.map(
              (k, v) => MapEntry(k.toString().toLowerCase(), v.toString()));
        }

        _direct = {};
        for (final entry in map.entries) {
          final k = entry.key;
          final v = entry.value;
          if (k.startsWith('_') || k == 'default') continue;
          if (v is num) _direct[k.toLowerCase()] = v.toInt();
        }
      }
    } catch (_) {
      // Asset yoksa default ile devam — UI bozulmasın.
    }
    _loaded = true;
  }

  /// Verilen pestisit adı için REI saat. Bilinmiyorsa default (24).
  static int lookup(String pesticideName) {
    final n = pesticideName.trim().toLowerCase();
    if (n.isEmpty) return _defaultHours;
    if (_direct.containsKey(n)) return _direct[n]!;
    final alias = _aliases[n];
    if (alias != null && _direct.containsKey(alias.toLowerCase())) {
      return _direct[alias.toLowerCase()]!;
    }
    // Substring eşleşme — kullanıcı "Mancozeb 80% WP" gibi ek metin yazdıysa
    for (final key in _direct.keys) {
      if (n.contains(key)) return _direct[key]!;
    }
    return _defaultHours;
  }

  static int get defaultHours => _defaultHours;
}
