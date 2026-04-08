/// Çevrimdışı Ansiklopedi Derinleştirme — Modül 4.
///
/// `OfflineEncyclopedia` mevcut 22 bitki için temel veri tutar; bu dosya
/// onun üstünde **kapsam genişletir**: adım adım büyüme rehberi, bölgesel
/// ekim takvimi, hastalık/zararlı tanıma, toprak iyileştirme, organik tarım
/// yöntemleri ve geleneksel Anadolu tarım bilgileri. Tamamen statik —
/// internet gerektirmez.
library;

/// Bir bitkinin tek bir büyüme aşaması.
class GrowthStage {
  final String label;
  final String durationDays;
  final String description;
  final String careTip;
  const GrowthStage({
    required this.label,
    required this.durationDays,
    required this.description,
    required this.careTip,
  });
}

/// Bir hastalık ya da zararlı tanıma kaydı.
class PestEntry {
  final String name;
  final String symptoms;
  final String organicTreatment;
  final String chemicalTreatment;
  const PestEntry({
    required this.name,
    required this.symptoms,
    required this.organicTreatment,
    required this.chemicalTreatment,
  });
}

class EncyclopediaExtensions {
  EncyclopediaExtensions._();

  // ─────────────────────────────────────────────────────────────────────
  // 1. ADIM ADIM BÜYÜME REHBERİ
  // Bitki tipine göre genel 5 aşamalı şablon. Her aşama: süre + bakım ipucu.
  // ─────────────────────────────────────────────────────────────────────

  static const Map<String, List<GrowthStage>> _stagesByType = {
    'tahıl': [
      GrowthStage(label: 'Çimlenme', durationDays: '7–14 gün',
          description: 'Tohum toprakta su alır, kök ve sürgün belirir.',
          careTip: 'Toprak nemli kalmalı, kabuk bağlamasını önleyin.'),
      GrowthStage(label: 'Kardeşlenme', durationDays: '20–40 gün',
          description: 'Ana sap çevresinde yan sürgünler oluşur.',
          careTip: 'İlk azot gübresi (üre) bu dönemde verilir.'),
      GrowthStage(label: 'Sapa Kalkma', durationDays: '30–50 gün',
          description: 'Saplar uzar, başak taslakları oluşur.',
          careTip: 'Yabancı ot ilaçlaması ve ikinci sulama.'),
      GrowthStage(label: 'Başaklanma', durationDays: '15–25 gün',
          description: 'Başaklar görünür hale gelir, çiçeklenme başlar.',
          careTip: 'Su stresi olmamalı; dane verimini doğrudan etkiler.'),
      GrowthStage(label: 'Olgunlaşma & Hasat', durationDays: '30–45 gün',
          description: 'Daneler sertleşir, bitki sararır.',
          careTip: 'Nem %14\'ün altına düştüğünde hasat.'),
    ],
    'sebze': [
      GrowthStage(label: 'Tohum Ekimi', durationDays: '0–5 gün',
          description: 'Tohum yastığa veya doğrudan tarlaya ekilir.',
          careTip: '1–2 cm derinlik; pülverize sulama.'),
      GrowthStage(label: 'Fide', durationDays: '20–35 gün',
          description: 'İlk gerçek yapraklar belirir, kök sistem güçlenir.',
          careTip: 'Sertleştirme için fide gündüz dışarı çıkarılır.'),
      GrowthStage(label: 'Vejetatif Büyüme', durationDays: '25–45 gün',
          description: 'Yapraklar ve gövde hızla büyür.',
          careTip: 'Azot ağırlıklı gübre; sürgün alma (kalem alma).'),
      GrowthStage(label: 'Çiçeklenme & Meyve', durationDays: '20–40 gün',
          description: 'Çiçek açar, küçük meyveler bağlanır.',
          careTip: 'Potasyum ağırlıklı gübre; arı dostu davranın.'),
      GrowthStage(label: 'Hasat Dönemi', durationDays: '30–60 gün',
          description: 'Olgun meyveler sırayla toplanır.',
          careTip: 'Sabah erken veya akşam serinlikte toplayın.'),
    ],
    'meyve': [
      GrowthStage(label: 'Dikim & Tutma', durationDays: '15–30 gün',
          description: 'Fidan çukura dikilir, kök tutar.',
          careTip: 'Destek kazığı; köke su yastığı yapın.'),
      GrowthStage(label: 'Sürgün Verme', durationDays: '40–80 gün',
          description: 'Yeni dallar uzar, taç oluşur.',
          careTip: 'Şekil budaması ile ana dallar belirlenir.'),
      GrowthStage(label: 'Çiçeklenme', durationDays: '15–30 gün',
          description: 'İlkbahar tomurcukları açar.',
          careTip: 'Don tehlikesinde sis makinesi/duman/örtü kullanın.'),
      GrowthStage(label: 'Meyve Tutma & Büyüme', durationDays: '60–120 gün',
          description: 'Çiçekler meyveye dönüşür, irileşir.',
          careTip: 'Fazla meyveyi seyreltin; iri ve kaliteli kalır.'),
      GrowthStage(label: 'Olgunlaşma & Hasat', durationDays: '20–40 gün',
          description: 'Renk ve şeker dengesi olgunluğa erişir.',
          careTip: 'Elle, sap kısa bırakılarak toplayın.'),
    ],
    'kök': [
      GrowthStage(label: 'Çimlenme', durationDays: '7–14 gün',
          description: 'Toprak altında ilk kök belirir.',
          careTip: 'Toprak gevşek ve taşsız olmalı.'),
      GrowthStage(label: 'Yaprak Gelişimi', durationDays: '20–30 gün',
          description: 'Üst kısımda yaprak kümeleri oluşur.',
          careTip: 'Sıra arası çapalama yapılır.'),
      GrowthStage(label: 'Kök Şişme', durationDays: '40–60 gün',
          description: 'Toprak altındaki kök kalınlaşır.',
          careTip: 'Düzenli sulama; kuraklık kökü çatlatır.'),
      GrowthStage(label: 'Olgunlaşma', durationDays: '20–30 gün',
          description: 'Kök tam boyuna ulaşır.',
          careTip: 'Hasat öncesi 1 hafta sulamayı azaltın.'),
      GrowthStage(label: 'Hasat', durationDays: '5–10 gün',
          description: 'Kökler topraktan çıkarılır.',
          careTip: 'Kürekle alttan kaldırın, kırılmasın.'),
    ],
  };

