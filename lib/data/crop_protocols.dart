import 'package:flutter/material.dart' show IconData, Icons;

import 'activity_types.dart';

// ═══════════════════════════════════════════════════════════════════════
// TOPRAK VE SULAMA TİPLERİ
// ═══════════════════════════════════════════════════════════════════════

enum SoilType {
  loamy('Tınlı', 'Çoğu bitkiye ideal, geçirgen ve besin tutumlu', '🟫'),
  clay('Killi', 'Su tutar, drenaj önemli, ağır işlenir', '🧱'),
  sandy('Kumlu', 'Hızlı drene olur, sık sulama ve organik madde şart', '🏖️'),
  volcanic('Volkanik', 'Doğal mineral zengin, pH kontrolü gerekir', '🌋');

  final String label;
  final String description;
  final String emoji;
  const SoilType(this.label, this.description, this.emoji);
}

enum IrrigationMethod {
  drip('Damla Sulama', 'Kök bölgesine hassas, su tasarrufu %40', Icons.water_damage_rounded),
  furrow('Karık Sulama', 'Geleneksel, sıra aralarına su verilir', Icons.waves_rounded),
  sprinkler('Yağmurlama', 'Üstten yağış simülasyonu, geniş alana uygun', Icons.shower_rounded),
  hand('El ile Sulama', 'Küçük parsel ve bahçe tipi', Icons.pan_tool_rounded);

  final String label;
  final String description;
  final IconData icon;

  const IrrigationMethod(this.label, this.description, this.icon);
}

// ═══════════════════════════════════════════════════════════════════════
// ÇİFTÇİ KONFİGÜRASYONU — kullanıcının tarlaya özel girişleri
// ═══════════════════════════════════════════════════════════════════════

class CropConfig {
  final SoilType soilType;
  final IrrigationMethod irrigationMethod;
  final double areaDekar;
  final double rowSpacingCm;    // sıra arası (cm)
  final double plantSpacingCm;  // bitki arası (cm)

  const CropConfig({
    required this.soilType,
    required this.irrigationMethod,
    required this.areaDekar,
    required this.rowSpacingCm,
    required this.plantSpacingCm,
  });

  Map<String, dynamic> toJson() => {
        'soilType': soilType.name,
        'irrigationMethod': irrigationMethod.name,
        'areaDekar': areaDekar,
        'rowSpacingCm': rowSpacingCm,
        'plantSpacingCm': plantSpacingCm,
      };

  factory CropConfig.fromJson(Map<String, dynamic> j) => CropConfig(
        soilType: SoilType.values.firstWhere(
          (e) => e.name == j['soilType'],
          orElse: () => SoilType.loamy,
        ),
        irrigationMethod: IrrigationMethod.values.firstWhere(
          (e) => e.name == j['irrigationMethod'],
          orElse: () => IrrigationMethod.furrow,
        ),
        areaDekar: (j['areaDekar'] as num?)?.toDouble() ?? 10.0,
        rowSpacingCm: (j['rowSpacingCm'] as num?)?.toDouble() ?? 70.0,
        plantSpacingCm: (j['plantSpacingCm'] as num?)?.toDouble() ?? 25.0,
      );
}

// ═══════════════════════════════════════════════════════════════════════
// ZENGİN PROTOKOL ADIMI
// ═══════════════════════════════════════════════════════════════════════

class ProtocolStep {
  final int order;
  final int dayOffset;
  final String stageEmoji;
  final String title;
  final String description;
  final String? expectedActivity;

  // Toprak tipine göre özel not
  final Map<String, String>? soilNotes;

  // Sulama yöntemine göre özel not
  final Map<String, String>? irrigationNotes;

  // Gübre spesifikasyonu (miktarlar /da bazında)
  final String? fertilizerSpec;

  // İlaç spesifikasyonu (ürün adı, etken madde, doz)
  final String? pesticideSpec;

  // Su miktarı referansı
  final String? waterSpec;

  // Tahmini maliyet (₺/da) — piyasa fiyatı baz alınarak
  final double? estimatedCostPerDekar;

  // ⚠️ Kırmızı kritik uyarı — kaçırılırsa verim felaket
  final String? criticalWarning;

  // 💡 Çiftçi ipucu — deneyimli üreticiden pratik bilgi
  final String? farmerTip;

  // ❌ Sık yapılan hata
  final String? commonMistake;

  const ProtocolStep({
    required this.order,
    required this.dayOffset,
    required this.stageEmoji,
    required this.title,
    required this.description,
    this.expectedActivity,
    this.soilNotes,
    this.irrigationNotes,
    this.fertilizerSpec,
    this.pesticideSpec,
    this.waterSpec,
    this.estimatedCostPerDekar,
    this.criticalWarning,
    this.farmerTip,
    this.commonMistake,
  });

  String? soilNote(SoilType? t) => t == null ? null : soilNotes?[t.name];
  String? irrigationNote(IrrigationMethod? m) =>
      m == null ? null : irrigationNotes?[m.name];
}

// ═══════════════════════════════════════════════════════════════════════
// KROKİ PROTOKOLÜ
// ═══════════════════════════════════════════════════════════════════════

class CropProtocol {
  final String cropKey;
  final String displayName;
  final String emoji;
  final int totalDays;
  final double defaultRowSpacingCm;
  final double defaultPlantSpacingCm;
  final List<ProtocolStep> steps;

  // Ekim mevsimi bilgisi (Türkiye'de)
  final String sowingSeasonTR;
  final String idealRegionsTR;

  const CropProtocol({
    required this.cropKey,
    required this.displayName,
    required this.emoji,
    required this.totalDays,
    required this.defaultRowSpacingCm,
    required this.defaultPlantSpacingCm,
    required this.steps,
    required this.sowingSeasonTR,
    required this.idealRegionsTR,
  });
}

// ═══════════════════════════════════════════════════════════════════════════════
// 🌻 AYÇIÇEĞI — Helianthus annuus — 120 GÜN
// Kaynak: TZOB Ayçiçeği Tarım Rehberi + Trakya Tarımsal Araştırma Enstitüsü
// ═══════════════════════════════════════════════════════════════════════════════

