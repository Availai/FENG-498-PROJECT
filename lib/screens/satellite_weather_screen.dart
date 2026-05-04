import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/app_providers.dart';
import '../widgets/help_panel.dart';

class SatelliteWeatherScreen extends ConsumerStatefulWidget {
  final dynamic fieldData;
  const SatelliteWeatherScreen({super.key, required this.fieldData});

  @override
  ConsumerState<SatelliteWeatherScreen> createState() =>
      _SatelliteWeatherScreenState();
}

class _SatelliteWeatherScreenState
    extends ConsumerState<SatelliteWeatherScreen> {
  Map<String, dynamic>? _data;
  bool _isLoading = true;
  String? _error;
  bool _isStaleData = false;
  DateTime? _lastUpdated;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final d = widget.fieldData;
      final result =
          await ref.read(weatherRepositoryProvider).getSatelliteWeather(
                latitude: (d['latitude'] as num).toDouble(),
                longitude: (d['longitude'] as num).toDouble(),
              );
      if (mounted) {
        setState(() {
          _data = result.data;
          _isStaleData = result.isStale;
          _lastUpdated = result.lastUpdated;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Uydu verisi alınamadı: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final fieldName = widget.fieldData['name'] ?? 'Tarla';
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1321),
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Row(children: [
          const Icon(Icons.satellite_alt, color: Color(0xFF4FC3F7), size: 22),
          const SizedBox(width: 8),
          Expanded(
            child: Text(fieldName,
                style: const TextStyle(fontSize: 17),
                overflow: TextOverflow.ellipsis),
          ),
        ]),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF4FC3F7)),
            onPressed: _load,
            tooltip: 'Yenile',
          ),
          IconButton(
            icon: const Icon(Icons.help_outline_rounded, color: Colors.white),
            tooltip: 'Yardım',
            onPressed: () =>
                HelpPanel.show(context, HelpContent.satelliteWeather),
          ),
        ],
      ),
      body: _isLoading
          ? _buildLoading()
          : _error != null
              ? _buildError()
              : _buildContent(),
    );
  }

  Widget _buildLoading() {
    return const Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        CircularProgressIndicator(color: Color(0xFF4FC3F7)),
        SizedBox(height: 20),
        Text('Uydu verileri alınıyor...',
            style: TextStyle(color: Colors.white70, fontSize: 15)),
        SizedBox(height: 6),
        Text('NASA POWER • Open-Meteo ERA5',
            style: TextStyle(color: Color(0xFF4FC3F7), fontSize: 12)),
      ]),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.satellite_alt, size: 60, color: Colors.red),
          const SizedBox(height: 16),
          Text(_error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _load,
            icon: const Icon(Icons.refresh),
            label: const Text('Tekrar Dene'),
          ),
        ]),
      ),
    );
  }

  Widget _buildContent() {
    final d = _data!;
    final List forecast = d['daily_forecast'] as List;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        // ── KAYNAK ROZET ──
        Row(children: [
          _sourceBadge('NASA POWER', Colors.orange),
          const SizedBox(width: 8),
          _sourceBadge('Open-Meteo ERA5', Colors.blue),
          const SizedBox(width: 8),
          _sourceBadge('Agromonitoring', Colors.green),
        ]),
        const SizedBox(height: 16),

        if (_isStaleData)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3CD),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFFE69C)),
            ),
            child: Row(
              children: [
                const Icon(Icons.wifi_off_rounded,
                    color: Color(0xFF7A5D00), size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _lastUpdated == null
                        ? 'Çevrimdışı mod: Son başarılı hava verisi gösteriliyor.'
                        : 'Çevrimdışı mod: Son başarılı veri ${_formatUpdatedAt(_lastUpdated!)} tarihinde alındı.',
                    style: const TextStyle(
                        color: Color(0xFF7A5D00), fontSize: 12.5),
                  ),
                ),
              ],
            ),
          ),

        if (_isStaleData) const SizedBox(height: 12),

        // ── ANLIK HAVA (Open-Meteo ERA5) ──
        _sectionTitle('Anlık Hava Durumu', Icons.wb_sunny_outlined),
        const SizedBox(height: 8),
        _currentWeatherCard(d),

        const SizedBox(height: 16),

        // ── NASA UYDU VERİSİ ──
        if (d['nasa_success'] == true) ...[
          _sectionTitle('NASA Uydu Atmosfer Verisi (${d['nasa_date']})',
              Icons.rocket_launch_outlined),
          const SizedBox(height: 8),
          _nasaCard(d),
          const SizedBox(height: 16),
        ],

        // ── UYDU TOPRAK NEMİ ──
        if ((d['soil_moisture'] as double) > 0) ...[
          _sectionTitle('Uydu Toprak Analizi', Icons.grass),
          const SizedBox(height: 8),
          _soilCard(d),
          const SizedBox(height: 16),
        ],

        // ── SAATLİK TAHMİN ──
        if ((d['hourly_forecast'] as List).isNotEmpty) ...[
          _sectionTitle('Saatlik Tahmin (sonraki 24 saat)', Icons.access_time),
          const SizedBox(height: 8),
          SizedBox(
            height: 120,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: (d['hourly_forecast'] as List).length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) => _hourlyCard(
                  (d['hourly_forecast'] as List)[i] as Map<String, dynamic>),
            ),
          ),
          const SizedBox(height: 16),
        ],

        // ── 7 GÜNLÜK TAHMİN + UV ──
        _sectionTitle('7 Günlük Tahmin (UV dahil)', Icons.calendar_month),
        const SizedBox(height: 8),
        SizedBox(
          height: 150,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: forecast.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) =>
                _dayCard(forecast[i] as Map<String, dynamic>),
          ),
        ),

        const SizedBox(height: 16),

        // ── UV İNDEKSİ AÇIKLAMASI ──
        _uvGuideCard(forecast),

        const SizedBox(height: 16),

        // ── KAYNAK AÇIKLAMASI ──
        _sourceInfoCard(),

        const SizedBox(height: 24),
      ]),
    );
  }

  String _formatUpdatedAt(DateTime dt) {
    final local = dt.toLocal();
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(local.day)}.${two(local.month)}.${local.year} ${two(local.hour)}:${two(local.minute)}';
  }

  Widget _sectionTitle(String title, IconData icon) {
    return Row(children: [
      Icon(icon, color: const Color(0xFF4FC3F7), size: 20),
      const SizedBox(width: 8),
      Text(title,
          style: const TextStyle(
              color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
    ]);
  }

  Widget _sourceBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.satellite_alt, size: 12, color: color),
        const SizedBox(width: 4),
        Text(label,
            style: TextStyle(
                color: color, fontSize: 11, fontWeight: FontWeight.bold)),
      ]),
    );
  }

  Widget _currentWeatherCard(Map<String, dynamic> d) {
    final code = d['weather_code'] as int;
    final desc = _wmoDescription(code);
    final icon = _wmoIcon(code);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2035),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2A3550)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, color: Colors.amber, size: 40),
          const SizedBox(width: 16),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${d['current_temp'].toStringAsFixed(1)}°C',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 34,
                    fontWeight: FontWeight.bold)),
            Text(desc, style: const TextStyle(color: Colors.white70)),
          ]),
        ]),
        const SizedBox(height: 16),
        Row(children: [
          _miniStat(
              Icons.water_drop,
              '%${(d['current_humidity'] as double).toStringAsFixed(0)}',
              'Nem',
              Colors.blue),
          _miniStat(
              Icons.air,
              '${(d['current_wind'] as double).toStringAsFixed(1)} km/h',
              'Rüzgar',
              Colors.cyan),
          _miniStat(
              Icons.cloud,
              '%${(d['current_cloud_cover'] as double).toStringAsFixed(0)}',
              'Bulut',
              Colors.grey),
          _miniStat(
              Icons.compress,
              '${(d['current_pressure'] as double).toStringAsFixed(0)} hPa',
              'Basınç',
              Colors.purple),
        ]),
        if ((d['current_precip'] as double) > 0)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Row(children: [
              const Icon(Icons.umbrella, color: Colors.lightBlue, size: 16),
              const SizedBox(width: 6),
              Text(
                  'Anlık yağış: ${(d['current_precip'] as double).toStringAsFixed(1)} mm',
                  style:
                      const TextStyle(color: Colors.lightBlue, fontSize: 13)),
            ]),
          ),
      ]),
    );
  }

  Widget _nasaCard(Map<String, dynamic> d) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.deepOrange.shade900.withValues(alpha: 0.8),
            const Color(0xFF1A2035),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.deepOrange.withValues(alpha: 0.3)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Row(children: [
          Icon(Icons.wb_sunny, color: Colors.orange, size: 20),
          SizedBox(width: 8),
          Text('Güneş Radyasyonu (Uydu Ölçümü)',
              style: TextStyle(
                  color: Colors.orange,
                  fontWeight: FontWeight.bold,
                  fontSize: 14)),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(
            child: _nasaStat(
                '${(d['nasa_solar'] as double).toStringAsFixed(1)} MJ/m²',
                'Güneş Radyasyonu',
                Colors.orange,
                Icons.wb_sunny),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _nasaStat(
                '${(d['nasa_temp'] as double).toStringAsFixed(1)}°C',
                'Ort. Sıcaklık',
                Colors.amber,
                Icons.thermostat),
          ),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(
            child: _nasaStat(
                '%${(d['nasa_humidity'] as double).toStringAsFixed(0)}',
                'Bağıl Nem',
                Colors.blue,
                Icons.water_drop),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _nasaStat(
                '${(d['nasa_wind'] as double).toStringAsFixed(1)} m/s',
                'Rüzgar Hızı',
                Colors.cyan,
                Icons.air),
          ),
        ]),
        if ((d['nasa_precip'] as double) > 0) ...[
          const SizedBox(height: 10),
          _nasaStat('${(d['nasa_precip'] as double).toStringAsFixed(2)} mm',
              'Düzeltilmiş Yağış', Colors.lightBlue, Icons.grain),
        ],
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.orange.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Text(
            '🛸 Veriler NASA POWER uydu ve yeniden analiz sisteminden alınmaktadır. '
            'CERES uydu radyometre ölçümleri + MERRA-2 atmosfer modeli.',
            style: TextStyle(color: Colors.orange, fontSize: 11, height: 1.4),
          ),
        ),
      ]),
    );
  }

  Widget _soilCard(Map<String, dynamic> d) {
    final moisture = (d['soil_moisture'] as double) * 100;
    final soilTemp = d['soil_temp_c'] as double;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2035),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
      ),
      child: Row(children: [
        Expanded(
            child: _nasaStat('%${moisture.toStringAsFixed(1)}', 'Toprak Nemi',
                Colors.green, Icons.water_drop)),
        const SizedBox(width: 10),
        Expanded(
            child: _nasaStat('${soilTemp.toStringAsFixed(1)}°C',
                'Toprak Sıcaklığı', Colors.deepOrange, Icons.thermostat)),
      ]),
    );
  }

  Widget _dayCard(Map<String, dynamic> day) {
    final date = (day['date'] as String).substring(5); // MM-DD
    final max = (day['max'] as double).toStringAsFixed(0);
    final min = (day['min'] as double).toStringAsFixed(0);
    final rain = (day['rain'] as double);
    final uv = (day['uv'] as double);
    final Color uvColor = uv >= 8
        ? Colors.red
        : uv >= 6
            ? Colors.orange
            : uv >= 3
                ? Colors.yellow
                : Colors.green;
    final hasRain = rain > 1;
    return Container(
      width: 90,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: hasRain ? const Color(0xFF0D1B2A) : const Color(0xFF1A2035),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: hasRain
                ? Colors.blue.withValues(alpha: 0.4)
                : const Color(0xFF2A3550)),
      ),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text(date,
            style: const TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.bold,
                fontSize: 12)),
        const SizedBox(height: 6),
        Icon(
          hasRain ? Icons.umbrella : Icons.wb_sunny,
          color: hasRain ? Colors.lightBlue : Colors.amber,
          size: 22,
        ),
        const SizedBox(height: 6),
        Text('$max° / $min°',
            style: const TextStyle(color: Colors.white, fontSize: 12)),
        if (rain > 0)
          Text('${rain.toStringAsFixed(1)} mm',
              style: const TextStyle(color: Colors.lightBlue, fontSize: 10)),
        const SizedBox(height: 4),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.wb_sunny_outlined, size: 10, color: uvColor),
          const SizedBox(width: 2),
          Text('UV ${uv.toStringAsFixed(0)}',
              style: TextStyle(color: uvColor, fontSize: 10)),
        ]),
      ]),
    );
  }

  Widget _hourlyCard(Map<String, dynamic> h) {
    final time = h['time'] as String;
    final hour = time.length >= 16 ? time.substring(11, 16) : '??:??';
    final temp = (h['temp'] as double).toStringAsFixed(0);
    final prob = h['precip_prob'] as int;
    final code = h['code'] as int;
    final wind = (h['wind'] as double).toStringAsFixed(0);
    final hum = h['humidity'] as int;
    final isRain = code >= 51 || prob >= 40;
    return Container(
      width: 72,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: isRain ? const Color(0xFF0D1B2A) : const Color(0xFF1A2035),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: isRain
                ? Colors.blue.withValues(alpha: 0.4)
                : const Color(0xFF2A3550)),
      ),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text(hour,
            style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.white70)),
        const SizedBox(height: 4),
        Icon(isRain ? Icons.umbrella : Icons.wb_sunny,
            size: 18, color: isRain ? Colors.lightBlue : Colors.amber),
        const SizedBox(height: 4),
        Text('$temp°',
            style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.bold)),
        Text('$wind km/h',
            style: const TextStyle(color: Colors.white38, fontSize: 10)),
        Text('%$hum',
            style: const TextStyle(color: Color(0xFF4FC3F7), fontSize: 10)),
        if (prob > 0)
          Text('🌧$prob%',
              style: const TextStyle(color: Colors.lightBlue, fontSize: 10)),
      ]),
    );
  }

  Widget _uvGuideCard(List forecast) {
    double maxUv = 0;
    for (final day in forecast) {
      final uv = (day['uv'] as double);
      if (uv > maxUv) maxUv = uv;
    }
    final String uvTip;
    final Color uvColor;
    if (maxUv >= 11) {
      uvTip =
          'Tehlikeli (${maxUv.toStringAsFixed(0)}): Tarla çalışması sabah erken / akşam üstü yapılmalı. Güneş koruyucu zorunlu.';
      uvColor = Colors.purple;
    } else if (maxUv >= 8) {
      uvTip =
          'Çok Yüksek (${maxUv.toStringAsFixed(0)}): Öğleden sonra tarla çalışmasından kaçının. Gölge ve bol su önemli.';
      uvColor = Colors.red;
    } else if (maxUv >= 6) {
      uvTip =
          'Yüksek (${maxUv.toStringAsFixed(0)}): Şapka ve uzun kollu giysi ile çalışın.';
      uvColor = Colors.orange;
    } else if (maxUv >= 3) {
      uvTip = 'Orta (${maxUv.toStringAsFixed(0)}): Normal önlemler yeterli.';
      uvColor = Colors.yellow;
    } else {
      uvTip =
          'Düşük (${maxUv.toStringAsFixed(0)}): Tarla çalışması için güvenli koşullar.';
      uvColor = Colors.green;
    }
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: uvColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: uvColor.withValues(alpha: 0.3)),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(Icons.wb_sunny, color: uvColor, size: 22),
        const SizedBox(width: 10),
        Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('UV İndeksi Haftanın Zirvesi',
                style: TextStyle(
                    color: uvColor, fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 4),
            Text(uvTip,
                style: const TextStyle(
                    color: Colors.white70, fontSize: 13, height: 1.4)),
          ]),
        ),
      ]),
    );
  }

  Widget _sourceInfoCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1729),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF2A3550)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Veri Kaynakları',
            style: TextStyle(
                color: Colors.white54,
                fontSize: 12,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        _sourceRow('🛰️ NASA POWER',
            'CERES uydu ölçümleri + MERRA-2 atmosfer yeniden analizi. Güneş radyasyonu, sıcaklık, nem, rüzgar.'),
        const SizedBox(height: 6),
        _sourceRow('🌍 Open-Meteo ERA5',
            'ECMWF/Copernicus ERA5 uydu reanaliz verisi. Anlık hava, tahmin, UV indeksi.'),
        const SizedBox(height: 6),
        _sourceRow('🌱 Agromonitoring',
            'Uydu destekli toprak nemi ve sıcaklığı (0–10 cm derinlik).'),
      ]),
    );
  }

  Widget _sourceRow(String title, String desc) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SizedBox(
        width: 120,
        child: Text(title,
            style: const TextStyle(
                color: Color(0xFF4FC3F7),
                fontSize: 11,
                fontWeight: FontWeight.w600)),
      ),
      Expanded(
        child: Text(desc,
            style: const TextStyle(
                color: Colors.white38, fontSize: 11, height: 1.4)),
      ),
    ]);
  }

  Widget _miniStat(IconData icon, String value, String label, Color c) {
    return Expanded(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: c, size: 18),
        const SizedBox(height: 4),
        Text(value,
            style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold)),
        Text(label,
            style: const TextStyle(color: Colors.white38, fontSize: 10)),
      ]),
    );
  }

  Widget _nasaStat(String value, String label, Color c, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: c.withValues(alpha: 0.2)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, color: c, size: 16),
          const SizedBox(width: 6),
          Text(label,
              style: TextStyle(color: c.withValues(alpha: 0.8), fontSize: 11)),
        ]),
        const SizedBox(height: 4),
        Text(value,
            style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold)),
      ]),
    );
  }

  // WMO weather code → Türkçe açıklama
  String _wmoDescription(int code) {
    if (code == 0) return 'Açık hava';
    if (code <= 3) return 'Parçalı bulutlu';
    if (code <= 49) return 'Sisli';
    if (code <= 69) return 'Yağmurlu';
    if (code <= 79) return 'Karlı';
    if (code <= 82) return 'Sağanak yağış';
    if (code <= 94) return 'Dolu';
    return 'Gök gürültülü fırtına';
  }

  // WMO weather code → ikon
  IconData _wmoIcon(int code) {
    if (code == 0) return Icons.wb_sunny;
    if (code <= 3) return Icons.cloud;
    if (code <= 49) return Icons.foggy;
    if (code <= 69) return Icons.umbrella;
    if (code <= 79) return Icons.ac_unit;
    if (code <= 82) return Icons.grain;
    return Icons.thunderstorm;
  }
}
