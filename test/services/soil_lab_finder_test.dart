import 'package:flutter_test/flutter_test.dart';

import 'package:feng_498/services/soil_lab_finder.dart';

/// SoilLabFinder — saf, deterministik arama bağlantısı üretici.
/// CLAUDE.md §6 (uydurma veri yok) + §10 (kaynak kuralları) + §29.
void main() {
  // Antalya merkez civarı örnek koordinat.
  const lat = 36.8969;
  const lon = 30.7133;

  group('buildOptions — deterministik ve uydurma içermez', () {
    test('aynı girdi → aynı çıktı (deterministik)', () {
      final a =
          SoilLabFinder.buildOptions(lat: lat, lon: lon, radiusKm: 100);
      final b =
          SoilLabFinder.buildOptions(lat: lat, lon: lon, radiusKm: 100);
      expect(a.options.length, b.options.length);
      for (var i = 0; i < a.options.length; i++) {
        expect(a.options[i].url, b.options[i].url);
        expect(a.options[i].title, b.options[i].title);
      }
      expect(a.radiusLabel, b.radiusLabel);
      expect(a.locationLabel, b.locationLabel);
    });

    test('üç arama bağlantısı üretir (harita + web + resmî)', () {
      final r = SoilLabFinder.buildOptions(lat: lat, lon: lon, radiusKm: 50);
      expect(r.options.length, 3);
      final kinds = r.options.map((o) => o.kind).toSet();
      expect(kinds, containsAll(SoilLabLinkKind.values));
    });

    test('tüm URL\'ler geçerli http(s) bağlantısıdır', () {
      final r = SoilLabFinder.buildOptions(lat: lat, lon: lon, radiusKm: 100);
      for (final o in r.options) {
        final uri = Uri.tryParse(o.url);
        expect(uri, isNotNull);
        expect(uri!.scheme, anyOf('http', 'https'));
        expect(uri.host, isNotEmpty);
      }
    });

    test('harita bağlantısı konum koordinatını içerir', () {
      final r = SoilLabFinder.buildOptions(lat: lat, lon: lon, radiusKm: 100);
      final map =
          r.options.firstWhere((o) => o.kind == SoilLabLinkKind.map);
      expect(map.url, contains(lat.toStringAsFixed(6)));
      expect(map.url, contains(lon.toStringAsFixed(6)));
    });

    test('yarıçap etiketi seçilen km değerini yansıtır', () {
      expect(
        SoilLabFinder.buildOptions(lat: lat, lon: lon, radiusKm: 150)
            .radiusLabel,
        '150 km',
      );
    });
  });

  group('konum etiketi', () {
    test('il/ilçe verilmezse koordinat gösterilir', () {
      final r = SoilLabFinder.buildOptions(lat: lat, lon: lon, radiusKm: 100);
      expect(r.locationLabel, contains('36.8969'));
      expect(r.locationLabel, contains('30.7133'));
    });

    test('il/ilçe verilirse yer adı kullanılır (uydurulmaz, geçilen değer)',
        () {
      final r = SoilLabFinder.buildOptions(
        lat: lat,
        lon: lon,
        radiusKm: 100,
        province: 'Antalya',
        district: 'Serik',
      );
      expect(r.locationLabel, 'Antalya Serik');
      final web =
          r.options.firstWhere((o) => o.kind == SoilLabLinkKind.web);
      expect(Uri.decodeFull(web.url).toLowerCase(), contains('antalya'));
    });
  });

  group('distanceKm — Haversine', () {
    test('aynı nokta → 0 km', () {
      expect(SoilLabFinder.distanceKm(lat, lon, lat, lon), closeTo(0, 0.001));
    });

    test('Antalya ↔ Ankara ~ 350-400 km aralığında', () {
      final d = SoilLabFinder.distanceKm(36.8969, 30.7133, 39.9334, 32.8597);
      expect(d, greaterThan(350));
      expect(d, lessThan(420));
    });
  });
}
