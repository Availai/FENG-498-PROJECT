/// Modül — Toprak Analizi → Sulama Kararı (deterministik).
///
/// Laboratuvar toprak analizi değerlerini (doku/doygunluk, tuzluluk, organik
/// madde) sulama kararlarına bağlar. `GrowthEngine.soilBaselineStressFrom` ve
/// `SoilTestAdvisor` ile aynı tasarım ilkeleri (CLAUDE.md §16, §22, §29):
///   • Saf fonksiyon — IO yok, ağ yok, rastgelelik yok. Aynı girdi → aynı çıktı.
///   • Uydurma yok: değer girilmemişse (null) o eksen sulamayı **etkilemez**;
///     tüm girdiler null ise [SoilIrrigationProfile.neutral] döner → davranış
///     birebir korunur.
///   • Yorum/eşikler yayınlanmış kaynaklara dayanır (her notta kaynak etiketi):
///       - FAO-56 (Allen ve ark. 1998): dokuya göre kullanılabilir su, sulama
///         sıklığı/dozu mantığı.
///       - FAO-29 Ayers & Westcot (1985): tuzlulukta yıkama (leaching) suyu.
///       - TAGEM Toprak-Gübre-Su: tuzluluk/drenaj yönetimi (mevcut
///         `SoilTestAdvisor` kaynağıyla hizalı).
library;

import '../data/crop_protocols.dart' show SoilType;
import 'field_setup_defaults.dart';
import 'soil_test_advisor.dart' show SoilSeverity, SoilTestAdvisor;

/// Tek bir sulama rehberi maddesi (Türkçe açıklama + kaynak).
class SoilIrrigationNote {
  /// Kısa başlık, ör. 'Sulama sıklığı', 'Tuzluluk — yıkama suyu'.
  final String title;

  /// Çiftçi diliyle açıklama (Türkçe).
  final String message;

  /// Bu yorumun dayandığı kaynak etiketi.
  final String source;

  final SoilSeverity severity;

  const SoilIrrigationNote({
    required this.title,
    required this.message,
    required this.source,
    this.severity = SoilSeverity.info,
  });
}

/// `SoilIrrigationAdvisor.analyze` çıktısı — sulama motoruna verilecek çarpanlar
/// + kullanıcıya gösterilecek açıklamalar.
class SoilIrrigationProfile {
  /// Doku/doygunluktan türetilen toprak tipi (null = türetilemedi).
  final SoilType? soilType;

  /// Doku etiketi (ör. 'Kumlu', 'Killi-Tınlı'); UI için. null = bilinmiyor.
  final String? textureLabel;

  /// Sulama aralığı çarpanı (FAO-56). <1 = daha sık (kumlu), >1 = daha seyrek
  /// (killi). Nötr = 1.0.
  final double intervalFactor;

  /// Tuzluluk yıkama fraksiyonu (FAO-29). 0.0 = yıkama gerekmez.
  final double leachingFraction;

  /// Brüt su çarpanı = 1 / (1 − leachingFraction). Nötr = 1.0.
  final double grossWaterMultiplier;

  /// Tarla su kapasitesi çarpanı (organik madde su tutmayı artırır). Nötr = 1.0.
  final double fieldCapacityMultiplier;

  /// Kullanıcıya gösterilecek açıklamalar (önem sırasına göre).
  final List<SoilIrrigationNote> notes;

  /// En az bir ölçülen değer sulamayı etkiledi mi.
  final bool hasInput;

  const SoilIrrigationProfile({
    this.soilType,
    this.textureLabel,
    this.intervalFactor = 1.0,
    this.leachingFraction = 0.0,
    this.grossWaterMultiplier = 1.0,
    this.fieldCapacityMultiplier = 1.0,
    this.notes = const [],
    this.hasInput = false,
  });

  /// Hiçbir lab değeri yoksa: sulamayı etkilemeyen nötr profil.
  static const neutral = SoilIrrigationProfile();

  /// Yıkama suyu yüzdesi (kullanıcıya gösterim için, ör. 25).
  int get leachingPercent => (leachingFraction * 100).round();
}

class SoilIrrigationAdvisor {
  SoilIrrigationAdvisor._();

