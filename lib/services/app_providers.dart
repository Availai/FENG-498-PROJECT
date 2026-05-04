import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../data/app_database.dart';
import '../data/turkish_crops_repository.dart';
import 'crop_scoring_service.dart';
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
import 'rules/crop_rule_set.dart';
import 'rules/recommendation.dart';
import 'rules/recommendation_ledger.dart';
import 'rules/sunflower_rules.dart';
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
  return ref.watch(taskDirectiveServiceProvider).generate(
        fieldCrops: crops,
        activities: activities,
        scheduledEvents: scheduled,
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
  ];
});

/// Tavsiye gösterim defteri — Hive box `recommendation_ledger`. Cooldown
/// kontrolü ve aktivite sonrası temizleme buradan yürür.
final recommendationLedgerProvider = Provider<RecommendationLedger>((ref) {
  return RecommendationLedger(Hive.box(RecommendationLedger.boxName));
});

/// Tarla bazında ayçiçeği (ve gelecekte eklenecek) deterministik tavsiyeleri.
/// `fieldGuideProvider` ile aynı stream'leri dinler → aktivite logu yazılınca,
/// büyüme yeniden hesaplanınca, hava verisi tazelenince otomatik invalidate.
///
/// Akış:
///   1. Aktivite/growth/plant instances/forecast topla
///   2. Her ekin için match eden RuleSet → evaluate → Recommendation listesi
///   3. Ledger ile cooldown filtresi uygula
///   4. Severity'ye göre sırala (acil → önemli → bilgi)
final fieldRecommendationsProvider = FutureProvider.family
    .autoDispose<List<Recommendation>, String>((ref, fieldId) async {
  final repo = ref.watch(localDataRepositoryProvider);
  final ruleSets = ref.watch(cropRuleSetsProvider);
  final ledger = ref.watch(recommendationLedgerProvider);
  if (ruleSets.isEmpty) return const [];

  final crops = await repo.loadFieldCrops(fieldId);
  if (crops.isEmpty) return const [];

  final activities = await ref.watch(fieldActivityLogProvider(fieldId).future);
  final growthList =
      await ref.watch(fieldGrowthStatesProvider(fieldId).future);
  final plantInstances =
      await ref.watch(fieldPlantInstancesProvider(fieldId).future);

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

  // Activity log → ActivityRecord (yeni → eski)
  final actRecords = <ActivityRecord>[];
  for (final a in activities) {
    final dateRaw = a['date'];
    DateTime? at;
    if (dateRaw is DateTime) {
      at = dateRaw;
    } else if (dateRaw is String) {
      at = DateTime.tryParse(dateRaw);
    }
    if (at == null) continue;
    actRecords.add(ActivityRecord(
      type: a['type']?.toString() ?? '',
      subtype: a['subtype']?.toString(),
      at: at,
      plantInstanceId: a['plant_instance_id']?.toString(),
      quantity: (a['quantity'] as num?)?.toDouble(),
    ));
  }
  actRecords.sort((a, b) => b.at.compareTo(a.at));

  // Plant instances → snapshot
  final plantSnaps = <PlantInstanceSnapshot>[];
  for (final p in plantInstances) {
    final flags = <String>[];
    final raw = p.conditionFlagsJson;
    if (raw != null && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          for (final v in decoded) {
            if (v is String && v.isNotEmpty) flags.add(v);
          }
        }
      } catch (_) {}
    }
    plantSnaps.add(PlantInstanceSnapshot(
      id: p.id,
      cropId: p.cropId,
      healthStatus: p.healthStatus,
      conditionFlags: flags,
    ));
  }

  // Saatlik forecast — koordinat varsa
  HourlyForecast? hourly;
  final fieldMap = await repo.loadFieldById(fieldId);
  final lat = (fieldMap?['latitude'] as num?)?.toDouble();
  final lng = (fieldMap?['longitude'] as num?)?.toDouble();
  if (lat != null && lng != null) {
    try {
      hourly = await ref
          .watch(weatherSoilServiceProvider)
          .fetchHourlyForecast(latitude: lat, longitude: lng);
    } catch (_) {}
  }

  final now = DateTime.now();
  final out = <Recommendation>[];

  for (final crop in crops) {
    final cropId = crop['id']?.toString();
    final cropName = crop['name']?.toString() ?? '';
    if (cropId == null || cropId.isEmpty) continue;

    // Bu ekine match eden ilk RuleSet'i çalıştır.
    CropRuleSet? matched;
    for (final rs in ruleSets) {
      if (rs.matches(cropName)) {
        matched = rs;
        break;
      }
    }
    if (matched == null) continue;

    final plantedRaw = crop['planted_date']?.toString();
    DateTime? planted;
    if (plantedRaw != null && plantedRaw.isNotEmpty) {
      planted = DateTime.tryParse(plantedRaw);
      if (planted == null) {
        final parts = plantedRaw.split('.');
        if (parts.length == 3) {
          planted = DateTime.tryParse(
              '${parts[2]}-${parts[1].padLeft(2, '0')}-${parts[0].padLeft(2, '0')}');
        }
      }
    }

    final ctx = RuleEvaluationContext(
      fieldId: fieldId,
      crop: FieldCropSnapshot(
        id: cropId,
        name: cropName,
        plantedDate: planted,
      ),
      growth: growthMap[cropId],
      recentActivities: actRecords,
      plantInstances: plantSnaps,
      hourly: hourly,
      now: now,
    );

    final recs = matched.evaluate(ctx);
    for (final r in recs) {
      // Cooldown'da mı?
      if (ledger.isOnCooldown(
        ruleKey: r.ruleKey,
        target: r.target,
        cooldownHours: r.cooldownHours,
        now: now,
      )) {
        continue;
      }
      // ClearOnActivity — son aktivite penceresinde varsa tavsiye expire.
      bool cleared = false;
      for (final clear in r.clearOnActivities) {
        for (final a in actRecords) {
          if (a.type != clear.activityType) continue;
          if (clear.subtype != null && a.subtype != clear.subtype) continue;
          // Tekil bitki hedefi varsa aktivite de aynı bitkide olmalı.
          if (r.target.plantInstanceId != null &&
              a.plantInstanceId != r.target.plantInstanceId) {
            continue;
          }
          final hours = now.difference(a.at).inMinutes / 60.0;
          if (hours <= clear.withinHours) {
            cleared = true;
            break;
          }
        }
        if (cleared) break;
      }
      if (cleared) continue;
      out.add(r);
    }
  }

  // Severity'ye göre sırala — critical en üste.
  int order(AlertSeverity s) {
    switch (s) {
      case AlertSeverity.critical:
        return 0;
      case AlertSeverity.warning:
        return 1;
      case AlertSeverity.info:
        return 2;
    }
  }

  out.sort((a, b) => order(a.severity).compareTo(order(b.severity)));
  return out;
});
