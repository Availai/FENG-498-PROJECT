/// Türkiye'de yaygın bitki hastalıkları için yapılandırılmış tavsiye veritabanı.
///
/// Kaynaklar (Türkiye'nin en güvenilir kuruluşları):
///  • T.C. Tarım ve Orman Bakanlığı — Bitki Sağlığı Araştırmaları Daire Başkanlığı
///  • TAGEM (Tarımsal Araştırmalar ve Politikalar Genel Müdürlüğü) Bitki
///    Koruma Bültenleri
///  • Zirai Mücadele Teknik Talimatları (Resmî Gazete'de yayımlanan)
///  • Ankara, Çukurova, Ege Üniversiteleri Ziraat Fakültesi Bitki Koruma
///    Bölümleri
///
/// Tüm aktif madde ve dozlar **Bitki Koruma Ürünleri Veri Tabanı**
/// (bku.tarim.gov.tr) ile uyumlu olarak listelenmiştir. Çiftçi mutlaka
/// satın aldığı ürünün etiketini okumalı ve son ruhsat durumunu
/// bku.tarim.gov.tr üzerinden teyit etmelidir.
library;

class DiseaseAdvice {
  const DiseaseAdvice({
    required this.name,
    required this.pathogenType,
    required this.contagious,
    required this.urgency,
    required this.symptoms,
    required this.spreadMechanism,
    required this.isolationSteps,
    required this.organicTreatments,
    required this.chemicalTreatments,
    required this.preventionTips,
    required this.deadPlantProtocol,
    required this.sources,
  });

  /// Hastalık adı (Türkçe).
  final String name;

  /// Patojen türü: 'Mantar', 'Bakteri', 'Virüs', 'Fizyolojik'.
  final String pathogenType;

  /// Bulaşıcı mı? (Komşu bitkilere yayılma riski.)
  final bool contagious;

  /// Müdahale aciliyeti: 'Düşük', 'Orta', 'Yüksek', 'Çok Yüksek'.
  final String urgency;

  /// Tipik belirtiler — çiftçinin teşhisi doğrulamasına yardım.
  final List<String> symptoms;

  /// Yayılma mekanizması — neden, nasıl yayılır.
  final String spreadMechanism;

  /// Bulaşıcı hastalıklarda hemen yapılacak izolasyon adımları.
  final List<String> isolationSteps;

  /// Organik / kültürel mücadele önerileri.
  final List<String> organicTreatments;

  /// Kimyasal mücadele — aktif madde + uygulama notu.
  /// Format: "Aktif madde — uygulama açıklaması".
  final List<String> chemicalTreatments;

  /// Tekrarlamayı önleme — kültürel önlemler.
  final List<String> preventionTips;

  /// Bitki ölmüşse: etrafa zarar vermeden koparma/imha protokolü.
  final List<String> deadPlantProtocol;

  /// Kaynak/referans listesi.
  final List<String> sources;

  /// Bilinen hastalık kataloğu — Tarım Bakanlığı Zirai Mücadele Teknik
  /// Talimatları'na göre Türkiye'de en sık karşılaşılan hastalıklar.
  static const Map<String, DiseaseAdvice> catalog = {
    'Yaprak Lekesi': _yaprakLekesi,
    'Mildiyö': _mildiyo,
    'Külleme': _kulleme,
    'Pas': _pas,
    'Mozaik Virüs': _mozaikVirus,
    'Bakteriyel Yanıklık': _bakteriyelYaniklik,
    'Kök Çürüklüğü': _kokCurukluk,
    'Antraknoz': _antraknoz,
    'Kurşuni Küf': _kursuniKuf,
    'Erken Yaprak Yanıklığı': _erkenYaniklik,
    'Fusarium Solgunluğu': _fusariumSolgunlugu,
    'Monilya': _monilya,
    'Ateş Yanıklığı': _atesYaniklik,
    'Cercospora Yaprak Lekesi': _cercospora,
    'Bilinmiyor': _bilinmeyen,
  };

  /// Hastalık adı takma adları — V2 trust veritabanından gelen alternatif
  /// isimler ana kataloğun anahtarına eşlenir. Anahtar küçük harf normalize
  /// edilmiş arama kelimesi, değer katalog anahtarıdır.
  static const Map<String, String> _aliases = {
    // Botrytis / Kurşuni küf
    'botrytis': 'Kurşuni Küf',
    'gri küf': 'Kurşuni Küf',
    'kursuni kuf': 'Kurşuni Küf',
    'kurşuni küf': 'Kurşuni Küf',
    // Alternaria / Erken yanıklık
    'alternaria': 'Erken Yaprak Yanıklığı',
    'erken yanıklık': 'Erken Yaprak Yanıklığı',
    'erken yaniklik': 'Erken Yaprak Yanıklığı',
    'alternaria yaprak lekesi': 'Erken Yaprak Yanıklığı',
    'alternaria yaprak yanıklığı': 'Erken Yaprak Yanıklığı',
    // Phytophthora / geç yanıklık → mildiyö ailesi
    'fitoftora': 'Mildiyö',
    'phytophthora': 'Mildiyö',
    'geç yanıklık': 'Mildiyö',
    'gec yaniklik': 'Mildiyö',
    'peronospora': 'Mildiyö',
    'mavi küf': 'Mildiyö',
    // Fusarium
    'fusarium': 'Fusarium Solgunluğu',
    'fusarium solgunluk': 'Fusarium Solgunluğu',
    'fusarium solgunluğu': 'Fusarium Solgunluğu',
    // Monilia
    'monilia': 'Monilya',
    'monilya': 'Monilya',
    'mumya hastalığı': 'Monilya',
    'meyve çürüklüğü': 'Monilya',
    // Ateş yanıklığı / Erwinia
    'ateş yanıklığı': 'Ateş Yanıklığı',
    'ates yanikligi': 'Ateş Yanıklığı',
    'erwinia': 'Ateş Yanıklığı',
    // Cercospora
    'cercospora': 'Cercospora Yaprak Lekesi',
    'cercospora yaprak lekesi': 'Cercospora Yaprak Lekesi',
    // Pas varyantları
    'sarı pas': 'Pas',
    'kahverengi pas': 'Pas',
    'kara pas': 'Pas',
    'mısır pası': 'Pas',
    // Bakteriyel grubu
    'bakteriyel kanser': 'Bakteriyel Yanıklık',
    'bakteriyel leke': 'Bakteriyel Yanıklık',
    'bakteriyel solgunluk': 'Bakteriyel Yanıklık',
    // Kök çürüklüğü varyantları
    'kök ve gövde çürüklüğü': 'Kök Çürüklüğü',
    'kök ve kökboğazı çürüklüğü': 'Kök Çürüklüğü',
    'kök çürüklüğü (phytophthora)': 'Kök Çürüklüğü',
    'kok curuklugu': 'Kök Çürüklüğü',
    // Virüs grubu
    'mozaik': 'Mozaik Virüs',
    'mozaik virüs': 'Mozaik Virüs',
    'dut mozaiği': 'Mozaik Virüs',
    'incir mozaiği': 'Mozaik Virüs',
    // Külleme varyantları (Türkçe karakter normalize)
    'kulleme': 'Külleme',
    // Sclerotinia / Beyaz çürüklük
    'sclerotinia': 'Kök Çürüklüğü',
    'beyaz çürüklük': 'Kök Çürüklüğü',
    'beyaz curukluk': 'Kök Çürüklüğü',
    // Ayçiçeği / mısır spesifik
    'mısır rastığı': 'Bilinmiyor',
    'misir rastigi': 'Bilinmiyor',
    'başak rastığı': 'Bilinmiyor',
    'basak rastigi': 'Bilinmiyor',
    'kuzey yaprak yanıklığı': 'Erken Yaprak Yanıklığı',
    'kuzey yaprak yanikligi': 'Erken Yaprak Yanıklığı',
    'gri yaprak lekesi': 'Cercospora Yaprak Lekesi',
    // Turunçgil spesifik — kabuk lekesi, yağ lekesi, uçkurutan, zamklanma
    'uçkurutan': 'Bakteriyel Yanıklık',
    'uckurutan': 'Bakteriyel Yanıklık',
    'kabuk lekesi': 'Antraknoz',
    'skab': 'Antraknoz',
    'yağ lekesi': 'Cercospora Yaprak Lekesi',
    'yag lekesi': 'Cercospora Yaprak Lekesi',
    'zamklanma': 'Kök Çürüklüğü',
    'kahverengi çürüklük': 'Kök Çürüklüğü',
    'kahverengi curukluk': 'Kök Çürüklüğü',
    // Çay spesifik
    'sürgün kuruması': 'Bakteriyel Yanıklık',
    'surgun kurumasi': 'Bakteriyel Yanıklık',
    'dal geriye kuruması': 'Bakteriyel Yanıklık',
    'dal geriye kurumasi': 'Bakteriyel Yanıklık',
    'tomurcuk çürüklüğü': 'Kurşuni Küf',
    'tomurcuk curuklugu': 'Kurşuni Küf',
  };

