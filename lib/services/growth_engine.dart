import 'dart:convert';
import 'dart:math' as math;

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';

import '../data/app_database.dart';
import '../data/activity_types.dart';
import '../data/crop_playbooks.dart';
import '../data/supported_crops.dart';
import '../models/seed_models.dart';
import 'alert_journal_service.dart';
import 'water_accounting.dart';

/// 3 vitrin bitki için GDD + aktivite delta → büyüme durumu hesaplayan servis.
///
/// **Akış:** ekimden bugüne günlük döngü — her günde:
///   1. Ortalama sıcaklıktan GDD birikir (Tbase bitkiye göre),
///   2. O günün aktivite kayıtlarındaki `quantity` ile `recommendedQuantity`
///      farkı toplanır (sulama açığı, azot stresi),
///   3. 10mm+ yağış ve 7+ gündür ilaçlama yoksa hastalık baskısı artar.
/// Sonuç tek satıra (`CropGrowthStates`) upsert edilir; UI bu tek kaydı okur.
///
/// **Offline-first:** Hava verisi verilmezse bölgesel klimatoloji ortalamaları
/// kullanılır. Ağ çağrısı yapmaz — çağıran katman opsiyonel olarak gerçek
/// günlük sıcaklıkları `dailyTemps` üzerinden geçebilir.
class GrowthEngine {
  GrowthEngine(this._db, {AlertJournalService? alertJournal})
      : _alertJournal = alertJournal;

  final AppDatabase _db;
  final AlertJournalService? _alertJournal;

  // ─── GDD tabanları (Tbase °C) ──────────────────────────────────────
  static const Map<String, double> _tBase = {
    'aycicegi': 6.0,
    'misir': 10.0,
    'domates': 10.0,
  };

  // ─── Fenoloji eşikleri (ekimden itibaren biriken GDD) ──────────────
  // Kaynaklar: FAO-56, TAGEM bitki kılavuzları, ZMO bölge raporları.
  static const Map<String, List<_StageBand>> _stages = {
    'aycicegi': [
      _StageBand('cimlenme', 0, 150),
      _StageBand('vejetatif', 150, 900),
      _StageBand('ciceklenme', 900, 1100),
      _StageBand('meyve_dolumu', 1100, 1500),
      _StageBand('olgunlasma', 1500, 1700),
    ],
    'misir': [
      _StageBand('cimlenme', 0, 180),
      _StageBand('vejetatif', 180, 750),
      _StageBand('ciceklenme', 750, 1000),
      _StageBand('meyve_dolumu', 1000, 1350),
      _StageBand('olgunlasma', 1350, 1550),
    ],
    'domates': [
      _StageBand('cimlenme', 0, 120),
      _StageBand('vejetatif', 120, 400),
      _StageBand('ciceklenme', 400, 700),
      _StageBand('meyve_dolumu', 700, 1100),
      _StageBand('olgunlasma', 1100, 1300),
    ],
  };

  // ─── Bölgesel aylık ortalama sıcaklık (°C) — agri_sim_service ile aynı tablo
  static const Map<TurkishRegion, List<double>> _monthlyAvg = {
    TurkishRegion.trakya: [
      3.5,
      4.5,
      7.5,
      13.0,
      18.0,
      23.0,
      26.0,
      25.5,
      21.0,
      15.5,
      9.5,
      5.0
    ],
    TurkishRegion.icAnadolu: [
      0.0,
      1.5,
      5.5,
      11.5,
      16.5,
      21.5,
      25.0,
      24.5,
      19.5,
      13.0,
      6.0,
      1.5
    ],
    TurkishRegion.ege: [
      7.5,
      8.5,
      11.5,
      16.5,
      21.5,
      26.5,
      29.5,
      29.0,
      24.5,
      18.5,
      13.0,
      9.0
    ],
    TurkishRegion.akdeniz: [
      9.0,
      10.0,
      13.5,
      18.0,
      23.0,
      28.0,
      31.0,
      31.0,
      26.5,
      20.5,
      15.0,
      10.5
    ],
    TurkishRegion.karadeniz: [
      5.0,
      5.5,
      8.0,
      12.5,
      17.0,
      21.0,
      24.0,
      24.0,
      19.5,
      14.5,
      10.0,
      6.5
    ],
    TurkishRegion.doguAnadolu: [
      -7.0,
      -5.5,
      -1.5,
      7.0,
      12.5,
      17.5,
      22.0,
      21.5,
      16.5,
      9.5,
      2.5,
      -3.5
    ],
    TurkishRegion.guneydoguAnadolu: [
      4.0,
      6.0,
      10.5,
      17.0,
      23.0,
      29.5,
      34.0,
      33.5,
      28.5,
      21.0,
      12.5,
      6.0
    ],
  };

