import '../../core/rule_engine/rule.dart';

/// CLAUDE.md sec 13 — Source metadata kayıtları için stabil ID rejistri.
///
/// **Önemli:** Bu dosyadaki her ID, ileride `assets/data/agri_sources.json`
/// üzerinden ayrıntılı kayıt (yayın yılı, URL, kurum, retrieved_at)
/// alacaktır. Şu an evidence kayıtları `missing_information` olarak
/// işaretlenir; bir kural production'a alınmadan önce gerçek kaynak
/// yüklenmelidir.
///
/// CLAUDE.md sec 10 öncelik sırası:
///   1. Tarım ve Orman Bakanlığı / TAGEM
///   2. Bakanlığa bağlı araştırma enstitüleri
///   3. ÇAYKUR / TEPGE
///   4. Üniversite ziraat fakültesi yayınları
///   5. Ziraat odası / kamu eğitim notları
class SourceIds {
  SourceIds._();

  // Ayçiçeği
  static const sunflowerIpm = 'source.tagem.sunflower_integrated_management';
  static const sunflowerAgronomy = 'source.tagem.sunflower_agronomy_guide';
  static const sunflowerOrobanche = 'source.tagem.sunflower_orobanche';
  static const sunflowerTrakya = 'source.trakya_agri_research.sunflower';

  // Mısır
  static const cornIpm = 'source.tagem.corn_integrated_management';
  static const cornAgronomy = 'source.tagem.corn_agronomy_guide';
  static const cornGap = 'source.gap_agri_research.corn';

  // Domates
  static const tomatoOpenFieldIpm = 'source.tagem.tomato_open_field_ipm';
  static const tomatoGreenhouseIpm = 'source.tagem.tomato_greenhouse_ipm';
  static const tomatoAgronomy = 'source.tagem.tomato_agronomy_guide';

  // Portakal / Narenciye
  static const orangeIpm = 'source.tagem.citrus_integrated_management';
  static const orangeAgronomy = 'source.tagem.citrus_agronomy_guide';
  static const citrusFrostProtection = 'source.tagem.citrus_frost_protection';

  // Çay
  static const teaIpm = 'source.caykur.tea_integrated_management';
  static const teaAgronomy = 'source.caykur.tea_agronomy_guide';
  static const teaPruning = 'source.caykur.tea_pruning_protocol';

  // Genel
  static const soilFertilizerGeneral = 'source.tagem.soil_and_fertilizer_general';
  static const meteorologyMgm = 'source.mgm.weather_forecast_warning';
  static const bkuRegistry = 'source.bku.plant_protection_product_registry';
}

/// Henüz kaynak doğrulanmamış evidence kayıtları için işaret.
/// `validate-rule-pack` skill bu listeyi `missing_information`'a yazar.
const missingEvidence = <RuleEvidence>[];

/// Pending-source evidence: kaynak ID'si var ama tam metin/sayfa henüz
/// çekilmemiş. Üretim öncesi mutlaka `evidence_text` doldurulmalıdır.
List<RuleEvidence> pendingEvidence(String sourceId, [String note = '']) =>
    [
      RuleEvidence(
        sourceId: sourceId,
        evidenceText: note.isEmpty
            ? 'Kaynak referansı: bu kural $sourceId kaynağından beklenir, tam metin extraction skill ile doldurulacak.'
            : note,
      ),
    ];
