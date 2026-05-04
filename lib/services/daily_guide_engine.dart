import 'dart:math' as math;

import '../data/activity_types.dart';
import 'crop_daily_plan.dart';
import 'task_directive_service.dart';

/// Risk şeritleri — yalnız gerçekten tetiklenenler render edilir.
enum RiskKind {
  frost,
  heat,
  heavyRain,
  droughtSevere,
  droughtMild,
  saturation,
  nDeficiency,
  disease,
  yieldLoss,
  rainPause,
  climateMismatch,
  noCrop,
}

enum RiskSeverity { info, warning, critical }

/// Tek satır renkli risk kartı (don/sıcak/aşırı sulama vb.).
class RiskBanner {
  final RiskKind kind;
  final RiskSeverity severity;
  final String title;
  final String message;
  final String advice;
  final String iconKey; // UI tarafında IconData'ya map'lenir
  final String? actionType;
  final double? actionQuantity;
  final String? actionUnit;

  const RiskBanner({
    required this.kind,
    required this.severity,
    required this.title,
    required this.message,
    required this.advice,
    required this.iconKey,
    this.actionType,
    this.actionQuantity,
    this.actionUnit,
  });
}

/// Hero kartında 0..1 arası gösterilen faktör çubuğu.
class FactorBar {
  final String label; // "Su", "Besin", "İklim", "Sağlık"
  final double value; // 0..1
  final String note;
  final String iconKey;

  const FactorBar({
    required this.label,
    required this.value,
    required this.note,
    required this.iconKey,
  });
}

/// "Bugün yapılacaklar" listesindeki tek bir somut görev.
class GuideAction {
  final String headline;
  final String detail;
  final String actionType;
  final double? recommendedQuantity;
  final String? unit;
  final bool done;
  final RiskSeverity priority;
  final String iconKey;

  const GuideAction({
    required this.headline,
    required this.detail,
    required this.actionType,
    this.recommendedQuantity,
    this.unit,
    this.done = false,
    required this.priority,
    required this.iconKey,
  });
}

/// 3 günlük tahmin çubuğu için tek günlük özet.
class ForecastDay {
  final DateTime date;
  final double rainMm;
  final double? tempMin;
  final double? tempMax;
  final Set<String> tags; // "rain", "frost", "heat", "dry"

  const ForecastDay({
    required this.date,
    required this.rainMm,
    this.tempMin,
    this.tempMax,
    this.tags = const {},
  });
}

class StageInfo {
  final String stageLabel;
  final int daysSincePlanting;
  final int daysToHarvest;
  final double seasonProgress; // 0..1
  final String oneLiner;

  const StageInfo({
    required this.stageLabel,
    required this.daysSincePlanting,
    required this.daysToHarvest,
    required this.seasonProgress,
    required this.oneLiner,
  });
}

/// Son loglanan aktivitenin canlı etkisi (UI'da animasyonlu şerit).
class ActivityImpact {
  final String activityLabel;
  final DateTime when;
  final String summary; // "+12 mm su"
  final String detail; // "Açık 8 → 0 mm"
  final String iconKey;

  const ActivityImpact({
    required this.activityLabel,
    required this.when,
    required this.summary,
    required this.detail,
    required this.iconKey,
  });
}

class DailyGuideState {
  final int healthScore; // 0-100
  final String healthLabel; // "Çok iyi" / "İyi" / "Dikkat" / "Risk"
  final List<FactorBar> factors;
  final List<RiskBanner> risks;
  final List<GuideAction> actions;
  final List<ForecastDay> forecast;
  final StageInfo? stage;
  final ActivityImpact? lastImpact;
  final String oneLiner;

  const DailyGuideState({
    required this.healthScore,
    required this.healthLabel,
    required this.factors,
    required this.risks,
    required this.actions,
    required this.forecast,
    required this.stage,
    required this.lastImpact,
    required this.oneLiner,
  });
}

/// Saf hesap motoru. UI'a hiç dokunmaz; tüm faktörleri tek bir state'e indirger.
class DailyGuideEngine {
  const DailyGuideEngine();

