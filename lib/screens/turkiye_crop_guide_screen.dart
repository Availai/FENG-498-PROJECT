/// Türkiye Yetiştirme Rehberi detay ekranı.
///
/// [TurkiyeCropGuides] içindeki TAGEM/BATEM/ÇAYKUR kaynaklı bilgiyi tek bir
/// okunabilir akışta sunar. Veri çevrimdışı paketten gelir; ekran yalnız
/// görselleştirme yapar, kural/öneri üretmez. Tıbbi/zirai tavsiye dili
/// kullanılmaz: kimyasal mücadele kararları için BKÜ ve uzman kontrolü
/// uyarısı kalıcı olarak görünür.
library;

import 'package:flutter/material.dart';

import '../data/turkiye_crop_guides.dart';
import '../services/crop_recommendations.dart';
import '../theme/app_theme.dart';
import 'tavsiyeler_screen.dart';

class TurkiyeCropGuideScreen extends StatelessWidget {
  const TurkiyeCropGuideScreen({super.key, required this.guide});

  final TurkiyeCropGuide guide;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text(guide.cropName),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(20),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                guide.scientificName,
                style: AppText.xs(context)
                    .copyWith(fontStyle: FontStyle.italic),
              ),
            ),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          _HeroCard(guide: guide),
          const SizedBox(height: 14),
          _HighlightsCard(guide: guide),
          const SizedBox(height: 14),
          _TechnicalMetricsCard(guide: guide),
          const SizedBox(height: 14),
          _SectionTitle(label: 'YETİŞTİRME AŞAMALARI'),
          const SizedBox(height: 8),
          _StagesTimeline(stages: guide.stages),
          const SizedBox(height: 14),
          _SectionTitle(label: 'BÖLGESEL TAKVİM'),
          const SizedBox(height: 8),
          _RegionalCalendarList(regions: guide.regionalCalendar),
          const SizedBox(height: 14),
          _SectionTitle(label: 'BESLEME PLANI'),
          const SizedBox(height: 8),
          _NutritionPlanList(plan: guide.nutritionPlan),
          const SizedBox(height: 8),
          _NotePanel(
            icon: Icons.water_drop_rounded,
            title: 'Sulama özeti',
            text: guide.irrigationSummary,
            color: AppColors.frost,
            background: AppColors.frostBg,
          ),
          const SizedBox(height: 8),
          _NotePanel(
            icon: Icons.eco_rounded,
            title: 'Gübreleme özeti',
            text: guide.fertilizerSummary,
            color: AppColors.emeraldDark,
            background: AppColors.mint,
          ),
          const SizedBox(height: 14),
          _SectionTitle(label: 'ZARARLI VE HASTALIK İZLEMESİ'),
          const SizedBox(height: 8),
          for (final pest in guide.pests) ...[
            _PestCard(pest: pest),
            const SizedBox(height: 8),
          ],
          const SizedBox(height: 6),
          _NotePanel(
            icon: Icons.shield_rounded,
            title: 'Entegre mücadele yaklaşımı',
            text: guide.integratedPestManagementNote,
            color: AppColors.emeraldDark,
            background: AppColors.mint,
          ),
          const SizedBox(height: 8),
          _NotePanel(
            icon: Icons.history_rounded,
            title: 'Ekim nöbeti / bahçe yenileme',
            text: guide.rotationNotes,
            color: AppColors.soil,
            background: AppColors.surfaceAlt,
          ),
          const SizedBox(height: 8),
          _NotePanel(
            icon: Icons.agriculture_rounded,
            title: 'Hasat ve kalite',
            text: guide.harvestQualityNotes,
            color: AppColors.warning,
            background: AppColors.warningBg,
          ),
          const SizedBox(height: 8),
          _NotePanel(
            icon: Icons.place_rounded,
            title: 'Bölge notu',
            text: guide.regionNote,
            color: AppColors.info,
            background: AppColors.infoBg,
          ),
          const SizedBox(height: 14),
          _SectionTitle(label: 'KAYNAKLAR'),
          const SizedBox(height: 8),
          _SourcesPanel(sources: guide.sourceRefs),
          const SizedBox(height: 14),
          _SafetyFooter(),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Hero
