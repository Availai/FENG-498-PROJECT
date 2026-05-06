import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart';

import '../core/rule_engine/rule.dart';

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
      'Domates',
      'Buğday',
      'Mısır',
      'Salatalık',
      'Patlıcan',
      'Biber',
      'Patates',
      'Soğan',
      'Sarımsak',
      'Kabak',
      'Karpuz',
      'Zeytin',
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

  /// v2 yapılandırılmış veri taşıyan öncelikli bitki (stable_id ile).
  ///
  /// Sadece 5 öncelikli ürün için doludur (CLAUDE.md sec 11). Diğerleri
  /// `null` döner — UI v1 alanlarına geri düşmelidir.
  CropV2Bundle? findV2ByStableId(String stableId) {
    final db = _db;
    if (db == null) return null;
    final rs = db.select(
      'SELECT name_tr, stable_id, v2_status, v2_confidence, v2_data '
      'FROM crops WHERE stable_id = ? LIMIT 1',
      [stableId],
    );
    if (rs.isEmpty) return null;
    return CropV2Bundle._fromRow(rs.first);
  }

  /// Stable id taşıyan tüm öncelikli kayıtlar — listeleme için.
  List<CropV2Summary> listPriorityV2() {
    final db = _db;
    if (db == null) return const [];
    final rs = db.select(
      'SELECT name_tr, stable_id, v2_status, v2_confidence FROM crops '
      'WHERE stable_id IS NOT NULL ORDER BY name_tr COLLATE NOCASE',
    );
    return rs
        .map((r) => CropV2Summary(
              nameTr: r['name_tr'] as String,
              stableId: r['stable_id'] as String,
              status: r['v2_status'] as String?,
              confidence: r['v2_confidence'] as String?,
            ))
        .toList(growable: false);
  }

  /// sources tablosundan kaynak metadata.
  AgriSource? findSource(String sourceId) {
    final db = _db;
    if (db == null) return null;
    final rs = db.select(
      'SELECT * FROM sources WHERE source_id = ? LIMIT 1',
      [sourceId],
    );
    if (rs.isEmpty) return null;
    return AgriSource._fromRow(rs.first);
  }

  List<AgriSource> listSources() {
    final db = _db;
    if (db == null) return const [];
    final rs = db.select(
      'SELECT * FROM sources ORDER BY institution, title',
    );
    return rs.map(AgriSource._fromRow).toList(growable: false);
  }

  static String _normalize(String s) {
    const replacements = {
      'ı': 'i',
      'ğ': 'g',
      'ü': 'u',
      'ş': 's',
      'ö': 'o',
      'ç': 'c',
      'İ': 'i',
      'Ğ': 'g',
      'Ü': 'u',
      'Ş': 's',
      'Ö': 'o',
      'Ç': 'c',
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
  final String? stableId;
  final String? v2Status;
  final String? v2Confidence;

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
    this.stableId,
    this.v2Status,
    this.v2Confidence,
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

    Map<String, dynamic>? decodeMap(dynamic raw) {
      if (raw == null || raw.toString().isEmpty) return null;
      try {
        final parsed = jsonDecode(raw as String);
        if (parsed is Map) return Map<String, dynamic>.from(parsed);
      } catch (_) {}
      return null;
    }

    List<Map<String, dynamic>> recordsFrom(
      Map<String, dynamic>? v2,
      String key,
    ) {
      final raw = v2?[key];
      if (raw is! List) return const [];
      return raw
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList(growable: false);
    }

    List<String> namesFrom(Map<String, dynamic>? v2, String key) {
      final out = <String>[];
      final seen = <String>{};
      for (final item in recordsFrom(v2, key)) {
        final name = item['name_tr']?.toString().trim();
        if (name == null || name.isEmpty || seen.contains(name)) continue;
        seen.add(name);
        out.add(name);
      }
      return out;
    }

    String? summariesFrom(Map<String, dynamic>? v2, String key) {
      final out = <String>[];
      for (final item in recordsFrom(v2, key)) {
        final summary = item['summary']?.toString().trim();
        if (summary != null && summary.isNotEmpty) out.add(summary);
        if (out.length >= 2) break;
      }
      return out.isEmpty ? null : out.join(' ');
    }

    final v2Data = decodeMap(r['v2_data']);
    final hasTrustedV2 = v2Data != null &&
        ((r['stable_id'] as String?)?.isNotEmpty ?? false);
    final v2Pests = namesFrom(v2Data, 'pests_v2');
    final v2Diseases = namesFrom(v2Data, 'diseases_v2');
    final v2Fertilizer = summariesFrom(v2Data, 'fertilizer_rules');

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
      fertilizerNotes:
          hasTrustedV2 ? v2Fertilizer : r['fertilizer_notes'] as String?,
      commonPests: hasTrustedV2
          ? v2Pests
          : decodeList(r['common_pests'], (v) => v.toString()),
      commonDiseases: hasTrustedV2
          ? v2Diseases
          : decodeList(r['common_diseases'], (v) => v.toString()),
      growingTips: hasTrustedV2 ? null : r['growing_tips'] as String?,
      daysToHarvest: (r['days_to_harvest'] as num?)?.toInt(),
      stableId: r['stable_id'] as String?,
      v2Status: r['v2_status'] as String?,
      v2Confidence: r['v2_confidence'] as String?,
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
      reasons
          .add('Sıcaklık maksimum ${tempMaxC!.toStringAsFixed(0)}°C üstünde');
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
        reasons.add(
            'pH uygun değil (tercih ${soilPhMin!.toStringAsFixed(1)}-${soilPhMax!.toStringAsFixed(1)})');
      }
    }

    if (m == null) {
      missing++;
    } else if (sowingMonths.isNotEmpty) {
      // Mevsime hoşgörülü: ±1 ay kabul.
      final ok = sowingMonths
          .any((mm) => (mm - m).abs() <= 1 || (12 - (mm - m).abs()) <= 1);
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
    final confidence =
        missing >= 3 ? 'low' : (missing >= 1 ? 'medium' : 'high');
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

/// 5 öncelikli ürün için yapılandırılmış v2 verisi (CLAUDE.md sec 11-14).
///
/// `evidence`, `diseases_v2`, `pests_v2`, `weeds_v2`, `rule_engine_rules`
/// alanları seed_plants.json içinde JSON olarak tutulur ve build script
/// `crops.v2_data` kolonuna serileştirir. Kural motoru (`RuleEngine`)
/// `rules` listesini doğrudan alıp facts ile değerlendirir.
class CropV2Bundle {
  final String stableId;
  final String nameTr;
  final String? status;
  final String? confidence;
  final List<String> sourceIds;
  final List<Rule> rules;
  final List<Map<String, dynamic>> diseases;
  final List<Map<String, dynamic>> pests;
  final List<Map<String, dynamic>> weeds;
  final List<Map<String, dynamic>> growthStages;
  final List<Map<String, dynamic>> fertilizerRules;
  final List<Map<String, dynamic>> irrigationRules;
  final List<Map<String, dynamic>> evidence;
  final List<String> missingInformation;

  const CropV2Bundle({
    required this.stableId,
    required this.nameTr,
    this.status,
    this.confidence,
    this.sourceIds = const [],
    this.rules = const [],
    this.diseases = const [],
    this.pests = const [],
    this.weeds = const [],
    this.growthStages = const [],
    this.fertilizerRules = const [],
    this.irrigationRules = const [],
    this.evidence = const [],
    this.missingInformation = const [],
  });

  factory CropV2Bundle._fromRow(Map<String, dynamic> r) {
    final raw = r['v2_data'] as String?;
    if (raw == null || raw.isEmpty) {
      return CropV2Bundle(
        stableId: r['stable_id'] as String? ?? '',
        nameTr: r['name_tr'] as String? ?? '',
        status: r['v2_status'] as String?,
        confidence: r['v2_confidence'] as String?,
      );
    }
    Map<String, dynamic> j;
    try {
      j = jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return CropV2Bundle(
        stableId: r['stable_id'] as String? ?? '',
        nameTr: r['name_tr'] as String? ?? '',
        status: r['v2_status'] as String?,
        confidence: r['v2_confidence'] as String?,
      );
    }

    List<Map<String, dynamic>> mapList(String key) {
      final v = j[key];
      if (v is! List) return const [];
      return v
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList(growable: false);
    }

    final rulesRaw = (j['rule_engine_rules'] as List?) ?? const [];
    final rules = rulesRaw
        .whereType<Map>()
        .map((m) => Rule.fromJson(Map<String, dynamic>.from(m)))
        .toList(growable: false);

    final missingRaw = (j['missing_information'] as List?) ?? const [];
    final missing =
        missingRaw.map((e) => e?.toString() ?? '').toList(growable: false);

    final sourceIdsRaw = (j['source_ids'] as List?) ?? const [];
    final sourceIds =
        sourceIdsRaw.map((e) => e?.toString() ?? '').toList(growable: false);

    return CropV2Bundle(
      stableId: r['stable_id'] as String? ?? (j['stable_id'] as String? ?? ''),
      nameTr: r['name_tr'] as String? ?? '',
      status: r['v2_status'] as String? ?? j['v2_status'] as String?,
      confidence: r['v2_confidence'] as String? ?? j['confidence'] as String?,
      sourceIds: sourceIds,
      rules: rules,
      diseases: mapList('diseases_v2'),
      pests: mapList('pests_v2'),
      weeds: mapList('weeds_v2'),
      growthStages: mapList('growth_stages'),
      fertilizerRules: mapList('fertilizer_rules'),
      irrigationRules: mapList('irrigation_rules'),
      evidence: mapList('evidence'),
      missingInformation: missing,
    );
  }
}

class CropV2Summary {
  final String nameTr;
  final String stableId;
  final String? status;
  final String? confidence;

  const CropV2Summary({
    required this.nameTr,
    required this.stableId,
    this.status,
    this.confidence,
  });
}

/// sources tablosundan kaynak metadata (CLAUDE.md sec 13).
class AgriSource {
  final String sourceId;
  final String title;
  final String? institution;
  final String? sourceType;
  final String? url;
  final int? publicationYear;
  final String? retrievedAt;
  final String? reliability;
  final String? notes;

  const AgriSource({
    required this.sourceId,
    required this.title,
    this.institution,
    this.sourceType,
    this.url,
    this.publicationYear,
    this.retrievedAt,
    this.reliability,
    this.notes,
  });

  factory AgriSource._fromRow(Map<String, dynamic> r) => AgriSource(
        sourceId: r['source_id'] as String,
        title: r['title'] as String,
        institution: r['institution'] as String?,
        sourceType: r['source_type'] as String?,
        url: r['url'] as String?,
        publicationYear: (r['publication_year'] as num?)?.toInt(),
        retrievedAt: r['retrieved_at'] as String?,
        reliability: r['reliability'] as String?,
        notes: r['notes'] as String?,
      );
}