  static const _criticalDeficitMm = 15.0;
  static const _moderateDeficitMm = 5.0;
  static const _heavyRainMm = 30.0;

  DailyGuideState compute({
    required Map<String, dynamic> crop,
    required List<Map<String, dynamic>> activities,
    required List<dynamic> dailyForecast,
    Map<String, dynamic>? growthState,
    CropDailyPlanResult? plan,
    DateTime? now,
  }) {
    final t = now ?? DateTime.now();
    final cropName = crop['name']?.toString() ?? 'Bitki';
    final cropId = crop['id']?.toString();
    final tempMin = (crop['temp_min_c'] as num?)?.toDouble();
    final tempMax = (crop['temp_max_c'] as num?)?.toDouble();
    final harvestDays = (crop['harvest_days'] as num?)?.toInt() ?? 100;
    final waterIntervalDays =
        (crop['water_interval_days'] as num?)?.toInt() ?? 7;

    // ── Büyüme durumu (canlı GDD/açık/stres) ─────────────────
    final waterDeficit = ((growthState?['water_deficit_mm'] ??
                growthState?['waterDeficitMm']) as num?)
            ?.toDouble() ??
        plan?.waterDeficitMm ??
        0.0;
    final nStress =
        ((growthState?['n_stress_idx'] ?? growthState?['nStressIdx']) as num?)
                ?.toDouble() ??
            0.0;
    final diseasePressure = ((growthState?['disease_pressure'] ??
                growthState?['diseasePressure']) as num?)
            ?.toDouble() ??
        0.0;
    final yieldMul = ((growthState?['yield_multiplier'] ??
                growthState?['yieldMultiplier']) as num?)
            ?.toDouble() ??
        1.0;
    final stageKey = (growthState?['current_stage_key'] ??
            growthState?['currentStageKey'])
        ?.toString();

    // ── Hava tahmini özeti (3 günlük) ───────────────────────
    final forecast = _parseForecast(dailyForecast, tempMin, tempMax, t);
    final today = forecast.isNotEmpty ? forecast.first : null;
    final tomorrow = forecast.length > 1 ? forecast[1] : null;
    final rainNext48h = forecast
        .take(2)
        .fold<double>(0.0, (s, d) => s + d.rainMm);
    final rainLast24h = _rainLast24h(dailyForecast, t);

    // ── Bitki seviyesi etkinlikleri ─────────────────────────
    final lastWater = _lastDate(activities, ActivityType.watering, cropId);
    final lastFert = _lastDate(activities, ActivityType.fertilizing, cropId);
    final daysSinceWater = lastWater == null
        ? null
        : t.difference(lastWater).inDays;

    // ── Aşırı sulama (saturation) tespiti ──────────────────
    // Açık negatif değil sadece — son 24 saatte sulama + sonra ağır yağmur
    // gelecekse / geldi ise bitki kökü boğulabilir.
    final justWatered = lastWater != null &&
        t.difference(lastWater).inHours < 24;
    final saturationRisk = justWatered &&
        (rainNext48h >= 20 || rainLast24h >= _heavyRainMm) &&
        waterDeficit < 2.0;

    // ── Risk şeritleri ──────────────────────────────────────
    final risks = <RiskBanner>[];

    if (tomorrow != null && tomorrow.tempMin != null) {
      final tolerance = (tempMin ?? 2.0);
      if (tomorrow.tempMin! < math.max(tolerance, 0.0) + 1.5) {
        final isCritical = tomorrow.tempMin! < tolerance;
        risks.add(RiskBanner(
          kind: RiskKind.frost,
          severity: isCritical ? RiskSeverity.critical : RiskSeverity.warning,
          title: 'DON RİSKİ — YARIN GECE',
          message:
              'Yarın gece ${tomorrow.tempMin!.toStringAsFixed(0)}°C. $cropName için alt sınır ${tolerance.toStringAsFixed(0)}°C.',
          advice: isCritical
              ? 'Hassas fideleri ört, sulamayı sabaha bırak. Don tülü kullan.'
              : 'Akşam sulama yapma — toprağı serinletmesin. Mümkünse örtü hazırla.',
          iconKey: 'frost',
        ));
      }
    }

    if (tomorrow != null && tomorrow.tempMax != null && tempMax != null) {
      if (tomorrow.tempMax! > tempMax + 2) {
        risks.add(RiskBanner(
          kind: RiskKind.heat,
          severity: RiskSeverity.warning,
          title: 'YARIN AŞIRI SICAK',
          message:
              'Yarın ${tomorrow.tempMax!.toStringAsFixed(0)}°C bekleniyor. $cropName ideali ${tempMax.toStringAsFixed(0)}°C.',
          advice:
              'Sulamayı 06:00-08:00 arasına al. Çiçeklenmedeyse meyve tutumu zayıflayabilir.',
          iconKey: 'heat',
        ));
      }
    }

    if (rainNext48h >= _heavyRainMm) {
      risks.add(RiskBanner(
        kind: RiskKind.heavyRain,
        severity: RiskSeverity.warning,
        title: 'AĞIR YAĞIŞ YOLDA',
        message:
            '48 saat içinde ${rainNext48h.toStringAsFixed(0)} mm yağış bekleniyor.',
        advice:
            'Drenajı kontrol et, taze gübre/ilaç uygulama. Sulamayı durdur — toprak doygunlaşıyor.',
        iconKey: 'storm',
      ));
    }

    if (saturationRisk) {
      risks.add(const RiskBanner(
        kind: RiskKind.saturation,
        severity: RiskSeverity.warning,
        title: 'AŞIRI SULAMA RİSKİ',
        message:
            'Son 24 saatte sulama yapıldı ve ağır yağış var. Toprak doygunluğa yakın.',
        advice:
            'Bugün sulama. Kök boğulması ve mantar riski artar. Sıralama gözle.',
        iconKey: 'saturation',
      ));
    }

    if (waterDeficit >= _criticalDeficitMm) {
      risks.add(RiskBanner(
        kind: RiskKind.droughtSevere,
        severity: RiskSeverity.critical,
        title: 'CİDDİ SU AÇIĞI',
        message:
            'Bitki ${waterDeficit.toStringAsFixed(0)} mm su açığı taşıyor. Verim düşmeye başladı.',
        advice: 'Bugün uzun sulama yap, akşamüstü kontrol et.',
        iconKey: 'drought',
        actionType: ActivityType.watering,
        actionQuantity: _suggestMinutes(waterDeficit),
        actionUnit: 'dk',
      ));
    } else if (waterDeficit >= _moderateDeficitMm && rainNext48h < 5) {
      risks.add(RiskBanner(
        kind: RiskKind.droughtMild,
        severity: RiskSeverity.warning,
        title: 'SU AÇIĞI BÜYÜYOR',
        message:
            '${waterDeficit.toStringAsFixed(0)} mm açık var, yakın yağış görünmüyor.',
        advice: 'Bugün veya yarın sabah sulama planla.',
        iconKey: 'drought',
        actionType: ActivityType.watering,
        actionQuantity: _suggestMinutes(waterDeficit),
        actionUnit: 'dk',
      ));
    }

    if (rainNext48h >= 8 &&
        daysSinceWater != null &&
        daysSinceWater >= waterIntervalDays - 1 &&
        waterDeficit < _criticalDeficitMm) {
      risks.add(RiskBanner(
        kind: RiskKind.rainPause,
        severity: RiskSeverity.info,
        title: 'SULAMAYI ERTELE',
        message:
            '48 saatte ${rainNext48h.toStringAsFixed(0)} mm yağış geliyor. Doğa sulayacak.',
        advice: 'Sulama sayacını sıfırla, su parasını koru.',
        iconKey: 'rain',
      ));
    }

    if (nStress > 0.30) {
      risks.add(RiskBanner(
        kind: RiskKind.nDeficiency,
        severity:
            nStress > 0.6 ? RiskSeverity.critical : RiskSeverity.warning,
        title: 'AZOT EKSİKLİĞİ',
        message:
            'Yapraklar sararıyor olabilir (stres %${(nStress * 100).round()}).',
        advice: lastFert == null
            ? 'Henüz gübre kaydı yok. Bugün üre veya 20-20-0 uygula.'
            : 'Son gübreleme ${t.difference(lastFert).inDays} gün önce. Tekrar gerekli.',
        iconKey: 'fertilizer',
        actionType: ActivityType.fertilizing,
      ));
    }

    if (diseasePressure > 0.40) {
      risks.add(RiskBanner(
        kind: RiskKind.disease,
        severity: diseasePressure > 0.7
            ? RiskSeverity.critical
            : RiskSeverity.warning,
        title: 'HASTALIK BASKISI',
        message:
            'Mantar/leke riski yüksek (%${(diseasePressure * 100).round()}).',
        advice: rainLast24h >= 5
            ? 'Yağmur sonrası gözlem yap, eşik aşıldıysa fungisit.'
            : 'Sıralarda gözlem yap. Erken müdahale verim kaybını önler.',
        iconKey: 'disease',
        actionType: ActivityType.scouting,
      ));
    }

    if (yieldMul < 0.85) {
      risks.add(RiskBanner(
        kind: RiskKind.yieldLoss,
        severity: yieldMul < 0.7 ? RiskSeverity.critical : RiskSeverity.warning,
        title: 'VERİM RİSKİ %${((1 - yieldMul) * 100).round()}',
        message:
            'Birikmiş stres bitki potansiyelinin %${((1 - yieldMul) * 100).round()}\'ını yiyor.',
        advice:
            'Üst risk şeritlerini kapat, açık birikmesin. Sezon henüz kurtarılabilir.',
        iconKey: 'yield',
      ));
    }

    // ── Bugün yapılacaklar ──────────────────────────────────
    final actions = _buildActions(
      crop: crop,
      activities: activities,
      plan: plan,
      risks: risks,
      now: t,
      cropId: cropId,
      cropName: cropName,
      waterDeficit: waterDeficit,
      rainNext48h: rainNext48h,
    );

    // ── Faktör çubukları (hero kart altı) ───────────────────
    final factors = _buildFactors(
      waterDeficit: waterDeficit,
      nStress: nStress,
      diseasePressure: diseasePressure,
      tempMin: tempMin,
      tempMax: tempMax,
      todayMin: today?.tempMin,
      todayMax: today?.tempMax,
    );

    // ── Sağlık skoru — ağırlıklı ortalama × verim çarpanı ──
    final healthScore =
        _healthScore(factors: factors, yieldMultiplier: yieldMul);
    final healthLabel = _healthLabel(healthScore);

    // ── Evre bilgisi ────────────────────────────────────────
    final stage =
        _stageInfo(crop: crop, stageKey: stageKey, plan: plan, now: t,
            harvestDays: harvestDays);

    // ── Son aktivite etkisi ─────────────────────────────────
    final lastImpact = _computeImpact(
      activities: activities,
      cropId: cropId,
      now: t,
      planTotal: plan?.seasonTargetMm,
      planApplied: plan?.appliedIrrigationMm,
      waterDeficit: waterDeficit,
    );

    // ── Tek cümle özet ──────────────────────────────────────
    final oneLiner = _oneLiner(
      risks: risks,
      actions: actions,
      healthScore: healthScore,
      stageLabel: stage?.stageLabel,
    );

    return DailyGuideState(
      healthScore: healthScore,
      healthLabel: healthLabel,
      factors: factors,
      risks: risks,
      actions: actions,
      forecast: forecast,
      stage: stage,
      lastImpact: lastImpact,
      oneLiner: oneLiner,
    );
  }

