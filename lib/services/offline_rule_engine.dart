/// Offline Rule Engine — Çevrimdışı Kural Motoru
///
/// **MİMARİ NOT:** Bu dosya backend'deki `rule_engine.py`'nin **çevrimdışı
/// aynasıdır**. İş kurallarının kanonik sahibi backend'dir; istemci öncelikle
/// `BackendService` üzerinden `/api/analyze/*` endpointlerini çağırmalıdır.
/// Bu motor yalnızca ağ erişiminin mümkün olmadığı durumlarda fallback
/// olarak çalışır (CLAUDE.md: "Çevrimdışı-öncelikli, indefinite loading yasak").
///
/// Kural değişikliklerinde backend `rule_engine.py` ile birebir parite şart.
library;

enum RiskLevel {
  critical, // 🔴 Acil müdahale
  warning, // 🟡 Dikkat
  info, // 🔵 Bilgi
  ok, // 🟢 Normal
}

enum RuleCategory {
  disease, // Hastalık / mantar / bakteri
  pest, // Zararlı
  irrigation, // Sulama
  soil, // Toprak
  weather, // Hava
  season, // Mevsim / ekim zamanı
  compatibility, // Bitki-tarla uyumu
  harvest, // Hasat
}

class RuleResult {
  final RiskLevel level;
  final RuleCategory category;
  final String title;
  final String message;
  final String recommendation;

  const RuleResult({
    required this.level,
    required this.category,
    required this.title,
    required this.message,
    required this.recommendation,
  });

  String get emoji {
    switch (level) {
      case RiskLevel.critical:
        return '🔴';
      case RiskLevel.warning:
        return '🟡';
      case RiskLevel.info:
        return '🔵';
      case RiskLevel.ok:
        return '🟢';
    }
  }

  String get categoryLabel {
    switch (category) {
      case RuleCategory.disease:
        return 'Hastalık';
      case RuleCategory.pest:
        return 'Zararlı';
      case RuleCategory.irrigation:
        return 'Sulama';
      case RuleCategory.soil:
        return 'Toprak';
      case RuleCategory.weather:
        return 'Hava';
      case RuleCategory.season:
        return 'Mevsim';
      case RuleCategory.compatibility:
        return 'Uyum';
      case RuleCategory.harvest:
        return 'Hasat';
    }
  }

  Map<String, dynamic> toMap() => {
        'level': level.name,
        'category': category.name,
        'title': title,
        'message': message,
        'recommendation': recommendation,
        'emoji': emoji,
        'category_label': categoryLabel,
      };
}

// ─────────────────────────────────────────────────────────────────────────────
// ANA MOTOR
// ─────────────────────────────────────────────────────────────────────────────

class OfflineRuleEngine {
  /// Tam analiz — tüm kategorileri çalıştırır.
  static List<RuleResult> analyze({
    String commonName = '', // Türkçe bitki adı (Domates, Buğday…)
    String scientificName = '', // Latince
    Map<String, dynamic> plantDetails = const {}, // Perenual / cache verisi
    double temperature = 20.0, // °C anlık
    double avgWeeklyTemp = 20.0, // °C haftalık ort.
    double humidity = 60.0, // % anlık
    double weeklyRain = 15.0, // mm/hafta
    double soilPh = 6.8, // 0-14
    double soilMoisture = 0.25, // 0-1 (AgroMonitoring)
    double soilTempC = 15.0, // °C
    double ndvi = 0.6, // 0-1 (AgroMonitoring; 0=ölü, 1=sağlıklı)
    double windSpeed = 3.0, // m/s
    int month = 6, // 1-12
    double precipProbNext3h = 0.0, // % (0-100)
  }) {
    final results = <RuleResult>[];
    final name = commonName.toLowerCase();

    results.addAll(_weatherRules(temperature, avgWeeklyTemp, humidity,
        weeklyRain, windSpeed, precipProbNext3h));
    results.addAll(_irrigationRules(ndvi, soilMoisture, weeklyRain,
        precipProbNext3h, plantDetails, temperature));
    results.addAll(_diseaseRules(
        name, temperature, humidity, weeklyRain, soilMoisture, month));
    results.addAll(_pestRules(name, temperature, humidity, windSpeed, month));
    results.addAll(_soilRules(soilPh, soilTempC, plantDetails, month));
    results.addAll(_seasonRules(name, month, plantDetails));
    results.addAll(_compatibilityRules(temperature, avgWeeklyTemp, soilPh,
        weeklyRain, humidity, plantDetails));
    results.addAll(_harvestRules(name, plantDetails));

    // Sırala: critical → warning → info → ok
    results.sort((a, b) => a.level.index.compareTo(b.level.index));
    return results;
  }

  // ── 1. HAVA KURALLARI ──────────────────────────────────────────────────────

