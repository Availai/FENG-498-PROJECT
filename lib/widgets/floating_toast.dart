import 'package:flutter/material.dart';

/// Overlay-tabanlı yüzen toast. SnackBar'ın yerine geçer — dalgalanan giriş
/// animasyonu, otomatik kaybolma, context bağımsız API.
enum ToastType { success, error, info, warning }

class AppToast {
  AppToast._();

  static void show(
    BuildContext context, {
    required String message,
    ToastType type = ToastType.info,
    Duration duration = const Duration(seconds: 3),
  }) {
    final overlay = Overlay.of(context, rootOverlay: true);
    final entry = OverlayEntry(
      builder: (_) => _ToastWidget(
        message: message,
        type: type,
        duration: duration,
      ),
    );
    overlay.insert(entry);
    Future.delayed(duration + const Duration(milliseconds: 350), () {
      if (entry.mounted) entry.remove();
    });
  }
}

class _ToastWidget extends StatefulWidget {
  const _ToastWidget({
    required this.message,
    required this.type,
    required this.duration,
  });

  final String message;
  final ToastType type;
  final Duration duration;

  @override
  State<_ToastWidget> createState() => _ToastWidgetState();
}

class _ToastWidgetState extends State<_ToastWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 300),
  );
  late final Animation<double> _slide = CurvedAnimation(
    parent: _c,
    curve: Curves.easeOutCubic,
  );

  @override
  void initState() {
    super.initState();
    _c.forward();
    Future.delayed(widget.duration, () {
      if (mounted) _c.reverse();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  ({Color bg, Color fg, IconData icon}) _styleFor(ToastType t) {
    switch (t) {
      case ToastType.success:
        return (bg: const Color(0xFF2E7D32), fg: Colors.white, icon: Icons.check_circle_rounded);
      case ToastType.error:
        return (bg: const Color(0xFFC62828), fg: Colors.white, icon: Icons.error_rounded);
      case ToastType.warning:
        return (bg: const Color(0xFFF57C00), fg: Colors.white, icon: Icons.warning_amber_rounded);
      case ToastType.info:
        return (bg: const Color(0xFF37474F), fg: Colors.white, icon: Icons.info_rounded);
    }
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final style = _styleFor(widget.type);
    return Positioned(
      top: mq.padding.top + 12,
      left: 16,
      right: 16,
      child: AnimatedBuilder(
        animation: _slide,
        builder: (context, child) {
          return Opacity(
            opacity: _slide.value,
            child: Transform.translate(
              offset: Offset(0, -30 * (1 - _slide.value)),
              child: child,
            ),
          );
        },
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: style.bg,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(style.icon, color: style.fg, size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.message,
                    style: TextStyle(
                      color: style.fg,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