  // ──────────────── helper'lar ────────────────

  List<ForecastDay> _parseForecast(
    List<dynamic> raw,
    double? cropMin,
    double? cropMax,
    DateTime now,
  ) {
    final out = <ForecastDay>[];
    final today = DateTime(now.year, now.month, now.day);
    for (final f in raw) {
      if (f is! Map) continue;
      final d = DateTime.tryParse(f['date']?.toString() ?? '');
      if (d == null) continue;
      final key = DateTime(d.year, d.month, d.day);
      if (key.isBefore(today)) continue;
      final rain = (f['rain'] as num?)?.toDouble() ?? 0.0;
      final mn = (f['min_temp'] ?? f['temp_min']) as num?;
      final mx = (f['max_temp'] ?? f['temp_max']) as num?;
      final tags = <String>{};
      if (rain >= 5) tags.add('rain');
      if (rain >= _heavyRainMm) tags.add('storm');
      if (mn != null && mn.toDouble() < math.max(cropMin ?? 2.0, 0.0) + 1.5) {
        tags.add('frost');
      }
      if (mx != null && cropMax != null && mx.toDouble() > cropMax + 2) {
        tags.add('heat');
      }
      out.add(ForecastDay(
        date: key,
        rainMm: rain,
        tempMin: mn?.toDouble(),
        tempMax: mx?.toDouble(),
        tags: tags,
      ));
      if (out.length >= 4) break;
    }
    return out;
  }

