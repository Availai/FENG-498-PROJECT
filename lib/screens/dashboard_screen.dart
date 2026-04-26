import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geocoding/geocoding.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../services/app_providers.dart';
import '../services/notification_service.dart';
import '../services/frost_alarm_service.dart';
import '../services/weather_soil_service.dart';
import '../theme/app_theme.dart';
import '../utils/location_utils.dart';
import '../widgets/animated_route.dart';
import '../widgets/tap_scale.dart';
import 'farm_journal_screen.dart';
import 'field_detail_screen.dart';

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

    // Önceki konumun cache'ini varsa anında göster — UI ilk frame'de
    // boş görünmesin. Konum + ağ tamamlanınca _refreshData taze değer atar.
    _hydrateFromLastCache();
    _animController.forward();
    // Konum izin diyaloğunu ilk frame'den sonraya ertele — flutter run'ın
    // Dart VM servisine bağlanmasına zaman tanır; aksi hâlde sistem diyalogu
    // aktiviteyi "paused" yapıp bağlantıyı donduruyor.
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => Future.delayed(const Duration(milliseconds: 600), _refreshData),
    );
  }

  /// Son başarılı tarihteki cache'i Hive'dan oku — instant first paint.
  void _hydrateFromLastCache() {
    try {
      final box = Hive.box('settingsBox');
      final lastLat = box.get('last_dashboard_lat');
      final lastLng = box.get('last_dashboard_lng');
      if (lastLat is num && lastLng is num) {
        final cached = const WeatherSoilService().readCachedConditions(
          latitude: lastLat.toDouble(),
          longitude: lastLng.toDouble(),
        );
        if (cached != null && !cached.isEmpty) {
          _temp = cached.temperatureC != null
              ? '${cached.temperatureC!.round()}'
              : '--';
          _humidity = cached.humidity?.toString() ?? '--';
          _wind = cached.windSpeedMs?.toStringAsFixed(1) ?? '--';
          _weatherDesc = cached.weatherDescriptionTr.isNotEmpty
              ? cached.weatherDescriptionTr[0].toUpperCase() +
                  cached.weatherDescriptionTr.substring(1)
              : '';
          _weatherCondition = _mapWeatherCondition(_weatherDesc);
        }
      }
      final lastAddr = box.get('last_dashboard_address');
      if (lastAddr is String && lastAddr.isNotEmpty) {
        _location = lastAddr;
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

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
        d.contains('fırtına')) {
      return 'rainy';
    }
    if (d.contains('cloud') ||
        d.contains('bulut') ||
        d.contains('overcast') ||
        d.contains('kapalı') ||
        d.contains('fog') ||
        d.contains('sis')) {
      return 'cloudy';
    }
    return 'sunny';
  }

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
    try {
      await ensureLocationPermission();
      final pos = await getCurrentPosition();

      _triggerWeatherAlertIfDue(pos.latitude, pos.longitude);

      // Konum koordinatlarını cache et — bir sonraki açılışta hava için
      // hangi koordinata bakılacağı bilinsin (instant first paint).
      try {
        final box = Hive.box('settingsBox');
        await box.put('last_dashboard_lat', pos.latitude);
        await box.put('last_dashboard_lng', pos.longitude);
      } catch (_) {}

      // Geocoding + weather'ı paralel başlat — sıralı await yerine.
      final addrFuture = _resolveAddress(pos.latitude, pos.longitude);
      final condFuture = const WeatherSoilService().fetchDashboardConditions(
        latitude: pos.latitude,
        longitude: pos.longitude,
      );

      final results = await Future.wait([addrFuture, condFuture]);
      final detailedAddress = results[0] as String;
      final cond = results[1] as DashboardConditions;

      try {
        await Hive.box('settingsBox')
            .put('last_dashboard_address', detailedAddress);
      } catch (_) {}

      if (mounted) {
        setState(() {
          _location = detailedAddress;
          if (cond.temperatureC != null) {
            _temp = '${cond.temperatureC!.round()}';
          }
          if (cond.humidity != null) {
            _humidity = '${cond.humidity}';
          }
          if (cond.windSpeedMs != null) {
            _wind = cond.windSpeedMs!.toStringAsFixed(1);
          }
          final desc = cond.weatherDescriptionTr;
          if (desc.isNotEmpty) {
            _weatherDesc = desc[0].toUpperCase() + desc.substring(1);
            _weatherCondition = _mapWeatherCondition(desc);
          }
        });
        _animController.forward();
      }
    } catch (e) {
      // Hata olsa bile cache'den hidrasyon devrede; sadece adresi güncelle.
      if (mounted && _location == 'Konum aranıyor...') {
        setState(() => _location = 'Konum veya internet hatası');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<String> _resolveAddress(double lat, double lng) async {
    try {
      final placemarks = await placemarkFromCoordinates(lat, lng)
          .timeout(const Duration(seconds: 5));
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        final mahalle = place.subLocality ?? place.thoroughfare ?? '';
        final ilce = place.subAdministrativeArea ?? '';
        final il = place.administrativeArea ?? '';
        final addr = [mahalle, ilce, il].where((s) => s.isNotEmpty).join(', ');
        if (addr.isNotEmpty) return addr;
      }
    } catch (_) {}
    return '${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}';
  }

  void _triggerWeatherAlertIfDue(double lat, double lng) {
    final settingsBox = Hive.box('settingsBox');
    final lastCheckStr = settingsBox.get('last_weather_check_at') as String?;
    final lastCheck =
        lastCheckStr != null ? DateTime.tryParse(lastCheckStr) : null;
    final now = DateTime.now().toUtc();

    if (lastCheck != null && now.difference(lastCheck).inHours < 3) {
      return;
    }

    () async {
      try {
        await NotificationService.checkWeatherAndAlert(lat, lng);
        await FrostAlarmService.checkAndNotify(lat: lat, lon: lng);
        await settingsBox.put(
          'last_weather_check_at',
          now.toIso8601String(),
        );
      } catch (_) {}
    }();
  }

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
            child: Container(color: Colors.black.withValues(alpha: 0.5)),
          ),
          RefreshIndicator(
            onRefresh: _refreshData,
            color: AppColors.emerald,
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
                          _buildFieldOverview(),
                          const SizedBox(height: 24),
                          _buildSectionHeader('Bugün Yapılacaklar',
                              Icons.checklist_rtl_rounded),
                          const SizedBox(height: 12),
                          _buildTasksSummarySection(),
                          const SizedBox(height: 24),
                          _buildSectionHeader(
                              'Tarlalarım', Icons.grass_rounded),
                          const SizedBox(height: 12),
                          _buildMyFieldsSection(),
                          const SizedBox(height: 24),
                          _buildSectionHeader(
                              'Hava Durumu', Icons.wb_sunny_rounded),
                          const SizedBox(height: 12),
                          _buildWeatherStrip(),
                          const SizedBox(height: 24),
                          _buildJournalButton(),
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
      expandedHeight: 240,
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
        stretchModes: const [
          StretchMode.zoomBackground,
          StretchMode.blurBackground
        ],
        background: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x22000000), Color(0x99000000)],
                ),
              ),
            ),
            if (!_isLoading)
              Positioned(
                bottom: 22,
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
              Shadow(
                  color: Color(0x66000000),
                  blurRadius: 4,
                  offset: Offset(0, 1)),
            ],
          ),
        ),
      ],
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // FIELD OVERVIEW — Tarla takibinin nabzı: 3 kritik metrik tek bakışta
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildFieldOverview() {
    final fieldsAsync = ref.watch(fieldMapsProvider);
    final fields = fieldsAsync.asData?.value ?? const <Map<String, dynamic>>[];

    final totalFields = fields.length;
    double totalDekar = 0;
    int needsIrrigation = 0;
    int healthy = 0;

    for (final f in fields) {
      final area = (f['area_dekar'] as num?)?.toDouble();
      if (area != null) totalDekar += area;
      final analysis = f['analysis'];
      final moisture = analysis is Map
          ? (analysis['soil_moisture'] as num?)?.toDouble()
          : null;
      if (moisture != null) {
        if (moisture < 0.3) {
          needsIrrigation++;
        } else if (moisture >= 0.45) {
          healthy++;
        }
      }
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFBF7EC), Colors.white],
        ),
        borderRadius: BorderRadius.circular(22),
        border:
            Border.all(color: Colors.white.withValues(alpha: 0.6), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: AppGradients.emeraldCard,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: AppShadows.emeraldGlow,
                ),
                child: const Icon(Icons.dashboard_rounded,
                    size: 16, color: Colors.white),
              ),
              const SizedBox(width: 10),
              Text(
                'Tarla Genel Durumu',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                  letterSpacing: 0.3,
                ),
              ),
              const Spacer(),
              if (needsIrrigation > 0)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.error.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.warning_amber_rounded,
                          size: 12, color: AppColors.error),
                      const SizedBox(width: 4),
                      Text(
                        '$needsIrrigation acil',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: AppColors.error,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _overviewMetric(
                  icon: Icons.crop_square_rounded,
                  value: '$totalFields',
                  label: 'Tarla',
                  color: AppColors.emeraldDark,
                ),
              ),
              _verticalDivider(),
              Expanded(
                child: _overviewMetric(
                  icon: Icons.straighten_rounded,
                  value: totalDekar > 0 ? totalDekar.toStringAsFixed(1) : '0',
                  label: 'Dekar',
                  color: AppColors.soil,
                ),
              ),
              _verticalDivider(),
              Expanded(
                child: _overviewMetric(
                  icon: Icons.eco_rounded,
                  value: '$healthy',
                  label: 'Sağlıklı',
                  color: AppColors.success,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _verticalDivider() => Container(
        width: 1,
        height: 44,
        color: AppColors.border,
      );

  Widget _overviewMetric({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: color,
            height: 1.0,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.textTertiary,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // WEATHER STRIP — Kompakt, opsiyonel detay
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildWeatherStrip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.6)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _weatherChip(
              icon: Icons.thermostat_rounded,
              value: _temp != '--' ? '$_temp°' : '--',
              label: 'Sıcaklık',
              color: const Color(0xFFE64A19),
            ),
          ),
          _verticalDivider(),
          Expanded(
            child: _weatherChip(
              icon: Icons.water_drop_rounded,
              value: _humidity != '--' ? '%$_humidity' : '--',
              label: 'Nem',
              color: const Color(0xFF0277BD),
            ),
          ),
          _verticalDivider(),
          Expanded(
            child: _weatherChip(
              icon: Icons.air_rounded,
              value: _wind != '--' ? _wind : '--',
              label: 'm/s',
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _weatherChip({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: AppColors.textTertiary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
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
          foregroundColor: Colors.white,
          backgroundColor: Colors.white.withValues(alpha: 0.1),
          side: const BorderSide(color: Colors.white54),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // ÇOKLU TARLA KARTLARI — zenginleştirilmiş tasarım
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildMyFieldsSection() {
    final fieldsAsync = ref.watch(fieldMapsProvider);
    final fields = fieldsAsync.asData?.value ?? const <Map<String, dynamic>>[];

    if (fields.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withValues(alpha: 0.6)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.mint,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(Icons.add_location_alt_rounded,
                  color: AppColors.emeraldDark, size: 28),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Henüz tarla yok',
                    style: AppText.h3(context),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Haritadan ilk tarlanızı çizerek başlayın.',
                    style: AppText.sm(context),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return SizedBox(
      height: 192,
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

    final nextIrrigation = soilMoisture == null
        ? 'Önce analiz yapın'
        : soilMoisture < 0.3
            ? 'Bugün / Yarın'
            : soilMoisture < 0.5
                ? '2-3 gün içinde'
                : '4+ gün sonra';

    final moisturePct =
        soilMoisture != null ? (soilMoisture * 100).round() : null;

    return TapScale(
      scale: 0.96,
      onTap: () {
        Navigator.of(context).push(
          AnimatedRoute.scaleFade(FieldDetailScreen(fieldData: field)),
        );
      },
      child: Container(
        width: 248,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: healthColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(healthIcon, color: healthColor, size: 16),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    name,
                    style: AppText.h3(context),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.spa_rounded, size: 12, color: AppColors.emeraldDark),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    area != null
                        ? '${area.toStringAsFixed(1)} dk · $cropLabel'
                        : cropLabel,
                    style: AppText.sm(context),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Toprak nemi bar
            if (moisturePct != null) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Toprak Nemi',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textTertiary,
                      letterSpacing: 0.3,
                    ),
                  ),
                  Text(
                    '%$moisturePct',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: healthColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Stack(
                  children: [
                    Container(
                      height: 6,
                      color: AppColors.border,
                    ),
                    FractionallySizedBox(
                      widthFactor: soilMoisture!.clamp(0.0, 1.0),
                      child: Container(
                        height: 6,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              healthColor.withValues(alpha: 0.6),
                              healthColor
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.border.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.science_outlined,
                        size: 12, color: AppColors.textTertiary),
                    const SizedBox(width: 6),
                    Text(
                      'Analiz bekleniyor',
                      style: TextStyle(
                        fontSize: 10,
                        color: AppColors.textTertiary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: healthColor.withValues(alpha: 0.1),
                borderRadius: AppRadius.full,
                border: Border.all(color: healthColor.withValues(alpha: 0.25)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.water_drop_rounded, size: 12, color: healthColor),
                  const SizedBox(width: 5),
                  Flexible(
                    child: Text(
                      nextIrrigation,
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: healthColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    healthLabel,
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w500,
                      color: healthColor.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // GÜNLÜK YÖNERGE ÖZETİ
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildTasksSummarySection() {
    final fieldsAsync = ref.watch(fieldMapsProvider);
    final fields = fieldsAsync.asData?.value ?? const <Map<String, dynamic>>[];
    if (fields.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.6)),
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

/// Tek tarla için 1-3 acil/yaklaşan yönergeyi özetler.
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
        final top = directives.where((d) => d.urgency >= 1).take(3).toList();

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
            return _miniRow(
                color, icon, d.headline, d.urgency == 2 ? 'BUGÜN' : null);
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
          color: Colors.white.withValues(alpha: 0.96),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.6)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
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
