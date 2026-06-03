/// Fiyat Defteri — masraf algoritmasının birim fiyat kaynağı.
///
/// Dürüstlük (CLAUDE.md §28): Türkiye'de yalnızca **akaryakıt** için ücretsiz
/// canlı bir kaynak var (EPDK / [EpdkPricesApi]). Gübre, tohum, işçilik ve
/// ürün satış fiyatları için resmî ücretsiz API yoktur; bu yüzden bunlar
/// **çiftçi tarafından düzenlenebilen, tarihli "güncel fiyat"** değerleridir.
/// Varsayılanlar TZOB bülteni referanslı [fertilizerPrices] listesinden üretilir.
/// Hiçbir fiyat uydurma bir API'den "canlı" gibi gösterilmez.
library;

import 'package:hive_flutter/hive_flutter.dart';

import '../data/fertilizer_prices.dart';
import 'api/epdk_prices_api.dart';

/// Türkçe karakterleri sadeleştirip küçük harfe çevirir (eşleme anahtarı için).
String normalizeTr(String s) => s
    .trim()
    .toLowerCase()
    .replaceAll('ç', 'c')
    .replaceAll('ğ', 'g')
    .replaceAll('ı', 'i')
    .replaceAll('İ', 'i')
    .replaceAll('ö', 'o')
    .replaceAll('ş', 's')
    .replaceAll('ü', 'u');

/// Düzenlenebilir birim fiyatlar + canlı akaryakıt.
class PriceBook {
  /// Gübre tipi (normalize anahtar) → ₺/kg. ör. 'dap', 'ure', 'npk'.
  final Map<String, double> fertilizerPerKg;

  /// Tohum ₺/kg (genel varsayılan; manuel girişte öneri için).
  final double seedPerKg;

  /// İşçilik ₺/gün.
  final double laborPerDay;

  /// Ürün (normalize ad) → satış fiyatı ₺/kg. Kâr tahmininde kullanılır.
  final Map<String, double> cropSalePerKg;

  /// Mazot ₺/L (akaryakıt canlıysa EPDK'dan).
  final double dieselPerL;

  /// Benzin ₺/L.
  final double gasolinePerL;

  /// Son güncelleme zamanı (kullanıcıya gösterilir).
  final DateTime updatedAt;

  /// Akaryakıt değerleri canlı EPDK'dan mı geldi.
  final bool fuelFromLive;

  const PriceBook({
    required this.fertilizerPerKg,
    required this.seedPerKg,
    required this.laborPerDay,
    required this.cropSalePerKg,
    required this.dieselPerL,
    required this.gasolinePerL,
    required this.updatedAt,
    required this.fuelFromLive,
  });

  /// Genel gübre ortalaması (bilinmeyen ad için fallback).
  double get fertilizerAveragePerKg {
    if (fertilizerPerKg.isEmpty) return 40.0;
    final sum = fertilizerPerKg.values.fold<double>(0, (a, b) => a + b);
    return sum / fertilizerPerKg.length;
  }

  /// Serbest metin gübre adından ₺/kg fiyatı tahmin eder.
  /// Bilinen tipe eşleşmezse genel ortalamayı döndürür.
  double fertilizerForName(String? name) {
    if (name == null || name.trim().isEmpty) return fertilizerAveragePerKg;
    final n = normalizeTr(name);
    String? key;
    if (n.contains('dap')) {
      key = 'dap';
    } else if (n.contains('amonyum')) {
      key = 'amonyum';
    } else if (n.contains('ure') || n.contains('46')) {
      key = 'ure';
    } else if (n.contains('can') || n.contains('%26') || n.contains('26')) {
      key = 'can';
    } else if (n.contains('npk') ||
        n.contains('kompoze') ||
        n.contains('15-15') ||
        n.contains('20-20') ||
        n.contains('taban')) {
      key = 'npk';
    }
    final v = key == null ? null : fertilizerPerKg[key];
    return v ?? fertilizerAveragePerKg;
  }

  /// Ürün adından satış fiyatı ₺/kg (yoksa 0 → kâr hesaplanmaz).
  double saleForCrop(String? cropName) {
    if (cropName == null || cropName.trim().isEmpty) return 0;
    final n = normalizeTr(cropName);
    if (cropSalePerKg.containsKey(n)) return cropSalePerKg[n]!;
    // Kısmi eşleşme (ör. "Ayçiçeği (yağlık)" → "aycicegi").
    for (final entry in cropSalePerKg.entries) {
      if (n.contains(entry.key) || entry.key.contains(n)) return entry.value;
    }
    return 0;
  }

  PriceBook copyWith({
    Map<String, double>? fertilizerPerKg,
    double? seedPerKg,
    double? laborPerDay,
    Map<String, double>? cropSalePerKg,
    double? dieselPerL,
    double? gasolinePerL,
    DateTime? updatedAt,
    bool? fuelFromLive,
  }) {
    return PriceBook(
      fertilizerPerKg: fertilizerPerKg ?? this.fertilizerPerKg,
      seedPerKg: seedPerKg ?? this.seedPerKg,
      laborPerDay: laborPerDay ?? this.laborPerDay,
      cropSalePerKg: cropSalePerKg ?? this.cropSalePerKg,
      dieselPerL: dieselPerL ?? this.dieselPerL,
      gasolinePerL: gasolinePerL ?? this.gasolinePerL,
      updatedAt: updatedAt ?? this.updatedAt,
      fuelFromLive: fuelFromLive ?? this.fuelFromLive,
    );
  }

