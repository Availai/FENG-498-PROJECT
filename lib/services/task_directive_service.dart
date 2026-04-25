import 'dart:math' as math;

import '../data/activity_types.dart';
import '../data/crop_playbooks.dart';
import '../data/crop_protocols.dart';
import '../data/turkiye_crop_guides.dart';
import 'field_state_service.dart';
import 'water_accounting.dart';

/// `GrowthEngine` tarafından üretilen bir ekinin stres/verim özeti. Saf POD —
/// Drift tipine bağlanmamak için bu dosyada tanımlı. Çağıran katman
/// `CropGrowthState` → `GrowthSnapshot` dönüşümünü yapar.
class GrowthSnapshot {
  /// Aktif fenoloji anahtarı: 'cimlenme' | 'vejetatif' | 'ciceklenme' |
  /// 'meyve_dolumu' | 'olgunlasma'.
  final String stageKey;

  /// 0..1 — aktif evre içi ilerleme.
  final double stageProgress;

  /// Ekimden bu yana biriken GDD.
  final double accumulatedGdd;

  /// Sulama açığı (mm). 0 = ideal.
  final double waterDeficitMm;

  /// Azot stres indeksi 0..1.
  final double nStressIdx;

  /// Hastalık baskısı 0..1.
  final double diseasePressure;

  /// Verim çarpanı (0.5..1.15). 1'in altı = verim kaybı.
  final double yieldMultiplier;

  const GrowthSnapshot({
    required this.stageKey,
    required this.stageProgress,
    required this.accumulatedGdd,
    required this.waterDeficitMm,
    required this.nStressIdx,
    required this.diseasePressure,
    required this.yieldMultiplier,
  });

  /// Verim kaybı yüzde olarak (0..50). Çiftçi dostu sayı.
  int get yieldLossPct => ((1.0 - yieldMultiplier) * 100).round().clamp(0, 50);

  /// Herhangi bir stres baskın mı? (reason metnine eklenecek mi?)
  bool get hasStress =>
      waterDeficitMm > 2.0 || nStressIdx > 0.15 || diseasePressure > 0.1;
}

/// Çiftçiye verilecek tek bir somut yönerge. UI sadece render eder; karar
/// mantığı tamamen burada oluşturulur ("flutter vitrindir" felsefesi).
class FieldDirective {
  /// Aciliyet seviyesi:
  /// 2 = BUGÜN yapılmalı (sula/ilaçla/hasat et)
  /// 1 = Bu hafta / yaklaşıyor (hazırlan)
  /// 0 = Bilgi / bekleme ("yağmur geliyor, sulamayı ertele")
  final int urgency;

  /// Büyük harfli emir başlık. Örn. "2 DK SULA", "DON UYARISI".
  final String headline;

  /// Tek satır gerekçe (çiftçi dostu, sebep-sonuç).
  final String reason;

  /// CTA chip'i için aktivite tipi — bastığında logActivity tetiklenir.
  /// Null ise sadece bilgi (yağmur bekleme gibi).
  final String? actionType;

  /// Miktar ipucu (örn. 15 dk, 3 kg) — actionType ile birlikte log'a gider.
  final double? suggestedQuantity;
  final String? quantityUnit;
  final double? recommendedQuantity;
  final List<String> steps;
  final List<String> sourceRefs;
  final double? areaDekar;
  final int? plantCount;

  /// Hangi ekin için (fieldCrops[i]['id']). Null ise tarla geneli.
  final String? cropId;
  final String? cropName;

  /// Ikon/kategori ayırmak için içsel sınıflandırma.
  final String kind;

  const FieldDirective({
    required this.urgency,
    required this.headline,
    required this.reason,
    required this.kind,
    this.actionType,
    this.suggestedQuantity,
    this.quantityUnit,
    this.recommendedQuantity,
    this.steps = const [],
    this.sourceRefs = const [],
    this.areaDekar,
    this.plantCount,
    this.cropId,
    this.cropName,
  });
}

/// Tarla durumunu (ekili bitkiler + hava tahmini + çiftçinin yaptığı
/// kayıtlar) girdi alarak somut yönergeler üretir. Tamamen saf: I/O yok,
/// istediğin her yerde çağrılabilir, kolayca unit-test edilir.
class TaskDirectiveService {
  const TaskDirectiveService();

