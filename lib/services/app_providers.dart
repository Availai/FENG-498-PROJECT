import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../data/app_database.dart';
import '../data/turkish_crops_repository.dart';
import 'crop_scoring_service.dart';
import 'api/soilgrids_api.dart';
import 'local_data_repository.dart';
import 'repositories/calendar_repository.dart';
import 'repositories/field_repository.dart';
import 'repositories/history_repository.dart';
import 'repositories/weather_repository.dart';
import 'repositories/sync_repository.dart';
import 'repositories/auth_repository.dart';
import 'sync_service.dart';
import 'task_directive_service.dart';
import 'field_state_service.dart';
import 'crop_schedule_seeder.dart';
import 'crop_daily_plan.dart';
import 'growth_engine.dart';
import 'weather_soil_service.dart';
import 'backend_service.dart';
import 'disease_diagnosis_service.dart';
import 'activity_logger.dart';
import 'guide_engine.dart';
import 'live_todo_service.dart';
import 'soil_fertilization_service.dart';
import 'rules/crop_rule_set.dart';
import 'rules/recommendation.dart';
import 'rules/recommendation_ledger.dart';
import 'rules/sunflower_rules.dart';
import 'rules/wheat_rules.dart';
import 'api/sync_api_client.dart';

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  throw UnimplementedError('AppDatabase override edilmedi.');
});

final localDataRepositoryProvider = Provider<LocalDataRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final uid = ref.watch(authStateChangesProvider).valueOrNull?.uid;
  return LocalDataRepository(database: db, currentUid: uid);
});

/// GDD + aktivite delta → CropGrowthStates üreten singleton. Tek bir
/// AppDatabase üstünde çalışır; UI katmanı `watch(cropId)` ile canlı okur.
final growthEngineProvider = Provider<GrowthEngine>((ref) {
  return GrowthEngine(ref.watch(appDatabaseProvider));
});

/// `logActivity` + `GrowthEngine.recompute` zincirlemesini tek yerde tutar.
/// UI tarafı doğrudan `localDataRepository.logActivity` yerine bu provider'ı
/// kullanmalı — böylece recompute hiçbir yerde unutulmaz.
final activityLoggerProvider = Provider<ActivityLogger>((ref) {
  return ActivityLogger(
    repository: ref.watch(localDataRepositoryProvider),
    growthEngine: ref.watch(growthEngineProvider),
  );
});

/// Bitki tarlaya eklendiğinde sezonluk sulama/gübreleme/ilaçlama programını
/// takvime yazan seeder.
final cropScheduleSeederProvider = Provider<CropScheduleSeeder>((ref) {
  return CropScheduleSeeder(ref.watch(appDatabaseProvider));
});

final settingsBoxProvider = Provider<Box>((ref) {
  return Hive.box('settingsBox');
});

final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final repository =
      AuthRepository(firebaseAuth: ref.watch(firebaseAuthProvider));
  BackendService.configure(authTokenProvider: repository.getIdToken);
  return repository;
});

final authStateChangesProvider = StreamProvider<User?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges();
});

final fieldRepositoryProvider = Provider<FieldRepository>((ref) {
  return FieldRepository(
      localDataRepository: ref.watch(localDataRepositoryProvider));
});

final calendarRepositoryProvider = Provider<CalendarRepository>((ref) {
  return CalendarRepository(
      localDataRepository: ref.watch(localDataRepositoryProvider));
});

final weatherRepositoryProvider = Provider<WeatherRepository>((ref) {
  return WeatherRepository(settingsBox: ref.watch(settingsBoxProvider));
});

final syncRepositoryProvider = Provider<SyncRepository>((ref) {
  return SyncRepository(database: ref.watch(appDatabaseProvider));
});

final syncServiceProvider = Provider<SyncService>((ref) {
  return SyncService(
    syncRepository: ref.watch(syncRepositoryProvider),
    database: ref.watch(appDatabaseProvider),
  );
});

final backendBaseUrlProvider = Provider<String>((ref) {
  return dotenv.env['BACKEND_BASE_URL'] ?? 'http://10.0.2.2:8000';
});