  double _rainLast24h(List<dynamic> raw, DateTime now) {
    final yesterday = DateTime(now.year, now.month, now.day)
        .subtract(const Duration(days: 1));
    for (final f in raw) {
      if (f is! Map) continue;
      final d = DateTime.tryParse(f['date']?.toString() ?? '');
      if (d == null) continue;
      if (DateTime(d.year, d.month, d.day) == yesterday) {
        return (f['rain'] as num?)?.toDouble() ?? 0.0;
      }
    }
    return 0.0;
  }

  DateTime? _lastDate(
    List<Map<String, dynamic>> activities,
    String type,
    String? cropId,
  ) {
    DateTime? best;
    for (final a in activities) {
      if (a['type']?.toString() != type) continue;
      final ac = a['crop_id']?.toString();
      if (cropId != null && ac != null && ac.isNotEmpty && ac != cropId) {
        continue;
      }
      final d = a['date'];
      if (d is DateTime) {
        if (best == null || d.isAfter(best)) best = d;
      }
    }
    return best;
  }

  List<FactorBar> _buildFactors({
    required double waterDeficit,
    required double nStress,
    required double diseasePressure,
    double? tempMin,
    double? tempMax,
    double? todayMin,
    double? todayMax,
  }) {
    // Su: açık ne kadar düşük o kadar iyi; -3..0 = ideal; 5..15 = orta; 15+ kötü.
    double waterScore;
    String waterNote;
    if (waterDeficit <= 2 && waterDeficit >= -3) {
      waterScore = 1.0;
      waterNote = 'İdeal nem';
    } else if (waterDeficit < -3) {
      waterScore = 0.55;
      waterNote = 'Aşırı ıslak';
    } else if (waterDeficit < _moderateDeficitMm) {
      waterScore = 0.85;
      waterNote = '${waterDeficit.toStringAsFixed(1)} mm açık';
    } else if (waterDeficit < _criticalDeficitMm) {
      waterScore = 0.55;
      waterNote = '${waterDeficit.toStringAsFixed(0)} mm açık — orta stres';
    } else {
      waterScore = 0.20;
      waterNote = '${waterDeficit.toStringAsFixed(0)} mm açık — yüksek stres';
    }

    final nScore = (1.0 - nStress).clamp(0.0, 1.0);
    final nNote = nStress < 0.10
        ? 'Yeterli besin'
        : nStress < 0.30
            ? 'Hafif eksiklik'
            : 'Belirgin eksiklik (%${(nStress * 100).round()})';

    // İklim: bugünün min/max bitki idealinin içindeyse 1, dışındaysa düşük.
    double climateScore = 1.0;
    String climateNote = 'Uygun';
    if (todayMin != null && tempMin != null && todayMin < tempMin) {
      climateScore = 0.55;
      climateNote = 'Soğuk stres';
    } else if (todayMax != null && tempMax != null && todayMax > tempMax) {
      climateScore = 0.55;
      climateNote = 'Sıcak stres';
    } else if (todayMin != null && tempMin != null && todayMin < tempMin + 3) {
      climateScore = 0.80;
      climateNote = 'Sınırda serin';
    } else if (todayMax != null && tempMax != null && todayMax > tempMax - 3) {
      climateScore = 0.80;
      climateNote = 'Sınırda sıcak';
    }

    final healthScore = (1.0 - diseasePressure).clamp(0.0, 1.0);
    final healthNote = diseasePressure < 0.10
        ? 'Sağlıklı'
        : diseasePressure < 0.40
            ? 'Hafif baskı'
            : diseasePressure < 0.70
                ? 'Yüksek baskı'
                : 'Kritik';

    return [
      FactorBar(
          label: 'Su',
          value: waterScore,
          note: waterNote,
          iconKey: 'water'),
      FactorBar(
          label: 'Besin',
          value: nScore,
          note: nNote,
          iconKey: 'fertilizer'),
      FactorBar(
          label: 'İklim',
          value: climateScore,
          note: climateNote,
          iconKey: 'climate'),
      FactorBar(
          label: 'Sağlık',
          value: healthScore,
          note: healthNote,
          iconKey: 'disease'),
    ];
  }