  /// [activities] — `watchActivityLog` stream'inden gelen liste (eventType +
  /// date alanları okunur). [dailyForecast] — `analysis['daily_forecast']`.
  /// [growthStates] — `GrowthEngine` tarafından yazılmış büyüme durumu (crop
  /// id → state). Varsa direktif `reason` metni verim çarpanı + stres düzeyi
  /// ile zenginleştirilir; yoksa klasik aralık/hava tabanlı mantık çalışır.
  List<FieldDirective> generate({
    required List<Map<String, dynamic>> fieldCrops,
    required List<Map<String, dynamic>> activities,
    List<dynamic>? dailyForecast,
    double? currentTemp,
    double? soilMoisture,
    Map<String, GrowthSnapshot>? growthStates,
    Map<String, CropFieldState>? fieldStates,

    /// Takvime otomatik yazılmış (auto_seed) sulama/gübre/ilaç planları —
    /// `CropScheduleSeeder.seedForCrop` çıktısı. Tarihi geçmiş ve log ile
    /// eşleşmemiş kayıtlar "yapılmadı" senaryosu olarak üstte gösterilir.
    List<Map<String, dynamic>>? scheduledEvents,
    DateTime? now,
  }) {
    final t = now ?? DateTime.now();
    final out = <FieldDirective>[];

    // ── Tarihi geçmiş takvim planları (auto_seed) → somut "yapılmadı" ──
    // senaryosu üret. Her kayıt "kaç gün geçti" + "hangi evredeyim" bilgisi
    // ile zenginleştirilir.
    if (scheduledEvents != null && scheduledEvents.isNotEmpty) {
      out.addAll(_overdueAutoSeedDirectives(
        scheduledEvents: scheduledEvents,
        fieldCrops: fieldCrops,
        growthStates: growthStates,
        now: t,
      ));
    }

    // ── Hava tahmini türev değerleri ────────────────────────────
    final forecast = _parseForecast(dailyForecast);
    final rainNext48h = _sumRain(forecast, 0, 2);
    final rainLast24h = _rainYesterday(forecast);
    final tomorrowMax = forecast.length > 1 ? forecast[1].max : null;
    final tomorrowMin = forecast.length > 1 ? forecast[1].min : null;

    // ── Tarla boş ise tek yönerge ──────────────────────────────
    if (fieldCrops.isEmpty) {
      out.add(const FieldDirective(
        urgency: 1,
        headline: 'TARLAYA BİTKİ EKLE',
        reason:
            'Henüz ekili bitki yok. "Tarlayı Tara" ile uygun çeşitleri gör.',
        kind: 'empty',
      ));
      return out;
    }

    // ── Global hava uyarıları (tüm tarlaya) ────────────────────
    if (tomorrowMin != null && tomorrowMin < 2) {
      out.add(FieldDirective(
        urgency: 2,
        headline: 'DON UYARISI — YARIN',
        reason:
            'Yarın gece ${tomorrowMin.toStringAsFixed(0)}°C. Hassas fideleri ört, sulamayı sabaha bırak.',
        kind: 'frost',
      ));
    }
    if (tomorrowMax != null && tomorrowMax > 35) {
      out.add(FieldDirective(
        urgency: 1,
        headline: 'YARIN AŞIRI SICAK',
        reason:
            'Yarın en yüksek ${tomorrowMax.toStringAsFixed(0)}°C. Sulamayı 06:00-08:00 arasına al.',
        kind: 'heat',
      ));
    }

    // ── Her ekin için sulama / gübre / hasat / ilaçlama yönergesi ──
    for (final crop in fieldCrops) {
      final cropId = crop['id']?.toString();
      final cropName = crop['name']?.toString() ?? 'Bitki';
      final waterInterval = (crop['water_interval_days'] as num?)?.toInt() ?? 7;
      final harvestDays = (crop['harvest_days'] as num?)?.toInt() ?? 90;
      final plantedDate = _parsePlantedDate(crop['planted_date']?.toString());

      final activitiesForCrop = activities.where((a) {
        final fid = a['crop_id']?.toString();
        return fid == null || fid.isEmpty || fid == cropId;
      }).toList();

      final lastWater = _lastActivity(activitiesForCrop, ActivityType.watering);
      final lastFert =
          _lastActivity(activitiesForCrop, ActivityType.fertilizing);
      final lastSpray = _lastActivity(activitiesForCrop, ActivityType.spraying);
      final growth = cropId == null ? null : growthStates?[cropId];
      final fieldState = cropId == null ? null : fieldStates?[cropId];
      final sourceRefs = _sourceRefsFor(cropName);

      // ── Protokol adımı (3 vitrin bitki için) ────────────────
      // Aktif adımı en üst sıraya yerleştir; hasat protokol içindeyse
      // ayrıca aşağıdaki harvest bloğu çalışmasın (continue ederiz).
      final protoStepDirective = _protocolStepDirective(
        crop: crop,
        cropId: cropId,
        cropName: cropName,
        plantedDate: plantedDate,
        activitiesForCrop: activitiesForCrop,
        now: t,
        fieldState: fieldState,
        sourceRefs: sourceRefs,
      );
      if (protoStepDirective != null) {
        out.add(protoStepDirective);
        // Hasat adımı protokol tarafından yönetiliyorsa ek "hasat zamanı"
        // direktifi gerekmez. Ama sulama/gübreleme önerileri yine devam
        // etsin — onlar hava/aralık tabanlı, protokole değil koşula bağlı.
        if (protoStepDirective.actionType == ActivityType.harvest) {
          continue;
        }
      }

      // Hasat kontrolü
      if (plantedDate != null) {
        final elapsed = t.difference(plantedDate).inDays;
        if (elapsed >= harvestDays) {
          out.add(FieldDirective(
            urgency: 2,
            headline: '$cropName: HASAT ZAMANI',
            reason:
                'Ekimden $elapsed gün geçti (hedef $harvestDays gün). Verim düşmeden topla.',
            kind: 'harvest',
            actionType: ActivityType.harvest,
            steps: _harvestSteps(fieldState),
            sourceRefs: sourceRefs,
            areaDekar: fieldState?.areaDekar,
            plantCount: fieldState?.estimatedPlantCount,
            cropId: cropId,
            cropName: cropName,
          ));
          continue; // hasatta sulama önerme
        }
      }

      // Sulama mantığı — yağmur varsa ertele, aralık dolduysa emir ver
      final daysSinceWater = lastWater == null
          ? (plantedDate != null
              ? t.difference(plantedDate).inDays
              : waterInterval)
          : t.difference(lastWater).inDays;

      if (rainNext48h >= 8) {
        // Önümüzdeki 2 günde ciddi yağış bekleniyor — sulamayı ertele.
        if (daysSinceWater >= waterInterval - 1) {
          out.add(FieldDirective(
            urgency: 0,
            headline: '$cropName: SULAMA ERTELENDİ',
            reason:
                '2 gün içinde ${rainNext48h.toStringAsFixed(0)} mm yağış bekleniyor. Boşa su harcama.',
            kind: 'rain_wait',
            cropId: cropId,
            cropName: cropName,
          ));
        }
      } else if (daysSinceWater >= waterInterval) {
        // Su açığı birikmişse süreye +%20 fazla öner — açığı kapat.
        final waterPlan = _waterRecommendation(
          fieldState: fieldState,
          waterIntervalDays: waterInterval,
          growth: growth,
        );
        final minutes = waterPlan.quantity.round();
        final baseReason = lastWater == null
            ? 'Henüz sulama kaydı yok. $waterInterval gün aralıkla sulama öneriliyor.'
            : 'Son sulama $daysSinceWater gün önce. Aralık $waterInterval gün doldu.';
        final stressNote = _growthStressNote(growth, focus: 'water');
        out.add(FieldDirective(
          urgency: 2,
          headline: '$cropName: BUGÜN $minutes DK SULA',
          reason: stressNote == null ? baseReason : '$baseReason $stressNote',
          kind: 'water_now',
          actionType: ActivityType.watering,
          suggestedQuantity: minutes.toDouble(),
          recommendedQuantity: minutes.toDouble(),
          quantityUnit: 'dk',
          steps: waterPlan.steps,
          sourceRefs: sourceRefs,
          areaDekar: fieldState?.areaDekar,
          plantCount: fieldState?.estimatedPlantCount,
          cropId: cropId,
          cropName: cropName,
        ));
      } else if (daysSinceWater == waterInterval - 1) {
        out.add(FieldDirective(
          urgency: 1,
          headline: '$cropName: YARIN SULA',
          reason:
              'Son sulama $daysSinceWater gün önce. Yarın sabah erken saatlere planla.',
          kind: 'water_soon',
          steps: _fieldScaleSteps(fieldState),
          sourceRefs: sourceRefs,
          areaDekar: fieldState?.areaDekar,
          plantCount: fieldState?.estimatedPlantCount,
          cropId: cropId,
          cropName: cropName,
        ));
      }

      // Yağmur sonrası mantar riski — 10mm+ yağış olduysa 7 gündür ilaçlama yoksa
      if (rainLast24h >= 10) {
        final daysSinceSpray =
            lastSpray == null ? 999 : t.difference(lastSpray).inDays;
        if (daysSinceSpray >= 7) {
          out.add(FieldDirective(
            urgency: 1,
            headline: '$cropName: MANTAR RİSKİ — İLAÇLA',
            reason:
                'Son 24 saatte ${rainLast24h.toStringAsFixed(0)} mm yağdı. Fungisit uygulaması öneriliyor.',
            kind: 'spray',
            actionType: ActivityType.spraying,
            steps: _spraySteps(cropName, fieldState),
            sourceRefs: sourceRefs,
            areaDekar: fieldState?.areaDekar,
            plantCount: fieldState?.estimatedPlantCount,
            cropId: cropId,
            cropName: cropName,
          ));
        }
      }

      // Gübreleme — ekimden sonra aralıklı, 30+ gün geçmişse
      if (plantedDate != null) {
        final elapsed = t.difference(plantedDate).inDays;
        final daysSinceFert =
            lastFert == null ? elapsed : t.difference(lastFert).inDays;
        if (elapsed > 20 && daysSinceFert >= 30 && elapsed < harvestDays - 10) {
          final baseReason = lastFert == null
              ? 'Ekimden $elapsed gün geçti, henüz gübre kaydı yok.'
              : 'Son gübreleme $daysSinceFert gün önce. Büyüme fazında tekrar gerekir.';
          final stressNote = _growthStressNote(growth, focus: 'nitrogen');
          // N stresi yüksekse aciliyeti 2'ye çek — "bu hafta" değil "bugün".
          final urgency = (growth != null && growth.nStressIdx > 0.3) ? 2 : 1;
          final headline = urgency == 2
              ? '$cropName: BUGÜN GÜBRELE'
              : '$cropName: BU HAFTA GÜBRELE';
          final fertPlan = _fertilizerRecommendation(
            cropName: cropName,
            fieldState: fieldState,
            daysSincePlanting: elapsed,
          );
          out.add(FieldDirective(
            urgency: urgency,
            headline: headline,
            reason: stressNote == null ? baseReason : '$baseReason $stressNote',
            kind: 'fertilize',
            actionType: ActivityType.fertilizing,
            suggestedQuantity: fertPlan?.quantity,
            recommendedQuantity: fertPlan?.quantity,
            quantityUnit: fertPlan?.unit,
            steps: fertPlan?.steps ?? _fieldScaleSteps(fieldState),
            sourceRefs: sourceRefs,
            areaDekar: fieldState?.areaDekar,
            plantCount: fieldState?.estimatedPlantCount,
            cropId: cropId,
            cropName: cropName,
          ));
        }
      }
    }

    // ── Her şey yolunda ise ferahlatıcı mesaj ──────────────────
    if (out.isEmpty) {
      out.add(FieldDirective(
        urgency: 0,
        headline: 'BUGÜN YAPILACAK BİR ŞEY YOK',
        reason: _nextCheckHint(fieldCrops, activities, t),
        kind: 'idle',
      ));
    }

    // En acilden bilgiye sırala
    out.sort((a, b) => b.urgency.compareTo(a.urgency));
    return out;
  }