  static List<RuleResult> _weatherRules(
    double temp,
    double avgTemp,
    double humidity,
    double weeklyRain,
    double wind,
    double precipProb,
  ) {
    final r = <RuleResult>[];

    // DON RİSKİ
    if (temp <= 0) {
      r.add(const RuleResult(
        level: RiskLevel.critical,
        category: RuleCategory.weather,
        title: 'Don Riski — Kritik',
        message: 'Sıcaklık 0°C\'nin altına düştü. Don olayı gerçekleşiyor.',
        recommendation:
            'Hassas bitkilerinizi hemen örtün. Seraların ısıtma sistemlerini devreye alın. Meyve ağaçları için baca yakın.',
      ));
    } else if (temp <= 3) {
      r.add(RuleResult(
        level: RiskLevel.critical,
        category: RuleCategory.weather,
        title: 'Don Riski',
        message: 'Sıcaklık ${temp.toStringAsFixed(1)}°C — donma eşiğine yakın.',
        recommendation:
            'Bitkilerinizi örtü bezi veya naylon ile örtün. Sulama yapılacaksa gece değil sabah erken yapın.',
      ));
    }

    // ISI STRESİ
    if (temp >= 40) {
      r.add(RuleResult(
        level: RiskLevel.critical,
        category: RuleCategory.weather,
        title: 'Aşırı Sıcaklık — Isı Stresi',
        message:
            '${temp.toStringAsFixed(1)}°C — çoğu kültür bitkisi için kritik eşik aşıldı.',
        recommendation:
            'Sulama sıklığını artırın. Şemsiyelik / gölgelik kullanın. Gündüz 12-16 arası tarla işi yapmaktan kaçının.',
      ));
    } else if (temp >= 36) {
      r.add(RuleResult(
        level: RiskLevel.warning,
        category: RuleCategory.weather,
        title: 'Yüksek Sıcaklık Uyarısı',
        message:
            '${temp.toStringAsFixed(1)}°C — yaprak yanığı ve su stresi riski arttı.',
        recommendation:
            'Sulama saatini sabah 06:00-08:00 veya akşam 18:00-20:00 olarak ayarlayın. Mulç (saman/plastik örtü) ile toprak ısısını düşürün.',
      ));
    }

    // RÜZGAR
    if (wind >= 15) {
      r.add(RuleResult(
        level: RiskLevel.critical,
        category: RuleCategory.weather,
        title: 'Şiddetli Rüzgar',
        message:
            '${wind.toStringAsFixed(1)} m/s rüzgar — bitki devrilme riski.',
        recommendation:
            'Uzun gövdeli bitkiler (domates, biber) için destek kazığı kontrol edin. Sera perdelerini tamamen kapatın.',
      ));
    } else if (wind >= 10) {
      r.add(RuleResult(
        level: RiskLevel.warning,
        category: RuleCategory.weather,
        title: 'Kuvvetli Rüzgar',
        message: '${wind.toStringAsFixed(1)} m/s rüzgar bekleniyor.',
        recommendation:
            'İlaçlama ve gübreleme ertelensin. Sera perdelerini kapatın.',
      ));
    }

    // YÜKSEK YEM (Sulama sırasında yağmur)
    if (precipProb >= 70) {
      r.add(RuleResult(
        level: RiskLevel.warning,
        category: RuleCategory.weather,
        title: 'Sulama Yapma — Yağmur Geliyor',
        message: 'Önümüzdeki 3 saatte yağış olasılığı %${precipProb.round()}.',
        recommendation:
            'Sulama ertelensin. İlaçlama/gübreleme kesinlikle yapılmasın — yağmur kimyasalları yıkayarak kök bölgesine taşır.',
      ));
    }

    // AŞIRI YAĞIŞ
    if (weeklyRain > 80) {
      r.add(RuleResult(
        level: RiskLevel.critical,
        category: RuleCategory.weather,
        title: 'Aşırı Yağış — Drenaj Sorunu',
        message:
            'Haftalık ${weeklyRain.round()} mm yağış — kök çürüklüğü ve toprak yıkanması riski.',
        recommendation:
            'Drenaj kanallarını kontrol edin. Sulamayı tamamen durdurun. Mantar hastalığı baskısı için uzman/ziraat mühendisi değerlendirmesi sonrası BKÜ veritabanından ruhsatlı koruyucu seçilebilir.',
      ));
    } else if (weeklyRain > 50) {
      r.add(RuleResult(
        level: RiskLevel.warning,
        category: RuleCategory.weather,
        title: 'Yüksek Yağış',
        message: 'Haftalık ${weeklyRain.round()} mm yağış.',
        recommendation:
            'Sulamayı haftaya kadar erteleyin. Mantar belirtisi görürseniz uzman onayı ve BKÜ veritabanı kontrolü ile ruhsatlı koruyucu değerlendirilmeli.',
      ));
    }

    // KURAK
    if (weeklyRain < 3 && humidity < 30) {
      r.add(RuleResult(
        level: RiskLevel.warning,
        category: RuleCategory.weather,
        title: 'Kurak Koşullar',
        message:
            'Haftalık yağış ${weeklyRain.round()} mm ve nem %${humidity.round()} — kuraklık stresi.',
        recommendation:
            'Damla sulama sistemi kullanıyorsanız çalışma süresini %30 artırın. Mulçlama yapın.',
      ));
    }

    return r;
  }

  // ── 2. SULAMA KURALLARI ──────────────────────────────────────────────────

  static List<RuleResult> _irrigationRules(
    double ndvi,
    double soilMoisture,
    double weeklyRain,
    double precipProb,
    Map<String, dynamic> plantDetails,
    double temp,
  ) {
    final r = <RuleResult>[];
    final watering =
        (plantDetails['watering'] ?? 'Average').toString().toLowerCase();
    final droughtTolerant = plantDetails['drought_tolerant'] == true;

    // KURAL 2 (Kullanıcının belirttiği): NDVI < 0.4 + toprak nemi düşük
    if (ndvi < 0.4 && soilMoisture < 0.15) {
      r.add(RuleResult(
        level: RiskLevel.critical,
        category: RuleCategory.irrigation,
        title: 'Acil Sulama Gerekli',
        message:
            'NDVI: ${ndvi.toStringAsFixed(2)} (bitki stres altında) + Toprak nemi: %${(soilMoisture * 100).round()} (kritik düşük).',
        recommendation:
            'En geç bugün sulama yapın. Damla sulama ile kök bölgesine yavaş ve derin sulama. Mulçlama yapın.',
      ));
    } else if (ndvi < 0.5 && soilMoisture < 0.20 && weeklyRain < 10) {
      r.add(RuleResult(
        level: RiskLevel.warning,
        category: RuleCategory.irrigation,
        title: 'Sulama Önerilir',
        message:
            'NDVI: ${ndvi.toStringAsFixed(2)} + Toprak nemi: %${(soilMoisture * 100).round()} + Haftalık yağış ${weeklyRain.round()} mm.',
        recommendation:
            'Yarın veya öbür gün sulama planlayın. Sabah erken saatlerde tercih edin.',
      ));
    }

    // AŞIRI SULAMA / DRENAJ
    if (soilMoisture > 0.50) {
      r.add(RuleResult(
        level: RiskLevel.critical,
        category: RuleCategory.irrigation,
        title: 'Toprak Aşırı Nemli — Kök Çürüklüğü Riski',
        message:
            'Toprak nemi %${(soilMoisture * 100).round()} — hava boşlukları yok, kökler boğuluyor.',
        recommendation:
            'Sulamayı derhal durdurun. Drenaj hendekleri açın. Phytophthora fungisidi önleyici olarak düşünün.',
      ));
    } else if (soilMoisture > 0.40) {
      r.add(RuleResult(
        level: RiskLevel.warning,
        category: RuleCategory.irrigation,
        title: 'Toprak Çok Nemli',
        message:
            'Toprak nemi %${(soilMoisture * 100).round()} — sulama azaltılmalı.',
        recommendation: 'En az 5 gün sulama yapmayın. Drenajı kontrol edin.',
      ));
    }

    // BİTKİ SU İHTİYACI vs YAĞIŞ
    if (watering == 'frequent' && weeklyRain < 10 && soilMoisture < 0.25) {
      r.add(RuleResult(
        level: RiskLevel.warning,
        category: RuleCategory.irrigation,
        title: 'Sık Sulayan Bitki — Yağış Yetersiz',
        message:
            'Bu bitki sık sulama ister. Haftalık yağış sadece ${weeklyRain.round()} mm.',
        recommendation:
            'Haftada en az 3 kez, sabah erkenden sulayın. Damla sulama ideal.',
      ));
    } else if (watering == 'minimum' && weeklyRain > 25) {
      if (!droughtTolerant) {
        r.add(RuleResult(
          level: RiskLevel.info,
          category: RuleCategory.irrigation,
          title: 'Az Sulayan Bitki — Yağış Yeterli',
          message:
              'Bu bitki az su ister ve ${weeklyRain.round()} mm yağış yeterince fazla.',
          recommendation:
              'Bu hafta ek sulama yapmayın. Toprak nem takibi yapın.',
        ));
      }
    }

    // NDVI SAĞLIKLI
    if (ndvi >= 0.7 && soilMoisture >= 0.20 && soilMoisture <= 0.40) {
      r.add(const RuleResult(
        level: RiskLevel.ok,
        category: RuleCategory.irrigation,
        title: 'Sulama Dengesi İdeal',
        message: 'NDVI yüksek, toprak nemi normal aralıkta.',
        recommendation: 'Mevcut sulama programını sürdürün.',
      ));
    }

    return r;
  }

