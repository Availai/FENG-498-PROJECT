/// Sulama yontemleri rehberi icin asset tabanli repository.
///
/// Veri: `assets/data/irrigation_methods.json` (kaynak kanitli, offline-first).
/// CLAUDE.md S10-S14 uyumlu: her metot evidence + source_ids tasir.
library;

import 'dart:convert';
import 'package:flutter/services.dart';

class IrrigationSource {
  final String id;
  final String title;
  final String institution;
  final String sourceType;
  final String url;
  final int? publicationYear;
  final String retrievedAt;
  final String reliability;
  final String? notes;

  const IrrigationSource({
    required this.id,
    required this.title,
    required this.institution,
    required this.sourceType,
    required this.url,
    required this.publicationYear,
    required this.retrievedAt,
    required this.reliability,
    required this.notes,
  });

  factory IrrigationSource.fromJson(Map<String, dynamic> j) => IrrigationSource(
        id: j['id'] as String,
        title: j['title'] as String,
        institution: j['institution'] as String,
        sourceType: j['source_type'] as String,
        url: j['url'] as String,
        publicationYear: j['publication_year'] as int?,
        retrievedAt: j['retrieved_at'] as String,
        reliability: j['reliability'] as String,
        notes: j['notes'] as String?,
      );
}

class IrrigationEvidence {
  final String sourceId;
  final String evidenceText;
  const IrrigationEvidence({required this.sourceId, required this.evidenceText});
  factory IrrigationEvidence.fromJson(Map<String, dynamic> j) =>
      IrrigationEvidence(
        sourceId: j['source_id'] as String,
        evidenceText: j['evidence_text'] as String,
      );
}

class IrrigationMethod {
  final String id;
  final String category; // surface | sprinkler | drip | micro
  final String nameTr;
  final String summary;
  final List<int> efficiencyPctRange; // [min,max]
  final List<int>? waterSavingVsFurrowPctRange;
  final int? waterSavingVsFurrowPct;
  final List<int> initialInvestmentTlPerDecareRange;
  final String operationalCostLevel;
  final String energyRequirement;
  final String laborRequirement;
  final List<String> suitableCrops;
  final String suitableTerrain;
  final List<String> pros;
  final List<String> cons;
  final List<IrrigationEvidence> evidence;
  final bool requiresExpertConfirmation;

  const IrrigationMethod({
    required this.id,
    required this.category,
    required this.nameTr,
    required this.summary,
    required this.efficiencyPctRange,
    required this.waterSavingVsFurrowPctRange,
    required this.waterSavingVsFurrowPct,
    required this.initialInvestmentTlPerDecareRange,
    required this.operationalCostLevel,
    required this.energyRequirement,
    required this.laborRequirement,
    required this.suitableCrops,
    required this.suitableTerrain,
    required this.pros,
    required this.cons,
    required this.evidence,
    required this.requiresExpertConfirmation,
  });

  factory IrrigationMethod.fromJson(Map<String, dynamic> j) {
    List<int> ints(dynamic v) =>
        (v as List).map((e) => (e as num).toInt()).toList();
    return IrrigationMethod(
      id: j['id'] as String,
      category: j['category'] as String,
      nameTr: j['name_tr'] as String,
      summary: j['summary'] as String,
      efficiencyPctRange: ints(j['efficiency_pct_range']),
      waterSavingVsFurrowPctRange: j['water_saving_vs_furrow_pct_range'] == null
          ? null
          : ints(j['water_saving_vs_furrow_pct_range']),
      waterSavingVsFurrowPct: (j['water_saving_vs_furrow_pct'] as num?)?.toInt(),
      initialInvestmentTlPerDecareRange:
          ints(j['initial_investment_tl_per_decare_range']),
      operationalCostLevel: j['operational_cost_level'] as String,
      energyRequirement: j['energy_requirement'] as String,
      laborRequirement: j['labor_requirement'] as String,
      suitableCrops:
          (j['suitable_crops'] as List).map((e) => e as String).toList(),
      suitableTerrain: j['suitable_terrain'] as String,
      pros: (j['pros'] as List).map((e) => e as String).toList(),
      cons: (j['cons'] as List).map((e) => e as String).toList(),
      evidence: (j['evidence'] as List)
          .map((e) => IrrigationEvidence.fromJson(e as Map<String, dynamic>))
          .toList(),
      requiresExpertConfirmation:
          j['requires_expert_confirmation'] as bool? ?? false,
    );
  }
}

