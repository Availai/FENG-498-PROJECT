/// SeedSelectorScreen — Anadolu Tohum Veritabanı + Büyüme Simülasyonu
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/seed_models.dart';
import '../data/supported_crops.dart';
import '../services/anatolian_seed_db.dart';
import '../services/agri_sim_service.dart';
import '../theme/app_theme.dart';

class SeedSelectorScreen extends StatefulWidget {
  const SeedSelectorScreen({super.key});

  @override
  State<SeedSelectorScreen> createState() => _SeedSelectorScreenState();
}

class _SeedSelectorScreenState extends State<SeedSelectorScreen>
    with SingleTickerProviderStateMixin {
  String? _selectedCrop;
  TurkishRegion _region = TurkishRegion.icAnadolu;
  List<SeedVariety> _varieties = [];
  SeedVariety? _selected;
  SimulationResult? _sim;
  late TabController _tabs;

  static const _crops = SupportedCrops.visibleNames;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _loadVarieties();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  void _loadVarieties() {
    setState(() {
      final raw =
          AnatolianSeedDB.getAll(cropTr: _selectedCrop, region: _region);
      // Prototip: Ayçiçeği / Mısır / Domates dışındaki çeşitler gizli.
      _varieties =
          raw.where((v) => SupportedCrops.isSupported(v.cropTr)).toList();
      _selected = null;
      _sim = null;
    });
  }

  void _selectVariety(SeedVariety v) {
    final sim = AgriSimService.simulate(
        variety: v, sowDate: DateTime.now(), region: _region);
    setState(() {
      _selected = v;
      _sim = sim;
    });
    _tabs.animateTo(1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Anadolu Tohum DB', style: AppText.h2(context)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: TabBar(
            controller: _tabs,
            indicatorColor: AppColors.emerald,
            indicatorWeight: 2,
            labelColor: AppColors.emeraldDark,
            unselectedLabelColor: AppColors.textSecondary,
            labelStyle:
                GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
            tabs: const [Tab(text: 'Çeşit Tarama'), Tab(text: 'Simülasyon')],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _VarietyBrowserTab(
            crops: _crops,
            selectedCrop: _selectedCrop,
            region: _region,
            varieties: _varieties,
            selected: _selected,
            onCropChanged: (c) {
              _selectedCrop = c;
              _loadVarieties();
            },
            onRegionChanged: (r) {
              _region = r;
              _loadVarieties();
            },
            onVarietyTap: _selectVariety,
          ),
          _SimulationTab(variety: _selected, sim: _sim),
        ],
      ),
    );
  }
}

// ── Çeşit Tarama ─────────────────────────────────────────────────────────

class _VarietyBrowserTab extends StatelessWidget {
  final List<String> crops;
  final String? selectedCrop;
  final TurkishRegion region;
  final List<SeedVariety> varieties;
  final SeedVariety? selected;
  final ValueChanged<String?> onCropChanged;
  final ValueChanged<TurkishRegion> onRegionChanged;
  final ValueChanged<SeedVariety> onVarietyTap;

