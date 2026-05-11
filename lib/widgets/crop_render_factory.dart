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

double _facingDegrees(String? directionKey) {
  final raw = directionKey?.trim();
  if (raw == null || raw.isEmpty) return 180.0;
  if (raw.startsWith('deg:')) {
    final parsed = double.tryParse(raw.substring(4));
    if (parsed != null) return parsed % 360.0;
  }
  return switch (directionKey) {
    'north' => 0.0,
    'northeast' => 45.0,
    'east' => 90.0,
    'southeast' => 135.0,
    'south' => 180.0,
    'southwest' => 225.0,
    'west' => 270.0,
    'northwest' => 315.0,
    _ => 180.0,
  };
}

double _facingYawForCameraRadians(
  String? directionKey,
  double cameraRotationDegrees,
) {
  final degrees = _facingDegrees(directionKey);
  final screenDegrees = (degrees + cameraRotationDegrees) % 360.0;
  final delta = ((screenDegrees - 180.0 + 540.0) % 360.0) - 180.0;
  return delta * math.pi / 180.0;
}

/// Yaw'ı tanh eğrisiyle ±[maxYawDegrees] aralığına yumuşatır — 2D sprite'ın
/// kameraya dik açıda incelip kaybolmasını engeller (klasik 2.5D billboarding
/// tekniği). Küçük açılarda doğal davranış, büyük açılarda yön ipucu olarak
/// hafif eğiklik korunur ama sprite hep "kalın" görünür.
double _softenYaw(double rawYawRadians, {double maxYawDegrees = 38.0}) {
  final maxRad = maxYawDegrees * math.pi / 180.0;
  if (maxRad <= 0) return 0.0;
  // tanh(x/k)*k → küçük x'te ≈ x, büyük x'te → ±k.
  final t = math.exp(rawYawRadians / maxRad);
  final invT = 1.0 / t;
  final tanh = (t - invT) / (t + invT);
  return maxRad * tanh;
}

bool _usesLayeredFacing(String cropName, String assetPath) {
  final name = cropName.toLowerCase();
  final asset = assetPath.toLowerCase();
  return asset.contains('aycicegi') ||
      asset.contains('sunflower') ||
      name.contains('aycicek') ||
      name.contains('aycicegi') ||
      name.contains('sunflower');
}

// ignore: unused_element
String _stageKeyForMaturity(double maturityPercent) {
  if (maturityPercent < 12) return 'cimlenme';
  if (maturityPercent < 50) return 'vejetatif';
  if (maturityPercent < 68) return 'ciceklenme';
  if (maturityPercent < 92) return 'meyve_dolumu';
  return 'olgunlasma';
}

/// Ayçiçeği, mısır ve domates dahil tüm bitkiler için gerçek PNG asset
/// dosyaları kullanılır. Vektör sprite devre dışı bırakıldı.
// ignore: unused_element
String? _spriteCropKey(String cropName) => null;

double _getScaleMultiplier(GrowthPhase phase) {
  switch (phase) {
    case GrowthPhase.seedling:
      return 0.66;
    case GrowthPhase.growing:
      return 0.9;
    case GrowthPhase.mature:
      return 1.08;
    case GrowthPhase.harvest:
      return 1.16;
  }
}

