/// 5 öncelikli ürün için iki kademeli guardrail limit tablosu.
///
/// **Hiçbir değer uydurulmamıştır** — limitler projedeki mevcut kaynaklı
/// değerlerden türetilir (CLAUDE.md §10, §16, §28):
///
///   • Su (haftalık): `TurkiyeCropGuides.seasonalWaterMm / 18` zaten
///     `FieldStateService._weeklyTargetMm` içinde haftalık hedef olarak
///     kullanılıyor. softMax = hedef × 1.2, hardMax = hedef × 1.8.
///     1.8 katı = FAO-56 toprak su kapasitesini aşıp drenaja/boğulmaya
///     gitme bölgesi (kök bölgesi havasızlığı).
///
///   • Azot (mevsimlik): `fertilizer_dose_calculator` NPK profillerindeki
///     (baselineN + topDressN) toplamı standart tavandır. Toprak analizi
///     **yoksa** §16 gereği kesin tavan konulamaz → `isAdvisoryOnly: true`
///     (motor block üretmez, sadece warn). softMax = standart × 1.15,
///     hardMax = standart × 1.5 (aşırı azot → tuzlanma, çevre, ürün riski).
///
///   • Tuzluluk (EC): FAO-29 eşiği. Lab analizi gelince motor doğrudan
///     ölçülen EC'yi kullanır; burada yalnızca eşik referansı tutulur.
///
/// İlaç REI ekseni ürün bağımsızdır (etken maddeye bağlı) → bu tabloda
/// yer almaz; `PesticideRei.lookup` üzerinden motor içinde çözülür.
library;

import '../../data/supported_crops.dart';
import '../../data/turkiye_crop_guides.dart';
import 'guardrail_limit.dart';

class GuardrailLimitsTable {
  GuardrailLimitsTable._();

  /// Mevsimlik standart azot tavanı (kg/dekar) — NPK doz profillerinden.
  /// `fertilizer_dose_calculator._profiles`: baselineN + topDressN.
  ///   ayçiçeği 6+6=12 · mısır 8+12=20 · domates 8+14=22 · buğday 6+8=14.
  /// Çay/portakal NPK profili yok → genel TAGEM üst aralığı (advisory).
  static const Map<String, double> _seasonalNStandardKgDa = {
    'aycicegi': 12,
    'misir': 20,
    'domates': 22,
    // Çay ve portakal için doz tablosu yok; advisory referans değer.
    'cay': 30,
    'portakal': 24,
  };

  /// Su ekseni limiti — haftalık hedef mm üzerinden iki kademe.
  ///
  /// [weeklyTargetMm] çağıran tarafça `FieldStateService` ile aynı kaynaktan
  /// (TurkiyeCropGuides) verilir; burada yeniden hesaplanmaz ki iki yer
  /// ayrışmasın (§28: Flutter davranışı tek olmalı).
  static GuardrailLimit water({required double weeklyTargetMm}) {
    final target = weeklyTargetMm > 0 ? weeklyTargetMm : 25.0;
    return GuardrailLimit(
      axis: GuardrailAxis.water,
      softMax: target * 1.2,
      hardMax: target * 1.8,
      unit: 'mm/hafta',
      sourceIds: const [
        'source.fao56.soil_water_balance',
        'source.turkiye_crop_guides.seasonal_water',
      ],
    );
  }

  /// Azot ekseni limiti — mevsimlik kg/dekar.
  ///
  /// [hasSoilTest] false ise §16 gereği `isAdvisoryOnly: true` → motor
  /// kesin block üretmez, sadece warn. true ise hardMax devreye girer.
  static GuardrailLimit nitrogen({
    required String cropName,
    required bool hasSoilTest,
  }) {
    final key = SupportedCrops.normalize(cropName);
    final standard = _seasonalNStandardKgDa[key] ?? 20.0;
    return GuardrailLimit(
      axis: GuardrailAxis.nitrogen,
      softMax: standard * 1.15,
      hardMax: standard * 1.5,
      unit: 'kg N/dekar',
      isAdvisoryOnly: !hasSoilTest,
      sourceIds: const [
        'source.tagem.npk_dose_profiles',
        'source.tagem.fertilization_general',
      ],
    );
  }

  /// Tuzluluk (EC) eşiği — dS/m. FAO-29 genel kök bölgesi tolerans referansı.
  /// Lab analizi gelince motor ölçülen EC'yi bu eşikle karşılaştırır.
  static GuardrailLimit salinity() {
    return const GuardrailLimit(
      axis: GuardrailAxis.salinity,
      softMax: 2.0, // dS/m üstü: hassas bitkilerde verim düşüşü başlar
      hardMax: 4.0, // dS/m üstü: çoğu kültür bitkisinde belirgin zarar
      unit: 'dS/m',
      sourceIds: ['source.fao29.salinity_thresholds'],
    );
  }

  /// Bu ürün için su limiti tanımlı mı (5 öncelikli ürün kapsamı)?
  static bool isSupportedCrop(String cropName) =>
      SupportedCrops.isSupported(cropName);

  /// TurkiyeCropGuides sezon suyundan haftalık hedef türet (FieldStateService
  /// ile aynı formül: sezon / 18 hafta). Guide yoksa null → çağıran fallback.
  static double? weeklyTargetFromGuide(String cropName) {
    final guide = TurkiyeCropGuides.lookup(cropName);
    if (guide == null) return null;
    return guide.seasonalWaterMm / 18.0;
  }
}