  // ───────────────── auto_seed "yapılmadı" senaryosu ─────────────────

  /// Tarihi geçmiş (bugünden önce) auto_seed takvim kayıtlarını "yapılmadı"
  /// direktiflerine dönüştürür. Her direktif; gecikme gün sayısı + aktif
  /// fenoloji evresi + verim kaybı tahmini ile zenginleştirilir.
  static List<FieldDirective> _overdueAutoSeedDirectives({
    required List<Map<String, dynamic>> scheduledEvents,
    required List<Map<String, dynamic>> fieldCrops,
    required Map<String, GrowthSnapshot>? growthStates,
    required DateTime now,
  }) {
    final cropById = <String, Map<String, dynamic>>{
      for (final c in fieldCrops)
        if (c['id'] != null) c['id'].toString(): c,
    };

    // Aynı cropId + type için yalnız en eski (en kritik) plan; başlığı
    // "3 gündür ihmal edildi" gibi rapor eder. Diğerleri sessizce atlanır.
    final byKey = <String, Map<String, dynamic>>{};
    for (final ev in scheduledEvents) {
      final rawDate = ev['date'];
      DateTime? evDate;
      if (rawDate is DateTime) {
        evDate = rawDate;
      } else if (rawDate is String) {
        evDate = DateTime.tryParse(rawDate);
      }
      if (evDate == null) continue;
      if (!evDate.isBefore(DateTime(now.year, now.month, now.day))) continue;

      final type = ev['type']?.toString() ?? '';
      final cropId = ev['crop_id']?.toString() ?? '';
      final key = '$cropId::$type';
      final prev = byKey[key];
      final prevDate = prev?['date'];
      if (prev == null || (prevDate is DateTime && evDate.isBefore(prevDate))) {
        byKey[key] = ev;
      }
    }

    final out = <FieldDirective>[];
    for (final ev in byKey.values) {
      final cropId = ev['crop_id']?.toString();
      final type = ev['type']?.toString() ?? '';
      final crop = cropId == null ? null : cropById[cropId];
      final cropName =
          (crop?['name']?.toString() ?? ev['title']?.toString() ?? 'Bitki')
              .trim();
      final evDate = ev['date'] as DateTime;
      final lateDays = DateTime(now.year, now.month, now.day)
          .difference(DateTime(evDate.year, evDate.month, evDate.day))
          .inDays;
      final meta = ev['metadata'] is Map
          ? Map<String, dynamic>.from(ev['metadata'] as Map)
          : const <String, dynamic>{};
      final recommended = (ev['recommended_quantity'] as num?)?.toDouble();
      final unit = ev['unit']?.toString();
      final growth = cropId == null ? null : growthStates?[cropId];

      final stageLabel = _stageLabelFromSnapshot(growth);
      final lossNote = growth != null && growth.yieldLossPct > 4
          ? ' Verim tahmini %${growth.yieldLossPct} düştü.'
          : '';
      final urgency = lateDays >= 3 ? 2 : 1;
      final cropLabel = cropName.isEmpty ? 'Bitki' : cropName;

      switch (type) {
        case 'watering':
          final minutes = recommended?.round();
          out.add(FieldDirective(
            urgency: urgency,
            headline: minutes == null
                ? '$cropLabel: SULAMA GECİKTİ'
                : '$cropLabel: $minutes DK SULA (GECİKTİ)',
            reason:
                'Takvimdeki sulama $lateDays gün önce planlıydı, kayıt yok. '
                '${stageLabel.isEmpty ? '' : '$stageLabel evresinde '}'
                'kök su açığı birikir.$lossNote',
            kind: 'overdue_water',
            actionType: ActivityType.watering,
            suggestedQuantity: recommended,
            recommendedQuantity: recommended,
            quantityUnit: unit,
            cropId: cropId,
            cropName: cropName,
          ));
          break;
        case 'fertilizing':
          final productName = meta['fertilizer_name']?.toString();
          final dose = recommended?.toStringAsFixed(1);
          out.add(FieldDirective(
            urgency: urgency,
            headline: '$cropLabel: ${productName ?? 'GÜBRELEME'} GECİKTİ',
            reason: productName == null
                ? 'Planlı gübreleme $lateDays gündür yapılmadı. '
                    '${stageLabel.isEmpty ? '' : '$stageLabel evresinde '}'
                    'azot yetmezliği başlıyor.$lossNote'
                : '$productName ${dose ?? '—'} ${unit ?? ''} uygulaması '
                    '$lateDays gün önce planlıydı. '
                    '${stageLabel.isEmpty ? '' : '$stageLabel evresinde '}'
                    'gecikme verim kaybına döner.$lossNote',
            kind: 'overdue_fertilize',
            actionType: ActivityType.fertilizing,
            suggestedQuantity: recommended,
            recommendedQuantity: recommended,
            quantityUnit: unit,
            steps: [
              if (meta['tip'] is String) meta['tip'] as String,
            ],
            cropId: cropId,
            cropName: cropName,
          ));
          break;
        case 'spraying':
          final productName = meta['pesticide_name']?.toString();
          final targets = (meta['targets'] as List?)?.join(', ');
          out.add(FieldDirective(
            urgency: urgency,
            headline: '$cropLabel: ${productName ?? 'İLAÇLAMA'} GECİKTİ',
            reason: productName == null
                ? 'Koruyucu ilaçlama $lateDays gün önce planlıydı.$lossNote'
                : '$productName uygulaması $lateDays gün önce planlıydı'
                    '${targets == null ? '' : ' ($targets)'}'
                    '.$lossNote',
            kind: 'overdue_spray',
            actionType: ActivityType.spraying,
            suggestedQuantity: recommended,
            recommendedQuantity: recommended,
            quantityUnit: unit,
            steps: [
              if (meta['tip'] is String) meta['tip'] as String,
            ],
            cropId: cropId,
            cropName: cropName,
          ));
          break;
      }
    }
    return out;
  }

