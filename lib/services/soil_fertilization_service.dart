/// Modül 6 — Detaylı Toprak Analizi & Gübreleme.
///
/// `SoilProfile` (SoilGrids) üstüne bina edilmiş hesaplama katmanı.
/// SoilGrids fosfor (P) ve potasyum (K) yayınlamaz; bu nedenle Türkiye
/// TAGEM ortalamalarına dayalı bir tahmin yapılır (toprak dokusu + organik
/// madde temelli). Kireçleme/kükürtleme için Adams-Evans / Shoemaker
/// yaklaşımının basitleştirilmiş hali kullanılır.
library;

import 'api/soilgrids_api.dart';

/// NPK düzeyi (kg/dekar saf besin maddesi cinsinden tahmin).
enum NutrientLevel { dusuk, orta, yuksek }

class NpkEstimate {
  final double nitrogenKgDekar; // saf N kg/dekar
  final double phosphorusKgDekar; // saf P₂O₅ kg/dekar
  final double potassiumKgDekar; // saf K₂O kg/dekar
  final NutrientLevel nLevel;
  final NutrientLevel pLevel;
  final NutrientLevel kLevel;

  const NpkEstimate({
    required this.nitrogenKgDekar,
    required this.phosphorusKgDekar,
    required this.potassiumKgDekar,
    required this.nLevel,
    required this.pLevel,
    required this.kLevel,
  });

  String get nLabel => _label(nLevel);
  String get pLabel => _label(pLevel);
  String get kLabel => _label(kLevel);

  static String _label(NutrientLevel l) {
    switch (l) {
      case NutrientLevel.dusuk:
        return 'Düşük';
      case NutrientLevel.orta:
        return 'Orta';
      case NutrientLevel.yuksek:
        return 'Yüksek';
    }
  }
}

/// Bitki için dönemsel gübreleme tavsiyesi.
class FertilizationStep {
  final String period; // "Ekim Öncesi", "Çiçeklenme" vb.
  final String fertilizer; // "20-20-0" "Üre" "DAP" vb.
  final double doseKgDekar;
  final String note;
  const FertilizationStep({
    required this.period,
    required this.fertilizer,
    required this.doseKgDekar,
    required this.note,
  });
}

/// pH değiştirme hesabı sonucu.
class AmendmentResult {
  final String materialName; // "Tarım kireci" / "Toz kükürt"
  final double doseKgDekar;
  final String application; // uygulama yöntemi açıklaması
  const AmendmentResult({
    required this.materialName,
    required this.doseKgDekar,
    required this.application,
  });
}

class SoilFertilizationService {
  SoilFertilizationService._();

  // ───────────────────────────────────────────────────────────────────
  // 1. NPK TAHMİNİ
  // SoilGrids yalnız N verir. P/K tahmini doku + organik madde tabanlı.
  // Tahminler TAGEM Türkiye toprak ortalamalarına yakındır; gerçek değer
  // için laboratuvar analizi şarttır.
  // ───────────────────────────────────────────────────────────────────

  static NpkEstimate estimateNpk(SoilProfile profile) {
    // N: SoilGrids nitrogen (g/kg) → kg/dekar saf N tahmini
    // 1 dekar × 20 cm × 1.4 g/cm³ ≈ 280 ton toprak; N (g/kg) × 0.28 = kg N/dekar
    final nKg = profile.nitrogenGKg * 0.28;

    // P: organik madde + kil yüzdesi tabanlı (P, kile bağlanır, OM ile döner)
    final om = profile.organicMatterPct;
    final clay = profile.clayPct;
    final pKg = (om * 0.8 + clay * 0.05).clamp(2.0, 18.0);

    // K: CEC (katyon değişim kapasitesi) ile orantılı
    final kKg = (profile.cecMmolKg * 0.06).clamp(5.0, 30.0);

    return NpkEstimate(
      nitrogenKgDekar: nKg,
      phosphorusKgDekar: pKg,
      potassiumKgDekar: kKg,
      nLevel: _classify(nKg, low: 1.5, high: 4.0),
      pLevel: _classify(pKg, low: 4.0, high: 10.0),
      kLevel: _classify(kKg, low: 10.0, high: 20.0),
    );
  }

  static NutrientLevel _classify(double value,
      {required double low, required double high}) {
    if (value < low) return NutrientLevel.dusuk;
    if (value > high) return NutrientLevel.yuksek;
    return NutrientLevel.orta;
  }

  // ───────────────────────────────────────────────────────────────────
  // 2. KİREÇLEME / KÜKÜRTLEME HESAPLAYICISI
  // Hedef pH ile mevcut pH arasındaki farka göre kg/dekar saf madde.
  // Adams-Evans basitleştirmesi: ΔpH × CEC tampon faktörü.
  // ───────────────────────────────────────────────────────────────────

