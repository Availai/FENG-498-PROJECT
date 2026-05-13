/// Türkiye'nin 5 öncelikli ürünü (Ayçiçeği, Domates, Mısır, Portakal, Çay)
/// için TAGEM / BATEM / ÇAYKUR / Tarım ve Orman Bakanlığı kaynaklarına
/// dayanan, kullanıcıya kısa, aksiyon odaklı "tavsiye kartı" üretir.
///
/// Bu servis LLM çıktısı veya tahmin üretmez; veriler
/// [TurkiyeCropGuides] çevrimdışı paketinden alınır ve sadece kullanıcı
/// dostu bir biçimde yeniden sunulur.
library;

import 'package:flutter/material.dart';

import '../data/turkiye_crop_guides.dart';
import '../theme/app_theme.dart';

/// Tavsiye kategorileri. UI'da renk/ikon eşlemesi sabittir.
enum TavsiyeKategori {
  ekim,
  sulama,
  besleme,
  koruma,
  hasat,
  munavebe,
  bolge,
  bku,
}

extension TavsiyeKategoriX on TavsiyeKategori {
  String get label {
    switch (this) {
      case TavsiyeKategori.ekim:
        return 'Ekim';
      case TavsiyeKategori.sulama:
        return 'Sulama';
      case TavsiyeKategori.besleme:
        return 'Besleme';
      case TavsiyeKategori.koruma:
        return 'Koruma';
      case TavsiyeKategori.hasat:
        return 'Hasat';
      case TavsiyeKategori.munavebe:
        return 'Münavebe';
      case TavsiyeKategori.bolge:
        return 'Bölge';
      case TavsiyeKategori.bku:
        return 'BKÜ Güvenliği';
    }
  }

  IconData get icon {
    switch (this) {
      case TavsiyeKategori.ekim:
        return Icons.eco_rounded;
      case TavsiyeKategori.sulama:
        return Icons.water_drop_rounded;
      case TavsiyeKategori.besleme:
        return Icons.compost_rounded;
      case TavsiyeKategori.koruma:
        return Icons.shield_rounded;
      case TavsiyeKategori.hasat:
        return Icons.agriculture_rounded;
      case TavsiyeKategori.munavebe:
        return Icons.history_rounded;
      case TavsiyeKategori.bolge:
        return Icons.place_rounded;
      case TavsiyeKategori.bku:
        return Icons.science_rounded;
    }
  }

  Color get color {
    switch (this) {
      case TavsiyeKategori.ekim:
        return AppColors.emeraldDark;
      case TavsiyeKategori.sulama:
        return AppColors.frost;
      case TavsiyeKategori.besleme:
        return AppColors.soil;
      case TavsiyeKategori.koruma:
        return AppColors.warning;
      case TavsiyeKategori.hasat:
        return AppColors.warning;
      case TavsiyeKategori.munavebe:
        return AppColors.soil;
      case TavsiyeKategori.bolge:
        return AppColors.info;
      case TavsiyeKategori.bku:
        return AppColors.error;
    }
  }

  Color get background {
    switch (this) {
      case TavsiyeKategori.ekim:
        return AppColors.mint;
      case TavsiyeKategori.sulama:
        return AppColors.frostBg;
      case TavsiyeKategori.besleme:
        return AppColors.surfaceAlt;
      case TavsiyeKategori.koruma:
        return AppColors.warningBg;
      case TavsiyeKategori.hasat:
        return AppColors.warningBg;
      case TavsiyeKategori.munavebe:
        return AppColors.surfaceAlt;
      case TavsiyeKategori.bolge:
        return AppColors.infoBg;
      case TavsiyeKategori.bku:
        return AppColors.errorBg;
    }
  }
}

/// Tek bir tavsiye kartı.
///
/// [title] kısa eylem başlığı, [action] çiftçiye anlatılan ne yapılacağı,
/// [reason] ise neden böyle yapılması gerektiği. [sources] resmi kaynak
/// referanslarıdır. [requiresBkuCheck] true ise UI'da BKÜ uyarısı gösterilir.
class CropRecommendation {
  final String id;
  final String cropId;
  final String cropName;
  final TavsiyeKategori category;
  final String title;
  final String action;
  final String? reason;
  final List<String> sources;
  final bool requiresBkuCheck;
  final bool requiresExpertConfirmation;

