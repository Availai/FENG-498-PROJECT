import 'dart:convert';
import 'dart:math' as math;

import '../data/activity_types.dart';
import '../data/supported_crops.dart';
import '../data/turkiye_crop_guides.dart';

class CropFieldState {
  final String cropId;
  final String cropName;
  final double areaDekar;
  final double areaSqm;
  final int estimatedPlantCount;
  final double weeklyWaterMm;
  final double weeklyWaterLiters;
  final double seasonalWaterMm;
  final double seasonalWaterLiters;
  final double weeklyWaterTargetMm;
  final DateTime? lastWateredAt;
  final DateTime? lastFertilizedAt;
  final String? lastFertilizerName;
  final double? lastFertilizerKg;
  final DateTime? lastSprayedAt;
  final String? lastPesticideName;
  final String? lastPesticideTarget;
  final double harvestedKg;
  final double yieldKgPerDekar;

  const CropFieldState({
    required this.cropId,
    required this.cropName,
    required this.areaDekar,
    required this.areaSqm,
    required this.estimatedPlantCount,
    required this.weeklyWaterMm,
    required this.weeklyWaterLiters,
    required this.seasonalWaterMm,
    required this.seasonalWaterLiters,
    required this.weeklyWaterTargetMm,
    this.lastWateredAt,
    this.lastFertilizedAt,
    this.lastFertilizerName,
    this.lastFertilizerKg,
    this.lastSprayedAt,
    this.lastPesticideName,
    this.lastPesticideTarget,
    required this.harvestedKg,
    required this.yieldKgPerDekar,
  });

  double get weeklyWaterRatio =>
      weeklyWaterTargetMm <= 0 ? 0 : (weeklyWaterMm / weeklyWaterTargetMm);

  bool get weeklyWaterSatisfied => weeklyWaterRatio >= 0.85;

  String get waterSummary =>
      '${weeklyWaterMm.toStringAsFixed(1)} mm / ${weeklyWaterLiters.round()} L';

  String get fertilizerSummary {
    if (lastFertilizerName == null || lastFertilizerName!.isEmpty) {
      return 'Kayıt yok';
    }
    final qty = lastFertilizerKg == null ? '' : ' ${lastFertilizerKg!.toStringAsFixed(1)} kg';
    return '$lastFertilizerName$qty';
  }

  String get spraySummary {
    if (lastPesticideName == null || lastPesticideName!.isEmpty) {
      return 'Kayıt yok';
    }
    if (lastPesticideTarget == null || lastPesticideTarget!.isEmpty) {
      return lastPesticideName!;
    }
    return '$lastPesticideName • $lastPesticideTarget';
  }

  String get harvestSummary =>
      '${harvestedKg.toStringAsFixed(0)} kg • ${yieldKgPerDekar.toStringAsFixed(0)} kg/da';
}

class FieldStateService {
  const FieldStateService();