  // ── 3. HASTALIK KURALLARI ─────────────────────────────────────────────────

  static List<RuleResult> _diseaseRules(
    String name,
    double temp,
    double humidity,
    double weeklyRain,
    double soilMoisture,
    int month,
  ) {
    final r = <RuleResult>[];

    // KURAL 1 (Kullanıcının belirttiği): Domates + yüksek nem + 20-25°C → Mantar/Fungus
    if (name.contains('domates') && humidity > 80 && temp >= 20 && temp <= 25) {
      r.add(RuleResult(
        level: RiskLevel.critical,
        category: RuleCategory.disease,
        title: 'Yüksek Mantar (Fungus) Riski — Domates',
        message:
            'Nem %${humidity.round()} + Sıcaklık ${temp.toStringAsFixed(1)}°C — Botrytis (gri küf) ve Alternaria yaprak lekesi için ideal koşullar.',
        recommendation:
            'Yaprak altlarını günlük kontrol edin. Sulamayı sabah yapın, gece ıslak bitki kalmayacak şekilde. Belirti varsa uzman/ziraat mühendisi değerlendirmesi ve BKÜ veritabanı kontrolü ile ruhsatlı koruyucu seçilebilir.',
      ));
    }

    // Genel mantar riski (tüm bitkiler)
    if (humidity > 85 && temp >= 18 && temp <= 28) {
      r.add(RuleResult(
        level: RiskLevel.warning,
        category: RuleCategory.disease,
        title: 'Genel Mantar Hastalık Riski',
        message:
            'Nem %${humidity.round()} + Sıcaklık ${temp.toStringAsFixed(1)}°C — fungal hastalıklar için elverişli koşullar.',
        recommendation:
            'Bitkilerin üzerinde yağmur suyunu giderecek sabah sulaması yapın. Hava sirkülasyonu için budama düşünün.',
      ));
    }

    // MİLDİYÖ (PATATES + DOMATES — soğuk+nemli)
    if ((name.contains('patates') || name.contains('domates')) &&
        humidity > 85 &&
        temp >= 10 &&
        temp <= 20) {
      r.add(RuleResult(
        level: RiskLevel.critical,
        category: RuleCategory.disease,
        title: 'Mildiyö (Phytophthora) Riski',
        message:
            'Nem %${humidity.round()} + Düşük sıcaklık ${temp.toStringAsFixed(1)}°C — geç yanıklık (late blight) için kritik koşul.',
        recommendation:
            'Hasta yaprak ve sürgünleri hemen uzaklaştırın. Damla sulamaya geçin. Uzman değerlendirmesi sonrası BKÜ veritabanından ruhsatlı koruyucu seçilebilir.',
      ));
    }

    // KÜLLEME (Salatalık, Kabak, Üzüm — kuru+sıcak)
    if ((name.contains('salatalık') ||
            name.contains('kabak') ||
            name.contains('üzüm') ||
            name.contains('kavun') ||
            name.contains('karpuz')) &&
        temp >= 22 &&
        temp <= 28 &&
        humidity >= 45 &&
        humidity <= 70) {
      r.add(RuleResult(
        level: RiskLevel.warning,
        category: RuleCategory.disease,
        title: 'Külleme (Powdery Mildew) Riski',
        message:
            '${temp.toStringAsFixed(1)}°C + Nem %${humidity.round()} — külleme gelişimi için ideal.',
        recommendation:
            'Yapraklarda beyaz pudra benzeri leke arayın. Belirti tespit ederseniz uzman/ziraat mühendisi değerlendirmesi ve BKÜ veritabanı kontrolü ile ruhsatlı koruyucu seçilebilir.',
      ));
    }

    // BUĞDAY PAS HASTALIĞI
    if (name.contains('buğday') && humidity > 75 && temp >= 15 && temp <= 25) {
      r.add(RuleResult(
        level: RiskLevel.warning,
        category: RuleCategory.disease,
        title: 'Pas Hastalığı Riski — Buğday',
        message:
            'Nem %${humidity.round()} + ${temp.toStringAsFixed(1)}°C — sarı pas veya kara pas sporları yayılabilir.',
        recommendation:
            'Tarlayı tarayın, pas belirtisi var mı kontrol edin. Belirti yoğunsa uzman değerlendirmesi ve BKÜ veritabanı kontrolü ile ruhsatlı koruyucu hazır bulundurun.',
      ));
    }

    // ÇİLEK BOTRYTİS
    if (name.contains('çilek') && humidity > 90 && temp >= 15 && temp <= 22) {
      r.add(RuleResult(
        level: RiskLevel.critical,
        category: RuleCategory.disease,
        title: 'Botrytis (Gri Küf) — Çilek',
        message:
            'Nem %${humidity.round()} — çilek için en tehlikeli mantar koşulları oluştu.',
        recommendation:
            'Drenajı iyileştirin. Olgunlaşmış meyveleri günlük toplayın. Uzman değerlendirmesi sonrası BKÜ veritabanından Botrytis için ruhsatlı koruyucu seçilebilir.',
      ));
    }

    // FASULYE ANTRAKNOZ
    if (name.contains('fasulye') && humidity > 80 && weeklyRain > 20) {
      r.add(RuleResult(
        level: RiskLevel.warning,
        category: RuleCategory.disease,
        title: 'Antraknoz Riski — Fasulye',
        message:
            'Yağış ${weeklyRain.round()} mm + Nem %${humidity.round()} — Colletotrichum hastalığı için koşullar uygun.',
        recommendation:
            'Yağışlı havalarda tarlaya girişi azaltın (bulaşma önleme). Belirti varsa uzman değerlendirmesi ve BKÜ veritabanı kontrolü ile ruhsatlı koruyucu seçilebilir.',
      ));
    }

    // BİBER BAKTERİYEL LEKE
    if (name.contains('biber') && humidity > 80 && temp >= 24 && temp <= 30) {
      r.add(RuleResult(
        level: RiskLevel.warning,
        category: RuleCategory.disease,
        title: 'Bakteriyel Leke Riski — Biber',
        message:
            '${temp.toStringAsFixed(1)}°C + Nem %${humidity.round()} — Xanthomonas bakterisi için uygun.',
        recommendation:
            'Bakırlı bakterisit uygulayın. Yapraklarda su ile ıslanmış lekeler arıyın.',
      ));
    }

    return r;
  }

