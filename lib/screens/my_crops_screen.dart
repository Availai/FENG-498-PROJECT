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
      floatingActionButton: Padding(
        // Ana nav bar (~96px float) üzerinden yukarıda kalması için offset
        padding: const EdgeInsets.only(bottom: 92),
        child: FloatingActionButton.extended(
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
                              final fieldName =
<<<<<<< HEAD
                                  (item['name']?.toString().trim().isNotEmpty ?? false)
                                      ? item['name'].toString()
                                      : 'Bu tarla';
                              final confirmed = await _confirmDeleteField(
                                context,
                                fieldName,
=======
                                  (item['name'] ?? 'İsimsiz Tarla').toString();
                              final confirmed = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  shape: RoundedRectangleBorder(
                                      borderRadius: AppRadius.md),
                                  title: Row(
                                    children: const [
                                      Icon(Icons.warning_amber_rounded,
                                          color: AppColors.error),
                                      SizedBox(width: 8),
                                      Expanded(child: Text('Silmek istediğinize emin misiniz?')),
                                    ],
                                  ),
                                  content: Text(
                                    '"$fieldName" tarlasını ve bu tarlaya ait '
                                    'tüm geçmiş kayıtları (takvim etkinlikleri, '
                                    'sulama planları, uygunluk raporları, '
                                    'büyüme durumu) kalıcı olarak silmek '
                                    'istediğinize emin misiniz?\n\n'
                                    'Bu işlem geri alınamaz.',
                                    style: AppText.body(ctx),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(ctx).pop(false),
                                      child: const Text('Vazgeç'),
                                    ),
                                    TextButton(
                                      style: TextButton.styleFrom(
                                          foregroundColor: AppColors.error),
                                      onPressed: () =>
                                          Navigator.of(ctx).pop(true),
                                      child: const Text('Sil'),
                                    ),
                                  ],
                                ),
>>>>>>> bfa38d7d23bc8c0bec06f2054cc027bacd3b42cd
                              );
                              if (confirmed != true) return;
                              await ref
                                  .read(fieldRepositoryProvider)
                                  .deleteField(id);
                              if (context.mounted) {
                                AppToast.show(
                                  context,
<<<<<<< HEAD
                                  message: '$fieldName ve tüm kayıtları silindi.',
=======
                                  message:
                                      '"$fieldName" ve tüm geçmişi silindi.',
>>>>>>> bfa38d7d23bc8c0bec06f2054cc027bacd3b42cd
                                  type: ToastType.success,
                                );
                              }
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

  Future<bool?> _confirmDeleteField(BuildContext context, String fieldName) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        icon: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.error.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.warning_amber_rounded,
              color: AppColors.error, size: 32),
        ),
        title: Text(
          'Tarlayı Silmek İstediğinize Emin misiniz?',
          style: AppText.h2(context),
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '"$fieldName" ve aşağıdaki tüm kayıtları kalıcı olarak silinecek:',
              style: AppText.body(context),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.errorBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: AppColors.error.withValues(alpha: 0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _bulletRow('Ekili bitkiler ve bölgeler'),
                  _bulletRow('Sulama planları'),
                  _bulletRow('Takvim olayları (sulama, gübreleme, hasat)'),
                  _bulletRow('Uygunluk raporları'),
                  _bulletRow('Maliyet defteri kayıtları'),
                  _bulletRow('Büyüme protokolü durumu'),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Bu işlem geri alınamaz.',
              style: AppText.sm(context).copyWith(
                color: AppColors.error,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(46),
                    foregroundColor: AppColors.textSecondary,
                    side: BorderSide(color: AppColors.border),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Vazgeç'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => Navigator.of(ctx).pop(true),
                  icon: const Icon(Icons.delete_forever_rounded, size: 18),
                  label: const Text('Sil'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(46),
                    backgroundColor: AppColors.error,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _bulletRow(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.close_rounded, size: 14, color: AppColors.error),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 12.5,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
