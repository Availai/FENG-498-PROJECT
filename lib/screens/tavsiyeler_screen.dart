/// Tavsiyeler Ekranı.
///
/// Türkiye'nin öncelikli 5 ürünü (Ayçiçeği, Domates, Mısır, Portakal, Çay)
/// için TAGEM / BATEM / ÇAYKUR / Tarım ve Orman Bakanlığı kaynaklarına
/// dayanan, kısa ve aksiyon odaklı tavsiyeleri çevrimdışı sunar.
///
/// Bu ekran kural motoru değildir; LLM tavsiyesi vermez. Sadece çevrimdışı
/// kaynak-kanıtlı tavsiyeleri kullanıcı dostu kartlar halinde gösterir.
library;

import 'package:flutter/material.dart';

import '../data/turkiye_crop_guides.dart';
import '../services/crop_recommendations.dart';
import '../theme/app_theme.dart';
import '../widgets/fade_slide_in.dart';
import '../widgets/help_panel.dart';
import '../widgets/random_effect_wrapper.dart';
import 'turkiye_crop_guide_screen.dart';

class TavsiyelerScreen extends StatefulWidget {
  const TavsiyelerScreen({super.key, this.initialCropId});

  /// Açılışta belirli bir ürünün filtresini seçili getirir (ör. 'domates').
  /// null ise "Tüm Ürünler" varsayılan seçilidir.
  final String? initialCropId;

  @override
  State<TavsiyelerScreen> createState() => _TavsiyelerScreenState();
}

class _TavsiyelerScreenState extends State<TavsiyelerScreen> {
  String? _selectedCropId;

  @override
  void initState() {
    super.initState();
    _selectedCropId = widget.initialCropId;
  }

