import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geocoding/geocoding.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../data/turkiye_crop_guides.dart';
import '../services/app_providers.dart';
import '../services/crop_recommendations.dart';
import '../services/notification_service.dart';
import '../services/frost_alarm_service.dart';
import '../services/weather_soil_service.dart';
import '../theme/app_theme.dart';
import '../utils/location_utils.dart';
import '../widgets/animated_route.dart';
import '../widgets/help_panel.dart';
import '../widgets/tap_scale.dart';
import 'farm_journal_screen.dart';
import 'field_detail_screen.dart';
import '../widgets/fade_slide_in.dart';
import '../widgets/hourly_weather_sheet.dart';
import '../widgets/random_effect_wrapper.dart';
import 'tavsiyeler_screen.dart';
import 'turkiye_crop_guide_screen.dart';

final dashboardWeeklyPlanProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final fieldsAsync = ref.watch(fieldMapsProvider);
  final fields = fieldsAsync.asData?.value ?? <Map<String, dynamic>>[];

  final plans = <Map<String, dynamic>>[];

  for (final f in fields) {
    final fieldId = f['id']?.toString() ?? '';
    final name = f['name']?.toString() ?? 'Tarla';

    // Check Irrigation
    final analysis = f['analysis'];
    final moisture = analysis is Map
        ? (analysis['soil_moisture'] as num?)?.toDouble()
        : null;
    if (moisture != null && moisture < 0.45) {
      plans.add({
        'title': '$name Sulama',
        'time': '06:00',
        'days': 'Her Gün',
        'type': 'water',
        'color': const Color(0xFF0288D1),
        'icon': Icons.water_drop_rounded,
        'field': f,
      });
    }

    // Check Treatment
    if (fieldId.isNotEmpty) {
      final plants =
          await ref.watch(fieldPlantInstancesProvider(fieldId).future);
      final treating =
          plants.where((p) => p.healthStatus == 'treating').toList();
      if (treating.isNotEmpty) {
        plans.add({
          'title': '$name İlaçlama',
          'time': '08:00 & 18:00',
          'days': 'Tedavi Süresince',
          'type': 'treatment',
          'color': const Color(0xFFFF9800),
          'icon': Icons.medication_rounded,
          'field': f,
        });
      }
    }
  }

  return plans;
});

final dashboardEmergencyProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final fieldsAsync = ref.watch(fieldMapsProvider);
  final fields = fieldsAsync.asData?.value ?? <Map<String, dynamic>>[];

  final alerts = <Map<String, dynamic>>[];

  for (final f in fields) {
    final fieldId = f['id']?.toString() ?? '';
    if (fieldId.isNotEmpty) {
      final plants =
          await ref.watch(fieldPlantInstancesProvider(fieldId).future);

      final diseased =
          plants.where((p) => p.healthStatus == 'diseased').toList();
      if (diseased.isNotEmpty) {
        final groups = <String, int>{};
        for (final p in diseased) {
          final d = (p.diseaseType == null || p.diseaseType!.trim().isEmpty)
              ? 'Bilinmeyen Hastalık'
              : p.diseaseType!;
          groups[d] = (groups[d] ?? 0) + 1;
        }

        final primaryDisease =
            groups.entries.reduce((a, b) => a.value >= b.value ? a : b);

        alerts.add({
          'field': f,
          'count': diseased.length,
          'disease': primaryDisease.key,
        });
      }
    }
  }
  return alerts;
});

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

  /// Açık olan daraltılabilir bölümler (kullanıcı detay görmek için
  /// başlığa basınca eklenir). Varsayılan: hepsi kapalı — temiz dashboard.
  final Set<String> _openSections = <String>{};

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

  /// Saatlik 7 günlük hava sheet'ini açar. Lat/lng son refresh'te
  /// Hive `settingsBox` içine yazılır; yoksa konum izinleri istenmeden
  /// kullanıcıya bilgi gösterilir.
  Future<void> _openHourlyForecast() async {
    double? lat;
    double? lon;
    try {
      final box = Hive.box('settingsBox');
      final rawLat = box.get('last_dashboard_lat');
      final rawLng = box.get('last_dashboard_lng');
      if (rawLat is num && rawLng is num) {
        lat = rawLat.toDouble();
        lon = rawLng.toDouble();
      }
    } catch (_) {}

    if (lat == null || lon == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Konum henüz hazır değil. Yenile düğmesiyle konumu güncelle.'),
        ),
      );
      return;
    }
    await showHourlyWeatherSheet(context, lat: lat, lon: lon);
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

    // Aynı 3 saatlik pencerede tarla bazlı rehber bildirimleri de gönder.
    _triggerGuideAlertsIfDue();
  }

  /// Her tarla için GuideEngine'i çalıştırır; yağmur/görev/don bildirimlerini
  /// iletir. 6 saatte bir rate-limit uygulanır (hava kontrolünden bağımsız).
  void _triggerGuideAlertsIfDue() {
    final settingsBox = Hive.box('settingsBox');
    final lastStr = settingsBox.get('last_guide_notify_at') as String?;
    final last = lastStr != null ? DateTime.tryParse(lastStr) : null;
    final now = DateTime.now().toUtc();
    if (last != null && now.difference(last).inHours < 6) return;

    () async {
      try {
        final fields = ref.read(fieldMapsProvider).asData?.value ?? [];
        for (int i = 0; i < fields.length; i++) {
          final field = fields[i];
          final fieldId = field['id']?.toString();
          final fieldName = field['name']?.toString() ?? 'Tarla';
          if (fieldId == null || fieldId.isEmpty) continue;
          try {
            final result = await ref
                .read(fieldGuideProvider(fieldId).future)
                .timeout(const Duration(seconds: 15));
            await NotificationService.sendGuideNotifications(
              result,
              fieldName,
              fieldId: fieldId,
              notificationIdSeed: (i + 1) * 100,
              alertJournal: ref.read(alertJournalServiceProvider),
            );
          } catch (_) {}
        }
        await settingsBox.put('last_guide_notify_at', now.toIso8601String());
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
                          _buildEmergencyBanners(),
                          _buildTavsiyelerStrip(),
                          const SizedBox(height: 10),
                          _buildCollapsibleSection(
                            id: 'overview',
                            title: 'Tarla Genel Durumu',
                            icon: Icons.dashboard_rounded,
                            body: _buildFieldOverview(),
                          ),
                          const SizedBox(height: 10),
                          _buildCollapsibleSection(
                            id: 'tasks',
                            title: 'Bugün Yapılacaklar',
                            icon: Icons.checklist_rtl_rounded,
                            body: _buildTasksSummarySection(),
                          ),
                          const SizedBox(height: 10),
                          _buildCollapsibleSection(
                            id: 'weekly',
                            title: 'Haftalık Plan',
                            icon: Icons.calendar_month_rounded,
                            body: _buildWeeklyPlanSection(),
                          ),
                          const SizedBox(height: 10),
                          _buildCollapsibleSection(
                            id: 'fields',
                            title: 'Tarlalarım',
                            icon: Icons.grass_rounded,
                            body: _buildMyFieldsSection(),
                          ),
                          const SizedBox(height: 18),
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
          icon: const Icon(Icons.help_outline_rounded, color: Colors.white),
          tooltip: 'Yardım',
          onPressed: () => HelpPanel.show(context, HelpContent.dashboard),
        ),
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
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // SOL: Ana sıcaklık + açıklama + konum
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Icon(_weatherIcon,
                                  color: Colors.white70, size: 36),
                              const SizedBox(width: 10),
                              Text(
                                _temp != '--' ? '$_temp°C' : '--',
                                style: const TextStyle(
                                  fontSize: 52,
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
                                fontSize: 14,
                                color: Colors.white70,
                                fontWeight: FontWeight.w300,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.location_on_outlined,
                                  color: Colors.white54, size: 13),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  _location,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Colors.white54,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          _HourlyForecastChip(onTap: _openHourlyForecast),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    // SAĞ: Nem + rüzgar yan yana
                    _HeroWeatherSideChip(
                      icon: Icons.water_drop_rounded,
                      value: _humidity != '--' ? '%$_humidity' : '--',
                      label: 'Nem',
                    ),
                    const SizedBox(width: 8),
                    _HeroWeatherSideChip(
                      icon: Icons.air_rounded,
                      value: _wind != '--' ? _wind : '--',
                      label: 'm/s',
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

  /// Daraltılabilir bölüm — başlık her zaman görünür, gövde varsayılan kapalı.
  /// Başlığa dokununca açılır/kapanır; ek bilgiler yalnızca istenince gelir.
  ///
  /// [id] _openSections set'inde açık olanları izlemek için stabil anahtar.
  // ───────────────────────────────────────────────────────────────────────────
  // TAVSİYELER ŞERİDİ — TAGEM/BATEM/ÇAYKUR kaynaklı 5 ürün için hızlı erişim.
  // Her kart ürünün detay rehberini açar; "Tümünü gör" butonu tavsiyeler
  // ekranını açar.
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildTavsiyelerStrip() {
    final guides = CropRecommendationsService.priorityGuides();
    if (guides.isEmpty) return const SizedBox.shrink();
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 3,
                height: 22,
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
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  gradient: AppGradients.emeraldCard,
                  borderRadius: BorderRadius.circular(9),
                  boxShadow: AppShadows.emeraldGlow,
                ),
                child: const Icon(Icons.recommend_rounded,
                    size: 15, color: Colors.white),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Tavsiyeler',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const TavsiyelerScreen(),
                    ),
                  );
                },
                style: TextButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  minimumSize: const Size(0, 32),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'Tümünü gör',
                  style: TextStyle(
                    color: AppColors.emeraldLight,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Padding(
            padding: EdgeInsets.fromLTRB(14, 0, 12, 8),
            child: Text(
              '5 öncelikli ürün için ekim, sulama, koruma ve hasat '
              'tavsiyeleri.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.white70,
                height: 1.4,
              ),
            ),
          ),
          SizedBox(
            height: 138,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              itemCount: guides.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (_, i) {
                final g = guides[i];
                return FadeSlideIn(
                  index: i,
                  child: _TavsiyeStripCard(
                    guide: g,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => TurkiyeCropGuideScreen(guide: g),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCollapsibleSection({
    required String id,
    required String title,
    required IconData icon,
    required Widget body,
  }) {
    final isOpen = _openSections.contains(id);
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: () {
              setState(() {
                if (isOpen) {
                  _openSections.remove(id);
                } else {
                  _openSections.add(id);
                }
              });
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 3,
                    height: 22,
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
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      gradient: AppGradients.emeraldCard,
                      borderRadius: BorderRadius.circular(9),
                      boxShadow: AppShadows.emeraldGlow,
                    ),
                    child: Icon(icon, size: 15, color: Colors.white),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                  AnimatedRotation(
                    turns: isOpen ? 0.5 : 0,
                    duration: const Duration(milliseconds: 180),
                    child: const Icon(
                      Icons.expand_more_rounded,
                      color: Colors.white70,
                      size: 22,
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 12),
              child: body,
            ),
            crossFadeState:
                isOpen ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
        ],
      ),
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

  // ───────────────────────────────────────────────────────────────────────────
  // HAFTALIK PLAN — Sulama ve İlaçlama Takvimi
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildWeeklyPlanSection() {
    final planAsync = ref.watch(dashboardWeeklyPlanProvider);

    return planAsync.when(
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: CircularProgressIndicator(color: AppColors.emerald),
        ),
      ),
      error: (_, __) => const Text('Plan yüklenemedi.'),
      data: (plans) {
        if (plans.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.6)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(Icons.event_available_rounded,
                    color: AppColors.emerald, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Bu hafta için rutin sulama veya tedavi planı bulunmuyor. Her şey yolunda!',
                    style: AppText.body(context).copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return SizedBox(
          height: 140,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: plans.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (_, i) {
              final p = plans[i];
              final color = p['color'] as Color;
              return TapScale(
                scale: 0.96,
                onTap: () {
                  Navigator.of(context).push(
                    AnimatedRoute.scaleFade(
                        FieldDetailScreen(fieldData: p['field'])),
                  );
                },
                child: Container(
                  width: 220,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        color.withValues(alpha: 0.8),
                        color,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.3),
                        blurRadius: 12,
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
                              color: Colors.white.withValues(alpha: 0.25),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child:
                                Icon(p['icon'], color: Colors.white, size: 18),
                          ),
                          const Spacer(),
                          Text(
                            p['days'],
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Text(
                        p['title'],
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.schedule_rounded,
                              color: Colors.white70, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            p['time'],
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // ACİL DURUM BANNERLARI (Hastalık Uyarıları)
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildEmergencyBanners() {
    final emergencyAsync = ref.watch(dashboardEmergencyProvider);

    return emergencyAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (alerts) {
        if (alerts.isEmpty) return const SizedBox.shrink();

        return Column(
          children: alerts.map((alert) {
            final field = alert['field'];
            final fieldName = field['name']?.toString() ?? 'Tarla';
            final count = alert['count'];
            final disease = alert['disease'];

            return Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: TapScale(
                scale: 0.95,
                onTap: () {
                  Navigator.of(context).push(
                    AnimatedRoute.scaleFade(
                        FieldDetailScreen(fieldData: field)),
                  );
                },
                child: Container(
                  width: double.infinity,
                  clipBehavior: Clip.hardEdge,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFFD32F2F),
                        Color(0xFFC62828),
                        Color(0xFFB71C1C)
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFD32F2F).withValues(alpha: 0.35),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        right: -30,
                        top: -30,
                        child: Icon(Icons.warning_amber_rounded,
                            size: 160,
                            color: Colors.white.withValues(alpha: 0.08)),
                      ),
                      Positioned(
                        right: 20,
                        bottom: -15,
                        child: Icon(Icons.pest_control_rounded,
                            size: 80,
                            color: Colors.black.withValues(alpha: 0.04)),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(22),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.2),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  )
                                ],
                              ),
                              child: const Icon(Icons.local_hospital_rounded,
                                  color: Color(0xFFD32F2F), size: 32),
                            ),
                            const SizedBox(width: 18),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.black
                                              .withValues(alpha: 0.3),
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                        child: const Text(
                                          'ACİL EYLEM',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: 1.2,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          fieldName,
                                          style: const TextStyle(
                                            color: Colors.white70,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    '$count BİTKİNİZ $disease HASTASI!',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Daha fazla yayılmadan hemen tedaviye başlamak için tıklayın.',
                                    style: TextStyle(
                                      color:
                                          Colors.white.withValues(alpha: 0.9),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      height: 1.3,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
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

/// SliverAppBar hero alanında ana sıcaklığın yanına yerleşen kompakt
/// nem/rüzgar chip'i. Şeffaf siyah üstünde beyaz tipografi.
class _HeroWeatherSideChip extends StatelessWidget {
  const _HeroWeatherSideChip({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white70, size: 16),
          const SizedBox(height: 3),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            label,
            style: const TextStyle(
              fontSize: 9,
              color: Colors.white54,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Saatlik tahmin chip'i — hero'da konum satırının altında şık tetikleyici.
// Cam efektli, kaynak rozeti ve chevron'lu; RandomEffectWrapper ile tıklama
// hissi verir ama onTap ASLA geciktirilmez.
// ─────────────────────────────────────────────────────────────────────────────

class _HourlyForecastChip extends StatelessWidget {
  const _HourlyForecastChip({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: RandomEffectWrapper(
        borderRadius: const BorderRadius.all(Radius.circular(999)),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.schedule_rounded, size: 14, color: Colors.white),
              SizedBox(width: 6),
              Text(
                'Saatlik 7 gün',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: 0.2,
                ),
              ),
              SizedBox(width: 6),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 4),
                child: SizedBox(
                  height: 12,
                  child: VerticalDivider(
                    color: Colors.white24,
                    width: 1,
                    thickness: 1,
                  ),
                ),
              ),
              Icon(Icons.verified_rounded, size: 12, color: Colors.white70),
              SizedBox(width: 4),
              Text(
                'MGM',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: Colors.white70,
                  letterSpacing: 0.4,
                ),
              ),
              SizedBox(width: 4),
              Icon(Icons.chevron_right_rounded,
                  size: 16, color: Colors.white70),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tavsiyeler şeridi — tek kart (yatay scroll içinde kullanılır)
// ─────────────────────────────────────────────────────────────────────────────

class _TavsiyeStripCard extends StatelessWidget {
  const _TavsiyeStripCard({required this.guide, required this.onTap});

  final TurkiyeCropGuide guide;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      child: RandomEffectWrapper(
        borderRadius: const BorderRadius.all(Radius.circular(16)),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.10),
            borderRadius: AppRadius.md,
            border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.emerald.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.eco_rounded,
                        color: Colors.white, size: 16),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      guide.cropName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                guide.category,
                style: const TextStyle(
                  color: Colors.white60,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.4,
                ),
              ),
              const SizedBox(height: 6),
              Expanded(
                child: Text(
                  'Ekim: ${guide.sowingWindow}\nHasat: ${guide.harvestWindow}',
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 11.5,
                    height: 1.35,
                  ),
                ),
              ),
              Row(
                children: const [
                  Text(
                    'Tavsiyeleri aç',
                    style: TextStyle(
                      color: AppColors.emeraldLight,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Spacer(),
                  Icon(Icons.chevron_right,
                      color: AppColors.emeraldLight, size: 18),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