  /// Tek bir ekinin büyüme durumunu sıfırdan yeniden hesaplar ve
  /// `CropGrowthStates` tablosuna upsert eder. Ekin yoksa veya ekim tarihi
  /// okunamazsa `null` döner (sessizce, kayıt yazılmaz).
  ///
  /// [dailyTemps]: 0. indeks = ekim günü, eleman: `{'tmax': double, 'tmin': double}`.
  /// Liste ekim ile bugün arası günleri kapsamıyorsa eksik günler klimatoloji
  /// ile doldurulur.
  Future<CropGrowthState?> recompute({
    required String cropId,
    DateTime? now,
    List<Map<String, dynamic>> dailyTemps = const [],
    TurkishRegion region = TurkishRegion.icAnadolu,
  }) async {
    final crop = await (_db.select(_db.fieldCrops)
          ..where((tbl) => tbl.id.equals(cropId) & tbl.deletedAt.isNull()))
        .getSingleOrNull();
    if (crop == null) return null;

    final key = SupportedCrops.normalize(
      SupportedCrops.canonicalName(crop.name) ?? crop.name,
    );
    if (!_stages.containsKey(key)) return null; // 3 vitrin dışı — atla

    final plantedDate = _parsePlantedDate(crop.plantedDate);
    if (plantedDate == null) return null;

    final t = now ?? DateTime.now();
    final daysSince = t.difference(plantedDate).inDays;
    if (daysSince < 0) return null; // ileri tarihli ekim — henüz başlamadı

    final field = await (_db.select(_db.fields)
          ..where((tbl) => tbl.id.equals(crop.fieldId))
          ..limit(1))
        .getSingleOrNull();
    final areaSqm = (field?.areaSqm != null && field!.areaSqm! > 0)
        ? field.areaSqm!
        : ((field?.areaDekar != null && field!.areaDekar! > 0)
            ? field.areaDekar! * 1000.0
            : 1000.0);
    final plantCount = WaterAccounting.estimatePlantCount(
      areaSqm: areaSqm,
      rowSpacingCm: crop.rowSpacingCm,
      plantSpacingCm: crop.plantSpacingCm,
    );

    // ── Aktiviteleri tek seferde çek (ekim gününden bugüne) ───────────
    final activities = await (_db.select(_db.calendarEvents)
          ..where((tbl) =>
              tbl.cropId.equals(cropId) &
              tbl.deletedAt.isNull() &
              tbl.source.equals('auto_seed').not() &
              tbl.eventDate.isBiggerOrEqualValue(
                  plantedDate.toUtc().subtract(const Duration(days: 1))) &
              tbl.eventDate.isSmallerOrEqualValue(t.toUtc())))
        .get();

    // Tarih bazlı günlük özet: day-index → {water_mm_applied, water_mm_rec,
    // fert_ratio_applied, spraying_done}
    final byDay = <int, _DayDelta>{};
    for (final ev in activities) {
      final di = ev.eventDate.toLocal().difference(plantedDate).inDays;
      if (di < 0 || di > daysSince + 1) continue;
      final delta = byDay.putIfAbsent(di, () => _DayDelta());

      final metadata = _metadata(ev.metadataJson);
      final qty = ev.quantity ?? _extractLegacyQuantity(metadata);
      final rec = ev.recommendedQuantity;

      switch (ev.eventType) {
        case ActivityType.watering:
          final impact = WaterAccounting.calculate(
            metadata: metadata,
            quantity: ev.quantity,
            quantityUnit: ev.unit,
            areaSqm: areaSqm,
            plantCount: plantCount,
          );
          delta.waterMmApplied += impact.mm;
          if (rec != null) {
            delta.waterMmRecommended += WaterAccounting.calculate(
              metadata: const {},
              quantity: rec,
              quantityUnit:
                  ev.unit ?? metadata['quantity_unit']?.toString() ?? 'dk',
              areaSqm: areaSqm,
              plantCount: plantCount,
              irrigationMethod: metadata['irrigation_method']?.toString(),
            ).mm;
          }
          break;
        case ActivityType.fertilizing:
          final fertType = metadata['fertilizer_type']?.toString() ?? '';
          final kFactor = _kFactorFromFertilizerType(fertType);
          if (qty != null && rec != null && rec > 0) {
            // Oran: uygulanan/önerilen — eksikse 1'den küçük, fazlaysa büyük.
            final ratio = (qty / rec).clamp(0.0, 2.0);
            delta.fertRatios.add(ratio);
            // K oranı: gübre tipine göre faktörlendirilir.
            // kFactor=0 (üre) → K verilmedi sayılır (0.0)
            // kFactor=1 (kompoze) → K oranı = N oranı
            delta.kRatios.add(ratio * kFactor);
          } else if (qty != null && qty > 0) {
            // Önerilen yoksa "yapıldı" kabul et (rec=qty varsayımı).
            delta.fertRatios.add(1.0);
            delta.kRatios.add(1.0 * kFactor);
          }
          break;
        case ActivityType.spraying:
          delta.sprayingDone = true;
          break;
      }
    }

    // ── Günlük döngü: GDD birikimi + stres akümülatörleri ─────────────
    final stageBands = _stages[key]!;
    final tBase = _tBase[key] ?? 10.0;
    final monthly =
        _monthlyAvg[region] ?? _monthlyAvg[TurkishRegion.icAnadolu]!;

    double accGdd = 0.0;
    double waterDeficit = 0.0;
    double nStress = 0.0;
    double kStress = 0.0;
    double disease = 0.0;

    // Playbook'tan günlük sulama ihtiyacı (weeklyMm / 7).
    final playbook = CropPlaybooks.resolveByName(crop.name);
    // Hastalık baskısı için yağmur+ilaç zinciri — sliding 7 günlük pencere.
    int daysSinceSpray = 999;

    for (int d = 0; d <= daysSince; d++) {
      final date = plantedDate.add(Duration(days: d));
      final monthIdx = (date.month - 1) % 12;

      double tmax, tmin;
      if (d < dailyTemps.length) {
        tmax = (dailyTemps[d]['tmax'] as num?)?.toDouble() ??
            monthly[monthIdx] + 6;
        tmin = (dailyTemps[d]['tmin'] as num?)?.toDouble() ??
            monthly[monthIdx] - 6;
      } else {
        tmax = monthly[monthIdx] + 6;
        tmin = monthly[monthIdx] - 6;
      }
      final tmean = (tmax + tmin) / 2;
      accGdd += math.max(0.0, tmean - tBase);

      // Sulama açığı — playbook'a göre günlük ideal mm, gerçek uygulama farkı.
      final band = playbook?.bandForDay(d);
      final idealMmDay = band == null ? 0.0 : band.weeklyMm / 7.0;
      final delta = byDay[d];
      final appliedMm = delta?.waterMmApplied ?? 0.0;
      final todayDeficit = math.max(0.0, idealMmDay - appliedMm);
      // Deficit günlük 5%'lik doğal iyileşme ile sönümlenir (yağmur/nem).
      waterDeficit = math.max(0.0, waterDeficit * 0.95 + todayDeficit * 0.4);

      // Azot stresi — 7-day moving average ile yumuşatılır.
      // Hedef setpoint: ratio düşükse stres artar, yüksekse düşer.
      // Smoothing katsayısı 0.14 ≈ 1/7 → ani değişiklikler bastırılır.
      double targetN = nStress;
      if (delta != null && delta.fertRatios.isNotEmpty) {
        final avgRatio =
            delta.fertRatios.reduce((a, b) => a + b) / delta.fertRatios.length;
        targetN = (1.0 - avgRatio).clamp(0.0, 1.0);
      } else if (band != null && band.stage.contains('Olgun') == false) {
        targetN = math.min(1.0, nStress + 0.05);
      }
      nStress = (0.86 * nStress + 0.14 * targetN).clamp(0.0, 1.0);

      // K (potasyum) stresi — kRatios üzerinden, çiçek/meyve evresinde kritik.
      double targetK = kStress;
      if (delta != null && delta.kRatios.isNotEmpty) {
        final avgKRatio =
            delta.kRatios.reduce((a, b) => a + b) / delta.kRatios.length;
        targetK = (1.0 - avgKRatio).clamp(0.0, 1.0);
      } else if (band != null &&
          (band.stage.contains('Çiçek') || band.stage.contains('Meyve'))) {
        // Kritik evre + K verilmedi → hedef stres yükselir
        targetK = math.min(1.0, kStress + 0.04);
      }
      kStress = (0.86 * kStress + 0.14 * targetK).clamp(0.0, 1.0);

      // Hastalık baskısı — aktivitede yağış metaverisi yok, yaklaşık modelle:
      // her "vejetatif+" günde ilaçsız geçirilen gün başına hafif artış;
      // ilaçlama yapıldığında sıfıra çekilir.
      if (delta?.sprayingDone == true) {
        disease = math.max(0.0, disease - 0.35);
        daysSinceSpray = 0;
      } else {
        daysSinceSpray++;
        if (d > 20 && daysSinceSpray > 14) {
          disease = math.min(1.0, disease + 0.006);
        }
      }
    }

    // ── Evre belirleme ────────────────────────────────────────────────
    _StageBand active = stageBands.first;
    for (final b in stageBands) {
      if (accGdd >= b.fromGdd) active = b;
    }
    final stageSpan =
        (active.toGdd - active.fromGdd).clamp(1.0, double.infinity);
    final stageProgress =
        ((accGdd - active.fromGdd) / stageSpan).clamp(0.0, 1.0);

    // ── Boy + biyokütle (sigmoid progress) ────────────────────────────
    final lastStage = stageBands.last;
    final totalGdd = lastStage.toGdd;
    final overallProgress = (accGdd / totalGdd).clamp(0.0, 1.0);
    final biomass = 1.0 / (1.0 + math.exp(-10 * (overallProgress - 0.5)));
    final height = _estimateHeight(key, overallProgress) * (1 - disease * 0.3);

    // ── Verim çarpanı — tüm streslerin kümülatif etkisi ───────────────
    // K stresi N kadar baskın değil (0.15) ama meyve/tane kalitesinde
    // anlamlı: yetersiz K = küçük meyve, düşük şeker.
    final yieldMul = (1.0 -
            0.03 * math.sqrt(waterDeficit / 10.0) -
            0.20 * nStress -
            0.15 * kStress -
            0.30 * disease)
        .clamp(0.5, 1.15);

    final nowUtc = DateTime.now().toUtc();
    final previousState = await (_db.select(_db.cropGrowthStates)
          ..where((tbl) => tbl.cropId.equals(cropId)))
        .getSingleOrNull();
    final newState = CropGrowthStatesCompanion(
      cropId: Value(cropId),
      fieldId: Value(crop.fieldId),
      asOfDate: Value(DateTime(t.year, t.month, t.day)),
      accumulatedGdd: Value(accGdd),
      currentStageKey: Value(active.key),
      stageProgress: Value(stageProgress),
      waterDeficitMm: Value(waterDeficit),
      nStressIdx: Value(nStress),
      kStressIdx: Value(kStress),
      diseasePressure: Value(disease),
      heightCm: Value(height),
      biomassRel: Value(biomass),
      yieldMultiplier: Value(yieldMul),
      lastComputedAt: Value(nowUtc),
      updatedAt: Value(nowUtc),
    );
    await _db.into(_db.cropGrowthStates).insertOnConflictUpdate(newState);
    await _recordStageTransition(
      previousState: previousState,
      fieldId: crop.fieldId,
      cropId: cropId,
      cropName: crop.name,
      newStageKey: active.key,
      accumulatedGdd: accGdd,
      at: t,
    );

    return (await (_db.select(_db.cropGrowthStates)
          ..where((tbl) => tbl.cropId.equals(cropId)))
        .getSingleOrNull());
  }

