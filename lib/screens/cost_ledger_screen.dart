import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:drift/drift.dart' show OrderingTerm;

import '../data/app_database.dart';
import '../services/app_providers.dart';
import '../services/cost_service.dart';
import '../services/price_book.dart';
import '../services/pdf_export_service.dart';
import '../theme/app_theme.dart';
import '../widgets/floating_toast.dart';
import '../widgets/help_panel.dart';
import '../widgets/shimmer_loader.dart';

/// Ürün bazlı maliyet defteri.
///
/// • Her ürünün gideri ayrı kartta listelenir.
/// • Gübre gideri loglanan aktivitelerden (veritabanı) otomatik türetilir;
///   mazot/tohum/işçilik/ilaç manuel girilir.
/// • Birim fiyatlar: akaryakıt EPDK'dan canlı; gübre/tohum/satış fiyatı
///   düzenlenebilir (tarihli). Hesaplama [CostService] + [PriceBook] ile.
class CostLedgerScreen extends ConsumerStatefulWidget {
  final String? fieldId;
  final String? fieldName;
  final double? areaDekar;

  const CostLedgerScreen({
    super.key,
    this.fieldId,
    this.fieldName,
    this.areaDekar,
  });

  @override
  ConsumerState<CostLedgerScreen> createState() => _CostLedgerScreenState();
}

class _CostLedgerScreenState extends ConsumerState<CostLedgerScreen> {
  final _fmt =
      NumberFormat.currency(locale: 'tr_TR', symbol: '₺', decimalDigits: 0);