  /// Bitki adından tipini çıkarır (basit kural tabanlı).
  static String inferType(String cropName) {
    final n = cropName.toLowerCase();
    if (n.contains('buğday') || n.contains('arpa') || n.contains('mısır') ||
        n.contains('çavdar') || n.contains('yulaf') || n.contains('çeltik') ||
        n.contains('sorgum')) {
      return 'tahıl';
    }
    if (n.contains('elma') || n.contains('armut') || n.contains('zeytin') ||
        n.contains('üzüm') || n.contains('erik') || n.contains('kiraz') ||
        n.contains('şeftali') || n.contains('kayısı')) {
      return 'meyve';
    }
    if (n.contains('havuç') || n.contains('turp') || n.contains('soğan') ||
        n.contains('patates') || n.contains('pancar')) {
      return 'kök';
    }
    return 'sebze';
  }

  /// Belirli bir bitki için adım adım büyüme aşamalarını döner.
  static List<GrowthStage> stagesFor(String cropName) {
    final type = inferType(cropName);
    return _stagesByType[type] ?? _stagesByType['sebze']!;
  }

  // ─────────────────────────────────────────────────────────────────────
  // 2. BÖLGESEL EKİM TAKVİMİ
  // Türkiye'nin 7 coğrafi bölgesi için yaygın bitki ekim ayları.
  // ─────────────────────────────────────────────────────────────────────

