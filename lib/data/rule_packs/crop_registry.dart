/// CLAUDE.md sec 11 — Stable crop ID registry.
///
/// Bu dosya bir ürünün **kararlı kimliğini** (`stable_id`), kullanıcı
/// arayüzünde gözüken Türkçe adlarını (`aliases`) ve display label'ını
/// tek noktada tutar.
///
/// ## Yeni ürün ekleme (3 adımdan ibaret)
///
/// 1. Bu dosyaya `CropDefinition` ekleyin:
///    ```dart
///    static const corn = CropDefinition(
///      stableId: 'crop.corn',
///      aliases: {'misir', 'corn', 'maize'},
///      displayName: 'Mısır',
///    );
///    ```
/// 2. `lib/data/rule_packs/[crop]_rule_pack.dart` oluşturup `static
///    `List<Rule> all() => [...]` döndüren bir pack yazın.
/// 3. `lib/services/app_providers.dart` içindeki `cropRuleSetsProvider`
///    listesine tek satır ekleyin:
///    ```dart
///    DeclarativeCropRuleSet(
///      definition: CropRegistry.corn,
///      packBuilder: CornRulePack.all,
///    ),
///    ```
///
/// Hepsi bu. Adapter, fact override, region akışı, ledger ve UI bağlantısı
/// otomatik çalışır.
class CropDefinition {
  /// CLAUDE.md sec 11 — küçük harf, Türkçe karakter yok, nokta ile ayrılı.
  final String stableId;

  /// `CropRuleSet.matches()` bu kümeyle Türkçe normalize sonrası alt-string
  /// eşleştirme yapar. Tüm değerler küçük harf + diakritiksiz.
  final Set<String> aliases;

  /// UI'da görünen Türkçe ad (loglara da geçer).
  final String displayName;

  const CropDefinition({
    required this.stableId,
    required this.aliases,
    required this.displayName,
  });
}

/// CLAUDE.md sec 11 öncelikli ürünler — 5 bitki.
class CropRegistry {
  CropRegistry._();

  static const sunflower = CropDefinition(
    stableId: 'crop.sunflower',
    aliases: {'aycicek', 'aycicegi', 'sunflower'},
    displayName: 'Ayçiçeği',
  );

  static const corn = CropDefinition(
    stableId: 'crop.corn',
    aliases: {'misir', 'corn', 'maize'},
    displayName: 'Mısır',
  );

  static const tomato = CropDefinition(
    stableId: 'crop.tomato',
    aliases: {'domates', 'tomato'},
    displayName: 'Domates',
  );

  static const orange = CropDefinition(
    stableId: 'crop.orange',
    aliases: {'portakal', 'orange', 'citrus'},
    displayName: 'Portakal',
  );

  static const tea = CropDefinition(
    stableId: 'crop.tea',
    aliases: {'cay', 'tea'},
    displayName: 'Çay',
  );

  /// Şu an aktif olan tüm tanımlar — `findByName` döner.
  static const all = <CropDefinition>[
    sunflower,
    corn,
    tomato,
    orange,
    tea,
  ];

  /// Ürün adından `CropDefinition` bul. CLAUDE.md `CropRuleSet._normalize`
  /// ile aynı normalize kuralları (lowercase + TR karakterleri ASCII).
  static CropDefinition? findByName(String name) {
    final n = _normalize(name);
    for (final def in all) {
      for (final a in def.aliases) {
        if (n.contains(a)) return def;
      }
    }
    return null;
  }

  static String _normalize(String s) => s
      .toLowerCase()
      .replaceAll('ç', 'c')
      .replaceAll('ğ', 'g')
      .replaceAll('ı', 'i')
      .replaceAll('İ', 'i')
      .replaceAll('ö', 'o')
      .replaceAll('ş', 's')
      .replaceAll('ü', 'u');
}
