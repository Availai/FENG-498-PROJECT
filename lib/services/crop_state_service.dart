import 'dart:math' as math;

import '../data/crop_lifecycle.dart';
import 'growth_engine.dart';

/// 5 ana ürünün (CLAUDE.md sec 11) yaşam döngüsü ve % state hesabı.
///
/// Bu servis 3 ayrı moda göre hesap yapar:
///
///  1. **Tek yıllık (annual)** — domates, mısır, ayçiçeği, buğday:
///     Tek sezonluk döngü. % = (ekimden geçen gün / hasada kadar gün) × 100.
///     Sezon sonu 100 olur, sonraki yıl yeniden başlar.
///
///  2. **Çok yıllık fidan (perennial seedling)** — yeni dikilmiş portakal/çay:
///     Fidan → ilk ekonomik hasat olgunluğu. % = (dikimden gün / hedef gün) × 100.
///     Hedef: portakalda ~1095 gün (3 yıl), çayda ~1280 gün (3.5 yıl).
///     %100'e ulaştığında "olgun" moduna geçer.
///
///  3. **Çok yıllık olgun (perennial mature)** — verim çağındaki portakal/çay:
///     Yıllık döngü içinde mevsim ilerlemesi.
///     Portakalda: Şubat (uyanma) → Kasım-Nisan hasat penceresi içinde.
///     Çayda: Mart (sürgün başı) → Mayıs-Ekim 3 sürgün.
///     % her yıl 0'a düşer ve mevsime göre yeniden artar.
///
/// Mevcut [GrowthEngine] desteklenen ürünler için (ayçiçeği vb.) GDD-tabanlı
/// hesap zaten yapıyor; bu servis o yolu öncelikli olarak kullanır,
/// olmadığında deterministik fallback uygular.
enum CropLifecycleMode {
  /// Tek yıllık bitki — ekimden hasata tek döngü.
  annual,

  /// Çok yıllık + yeni fidan — olgunluğa erişme süreci.
  perennialSeedling,

  /// Çok yıllık + olgun — yıllık döngü içinde mevsim ilerlemesi.
  perennialMature,
}

/// 5 ana ürün için CLAUDE.md sec 11 stable_id eşlemesi.
const Map<String, String> _knownCropStableIds = {
  'ayçiçeği': 'crop.sunflower',
  'aycicegi': 'crop.sunflower',
  'mısır': 'crop.corn',
  'misir': 'crop.corn',
  'domates': 'crop.tomato',
  'portakal': 'crop.orange',
  'çay': 'crop.tea',
  'cay': 'crop.tea',
};

/// Çok yıllık ürün stable ID'leri.
const Set<String> _perennialStableIds = {
  'crop.orange',
  'crop.tea',
};

/// Çok yıllık fidanın olgun moduna geçtiği günler.
/// Portakal: aşılı fidandan ilk ticari hasat ~3 yıl (1095 gün).
/// Çay: fidandan ilk yaş yaprak hasadı ~3.5 yıl (1280 gün).
const Map<String, int> _seedlingToMatureDays = {
  'crop.orange': 1095,
  'crop.tea': 1280,
};

/// Olgun çok yıllıkların yıllık döngü içinde hasat ay aralığı.
/// Portakal: Kasım-Nisan (yılbaşı sarmalayan); döngü başı Şubat.
/// Çay: Mayıs-Ekim 3 sürgün; döngü başı Mart.
const Map<String, _AnnualCycle> _matureAnnualCycles = {
  'crop.orange': _AnnualCycle(cycleStartMonth: 2, harvestStartMonth: 11),
  'crop.tea': _AnnualCycle(cycleStartMonth: 3, harvestStartMonth: 5),
};

class _AnnualCycle {
  /// Döngünün yılda başladığı ay (1-12). Bu aya kadar % = 0.
  final int cycleStartMonth;

  /// Hasat penceresinin başladığı ay. Bu noktada % ≈ 80-90.
  final int harvestStartMonth;

  const _AnnualCycle({
    required this.cycleStartMonth,
    required this.harvestStartMonth,
  });
}

class CropStateService {
  CropStateService._();

