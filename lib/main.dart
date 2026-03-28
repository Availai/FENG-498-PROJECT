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

class _AgriDashboardState extends State<AgriDashboard> {
  String _temp = '--',
      _humidity = '--',
      _wind = '--',
      _ph = '--',
      _location = 'Aranıyor...';
  bool _isLoading = false;

  // Çevre değişkeninden API anahtarını güvenli çekiyoruz
  static String get _weatherKey => dotenv.env['WEATHER_API_KEY'] ?? '';

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  Future<void> _refreshData() async {
    setState(() => _isLoading = true);
    try {
      await _ensureLocationPermission();
      final pos = await _getCurrentPosition();

      // Detaylı Adres Çözümleme
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
        http.get(
          Uri.parse(
            'https://api.openweathermap.org/data/2.5/weather?lat=${pos.latitude}&lon=${pos.longitude}&appid=$_weatherKey&units=metric&lang=tr',
          ),
        ),
        http.get(
          Uri.parse(
            'https://rest.isric.org/soilgrids/v2.0/properties/query?lon=${pos.longitude}&lat=${pos.latitude}&property=phh2o&depth=0-5cm&value=mean',
          ),
        ),
      ]);

      if (mounted) {
        setState(() {
          _location = detailedAddress;

          // Hava Durumu Verisi
          if (results[0].statusCode == 200) {
            final data = jsonDecode(results[0].body);
            _temp = '${data['main']['temp'].round()}°C';
            _humidity = '%${data['main']['humidity']}';
            _wind = (data['wind'] != null && data['wind']['speed'] != null)
                ? '${data['wind']['speed']} m/s'
                : 'N/A';
          } else {
            _temp = '--';
            _humidity = '--';
            _wind = '--';
          }

          // Toprak pH Verisi
          if (results[1].statusCode == 200) {
            final data = jsonDecode(results[1].body);
            final val =
                data['properties']?['layers']?[0]?['depths']?[0]?['values']?['mean'];
            if (val != null) {
              _ph = (val / 10.0).toStringAsFixed(1);
            } else {
              _ph =
                  'Veri Yok (Şehir İçi)'; // Emülatör / Betonarme alan kontrolü
            }
          } else {
            _ph = 'API Hatası';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _location = 'Konum veya internet hatası!';
          _temp = '--';
          _humidity = '--';
          _ph = '--';
        });
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Anlık Çevre Analizi'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _refreshData),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildInfoCard('📍 Mevcut Konum', _location, Colors.blue),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildInfoCard(
                          '🌡️ Sıcaklık',
                          _temp,
                          Colors.orange,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildInfoCard('💧 Nem', _humidity, Colors.cyan),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildInfoCard(
                          '💨 Rüzgar',
                          _wind,
                          Colors.blueGrey,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildInfoCard('🌿 Toprak pH', _ph, Colors.teal),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  FilledButton.icon(
                    onPressed: () async {
                      final box = Hive.box('agri_history');
                      await box.add({
                        'date': DateFormat(
                          'dd.MM.yyyy HH:mm',
                        ).format(DateTime.now()),
                        'temp': _temp,
                        'ph': _ph,
                        'location': _location
                            .split('\n')
                            .first, // Sadece Adres kısmını al
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Veriler arşive kaydedildi!'),
                        ),
                      );
                    },
                    icon: const Icon(Icons.save),
                    label: const Text('BU ANALİZİ ARŞİVLE'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildInfoCard(String title, String value, Color color) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              style: TextStyle(color: color, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// 2. SEKME: TARLALARIM
// ─────────────────────────────────────────────

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

      // İŞTE YENİLEDİĞİMİZ ÇİFT BUTONLU YAPI BURASI
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton.extended(
            heroTag: 'calcBtn',
            onPressed: () async {
              try {
                // Kullanıcının anlık konumunu alıp haritayı o noktada başlatıyoruz
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
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('Konum hatası: $e')));
              }
            },
            backgroundColor: Colors.blue.shade700,
            icon: const Icon(Icons.map, color: Colors.white),
            label: const Text(
              'Haritadan Tarla Çiz',
              style: TextStyle(color: Colors.white),
            ),
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
          if (b.isEmpty)
            return const Center(child: Text('Henüz ekili tarla yok.'));
          return ListView.builder(
            itemCount: b.length,
            itemBuilder: (context, i) {
              final item = b.getAt(i);
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Colors.green,
                    child: Icon(Icons.grass, color: Colors.white),
                  ),
                  title: Text(
                    item['name'],
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text('Ekim: ${item['date']}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
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

  void _showAddDialog(BuildContext context, Box box) {
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
                                  try {
                                    final pos = await _getCurrentPosition();
                                    // HİBRİT SERVİSİ ÇAĞIRIYORUZ
                                    final res = await AgriService.analyzeImage(
                                      _photos[i],
                                      pos.latitude,
                                      pos.longitude,
                                    );
                                    if (mounted) {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => AnalysisResultScreen(
                                            image: _photos[i],
                                            result: res,
                                          ),
                                        ),
                                      );
                                    }
                                  } catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Hata: $e')),
                                    );
                                  } finally {
                                    if (mounted)
                                      setState(() => _isLoading = false);
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
          if (b.isEmpty)
            return const Center(child: Text('Kayıtlı analiz yok.'));
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
          if (b.isEmpty)
            return const Center(child: Text('Henüz bir sonuç kaydedilmedi.'));
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
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bilimsel Adı: ${details['scientific_name'] ?? 'Bilinmiyor'}',
              style: const TextStyle(
                fontStyle: FontStyle.italic,
                color: Colors.grey,
                fontSize: 16,
              ),
            ),
            const Divider(height: 20),
            Text(
              'Özellikler: ${details['features']}',
              style: const TextStyle(height: 1.4),
            ),
            const SizedBox(height: 10),
            Text(
              'Bakım: ${details['care']}',
              style: const TextStyle(height: 1.4),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(IconData icon, String title, String? content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: Colors.green, size: 20),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(content ?? 'Bilgi Yok', style: const TextStyle(height: 1.4)),
      ],
    );
  }
}
