import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:latlong2/latlong.dart';
import 'package:maps_toolkit/maps_toolkit.dart' as toolkit;
import 'package:intl/intl.dart';
import '../services/app_providers.dart';
import '../services/yield_calculation_service.dart';
import '../theme/app_theme.dart';
import '../widgets/floating_toast.dart';
import '../widgets/glass_panel.dart';
import '../widgets/help_panel.dart';

class Field3DPlannerScreen extends ConsumerStatefulWidget {
  final double initialLat;
  final double initialLng;
  final Map<String, dynamic>? existingField; // If editing an existing field
  final int? fieldIndex;

  const Field3DPlannerScreen({
    super.key,
    required this.initialLat,
    required this.initialLng,
    this.existingField,
    this.fieldIndex,
  });

  @override
  ConsumerState<Field3DPlannerScreen> createState() =>
      _Field3DPlannerScreenState();
}

class _Field3DPlannerScreenState extends ConsumerState<Field3DPlannerScreen> {
  final MapController _mapController = MapController();
  List<LatLng> _points = [];
  double _calculatedAreaSqm = 0.0;

  // ── Sezon Sonu Kârı varsayılanları ──────────────────────────────────────
  // Tarla çizim ekranında henüz ürün seçimi yok; kartta gösterilen değerler
  // "ideal koşullarda" (su tam, sıcaklık normal, gübre verildi) hesaplanır.
  // Toplam masraf artık Hive 'cost_ledger' kutusundan canlı okunur.
  static const String _defaultCrop = 'ayçiçeği';       // 300 kg/dekar
  static const double _defaultPricePerKg = 25.0;       // ₺/kg

  final YieldCalculationService _yieldService = YieldCalculationService();

  /// Maliyet defterinden toplam masrafı hesaplar.
  /// Mevcut tarla düzenleniyorsa yalnızca o tarlanın kayıtları,
  /// aksi halde tüm kayıtlar toplanır.
  double _totalCostFromLedger() {
    if (!Hive.isBoxOpen('cost_ledger')) return 0;
    final box = Hive.box('cost_ledger');
    final targetFieldId = widget.existingField?['id']?.toString();
    double sum = 0;
    for (int i = 0; i < box.length; i++) {
      final raw = box.getAt(i);
      if (raw is! Map) continue;
      final e = Map<String, dynamic>.from(raw);
      if (targetFieldId != null && e['field_id']?.toString() != targetFieldId) {
        continue;
      }
      sum += (e['total_try'] as num?)?.toDouble() ?? 0;
    }
    return sum;
  }

  YieldResult _computeSeasonProfit(double dekar, double toplamMasraf) {
    return _yieldService.hesapla(
      bitkiTuru: _defaultCrop,
      dekar: dekar,
      // İdeal koşullar → tüm çarpanlar 1.0
      haftalikSuIhtiyaciMm: 40,
      haftalikVerilenSuMm: 40,
      maksSicaklikLimitC: 32,
      asilanGunSayisi: 0,
      gubreVerildiMi: true,
      satisFiyatiPerKg: _defaultPricePerKg,
      toplamMasrafTl: toplamMasraf,
    );
  }

  @override
  void initState() {
    super.initState();
    if (widget.existingField != null &&
        widget.existingField!['polygon'] != null) {
      _points = (widget.existingField!['polygon'] as List)
          .map((e) => LatLng(e['lat'], e['lng']))
          .toList();
      _calculateArea();
    }
  }

  void _onMapTap(TapPosition _, LatLng latlng) {
    setState(() {
      _points.add(latlng);
    });
    if (_points.length >= 3) _calculateArea();
  }

  void _calculateArea() {
    final toolkitPts =
        _points.map((p) => toolkit.LatLng(p.latitude, p.longitude)).toList();
    _calculatedAreaSqm =
        toolkit.SphericalUtil.computeArea(toolkitPts).toDouble();
    setState(() {});
  }

  void _undoLastPoint() {
    if (_points.isEmpty) return;
    setState(() {
      _points.removeLast();
      if (_points.length < 3) {
        _calculatedAreaSqm = 0;
      } else {
        _calculateArea();
      }
    });
  }

  void _clearMap() {
    setState(() {
      _points.clear();
      _calculatedAreaSqm = 0;
    });
  }

  // ── Harita yakınlaştırma kontrolleri ──────────────────────────────────
  static const double _minZoom = 14.0;
  static const double _maxZoom = 21.0;

