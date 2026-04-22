import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import '../data/fertilizer_prices.dart';
import '../services/api/epdk_prices_api.dart';
import '../theme/app_theme.dart';
import '../widgets/floating_toast.dart';
import '../widgets/shimmer_loader.dart';

/// ÇKS (Çiftçi Kayıt Sistemi) uyumlu basit maliyet defteri.
///
/// Çiftçinin defter/ajanda alışkanlığına göre tasarlandı:
///  • Dönüm başına DAP, Üre, mazot ve "diğer" masraf girilebilir
///  • Her giriş tarla kimliği ile eşleştirilebilir
///  • Hive kutusu: 'cost_ledger'
class CostLedgerScreen extends StatefulWidget {
  final String? fieldId;
  final String? fieldName;

  const CostLedgerScreen({super.key, this.fieldId, this.fieldName});

  @override
  State<CostLedgerScreen> createState() => _CostLedgerScreenState();
}

class _CostLedgerScreenState extends State<CostLedgerScreen> {
  Box get _box => Hive.box('cost_ledger');

  late Future<FuelPrices?> _fuelFuture;

  @override
  void initState() {
    super.initState();
    _fuelFuture = EpdkPricesApi.fetchFuel();
  }

  Future<void> _refreshFuel() async {
    setState(() => _fuelFuture = EpdkPricesApi.fetchFuel());
    await _fuelFuture;
  }

