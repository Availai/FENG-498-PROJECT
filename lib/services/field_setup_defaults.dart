/// Modül — Tarla Kurulum Varsayılanları (türetici).
///
/// Bir tarlaya yeni bitki dikilirken, çiftçinin **tekrar girmek zorunda
/// kalmaması** için tarladan zaten bilinen bilgileri çıkarır:
///   • Toprak türü ← en son laboratuvar toprak analizinin doku/bünye sınıfı.
///   • Sulama yöntemi ← tarlanın son sulama/ekim aktivitesindeki yöntem.
///
/// Tasarım ilkeleri (CLAUDE.md §0, §6, §29):
///   • Saf fonksiyon — IO yok, ağ yok, rastgelelik yok. Aynı girdi → aynı çıktı.
///   • Uydurma YOK: kaynak veride karşılık yoksa `null` döner; çağıran taraf
///     form varsayılanına düşer.
///   • Türetilen değer kullanıcıya **ön-seçili öneri** olarak sunulur;
///     kullanıcı her zaman değiştirebilir (form alanları gizlenmez).
library;

import '../data/app_database.dart';
import '../data/crop_protocols.dart';

/// Bir alanın hangi kaynaktan türetildiğini işaretler — UI "şu kaynaktan
/// alındı" notu gösterir. Dahili enum (İngilizce), kullanıcıya görünmez.
enum FieldDefaultSource { soilTest, activity, none }

/// Tarladan türetilen kurulum önerileri. Alan `null` ise türetilemedi.
class FieldSetupDefaults {
  final SoilType? soilType;
  final FieldDefaultSource soilSource;

  final IrrigationMethod? irrigationMethod;
  final FieldDefaultSource irrigationSource;

  const FieldSetupDefaults({
    this.soilType,
    this.soilSource = FieldDefaultSource.none,
    this.irrigationMethod,
    this.irrigationSource = FieldDefaultSource.none,
  });

  bool get hasAny => soilType != null || irrigationMethod != null;
}

class FieldSetupDefaultsBuilder {
  FieldSetupDefaultsBuilder._();

  /// [soilTests]: tarlanın toprak analizleri (yeni → eski sıralı beklenir).
  /// [activityLog]: tarlanın aktivite kayıtları (yeni → eski sıralı beklenir);
  /// her kayıt `watchActivityLog` map biçimindedir (`type`, `metadata`).
  static FieldSetupDefaults build({
    required List<SoilTest> soilTests,
    required List<Map<String, dynamic>> activityLog,
  }) {
    final soil = _soilTypeFromTests(soilTests);
    final irrigation = _irrigationFromActivity(activityLog);

    return FieldSetupDefaults(
      soilType: soil,
      soilSource:
          soil == null ? FieldDefaultSource.none : FieldDefaultSource.soilTest,
      irrigationMethod: irrigation,
      irrigationSource: irrigation == null
          ? FieldDefaultSource.none
          : FieldDefaultSource.activity,
    );
  }

  // ── Toprak türü ← lab analizi doku sınıfı ───────────────────────────────

  /// En son (ilk) analizde doku/bünye sınıfı varsa SoilType'a eşler.
  static SoilType? _soilTypeFromTests(List<SoilTest> tests) {
    for (final t in tests) {
      final st = mapTexture(t.textureClass);
      if (st != null) return st;
    }
    return null;
  }

  /// SoilTestAdvisor doku etiketleri (Kumlu/Tınlı/Killi-Tınlı/Killi/Ağır Killi)
  /// → form SoilType. Volkanik toprak lab dokusundan türetilemez (jeolojik
  /// köken bilgisi gerekir) → null bırakılır, uydurma yapılmaz.
  static SoilType? mapTexture(String? texture) {
    if (texture == null) return null;
    final t = texture.toLowerCase().trim();
    if (t.isEmpty) return null;
    if (t.contains('kum')) return SoilType.sandy;
    // Killi, Killi-Tınlı, Ağır Killi → clay
    if (t.contains('kil')) return SoilType.clay;
    if (t.contains('tın') || t.contains('tin')) return SoilType.loamy;
    if (t.contains('volkan')) return SoilType.volcanic;
    return null;
  }

  // ── Sulama yöntemi ← son aktivite metadatası ────────────────────────────

  /// Aktivite kayıtlarında (yeni → eski) ilk bulunan `irrigation_method`
  /// metadatasını IrrigationMethod'a eşler. Sulama ve ekim kayıtları taşır.
  static IrrigationMethod? _irrigationFromActivity(
      List<Map<String, dynamic>> log) {
    for (final entry in log) {
      final meta = entry['metadata'];
      if (meta is! Map) continue;
      final raw = meta['irrigation_method'] ?? meta['application_method'];
      final m = mapIrrigation(raw?.toString());
      if (m != null) return m;
    }
    return null;
  }

  /// CalendarEvents metadatasındaki yöntem anahtarı → IrrigationMethod.
  static IrrigationMethod? mapIrrigation(String? raw) {
    switch (raw?.toLowerCase().trim()) {
      case 'drip':
        return IrrigationMethod.drip;
      case 'furrow':
        return IrrigationMethod.furrow;
      case 'sprinkler':
        return IrrigationMethod.sprinkler;
      case 'hand':
        return IrrigationMethod.hand;
      default:
        return null;
    }
  }
}