  /// Hastalık adına göre tavsiye getirir; eşleşme yoksa "Bilinmiyor"
  /// için olan jenerik korumacı protokol döner.
  ///
  /// Eşleştirme sırası:
  ///   1. Tam katalog anahtarı eşleşmesi
  ///   2. Takma ad sözlüğü (botrytis, alternaria, fusarium vb.)
  ///   3. Alt string aranması (her iki yönde — katalog anahtarı arama
  ///      metninde, veya arama metni katalog anahtarında geçiyor mu)
  ///   4. Türkçe karakter normalize ederek alt string araması
  static DiseaseAdvice forName(String? name) {
    if (name == null || name.trim().isEmpty) return _bilinmeyen;
    final trimmed = name.trim();
    // 1) Tam eşleşme
    final hit = catalog[trimmed];
    if (hit != null) return hit;

    final lower = trimmed.toLowerCase();
    final normalized = _normalizeTr(lower);

    // 2) Takma ad sözlüğü — tam veya alt string
    if (_aliases.containsKey(lower)) {
      final mapped = _aliases[lower]!;
      final adv = catalog[mapped];
      if (adv != null) return adv;
    }
    for (final entry in _aliases.entries) {
      if (lower.contains(entry.key) ||
          normalized.contains(_normalizeTr(entry.key))) {
        final adv = catalog[entry.value];
        if (adv != null) return adv;
      }
    }

    // 3) Esnek alt string — her iki yön (kullanıcı kısaltma yazmış olabilir)
    for (final entry in catalog.entries) {
      final keyLower = entry.key.toLowerCase();
      if (lower.contains(keyLower) || keyLower.contains(lower)) {
        return entry.value;
      }
    }

    // 4) Normalize edilmiş alt string (ş→s, ğ→g, ı→i, ü→u, ö→o, ç→c)
    for (final entry in catalog.entries) {
      final keyNorm = _normalizeTr(entry.key.toLowerCase());
      if (normalized.contains(keyNorm) || keyNorm.contains(normalized)) {
        return entry.value;
      }
    }

    return _bilinmeyen;
  }

  static String _normalizeTr(String s) => s
      .replaceAll('ı', 'i')
      .replaceAll('İ', 'i')
      .replaceAll('ğ', 'g')
      .replaceAll('Ğ', 'g')
      .replaceAll('ü', 'u')
      .replaceAll('Ü', 'u')
      .replaceAll('ş', 's')
      .replaceAll('Ş', 's')
      .replaceAll('ö', 'o')
      .replaceAll('Ö', 'o')
      .replaceAll('ç', 'c')
      .replaceAll('Ç', 'c');

  /// Ölü bitki için patojen-spesifik koparma protokolü. Hastalık türü
  /// belirtilmemişse temel "güvenli kaldırma" rehberi döner.
  static List<String> deadRemovalFor(String? diseaseName) {
    final advice = forName(diseaseName);
    return advice.deadPlantProtocol;
  }
}

// ─────────────────────────────────────────────────────────────────────
// Hastalık tanımları — Tarım Bakanlığı bültenlerinden derlendi
// ─────────────────────────────────────────────────────────────────────

const _yaprakLekesi = DiseaseAdvice(
  name: 'Yaprak Lekesi',
  pathogenType: 'Mantar',
  contagious: true,
  urgency: 'Orta',
  symptoms: [
    'Yapraklarda kahverengi/siyah, sınırları belirgin yuvarlak lekeler',
    'Lekelerin merkezi açık, kenarı koyu (göz şeklinde)',
    'İleri evrede yaprak sararıp dökülür',
  ],
  spreadMechanism:
      'Mantar sporları rüzgâr, yağmur sıçraması ve aletlerle yayılır. '
      'Nemli ve 18–24 °C hava, hastalığın patlak vermesi için ideal koşuldur.',
  isolationSteps: [
    'Hasta yaprakları sabah çiy kalkmadan eldivenle koparın — sporlar ıslakken çevreye saçılmaz',
    'Komşu sağlıklı bitkilere dokunmadan önce ellerinizi ve makasınızı %70 alkol veya 1/9 çamaşır suyu çözeltisiyle silin',
    'Hasta yaprakları kompostlamayın; çift kat poşete koyup yakarak ya da çöple bertaraf edin',
    'Bulaşık parselde sulamayı damla sulamaya çevirin — yağmurlama yaprakları ıslatıp yayılımı hızlandırır',
  ],
  organicTreatments: [
    'Bordo bulamacı (%1) — 7–10 gün arayla 2–3 uygulama, sabah erken saatte',
    'Bakır oksiklorür içerikli organik onaylı ürünler (etikete uygun doz)',
    'Süt-su karışımı (1:9) — koruyucu, hafif enfeksiyonda haftada bir',
    'Mahsul artıklarını topladıktan sonra parseli en az 8 cm derinden sürün',
  ],
  chemicalTreatments: [
    'Mancozeb (%80 WP) — 250 g / 100 L su, koruyucu olarak 10 gün arayla',
    'Klorotalonil — etiket dozunda, hasattan en az 14 gün önce kesilir',
    'Azoksistrobin + Difenokonazol — sistemik etki, dirençli ırklarda etkin',
    'NOT: Aktif madde ruhsat durumunu mutlaka bku.tarim.gov.tr üzerinden doğrulayın',
  ],
  preventionTips: [
    'Sertifikalı, sağlıklı tohum/fide kullanın',
    'Sıra arasını dar tutmayın — hava sirkülasyonu sporları kurutur',
    'Aynı tarlaya 2–3 yıl üst üste aynı familyadan bitki ekmeyin (rotasyon)',
    'Hasat sonrası bitki artıklarını tarladan kaldırın, kışı yapraklarda geçirmesin',
  ],
  deadPlantProtocol: [
    'Bitkiyi kökü ile birlikte sökün — kök bölgesinde sporlar kalmasın',
    'Sökerken 30 cm çevresine dokunmayın; gerekirse o alanı işaretleyip 2 hafta gözleyin',
    'Sökülen bitkiyi naylon poşete koyup ağzını sıkıca kapatın, kompostlamayın',
    'Çıkarıldığı yerdeki toprağı 5 cm derinlikten alın, parsel dışına atın ya da yakın',
    'Kullanılan eldiven, makas, kürek %70 alkol veya çamaşır suyu (1/9) ile dezenfekte edilmeli',
  ],
  sources: [
    'TAGEM — Bitki Hastalıkları Standart İlaç Deneme Metotları',
    'Tarım ve Orman Bakanlığı — Zirai Mücadele Teknik Talimatları',
    'bku.tarim.gov.tr — Bitki Koruma Ürünleri Veri Tabanı',
  ],
);

