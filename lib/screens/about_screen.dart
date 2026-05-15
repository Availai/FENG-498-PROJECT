import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';
import '../widgets/floating_toast.dart';

/// Hakkımızda — Tarlam'ın kullandığı veri kaynakları ve referansları
/// kullanıcıya şeffaf biçimde sunan ekran. Amaç: bilgilerin hangi
/// kurum/kuruluştan geldiğini göstererek güven inşa etmek.
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Hakkımızda'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          _Header(),
          const SizedBox(height: 20),
          _IntroCard(),
          const SizedBox(height: 24),

          _SectionTitle('Hava Durumu ve İklim Verileri'),
          _ReferenceTile(
            title: 'OpenWeatherMap',
            description:
                'Anlık hava durumu, sıcaklık, nem ve rüzgâr verileri için kullanılır.',
            url: 'https://openweathermap.org',
            icon: Icons.wb_sunny_rounded,
            color: Color(0xFFE67E22),
          ),
          _ReferenceTile(
            title: 'Open-Meteo',
            description:
                '7 günlük yağış ve sıcaklık tahminleri ile sulama planlaması için referans veri kaynağıdır.',
            url: 'https://open-meteo.com',
            icon: Icons.cloud_rounded,
            color: Color(0xFF1976D2),
          ),
          _ReferenceTile(
            title: 'Meteoroloji Genel Müdürlüğü (MGM)',
            description:
                'Türkiye resmi meteoroloji kurumu. Don uyarıları ve resmi iklim verileri için referans alınmıştır.',
            url: 'https://www.mgm.gov.tr',
            icon: Icons.ac_unit_rounded,
            color: Color(0xFF0288D1),
          ),
          _ReferenceTile(
            title: 'Agromonitoring',
            description:
                'Uydu tabanlı tarımsal hava ve bitki sağlığı (NDVI) analizleri için kullanılır.',
            url: 'https://agromonitoring.com',
            icon: Icons.satellite_alt_rounded,
            color: Color(0xFF6A1B9A),
          ),

          const SizedBox(height: 16),
          _SectionTitle('Toprak ve Arazi Verileri'),
          _ReferenceTile(
            title: 'SoilGrids (ISRIC)',
            description:
                'Dünya genelinde 250 m çözünürlüklü toprak özellikleri (pH, organik karbon, kil oranı vb.) sağlayan akademik veri tabanı.',
            url: 'https://soilgrids.org',
            icon: Icons.landscape_rounded,
            color: Color(0xFF8D6E63),
          ),
          _ReferenceTile(
            title: 'OpenStreetMap (OSM)',
            description:
                'Tarla poligonları ve harita altlığı için açık kaynak coğrafi veri sağlayıcısıdır.',
            url: 'https://www.openstreetmap.org',
            icon: Icons.map_rounded,
            color: Color(0xFF388E3C),
          ),
          _ReferenceTile(
            title: 'Esri ArcGIS World Imagery',
            description:
                'Yüksek çözünürlüklü uydu görüntüsü altlığı için kullanılır.',
            url: 'https://www.arcgis.com',
            icon: Icons.public_rounded,
            color: Color(0xFF1565C0),
          ),

          const SizedBox(height: 16),
          _SectionTitle('Bitki ve Tarım Veritabanı'),
          _ReferenceTile(
            title: 'BÜGEM — Bitkisel Üretim Genel Müdürlüğü',
            description:
                'Uygulamadaki 292 Türkiye bitkisinin ekim/hasat takvimi, çeşit önerileri ve bölgesel uygunluk verisi BÜGEM yetiştiricilik kılavuzlarından derlenmiştir.',
            url: 'https://www.tarimorman.gov.tr/BUGEM',
            icon: Icons.eco_rounded,
            color: Color(0xFF2E7D32),
          ),
          _ReferenceTile(
            title: 'T.C. Tarım ve Orman Bakanlığı',
            description:
                'Bitki yetiştiricilik kılavuzları, çeşit tescili ve resmi tarım istatistikleri — uygulamadaki ürün profillerinin ana referansıdır.',
            url: 'https://www.tarimorman.gov.tr',
            icon: Icons.account_balance_rounded,
            color: Color(0xFF1B5E20),
          ),
          _ReferenceTile(
            title: 'TAGEM (Tarımsal Araştırmalar Genel Müdürlüğü)',
            description:
                'Sıcaklık, pH ve yağış toleransları, hastalık eşik değerleri ve Zirai Mücadele Teknik Talimatları TAGEM yayınlarından alınmıştır.',
            url: 'https://www.tarimorman.gov.tr/TAGEM',
            icon: Icons.science_rounded,
            color: Color(0xFF558B2F),
          ),
          _ReferenceTile(
            title: 'BKÜ — Bitki Koruma Ürünleri Veritabanı',
            description:
                'Aktif madde, ruhsatlı ticari ürün ve hasada bekleme süresi (PHI) doğrulaması için bu resmi veritabanına yönlendirme yapılır.',
            url: 'https://bku.tarim.gov.tr',
            icon: Icons.medication_liquid_rounded,
            color: Color(0xFFEF6C00),
          ),
          _ReferenceTile(
            title: 'Perenual Plant API',
            description:
                'Bitki türleri, bakım gereksinimleri ve botanik bilgiler için ek referans olarak kullanılır.',
            url: 'https://perenual.com/docs/api',
            icon: Icons.local_florist_rounded,
            color: Color(0xFF7CB342),
          ),
          _ReferenceTile(
            title: 'FAO (Food and Agriculture Organization)',
            description:
                'Sulama suyu gereksinimi (ETo, Kc katsayıları) hesabı FAO-56 metodolojisine göre yapılmaktadır.',
            url: 'https://www.fao.org/land-water/databases-and-software/crop-information',
            icon: Icons.water_drop_rounded,
            color: Color(0xFF00897B),
          ),

          const SizedBox(height: 16),
          _SectionTitle('Tarım Kural Motoru — Bilimsel Referanslar'),
          _ReferenceTile(
            title: 'FAO Irrigation & Drainage Paper No. 56',
            description:
                'Sulama suyu hesabı (ETo, Kc katsayıları) ve haftalık su açığı kuralları, FAO-56 Crop Evapotranspiration metodolojisine göre uygulanır.',
            url: 'https://www.fao.org/3/x0490e/x0490e00.htm',
            icon: Icons.calculate_rounded,
            color: Color(0xFF00897B),
          ),
          _ReferenceTile(
            title: 'EPPO Global Database',
            description:
                'Hastalık ve zararlı kuralları, EPPO Bayer kodları (BOTRCI, PHYTIN, PUCCST, TUTAAB vb.) ile etiketlenmiştir — AB resmi taksonomi standardı.',
            url: 'https://gd.eppo.int',
            icon: Icons.bug_report_rounded,
            color: Color(0xFF6D4C41),
          ),
          _ReferenceTile(
            title: 'FAO Frost Protection Rehberi',
            description:
                'Don uyarı eşikleri (0 °C kritik, +2 °C uyarı) FAO Frost Protection rehberi ve WMO ground-frost tanımına dayanır.',
            url: 'https://www.fao.org/3/y7223e/y7223e00.htm',
            icon: Icons.ac_unit_rounded,
            color: Color(0xFF0277BD),
          ),
          _ReferenceTile(
            title: 'WMO — Beaufort Rüzgâr Ölçeği',
            description:
                'Şiddetli rüzgâr ve fırtına uyarıları (≥10.8 m/s uyarı, ≥17.2 m/s fırtına) WMO Beaufort ölçeği standardına göre üretilir.',
            url: 'https://library.wmo.int/idurl/4/41650',
            icon: Icons.air_rounded,
            color: Color(0xFF455A64),
          ),
          _ReferenceTile(
            title: 'USDA Natural Resources Conservation Service',
            description:
                'Toprak sınıflandırması, pH limitleri ve tarla kapasitesi eşik değerleri NRCS yayınlarından alınmıştır.',
            url: 'https://www.nrcs.usda.gov',
            icon: Icons.grass_rounded,
            color: Color(0xFF689F38),
          ),

          const SizedBox(height: 16),
          _SectionTitle('Altyapı ve Servisler'),
          _ReferenceTile(
            title: 'Firebase Authentication',
            description: 'Güvenli kullanıcı kimlik doğrulaması için kullanılır.',
            url: 'https://firebase.google.com/docs/auth',
            icon: Icons.lock_rounded,
            color: Color(0xFFFF6F00),
          ),
          _ReferenceTile(
            title: 'Firebase Cloud Messaging (FCM)',
            description: 'Don ve sulama bildirimleri için kullanılır.',
            url: 'https://firebase.google.com/docs/cloud-messaging',
            icon: Icons.notifications_rounded,
            color: Color(0xFFFFA000),
          ),

          const SizedBox(height: 28),
          _DisclaimerCard(),
          const SizedBox(height: 16),
          _ProjectInfoCard(),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.emeraldDark, AppColors.emerald],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: AppRadius.lg,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.verified_rounded,
                color: Colors.white, size: 30),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tarlam',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Doğrulanabilir kaynaklara dayanan akıllı tarım uygulaması',
                  style: TextStyle(
                    color: Color(0xFFE0F2E4),
                    fontSize: 13,
                    height: 1.3,
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

class _IntroCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.md,
        border: Border.all(color: AppColors.border),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline_rounded,
                  color: AppColors.emeraldDark, size: 20),
              SizedBox(width: 8),
              Text(
                'Neden bu sayfa?',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          SizedBox(height: 10),
          Text(
            'Tarlam, çiftçiye sunduğu her bilginin nereden geldiğini açıkça '
            'gösterir. Hava durumu, toprak verisi, bitki yetiştiricilik '
            'kuralları ve sulama hesapları; akademik yayınlardan, resmi '
            'kurum kayıtlarından ve açık kaynaklı bilimsel veri tabanlarından '
            'derlenmiştir. Aşağıda kullandığımız tüm kaynakları bulabilirsiniz.',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 16, 4, 10),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 18,
            decoration: BoxDecoration(
              color: AppColors.emerald,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReferenceTile extends StatelessWidget {
  final String title;
  final String description;
  final String url;
  final IconData icon;
  final Color color;

  const _ReferenceTile({
    required this.title,
    required this.description,
    required this.url,
    required this.icon,
    required this.color,
  });

  bool _isWebUrl(String s) =>
      s.startsWith('http://') || s.startsWith('https://');

  Future<void> _openUrl(BuildContext context, String raw) async {
    if (!_isWebUrl(raw)) {
      // Yerel asset/dosya yolu: tarayıcıda açılamaz, kopyalamayı öner.
      await _copyUrl(context, raw);
      return;
    }
    final uri = Uri.tryParse(raw);
    bool ok = false;
    if (uri != null) {
      try {
        ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      } catch (_) {
        ok = false;
      }
    }
    if (!ok && context.mounted) {
      AppToast.show(
        context,
        message: 'Bağlantı açılamadı, kopyalandı: $raw',
        type: ToastType.warning,
      );
      await Clipboard.setData(ClipboardData(text: raw));
    }
  }

  Future<void> _copyUrl(BuildContext context, String raw) async {
    await Clipboard.setData(ClipboardData(text: raw));
    if (context.mounted) {
      AppToast.show(
        context,
        message: 'Bağlantı kopyalandı',
        type: ToastType.success,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.md,
        border: Border.all(color: AppColors.border),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _openUrl(context, url),
        onLongPress: () => _copyUrl(context, url),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          _isWebUrl(url)
                              ? Icons.open_in_new_rounded
                              : Icons.folder_open_rounded,
                          size: 14,
                          color: AppColors.textTertiary,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            url,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.info,
                              fontWeight: FontWeight.w500,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.copy_rounded, size: 16),
                          color: AppColors.textTertiary,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                              minWidth: 32, minHeight: 32),
                          tooltip: 'Bağlantıyı kopyala',
                          onPressed: () => _copyUrl(context, url),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DisclaimerCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.warningBg,
        borderRadius: AppRadius.md,
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.shield_outlined, color: AppColors.warning, size: 22),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sorumluluk Bildirimi',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Tarlam, akademik ve resmi kaynaklara dayanır; ancak '
                  'tarımsal kararlar yerel koşullara bağlıdır. Kritik '
                  'kararlarda yerel ziraat mühendisi veya İl/İlçe Tarım '
                  'Müdürlüğü ile görüşmenizi öneririz.',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    height: 1.45,
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

class _ProjectInfoCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.mint,
        borderRadius: AppRadius.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.school_rounded,
                  size: 20, color: AppColors.emeraldDark),
              SizedBox(width: 8),
              Text(
                'Proje Bilgisi',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.emeraldDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Tarlam, FENG-498 Senior Design Project kapsamında geliştirilen '
            'çevrimdışı öncelikli bir Türkçe akıllı tarım uygulamasıdır.',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Sürüm 1.0 · 2026',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textTertiary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
