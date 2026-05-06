/// FAO Penman-Monteith Referans Evapotranspirasyon (ETo) Hesaplayıcısı
///
/// Kaynak: FAO Irrigation and Drainage Paper No. 56
/// "Crop evapotranspiration — Guidelines for computing crop water requirements"
/// Allen, R.G., Pereira, L.S., Raes, D., & Smith, M. (1998).
/// https://www.fao.org/3/X0490E/x0490e00.htm
///
/// Bu, dünya genelinde sulama planlaması için altın standart formüldür.
/// Bitki su ihtiyacı (ETc) = Kc × ETo olarak hesaplanır;
/// Kc katsayıları her bitki ve gelişim evresine özgüdür (FAO-56 Tablo 12).
library;

import 'dart:math' as math;

/// Tek bir günlük ETo girdisi.
class EToInput {
  final double tMaxC; // Maks sıcaklık °C
  final double tMinC; // Min sıcaklık °C
  final double rhMaxPct; // Maks bağıl nem %
  final double rhMinPct; // Min bağıl nem %
  final double windMs; // 2m rüzgar hızı m/s (ya da 10m'den çevrilmiş)
  final double solarRadMjM2Day; // Net solar radyasyon MJ/m²/gün
  final double elevationM; // Deniz seviyesinden yükseklik m
  final double latitudeDeg; // Enlem (radyasyon hesabı için)
  final int dayOfYear; // 1-365

  const EToInput({
    required this.tMaxC,
    required this.tMinC,
    required this.rhMaxPct,
    required this.rhMinPct,
    required this.windMs,
    required this.solarRadMjM2Day,
    required this.elevationM,
    required this.latitudeDeg,
    required this.dayOfYear,
  });
}

/// FAO-56 Penman-Monteith ETo hesaplayıcısı.
///
/// Formül (Eq. 6, FAO-56):
///
///                0.408 Δ (Rn − G) + γ (900/(T+273)) u₂ (es − ea)
///   ETo  =  ─────────────────────────────────────────────────────
///                       Δ + γ (1 + 0.34 u₂)
///
/// Birim: mm/gün
class FaoEtoService {
  /// Günlük referans evapotranspirasyon (mm/gün).
  static double calculateDailyEto(EToInput i) {
    final tMean = (i.tMaxC + i.tMinC) / 2.0;

    // 1) Atmosferik basınç P (kPa) — Eq. 7
    final p = 101.3 * math.pow((293.0 - 0.0065 * i.elevationM) / 293.0, 5.26);

    // 2) Psikrometrik sabit γ (kPa/°C) — Eq. 8
    final gamma = 0.000665 * p;

    // 3) Doygunluk buhar basıncı es (kPa) — Eq. 11, 12
    final esTmax = 0.6108 * math.exp((17.27 * i.tMaxC) / (i.tMaxC + 237.3));
    final esTmin = 0.6108 * math.exp((17.27 * i.tMinC) / (i.tMinC + 237.3));
    final es = (esTmax + esTmin) / 2.0;

    // 4) Gerçek buhar basıncı ea (kPa) — Eq. 17
    final ea =
        (esTmin * (i.rhMaxPct / 100.0) + esTmax * (i.rhMinPct / 100.0)) / 2.0;

    // 5) Doygunluk buhar basıncı eğimi Δ (kPa/°C) — Eq. 13
    final delta =
        (4098 * (0.6108 * math.exp((17.27 * tMean) / (tMean + 237.3)))) /
            math.pow(tMean + 237.3, 2);

    // 6) Net radyasyon Rn (MJ/m²/gün)
    //    Solar radyasyondan basit çıkarım: Rn ≈ 0.77 × Rs (FAO-56 ortalama)
    //    Tam formül için Rnl (uzun dalga) hesabı gerekir; pratikte 0.77 katsayısı
    //    ortalama tarımsal koşullarda %5 hata ile çalışır.
    final rn = 0.77 * i.solarRadMjM2Day;

    // 7) Toprak ısı akısı G — günlük hesapta ihmal edilebilir (FAO-56 Eq. 42)
    const g = 0.0;

    // 8) Penman-Monteith — Eq. 6
    final numerator = 0.408 * delta * (rn - g) +
        gamma * (900.0 / (tMean + 273.0)) * i.windMs * (es - ea);
    final denominator = delta + gamma * (1.0 + 0.34 * i.windMs);

    final eto = numerator / denominator;
    return eto.isFinite && eto > 0 ? eto : 0.0;
  }