const _aycicegi = CropProtocol(
  cropKey: 'aycicegi',
  displayName: 'Ayçiçeği',
  emoji: '🌻',
  totalDays: 120,
  defaultRowSpacingCm: 70,
  defaultPlantSpacingCm: 25,
  sowingSeasonTR: 'Nisan–Mayıs (toprak sıcaklığı en az 10°C)',
  idealRegionsTR: 'Trakya, İç Anadolu, Marmara',
  steps: [
    ProtocolStep(
      order: 1,
      dayOffset: 0,
      stageEmoji: '🌱',
      title: 'Toprak Hazırlığı ve Ekim',
      description:
          'Sonbahar sürümü + ilkbahar diskaro yapılmış, ekim yatağı hazır. '
          'Sıra arası mesafeyi tarlanın eğimine göre ayarla. '
          'Tohum ekim derinliği 5 cm — nem olan toprağa, kuru toprağa ekme. '
          'Dekara 2–2.5 kg sertifikalı hibrit tohum kullan (Sanbro, P64LE99, ES Bella).',
      expectedActivity: ActivityType.planting,
      soilNotes: {
        'clay':
            'Drenaj kritik: sıra aralarına 30 cm derinliğinde sığ hendek aç. '
            'Ekim öncesi 3 ton/da çiftlik gübresi karıştır — toprağı gevşetir.',
        'sandy':
            'Ekim öncesi 3–4 ton/da kompost veya yanmış ahır gübresi işle. '
            'Tohum derinliğini 4 cm\'de tut — nem daha hızlı uçar.',
        'loamy':
            'İdeal toprak. Ekim yatağını diskaro ile 15 cm işle, clod (topak) bırakma.',
        'volcanic':
            'pH 6.0–7.0 aralığında olmalı. Yüksekse ekimden 3 hafta önce '
            'dekara 15 kg tarımsal kireç serp ve diskaro ile karıştır.',
      },
      irrigationNotes: {
        'drip':
            'Lateralleri döşe (sıra üstü), her bitkiye 1 adet damlatıcı. '
            'Çimlenme için 2 L/bitki can suyu ver.',
        'furrow':
            'Ekimden önce sıra aralarına hafif karık aç; '
            'ekim sonrası %60 debi ile 20 dk kısa sulama yap.',
        'sprinkler':
            'Ekim sonrası 15 mm üniform sulama. Toprağı su basmadan ıslat.',
        'hand':
            'Her sıra uzunluğuna yavaşça 8–10 L su ver, toprak suyu emene kadar bekle.',
      },
      fertilizerSpec:
          'Taban gübre (ekimle birlikte, tohumla temas ettirme):\n'
          '• 15 kg/da DAP (18-46-0) — fosfor ihtiyacı\n'
          '• 5 kg/da K₂SO₄ — potasyum temel doz\n'
          'Uygulama: tohum sıralarının 5 cm yanına ve 5 cm altına.',
      pesticideSpec:
          'Tohumluk ilaçlama (tohumlar satın alınmamışsa):\n'
          '• Thiram + Carbathiin karışımı — 200 g / 100 kg tohum\n'
          '• İmidakloprid (tel kurdu için) — 100 g / 100 kg tohum\n'
          'Fabrika ilaçlı tohumda gerek yok.',
      estimatedCostPerDekar: 480,
      criticalWarning:
          'Ekim derinliği KESİNLİKLE 5 cm olmalı! '
          'Daha sığ → kuşlar yer, daha derin → çimlenme %30 düşer. '
          'Ekim mibzerini her 50 m\'de bir kontrol et.',
      farmerTip:
          'Çekirdeği toprağa dik bas, yatık değil — çimlenme hızı %20 artar. '
          'İzole edilmiş veya sertifikalı tohum kullan; piyasa tohumunda çimlenme garantisi yok.',
      commonMistake:
          'Taban gübre ile tohum aynı çiziye atılırsa gübre tuzları kök yakar. '
          'Kesinlikle yan-alta uygulaması yap.',
    ),

    ProtocolStep(
      order: 2,
      dayOffset: 8,
      stageEmoji: '🔍',
      title: 'Çimlenme Kontrolü',
      description:
          'Tohumlar 7–12 günde toprak yüzeyini kırar. '
          'Sıra boyunca say: 10 tohum başına kaç tanesi çimlenmiş? '
          '%70 üstünde ise normal, altındaysa 3. güne kadar bekle sonra yedek ekim yap.',
      soilNotes: {
        'clay':
            'Yüzey kabuklaşmıştı? Hafif tırmık veya çapa ile 2 cm sığ çek — '
            'fideler yüzeyi daha kolay kırar.',
        'sandy':
            'Toprak hızlı kurudu mu kontrol et. 5 cm derinliğe parmak sok — '
            'serinlik yoksa hafif can suyu gerekiyor.',
        'volcanic':
            'Volkanik toprakta çimlenme 2–3 gün gecikebilir; panikle yedek ekim yapma.',
      },
      irrigationNotes: {
        'drip': 'Toprak nemini %50–60 bandında tut. Altına düşmüş ise 1 L/bitki/gün ekle.',
        'hand': 'Çimlenmeyen yerler varsa etkilenen tohumun yanına (5 cm) yavaşça 300 mL su damla.',
      },
      estimatedCostPerDekar: 0,
      criticalWarning:
          'Çimlenme %60 altındaysa gün 12\'ye kadar bekle, sonra '
          'boş yerlere yedek tohum ek. 12. güne kadar tohumun kendisi kazanabilir.',
      farmerTip:
          'Gece sıcaklığı 8°C altına düştüyse don stresi olabilir. '
          'Sabah erkenden tarlaya gir — fideler sararmış veya bükülmüşse koruyucu kapak (agril) ört.',
      commonMistake:
          '10. günden önce yedek ekim yapmak — iki mahsul birbirine karışır, '
          'seyreltme güçleşir ve tarla düzensizleşir.',
    ),

    ProtocolStep(
      order: 3,
      dayOffset: 14,
      stageEmoji: '✂️',
      title: 'Seyreltme — Bitki Sıklığını Ayarla',
      description:
          'Fideler 2–4 yapraklı (kotiledon hariç) dönemde seyrelt. '
          'Her ocakta en güçlü 1 fideyi bırak, diğerlerini dibinden kopar (çekme). '
          'Hedef bitki sıklığı: sıra arası × bitki arası mesafene göre '
          'dekarda 5.000–6.000 bitki (dar aralıklarda daha az).',
      soilNotes: {
        'clay': 'Seyreltme sonrası kök boğazını toprağa hafif gömülü bırak — rüzgar devirmez.',
        'sandy': 'Sökülen fideler organik madde sağlar; çukura göm ve üstünü toprakla kapat.',
      },
      irrigationNotes: {
        'drip': 'Seyreltme günü sulama yapma — ıslak toprak köklerin birlikte gelmesine neden olur.',
        'furrow': 'Seyreltmeden 2 gün önce sulama yaptıysan zemin hâlâ ıslak; 1 gün bekle.',
      },
      estimatedCostPerDekar: 90,
      farmerTip:
          'Sağlıklı seyreltme fidelerini küçük ayrı bir parsele şaşırt. '
          'Tarlada doldurmak zorunda kalırsan hazır fide olur.',
      commonMistake:
          '4 yapraktan büyük fidelerin seyreltilmesi kök hasarı yaratır ve '
          'bırakılan bitkiyi de etkiler. Zamanında yap!',
    ),

    ProtocolStep(
      order: 4,
      dayOffset: 20,
      stageEmoji: '🌿',
      title: 'Herbisit Uygulaması — Yabancı Ot',
      description:
          'Yabancı otlar besin rekabeti yaratır; bu dönem kritik. '
          'İlaçlamadan önce tarladaki yabancı ot türünü belirle: '
          'dar yapraklı mı (ayrık otu, yulaf) yoksa geniş yapraklı mı (sirken, horoz ibiği)?',
      pesticideSpec:
          'Dar yapraklı yabancı ota karşı:\n'
          '• Fluazifop-P-butyl (ör. Fusilade Forte) — 100–125 mL/da, 200 L su\n\n'
          'Geniş yapraklı yabancı ota karşı:\n'
          '• Imazethapyr (ör. Scepter O.T.) — 50 mL/da, 200 L su\n\n'
          'Karışık varsa iki ürün birlikte kullanılabilir (etiket kontrolü zorunlu).',
      estimatedCostPerDekar: 180,
      criticalWarning:
          'İlaçlamadan 48 saat önce ve sonra yağış olmamalı — etkinlik sıfıra iner. '
          'Rüzgar hızı 10 km/s üstünde ise ASLA ilaçlama yapma: '
          'sürükleme (drift) komşu bitkiye zarar verir.',
      farmerTip:
          'Sabah çiğ kalktıktan 2 saat sonra ilaçla — öğlen sıcağında ilaç buharlaşır, '
          'etkinlik düşer. En ideal saat 08:00–11:00.',
      commonMistake:
          'Aynı herbisit etken maddesini 3 yıl üst üste kullanmak direnç geliştiriyor. '
          'Her sezon farklı etken madde grubuna geç (rotasyon).',
    ),

    ProtocolStep(
      order: 5,
      dayOffset: 25,
      stageEmoji: '🏺',
      title: 'İlk Çapa + Birinci Üst Gübre (Üre)',
      description:
          'Mekanik yabancı ot temizliği + azot desteği. '
          'Çapa ile sıra aralarını işle, toprağı havalandır. '
          'Üreyi sıra kenarlarına (bitkiden 10–15 cm uzak) serp ve hemen toprakla karıştır.',
      soilNotes: {
        'clay': 'Çapa derinliği max 8 cm — daha derin kök hasarı. Topak yüzey kırılmasını sağla.',
        'sandy': 'Çapa sonrası saman veya bitkisel artık ile mulçla — nemini tutsun.',
        'loamy': '10 cm çapa yapılabilir. Toprak ufalanmış ve havalanmış kalmalı.',
        'volcanic': 'Çapa sonrası toprak parçalanabilir; hafifçe bastır, erozyon önle.',
      },
      irrigationNotes: {
        'drip': 'Üreyi fertigasyonla ver: 10 kg/da üreyi 200 L suda eri, damla sisteme bas.',
        'furrow':
            'Üreyi ekimden önce sıra kenarına serp, HEMEN arkasından karık aç ve sula. '
            'Azot gazlaşma kayıp oranı %30\'a çıkabilir — gübreleme ve sulama arasında 2 saatten fazla bekleme.',
        'sprinkler': 'Üre serpildikten hemen sonra yağmurlama yap, nem taşınsın.',
        'hand': 'Üreyi toprağa karıştırdıktan sonra bitkinin kökünü ıslatacak şekilde su ver.',
      },
      fertilizerSpec:
          'Birinci üst gübre:\n'
          '• Üre (%46 N): Tınlı/Killi toprak → 12 kg/da | Kumlu toprak → 10 kg/da (bölünmüş doz)\n'
          'Not: Gübre kuru toprağa uygulanırsa amonyak olarak uçar — sulama şart.',
      estimatedCostPerDekar: 220,
      criticalWarning:
          'Gübre uygulandıktan sonra 6 saat içinde sulama yapılmazsa '
          'azotun %20–30\'u amonyak olarak havaya karışır. Gübreleme günü mutlaka sula!',
      farmerTip:
          'Gübreyi bitkinin hemen dibine değil 10 cm uzağa serp — '
          'tuz konsantrasyonu kök yakabilir.',
      commonMistake:
          'Rüzgarlı havada üre serpmek — gübre komşunun tarlasına gider. '
          'Sakin, nem oranı yüksek sabah saatlerinde uygula.',
    ),

    ProtocolStep(
      order: 6,
      dayOffset: 45,
      stageEmoji: '💧',
      title: 'Vejetatif Büyüme — Sulama ve Fungusit',
      description:
          'Bitki hızlı büyüme döneminde; kök sistemi derinleşiyor. '
          'Bu dönemde su stresi bitki boyunu ve tabla büyüklüğünü doğrudan etkiler. '
          'Sulama aralığına dikkat et — toprak tipine göre farklılık var.',
      soilNotes: {
        'clay': '15–18 günde bir sula. Tava sulama YAPMA; kök çürüklüğü riski yüksek. Karık tercih et.',
        'sandy': '8–10 günde bir sula. Toprak nem tutmuyor, sık kontrol et.',
        'loamy': '12–14 günde bir sula. İdeal sulama periyodu.',
        'volcanic': '10–12 günde bir sula. Toprak ısınma hızı yüksek; sabah sulama kritik.',
      },
      irrigationNotes: {
        'drip': '2 L/bitki/gün. Yavaş ve sürekli; 6–8 saatlik fraksiyonlar.',
        'furrow': '35–45 dakika karık sulaması. Sabah 06:00–09:00 arası.',
        'sprinkler': '40 mm/seans. Sabah erken uygula — yapraklar akşama kurumuş olsun.',
        'hand': '10–15 L/bitki. Öğlen sıcağında YAPMA — yaprak yanığı.',
      },
      waterSpec: 'Toplam su ihtiyacı bu dönemde: 50–60 mm/hafta.',
      pesticideSpec:
          'İhtiyati fungusit (mildiyöye karşı):\n'
          '• Tebuconazole %25 SC — 60–80 mL/da, 200 L su\n'
          '• Bitki 30–40 cm boyunda uygula\n'
          '• Yağmur sonrası 48 saat içinde tekrarla',
      estimatedCostPerDekar: 195,
      criticalWarning:
          'Öğlen 13:00–16:00 arası sulama yapma — yaprak yanığı oluşur. '
          'Sulama fiyatının yüksek olduğu bölgelerde sabah 06:00\'ı tercih et.',
      farmerTip:
          'Sıcaklık 30°C üstüne çıktığında sulama miktarını %20 artır. '
          'Buharlaşma kayıpları bu dönemde zirvede — güneş öncesi veya sonrası sul.',
      commonMistake:
          'Sulama sırasında yaprakları ıslatmak ve akşama kadar ıslak bırakmak '
          'fungal enfeksiyon için zemin hazırlar. Sabah erken sula, gün içinde kurur.',
    ),

    ProtocolStep(
      order: 7,
      dayOffset: 60,
      stageEmoji: '🌼',
      title: 'Tabla Oluşumu — Fosfat + İkinci Fungusit',
      description:
          'R1 fenolojik dönem: tabla tomurcuğu görünür. '
          'Bu dönem fosforsuz geçirilirse tabla küçük kalır, tane dolumu zayıflar. '
          'Bitki boyu 60–90 cm arasında olmalı — gelişim düşükse gübrelemeyi artır.',
      soilNotes: {
        'clay': 'Fosforu toprağın kilden salınması yavaş; fertigasyon veya üst gübre olarak ver.',
        'sandy': 'Fosfor yıkanabilir; bölünmüş doz ver (yarısı şimdi, yarısı 10 gün sonra).',
      },
      irrigationNotes: {
        'drip': '2.5 L/bitki/gün\'e çıkar. Bu dönem su ihtiyacı %25 artar.',
        'furrow': 'Sulama süresini 40–50 dakikaya uzat.',
        'sprinkler': '50 mm/seans.',
        'hand': '15–20 L/bitki. 10 günde bir.',
      },
      fertilizerSpec:
          'İkinci üst gübre:\n'
          '• DAP (18-46-0): 8 kg/da VEYA MAP (12-61-0): 6 kg/da\n'
          '• Potasyum eksikliği belirtisi varsa (yaprak kenarları kahverengi): 5 kg/da K₂SO₄ ekle\n'
          '• Uygulama: sıra kenarına serp + sulama',
      pesticideSpec:
          'Kurşuni küf ve tabla çürüklüğüne karşı:\n'
          '• Propiconazole %25 EC — 50–60 mL/da, 200 L su\n'
          '• 7–10 günde bir tekrarla (tabla kahverengi noktalar alınca ilaçlama kritik)',
      estimatedCostPerDekar: 340,
      criticalWarning:
          'Tabla büyüklüğünün %70\'i bu dönemde belirlenir. '
          'Su veya besin stresi şimdi yaşanırsa hasat sonu %40\'a kadar verim kaybı olabilir.',
      farmerTip:
          'Tabla görününce sahaya gir, kurumuş yaprak veya gri/pembe renkli tabla ara — '
          'Botrytis (kurşuni küf) işareti. Görürsen hemen Iprodione ile ilaçla.',
      commonMistake:
          'Fosfatı çok geç vermek (tablo oluştuktan sonra). '
          'Bu gübrenin etkisi toprağa alımdan 7–10 gün sonra bitki tarafından kullanılır.',
    ),

    ProtocolStep(
      order: 8,
      dayOffset: 75,
      stageEmoji: '🌻',
      title: 'Çiçeklenme — KRİTİK Sulama Dönemi',
      description:
          'Sarı taç yapraklar açıldı — en hassas fenolojik dönem. '
          'Bu dönemde tek günlük su stresi bile dane dolumunu %15–20 düşürebilir. '
          'Arı pollinasyonu akşam 08:00–12:00 arasında gerçekleşir — sulama saatine DİKKAT.',
      soilNotes: {
        'clay': 'Sulama sonrası toprak yüzeyinde çatlak varsa sulama azalmış demek. Aralığı kıs.',
        'sandy': 'Bu dönem günlük sulama gerekebilir. 5 cm derinlikte nem kontrolü yap.',
      },
      irrigationNotes: {
        'drip': '3 L/bitki/gün. Sabah 06:00–10:00 arasında ver, çiçeklenme saatine denk getirme.',
        'furrow': '50–60 dakika. 7–8 günde bir. Karıkların başlarını kontrol et — tıkanmış olabilir.',
        'sprinkler': '60 mm/seans. Sabah 10:00–12:00 arası KESİNLİKLE YAPMA — arı aktivitesine zarar.',
        'hand': '20–25 L/bitki. Sabah 06:00–08:00 arası. Tablaya doğrudan su değdirme.',
      },
      pesticideSpec:
          'Botrytis (tabla çürüklüğü) için:\n'
          '• Iprodione %50 WP — 100–150 g/da, 200 L su\n'
          '• 10 günde bir uygula, tablayı da ıslat\n'
          '• Yağmur bekleniyorsa 24 saat içinde uygula',
      estimatedCostPerDekar: 260,
      criticalWarning:
          '⚠️ SABAH 10:00–12:00 ARASI SULAMA YAPMA! '
          'Arılar bu saatte çiçeği tozlar. Yağmurlama veya elle sulama çiçek tozunu '
          'yıkar, pollinasyon engellenir → tane bağlama %40 düşer.',
      farmerTip:
          'Yakınına kovan yerleştirme teklifi için arıcıyla anlaş. '
          'Yeterli pollinasyon tabla başına 1.000–1.200 dane garanti eder.',
      commonMistake:
          'Su kesintisi ya da aşırı sulama bu dönemde eşit zararlı. '
          'Nem fazlası da tabla çürüklüğünü tetikler — denge şart.',
    ),

    ProtocolStep(
      order: 9,
      dayOffset: 100,
      stageEmoji: '🍂',
      title: 'Olgunlaşma — Suyu Kes',
      description:
          'Tablalar eğilmeye başladı, sarı-kahverengi renge dönüyor. '
          'Bu dönem fazla nem tanelerin küflenmesine yol açar. '
          'Tane nemi %15\'in altına indi mi? Parmakla test et: tırnakla sert mi?',
      soilNotes: {
        'clay': 'Killi toprakta nem uzun süre kalır; suyu 10 gün erken kes.',
        'sandy': 'Kumlu toprak hızlı kurur; 5–7 gün önce su kes.',
      },
      estimatedCostPerDekar: 0,
      criticalWarning:
          'Tabla arka yüzü %80 kahverengi olduktan sonra su kesilmeli. '
          'Geç sulamak tane içinde küf ve çürüme garantisi.',
      farmerTip:
          'Tane nem ölçer yoksa çivi testini uygula: tane yarısından kestiğinde '
          'içi hamurumsu değil, sertsek hasat zamanı yaklaşıyor.',
      commonMistake:
          'Erken hasat: tane nemi %20 üstündeyken harmanlarsanız depolama çürümesi kaçınılmaz. '
          'Tarlada 3–5 gün daha beklemeye değer.',
    ),

    ProtocolStep(
      order: 10,
      dayOffset: 115,
      stageEmoji: '🌾',
      title: 'Hasat — Tabla Sert, Dane Hazır',
      description:
          'Tabla arka yüzü sarı-kahverengi, taneler sert ve parlak. '
          'Hasatı makine ile yapıyorsan tabla nem ölçümü %12–14 olmalı. '
          'Elle hasatta: tablaları orakla kes, 3–5 gün açık havada kurutucu örtü altında kuruye bırak, sonra harmanla.',
      pesticideSpec:
          'Preharvest interval: Son ilaçlamadan bu yana en az 14 gün geçmiş olmalı. '
          'Hasat öncesi pestisit uygulaması YAPMA.',
      estimatedCostPerDekar: 350,
      criticalWarning:
          'Tablalar olgunlaşınca kuş hasarı hızlanır. '
          'Ağ gererek veya tablaları kâğıt torbaya sararak koruma altına al.',
      farmerTip:
          'Hasat edilen tablalar nemli ortamda bırakılırsa 48 saat içinde küf başlar. '
          'Sergi alanı iyi havalanmalı; üst üste yığma.',
      commonMistake:
          'Harman sonrası tohumları çuvala koyup ıslak zeminde depolamak. '
          'Nem %13\'ün altındayken kapalı teneke veya taşıma çuvalında sakla.',
    ),
  ],
);

