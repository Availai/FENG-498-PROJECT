import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/crop_layer.dart';
import '../services/app_providers.dart';
import '../services/companion_service.dart';
import '../widgets/top_down_field_view.dart';

class GardenManagerScreen extends ConsumerStatefulWidget {
  final dynamic fieldData;

  const GardenManagerScreen({super.key, required this.fieldData});

  @override
  ConsumerState<GardenManagerScreen> createState() => _GardenManagerScreenState();
}

class _GardenManagerScreenState extends ConsumerState<GardenManagerScreen> {
  List<Map<String, dynamic>> _crops = [];
  bool _dirty = false; // kayıt bekliyor mu

  // Tarla boyutları
  late double _fieldWidthM;
  late double _fieldHeightM;
  late double _areaM2;

  @override
  void initState() {
    super.initState();
    _computeDimensions();
    _loadCropsFromRepository();
  }

  // ── Boyut hesaplama (TopDownFieldView ile aynı newton yöntemi) ─────────
  void _computeDimensions() {
    final d = widget.fieldData;
    final dekar = (d['area_dekar'] as num?)?.toDouble() ?? 1.0;
    _areaM2 = dekar * 1000.0;
    double h = _areaM2 / 2;
    for (int i = 0; i < 20; i++) {
      h = (h + (_areaM2 / 1.5) / h) / 2;
    }
    _fieldHeightM = h.clamp(5.0, 500.0);
    _fieldWidthM = (_areaM2 / _fieldHeightM).clamp(5.0, 500.0);
  }

  Future<void> _loadCropsFromRepository() async {
    final fieldId = widget.fieldData['id']?.toString();
    if (fieldId == null) {
      if (!mounted) return;
      setState(() => _crops = []);
      return;
    }

    final crops = await ref.read(localDataRepositoryProvider).loadFieldCrops(fieldId);
    if (!mounted) return;
    setState(() => _crops = crops);
  }

  Future<void> _saveToRepository() async {
    final fieldId = widget.fieldData['id']?.toString();
    if (fieldId == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Alan kimliği bulunamadı, kayıt yapılamadı.')),
      );
      return;
    }

