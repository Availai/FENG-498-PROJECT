import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart';

/// Küratörlü Türkiye bitki bilgi tabanı. seed_plants.json -> SQLite asset.
///
/// Asset (`assets/data/turkish_crops.sqlite`) uygulama açıldığında app
/// documents dir'e kopyalanır, sonra read-only açılır. Asset'in byte boyutu
/// değiştiğinde kopya tazelenir.
class TurkishCropsRepository {
  TurkishCropsRepository._();

  static final TurkishCropsRepository instance = TurkishCropsRepository._();

  static const _assetPath = 'assets/data/turkish_crops.sqlite';
  static const _localFileName = 'turkish_crops.sqlite';

  Database? _db;
  bool _initTried = false;

  bool get isReady => _db != null;

  Future<void> ensureReady() async {
    if (_initTried) return;
    _initTried = true;
    try {
      final docDir = await getApplicationDocumentsDirectory();
      final localPath = p.join(docDir.path, _localFileName);
      final localFile = File(localPath);

      final assetBytes = await _loadAssetOrNull();
      if (assetBytes == null) return;

      final needsCopy = !localFile.existsSync() ||
          await localFile.length() != assetBytes.lengthInBytes;
      if (needsCopy) {
        await localFile.writeAsBytes(
          assetBytes.buffer.asUint8List(),
          flush: true,
        );
      }
      _db = sqlite3.open(localPath, mode: OpenMode.readOnly);
    } catch (_) {
      _db = null;
    }
  }

  Future<ByteData?> _loadAssetOrNull() async {
    try {
      return await rootBundle.load(_assetPath);
    } catch (_) {
      return null;
    }
  }

  List<TurkishCrop> search({
    required String query,
    String? category,
    int limit = 80,
  }) {
    final db = _db;
    if (db == null) return const [];
    final norm = _normalize(query);

    final where = <String>[];
    final args = <Object?>[];
    if (norm.isNotEmpty) {
      where.add('search_key LIKE ?');
      args.add('%$norm%');
    }
    if (category != null && category.isNotEmpty && category != 'Tümü') {
      where.add('category = ?');
      args.add(category);
    }
    final whereClause = where.isEmpty ? '' : 'WHERE ${where.join(' AND ')}';

    final sql = '''
      SELECT * FROM crops
      $whereClause
      ORDER BY name_tr COLLATE NOCASE
      LIMIT ?
    ''';
    args.add(limit);
    final rs = db.select(sql, args);
    return rs.map(TurkishCrop.fromRow).toList(growable: false);
  }

  TurkishCrop? findByName(String name) {
    final db = _db;
    if (db == null) return null;
    final norm = _normalize(name);
    final rs = db.select(
      'SELECT * FROM crops WHERE search_key LIKE ? LIMIT 1',
      ['%$norm%'],
    );
    if (rs.isEmpty) return null;
    return TurkishCrop.fromRow(rs.first);
  }

  List<String> listCategories() {
    final db = _db;
    if (db == null) return const [];
    final rs = db.select(
      'SELECT DISTINCT category FROM crops ORDER BY category COLLATE NOCASE',
    );
    return ['Tümü', ...rs.map((r) => r['category'] as String)];
  }

  List<TurkishCrop> popular({int limit = 12}) {
    final db = _db;
    if (db == null) return const [];
    // İlk N bitki — isimden sıralı, yaygın ürünler seed'in başında.
    const priority = [
      'Domates','Buğday','Mısır','Salatalık','Patlıcan','Biber',
      'Patates','Soğan','Sarımsak','Kabak','Karpuz','Zeytin',
    ];
    final result = <TurkishCrop>[];
    for (final name in priority) {
      final c = findByName(name);
      if (c != null) result.add(c);
      if (result.length >= limit) break;
    }
    return result;
  }

  int totalCount() {
    final db = _db;
    if (db == null) return 0;
    final rs = db.select('SELECT COUNT(*) AS c FROM crops');
    return (rs.first['c'] as int?) ?? 0;
  }

  static String _normalize(String s) {
    const replacements = {
      'ı': 'i', 'ğ': 'g', 'ü': 'u', 'ş': 's', 'ö': 'o', 'ç': 'c',
      'İ': 'i', 'Ğ': 'g', 'Ü': 'u', 'Ş': 's', 'Ö': 'o', 'Ç': 'c',
    };
    final buf = StringBuffer();
    for (final ch in s.toLowerCase().split('')) {
      buf.write(replacements[ch] ?? ch);
    }
    return buf.toString().trim();
  }
}

class TurkishCrop {
  final int id;
  final String nameTr;
  final List<String> aliases;
  final String? scientificName;
  final String category;
  final List<int> sowingMonths;
  final List<int> harvestMonths;
  final double? tempMinC;
  final double? tempMaxC;
  final double? optimalTempC;
  final String? waterNeed;
  final String? sunNeed;
  final double? soilPhMin;
  final double? soilPhMax;
  final List<String> soilType;
  final List<String> regionSuitability;
  final String? fertilizerNotes;
  final List<String> commonPests;
  final List<String> commonDiseases;
  final String? growingTips;
  final int? daysToHarvest;

  const TurkishCrop({
    required this.id,
    required this.nameTr,
    required this.category,
    this.aliases = const [],
    this.scientificName,
    this.sowingMonths = const [],
    this.harvestMonths = const [],
    this.tempMinC,
    this.tempMaxC,
    this.optimalTempC,
    this.waterNeed,
    this.sunNeed,
    this.soilPhMin,
    this.soilPhMax,
    this.soilType = const [],
    this.regionSuitability = const [],
    this.fertilizerNotes,
    this.commonPests = const [],
    this.commonDiseases = const [],
    this.growingTips,
    this.daysToHarvest,
  });

