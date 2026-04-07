import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'data/app_database.dart';
import 'firebase_options.dart';
import 'screens/navigation_screen.dart';
import 'screens/auth_screen.dart';
import 'services/notification_service.dart';
import 'services/offline_encyclopedia.dart';
import 'services/app_providers.dart';
import 'services/local_data_repository.dart';
import 'services/background_sync_service.dart';
import 'theme/app_theme.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('tr_TR', null);
  await initializeDateFormatting('en_US', null);
  Intl.defaultLocale = 'tr_TR';

  // 1. Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // 2. Env vars
  await dotenv.load(fileName: ".env");

  // 3. Hive local DB
  await Hive.initFlutter();
  await Hive.openBox('agri_history');
  await Hive.openBox('user_crops');
  await Hive.openBox('recognized_plants');
  await Hive.openBox('plant_cache'); // ortak bitki bilgi veritabanı
  await Hive.openBox('fieldsBox');
  await Hive.openBox('settingsBox');
  await Hive.openBox('sim_results_cache');


  // 4. Push notification service
  await NotificationService.initialize();

  // 5. Offline encyclopedia — pre-seed plant_cache with static Turkish crop data
  OfflineEncyclopedia.preSeed(); // fire-and-forget; doesn't block startup

  final database = AppDatabase();
  final localDataRepository = LocalDataRepository(database: database);
  await localDataRepository.bootstrapFromLegacyHive();

  // 6. Background periodic tasks (Android'de aktif, diğer platformlarda no-op)
  await BackgroundSyncService.initialize();

  runApp(
    ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWithValue(database),
      ],
      child: const SmartAgriApp(),
    ),
  );
}

class SmartAgriApp extends StatelessWidget {
  const SmartAgriApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
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
      // Uygulamayı tüm özellikleriyle (navigasyon menüsüyle) başlatmak için
      // giriş kapısına geri dönüyoruz.
      home: const _AuthGate(),
    );
  }
}

/// Listens to Firebase Auth state and routes to Auth or Main screen.
class _AuthGate extends ConsumerWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authStateAsync = ref.watch(authStateChangesProvider);

    return authStateAsync.when(
      loading: () => const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF00E676)),
        ),
      ),
      error: (_, __) => const AuthScreen(),
      data: (user) {
        if (user != null) {
          return const MainNavigationScreen();
        }
        return const AuthScreen();
      },
    );
  }
}