const _mildiyo = DiseaseAdvice(
  name: 'Mildiyö',
  pathogenType: 'Mantar',
  contagious: true,
  urgency: 'Çok Yüksek',
  symptoms: [
    'Yaprağın üstünde sarı-yeşil, yağ damlası gibi şeffaf lekeler',
    'Yaprağın altında griye çalan, kül rengi tüy benzeri kaplama (sporlar)',
    'Hızla kuruyup kahverengileşen yaprak dokusu',
    'Asma, domates, patates ve soğanda yaygın; nemli/serin havayı sever',
  ],
  spreadMechanism:
      'Sporlar nemli havada (>%85 nem, 15–22 °C) saatler içinde patlama '
      'yapar. Rüzgârla kilometrelerce taşınır; yaprak ıslaklığı 4 saati '
      'aştığında enfeksiyon kesinleşir.',
  isolationSteps: [
    'TEHLİKE: Mildiyö 2–3 günde tüm tarlayı sarabilir — gecikmeyin',
    'Hasta bitkileri en az 1 metre çevresiyle birlikte işaretleyin',
    'Sulamayı derhal damla sulamaya çevirin, yağmurlamayı durdurun',
    'Hasta yaprakları kuru havada koparın, hemen poşetleyip uzaklaştırın',
    'Sera ise havalandırmayı azamiye çıkarın, nemi %70 altına düşürün',
  ],
  organicTreatments: [
    'Bordo bulamacı (%1–1.5) — koruyucu, ilk belirtide derhal',
    'Bakır hidroksit veya bakır oksiklorür — organik üretimde tek seçenek',
    'Yaprakları sabah erken sulayın ki gece kuru kalsın',
  ],
  chemicalTreatments: [
    'Metalaksil-M + Mancozeb — sistemik+koruyucu, 7 gün arayla 2 uygulama',
    'Fosetyl-Al — sistemik, kök bölgesinden de etkin',
    'Siyazofamid veya Mandipropamid — yeni nesil, dirençli ırklara etkili',
    'Dimetomorf — özellikle bağda mildiyöye karşı tercih edilir',
    'NOT: Aynı aktif maddeyi üst üste kullanmayın — direnç gelişir',
  ],
  preventionTips: [
    'Dayanıklı çeşit seçin (örn. Domateste mildiyöye toleranslı F1 hibritler)',
    'Sıra yönünü hâkim rüzgâra paralel yapın — yapraklar daha çabuk kurur',
    'Sulamayı sabah 06–10 arası yapın, akşam ıslak yaprak bırakmayın',
    "Hava nem ve sıcaklığını izleyin — MGM'nin 5 günlük tahmini ile koruyucu ilaçlama planlayın",
  ],
  deadPlantProtocol: [
    'Bitkiyi gövdesinden değil, toprak hizasından kesin — kök kalsın yayılma azalır',
    'Hasta dokuları kuru havada toplayın; nemli havada sporlar dağılır',
    'Çift kat siyah poşete alıp güneşte 2 gün bekletin (solarizasyon ile sporlar ölür)',
    'Sonra çöpe atın, ASLA kompost yapmayın',
    'Aynı parsele 3 yıl boyunca aynı familyadan bitki ekmeyin',
    'Sökme aletlerini bakırlı dezenfektan veya %70 alkolle silin',
  ],
  sources: [
    'TAGEM — Bağ, Domates, Patates Hastalıkları Mücadele Talimatları',
    'Tarım Bakanlığı — Mildiyö Erken Uyarı Sistemi (bazı illerde aktif)',
    'bku.tarim.gov.tr — Aktif madde ruhsat sorgulama',
  ],
);

const _kulleme = DiseaseAdvice(
  name: 'Külleme',
  pathogenType: 'Mantar',
  contagious: true,
  urgency: 'Orta',
  symptoms: [
    'Yaprak, sap ve meyvelerde un serpilmiş gibi beyaz toz tabaka',
    'İleri evrede yapraklar kıvrılır, sararır, dökülür',
    'Meyvelerde çatlama ve şekil bozulması',
    'Bağ, kabakgil, gül ve buğdayda çok yaygın',
  ],
  spreadMechanism:
      'Sporlar kuru ve sıcak havada (20–28 °C, %40–70 nem) hızla yayılır. '
      'Mildiyönün aksine yaprak ıslaklığı GEREKMEZ — kuru sıcak ile patlar.',
  isolationSteps: [
    'Hasta yaprakları derhal koparıp kapalı poşette bertaraf edin',
    'Bitki gölgede mi? Güneş alsın diye komşu yapraklardan budama yapın',
    'Sıra arasını seyrekleştirin (gerekirse fideleri ayıklayın)',
    'Sera ise havalandırmayı artırın, sıcak nemli noktayı dağıtın',
  ],
  organicTreatments: [
    'Toz kükürt — sabah erken yaprak altı dahil tozlama, 28 °C üstünde uygulamayın (yanıklık riski)',
    'Süt-su karışımı (1:9) — haftalık koruyucu, hafif enfeksiyonda',
    'Karbonat çözeltisi (5 g/L su + birkaç damla sıvı sabun) — pH değiştirir, mantarı baskılar',
    'Neem yağı (azadirachtin) — hem külleme hem de zararlı önler',
  ],
  chemicalTreatments: [
    'Sülfür (kükürt) WP veya WG formülasyonu — etiket dozunda, 7 gün arayla',
    'Miklobutanil — sistemik triazol, tedavi+koruma',
    'Penkonazol — bağda külleme için yaygın',
    'Tebukonazol — yeni enfeksiyonda etkili',
    'Azoksistrobin — geniş spektrumlu strobilurin (direnç dönüşümlü kullanım)',
  ],
  preventionTips: [
    'Toleranslı çeşit seçin (özellikle kabakgil ve bağda)',
    'Aşırı azotlu gübrelemeden kaçının — yumuşak doku küllemeyi davet eder',
    'Sırt rüzgârına açık parsel tercih edin',
    'Sulamayı düzenli yapın, susuz/streslenmiş bitki daha hassas',
  ],
  deadPlantProtocol: [
    'Tüm bitkiyi gövde ile birlikte sökün',
    'Kuru havada toplayın — sporlar düşük nemde uçucu, bu yüzden sabah erken çalışın',
    'Poşetleyip yakın ya da çöpe atın; kompost yapmayın',
    'Yan komşu bitkilerin yapraklarını gözden geçirin, küçük kuluçka lekeleri varsa onları da işleme alın',
    'Sökme bölgesindeki ölü yapraklarını da toplayın — mantar kışı yapraklarda geçirir',
  ],
  sources: [
    'TAGEM — Bağ, Sebze ve Tahıl Külleme Mücadele Talimatları',
    'Ankara Üniv. Ziraat Fak. Bitki Koruma Bölümü — Külleme Tanı Rehberi',
  ],
);