  void _zoomIn() {
    final z = _mapController.camera.zoom;
    _mapController.move(
      _mapController.camera.center,
      (z + 1).clamp(_minZoom, _maxZoom),
    );
  }

  void _zoomOut() {
    final z = _mapController.camera.zoom;
    _mapController.move(
      _mapController.camera.center,
      (z - 1).clamp(_minZoom, _maxZoom),
    );
  }

  /// Çizilen poligonun tamamını ekrana sığdıracak şekilde kamerayı konumlar.
  void _fitToPoints() {
    if (_points.length < 2) {
      // Henüz yeterli nokta yok → başlangıç konumuna dön
      _mapController.move(
        LatLng(widget.initialLat, widget.initialLng),
        18.0,
      );
      return;
    }
    final bounds = LatLngBounds.fromPoints(_points);
    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: bounds,
        padding: const EdgeInsets.all(60),
      ),
    );
  }

  void _saveField() {
    if (_calculatedAreaSqm == 0.0 || _points.length < 3) {
      AppToast.show(
        context,
        message: 'En az 3 nokta işaretleyip alan oluşturun.',
        type: ToastType.warning,
      );
      return;
    }

    double centerLat = 0, centerLng = 0;
    for (final p in _points) {
      centerLat += p.latitude;
      centerLng += p.longitude;
    }
    centerLat /= _points.length;
    centerLng /= _points.length;
    final dekar = _calculatedAreaSqm / 1000;

    String name = widget.existingField?['name']?.split(' ').first ?? '';
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.bg,
            borderRadius: AppRadius.lg,
            boxShadow: AppShadows.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Yeşil başlık
              Container(
                padding: const EdgeInsets.all(18),
                decoration: const BoxDecoration(
                  gradient: AppGradients.forestHero,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
                ),
                child: Row(children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child:
                        const Icon(Icons.save_alt_rounded, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Ekim Alanını Kaydet',
                            style: AppText.h3Dark(context)),
                        Text(
                          '${dekar.toStringAsFixed(1)} dekarlık alan oluşturulacak',
                          style:
                              AppText.bodyDark(context).copyWith(fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ]),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Tarla Adı',
                        style: AppText.label(context)
                            .copyWith(color: AppColors.emeraldDark)),
                    const SizedBox(height: 8),
                    TextField(
                      onChanged: (v) => name = v,
                      autofocus: true,
                      style: AppText.body(context),
                      cursorColor: AppColors.emerald,
                      decoration: InputDecoration(
                        hintText: 'Örn: Kuzey Tarlası',
                        prefixIcon: const Icon(Icons.landscape_outlined,
                            color: AppColors.emeraldDark),
                        filled: true,
                        fillColor: AppColors.surface,
                        border: OutlineInputBorder(
                          borderRadius: AppRadius.sm,
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: AppRadius.sm,
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: AppRadius.sm,
                          borderSide: const BorderSide(
                              color: AppColors.emerald, width: 2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.mint,
                        borderRadius: AppRadius.sm,
                      ),
                      child: Row(children: [
                        const Icon(Icons.info_outline,
                            color: AppColors.emeraldDark, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Bu ad, tarla listesinde ve raporlarda görünecektir.',
                            style: AppText.xs(context)
                                .copyWith(color: AppColors.emeraldDark),
                          ),
                        ),
                      ]),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: const BorderSide(color: AppColors.border),
                          shape: const RoundedRectangleBorder(
                              borderRadius: AppRadius.sm),
                          foregroundColor: AppColors.textSecondary,
                        ),
                        child: Text('İptal',
                            style: AppText.bodyMd(context)
                                .copyWith(color: AppColors.textSecondary)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          if (name.trim().isEmpty) return;
                          final data = {
                            'id': widget.existingField?['id'],
                            'name':
                                '${name.trim()} (${dekar.toStringAsFixed(1)} da)',
                            'date':
                                DateFormat('dd.MM.yyyy').format(DateTime.now()),
                            'latitude': centerLat,
                            'longitude': centerLng,
                            'area_dekar': dekar,
                            'area_sqm': _calculatedAreaSqm,
                            'polygon': _points
                                .map((p) =>
                                    {'lat': p.latitude, 'lng': p.longitude})
                                .toList(),
                            'planted_crops':
                                widget.existingField?['planted_crops'] ??
                                    const [],
                          };

                          await ref
                              .read(localDataRepositoryProvider)
                              .upsertFieldFromLegacyMap(data);

                          if (!ctx.mounted) return;
                          Navigator.pop(ctx);
                          if (!mounted) return;
                          Navigator.pop(context);
                          if (!mounted) return;
                          AppToast.show(
                            context,
                            message: 'Ekim alanı başarıyla kaydedildi!',
                            type: ToastType.success,
                          );
                        },
                        icon: const Icon(Icons.check_rounded,
                            color: Colors.white),
                        label: Text('Kaydet',
                            style: AppText.bodyMd(context)
                                .copyWith(color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.emerald,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          elevation: 0,
                          shape: const RoundedRectangleBorder(
                              borderRadius: AppRadius.sm),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Tarla içi yerleşim paterni
  List<Polygon> _buildCropPattern() {
    if (_points.length < 3) return [];

    const cropColor = AppColors.emerald;

    return [
      Polygon(
        points: _points,
        color: Colors.black.withValues(alpha: 0.3),
        borderStrokeWidth: 0,
      ),
      Polygon(
        points: _points,
        color: cropColor.withValues(alpha: 0.6),
        borderColor: cropColor,
        borderStrokeWidth: 2.0,
      ),
      Polygon(
        points: _calculateInnerPolygon(),
        color: Colors.white.withValues(alpha: 0.1),
        borderColor: Colors.white.withValues(alpha: 0.3),
        borderStrokeWidth: 1.0,
      ),
    ];
  }

  // Shrinks polygon to create a pseudo 3d 'top' surface
  List<LatLng> _calculateInnerPolygon() {
    if (_points.length < 3) return [];
    // Calculate centroid
    double clat = 0, clng = 0;
    for (var p in _points) {
      clat += p.latitude;
      clng += p.longitude;
    }
    clat /= _points.length;
    clng /= _points.length;

    // Scale towards center by 5%
    return _points
        .map((p) => LatLng(
              p.latitude + (clat - p.latitude) * 0.05,
              p.longitude + (clng - p.longitude) * 0.05,
            ))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    double dekar = _calculatedAreaSqm / 1000;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text('3D Tarla Yerleşimi', style: AppText.h3Dark(context)),
        actions: [
          IconButton(icon: const Icon(Icons.undo), onPressed: _undoLastPoint),
          IconButton(
              icon: const Icon(Icons.cleaning_services), onPressed: _clearMap),
          IconButton(
            icon: const Icon(Icons.help_outline_rounded),
            tooltip: 'Yardım',
            onPressed: () => HelpPanel.show(context, HelpContent.fieldPlanner),
          ),
        ],
      ),
      body: Stack(
        children: [
          // MAP
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: LatLng(widget.initialLat, widget.initialLng),
              initialZoom: 18.0,
              onTap: _onMapTap,
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
                userAgentPackageName: 'com.example.feng_498',
                maxZoom: 21,
              ),
              if (_points.length >= 3)
                PolygonLayer(polygons: _buildCropPattern()),
              if (_points.isNotEmpty)
                PolylineLayer<Object>(polylines: [
                  Polyline(
                    points: _points.length >= 3
                        ? [..._points, _points.first]
                        : [..._points],
                    color: Colors.white,
                    strokeWidth: 2.0,
                  ),
                ]),
              MarkerLayer(
                  markers: _points
                      .map((p) => Marker(
                            point: p,
                            width: 12,
                            height: 12,
                            child: Container(
                                decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    boxShadow: AppShadows.md)),
                          ))
                      .toList()),
            ],
          ),

          // ── ZOOM KONTROLLERİ (sağ kenar) ──
          Positioned(
            right: 12,
            top: MediaQuery.of(context).padding.top + 72,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _zoomBtn(Icons.add, _zoomIn, tooltip: 'Yakınlaştır'),
                const SizedBox(height: 8),
                _zoomBtn(Icons.remove, _zoomOut, tooltip: 'Uzaklaştır'),
                const SizedBox(height: 8),
                _zoomBtn(
                  Icons.center_focus_strong,
                  _fitToPoints,
                  tooltip: 'Çizime Odaklan',
                ),
              ],
            ),
          ),

          // BOTTOM GLASS PANELS (Stats & Save)
          Positioned(
            bottom: 30,
            left: 16,
            right: 16,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_calculatedAreaSqm > 0)
                  GlassPanel(
                    borderRadius: 20,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatBox(
                            'Alan', dekar.toStringAsFixed(2), 'Dekar'),
                        Container(
                            width: 1, height: 40, color: AppColors.border),
                        _buildStatBox(
                            'Köşe', _points.length.toString(), 'Nokta'),
                      ],
                    ),
                  ),
                if (_calculatedAreaSqm > 0) const SizedBox(height: 12),
                if (_calculatedAreaSqm > 0) _buildProfitCard(dekar),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: _points.length >= 3 ? _saveField : null,
                    icon: const Icon(Icons.check_circle_outline),
                    label: Text(
                      _points.length >= 3
                          ? 'EKİM PLANINI KAYDET'
                          : 'KÖŞELERİ İŞARETLEYİN',
                      style: const TextStyle(letterSpacing: 1.2),
                    ),
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: AppRadius.lg),
                      backgroundColor: AppColors.emerald,
                      disabledBackgroundColor: AppColors.textTertiary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfitCard(double dekar) {
    // Hive 'cost_ledger' kutusunu dinle; masraf eklendiğinde kart kendini yeniler.
    return ValueListenableBuilder<Box>(
      valueListenable: Hive.box('cost_ledger').listenable(),
      builder: (context, _, __) {
        final toplamMasraf = _totalCostFromLedger();
        return _buildProfitCardInner(dekar, toplamMasraf);
      },
    );
  }

  Widget _buildProfitCardInner(double dekar, double toplamMasraf) {
    final sonuc = _computeSeasonProfit(dekar, toplamMasraf);
    final rekolte = sonuc.tahminiRekolte;
    final gelir = rekolte * _defaultPricePerKg;
    final netKar = sonuc.tahminiKar;
    final isProfitable = netKar >= 0;

    final moneyFmt = NumberFormat.currency(
      locale: 'tr_TR',
      symbol: '₺',
      decimalDigits: 0,
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isProfitable
              ? const [Color(0xFF2E7D32), Color(0xFF1B5E20)]
              : const [Color(0xFFD32F2F), Color(0xFFB71C1C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: (isProfitable
                    ? const Color(0xFF2E7D32)
                    : const Color(0xFFD32F2F))
                .withValues(alpha: 0.35),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Başlık satırı ────────────────────────────────────────────
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.savings_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tahmini Sezon Sonu Kârı',
                      style: AppText.h3Dark(context).copyWith(fontSize: 15),
                    ),
                    Text(
                      'Varsayılan ürün: Ayçiçeği · ideal koşullar',
                      style: AppText.bodyDark(context)
                          .copyWith(fontSize: 11, color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // ── Hesap kırılımı ───────────────────────────────────────────
          _profitRow(
            'Tahmini Rekolte',
            '${rekolte.toStringAsFixed(0)} kg',
            Icons.grass_rounded,
          ),
          const SizedBox(height: 6),
          _profitRow(
            'Gelir (${_defaultPricePerKg.toStringAsFixed(0)} ₺/kg)',
            moneyFmt.format(gelir),
            Icons.trending_up_rounded,
          ),
          const SizedBox(height: 6),
          _profitRow(
            toplamMasraf > 0
                ? 'Toplam Masraf (Cüzdan)'
                : 'Toplam Masraf',
            '− ${moneyFmt.format(toplamMasraf)}',
            Icons.receipt_long_rounded,
          ),

          // ── Ayraç ────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Container(
              height: 1,
              color: Colors.white.withValues(alpha: 0.25),
            ),
          ),

          // ── Net kâr ──────────────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Net Kâr',
                style: AppText.h3Dark(context).copyWith(fontSize: 14),
              ),
              Text(
                moneyFmt.format(netKar),
                style: AppText.h2(context).copyWith(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _profitRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.white70, size: 14),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: AppText.bodyDark(context)
                .copyWith(fontSize: 12, color: Colors.white70),
          ),
        ),
        Text(
          value,
          style: AppText.bodyMd(context).copyWith(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _zoomBtn(IconData icon, VoidCallback onTap, {String? tooltip}) {
    final btn = Material(
      color: Colors.white.withValues(alpha: 0.92),
      elevation: 3,
      shadowColor: Colors.black.withValues(alpha: 0.3),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.emerald.withValues(alpha: 0.35),
              width: 1,
            ),
          ),
          child: Icon(icon, color: AppColors.emeraldDark, size: 22),
        ),
      ),
    );
    return tooltip == null ? btn : Tooltip(message: tooltip, child: btn);
  }

  Widget _buildStatBox(String label, String value, String unit) {
    return Column(
      children: [
        Text(label,
            style:
                const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
        const SizedBox(height: 4),
        Text(value,
            style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.bold)),
        Text(unit,
            style: const TextStyle(
                color: AppColors.emerald,
                fontSize: 11,
                fontWeight: FontWeight.w600)),
      ],
    );
  }
}
