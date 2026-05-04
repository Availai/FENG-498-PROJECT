import 'package:flutter/foundation.dart';

import '../../data/activity_types.dart';
import '../guide_engine.dart' show AlertSeverity;

/// Bir tavsiyenin hedeflediği kapsam — tarla / bölge / tekil bitki.
@immutable
class RecommendationTarget {
  final String fieldId;
  final String? cropId;
  final String? plantInstanceId;
  final ActivityScope scope;

  const RecommendationTarget({
    required this.fieldId,
    this.cropId,
    this.plantInstanceId,
    required this.scope,
  });

  /// Hızlı bir "tek tarla geneli" hedef üretici.
  factory RecommendationTarget.field(String fieldId) =>
      RecommendationTarget(fieldId: fieldId, scope: ActivityScope.field);

  factory RecommendationTarget.crop({
    required String fieldId,
    required String cropId,
  }) =>
      RecommendationTarget(
        fieldId: fieldId,
        cropId: cropId,
        scope: ActivityScope.zone,
      );

  factory RecommendationTarget.plant({
    required String fieldId,
    required String plantInstanceId,
    String? cropId,
  }) =>
      RecommendationTarget(
        fieldId: fieldId,
        cropId: cropId,
        plantInstanceId: plantInstanceId,
        scope: ActivityScope.plant,
      );
}

/// Bir aktivite kaydedildiğinde tavsiyenin "süresinin dolması" koşulu.
/// Örn: water_stress.flower kuralı için
/// `ClearOnActivity(activityType: watering, withinHours: 36)` →
/// son 36 saatte sulama yapıldıysa kural artık tetiklenmez.
@immutable
class ClearOnActivity {
  final String activityType;
  final String? subtype;
  final int withinHours;

  const ClearOnActivity({
    required this.activityType,
    this.subtype,
    this.withinHours = 24,
  });
}

/// Deterministik kural setlerinin ürettiği tek bir tavsiye kaydı.
///
/// `ruleKey` dedup için stabil olmalı: sürüm bilgisini ('v1') anahtarın
/// içine yerleştir; kural mantığı değiştiğinde versiyonu artır → eski
/// ledger satırı yenisinden ayrılır, çiftçi tavsiyeyi yeniden görür.
@immutable
class Recommendation {
  final String ruleKey;
  final AlertSeverity severity;
  final RecommendationTarget target;
  final String title;

  /// Kısa neden cümlesi (UI'da çoğu zaman tek satır gösterilir).
  final String reasonText;

  /// Genişletilmiş neden — collapsible "Neden ▾" listesi için madde madde.
  final List<String> reasonBullets;

  /// Çiftçinin alacağı somut aksiyon — fiil ve miktar içermeli.
  final String actionHint;

  /// Bu aktivitelerden biri pencerede gerçekleşirse tavsiye expire olur.
  final List<ClearOnActivity> clearOnActivities;

  /// Aynı ruleKey için bu süre boyunca yeniden tetiklenme bastırılır.
  /// 0 → her hesaplamada yeniden gösterilebilir.
  final int cooldownHours;

  const Recommendation({
    required this.ruleKey,
    required this.severity,
    required this.target,
    required this.title,
    required this.reasonText,
    this.reasonBullets = const [],
    required this.actionHint,
    this.clearOnActivities = const [],
    this.cooldownHours = 24,
  });

  /// Severity için Türkçe etiket — UI'da rozet metninde kullanılır.
  static String severityLabel(AlertSeverity s) {
    switch (s) {
      case AlertSeverity.critical:
        return 'Acil';
      case AlertSeverity.warning:
        return 'Önemli';
      case AlertSeverity.info:
        return 'Bilgi';
    }
  }
}