  // ── 4. ZARARLI KURALLARI ────────────────────────────────────────────────

  static List<RuleResult> _pestRules(
    String name,
    double temp,
    double humidity,
    double wind,
    int month,
  ) {
    final r = <RuleResult>[];

    // KIRMIZI ÖRÜMCEK (Tetranychus) — sıcak+kuru
    if ((name.contains('domates') ||
            name.contains('biber') ||
            name.contains('salatalık') ||
            name.contains('patlıcan')) &&
        temp > 30 &&
        humidity < 40) {
      r.add(RuleResult(
        level: RiskLevel.warning,
        category: RuleCategory.pest,
        title: 'Kırmızı Örümcek Riski',
        message:
            '${temp.toStringAsFixed(1)}°C + Düşük nem %${humidity.round()} — akar popülasyonu patlayabilir.',
        recommendation:
            'Yaprak altlarını kontrol edin (kırmızı/sarı noktacıklar). Abamektin veya kükürt bazlı akarisit uygulayın. Sera içinde nemlendirme artırın.',
      ));
    }

    // YAPRAK BİTİ (Aphid) — ılık bahar
    if ((month >= 3 && month <= 6) &&
        temp >= 15 &&
        temp <= 25 &&
        humidity >= 60) {
      r.add(RuleResult(
        level: RiskLevel.info,
        category: RuleCategory.pest,
        title: 'Yaprak Biti (Aphid) Sezonu',
        message:
            'Bahar sezonu ve ${temp.toStringAsFixed(1)}°C — yaprak biti çoğalması için uygun.',
        recommendation:
            'Genç sürgünleri kontrol edin. Sarı yapışkanlı tuzak kullanın. Gerekirse imidakloprid veya pyretrin uygulayın.',
      ));
    }

    // COLORADO BÖCEĞİ (Patates, Patlıcan)
    if ((name.contains('patates') || name.contains('patlıcan')) &&
        temp > 20 &&
        month >= 5 &&
        month <= 8) {
      r.add(RuleResult(
        level: RiskLevel.warning,
        category: RuleCategory.pest,
        title: 'Colorado Böceği Riski',
        message:
            'Yaz sezonu ve ${temp.toStringAsFixed(1)}°C — Colorado böceği ergin ve larvaları aktif.',
        recommendation:
            'Yaprak altlarını günlük kontrol edin. Sarı-siyah çizgili erginleri elle toplayın. Yoğunluk eşik üstündeyse uzman değerlendirmesi ve BKÜ veritabanı kontrolü ile ruhsatlı insektisit seçilebilir.',
      ));
    }

    // BEYAZSINEK (Domates, Biber)
    if ((name.contains('domates') || name.contains('biber')) &&
        temp > 25 &&
        humidity < 70) {
      r.add(RuleResult(
        level: RiskLevel.info,
        category: RuleCategory.pest,
        title: 'Beyazsinek İzleme',
        message:
            '${temp.toStringAsFixed(1)}°C — beyazsinek (Trialeurodes) popülasyonu artabilir.',
        recommendation:
            'Sarı yapışkanlı tuzaklar kurun. Yoğun popülasyonda pymetrozine veya spirotetramat.',
      ));
    }

    // MISIR KURDU
    if (name.contains('mısır') && temp > 25 && month >= 6 && month <= 9) {
      r.add(RuleResult(
        level: RiskLevel.warning,
        category: RuleCategory.pest,
        title: 'Mısır Kurdu (Helicoverpa) Riski',
        message: 'Sıcak yaz — koçan kurdu ve yaprak kurdu aktif dönemde.',
        recommendation:
            'Koçan tepe kısmını kontrol edin. Feromonlu tuzaklar kurun. Bacillus thuringiensis (Bt) biyolojik mücadele.',
      ));
    }

    return r;
  }

  // ── 5. TOPRAK KURALLARI ───────────────────────────────────────────────────

