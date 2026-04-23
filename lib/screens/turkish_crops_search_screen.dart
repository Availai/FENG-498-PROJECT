import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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
            if (crop.fertilizerNotes != null) ...[
              const SizedBox(height: 16),
              _sectionTitle('Gübreleme', Icons.scatter_plot_rounded),
              const SizedBox(height: 6),
              _paragraph(crop.fertilizerNotes!),
            ],
            if (crop.commonPests.isNotEmpty) ...[
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
            if (crop.commonDiseases.isNotEmpty) ...[
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
            if (crop.growingTips != null) ...[
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
    const labels = ['O','Ş','M','N','M','H','T','A','E','E','K','A'];
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
          decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(width: 4),
        Text(label,
            style: GoogleFonts.inter(
                fontSize: 11, color: Colors.grey.shade600)),
      ],
    );
  }

  Widget _sectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.emeraldDark),
        const SizedBox(width: 6),
        Text(title,
            style: GoogleFonts.inter(
                fontSize: 14, fontWeight: FontWeight.w800)),
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
