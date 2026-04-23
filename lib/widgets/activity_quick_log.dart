import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/activity_types.dart';
import '../data/supported_crops.dart';
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
    this.fieldCrops = const [],
    this.onLogged,
  });

  final String fieldId;
  final String? cropId;
  final List<Map<String, dynamic>> fieldCrops;
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
      builder: (_) => _QuickLogSheet(
        type: type,
        crops: widget.fieldCrops
            .where((crop) => SupportedCrops.isSupported(crop['name']?.toString()))
            .toList(growable: false),
        initialCropId: widget.cropId,
      ),
    );
    if (detail == null) return;
    final repo = ref.read(localDataRepositoryProvider);
    try {
      await repo.logActivity(
        fieldId: widget.fieldId,
        type: type,
        cropId: detail.cropId ?? widget.cropId,
        note: detail.note,
        quantity: detail.quantity,
        quantityUnit: ActivityType.quantityUnit(type),
        metadata: detail.metadata,
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
  const _QuickLogDetail({
    this.cropId,
    this.note,
    this.quantity,
    this.metadata = const {},
  });

  final String? cropId;
  final String? note;
  final double? quantity;
  final Map<String, dynamic> metadata;
}

class _QuickLogSheet extends StatefulWidget {
  const _QuickLogSheet({
    required this.type,
    required this.crops,
    this.initialCropId,
  });

  final String type;
  final List<Map<String, dynamic>> crops;
  final String? initialCropId;

  @override
  State<_QuickLogSheet> createState() => _QuickLogSheetState();
}

class _QuickLogSheetState extends State<_QuickLogSheet> {
  final _noteCtrl = TextEditingController();
  final _qtyCtrl = TextEditingController();
  final _extraQtyCtrl = TextEditingController();
  final _materialCtrl = TextEditingController();
  final _activeCtrl = TextEditingController();
  final _targetCtrl = TextEditingController();
  String? _selectedCropId;
  String _method = 'Damla sulama';

  List<Map<String, dynamic>> get _selectableCrops => widget.crops
      .where((crop) => (crop['id']?.toString().isNotEmpty ?? false))
      .toList(growable: false);

  @override
  void dispose() {
    _noteCtrl.dispose();
    _qtyCtrl.dispose();
    _extraQtyCtrl.dispose();
    _materialCtrl.dispose();
    _activeCtrl.dispose();
    _targetCtrl.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    final hasInitial = widget.initialCropId != null &&
        widget.crops.any((crop) => crop['id']?.toString() == widget.initialCropId);
    _selectedCropId = hasInitial
        ? widget.initialCropId
        : (_selectableCrops.length == 1
            ? _selectableCrops.first['id']?.toString()
            : null);
    if (widget.type == ActivityType.fertilizing) {
      _method = 'Serpme';
    } else if (widget.type == ActivityType.spraying) {
      _method = 'Pülverizatör';
    } else if (widget.type == ActivityType.harvest) {
      _method = 'Kasa';
    }
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
        child: SingleChildScrollView(
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
            if (_selectableCrops.isNotEmpty && widget.initialCropId == null) ...[
              Text(
                'Hedef ürün',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                value: _selectedCropId,
                items: _selectableCrops.map((crop) {
                  final id = crop['id']!.toString();
                  final name = crop['name']?.toString() ?? 'Ürün';
                  return DropdownMenuItem<String>(
                    value: id,
                    child: Text(name),
                  );
                }).toList(),
                onChanged: (value) => setState(() => _selectedCropId = value),
                decoration: InputDecoration(
                  hintText: 'Ürün seç',
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
            if (unit != null) ...[
              Text(
                _quantityLabel(type),
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
                  suffixText: _quantityUnitLabel(type, unit),
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
            ..._typeSpecificFields(type),
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
      ),
    );
  }

  void _save() {
    final qty = double.tryParse(_qtyCtrl.text.replaceAll(',', '.'));
    final extraQty = double.tryParse(_extraQtyCtrl.text.replaceAll(',', '.'));
    if (widget.type == ActivityType.spraying &&
        _materialCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('İlaç adını girin.')),
      );
      return;
    }
    final metadata = <String, dynamic>{
      'activity_version': 2,
      if (_selectedCropName != null) 'crop_name': _selectedCropName,
      if (_method.trim().isNotEmpty) 'application_method': _method,
    };
    if (widget.type == ActivityType.watering) {
      metadata['irrigation_method'] = _method;
      if (qty != null) metadata['duration_minutes'] = qty;
      if (extraQty != null) metadata['water_liters'] = extraQty;
    } else if (widget.type == ActivityType.fertilizing) {
      if (_materialCtrl.text.trim().isNotEmpty) {
        metadata['fertilizer_name'] = _materialCtrl.text.trim();
      }
      if (qty != null) metadata['fertilizer_kg'] = qty;
      if (_targetCtrl.text.trim().isNotEmpty) {
        metadata['growth_stage'] = _targetCtrl.text.trim();
      }
    } else if (widget.type == ActivityType.spraying) {
      metadata['pesticide_name'] = _materialCtrl.text.trim();
      if (_activeCtrl.text.trim().isNotEmpty) {
        metadata['active_ingredient'] = _activeCtrl.text.trim();
      }
      if (_targetCtrl.text.trim().isNotEmpty) {
        metadata['target_pest'] = _targetCtrl.text.trim();
      }
      if (qty != null) metadata['mixture_liters'] = qty;
    } else if (widget.type == ActivityType.harvest) {
      if (qty != null) metadata['harvest_kg'] = qty;
      if (_targetCtrl.text.trim().isNotEmpty) {
        metadata['quality_note'] = _targetCtrl.text.trim();
      }
    }
    Navigator.of(context).pop(_QuickLogDetail(
      cropId: _selectedCropId,
      note: _noteCtrl.text.isEmpty ? null : _noteCtrl.text,
      quantity: qty,
      metadata: metadata,
    ));
  }

  String? get _selectedCropName {
    for (final crop in widget.crops) {
      if (crop['id']?.toString() == _selectedCropId) {
        return crop['name']?.toString();
      }
    }
    return null;
  }

  String _quantityLabel(String type) {
    switch (type) {
      case ActivityType.watering:
        return 'Süre';
      case ActivityType.fertilizing:
        return 'Gübre miktarı';
      case ActivityType.spraying:
        return 'Hazırlanan karışım';
      case ActivityType.harvest:
        return 'Hasat miktarı';
      default:
        return 'Miktar';
    }
  }

  String _quantityUnitLabel(String type, String fallback) {
    switch (type) {
      case ActivityType.watering:
        return 'dk';
      case ActivityType.fertilizing:
        return 'kg';
      case ActivityType.spraying:
        return 'L';
      case ActivityType.harvest:
        return 'kg';
      default:
        return fallback;
    }
  }

  List<Widget> _typeSpecificFields(String type) {
    switch (type) {
      case ActivityType.watering:
        return [
          _methodDropdown(
            label: 'Sulama yöntemi',
            values: const ['Damla sulama', 'Karık sulama', 'Yağmurlama', 'Elle sulama'],
          ),
          const SizedBox(height: 14),
          _textField(
            controller: _extraQtyCtrl,
            label: 'Verilen su (opsiyonel)',
            hint: 'Örn. 1200',
            suffix: 'L',
            number: true,
          ),
          const SizedBox(height: 14),
        ];
      case ActivityType.fertilizing:
        return [
          _textField(
            controller: _materialCtrl,
            label: 'Gübre adı',
            hint: 'Örn. Üre, 15-15-15, potasyum nitrat',
          ),
          const SizedBox(height: 14),
          _methodDropdown(
            label: 'Uygulama yöntemi',
            values: const ['Serpme', 'Banda verme', 'Damla ile', 'Yapraktan'],
          ),
          const SizedBox(height: 14),
          _textField(
            controller: _targetCtrl,
            label: 'Dönem (opsiyonel)',
            hint: 'Örn. çiçeklenme, V6, meyve tutumu',
          ),
          const SizedBox(height: 14),
        ];
      case ActivityType.spraying:
        return [
          _textField(
            controller: _materialCtrl,
            label: 'İlaç adı',
            hint: 'Kullanılan ilacın ticari adını girin',
          ),
          const SizedBox(height: 14),
          _textField(
            controller: _activeCtrl,
            label: 'Etken madde (opsiyonel)',
            hint: 'Örn. bakır, kükürt, biyolojik preparat',
          ),
          const SizedBox(height: 14),
          _textField(
            controller: _targetCtrl,
            label: 'Hedef hastalık/zararlı',
            hint: 'Örn. mildiyö, Tuta, mısır kurdu',
          ),
          const SizedBox(height: 14),
          _methodDropdown(
            label: 'Uygulama yöntemi',
            values: const ['Pülverizatör', 'Sırt pompası', 'Damla ile', 'Tohum uygulaması'],
          ),
          const SizedBox(height: 14),
        ];
      case ActivityType.harvest:
        return [
          _textField(
            controller: _targetCtrl,
            label: 'Kalite / kullanım notu',
            hint: 'Örn. sofralık, silaj, dane, pazara ayrıldı',
          ),
          const SizedBox(height: 14),
        ];
      default:
        return const [];
    }
  }

  Widget _methodDropdown({
    required String label,
    required List<String> values,
  }) {
    if (!values.contains(_method)) _method = values.first;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: _method,
          items: values
              .map((value) => DropdownMenuItem(value: value, child: Text(value)))
              .toList(),
          onChanged: (value) => setState(() => _method = value ?? values.first),
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.border),
            ),
          ),
        ),
      ],
    );
  }

  Widget _textField({
    required TextEditingController controller,
    required String label,
    required String hint,
    String? suffix,
    bool number = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: number
              ? const TextInputType.numberWithOptions(decimal: true)
              : TextInputType.text,
          decoration: InputDecoration(
            hintText: hint,
            suffixText: suffix,
            filled: true,
            fillColor: AppColors.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.border),
            ),
          ),
        ),
      ],
    );
  }
}
