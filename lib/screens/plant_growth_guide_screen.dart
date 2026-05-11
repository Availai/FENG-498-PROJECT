/// Bitki Gelişim Rehberi — TAGEM/BATEM/ÇAYKUR gibi resmi Türk kaynaklarına
/// dayanan çevrimdışı yetiştirme rehberlerinin listelendiği hub ekran.
///
/// Bir bitki seçildiğinde [TurkiyeCropGuideScreen] açılır ve o bitki için
/// ekim, sulama, gübreleme, zararlı/hastalık izleme ve hasat yönergeleri
/// kaynak referansı ile gösterilir.
library;

import 'package:flutter/material.dart';

import '../data/turkiye_crop_guides.dart';
import '../theme/app_theme.dart';
import 'turkiye_crop_guide_screen.dart';

class PlantGrowthGuideScreen extends StatelessWidget {
  const PlantGrowthGuideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final guides = TurkiyeCropGuides.guides;
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Bitki Gelişim Rehberi'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          _IntroCard(count: guides.length),
          const SizedBox(height: 12),
          for (final guide in guides) ...[
            _GuideCard(guide: guide),
            const SizedBox(height: 10),
          ],
          const SizedBox(height: 8),
          _SafetyNote(),
        ],
      ),
    );
  }
}

class _IntroCard extends StatelessWidget {
  const _IntroCard({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: AppGradients.forestHero,
        borderRadius: AppRadius.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.eco_rounded, color: AppColors.textOnDark),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Resmi kaynaklı yetiştirme rehberi',
                  style: AppText.h3Dark(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Bir bitki ekleyince ya da bir ürünü merak ettiğinde, '
            'TAGEM, BATEM ve ÇAYKUR gibi Tarım ve Orman Bakanlığı '
            'kuruluşlarının resmi teknik talimatlarına dayalı '
            'ekim, sulama, gübreleme, zararlı/hastalık izleme ve hasat '
            'yönergeleri bu ekrandan açılır.',
            style: AppText.bodyDark(context),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: AppRadius.full,
            ),
            child: Text(
              '$count ürün rehberi · çevrimdışı',
              style: AppText.xs(context).copyWith(color: AppColors.textOnDark),
            ),
          ),
        ],
      ),
    );
  }
}

class _GuideCard extends StatelessWidget {
  const _GuideCard({required this.guide});
  final TurkiyeCropGuide guide;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: AppRadius.md,
      child: InkWell(
        borderRadius: AppRadius.md,
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => TurkiyeCropGuideScreen(guide: guide),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: AppRadius.md,
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.mint,
                  borderRadius: AppRadius.sm,
                ),
                child: Text(
                  _emoji(guide.id),
                  style: const TextStyle(fontSize: 24),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(guide.cropName, style: AppText.h3(context)),
                    const SizedBox(height: 2),
                    Text(
                      guide.scientificName,
                      style: AppText.xs(context)
                          .copyWith(fontStyle: FontStyle.italic),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _MiniChip(
                          icon: Icons.calendar_today_rounded,
                          label: 'Ekim: ${guide.sowingWindow}',
                        ),
                        _MiniChip(
                          icon: Icons.agriculture_rounded,
                          label: 'Hasat: ${guide.harvestWindow}',
                        ),
                        _MiniChip(
                          icon: Icons.thermostat_rounded,
                          label:
                              '${guide.idealTempMin.toStringAsFixed(0)}-${guide.idealTempMax.toStringAsFixed(0)} °C',
                        ),
                        _MiniChip(
                          icon: Icons.water_drop_rounded,
                          label:
                              '${guide.seasonalWaterMm.toStringAsFixed(0)} mm/sezon',
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.menu_book_rounded,
                            size: 14, color: AppColors.emeraldDark),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            '${guide.sourceRefs.length} kaynak referansı',
                            style: AppText.xs(context).copyWith(
                              color: AppColors.emeraldDark,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded,
                  color: AppColors.textTertiary),
            ],
          ),
        ),
      ),
    );
  }

  String _emoji(String id) {
    switch (id) {
      case 'aycicegi':
        return '🌻';
      case 'domates':
        return '🍅';
      case 'misir':
        return '🌽';
      case 'portakal':
        return '🍊';
      case 'cay':
        return '🍵';
      default:
        return '🌱';
    }
  }
}

class _MiniChip extends StatelessWidget {
  const _MiniChip({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: AppRadius.full,
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.textSecondary),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppText.xs(context).copyWith(fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _SafetyNote extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.warningBg,
        borderRadius: AppRadius.sm,
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.shield_outlined, color: AppColors.warning, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Bu rehberler genel bilgi içindir. Kimyasal mücadele kararları '
              'Tarım ve Orman Bakanlığı BKÜ veri tabanı ve il/ilçe müdürlüğü '
              'teknik önerisi ile doğrulanmadan uygulanmamalıdır.',
              style: AppText.xs(context)
                  .copyWith(color: AppColors.textPrimary, height: 1.45),
            ),
          ),
        ],
      ),
    );
  }
}
