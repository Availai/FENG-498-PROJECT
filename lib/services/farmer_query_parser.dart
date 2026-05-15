import '../data/rule_packs/fact_keys.dart';

/// CLAUDE.md sec 9 — Kullanıcının serbest Türkçe metninden deterministik
/// fact'ler çıkaran lexicon parser. **LLM kullanmaz**; sadece anahtar
/// kelime → fact eşlemesi yapar. Aynı girdi her zaman aynı çıktıyı verir.
///
/// Tarımsal Türkçe sözlüğü kullanıcı yazımlarına yakın olacak şekilde
/// hem standart hem yöresel kullanımları içerir ("kurşuni küf",
/// "gri küf", "Botrytis" hepsi tek sembole çevrilir).
class FarmerQueryParser {
  const FarmerQueryParser();

  /// Metni analiz eder. Eşleşme yoksa `signals` boş döner; UI bu durumda
  /// "Sorununuzu daha açık yazın" mesajı + örnek prompt gösterir.
  FarmerQueryAnalysis analyze(String input) {
    final normalized = _normalize(input);
    if (normalized.isEmpty) {
      return const FarmerQueryAnalysis(
        facts: {},
        signals: [],
        suggestedCategories: [],
      );
    }

    final facts = <String, Object?>{};
    final signals = <FarmerQuerySignal>[];
    final suggestedCategories = <String>{};

    // ── Hastalık belirtileri → observed_symptom ──────────────────────
    for (final entry in _symptomLexicon.entries) {
      if (_anyHit(normalized, entry.value)) {
        facts[FactKeys.observedSymptom] = entry.key;
        signals.add(FarmerQuerySignal(
          kind: 'belirti',
          label: _symptomLabel(entry.key),
          factKey: FactKeys.observedSymptom,
          factValue: entry.key,
        ));
        suggestedCategories.add('disease_risk');
        break; // en spesifik eşleşme yeterli
      }
    }

    // ── Zararlı → observed_pest ──────────────────────────────────────
    for (final entry in _pestLexicon.entries) {
      if (_anyHit(normalized, entry.value)) {
        facts[FactKeys.observedPest] = entry.key;
        // Şikâyet → eşik üstü varsayımı (kullanıcı şikâyet ediyorsa
        // popülasyon görünür demektir).
        facts[FactKeys.pestPopulationLevel] = 'above_threshold';
        signals.add(FarmerQuerySignal(
          kind: 'zararlı',
          label: _pestLabel(entry.key),
          factKey: FactKeys.observedPest,
          factValue: entry.key,
        ));
        suggestedCategories.add('pest_risk');
        break;
      }
    }

    // ── Yabani ot → observed_weed ────────────────────────────────────
    for (final entry in _weedLexicon.entries) {
      if (_anyHit(normalized, entry.value)) {
        facts[FactKeys.observedWeed] = entry.key;
        signals.add(FarmerQuerySignal(
          kind: 'yabancı ot',
          label: _weedLabel(entry.key),
          factKey: FactKeys.observedWeed,
          factValue: entry.key,
        ));
        suggestedCategories.add('weed_management');
        break;
      }
    }

    // ── Büyüme evresi → growth_stage ─────────────────────────────────
    final stage = _detectStage(normalized);
    if (stage != null) {
      facts[FactKeys.growthStage] = stage;
      signals.add(FarmerQuerySignal(
        kind: 'evre',
        label: _stageLabel(stage),
        factKey: FactKeys.growthStage,
        factValue: stage,
      ));
    }

    // ── Hava / iklim sinyalleri ──────────────────────────────────────
    if (_anyHit(
        normalized, ['kurak', 'kurudu', 'su yok', 'susuz', 'kurumuş'])) {
      facts[FactKeys.soilMoisture] = 0.12;
      facts[FactKeys.weeklyRainMm] = 0;
      signals.add(const FarmerQuerySignal(
        kind: 'koşul',
        label: 'Toprak kurak',
        factKey: FactKeys.soilMoisture,
        factValue: 0.12,
      ));
      suggestedCategories.add('irrigation');
    }
    if (_anyHit(normalized, [
      'sel',
      'su göllen',
      'su gollen',
      'fazla su',
      'aşırı sulama',
      'asiri sulama',
    ])) {
      facts[FactKeys.soilMoisture] = 0.50;
      signals.add(const FarmerQuerySignal(
        kind: 'koşul',
        label: 'Su göllenmesi',
        factKey: FactKeys.soilMoisture,
        factValue: 0.50,
      ));
      suggestedCategories.add('weather_warning');
    }
    if (_anyHit(normalized, ['don', 'donma', 'soğuk', 'soguk', 'ayaz'])) {
      facts[FactKeys.frostRiskNext48h] = true;
      facts[FactKeys.tempMin24hC] = 0;
      signals.add(const FarmerQuerySignal(
        kind: 'koşul',
        label: 'Don/soğuk riski',
        factKey: FactKeys.frostRiskNext48h,
        factValue: true,
      ));
      suggestedCategories.add('weather_warning');
    }
    if (_anyHit(
        normalized, ['sıcak', 'sicak', 'kavur', 'yandı', 'yanik', 'kavrul'])) {
      facts[FactKeys.heatStressNext48h] = true;
      facts[FactKeys.tempMax24hC] = 38;
      signals.add(const FarmerQuerySignal(
        kind: 'koşul',
        label: 'Aşırı sıcak / ısı stresi',
        factKey: FactKeys.heatStressNext48h,
        factValue: true,
      ));
      suggestedCategories.add('weather_warning');
    }
    if (_anyHit(normalized, ['rüzgar', 'ruzgar', 'fırtına', 'firtina'])) {
      facts[FactKeys.windSpeedMs] = 15;
      signals.add(const FarmerQuerySignal(
        kind: 'koşul',
        label: 'Şiddetli rüzgar',
        factKey: FactKeys.windSpeedMs,
        factValue: 15,
      ));
      suggestedCategories.add('weather_warning');
    }
    if (_anyHit(normalized, ['nem', 'rutubet', 'çiy', 'ciy', 'sis'])) {
      facts[FactKeys.humidityLevel] = 'high';
      facts[FactKeys.humidityPct] = 85;
      signals.add(const FarmerQuerySignal(
        kind: 'koşul',
        label: 'Yüksek nem',
        factKey: FactKeys.humidityLevel,
        factValue: 'high',
      ));
    }
    if (_anyHit(normalized, ['dolu '])) {
      facts[FactKeys.hailRiskNext24h] = true;
      signals.add(const FarmerQuerySignal(
        kind: 'koşul',
        label: 'Dolu riski',
        factKey: FactKeys.hailRiskNext24h,
        factValue: true,
      ));
      suggestedCategories.add('weather_warning');
    }

    // ── Kategori sinyalleri (kullanıcı "sulama hakkında" gibi) ───────
    if (_anyHit(normalized, ['sulama', 'su ver', 'sular'])) {
      suggestedCategories.add('irrigation');
    }
    if (_anyHit(normalized, ['gübre', 'gubre', 'azot', 'fosfor', 'potasyum'])) {
      suggestedCategories.add('fertilization');
    }
    if (_anyHit(normalized, ['toprak', 'analiz', 'ph', 'tuzluluk', 'ec'])) {
      suggestedCategories.add('soil_analysis');
    }
    if (_anyHit(normalized, ['hasat', 'biçer', 'bicer'])) {
      suggestedCategories.add('harvest');
    }
    if (_anyHit(normalized, ['ekim', 'tohum', 'mibzer'])) {
      suggestedCategories.add('sowing_or_planting');
    }

    return FarmerQueryAnalysis(
      facts: Map.unmodifiable(facts),
      signals: List.unmodifiable(signals),
      suggestedCategories: List.unmodifiable(suggestedCategories.toList()),
    );
  }

