import 'package:flutter/foundation.dart';

import '../task_directive_service.dart' show GrowthSnapshot;
import '../weather_soil_service.dart' show HourlyForecast;
import 'recommendation.dart';

/// Bir [CropRuleSet] çalıştırılırken gereken tüm bağlam — saf POD; Drift'e
/// bağımlı değil, testlerde elle inşa edilebilir. Provider katmanı Drift
/// satırlarını bu snapshot'lara dönüştürerek `evaluate` çağırır.
@immutable
class RuleEvaluationContext {
  final String fieldId;
  final FieldCropSnapshot crop;

  /// `GrowthEngine`'den gelen büyüme/stres özeti. null → henüz hesap yok
  /// (örn. yeni ekilmiş tarla); bu durumda kurallar daysSincePlanted gibi
  /// basit fallback'lere düşer.
  final GrowthSnapshot? growth;

  /// Son N gün aktivite kayıtları — yeni → eski sırada beklenir.
  final List<ActivityRecord> recentActivities;
  final List<PlantInstanceSnapshot> plantInstances;

  /// Saatlik hava tahmini. null → çevrimdışı; yağmur/sıcak kontrolleri
  /// "veri yok → kuralı tetikleme" olarak defansif davranır.
  final HourlyForecast? hourly;

  /// Son bilinen çevre/toprak snapshot'ı. Canlı servis, cache veya son
  /// uygunluk raporu kaynaklı olabilir; null alanlar bilinmeyen veridir.
  final RuleEnvironmentSnapshot? environment;

  /// Ürünün bu tarladaki alanı, tahmini bitki sayısı ve su dengesi.
  final RuleFieldStateSnapshot? fieldState;

  final DateTime now;

  const RuleEvaluationContext({
    required this.fieldId,
    required this.crop,
    this.growth,
    this.recentActivities = const [],
    this.plantInstances = const [],
    this.hourly,
    this.environment,
    this.fieldState,
    required this.now,
  });

  /// Verilen tip/alt-tipte son [window] içinde aktivite var mı?
  /// `subtype` null geçilirse alt-tip kontrolü yapılmaz.
  bool hasActivityWithin({
    required String type,
    String? subtype,
    required Duration window,
  }) {
    final cutoff = now.subtract(window);
    for (final a in recentActivities) {
      if (a.at.isBefore(cutoff)) continue;
      if (a.type != type) continue;
      if (subtype != null && a.subtype != subtype) continue;
      return true;
    }
    return false;
  }

  /// Belirli bir tipteki en son aktivitenin zamanı; yoksa null.
  DateTime? lastActivityAt({required String type, String? subtype}) {
    for (final a in recentActivities) {
      if (a.type != type) continue;
      if (subtype != null && a.subtype != subtype) continue;
      return a.at;
    }
    return null;
  }
}

@immutable
class RuleEnvironmentSnapshot {
  final double? temperatureC;
  final double? humidityPct;
  final double? windSpeedMs;
  final double? weeklyRainMm;
  final double? soilMoisture; // 0..1
  final double? soilTempC;
  final double? soilPh;
  final double? nitrogenKgDekar;
  final double? phosphorusKgDekar;
  final double? potassiumKgDekar;
  final DateTime? fetchedAt;
  final String source;

  const RuleEnvironmentSnapshot({
    this.temperatureC,
    this.humidityPct,
    this.windSpeedMs,
    this.weeklyRainMm,
    this.soilMoisture,
    this.soilTempC,
    this.soilPh,
    this.nitrogenKgDekar,
    this.phosphorusKgDekar,
    this.potassiumKgDekar,
    this.fetchedAt,
    this.source = 'bilinmiyor',
  });

  bool get hasWeather =>
      temperatureC != null || humidityPct != null || weeklyRainMm != null;

  bool get hasSoil =>
      soilMoisture != null || soilTempC != null || soilPh != null;

  bool get hasNpk =>
      nitrogenKgDekar != null ||
      phosphorusKgDekar != null ||
      potassiumKgDekar != null;

  bool get isDrySoil => soilMoisture != null && soilMoisture! < 0.22;
  bool get isWetSoil => soilMoisture != null && soilMoisture! > 0.42;
  bool get isColdSoil => soilTempC != null && soilTempC! < 10;
  bool get isHotDryAir =>
      (temperatureC != null && temperatureC! >= 32) ||
      (humidityPct != null && humidityPct! <= 30);
}

