/// Domates (Solanum lycopersicum) kuralları için merkezi kaynak listesi.
///
/// CLAUDE.md sec 10 öncelik sırası — resmi kaynaklar:
///   1. T.C. Tarım ve Orman Bakanlığı / TAGEM
///   2. Sebze Araştırma Enstitüsü (Yalova Atatürk Bahçe Kültürleri)
///   3. Antalya Batı Akdeniz Tarımsal Araştırma Enstitüsü (BATEM)
///   4. TEPGE / TZOB
class TomatoSources {
  TomatoSources._();

  static const tagemOpenFieldIpm =
      'T.C. Tarım ve Orman Bakanlığı/TAGEM, Açık Alan Domates Entegre Mücadele Teknik Talimatı; toprak, ekim, izleme, hastalık-zararlı eşikleri';

  static const tagemGreenhouseIpm =
      'T.C. Tarım ve Orman Bakanlığı/TAGEM, Örtüaltı Domates Entegre Mücadele Teknik Talimatı; sera ortamı izleme, havalandırma, biyolojik mücadele';

  static const tagemAgronomy =
      'T.C. Tarım ve Orman Bakanlığı/TAGEM, Domates Tarımı Teknik Talimatı; ekim, çeşit, gübreleme, sulama, hasat ve depolama';

  static const yalovaResearch =
      'Atatürk Bahçe Kültürleri Merkez Araştırma Enstitüsü, Yalova; sebze yetiştiriciliği rehberleri, https://arastirma.tarimorman.gov.tr/yalovabahce';

  static const batemTomato =
      'T.C. Tarım ve Orman Bakanlığı/TAGEM-BATEM, Antalya; örtüaltı sebze yetiştiriciliği teknik kaynakları, https://arastirma.tarimorman.gov.tr/batem';

  static const tutaAbsoluta =
      'T.C. Tarım ve Orman Bakanlığı/TAGEM, Tuta absoluta (Domates güvesi) Entegre Mücadele Teknik Talimatı; feromon izleme, ekonomik eşik, biyolojik mücadele';

  static const bkuDatabase =
      'T.C. Tarım ve Orman Bakanlığı Bitki Koruma Ürünleri Veri Tabanı (BKÜ); ruhsatlı ürün, etiket ve son ilaçlama-hasat arası süre kontrolü, https://bku.tarimorman.gov.tr/';

  static const fao56 =
      'FAO Irrigation and Drainage Paper 56, Crop Evapotranspiration, 1998; ET0/Kc yaklaşımı ve domates bitki katsayıları, https://www.fao.org/4/X0490E/X0490E00.htm';
}

class TomatoRuleSourceRefs {
  TomatoRuleSourceRefs._();

  static const climateAndSystem = [
    TomatoSources.tagemAgronomy,
    TomatoSources.batemTomato,
  ];

  static const soilAndSowing = [
    TomatoSources.tagemAgronomy,
    TomatoSources.yalovaResearch,
  ];

  static const fertilizer = [
    TomatoSources.tagemAgronomy,
  ];

  static const irrigation = [
    TomatoSources.tagemAgronomy,
    TomatoSources.fao56,
  ];

  static const diseasesGreenhouse = [
    TomatoSources.tagemGreenhouseIpm,
    TomatoSources.bkuDatabase,
  ];

  static const diseasesOpenField = [
    TomatoSources.tagemOpenFieldIpm,
    TomatoSources.bkuDatabase,
  ];

  static const tutaAbsoluta = [
    TomatoSources.tutaAbsoluta,
    TomatoSources.bkuDatabase,
  ];

  static const harvest = [
    TomatoSources.tagemAgronomy,
  ];
}