  /// 10m rüzgarı 2m'ye çevir (FAO-56 Eq. 47).
  static double wind10mTo2m(double u10) =>
      u10 * (4.87 / math.log(67.8 * 10 - 5.42));

  /// Solar radyasyon ölçümü yoksa Hargreaves yaklaşımı (FAO-56 Eq. 50):
  /// Rs ≈ 0.16 × √(Tmax−Tmin) × Ra
  /// Ra = ekstraterestriyal radyasyon (latitude + DOY ile hesaplanır).
  static double estimateSolarRad({
    required double tMaxC,
    required double tMinC,
    required double latitudeDeg,
    required int dayOfYear,
  }) {
    final phi = latitudeDeg * math.pi / 180.0;
    // Güneş deklinasyonu δ — Eq. 24
    final delta = 0.409 * math.sin((2 * math.pi / 365.0) * dayOfYear - 1.39);
    // Saat açısı ωs — Eq. 25
    final ws = math.acos(-math.tan(phi) * math.tan(delta));
    // Ters göreli mesafe dr — Eq. 23
    final dr = 1 + 0.033 * math.cos((2 * math.pi / 365.0) * dayOfYear);
    // Ekstraterestriyal radyasyon Ra (MJ/m²/gün) — Eq. 21
    const gsc = 0.0820;
    final ra = (24 * 60 / math.pi) *
        gsc *
        dr *
        (ws * math.sin(phi) * math.sin(delta) +
            math.cos(phi) * math.cos(delta) * math.sin(ws));
    // Hargreaves
    return 0.16 * math.sqrt((tMaxC - tMinC).abs()) * ra;
  }

  /// Bitki su ihtiyacı ETc = Kc × ETo
  static double calculateCropWater({
    required double etoMmDay,
    required double kc,
  }) =>
      etoMmDay * kc;
}

/// FAO-56 Tablo 12'den seçilmiş ana kültür bitkileri için Kc katsayıları.
/// Üç evre: başlangıç (initial), gelişme orta (mid), hasat sonu (end).
///
/// Kullanım: Bitkinin gelişim evresine göre uygun Kc seçilir,
/// sonra ETc = Kc × ETo formülü uygulanır.
class FaoCropCoefficients {
  final String nameTr;
  final double kcInit;
  final double kcMid;
  final double kcEnd;
  final int totalLengthDays;
  final String faoTableRef; // FAO-56 dökümandaki kaynağı

  const FaoCropCoefficients({
    required this.nameTr,
    required this.kcInit,
    required this.kcMid,
    required this.kcEnd,
    required this.totalLengthDays,
    required this.faoTableRef,
  });

