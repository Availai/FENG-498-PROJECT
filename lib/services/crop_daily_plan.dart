import 'dart:convert';

import '../data/activity_types.dart';
import '../data/crop_playbooks.dart';
import '../data/supported_crops.dart';
import 'rules/timing_window.dart';
import 'water_accounting.dart';

/// Bir sulama aktivitesinin tarlaya kattığı toplam mm'yi hesaplar.
///
/// Öncelik sırası:
///  1. `effective_water_mm` / `water_mm`
///  2. `water_liters` veya L birimi
///  3. süre + sulama yöntemi
///
/// Bu sayede çiftçi gerçek litre ölçümü girdiğinde su muhasebesi kesin olur;
/// yalnızca süre girilmişse yöntem/bitki sayısı varsayımıyla yaklaşık değere düşer.
double _wateringMm(Map<String, dynamic> a, double areaDekar, int plantCount) {
  final meta = a['metadata'];
  final metadata = meta is Map ? Map<String, dynamic>.from(meta) : null;
  return WaterAccounting.calculate(
    metadata: metadata,
    quantity: (a['quantity'] as num?)?.toDouble(),
    quantityUnit: a['unit']?.toString(),
    areaSqm: (areaDekar <= 0 ? 1.0 : areaDekar) * 1000.0,
    plantCount: plantCount,
  ).mm;
}

/// Pencere uzunluğu — bugünden geriye 3 gün, ileriye 10 gün (toplam 14 gün).
const int _windowDaysBefore = 3;
const int _windowDaysAfter = 10;

class CropDailyPlanResult {
  final String cropKey;
  final String cropName;
  final String cropId;
  final String fieldId;
  final DateTime plantedDate;
  final DateTime harvestDate;
  final int harvestDays;
  final double areaDekar;

  final double seasonTargetMm;
  final double appliedIrrigationMm;
  final double accountedRainMm;

  final String? currentStageKey;
  final double stageProgress;
  final double accumulatedGdd;
  final double totalGdd;
  final double waterDeficitMm;
  final int yieldLossPct;

  final List<DayPlan> days;
  final int todayIndex;

  const CropDailyPlanResult({
    required this.cropKey,
    required this.cropName,
    required this.cropId,
    required this.fieldId,
    required this.plantedDate,
    required this.harvestDate,
    required this.harvestDays,
    required this.areaDekar,
    required this.seasonTargetMm,
    required this.appliedIrrigationMm,
    required this.accountedRainMm,
    required this.currentStageKey,
    required this.stageProgress,
    required this.accumulatedGdd,
    required this.totalGdd,
    required this.waterDeficitMm,
    required this.yieldLossPct,
    required this.days,
    required this.todayIndex,
  });

  /// Sezonun kalan toplam sulama ihtiyacı (mm). Asla negatife düşmez —
  /// fazlaysa 0 gösterir. Yağmur arttıkça canlı azalır.
  double get remainingSeasonMm {
    final r = seasonTargetMm - appliedIrrigationMm - accountedRainMm;
    return r < 0 ? 0 : r;
  }

  /// 0..1 — gauge için tamamlanmış oran.
  double get coverageFraction {
    if (seasonTargetMm <= 0) return 0;
    final f = (appliedIrrigationMm + accountedRainMm) / seasonTargetMm;
    if (f < 0) return 0;
    if (f > 1) return 1;
    return f;
  }

  DayPlan? get today =>
      todayIndex >= 0 && todayIndex < days.length ? days[todayIndex] : null;
}

class DayPlan {
  final DateTime date;
  final int dayIndex;
  final String stageLabel;
  final double waterTargetMm;
  final double waterIrrigatedMm;
  final double waterRainMm;
  final List<DayTask> tasks;
  final bool isToday;
  final bool isPast;
  final bool isFuture;