  static String _stageLabelFromSnapshot(GrowthSnapshot? g) {
    if (g == null) return '';
    switch (g.stageKey) {
      case 'cimlenme':
        return 'çimlenme';
      case 'vejetatif':
        return 'vejetatif büyüme';
      case 'ciceklenme':
        return 'çiçeklenme';
      case 'meyve_dolumu':
        return 'meyve dolumu';
      case 'olgunlasma':
        return 'olgunlaşma';
      default:
        return '';
    }
  }

  // ───────────────────────────── yardımcılar ─────────────────

  /// 3 vitrin bitki için aktif yetiştirme adımını direktif olarak üretir.
  /// Eşleşen protokol yoksa veya tüm adımlar tamamsa null döner.
  static FieldDirective? _protocolStepDirective({
    required Map<String, dynamic> crop,
    required String? cropId,
    required String cropName,
    required DateTime? plantedDate,
    required List<Map<String, dynamic>> activitiesForCrop,
    required DateTime now,
    CropFieldState? fieldState,
    List<String> sourceRefs = const [],
  }) {
    final protocol = CropProtocols.resolveByName(crop['name']?.toString());
    if (protocol == null || plantedDate == null) return null;

    final daysSince = now.difference(plantedDate).inDays;
    ProtocolStep? active;
    int completed = 0;
    for (final step in protocol.steps) {
      if (daysSince < step.dayOffset) break;
      bool isDone;
      if (step.expectedActivity == null) {
        // Sonraki adımın günü geldiyse otomatik tamam.
        int? nextOffset;
        for (final s in protocol.steps) {
          if (s.order > step.order) {
            nextOffset = s.dayOffset;
            break;
          }
        }
        isDone = nextOffset != null && daysSince >= nextOffset;
      } else {
        isDone = activitiesForCrop
            .any((a) => a['type']?.toString() == step.expectedActivity);
      }
      if (isDone) {
        completed++;
      } else {
        active = step;
        break;
      }
    }

    if (active == null) return null;

    final remainingDays = active.dayOffset - daysSince;
    final urgency = remainingDays <= 0 ? 2 : (remainingDays <= 3 ? 1 : 0);

    return FieldDirective(
      urgency: urgency,
      headline:
          '${protocol.emoji} $cropName: Adım ${active.order}/${protocol.steps.length} — ${active.title}',
      reason:
          '${active.description}\n\nİlerleme: $completed/${protocol.steps.length} adım tamam.',
      kind: 'protocol_step',
      actionType: active.expectedActivity,
      steps: _protocolSteps(active, fieldState),
      sourceRefs: sourceRefs,
      areaDekar: fieldState?.areaDekar,
      plantCount: fieldState?.estimatedPlantCount,
      cropId: cropId,
      cropName: cropName,
    );
  }

