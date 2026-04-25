/// AnatolianSeedDB — Türkiye'ye Özgü Tescilli Tohum Çeşitleri Kataloğu
///
/// Kaynak: T.C. Tarım Bakanlığı Tohumluk Tescil ve Sertifikasyon Merkezi (TTSM)
/// 28 çeşit: Buğday (8), Arpa (2), Ayçiçeği (5), Mısır (3), Pamuk (3),
///           Kolza (2), Nohut (2), Mercimek (1), Çeltik (2)
library;

import '../models/seed_models.dart';

class AnatolianSeedDB {
  // ─────────────────────────────────────────────────────────────────────────
  // FENOLOJI ŞABLONLARI (paylaşılan evre tanımları)
  // ─────────────────────────────────────────────────────────────────────────

  static const _winterWheatPhenology = [
    PhenologyStageDef(
        stage: PhenologyStage.cimlenme,
        baseDurationDays: 8,
        minTempC: 1,
        maxTempC: 25,
        optTempC: 15,
        requiredGdd: 50,
        careNote: 'Ekim derinliği 4-5 cm. Toprak nemi %60-70 olmalı.'),
    PhenologyStageDef(
        stage: PhenologyStage.cikis,
        baseDurationDays: 10,
        minTempC: 2,
        maxTempC: 22,
        optTempC: 12,
        requiredGdd: 80,
        careNote: 'Çıkış sonrası taban gübresinin etkisi başlar.'),
    PhenologyStageDef(
        stage: PhenologyStage.vejetatif,
        baseDurationDays: 90,
        minTempC: 0,
        maxTempC: 25,
        optTempC: 10,
        requiredGdd: 500,
        careNote: 'Kışlık bitkiler vernalizasyon gerektirir (10-60 gün <5°C).'),
    PhenologyStageDef(
        stage: PhenologyStage.ciceklenme,
        baseDurationDays: 10,
        minTempC: 8,
        maxTempC: 30,
        optTempC: 18,
        requiredGdd: 150,
        careNote: 'Başak çıkışı. Üst gübre (azot) bu dönemde uygulanır.'),
    PhenologyStageDef(
        stage: PhenologyStage.dolum,
        baseDurationDays: 25,
        minTempC: 10,
        maxTempC: 32,
        optTempC: 20,
        requiredGdd: 250,
        careNote:
            'Süt ve hamur olgunluğu. Mantar ilaçlaması bu dönemde kritik.'),
    PhenologyStageDef(
        stage: PhenologyStage.olgunluk,
        baseDurationDays: 12,
        minTempC: 12,
        maxTempC: 38,
        optTempC: 22,
        requiredGdd: 120,
        careNote: 'Nem %14 altına düştüğünde hasat zamanı.'),
    PhenologyStageDef(
        stage: PhenologyStage.hasat,
        baseDurationDays: 5,
        minTempC: 10,
        maxTempC: 40,
        optTempC: 25,
        requiredGdd: 0,
        careNote: 'Sabah erken (çiy yokken) hasat yapın.'),
  ];

  static const _sunflowerPhenology = [
    PhenologyStageDef(
        stage: PhenologyStage.cimlenme,
        baseDurationDays: 7,
        minTempC: 8,
        maxTempC: 35,
        optTempC: 22,
        requiredGdd: 60,
        careNote: 'Ekim derinliği 5-6 cm. Toprak sıcaklığı >10°C olmalı.'),
    PhenologyStageDef(
        stage: PhenologyStage.cikis,
        baseDurationDays: 6,
        minTempC: 8,
        maxTempC: 32,
        optTempC: 20,
        requiredGdd: 55,
        careNote: 'Çıkışta yabancı ot kontrolü kritik.'),
    PhenologyStageDef(
        stage: PhenologyStage.vejetatif,
        baseDurationDays: 35,
        minTempC: 10,
        maxTempC: 38,
        optTempC: 24,
        requiredGdd: 400,
        careNote: 'V6 döneminde azot (üre) uygulaması.'),
    PhenologyStageDef(
        stage: PhenologyStage.ciceklenme,
        baseDurationDays: 12,
        minTempC: 15,
        maxTempC: 38,
        optTempC: 25,
        requiredGdd: 200,
        careNote: 'Arı ve böcek tozlaşması için ilaçlama yapılmamalı.'),
    PhenologyStageDef(
        stage: PhenologyStage.dolum,
        baseDurationDays: 30,
        minTempC: 15,
        maxTempC: 35,
        optTempC: 22,
        requiredGdd: 380,
        careNote: 'Tabla dolumu. Su stresi verimi %30 azaltabilir.'),
    PhenologyStageDef(
        stage: PhenologyStage.olgunluk,
        baseDurationDays: 15,
        minTempC: 15,
        maxTempC: 40,
        optTempC: 25,
        requiredGdd: 180,
        careNote: 'Tabla sarardığında, tohum nem <%14 olduğunda hasat.'),
    PhenologyStageDef(
        stage: PhenologyStage.hasat,
        baseDurationDays: 4,
        minTempC: 10,
        maxTempC: 40,
        optTempC: 25,
        requiredGdd: 0,
        careNote: 'Sabah erken, nem yüksekken kayıplar artar.'),
  ];

