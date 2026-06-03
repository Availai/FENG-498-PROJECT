/// UI'nin tek temas noktası: bir aktivite kaydedilmeden ÖNCE çağrılır,
/// uygun eksendeki [GuardrailVerdict]'i döndürür.
///
/// Snapshot kurma + motor çağrısını tek yerde birleştirir, böylece her ekran
/// (activity_quick_log vb.) ayrı ayrı motor mantığı taşımaz (§22: UI içinde
/// kural değerlendirme yazma). Saf — IO yok; repository verileri çağırana
/// hazır şekilde verir.
library;

import '../../data/activity_types.dart';
import '../../data/pesticide_rei.dart';
import 'field_snapshot.dart';
import 'guardrail_limit.dart';
import 'guardrail_limits_table.dart';
import 'intake_guardrail_engine.dart';

class GuardrailChecker {
  GuardrailChecker._();

  /// Sulama kaydı öncesi su seti kontrolü.
  ///
  /// [weeklyTargetMm] çağıran tarafça `FieldStateService` ile aynı kaynaktan
  /// verilir; verilmezse `TurkiyeCropGuides`'tan türetilir, o da yoksa null
  /// → kontrol yapılmaz (ok).
  static GuardrailVerdict checkWatering({
    required FieldSnapshot snapshot,
    required double attemptMm,
    double? weeklyTargetMm,
  }) {
    final target = weeklyTargetMm ??
        GuardrailLimitsTable.weeklyTargetFromGuide(snapshot.cropName);
    if (target == null || target <= 0) {
      return GuardrailVerdict.ok(
        axis: GuardrailAxis.water,
        attemptedValue: attemptMm,
        projectedTotal: snapshot.currentWeeklyWaterMm + attemptMm,
        limitValue: 0,
        unit: 'mm/hafta',
      );
    }
    return IntakeGuardrailEngine.checkWater(
      currentWeeklyMm: snapshot.currentWeeklyWaterMm,
      attemptMm: attemptMm,
      weeklyTargetMm: target,
    );
  }

  /// Gübreleme kaydı öncesi azot seti kontrolü.
  static GuardrailVerdict checkFertilizing({
    required FieldSnapshot snapshot,
    required String? fertilizerName,
    required double? rawKg,
  }) {
    final attemptN = FieldSnapshotBuilder.nitrogenAttemptKgDa(
      fertilizerName: fertilizerName,
      rawKg: rawKg,
      areaDekar: snapshot.areaDekar,
    );
    return IntakeGuardrailEngine.checkNitrogen(
      cropName: snapshot.cropName,
      seasonalNkgDa: snapshot.seasonalNitrogenKgDa,
      attemptNkgDa: attemptN,
      hasSoilTest: snapshot.hasSoilTest,
    );
  }

  /// İlaçlama kaydı öncesi REI (yeniden girme aralığı) kontrolü.
  ///
  /// Yeni ilaçlamada kullanılacak etken madde [pesticideName] verilirse onun
  /// REI'si; verilmezse son uygulananın REI'si kullanılır.
  static GuardrailVerdict checkSpraying({
    required FieldSnapshot snapshot,
    String? pesticideName,
  }) {
    final name = pesticideName ?? snapshot.lastPesticideName ?? '';
    final reiHours = PesticideRei.lookup(name);
    return IntakeGuardrailEngine.checkPesticideReentry(
      hoursSinceLastSpray: snapshot.hoursSinceLastSpray,
      reiHours: reiHours,
    );
  }

  /// Tuzluluk durum kontrolü (gübreleme/sulama ekranında bilgi rozeti).
  static GuardrailVerdict checkSalinity(FieldSnapshot snapshot) =>
      IntakeGuardrailEngine.checkSalinity(
          measuredEcDsM: snapshot.measuredEcDsM);

  /// Aktivite tipine göre doğru ekseni seçip kontrol eder — UI tek çağrı.
  /// İlgisiz tip (gözlem, hasat vb.) → ok (sessiz).
  static GuardrailVerdict checkForActivity({
    required String activityType,
    required FieldSnapshot snapshot,
    double attemptMm = 0,
    double? weeklyTargetMm,
    String? fertilizerName,
    double? rawKg,
    String? pesticideName,
  }) {
    switch (activityType) {
      case ActivityType.watering:
        return checkWatering(
          snapshot: snapshot,
          attemptMm: attemptMm,
          weeklyTargetMm: weeklyTargetMm,
        );
      case ActivityType.fertilizing:
        return checkFertilizing(
          snapshot: snapshot,
          fertilizerName: fertilizerName,
          rawKg: rawKg,
        );
      case ActivityType.spraying:
        return checkSpraying(
          snapshot: snapshot,
          pesticideName: pesticideName,
        );
      default:
        return GuardrailVerdict.ok(
          axis: GuardrailAxis.water,
          attemptedValue: 0,
          projectedTotal: 0,
          limitValue: 0,
          unit: '',
        );
    }
  }
}