  int _healthScore({
    required List<FactorBar> factors,
    required double yieldMultiplier,
  }) {
    if (factors.isEmpty) return 80;
    // Su ve sağlık daha kritik — 1.4x ağırlık.
    final weights = {'Su': 1.4, 'Besin': 1.0, 'İklim': 1.0, 'Sağlık': 1.4};
    double weightedSum = 0;
    double totalWeight = 0;
    for (final f in factors) {
      final w = weights[f.label] ?? 1.0;
      weightedSum += f.value * w;
      totalWeight += w;
    }
    final base = (weightedSum / totalWeight) * 100;
    final adjusted = base * yieldMultiplier.clamp(0.5, 1.05);
    return adjusted.round().clamp(0, 100);
  }

  String _healthLabel(int score) {
    if (score >= 85) return 'Çok iyi';
    if (score >= 70) return 'İyi';
    if (score >= 55) return 'Dikkat';
    if (score >= 40) return 'Risk';
    return 'Kritik';
  }

  StageInfo? _stageInfo({
    required Map<String, dynamic> crop,
    String? stageKey,
    CropDailyPlanResult? plan,
    required DateTime now,
    required int harvestDays,
  }) {
    final plantedRaw = crop['planted_date']?.toString();
    final planted = plan?.plantedDate ?? _parsePlanted(plantedRaw);
    if (planted == null) return null;
    final since = now.difference(planted).inDays;
    final remaining = (harvestDays - since).clamp(0, harvestDays);
    final progress = harvestDays <= 0 ? 0.0 : (since / harvestDays).clamp(0.0, 1.0);
    final label = _stageLabel(stageKey ?? plan?.currentStageKey);
    final liner = remaining == 0
        ? 'Hasat zamanı.'
        : remaining < 14
            ? '$remaining gün içinde hasata hazırlık.'
            : '$label evresi · $remaining gün hasata kaldı.';
    return StageInfo(
      stageLabel: label,
      daysSincePlanting: since,
      daysToHarvest: remaining,
      seasonProgress: progress,
      oneLiner: liner,
    );
  }

