import 'package:flutter/material.dart';

import '../data/disease_advice.dart';
import '../data/disease_types.dart';
import '../theme/app_theme.dart';

/// Hastalık tanısı kaydedildikten sonra çiftçiye yönelik kompakt özet kart.
///
/// Detaylı tedavi planı, izolasyon adımları ve kaynaklar **Bugünün Rehberi**
/// ekranındaki HASTALIK REHBERİ bölümünde otomatik gösterilir. Bu sheet
/// sadece çiftçinin işaretlemenin başarılı olduğunu görmesi ve önerilen
/// kimyasal mücadelenin başlıca aktif maddelerini hızlıca okuyabilmesi
/// içindir.
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
      backgroundColor: AppColors.bg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => DiseaseAdviceSheet(
        cropName: cropName,
        healthStatus: healthStatus,
        diseaseType: diseaseType,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final advice = DiseaseAdvice.forName(diseaseType);
    final isDead = healthStatus == DiseaseTypes.statusDead;

    final urgencyColor = isDead
        ? const Color(0xFF424242)
        : switch (advice.urgency) {
            'Çok Yüksek' => const Color(0xFFB71C1C),
            'Yüksek' => const Color(0xFFD32F2F),
            'Orta' => const Color(0xFFF57C00),
            _ => const Color(0xFF558B2F),
          };

    final activeIngredients = _topActiveIngredients(advice.chemicalTreatments);

    return SafeArea(
      child: Padding(
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
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isDead ? 'Ölü bitki kaydedildi' : '${advice.name} kaydedildi',
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
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                _Tag(
                  icon: Icons.priority_high_rounded,
                  label: 'Aciliyet: ${advice.urgency}',
                  color: urgencyColor,
                ),
                _Tag(
                  icon: Icons.biotech_rounded,
                  label: advice.pathogenType,
                  color: const Color(0xFF455A64),
                ),
                if (advice.contagious && !isDead)
                  const _Tag(
                    icon: Icons.coronavirus_rounded,
                    label: 'BULAŞICI',
                    color: Color(0xFFD32F2F),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            if (isDead)
              _CompactList(
                title: 'Sökme önerisi',
                icon: Icons.delete_forever_rounded,
                color: const Color(0xFF424242),
                items: advice.deadPlantProtocol.take(3).toList(),
              )
            else if (activeIngredients.isNotEmpty)
              _CompactList(
                title: 'Önerilen aktif maddeler',
                icon: Icons.medication_rounded,
                color: const Color(0xFFEF6C00),
                items: activeIngredients,
              ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.mint,
                borderRadius: AppRadius.sm,
              ),
              child: Row(
                children: const [
                  Icon(Icons.menu_book_rounded,
                      color: AppColors.emeraldDark, size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Detaylı tedavi planı, izolasyon adımları ve kaynaklar '
                      'Bugünün Rehberi → HASTALIK REHBERİ bölümünde otomatik gösterilir.',
                      style: TextStyle(
                        color: AppColors.emeraldDark,
                        fontSize: 12,
                        height: 1.35,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.check_rounded),
                label: const Text('Tamam'),
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
    );
  }

  /// `chemicalTreatments` içindeki uzun açıklamalardan ilk 3 aktif maddeyi
  /// kısa biçimde (em-dash öncesini) çıkarır.
  List<String> _topActiveIngredients(List<String> treatments) {
    final out = <String>[];
    for (final t in treatments) {
      final stripped = t.trim();
      if (stripped.isEmpty) continue;
      if (stripped.toLowerCase().startsWith('not')) continue;
      final head = stripped.split('—').first.trim();
      if (head.isEmpty) continue;
      out.add(head);
      if (out.length >= 3) break;
    }
    return out;
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
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

class _CompactList extends StatelessWidget {
  const _CompactList({
    required this.title,
    required this.icon,
    required this.color,
    required this.items,
  });

  final String title;
  final IconData icon;
  final Color color;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
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
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  color: color,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          for (final it in items)
            Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 7),
                    child: Container(
                      width: 5,
                      height: 5,
                      decoration:
                          BoxDecoration(color: color, shape: BoxShape.circle),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      it,
                      style: AppText.body(context).copyWith(
                        height: 1.35,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
