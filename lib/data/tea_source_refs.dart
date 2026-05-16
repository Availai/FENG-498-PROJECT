/// Çay (Camellia sinensis) kuralları için merkezi kaynak listesi.
///
/// CLAUDE.md sec 10 öncelik sırası — resmi kaynaklar:
///   1. Çay-Kur (kamu iktisadi teşekkül)
///   2. T.C. Tarım ve Orman Bakanlığı Rize/Trabzon İl Müdürlükleri
///   3. Recep Tayyip Erdoğan Üniversitesi Çay İhtisas Merkezi
///   4. Atatürk Çay ve Bahçe Kültürleri Araştırma Enstitüsü
class TeaSources {
  TeaSources._();

  static const caykurAgronomy =
      'ÇAYKUR Tarım Kısım Müdürlüğü Ders Notları, 2025; çay yetiştiriciliği, toprak hazırlığı, hasat tekniği, https://caykur.gov.tr/uploads/8.tarim_kisim_mudurlugu_ders_notlari.pdf';

  static const caykurSectorReport =
      'ÇAYKUR 2015 Çay Sektörü Raporu; üretim bölgeleri, hasat dönemleri, ekonomik ömür, https://www.caykur.gov.tr/CMS/Design/Sources/Dosya/Yayinlar/104.pdf';

  static const caykurFertilizer =
      'ÇAYKUR İstatistik Bülteni, 2017; 25-5-10 azot ağırlıklı çay gübresi kullanımı ve dozu, https://www.caykur.gov.tr/CMS/Design/Sources/Dosya/Yayinlar/281.pdf';

  static const rizeTarimDolomit =
      'T.C. Tarım ve Orman Bakanlığı Rize İl Müdürlüğü; çayda dolomit kalsiyum granül oksit ile pH düzeltme uygulaması, hedef pH 5.0-5.5, https://rize.tarimorman.gov.tr/Haber/650/Cayda-Dolomit-Kalsiyum-Granul-Oksit-Formunda-Tarim-Kireci-Uygulanmasi-Yerinde-Incelendi';

  static const rteuTeaHarvest =
      'Recep Tayyip Erdoğan Üniversitesi Çay İhtisas Merkezi, Çay Hasadı Broşürü; tepe tomurcuğu + iki körpe yaprak hasat standardı, 3 sürgün dönemi, https://cayihtisas.erdogan.edu.tr/Files/ckFiles/cayihtisas-erdogan-edu-tr/%C3%87ay%20Hasad%C4%B1%20Bro%C5%9F%C3%BCr%C3%BC%20%C4%B0kili%20Sayfa.pdf';

  static const ataturkTeaResearch =
      'Atatürk Çay ve Bahçe Kültürleri Araştırma Enstitüsü Müdürlüğü; çayda iklim, toprak ve verim araştırmaları, https://www.caykur.gov.tr/Arge/Pages/Hakkimizda.aspx?ParentId=56';

  static const bkuDatabase =
      'T.C. Tarım ve Orman Bakanlığı Bitki Koruma Ürünleri Veri Tabanı (BKÜ); ruhsatlı ürün, etiket ve son ilaçlama-hasat arası süre kontrolü, https://bku.tarimorman.gov.tr/';
}

class TeaRuleSourceRefs {
  TeaRuleSourceRefs._();

  static const climateAndRegion = [
    TeaSources.caykurAgronomy,
    TeaSources.caykurSectorReport,
  ];

  static const phAndSoil = [
    TeaSources.rizeTarimDolomit,
    TeaSources.caykurAgronomy,
  ];

  static const fertilizer = [
    TeaSources.caykurFertilizer,
    TeaSources.caykurAgronomy,
  ];

  static const harvestProtocol = [
    TeaSources.rteuTeaHarvest,
    TeaSources.caykurAgronomy,
  ];

  static const pestAndDiseaseLight = [
    TeaSources.caykurAgronomy,
    TeaSources.bkuDatabase,
  ];

  static const pruning = [
    TeaSources.caykurAgronomy,
    TeaSources.ataturkTeaResearch,
  ];
}