  const _VarietyBrowserTab({
    required this.crops,
    required this.selectedCrop,
    required this.region,
    required this.varieties,
    required this.selected,
    required this.onCropChanged,
    required this.onRegionChanged,
    required this.onVarietyTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Crop chips
        Container(
          color: AppColors.surface,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Column(
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [null, ...crops].map((c) {
                    final isSelected = c == selectedCrop;
                    return GestureDetector(
                      onTap: () => onCropChanged(c),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.emerald : AppColors.bg,
                          borderRadius: AppRadius.full,
                          border: Border.all(
                              color: isSelected
                                  ? AppColors.emerald
                                  : AppColors.border),
                        ),
                        child: Text(
                          c ?? 'Tümü',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isSelected
                                ? Colors.white
                                : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 10),
              // Region picker
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: TurkishRegion.values.map((r) {
                    final isSelected = r == region;
                    return GestureDetector(
                      onTap: () => onRegionChanged(r),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.emeraldDark
                              : Colors.transparent,
                          borderRadius: AppRadius.full,
                          border: Border.all(
                              color: isSelected
                                  ? AppColors.emeraldDark
                                  : AppColors.border),
                        ),
                        child: Text(
                          r.label,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: isSelected
                                ? Colors.white
                                : AppColors.textTertiary,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(children: [
            Text('${varieties.length} çeşit', style: AppText.sm(context)),
            const Spacer(),
            if (selected != null)
              AppTag('${selected!.nameTr} seçildi', color: AppColors.emerald),
          ]),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
            itemCount: varieties.length,
            itemBuilder: (_, i) => _VarietyCard(
              variety: varieties[i],
              isSelected: varieties[i].id == selected?.id,
              onTap: () => onVarietyTap(varieties[i]),
            ),
          ),
        ),
      ],
    );
  }
}

class _VarietyCard extends StatelessWidget {
  final SeedVariety variety;
  final bool isSelected;
  final VoidCallback onTap;
  const _VarietyCard(
      {required this.variety, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.md,
          border: Border.all(
            color: isSelected ? AppColors.emerald : AppColors.border,
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: isSelected ? AppShadows.md : AppShadows.sm,
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Expanded(
                  child: Text(
                    variety.nameTr,
                    style: AppText.h3(context).copyWith(
                      color: isSelected
                          ? AppColors.emeraldDark
                          : AppColors.textPrimary,
                    ),
                  ),
                ),
                AppTag(variety.cropTr,
                    color: AppColors.sage, bgColor: AppColors.mint),
                const SizedBox(width: 6),
                Text(variety.registrationYear.toString(),
                    style: AppText.xs(context)),
              ]),
              const SizedBox(height: 4),
              Text(variety.breeder, style: AppText.sm(context)),
              const SizedBox(height: 10),
              // Stats row
              Row(children: [
                _ToleranceDot(
                    'Verim',
                    '${variety.avgYieldKgDekar.round()} kg/da',
                    AppColors.emerald),
                const SizedBox(width: 8),
                _ToleranceDot('Kuraklık', _pct(variety.droughtTolerance),
                    _toleranceColor(variety.droughtTolerance)),
                const SizedBox(width: 8),
                _ToleranceDot('Don', _pct(variety.frostTolerance),
                    _toleranceColor(variety.frostTolerance)),
              ]),
              const SizedBox(height: 10),
              // Phenology mini timeline
              _PhenologyBar(stages: variety.phenology),
              if (variety.notes.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(variety.notes,
                    style: AppText.sm(context),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
              ],
              if (isSelected) ...[
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    const Icon(Icons.play_circle_outline_rounded,
                        size: 14, color: AppColors.emerald),
                    const SizedBox(width: 4),
                    Text('Simülasyonu Görüntüle →',
                        style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.emerald)),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _pct(double v) => '%${(v * 100).round()}';
  Color _toleranceColor(double t) {
    if (t >= 0.7) return AppColors.success;
    if (t >= 0.5) return AppColors.warning;
    return AppColors.error;
  }
}

class _ToleranceDot extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _ToleranceDot(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.07),
          borderRadius: AppRadius.sm,
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: AppText.xs(context)),
            const SizedBox(height: 2),
            Text(value,
                style: GoogleFonts.outfit(
                    fontSize: 13, fontWeight: FontWeight.w700, color: color)),
          ],
        ),
      ),
    );
  }
}

