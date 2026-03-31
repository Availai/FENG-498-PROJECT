import 'package:flutter/material.dart';
import '../services/agri_service.dart';
import 'crop_field_match_screen.dart';
import 'camera_screen.dart';

class FieldDetailScreen extends StatefulWidget {
  final dynamic fieldData;
  const FieldDetailScreen({super.key, required this.fieldData});
  @override
  State<FieldDetailScreen> createState() => _FieldDetailScreenState();
}

class _FieldDetailScreenState extends State<FieldDetailScreen> {
  Map<String, dynamic>? _analysis;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAnalysis();
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
          _error = 'Veri yüklenirken hata: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.fieldData;
    return Scaffold(
      appBar: AppBar(
        title: Text(d['name'] ?? 'Tarla Detayı'),
        actions: [
          IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadAnalysis,
              tooltip: 'Yenile'),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
              CircularProgressIndicator(color: Colors.green),
              SizedBox(height: 16),
              Text(
                  'Tarla analizi yükleniyor...\nHava, toprak ve AI verileri getiriliyor.',
                  textAlign: TextAlign.center),
            ]))
          : _error != null
              ? Center(
                  child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.cloud_off,
                            size: 60, color: Colors.red),
                        const SizedBox(height: 16),
                        Text(_error!, textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        FilledButton.icon(
                            onPressed: _loadAnalysis,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Tekrar Dene')),
                      ])))
              : _buildContent(),
    );
  }

  Widget _buildContent() {
    final a = _analysis!;
    final List dailyForecast = a['daily_forecast'] ?? [];
    final List crops = a['crops'] ?? [];
    final d = widget.fieldData;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        // ── BAŞLIK KARTI ──
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
                colors: [Colors.green.shade700, Colors.teal.shade600]),
            borderRadius: BorderRadius.circular(16),
          ),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Icon(Icons.landscape, color: Colors.white, size: 32),
              const SizedBox(width: 12),
              Expanded(
                  child: Text(d['name'] ?? 'Tarla',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold))),
            ]),
            const SizedBox(height: 8),
            Text(
              'Kayıt: ${d['date']} • ${d['area_dekar'] != null ? '${(d['area_dekar'] as num).toStringAsFixed(1)} Dekar' : 'Alan bilgisi yok'}',
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ]),
        ),

        const SizedBox(height: 16),

        // ── ANLIK HAVA ──
        const Text('🌤️ Anlık Hava Durumu',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Row(children: [
          _wTile(Icons.thermostat, '${(a['temp'] as num).toStringAsFixed(1)}°C',
              'Sıcaklık', Colors.orange),
          const SizedBox(width: 8),
          _wTile(
              Icons.water_drop,
              '%${(a['humidity'] as num).toStringAsFixed(0)}',
              'Nem',
              Colors.blue),
          const SizedBox(width: 8),
          _wTile(Icons.air, '${(a['wind'] as num).toStringAsFixed(1)} m/s',
              'Rüzgar', Colors.cyan),
        ]),
        if ((a['weather_desc'] as String).isNotEmpty)
          Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                  '${(a['weather_desc'] as String)[0].toUpperCase()}${(a['weather_desc'] as String).substring(1)}',
                  style: TextStyle(color: Colors.grey.shade700, fontSize: 14))),

        const SizedBox(height: 16),

        // ── TOPRAK pH + AGROMONITORING ──
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.brown.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.brown.shade200),
          ),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Icon(Icons.science, color: Colors.brown.shade700, size: 28),
              const SizedBox(width: 12),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text('Toprak pH: ${(a['ph'] as num).toStringAsFixed(1)}',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.brown.shade800)),
                    Text(_phComment((a['ph'] as num).toDouble()),
                        style: TextStyle(
                            fontSize: 13, color: Colors.brown.shade600)),
                  ])),
            ]),
            if ((a['soil_moisture'] as num?)?.toDouble() != null &&
                (a['soil_moisture'] as num).toDouble() > 0) ...[
              const Divider(height: 16),
              Row(children: [
                _soilMiniTile(
                    Icons.water_drop,
                    'Toprak Nem',
                    '%${((a['soil_moisture'] as num).toDouble() * 100).toStringAsFixed(1)}',
                    Colors.blue),
                const SizedBox(width: 12),
                _soilMiniTile(
                    Icons.thermostat,
                    'Toprak Sıcaklık',
                    '${(a['soil_temp_c'] as num).toStringAsFixed(1)}°C',
                    Colors.deepOrange),
              ]),
              Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text('📡 Kaynak: Agromonitoring API (canlı veri)',
                      style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                          fontStyle: FontStyle.italic))),
            ],
          ]),
        ),

        const SizedBox(height: 20),

        // ── 7 GÜNLÜK TAHMİN ──
        const Text('📅 7 Günlük Hava Tahmini',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
              children: dailyForecast.map<Widget>((day) {
            final date = (day['date'] as String).substring(5);
            final max = (day['max'] as num).toStringAsFixed(0);
            final min = (day['min'] as num).toStringAsFixed(0);
            final rain = (day['rain'] as num).toDouble();
            return Container(
              width: 90,
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: rain > 5 ? Colors.blue.shade50 : Colors.amber.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: rain > 5
                        ? Colors.blue.shade200
                        : Colors.amber.shade200),
              ),
              child: Column(children: [
                Text(date,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 4),
                Icon(rain > 5 ? Icons.umbrella : Icons.wb_sunny,
                    color: rain > 5 ? Colors.blue : Colors.orange, size: 22),
                const SizedBox(height: 4),
                Text('$max° / $min°', style: const TextStyle(fontSize: 12)),
                if (rain > 0)
                  Text('${rain.toStringAsFixed(1)} mm',
                      style:
                          TextStyle(fontSize: 11, color: Colors.blue.shade700)),
              ]),
            );
          }).toList()),
        ),
        Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
                'Ort. Sıcaklık: ${a['avg_weekly_temp']}°C  •  Toplam Yağış: ${a['total_weekly_rain']} mm',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13))),

        const SizedBox(height: 20),

        // ── NE EKİLEBİLİR ──
        const Text('🌾 Bu Tarlada Ne Ekilebilir?',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ...crops.map<Widget>((crop) => _cropCard(crop)),

        const SizedBox(height: 20),

        // ── AI YORUM ──
        const Text('🤖 AI Haftalık Tarla Yorumu',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.indigo.shade50,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.indigo.shade200),
          ),
          child: Text(a['ai_weekly_comment'] ?? '',
              style: const TextStyle(fontSize: 15, height: 1.6)),
        ),

        const SizedBox(height: 24),

        // ── EYLEM BUTONLARI ──
        const Text('⚡ Hızlı İşlemler',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        FilledButton.icon(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CropFieldMatchScreen()),
          ),
          icon: const Icon(Icons.compare_arrows),
          label: const Text('Ürün–Tarla Uygunluk Analizi'),
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(52),
            backgroundColor: Colors.indigo.shade700,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 10),
        FilledButton.icon(
          onPressed: () => _cropSelectForPlan(context, d['name'] ?? ''),
          icon: const Icon(Icons.edit_calendar),
          label: const Text('AI ile Ekim Planı Oluştur'),
          style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              backgroundColor: Colors.teal.shade700,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12))),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: () => Navigator.push(
              context, MaterialPageRoute(builder: (_) => const CameraScreen())),
          icon: const Icon(Icons.camera_alt),
          label: const Text('Bu Tarlada Bitki/Toprak Tara'),
          style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              side: BorderSide(color: Colors.green.shade700),
              foregroundColor: Colors.green.shade700,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12))),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: () => _fertilizerTip(context, a),
          icon: const Icon(Icons.science),
          label: const Text('Gübre ve Toprak İyileştirme Önerisi'),
          style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              side: BorderSide(color: Colors.brown.shade700),
              foregroundColor: Colors.brown.shade700,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12))),
        ),
        const SizedBox(height: 40),
      ]),
    );
  }

  Widget _wTile(IconData icon, String value, String label, Color c) {
    return Expanded(
        child: Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
          color: c.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: c.withValues(alpha: 0.3))),
      child: Column(children: [
        Icon(icon, color: c, size: 26),
        const SizedBox(height: 6),
        Text(value,
            style:
                TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: c)),
        Text(label,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
      ]),
    ));
  }

  Widget _cropCard(dynamic crop) {
    final double uygunluk = (crop['uygunluk'] as num?)?.toDouble() ?? 0;
    final Color uygunlukColor = uygunluk >= 80
        ? Colors.green
        : uygunluk >= 60
            ? Colors.orange
            : Colors.red;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: CircleAvatar(
              backgroundColor: Colors.green.shade100,
              child: const Icon(Icons.eco, color: Colors.green)),
          title: Text(crop['name'],
              style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Mevsim: ${crop['season']}',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
            const SizedBox(height: 4),
            Row(children: [
              Icon(Icons.check_circle, size: 14, color: uygunlukColor),
              const SizedBox(width: 4),
              Text('Uygunluk: %${uygunluk.toStringAsFixed(0)}',
                  style: TextStyle(
                      color: uygunlukColor,
                      fontSize: 13,
                      fontWeight: FontWeight.bold)),
            ]),
          ]),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Uygunluk çubuğu
                    Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.grey.shade200),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: uygunluk / 100,
                          minHeight: 8,
                          backgroundColor: Colors.grey.shade200,
                          valueColor: AlwaysStoppedAnimation(uygunlukColor),
                        ),
                      ),
                    ),
                    _cropInfo('📋 Genel Bilgi', crop['info']),
                    _cropInfo('🧪 Gübreleme', crop['fertilizer']),
                    _cropInfo('🌧️ Hava Etkisi', crop['weather_impact']),
                    _cropInfo('🛠️ Bakım', crop['care_details']),
                    const SizedBox(height: 8),
                    SizedBox(
                        width: double.infinity,
                        child: FilledButton.tonal(
                          onPressed: () => _genPlan(crop['name']),
                          child: Text('${crop['name']} için AI Ekim Planı'),
                        )),
                    const SizedBox(height: 8),
                  ]),
            )
          ],
        ),
      ),
    );
  }

  Widget _cropInfo(String title, String? content) {
    if (content == null || content.isEmpty) {
      return const SizedBox.shrink();
    }
    return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade800,
                    fontSize: 14)),
            const SizedBox(height: 2),
            Text(content, style: const TextStyle(fontSize: 14, height: 1.4)),
          ],
        ));
  }

  Widget _soilMiniTile(IconData icon, String label, String value, Color c) {
    return Expanded(
        child: Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: c.withValues(alpha: 0.2)),
      ),
      child: Row(children: [
        Icon(icon, color: c, size: 20),
        const SizedBox(width: 8),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
          Text(value,
              style: TextStyle(
                  fontSize: 14, fontWeight: FontWeight.bold, color: c)),
        ]),
      ]),
    ));
  }

  String _phComment(double ph) {
    if (ph < 5.5) {
      return 'Çok asidik — kireçleme gerekebilir';
    }
    if (ph < 6.0) {
      return 'Hafif asidik — çoğu sebze için uygun';
    }
    if (ph < 7.0) {
      return 'Nötre yakın — ideal tarım toprağı';
    }
    if (ph < 7.5) {
      return 'Hafif bazik — kabul edilebilir';
    }
    return 'Bazik toprak — kükürt uygulaması düşünülebilir';
  }

  void _cropSelectForPlan(BuildContext context, String fieldName) {
    final crops = _analysis?['crops'] as List? ?? [];
    if (crops.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Önce ürün önerileri yüklenmelidir.')));
      return;
    }
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Hangi ürün için plan oluşturulsun?',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              ...crops.map<Widget>((crop) => ListTile(
                    leading: const Icon(Icons.eco, color: Colors.green),
                    title: Text(crop['name']),
                    onTap: () {
                      Navigator.pop(ctx);
                      _genPlan(crop['name']);
                    },
                  )),
            ],
          )),
    );
  }

  void _genPlan(String cropName) {
    final d = widget.fieldData;
    final fieldName = d['name'] ?? 'Tarla';
    final double? lat = (d['latitude'] as num?)?.toDouble();
    final double? lng = (d['longitude'] as num?)?.toDouble();
    final double? area = (d['area_dekar'] as num?)?.toDouble();
    // Çevresel verileri de gönder
    final double? ph = (_analysis?['ph'] as num?)?.toDouble();
    final double? avgT = (_analysis?['avg_weekly_temp'] as num?)?.toDouble();
    final double? rain = (_analysis?['total_weekly_rain'] as num?)?.toDouble();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext loadingCtx) {
        AgriService.generateFieldPlan(
          cropName,
          fieldName,
          latitude: lat,
          longitude: lng,
          ph: ph,
          avgTemp: avgT,
          totalRain: rain,
          areaDekar: area,
        ).then((plan) {
          if (loadingCtx.mounted) {
            Navigator.pop(loadingCtx);
          }
          if (loadingCtx.mounted) {
            showDialog(
                context: loadingCtx,
                builder: (c) => AlertDialog(
                      title: Text('$cropName Ekim Planı',
                          style: const TextStyle(
                              color: Colors.teal, fontWeight: FontWeight.bold)),
                      content: SingleChildScrollView(
                          child: Text(plan,
                              style:
                                  const TextStyle(height: 1.5, fontSize: 15))),
                      actions: [
                        FilledButton(
                            onPressed: () => Navigator.pop(c),
                            child: const Text('Tamam'))
                      ],
                    ));
          }
        });
        return const AlertDialog(
            content: Row(children: [
          CircularProgressIndicator(color: Colors.green),
          SizedBox(width: 20),
          Expanded(
              child: Text(
                  'AI ekim planı hazırlanıyor...\nTarla verileri ile kişiselleştiriliyor.')),
        ]));
      },
    );
  }

  void _fertilizerTip(BuildContext context, Map<String, dynamic> a) {
    final ph = (a['ph'] as num).toDouble();
    String tip;
    if (ph < 5.5) {
      tip = '🧪 Toprak pH\'ınız ${ph.toStringAsFixed(1)} ile çok asidik.\n\n'
          '• Dekara 200-300 kg tarım kireci uygulayın.\n'
          '• Kireçleme sonbahar veya kış aylarında yapılmalıdır.\n'
          '• Organik madde (kompost, ahır gübresi) ekleyin.\n'
          '• 6 ay sonra pH\'ı tekrar ölçün.';
    } else if (ph < 6.0) {
      tip = '🧪 pH ${ph.toStringAsFixed(1)} — Hafif asidik.\n\n'
          '• Çoğu sebze için uygun aralıktadır.\n'
          '• Dekara 15-20 kg 15-15-15 kompoze gübre uygulayabilirsiniz.\n'
          '• Yaprak gübresi olarak hümik asit takviyesi faydalı olabilir.';
    } else if (ph < 7.5) {
      tip = '🧪 pH ${ph.toStringAsFixed(1)} — İdeal!\n\n'
          '• Toprak pH\'ınız mükemmel aralıkta.\n'
          '• Standart NPK gübrelemesi yeterlidir.\n'
          '• Her sezon sonunda dekara 2-3 ton yanmış ahır gübresi ekleyin.\n'
          '• Toprağın organik maddesini korumak için örtü bitkisi kullanın.';
    } else {
      tip = '🧪 pH ${ph.toStringAsFixed(1)} — Bazik toprak.\n\n'
          '• Dekara 20-30 kg elementel kükürt uygulayın.\n'
          '• Asit sevici bitkiler yerine alkali toleranslı çeşitler seçin.\n'
          '• Ahır gübresi ve kompost ile organik maddeyi artırın.';
    }
    showDialog(
        context: context,
        builder: (c) => AlertDialog(
              title: const Text('Gübre & Toprak İyileştirme',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.brown)),
              content: SingleChildScrollView(
                  child: Text(tip,
                      style: const TextStyle(fontSize: 15, height: 1.5))),
              actions: [
                FilledButton(
                    onPressed: () => Navigator.pop(c),
                    child: const Text('Anladım'))
              ],
            ));
  }
}
