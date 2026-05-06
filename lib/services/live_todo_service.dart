import 'dart:convert';

import '../data/activity_types.dart';
import '../data/app_database.dart';
import 'field_state_service.dart';
import 'guide_engine.dart' show AlertSeverity;
import 'rules/crop_rule_set.dart';
import 'rules/recommendation.dart';
import 'rules/recommendation_ledger.dart';
import 'task_directive_service.dart';
import 'weather_soil_service.dart';

class LiveDecisionContext {
  final String fieldId;
  final List<Map<String, dynamic>> fieldCrops;
  final List<Map<String, dynamic>> activities;
  final List<Map<String, dynamic>> scheduledEvents;
  final Map<String, GrowthSnapshot> growthStates;
  final Map<String, CropFieldState> cropFieldStates;
  final Map<String, RuleFieldStateSnapshot> fieldStates;
  final List<ActivityRecord> activityRecords;
  final List<PlantInstanceSnapshot> plantInstances;
  final List<CropRuleSet> ruleSets;
  final HourlyForecast? hourly;
  final RuleEnvironmentSnapshot? environment;
  final RecommendationLedger? ledger;
  final DateTime now;

  const LiveDecisionContext({
    required this.fieldId,
    required this.fieldCrops,
    required this.activities,
    required this.scheduledEvents,
    required this.growthStates,
    required this.cropFieldStates,
    required this.fieldStates,
    required this.activityRecords,
    required this.plantInstances,
    required this.ruleSets,
    required this.now,
    this.hourly,
    this.environment,
    this.ledger,
  });
}

class LiveDecisionContextBuilder {
  const LiveDecisionContextBuilder();

  LiveDecisionContext build({
    required String fieldId,
    required List<Map<String, dynamic>> fieldCrops,
    required List<Map<String, dynamic>> activities,
    required List<Map<String, dynamic>> scheduledEvents,
    required List<CropGrowthState> growthRows,
    required List<FieldPlantInstance> plantRows,
    required List<CropFieldState> fieldStateRows,
    required List<CropRuleSet> ruleSets,
    required DateTime now,
    HourlyForecast? hourly,
    RuleEnvironmentSnapshot? environment,
    RecommendationLedger? ledger,
  }) {
    final realActivities = activities
        .where((activity) => _isRealActivity(activity, now))
        .toList(growable: false);
    final growthStates = <String, GrowthSnapshot>{};
    for (final g in growthRows) {
      growthStates[g.cropId] = GrowthSnapshot(
        stageKey: g.currentStageKey,
        stageProgress: g.stageProgress,
        accumulatedGdd: g.accumulatedGdd,
        waterDeficitMm: g.waterDeficitMm,
        nStressIdx: g.nStressIdx,
        diseasePressure: g.diseasePressure,
        yieldMultiplier: g.yieldMultiplier,
      );
    }

    final activityRecords = <ActivityRecord>[];
    for (final a in realActivities) {
      final at = _parseDate(a['date']);
      if (at == null) continue;
      activityRecords.add(ActivityRecord(
        type: a['type']?.toString() ?? '',
        subtype: a['subtype']?.toString(),
        at: at,
        plantInstanceId: a['plant_instance_id']?.toString(),
        quantity: (a['quantity'] as num?)?.toDouble(),
      ));
    }
    activityRecords.sort((a, b) => b.at.compareTo(a.at));

    final plantInstances = <PlantInstanceSnapshot>[];
    for (final p in plantRows) {
      plantInstances.add(PlantInstanceSnapshot(
        id: p.id,
        cropId: p.cropId,
        cropName: p.cropName,
        healthStatus: p.healthStatus,
        conditionFlags: _decodeStringList(p.conditionFlagsJson),
      ));
    }

    final fieldStates = <String, RuleFieldStateSnapshot>{};
    final cropFieldStates = <String, CropFieldState>{};
    for (final state in fieldStateRows) {
      cropFieldStates[state.cropId] = state;
      fieldStates[state.cropId] = RuleFieldStateSnapshot(
        areaDekar: state.areaDekar,
        areaSqm: state.areaSqm,
        estimatedPlantCount: state.estimatedPlantCount,
        weeklyWaterMm: state.weeklyWaterMm,
        weeklyWaterLiters: state.weeklyWaterLiters,
        weeklyWaterTargetMm: state.weeklyWaterTargetMm,
        seasonalWaterMm: state.seasonalWaterMm,
        seasonalWaterLiters: state.seasonalWaterLiters,
        lastWateredAt: state.lastWateredAt,
        lastFertilizedAt: state.lastFertilizedAt,
        lastSprayedAt: state.lastSprayedAt,
      );
    }

    return LiveDecisionContext(
      fieldId: fieldId,
      fieldCrops: fieldCrops,
      activities: realActivities,
      scheduledEvents: scheduledEvents,
      growthStates: growthStates,
      cropFieldStates: cropFieldStates,
      fieldStates: fieldStates,
      activityRecords: activityRecords,
      plantInstances: plantInstances,
      ruleSets: ruleSets,
      hourly: hourly,
      environment: environment,
      ledger: ledger,
      now: now,
    );
  }