class _PhenologyBar extends StatelessWidget {
  final List<PhenologyStageDef> stages;
  const _PhenologyBar({required this.stages});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Fenoloji', style: AppText.xs(context)),
        const SizedBox(height: 6),
        Row(
          children: stages.asMap().entries.map((e) {
            final isLast = e.key == stages.length - 1;
            return Expanded(
              child: Row(
                children: [
                  Column(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: isLast ? AppColors.emerald : AppColors.bg,
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: isLast
                                  ? AppColors.emerald
                                  : AppColors.border),
                        ),
                        child: Center(
                            child: Text(e.value.stage.icon,
                                style: const TextStyle(fontSize: 10))),
                      ),
                      const SizedBox(height: 3),
                      Text(e.value.stage.labelTr,
                          style: AppText.xs(context).copyWith(fontSize: 9),
                          overflow: TextOverflow.visible,
                          softWrap: false),
                    ],
                  ),
                  if (!isLast)
                    Expanded(
                        child: Container(height: 1, color: AppColors.border)),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

// ── Simülasyon Sekmesi ────────────────────────────────────────────────────

class _SimulationTab extends StatelessWidget {
  final SeedVariety? variety;
  final SimulationResult? sim;
  const _SimulationTab({this.variety, this.sim});

  @override
  Widget build(BuildContext context) {
    if (variety == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                    color: AppColors.mint, borderRadius: AppRadius.lg),
                child: const Center(
                    child: Text('🌱', style: TextStyle(fontSize: 32))),
              ),
              const SizedBox(height: 16),
              Text('Çeşit Seçilmedi', style: AppText.h3(context)),
              const SizedBox(height: 6),
              Text(
                  'Çeşit Tarama sekmesinden bir çeşit seçerek büyüme simülasyonunu başlatın.',
                  style: AppText.sm(context),
                  textAlign: TextAlign.center),
            ],
          ),
        ),
      );
    }

    final result = sim!;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        _SimSummaryCard(result: result),
        const SizedBox(height: 12),
        _PhenologyDatesCard(result: result),
        const SizedBox(height: 12),
        _GrowthChartCard(records: result.dailyRecords),
        const SizedBox(height: 12),
        _EventsCard(records: result.dailyRecords),
      ],
    );
  }
}

class _SimSummaryCard extends StatelessWidget {
  final SimulationResult result;
  const _SimSummaryCard({required this.result});

  @override
  Widget build(BuildContext context) {
    final daysLeft = result.estimatedHarvestDate
        .difference(DateTime.now())
        .inDays
        .clamp(0, 999);
    return Container(
      decoration: BoxDecoration(
        gradient: AppGradients.forestHero,
        borderRadius: AppRadius.lg,
        boxShadow: AppShadows.lg,
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(result.variety.nameTr, style: AppText.h1Dark(context)),
          const SizedBox(height: 4),
          Text(result.variety.cropTr, style: AppText.bodyDark(context)),
          const SizedBox(height: 16),
          Row(children: [
            _DarkStat('Ekim', _fmtDate(result.sowDate)),
            const SizedBox(width: 20),
            _DarkStat('Hasat', _fmtDate(result.estimatedHarvestDate)),
            const SizedBox(width: 20),
            _DarkStat('Kalan', '$daysLeft gün'),
          ]),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('İlerleme',
                      style: AppText.bodyDark(context).copyWith(fontSize: 11)),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: AppRadius.full,
                    child: LinearProgressIndicator(
                      value: result.progressPercent / 100,
                      minHeight: 6,
                      backgroundColor: Colors.white.withValues(alpha: 0.15),
                      valueColor:
                          const AlwaysStoppedAnimation(AppColors.emeraldLight),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                      '${result.progressPercent.toStringAsFixed(0)}% — ${result.currentStage.labelTr}',
                      style: AppText.bodyDark(context).copyWith(fontSize: 11)),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Column(
              children: [
                Text(result.predictedYieldKgDekar.toStringAsFixed(0),
                    style: GoogleFonts.outfit(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: AppColors.emeraldLight)),
                Text('kg/da',
                    style: AppText.bodyDark(context).copyWith(fontSize: 10)),
              ],
            ),
          ]),
        ],
      ),
    );
  }

  String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';
}

