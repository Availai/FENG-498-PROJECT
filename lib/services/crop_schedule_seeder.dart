import 'dart:convert';

import 'package:drift/drift.dart';

import '../data/activity_types.dart';
import '../data/app_database.dart';
import '../data/crop_ipm_rules.dart';
import '../data/crop_playbooks.dart';
import '../data/crop_protocols.dart' show IrrigationMethod;
import 'ipm_decision_service.dart';
import 'soil_irrigation_advisor.dart';

/// Bitki tarlaya eklendiğinde sezonluk takvim programını (sulama + gübreleme +
/// gözlem/ilaçlama) `CalendarEvents` tablosuna **source='auto_seed'** olarak yazan
/// saf yardımcı.
///
/// - Çiftçi gerçek aktiviteyi logladığında `LocalDataRepository.logActivity`
///   eşleşen en yakın auto_seed kaydını soft-delete eder ("yapıldı").
/// - Plan tarihi geçmiş ama log yoksa kayıt canlı kalır; TaskDirectiveService
///   bunu "yapılmadı" senaryosuna dönüştürür.
///
/// Playbook/protokol bulunmayan bitkiler için sadece sulama programı yazılır
/// (basit aralık tabanlı). IPM kuralı olan bitkilerde kimyasal yerine önce
/// gözlem programı eklenir.
class CropScheduleSeeder {
  CropScheduleSeeder(this._db);
  final AppDatabase _db;

  /// Ekim sonrası varsayılan sulama yöntemi → aralık (gün).
  /// `CropConfig.irrigationMethod` yoksa çağıran katman null geçebilir; bu
  /// durumda `waterIntervalDays` parametresi olduğu gibi kullanılır.
  static int intervalForMethod(IrrigationMethod? m) {
    switch (m) {
      case IrrigationMethod.drip:
        return 3;
      case IrrigationMethod.sprinkler:
        return 5;
      case IrrigationMethod.hand:
        return 5;
      case IrrigationMethod.furrow:
        return 7;
      case null:
        return 7;
    }
  }

  /// Sulama yöntemi + toprak analizine göre aralık (gün). Toprak profili yoksa
  /// veya etkisi nötrse [intervalForMethod] ile **birebir aynıdır** (geriye
  /// uyumlu). Kumlu toprak aralığı kısaltır (daha sık), killi uzatır (daha
  /// seyrek) — FAO-56 kullanılabilir su mantığı. Sonuç 1–30 gün aralığına clamp.
  static int intervalForMethodAndSoil(
      IrrigationMethod? m, SoilIrrigationProfile? soil) {
    final base = intervalForMethod(m);
    final factor = soil?.intervalFactor ?? 1.0;
    if (factor == 1.0) return base;
    return (base * factor).round().clamp(1, 30);
  }

  /// Tek bitkinin sezonluk programını yazar. Aynı crop için önceki auto_seed
  /// kayıtları önce temizlenir; böylece yeniden-ekim durumunda takvim
  /// kirlenmez.
  Future<int> seedForCrop({
    required String fieldId,
    required String cropId,
    required String cropName,
    required DateTime plantedDate,
    required int harvestDays,
    required int waterIntervalDays,
    double? areaDekar,
    IrrigationMethod? irrigationMethod,
    DateTime? now,
  }) async {
    await clearForCrop(cropId);

    final today = now ?? DateTime.now();
    final playbook = CropPlaybooks.resolveByName(cropName);
    int count = 0;

    count += await _seedWatering(
      fieldId: fieldId,
      cropId: cropId,
      cropName: cropName,
      plantedDate: plantedDate,
      harvestDays: harvestDays,
      waterIntervalDays: waterIntervalDays,
      areaDekar: areaDekar,
      playbook: playbook,
      irrigationMethod: irrigationMethod,
      today: today,
    );

    if (playbook != null) {
      count += await _seedFertilizers(
        fieldId: fieldId,
        cropId: cropId,
        cropName: cropName,
        plantedDate: plantedDate,
        harvestDays: harvestDays,
        areaDekar: areaDekar,
        playbook: playbook,
      );
      if (IpmDecisionService.supports(cropName)) {
        count += await _seedIpmScoutings(
          fieldId: fieldId,
          cropId: cropId,
          cropName: cropName,
          plantedDate: plantedDate,
          harvestDays: harvestDays,
        );
      } else {
        count += await _seedPreventiveSprays(
          fieldId: fieldId,
          cropId: cropId,
          cropName: cropName,
          plantedDate: plantedDate,
          harvestDays: harvestDays,
          areaDekar: areaDekar,
          playbook: playbook,
        );
      }
    }

    return count;
  }

