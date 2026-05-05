import 'package:flutter_test/flutter_test.dart';

import 'package:feng_498/data/activity_types.dart';
import 'package:feng_498/services/daily_guide_engine.dart';

const _engine = DailyGuideEngine();

Map<String, dynamic> _crop() => const {
      'id': 'crop-1',
      'name': 'Ayçiçeği',
      'planted_date': '01.05.2026',
      'harvest_days': 120,
      'water_interval_days': 7,
      'temp_min_c': 8,
      'temp_max_c': 32,
    };

Map<String, dynamic> _growth({
  double waterDeficit = 0,
  double nStress = 0,
  double disease = 0,
  double yieldMultiplier = 1,
}) {
  return {
    'current_stage_key': 'vejetatif',
    'stage_progress': 0.35,
    'accumulated_gdd': 420,
    'water_deficit_mm': waterDeficit,
    'n_stress_idx': nStress,
    'disease_pressure': disease,
    'yield_multiplier': yieldMultiplier,
  };
}

void main() {
  test('yağmur yaklaşınca sulamayı ertele riskini üretir', () {
    final now = DateTime(2026, 5, 15, 9);
    final state = _engine.compute(
      now: now,
      crop: _crop(),
      activities: [
        {
          'type': ActivityType.watering,
          'crop_id': 'crop-1',
          'date': DateTime(2026, 5, 8, 7),
        },
      ],
      dailyForecast: const [
        {'date': '2026-05-15', 'rain': 4, 'min_temp': 14, 'max_temp': 24},
        {'date': '2026-05-16', 'rain': 5, 'min_temp': 15, 'max_temp': 24},
      ],
      growthState: _growth(waterDeficit: 0),
    );

    final rainPause =
        state.risks.firstWhere((r) => r.kind == RiskKind.rainPause);
    expect(rainPause.severity, RiskSeverity.info);
    expect(rainPause.title, contains('SULAMAYI ERTELE'));
    expect(
      state.actions.any((a) => a.actionType == ActivityType.watering),
      isFalse,
    );
  });

  test('don tahmini kritik risk şeridi üretir', () {
    final now = DateTime(2026, 5, 15);
    final state = _engine.compute(
      now: now,
      crop: _crop(),
      activities: const [],
      dailyForecast: const [
        {'date': '2026-05-15', 'rain': 0, 'min_temp': 12, 'max_temp': 24},
        {'date': '2026-05-16', 'rain': 0, 'min_temp': 2, 'max_temp': 20},
      ],
      growthState: _growth(),
    );

    final frost = state.risks.firstWhere((r) => r.kind == RiskKind.frost);
    expect(frost.severity, RiskSeverity.critical);
    expect(frost.advice, contains('ört'));
  });

  test('sıcak dalgası uyarı seviyesinde risk şeridi üretir', () {
    final now = DateTime(2026, 7, 15);
    final state = _engine.compute(
      now: now,
      crop: _crop(),
      activities: const [],
      dailyForecast: const [
        {'date': '2026-07-15', 'rain': 0, 'min_temp': 20, 'max_temp': 30},
        {'date': '2026-07-16', 'rain': 0, 'min_temp': 22, 'max_temp': 35},
      ],
      growthState: _growth(),
    );

    final heat = state.risks.firstWhere((r) => r.kind == RiskKind.heat);
    expect(heat.severity, RiskSeverity.warning);
    expect(heat.advice, contains('06:00'));
  });

  test('su açığı kritikse sulama aksiyonu üretir', () {
    final now = DateTime(2026, 6, 1);
    final state = _engine.compute(
      now: now,
      crop: _crop(),
      activities: const [],
      dailyForecast: const [
        {'date': '2026-06-01', 'rain': 0, 'min_temp': 18, 'max_temp': 28},
        {'date': '2026-06-02', 'rain': 0, 'min_temp': 18, 'max_temp': 29},
      ],
      growthState: _growth(waterDeficit: 22),
    );

    final drought =
        state.risks.firstWhere((r) => r.kind == RiskKind.droughtSevere);
    expect(drought.severity, RiskSeverity.critical);
    expect(drought.actionType, ActivityType.watering);
    expect(
      state.actions.any((a) => a.actionType == ActivityType.watering),
      isTrue,
    );
  });
}
