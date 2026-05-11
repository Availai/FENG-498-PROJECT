/// Bitki Hastalığı Tedavi Protokolü ekranı.
///
/// Hastalık işaretlenmiş bir bitki için kullanıcıya adım adım tedavi yolu
/// sunar. Veri tabanı [DiseaseAdvice] (TAGEM/Zirai Mücadele Teknik
/// Talimatları kaynaklı) içeriği ile beslenir.
///
/// CLAUDE.md Bölüm 17 (BKÜ Güvenlik Kuralları) uyumu için:
///   • Önce izolasyon + kültürel/organik mücadele gösterilir.
///   • Aktif madde referansları yalnız BKÜ doğrulama kapısı ile açılır;
///     bu ekran kullanıcıya "şu ürünü şu dozda at" reçetesi vermez.
///   • Uygulama zamanlaması ve teknik prensipler ürün-agnostiktir
///     (saat, rüzgar, koruyucu donanım, yeniden uygulama aralığı genel
///     kuralı); spesifik doz ve hasat bekleme süresi (PHI) için ürün
///     etiketi ve bku.tarim.gov.tr referansı zorunlu kılınır.
///   • Uzman onayı uyarısı kalıcı footer'da görünür.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';

import '../data/activity_types.dart';
import '../data/disease_advice.dart';
import '../services/app_providers.dart';
import '../theme/app_theme.dart';
import '../widgets/activity_quick_log.dart';
import '../widgets/floating_toast.dart';

class TreatmentProtocolScreen extends ConsumerWidget {
  const TreatmentProtocolScreen({
    super.key,
    required this.fieldId,
    required this.fieldName,
    required this.cropName,
    required this.diseaseName,
    this.plantInstanceId,
  });

