import '../core/rule_engine/rule.dart';
import '../data/rule_packs/corn_rule_pack.dart';
import '../data/rule_packs/crop_registry.dart';
import '../data/rule_packs/orange_rule_pack.dart';
import '../data/rule_packs/sunflower_rule_pack.dart';
import '../data/rule_packs/tea_rule_pack.dart';
import '../data/rule_packs/tomato_rule_pack.dart';

/// Bir ürün için **fact-bağımsız** genel kuralları (suitability +
/// pre_planting + soil_analysis kategorileri) döndürür.
///
/// Bu kayıtlar ana ekrana çıkmaz; ürün ansiklopedisinde "Bu ürün için
/// genel kurallar" başlığı altında okunabilir referans olarak gösterilir.
/// Eşleştirme yok — kullanıcı tüm kuralları kararsız görür ve karar
/// vermeden önce kendi koşullarını değerlendirir.
///
/// CLAUDE.md sec 12-14: rule pack kayıtları kaynak kanıtlı; bu servis
/// onları yalnız listeler, mantığı değiştirmez.
class CropGeneralRules {
  CropGeneralRules._();

  /// "Bilgi notu" sayılan kategoriler — ana ekrandan filtrelenir,
  /// ansiklopediye yönlendirilir.
  static const Set<String> informationalCategories = {
    'suitability',
    'pre_planting',
    'soil_analysis',
  };

  /// Pack builder eşleşmesi. `cropRuleSetsProvider` (app_providers) ile
  /// senkronize tutulmalı; yeni ürün eklenirse buraya da eklenir.
  static final Map<String, List<Rule> Function()> _packBuilders = {
    CropRegistry.sunflower.stableId: SunflowerRulePack.all,
    CropRegistry.corn.stableId: CornRulePack.all,
    CropRegistry.tomato.stableId: TomatoRulePack.all,
    CropRegistry.orange.stableId: OrangeRulePack.all,
    CropRegistry.tea.stableId: TeaRulePack.all,
  };

  /// Türkçe ürün adından genel kuralları bulur.
  /// Pack yoksa boş liste döner — encyclopedia bölümü gizlenir.
  static List<Rule> forCropName(String cropName) {
    final def = CropRegistry.findByName(cropName);
    if (def == null) return const [];
    return forStableId(def.stableId);
  }

  /// Stable ID ile genel kuralları bulur.
  static List<Rule> forStableId(String stableId) {
    final builder = _packBuilders[stableId];
    if (builder == null) return const [];
    final all = builder();
    return all
        .where((r) => r.enabled && informationalCategories.contains(r.category))
        .toList();
  }

  /// Kategori başlıklarını Türkçe label'a çevirir.
  static String categoryLabel(String category) {
    return switch (category) {
      'suitability' => 'Uygunluk',
      'pre_planting' => 'Ekim Öncesi',
      'soil_analysis' => 'Toprak Analizi',
      _ => category,
    };
  }
}
