/// Randomized Interaction System — herhangi bir widget'a sarılınca her
/// tıklamada havuzdan rastgele bir "game feel" efekti tetikler.
///
/// Mimari:
///  - [InteractionEffectManager] — singleton; efekt havuzu, konfigürasyon
///    ve son seçilen efekti hatırlama (art arda aynı efektin tekrarını
///    engeller).
///  - [RandomEffectWrapper] — herhangi bir child'ı sarar; `onTap` ASLA
///    geciktirilmez: callback önce çağrılır, animasyon arka planda
///    paralel olarak başlar.
///  - 4 efekt: [InteractionEffect.bounceGlow], [InteractionEffect.rippleBurst],
///    [InteractionEffect.particlePop], [InteractionEffect.elasticShake].
///    Süreler 200-400 ms arası tutulur ve 60 FPS hedefiyle tasarlanır.
///  - Parçacık efekti widget sınırlarının dışına taşabilsin diye
///    [OverlayEntry] üzerinde çizilir.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
// EFFECT TYPES
// ─────────────────────────────────────────────────────────────────────────────

enum InteractionEffect {
  bounceGlow,
  rippleBurst,
  particlePop,
  elasticShake,
}

// ─────────────────────────────────────────────────────────────────────────────
// MANAGER — Singleton
// ─────────────────────────────────────────────────────────────────────────────

class InteractionEffectConfig {
  /// Aktif efekt havuzu. Sadece bunlardan rastgele seçilir.
  final List<InteractionEffect> enabledEffects;

  /// Parçacık ve parlama efektlerinde kullanılacak renkler.
  final List<Color> palette;

  /// 0.0 - 1.0 arası küresel yoğunluk çarpanı (büyüklük/parlaklık).
  final double intensity;

  /// `true` ise aynı efekt art arda iki kez seçilmez.
  final bool avoidRepeat;

  const InteractionEffectConfig({
    this.enabledEffects = const [
      InteractionEffect.bounceGlow,
      InteractionEffect.rippleBurst,
      InteractionEffect.particlePop,
      InteractionEffect.elasticShake,
    ],
    this.palette = const [
      Color(0xFF43A047), // emerald
      Color(0xFF81C784), // emeraldLight
      Color(0xFFE67E22), // warning
      Color(0xFF1976D2), // info
      Color(0xFFE8D48A), // wheat
    ],
    this.intensity = 1.0,
    this.avoidRepeat = true,
  });

  InteractionEffectConfig copyWith({
    List<InteractionEffect>? enabledEffects,
    List<Color>? palette,
    double? intensity,
    bool? avoidRepeat,
  }) {
    return InteractionEffectConfig(
      enabledEffects: enabledEffects ?? this.enabledEffects,
      palette: palette ?? this.palette,
      intensity: intensity ?? this.intensity,
      avoidRepeat: avoidRepeat ?? this.avoidRepeat,
    );
  }
}

class InteractionEffectManager {
  InteractionEffectManager._();
  static final InteractionEffectManager instance =
      InteractionEffectManager._();

  InteractionEffectConfig _config = const InteractionEffectConfig();
  final math.Random _rng = math.Random();
  InteractionEffect? _last;

  InteractionEffectConfig get config => _config;

  void configure(InteractionEffectConfig config) {
    _config = config;
  }

  /// Havuzdan rastgele bir efekt seçer. `avoidRepeat` aktifse son seçilenle
  /// aynı olanı atlar (havuzda en az 2 efekt varsa).
  InteractionEffect pickEffect() {
    final pool = _config.enabledEffects;
    if (pool.isEmpty) return InteractionEffect.bounceGlow;
    if (pool.length == 1) {
      _last = pool.first;
      return _last!;
    }
    InteractionEffect picked;
    var attempts = 0;
    do {
      picked = pool[_rng.nextInt(pool.length)];
      attempts++;
    } while (_config.avoidRepeat && picked == _last && attempts < 4);
    _last = picked;
    return picked;
  }

  Color pickColor() {
    final palette = _config.palette;
    if (palette.isEmpty) return Colors.white;
    return palette[_rng.nextInt(palette.length)];
  }

  double get intensity => _config.intensity.clamp(0.1, 2.0);
}

// ─────────────────────────────────────────────────────────────────────────────
// WRAPPER
// ─────────────────────────────────────────────────────────────────────────────

class RandomEffectWrapper extends StatefulWidget {
  const RandomEffectWrapper({
    super.key,
    required this.child,
    this.onTap,
    this.forceEffect,
    this.behavior = HitTestBehavior.opaque,
    this.borderRadius,
  });

  final Widget child;
  final VoidCallback? onTap;

