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
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/turkiye_crop_guides.dart';
import '../services/app_providers.dart';
import '../services/crop_recommendations.dart';
import '../services/crop_scoring_service.dart';
import '../services/weather_soil_service.dart';
import '../theme/app_theme.dart';
import '../utils/location_utils.dart';
import '../widgets/fade_slide_in.dart';
import '../widgets/help_panel.dart';
import '../widgets/random_effect_wrapper.dart';
import 'turkiye_crop_guide_screen.dart';

class TavsiyelerScreen extends ConsumerStatefulWidget {
  const TavsiyelerScreen({super.key, this.initialCropId});

  /// Açılışta belirli bir ürünün filtresini seçili getirir (ör. 'domates').
  /// null ise "Tüm Ürünler" varsayılan seçilidir.
  final String? initialCropId;

  @override
  ConsumerState<TavsiyelerScreen> createState() => _TavsiyelerScreenState();
}

class _TavsiyelerScreenState extends ConsumerState<TavsiyelerScreen> {
  String? _selectedCropId;

  /// Konuma göre kolay yetişen bitkiler. null = henüz yüklenmedi.
  List<ScoredCrop>? _easyCrops;
  bool _easyLoading = true;
  String? _easyError;

  // Skorlama için kullanılan çevre değerleri (kullanıcıya gösterilir).
  double? _envTemp;
  double? _envPh;

  @override
  void initState() {
    super.initState();
    _selectedCropId = widget.initialCropId;
    _loadEasyCrops();
  }

  /// Mevcut konumdan çevre koşullarını alıp en kolay yetişen ~15 bitkiyi
  /// skorlar. Konum/internet yoksa Türkiye ortalama koşullarına düşer
  /// (offline-first — sonsuz loading yasak).
  Future<void> _loadEasyCrops() async {
    // Varsayılan: Türkiye geneli makul ortalama (konum alınamazsa).
    double temp = 20.0;
    double ph = 6.8;
    double weeklyRain = 12.0;
    try {
      await ensureLocationPermission();
      final pos = await getCurrentPosition();
      final cond = await const WeatherSoilService().fetchDashboardConditions(
        latitude: pos.latitude,
        longitude: pos.longitude,
      );
      if (cond.temperatureC != null) temp = cond.temperatureC!;
      ph = cond.phH2O;
    } catch (_) {
      // Konum/hava alınamadı — varsayılan ortalama ile devam (sessiz fallback).
    }

    try {
      final ranked = await ref.read(cropScoringServiceProvider).rankForEnv(
            temperature: temp,
            soilPh: ph,
            weeklyRain: weeklyRain,
            month: DateTime.now().month,
            topN: 15,
          );
      if (!mounted) return;
      setState(() {
        _easyCrops = ranked;
        _envTemp = temp;
        _envPh = ph;
        _easyLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _easyError = 'Bitki veritabanı yüklenemedi.';
        _easyLoading = false;
      });
    }
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
          _EasyCropsSection(
            loading: _easyLoading,
            error: _easyError,
            crops: _easyCrops,
            envTemp: _envTemp,
            envPh: _envPh,
          ),
          const SizedBox(height: 18),
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
// Konuma göre "kolay yetişen" bitkiler bölümü
// ─────────────────────────────────────────────────────────────────────────────

class _EasyCropsSection extends StatelessWidget {
  const _EasyCropsSection({
    required this.loading,
    required this.error,
    required this.crops,
    required this.envTemp,
    required this.envPh,
  });

  final bool loading;
  final String? error;
  final List<ScoredCrop>? crops;
  final double? envTemp;
  final double? envPh;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Icon(Icons.place_rounded,
                color: AppColors.emeraldDark, size: 20),
            const SizedBox(width: 6),
            Expanded(
              child: Text('Konumunuza Göre Kolay Yetişenler',
                  style: AppText.h3(context)),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Bulunduğunuz yerin sıcaklık ve toprak koşullarına en uygun, '
          'yetiştirmesi kolay bitkiler. Skor yükseldikçe işiniz kolaylaşır.',
          style: AppText.sm(context),
        ),
        if (envTemp != null && envPh != null) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              AppTag('Sıcaklık ${envTemp!.toStringAsFixed(0)}°C',
                  color: AppColors.warning),
              AppTag('pH ${envPh!.toStringAsFixed(1)}', color: AppColors.info),
            ],
          ),
        ],
        const SizedBox(height: 12),
        if (loading)
          _EasyLoadingState()
        else if (error != null)
          _EasyMessage(text: error!)
        else if (crops == null || crops!.isEmpty)
          _EasyMessage(
              text: 'Şu an öneri üretilemedi. Konum ve internet bağlantınızı '
                  'kontrol edip tekrar deneyin.')
        else
          for (var i = 0; i < crops!.length; i++) ...[
            FadeSlideIn(
              index: i,
              child: _EasyCropCard(scored: crops![i], rank: i + 1),
            ),
            const SizedBox(height: 8),
          ],
      ],
    );
  }
}