final syncApiClientProvider = Provider<SyncApiClient>((ref) {
  return SyncApiClient(
    baseUrl: ref.watch(backendBaseUrlProvider),
    authTokenProvider: () => ref.read(authRepositoryProvider).getIdToken(),
  );
});

final fieldMapsProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  return ref.watch(fieldRepositoryProvider).watchFields();
});

/// Uygulama foreground'a geldiğinde otomatik senkronizasyon çalıştır.
/// Bu provider ilk kez okunduğunda push cycle'ı tetikler.
final foregroundSyncProvider = FutureProvider<void>((ref) async {
  final syncService = ref.read(syncServiceProvider);
  final apiClient = ref.read(syncApiClientProvider);
  await syncService.runForegroundSync(apiClient: apiClient);
});

/// AI analiz + anlık çevre geçmişi için Hive facade repository.
final historyRepositoryProvider = Provider<HistoryRepository>((ref) {
  return HistoryRepository();
});

/// 292 Türk bitkisi SQLite asset singleton'unu Riverpod grafiğine bağlar.
/// Yeni kod .instance yerine bu provider'ı okumalı (singleton backing kalır).
final turkishCropsRepositoryProvider = Provider<TurkishCropsRepository>((ref) {
  return TurkishCropsRepository.instance;
});

/// Hava + toprak pH çevre-verisi servisi (Open-Meteo + SoilGrids).
/// Widget'lar doğrudan http.get kullanmamalı; bu servisi çağırmalı.
final weatherSoilServiceProvider = Provider<WeatherSoilService>((ref) {
  return const WeatherSoilService();
});

/// 292 bitki skorlama döngüsünü background isolate'a taşır.
/// Widget'lar `TurkishCrop.scoreFor`'u döngüde çağırmak yerine bu servisi
/// kullanmalı — UI thread frame drop yaşamaz.
final cropScoringServiceProvider = Provider<CropScoringService>((ref) {
  return CropScoringService(ref.watch(turkishCropsRepositoryProvider));
});

/// Tarla bazında son aktiviteleri (sulama/gübre/ilaç/hasat) Drift stream
/// olarak sağlar. Görevler modalı bunu dinler → her log sonrası yönergeler
/// anında tazelenir.
final fieldActivityLogProvider = StreamProvider.family
    .autoDispose<List<Map<String, dynamic>>, String>((ref, fieldId) {
  return ref
      .watch(localDataRepositoryProvider)
      .watchActivityLog(fieldId: fieldId, limit: 200);
});

/// Tarla bazında canlı büyüme durumları. Görev modalı ve harita aynı
/// `CropGrowthStates` kaynağını okur; böylece görsel büyüme ile öneriler ayrışmaz.
final fieldGrowthStatesProvider = StreamProvider.family
    .autoDispose<List<CropGrowthState>, String>((ref, fieldId) {
  return ref.watch(growthEngineProvider).watchForField(fieldId);
});

/// Tarladaki tüm tekil bitki kayıtları (sağlık durumlu + standalone yerleşim).
/// Marker render'ında ve hastalık badge'inde kullanılır.
final fieldPlantInstancesProvider = StreamProvider.family
    .autoDispose<List<FieldPlantInstance>, String>((ref, fieldId) {
  return ref.watch(localDataRepositoryProvider).watchPlantInstances(fieldId);
});

/// Tarladaki bitki durum gözlemleri (PlantConditionEvents) — yeni gözlem
/// girildiğinde [fieldLiveTodosProvider] anında yenilensin diye expose edilir.
final fieldPlantConditionEventsProvider = StreamProvider.family
    .autoDispose<List<PlantConditionEvent>, String>((ref, fieldId) {
  return ref
      .watch(localDataRepositoryProvider)
      .watchPlantConditionEventsForField(fieldId);
});

/// Tarla ürünleri canlı stream — su aralığı / dikim tarihi / polygon
/// düzenlemesi sonrası tavsiye motoru anında yenilensin diye eklendi.
final fieldCropsStreamProvider = StreamProvider.family
    .autoDispose<List<Map<String, dynamic>>, String>((ref, fieldId) {
  return ref.watch(localDataRepositoryProvider).watchFieldCrops(fieldId);
});