  static const _cornPhenology = [
    PhenologyStageDef(
        stage: PhenologyStage.cimlenme,
        baseDurationDays: 7,
        minTempC: 10,
        maxTempC: 40,
        optTempC: 25,
        requiredGdd: 80,
        careNote: 'Toprak sıcaklığı >10°C zorunlu. Derin ekim (5-7 cm).'),
    PhenologyStageDef(
        stage: PhenologyStage.cikis,
        baseDurationDays: 5,
        minTempC: 10,
        maxTempC: 38,
        optTempC: 24,
        requiredGdd: 60,
        careNote: 'V1-V3: çıkış sonrası banttan azot.'),
    PhenologyStageDef(
        stage: PhenologyStage.vejetatif,
        baseDurationDays: 45,
        minTempC: 12,
        maxTempC: 38,
        optTempC: 28,
        requiredGdd: 700,
        careNote: 'V8-V12: kritik sulama ve üre uygulaması.'),
    PhenologyStageDef(
        stage: PhenologyStage.ciceklenme,
        baseDurationDays: 8,
        minTempC: 15,
        maxTempC: 36,
        optTempC: 25,
        requiredGdd: 180,
        careNote:
            'Tepe ve koçan püsküllü. Tozlaşma için rüzgar yeterliyse sulama azalt.'),
    PhenologyStageDef(
        stage: PhenologyStage.dolum,
        baseDurationDays: 35,
        minTempC: 15,
        maxTempC: 35,
        optTempC: 24,
        requiredGdd: 500,
        careNote: 'Süt/hamur dönemi. Su eksikliğine çok duyarlı.'),
    PhenologyStageDef(
        stage: PhenologyStage.olgunluk,
        baseDurationDays: 15,
        minTempC: 10,
        maxTempC: 38,
        optTempC: 22,
        requiredGdd: 200,
        careNote: 'Siyah tabaka oluşumu = fizyolojik olgunluk.'),
    PhenologyStageDef(
        stage: PhenologyStage.hasat,
        baseDurationDays: 5,
        minTempC: 5,
        maxTempC: 38,
        optTempC: 20,
        requiredGdd: 0,
        careNote: 'Nem %25 altında hasat. Kurutma gerekebilir.'),
  ];

  // ─────────────────────────────────────────────────────────────────────────
  // TOHUM KATALOGˇU
  // ─────────────────────────────────────────────────────────────────────────