  /// Büyüme durumuna göre direktif reason'una eklenecek stres/verim notu.
  /// [focus]: hangi stresin vurgulanacağı — 'water' veya 'nitrogen'. Null
  /// dönerse reason değiştirilmez (stres yok / snapshot yok).
  static String? _growthStressNote(GrowthSnapshot? g, {required String focus}) {
    if (g == null || !g.hasStress) return null;
    final loss = g.yieldLossPct;
    if (focus == 'water' && g.waterDeficitMm > 2.0) {
      final mm = g.waterDeficitMm.toStringAsFixed(0);
      return loss > 5
          ? 'Biriken su açığı $mm mm — verim tahmini %$loss düştü.'
          : 'Biriken su açığı $mm mm.';
    }
    if (focus == 'nitrogen' && g.nStressIdx > 0.15) {
      final pct = (g.nStressIdx * 100).round();
      return loss > 5
          ? 'Azot stresi %$pct — verim tahmini %$loss düştü, gecikme verim kaybını artırır.'
          : 'Azot stresi %$pct seviyesinde, gecikme verim kaybını artırır.';
    }
    return null;
  }

  static int _estimateWateringMinutes(int interval) {
    if (interval <= 2) return 10;
    if (interval <= 4) return 20;
    if (interval <= 6) return 30;
    return 45;
  }

