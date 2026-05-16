/// CLAUDE.md sec 15 — Türkiye coğrafi bölge çıkarımı.
///
/// Lat/lng → bölge kodu. Rule pack'lerdeki `region` fact'i ile eşleşir.
/// Bölge sınırları yaklaşıktır; kullanıcı bölgeyi manuel seçtiğinde
/// (örn. tarla detay ayarları), o değer öncelikli olmalıdır.
///
/// Türkiye 7 coğrafi bölge — TUİK standardı:
///   marmara (Trakya kısmı için 'trakya'), ege, akdeniz,
///   ic_anadolu, karadeniz, dogu_anadolu, gap (Güneydoğu Anadolu)
class RegionInference {
  RegionInference._();

  /// Verilen lat/lng için tahmini bölge kodu döner.
  /// Türkiye dışı koordinatlar için null.
  static String? fromLatLng(double? lat, double? lng) {
    if (lat == null || lng == null) return null;
    if (lat < 35.5 || lat > 42.5 || lng < 25.5 || lng > 45.0) return null;

    // Trakya — Marmara'nın Avrupa yakası
    if (lng < 28.0 && lat > 40.5) return 'trakya';

    // Marmara — Anadolu yakası (geriye kalan); rule pack ayrımı yok,
    // 'trakya'ya en yakın eşleşme.
    if (lat > 40.0 && lng < 30.0) return 'trakya';

    // Karadeniz — kuzey kıyı şeridi
    if (lat > 40.5) return 'karadeniz';

    // Ege — batı kıyı
    if (lng < 29.0 && lat < 39.5) return 'ege';

    // Akdeniz — güney kıyı şeridi
    if (lat < 37.5 && lng < 36.5) return 'akdeniz';

    // GAP — Güneydoğu Anadolu (Şanlıurfa-Diyarbakır-Mardin civarı)
    if (lat < 38.5 && lng > 37.0 && lng < 43.0) return 'gap';

    // Doğu Anadolu — yüksek doğu
    if (lng > 39.5) return 'dogu_anadolu';

    // İç Anadolu — Anadolu platosu (varsayılan kalan)
    return 'ic_anadolu';
  }

  /// Üretim sistemi enum string'i → `cultivation_type` fact'i.
  /// `ProductionSystem.greenhouse` → 'greenhouse'; diğerleri 'open_field'.
  static String cultivationTypeFromProductionSystem(String? productionSystem) {
    return productionSystem == 'greenhouse' ? 'greenhouse' : 'open_field';
  }

  /// Üretim sistemi → `water_regime`. `dryFarming` → 'dryland'; aksi
  /// 'irrigated' (varsayılan en yaygın senaryo).
  static String waterRegimeFromProductionSystem(String? productionSystem) {
    return productionSystem == 'dryFarming' ? 'dryland' : 'irrigated';
  }
}
