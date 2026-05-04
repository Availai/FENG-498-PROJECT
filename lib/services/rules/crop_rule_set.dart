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
  final DateTime now;

  const RuleEvaluationContext({
    required this.fieldId,
    required this.crop,
    this.growth,
    this.recentActivities = const [],
    this.plantInstances = const [],
    this.hourly,
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
