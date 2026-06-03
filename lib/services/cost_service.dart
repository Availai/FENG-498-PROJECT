/// Maliyet motoru — ürün bazlı gider toplama + kâr tahmini.
///
/// Saf fonksiyon (IO yok, deterministik). Girdiler repository/provider
/// katmanında Drift satırlarından üretilip verilir.
///
/// İki gider kaynağı birleştirilir:
///   • OTOMATİK — loglanan gübreleme aktiviteleri (kg × güncel gübre fiyatı).
///     Uygulama veritabanından (CalendarEvents) gelir; her zaman güncel.
///   • MANUEL — çiftçinin girdiği mazot/tohum/işçilik/ilaç/diğer kalemleri.
/// Hepsi ürüne (cropId) atfedilir; cropId yoksa "tarla geneli" sayılır.
library;

import 'price_book.dart';
import 'yield_calculation_service.dart';

/// Gider türü anahtarları (dahili; UI Türkçe etiket eşler).
class CostKinds {
  static const fertilizer = 'fertilizer';
  static const fuel = 'fuel';
  static const seed = 'seed';
  static const labor = 'labor';
  static const pesticide = 'pesticide';
  static const irrigation = 'irrigation';
  static const other = 'other';

  static const all = [
    fertilizer,
    fuel,
    seed,
    labor,
    pesticide,
    irrigation,
    other,
  ];

  static String label(String kind) {
    switch (kind) {
      case fertilizer:
        return 'Gübre';
      case fuel:
        return 'Mazot / Yakıt';
      case seed:
        return 'Tohum';
      case labor:
        return 'İşçilik';
      case pesticide:
        return 'İlaç (BKÜ)';
      case irrigation:
        return 'Sulama';
      default:
        return 'Diğer';
    }
  }
}

enum CostSource { auto, manual }

/// Tarladaki bir ürün (gider atfı için).
class CostCrop {
  final String id;
  final String name;

  /// Ürünün yaklaşık alanı (dekar) — kâr tahmini için. null → kâr atlanır.
  final double? areaDekar;

  const CostCrop({required this.id, required this.name, this.areaDekar});
}

/// Loglanmış aktivite (yalnız gübreleme maliyete dönüşür).
class CostActivity {
  final String? cropId;
  final String type; // ActivityType anahtarı, ör. 'fertilizing'
  final double? fertilizerKg;
  final String? fertilizerName;

  const CostActivity({
    required this.type,
    this.cropId,
    this.fertilizerKg,
    this.fertilizerName,
  });
}

/// Manuel gider kaydı (Drift CostEntries'ten map'lenir).
class ManualCost {
  final String id;
  final String? cropId;
  final String kind;
  final double amountTry;
  final String? note;
  final DateTime date;

  const ManualCost({
    required this.id,
    required this.kind,
    required this.amountTry,
    required this.date,
    this.cropId,
    this.note,
  });
}

/// Tek gider satırı (otomatik veya manuel).
class CostLineItem {
  final String id; // manuel kayıt id'si veya otomatik için sentetik
  final String kind;
  final String label;
  final double amountTry;
  final CostSource source;
  final String? detail;

  const CostLineItem({
    required this.id,
    required this.kind,
    required this.label,
    required this.amountTry,
    required this.source,
    this.detail,
  });
}

/// Bir ürün (veya tarla geneli) için gider kırılımı.
class CropCostBreakdown {
  final String? cropId; // null → tarla geneli
  final String cropName;
  final List<CostLineItem> items;
  final double total;
  final double? estimatedYieldKg;
  final double? estimatedRevenue;
  final double? estimatedProfit;

  const CropCostBreakdown({
    required this.cropId,
    required this.cropName,
    required this.items,
    required this.total,
    this.estimatedYieldKg,
    this.estimatedRevenue,
    this.estimatedProfit,
  });

  bool get hasProfitEstimate => estimatedProfit != null;
}

/// Tarla geneli rapor.
class FieldCostReport {
  final List<CropCostBreakdown> crops;
  final CropCostBreakdown? shared;
  final double grandTotal;
  final Map<String, double> byCategory;

  const FieldCostReport({
    required this.crops,
    required this.shared,
    required this.grandTotal,
    required this.byCategory,
  });

  bool get isEmpty =>
      grandTotal == 0 && crops.every((c) => c.items.isEmpty) && shared == null;
}

class CostService {
  CostService._();

