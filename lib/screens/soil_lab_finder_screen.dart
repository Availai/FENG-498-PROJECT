import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/soil_lab_finder.dart';
import '../theme/app_theme.dart';
import '../widgets/floating_toast.dart';

/// Yakındaki Toprak Analizi Laboratuvarı Bulucu ekranı.
///
/// Tarla/örnek konumuna göre, çiftçinin seçtiği yarıçap içinde **akredite
/// toprak analizi laboratuvarı** aratmasına yardımcı olur. CLAUDE.md ilkeleri
/// gereği laboratuvar listesi UYDURULMAZ; ekran yalnızca konuma dayalı harita
/// ve web arama bağlantıları üretir ([SoilLabFinder]). Gerçek sonuçları
/// kullanıcı cihazının harita/tarayıcı uygulamasında görür.
///
/// Çevrimdışı-öncelikli: bağlantı üretimi yereldir; yalnızca kullanıcı bir
/// bağlantıya dokunduğunda internet gerekir.
class SoilLabFinderScreen extends StatefulWidget {
  final double latitude;
  final double longitude;

  /// Konum etiketi için (varsa) — uydurulmaz, yoksa null geçilir.
  final String? province;
  final String? district;

  /// Başlangıç arama yarıçapı (km).
  final int initialRadiusKm;

  const SoilLabFinderScreen({
    super.key,
    required this.latitude,
    required this.longitude,
    this.province,
    this.district,
    this.initialRadiusKm = 100,
  });

  @override
  State<SoilLabFinderScreen> createState() => _SoilLabFinderScreenState();
}

class _SoilLabFinderScreenState extends State<SoilLabFinderScreen> {
  late int _radiusKm;

  @override
  void initState() {
    super.initState();
    _radiusKm = SoilLabFinder.radiusOptionsKm.contains(widget.initialRadiusKm)
        ? widget.initialRadiusKm
        : 100;
  }

  Future<void> _open(String raw) async {
    final uri = Uri.tryParse(raw);
    bool ok = false;
    if (uri != null) {
      try {
        ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      } catch (_) {
        ok = false;
      }
    }
    if (!ok && mounted) {
      await Clipboard.setData(ClipboardData(text: raw));
      if (mounted) {
        AppToast.show(
          context,
          message: 'Bağlantı açılamadı, panoya kopyalandı.',
          type: ToastType.warning,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final result = SoilLabFinder.buildOptions(
      lat: widget.latitude,
      lon: widget.longitude,
      radiusKm: _radiusKm,
      province: widget.province,
      district: widget.district,
    );

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Yakındaki Toprak Laboratuvarı'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          _locationCard(result),
          const SizedBox(height: 12),
          _radiusCard(),
          const SizedBox(height: 12),
          Text(
            'Arama bağlantıları',
            style: GoogleFonts.outfit(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          ...result.options.map(_optionTile),
          const SizedBox(height: 12),
          _disclaimerCard(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _locationCard(SoilLabFinderResult result) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.emerald.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          const Icon(Icons.place_rounded, color: AppColors.emeraldDark),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Arama merkezi',
                    style: TextStyle(
                        fontSize: 12, color: AppColors.textSecondary)),
                const SizedBox(height: 2),
                Text(
                  result.locationLabel,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.emerald.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '~${result.radiusLabel}',
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.emeraldDark),
            ),
          ),
        ],
      ),
    );
  }

  Widget _radiusCard() {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.emerald.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Arama yarıçapı',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 2),
          const Text(
            'Aramayı konumunuzun çevresinde yaklaşık bu uzaklıkta tutar.',
            style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            children: [
              for (final km in SoilLabFinder.radiusOptionsKm)
                ChoiceChip(
                  label: Text('$km km'),
                  selected: _radiusKm == km,
                  selectedColor: AppColors.emerald.withValues(alpha: 0.18),
                  labelStyle: TextStyle(
                    fontSize: 13,
                    fontWeight:
                        _radiusKm == km ? FontWeight.w700 : FontWeight.w500,
                    color: _radiusKm == km
                        ? AppColors.emeraldDark
                        : AppColors.textSecondary,
                  ),
                  onSelected: (_) => setState(() => _radiusKm = km),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _optionTile(SoilLabSearchOption opt) {
    final (icon, color) = switch (opt.kind) {
      SoilLabLinkKind.map => (Icons.map_rounded, AppColors.emeraldDark),
      SoilLabLinkKind.web => (Icons.travel_explore_rounded, AppColors.emerald),
      SoilLabLinkKind.official => (
          Icons.account_balance_rounded,
          AppColors.warning
        ),
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: () => _open(opt.url),
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: color.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        opt.title,
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        opt.subtitle,
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.open_in_new_rounded,
                    size: 18, color: AppColors.textSecondary),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _disclaimerCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, size: 18, color: AppColors.warning),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Bu liste arama bağlantılarından oluşur; Tarlam belirli bir '
              'laboratuvarı önermez veya doğruluğunu garanti etmez. '
              'Analiz öncesi laboratuvarın akreditasyonunu (TÜRKAK / Bakanlık '
              'yetkisi) ve örnek alma kurallarını teyit edin.',
              style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}