  static List<RuleResult> _soilRules(
    double ph,
    double soilTemp,
    Map<String, dynamic> plantDetails,
    int month,
  ) {
    final r = <RuleResult>[];
    final idealPhMin =
        (plantDetails['ideal_ph_min'] as num?)?.toDouble() ?? 5.5;
    final idealPhMax =
        (plantDetails['ideal_ph_max'] as num?)?.toDouble() ?? 7.0;

    // pH AŞIRI ASİDİK
    if (ph < 5.0) {
      r.add(RuleResult(
        level: RiskLevel.critical,
        category: RuleCategory.soil,
        title: 'Toprak Aşırı Asidik',
        message:
            'pH ${ph.toStringAsFixed(1)} — besin alımı bloke, alüminyum toksisitesi riski.',
        recommendation:
            'Tarım İl Müdürlüğü onayı ile geniş çaplı kireçleme planlanmalı; uzman/ziraat mühendisi toprak analiz raporuna göre kireç miktarını belirler. Sonbahar-kış döneminde uygulanması verimli.',
      ));
    } else if (ph < 5.5) {
      r.add(RuleResult(
        level: RiskLevel.warning,
        category: RuleCategory.soil,
        title: 'Toprak Asidik — Kireçleme Önerisi',
        message:
            'pH ${ph.toStringAsFixed(1)} — çoğu kültür bitkisi için alt sınıra yakın.',
        recommendation:
            'Uzman/ziraat mühendisi gözetiminde toprak analizine göre kireçleme planlayın. 6 ay sonra tekrar pH ölçümü yapın.',
      ));
    }

    // pH BAZIK
    if (ph > 8.0) {
      r.add(RuleResult(
        level: RiskLevel.critical,
        category: RuleCategory.soil,
        title: 'Toprak Aşırı Bazik',
        message:
            'pH ${ph.toStringAsFixed(1)} — demir, çinko ve mangan alımı bloke.',
        recommendation:
            'Uzman/ziraat mühendisi gözetiminde elementel kükürt uygulaması planlanmalı; doz toprak analizi raporuna göre belirlenir. Yapraktan şelat demir spreyi yardımcı olabilir.',
      ));
    } else if (ph > 7.5) {
      r.add(RuleResult(
        level: RiskLevel.warning,
        category: RuleCategory.soil,
        title: 'Toprak Bazik',
        message:
            'pH ${ph.toStringAsFixed(1)} — mikro besin eksikliği riski başlıyor.',
        recommendation:
            'Asidik organik materyal (çam kabuğu kompostu) ekleyin. Amonyum nitrat tercih edin.',
      ));
    }

    // BİTKİYE ÖZGÜ pH UYUMU
    if (ph < idealPhMin - 0.3) {
      r.add(RuleResult(
        level: RiskLevel.warning,
        category: RuleCategory.soil,
        title: 'pH Bitki İdeal Aralığının Altında',
        message:
            'Bitki ideal pH ${idealPhMin.toStringAsFixed(1)}-${idealPhMax.toStringAsFixed(1)} iken mevcut pH ${ph.toStringAsFixed(1)}.',
        recommendation:
            'Kireçleme yapın. Bitki bu pH\'ta besin alımı güçlüğü yaşayacak.',
      ));
    } else if (ph > idealPhMax + 0.3) {
      r.add(RuleResult(
        level: RiskLevel.warning,
        category: RuleCategory.soil,
        title: 'pH Bitki İdeal Aralığının Üstünde',
        message:
            'Bitki ideal pH ${idealPhMin.toStringAsFixed(1)}-${idealPhMax.toStringAsFixed(1)} iken mevcut pH ${ph.toStringAsFixed(1)}.',
        recommendation: 'Kükürt uygulaması ve asidik gübre ile pH düşürün.',
      ));
    }

    // TOPRAK SICAKLIĞI — EKİM İÇİN
    if (soilTemp < 8 && month >= 3 && month <= 5) {
      r.add(RuleResult(
        level: RiskLevel.warning,
        category: RuleCategory.soil,
        title: 'Toprak Henüz Soğuk — Ekim Riski',
        message:
            'Toprak sıcaklığı ${soilTemp.toStringAsFixed(1)}°C — çimlenme yavaş veya başarısız olabilir.',
        recommendation:
            'Siyah plastik mulç ile toprağı ısıtın. Fide kullanın, tohum ekmekten kaçının.',
      ));
    } else if (soilTemp >= 15 && soilTemp <= 25) {
      r.add(RuleResult(
        level: RiskLevel.ok,
        category: RuleCategory.soil,
        title: 'Toprak Sıcaklığı İdeal',
        message:
            '${soilTemp.toStringAsFixed(1)}°C — çimlenme ve kök gelişimi için mükemmel.',
        recommendation: 'Ekim ve dikim için uygun koşullar.',
      ));
    }

    return r;
  }

  // ── 6. MEVSİM KURALLARI ──────────────────────────────────────────────────

  static List<RuleResult> _seasonRules(
    String name,
    int month,
    Map<String, dynamic> plantDetails,
  ) {
    final r = <RuleResult>[];

    // Tropikal bitkiler kışta uyarısı
    if (plantDetails['tropical'] == true &&
        (month == 12 || month == 1 || month == 2)) {
      r.add(const RuleResult(
        level: RiskLevel.critical,
        category: RuleCategory.season,
        title: 'Tropikal Bitki — Kış Dönemi',
        message: 'Bu bitki tropikal kökenli ve kış aylarına karşı hassas.',
        recommendation:
            'Saksıdaysa içeri alın. Tarlada ise kalın örtü bezi veya sera içinde tutun.',
      ));
    }

    // Buğday ekim zamanı
    if (name.contains('buğday') && (month >= 10 && month <= 11)) {
      r.add(const RuleResult(
        level: RiskLevel.ok,
        category: RuleCategory.season,
        title: 'Kışlık Buğday Ekim Zamanı',
        message: 'Ekim-Kasım kışlık buğday ekimi için ideal dönem.',
        recommendation:
            'Ekim derinliği 4-5 cm. Dekara 20-22 kg tohumluk kullanın. Taban gübresi (DAP) ekimde uygulayın.',
      ));
    } else if (name.contains('buğday') && month >= 4 && month <= 9) {
      r.add(const RuleResult(
        level: RiskLevel.warning,
        category: RuleCategory.season,
        title: 'Buğday Ekim Mevsimi Dışı',
        message:
            'Kışlık buğday için en uygun ekim zamanı Ekim-Kasım aylarıdır.',
        recommendation:
            'Yazlık çeşit değerlendirin veya sonbahara kadar bekleyin.',
      ));
    }

    // Domates/biber/patlıcan yaz bitkisi kontrolü
    if ((name.contains('domates') ||
            name.contains('biber') ||
            name.contains('patlıcan')) &&
        (month == 12 || month == 1 || month == 2)) {
      r.add(const RuleResult(
        level: RiskLevel.critical,
        category: RuleCategory.season,
        title: 'Açık Tarla Dışında Ekim Zamanı',
        message: 'Domates/biber/patlıcan soğuğa dayanmaz.',
        recommendation:
            'Açık tarlada ekim yapılmamalı. Sera koşullarında kış üretimi için ısıtma gereklidir.',
      ));
    }

    // İdeal mevsim (ilkbahar yaz bitkiler)
    if ((name.contains('domates') ||
            name.contains('biber') ||
            name.contains('salatalık') ||
            name.contains('kabak')) &&
        month >= 4 &&
        month <= 6) {
      r.add(const RuleResult(
        level: RiskLevel.ok,
        category: RuleCategory.season,
        title: 'İdeal Ekim/Dikim Zamanı',
        message: 'İlkbahar — bu bitki için en uygun dönem.',
        recommendation:
            'Gece sıcaklıkları 10°C\'nin üzerinde olduğunda dikimi yapın.',
      ));
    }

    return r;
  }