  const DayPlan({
    required this.date,
    required this.dayIndex,
    required this.stageLabel,
    required this.waterTargetMm,
    required this.waterIrrigatedMm,
    required this.waterRainMm,
    required this.tasks,
    required this.isToday,
    required this.isPast,
    required this.isFuture,
  });

  double get waterCoverageMm => waterIrrigatedMm + waterRainMm;

  double get waterRemainingMm {
    final r = waterTargetMm - waterCoverageMm;
    return r < 0 ? 0 : r;
  }

  /// 0..1 — günlük kapsama. Görsel su barı için.
  double get waterCoverageFraction {
    if (waterTargetMm <= 0) return waterIrrigatedMm > 0 ? 1.0 : 0.0;
    final f = waterCoverageMm / waterTargetMm;
    if (f < 0) return 0;
    if (f > 1) return 1;
    return f;
  }

  bool get hasOpenTask => tasks.any((t) => !t.done);
}

class DayTask {
  /// `ActivityType` sabiti.
  final String type;

  /// Çiftçi dostu ana etiket (ör. "Suladım", "Üre %46 N").
  final String label;

  /// Tek satır detay (ör. "20 dk damla — 16 mm hedef").
  final String? detail;
  final double? recommendedQuantity;
  final String? unit;
  final String? timingLabel;
  final bool done;
  final DateTime? doneAt;

  /// 'auto_seed' (takvim) / 'computed' (anlık öneri) / 'log' (sadece kayıt).
  final String origin;

  const DayTask({
    required this.type,
    required this.label,
    required this.origin,
    this.detail,
    this.recommendedQuantity,
    this.unit,
    this.timingLabel,
    this.done = false,
    this.doneAt,
  });
}

class CropDailyPlanService {
  const CropDailyPlanService();

