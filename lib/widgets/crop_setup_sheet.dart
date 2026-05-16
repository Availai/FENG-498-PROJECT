import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../data/crop_lifecycle.dart';
import '../data/crop_protocols.dart';
import '../data/crop_setup_scenario.dart';
import '../theme/app_theme.dart';

/// Bitki seçimi ile bölge çizimi arasında açılan kurulum sayfası.
/// [protocol] bilgisi üzerinden toprak, sulama, üretim sistemi ve aralık alır;
/// Navigator.pop ile [CropConfig] döndürür.
class CropSetupSheet extends StatefulWidget {
  const CropSetupSheet({
    super.key,
    required this.protocol,
    required this.fieldAreaDekar,
    this.initialConfig,
  });

  final CropProtocol protocol;
  final CropConfig? initialConfig;

  /// Tarla poligonundan ölçülen alan — kullanıcı manuel girmez.
  final double fieldAreaDekar;

  @override
  State<CropSetupSheet> createState() => _CropSetupSheetState();
}

class _CropSetupSheetState extends State<CropSetupSheet> {
  late SoilType _soil;
  late IrrigationMethod _irrigation;
  late ProductionSystem _productionSystem;
  late final TextEditingController _rowCtrl;
  late final TextEditingController _plantCtrl;
  late final TextEditingController _plantCountCtrl;

  /// Çok yıllık ürünler için: kullanıcı yeni fidan mı, olgun ağaç mı
  /// diktiğini işaretler. Tek yıllık üründe bu alan UI'da gösterilmez
  /// ve null kalır. CropStateService.modeFor() bu değeri okuyup
  /// doğru % state + disclaimer üretir.
  bool? _isSeedling;

  static const _bg = Colors.white;
  static const _accent = AppColors.emerald;
  static const _card = AppColors.surface;
  static const _textPrimary = AppColors.textPrimary;
  static const _textSecondary = AppColors.textSecondary;
  static const _textTertiary = AppColors.textTertiary;
  static const _borderColor = AppColors.border;

  @override
  void initState() {
    super.initState();
    final cfg = widget.initialConfig;
    _soil = cfg?.soilType ?? SoilType.loamy;
    _irrigation = cfg?.irrigationMethod ?? IrrigationMethod.furrow;
    _productionSystem = cfg?.productionSystem ?? ProductionSystem.openField;
    _rowCtrl = TextEditingController(
        text: (cfg?.rowSpacingCm ?? widget.protocol.defaultRowSpacingCm)
            .toStringAsFixed(0));
    _plantCtrl = TextEditingController(
        text: (cfg?.plantSpacingCm ?? widget.protocol.defaultPlantSpacingCm)
            .toStringAsFixed(0));
    _plantCountCtrl = TextEditingController(
      text: cfg?.targetPlantCount == null ? '' : '${cfg!.targetPlantCount}',
    );
    _isSeedling = cfg?.isSeedling;
  }

  /// Bu ürün çok yıllık mı? Picker yalnız `true` ise gösterilir.
  bool get _isPerennial =>
      cycleTypeFor(cropName: widget.protocol.displayName) ==
      CropCycleType.perennial;

  @override
  void dispose() {
    _rowCtrl.dispose();
    _plantCtrl.dispose();
    _plantCountCtrl.dispose();
    super.dispose();
  }