  /// Tüm aktif ekinleri yeniden hesaplar. Batch arka-plan sync için.
  /// Başarılı hesap sayısını döner.
  Future<int> recomputeAll({DateTime? now}) async {
    final crops = await (_db.select(_db.fieldCrops)
          ..where((tbl) => tbl.deletedAt.isNull()))
        .get();
    int ok = 0;
    for (final c in crops) {
      try {
        final r = await recompute(cropId: c.id, now: now);
        if (r != null) ok++;
      } catch (e, st) {
        debugPrint('GrowthEngine.recompute(${c.id}) hata: $e\n$st');
      }
    }
    return ok;
  }

  Future<void> _recordStageTransition({
    required CropGrowthState? previousState,
    required String fieldId,
    required String cropId,
    required String cropName,
    required String newStageKey,
    required double accumulatedGdd,
    required DateTime at,
  }) async {
    final journal = _alertJournal;
    if (journal == null || previousState == null) return;
    final previousStage = previousState.currentStageKey;
    if (previousStage == newStageKey) return;
    try {
      await journal.recordGrowthStageTransition(
        fieldId: fieldId,
        cropId: cropId,
        cropName: cropName,
        previousStageKey: previousStage,
        stageKey: newStageKey,
        stageLabel: GrowthEngineStageLabels.label(newStageKey),
        accumulatedGdd: accumulatedGdd,
        at: at,
      );
    } catch (_) {
      // Uyarı günlüğü best-effort; büyüme hesabını asla bozmasın.
    }
  }

