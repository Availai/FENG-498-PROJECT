/// Aşırı girdi (su / azot / tuzluluk / ilaç REI) için deterministik yargıç.
///
/// CLAUDE.md §22: saf fonksiyon kümesi — IO yok, takvim yok, UI yok.
/// Aynı girdi → aynı [GuardrailVerdict]. Bu motor **karar üretmez**, yalnızca
/// "bu girdi fazla mı?" sorusuna iki kademeli (warn/block) cevap verir.
/// Doz/plan hâlâ mevcut servislerden gelir (FAO-56, NPK doz); bu motor onları
/// yalnızca **okuyup yargılar** (§29: deterministik karar destek sistemi).
library;

import 'guardrail_limit.dart';
import 'guardrail_limits_table.dart';

class IntakeGuardrailEngine {
  IntakeGuardrailEngine._();

  /// İki kademeli eşik değerlendirmesi — tüm eksenler bunu paylaşır.
  ///
  /// [projectedTotal] mevcut birikim + bu girdi. [limit] eksene özgü tablodan.
  /// `isAdvisoryOnly` ise hardMax aşımı bile yalnızca [GuardrailLevel.warn]
  /// üretir (§16: toprak analizi yokken kesin block yok).
  static GuardrailLevel _levelFor({
    required double projectedTotal,
    required GuardrailLimit limit,
  }) {
    if (projectedTotal > limit.hardMax) {
      return limit.isAdvisoryOnly ? GuardrailLevel.warn : GuardrailLevel.block;
    }
    if (projectedTotal > limit.softMax) return GuardrailLevel.warn;
    return GuardrailLevel.ok;
  }

  // ── SU ──────────────────────────────────────────────────────────────
  /// Bu hafta zaten verilen su ([currentWeeklyMm]) + planlanan kayıt
  /// ([attemptMm]) haftalık hedefi/kapasiteyi aşıyor mu?
  ///
  /// [weeklyTargetMm] çağıran tarafça `FieldStateService` kaynağıyla aynı
  /// değerden verilir; eşik tablosu bunu iki kademeye çevirir.
  static GuardrailVerdict checkWater({
    required double currentWeeklyMm,
    required double attemptMm,
    required double weeklyTargetMm,
  }) {
    final limit = GuardrailLimitsTable.water(weeklyTargetMm: weeklyTargetMm);
    final projected = currentWeeklyMm + attemptMm;
    final level = _levelFor(projectedTotal: projected, limit: limit);

    if (level == GuardrailLevel.ok) {
      return GuardrailVerdict.ok(
        axis: GuardrailAxis.water,
        attemptedValue: attemptMm,
        projectedTotal: projected,
        limitValue: limit.hardMax,
        unit: limit.unit,
        sourceIds: limit.sourceIds,
      );
    }

    final pct =
        weeklyTargetMm > 0 ? (projected / weeklyTargetMm * 100).round() : null;
    final isBlock = level == GuardrailLevel.block;
    final limitValue = isBlock ? limit.hardMax : limit.softMax;

    return GuardrailVerdict(
      axis: GuardrailAxis.water,
      level: level,
      attemptedValue: attemptMm,
      projectedTotal: projected,
      limitValue: limitValue,
      unit: limit.unit,
      reasonTr: isBlock
          ? 'Bu hafta su miktarı haftalık ihtiyacın '
              '${pct != null ? "%$pct" : "çok"} üzerine çıkıyor — '
              'kök bölgesi havasız kalabilir, besinler yıkanır.'
          : 'Bu hafta su miktarı haftalık ihtiyacın '
              '${pct != null ? "%$pct" : "üst"} seviyesine ulaşıyor.',
      recommendationTr: isBlock
          ? 'Bir sonraki sulamayı erteleyin; toprak nemini kontrol edin.'
          : 'Toprak hâlâ nemliyse bu sulamayı atlamayı düşünün.',
      sourceIds: limit.sourceIds,
    );
  }

  // ── AZOT ────────────────────────────────────────────────────────────
  /// Mevsimlik toplam azot kontrolü (kg N/dekar bazında).
  ///
  /// [seasonalNkgDa] sezon boyunca şimdiye dek verilen N; [attemptNkgDa] bu
  /// uygulamanın N'i. [hasSoilTest] false ise §16 gereği yalnızca warn
  /// üretilir (kesin tavan koyulamaz).
  static GuardrailVerdict checkNitrogen({
    required String cropName,
    required double seasonalNkgDa,
    required double attemptNkgDa,
    required bool hasSoilTest,
  }) {
    final limit = GuardrailLimitsTable.nitrogen(
      cropName: cropName,
      hasSoilTest: hasSoilTest,
    );
    final projected = seasonalNkgDa + attemptNkgDa;
    final level = _levelFor(projectedTotal: projected, limit: limit);

    if (level == GuardrailLevel.ok) {
      return GuardrailVerdict.ok(
        axis: GuardrailAxis.nitrogen,
        attemptedValue: attemptNkgDa,
        projectedTotal: projected,
        limitValue: limit.hardMax,
        unit: limit.unit,
        sourceIds: limit.sourceIds,
      );
    }

    final isBlock = level == GuardrailLevel.block;
    final limitValue = isBlock ? limit.hardMax : limit.softMax;
    // §16: analiz yoksa "kesin tavan" dili kullanma — daha temkinli ifade.
    final advisorySuffix = limit.isAdvisoryOnly
        ? ' Kesin miktar için toprak analizi gerekir.'
        : '';

    return GuardrailVerdict(
      axis: GuardrailAxis.nitrogen,
      level: level,
      attemptedValue: attemptNkgDa,
      projectedTotal: projected,
      limitValue: limitValue,
      unit: limit.unit,
      reasonTr: isBlock
          ? 'Mevsimlik azot ${projected.toStringAsFixed(1)} kg/da — '
              'önerilen üst sınır ${limitValue.toStringAsFixed(1)} kg/da aşılıyor; '
              'aşırı azot tuzlanma ve çevre riski yaratır.$advisorySuffix'
          : 'Mevsimlik azot ${projected.toStringAsFixed(1)} kg/da seviyesine '
              'ulaşıyor — önerilen aralığın üzerine çıkmak üzeresiniz.$advisorySuffix',
      recommendationTr: isBlock
          ? 'Bu gübrelemeyi azaltın veya erteleyin; toprak analizi yaptırın.'
          : 'Dozu düşürmeyi veya bir sonraki döneme bölmeyi düşünün.',
      sourceIds: limit.sourceIds,
    );
  }

