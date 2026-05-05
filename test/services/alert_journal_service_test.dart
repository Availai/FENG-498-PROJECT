import 'dart:convert';

import 'package:drift/drift.dart' hide isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:feng_498/data/activity_types.dart';
import 'package:feng_498/data/app_database.dart';
import 'package:feng_498/services/alert_journal_service.dart';
import 'package:feng_498/services/guide_engine.dart';
import 'package:feng_498/services/local_data_repository.dart';

void main() {
  late AppDatabase database;
  late AlertJournalService service;

  setUp(() async {
    database = AppDatabase(NativeDatabase.memory());
    service = AlertJournalService(
      repository: LocalDataRepository(database: database),
    );
    final now = DateTime.now().toUtc();
    await database.into(database.fields).insert(
          FieldsCompanion.insert(
            id: 'field-1',
            name: 'Yağmur tarlası',
            date: '05.05.2026',
            createdAt: now,
            updatedAt: now,
            areaDekar: const Value(1),
            areaSqm: const Value(1000),
          ),
        );
    await database.into(database.fieldCrops).insert(
          FieldCropsCompanion.insert(
            id: 'crop-1',
            fieldId: 'field-1',
            name: 'Ayçiçeği',
            zoneStart: 0,
            zoneEnd: 1,
            rowSpacingCm: 70,
            plantSpacingCm: 30,
            plantedDate: const Value('01.05.2026'),
            harvestDays: const Value(120),
            waterIntervalDays: const Value(7),
            createdAt: now,
            updatedAt: now,
          ),
        );
  });

  tearDown(() async {
    await database.close();
  });

  Future<List<CalendarEvent>> events() {
    return (database.select(database.calendarEvents)
          ..orderBy([(tbl) => OrderingTerm.asc(tbl.createdAt)]))
        .get();
  }

  Map<String, dynamic> metadata(CalendarEvent event) {
    return jsonDecode(event.metadataJson!) as Map<String, dynamic>;
  }

  test('hava uyarısını system_alert olarak CalendarEvents tablosuna yazar',
      () async {
    final wrote = await service.recordWeatherAlert(
      fieldId: 'field-1',
      fieldName: 'Yağmur tarlası',
      alertKey: 'rain_warning',
      title: 'Kuvvetli yağış',
      message: 'Bugün yağış var; sulamayı atla.',
      severity: ActivityType.alertSeverityWarning,
      icon: '🌧️',
      metadata: const {'rain_mm': 18},
    );

    expect(wrote, isTrue);
    final rows = await events();
    expect(rows, hasLength(1));
    expect(rows.single.eventType, ActivityType.systemAlert);
    expect(rows.single.source, 'system');
    expect(rows.single.subtype, 'weather_rain_warning');
    expect(rows.single.noteText, contains('sulamayı atla'));

    final meta = metadata(rows.single);
    expect(meta['severity'], ActivityType.alertSeverityWarning);
    expect(meta['origin'], 'weather');
    expect(meta['message'], contains('sulamayı atla'));
    expect(meta['rain_mm'], 18);
  });

  test('aynı tarla ve uyarı anahtarını 24 saat içinde tekrar yazmaz', () async {
    Future<bool> write() {
      return service.recordWeatherAlert(
        fieldId: 'field-1',
        fieldName: 'Yağmur tarlası',
        alertKey: 'rain_warning',
        title: 'Kuvvetli yağış',
        message: 'Bugün yağış var; sulamayı atla.',
        severity: ActivityType.alertSeverityWarning,
      );
    }

    expect(await write(), isTrue);
    expect(await write(), isFalse);
    expect(await events(), hasLength(1));
  });

  test('GuideResult kritik uyarısını günlük kaydına çevirir', () async {
    final wrote = await service.recordGuideResult(
      fieldId: 'field-1',
      fieldName: 'Yağmur tarlası',
      result: const GuideResult(
        today: [],
        thisWeek: [],
        alerts: [
          EnvAlert(
            severity: AlertSeverity.critical,
            kind: AlertKind.frost,
            title: 'DON UYARISI',
            message: '-1°C bekleniyor. Hassas bitkileri örtün.',
            icon: '❄️',
          ),
        ],
        insights: [],
      ),
    );

    expect(wrote, isTrue);
    final rows = await events();
    expect(rows, hasLength(1));
    expect(rows.single.subtype, 'guide_frost_critical');
    final meta = metadata(rows.single);
    expect(meta['kind'], 'frost');
    expect(meta['severity'], ActivityType.alertSeverityCritical);
  });

  test('büyüme evresi geçişini bilgi seviyesinde sistem uyarısı yapar',
      () async {
    final wrote = await service.recordGrowthStageTransition(
      fieldId: 'field-1',
      cropId: 'crop-1',
      cropName: 'Ayçiçeği',
      previousStageKey: 'cimlenme',
      stageKey: 'vejetatif',
      stageLabel: 'Vejetatif',
      accumulatedGdd: 240,
    );

    expect(wrote, isTrue);
    final rows = await events();
    expect(rows, hasLength(1));
    expect(rows.single.cropId, 'crop-1');
    expect(rows.single.subtype, 'growth_stage_crop-1_vejetatif');
    final meta = metadata(rows.single);
    expect(meta['origin'], 'growth');
    expect(meta['previous_stage_label'], 'Çimlenme');
    expect(meta['stage_label'], 'Vejetatif');
    expect(meta['severity'], ActivityType.alertSeverityInfo);
  });
}
