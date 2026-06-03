import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';

import '../data/app_database.dart';
import '../services/app_providers.dart';
import '../services/soil_fertilization_service.dart';
import '../services/soil_test_advisor.dart';
import '../theme/app_theme.dart';
import '../widgets/floating_toast.dart';
import '../widgets/help_panel.dart';
import 'soil_lab_finder_screen.dart';
import 'soil_sample_point_picker_screen.dart';

/// Laboratuvar Toprak Analizi — manuel sonuç girişi + deterministik öneri.
///
/// Çiftçi, tarlasının istediği bir kısmından aldığı toprak örneğini akredite
/// bir laboratuvarda analiz ettirir; rapordaki değerleri buraya girer ve
/// [SoilTestAdvisor] ile kaynaklı, açıklanabilir Türkçe öneriler alır.
/// Sonuçlar tarla bazında (farmerUid izole) kaydedilir; geçmiş tutulur.
/// Tamamen çevrimdışı çalışır — hesaplama yereldir, ağ gerekmez.
class SoilTestEntryScreen extends ConsumerStatefulWidget {
  final String fieldId;
  final String fieldName;
  final String? cropName;

  /// Tarla sınırı — örnek noktası haritadan seçilirken kullanılır. Boşsa
  /// harita yine açılır ama sınır gösterilmez.
  final List<LatLng> fieldPolygon;

  const SoilTestEntryScreen({
    super.key,
    required this.fieldId,
    required this.fieldName,
    this.cropName,
    this.fieldPolygon = const [],
  });

  @override
  ConsumerState<SoilTestEntryScreen> createState() =>
      _SoilTestEntryScreenState();
}

class _SoilTestEntryScreenState extends ConsumerState<SoilTestEntryScreen> {
  final _sampleLabelCtrl = TextEditingController();
  final _labNameCtrl = TextEditingController();
  final _phCtrl = TextEditingController();
  final _saltCtrl = TextEditingController();
  final _ecCtrl = TextEditingController();
  final _limeCtrl = TextEditingController();
  final _omCtrl = TextEditingController();
  final _pCtrl = TextEditingController();
  final _kCtrl = TextEditingController();
  final _nCtrl = TextEditingController();
  final _satCtrl = TextEditingController();

  DateTime? _sampledAt;
  double? _sampleLat;
  double? _sampleLng;
  double? _sampleRadius;
  SoilTestAdvice? _advice;

  /// Öneri paneli açık mı (katlanabilir). Kaydet sonrası varsayılan kapalı;
  /// geçmiş analiz açıldığında otomatik açık gelir.
  bool _showAdvice = false;

  /// Geçmiş bir analiz görüntüleniyor mu — formu gizleyip yalnızca önerileri
  /// gösterir (ekran kalabalığını önler).
  bool _viewingPast = false;
  final _resultKey = GlobalKey();

