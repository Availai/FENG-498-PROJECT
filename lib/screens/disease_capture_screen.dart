import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../data/disease_types.dart';
import '../data/turkish_crops_repository.dart';
import '../services/app_providers.dart';
import '../services/disease_diagnosis_service.dart';
import '../theme/app_theme.dart';
import '../widgets/floating_toast.dart';

/// Hastalık fotoğrafı çekme + AI teşhis ekranı.
///
/// Mimari: foto çekildikten sonra [DiseaseDiagnosisService] çağrılır. Şimdilik
/// stub implementasyon `null` döndüğü için kullanıcıya manuel hastalık türü
/// formu gösterilir. AI implementasyonu eklendiğinde aynı ekran teşhis edilen
/// hastalığı otomatik öne çıkarır; kullanıcı onaylar ya da düzeltir.
class DiseaseCaptureScreen extends ConsumerStatefulWidget {
  const DiseaseCaptureScreen({
    super.key,
    required this.cropName,
    this.lat,
    this.lng,
  });

  final String cropName;
  final double? lat;
  final double? lng;

  /// Sonuç: `(photoPath, diseaseType)` çifti. Kullanıcı vazgeçerse null.
  static Future<DiseaseCaptureResult?> show(
    BuildContext context, {
    required String cropName,
    double? lat,
    double? lng,
  }) {
    return Navigator.of(context).push<DiseaseCaptureResult>(
      MaterialPageRoute(
        builder: (_) => DiseaseCaptureScreen(
          cropName: cropName,
          lat: lat,
          lng: lng,
        ),
      ),
    );
  }

  @override
  ConsumerState<DiseaseCaptureScreen> createState() =>
      _DiseaseCaptureScreenState();
}

class _DiseaseCaptureScreenState extends ConsumerState<DiseaseCaptureScreen> {
  File? _photo;
  bool _diagnosing = false;
  DiseaseDiagnosis? _diagnosis;
  String? _selectedDisease;
  final TextEditingController _otherCtrl = TextEditingController();
  bool _isOther = false;

  @override
  void initState() {
    super.initState();
    TurkishCropsRepository.instance.ensureReady().then((_) {
      if (mounted) setState(() {});
    });
  }

  bool get _useTrustedDiseaseOptions {
    final repo = TurkishCropsRepository.instance;
    if (!repo.isReady) return false;
    final crop = repo.findByName(widget.cropName);
    final stableId = crop?.stableId;
    if (stableId == null || stableId.isEmpty) return false;
    return repo.findV2ByStableId(stableId) != null;
  }

  List<String> get _availableDiseases {
    final repo = TurkishCropsRepository.instance;
    if (!_useTrustedDiseaseOptions || !repo.isReady) {
      return DiseaseTypes.commonTurkish;
    }
    final crop = repo.findByName(widget.cropName);
    final stableId = crop?.stableId;
    final v2 = stableId == null ? null : repo.findV2ByStableId(stableId);
    final out = <String>[];
    final seen = <String>{};
    for (final disease in v2?.diseases ?? const <Map<String, dynamic>>[]) {
      final name = disease['name_tr']?.toString().trim();
      if (name == null || name.isEmpty || seen.contains(name)) continue;
      seen.add(name);
      out.add(name);
    }
    if (!seen.contains('Bilinmiyor')) out.add('Bilinmiyor');
    return out;
  }