  /// Saf hesap. Tüm girdileri map liste alır; UI/Drift bağımlılığı yok.
  /// Desteklenmeyen bitki / eksik ekim tarihi → null.
  CropDailyPlanResult? build({
    required Map<String, dynamic> crop,
    required String fieldId,
    double? areaDekar,
    required List<Map<String, dynamic>> activities,
    required List<Map<String, dynamic>> scheduledEvents,
    required List<dynamic> dailyForecast,
    Map<String, dynamic>? growthState,
    DateTime? now,
  }) {
    final cropName = crop['name']?.toString() ?? '';
    final canonical = SupportedCrops.canonicalName(cropName);
    if (canonical == null) return null;
    final cropKey = SupportedCrops.normalize(canonical);
    final playbook = CropPlaybooks.resolveByName(cropName);
    if (playbook == null) return null;
    final plantedDate = _parsePlanted(crop['planted_date']?.toString());
    if (plantedDate == null) return null;
    final cropId = crop['id']?.toString() ?? '';
    final harvestDays = (crop['harvest_days'] as num?)?.toInt() ?? 100;
    final effectiveAreaDekar = areaDekar ?? 1.0;
    final areaSqm =
        effectiveAreaDekar <= 0 ? 1000.0 : effectiveAreaDekar * 1000.0;
    final plantCount = WaterAccounting.estimatePlantCount(
      areaSqm: areaSqm,
      rowSpacingCm: (crop['row_spacing_cm'] as num?)?.toDouble(),
      plantSpacingCm: (crop['plant_spacing_cm'] as num?)?.toDouble(),
    );
    final t = now ?? DateTime.now();
    final today = DateTime(t.year, t.month, t.day);
    final harvestDate = plantedDate.add(Duration(days: harvestDays));

    final forecastByDate = <DateTime, double>{};
    for (final f in dailyForecast) {
      if (f is! Map) continue;
      final ds = f['date']?.toString();
      if (ds == null) continue;
      final dt = DateTime.tryParse(ds);
      if (dt == null) continue;
      final key = DateTime(dt.year, dt.month, dt.day);
      forecastByDate[key] = (f['rain'] as num?)?.toDouble() ?? 0.0;
    }

    final activitiesByDay = <DateTime, List<Map<String, dynamic>>>{};
    double appliedTotalMm = 0;
    for (final a in activities) {
      if (!_isRealActivity(a, t)) continue;
      final aCrop = a['crop_id']?.toString();
      // crop_id boş → tarla geneli; bu ekine de say.
      if (aCrop != null && aCrop.isNotEmpty && aCrop != cropId) continue;
      final date = a['date'];
      if (date is! DateTime) continue;
      if (date.isBefore(plantedDate.subtract(const Duration(days: 1)))) {
        continue;
      }
      final key = DateTime(date.year, date.month, date.day);
      activitiesByDay.putIfAbsent(key, () => []).add(a);
      if (a['type']?.toString() == ActivityType.watering) {
        appliedTotalMm += _wateringMm(a, effectiveAreaDekar, plantCount);
      }
    }

    final plansByDay = <DateTime, List<Map<String, dynamic>>>{};
    for (final ev in scheduledEvents) {
      if (ev['crop_id']?.toString() != cropId) continue;
      final raw = ev['date'];
      DateTime? d;
      if (raw is DateTime) d = raw;
      if (raw is String) d = DateTime.tryParse(raw);
      if (d == null) continue;
      final key = DateTime(d.year, d.month, d.day);
      plansByDay.putIfAbsent(key, () => []).add(ev);
    }

    double seasonTargetMm = 0;
    for (final b in playbook.waterGuide) {
      final to = b.dayTo > harvestDays ? harvestDays : b.dayTo;
      final span = to - b.dayFrom + 1;
      if (span <= 0) continue;
      seasonTargetMm += (b.weeklyMm / 7.0) * span;
    }

    double rainAccountedMm = 0;
    forecastByDate.forEach((d, mm) {
      if (d.isBefore(plantedDate)) return;
      if (d.isAfter(harvestDate)) return;
      rainAccountedMm += mm;
    });

    final days = <DayPlan>[];
    int todayIdx = -1;
    for (int i = -_windowDaysBefore; i <= _windowDaysAfter; i++) {
      final date = today.add(Duration(days: i));
      final dayIdx = date.difference(plantedDate).inDays;
      if (dayIdx < 0 || dayIdx > harvestDays) continue;
      final band = playbook.bandForDay(dayIdx);
      final dayActs = activitiesByDay[date] ?? const [];
      final dayPlans = plansByDay[date] ?? const [];

      double waterMm = 0;
      for (final a in dayActs) {
        if (a['type']?.toString() == ActivityType.watering) {
          waterMm += _wateringMm(a, effectiveAreaDekar, plantCount);
        }
      }
      final rain = forecastByDate[date] ?? 0.0;
      final waterTarget = band == null ? 0.0 : band.weeklyMm / 7.0;

      final tasks = _tasksForDay(
        date: date,
        today: today,
        plans: dayPlans,
        activities: dayActs,
        playbook: playbook,
        band: band,
        waterTargetMm: waterTarget,
        waterIrrigatedMm: waterMm,
        waterRainMm: rain,
        areaSqm: areaSqm,
      );

      final isToday = date == today;
      final dp = DayPlan(
        date: date,
        dayIndex: dayIdx,
        stageLabel: band?.stage ?? '—',
        waterTargetMm: waterTarget,
        waterIrrigatedMm: waterMm,
        waterRainMm: rain,
        tasks: tasks,
        isToday: isToday,
        isPast: date.isBefore(today),
        isFuture: date.isAfter(today),
      );
      if (isToday) todayIdx = days.length;
      days.add(dp);
    }

    final stageKey =
        (growthState?['current_stage_key'] ?? growthState?['currentStageKey'])
            ?.toString();
    final stageProg = ((growthState?['stage_progress'] ??
                growthState?['stageProgress']) as num?)
            ?.toDouble() ??
        0;
    final accGdd = ((growthState?['accumulated_gdd'] ??
                growthState?['accumulatedGdd']) as num?)
            ?.toDouble() ??
        0;
    final waterDef = ((growthState?['water_deficit_mm'] ??
                growthState?['waterDeficitMm']) as num?)
            ?.toDouble() ??
        0;
    final yieldMul = ((growthState?['yield_multiplier'] ??
                growthState?['yieldMultiplier']) as num?)
            ?.toDouble() ??
        1.0;

    final totalGdd = _totalGddFor(cropKey);

    return CropDailyPlanResult(
      cropKey: cropKey,
      cropName: canonical,
      cropId: cropId,
      fieldId: fieldId,
      plantedDate: plantedDate,
      harvestDate: harvestDate,
      harvestDays: harvestDays,
      areaDekar: effectiveAreaDekar,
      seasonTargetMm: seasonTargetMm,
      appliedIrrigationMm: appliedTotalMm,
      accountedRainMm: rainAccountedMm,
      currentStageKey: stageKey,
      stageProgress: stageProg,
      accumulatedGdd: accGdd,
      totalGdd: totalGdd,
      waterDeficitMm: waterDef,
      yieldLossPct: ((1.0 - yieldMul) * 100).round().clamp(0, 50),
      days: days,
      todayIndex: todayIdx,
    );
  }

