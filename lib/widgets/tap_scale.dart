import 'package:flutter/material.dart';
import '../services/haptic_service.dart';

/// Basmada nazikçe küçülen, bırakmada yaylanarak geri gelen animasyonlu sarmalayıcı.
/// Dokunmatik tepkiyi zenginleştirir — haptik + görsel feedback birlikte.
class TapScale extends StatefulWidget {
  const TapScale({
    super.key,
    required this.onTap,
    required this.child,
    this.scale = 0.95,
    this.haptic = true,
  });

  final VoidCallback? onTap;
  final Widget child;
  final double scale;
  final bool haptic;

  @override
  State<TapScale> createState() => _TapScaleState();
}

class _TapScaleState extends State<TapScale>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 90),
    reverseDuration: const Duration(milliseconds: 180),
    lowerBound: 0.0,
    upperBound: 1.0,
  );

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _onDown(TapDownDetails _) => _ctrl.forward();
  void _onUp(TapUpDetails _) => _ctrl.reverse();
  void _onCancel() => _ctrl.reverse();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.onTap == null ? null : _onDown,
      onTapUp: widget.onTap == null ? null : _onUp,
      onTapCancel: widget.onTap == null ? null : _onCancel,
      onTap: widget.onTap == null
          ? null
          : () {
              if (widget.haptic) HapticService.instance.light();
              widget.onTap!();
            },
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, child) {
          final s = 1.0 - (_ctrl.value * (1.0 - widget.scale));
          return Transform.scale(scale: s, child: child);
        },
        child: widget.child,
      ),
    );
  }
}