  @override
  void dispose() {
    _otherCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto(ImageSource source) async {
    final img = await ImagePicker().pickImage(
      source: source,
      imageQuality: 80,
      maxWidth: 1280,
      maxHeight: 1280,
    );
    if (img == null) return;

    // Kalıcı yola kopyala — image_picker'ın temp dosyası app yeniden açılınca
    // kaybolabilir, biz instance'a path'i bağladığımız için kalıcı olmalı.
    final dir = await getApplicationDocumentsDirectory();
    final diseaseDir = Directory(p.join(dir.path, 'disease_photos'));
    if (!await diseaseDir.exists()) {
      await diseaseDir.create(recursive: true);
    }
    final filename =
        'disease_${DateTime.now().millisecondsSinceEpoch}${p.extension(img.path)}';
    final saved = await File(img.path).copy(p.join(diseaseDir.path, filename));

    if (!mounted) return;
    setState(() {
      _photo = saved;
      _diagnosis = null;
      _diagnosing = true;
    });

    final svc = ref.read(diseaseDiagnosisServiceProvider);
    try {
      final result = await svc.diagnose(
        imagePath: saved.path,
        cropName: widget.cropName,
        lat: widget.lat,
        lng: widget.lng,
      );
      if (!mounted) return;
      setState(() {
        _diagnosis = result;
        _diagnosing = false;
        // AI sonucu varsa preset'lerden eşleştirip otomatik seç
        if (result.diseaseType != null) {
          if (_availableDiseases.contains(result.diseaseType)) {
            _selectedDisease = result.diseaseType;
          } else if (!_useTrustedDiseaseOptions) {
            _isOther = true;
            _otherCtrl.text = result.diseaseType!;
          } else {
            _selectedDisease = 'Bilinmiyor';
          }
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _diagnosing = false);
      AppToast.show(context,
          message: 'Teşhis hatası: $e', type: ToastType.error);
    }
  }

  void _save() {
    final disease = _isOther ? _otherCtrl.text.trim() : _selectedDisease;
    if (disease == null || disease.isEmpty) {
      AppToast.show(context,
          message: 'Lütfen bir hastalık türü seçin veya yazın.',
          type: ToastType.warning);
      return;
    }
    Navigator.of(context).pop(
      DiseaseCaptureResult(
        photoPath: _photo?.path,
        diseaseType: disease,
        diagnosisSource: _diagnosis?.source == 'gemini'
            ? DiseaseTypes.sourceAiCompleted
            : DiseaseTypes.sourceManual,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text('${widget.cropName} — Hastalık'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildPhotoCard(),
          const SizedBox(height: 16),
          if (_diagnosing)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2)),
                  SizedBox(width: 10),
                  Text('Teşhis ediliyor…'),
                ],
              ),
            ),
          if (_diagnosis != null) _buildDiagnosisInfo(_diagnosis!),
          const SizedBox(height: 12),
          Text('Hastalık Türü', style: AppText.label(context)),
          const SizedBox(height: 8),
          if (_useTrustedDiseaseOptions)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.emerald.withValues(alpha: 0.08),
                borderRadius: AppRadius.sm,
                border: Border.all(
                  color: AppColors.emerald.withValues(alpha: 0.22),
                ),
              ),
              child: Text(
                'Bu bitkide yalnız doğrulanmış hastalık seçenekleri gösterilir.',
                style: AppText.sm(context).copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          DropdownButtonFormField<String>(
            initialValue: _isOther ? DiseaseTypes.otherKey : _selectedDisease,
            isExpanded: true,
            decoration: InputDecoration(
              filled: true,
              fillColor: AppColors.surface,
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
              if (!_useTrustedDiseaseOptions)
                DropdownMenuItem(
                  value: DiseaseTypes.otherKey,
                  child: Text('${DiseaseTypes.otherKey} (manuel girin)'),
                ),
            ],
            onChanged: (v) {
              setState(() {
                if (v == DiseaseTypes.otherKey) {
                  _isOther = true;
                  _selectedDisease = null;
                } else {
                  _isOther = false;
                  _selectedDisease = v;
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
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius: AppRadius.sm,
                  borderSide: const BorderSide(color: AppColors.border),
                ),
              ),
            ),
          ],
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.check_rounded, color: Colors.white),
            label: const Text('Kaydet'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.emerald,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoCard() {
    if (_photo == null) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.md,
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            const Icon(Icons.photo_camera_outlined,
                size: 56, color: AppColors.emerald),
            const SizedBox(height: 12),
            Text('Hastalıklı yaprak/meyve fotoğrafı çekin',
                textAlign: TextAlign.center, style: AppText.body(context)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _pickPhoto(ImageSource.camera),
                  icon:
                      const Icon(Icons.camera_alt_rounded, color: Colors.white),
                  label: const Text('Kamera'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.emerald,
                    foregroundColor: Colors.white,
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () => _pickPhoto(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library_outlined),
                  label: const Text('Galeri'),
                ),
              ],
            ),
          ],
        ),
      );
    }
    return ClipRRect(
      borderRadius: AppRadius.md,
      child: Stack(
        children: [
          Image.file(
            _photo!,
            width: double.infinity,
            height: 240,
            fit: BoxFit.cover,
          ),
          Positioned(
            top: 8,
            right: 8,
            child: IconButton.filled(
              onPressed: () => setState(() {
                _photo = null;
                _diagnosis = null;
              }),
              icon: const Icon(Icons.refresh_rounded),
              style: IconButton.styleFrom(backgroundColor: Colors.black54),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiagnosisInfo(DiseaseDiagnosis d) {
    final isStub = d.source == 'stub';
    final color = isStub ? AppColors.warning : AppColors.emerald;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: AppRadius.sm,
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(isStub ? Icons.info_outline : Icons.smart_toy_outlined,
              color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              isStub
                  ? 'AI teşhisi henüz aktif değil. Hastalık türünü manuel girin; '
                      'fotoğraf kaydında kalır, AI eklendiğinde otomatik teşhis çalışacak.'
                  : 'AI teşhisi: ${d.diseaseType ?? "belirlenemedi"}'
                      '${d.confidence != null ? " (%${(d.confidence! * 100).round()})" : ""}',
              style: AppText.xs(context),
            ),
          ),
        ],
      ),
    );
  }
}

class DiseaseCaptureResult {
  const DiseaseCaptureResult({
    this.photoPath,
    required this.diseaseType,
    this.diagnosisSource = DiseaseTypes.sourceManual,
  });

  final String? photoPath;
  final String diseaseType;
  final String diagnosisSource;
}
