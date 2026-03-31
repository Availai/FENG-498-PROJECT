import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:geocoding/geocoding.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../utils/location_utils.dart';

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
      _location = 'Aranıyor...';
  bool _isLoading = false;
  String _weatherCondition = 'sunny'; // sunny, rainy, cloudy

  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  static String get _weatherKey => dotenv.env['WEATHER_API_KEY'] ?? '';

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeIn);
    _refreshData();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  String _getWeatherImage() {
    switch (_weatherCondition) {
      case 'rainy':
        return 'assets/weather/rainy.png';
      case 'cloudy':
        return 'assets/weather/cloudy.png';
      default:
        return 'assets/weather/sunny.png';
    }
  }

  String _mapWeatherCondition(String description) {
    final d = description.toLowerCase();
    if (d.contains('rain') ||
        d.contains('yağmur') ||
        d.contains('drizzle') ||
        d.contains('storm') ||
        d.contains('fırtına')) {
      return 'rainy';
    } else if (d.contains('cloud') ||
        d.contains('bulut') ||
        d.contains('overcast') ||
        d.contains('kapalı') ||
        d.contains('fog') ||
        d.contains('sis')) {
      return 'cloudy';
    }
    return 'sunny';
  }

  Future<void> _refreshData() async {
    setState(() => _isLoading = true);
    _animController.reset();
    try {
      await ensureLocationPermission();
      final pos = await getCurrentPosition();

      String detailedAddress = 'Adres çözümleniyor...';
      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(
          pos.latitude,
          pos.longitude,
        );
        if (placemarks.isNotEmpty) {
          Placemark place = placemarks.first;
          String mahalle = place.subLocality ?? place.thoroughfare ?? '';
          String ilce = place.subAdministrativeArea ?? '';
          String il = place.administrativeArea ?? '';
          detailedAddress =
              '$mahalle, $ilce, $il\nKoor: ${pos.latitude.toStringAsFixed(4)}, ${pos.longitude.toStringAsFixed(4)}';
        }
      } catch (e) {
        detailedAddress =
            'Koor: ${pos.latitude.toStringAsFixed(4)}, ${pos.longitude.toStringAsFixed(4)}';
      }

      final results = await Future.wait([
        http.get(Uri.parse(
          'https://api.openweathermap.org/data/2.5/weather?lat=${pos.latitude}&lon=${pos.longitude}&appid=$_weatherKey&units=metric&lang=tr',
        )),
        http.get(Uri.parse(
          'https://rest.isric.org/soilgrids/v2.0/properties/query?lon=${pos.longitude}&lat=${pos.latitude}&property=phh2o&depth=0-5cm&value=mean',
        )),
      ]);

      if (mounted) {
        setState(() {
          _location = detailedAddress;
          if (results[0].statusCode == 200) {
            final data = jsonDecode(results[0].body);
            _temp = '${data['main']['temp'].round()}°C';
            _humidity = '%${data['main']['humidity']}';
            _wind = (data['wind'] != null && data['wind']['speed'] != null)
                ? '${data['wind']['speed']} m/s'
                : 'N/A';
            // Hava durumuna göre arka plan
            final desc = data['weather']?[0]?['description'] ?? '';
            _weatherCondition = _mapWeatherCondition(desc);
          } else {
            _temp = '--';
            _humidity = '--';
            _wind = '--';
          }

          if (results[1].statusCode == 200) {
            final data = jsonDecode(results[1].body);
            final val = data['properties']?['layers']?[0]?['depths']?[0]
                ?['values']?['mean'];
            if (val != null) {
              _ph = (val / 10.0).toStringAsFixed(1);
            } else {
              _ph = '6.8 (Tahmini)';
            }
          } else {
            _ph = '6.8 (Tahmini)';
          }
        });
        _animController.forward();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _location = 'Konum veya internet hatası!';
          _temp = '--';
          _humidity = '--';
          _ph = '--';
        });
        _animController.forward();
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Anlık Çevre Analizi'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _refreshData),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Dinamik arka plan
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 600),
            child: Image.asset(
              _getWeatherImage(),
              key: ValueKey(_weatherCondition),
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
            ),
          ),
          // Koyu overlay (kartlar okunabilsin)
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.3),
                  Colors.black.withValues(alpha: 0.6),
                ],
              ),
            ),
          ),
          // İçerik
          _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: Colors.white))
              : FadeTransition(
                  opacity: _fadeAnim,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 100, 16, 16),
                    child: Column(children: [
                      _buildGlassCard(
                          '📍 Mevcut Konum', _location, Colors.blue.shade300),
                      const SizedBox(height: 12),
                      Row(children: [
                        Expanded(
                            child: _buildGlassCard(
                                '🌡️ Sıcaklık', _temp, Colors.orange.shade300)),
                        const SizedBox(width: 12),
                        Expanded(
                            child: _buildGlassCard(
                                '💧 Nem', _humidity, Colors.cyan.shade300)),
                      ]),
                      const SizedBox(height: 12),
                      Row(children: [
                        Expanded(
                            child: _buildGlassCard(
                                '💨 Rüzgar', _wind, Colors.blueGrey.shade300)),
                        const SizedBox(width: 12),
                        Expanded(
                            child: _buildGlassCard(
                                '🌿 Toprak pH', _ph, Colors.teal.shade300)),
                      ]),
                      const SizedBox(height: 30),
                      FilledButton.icon(
                        onPressed: () async {
                          final box = Hive.box('agri_history');
                          await box.add({
                            'date': DateFormat('dd.MM.yyyy HH:mm')
                                .format(DateTime.now()),
                            'temp': _temp,
                            'ph': _ph,
                            'location': _location.split('\n').first,
                          });
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Veriler arşive kaydedildi!')),
                            );
                          }
                        },
                        icon: const Icon(Icons.save),
                        label: const Text('BU ANALİZİ ARŞİVLE'),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(50),
                          backgroundColor: Colors.green.shade700,
                        ),
                      ),
                    ]),
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildGlassCard(String title, String value, Color color) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                spreadRadius: -2,
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(title,
                  style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      letterSpacing: 0.5)),
              const SizedBox(height: 10),
              Text(value,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: Colors.white)),
            ],
          ),
        ),
      ),
    );
  }
}