  final String fieldId;
  final String fieldName;
  final String cropName;
  final String diseaseName;
  final String? plantInstanceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final advice = DiseaseAdvice.forName(diseaseName);
    final activitiesAsync = ref.watch(fieldActivityLogProvider(fieldId));
    final sprayingLog = (activitiesAsync.valueOrNull ?? const [])
        .where((a) => a['type'] == ActivityType.spraying)
        .toList();
    final lastSpraying = sprayingLog.isEmpty
        ? null
        : (sprayingLog.first['date'] is DateTime
            ? sprayingLog.first['date'] as DateTime
            : DateTime.tryParse(sprayingLog.first['date'].toString()));
    final daysSinceLast = lastSpraying == null
        ? null
        : DateTime.now().difference(lastSpraying).inDays;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Tedavi Protokolü'),
            Text(
              '$cropName · ${advice.name}',
              style: AppText.xs(context),
            ),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          _HeroCard(advice: advice, fieldName: fieldName),
          const SizedBox(height: 14),
          _RetreatmentBanner(daysSinceLast: daysSinceLast),
          if (daysSinceLast != null) const SizedBox(height: 14),
          _ExpertGate(),
          const SizedBox(height: 14),
          _StepCard(
            number: 1,
            title: 'İzolasyon ve acil önlem',
            color: AppColors.error,
            icon: Icons.warning_amber_rounded,
            items: advice.isolationSteps,
          ),
          const SizedBox(height: 12),
          _StepCard(
            number: 2,
            title: 'Kültürel ve organik mücadele (önce bunları uygula)',
            color: AppColors.emeraldDark,
            icon: Icons.spa_rounded,
            items: advice.organicTreatments,
          ),
          const SizedBox(height: 12),
          _ApplicationPrinciplesCard(),
          const SizedBox(height: 12),
          _ChemicalReferenceCard(items: advice.chemicalTreatments),
          const SizedBox(height: 12),
          _RetreatmentRulesCard(),
          const SizedBox(height: 12),
          _StepCard(
            number: 6,
            title: 'Önleme ve tekrar bulaşmayı engelleme',
            color: AppColors.info,
            icon: Icons.shield_outlined,
            items: advice.preventionTips,
          ),
          const SizedBox(height: 18),
          _TreatmentLogSection(
            fieldId: fieldId,
            sprayingLog: sprayingLog.take(5).toList(),
            daysSinceLast: daysSinceLast,
          ),
          const SizedBox(height: 18),
          _SourcesCard(sources: advice.sources),
          const SizedBox(height: 14),
          _SafetyFooter(),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HERO
// ─────────────────────────────────────────────────────────────────────────────

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.advice, required this.fieldName});
  final DiseaseAdvice advice;
  final String fieldName;

  @override
  Widget build(BuildContext context) {
    final urgencyColor = switch (advice.urgency) {
      'Çok Yüksek' => const Color(0xFFB71C1C),
      'Yüksek' => const Color(0xFFD32F2F),
      'Orta' => const Color(0xFFF57C00),
      _ => const Color(0xFF558B2F),
    };
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: urgencyColor.withValues(alpha: 0.08),
        borderRadius: AppRadius.md,
        border: Border.all(color: urgencyColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.healing_rounded, color: urgencyColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  advice.name,
                  style: AppText.h2(context).copyWith(color: urgencyColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(fieldName, style: AppText.sm(context)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _Pill(
                  label: 'Aciliyet: ${advice.urgency}', color: urgencyColor),
              _Pill(
                  label: advice.pathogenType,
                  color: const Color(0xFF455A64)),
              if (advice.contagious)
                const _Pill(label: 'BULAŞICI', color: Color(0xFFD32F2F)),
            ],
          ),
          const SizedBox(height: 12),
          Text('Yayılma mekanizması', style: AppText.label(context)),
          const SizedBox(height: 4),
          Text(advice.spreadMechanism, style: AppText.sm(context)),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: AppRadius.full,
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style: AppText.xs(context).copyWith(color: color),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// UZMAN ONAY KAPISI (üstte sabit hatırlatma)
// ─────────────────────────────────────────────────────────────────────────────

class _ExpertGate extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.warningBg,
        borderRadius: AppRadius.sm,
        border: Border.all(color: AppColors.warning),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.fact_check_rounded,
              color: AppColors.warning, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Önce teşhisi doğrulat',
                    style: AppText.bodyMd(context)
                        .copyWith(color: AppColors.warning)),
                const SizedBox(height: 4),
                Text(
                  'Bu protokol genel rehberdir. Kesin teşhis ve kimyasal '
                  'mücadele kararı için il/ilçe Tarım Müdürlüğü Bitki Koruma '
                  'Şubesi veya ziraat mühendisi onayı gerekir.',
                  style: AppText.sm(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SONRAKİ UYGULAMA BANNER'I
// ─────────────────────────────────────────────────────────────────────────────

class _RetreatmentBanner extends StatelessWidget {
  const _RetreatmentBanner({required this.daysSinceLast});
  final int? daysSinceLast;

  @override
  Widget build(BuildContext context) {
    if (daysSinceLast == null) return const SizedBox.shrink();
    final due = daysSinceLast! >= 7;
    final color = due ? AppColors.error : AppColors.info;
    final bg = due ? AppColors.errorBg : AppColors.infoBg;
    final label = due
        ? 'Son ilaçlamadan $daysSinceLast gün geçti. Etiket aralığı dolduysa kontrol uygulaması gündeme alınabilir.'
        : 'Son ilaçlama $daysSinceLast gün önce. Etikette yazan uygulama aralığını bekleyin.';
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: AppRadius.sm,
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(Icons.event_repeat_rounded, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text(label, style: AppText.sm(context))),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// UYGULAMA PRENSİPLERİ — Ürün-agnostik teknik kurallar
// ─────────────────────────────────────────────────────────────────────────────

class _ApplicationPrinciplesCard extends StatelessWidget {
  static const _principles = <String>[
    'Sabah 06:00–10:00 veya akşam 17:00 sonrası uygula; gün ortası sıcaklarda yaprak yanması ve hızlı buharlaşma olur.',
    'Rüzgar hızı 4 m/s (≈ 14 km/s) altında olmalı; rüzgar yoksa drift komşu parsele kaçmaz.',
    'Yağıştan en az 24 saat sonra ve gelecek 24 saat yağış beklenmiyorken uygula; aksi halde koruyucu film yıkanır.',
    'Yaprak ıslakken (çiy/yağmur) uygulama yapma; sprey homojen kaplama yapmaz.',
    'Yaprağın hem üst hem ALT yüzeyini ıslatacak biçimde, damlama başlayana kadar tek geçişte örtün.',
    'Sıcaklık 25–28 °C üzerine çıkacaksa erken saate çek; kükürt gibi bazı koruyucular sıcakta yaprak yakar.',
    'Çiçeklenme dönemindeyse arıların aktif olduğu saatleri kesinlikle dışla (sabah erken / akşam geç tercih).',
    'Koruyucu donanım zorunlu: nitril eldiven, gözlük, FFP2/FFP3 maske, uzun kollu kıyafet, çizme.',
    'Sprey tankını uygulamadan önce temizle ve kalibre et; doz ETİKETTEN okunur, "biraz daha fazla" verme.',
    'Aynı aktif maddeyi iki sezon üst üste tek başına kullanma; FRAC/IRAC etki grubuna göre dönüşümlü uygula (direnç önleme).',
    'Hasada en az [etikette yazan PHI] gün kala uygulamayı kes. Bu süreyi etiket veya bku.tarim.gov.tr üzerinden doğrula.',
    'Uygulama sonrası tank, hortum ve memeyi sabunlu su ile yıka; boş ambalajı üçlü yıka, kapağını kapat, geri dönüşüme ver.',
  ];

  @override
  Widget build(BuildContext context) {
    return _StepCard(
      number: 3,
      title: 'Uygulama prensipleri (genel — etiketten önce bunları uygula)',
      color: AppColors.info,
      icon: Icons.schedule_rounded,
      items: _principles,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// KİMYASAL REFERANSLAR — BKÜ kapısı
// ─────────────────────────────────────────────────────────────────────────────

class _ChemicalReferenceCard extends StatelessWidget {
  const _ChemicalReferenceCard({required this.items});
  final List<String> items;

  @override
  Widget build(BuildContext context) {
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
                width: 30,
                height: 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFFEF6C00).withValues(alpha: 0.12),
                  borderRadius: AppRadius.full,
                ),
                child: Text('4',
                    style: AppText.bodyMd(context)
                        .copyWith(color: const Color(0xFFEF6C00))),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Kimyasal aktif madde referansları',
                  style: AppText.bodyMd(context),
                ),
              ),
              const Icon(Icons.medication_rounded,
                  color: Color(0xFFEF6C00), size: 22),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.errorBg,
              borderRadius: AppRadius.sm,
              border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.error_outline_rounded,
                    color: AppColors.error, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Aşağıdaki aktif maddelerin Türkiye\'deki güncel ruhsat '
                    'durumu, izinli ürün adı, etiket dozu ve hasat öncesi '
                    'son uygulama süresi (PHI) için bku.tarim.gov.tr '
                    'üzerinden ürün/ürün etiketi sorgulaması yapın. '
                    'Bu liste reçete değildir.',
                    style: AppText.sm(context),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          for (final item in items) _ActiveIngredientRow(text: item),
        ],
      ),
    );
  }
}

class _ActiveIngredientRow extends StatelessWidget {
  const _ActiveIngredientRow({required this.text});
  final String text;

  String get _queryTerm {
    final dashIdx = text.indexOf('—');
    final base = dashIdx > 0 ? text.substring(0, dashIdx) : text;
    return base.trim();
  }

  bool get _isNote =>
      text.toUpperCase().startsWith('NOT') || text.startsWith('•');

  @override
  Widget build(BuildContext context) {
    if (_isNote) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Text(text,
            style: AppText.xs(context)
                .copyWith(color: AppColors.textSecondary, height: 1.4)),
      );
    }
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: AppRadius.sm,
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.medication_rounded,
              color: Color(0xFFEF6C00), size: 16),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: AppText.sm(context))),
          IconButton(
            visualDensity: VisualDensity.compact,
            tooltip: 'BKÜ arama metnini kopyala',
            icon: const Icon(Icons.copy_rounded, size: 16),
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: _queryTerm));
              if (!context.mounted) return;
              AppToast.show(
                context,
                message:
                    '"$_queryTerm" kopyalandı. bku.tarim.gov.tr aramasına yapıştırın.',
                type: ToastType.success,
              );
            },
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// YENİDEN UYGULAMA / DİRENÇ KURALLARI
// ─────────────────────────────────────────────────────────────────────────────

