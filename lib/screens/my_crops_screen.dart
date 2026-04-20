import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/app_providers.dart';
import '../utils/location_utils.dart';
import '../widgets/animated_route.dart';
import '../widgets/floating_toast.dart';
import '../widgets/shimmer_loader.dart';
import '../widgets/tap_scale.dart';
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
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'calcBtn',
        onPressed: () async {
          try {
            final pos = await getCurrentPosition();
            if (context.mounted) {
              Navigator.of(context).push(AnimatedRoute.slideUp(
                Field3DPlannerScreen(
                  initialLat: pos.latitude,
                  initialLng: pos.longitude,
                ),
              ));
            }
          } catch (e) {
            if (context.mounted) {
              AppToast.show(
                context,
                message: 'Sinyal hatası: $e',
                type: ToastType.error,
              );
            }
          }
        },
        backgroundColor: AppColors.emerald,
        icon: const Icon(Icons.satellite_alt, color: Colors.white),
        label: Text('YENİ ALAN ÇİZ',
            style: AppText.label(context).copyWith(color: Colors.white)),
      ),
      body: fieldsAsync.when(
        loading: () => ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          itemCount: 5,
          itemBuilder: (_, __) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: ShimmerBox(
              width: double.infinity,
              height: 96,
              borderRadius: 16,
            ),
          ),
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
                child: TapScale(
                  scale: 0.97,
                  onTap: hasLocation
                      ? () {
                          Navigator.of(context).push(
                            AnimatedRoute.scaleFade(
                              FieldDetailScreen(fieldData: item),
                            ),
                          );
                        }
                      : null,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: AppRadius.md,
                      boxShadow: AppShadows.sm,
                      border: Border.all(color: AppColors.border),
                    ),
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
                              await ref.read(fieldRepositoryProvider).deleteField(id);
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
}
