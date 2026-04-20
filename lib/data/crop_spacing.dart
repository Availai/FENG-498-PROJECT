/// Türkiye tarımında kabul görmüş sıra (row) × bitki (plant) aralıkları — cm.
/// Kaynak: Tarım Bakanlığı bitkisel üretim teknik şartnameleri, TZOB yetiştirici
/// rehberleri. Tam bilimsel değer değil; haritada bir "doğru ölçek" ile yerleşim
/// üretmek için referans.
library;

class CropSpacing {
  final double rowCm;
  final double plantCm;
  const CropSpacing(this.rowCm, this.plantCm);

  double get rowM => rowCm / 100.0;
  double get plantM => plantCm / 100.0;
}

const CropSpacing _default = CropSpacing(60, 30);

const Map<String, CropSpacing> _bySubstring = {
  // Tahıl — çok sık ekilir; görsel olarak örnekleme için aralık biraz açılmıştır
  'buğday': CropSpacing(40, 15),
  'arpa': CropSpacing(40, 15),
  'yulaf': CropSpacing(40, 15),
  'çeltik': CropSpacing(25, 15),
  'pirinç': CropSpacing(25, 15),
  // Geniş sıralı tarla bitkileri
  'mısır': CropSpacing(70, 25),
  'ayçiçek': CropSpacing(70, 30),
  'pamuk': CropSpacing(70, 20),
  'soya': CropSpacing(50, 15),
  'kolza': CropSpacing(45, 20),
  // Sebze (orta sıra)
  'domates': CropSpacing(100, 50),
  'biber': CropSpacing(60, 40),
  'patlıcan': CropSpacing(80, 60),
  'salatalık': CropSpacing(150, 50),
  // Yaprak sebze
  'marul': CropSpacing(40, 30),
  'lahana': CropSpacing(60, 40),
  // Kök sebzeler
  'havuç': CropSpacing(30, 8),
  'soğan': CropSpacing(25, 10),
  'patates': CropSpacing(75, 30),
  // Baklagil
  'fasulye': CropSpacing(50, 15),
  'nohut': CropSpacing(40, 10),
  'mercimek': CropSpacing(30, 8),
  // Kavun-karpuz — sürünücü
  'karpuz': CropSpacing(250, 100),
  'kavun': CropSpacing(250, 100),
  // Bağ / meyve
  'üzüm': CropSpacing(250, 150),
  'elma': CropSpacing(500, 400),
  'armut': CropSpacing(450, 350),
  'şeftali': CropSpacing(450, 350),
  'kiraz': CropSpacing(500, 400),
  'zeytin': CropSpacing(600, 600),
  'ceviz': CropSpacing(800, 800),
};

CropSpacing spacingFor(String cropName) {
  final n = cropName.toLowerCase();
  for (final e in _bySubstring.entries) {
    if (n.contains(e.key)) return e.value;
  }
  return _default;
}
