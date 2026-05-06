import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:maps_toolkit/maps_toolkit.dart' as toolkit;
import 'package:intl/intl.dart';
import '../services/app_providers.dart';
import '../theme/app_theme.dart';
import '../widgets/contextual_tip.dart';
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

  Widget _buildPlannerTip() {
    if (_points.isEmpty) {
      return const ActionTipCard(
        icon: Icons.touch_app_rounded,
        color: AppColors.emerald,
        title: 'Tarlanın köşelerine dokunun',
        message:
            'Dış sınırı dolaşıyormuş gibi köşeleri sırayla işaretleyin. Konum alınamazsa haritayı elinizle kaydırıp tarlanızı bulun.',
        dark: true,
        compact: true,
        dismissible: false,
      );
    }

    if (_points.length < 3) {
      return ActionTipCard(
        icon: Icons.polyline_rounded,
        color: AppColors.warning,
        title: '${_points.length} köşe seçildi',
        message:
            'Alanı kapatmak için en az ${3 - _points.length} köşe daha ekleyin. Yanlış nokta koyduysanız sağ üstteki geri al simgesini kullanın.',
        dark: true,
        compact: true,
        dismissible: false,
      );
    }

    final dekar = (_calculatedAreaSqm / 1000).toStringAsFixed(2);
    return ActionTipCard(
      icon: Icons.check_circle_outline_rounded,
      color: AppColors.emerald,
      title: '$dekar dekar alan hazır',
      message:
          'Kaydedince tarla "Tarlalarım" listesinde, takvimde ve harita merkezinde görünür. Ürün eklemeyi tarla detayındaki "Ekle" düğmesinden yapabilirsiniz.',
      actionLabel: 'Kaydet',
      onAction: _saveField,
      dark: true,
      compact: true,
      dismissible: false,
    );
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

          Positioned(
            left: 12,
            right: 72,
            top: MediaQuery.of(context).padding.top + 70,
            child: _buildPlannerTip(),
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