const _pas = DiseaseAdvice(
  name: 'Pas',
  pathogenType: 'Mantar',
  contagious: true,
  urgency: 'Yüksek',
  symptoms: [
    'Yaprak altında turuncu, kahverengi veya siyah toz benzeri püstüller',
    'Yaprak üstünde sarı-açık kahverengi noktalar',
    'Şiddetli enfeksiyonda yaprak kuruyup dökülür',
    'Buğdayda kara pas, sarı pas, kahverengi pas formları var',
  ],
  spreadMechanism:
      'Sporlar rüzgârla yüzlerce kilometre taşınabilir. Çiy ve hafif yağmur '
      '(15–22 °C) ile saatler içinde çimlenir. Buğday pasında ara konukçu '
      'çalılar hastalığı yıllarca tarlada tutar.',
  isolationSteps: [
    'Tarlayı haritalandırın — pas ocaklarının yerini işaretleyin',
    'Komşu sağlıklı bitkilere koruyucu ilaçlama yapın (etrafa yayılım hızlı)',
    'Hasta bitki artıklarını anız bozumu ile derin gömün (en az 15 cm)',
    'Aletleri parselden çıkarken bakırlı dezenfektan ile silin',
  ],
  organicTreatments: [
    'Bordo bulamacı (%1) — koruyucu, henüz püstül oluşmadığında etkili',
    'Sülfür uygulamaları — pas için orta düzey etki',
    'Erken hasat — buğdayda pas geç gelirse erken hasat ile zarar düşer',
  ],
  chemicalTreatments: [
    'Triazol grubu (Propikonazol, Tebukonazol, Difenokonazol) — sistemik, tedavi+koruma',
    'Azoksistrobin — strobilurin grubu, geniş spektrum',
    'Trifloksistrobin + Tebukonazol — kombinasyon, dirence karşı',
    'Buğdayda: T2 evresinde (bayrak yaprak çıkışı) tek uygulama yeterli olabilir',
  ],
  preventionTips: [
    'Dayanıklı çeşit seçin — özellikle buğdayda Tarım Bakanlığı tescilli pasa dayanıklı çeşitler kullanın',
    'Erken ekim pas baskısını azaltır',
    'Aşırı azotlama bitkiyi sulu yapar, pas riskini artırır',
    'Yabani buğdaygil otları temizleyin (ara konukçu)',
  ],
  deadPlantProtocol: [
    'Bitkiyi kökü ile birlikte sökün',
    'Sökme öncesi sporları yere indirmek için bitkiyi hafif su ile ıslatın',
    'Çift kat poşete koyup yakın — pas sporları çok dirençlidir, kompostta canlı kalır',
    'Sökme bölgesinde 5 cm üst toprağı kazıyıp parsel dışına atın',
    'Bir sonraki sezonda en az 2 yıl başka familyadan bitki ekin',
  ],
  sources: [
    'TAGEM — Buğday Pasları Mücadele Talimatları',
    'Tarla Bitkileri Merkez Araştırma Enstitüsü — Pasa Dayanıklı Çeşit Listesi',
  ],
);

const _mozaikVirus = DiseaseAdvice(
  name: 'Mozaik Virüs',
  pathogenType: 'Virüs',
  contagious: true,
  urgency: 'Çok Yüksek',
  symptoms: [
    'Yapraklarda açık-koyu yeşil veya sarı mozaik benzeri lekeler',
    'Yaprak deformasyonu, kıvrılma, küçülme',
    'Bitki bodur kalır, verim ciddi düşer',
    'Meyvelerde çatlak, lekeli görünüm',
  ],
  spreadMechanism:
      'Virüsün TEDAVİSİ YOKTUR. Yaprak biti (afit), beyaz sinek, thrips '
      'gibi vektör böceklerle ve kirli aletlerle bulaşır. Tütün mozaik '
      'virüsü (TMV) sigara dumanı ve elle bile bulaşabilir.',
  isolationSteps: [
    'ACİL: Hasta bitkiyi derhal sökün — kurtarma şansı yoktur, çevreye yayılır',
    'Sökmeden ÖNCE elinizi sabunlayıp eldiven giyin',
    'Çevredeki yaprak biti ve beyaz sineği derhal kontrol altına alın (vektör mücadelesi)',
    'Sökerken bitkiye dokunan tüm aletleri saf süt veya %2 sodyum hipoklorit ile sterilize edin',
    'Tarlada sigara içmeyin (TMV bulaştırır), elinizi yıkamadan başka bitkiye dokunmayın',
  ],
  organicTreatments: [
    'Virüse karşı doğrudan organik ilaç YOKTUR',
    'Vektör böcek mücadelesi: sarı yapışkan tuzaklar, sabun-su, neem yağı',
    'Hasta bitkiyi sökmek tek "tedavi" yoludur',
  ],
  chemicalTreatments: [
    'Virüse karşı kimyasal ilaç YOKTUR',
    'Vektör mücadelesi: İmidakloprid, Asetamiprid (yaprak biti, beyaz sinek için)',
    'Spinetoram veya Spinosad — thrips kontrolü',
    'Kovucu mineral yağ — vektörü uzak tutar',
  ],
  preventionTips: [
    'Sertifikalı, virüsten ari fide/tohum kullanın',
    'Yaprak biti ve beyaz sineği erken tespit için sarı yapışkan tuzak kurun',
    'Yabani konukçu otları temizleyin (köpek dişi, ısırgan, vb.)',
    'Tütün/sigara kullanan biri tarlada çalışıyorsa ellerini sabunlu su ile yıkasın',
    'Aletleri bitkiler arasında %1 sodyum hipoklorit ile dezenfekte edin',
  ],
  deadPlantProtocol: [
    'KRİTİK: Hasta bitki ölü değilse bile virüs yayılımını durdurmak için sökülmelidir',
    'Bitkiyi yere düşürmeden, sökerken çift kat poşete alın',
    'Tüm bitki artıklarını (yaprak, kök, meyve) toplayın — birinde virüs varsa hepsi taşır',
    'Yakarak imha edin; ASLA kompostlamayın',
    'Sökme noktasındaki toprağa dokunan eldiveni de poşete atın',
    'Aletleri %2 sodyum hipoklorit (1 ölçü çamaşır suyu : 24 ölçü su) çözeltisinde 10 dk bekletin',
    'Aynı parsele en az 1 yıl başka familyadan bitki ekin',
  ],
  sources: [
    'TAGEM — Bitki Virüs Hastalıkları Standartları',
    'Tarım Bakanlığı — Sertifikalı Tohum Yönetmeliği',
    'bku.tarim.gov.tr — Vektör böcek mücadele ürünleri',
  ],
);

const _bakteriyelYaniklik = DiseaseAdvice(
  name: 'Bakteriyel Yanıklık',
  pathogenType: 'Bakteri',
  contagious: true,
  urgency: 'Yüksek',
  symptoms: [
    'Yaprak ve sürgünlerde aniden kararma, kuruma — sanki ateş yanmış',
    'Sürgün uçları çengel gibi aşağı bükülür',
    'Sızıntı şeklinde sütlü-kahve damlacıklar (bakteri özsuyu)',
    'Meyve ağaçlarında (armut, ayva, elma) çok tahripkâr',
  ],
  spreadMechanism:
      'Bakteri yağmur sıçraması, böcek (özellikle arı), aletler ve dolu '
      'ile yayılır. 18–28 °C nemli havada saldırır. Çiçeklenme döneminde '
      'arı ile en hızlı yayılır.',
  isolationSteps: [
    'Hasta dalları belirti çıkış noktasının 30–40 cm AŞAĞISINDAN kesin (sağlam dokuya 30 cm girmeden tam temizlenmez)',
    'Her kesimden sonra makas/testereyi %10 çamaşır suyu veya %70 alkolle silin',
    'Kesilen dalları parselden çıkarıp yakın — kompost ya da çitin altına BIRAKMAYIN',
    'Kesim yarasına bakırlı bordo macunu sürün',
    'Çiçeklenme dönemindeyse arı kovanı varsa parselden uzaklaştırılmasını rica edin',
  ],
  organicTreatments: [
    'Bordo bulamacı (%2 — kuvvetli doz, gözlem altında) — çiçeklenme öncesi koruma',
    'Bakır hidroksit — koruyucu, etkin organik seçenek',
    'Aşırı budama YAPMAYIN — yara her bakteri kapısı',
  ],
  chemicalTreatments: [
    'Bakır oksiklorür veya Bakır hidroksit — temel koruyucu',
    "Streptomisin sülfat — Türkiye'de bazı kullanımlarda kısıtlı, etiket kontrol edin",
    'Kasugamisin — ihracat hedefli üründe genellikle yasak; iç piyasa için kontrol',
    'NOT: Bakteriyel hastalıklarda kimyasal etkisi sınırlıdır — kültürel önlemler kritik',
  ],
  preventionTips: [
    'Hastalıktan ari fidan kullanın (sertifikalı fidanlık)',
    'Aşırı sulamadan kaçının — özellikle yapraklara yağmurlama',
    'Budamayı kuru, soğuk havada (kış sonu) yapın',
    'Aletleri her ağaç arasında dezenfekte edin (%70 alkol veya 1/9 çamaşır suyu)',
    'Aşırı azotlu gübre vermeyin — sulu sürgün bakteriyi davet eder',
    'Kasırga, dolu sonrası 24 saat içinde koruyucu bakırlı uygulama yapın',
  ],
  deadPlantProtocol: [
    'Bitkiyi kökü ile birlikte sökün — bakteri toprakta da kalabilir',
    'Sökme öncesi tüm bitkiyi çuvalla örtün, sonra dibinden kesin (sıçrama önlemek için)',
    'Kullanılan tüm aletleri %10 çamaşır suyunda 10 dk bekletin',
    'Sökme yerindeki toprağı 10 cm derinden temizleyin',
    'Söktüğünüz bitkiyi parselden çıkarıp yakın',
    'Komşu bitkilere koruyucu bakırlı uygulama yapın',
    'En az 2 sezon aynı parsele aynı türden ağaç dikmeyin',
  ],
  sources: [
    'TAGEM — Ateş Yanıklığı (Erwinia amylovora) Mücadele Talimatı',
    'Tarım Bakanlığı — Karantina Hastalıkları Listesi (bazı bakteriyel yanıklıklar bildirimli)',
    'bku.tarim.gov.tr',
  ],
);