  static _QuantityPlan _waterRecommendation({
    required CropFieldState? fieldState,
    required int waterIntervalDays,
    required GrowthSnapshot? growth,
  }) {
    final baseMinutes = _estimateWateringMinutes(waterIntervalDays).toDouble();
    if (fieldState == null ||
        fieldState.areaSqm <= 0 ||
        fieldState.estimatedPlantCount <= 0) {
      final adjusted = growth != null && growth.waterDeficitMm > 5
          ? baseMinutes * 1.2
          : baseMinutes;
      return _QuantityPlan(
        quantity: adjusted.roundToDouble(),
        unit: 'dk',
        steps: const ['Sulamayı sabah erken veya güneş battıktan sonra yap.'],
      );
    }

    final targetMm = fieldState.weeklyWaterTargetMm <= 0
        ? 25.0
        : fieldState.weeklyWaterTargetMm;
    final remainingMm = math.max(
      targetMm - fieldState.weeklyWaterMm,
      targetMm * (waterIntervalDays / 7.0).clamp(0.35, 1.0),
    );
    final stressMm = math.max(0.0, growth?.waterDeficitMm ?? 0.0);
    final totalMm = remainingMm + stressMm * 0.35;
    final liters = totalMm * fieldState.areaSqm;
    const dripperLiterPerHour = 1.6;
    final minutes =
        (liters / (fieldState.estimatedPlantCount * dripperLiterPerHour) * 60)
            .clamp(5.0, 480.0);
    final impact = WaterAccounting.calculate(
      metadata: const {'irrigation_method': 'Damla sulama'},
      quantity: minutes,
      quantityUnit: 'dk',
      areaSqm: fieldState.areaSqm,
      plantCount: fieldState.estimatedPlantCount,
    );

    return _QuantityPlan(
      quantity: minutes.roundToDouble(),
      unit: 'dk',
      steps: [
        '${fieldState.areaDekar.toStringAsFixed(2)} da alanda ${fieldState.estimatedPlantCount} bitki hesaba katıldı.',
        'Hedef su: ${impact.mm.toStringAsFixed(1)} mm, yaklaşık ${impact.liters.round()} L.',
        'Damla sulama varsayımı ile ${minutes.round()} dk uygula; karıkta toprak tava gelince kes.',
      ],
    );
  }

