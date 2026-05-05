import 'package:flutter/material.dart';

import '../data/disease_advice.dart';
import '../data/disease_types.dart';
import '../theme/app_theme.dart';

/// Hastalık tanısı kaydedildikten sonra çiftçiye yönelik tavsiye paneli.
///
/// Bulaşıcılık, izolasyon adımları, organik+kimyasal mücadele, koruma ve
/// (ölü bitki seçilmişse) güvenli koparma protokolü gösterir. Tüm içerik
/// `DiseaseAdvice` veritabanından gelir; kaynak Tarım Bakanlığı / TAGEM
/// teknik talimatlarına dayanır.
class DiseaseAdviceSheet extends StatelessWidget {
  const DiseaseAdviceSheet({
    super.key,
    required this.cropName,
    required this.healthStatus,
    required this.diseaseType,
  });

  final String cropName;

  /// 'diseased' veya 'dead'.
  final String healthStatus;

  /// Hastalık adı; 'dead' durumunda da varsa gösterilir.
  final String? diseaseType;

  static Future<void> show(
    BuildContext context, {
    required String cropName,
    required String healthStatus,
    String? diseaseType,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.bg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.78,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        builder: (_, scrollCtrl) => DiseaseAdviceSheet(
          cropName: cropName,
          healthStatus: healthStatus,
          diseaseType: diseaseType,
        )._build(context, scrollCtrl),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => _build(context, null);

  Widget _build(BuildContext context, ScrollController? scrollCtrl) {
    final advice = DiseaseAdvice.forName(diseaseType);
    final isDead = healthStatus == DiseaseTypes.statusDead;

    final urgencyColor = switch (advice.urgency) {
      'Çok Yüksek' => const Color(0xFFB71C1C),
      'Yüksek' => const Color(0xFFD32F2F),
      'Orta' => const Color(0xFFF57C00),
      _ => const Color(0xFF558B2F),
    };

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Başlık
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: urgencyColor.withValues(alpha: 0.15),
                  borderRadius: AppRadius.sm,
                ),
                child: Icon(
                  isDead ? Icons.dangerous_rounded : Icons.healing_rounded,
                  color: urgencyColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isDead
                          ? 'Ölü Bitki — Güvenli Koparma'
                          : '${advice.name} — Mücadele Rehberi',
                      style: AppText.h3(context),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      cropName,
                      style: AppText.xs(context)
                          .copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Etiketler — patojen tipi, bulaşıcılık, aciliyet
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _Tag(
                icon: Icons.biotech_rounded,
                label: 'Patojen: ${advice.pathogenType}',
                color: const Color(0xFF455A64),
              ),
              if (advice.contagious)
                const _Tag(
                  icon: Icons.coronavirus_rounded,
                  label: 'BULAŞICI',
                  color: Color(0xFFD32F2F),
                ),
              _Tag(
                icon: Icons.priority_high_rounded,
                label: 'Aciliyet: ${advice.urgency}',
                color: urgencyColor,
              ),
            ],
          ),
          const SizedBox(height: 14),
          // İçerik — kaydırılabilir
          Expanded(
            child: SingleChildScrollView(
              controller: scrollCtrl,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (isDead) ...[
                    _Section(
                      title: 'Etrafa Zarar Vermeden Koparma Protokolü',
                      icon: Icons.delete_forever_rounded,
                      color: const Color(0xFF6A1B9A),
                      bullets: advice.deadPlantProtocol,
                    ),
                    const SizedBox(height: 12),
                    _InfoBanner(
                      text:
                          'Hastalık bulaşıcı ise yan komşu bitkilere koruyucu mücadele uygulamayı unutmayın.',
                      color: urgencyColor,
                    ),
                  ] else ...[
                    if (advice.contagious)
                      _InfoBanner(
                        text:
                            'Bu hastalık BULAŞICIDIR. Aşağıdaki izolasyon adımlarını saatler içinde uygulayın.',
                        color: const Color(0xFFD32F2F),
                      ),
                    if (advice.contagious) const SizedBox(height: 10),
                    _Section(
                      title: 'Belirtiler',
                      icon: Icons.visibility_rounded,
                      color: const Color(0xFF455A64),
                      bullets: advice.symptoms,
                    ),
                    const SizedBox(height: 12),
                    _Paragraph(
                      title: 'Yayılma Mekanizması',
                      icon: Icons.air_rounded,
                      color: const Color(0xFF1565C0),
                      body: advice.spreadMechanism,
                    ),
                    const SizedBox(height: 12),
                    _Section(
                      title: 'Hemen Yapılacaklar — İzolasyon',
                      icon: Icons.shield_rounded,
                      color: const Color(0xFFD32F2F),
                      bullets: advice.isolationSteps,
                    ),
                    const SizedBox(height: 12),
                    _Section(
                      title: 'Organik / Kültürel Mücadele',
                      icon: Icons.eco_rounded,
                      color: const Color(0xFF2E7D32),
                      bullets: advice.organicTreatments,
                    ),
                    const SizedBox(height: 12),
                    _Section(
                      title: 'Kimyasal Mücadele (Aktif Madde)',
                      icon: Icons.science_rounded,
                      color: const Color(0xFFEF6C00),
                      bullets: advice.chemicalTreatments,
                    ),
                    const SizedBox(height: 12),
                    _Section(
                      title: 'Tekrarlamayı Önleme',
                      icon: Icons.health_and_safety_rounded,
                      color: const Color(0xFF1565C0),
                      bullets: advice.preventionTips,
                    ),
                  ],
                  const SizedBox(height: 16),
                  _Sources(sources: advice.sources),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.mint,
                      borderRadius: AppRadius.sm,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.info_outline,
                            color: AppColors.emeraldDark, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Kimyasal aktif madde ruhsat durumu sürekli güncellenir. '
                            'Satın aldığınız ürünün etiketini mutlaka okuyun ve '
                            'bku.tarim.gov.tr üzerinden son durumu doğrulayın.',
                            style: AppText.xs(context)
                                .copyWith(color: AppColors.emeraldDark),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.check_rounded),
                      label: const Text('Anladım'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.emerald,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: const RoundedRectangleBorder(
                          borderRadius: AppRadius.sm,
                        ),
                      ),
                    ),
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

class _Tag extends StatelessWidget {
  const _Tag({required this.icon, required this.label, required this.color});

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.icon,
    required this.color,
    required this.bullets,
  });

  final String title;
  final IconData icon;
  final Color color;
  final List<String> bullets;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: AppRadius.sm,
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...bullets.map(
            (b) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      b,
                      style: AppText.body(context).copyWith(
                        height: 1.35,
                        fontSize: 13,
                      ),
                    ),
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

class _Paragraph extends StatelessWidget {
  const _Paragraph({
    required this.title,
    required this.icon,
    required this.color,
    required this.body,
  });

  final String title;
  final IconData icon;
  final Color color;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: AppRadius.sm,
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: color,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            body,
            style: AppText.body(context).copyWith(height: 1.4, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _InfoBanner extends StatelessWidget {
  const _InfoBanner({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: AppRadius.sm,
        border: Border.all(color: color),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning_amber_rounded, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Sources extends StatelessWidget {
  const _Sources({required this.sources});

  final List<String> sources;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.sm,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.menu_book_rounded,
                  size: 16, color: AppColors.textSecondary),
              SizedBox(width: 6),
              Text(
                'Kaynaklar',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ...sources.map(
            (s) => Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Text(
                '• $s',
                style: AppText.xs(context).copyWith(
                  color: AppColors.textSecondary,
                  height: 1.35,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
