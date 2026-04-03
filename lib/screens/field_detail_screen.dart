import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/agri_service.dart';
import '../services/app_providers.dart';
import '../data/verified_agri_database.dart';
import '../widgets/glass_panel.dart';
import '../widgets/tech_3d_field_renderer.dart';
import 'seed_selector_screen.dart';
import 'harvest_oracle_screen.dart';

class FieldDetailScreen extends ConsumerStatefulWidget {
  final dynamic fieldData;
  const FieldDetailScreen({super.key, required this.fieldData});
  @override
  ConsumerState<FieldDetailScreen> createState() => _FieldDetailScreenState();
}

class _FieldDetailScreenState extends ConsumerState<FieldDetailScreen>
    with SingleTickerProviderStateMixin {
  Map<String, dynamic>? _analysis;
  bool _isLoading = true;
  String? _error;

  late AnimationController _animCtrl;
  late Animation<double> _uiFadeAnim;
  late Animation<Offset> _uiSlideAnim;

  final FieldViewMode _currentMode = FieldViewMode.physical;

  double _yaw = 0.78; 
  double _pitch = 0.95; 
  double _scale = 1.8; 
  
  double _globalGrowth = 1.0; // 0.0 to 1.0

  int? _selectedRow;
  int? _selectedCol;

  // Stores what crop is planted in each block
  final Map<String, Tech3DRenderData> _farmGrid = {};

  final int _rows = 12;
  final int _cols = 12;

  final List<AgriPlant> _seeds = VerifiedAgriDatabase.plants;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2500));

    _uiFadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(
        parent: _animCtrl,
        curve: const Interval(0.2, 1.0, curve: Curves.easeOut)));
    _uiSlideAnim = Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero)
        .animate(CurvedAnimation(
            parent: _animCtrl,
            curve: const Interval(0.2, 1.0, curve: Curves.easeOutBack)));

    _animCtrl.forward();

    // Init matrix data with area approximation
    double area = (widget.fieldData['area_dekar'] as num?)?.toDouble() ?? 1.0;
    // You could dynamically calculate rows/cols based on true area here, but for tech demo keep static or clamped.

    _loadAnalysis();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadAnalysis() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final d = widget.fieldData;
      final result = await AgriService.getFieldAnalysis(
        (d['latitude'] as num).toDouble(),
        (d['longitude'] as num).toDouble(),
        d['name'] ?? 'Tarla',
        (d['area_dekar'] as num?)?.toDouble() ?? 1.0,
      );
      if (mounted) {
        setState(() {
          if (result['success'] == true) {
            _analysis = result;
          } else {
            _error = result['error'] ?? 'Bilinmeyen hata';
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Bağlantı Hatası: $e';
          _isLoading = false;
        });
      }
    }
  }


  Future<void> _showSyncQueueDialog() async {
    final syncRepository = ref.read(syncRepositoryProvider);
    final stats = await syncRepository.getQueueStats();
    if (!mounted) return;

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Senkron Kuyruğu'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Bekleyen: ${stats['pending'] ?? 0}'),
            Text('İşleniyor: ${stats['in_progress'] ?? 0}'),
            Text('Hatalı: ${stats['failed'] ?? 0}'),
            const SizedBox(height: 8),
            Text('Toplam: ${stats['total'] ?? 0}'),
            const SizedBox(height: 8),
            const Text(
              'Not: Bu adım yalnızca yerel outbox kuyruğunu yönetir.',
              style: TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Kapat'),
          ),
          FilledButton(
            onPressed: () async {
              final moved = await syncRepository.retryFailedJobs();
              final report = await ref.read(syncServiceProvider).runPushCycleWithApi(
                    apiClient: ref.read(syncApiClientProvider),
                  );
              if (!mounted) return;
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    '$moved kayıt tekrar kuyruğa alındı • '
                    'Push: ${report.completed}/${report.picked} başarılı',
                  ),
                ),
              );
            },
            child: const Text('Hatalıları Tekrar Dene'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.fieldData;
    final a = _analysis;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: const Color(0xFF0D1811), // Deep premium dark green
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: AnimatedOpacity(
          opacity: _uiFadeAnim.value,
          duration: const Duration(milliseconds: 300),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.architecture_rounded, color: Color(0xFF00E676)),
              const SizedBox(width: 8),
              Text(d['name']?.toUpperCase() ?? 'AGRI-FARM AR',
                  style: GoogleFonts.outfit(
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2.0,
                      color: Colors.white,
                      fontSize: 18)),
              const SizedBox(width: 12),
              const Text('3D TECH VIEW',
                  style: TextStyle(
                      color: Colors.white54, fontSize: 12, letterSpacing: 1.0)),
            ],
          ),
        ),
        actions: [
          IconButton(
              icon: const Icon(Icons.sync, color: Color(0xFF00E676)),
              onPressed: _showSyncQueueDialog),
        ],
      ),
      body: Stack(
        children: [
          // 1. 3D Render Engine Fullscreen Layer
          Positioned.fill(
            child: GestureDetector(
              onPanUpdate: (details) {
                setState(() {
                  _yaw -= details.delta.dx * 0.01;
                  _pitch -= details.delta.dy * 0.01;
                  _pitch = _pitch.clamp(0.1, 1.5);
                });
              },
              onScaleUpdate: (details) {
                // Ignore small scale triggers during pan to separate pinch vs drag if needed
                if (details.scale != 1.0) {
                  setState(() {
                    _scale = (_scale * details.scale).clamp(0.5, 4.0);
                  });
                }
              },
              onTapUp: (details) {
               // Perform hit testing roughly if needed via projection inversion
               // For a seamless true 3D interactive grid, we rely on inverse matrix math.
               double bestDist = double.infinity;
               int? bR, bC;
               double blockSize = 20.0;
               double gridW = _cols * blockSize;
               double gridH = _rows * blockSize;
               double cx = MediaQuery.of(context).size.width / 2;
               double cy = MediaQuery.of(context).size.height / 2;

               for (int r = 0; r < _rows; r++) {
                 for (int c = 0; c < _cols; c++) {
                   double tx = c * blockSize + blockSize/2 - gridW/2;
                   double ty = r * blockSize + blockSize/2 - gridH/2;
                   double r1x = tx * math.cos(_yaw) - ty * math.sin(_yaw);
                   double r1y = tx * math.sin(_yaw) + ty * math.cos(_yaw);
                   double r2x = r1x;
                   double r2y = r1y * math.cos(_pitch); // ignore z=0 for base
                   
                   double screenX = cx + r2x * _scale;
                   double screenY = cy + r2y * _scale;

                   double dist = math.sqrt(math.pow(details.localPosition.dx - screenX, 2) + math.pow(details.localPosition.dy - screenY, 2));
                   if (dist < 40 * _scale && dist < bestDist) {
                     bestDist = dist; bR = r; bC = c;
                   }
                 }
               }
               if (bR != null && bC != null) {
                 setState(() { _selectedRow = bR; _selectedCol = bC; });
               }
              },
              child: CustomPaint(
                size: Size.infinite,
                painter: Tech3DRenderer(
                  farmGrid: _farmGrid,
                  rows: _rows,
                  cols: _cols,
                  blockSize: 20.0,
                  cameraYaw: _yaw,
                  cameraPitch: _pitch,
                  cameraScale: _scale,
                  viewMode: _currentMode,
                  selectedRow: _selectedRow,
                  selectedCol: _selectedCol,
                  globalGrowth: _globalGrowth,
                ),
              ),
            ),
          ),

          // 2. Growth Slider Overlay
          Positioned(
            left: 20,
            bottom: 120, // above bottom nav
            child: FadeTransition(
              opacity: _uiFadeAnim,
              child: RotatedBox(
                quarterTurns: 3,
                child: GlassPanel(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.spa_rounded, color: Colors.greenAccent, size: 18),
                      // Slider needs fixed width inside RotatedBox horizontally
                      SizedBox(
                        width: 200,
                        child: SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            activeTrackColor: Colors.greenAccent,
                            inactiveTrackColor: Colors.white24,
                            thumbColor: Colors.white,
                          ),
                          child: Slider(
                            value: _globalGrowth,
                            min: 0.1,
                            max: 1.0,
                            onChanged: (v) => setState(() => _globalGrowth = v),
                          ),
                        ),
                      ),
                      const Icon(Icons.forest_rounded, color: Colors.green, size: 18),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // 3. Seed Lab (when cell placed)
          if (_selectedRow != null && _selectedCol != null)
            Positioned(
              left: 64, // clear the slider
              right: 20,
              bottom: 100,
              child: FadeTransition(
                opacity: _uiFadeAnim,
                child: _buildSeedLab(),
              ),
            ),

          // 4. Center Top/Sides stats
          if (!_isLoading && _error == null)
            Positioned(
              right: 16,
              top: MediaQuery.of(context).padding.top + 60,
              child: FadeTransition(
                opacity: _uiFadeAnim,
                child: SlideTransition(
                  position: _uiSlideAnim,
                  child: _buildHUDRightSidebar(a),
                ),
              ),
            ),

          // 5. Bottom System Nav
          if (!_isLoading && _error == null)
            Positioned(
              left: 16,
              right: 16,
              bottom: MediaQuery.of(context).padding.bottom + 20,
              child: FadeTransition(
                opacity: _uiFadeAnim,
                child: SlideTransition(
                  position: _uiSlideAnim,
                  child: _buildHUDBottomBar(),
                ),
              ),
            ),

          if (_isLoading)
            const Center(child: CircularProgressIndicator(color: Color(0xFF00E676))),
          if (_error != null)
            Center(
                child: GlassPanel(
                    child: Text(_error!, style: const TextStyle(color: Colors.white)))),
        ],
      ),
    );
  }

  Widget _buildHUDRightSidebar(Map<String, dynamic>? a) {
    String temp = '--°C';
    String humid = '--';

    if (a != null) {
      final cw = a['current_weather'];
      if (cw != null) {
        temp = '${cw['temp']?.round() ?? '--'}°C';
        humid = '%${cw['humidity']?.round() ?? '--'}';
      }
    }

    final fieldName = widget.fieldData['name'] ?? 'Tarla';

    return GlassPanel(
      baseColor: const Color(0xFF1B5E20),
      borderRadius: 16,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.lens_blur_rounded, color: Color(0xFF00E676), size: 14),
            const SizedBox(width: 6),
            Text(fieldName,
                style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
          ]),
          const SizedBox(height: 12),
          _buildStatItem(Icons.thermostat_outlined, 'Env. Temp', temp, const Color(0xFFFFCC80)),
          _buildStatItem(Icons.opacity_outlined, 'Humidity', humid, const Color(0xFFA5D6A7)),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String label, String value, Color iconColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10, fontFamily: 'monospace')),
              Text(value, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHUDBottomBar() {
    return GlassPanel(
      baseColor: Colors.white,
      borderRadius: 20,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildNavBtn(Icons.eco_rounded, 'Nöbetleşe Ekim', _showCropRecommendations, primary: true),
          _buildNavBtn(Icons.grain_rounded, 'Tohum DB', () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const SeedSelectorScreen()))),
          _buildNavBtn(Icons.wb_cloudy_rounded, 'Hasat Modülü', () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const HarvestOracleScreen()))),
        ],
      ),
    );
  }

  Widget _buildNavBtn(IconData icon, String text, VoidCallback onTap, {bool primary = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: primary ? BoxDecoration(
          color: const Color(0xFF1B5E20),
          borderRadius: BorderRadius.circular(16),
        ) : null,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: primary ? Colors.white : const Color(0xFF2E7D32), size: 22),
            const SizedBox(height: 4),
            Text(text, style: GoogleFonts.inter(
              color: primary ? Colors.white : const Color(0xFF2E7D32),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            )),
          ],
        ),
      ),
    );
  }

  void _showCropRecommendations() {
    double currentT = 20.0;
    double currentPh = 6.5;
    double totalRain = 400.0;

    if (_analysis != null) {
      if (_analysis!['current_weather'] != null) currentT = (_analysis!['current_weather']['temp'] as num?)?.toDouble() ?? 20.0;
      if (_analysis!['soil'] != null) currentPh = (_analysis!['soil']['ph'] as num?)?.toDouble() ?? 6.5;
    }

    // Use Verified Database perfectly 
    List<Map<String, dynamic>> scoredPlants = [];
    for (var plant in VerifiedAgriDatabase.plants) {
       int score = plant.evaluateSuitability(currentPh, currentT, totalRain);
       scoredPlants.add({
         'plant': plant,
         'score': score
       });
    }

    scoredPlants.sort((a,b) => (b['score'] as int).compareTo(a['score'] as int));

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _VerifiedRecommendationSheet(recommendations: scoredPlants),
    );
  }

  Widget _buildSeedLab() {
    return GlassPanel(
      baseColor: const Color(0xFF00E676),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("🧬 SEED_INJECT [$_selectedRow,$_selectedCol]",
                  style: const TextStyle(
                      color: Color(0xFF00E676),
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace',
                      letterSpacing: 1.5,
                      fontSize: 11)),
              InkWell(
                  onTap: () => setState(() => _farmGrid.remove('$_selectedRow+$_selectedCol')),
                  child: const Icon(Icons.delete_sweep, color: Colors.redAccent, size: 20))
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 44,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _seeds.length,
              itemBuilder: (context, index) {
                final s = _seeds[index];
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: s.renderColor.withValues(alpha: 0.2),
                      foregroundColor: Colors.white,
                      side: BorderSide(color: s.renderColor),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      setState(() {
                         _farmGrid['$_selectedRow+$_selectedCol'] = Tech3DRenderData(
                             _selectedRow!, _selectedCol!,
                             _selectedCol! * 20.0 + 10.0, _selectedRow! * 20.0 + 10.0,
                             s.id, 1.0 // Initialize with growth driven by global
                         );
                      });
                    },
                    child: Text(s.nameTr.toUpperCase(),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                  ),
                );
              },
            ),
          )
        ],
      ),
    );
  }
}