  @override
  void dispose() {
    for (final c in [
      _sampleLabelCtrl,
      _labNameCtrl,
      _phCtrl,
      _saltCtrl,
      _ecCtrl,
      _limeCtrl,
      _omCtrl,
      _pCtrl,
      _kCtrl,
      _nCtrl,
      _satCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  /// Virgül veya nokta ondalık kabul eder; boş/geçersiz → null.
  double? _parse(String raw) {
    final t = raw.trim().replaceAll(',', '.');
    if (t.isEmpty) return null;
    return double.tryParse(t);
  }

  SoilTestInput _buildInput() => SoilTestInput(
        ph: _parse(_phCtrl.text),
        saltPct: _parse(_saltCtrl.text),
        ecDsM: _parse(_ecCtrl.text),
        limePct: _parse(_limeCtrl.text),
        organicMatterPct: _parse(_omCtrl.text),
        phosphorusKgDa: _parse(_pCtrl.text),
        potassiumKgDa: _parse(_kCtrl.text),
        nitrogenPct: _parse(_nCtrl.text),
        saturationPct: _parse(_satCtrl.text),
        cropName: widget.cropName,
      );

  Future<void> _analyzeAndSave() async {
    FocusScope.of(context).unfocus();
    final input = _buildInput();
    if (!input.hasAnyMeasurement) {
      AppToast.show(
        context,
        message: 'En az bir analiz değeri girin (ör. pH, fosfor, potasyum).',
        type: ToastType.warning,
      );
      return;
    }

    final advice = SoilTestAdvisor.analyze(input);

    try {
      await ref.read(localDataRepositoryProvider).saveSoilTest(
            fieldId: widget.fieldId,
            sampleLabel: _sampleLabelCtrl.text.trim().isEmpty
                ? null
                : _sampleLabelCtrl.text.trim(),
            labName: _labNameCtrl.text.trim().isEmpty
                ? null
                : _labNameCtrl.text.trim(),
            sampledAt: _sampledAt,
            ph: input.ph,
            saltPct: input.saltPct,
            ecDsM: input.ecDsM,
            limePct: input.limePct,
            organicMatterPct: input.organicMatterPct,
            phosphorusKgDa: input.phosphorusKgDa,
            potassiumKgDa: input.potassiumKgDa,
            nitrogenPct: input.nitrogenPct,
            saturationPct: input.saturationPct,
            sampleLat: _sampleLat,
            sampleLng: _sampleLng,
            sampleRadius: _sampleRadius,
          );

      // Yeni toprak analizi büyüme/verim tahminini etkiler (başlangıç besin
      // stresi). Bu tarlanın ekinlerini yeniden hesapla → canlı büyüme,
      // evre ve verim çarpanı analize göre anında güncellensin.
      await _recomputeFieldGrowth();

      if (!mounted) return;
      AppToast.show(
        context,
        message: 'Analiz kaydedildi. Öneriler hazır — açmak için dokunun.',
        type: ToastType.success,
      );
    } catch (_) {
      if (!mounted) return;
      AppToast.show(
        context,
        message: 'Kayıt sırasında sorun oluştu; öneriler yine de gösteriliyor.',
        type: ToastType.error,
      );
    }

    setState(() {
      _advice = advice;
      _viewingPast = false;
      // Öneriler arka planda hazır; katlanmış gelir, kullanıcı isterse açar.
      _showAdvice = false;
    });
    _scrollToResults();
  }

  /// Bu tarlanın ekinleri için büyüme durumunu yeniden hesaplar.
  /// Yeni toprak analizi başlangıç besin stresini değiştirir; GrowthEngine
  /// yalnızca desteklenen vitrin ürünlerini işler, diğerleri no-op döner.
  /// Hata fatal değildir — analiz kaydı yine de geçerlidir.
  Future<void> _recomputeFieldGrowth() async {
    try {
      final crops = await ref
          .read(localDataRepositoryProvider)
          .loadFieldCrops(widget.fieldId);
      final engine = ref.read(growthEngineProvider);
      for (final c in crops) {
        final cropId = c['id']?.toString();
        if (cropId != null && cropId.isNotEmpty) {
          await engine.recompute(cropId: cropId);
        }
      }
    } catch (_) {
      // Büyüme yeniden hesabı başarısız olsa bile analiz kaydı korunur.
    }
  }

  /// Geçmiş bir kaydı forma yükler ve yeniden yorumlar.
  void _loadFromRecord(SoilTest t) {
    String s(double? v) => v == null ? '' : _fmt(v);
    _sampleLabelCtrl.text = t.sampleLabel ?? '';
    _labNameCtrl.text = t.labName ?? '';
    _sampledAt = t.sampledAt?.toLocal();
    _sampleLat = t.sampleLat;
    _sampleLng = t.sampleLng;
    _sampleRadius = t.sampleRadius;
    _phCtrl.text = s(t.ph);
    _saltCtrl.text = s(t.saltPct);
    _ecCtrl.text = s(t.ecDsM);
    _limeCtrl.text = s(t.limePct);
    _omCtrl.text = s(t.organicMatterPct);
    _pCtrl.text = s(t.phosphorusKgDa);
    _kCtrl.text = s(t.potassiumKgDa);
    _nCtrl.text = s(t.nitrogenPct);
    _satCtrl.text = s(t.saturationPct);

    final advice = SoilTestAdvisor.analyze(SoilTestInput(
      ph: t.ph,
      saltPct: t.saltPct,
      ecDsM: t.ecDsM,
      limePct: t.limePct,
      organicMatterPct: t.organicMatterPct,
      phosphorusKgDa: t.phosphorusKgDa,
      potassiumKgDa: t.potassiumKgDa,
      nitrogenPct: t.nitrogenPct,
      saturationPct: t.saturationPct,
      textureClass: t.textureClass,
      cropName: widget.cropName,
    ));
    setState(() {
      _advice = advice;
      _showAdvice = true;
      _viewingPast = true;
    });
    AppToast.show(context,
        message: 'Geçmiş analiz önerileri gösteriliyor.', type: ToastType.info);
    _scrollToResults();
  }

  Future<void> _confirmDelete(SoilTest t) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Analizi sil'),
        content: const Text(
            'Bu toprak analizi kaydını silmek istediğinize emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(localDataRepositoryProvider).deleteSoilTest(t.id);
      if (mounted) {
        AppToast.show(context,
            message: 'Analiz silindi.', type: ToastType.success);
      }
    }
  }

  /// Örnek noktasını tarla haritasından seçtirir.
  Future<void> _pickOnMap() async {
    final past = <SoilSamplePastPoint>[];
    final tests =
        ref.read(fieldSoilTestsProvider(widget.fieldId)).valueOrNull ??
            const <SoilTest>[];
    for (final t in tests) {
      if (t.sampleLat != null && t.sampleLng != null) {
        past.add(SoilSamplePastPoint(
          point: LatLng(t.sampleLat!, t.sampleLng!),
          label: t.sampleLabel ?? '',
        ));
      }
    }
    final initial = (_sampleLat != null && _sampleLng != null)
        ? LatLng(_sampleLat!, _sampleLng!)
        : null;
    final result = await Navigator.push<SoilSampleArea>(
      context,
      MaterialPageRoute(
        builder: (_) => SoilSamplePointPickerScreen(
          fieldPolygon: widget.fieldPolygon,
          fieldName: widget.fieldName,
          initialPoint: initial,
          initialRadiusMeters: _sampleRadius ?? 25,
          pastPoints: past,
        ),
      ),
    );
    if (result != null) {
      setState(() {
        _sampleLat = result.center.latitude;
        _sampleLng = result.center.longitude;
        _sampleRadius = result.radiusMeters;
        if (_sampleLabelCtrl.text.trim().isEmpty) {
          _sampleLabelCtrl.text = 'Haritadan seçilen alan';
        }
      });
    }
  }

  /// Örnek/tarla konumu — seçilen nokta varsa onu, yoksa tarla merkezini kullanır.
  /// Hiçbiri yoksa null (lab bulucu açılamaz).
  LatLng? _searchCenter() {
    if (_sampleLat != null && _sampleLng != null) {
      return LatLng(_sampleLat!, _sampleLng!);
    }
    if (widget.fieldPolygon.isEmpty) return null;
    double lat = 0, lng = 0;
    for (final p in widget.fieldPolygon) {
      lat += p.latitude;
      lng += p.longitude;
    }
    return LatLng(
      lat / widget.fieldPolygon.length,
      lng / widget.fieldPolygon.length,
    );
  }

  /// Yakındaki toprak analizi laboratuvarı bulucu ekranını açar.
  void _openLabFinder() {
    final center = _searchCenter();
    if (center == null) {
      AppToast.show(
        context,
        message:
            'Konum yok. Önce haritadan örnek alanı seçin veya tarla sınırı tanımlı olsun.',
        type: ToastType.warning,
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SoilLabFinderScreen(
          latitude: center.latitude,
          longitude: center.longitude,
        ),
      ),
    );
  }

  Widget _mapPickRow() {
    final has = _sampleLat != null && _sampleLng != null;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pickOnMap,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.emeraldDark,
                    side: const BorderSide(color: AppColors.emeraldLight),
                    minimumSize: const Size.fromHeight(46),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: Icon(
                      has
                          ? Icons.edit_location_alt_rounded
                          : Icons.add_location_alt_rounded,
                      size: 18),
                  label: Text(
                      has ? 'Noktayı değiştir' : 'Haritadan örnek noktası seç'),
                ),
              ),
              if (has) ...[
                const SizedBox(width: 6),
                IconButton(
                  tooltip: 'Noktayı kaldır',
                  onPressed: () => setState(() {
                    _sampleLat = null;
                    _sampleLng = null;
                    _sampleRadius = null;
                  }),
                  icon: const Icon(Icons.close_rounded,
                      color: AppColors.textSecondary),
                ),
              ],
            ],
          ),
          if (has)
            Padding(
              padding: const EdgeInsets.only(top: 4, left: 4),
              child: Row(
                children: [
                  const Icon(Icons.place_rounded,
                      size: 14, color: AppColors.emerald),
                  const SizedBox(width: 4),
                  Text(
                    '${_sampleLat!.toStringAsFixed(5)}, ${_sampleLng!.toStringAsFixed(5)}'
                    '${_sampleRadius != null ? ' • yarıçap ${_sampleRadius!.toStringAsFixed(0)} m' : ''}',
                    style: const TextStyle(
                        fontSize: 11.5, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _sampledAt ?? now,
      firstDate: DateTime(now.year - 5),
      lastDate: now,
      helpText: 'Örnek/analiz tarihi',
    );
    if (picked != null) setState(() => _sampledAt = picked);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text('Toprak Analizi — ${widget.fieldName}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline_rounded),
            tooltip: 'Yardım',
            onPressed: () => HelpPanel.show(context, HelpContent.soilAnalysis),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!_viewingPast) ...[
              _introCard(),
              const SizedBox(height: 14),
              _formCard(),
              const SizedBox(height: 14),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.emerald,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: _analyzeAndSave,
                icon: const Icon(Icons.save_rounded),
                label: Text(
                  'Kaydet',
                  style: GoogleFonts.outfit(
                      fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
            ] else
              _viewingPastBanner(),
            if (_advice != null) ...[
              const SizedBox(height: 18),
              _recsToggle(),
            ],
            const SizedBox(height: 18),
            _historySection(),
          ],
        ),
      ),
    );
  }

  void _scrollToResults() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _resultKey.currentContext;
      if (ctx != null) {
        Scrollable.ensureVisible(ctx,
            duration: const Duration(milliseconds: 350), curve: Curves.easeOut);
      }
    });
  }

  /// Geçmiş görüntüleme modundan çıkıp boş form ile yeni analiz girişine döner.
  void _resetToNewEntry() {
    for (final c in [
      _sampleLabelCtrl,
      _labNameCtrl,
      _phCtrl,
      _saltCtrl,
      _ecCtrl,
      _limeCtrl,
      _omCtrl,
      _pCtrl,
      _kCtrl,
      _nCtrl,
      _satCtrl,
    ]) {
      c.clear();
    }
    setState(() {
      _sampledAt = null;
      _sampleLat = null;
      _sampleLng = null;
      _sampleRadius = null;
      _advice = null;
      _showAdvice = false;
      _viewingPast = false;
    });
  }

  // ── Bölümler ───────────────────────────────────────────────────────────

  Widget _viewingPastBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.infoBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.info.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.history_rounded, color: AppColors.info),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Geçmiş bir analizin önerileri görüntüleniyor.',
              style: TextStyle(fontSize: 13),
            ),
          ),
          TextButton.icon(
            onPressed: _resetToNewEntry,
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Yeni analiz'),
          ),
        ],
      ),
    );
  }

  /// Önerileri katlanabilir gösterir — başlığa basınca aç/gizle.
  Widget _recsToggle() {
    return Column(
      key: _resultKey,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Material(
          color: AppColors.successBg,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              setState(() => _showAdvice = !_showAdvice);
              if (_showAdvice) _scrollToResults();
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              child: Row(
                children: [
                  const Icon(Icons.insights_rounded,
                      color: AppColors.emeraldDark),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _showAdvice ? 'Önerileri gizle' : 'Önerileri göster',
                      style: GoogleFonts.outfit(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.emeraldDark),
                    ),
                  ),
                  Icon(
                    _showAdvice
                        ? Icons.expand_less_rounded
                        : Icons.expand_more_rounded,
                    color: AppColors.emeraldDark,
                  ),
                ],
              ),
            ),
          ),
        ),
        if (_showAdvice) ...[
          const SizedBox(height: 12),
          _resultsSection(_advice!),
        ],
      ],
    );
  }

  Widget _introCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.successBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.emeraldLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.eco_rounded, color: AppColors.emeraldDark),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Laboratuvar sonucunu girin',
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.emeraldDark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Tarlanızın istediğiniz bir kısmından aldığınız toprak örneğini '
            'akredite bir laboratuvarda analiz ettirin, ardından rapordaki '
            'değerleri buraya girin. Sadece raporda yazan değerleri doldurun; '
            'olmayan alanları boş bırakın.',
            style: TextStyle(fontSize: 13, height: 1.35),
          ),
        ],
      ),
    );
  }

  Widget _formCard() {
    return _card(
      icon: Icons.edit_note_rounded,
      color: AppColors.info,
      title: 'Analiz Değerleri',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _textField(
            controller: _sampleLabelCtrl,
            label: 'Örnek alınan tarla kısmı',
            hint: 'ör. Kuzey köşe, dere kenarı, orta kısım',
          ),
          _mapPickRow(),
          _textField(
            controller: _labNameCtrl,
            label: 'Laboratuvar / kurum (isteğe bağlı)',
            hint: 'ör. İl Tarım Müdürlüğü laboratuvarı',
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: OutlinedButton.icon(
              onPressed: _openLabFinder,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.emeraldDark,
                side: const BorderSide(color: AppColors.emeraldLight),
                minimumSize: const Size.fromHeight(46),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              icon: const Icon(Icons.travel_explore_rounded, size: 18),
              label: const Text('Yakındaki toprak laboratuvarı bul'),
            ),
          ),
          _dateRow(),
          const SizedBox(height: 4),
          const Divider(),
          const SizedBox(height: 4),
          _numField(_phCtrl, 'pH (reaksiyon)', hint: 'ör. 6.8'),
          _numField(_saltCtrl, 'Tuzluluk — % Toplam Tuz',
              hint: 'ör. 0.20', unit: '%'),
          _numField(_ecCtrl, 'Tuzluluk — EC', hint: 'ör. 1.5', unit: 'dS/m'),
          _numField(_limeCtrl, 'Kireç (CaCO₃)', hint: 'ör. 8', unit: '%'),
          _numField(_omCtrl, 'Organik madde', hint: 'ör. 1.8', unit: '%'),
          _numField(_pCtrl, 'Fosfor (P₂O₅)', hint: 'ör. 5', unit: 'kg/dekar'),
          _numField(_kCtrl, 'Potasyum (K₂O)', hint: 'ör. 25', unit: 'kg/dekar'),
          _numField(_nCtrl, 'Toplam azot (isteğe bağlı)',
              hint: 'ör. 0.08', unit: '%'),
          _numField(_satCtrl, 'Suyla doygunluk (isteğe bağlı)',
              hint: 'ör. 55', unit: '%'),
          const SizedBox(height: 6),
          Text(
            'İpucu: Tuzluluk için raporda hangisi varsa (% tuz veya EC) onu girin.',
            style: TextStyle(
                fontSize: 11.5,
                color: AppColors.textSecondary,
                fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }

  Widget _resultsSection(SoilTestAdvice advice) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Özet
        _card(
          icon: Icons.assignment_turned_in_rounded,
          color: AppColors.emeraldDark,
          title: 'Değerlendirme Özeti',
          child: Text(advice.summary,
              style: const TextStyle(fontSize: 13.5, height: 1.35)),
        ),
        const SizedBox(height: 12),

        // Bulgular
        ...advice.findings.map(_findingCard),

        // Ürün gübre takvimi (genel rehber)
        if (advice.fertilizationPlan.isNotEmpty) ...[
          const SizedBox(height: 12),
          _card(
            icon: Icons.event_note_rounded,
            color: AppColors.warning,
            title:
                'Gübreleme Takvimi — ${widget.cropName ?? ''} (genel rehber)',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...advice.fertilizationPlan.map(_fertStepTile),
                const SizedBox(height: 4),
                _fertPlanFootnote(advice),
              ],
            ),
          ),
        ],

        const SizedBox(height: 12),

        // Zorunlu uyarılar
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.warningBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.warning.withValues(alpha: 0.5)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.shield_outlined,
                      size: 18, color: AppColors.warning),
                  const SizedBox(width: 6),
                  Text('Önemli uyarılar',
                      style: GoogleFonts.outfit(
                          fontWeight: FontWeight.w700,
                          fontSize: 13.5,
                          color: AppColors.warning)),
                ],
              ),
              const SizedBox(height: 6),
              ...advice.disclaimers.map(
                (d) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('•  '),
                      Expanded(
                        child: Text(d,
                            style: const TextStyle(fontSize: 12, height: 1.3)),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _historySection() {
    final async = ref.watch(fieldSoilTestsProvider(widget.fieldId));
    return async.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (tests) {
        if (tests.isEmpty) return const SizedBox.shrink();
        return _card(
          icon: Icons.history_rounded,
          color: AppColors.textSecondary,
          title: 'Geçmiş Analizler (${tests.length})',
          child: Column(
            children: tests.map(_historyTile).toList(),
          ),
        );
      },
    );
  }

  // ── Küçük yapı taşları ───────────────────────────────────────────────────

  Widget _historyTile(SoilTest t) {
    final df = DateFormat('dd.MM.yyyy', 'tr_TR');
    final when = t.sampledAt ?? t.createdAt;
    final parts = <String>[
      if (t.ph != null) 'pH ${_fmt(t.ph!)}',
      if (t.phosphorusKgDa != null) 'P ${_fmt(t.phosphorusKgDa!)}',
      if (t.potassiumKgDa != null) 'K ${_fmt(t.potassiumKgDa!)}',
      if (t.organicMatterPct != null) 'OM %${_fmt(t.organicMatterPct!)}',
    ];

    // Açıldığında gösterilecek tüm girilen değerler.
    final rows = <MapEntry<String, String>>[
      if (t.ph != null) MapEntry('pH', _fmt(t.ph!)),
      if (t.saltPct != null)
        MapEntry('Tuzluluk (% tuz)', '%${_fmt(t.saltPct!)}'),
      if (t.ecDsM != null) MapEntry('Tuzluluk (EC)', '${_fmt(t.ecDsM!)} dS/m'),
      if (t.limePct != null) MapEntry('Kireç (CaCO₃)', '%${_fmt(t.limePct!)}'),
      if (t.organicMatterPct != null)
        MapEntry('Organik madde', '%${_fmt(t.organicMatterPct!)}'),
      if (t.phosphorusKgDa != null)
        MapEntry('Fosfor (P₂O₅)', '${_fmt(t.phosphorusKgDa!)} kg/dekar'),
      if (t.potassiumKgDa != null)
        MapEntry('Potasyum (K₂O)', '${_fmt(t.potassiumKgDa!)} kg/dekar'),
      if (t.nitrogenPct != null)
        MapEntry('Toplam azot', '%${_fmt(t.nitrogenPct!)}'),
      if (t.saturationPct != null)
        MapEntry('Suyla doygunluk', '%${_fmt(t.saturationPct!)}'),
      if (t.labName?.isNotEmpty == true) MapEntry('Laboratuvar', t.labName!),
      if (t.sampleLat != null && t.sampleLng != null)
        MapEntry('Konum',
            '${t.sampleLat!.toStringAsFixed(5)}, ${t.sampleLng!.toStringAsFixed(5)}'),
    ];

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Theme(
        // ExpansionTile'ın varsayılan ayraç çizgilerini gizle.
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          // Detaylar varsayılan olarak KAPALI — basınca açılır.
          initiallyExpanded: false,
          tilePadding: const EdgeInsets.symmetric(horizontal: 12),
          childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          leading: Icon(
            t.sampleLat != null ? Icons.place_rounded : Icons.science_outlined,
            color: t.sampleLat != null
                ? AppColors.emerald
                : AppColors.textSecondary,
          ),
          title: Text(
            t.sampleLabel?.isNotEmpty == true
                ? t.sampleLabel!
                : 'Toprak örneği',
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
          subtitle: Text(
            '${df.format(when.toLocal())}'
            '${parts.isEmpty ? '' : ' · ${parts.join(' · ')}'}',
            style: const TextStyle(fontSize: 12),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          children: [
            ...rows.map((e) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Text(e.key,
                            style: const TextStyle(
                                fontSize: 12.5,
                                color: AppColors.textSecondary)),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(e.value,
                            style: const TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                )),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: FilledButton.tonalIcon(
                    onPressed: () => _loadFromRecord(t),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.successBg,
                      foregroundColor: AppColors.emeraldDark,
                      visualDensity: VisualDensity.compact,
                    ),
                    icon: const Icon(Icons.insights_rounded, size: 18),
                    label: const Text('Önerileri göster'),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: () => _confirmDelete(t),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: BorderSide(
                        color: AppColors.error.withValues(alpha: 0.5)),
                    visualDensity: VisualDensity.compact,
                  ),
                  icon: const Icon(Icons.delete_outline_rounded, size: 18),
                  label: const Text('Sil'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _findingCard(SoilFinding f) {
    final c = _severityColor(f.severity);
    final bg = _severityBg(f.severity);
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.withValues(alpha: 0.55)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(_severityIcon(f.severity), size: 18, color: c),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  f.parameter,
                  style: GoogleFonts.outfit(
                      fontWeight: FontWeight.w700, fontSize: 14.5),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: c.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: c),
                ),
                child: Text(
                  f.level,
                  style: TextStyle(
                      fontSize: 11, color: c, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text('Ölçülen: ${f.measured}',
              style:
                  const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(f.interpretation,
              style: const TextStyle(fontSize: 12.5, height: 1.32)),
          if (f.action != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.task_alt_rounded,
                      size: 16, color: AppColors.emeraldDark),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(f.action!,
                        style: const TextStyle(fontSize: 12.5, height: 1.3)),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 6),
          Text('Kaynak: ${f.source}',
              style: TextStyle(
                  fontSize: 10.5,
                  color: AppColors.textSecondary,
                  fontStyle: FontStyle.italic)),
        ],
      ),
    );
  }

  /// Takvimin altına bağlam notu: analize göre uyarlandıysa bilgi, aksi
  /// halde "genel rehber, kesin doz için analiz girin" uyarısı (CLAUDE.md §16).
  Widget _fertPlanFootnote(SoilTestAdvice advice) {
    final adjusted = advice.fertilizationPlan.any((s) => s.adjustedBySoil);
    final text = adjusted
        ? 'Dozlar girdiğiniz toprak analizine göre uyarlandı. Kesin uygulama '
            'için laboratuvar raporundaki ziraat mühendisi önerisini esas alın.'
        : 'Bu dozlar genel rehberdir. Tarlanıza özel kesin doz için azot, '
            'fosfor ve potasyum değerlerini içeren toprak analizi girin.';
    final color = adjusted ? AppColors.emeraldDark : AppColors.warning;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(adjusted ? Icons.verified_rounded : Icons.info_outline_rounded,
              size: 15, color: color),
          const SizedBox(width: 6),
          Expanded(
            child: Text(text,
                style: TextStyle(fontSize: 11, height: 1.35, color: color)),
          ),
        ],
      ),
    );
  }

  Widget _fertStepTile(FertilizationStep step) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.warningBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(step.period,
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: AppColors.warning)),
              ),
              if (step.adjustedBySoil)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Icon(Icons.tune_rounded,
                      size: 14, color: AppColors.emeraldDark),
                ),
              Text('${_fmt(step.doseKgDekar)} kg/dekar',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 4),
          Text('Gübre: ${step.fertilizer}',
              style: const TextStyle(fontSize: 12)),
          const SizedBox(height: 2),
          Text(step.note,
              style: TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                  fontStyle: FontStyle.italic)),
          if (step.adjustmentNote != null) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.emerald.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.science_outlined,
                      size: 13, color: AppColors.emeraldDark),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(step.adjustmentNote!,
                        style: const TextStyle(
                            fontSize: 11,
                            height: 1.3,
                            fontWeight: FontWeight.w600,
                            color: AppColors.emeraldDark)),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _card({
    required IconData icon,
    required Color color,
    required String title,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.outfit(
                      fontSize: 15, fontWeight: FontWeight.w700, color: color),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  Widget _textField({
    required TextEditingController controller,
    required String label,
    String? hint,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        // Türkçe karakter (ı, ü, ş, ğ, ö, ç) girişini engelleyen IME
        // otomatik düzeltme/önerisini kapat — aksi halde İngilizce klavye
        // sözlüğü harfleri değiştirebiliyor.
        keyboardType: TextInputType.text,
        textCapitalization: TextCapitalization.sentences,
        autocorrect: false,
        enableSuggestions: false,
        style: const TextStyle(fontSize: 14),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          isDense: true,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }

  Widget _numField(TextEditingController controller, String label,
      {String? hint, String? unit}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
        ],
        style: const TextStyle(fontSize: 14),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          isDense: true,
          suffixText: unit,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }

  Widget _dateRow() {
    final df = DateFormat('dd.MM.yyyy', 'tr_TR');
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: InkWell(
        onTap: _pickDate,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.borderDark),
          ),
          child: Row(
            children: [
              const Icon(Icons.calendar_today_rounded,
                  size: 18, color: AppColors.textSecondary),
              const SizedBox(width: 10),
              Text(
                _sampledAt == null
                    ? 'Örnek/analiz tarihi (isteğe bağlı)'
                    : df.format(_sampledAt!),
                style: TextStyle(
                  fontSize: 14,
                  color: _sampledAt == null
                      ? AppColors.textSecondary
                      : AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Yardımcılar ──────────────────────────────────────────────────────────

  Color _severityColor(SoilSeverity s) {
    switch (s) {
      case SoilSeverity.ideal:
        return AppColors.success;
      case SoilSeverity.info:
        return AppColors.info;
      case SoilSeverity.warning:
        return AppColors.warning;
      case SoilSeverity.critical:
        return AppColors.error;
    }
  }

  Color _severityBg(SoilSeverity s) {
    switch (s) {
      case SoilSeverity.ideal:
        return AppColors.successBg;
      case SoilSeverity.info:
        return AppColors.infoBg;
      case SoilSeverity.warning:
        return AppColors.warningBg;
      case SoilSeverity.critical:
        return AppColors.errorBg;
    }
  }

  IconData _severityIcon(SoilSeverity s) {
    switch (s) {
      case SoilSeverity.ideal:
        return Icons.check_circle_rounded;
      case SoilSeverity.info:
        return Icons.info_rounded;
      case SoilSeverity.warning:
        return Icons.warning_amber_rounded;
      case SoilSeverity.critical:
        return Icons.error_rounded;
    }
  }

  String _fmt(double v) {
    if (v == v.roundToDouble()) return v.toStringAsFixed(0);
    final s = v.toStringAsFixed(2);
    return s.endsWith('0') ? s.substring(0, s.length - 1) : s;
  }
}