  /// Belirli bir ekinin tüm auto_seed takvim kayıtlarını soft-delete eder.
  Future<void> clearForCrop(String cropId) async {
    final now = DateTime.now().toUtc();
    await (_db.update(_db.calendarEvents)
          ..where((tbl) =>
              tbl.cropId.equals(cropId) &
              tbl.source.equals('auto_seed') &
              tbl.deletedAt.isNull()))
        .write(CalendarEventsCompanion(
      deletedAt: Value(now),
      updatedAt: Value(now),
    ));
  }

  // ─────────────────────────────────────── sulama ─────────────────────

  Future<int> _seedWatering({
    required String fieldId,
    required String cropId,
    required String cropName,
    required DateTime plantedDate,
    required int harvestDays,
    required int waterIntervalDays,
    required double? areaDekar,
    required CropPlaybook? playbook,
    required IrrigationMethod? irrigationMethod,
    required DateTime today,
  }) async {
    final interval = waterIntervalDays <= 0 ? 7 : waterIntervalDays;
    int written = 0;
    for (int d = interval; d <= harvestDays - 5; d += interval) {
      final date = plantedDate.add(Duration(days: d));
      // Çok eski planları yazma — bugünden 3 gün öncesinden itibaren yeterli.
      if (date.isBefore(today.subtract(const Duration(days: 3)))) continue;

      final band = playbook?.bandForDay(d);
      final weeklyMm = band?.weeklyMm ?? 30;
      final minutes = _estimateMinutes(
        weeklyMm: weeklyMm,
        intervalDays: interval,
        method: irrigationMethod,
      );
      final stage = band?.stage ?? 'Düzenli bakım';
      final note =
          '$stage evresi — yaklaşık ${(weeklyMm * interval / 7).round()} mm / $interval gün.';

      await _insertEvent(
        fieldId: fieldId,
        cropId: cropId,
        title: '$cropName — Sulama',
        eventType: ActivityType.watering,
        eventDate: date,
        quantity: null,
        unit: 'dk',
        recommendedQuantity: minutes.toDouble(),
        metadata: {
          'seed_kind': 'watering',
          'stage': stage,
          'weekly_mm': weeklyMm,
          if (irrigationMethod != null) 'method': irrigationMethod.name,
          if (areaDekar != null) 'area_dekar': areaDekar,
          'note': note,
        },
      );
      written++;
    }
    return written;
  }

  int _estimateMinutes({
    required int weeklyMm,
    required int intervalDays,
    required IrrigationMethod? method,
  }) {
    // Damla: mm'nin yaklaşık 1 mm/dk uygulama hızı (1.6 L/saat/damlatıcı);
    // diğer yöntemler daha uzun süre.
    final mmNeeded = weeklyMm * intervalDays / 7.0;
    final perMethod = switch (method) {
      IrrigationMethod.drip => mmNeeded * 1.0,
      IrrigationMethod.sprinkler => mmNeeded * 1.3,
      IrrigationMethod.hand => mmNeeded * 1.5,
      IrrigationMethod.furrow => mmNeeded * 1.8,
      null => mmNeeded * 1.3,
    };
    return perMethod.clamp(8.0, 120.0).round();
  }

  // ─────────────────────────────────────── gübre ──────────────────────

