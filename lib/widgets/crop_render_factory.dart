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

/// Bitki yönü seçimi şimdilik uygulamadan kaldırıldı.
/// Eski kayıtlar `facingDirection` taşısa bile haritada yön oku gösterilmez.
bool _hasFacingDirection(String? directionKey) => false;

String _facingDirectionSemanticLabel(String? directionKey) {
  final degrees = _facingDegrees(directionKey).round() % 360;
  return switch (degrees) {
    0 => 'kuzeye',
    45 => 'kuzeydoğuya',
    90 => 'doğuya',
    135 => 'güneydoğuya',
    180 => 'güneye',
    225 => 'güneybatıya',
    270 => 'batıya',
    315 => 'kuzeybatıya',
    _ => '$degrees derece yönüne',
  };
}

Widget _buildFacingArrow({
  required String? facingDirection,
  required double cameraRotationDegrees,
  required double zoomScale,
}) {
  // facingDirection null/empty olduğunda _facingDegrees 180° (güney) döner —
  // Türkiye için kuzey yarımkürede güneye bakış varsayılan yetiştirme yönüdür.
  final screenDegrees =
      (_facingDegrees(facingDirection) + cameraRotationDegrees) % 360.0;
  final arrowSize = (52.0 * zoomScale).clamp(16.0, 86.0).toDouble();
  final strokeWidth = (2.7 * zoomScale).clamp(1.0, 4.6).toDouble();

  return IgnorePointer(
    child: Semantics(
      label:
          'Bitkinin baktığı yön: ${_facingDirectionSemanticLabel(facingDirection)}',
      child: Transform.rotate(
        angle: screenDegrees * math.pi / 180.0,
        child: CustomPaint(
          key: const ValueKey<String>('crop-facing-surface-arrow'),
          size: Size.square(arrowSize),
          painter: _FacingSurfaceArrowPainter(strokeWidth: strokeWidth),
        ),
      ),
    ),
  );
}

class _FacingSurfaceArrowPainter extends CustomPainter {
  const _FacingSurfaceArrowPainter({required this.strokeWidth});

  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final fill = const Color(0xFFF2F4F0);
    final edge = const Color(0xFF4E5951);
    final baseCenter = Offset(size.width * 0.5, size.height * 0.62);
    final tip = Offset(size.width * 0.5, size.height * 0.12);
    final tail = Offset(size.width * 0.5, size.height * 0.78);
    final headWidth = size.width * 0.14;
    final headHeight = size.height * 0.17;

