/// Portakal (Citrus sinensis) ve turunçgil kuralları için merkezi
/// kaynak listesi.
///
/// CLAUDE.md sec 10 öncelik sırası — resmi kaynaklar:
///   1. T.C. Tarım ve Orman Bakanlığı / TAGEM
///   2. Batı Akdeniz Tarımsal Araştırma Enstitüsü (BATEM)
///   3. Zirai Mücadele Merkez Araştırma Enstitüsü
///   4. TEPGE (sektör/piyasa raporları)
class OrangeSources {
  OrangeSources._();

  static const batemAgronomy =
      'T.C. Tarım ve Orman Bakanlığı/TAGEM-BATEM, "Portakal Yetiştiriciliği"; iklim, toprak, çiçeklenme, hasat dönemleri, https://arastirma.tarimorman.gov.tr/batem/Belgeler/Kutuphane/Teknik%20Bilgiler/Portakal%20Yeti%C5%9Ftiricili%C4%9Fi.pdf';

  static const batemCitrusGuide =
      'T.C. Tarım ve Orman Bakanlığı/TAGEM-BATEM, "Turunçgil Yetiştiriciliği Rehberi"; bahçe tesisi, toprak analizi (0-30/30-60/60-90 cm), drenaj ve düşük sıcaklık eşiği, https://arastirma.tarimorman.gov.tr/batem/Belgeler/Kutuphane/Teknik%20Bilgiler/Turun%C3%A7gil%20Yeti%C5%9Ftiricili%C4%9Fi.pdf';

  static const tagemCitrusIpm =
      'T.C. Tarım ve Orman Bakanlığı/TAGEM, Turunçgil Entegre Mücadele Teknik Talimatı; turunçgil zararlı ve hastalıkları izleme, ekonomik eşik, kültürel ve kimyasal mücadele kapıları';

  static const zmmaeFruitGuide =
      'T.C. Tarım ve Orman Bakanlığı Zirai Mücadele Merkez Araştırma Enstitüsü, Meyve Hastalıkları ve Zararlıları Rehberi; turunçgil zararlıları listesi, https://arastirma.tarimorman.gov.tr/zmmae/Sayfalar/Detay.aspx?SayfaId=34';

  static const batemFidanTanitim =
      'T.C. Tarım ve Orman Bakanlığı/TAGEM-BATEM, Fidan Tanıtım Kataloğu (Washington Navel, Batem Fatihi vb.); aşılı fidan özellikleri ve verim profilleri, https://arastirma.tarimorman.gov.tr/batem/belgeler/fidan_tanitim.pdf';

  static const tepgePortakal =
      'TEPGE Portakal Tarım Ürünleri Piyasa Raporu, 2021; bölge dağılımı, üretim ve fiyat dinamikleri, https://arastirma.tarimorman.gov.tr/tepge';

  static const bkuDatabase =
      'T.C. Tarım ve Orman Bakanlığı Bitki Koruma Ürünleri Veri Tabanı (BKÜ); ruhsatlı ürün, etiket ve son ilaçlama-hasat arası süre kontrolü, https://bku.tarimorman.gov.tr/';

  static const fao56 =
      'FAO Irrigation and Drainage Paper 56, Crop Evapotranspiration, 1998; ET0/Kc yaklaşımı ve turunçgil bitki katsayıları, https://www.fao.org/4/X0490E/X0490E00.htm';
}

class OrangeRuleSourceRefs {
  OrangeRuleSourceRefs._();

  static const climateAndRegion = [
    OrangeSources.batemAgronomy,
    OrangeSources.batemCitrusGuide,
  ];

  static const phAndSoil = [
    OrangeSources.batemCitrusGuide,
    OrangeSources.batemAgronomy,
  ];

  static const fertilizer = [
    OrangeSources.batemCitrusGuide,
    OrangeSources.batemAgronomy,
  ];

  static const irrigation = [
    OrangeSources.batemAgronomy,
    OrangeSources.fao56,
  ];

  static const harvest = [
    OrangeSources.batemAgronomy,
    OrangeSources.tepgePortakal,
  ];

  static const frostAndHeat = [
    OrangeSources.batemAgronomy,
    OrangeSources.batemCitrusGuide,
  ];

  static const ipmPests = [
    OrangeSources.tagemCitrusIpm,
    OrangeSources.zmmaeFruitGuide,
    OrangeSources.bkuDatabase,
  ];
}
