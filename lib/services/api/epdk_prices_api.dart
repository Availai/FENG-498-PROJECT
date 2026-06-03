import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:hive_flutter/hive_flutter.dart';

class FuelPrices {
  final double dieselTry;
  final double gasolineTry;
  final DateTime fetchedAt;
  final String city;
  final bool fromCache;

  FuelPrices({
    required this.dieselTry,
    required this.gasolineTry,
    required this.fetchedAt,
    required this.city,
    this.fromCache = false,
  });

  Map<String, dynamic> toMap() => {
        'diesel': dieselTry,
        'gasoline': gasolineTry,
        'fetchedAt': fetchedAt.toIso8601String(),
        'city': city,
      };

  factory FuelPrices.fromMap(Map m, {bool fromCache = false}) => FuelPrices(
        dieselTry: (m['diesel'] as num).toDouble(),
        gasolineTry: (m['gasoline'] as num).toDouble(),
        fetchedAt: DateTime.tryParse(m['fetchedAt']?.toString() ?? '') ??
            DateTime.now(),
        city: m['city']?.toString() ?? 'ISTANBUL',
        fromCache: fromCache,
      );
}

/// EPDK haftalık akaryakıt bülteni (third-party scraper: hasanadiguzel.com.tr).
/// Key gerekmez. 10s timeout + Hive cache fallback.
class EpdkPricesApi {
  static const _city = 'ISTANBUL';
  static const _endpoint =
      'https://hasanadiguzel.com.tr/api/akaryakit/sehir=$_city';

  static Box get _cache => Hive.box('fuel_cache');

  static Future<FuelPrices?> fetchFuel() async {
    try {
      final r = await http
          .get(Uri.parse(_endpoint))
          .timeout(const Duration(seconds: 8));
      if (r.statusCode != 200) return _readCache();

      final j = jsonDecode(r.body) as Map?;
      if (j == null) return _readCache();

      // API formatı: {"data": {"62,73": {...fiyatlar...}, ...}}
      final dataMap = (j['data'] as Map?)?.cast<String, dynamic>();
      if (dataMap == null || dataMap.isEmpty) return _readCache();

      double? diesel, gasoline;

      // Her bölge için parse et (hepsi aynı fiyat olmalı)
      for (final regionData in dataMap.values) {
        if (regionData is! Map) continue;
        final region = regionData.cast<String, dynamic>();

        // Benzin: "Kursunsuz_95..."
        final benzinKey = region.keys
            .cast<String>()
            .firstWhere((k) => k.contains('Kursunsuz_95'), orElse: () => '');
        if (benzinKey.isNotEmpty) {
          final benzinStr = region[benzinKey]?.toString().replaceAll(',', '.');
          if (benzinStr != null) {
            gasoline ??= double.tryParse(benzinStr);
          }
        }

        // Mazot: "Motorin(Eurodiesel)" (Excellium değil)
        final mazotKey = region.keys.cast<String>().firstWhere(
            (k) =>
                k.contains('Motorin(Eurodiesel)') && !k.contains('Excellium'),
            orElse: () => '');
        if (mazotKey.isNotEmpty) {
          final mazotStr = region[mazotKey]?.toString().replaceAll(',', '.');
          if (mazotStr != null) {
            diesel ??= double.tryParse(mazotStr);
          }
        }

        // Bulduysak döngüyü kır
        if (diesel != null && gasoline != null) break;
      }

      // Başarılı parse ise cache'e yaz
      if (diesel != null && gasoline != null) {
        final fresh = FuelPrices(
          dieselTry: diesel,
          gasolineTry: gasoline,
          fetchedAt: DateTime.now(),
          city: _city,
        );
        await _cache.put('latest', fresh.toMap());
        return fresh;
      }

      // Parse başarısız → cache'i deneyelim
      return _readCache();
    } catch (_) {
      return _readCache();
    }
  }

  static FuelPrices? _readCache() {
    final raw = _cache.get('latest');
    if (raw is Map) return FuelPrices.fromMap(raw, fromCache: true);
    return null;
  }

  /// Fallback — canlı bülten alınamazsa kaba bir TAHMİN döndürür.
  /// Bu değerler kesin değildir; UI bunu "tahmini" olarak etiketler ve çiftçi
  /// kendi bayi fiyatıyla değiştirebilir (PriceBook manuel override).
  /// `fromCache: true` → değer "canlı" gibi gösterilmez (dürüstlük, CLAUDE.md §28).
  static FuelPrices fallbackPrices() => FuelPrices(
        dieselTry: 50.0, // kaba tahmin — lütfen güncelleyin
        gasolineTry: 52.0, // kaba tahmin — lütfen güncelleyin
        fetchedAt: DateTime.now(),
        city: _city,
        fromCache: true,
      );
}
