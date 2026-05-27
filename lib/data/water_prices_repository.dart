/// Bölgesel su ve elektrik fiyatları için asset tabanlı repository.
///
/// Veri: `assets/data/regional_water_prices.json` (kaynak: DSİ, EPDK 2025).
/// CLAUDE.md §10 uyumlu: her değer kaynak ile etiketlenmiş.
library;

import 'dart:convert';
import 'package:flutter/services.dart';

class WaterPriceDefaults {
  final double waterTlPerM3;
  final double electricityTlPerKwh;
  final double pumpKwhPerM3ShallowWell;
  final double pumpKwhPerM3DeepWell;
  const WaterPriceDefaults({
    required this.waterTlPerM3,
    required this.electricityTlPerKwh,
    required this.pumpKwhPerM3ShallowWell,
    required this.pumpKwhPerM3DeepWell,
  });
  factory WaterPriceDefaults.fromJson(Map<String, dynamic> j) =>
      WaterPriceDefaults(
        waterTlPerM3: (j['water_tl_per_m3'] as num).toDouble(),
        electricityTlPerKwh: (j['electricity_tl_per_kwh'] as num).toDouble(),
        pumpKwhPerM3ShallowWell:
            (j['pump_kwh_per_m3_shallow_well'] as num).toDouble(),
        pumpKwhPerM3DeepWell:
            (j['pump_kwh_per_m3_deep_well'] as num).toDouble(),
      );
}

class RegionalWaterPrice {
  final String province;
  final double waterTlPerM3;
  final String note;
  const RegionalWaterPrice({
    required this.province,
    required this.waterTlPerM3,
    required this.note,
  });
  factory RegionalWaterPrice.fromJson(Map<String, dynamic> j) =>
      RegionalWaterPrice(
        province: j['province'] as String,
        waterTlPerM3: (j['water_tl_per_m3'] as num).toDouble(),
        note: j['note'] as String? ?? '',
      );
}

class WaterPricesData {
  final String schemaVersion;
  final String disclaimer;
  final WaterPriceDefaults defaults;
  final List<RegionalWaterPrice> regions;
  const WaterPricesData({
    required this.schemaVersion,
    required this.disclaimer,
    required this.defaults,
    required this.regions,
  });

  /// İl adına göre su fiyatı; bulamazsa varsayılan.
  double waterPriceFor(String? province) {
    if (province == null || province.trim().isEmpty) {
      return defaults.waterTlPerM3;
    }
    final norm = _norm(province);
    for (final r in regions) {
      if (_norm(r.province) == norm) return r.waterTlPerM3;
    }
    return defaults.waterTlPerM3;
  }

  static String _norm(String s) => s
      .toLowerCase()
      .trim()
      .replaceAll('ç', 'c')
      .replaceAll('ğ', 'g')
      .replaceAll('ı', 'i')
      .replaceAll('ö', 'o')
      .replaceAll('ş', 's')
      .replaceAll('ü', 'u');
}

class WaterPricesRepository {
  WaterPricesRepository._();
  static final instance = WaterPricesRepository._();

  WaterPricesData? _cache;
  Future<WaterPricesData>? _loading;

  Future<WaterPricesData> load() {
    if (_cache != null) return Future.value(_cache);
    return _loading ??= _loadFromAsset();
  }

  Future<WaterPricesData> _loadFromAsset() async {
    final raw = await rootBundle
        .loadString('assets/data/regional_water_prices.json');
    final json = jsonDecode(raw) as Map<String, dynamic>;
    final data = WaterPricesData(
      schemaVersion: json['schema_version'] as String,
      disclaimer: json['disclaimer'] as String,
      defaults: WaterPriceDefaults.fromJson(
          json['defaults'] as Map<String, dynamic>),
      regions: (json['regional_overrides'] as List)
          .map((e) => RegionalWaterPrice.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
    _cache = data;
    return data;
  }
}