  // ─── Türkçe normalize: küçük harf + diakritik temizle ───────────────
  String _normalize(String s) => s
      .toLowerCase()
      .replaceAll('ç', 'c')
      .replaceAll('ğ', 'g')
      .replaceAll('ı', 'i')
      .replaceAll('İ', 'i')
      .replaceAll('ö', 'o')
      .replaceAll('ş', 's')
      .replaceAll('ü', 'u')
      .trim();

  bool _anyHit(String haystack, List<String> needles) {
    for (final n in needles) {
      if (haystack.contains(_normalize(n))) return true;
    }
    return false;
  }

  String? _detectStage(String n) {
    if (_anyHit(n, ['cimlen', 'cikis ', 'cikti '])) return 'germination';
    if (_anyHit(n, ['fide', 'filiz', 'genc bitki'])) return 'seedling';
    if (_anyHit(n, ['vejetatif', 'yapraklan'])) return 'vegetative';
    if (_anyHit(n, ['tomurcuk', 'cicek oncesi'])) return 'pre_flowering';
    if (_anyHit(n, ['cicek', 'sari cicek', 'tabla acti'])) return 'flowering';
    if (_anyHit(n, ['dane dol', 'tohum dol', 'meyve dol'])) {
      return 'grain_filling';
    }
    if (_anyHit(n, ['olgun', 'kahverengi bas', 'kuru bas'])) return 'maturity';
    if (_anyHit(n, ['hasat'])) return 'harvest';
    return null;
  }