class _EasyLoadingState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.md,
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text('Konumunuza uygun bitkiler hesaplanıyor…',
                style: AppText.sm(context)),
          ),
        ],
      ),
    );
  }
}

class _EasyMessage extends StatelessWidget {
  const _EasyMessage({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: AppRadius.md,
        border: Border.all(color: AppColors.border),
      ),
      child: Text(text, style: AppText.sm(context)),
    );
  }
}

class _EasyCropCard extends StatelessWidget {
  const _EasyCropCard({required this.scored, required this.rank});
  final ScoredCrop scored;
  final int rank;

  /// Skoru kullanıcı diline çevir: yüksek = kolay.
  ({String label, Color color, Color bg}) _ease(double score) {
    if (score >= 80) {
      return (
        label: 'Çok kolay',
        color: AppColors.success,
        bg: AppColors.successBg
      );
    }
    if (score >= 65) {
      return (label: 'Kolay', color: AppColors.emeraldDark, bg: AppColors.mint);
    }
    if (score >= 50) {
      return (label: 'Orta', color: AppColors.warning, bg: AppColors.warningBg);
    }
    return (label: 'Zorlu', color: AppColors.error, bg: AppColors.errorBg);
  }

  @override
  Widget build(BuildContext context) {
    final ease = _ease(scored.score);
    final crop = scored.crop;
    final reasons = scored.reasons.take(3).toList();

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
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.mint,
                  borderRadius: AppRadius.sm,
                ),
                child: Text('$rank',
                    style: AppText.bodyMd(context)
                        .copyWith(color: AppColors.emeraldDark)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(crop.nameTr, style: AppText.bodyMd(context)),
                    Text(crop.category, style: AppText.xs(context)),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: ease.bg,
                  borderRadius: AppRadius.full,
                ),
                child: Text(
                  '${ease.label} • ${scored.score.toStringAsFixed(0)}',
                  style: AppText.xs(context).copyWith(color: ease.color),
                ),
              ),
            ],
          ),
          if (reasons.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text('NEDEN', style: AppText.label(context)),
            const SizedBox(height: 4),
            for (final r in reasons)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text('• $r', style: AppText.xs(context)),
              ),
          ],
          if (scored.confidence != 'high') ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.info_outline_rounded,
                    size: 13, color: AppColors.textTertiary),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    scored.confidence == 'low'
                        ? 'Bazı çevre verileri eksik olduğundan bu öneri sınırlı güvenilirliktedir.'
                        : 'Çevre verisinin bir kısmı tahmini; öneri orta güvenilirliktedir.',
                    style: AppText.xs(context),
                  ),
                ),
              ],
            ),
          ],
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
                  'Tavsiyeler',
                  style: AppText.h3Dark(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Türkiye için öncelikli $count üründe ekim, sulama, besleme, '
            'koruma, hasat ve münavebe için kısa ve aksiyon odaklı '
            'tavsiyeler.',
            style: AppText.bodyDark(context),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: const [
              _HeroBadge(label: 'Çevrimdışı'),
              _HeroBadge(label: 'İlaç uyarılı'),
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
              'Bu tavsiyeler genel bilgi içindir. Kesin teşhis, doz ve '
              'uygulama kararları için yerel ziraat mühendisi veya il/ilçe '
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
