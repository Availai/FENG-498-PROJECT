/// Tek yıllık vs çok yıllık ürün ayrımı ve UI gösterim yardımcıları.
///
/// Tarlam'da `days_to_harvest` / `harvestDays` alanı iki anlam taşır:
///  - Tek yıllık ürünler (domates, mısır, ayçiçeği, buğday vb.):
///    Tohum ekiminden hasada kadar takvim günü. Çiftci her sezon başa
///    sarar.
///  - Çok yıllık ürünler (portakal, çay, zeytin, ceviz vb.):
///    Fidan dikiminden ilk ekonomik hasada kadar **takriben** geçen
///    gün (yaklaşık yazımdır). Asıl önemli olan tesis sonrası her
///    yıl tekrarlanan hasat penceresi (çay Mayıs-Ekim 3 sürgün,
///    portakal Kasım-Nisan).
///
/// Bu dosya tek kaynak helper'dır; UI bunu çağırarak ürüne göre
/// doğru metni üretir. Mevcut Drift şemasına (Fields.harvestDays)
/// dokunmaz — sadece sunum kat\u031manında ayrışır.
library;

/// Ürün yaşam döngüsü tipi.
enum CropCycleType {
  /// Tek yıllık: her sezon ekim → hasat (domates, mısır vb.).
  annual,

  /// Çok yıllık: bir kez tesis edilir, yıllar boyunca verim verir
  /// (portakal, çay, zeytin, ceviz, asma vb.).
  perennial,
}

/// 5 ana ürün ve diğer bilinen çok yıllıklar için stable_id
/// eşlemesi. Kaynak: seed_plants.json + CLAUDE.md §11.
const Set<String> _perennialStableIds = <String>{
  'crop.tea',
  'crop.orange',
  // Diğer turunçgiller ve meyve ağaçları eklenirse buraya:
  // 'crop.lemon', 'crop.mandarin', 'crop.olive', 'crop.walnut',
  // 'crop.apple', 'crop.cherry', 'crop.hazelnut', 'crop.grapevine',
};

/// Kategori bazlı (Meyve / Endustri Bitkisi / vb.) çok yıllık tahmini.
/// stable_id yoksa fallback olarak kullanılır.
const Set<String> _perennialCategories = <String>{
  'Meyve',
  // Çay "Endüstri Bitkisi" kategorisinde; tek başına kategoriden
  // çıkarılamaz çünkü ayçiçeği de "Endüstri Bitkisi"dir.
  // Bu yüzden stable_id birincil kaynaktır.
};

/// Türkçe ürün adı → stable_id eşlemesi (5 ana ürün ve yaygın çok
/// yıllıklar). Drift / SQLite lookup'ı senkron olmayan yerlerden de
/// (örn. statik CropGuide kayıtları) çok yıllık tespiti için hızlı
/// ad bazlı kontrol sağlar. Büyük/küçük harf duyarsızdır.
const Map<String, String> _perennialCropNamesTr = <String, String>{
  'portakal': 'crop.orange',
  'çay': 'crop.tea',
};

/// Bir ürünün çok yıllık olup olmadığını belirler.
///
/// Öncelik sırası:
///  1. `stableId` `_perennialStableIds` kümesinde mi?
///  2. `cropName` çok yıllık ad listesinde mi (Türkçe, case-insensitive)?
///  3. `category` "Meyve" gibi bir kategori mi?
///  4. Aksi takdirde tek yıllık varsayılır.
CropCycleType cycleTypeFor({
  String? stableId,
  String? cropName,
  String? category,
}) {
  if (stableId != null && _perennialStableIds.contains(stableId)) {
    return CropCycleType.perennial;
  }
  if (cropName != null) {
    final key = cropName.trim().toLowerCase();
    if (_perennialCropNamesTr.containsKey(key)) {
      return CropCycleType.perennial;
    }
  }
  if (category != null && _perennialCategories.contains(category)) {
    return CropCycleType.perennial;
  }
  return CropCycleType.annual;
}

/// `harvestDays` değerini insan okunabilir Türkçe metne çevirir.
///
/// Tek yıllık: "120 gün" (yaklaşık ay bilgisi eklenir).
/// Çok yıllık: "~3 yıl" / "~3.5 yıl".
String harvestDaysLabel({
  required int harvestDays,
  required CropCycleType cycle,
}) {
  if (cycle == CropCycleType.perennial) {
    final years = harvestDays / 365.0;
    if (years >= 1.0) {
      // 0.5 hassasiyetle yuvarla: 3.0, 3.5, 4.0 ...
      final rounded = (years * 2).round() / 2;
      if (rounded == rounded.truncate()) {
        return '~${rounded.toInt()} yıl';
      }
      return '~${rounded.toStringAsFixed(1)} yıl';
    }
    return '~$harvestDays gün';
  }
  return '$harvestDays gün';
}

/// Tooltip / kart / setup-senaryosu için tam cümle oluşturur.
///
/// Tek yıllık: "Hasat süresi: 120 gün (ekimden)"
/// Çok yıllık: "İlk ekonomik hasat: ~3 yıl (fidan dikiminden)"
String harvestSummary({
  required int harvestDays,
  required CropCycleType cycle,
}) {
  final label = harvestDaysLabel(harvestDays: harvestDays, cycle: cycle);
  if (cycle == CropCycleType.perennial) {
    return 'İlk ekonomik hasat: $label (fidan dikiminden)';
  }
  return 'Hasat süresi: $label (ekimden)';
}

/// Çok yıllık üründe her yıl tekrarlanan hasat penceresi bilgisi.
/// `harvestMonths` 1-12 aralığında ay numaraları listesidir.
/// Boşsa `null` döner.
String? annualHarvestWindow(List<int>? harvestMonths) {
  if (harvestMonths == null || harvestMonths.isEmpty) return null;
  const names = <String>[
    '',
    'Ocak',
    'Şubat',
    'Mart',
    'Nisan',
    'Mayıs',
    'Haziran',
    'Temmuz',
    'Ağustos',
    'Eylül',
    'Ekim',
    'Kasım',
    'Aralık',
  ];
  // Bitiminin başlangıcının önünde olabileceği turunçgil gibi
  // kış hasatları (örn. 11,12,1,2,3,4) için ardışıklık testi yapıp
  // tek aralık gösterilir.
  final sorted = [...harvestMonths]..sort();
  // Yılbaşını sarmalayan dizi tespiti: 11,12,1,2 → 11..4 göstergesi.
  final wrapAround = sorted.contains(12) && sorted.contains(1);
  if (wrapAround) {
    final winter = sorted.where((m) => m >= 9).toList()..sort();
    final spring = sorted.where((m) => m <= 6).toList()..sort();
    if (winter.isNotEmpty && spring.isNotEmpty) {
      return 'Her yıl ${names[winter.first]}-${names[spring.last]} arası hasat';
    }
  }
  if (sorted.length == 1) {
    return 'Her yıl ${names[sorted.first]} ayı hasat';
  }
  return 'Her yıl ${names[sorted.first]}-${names[sorted.last]} arası hasat';
}

/// `Hasada X gün kaldı` sayacının gösterilip gösterilmeyeceği.
///
/// Çok yıllık üründe tek seferlik geri sayım anlamsız; bunun yerine
/// "Her yıl ... arası hasat" mesajı gösterilir. UI buna göre ayrışır.
bool shouldShowCountdown(CropCycleType cycle) {
  return cycle == CropCycleType.annual;
}