  // ── Lexicon tabloları — anahtar = fact value, değer = TR eş anlamlılar
  static const _symptomLexicon = <String, List<String>>{
    'leaf_spot': [
      'yaprak lekesi',
      'yaprak leke',
      'leke var',
      'kahverengi leke',
      'septoria',
      'alternaria',
    ],
    'downy_mildew': [
      'mildiyo',
      'mildiyö',
      'yaprak alt yuzu beyaz',
      'beyaz ortuk',
      'downy',
    ],
    'powdery_mildew': [
      'kulleme',
      'külleme',
      'beyaz toz',
      'powdery',
      'kul gibi',
    ],
    'rust': [
      'pas hastaligi',
      'turuncu pust',
      'kirmizi pust',
      'rust',
    ],
    'grey_mold': [
      'kursuni kuf',
      'kurşuni küf',
      'gri kuf',
      'gri küf',
      'botrytis',
    ],
    'head_rot': [
      'bas curuk',
      'baş çürük',
      'tabla curuk',
      'sclerotinia bas',
    ],
    'stem_rot': [
      'sap curuk',
      'sap çürük',
      'sap kararm',
      'phomopsis',
      'phoma',
      'kok curuk',
    ],
    'wilt': [
      'solgun',
      'pörsü',
      'porsu',
      'bayilm',
      'duşuyor',
      'dususuyor',
      'verticillium',
      'fusarium',
    ],
    'mosaic_virus': [
      'mozaik',
      'damar arasi sararma',
      'virus belirtisi',
    ],
    'anthracnose': [
      'antraknoz',
    ],
    'bacterial_blight': [
      'bakteriyel yanik',
      'bakteriyel leke',
    ],
  };

  static const _pestLexicon = <String, List<String>>{
    'helicoverpa': [
      'yesil kurt',
      'yeşil kurt',
      'helicoverpa',
      'kurt var',
      'tirtil',
      'tırtıl',
    ],
    'aphid': [
      'yaprak biti',
      'yapragin altinda kucuk bocek',
      'afid',
    ],
    'thrips': [
      'trips',
      'thrips',
    ],
    'stem_borer': [
      'sap delici',
      'gov delik',
    ],
    'spodoptera': [
      'kömur akrebi',
      'komur akrebi',
      'spodoptera',
    ],
    'meadow_moth': [
      'cayir tirtili',
      'çayır tırtılı',
    ],
    'bird': [
      'kus zarari',
      'kus yiyor',
      'kuş zararı',
      'serce',
    ],
    'field_mouse': [
      'fare',
      'tarla faresi',
    ],
    'wireworm': [
      'tel kurdu',
      'agriotes',
    ],
    'snail': [
      'salyangoz',
      'sumuklu',
    ],
    'flea_beetle': [
      'pire bocek',
      'pire böcek',
    ],
  };