  static const Map<String, Map<String, String>> regionalCalendar = {
    'Akdeniz': {
      'iklim': 'Yumuşak kış, sıcak-kurak yaz',
      'domates': 'Şubat–Nisan (örtü altı Ocak)',
      'biber': 'Şubat–Nisan',
      'mısır': 'Mart–Haziran',
      'buğday': 'Ekim–Kasım',
      'zeytin (dikim)': 'Şubat–Mart',
      'pamuk': 'Nisan–Mayıs',
      'narenciye': 'Şubat–Mart',
    },
    'Ege': {
      'iklim': 'Ilıman, kıyıda yumuşak kış',
      'domates': 'Mart–Mayıs',
      'biber': 'Mart–Mayıs',
      'üzüm (dikim)': 'Şubat–Mart',
      'incir': 'Şubat–Nisan',
      'pamuk': 'Nisan–Mayıs',
      'buğday': 'Ekim–Kasım',
      'zeytin': 'Şubat–Mart',
    },
    'Marmara': {
      'iklim': 'Geçiş iklimi',
      'domates': 'Nisan–Mayıs',
      'ayçiçeği': 'Mart–Nisan',
      'mısır': 'Nisan–Mayıs',
      'buğday': 'Ekim',
      'üzüm': 'Mart',
    },
    'İç Anadolu': {
      'iklim': 'Karasal — soğuk kış, kurak yaz',
      'buğday': 'Eylül–Ekim',
      'arpa': 'Eylül–Ekim',
      'şeker pancarı': 'Mart–Nisan',
      'patates': 'Nisan–Mayıs',
      'fasulye': 'Mayıs',
      'ayçiçeği': 'Nisan',
    },
    'Karadeniz': {
      'iklim': 'Bol yağışlı, ılıman',
      'mısır': 'Nisan–Mayıs',
      'çay (dikim)': 'Mart–Nisan, Eylül–Ekim',
      'fındık (dikim)': 'Kasım–Mart',
      'fasulye': 'Mayıs',
      'lahana': 'Mart–Nisan, Ağustos',
    },
    'Doğu Anadolu': {
      'iklim': 'Sert kış, kısa yaz',
      'buğday': 'Eylül (yazlık Mart)',
      'arpa': 'Eylül (yazlık Mart)',
      'patates': 'Mayıs',
      'fasulye': 'Mayıs–Haziran',
      'şekerpancarı': 'Nisan–Mayıs',
    },
    'Güneydoğu Anadolu': {
      'iklim': 'Sıcak-kurak, sulamaya bağlı',
      'pamuk': 'Mart–Nisan',
      'buğday': 'Ekim–Kasım',
      'arpa': 'Ekim–Kasım',
      'mercimek': 'Ekim–Kasım',
      'mısır (II. ürün)': 'Haziran',
      'antep fıstığı': 'Şubat–Mart',
    },
  };

  // ─────────────────────────────────────────────────────────────────────
  // 3. HASTALIK & ZARARLI TANIMA REHBERİ
  // Görsel olmayan sürümde belirti tarifi + organik/kimyasal müdahale.
  // ─────────────────────────────────────────────────────────────────────

