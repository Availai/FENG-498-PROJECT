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
          .timeout(const Duration(seconds: 10));
      if (r.statusCode != 200) return _readCache();

      final j = jsonDecode(r.body);
      final list = (j is Map ? j['data'] : null) ?? j;
      double? diesel, gasoline;

      if (list is List) {
        for (final item in list) {
          if (item is! Map) continue;
          final name =
              (item['urun'] ?? item['urunTuru'] ?? '').toString().toLowerCase();
          final priceStr = (item['fiyat'] ?? item['price'] ?? '')
              .toString()
              .replaceAll(',', '.');
          final price = double.tryParse(priceStr);
          if (price == null) continue;
          if (name.contains('motorin') ||
              name.contains('mazot') ||
              name.contains('diesel')) {
            diesel ??= price;
          } else if (name.contains('benzin') || name.contains('gasoline')) {
            gasoline ??= price;
          }
        }
      }

      if (diesel == null && gasoline == null) return _readCache();

      final fresh = FuelPrices(
        dieselTry: diesel ?? 0,
        gasolineTry: gasoline ?? 0,
        fetchedAt: DateTime.now(),
        city: _city,
      );
      await _cache.put('latest', fresh.toMap());
      return fresh;
    } catch (_) {
      return _readCache();
    }
  }

  static FuelPrices? _readCache() {
    final raw = _cache.get('latest');
    if (raw is Map) return FuelPrices.fromMap(raw, fromCache: true);
    return null;
  }
}
