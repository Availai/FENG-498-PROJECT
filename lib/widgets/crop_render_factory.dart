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

double _facingYawRadians(String? directionKey) {
  final degrees = _facingDegrees(directionKey);
  final delta = ((degrees - 180.0 + 540.0) % 360.0) - 180.0;
  return delta * math.pi / 180.0;
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

      const double baseWidth =
          42; // Görselde çok devasa durduğu için yarıya indirdim
      const double baseHeight = 48;

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
        return Image.asset(
          pngPath,
          width: spriteW,
          height: spriteH,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.high,
          errorBuilder: (_, __, ___) => Image.asset(
            jpgPath,
            width: spriteW,
            height: spriteH,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
            errorBuilder: (_, __, ___) => const SizedBox.shrink(),
          ),
        );
      }

      final sprite = buildSpriteImage();
      final facingYaw = _facingYawRadians(facingDirection);

      Widget orientLayer(Widget child) {
        return TweenAnimationBuilder<double>(
          tween: Tween<double>(end: facingYaw),
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
          child: child,
          builder: (_, yaw, layerChild) {
            final rearRatio = ((-math.cos(yaw)).clamp(0.0, 1.0)).toDouble();
            final brightness = 1.0 - (rearRatio * 0.34);
            final saturation = 1.0 - (rearRatio * 0.22);
            final filteredChild = ColorFiltered(
              colorFilter: ColorFilter.matrix([
                brightness * saturation,
                0,
                0,
                0,
                rearRatio * 18,
                0,
                brightness,
                0,
                0,
                rearRatio * 10,
                0,
                0,
                brightness * saturation,
                0,
                -rearRatio * 8,
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
      final orientedSprite = layeredFacing
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
      final showGroundContact = currentZoom >= 16.0;
      final double rootLockW = spriteW * 0.24;
      final double rootLockH = (spriteH * 0.055).clamp(2.0, 8.0);
      final double rootPinW = (spriteW * 0.055).clamp(2.0, 4.5);
      final double rootPinH = (spriteH * 0.16).clamp(7.0, 18.0);
      final rootPin = Container(
        width: rootPinW,
        height: rootPinH,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(rootPinW),
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF6E6A22),
              Color(0xFF5B3A1F),
              Color(0xFF2D1A0F),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.22),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
      );
      final double rootMoundW = spriteW * 0.36;
      final double rootMoundH = (spriteH * 0.09).clamp(4.0, 12.0);
      final rootMound = Container(
        width: rootMoundW,
        height: rootMoundH,
        decoration: BoxDecoration(
          borderRadius:
              BorderRadius.all(Radius.elliptical(rootMoundW, rootMoundH)),
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 0.72,
            colors: [
              const Color(0xFF2D1A0F).withValues(alpha: 0.82),
              const Color(0xFF4A2D18).withValues(alpha: 0.56),
              const Color(0xFF4A2D18).withValues(alpha: 0.0),
            ],
            stops: const [0.0, 0.58, 1.0],
          ),
        ),
      );
      final rootLock = Container(
        width: rootLockW,
        height: rootLockH,
        decoration: BoxDecoration(
          borderRadius:
              BorderRadius.all(Radius.elliptical(rootLockW, rootLockH)),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF6B4728).withValues(alpha: 0.0),
              const Color(0xFF4A2D18).withValues(alpha: 0.62),
              const Color(0xFF2D1A0F).withValues(alpha: 0.82),
            ],
            stops: const [0.0, 0.45, 1.0],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.16),
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ],
        ),
      );

      // PNG bitki: TABANI marker'ın alt kenarına yapışır. Dış Marker
      // `Alignment.topCenter` ile bu kenar lat/lng zeminine oturur.
      final marker = Transform(
        transform: Matrix4.identity()..rotateX(0.95),
        alignment: Alignment.bottomCenter,
        child: SizedBox.expand(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: SizedBox(
              width: spriteW,
              height: spriteH,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.bottomCenter,
                children: [
                  // 1. Toprak dairesi (zemin) — bitkinin altına denk gelir
                  if (showGroundContact)
                    Positioned(
                      bottom: 0,
                      child: soilDisc,
                    ),
                  // 2. Gölge: toprağın üstünde hafif kararma
                  if (showGroundContact)
                    Positioned(
                      bottom: 0,
                      child: groundShadow,
                    ),
                  // 3. Bitki: tabanı zemin çizgisinde
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: orientedSprite,
                  ),
                  if (showGroundContact)
                    Positioned(
                      bottom: 0,
                      child: rootPin,
                    ),
                  if (showGroundContact)
                    Positioned(
                      bottom: 0,
                      child: rootMound,
                    ),
                  if (showGroundContact)
                    Positioned(
                      bottom: rootMoundH * 0.24,
                      child: rootLock,
                    ),
                  // 4. Sağlık badge'i — hasta/ölü işaretlenmiş bitkilerde
                  // sağ-üst köşede ünlem (kırmızı) veya X (siyah).
                  if (healthStatus == 'diseased' || healthStatus == 'dead')
                    Positioned(
                      top: 0,
                      right: 0,
                      child: _HealthBadge(
                        status: healthStatus!,
                        diameter: (spriteW * 0.32).clamp(10.0, 18.0),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      );

      final highlightHalo = IgnorePointer(
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
      final highlightLabel = IgnorePointer(
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

      final highlightedMarker = Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          Positioned(bottom: 1, child: highlightHalo),
          AnimatedScale(
            scale: isHighlighted ? 1.16 : 1.0,
            duration: const Duration(milliseconds: 120),
            curve: Curves.easeOutCubic,
            alignment: Alignment.bottomCenter,
            child: marker,
          ),
          if (cropName.trim().isNotEmpty)
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
  );
}

/// Hasta/ölü bitkinin sağ-üst köşesine yapıştırılan küçük gösterge.
/// Tasarım: kırmızı/siyah dolgulu daire + beyaz kenarlık + içinde ikon.
/// Boyut zoom ile birlikte ölçeklenir (10–18px).
class _HealthBadge extends StatelessWidget {
  const _HealthBadge({required this.status, required this.diameter});

  final String status;
  final double diameter;

  @override
  Widget build(BuildContext context) {
    final isDead = status == 'dead';
    final color = isDead ? const Color(0xFF1A1A1A) : const Color(0xFFD32F2F);
    final icon = isDead ? Icons.close_rounded : Icons.priority_high_rounded;
    return Container(
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.45),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Icon(icon, color: Colors.white, size: diameter * 0.7),
    );
  }
}