  const CropRecommendation({
    required this.id,
    required this.cropId,
    required this.cropName,
    required this.category,
    required this.title,
    required this.action,
    required this.sources,
    this.reason,
    this.requiresBkuCheck = false,
    this.requiresExpertConfirmation = false,
  });
}

/// [TurkiyeCropGuides] verisinden 5 öncelikli ürün için tavsiye kartları
/// türetir. Aynı girdiye aynı çıktı verir; içerikler tamamen
/// kaynak-kanıtlı çevrimdışı verilerden çıkarılır.
class CropRecommendationsService {
  CropRecommendationsService._();

  /// 5 öncelikli ürünün ID'leri.
  static const List<String> priorityCropIds = [
    'aycicegi',
    'domates',
    'misir',
    'portakal',
    'cay',
  ];

  /// 5 öncelikli ürünün rehberleri.
  static List<TurkiyeCropGuide> priorityGuides() {
    final byId = {for (final g in TurkiyeCropGuides.guides) g.id: g};
    return [
      for (final id in priorityCropIds)
        if (byId.containsKey(id)) byId[id]!,
    ];
  }

  /// Belirli bir ürünün tüm tavsiyelerini sıralı döner.
  /// Sıra: Ekim → Sulama → Besleme → Koruma → Hasat → Münavebe → Bölge → BKÜ.
  static List<CropRecommendation> recommendationsFor(TurkiyeCropGuide g) {
    final firstStage = g.stages.isNotEmpty ? g.stages.first : null;
    final firstPest = g.pests.isNotEmpty ? g.pests.first : null;

    return [
      CropRecommendation(
        id: '${g.id}.ekim',
        cropId: g.id,
        cropName: g.cropName,
        category: TavsiyeKategori.ekim,
        title: 'Ekim / Dikim zamanı',
        action: firstStage != null
            ? '${firstStage.action} (${g.sowingWindow})'
            : 'Ekim aralığı: ${g.sowingWindow}',
        reason:
            'Sıra arası ${_fmt(g.rowSpacingCm)} cm, sıra üzeri ${_fmt(g.plantSpacingCm)} cm; ekim derinliği ${_fmt(g.sowingDepthCm)} cm. Hedef bitki yoğunluğu yaklaşık ${g.plantPopulationPerDekar} bitki/da.',
        sources: g.sourceRefs,
      ),
      CropRecommendation(
        id: '${g.id}.sulama',
        cropId: g.id,
        cropName: g.cropName,
        category: TavsiyeKategori.sulama,
        title: 'Sulama planı',
        action: g.irrigationSummary,
        reason:
            'Sezonluk yaklaşık ${_fmt(g.seasonalWaterMm)} mm su; günlük ${_fmt(g.dailyWaterLitersPerPlant)} L/bitki referans değer. ${g.droughtTolerant ? "Kuraklığa görece dayanıklı olsa da" : "Kuraklığa hassas olduğundan"} kritik dönemlerde su stresinden kaçınılmalıdır.',
        sources: g.sourceRefs,
      ),
      CropRecommendation(
        id: '${g.id}.besleme',
        cropId: g.id,
        cropName: g.cropName,
        category: TavsiyeKategori.besleme,
        title: 'Gübreleme / besleme',
        action: g.fertilizerSummary,
        reason:
            'Önce toprak analizi yaptırın; analiz olmadan kesin doz önerisi vermeyiz. ${g.fertilizerType} yaklaşımı bu üründe önerilen genel yapıdır.',
        sources: g.sourceRefs,
      ),
      CropRecommendation(
        id: '${g.id}.koruma',
        cropId: g.id,
        cropName: g.cropName,
        category: TavsiyeKategori.koruma,
        title: firstPest != null
            ? '${firstPest.name} için entegre izleme'
            : 'Entegre zararlı/hastalık izleme',
        action: firstPest != null
            ? '${firstPest.integratedControl} İzleme: ${firstPest.monitoring}'
            : g.integratedPestManagementNote,
        reason: firstPest?.economicThreshold != null
            ? 'Ekonomik eşik: ${firstPest!.economicThreshold}. Eşik aşılmadan kimyasal mücadeleye başlanmaz; teşhis için il/ilçe müdürlüğü teknik desteği önerilir.'
            : 'Kimyasal mücadele yalnızca eşik aşıldığında, etiket dozu ve resmi teknik öneriyle yapılmalıdır.',
        sources: g.sourceRefs,
        requiresBkuCheck: true,
        requiresExpertConfirmation: true,
      ),
      CropRecommendation(
        id: '${g.id}.hasat',
        cropId: g.id,
        cropName: g.cropName,
        category: TavsiyeKategori.hasat,
        title: 'Hasat ve kalite',
        action: g.harvestQualityNotes,
        reason:
            'Hasat aralığı: ${g.harvestWindow}. ${g.yieldExpectation}. Zamanından önce veya çok geç hasat kalite ve verim kaybı yaratır.',
        sources: g.sourceRefs,
      ),
      CropRecommendation(
        id: '${g.id}.munavebe',
        cropId: g.id,
        cropName: g.cropName,
        category: TavsiyeKategori.munavebe,
        title: 'Ekim nöbeti / münavebe',
        action: g.rotationNotes,
        reason:
            'Aynı parsele üst üste aynı ürün ekmek toprak kaynaklı hastalık, zararlı ve yabancı ot baskısını artırır.',
        sources: g.sourceRefs,
      ),
      CropRecommendation(
        id: '${g.id}.bolge',
        cropId: g.id,
        cropName: g.cropName,
        category: TavsiyeKategori.bolge,
        title: 'Bölgesel uygunluk notu',
        action: g.regionNote,
        reason:
            'İdeal sıcaklık ${_fmt(g.idealTempMin)}-${_fmt(g.idealTempMax)} °C, ideal pH ${_fmt(g.idealPhMin)}-${_fmt(g.idealPhMax)}.',
        sources: g.sourceRefs,
      ),
      CropRecommendation(
        id: '${g.id}.bku',
        cropId: g.id,
        cropName: g.cropName,
        category: TavsiyeKategori.bku,
        title: 'Bitki Koruma Ürünü güvenlik kontrolü',
        action:
            'Kimyasal mücadele gerekirse: önce kesin teşhis ve eşik doğrulaması yapın. Sonra bku.tarim.gov.tr üzerinden bu ürün-hastalık çifti için güncel ruhsatlı aktif madde, etiket dozu ve hasada bekleme süresini (PHI) doğrulayın. Tarlam belirli bir ticari ürün önermez.',
        reason:
            'Ruhsat durumu, doz ve PHI değerleri zamanla değişebildiği için tek otorite resmi BKÜ veritabanıdır. Çocuk, hayvan, su kaynağı ve kullanıcı sağlığı için koruyucu ekipman zorunludur.',
        sources: const [
          'Tarım ve Orman Bakanlığı BKÜ Veritabanı (bku.tarim.gov.tr)',
        ],
        requiresBkuCheck: true,
        requiresExpertConfirmation: true,
      ),
    ];
  }

  /// 5 öncelikli ürün için tüm tavsiyeler tek liste halinde.
  static List<CropRecommendation> allRecommendations() {
    return [
      for (final g in priorityGuides()) ...recommendationsFor(g),
    ];
  }

  /// Bir ürünün öne çıkan ilk 4 tavsiyesi (Ekim, Sulama, Besleme, Koruma).
  /// Detay rehberin üst kısmında özet olarak gösterilir.
  static List<CropRecommendation> highlightsFor(TurkiyeCropGuide g) {
    final all = recommendationsFor(g);
    return all
        .where((r) =>
            r.category == TavsiyeKategori.ekim ||
            r.category == TavsiyeKategori.sulama ||
            r.category == TavsiyeKategori.besleme ||
            r.category == TavsiyeKategori.koruma)
        .toList();
  }

  static String _fmt(double value) => value == value.roundToDouble()
      ? value.toStringAsFixed(0)
      : value.toStringAsFixed(1);
}
