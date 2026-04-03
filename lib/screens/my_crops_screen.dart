import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/app_providers.dart';
import '../utils/location_utils.dart';
import 'field_3d_planner_screen.dart';
import 'field_detail_screen.dart';
import '../theme/app_theme.dart';

class MyCropsScreen extends ConsumerWidget {
  const MyCropsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fieldsAsync = ref.watch(fieldMapsProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text('Tarım Alanlarım', style: AppText.h2(context)),
        backgroundColor: AppColors.surface,
        elevation: 0,
        centerTitle: false,
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton.extended(
            heroTag: 'calcBtn',
            onPressed: () async {
              try {
                final pos = await getCurrentPosition();
                if (context.mounted) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => Field3DPlannerScreen(
                        initialLat: pos.latitude,
                        initialLng: pos.longitude,
                      ),
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Sinyal hatası: $e'),
                      backgroundColor: AppColors.error,
                    )
                  );
                }
              }
            },
            backgroundColor: AppColors.emerald,
            icon: const Icon(Icons.satellite_alt, color: Colors.white),
            label: Text('YENİ ALAN ÇİZ',
                style: AppText.label(context).copyWith(color: Colors.white)),
          ),
          const SizedBox(height: 12),
          FloatingActionButton(
            heroTag: 'addBtn',
            onPressed: () => _showAddDialog(context, ref),
            backgroundColor: AppColors.surface,
            child: const Icon(Icons.add_location_alt, color: AppColors.emerald),
          ),
        ],
      ),
      body: fieldsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.emerald),
        ),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Alanlar yüklenemedi: $error',
              style: AppText.body(context),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        data: (fields) {
          if (fields.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppColors.emerald.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.radar, size: 64, color: AppColors.emerald),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Kayıtlı Alan Bulunmuyor',
                      textAlign: TextAlign.center,
                      style: AppText.h2(context),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Uydudan gerçek arazinizi seçerek ekim alanlarınızı oluşturmaya başlayın.',
                      textAlign: TextAlign.center,
                      style: AppText.body(context),
                    ),
                  ],
                ),
              ),
            );
          }
          
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            itemCount: fields.length,
            itemBuilder: (context, i) {
              final item = fields[i];
              final hasLocation = item['latitude'] != null;
              final areaDekar = item['area_dekar'];
              final cropName = item['crop'] ?? 'Bilinmiyor';
              
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: AppRadius.md,
                    boxShadow: AppShadows.sm,
                    border: Border.all(color: AppColors.border),
                  ),
                  child: InkWell(
                    borderRadius: AppRadius.md,
                    onTap: hasLocation ? () {
                      Navigator.push(context, MaterialPageRoute(
                        builder: (_) => FieldDetailScreen(fieldData: item)
                      ));
                    } : null,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.emeraldLight.withValues(alpha: 0.2),
                              borderRadius: AppRadius.sm,
                            ),
                            child: const Icon(Icons.dashboard_customize, color: AppColors.emerald, size: 28),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  (item['name'] ?? 'İsimsiz Tarla').toString(),
                                  style: AppText.h3(context),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Icons.calendar_today, size: 12, color: AppColors.textSecondary),
                                    const SizedBox(width: 4),
                                    Text('${item['date']}', style: AppText.xs(context)),
                                    if (areaDekar != null) ...[
                                      const SizedBox(width: 12),
                                      const Icon(Icons.square_foot, size: 12, color: AppColors.textSecondary),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${(areaDekar as num).toStringAsFixed(1)} da',
                                        style: AppText.xs(context),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    AppTag(cropName),
                                    const Spacer(),
                                    if (hasLocation)
                                      Row(
                                        children: [
                                          Text('Bağlı', style: AppText.xs(context).copyWith(color: AppColors.emerald)),
                                          const SizedBox(width: 4),
                                          const Icon(Icons.link, size: 12, color: AppColors.emerald),
                                        ],
                                      )
                                    else 
                                      Row(
                                        children: [
                                          Text('Koordinat Yok', style: AppText.xs(context).copyWith(color: AppColors.error)),
                                          const SizedBox(width: 4),
                                          const Icon(Icons.location_off, size: 12, color: AppColors.error),
                                        ],
                                      )
                                  ],
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: AppColors.error),
                            onPressed: () async {
                              final id = item['id']?.toString();
                              if (id == null) return;
                              await ref.read(localDataRepositoryProvider).deleteField(id);
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showAddDialog(BuildContext context, WidgetRef ref) async {
    double? lat, lng;
    try {
      final pos = await getCurrentPosition();
      lat = pos.latitude;
      lng = pos.longitude;
    } catch (_) {}

    if (!context.mounted) return;

    String name = '';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('Manuel Konum Ekle', style: AppText.h2(context)),
        content: TextField(
          onChanged: (v) => name = v,
          style: AppText.body(context),
          decoration: const InputDecoration(
            hintText: 'Tanımlayıcı Giriniz',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('İptal', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (name.isNotEmpty) {
                await ref.read(localDataRepositoryProvider).createManualField(
                      name: name,
                      latitude: lat,
                      longitude: lng,
                    );
                if (context.mounted) {
                  Navigator.pop(ctx);
                }
              }
            },
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
  }
}
