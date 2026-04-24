import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

import 'package:feng_498/services/crop_placement.dart';

void main() {
  test('kayitli sira ve bitki araligi marker yogunlugunu degistirir', () {
    const polygon = [
      LatLng(39.00000, 35.00000),
      LatLng(39.00000, 35.00016),
      LatLng(39.00016, 35.00016),
      LatLng(39.00016, 35.00000),
    ];

    final dense = plantPlacementInPolygon(
      polygon: polygon,
      cropName: 'Mısır',
      rowSpacingCm: 70,
      plantSpacingCm: 20,
      maxCount: 1000,
      minVisualSpacingM: 0.1,
    );
    final sparse = plantPlacementInPolygon(
      polygon: polygon,
      cropName: 'Mısır',
      rowSpacingCm: 140,
      plantSpacingCm: 80,
      maxCount: 1000,
      minVisualSpacingM: 0.1,
    );

    expect(dense.length, greaterThan(sparse.length));
    expect(dense, isNotEmpty);
  });
}
