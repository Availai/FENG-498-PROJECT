/// Anlık birleşik tarla durumu — guardrail motorunun girdisi.
///
/// "Tarla verisi çok net saklanmalı ve anında güncellenmeli" hedefinin
/// modeli. **Yeni DB tablosu gerektirmez** (CLAUDE.md §6): mevcut aktivite
/// kayıtları + `SoilTests` + `FieldStateService` çıktısından türetilir.
///
/// Saf builder (§22): aktivite listesi + lab değerleri girer, motora hazır
/// alanlar çıkar. IO yok — repository katmanı verileri okuyup buraya verir,
/// her aktivite kaydından sonra (mevcut `ActivityLogger` zinciri) yeniden
/// kurulur → "anlık güncelleme" buradan gelir.
library;

import 'dart:convert';

import '../../data/activity_types.dart';
import '../../data/supported_crops.dart';
import '../water_accounting.dart';

/// Bir ürün için guardrail değerlendirmesine yetecek anlık durum.
class FieldSnapshot {
  final String cropName;
  final double areaDekar;

  /// Bu hafta (son 7 gün) verilen etken su (mm). Su ekseni guardrail'ı.
  final double currentWeeklyWaterMm;

  /// Sezon boyunca verilen **saf azot** birikimi (kg N/dekar). Azot ekseni.
  final double seasonalNitrogenKgDa;

  /// Lab toprak analizinden ölçülen EC (dS/m). null → analiz yok / EC yok.
  final double? measuredEcDsM;

  /// Toprak analizi kaydı var mı? §16: azot block'u yalnızca analiz varsa.
  final bool hasSoilTest;

  /// Son ilaçlamadan bu yana geçen saat. null → ilaçlama kaydı yok.
  final double? hoursSinceLastSpray;

  /// Son uygulanan etken madde / ilaç adı (REI lookup için). null → yok.
  final String? lastPesticideName;

  const FieldSnapshot({
    required this.cropName,
    required this.areaDekar,
    required this.currentWeeklyWaterMm,
    required this.seasonalNitrogenKgDa,
    required this.measuredEcDsM,
    required this.hasSoilTest,
    required this.hoursSinceLastSpray,
    required this.lastPesticideName,
  });
}

class FieldSnapshotBuilder {
  FieldSnapshotBuilder._();

  /// Aktivite listesi + lab değerlerinden anlık durum kur.
  ///
  /// [activities] `field_state_service` ile aynı ham şekil:
  /// `{type, date(DateTime), crop_id, metadata}`.
  /// [soilTest] tek bir lab kaydının alanları (null → analiz yok).
  static FieldSnapshot build({
    required String cropName,
    required double areaDekar,
    required List<Map<String, dynamic>> activities,
    required double weeklyWaterMm,
    Map<String, dynamic>? soilTest,
    DateTime? now,
  }) {
    final t = now ?? DateTime.now();

    double seasonalNkg = 0; // toplam saf N (kg), alana bölmeden önce
    DateTime? lastSpray;
    String? lastPesticide;

    for (final a in activities) {
      final type = a['type']?.toString();
      final date = a['date'];
      if (date is! DateTime || date.isAfter(t)) continue;
      final meta = _metadata(a);

      if (type == ActivityType.fertilizing) {
        final fertName =
            _stringValue(meta, ['fertilizer_name', 'material_name', 'note']);
        final rawKg = _doubleValue(meta, ['fertilizer_kg', 'quantity']);
        if (rawKg != null && rawKg > 0) {
          // Ham gübre kg → saf N kg. Gübre adından N içeriği çözülür;
          // çözülemezse muhafazakâr varsayım (kompoze ~%15 N).
          seasonalNkg += rawKg * _nitrogenFraction(fertName);
        }
      } else if (type == ActivityType.spraying) {
        if (lastSpray == null || date.isAfter(lastSpray)) {
          lastSpray = date;
          lastPesticide =
              _stringValue(meta, ['pesticide_name', 'material_name', 'note']);
        }
      }
    }

    final seasonalNkgDa = areaDekar > 0 ? seasonalNkg / areaDekar : 0.0;
    final hoursSinceSpray =
        lastSpray == null ? null : t.difference(lastSpray).inMinutes / 60.0;

    final ec =
        soilTest == null ? null : _doubleValue(soilTest, ['ec_ds_m', 'ecDsM']);
    final hasSoilTest = soilTest != null && soilTest.isNotEmpty;

    return FieldSnapshot(
      cropName: cropName,
      areaDekar: areaDekar,
      currentWeeklyWaterMm: weeklyWaterMm,
      seasonalNitrogenKgDa: seasonalNkgDa,
      measuredEcDsM: ec,
      hasSoilTest: hasSoilTest,
      hoursSinceLastSpray: hoursSinceSpray,
      lastPesticideName: lastPesticide,
    );
  }

