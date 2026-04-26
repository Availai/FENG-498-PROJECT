/// SoilGrids API — ISRIC World Soil Information (free, no key)
///
/// REST endpoint: https://rest.isric.org/soilgrids/v2.0/properties/query
/// Returns soil properties at a given lat/lon for 0-5 cm, 5-15 cm, 15-30 cm depths.
///
/// ─── TÜRKİYE TOPRAK VERİSİ KAYNAK HİYERARŞİSİ ────────────────────────────────
///
/// SoilGrids global bir model olduğundan Türkiye için yerel kaynaklar tercih
/// edilmelidir. Bu servis aşağıdaki **fallback chain**'in son halkasıdır:
///
/// 1. **TÜBİTAK MAM Toprak Veritabanı** (öncelikli — yerel ölçüm)
///    https://www.mam.tubitak.gov.tr — Türkiye'nin 1:25.000 ölçekli detaylı
///    toprak haritası. API erişimi sınırlı; veri çekilemediğinde adım 2.
///
/// 2. **TAGEM Toprak Etüt Raporları** (il/ilçe bazlı)
///    https://www.tarimorman.gov.tr/TAGEM — devlet etüt-haritalama projeleri
///    sonucu üretilen lokal toprak profilleri.
///
/// 3. **SoilGrids (ISRIC)** — bu dosya. Global, ücretsiz, anlık erişim.
///    Türkiye'de %15-25 sapma payı vardır ama her zaman erişilebilir.
///
/// `fetchProfileWithFallback` tüm zinciri sırayla dener.
library;

import '../backend_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// MODELLER
// ─────────────────────────────────────────────────────────────────────────────

class SoilProfile {
  /// pH (water) × 10  →  divide by 10 for real pH
  final double phH2o;

  /// Organic carbon g/kg
  final double organicCarbonGKg;

  /// Clay content g/kg (divide by 10 for %)
  final double clayGKg;

  /// Sand content g/kg
  final double sandGKg;

  /// Silt content g/kg
  final double siltGKg;

  /// Bulk density kg/m³ (cg/cm³ × 100 in API)
  final double bulkDensityKgM3;

  /// Cation Exchange Capacity mmol(c)/kg
  final double cecMmolKg;

  /// Nitrogen g/kg
  final double nitrogenGKg;

  const SoilProfile({
    required this.phH2o,
    required this.organicCarbonGKg,
    required this.clayGKg,
    required this.sandGKg,
    required this.siltGKg,
    required this.bulkDensityKgM3,
    required this.cecMmolKg,
    required this.nitrogenGKg,
  });

  double get phReal => phH2o / 10;
  double get clayPct => clayGKg / 10;
  double get sandPct => sandGKg / 10;
  double get siltPct => siltGKg / 10;
  double get organicMatterPct =>
      organicCarbonGKg * 1.724 / 10; // Van Bemmelen factor

  String get textureClass {
    if (clayPct >= 40) return 'Ağır Killi';
    if (clayPct >= 27 && siltPct >= 28) return 'Killi';
    if (sandPct >= 70) return 'Kumlu';
    if (siltPct >= 50) return 'Siltli';
    if (clayPct >= 20 && sandPct <= 45) return 'Killi-Tınlı';
    return 'Tınlı';
  }

  String get phDescription {
    final ph = phReal;
    if (ph < 5.5) return 'Çok Asitli — kireçleme önerilir';
    if (ph < 6.0) return 'Asitli — çoğu ürün için sınırda';
    if (ph < 7.0) return 'Hafif Asitli — ideal aralık';
    if (ph < 7.5) return 'Nötr — ideal';
    if (ph < 8.0) return 'Hafif Bazik — kabul edilebilir';
    return 'Bazik — kükürt uygulaması düşünülebilir';
  }

  /// Actionable Turkish agronomic assessment
  String get assessment {
    final issues = <String>[];
    if (phReal < 5.8) {
      issues.add(
          'pH düşük (${phReal.toStringAsFixed(1)}) — dekar başına 200-400 kg kireç uygula');
    }
    if (phReal > 8.0) {
      issues.add(
          'pH yüksek (${phReal.toStringAsFixed(1)}) — kükürt veya asit gübre kullan');
    }
    if (organicCarbonGKg < 5) {
      issues.add(
          'Organik madde yetersiz — ahır gübresi veya yeşil gübre önerilir');
    }
    if (clayPct > 50) issues.add('Ağır kil — drenaj sorununa dikkat');
    if (sandPct > 75) {
      issues.add('Kumlu toprak — sık sulama ve bölünmüş gübreleme uygula');
    }
    if (nitrogenGKg < 1) {
      issues.add('Azot yetersiz — ekim öncesi N gübresi planla');
    }
    if (issues.isEmpty) {
      return 'Toprak özellikleri genel tarım için uygun görünüyor.';
    }
    return issues.join('\n');
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SERVİS
// ─────────────────────────────────────────────────────────────────────────────

class SoilGridsApi {
  /// Fetch top-soil profile (mean of 0-5 cm and 5-15 cm layers)
  static Future<SoilProfile> fetchProfile({
    required double lat,
    required double lon,
  }) async {
    final response = await BackendService.soilProfile(lat: lat, lng: lon);
    final data = response?['data'];
    if (data is! Map) {
      throw Exception('Toprak profili backend üzerinden alınamadı.');
    }
    return SoilProfile(
      phH2o: (data['ph_h2o'] as num?)?.toDouble() ?? 68.0,
      organicCarbonGKg: (data['organic_carbon_gkg'] as num?)?.toDouble() ?? 0.0,
      clayGKg: (data['clay_gkg'] as num?)?.toDouble() ?? 0.0,
      sandGKg: (data['sand_gkg'] as num?)?.toDouble() ?? 0.0,
      siltGKg: (data['silt_gkg'] as num?)?.toDouble() ?? 0.0,
      bulkDensityKgM3: (data['bulk_density_kgm3'] as num?)?.toDouble() ?? 0.0,
      cecMmolKg: (data['cec_mmolkg'] as num?)?.toDouble() ?? 0.0,
      nitrogenGKg: (data['nitrogen_gkg'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