const _kokCurukluk = DiseaseAdvice(
  name: 'Kök Çürüklüğü',
  pathogenType: 'Mantar',
  contagious: true,
  urgency: 'Yüksek',
  symptoms: [
    'Bitki sebepsiz solar, sulansa bile dirilmez',
    'Toprak hizasında gövde kararır, çürür, kolay kopar',
    'Kök sistemi kahverengi, koku yapar, kolay parçalanır',
    'Genç fidelerde yatma (damping-off) hastalığı — Pythium, Rhizoctonia',
  ],
  spreadMechanism:
      'Toprakta yaşayan mantarlar (Phytophthora, Pythium, Fusarium, '
      'Rhizoctonia). Aşırı sulama, kötü drenaj, sıkışmış toprak ile patlar. '
      'Sulama suyu, alet, fide toprağı ile bulaşır.',
  isolationSteps: [
    'Sulamayı DERHAL azaltın — fazla nem hastalığın yakıtı',
    'Hasta bitkinin kökü ile birlikte sökülmesi şart, gevşek bir kazma ile',
    'Sökme noktasını işaretleyin; o noktadan sulama akışı gelmemesini sağlayın',
    'Aynı sulama hattından beslenen bitkileri yakından izleyin (5 günde bir kontrol)',
    'Aletleri %70 alkol veya 1/9 çamaşır suyu ile silin',
  ],
  organicTreatments: [
    'Trichoderma harzianum — biyolojik koruma; toprağa veya tohum gömleğine uygulanır',
    'Kompost çayı — toprak mikrobiyomu güçlendirir',
    'Drenaj iyileştirme — yüksek yatak (raised bed), kum karışımı',
    'Solarizasyon — yaz aylarında saydam naylonla 4–6 hafta toprak ısıtma (mantarı öldürür)',
  ],
  chemicalTreatments: [
    'Fosetyl-Al — Phytophthora ve Pythium için sistemik',
    'Metalaksil-M — kök bölgesine can suyuyla',
    'Propamokarb HCl — fide döneminde toprağa uygulama',
    'Tolklofos-metil — Rhizoctonia için',
    'Karboksin + Tiram — tohum ilaçlama, fide yatması (damping-off) için',
  ],
  preventionTips: [
    'Toprağı drenaj testi yapın — 30 cm derinde su 24 saatte çekilmeli',
    'Aşırı sulamadan kaçının; "az ve sık" yerine "yeterli ve seyrek" sulayın',
    'Toprağı havalandırın — sıkışmış toprak kök çürüklüğünü davet eder',
    'Çeşit rotasyonu yapın — Fusarium toprağa yıllarca bulaşır',
    "pH'ı kontrol edin — bazı patojenler ekstrem pH'ta artar",
  ],
  deadPlantProtocol: [
    'Bitkiyi sökerken etrafındaki 30 cm toprağı da çıkarın',
    'Toprakla birlikte poşete koyun — patojen toprağa yayılmasın',
    'Söküm sonrası boş çukuru bir hafta açık bırakın (güneş sterilize eder)',
    'Çukuru sağlam toprakla doldurmadan önce sönmüş kireçle (200 g/m²) muamele edin',
    'Aynı yere en az 2 yıl boyunca aynı familyadan bitki dikmeyin',
    'Sulama hattını yıkayın — patojen damla deliklerinde kalabilir',
  ],
  sources: [
    'TAGEM — Toprak Kökenli Hastalıklar Mücadele Talimatları',
    'Çukurova Üniv. Ziraat Fak. — Kök Hastalıkları Tanı Rehberi',
  ],
);

const _antraknoz = DiseaseAdvice(
  name: 'Antraknoz',
  pathogenType: 'Mantar',
  contagious: true,
  urgency: 'Yüksek',
  symptoms: [
    'Yaprak, gövde ve özellikle MEYVELERDE çökük, koyu, halka biçimli lekeler',
    'Lekelerde nemli havada turuncu-pembe sporlar (akrosporlar)',
    'Olgun meyvelerde hızla yumuşama ve çürüme',
    'Çilek, biber, fasulye, üzüm, kavun-karpuzda yaygın',
  ],
  spreadMechanism:
      'Sporlar yağmur sıçraması, böcekler ve aletlerle yayılır. 22–28 °C '
      've %95 üstü nemde patlar. Hasat sırasında ve depolamada da meyveye '
      'bulaşır — kuluçka süresi gizlenebilir.',
  isolationSteps: [
    'Hasta meyveleri tarlada bırakmayın, derhal poşetleyip uzaklaştırın',
    'Sulamayı yağmurlamadan damla sulamaya çevirin',
    'Hasattan önce yaş havada toplama yapmayın — sporlar dağılır',
    'Hasat kasalarını kullanmadan önce dezenfekte edin',
  ],
  organicTreatments: [
    'Bordo bulamacı (%1) — çiçeklenme öncesi koruyucu',
    'Bakır hidroksit — yaygın organik seçenek',
    'Kompost çayı — yaprak yüzeyinde mikrobiyal rekabet',
    'Hasta bitki artıklarını yakın — sporlar kışı artıkta geçirir',
  ],
  chemicalTreatments: [
    'Klorotalonil — koruyucu, çok kullanılır',
    'Mancozeb — koruyucu, geniş spektrum',
    'Azoksistrobin + Difenokonazol — sistemik, tedavi+koruma',
    'Tebukonazol veya Pirakloztrobin — alternatif aktif maddeler',
    'Hasattan en az 7–14 gün önce ilaçlamayı kesin (etiket bekleme süresi)',
  ],
  preventionTips: [
    'Sertifikalı, hastalıktan ari tohum/fide kullanın',
    'Sıra yönü hâkim rüzgâra paralel — yapraklar daha çabuk kurur',
    'Aşırı azot vermeyin — sulu doku antraknozu çağırır',
    'Hasat sonrası bitki artıklarını parsel dışına alın, anız bozumu yapın',
    '3 yıl rotasyon — aynı familyaya geri dönmeyin',
  ],
  deadPlantProtocol: [
    'Bitkiyi tüm artıkları ile birlikte toplayın (yaprak, sap, dökülen meyve)',
    'Mutlaka kuru havada toplama yapın — nemli hava sporları dağıtır',
    'Çift kat poşete koyup yakın; kompostlamayın',
    'Toprağı sürerek artıkları gömün, hava ile temasını kesin',
    'Aletleri bakırlı dezenfektan ile silin',
    'Yan komşu bitkileri 7 gün boyunca yakın gözlem altına alın',
  ],
  sources: [
    'TAGEM — Antraknoz Mücadele Teknik Talimatları (Çilek, Biber, Bağ)',
    'Ege Üniv. Ziraat Fak. — Bahçe Bitkileri Hastalıkları',
  ],
);