  // ── 7. BİTKİ-TARLA UYUM KURALLARI ───────────────────────────────────────

  static List<RuleResult> _compatibilityRules(
    double temp,
    double avgTemp,
    double ph,
    double weeklyRain,
    double humidity,
    Map<String, dynamic> plant,
  ) {
    final r = <RuleResult>[];
    if (plant.isEmpty) return r;

    final idealTempMin = (plant['ideal_temp_min'] as num?)?.toDouble() ?? 10;
    final idealTempMax = (plant['ideal_temp_max'] as num?)?.toDouble() ?? 35;
    final idealPhMin = (plant['ideal_ph_min'] as num?)?.toDouble() ?? 5.5;
    final idealPhMax = (plant['ideal_ph_max'] as num?)?.toDouble() ?? 7.5;
    final waterNeed = (plant['water_need_mm_week'] as num?)?.toDouble() ?? 15;

    // pH UYUMU
    if (ph < idealPhMin - 0.5) {
      r.add(RuleResult(
        level: RiskLevel.warning,
        category: RuleCategory.compatibility,
        title: 'pH Uyumsuz — Çok Asidik',
        message:
            'Tarla pH ${ph.toStringAsFixed(1)}, bitki için ideal: ${idealPhMin.toStringAsFixed(1)}-${idealPhMax.toStringAsFixed(1)}.',
        recommendation: 'Tarım kireci uygulayarak pH\'ı yükseltin.',
      ));
    } else if (ph > idealPhMax + 0.5) {
      r.add(RuleResult(
        level: RiskLevel.warning,
        category: RuleCategory.compatibility,
        title: 'pH Uyumsuz — Çok Bazik',
        message:
            'Tarla pH ${ph.toStringAsFixed(1)}, bitki için ideal: ${idealPhMin.toStringAsFixed(1)}-${idealPhMax.toStringAsFixed(1)}.',
        recommendation: 'Kükürt uygulaması ile pH\'ı düşürün.',
      ));
    } else {
      r.add(RuleResult(
        level: RiskLevel.ok,
        category: RuleCategory.compatibility,
        title: 'pH Uyumlu',
        message: 'Tarla pH ${ph.toStringAsFixed(1)} bitki için ideal aralıkta.',
        recommendation: 'pH değeri uygun, ek işlem gerekmez.',
      ));
    }

    // SICAKLIK UYUMU
    if (avgTemp < idealTempMin - 3) {
      r.add(RuleResult(
        level: RiskLevel.critical,
        category: RuleCategory.compatibility,
        title: 'Sıcaklık Uyumsuz — Çok Soğuk',
        message:
            'Mevcut ${avgTemp.toStringAsFixed(1)}°C, ideal minimum ${idealTempMin.toStringAsFixed(0)}°C.',
        recommendation: 'Bu bitkiyi bu koşullarda yetiştirmeyin.',
      ));
    } else if (avgTemp < idealTempMin) {
      r.add(RuleResult(
        level: RiskLevel.warning,
        category: RuleCategory.compatibility,
        title: 'Sıcaklık Biraz Düşük',
        message:
            'Mevcut ${avgTemp.toStringAsFixed(1)}°C, ideal min ${idealTempMin.toStringAsFixed(0)}°C.',
        recommendation:
            'Plastik mulç ile toprak ısısı artırılabilir. Sezon sonunu göz önünde bulundurun.',
      ));
    } else if (avgTemp >= idealTempMin && avgTemp <= idealTempMax) {
      r.add(RuleResult(
        level: RiskLevel.ok,
        category: RuleCategory.compatibility,
        title: 'Sıcaklık Uyumlu',
        message:
            '${avgTemp.toStringAsFixed(1)}°C — bitki için ideal aralıkta (${idealTempMin.toStringAsFixed(0)}-${idealTempMax.toStringAsFixed(0)}°C).',
        recommendation: 'Sıcaklık koşulları mükemmel.',
      ));
    } else if (avgTemp > idealTempMax + 3) {
      r.add(RuleResult(
        level: RiskLevel.warning,
        category: RuleCategory.compatibility,
        title: 'Sıcaklık Çok Yüksek',
        message:
            'Mevcut ${avgTemp.toStringAsFixed(1)}°C, ideal max ${idealTempMax.toStringAsFixed(0)}°C.',
        recommendation:
            'Gölgeleme ağı ve bol sulama ile sıcaklık etkisini azaltın.',
      ));
    }

    // SU İHTİYACI UYUMU
    final waterDiff = (weeklyRain - waterNeed).abs();
    if (weeklyRain < waterNeed - 10) {
      r.add(RuleResult(
        level: RiskLevel.warning,
        category: RuleCategory.compatibility,
        title: 'Su Açığı Var',
        message:
            'Bitki haftada ${waterNeed.round()} mm ister, yağış ${weeklyRain.round()} mm.',
        recommendation:
            '${(waterNeed - weeklyRain).round()} mm eksik — sulama ile tamamlayın.',
      ));
    } else if (waterDiff <= 10) {
      r.add(RuleResult(
        level: RiskLevel.ok,
        category: RuleCategory.compatibility,
        title: 'Su Dengesi Uyumlu',
        message:
            'Yağış (${weeklyRain.round()} mm) bitki su ihtiyacını (${waterNeed.round()} mm) karşılıyor.',
        recommendation: 'Ek sulama gerekmeyebilir.',
      ));
    }

    return r;
  }

  // ── 8. HASAT KURALLARI ────────────────────────────────────────────────────

  static List<RuleResult> _harvestRules(
    String name,
    Map<String, dynamic> plant,
  ) {
    final r = <RuleResult>[];
    // Bu kural, ekim tarihi + hasat günü bilgisini gerektiriyor;
    // GardenManager ekranından çağrıldığında dolduruluyor.
    // Temel kontrol: meyve kalitesini bozan hava koşulları
    if (name.contains('karpuz') || name.contains('kavun')) {
      r.add(const RuleResult(
        level: RiskLevel.info,
        category: RuleCategory.harvest,
        title: 'Hasat Kalite İpucu — Kavun/Karpuz',
        message: 'Olgunlaşma döneminde sulama azaltılırsa şeker oranı artar.',
        recommendation:
            'Hasattan 10-14 gün önce sulamayı azaltın. Sapın kurumaya başlaması ve koku olgunluğun işareti.',
      ));
    }
    return r;
  }

