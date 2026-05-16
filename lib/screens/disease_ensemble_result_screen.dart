import 'dart:io';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Çoklu fotoğraf ensemble hastalık teşhisi sonuç ekranı.
/// AgriService.diagnoseDiseaseEnsemble çıktısını gösterir.
class DiseaseEnsembleResultScreen extends StatelessWidget {
  final List<File> photos;
  final Map<String, dynamic> result;

  const DiseaseEnsembleResultScreen({
    super.key,
    required this.photos,
    required this.result,
  });

  @override
  Widget build(BuildContext context) {
    final data = (result['data'] as Map?) ?? const {};
    final species = (data['species'] ?? 'Bilinmeyen').toString();
    final speciesConf = (data['species_confidence'] as num?)?.toInt() ?? 0;
    final diseasePresent = data['disease_present'] == true;
    final diseaseName = (data['disease_name'] ?? '').toString();
    final diseaseConf = (data['disease_confidence'] as num?)?.toInt() ?? 0;
    final severity = (data['severity'] ?? '').toString();
    final treatment = (data['treatment'] ?? '').toString();
    final photoCount = (data['photo_count'] as num?)?.toInt() ?? photos.length;

    final color = !diseasePresent
        ? AppColors.emerald
        : (severity == 'şiddetli'
            ? AppColors.error
            : (severity == 'orta' ? Colors.orange : Colors.amber));

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Hastalık Teşhisi'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Foto şeridi
          SizedBox(
            height: 90,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: photos.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) => ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(photos[i],
                    width: 90, height: 90, fit: BoxFit.cover),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Tür kartı
          _statCard(
            icon: Icons.eco,
            iconColor: AppColors.emerald,
            title: 'Tespit Edilen Tür',
            value: species,
            confidencePct: speciesConf,
            barColor: AppColors.emerald,
          ),
          const SizedBox(height: 12),

          // Hastalık kartı
          _statCard(
            icon: diseasePresent ? Icons.warning_amber : Icons.check_circle,
            iconColor: color,
            title: diseasePresent ? 'Hastalık Tespit Edildi' : 'Bitki Sağlıklı',
            value: diseasePresent
                ? '$diseaseName${severity.isNotEmpty ? "  •  Şiddet: $severity" : ""}'
                : 'Belirgin bir hastalık bulgusu yok.',
            confidencePct: diseasePresent ? diseaseConf : speciesConf,
            barColor: color,
          ),

          if (diseasePresent && treatment.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: AppRadius.md,
                border: Border.all(color: color.withValues(alpha: 0.4)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.medical_services_outlined,
                          color: color, size: 20),
                      const SizedBox(width: 8),
                      Text('Önerilen Müdahale',
                          style: AppText.h3(context).copyWith(color: color)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(treatment, style: AppText.sm(context)),
                ],
              ),
            ),
          ],

          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: AppRadius.md,
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, size: 16, color: Colors.white54),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Sonuç $photoCount fotoğrafın iki bağımsız kanaldan '
                    '(PlantNet + Gemini Vision) ayrı ayrı değerlendirilip '
                    'oy birleştirilerek üretildi. Güven oranı bu iki kanalın '
                    'uyumunu yansıtır.',
                    style: const TextStyle(color: Colors.white54, fontSize: 11),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
    required int confidencePct,
    required Color barColor,
  }) {
    return Builder(builder: (context) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.md,
          boxShadow: AppShadows.md,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: iconColor, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(title,
                      style:
                          AppText.sm(context).copyWith(color: Colors.white70)),
                ),
                Text('%$confidencePct',
                    style: TextStyle(
                        color: barColor, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 6),
            Text(value, style: AppText.h3(context)),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: confidencePct / 100,
                minHeight: 6,
                backgroundColor: Colors.white12,
                valueColor: AlwaysStoppedAnimation(barColor),
              ),
            ),
          ],
        ),
      );
    });
  }
}
