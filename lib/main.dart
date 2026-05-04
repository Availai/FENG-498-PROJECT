import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'dart:convert';

import 'data/app_database.dart';
import 'firebase_options.dart';
import 'screens/daily_guide_screen.dart';
import 'screens/field_detail_screen.dart';
import 'screens/navigation_screen.dart';
import 'screens/auth_screen.dart';
import 'services/notification_service.dart';
import 'services/offline_encyclopedia.dart';
import 'services/app_providers.dart';
import 'services/background_sync_service.dart';
import 'theme/app_theme.dart';
import 'widgets/crop_render_factory.dart';
import 'widgets/floating_toast.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart';

void main() {
  // Tüm async hataları tek yerde yakala — startup'ta bir future patlasa bile
  // app donmasın. debugPrint log'a düşsün; kritik olanlar _BootstrapErrorApp
  // üzerinden kullanıcıya gösterilir.
  runZonedGuarded<Future<void>>(() async {
    WidgetsFlutterBinding.ensureInitialized();

    try {
      final database = await _bootstrap();

      // ErrorWidget yerine sessiz placeholder — tek widget hatası app'i
      // kırmızı ekrana düşürmesin.
      ErrorWidget.builder = (details) {
        debugPrint('Widget build hatası: ${details.exception}');
        return const SizedBox.shrink();
      };

      runApp(
        ProviderScope(
          overrides: [
            appDatabaseProvider.overrideWithValue(database),
          ],
          child: const SmartAgriApp(),
        ),
      );
    } catch (e, st) {
      debugPrint('Bootstrap fatal: $e\n$st');
      runApp(_BootstrapErrorApp(error: e));
    }
  }, (error, stack) {
    // Zone içinden sızan yakalanmamış hatalar sadece loglanır.
    debugPrint('Zoned uncaught: $error\n$stack');
  });
}

/// Kritik init'leri paralel yapar; non-kritikleri ilk frame sonrasına erteler.
Future<AppDatabase> _bootstrap() async {
  // 1) Lokal tarih formatlama — eş zamanlı başlatılabilir.
  final localeSetup = Future.wait([
    initializeDateFormatting('tr_TR', null),
    initializeDateFormatting('en_US', null),
  ]);

  // 2) Paralel: Firebase + dotenv + Hive init + tarih — hiçbiri diğerine bağlı
  //    değil. `.env` yoksa sessiz yut; app tema/placeholder key'lerle çalışır.
  await Future.wait([
    Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform),
    dotenv.load(fileName: '.env').catchError((e) {
      debugPrint('.env yüklenemedi: $e');
    }),
    Hive.initFlutter(),
    localeSetup,
  ]);

  Intl.defaultLocale = 'tr_TR';

  // 3) Tüm Hive box'ları paralel aç — tek tek sıralamak 200-400ms ekliyordu.
  const boxNames = <String>[
    'agri_history',
    'user_crops',
    'recognized_plants',
    'plant_cache',
    'fieldsBox',
    'settingsBox',
    'sim_results_cache',
    'cost_ledger',
    'crop_history',
    'fuel_cache',
    'crop_protocol_state',
    'recommendation_ledger',
  ];
  await Future.wait(boxNames.map((name) => Hive.openBox(name)));

  // 4) Drift — LazyDatabase olduğu için bu constructor I/O tetiklemez; ilk
  //    query'de açılır. Bootstrap kritik yoluna sokma.
  final database = AppDatabase();

  // 5) Non-kritik servisler ilk frame'den sonra yüklensin — push notification
  //    channel, WorkManager kaydı ve encyclopedia seed app'in interaktif
  //    olmasını bekletmez.
  WidgetsBinding.instance.addPostFrameCallback((_) {
    Future(() async {
      try {
        await NotificationService.initialize();
      } catch (e) {
        debugPrint('NotificationService init hata: $e');
      }
      try {
        await BackgroundSyncService.initialize();
      } catch (e) {
        debugPrint('BackgroundSyncService init hata: $e');
      }
      try {
        OfflineEncyclopedia.preSeed();
      } catch (e) {
        debugPrint('OfflineEncyclopedia preSeed hata: $e');
      }
      try {
        // 292-bitki crop_images.json eşlemesini yükle — Türkçe isim →
        // gerçek asset dosyası dönüşümü için tarla haritasında kullanılır.
        await CropImageMap.load();
      } catch (e) {
        debugPrint('CropImageMap load hata: $e');
      }
    });
  });

  return database;
}

class SmartAgriApp extends StatefulWidget {
  const SmartAgriApp({super.key});

  /// Bildirime tıklandığında `NotificationService` bu key üzerinden gezinir.
  static final navigatorKey = GlobalKey<NavigatorState>();

  @override
  State<SmartAgriApp> createState() => _SmartAgriAppState();
}