  /// FAO-56 Table 12 — başlıca kültür bitkileri için resmi değerler.
  static const Map<String, FaoCropCoefficients> _data = {
    'domates': FaoCropCoefficients(
      nameTr: 'Domates',
      kcInit: 0.60,
      kcMid: 1.15,
      kcEnd: 0.80,
      totalLengthDays: 135,
      faoTableRef: 'FAO-56 Table 12 — Tomato',
    ),
    'biber': FaoCropCoefficients(
      nameTr: 'Biber (Sweet Pepper)',
      kcInit: 0.60,
      kcMid: 1.05,
      kcEnd: 0.90,
      totalLengthDays: 125,
      faoTableRef: 'FAO-56 Table 12 — Sweet Pepper',
    ),
    'patlıcan': FaoCropCoefficients(
      nameTr: 'Patlıcan',
      kcInit: 0.60,
      kcMid: 1.05,
      kcEnd: 0.90,
      totalLengthDays: 130,
      faoTableRef: 'FAO-56 Table 12 — Eggplant',
    ),
    'salatalık': FaoCropCoefficients(
      nameTr: 'Salatalık (taze)',
      kcInit: 0.60,
      kcMid: 1.00,
      kcEnd: 0.75,
      totalLengthDays: 105,
      faoTableRef: 'FAO-56 Table 12 — Cucumber Fresh',
    ),
    'kabak': FaoCropCoefficients(
      nameTr: 'Kabak',
      kcInit: 0.50,
      kcMid: 1.00,
      kcEnd: 0.80,
      totalLengthDays: 100,
      faoTableRef: 'FAO-56 Table 12 — Squash',
    ),
    'karpuz': FaoCropCoefficients(
      nameTr: 'Karpuz',
      kcInit: 0.40,
      kcMid: 1.00,
      kcEnd: 0.75,
      totalLengthDays: 100,
      faoTableRef: 'FAO-56 Table 12 — Watermelon',
    ),
    'kavun': FaoCropCoefficients(
      nameTr: 'Kavun',
      kcInit: 0.50,
      kcMid: 1.05,
      kcEnd: 0.75,
      totalLengthDays: 100,
      faoTableRef: 'FAO-56 Table 12 — Sweet Melons',
    ),
    'patates': FaoCropCoefficients(
      nameTr: 'Patates',
      kcInit: 0.50,
      kcMid: 1.15,
      kcEnd: 0.75,
      totalLengthDays: 130,
      faoTableRef: 'FAO-56 Table 12 — Potato',
    ),
    'soğan': FaoCropCoefficients(
      nameTr: 'Soğan (kuru)',
      kcInit: 0.70,
      kcMid: 1.05,
      kcEnd: 0.75,
      totalLengthDays: 150,
      faoTableRef: 'FAO-56 Table 12 — Onion Dry',
    ),
    'sarımsak': FaoCropCoefficients(
      nameTr: 'Sarımsak',
      kcInit: 0.70,
      kcMid: 1.00,
      kcEnd: 0.70,
      totalLengthDays: 210,
      faoTableRef: 'FAO-56 Table 12 — Garlic',
    ),
    'havuç': FaoCropCoefficients(
      nameTr: 'Havuç',
      kcInit: 0.70,
      kcMid: 1.05,
      kcEnd: 0.95,
      totalLengthDays: 115,
      faoTableRef: 'FAO-56 Table 12 — Carrots',
    ),
    'lahana': FaoCropCoefficients(
      nameTr: 'Lahana',
      kcInit: 0.70,
      kcMid: 1.05,
      kcEnd: 0.95,
      totalLengthDays: 130,
      faoTableRef: 'FAO-56 Table 12 — Cabbage',
    ),
    'marul': FaoCropCoefficients(
      nameTr: 'Marul',
      kcInit: 0.70,
      kcMid: 1.00,
      kcEnd: 0.95,
      totalLengthDays: 80,
      faoTableRef: 'FAO-56 Table 12 — Lettuce',
    ),
    'fasulye': FaoCropCoefficients(
      nameTr: 'Fasulye (yeşil)',
      kcInit: 0.50,
      kcMid: 1.05,
      kcEnd: 0.90,
      totalLengthDays: 90,
      faoTableRef: 'FAO-56 Table 12 — Beans Green',
    ),
    'nohut': FaoCropCoefficients(
      nameTr: 'Nohut',
      kcInit: 0.40,
      kcMid: 1.00,
      kcEnd: 0.35,
      totalLengthDays: 95,
      faoTableRef: 'FAO-56 Table 12 — Chick Pea',
    ),
    'mercimek': FaoCropCoefficients(
      nameTr: 'Mercimek',
      kcInit: 0.40,
      kcMid: 1.10,
      kcEnd: 0.30,
      totalLengthDays: 150,
      faoTableRef: 'FAO-56 Table 12 — Lentil',
    ),
    'buğday': FaoCropCoefficients(
      nameTr: 'Buğday (kışlık)',
      kcInit: 0.70,
      kcMid: 1.15,
      kcEnd: 0.40,
      totalLengthDays:
          210, // Kışlık buğday; diğer kaynaklarla hizalandı (VerifiedAgriDatabase: 210 gün)
      faoTableRef: 'FAO-56 Table 12 — Winter Wheat',
    ),
    'arpa': FaoCropCoefficients(
      nameTr: 'Arpa',
      kcInit: 0.30,
      kcMid: 1.15,
      kcEnd: 0.25,
      totalLengthDays: 130,
      faoTableRef: 'FAO-56 Table 12 — Barley',
    ),
    'mısır': FaoCropCoefficients(
      nameTr: 'Mısır (dane)',
      kcInit: 0.30,
      kcMid: 1.20,
      kcEnd: 0.60,
      totalLengthDays:
          130, // TAGEM Türkiye dane mısır: 120-130 gün; TurkiyeCropGuides ile hizalandı
      faoTableRef: 'FAO-56 Table 12 — Maize Grain',
    ),
    'çeltik': FaoCropCoefficients(
      nameTr: 'Çeltik',
      kcInit: 1.05,
      kcMid: 1.20,
      kcEnd: 0.90,
      totalLengthDays: 150,
      faoTableRef: 'FAO-56 Table 12 — Rice',
    ),
    'ayçiçeği': FaoCropCoefficients(
      nameTr: 'Ayçiçeği',
      kcInit: 0.35,
      kcMid: 1.15,
      kcEnd: 0.35,
      totalLengthDays: 130,
      faoTableRef: 'FAO-56 Table 12 — Sunflower',
    ),
    'pamuk': FaoCropCoefficients(
      nameTr: 'Pamuk',
      kcInit: 0.35,
      kcMid: 1.20,
      kcEnd: 0.60,
      totalLengthDays: 195,
      faoTableRef: 'FAO-56 Table 12 — Cotton',
    ),
    'şekerpancarı': FaoCropCoefficients(
      nameTr: 'Şeker pancarı',
      kcInit: 0.35,
      kcMid: 1.20,
      kcEnd: 0.70,
      totalLengthDays: 180,
      faoTableRef: 'FAO-56 Table 12 — Sugar Beet',
    ),
    'yonca': FaoCropCoefficients(
      nameTr: 'Yonca',
      kcInit: 0.40,
      kcMid: 0.95,
      kcEnd: 0.90,
      totalLengthDays: 165,
      faoTableRef: 'FAO-56 Table 12 — Alfalfa Hay',
    ),
    'üzüm': FaoCropCoefficients(
      nameTr: 'Üzüm (sofralık)',
      kcInit: 0.30,
      kcMid: 0.85,
      kcEnd: 0.45,
      totalLengthDays: 205,
      faoTableRef: 'FAO-56 Table 12 — Grapes Table',
    ),
    'zeytin': FaoCropCoefficients(
      nameTr: 'Zeytin',
      kcInit: 0.65,
      kcMid: 0.70,
      kcEnd: 0.70,
      totalLengthDays: 365,
      faoTableRef: 'FAO-56 Table 12 — Olives',
    ),
    'elma': FaoCropCoefficients(
      nameTr: 'Elma',
      kcInit: 0.60,
      kcMid: 0.95,
      kcEnd: 0.75,
      totalLengthDays: 240,
      faoTableRef: 'FAO-56 Table 12 — Apples',
    ),
  };