  /// Tek bir ekinin büyüme durumunu canlı izler (Drift stream).
  Stream<CropGrowthState?> watch(String cropId) {
    return (_db.select(_db.cropGrowthStates)
          ..where((tbl) => tbl.cropId.equals(cropId)))
        .watchSingleOrNull();
  }

  /// UI'ın birden fazla ekinin durumunu tek stream'de dinlemesi için.
  Stream<List<CropGrowthState>> watchForField(String fieldId) {
    return (_db.select(_db.cropGrowthStates)
          ..where((tbl) => tbl.fieldId.equals(fieldId)))
        .watch();
  }

  /// Desteklenen bitki anahtarı (TurkishCrop adından normalize edilmiş) için
  /// hasat'a kadar toplam GDD eşiği. Bilinmeyen bitki için null.
  static double? totalGddFor(String cropKey) {
    final bands = _stages[cropKey];
    if (bands == null || bands.isEmpty) return null;
    return bands.last.toGdd;
  }

  /// Birikim GDD'ye göre 0..1 arasında görsel büyüme ilerlemesi. UI boy +
  /// biyokütle skalası için bu değeri tüketir.
  static double overallProgressFor(String cropKey, double accumulatedGdd) {
    final total = totalGddFor(cropKey);
    if (total == null || total <= 0) return 0.0;
    return (accumulatedGdd / total).clamp(0.0, 1.0);
  }

