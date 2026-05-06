import 'package:flutter/material.dart';

import '../data/disease_types.dart';
import '../theme/app_theme.dart';

/// Bir bitki marker'ına dokunulduğunda açılan bottom sheet — sağlık durumunu
/// seçmek + (hasta seçilirse) hastalık türü ve fotoğraf akışını başlatmak için.
///
/// Sonuç [DiseaseSheetResult] olarak döner; çağıran taraf
/// [LocalDataRepository.setPlantHealth] ile yazar.
class DiseasePickerSheet extends StatefulWidget {
  const DiseasePickerSheet({
    super.key,
    required this.cropName,
    this.currentStatus,
    this.currentDiseaseType,
    this.currentPhotoPath,
    this.diseaseOptions = const [],
    this.useTrustedDiseaseOptions = false,
    this.onCapturePhoto,
  });

  final String cropName;
  final String? currentStatus;
  final String? currentDiseaseType;
  final String? currentPhotoPath;
  final List<String> diseaseOptions;
  final bool useTrustedDiseaseOptions;

  /// Çağıran tarafın sağladığı foto yakalama akışı. Null değilse "Foto Çek"
  /// butonu gösterilir; null'sa gizlenir. Geri dönen path foto yolu.
  final Future<String?> Function()? onCapturePhoto;

  static Future<DiseaseSheetResult?> show(
    BuildContext context, {
    required String cropName,
    String? currentStatus,
    String? currentDiseaseType,
    String? currentPhotoPath,
    List<String> diseaseOptions = const [],
    bool useTrustedDiseaseOptions = false,
    Future<String?> Function()? onCapturePhoto,
  }) {
    return showModalBottomSheet<DiseaseSheetResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => DiseasePickerSheet(
        cropName: cropName,
        currentStatus: currentStatus,
        currentDiseaseType: currentDiseaseType,
        currentPhotoPath: currentPhotoPath,
        diseaseOptions: diseaseOptions,
        useTrustedDiseaseOptions: useTrustedDiseaseOptions,
        onCapturePhoto: onCapturePhoto,
      ),
    );
  }

  @override
  State<DiseasePickerSheet> createState() => _DiseasePickerSheetState();
}

class _DiseasePickerSheetState extends State<DiseasePickerSheet> {
  late String _status;
  String? _diseaseType;
  String? _photoPath;
  final TextEditingController _otherCtrl = TextEditingController();
  bool _isOther = false;

  List<String> get _availableDiseases {
    final source = widget.useTrustedDiseaseOptions
        ? widget.diseaseOptions
        : DiseaseTypes.commonTurkish;
    final out = <String>[];
    final seen = <String>{};
    for (final raw in source) {
      final value = raw.trim();
      if (value.isEmpty || seen.contains(value)) continue;
      seen.add(value);
      out.add(value);
    }
    if (widget.useTrustedDiseaseOptions && !seen.contains('Bilinmiyor')) {
      out.add('Bilinmiyor');
    }
    return out;
  }

  @override
  void initState() {
    super.initState();
    _status = widget.currentStatus ?? DiseaseTypes.statusHealthy;
    _photoPath = widget.currentPhotoPath;
    final preset = widget.currentDiseaseType;
    if (preset != null && preset.isNotEmpty) {
      if (_availableDiseases.contains(preset)) {
        _diseaseType = preset;
      } else if (!widget.useTrustedDiseaseOptions) {
        _isOther = true;
        _otherCtrl.text = preset;
      }
    }
  }