// ─────────────────────────────────────────────────────────────────────────────
// Yeni eklenen hastalık tanımları — V2 trust DB'deki yaygın isimleri kapsar.
// Kaynaklar: TAGEM Zirai Mücadele Teknik Talimatları + üniversite ziraat
// fakülteleri + bku.tarim.gov.tr.
// ─────────────────────────────────────────────────────────────────────────────

const _kursuniKuf = DiseaseAdvice(
  name: 'Kurşuni Küf',
  pathogenType: 'Mantar',
  contagious: true,
  urgency: 'Çok Yüksek',
  symptoms: [
    'Çiçek, yaprak ve meyvelerde gri-kahverengi tüy benzeri küf tabakası',
    'Meyve sapı bölgesinde halka şeklinde kuru çürüklük',
    'Yaprak kenarlarında kavrulma; ölü dokular kolay parçalanır',
    'Domates, çilek, biber, üzüm ve süs bitkilerinde yaygın',
  ],
  spreadMechanism:
      'Botrytis cinerea sporları havada her yerde bulunur; 15–22 °C ve %90 '
      'üstü nem ile saatler içinde patlama yapar. Yaralı doku, açık çiçek '
      've biriken ölü yapraklar başlıca giriş noktalarıdır.',
  isolationSteps: [
    'Hasta dokuları kuru havada koparın — nemli havada sporlar bulutlanır',
    'Sera ise nemi %75 altına çekin: havalandırma + ısıtma',
    'Damla sulamaya geçin, yaprak ıslaklığını ortadan kaldırın',
    'Hasta meyve ve çiçek artıklarını tarladan tamamen uzaklaştırın',
    'Bitki sıklığını azaltın — hava sirkülasyonu kritiktir',
  ],
  organicTreatments: [
    'Bakır oksiklorür — koruyucu, yaralı dokuya öncelikle uygulanır',
    'Trichoderma harzianum bazlı biyolojik preparatlar',
    'Karbonat çözeltisi (5 g/L su) — yaprak yüzey pH\'sını yükseltir',
    'Aşırı azotlu gübrelemeden kaçının — yumuşak doku botrytis çağırır',
  ],
  chemicalTreatments: [
    'Boscalid + Pyraclostrobin — sistemik+koruyucu, çiçeklenme öncesi',
    'Fenheksamid — botrytis için özelleşmiş, kalıntı süresi kısa',
    'Fludioksonil + Siprodinil — kombinasyon, dirence karşı',
    'İprodion — koruyucu, klasik etken',
    'NOT: Aynı aktif maddeyi üst üste kullanmayın; etiket dozu ve hasada '
        'bekleme süresi (PHI) için bku.tarim.gov.tr kontrolü zorunludur',
  ],
  preventionTips: [
    'Sera nemini %75 altında tutun',
    'Sabah erken yaprak ıslaklığı kalmasın — havalandırma artırın',
    'Toleranslı çeşit seçin (özellikle domates ve çilekte)',
    'Hasattan sonra bitki artıklarını tarladan kaldırın — Botrytis kışı '
        'artıklarda geçirir',
  ],
  deadPlantProtocol: [
    'Bitkiyi kuru havada sökün — nemli havada sporlar dağılır',
    'Hasta dokuları çift kat poşete alıp ağzını sıkıca kapatın',
    'Yakarak imha edin; kompost yapmayın',
    'Sökme bölgesindeki tüm ölü çiçek ve yaprakları toplayın',
    'Aletleri %70 alkol veya bakırlı dezenfektanla silin',
  ],
  sources: [
    'TAGEM — Domates ve Çilek Botrytis Mücadele Talimatları',
    'Ankara Üniv. Ziraat Fak. — Botrytis cinerea Tanı Rehberi',
    'bku.tarim.gov.tr — Botrytis için ruhsatlı aktif madde sorgulama',
  ],
);

const _erkenYaniklik = DiseaseAdvice(
  name: 'Erken Yaprak Yanıklığı',
  pathogenType: 'Mantar',
  contagious: true,
  urgency: 'Yüksek',
  symptoms: [
    'Alt yapraklardan başlayan koyu kahverengi, kenarları sarı haleli lekeler',
    'Lekelerde iç içe halkalar (hedef tahtası deseni) — Alternaria belirteci',
    'İleri evrede yapraklar tamamen kuruyup dökülür',
    'Meyvelerde sap kısmından çökük, koyu çürüklük (özellikle domates)',
    'Domates, patates, havuç, lahana ve süs bitkilerinde yaygın',
  ],
  spreadMechanism:
      'Alternaria solani sporları rüzgâr, yağmur ve aletlerle yayılır. '
      '20–30 °C ve değişken nem koşulları (gündüz sıcak, gece çiy) hastalığı '
      'tetikler. Yaşlı, stresli bitkilerde patlama yapar.',
  isolationSteps: [
    'Alt yaprakları hemen koparıp bertaraf edin — sporlar yukarı taşınmasın',
    'Damla sulamaya geçin, yaprak alt yüzeyini ıslak bırakmayın',
    'Aletleri bitkiler arasında %70 alkolle silin',
    'Bitki diplerinde malç kullanın — toprak sıçraması önlenir',
  ],
  organicTreatments: [
    'Bordo bulamacı (%1) — koruyucu, ilk belirti görüldüğünde',
    'Bakır oksiklorür — yağışlardan önce koruyucu',
    'Trichoderma bazlı biyolojik preparatlar — toprak desteği',
    'Bitki dipleri havalı kalsın — sık dikim yapmayın',
  ],
  chemicalTreatments: [
    'Mancozeb (%80 WP) — koruyucu, 10 gün arayla',
    'Klorotalonil — geniş spektrum koruyucu',
    'Azoksistrobin + Difenokonazol — sistemik, tedavi+koruma',
    'Pyraclostrobin + Metiram — kombinasyon',
    'Boscalid — alternatif aktif madde, direnç yönetimi için',
    'NOT: Hasada en az 7 gün kala ilaçlamayı kesin; etiket dozu ve PHI için '
        'bku.tarim.gov.tr',
  ],
  preventionTips: [
    'Dayanıklı çeşit seçin (domates ve patatesde tolerans değişir)',
    'Aşırı azot kullanmayın — sulu doku Alternaria\'ya hassas',
    'Sıra arası havalandırma — sık dikimden kaçının',
    'Hasat sonrası bitki artıklarını parsel dışına alın',
    '2–3 yıl rotasyon — aynı familyaya geri dönmeyin',
  ],
  deadPlantProtocol: [
    'Bitkiyi kökü ile birlikte sökün',
    'Yaprakları tek tek toplayın — sporlar yaprakta uzun süre canlı kalır',
    'Çift kat poşete koyup yakın; kompostlamayın',
    'Sürerek artıkları derin gömün (en az 15 cm)',
    'Aletleri bakırlı dezenfektanla silin',
  ],
  sources: [
    'TAGEM — Alternaria Erken Yanıklık Teknik Talimatları',
    'Çukurova Üniv. Ziraat Fak. — Solanaceae Hastalıkları',
  ],
);

