/// Perenual API — Plant encyclopedia with care data
///
/// Requires PERENUAL_API_KEY in .env
/// Docs: https://perenual.com/docs/api
library;

import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

// ─────────────────────────────────────────────────────────────────────────────
// MODELLER
// ─────────────────────────────────────────────────────────────────────────────

class PerenualPlant {
  final int id;
  final String commonName;
  final List<String> scientificNames;
  final String? imageUrl;
  final String? cycle; // annual / perennial / biennial
  final String? watering; // frequent / average / minimum / none
  final List<String> sunlight;
  final List<String> maintenance;
  final String? careLevel;
  final List<String> flowers;
  final bool edible;
  final bool poisonous;

  const PerenualPlant({
    required this.id,
    required this.commonName,
    required this.scientificNames,
    this.imageUrl,
    this.cycle,
    this.watering,
    required this.sunlight,
    required this.maintenance,
    this.careLevel,
    required this.flowers,
    required this.edible,
    required this.poisonous,
  });

  factory PerenualPlant.fromJson(Map<String, dynamic> j) {
    return PerenualPlant(
      id: j['id'] as int,
      commonName: j['common_name'] as String? ?? '',
      scientificNames: (j['scientific_name'] as List? ?? []).cast<String>(),
      imageUrl: (j['default_image'] as Map<String, dynamic>?)?['medium_url']
          as String?,
      cycle: j['cycle'] as String?,
      watering: j['watering'] as String?,
      sunlight: (j['sunlight'] as List? ?? []).cast<String>(),
      maintenance: (j['maintenance'] as List? ?? []).cast<String>(),
      careLevel: j['care_level'] as String?,
      flowers: (j['flowers'] as List? ?? []).cast<String>(),
      edible: (j['edible_fruit'] as bool?) ?? false,
      poisonous: (j['poisonous_to_humans'] as bool?) ?? false,
    );
  }

  /// Turkish care summary
  String get careSummaryTr {
    final lines = <String>[];
    switch (watering?.toLowerCase()) {
      case 'frequent':
        lines.add('💧 Sulama: Sık (her 2-3 günde bir)');
      case 'average':
        lines.add('💧 Sulama: Orta (haftada 1-2)');
      case 'minimum':
        lines.add('💧 Sulama: Az (2 haftada bir)');
      case 'none':
        lines.add('💧 Sulama: Gerek yok');
    }
    if (sunlight.isNotEmpty) {
      final sun = sunlight.first.toLowerCase();
      if (sun.contains('full sun')) {
        lines.add('☀️ Işık: Tam güneş gerekli');
      } else if (sun.contains('part shade')) {
        lines.add('🌤️ Işık: Yarı gölge uygun');
      } else if (sun.contains('full shade')) {
        lines.add('🌑 Işık: Gölgede yetişir');
      }
    }
    if (poisonous) lines.add('⚠️ İnsan/hayvan için zehirli');
    if (edible) lines.add('✅ Yenilebilir meyve/ürün');
    return lines.isEmpty ? 'Bakım bilgisi mevcut değil.' : lines.join('\n');
  }
}

class PerenualCareDetail {
  final int plantId;
  final String? pruning;
  final String? hardiness;
  final String? soilType;
  final String? phRange;
  final String? growthRate;
  final String? spacing;
  final String? depth;
  final String? bestTime;

  const PerenualCareDetail({
    required this.plantId,
    this.pruning,
    this.hardiness,
    this.soilType,
    this.phRange,
    this.growthRate,
    this.spacing,
    this.depth,
    this.bestTime,
  });

  factory PerenualCareDetail.fromJson(int id, Map<String, dynamic> j) {
    return PerenualCareDetail(
      plantId: id,
      pruning: (j['pruning'] as List?)?.join(', '),
      hardiness: j['hardiness']?.toString(),
      soilType: (j['soil'] as List?)?.join(', '),
      phRange: j['maintenance'] as String?,
      growthRate: j['growth_rate'] as String?,
      spacing: j['spacing']?.toString(),
      depth: j['depth']?.toString(),
      bestTime: (j['best_watering'] as List?)?.join(', '),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SERVİS
// ─────────────────────────────────────────────────────────────────────────────

class PerenualApi {
  static const _base = 'https://perenual.com/api';
  static const _timeout = Duration(seconds: 12);

  static String get _key {
    final k = dotenv.env['PERENUAL_API_KEY'] ?? '';
    if (k.isEmpty) throw Exception('PERENUAL_API_KEY not set in .env');
    return k;
  }

  /// Bitki ara (isim ile)
  static Future<List<PerenualPlant>> search(String query,
      {int page = 1}) async {
    final encoded = Uri.encodeComponent(query);
    final uri =
        Uri.parse('$_base/species-list?key=$_key&q=$encoded&page=$page');
    final resp = await http.get(uri).timeout(_timeout);
    if (resp.statusCode != 200) {
      throw Exception('Perenual search: HTTP ${resp.statusCode}');
    }
    final body = jsonDecode(resp.body) as Map<String, dynamic>;
    final data = (body['data'] as List).cast<Map<String, dynamic>>();
    return data.map(PerenualPlant.fromJson).toList();
  }

  /// Belirli bir bitkinin detaylarını getir
  static Future<PerenualPlant?> detail(int plantId) async {
    final uri = Uri.parse('$_base/species/details/$plantId?key=$_key');
    final resp = await http.get(uri).timeout(_timeout);
    if (resp.statusCode == 404) return null;
    if (resp.statusCode != 200) {
      throw Exception('Perenual detail: HTTP ${resp.statusCode}');
    }
    return PerenualPlant.fromJson(
        jsonDecode(resp.body) as Map<String, dynamic>);
  }

  /// Bakım rehberi detayları
  static Future<PerenualCareDetail?> careGuide(int plantId) async {
    final uri = Uri.parse(
        '$_base/species-care-guide-list?key=$_key&species_id=$plantId');
    final resp = await http.get(uri).timeout(_timeout);
    if (resp.statusCode != 200) return null;
    final body = jsonDecode(resp.body) as Map<String, dynamic>;
    final data = (body['data'] as List?)?.cast<Map<String, dynamic>>();
    if (data == null || data.isEmpty) return null;
    return PerenualCareDetail.fromJson(plantId, data.first);
  }

  /// İlk eşleşmeyi getir (offline encyclopedia fallback)
  static Future<PerenualPlant?> firstMatch(String cropNameTr) async {
    try {
      final results = await search(cropNameTr);
      return results.isEmpty ? null : results.first;
    } catch (_) {
      return null;
    }
  }
}
