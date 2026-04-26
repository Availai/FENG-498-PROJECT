import '../data/crop_protocols.dart';

/// Hava durumu ve sulama koşullarının hasat tarihini nasıl kaydıracağını
/// çiftçi-dostu bir dille tahmin eder. Tamamen deterministik ve çevrimdışı:
/// herhangi bir API çağrısı yapmaz, saf hesap.
///
/// Felsefe: çiftçi "hasat tarihi değişir mi, değişmez mi" değil, koşulların
/// tarihi hangi yönde ittiğini görmek ister. Bu yüzden:
///   - Pozitif `daysShift` → hasat gecikecek (stres/soğuk/kuraklık).
///   - Negatif `daysShift` → hasat hızlanacak (sıcak + bol güneş).
///   - 0 → koşullar baz günleri doğruluyor; hasat tarihi sabit.
class HarvestShiftEstimator {
  const HarvestShiftEstimator._();

  /// [baseHarvestDays] — protokol / veri tabanı kaynaklı varsayılan.
  /// [weeklyRainMm] — son bilinen haftalık yağış (mm).
  /// [idealWeeklyRainMm] — bitkinin haftalık ihtiyacı (varsayılan 25 mm).
  /// [avgTempC] — mevcut dönem ortalama sıcaklığı.
  /// [idealTempC] — bitkinin ideal büyüme sıcaklığı (varsayılan 22).
  /// [cropName] — ad; Ayçiçeği/Mısır/Domates için hassasiyet ayarı.
  static HarvestShiftEstimate estimate({
    required int baseHarvestDays,
    required DateTime plantedDate,
    double? weeklyRainMm,
    double idealWeeklyRainMm = 25.0,
    double? avgTempC,
    double idealTempC = 22.0,
    String? cropName,
  }) {
    final factors = <HarvestShiftFactor>[];
    double shift = 0;

    // ── Su açığı / fazlası ────────────────────────────────────
    if (weeklyRainMm != null) {
      final diff = weeklyRainMm - idealWeeklyRainMm;
      if (diff <= -10) {
        // Ciddi kuraklık — olgunlaşma yavaşlar (stres) veya hızlanır
        // (erken zorunlu olgunlaşma). Prototipte basitçe gecikme
        // varsayıyoruz; çiftçi sulamayı arttırırsa stres kalkar.
        final extra = ((-diff) / 10).clamp(0.5, 5).toDouble();
        shift += extra;
        factors.add(HarvestShiftFactor(
          icon: '💧',
          label: 'Haftalık yağış eksik',
          detail: 'Bu hafta ${weeklyRainMm.toStringAsFixed(0)} mm yağış — '
              'bitkinin ihtiyacı ~${idealWeeklyRainMm.toStringAsFixed(0)} mm. '
              'Sulamayı arttırmazsan olgunlaşma ~${extra.toStringAsFixed(0)} gün gecikir.',
          deltaDays: extra.round(),
        ));
      } else if (diff >= 15) {
        final extra = (diff / 15).clamp(0.5, 3).toDouble();
        shift += extra;
        factors.add(HarvestShiftFactor(
          icon: '🌧️',
          label: 'Aşırı yağış',
          detail:
              'Bu hafta ${weeklyRainMm.toStringAsFixed(0)} mm — ihtiyacın çok üzerinde. '
              'Kök çürüklüğü + mantar riski olgunlaşmayı ~${extra.toStringAsFixed(0)} gün yavaşlatabilir.',
          deltaDays: extra.round(),
        ));
      } else {
        factors.add(const HarvestShiftFactor(
          icon: '✅',
          label: 'Su dengesi iyi',
          detail:
              'Haftalık yağış bitkinin ihtiyacına yakın. Hasat tarihi bu koşulda sabit kalır.',
          deltaDays: 0,
        ));
      }
    }

    // ── Sıcaklık sapması ──────────────────────────────────────
    if (avgTempC != null) {
      final diff = avgTempC - idealTempC;
      if (diff >= 4) {
        // Sıcak — GDD birikimi hızlı, hasat öne gelir.
        final faster = (diff / 2).clamp(1, 6).toDouble();
        shift -= faster;
        factors.add(HarvestShiftFactor(
          icon: '🔥',
          label: 'Ortalama sıcaklık yüksek',
          detail:
              'Ortalama ${avgTempC.toStringAsFixed(0)}°C — ideal ${idealTempC.toStringAsFixed(0)}°C. '
              'Sıcak havada gün-derece (GDD) birikimi hızlı, hasat ~${faster.toStringAsFixed(0)} gün öne gelebilir. '
              'Sulamayı aksatma, kalite düşer.',
          deltaDays: -faster.round(),
        ));
      } else if (diff <= -4) {
        final slower = ((-diff) / 2).clamp(1, 8).toDouble();
        shift += slower;
        factors.add(HarvestShiftFactor(
          icon: '🧊',
          label: 'Ortalama sıcaklık düşük',
          detail:
              'Ortalama ${avgTempC.toStringAsFixed(0)}°C — ideal ${idealTempC.toStringAsFixed(0)}°C. '
              'Soğuk havada büyüme yavaşlar; hasat ~${slower.toStringAsFixed(0)} gün gecikebilir.',
          deltaDays: slower.round(),
        ));
      } else {
        factors.add(const HarvestShiftFactor(
          icon: '🌤️',
          label: 'Sıcaklık dengede',
          detail:
              'Ortalama sıcaklık ideale yakın. Gün-derece birikimi beklentiye uygun ilerliyor.',
          deltaDays: 0,
        ));
      }
    }

    // Toplam kaymayı makul aralığa sınırla — kaotik öneriler üretmeyelim.
    final clampedShift = shift.clamp(-10.0, 15.0);
    final estimatedDate = plantedDate.add(
      Duration(days: baseHarvestDays + clampedShift.round()),
    );

    final summary = _composeSummary(clampedShift.round());

    return HarvestShiftEstimate(
      baseHarvestDate: plantedDate.add(Duration(days: baseHarvestDays)),
      estimatedHarvestDate: estimatedDate,
      daysShift: clampedShift.round(),
      summary: summary,
      factors: factors,
    );
  }

