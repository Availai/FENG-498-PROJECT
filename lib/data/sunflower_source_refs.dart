/// Ayçiçeği kuralları ve rehberleri için merkezi kaynak listesi.
///
/// Kaynak metinleri kasıtlı olarak uzun tutulur: UI kısa rozet gösterir,
/// aktivite kaydında ise hangi kuralın hangi resmi/teknik dayanakla
/// üretildiği izlenebilir kalır.
class SunflowerSources {
  SunflowerSources._();

  static const tagemTechnicalSpec =
      'TAGEM Ayçiçeği Tarımı Teknik Talimatı, 2019; ekim aralığı, pH, NPK, su ve hasat günü teknik değerleri';

  static const tagemIpm2022 =
      'TAGEM Bitki Sağlığı Araştırmaları Daire Başkanlığı, Ayçiçeği Entegre Mücadele Teknik Talimatı, 2022; izleme, ekonomik eşik ve entegre mücadele kapıları';

  static const bkuDatabase =
      'T.C. Tarım ve Orman Bakanlığı Bitki Koruma Ürünleri Veri Tabanı (BKÜ); ruhsatlı ürün, etiket ve son ilaçlama-hasat arası süre kontrolü, https://bku.tarimorman.gov.tr/';

  static const trakyaYalcinKaya =
      'Trakya Tarımsal Araştırma Enstitüsü, Doç. Dr. Yalçın Kaya, "Ayçiçeği Tarımı"; iklim-toprak, gübreleme, sulama, hastalık-zararlı, hasat ve depolama, https://arastirma.tarimorman.gov.tr/ttae/Sayfalar/Detay.aspx?SayfaId=54';

  static const trakyaSamiSuzer =
      'Trakya Tarımsal Araştırma Enstitüsü, Dr. Sami Süzer, "Ayçiçeği Tarımı"; toprak hazırlığı, gübreleme, sulama, ekim nöbeti, hasat nemi, https://arastirma.tarimorman.gov.tr/ttae/Sayfalar/Detay.aspx?SayfaId=49';

  static const meadowMothInstruction =
      'T.C. Tarım ve Orman Bakanlığı/TAGEM, "Ayçiçeğinde Çayır Tırtılı Zirai Mücadele Teknik Talimatı", 24.07.2022; metrekarede 10 larva eşiği ve kültürel önlemler, https://www.tarimorman.gov.tr/Haber/5311/Tarim-Ve-Orman-Bakanligindan-Cayir-Tirtiliyla-Mucadele-Talimati';

  static const fao56 =
      'FAO Irrigation and Drainage Paper 56, Crop Evapotranspiration, 1998; ET0/Kc yaklaşımı ve ayçiçeği bitki katsayıları, https://www.fao.org/4/X0490E/X0490E00.htm';
}

class SunflowerRuleSourceRefs {
  SunflowerRuleSourceRefs._();

  static const emergenceCrusting = [
    SunflowerSources.trakyaYalcinKaya,
    SunflowerSources.trakyaSamiSuzer,
    SunflowerSources.tagemTechnicalSpec,
  ];

  static const floweringWaterStress = [
    SunflowerSources.trakyaYalcinKaya,
    SunflowerSources.trakyaSamiSuzer,
    SunflowerSources.fao56,
  ];

  static const grainWaterStress = [
    SunflowerSources.trakyaYalcinKaya,
    SunflowerSources.trakyaSamiSuzer,
    SunflowerSources.fao56,
  ];

  static const nutrientAndPhStress = [
    SunflowerSources.trakyaYalcinKaya,
    SunflowerSources.trakyaSamiSuzer,
    SunflowerSources.tagemTechnicalSpec,
  ];

  static const diseaseScouting = [
    SunflowerSources.tagemIpm2022,
    SunflowerSources.trakyaYalcinKaya,
    SunflowerSources.bkuDatabase,
  ];

  static const pestHelicoverpa = [
    SunflowerSources.tagemIpm2022,
    SunflowerSources.bkuDatabase,
  ];

  static const harvestReady = [
    SunflowerSources.trakyaYalcinKaya,
    SunflowerSources.trakyaSamiSuzer,
    SunflowerSources.tagemTechnicalSpec,
  ];
}