  Map<String, dynamic> toMap() => {
        'fertilizerPerKg': fertilizerPerKg,
        'seedPerKg': seedPerKg,
        'laborPerDay': laborPerDay,
        'cropSalePerKg': cropSalePerKg,
        'updatedAt': updatedAt.toIso8601String(),
      };

  /// Varsayılan fiyat defteri — TZOB bülteni referanslı [fertilizerPrices]
  /// (50 kg çuval → ₺/kg) + makul ürün satış fiyatları (düzenlenebilir).
  factory PriceBook.defaults() {
    final fert = <String, double>{};
    for (final fp in fertilizerPrices) {
      final n = normalizeTr(fp.name);
      // 50 kg çuval fiyatı → ₺/kg.
      final perKg = fp.tryPrice / 50.0;
      if (n.contains('dap')) {
        fert['dap'] = perKg;
      } else if (n.contains('amonyum')) {
        fert['amonyum'] = perKg;
      } else if (n.contains('ure')) {
        fert['ure'] = perKg;
      } else if (n.contains('can')) {
        fert['can'] = perKg;
      } else if (n.contains('npk') || n.contains('15-15')) {
        fert['npk'] = perKg;
      }
    }
    // Eksik kalan tipler için makul varsayılan.
    fert.putIfAbsent('dap', () => 57);
    fert.putIfAbsent('ure', () => 39);
    fert.putIfAbsent('amonyum', () => 28);
    fert.putIfAbsent('npk', () => 42);
    fert.putIfAbsent('can', () => 25);

    return PriceBook(
      fertilizerPerKg: fert,
      seedPerKg: 120,
      laborPerDay: 1000,
      cropSalePerKg: const {
        'aycicegi': 25,
        'bugday': 9,
        'arpa': 8,
        'misir': 9,
        'celtik': 18,
        'pamuk': 28,
        'nohut': 35,
        'mercimek': 30,
        'fasulye': 40,
        'domates': 12,
        'biber': 20,
        'patlican': 15,
        'patates': 12,
        'sogan': 10,
        'havuc': 11,
        'zeytin': 35,
        'seker pancari': 3,
      },
      dieselPerL: 0,
      gasolinePerL: 0,
      updatedAt: DateTime.now(),
      fuelFromLive: false,
    );
  }
}

/// Fiyat defterini Hive'dan yükler/saklar; akaryakıtı EPDK'dan canlı doldurur.
class PriceBookService {
  PriceBookService._();

  static const _boxName = 'price_book';
  static const _key = 'latest';

  static Future<Box> _openBox() async {
    if (Hive.isBoxOpen(_boxName)) return Hive.box(_boxName);
    return Hive.openBox(_boxName);
  }

  /// Kayıtlı düzenlenebilir fiyatları okur (yoksa varsayılan) ve üstüne canlı
  /// akaryakıtı yazar. Ağ yoksa cache/fallback akaryakıt kullanılır.
  static Future<PriceBook> load() async {
    PriceBook base = PriceBook.defaults();
    try {
      final box = await _openBox();
      final raw = box.get(_key);
      if (raw is Map) {
        base = _fromMap(Map<String, dynamic>.from(raw), base);
      }
    } catch (_) {}

    // Akaryakıt — canlı EPDK (fallback: cache → makul varsayılan).
    double diesel = base.dieselPerL;
    double gasoline = base.gasolinePerL;
    bool live = false;
    try {
      final fuel =
          await EpdkPricesApi.fetchFuel() ?? EpdkPricesApi.fallbackPrices();
      if (fuel.dieselTry > 0) diesel = fuel.dieselTry;
      if (fuel.gasolineTry > 0) gasoline = fuel.gasolineTry;
      live = !fuel.fromCache;
    } catch (_) {}

    return base.copyWith(
      dieselPerL: diesel,
      gasolinePerL: gasoline,
      fuelFromLive: live,
    );
  }

  /// Çiftçinin düzenlediği fiyatları saklar (akaryakıt hariç — o canlı gelir).
  static Future<void> save(PriceBook book) async {
    try {
      final box = await _openBox();
      await box.put(_key, {
        ...book.toMap(),
        'updatedAt': DateTime.now().toIso8601String(),
      });
    } catch (_) {}
  }

  static PriceBook _fromMap(Map<String, dynamic> m, PriceBook fallback) {
    Map<String, double> dbl(Object? v, Map<String, double> def) {
      if (v is Map) {
        final out = <String, double>{};
        v.forEach((k, val) {
          final d = (val is num) ? val.toDouble() : null;
          if (d != null) out[k.toString()] = d;
        });
        return out.isEmpty ? def : out;
      }
      return def;
    }

    return PriceBook(
      fertilizerPerKg: dbl(m['fertilizerPerKg'], fallback.fertilizerPerKg),
      seedPerKg: (m['seedPerKg'] as num?)?.toDouble() ?? fallback.seedPerKg,
      laborPerDay:
          (m['laborPerDay'] as num?)?.toDouble() ?? fallback.laborPerDay,
      cropSalePerKg: dbl(m['cropSalePerKg'], fallback.cropSalePerKg),
      dieselPerL: 0,
      gasolinePerL: 0,
      updatedAt: DateTime.tryParse(m['updatedAt']?.toString() ?? '') ??
          fallback.updatedAt,
      fuelFromLive: false,
    );
  }
}
