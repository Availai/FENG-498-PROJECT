import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/activity_types.dart';
import '../data/crop_ipm_rules.dart';
import '../data/crop_playbooks.dart';
import '../data/supported_crops.dart';
import '../services/app_providers.dart';
import '../services/haptic_service.dart';
import '../services/ipm_decision_service.dart';
import '../services/water_accounting.dart';
import '../theme/app_theme.dart';
import 'floating_toast.dart';
import 'tap_scale.dart';

Future<bool> showActivityQuickLogSheet({
  required BuildContext context,
  required WidgetRef ref,
  required String fieldId,
  required String type,
  String? cropId,
  List<Map<String, dynamic>> fieldCrops = const [],
  double fieldAreaDekar = 1.0,
  double? recommendedQuantity,
  String? quantityUnit,
  String? note,
}) async {
  HapticService.instance.light();
  final detail = await showModalBottomSheet<_QuickLogDetail>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => _QuickLogSheet(
      type: type,
      crops: fieldCrops
          .where((crop) => SupportedCrops.isSupported(crop['name']?.toString()))
          .toList(growable: false),
      initialCropId: cropId,
      fieldAreaDekar: fieldAreaDekar,
      initialQuantity: recommendedQuantity,
      recommendedQuantity: recommendedQuantity,
      quantityUnit: quantityUnit,
      initialNote: note,
    ),
  );
  if (detail == null) return false;

  // ActivityLogger wrapper: logActivity + recompute zincirini garantili
  // tek noktadan yapar — eskiden burada manuel recompute çağrılıyordu.
  final logger = ref.read(activityLoggerProvider);
  try {
    await logger.log(
      fieldId: fieldId,
      type: type,
      cropId: detail.cropId ?? cropId,
      note: detail.note,
      quantity: detail.quantity,
      quantityUnit: detail.quantityUnit ??
          quantityUnit ??
          ActivityType.quantityUnit(type),
      recommendedQuantity: detail.recommendedQuantity,
      metadata: detail.metadata,
    );
    if (context.mounted) {
      HapticService.instance.success();
      AppToast.show(
        context,
        message: '${ActivityType.actionLabel(type)} kaydedildi',
        type: ToastType.success,
      );
    }
    return true;
  } catch (e) {
    if (context.mounted) {
      AppToast.show(
        context,
        message: 'Kayıt başarısız: $e',
        type: ToastType.error,
      );
    }
    return false;
  }
}

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
    this.fieldAreaDekar = 1.0,
    this.onLogged,
  });

  final String fieldId;
  final String? cropId;
  final List<Map<String, dynamic>> fieldCrops;

  /// Tarla alanı (dekar) — sulama litre dönüşümü ve gübre/ilaç toplam doz
  /// hesaplamak için kullanılır. Yoksa 1.0 alınır.
  final double fieldAreaDekar;

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
          Column(
            children: ActivityType.quickLogOrder
                .map((type) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: _QuickChip(
                        type: type,
                        onTap: () => _onChipTap(type),
                      ),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }

  Future<void> _onChipTap(String type) async {
    final ok = await showActivityQuickLogSheet(
      context: context,
      ref: ref,
      fieldId: widget.fieldId,
      type: type,
      cropId: widget.cropId,
      fieldCrops: widget.fieldCrops,
      fieldAreaDekar: widget.fieldAreaDekar,
    );
    if (ok) {
      widget.onLogged?.call();
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
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.30)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(ActivityType.icon(type), size: 18, color: color),
            ),
            const SizedBox(width: 12),
            Text(
              ActivityType.actionLabel(type),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const Spacer(),
            Icon(Icons.chevron_right_rounded,
                size: 18, color: color.withValues(alpha: 0.55)),
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
    this.quantityUnit,
    this.recommendedQuantity,
    this.metadata = const {},
  });

  final String? cropId;
  final String? note;
  final double? quantity;
  final String? quantityUnit;
  final double? recommendedQuantity;
  final Map<String, dynamic> metadata;
}

class _QuickLogSheet extends StatefulWidget {
  const _QuickLogSheet({
    required this.type,
    required this.crops,
    this.initialCropId,
    this.fieldAreaDekar = 1.0,
    this.initialQuantity,
    this.recommendedQuantity,
    this.quantityUnit,
    this.initialNote,
  });