// ─────────────────────────────────────────────────────────────────────────────

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.guide});
  final TurkiyeCropGuide guide;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppGradients.forestHero,
        borderRadius: AppRadius.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _HeroChip(label: guide.category),
              const SizedBox(width: 6),
              _HeroChip(label: guide.lifeCycle),
              const SizedBox(width: 6),
              _HeroChip(label: 'Bakım: ${guide.careLevel}'),
            ],
          ),
          const SizedBox(height: 12),
          Text(guide.summary, style: AppText.bodyDark(context)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _HeroFact(
                  label: 'Ekim',
                  value: guide.sowingWindow,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _HeroFact(
                  label: 'Hasat',
                  value: guide.harvestWindow,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroChip extends StatelessWidget {
  const _HeroChip({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: AppRadius.full,
      ),
      child: Text(
        label,
        style: AppText.xs(context).copyWith(color: AppColors.textOnDark),
      ),
    );
  }
}

class _HeroFact extends StatelessWidget {
  const _HeroFact({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: AppRadius.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: AppText.label(context)
                  .copyWith(color: AppColors.textOnDarkMuted)),
          const SizedBox(height: 4),
          Text(value, style: AppText.bodyDark(context)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Öne Çıkan Tavsiyeler — TAGEM/BATEM/ÇAYKUR kaynaklı 4 kritik aksiyon kartı
// ─────────────────────────────────────────────────────────────────────────────

class _HighlightsCard extends StatelessWidget {
  const _HighlightsCard({required this.guide});
  final TurkiyeCropGuide guide;

  @override
  Widget build(BuildContext context) {
    final tavsiyeler = CropRecommendationsService.highlightsFor(guide);
    if (tavsiyeler.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.md,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.recommend_rounded,
                  color: AppColors.emeraldDark, size: 18),
              const SizedBox(width: 6),
              Text('ÖNE ÇIKAN TAVSİYELER', style: AppText.label(context)),
              const Spacer(),
              TextButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          TavsiyelerScreen(initialCropId: guide.id),
                    ),
                  );
                },
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  minimumSize: const Size(0, 28),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'Tümü',
                  style: AppText.xs(context)
                      .copyWith(color: AppColors.emeraldDark),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          for (var i = 0; i < tavsiyeler.length; i++) ...[
            _HighlightRow(tavsiye: tavsiyeler[i]),
            if (i < tavsiyeler.length - 1)
              const Divider(height: 16, color: AppColors.divider),
          ],
        ],
      ),
    );
  }
}

class _HighlightRow extends StatelessWidget {
  const _HighlightRow({required this.tavsiye});
  final CropRecommendation tavsiye;

  @override
  Widget build(BuildContext context) {
    final c = tavsiye.category;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: c.background,
            borderRadius: AppRadius.sm,
          ),
          child: Icon(c.icon, size: 16, color: c.color),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    c.label.toUpperCase(),
                    style: AppText.label(context).copyWith(color: c.color),
                  ),
                  if (tavsiye.requiresBkuCheck) ...[
                    const SizedBox(width: 6),
                    const Icon(Icons.science_rounded,
                        size: 12, color: AppColors.error),
                  ],
                ],
              ),
              const SizedBox(height: 2),
              Text(tavsiye.title, style: AppText.bodyMd(context)),
              const SizedBox(height: 4),
              Text(
                tavsiye.action,
                style: AppText.sm(context),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Technical metrics
// ─────────────────────────────────────────────────────────────────────────────

class _TechnicalMetricsCard extends StatelessWidget {
  const _TechnicalMetricsCard({required this.guide});
  final TurkiyeCropGuide guide;

  @override
  Widget build(BuildContext context) {
    final metrics = guide.technicalMetrics.entries.toList();
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('TEKNİK ÖLÇÜLER', style: AppText.label(context)),
          const SizedBox(height: 10),
          for (var i = 0; i < metrics.length; i++) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 4,
                  child: Text(metrics[i].key, style: AppText.sm(context)),
                ),
                Expanded(
                  flex: 5,
                  child: Text(
                    metrics[i].value.toString(),
                    style: AppText.bodyMd(context).copyWith(fontSize: 14),
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
            if (i < metrics.length - 1)
              const Divider(height: 16, color: AppColors.divider),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Stages
// ─────────────────────────────────────────────────────────────────────────────

class _StagesTimeline extends StatelessWidget {
  const _StagesTimeline({required this.stages});
  final List<GuideStage> stages;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < stages.length; i++)
          _StageRow(
            index: i + 1,
            isLast: i == stages.length - 1,
            stage: stages[i],
          ),
      ],
    );
  }
}

class _StageRow extends StatelessWidget {
  const _StageRow({
    required this.index,
    required this.isLast,
    required this.stage,
  });

  final int index;
  final bool isLast;
  final GuideStage stage;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.emerald,
                  borderRadius: AppRadius.full,
                ),
                child: Text(
                  '$index',
                  style: AppText.xs(context)
                      .copyWith(color: AppColors.textOnDark, fontSize: 13),
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: AppColors.emeraldLight,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              margin: EdgeInsets.only(bottom: isLast ? 0 : 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: AppRadius.sm,
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(stage.title, style: AppText.bodyMd(context)),
                  const SizedBox(height: 2),
                  Text(stage.timing, style: AppText.xs(context)),
                  const SizedBox(height: 8),
                  Text(stage.action, style: AppText.sm(context)),
                  const SizedBox(height: 6),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.warning_amber_rounded,
                          size: 14, color: AppColors.warning),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          stage.risk,
                          style: AppText.xs(context)
                              .copyWith(color: AppColors.warning),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Regional calendar
// ─────────────────────────────────────────────────────────────────────────────

class _RegionalCalendarList extends StatelessWidget {
  const _RegionalCalendarList({required this.regions});
  final List<RegionalCropCalendar> regions;

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < regions.length; i++) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.place_outlined,
                    size: 18, color: AppColors.emeraldDark),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(regions[i].region, style: AppText.bodyMd(context)),
                      const SizedBox(height: 2),
                      Text(
                        'Ekim: ${regions[i].plantingWindow}',
                        style: AppText.xs(context),
                      ),
                      Text(
                        'Hasat: ${regions[i].harvestWindow}',
                        style: AppText.xs(context),
                      ),
                      const SizedBox(height: 4),
                      Text(regions[i].notes, style: AppText.sm(context)),
                    ],
                  ),
                ),
              ],
            ),
            if (i < regions.length - 1)
              const Divider(height: 18, color: AppColors.divider),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Nutrition
