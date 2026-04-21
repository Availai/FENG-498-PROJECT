import '../data/activity_types.dart';

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
  List<FieldDirective> generate({
    required List<Map<String, dynamic>> fieldCrops,
    required List<Map<String, dynamic>> activities,
    List<dynamic>? dailyForecast,
    double? currentTemp,
    double? soilMoisture,
    DateTime? now,
  }) {
    final t = now ?? DateTime.now();
    final out = <FieldDirective>[];

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
        reason: 'Henüz ekili bitki yok. "Tarlayı Tara" ile uygun çeşitleri gör.',
        kind: 'empty',
      ));
      return out;
    }

    // ── Global hava uyarıları (tüm tarlaya) ────────────────────
    if (tomorrowMin != null && tomorrowMin < 2) {
      out.add(FieldDirective(
        urgency: 2,
        headline: 'DON UYARISI — YARIN',
        reason: 'Yarın gece ${tomorrowMin.toStringAsFixed(0)}°C. Hassas fideleri ört, sulamayı sabaha bırak.',
        kind: 'frost',
      ));
    }
    if (tomorrowMax != null && tomorrowMax > 35) {
      out.add(FieldDirective(
        urgency: 1,
        headline: 'YARIN AŞIRI SICAK',
        reason: 'Yarın en yüksek ${tomorrowMax.toStringAsFixed(0)}°C. Sulamayı 06:00-08:00 arasına al.',
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
      final lastFert = _lastActivity(activitiesForCrop, ActivityType.fertilizing);
      final lastSpray = _lastActivity(activitiesForCrop, ActivityType.spraying);

      // Hasat kontrolü
      if (plantedDate != null) {
        final elapsed = t.difference(plantedDate).inDays;
        if (elapsed >= harvestDays) {
          out.add(FieldDirective(
            urgency: 2,
            headline: '$cropName: HASAT ZAMANI',
            reason: 'Ekimden $elapsed gün geçti (hedef $harvestDays gün). Verim düşmeden topla.',
            kind: 'harvest',
            actionType: ActivityType.harvest,
            cropId: cropId,
            cropName: cropName,
          ));
          continue; // hasatta sulama önerme
        }
      }

      // Sulama mantığı — yağmur varsa ertele, aralık dolduysa emir ver
      final daysSinceWater = lastWater == null
          ? (plantedDate != null ? t.difference(plantedDate).inDays : waterInterval)
          : t.difference(lastWater).inDays;

      if (rainNext48h >= 8) {
        // Önümüzdeki 2 günde ciddi yağış bekleniyor — sulamayı ertele.
        if (daysSinceWater >= waterInterval - 1) {
          out.add(FieldDirective(
            urgency: 0,
            headline: '$cropName: SULAMA ERTELENDİ',
            reason: '2 gün içinde ${rainNext48h.toStringAsFixed(0)} mm yağış bekleniyor. Boşa su harcama.',
            kind: 'rain_wait',
            cropId: cropId,
            cropName: cropName,
          ));
        }
      } else if (daysSinceWater >= waterInterval) {
        final minutes = _estimateWateringMinutes(waterInterval);
        out.add(FieldDirective(
          urgency: 2,
          headline: '$cropName: BUGÜN $minutes DK SULA',
          reason: lastWater == null
              ? 'Henüz sulama kaydı yok. $waterInterval gün aralıkla sulama öneriliyor.'
              : 'Son sulama $daysSinceWater gün önce. Aralık $waterInterval gün doldu.',
          kind: 'water_now',
          actionType: ActivityType.watering,
          suggestedQuantity: minutes.toDouble(),
          quantityUnit: 'dk',
          cropId: cropId,
          cropName: cropName,
        ));
      } else if (daysSinceWater == waterInterval - 1) {
        out.add(FieldDirective(
          urgency: 1,
          headline: '$cropName: YARIN SULA',
          reason: 'Son sulama $daysSinceWater gün önce. Yarın sabah erken saatlere planla.',
          kind: 'water_soon',
          cropId: cropId,
          cropName: cropName,
        ));
      }

      // Yağmur sonrası mantar riski — 10mm+ yağış olduysa 7 gündür ilaçlama yoksa
      if (rainLast24h >= 10) {
        final daysSinceSpray = lastSpray == null
            ? 999
            : t.difference(lastSpray).inDays;
        if (daysSinceSpray >= 7) {
          out.add(FieldDirective(
            urgency: 1,
            headline: '$cropName: MANTAR RİSKİ — İLAÇLA',
            reason: 'Son 24 saatte ${rainLast24h.toStringAsFixed(0)} mm yağdı. Fungisit uygulaması öneriliyor.',
            kind: 'spray',
            actionType: ActivityType.spraying,
            cropId: cropId,
            cropName: cropName,
          ));
        }
      }

      // Gübreleme — ekimden sonra aralıklı, 30+ gün geçmişse
      if (plantedDate != null) {
        final elapsed = t.difference(plantedDate).inDays;
        final daysSinceFert = lastFert == null
            ? elapsed
            : t.difference(lastFert).inDays;
        if (elapsed > 20 && daysSinceFert >= 30 && elapsed < harvestDays - 10) {
          out.add(FieldDirective(
            urgency: 1,
            headline: '$cropName: BU HAFTA GÜBRELE',
            reason: lastFert == null
                ? 'Ekimden $elapsed gün geçti, henüz gübre kaydı yok.'
                : 'Son gübreleme $daysSinceFert gün önce. Büyüme fazında tekrar gerekir.',
            kind: 'fertilize',
            actionType: ActivityType.fertilizing,
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

  // ───────────────────────────── yardımcılar ─────────────────

  static int _estimateWateringMinutes(int interval) {
    if (interval <= 2) return 10;
    if (interval <= 4) return 20;
    if (interval <= 6) return 30;
    return 45;
  }

  static DateTime? _parsePlantedDate(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    final parts = raw.split('.');
    if (parts.length == 3) {
      final iso = '${parts[2]}-${parts[1].padLeft(2, '0')}-${parts[0].padLeft(2, '0')}';
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

  static double _sumRain(List<_ForecastDay> f, int fromIdx, int toIdxInclusive) {
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
      final days = lastWater == null ? interval : t.difference(lastWater).inDays;
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
  const _ForecastDay({required this.max, required this.min, required this.rain});
}
