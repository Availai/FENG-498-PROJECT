import 'dart:math' as math;

import '../data/activity_types.dart';
import '../data/pesticide_rei.dart';
import '../data/turkish_crops_repository.dart';
import 'field_state_service.dart' show CropFieldState;
import 'task_directive_service.dart';
import 'water_accounting.dart';
import 'weather_soil_service.dart';

/// Birleşik rehber motoru — TaskDirectiveService'in çıktısını alır,
/// dış faktör uyarıları (don/aşırı sıcak/aşırı yağmur/aşırı sulama/REI)
/// ve playbook insights ile zenginleştirir, çakışmaları dedup eder.
///
/// **Tek karar yeri kuralı**:
/// - `today` listesinde yağmur ≥8mm bekleniyorsa "BUGÜN SULA" çıkmaz.
///   Bunun yerine `alerts` listesine "Yağmur bekleniyor — sulama yarına" düşer.
/// - `thisWeek` listesinde `today`'deki görevlerin tekrarı bulunmaz.
/// - `alerts` ayrı kategori — banner olarak gösterilir, action chip değildir.
class GuideEngine {
  const GuideEngine();

  Future<GuideResult> generate({
    required List<Map<String, dynamic>> fieldCrops,
    required List<Map<String, dynamic>> activities,
    List<Map<String, dynamic>>? scheduledEvents,
    Map<String, GrowthSnapshot>? growthStates,
    HourlyForecast? hourly,
    List<dynamic>? dailyForecast,
    double? currentTemp,
    double? soilMoisture,
    Map<String, CropFieldState>? fieldStates,
    DateTime? now,
  }) async {
    final t = now ?? DateTime.now();

    // 1) Klasik direktif motorunu çağır
    const taskService = TaskDirectiveService();
    final allDirectives = taskService.generate(
      fieldCrops: fieldCrops,
      activities: activities,
      dailyForecast: dailyForecast,
      currentTemp: currentTemp,
      soilMoisture: soilMoisture,
      growthStates: growthStates,
      fieldStates: fieldStates,
      scheduledEvents: scheduledEvents,
      now: t,
    );

    // 2) Hava tahminine göre çakışan direktifleri filtrele + alert üret
    final alerts = <EnvAlert>[];
    final filteredDirectives =
        _resolveConflicts(allDirectives, hourly, dailyForecast, alerts, t);

    // 3) Saatlik forecast tabanlı alerts (don/sıcak/yağmur)
    if (hourly != null && !hourly.isEmpty) {
      _emitWeatherAlerts(hourly, alerts, t);
    }

    // 4) Aşırı sulama alert (son 7 gün uygulanan vs. ihtiyaç)
    _emitOverWateringAlert(activities, fieldCrops, alerts, t, fieldStates);

    // 5) REI alert (son ilaçlama timestamp + REI saat)
    await _emitReiAlert(activities, alerts, t);

    // 6) today vs thisWeek ayır (urgency 2 = today, 1 = thisWeek)
    final today = <UrgentTask>[];
    final thisWeek = <UpcomingTask>[];
    final seenKinds = <String>{};
    for (final d in filteredDirectives) {
      // Çakışma alert'e dönüştürüldüyse atla
      if (d.kind == 'frost' || d.kind == 'heat') continue;
      final key = '${d.kind}_${d.cropId ?? ""}';
      if (seenKinds.contains(key)) continue;
      seenKinds.add(key);
      if (d.urgency >= 2) {
        today.add(UrgentTask.fromDirective(d));
      } else if (d.urgency == 1) {
        thisWeek.add(UpcomingTask.fromDirective(d));
      }
    }

    // BUGÜN max 3 kart, BU HAFTA max 5
    final todayClipped = today.take(3).toList();
    final weekClipped = thisWeek.take(5).toList();

    // 7) Insights — bitki + evre + sıcaklık tabanlı playbook kuralları
    final insights = _buildInsights(
      fieldCrops: fieldCrops,
      growthStates: growthStates,
      hourly: hourly,
      currentTemp: currentTemp,
      activities: activities,
      now: t,
    );

    return GuideResult(
      today: todayClipped,
      thisWeek: weekClipped,
      alerts: alerts,
      insights: insights,
    );
  }