  List<Map<String, dynamic>> _fieldEntries() {
    final all = <Map<String, dynamic>>[];
    for (int i = 0; i < _box.length; i++) {
      final raw = _box.getAt(i);
      if (raw is Map) {
        final e = Map<String, dynamic>.from(raw);
        if (widget.fieldId == null || e['field_id'] == widget.fieldId) {
          e['__index'] = i;
          all.add(e);
        }
      }
    }
    all.sort((a, b) {
      final da = DateTime.tryParse(a['date']?.toString() ?? '') ?? DateTime(1970);
      final db = DateTime.tryParse(b['date']?.toString() ?? '') ?? DateTime(1970);
      return db.compareTo(da);
    });
    return all;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text(widget.fieldName != null
            ? '${widget.fieldName} · Cüzdan'
            : 'ÇKS Cüzdan — Maliyet Defteri'),
      ),
      body: ValueListenableBuilder<Box>(
        valueListenable: _box.listenable(),
        builder: (_, __, ___) {
          final list = _fieldEntries();
          final total = list.fold<double>(
              0, (s, e) => s + ((e['total_try'] as num?)?.toDouble() ?? 0));
          return Column(
            children: [
              _buildSummaryCard(total, list.length),
              _buildLivePricesCard(),
              Expanded(
                child: list.isEmpty
                    ? _buildEmpty()
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: list.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (_, i) => _buildEntryTile(list[i]),
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddDialog,
        backgroundColor: AppColors.emerald,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text('Masraf Ekle',
            style: AppText.bodyMd(context).copyWith(color: Colors.white)),
      ),
    );
  }

  Widget _buildSummaryCard(double total, int count) {
    final fmt = NumberFormat.currency(locale: 'tr_TR', symbol: '₺', decimalDigits: 0);
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppGradients.emeraldCard,
        borderRadius: AppRadius.lg,
      ),
      child: Row(
        children: [
          const Icon(Icons.account_balance_wallet_rounded,
              color: Colors.white, size: 36),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Toplam Masraf',
                    style: AppText.bodyDark(context)),
                const SizedBox(height: 4),
                Text(fmt.format(total), style: AppText.h1Dark(context)),
                const SizedBox(height: 2),
                Text('$count kayıt',
                    style: AppText.bodyDark(context).copyWith(fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Canlı piyasa fiyatları — EPDK mazot + TZOB gübre.
  /// Hive cache fallback ile çevrimdışı çalışır.
  Widget _buildLivePricesCard() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.lg,
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.trending_up_rounded, color: AppColors.emerald, size: 20),
              const SizedBox(width: 8),
              Text('Canlı Piyasa Fiyatları',
                  style: AppText.bodyMd(context).copyWith(fontWeight: FontWeight.w700)),
              const Spacer(),
              GestureDetector(
                onTap: _refreshFuel,
                child: Icon(Icons.refresh_rounded,
                    color: AppColors.textSecondary, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ── Akaryakıt — EPDK Canlı Veri ──
          FutureBuilder<FuelPrices?>(
            future: _fuelFuture,
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return _priceShimmerRow();
              }
              // Fallback: null ise varsayılan makul değerleri kullan
              final fp = snap.data ?? EpdkPricesApi.fallbackPrices();
              final dieselStr = fp.dieselTry > 0
                  ? '${fp.dieselTry.toStringAsFixed(2)} ₺/lt'
                  : '--';
              final gasolineStr = fp.gasolineTry > 0
                  ? '${fp.gasolineTry.toStringAsFixed(2)} ₺/lt'
                  : '--';
              final dateStr = DateFormat('dd.MM.yyyy HH:mm').format(fp.fetchedAt);
              final srcLabel = fp.fromCache ? 'Önbellek' : 'EPDK ${fp.city}';
              return Column(
                children: [
                  _priceRow(
                    icon: Icons.local_gas_station_rounded,
                    label: 'Mazot (Motorin)',
                    value: dieselStr,
                    sub: '$srcLabel · $dateStr',
                    color: AppColors.emeraldDark,
                  ),
                  const SizedBox(height: 8),
                  _priceRow(
                    icon: Icons.local_gas_station_outlined,
                    label: 'Benzin (95 Oktan)',
                    value: gasolineStr,
                    sub: '$srcLabel · $dateStr',
                    color: AppColors.emeraldDark,
                  ),
                ],
              );
            },
          ),

          const Divider(height: 20),

          // ── Gübre Fiyatları — TZOB / Tarım Bakanlığı ──
          Text('Gübre Fiyatları (TZOB)',
              style: AppText.xs(context).copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary)),
          const SizedBox(height: 6),
          ...fertilizerPrices.map((fp) => _priceRow(
                icon: Icons.science_outlined,
                label: fp.name,
                value: '${fp.tryPrice.toStringAsFixed(0)} ₺ / ${fp.unit}',
                sub: 'Güncelleme: $fertilizerPricesUpdatedAt',
                color: Colors.teal.shade700,
              )),
          const SizedBox(height: 6),
          Text(
            'Kaynak: EPDK Haftalık Bülten · TZOB Gübre Bülteni',
            style: AppText.xs(context).copyWith(
                fontSize: 10, color: AppColors.textTertiary),
          ),
        ],
      ),
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
              borderRadius: AppRadius.sm,
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppText.sm(context).copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary)),
                Text(sub, style: AppText.xs(context).copyWith(fontSize: 10)),
              ],
            ),
          ),
          Text(value,
              style: AppText.bodyMd(context).copyWith(
                  fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }

  Widget _priceShimmerRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          ShimmerBox(width: 28, height: 28, borderRadius: 6),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShimmerBox(width: 140, height: 12, borderRadius: 4),
                const SizedBox(height: 4),
                ShimmerBox(width: 100, height: 10, borderRadius: 4),
              ],
            ),
          ),
          ShimmerBox(width: 70, height: 16, borderRadius: 4),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.receipt_long_rounded,
                size: 56, color: AppColors.sage),
            const SizedBox(height: 12),
            Text('Henüz masraf girişi yok',
                style: AppText.h3(context)),
            const SizedBox(height: 6),
            Text(
              'DAP, Üre, mazot gibi masraflarınızı alt sağdaki butondan ekleyin.',
              textAlign: TextAlign.center,
              style: AppText.sm(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEntryTile(Map<String, dynamic> e) {
    final date = DateTime.tryParse(e['date']?.toString() ?? '');
    final dateStr = date != null
        ? DateFormat('dd.MM.yyyy', 'tr_TR').format(date)
        : '—';
    final kind = e['kind']?.toString() ?? 'Diğer';
    final perDekar = (e['per_dekar_try'] as num?)?.toDouble() ?? 0;
    final dekar = (e['dekar'] as num?)?.toDouble() ?? 0;
    final total = (e['total_try'] as num?)?.toDouble() ?? 0;
    final note = e['note']?.toString() ?? '';
    final index = e['__index'] as int;

    final icon = _iconForKind(kind);

    return Dismissible(
      key: ValueKey('cost_$index'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        decoration: BoxDecoration(
          color: AppColors.errorBg,
          borderRadius: AppRadius.md,
        ),
        child: Icon(Icons.delete_outline, color: AppColors.error),
      ),
      onDismissed: (_) => _box.deleteAt(index),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.md,
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.mint,
                borderRadius: AppRadius.sm,
              ),
              child: Icon(icon, color: AppColors.emeraldDark, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(kind, style: AppText.bodyMd(context)),
                  Text(
                    '$dateStr · ${dekar.toStringAsFixed(1)} dekar · ${perDekar.toStringAsFixed(0)} ₺/da',
                    style: AppText.sm(context),
                  ),
                  if (note.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(note,
                        style: AppText.xs(context),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                  ],
                ],
              ),
            ),
            Text('${total.toStringAsFixed(0)} ₺',
                style: AppText.h3(context).copyWith(color: AppColors.emeraldDark)),
          ],
        ),
      ),
    );
  }

  IconData _iconForKind(String kind) {
    switch (kind) {
      case 'DAP':
      case 'Üre':
      case 'Kompoze':
        return Icons.science_outlined;
      case 'Mazot':
        return Icons.local_gas_station_outlined;
      case 'İlaç':
        return Icons.medication_liquid_outlined;
      case 'Tohum':
        return Icons.eco_outlined;
      case 'İşçilik':
        return Icons.engineering_outlined;
      default:
        return Icons.receipt_long_outlined;
    }
  }

  Future<void> _openAddDialog() async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.bg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _AddCostSheet(defaultFieldId: widget.fieldId),
    );
    if (result != null) {
      await _box.add(result);
    }
  }
}