  static DateTime? _parseDate(Object? raw) {
    if (raw is DateTime) return raw;
    if (raw is String) return DateTime.tryParse(raw);
    return null;
  }

  static bool _isRealActivity(Map<String, dynamic> activity, DateTime now) {
    if (activity['source']?.toString() == 'auto_seed') return false;
    final at = _parseDate(activity['date']);
    if (at != null && at.isAfter(now)) return false;
    return true;
  }

  static List<String> _decodeStringList(String? raw) {
    if (raw == null || raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return decoded.whereType<String>().where((v) => v.isNotEmpty).toList();
    } catch (_) {
      return const [];
    }
  }
}

class LiveTodoService {
  const LiveTodoService();

  List<Recommendation> generate(LiveDecisionContext ctx) {
    final out = <Recommendation>[
      ..._deadPlantRecommendations(ctx),
      ..._directiveRecommendations(ctx),
      ..._ruleRecommendations(ctx),
    ];
    final cleared = out.where((r) => !_isCleared(ctx, r)).toList();
    final conflictFree = _resolveConflicts(ctx, cleared);
    final deduped = _dedupe(conflictFree);
    deduped.sort(_compare);
    return deduped;
  }

  List<Recommendation> _deadPlantRecommendations(LiveDecisionContext ctx) {
    final out = <Recommendation>[];
    for (final plant in ctx.plantInstances) {
      if (plant.healthStatus != 'dead') continue;
      final cropName = plant.cropName?.isNotEmpty == true
          ? plant.cropName!
          : 'Bitki';
      out.add(Recommendation(
        ruleKey: 'plant.dead.remove.${plant.id}.v1',
        severity: AlertSeverity.critical,
        target: RecommendationTarget.plant(
          fieldId: ctx.fieldId,
          plantInstanceId: plant.id,
          cropId: plant.cropId,
        ),
        title: '$cropName cansız bitki: sök',
        reasonText: 'Bitki cansız işaretlendi; tarlada bırakılmamalı.',
        reasonBullets: const [
          'Bitkiyi köküyle birlikte söküp tarladan uzaklaştırın.',
          'Belirti çevresine yayıldıysa yakın çevrede hastalık ve zararlı takibi yapın.',
          'Yayılım doğrulanırsa BKÜ etiketi ve uzman onayıyla çevresel ilaçlama gerekebilir.',
        ],
        actionHint: 'Tekil sökme kaydı oluştur ve bitkiyi haritadan kaldır.',
        gate: RecommendationGate.actionable,
        evidence: [
          const RecommendationEvidence(label: 'Bitki durumu', value: 'Cansız'),
          RecommendationEvidence(label: 'Bitki', value: cropName),
        ],
        command: RecommendationCommand(
          activityType: ActivityType.scouting,
          subtype: ActivitySubtype.note,
          buttonLabel: 'Söktüm, haritadan kaldır',
          note: '$cropName cansız bitki söküldü ve tarladan uzaklaştırıldı',
          metadata: {
            'dead_plant_removal': true,
            'remove_plant_instance_after_log': true,
            'health_status': 'dead',
            'crop_name': cropName,
            'spread_warning': true,
          },
        ),
        cooldownHours: 0,
      ));
    }
    return out;
  }