  List<DayTask> _tasksForDay({
    required DateTime date,
    required DateTime today,
    required List<Map<String, dynamic>> plans,
    required List<Map<String, dynamic>> activities,
    required CropPlaybook playbook,
    required WaterGuideBand? band,
    required double waterTargetMm,
    required double waterIrrigatedMm,
    required double waterRainMm,
    required double areaSqm,
  }) {
    final out = <DayTask>[];
    final loggedTypes = <String>{};
    for (final a in activities) {
      final t = a['type']?.toString();
      if (t != null) loggedTypes.add(t);
    }

    // 1) Takvime auto-seed yazılmış planlar (sulama + gübre + ilaç).
    for (final ev in plans) {
      final type = ev['type']?.toString() ?? ActivityType.other;
      final meta =
          (ev['metadata'] as Map?)?.cast<String, dynamic>() ?? const {};
      final qty = (ev['recommended_quantity'] as num?)?.toDouble() ??
          (ev['quantity'] as num?)?.toDouble() ??
          (meta['recommended_quantity'] as num?)?.toDouble();
      final unit = ev['unit']?.toString() ?? meta['quantity_unit']?.toString();
      final productName = (meta['product_name'] ??
              meta['fertilizer_name'] ??
              meta['pesticide_name'])
          ?.toString();
      final stage = meta['stage']?.toString();
      final tip = meta['tip']?.toString();
      final detail = [
        if (productName != null) productName,
        if (qty != null && unit != null) '${_fmtNum(qty)} $unit/da',
        if (stage != null) stage,
        if (tip != null) tip,
      ].where((s) => s.isNotEmpty).join(' • ');

      final loggedAt = _matchLogDate(activities, type);
      out.add(DayTask(
        type: type,
        label: ev['title']?.toString() ?? ActivityType.label(type),
        origin: 'auto_seed',
        detail: detail.isEmpty ? null : detail,
        recommendedQuantity: qty,
        unit: unit,
        done: loggedAt != null,
        doneAt: loggedAt,
      ));
    }

    // 2) Bugün için sulama planı yoksa ama target > yağmur → "şimdi sula".
    if (date == today &&
        band != null &&
        waterTargetMm > 0 &&
        waterRainMm < waterTargetMm * 0.5 &&
        !out.any((t) => t.type == ActivityType.watering)) {
      // Hedefi mm cinsinden → dakika
      final neededMm = (waterTargetMm - waterIrrigatedMm - waterRainMm)
          .clamp(0, double.infinity)
          .toDouble();
      if (neededMm > 0.5) {
        final liters =
            neededMm * areaSqm / WaterAccounting.methodEfficiency('Damla sulama');
        final timing = TimingWindow.forIrrigation(now: today);
        out.add(DayTask(
          type: ActivityType.watering,
          label: 'Sulama önerisi',
          origin: 'computed',
          detail:
              'Bugün ${_fmtNum(neededMm)} mm açık, damla sulama için yaklaşık ${_fmtNum(liters)} L. Uygun saat: ${timing?.descriptor ?? 'Sabah 06:00-10:00'}.',
          recommendedQuantity: liters.toDouble(),
          unit: 'L',
          timingLabel: timing?.descriptor,
          done: waterIrrigatedMm > 0,
        ));
      }
    }

    // 3) Çiftçi planı olmayan ama log atılmış aktiviteleri "yapıldı" kartı olarak göster.
    for (final a in activities) {
      final type = a['type']?.toString();
      if (type == null) continue;
      if (out.any((t) => t.type == type)) continue;
      final qty = (a['quantity'] as num?)?.toDouble();
      final unit = a['unit']?.toString();
      out.add(DayTask(
        type: type,
        label: ActivityType.label(type),
        origin: 'log',
        detail: qty != null && unit != null
            ? '${_fmtNum(qty)} $unit kayıt edildi'
            : null,
        recommendedQuantity: null,
        unit: unit,
        done: true,
        doneAt: a['date'] as DateTime?,
      ));
    }

    // Bittiyse → bitenler altta, beklenler üstte.
    out.sort((a, b) {
      if (a.done == b.done) return 0;
      return a.done ? 1 : -1;
    });

    return out;
  }