  static const String _kFao56 =
      'FAO-56 Bitki Su Tüketimi (Allen ve ark., 1998)';
  static const String _kFao29 =
      'FAO-29 Sulama Suyu Kalitesi (Ayers & Westcot, 1985)';
  static const String _kTagem =
      'TAGEM / Toprak Gübre ve Su Kaynakları — tuzluluk ve drenaj yönetimi';

  /// Lab değerlerini deterministik olarak sulama profiline çevirir.
  ///
  /// - [saturationPct]: suyla doygunluk % (doku türetmek için).
  /// - [textureClass]: doğrudan girilen doku sınıfı (varsa doygunluğa öncelikli).
  /// - [ecDsM]: elektriksel iletkenlik (dS/m) — tuzluluk (öncelikli).
  /// - [saltPct]: % toplam tuz — EC yoksa tuzluluk kaynağı.
  /// - [organicMatterPct]: organik madde % — su tutma düzeltmesi.
  static SoilIrrigationProfile analyze({
    double? saturationPct,
    String? textureClass,
    double? ecDsM,
    double? saltPct,
    double? organicMatterPct,
  }) {
    final hasAny = saturationPct != null ||
        (textureClass != null && textureClass.trim().isNotEmpty) ||
        ecDsM != null ||
        saltPct != null ||
        organicMatterPct != null;
    if (!hasAny) return SoilIrrigationProfile.neutral;

    final notes = <SoilIrrigationNote>[];

    // ── Doku → sulama sıklığı / dozu ────────────────────────────────────────
    final textureLabel =
        (textureClass != null && textureClass.trim().isNotEmpty)
            ? textureClass.trim()
            : SoilTestAdvisor.textureFromSaturation(saturationPct);
    final soilType = FieldSetupDefaultsBuilder.mapTexture(textureLabel);
    final intervalFactor = _intervalFactor(soilType);
    if (soilType != null && textureLabel != null) {
      notes.add(SoilIrrigationNote(
        title: 'Sulama sıklığı ve dozu',
        message: _textureMessage(soilType, textureLabel),
        source: _kFao56,
      ));
    }

    // ── Tuzluluk → yıkama (leaching) suyu ───────────────────────────────────
    final leaching = _leachingFraction(ecDsM: ecDsM, saltPct: saltPct);
    final grossMul = leaching > 0 ? 1.0 / (1.0 - leaching) : 1.0;
    if (leaching > 0) {
      final extraPct = ((grossMul - 1.0) * 100).round();
      final sev =
          leaching >= 0.3 ? SoilSeverity.critical : SoilSeverity.warning;
      notes.add(SoilIrrigationNote(
        title: 'Tuzluluk — yıkama suyu',
        message:
            'Toprak tuzlu. Kök bölgesindeki tuzu derine yıkamak için her sulamada '
            'yaklaşık %$extraPct (yıkama fraksiyonu ~%${(leaching * 100).round()}) '
            'fazla su verin ve drenajın açık olmasına dikkat edin. Tuz indeksi '
            'yüksek gübrelerden ve aşırı azottan kaçının.',
        source: _kFao29,
        severity: sev,
      ));
      if (leaching >= 0.3) {
        notes.add(const SoilIrrigationNote(
          title: 'Tuzluluk — drenaj uyarısı',
          message:
              'Tuzluluk çok yüksek. Drenaj yetersizse aşırı sulama tuzu yüzeyde '
              'biriktirip durumu kötüleştirebilir. Önce tarla drenajını iyileştirin; '
              'gerekiyorsa tuza dayanıklı ürün/çeşit tercih edin.',
          source: _kTagem,
          severity: SoilSeverity.critical,
        ));
      }
    }

    // ── Organik madde → su tutma ─────────────────────────────────────────────
    final fcMul = _fieldCapacityMultiplier(organicMatterPct);
    if (organicMatterPct != null) {
      if (organicMatterPct < 2.0) {
        notes.add(const SoilIrrigationNote(
          title: 'Organik madde — su tutma',
          message:
              'Organik madde düşük; toprak suyu daha az tutar ve daha çabuk kurur. '
              'Sulamayı biraz daha sık ve ölçülü yapın; yanmış ahır gübresi/kompost '
              'ile organik maddeyi artırmak su tutmayı iyileştirir.',
          source: _kFao56,
          severity: SoilSeverity.info,
        ));
      } else if (organicMatterPct >= 3.0) {
        notes.add(const SoilIrrigationNote(
          title: 'Organik madde — su tutma',
          message:
              'Organik madde iyi düzeyde; toprak suyu daha iyi tutar. Sulama '
              'aralığını biraz uzatabilir, her seferinde yeterli derinliğe su '
              'verebilirsiniz.',
          source: _kFao56,
          severity: SoilSeverity.ideal,
        ));
      }
    }

    return SoilIrrigationProfile(
      soilType: soilType,
      textureLabel: textureLabel,
      intervalFactor: intervalFactor,
      leachingFraction: leaching,
      grossWaterMultiplier: grossMul,
      fieldCapacityMultiplier: fcMul,
      notes: notes,
      hasInput: true,
    );
  }