  /// Protokolden yetiştirme aşamalarını timeline verisine dönüştür.
  /// Her aşama için planted + offset = tahmini geçiş günü verilir.
  static List<HarvestTimelineStep> timelineFor({
    required String cropName,
    required DateTime plantedDate,
  }) {
    final protocol = CropProtocols.resolveByName(cropName);
    if (protocol == null) return const [];
    return protocol.steps.map((s) {
      return HarvestTimelineStep(
        order: s.order,
        title: s.title,
        emoji: s.stageEmoji,
        dayOffset: s.dayOffset,
        estimatedDate: plantedDate.add(Duration(days: s.dayOffset)),
        description: s.description,
        criticalWarning: s.criticalWarning,
        farmerTip: s.farmerTip,
      );
    }).toList(growable: false);
  }

  static String _composeSummary(int shift) {
    if (shift == 0) {
      return 'Mevcut hava ve su koşullarında hasat tarihi sabit görünüyor.';
    }
    if (shift > 0) {
      return 'Mevcut koşullar hasadı ~$shift gün geciktirebilir. Sulama + gübrelemeyi takvime sadık tut.';
    }
    final faster = -shift;
    return 'Mevcut koşullar hasadı ~$faster gün öne çekebilir. Olgunlaşma hızlanacağı için hasat döneminde sahayı sık kontrol et.';
  }
}

class HarvestShiftEstimate {
  final DateTime baseHarvestDate;
  final DateTime estimatedHarvestDate;

  /// Pozitif → gecikme; negatif → erken hasat.
  final int daysShift;
  final String summary;
  final List<HarvestShiftFactor> factors;

  const HarvestShiftEstimate({
    required this.baseHarvestDate,
    required this.estimatedHarvestDate,
    required this.daysShift,
    required this.summary,
    required this.factors,
  });
}

class HarvestShiftFactor {
  final String icon;
  final String label;
  final String detail;
  final int deltaDays;

  const HarvestShiftFactor({
    required this.icon,
    required this.label,
    required this.detail,
    required this.deltaDays,
  });
}

class HarvestTimelineStep {
  final int order;
  final String title;
  final String emoji;
  final int dayOffset;
  final DateTime estimatedDate;
  final String description;
  final String? criticalWarning;
  final String? farmerTip;

  const HarvestTimelineStep({
    required this.order,
    required this.title,
    required this.emoji,
    required this.dayOffset,
    required this.estimatedDate,
    required this.description,
    this.criticalWarning,
    this.farmerTip,
  });
}