/// Bitki hastalığı teşhis servisi — şimdilik stub. AI eklendiğinde tek
/// satır değişikliği ile `GeminiDiseaseDiagnosisService(...)` döndürülecek.
final diseaseDiagnosisServiceProvider = Provider<DiseaseDiagnosisService>((_) {
  return const StubDiseaseDiagnosisService();
});

/// Kural tabanlı "bugün ne yapmalıyım?" yönerge motoru. Saf servis; widget
/// katmanı sadece `generate()` çıktısını render eder.
final taskDirectiveServiceProvider = Provider<TaskDirectiveService>((ref) {
  return const TaskDirectiveService();
});

/// Birleşik rehber motoru — TaskDirective + alerts + insights tek çıktıda.
/// UI katmanı `fieldGuideProvider`'ı dinler; doğrudan motor erişimi nadirdir.
final guideEngineProvider = Provider<GuideEngine>((ref) {
  return const GuideEngine();
});

/// Tarla bazında canlı rehber sonucu — `GuideResult` döner. Aktivite log,
/// growth states, scheduled events ve hava forecast değişikliklerinde
/// otomatik invalidate olur (Riverpod stream watcher davranışı).
final fieldGuideProvider = FutureProvider.family
    .autoDispose<GuideResult, String>((ref, fieldId) async {
  final repo = ref.watch(localDataRepositoryProvider);
  final activities = await ref.watch(fieldActivityLogProvider(fieldId).future);
  final scheduled = await ref.watch(
    fieldScheduledAutoSeedProvider(fieldId).future,
  );
  final growthList = await ref.watch(
    fieldGrowthStatesProvider(fieldId).future,
  );

  // GrowthState[] → Map<cropId, GrowthSnapshot>
  final growthMap = <String, GrowthSnapshot>{};
  for (final g in growthList) {
    growthMap[g.cropId] = GrowthSnapshot(
      stageKey: g.currentStageKey,
      stageProgress: g.stageProgress,
      accumulatedGdd: g.accumulatedGdd,
      waterDeficitMm: g.waterDeficitMm,
      nStressIdx: g.nStressIdx,
      diseasePressure: g.diseasePressure,
      yieldMultiplier: g.yieldMultiplier,
    );
  }

  final fieldMap = await repo.loadFieldById(fieldId);
  final crops = await repo.loadFieldCrops(fieldId);
  final fieldStateRows = fieldMap == null
      ? const <CropFieldState>[]
      : ref.read(fieldStateServiceProvider).compute(
            field: fieldMap,
            fieldCrops: crops,
            activities: activities,
          );
  final fieldStateMap = {
    for (final state in fieldStateRows) state.cropId: state,
  };

  // Saatlik forecast — koordinat varsa
  HourlyForecast? hourly;
  final lat = (fieldMap?['latitude'] as num?)?.toDouble();
  final lng = (fieldMap?['longitude'] as num?)?.toDouble();
  if (lat != null && lng != null) {
    try {
      hourly = await ref
          .watch(weatherSoilServiceProvider)
          .fetchHourlyForecast(latitude: lat, longitude: lng);
    } catch (_) {}
  }

  return ref.read(guideEngineProvider).generate(
        fieldCrops: crops,
        activities: activities,
        scheduledEvents: scheduled,
        growthStates: growthMap,
        fieldStates: fieldStateMap,
        hourly: hourly,
      );
});

final fieldStateServiceProvider = Provider<FieldStateService>((ref) {
  return const FieldStateService();
});

/// Saf gün-gün plan üreteci. UI mevcut aktivite/auto-seed/growth stream'lerini
/// dinler, bu servisi çağırarak `CropDailyPlanResult` oluşturur. Sulama ve
/// yağmur değiştiğinde stream'ler tazelenir → ekran canlı güncellenir.
final cropDailyPlanServiceProvider = Provider<CropDailyPlanService>((ref) {
  return const CropDailyPlanService();
});

