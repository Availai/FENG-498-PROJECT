import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';

/// seed_plants.json'daki 292 bitkiden her biri için Wikipedia'dan indirilen
/// fotoğrafları (Türkçe isim → dosya adı) taşır. `assets/data/crop_images.json`
/// içinde üretilir (backend/data_pipeline/fetch_crop_images.js).
class CropImageMap {
  static Map<String, String> _map = {};
  static Map<String, String> _mapLower = {};
  static bool _loaded = false;

  static Future<void> load() async {
    if (_loaded) return;
    try {
      final raw = await rootBundle.loadString('assets/data/crop_images.json');
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        _map = decoded.map((k, v) => MapEntry(k.toString(), v.toString()));
        _mapLower = {
          for (final e in _map.entries) e.key.toLowerCase(): e.value,
        };
      }
    } catch (_) {
      // Map yoksa sessiz kal — fallback string-match devrede
    }
    _loaded = true;
  }

  static String? lookup(String cropName) {
    final hit = _map[cropName] ?? _mapLower[cropName.toLowerCase()];
    return hit == null ? null : 'assets/crops/$hit';
  }
}

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
  // 1. Önce indirilen 292-bitki eşlemesinde ara (Türkçe isim tam eşleşme)
  final mapped = CropImageMap.lookup(cropName);
  if (mapped != null) return mapped;

  // 2. Fallback: substring eşleştirme — Türkçe dosya adlarıyla
  final name = cropName.toLowerCase();
  if (name.contains('buğday') || name.contains('tritikale') || name.contains('çavdar')) return 'assets/crops/bugday.jpg';
  if (name.contains('arpa')) return 'assets/crops/arpa.jpg';
  if (name.contains('yulaf')) return 'assets/crops/bugday.jpg';
  if (name.contains('mısır')) return 'assets/crops/misir.jpg';
  if (name.contains('ayçiçek')) return 'assets/crops/aycicegi.jpg';
  if (name.contains('pamuk')) return 'assets/crops/pamuk.jpg';
  if (name.contains('çeltik') || name.contains('pirinç')) return 'assets/crops/celtik.jpg';
  if (name.contains('domates')) return 'assets/crops/domates.jpg';
  if (name.contains('biber')) return 'assets/crops/biber.jpg';
  if (name.contains('patlıcan')) return 'assets/crops/patlican.jpg';
  if (name.contains('üzüm')) return 'assets/crops/uzum.jpg';
  if (name.contains('elma')) return 'assets/crops/elma.jpg';
  if (name.contains('armut')) return 'assets/crops/armut.jpg';
  if (name.contains('karpuz')) return 'assets/crops/karpuz.jpg';
  if (name.contains('kavun')) return 'assets/crops/karpuz.jpg';
  if (name.contains('marul')) return 'assets/crops/marul.jpg';
  if (name.contains('lahana')) return 'assets/crops/lahana.jpg';
  if (name.contains('havuç')) return 'assets/crops/havuc.jpg';
  if (name.contains('soğan')) return 'assets/crops/sogan.jpg';
  if (name.contains('zeytin')) return 'assets/crops/zeytin.jpg';
  if (name.contains('patates')) return 'assets/crops/patates.jpg';
  if (name.contains('nohut')) return 'assets/crops/nohut.jpg';
  if (name.contains('mercimek')) return 'assets/crops/mercimek.png';
  if (name.contains('fasulye')) return 'assets/crops/kuru_fasulye.jpg';
  if (name.contains('kolza') || name.contains('kanola')) return 'assets/crops/kanola.jpg';
  if (name.contains('ayçiçek')) return 'assets/crops/aycicegi.jpg';
  if (name.contains('susam')) return 'assets/crops/susam.jpg';
  if (name.contains('soya')) return 'assets/crops/soya.jpg';
  return 'assets/crops/bugday.jpg';
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
      zoomScale = zoomScale.clamp(0.2, 2.5); // Maximum scale sınırlandırıldı ki aşırı abartı durmasın

      final phase = getGrowthPhase(maturityPercent);
      final phaseScale = _getScaleMultiplier(phase);
      final assetPath = _getAssetPath(cropName);

      const double baseWidth = 34;  // Daha ferah bir yerleşim için küçültüldü
      const double baseHeight = 40;

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
      final double shadowAlpha = phase == GrowthPhase.harvest
          ? 0.18 + (harvestPulse * 0.05)
          : 0.12;

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
        transform: Matrix4.identity()..rotateX(0.95), // Doğru 3D pop-up perspektifi
        alignment: Alignment.center, // Harita koordinatı olan merkeze kilitli dön!
        child: SizedBox(
          width: 240,
          height: 240,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center, // Bütün objelerin tam ortası LatLng koordinatına oturur!
            children: [
              // 1. Toprak dairesi — koordinatın merkezinde, ekim izlenimini verir
              currentZoom < 16.5 ? const SizedBox.shrink() : soilDisc,
              // 2. Gölge: toprak üstünde hafif kararma
              currentZoom < 16.5 ? const SizedBox.shrink() : groundShadow,

              // 3. Bitki: Ortası harita noktasındayken (yani yarısı yeraltındayken),
              // tam boyunun yarısı kadar (spriteH / 2) yukarı (eksi Y ekseni) kaydırarak
              // bitkinin tam KÖKÜNÜ koordinata/gölgeye oturtuyoruz!
              Transform.translate(
                offset: Offset(0, -(spriteH / 2) + 4), // 4 pixel küçük bir gölge/kök payı
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