class _RetreatmentRulesCard extends StatelessWidget {
  static const _rules = <String>[
    'Etikette belirtilen uygulama aralığını (genelde 7–14 gün) aynen takip et; daha sık uygulama direnç riskini artırır.',
    'Aynı etki mekanizmasındaki (FRAC/IRAC kodu aynı) aktif maddeyi en fazla 2 kez üst üste kullan; ardından farklı gruba geç.',
    'Tedaviye başlandıktan sonra her uygulama öncesi yapraklarda iyileşme/yeni belirti olup olmadığını fotoğrafla kaydet.',
    'Hava nem ve sıcaklık tahmini değiştiyse uygulama planını güncelle; nemli/serin dönemde mantar sporları daha aktif olur.',
    'Belirti 2 uygulamadan sonra azalmıyorsa teşhisi sorgulat: yanlış patojen olabilir.',
  ];

  @override
  Widget build(BuildContext context) {
    return _StepCard(
      number: 5,
      title: 'Yeniden uygulama ve direnç yönetimi',
      color: AppColors.soil,
      icon: Icons.repeat_rounded,
      items: _rules,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TEDAVİ SÜRECİ TAKİBİ — kayıt + son uygulamalar
// ─────────────────────────────────────────────────────────────────────────────

class _TreatmentLogSection extends ConsumerWidget {
  const _TreatmentLogSection({
    required this.fieldId,
    required this.sprayingLog,
    required this.daysSinceLast,
  });

  final String fieldId;
  final List<Map<String, dynamic>> sprayingLog;
  final int? daysSinceLast;

  Future<void> _logTreatment(BuildContext context, WidgetRef ref) async {
    final crops =
        ref.read(fieldCropsStreamProvider(fieldId)).valueOrNull ?? const [];
    final fieldData =
        await ref.read(localDataRepositoryProvider).loadFieldById(fieldId);
    final areaDekar = (fieldData?['area_dekar'] as num?)?.toDouble() ?? 1.0;
    if (!context.mounted) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 12,
          bottom: MediaQuery.of(ctx).padding.bottom + 16,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppRadius.lg,
            border: Border.all(color: AppColors.border),
          ),
          padding: const EdgeInsets.all(12),
          child: ActivityQuickLog(
            fieldId: fieldId,
            fieldCrops: crops,
            fieldAreaDekar: areaDekar,
            onLogged: () => Navigator.of(ctx).maybePop(),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
              const Icon(Icons.monitor_heart_rounded,
                  color: AppColors.emeraldDark),
              const SizedBox(width: 8),
              Expanded(
                child: Text('Tedavi süreci',
                    style: AppText.h3(context)
                        .copyWith(color: AppColors.emeraldDark)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            daysSinceLast == null
                ? 'Henüz ilaçlama kaydı yok. Önce kültürel önlemleri uygula; '
                    'kimyasal gerekiyorsa BKÜ\'den doğrulanmış ürünü '
                    '"İlaçlama kaydet" ile günlüğe ekle.'
                : 'Son ilaçlamadan $daysSinceLast gün geçti. Kayıt ekledikçe '
                    'yeniden uygulama aralığı ve sonraki kontrol günü '
                    'otomatik hatırlatılır.',
            style: AppText.sm(context),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.warning,
                foregroundColor: AppColors.textOnDark,
                minimumSize: const Size.fromHeight(46),
                shape: const RoundedRectangleBorder(borderRadius: AppRadius.sm),
              ),
              onPressed: () => _logTreatment(context, ref),
              icon: const Icon(Icons.science_rounded),
              label: const Text('İlaçlama / uygulama kaydet'),
            ),
          ),
          if (sprayingLog.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text('SON UYGULAMALAR', style: AppText.label(context)),
            const SizedBox(height: 6),
            for (final s in sprayingLog) _SprayingRow(activity: s),
          ],
        ],
      ),
    );
  }
}