  List<Recommendation> _directiveRecommendations(LiveDecisionContext ctx) {
    final directives = const TaskDirectiveService().generate(
      fieldCrops: ctx.fieldCrops,
      activities: ctx.activities,
      scheduledEvents: ctx.scheduledEvents,
      growthStates: ctx.growthStates,
      fieldStates: ctx.cropFieldStates,
      now: ctx.now,
    );
    return directives
        .where((d) => d.kind != 'idle')
        .map((d) => _fromDirective(ctx.fieldId, d))
        .toList();
  }

  Recommendation _fromDirective(String fieldId, FieldDirective d) {
    final target = d.cropId == null || d.cropId!.isEmpty
        ? RecommendationTarget.field(fieldId)
        : RecommendationTarget.crop(fieldId: fieldId, cropId: d.cropId!);
    final gate = d.actionType == ActivityType.spraying
        ? RecommendationGate.observeFirst
        : RecommendationGate.actionable;
    final commandType = gate == RecommendationGate.observeFirst
        ? ActivityType.scouting
        : d.actionType;
    final evidence = <RecommendationEvidence>[
      RecommendationEvidence(label: 'Direktif türü', value: d.kind),
      if (d.areaDekar != null)
        RecommendationEvidence(
          label: 'Alan',
          value: '${d.areaDekar!.toStringAsFixed(2)} da',
        ),
      if (d.plantCount != null)
        RecommendationEvidence(
            label: 'Tahmini bitki', value: '${d.plantCount}'),
    ];
    return Recommendation(
      ruleKey: 'directive.${d.kind}.${d.cropId ?? fieldId}.v1',
      severity: d.urgency >= 2
          ? AlertSeverity.critical
          : (d.urgency == 1 ? AlertSeverity.warning : AlertSeverity.info),
      target: target,
      title: d.headline,
      reasonText: d.reason,
      reasonBullets: d.steps,
      actionHint: d.steps.isEmpty ? d.reason : d.steps.first,
      gate: gate,
      evidence: evidence,
      command: commandType == null
          ? null
          : RecommendationCommand(
              activityType: commandType,
              quantity: d.suggestedQuantity,
              quantityUnit: d.quantityUnit,
              recommendedQuantity: d.recommendedQuantity ?? d.suggestedQuantity,
              buttonLabel: ActivityType.actionLabel(commandType),
              metadata: {
                'directive_kind': d.kind,
                if (gate == RecommendationGate.observeFirst)
                  'ipm_gate': 'observe_before_spray',
              },
            ),
      sourceRefs: d.sourceRefs,
      cooldownHours: d.urgency >= 2 ? 12 : 24,
    );
  }

  List<Recommendation> _ruleRecommendations(LiveDecisionContext ctx) {
    final out = <Recommendation>[];
    for (final crop in ctx.fieldCrops) {
      final cropId = crop['id']?.toString();
      final cropName = crop['name']?.toString() ?? '';
      if (cropId == null || cropId.isEmpty) continue;
      final ruleSet = _ruleSetFor(ctx.ruleSets, cropName);
      if (ruleSet == null) continue;
      final planted = _parsePlanted(crop['planted_date']?.toString());
      final evalCtx = RuleEvaluationContext(
        fieldId: ctx.fieldId,
        crop: FieldCropSnapshot(
          id: cropId,
          name: cropName,
          plantedDate: planted,
        ),
        growth: ctx.growthStates[cropId],
        recentActivities: ctx.activityRecords,
        plantInstances: ctx.plantInstances,
        hourly: ctx.hourly,
        environment: ctx.environment,
        fieldState: ctx.fieldStates[cropId],
        now: ctx.now,
      );
      for (final rec in ruleSet.evaluate(evalCtx)) {
        final ledger = ctx.ledger;
        if (ledger != null &&
            ledger.isOnCooldown(
              ruleKey: rec.ruleKey,
              target: rec.target,
              cooldownHours: rec.cooldownHours,
              now: ctx.now,
            )) {
          continue;
        }
        out.add(rec);
      }
    }
    return out;
  }