  final String type;
  final List<Map<String, dynamic>> crops;
  final String? initialCropId;
  final double fieldAreaDekar;
  final double? initialQuantity;
  final double? recommendedQuantity;
  final String? quantityUnit;
  final String? initialNote;

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
  final _sampledPlantsCtrl = TextEditingController();
  final _affectedPlantsCtrl = TextEditingController();
  final _larvaePerSqmCtrl = TextEditingController();
  final _trapAverageCtrl = TextEditingController();
  final _diseasePercentCtrl = TextEditingController();
  String? _selectedCropId;
  bool _cropError = false;
  String? _ipmPestKey;
  String _method = 'Damla sulama';

  // Playbook'tan seçilen ürün (null → serbest metin modu).
  FertilizerProduct? _pickedFertilizer;
  PesticideProduct? _pickedPesticide;
  PesticideCategory? _pesticideCategoryFilter;

  /// Seçili bitkinin playbook'u (Ayçiçeği/Mısır/Domates) — yoksa null.
  CropPlaybook? get _playbook => CropPlaybooks.resolveByName(_selectedCropName);

  bool get _hasIpmRules => IpmDecisionService.supports(_selectedCropName);

  List<Map<String, dynamic>> get _selectableCrops => widget.crops
      .where((crop) => (crop['id']?.toString().isNotEmpty ?? false))
      .toList(growable: false);

  @override
  void dispose() {
    _qtyCtrl.removeListener(_refreshWaterPreview);
    _extraQtyCtrl.removeListener(_refreshWaterPreview);
    _sampledPlantsCtrl.removeListener(_refreshIpmPreview);
    _affectedPlantsCtrl.removeListener(_refreshIpmPreview);
    _larvaePerSqmCtrl.removeListener(_refreshIpmPreview);
    _trapAverageCtrl.removeListener(_refreshIpmPreview);
    _diseasePercentCtrl.removeListener(_refreshIpmPreview);
    _noteCtrl.dispose();
    _qtyCtrl.dispose();
    _extraQtyCtrl.dispose();
    _materialCtrl.dispose();
    _activeCtrl.dispose();
    _targetCtrl.dispose();
    _sampledPlantsCtrl.dispose();
    _affectedPlantsCtrl.dispose();
    _larvaePerSqmCtrl.dispose();
    _trapAverageCtrl.dispose();
    _diseasePercentCtrl.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    final hasInitial = widget.initialCropId != null &&
        widget.crops
            .any((crop) => crop['id']?.toString() == widget.initialCropId);
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
    if (widget.initialQuantity != null) {
      _qtyCtrl.text = _formatNum(widget.initialQuantity!);
    }
    if (widget.initialNote != null && widget.initialNote!.trim().isNotEmpty) {
      _noteCtrl.text = widget.initialNote!.trim();
    }
    _syncIpmRuleForSelectedCrop();
    _qtyCtrl.addListener(_refreshWaterPreview);
    _extraQtyCtrl.addListener(_refreshWaterPreview);
    _sampledPlantsCtrl.addListener(_refreshIpmPreview);
    _affectedPlantsCtrl.addListener(_refreshIpmPreview);
    _larvaePerSqmCtrl.addListener(_refreshIpmPreview);
    _trapAverageCtrl.addListener(_refreshIpmPreview);
    _diseasePercentCtrl.addListener(_refreshIpmPreview);
  }

  void _refreshWaterPreview() {
    if (widget.type == ActivityType.watering && mounted) {
      setState(() {});
    }
  }