  static const Map<String, List<PestEntry>> _pestsByType = {
    'sebze': [
      PestEntry(name: 'Beyazsinek',
          symptoms: 'Yaprak altında küçük beyaz sinekler; sarı yapışkan salgı.',
          organicTreatment: 'Sarı yapışkan tuzak, sabunlu su, neem yağı.',
          chemicalTreatment: 'İmidakloprid bazlı insektisit (etiket dozu).'),
      PestEntry(name: 'Kırmızı Örümcek',
          symptoms: 'Yapraklarda sarımsı noktalar, ince ağ dokusu.',
          organicTreatment: 'Yaprak altına su püskürtme, kükürt tozu.',
          chemicalTreatment: 'Akarisit (abamektin vb.)'),
      PestEntry(name: 'Mildiyö',
          symptoms: 'Yaprakta sarı lekeler, alt yüzde grimsi tüy.',
          organicTreatment: 'Bordo bulamacı, havalandırma artırma.',
          chemicalTreatment: 'Bakır oksiklorür veya mancozeb fungisit.'),
      PestEntry(name: 'Külleme',
          symptoms: 'Yaprak üstünde un benzeri beyaz lekeler.',
          organicTreatment: 'Süt + su (1:9) sprey, kükürt tozu.',
          chemicalTreatment: 'Sistemik fungisit (penkonazol).'),
    ],
    'tahıl': [
      PestEntry(name: 'Sarı Pas',
          symptoms: 'Yaprakta sıralı sarı toz püstüller.',
          organicTreatment: 'Dayanıklı çeşit seçimi, tarla rotasyonu.',
          chemicalTreatment: 'Triazol grubu fungisit.'),
      PestEntry(name: 'Süne',
          symptoms: 'Başakta beyaz, boş daneler; sap dibinde böcek.',
          organicTreatment: 'Erken hasat, doğal düşman (yumurta paraziti).',
          chemicalTreatment: 'Deltamethrin (TAGEM eşik üstü).'),
      PestEntry(name: 'Külleme',
          symptoms: 'Yaprak ve sapta beyaz unsu lekeler.',
          organicTreatment: 'Sık ekimden kaçın, dengeli azot.',
          chemicalTreatment: 'Tebukonazol fungisit.'),
    ],
    'meyve': [
      PestEntry(name: 'Elma İç Kurdu',
          symptoms: 'Meyvede delik, içte kahverengi tünel.',
          organicTreatment: 'Feromon tuzak, oluklu mukavva bant.',
          chemicalTreatment: 'Spinosad veya klorantraniliprol.'),
      PestEntry(name: 'Karaleke',
          symptoms: 'Yaprak ve meyvede zeytin yeşili lekeler.',
          organicTreatment: 'Yere düşmüş yaprakları temizle, bakır.',
          chemicalTreatment: 'Captan veya difenokonazol.'),
      PestEntry(name: 'Zeytin Sineği',
          symptoms: 'Meyvede iğne deliği, içeride larva, erken dökülme.',
          organicTreatment: 'Mc Phail tuzak, kaolin kil püskürtme.',
          chemicalTreatment: 'Spinosad zehirli yem püskürtme.'),
    ],
    'kök': [
      PestEntry(name: 'Havuç Sineği',
          symptoms: 'Kökte kahverengi tüneller, üst yapraklar mor.',
          organicTreatment: 'Soğanla birlikte ekim, ince tül örtü.',
          chemicalTreatment: 'Spinosad veya cypermetrin.'),
      PestEntry(name: 'Patates Mildiyösü',
          symptoms: 'Yaprakta esmer lekeler, hızlı yayılan kuruma.',
          organicTreatment: 'Bordo bulamacı, dayanıklı çeşit.',
          chemicalTreatment: 'Mancozeb veya metalaksil.'),
      PestEntry(name: 'Kök Nematodu',
          symptoms: 'Kökte yumru-şişlikler, bitki cılız kalır.',
          organicTreatment: 'Kadife çiçeği nöbetleşe ekim, solarizasyon.',
          chemicalTreatment: 'Nematisit (uzman önerisiyle).'),
    ],
  };

  static List<PestEntry> pestsFor(String cropName) {
    final type = inferType(cropName);
    return _pestsByType[type] ?? _pestsByType['sebze']!;
  }

  // ─────────────────────────────────────────────────────────────────────
  // 4. TOPRAK İYİLEŞTİRME REHBERİ
  // ─────────────────────────────────────────────────────────────────────

  static const List<Map<String, String>> soilImprovement = [
    {
      'baslik': 'Asitli Toprak (pH < 6)',
      'oneri': 'Tarım kireci (CaCO₃) uygulanır. Dekara 100–300 kg, ekim öncesi sonbaharda. '
          'pH yükselir, kalsiyum eksikliği giderilir.',
    },
    {
      'baslik': 'Bazik / Tuzlu Toprak (pH > 8)',
      'oneri': 'Toz kükürt veya jips serpilir. Dekara 50–150 kg jips. '
          'Yağmurlama sulamayla yıkama yapılır.',
    },
    {
      'baslik': 'Ağır Killi Toprak',
      'oneri': 'Kaba kum, yanmış çiftlik gübresi ve kompost karıştırılır. '
          'Drenaj iyileşir, kök gelişimi rahatlar.',
    },
    {
      'baslik': 'Kumlu / Su Tutmayan Toprak',
      'oneri': 'Çiftlik gübresi, kompost, malç (saman) ile organik madde artırılır. '
          'Yeşil gübre (fiğ, yulaf) ekilip toprağa karıştırılır.',
    },
    {
      'baslik': 'Organik Madde Eksik Toprak',
      'oneri': 'Yılda en az 1 ton/dekar yanmış çiftlik gübresi. '
          'Nöbetleşe ekimde baklagil (mercimek, fasulye) toprağı zenginleştirir.',
    },
    {
      'baslik': 'Mikro Element Eksikliği',
      'oneri': 'Yaprak analizi sonucuna göre demir, çinko, bor takviyesi. '
          'Yaprak gübresi olarak püskürtmek hızlı sonuç verir.',
    },
  ];

