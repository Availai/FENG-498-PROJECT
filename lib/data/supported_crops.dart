library;

class SupportedCrops {
  SupportedCrops._();

  static const visibleNames = <String>[
    'Ayçiçeği',
    'Mısır',
    'Domates',
    'Portakal',
    'Çay',
  ];

  static const _keyToCanonical = <String, String>{
    'aycicegi': 'Ayçiçeği',
    'aycicek': 'Ayçiçeği',
    'gunebakan': 'Ayçiçeği',
    'misir': 'Mısır',
    'domates': 'Domates',
    'portakal': 'Portakal',
    'narenciye': 'Portakal',
    'cay': 'Çay',
    'caycamellia': 'Çay',
  };

  static bool isSupported(String? cropName) {
    if (cropName == null || cropName.trim().isEmpty) return false;
    return _keyToCanonical.containsKey(normalize(cropName));
  }

  static String? canonicalName(String? cropName) {
    return _keyToCanonical[normalize(cropName ?? '')];
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