class _VerifiedRecommendationSheet extends StatelessWidget {
  final List<Map<String, dynamic>> recommendations;
  const _VerifiedRecommendationSheet({required this.recommendations});


  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      child: Column(
        children: [
          Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.verified_user_rounded, color: Color(0xFF2E7D32), size: 20),
            ),
            const SizedBox(width: 12),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Doğrulanmış Algoritma Önerileri', style: GoogleFonts.outfit(fontSize: 17, fontWeight: FontWeight.w700, color: const Color(0xFF1B5E20))),
              Text('%100 Çevresel Uyum Garantisi', style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade500)),
            ]),
          ]),
          const SizedBox(height: 16),
          const Divider(),
          Expanded(
            child: ListView.builder(
              itemCount: recommendations.length,
              itemBuilder: (context, i) {
                AgriPlant p = recommendations[i]['plant'];
                int score = recommendations[i]['score'];
                Color sColor = score >= 80 ? Colors.green : score >= 50 ? Colors.orange : Colors.red;
                return ListTile(
                  leading: CircleAvatar(backgroundColor: p.renderColor, child: const Icon(Icons.eco, color: Colors.white, size: 16)),
                  title: Text(p.nameTr, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('Süre: ${p.daysToHarvest} gün | Cinsi: ${p.category}'),
                  trailing: Text('%$score', style: TextStyle(color: sColor, fontWeight: FontWeight.bold, fontSize: 16)),
                );
              },
            ),
          )
        ],
      ),
    );
  }
}