  static AmendmentResult? amendmentFor({
    required SoilProfile profile,
    required double targetPh,
  }) {
    final current = profile.phReal;
    final delta = targetPh - current;

    // 0.2 pH'lık fark anlamsız sayılır
    if (delta.abs() < 0.2) return null;

    // Doku tampon faktörü — kil ne kadar yüksekse o kadar fazla madde gerek
    final clay = profile.clayPct;
    double bufferFactor;
    if (clay < 15) {
      bufferFactor = 0.8; // kumlu
    } else if (clay < 30) {
      bufferFactor = 1.0; // tınlı
    } else if (clay < 45) {
      bufferFactor = 1.3; // killi-tınlı
    } else {
      bufferFactor = 1.6; // ağır killi
    }

    if (delta > 0) {
      // pH yükseltme — tarım kireci (CaCO₃) gerekli
      // Yaklaşık: 1 birim pH artışı için 200–400 kg/dekar (doku ile orantılı)
      final dose = (delta * 250 * bufferFactor).clamp(50.0, 800.0);
      return AmendmentResult(
        materialName: 'Tarım Kireci (CaCO₃)',
        doseKgDekar: dose,
        application:
            'Sonbaharda ekim öncesi tüm yüzeye serpilir, 15–20 cm derinliğe '
            'pulluk veya diskaroyla karıştırılır. Etkisi 6–12 ay içinde görülür.',
      );
    } else {
      // pH düşürme — toz kükürt gerekli
      // Yaklaşık: 1 birim pH düşüşü için 50–150 kg/dekar
      final dose = (delta.abs() * 80 * bufferFactor).clamp(20.0, 400.0);
      return AmendmentResult(
        materialName: 'Toz Kükürt (S)',
        doseKgDekar: dose,
        application:
            'İlkbahar başında yüzeye serpilir, hafif çapayla karıştırılır. '
            'Sulamayı izleyen mikroorganizmalar 2–3 ayda asitlendirir.',
      );
    }
  }

  // ───────────────────────────────────────────────────────────────────
  // 3. BİTKİ BAZLI GÜBRELEME TAKVİMİ
  // Bitki tipine göre dönemsel NPK programı.
  // ───────────────────────────────────────────────────────────────────