  static String _stageLabel(String? key) {
    switch (key) {
      case 'cimlenme':
        return 'Çimlenme';
      case 'vejetatif':
        return 'Vejetatif büyüme';
      case 'ciceklenme':
        return 'Çiçeklenme';
      case 'meyve_dolumu':
        return 'Meyve dolumu';
      case 'olgunlasma':
        return 'Olgunlaşma';
      case 'hasat':
        return 'Hasat';
      default:
        return 'Büyüme';
    }
  }

  static DateTime? _parsePlanted(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    final parts = raw.split('.');
    if (parts.length == 3) {
      final iso =
          '${parts[2]}-${parts[1].padLeft(2, '0')}-${parts[0].padLeft(2, '0')}';
      return DateTime.tryParse(iso);
    }
    return DateTime.tryParse(raw);
  }

  List<GuideAction> _buildActions({
    required Map<String, dynamic> crop,
    required List<Map<String, dynamic>> activities,
    CropDailyPlanResult? plan,
    required List<RiskBanner> risks,
    required DateTime now,
    String? cropId,
    required String cropName,
    required double waterDeficit,
    required double rainNext48h,
  }) {
    final out = <GuideAction>[];
    final added = <String>{};

    // Risk şeritlerinden actionType olanları tek-tıklık görev yap.
    for (final r in risks) {
      if (r.actionType == null) continue;
      final key = '${r.actionType}_${r.kind.name}';
      if (added.contains(key)) continue;
      added.add(key);
      out.add(GuideAction(
        headline: _actionHeadline(r),
        detail: r.advice,
        actionType: r.actionType!,
        recommendedQuantity: r.actionQuantity,
        unit: r.actionUnit,
        priority: r.severity,
        iconKey: r.iconKey,
      ));
    }

    // Bugünün plan görevlerinden henüz yapılmamış olanlar.
    final today = plan?.today;
    if (today != null) {
      for (final task in today.tasks) {
        if (task.done) continue;
        final key = '${task.type}_plan';
        if (added.contains(key)) continue;
        added.add(key);
        out.add(GuideAction(
          headline: task.label,
          detail: task.detail ?? '',
          actionType: task.type,
          recommendedQuantity: task.recommendedQuantity,
          unit: task.unit,
          priority: RiskSeverity.warning,
          iconKey: _iconForActivity(task.type),
        ));
      }
    }

    return out;
  }