  static _QuantityPlan? _fertilizerRecommendation({
    required String cropName,
    required CropFieldState? fieldState,
    required int daysSincePlanting,
  }) {
    final pb = CropPlaybooks.resolveByName(cropName);
    if (pb == null || pb.fertilizers.isEmpty || fieldState == null) {
      return null;
    }

    FertilizerProduct product = pb.fertilizers.first;
    for (final f in pb.fertilizers) {
      final stage = f.stage.toLowerCase();
      if (daysSincePlanting >= 50 &&
          (stage.contains('55') ||
              stage.contains('60') ||
              stage.contains('meyve'))) {
        product = f;
      } else if (daysSincePlanting < 50 &&
          (stage.contains('21') ||
              stage.contains('25') ||
              stage.contains('ilk'))) {
        product = f;
        break;
      }
    }

    final total = product.defaultDosePerDa * fieldState.areaDekar;
    return _QuantityPlan(
      quantity: total,
      unit: product.unit,
      steps: [
        '${product.name}: ${product.defaultDosePerDa.toStringAsFixed(1)} ${product.unit}/da.',
        '${fieldState.areaDekar.toStringAsFixed(2)} da için toplam ${total.toStringAsFixed(1)} ${product.unit}.',
        product.tip ??
            'Gübreyi kök boğazına değdirmeden uygula ve ardından hafif sulama yap.',
      ],
    );
  }