  @override
  void dispose() {
    _otherCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + viewInsets),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Text('${widget.cropName} — Sağlık Durumu',
              style: AppText.h3(context)),
          const SizedBox(height: 12),
          _StatusChips(
            current: _status,
            onSelect: (s) => setState(() => _status = s),
          ),
          if (_status == DiseaseTypes.statusDiseased) ...[
            const SizedBox(height: 16),
            Text('Hastalık Türü', style: AppText.label(context)),
            const SizedBox(height: 8),
            if (widget.useTrustedDiseaseOptions)
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.emerald.withValues(alpha: 0.08),
                  borderRadius: AppRadius.sm,
                  border: Border.all(
                    color: AppColors.emerald.withValues(alpha: 0.22),
                  ),
                ),
                child: Text(
                  widget.diseaseOptions.isEmpty
                      ? 'Bu bitki için kaynaklı hastalık profili yok; hastalık adı uydurulmadan gözlem kaydedilir.'
                      : 'Liste, bu bitki için kaynaklı JSON hastalıklarından gelir.',
                  style: AppText.sm(context).copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            DropdownButtonFormField<String>(
              initialValue: _isOther ? DiseaseTypes.otherKey : _diseaseType,
              isExpanded: true,
              decoration: InputDecoration(
                filled: true,
                fillColor: AppColors.bg,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: AppRadius.sm,
                  borderSide: const BorderSide(color: AppColors.border),
                ),
              ),
              hint: const Text('Hastalık seçin…'),
              items: [
                ..._availableDiseases
                    .map((d) => DropdownMenuItem(value: d, child: Text(d))),
                if (!widget.useTrustedDiseaseOptions)
                  DropdownMenuItem(
                    value: DiseaseTypes.otherKey,
                    child: Text('${DiseaseTypes.otherKey} (manuel girin)'),
                  ),
              ],
              onChanged: (v) {
                setState(() {
                  if (v == DiseaseTypes.otherKey) {
                    _isOther = true;
                    _diseaseType = null;
                  } else {
                    _isOther = false;
                    _diseaseType = v;
                  }
                });
              },
            ),
            if (_isOther) ...[
              const SizedBox(height: 8),
              TextField(
                controller: _otherCtrl,
                decoration: InputDecoration(
                  hintText: 'Hastalık adını yazın',
                  filled: true,
                  fillColor: AppColors.bg,
                  border: OutlineInputBorder(
                    borderRadius: AppRadius.sm,
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                ),
              ),
            ],
            if (widget.onCapturePhoto != null) ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () async {
                  final path = await widget.onCapturePhoto!.call();
                  if (path != null && mounted) {
                    setState(() => _photoPath = path);
                  }
                },
                icon: const Icon(Icons.camera_alt_rounded),
                label: Text(_photoPath == null
                    ? 'Foto Çek (AI Analizi)'
                    : 'Foto Eklendi — Yeniden Çek'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side: const BorderSide(color: AppColors.emerald),
                  foregroundColor: AppColors.emerald,
                ),
              ),
            ],
          ],
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('İptal'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: _canSave() ? _save : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.emerald,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('Kaydet'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  bool _canSave() {
    if (_status != DiseaseTypes.statusDiseased) return true;
    // Hasta seçildiyse ya dropdown ya da serbest metin dolu olmalı
    if (_isOther) return _otherCtrl.text.trim().isNotEmpty;
    return _diseaseType != null && _diseaseType!.isNotEmpty;
  }

  void _save() {
    String? disease;
    if (_status == DiseaseTypes.statusDiseased) {
      disease = _isOther ? _otherCtrl.text.trim() : _diseaseType;
    }
    Navigator.of(context).pop(DiseaseSheetResult(
      status: _status,
      diseaseType: disease,
      photoPath: _photoPath,
    ));
  }
}

class _StatusChips extends StatelessWidget {
  const _StatusChips({required this.current, required this.onSelect});

  final String current;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    Widget chip(String value, IconData icon, Color color, String label) {
      final selected = current == value;
      return ChoiceChip(
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: selected ? Colors.white : color),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                    color: selected ? Colors.white : AppColors.textPrimary)),
          ],
        ),
        selected: selected,
        selectedColor: color,
        backgroundColor: color.withValues(alpha: 0.10),
        onSelected: (_) => onSelect(value),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.sm),
        side: BorderSide(color: color.withValues(alpha: 0.4)),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        chip(DiseaseTypes.statusHealthy, Icons.check_circle_rounded,
            AppColors.emerald, 'Sağlıklı'),
        chip(DiseaseTypes.statusDiseased, Icons.priority_high_rounded,
            const Color(0xFFD32F2F), 'Hasta'),
        chip(DiseaseTypes.statusDead, Icons.close_rounded,
            const Color(0xFF424242), 'Ölü'),
      ],
    );
  }
}

/// Bottom sheet sonuç tipi.
class DiseaseSheetResult {
  const DiseaseSheetResult({
    required this.status,
    this.diseaseType,
    this.photoPath,
  });

  final String status;
  final String? diseaseType;
  final String? photoPath;
}