  static DateTime? _matchLogDate(
    List<Map<String, dynamic>> activities,
    String type,
  ) {
    for (final a in activities) {
      if (a['type']?.toString() == type) {
        final d = a['date'];
        if (d is DateTime) return d;
      }
    }
    return null;
  }

  static String _fmtNum(double v) {
    if (v == v.roundToDouble()) return v.toInt().toString();
    return v.toStringAsFixed(1);
  }

  static bool _isRealActivity(Map<String, dynamic> activity, DateTime now) {
    if (activity['source']?.toString() == 'auto_seed') return false;
    final date = activity['date'];
    if (date is DateTime && date.isAfter(now)) return false;
    return true;
  }

  static DateTime? _parsePlanted(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    final parts = raw.split('.');
    if (parts.length == 3) {
      final iso =
          '${parts[2]}-${parts[1].padLeft(2, '0')}-${parts[0].padLeft(2, '0')}';
      final dt = DateTime.tryParse(iso);
      if (dt != null) return DateTime(dt.year, dt.month, dt.day);
    }
    final dt = DateTime.tryParse(raw);
    if (dt == null) return null;
    return DateTime(dt.year, dt.month, dt.day);
  }

  /// `GrowthEngine._stages` ile aynı toplam GDD eşikleri.
  static double _totalGddFor(String cropKey) {
    switch (cropKey) {
      case 'aycicegi':
        return 1700;
      case 'misir':
        return 1550;
      case 'domates':
        return 1300;
      default:
        return 1500;
    }
  }
}

/// Test ve debug için saf JSON dump.
String debugDumpDailyPlan(CropDailyPlanResult r) => jsonEncode({
      'crop': r.cropName,
      'planted': r.plantedDate.toIso8601String(),
      'season_target_mm': r.seasonTargetMm,
      'applied_mm': r.appliedIrrigationMm,
      'rain_mm': r.accountedRainMm,
      'days': r.days
          .map((d) => {
                'date': d.date.toIso8601String(),
                'idx': d.dayIndex,
                'stage': d.stageLabel,
                'target_mm': d.waterTargetMm,
                'rain_mm': d.waterRainMm,
                'irr_mm': d.waterIrrigatedMm,
                'tasks': d.tasks.length,
              })
          .toList(),
    });