  factory TurkishCrop.fromRow(Map<String, dynamic> r) {
    List<T> decodeList<T>(dynamic raw, T Function(dynamic) cast) {
      if (raw == null || raw.toString().isEmpty) return <T>[];
      try {
        final parsed = jsonDecode(raw as String);
        if (parsed is List) return parsed.map(cast).toList(growable: false);
      } catch (_) {}
      return <T>[];
    }

    return TurkishCrop(
      id: r['id'] as int,
      nameTr: r['name_tr'] as String,
      aliases: decodeList(r['aliases'], (v) => v.toString()),
      scientificName: r['scientific_name'] as String?,
      category: r['category'] as String,
      sowingMonths: decodeList(r['sowing_months'], (v) => (v as num).toInt()),
      harvestMonths: decodeList(r['harvest_months'], (v) => (v as num).toInt()),
      tempMinC: (r['temp_min_c'] as num?)?.toDouble(),
      tempMaxC: (r['temp_max_c'] as num?)?.toDouble(),
      optimalTempC: (r['optimal_temp_c'] as num?)?.toDouble(),
      waterNeed: r['water_need'] as String?,
      sunNeed: r['sun_need'] as String?,
      soilPhMin: (r['soil_ph_min'] as num?)?.toDouble(),
      soilPhMax: (r['soil_ph_max'] as num?)?.toDouble(),
      soilType: decodeList(r['soil_type'], (v) => v.toString()),
      regionSuitability:
          decodeList(r['region_suitability'], (v) => v.toString()),
      fertilizerNotes: r['fertilizer_notes'] as String?,
      commonPests: decodeList(r['common_pests'], (v) => v.toString()),
      commonDiseases: decodeList(r['common_diseases'], (v) => v.toString()),
      growingTips: r['growing_tips'] as String?,
      daysToHarvest: (r['days_to_harvest'] as num?)?.toInt(),
    );
  }

  /// Tarla çevre koşullarına göre 0-100 uygunluk skoru + sebep listesi.
  ///
  /// NaN/Inf/null değerler sessizce ignore edilir ve [SuitabilityScore.confidence]
  /// alanı 'medium' veya 'low' olarak döner — UI bunu kullanıcıya rozet olarak
  /// göstermelidir (eksik veya hatalı API cevabı sinyali).
  SuitabilityScore scoreFor({
    double? temperature,
    double? soilPh,
    double? weeklyRain,
    int? month,
    String? region,
  }) {
    double? safe(double? v) =>
        (v == null || v.isNaN || v.isInfinite) ? null : v;
    final t = safe(temperature);
    final ph = safe(soilPh);
    final rain = safe(weeklyRain);
    final m = (month == null || month < 1 || month > 12) ? null : month;

    double score = 70;
    final reasons = <String>[];
    int missing = 0;

    if (t == null) {
      missing++;
    } else if (tempMinC != null && t < tempMinC!) {
      score -= 25;
      reasons.add('Sıcaklık minimum ${tempMinC!.toStringAsFixed(0)}°C altında');
    } else if (tempMaxC != null && t > tempMaxC!) {
      score -= 25;
      reasons.add('Sıcaklık maksimum ${tempMaxC!.toStringAsFixed(0)}°C üstünde');
    } else if (optimalTempC != null) {
      final diff = (t - optimalTempC!).abs();
      if (diff <= 3) {
        score += 10;
      } else if (diff <= 7) {
        score += 3;
      } else {
        score -= 5;
      }
    }

    if (ph == null) {
      missing++;
    } else if (soilPhMin != null && soilPhMax != null) {
      if (ph >= soilPhMin! && ph <= soilPhMax!) {
        score += 8;
        reasons.add('pH uygun (${ph.toStringAsFixed(1)})');
      } else {
        score -= 15;
        reasons.add('pH uygun değil (tercih ${soilPhMin!.toStringAsFixed(1)}-${soilPhMax!.toStringAsFixed(1)})');
      }
    }

    if (m == null) {
      missing++;
    } else if (sowingMonths.isNotEmpty) {
      // Mevsime hoşgörülü: ±1 ay kabul.
      final ok = sowingMonths.any((mm) => (mm - m).abs() <= 1 || (12 - (mm - m).abs()) <= 1);
      if (ok) {
        score += 6;
      } else {
        score -= 8;
        reasons.add('Ekim dönemi dışında');
      }
    }

    if (rain == null) {
      missing++;
    } else if (waterNeed != null) {
      if (waterNeed == 'high' && rain < 10) {
        score -= 5;
        reasons.add('Yüksek su ihtiyacı, yağış az (sulama gerekir)');
      } else if (waterNeed == 'low' && rain > 30) {
        score -= 3;
      }
    }

    if (region != null && regionSuitability.isNotEmpty) {
      if (regionSuitability.contains(region)) {
        score += 5;
      } else {
        score -= 4;
        reasons.add('Bölge ($region) önerilen listede değil');
      }
    }

    // Çok sayıda eksik veri varsa güven düşer — kullanıcı uyarılmalı.
    final confidence = missing >= 3
        ? 'low'
        : (missing >= 1 ? 'medium' : 'high');
    if (missing >= 2) {
      reasons.add('Bazı çevre verileri eksik ($missing alan)');
    }

    return SuitabilityScore(
      score: score.clamp(0, 100).toDouble(),
      reasons: reasons,
      confidence: confidence,
    );
  }
}

class SuitabilityScore {
  final double score;
  final List<String> reasons;
  /// 'high' | 'medium' | 'low' — giriş veri kalitesine göre.
  final String confidence;
  const SuitabilityScore({
    required this.score,
    required this.reasons,
    this.confidence = 'high',
  });
}
