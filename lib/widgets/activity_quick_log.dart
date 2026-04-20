import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/activity_types.dart';
import '../services/app_providers.dart';
import '../services/haptic_service.dart';
import '../theme/app_theme.dart';
import 'floating_toast.dart';
import 'tap_scale.dart';

/// Çiftçinin tarlada yaptığı günlük işleri tek tap ile kaydettiği chip satırı.
/// Field detail ekranında HUD'un üstüne yerleşir.
///
/// Tasarım: Sadelik önceliği — miktar ve not opsiyonel. Boş bırakılabilir.
class ActivityQuickLog extends ConsumerStatefulWidget {
  const ActivityQuickLog({
    super.key,
    required this.fieldId,
    this.cropId,
    this.onLogged,
  });

  final String fieldId;
  final String? cropId;
  final VoidCallback? onLogged;

  @override
  ConsumerState<ActivityQuickLog> createState() => _ActivityQuickLogState();
}

class _ActivityQuickLogState extends ConsumerState<ActivityQuickLog> {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.check_circle_outline_rounded,
                  size: 18, color: AppColors.emeraldDark),
              const SizedBox(width: 6),
              Text(
                'Bugün ne yaptın?',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: ActivityType.quickLogOrder.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final type = ActivityType.quickLogOrder[i];
                return _QuickChip(
                  type: type,
                  onTap: () => _onChipTap(type),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _onChipTap(String type) async {
    HapticService.instance.light();
    final detail = await showModalBottomSheet<_QuickLogDetail>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _QuickLogSheet(type: type),
    );
    if (detail == null) return;
    final repo = ref.read(localDataRepositoryProvider);
    try {
      await repo.logActivity(
        fieldId: widget.fieldId,
        type: type,
        cropId: widget.cropId,
        note: detail.note,
        quantity: detail.quantity,
        quantityUnit: ActivityType.quantityUnit(type),
      );
      if (!mounted) return;
      HapticService.instance.success();
      AppToast.show(
        context,
        message: '${ActivityType.actionLabel(type)} kaydedildi',
        type: ToastType.success,
      );
      widget.onLogged?.call();
    } catch (e) {
      if (!mounted) return;
      AppToast.show(
        context,
        message: 'Kayıt başarısız: $e',
        type: ToastType.error,
      );
    }
  }
}

class _QuickChip extends StatelessWidget {
  const _QuickChip({required this.type, required this.onTap});

  final String type;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = ActivityType.color(type);
    return TapScale(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: color.withValues(alpha: 0.35)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(ActivityType.icon(type), size: 18, color: color),
            const SizedBox(width: 6),
            Text(
              ActivityType.actionLabel(type),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickLogDetail {
  const _QuickLogDetail({this.note, this.quantity});
  final String? note;
  final double? quantity;
}

class _QuickLogSheet extends StatefulWidget {
  const _QuickLogSheet({required this.type});
  final String type;

  @override
  State<_QuickLogSheet> createState() => _QuickLogSheetState();
}

class _QuickLogSheetState extends State<_QuickLogSheet> {
  final _noteCtrl = TextEditingController();
  final _qtyCtrl = TextEditingController();

  @override
  void dispose() {
    _noteCtrl.dispose();
    _qtyCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final type = widget.type;
    final color = ActivityType.color(type);
    final unit = ActivityType.quantityUnit(type);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.bg,
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(ActivityType.icon(type), color: color, size: 22),
                ),
                const SizedBox(width: 10),
                Text(
                  ActivityType.label(type),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            if (unit != null) ...[
              Text(
                'Miktar (isteğe bağlı)',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _qtyCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  hintText: '0',
                  suffixText: unit,
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.border),
                  ),
                ),
              ),
              const SizedBox(height: 14),
            ],
            Text(
              'Not (isteğe bağlı)',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _noteCtrl,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: 'Örn. sabah 07:00, damla sulama',
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.border),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(color: AppColors.border),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Vazgeç'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: color,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      ActivityType.actionLabel(type),
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _save() {
    final qty = double.tryParse(_qtyCtrl.text.replaceAll(',', '.'));
    Navigator.of(context).pop(_QuickLogDetail(
      note: _noteCtrl.text.isEmpty ? null : _noteCtrl.text,
      quantity: qty,
    ));
  }
}