class _SprayingRow extends StatelessWidget {
  const _SprayingRow({required this.activity});
  final Map<String, dynamic> activity;

  @override
  Widget build(BuildContext context) {
    final date = activity['date'];
    final qty = activity['quantity'];
    final unit = activity['unit']?.toString();
    final note = activity['note_text']?.toString();
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.warningBg,
        borderRadius: AppRadius.sm,
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.science_rounded,
              size: 16, color: AppColors.warning),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_dateLabel(date), style: AppText.bodyMd(context).copyWith(fontSize: 14)),
                if (qty is num && unit != null && unit.isNotEmpty)
                  Text('${_fmt(qty)} $unit',
                      style: AppText.xs(context)),
                if (note != null && note.isNotEmpty)
                  Text(note, style: AppText.xs(context)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _fmt(num v) {
    final d = v.toDouble();
    if (d == d.roundToDouble()) return d.toStringAsFixed(0);
    return d.toStringAsFixed(1);
  }

  static String _dateLabel(dynamic raw) {
    DateTime? d = raw is DateTime ? raw : (raw is String ? DateTime.tryParse(raw) : null);
    if (d == null) return '';
    final now = DateTime.now();
    final diff = now.difference(d);
    if (diff.inHours < 24) return '${diff.inHours} saat önce';
    if (diff.inDays < 7) return '${diff.inDays} gün önce';
    return '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// KAYNAKLAR + FOOTER
// ─────────────────────────────────────────────────────────────────────────────

class _SourcesCard extends StatelessWidget {
  const _SourcesCard({required this.sources});
  final List<String> sources;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: AppRadius.md,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('KAYNAKLAR', style: AppText.label(context)),
          const SizedBox(height: 8),
          for (final s in sources)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.menu_book_rounded,
                      size: 14, color: AppColors.emeraldDark),
                  const SizedBox(width: 8),
                  Expanded(child: Text(s, style: AppText.sm(context))),
                ],
              ),
            ),
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
        color: AppColors.errorBg,
        borderRadius: AppRadius.sm,
        border: Border.all(color: AppColors.error.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.report_gmailerrorred_rounded,
              color: AppColors.error),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Hiçbir kimyasal mücadele kararı bu ekranda son halini almaz. '
              'Aktif madde, ruhsatlı ürün adı, doz ve hasat öncesi son '
              'uygulama süresi (PHI) için ürün etiketi ve '
              'bku.tarim.gov.tr esastır. Uygulama öncesi il/ilçe Tarım '
              'Müdürlüğü Bitki Koruma Şubesi veya yetkili ziraat mühendisi '
              'onayı zorunludur.',
              style: AppText.xs(context)
                  .copyWith(color: AppColors.textPrimary, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ORTAK ADIM KARTI
// ─────────────────────────────────────────────────────────────────────────────

class _StepCard extends StatelessWidget {
  const _StepCard({
    required this.number,
    required this.title,
    required this.color,
    required this.icon,
    required this.items,
  });

  final int number;
  final String title;
  final Color color;
  final IconData icon;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
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
                width: 30,
                height: 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: AppRadius.full,
                ),
                child: Text('$number',
                    style: AppText.bodyMd(context).copyWith(color: color)),
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(title, style: AppText.bodyMd(context))),
              Icon(icon, color: color, size: 22),
            ],
          ),
          const SizedBox(height: 10),
          for (final item in items)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    margin: const EdgeInsets.only(top: 7),
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Text(item, style: AppText.sm(context))),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