  /// Drift `SoilTest` benzeri bir kayıttan profil üretir (kolaylık sarmalayıcı).
  /// Alanlar nullable double/string olduğu sürece tip bağımsızdır.
  static SoilIrrigationProfile fromValues({
    double? saturationPct,
    String? textureClass,
    double? ecDsM,
    double? saltPct,
    double? organicMatterPct,
  }) =>
      analyze(
        saturationPct: saturationPct,
        textureClass: textureClass,
        ecDsM: ecDsM,
        saltPct: saltPct,
        organicMatterPct: organicMatterPct,
      );

  // ── Eşik tabloları ────────────────────────────────────────────────────────

  /// Dokuya göre sulama aralığı çarpanı. Kumlu su tutmaz → daha sık; killi
  /// tutar → daha seyrek (FAO-56 kullanılabilir su mantığı).
  static double _intervalFactor(SoilType? soil) {
    switch (soil) {
      case SoilType.sandy:
        return 0.7;
      case SoilType.loamy:
        return 1.0;
      case SoilType.clay:
        return 1.3;
      case SoilType.volcanic:
        return 1.05;
      case null:
        return 1.0;
    }
  }

  static String _textureMessage(SoilType soil, String textureLabel) {
    switch (soil) {
      case SoilType.sandy:
        return '$textureLabel toprak suyu az tutar ve çabuk kurur: daha SIK ama her '
            'seferinde DAHA AZ su verin (kısa aralık). Derine giden su israf olur.';
      case SoilType.clay:
        return '$textureLabel toprak suyu uzun süre tutar: DAHA SEYREK ama her '
            'seferinde DAHA BOL su verin. Sık az sulama yüzeyde göllenme/sıkışma yapar.';
      case SoilType.volcanic:
        return '$textureLabel toprak suyu iyi tutar: dengeli aralıkla, kök '
            'derinliğine yetecek kadar su verin.';
      case SoilType.loamy:
        return '$textureLabel toprak su tutma açısından dengelidir: orta aralıkla, '
            'kök bölgesini ıslatacak kadar su verin.';
    }
  }

  /// Tuzluluktan yıkama fraksiyonu. EC öncelikli; yoksa % toplam tuz.
  /// Eşikler `SoilTestAdvisor` tuzluluk sınıflarıyla hizalı (TAGEM/USDA).
  static double _leachingFraction({double? ecDsM, double? saltPct}) {
    if (ecDsM != null) {
      if (ecDsM < 2) return 0.0; // tuzsuz
      if (ecDsM < 4) return 0.10; // çok hafif tuzlu
      if (ecDsM < 8) return 0.20; // orta tuzlu
      if (ecDsM <= 15) return 0.30; // kuvvetli tuzlu
      return 0.40; // çok kuvvetli tuzlu
    }
    if (saltPct != null) {
      if (saltPct < 0.15) return 0.0; // tuzsuz
      if (saltPct < 0.35) return 0.10; // hafif tuzlu
      if (saltPct <= 0.65) return 0.20; // orta tuzlu
      return 0.35; // çok tuzlu
    }
    return 0.0;
  }

  /// Organik maddeye göre tarla su kapasitesi çarpanı. OM su tutmayı artırır;
  /// çok düşükse efektif kullanılabilir su biraz azalır (yapı zayıf). Konservatif.
  static double _fieldCapacityMultiplier(double? organicMatterPct) {
    final om = organicMatterPct;
    if (om == null) return 1.0;
    if (om < 1.0) return 0.95;
    if (om < 2.0) return 1.0;
    if (om < 3.0) return 1.03;
    if (om <= 4.0) return 1.06;
    return 1.10;
  }
}
