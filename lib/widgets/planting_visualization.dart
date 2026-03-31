import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'root_painter.dart';
import 'planting_stat_card.dart';
import 'top_down_field_view.dart';

class PlantingVisualization extends StatefulWidget {
  final String cropName;
  final Map<String, dynamic>? plantingData;
  const PlantingVisualization({
    required this.cropName,
    this.plantingData,
    super.key,
  });

  @override
  State<PlantingVisualization> createState() => _PlantingVisualizationState();
}

class _PlantingVisualizationState extends State<PlantingVisualization>
    with TickerProviderStateMixin {
  late AnimationController _phaseController;
  late AnimationController _growController;
  late Animation<double> _seedDrop;
  late Animation<double> _rootGrow;
  late Animation<double> _sproutGrow;
  late Animation<double> _leafGrow;
  final List<Map<String, dynamic>> _fields = [];

  @override
  void initState() {
    super.initState();
    _loadFields();

    _phaseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3500),
    );

    _growController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _seedDrop = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _phaseController, curve: const Interval(0.0, 0.25, curve: Curves.bounceOut)),
    );
    _rootGrow = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _phaseController, curve: const Interval(0.25, 0.50, curve: Curves.easeOut)),
    );
    _sproutGrow = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _phaseController, curve: const Interval(0.50, 0.75, curve: Curves.easeOutCubic)),
    );
    _leafGrow = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _phaseController, curve: const Interval(0.75, 1.0, curve: Curves.easeOutCubic)),
    );

    _phaseController.forward();
  }

  void _loadFields() {
    try {
      final box = Hive.box('user_crops');
      for (int i = 0; i < box.length; i++) {
        final f = box.getAt(i);
        if (f != null) {
          _fields.add(Map<String, dynamic>.from(f));
        }
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _phaseController.dispose();
    _growController.dispose();
    super.dispose();
  }

  String get _cropEmoji {
    final name = widget.cropName.toLowerCase();
    if (name.contains('domates')) return '🍅';
    if (name.contains('mısır')) return '🌽';
    if (name.contains('salatalık')) return '🥒';
    if (name.contains('patlıcan')) return '🍆';
    if (name.contains('buğday') || name.contains('bugday')) return '🌾';
    if (name.contains('biber')) return '🫑';
    if (name.contains('patates')) return '🥔';
    if (name.contains('soğan') || name.contains('sogan')) return '🧅';
    if (name.contains('çilek') || name.contains('cilek')) return '🍓';
    if (name.contains('kavun')) return '🍈';
    if (name.contains('karpuz')) return '🍉';
    if (name.contains('üzüm') || name.contains('uzum')) return '🍇';
    return '🌱';
  }

  @override
  Widget build(BuildContext context) {
    final depth = (widget.plantingData?['depth_cm'] ?? 3) as num;
    final rowSpacing = (widget.plantingData?['row_spacing_cm'] ?? 50) as num;
    final plantSpacing = (widget.plantingData?['plant_spacing_cm'] ?? 40) as num;
    final irrType = widget.plantingData?['irrigation_type']?.toString() ?? 'Damla Sulama';
    final irrDripperSpacing = (widget.plantingData?['irrigation_dripper_spacing_cm'] ?? 30) as num;
    final fertType = widget.plantingData?['fertilizer_type']?.toString() ?? 'NPK 15-15-15';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('🌱 Ekim Görselleştirme',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),

        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.lightBlue.shade50, Colors.brown.shade100],
              stops: const [0.5, 0.5],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.green.shade200),
          ),
          child: AnimatedBuilder(
            animation: _phaseController,
            builder: (context, _) {
              return Column(
                children: [
                  SizedBox(
                    height: 120,
                    child: Stack(
                      alignment: Alignment.bottomCenter,
                      children: [
                        Positioned(
                          top: 5,
                          right: 15,
                          child: Opacity(
                            opacity: _sproutGrow.value,
                            child: const Text('☀️', style: TextStyle(fontSize: 28)),
                          ),
                        ),
                        Positioned(
                          bottom: 0 + (_seedDrop.value * 0),
                          child: Transform.translate(
                            offset: Offset(0, -60 + (_seedDrop.value * 60)),
                            child: Opacity(
                              opacity: _seedDrop.value > 0 ? 1 : 0,
                              child: Text(
                                _seedDrop.value < 0.95 ? '🫘' : '',
                                style: const TextStyle(fontSize: 22),
                              ),
                            ),
                          ),
                        ),
                        if (_sproutGrow.value > 0)
                          Positioned(
                            bottom: 0,
                            child: SizedBox(
                              height: 70 * _sproutGrow.value,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Text(
                                    _leafGrow.value > 0.5 ? _cropEmoji : '🌱',
                                    style: TextStyle(
                                      fontSize: 20 + (16 * _leafGrow.value),
                                    ),
                                  ),
                                  Container(
                                    width: 3,
                                    height: 30 * _sproutGrow.value,
                                    decoration: BoxDecoration(
                                      color: Colors.green.shade700,
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Container(
                    height: 3,
                    width: double.infinity,
                    color: Colors.brown.shade400,
                  ),
                  SizedBox(
                    height: 50,
                    child: Stack(
                      alignment: Alignment.topCenter,
                      children: [
                        if (_rootGrow.value > 0)
                          CustomPaint(
                            size: const Size(100, 50),
                            painter: RootPainter(_rootGrow.value),
                          ),
                        Positioned(
                          right: 10,
                          top: 5,
                          child: Opacity(
                            opacity: _rootGrow.value,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.brown.shade300,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '↕ ${depth}cm derinlik',
                                style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 8),

        AnimatedBuilder(
          animation: _phaseController,
          builder: (context, _) {
            String phase = 'Tohum hazırlanıyor...';
            IconData icon = Icons.grain;
            Color color = Colors.brown;
            if (_leafGrow.value > 0.3) {
              phase = '4/4 — Yapraklanma & meyve';
              icon = Icons.eco;
              color = Colors.green.shade800;
            } else if (_sproutGrow.value > 0.1) {
              phase = '3/4 — Filizlenme';
              icon = Icons.spa;
              color = Colors.green;
            } else if (_rootGrow.value > 0.1) {
              phase = '2/4 — Kök salma (${depth}cm)';
              icon = Icons.arrow_downward;
              color = Colors.brown.shade600;
            } else if (_seedDrop.value > 0.1) {
              phase = '1/4 — Tohum ekimi';
              icon = Icons.grain;
              color = Colors.orange.shade700;
            }
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(icon, color: color, size: 20),
                  const SizedBox(width: 8),
                  Text(phase, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14)),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.replay, size: 20),
                    onPressed: () {
                      _phaseController.reset();
                      _phaseController.forward();
                    },
                    tooltip: 'Tekrar Oynat',
                    color: color,
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 12),

        Row(
          children: [
            PlantingStatCard(icon: Icons.arrow_downward, label: 'Derinlik', value: '${depth}cm', color: Colors.brown),
            const SizedBox(width: 8),
            PlantingStatCard(icon: Icons.swap_horiz, label: 'Sıra Arası', value: '${rowSpacing}cm', color: Colors.blue),
            const SizedBox(width: 8),
            PlantingStatCard(icon: Icons.space_bar, label: 'Bitki Arası', value: '${plantSpacing}cm', color: Colors.teal),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            PlantingStatCard(icon: Icons.water_drop, label: 'Sulama', value: irrType, color: Colors.blue),
            const SizedBox(width: 8),
            PlantingStatCard(icon: Icons.opacity, label: 'Damlatıcı Arası', value: '${irrDripperSpacing}cm', color: Colors.cyan),
            const SizedBox(width: 8),
            PlantingStatCard(icon: Icons.science, label: 'Gübre', value: fertType, color: Colors.orange),
          ],
        ),
        const SizedBox(height: 12),

        if (_fields.isNotEmpty) ...[
          const Text('🗺️ Kuşbakışı Tarla Görünümü',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ..._fields.map((f) {
            final dekar = (f['area_dekar'] as num?)?.toDouble() ?? 1.0;
            return TopDownFieldView(
              fieldName: f['name'] ?? 'Tarla',
              areaDekar: dekar,
              plantingData: widget.plantingData,
              cropName: widget.cropName,
            );
          }),
        ],
      ],
    );
  }
}