@immutable
class RuleFieldStateSnapshot {
  final double areaDekar;
  final double areaSqm;
  final int estimatedPlantCount;
  final double weeklyWaterMm;
  final double weeklyWaterLiters;
  final double weeklyWaterTargetMm;
  final double seasonalWaterMm;
  final double seasonalWaterLiters;
  final DateTime? lastWateredAt;
  final DateTime? lastFertilizedAt;
  final DateTime? lastSprayedAt;

  const RuleFieldStateSnapshot({
    required this.areaDekar,
    required this.areaSqm,
    required this.estimatedPlantCount,
    required this.weeklyWaterMm,
    required this.weeklyWaterLiters,
    required this.weeklyWaterTargetMm,
    required this.seasonalWaterMm,
    required this.seasonalWaterLiters,
    this.lastWateredAt,
    this.lastFertilizedAt,
    this.lastSprayedAt,
  });

  double get weeklyWaterRatio =>
      weeklyWaterTargetMm <= 0 ? 0 : weeklyWaterMm / weeklyWaterTargetMm;

  double get weeklyWaterMissingMm =>
      weeklyWaterTargetMm <= 0 ? 0 : (weeklyWaterTargetMm - weeklyWaterMm);

  bool get waterBehind => weeklyWaterTargetMm > 0 && weeklyWaterRatio < 0.70;
}

@immutable
class FieldCropSnapshot {
  final String id;
  final String name;
  final DateTime? plantedDate;

  const FieldCropSnapshot({
    required this.id,
    required this.name,
    this.plantedDate,
  });

  /// Ekimden bugüne geçen gün — null güvenli.
  int? daysSincePlanted(DateTime now) {
    if (plantedDate == null) return null;
    return now.toUtc().difference(plantedDate!.toUtc()).inDays;
  }
}

@immutable
class ActivityRecord {
  final String type;
  final String? subtype;
  final DateTime at;
  final String? plantInstanceId;
  final double? quantity;

  const ActivityRecord({
    required this.type,
    this.subtype,
    required this.at,
    this.plantInstanceId,
    this.quantity,
  });
}

@immutable
class PlantInstanceSnapshot {
  final String id;
  final String? cropId;

  /// 'healthy' | 'diseased' | 'dead' — mevcut 3-değerli durum.
  final String healthStatus;

  /// PlantCondition.* sabit listesi (v8 conditionFlagsJson içeriği).
  final List<String> conditionFlags;

  const PlantInstanceSnapshot({
    required this.id,
    this.cropId,
    required this.healthStatus,
    this.conditionFlags = const [],
  });

  bool hasCondition(String flag) => conditionFlags.contains(flag);
}

/// Bir ürün için deterministik tavsiye üreteci. Saf — IO yok, sadece
/// pure-function [evaluate]. İleride mısır/buğday için ek implementasyonlar
/// eklenebilir; çağıran katman ürün adına göre uygun rule set'i seçer.
abstract class CropRuleSet {
  const CropRuleSet();

  /// Hangi ürün adlarına yanıt veriyor? Tüm değerler küçük harfli ve
  /// Türkçe karakter normalize edilmiş olmalı (`aycicegi`, `sunflower`...).
  Set<String> get supportedCropNames;

  /// Ürün adı normalize edilip [supportedCropNames] içinde mi?
  bool matches(String cropName) {
    final n = _normalize(cropName);
    return supportedCropNames.any((s) => n.contains(s));
  }

  List<Recommendation> evaluate(RuleEvaluationContext context);

  /// Türkçe + uppercase + diakritikleri sade ASCII'ye düşür — eşleştirme
  /// için. Asset path normalizasyonuyla aynı kuralları izler.
  static String _normalize(String s) {
    return s
        .toLowerCase()
        .replaceAll('ç', 'c')
        .replaceAll('ğ', 'g')
        .replaceAll('ı', 'i')
        .replaceAll('İ', 'i')
        .replaceAll('ö', 'o')
        .replaceAll('ş', 's')
        .replaceAll('ü', 'u');
  }
}