  CropRuleSet? _ruleSetFor(List<CropRuleSet> ruleSets, String cropName) {
    for (final rs in ruleSets) {
      if (rs.matches(cropName)) return rs;
    }
    return null;
  }

  bool _isCleared(LiveDecisionContext ctx, Recommendation rec) {
    for (final clear in rec.clearOnActivities) {
      for (final a in ctx.activityRecords) {
        if (a.type != clear.activityType) continue;
        if (clear.subtype != null && a.subtype != clear.subtype) continue;
        if (rec.target.plantInstanceId != null &&
            a.plantInstanceId != rec.target.plantInstanceId) {
          continue;
        }
        final hours = ctx.now.difference(a.at).inMinutes / 60.0;
        if (hours <= clear.withinHours) return true;
      }
    }
    return false;
  }

  List<Recommendation> _resolveConflicts(
    LiveDecisionContext ctx,
    List<Recommendation> input,
  ) {
    final harvestCropIds = input
        .where((r) => r.command?.activityType == ActivityType.harvest)
        .map((r) => r.target.cropId)
        .whereType<String>()
        .toSet();
    final rainNext24h = ctx.hourly?.rainSumNext(24) ?? 0;
    return input.where((r) {
      final action = r.command?.activityType;
      final cropId = r.target.cropId;
      if (cropId != null &&
          harvestCropIds.contains(cropId) &&
          (action == ActivityType.watering ||
              action == ActivityType.fertilizing)) {
        return false;
      }
      if (rainNext24h >= 8 &&
          action == ActivityType.watering &&
          !r.ruleKey.startsWith('sunflower.water_stress.')) {
        return false;
      }
      return true;
    }).toList();
  }

  List<Recommendation> _dedupe(List<Recommendation> input) {
    final byKey = <String, Recommendation>{};
    for (final r in input) {
      final key = [
        r.command?.activityType ?? r.ruleKey,
        r.target.fieldId,
        r.target.cropId ?? '',
        r.target.plantInstanceId ?? '',
      ].join('::');
      final prev = byKey[key];
      if (prev == null || _compare(r, prev) < 0) {
        byKey[key] = r;
      }
    }
    return byKey.values.toList();
  }

  int _compare(Recommendation a, Recommendation b) {
    final severity = _severityOrder(a.severity).compareTo(
      _severityOrder(b.severity),
    );
    if (severity != 0) return severity;
    final gate = _gateOrder(a.gate).compareTo(_gateOrder(b.gate));
    if (gate != 0) return gate;
    final origin = _originOrder(a).compareTo(_originOrder(b));
    if (origin != 0) return origin;
    final sources = b.sourceRefs.length.compareTo(a.sourceRefs.length);
    if (sources != 0) return sources;
    return a.ruleKey.compareTo(b.ruleKey);
  }

  int _originOrder(Recommendation r) {
    return r.ruleKey.startsWith('directive.') ? 1 : 0;
  }

  int _severityOrder(AlertSeverity severity) {
    switch (severity) {
      case AlertSeverity.critical:
        return 0;
      case AlertSeverity.warning:
        return 1;
      case AlertSeverity.info:
        return 2;
    }
  }

  int _gateOrder(RecommendationGate gate) {
    switch (gate) {
      case RecommendationGate.actionable:
        return 0;
      case RecommendationGate.observeFirst:
        return 1;
      case RecommendationGate.blocked:
        return 2;
    }
  }

  DateTime? _parsePlanted(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    final direct = DateTime.tryParse(raw);
    if (direct != null) return direct;
    final parts = raw.split('.');
    if (parts.length != 3) return null;
    return DateTime.tryParse(
      '${parts[2]}-${parts[1].padLeft(2, '0')}-${parts[0].padLeft(2, '0')}',
    );
  }
}