// ─────────────────────────────────────────────────────────────────────────────

class _NutritionPlanList extends StatelessWidget {
  const _NutritionPlanList({required this.plan});
  final List<NutritionGuide> plan;

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < plan.length; i++) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  margin: const EdgeInsets.only(top: 7),
                  decoration: const BoxDecoration(
                    color: AppColors.emerald,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${plan[i].phase} · ${plan[i].timing}',
                        style: AppText.bodyMd(context).copyWith(fontSize: 14),
                      ),
                      const SizedBox(height: 4),
                      Text(plan[i].recommendation, style: AppText.sm(context)),
                    ],
                  ),
                ),
              ],
            ),
            if (i < plan.length - 1)
              const Divider(height: 16, color: AppColors.divider),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Pest cards
// ─────────────────────────────────────────────────────────────────────────────

class _PestCard extends StatelessWidget {
  const _PestCard({required this.pest});
  final PestDiseaseGuide pest;

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        childrenPadding: const EdgeInsets.only(top: 4),
        shape: const Border(),
        collapsedShape: const Border(),
        title: Row(
          children: [
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.warningBg,
                borderRadius: AppRadius.full,
              ),
              child: Text(
                pest.type,
                style: AppText.xs(context).copyWith(color: AppColors.warning),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(pest.name, style: AppText.bodyMd(context)),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(
            pest.symptoms,
            style: AppText.sm(context),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        children: [
          _PestRow(label: 'Belirti', text: pest.symptoms),
          _PestRow(label: 'İzleme', text: pest.monitoring),
          if (pest.samplingMethod != null)
            _PestRow(label: 'Sayım yöntemi', text: pest.samplingMethod!),
          if (pest.economicThreshold != null)
            _PestRow(
              label: 'Ekonomik eşik',
              text: pest.economicThreshold!,
              highlight: true,
            ),
          _PestRow(label: 'Entegre mücadele', text: pest.integratedControl),
          if (pest.chemicalGate != null)
            _PestRow(
              label: 'Kimyasal kapısı',
              text: pest.chemicalGate!,
              highlight: true,
            ),
          _PestRow(label: 'Yükseltme', text: pest.escalation),
        ],
      ),
    );
  }
}

class _PestRow extends StatelessWidget {
  const _PestRow({
    required this.label,
    required this.text,
    this.highlight = false,
  });

  final String label;
  final String text;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(),
              style: AppText.label(context).copyWith(
                color: highlight ? AppColors.warning : AppColors.textSecondary,
              )),
          const SizedBox(height: 2),
          Text(text, style: AppText.sm(context)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sources & safety
// ─────────────────────────────────────────────────────────────────────────────

class _SourcesPanel extends StatelessWidget {
  const _SourcesPanel({required this.sources});
  final List<String> sources;

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < sources.length; i++) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.menu_book_rounded,
                    size: 16, color: AppColors.emeraldDark),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(sources[i], style: AppText.sm(context)),
                ),
              ],
            ),
            if (i < sources.length - 1)
              const Divider(height: 14, color: AppColors.divider),
          ],
        ],
      ),
    );
  }
}

class _SafetyFooter extends StatelessWidget {
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
          const Icon(Icons.report_gmailerrorred_rounded,
              color: AppColors.warning),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Bu rehber resmi kaynaklardan derlenmiştir ve genel bilgi içindir. '
              'Kimyasal mücadele kararları için Tarım ve Orman Bakanlığı BKÜ '
              'veri tabanı ve il/ilçe müdürlüğü teknik önerisi esastır. '
              'Doz, hasat aralığı ve etiket koşullarını her zaman güncel '
              'BKÜ kaydı üzerinden doğrulayın.',
              style: AppText.xs(context)
                  .copyWith(color: AppColors.textPrimary, height: 1.45),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(label, style: AppText.label(context)),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.md,
        border: Border.all(color: AppColors.border),
      ),
      child: child,
    );
  }
}

class _NotePanel extends StatelessWidget {
  const _NotePanel({
    required this.icon,
    required this.title,
    required this.text,
    required this.color,
    required this.background,
  });

  final IconData icon;
  final String title;
  final String text;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: background,
        borderRadius: AppRadius.sm,
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: AppText.label(context).copyWith(color: color)),
                const SizedBox(height: 4),
                Text(text, style: AppText.sm(context)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