  Future<int> _seedFertilizers({
    required String fieldId,
    required String cropId,
    required String cropName,
    required DateTime plantedDate,
    required int harvestDays,
    required double? areaDekar,
    required CropPlaybook playbook,
  }) async {
    int written = 0;
    for (final f in playbook.fertilizers) {
      final offsets = _parseStageOffsets(
        stage: f.stage,
        playbook: playbook,
        harvestDays: harvestDays,
      );
      for (final day in offsets) {
        if (day > harvestDays - 3) continue;
        final date = plantedDate.add(Duration(days: day));
        final dose = areaDekar != null && areaDekar > 0
            ? f.defaultDosePerDa * areaDekar
            : f.defaultDosePerDa;

        await _insertEvent(
          fieldId: fieldId,
          cropId: cropId,
          title: '$cropName — ${f.name}',
          eventType: ActivityType.fertilizing,
          eventDate: date,
          quantity: null,
          unit: f.unit,
          recommendedQuantity: double.parse(dose.toStringAsFixed(2)),
          metadata: {
            'seed_kind': 'fertilizing',
            'fertilizer_name': f.name,
            'formula': f.formula,
            'stage': f.stage,
            'dose_per_da': f.defaultDosePerDa,
            if (areaDekar != null) 'area_dekar': areaDekar,
            if (f.tip != null) 'tip': f.tip,
          },
        );
        written++;
      }
    }
    return written;
  }

  /// Gübre `stage` metninden (veya playbook evre tablosundan) gün offset
  /// listesi üretir. "Çiçeklenme boyunca haftalık" gibi tekrarlı ifadeler 3
  /// haftaya yayılır; sayısal ifadeler ("25. gün", "55–60. gün") ilk sayıya
  /// sabitlenir; anahtar kelimeler playbook'un ilgili evre gününe bağlanır.
  List<int> _parseStageOffsets({
    required String stage,
    required CropPlaybook playbook,
    required int harvestDays,
  }) {
    final lower = stage.toLowerCase();
    final numericMatch = RegExp(r'(\d{1,3})').firstMatch(stage);
    if (numericMatch != null) {
      final v = int.tryParse(numericMatch.group(1)!);
      if (v != null && v > 0 && v < harvestDays) {
        if (lower.contains('haftalık') || lower.contains('haftada')) {
          return [v, v + 7, v + 14];
        }
        return [v];
      }
    }
    if (lower.contains('dikim') ||
        lower.contains('ekim') ||
        lower.contains('taban') ||
        lower.contains('çukuru')) {
      return const [0];
    }
    if (lower.contains('çiçek')) {
      final band = _firstBandWith(playbook, 'çiçek');
      if (band != null) {
        if (lower.contains('haftalık')) {
          return [band.dayFrom, band.dayFrom + 7, band.dayFrom + 14];
        }
        return [band.dayFrom];
      }
    }
    if (lower.contains('meyve')) {
      final band = _firstBandWith(playbook, 'meyve') ??
          _firstBandWith(playbook, 'dolum');
      if (band != null) return [band.dayFrom];
    }
    if (lower.contains('olgun')) {
      final band = _firstBandWith(playbook, 'olgun');
      if (band != null) return [band.dayFrom];
    }
    // Güvenli fallback — sezonun ortası.
    return [harvestDays ~/ 3];
  }

  WaterGuideBand? _firstBandWith(CropPlaybook playbook, String needle) {
    for (final b in playbook.waterGuide) {
      if (b.stage.toLowerCase().contains(needle)) return b;
    }
    return null;
  }

  // ─────────────────────────────────────── ilaç ───────────────────────

  Future<int> _seedPreventiveSprays({
    required String fieldId,
    required String cropId,
    required String cropName,
    required DateTime plantedDate,
    required int harvestDays,
    required double? areaDekar,
    required CropPlaybook playbook,
  }) async {
    // İlk fungisit ürününü koruyucu olarak sezonun ortasına ve çiçeklenme
    // civarına planla. Yok ise ilk insektisit ya da ilk ürünü kullan.
    if (playbook.pesticides.isEmpty) return 0;
    final preferred = playbook.pesticides.firstWhere(
      (p) => p.category.name == 'fungicide',
      orElse: () => playbook.pesticides.first,
    );

    // Koruyucu tarihler: 30. gün + çiçeklenme/meyve evresinin başı.
    final floweringBand = _firstBandWith(playbook, 'çiçek') ??
        _firstBandWith(playbook, 'meyve') ??
        _firstBandWith(playbook, 'dolum');
    final offsets = <int>{30};
    if (floweringBand != null) {
      offsets.add(floweringBand.dayFrom);
    }

    int written = 0;
    for (final day in offsets) {
      if (day > harvestDays - preferred.preharvestIntervalDays) continue;
      final date = plantedDate.add(Duration(days: day));
      final dose = areaDekar != null && areaDekar > 0
          ? preferred.defaultDosePerDa * areaDekar
          : preferred.defaultDosePerDa;

      await _insertEvent(
        fieldId: fieldId,
        cropId: cropId,
        title: '$cropName — ${preferred.name}',
        eventType: ActivityType.spraying,
        eventDate: date,
        quantity: null,
        unit: preferred.unit,
        recommendedQuantity: double.parse(dose.toStringAsFixed(2)),
        metadata: {
          'seed_kind': 'spraying',
          'pesticide_name': preferred.name,
          'active_ingredient': preferred.activeIngredient,
          'category': preferred.category.name,
          'targets': preferred.targets,
          'preharvest_days': preferred.preharvestIntervalDays,
          if (areaDekar != null) 'area_dekar': areaDekar,
          if (preferred.tip != null) 'tip': preferred.tip,
          'note': 'Koruyucu uygulama — yağmurdan 48 saat önce.',
        },
      );
      written++;
    }
    return written;
  }