  List<CropFieldState> compute({
    required Map<String, dynamic> field,
    required List<Map<String, dynamic>> fieldCrops,
    required List<Map<String, dynamic>> activities,
    DateTime? now,
  }) {
    final t = now ?? DateTime.now();
    final supportedCrops = fieldCrops
        .where((crop) => SupportedCrops.isSupported(crop['name']?.toString()))
        .toList(growable: false);
    if (supportedCrops.isEmpty) return const [];

    final fieldAreaSqm = _fieldAreaSqm(field);
    return supportedCrops.map((crop) {
      final cropId = crop['id']?.toString() ?? '';
      final cropName = SupportedCrops.canonicalName(crop['name']?.toString()) ??
          crop['name']?.toString() ??
          'Bitki';
      final setup = _setupMetadata(activities, cropId);
      final areaSqm =
          _cropAreaSqm(crop, setup, fieldAreaSqm, supportedCrops.length);
      final areaDekar = areaSqm / 1000.0;
      final rowM = (((crop['row_spacing_cm'] as num?)?.toDouble() ??
                  _doubleValue(setup, ['row_spacing_cm']) ??
                  70) /
              100)
          .clamp(0.1, 20.0)
          .toDouble();
      final plantM = (((crop['plant_spacing_cm'] as num?)?.toDouble() ??
                  _doubleValue(setup, ['plant_spacing_cm']) ??
                  30) /
              100)
          .clamp(0.05, 20.0)
          .toDouble();
      final plantCount = math.max(1, (areaSqm / (rowM * plantM)).round());
      final guide = TurkiyeCropGuides.lookup(cropName);
      final targetMm = _weeklyTargetMm(guide, cropName);
      final defaultIrrigationMethod =
          _stringValue(setup, ['irrigation_method']) ?? 'Damla sulama';

      DateTime? plantedAt = _parsePlantedDate(crop['planted_date']?.toString());
      plantedAt ??= _firstActivityDate(activities, cropId, ActivityType.planting);

      double weeklyWaterMm = 0;
      double weeklyWaterL = 0;
      double seasonalWaterMm = 0;
      double seasonalWaterL = 0;
      DateTime? lastWater;

      DateTime? lastFert;
      String? lastFertName;
      double? lastFertKg;

      DateTime? lastSpray;
      String? lastPesticide;
      String? lastTarget;

      double harvestedKg = 0;

      for (final activity in activities) {
        if (!_belongsToCrop(activity, cropId)) continue;
        final type = activity['type']?.toString();
        final date = activity['date'];
        if (date is! DateTime) continue;
        final metadata = _metadata(activity);

        if (type == ActivityType.watering) {
          final impact = _waterImpactMm(
            metadata: metadata,
            quantity: (metadata['quantity'] as num?)?.toDouble(),
            quantityUnit: metadata['quantity_unit']?.toString(),
            areaSqm: areaSqm,
            plantCount: plantCount,
            defaultMethod: defaultIrrigationMethod,
          );
          seasonalWaterMm += impact.mm;
          seasonalWaterL += impact.liters;
          if (!date.isBefore(t.subtract(const Duration(days: 7)))) {
            weeklyWaterMm += impact.mm;
            weeklyWaterL += impact.liters;
          }
          if (lastWater == null || date.isAfter(lastWater)) lastWater = date;
        } else if (type == ActivityType.fertilizing) {
          if (lastFert == null || date.isAfter(lastFert)) {
            lastFert = date;
            lastFertName = _stringValue(metadata, ['fertilizer_name', 'material_name', 'note']);
            lastFertKg = _doubleValue(metadata, ['fertilizer_kg', 'quantity']);
          }
        } else if (type == ActivityType.spraying) {
          if (lastSpray == null || date.isAfter(lastSpray)) {
            lastSpray = date;
            lastPesticide = _stringValue(metadata, ['pesticide_name', 'material_name', 'note']);
            lastTarget = _stringValue(metadata, ['target_pest', 'target']);
          }
        } else if (type == ActivityType.harvest) {
          harvestedKg += _doubleValue(metadata, ['harvest_kg', 'quantity']) ?? 0;
        }
      }

      return CropFieldState(
        cropId: cropId,
        cropName: cropName,
        areaDekar: areaDekar,
        areaSqm: areaSqm,
        estimatedPlantCount: plantCount,
        weeklyWaterMm: weeklyWaterMm,
        weeklyWaterLiters: weeklyWaterL,
        seasonalWaterMm: seasonalWaterMm,
        seasonalWaterLiters: seasonalWaterL,
        weeklyWaterTargetMm: targetMm,
        lastWateredAt: lastWater,
        lastFertilizedAt: lastFert,
        lastFertilizerName: lastFertName,
        lastFertilizerKg: lastFertKg,
        lastSprayedAt: lastSpray,
        lastPesticideName: lastPesticide,
        lastPesticideTarget: lastTarget,
        harvestedKg: harvestedKg,
        yieldKgPerDekar: areaDekar <= 0 ? 0 : harvestedKg / areaDekar,
      );
    }).toList(growable: false);
  }

  static double _weeklyTargetMm(TurkiyeCropGuide? guide, String cropName) {
    if (guide != null) return guide.seasonalWaterMm / 18.0;
    final key = SupportedCrops.normalize(cropName);
    if (key == 'domates') return 34;
    if (key == 'misir') return 39;
    if (key == 'aycicegi') return 30;
    return 25;
  }

  static bool _belongsToCrop(Map<String, dynamic> activity, String cropId) {
    final activityCropId = activity['crop_id']?.toString();
    return activityCropId == null || activityCropId.isEmpty || activityCropId == cropId;
  }