  // ─────────────────────────────────────────────────────────────────────
  // 5. ORGANİK TARIM YÖNTEMLERİ
  // ─────────────────────────────────────────────────────────────────────

  static const List<Map<String, String>> organicMethods = [
    {
      'baslik': 'Kompost Yapımı',
      'aciklama': 'Bitki artıkları, çiftlik gübresi ve toprak katmanlanır. '
          '3 ayda bir karıştırılır, 4–6 ayda olgunlaşır. '
          'Toprağa hayat verir, gübre maliyetini düşürür.',
    },
    {
      'baslik': 'Yeşil Gübre',
      'aciklama': 'Ana üründen önce fiğ, yonca veya bakla ekilir; '
          'çiçeklenmeden önce sürülerek toprağa karıştırılır. '
          'Azotu doğal yolla bağlar.',
    },
    {
      'baslik': 'Nöbetleşe Ekim (Münavebe)',
      'aciklama': 'Aynı tarlaya art arda aynı bitki ekilmez. '
          'Örnek: Buğday → mercimek → ayçiçeği → buğday. '
          'Hastalık ve zararlı baskısı kırılır.',
    },
    {
      'baslik': 'Birlikte Ekim (Companion)',
      'aciklama': 'Domates yanına fesleğen, havuç yanına soğan, lahana yanına kekik. '
          'Doğal koku zararlıları kovar.',
    },
    {
      'baslik': 'Doğal Mücadele',
      'aciklama': 'Sarımsak-acı biber suyu, ısırgan otu çayı, sabunlu su. '
          'Uğur böceği, yusufçuk gibi doğal düşmanlar korunur.',
    },
    {
      'baslik': 'Malçlama',
      'aciklama': 'Toprak yüzeyi saman, talaş veya kuru ot ile kapatılır. '
          'Su buharlaşması azalır, yabancı ot bastırılır, toprak sıcaklığı dengelenir.',
    },
  ];

  // ─────────────────────────────────────────────────────────────────────
  // 6. GELENEKSEL ANADOLU TARIM BİLGİLERİ
  // ─────────────────────────────────────────────────────────────────────

  static const List<Map<String, String>> traditionalKnowledge = [
    {
      'baslik': 'Ay Takvimine Göre Ekim',
      'aciklama': 'Anadolu çiftçisi yer altı bitkilerini (havuç, patates) '
          'küçülen ayda; yer üstü bitkilerini (mısır, fasulye) büyüyen ayda eker. '
          'Halk inancına göre verim artar.',
    },
    {
      'baslik': 'Çiftçi İşaretleri',
      'aciklama': '"Mart kapıdan baktırır, kazma kürek yaktırır." '
          'Karıncaların yuvayı kapatması yağmur habercisidir. '
          'Akşam kızıllığı ertesi güne güzel hava işaretidir.',
    },
    {
      'baslik': 'Kara Saban & Çift Sürme',
      'aciklama': 'Geleneksel ahşap saban toprağı 10–15 cm derinliğe işler. '
          'Bugün modern pulluğun yanında, ekoloji dostu sürüm için hâlâ tercih edilir.',
    },
    {
      'baslik': 'Tohum Saklama',
      'aciklama': 'En sağlıklı bitkilerden seçilen tohumlar bez torbada, '
          'kuru ve serin yerde, küllü ortamda saklanır. '
          'Atalık tohumlar nesilden nesile aktarılır.',
    },
    {
      'baslik': 'Çiftlik Gübresi Olgunlaştırma',
      'aciklama': 'Taze gübre yakar; en az 6 ay yığınlanıp altüst edilerek '
          '"yanmış" gübre haline getirilir. Kahverengi, kokusuz olunca kullanılır.',
    },
    {
      'baslik': 'Su Yastığı (Tava) Sulama',
      'aciklama': 'Meyve ağaçlarının dibinde toprak halka şeklinde yükseltilip '
          'içi suyla doldurulur. Kök bölgesine yavaş yavaş su iner; '
          'damla sulama olmadığında etkili yöntemdir.',
    },
  ];
}
