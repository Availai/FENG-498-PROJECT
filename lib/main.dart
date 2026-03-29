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

// Kendi servislerimizi import ediyoruz
import 'agri_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Çevre değişkenlerini (API şifrelerini) yükle
  await dotenv.load(fileName: ".env");

  // Yerel Veritabanını (Hive) başlat
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
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      throw Exception('Konum izni reddedildi.');
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
    MyCropsScreen(),
    CameraScreen(),
    AnalysisHistoryScreen(),
    PlantDatabaseScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        indicatorColor: Colors.green.shade200,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.analytics_outlined),
            label: 'Analiz',
          ),
          NavigationDestination(
            icon: Icon(Icons.grass_outlined),
            label: 'Tarlalarım',
          ),
          NavigationDestination(
            icon: Icon(Icons.camera_alt_outlined),
            label: 'AI Kamera',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            label: 'Geçmiş',
          ),
          NavigationDestination(
            icon: Icon(Icons.library_books_outlined),
            label: 'Kayıtlar',
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
    if (d.contains('rain') || d.contains('yağmur') || d.contains('drizzle') || d.contains('storm') || d.contains('fırtına')) {
      return 'rainy';
    } else if (d.contains('cloud') || d.contains('bulut') || d.contains('overcast') || d.contains('kapalı') || d.contains('fog') || d.contains('sis')) {
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
          pos.latitude, pos.longitude,
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
                ? '${data['wind']['speed']} m/s' : 'N/A';
            // Hava durumuna göre arka plan
            final desc = data['weather']?[0]?['description'] ?? '';
            _weatherCondition = _mapWeatherCondition(desc);
          } else { _temp = '--'; _humidity = '--'; _wind = '--'; }

          if (results[1].statusCode == 200) {
            final data = jsonDecode(results[1].body);
            final val = data['properties']?['layers']?[0]?['depths']?[0]?['values']?['mean'];
            if (val != null) { _ph = (val / 10.0).toStringAsFixed(1); }
            else { _ph = 'Veri Yok (Şehir İçi)'; }
          } else { _ph = 'API Hatası'; }
        });
        _animController.forward();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _location = 'Konum veya internet hatası!';
          _temp = '--'; _humidity = '--'; _ph = '--';
        });
        _animController.forward();
      }
    } finally {
      if (mounted) { setState(() => _isLoading = false); }
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
              ? const Center(child: CircularProgressIndicator(color: Colors.white))
              : FadeTransition(
                  opacity: _fadeAnim,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 100, 16, 16),
                    child: Column(children: [
                      _buildGlassCard('📍 Mevcut Konum', _location, Colors.blue.shade300),
                      const SizedBox(height: 12),
                      Row(children: [
                        Expanded(child: _buildGlassCard('🌡️ Sıcaklık', _temp, Colors.orange.shade300)),
                        const SizedBox(width: 12),
                        Expanded(child: _buildGlassCard('💧 Nem', _humidity, Colors.cyan.shade300)),
                      ]),
                      const SizedBox(height: 12),
                      Row(children: [
                        Expanded(child: _buildGlassCard('💨 Rüzgar', _wind, Colors.blueGrey.shade300)),
                        const SizedBox(width: 12),
                        Expanded(child: _buildGlassCard('🌿 Toprak pH', _ph, Colors.teal.shade300)),
                      ]),
                      const SizedBox(height: 30),
                      FilledButton.icon(
                        onPressed: () async {
                          final box = Hive.box('agri_history');
                          await box.add({
                            'date': DateFormat('dd.MM.yyyy HH:mm').format(DateTime.now()),
                            'temp': _temp, 'ph': _ph,
                            'location': _location.split('\n').first,
                          });
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Veriler arşive kaydedildi!')),
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 8),
          Text(value, textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
        ],
      ),
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
                  ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(content: Text('Konum hatası: $e')));
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
                    Icon(Icons.agriculture, size: 80, color: Colors.green.shade300),
                    const SizedBox(height: 16),
                    const Text(
                      'Henüz kayıtlı tarla yok',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Haritadan tarla çizerek veya + butonuna basarak ilk tarlanızı ekleyin. '
                      'Eklediğiniz tarlalar için anlık hava durumu, toprak analizi ve '
                      'AI destekli ekim önerileri alabilirsiniz!',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
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
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: hasLocation
                      ? () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => FieldDetailScreen(fieldData: item),
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
                          child: Icon(Icons.grass, color: Colors.green.shade700, size: 28),
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
                                          fontSize: 13, color: Colors.grey.shade600)),
                                  if (areaDekar != null) ...[
                                    const SizedBox(width: 12),
                                    Icon(Icons.square_foot,
                                        size: 14, color: Colors.grey.shade600),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${(areaDekar as num).toStringAsFixed(1)} Dekar',
                                      style: TextStyle(
                                          fontSize: 13, color: Colors.grey.shade600),
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
                          icon: const Icon(Icons.delete_outline, color: Colors.red),
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
    setState(() { _isLoading = true; _error = null; });
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
          if (result['success'] == true) { _analysis = result; }
          else { _error = result['error'] ?? 'Bilinmeyen hata'; }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() { _error = 'Veri yüklenirken hata: $e'; _isLoading = false; });
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
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadAnalysis, tooltip: 'Yenile'),
        ],
      ),
      body: _isLoading
          ? const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
              CircularProgressIndicator(color: Colors.green),
              SizedBox(height: 16),
              Text('Tarla analizi yükleniyor...\nHava, toprak ve AI verileri getiriliyor.', textAlign: TextAlign.center),
            ]))
          : _error != null
              ? Center(child: Padding(padding: const EdgeInsets.all(32), child: Column(
                  mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.cloud_off, size: 60, color: Colors.red),
                    const SizedBox(height: 16),
                    Text(_error!, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    FilledButton.icon(onPressed: _loadAnalysis, icon: const Icon(Icons.refresh), label: const Text('Tekrar Dene')),
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
            gradient: LinearGradient(colors: [Colors.green.shade700, Colors.teal.shade600]),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Icon(Icons.landscape, color: Colors.white, size: 32),
              const SizedBox(width: 12),
              Expanded(child: Text(d['name'] ?? 'Tarla',
                  style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold))),
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
        const Text('🌤️ Anlık Hava Durumu', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Row(children: [
          _wTile(Icons.thermostat, '${(a['temp'] as num).toStringAsFixed(1)}°C', 'Sıcaklık', Colors.orange),
          const SizedBox(width: 8),
          _wTile(Icons.water_drop, '%${(a['humidity'] as num).toStringAsFixed(0)}', 'Nem', Colors.blue),
          const SizedBox(width: 8),
          _wTile(Icons.air, '${(a['wind'] as num).toStringAsFixed(1)} m/s', 'Rüzgar', Colors.cyan),
        ]),
        if ((a['weather_desc'] as String).isNotEmpty)
          Padding(padding: const EdgeInsets.only(top: 6),
            child: Text('${(a['weather_desc'] as String)[0].toUpperCase()}${(a['weather_desc'] as String).substring(1)}',
                style: TextStyle(color: Colors.grey.shade700, fontSize: 14))),

        const SizedBox(height: 16),

        // ── TOPRAK pH ──
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.brown.shade50, borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.brown.shade200),
          ),
          child: Row(children: [
            Icon(Icons.science, color: Colors.brown.shade700, size: 28),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Toprak pH: ${(a['ph'] as num).toStringAsFixed(1)}',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.brown.shade800)),
              Text(_phComment((a['ph'] as num).toDouble()),
                  style: TextStyle(fontSize: 13, color: Colors.brown.shade600)),
            ])),
          ]),
        ),

        const SizedBox(height: 20),

        // ── 7 GÜNLÜK TAHMİN ──
        const Text('📅 7 Günlük Hava Tahmini', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(children: dailyForecast.map<Widget>((day) {
            final date = (day['date'] as String).substring(5);
            final max = (day['max'] as num).toStringAsFixed(0);
            final min = (day['min'] as num).toStringAsFixed(0);
            final rain = (day['rain'] as num).toDouble();
            return Container(
              width: 90, margin: const EdgeInsets.only(right: 8), padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: rain > 5 ? Colors.blue.shade50 : Colors.amber.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: rain > 5 ? Colors.blue.shade200 : Colors.amber.shade200),
              ),
              child: Column(children: [
                Text(date, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 4),
                Icon(rain > 5 ? Icons.umbrella : Icons.wb_sunny,
                    color: rain > 5 ? Colors.blue : Colors.orange, size: 22),
                const SizedBox(height: 4),
                Text('$max° / $min°', style: const TextStyle(fontSize: 12)),
                if (rain > 0)
                  Text('${rain.toStringAsFixed(1)} mm',
                      style: TextStyle(fontSize: 11, color: Colors.blue.shade700)),
              ]),
            );
          }).toList()),
        ),
        Padding(padding: const EdgeInsets.only(top: 6),
          child: Text('Ort. Sıcaklık: ${a['avg_weekly_temp']}°C  •  Toplam Yağış: ${a['total_weekly_rain']} mm',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13))),

        const SizedBox(height: 20),

        // ── NE EKİLEBİLİR ──
        const Text('🌾 Bu Tarlada Ne Ekilebilir?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ...crops.map<Widget>((crop) => _cropCard(crop)),

        const SizedBox(height: 20),

        // ── AI YORUM ──
        const Text('🤖 AI Haftalık Tarla Yorumu', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.indigo.shade50, borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.indigo.shade200),
          ),
          child: Text(a['ai_weekly_comment'] ?? '', style: const TextStyle(fontSize: 15, height: 1.6)),
        ),

        const SizedBox(height: 24),

        // ── EYLEM BUTONLARI ──
        const Text('⚡ Hızlı İşlemler', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        FilledButton.icon(
          onPressed: () => _cropSelectForPlan(context, d['name'] ?? ''),
          icon: const Icon(Icons.edit_calendar),
          label: const Text('AI ile Ekim Planı Oluştur'),
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52),
              backgroundColor: Colors.teal.shade700,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CameraScreen())),
          icon: const Icon(Icons.camera_alt),
          label: const Text('Bu Tarlada Bitki/Toprak Tara'),
          style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(52),
              side: BorderSide(color: Colors.green.shade700),
              foregroundColor: Colors.green.shade700,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: () => _fertilizerTip(context, a),
          icon: const Icon(Icons.science),
          label: const Text('Gübre ve Toprak İyileştirme Önerisi'),
          style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(52),
              side: BorderSide(color: Colors.brown.shade700),
              foregroundColor: Colors.brown.shade700,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
        ),
        const SizedBox(height: 40),
      ]),
    );
  }

  Widget _wTile(IconData icon, String value, String label, Color c) {
    return Expanded(child: Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(color: c.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12),
          border: Border.all(color: c.withValues(alpha: 0.3))),
      child: Column(children: [
        Icon(icon, color: c, size: 26), const SizedBox(height: 6),
        Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: c)),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
      ]),
    ));
  }

  Widget _cropCard(dynamic crop) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10), elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: CircleAvatar(backgroundColor: Colors.green.shade100, child: const Icon(Icons.eco, color: Colors.green)),
          title: Text(crop['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text('Mevsim: ${crop['season']}', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
          children: [Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _cropInfo('📋 Genel Bilgi', crop['info']),
              _cropInfo('🧪 Gübreleme', crop['fertilizer']),
              _cropInfo('🌧️ Hava Etkisi', crop['weather_impact']),
              _cropInfo('🛠️ Bakım', crop['care_details']),
              const SizedBox(height: 8),
              SizedBox(width: double.infinity, child: FilledButton.tonal(
                onPressed: () => _genPlan(crop['name']),
                child: Text('${crop['name']} için AI Ekim Planı'),
              )),
              const SizedBox(height: 8),
            ]),
          )],
        ),
      ),
    );
  }

  Widget _cropInfo(String title, String? content) {
    if (content == null || content.isEmpty) { return const SizedBox.shrink(); }
    return Padding(padding: const EdgeInsets.only(bottom: 10), child: Column(
      crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green.shade800, fontSize: 14)),
        const SizedBox(height: 2),
        Text(content, style: const TextStyle(fontSize: 14, height: 1.4)),
      ],
    ));
  }

  String _phComment(double ph) {
    if (ph < 5.5) { return 'Çok asidik — kireçleme gerekebilir'; }
    if (ph < 6.0) { return 'Hafif asidik — çoğu sebze için uygun'; }
    if (ph < 7.0) { return 'Nötre yakın — ideal tarım toprağı'; }
    if (ph < 7.5) { return 'Hafif bazik — kabul edilebilir'; }
    return 'Bazik toprak — kükürt uygulaması düşünülebilir';
  }

  void _cropSelectForPlan(BuildContext context, String fieldName) {
    final crops = _analysis?['crops'] as List? ?? [];
    if (crops.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Önce ürün önerileri yüklenmelidir.')));
      return;
    }
    showModalBottomSheet(context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(padding: const EdgeInsets.all(20), child: Column(
        mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Hangi ürün için plan oluşturulsun?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          ...crops.map<Widget>((crop) => ListTile(
            leading: const Icon(Icons.eco, color: Colors.green),
            title: Text(crop['name']),
            onTap: () { Navigator.pop(ctx); _genPlan(crop['name']); },
          )),
        ],
      )),
    );
  }

  void _genPlan(String cropName) {
    final fieldName = widget.fieldData['name'] ?? 'Tarla';
    showDialog(context: context, barrierDismissible: false,
      builder: (BuildContext loadingCtx) {
        AgriService.generateFieldPlan(cropName, fieldName).then((plan) {
          if (loadingCtx.mounted) { Navigator.pop(loadingCtx); }
          if (loadingCtx.mounted) {
            showDialog(context: loadingCtx, builder: (c) => AlertDialog(
              title: Text('$cropName Ekim Planı', style: const TextStyle(color: Colors.teal, fontWeight: FontWeight.bold)),
              content: SingleChildScrollView(child: Text(plan, style: const TextStyle(height: 1.5, fontSize: 15))),
              actions: [FilledButton(onPressed: () => Navigator.pop(c), child: const Text('Tamam'))],
            ));
          }
        });
        return const AlertDialog(content: Row(children: [
          CircularProgressIndicator(color: Colors.green), SizedBox(width: 20),
          Expanded(child: Text('AI ekim planı hazırlanıyor...\nLütfen bekleyin.')),
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
    showDialog(context: context, builder: (c) => AlertDialog(
      title: const Text('Gübre & Toprak İyileştirme', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.brown)),
      content: SingleChildScrollView(child: Text(tip, style: const TextStyle(fontSize: 15, height: 1.5))),
      actions: [FilledButton(onPressed: () => Navigator.pop(c), child: const Text('Anladım'))],
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
                                  final messenger = ScaffoldMessenger.of(context);
                                  try {
                                    final pos = await _getCurrentPosition();
                                    // HİBRİT SERVİSİ ÇAĞIRIYORUZ
                                    final res = await AgriService.analyzeImage(
                                      _photos[i],
                                      pos.latitude,
                                      pos.longitude,
                                    );
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
// 4. SEKME: ÇEVRE ANALİZ GEÇMİŞİ
// ─────────────────────────────────────────────

class AnalysisHistoryScreen extends StatelessWidget {
  const AnalysisHistoryScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final box = Hive.box('agri_history');
    return Scaffold(
      appBar: AppBar(title: const Text('Çevre Analiz Geçmişi')),
      body: ValueListenableBuilder(
        valueListenable: box.listenable(),
        builder: (context, Box b, _) {
          if (b.isEmpty) {
            return const Center(child: Text('Kayıtlı analiz yok.'));
          }
          return ListView.builder(
            itemCount: b.length,
            reverse: true,
            itemBuilder: (context, i) {
              final item = b.getAt(i);
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: ListTile(
                  leading: const Icon(Icons.history, color: Colors.blue),
                  title: Text(
                    item['date'],
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    '${item['location']}\nSıcaklık: ${item['temp']} | pH: ${item['ph']}',
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
      ),
    );
  }
}

// ─────────────────────────────────────────────
// 5. SEKME: BİTKİ/ARAZİ KAYITLARI
// ─────────────────────────────────────────────

class PlantDatabaseScreen extends StatelessWidget {
  const PlantDatabaseScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final box = Hive.box('recognized_plants');
    return Scaffold(
      appBar: AppBar(title: const Text('Analiz Raporlarım')),
      body: ValueListenableBuilder(
        valueListenable: box.listenable(),
        builder: (context, Box b, _) {
          if (b.isEmpty) {
            return const Center(child: Text('Henüz bir sonuç kaydedilmedi.'));
          }
          return ListView.builder(
            itemCount: b.length,
            reverse: true,
            itemBuilder: (context, i) {
              final item = b.getAt(i);
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: item['type'] == 'plant'
                        ? Colors.green.shade100
                        : Colors.amber.shade100,
                    child: Icon(
                      item['type'] == 'plant' ? Icons.eco : Icons.landscape,
                      color: item['type'] == 'plant'
                          ? Colors.green
                          : Colors.amber.shade900,
                    ),
                  ),
                  title: Text(
                    item['title'] ?? 'Bilinmeyen',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(item['date']),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => b.deleteAt(i),
                  ),
                  onTap: () => _showDetails(context, item),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showDetails(BuildContext context, dynamic item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item['title'] ?? '',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            if (item['description'] != null) ...[
              const SizedBox(height: 10),
              Text(item['description'], style: const TextStyle(fontSize: 16)),
            ],
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () => Navigator.pop(ctx),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
              ),
              child: const Text('Kapat'),
            ),
          ],
        ),
      ),
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

  void _showFieldSelectionDialog(BuildContext context, String plantName) {
    final box = Hive.box('user_crops');
    if (box.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Önce "Tarlalarım" sekmesinden bir tarla eklemelisiniz!',
          ),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('$plantName İçin Tarla Seçin'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: box.length,
            itemBuilder: (context, i) {
              final field = box.getAt(i);
              return ListTile(
                leading: const Icon(Icons.landscape, color: Colors.green),
                title: Text(field['name']),
                onTap: () {
                  // 1. Önce alttaki Tarlalar listesini (Bottom Sheet) kapatıyoruz
                  Navigator.pop(ctx);

                  // 2. Yükleniyor Dialogunu Açıyoruz ve İŞLEMİ İÇİNE GÖMÜYORUZ
                  showDialog(
                    context: context,
                    barrierDismissible:
                        false, // Kullanıcı dışarı tıklayıp bozamasın
                    builder: (BuildContext loadingContext) {
                      // 3. Ekran açıldığı an Gemini'yi arka planda tetikliyoruz
                      AgriService.generateFieldPlan(
                        plantName,
                        field['name'],
                      ).then((plan) {
                        // 4. Gemini'den cevap geldiği an "loadingContext" ile Yükleniyor kutucuğunu KESİN OLARAK kapat!
                        if (loadingContext.mounted) {
                          Navigator.pop(loadingContext);
                        }

                        // 5. Ve sonucu gösteren büyük plan kutucuğunu aç
                        if (loadingContext.mounted) {
                          showDialog(
                            context: loadingContext,
                          builder: (c) => AlertDialog(
                            title: Text(
                              '${field['name']} - Ekim Planı',
                              style: const TextStyle(
                                color: Colors.teal,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            content: SingleChildScrollView(
                              child: Text(
                                plan,
                                style: const TextStyle(
                                  height: 1.5,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            actions: [
                              FilledButton(
                                onPressed: () => Navigator.pop(c),
                                child: const Text('Tamam, Teşekkürler'),
                              ),
                            ],
                          ),
                        );
                        } // end if loadingContext.mounted
                      });

                      // Bu return, yükleniyor ekranının tasarımıdır
                      return const AlertDialog(
                        content: Row(
                          children: [
                            CircularProgressIndicator(color: Colors.green),
                            SizedBox(width: 20),
                            Expanded(
                              child: Text(
                                "Tarlanıza özel Zirai Takvim hazırlanıyor...\nLütfen bekleyin.",
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  // --- İNANILMAZ DETAYLI KART WIDGET'I ---
  Widget _buildAdvancedCropCard(dynamic crop) {
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
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    crop['season'] ?? '',
                    style: const TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(),
            ),

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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Bilimsel Adı: ${result['data']['scientific_name'] ?? 'Bilinmiyor'}\nFamilya: ${details['family'] ?? 'Bilinmiyor'}',
          style: const TextStyle(
            fontStyle: FontStyle.italic,
            color: Colors.grey,
            fontSize: 16,
            height: 1.4,
          ),
        ),
        const Divider(height: 30),

        // --- YENİ: HALK DİLİNDEKİ ADI ---
        _buildInfoBombCard(
          Icons.record_voice_over,
          'Halk Arasındaki Adı',
          details['halk_dilindeki_adi'] ?? 'Bilinmiyor',
          Colors.purple.shade700,
          isBold: true,
        ),

        // 1. Başarı Şansı (Dikkat Çekici)
        Card(
          color: Colors.green.shade50,
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.analytics, color: Colors.green, size: 35),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Konuma Göre Yetişme Şansı',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        details['basari_sansi'] ?? 'Hesaplanamadı',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // 2. Konum Yorumu
        _buildInfoBombCard(
          Icons.thermostat,
          'Sıcaklık ve pH Uyumu',
          details['konum_yorumu'],
          Colors.orange.shade700,
        ),

        // 3. Nasıl Yetiştirilir?
        _buildInfoBombCard(
          Icons.agriculture,
          'Genel Yetiştirme Adımları',
          details['nasil_yetistirilir'],
          Colors.blue.shade700,
        ),

        // 4. Bakım Püf Noktası
        _buildInfoBombCard(
          Icons.wb_incandescent,
          'Uzman Püf Noktası',
          details['bakim_puf_noktasi'],
          Colors.amber.shade900,
          isBold: true,
        ),

        // 5. Hastalık Riskleri
        _buildInfoBombCard(
          Icons.bug_report,
          'Hastalık ve Zararlı Riskleri',
          details['hastalik_riskleri'],
          Colors.red.shade700,
        ),

        // 6. Sulama Takvimi
        _buildInfoBombCard(
          Icons.water_drop,
          'Sulama Takvimi ve Yöntemi',
          details['sulama_takvimi'],
          Colors.cyan.shade700,
        ),

        // 7. Gübre Önerisi
        _buildInfoBombCard(
          Icons.science,
          'Gübre Önerisi ve Dozajı',
          details['gubre_onerisi'],
          Colors.brown.shade700,
        ),

        // 8. Hasat Zamanı
        _buildInfoBombCard(
          Icons.calendar_month,
          'Hasat Zamanı ve Olgunluk',
          details['hasat_zamani'],
          Colors.deepPurple.shade700,
        ),

        // 9. Depolama ve Saklama
        _buildInfoBombCard(
          Icons.warehouse,
          'Depolama ve Saklama Koşulları',
          details['depolama_saklama'],
          Colors.blueGrey.shade700,
        ),

        const SizedBox(height: 20),


        // --- YENİ: TARLAYA ÖZEL PLANLAMA BUTONU ---
        Builder(
          builder: (context) {
            return FilledButton.icon(
              onPressed: () =>
                  _showFieldSelectionDialog(context, result['data']['title']),
              icon: const Icon(Icons.edit_calendar),
              label: const Text('Kayıtlı Tarlama Ek ve Planla'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(55),
                backgroundColor: Colors.teal.shade700,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            );
          },
        ),
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