  static FieldCostReport build({
    required List<CostCrop> crops,
    required List<CostActivity> activities,
    required List<ManualCost> manualEntries,
    required PriceBook prices,
  }) {
    final yieldSvc = YieldCalculationService();
    final byCategory = <String, double>{};

    void addCategory(String kind, double amount) {
      byCategory[kind] = (byCategory[kind] ?? 0) + amount;
    }

    // ── Otomatik gübre giderini cropId'ye göre topla ──────────────────────
    // cropId değeri null → 'tarla geneli' kovasına ('' anahtar) gider.
    final autoFertByCrop = <String, double>{}; // cropKey -> ₺
    final autoFertKgByCrop = <String, double>{};
    final autoFertCountByCrop = <String, int>{};
    for (final a in activities) {
      if (a.type != 'fertilizing') continue;
      final kg = a.fertilizerKg;
      if (kg == null || kg <= 0) continue;
      final cost = kg * prices.fertilizerForName(a.fertilizerName);
      final key = a.cropId ?? '';
      autoFertByCrop[key] = (autoFertByCrop[key] ?? 0) + cost;
      autoFertKgByCrop[key] = (autoFertKgByCrop[key] ?? 0) + kg;
      autoFertCountByCrop[key] = (autoFertCountByCrop[key] ?? 0) + 1;
    }

    // ── Manuel giderleri cropId'ye göre grupla ────────────────────────────
    final manualByCrop = <String, List<ManualCost>>{};
    for (final m in manualEntries) {
      final key = m.cropId ?? '';
      manualByCrop.putIfAbsent(key, () => []).add(m);
    }

    CropCostBreakdown buildBreakdown({
      required String? cropId,
      required String cropName,
      double? areaDekar,
    }) {
      final key = cropId ?? '';
      final items = <CostLineItem>[];

      // Otomatik gübre satırı (tek özet kalem).
      final autoCost = autoFertByCrop[key] ?? 0;
      if (autoCost > 0) {
        final kg = autoFertKgByCrop[key] ?? 0;
        final cnt = autoFertCountByCrop[key] ?? 0;
        items.add(CostLineItem(
          id: 'auto_fert_$key',
          kind: CostKinds.fertilizer,
          label: 'Gübre (kayıtlı uygulamalar)',
          amountTry: autoCost,
          source: CostSource.auto,
          detail: '$cnt uygulama · toplam ${_fmt(kg)} kg',
        ));
        addCategory(CostKinds.fertilizer, autoCost);
      }

      // Manuel kalemler.
      for (final m in (manualByCrop[key] ?? const <ManualCost>[])) {
        items.add(CostLineItem(
          id: m.id,
          kind: m.kind,
          label: CostKinds.label(m.kind),
          amountTry: m.amountTry,
          source: CostSource.manual,
          detail: (m.note != null && m.note!.trim().isNotEmpty)
              ? m.note!.trim()
              : null,
        ));
        addCategory(m.kind, m.amountTry);
      }

      final total = items.fold<double>(0, (s, e) => s + e.amountTry);

      // Kâr tahmini — yalnız alan + satış fiyatı varsa.
      double? yieldKg, revenue, profit;
      final sale = prices.saleForCrop(cropName);
      if (cropId != null && areaDekar != null && areaDekar > 0 && sale > 0) {
        final r = yieldSvc.hesapla(
          bitkiTuru: cropName,
          dekar: areaDekar,
          haftalikSuIhtiyaciMm: 40,
          haftalikVerilenSuMm: 40,
          maksSicaklikLimitC: 32,
          asilanGunSayisi: 0,
          gubreVerildiMi: autoCost > 0,
          satisFiyatiPerKg: sale,
          toplamMasrafTl: total,
        );
        yieldKg = r.tahminiRekolte;
        revenue = r.tahminiRekolte * sale;
        profit = r.tahminiKar;
      }

      return CropCostBreakdown(
        cropId: cropId,
        cropName: cropName,
        items: items,
        total: total,
        estimatedYieldKg: yieldKg,
        estimatedRevenue: revenue,
        estimatedProfit: profit,
      );
    }

    final cropReports = <CropCostBreakdown>[
      for (final c in crops)
        buildBreakdown(
          cropId: c.id,
          cropName: c.name,
          areaDekar: c.areaDekar,
        ),
    ];

    // Tarla geneli (cropId null) — yalnız ilgili kalem varsa.
    CropCostBreakdown? shared;
    final hasSharedAuto = (autoFertByCrop[''] ?? 0) > 0;
    final hasSharedManual = (manualByCrop[''] ?? const []).isNotEmpty;
    if (hasSharedAuto || hasSharedManual) {
      shared = buildBreakdown(cropId: null, cropName: 'Tarla geneli');
    }

    final grandTotal = cropReports.fold<double>(0, (s, c) => s + c.total) +
        (shared?.total ?? 0);

    return FieldCostReport(
      crops: cropReports,
      shared: shared,
      grandTotal: grandTotal,
      byCategory: byCategory,
    );
  }

  static String _fmt(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1);
}
