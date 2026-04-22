import 'dart:io';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AnalysisResultScreen extends StatelessWidget {
  final File image;
  final Map<String, dynamic> result;

  const AnalysisResultScreen({
    super.key,
    required this.image,
    required this.result,
  });

  @override
  Widget build(BuildContext context) {
    final type = result['type'] ?? 'error';
    final data = result['data'] ?? {};

    final String title = data['title'] ?? 'Analiz Sonucu';
    final String description = data['description'] ?? '';

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text('Akıllı Tarım Raporu'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Image.file(
              image,
              height: 250,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Çevre Özeti Kartı (Sadece Tarla ise)
                  if (type == 'field')
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.cloud_outlined,
                            color: Colors.blue,
                            size: 30,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              description,
                              style: TextStyle(
                                color: Colors.blue.shade900,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  if (type == 'plant')
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade800,
                      ),
                    ),

                  const Divider(height: 30),

                  // --- YENİ DEVASA TARLA KARTLARI ---
                  if (type == 'field' && data['crops'] != null) ...[
                    const Text(
                      '🚜 Detaylı Ekim ve Gübreleme Planı',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 15),
                    ...(data['crops'] as List).map(
                      (crop) => _buildAdvancedCropCard(context, crop),
                    ),
                  ],

                  if (type == 'plant') ...[
                    _buildDiseaseBanner(data),
                    const SizedBox(height: 12),
                  ],

                  if (type == 'plant' && data['plant_details'] != null) ...[
                    const Text(
                      '🔍 Bitki Özellikleri',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 15),
                    _buildPlantDetails(data['plant_details']),
                  ],

                  if (type == 'error') ...[
                    Card(
                      color: Colors.red.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.error_outline,
                              color: Colors.red,
                              size: 30,
                            ),
                            const SizedBox(width: 15),
                            Expanded(
                              child: Text(
                                data['message'] ?? 'Hata',
                                style: const TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDiseaseBanner(Map<String, dynamic> data) {
    // `disease_analyzed` map'te yoksa → hastalık verisi hiç yok → unknown state.
    final bool analyzed = data.containsKey('disease_analyzed')
        ? data['disease_analyzed'] == true
        : false;
    final bool diseasePresent = data['disease_present'] == true;
    final String diseaseName = (data['disease_name'] ?? '').toString();
    final int confidence = (data['disease_confidence'] as num?)?.toInt() ?? 0;
    final String severity = (data['severity'] ?? '').toString();
    final String symptoms = (data['symptoms'] ?? '').toString();
    final String treatment = (data['treatment'] ?? '').toString();
    final String failureReason =
        (data['disease_failure_reason'] ?? '').toString();

    // STATE 1: Analiz yapılamadı (Gemini hata verdi)
    if (!analyzed) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: AppRadius.md,
          border: Border.all(color: Colors.white24),
        ),
        child: Row(
          children: [
            const Icon(Icons.info_outline, color: Colors.white54, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Hastalık Analizi Yapılamadı',
                    style: TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    failureReason.isNotEmpty
                        ? 'Sebep: $failureReason. Yeniden deneyin.'
                        : 'Görüntü analizi servisine ulaşılamadı. Yeniden deneyin.',
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // STATE 2: Analiz yapıldı, bitki sağlıklı
    if (!diseasePresent) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.emerald.withValues(alpha: 0.12),
          borderRadius: AppRadius.md,
          border: Border.all(color: AppColors.emerald.withValues(alpha: 0.4)),
        ),
        child: Row(
          children: [
            Icon(Icons.check_circle_outline, color: AppColors.emerald, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bitki Sağlıklı',
                    style: TextStyle(
                      color: AppColors.emerald,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  Text(
                    'Görüntü analizinde hastalık veya zararlı belirtisi tespit edilmedi.',
                    style: TextStyle(
                      color: AppColors.emerald.withValues(alpha: 0.8),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final Color severityColor = severity == 'şiddetli'
        ? AppColors.error
        : severity == 'orta'
            ? Colors.orange
            : Colors.amber;

    return Container(
      decoration: BoxDecoration(
        color: severityColor.withValues(alpha: 0.08),
        borderRadius: AppRadius.md,
        border: Border.all(color: severityColor.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Başlık şeridi
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: severityColor.withValues(alpha: 0.18),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
            ),
            child: Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: severityColor, size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'HASTALIK TESPİT EDİLDİ: $diseaseName',
                    style: TextStyle(
                      color: severityColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: severityColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '%$confidence',
                    style: TextStyle(
                      color: severityColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (severity.isNotEmpty)
                  Row(
                    children: [
                      const Text('Şiddet: ',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: severityColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          severity.toUpperCase(),
                          style: TextStyle(
                            color: severityColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                if (symptoms.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Belirtiler: $symptoms',
                    style: const TextStyle(fontSize: 13, height: 1.4),
                  ),
                ],
                if (treatment.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.medical_services_outlined,
                          color: severityColor, size: 18),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          treatment,
                          style: const TextStyle(fontSize: 13, height: 1.4),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- İNANILMAZ DETAYLI KART WIDGET'I ---
  Widget _buildAdvancedCropCard(BuildContext context, dynamic crop) {
    final double uygunluk = (crop['uygunluk'] as num?)?.toDouble() ?? 0;
    final Color uygunlukColor = uygunluk >= 80
        ? Colors.green
        : uygunluk >= 60
            ? Colors.orange
            : Colors.red;
    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Başlık ve Sezon
            Row(
              children: [
                const CircleAvatar(
                  backgroundColor: Colors.green,
                  child: Icon(Icons.eco, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    crop['name'] ?? '',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Sezon ve uygunluk satırı
            Row(children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(crop['season'] ?? '',
                    style: const TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                        fontSize: 12)),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: uygunlukColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.check_circle, size: 14, color: uygunlukColor),
                  const SizedBox(width: 4),
                  Text('%${uygunluk.toStringAsFixed(0)} Uygun',
                      style: TextStyle(
                          color: uygunlukColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12)),
                ]),
              ),
            ]),
            // Uygunluk çubuğu
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: uygunluk / 100,
                  minHeight: 6,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation(uygunlukColor),
                ),
              ),
            ),
            const Divider(),
            const SizedBox(height: 4),

            // Temel Bilgi
            Text(
              crop['info'] ?? '',
              style: const TextStyle(fontSize: 15, height: 1.4),
            ),
            const SizedBox(height: 16),

            // Gübreleme ve Hava Durumu İkonlu Liste
            _buildDetailRow(
              Icons.science,
              'Gübreleme Programı',
              crop['fertilizer'] ?? '',
              Colors.orange,
            ),
            const SizedBox(height: 12),
            _buildDetailRow(
              Icons.water_drop,
              'Haftalık Hava Etkisi',
              crop['weather_impact'] ?? '',
              Colors.blue,
            ),
            const SizedBox(height: 12),
            _buildDetailRow(
              Icons.build_circle,
              'Bakım ve İşçilik',
              crop['care_details'] ?? '',
              Colors.brown,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    IconData icon,
    String title,
    String content,
    Color iconColor,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: iconColor, size: 24),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                content,
                style: TextStyle(color: Colors.grey.shade700, height: 1.4),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPlantDetails(dynamic details) {
    if (details == null) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Text('Bitki detayı bulunamadı.',
            style: TextStyle(color: Colors.red)),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Bilimsel Adı: ${result['data']?['scientific_name'] ?? 'Bilinmiyor'}\nFamilya: ${details['family'] ?? 'Bilinmiyor'}',
          style: const TextStyle(
              fontStyle: FontStyle.italic,
              color: Colors.grey,
              fontSize: 16,
              height: 1.4),
        ),
        const Divider(height: 30),
        _buildInfoBombCard(Icons.speed, 'Başarı Şansı', details['basari_sansi'],
            Colors.green.shade700,
            isBold: true),
        _buildInfoBombCard(Icons.location_on, 'Konum & Çevre Yorumu',
            details['konum_yorumu'], Colors.brown.shade700),
        _buildInfoBombCard(Icons.water_drop, 'Sulama Takvimi',
            details['sulama_takvimi'], Colors.blue.shade700),
        _buildInfoBombCard(Icons.eco, 'Gübre Önerisi', details['gubre_onerisi'],
            Colors.teal.shade700),
        _buildInfoBombCard(Icons.menu_book, 'Nasıl Yetiştirilir?',
            details['nasil_yetistirilir'], Colors.orange.shade700),
        _buildInfoBombCard(Icons.lightbulb, 'Bakım Püf Noktaları',
            details['bakim_puf_noktasi'], Colors.amber.shade800),
        _buildInfoBombCard(Icons.bug_report, 'Hastalık & Zararlı Riskleri',
            details['hastalik_riskleri'], Colors.red.shade700),
        if (details['hasat_zamani'] != null &&
            details['hasat_zamani'].toString().length > 5)
          _buildInfoBombCard(Icons.shopping_basket, 'Hasat Bilgisi',
              details['hasat_zamani'], Colors.purple.shade700),
        if (details['depolama_saklama'] != null &&
            details['depolama_saklama'].toString().length > 5)
          _buildInfoBombCard(Icons.inventory, 'Depolama & Saklama',
              details['depolama_saklama'], Colors.blueGrey.shade700),
      ],
    );
  }

  Widget _buildInfoBombCard(
    IconData icon,
    String title,
    String? content,
    Color color, {
    bool isBold = false,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: color.withValues(alpha: 0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    content ?? 'Bilgi Yok',
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.4,
                      fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