class _DarkStat extends StatelessWidget {
  final String label;
  final String value;
  const _DarkStat(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: GoogleFonts.inter(
                fontSize: 10, color: AppColors.textOnDarkMuted)),
        Text(value,
            style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textOnDark)),
      ],
    );
  }
}

class _PhenologyDatesCard extends StatelessWidget {
  final SimulationResult result;
  const _PhenologyDatesCard({required this.result});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.md,
          boxShadow: AppShadows.sm,
          border: Border.all(color: AppColors.border)),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Fenoloji Takvimi', style: AppText.h3(context)),
          const SizedBox(height: 12),
          ...result.stageDates.entries.map((e) {
            final d = e.value;
            final isPast = d.isBefore(DateTime.now());
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(children: [
                Text(e.key.icon, style: const TextStyle(fontSize: 16)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    e.key.labelTr,
                    style: AppText.body(context).copyWith(
                        color: isPast
                            ? AppColors.textTertiary
                            : AppColors.textPrimary),
                  ),
                ),
                AppTag(
                  '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}',
                  color: isPast ? AppColors.textTertiary : AppColors.emerald,
                  bgColor: isPast ? AppColors.bg : AppColors.successBg,
                ),
              ]),
            );
          }),
        ],
      ),
    );
  }
}

class _GrowthChartCard extends StatelessWidget {
  final List<GrowthDayRecord> records;
  const _GrowthChartCard({required this.records});

  @override
  Widget build(BuildContext context) {
    final slice =
        records.length > 30 ? records.sublist(records.length - 30) : records;
    return Container(
      height: 140,
      decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.md,
          boxShadow: AppShadows.sm,
          border: Border.all(color: AppColors.border)),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Boy Gelişimi (cm) — son 30 gün', style: AppText.xs(context)),
          const SizedBox(height: 8),
          Expanded(
            child: CustomPaint(
              painter: _MiniLinePainter(
                  values: slice.map((r) => r.heightCm).toList()),
              size: const Size(double.infinity, double.infinity),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniLinePainter extends CustomPainter {
  final List<double> values;
  const _MiniLinePainter({required this.values});

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;
    final maxV = values.reduce((a, b) => a > b ? a : b);
    if (maxV == 0) return;

    final path = Path();
    for (int i = 0; i < values.length; i++) {
      final x = i / (values.length - 1) * size.width;
      final y = size.height - (values[i] / maxV) * size.height;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(
        path,
        Paint()
          ..color = AppColors.emerald
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round);

    final fill = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(
        fill,
        Paint()
          ..color = AppColors.emerald.withValues(alpha: 0.08)
          ..style = PaintingStyle.fill);

    // Grid lines
    for (int i = 1; i <= 3; i++) {
      final y = size.height * i / 4;
      canvas.drawLine(
          Offset(0, y),
          Offset(size.width, y),
          Paint()
            ..color = AppColors.border
            ..strokeWidth = 0.5);
    }
  }

  @override
  bool shouldRepaint(_MiniLinePainter old) => old.values != values;
}

class _EventsCard extends StatelessWidget {
  final List<GrowthDayRecord> records;
  const _EventsCard({required this.records});

  @override
  Widget build(BuildContext context) {
    final events = records.where((r) => r.event != null).toList();
    if (events.isEmpty) return const SizedBox.shrink();
    return Container(
      decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.md,
          boxShadow: AppShadows.sm,
          border: Border.all(color: AppColors.border)),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Önemli Olaylar', style: AppText.h3(context)),
          const SizedBox(height: 10),
          ...events.map((r) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Row(children: [
                  Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                          color: AppColors.mint, borderRadius: AppRadius.sm),
                      child: Center(
                          child: Text('Gün\n${r.dayNumber}',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.emeraldDark)))),
                  const SizedBox(width: 10),
                  Expanded(child: Text(r.event!, style: AppText.body(context))),
                ]),
              )),
        ],
      ),
    );
  }
}
