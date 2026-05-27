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
    // SDI ve yüzey damla — damlatıcı başına ~1.6 L/saat.
    if (key.contains('sdi') ||
        key.contains('yuzey alti') ||
        key.contains('subsurface') ||
        key.contains('damla') ||
        key.contains('drip')) {
      const dripperLiterPerHour = 1.6;
      if (plantCount != null && plantCount > 0) {
        return (plantCount * dripperLiterPerHour * hours) / areaSqm;
      }
      return minutes * fallbackMmPerWaterMinute;
    }
    // Sisleme — saatte ~3 mm (kuru hava nem yönetimi).
    if (key.contains('sis') || key.contains('fog') || key.contains('mist')) {
      return 3.0 * hours;
    }
    // Mikro yağmurlama — ~5 mm/sa (bahçe).
    if (key.contains('mikro') || key.contains('micro')) {
      return 5.0 * hours;
    }
    // Center-pivot — geniş alan, saatte ~6 mm.
    if (key.contains('pivot')) {
      return 6.0 * hours;
    }
    // Sabit yağmurlama — saatte ~7 mm.
    if (key.contains('yagmurlama') || key.contains('sprinkler')) {
      return 7.0 * hours;
    }
    // Karık/salma — saatte ~12 mm (yüksek hacim, düşük verim).
    if (key.contains('karik') ||
        key.contains('salma') ||
        key.contains('tava') ||
        key.contains('furrow')) {
      return 12.0 * hours;
    }
    // Elle (kova/hortum) — saatte ~5 mm.
    if (key.contains('el') || key.contains('elle') || key.contains('hand')) {
      return 5.0 * hours;
    }
    return minutes * fallbackMmPerWaterMinute;
  }

  /// Sulama yöntemi randımanı (etken su / verilen su).
  ///
  /// Değerler `assets/data/irrigation_methods.json` aralıklarının orta noktası
  /// alınarak hizalanmıştır (kaynaklar: TAGEM, suverimliligi.gov.tr).
  ///
  /// - Yüzey altı damla (SDI): %92-97 → 0.94
  /// - Yüzey damla: %90-95 → 0.92
  /// - Mikro yağmurlama / sisleme: %80-90 → 0.85
  /// - Center-pivot: %75-85 → 0.80
  /// - Sabit yağmurlama: %70-80 → 0.75
  /// - Karık / salma: %40-60 → 0.50
  /// - Elle (kova/hortum, yerel): ~0.80 (hedefli ama yüksek değişken)
  static double methodEfficiency(String method) {
    final key = SupportedCrops.normalize(method);
    if (key.contains('sdi') ||
        key.contains('yuzey alti') ||
        key.contains('subsurface')) {
      return 0.94;
    }
    if (key.contains('damla') || key.contains('drip')) return 0.92;
    if (key.contains('sis') || key.contains('fog') || key.contains('mist')) {
      return 0.88;
    }
    if (key.contains('mikro') || key.contains('micro')) return 0.85;
    if (key.contains('pivot')) return 0.80;
    if (key.contains('yagmurlama') || key.contains('sprinkler')) return 0.75;
    if (key.contains('karik') ||
        key.contains('salma') ||
        key.contains('tava') ||
        key.contains('furrow')) {
      return 0.50;
    }
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