  static List<FertilizationStep> fertilizationPlan(String cropName) {
    final n = cropName.toLowerCase();

    // Tahıllar (buğday, arpa, çavdar, yulaf)
    if (n.contains('buğday') ||
        n.contains('arpa') ||
        n.contains('çavdar') ||
        n.contains('yulaf')) {
      return const [
        FertilizationStep(
          period: 'Ekim Öncesi (Sonbahar)',
          fertilizer: '20-20-0 (DAP veya kompoze)',
          doseKgDekar: 20,
          note: 'Tohumla birlikte veya tohum bandının altına verilir. '
              'Fosfor kök gelişimi için kritik.',
        ),
        FertilizationStep(
          period: 'Kardeşlenme (Şubat–Mart)',
          fertilizer: 'Üre (%46 N) veya Amonyum Sülfat',
          doseKgDekar: 15,
          note: 'Yaprak gelişimini hızlandırır. Nemli toprağa serpilir.',
        ),
        FertilizationStep(
          period: 'Sapa Kalkma (Mart–Nisan)',
          fertilizer: 'Üre veya CAN (%26 N)',
          doseKgDekar: 12,
          note: 'Başak verimi için ikinci azot dozu. Yağıştan önce verin.',
        ),
      ];
    }

    // Mısır
    if (n.contains('mısır')) {
      return const [
        FertilizationStep(
          period: 'Ekim Öncesi',
          fertilizer: '15-15-15 NPK',
          doseKgDekar: 30,
          note: 'Toprağa karıştırılarak.',
        ),
        FertilizationStep(
          period: '4–6 Yapraklı Dönem',
          fertilizer: 'Üre',
          doseKgDekar: 18,
          note: 'Sıra arasına serpilip toprağa karıştırılır.',
        ),
        FertilizationStep(
          period: 'Tepe Püskülü',
          fertilizer: 'Üre',
          doseKgDekar: 15,
          note: 'Koçan oluşumunu desteklemek için son azot dozu.',
        ),
      ];
    }

    // Domates / biber / patlıcan / sebze
    if (n.contains('domates') ||
        n.contains('biber') ||
        n.contains('patlıcan') ||
        n.contains('salatalık')) {
      return const [
        FertilizationStep(
          period: 'Dikim Öncesi',
          fertilizer: '15-15-15 + Yanmış Çiftlik Gübresi',
          doseKgDekar: 25,
          note: 'Çiftlik gübresi 1–2 ton/dekar; kompoze 25 kg/dekar.',
        ),
        FertilizationStep(
          period: 'Vejetatif Büyüme',
          fertilizer: 'Üre veya Amonyum Nitrat',
          doseKgDekar: 8,
          note: 'Damla sulamadan haftalık verilir (fertigasyon).',
        ),
        FertilizationStep(
          period: 'Çiçeklenme',
          fertilizer: 'Mono Potasyum Fosfat (MKP)',
          doseKgDekar: 6,
          note: 'Çiçek tutmayı artırır. Damla sulamadan.',
        ),
        FertilizationStep(
          period: 'Meyve Bağlama & Hasat',
          fertilizer: 'Potasyum Nitrat',
          doseKgDekar: 10,
          note: 'Meyve iriliği ve şeker oranını yükseltir.',
        ),
      ];
    }

    // Meyve ağaçları (zeytin, elma, üzüm vb.)
    if (n.contains('zeytin') ||
        n.contains('elma') ||
        n.contains('armut') ||
        n.contains('üzüm') ||
        n.contains('kayısı') ||
        n.contains('kiraz')) {
      return const [
        FertilizationStep(
          period: 'Kış Sonu (Şubat)',
          fertilizer: 'Yanmış Çiftlik Gübresi',
          doseKgDekar: 1500,
          note: 'Ağaç başına 20–40 kg, taç izdüşümüne saçılarak.',
        ),
        FertilizationStep(
          period: 'Sürgün Verme (Mart–Nisan)',
          fertilizer: '20-20-0 veya Amonyum Sülfat',
          doseKgDekar: 25,
          note: 'Taç izdüşümüne çepeçevre serpilip 5–10 cm karıştırılır.',
        ),
        FertilizationStep(
          period: 'Meyve Tutma (Mayıs–Haziran)',
          fertilizer: 'Potasyum Sülfat',
          doseKgDekar: 15,
          note: 'Meyve iriliği için. Damla sulama varsa fertigasyon.',
        ),
        FertilizationStep(
          period: 'Hasat Sonrası (Sonbahar)',
          fertilizer: 'Yaprak Gübresi (mikro)',
          doseKgDekar: 2,
          note: 'Çinko, bor, demir takviyesi yaprağa püskürtülür.',
        ),
      ];
    }

    // Kök bitkileri
    if (n.contains('havuç') ||
        n.contains('soğan') ||
        n.contains('patates') ||
        n.contains('turp') ||
        n.contains('pancar')) {
      return const [
        FertilizationStep(
          period: 'Ekim Öncesi',
          fertilizer: '15-15-15',
          doseKgDekar: 30,
          note: 'Tüm yüzeye serpilip toprağa karıştırılır.',
        ),
        FertilizationStep(
          period: 'Kök Şişme Başlangıcı',
          fertilizer: 'Potasyum Sülfat',
          doseKgDekar: 12,
          note: 'Sıra üstüne band uygulaması.',
        ),
        FertilizationStep(
          period: 'Olgunlaşma',
          fertilizer: 'Üre (sınırlı)',
          doseKgDekar: 5,
          note: 'Aşırı azot kök şeklini bozar; ölçülü verin.',
        ),
      ];
    }

    // Genel sebze / varsayılan
    return const [
      FertilizationStep(
        period: 'Ekim Öncesi',
        fertilizer: '15-15-15 + Çiftlik Gübresi',
        doseKgDekar: 25,
        note: 'Genel amaçlı dengeli başlangıç.',
      ),
      FertilizationStep(
        period: 'Vejetatif Dönem',
        fertilizer: 'Üre',
        doseKgDekar: 8,
        note: 'Yaprak ve gövde gelişimi için azot.',
      ),
      FertilizationStep(
        period: 'Verim Dönemi',
        fertilizer: 'Potasyum Sülfat',
        doseKgDekar: 8,
        note: 'Ürün kalitesini artırır.',
      ),
    ];
  }

  // ───────────────────────────────────────────────────────────────────
  // 4. TOPRAK TİPİ → UYGUN BİTKİLER
  // ───────────────────────────────────────────────────────────────────

  static String suitableCropsForTexture(String texture) {
    switch (texture) {
      case 'Ağır Killi':
        return 'Çeltik, buğday, ayçiçeği, fasulye, yonca. '
            'Drenaj zayıfsa pancar/havuç sakıncalı.';
      case 'Killi':
        return 'Buğday, mısır, pamuk, soya, yonca, ayçiçeği.';
      case 'Killi-Tınlı':
        return 'Hemen her bitki uygun: tahıl, sebze, meyve, baklagil. '
            'Tarım için en ideal doku.';
      case 'Tınlı':
        return 'Sebze, meyve, tahıl, baklagil — geniş yelpaze.';
      case 'Siltli':
        return 'Mısır, sebze, kavun-karpuz, çilek. Sıkışmaya dikkat.';
      case 'Kumlu':
        return 'Havuç, turp, soğan, patates, kavun, karpuz, yer fıstığı. '
            'Sık sulama ve organik madde takviyesi şart.';
      default:
        return 'Çoğu bitki için uygundur.';
    }
  }
}
