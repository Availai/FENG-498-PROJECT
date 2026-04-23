/// İlk üretim sürümünde tam desteklenen ürünler.
///
/// Diğer bitki verileri repoda kalır; kullanıcıya yeni ekim/rehber/seçim
/// yüzeylerinde yalnız bu üç ürün gösterilir.
library;

class SupportedCrops {
  SupportedCrops._();

  static const visibleNames = <String>[
    'Ayçiçeği',
    'Mısır',
    'Domates',
  ];

  static const _keys = <String>{
    'aycicegi',
    'aycicek',
    'gunebakan',
    'misir',
    'domates',
  };

  static bool isSupported(String? cropName) {
    if (cropName == null || cropName.trim().isEmpty) return false;
    return _keys.contains(normalize(cropName));
  }

  static String? canonicalName(String? cropName) {
    final key = normalize(cropName ?? '');
    if (key == 'aycicegi' || key == 'aycicek' || key == 'gunebakan') {
      return 'Ayçiçeği';
    }
    if (key == 'misir') return 'Mısır';
    if (key == 'domates') return 'Domates';
    return null;
  }

  static String normalize(String input) {
    return input
        .toLowerCase()
        .replaceAll('ı', 'i')
        .replaceAll('İ', 'i')
        .replaceAll('ğ', 'g')
        .replaceAll('ü', 'u')
        .replaceAll('ş', 's')
        .replaceAll('ö', 'o')
        .replaceAll('ç', 'c')
        .replaceAll(RegExp(r'[^a-z0-9]'), '');
  }
}
