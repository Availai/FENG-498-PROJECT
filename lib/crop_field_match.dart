import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:http/http.dart' as http;
import 'dart:math';

/// Seçilen ürünün kayıtlı tarlalara uygunluğunu animasyonlu gösterir.
class CropFieldMatchScreen extends StatefulWidget {
  const CropFieldMatchScreen({super.key});

  @override
  State<CropFieldMatchScreen> createState() => _CropFieldMatchScreenState();
}

class _CropFieldMatchScreenState extends State<CropFieldMatchScreen>
    with TickerProviderStateMixin {
  final _cropController = TextEditingController();
  bool _isLoading = false;
  List<FieldMatch> _results = [];

  // Her kart için staggered animasyon
  late AnimationController _staggerController;

  final List<String> _quickCrops = [
    '🍅 Domates',
    '🌽 Mısır',
    '🥒 Salatalık',
    '🍆 Patlıcan',
    '🌾 Buğday',
    '🫑 Biber',
    '🥔 Patates',
    '🧅 Soğan',
  ];

  @override
  void initState() {
    super.initState();
    _staggerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
  }

  @override
  void dispose() {
    _cropController.dispose();
    _staggerController.dispose();
    super.dispose();
  }

  Future<void> _analyze(String cropName) async {
    if (cropName.trim().isEmpty) return;

    final box = Hive.box('user_crops');
    final fields = <Map<String, dynamic>>[];
    for (int i = 0; i < box.length; i++) {
      final f = box.getAt(i);
      if (f != null && f['latitude'] != null) {
        fields.add(Map<String, dynamic>.from(f));
      }
    }

    if (fields.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Konum bilgisi olan kayıtlı tarla bulunamadı.')),
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
      final results = await _batchEvaluate(cropName, fields, fieldEnvList);

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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e')),
        );
      }
    }
  }

  /// Tarla çevre verilerini paralel çeker (hava + pH)
  Future<Map<String, double>> _fetchEnvData(double lat, double lng) async {
    double temp = 20, ph = 6.5, rain = 0, humidity = 50;
    await Future.wait([
      () async {
        try {
          final key = dotenv.env['WEATHER_API_KEY'] ?? '';
          final r = await http.get(Uri.parse(
            'https://api.openweathermap.org/data/2.5/weather?lat=$lat&lon=$lng&appid=$key&units=metric',
          )).timeout(const Duration(seconds: 8));
          if (r.statusCode == 200) {
            final d = jsonDecode(r.body);
            temp = (d['main']['temp'] as num).toDouble();
            humidity = (d['main']['humidity'] as num).toDouble();
          }
        } catch (_) {}
      }(),
      () async {
        try {
          final r = await http.get(Uri.parse(
            'https://rest.isric.org/soilgrids/v2.0/properties/query?lon=$lng&lat=$lat&property=phh2o&depth=0-5cm&value=mean',
          )).timeout(const Duration(seconds: 10));
          if (r.statusCode == 200) {
            final v = jsonDecode(r.body)['properties']?['layers']?[0]?['depths']?[0]?['values']?['mean'];
            if (v != null) ph = (v as num).toDouble() / 10.0;
          }
        } catch (_) {}
      }(),
      () async {
        try {
          final r = await http.get(Uri.parse(
            'https://api.open-meteo.com/v1/forecast?latitude=$lat&longitude=$lng&daily=precipitation_sum&timezone=auto',
          )).timeout(const Duration(seconds: 8));
          if (r.statusCode == 200) {
            final rains = jsonDecode(r.body)['daily']['precipitation_sum'] as List;
            for (int i = 0; i < min(7, rains.length); i++) {
              rain += (rains[i] as num).toDouble();
            }
          }
        } catch (_) {}
      }(),
    ]);
    return {'temp': temp, 'ph': ph, 'rain': rain, 'humidity': humidity};
  }

  /// Tek Gemini çağrısıyla tüm tarlaları toplu değerlendir
  Future<List<FieldMatch>> _batchEvaluate(
    String crop,
    List<Map<String, dynamic>> fields,
    List<Map<String, double>> envList,
  ) async {
    final model = GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: dotenv.env['GEMINI_API_KEY'] ?? '',
    );

    // Tarla bilgilerini prompt'a ekle
    final sb = StringBuffer();
    for (int i = 0; i < fields.length; i++) {
      final f = fields[i];
      final e = envList[i];
      final dekar = (f['area_dekar'] as num?)?.toDouble() ?? 1.0;
      sb.writeln('Tarla${i + 1}: "${f['name']}", $dekar Dekar, '
          'Sıcaklık:${e['temp']!.toStringAsFixed(1)}°C, '
          'pH:${e['ph']!.toStringAsFixed(1)}, '
          'Yağış:${e['rain']!.toStringAsFixed(1)}mm/hafta, '
          'Nem:%${e['humidity']!.toStringAsFixed(0)}');
    }

    final prompt = '''
"$crop" bitkisi için aşağıdaki tarlaların her birini değerlendir.
$sb
Her tarla için JSON döndür. Markdown KULLANMA, saf JSON array:
[
  {
    "index": 0,
    "uygunluk": 85,
    "max_bitki_sayisi": 1200,
    "dekara_verim_kg": 3500,
    "toplam_verim_kg": 3500,
    "neden": "pH ve sıcaklık ideal, yağış yeterli (1-2 cümle)",
    "oneri": "Damla sulama ile verimi %20 artırabilirsiniz (1 cümle)"
  }
]
Uygunluk 0-100 arası. max_bitki_sayisi tarlanın dekar alanına göre hesapla. toplam_verim_kg = dekara_verim * dekar.
''';

    final response = await model.generateContent([Content.text(prompt)]);
    String text = response.text?.trim() ?? '[]';
    if (text.startsWith('```json')) text = text.substring(7);
    if (text.startsWith('```')) text = text.substring(3);
    if (text.endsWith('```')) text = text.substring(0, text.length - 3);
    text = text.trim();

    final List decoded = jsonDecode(text);
    return decoded.map((item) {
      final idx = (item['index'] as int?) ?? 0;
      final f = fields[idx < fields.length ? idx : 0];
      return FieldMatch(
        fieldName: f['name'] ?? 'Tarla',
        areaDekar: (f['area_dekar'] as num?)?.toDouble() ?? 1.0,
        uygunluk: (item['uygunluk'] as num?)?.toDouble() ?? 0,
        maxPlants: (item['max_bitki_sayisi'] as num?)?.toInt() ?? 0,
        yieldPerDekar: (item['dekara_verim_kg'] as num?)?.toDouble() ?? 0,
        totalYield: (item['toplam_verim_kg'] as num?)?.toDouble() ?? 0,
        reason: item['neden']?.toString() ?? '',
        suggestion: item['oneri']?.toString() ?? '',
      );
    }).toList()
      ..sort((a, b) => b.uygunluk.compareTo(a.uygunluk));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ürün–Tarla Eşleştirme')),
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
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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
                                label: Text(c, style: const TextStyle(fontSize: 13)),
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
                              Icon(Icons.eco, size: 64, color: Colors.green.shade200),
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
                            curve: Interval(start, end, curve: Curves.easeOutCubic),
                          ));
                          final fadeAnim = Tween<double>(begin: 0, end: 1).animate(
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
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text('${match.areaDekar.toStringAsFixed(1)} Dekar',
                          style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
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
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade800, height: 1.4)),
            ),

            // Öneri
            if (match.suggestion.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.lightbulb, size: 18, color: Colors.amber.shade700),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(match.suggestion,
                          style: TextStyle(fontSize: 13, color: Colors.amber.shade900, fontStyle: FontStyle.italic)),
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
  const _StatBox({required this.icon, required this.label, required this.value, required this.color});

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
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: color),
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
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: color),
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