    final surfacePaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.12)
      ..style = PaintingStyle.fill;
    final surfaceBorderPaint = Paint()
      ..color = fill.withValues(alpha: 0.22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = (strokeWidth * 0.55).clamp(1.2, 2.4);

    final surfaceOval = Rect.fromCenter(
      center: baseCenter,
      width: size.width * 0.76,
      height: size.height * 0.26,
    );
    canvas.drawOval(surfaceOval, surfacePaint);
    canvas.drawOval(surfaceOval, surfaceBorderPaint);

    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.30)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = strokeWidth + 2.0;
    final shaftPaint = Paint()
      ..color = fill.withValues(alpha: 0.86)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = strokeWidth;
    final edgePaint = Paint()
      ..color = edge.withValues(alpha: 0.58)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = (strokeWidth * 0.36).clamp(0.8, 1.6);

    canvas.drawLine(
        tail + const Offset(0, 1.4), tip + const Offset(0, 1.4), shadowPaint);
    canvas.drawLine(tail, tip, shaftPaint);
    canvas.drawLine(tail, tip, edgePaint);

    final headPath = Path()
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(tip.dx - headWidth, tip.dy + headHeight)
      ..lineTo(tip.dx + headWidth, tip.dy + headHeight)
      ..close();
    canvas.drawPath(headPath.shift(const Offset(0, 1.4)), shadowPaint);
    canvas.drawPath(
      headPath,
      Paint()
        ..color = fill.withValues(alpha: 0.86)
        ..style = PaintingStyle.fill,
    );
    canvas.drawPath(
      headPath,
      Paint()
        ..color = edge.withValues(alpha: 0.42)
        ..style = PaintingStyle.stroke
        ..strokeWidth = (strokeWidth * 0.34).clamp(0.8, 1.4),
    );

    canvas.drawCircle(
      tail,
      (strokeWidth * 1.05).clamp(2.0, 5.0),
      Paint()..color = fill.withValues(alpha: 0.58),
    );
  }

  @override
  bool shouldRepaint(covariant _FacingSurfaceArrowPainter oldDelegate) {
    return oldDelegate.strokeWidth != strokeWidth;
  }
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
  bool isHovered = false,
  ValueChanged<bool>? onHover,
  VoidCallback? onTap,
  VoidCallback? onLongPress,
  String?
      facingDirection, // 'north' | 'northeast' | 'deg:180' | null. Yüzey oku için kullanılır.
}) {
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
        // Aralık geniş tutulur: uzaklaşınca gerçekten küçülür, yakınlaşınca
        // marker kutusunu taşırmadan büyür.
        double zoomScale = math.pow(2.0, currentZoom - 18.0).toDouble();
        // Geniş aralık: uzakta gerçekten küçülsün, yakında tarlayı boğmasın.
        zoomScale = zoomScale.clamp(0.18, 2.4).toDouble();

        final phase = getGrowthPhase(maturityPercent);
        final phaseScale = _getScaleMultiplier(phase);

        // Taban boyutu küçültüldü (54→38, 62→44): yakın görünümde bitkiler
        // birbirine yapışmasın, tarla deseni okunabilir kalsın.
        const double baseWidth = 38;
        const double baseHeight = 44;

        final double spriteW = baseWidth * phaseScale * zoomScale;
        final double spriteH = baseHeight * phaseScale * zoomScale;

        // LOD eşiği: bu değerin altında fotoğraf yerine stilize "yaprak dane"
        // simgesi çizilir — uzaktan net, temiz ve tarlaya doğal görünür.
        final bool useLowLod = zoomScale < 0.55;

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
          final photo = Image.asset(
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
          // Satellite imagery üstünde fotoğrafın okunabilirliği için ince
          // beyaz halo + hafif drop shadow. Marker fotoyu kesmesin diye
          // shadow blur sprite kutusunun dışına taşar (Stack clipBehavior
          // none olarak ayarlandı).
          return DecoratedBox(
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.28),
                  blurRadius: 6,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: photo,
          );
        }

        // ── LOD: uzak görünüm için stilize "yaprak-dane" simgesi ─────────
        // Fotoğraflar 20px altında bulaşır; bunun yerine ürün renginde net,
        // çiftçi dostu vektör simge çiziyoruz. Aynı sprite yerleşim kutusu
        // kullanılır, böylece tıklama hedefleri ve hizalama değişmez.
        Widget buildLowLodSprite() {
          final dotSize = math.min(spriteW, spriteH * 0.85);
          return Center(
            child: CustomPaint(
              size: Size(dotSize, dotSize),
              painter: _StylizedCropDotPainter(
                color: cropColor,
                growthPhase: phase,
              ),
            ),
          );
        }

        final sprite = useLowLod ? buildLowLodSprite() : buildSpriteImage();

        // ── Toprak gölgesi — bitki "havada" değil "ekili" görünsün ───────
        // Sprite altında yumuşak elips, zemine oturma hissi verir.
        final shadowW = spriteW * 0.78;
        final shadowH = (spriteH * 0.14).clamp(2.5, 14.0);
        final groundShadow = IgnorePointer(
          child: Container(
            width: shadowW,
            height: shadowH,
            decoration: BoxDecoration(
              borderRadius:
                  BorderRadius.all(Radius.elliptical(shadowW, shadowH)),
              gradient: RadialGradient(
                colors: [
                  Colors.black.withValues(alpha: 0.42),
                  Colors.black.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        );
        final hasFacingDirection = _hasFacingDirection(facingDirection);

        // ── Sağlık durumu rozeti — kritik UX, çiftçi haritada hangi bitkinin
        // hasta/cansız olduğunu tek bakışta görmeli. Renk kodu:
        // kırmızı=hasta, turuncu=tedavi ediliyor, gri=cansız.
        Widget? healthBadge;
        if (healthStatus == 'diseased' ||
            healthStatus == 'dead' ||
            healthStatus == 'treating') {
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
                border: Border.all(
                    color: Colors.white,
                    width: (badgeSize * 0.1).clamp(1.0, 2.0)),
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
              // Toprak gölgesi — sprite tabanına oturur, "ekili" hissi verir.
              Positioned(
                bottom: -(shadowH * 0.3),
                child: groundShadow,
              ),
              sprite,
              if (hasFacingDirection)
                Positioned(
                  bottom: (spriteH * 0.02).clamp(0.0, 6.0),
                  child: _buildFacingArrow(
                    facingDirection: facingDirection,
                    cameraRotationDegrees: currentRotation,
                    zoomScale: zoomScale,
                  ),
                ),
              if (healthBadge != null)
                Positioned(
                  bottom: spriteH * 0.5, // Bitkinin tam ortası hizası
                  right: -(18.0 * zoomScale).clamp(12.0, 24.0) *
                      0.2, // Hafifçe dışarı taşsın
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
        final directionSemantics = hasFacingDirection
            ? ', ${_facingDirectionSemanticLabel(facingDirection)} bakıyor'
            : '';
        final harvestMarkerScale =
            phase == GrowthPhase.harvest ? 1.0 + (harvestPulse * 0.03) : 1.0;

        // PNG sprite — taban (bottom-center) tam zemine oturur. Gölge/kök yok.
        final marker = Semantics(
          label: cropName.trim().isEmpty
              ? null
              : '$cropName$statusSemantics$directionSemantics',
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
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
            if (isHighlighted) Positioned(bottom: 1, child: highlightHalo),
            isHovered
                ? AnimatedScale(
                    scale: 1.08,
                    duration: const Duration(milliseconds: 120),
                    curve: Curves.easeOutCubic,
                    alignment: Alignment.bottomCenter,
                    child: marker,
                  )
                : marker,
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
                cursor: onTap == null
                    ? MouseCursor.defer
                    : SystemMouseCursors.click,
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

/// Uzak görünüm (LOD) için stilize "yaprak-dane" simgesi.
/// Fotoğraf 20px altında bulaşır; bu painter ürün renginde temiz bir
/// silüet çizer: toprak halkası + yaprak/meyve şekli + beyaz outline.
/// Olgunluk evresine göre renk doygunluğu ve dane sayısı değişir, böylece
/// uzaktan bakıldığında bile bitkinin durumu okunabilir.
class _StylizedCropDotPainter extends CustomPainter {
  const _StylizedCropDotPainter({
    required this.color,
    required this.growthPhase,
  });

  final Color color;
  final GrowthPhase growthPhase;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = math.min(size.width, size.height) / 2;

    // Olgunluk renkleri: fide→açık yeşil, büyüme→canlı yeşil,
    // olgun→koyun yeşil, hasat→ürün rengi (sarı/kırmızı vb).
    final base = switch (growthPhase) {
      GrowthPhase.seedling => const Color(0xFFA8D982),
      GrowthPhase.growing => const Color(0xFF66BB6A),
      GrowthPhase.mature => const Color(0xFF2E7D32),
      GrowthPhase.harvest => color,
    };
    final highlight = Color.lerp(base, Colors.white, 0.35) ?? base;
    final shade = Color.lerp(base, Colors.black, 0.32) ?? base;

    // 1) Beyaz outline halo — satellite zeminde okunabilirlik
    final haloPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.85)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(cx, cy), r * 0.95, haloPaint);

    // 2) Dış koyu çerçeve — temiz silüet kenarı
    final ringPaint = Paint()
      ..color = shade.withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(0.8, r * 0.08);
    canvas.drawCircle(Offset(cx, cy), r * 0.88, ringPaint);

    // 3) Bitki gövdesi — radial gradient ile hacim hissi
    final bodyRect = Rect.fromCircle(center: Offset(cx, cy), radius: r * 0.82);
    final bodyPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.25, -0.35),
        radius: 1.0,
        colors: [highlight, base, shade],
        stops: const [0.0, 0.55, 1.0],
      ).createShader(bodyRect);
    canvas.drawCircle(Offset(cx, cy), r * 0.82, bodyPaint);

    // 4) Yaprak çentiği — bitki silüeti hissi (basit "V" üstte)
    final leafPaint = Paint()
      ..color = highlight.withValues(alpha: 0.85)
      ..style = PaintingStyle.fill;
    final leafPath = Path()
      ..moveTo(cx, cy - r * 0.78)
      ..quadraticBezierTo(
          cx + r * 0.32, cy - r * 0.55, cx + r * 0.12, cy - r * 0.18)
      ..quadraticBezierTo(cx, cy - r * 0.32, cx - r * 0.12, cy - r * 0.18)
      ..quadraticBezierTo(cx - r * 0.32, cy - r * 0.55, cx, cy - r * 0.78)
      ..close();
    canvas.drawPath(leafPath, leafPaint);

    // 5) Hasat evresinde küçük meyve/dane noktası — uzaktan bile "olgun"
    if (growthPhase == GrowthPhase.harvest) {
      final fruitPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.9)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(
          Offset(cx + r * 0.18, cy + r * 0.05), r * 0.16, fruitPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _StylizedCropDotPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.growthPhase != growthPhase;
  }
}