  String _actionHeadline(RiskBanner r) {
    if (r.actionType == ActivityType.watering) {
      final mins = r.actionQuantity?.round();
      return mins == null ? 'Sula' : '$mins dk sula';
    }
    if (r.actionType == ActivityType.fertilizing) return 'Gübrele';
    if (r.actionType == ActivityType.spraying) return 'İlaçla';
    if (r.actionType == ActivityType.scouting) return 'Tarlayı gez';
    if (r.actionType == ActivityType.harvest) return 'Hasat et';
    return 'Yap';
  }

  String _iconForActivity(String type) {
    switch (type) {
      case ActivityType.watering:
        return 'water';
      case ActivityType.fertilizing:
        return 'fertilizer';
      case ActivityType.spraying:
        return 'spray';
      case ActivityType.scouting:
        return 'scout';
      case ActivityType.harvest:
        return 'harvest';
      default:
        return 'task';
    }
  }

  ActivityImpact? _computeImpact({
    required List<Map<String, dynamic>> activities,
    String? cropId,
    required DateTime now,
    double? planTotal,
    double? planApplied,
    required double waterDeficit,
  }) {
    Map<String, dynamic>? last;
    for (final a in activities) {
      final ac = a['crop_id']?.toString();
      if (cropId != null && ac != null && ac.isNotEmpty && ac != cropId) {
        continue;
      }
      final d = a['date'];
      if (d is! DateTime) continue;
      if (last == null || d.isAfter(last['date'] as DateTime)) {
        last = a;
      }
    }
    if (last == null) return null;
    final when = last['date'] as DateTime;
    if (now.difference(when).inHours > 36) return null; // çok eski
    final type = last['type']?.toString() ?? '';
    final qty = (last['quantity'] as num?)?.toDouble();
    final unit = last['unit']?.toString();
    String summary;
    String detail;
    String iconKey;
    final hoursAgo = now.difference(when).inHours;
    final timeLabel = hoursAgo < 1
        ? '${now.difference(when).inMinutes} dk önce'
        : hoursAgo < 24
            ? '$hoursAgo saat önce'
            : 'dün';
    switch (type) {
      case ActivityType.watering:
        final waterMm =
            ((last['metadata'] as Map?)?['effective_water_mm'] as num?)
                ?.toDouble();
        summary = waterMm != null
            ? '+${waterMm.toStringAsFixed(0)} mm su'
            : (qty != null && unit != null)
                ? '${qty.toStringAsFixed(0)} $unit'
                : 'Sulama yapıldı';
        detail = waterDeficit <= 2
            ? 'Açık kapandı, bitki rahat. ($timeLabel)'
            : 'Açık ${waterDeficit.toStringAsFixed(0)} mm — $timeLabel.';
        iconKey = 'water';
        break;
      case ActivityType.fertilizing:
        summary = qty != null ? '${qty.toStringAsFixed(0)} kg gübre' : 'Gübrelendi';
        detail = 'Etkisi 3-5 günde yapraklarda görünür. ($timeLabel)';
        iconKey = 'fertilizer';
        break;
      case ActivityType.spraying:
        summary = 'İlaçlama yapıldı';
        detail =
            'Gözlem 7 gün sonra yapılmalı; bekleme süresine dikkat. ($timeLabel)';
        iconKey = 'spray';
        break;
      case ActivityType.harvest:
        summary = qty != null ? '${qty.toStringAsFixed(0)} kg hasat' : 'Hasat';
        detail = 'Sezon kayıtlandı. ($timeLabel)';
        iconKey = 'harvest';
        break;
      case ActivityType.scouting:
        summary = 'Gözlem kaydı';
        detail = 'Eşik aşıldıysa ilaçlama, değilse tekrar gözle. ($timeLabel)';
        iconKey = 'scout';
        break;
      default:
        summary = 'Aktivite kaydı';
        detail = timeLabel;
        iconKey = 'task';
    }
    return ActivityImpact(
      activityLabel: ActivityType.label(type),
      when: when,
      summary: summary,
      detail: detail,
      iconKey: iconKey,
    );
  }