  void _confirm() {
    final row = double.tryParse(_rowCtrl.text.trim()) ??
        widget.protocol.defaultRowSpacingCm;
    final plant = double.tryParse(_plantCtrl.text.trim()) ??
        widget.protocol.defaultPlantSpacingCm;
    final area = widget.fieldAreaDekar.clamp(0.1, 10000).toDouble();
    final plantCountRaw = _plantCountCtrl.text.trim();
    final plantCount =
        plantCountRaw.isEmpty ? null : int.tryParse(plantCountRaw);
    if (plantCountRaw.isNotEmpty && (plantCount == null || plantCount <= 0)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bitki adedi pozitif bir sayı olmalı.')),
      );
      return;
    }
    final cleanRow = row.clamp(20, 200).toDouble();
    final cleanPlant = plant.clamp(5, 200).toDouble();
    if (plantCount != null) {
      final requiredDekar = _requiredDekarFor(
        plantCount: plantCount,
        rowSpacingCm: cleanRow,
        plantSpacingCm: cleanPlant,
      );
      if (requiredDekar > area + 0.01) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '$plantCount bitki için yaklaşık ${requiredDekar.toStringAsFixed(2)} da gerekir. Tarlada ${area.toStringAsFixed(2)} da var.',
            ),
          ),
        );
        return;
      }
    }
    Navigator.pop(
      context,
      CropConfig(
        soilType: _soil,
        irrigationMethod: _irrigation,
        productionSystem: _productionSystem,
        areaDekar: area,
        rowSpacingCm: cleanRow,
        plantSpacingCm: cleanPlant,
        targetPlantCount: plantCount,
        // Yalnız çok yıllık üründe anlamlı. Tek yıllıkta null bırakılır.
        isSeedling: _isPerennial ? _isSeedling : null,
      ),
    );
  }

  double _requiredDekarFor({
    required int plantCount,
    required double rowSpacingCm,
    required double plantSpacingCm,
  }) {
    final footprintSqm = (rowSpacingCm / 100) * (plantSpacingCm / 100);
    return (plantCount * footprintSqm) / 1000;
  }

  int _estimatedCountForCurrentSpacing() {
    final row = double.tryParse(_rowCtrl.text.trim()) ??
        widget.protocol.defaultRowSpacingCm;
    final plant = double.tryParse(_plantCtrl.text.trim()) ??
        widget.protocol.defaultPlantSpacingCm;
    final footprintSqm =
        (row.clamp(20, 200) / 100) * (plant.clamp(5, 200) / 100);
    if (footprintSqm <= 0) return 0;
    return ((widget.fieldAreaDekar * 1000) / footprintSqm).round();
  }

  double? _targetDekarPreview() {
    final plantCountRaw = _plantCountCtrl.text.trim();
    if (plantCountRaw.isEmpty) return null;
    final plantCount = int.tryParse(plantCountRaw);
    if (plantCount == null || plantCount <= 0) return null;
    final row = double.tryParse(_rowCtrl.text.trim()) ??
        widget.protocol.defaultRowSpacingCm;
    final plant = double.tryParse(_plantCtrl.text.trim()) ??
        widget.protocol.defaultPlantSpacingCm;
    return _requiredDekarFor(
      plantCount: plantCount,
      rowSpacingCm: row.clamp(20, 200).toDouble(),
      plantSpacingCm: plant.clamp(5, 200).toDouble(),
    );
  }

  double _currentRowSpacingCm() {
    final parsed = double.tryParse(_rowCtrl.text.trim());
    return (parsed ?? widget.protocol.defaultRowSpacingCm)
        .clamp(20, 200)
        .toDouble();
  }

  double _currentPlantSpacingCm() {
    final parsed = double.tryParse(_plantCtrl.text.trim());
    return (parsed ?? widget.protocol.defaultPlantSpacingCm)
        .clamp(5, 200)
        .toDouble();
  }

  int? _currentTargetPlantCount() {
    final raw = _plantCountCtrl.text.trim();
    if (raw.isEmpty) return null;
    final parsed = int.tryParse(raw);
    return parsed != null && parsed > 0 ? parsed : null;
  }

  CropSetupScenario _currentScenario() => CropSetupScenarioEngine.build(
        cropName: widget.protocol.displayName,
        soilType: _soil,
        irrigationMethod: _irrigation,
        productionSystem: _productionSystem,
        fieldAreaDekar: widget.fieldAreaDekar,
        rowSpacingCm: _currentRowSpacingCm(),
        plantSpacingCm: _currentPlantSpacingCm(),
        targetPlantCount: _currentTargetPlantCount(),
      );

  @override
  Widget build(BuildContext context) {
    final scenario = _currentScenario();
    return Container(
      decoration: const BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        left: 20,
        right: 20,
        top: 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: _borderColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(children: [
              Text(widget.protocol.emoji, style: const TextStyle(fontSize: 30)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${widget.protocol.displayName} Tarlası Kurulumu',
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: _textPrimary,
                      ),
                    ),
                    const Text(
                      'Kurulum bilgisi bakım planını hesaplar; sulama kaydı oluşturmaz',
                      style: TextStyle(color: _textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ]),
            const SizedBox(height: 20),
            _sectionLabel('🌍 Toprak Türü'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: SoilType.values.map((s) {
                final selected = _soil == s;
                return GestureDetector(
                  onTap: () => setState(() => _soil = s),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: selected ? _accent.withValues(alpha: 0.18) : _card,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: selected ? _accent : _borderColor,
                        width: selected ? 1.5 : 1,
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(s.emoji, style: const TextStyle(fontSize: 22)),
                        const SizedBox(height: 4),
                        Text(s.label,
                            style: TextStyle(
                              color: selected ? _accent : _textSecondary,
                              fontSize: 12,
                              fontWeight: selected
                                  ? FontWeight.w700
                                  : FontWeight.normal,
                            )),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                _soil.description,
                style: const TextStyle(
                    color: _textSecondary, fontSize: 11, height: 1.4),
              ),
            ),
            const SizedBox(height: 20),
            _sectionLabel('💧 Sulama Yöntemi'),
            const SizedBox(height: 4),
            const Text(
              'Bu seçim nasıl sulanacağını ve takvim aralığını belirler; Tarlam Günlüğü\'ne sulama yapılmış gibi kayıt düşmez.',
              style:
                  TextStyle(color: _textSecondary, fontSize: 11, height: 1.35),
            ),
            const SizedBox(height: 8),
            ...IrrigationMethod.values.map((m) {
              final selected = _irrigation == m;
              return GestureDetector(
                onTap: () => setState(() => _irrigation = m),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  margin: const EdgeInsets.only(bottom: 8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: selected ? _accent.withValues(alpha: 0.15) : _card,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: selected ? _accent : _borderColor,
                      width: selected ? 1.5 : 1,
                    ),
                  ),
                  child: Row(children: [
                    Icon(m.icon,
                        color: selected ? _accent : _textTertiary, size: 22),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(m.label,
                              style: TextStyle(
                                color: selected ? _accent : _textPrimary,
                                fontSize: 14,
                                fontWeight: selected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                              )),
                          Text(m.description,
                              style: const TextStyle(
                                  color: _textSecondary, fontSize: 11)),
                        ],
                      ),
                    ),
                    if (selected)
                      const Icon(Icons.check_circle_rounded,
                          color: _accent, size: 20),
                  ]),
                ),
              );
            }),
            const SizedBox(height: 20),
            _sectionLabel('🏛️ Tarım Şekli'),
            const SizedBox(height: 4),
            const Text(
              'Seçenekler T.C. Tarım ve Orman Bakanlığı destek/uygulama başlıkları esas alınarak sadeleştirildi.',
              style:
                  TextStyle(color: _textSecondary, fontSize: 11, height: 1.35),
            ),
            const SizedBox(height: 8),
            ...ProductionSystem.values.map((system) {
              final selected = _productionSystem == system;
              return GestureDetector(
                onTap: () => setState(() => _productionSystem = system),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  margin: const EdgeInsets.only(bottom: 8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: selected ? _accent.withValues(alpha: 0.15) : _card,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: selected ? _accent : _borderColor,
                      width: selected ? 1.5 : 1,
                    ),
                  ),
                  child: Row(children: [
                    Icon(system.icon,
                        color: selected ? _accent : _textTertiary, size: 22),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(system.label,
                              style: TextStyle(
                                color: selected ? _accent : _textPrimary,
                                fontSize: 14,
                                fontWeight: selected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                              )),
                          Text(system.description,
                              style: const TextStyle(
                                  color: _textSecondary, fontSize: 11)),
                        ],
                      ),
                    ),
                    if (selected)
                      const Icon(Icons.check_circle_rounded,
                          color: _accent, size: 20),
                  ]),
                ),
              );
            }),
            if (_isPerennial) ...[
              const SizedBox(height: 20),
              _sectionLabel('🌳 Fidan mı, Olgun Ağaç mı?'),
              const SizedBox(height: 4),
              const Text(
                'Çok yıllık ürünlerde (portakal, çay) ilk ekonomik hasat yıllar sonra gelir. Doğru % ilerleme ve tavsiye için kaydın durumunu işaretleyin.',
                style: TextStyle(
                    color: _textSecondary, fontSize: 11, height: 1.35),
              ),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(
                  child: _seedlingChoice(
                    label: 'Yeni fidan',
                    description:
                        'Yeni dikildi; ilk hasat için yıllar bekleniyor.',
                    selected: _isSeedling == true,
                    onTap: () => setState(() => _isSeedling = true),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _seedlingChoice(
                    label: 'Olgun ağaç',
                    description: 'Verim çağında; yıllık hasat döngüsünde.',
                    selected: _isSeedling == false,
                    onTap: () => setState(() => _isSeedling = false),
                  ),
                ),
              ]),
              if (_isSeedling == null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'İşaretlemezsen dikim tarihinden tahmin edilir (~3 yıldan eskiyse olgun kabul edilir).',
                    style: TextStyle(
                        color: AppColors.warning, fontSize: 11, height: 1.35),
                  ),
                ),
            ],
            const SizedBox(height: 20),
            _sectionLabel('📐 Tarla Alanı'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: _card,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _borderColor),
              ),
              child: Row(children: [
                const Icon(Icons.straighten_rounded,
                    color: _textSecondary, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '${widget.fieldAreaDekar.toStringAsFixed(1)} da · tarladan otomatik alındı',
                    style: const TextStyle(
                        color: _textPrimary, fontSize: 13, height: 1.3),
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 16),
            _sectionLabel('📏 Ekim Aralıkları'),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(
                child: _inputField(
                  controller: _rowCtrl,
                  label: 'Sıra arası',
                  hint: widget.protocol.defaultRowSpacingCm.toStringAsFixed(0),
                  suffix: 'cm',
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _inputField(
                  controller: _plantCtrl,
                  label: 'Bitki arası',
                  hint:
                      widget.protocol.defaultPlantSpacingCm.toStringAsFixed(0),
                  suffix: 'cm',
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ]),
            const SizedBox(height: 8),
            const Text(
              'Bu aralıklar ekim bölgesindeki bitki dizilimine, bitki sayısı hesabına ve sonraki bakım planına uygulanır.',
              style:
                  TextStyle(color: _textSecondary, fontSize: 11, height: 1.35),
            ),
            const SizedBox(height: 16),
            _sectionLabel('🌱 Kaç Adet Ekeceksin?'),
            const SizedBox(height: 8),
            _inputField(
              controller: _plantCountCtrl,
              label: 'Bitki adedi',
              hint: 'Boş bırakılabilir',
              suffix: 'adet',
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 8),
            Builder(builder: (_) {
              final targetDekar = _targetDekarPreview();
              final estimatedCount = _estimatedCountForCurrentSpacing();
              final targetText = targetDekar == null
                  ? 'Adet girmezsen tüm ekim alanı için yaklaşık $estimatedCount bitki hesaplanır.'
                  : 'Bu adet için yaklaşık ${targetDekar.toStringAsFixed(2)} da ekim alanı gerekir.';
              final overLimit =
                  targetDekar != null && targetDekar > widget.fieldAreaDekar;
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: overLimit
                      ? Colors.red.withValues(alpha: 0.10)
                      : _accent.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: overLimit
                        ? Colors.red.withValues(alpha: 0.35)
                        : _accent.withValues(alpha: 0.20),
                  ),
                ),
                child: Text(
                  targetText,
                  style: TextStyle(
                    color: overLimit ? AppColors.error : _textSecondary,
                    fontSize: 11,
                    height: 1.35,
                  ),
                ),
              );
            }),
            const SizedBox(height: 16),
            _scenarioCard(scenario),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _accent.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _accent.withValues(alpha: 0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    const Icon(Icons.calendar_today_rounded,
                        color: _accent, size: 14),
                    const SizedBox(width: 6),
                    Text(
                      'Ekim Zamanı (Türkiye)',
                      style: GoogleFonts.outfit(
                          color: _accent,
                          fontSize: 12,
                          fontWeight: FontWeight.w700),
                    ),
                  ]),
                  const SizedBox(height: 4),
                  Text(widget.protocol.sowingSeasonTR,
                      style: const TextStyle(
                          color: _textPrimary, fontSize: 11, height: 1.3)),
                  const SizedBox(height: 6),
                  Row(children: [
                    const Icon(Icons.location_on_rounded,
                        color: _accent, size: 14),
                    const SizedBox(width: 6),
                    Text(
                      'İdeal Bölgeler',
                      style: GoogleFonts.outfit(
                          color: _accent,
                          fontSize: 12,
                          fontWeight: FontWeight.w700),
                    ),
                  ]),
                  const SizedBox(height: 4),
                  Text(widget.protocol.idealRegionsTR,
                      style: const TextStyle(
                          color: _textPrimary, fontSize: 11, height: 1.3)),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _confirm,
                icon: const Icon(Icons.check_rounded, size: 20),
                label: Text(
                  'Kurulumu Tamamla ve Devam Et',
                  style: GoogleFonts.outfit(
                      fontSize: 15, fontWeight: FontWeight.w700),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _accent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) => Text(
        text,
        style: GoogleFonts.outfit(
          color: _textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
      );

  Widget _seedlingChoice({
    required String label,
    required String description,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? _accent.withValues(alpha: 0.15) : _card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? _accent : _borderColor,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color: selected ? _accent : _textPrimary,
                fontSize: 13,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: const TextStyle(
                color: _textSecondary,
                fontSize: 11,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _scenarioCard(CropSetupScenario scenario) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _accent.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.fact_check_rounded, color: _accent, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Senaryo Özeti',
                      style: GoogleFonts.outfit(
                        color: _accent,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      scenario.summary,
                      style: const TextStyle(
                        color: _textPrimary,
                        fontSize: 12,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...scenario.lines.take(5).map(
                (line) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _scenarioLine(line.title, line.body),
                ),
              ),
          if (scenario.warnings.isNotEmpty) ...[
            const SizedBox(height: 2),
            ...scenario.warnings.take(3).map(
                  (warning) => _scenarioNotice(
                    icon: Icons.warning_amber_rounded,
                    color: const Color(0xFFFFB74D),
                    text: warning,
                  ),
                ),
          ],
          const SizedBox(height: 4),
          _scenarioNotice(
            icon: Icons.verified_user_rounded,
            color: const Color(0xFF40C4FF),
            text:
                'İlaç, doz ve aktif madde kararı bu ekranda verilmez; önce gözlem, eşik, uzman onayı ve BKÜ kontrolü gerekir.',
          ),
          if (scenario.missingInformation.isNotEmpty) ...[
            const SizedBox(height: 8),
            ...scenario.missingInformation.take(2).map(
                  (missing) => _scenarioNotice(
                    icon: Icons.info_outline_rounded,
                    color: _textSecondary,
                    text: missing,
                  ),
                ),
          ],
          if (scenario.sourceRefs.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: scenario.sourceRefs.take(3).map(_sourceChip).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _scenarioLine(String title, String body) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 6,
          height: 6,
          margin: const EdgeInsets.only(top: 6),
          decoration: const BoxDecoration(
            color: _accent,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: const TextStyle(
                color: _textPrimary,
                fontSize: 12,
                height: 1.35,
              ),
              children: [
                TextSpan(
                  text: '$title: ',
                  style: const TextStyle(
                    color: _textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                TextSpan(text: body),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _scenarioNotice({
    required IconData icon,
    required Color color,
    required String text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: color == _textSecondary ? _textSecondary : color,
                fontSize: 11,
                height: 1.35,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sourceChip(String source) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: _accent.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _accent.withValues(alpha: 0.30)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.verified_rounded, color: _accent, size: 12),
          const SizedBox(width: 4),
          Text(
            _shortSource(source),
            style: const TextStyle(
              color: Color(0xFFB9F6CA),
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  String _shortSource(String source) {
    final s = source.toLowerCase();
    if (s.contains('bku') || s.contains('bitki koruma')) return 'BKÜ';
    if (s.contains('tagem')) return 'Resmi';
    if (s.contains('tarım ve orman') || s.contains('tarim ve orman')) {
      return 'Tarım ve Orman';
    }
    if (s.contains('trakya')) return 'Trakya TAE';
    if (s.contains('bakan')) return 'Bakanlık';
    return source.length <= 22 ? source : '${source.substring(0, 22)}...';
  }

  Widget _inputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required String suffix,
    ValueChanged<String>? onChanged,
  }) =>
      TextField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        onChanged: onChanged,
        style: const TextStyle(color: _textPrimary, fontSize: 15),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: _textSecondary, fontSize: 13),
          hintText: hint,
          hintStyle: const TextStyle(color: _textTertiary),
          suffixText: suffix,
          suffixStyle: const TextStyle(color: _textSecondary),
          filled: true,
          fillColor: _card,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: _borderColor),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: _borderColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: _accent, width: 1.5),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
      );
}
