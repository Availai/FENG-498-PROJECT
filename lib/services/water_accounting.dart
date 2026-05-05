import 'dart:math' as math;

import '../data/supported_crops.dart';

const double fallbackMmPerWaterMinute = 0.8;

class WaterImpact {
  final double mm;
  final double liters;
  final String source;
  final String method;

  const WaterImpact({
    required this.mm,
    required this.liters,
    required this.source,
    required this.method,
  });

  bool get hasWater => mm > 0 || liters > 0;
}

class WaterAccounting {
  const WaterAccounting._();

  static WaterImpact calculate({
    Map<String, dynamic>? metadata,
    double? quantity,
    String? quantityUnit,
    required double areaSqm,
    int? plantCount,
    String? irrigationMethod,
  }) {
    final meta = metadata ?? const <String, dynamic>{};
    final safeAreaSqm = areaSqm > 0 ? areaSqm : 1000.0;
    final method =
        (irrigationMethod ?? _stringValue(meta, ['irrigation_method']) ?? '')
            .trim();

    final explicitMm = _doubleValue(meta, ['effective_water_mm', 'water_mm']);
    if (explicitMm != null && explicitMm >= 0) {
      final liters = _doubleValue(meta, ['effective_water_liters']) ??
          explicitMm * safeAreaSqm;
      return WaterImpact(
        mm: explicitMm,
        liters: liters,
        source: 'mm',
        method: method,
      );
    }

    final explicitEffectiveLiters =
        _doubleValue(meta, ['effective_water_liters']);
    if (explicitEffectiveLiters != null && explicitEffectiveLiters > 0) {
      return WaterImpact(
        mm: explicitEffectiveLiters / safeAreaSqm,
        liters: explicitEffectiveLiters,
        source: 'liters',
        method: method,
      );
    }

    final rawLiters = _doubleValue(
          meta,
          ['water_liters', 'water_l', 'liters'],
        ) ??
        (_isLiterUnit(quantityUnit) ? quantity : null);
    if (rawLiters != null && rawLiters > 0) {
      final effectiveLiters = rawLiters * methodEfficiency(method);
      return WaterImpact(
        mm: effectiveLiters / safeAreaSqm,
        liters: effectiveLiters,
        source: 'liters',
        method: method,
      );
    }

    final minutes = _doubleValue(
          meta,
          ['duration_minutes', 'water_minutes', 'minutes'],
        ) ??
        (_isMinuteUnit(quantityUnit) ? quantity : null);
    if (minutes != null && minutes > 0) {
      final mm = durationToMm(
        method: method,
        minutes: minutes,
        plantCount: plantCount,
        areaSqm: safeAreaSqm,
      );
      return WaterImpact(
        mm: mm,
        liters: mm * safeAreaSqm,
        source: 'duration',
        method: method,
      );
    }

    return WaterImpact(
      mm: 0,
      liters: 0,
      source: 'none',
      method: method,
    );
  }

  static double durationToMm({
    required String method,
    required double minutes,
    required double areaSqm,
    int? plantCount,
  }) {
    if (minutes <= 0 || areaSqm <= 0) return 0;
    final hours = minutes / 60.0;
    final key = SupportedCrops.normalize(method);
    if (key.contains('damla') || key.contains('drip')) {
      const dripperLiterPerHour = 1.6;
      if (plantCount != null && plantCount > 0) {
        return (plantCount * dripperLiterPerHour * hours) / areaSqm;
      }
      return minutes * fallbackMmPerWaterMinute;
    }
    if (key.contains('yagmurlama') || key.contains('sprinkler')) {
      return 7.0 * hours;
    }
    if (key.contains('karik') || key.contains('furrow')) {
      return 10.0 * hours;
    }
    if (key.contains('el') || key.contains('elle') || key.contains('hand')) {
      return 5.0 * hours;
    }
    return minutes * fallbackMmPerWaterMinute;
  }

  static double methodEfficiency(String method) {
    final key = SupportedCrops.normalize(method);
    if (key.contains('damla') || key.contains('drip')) return 0.90;
    if (key.contains('yagmurlama') || key.contains('sprinkler')) return 0.75;
    if (key.contains('karik') || key.contains('furrow')) return 0.65;
    if (key.contains('el') || key.contains('elle') || key.contains('hand')) {
      return 0.80;
    }
    return 0.75;
  }

  static int estimatePlantCount({
    required double areaSqm,
    double? rowSpacingCm,
    double? plantSpacingCm,
  }) {
    final rowM = ((rowSpacingCm ?? 70) / 100).clamp(0.1, 20.0).toDouble();
    final plantM = ((plantSpacingCm ?? 30) / 100).clamp(0.05, 20.0).toDouble();
    return math.max(1, (areaSqm / (rowM * plantM)).round());
  }

  static double? _doubleValue(
      Map<String, dynamic> metadata, List<String> keys) {
    for (final key in keys) {
      final value = metadata[key];
      if (value is num) return value.toDouble();
      if (value is String) {
        final parsed = double.tryParse(value.replaceAll(',', '.'));
        if (parsed != null) return parsed;
      }
    }
    return null;
  }

  static String? _stringValue(
      Map<String, dynamic> metadata, List<String> keys) {
    for (final key in keys) {
      final value = metadata[key]?.toString().trim();
      if (value != null && value.isNotEmpty) return value;
    }
    return null;
  }

  static bool _isLiterUnit(String? unit) {
    if (unit == null) return false;
    final key = SupportedCrops.normalize(unit);
    return key == 'l' || key == 'lt' || key.contains('litre');
  }

  static bool _isMinuteUnit(String? unit) {
    if (unit == null) return false;
    final key = SupportedCrops.normalize(unit);
    return key == 'dk' || key.contains('dakika') || key.contains('minute');
  }
}