  // ── FIELD PLAN GENERATOR (generateFieldPlan yerine) ──────────────────────

  static String generateFieldPlan({
    required String plantName,
    required String fieldName,
    required double ph,
    required double avgTemp,
    required double totalRain,
    required double areaDekar,
    required int month,
    Map<String, dynamic> plantDetails = const {},
  }) {
    final monthNames = [
      '',
      'Ocak',
      'Şubat',
      'Mart',
      'Nisan',
      'Mayıs',
      'Haziran',
      'Temmuz',
      'Ağustos',
      'Eylül',
      'Ekim',
      'Kasım',
      'Aralık'
    ];
    final season = _currentSeason(month);
    final buf = StringBuffer();

    final rowSp = (plantDetails['row_spacing_cm'] as num?)?.toInt() ?? 60;
    final plantSp = (plantDetails['plant_spacing_cm'] as num?)?.toInt() ?? 40;
    final depth = (plantDetails['depth_cm'] as num?)?.toInt() ?? 3;
    final seeds = (plantDetails['seeds_per_dekar'] as num?)?.toInt() ?? 500;
    final harvest = (plantDetails['harvest_days'] as num?)?.toInt() ?? 90;
    final watering = (plantDetails['watering'] ?? 'Average').toString();
    final care = (plantDetails['care_description'] ?? '').toString();
    final pests =
        (plantDetails['pest_susceptibility'] ?? 'Genel zararlı takibi')
            .toString();

    // Tahmini hasat tarihi
    final now = DateTime.now();
    final harvestDate = now.add(Duration(days: harvest));

    buf.writeln('📋 $plantName — $fieldName Ekim Planı');
    buf.writeln(
        'Tarih: ${now.day} ${monthNames[month]} ${now.year} | Mevsim: $season');
    buf.writeln('Alan: ${areaDekar.toStringAsFixed(1)} dekar\n');

    // 1. Toprak Hazırlığı
    buf.writeln('🌱 1. TOPRAK HAZIRLIĞI');
    if (ph < 5.5) {
      buf.writeln(
          '• pH ${ph.toStringAsFixed(1)} — Düşük pH; ekimden önce kireçleme gerekir. Uzman/ziraat mühendisi toprak analizine göre kireç miktarını belirler.');
    } else if (ph > 7.5) {
      buf.writeln(
          '• pH ${ph.toStringAsFixed(1)} — Yüksek pH; uzman gözetiminde elementel kükürt uygulaması planlanmalı.');
    } else {
      buf.writeln(
          '• pH ${ph.toStringAsFixed(1)} ✅ toprak ideal aralıkta, kireçleme gerekmez.');
    }
    buf.writeln(
        '• Taban gübresi: NPK miktarı toprak analizine göre ziraat mühendisi onayıyla belirlenmeli; ekimden 5-7 gün önce uygulanır.');
    buf.writeln(
        '• Derin sürüm (25-30 cm) ve diskaro ile toprak hazırlığı yapın.\n');

    // 2. Ekim/Dikim
    buf.writeln('🌾 2. EKİM / DİKİM SÜRECİ');
    buf.writeln('• Ekim derinliği: $depth cm');
    buf.writeln('• Sıra arası: $rowSp cm | Bitki arası: $plantSp cm');
    buf.writeln('• Tohumluk/Fide: Dekara $seeds adet');
    buf.writeln(
        '• ${areaDekar.toStringAsFixed(1)} dekar için toplam: ${(seeds * areaDekar).round()} adet fide/tohum');
    buf.writeln(
        '• Tahmini hasat: ${harvestDate.day} ${monthNames[harvestDate.month]} ${harvestDate.year}\n');

    // 3. Sulama & Gübre
    buf.writeln('💧 3. SULAMA VE GÜBRELEME TAKVİMİ');
    buf.writeln('• Mevcut haftalık yağış: ${totalRain.round()} mm');
    if (watering.toLowerCase() == 'frequent' && totalRain < 15) {
      buf.writeln(
          '• ⚠️ Bu bitki sık sulama ister — haftada 3 kez sabah erken sulama yapın.');
    } else if (watering.toLowerCase() == 'minimum') {
      buf.writeln(
          '• Bu bitki az su ister — haftada 1 kez derin sulama yeterli.');
    } else {
      buf.writeln('• Haftada 2 kez, sabah 06:00-08:00 arası sulama önerilir.');
    }
    buf.writeln(
        '• Gübre takvimi: Fide dönemi azot → çiçek dönemi fosfor → meyve dönemi potasyum.\n');

    // 4. Bakım & Hastalık
    buf.writeln('🌡️ 4. BAKIM VE HASTALIK TAKİBİ');
    if (care.isNotEmpty && care.length > 20) {
      buf.writeln(care.split('\n').take(6).join('\n'));
    } else {
      buf.writeln('• Düzenli gözlem: haftada 2 kez yaprak ve kök kontrolü.');
      buf.writeln('• Hassas olduğu zararlılar: $pests');
    }
    buf.writeln('');

    // 5. Hasat Beklentisi
    buf.writeln('🎯 5. HASAT BEKLENTİSİ');
    buf.writeln('• Ekim tarihinden ~$harvest gün sonra hasat.');
    buf.writeln(
        '• ${areaDekar.toStringAsFixed(1)} dekar alandan beklenen verim:');
    // Yaklaşık bitki sayısı: dekar -> m2, sıra/bitki aralığı cm -> m.
    final plantFootprintSqm = (rowSp / 100.0) * (plantSp / 100.0);
    final plantCount = plantFootprintSqm > 0
        ? ((areaDekar * 1000.0) / plantFootprintSqm).round()
        : 0;
    buf.writeln(
        '  Toplam $plantCount bitki × ortalama verim = tür bazlı hesap yapın.');
    buf.writeln('• Hasat sabah erken saatlerde, serin havada yapılmalıdır.');

    return buf.toString();
  }

