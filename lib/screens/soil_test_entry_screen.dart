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
  SoilTestAdvice? _advice;
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
          );
      if (!mounted) return;
      AppToast.show(
        context,
        message: 'Analiz kaydedildi ve öneriler oluşturuldu.',
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

    setState(() => _advice = advice);
    // Sonuç bölümüne kaydır.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _resultKey.currentContext;
      if (ctx != null) {
        Scrollable.ensureVisible(ctx,
            duration: const Duration(milliseconds: 350), curve: Curves.easeOut);
      }
    });
  }

  /// Geçmiş bir kaydı forma yükler ve yeniden yorumlar.
  void _loadFromRecord(SoilTest t) {
    String s(double? v) => v == null ? '' : _fmt(v);
    _sampleLabelCtrl.text = t.sampleLabel ?? '';
    _labNameCtrl.text = t.labName ?? '';
    _sampledAt = t.sampledAt?.toLocal();
    _sampleLat = t.sampleLat;
    _sampleLng = t.sampleLng;
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
    setState(() => _advice = advice);
    AppToast.show(context,
        message: 'Geçmiş analiz forma yüklendi.', type: ToastType.info);
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
    final result = await Navigator.push<LatLng>(
      context,
      MaterialPageRoute(
        builder: (_) => SoilSamplePointPickerScreen(
          fieldPolygon: widget.fieldPolygon,
          fieldName: widget.fieldName,
          initialPoint: initial,
          pastPoints: past,
        ),
      ),
    );
    if (result != null) {
      setState(() {
        _sampleLat = result.latitude;
        _sampleLng = result.longitude;
        if (_sampleLabelCtrl.text.trim().isEmpty) {
          _sampleLabelCtrl.text = 'Haritadan seçilen nokta';
        }
      });
    }
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
                    '${_sampleLat!.toStringAsFixed(5)}, ${_sampleLng!.toStringAsFixed(5)}',
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
              icon: const Icon(Icons.science_rounded),
              label: Text(
                'Önerileri Oluştur',
                style: GoogleFonts.outfit(
                    fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
            if (_advice != null) ...[
              const SizedBox(height: 18),
              KeyedSubtree(key: _resultKey, child: _resultsSection(_advice!)),
            ],
            const SizedBox(height: 18),
            _historySection(),
          ],
        ),
      ),
    );
  }

  // ── Bölümler ───────────────────────────────────────────────────────────

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
              children: advice.fertilizationPlan.map(_fertStepTile).toList(),
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
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: ListTile(
        onTap: () => _loadFromRecord(t),
        leading: Icon(
          t.sampleLat != null ? Icons.place_rounded : Icons.science_outlined,
          color:
              t.sampleLat != null ? AppColors.emerald : AppColors.textSecondary,
        ),
        title: Text(
          t.sampleLabel?.isNotEmpty == true ? t.sampleLabel! : 'Toprak örneği',
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        subtitle: Text(
          '${df.format(when.toLocal())}'
          '${parts.isEmpty ? '' : ' · ${parts.join(' · ')}'}'
          '${t.labName?.isNotEmpty == true ? '\n${t.labName}' : ''}',
          style: const TextStyle(fontSize: 12),
        ),
        isThreeLine: t.labName?.isNotEmpty == true,
        trailing: IconButton(
          tooltip: 'Sil',
          icon:
              const Icon(Icons.delete_outline_rounded, color: AppColors.error),
          onPressed: () => _confirmDelete(t),
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
              Text('${step.doseKgDekar.toStringAsFixed(0)} kg/dekar',
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