  static List<String> _spraySteps(String cropName, CropFieldState? fieldState) {
    final pb = CropPlaybooks.resolveByName(cropName);
    final pesticide =
        pb?.pesticides.isNotEmpty == true ? pb!.pesticides.first : null;
    return [
      ..._fieldScaleSteps(fieldState),
      if (pesticide != null)
        '${pesticide.name}: ${pesticide.defaultDosePerDa.toStringAsFixed(0)} ${pesticide.unit}/da; etiket ve il/ilçe teknik önerisiyle uygula.',
      'Rüzgarlı saatte ilaçlama yapma; yaprak altı ve hastalık belirtisini önce kontrol et.',
    ];
  }

  static List<String> _harvestSteps(CropFieldState? fieldState) {
    return [
      ..._fieldScaleSteps(fieldState),
      'Sabah serinliğinde hasat et ve ıslak ürünü kasaya alma.',
      if (fieldState != null && fieldState.harvestedKg > 0)
        'Önceki kayıt: ${fieldState.harvestSummary}.',
    ];
  }

  static List<String> _protocolSteps(
      ProtocolStep step, CropFieldState? fieldState) {
    return [
      ..._fieldScaleSteps(fieldState),
      if (step.fertilizerSpec != null) step.fertilizerSpec!,
      if (step.waterSpec != null) step.waterSpec!,
      if (step.pesticideSpec != null) step.pesticideSpec!,
      if (step.criticalWarning != null) step.criticalWarning!,
      if (step.farmerTip != null) step.farmerTip!,
    ];
  }

  static List<String> _fieldScaleSteps(CropFieldState? fieldState) {
    if (fieldState == null) return const [];
    return [
      '${fieldState.areaDekar.toStringAsFixed(2)} da ekim alanı.',
      '${fieldState.estimatedPlantCount} tahmini bitki; su ve gübre hesabı bu alana göre yapıldı.',
    ];
  }

  static List<String> _sourceRefsFor(String cropName) {
    final guide = TurkiyeCropGuides.lookup(cropName);
    return guide?.sourceRefs ?? const [];
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

  static DateTime? _lastActivity(List<Map<String, dynamic>> acts, String type) {
    DateTime? latest;
    for (final a in acts) {
      if (a['type']?.toString() != type) continue;
      final date = a['date'];
      if (date is DateTime) {
        if (latest == null || date.isAfter(latest)) latest = date;
      }
    }
    return latest;
  }

  static List<_ForecastDay> _parseForecast(List<dynamic>? raw) {
    if (raw == null) return const [];
    final out = <_ForecastDay>[];
    for (final d in raw) {
      if (d is Map) {
        out.add(_ForecastDay(
          max: (d['max'] as num?)?.toDouble() ?? 0,
          min: (d['min'] as num?)?.toDouble() ?? 0,
          rain: (d['rain'] as num?)?.toDouble() ?? 0,
        ));
      }
    }
    return out;
  }

  static double _sumRain(
      List<_ForecastDay> f, int fromIdx, int toIdxInclusive) {
    double s = 0;
    for (var i = fromIdx; i <= toIdxInclusive && i < f.length; i++) {
      s += f[i].rain;
    }
    return s;
  }

  static double _rainYesterday(List<_ForecastDay> f) {
    // forecast[0] = bugün; "son 24 saat" yaklaşımı için bugünkü yağışı alıyoruz.
    return f.isEmpty ? 0 : f[0].rain;
  }

  static String _nextCheckHint(
    List<Map<String, dynamic>> crops,
    List<Map<String, dynamic>> activities,
    DateTime t,
  ) {
    int? minDays;
    for (final crop in crops) {
      final interval = (crop['water_interval_days'] as num?)?.toInt() ?? 7;
      final lastWater = _lastActivity(activities, ActivityType.watering);
      final days =
          lastWater == null ? interval : t.difference(lastWater).inDays;
      final remaining = interval - days;
      if (remaining > 0 && (minDays == null || remaining < minDays)) {
        minDays = remaining;
      }
    }
    if (minDays == null) return 'Kayıtlı aktivitelere göre tarlan güncel.';
    return 'Bir sonraki sulama için $minDays gün var.';
  }
}

class _ForecastDay {
  final double max;
  final double min;
  final double rain;
  const _ForecastDay(
      {required this.max, required this.min, required this.rain});
}

class _QuantityPlan {
  final double quantity;
  final String unit;
  final List<String> steps;

  const _QuantityPlan({
    required this.quantity,
    required this.unit,
    required this.steps,
  });
}