  /// Bir bitki kaydı için yaşam döngüsü modunu belirler.
  ///
  /// - [cropName]: serbest format Türkçe ad (büyük/küçük, diakritik fark etmez)
  /// - [isSeedling]: kullanıcının "fidan olarak diktim" işareti (sadece çok yıllıkta anlamlı)
  /// - [plantedDate]: dikim/ekim tarihi — null ise mode tahmininde yardımcı
  ///
  /// Çok yıllık üründe `isSeedling=true` ise → `perennialSeedling`.
  /// `isSeedling=false` ise → `perennialMature` (olgun ağaç olarak ekilmiş).
  /// `isSeedling=null` ise dikim tarihi referans alınır: 3+ yıl önce → mature.
  static CropLifecycleMode modeFor({
    required String cropName,
    bool? isSeedling,
    DateTime? plantedDate,
    DateTime? now,
  }) {
    final stableId = _stableIdFor(cropName);
    final isPerennial = stableId != null && _perennialStableIds.contains(stableId);

    if (!isPerennial) {
      // Tek yıllık ürün — domates, mısır, ayçiçeği vb.
      return CropLifecycleMode.annual;
    }

    // Çok yıllık ürün: kullanıcı işareti birinci kaynak.
    if (isSeedling == true) return CropLifecycleMode.perennialSeedling;
    if (isSeedling == false) return CropLifecycleMode.perennialMature;

    // İşaret yok — dikim tarihinden tahmin et.
    if (plantedDate != null) {
      final ref = now ?? DateTime.now();
      final ageInDays = ref.difference(plantedDate).inDays;
      // isPerennial=true → stableId zaten _perennialStableIds'de, non-null.
      final maturityDays = _seedlingToMatureDays[stableId] ?? 1095;
      if (ageInDays >= maturityDays) {
        return CropLifecycleMode.perennialMature;
      }
      return CropLifecycleMode.perennialSeedling;
    }

    // Hiç bilgi yok — varsayılan: çiftçi olgun ağaç dikiyor (en yaygın senaryo).
    return CropLifecycleMode.perennialMature;
  }

  /// 0-100 arası state yüzdesi. Mod'a göre üç farklı hesap.
  ///
  /// - [accumulatedGdd]: GrowthEngine sağlıyorsa daha doğru bir hesap için kullanılır.
  /// - [harvestDays]: seed_plants.json'dan gelen "ekim → hasat" gün sayısı.
  static double percentFor({
    required String cropName,
    required CropLifecycleMode mode,
    DateTime? plantedDate,
    int? harvestDays,
    double? accumulatedGdd,
    DateTime? now,
  }) {
    final ref = now ?? DateTime.now();

    switch (mode) {
      case CropLifecycleMode.annual:
        return _annualPercent(
          cropName: cropName,
          plantedDate: plantedDate,
          harvestDays: harvestDays,
          accumulatedGdd: accumulatedGdd,
          now: ref,
        );

      case CropLifecycleMode.perennialSeedling:
        return _seedlingPercent(
          cropName: cropName,
          plantedDate: plantedDate,
          now: ref,
        );

      case CropLifecycleMode.perennialMature:
        return _matureAnnualPercent(
          cropName: cropName,
          now: ref,
        );
    }
  }

  /// UI'da gösterilecek disclaimer metni. Mod'a göre değişir.
  ///
  /// Tek yıllık: 'Bu yılki sezon ilerlemesi'
  /// Fidan: 'Yeni fidan — ilk hasada ~X gün kaldı'
  /// Olgun: 'Bu yılki mevsim ilerlemesi · Sonraki hasat: ...'
  static String disclaimerFor({
    required String cropName,
    required CropLifecycleMode mode,
    DateTime? plantedDate,
    DateTime? now,
  }) {
    final ref = now ?? DateTime.now();

    switch (mode) {
      case CropLifecycleMode.annual:
        return 'Tek yıllık bitki — bu sezonun ekim → hasat döngüsü';

      case CropLifecycleMode.perennialSeedling:
        final stableId = _stableIdFor(cropName);
        final targetDays = stableId != null
            ? (_seedlingToMatureDays[stableId] ?? 1095)
            : 1095;
        if (plantedDate == null) {
          return 'Yeni fidan — ilk ekonomik hasat ~${(targetDays / 365).toStringAsFixed(1)} yıl sonra';
        }
        final ageInDays = ref.difference(plantedDate).inDays;
        final remaining = targetDays - ageInDays;
        if (remaining <= 0) {
          return 'Fidan olgunluğa ulaştı — bu sezon ilk ekonomik hasat olabilir';
        }
        final remainingYears = remaining / 365;
        if (remainingYears >= 1.0) {
          return 'Yeni fidan — ilk ekonomik hasata ~${remainingYears.toStringAsFixed(1)} yıl';
        }
        return 'Fidan olgunlaşıyor — ilk ekonomik hasata yaklaşık $remaining gün';

      case CropLifecycleMode.perennialMature:
        final stableId = _stableIdFor(cropName);
        if (stableId == 'crop.orange') {
          return 'Olgun ağaç — yıllık döngü (hasat: Kasım-Nisan)';
        }
        if (stableId == 'crop.tea') {
          return 'Olgun çay bahçesi — 3 sürgün/yıl (Mayıs-Ekim)';
        }
        return 'Olgun çok yıllık bitki — yıllık döngü';
    }
  }