  /// Tek bir bitkinin desteklenip desteklenmediği (3 vitrin bitki).
  static bool isSupported(String cropKey) => _stages.containsKey(cropKey);

  // ─── Yardımcılar ──────────────────────────────────────────────────

  /// TurkishRegion'ı enlem/boylamdan kaba tahmin — fieldState yoksa.
  /// Türkiye sınırları içinde bölge merkezlerine en yakın olanı seçer.
  static TurkishRegion regionFromLatLng(double lat, double lng) {
    const centers = <TurkishRegion, (double, double)>{
      TurkishRegion.trakya: (41.2, 27.0),
      TurkishRegion.icAnadolu: (39.0, 33.0),
      TurkishRegion.ege: (38.4, 27.8),
      TurkishRegion.akdeniz: (36.9, 31.0),
      TurkishRegion.karadeniz: (41.0, 36.0),
      TurkishRegion.doguAnadolu: (39.7, 41.3),
      TurkishRegion.guneydoguAnadolu: (37.5, 39.5),
    };
    TurkishRegion best = TurkishRegion.icAnadolu;
    double bestDist = double.infinity;
    centers.forEach((r, c) {
      final d = math.pow(lat - c.$1, 2) + math.pow(lng - c.$2, 2).toDouble();
      if (d < bestDist) {
        bestDist = d.toDouble();
        best = r;
      }
    });
    return best;
  }