    await ref.read(localDataRepositoryProvider).replaceFieldCrops(
          fieldId: fieldId,
          crops: _crops.map((c) => Map<String, dynamic>.from(c)).toList(),
        );
    if (!mounted) return;
    setState(() => _dirty = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Bahçe kaydedildi!')),
    );
  }

  // ── CropLayer listesi üret (TopDownFieldView için) ─────────────────────
  List<CropLayer> get _cropLayers => _crops.map((c) {
        final colorInt = c['color_value'] as int? ?? 0xFF4CAF50;
        return CropLayer(
          name: c['name'] as String,
          color: Color(colorInt),
          rowSpacingCm: (c['row_spacing_cm'] as num).toDouble(),
          plantSpacingCm: (c['plant_spacing_cm'] as num).toDouble(),
          startPercent: (c['zone_start'] as num).toDouble(),
          endPercent: (c['zone_end'] as num).toDouble(),
        );
      }).toList();

  // ── Uyarıları üret ────────────────────────────────────────────────────
  List<GardenWarning> get _warnings => CompanionService.generateWarnings(
        crops: _crops,
        fieldWidthM: _fieldWidthM,
        fieldHeightM: _fieldHeightM,
      );

  // ── Toplam bitki sayısı ───────────────────────────────────────────────
  int _totalPlants() {
    int total = 0;
    for (final c in _crops) {
      total += CompanionService.estimatePlantCount(
        fieldWidthM: _fieldWidthM,
        fieldHeightM: _fieldHeightM,
        zoneStart: (c['zone_start'] as num).toDouble(),
        zoneEnd: (c['zone_end'] as num).toDouble(),
        rowSpacingCm: (c['row_spacing_cm'] as num).toDouble(),
        plantSpacingCm: (c['plant_spacing_cm'] as num).toDouble(),
      );
    }
    return total;
  }

  double _totalCoverage() {
    double t = 0;
    for (final c in _crops) {
      t += (c['zone_end'] as num).toDouble() -
          (c['zone_start'] as num).toDouble();
    }
    return t.clamp(0.0, 1.0);
  }

  // ────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final d = widget.fieldData;
    final fieldName = d['name'] ?? 'Tarla';
    final dekar = (d['area_dekar'] as num?)?.toDouble() ?? 1.0;
    final warnings = _warnings;
    final errorCount = warnings.where((w) => w.level == WarnLevel.error).length;

    return Scaffold(
      appBar: AppBar(
        title: Row(children: [
          const Text('🌿 '),
          Expanded(
              child: Text(fieldName, overflow: TextOverflow.ellipsis)),
        ]),
        actions: [
          if (_dirty)
            IconButton(
              icon: const Icon(Icons.save, color: Colors.white),
              onPressed: () => _saveToRepository(),
              tooltip: 'Kaydet',
            ),
          if (errorCount > 0)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Badge(
                backgroundColor: Colors.red,
                label: Text('$errorCount'),
                child: const Icon(Icons.warning_amber),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddCropDialog,
        backgroundColor: Colors.green.shade700,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Bitki Ekle', style: TextStyle(color: Colors.white)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
          // ── TARLA BİLGİ KARTI ──────────────────────────────────────────
          _fieldInfoCard(dekar),
          const SizedBox(height: 16),

          // ── CANLI BAHÇE GÖRSELLEŞTİRME ────────────────────────────────
          const Text('🗺️ Canlı Bahçe Görünümü',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          _crops.isEmpty
              ? _emptyGardenCard()
              : TopDownFieldView(
                  key: ValueKey(_crops.length),
                  fieldName: fieldName,
                  areaDekar: dekar,
                  plantingData: {
                    'row_spacing_cm':
                        (_crops.first['row_spacing_cm'] as num).toDouble(),
                    'plant_spacing_cm':
                        (_crops.first['plant_spacing_cm'] as num).toDouble(),
                    'seeds_per_dekar': 500,
                    'irrigation_type': 'Damla Sulama',
                    'irrigation_line_spacing_cm': 70,
                    'irrigation_dripper_spacing_cm': 30,
                    'fertilizer_band_cm': 15,
                    'fertilizer_type': 'NPK 15-15-15',
                  },
                  cropName: _crops.first['name'] as String,
                  extraCrops: _cropLayers,
                ),

          const SizedBox(height: 16),

          // ── UYARILAR ───────────────────────────────────────────────────
          if (warnings.isNotEmpty) ...[
            Row(children: [
              const Text('⚠️ Uyarılar & Öneriler',
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: errorCount > 0
                      ? Colors.red.shade100
                      : Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text('${warnings.length}',
                    style: TextStyle(
                        color: errorCount > 0
                            ? Colors.red.shade700
                            : Colors.orange.shade700,
                        fontWeight: FontWeight.bold)),
              ),
            ]),
            const SizedBox(height: 8),
            ...warnings.map((w) => _warningCard(w)),
            const SizedBox(height: 8),
          ],

          // ── EKİLEN BİTKİLER ────────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('🌱 Ekilen Bitkiler',
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              if (_crops.isNotEmpty)
                Text('Toplam: ${_totalPlants()} bitki',
                    style: TextStyle(
                        color: Colors.green.shade700, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 8),
          _crops.isEmpty
              ? _noCropsHint()
              : Column(
                  children: List.generate(
                      _crops.length, (i) => _cropCard(i))),

          const SizedBox(height: 80), // FAB boşluğu
        ]),
      ),
    );
  }

  // ── Tarla bilgi kartı ──────────────────────────────────────────────────
  Widget _fieldInfoCard(double dekar) {
    final coverage = (_totalCoverage() * 100).toStringAsFixed(0);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
            colors: [Colors.green.shade700, Colors.teal.shade600]),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(children: [
        Expanded(
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            Text('${_fieldWidthM.toStringAsFixed(0)} m × ${_fieldHeightM.toStringAsFixed(0)} m',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold)),
            Text(
                '${_areaM2.toStringAsFixed(0)} m²  •  ${dekar.toStringAsFixed(1)} Dekar',
                style: const TextStyle(
                    color: Colors.white70, fontSize: 13)),
          ]),
        ),
        Column(children: [
          Text('$coverage%',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold)),
          const Text('Kapsama',
              style: TextStyle(color: Colors.white70, fontSize: 12)),
        ]),
      ]),
    );
  }

  // ── Boş bahçe ─────────────────────────────────────────────────────────
  Widget _emptyGardenCard() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(children: [
        Icon(Icons.grass, size: 60, color: Colors.green.shade300),
        const SizedBox(height: 12),
        Text('Henüz bitki eklenmedi',
            style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 16,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text('Aşağıdaki "Bitki Ekle" butonuyla başlayın',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
      ]),
    );
  }

  Widget _noCropsHint() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: const Text(
          '+ Bitki Ekle butonunu kullanarak birden fazla bitki '
          'ekleyebilir, her bitkiye tarla içinde yer atayabilirsiniz.',
          style: TextStyle(fontSize: 14, height: 1.5)),
    );
  }

  // ── Uyarı kartı ───────────────────────────────────────────────────────
  Widget _warningCard(GardenWarning w) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: w.bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: w.color.withValues(alpha: 0.4)),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(w.icon, color: w.color, size: 22),
        const SizedBox(width: 10),
        Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
          Text('${w.emoji} ${w.title}',
              style: TextStyle(
                  color: w.color,
                  fontWeight: FontWeight.bold,
                  fontSize: 14)),
          const SizedBox(height: 4),
          Text(w.message,
              style: const TextStyle(fontSize: 13, height: 1.4)),
        ])),
      ]),
    );
  }

  // ── Tek bitki kartı ───────────────────────────────────────────────────
  Widget _cropCard(int index) {
    final c = _crops[index];
    final name = c['name'] as String;
    final start = (c['zone_start'] as num).toDouble();
    final end = (c['zone_end'] as num).toDouble();
    final row = (c['row_spacing_cm'] as num).toDouble();
    final plant = (c['plant_spacing_cm'] as num).toDouble();
    final colorInt = c['color_value'] as int? ?? 0xFF4CAF50;
    final color = Color(colorInt);
    final plantedDate = c['planted_date'] as String? ?? '';
    final defaults = CompanionService.getDefaults(name);
    final emoji = defaults?.emoji ?? '🌱';
    final plantCount = CompanionService.estimatePlantCount(
      fieldWidthM: _fieldWidthM,
      fieldHeightM: _fieldHeightM,
      zoneStart: start,
      zoneEnd: end,
      rowSpacingCm: row,
      plantSpacingCm: plant,
    );
    final zoneWidthM = _fieldWidthM * (end - start);
    final zoneAreaM2 = zoneWidthM * _fieldHeightM;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
          Row(children: [
            // Renk + emoji
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
                border: Border.all(color: color, width: 2),
              ),
              child: Center(
                  child: Text(emoji,
                      style: const TextStyle(fontSize: 22))),
            ),
            const SizedBox(width: 12),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
              Text(name,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16)),
              if (plantedDate.isNotEmpty)
                Text('Ekim: $plantedDate',
                    style: TextStyle(
                        fontSize: 12, color: Colors.grey.shade500)),
            ])),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: () => _deleteCrop(index),
              tooltip: 'Kaldır',
            ),
          ]),

          const SizedBox(height: 10),

          // Bölge göstergesi
          _zoneBar(start, end, color),

          const SizedBox(height: 8),

          // İstatistikler
          Wrap(spacing: 8, runSpacing: 6, children: [
            _statChip(
                Icons.straighten,
                '${(zoneWidthM).toStringAsFixed(1)} m × '
                    '${_fieldHeightM.toStringAsFixed(0)} m',
                Colors.teal),
            _statChip(Icons.grid_on,
                '${zoneAreaM2.toStringAsFixed(0)} m² alan', Colors.blue),
            _statChip(
                Icons.eco, '$plantCount bitki', Colors.green.shade700),
            _statChip(Icons.swap_vert, '${row.round()} cm sıra arası',
                Colors.brown),
            _statChip(Icons.swap_horiz,
                '${plant.round()} cm bitki arası', Colors.orange),
          ]),
        ]),
      ),
    );
  }

  // ── Bölge çubuğu ─────────────────────────────────────────────────────
  Widget _zoneBar(double start, double end, Color color) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(
          'Bölge: %${(start * 100).round()} – %${(end * 100).round()} '
          '(${((end - start) * 100).round()}% tarla)',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
      const SizedBox(height: 4),
      ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Stack(children: [
          Container(
              height: 12,
              width: double.infinity,
              color: Colors.grey.shade200),
          FractionallySizedBox(
            widthFactor: end - start,
            child: FractionalTranslation(
              translation: Offset(start / (end - start == 0 ? 1 : end - start) * (end - start), 0),
              child: Container(height: 12, color: color.withValues(alpha: 0.7)),
            ),
          ),
          Positioned.fill(
            child: LayoutBuilder(builder: (ctx, constraints) {
              return Stack(children: [
                Positioned(
                  left: constraints.maxWidth * start,
                  width: constraints.maxWidth * (end - start),
                  top: 0,
                  height: 12,
                  child: Container(
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ]);
            }),
          ),
        ]),
      ),
    ]);
  }

  Widget _statChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 4),
        Text(label,
            style: TextStyle(
                fontSize: 12, color: color, fontWeight: FontWeight.w600)),
      ]),
    );
  }

  // ── Bitki silme ────────────────────────────────────────────────────────
  void _deleteCrop(int index) {
    final name = _crops[index]['name'];
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Bitkiyi Kaldır'),
        content: Text('$name bu tarladan kaldırılsın mı?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('İptal')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                _crops.removeAt(index);
                _dirty = true;
              });
              _saveToRepository();
            },
            child: const Text('Kaldır'),
          ),
        ],
      ),
    );
  }

  // ── Bitki ekleme diyaloğu ──────────────────────────────────────────────
  void _showAddCropDialog() {
    String selectedCrop = CompanionService.cropNames.first;
    double zoneStart = 0.0;
    double zoneEnd = 0.5;
    double? rowCm;
    double? plantCm;

    // Mevcut alanların dışındaki ilk boş bölgeyi bul
    if (_crops.isNotEmpty) {
      double maxEnd = 0;
      for (final c in _crops) {
        final e = (c['zone_end'] as num).toDouble();
        if (e > maxEnd) maxEnd = e;
      }
      zoneStart = maxEnd.clamp(0.0, 0.9);
      zoneEnd = (zoneStart + 0.5).clamp(zoneStart + 0.05, 1.0);
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) {
          final defaults = CompanionService.getDefaults(selectedCrop);
          rowCm ??= defaults?.rowSpacingCm ?? 50;
          plantCm ??= defaults?.plantSpacingCm ?? 40;
          final preview = CompanionService.estimatePlantCount(
            fieldWidthM: _fieldWidthM,
            fieldHeightM: _fieldHeightM,
            zoneStart: zoneStart,
            zoneEnd: zoneEnd,
            rowSpacingCm: rowCm!,
            plantSpacingCm: plantCm!,
          );
          final zoneW =
              (_fieldWidthM * (zoneEnd - zoneStart)).toStringAsFixed(1);
          final zoneA =
              (_fieldWidthM * (zoneEnd - zoneStart) * _fieldHeightM)
                  .toStringAsFixed(0);

          return Padding(
            padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
                left: 20, right: 20, top: 20),
            child: SingleChildScrollView(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                // Başlık
                Row(children: [
                  Text(defaults?.emoji ?? '🌱',
                      style: const TextStyle(fontSize: 30)),
                  const SizedBox(width: 12),
                  const Text('Yeni Bitki Ekle',
                      style: TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold)),
                ]),
                const SizedBox(height: 16),

                // Bitki seçimi
                const Text('Bitki Seç',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  initialValue: selectedCrop,
                  decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10)),
                  items: CompanionService.cropNames
                      .map((n) => DropdownMenuItem(
                          value: n,
                          child: Row(children: [
                            Text(
                                CompanionService.getDefaults(n)?.emoji ??
                                    '🌱'),
                            const SizedBox(width: 8),
                            Text(n),
                          ])))
                      .toList(),
                  onChanged: (v) {
                    if (v == null) return;
                    setSheet(() {
                      selectedCrop = v;
                      final d = CompanionService.getDefaults(v);
                      rowCm = d?.rowSpacingCm ?? 50;
                      plantCm = d?.plantSpacingCm ?? 40;
                    });
                  },
                ),
                const SizedBox(height: 16),

                // Tarla bölgesi
                Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                  const Text('Tarladaki Bölge',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(
                      '%${(zoneStart * 100).round()} – %${(zoneEnd * 100).round()}',
                      style: TextStyle(
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.bold)),
                ]),
                RangeSlider(
                  values: RangeValues(zoneStart, zoneEnd),
                  min: 0,
                  max: 1,
                  divisions: 20,
                  activeColor: Colors.green.shade700,
                  onChanged: (v) => setSheet(() {
                    zoneStart = v.start;
                    zoneEnd = v.end;
                    if (zoneEnd - zoneStart < 0.05) {
                      zoneEnd = (zoneStart + 0.05).clamp(0, 1);
                    }
                  }),
                ),

                // Boyut bilgisi
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.teal.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                      '📐 $zoneW m genişlik  •  $zoneA m² alan  •  ~$preview bitki',
                      style: TextStyle(
                          color: Colors.teal.shade800,
                          fontWeight: FontWeight.bold,
                          fontSize: 13)),
                ),

                const SizedBox(height: 14),

                // Aralık ayarları
                Row(children: [
                  Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text(
                          'Sıra Arası: ${rowCm!.round()} cm',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13)),
                      Slider(
                        value: rowCm!,
                        min: 10,
                        max: 200,
                        divisions: 38,
                        activeColor: Colors.brown,
                        label: '${rowCm!.round()} cm',
                        onChanged: (v) =>
                            setSheet(() => rowCm = v),
                      ),
                    ]),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text(
                          'Bitki Arası: ${plantCm!.round()} cm',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13)),
                      Slider(
                        value: plantCm!,
                        min: 5,
                        max: 150,
                        divisions: 29,
                        activeColor: Colors.green,
                        label: '${plantCm!.round()} cm',
                        onChanged: (v) =>
                            setSheet(() => plantCm = v),
                      ),
                    ]),
                  ),
                ]),

                // Uyumluluk ön uyarısı
                if (_crops.isNotEmpty) ...[
                  ..._crops.map((existing) {
                    final existName = existing['name'] as String;
                    final tempCrops = [
                      ...(_crops.map((c) => Map<String, dynamic>.from(c))),
                      {
                        'name': selectedCrop,
                        'zone_start': zoneStart,
                        'zone_end': zoneEnd,
                        'row_spacing_cm': rowCm,
                        'plant_spacing_cm': plantCm,
                      }
                    ];
                    final newWarnings =
                        CompanionService.generateWarnings(
                      crops: tempCrops,
                      fieldWidthM: _fieldWidthM,
                      fieldHeightM: _fieldHeightM,
                    )
                            .where((w) =>
                                w.level == WarnLevel.error &&
                                (w.title.contains(selectedCrop) ||
                                    w.title.contains(existName)))
                            .toList();
                    return Column(
                        children: newWarnings
                            .map((w) => Container(
                                  margin: const EdgeInsets.only(
                                      bottom: 6),
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade50,
                                    borderRadius:
                                        BorderRadius.circular(10),
                                    border: Border.all(
                                        color: Colors.red.shade200),
                                  ),
                                  child: Text(
                                      '🚫 ${w.title}\n${w.message}',
                                      style: TextStyle(
                                          color: Colors.red.shade700,
                                          fontSize: 12)),
                                ))
                            .toList());
                  }),
                ],

                const SizedBox(height: 16),

                // Ekle butonu
                FilledButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _addCrop(
                      name: selectedCrop,
                      zoneStart: zoneStart,
                      zoneEnd: zoneEnd,
                      rowCm: rowCm!,
                      plantCm: plantCm!,
                      color: CompanionService.getDefaults(selectedCrop)
                              ?.color ??
                          Colors.green,
                    );
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Tarlaya Ekle'),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.green.shade700,
                    minimumSize: const Size.fromHeight(50),
                  ),
                ),
                const SizedBox(height: 20),
              ]),
            ),
          );
        },
      ),
    );
  }

  void _addCrop({
    required String name,
    required double zoneStart,
    required double zoneEnd,
    required double rowCm,
    required double plantCm,
    required Color color,
  }) {
    setState(() {
      _crops.add({
        'name': name,
        'zone_start': zoneStart,
        'zone_end': zoneEnd,
        'row_spacing_cm': rowCm,
        'plant_spacing_cm': plantCm,
        'color_value': color.toARGB32(),
        'planted_date':
            '${DateTime.now().day.toString().padLeft(2, '0')}.${DateTime.now().month.toString().padLeft(2, '0')}.${DateTime.now().year}',
      });
      _dirty = true;
    });
    _saveToRepository();
  }
}
