/// SoilGrids API — ISRIC World Soil Information (free, no key)
///
/// REST endpoint: https://rest.isric.org/soilgrids/v2.0/properties/query
/// Returns soil properties at a given lat/lon for 0-5 cm, 5-15 cm, 15-30 cm depths.
library;

import 'dart:convert';
import 'package:http/http.dart' as http;

// ─────────────────────────────────────────────────────────────────────────────
// MODELLER
// ─────────────────────────────────────────────────────────────────────────────

class SoilProfile {
  /// pH (water) × 10  →  divide by 10 for real pH
  final double phH2o;

  /// Organic carbon g/kg
  final double organicCarbonGKg;

  /// Clay content g/kg (divide by 10 for %)
  final double clayGKg;

  /// Sand content g/kg
  final double sandGKg;

  /// Silt content g/kg
  final double siltGKg;

  /// Bulk density kg/m³ (cg/cm³ × 100 in API)
  final double bulkDensityKgM3;

  /// Cation Exchange Capacity mmol(c)/kg
  final double cecMmolKg;

  /// Nitrogen g/kg
  final double nitrogenGKg;

  const SoilProfile({
    required this.phH2o,
    required this.organicCarbonGKg,
    required this.clayGKg,
    required this.sandGKg,
    required this.siltGKg,
    required this.bulkDensityKgM3,
    required this.cecMmolKg,
    required this.nitrogenGKg,
  });

  double get phReal => phH2o / 10;
  double get clayPct => clayGKg / 10;
  double get sandPct => sandGKg / 10;
  double get siltPct => siltGKg / 10;
  double get organicMatterPct => organicCarbonGKg * 1.724 / 10; // Van Bemmelen factor

  String get textureClass {
    if (clayPct >= 40) return 'Ağır Killi';
    if (clayPct >= 27 && siltPct >= 28) return 'Killi';
    if (sandPct >= 70) return 'Kumlu';
    if (siltPct >= 50) return 'Siltli';
    if (clayPct >= 20 && sandPct <= 45) return 'Killi-Tınlı';
    return 'Tınlı';
  }

  String get phDescription {
    final ph = phReal;
    if (ph < 5.5) return 'Çok Asitli — kireçleme önerilir';
    if (ph < 6.0) return 'Asitli — çoğu ürün için sınırda';
    if (ph < 7.0) return 'Hafif Asitli — ideal aralık';
    if (ph < 7.5) return 'Nötr — ideal';
    if (ph < 8.0) return 'Hafif Bazik — kabul edilebilir';
    return 'Bazik — kükürt uygulaması düşünülebilir';
  }

  /// Actionable Turkish agronomic assessment
  String get assessment {
    final issues = <String>[];
    if (phReal < 5.8) issues.add('pH düşük (${phReal.toStringAsFixed(1)}) — dekar başına 200-400 kg kireç uygula');
    if (phReal > 8.0) issues.add('pH yüksek (${phReal.toStringAsFixed(1)}) — kükürt veya asit gübre kullan');
    if (organicCarbonGKg < 5) issues.add('Organik madde yetersiz — ahır gübresi veya yeşil gübre önerilir');
    if (clayPct > 50) issues.add('Ağır kil — drenaj sorununa dikkat');
    if (sandPct > 75) issues.add('Kumlu toprak — sık sulama ve bölünmüş gübreleme uygula');
    if (nitrogenGKg < 1) issues.add('Azot yetersiz — ekim öncesi N gübresi planla');
    if (issues.isEmpty) return 'Toprak özellikleri genel tarım için uygun görünüyor.';
    return issues.join('\n');
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SERVİS
// ─────────────────────────────────────────────────────────────────────────────

class SoilGridsApi {
  static const _base = 'https://rest.isric.org/soilgrids/v2.0/properties/query';
  static const _timeout = Duration(seconds: 15);

  static const _props = [
    'phh2o', 'ocd', 'clay', 'sand', 'silt', 'bdod', 'cec', 'nitrogen',
  ];

  /// Fetch top-soil profile (mean of 0-5 cm and 5-15 cm layers)
  static Future<SoilProfile> fetchProfile({
    required double lat,
    required double lon,
  }) async {
    final propParam = _props.map((p) => 'property=$p').join('&');
    final uri = Uri.parse('$_base?lon=$lon&lat=$lat&$propParam&depth=0-5cm&depth=5-15cm&value=mean');
    final resp = await http.get(uri).timeout(_timeout);
    if (resp.statusCode != 200) {
      throw Exception('SoilGrids: HTTP ${resp.statusCode}');
    }
    return _parse(jsonDecode(resp.body) as Map<String, dynamic>);
  }

  static SoilProfile _parse(Map<String, dynamic> body) {
    final layers = (body['properties']['layers'] as List).cast<Map<String, dynamic>>();

    double mean(String name) {
      final layer = layers.firstWhere((l) => l['name'] == name, orElse: () => <String, dynamic>{});
      if (layer.isEmpty) return 0;
      final depths = (layer['depths'] as List).cast<Map<String, dynamic>>();
      final vals = depths.map((d) => (d['values']['mean'] as num?)?.toDouble() ?? 0).toList();
      if (vals.isEmpty) return 0;
      return vals.reduce((a, b) => a + b) / vals.length;
    }

    return SoilProfile(
      phH2o: mean('phh2o'),
      organicCarbonGKg: mean('ocd'),
      clayGKg: mean('clay'),
      sandGKg: mean('sand'),
      siltGKg: mean('silt'),
      bulkDensityKgM3: mean('bdod'),
      cecMmolKg: mean('cec'),
      nitrogenGKg: mean('nitrogen'),
    );
  }
}
