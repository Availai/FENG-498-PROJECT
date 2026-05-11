import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/rule_engine/rule.dart';
import '../data/turkish_crops_repository.dart';
import '../data/supported_crops.dart';
import '../theme/app_theme.dart';
import '../widgets/tap_scale.dart';

class TurkishCropsSearchScreen extends StatefulWidget {
  const TurkishCropsSearchScreen({
    super.key,
    this.embedded = false,
    this.pickerMode = false,
  });

  /// `true` ise Scaffold sarılmaz (AppBar/BottomNav parent'tan gelir).
  final bool embedded;

  /// `true` ise tile tıklanınca `Navigator.pop(crop)` ile `TurkishCrop` döner.
  /// Normalde detay sayfası açılır.
  final bool pickerMode;

  @override
  State<TurkishCropsSearchScreen> createState() =>
      _TurkishCropsSearchScreenState();
}

class _TurkishCropsSearchScreenState extends State<TurkishCropsSearchScreen> {
  final _repo = TurkishCropsRepository.instance;
  final _controller = TextEditingController();
  Timer? _debounce;

  bool _loading = true;
  String _query = '';
  String _category = 'Tümü';
  List<String> _categories = const ['Tümü'];
  List<TurkishCrop> _results = const [];
  int _total = 0;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    await _repo.ensureReady();
    if (!mounted) return;
    final supported = _supportedCrops(query: '', category: 'Tümü');
    setState(() {
      _categories = [
        'Tümü',
        ...supported.map((crop) => crop.category).toSet(),
      ];
      _total = supported.length;
      _results = supported;
      _loading = false;
    });
  }

  List<TurkishCrop> _supportedCrops({
    required String query,
    required String category,
  }) {
    final q = SupportedCrops.normalize(query);
    final out = <TurkishCrop>[];
    for (final name in SupportedCrops.visibleNames) {
      final crop = _repo.findByName(name);
      if (crop == null) continue;
      final cropKey = SupportedCrops.normalize(
        '${crop.nameTr} ${crop.aliases.join(' ')} ${crop.scientificName ?? ''}',
      );
      if (q.isNotEmpty && !cropKey.contains(q)) continue;
      if (category != 'Tümü' && crop.category != category) continue;
      out.add(crop);
    }
    return out;
  }

  void _onQueryChanged(String v) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 220), () {
      if (!mounted) return;
      setState(() {
        _query = v;
        _results = _supportedCrops(query: v, category: _category);
      });
    });
  }

  void _selectCategory(String cat) {
    setState(() {
      _category = cat;
      _results = _supportedCrops(query: _query, category: cat);
    });
  }

  @override
  Widget build(BuildContext context) {
    final body = _buildBody();
    if (widget.embedded) return body;
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Türkiye Bitkileri'),
      ),
      body: body,
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (!_repo.isReady) {
      return _EmptyDbNotice();
    }
    return Column(
      children: [
        _buildSearchField(),
        _buildCategoryChips(),
        _buildHeaderCount(),
        Expanded(child: _buildResults()),
      ],
    );
  }

  Widget _buildSearchField() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: TextField(
        controller: _controller,
        onChanged: _onQueryChanged,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: 'Bitki, çeşit veya bölge ara...',
          prefixIcon: const Icon(Icons.search_rounded),
          suffixIcon: _controller.text.isEmpty
              ? null
              : IconButton(
                  icon: const Icon(Icons.clear_rounded),
                  onPressed: () {
                    _controller.clear();
                    _onQueryChanged('');
                  },
                ),
          filled: true,
          fillColor: Colors.grey.shade100,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildCategoryChips() {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final cat = _categories[i];
          final selected = cat == _category;
          return ChoiceChip(
            label: Text(cat),
            selected: selected,
            onSelected: (_) => _selectCategory(cat),
            selectedColor: AppColors.emerald.withValues(alpha: 0.18),
            labelStyle: TextStyle(
              color: selected ? AppColors.emeraldDark : Colors.grey.shade700,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
            side: BorderSide(
              color: selected ? AppColors.emerald : Colors.grey.shade300,
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeaderCount() {
    final shown = _results.length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 6),
      child: Row(
        children: [
          Icon(Icons.eco_rounded, size: 16, color: AppColors.emerald),
          const SizedBox(width: 6),
          Text(
            '$shown / $_total bitki',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResults() {
    if (_results.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.search_off_rounded,
                  size: 56, color: Colors.grey.shade400),
              const SizedBox(height: 12),
              Text('Sonuç bulunamadı',
                  style: GoogleFonts.inter(
                      fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(
                'Farklı bir arama deneyin veya kategori filtresini değiştirin.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                    fontSize: 13, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      itemCount: _results.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) => _CropTile(
        crop: _results[i],
        onTap: () => widget.pickerMode
            ? Navigator.of(context).pop(_results[i])
            : showCropDetail(context, _results[i]),
      ),
    );
  }
}

/// Dışarıdan da çağrılabilir (örn. my_crops detay sayfasından).
void showCropDetail(BuildContext context, TurkishCrop c) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => _CropDetailSheet(crop: c),
  );
}

class _CropTile extends StatelessWidget {
  const _CropTile({required this.crop, required this.onTap});

  final TurkishCrop crop;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return TapScale(
      onTap: onTap,
      scale: 0.98,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.emerald.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.local_florist_rounded,
                  color: AppColors.emeraldDark),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(crop.nameTr,
                      style: GoogleFonts.inter(
                          fontSize: 15, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Wrap(
                    spacing: 6,
                    runSpacing: 2,
                    children: [
                      _miniChip(crop.category, AppColors.emerald),
                      if (crop.waterNeed != null)
                        _miniChip(_waterLabel(crop.waterNeed!), Colors.blue),
                      if (crop.sunNeed != null)
                        _miniChip(_sunLabel(crop.sunNeed!), Colors.orange),
                    ],
                  ),
                ],
              ),
            ),
            // Resmî kaynak rozeti — yalnızca v2 verisi taşıyan öncelikli
            // bitkilerde (CLAUDE.md sec 11). Detay sheet zaten kaynak ve
            // kanıtları gösteriyor; bu pin kullanıcıya v2 olduğunu belli eder.
            if (crop.stableId != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.emerald.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                      color: AppColors.emerald.withValues(alpha: 0.35)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.verified_rounded,
                        size: 12, color: AppColors.emeraldDark),
                    const SizedBox(width: 3),
                    Text('Resmî',
                        style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppColors.emeraldDark)),
                  ],
                ),
              ),
              const SizedBox(width: 6),
            ],
            const Icon(Icons.chevron_right_rounded, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _miniChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color.withValues(alpha: 0.9),
        ),
      ),
    );
  }

  String _waterLabel(String v) => switch (v) {
        'low' => 'Az su',
        'medium' => 'Orta su',
        'high' => 'Bol su',
        _ => v,
      };
  String _sunLabel(String v) => switch (v) {
        'full' => 'Tam güneş',
        'partial' => 'Yarı gölge',
        'shade' => 'Gölge',
        _ => v,
      };
}

