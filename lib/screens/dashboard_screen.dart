import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../services/notification_service.dart';
import '../services/frost_alarm_service.dart';
import '../theme/app_theme.dart';
import '../utils/location_utils.dart';
import '../widgets/animated_route.dart';
import '../widgets/floating_toast.dart';
import '../widgets/tap_scale.dart';
import 'farm_journal_screen.dart';
import 'field_detail_screen.dart';
import 'sensor_data_screen.dart';

class AgriDashboard extends StatefulWidget {
  const AgriDashboard({super.key});

  @override
  State<AgriDashboard> createState() => _AgriDashboardState();
}

class _AgriDashboardState extends State<AgriDashboard>
    with SingleTickerProviderStateMixin {
  String _temp = '--',
      _humidity = '--',
      _wind = '--',
      _ph = '--',
      _location = 'Konum aranıyor...',
      _weatherDesc = '';
  bool _isLoading = false;
  String _weatherCondition = 'sunny';

  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  static String _dashboardWmoCodeToTr(int code) {
    if (code == 0) return 'açık';
    if (code == 1) return 'az bulutlu';
    if (code == 2) return 'parçalı bulutlu';
    if (code == 3) return 'kapalı';
    if (code == 45 || code == 48) return 'sisli';
    if (code >= 51 && code <= 57) return 'çisenti';
    if (code >= 61 && code <= 67) return 'yağmurlu';
    if (code >= 71 && code <= 77) return 'karlı';
    if (code >= 80 && code <= 82) return 'sağanak';
    if (code >= 85 && code <= 86) return 'kar sağanağı';
    if (code >= 95) return 'gök gürültülü fırtına';
    return '';
  }

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _refreshData();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  // HD tarım alanı arka plan görseli — çevrimdışı öncelikli, sabit asset.

  Widget _fallbackGradient() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1B5E20), Color(0xFF4CAF50), Color(0xFFFFB300)],
        ),
      ),
    );
  }

  String _mapWeatherCondition(String description) {
    final d = description.toLowerCase();
    if (d.contains('rain') ||
        d.contains('yağmur') ||
        d.contains('drizzle') ||
        d.contains('storm') ||
        d.contains('fırtına')) { return 'rainy'; }
    if (d.contains('cloud') ||
        d.contains('bulut') ||
        d.contains('overcast') ||
        d.contains('kapalı') ||
        d.contains('fog') ||
        d.contains('sis')) { return 'cloudy'; }
    return 'sunny';
  }

  // Weather icon based on condition
  IconData get _weatherIcon {
    switch (_weatherCondition) {
      case 'rainy':
        return Icons.thunderstorm_outlined;
      case 'cloudy':
        return Icons.cloud_outlined;
      default:
        return Icons.wb_sunny_outlined;
    }
  }

  Future<void> _refreshData() async {
    setState(() => _isLoading = true);
    _animController.reset();
    try {
      await ensureLocationPermission();
      final pos = await getCurrentPosition();

      // ── Proaktif hava uyarısı: max 3 saatte 1 kez ──
      _triggerWeatherAlertIfDue(pos.latitude, pos.longitude);


      String detailedAddress = 'Adres çözümleniyor...';
      try {
        List<Placemark> placemarks =
            await placemarkFromCoordinates(pos.latitude, pos.longitude);
        if (placemarks.isNotEmpty) {
          Placemark place = placemarks.first;
          String mahalle = place.subLocality ?? place.thoroughfare ?? '';
          String ilce = place.subAdministrativeArea ?? '';
          String il = place.administrativeArea ?? '';
          detailedAddress = [mahalle, ilce, il]
              .where((s) => s.isNotEmpty)
              .join(', ');
        }
      } catch (_) {
        detailedAddress =
            '${pos.latitude.toStringAsFixed(4)}, ${pos.longitude.toStringAsFixed(4)}';
      }

      final results = await Future.wait([
        http.get(Uri.parse(
          'https://api.open-meteo.com/v1/forecast?latitude=${pos.latitude}&longitude=${pos.longitude}&current=temperature_2m,relative_humidity_2m,wind_speed_10m,weather_code&wind_speed_unit=ms&timezone=auto',
        )),
        http.get(Uri.parse(
          'https://rest.isric.org/soilgrids/v2.0/properties/query?lon=${pos.longitude}&lat=${pos.latitude}&property=phh2o&depth=0-5cm&value=mean',
        )),
      ]);

      if (mounted) {
        setState(() {
          _location = detailedAddress;
          if (results[0].statusCode == 200) {
            final cur = jsonDecode(results[0].body)['current'];
            final t = (cur['temperature_2m'] as num?)?.toDouble();
            _temp = t != null ? '${t.round()}' : '--';
            _humidity = '${(cur['relative_humidity_2m'] as num?)?.round() ?? '--'}';
            final w = (cur['wind_speed_10m'] as num?)?.toDouble();
            _wind = w != null ? w.toStringAsFixed(1) : '--';
            final desc = _dashboardWmoCodeToTr(
                (cur['weather_code'] as num?)?.toInt() ?? 0);
            _weatherDesc = desc.isNotEmpty
                ? desc[0].toUpperCase() + desc.substring(1)
                : '';
            _weatherCondition = _mapWeatherCondition(desc);
          }

          if (results[1].statusCode == 200) {
            final data = jsonDecode(results[1].body);
            final val = data['properties']?['layers']?[0]?['depths']?[0]
                ?['values']?['mean'];
            _ph = val != null
                ? (val / 10.0).toStringAsFixed(1)
                : '6.8';
          } else {
            _ph = '6.8';
          }
        });
        _animController.forward();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _location = 'Konum veya internet hatası';
          _temp = '--';
          _humidity = '--';
          _ph = '--';
        });
        _animController.forward();
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Proaktif hava uyarısını tetikler — max 3 saatte 1 kez.
  /// Fire-and-forget: sonucu beklemeyiz, UI'ı bloklamaz.
  void _triggerWeatherAlertIfDue(double lat, double lng) {
    final settingsBox = Hive.box('settingsBox');
    final lastCheckStr = settingsBox.get('last_weather_check_at') as String?;
    final lastCheck = lastCheckStr != null
        ? DateTime.tryParse(lastCheckStr)
        : null;
    final now = DateTime.now().toUtc();

    // Son kontrolden 3 saatten az geçmişse atla
    if (lastCheck != null &&
        now.difference(lastCheck).inHours < 3) {
      return;
    }

    // Fire-and-forget — arka planda çalışır, hata sessizce yutulur
    () async {
      try {
        await NotificationService.checkWeatherAndAlert(lat, lng);
        await FrostAlarmService.checkAndNotify(lat: lat, lon: lng);
        await settingsBox.put(
          'last_weather_check_at',
          now.toIso8601String(),
        );
      } catch (_) {
        // Bildirim hatası uygulamayı etkilememeli
      }
    }();
  }

  // Hive stats
  int get _fieldCount => Hive.box('user_crops').length;
  int get _analysisCount => Hive.box('agri_history').length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/dashboard_bg.png',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _fallbackGradient(),
            ),
          ),
          Positioned.fill(
            child: Container(color: Colors.black.withValues(alpha: 0.45)),
          ),
          RefreshIndicator(
            onRefresh: _refreshData,
            color: Colors.green,
            child: CustomScrollView(
              slivers: [
                _buildHeroSliverAppBar(),
            SliverToBoxAdapter(
              child: FadeTransition(
                opacity: _fadeAnim,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 120),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionHeader('Hava Durumu', Icons.wb_sunny),
                      const SizedBox(height: 12),
                      _buildWeatherGrid(),
                      const SizedBox(height: 24),
                      _buildSectionHeader('Tarlalarım', Icons.grass_rounded),
                      const SizedBox(height: 12),
                      _buildMyFieldsSection(),
                      const SizedBox(height: 24),
                      _buildSectionHeader('Tarla İstatistikleri', Icons.bar_chart),
                      const SizedBox(height: 12),
                      _buildStatsRow(),
                      const SizedBox(height: 24),
                      _buildSectionHeader('Toprak Analizi', Icons.terrain),
                      const SizedBox(height: 12),
                      _buildSoilCard(),
                      const SizedBox(height: 24),
                      _buildSensorButton(),
                      const SizedBox(height: 12),
                      _buildJournalButton(),
                      const SizedBox(height: 12),
                      _buildArchiveButton(),
                    ],
                  ),
                ),
              ),
            ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 260,
      pinned: true,
      stretch: true,
      backgroundColor: const Color(0xFF1B5E20),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh_rounded, color: Colors.white),
          onPressed: _refreshData,
        ),
        const SizedBox(width: 8),
      ],
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [StretchMode.zoomBackground, StretchMode.blurBackground],
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Gradient overlay (dashboard HD bg lives behind Scaffold body)
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0x22000000),
                    Color(0x88000000),
                  ],
                ),
              ),
            ),
            // Hero weather content
            if (!_isLoading)
              Positioned(
                bottom: 24,
                left: 20,
                right: 20,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Icon(_weatherIcon, color: Colors.white70, size: 36),
                        const SizedBox(width: 12),
                        Text(
                          _temp != '--' ? '$_temp°C' : '--',
                          style: const TextStyle(
                            fontSize: 56,
                            fontWeight: FontWeight.w200,
                            color: Colors.white,
                            height: 1.0,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    if (_weatherDesc.isNotEmpty)
                      Text(
                        _weatherDesc,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.white70,
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined,
                            color: Colors.white54, size: 14),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            _location,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.white54,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            if (_isLoading)
              const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: Colors.green.shade700),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.grey.shade800,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }

  Widget _buildWeatherGrid() {
    return Row(
      children: [
        Expanded(
          child: _buildMetricCard(
            icon: Icons.thermostat_rounded,
            label: 'Sıcaklık',
            value: _temp != '--' ? '$_temp°C' : '--',
            unit: '',
            gradientColors: [const Color(0xFFFF7043), const Color(0xFFE64A19)],
            iconBg: const Color(0xFFFFCDD2),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildMetricCard(
            icon: Icons.water_drop_rounded,
            label: 'Nem',
            value: _humidity,
            unit: '%',
            gradientColors: [const Color(0xFF29B6F6), const Color(0xFF0277BD)],
            iconBg: const Color(0xFFB3E5FC),
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required IconData icon,
    required String label,
    required String value,
    required String unit,
    required List<Color> gradientColors,
    required Color iconBg,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: gradientColors.last.withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(height: 16),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          RichText(
            text: TextSpan(
              text: value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w700,
                height: 1.1,
              ),
              children: unit.isNotEmpty
                  ? [
                      TextSpan(
                        text: unit,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
                      ),
                    ]
                  : [],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            icon: Icons.crop_square_rounded,
            label: 'Kayıtlı Tarla',
            value: '$_fieldCount',
            color: Colors.green.shade700,
            bg: Colors.green.shade50,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            icon: Icons.history_rounded,
            label: 'Arşiv Kaydı',
            value: '$_analysisCount',
            color: Colors.purple.shade700,
            bg: Colors.purple.shade50,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            icon: Icons.air_rounded,
            label: 'Rüzgar',
            value: _wind != '--' ? '$_wind m/s' : '--',
            color: Colors.blueGrey.shade700,
            bg: Colors.blueGrey.shade50,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required Color bg,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey.shade500,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSoilCard() {
    final phVal = double.tryParse(_ph.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 7.0;
    final phColor = phVal < 6.0
        ? Colors.orange.shade700
        : phVal > 7.5
            ? Colors.purple.shade700
            : Colors.green.shade700;
    final phLabel = phVal < 6.0
        ? 'Asidik'
        : phVal > 7.5
            ? 'Alkali'
            : 'Nötr (İdeal)';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.teal.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.eco_rounded, color: Colors.teal.shade700, size: 22),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Toprak pH Değeri',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        _ph,
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: phColor,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: phColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          phLabel,
                          style: TextStyle(
                            fontSize: 11,
                            color: phColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          // pH bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Container(
              height: 8,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFFFF7043),
                    Color(0xFFFFEB3B),
                    Color(0xFF4CAF50),
                    Color(0xFF29B6F6),
                    Color(0xFF7B1FA2),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Asidik (0)', style: TextStyle(fontSize: 10, color: Colors.grey.shade400)),
              Text('Nötr (7)', style: TextStyle(fontSize: 10, color: Colors.grey.shade400)),
              Text('Alkali (14)', style: TextStyle(fontSize: 10, color: Colors.grey.shade400)),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'SoilGrids ISRIC verisi · 0–5 cm derinlik',
            style: TextStyle(fontSize: 10.5, color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }


  Widget _buildSensorButton() {
    return TapScale(
      scale: 0.97,
      onTap: () {
        Navigator.of(context).push(
          AnimatedRoute.slideX(const SensorDataScreen()),
        );
      },
      child: OutlinedButton.icon(
        onPressed: () {
          Navigator.of(context).push(
            AnimatedRoute.slideX(const SensorDataScreen()),
          );
        },
        icon: const Icon(Icons.sensors_rounded),
        label: const Text('CANLI SENSÖR PANELİ'),
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
          foregroundColor: Colors.teal.shade700,
          side: BorderSide(color: Colors.teal.shade300),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }

  Widget _buildJournalButton() {
    return TapScale(
      scale: 0.97,
      onTap: () {
        Navigator.of(context).push(
          AnimatedRoute.slideX(const FarmJournalScreen()),
        );
      },
      child: OutlinedButton.icon(
        onPressed: () {
          Navigator.of(context).push(
            AnimatedRoute.slideX(const FarmJournalScreen()),
          );
        },
        icon: const Icon(Icons.event_note_rounded),
        label: const Text('TARLAM GÜNLÜĞÜ'),
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
          foregroundColor: AppColors.emeraldDark,
          side: BorderSide(color: AppColors.emerald.withValues(alpha: 0.5)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }

  Widget _buildArchiveButton() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.shade600, Colors.green.shade800],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.green.shade700.withValues(alpha: 0.4),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () async {
            final box = Hive.box('agri_history');
            await box.add({
              'date': DateFormat('dd.MM.yyyy HH:mm').format(DateTime.now()),
              'temp': _temp != '--' ? '$_temp°C' : '--',
              'ph': _ph,
              'location': _location.split('\n').first,
            });
            if (mounted) {
              AppToast.show(
                context,
                message: 'Veriler arşive kaydedildi!',
                type: ToastType.success,
              );
            }
          },
          child: const Padding(
            padding: EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.save_rounded, color: Colors.white, size: 22),
                SizedBox(width: 10),
                Text(
                  'BU ANALİZİ ARŞİVLE',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // ÇOKLU TARLA KARTLARI — Dashboard'da birden fazla tarlanın özeti tek bakışta
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildMyFieldsSection() {
    return ValueListenableBuilder<Box>(
      valueListenable: Hive.box('user_crops').listenable(),
      builder: (context, box, _) {
        final fields = <Map<String, dynamic>>[];
        for (int i = 0; i < box.length; i++) {
          final raw = box.getAt(i);
          if (raw is Map) {
            fields.add(Map<String, dynamic>.from(raw));
          }
        }

        if (fields.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: AppRadius.md,
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Icon(Icons.grass_rounded,
                    color: AppColors.emeraldLight, size: 26),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Henüz tarla eklemediniz.\nHaritadan ilk tarlanızı çizerek başlayın.',
                    style: AppText.body(context),
                  ),
                ),
              ],
            ),
          );
        }

        // Yatay kaydırılabilir liste — çiftçi tek bakışta birkaç tarlayı görür.
        return SizedBox(
          height: 168,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: fields.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (_, i) => _buildFieldCard(fields[i]),
          ),
        );
      },
    );
  }

  Widget _buildFieldCard(Map<String, dynamic> field) {
    final name = field['name']?.toString() ?? 'İsimsiz Tarla';
    final area = (field['area_dekar'] as num?)?.toDouble();
    final crops = field['planted_crops'];
    String cropLabel = '';
    if (crops is List && crops.isNotEmpty) {
      final first = crops.first;
      if (first is Map && first['name'] != null) {
        cropLabel = first['name'].toString();
      } else if (first is String) {
        cropLabel = first;
      }
    }
    cropLabel = cropLabel.isEmpty ? 'Ürün seçilmemiş' : cropLabel;

    final analysis = field['analysis'];
    final soilMoisture = analysis is Map
        ? (analysis['soil_moisture'] as num?)?.toDouble()
        : null;

    // Sağlık rozeti — toprak nemi eşiklerine göre
    Color healthColor;
    String healthLabel;
    IconData healthIcon;
    if (soilMoisture == null) {
      healthColor = AppColors.textTertiary;
      healthLabel = 'Analiz bekliyor';
      healthIcon = Icons.help_outline_rounded;
    } else if (soilMoisture < 0.25) {
      healthColor = AppColors.error;
      healthLabel = 'Sulama gerek';
      healthIcon = Icons.water_drop_outlined;
    } else if (soilMoisture < 0.45) {
      healthColor = AppColors.warning;
      healthLabel = 'Takip et';
      healthIcon = Icons.visibility_outlined;
    } else {
      healthColor = AppColors.emerald;
      healthLabel = 'Sağlıklı';
      healthIcon = Icons.check_circle_outline_rounded;
    }

    // Sıradaki sulama tahmini — basit heuristik
    final nextIrrigation = soilMoisture == null
        ? 'Önce analiz yapın'
        : soilMoisture < 0.3
            ? 'Bugün / Yarın'
            : soilMoisture < 0.5
                ? '2-3 gün içinde'
                : '4+ gün sonra';

    return TapScale(
      scale: 0.96,
      onTap: () {
        Navigator.of(context).push(
          AnimatedRoute.scaleFade(FieldDetailScreen(fieldData: field)),
        );
      },
      child: Container(
        width: 240,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.md,
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    name,
                    style: AppText.h3(context),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(healthIcon, color: healthColor, size: 20),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              area != null
                  ? '${area.toStringAsFixed(1)} dekar · $cropLabel'
                  : cropLabel,
              style: AppText.sm(context),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: healthColor.withValues(alpha: 0.12),
                borderRadius: AppRadius.full,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: healthColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    healthLabel,
                    style: AppText.xs(context).copyWith(color: healthColor),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.water_drop_rounded,
                    size: 14, color: AppColors.info),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'Sulama: $nextIrrigation',
                    style: AppText.sm(context),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
