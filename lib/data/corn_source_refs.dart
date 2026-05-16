/// Mısır (Zea mays) kuralları için merkezi kaynak listesi.
///
/// CLAUDE.md sec 10 öncelik sırası — resmi kaynaklar:
///   1. T.C. Tarım ve Orman Bakanlığı / TAGEM
///   2. GAP Tarımsal Araştırma Enstitüsü (Şanlıurfa)
///   3. Mısır Araştırma Enstitüsü Müdürlüğü (Sakarya)
///   4. TEPGE / TZOB
class CornSources {
  CornSources._();

  static const tagemAgronomy =
      'T.C. Tarım ve Orman Bakanlığı/TAGEM, Mısır Tarımı Teknik Talimatı; ekim aralığı, pH, NPK, sulama ve hasat günü teknik değerleri';

  static const tagemCornIpm =
      'T.C. Tarım ve Orman Bakanlığı/TAGEM Bitki Sağlığı Araştırmaları Daire Başkanlığı, Mısır Entegre Mücadele Teknik Talimatı; koçan kurdu, mısır kurdu izleme ve ekonomik eşik';

  static const gapResearchCorn =
      'GAP Tarımsal Araştırma Enstitüsü Müdürlüğü, Şanlıurfa, Mısır Yetiştiriciliği; bölgesel sulama, II. ürün mısır, çeşit seçimi, https://arastirma.tarimorman.gov.tr/gaputaem';

  static const cornResearchSakarya =
      'Mısır Araştırma Enstitüsü Müdürlüğü, Sakarya; tane ve silajlık mısır çeşit özellikleri, ekim normu, https://arastirma.tarimorman.gov.tr/misir';

  static const tepgeCornReport =
      'TEPGE Mısır Tarım Ürünleri Piyasa Raporu; bölge dağılımı ve üretim verisi, https://arastirma.tarimorman.gov.tr/tepge';

  static const bkuDatabase =
      'T.C. Tarım ve Orman Bakanlığı Bitki Koruma Ürünleri Veri Tabanı (BKÜ); ruhsatlı ürün, etiket ve son ilaçlama-hasat arası süre kontrolü, https://bku.tarimorman.gov.tr/';

  static const fao56 =
      'FAO Irrigation and Drainage Paper 56, Crop Evapotranspiration, 1998; ET0/Kc yaklaşımı ve mısır bitki katsayıları, https://www.fao.org/4/X0490E/X0490E00.htm';
}

class CornRuleSourceRefs {
  CornRuleSourceRefs._();

  static const climateAndRegion = [
    CornSources.tagemAgronomy,
    CornSources.gapResearchCorn,
  ];

  static const sowingAndSoil = [
    CornSources.tagemAgronomy,
    CornSources.cornResearchSakarya,
  ];

  static const fertilizer = [
    CornSources.tagemAgronomy,
  ];

  static const irrigation = [
    CornSources.tagemAgronomy,
    CornSources.gapResearchCorn,
    CornSources.fao56,
  ];

  static const ipmPests = [
    CornSources.tagemCornIpm,
    CornSources.bkuDatabase,
  ];

  static const harvest = [
    CornSources.tagemAgronomy,
    CornSources.cornResearchSakarya,
  ];
}