  static double _estimateHeight(String key, double progress) {
    const maxH = {'aycicegi': 200.0, 'misir': 250.0, 'domates': 150.0};
    final max = maxH[key] ?? 120.0;
    if (progress > 0.9) return max; // olgunlaşmada durur, düşmez
    return max / (1.0 + math.exp(-12 * (progress - 0.4)));
  }

  static DateTime? _parsePlantedDate(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    final parts = raw.split('.');
    if (parts.length == 3) {
      final iso =
          '${parts[2]}-${parts[1].padLeft(2, '0')}-${parts[0].padLeft(2, '0')}';
      final dt = DateTime.tryParse(iso);
      if (dt != null) return dt;
    }
    return DateTime.tryParse(raw);
  }

  static Map<String, dynamic> _metadata(String? metaJson) {
    if (metaJson == null || metaJson.isEmpty) return const <String, dynamic>{};
    try {
      final m = jsonDecode(metaJson);
      if (m is Map) return Map<String, dynamic>.from(m);
    } catch (_) {}
    return const <String, dynamic>{};
  }

  static double? _extractLegacyQuantity(Map<String, dynamic> metadata) {
    final v = metadata['quantity'] ??
        metadata['fertilizer_kg'] ??
        metadata['harvest_kg'];
    if (v is num) return v.toDouble();
    if (v is String) {
      return double.tryParse(v.replaceAll(',', '.'));
    }
    return null;
  }
}

class _StageBand {
  final String key;
  final double fromGdd;
  final double toGdd;
  const _StageBand(this.key, this.fromGdd, this.toGdd);
}

class _DayDelta {
  double waterMmApplied = 0.0;
  double waterMmRecommended = 0.0;
  final List<double> fertRatios = [];   // N karşılığı uygulama oranları
  final List<double> kRatios = [];      // K karşılığı uygulama oranları
  bool sprayingDone = false;
}

/// Gübre tipinden K oranı (0..1). 0 = K içermez (üre/DAP), 1 = tam K (potas/kompoze).
/// Bilinmeyen tipte default 1.0 (kompoze varsayımı) — geriye dönük uyumlu.
double _kFactorFromFertilizerType(String type) {
  if (type.isEmpty) return 1.0;
  final t = type.toLowerCase();
  if (t.contains('üre') || t.contains('urea')) return 0.0;
  if (t.contains('amonyum sülfat') || t.contains('amonyum nitrat')) return 0.0;
  if (t.contains('dap')) return 0.0;
  if (t.contains('tsp') || t.contains('triple')) return 0.0;
  if (t.contains('kcl') || t.contains('potas') || t.contains('0-0-')) return 1.0;
  return 1.0; // kompoze / NPK / bilinmeyen
}