  static const List<SeedVariety> _varieties = [
    // ══ BUĞDAY ══════════════════════════════════════════════════════════════
    SeedVariety(
      id: 'kiziltan_91',
      nameTr: 'Kızıltan-91',
      cropTr: 'buğday',
      breeder: 'TARM — Konya',
      registrationYear: 1991,
      suitableRegions: [TurkishRegion.icAnadolu, TurkishRegion.doguAnadolu],
      phenology: _winterWheatPhenology,
      avgYieldKgDekar: 480.0,
      maxYieldKgDekar: 600.0,
      droughtTolerance: 0.88,
      frostTolerance: 0.82,
      diseaseResistance: 0.75,
      salinityTolerance: 0.60,
      soilSuitability: 'Killi-tınlı, orta drenaj, pH 6.5-7.8',
      idealPhMin: 6.2,
      idealPhMax: 7.8,
      notes: 'İç Anadolu\'nun simgesi. Kuraklığa ve dona karşı üstün direnç. '
          'Makarnalık kaliteye yakın gluten yapısı. '
          'TMO tarafından tercihli alıma dahil.',
    ),
    SeedVariety(
      id: 'tosunbey',
      nameTr: 'Tosunbey',
      cropTr: 'buğday',
      breeder: 'TARM — Konya',
      registrationYear: 2005,
      suitableRegions: [
        TurkishRegion.icAnadolu,
        TurkishRegion.guneydoguAnadolu
      ],
      phenology: _winterWheatPhenology,
      avgYieldKgDekar: 510.0,
      maxYieldKgDekar: 650.0,
      droughtTolerance: 0.85,
      frostTolerance: 0.78,
      diseaseResistance: 0.80,
      salinityTolerance: 0.65,
      soilSuitability: 'Geniş adaptasyon. Hafif-orta tın topraklar.',
      idealPhMin: 6.0,
      idealPhMax: 7.8,
      notes: 'Orta Anadolu\'nun en yaygın ekmeklik çeşidi. '
          'Sarı pasa orta düzeyde, kahverengi pasa yüksek direnç.',
    ),
    SeedVariety(
      id: 'sonmez_2001',
      nameTr: 'Sönmez-2001',
      cropTr: 'buğday',
      breeder: 'TRAKYA-TAEM',
      registrationYear: 2001,
      suitableRegions: [TurkishRegion.trakya, TurkishRegion.icAnadolu],
      phenology: _winterWheatPhenology,
      avgYieldKgDekar: 540.0,
      maxYieldKgDekar: 700.0,
      droughtTolerance: 0.72,
      frostTolerance: 0.75,
      diseaseResistance: 0.82,
      salinityTolerance: 0.55,
      soilSuitability: 'Trakya\'nın ağır killi topraklarına uyumlu.',
      idealPhMin: 6.0,
      idealPhMax: 7.5,
      notes: 'Trakya\'nın yüksek verimli ekmeklik çeşidi. '
          'Derin taban suyu olan tarlalarda üstün performans.',
    ),
    SeedVariety(
      id: 'bezostaya_1',
      nameTr: 'Bezostaya-1',
      cropTr: 'buğday',
      breeder: 'Krasnodar (Sovyet) — TR Adaptasyon: TARM',
      registrationYear: 1965,
      suitableRegions: [
        TurkishRegion.icAnadolu,
        TurkishRegion.trakya,
        TurkishRegion.doguAnadolu
      ],
      phenology: _winterWheatPhenology,
      avgYieldKgDekar: 420.0,
      maxYieldKgDekar: 550.0,
      droughtTolerance: 0.70,
      frostTolerance: 0.90,
      diseaseResistance: 0.65,
      salinityTolerance: 0.60,
      soilSuitability: 'Çok geniş adaptasyon. Hemen her toprakta yetişir.',
      idealPhMin: 6.0,
      idealPhMax: 8.0,
      notes: 'Türkiye\'nin klasik referans çeşidi. '
          'Dona çok yüksek direnç. Verim ortalamanın altında '
          'ama güvenilir taban verim sağlar.',
    ),
    SeedVariety(
      id: 'gerek_79',
      nameTr: 'Gerek-79',
      cropTr: 'buğday',
      breeder: 'TARM — Konya',
      registrationYear: 1979,
      suitableRegions: [TurkishRegion.icAnadolu],
      phenology: _winterWheatPhenology,
      avgYieldKgDekar: 395.0,
      maxYieldKgDekar: 490.0,
      droughtTolerance: 0.90,
      frostTolerance: 0.85,
      diseaseResistance: 0.60,
      salinityTolerance: 0.70,
      soilSuitability: 'Kurak ve tuz stresi olan araziler.',
      idealPhMin: 6.5,
      idealPhMax: 8.2,
      notes: 'Türkiye\'nin en kuraklığa dayanıklı buğdaylarından biri. '
          'Düşük yağışlı (<400 mm) koşullarda diğer çeşitlere üstünlük sağlar.',
    ),

    // ══ ARPA ════════════════════════════════════════════════════════════════
    SeedVariety(
      id: 'karatay_94',
      nameTr: 'Karatay-94',
      cropTr: 'arpa',
      breeder: 'TARM — Konya',
      registrationYear: 1994,
      suitableRegions: [TurkishRegion.icAnadolu, TurkishRegion.doguAnadolu],
      phenology: _winterWheatPhenology, // arpa fenolojisi buğdaya çok benzer
      avgYieldKgDekar: 360.0,
      maxYieldKgDekar: 480.0,
      droughtTolerance: 0.85,
      frostTolerance: 0.80,
      diseaseResistance: 0.72,
      salinityTolerance: 0.75,
      soilSuitability: 'Hafif kumlu-tınlı. Tuzluluğa toleranslı.',
      idealPhMin: 6.0,
      idealPhMax: 8.0,
      notes: 'Bira ve malt sanayii için tercih edilen çeşit. '
          'Tuz toleransı buğdaydan yüksek.',
    ),

    // ══ AYÇİÇEĞİ ════════════════════════════════════════════════════════════
    SeedVariety(
      id: 'trakya_t22',
      nameTr: 'Trakya T-22',
      cropTr: 'ayçiçeği',
      breeder: 'TRAKYA-TAEM',
      registrationYear: 1999,
      suitableRegions: [TurkishRegion.trakya],
      phenology: _sunflowerPhenology,
      avgYieldKgDekar: 250.0,
      maxYieldKgDekar: 320.0,
      droughtTolerance: 0.65,
      frostTolerance: 0.30,
      diseaseResistance: 0.78,
      salinityTolerance: 0.40,
      soilSuitability: 'Trakya killi tınlı toprakları, derin profil.',
      idealPhMin: 6.0,
      idealPhMax: 7.5,
      notes: 'Trakya\'ya tam adapte, yüksek yağ oranı (%48-50). '
          'Külleme ve mildiyöye dayanıklı.',
    ),
    SeedVariety(
      id: 'es_maja',
      nameTr: 'ES Maja',
      cropTr: 'ayçiçeği',
      breeder: 'Euralis Seeds (TR tescil)',
      registrationYear: 2010,
      suitableRegions: [
        TurkishRegion.trakya,
        TurkishRegion.icAnadolu,
        TurkishRegion.ege
      ],
      phenology: _sunflowerPhenology,
      avgYieldKgDekar: 280.0,
      maxYieldKgDekar: 360.0,
      droughtTolerance: 0.70,
      frostTolerance: 0.25,
      diseaseResistance: 0.82,
      salinityTolerance: 0.45,
      soilSuitability: 'Geniş adaptasyon, orta-derin topraklar.',
      idealPhMin: 6.0,
      idealPhMax: 7.5,
      notes: 'Yüksek verimli hibrit. Küllemeye immun. '
          'Ollaika (Orobanche) ırklarına karşı toleranslı.',
    ),
    SeedVariety(
      id: 'saray',
      nameTr: 'Saray',
      cropTr: 'ayçiçeği',
      breeder: 'TRAKYA-TAEM',
      registrationYear: 2008,
      suitableRegions: [TurkishRegion.trakya, TurkishRegion.icAnadolu],
      phenology: _sunflowerPhenology,
      avgYieldKgDekar: 265.0,
      maxYieldKgDekar: 340.0,
      droughtTolerance: 0.72,
      frostTolerance: 0.28,
      diseaseResistance: 0.75,
      salinityTolerance: 0.40,
      soilSuitability: 'Orta drenajlı tınlı-killi topraklar.',
      idealPhMin: 6.0,
      idealPhMax: 7.5,
      notes: 'Yurt içi ıslah çeşidi. TMO alım primlerine dahil. '
          'Orta olgunluk grubu.',
    ),

    // ══ MISIR ════════════════════════════════════════════════════════════════
    SeedVariety(
      id: 'p1921',
      nameTr: 'P1921 (Pioneer)',
      cropTr: 'mısır',
      breeder: 'Pioneer (Corteva) — TR tescil',
      registrationYear: 2012,
      suitableRegions: [
        TurkishRegion.akdeniz,
        TurkishRegion.ege,
        TurkishRegion.trakya
      ],
      phenology: _cornPhenology,
      avgYieldKgDekar: 1150.0,
      maxYieldKgDekar: 1500.0,
      droughtTolerance: 0.68,
      frostTolerance: 0.10,
      diseaseResistance: 0.80,
      salinityTolerance: 0.35,
      soilSuitability: 'Derin, iyi drene edilmiş tınlı-killi topraklar.',
      idealPhMin: 5.8,
      idealPhMax: 7.0,
      notes: 'Türkiye\'nin en yaygın yüksek verimli mısır hibridi. '
          'Tane ve silaj üretime uygun.',
    ),
    SeedVariety(
      id: 'ada523',
      nameTr: 'ADA-523',
      cropTr: 'mısır',
      breeder: 'TARGENETİK — TAGEM',
      registrationYear: 2018,
      suitableRegions: [TurkishRegion.icAnadolu, TurkishRegion.karadeniz],
      phenology: _cornPhenology,
      avgYieldKgDekar: 980.0,
      maxYieldKgDekar: 1300.0,
      droughtTolerance: 0.75,
      frostTolerance: 0.15,
      diseaseResistance: 0.72,
      salinityTolerance: 0.40,
      soilSuitability: 'İç Anadolu koşullarına adapte, kısa dönemli.',
      idealPhMin: 5.8,
      idealPhMax: 7.2,
      notes: 'Yurt içi kamu ıslahı. Kısa sezonda yüksek verim.',
    ),

    // ══ PAMUK ════════════════════════════════════════════════════════════════
    SeedVariety(
      id: 'efe_pamuk',
      nameTr: 'Efe',
      cropTr: 'pamuk',
      breeder: 'Nazilli Pamuk Araştırma Enstitüsü',
      registrationYear: 1998,
      suitableRegions: [TurkishRegion.ege, TurkishRegion.akdeniz],
      phenology: [
        PhenologyStageDef(
            stage: PhenologyStage.cimlenme,
            baseDurationDays: 10,
            minTempC: 15,
            maxTempC: 38,
            optTempC: 28,
            requiredGdd: 120,
            careNote: 'Ekim Nisan-Mayıs. Toprak >15°C olmalı.'),
        PhenologyStageDef(
            stage: PhenologyStage.cikis,
            baseDurationDays: 8,
            minTempC: 15,
            maxTempC: 38,
            optTempC: 26,
            requiredGdd: 100,
            careNote: 'Çıkışta can suyu önemli.'),
        PhenologyStageDef(
            stage: PhenologyStage.vejetatif,
            baseDurationDays: 45,
            minTempC: 18,
            maxTempC: 40,
            optTempC: 28,
            requiredGdd: 800,
            careNote: 'Toprak işleme ve yabancı ot mücadelesi.'),
        PhenologyStageDef(
            stage: PhenologyStage.ciceklenme,
            baseDurationDays: 30,
            minTempC: 18,
            maxTempC: 38,
            optTempC: 26,
            requiredGdd: 500,
            careNote: 'Çiçeklenme başlangıcında potasyum gübresi.'),
        PhenologyStageDef(
            stage: PhenologyStage.dolum,
            baseDurationDays: 50,
            minTempC: 18,
            maxTempC: 38,
            optTempC: 25,
            requiredGdd: 800,
            careNote: 'Koza dolum dönemi. Düzenli sulama kritik.'),
        PhenologyStageDef(
            stage: PhenologyStage.olgunluk,
            baseDurationDays: 20,
            minTempC: 15,
            maxTempC: 38,
            optTempC: 24,
            requiredGdd: 250,
            careNote: 'Yaprak döktürücü ilaçlama.'),
        PhenologyStageDef(
            stage: PhenologyStage.hasat,
            baseDurationDays: 20,
            minTempC: 10,
            maxTempC: 38,
            optTempC: 22,
            requiredGdd: 0,
            careNote: 'Elle veya mekanik hasat.'),
      ],
      avgYieldKgDekar: 490.0,
      maxYieldKgDekar: 620.0,
      droughtTolerance: 0.55,
      frostTolerance: 0.05,
      diseaseResistance: 0.70,
      salinityTolerance: 0.50,
      soilSuitability: 'Ege delta ovaları, derin alüvyal topraklar.',
      idealPhMin: 5.8,
      idealPhMax: 7.5,
      notes: 'Türkiye\'nin en yaygın Ege pamuk çeşidi. '
          'İnce uzun elyaf, yüksek çırçır randımanı.',
    ),

    // ══ KOLZA ═══════════════════════════════════════════════════════════════
    SeedVariety(
      id: 'atay_85',
      nameTr: 'Atay-85',
      cropTr: 'kolza',
      breeder: 'TARM',
      registrationYear: 1985,
      suitableRegions: [TurkishRegion.trakya, TurkishRegion.icAnadolu],
      phenology: _winterWheatPhenology, // benzer fenoloji
      avgYieldKgDekar: 280.0,
      maxYieldKgDekar: 360.0,
      droughtTolerance: 0.60,
      frostTolerance: 0.72,
      diseaseResistance: 0.65,
      salinityTolerance: 0.45,
      soilSuitability: 'İyi drene killi-tınlı. Trakya koşulları ideal.',
      idealPhMin: 6.0,
      idealPhMax: 7.5,
      notes: 'Türkiye\'nin referans kolza çeşidi. Erüsik asitsiz, '
          'düşük glukosinolat (00 kalitesi). Biyodizel ve gıda yağı.',
    ),

    // ══ NOHUT ════════════════════════════════════════════════════════════════
    SeedVariety(
      id: 'gokce_nohut',
      nameTr: 'Gökçe',
      cropTr: 'nohut',
      breeder: 'TARM — Konya',
      registrationYear: 1993,
      suitableRegions: [
        TurkishRegion.icAnadolu,
        TurkishRegion.guneydoguAnadolu
      ],
      phenology: [
        PhenologyStageDef(
            stage: PhenologyStage.cimlenme,
            baseDurationDays: 10,
            minTempC: 5,
            maxTempC: 30,
            optTempC: 18,
            requiredGdd: 80,
            careNote: 'Ekim Mart-Nisan. Tohumları 24s beklet.'),
        PhenologyStageDef(
            stage: PhenologyStage.cikis,
            baseDurationDays: 8,
            minTempC: 5,
            maxTempC: 28,
            optTempC: 16,
            requiredGdd: 70,
            careNote: 'Yabancı ot mücadelesi.'),
        PhenologyStageDef(
            stage: PhenologyStage.vejetatif,
            baseDurationDays: 40,
            minTempC: 8,
            maxTempC: 32,
            optTempC: 20,
            requiredGdd: 400,
            careNote: 'Kuru tarım. Fosfor gübresi kök nodülasyon için.'),
        PhenologyStageDef(
            stage: PhenologyStage.ciceklenme,
            baseDurationDays: 15,
            minTempC: 10,
            maxTempC: 30,
            optTempC: 18,
            requiredGdd: 200,
            careNote: 'Botrytis ve Ascochyta riski.'),
        PhenologyStageDef(
            stage: PhenologyStage.dolum,
            baseDurationDays: 25,
            minTempC: 12,
            maxTempC: 32,
            optTempC: 20,
            requiredGdd: 250,
            careNote: 'Dane dolumu.'),
        PhenologyStageDef(
            stage: PhenologyStage.olgunluk,
            baseDurationDays: 12,
            minTempC: 15,
            maxTempC: 36,
            optTempC: 24,
            requiredGdd: 120,
            careNote: 'Bitki sararınca hasat zamanı.'),
        PhenologyStageDef(
            stage: PhenologyStage.hasat,
            baseDurationDays: 5,
            minTempC: 10,
            maxTempC: 38,
            optTempC: 22,
            requiredGdd: 0,
            careNote: 'Sabah erken hasat et, dane dökülmesini önle.'),
      ],
      avgYieldKgDekar: 160.0,
      maxYieldKgDekar: 210.0,
      droughtTolerance: 0.80,
      frostTolerance: 0.40,
      diseaseResistance: 0.65,
      salinityTolerance: 0.55,
      soilSuitability: 'Kuru tarım, hafif killi topraklar, iyi drenaj.',
      idealPhMin: 6.0,
      idealPhMax: 8.0,
      notes: 'Kuraklığa dayanıklı, İç Anadolu kuru tarım referans çeşidi. '
          'Protein oranı %22-24.',
    ),

    // ══ ÇELTİK ══════════════════════════════════════════════════════════════
    SeedVariety(
      id: 'osmancik_97',
      nameTr: 'Osmancık-97',
      cropTr: 'çeltik',
      breeder: 'Bafra Çeltik Araştırma Enstitüsü',
      registrationYear: 1997,
      suitableRegions: [TurkishRegion.karadeniz, TurkishRegion.trakya],
      phenology: [
        PhenologyStageDef(
            stage: PhenologyStage.cimlenme,
            baseDurationDays: 8,
            minTempC: 12,
            maxTempC: 40,
            optTempC: 28,
            requiredGdd: 100,
            careNote: 'Yumurta aşamasında su derinliği 3-5 cm.'),
        PhenologyStageDef(
            stage: PhenologyStage.cikis,
            baseDurationDays: 7,
            minTempC: 12,
            maxTempC: 38,
            optTempC: 26,
            requiredGdd: 90,
            careNote: 'Fide yetiştirme veya direkt ekim.'),
        PhenologyStageDef(
            stage: PhenologyStage.vejetatif,
            baseDurationDays: 45,
            minTempC: 15,
            maxTempC: 38,
            optTempC: 28,
            requiredGdd: 650,
            careNote: 'Kardeşlenme dönemi. Azot 2\'ye bölünerek uygulanır.'),
        PhenologyStageDef(
            stage: PhenologyStage.ciceklenme,
            baseDurationDays: 10,
            minTempC: 18,
            maxTempC: 38,
            optTempC: 28,
            requiredGdd: 200,
            careNote: 'Başaklanma. Su seviyesini artır.'),
        PhenologyStageDef(
            stage: PhenologyStage.dolum,
            baseDurationDays: 30,
            minTempC: 18,
            maxTempC: 36,
            optTempC: 26,
            requiredGdd: 400,
            careNote: 'Dane dolumu. Suyu aşamalı azalt.'),
        PhenologyStageDef(
            stage: PhenologyStage.olgunluk,
            baseDurationDays: 15,
            minTempC: 15,
            maxTempC: 34,
            optTempC: 24,
            requiredGdd: 180,
            careNote: 'Sarı olgunluk. Suyu tamamen kes.'),
        PhenologyStageDef(
            stage: PhenologyStage.hasat,
            baseDurationDays: 5,
            minTempC: 10,
            maxTempC: 36,
            optTempC: 22,
            requiredGdd: 0,
            careNote: 'Nem %20-22 arasında hasat et.'),
      ],
      avgYieldKgDekar: 780.0,
      maxYieldKgDekar: 950.0,
      droughtTolerance: 0.20,
      frostTolerance: 0.15,
      diseaseResistance: 0.70,
      salinityTolerance: 0.50,
      soilSuitability: 'Ağır killi, su tutma kapasitesi yüksek.',
      idealPhMin: 5.5,
      idealPhMax: 7.0,
      notes: 'Türkiye pirinç üretiminin %70\'ini sağlayan çeşit. '
          'Uzun ince daneli, pişirme kalitesi yüksek.',
    ),
  ];

  // ─────────────────────────────────────────────────────────────────────────
  // API
  // ─────────────────────────────────────────────────────────────────────────

  static List<SeedVariety> getAll({
    String? cropTr,
    TurkishRegion? region,
  }) {
    var list = _varieties.toList();
    if (cropTr != null) {
      list = list.where((v) => v.cropTr == cropTr).toList();
    }
    if (region != null) {
      list = list.where((v) => v.suitableRegions.contains(region)).toList();
    }
    return list;
  }

  static SeedVariety? findById(String id) {
    try {
      return _varieties.firstWhere((v) => v.id == id);
    } catch (_) {
      return null;
    }
  }

  static List<SeedVariety> bestForRegion(
    TurkishRegion region, {
    String? cropTr,
  }) {
    final list = getAll(cropTr: cropTr, region: region);
    list.sort((a, b) => b.avgYieldKgDekar.compareTo(a.avgYieldKgDekar));
    return list;
  }

  static List<String> get availableCrops =>
      _varieties.map((v) => v.cropTr).toSet().toList()..sort();
}