  @override
  Widget build(BuildContext context) {
    final guides = CropRecommendationsService.priorityGuides();
    final filtered = _selectedCropId == null
        ? guides
        : guides.where((g) => g.id == _selectedCropId).toList();

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Tavsiyeler'),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline_rounded),
            tooltip: 'Yardım',
            onPressed: () => HelpPanel.show(context, HelpContent.tavsiyeler),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          _IntroHero(count: guides.length),
          const SizedBox(height: 14),
          _CropFilterChips(
            guides: guides,
            selectedId: _selectedCropId,
            onChanged: (id) => setState(() => _selectedCropId = id),
          ),
          const SizedBox(height: 14),
          for (final g in filtered) ...[
            _CropTavsiyeSection(guide: g),
            const SizedBox(height: 18),
          ],
          _SafetyFooter(),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Intro hero
// ─────────────────────────────────────────────────────────────────────────────

class _IntroHero extends StatelessWidget {
  const _IntroHero({required this.count});
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
              const Icon(Icons.recommend_rounded, color: AppColors.textOnDark),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Resmi kaynaklı tavsiyeler',
                  style: AppText.h3Dark(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Türkiye için öncelikli $count üründe ekim, sulama, besleme, '
            'koruma, hasat, münavebe ve BKÜ güvenliği için kısa ve aksiyon '
            'odaklı tavsiyeler. Tüm içerikler TAGEM, BATEM, ÇAYKUR ve '
            'Tarım ve Orman Bakanlığı yayınlarına dayanır.',
            style: AppText.bodyDark(context),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: const [
              _HeroBadge(label: 'Çevrimdışı'),
              _HeroBadge(label: 'Kaynaklı'),
              _HeroBadge(label: 'BKÜ uyarılı'),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroBadge extends StatelessWidget {
  const _HeroBadge({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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

// ─────────────────────────────────────────────────────────────────────────────
// Ürün filtre chip'leri
// ─────────────────────────────────────────────────────────────────────────────

class _CropFilterChips extends StatelessWidget {
  const _CropFilterChips({
    required this.guides,
    required this.selectedId,
    required this.onChanged,
  });

  final List<TurkiyeCropGuide> guides;
  final String? selectedId;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _Chip(
            label: 'Tüm Ürünler',
            selected: selectedId == null,
            onTap: () => onChanged(null),
          ),
          for (final g in guides)
            _Chip(
              label: g.cropName,
              selected: selectedId == g.id,
              onTap: () => onChanged(g.id),
            ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: selected ? AppColors.emerald : AppColors.surface,
        borderRadius: AppRadius.full,
        child: InkWell(
          borderRadius: AppRadius.full,
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: AppRadius.full,
              border: Border.all(
                color: selected ? AppColors.emeraldDark : AppColors.border,
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              label,
              style: AppText.sm(context).copyWith(
                color: selected ? AppColors.textOnDark : AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Ürün bazlı tavsiye bölümü
// ─────────────────────────────────────────────────────────────────────────────

class _CropTavsiyeSection extends StatelessWidget {
  const _CropTavsiyeSection({required this.guide});
  final TurkiyeCropGuide guide;

  @override
  Widget build(BuildContext context) {
    final tavsiyeler = CropRecommendationsService.recommendationsFor(guide);
    // Mount edildiğinde her satır stagger ile beliriyor; filtre değişince
    // ValueKey ile yeniden mount edilip animasyon yeniden çalışıyor.
    return Column(
      key: ValueKey('tavsiye-${guide.id}'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FadeSlideIn(
          index: 0,
          child: _CropHeader(guide: guide),
        ),
        const SizedBox(height: 10),
        for (var i = 0; i < tavsiyeler.length; i++) ...[
          FadeSlideIn(
            index: i + 1,
            child: _TavsiyeCard(tavsiye: tavsiyeler[i], guide: guide),
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _CropHeader extends StatelessWidget {
  const _CropHeader({required this.guide});
  final TurkiyeCropGuide guide;

  @override
  Widget build(BuildContext context) {
    return RandomEffectWrapper(
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
          color: AppColors.surface,
          borderRadius: AppRadius.md,
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.mint,
                borderRadius: AppRadius.sm,
              ),
              child:
                  const Icon(Icons.eco_rounded, color: AppColors.emeraldDark),
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
                    style: AppText.xs(context).copyWith(
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Ekim: ${guide.sowingWindow}',
                    style: AppText.xs(context),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textTertiary),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tavsiye kartı
// ─────────────────────────────────────────────────────────────────────────────

class _TavsiyeCard extends StatelessWidget {
  const _TavsiyeCard({required this.tavsiye, required this.guide});
  final CropRecommendation tavsiye;
  final TurkiyeCropGuide guide;

  @override
  Widget build(BuildContext context) {
    final c = tavsiye.category;
    return RandomEffectWrapper(
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
          color: AppColors.surface,
          borderRadius: AppRadius.md,
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: c.background,
                    borderRadius: AppRadius.sm,
                  ),
                  child: Icon(c.icon, color: c.color, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: c.background,
                          borderRadius: AppRadius.full,
                        ),
                        child: Text(
                          c.label.toUpperCase(),
                          style:
                              AppText.label(context).copyWith(color: c.color),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(tavsiye.title, style: AppText.bodyMd(context)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text('NE YAPMALI', style: AppText.label(context)),
            const SizedBox(height: 4),
            Text(tavsiye.action, style: AppText.sm(context)),
            if (tavsiye.reason != null) ...[
              const SizedBox(height: 10),
              Text('NEDEN', style: AppText.label(context)),
              const SizedBox(height: 4),
              Text(tavsiye.reason!, style: AppText.sm(context)),
            ],
            if (tavsiye.requiresBkuCheck ||
                tavsiye.requiresExpertConfirmation) ...[
              const SizedBox(height: 10),
              _BkuChips(
                requiresBku: tavsiye.requiresBkuCheck,
                requiresExpert: tavsiye.requiresExpertConfirmation,
              ),
            ],
            const SizedBox(height: 10),
            _SourcesInline(sources: tavsiye.sources),
          ],
        ),
      ),
    );
  }
}

class _BkuChips extends StatelessWidget {
  const _BkuChips({required this.requiresBku, required this.requiresExpert});
  final bool requiresBku;
  final bool requiresExpert;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        if (requiresBku)
          _WarnChip(
            icon: Icons.science_rounded,
            label: 'BKÜ kontrolü gerekir',
            color: AppColors.error,
            background: AppColors.errorBg,
          ),
        if (requiresExpert)
          _WarnChip(
            icon: Icons.support_agent_rounded,
            label: 'Uzman onayı önerilir',
            color: AppColors.warning,
            background: AppColors.warningBg,
          ),
      ],
    );
  }
}

class _WarnChip extends StatelessWidget {
  const _WarnChip({
    required this.icon,
    required this.label,
    required this.color,
    required this.background,
  });
  final IconData icon;
  final String label;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: AppRadius.full,
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppText.xs(context).copyWith(color: color),
          ),
        ],
      ),
    );
  }
}

class _SourcesInline extends StatelessWidget {
  const _SourcesInline({required this.sources});
  final List<String> sources;

  @override
  Widget build(BuildContext context) {
    if (sources.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: AppRadius.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.menu_book_rounded,
                  size: 14, color: AppColors.emeraldDark),
              const SizedBox(width: 6),
              Text('KAYNAKLAR', style: AppText.label(context)),
            ],
          ),
          const SizedBox(height: 4),
          for (final s in sources)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text('• $s', style: AppText.xs(context)),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Safety footer — BKÜ uyarısı
// ─────────────────────────────────────────────────────────────────────────────

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
              'Bu tavsiyeler resmi kaynaklara dayanır ve genel bilgi içindir. '
              'Kesin teşhis, doz ve uygulama kararları için Tarım ve Orman '
              'Bakanlığı BKÜ veritabanı (bku.tarim.gov.tr) ve il/ilçe '
              'müdürlüğü teknik desteği esastır. Toprak analizi olmadan kesin '
              'gübre miktarı önerilmez; çocuk, hayvan ve su kaynaklarını '
              'koruyacak güvenlik önlemleri her zaman uygulanmalıdır.',
              style: AppText.xs(context)
                  .copyWith(color: AppColors.textPrimary, height: 1.45),
            ),
          ),
        ],
      ),
    );
  }
}