class _AddCostSheet extends StatefulWidget {
  final String? defaultFieldId;
  const _AddCostSheet({this.defaultFieldId});

  @override
  State<_AddCostSheet> createState() => _AddCostSheetState();
}

class _AddCostSheetState extends State<_AddCostSheet> {
  final _perDekarCtrl = TextEditingController();
  final _dekarCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  String _kind = 'DAP';

  static const _kinds = ['DAP', 'Üre', 'Kompoze', 'Mazot', 'İlaç', 'Tohum', 'İşçilik', 'Diğer'];

  @override
  void dispose() {
    _perDekarCtrl.dispose();
    _dekarCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
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
                color: AppColors.border,
                borderRadius: AppRadius.full,
              ),
            ),
            Text('Yeni Masraf Girişi', style: AppText.h2(context)),
            const SizedBox(height: 4),
            Text('Dönüm başı tutar girin; toplam otomatik hesaplanır.',
                style: AppText.sm(context)),
            const SizedBox(height: 20),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _kinds.map((k) {
                final selected = _kind == k;
                return ChoiceChip(
                  label: Text(k),
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
            TextField(
              controller: _perDekarCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Dönüm başı tutar (₺/da)',
                prefixIcon: Icon(Icons.attach_money_rounded),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _dekarCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Toplam dekar',
                prefixIcon: Icon(Icons.crop_square_rounded),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _noteCtrl,
              decoration: const InputDecoration(
                labelText: 'Not (opsiyonel)',
                prefixIcon: Icon(Icons.edit_note_rounded),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.save_rounded),
              label: const Text('Kaydet'),
            ),
          ],
        ),
      ),
    );
  }

  void _save() {
    final perDekar = double.tryParse(_perDekarCtrl.text.replaceAll(',', '.')) ?? 0;
    final dekar = double.tryParse(_dekarCtrl.text.replaceAll(',', '.')) ?? 0;
    if (perDekar <= 0 || dekar <= 0) {
      AppToast.show(
        context,
        message: 'Tutar ve dekar pozitif olmalı.',
        type: ToastType.warning,
      );
      return;
    }
    final entry = {
      'kind': _kind,
      'per_dekar_try': perDekar,
      'dekar': dekar,
      'total_try': perDekar * dekar,
      'note': _noteCtrl.text.trim(),
      'date': DateTime.now().toIso8601String(),
      'field_id': widget.defaultFieldId,
    };
    Navigator.pop(context, entry);
  }
}
