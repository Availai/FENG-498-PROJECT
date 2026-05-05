import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/turkish_crops_repository.dart';
import '../data/supported_crops.dart';
import '../services/app_providers.dart';
import '../services/offline_rule_engine.dart';
import '../services/offline_encyclopedia.dart';
import '../services/weather_soil_service.dart';
import '../widgets/floating_toast.dart';

/// Seçilen ürünün kayıtlı tarlalara uygunluğunu animasyonlu gösterir.
class CropFieldMatchScreen extends ConsumerStatefulWidget {
  const CropFieldMatchScreen({super.key});

  @override
  ConsumerState<CropFieldMatchScreen> createState() =>
      _CropFieldMatchScreenState();
}

class _CropFieldMatchScreenState extends ConsumerState<CropFieldMatchScreen>
    with TickerProviderStateMixin {
  final _cropController = TextEditingController();
  bool _isLoading = false;
  List<FieldMatch> _results = [];

  // Her kart için staggered animasyon
  late AnimationController _staggerController;

  List<String> _quickCrops = SupportedCrops.visibleNames;

  @override
  void initState() {
    super.initState();
    _staggerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _loadQuickCropsFromDb();
  }

  Future<void> _loadQuickCropsFromDb() async {
    await TurkishCropsRepository.instance.ensureReady();
    final popular = TurkishCropsRepository.instance.popular(limit: 10);
    if (!mounted || popular.isEmpty) return;
    setState(() {
      _quickCrops = popular
          .where((c) => SupportedCrops.isSupported(c.nameTr))
          .map((c) => SupportedCrops.canonicalName(c.nameTr) ?? c.nameTr)
          .toSet()
          .toList();
      if (_quickCrops.isEmpty) _quickCrops = SupportedCrops.visibleNames;
    });
  }

  @override
  void dispose() {
    _cropController.dispose();
    _staggerController.dispose();
    super.dispose();
  }

  Future<void> _analyze(String cropName) async {
    if (cropName.trim().isEmpty) return;
    final canonical = SupportedCrops.canonicalName(cropName);
    if (canonical == null) {
      AppToast.show(
        context,
        message:
            'Desteklenen ürünler: Ayçiçeği, Mısır, Domates, Portakal, Çay.',
        type: ToastType.warning,
      );
      return;
    }

    final all = await ref.read(localDataRepositoryProvider).loadFieldMaps();
    final fields = all.where((f) => f['latitude'] != null).toList();

    if (fields.isEmpty) {
      if (mounted) {
        AppToast.show(
          context,
          message: 'Konum bilgisi olan kayıtlı tarla bulunamadı.',
          type: ToastType.warning,
        );
      }
      return;
    }

    setState(() {
      _isLoading = true;
      _results = [];
    });
    _staggerController.reset();

    try {
      // Her tarla için paralel çevre verisi çek
      final fieldEnvList = await Future.wait(
        fields.map((f) => _fetchEnvData(
              (f['latitude'] as num).toDouble(),
              (f['longitude'] as num).toDouble(),
            )),
      );

      // Tek bir Gemini çağrısıyla tüm tarlaları değerlendir
      final results = await _batchEvaluate(canonical, fields, fieldEnvList);

      if (mounted) {
        setState(() {
          _results = results;
          _isLoading = false;
        });
        _staggerController.forward();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        AppToast.show(
          context,
          message: 'Hata: $e',
          type: ToastType.error,
        );
      }
    }
  }

  /// Tarla çevre verilerini servis üzerinden çeker (hava + pH + 7-gün yağış).
  Future<Map<String, double>> _fetchEnvData(double lat, double lng) async {
    final env = await const WeatherSoilService().fetchFieldEnv(
      latitude: lat,
      longitude: lng,
    );
    return {
      'temp': env.temperatureC,
      'ph': env.phH2O,
      'rain': env.weeklyRainMm,
      'humidity': env.humidity,
    };
  }

  /// Kural motoru ile tüm tarlaları toplu değerlendir (Gemini kaldırıldı)
  Future<List<FieldMatch>> _batchEvaluate(
    String crop,
    List<Map<String, dynamic>> fields,
    List<Map<String, double>> envList,
  ) async {
    // Önce yeni küratörlü DB'de ara, yoksa eski OfflineEncyclopedia fallback.
    await TurkishCropsRepository.instance.ensureReady();
    final tcrop = TurkishCropsRepository.instance.findByName(crop);
    final plantDetails = OfflineEncyclopedia.getByName(crop) ?? {};
    final results = <FieldMatch>[];
    final month = DateTime.now().month;

    for (int i = 0; i < fields.length; i++) {
      final f = fields[i];
      final e = envList[i];
      final dekar = (f['area_dekar'] as num?)?.toDouble() ?? 1.0;
      final temp = e['temp'] ?? 20.0;
      final ph = e['ph'] ?? 6.5;
      final rain = e['rain'] ?? 15.0;
      final humidity = e['humidity'] ?? 50.0;

      // Yeni DB skorlaması (varsa)
      double score = 70.0;
      final reasons = <String>[];
      if (tcrop != null) {
        final s = tcrop.scoreFor(
          temperature: temp,
          soilPh: ph,
          weeklyRain: rain,
          month: month,
        );
        score = s.score;
        reasons.addAll(s.reasons);
      }

      // Çevrimdışı-öncelikli: lokal mirror; backend ile parite garanti edilir.
      final ruleResults = OfflineRuleEngine.analyze(
        commonName: crop,
        plantDetails: plantDetails,
        temperature: temp,
        avgWeeklyTemp: temp,
        humidity: humidity,
        weeklyRain: rain,
        soilPh: ph,
        month: month,
      );
      if (tcrop == null) {
        // TurkishCrop yoksa skor tamamen OfflineRuleEngine'den gelir.
        for (final r in ruleResults) {
          if (r.level == RiskLevel.critical) score -= 20;
          if (r.level == RiskLevel.warning) score -= 8;
          if (r.level == RiskLevel.ok) score += 5;
        }
        score = score.clamp(0.0, 100.0);
      }

      // Verim tahmini
      final harvestDays = tcrop?.daysToHarvest ??
          (plantDetails['harvest_days'] as num?)?.toInt() ??
          90;
      final rowSp = (plantDetails['row_spacing_cm'] as num?)?.toInt() ?? 60;
      final plantSp = (plantDetails['plant_spacing_cm'] as num?)?.toInt() ?? 40;
      final maxPlants = ((10000 * dekar) / (rowSp * plantSp)).round();
      final yieldPerDekar = 2000.0 + (score - 50) * 30;
      final totalYield = yieldPerDekar * dekar;

      final criticals =
          ruleResults.where((r) => r.level == RiskLevel.critical).toList();
      final reason = reasons.isNotEmpty
          ? reasons.join(' • ')
          : (criticals.isNotEmpty
              ? criticals.first.message
              : 'pH ${ph.toStringAsFixed(1)}, ${temp.toStringAsFixed(1)}°C — koşullar değerlendirildi.');
      final suggestion = tcrop?.growingTips ??
          'Hasat ~$harvestDays gün. Damla sulama ile verim artırılabilir.';

      results.add(FieldMatch(
        fieldName: f['name'] ?? 'Tarla',
        areaDekar: dekar,
        uygunluk: score,
        maxPlants: maxPlants,
        yieldPerDekar: yieldPerDekar,
        totalYield: totalYield,
        reason: reason,
        suggestion: suggestion,
      ));
    }

    results.sort((a, b) => b.uygunluk.compareTo(a.uygunluk));
    return results;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text('Ürün–Tarla Eşleştirme'),
      ),
      body: Column(
        children: [
          // Ürün seçimi
          Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _cropController,
                  decoration: InputDecoration(
                    hintText: 'Yetiştirmek istediğiniz ürün...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.send, color: Colors.green),
                      onPressed: () => _analyze(_cropController.text),
                    ),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  onSubmitted: _analyze,
                ),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _quickCrops
                        .map((c) => Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: ActionChip(
                                label: Text(c,
                                    style: const TextStyle(fontSize: 13)),
                                onPressed: () {
                                  _cropController.text = c;
                                  _analyze(c);
                                },
                              ),
                            ))
                        .toList(),
                  ),
                ),
              ],
            ),
          ),

          // Sonuçlar
          Expanded(
            child: _isLoading
                ? const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(color: Colors.green),
                        SizedBox(height: 16),
                        Text('Tarlalar analiz ediliyor...'),
                      ],
                    ),
                  )
                : _results.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.eco,
                                  size: 64, color: Colors.green.shade200),
                              const SizedBox(height: 12),
                              const Text(
                                'Bir ürün seçerek kayıtlı tarlalarınıza\nuygunluk analizi başlatın.',
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: _results.length,
                        itemBuilder: (context, i) {
                          // Staggered giriş animasyonu
                          final start = i / _results.length;
                          final end = min(start + 0.4, 1.0);
                          final slideAnim = Tween<Offset>(
                            begin: const Offset(0, 0.3),
                            end: Offset.zero,
                          ).animate(CurvedAnimation(
                            parent: _staggerController,
                            curve: Interval(start, end,
                                curve: Curves.easeOutCubic),
                          ));
                          final fadeAnim =
                              Tween<double>(begin: 0, end: 1).animate(
                            CurvedAnimation(
                              parent: _staggerController,
                              curve: Interval(start, end, curve: Curves.easeIn),
                            ),
                          );
                          return SlideTransition(
                            position: slideAnim,
                            child: FadeTransition(
                              opacity: fadeAnim,
                              child: _MatchCard(
                                match: _results[i],
                                rank: i + 1,
                                animController: _staggerController,
                                animStart: start,
                                animEnd: end,
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

// ─── Veri modeli ───
class FieldMatch {
  final String fieldName;
  final double areaDekar, uygunluk, yieldPerDekar, totalYield;
  final int maxPlants;
  final String reason, suggestion;

  FieldMatch({
    required this.fieldName,
    required this.areaDekar,
    required this.uygunluk,
    required this.maxPlants,
    required this.yieldPerDekar,
    required this.totalYield,
    required this.reason,
    required this.suggestion,
  });
}

// ─── Animasyonlu Eşleşme Kartı ───
class _MatchCard extends StatelessWidget {
  final FieldMatch match;
  final int rank;
  final AnimationController animController;
  final double animStart, animEnd;

  const _MatchCard({
    required this.match,
    required this.rank,
    required this.animController,
    required this.animStart,
    required this.animEnd,
  });

  Color get _color => match.uygunluk >= 75
      ? Colors.green
      : match.uygunluk >= 50
          ? Colors.orange
          : Colors.red;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Başlık satırı
            Row(
              children: [
                // Sıralama rozeti
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: rank == 1 ? Colors.amber : Colors.grey.shade300,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text('#$rank',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: rank == 1 ? Colors.white : Colors.black87,
                      )),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(match.fieldName,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                      Text('${match.areaDekar.toStringAsFixed(1)} Dekar',
                          style: TextStyle(
                              fontSize: 13, color: Colors.grey.shade600)),
                    ],
                  ),
                ),
                // Animasyonlu dairesel uygunluk göstergesi
                _AnimatedGauge(
                  value: match.uygunluk / 100,
                  color: _color,
                  controller: animController,
                  start: animStart,
                  end: animEnd,
                ),
              ],
            ),
            const SizedBox(height: 14),

            // İstatistik kutuları
            Row(
              children: [
                _StatBox(
                  icon: Icons.local_florist,
                  label: 'Bitki Sayısı',
                  value: _formatNumber(match.maxPlants),
                  color: Colors.green,
                ),
                const SizedBox(width: 8),
                _StatBox(
                  icon: Icons.inventory_2,
                  label: 'Toplam Verim',
                  value: '${_formatNumber(match.totalYield.round())} kg',
                  color: Colors.deepOrange,
                ),
                const SizedBox(width: 8),
                _StatBox(
                  icon: Icons.speed,
                  label: 'Dekar Verim',
                  value: '${match.yieldPerDekar.round()} kg',
                  color: Colors.indigo,
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Neden
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _color.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(match.reason,
                  style: TextStyle(
                      fontSize: 14, color: Colors.grey.shade800, height: 1.4)),
            ),

            // Öneri
            if (match.suggestion.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.lightbulb,
                        size: 18, color: Colors.amber.shade700),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(match.suggestion,
                          style: TextStyle(
                              fontSize: 13,
                              color: Colors.amber.shade900,
                              fontStyle: FontStyle.italic)),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatNumber(int n) {
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toString();
  }
}

// ─── İstatistik Kutusu ───
class _StatBox extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final Color color;
  const _StatBox(
      {required this.icon,
      required this.label,
      required this.value,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(height: 4),
            Text(value,
                style: TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 14, color: color),
                textAlign: TextAlign.center),
            Text(label,
                style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

// ─── Animasyonlu Dairesel Gösterge ───
class _AnimatedGauge extends StatelessWidget {
  final double value;
  final Color color;
  final AnimationController controller;
  final double start, end;

  const _AnimatedGauge({
    required this.value,
    required this.color,
    required this.controller,
    required this.start,
    required this.end,
  });

  @override
  Widget build(BuildContext context) {
    final anim = Tween<double>(begin: 0, end: value).animate(
      CurvedAnimation(
        parent: controller,
        curve: Interval(start, min(end + 0.2, 1.0), curve: Curves.easeOutCubic),
      ),
    );
    return AnimatedBuilder(
      animation: anim,
      builder: (context, child) {
        return SizedBox(
          width: 60,
          height: 60,
          child: CustomPaint(
            painter: _GaugePainter(anim.value, color),
            child: Center(
              child: Text(
                '%${(anim.value * 100).toInt()}',
                style: TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 14, color: color),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _GaugePainter extends CustomPainter {
  final double progress;
  final Color color;
  _GaugePainter(this.progress, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;

    // Arka plan halkası
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = Colors.grey.shade200
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6,
    );

    // İlerleme yayı
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      2 * pi * progress,
      false,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _GaugePainter old) =>
      old.progress != progress || old.color != color;
}