const _fusariumSolgunlugu = DiseaseAdvice(
  name: 'Fusarium Solgunluğu',
  pathogenType: 'Mantar',
  contagious: true,
  urgency: 'Çok Yüksek',
  symptoms: [
    'Alt yapraklardan başlayan tek taraflı sararma ve solma',
    'Gündüz solar, gece düzelir — su yetersizliği değildir',
    'Gövde kesildiğinde damarlarda kahverengi renk değişimi (vasküler iz)',
    'İleri evrede bitki tamamen kurur; kökler sağlam görünebilir',
    'Domates, biber, kavun, karpuz, hıyar ve muzda yaygın',
  ],
  spreadMechanism:
      'Fusarium oxysporum toprak kökenli mantar; bitkinin kökünden girer ve '
      'iletim demetlerini tıkar. Toprakta 5+ yıl canlı kalır. 25–30 °C ve '
      'asidik toprakta (pH<6.5) patlama yapar.',
  isolationSteps: [
    'Hasta bitkiyi 30 cm çevresiyle birlikte sökün — toprak da kontamine',
    'Sökme bölgesini işaretleyin, ertesi yıl ekim yapmayın',
    'Sulama hattını ayırın — patojen damla deliklerinde yayılır',
    'Aletleri %10 çamaşır suyunda 10 dakika bekletin',
  ],
  organicTreatments: [
    'Toprağı yaz aylarında solarize edin (şeffaf naylon, 4–6 hafta)',
    'Trichoderma harzianum bazlı toprak preparatları',
    'Aşılı fide kullanın (Fusarium\'a dayanıklı anaç)',
    'Organik madde (yanmış çiftlik gübresi) ile mikrobiyal denge sağlayın',
    'pH\'ı 6.5–7.0 aralığında tutun (kireçleme)',
  ],
  chemicalTreatments: [
    'Karbendazim — sınırlı etki, sadece koruyucu',
    'Tiyofanat-metil — sistemik, fide döneminde uygulanır',
    'Toprak dezenfeksiyonu: Metam-sodyum (yalnız ruhsatlı bayi gözetiminde)',
    'NOT: Fusarium toprak kökenli olduğu için kimyasal mücadele sınırlıdır. '
        'Asıl çözüm dayanıklı çeşit + rotasyon + solarizasyondur.',
  ],
  preventionTips: [
    'Fusarium\'a dayanıklı çeşit kullanın (etiketin F1, F2, F3 işaretleri)',
    '4–5 yıl rotasyon — aynı familyaya geri dönmeyin',
    'Sertifikalı, hastalıktan ari fide alın',
    'Tek bitki tek damla — sulama suyundan bulaşmayı engelleyin',
    'Aşırı azottan kaçının — yumuşak doku Fusarium\'a hassas',
  ],
  deadPlantProtocol: [
    'Bitkiyi tüm köküyle ve 30 cm çevre toprağıyla birlikte sökün',
    'Topraklı çift kat poşete koyun — toprak patojen taşır',
    'Yakarak imha edin; kompostlamayın',
    'Çukuru 1 hafta açık bırakın, ardından sönmüş kireç (200 g/m²) uygulayın',
    'Aletleri %10 çamaşır suyunda 10 dakika dezenfekte edin',
    'Aynı yere en az 4 yıl Solanaceae veya Cucurbitaceae ekmeyin',
  ],
  sources: [
    'TAGEM — Toprak Kökenli Hastalıklar Mücadele Talimatları',
    'Antalya Batı Akdeniz Tarımsal Araştırma Enstitüsü — Solgunluk Hastalıkları',
    'Ege Üniv. Ziraat Fak. — Fusarium oxysporum Tanı Rehberi',
  ],
);

const _monilya = DiseaseAdvice(
  name: 'Monilya',
  pathogenType: 'Mantar',
  contagious: true,
  urgency: 'Yüksek',
  symptoms: [
    'Çiçek yanıklığı — açan çiçekler kahverengileşip dalda kuruyarak kalır',
    'Sürgün ucu yanıklığı — taze sürgünler kuruyarak çengelleşir',
    'Meyvelerde kahverengi yumuşak çürüklük, üzerinde gri-bej sporulasyon halkaları',
    'Çürüyen meyveler dalda kuruyarak "mumya" şeklinde kalır',
    'Kayısı, şeftali, kiraz, erik, badem ve elmada yaygın',
  ],
  spreadMechanism:
      'Monilinia laxa ve M. fructigena çiçeklenme döneminde sporlarını '
      'salar. 10–25 °C, çiçeklenme sırasında yağmur veya çiy hastalığı '
      'patlatır. Mumya meyveler ve hasta sürgünler kışı geçirme noktasıdır.',
  isolationSteps: [
    'Dalda kalan mumyalaşmış meyveleri kışın budamayla temizleyin',
    'Hasta sürgün uçlarını sağlam dokunun 10 cm altından kesin',
    'Budama aletlerini her dal arasında %70 alkolle silin',
    'Hasta dokuları yakın — bahçede bırakmayın',
  ],
  organicTreatments: [
    'Bordo bulamacı (%1) — kabuk patlama (uyanma) öncesi koruyucu',
    'Bakır oksiklorür — çiçeklenme öncesi (pembe tomurcuk evresi)',
    'Budama artıklarını bahçeden uzaklaştırın',
    'Sertifikalı fidan kullanın — bulaşık fidanlar yıllarca sorun yaratır',
  ],
  chemicalTreatments: [
    'Tebukonazol — çiçeklenme döneminde sistemik etki',
    'Difenokonazol — koruyucu+tedavi, kalıntı süresi orta',
    'Boscalid + Pyraclostrobin — çiçek yanıklığı için kombinasyon',
    'Sülfür (kükürt) — uyanma öncesi koruyucu',
    'İprodion — meyve çürüklüğü için',
    'NOT: Hasada bekleme süresi (PHI) ürüne göre değişir — etiket + '
        'bku.tarim.gov.tr kontrolü zorunludur',
  ],
  preventionTips: [
    'Bahçe dolaşımı iyi olsun — havalandırmayı destekleyin',
    'Hasta dalları kıştan önce kesip yakın',
    'Mumya meyveleri ağaçta bırakmayın — kış konağı oluşur',
    'Çiçeklenme döneminde yağış varsa koruyucu ilaçlama planlayın',
    'Hasat sonrası kalan meyveleri toplayın',
  ],
  deadPlantProtocol: [
    'Ağaç tamamen ölmüşse kökü ile birlikte sökün',
    'Mumya meyveleri ve kuru dalları topla — sporlar yıllarca canlı',
    'Çift kat poşete koyup yakın',
    'Sökme bölgesi 1 hafta açık bekletilebilir',
    'Aletleri %70 alkolle silin',
  ],
  sources: [
    'TAGEM — Sert Çekirdekli Meyveler Monilya Mücadele Talimatları',
    'Eğirdir Meyvecilik Araştırma Enstitüsü — Monilya Rehberi',
  ],
);

const _atesYaniklik = DiseaseAdvice(
  name: 'Ateş Yanıklığı',
  pathogenType: 'Bakteri',
  contagious: true,
  urgency: 'Çok Yüksek',
  symptoms: [
    'Çiçek ve sürgün uçları aniden kararıp kuruyarak ağacın "yanmış" görünmesi',
    'Sürgün uçlarının çengel/bastonu şeklinde kıvrılması (karakteristik)',
    'Dal kabuğunda çatlaklar ve sızıntı — nemli havada süt rengi akıntı',
    'Lekeli yaprak ve meyveler ağaçta asılı kalır',
    'Armut, elma, ayva, alıç ve dağ muşmulasında yaygın',
  ],
  spreadMechanism:
      'Erwinia amylovora bakterisi çiçeklenme döneminde arılar, yağmur ve '
      'rüzgârla yayılır. 18–30 °C ve yüksek nem (%70+) ile saatler içinde '
      'patlama yapar. Budama yarası, dolu vurması ve böcek izleri başlıca '
      'giriş noktalarıdır.',
  isolationSteps: [
    'TEHLİKE: Ateş yanıklığı hızlı yayılan bakteriyel hastalıktır',
    'Hasta dalı sağlam dokunun 30–40 cm altından kesin',
    'Her kesimden sonra aleti %10 çamaşır suyunda DALDIRIN (silmek yetmez)',
    'Kesilen dalları ağaçtan uzaklaştırın, derhal yakın',
    'Bahçeyi karantinaya alın; komşu bahçelere uyarı yapın (resmi bildirimde)',
    'Tarım İl Müdürlüğü Bitki Koruma Şubesi\'ne bildirim ZORUNLUDUR',
  ],
  organicTreatments: [
    'Bakır hidroksit (uyanma öncesi) — koruyucu, tedavi etmez',
    'Sertifikalı, hastalıktan ari fidan kullanın',
    'Bahçeyi hâkim rüzgâra göre konumlandırın',
    'Aşırı azot vermeyin — sulu sürgün ateş yanıklığını çağırır',
  ],
  chemicalTreatments: [
    'Bakırlı bileşikler (bakır oksiklorür, bakır hidroksit) — koruyucu, '
        'çiçeklenme öncesi',
    'Streptomisin sülfat — Tarım İl Müdürlüğü kontrolünde, yalnız ruhsatlı '
        'uygulayıcı; antibiyotik direnci kritik',
    'Fosetil-Al — bitki bağışıklığını destekler',
    'NOT: Ateş yanıklığı kontrolü için aktif madde ve uygulama zamanı il '
        'müdürlüğü tarafından belirlenir; etiket + bku.tarim.gov.tr',
  ],
  preventionTips: [
    'Sertifikalı, dayanıklı çeşit/anaç kullanın',
    'Budamayı kuru havada yapın, yağmurdan kaçının',
    'Aşırı azotlu gübrelemeden kaçının — sulu sürgün hastalığı çağırır',
    'Dolu vurması sonrası 24 saat içinde bakırlı koruyucu uygulayın',
    'Çiçeklenme döneminde yağış varsa il müdürlüğü uyarısına uyun',
  ],
  deadPlantProtocol: [
    'Hasta ağaç tamamen sökülmelidir — bakteri ağaçta yıllarca kalır',
    'Köküyle birlikte çıkarın, toprağı derin sürün',
    'Tüm dalları yakarak imha edin — bakteri ısıdan ölür',
    'Söküm bölgesini en az 2 yıl yumuşak çekirdekli meyve için kullanmayın',
    'Aletleri %10 çamaşır suyunda 10 dk dezenfekte edin',
    'TC Tarım İl Müdürlüğü Bitki Koruma Şubesi\'ne bildirim — ihbarı zorunlu '
        'hastalıktır',
  ],
  sources: [
    'TC Tarım ve Orman Bakanlığı — Ateş Yanıklığı Mücadele Talimatı',
    'TAGEM — Erwinia amylovora Bültenleri',
    'Eğirdir Meyvecilik Araştırma Enstitüsü — Ateş Yanıklığı Rehberi',
  ],
);