// ═══════════════════════════════════════════════════════════════════════════════
// 🍅 DOMATES — Solanum lycopersicum — 95 GÜN
// Kaynak: BÜGEM (Bahçe Kültürleri Araştırma Enstitüsü) + Çiftçi El Kitabı
// ═══════════════════════════════════════════════════════════════════════════════

const _domates = CropProtocol(
  cropKey: 'domates',
  displayName: 'Domates',
  emoji: '🍅',
  totalDays: 95,
  defaultRowSpacingCm: 80,
  defaultPlantSpacingCm: 50,
  sowingSeasonTR: 'Fide: Şubat–Mart (sıcaklık 20°C+) / Tarlaya: Nisan–Mayıs don riski geçince',
  idealRegionsTR: 'Akdeniz, Ege, Marmara, İç Anadolu\'nun ılıman kesimleri',
  steps: [
    ProtocolStep(
      order: 1,
      dayOffset: 0,
      stageEmoji: '🌱',
      title: 'Fide Dikimi — Doğru Derinlik ve Aralık',
      description:
          'Fideleri ilk 2 gerçek yaprak çiftine kadar (kotiledonların hemen üstüne) toprağa göm. '
          'Gömülü gövde kısmından ek adventif kök çıkar, bitki daha güçlü olur. '
          'Aralık: sıra arası 80 cm, sıra üstü 50 cm (indeterminate/sınırsız boy için). '
          'Belirgin boy çeşitlerde 40 cm yeterli.',
      expectedActivity: ActivityType.planting,
      soilNotes: {
        'clay':
            'Diken alanına kaba kum + perlit karıştır (hacmin %20\'si) — drene edemezse kök çürür. '
            'Sıralar arası yüzeyi hafif tümsek bırak, su birikmez.',
        'sandy':
            'Her dikim çukuruna bir avuç kompost veya yanmış gübre koy. '
            'İlk hafta günlük sulama — toprak nemi tutmuyor.',
        'loamy': 'İdeal toprak. Çukuru 15 cm derinliğe kaz, bitkiyi yerleştir, sıkıştır.',
        'volcanic':
            'Domates pH 6.0–6.8 ister. Önce toprak testi yaptır; '
            'pH yüksekse kükürt (S) uygula ve dolomit kireç kullan.',
      },
      irrigationNotes: {
        'drip':
            'Her bitkiye 1 adet 2 L/saat damlatıcı. Lateral üzerinden sıra ortasına konumlandır. '
            'Can suyu: 2 L/bitki, 2 saat süre.',
        'furrow': 'Dikimden 2 saat sonra kısa (15 dk) can suyu karığı aç. Gölge yap çıkışa kadar.',
        'sprinkler': '10 mm can suyu. Sabah erken.',
        'hand': 'Dikimlerin hepsine sırayla bitki başına 1.5–2 L can suyu ver.',
      },
      fertilizerSpec:
          'Dikim gübresi (çukura, kökle TEMAS ETTİRME):\n'
          '• 20 kg/da yanmış ahır gübresi (dikim öncesi toprağa karıştır)\n'
          '• 10 kg/da 15-15-15 kompoze gübre (çukurun 5 cm altına)',
      pesticideSpec:
          'Fide ilaçlaması (söküm sırasında):\n'
          '• Kök hastalıklarına: Metalaxyl — 100 g/100 L sulama suyu, dikim sonrası drench\n'
          '• Sera fideleri ise önce thrips ve yaprak biti kontrolü yap',
      estimatedCostPerDekar: 520,
      criticalWarning:
          'Don riski tamamen geçmeden KESINLIKLE tarlaya fide dikme. '
          'Bir gece -1°C dahi tüm fidelerinizi mahvedebilir. '
          'MGM uzun dönem tahminini kontrol et.',
      farmerTip:
          'Öğleden sonra saat 16:00 sonrasında dik — güneşin şiddetinden yeni fideler stres almaz. '
          'İlk 3 gün öğlen gölgeleme örtüsü (agril) koy.',
      commonMistake:
          'Fideyi çok sığ dikmek (sadece kök toprağını bırakmak). '
          'Gövdeyi toprağa gömmezsen ek kök çıkmaz, bitki zayıf kalır.',
    ),

    ProtocolStep(
      order: 2,
      dayOffset: 2,
      stageEmoji: '💧',
      title: 'Can Suyu — İlk Sulama',
      description:
          'Dikimden 1–2 gün sonra kök stabilizasyonu için hafif sulama. '
          'Bitkinin etrafındaki toprağı sıkıştır, hava boşlukları kök kurumasına yol açar.',
      expectedActivity: ActivityType.watering,
      irrigationNotes: {
        'drip': 'Damla sistemi 2 saat aç: 2 L/bitki can suyu. Yavaş emilsin.',
        'furrow': 'Kısa karık (10 dk). Su brikip durunca kes — göl yaratma.',
        'sprinkler': '8 mm. Köklerin yerleşmesine yardımcı olur.',
        'hand': 'Bitki başına 1.5 L. Yaprakları ISLATMA. Kök bölgesine damlatarak ver.',
      },
      estimatedCostPerDekar: 0,
      farmerTip:
          'Sıcaklık 28°C üstünde ise fideler günde iki kez kontrol et. '
          'Yapraklar solar gibi olunca hemen su ver.',
      commonMistake:
          'Aşırı sulama ilk günlerde kök çürüklüğü (Pythium) başlatır. '
          'Toprak ıslak kalmasın, sadece nemli olsun.',
    ),

    ProtocolStep(
      order: 3,
      dayOffset: 14,
      stageEmoji: '🏗️',
      title: 'Herek Dik veya İp Çek',
      description:
          'Bitki 25–35 cm boya geldiğinde destek zorunlu. '
          'Seçenek 1: Her bitkinin yanına 1.5–2 m ahşap herek çak, 8 şekli ile bağla. '
          'Seçenek 2: Sıra üstüne telden geçir, bitkiyi iplik ile sardır (Hollanda sistemi). '
          'Bağlamayı gövde yumuşak dokuya bastırmadan yap.',
      soilNotes: {
        'clay': 'Killi toprakta herek çakmak zorsa önce demir çubukla delik aç.',
        'sandy': 'Kumlu toprakta hereği daha derin çak (en az 40 cm) — rüzgar devirir.',
      },
      estimatedCostPerDekar: 120,
      farmerTip:
          'Herek için baklagilden kesilen dut, kavak veya metal çubuklar kullan. '
          'Ahşap herekler sezon sonu yakılırsa hastalık toprakta kalmaz.',
      commonMistake:
          'Bağlamayı gövdeye sıkı yapmak boğma yaratır, su ve besin iletimi durur. '
          '8 şekli bırak — hem bitkiye hem hereğe destek verir.',
    ),

    ProtocolStep(
      order: 4,
      dayOffset: 21,
      stageEmoji: '🏺',
      title: 'İlk Çapa + Kompoze Gübre',
      description:
          'Yabancı ot temizliği + besin desteği. '
          '5–8 cm derinliğinde çapa yap, kök bölgesine zarar verme. '
          'Gübreyi bitkinin kök boğazından 10 cm uzağa serp, toprağa karıştır.',
      soilNotes: {
        'clay': 'Çapadan sonra toprak oluşan tabakayı kır — yüzey çatlağı suyu yönteme sokuyor.',
        'sandy': '15-15-15\'i bölünmüş doz ver (yarısı şimdi, yarısı 2 hafta sonra).',
        'loamy': 'Normal doz yeterli. Çapa 8 cm derinlikte.',
        'volcanic': 'Kompoze gübre eğer pH\'ı daha da yükseltirse sülfatlı gübre tercih et.',
      },
      irrigationNotes: {
        'drip': '15-15-15\'i 200 L suda eritip fertigasyon olarak ver.',
        'furrow': 'Gübre serpildikten hemen sonra karık sulaması (20 dk) — nem taşısın.',
        'sprinkler': 'Gübre sonrası yağmurlama yap.',
        'hand': 'Gübreyi toprağa karıştırdıktan sonra kök bölgesini ıslat.',
      },
      fertilizerSpec:
          'Birinci üst gübre:\n'
          '• 15-15-15 Kompoze: 25–30 g/bitki (≈ 15 kg/da)\n'
          '• Mikronütrien eksikliği varsa (yaprak sararma): 1 kg/da Zn-Fe karışımı sprey',
      estimatedCostPerDekar: 185,
      criticalWarning:
          'Bu dönemde Fusarium veya Verticillium (sarılma) hastalığı başlayabilir. '
          'Yapraklar aşağıdan sararıp soluyorsa HEMEN hastalık teşhisi yaptır.',
      farmerTip:
          'Çapa yapılmış toprak üstüne 3–5 cm saman veya kuru ot mulçu serdikten sonra '
          'nem uzun süre tutulur, yabancı ot baskılanır.',
      commonMistake:
          'Çapa sırasında köklere zarar vermek — domates yüzeysel kök atar, çok derine çapayı götürme.',
    ),

    ProtocolStep(
      order: 5,
      dayOffset: 35,
      stageEmoji: '🌿',
      title: 'Koltuk Alma — Yan Filiz Koparma',
      description:
          'Yaprak koltuklarından çıkan yan sürgünleri (obur dal) elle veya bıçakla kopar. '
          'Kural: 1 gövde (indeterminate çeşit) → tek büyük dal bırak + ana gövde. '
          'Gövde kalınsa makasla kes (dezenfekte edilmiş makasla — Virüs bulaşmasın).',
      estimatedCostPerDekar: 95,
      criticalWarning:
          'Kesim yapılan alet kirli ise Tomato Mosaic Virus (ToMV) tüm tarlaya yayılır. '
          'Her bitkiden sonra makası %70 alkol veya çamaşır suyuyla sil.',
      farmerTip:
          'Koltuk almayı yağmurlu veya nemli günlerde YAPMA — '
          'yara yerleri hızlı enfekte olur. Kuru, güneşli sabah saatlerini seç.',
      commonMistake:
          'Çok büyüdükten sonra sürgün kesmek büyük yara açar ve bitki enerji kaybeder. '
          '5–8 cm uzadığında koparılacak.',
    ),

    ProtocolStep(
      order: 6,
      dayOffset: 45,
      stageEmoji: '🌸',
      title: 'Çiçeklenme — Kalsiyum + Düzenli Sulama',
      description:
          'Sarı çiçekler açıldı. Bu dönem kalsiyum eksikliğinde '
          '"çiçek burnu çürüklüğü" (blossom end rot) kaçınılmaz. '
          'Meyve bağlamak için çiçek silkme yapabilirsin (domateste öz pollinasyon; elle salla).',
      soilNotes: {
        'clay': 'Kalsiyum killi topraklarda yavaş alınır — yaprak spreyini tercih et.',
        'sandy': 'Kalsiyum kumlu topraktan yıkanır. Haftada bir yaprağa sprey yap.',
        'volcanic':
            'Volkanik toprakta yüksek Magnezyum, Kalsiyum alımını bloke edebilir. '
            'Kalsiyum nitrat damla sulamayla ver.',
      },
      irrigationNotes: {
        'drip': '2 L/bitki/gün. Düzenli aralık şart — sulama tutarsızlığı çatlamaya neden olur.',
        'furrow': '20–25 dakika, 7–8 günde bir. Düzenli ol.',
        'sprinkler': '30 mm/seans. Yaprakların akşama kadar kuruyacağı saatte uygula.',
        'hand': '10–12 L/bitki, günde bir. Kök bölgesine.',
      },
      fertilizerSpec:
          'Kalsiyum takviyesi:\n'
          '• Kalsiyum nitrat [Ca(NO₃)₂]: 150–200 g / 100 L sulama suyu (damla)\n'
          '  VEYA yaprak spreyı: %0.3 Ca(NO₃)₂ çözeltisi, hafta 1–2 kez\n'
          '• Potasyum nitrat (KNO₃): 100 g/100 L — meyve kalitesi için',
      pesticideSpec:
          'Erken külleme önlemi:\n'
          '• Azoxystrobin %25 SC — 80 mL/da, 10 günde bir\n'
          '• Kırmızı örümcek varsa: Abamectin %1.8 EC — 75 mL/da',
      estimatedCostPerDekar: 220,
      criticalWarning:
          'Sulama tutarsızlığı (önce kuraklık + sonra aşırı sulama) '
          'meyve çatlaması ve burnu çürüklüğü ikisine birden zemin hazırlar. '
          'Aralığı standart tut!',
      farmerTip:
          'Çiçek silkme için sabah 10:00–12:00 arası bitki gövdesine hafifçe vur. '
          'Çiçekler kendiliğinden tozlaşır, meyve tutumu artar.',
      commonMistake:
          'Kalsiyum gübre tek seferlik uygulamak yetersiz kalır. '
          'Haftada bir yaprağa spray + damla sisteme karıştır — ikisi birlikte daha etkili.',
    ),

    ProtocolStep(
      order: 7,
      dayOffset: 55,
      stageEmoji: '🔬',
      title: 'Koruyucu Fungusit + Zararlı Kontrolü',
      description:
          'Meyve tutumundan hasada kadar mantar ve böcek baskısı kritik. '
          'Mildiyö (Phytophthora infestans) yağmurlu dönemde patlamadan önce ilaçla. '
          'Haftada bir tarla içini gez, yaprak altına bak.',
      soilNotes: {
        'clay': 'Nem killi toprakta uzun kalır; Phytophthora riski yüksek. Önlemli ilaçla.',
        'sandy': 'Kırmızı örümcek kuru ve sıcak topraklarda hızlı çoğalır; alt yapraklara dikkat.',
      },
      irrigationNotes: {
        'drip': 'Yapraklar ıslak olmaz — fungal baskı düşer. Yine de koruyucu ilaç at.',
        'sprinkler': 'Yapraklar sık ıslanır — her ilaçlama arasını 7 güne indir.',
        'hand': 'Su yaprak üstüne değiyorsa akşamüstü değil sabah sula.',
      },
      pesticideSpec:
          'Mildiyöye karşı (koruyucu):\n'
          '• Bakır oksiklorür %50 WP — 250–300 g/da, 7–10 günde bir\n'
          '  VEYA Mankozeb + Metalaxyl — 200–250 g/da\n\n'
          'Kırmızı örümcek için:\n'
          '• Bifenazate %24 SC — 60–80 mL/da\n\n'
          'Beyaz sinek için:\n'
          '• Spirotetramat %15 OD — 60 mL/da',
      estimatedCostPerDekar: 280,
      criticalWarning:
          'İlaçlamayı 3 günden fazla erteleyen her çiftçi ortalama %20 verim kaybeder. '
          'Mildiyö gördükten sonra ilaçlarsanız çok geç — ÖNCE ilaçla.',
      farmerTip:
          'Düzenli bir not defteri tut: ilaç adı, tarihi, hangi ürünü kullandın. '
          'Hem etkinliği takip edersin hem ruhsat sorunlarında delil olur.',
      commonMistake:
          'Aynı etken maddeyi her seferinde uygulamak direnç yaratır. '
          'Farklı kimyasal grupları dönüşümlü kullan.',
    ),

    ProtocolStep(
      order: 8,
      dayOffset: 70,
      stageEmoji: '🔴',
      title: 'Meyve Olgunlaşması — Sulamayı Azalt',
      description:
          'Meyveler renk almaya başladı. '
          'Aşırı sulama bu dönemde meyveyi sulandırır (Brix değeri düşer), çatlatır. '
          'Sulama aralığını artır ama kesme — nem stresi tat arttırır ama aşırı düşünce meyve küçülür.',
      irrigationNotes: {
        'drip': '1.5 L/bitki/gün\'e indir.',
        'furrow': 'Sulama aralığını 12–14 güne uzat.',
        'sprinkler': '20 mm/seans. Yeterli.',
        'hand': '8 L/bitki, 10 günde bir.',
      },
      estimatedCostPerDekar: 0,
      farmerTip:
          'Meyve üretimi için ideal Brix değeri 5–6. '
          'Küçük refraktometre ile meyve suyunu ölç. '
          '4\'ün altındaysa sulamayı biraz kıs.',
      commonMistake:
          'Renk almış meyveler için sulamayı tamamen kesmek '
          'meyve dökülmesine ve şok olgunlaşmaya neden olur.',
    ),

    ProtocolStep(
      order: 9,
      dayOffset: 85,
      stageEmoji: '🍅',
      title: 'Hasat — Kırmızılaşan Meyveleri Topla',
      description:
          'Meyveler tam kırmızı (veya çeşide göre sarı/pembe) olunca hafifçe çevirerek sap üstünden topla. '
          '3–4 günde bir hasat yap — bitkide kalırsa aşırı olgunlaşır ve sap altındaki meyvelerin büyümesi durur. '
          'Toplanmayan meyveler bütün bitkiyi "yıkmaya" başlar.',
      pesticideSpec: 'Son ilaçlamadan bu yana 14+ gün geçmiş olmalı. Meyve kalıntı kontrolü.',
      estimatedCostPerDekar: 400,
      criticalWarning:
          'Piyasaya götürmeden önce bekleteceğin meyveler yeşil-pembe dönemde topla, '
          'depoda olgunlaştır. Tam kırmızı hasat 2 günlük raf ömrü verir.',
      farmerTip:
          'Sabah serin saatlerde hasat yap — meyve sıcak iken toplandığında soğuk zincirde bile bozulma hızlıdır. '
          'Gölgede geçici saklama yeri kur.',
      commonMistake:
          'Hasadı haftalarca ertelemek — bitkinin üst kısmındaki meyveler küçük kalır. '
          'Sık ve düzenli hasat toplam verim artırır.',
    ),
  ],
);

