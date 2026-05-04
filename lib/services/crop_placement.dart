import 'dart:math' as math;
import 'package:latlong2/latlong.dart';
import '../data/crop_spacing.dart';

const int defaultVisualPlantLimit = 160;
const int hardVisualPlantLimit = 320;
const double defaultMinVisualSpacingM = 1.25;

/// Poligon içinde, tarlanın ilk kenarına paralel satırlar halinde,
/// bitki için girilen gerçek sıra × bitki aralığına (cm) uyan coğrafi
/// temsili noktalar üretir.
///
/// - [polygon]: ekim bölgesi sınırı (en az 3 nokta)
/// - [cropName]: bitki adı — [spacingFor] tablosundan varsayılan aralık için
/// - [rowSpacingCm]: sıra arası cm (kullanıcının girdiği değer önceliklidir)
/// - [plantSpacingCm]: bitki arası cm (kullanıcının girdiği değer önceliklidir)
/// - [exactCount]: kullanıcının hedeflediği gerçek bitki adedi. Harita bu adedi
///   bire bir çizmez; alana yayılmış temsili marker yoğunluğu hesaplar.
/// - [maxCount]: render tavanı. Gerçek bitki hesabından bağımsızdır.
/// - [minVisualSpacingM]: marker çakışmasını önleyen görsel alt sınır.
List<LatLng> plantPlacementInPolygon({
  required List<LatLng> polygon,
  required String cropName,
  double? rowSpacingCm,
  double? plantSpacingCm,
  int? exactCount,
  int maxCount = defaultVisualPlantLimit,
  double minVisualSpacingM = defaultMinVisualSpacingM,
}) {
  if (polygon.length < 3 || maxCount <= 0) return const [];
  final safeMax = maxCount.clamp(1, hardVisualPlantLimit).toInt();

  final defaultSpacing = spacingFor(cropName);
  // Kullanıcı değeri her zaman önce gelir; yoksa tablo varsayılanı kullan.
  final rowCm = (rowSpacingCm != null && rowSpacingCm > 0)
      ? rowSpacingCm
      : defaultSpacing.rowCm;
  final plantCm = (plantSpacingCm != null && plantSpacingCm > 0)
      ? plantSpacingCm
      : defaultSpacing.plantCm;

  final rowM = rowCm / 100.0;
  final plantM = plantCm / 100.0;
  if (rowM <= 0 || plantM <= 0) return const [];

  final areaSqm = polygonAreaSqm(polygon);
  final rawCapacity =
      areaSqm > 0 ? math.max(1, (areaSqm / (rowM * plantM)).floor()) : safeMax;
  final requestedCount =
      exactCount != null && exactCount > 0 ? exactCount : rawCapacity;
  final visibleTarget = math.min(requestedCount, safeMax);
  if (visibleTarget <= 0) return const [];

  // Gerçek yoğunluk yüksekse marker aralığını orantılı büyütürüz. Böylece
  // ilk satırda kesmek yerine tüm poligona yayılmış temsili bir görünüm kalır.
  final countScale =
      math.sqrt(rawCapacity / visibleTarget).clamp(1.0, double.infinity);
  final visualScale = minVisualSpacingM <= 0
      ? 1.0
      : math.max(minVisualSpacingM / rowM, minVisualSpacingM / plantM);
  final spacingScale =
      math.max(1.0, math.max(countScale.toDouble(), visualScale));
  final effRowM = rowM * spacingScale;
  final effPlantM = plantM * spacingScale;

  // ── 1. Sıra yönü = ilk kenarın yönü
  final origin = polygon[0];
  final dLat = polygon[1].latitude - polygon[0].latitude;
  final dLng = polygon[1].longitude - polygon[0].longitude;
  final rowAngle = math.atan2(dLat, dLng); // east=0 radian

  // ── 2. Merkez enlemde 1 m kaç derece
  double cLat = 0;
  for (final p in polygon) {
    cLat += p.latitude;
  }
  cLat /= polygon.length;

  const mPerDegLat = 111320.0;
  final rawMPerDegLng = 111320.0 * math.cos(cLat * math.pi / 180.0);
  final mPerDegLng = rawMPerDegLng.abs() < 1e-6 ? 1e-6 : rawMPerDegLng;

  // ── 3. Rotasyon helper'ları
  LatLng rotate(LatLng p, double a) {
    final y = (p.latitude - origin.latitude);
    final x = (p.longitude - origin.longitude);
    final rx = x * math.cos(a) - y * math.sin(a);
    final ry = x * math.sin(a) + y * math.cos(a);
    return LatLng(origin.latitude + ry, origin.longitude + rx);
  }

  final rotatedPoly = polygon.map((p) => rotate(p, -rowAngle)).toList();

  double minLat = rotatedPoly.first.latitude,
      maxLat = rotatedPoly.first.latitude;
  double minLng = rotatedPoly.first.longitude,
      maxLng = rotatedPoly.first.longitude;
  for (final p in rotatedPoly) {
    if (p.latitude < minLat) minLat = p.latitude;
    if (p.latitude > maxLat) maxLat = p.latitude;
    if (p.longitude < minLng) minLng = p.longitude;
    if (p.longitude > maxLng) maxLng = p.longitude;
  }

  // ── 4. Adım büyüklükleri — agronomik oran korunur, görsel yoğunluk seyreltilir.
  final latStep = effRowM / mPerDegLat;
  final lngStep = effPlantM / mPerDegLng;
  if (latStep <= 0 || lngStep <= 0) return const [];

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
        final p = rotate(LatLng(lat, lng), rowAngle);
        result.add(p);
        if (result.length >= visibleTarget) return result;
      }
    }
  }
  return result;
}

/// Verilen alan (m²), sıra arası (cm) ve bitki arası (cm) değerlerinden
/// kaç bitki sığacağını hesaplar. Görsel render'dan bağımsız saf hesap.
int estimatePlantCount({
  required double areaSqm,
  required double rowSpacingCm,
  required double plantSpacingCm,
}) {
  final rowM = rowSpacingCm / 100.0;
  final plantM = plantSpacingCm / 100.0;
  if (rowM <= 0 || plantM <= 0 || areaSqm <= 0) return 0;
  return (areaSqm / (rowM * plantM)).floor();
}

double polygonAreaSqm(List<LatLng> polygon) {
  if (polygon.length < 3) return 0;
  final avgLat =
      polygon.map((p) => p.latitude).reduce((a, b) => a + b) / polygon.length;
  const metersPerDegLat = 111320.0;
  final metersPerDegLng = 111320.0 * math.cos(avgLat * math.pi / 180.0);
  double sum = 0;
  for (var i = 0; i < polygon.length; i++) {
    final a = polygon[i];
    final b = polygon[(i + 1) % polygon.length];
    final ax = a.longitude * metersPerDegLng;
    final ay = a.latitude * metersPerDegLat;
    final bx = b.longitude * metersPerDegLng;
    final by = b.latitude * metersPerDegLat;
    sum += ax * by - bx * ay;
  }
  return sum.abs() / 2.0;
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