class WaterSavingTip {
  final String id;
  final String title;
  final String detail;
  final List<String> sourceIds;
  const WaterSavingTip({
    required this.id,
    required this.title,
    required this.detail,
    required this.sourceIds,
  });
  factory WaterSavingTip.fromJson(Map<String, dynamic> j) => WaterSavingTip(
        id: j['id'] as String,
        title: j['title'] as String,
        detail: j['detail'] as String,
        sourceIds:
            (j['source_ids'] as List).map((e) => e as String).toList(),
      );
}

class TransitionExample {
  final String id;
  final String fromMethodId;
  final String toMethodId;
  final List<int> waterSavingPctRange;
  final List<int>? yieldIncreasePctRange;
  final List<int>? paybackYearsRange;
  final List<IrrigationEvidence> evidence;
  final String? note;

  const TransitionExample({
    required this.id,
    required this.fromMethodId,
    required this.toMethodId,
    required this.waterSavingPctRange,
    required this.yieldIncreasePctRange,
    required this.paybackYearsRange,
    required this.evidence,
    required this.note,
  });

  factory TransitionExample.fromJson(Map<String, dynamic> j) {
    List<int>? ints(dynamic v) =>
        v == null ? null : (v as List).map((e) => (e as num).toInt()).toList();
    return TransitionExample(
      id: j['id'] as String,
      fromMethodId: j['from_method_id'] as String,
      toMethodId: j['to_method_id'] as String,
      waterSavingPctRange: ints(j['water_saving_pct_range'])!,
      yieldIncreasePctRange: ints(j['yield_increase_pct_range']),
      paybackYearsRange: ints(j['payback_years_range']),
      evidence: (j['evidence'] as List)
          .map((e) => IrrigationEvidence.fromJson(e as Map<String, dynamic>))
          .toList(),
      note: j['note'] as String?,
    );
  }
}

class Incentive {
  final String id;
  final String title;
  final String detail;
  final List<String> sourceIds;
  final String userAction;
  const Incentive({
    required this.id,
    required this.title,
    required this.detail,
    required this.sourceIds,
    required this.userAction,
  });
  factory Incentive.fromJson(Map<String, dynamic> j) => Incentive(
        id: j['id'] as String,
        title: j['title'] as String,
        detail: j['detail'] as String,
        sourceIds:
            (j['source_ids'] as List).map((e) => e as String).toList(),
        userAction: j['user_action'] as String,
      );
}

class IrrigationGuideData {
  final String schemaVersion;
  final String disclaimer;
  final List<IrrigationSource> sources;
  final List<WaterSavingTip> generalTips;
  final List<IrrigationMethod> methods;
  final List<TransitionExample> transitions;
  final List<Incentive> incentives;

  const IrrigationGuideData({
    required this.schemaVersion,
    required this.disclaimer,
    required this.sources,
    required this.generalTips,
    required this.methods,
    required this.transitions,
    required this.incentives,
  });

  IrrigationSource? sourceById(String id) {
    for (final s in sources) {
      if (s.id == id) return s;
    }
    return null;
  }

  IrrigationMethod? methodById(String id) {
    for (final m in methods) {
      if (m.id == id) return m;
    }
    return null;
  }
}

class IrrigationMethodsRepository {
  IrrigationMethodsRepository._();
  static final instance = IrrigationMethodsRepository._();

  IrrigationGuideData? _cache;
  Future<IrrigationGuideData>? _loading;

  Future<IrrigationGuideData> load() {
    if (_cache != null) return Future.value(_cache);
    return _loading ??= _loadFromAsset();
  }

  Future<IrrigationGuideData> _loadFromAsset() async {
    final raw =
        await rootBundle.loadString('assets/data/irrigation_methods.json');
    final json = jsonDecode(raw) as Map<String, dynamic>;
    final data = IrrigationGuideData(
      schemaVersion: json['schema_version'] as String,
      disclaimer: json['disclaimer'] as String,
      sources: (json['source_metadata'] as List)
          .map((e) => IrrigationSource.fromJson(e as Map<String, dynamic>))
          .toList(),
      generalTips: (json['general_water_saving_tips'] as List)
          .map((e) => WaterSavingTip.fromJson(e as Map<String, dynamic>))
          .toList(),
      methods: (json['methods'] as List)
          .map((e) => IrrigationMethod.fromJson(e as Map<String, dynamic>))
          .toList(),
      transitions: (json['transition_savings_examples'] as List)
          .map((e) => TransitionExample.fromJson(e as Map<String, dynamic>))
          .toList(),
      incentives: (json['incentives'] as List)
          .map((e) => Incentive.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
    _cache = data;
    return data;
  }
}