  /// Çakışma çözümü: yağmur tahmini ≥8mm + sulama direktifi → sulama düşer,
  /// alert eklenir.
  List<FieldDirective> _resolveConflicts(
    List<FieldDirective> directives,
    HourlyForecast? hourly,
    List<dynamic>? dailyForecast,
    List<EnvAlert> alerts,
    DateTime now,
  ) {
    // Önümüzdeki 24 saat yağmur tahmini
    double rainNext24h = 0;
    if (hourly != null && !hourly.isEmpty) {
      rainNext24h = hourly.rainSumNext(24);
    } else if (dailyForecast != null && dailyForecast.isNotEmpty) {
      final tomorrow = dailyForecast.first;
      if (tomorrow is Map) {
        rainNext24h = (tomorrow['rain'] as num?)?.toDouble() ?? 0;
      }
    }

    if (rainNext24h < 8.0) return directives;

    // Yağmur var → sulama direktiflerini bastır
    final result = <FieldDirective>[];
    bool addedRainAlert = false;
    for (final d in directives) {
      if (d.kind == 'water' || d.actionType == ActivityType.watering) {
        if (!addedRainAlert) {
          alerts.add(EnvAlert(
            severity: AlertSeverity.info,
            kind: AlertKind.rainExpected,
            title: 'Yağmur bekleniyor',
            message:
                'Önümüzdeki 24 saatte ${rainNext24h.toStringAsFixed(0)}mm yağmur bekleniyor — sulama yarına ertelendi.',
            icon: '💧',
          ));
          addedRainAlert = true;
        }
        continue;
      }
      result.add(d);
    }
    return result;
  }

  /// Saatlik forecast'tan don / aşırı sıcak / aşırı yağmur alert üret.
  void _emitWeatherAlerts(
      HourlyForecast hourly, List<EnvAlert> alerts, DateTime now) {
    // Don — 24 saat içinde min sıcaklık ≤ 0°C
    final min24h = hourly.minTempNext(24);
    if (min24h != null && min24h <= 0) {
      // Hangi saatte?
      DateTime? frostHour;
      for (final s in hourly.slots.take(24)) {
        if (s.tempC <= 0) {
          frostHour = s.hour;
          break;
        }
      }
      final hh = frostHour == null
          ? ''
          : ' (${frostHour.hour.toString().padLeft(2, '0')}:00 civarı)';
      alerts.add(EnvAlert(
        severity: AlertSeverity.critical,
        kind: AlertKind.frost,
        title: 'DON UYARISI',
        message:
            '${min24h.toStringAsFixed(1)}°C bekleniyor$hh. Hassas bitkileri örtün.',
        icon: '❄️',
      ));
    } else if (min24h != null && min24h <= 2) {
      alerts.add(EnvAlert(
        severity: AlertSeverity.warning,
        kind: AlertKind.frost,
        title: 'Don Riski',
        message:
            '${min24h.toStringAsFixed(1)}°C bekleniyor — radyatif soğuma marjı.',
        icon: '🌡️',
      ));
    }

    // Aşırı sıcak — 24 saat içinde max ≥ 35°C
    final max24h = hourly.maxTempNext(24);
    if (max24h != null && max24h >= 40) {
      alerts.add(EnvAlert(
        severity: AlertSeverity.critical,
        kind: AlertKind.heat,
        title: 'KRİTİK Sıcak',
        message:
            '${max24h.toStringAsFixed(0)}°C — sulamayı 06:00 öncesi yapın, gölgeleme uygulayın.',
        icon: '🔥',
      ));
    } else if (max24h != null && max24h >= 35) {
      alerts.add(EnvAlert(
        severity: AlertSeverity.warning,
        kind: AlertKind.heat,
        title: 'Yüksek Sıcaklık',
        message:
            '${max24h.toStringAsFixed(0)}°C bekleniyor. Sulamayı sabah erken/akşam üstüne alın.',
        icon: '🌡️',
      ));
    }

    // Aşırı yağmur — 24 saat içinde toplam ≥ 30mm → sahaya girilemez
    final rain24h = hourly.rainSumNext(24);
    if (rain24h >= 30) {
      alerts.add(EnvAlert(
        severity: AlertSeverity.warning,
        kind: AlertKind.fieldUnsafe,
        title: 'Toprak Islak — Ekipman Girmesin',
        message:
            '24 saatte ${rain24h.toStringAsFixed(0)}mm yağış. Ağır makineler tarlaya girmesin, drenaj kanallarını açın.',
        icon: '⛈️',
      ));
    }
  }

