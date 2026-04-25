import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

enum GrowthPhase { seedling, growing, mature, harvest }

GrowthPhase getGrowthPhase(double maturityPercent) {
  if (maturityPercent < 25) return GrowthPhase.seedling;
  if (maturityPercent < 75) return GrowthPhase.growing;
  if (maturityPercent < 90) return GrowthPhase.mature;
  return GrowthPhase.harvest;
}

double _getScaleMultiplier(GrowthPhase phase) {
  switch (phase) {
    case GrowthPhase.seedling:
      return 0.55;
    case GrowthPhase.growing:
      return 0.8;
    case GrowthPhase.mature:
      return 1.0;
    case GrowthPhase.harvest:
      return 1.08; // Hasat: hafif büyütme, abartıya kaçmadan
  }
}

String _getAssetPath(String cropName) {
  final name = cropName.toLowerCase();
  if (name.contains('buğday') ||
      name.contains('arpa') ||
      name.contains('yulaf')) return 'assets/crops/wheat.png';
  if (name.contains('mısır')) return 'assets/crops/corn.png';
  if (name.contains('ayçiçek') || name.contains('ayçiçeği'))
    return 'assets/crops/sunflower.png';
  if (name.contains('pamuk')) return 'assets/crops/cotton.png';
  if (name.contains('çeltik') || name.contains('pirinç'))
    return 'assets/crops/rice.png';
  if (name.contains('domates')) return 'assets/crops/tomato.png';
  if (name.contains('biber')) return 'assets/crops/pepper.png';
  if (name.contains('patlıcan')) return 'assets/crops/eggplant.png';
  if (name.contains('üzüm')) return 'assets/crops/grape.png';
  if (name.contains('elma')) return 'assets/crops/apple_tree.png';
  if (name.contains('karpuz') || name.contains('kavun'))
    return 'assets/crops/watermelon.png';
  if (name.contains('marul') ||
      name.contains('lahana') ||
      name.contains('kolza')) return 'assets/crops/cabbage.png';
  if (name.contains('havuç')) return 'assets/crops/carrot.png';
  if (name.contains('soğan')) return 'assets/crops/onion.png';
  if (name.contains('zeytin')) return 'assets/crops/olive_tree.png';
  if (name.contains('nohut') ||
      name.contains('mercimek') ||
      name.contains('patates')) return 'assets/crops/potato.png';
  return 'assets/crops/wheat.png';
}

/// Tarla poligonu üzerine yerleşen bitki markerı.
/// Tasarım notları:
///  • Hiçbir arka-plan kutu/çerçeve/frame yok — saf transparan PNG.
///  • PNG'nin altında yumuşak bir toprak gölgesi (elips) oluşturularak bitkinin
///    "havada süzülmek" yerine toprağa ekilmiş gibi görünmesi sağlanır.
///  • Sprite'ın tabanı (bottom-center) markerın alt kenarına hizalanır; bu
///    flutter_map'in lat/lng noktasını toprak zeminine çevirir.
///  • Neon glow efekti kaldırıldı (çiftçi dostu tema gereği).
Widget buildCropMarkerWidget({
  required String cropName,
  required Color cropColor,
  required double maturityPercent,
  double harvestPulse = 0.0,
  VoidCallback? onTap,
}) {
  return Builder(
    builder: (context) {
      final camera = MapCamera.maybeOf(context);
      final currentZoom = camera?.zoom ?? 18.0;

      // Harita zoom seviyesine göre büyüme çarpanı
      // zoom 18 referans alınarak (2^(zoom-18)), crop'lar harita büyüklüğüne kitlenir.
      double zoomScale = math.pow(2.0, currentZoom - 18.0).toDouble();
      zoomScale = zoomScale.clamp(
          0.2, 2.5); // Maximum scale sınırlandırıldı ki aşırı abartı durmasın

      final phase = getGrowthPhase(maturityPercent);
      final phaseScale = _getScaleMultiplier(phase);
      final assetPath = _getAssetPath(cropName);

      const double baseWidth =
          42; // Görselde çok devasa durduğu için yarıya indirdim
      const double baseHeight = 48;

      final double spriteW = baseWidth * phaseScale * zoomScale;
      final double spriteH = baseHeight * phaseScale * zoomScale;

      final sprite = Image.asset(
        assetPath,
        width: spriteW,
        height: spriteH,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.medium,
        // Hata durumunda render iptali.
        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
      );

      final double shadowW = spriteW * 0.7;
      final double shadowH = spriteH * 0.12;
      // Gölgeleri çok yumuşattık çünkü overlap olunca kapkara oluyorlardı.
      final double shadowAlpha =
          phase == GrowthPhase.harvest ? 0.18 + (harvestPulse * 0.05) : 0.12;

      final groundShadow = Container(
        width: shadowW,
        height: shadowH,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: shadowAlpha),
          borderRadius: BorderRadius.all(Radius.elliptical(shadowW, shadowH)),
        ),
      );

      // "Kazılmış toprak" dairesi — bitkinin toprağa ekildiği izlenim için
      // radial gradient: merkez koyu toprak, kenar fade-out
      final double soilW = spriteW * 0.85;
      final double soilH = spriteH * 0.22;
      final soilDisc = Container(
        width: soilW,
        height: soilH,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.all(Radius.elliptical(soilW, soilH)),
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 0.55,
            colors: [
              const Color(0xFF3E2A17).withValues(alpha: 0.55),
              const Color(0xFF5B3A21).withValues(alpha: 0.35),
              const Color(0xFF5B3A21).withValues(alpha: 0.0),
            ],
            stops: const [0.0, 0.55, 1.0],
          ),
        ),
      );

      final marker = Transform(
        transform: Matrix4.identity()
          ..rotateX(0.95), // Doğru 3D pop-up perspektifi
        alignment:
            Alignment.center, // Harita koordinatı olan merkeze kilitli dön!
        child: SizedBox(
          width: 240,
          height: 240,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment
                .center, // Bütün objelerin tam ortası LatLng koordinatına oturur!
            children: [
              // 1. Toprak dairesi — koordinatın merkezinde, ekim izlenimini verir
              currentZoom < 16.5 ? const SizedBox.shrink() : soilDisc,
              // 2. Gölge: toprak üstünde hafif kararma
              currentZoom < 16.5 ? const SizedBox.shrink() : groundShadow,

              // 3. Bitki: Ortası harita noktasındayken (yani yarısı yeraltındayken),
              // tam boyunun yarısı kadar (spriteH / 2) yukarı (eksi Y ekseni) kaydırarak
              // bitkinin tam KÖKÜNÜ koordinata/gölgeye oturtuyoruz!
              Transform.translate(
                offset: Offset(
                    0, -(spriteH / 2) + 4), // 4 pixel küçük bir gölge/kök payı
                child: sprite,
              ),
            ],
          ),
        ),
      );

      if (onTap != null) {
        return GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: marker,
        );
      }
      return marker;
    },
  );
}