/// Dashboard'da tarla başına hızlı yönerge özeti — hava tahmini yüklenmez
/// (o online iştir, detail ekranında çalışır). Burada ekim + aktivite log'u
/// yeter: sulama aralığı doldu mu, hasat zamanı geldi mi, gübre gecikti mi.
/// Aktivite stream'i tazelendikçe FutureProvider otomatik yeniden koşar —
/// "Suladım" dedikten sonra dashboard da anında güncellenir.
final fieldDirectivesSummaryProvider = FutureProvider.family
    .autoDispose<List<FieldDirective>, String>((ref, fieldId) async {
  final repo = ref.watch(localDataRepositoryProvider);
  final activities = await ref.watch(fieldActivityLogProvider(fieldId).future);
  final crops = await repo.loadFieldCrops(fieldId);
  final scheduled =
      await repo.watchScheduledAutoSeedEvents(fieldId: fieldId).first;
  final fieldMap = await repo.loadFieldById(fieldId);
  final fieldStateRows = fieldMap == null
      ? const <CropFieldState>[]
      : ref.read(fieldStateServiceProvider).compute(
            field: fieldMap,
            fieldCrops: crops,
            activities: activities,
          );
  final fieldStateMap = {
    for (final state in fieldStateRows) state.cropId: state,
  };
  return ref.watch(taskDirectiveServiceProvider).generate(
        fieldCrops: crops,
        activities: activities,
        scheduledEvents: scheduled,
        fieldStates: fieldStateMap,
      );
});

/// Tek bir tarlanın auto_seed takvim planlarını canlı izler. UI direktif
/// listesi + takvim görünümü bunu tüketir.
final fieldScheduledAutoSeedProvider = StreamProvider.family
    .autoDispose<List<Map<String, dynamic>>, String>((ref, fieldId) {
  final repo = ref.watch(localDataRepositoryProvider);
  return repo.watchScheduledAutoSeedEvents(fieldId: fieldId);
});

// ─────────────────────────────────────────────────────────────────────────────
// Deterministik tavsiye motoru (ayçiçeği MVP-1; ileride çoklu bitki)
// ─────────────────────────────────────────────────────────────────────────────

/// Mevcut bitki kural setleri. Yeni bitki eklemek için bu listeye yeni bir
/// `CropRuleSet` implementation eklemek yeterli; UI değişmez.
final cropRuleSetsProvider = Provider<List<CropRuleSet>>((ref) {
  return const [
    SunflowerRules(),
    WheatRules(),
  ];
});

/// Tavsiye gösterim defteri — Hive box `recommendation_ledger`. Cooldown
/// kontrolü ve aktivite sonrası temizleme buradan yürür.
final recommendationLedgerProvider = Provider<RecommendationLedger>((ref) {
  return RecommendationLedger(Hive.box(RecommendationLedger.boxName));
});

final liveDecisionContextBuilderProvider =
    Provider<LiveDecisionContextBuilder>((ref) {
  return const LiveDecisionContextBuilder();
});

final liveTodoServiceProvider = Provider<LiveTodoService>((ref) {
  return const LiveTodoService();
});