class _SmartAgriAppState extends State<SmartAgriApp> {
  @override
  void initState() {
    super.initState();
    // Bildirime tıklanınca payload decode et → ilgili ekrana git.
    NotificationService.onNotificationTap = (payload) {
      try {
        final data = jsonDecode(payload) as Map<String, dynamic>;
        final type = data['type']?.toString() ?? 'guide';
        final fieldId = data['fieldId']?.toString() ?? '';
        final fieldName = data['fieldName']?.toString();
        if (fieldId.isEmpty) return;

        final nav = SmartAgriApp.navigatorKey.currentState;
        if (nav == null) return;

        if (type == 'field') {
          // Tarla haritası ekranı — fieldData async yüklenir.
          nav.push(MaterialPageRoute(
            builder: (_) => _NotificationFieldLaunchPage(
              fieldId: fieldId,
              fieldName: fieldName,
            ),
          ));
        } else {
          // 'guide' ve diğer tipler → DailyGuideScreen
          nav.push(MaterialPageRoute(
            builder: (_) =>
                DailyGuideScreen(fieldId: fieldId, fieldName: fieldName),
          ));
        }
      } catch (_) {}
    };
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: SmartAgriApp.navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'Smart Agri',
      locale: const Locale('tr', 'TR'),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('tr', 'TR'),
        Locale('en', 'US'),
      ],
      theme: buildAppTheme(),
      home: const _AuthGate(),
    );
  }
}

/// Listens to Firebase Auth state and routes to Auth or Main screen.
class _AuthGate extends ConsumerStatefulWidget {
  const _AuthGate();

  @override
  ConsumerState<_AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends ConsumerState<_AuthGate> {
  String? _lastBootstrappedUid;

  /// Auth sonrası legacy Hive→Drift geçişini arka planda yürütür. UI
  /// MainNavigation'ı hemen açar; migrasyon bitince `fieldMapsProvider`
  /// invalidate edilir, dashboard kartları kendiliğinden tazelenir.
  void _runPostAuthBootstrap(String uid) {
    if (_lastBootstrappedUid == uid) return;
    _lastBootstrappedUid = uid;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final repo = ref.read(localDataRepositoryProvider);
      Future(() async {
        try {
          await repo.bootstrapFromLegacyHive();
          if (!mounted) return;
          // Drift watch akışını tazele — yeni migrate olan tarlalar görünsün.
          ref.invalidate(fieldMapsProvider);
        } catch (e) {
          debugPrint('bootstrapFromLegacyHive hata: $e');
          if (mounted) {
            AppToast.show(
              context,
              message:
                  'Eski veriler aktarılamadı. Uygulama çalışmaya devam ediyor.',
              type: ToastType.warning,
            );
          }
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final authStateAsync = ref.watch(authStateChangesProvider);

    return authStateAsync.when(
      loading: () => const Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF00E676)),
        ),
      ),
      error: (_, __) => const AuthScreen(),
      data: (user) {
        if (user != null) {
          _runPostAuthBootstrap(user.uid);
          return const MainNavigationScreen();
        }
        return const AuthScreen();
      },
    );
  }
}

/// Bildirime tıklandığında fieldId'den fieldData'yı async yükler,
/// ardından FieldDetailScreen'e geçer. Yükleme sırasında spinner gösterir;
/// hata/veri-yok durumunda DailyGuideScreen'e düşer.
class _NotificationFieldLaunchPage extends ConsumerStatefulWidget {
  final String fieldId;
  final String? fieldName;

  const _NotificationFieldLaunchPage({
    required this.fieldId,
    this.fieldName,
  });

  @override
  ConsumerState<_NotificationFieldLaunchPage> createState() =>
      _NotificationFieldLaunchPageState();
}

class _NotificationFieldLaunchPageState
    extends ConsumerState<_NotificationFieldLaunchPage> {
  @override
  void initState() {
    super.initState();
    _navigate();
  }

  Future<void> _navigate() async {
    try {
      final repo = ref.read(localDataRepositoryProvider);
      final fieldData = await repo.loadFieldById(widget.fieldId);
      if (!mounted) return;
      if (fieldData != null) {
        Navigator.of(context).pushReplacement(MaterialPageRoute(
          builder: (_) => FieldDetailScreen(fieldData: fieldData),
        ));
      } else {
        _fallback();
      }
    } catch (_) {
      if (mounted) _fallback();
    }
  }

  void _fallback() {
    Navigator.of(context).pushReplacement(MaterialPageRoute(
      builder: (_) => DailyGuideScreen(
        fieldId: widget.fieldId,
        fieldName: widget.fieldName,
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF0D1F13),
      body: Center(
        child: CircularProgressIndicator(color: Color(0xFF00E676)),
      ),
    );
  }
}

/// Bootstrap hatası (Firebase/Hive/Drift fatal) — kullanıcıya Türkçe mesaj +
/// yeniden dene butonu. Süreci yeniden çalıştırmak için main()'i tekrar çağırır.
class _BootstrapErrorApp extends StatelessWidget {
  const _BootstrapErrorApp({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: const Color(0xFF1B5E20),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, color: Colors.white, size: 56),
                const SizedBox(height: 16),
                const Text(
                  'Uygulama başlatılamadı',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Bir hata oluştu: $error',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: () => main(),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Yeniden Dene'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
