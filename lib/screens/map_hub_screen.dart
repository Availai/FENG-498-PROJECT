library;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../services/app_providers.dart';
import '../widgets/help_panel.dart';

/// Aşama-1 / Flutter çekirdek modülü:
/// Harita odaklı tarla görünümü (offline-first veri kaynağı: local repository).
class MapHubScreen extends ConsumerWidget {
  const MapHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fieldsAsync = ref.watch(fieldMapsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Harita Merkezi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline_rounded),
            tooltip: 'Yardım',
            onPressed: () => HelpPanel.show(context, HelpContent.mapHub),
          ),
        ],
      ),
      body: fieldsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _ErrorView(error: e.toString()),
        data: (fields) {
          final polygonEntries = _buildPolygonEntries(fields);
          final center = _estimateCenter(polygonEntries);

          if (polygonEntries.isEmpty) {
            return const _EmptyMapHint();
          }

          return Column(
            children: [
              _MapStatsBar(
                totalFields: fields.length,
                mappedFields: polygonEntries.length,
              ),
              Expanded(
                child: FlutterMap(
                  options: MapOptions(
                    initialCenter: center,
                    initialZoom: 13,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.smartagri.app',
                    ),
                    PolygonLayer(
                      polygons: polygonEntries
                          .map((entry) => Polygon(
                                points: entry.points,
                                color: Colors.green.withValues(alpha: 0.25),
                                borderColor: Colors.green.shade700,
                                borderStrokeWidth: 2.2,
                              ))
                          .toList(),
                    ),
                    MarkerLayer(
                      markers: polygonEntries
                          .map((entry) => Marker(
                                point: entry.center,
                                width: 150,
                                height: 44,
                                child: _FieldMarkerChip(label: entry.name),
                              ))
                          .toList(),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _PolygonEntry {
  final String name;
  final List<LatLng> points;
  final LatLng center;

  const _PolygonEntry({
    required this.name,
    required this.points,
    required this.center,
  });
}

List<_PolygonEntry> _buildPolygonEntries(List<Map<String, dynamic>> fields) {
  final entries = <_PolygonEntry>[];
  for (final field in fields) {
    final points = _extractPolygon(field);
    if (points.length < 3) continue;
    entries.add(
      _PolygonEntry(
        name: (field['name']?.toString().trim().isNotEmpty ?? false)
            ? field['name'].toString()
            : 'Adsız Tarla',
        points: points,
        center: _centerOf(points),
      ),
    );
  }
  return entries;
}

List<LatLng> _extractPolygon(Map<String, dynamic> field) {
  final raw = field['polygon'];
  if (raw is! List) return const [];
  final points = <LatLng>[];
  for (final item in raw) {
    if (item is! Map) continue;
    final lat = (item['lat'] as num?)?.toDouble();
    final lng = (item['lng'] as num?)?.toDouble();
    if (lat == null || lng == null) continue;
    points.add(LatLng(lat, lng));
  }
  return points;
}

LatLng _estimateCenter(List<_PolygonEntry> entries) {
  if (entries.isEmpty) return const LatLng(39.0, 35.0);
  double lat = 0;
  double lng = 0;
  for (final entry in entries) {
    lat += entry.center.latitude;
    lng += entry.center.longitude;
  }
  return LatLng(lat / entries.length, lng / entries.length);
}

LatLng _centerOf(List<LatLng> points) {
  double lat = 0;
  double lng = 0;
  for (final p in points) {
    lat += p.latitude;
    lng += p.longitude;
  }
  return LatLng(lat / points.length, lng / points.length);
}

class _FieldMarkerChip extends StatelessWidget {
  final String label;

  const _FieldMarkerChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.72),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}

class _MapStatsBar extends StatelessWidget {
  final int totalFields;
  final int mappedFields;

  const _MapStatsBar({
    required this.totalFields,
    required this.mappedFields,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      color: Colors.green.shade50,
      child: Wrap(
        spacing: 16,
        runSpacing: 8,
        children: [
          _Badge(
            icon: Icons.map_outlined,
            label: 'Toplam Tarla',
            value: '$totalFields',
          ),
          _Badge(
            icon: Icons.polyline_rounded,
            label: 'Haritada Çizili',
            value: '$mappedFields',
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _Badge({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: Colors.white,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: Colors.green.shade700),
            const SizedBox(width: 6),
            Text(
              '$label: $value',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyMapHint extends StatelessWidget {
  const _EmptyMapHint();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.map_outlined, size: 56, color: Colors.grey),
            SizedBox(height: 12),
            Text(
              'Henüz haritada gösterilecek tarla yok.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 8),
            Text(
              'Önce Tarlalar ekranından bir tarla oluşturup köşeleri işaretleyin.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String error;

  const _ErrorView({required this.error});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          'Harita verisi yüklenemedi.\n$error',
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.redAccent),
        ),
      ),
    );
  }
}