  /// Haftalık tarla yorumu (getFieldAnalysis AI comment yerine)
  static String generateWeeklyComment({
    required String fieldName,
    required double temp,
    required double avgTemp,
    required double humidity,
    required double wind,
    required double ph,
    required double soilMoisture,
    required double soilTempC,
    required double totalWeeklyRain,
    required List<Map<String, dynamic>> crops,
    required int month,
  }) {
    final monthNames = [
      '',
      'Ocak',
      'Şubat',
      'Mart',
      'Nisan',
      'Mayıs',
      'Haziran',
      'Temmuz',
      'Ağustos',
      'Eylül',
      'Ekim',
      'Kasım',
      'Aralık'
    ];
    final season = _currentSeason(month);
    final suggestedCrops = crops.map((c) => c['name']).take(5).join(', ');
    final buf = StringBuffer();

    buf.writeln('🌤️ HAFTALIK HAVA DEĞERLENDİRMESİ');
    buf.writeln('Tarla: $fieldName | ${monthNames[month]} — $season');
    buf.writeln(
        'Anlık: ${temp.toStringAsFixed(1)}°C, Nem %${humidity.round()}, Rüzgar ${wind.toStringAsFixed(1)} m/s');
    buf.writeln(
        'Haftalık ort: ${avgTemp.toStringAsFixed(1)}°C | Yağış: ${totalWeeklyRain.round()} mm\n');

    buf.writeln('🌱 BU HAFTA YAPILMASI GEREKENLER');
    if (totalWeeklyRain < 10) {
      buf.writeln(
          '• Sulama: Haftada 2-3 kez, sabah erken saatleri tercih edin.');
    } else if (totalWeeklyRain > 40) {
      buf.writeln('• Sulama: Bu hafta yağış yeterli — sulama yapmayın.');
      buf.writeln('• Drenaj kanallarını kontrol edin.');
    } else {
      buf.writeln('• Sulama: Haftada 1-2 kez yeterli olacaktır.');
    }
    if (avgTemp >= 18 && avgTemp <= 30) {
      buf.writeln(
          '• Gübreleme: Bu hafta gübre uygulaması için uygun koşullar.');
    }
    if (month >= 3 && month <= 5) {
      buf.writeln(
          '• İlkbahar bakım: Yabancı ot kontrolü ve çapalama önerilir.');
    }
    buf.writeln('');

    buf.writeln('🧪 TOPRAK VE GÜBRE DURUMU');
    if (ph < 5.5) {
      buf.writeln(
          '⚠️ Toprak asidik (pH ${ph.toStringAsFixed(1)}) — kireçleme gerekli.');
    } else if (ph > 7.5) {
      buf.writeln(
          '⚠️ Toprak bazik (pH ${ph.toStringAsFixed(1)}) — kükürt uygulaması önerilir.');
    } else {
      buf.writeln('✅ Toprak pH\'ı (${ph.toStringAsFixed(1)}) ideal aralıkta.');
    }
    buf.writeln(
        'Toprak nemi: %${(soilMoisture * 100).round()} | Toprak sıcaklığı: ${soilTempC.toStringAsFixed(1)}°C');
    buf.writeln('');

    buf.writeln('⚠️ RİSKLER');
    if (humidity > 80 && temp >= 18 && temp <= 28) {
      buf.writeln(
          '• Mantar hastalık riski yüksek — belirti gözlemleyin; uzman değerlendirmesi sonrası BKÜ veritabanından ruhsatlı koruyucu seçilebilir.');
    }
    if (temp > 35) {
      buf.writeln('• Isı stresi — sulama sıklığını artırın, mulçlama yapın.');
    }
    if (temp < 5) {
      buf.writeln('• Don riski — hassas bitkilerinizi koruyun.');
    }
    if (totalWeeklyRain < 5 && humidity < 35) {
      buf.writeln('• Kuraklık stresi — damla sulama sisteminizi kontrol edin.');
    }
    buf.writeln('');

    buf.writeln('💡 ÖNERİLEN ÜRÜNLER');
    buf.writeln('Mevcut koşullara göre önerilen ürünler: $suggestedCrops');

    return buf.toString();
  }

  /// Çevresel rapor (Senaryo C: ilgisiz fotoğraf için)
  static String generateEnvironmentalReport({
    required double temp,
    required double humidity,
    required double weeklyRain,
    required double ph,
    required double soilMoisture,
    required double soilTempC,
    required int month,
  }) {
    final monthNames = [
      '',
      'Ocak',
      'Şubat',
      'Mart',
      'Nisan',
      'Mayıs',
      'Haziran',
      'Temmuz',
      'Ağustos',
      'Eylül',
      'Ekim',
      'Kasım',
      'Aralık'
    ];
    final season = _currentSeason(month);
    final buf = StringBuffer();

    buf.writeln(
        'Fotoğraf tarımsal bir içerik olarak tanımlanamadı. Ancak bulunduğunuz bölgedeki güncel tarımsal çevre şartları şu şekildedir:');
    buf.writeln('');
    buf.writeln('📍 BÖLGE ÇEVRESİ — ${monthNames[month]} $season');
    buf.writeln('🌡️ Anlık Sıcaklık: ${temp.toStringAsFixed(1)}°C');
    buf.writeln('💧 Nem Oranı: %${humidity.round()}');
    buf.writeln('🌧️ Haftalık Yağış Beklentisi: ${weeklyRain.round()} mm');
    buf.writeln('🌿 Toprak pH: ${ph.toStringAsFixed(1)}');
    if (soilMoisture > 0) {
      buf.writeln('💦 Toprak Nem: %${(soilMoisture * 100).round()}');
    }
    if (soilTempC > 0) {
      buf.writeln('🌡️ Toprak Sıcaklığı: ${soilTempC.toStringAsFixed(1)}°C');
    }
    buf.writeln('');

    // Genel yorum
    if (temp >= 15 && temp <= 28 && humidity >= 40 && humidity <= 70) {
      buf.writeln(
          '✅ Bölgeniz şu an tarımsal faaliyet için uygun koşullara sahip.');
    } else if (temp < 5) {
      buf.writeln(
          '⚠️ Soğuk koşullar — açık alanda hassas bitki yetiştiriciliği önerilmez.');
    } else if (temp > 36) {
      buf.writeln('⚠️ Aşırı sıcak — sulama ve gölgeleme önlemleri alın.');
    }

    if (ph >= 6.0 && ph <= 7.0) {
      buf.writeln('✅ Toprak pH\'ı çoğu sebze ve meyve için mükemmel aralıkta.');
    }

    return buf.toString();
  }

  static String _currentSeason(int month) {
    if (month >= 3 && month <= 5) return 'İlkbahar';
    if (month >= 6 && month <= 8) return 'Yaz';
    if (month >= 9 && month <= 11) return 'Sonbahar';
    return 'Kış';
  }
}