  void _refreshIpmPreview() {
    if ((widget.type == ActivityType.scouting ||
            widget.type == ActivityType.spraying) &&
        mounted) {
      setState(() {});
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
                    child:
                        Icon(ActivityType.icon(type), color: color, size: 22),
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
              if (_selectableCrops.isNotEmpty &&
                  widget.initialCropId == null) ...[
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
                  key: ValueKey(_selectedCropId),
                  initialValue: _selectedCropId,
                  items: _selectableCrops.map((crop) {
                    final id = crop['id']!.toString();
                    final name = crop['name']?.toString() ?? 'Ürün';
                    return DropdownMenuItem<String>(
                      value: id,
                      child: Text(name),
                    );
                  }).toList(),
                  onChanged: (value) => setState(() {
                    _selectedCropId = value;
                    _cropError = false;
                    // Bitki değişti → playbook seçimleri sıfırla.
                    _pickedFertilizer = null;
                    _pickedPesticide = null;
                    _pesticideCategoryFilter = null;
                    _syncIpmRuleForSelectedCrop();
                  }),
                  decoration: InputDecoration(
                    hintText: 'Ürün seç',
                    filled: true,
                    fillColor: _cropError
                        ? AppColors.error.withValues(alpha: 0.08)
                        : AppColors.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: _cropError ? AppColors.error : AppColors.border,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: _cropError ? AppColors.error : AppColors.border,
                      ),
                    ),
                    errorText: _cropError ? 'Devam etmek için bir ürün seçin' : null,
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
    if (_selectableCrops.isNotEmpty && _selectedCropId == null) {
      setState(() => _cropError = true);
      return;
    }
    final qty = double.tryParse(_qtyCtrl.text.replaceAll(',', '.'));
    final extraQty = double.tryParse(_extraQtyCtrl.text.replaceAll(',', '.'));
    final ipmDecision = _currentIpmDecision();
    if (widget.type == ActivityType.scouting &&
        _hasIpmRules &&
        ipmDecision == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gözlem için hedef zararlı seçin.')),
      );
      return;
    }
    if (widget.type == ActivityType.spraying &&
        _hasIpmRules &&
        ipmDecision?.allowsChemical != true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Eşik aşılmadan ayçiçeğinde ilaç kaydı açılamaz. Önce gözlem kaydı oluşturun.',
          ),
        ),
      );
      return;
    }
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
      final impact = _waterImpact(qty: qty, liters: extraQty);
      if (impact.hasWater) {
        metadata['effective_water_mm'] = impact.mm;
        metadata['effective_water_liters'] = impact.liters;
        metadata['water_impact_source'] = impact.source;
      }
      // Playbook'tan haftalık önerilen mm — gerçek/öneri karşılaştırması için.
      final crop = _selectedCropMap();
      final pb = _playbook;
      if (pb != null && crop != null) {
        final planted = _parsePlantedDate(crop['planted_date']?.toString());
        if (planted != null) {
          final days = DateTime.now().difference(planted).inDays;
          final band = pb.bandForDay(days);
          if (band != null) {
            metadata['recommended_weekly_mm'] = band.weeklyMm;
            metadata['stage_label'] = band.stage;
            metadata['days_since_planting'] = days;
          }
        }
      }
    } else if (widget.type == ActivityType.fertilizing) {
      if (_materialCtrl.text.trim().isNotEmpty) {
        metadata['fertilizer_name'] = _materialCtrl.text.trim();
      }
      if (qty != null) metadata['fertilizer_kg'] = qty;
      if (_targetCtrl.text.trim().isNotEmpty) {
        metadata['growth_stage'] = _targetCtrl.text.trim();
      }
      // Playbook seçimi varsa strüktüre alanlar:
      final f = _pickedFertilizer;
      if (f != null) {
        metadata['fertilizer_formula'] = f.formula;
        metadata['fertilizer_dose_per_da'] = f.defaultDosePerDa;
        metadata['fertilizer_unit'] = f.unit;
        metadata['source'] = 'playbook';
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
      final p = _pickedPesticide;
      if (p != null) {
        metadata['pesticide_category'] = p.category.name;
        metadata['pesticide_dose_per_da'] = p.defaultDosePerDa;
        metadata['pesticide_dose_unit'] = p.unit;
        metadata['preharvest_interval_days'] = p.preharvestIntervalDays;
        metadata['source'] = 'playbook';
      }
      if (ipmDecision != null) {
        metadata['ipm_gate'] = ipmDecision.toJson();
        metadata['ipm_observation'] = _ipmObservationInput()?.toJson();
        metadata['chemical_gate_reason'] = ipmDecision.message;
      }
    } else if (widget.type == ActivityType.scouting) {
      final input = _ipmObservationInput();
      if (input != null && ipmDecision != null) {
        metadata['source'] = 'ipm';
        metadata['ipm_observation'] = input.toJson();
        metadata['ipm_decision'] = ipmDecision.toJson();
        metadata['target_pest'] = ipmDecision.rule.pestName;
        metadata['threshold_status'] = ipmDecision.status.name;
        metadata['allows_chemical'] = ipmDecision.allowsChemical;
      } else if (_targetCtrl.text.trim().isNotEmpty) {
        metadata['scouting_target'] = _targetCtrl.text.trim();
      }
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
      quantityUnit:
          widget.quantityUnit ?? ActivityType.quantityUnit(widget.type),
      recommendedQuantity: widget.recommendedQuantity,
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
          if (_wateringRecommendation() != null) ...[
            _wateringRecommendation()!,
            const SizedBox(height: 12),
          ],
          _methodDropdown(
            label: 'Sulama yöntemi',
            values: const [
              'Damla sulama',
              'Karık sulama',
              'Yağmurlama',
              'Elle sulama'
            ],
          ),
          const SizedBox(height: 14),
          _textField(
            controller: _extraQtyCtrl,
            label: 'Verilen su (opsiyonel)',
            hint: 'Örn. 1200',
            suffix: 'L',
            number: true,
          ),
          const SizedBox(height: 10),
          _wateringEffectPreview(),
          const SizedBox(height: 14),
        ];
      case ActivityType.fertilizing:
        return [
          if (_playbook != null) ...[
            _fertilizerPicker(_playbook!),
            const SizedBox(height: 14),
          ],
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
        final chemicalGateOpen =
            !_hasIpmRules || (_currentIpmDecision()?.allowsChemical ?? false);
        return [
          if (_hasIpmRules) ...[
            _ipmObservationCard(forChemicalGate: true),
            const SizedBox(height: 14),
          ],
          if (chemicalGateOpen && _playbook != null) ...[
            _pesticidePicker(_playbook!),
            const SizedBox(height: 14),
          ],
          if (!chemicalGateOpen) ...[
            _chemicalLockedCard(),
            const SizedBox(height: 14),
          ],
          if (chemicalGateOpen) ...[
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
            values: const [
              'Pülverizatör',
              'Sırt pompası',
              'Damla ile',
              'Tohum uygulaması'
            ],
          ),
          const SizedBox(height: 14),
          ],
        ];
      case ActivityType.scouting:
        return [
          if (_hasIpmRules) ...[
            _ipmObservationCard(),
            const SizedBox(height: 14),
          ] else ...[
            _textField(
              controller: _targetCtrl,
              label: 'Gözlem konusu',
              hint: 'Örn. yaprak, tabla, yabancı ot, hastalık belirtisi',
            ),
            const SizedBox(height: 14),
          ],
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

  // ───────────────────────────────────────────────────────────────────────
  // Playbook destekli pickerlar
  // ───────────────────────────────────────────────────────────────────────

  void _syncIpmRuleForSelectedCrop() {
    final rules = IpmDecisionService.rulesForCrop(_selectedCropName);
    if (rules.isEmpty) {
      _ipmPestKey = null;
      return;
    }
    if (_ipmPestKey == null ||
        !rules.any((rule) => rule.pestKey == _ipmPestKey)) {
      _ipmPestKey = rules.first.pestKey;
      _applyIpmRuleDefaults();
    }
  }

  CropIpmRule _selectedIpmRule(List<CropIpmRule> rules) {
    return rules.firstWhere(
      (rule) => rule.pestKey == _ipmPestKey,
      orElse: () => rules.first,
    );
  }

  void _applyIpmRuleDefaults() {
    final rule = IpmDecisionService.ruleFor(
      cropName: _selectedCropName ?? '',
      pestKey: _ipmPestKey ?? '',
    );
    if (rule == null) return;
    if (_needsPlantCount(rule) && _sampledPlantsCtrl.text.trim().isEmpty) {
      _sampledPlantsCtrl.text = '100';
    }
  }

  IpmObservationInput? _ipmObservationInput() {
    final cropName = _selectedCropName;
    final rules = IpmDecisionService.rulesForCrop(cropName);
    if (cropName == null || rules.isEmpty) return null;
    final pestKey = _ipmPestKey ?? rules.first.pestKey;
    return IpmObservationInput(
      cropName: cropName,
      pestKey: pestKey,
      sampledPlants: _parseInt(_sampledPlantsCtrl.text),
      affectedPlants: _parseInt(_affectedPlantsCtrl.text),
      larvaePerSquareMeter: _parseDouble(_larvaePerSqmCtrl.text),
      trapAverage: _parseDouble(_trapAverageCtrl.text),
      diseasePercent: _parseDouble(_diseasePercentCtrl.text),
    );
  }

  IpmDecision? _currentIpmDecision() {
    final input = _ipmObservationInput();
    if (input == null) return null;
    try {
      return IpmDecisionService.evaluate(input);
    } catch (_) {
      return null;
    }
  }

  bool _needsPlantCount(CropIpmRule rule) {
    return rule.pestKey == 'yesilkurt' || rule.pestKey == 'aycicegi_guvesi';
  }

  bool _needsLarvaePerSquareMeter(CropIpmRule rule) {
    return rule.pestKey == 'bozkurt' ||
        rule.pestKey == 'cayir_tirtili' ||
        rule.pestKey == 'telkurtlari';
  }

  int? _parseInt(String raw) {
    final v = double.tryParse(raw.replaceAll(',', '.'));
    return v?.round();
  }

  double? _parseDouble(String raw) {
    return double.tryParse(raw.replaceAll(',', '.'));
  }

  Widget _ipmObservationCard({bool forChemicalGate = false}) {
    final cropName = _selectedCropName;
    final rules = IpmDecisionService.rulesForCrop(cropName);
    if (rules.isEmpty) return const SizedBox.shrink();
    final selected = _selectedIpmRule(rules);
    final decision = _currentIpmDecision();
    return _PickerCard(
      title: forChemicalGate
          ? 'Ayçiçeği entegre mücadele kilidi'
          : 'Ayçiçeği gözlem kaydı',
      subtitle: forChemicalGate
          ? 'Ürün kataloğu yalnız ekonomik eşik doğrulanırsa açılır.'
          : 'Sayımı gir; karar otomatik eşik kontrolüyle kayda geçer.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DropdownButtonFormField<String>(
            key: ValueKey(_ipmPestKey),
            initialValue: selected.pestKey,
            items: rules
                .map(
                  (rule) => DropdownMenuItem<String>(
                    value: rule.pestKey,
                    child: Text(rule.pestName),
                  ),
                )
                .toList(),
            onChanged: (value) => setState(() {
              _ipmPestKey = value;
              _pickedPesticide = null;
              _pesticideCategoryFilter = null;
              _materialCtrl.clear();
              _activeCtrl.clear();
              _targetCtrl.clear();
              _applyIpmRuleDefaults();
            }),
            decoration: InputDecoration(
              labelText: 'Hedef zararlı/hastalık',
              filled: true,
              fillColor: AppColors.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.border),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Eşik: ${selected.economicThreshold}',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.warning,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            selected.monitoringMethod,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 12),
          if (_needsPlantCount(selected)) ...[
            Row(
              children: [
                Expanded(
                  child: _textField(
                    controller: _sampledPlantsCtrl,
                    label: 'Örneklenen bitki',
                    hint: '100',
                    number: true,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _textField(
                    controller: _affectedPlantsCtrl,
                    label: 'Belirti görülen',
                    hint: '0',
                    number: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
          if (_needsLarvaePerSquareMeter(selected)) ...[
            _textField(
              controller: _larvaePerSqmCtrl,
              label: 'Metrekare larva sayısı',
              hint: '0',
              suffix: 'adet/m²',
              number: true,
            ),
            const SizedBox(height: 12),
          ],
          if (selected.pestKey == 'aycicegi_guvesi') ...[
            _textField(
              controller: _trapAverageCtrl,
              label: 'Tuzak ortalaması',
              hint: '0',
              suffix: 'ergin',
              number: true,
            ),
            const SizedBox(height: 12),
          ],
          if (selected.pestKey == 'mildiyo') ...[
            _textField(
              controller: _diseasePercentCtrl,
              label: 'Hastalıklı bitki oranı',
              hint: '0',
              suffix: '%',
              number: true,
            ),
            const SizedBox(height: 12),
          ],
          if (decision != null) _ipmDecisionPreview(decision),
        ],
      ),
    );
  }

  Widget _ipmDecisionPreview(IpmDecision decision) {
    final color = switch (decision.status) {
      IpmDecisionStatus.chemicalAllowed => AppColors.warning,
      IpmDecisionStatus.criticalNoChemical => AppColors.error,
      IpmDecisionStatus.followUp => AppColors.frost,
      IpmDecisionStatus.belowThreshold => AppColors.emerald,
    };
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${decision.status.label} · ${decision.headline}',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            decision.message,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textPrimary,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  Widget _chemicalLockedCard() {
    final decision = _currentIpmDecision();
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.lock_outline_rounded,
              color: AppColors.warning, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              decision == null
                  ? 'Ayçiçeğinde ilaç kataloğu için önce hedef zararlıyı seçip gözlem sayımı gir.'
                  : 'Kimyasal kapı kapalı: ${decision.message}',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textPrimary,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _fertilizerPicker(CropPlaybook pb) {
    return _PickerCard(
      title: '${pb.displayName} için gübre kataloğu',
      subtitle: 'Dokun → tüm alanlar otomatik dolar (üzerine yazabilirsin)',
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: pb.fertilizers.map((f) {
          final selected = _pickedFertilizer == f;
          return TapScale(
            onTap: () => _applyFertilizer(f),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: selected
                    ? AppColors.emerald.withValues(alpha: 0.18)
                    : AppColors.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: selected ? AppColors.emerald : AppColors.border,
                  width: selected ? 1.5 : 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    f.name,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${f.formula} · ${_formatNum(f.defaultDosePerDa)} ${f.unit}/da',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _pesticidePicker(CropPlaybook pb) {
    final filtered = _pesticideCategoryFilter == null
        ? pb.pesticides
        : pb.pesticides
            .where((p) => p.category == _pesticideCategoryFilter)
            .toList();
    return _PickerCard(
      title: '${pb.displayName} için ilaç kataloğu',
      subtitle: 'Önce kategori, sonra ürün seç. Tüm alanlar otomatik dolar.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _categoryChip(null, 'Tümü'),
              ...PesticideCategory.values.map(
                (c) => _categoryChip(c, c.label),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (filtered.isEmpty)
            Text(
              'Bu kategoride kayıtlı ürün yok.',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textTertiary,
                fontStyle: FontStyle.italic,
              ),
            )
          else
            Column(
              children: filtered.map((p) {
                final selected = _pickedPesticide == p;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: TapScale(
                    onTap: () => _applyPesticide(p),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: selected
                            ? AppColors.warning.withValues(alpha: 0.14)
                            : AppColors.surface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color:
                              selected ? AppColors.warning : AppColors.border,
                          width: selected ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  p.name,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  p.activeIngredient,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Hedef: ${p.targets.take(3).join(", ")}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textTertiary,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.warning.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${_formatNum(p.defaultDosePerDa)} ${p.unit}/da',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.warning,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _categoryChip(PesticideCategory? cat, String label) {
    final selected = _pesticideCategoryFilter == cat;
    return TapScale(
      onTap: () =>
          setState(() => _pesticideCategoryFilter = selected ? null : cat),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.emerald.withValues(alpha: 0.16)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppColors.emerald : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: selected ? AppColors.emeraldDark : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  WaterImpact _waterImpact({double? qty, double? liters}) {
    final areaSqm =
        (widget.fieldAreaDekar <= 0 ? 1.0 : widget.fieldAreaDekar) * 1000.0;
    final crop = _selectedCropMap();
    final plantCount = WaterAccounting.estimatePlantCount(
      areaSqm: areaSqm,
      rowSpacingCm: (crop?['row_spacing_cm'] as num?)?.toDouble(),
      plantSpacingCm: (crop?['plant_spacing_cm'] as num?)?.toDouble(),
    );
    return WaterAccounting.calculate(
      metadata: {
        'irrigation_method': _method,
        if (liters != null) 'water_liters': liters,
        if (qty != null) 'duration_minutes': qty,
      },
      quantity: qty,
      quantityUnit: 'dk',
      areaSqm: areaSqm,
      plantCount: plantCount,
    );
  }

  Widget _wateringEffectPreview() {
    final qty = double.tryParse(_qtyCtrl.text.replaceAll(',', '.'));
    final liters = double.tryParse(_extraQtyCtrl.text.replaceAll(',', '.'));
    final impact = _waterImpact(qty: qty, liters: liters);
    final pb = _playbook;
    final crop = _selectedCropMap();
    double? weeklyTarget;
    if (pb != null && crop != null) {
      final planted = _parsePlantedDate(crop['planted_date']?.toString());
      if (planted != null) {
        final daysSince = DateTime.now().difference(planted).inDays;
        weeklyTarget = pb.bandForDay(daysSince)?.weeklyMm.toDouble();
      }
    }
    final targetPct = weeklyTarget == null || weeklyTarget <= 0
        ? null
        : (impact.mm / weeklyTarget * 100).clamp(0, 999).round();
    final hasInput = (qty != null && qty > 0) || (liters != null && liters > 0);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.frostBg.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.frost.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.insights_rounded, color: AppColors.frost, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              hasInput
                  ? 'Bu kayıt yaklaşık ${impact.mm.toStringAsFixed(1)} mm / '
                      '${_formatLargeLiter(impact.liters)} L etki eder. '
                      '${targetPct == null ? '' : 'Haftalık hedefin %$targetPct kadarını karşılar. '}'
                      'Su açığını yaklaşık ${impact.mm.toStringAsFixed(1)} mm azaltır.'
                  : 'Süre veya litre girince sulamanın tarlaya kaç mm etki edeceği burada hesaplanır.',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textPrimary,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Sulama dialogunda haftalık önerilen mm ve dekara karşılık L hesabı.
  /// Bitki seçili + planted_date varsa playbook'tan band çekilir; yoksa null.
  Widget? _wateringRecommendation() {
    final pb = _playbook;
    if (pb == null) return null;
    final crop = _selectedCropMap();
    if (crop == null) return null;
    final planted = _parsePlantedDate(crop['planted_date']?.toString());
    if (planted == null) return null;
    final daysSince = DateTime.now().difference(planted).inDays;
    if (daysSince < 0) return null;
    final band = pb.bandForDay(daysSince);
    if (band == null) return null;

    // 1 mm = 1 L/m². 1 dekar = 1000 m². Toplam L = mm × 1000 × dekar.
    final totalLiters = band.weeklyMm * 1000 * widget.fieldAreaDekar;
    final litersPerDay = totalLiters / 7;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.frostBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.frost.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.water_drop_rounded,
              color: AppColors.frost, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${pb.displayName} · ${band.stage} ($daysSince. gün)',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.frost,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Bu evrede haftada ${band.weeklyMm} mm önerilir. '
                  'Tarlan ${_formatNum(widget.fieldAreaDekar)} dekar → '
                  '~${_formatLargeLiter(totalLiters)} L/hafta '
                  '(≈ ${_formatLargeLiter(litersPerDay)} L/gün)',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textPrimary,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _applyFertilizer(FertilizerProduct f) {
    setState(() {
      _pickedFertilizer = f;
      _materialCtrl.text = '${f.name} (${f.formula})';
      // Toplam doz = doz/da × alan (kullanıcı override edebilir).
      final totalDose = f.defaultDosePerDa * widget.fieldAreaDekar;
      _qtyCtrl.text = _formatNum(totalDose);
      _targetCtrl.text = f.stage;
    });
  }

  void _applyPesticide(PesticideProduct p) {
    setState(() {
      _pickedPesticide = p;
      _materialCtrl.text = p.name;
      _activeCtrl.text = p.activeIngredient;
      _targetCtrl.text = p.targets.first;
      // Karışım hacmi = sulandırma su × alan (200 L/da varsayılan).
      final mixtureL = p.dilutionWaterLPerDa * widget.fieldAreaDekar;
      _qtyCtrl.text = _formatNum(mixtureL);
    });
  }

  Map<String, dynamic>? _selectedCropMap() {
    for (final c in widget.crops) {
      if (c['id']?.toString() == _selectedCropId) return c;
    }
    return null;
  }

  static DateTime? _parsePlantedDate(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    final parts = raw.split('.');
    if (parts.length == 3) {
      final iso =
          '${parts[2]}-${parts[1].padLeft(2, '0')}-${parts[0].padLeft(2, '0')}';
      final dt = DateTime.tryParse(iso);
      if (dt != null) return dt;
    }
    return DateTime.tryParse(raw);
  }

  static String _formatNum(double v) {
    if (v == v.toInt()) return v.toInt().toString();
    return v.toStringAsFixed(1);
  }

  static String _formatLargeLiter(double v) {
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)} m³';
    return v.toStringAsFixed(0);
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
          key: ValueKey(_method),
          initialValue: _method,
          items: values
              .map(
                  (value) => DropdownMenuItem(value: value, child: Text(value)))
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

// ─── Ortak picker kartı çerçevesi ─────────────────────────────────────────

class _PickerCard extends StatelessWidget {
  const _PickerCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.mint,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.emerald.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome_rounded,
                  size: 16, color: AppColors.emeraldDark),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppColors.emeraldDark,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}