  @override
  Widget build(BuildContext context) {
    final fieldId = widget.fieldId;
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text(widget.fieldName != null
            ? '${widget.fieldName} · Masraflar'
            : 'Masraf Defteri'),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download_rounded),
            tooltip: 'Sezon Raporu (PDF)',
            onPressed: _generateSeasonReport,
          ),
          IconButton(
            icon: const Icon(Icons.help_outline_rounded),
            tooltip: 'Yardım',
            onPressed: () => HelpPanel.show(context, HelpContent.costLedger),
          ),
        ],
      ),
      body: fieldId == null
          ? _buildNoField()
          : ref.watch(fieldCostReportProvider(fieldId)).when(
                loading: () => _buildLoading(),
                error: (e, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text('Masraflar yüklenemedi: $e',
                        textAlign: TextAlign.center),
                  ),
                ),
                data: (report) => _buildBody(report, fieldId),
              ),
      floatingActionButton: fieldId == null
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _openAddDialog(fieldId, null),
              backgroundColor: AppColors.emerald,
              icon: const Icon(Icons.add, color: Colors.white),
              label: Text('Masraf Ekle',
                  style: AppText.bodyMd(context).copyWith(color: Colors.white)),
            ),
    );
  }

  Widget _buildBody(FieldCostReport report, String fieldId) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
      children: [
        _buildSummaryCard(report),
        const SizedBox(height: 12),
        _buildLivePricesCard(),
        const SizedBox(height: 12),
        if (report.crops.isEmpty && report.shared == null)
          _buildEmpty()
        else ...[
          if (report.crops.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8, left: 4),
              child: Text('Ürün Bazlı Giderler',
                  style: AppText.bodyMd(context)
                      .copyWith(fontWeight: FontWeight.w700)),
            ),
          ...report.crops.map((c) => _buildCropCard(c, fieldId)),
          if (report.shared != null) ...[
            const SizedBox(height: 4),
            _buildCropCard(report.shared!, fieldId),
          ],
        ],
      ],
    );
  }

  // ── Özet ────────────────────────────────────────────────────────────────

  Widget _buildSummaryCard(FieldCostReport report) {
    double? totalProfit;
    for (final c in report.crops) {
      if (c.estimatedProfit != null) {
        totalProfit = (totalProfit ?? 0) + c.estimatedProfit!;
      }
    }
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppGradients.emeraldCard,
        borderRadius: AppRadius.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.account_balance_wallet_rounded,
                  color: Colors.white, size: 34),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Toplam Masraf', style: AppText.bodyDark(context)),
                    const SizedBox(height: 2),
                    Text(_fmt.format(report.grandTotal),
                        style: AppText.h1Dark(context)),
                  ],
                ),
              ),
            ],
          ),
          if (totalProfit != null) ...[
            const SizedBox(height: 10),
            Container(height: 1, color: Colors.white.withValues(alpha: 0.25)),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Tahmini Net Kâr',
                    style: AppText.bodyDark(context).copyWith(fontSize: 13)),
                Text(_fmt.format(totalProfit),
                    style: AppText.h3Dark(context).copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: totalProfit >= 0
                            ? Colors.white
                            : const Color(0xFFFFCDD2))),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ── Canlı / güncel fiyatlar ───────────────────────────────────────────────

  Widget _buildLivePricesCard() {
    return ref.watch(priceBookProvider).when(
          loading: () => _priceShimmerCard(),
          error: (_, __) => const SizedBox.shrink(),
          data: (pb) {
            final dateStr =
                DateFormat('dd.MM.yyyy', 'tr_TR').format(pb.updatedAt);
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: AppRadius.lg,
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.trending_up_rounded,
                          color: AppColors.emerald, size: 20),
                      const SizedBox(width: 8),
                      Text('Birim Fiyatlar',
                          style: AppText.bodyMd(context)
                              .copyWith(fontWeight: FontWeight.w700)),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: () => _openPriceEdit(pb),
                        icon: const Icon(Icons.edit_rounded, size: 16),
                        label: const Text('Güncelle'),
                        style: TextButton.styleFrom(
                            visualDensity: VisualDensity.compact),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  _priceRow(
                    icon: Icons.local_gas_station_rounded,
                    label: 'Mazot (Motorin)',
                    value: '${pb.dieselPerL.toStringAsFixed(2)} ₺/L',
                    sub: pb.fuelFromLive ? 'EPDK · canlı' : 'EPDK · önbellek',
                    color: AppColors.emeraldDark,
                  ),
                  _priceRow(
                    icon: Icons.local_gas_station_outlined,
                    label: 'Benzin',
                    value: '${pb.gasolinePerL.toStringAsFixed(2)} ₺/L',
                    sub: pb.fuelFromLive ? 'EPDK · canlı' : 'EPDK · önbellek',
                    color: AppColors.emeraldDark,
                  ),
                  const Divider(height: 18),
                  _priceRow(
                    icon: Icons.science_outlined,
                    label: 'Gübre — DAP',
                    value:
                        '${(pb.fertilizerPerKg['dap'] ?? 0).toStringAsFixed(0)} ₺/kg',
                    sub: 'Düzenlenebilir · $dateStr',
                    color: Colors.teal.shade700,
                  ),
                  _priceRow(
                    icon: Icons.science_outlined,
                    label: 'Gübre — Üre',
                    value:
                        '${(pb.fertilizerPerKg['ure'] ?? 0).toStringAsFixed(0)} ₺/kg',
                    sub: 'Düzenlenebilir · $dateStr',
                    color: Colors.teal.shade700,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Akaryakıt EPDK\'dan canlı; gübre/tohum/satış fiyatları '
                    'çiftçi tarafından güncellenir.',
                    style: AppText.xs(context)
                        .copyWith(fontSize: 10, color: AppColors.textTertiary),
                  ),
                ],
              ),
            );
          },
        );
  }

  Widget _priceRow({
    required IconData icon,
    required String label,
    required String value,
    required String sub,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: AppRadius.sm),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: AppText.sm(context).copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary)),
                Text(sub, style: AppText.xs(context).copyWith(fontSize: 10)),
              ],
            ),
          ),
          Text(value,
              style: AppText.bodyMd(context)
                  .copyWith(fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }

  Widget _priceShimmerCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.lg,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: List.generate(
          3,
          (_) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                ShimmerBox(width: 28, height: 28, borderRadius: 6),
                const SizedBox(width: 10),
                Expanded(child: ShimmerBox(width: 120, height: 12)),
                ShimmerBox(width: 60, height: 14, borderRadius: 4),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Ürün kartı (katlanabilir) ─────────────────────────────────────────────

  Widget _buildCropCard(CropCostBreakdown b, String fieldId) {
    final isShared = b.cropId == null;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.md,
        border: Border.all(color: AppColors.border),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: false,
          tilePadding: const EdgeInsets.symmetric(horizontal: 14),
          childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
          leading: Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: isShared ? AppColors.mint : AppColors.successBg,
              borderRadius: AppRadius.sm,
            ),
            child: Icon(isShared ? Icons.public_rounded : Icons.eco_rounded,
                color: AppColors.emeraldDark, size: 20),
          ),
          title: Text(b.cropName,
              style: AppText.bodyMd(context)
                  .copyWith(fontWeight: FontWeight.w700)),
          subtitle: Text(
            b.estimatedProfit != null
                ? 'Tahmini kâr: ${_fmt.format(b.estimatedProfit)}'
                : '${b.items.length} kalem',
            style: AppText.xs(context).copyWith(
              color: b.estimatedProfit != null && b.estimatedProfit! < 0
                  ? AppColors.error
                  : AppColors.textSecondary,
            ),
          ),
          trailing: Text(_fmt.format(b.total),
              style: AppText.h3(context).copyWith(
                  color: AppColors.emeraldDark, fontWeight: FontWeight.w800)),
          children: [
            if (b.items.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child:
                    Text('Bu ürün için gider yok.', style: AppText.sm(context)),
              )
            else
              ...b.items.map((it) => _buildLineItem(it)),
            if (b.estimatedProfit != null) _buildProfitBreakdown(b),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _openAddDialog(fieldId, b.cropId,
                    cropName: isShared ? null : b.cropName),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.emeraldDark,
                  side: const BorderSide(color: AppColors.emeraldLight),
                  minimumSize: const Size.fromHeight(44),
                ),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: Text(isShared
                    ? 'Tarla geneli masraf ekle'
                    : '${b.cropName} için masraf ekle'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLineItem(CostLineItem it) {
    final isAuto = it.source == CostSource.auto;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Icon(_iconForKind(it.kind), size: 18, color: AppColors.textSecondary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(it.label,
                          style: AppText.sm(context)
                              .copyWith(fontWeight: FontWeight.w600)),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: isAuto ? AppColors.infoBg : AppColors.surfaceAlt,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(isAuto ? 'oto · DB' : 'manuel',
                          style: AppText.xs(context).copyWith(
                              fontSize: 9,
                              color: isAuto
                                  ? AppColors.info
                                  : AppColors.textSecondary)),
                    ),
                  ],
                ),
                if (it.detail != null)
                  Text(it.detail!,
                      style: AppText.xs(context).copyWith(fontSize: 10),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(_fmt.format(it.amountTry),
              style: AppText.sm(context).copyWith(fontWeight: FontWeight.w700)),
          // Sadece manuel kalem silinebilir (otomatik gider aktiviteden gelir).
          if (!isAuto)
            IconButton(
              tooltip: 'Sil',
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.close_rounded,
                  size: 18, color: AppColors.textTertiary),
              onPressed: () => _deleteEntry(it.id),
            )
          else
            const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildProfitBreakdown(CropCostBreakdown b) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: AppRadius.sm,
      ),
      child: Column(
        children: [
          _profitRow('Tahmini rekolte',
              '${b.estimatedYieldKg!.toStringAsFixed(0)} kg'),
          _profitRow('Tahmini gelir', _fmt.format(b.estimatedRevenue)),
          _profitRow('Toplam gider', '− ${_fmt.format(b.total)}'),
          const Divider(height: 12),
          _profitRow(
            'Net kâr',
            _fmt.format(b.estimatedProfit),
            bold: true,
            color: b.estimatedProfit! >= 0
                ? AppColors.emeraldDark
                : AppColors.error,
          ),
        ],
      ),
    );
  }

  Widget _profitRow(String label, String value,
      {bool bold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: AppText.xs(context).copyWith(
                  fontWeight: bold ? FontWeight.w700 : FontWeight.normal)),
          Text(value,
              style: AppText.sm(context).copyWith(
                  fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
                  color: color)),
        ],
      ),
    );
  }

  IconData _iconForKind(String kind) {
    switch (kind) {
      case CostKinds.fertilizer:
        return Icons.science_outlined;
      case CostKinds.fuel:
        return Icons.local_gas_station_outlined;
      case CostKinds.pesticide:
        return Icons.medication_liquid_outlined;
      case CostKinds.seed:
        return Icons.eco_outlined;
      case CostKinds.labor:
        return Icons.engineering_outlined;
      case CostKinds.irrigation:
        return Icons.water_drop_outlined;
      default:
        return Icons.receipt_long_outlined;
    }
  }

  // ── Boş / yükleniyor / tarla yok ──────────────────────────────────────────

  Widget _buildLoading() => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ShimmerBox(width: double.infinity, height: 110, borderRadius: 16),
          const SizedBox(height: 12),
          _priceShimmerCard(),
        ],
      );

  Widget _buildEmpty() {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        children: [
          Icon(Icons.receipt_long_rounded, size: 52, color: AppColors.sage),
          const SizedBox(height: 12),
          Text('Henüz gider yok', style: AppText.h3(context)),
          const SizedBox(height: 6),
          Text(
            'Tarlaya ürün ekleyin; gübreleme loglayınca gübre gideri otomatik '
            'gelir. Mazot/tohum/işçilik için alt sağdaki butonu kullanın.',
            textAlign: TextAlign.center,
            style: AppText.sm(context),
          ),
        ],
      ),
    );
  }

  Widget _buildNoField() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Text(
          'Masrafları görmek için bir tarla detayından açın.',
          textAlign: TextAlign.center,
          style: AppText.body(context),
        ),
      ),
    );
  }

  // ── Aksiyonlar ────────────────────────────────────────────────────────────

  Future<void> _deleteEntry(String id) async {
    await ref.read(localDataRepositoryProvider).deleteCostEntry(id);
    if (mounted) {
      AppToast.show(context,
          message: 'Gider silindi.', type: ToastType.success);
    }
  }

  Future<void> _openAddDialog(String fieldId, String? cropId,
      {String? cropName}) async {
    final report = ref.read(fieldCostReportProvider(fieldId)).valueOrNull;
    final pb = ref.read(priceBookProvider).valueOrNull;
    final crops = report?.crops ?? const <CropCostBreakdown>[];
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.bg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _AddCostSheet(
        fieldId: fieldId,
        crops: crops,
        initialCropId: cropId,
        dieselPerL: pb?.dieselPerL ?? 0,
      ),
    );
  }

  Future<void> _openPriceEdit(PriceBook pb) async {
    final fieldId = widget.fieldId;
    final cropNames = fieldId == null
        ? <String>[]
        : (ref.read(fieldCostReportProvider(fieldId)).valueOrNull?.crops ??
                const <CropCostBreakdown>[])
            .map((c) => c.cropName)
            .toList();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.bg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _PriceEditSheet(priceBook: pb, cropNames: cropNames),
    );
    // Fiyat değişmiş olabilir → defteri ve raporu yenile.
    ref.invalidate(priceBookProvider);
  }

  Future<void> _generateSeasonReport() async {
    final fieldId = widget.fieldId;
    if (fieldId == null) {
      AppToast.show(context,
          message: 'Tarla seçilmediği için rapor oluşturulamaz.',
          type: ToastType.warning);
      return;
    }

    final firebaseUser = FirebaseAuth.instance.currentUser;
    final farmerName = firebaseUser?.displayName?.isNotEmpty == true
        ? firebaseUser!.displayName!
        : (firebaseUser?.email ?? 'Bilinmeyen Çiftçi');
    final farmerEmail = firebaseUser?.email;

    final db = ref.read(appDatabaseProvider);
    Field? field;
    try {
      field = await (db.select(db.fields)..where((f) => f.id.equals(fieldId)))
          .getSingleOrNull();
    } catch (_) {
      field = null;
    }

    FieldCrop? firstCrop;
    try {
      firstCrop = await (db.select(db.fieldCrops)
            ..where((c) => c.fieldId.equals(fieldId))
            ..orderBy([(c) => OrderingTerm.asc(c.createdAt)])
            ..limit(1))
          .getSingleOrNull();
    } catch (_) {
      firstCrop = null;
    }

    final report = await ref.read(fieldCostReportProvider(fieldId).future);
    final totalCost = report.grandTotal;

    // Gider listesi — ürün bazlı kalemlerden düz liste (PDF için).
    final expenses = <Map<String, dynamic>>[];
    void addItems(CropCostBreakdown b) {
      for (final it in b.items) {
        expenses.add({
          'kind': '${b.cropName} · ${it.label}',
          'total_try': it.amountTry,
          'note': it.detail ?? '',
          'date': DateTime.now().toIso8601String(),
        });
      }
    }

    for (final c in report.crops) {
      addItems(c);
    }
    if (report.shared != null) addItems(report.shared!);

    final dekar = field?.areaDekar ?? widget.areaDekar ?? 0.0;
    final cropName = field?.crop ?? firstCrop?.name ?? 'Belirtilmemiş';
    final lat = field?.latitude ?? 0.0;
    final lng = field?.longitude ?? 0.0;

    DateTime plantingDate;
    if (firstCrop?.plantedDate != null) {
      plantingDate = DateTime.tryParse(firstCrop!.plantedDate!) ??
          (field?.createdAt ?? DateTime.now());
    } else {
      plantingDate = field?.createdAt ?? DateTime.now();
    }

    final city = _cityFromCoords(lat, lng);

    final activities = <Map<String, dynamic>>[];
    try {
      final events = await (db.select(db.calendarEvents)
            ..where((e) => e.fieldId.equals(fieldId))
            ..orderBy([(e) => OrderingTerm.asc(e.eventDate)]))
          .get();
      for (final ev in events) {
        activities.add({
          'date': ev.eventDate.toIso8601String(),
          'activity_type': ev.eventType,
          'notes': ev.title,
        });
      }
    } catch (_) {}

    // Tahmini gelir/kâr — rapordaki ürün kârlarının toplamı (varsa).
    double estimatedYieldKg = 0;
    double estimatedProfitTl = -totalCost;
    bool anyProfit = false;
    for (final c in report.crops) {
      if (c.estimatedYieldKg != null) estimatedYieldKg += c.estimatedYieldKg!;
      if (c.estimatedProfit != null) {
        if (!anyProfit) {
          estimatedProfitTl = 0;
          anyProfit = true;
        }
        estimatedProfitTl += c.estimatedProfit!;
      }
    }

    final reportData = SeasonReportData(
      fieldName: widget.fieldName ?? field?.name ?? 'Bilinmeyen Tarla',
      dekar: dekar,
      cropName: cropName,
      city: city,
      latitude: lat,
      longitude: lng,
      plantingDate: plantingDate,
      harvestDate: null,
      activities: activities,
      expenses: expenses,
      estimatedYieldKg: estimatedYieldKg,
      estimatedProfitTl: estimatedProfitTl,
      totalCostTl: totalCost,
      farmerName: farmerName,
      farmerPhone: null,
      farmerEmail: farmerEmail,
    );

    final filePath = await PdfExportService.exportSeasonReport(reportData);
    if (filePath != null && mounted) {
      AppToast.show(context,
          message: 'PDF rapor oluşturuldu ve açıldı!', type: ToastType.success);
    } else if (mounted) {
      AppToast.show(context,
          message: 'PDF oluşturulurken hata oluştu.', type: ToastType.error);
    }
  }

  String _cityFromCoords(double lat, double lng) {
    if (lat == 0 && lng == 0) return 'Bilinmiyor';
    if (lat >= 40.8 && lat <= 41.2 && lng >= 28.5 && lng <= 29.5) {
      return 'İstanbul';
    }
    if (lat >= 39.7 && lat <= 40.2 && lng >= 32.5 && lng <= 33.2) {
      return 'Ankara';
    }
    if (lat >= 38.2 && lat <= 38.6 && lng >= 27.0 && lng <= 27.6) {
      return 'İzmir';
    }
    if (lat >= 36.8 && lat <= 37.2 && lng >= 35.0 && lng <= 36.0) {
      return 'Adana';
    }
    if (lat >= 37.7 && lat <= 38.2 && lng >= 32.4 && lng <= 33.0) {
      return 'Konya';
    }
    return 'Türkiye';
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// MASRAF EKLE
// ═══════════════════════════════════════════════════════════════════════════

class _AddCostSheet extends ConsumerStatefulWidget {
  final String fieldId;
  final List<CropCostBreakdown> crops;
  final String? initialCropId;
  final double dieselPerL;

  const _AddCostSheet({
    required this.fieldId,
    required this.crops,
    required this.dieselPerL,
    this.initialCropId,
  });

  @override
  ConsumerState<_AddCostSheet> createState() => _AddCostSheetState();
}

class _AddCostSheetState extends ConsumerState<_AddCostSheet> {
  final _amountCtrl = TextEditingController();
  final _litersCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  String _kind = CostKinds.fuel;
  String? _cropId; // null = tarla geneli

  @override
  void initState() {
    super.initState();
    _cropId = widget.initialCropId;
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _litersCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  double _computedAmount() {
    if (_kind == CostKinds.fuel && widget.dieselPerL > 0) {
      final liters = double.tryParse(_litersCtrl.text.replaceAll(',', '.'));
      if (liters != null && liters > 0) return liters * widget.dieselPerL;
    }
    return double.tryParse(_amountCtrl.text.replaceAll(',', '.')) ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.of(context).viewInsets.bottom;
    // Mazot için canlı fiyatla otomatik hesap alanı göster.
    final showLiters = _kind == CostKinds.fuel && widget.dieselPerL > 0;
    return Padding(
      padding: EdgeInsets.only(bottom: viewInsets),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                  color: AppColors.border, borderRadius: AppRadius.full),
            ),
            Text('Masraf Ekle', style: AppText.h2(context)),
            const SizedBox(height: 12),

            // Tür seçimi
            Text('Tür', style: AppText.sm(context)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: CostKinds.all
                  .where((k) => k != CostKinds.fertilizer || true)
                  .map((k) {
                final selected = _kind == k;
                return ChoiceChip(
                  label: Text(CostKinds.label(k)),
                  selected: selected,
                  onSelected: (_) => setState(() => _kind = k),
                  selectedColor: AppColors.emerald,
                  labelStyle: TextStyle(
                    color: selected ? Colors.white : AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Ürün seçimi
            Text('Hangi ürün?', style: AppText.sm(context)),
            const SizedBox(height: 6),
            DropdownButtonFormField<String?>(
              initialValue: _cropId,
              decoration: const InputDecoration(
                isDense: true,
                prefixIcon: Icon(Icons.eco_outlined),
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem<String?>(
                    value: null, child: Text('Tarla geneli (paylaşılan)')),
                ...widget.crops
                    .where((c) => c.cropId != null)
                    .map((c) => DropdownMenuItem<String?>(
                          value: c.cropId,
                          child: Text(c.cropName),
                        )),
              ],
              onChanged: (v) => setState(() => _cropId = v),
            ),
            const SizedBox(height: 16),

            if (showLiters) ...[
              TextField(
                controller: _litersCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                ],
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  labelText: 'Mazot (litre)',
                  helperText:
                      'Canlı fiyat: ${widget.dieselPerL.toStringAsFixed(2)} ₺/L',
                  prefixIcon: const Icon(Icons.local_gas_station_outlined),
                ),
              ),
              const SizedBox(height: 12),
            ],

            TextField(
              controller: _amountCtrl,
              enabled: !(showLiters && _litersCtrl.text.trim().isNotEmpty),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
              ],
              decoration: InputDecoration(
                labelText: showLiters ? 'veya toplam tutar (₺)' : 'Tutar (₺)',
                prefixIcon: const Icon(Icons.attach_money_rounded),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _noteCtrl,
              textCapitalization: TextCapitalization.sentences,
              autocorrect: false,
              enableSuggestions: false,
              decoration: const InputDecoration(
                labelText: 'Not (opsiyonel)',
                prefixIcon: Icon(Icons.edit_note_rounded),
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.emerald,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(50),
              ),
              onPressed: _save,
              icon: const Icon(Icons.save_rounded),
              label: Text(
                _computedAmount() > 0
                    ? 'Kaydet — ${_computedAmount().toStringAsFixed(0)} ₺'
                    : 'Kaydet',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    final amount = _computedAmount();
    if (amount <= 0) {
      AppToast.show(context,
          message: 'Geçerli bir tutar girin.', type: ToastType.warning);
      return;
    }
    final liters = double.tryParse(_litersCtrl.text.replaceAll(',', '.'));
    await ref.read(localDataRepositoryProvider).saveCostEntry(
          fieldId: widget.fieldId,
          cropId: _cropId,
          kind: _kind,
          amountTry: amount,
          quantity: _kind == CostKinds.fuel ? liters : null,
          unit: _kind == CostKinds.fuel && liters != null ? 'L' : null,
          unitPriceTry: _kind == CostKinds.fuel && liters != null
              ? widget.dieselPerL
              : null,
          note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
        );
    if (mounted) {
      Navigator.pop(context);
      AppToast.show(context,
          message: 'Masraf eklendi.', type: ToastType.success);
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// FİYAT GÜNCELLE
// ═══════════════════════════════════════════════════════════════════════════

class _PriceEditSheet extends ConsumerStatefulWidget {
  final PriceBook priceBook;
  final List<String> cropNames;

  const _PriceEditSheet({required this.priceBook, required this.cropNames});

  @override
  ConsumerState<_PriceEditSheet> createState() => _PriceEditSheetState();
}

class _PriceEditSheetState extends ConsumerState<_PriceEditSheet> {
  late final Map<String, TextEditingController> _fertCtrls;
  late final TextEditingController _seedCtrl;
  late final TextEditingController _laborCtrl;
  late final Map<String, TextEditingController> _saleCtrls;

  static const _fertOrder = ['dap', 'ure', 'npk', 'amonyum', 'can'];
  static const _fertLabel = {
    'dap': 'DAP',
    'ure': 'Üre',
    'npk': 'NPK / Kompoze',
    'amonyum': 'Amonyum Sülfat',
    'can': 'CAN',
  };

  @override
  void initState() {
    super.initState();
    final pb = widget.priceBook;
    _fertCtrls = {
      for (final k in _fertOrder)
        k: TextEditingController(
            text: (pb.fertilizerPerKg[k] ?? 0).toStringAsFixed(0)),
    };
    _seedCtrl = TextEditingController(text: pb.seedPerKg.toStringAsFixed(0));
    _laborCtrl = TextEditingController(text: pb.laborPerDay.toStringAsFixed(0));
    // Tarladaki ürünler için satış fiyatı alanları.
    _saleCtrls = {};
    for (final name in widget.cropNames) {
      final key = normalizeTr(name);
      if (_saleCtrls.containsKey(key)) continue;
      _saleCtrls[key] =
          TextEditingController(text: pb.saleForCrop(name).toStringAsFixed(0));
    }
  }

  @override
  void dispose() {
    for (final c in _fertCtrls.values) {
      c.dispose();
    }
    for (final c in _saleCtrls.values) {
      c.dispose();
    }
    _seedCtrl.dispose();
    _laborCtrl.dispose();
    super.dispose();
  }

  double _num(TextEditingController c, double fallback) =>
      double.tryParse(c.text.replaceAll(',', '.')) ?? fallback;

  Future<void> _save() async {
    final pb = widget.priceBook;
    final fert = <String, double>{...pb.fertilizerPerKg};
    for (final k in _fertOrder) {
      fert[k] = _num(_fertCtrls[k]!, fert[k] ?? 0);
    }
    final sale = <String, double>{...pb.cropSalePerKg};
    _saleCtrls.forEach((key, c) {
      final v = _num(c, 0);
      if (v > 0) sale[key] = v;
    });
    final updated = pb.copyWith(
      fertilizerPerKg: fert,
      seedPerKg: _num(_seedCtrl, pb.seedPerKg),
      laborPerDay: _num(_laborCtrl, pb.laborPerDay),
      cropSalePerKg: sale,
      updatedAt: DateTime.now(),
    );
    await PriceBookService.save(updated);
    if (mounted) {
      Navigator.pop(context);
      AppToast.show(context,
          message: 'Fiyatlar güncellendi.', type: ToastType.success);
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: viewInsets),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                  color: AppColors.border, borderRadius: AppRadius.full),
            ),
            Text('Güncel Fiyatlar', style: AppText.h2(context)),
            const SizedBox(height: 4),
            Text(
              'Akaryakıt EPDK\'dan canlı gelir; buradaki gübre/tohum/işçilik ve '
              'ürün satış fiyatlarını güncel bayi değerlerinizle düzeltin.',
              style: AppText.sm(context),
            ),
            const SizedBox(height: 16),
            Text('Gübre (₺/kg)',
                style: AppText.bodyMd(context)
                    .copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            ..._fertOrder
                .map((k) => _priceField(_fertLabel[k]!, _fertCtrls[k]!)),
            const SizedBox(height: 8),
            _priceField('Tohum (₺/kg)', _seedCtrl),
            _priceField('İşçilik (₺/gün)', _laborCtrl),
            if (_saleCtrls.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text('Ürün satış fiyatı (₺/kg)',
                  style: AppText.bodyMd(context)
                      .copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              ...widget.cropNames.toSet().map((name) {
                final key = normalizeTr(name);
                final ctrl = _saleCtrls[key];
                if (ctrl == null) return const SizedBox.shrink();
                return _priceField(name, ctrl);
              }),
            ],
            const SizedBox(height: 20),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.emerald,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(50),
              ),
              onPressed: _save,
              icon: const Icon(Icons.save_rounded),
              label: const Text('Fiyatları Kaydet'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _priceField(String label, TextEditingController ctrl) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: ctrl,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
        ],
        decoration: InputDecoration(
          labelText: label,
          isDense: true,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }
}
