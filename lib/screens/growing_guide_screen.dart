import 'package:flutter/material.dart';
import '../services/agri_service.dart';
import '../services/encyclopedia_extensions.dart';
import '../services/harvest_shift_estimator.dart';
import '../data/supported_crops.dart';
import '../utils/location_utils.dart';
import '../widgets/floating_toast.dart';
import '../widgets/weekly_water_card.dart';

class GrowingGuideScreen extends StatefulWidget {
  const GrowingGuideScreen({super.key});

  @override
  State<GrowingGuideScreen> createState() => _GrowingGuideScreenState();
}

class _GrowingGuideScreenState extends State<GrowingGuideScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  // Eskiden Hobi/Profesyonel toggle vardı; çiftçi için anlamı belirsizdi
  // (tarla zaten profesyonel ölçek). UI'dan kaldırıldı, backend uyumu için
  // sabit 'Profesyonel' kalıyor.
  static const String _scale = 'Profesyonel';
  bool _isLoading = false;
  Map<String, dynamic>? _result;
  String _currentCrop = '';
  String? _error;

  void _getGuide() async {
    final query = _searchCtrl.text.trim();
    if (query.isEmpty) {
      AppToast.show(
        context,
        message: 'Lütfen bir bitki adı girin.',
        type: ToastType.warning,
      );
      return;
    }
    final canonical = SupportedCrops.canonicalName(query);
    if (canonical == null) {
      AppToast.show(
        context,
        message:
            'Bu prototipte yalnız Ayçiçeği, Mısır ve Domates destekleniyor.',
        type: ToastType.warning,
      );
      return;
    }
    setState(() {
      _isLoading = true;
      _result = null;
      _error = null;
    });

    try {
      final pos = await getCurrentPosition();
      final result = await AgriService.getPlantGuide(
        canonical,
        pos.latitude,
        pos.longitude,
        scale: _scale,
      );

      if (mounted) {
        setState(() {
          _result = result;
          _currentCrop = canonical;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = '$e');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String get _cropEmoji {
    final n = _currentCrop.toLowerCase();
    if (n.contains('domates')) return '🍅';
    if (n.contains('mısır') || n.contains('misir')) return '🌽';
    if (n.contains('salatalık') || n.contains('salatalik')) return '🥒';
    if (n.contains('patlıcan') || n.contains('patlican')) return '🍆';
    if (n.contains('buğday') || n.contains('bugday')) return '🌾';
    if (n.contains('biber')) return '🫑';
    if (n.contains('patates')) return '🥔';
    if (n.contains('soğan') || n.contains('sogan')) return '🧅';
    if (n.contains('çilek') || n.contains('cilek')) return '🍓';
    if (n.contains('kavun')) return '🍈';
    if (n.contains('karpuz')) return '🍉';
    if (n.contains('üzüm') || n.contains('uzum')) return '🍇';
    if (n.contains('elma')) return '🍎';
    if (n.contains('armut')) return '🍐';
    if (n.contains('portakal')) return '🍊';
    if (n.contains('limon')) return '🍋';
    if (n.contains('fasulye')) return '🫘';
    if (n.contains('havuç') || n.contains('havuc')) return '🥕';
    return '🌱';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Akıllı Tarım Rehberi'), elevation: 0),
      body: Column(
        children: [
          // ── Arama Bölümü ──
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              borderRadius:
                  const BorderRadius.vertical(bottom: Radius.circular(30)),
              boxShadow: [
                BoxShadow(
                    color: Colors.green.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 5))
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Ne yetiştirmek istiyorsunuz?',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                TextField(
                  controller: _searchCtrl,
                  decoration: InputDecoration(
                    hintText: 'Ayçiçeği, Mısır veya Domates...',
                    filled: true,
                    fillColor: Colors.white,
                    prefixIcon: const Icon(Icons.search, color: Colors.green),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none),
                  ),
                  onSubmitted: (_) => _getGuide(),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _getGuide,
                    icon: _isLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                color: Colors.green, strokeWidth: 2))
                        : const Icon(Icons.auto_awesome, size: 18),
                    label: Text(_isLoading ? 'Yükleniyor...' : 'Rehber Oluştur',
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.green.shade800,
                      backgroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Sonuç Bölümü ──
          Expanded(
            child: _isLoading
                ? const Center(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                    CircularProgressIndicator(color: Colors.green),
                    SizedBox(height: 16),
                    Text('Hava tahmini, toprak ve bitki verileri\nçekiliyor...',
                        textAlign: TextAlign.center),
                  ]))
                : _result == null
                    ? _buildEmptyState()
                    : _buildGuideContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildGuideContent() {
    final crop = (_result!['cropData'] as Map<String, dynamic>?) ?? {};
    final env = (_result!['envData'] as Map<String, dynamic>?) ?? {};
    final pd = (_result!['plantingData'] as Map<String, dynamic>?) ?? {};
    final forecast = (_result!['weeklyForecast'] as List?) ?? [];
    final waterPlan = (_result!['weeklyWaterPlan'] as List?) ?? [];
    final hasTurkiyeGuide =
        ((_result!['turkiyeGuide'] as Map?)?.isNotEmpty ?? false);

    final temp = (env['temp'] as num?)?.toDouble() ?? 20;
    final ph = (env['ph'] as num?)?.toDouble() ?? 6.8;
    final hum = (env['humidity'] as num?)?.toDouble() ?? 50;
    final location = env['location']?.toString() ?? 'Bölgeniz';
    final uygunluk = (crop['region_uygunluk'] as num?)?.toDouble() ?? 70;
    final idealTempMin = (crop['ideal_temp_min'] as num?)?.toDouble() ?? 15;
    final idealTempMax = (crop['ideal_temp_max'] as num?)?.toDouble() ?? 30;
    final idealPhMin = (crop['ideal_ph_min'] as num?)?.toDouble() ?? 5.5;
    final idealPhMax = (crop['ideal_ph_max'] as num?)?.toDouble() ?? 7.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── 1. Bitki Özet Kartı ──
          Card(
            elevation: 4,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: LinearGradient(
                  colors: [Colors.green.shade700, Colors.green.shade400],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(_cropEmoji, style: const TextStyle(fontSize: 42)),
                      const SizedBox(width: 14),
                      Expanded(
                        // Eskiden Latince ad (Solanum lycopersicum vb.) ikinci
                        // satırda gösteriliyordu — çiftçiye katma değer yoktu,
                        // kaldırıldı. Bunun yerine "tarlana ne kadar uygun?"
                        // sözel etiketi başlığın altında daha öne çıkarıldı.
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_currentCrop.toUpperCase(),
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold)),
                            const SizedBox(height: 2),
                            Text(_uygunlukSozel(uygunluk),
                                style: TextStyle(
                                    color:
                                        Colors.white.withValues(alpha: 0.92),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                      // Uygunluk rozeti
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.2),
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        alignment: Alignment.center,
                        child: Text('%${uygunluk.round()}',
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(crop['desc']?.toString() ?? '',
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 14,
                          height: 1.4)),
                  const SizedBox(height: 14),
                  // Mini bilgi satırı
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      _infoBadge(Icons.calendar_month,
                          crop['cycle']?.toString() ?? ''),
                      _infoBadge(Icons.timer,
                          '${crop['harvest_days'] ?? 90} gün hasat'),
                      _infoBadge(Icons.wb_sunny,
                          '${crop['sunlight_hours'] ?? 8}sa güneş'),
                      _infoBadge(Icons.spa, crop['care']?.toString() ?? 'Orta'),
                      // "İç mekan uygun" badge'i kaldırıldı: tarla bağlamında
                      // saç-mas, çiftçi için yararsız bilgiydi.
                      if (crop['drought'] == true)
                        _infoBadge(
                            Icons.water_drop_outlined, 'Kuraklığa dayanıklı'),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          // ── 2. Bölge Uyumu Kartı ──
          Card(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.place, color: Colors.blue.shade700),
                      const SizedBox(width: 6),
                      Text('$location — Bölge Uyumu',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 15)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Sıcaklık barı
                  _rangeBar('Sıcaklık', temp, idealTempMin, idealTempMax, '°C',
                      Colors.orange),
                  const SizedBox(height: 8),
                  // pH barı
                  _rangeBar('Toprak pH', ph, idealPhMin, idealPhMax, '',
                      Colors.brown),
                  const SizedBox(height: 8),
                  // Nem
                  Row(
                    children: [
                      Icon(Icons.water_drop,
                          size: 18, color: Colors.blue.shade400),
                      const SizedBox(width: 6),
                      Text('Nem: %${hum.round()}',
                          style: const TextStyle(fontSize: 13)),
                    ],
                  ),
                  if (crop['region_note'] != null &&
                      (crop['region_note'] as String).isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: uygunluk >= 70
                            ? Colors.green.shade50
                            : Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Icon(
                              uygunluk >= 70
                                  ? Icons.check_circle
                                  : Icons.warning,
                              size: 18,
                              color: uygunluk >= 70
                                  ? Colors.green
                                  : Colors.orange),
                          const SizedBox(width: 8),
                          Expanded(
                              child: Text(crop['region_note'].toString(),
                                  style: const TextStyle(fontSize: 13))),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          // ── 3. Haftalık Hava & Sulama Planı ──
          WeeklyWaterCard(
            forecast: forecast,
            waterPlan: waterPlan,
            cropName: _currentCrop,
            cropEmoji: _cropEmoji,
          ),
          const SizedBox(height: 14),

          // ── 3b. Sıfırdan Hasada Yolculuk + Hasat Kestirimi ──
          _buildHarvestJourneyCard(
            crop: crop,
            forecast: forecast,
            avgTemp: temp,
            idealTempMin: idealTempMin,
            idealTempMax: idealTempMax,
          ),
          const SizedBox(height: 14),

          // ── 4. Ekim & Dikim Bilgileri ──
          Card(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.grass, color: Colors.green),
                      SizedBox(width: 6),
                      Text('Ekim & Dikim',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 15)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _detailTile(Icons.arrow_downward,
                          '${pd['depth_cm'] ?? 3}cm', 'Derinlik', Colors.brown),
                      _detailTile(
                          Icons.swap_horiz,
                          '${pd['row_spacing_cm'] ?? 50}cm',
                          'Sıra Arası',
                          Colors.green),
                      _detailTile(
                          Icons.space_bar,
                          '${pd['plant_spacing_cm'] ?? 40}cm',
                          'Bitki Arası',
                          Colors.teal),
                      _detailTile(
                          Icons.grid_view,
                          '${pd['seeds_per_dekar'] ?? 500}',
                          'Fide/Dekar',
                          Colors.indigo),
                    ],
                  ),
                  if (crop['best_planting_months'] != null &&
                      (crop['best_planting_months'] as String).isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Icon(Icons.date_range,
                            size: 18, color: Colors.green.shade700),
                        const SizedBox(width: 6),
                        Expanded(
                            child: Text(
                                'Ekim Ayları: ${crop['best_planting_months']}',
                                style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.green.shade800))),
                      ],
                    ),
                  ],
                  if (crop['planting_tip'] != null &&
                      (crop['planting_tip'] as String).isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                          color: Colors.amber.shade50,
                          borderRadius: BorderRadius.circular(10)),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.lightbulb,
                              size: 18, color: Colors.amber.shade700),
                          const SizedBox(width: 6),
                          Expanded(
                              child: Text(crop['planting_tip'].toString(),
                                  style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.amber.shade900,
                                      fontStyle: FontStyle.italic))),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          // ── 5. Sulama & Gübre ──
          Card(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.water_drop, color: Colors.blue),
                      SizedBox(width: 6),
                      Text('Sulama & Gübreleme',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 15)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _detailTile(
                          Icons.water,
                          pd['irrigation_type']?.toString() ?? 'Damla',
                          'Sulama Tipi',
                          Colors.blue),
                      _detailTile(
                          Icons.opacity,
                          '${pd['daily_water_liters'] ?? 2}L',
                          'Günlük/Bitki',
                          Colors.cyan),
                      _detailTile(
                          Icons.science,
                          pd['fertilizer_type']?.toString() ?? 'NPK',
                          'Gübre',
                          Colors.orange),
                      _detailTile(
                          Icons.straighten,
                          '${pd['fertilizer_band_cm'] ?? 15}cm',
                          'Gübre Mesafesi',
                          Colors.deepOrange),
                    ],
                  ),
                  if (pd['fertilizer_schedule'] != null &&
                      (pd['fertilizer_schedule'] as String).isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(10)),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.schedule,
                              size: 18, color: Colors.orange.shade700),
                          const SizedBox(width: 6),
                          Expanded(
                              child: Text(pd['fertilizer_schedule'].toString(),
                                  style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.orange.shade900))),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          if (hasTurkiyeGuide) ...[
            _buildTurkiyeTechnicalGuideCard(),
            const SizedBox(height: 14),
          ],

          // ── 6. Birlikte Ekim & Zararlılar ──
          Card(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.groups, color: Colors.purple),
                      SizedBox(width: 6),
                      Text('Birlikte Ekim & Zararlılar',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 15)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (crop['companion_plants'] != null &&
                      (crop['companion_plants'] as String).isNotEmpty)
                    _companionRow(Icons.handshake, 'İyi Eş:',
                        crop['companion_plants'].toString(), Colors.green),
                  if (crop['avoid_plants'] != null &&
                      (crop['avoid_plants'] as String).isNotEmpty) ...[
                    const SizedBox(height: 6),
                    _companionRow(Icons.block, 'Uzak Tut:',
                        crop['avoid_plants'].toString(), Colors.red),
                  ],
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(10)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.bug_report,
                                size: 18, color: Colors.red.shade700),
                            const SizedBox(width: 6),
                            Text('Zararlılar',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: Colors.red.shade800)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(crop['pests']?.toString() ?? '',
                            style: TextStyle(
                                fontSize: 13, color: Colors.red.shade900)),
                        if (crop['pest_prevention'] != null &&
                            (crop['pest_prevention'] as String).isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.shield,
                                  size: 16, color: Colors.green.shade700),
                              const SizedBox(width: 4),
                              Expanded(
                                  child: Text(
                                      crop['pest_prevention'].toString(),
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.green.shade900))),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (crop['pruning'] != null &&
                      crop['pruning'] != 'Yok' &&
                      (crop['pruning'] as String).isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Icon(Icons.content_cut,
                            size: 18, color: Colors.purple.shade700),
                        const SizedBox(width: 6),
                        Expanded(
                            child: Text('Budama: ${crop['pruning']}',
                                style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.purple.shade800))),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          // ── 7. Ansiklopedi Derinleştirme — Modül 4 ──
          _buildEncyclopediaDeepCard(),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  /// Boş ekran — kullanıcı henüz arama yapmadıysa. Eskiden sade gri ikon ve
  /// "bitki adı yaz" satırı vardı; çiftçi için soğuk ve nereye tıklayacağı
  /// belirsizdi. Artık 3 vitrin bitki (ayçiçeği, mısır, domates) için tek
  /// dokunuşluk hızlı seçim butonları + sıcak bir karşılama metni var.
  Widget _buildEmptyState() {
    final quickPicks = <Map<String, String>>[
      {'name': 'Ayçiçeği', 'emoji': '🌻'},
      {'name': 'Mısır', 'emoji': '🌽'},
      {'name': 'Domates', 'emoji': '🍅'},
    ];

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🌱', style: TextStyle(fontSize: 56)),
            const SizedBox(height: 12),
            Text(
              'Hangi bitkiyi yetiştireceksin?',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Tarlana göre ekim, sulama ve hasat planını çıkaralım.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 22),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: quickPicks.map((p) {
                return InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () {
                    _searchCtrl.text = p['name']!;
                    _getGuide();
                  },
                  child: Container(
                    width: 100,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(p['emoji']!, style: const TextStyle(fontSize: 32)),
                        const SizedBox(height: 4),
                        Text(
                          p['name']!,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Colors.green.shade900,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 18),
            Text(
              'veya yukarıdaki kutuya bitki adı yaz',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
            ),
            if (_error != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Hata: $_error',
                  style: TextStyle(color: Colors.red.shade800, fontSize: 12),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Uygunluk yüzdesini çiftçi diline çevirir.
  /// Eskiden ham "%67" rakamı sözeldi, çiftçi için anlamsızdı; renk kodlu
  /// metin ("Tarlana çok uygun") karar vermeyi kolaylaştırıyor.
  String _uygunlukSozel(double pct) {
    if (pct >= 80) return '✅ Tarlana çok uygun';
    if (pct >= 60) return '🟢 Tarlana uygun';
    if (pct >= 40) return '🟡 Sınırda — dikkatli git';
    return '🔴 Tarlana zor — başka çeşit dene';
  }

  Widget _infoBadge(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 4),
          Text(text,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _rangeBar(String label, double current, double idealMin,
      double idealMax, String unit, Color color) {
    final inRange = current >= idealMin && current <= idealMax;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('$label: ',
                style:
                    const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
            Text('${current.toStringAsFixed(1)}$unit',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: inRange ? Colors.green : Colors.red)),
            Text(
                '  (ideal: ${idealMin.toStringAsFixed(1)}–${idealMax.toStringAsFixed(1)}$unit)',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
            const Spacer(),
            Icon(inRange ? Icons.check_circle : Icons.error,
                size: 16, color: inRange ? Colors.green : Colors.red),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value:
                ((current - idealMin) / (idealMax - idealMin)).clamp(0.0, 1.0),
            backgroundColor: Colors.grey.shade200,
            color: inRange ? Colors.green : Colors.red.shade300,
            minHeight: 5,
          ),
        ),
      ],
    );
  }

  Widget _detailTile(IconData icon, String value, String label, Color color) {
    return Container(
      width: (MediaQuery.of(context).size.width - 72) / 2,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Expanded(
              child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value,
                  style: TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 13, color: color),
                  overflow: TextOverflow.ellipsis),
              Text(label,
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
            ],
          )),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _mapList(Object? raw) {
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList(growable: false);
  }

  Widget _buildTurkiyeTechnicalGuideCard() {
    final guide = Map<String, dynamic>.from(
      (_result!['turkiyeGuide'] as Map?) ?? <String, dynamic>{},
    );
    if (guide.isEmpty) return const SizedBox.shrink();

    final metrics = Map<String, dynamic>.from(
      (_result!['technicalMetrics'] as Map?) ?? <String, dynamic>{},
    );
    final stages = _mapList(_result!['growthStages']);
    final pests = _mapList(_result!['pestGuides']);
    final regions = _mapList(_result!['regionalCalendar']);
    final nutrition = _mapList(guide['nutritionPlan']);
    final sources = ((_result!['sourceRefs'] as List?) ?? const [])
        .map((source) => source.toString())
        .where((source) => source.trim().isNotEmpty)
        .toList(growable: false);
    final cropName = guide['cropName']?.toString() ?? _currentCrop;
    final summary = guide['summary']?.toString() ?? '';
    final rotation = _result!['rotationNotes']?.toString() ?? '';
    final harvest = _result!['harvestQualityNotes']?.toString() ?? '';

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.verified, color: Colors.green.shade700),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '$cropName — Türkiye Teknik Rehberi',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(summary, style: const TextStyle(fontSize: 13, height: 1.35)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: metrics.entries
                  .take(6)
                  .map(
                    (entry) => _guideMetricTile(
                      entry.key,
                      entry.value.toString(),
                      Colors.green,
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 6),
            ExpansionTile(
              tilePadding: const EdgeInsets.symmetric(horizontal: 4),
              leading: const Icon(Icons.straighten, color: Colors.green),
              title: const Text(
                'Teknik Ölçüler',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              children: metrics.entries
                  .map(
                    (entry) => ListTile(
                      dense: true,
                      title: Text(
                        entry.key,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        entry.value.toString(),
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  )
                  .toList(),
            ),
            ExpansionTile(
              tilePadding: const EdgeInsets.symmetric(horizontal: 4),
              leading: const Icon(Icons.timeline, color: Colors.teal),
              title: const Text(
                'Dönem Dönem Yapılacaklar',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              children: stages.map((stage) {
                return ListTile(
                  dense: true,
                  title: Text(
                    '${stage['title']} — ${stage['timing']}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        stage['action']?.toString() ?? '',
                        style: const TextStyle(fontSize: 12),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Risk: ${stage['risk'] ?? ''}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.red.shade800,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
            ExpansionTile(
              tilePadding: const EdgeInsets.symmetric(horizontal: 4),
              leading: const Icon(Icons.science, color: Colors.orange),
              title: const Text(
                'Gübreleme Planı',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              children: nutrition.map((item) {
                return ListTile(
                  dense: true,
                  title: Text(
                    '${item['phase']} — ${item['timing']}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    item['recommendation']?.toString() ?? '',
                    style: const TextStyle(fontSize: 12),
                  ),
                );
              }).toList(),
            ),
            ExpansionTile(
              tilePadding: const EdgeInsets.symmetric(horizontal: 4),
              leading: const Icon(Icons.bug_report, color: Colors.red),
              title: const Text(
                'Hastalık ve Zararlı Takibi',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              children: pests.map((pest) {
                return Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${pest['name']} (${pest['type']})',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: Colors.red.shade900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '🔍 Belirti: ${pest['symptoms']}',
                          style: const TextStyle(fontSize: 12),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '👀 Nasıl izlenir: ${pest['monitoring']}',
                          style: const TextStyle(fontSize: 12),
                        ),
                        if (pest['samplingMethod'] != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            '🌾 Tarlada bakma şekli: ${pest['samplingMethod']}',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                        if (pest['economicThreshold'] != null) ...[
                          const SizedBox(height: 2),
                          // Akademikte "ekonomik eşik" denir; çiftçi için
                          // "bu sayıdan sonra zarar başlar" daha anlaşılır.
                          Text(
                            '⚠️ Sınır (bunu geçince zarar başlar): ${pest['economicThreshold']}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.red.shade800,
                            ),
                          ),
                        ],
                        const SizedBox(height: 2),
                        Text(
                          '🛡️ İlk önlem: ${pest['integratedControl']}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.green.shade900,
                          ),
                        ),
                        if (pest['chemicalGate'] != null) ...[
                          const SizedBox(height: 2),
                          // Eskiden "Kimyasal kapı" — agronomik jargon.
                          Text(
                            '🚪 İlaç ne zaman gerekli: ${pest['chemicalGate']}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.orange.shade900,
                            ),
                          ),
                        ],
                        const SizedBox(height: 2),
                        // Eskiden "Kimyasal karar".
                        Text(
                          '💊 İlaç seçeneği: ${pest['escalation']}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.orange.shade900,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            ExpansionTile(
              tilePadding: const EdgeInsets.symmetric(horizontal: 4),
              leading: const Icon(Icons.map, color: Colors.blue),
              title: const Text(
                'Bölgesel Takvim',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              children: regions.map((region) {
                return ListTile(
                  dense: true,
                  title: Text(
                    region['region']?.toString() ?? '',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    'Ekim: ${region['plantingWindow']}\n'
                    'Hasat: ${region['harvestWindow']}\n'
                    '${region['notes']}',
                    style: const TextStyle(fontSize: 12),
                  ),
                );
              }).toList(),
            ),
            ExpansionTile(
              tilePadding: const EdgeInsets.symmetric(horizontal: 4),
              leading: const Icon(Icons.fact_check, color: Colors.brown),
              title: const Text(
                'Hasat, Münavebe ve Kaynak',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              children: [
                if (harvest.isNotEmpty)
                  ListTile(
                    dense: true,
                    title: const Text(
                      'Hasat Kalitesi',
                      style:
                          TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    subtitle:
                        Text(harvest, style: const TextStyle(fontSize: 12)),
                  ),
                if (rotation.isNotEmpty)
                  ListTile(
                    dense: true,
                    title: const Text(
                      'Münavebe (sonraki sezon ne ekilmeli?)',
                      style:
                          TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    subtitle:
                        Text(rotation, style: const TextStyle(fontSize: 12)),
                  ),
                if (sources.isNotEmpty)
                  ListTile(
                    dense: true,
                    title: const Text(
                      'Kaynak Dayanağı',
                      style:
                          TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      sources.map((source) => '• $source').join('\n'),
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _guideMetricTile(String label, String value, Color color) {
    return Container(
      width: (MediaQuery.of(context).size.width - 72) / 2,
      padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────
  // Çiftçi İpuçları — sadeleştirilmiş ansiklopedi
  //
  // Eskiden 6 ayrı ExpansionTile vardı. 3'ü Türkiye Teknik Rehberi kartıyla
  // birebir çakışıyordu (Adım Adım Yetiştirme, Bölgesel Ekim Takvimi,
  // Hastalık & Zararlı Tanıma) — silindi. Kalan 3'ü (Toprak İyileştirme,
  // Organik Tarım, Geleneksel Anadolu Bilgisi) bitkiye özel değil; tek
  // "Çiftçi İpuçları" başlığı altında konsolide edildi.
  // ─────────────────────────────────────────────────────────────────────
  Widget _buildEncyclopediaDeepCard() {
    final tips = <Map<String, String>>[
      ...EncyclopediaExtensions.soilImprovement.map(
        (item) => {
          'kategori': '🌍 Toprak',
          'baslik': item['baslik'] ?? '',
          'aciklama': item['oneri'] ?? '',
        },
      ),
      ...EncyclopediaExtensions.organicMethods.map(
        (item) => {
          'kategori': '🌿 Doğal yöntem',
          'baslik': item['baslik'] ?? '',
          'aciklama': item['aciklama'] ?? '',
        },
      ),
      ...EncyclopediaExtensions.traditionalKnowledge.map(
        (item) => {
          'kategori': '👴 Anadolu bilgeliği',
          'baslik': item['baslik'] ?? '',
          'aciklama': item['aciklama'] ?? '',
        },
      ),
    ];

    if (tips.isEmpty) return const SizedBox.shrink();

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.tips_and_updates_rounded, color: Colors.teal),
                SizedBox(width: 6),
                Text('Çiftçi İpuçları',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Toprak, doğal yöntem ve Anadolu bilgeliğinden seçme notlar.',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 10),
            ...tips.map((t) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.teal.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.teal.shade100),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${t['kategori']}  •  ${t['baslik']}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.teal.shade900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          t['aciklama'] ?? '',
                          style: const TextStyle(fontSize: 12, height: 1.35),
                        ),
                      ],
                    ),
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _companionRow(IconData icon, String label, String text, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 6),
        Text('$label ',
            style: TextStyle(
                fontWeight: FontWeight.bold, fontSize: 13, color: color)),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────
  // Sıfırdan Hasada Yolculuk + Hasat Tarihi Kestirimi
  //
  // Çiftçi "tarih değişir mi" değil "ne olursa ne kadar değişir" ister.
  // Bu kart ekimden hasada tüm aşamaları tarihli timeline olarak gösterir,
  // altında mevcut hava + sulama koşullarının hasadı hangi yönde kaydıracağını
  // somut gün sayılarıyla açıklar.
  // ─────────────────────────────────────────────────────────────────────
  Widget _buildHarvestJourneyCard({
    required Map<String, dynamic> crop,
    required List forecast,
    required double avgTemp,
    required double idealTempMin,
    required double idealTempMax,
  }) {
    final baseHarvestDays = (crop['harvest_days'] as num?)?.toInt() ?? 90;
    // Timeline ve kestirim: plantedDate bilinmiyorsa bugünü referans alıyoruz;
    // çiftçi tarihleri "X gün sonra" formatında okuyabilir.
    final plantedDate = DateTime.now();

    final timeline = HarvestShiftEstimator.timelineFor(
      cropName: _currentCrop,
      plantedDate: plantedDate,
    );

    // Haftalık yağış toplamı — 7 günlük forecast'ten.
    double? weeklyRain;
    if (forecast.isNotEmpty) {
      double sum = 0;
      int counted = 0;
      for (final d in forecast.take(7)) {
        if (d is Map) {
          final r = (d['rain'] as num?)?.toDouble() ?? 0;
          sum += r;
          counted++;
        }
      }
      if (counted > 0) weeklyRain = sum;
    }

    final idealMid = (idealTempMin + idealTempMax) / 2.0;
    final estimate = HarvestShiftEstimator.estimate(
      baseHarvestDays: baseHarvestDays,
      plantedDate: plantedDate,
      weeklyRainMm: weeklyRain,
      avgTempC: avgTemp,
      idealTempC: idealMid,
      cropName: _currentCrop,
    );

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.timeline_rounded, color: Colors.teal),
                SizedBox(width: 6),
                Expanded(
                  child: Text('Bitkin nasıl büyüyecek?',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Ekim gününden hasada kadar her aşamanın ne zaman geleceğini '
              'gösteren takvim. Ekim yaptığın gün bu plan otomatik başlar.',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
            ),
            const SizedBox(height: 10),

            // Timeline
            if (timeline.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'Bu bitki için adım adım protokol bulunmuyor.',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                ),
              )
            else
              ...timeline
                  .map((step) => _buildTimelineRow(step, baseHarvestDays)),

            const SizedBox(height: 10),
            const Divider(height: 1),
            const SizedBox(height: 10),

            // Hasat kestirimi
            Row(
              children: [
                Icon(Icons.event_available, color: Colors.green.shade700),
                const SizedBox(width: 6),
                const Expanded(
                  child: Text('Hasat Tarihi Kestirimi',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _buildHarvestEstimateBlock(estimate, baseHarvestDays),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineRow(HarvestTimelineStep step, int totalDays) {
    final isLast = step.dayOffset >= totalDays - 1;
    final dayLabel =
        step.dayOffset == 0 ? 'Ekim günü' : '${step.dayOffset}. gün';
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.teal.shade50,
                  border: Border.all(color: Colors.teal.shade200),
                ),
                child: Text(step.emoji, style: const TextStyle(fontSize: 16)),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 2),
                    color: Colors.teal.shade100,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${step.order}. ${step.title}',
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w700),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.teal.shade50,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          dayLabel,
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.teal.shade800),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    step.description,
                    style: const TextStyle(fontSize: 12, height: 1.3),
                  ),
                  if (step.criticalWarning != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.warning_amber_rounded,
                            size: 14, color: Colors.red.shade700),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            step.criticalWarning!,
                            style: TextStyle(
                                fontSize: 11, color: Colors.red.shade800),
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (step.farmerTip != null) ...[
                    const SizedBox(height: 2),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.lightbulb_outline,
                            size: 14, color: Colors.amber.shade800),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            step.farmerTip!,
                            style: TextStyle(
                                fontSize: 11, color: Colors.amber.shade900),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHarvestEstimateBlock(
      HarvestShiftEstimate estimate, int baseHarvestDays) {
    final base = estimate.baseHarvestDate;
    final est = estimate.estimatedHarvestDate;
    final shift = estimate.daysShift;
    Color accent;
    IconData icon;
    String shiftLabel;
    if (shift == 0) {
      accent = Colors.green.shade700;
      icon = Icons.check_circle;
      shiftLabel = 'Değişiklik yok';
    } else if (shift > 0) {
      accent = Colors.orange.shade800;
      icon = Icons.schedule;
      shiftLabel = '+$shift gün (gecikme)';
    } else {
      accent = Colors.blue.shade800;
      icon = Icons.bolt;
      shiftLabel = '$shift gün (erken)';
    }

    String fmt(DateTime d) =>
        '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: accent.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: 18, color: accent),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      shiftLabel,
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: accent),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Baz hasat: ${fmt(base)}  ($baseHarvestDays gün)',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade800),
              ),
              Text(
                'Tahmini hasat: ${fmt(est)}',
                style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600, color: accent),
              ),
              const SizedBox(height: 6),
              Text(
                estimate.summary,
                style: const TextStyle(fontSize: 12, height: 1.35),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        if (estimate.factors.isNotEmpty)
          ...estimate.factors.map((f) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(f.icon, style: const TextStyle(fontSize: 16)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            f.label,
                            style: const TextStyle(
                                fontSize: 12, fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            f.detail,
                            style: const TextStyle(fontSize: 11, height: 1.3),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )),
        const SizedBox(height: 4),
        Text(
          'Not: Kestirim mevcut haftalık hava tahmini ve sıcaklığa göredir. '
          'Sulamayı planına göre yaparsan gecikme etkisi azalır; ihmal edersen büyür.',
          style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade700,
              fontStyle: FontStyle.italic),
        ),
      ],
    );
  }
}
