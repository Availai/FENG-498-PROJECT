import 'dart:math' as math;
import 'package:latlong2/latlong.dart';
import 'package:maps_toolkit/maps_toolkit.dart' as toolkit;
import '../data/crop_spacing.dart';

/// Poligon içinde, tarlanın ilk kenarına paralel satırlar halinde,
/// bitki için önerilen gerçek sıra × bitki aralığına uyan noktalar üretir.
///
/// - [polygon]: ekim bölgesi sınırı (en az 3 nokta)
/// - [cropName]: bitki adı — [spacingFor] tablosundan aralık seçmek için
/// - [maxCount]: render başına üst sınır (render performansı için); gerçek
///   yoğunluk bu sayıdan fazlaysa aralıklar orantılı büyütülür (noktalar aynı
///   grid'de kalır, sadece seyrelir).
List<LatLng> plantPlacementInPolygon({
  required List<LatLng> polygon,
  required String cropName,
  int maxCount = 120,
}) {
  if (polygon.length < 3 || maxCount <= 0) return const [];

  final spacing = spacingFor(cropName);

  // ── 1. Poligon alanı ve naif yoğunluktan ölçek çarpanı
  final toolkitPts = polygon
      .map((p) => toolkit.LatLng(p.latitude, p.longitude))
      .toList();
  final areaSqm = toolkit.SphericalUtil.computeArea(toolkitPts).toDouble();
  final cellArea = spacing.rowM * spacing.plantM;
  final rawDensity = cellArea > 0 ? (areaSqm / cellArea).floor() : 0;
  final scale = rawDensity > maxCount
      ? math.sqrt(rawDensity / maxCount) // aralıkları orantılı genişlet
      : 1.0;
  final effRowM = spacing.rowM * scale;
  final effPlantM = spacing.plantM * scale;

  // ── 2. Sıra yönü = ilk kenarın yönü
  final origin = polygon[0];
  final dLat = polygon[1].latitude - polygon[0].latitude;
  final dLng = polygon[1].longitude - polygon[0].longitude;
  final rowAngle = math.atan2(dLat, dLng); // east=0 radian

  // ── 3. Merkez enlemde 1 m kaç derece — sabit dönüşüm (küçük tarlalar için yeterli)
  double cLat = 0;
  for (final p in polygon) {
    cLat += p.latitude;
  }
  cLat /= polygon.length;

  const mPerDegLat = 111320.0;
  final mPerDegLng = 111320.0 * math.cos(cLat * math.pi / 180.0);

  // ── 4. Rotasyon helper'ları (lat/lng düzleminde, kısa mesafeler için kabul edilebilir)
  LatLng rotate(LatLng p, double a) {
    final y = (p.latitude - origin.latitude);
    final x = (p.longitude - origin.longitude);
    final rx = x * math.cos(a) - y * math.sin(a);
    final ry = x * math.sin(a) + y * math.cos(a);
    return LatLng(origin.latitude + ry, origin.longitude + rx);
  }

  final rotatedPoly = polygon.map((p) => rotate(p, -rowAngle)).toList();

  double minLat = rotatedPoly.first.latitude, maxLat = rotatedPoly.first.latitude;
  double minLng = rotatedPoly.first.longitude, maxLng = rotatedPoly.first.longitude;
  for (final p in rotatedPoly) {
    if (p.latitude < minLat) minLat = p.latitude;
    if (p.latitude > maxLat) maxLat = p.latitude;
    if (p.longitude < minLng) minLng = p.longitude;
    if (p.longitude > maxLng) maxLng = p.longitude;
  }

  // ── 5. Döndürülmüş düzlemde satır = X ekseni (longitude), sıra = Y ekseni (latitude)
  //     row spacing → latitude aralığı;  plant spacing → longitude aralığı
  final latStep = effRowM / mPerDegLat;
  final lngStep = effPlantM / mPerDegLng;
  if (latStep <= 0 || lngStep <= 0) return const [];

  // Satırları ve bitkileri kenarlardan half-step içeriden başlat
  final rows = ((maxLat - minLat) / latStep).floor();
  final cols = ((maxLng - minLng) / lngStep).floor();

  final result = <LatLng>[];
  for (int r = 0; r <= rows; r++) {
    final lat = minLat + latStep * (r + 0.5);
    if (lat > maxLat) break;
    for (int c = 0; c <= cols; c++) {
      final lng = minLng + lngStep * (c + 0.5);
      if (lng > maxLng) break;
      if (_pointInPolygon(lat, lng, rotatedPoly)) {
        // Orijinal yöne geri döndür
        final p = rotate(LatLng(lat, lng), rowAngle);
        result.add(p);
        if (result.length >= maxCount) return result;
      }
    }
  }
  return result;
}

bool _pointInPolygon(double lat, double lng, List<LatLng> polygon) {
  bool inside = false;
  for (int i = 0, j = polygon.length - 1; i < polygon.length; j = i++) {
    final yi = polygon[i].latitude, xi = polygon[i].longitude;
    final yj = polygon[j].latitude, xj = polygon[j].longitude;
    final denom = (yj - yi) == 0 ? 1e-12 : (yj - yi);
    final intersect = ((yi > lat) != (yj > lat)) &&
        (lng < (xj - xi) * (lat - yi) / denom + xi);
    if (intersect) inside = !inside;
  }
  return inside;
}