// ═══════════════════════════════════════════════════════════════════════════════
// 🌽 MISIR — Zea mays — 110 GÜN
// Kaynak: TARSUS Tarımsal Araştırma Enstitüsü + FAO Mısır Üretim Kılavuzu
// ═══════════════════════════════════════════════════════════════════════════════

const _misir = CropProtocol(
  cropKey: 'misir',
  displayName: 'Mısır',
  emoji: '🌽',
  totalDays: 110,
  defaultRowSpacingCm: 70,
  defaultPlantSpacingCm: 20,
  sowingSeasonTR: 'Nisan sonu – Mayıs (toprak sıcaklığı 12°C üstü, don riski bitmiş)',
  idealRegionsTR: 'Akdeniz (2. ürün), Karadeniz (1. ürün), Çukurova, İç Anadolu',
  steps: [
    ProtocolStep(
      order: 1,
      dayOffset: 0,
      stageEmoji: '🌱',
      title: 'Ekim — Sıra ve Derinlik Hassasiyeti',
      description:
          'Mısır toprağı ısındıktan (12°C) sonra ekilir; '
          'soğuk toprak çimlenmeyi geciktirir ve çökerten hastalığını tetikler. '
          'Sıra arası 70 cm, bitki arası 20 cm → dekarda 7.000–7.500 bitki. '
          'Dane mısır için 60 cm × 20 cm tercih edilebilir.',
      expectedActivity: ActivityType.planting,
      soilNotes: {
        'clay':
            'Ekim öncesi mutlaka ara sürüm veya diskaro yap — kabuklanmış killi toprak '
            'çimlenmeyi engeller. Drenaj kanalı açmayı unutma.',
        'sandy':
            'Ekim derinliği 5 cm\'de tut. Nem tutamayan kumlu toprakta 6 cm derin ekim '
            'tohumun neme ulaşmasını sağlar.',
        'loamy': 'İdeal. Pulluktan sonra diskaro, ardından ekim. 5 cm derinlik standart.',
        'volcanic':
            'pH kontrolü: 5.8–7.0 arası mısır için ideal. Dışarı çıkıyorsa kireç uygula.',
      },
      irrigationNotes: {
        'drip': 'Lateralleri sıra üstüne kur. Ekim sonrası 2 L/m² can suyu.',
        'furrow': 'Ekim sonrası kısa karık (15–20 dk). Tohumun üstü ıslansın.',
        'sprinkler': '15 mm. Toprağı suyla gömmeden ıslat.',
        'hand': 'Sıra başına 10 L, yavaşça ver. Su birikmeden emilsin.',
      },
      fertilizerSpec:
          'Taban gübre (ekimle aynı sıraya DEĞIL, 5 cm yan/alt):\n'
          '• DAP (18-46-0): 20 kg/da — fosfor + azot temeli\n'
          '• K₂SO₄: 8 kg/da — potasyum\n'
          '• Çinko sülfat (ZnSO₄): 2 kg/da — mısır çinkoya hassas',
      pesticideSpec:
          'Tohum ilaçlaması (fabrika işlenmemişse):\n'
          '• Tel kurdu: Imidacloprid 600 FS — 6 mL/kg tohum\n'
          '• Çökerten (Pythium/Fusarium): Thiram + Metalaxyl — 3 g/kg tohum',
      estimatedCostPerDekar: 430,
      criticalWarning:
          'Çinko eksikliği mısırda verim düşürür ve karakteristik solgun beyaz şerit oluşturur. '
          'Taban gübreye mutlaka 2 kg/da ZnSO₄ ekle.',
      farmerTip:
          'Ekimden önce toprak sıcaklığını ölç (basit termometre, sabah 07:00, 10 cm derinlik). '
          '10°C\'nin altında iken ek meyvede çimlenme kaybı yaşarsın.',
      commonMistake:
          'Çok erken ekim: toprak soğuk, çimlenme yavaş, toprak kaynaklı hastalıklar saldırır. '
          'Hava güzel görünse de toprak sıcaklığı asıl kriter.',
    ),

    ProtocolStep(
      order: 2,
      dayOffset: 10,
      stageEmoji: '🔍',
      title: 'Çimlenme Kontrolü — Boşlukları Doldur',
      description:
          'Tohumlar 7–12 günde çıkar. Sıra boyu say: '
          '10 bitkiden 8\'i çıkmışsa (%80) normal. '
          'Boş kalan yerlere aynı mısır çeşidinden yedek tohum at. '
          '3. günden sonra ekilen yedek bitkiler özgün bitkiler kadar verim vermez ama boşluk kapar.',
      soilNotes: {
        'clay': 'Kabuklanma varsa yüzeyi hafif tırmıkla — fidelerin çıkışını kolaylaştır.',
        'sandy':
            'Toprak hızlı kuruyorsa nem eksikliğinden çimlenme yavaş. '
            'Hafif can suyu ver, suya gömme.',
        'volcanic': 'Volkanik toprakta çimlenme 2 gün geç olabilir; sabret.',
      },
      estimatedCostPerDekar: 0,
      criticalWarning:
          'Karga/güvercin hasarı bu dönemde çok ciddi. '
          'Çıkmayan yerlere bakmadan önce tarlayı baştan tara — kuşlar tohumu söküp yemişse '
          'acil tedbir (korkuluk, ses cihazı, ağ) al.',
      farmerTip:
          'İlk 3 yapraklı dönem (V3) bitkinin en hassas zamanı. '
          'Herbisit, gübre, her türlü stres bu dönemde zarar verir.',
    ),

    ProtocolStep(
      order: 3,
      dayOffset: 20,
      stageEmoji: '🏺',
      title: 'İlk Çapa + Amonyum Sülfat',
      description:
          'V3–V5 dönemi (3–5 yapraklı bitki). '
          'Sıra aralarını çapala, yabancı ot temizle. '
          'Amonyum sülfat bitki dibine serp ve toprağa karıştır. '
          'Bu dönem mısırın tüm vejetatif büyümesi için azot kritik.',
      soilNotes: {
        'clay': 'Amonyum sülfat nem çekici; çapa sonrası toprağa karışmazsa yüzeyde kalır ve kaybolur.',
        'sandy':
            'Kumlu toprakta azot hızla yıkanır. Bölünmüş doz ver: '
            'yarısı şimdi, yarısı 10 gün sonra.',
        'loamy': 'Standart doz. Gübre serpip toprakla karıştır.',
        'volcanic': 'pH\'a bağlı azot uygunluğunu kontrol et. Yüksek pH\'ta üre daha iyi çözünür.',
      },
      irrigationNotes: {
        'drip': 'Amonyum sülfatı eritip fertigasyon olarak ver — daha hızlı alım.',
        'furrow': 'Gübre serpildikten sonra hemen karık aç ve sula.',
        'sprinkler': 'Gübre sonrası yağmurlama (10 mm) — taşıma için.',
        'hand': 'Gübre toprakla karıştıktan sonra kök bölgesini ıslat.',
      },
      fertilizerSpec:
          'Birinci üst gübre:\n'
          '• Amonyum sülfat (%21 N): 25 kg/da\n'
          '  VEYA Üre (%46 N): 12 kg/da (eşdeğer azot)\n'
          'Not: V3\'te aşırı doz vurursanız yaprak yanığı olur.',
      pesticideSpec:
          'Dar yapraklı yabancı ot: Nicosulfuron (ör. Milagro) — 125 mL/da (V2–V6 arası)\n'
          'Geniş yapraklı: Atrazine 500 SC — 300 mL/da (post-emergence, V1–V3)',
      estimatedCostPerDekar: 210,
      criticalWarning:
          'V3\'ten önce herbisit atmak fideciklere zarar verir. '
          'V6\'dan sonra Nicosulfuron mısırda büyük verim kaybı yaratır. '
          'Zamanlama çok kritik!',
      farmerTip:
          'Mısır büyüdükçe sıra aralarına girmek zorlaşır. '
          'Bu son gübre ve çapa fırsatın; sonraki gübreyi traktörle yapman gerekecek.',
      commonMistake:
          'Amonyum sülfatı nemli toprakta bırakmak ve sulamayı ertelemek — '
          'yüzeyde kristal oluşur, azot buharlaşır.',
    ),

    ProtocolStep(
      order: 4,
      dayOffset: 35,
      stageEmoji: '⛏️',
      title: 'Boğaz Doldurma + İlk Sulama',
      description:
          'V8–V10 dönemi: bitki bel hizasına geldi. '
          'Traktörle sıra aralarını işle, kök boğazına toprak çek (boğaz doldurma). '
          'Bu işlem kök gelişimini hızlandırır ve bitki devrilmesini önler. '
          'Ardından ilk karık sulama — 10–12 gün arayla sürdür.',
      soilNotes: {
        'clay': 'Boğaz doldurma sırasında nem varsa traktör çıkmazsa bekle — sıkışmış kil kök çürütür.',
        'sandy': 'Boğaz doldurmayı bol toprağı yüksek tut — kumlu toprak çabuk kayar.',
        'loamy': 'İdeal. Boğaz yüksekliği 10–15 cm.',
        'volcanic': 'Serbest yapılı volkanik toprakta boğaz kolay yıkılır; sıkıştırarak çek.',
      },
      irrigationNotes: {
        'drip': 'İlk uzun sulama: 4–5 L/bitki/gün, 3 gün üst üste. Sonra 2 günde bir 3 L.',
        'furrow': '40–45 dakika karık sulaması. 10–12 günde bir.',
        'sprinkler': '50 mm/seans. Sabah erken.',
        'hand': '15 L/bitki. Karık usulü değilse bitkinin etrafına yavaşça dök.',
      },
      estimatedCostPerDekar: 150,
      farmerTip:
          'Bu dönemde mısır "geceyarısı büyür" — sabah erkenden tarlaya git, boyun kaç cm arttığını say. '
          '3 cm/gün altındaysa besin veya nem eksikliği var.',
      commonMistake:
          'Sulamayı ya da boğaz doldurmayı geç bırakmak bitki toprağa tutunamamış demek — '
          'fırtına veya rüzgarda devrilme riski yüksek.',
    ),

    ProtocolStep(
      order: 5,
      dayOffset: 50,
      stageEmoji: '🌾',
      title: 'Tepe Püskülü Öncesi — Üre Takviyesi',
      description:
          'V14–V16 dönemi: tepe kısmı görünüyor ama püskül çıkmadı. '
          'Bu mısır bitkisinin azota en yüksek ihtiyaç duyduğu dönem. '
          'Üst gübre ver; traktörle sıra arası değil, sıra üstünden serp.',
      soilNotes: {
        'clay': 'Üreyi toprağa karıştır, serbest bırakma.',
        'sandy': 'Üre yerine CAN (Kalsiyum Amonyum Nitrat) kullan — yıkanmaya karşı dirençli.',
        'loamy': 'Standart üre. Sulama öncesi ver.',
        'volcanic': 'Sulama anındaki fertigasyon en etkili yöntem.',
      },
      irrigationNotes: {
        'drip': 'Üreyi damla sistemine vermen bu dönemin en verimli gübreleme şekli.',
        'furrow': 'Gübre serp, hemen sulama — 48 saat bekletme.',
        'sprinkler': 'Gübre + yağmurlama kombinasyonu ideal.',
        'hand': '20 L/bitki. Gübre toprakla karışmadan önce su verme.',
      },
      fertilizerSpec:
          'İkinci üst gübre:\n'
          '• Üre (%46 N): 15 kg/da\n'
          '  VEYA CAN (%26 N): 25 kg/da\n'
          'Bu dönemde azot eksikliği koçan büyüklüğünü ve dane sayısını DOĞRUDAN düşürür.',
      estimatedCostPerDekar: 185,
      criticalWarning:
          'Tepe püskülü dönemi azot eksikliğinin en görünür belirtisi: '
          'alt yapraklar sarı şeritli (V şekli). Belirtileri görürsen dozu artır!',
      farmerTip:
          'Bu dönemde toprak analizi yaptırırsan bir sonraki sezonu planlaman kolaylaşır. '
          'Tarım İl Müdürlüğü ücretsiz analiz yapıyor.',
      commonMistake:
          'Gübreyi püskül çıkışından sonra vermek çok geç kalır — '
          'azot koçana değil yapraklara gider.',
    ),

    ProtocolStep(
      order: 6,
      dayOffset: 65,
      stageEmoji: '🌽',
      title: 'Tepe Püskülü Çıkışı — KRİTİK Sulama',
      description:
          'Sarı tepe püskülü göründü — mısırın en hassas dönemi. '
          'Püskül poleni saçtığında koçan ipekleri tam açık olmalı. '
          'Bu dönemde tek günlük su stresi koçanda 200–300 dane azalmasına neden olabilir.',
      soilNotes: {
        'clay': 'Sulama arttı — yüzey su yansımasına dikkat et, drenaj açık olsun.',
        'sandy': 'Bu dönem günlük sulama gerekebilir. Toprak nemini her sabah kontrol et.',
      },
      irrigationNotes: {
        'drip': '4 L/bitki/gün. En yoğun sulama dönemi.',
        'furrow': '55–60 dakika. 7 günde bir. Karıklar tam boydan akmalı.',
        'sprinkler': '70 mm/seans. 5–6 günde bir.',
        'hand': '25 L/bitki. Mümkünse 2 günde bir.',
      },
      estimatedCostPerDekar: 200,
      criticalWarning:
          'Sıcaklık 38°C üstüne çıkarsa polen canlılığını kaybeder — koçan dane tutmaz! '
          'Hava tahmini böyle bir sıcaklık gösteriyorsa sabah 06:00\'ta ek sulama yap.',
      farmerTip:
          'Koçan ipekleri tamamen çıktıktan 5–7 gün sonra tepe püskülünü kır — '
          'besin enerji koçana yönelir, verim artar (Türkiye\'de yaygın pratik).',
      commonMistake:
          'Rüzgarlı günlerde ilaçlama yapmak — hem bitki zarar görür hem de pollen dağılımı bozulur.',
    ),

    ProtocolStep(
      order: 7,
      dayOffset: 80,
      stageEmoji: '🥛',
      title: 'Süt Olum — Sulamayı Sürdür',
      description:
          'Koçan ipekleri kahverengileşti, taneler süt kıvamında. '
          'Bitkinin besin ve su ihtiyacı hâlâ yüksek. '
          'Danelerin dolması için sulamayı düzenli tut. '
          'Kuraklık şimdi tane boyutunu kalıcı olarak küçültür.',
      soilNotes: {
        'clay': 'Su uzun süre tutulduğu için aralığı 12–15 güne çıkarabilirsin.',
        'sandy': 'Aralık 8–10 gün. Hız kesme.',
      },
      irrigationNotes: {
        'drip': '3 L/bitki/gün\'e indir. Tane dolumu için yeterli.',
        'furrow': '45–50 dakika, 10 günde bir.',
        'sprinkler': '50 mm/seans.',
        'hand': '20 L/bitki, 8–10 günde bir.',
      },
      estimatedCostPerDekar: 0,
      farmerTip:
          'Bu dönemde bazı bölgelerde mısır kurdu (Ostrinia nubilalis) koçan içine girer. '
          'Koçan ipeklerinin dibinde siyah dışkı görürsen hemen müdahale et.',
      commonMistake:
          'Sulamayı bu dönem kesmek dane ağırlığını %20–30 düşürür. '
          '"Zaten doldu" sanıyorsun ama olgunlaşma tamamlanmadı.',
    ),

    ProtocolStep(
      order: 8,
      dayOffset: 105,
      stageEmoji: '🌾',
      title: 'Hasat — Koçan Kabukları Kuruyunca',
      description:
          'Koçan kabukları tamamen sarı-kahverengi ve kuru. '
          'Tane tırnakla bastırıldığında iz kalmıyor → hasat zamanı. '
          'Makine hasadı için tane nemi %25\'in altında olmalı; '
          'elle hasatta %30\'a kadar yapılabilir, sonra güneşte kurut.',
      pesticideSpec: 'Son ilaçlamadan 21 gün geçmeli (preharvest interval). Hasat öncesi ürün ilaçlama YOK.',
      estimatedCostPerDekar: 380,
      criticalWarning:
          'Yüksek nemde depolanan mısırda Aflatoksin (zehirli küf) riski var. '
          'Nem %14\'ün altına inmeden çuvala koyma — '
          'birkaç yüz kg mısır kolayca imha edilir.',
      farmerTip:
          'Hasattan sonra koçanları kırıp yerde bırakma — '
          'mısır kurdu ve fare yuva yapar. Tarlayı sonbaharda sür, artıkları gömülsün.',
      commonMistake:
          'Makine hasadında ayar hatalı ise koçanlar kırılır ve taneler ezilir. '
          'Hasat makinesi ayarını teknik yetkili ile yaptır.',
    ),
  ],
);