/// Tarla bazında tek canlı yapılacaklar listesi. Eski direktifler,
/// ayçiçeği kural seti, aktivite sonrası temizleme, çevre/toprak bağlamı ve
/// güvenlik kapıları burada tek `Recommendation` listesine birleşir.
final fieldLiveTodosProvider = FutureProvider.family
    .autoDispose<List<Recommendation>, String>((ref, fieldId) async {
  final repo = ref.watch(localDataRepositoryProvider);
  final ruleSets = ref.watch(cropRuleSetsProvider);
  final ledger = ref.watch(recommendationLedgerProvider);

  // Ürün kayıtları stream'den geliyor — su aralığı/dikim tarihi düzenlemesi
  // sonrası provider anında yenilenir.
  final crops = await ref.watch(fieldCropsStreamProvider(fieldId).future);
  final activities = await ref.watch(fieldActivityLogProvider(fieldId).future);
  final scheduled = await ref.watch(
    fieldScheduledAutoSeedProvider(fieldId).future,
  );
  final growthList = await ref.watch(fieldGrowthStatesProvider(fieldId).future);
  final plantInstances =
      await ref.watch(fieldPlantInstancesProvider(fieldId).future);
  // Bitki durum gözlemleri (scouting → eşik onayı kaskadı) için stream
  // izlenir. İçeriği LiveDecisionContext'te kullanmıyoruz (recentActivities
  // CalendarEvents üzerinden yeterli), ama yeni gözlem eklendiğinde
  // tavsiyeler hemen yenilensin diye watch ediliyor.
  await ref.watch(fieldPlantConditionEventsProvider(fieldId).future);

  final now = DateTime.now();

  final fieldMap = await repo.loadFieldById(fieldId);
  final fieldStateRows = fieldMap == null
      ? const <CropFieldState>[]
      : ref.read(fieldStateServiceProvider).compute(
            field: fieldMap,
            fieldCrops: crops,
            activities: activities,
            now: now,
          );

  // Saatlik forecast — koordinat varsa
  HourlyForecast? hourly;
  final lat = (fieldMap?['latitude'] as num?)?.toDouble();
  final lng = (fieldMap?['longitude'] as num?)?.toDouble();
  final weatherService = ref.watch(weatherSoilServiceProvider);
  if (lat != null && lng != null) {
    try {
      hourly = await weatherService.fetchHourlyForecast(
        latitude: lat,
        longitude: lng,
      );
    } catch (_) {}
  }

  final environment = await _buildRuleEnvironmentSnapshot(
    repo: repo,
    fieldId: fieldId,
    fieldMap: fieldMap,
    hourly: hourly,
    weatherService: weatherService,
  );

  final context = ref.read(liveDecisionContextBuilderProvider).build(
        fieldId: fieldId,
        fieldCrops: crops,
        activities: activities,
        scheduledEvents: scheduled,
        growthRows: growthList,
        plantRows: plantInstances,
        fieldStateRows: fieldStateRows,
        ruleSets: ruleSets,
        hourly: hourly,
        environment: environment,
        ledger: ledger,
        now: now,
      );
  return ref.read(liveTodoServiceProvider).generate(context);
});

/// Geriye uyumluluk: eski ekranlar aynı provider adını kullanmaya devam eder.
final fieldRecommendationsProvider = FutureProvider.family
    .autoDispose<List<Recommendation>, String>((ref, fieldId) {
  return ref.watch(fieldLiveTodosProvider(fieldId).future);
});

/// "Şimdi yenile" aksiyonu — kullanıcı pull-to-refresh yaptığında veya
/// koordinat/parametre düzenlemesinden sonra UI bunu çağırır.
/// `fieldLiveTodosProvider`'ı geçersiz kılar; tüm bağlı stream'ler tazelenir.
final recomputeNowProvider =
    Provider.family<void Function(), String>((ref, fieldId) {
  return () => ref.invalidate(fieldLiveTodosProvider(fieldId));
});