String _getAssetPath(String cropName) {
  // 1. Önce indirilen 292-bitki eşlemesinde ara (Türkçe isim tam eşleşme)
  final mapped = CropImageMap.lookup(cropName);
  if (mapped != null) return mapped;

  // 2. Fallback: substring eşleştirme — Türkçe dosya adları (.jpg uzantısı,
  // PNG varsa _buildSprite zaten önce PNG dener, sonra JPG'ye düşer).
  final name = cropName.toLowerCase();
  if (name.contains('ayçiçek')) return 'assets/crops/aycicegi.jpg';
  if (name.contains('mısır')) return 'assets/crops/misir.jpg';
  if (name.contains('domates')) return 'assets/crops/domates.jpg';
  if (name.contains('buğday')) return 'assets/crops/bugday.jpg';
  if (name.contains('arpa')) return 'assets/crops/arpa.jpg';
  if (name.contains('yulaf')) return 'assets/crops/yulaf.jpg';
  if (name.contains('pamuk')) return 'assets/crops/pamuk.jpg';
  if (name.contains('çeltik') || name.contains('pirinç')) {
    return 'assets/crops/celtik.jpg';
  }
  if (name.contains('biber')) return 'assets/crops/biber.jpg';
  if (name.contains('patlıcan')) return 'assets/crops/patlican.jpg';
  if (name.contains('üzüm')) return 'assets/crops/uzum.jpg';
  if (name.contains('elma')) return 'assets/crops/elma.jpg';
  if (name.contains('karpuz')) return 'assets/crops/karpuz.jpg';
  if (name.contains('kavun')) return 'assets/crops/kavun.jpg';
  if (name.contains('marul')) return 'assets/crops/marul.jpg';
  if (name.contains('lahana')) return 'assets/crops/lahana.jpg';
  if (name.contains('kanola') || name.contains('kolza')) {
    return 'assets/crops/kanola.jpg';
  }
  if (name.contains('havuç')) return 'assets/crops/havuc.jpg';
  if (name.contains('soğan')) return 'assets/crops/sogan.jpg';
  if (name.contains('zeytin')) return 'assets/crops/zeytin.jpg';
  if (name.contains('nohut')) return 'assets/crops/nohut.jpg';
  if (name.contains('mercimek')) return 'assets/crops/mercimek.jpg';
  if (name.contains('patates')) return 'assets/crops/patates.jpg';
  if (name.contains('portakal') || name.contains('narenciye')) {
    return 'assets/crops/portakal.png';
  }
  if (name.contains('çay') && !name.contains('adaçay')) {
    return 'assets/crops/cay.png';
  }
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
  String? healthStatus, // 'healthy' | 'diseased' | 'dead' (null = no badge)
  String? diseaseType, // tooltip / accessibility için
  bool isHighlighted = false,
  ValueChanged<bool>? onHover,
  VoidCallback? onTap,
  VoidCallback? onLongPress,
  String?
      facingDirection, // 'north' | 'northeast' | 'deg:180' | null. Bitki dönüşü için kullanılır.
}) {
  // Pahalı efektleri (facing rotation, ColorFilter matrix, AnimatedScale,
  // halo) yalnızca *gerçekten gerekli* marker'larda çalıştır. Tarlada 200+
  // bitki marker'ı varsa, %95'i sıradan/sağlıklı/highlight yok durumdadır;
  // onları sadeleştirilmiş bir code path ile çiz, böylece kamera her hareket
  // ettiğinde yüzlerce ColorFiltered/TweenAnimationBuilder yeniden
  // değerlendirmesi gerekmez.
  final bool needsRichEffects = isHighlighted ||
      healthStatus == 'diseased' ||
      healthStatus == 'dead' ||
      healthStatus == 'treating' ||
      maturityPercent >= 90;
  return RepaintBoundary(
    child: Builder(
    builder: (context) {
      final camera = MapCamera.maybeOf(context);
      final rawZoom = camera?.zoom ?? 18.0;
      // Zoom'u 0.25 birime yuvarla — kamera her küçük zoom değişikliğinde
      // 200+ marker yeniden rasterize edilmesin, ama büyüme yine de akıcı görünsün.
      final currentZoom = (rawZoom * 4.0).round() / 4.0;
      final currentRotation = camera?.rotation ?? 0.0;

      // Harita zoom seviyesine göre büyüme çarpanı.
      // zoom 18 referans alınarak (2^(zoom-18)), crop'lar harita büyüklüğüne kitlenir.
      // Aralık (0.4, 4.0) — uzaklaştıkça okunabilir kalır, yakınlaştıkça gerçekten büyür.
      double zoomScale = math.pow(2.0, currentZoom - 18.0).toDouble();
      zoomScale = zoomScale.clamp(0.4, 4.0).toDouble();

      final phase = getGrowthPhase(maturityPercent);
      final phaseScale = _getScaleMultiplier(phase);

      const double baseWidth = 54;
      const double baseHeight = 62;

      final double spriteW = baseWidth * phaseScale * zoomScale;
      final double spriteH = baseHeight * phaseScale * zoomScale;

      // ── PNG rendering — önce .png dene, bulamazsa .jpg'ye düş ────────────
      final assetPath = _getAssetPath(cropName);
      final pngPath = assetPath.endsWith('.jpg')
          ? assetPath.replaceAll('.jpg', '.png')
          : assetPath;
      final jpgPath = assetPath.endsWith('.png')
          ? assetPath.replaceAll('.png', '.jpg')
          : assetPath;

      Widget buildSpriteImage() {
        final devicePixelRatio =
            MediaQuery.maybeDevicePixelRatioOf(context) ?? 1.0;
        // Floor 36 → uzaklaştığında bile sprite supersampling ile keskin kalır.
        // Ceiling 1024/1280 → yakınlaştığında büyüyen sprite pikselleşmez.
        final cacheW =
            (spriteW * devicePixelRatio).round().clamp(36, 1024).toInt();
        final cacheH =
            (spriteH * devicePixelRatio).round().clamp(36, 1280).toInt();
        return Image.asset(
          pngPath,
          width: spriteW,
          height: spriteH,
          fit: BoxFit.contain,
          cacheWidth: cacheW,
          cacheHeight: cacheH,
          filterQuality: FilterQuality.high,
          isAntiAlias: true,
          gaplessPlayback: true,
          errorBuilder: (_, __, ___) => Image.asset(
            jpgPath,
            width: spriteW,
            height: spriteH,
            fit: BoxFit.contain,
            cacheWidth: cacheW,
            cacheHeight: cacheH,
            filterQuality: FilterQuality.high,
            isAntiAlias: true,
            gaplessPlayback: true,
            errorBuilder: (_, __, ___) => const SizedBox.shrink(),
          ),
        );
      }

      final sprite = buildSpriteImage();
      final facingYaw = _softenYaw(
        _facingYawForCameraRadians(facingDirection, currentRotation),
      );

      // Hafif yol: vurgulu/hasta/hasat-aşamasındaki olmayan markerlar için
      // ColorFilter.matrix ve TweenAnimationBuilder devreye sokulmuyor.
      // Bu yüzlerce markerın her kamera hareketinde repaint maliyetini düşürür.
      Widget orientLayer(Widget child) {
        if (!needsRichEffects) {
          return Transform(
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.0014)
              ..rotateY(facingYaw),
            alignment: Alignment.bottomCenter,
            child: child,
          );
        }
        return TweenAnimationBuilder<double>(
          tween: Tween<double>(end: facingYaw),
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
          child: child,
          builder: (_, yaw, layerChild) {
            final rearRatio = ((-math.cos(yaw)).clamp(0.0, 1.0)).toDouble();
            final brightness = 1.08 - (rearRatio * 0.24);
            final saturation = 1.12 - (rearRatio * 0.12);
            final filteredChild = ColorFiltered(
              colorFilter: ColorFilter.matrix([
                brightness * saturation,
                0,
                0,
                0,
                4 + rearRatio * 10,
                0,
                brightness,
                0,
                0,
                6 + rearRatio * 8,
                0,
                0,
                brightness * saturation,
                0,
                2 - rearRatio * 4,
                0,
                0,
                0,
                1,
                0,
              ]),
              child: layerChild!,
            );
            return Transform(
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.0014)
                ..rotateY(yaw),
              alignment: Alignment.bottomCenter,
              child: filteredChild,
            );
          },
        );
      }

      Widget spriteSlice({
        required double top,
        required double height,
      }) {
        return SizedBox(
          width: spriteW,
          height: height,
          child: ClipRect(
            child: Transform.translate(
              offset: Offset(0, -top),
              child: SizedBox(
                width: spriteW,
                height: spriteH,
                child: buildSpriteImage(),
              ),
            ),
          ),
        );
      }

      final layeredFacing = _usesLayeredFacing(cropName, assetPath);
      final headCut = spriteH * 0.58;
      final bodyTop = spriteH * 0.46;
      final baseOrientedSprite = layeredFacing
          ? SizedBox(
              width: spriteW,
              height: spriteH,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    top: bodyTop,
                    child: spriteSlice(
                      top: bodyTop,
                      height: spriteH - bodyTop,
                    ),
                  ),
                  Positioned(
                    top: 0,
                    child: orientLayer(
                      spriteSlice(
                        top: 0,
                        height: headCut,
                      ),
                    ),
                  ),
                ],
              ),
            )
          : orientLayer(sprite);

      // ── Sağlık durumu rozeti — kritik UX, çiftçi haritada hangi bitkinin
      // hasta/cansız olduğunu tek bakışta görmeli. Renk kodu:
      // kırmızı=hasta, turuncu=tedavi ediliyor, gri=cansız.
      Widget? healthBadge;
      if (healthStatus == 'diseased' || healthStatus == 'dead' || healthStatus == 'treating') {
        final badgeColor = switch (healthStatus) {
          'diseased' => const Color(0xFFD32F2F),
          'treating' => const Color(0xFFE67E22),
          'dead' => const Color(0xFF424242),
          _ => const Color(0xFFD32F2F),
        };
        final badgeIcon = switch (healthStatus) {
          'diseased' => Icons.priority_high_rounded,
          'treating' => Icons.medication_rounded,
          'dead' => Icons.close_rounded,
          _ => Icons.priority_high_rounded,
        };
            
        // Rozet boyutunu da zoom ile hafifçe ölçeklendir, ancak çok küçülmesini engelle
        final badgeSize = (18.0 * zoomScale).clamp(12.0, 24.0);
        
        healthBadge = IgnorePointer(
          child: Container(
              width: badgeSize,
              height: badgeSize,
              decoration: BoxDecoration(
                color: badgeColor,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: (badgeSize * 0.1).clamp(1.0, 2.0)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.4),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Icon(
                badgeIcon,
                size: badgeSize * 0.7,
                color: Colors.white,
              ),
          ),
        );
      }

      final orientedSprite = SizedBox(
        width: spriteW,
        height: spriteH,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.bottomCenter,
          children: [
            baseOrientedSprite,
            if (healthBadge != null)
              Positioned(
                bottom: spriteH * 0.5, // Bitkinin tam ortası hizası
                right: -(18.0 * zoomScale).clamp(12.0, 24.0) * 0.2, // Hafifçe dışarı taşsın
                child: healthBadge,
              ),
          ],
        ),
      );

      final statusSemantics = switch (healthStatus) {
        'diseased' => diseaseType?.trim().isNotEmpty == true
            ? ', hastalık belirtisi: $diseaseType'
            : ', hastalık belirtisi var',
        'dead' => ', bitki cansız',
        _ => '',
      };
      final harvestMarkerScale =
          phase == GrowthPhase.harvest ? 1.0 + (harvestPulse * 0.03) : 1.0;

      // PNG sprite — taban (bottom-center) tam zemine oturur. Gölge/kök yok.
      final marker = Semantics(
        label: cropName.trim().isEmpty ? null : '$cropName$statusSemantics',
        child: SizedBox.expand(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Transform.scale(
              scale: harvestMarkerScale,
              alignment: Alignment.bottomCenter,
              child: orientedSprite,
            ),
          ),
        ),
      );

      // Vurgu olmayan markerda halo widget ağacını hiç oluşturma — sadece
      // boş yer tutucu döndür. AnimatedOpacity'nin opacity:0 ile bile
      // layer/composite maliyeti vardır.
      final highlightHalo = !isHighlighted
          ? const SizedBox.shrink()
          : IgnorePointer(
        child: AnimatedOpacity(
          opacity: isHighlighted ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 120),
          child: Container(
            width: (spriteW * 1.25).clamp(30.0, 92.0),
            height: (spriteH * 0.26).clamp(10.0, 28.0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.all(
                Radius.elliptical(
                  (spriteW * 1.25).clamp(30.0, 92.0),
                  (spriteH * 0.26).clamp(10.0, 28.0),
                ),
              ),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.9),
                width: 2.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: cropColor.withValues(alpha: 0.65),
                  blurRadius: 18,
                  spreadRadius: 3,
                ),
              ],
            ),
          ),
        ),
      );

      final labelBottom = (spriteH * 0.82).clamp(32.0, 108.0);
      final highlightLabel = !isHighlighted
          ? const SizedBox.shrink()
          : IgnorePointer(
        child: AnimatedOpacity(
          opacity: isHighlighted ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 120),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 118),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF0D1811).withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: cropColor.withValues(alpha: 0.85),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.35),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              cropName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      );

      final scaledMarker = isHighlighted
          ? AnimatedScale(
              scale: 1.16,
              duration: const Duration(milliseconds: 120),
              curve: Curves.easeOutCubic,
              alignment: Alignment.bottomCenter,
              child: marker,
            )
          : marker;
      final highlightedMarker = Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          if (isHighlighted) Positioned(bottom: 1, child: highlightHalo),
          scaledMarker,
          if (isHighlighted && cropName.trim().isNotEmpty)
            Positioned(bottom: labelBottom, child: highlightLabel),
        ],
      );

      if (onTap != null || onHover != null || onLongPress != null) {
        final hitWidth = (spriteW * 0.62).clamp(24.0, 76.0);
        final hitHeight = (spriteH * 0.96).clamp(32.0, 112.0);
        final preciseHitTarget = Positioned(
          bottom: 0,
          child: SizedBox(
            width: hitWidth,
            height: hitHeight,
            child: MouseRegion(
              cursor:
                  onTap == null ? MouseCursor.defer : SystemMouseCursors.click,
              onEnter: (_) => onHover?.call(true),
              onExit: (_) => onHover?.call(false),
              child: GestureDetector(
                onTap: onTap,
                onLongPress: onLongPress,
                behavior: HitTestBehavior.opaque,
                child: const SizedBox.expand(),
              ),
            ),
          ),
        );
        return Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.bottomCenter,
          children: [
            IgnorePointer(child: highlightedMarker),
            preciseHitTarget,
          ],
        );
      }
      return highlightedMarker;
    },
  ),
  );
}