// ═══════════════════════════════════════════════════════════════════════
// ANA ERİŞİM SINIFI
// ═══════════════════════════════════════════════════════════════════════

class CropProtocols {
  static const Map<String, CropProtocol> _all = {
    'aycicegi': _aycicegi,
    'domates': _domates,
    'misir': _misir,
  };

  static List<CropProtocol> get all => _all.values.toList();

  static CropProtocol? resolveByName(String? name) {
    if (name == null || name.trim().isEmpty) return null;
    final key = _normalize(name);
    if (_all.containsKey(key)) return _all[key];
    for (final entry in _all.entries) {
      if (key.contains(entry.key)) return entry.value;
    }
    return null;
  }

  static String _normalize(String s) => s
      .toLowerCase()
      .replaceAll('ı', 'i')
      .replaceAll('ç', 'c')
      .replaceAll('ş', 's')
      .replaceAll('ğ', 'g')
      .replaceAll('ü', 'u')
      .replaceAll('ö', 'o')
      .replaceAll(RegExp(r'[^a-z]'), '');
}

// ═══════════════════════════════════════════════════════════════════════
// PROTOCOLSTEP — TARLA AKTİVİTESİYLE EŞLEŞTİRME
// activity_logs / CalendarEvents kayıtlarına göre step'in tamamlanmış,
// aktif veya gelecek olduğunu belirler. Yetiştirme rehberindeki ✓/●/○
// gösterimini bu helper'lar besler.
// ═══════════════════════════════════════════════════════════════════════

