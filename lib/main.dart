import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'dart:io';
import 'map_calculator.dart';
import 'crop_field_match.dart';

import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'agri_service.dart';

Future<void> seedDatabaseOneTime() async {
  final firestore = FirebaseFirestore.instance;

  // Yapay zekaya ürettirebileceğin devasa JSON listen
  final Map<String, Map<String, dynamic>> initialData = {
    "domates": {
      "scientific": "Solanum lycopersicum",
      "desc":
          "Türkiye'de en çok yetiştirilen ve tüketilen sebzelerden biridir. Sıcak ve ılıman iklimleri sever, dona karşı hassastır.",
      "cycle": "Tek Yıllık",
      "watering": "Orta - Sık (Toprak kurumadan)",
      "sunlight": "Tam Güneş (Günde en az 6-8 saat)",
      "growth": "Hızlı",
      "care": "Orta",
      "indoor": false,
      "drought": false,
      "pruning": "Haziran, Temmuz (Koltuk alma işlemi şarttır)",
      "pests":
          "Tuta absoluta (Domates Güvesi), Kırmızı Örümcek, Mildiyö Hastalığı"
    },
    "buğday": {
      "scientific": "Triticum",
      "desc":
          "Karasal iklime en uygun, Türkiye'nin en stratejik tahıl ürünüdür. Soğuğa ve kuraklığa toleranslıdır.",
      "cycle": "Tek Yıllık",
      "watering": "Az (Genelde yağmur suyuyla yetişir)",
      "sunlight": "Tam Güneş",
      "growth": "Orta",
      "care": "Düşük",
      "indoor": false,
      "drought": true,
      "pruning": "Yok",
      "pests": "Süne, Kımıl, Pas Hastalıkları"
    },
    // Buraya yüzlerce ürünü yapıştırabilirsin...
  };

  for (var entry in initialData.entries) {
    await firestore.collection('crops').doc(entry.key).set(entry.value);
  }

  print("Veritabanı başarıyla tohumlandı! 🌱");
}

// Kendi servislerimizi import ediyoruz

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Firebase'i Başlat
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 2. Çevre değişkenlerini ve Yerel Veritabanlarını Başlat
  await dotenv.load(fileName: ".env");

  // 3. Yerel Veritabanını (Hive) başlat
  await Hive.initFlutter();
  await Hive.openBox('agri_history');
  await Hive.openBox('user_crops');
  await Hive.openBox('recognized_plants');

  runApp(const SmartAgriApp());
}

class SmartAgriApp extends StatelessWidget {
  const SmartAgriApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Smart Agri',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2E7D32), // Tarım konseptine uygun yeşil
          brightness: Brightness.light,
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
          backgroundColor: Color(0xFF2E7D32),
          foregroundColor: Colors.white,
        ),
      ),
      home: const MainNavigationScreen(),
    );
  }
}

// ─────────────────────────────────────────────
// KONUM VE GPS YARDIMCILARI (YÜKSEK HASSASİYET)
// ─────────────────────────────────────────────

Future<void> _ensureLocationPermission() async {
  LocationPermission permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.deniedForever) {
    throw Exception(
        'Konum izni kalıcı olarak reddedildi. Lütfen telefon ayarlarından uygulama konumuna izin verin.');
  }
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      throw Exception('Konum izni reddedildi.');
    }
    if (permission == LocationPermission.deniedForever) {
      throw Exception(
          'Konum izni kalıcı olarak reddedildi. Lütfen telefon ayarlarından uygulama konumuna izin verin.');
    }
  }
}

Future<Position> _getCurrentPosition() async {
  try {
    // Tarla için nokta atışı yüksek hassasiyet
    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
      timeLimit: const Duration(seconds: 15),
    );
  } catch (e) {
    final lastPosition = await Geolocator.getLastKnownPosition();
    if (lastPosition != null) return lastPosition;
    throw Exception(
      'Konum alınamadı. Lütfen açık alana çıkın veya GPS\'i kontrol edin.',
    );
  }
}

