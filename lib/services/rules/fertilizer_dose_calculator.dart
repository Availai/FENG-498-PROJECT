import 'crop_rule_set.dart';

/// Ürün × evre için NPK doz tablosu (kg/dekar). Değerler **konservatif
/// aralıkların alt-orta** noktasıdır; çiftçi toprak analizine göre
/// üst sınırı kendi inisiyatifiyle artırabilir.
///
/// Kaynak: TAGEM Bitkisel Üretim Genel Müdürlüğü teknik talimatları,
/// Tarım İl Müdürlüğü çiftçi rehberleri (gözden geçirilmiş, 2022-2024).
class _NpkProfile {
  final double baselineN; // taban / ekim öncesi
  final double topDressN; // üst gübreleme (vejetatif/erken üreme)
  final double phosphorus;
  final double potassium;
  const _NpkProfile({
    required this.baselineN,
    required this.topDressN,
    required this.phosphorus,
    required this.potassium,
  });
}

/// Ürün anahtarı ASCII normalize edilmiş ürün adı:
///   sunflower → 'aycicegi', wheat → 'bugday', corn → 'misir', tomato → 'domates'
const Map<String, _NpkProfile> _profiles = {
  'aycicegi': _NpkProfile(
      baselineN: 6, topDressN: 6, phosphorus: 7, potassium: 6),
  'bugday': _NpkProfile(
      baselineN: 6, topDressN: 8, phosphorus: 6, potassium: 4),
  'misir': _NpkProfile(
      baselineN: 8, topDressN: 12, phosphorus: 8, potassium: 8),
  'domates': _NpkProfile(
      baselineN: 8, topDressN: 14, phosphorus: 10, potassium: 18),
};

/// Hangi evrelerde "üst gübreleme" pencereye girer.
const _topDressStages = {
  'vejetatif',
  'tomurcuklanma',
  'kardeslenme',
  'sapakalkma',
};

/// Bir tarla × ürün × evre için önerilen toplam NPK gübre planı.
///
/// `null` döndüğünde ürün/evre tablo dışında, kural sessizce atlamalıdır.
class FertilizerPlan {
  /// Önerilen toplam azot (kg).
  final double recommendedNkg;
  final double recommendedPkg;
  final double recommendedKkg;

  /// Bu uygulamada verilmesi tavsiye edilen azot kısmı (taban veya üst).
  final double thisApplicationNkg;

  /// "taban" | "ust" — UI ve aktivite metadata'sı için.
  final String splitWindow;

  /// İnsan-okur açıklama (Türkçe).
  final String reasoning;

  const FertilizerPlan({
    required this.recommendedNkg,
    required this.recommendedPkg,
    required this.recommendedKkg,
    required this.thisApplicationNkg,
    required this.splitWindow,
    required this.reasoning,
  });
}

/// Ürün adına ve evreye göre dekar bazında NPK planı hesaplar.
///
/// Girdiler:
///   • [cropName]   — Türkçe veya ASCII; profile lookup için normalize edilir.
///   • [stageKey]   — `vejetatif`, `kardeslenme`, `tomurcuklanma`, ... veya null.
///   • [areaDekar]  — toplam alan (decimal); 0 veya negatifse `null` döner.
///   • [recentFertilizing] — son N gün gübreleme aktiviteleri; pencerede
///     gübreleme yapıldıysa kural çağırıcı tarafından bastırılır (burada
///     sadece doz çıkarılır).
///
/// Saf fonksiyon — IO yok, takvim yok; testlerde elle kurulur.
class FertilizerDoseCalculator {
  FertilizerDoseCalculator._();

  static FertilizerPlan? calculate({
    required String cropName,
    required String? stageKey,
    required double areaDekar,
  }) {
    if (areaDekar <= 0) return null;
    final key = _normalize(cropName);
    final profile = _profiles[key];
    if (profile == null) return null;

    final isTopDress = stageKey != null && _topDressStages.contains(stageKey);
    final splitWindow = isTopDress ? 'ust' : 'taban';
    final thisN = isTopDress ? profile.topDressN : profile.baselineN;

    final totalN =
        (profile.baselineN + profile.topDressN) * areaDekar;
    final totalP = profile.phosphorus * areaDekar;
    final totalK = profile.potassium * areaDekar;
    final thisAppN = thisN * areaDekar;

    final reasoning = isTopDress
        ? '$key için $stageKey evresinde üst gübre ${profile.topDressN.toStringAsFixed(0)} kg N/da; '
            'alan ${areaDekar.toStringAsFixed(2)} da → bu uygulamada ${thisAppN.toStringAsFixed(1)} kg N.'
        : '$key için ekim öncesi taban gübresi ${profile.baselineN.toStringAsFixed(0)} kg N/da + '
            '${profile.phosphorus.toStringAsFixed(0)} kg P/da + ${profile.potassium.toStringAsFixed(0)} kg K/da; '
            'alan ${areaDekar.toStringAsFixed(2)} da → ${thisAppN.toStringAsFixed(1)} kg N + '
            '${totalP.toStringAsFixed(1)} kg P + ${totalK.toStringAsFixed(1)} kg K.';

    return FertilizerPlan(
      recommendedNkg: totalN,
      recommendedPkg: totalP,
      recommendedKkg: totalK,
      thisApplicationNkg: thisAppN,
      splitWindow: splitWindow,
      reasoning: reasoning,
    );
  }

  /// Stage'i bilmiyorsa, `daysSincePlanted`'a göre kabaca tahmin et.
  /// Üst gübreleme genelde 30-60. gün arası — bu aralıkta isTopDress true.
  static FertilizerPlan? calculateFromDays({
    required String cropName,
    required int? daysSincePlanted,
    required double areaDekar,
  }) {
    final stage = daysSincePlanted == null
        ? null
        : (daysSincePlanted >= 30 && daysSincePlanted <= 60
            ? 'vejetatif'
            : null);
    return calculate(
      cropName: cropName,
      stageKey: stage,
      areaDekar: areaDekar,
    );
  }

  /// Aynı ürün için son [withinDays] gün içinde gübreleme yapılmış mı —
  /// kuralın "doz tekrar etmesin" kontrolünde kullanılır. Saf yardımcı.
  static bool fertilizedRecently({
    required List<ActivityRecord> recentActivities,
    required DateTime now,
    required int withinDays,
  }) {
    final cutoff = now.subtract(Duration(days: withinDays));
    for (final a in recentActivities) {
      if (a.type == 'fertilizing' && a.at.isAfter(cutoff)) return true;
    }
    return false;
  }

  static String _normalize(String s) {
    return s
        .toLowerCase()
        .replaceAll('ç', 'c')
        .replaceAll('ğ', 'g')
        .replaceAll('ı', 'i')
        .replaceAll('İ', 'i')
        .replaceAll('ö', 'o')
        .replaceAll('ş', 's')
        .replaceAll('ü', 'u')
        .trim();
  }
}