extension ProtocolStepProgress on ProtocolStep {
  DateTime expectedDateFrom(DateTime plantedDate) =>
      plantedDate.add(Duration(days: dayOffset));

  /// Bu step'e eşleşen bir aktivite log'u var mı?
  /// `activities` öğeleri en az şu alanlara sahip olmalı:
  ///   - 'eventType' (String) ya da 'type'
  ///   - 'eventDate' (ISO timestamp) ya da 'at'
  bool isCompletedFor(
    List<Map<String, dynamic>> activities,
    DateTime plantedDate,
  ) {
    if (expectedActivity == null) return false;
    final windowStart = plantedDate.add(Duration(days: dayOffset - 3));
    final windowEnd = plantedDate.add(Duration(days: dayOffset + 7));
    for (final a in activities) {
      final type = (a['eventType'] ?? a['type'])?.toString();
      if (type != expectedActivity) continue;
      final raw = a['eventDate'] ?? a['at'] ?? a['date'];
      final at = raw is DateTime
          ? raw
          : (raw is String ? DateTime.tryParse(raw) : null);
      if (at == null) continue;
      if (at.isAfter(windowStart) && at.isBefore(windowEnd)) return true;
    }
    return false;
  }

  /// Aktif step: bugünkü tarihe denk düşen veya hemen geçmişteki step.
  bool isActiveOn(DateTime plantedDate, {DateTime? now}) {
    final today = now ?? DateTime.now();
    final dayDiff = today.difference(plantedDate).inDays;
    return dayDiff >= dayOffset - 3 && dayDiff <= dayOffset + 7;
  }
}

/// CropProtocol seviyesinde toplu yardımcılar.
/// Not: `crop_protocol_service.dart`'taki `CropProtocolProgress` *sınıfı* ile
/// karışmaması için extension adı farklı tutuldu.
extension CropProtocolStepLookup on CropProtocol {
  /// Plant tarihi + aktivite log'u baz alarak şu anda aktif olan step'i bulur.
  /// Aktivite eşleşmesi olmayan, dayOffset'i bugüne en yakın olan step "aktif".
  ProtocolStep? activeStep(
    DateTime plantedDate,
    List<Map<String, dynamic>> activities, {
    DateTime? now,
  }) {
    final today = now ?? DateTime.now();
    final dayDiff = today.difference(plantedDate).inDays;
    ProtocolStep? best;
    int bestDelta = 1 << 30;
    for (final s in steps) {
      if (s.isCompletedFor(activities, plantedDate)) continue;
      final delta = (s.dayOffset - dayDiff).abs();
      if (delta < bestDelta) {
        bestDelta = delta;
        best = s;
      }
    }
    return best;
  }
}