Future<RuleEnvironmentSnapshot?> _buildRuleEnvironmentSnapshot({
  required LocalDataRepository repo,
  required String fieldId,
  required Map<String, dynamic>? fieldMap,
  required HourlyForecast? hourly,
  required WeatherSoilService weatherService,
}) async {
  final latest = await repo.loadLatestSuitabilityReport(fieldId);
  final report = _mapValue(latest?['report']);
  final weatherSnapshot = _mapValue(report?['weather_snapshot']);
  final soilSnapshot = _mapValue(report?['soil_snapshot']);

  final lat = (fieldMap?['latitude'] as num?)?.toDouble();
  final lng = (fieldMap?['longitude'] as num?)?.toDouble();
  DashboardConditions? conditions;
  Map<String, double>? satelliteSoil;
  SoilProfile? soilProfile;

  final sources = <String>[];
  if (weatherSnapshot != null || soilSnapshot != null) {
    sources.add('son analiz');
  }

  if (lat != null && lng != null) {
    conditions = weatherService.readCachedConditions(
      latitude: lat,
      longitude: lng,
    );
    if (conditions != null && !conditions.isEmpty) {
      sources.add('hava önbelleği');
    }

    final liveConditionsFuture = weatherService
        .fetchDashboardConditions(latitude: lat, longitude: lng)
        .timeout(const Duration(seconds: 5))
        .then<DashboardConditions?>((live) => live.isEmpty ? null : live)
        .catchError((_) => null);
    final satelliteFuture = BackendService.satelliteSoil(lat: lat, lng: lng)
        .timeout(const Duration(seconds: 6))
        .catchError((_) => null);
    final soilProfileFuture = SoilGridsApi.fetchProfile(lat: lat, lon: lng)
        .timeout(const Duration(seconds: 6))
        .then<SoilProfile?>((profile) => profile)
        .catchError((_) => null);

    await Future.wait<void>([
      liveConditionsFuture.then((live) {
        if (live != null) {
          conditions = live;
          sources.add('anlık hava');
        }
      }),
      satelliteFuture.then((soil) {
        if (soil != null) {
          satelliteSoil = soil;
          sources.add('uydu toprak');
        }
      }),
      soilProfileFuture.then((profile) {
        if (profile != null) {
          soilProfile = profile;
          sources.add('toprak profili');
        }
      }),
    ]);
  }

  final profileForNpk = soilProfile;
  final npk = profileForNpk == null
      ? null
      : SoilFertilizationService.estimateNpk(profileForNpk);
  final firstHourly =
      hourly?.slots.isNotEmpty == true ? hourly!.slots.first : null;

  final snapshot = RuleEnvironmentSnapshot(
    temperatureC: conditions?.temperatureC ??
        _firstDouble(weatherSnapshot, const ['temp', 'temperature_c']) ??
        firstHourly?.tempC,
    humidityPct: conditions?.humidity?.toDouble() ??
        _firstDouble(weatherSnapshot, const ['humidity', 'humidity_pct']) ??
        firstHourly?.humidity,
    windSpeedMs: conditions?.windSpeedMs ??
        _firstDouble(weatherSnapshot, const ['wind']),
    weeklyRainMm: _firstDouble(
      weatherSnapshot,
      const ['total_weekly_rain', 'weekly_rain_mm', 'weekly_rain'],
    ),
    soilMoisture: satelliteSoil?['moisture'] ??
        satelliteSoil?['soil_moisture'] ??
        _firstDouble(soilSnapshot, const ['soil_moisture', 'moisture']),
    soilTempC: satelliteSoil?['soil_temp_c'] ??
        _firstDouble(soilSnapshot, const ['soil_temp_c', 'soil_temp']),
    soilPh: soilProfile?.phReal ??
        conditions?.phH2O ??
        _firstDouble(soilSnapshot, const ['ph', 'soil_ph', 'ph_h2o']),
    nitrogenKgDekar: npk?.nitrogenKgDekar ??
        _firstDouble(soilSnapshot, const ['nitrogen_kg_dekar', 'n_kg_dekar']),
    phosphorusKgDekar: npk?.phosphorusKgDekar ??
        _firstDouble(soilSnapshot, const ['phosphorus_kg_dekar', 'p_kg_dekar']),
    potassiumKgDekar: npk?.potassiumKgDekar ??
        _firstDouble(soilSnapshot, const ['potassium_kg_dekar', 'k_kg_dekar']),
    fetchedAt: DateTime.now(),
    source:
        sources.isEmpty ? 'çevrimdışı varsayım' : sources.toSet().join(', '),
  );

  if (!snapshot.hasWeather && !snapshot.hasSoil && !snapshot.hasNpk) {
    return null;
  }
  return snapshot;
}

Map<String, dynamic>? _mapValue(Object? value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return null;
}

double? _firstDouble(Map<String, dynamic>? map, List<String> keys) {
  if (map == null) return null;
  for (final key in keys) {
    final value = map[key];
    if (value is num) return value.toDouble();
    if (value is String) {
      final parsed = double.tryParse(value.replaceAll(',', '.'));
      if (parsed != null) return parsed;
    }
  }
  return null;
}