  Future<int> _seedIpmScoutings({
    required String fieldId,
    required String cropId,
    required String cropName,
    required DateTime plantedDate,
    required int harvestDays,
  }) async {
    final windows = IpmDecisionService.scoutingWindowsFor(cropName);
    if (windows.isEmpty) return 0;

    int written = 0;
    for (final window in windows) {
      if (window.dayOffset > harvestDays) continue;
      final rules = window.pestKeys
          .map((key) => IpmDecisionService.ruleFor(
                cropName: cropName,
                pestKey: key,
              ))
          .whereType<CropIpmRule>()
          .toList(growable: false);
      if (rules.isEmpty) continue;

      await _insertEvent(
        fieldId: fieldId,
        cropId: cropId,
        title: '$cropName — ${window.title}',
        eventType: ActivityType.scouting,
        eventDate: plantedDate.add(Duration(days: window.dayOffset)),
        quantity: null,
        unit: null,
        recommendedQuantity: null,
        metadata: {
          'seed_kind': 'scouting',
          'ipm_crop': cropName,
          'ipm_rule_keys': window.pestKeys,
          'targets': rules.map((rule) => rule.pestName).toList(),
          'thresholds': {
            for (final rule in rules) rule.pestKey: rule.economicThreshold,
          },
          'monitoring_methods': {
            for (final rule in rules) rule.pestKey: rule.monitoringMethod,
          },
          'note':
              'Entegre mücadele gözlemi — eşik doğrulanmadan kimyasal önerilmez.',
        },
      );
      written++;
    }
    return written;
  }

  // ─────────────────────────────────────── db ─────────────────────────

  Future<void> _insertEvent({
    required String fieldId,
    required String cropId,
    required String title,
    required String eventType,
    required DateTime eventDate,
    required double? quantity,
    required String? unit,
    required double? recommendedQuantity,
    required Map<String, dynamic> metadata,
  }) async {
    final now = DateTime.now().toUtc();
    final id = _newEventId();
    await _db.into(_db.calendarEvents).insert(
          CalendarEventsCompanion.insert(
            id: id,
            title: title,
            eventType: eventType,
            eventDate: eventDate.toUtc(),
            createdAt: now,
            updatedAt: now,
            fieldId: Value(fieldId),
            cropId: Value(cropId),
            source: const Value('auto_seed'),
            metadataJson: Value(jsonEncode(metadata)),
            quantity: Value(quantity),
            unit: Value(unit),
            recommendedQuantity: Value(recommendedQuantity),
          ),
        );
  }

  /// Auto-seed kayıtları için tekil ID. Eskiden yalnız mikrosaniye timestamp
  /// kullanılıyordu; aynı tick içinde art arda gelen `insert`'lerde
  /// `UNIQUE constraint failed: calendar_events.id` oluşuyordu (sezon boyunca
  /// onlarca etkinlik tek seeder çağrısında yazılıyor). Process-içi monotonik
  /// counter eklendi — aynı tick olsa bile her ID farklı.
  static int _idCounter = 0;
  static String _newEventId() {
    final ts = DateTime.now().microsecondsSinceEpoch.toRadixString(36);
    final c = (_idCounter++).toRadixString(36);
    return 'seed_${ts}_$c';
  }
}
