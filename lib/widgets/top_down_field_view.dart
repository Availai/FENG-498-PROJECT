import 'package:flutter/material.dart';
import '../models/crop_layer.dart';
import 'top_down_field_painter.dart';

class TopDownFieldView extends StatefulWidget {
  final String fieldName;
  final double areaDekar;
  final Map<String, dynamic>? plantingData;
  final String cropName;
  final List<CropLayer> extraCrops;

  const TopDownFieldView({
    required this.fieldName,
    required this.areaDekar,
    required this.plantingData,
    required this.cropName,
    this.extraCrops = const [],
    super.key,
  });

  @override
  State<TopDownFieldView> createState() => _TopDownFieldViewState();
}

class _TopDownFieldViewState extends State<TopDownFieldView>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _anim;
  bool _showPlanting = true;
  bool _showIrrigation = true;
  bool _showFertilizer = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4000),
    );
    _anim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pd = widget.plantingData ?? {};
    final rowSpacing = (pd['row_spacing_cm'] as num?)?.toDouble() ?? 50;
    final plantSpacing = (pd['plant_spacing_cm'] as num?)?.toDouble() ?? 40;
    final seedsPerDekar = (pd['seeds_per_dekar'] as num?)?.toInt() ?? 500;
    final irrType = pd['irrigation_type']?.toString() ?? 'Damla Sulama';
    final irrLineSpacing = (pd['irrigation_line_spacing_cm'] as num?)?.toDouble() ?? 70;
    final irrDripperSpacing = (pd['irrigation_dripper_spacing_cm'] as num?)?.toDouble() ?? 30;
    final fertBand = (pd['fertilizer_band_cm'] as num?)?.toDouble() ?? 15;
    final fertType = pd['fertilizer_type']?.toString() ?? 'NPK 15-15-15';

    final areaM2 = widget.areaDekar * 1000.0;
    double hGuess = areaM2 / 2;
    for (int i = 0; i < 20; i++) {
      hGuess = (hGuess + (areaM2 / 1.5) / hGuess) / 2;
    }
    final fieldHeightM = hGuess.clamp(5.0, 500.0);
    final fieldWidthM = (areaM2 / fieldHeightM).clamp(5.0, 500.0);

    final totalPlants = (seedsPerDekar * widget.areaDekar).round();
    final totalRows = (fieldHeightM * 100 / rowSpacing).round();
    final irrLengthM = (totalRows * fieldWidthM).round();

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.landscape, color: Colors.green.shade700, size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(widget.fieldName,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('${widget.areaDekar.toStringAsFixed(1)} Dekar',
                      style: TextStyle(fontSize: 12, color: Colors.green.shade800, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 6),
                IconButton(
                  icon: const Icon(Icons.replay, size: 20),
                  onPressed: () {
                    _controller.reset();
                    _controller.forward();
                  },
                  tooltip: 'Tekrar Oynat',
                  color: Colors.green.shade700,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _layerChip('Ekim', Colors.green, _showPlanting, (v) => setState(() => _showPlanting = v)),
                const SizedBox(width: 6),
                _layerChip('Sulama', Colors.blue, _showIrrigation, (v) => setState(() => _showIrrigation = v)),
                const SizedBox(width: 6),
                _layerChip('Gübre', Colors.orange, _showFertilizer, (v) => setState(() => _showFertilizer = v)),
              ],
            ),
            const SizedBox(height: 10),
            AnimatedBuilder(
              animation: _anim,
              builder: (context, _) {
                return AspectRatio(
                  aspectRatio: 1.5,
                  child: CustomPaint(
                    painter: TopDownFieldPainter(
                      phase: _anim.value,
                      rowSpacingCm: rowSpacing,
                      plantSpacingCm: plantSpacing,
                      irrigationLineSpacingCm: irrLineSpacing,
                      irrigationDripperSpacingCm: irrDripperSpacing,
                      fertilizerBandCm: fertBand,
                      fieldWidthM: fieldWidthM,
                      fieldHeightM: fieldHeightM,
                      showPlanting: _showPlanting,
                      showIrrigation: _showIrrigation,
                      showFertilizer: _showFertilizer,
                      crops: widget.extraCrops,
                    ),
                    size: Size.infinite,
                  ),
                );
              },
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _legendItem(Colors.green.shade600, 'Bitki', Icons.circle),
                  _legendItem(Colors.blue.shade500, 'Sulama', Icons.horizontal_rule),
                  _legendItem(Colors.orange.shade400, 'Gübre', Icons.square_rounded),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.blue.shade100),
              ),
              child: Row(
                children: [
                  Icon(Icons.water_drop, color: Colors.blue.shade600, size: 18),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text('$irrType  •  Hat arası: ${irrLineSpacing.round()}cm  •  Damlatıcı arası: ${irrDripperSpacing.round()}cm',
                        style: TextStyle(fontSize: 12, color: Colors.blue.shade800)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.orange.shade100),
              ),
              child: Row(
                children: [
                  Icon(Icons.science, color: Colors.orange.shade700, size: 18),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text('$fertType  •  Bant genişliği: ${(fertBand * 2).round()}cm  •  Bitkiden ${fertBand.round()}cm mesafe',
                        style: TextStyle(fontSize: 12, color: Colors.orange.shade800)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _miniStat('Toplam Bitki', '$totalPlants', Colors.green.shade700),
                _miniStat('Sıra Sayısı', '~$totalRows', Colors.brown.shade600),
                _miniStat('Sulama Hattı', '~${irrLengthM}m', Colors.blue.shade700),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _layerChip(String label, Color color, bool selected, ValueChanged<bool> onChanged) {
    return FilterChip(
      label: Text(label, style: TextStyle(fontSize: 12, color: selected ? Colors.white : color)),
      selected: selected,
      onSelected: onChanged,
      selectedColor: color,
      checkmarkColor: Colors.white,
      backgroundColor: color.withValues(alpha: 0.1),
      side: BorderSide(color: color.withValues(alpha: 0.3)),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      visualDensity: VisualDensity.compact,
    );
  }

  Widget _legendItem(Color color, String label, IconData icon) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 14),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade700)),
      ],
    );
  }

  Widget _miniStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: color)),
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
      ],
    );
  }
}