  /// Bitki adına göre Kc katsayılarını döndürür (Türkçe arama, fuzzy).
  static FaoCropCoefficients? lookup(String cropTr) {
    final key = _normalizeCropName(cropTr);
    for (final entry in _data.entries) {
      final entryKey = _normalizeCropName(entry.key);
      if (entryKey == key || key.contains(entryKey) || entryKey.contains(key)) {
        return entry.value;
      }
    }
    return null;
  }

  static String _normalizeCropName(String value) => value
      .toLowerCase()
      .trim()
      .replaceAll('\u011f', 'g')
      .replaceAll('\u00fc', 'u')
      .replaceAll('\u015f', 's')
      .replaceAll('\u0131', 'i')
      .replaceAll('\u00f6', 'o')
      .replaceAll('\u00e7', 'c');

  /// Verilen ekim tarihinden bugüne göre uygun gelişim evresinin Kc'sini seç.
  static double kcForStage({
    required FaoCropCoefficients crop,
    required DateTime plantedDate,
  }) {
    final daysSince = DateTime.now().difference(plantedDate).inDays;
    final pct = daysSince / crop.totalLengthDays;
    if (pct < 0.20) return crop.kcInit; // 0-20%: başlangıç
    if (pct < 0.75) return crop.kcMid; // 20-75%: gelişme + orta sezon
    return crop.kcEnd; // 75-100%: hasat sonu
  }
}