  String _oneLiner({
    required List<RiskBanner> risks,
    required List<GuideAction> actions,
    required int healthScore,
    String? stageLabel,
  }) {
    final critical =
        risks.where((r) => r.severity == RiskSeverity.critical).toList();
    if (critical.isNotEmpty) return critical.first.title.toLowerCase();
    if (actions.isEmpty && risks.isEmpty) {
      if (healthScore >= 85) {
        return 'Bitki rahat. Bugün acil iş yok.';
      }
      return 'Bugün acil iş yok, ${stageLabel?.toLowerCase() ?? 'büyüme'} sürüyor.';
    }
    if (actions.length == 1) return '${actions.first.headline}.';
    return '${actions.length} görev sıraya alındı.';
  }

  static double _suggestMinutes(double deficitMm) {
    // 1 dk damla ≈ 0.6 mm (varsayılan plan motoru ile aynı). Açık kapatma + %20.
    final mins = (deficitMm / 0.6) * 1.2;
    return mins.clamp(8.0, 90.0);
  }
}

// Daily plan motoruna `GrowthSnapshot` map'leme yardımcısı (UI tarafı çağırır).
GrowthSnapshot? snapshotFromMap(Map<String, dynamic>? m) {
  if (m == null) return null;
  return GrowthSnapshot(
    stageKey: (m['current_stage_key'] ?? m['currentStageKey'])?.toString() ??
        'vejetatif',
    stageProgress:
        ((m['stage_progress'] ?? m['stageProgress']) as num?)?.toDouble() ?? 0,
    accumulatedGdd:
        ((m['accumulated_gdd'] ?? m['accumulatedGdd']) as num?)?.toDouble() ??
            0,
    waterDeficitMm:
        ((m['water_deficit_mm'] ?? m['waterDeficitMm']) as num?)?.toDouble() ??
            0,
    nStressIdx:
        ((m['n_stress_idx'] ?? m['nStressIdx']) as num?)?.toDouble() ?? 0,
    diseasePressure: ((m['disease_pressure'] ?? m['diseasePressure']) as num?)
            ?.toDouble() ??
        0,
    yieldMultiplier:
        ((m['yield_multiplier'] ?? m['yieldMultiplier']) as num?)?.toDouble() ??
            1.0,
  );
}
