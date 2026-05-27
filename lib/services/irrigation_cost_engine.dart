/// Sulama maliyet/tasarruf motoru — alternatif yönteme geçişin TL etkisi.
///
/// Pure function (CLAUDE.md §22). Aynı girdi → aynı çıktı.
///
/// Mantık:
///   - Net su ihtiyacı (mm × m²) sabittir; yöntem değişse de aynı.
///   - Gross (verilen) su = net / yöntem verimi.
///   - Yöntem değişince gross değişir → su faturası + pompa enerjisi değişir.
///   - Tasarruf = (mevcut gross − alternatif gross) × (su fiyatı + enerji fiyatı).
library;

import '../data/irrigation_methods_repository.dart';
import 'water_accounting.dart';

class CostFacts {
  final double areaDekar;
  final double seasonNetMmTotal; // sezon boyu net bitki ihtiyacı (mm)
  final String currentMethod;
  final String alternativeMethod;
  final double waterTlPerM3;
  final double electricityTlPerKwh;
  final double pumpKwhPerM3;
  final double? estimatedInvestmentTlPerDecare; // alternatif için TL/da
  final double subsidyPct; // hibe oranı (0..1) — KKYDP tipik 0.50

  const CostFacts({
    required this.areaDekar,
    required this.seasonNetMmTotal,
    required this.currentMethod,
    required this.alternativeMethod,
    required this.waterTlPerM3,
    required this.electricityTlPerKwh,
    required this.pumpKwhPerM3,
    this.estimatedInvestmentTlPerDecare,
    this.subsidyPct = 0.50,
  });
}

class MethodCostBreakdown {
  final String method;
  final double grossLiters;
  final double grossM3;
  final double waterCostTl;
  final double energyCostTl;
  final double totalCostTl;
  final double efficiency;
  const MethodCostBreakdown({
    required this.method,
    required this.grossLiters,
    required this.grossM3,
    required this.waterCostTl,
    required this.energyCostTl,
    required this.totalCostTl,
    required this.efficiency,
  });
}

class CostResult {
  final MethodCostBreakdown current;
  final MethodCostBreakdown alternative;
  final double savedM3;
  final double savedTlPerSeason;
  final double? investmentTl;
  final double? investmentAfterSubsidyTl;
  final double? paybackYears;
  final double? paybackYearsWithSubsidy;

  const CostResult({
    required this.current,
    required this.alternative,
    required this.savedM3,
    required this.savedTlPerSeason,
    required this.investmentTl,
    required this.investmentAfterSubsidyTl,
    required this.paybackYears,
    required this.paybackYearsWithSubsidy,
  });

  bool get isWorthIt => savedTlPerSeason > 0;
}

class IrrigationCostEngine {
  const IrrigationCostEngine();

  MethodCostBreakdown _breakdownFor({
    required String method,
    required double netLiters,
    required double waterTlPerM3,
    required double electricityTlPerKwh,
    required double pumpKwhPerM3,
  }) {
    final eff = WaterAccounting.methodEfficiency(method);
    final grossLiters = eff > 0 ? netLiters / eff : netLiters;
    final grossM3 = grossLiters / 1000.0;
    final waterCost = grossM3 * waterTlPerM3;
    final energyCost = grossM3 * pumpKwhPerM3 * electricityTlPerKwh;
    return MethodCostBreakdown(
      method: method,
      grossLiters: grossLiters,
      grossM3: grossM3,
      waterCostTl: waterCost,
      energyCostTl: energyCost,
      totalCostTl: waterCost + energyCost,
      efficiency: eff,
    );
  }

  CostResult compute(CostFacts f) {
    final areaSqm = (f.areaDekar <= 0 ? 1.0 : f.areaDekar) * 1000.0;
    final netLiters = f.seasonNetMmTotal * areaSqm;

    final current = _breakdownFor(
      method: f.currentMethod,
      netLiters: netLiters,
      waterTlPerM3: f.waterTlPerM3,
      electricityTlPerKwh: f.electricityTlPerKwh,
      pumpKwhPerM3: f.pumpKwhPerM3,
    );
    final alt = _breakdownFor(
      method: f.alternativeMethod,
      netLiters: netLiters,
      waterTlPerM3: f.waterTlPerM3,
      electricityTlPerKwh: f.electricityTlPerKwh,
      pumpKwhPerM3: f.pumpKwhPerM3,
    );

    final savedM3 = current.grossM3 - alt.grossM3;
    final saved = current.totalCostTl - alt.totalCostTl;

    final invest = f.estimatedInvestmentTlPerDecare == null
        ? null
        : f.estimatedInvestmentTlPerDecare! * f.areaDekar;
    final investAfter = invest == null ? null : invest * (1 - f.subsidyPct);

    double? payback;
    double? paybackSub;
    if (invest != null && saved > 0) {
      payback = invest / saved;
      paybackSub = investAfter! / saved;
    }

    return CostResult(
      current: current,
      alternative: alt,
      savedM3: savedM3,
      savedTlPerSeason: saved,
      investmentTl: invest,
      investmentAfterSubsidyTl: investAfter,
      paybackYears: payback,
      paybackYearsWithSubsidy: paybackSub,
    );
  }

  /// Yardımcı: `IrrigationMethod` rehberinden alternatif yöntemin
  /// TL/da yatırım orta değerini al.
  static double? investmentTlPerDecareFromGuide({
    required IrrigationGuideData guide,
    required String methodNameTr,
  }) {
    for (final m in guide.methods) {
      if (m.nameTr.toLowerCase().contains(methodNameTr.toLowerCase()) ||
          methodNameTr.toLowerCase().contains(m.nameTr.toLowerCase())) {
        final r = m.initialInvestmentTlPerDecareRange;
        if (r.length >= 2) return (r[0] + r[1]) / 2.0;
      }
    }
    return null;
  }
}
