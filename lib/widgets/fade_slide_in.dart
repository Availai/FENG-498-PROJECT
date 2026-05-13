/// Listeye girerken yumuşak fade + dikey kayma ile beliren çocuk.
///
/// Liste içinde [index] verilerek sırayla "stagger" giriş efekti elde edilir
/// ([index] başına +60 ms gecikme). Tek seferlik giriş animasyonu olarak
/// tasarlanmıştır — widget unmount/rebuild olmadığı sürece tekrarlanmaz.
library;

import 'package:flutter/material.dart';

class FadeSlideIn extends StatefulWidget {
  const FadeSlideIn({
    super.key,
    required this.child,
    this.index = 0,
    this.delayPerIndex = const Duration(milliseconds: 60),
    this.duration = const Duration(milliseconds: 340),
    this.offset = 14,
    this.curve = Curves.easeOutCubic,
  });

  final Widget child;
  final int index;
  final Duration delayPerIndex;
  final Duration duration;

  /// Başlangıç dikey ofset (px). Yukarıdan değil, biraz aşağıdan belirir.
  final double offset;
  final Curve curve;

  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: widget.duration);
    final delay = widget.delayPerIndex * widget.index;
    if (delay == Duration.zero) {
      _ctrl.forward();
    } else {
      Future.delayed(delay, () {
        if (mounted) _ctrl.forward();
      });
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, child) {
        final t = widget.curve.transform(_ctrl.value);
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, widget.offset * (1 - t)),
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}