  /// Tavsiye filtresinde kullanılır: fidan dönemindeki çok yıllık ürünlerde
  /// hasat/sürgün önerileri gizlenir (henüz uygulanabilir değil).
  static bool shouldSuppressHarvestAdvice({
    required CropLifecycleMode mode,
    required DateTime? plantedDate,
    String? cropName,
    DateTime? now,
  }) {
    if (mode != CropLifecycleMode.perennialSeedling) return false;
    if (plantedDate == null) return true;
    final ref = now ?? DateTime.now();
    final ageInDays = ref.difference(plantedDate).inDays;
    final stableId = cropName != null ? _stableIdFor(cropName) : null;
    final targetDays = stableId != null
        ? (_seedlingToMatureDays[stableId] ?? 1095)
        : 1095;
    return ageInDays < targetDays;
  }

  // ─── Internal ──────────────────────────────────────────────────────

  static String? _stableIdFor(String cropName) {
    final key = cropName.trim().toLowerCase();
    if (_knownCropStableIds.containsKey(key)) {
      return _knownCropStableIds[key];
    }
    // 5 ana ürünün dışındakiler — direkt match yoksa null.
    return null;
  }

  static double _annualPercent({
    required String cropName,
    required DateTime? plantedDate,
    required int? harvestDays,
    required double? accumulatedGdd,
    required DateTime now,
  }) {
    // GrowthEngine destekliyorsa GDD-temelli daha doğru.
    if (accumulatedGdd != null) {
      final stableId = _stableIdFor(cropName);
      final key = _engineKeyFromStableId(stableId);
      if (key != null && GrowthEngine.isSupported(key)) {
        return (GrowthEngine.overallProgressFor(key, accumulatedGdd) * 100)
            .clamp(0.0, 100.0);
      }
    }
    // Fallback: dikim tarihinden geçen / harvest_days.
    if (plantedDate == null || harvestDays == null || harvestDays <= 0) {
      return 0.0;
    }
    final elapsed = now.difference(plantedDate).inDays;
    return ((elapsed / harvestDays) * 100).clamp(0.0, 100.0);
  }

  static double _seedlingPercent({
    required String cropName,
    required DateTime? plantedDate,
    required DateTime now,
  }) {
    if (plantedDate == null) return 0.0;
    final stableId = _stableIdFor(cropName);
    final targetDays = stableId != null
        ? (_seedlingToMatureDays[stableId] ?? 1095)
        : 1095;
    final ageInDays = now.difference(plantedDate).inDays;
    return ((ageInDays / targetDays) * 100).clamp(0.0, 100.0);
  }

  /// Olgun çok yıllıkta yıllık döngü içinde % hesabı.
  /// Mart-Şubat (çay) veya Şubat-Ocak (portakal) yıl döngüsünü 0-100'e map'ler.
  static double _matureAnnualPercent({
    required String cropName,
    required DateTime now,
  }) {
    final stableId = _stableIdFor(cropName);
    if (stableId == null || !_matureAnnualCycles.containsKey(stableId)) {
      return 0.0;
    }
    final cycle = _matureAnnualCycles[stableId]!;

    // Döngü içindeki konum: cycleStartMonth'tan bu yana geçen gün sayısı.
    DateTime cycleStart = DateTime(now.year, cycle.cycleStartMonth, 1);
    if (cycleStart.isAfter(now)) {
      // Henüz bu yılki döngü başlamadı → önceki yıldan say.
      cycleStart = DateTime(now.year - 1, cycle.cycleStartMonth, 1);
    }
    final daysIntoCycle = now.difference(cycleStart).inDays;
    final cycleLength = 365;
    return ((daysIntoCycle / cycleLength) * 100).clamp(0.0, 100.0);
  }

  /// stable_id → GrowthEngine cropKey eşlemesi.
  static String? _engineKeyFromStableId(String? stableId) {
    return switch (stableId) {
      'crop.sunflower' => 'aycicegi',
      'crop.corn' => 'misir',
      'crop.tomato' => 'domates',
      _ => null,
    };
  }
}

/// `crop_lifecycle.dart` ile çapraz uyum: aynı 5 ürün için tutarlı tip.
CropCycleType cycleTypeFromMode(CropLifecycleMode mode) {
  return mode == CropLifecycleMode.annual
      ? CropCycleType.annual
      : CropCycleType.perennial;
}

/// Test için: olgun moda geçiş eşiği — örnek/test verisi.
@Deprecated('Sadece test/diagnostik için; production üretmez.')
int seedlingMatureThresholdDaysFor(String stableId) {
  return _seedlingToMatureDays[stableId] ?? 1095;
}

/// Unused-helper hatasını önler.
// ignore: unused_element
double _clampForCompile(double v) => math.max(0.0, math.min(100.0, v));