  /// Belirli bir efekti zorlamak için kullanılır (debug/test için).
  final InteractionEffect? forceEffect;

  final HitTestBehavior behavior;

  /// Bounce & glow için clipler/glow kenar yumuşaklığı.
  final BorderRadius? borderRadius;

  @override
  State<RandomEffectWrapper> createState() => _RandomEffectWrapperState();
}

class _RandomEffectWrapperState extends State<RandomEffectWrapper>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  InteractionEffect _current = InteractionEffect.bounceGlow;
  Color _accent = const Color(0xFF43A047);
  OverlayEntry? _overlayEntry;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _ctrl.addStatusListener(_onStatus);
  }

  @override
  void dispose() {
    _ctrl.removeStatusListener(_onStatus);
    _ctrl.dispose();
    _removeOverlay();
    super.dispose();
  }

  void _onStatus(AnimationStatus s) {
    if (s == AnimationStatus.completed) {
      _removeOverlay();
    }
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _handleTap() {
    // 1) Kullanıcı callback'ini ASLA geciktirme.
    widget.onTap?.call();

    // 2) Efekti seç ve süreyi efekte göre ayarla.
    final picked =
        widget.forceEffect ?? InteractionEffectManager.instance.pickEffect();
    _accent = InteractionEffectManager.instance.pickColor();
    _current = picked;
    _ctrl.duration = _durationFor(picked);

    // 3) Parçacık efekti için Overlay aç — widget sınırlarını aşabilsin.
    _removeOverlay();
    if (picked == InteractionEffect.particlePop) {
      _spawnParticleOverlay();
    }

    // 4) Animasyonu sıfırdan başlat.
    _ctrl.forward(from: 0);
  }

  Duration _durationFor(InteractionEffect e) {
    switch (e) {
      case InteractionEffect.bounceGlow:
        return const Duration(milliseconds: 360);
      case InteractionEffect.rippleBurst:
        return const Duration(milliseconds: 380);
      case InteractionEffect.particlePop:
        return const Duration(milliseconds: 400);
      case InteractionEffect.elasticShake:
        return const Duration(milliseconds: 280);
    }
  }

  void _spawnParticleOverlay() {
    final renderBox = context.findRenderObject() as RenderBox?;
    final overlay = Overlay.maybeOf(context);
    if (renderBox == null || overlay == null) return;

    final origin = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;
    final intensity = InteractionEffectManager.instance.intensity;
    final particles = _ParticleSpec.generate(
      count: 5,
      palette: InteractionEffectManager.instance.config.palette,
      intensity: intensity,
    );

    _overlayEntry = OverlayEntry(
      builder: (_) => Positioned(
        left: origin.dx,
        top: origin.dy,
        width: size.width,
        height: size.height,
        child: IgnorePointer(
          child: AnimatedBuilder(
            animation: _ctrl,
            builder: (_, __) {
              return CustomPaint(
                painter: _ParticleBurstPainter(
                  t: _ctrl.value,
                  size: size,
                  particles: particles,
                ),
              );
            },
          ),
        ),
      ),
    );
    overlay.insert(_overlayEntry!);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: widget.behavior,
      onTap: _handleTap,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, child) {
          final t = _ctrl.value;
          switch (_current) {
            case InteractionEffect.bounceGlow:
              return _bounceGlow(t, child!);
            case InteractionEffect.elasticShake:
              return _elasticShake(t, child!);
            case InteractionEffect.rippleBurst:
              return _rippleBurst(t, child!);
            case InteractionEffect.particlePop:
              return child!;
          }
        },
        child: widget.child,
      ),
    );
  }

  // ─── Effect: Bounce & Glow ─────────────────────────────────────────────
  Widget _bounceGlow(double t, Widget child) {
    if (t == 0) return child;
    // Önce hafifçe küçül (0..0.35), sonra elastik şişip 1.0'a yerleş.
    final scale = t < 0.35
        ? 1.0 - 0.06 * (t / 0.35)
        : 0.94 + 0.12 * _easeOutBack((t - 0.35) / 0.65);
    // Parlama 0..0.5 zirve, sonra söner.
    final glow = (t < 0.5 ? t / 0.5 : 1.0 - (t - 0.5) / 0.5)
        .clamp(0.0, 1.0) *
        InteractionEffectManager.instance.intensity;
    final radius = widget.borderRadius ??
        const BorderRadius.all(Radius.circular(12));
    return Transform.scale(
      scale: scale,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: radius,
          boxShadow: [
            BoxShadow(
              color: _accent.withValues(alpha: 0.55 * glow),
              blurRadius: 18 * glow + 4,
              spreadRadius: 1.5 * glow,
            ),
          ],
        ),
        child: child,
      ),
    );
  }

  // ─── Effect: Elastic Shake ─────────────────────────────────────────────
  Widget _elasticShake(double t, Widget child) {
    if (t == 0) return child;
    // Hızlı sönen sinüs salınımı (~3 tam tur).
    final decay = 1.0 - t;
    final dx = math.sin(t * math.pi * 6) *
        4.5 *
        decay *
        InteractionEffectManager.instance.intensity;
    return Transform.translate(offset: Offset(dx, 0), child: child);
  }

  // ─── Effect: Ripple Burst ──────────────────────────────────────────────
  Widget _rippleBurst(double t, Widget child) {
    if (t == 0) return child;
    return CustomPaint(
      foregroundPainter: _RippleBurstPainter(
        t: t,
        color: _accent,
        intensity: InteractionEffectManager.instance.intensity,
      ),
      child: child,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CURVES & HELPERS
// ─────────────────────────────────────────────────────────────────────────────

double _easeOutBack(double t) {
  // Elastik geri sıçrama — ufak overshoot.
  const c1 = 1.70158;
  const c3 = c1 + 1;
  final x = t - 1;
  return 1 + c3 * x * x * x + c1 * x * x;
}

// ─────────────────────────────────────────────────────────────────────────────
// PAINTERS
// ─────────────────────────────────────────────────────────────────────────────

class _RippleBurstPainter extends CustomPainter {
  _RippleBurstPainter({
    required this.t,
    required this.color,
    required this.intensity,
  });

  final double t;
  final Color color;
  final double intensity;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxR = math.max(size.width, size.height) * 0.95;
    // 3 halka — her biri farklı fazda başlar.
    for (var i = 0; i < 3; i++) {
      final phase = (t - i * 0.12).clamp(0.0, 1.0);
      if (phase <= 0 || phase >= 1) continue;
      final r = maxR * phase * (0.7 + intensity * 0.3);
      final alpha = (1 - phase) * 0.55;
      final paint = Paint()
        ..color = color.withValues(alpha: alpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5 * (1 - phase) + 0.8;
      canvas.drawCircle(center, r, paint);
    }
  }

  @override
  bool shouldRepaint(_RippleBurstPainter old) =>
      old.t != t || old.color != color || old.intensity != intensity;
}

class _ParticleSpec {
  _ParticleSpec({
    required this.angle,
    required this.distance,
    required this.size,
    required this.color,
    required this.rotation,
  });

  final double angle; // radyan
  final double distance; // px
  final double size; // px
  final Color color;
  final double rotation;

  static List<_ParticleSpec> generate({
    required int count,
    required List<Color> palette,
    required double intensity,
  }) {
    final rng = math.Random();
    final colors = palette.isEmpty ? const [Colors.white] : palette;
    return List.generate(count, (i) {
      final base = (2 * math.pi / count) * i;
      final jitter = (rng.nextDouble() - 0.5) * 0.8;
      return _ParticleSpec(
        angle: base + jitter,
        distance: (28 + rng.nextDouble() * 22) * intensity,
        size: 4 + rng.nextDouble() * 3,
        color: colors[rng.nextInt(colors.length)],
        rotation: rng.nextDouble() * math.pi,
      );
    });
  }
}

class _ParticleBurstPainter extends CustomPainter {
  _ParticleBurstPainter({
    required this.t,
    required this.size,
    required this.particles,
  });

  final double t;
  final Size size;
  final List<_ParticleSpec> particles;

  @override
  void paint(Canvas canvas, Size canvasSize) {
    if (t == 0) return;
    final center = Offset(size.width / 2, size.height / 2);
    final eased = Curves.easeOutCubic.transform(t);
    final alpha = (1 - t).clamp(0.0, 1.0);

    for (final p in particles) {
      final d = p.distance * eased;
      final dx = math.cos(p.angle) * d;
      final dy = math.sin(p.angle) * d - (8 * t); // hafif yukarı yer çekimi
      final offset = center + Offset(dx, dy);

      final paint = Paint()..color = p.color.withValues(alpha: alpha);
      final scale = (1 - t * 0.5).clamp(0.3, 1.0);
      final r = p.size * scale;

      canvas.save();
      canvas.translate(offset.dx, offset.dy);
      canvas.rotate(p.rotation + t * math.pi);
      // Yuvarlak köşeli küçük kare → konfeti hissi.
      final rect = Rect.fromCenter(
        center: Offset.zero,
        width: r * 2,
        height: r * 2,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, Radius.circular(r * 0.4)),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ParticleBurstPainter old) => old.t != t;
}