  // ── TUZLULUK (EC) ───────────────────────────────────────────────────
  /// Lab analizinden ölçülen EC + (varsa) gübre/yıkama etkisi tuzluluk
  /// eşiğini aşıyor mu? Bu eksen yalnızca **ölçülen** EC olduğunda anlamlı;
  /// [measuredEcDsM] null ise [GuardrailVerdict.ok] (sessiz) döner.
  static GuardrailVerdict checkSalinity({required double? measuredEcDsM}) {
    final limit = GuardrailLimitsTable.salinity();
    final ec = measuredEcDsM ?? 0;
    if (measuredEcDsM == null) {
      return GuardrailVerdict.ok(
        axis: GuardrailAxis.salinity,
        attemptedValue: 0,
        projectedTotal: 0,
        limitValue: limit.hardMax,
        unit: limit.unit,
        sourceIds: limit.sourceIds,
      );
    }
    final level = _levelFor(projectedTotal: ec, limit: limit);
    if (level == GuardrailLevel.ok) {
      return GuardrailVerdict.ok(
        axis: GuardrailAxis.salinity,
        attemptedValue: ec,
        projectedTotal: ec,
        limitValue: limit.hardMax,
        unit: limit.unit,
        sourceIds: limit.sourceIds,
      );
    }
    final isBlock = level == GuardrailLevel.block;
    return GuardrailVerdict(
      axis: GuardrailAxis.salinity,
      level: level,
      attemptedValue: ec,
      projectedTotal: ec,
      limitValue: isBlock ? limit.hardMax : limit.softMax,
      unit: limit.unit,
      reasonTr: isBlock
          ? 'Toprak tuzluluğu ${ec.toStringAsFixed(1)} dS/m — yüksek; '
              'gübre eklemek tuz stresini artırır.'
          : 'Toprak tuzluluğu ${ec.toStringAsFixed(1)} dS/m — sınırda; '
              'hassas bitkilerde verim düşebilir.',
      recommendationTr: isBlock
          ? 'Gübreyi azaltın; yıkama sulaması ve drenajı değerlendirin.'
          : 'Tuza dayanıklı çeşit ve dengeli sulamayı düşünün.',
      sourceIds: limit.sourceIds,
    );
  }

  // ── İLAÇ (REI) ──────────────────────────────────────────────────────
  /// Son ilaçlamadan bu yana geçen süre, etken maddenin REI penceresinden
  /// kısa mı? Penceredeyse sahaya girme/yeni ilaçlama riskli (§17 BKÜ).
  ///
  /// [hoursSinceLastSpray] son ilaçlamadan geçen saat; [reiHours]
  /// `PesticideRei.lookup` ile çözülen değer. Kayıt yoksa [hoursSinceLastSpray]
  /// null → ok.
  static GuardrailVerdict checkPesticideReentry({
    required double? hoursSinceLastSpray,
    required int reiHours,
  }) {
    if (hoursSinceLastSpray == null || hoursSinceLastSpray >= reiHours) {
      return GuardrailVerdict.ok(
        axis: GuardrailAxis.pesticideReentry,
        attemptedValue: hoursSinceLastSpray ?? 0,
        projectedTotal: hoursSinceLastSpray ?? 0,
        limitValue: reiHours.toDouble(),
        unit: 'saat',
        sourceIds: const ['source.bku.reentry_interval'],
      );
    }
    final remaining = (reiHours - hoursSinceLastSpray).ceil();
    return GuardrailVerdict(
      axis: GuardrailAxis.pesticideReentry,
      level: GuardrailLevel.block,
      attemptedValue: hoursSinceLastSpray,
      projectedTotal: hoursSinceLastSpray,
      limitValue: reiHours.toDouble(),
      unit: 'saat',
      reasonTr: 'Son ilaçlamadan bu yana güvenli bekleme süresi (REI) '
          'henüz dolmadı — yaklaşık $remaining saat daha var.',
      recommendationTr: 'Sahaya girişi ve yeni ilaçlamayı erteleyin. '
          'Güncel ruhsat, doz ve hasada bekleme süresi için bku.tarim.gov.tr '
          'kontrol edin.',
      sourceIds: const ['source.bku.reentry_interval'],
    );
  }
}
