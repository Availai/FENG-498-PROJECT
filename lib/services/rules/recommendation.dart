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

enum RecommendationGate {
  actionable,
  observeFirst,
  blocked,
}

extension RecommendationGateLabel on RecommendationGate {
  String get label {
    switch (this) {
      case RecommendationGate.actionable:
        return 'Uygulanabilir';
      case RecommendationGate.observeFirst:
        return 'Önce gözlem';
      case RecommendationGate.blocked:
        return 'Kilitli';
    }
  }
}

@immutable
class RecommendationEvidence {
  final String label;
  final String value;

  const RecommendationEvidence({
    required this.label,
    required this.value,
  });

  Map<String, dynamic> toJson() => {
        'label': label,
        'value': value,
      };
}

@immutable
class RecommendationCommand {
  final String activityType;
  final String? subtype;
  final double? quantity;
  final String? quantityUnit;
  final double? recommendedQuantity;
  final String? note;
  final String? buttonLabel;
  final Map<String, dynamic> metadata;

  const RecommendationCommand({
    required this.activityType,
    this.subtype,
    this.quantity,
    this.quantityUnit,
    this.recommendedQuantity,
    this.note,
    this.buttonLabel,
    this.metadata = const {},
  });
}

/// Tavsiyenin uygulanması için önerilen zaman penceresi. UI üstte küçük bir
/// chip olarak gösterir; saat aralığı verilmediyse `descriptor` cümlesi
/// (örn. "rüzgâr <4 m/s sakin saatlerde") tek başına yeterlidir.
@immutable
class RecommendationTiming {
  /// Tavsiyenin uygulanmasının uygun olduğu pencerenin başlangıcı (yerel).
  final DateTime? windowStart;

  /// Pencerenin bitişi.
  final DateTime? windowEnd;

  /// Pencere için kısa Türkçe açıklama; UI rozetinin metni.
  final String descriptor;

  /// Pencere bilgisi nereden geldi: 'forecast' | 'agronomic' | 'guideline'.
  final String source;

  const RecommendationTiming({
    this.windowStart,
    this.windowEnd,
    required this.descriptor,
    this.source = 'agronomic',
  });

  bool get hasWindow => windowStart != null && windowEnd != null;
}

/// `RecommendationCommand.metadata` için stabil anahtar sabitleri.
/// Üretici/tüketici aynı string'lere bağlanır; typo'yu önler.
class RecommendationMetadataKeys {
  RecommendationMetadataKeys._();

  /// Pestisit kategorisi ipucu — örn. "piretroid grubu insektisit".
  /// Marka adı/dozu YOK; kullanıcı BKÜ etiketine yönlendirilir.
  static const productCategoryHint = 'product_category_hint';

  /// İlaçlama sonrası hasat öncesi bekleme (sadece bilgi notu).
  static const preHarvestIntervalHint = 'phi_hint';

  /// Yağmur/rüzgâr güvenlik penceresi (saat).
  static const safetyWindowHours = 'safety_window_hours';

  /// Sulama: hesaplanan litre cinsi tavsiye.
  static const effectiveWaterMm = 'effective_water_mm';
  static const effectiveWaterLiters = 'effective_water_liters';

  /// IPM eşiği için scouting öncesi kapı işareti.
  static const ipmGate = 'ipm_gate';
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

  /// Uygulama güvenlik kapısı. Özellikle ilaç tavsiyesinde gözlem/eşik/BKÜ
  /// doğrulanmadan kimyasal uygulama komutu açılmaz.
  final RecommendationGate gate;

  /// Tavsiyeyi üretirken kullanılan ölçümler ve karar girdileri.
  final List<RecommendationEvidence> evidence;

  /// Kullanıcı butona bastığında loglanacak aktivite komutu.
  final RecommendationCommand? command;

  /// Kuralın dayandığı teknik/resmi kaynaklar. UI kısa rozet gösterir; tam
  /// metin aktivite metadata'sına veya debug çıktısına taşınabilir.
  final List<String> sourceRefs;

  /// Bu aktivitelerden biri pencerede gerçekleşirse tavsiye expire olur.
  final List<ClearOnActivity> clearOnActivities;

  /// Aynı ruleKey için bu süre boyunca yeniden tetiklenme bastırılır.
  /// 0 → her hesaplamada yeniden gösterilebilir.
  final int cooldownHours;

  /// Tavsiyenin uygulanması için ideal zaman penceresi (opsiyonel).
  /// UI küçük bir rozet gösterir; null ise rozet çizilmez.
  final RecommendationTiming? timing;

  /// Bu tavsiye, listede başka tavsiyelerin tamamlanmasına bağlı ise
  /// onların `ruleKey` kümesi. Cascade gate motoru: bağımlı bir kuralın
  /// `executed/observed` durumu yoksa bu tavsiye `gate: blocked` olarak
  /// gösterilir, kullanıcı önce gözlem yapmaya yönlendirilir.
  final List<String> dependsOn;

  const Recommendation({
    required this.ruleKey,
    required this.severity,
    required this.target,
    required this.title,
    required this.reasonText,
    this.reasonBullets = const [],
    required this.actionHint,
    this.gate = RecommendationGate.actionable,
    this.evidence = const [],
    this.command,
    this.sourceRefs = const [],
    this.clearOnActivities = const [],
    this.cooldownHours = 24,
    this.timing,
    this.dependsOn = const [],
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
