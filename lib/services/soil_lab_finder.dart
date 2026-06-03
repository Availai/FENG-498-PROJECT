/// Modül — Yakındaki Toprak Analizi Laboratuvarı Bulucu (link üretici).
///
/// Çiftçinin tarla konumuna göre **akredite toprak analizi laboratuvarı**
/// aratmasına yardımcı olur. CLAUDE.md ilkeleri gereği bu servis hiçbir
/// laboratuvar listesi UYDURMAZ; bunun yerine kullanıcının konumunu ve
/// seçtiği arama yarıçapını kullanarak resmî/harita arama bağlantıları
/// üretir. Gerçek sonuçları kullanıcı, cihazının harita/tarayıcı uygulaması
/// üzerinden görür.
///
/// Tasarım ilkeleri (CLAUDE.md §0, §6, §10, §29):
///   • Saf fonksiyon — IO yok, ağ yok, rastgelelik yok. Aynı girdi → aynı çıktı.
///   • Uydurma kaynak/işletme adı YOK — yalnızca arama bağlantısı.
///   • Çevrimdışı-öncelikli: bağlantı üretimi yereldir; yalnızca kullanıcı
///     bir bağlantıya dokunduğunda internet gerekir.
library;

import 'dart:math' as math;

/// Tek bir arama/yönlendirme bağlantısı önerisi.
class SoilLabSearchOption {
  /// Kullanıcıya görünen başlık (Türkçe).
  final String title;

  /// Kısa açıklama (Türkçe).
  final String subtitle;

  /// Açılacak URL (harita veya web araması).
  final String url;

  /// Bağlantı türü — UI ikon/renk eşler.
  final SoilLabLinkKind kind;

  const SoilLabSearchOption({
    required this.title,
    required this.subtitle,
    required this.url,
    required this.kind,
  });
}

/// Bağlantı türü. Dahili enum (İngilizce) — kullanıcıya görünmez.
enum SoilLabLinkKind { map, web, official }

/// Lab bulucu çıktısı.
class SoilLabFinderResult {
  /// Üretilen arama bağlantıları (öncelik sırasıyla).
  final List<SoilLabSearchOption> options;

  /// İnsana okunur yarıçap etiketi, ör. '100 km'.
  final String radiusLabel;

  /// Konum etiketi (varsa il/ilçe; yoksa koordinat).
  final String locationLabel;

  const SoilLabFinderResult({
    required this.options,
    required this.radiusLabel,
    required this.locationLabel,
  });
}

class SoilLabFinder {
  SoilLabFinder._();

  /// Desteklenen yarıçap seçenekleri (km). Harita aramaları yarıçapı tam
  /// olarak sınırlamaz; bu değer kullanıcıya gösterilen niyet + zoom ipucudur.
  static const List<int> radiusOptionsKm = [25, 50, 100, 150];

  /// Toprak analizi laboratuvarı aramak için arama terimleri.
  static const String _queryTr = 'toprak analizi laboratuvarı';

  /// Verilen konum ve yarıçap için arama bağlantılarını üretir.
  ///
  /// [lat], [lon] tarla/örnek noktası koordinatıdır. [radiusKm] kullanıcının
  /// seçtiği daire yarıçapı. [province]/[district] biliniyorsa arama metnine
  /// eklenir (daha isabetli web sonucu). Hiçbiri uydurulmaz; null ise atlanır.
  static SoilLabFinderResult buildOptions({
    required double lat,
    required double lon,
    required int radiusKm,
    String? province,
    String? district,
  }) {
    final place = _placeLabel(province, district);
    final locationLabel =
        place ?? '${lat.toStringAsFixed(4)}, ${lon.toStringAsFixed(4)}';

    // Web araması metni: yer adı varsa onunla, yoksa "yakınımdaki".
    final webQuery = place != null ? '$_queryTr $place' : '$_queryTr yakınımda';

    // Harita araması metni — konum harita merkeziyle sınırlanır.
    final mapQuery = _queryTr;

    final options = <SoilLabSearchOption>[
      // 1. Google Haritalar — konuma yakın işletme araması (yarıçapa en yakın).
      SoilLabSearchOption(
        title: 'Haritada yakındaki laboratuvarlar',
        subtitle:
            'Konumunuza yakın toprak analizi laboratuvarlarını haritada gösterir.',
        url: _googleMapsSearchUrl(query: mapQuery, lat: lat, lon: lon),
        kind: SoilLabLinkKind.map,
      ),

      // 2. Web araması — yer adıyla zenginleştirilmiş.
      SoilLabSearchOption(
        title: 'Web\'de ara',
        subtitle: place != null
            ? '"$place" için akredite laboratuvar arama sonuçları.'
            : 'Yakınınızdaki laboratuvarlar için web arama sonuçları.',
        url: _googleWebSearchUrl(webQuery),
        kind: SoilLabLinkKind.web,
      ),

      // 3. Resmî yönlendirme — Tarım ve Orman Bakanlığı il/ilçe müdürlükleri.
      const SoilLabSearchOption(
        title: 'Resmî kurumlara danış',
        subtitle:
            'İl/İlçe Tarım ve Orman Müdürlüğü ile akredite kamu laboratuvarları.',
        url:
            'https://www.google.com/search?q=il+il%C3%A7e+tar%C4%B1m+orman+m%C3%BCd%C3%BCrl%C3%BC%C4%9F%C3%BC+toprak+analizi',
        kind: SoilLabLinkKind.official,
      ),
    ];

    return SoilLabFinderResult(
      options: options,
      radiusLabel: '$radiusKm km',
      locationLabel: locationLabel,
    );
  }

  /// Belirli bir koordinatın yaklaşık kaç km uzakta olduğunu hesaplar
  /// (Haversine). Geçmiş örnek noktaları vb. için yardımcı.
  static double distanceKm(double lat1, double lon1, double lat2, double lon2) {
    const earthRadiusKm = 6371.0;
    final dLat = _deg2rad(lat2 - lat1);
    final dLon = _deg2rad(lon2 - lon1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_deg2rad(lat1)) *
            math.cos(_deg2rad(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadiusKm * c;
  }

  // ───────────────────────────────────────────────────────────────────────
  // YARDIMCILAR
  // ───────────────────────────────────────────────────────────────────────

  static String? _placeLabel(String? province, String? district) {
    final p = province?.trim();
    final d = district?.trim();
    final hasP = p != null && p.isNotEmpty;
    final hasD = d != null && d.isNotEmpty;
    if (hasP && hasD) return '$p $d';
    if (hasP) return p;
    if (hasD) return d;
    return null;
  }

  /// Google Haritalar arama URL'si — harita konuma odaklanır (ll + sorgu).
  static String _googleMapsSearchUrl({
    required String query,
    required double lat,
    required double lon,
  }) {
    final q = Uri.encodeComponent(query);
    final c = '${lat.toStringAsFixed(6)},${lon.toStringAsFixed(6)}';
    return 'https://www.google.com/maps/search/?api=1&query=$q&query_place_id=&center=$c';
  }

  /// Google web araması URL'si.
  static String _googleWebSearchUrl(String query) {
    final q = Uri.encodeComponent(query);
    return 'https://www.google.com/search?q=$q';
  }

  static double _deg2rad(double deg) => deg * (math.pi / 180.0);
}
