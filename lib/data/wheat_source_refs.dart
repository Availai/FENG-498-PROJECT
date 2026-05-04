/// Buğday kuralları için merkezi kaynak listesi.
///
/// Tutum: kaynak metinleri uzun ve yarı-formaldır; UI kısa rozet gösterir,
/// aktivite metadata'sına tam metin gider. Linkler **kurum kök sayfasına**
/// bırakılmıştır (alt-sayfa adresi sürüm değiştirebilir); çiftçi orada
/// arama kutusuyla doğrulayabilir.
class WheatSources {
  WheatSources._();

  static const tagemTechnicalSpec =
      'TAGEM Tarla Bitkileri Araştırma Daire Başkanlığı, Buğday Tarımı Teknik Talimatı; ekim normu, gübreleme, sulama ve hasat kriterleri, https://www.tarimorman.gov.tr/TAGEM';

  static const bahriDagdas =
      'Bahri Dağdaş Uluslararası Tarımsal Araştırma Enstitüsü Müdürlüğü, Buğday Yetiştiriciliği rehberleri; çeşit seçimi, kardeşlenme dönemi azot uygulaması, hastalık-zararlı izlemesi, https://arastirma.tarimorman.gov.tr/bahridagdas';

  static const trakyaWheatGuide =
      'Trakya Tarımsal Araştırma Enstitüsü, Buğday Yetiştiriciliği teknik yayınları; sapa kalkma–başaklanma sulaması ve pas hastalıkları izlemesi, https://arastirma.tarimorman.gov.tr/ttae';

  static const tagemIpm =
      'TAGEM Bitki Sağlığı Araştırmaları Daire Başkanlığı, Buğday Entegre Mücadele Teknik Talimatı; süne, kımıl, pas (sarı/kahverengi/kara) hastalıkları için ekonomik eşik ve izleme yöntemleri';

  static const bkuDatabase =
      'T.C. Tarım ve Orman Bakanlığı Bitki Koruma Ürünleri Veri Tabanı (BKÜ); ruhsatlı ürün, etiket dozu ve son ilaçlama-hasat arası süre kontrolü, https://bku.tarimorman.gov.tr/';

  static const fao56 =
      'FAO Irrigation and Drainage Paper 56, Crop Evapotranspiration, 1998; ET0/Kc yaklaşımı ve buğday bitki katsayıları, https://www.fao.org/4/X0490E/X0490E00.htm';
}

class WheatRuleSourceRefs {
  WheatRuleSourceRefs._();

  static const emergence = [
    WheatSources.tagemTechnicalSpec,
    WheatSources.bahriDagdas,
  ];

  static const tilleringNitrogen = [
    WheatSources.tagemTechnicalSpec,
    WheatSources.bahriDagdas,
    WheatSources.trakyaWheatGuide,
  ];

  static const stemElongationWater = [
    WheatSources.fao56,
    WheatSources.trakyaWheatGuide,
    WheatSources.tagemTechnicalSpec,
  ];

  static const rustScouting = [
    WheatSources.tagemIpm,
    WheatSources.trakyaWheatGuide,
    WheatSources.bkuDatabase,
  ];

  static const harvestReady = [
    WheatSources.tagemTechnicalSpec,
    WheatSources.bahriDagdas,
  ];
}