  /// Son 7 gün uygulanan toplam sulama mm > playbook ihtiyacı × 1.5 → uyarı.
  void _emitOverWateringAlert(
    List<Map<String, dynamic>> activities,
    List<Map<String, dynamic>> fieldCrops,
    List<EnvAlert> alerts,
    DateTime now,
    Map<String, CropFieldState>? fieldStates,
  ) {
    final cutoff = now.subtract(const Duration(days: 7));
    double appliedMm7d = 0;
    for (final a in activities) {
      if (a['source']?.toString() == 'auto_seed') continue;
      if ((a['type'] ?? a['event_type']) != ActivityType.watering) continue;
      final rawDate = a['date'] ?? a['event_date'];
      final d = rawDate is DateTime
          ? rawDate
          : DateTime.tryParse(rawDate?.toString() ?? '');
      if (d == null || d.isAfter(now) || d.isBefore(cutoff)) continue;
      final cropId = a['crop_id']?.toString();
      final state = cropId == null ? null : fieldStates?[cropId];
      final areaSqm = state?.areaSqm ??
          ((fieldCrops.isNotEmpty
                      ? (fieldCrops.first['area_dekar'] as num?)?.toDouble()
                      : null) ??
                  1.0) *
              1000.0;
      final impact = WaterAccounting.calculate(
        metadata: a['metadata'] is Map
            ? Map<String, dynamic>.from(a['metadata'] as Map)
            : const <String, dynamic>{},
        quantity: (a['quantity'] as num?)?.toDouble(),
        quantityUnit: a['unit']?.toString(),
        areaSqm: areaSqm,
        plantCount: state?.estimatedPlantCount,
      );
      appliedMm7d += impact.mm;
    }

    // Playbook ihtiyacı yaklaşık 30mm/hafta × 1.5 = 45mm
    if (appliedMm7d > 45) {
      alerts.add(EnvAlert(
        severity: AlertSeverity.warning,
        kind: AlertKind.overWatering,
        title: 'Aşırı Sulama Riski',
        message:
            '7 günde ${appliedMm7d.toStringAsFixed(0)}mm su uygulandı (önerilen ~30mm). Kök çürüklüğüne dikkat — toprak nemini kontrol edin.',
        icon: '💧',
      ));
    }
  }

  /// Son ilaçlama + REI saat > şu an → banner.
  Future<void> _emitReiAlert(
    List<Map<String, dynamic>> activities,
    List<EnvAlert> alerts,
    DateTime now,
  ) async {
    await PesticideRei.load();

    // En son ilaçlama
    Map<String, dynamic>? lastSpray;
    DateTime? lastSprayDate;
    for (final a in activities) {
      if (a['event_type'] != ActivityType.spraying) continue;
      final dStr = a['event_date']?.toString();
      if (dStr == null) continue;
      final d = DateTime.tryParse(dStr);
      if (d == null) continue;
      if (lastSprayDate == null || d.isAfter(lastSprayDate)) {
        lastSprayDate = d;
        lastSpray = a;
      }
    }

    if (lastSpray == null || lastSprayDate == null) return;

    // Pestisit adı metadata['pesticide_name'] veya note'tan
    final meta = lastSpray['metadata'];
    String pesticideName = '';
    if (meta is Map) {
      pesticideName = meta['pesticide_name']?.toString() ?? '';
    }
    if (pesticideName.isEmpty) {
      pesticideName = lastSpray['note']?.toString() ?? '';
    }

    final reiHours = PesticideRei.lookup(pesticideName);
    final reiEnd = lastSprayDate.add(Duration(hours: reiHours));
    if (reiEnd.isAfter(now)) {
      final remaining = reiEnd.difference(now).inHours;
      final label =
          pesticideName.isEmpty ? 'İlaçlama' : pesticideName.split(' ').first;
      alerts.add(EnvAlert(
        severity: AlertSeverity.warning,
        kind: AlertKind.reiActive,
        title: 'Sahaya Girmeyin',
        message:
            '$label sonrası ${remaining}saat daha bekleyin. Yeniden girilebilir saat: ${_fmtHour(reiEnd)}.',
        icon: '⚠️',
      ));
    }
  }