  static Map<String, dynamic> _metadata(Map<String, dynamic> activity) {
    final raw = activity['metadata'];
    if (raw is Map) return Map<String, dynamic>.from(raw);
    if (raw is String && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map) return Map<String, dynamic>.from(decoded);
      } catch (_) {}
    }
    return <String, dynamic>{};
  }

  static double _fieldAreaSqm(Map<String, dynamic> field) {
    final sqm = (field['area_sqm'] as num?)?.toDouble();
    if (sqm != null && sqm > 0) return sqm;
    final dekar = (field['area_dekar'] as num?)?.toDouble();
    if (dekar != null && dekar > 0) return dekar * 1000.0;
    final polygon = field['polygon'];
    if (polygon is List) {
      final area = _polygonAreaSqm(polygon);
      if (area > 0) return area;
    }
    return 1000.0;
  }

  static double _cropAreaSqm(
    Map<String, dynamic> crop,
    Map<String, dynamic> setup,
    double fieldAreaSqm,
    int cropCount,
  ) {
    final setupAreaDekar =
        _doubleValue(setup, ['area_dekar', 'setup_area_dekar']);
    if (setupAreaDekar != null && setupAreaDekar > 0) {
      return setupAreaDekar * 1000.0;
    }

    final zoneRaw = crop['zone_polygon_json']?.toString();
    if (zoneRaw != null && zoneRaw.isNotEmpty) {
      try {
        final decoded = jsonDecode(zoneRaw);
        if (decoded is List) {
          final area = _polygonAreaSqm(decoded);
          if (area > 0) return area;
        }
      } catch (_) {}
    }
    return fieldAreaSqm / math.max(1, cropCount);
  }

  static double _polygonAreaSqm(List<dynamic> raw) {
    final points = <({double lat, double lng})>[];
    for (final item in raw) {
      if (item is Map) {
        final lat = (item['lat'] ?? item['latitude']) as num?;
        final lng = (item['lng'] ?? item['longitude']) as num?;
        if (lat != null && lng != null) {
          points.add((lat: lat.toDouble(), lng: lng.toDouble()));
        }
      }
    }
    if (points.length < 3) return 0;

    final avgLat =
        points.map((p) => p.lat).reduce((a, b) => a + b) / points.length;
    const metersPerDegLat = 111320.0;
    final metersPerDegLng =
        111320.0 * math.cos(avgLat * math.pi / 180.0);
    double sum = 0;
    for (var i = 0; i < points.length; i++) {
      final a = points[i];
      final b = points[(i + 1) % points.length];
      final ax = a.lng * metersPerDegLng;
      final ay = a.lat * metersPerDegLat;
      final bx = b.lng * metersPerDegLng;
      final by = b.lat * metersPerDegLat;
      sum += ax * by - bx * ay;
    }
    return sum.abs() / 2.0;
  }

  static _WaterImpact _waterImpactMm({
    required Map<String, dynamic> metadata,
    required double? quantity,
    required String? quantityUnit,
    required double areaSqm,
    required int plantCount,
    required String defaultMethod,
  }) {
    final explicitMm = _doubleValue(metadata, ['effective_water_mm', 'water_mm']);
    if (explicitMm != null) {
      return _WaterImpact(explicitMm, explicitMm * areaSqm);
    }

    final liters = _doubleValue(metadata, ['water_liters', 'water_l', 'liters']) ??
        (quantityUnit == 'L' ? quantity : null);
    if (liters != null && liters > 0) {
      return _WaterImpact(liters / areaSqm, liters);
    }

    final minutes = _doubleValue(metadata, ['duration_minutes']) ??
        (quantityUnit == 'dk' ? quantity : null);
    final method = (metadata['irrigation_method'] ?? defaultMethod).toString();
    final mm = _durationToMm(method, minutes ?? 0, plantCount, areaSqm);
    return _WaterImpact(mm, mm * areaSqm);
  }

  static Map<String, dynamic> _setupMetadata(
    List<Map<String, dynamic>> activities,
    String cropId,
  ) {
    DateTime? latest;
    Map<String, dynamic> selected = const <String, dynamic>{};
    for (final activity in activities) {
      if (!_belongsToCrop(activity, cropId)) continue;
      if (activity['type']?.toString() != ActivityType.planting) continue;
      final metadata = _metadata(activity);
      final hasSetup = metadata['setup_version'] != null ||
          metadata['row_spacing_cm'] != null ||
          metadata['area_dekar'] != null;
      if (!hasSetup) continue;
      final date = activity['date'];
      if (date is DateTime) {
        if (latest == null || date.isAfter(latest)) {
          latest = date;
          selected = metadata;
        }
      } else if (latest == null) {
        selected = metadata;
      }
    }
    return selected;
  }

  static double _durationToMm(
    String method,
    double minutes,
    int plantCount,
    double areaSqm,
  ) {
    if (minutes <= 0) return 0;
    final hours = minutes / 60.0;
    final key = SupportedCrops.normalize(method);
    if (key.contains('damla') || key.contains('drip')) {
      const dripperLiterPerHour = 1.6;
      return (plantCount * dripperLiterPerHour * hours) / areaSqm;
    }
    if (key.contains('yagmurlama') || key.contains('sprinkler')) {
      return 7.0 * hours;
    }
    if (key.contains('karik') || key.contains('furrow')) {
      return 10.0 * hours;
    }
    return 5.0 * hours;
  }

  static DateTime? _parsePlantedDate(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    final parts = raw.split('.');
    if (parts.length == 3) {
      final iso =
          '${parts[2]}-${parts[1].padLeft(2, '0')}-${parts[0].padLeft(2, '0')}';
      final dt = DateTime.tryParse(iso);
      if (dt != null) return dt;
    }
    return DateTime.tryParse(raw);
  }

  static DateTime? _firstActivityDate(
    List<Map<String, dynamic>> activities,
    String cropId,
    String type,
  ) {
    DateTime? first;
    for (final activity in activities) {
      if (!_belongsToCrop(activity, cropId)) continue;
      if (activity['type']?.toString() != type) continue;
      final date = activity['date'];
      if (date is DateTime && (first == null || date.isBefore(first))) {
        first = date;
      }
    }
    return first;
  }

  static String? _stringValue(Map<String, dynamic> metadata, List<String> keys) {
    for (final key in keys) {
      final value = metadata[key]?.toString().trim();
      if (value != null && value.isNotEmpty) return value;
    }
    return null;
  }

  static double? _doubleValue(Map<String, dynamic> metadata, List<String> keys) {
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
}

class _WaterImpact {
  final double mm;
  final double liters;

  const _WaterImpact(this.mm, this.liters);
}