class _CropDetailSheet extends StatelessWidget {
  const _CropDetailSheet({required this.crop});
  final TurkishCrop crop;

  @override
  Widget build(BuildContext context) {
    final stableId = crop.stableId;
    final v2 = stableId == null || stableId.isEmpty
        ? null
        : TurkishCropsRepository.instance.findV2ByStableId(stableId);
    final usesTrustedV2 = v2 != null;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      maxChildSize: 0.95,
      minChildSize: 0.4,
      builder: (_, scrollCtrl) => SingleChildScrollView(
        controller: scrollCtrl,
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            _header(),
            const SizedBox(height: 20),
            _summaryIcons(),
            if (v2 != null) ...[
              const SizedBox(height: 18),
              _v2Knowledge(v2),
            ],
            const SizedBox(height: 16),
            if (crop.sowingMonths.isNotEmpty || crop.harvestMonths.isNotEmpty)
              _calendarBar(),
            if (crop.regionSuitability.isNotEmpty) ...[
              const SizedBox(height: 16),
              _sectionTitle('Yetiştiği Bölgeler', Icons.map_rounded),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: crop.regionSuitability
                    .map((r) => _chip(r, AppColors.emerald))
                    .toList(),
              ),
            ],
            if (crop.soilPhMin != null || crop.soilType.isNotEmpty) ...[
              const SizedBox(height: 16),
              _sectionTitle('Toprak', Icons.terrain_rounded),
              const SizedBox(height: 6),
              if (crop.soilPhMin != null && crop.soilPhMax != null)
                _kv('pH',
                    '${crop.soilPhMin!.toStringAsFixed(1)} - ${crop.soilPhMax!.toStringAsFixed(1)}'),
              if (crop.soilType.isNotEmpty)
                _kv('Toprak tipi', crop.soilType.join(', ')),
            ],
            if (!usesTrustedV2 && crop.fertilizerNotes != null) ...[
              const SizedBox(height: 16),
              _sectionTitle('Gübreleme', Icons.scatter_plot_rounded),
              const SizedBox(height: 6),
              _paragraph(crop.fertilizerNotes!),
            ],
            if (!usesTrustedV2 && crop.commonPests.isNotEmpty) ...[
              const SizedBox(height: 16),
              _sectionTitle('Yaygın Zararlılar', Icons.pest_control_rounded),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: crop.commonPests
                    .map((r) => _chip(r, Colors.red.shade700))
                    .toList(),
              ),
            ],
            if (!usesTrustedV2 && crop.commonDiseases.isNotEmpty) ...[
              const SizedBox(height: 16),
              _sectionTitle('Yaygın Hastalıklar', Icons.sick_rounded),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: crop.commonDiseases
                    .map((r) => _chip(r, Colors.deepOrange))
                    .toList(),
              ),
            ],
            if (!usesTrustedV2 && crop.growingTips != null) ...[
              const SizedBox(height: 16),
              _sectionTitle('Yetiştirme İpuçları', Icons.lightbulb_rounded),
              const SizedBox(height: 6),
              _paragraph(crop.growingTips!),
            ],
            if (crop.daysToHarvest != null) ...[
              const SizedBox(height: 16),
              _kv('Hasat süresi',
                  '${crop.daysToHarvest} gün (~${(crop.daysToHarvest! / 30).toStringAsFixed(1)} ay)'),
            ],
          ],
        ),
      ),
    );
  }

  Widget _v2Knowledge(CropV2Bundle v2) {
    final specialRiskCount = v2.diseases.length + v2.pests.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Kaynaklı Ürün Rehberi', Icons.verified_rounded),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            _chip(_statusLabel(v2.status), AppColors.emerald),
            _chip(_confidenceLabel(v2.confidence), Colors.indigo),
            _chip('$specialRiskCount özel risk', Colors.deepOrange),
            _chip('${v2.rules.length} çözüm kuralı', Colors.blueGrey),
          ],
        ),
        if (v2.growthStages.isNotEmpty) ...[
          const SizedBox(height: 14),
          _v2MapSection(
            'Kaynaklı Dönemler',
            Icons.timeline_rounded,
            v2.growthStages,
            AppColors.emerald,
          ),
        ],
        if (v2.diseases.isNotEmpty) ...[
          const SizedBox(height: 14),
          _v2MapSection(
            'Özel Hastalıklar',
            Icons.sick_rounded,
            v2.diseases,
            Colors.deepOrange,
            showControls: true,
          ),
        ] else if (v2.stableId == 'crop.tea') ...[
          const SizedBox(height: 14),
          _sectionTitle('Özel Hastalıklar', Icons.sick_rounded),
          const SizedBox(height: 8),
          _noticeCard(
            'Çay için doğrulanmış özel hastalık profili henüz eklenmedi. Zararlı, toprak, sulama ve hasat uyarıları gösterilir; yaygın belirti görürseniz uzmanla doğrulayın.',
          ),
        ],
        if (v2.pests.isNotEmpty) ...[
          const SizedBox(height: 14),
          _v2MapSection(
            'Özel Zararlılar',
            Icons.pest_control_rounded,
            v2.pests,
            Colors.red.shade700,
            showControls: true,
          ),
        ],
        if (v2.weeds.isNotEmpty) ...[
          const SizedBox(height: 14),
          _v2MapSection(
            'Özel Yabancı Otlar',
            Icons.grass_rounded,
            v2.weeds,
            Colors.green.shade700,
            showControls: true,
          ),
        ],
        if (v2.fertilizerRules.isNotEmpty) ...[
          const SizedBox(height: 14),
          _v2MapSection(
            'Gübreleme Güvenlik Kuralı',
            Icons.scatter_plot_rounded,
            v2.fertilizerRules,
            Colors.brown.shade700,
            showGuardrail: true,
          ),
        ],
        if (v2.irrigationRules.isNotEmpty) ...[
          const SizedBox(height: 14),
          _v2MapSection(
            'Sulama Güvenlik Kuralı',
            Icons.water_drop_rounded,
            v2.irrigationRules,
            Colors.blue.shade700,
          ),
        ],
        if (v2.rules.isNotEmpty) ...[
          const SizedBox(height: 14),
          _sectionTitle('Özel Çözüm Kartları', Icons.rule_rounded),
          const SizedBox(height: 8),
          ...v2.rules.map((rule) => _v2RuleCard(rule, v2)),
        ],
        if (v2.evidence.isNotEmpty) ...[
          const SizedBox(height: 14),
          _v2MapSection(
            'Kaynak Kanıtları',
            Icons.source_rounded,
            v2.evidence,
            Colors.blueGrey,
          ),
        ],
      ],
    );
  }

  Widget _v2MapSection(
    String title,
    IconData icon,
    List<Map<String, dynamic>> items,
    Color color, {
    bool showControls = false,
    bool showGuardrail = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(title, icon),
        const SizedBox(height: 8),
        ...items.map(
          (item) => _v2RecordCard(
            item,
            color,
            showControls: showControls,
            showGuardrail: showGuardrail,
          ),
        ),
      ],
    );
  }

  Widget _v2RecordCard(
    Map<String, dynamic> item,
    Color color, {
    bool showControls = false,
    bool showGuardrail = false,
  }) {
    final title = _firstText(item, const ['name_tr', 'title', 'label_tr']) ??
        _firstText(item, const ['id']) ??
        'Kayıt';
    final scientificName = _firstText(item, const ['scientific_name']);
    final summary = _firstText(item, const ['summary']);
    final guardrail = _firstText(item, const ['guardrail']);
    final controls = showControls
        ? _stringList(item, 'control_methods_cultural')
        : const <String>[];
    final evidence = _firstEvidence(item);
    final requiresBku = item['requires_bku_check'] == true;
    final requiresExpert = item['requires_expert_confirmation'] == true;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: color.withValues(alpha: 0.95),
            ),
          ),
          if (scientificName != null) ...[
            const SizedBox(height: 2),
            Text(
              scientificName,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: Colors.grey.shade700,
              ),
            ),
          ],
          if (summary != null) ...[
            const SizedBox(height: 6),
            _paragraph(summary),
          ],
          if (showGuardrail && guardrail != null) ...[
            const SizedBox(height: 6),
            _inlineWarning(guardrail),
          ],
          if (requiresBku || requiresExpert) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                if (requiresBku) _chip('BKÜ kontrolü', Colors.red.shade700),
                if (requiresExpert) _chip('Uzman onayı', Colors.indigo),
              ],
            ),
          ],
          if (controls.isNotEmpty) ...[
            const SizedBox(height: 8),
            ...controls.map(_bullet),
          ],
          if (evidence != null) ...[
            const SizedBox(height: 8),
            _evidenceLine(evidence),
          ],
        ],
      ),
    );
  }

  Widget _v2RuleCard(Rule rule, CropV2Bundle v2) {
    final color = _riskColor(rule.result.riskLevel);
    final title =
        _problemLabel(v2, rule.result.possibleProblemId, rule.category);
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: color.withValues(alpha: 0.95),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _chip(_riskLabel(rule.result.riskLevel), color),
            ],
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _chip(_categoryLabel(rule.category), Colors.blueGrey),
              if (rule.result.requiresBkuCheck)
                _chip('BKÜ kontrolü', Colors.red.shade700),
              if (rule.result.requiresExpertConfirmation)
                _chip('Uzman onayı', Colors.indigo),
            ],
          ),
          if (rule.explanation != null && rule.explanation!.isNotEmpty) ...[
            const SizedBox(height: 8),
            _paragraph(rule.explanation!),
          ],
          if (rule.result.recommendations.isNotEmpty) ...[
            const SizedBox(height: 8),
            ...rule.result.recommendations
                .where((r) => r.isNotEmpty)
                .map(_bullet),
          ],
          if (rule.evidence.isNotEmpty) ...[
            const SizedBox(height: 8),
            _ruleEvidenceLine(rule.evidence.first),
          ],
        ],
      ),
    );
  }

  Widget _noticeCard(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.35)),
      ),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 13,
          height: 1.45,
          color: Colors.grey.shade800,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _inlineWarning(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 12,
          height: 1.4,
          color: Colors.brown.shade800,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _bullet(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 7),
            child: Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                color: AppColors.emeraldDark,
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(child: _paragraph(text)),
        ],
      ),
    );
  }

  Widget _evidenceLine(Map<String, dynamic> evidence) {
    final text = _firstText(evidence, const ['evidence_text']);
    if (text == null || text.isEmpty) return const SizedBox.shrink();
    final source = _sourceLabel(_firstText(evidence, const ['source_id']));
    final page = evidence['page'];
    final pageText = page == null ? '' : ', s. $page';
    return Text(
      '$source$pageText: $text',
      style: GoogleFonts.inter(
        fontSize: 11,
        height: 1.4,
        color: Colors.grey.shade700,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _ruleEvidenceLine(RuleEvidence evidence) {
    final pageText = evidence.page == null ? '' : ', s. ${evidence.page}';
    return Text(
      '${_sourceLabel(evidence.sourceId)}$pageText: ${evidence.evidenceText}',
      style: GoogleFonts.inter(
        fontSize: 11,
        height: 1.4,
        color: Colors.grey.shade700,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Map<String, dynamic>? _firstEvidence(Map<String, dynamic> item) {
    final raw = item['evidence'];
    if (raw is! List || raw.isEmpty) return null;
    final first = raw.first;
    if (first is! Map) return null;
    return Map<String, dynamic>.from(first);
  }

  String? _firstText(Map<String, dynamic> item, List<String> keys) {
    for (final key in keys) {
      final value = item[key];
      if (value is String && value.trim().isNotEmpty) return value.trim();
    }
    return null;
  }

  List<String> _stringList(Map<String, dynamic> item, String key) {
    final raw = item[key];
    if (raw is! List) return const [];
    return raw
        .map((e) => e?.toString().trim() ?? '')
        .where((e) => e.isNotEmpty)
        .toList(growable: false);
  }

  String _problemLabel(
    CropV2Bundle v2,
    String? problemId,
    String category,
  ) {
    if (problemId != null && problemId.isNotEmpty) {
      for (final item in [...v2.diseases, ...v2.pests, ...v2.weeds]) {
        if (item['id'] == problemId) {
          return _firstText(item, const ['name_tr', 'title']) ??
              _categoryLabel(category);
        }
      }
      const custom = {
        'physiology.tomato.blossom_end_rot': 'Çiçek burnu çürüklüğü',
        'physiology.tomato.flower_drop': 'Çiçek dökülmesi',
      };
      final label = custom[problemId];
      if (label != null) return label;
    }
    return _categoryLabel(category);
  }

  String _categoryLabel(String category) => switch (category) {
        'disease_risk' => 'Hastalık riski',
        'pest_risk' => 'Zararlı riski',
        'physiological_risk' => 'Fizyolojik risk',
        'soil_analysis' => 'Toprak analizi',
        'irrigation' => 'Sulama',
        'nutrition_risk' => 'Besleme riski',
        'harvest_quality' => 'Hasat kalitesi',
        _ => 'Kaynaklı kural',
      };

  String _statusLabel(String? status) => switch (status) {
        'approved' => 'Onaylı',
        'review' => 'İncelemede',
        'draft' => 'Taslak',
        'pending_sources' => 'Kaynak bekliyor',
        _ => 'Kaynaklı',
      };

  String _confidenceLabel(String? confidence) => switch (confidence) {
        'high' => 'Yüksek güven',
        'medium' => 'Orta güven',
        'low' => 'Düşük güven',
        _ => 'Güven belirtilmedi',
      };

  String _riskLabel(String? risk) => switch (risk) {
        'high' => 'Yüksek',
        'medium' => 'Orta',
        'low' => 'Düşük',
        _ => 'Risk',
      };

  Color _riskColor(String? risk) => switch (risk) {
        'high' => Colors.red.shade700,
        'medium' => Colors.orange.shade800,
        'low' => AppColors.emeraldDark,
        _ => Colors.blueGrey,
      };

  String _sourceLabel(String? sourceId) {
    final id = sourceId ?? '';
    if (id.contains('caykur')) return 'ÇAYKUR';
    if (id.contains('tagem')) return 'TAGEM';
    if (id.contains('mgm')) return 'MGM';
    return 'Kaynak';
  }

  Widget _header() {
    return Row(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: AppColors.emerald.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(Icons.local_florist_rounded,
              color: AppColors.emeraldDark, size: 32),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(crop.nameTr,
                  style: GoogleFonts.inter(
                      fontSize: 22, fontWeight: FontWeight.w800)),
              if (crop.scientificName != null)
                Text(crop.scientificName!,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                      color: Colors.grey.shade600,
                    )),
              const SizedBox(height: 4),
              _chip(crop.category, AppColors.emerald),
            ],
          ),
        ),
      ],
    );
  }

  Widget _summaryIcons() {
    final items = <_IconStat>[];
    if (crop.optimalTempC != null) {
      items.add(_IconStat(
        Icons.thermostat_rounded,
        'Sıcaklık',
        '${crop.tempMinC?.toStringAsFixed(0) ?? '?'}-${crop.tempMaxC?.toStringAsFixed(0) ?? '?'}°C',
        Colors.orange,
      ));
    }
    if (crop.waterNeed != null) {
      items.add(_IconStat(
        Icons.water_drop_rounded,
        'Su',
        switch (crop.waterNeed!) {
          'low' => 'Az',
          'medium' => 'Orta',
          'high' => 'Bol',
          _ => crop.waterNeed!,
        },
        Colors.blue,
      ));
    }
    if (crop.sunNeed != null) {
      items.add(_IconStat(
        Icons.wb_sunny_rounded,
        'Güneş',
        switch (crop.sunNeed!) {
          'full' => 'Tam',
          'partial' => 'Yarı',
          'shade' => 'Gölge',
          _ => crop.sunNeed!,
        },
        Colors.amber,
      ));
    }
    if (crop.soilPhMin != null && crop.soilPhMax != null) {
      items.add(_IconStat(
        Icons.science_rounded,
        'pH',
        '${crop.soilPhMin!.toStringAsFixed(1)}-${crop.soilPhMax!.toStringAsFixed(1)}',
        Colors.purple,
      ));
    }
    if (items.isEmpty) return const SizedBox.shrink();
    return Row(
      children: items.map((s) {
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: s.color.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  Icon(s.icon, color: s.color, size: 22),
                  const SizedBox(height: 4),
                  Text(s.value,
                      style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: s.color)),
                  Text(s.label,
                      style: GoogleFonts.inter(
                          fontSize: 10, color: Colors.grey.shade600)),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _calendarBar() {
    const labels = ['O', 'Ş', 'M', 'N', 'M', 'H', 'T', 'A', 'E', 'E', 'K', 'A'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Ekim ve Hasat Takvimi', Icons.calendar_month_rounded),
        const SizedBox(height: 8),
        Row(
          children: List.generate(12, (i) {
            final month = i + 1;
            final isSow = crop.sowingMonths.contains(month);
            final isHarvest = crop.harvestMonths.contains(month);
            Color? bg;
            if (isSow && isHarvest) {
              bg = Colors.purple.shade400;
            } else if (isSow) {
              bg = AppColors.emerald;
            } else if (isHarvest) {
              bg = Colors.orange.shade700;
            }
            return Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 2),
                height: 36,
                decoration: BoxDecoration(
                  color: bg ?? Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(6),
                ),
                alignment: Alignment.center,
                child: Text(
                  labels[i],
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: bg != null ? Colors.white : Colors.grey.shade500,
                  ),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            _legend(AppColors.emerald, 'Ekim'),
            const SizedBox(width: 12),
            _legend(Colors.orange.shade700, 'Hasat'),
            const SizedBox(width: 12),
            _legend(Colors.purple.shade400, 'Her ikisi'),
          ],
        ),
      ],
    );
  }

  Widget _legend(Color c, String label) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration:
              BoxDecoration(color: c, borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(width: 4),
        Text(label,
            style:
                GoogleFonts.inter(fontSize: 11, color: Colors.grey.shade600)),
      ],
    );
  }

  Widget _sectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.emeraldDark),
        const SizedBox(width: 6),
        Text(title,
            style:
                GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w800)),
      ],
    );
  }

  Widget _chip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(text,
          style: GoogleFonts.inter(
              fontSize: 12, fontWeight: FontWeight.w600, color: color)),
    );
  }

  Widget _kv(String k, String v) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(k,
                style: GoogleFonts.inter(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w600)),
          ),
          Expanded(
            child: Text(v,
                style: GoogleFonts.inter(
                    fontSize: 14, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _paragraph(String t) => Text(t,
      style: GoogleFonts.inter(
          fontSize: 13, color: Colors.grey.shade800, height: 1.5));
}

class _IconStat {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  _IconStat(this.icon, this.label, this.value, this.color);
}

class _EmptyDbNotice extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_rounded,
                size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text('Bitki veritabanı yüklenmedi',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                    fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(
              'backend/data_pipeline/build_turkish_crops_db.py scriptini çalıştır,\n'
              'sonra uygulamayı yeniden aç.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                  fontSize: 13, color: Colors.grey.shade600, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}