  /// Bir kayıt yapılmadan ÖNCE, su attempt'inin mm karşılığını hesaplar —
  /// guardrail su kontrolü için. Mevcut `WaterAccounting` ile aynı mantık,
  /// böylece kayıt sonrası birikime tutarlı eklenir.
  static double waterAttemptMm({
    required Map<String, dynamic> metadata,
    double? quantity,
    String? quantityUnit,
    required double areaDekar,
    int? plantCount,
    String? irrigationMethod,
  }) {
    final impact = WaterAccounting.calculate(
      metadata: metadata,
      quantity: quantity,
      quantityUnit: quantityUnit,
      areaSqm: (areaDekar <= 0 ? 1.0 : areaDekar) * 1000.0,
      plantCount: plantCount,
      irrigationMethod: irrigationMethod,
    );
    return impact.mm;
  }

  /// Bir gübreleme kaydının saf N karşılığı (kg N/dekar) — guardrail azot
  /// attempt'i için. Ham kg + gübre adı → saf N, sonra alana böl.
  static double nitrogenAttemptKgDa({
    required String? fertilizerName,
    required double? rawKg,
    required double areaDekar,
  }) {
    if (rawKg == null || rawKg <= 0 || areaDekar <= 0) return 0;
    return rawKg * _nitrogenFraction(fertilizerName) / areaDekar;
  }

  // ── Gübre adı → saf N oranı (kütlece) ──────────────────────────────
  /// Kaynak: yaygın gübrelerin etiket besin içerikleri (TAGEM çiftçi
  /// rehberleri). Çözülemeyen ad için muhafazakâr kompoze varsayımı.
  static double _nitrogenFraction(String? fertilizerName) {
    if (fertilizerName == null || fertilizerName.trim().isEmpty) return 0.15;
    final f = SupportedCrops.normalize(fertilizerName);
    if (f.contains('ure')) return 0.46; // Üre %46 N
    if (f.contains('amonyumsulfat') || f.contains('as21')) return 0.21;
    if (f.contains('can')) return 0.26; // Kalsiyum amonyum nitrat %26
    if (f.contains('amonyumnitrat')) return 0.33;
    if (f.contains('dap')) return 0.18; // 18-46-0
    if (f.contains('151515') || f.contains('kompoze')) return 0.15;
    if (f.contains('202020')) return 0.20;
    if (f.contains('potasyumnitrat')) return 0.13;
    // Saf P/K kaynakları (MKP, potasyum sülfat) azot içermez.
    if (f.contains('mkp') ||
        f.contains('potasyumsulfat') ||
        f.contains('0060') ||
        f.contains('00')) {
      return 0.0;
    }
    // Organik / çiftlik gübresi — düşük, yavaş salınan N (~%0.5).
    if (f.contains('ciftlik') ||
        f.contains('ahir') ||
        f.contains('kompost') ||
        f.contains('organik')) {
      return 0.005;
    }
    return 0.15; // bilinmeyen kompoze varsayımı
  }

  static Map<String, dynamic> _metadata(Map<String, dynamic> activity) {
    final raw = activity['metadata'];
    if (raw is Map) return Map<String, dynamic>.from(raw);
    if (raw is String && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map) return Map<String, dynamic>.from(decoded);
      } catch (_) {}
    }
    return <String, dynamic>{};
  }

  static String? _stringValue(Map<String, dynamic> meta, List<String> keys) {
    for (final key in keys) {
      final value = meta[key]?.toString().trim();
      if (value != null && value.isNotEmpty) return value;
    }
    return null;
  }

  static double? _doubleValue(Map<String, dynamic> meta, List<String> keys) {
    for (final key in keys) {
      final value = meta[key];
      if (value is num) return value.toDouble();
      if (value is String) {
        final parsed = double.tryParse(value.replaceAll(',', '.'));
        if (parsed != null) return parsed;
      }
    }
    return null;
  }
}