  String _fmtHour(DateTime d) {
    final hh = d.hour.toString().padLeft(2, '0');
    final mm = d.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  /// Bitki + evre + koşul context'ine göre playbook'tan insight üret.
  List<Insight> _buildInsights({
    required List<Map<String, dynamic>> fieldCrops,
    required Map<String, GrowthSnapshot>? growthStates,
    required HourlyForecast? hourly,
    required double? currentTemp,
    required List<Map<String, dynamic>> activities,
    required DateTime now,
  }) {
    final out = <Insight>[];
    if (fieldCrops.isEmpty) return out;

    final tempMaxNext24 =
        hourly != null && !hourly.isEmpty ? hourly.maxTempNext(24) : null;
    final tempNow = currentTemp ?? tempMaxNext24;

    for (final crop in fieldCrops) {
      final cropId = crop['id']?.toString();
      final cropName = crop['name']?.toString() ?? '';
      final lname = cropName.toLowerCase();
      GrowthSnapshot? state;
      if (cropId != null && growthStates != null) {
        state = growthStates[cropId];
      }
      final stage = state?.stageKey ?? '';

      // Domates + çiçeklenme + ≥28°C → pollen ölümü
      if (lname.contains('domates') &&
          (stage == 'ciceklenme' || stage == 'meyve_dolumu') &&
          tempNow != null &&
          tempNow >= 28) {
        out.add(Insight(
          title: 'Domates pollen riski',
          body:
              '28°C üstü pollen canlılığını düşürür; meyve tutumunda %20-40 kayıp olabilir. Mümkünse gölgeleme uygulayın.',
          icon: '💡',
          cropName: cropName,
        ));
      }

      // Mısır + tane dolumu + waterDeficit > 15mm
      if (lname.contains('mısır') &&
          stage == 'meyve_dolumu' &&
          state != null &&
          state.waterDeficitMm > 15) {
        out.add(Insight(
          title: 'Mısır tane dolum kritik',
          body:
              'Tane dolum evresinde su açığı tane ağırlığını doğrudan düşürür (mm açığı başına ~%1.5 kayıp).',
          icon: '🌽',
          cropName: cropName,
        ));
      }

      // Ayçiçeği + GDD < 1200 + çiçeklenmeye yakın
      if (lname.contains('ayçiçek') &&
          state != null &&
          state.accumulatedGdd < 1200 &&
          state.accumulatedGdd > 800) {
        out.add(Insight(
          title: 'Ayçiçeği çiçeklenmeye yakın',
          body:
              'GDD ${state.accumulatedGdd.toStringAsFixed(0)} — 1200 GDD\'de çiçeklenme başlar. Suyu kesmeyin.',
          icon: '🌻',
          cropName: cropName,
        ));
      }

      // Yüksek hastalık baskısı + son ilaçlama yok
      if (state != null && state.diseasePressure > 0.4) {
        // Son ilaçlama tarihi
        DateTime? lastSpray;
        for (final a in activities) {
          if (a['event_type'] != ActivityType.spraying) continue;
          if (a['crop_id']?.toString() != cropId) continue;
          final d = DateTime.tryParse(a['event_date']?.toString() ?? '');
          if (d != null && (lastSpray == null || d.isAfter(lastSpray))) {
            lastSpray = d;
          }
        }
        final daysSinceSpray =
            lastSpray == null ? 999 : now.difference(lastSpray).inDays;
        if (daysSinceSpray > 14) {
          out.add(Insight(
            title: '$cropName için preventif ilaç düşün',
            body:
                'Hastalık baskısı %${(state.diseasePressure * 100).round()}; son 14+ gündür ilaçlama yok.',
            icon: '🛡️',
            cropName: cropName,
          ));
        }
      }

      // Genel optimum sıcaklık aralığı (TurkishCrop varsa)
      if (tempNow != null) {
        final tcrop = TurkishCropsRepository.instance.findByName(cropName);
        final tMax = tcrop?.tempMaxC;
        final tMin = tcrop?.tempMinC;
        if (tcrop != null && tMax != null && tempNow > tMax + 5) {
          out.add(Insight(
            title: '$cropName için sıcak stres',
            body:
                'Optimum üst sınır ${tMax.toStringAsFixed(0)}°C; şu an ${tempNow.toStringAsFixed(0)}°C → büyüme yavaşlar.',
            icon: '🌡️',
            cropName: cropName,
          ));
        }
        if (tcrop != null && tMin != null && tempNow < tMin - 3) {
          out.add(Insight(
            title: '$cropName için soğuk stres',
            body:
                'Optimum alt sınır ${tMin.toStringAsFixed(0)}°C; şu an ${tempNow.toStringAsFixed(0)}°C → metabolizma yavaşlar.',
            icon: '❄️',
            cropName: cropName,
          ));
        }
      }

      // Maksimum 3 insight per crop
      if (out.where((i) => i.cropName == cropName).length >= 3) continue;
    }

    // Toplam max 5 insight (UI sade kalsın)
    return out.take(5).toList();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Veri Tipleri
// ─────────────────────────────────────────────────────────────────────────────

class GuideResult {
  final List<UrgentTask> today; // BUGÜN — max 3
  final List<UpcomingTask> thisWeek; // BU HAFTA — max 5
  final List<EnvAlert> alerts; // Don/sıcak/yağmur/aşırı sulama/REI
  final List<Insight> insights; // Playbook context-aware bilgiler

  const GuideResult({
    required this.today,
    required this.thisWeek,
    required this.alerts,
    required this.insights,
  });

  bool get isEmpty =>
      today.isEmpty && thisWeek.isEmpty && alerts.isEmpty && insights.isEmpty;
}

class UrgentTask {
  final String headline;
  final String reason;
  final String? actionType;
  final double? suggestedQuantity;
  final String? quantityUnit;
  final double? recommendedQuantity;
  final String? cropId;
  final String? cropName;
  final String kind;
  final List<String> steps;

  const UrgentTask({
    required this.headline,
    required this.reason,
    required this.kind,
    this.actionType,
    this.suggestedQuantity,
    this.quantityUnit,
    this.recommendedQuantity,
    this.cropId,
    this.cropName,
    this.steps = const [],
  });

  factory UrgentTask.fromDirective(FieldDirective d) => UrgentTask(
        headline: d.headline,
        reason: d.reason,
        kind: d.kind,
        actionType: d.actionType,
        suggestedQuantity: d.suggestedQuantity,
        quantityUnit: d.quantityUnit,
        recommendedQuantity: d.recommendedQuantity,
        cropId: d.cropId,
        cropName: d.cropName,
        steps: d.steps,
      );
}

class UpcomingTask {
  final String headline;
  final String reason;
  final String kind;
  final String? cropName;
  final DateTime? plannedDate;

  const UpcomingTask({
    required this.headline,
    required this.reason,
    required this.kind,
    this.cropName,
    this.plannedDate,
  });

  factory UpcomingTask.fromDirective(FieldDirective d) => UpcomingTask(
        headline: d.headline,
        reason: d.reason,
        kind: d.kind,
        cropName: d.cropName,
      );
}

enum AlertSeverity { info, warning, critical }

enum AlertKind {
  frost,
  heat,
  rainExpected,
  fieldUnsafe,
  overWatering,
  reiActive,
}

class EnvAlert {
  final AlertSeverity severity;
  final AlertKind kind;
  final String title;
  final String message;
  final String icon;

  const EnvAlert({
    required this.severity,
    required this.kind,
    required this.title,
    required this.message,
    required this.icon,
  });
}

class Insight {
  final String title;
  final String body;
  final String icon;
  final String? cropName;

  const Insight({
    required this.title,
    required this.body,
    required this.icon,
    this.cropName,
  });
}

// Yardımcı (math import sessiz kalmasın)
// ignore: unused_element
double _ensureMathImported() => math.pi;