  static const _weedLexicon = <String, List<String>>{
    'orobanche': [
      'canavar otu',
      'canavar ot',
      'orobans',
      'orobanş',
      'parazit ot',
    ],
    'amaranthus': [
      'horoz ibig',
      'amaranth',
    ],
    'chenopodium': [
      'sirken',
    ],
    'sorghum_halepense': [
      'kanyas',
      'kanyaş',
    ],
    'xanthium': [
      'domuz pitr',
      'domuz pıtr',
    ],
  };

  // ─── Türkçe etiketler — UI chip metinleri ────────────────────────────
  String _symptomLabel(String k) => switch (k) {
        'leaf_spot' => 'Yaprak lekesi',
        'downy_mildew' => 'Mildiyö',
        'powdery_mildew' => 'Külleme',
        'rust' => 'Pas',
        'grey_mold' => 'Kurşuni küf',
        'head_rot' => 'Baş çürüklüğü',
        'stem_rot' => 'Sap çürüklüğü',
        'wilt' => 'Solgunluk',
        'mosaic_virus' => 'Mozaik virüs',
        'anthracnose' => 'Antraknoz',
        'bacterial_blight' => 'Bakteriyel yanıklık',
        _ => k,
      };
  String _pestLabel(String k) => switch (k) {
        'helicoverpa' => 'Yeşil kurt',
        'aphid' => 'Yaprak biti',
        'thrips' => 'Tripsler',
        'stem_borer' => 'Sap delici',
        'spodoptera' => 'Kömür akrebi',
        'meadow_moth' => 'Çayır tırtılı',
        'bird' => 'Kuş zararı',
        'field_mouse' => 'Tarla faresi',
        'wireworm' => 'Tel kurdu',
        'snail' => 'Salyangoz',
        'flea_beetle' => 'Pire böceği',
        _ => k,
      };
  String _weedLabel(String k) => switch (k) {
        'orobanche' => 'Canavar otu (orobanş)',
        'amaranthus' => 'Horoz ibiği',
        'chenopodium' => 'Sirken',
        'sorghum_halepense' => 'Kanyaş',
        'xanthium' => 'Domuz pıtrağı',
        _ => k,
      };
  String _stageLabel(String k) => switch (k) {
        'germination' => 'Çimlenme',
        'seedling' => 'Fide',
        'vegetative' => 'Vejetatif',
        'pre_flowering' => 'Çiçeklenme öncesi',
        'flowering' => 'Çiçeklenme',
        'grain_filling' => 'Dane dolumu',
        'maturity' => 'Olgunluk',
        'harvest' => 'Hasat',
        _ => k,
      };
}

/// Parser çıktısı — facts override haritası + UI'a gösterilecek
/// "anladığım sinyaller" rozetleri + öneri kategorileri.
class FarmerQueryAnalysis {
  final Map<String, Object?> facts;
  final List<FarmerQuerySignal> signals;
  final List<String> suggestedCategories;

  const FarmerQueryAnalysis({
    required this.facts,
    required this.signals,
    required this.suggestedCategories,
  });

  bool get isEmpty => signals.isEmpty && facts.isEmpty;
}

/// Bir parse sinyali — kullanıcıya "şunu anladım" rozeti olarak
/// gösterilir. Şeffaflık için: kara kutu yok.
class FarmerQuerySignal {
  final String kind; // 'belirti'|'zararlı'|'yabancı ot'|'evre'|'koşul'
  final String label;
  final String factKey;
  final Object? factValue;

  const FarmerQuerySignal({
    required this.kind,
    required this.label,
    required this.factKey,
    required this.factValue,
  });
}