const _cercospora = DiseaseAdvice(
  name: 'Cercospora Yaprak Lekesi',
  pathogenType: 'Mantar',
  contagious: true,
  urgency: 'Orta',
  symptoms: [
    'Yapraklarda küçük (2–5 mm), yuvarlak, koyu kahverengi-mor kenarlı, '
        'gri-açık merkezli lekeler',
    'Şiddetli enfeksiyonda lekeler birleşerek geniş ölü alanlar oluşturur',
    'Alt yapraklardan yukarı doğru ilerler',
    'Şeker pancarı, fasulye, soya, biber, havuç ve süs bitkilerinde yaygın',
  ],
  spreadMechanism:
      'Cercospora beticola ve diğer Cercospora türleri rüzgâr, yağmur ve '
      'aletlerle yayılır. 25–30 °C ve %90+ nem ile hızla yayılır. Sporlar '
      'yağışla yaprak alt yüzeyine ulaşır.',
  isolationSteps: [
    'Alt hasta yaprakları koparıp bertaraf edin',
    'Damla sulamaya geçin, yaprak ıslaklığını azaltın',
    'Sıra arası havalandırmayı artırın — sık dikimden kaçının',
    'Aletleri %70 alkolle silin',
  ],
  organicTreatments: [
    'Bordo bulamacı (%1) — koruyucu, ilk belirti görüldüğünde',
    'Bakır oksiklorür — yağışlardan önce',
    'Süt-su karışımı (1:9) — hafif enfeksiyonda haftalık',
    'Hasat sonrası bitki artıklarını parsel dışına alın',
  ],
  chemicalTreatments: [
    'Triazol grubu (Difenokonazol, Tebukonazol) — sistemik+koruyucu',
    'Strobilurin grubu (Azoksistrobin, Pyraclostrobin) — geniş spektrum',
    'Mancozeb — geleneksel koruyucu, kombinasyon için',
    'Karbendazim — sistemik, dirence dikkat',
    'NOT: Aynı grupta aktif maddeyi üst üste kullanmayın — direnç gelişir; '
        'hasada bekleme süresi için bku.tarim.gov.tr kontrolü zorunludur',
  ],
  preventionTips: [
    'Sertifikalı, dayanıklı çeşit kullanın',
    'Sıra arasını dar tutmayın — havalandırma',
    'Aşırı azottan kaçının',
    '2–3 yıl rotasyon — aynı familyaya geri dönmeyin',
    'Hasat sonrası bitki artıklarını derin gömün veya yakın',
  ],
  deadPlantProtocol: [
    'Bitkiyi tüm yaprakları ile birlikte sökün',
    'Yapraklarda sporlar uzun süre canlı — toplayıp poşetleyin',
    'Yakarak imha edin; kompostlamayın',
    'Aletleri bakırlı dezenfektanla silin',
  ],
  sources: [
    'TAGEM — Cercospora Yaprak Lekesi Mücadele Talimatları',
    'Ege Üniv. Ziraat Fak. — Şeker Pancarı Hastalıkları',
  ],
);

const _bilinmeyen = DiseaseAdvice(
  name: 'Bilinmiyor',
  pathogenType: 'Belirsiz',
  contagious: true,
  urgency: 'Orta',
  symptoms: [
    "Belirti açık değil — fotoğraf çekip Tarım İl/İlçe Müdürlüğü'ne danışın",
    'En yakın Ziraat Odası veya Ziraat Fakültesi tanı laboratuvarı yardımcı olur',
  ],
  spreadMechanism:
      'Bilinmediği için en kötü senaryoyu varsayın: bulaşıcı kabul edip '
      'koruyucu önlemleri uygulayın.',
  isolationSteps: [
    'Hasta bitkiyi 50 cm halka çevresiyle birlikte gözlem altına alın',
    'Aletleri her bitki arasında %70 alkol veya 1/9 çamaşır suyuyla silin',
    'Sulamayı yağmurlamadan damla sulamaya çevirin',
    "Tarım İl Müdürlüğü Bitki Koruma Şubesi'ne fotoğraflı başvuru yapın",
    'Yerel Ziraat Odası uzmanından telefonla destek alın',
  ],
  organicTreatments: [
    'Genel koruma: Bordo bulamacı (%1) — geniş spektrum mantar koruması',
    'Bakırlı uygulamalar — bakteriyel ihtimal için',
    'Yaprak biti, beyaz sinek varsa sarı yapışkan tuzak kurun (vektör tespiti)',
  ],
  chemicalTreatments: [
    'Tanı netleşmeden geniş spektrumlu KORUYUCU dışında kimyasal kullanmayın',
    'Yanlış aktif madde direnç gelişimine yol açabilir',
    'Tarım İl Müdürlüğü uzmanından teşhis aldıktan sonra etiket dozu uygulayın',
  ],
  preventionTips: [
    'Sertifikalı tohum/fide kullanın',
    'Yıllık 2–3 koruyucu bakırlı uygulama yapın (özellikle yağmur sonrası)',
    'Tarla günlüğü tutun — hangi bitki ne zaman, hangi belirti gösterdi',
    'Yıllık toprak analizi yaptırın (Tarım İl Müdürlüğü laboratuvarları)',
  ],
  deadPlantProtocol: [
    'En kötü senaryoyu varsayarak bulaşıcı protokol uygulayın',
    'Bitkiyi kökü ile birlikte ve 30 cm çevre toprağı dahil sökün',
    'Çift kat poşete alın, yakarak imha edin (kompost yapmayın)',
    'Toprağı bir hafta açık bırakın — güneş kısmen sterilize eder',
    'Aletleri %10 çamaşır suyunda 10 dk bekletin',
    'Söktüğünüz bitkiden örnek (yaprak/sap, fotoğraf) saklayın — laboratuvar tanısı için',
  ],
  sources: [
    'Tarım İl/İlçe Müdürlüğü Bitki Koruma Şubeleri',
    'Ziraat Odaları — telefon hattı',
    'Türkiye Bitki Hastalıkları ve Zararlıları Listesi (TAGEM)',
  ],
);