// ─────────────────────────────────────────────
// ANA NAVİGASYON (MATERIAL 3)
// ─────────────────────────────────────────────

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  static const List<Widget> _pages = [
    AgriDashboard(),
    GrowingGuideScreen(), // YENİ REHBER SEKMESİ
    MyCropsScreen(),
    CameraScreen(),
    PlantDatabaseScreen(), // Geçmiş ve Kayıtlar birleştirildi
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        indicatorColor: Colors.green.shade300,
        backgroundColor: Colors.white,
        elevation: 8,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.analytics_outlined),
            selectedIcon: Icon(Icons.analytics, color: Colors.green),
            label: 'Özet',
          ),
          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book, color: Colors.green),
            label: 'Rehber',
          ),
          NavigationDestination(
            icon: Icon(Icons.grass_outlined),
            selectedIcon: Icon(Icons.grass, color: Colors.green),
            label: 'Tarlalarım',
          ),
          NavigationDestination(
            icon: Icon(Icons.camera_alt_outlined),
            selectedIcon: Icon(Icons.camera_alt, color: Colors.green),
            label: 'AI Analiz',
          ),
          NavigationDestination(
            icon: Icon(Icons.library_books_outlined),
            selectedIcon: Icon(Icons.library_books, color: Colors.green),
            label: 'Ortak Arşiv',
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// 1. SEKME: DASHBOARD (HAVA VE TOPRAK ANALİZİ)
// ─────────────────────────────────────────────

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
      await _ensureLocationPermission();
      final pos = await _getCurrentPosition();

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
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
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

// ─────────────────────────────────────────────
// REHBER EKRANI (Yeni Özellik)
// ─────────────────────────────────────────────

class GrowingGuideScreen extends StatefulWidget {
  const GrowingGuideScreen({super.key});

  @override
  State<GrowingGuideScreen> createState() => _GrowingGuideScreenState();
}

class _GrowingGuideScreenState extends State<GrowingGuideScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _scale = 'Hobi Bahçesi';
  bool _isLoading = false;
  String? _guideResult;
  String? _locationInfo;
  Map<String, dynamic>? _plantingData;
  String _currentCrop = '';

  void _getGuide() async {
    final query = _searchCtrl.text.trim();
    if (query.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lütfen bir bitki adı girin.')));
      return;
    }
    setState(() {
      _isLoading = true;
      _guideResult = null;
      _plantingData = null;
    });

    try {
      final pos = await _getCurrentPosition();
      final result = await AgriService.getPlantGuide(
        query,
        pos.latitude,
        pos.longitude,
        scale: _scale,
      );

      if (mounted) {
        setState(() {
          _guideResult = result['guide'];
          _locationInfo = result['locationInfo'];
          _plantingData = result['plantingData'] as Map<String, dynamic>?;
          _currentCrop = query;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _guideResult = 'Bir hata oluştu: $e';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Akıllı Tarım Rehberi'),
        elevation: 0,
      ),
      body: Column(
        children: [
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
                const Text(
                  'Ne yetiştirmek istiyorsunuz?',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _searchCtrl,
                  decoration: InputDecoration(
                    hintText: 'Örn: Domates, Salatalık, Buğday...',
                    filled: true,
                    fillColor: Colors.white,
                    prefixIcon: const Icon(Icons.search, color: Colors.green),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onSubmitted: (_) => _getGuide(),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Text('Hedef Ölçek: ',
                        style: TextStyle(
                            color: Colors.white70,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('Hobi Bahçesi'),
                      selected: _scale == 'Hobi Bahçesi',
                      onSelected: (val) {
                        if (val) setState(() => _scale = 'Hobi Bahçesi');
                      },
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('Profesyonel'),
                      selected: _scale == 'Profesyonel',
                      onSelected: (val) {
                        if (val) setState(() => _scale = 'Profesyonel');
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _getGuide,
                    icon: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                color: Colors.green, strokeWidth: 2))
                        : const Icon(Icons.auto_awesome),
                    label: Text(_isLoading
                        ? 'AI Rehberi Hazırlanıyor...'
                        : 'Size Özel Rehber Oluştur'),
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.green.shade800,
                      backgroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _guideResult == null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.local_florist,
                            size: 80, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        Text(
                          'Bulunduğunuz konumdaki hava ve\ntoprak şartlarına özel AI yetiştiricilik\nrehberi oluşturun.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: Colors.grey.shade600, fontSize: 16),
                        ),
                      ],
                    ),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_locationInfo != null) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.blue.shade100),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.place, color: Colors.blue.shade700),
                                const SizedBox(width: 8),
                                Expanded(
                                    child: Text(
                                        'Hesaplanan Konum: $_locationInfo',
                                        style: TextStyle(
                                            color: Colors.blue.shade900,
                                            fontWeight: FontWeight.w500))),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                        Text(
                          _guideResult!,
                          style: const TextStyle(fontSize: 16, height: 1.6),
                        ),
                        const SizedBox(height: 24),
                        // ── Animasyonlu Ekim Görselleştirme ──
                        if (_currentCrop.isNotEmpty)
                          _PlantingVisualization(
                            cropName: _currentCrop,
                            plantingData: _plantingData,
                          ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

// ─── Animasyonlu Ekim Görselleştirme Widget ───
class _PlantingVisualization extends StatefulWidget {
  final String cropName;
  final Map<String, dynamic>? plantingData;
  const _PlantingVisualization({required this.cropName, this.plantingData});

  @override
  State<_PlantingVisualization> createState() => _PlantingVisualizationState();
}

class _PlantingVisualizationState extends State<_PlantingVisualization>
    with TickerProviderStateMixin {
  late AnimationController _phaseController;
  late AnimationController _growController;
  late Animation<double> _seedDrop;
  late Animation<double> _rootGrow;
  late Animation<double> _sproutGrow;
  late Animation<double> _leafGrow;
  final List<Map<String, dynamic>> _fields = [];

  @override
  void initState() {
    super.initState();
    _loadFields();

    _phaseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3500),
    );

    _growController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _seedDrop = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _phaseController, curve: const Interval(0.0, 0.25, curve: Curves.bounceOut)),
    );
    _rootGrow = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _phaseController, curve: const Interval(0.25, 0.50, curve: Curves.easeOut)),
    );
    _sproutGrow = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _phaseController, curve: const Interval(0.50, 0.75, curve: Curves.easeOutCubic)),
    );
    _leafGrow = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _phaseController, curve: const Interval(0.75, 1.0, curve: Curves.easeOutCubic)),
    );

    _phaseController.forward();
  }

  void _loadFields() {
    try {
      final box = Hive.box('user_crops');
      for (int i = 0; i < box.length; i++) {
        final f = box.getAt(i);
        if (f != null) {
          _fields.add(Map<String, dynamic>.from(f));
        }
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _phaseController.dispose();
    _growController.dispose();
    super.dispose();
  }

  String get _cropEmoji {
    final name = widget.cropName.toLowerCase();
    if (name.contains('domates')) return '🍅';
    if (name.contains('mısır')) return '🌽';
    if (name.contains('salatalık')) return '🥒';
    if (name.contains('patlıcan')) return '🍆';
    if (name.contains('buğday') || name.contains('bugday')) return '🌾';
    if (name.contains('biber')) return '🫑';
    if (name.contains('patates')) return '🥔';
    if (name.contains('soğan') || name.contains('sogan')) return '🧅';
    if (name.contains('çilek') || name.contains('cilek')) return '🍓';
    if (name.contains('kavun')) return '🍈';
    if (name.contains('karpuz')) return '🍉';
    if (name.contains('üzüm') || name.contains('uzum')) return '🍇';
    return '🌱';
  }

  @override
  Widget build(BuildContext context) {
    final depth = (widget.plantingData?['depth_cm'] ?? 3) as num;
    final rowSpacing = (widget.plantingData?['row_spacing_cm'] ?? 50) as num;
    final plantSpacing = (widget.plantingData?['plant_spacing_cm'] ?? 40) as num;
    final seedsPerDekar = (widget.plantingData?['seeds_per_dekar'] ?? 500) as num;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('🌱 Ekim Görselleştirme',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),

        // ── Büyüme Animasyonu ──
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.lightBlue.shade50, Colors.brown.shade100],
              stops: const [0.5, 0.5],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.green.shade200),
          ),
          child: AnimatedBuilder(
            animation: _phaseController,
            builder: (context, _) {
              return Column(
                children: [
                  // Gökyüzü + Bitki
                  SizedBox(
                    height: 120,
                    child: Stack(
                      alignment: Alignment.bottomCenter,
                      children: [
                        // Güneş
                        Positioned(
                          top: 5,
                          right: 15,
                          child: Opacity(
                            opacity: _sproutGrow.value,
                            child: const Text('☀️', style: TextStyle(fontSize: 28)),
                          ),
                        ),
                        // Tohum düşüşü
                        Positioned(
                          bottom: 0 + (_seedDrop.value * 0),
                          child: Transform.translate(
                            offset: Offset(0, -60 + (_seedDrop.value * 60)),
                            child: Opacity(
                              opacity: _seedDrop.value > 0 ? 1 : 0,
                              child: Text(
                                _seedDrop.value < 0.95 ? '🫘' : '',
                                style: const TextStyle(fontSize: 22),
                              ),
                            ),
                          ),
                        ),
                        // Filiz
                        if (_sproutGrow.value > 0)
                          Positioned(
                            bottom: 0,
                            child: SizedBox(
                              height: 70 * _sproutGrow.value,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Text(
                                    _leafGrow.value > 0.5 ? _cropEmoji : '🌱',
                                    style: TextStyle(
                                      fontSize: 20 + (16 * _leafGrow.value),
                                    ),
                                  ),
                                  Container(
                                    width: 3,
                                    height: 30 * _sproutGrow.value,
                                    decoration: BoxDecoration(
                                      color: Colors.green.shade700,
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Toprak çizgisi
                  Container(
                    height: 3,
                    width: double.infinity,
                    color: Colors.brown.shade400,
                  ),

                  // Toprak altı - kökler
                  SizedBox(
                    height: 50,
                    child: Stack(
                      alignment: Alignment.topCenter,
                      children: [
                        if (_rootGrow.value > 0)
                          CustomPaint(
                            size: const Size(100, 50),
                            painter: _RootPainter(_rootGrow.value),
                          ),
                        // Derinlik göstergesi
                        Positioned(
                          right: 10,
                          top: 5,
                          child: Opacity(
                            opacity: _rootGrow.value,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.brown.shade300,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '↕ ${depth}cm derinlik',
                                style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 8),

        // Fazlar açıklaması
        AnimatedBuilder(
          animation: _phaseController,
          builder: (context, _) {
            String phase = 'Tohum hazırlanıyor...';
            IconData icon = Icons.grain;
            Color color = Colors.brown;
            if (_leafGrow.value > 0.3) {
              phase = '4/4 — Yapraklanma & meyve';
              icon = Icons.eco;
              color = Colors.green.shade800;
            } else if (_sproutGrow.value > 0.1) {
              phase = '3/4 — Filizlenme';
              icon = Icons.spa;
              color = Colors.green;
            } else if (_rootGrow.value > 0.1) {
              phase = '2/4 — Kök salma (${depth}cm)';
              icon = Icons.arrow_downward;
              color = Colors.brown.shade600;
            } else if (_seedDrop.value > 0.1) {
              phase = '1/4 — Tohum ekimi';
              icon = Icons.grain;
              color = Colors.orange.shade700;
            }
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(icon, color: color, size: 20),
                  const SizedBox(width: 8),
                  Text(phase, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14)),
                  const Spacer(),
                  // Tekrar oynat butonu
                  IconButton(
                    icon: const Icon(Icons.replay, size: 20),
                    onPressed: () {
                      _phaseController.reset();
                      _phaseController.forward();
                    },
                    tooltip: 'Tekrar Oynat',
                    color: color,
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 12),

        // Ekim ölçüleri kartları
        Row(
          children: [
            _PlantingStatCard(icon: Icons.arrow_downward, label: 'Derinlik', value: '${depth}cm', color: Colors.brown),
            const SizedBox(width: 8),
            _PlantingStatCard(icon: Icons.swap_horiz, label: 'Sıra Arası', value: '${rowSpacing}cm', color: Colors.blue),
            const SizedBox(width: 8),
            _PlantingStatCard(icon: Icons.space_bar, label: 'Bitki Arası', value: '${plantSpacing}cm', color: Colors.teal),
          ],
        ),
        const SizedBox(height: 12),

        // Tarla bazlı ekim gösterimi
        if (_fields.isNotEmpty) ...[
          const Text('📐 Tarlalarıma Göre Ekim Planı',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ..._fields.map((f) {
            final dekar = (f['area_dekar'] as num?)?.toDouble() ?? 1.0;
            final totalSeeds = (seedsPerDekar * dekar).round();
            final totalRows = (dekar * 10000 / (rowSpacing * 100)).round(); // yaklaşık sıra sayısı
            return _FieldPlantingCard(
              fieldName: f['name'] ?? 'Tarla',
              areaDekar: dekar,
              totalSeeds: totalSeeds,
              totalRows: totalRows,
              cropEmoji: _cropEmoji,
              seedsPerDekar: seedsPerDekar.toInt(),
            );
          }),
        ],
      ],
    );
  }
}

class _RootPainter extends CustomPainter {
  final double progress;
  _RootPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.brown.shade600
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final cx = size.width / 2;

    // Ana kök
    final mainLen = size.height * 0.8 * progress;
    canvas.drawLine(Offset(cx, 0), Offset(cx, mainLen), paint);

    // Sol yan kök
    if (progress > 0.3) {
      final side = (progress - 0.3) / 0.7;
      canvas.drawLine(
        Offset(cx, mainLen * 0.3),
        Offset(cx - 20 * side, mainLen * 0.3 + 15 * side),
        paint..strokeWidth = 1.5,
      );
    }
    // Sağ yan kök
    if (progress > 0.5) {
      final side = (progress - 0.5) / 0.5;
      canvas.drawLine(
        Offset(cx, mainLen * 0.55),
        Offset(cx + 18 * side, mainLen * 0.55 + 12 * side),
        paint..strokeWidth = 1.5,
      );
    }
    // Sol alt kök
    if (progress > 0.7) {
      final side = (progress - 0.7) / 0.3;
      canvas.drawLine(
        Offset(cx, mainLen * 0.7),
        Offset(cx - 14 * side, mainLen * 0.7 + 10 * side),
        paint..strokeWidth = 1,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RootPainter old) => old.progress != progress;
}

class _PlantingStatCard extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final Color color;
  const _PlantingStatCard({required this.icon, required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: color)),
            Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
          ],
        ),
      ),
    );
  }
}

class _FieldPlantingCard extends StatefulWidget {
  final String fieldName, cropEmoji;
  final double areaDekar;
  final int totalSeeds, totalRows, seedsPerDekar;

  const _FieldPlantingCard({
    required this.fieldName,
    required this.areaDekar,
    required this.totalSeeds,
    required this.totalRows,
    required this.cropEmoji,
    required this.seedsPerDekar,
  });

  @override
  State<_FieldPlantingCard> createState() => _FieldPlantingCardState();
}

class _FieldPlantingCardState extends State<_FieldPlantingCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fillAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    _fillAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Grid'de gösterilecek bitki sayısı (max 40 görsel)
    final displayCount = widget.totalSeeds.clamp(1, 40);

    return AnimatedBuilder(
      animation: _fillAnim,
      builder: (context, _) {
        final visibleCount = (_fillAnim.value * displayCount).round();
        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Tarla başlığı
                Row(
                  children: [
                    Icon(Icons.landscape, color: Colors.green.shade700, size: 22),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(widget.fieldName,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text('${widget.areaDekar.toStringAsFixed(1)} Dekar',
                          style: TextStyle(fontSize: 12, color: Colors.green.shade800, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Animasyonlu ekim grid'i
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.brown.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.brown.shade200),
                  ),
                  child: Wrap(
                    spacing: 2,
                    runSpacing: 2,
                    children: List.generate(displayCount, (i) {
                      final isVisible = i < visibleCount;
                      return SizedBox(
                        width: 28,
                        height: 28,
                        child: Center(
                          child: AnimatedOpacity(
                            duration: const Duration(milliseconds: 200),
                            opacity: isVisible ? 1.0 : 0.1,
                            child: AnimatedScale(
                              duration: const Duration(milliseconds: 300),
                              scale: isVisible ? 1.0 : 0.3,
                              child: Text(
                                isVisible ? widget.cropEmoji : '·',
                                style: TextStyle(fontSize: isVisible ? 16 : 10),
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
                const SizedBox(height: 8),

                // İstatistikler
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _miniStat('Toplam Fide', '${widget.totalSeeds}'),
                    _miniStat('Sıra Sayısı', '~${widget.totalRows}'),
                    _miniStat('Dekara', '${widget.seedsPerDekar}'),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _miniStat(String label, String value) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.green.shade800)),
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// 2. SEKME: TARLALARIM
// ─────────────────────────────────────────────

class MyCropsScreen extends StatelessWidget {
  const MyCropsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final box = Hive.box('user_crops');
    return Scaffold(
      appBar: AppBar(title: const Text('Tarlalarım')),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton.extended(
            heroTag: 'calcBtn',
            onPressed: () async {
              try {
                final pos = await _getCurrentPosition();
                if (context.mounted) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MapAreaCalculatorScreen(
                        initialLat: pos.latitude,
                        initialLng: pos.longitude,
                      ),
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Konum hatası: $e')));
                }
              }
            },
            backgroundColor: Colors.blue.shade700,
            icon: const Icon(Icons.map, color: Colors.white),
            label: const Text('Haritadan Tarla Çiz',
                style: TextStyle(color: Colors.white)),
          ),
          const SizedBox(height: 12),
          FloatingActionButton(
            heroTag: 'addBtn',
            onPressed: () => _showAddDialog(context, box),
            backgroundColor: Colors.green,
            child: const Icon(Icons.add, color: Colors.white),
          ),
        ],
      ),
      body: ValueListenableBuilder(
        valueListenable: box.listenable(),
        builder: (context, Box b, _) {
          if (b.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.agriculture,
                        size: 80, color: Colors.green.shade300),
                    const SizedBox(height: 16),
                    const Text(
                      'Henüz kayıtlı tarla yok',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Haritadan tarla çizerek veya + butonuna basarak ilk tarlanızı ekleyin. '
                      'Eklediğiniz tarlalar için anlık hava durumu, toprak analizi ve '
                      'AI destekli ekim önerileri alabilirsiniz!',
                      textAlign: TextAlign.center,
                      style:
                          TextStyle(fontSize: 14, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.only(bottom: 100),
            itemCount: b.length,
            itemBuilder: (context, i) {
              final item = b.getAt(i);
              final hasLocation = item['latitude'] != null;
              final areaDekar = item['area_dekar'];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                elevation: 2,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: hasLocation
                      ? () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  FieldDetailScreen(fieldData: item),
                            ),
                          )
                      : null,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: Colors.green.shade100,
                          child: Icon(Icons.grass,
                              color: Colors.green.shade700, size: 28),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item['name'] ?? '',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(Icons.calendar_today,
                                      size: 14, color: Colors.grey.shade600),
                                  const SizedBox(width: 4),
                                  Text('${item['date']}',
                                      style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey.shade600)),
                                  if (areaDekar != null) ...[
                                    const SizedBox(width: 12),
                                    Icon(Icons.square_foot,
                                        size: 14, color: Colors.grey.shade600),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${(areaDekar as num).toStringAsFixed(1)} Dekar',
                                      style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey.shade600),
                                    ),
                                  ],
                                ],
                              ),
                              if (hasLocation)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    'Detaylar için dokunun →',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.green.shade700,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline,
                              color: Colors.red),
                          onPressed: () => b.deleteAt(i),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showAddDialog(BuildContext context, Box box) async {
    double? lat, lng;
    try {
      final pos = await _getCurrentPosition();
      lat = pos.latitude;
      lng = pos.longitude;
    } catch (_) {}

    if (!context.mounted) return;

    String name = '';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tarla Ekle'),
        content: TextField(
          onChanged: (v) => name = v,
          decoration: const InputDecoration(
            hintText: 'Örn: Arka Bahçe Domates',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('İptal'),
          ),
          FilledButton(
            onPressed: () {
              if (name.isNotEmpty) {
                box.add({
                  'name': name,
                  'date': DateFormat('dd.MM.yyyy').format(DateTime.now()),
                  'latitude': lat,
                  'longitude': lng,
                });
                Navigator.pop(ctx);
              }
            },
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// TARLA DETAY EKRANI
// ─────────────────────────────────────────────

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

// ─────────────────────────────────────────────
// 3. SEKME: KAMERA VE HİBRİT ANALİZ
// ─────────────────────────────────────────────

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});
  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  final List<File> _photos = [];
  bool _isLoading = false;

  Future<void> _pick(ImageSource s) async {
    final img = await ImagePicker().pickImage(
      source: s,
      imageQuality: 70,
      maxWidth: 1080, // Fotoğraf 10MB olsa bile 300KB'a düşürülür, API çökmez!
      maxHeight: 1080,
    );
    if (img != null) setState(() => _photos.insert(0, File(img.path)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Akıllı Asistan Kamerası')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => _pick(ImageSource.camera),
                    icon: const Icon(Icons.camera),
                    label: const Text('Kamera'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => _pick(ImageSource.gallery),
                    icon: const Icon(Icons.image),
                    label: const Text('Galeri'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_isLoading) const LinearProgressIndicator(color: Colors.green),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(12),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 0.8,
              ),
              itemCount: _photos.length,
              itemBuilder: (context, i) => Card(
                clipBehavior: Clip.antiAlias,
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.file(_photos[i], fit: BoxFit.cover),
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [Colors.black87, Colors.transparent],
                          ),
                        ),
                        child: FilledButton(
                          onPressed: _isLoading
                              ? null
                              : () async {
                                  setState(() => _isLoading = true);
                                  final navigator = Navigator.of(context);
                                  final messenger =
                                      ScaffoldMessenger.of(context);
                                  try {
                                    final pos = await _getCurrentPosition();
                                    // HİBRİT SERVİSİ ÇAĞIRIYORUZ
                                    final res = await AgriService.analyzeImage(
                                      _photos[i],
                                      pos.latitude,
                                      pos.longitude,
                                    );
                                    // Başarılı analiz sonuçlarını Kayıtlar sekmesine kaydet
                                    if (res['type'] != 'error') {
                                      Hive.box('recognized_plants').add({
                                        'type': res['type'],
                                        'title': res['data']?['title'] ??
                                            'Bilinmeyen',
                                        'description': res['data']
                                            ?['description'],
                                        'date': DateFormat('dd.MM.yyyy HH:mm')
                                            .format(DateTime.now()),
                                      });
                                    }
                                    if (mounted) {
                                      navigator.push(
                                        MaterialPageRoute(
                                          builder: (_) => AnalysisResultScreen(
                                            image: _photos[i],
                                            result: res,
                                          ),
                                        ),
                                      );
                                    }
                                  } catch (e) {
                                    if (mounted) {
                                      messenger.showSnackBar(
                                        SnackBar(content: Text('Hata: $e')),
                                      );
                                    }
                                  } finally {
                                    if (mounted) {
                                      setState(() => _isLoading = false);
                                    }
                                  }
                                },
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.amber.shade900,
                          ),
                          child: const Text(
                            'Analiz Et',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// 5. SEKME: ORTAK ARŞİV (Geçmiş ve Kayıtlar)
// ─────────────────────────────────────────────

class PlantDatabaseScreen extends StatelessWidget {
  const PlantDatabaseScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Kayıtlı Verilerim'),
          bottom: const TabBar(
            indicatorColor: Colors.white,
            labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            tabs: [
              Tab(icon: Icon(Icons.landscape), text: 'AI Görüntü Analizleri'),
              Tab(icon: Icon(Icons.history), text: 'Hızlı Çevre Geçmişi'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _AiAnalysisHistoryTab(),
            _QuickEnvironmentHistoryTab(),
          ],
        ),
      ),
    );
  }
}

class _AiAnalysisHistoryTab extends StatelessWidget {
  const _AiAnalysisHistoryTab();
  @override
  Widget build(BuildContext context) {
    final box = Hive.box('recognized_plants');
    return ValueListenableBuilder(
      valueListenable: box.listenable(),
      builder: (context, Box b, _) {
        if (b.isEmpty) {
          return const Center(
              child: Text('Henüz bir AI görüntü analizi kaydedilmedi.'));
        }
        return ListView.builder(
          itemCount: b.length,
          reverse: true,
          padding: const EdgeInsets.all(12),
          itemBuilder: (context, i) {
            final item = b.getAt(i);
            return Card(
              elevation: 3,
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: ListTile(
                contentPadding: const EdgeInsets.all(12),
                leading: CircleAvatar(
                  radius: 25,
                  backgroundColor: item['type'] == 'plant'
                      ? Colors.green.shade100
                      : Colors.amber.shade100,
                  child: Icon(
                    item['type'] == 'plant' ? Icons.eco : Icons.landscape,
                    color: item['type'] == 'plant'
                        ? Colors.green
                        : Colors.amber.shade900,
                    size: 30,
                  ),
                ),
                title: Text(
                  item['title'] ?? 'Bilinmeyen',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(item['date'],
                      style: TextStyle(color: Colors.grey.shade600)),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () => b.deleteAt(i),
                ),
                onTap: () => _showDetails(context, item),
              ),
            );
          },
        );
      },
    );
  }

  void _showDetails(BuildContext context, dynamic item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (_, controller) =>
            _BottomSheetContent(item: item, controller: controller),
      ),
    );
  }
}

class _BottomSheetContent extends StatelessWidget {
  final dynamic item;
  final ScrollController controller;
  const _BottomSheetContent({required this.item, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 5,
            decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10)),
          ),
          const SizedBox(height: 20),
          Text(
            item['title'] ?? '',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const Divider(height: 30),
          Expanded(
            child: SingleChildScrollView(
              controller: controller,
              child: item['description'] != null
                  ? Text(item['description'],
                      style: const TextStyle(fontSize: 16, height: 1.5))
                  : const Text('Detay bulunamadı.'),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () => Navigator.pop(context),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
            ),
            child: const Text('Kapat',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ],
      ),
    );
  }
}

class _QuickEnvironmentHistoryTab extends StatelessWidget {
  const _QuickEnvironmentHistoryTab();
  @override
  Widget build(BuildContext context) {
    final box = Hive.box('agri_history');
    return ValueListenableBuilder(
      valueListenable: box.listenable(),
      builder: (context, Box b, _) {
        if (b.isEmpty) {
          return const Center(
              child: Text('Kaydedilmiş anlık çevre analizi yok.'));
        }
        return ListView.builder(
          itemCount: b.length,
          reverse: true,
          padding: const EdgeInsets.all(12),
          itemBuilder: (context, i) {
            final item = b.getAt(i);
            return Card(
              elevation: 2,
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                leading: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                      color: Colors.blue.shade50, shape: BoxShape.circle),
                  child: Icon(Icons.wb_sunny_outlined,
                      color: Colors.blue.shade700, size: 28),
                ),
                title: Text(
                  item['date'],
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    '📍 ${item['location']}\n🌡️ ${item['temp']}   🌿 pH: ${item['ph']}',
                    style: TextStyle(height: 1.4, color: Colors.grey.shade700),
                  ),
                ),
                isThreeLine: true,
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () => b.deleteAt(i),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// ─────────────────────────────────────────────
// SONUÇ EKRANI (PROFESYONEL UI)
// ─────────────────────────────────────────────

class AnalysisResultScreen extends StatelessWidget {
  final File image;
  final Map<String, dynamic> result;

  const AnalysisResultScreen({
    super.key,
    required this.image,
    required this.result,
  });

  @override
  Widget build(BuildContext context) {
    final type = result['type'] ?? 'error';
    final data = result['data'] ?? {};

    final String title = data['title'] ?? 'Analiz Sonucu';
    final String description = data['description'] ?? '';

    return Scaffold(
      appBar: AppBar(title: const Text('Akıllı Tarım Raporu')),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Image.file(
              image,
              height: 250,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Çevre Özeti Kartı (Sadece Tarla ise)
                  if (type == 'field')
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.cloud_outlined,
                            color: Colors.blue,
                            size: 30,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              description,
                              style: TextStyle(
                                color: Colors.blue.shade900,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  if (type == 'plant')
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade800,
                      ),
                    ),

                  const Divider(height: 30),

                  // --- YENİ DEVASA TARLA KARTLARI ---
                  if (type == 'field' && data['crops'] != null) ...[
                    const Text(
                      '🚜 Detaylı Ekim ve Gübreleme Planı',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 15),
                    ...(data['crops'] as List).map(
                      (crop) => _buildAdvancedCropCard(crop),
                    ),
                  ],

                  if (type == 'plant' && data['plant_details'] != null) ...[
                    const Text(
                      '🔍 Bitki Özellikleri',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 15),
                    _buildPlantDetails(data['plant_details']),
                  ],

                  if (type == 'error') ...[
                    Card(
                      color: Colors.red.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.error_outline,
                              color: Colors.red,
                              size: 30,
                            ),
                            const SizedBox(width: 15),
                            Expanded(
                              child: Text(
                                data['message'] ?? 'Hata',
                                style: const TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- İNANILMAZ DETAYLI KART WIDGET'I ---
  Widget _buildAdvancedCropCard(dynamic crop) {
    final double uygunluk = (crop['uygunluk'] as num?)?.toDouble() ?? 0;
    final Color uygunlukColor = uygunluk >= 80
        ? Colors.green
        : uygunluk >= 60
            ? Colors.orange
            : Colors.red;
    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Başlık ve Sezon
            Row(
              children: [
                const CircleAvatar(
                  backgroundColor: Colors.green,
                  child: Icon(Icons.eco, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    crop['name'] ?? '',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Sezon ve uygunluk satırı
            Row(children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(crop['season'] ?? '',
                    style: const TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                        fontSize: 12)),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: uygunlukColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.check_circle, size: 14, color: uygunlukColor),
                  const SizedBox(width: 4),
                  Text('%${uygunluk.toStringAsFixed(0)} Uygun',
                      style: TextStyle(
                          color: uygunlukColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12)),
                ]),
              ),
            ]),
            // Uygunluk çubuğu
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: uygunluk / 100,
                  minHeight: 6,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation(uygunlukColor),
                ),
              ),
            ),
            const Divider(),
            const SizedBox(height: 4),

            // Temel Bilgi
            Text(
              crop['info'] ?? '',
              style: const TextStyle(fontSize: 15, height: 1.4),
            ),
            const SizedBox(height: 16),

            // Gübreleme ve Hava Durumu İkonlu Liste
            _buildDetailRow(
              Icons.science,
              'Gübreleme Programı',
              crop['fertilizer'] ?? '',
              Colors.orange,
            ),
            const SizedBox(height: 12),
            _buildDetailRow(
              Icons.water_drop,
              'Haftalık Hava Etkisi',
              crop['weather_impact'] ?? '',
              Colors.blue,
            ),
            const SizedBox(height: 12),
            _buildDetailRow(
              Icons.build_circle,
              'Bakım ve İşçilik',
              crop['care_details'] ?? '',
              Colors.brown,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    IconData icon,
    String title,
    String content,
    Color iconColor,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: iconColor, size: 24),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                content,
                style: TextStyle(color: Colors.grey.shade700, height: 1.4),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPlantDetails(dynamic details) {
    if (details == null) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Text('Bitki detayı bulunamadı.',
            style: TextStyle(color: Colors.red)),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Bilimsel Adı: ${result['data']?['scientific_name'] ?? 'Bilinmiyor'}\nFamilya: ${details['family'] ?? 'Bilinmiyor'}',
          style: const TextStyle(
              fontStyle: FontStyle.italic,
              color: Colors.grey,
              fontSize: 16,
              height: 1.4),
        ),
        const Divider(height: 30),
        _buildInfoBombCard(Icons.speed, 'Başarı Şansı', details['basari_sansi'],
            Colors.green.shade700,
            isBold: true),
        _buildInfoBombCard(Icons.location_on, 'Konum & Çevre Yorumu',
            details['konum_yorumu'], Colors.brown.shade700),
        _buildInfoBombCard(Icons.water_drop, 'Sulama Takvimi',
            details['sulama_takvimi'], Colors.blue.shade700),
        _buildInfoBombCard(Icons.eco, 'Gübre Önerisi', details['gubre_onerisi'],
            Colors.teal.shade700),
        _buildInfoBombCard(Icons.menu_book, 'Nasıl Yetiştirilir?',
            details['nasil_yetistirilir'], Colors.orange.shade700),
        _buildInfoBombCard(Icons.lightbulb, 'Bakım Püf Noktaları',
            details['bakim_puf_noktasi'], Colors.amber.shade800),
        _buildInfoBombCard(Icons.bug_report, 'Hastalık & Zararlı Riskleri',
            details['hastalik_riskleri'], Colors.red.shade700),
        if (details['hasat_zamani'] != null &&
            details['hasat_zamani'].toString().length > 5)
          _buildInfoBombCard(Icons.shopping_basket, 'Hasat Bilgisi',
              details['hasat_zamani'], Colors.purple.shade700),
        if (details['depolama_saklama'] != null &&
            details['depolama_saklama'].toString().length > 5)
          _buildInfoBombCard(Icons.inventory, 'Depolama & Saklama',
              details['depolama_saklama'], Colors.blueGrey.shade700),
      ],
    );
  }

  Widget _buildInfoBombCard(
    IconData icon,
    String title,
    String? content,
    Color color, {
    bool isBold = false,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: color.withValues(alpha: 0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    content ?? 'Bilgi Yok',
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.4,
                      fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
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
}
