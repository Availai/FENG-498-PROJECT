import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geocoding/geocoding.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import '../services/app_providers.dart';
import '../services/notification_service.dart';
import '../services/frost_alarm_service.dart';
import '../services/weather_soil_service.dart';
import '../theme/app_theme.dart';
import '../utils/location_utils.dart';
import '../widgets/animated_route.dart';
import '../widgets/floating_toast.dart';
import '../widgets/tap_scale.dart';
import 'farm_journal_screen.dart';
import 'field_detail_screen.dart';
import 'sensor_data_screen.dart';

class AgriDashboard extends ConsumerStatefulWidget {
  const AgriDashboard({super.key});

  @override
  ConsumerState<AgriDashboard> createState() => _AgriDashboardState();
}

class _AgriDashboardState extends ConsumerState<AgriDashboard>
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

      final cond = await const WeatherSoilService().fetchDashboardConditions(
        latitude: pos.latitude,
        longitude: pos.longitude,
      );

      if (mounted) {
        setState(() {
          _location = detailedAddress;
          _temp = cond.temperatureC != null ? '${cond.temperatureC!.round()}' : '--';
          _humidity = cond.humidity != null ? '${cond.humidity}' : '--';
          _wind = cond.windSpeedMs != null
              ? cond.windSpeedMs!.toStringAsFixed(1)
              : '--';
          final desc = cond.weatherDescriptionTr;
          _weatherDesc = desc.isNotEmpty
              ? desc[0].toUpperCase() + desc.substring(1)
              : '';
          _weatherCondition = _mapWeatherCondition(desc);
          _ph = cond.phH2O.toStringAsFixed(1);
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

  // Drift / Hive stats
  int get _fieldCount =>
      ref.watch(fieldMapsProvider).asData?.value.length ?? 0;
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
                      _buildSectionHeader(
                          'Bugün Yapılacaklar', Icons.checklist_rtl_rounded),
                      const SizedBox(height: 12),
                      _buildTasksSummarySection(),
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
          width: 3,
          height: 24,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [AppColors.emeraldLight, AppColors.emeraldDark],
            ),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            gradient: AppGradients.emeraldCard,
            borderRadius: BorderRadius.circular(10),
            boxShadow: AppShadows.emeraldGlow,
          ),
          child: Icon(icon, size: 17, color: Colors.white),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            letterSpacing: 0.3,
            shadows: [
              Shadow(color: Color(0x66000000), blurRadius: 4, offset: Offset(0, 1)),
            ],
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
    final fieldsAsync = ref.watch(fieldMapsProvider);
    final fields = fieldsAsync.asData?.value ?? const <Map<String, dynamic>>[];

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

  // ───────────────────────────────────────────────────────────────────────────
  // GÜNLÜK YÖNERGE ÖZETİ — tüm tarlaların acil işlerini tek bakışta gösterir
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildTasksSummarySection() {
    final fieldsAsync = ref.watch(fieldMapsProvider);
    final fields = fieldsAsync.asData?.value ?? const <Map<String, dynamic>>[];
    if (fields.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.md,
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Icon(Icons.check_circle_outline_rounded,
                color: AppColors.emerald, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Tarla eklendiğinde günlük yönergeler burada listelenecek.',
                style: AppText.body(context),
              ),
            ),
          ],
        ),
      );
    }
    return Column(
      children: [
        for (final f in fields)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _FieldDirectivesStrip(field: f),
          ),
      ],
    );
  }
}

/// Tek tarla için 1-3 acil/yaklaşan yönergeyi özetler. Bastıkça tarla
/// detayına gider — oradaki Görevler butonu tüm yönergeleri + CTA'ları açar.
class _FieldDirectivesStrip extends ConsumerWidget {
  const _FieldDirectivesStrip({required this.field});

  final Map<String, dynamic> field;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fieldId = field['id']?.toString() ?? '';
    final name = field['name']?.toString() ?? 'Tarla';
    if (fieldId.isEmpty) return const SizedBox.shrink();

    final dirAsync = ref.watch(fieldDirectivesSummaryProvider(fieldId));
    return dirAsync.when(
      loading: () => _shell(context, name, [
        _miniRow(AppColors.textTertiary, Icons.hourglass_top_rounded,
            'Hesaplanıyor...', null),
      ]),
      error: (_, __) => _shell(context, name, [
        _miniRow(AppColors.error, Icons.error_outline_rounded,
            'Yönerge hesaplanamadı', null),
      ]),
      data: (directives) {
        // urgency >= 1 olanlardan en fazla 3 tanesini göster
        final top = directives
            .where((d) => d.urgency >= 1)
            .take(3)
            .toList();

        if (top.isEmpty) {
          return _shell(context, name, [
            _miniRow(AppColors.emerald, Icons.check_circle_outline_rounded,
                'Bugün yapılacak bir şey yok', null),
          ]);
        }
        return _shell(
          context,
          name,
          top.map((d) {
            final color = d.urgency == 2
                ? const Color(0xFFFF5252)
                : const Color(0xFFFFB74D);
            final icon = _iconFor(d.kind);
            return _miniRow(color, icon, d.headline, d.urgency == 2 ? 'BUGÜN' : null);
          }).toList(),
        );
      },
    );
  }

  static IconData _iconFor(String kind) {
    switch (kind) {
      case 'water_now':
      case 'water_soon':
        return Icons.water_drop_rounded;
      case 'fertilize':
        return Icons.grass_rounded;
      case 'spray':
        return Icons.science_rounded;
      case 'harvest':
        return Icons.agriculture_rounded;
      case 'frost':
        return Icons.ac_unit_rounded;
      case 'heat':
        return Icons.wb_sunny_rounded;
      default:
        return Icons.flag_rounded;
    }
  }

  Widget _shell(BuildContext context, String fieldName, List<Widget> rows) {
    return TapScale(
      scale: 0.97,
      onTap: () {
        Navigator.of(context).push(
          AnimatedRoute.scaleFade(FieldDetailScreen(fieldData: field)),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.md,
          border: Border.all(color: AppColors.border),
          boxShadow: AppShadows.sm,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.grass_rounded,
                    size: 16, color: AppColors.emeraldDark),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    fieldName,
                    style: AppText.h3(context),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(Icons.chevron_right_rounded,
                    color: AppColors.textTertiary, size: 20),
              ],
            ),
            const SizedBox(height: 8),
            ...rows,
          ],
        ),
      ),
    );
  }

  Widget _miniRow(Color color, IconData icon, String text, String? badge) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (badge != null) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                badge,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: color,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
