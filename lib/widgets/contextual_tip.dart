import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../theme/app_theme.dart';

class ActionTipData {
  final String? id;
  final IconData icon;
  final Color color;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const ActionTipData({
    this.id,
    required this.icon,
    required this.color,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });
}

class ActionTipCard extends StatefulWidget {
  final String? id;
  final IconData icon;
  final Color color;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool dismissible;
  final bool dark;
  final bool compact;
  final EdgeInsetsGeometry margin;

  const ActionTipCard({
    super.key,
    this.id,
    required this.icon,
    required this.color,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.dismissible = true,
    this.dark = false,
    this.compact = false,
    this.margin = EdgeInsets.zero,
  });

  ActionTipCard.fromData(
    ActionTipData tip, {
    super.key,
    bool? dismissible,
    this.dark = false,
    this.compact = false,
    this.margin = EdgeInsets.zero,
  })  : id = tip.id,
        icon = tip.icon,
        color = tip.color,
        title = tip.title,
        message = tip.message,
        actionLabel = tip.actionLabel,
        onAction = tip.onAction,
        dismissible = dismissible ?? tip.id != null;

  @override
  State<ActionTipCard> createState() => _ActionTipCardState();
}

class _ActionTipCardState extends State<ActionTipCard> {
  bool _hidden = false;

  String get _storageKey => 'action_tip_dismissed_${widget.id}';

  @override
  void initState() {
    super.initState();
    _hidden = _isDismissed();
  }

  @override
  void didUpdateWidget(covariant ActionTipCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.id != widget.id ||
        oldWidget.dismissible != widget.dismissible) {
      _hidden = _isDismissed();
    }
  }

  bool _isDismissed() {
    if (!widget.dismissible || widget.id == null) return false;
    if (!Hive.isBoxOpen('settingsBox')) return false;
    return Hive.box('settingsBox').get(_storageKey) == true;
  }

  Future<void> _dismiss() async {
    if (widget.id != null && Hive.isBoxOpen('settingsBox')) {
      await Hive.box('settingsBox').put(_storageKey, true);
    }
    if (mounted) setState(() => _hidden = true);
  }

  @override
  Widget build(BuildContext context) {
    if (_hidden) return const SizedBox.shrink();

    final bg = widget.dark ? const Color(0xFF14241B) : AppColors.surface;
    final border = widget.dark
        ? widget.color.withValues(alpha: 0.55)
        : widget.color.withValues(alpha: 0.28);
    final titleColor = widget.dark ? Colors.white : AppColors.textPrimary;
    final bodyColor = widget.dark
        ? Colors.white.withValues(alpha: 0.78)
        : AppColors.textSecondary;
    final padding = widget.compact
        ? const EdgeInsets.fromLTRB(12, 10, 8, 10)
        : const EdgeInsets.fromLTRB(14, 14, 8, 14);

    return Material(
      color: Colors.transparent,
      child: Container(
        margin: widget.margin,
        padding: padding,
        decoration: BoxDecoration(
          color: bg.withValues(alpha: widget.dark ? 0.96 : 1),
          borderRadius: AppRadius.md,
          border: Border.all(color: border, width: 1.2),
          boxShadow: widget.dark ? AppShadows.lg : AppShadows.sm,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: widget.compact ? 38 : 42,
              height: widget.compact ? 38 : 42,
              decoration: BoxDecoration(
                color:
                    widget.color.withValues(alpha: widget.dark ? 0.18 : 0.12),
                borderRadius: AppRadius.sm,
              ),
              child: Icon(
                widget.icon,
                color: widget.dark ? Colors.white : widget.color,
                size: widget.compact ? 20 : 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.bodyMd(context).copyWith(
                      color: titleColor,
                      fontSize: widget.compact ? 14 : 15,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.message,
                    style: AppText.sm(context).copyWith(
                      color: bodyColor,
                      fontSize: 13,
                      height: 1.35,
                    ),
                  ),
                  if (widget.actionLabel != null &&
                      widget.onAction != null) ...[
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: FilledButton.tonalIcon(
                        onPressed: widget.onAction,
                        icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                        label: Text(widget.actionLabel!),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(48, 48),
                          visualDensity: VisualDensity.compact,
                          backgroundColor: widget.dark
                              ? widget.color.withValues(alpha: 0.2)
                              : widget.color.withValues(alpha: 0.12),
                          foregroundColor:
                              widget.dark ? Colors.white : widget.color,
                          textStyle: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (widget.dismissible)
              IconButton(
                tooltip: 'İpucunu kapat',
                onPressed: _dismiss,
                constraints: const BoxConstraints.tightFor(
                  width: 48,
                  height: 48,
                ),
                icon: Icon(
                  Icons.close_rounded,
                  color: widget.dark
                      ? Colors.white.withValues(alpha: 0.72)
                      : AppColors.textTertiary,
                  size: 20,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class ActionTipOverlay {
  ActionTipOverlay._();

  static void show(
    BuildContext context, {
    required ActionTipData tip,
    Duration duration = const Duration(seconds: 5),
  }) {
    final overlay = Overlay.of(context, rootOverlay: true);
    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (ctx) {
        final mq = MediaQuery.of(ctx);
        return Positioned(
          left: 16,
          right: 16,
          bottom: mq.padding.bottom + 24,
          child: ActionTipCard.fromData(
            tip,
            dismissible: false,
            dark: true,
            compact: true,
          ),
        );
      },
    );
    overlay.insert(entry);
    Future.delayed(duration, () {
      if (entry.mounted) entry.remove();
    });
  }
}
