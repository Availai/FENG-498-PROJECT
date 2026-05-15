import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/turkiye_crop_guides.dart';
import '../data/turkish_crops_repository.dart';
import '../models/advisor_models.dart';
import 'crop_recommendations.dart';
import 'farmer_query_parser.dart';

final advisorServiceProvider = Provider<VerifiedAdvisorService>((ref) {
  return const VerifiedAdvisorService();
});

class VerifiedAdvisorService {
  final TurkishCropsRepository? cropsRepository;
  final FarmerQueryParser parser;
  final bool loadRepository;

  const VerifiedAdvisorService({
    this.cropsRepository,
    this.parser = const FarmerQueryParser(),
    this.loadRepository = true,
  });

  Future<AdvisorAnswer> answer(AdvisorQuery query) async {
    final question = query.text.trim();
    if (question.isEmpty) {
      return AdvisorAnswer.noVerifiedSource(
        question: question,
        intent: AdvisorIntent.general,
      );
    }

    final repo = cropsRepository ?? TurkishCropsRepository.instance;
    if (loadRepository) {
      await repo.ensureReady();
    }

    final analysis = parser.analyze(question);
    final intent = _intentFrom(analysis, question);
    final guide = _detectGuide(question, query.fieldContext);
    final signals = analysis.signals
        .map((signal) => '${signal.kind}: ${signal.label}')
        .toList(growable: false);

    final fieldItems = _fieldItems(query.fieldContext, intent);
    if (fieldItems.isNotEmpty) {
      return _buildAnswer(
        question: question,
        intent: intent,
        cropName: guide?.cropName,
        signals: signals,
        items: fieldItems,
        repo: repo,
        fromField: true,
      );
    }

    final appDataAnswer = _appDataAnswer(
      question: question,
      appContext: query.appContext,
    );
    if (appDataAnswer != null) return appDataAnswer;

    final appHelpAnswer = _appHelpAnswer(question);
    if (appHelpAnswer != null) return appHelpAnswer;

    if (guide == null) {
      return AdvisorAnswer.noVerifiedSource(
        question: question,
        intent: intent,
        understoodSignals: signals,
      );
    }

    final items = <_AdvisorKnowledgeItem>[
      ..._recommendationItems(guide, intent),
      ..._guideItems(guide, intent),
      ..._v2Items(repo, guide, intent, question),
    ];
    items.sort((a, b) => b.score.compareTo(a.score));

    final selected = items.where((item) => item.sourceRefs.isNotEmpty).take(4);
    if (selected.isEmpty) {
      return AdvisorAnswer.noVerifiedSource(
        question: question,
        intent: intent,
        cropName: guide.cropName,
        understoodSignals: signals,
      );
    }

    return _buildAnswer(
      question: question,
      intent: intent,
      cropName: guide.cropName,
      signals: signals,
      items: selected.toList(growable: false),
      repo: repo,
    );
  }

  AdvisorIntent _intentFrom(FarmerQueryAnalysis analysis, String question) {
    final categories = analysis.suggestedCategories.toSet();
    if (categories.contains('disease_risk')) return AdvisorIntent.disease;
    if (categories.contains('pest_risk')) return AdvisorIntent.pest;
    if (categories.contains('weed_management')) return AdvisorIntent.weed;
    if (categories.contains('irrigation')) return AdvisorIntent.irrigation;
    if (categories.contains('fertilization')) {
      return AdvisorIntent.fertilization;
    }
    if (categories.contains('soil_analysis')) return AdvisorIntent.soilAnalysis;
    if (categories.contains('harvest')) return AdvisorIntent.harvest;
    if (categories.contains('sowing_or_planting')) {
      return AdvisorIntent.sowingOrPlanting;
    }
    if (categories.contains('weather_warning')) {
      return AdvisorIntent.weatherWarning;
    }

    final text = _normalize(question);
    if (text.contains('sula')) return AdvisorIntent.irrigation;
    if (text.contains('gubre') || text.contains('azot')) {
      return AdvisorIntent.fertilization;
    }
    if (text.contains('toprak') || text.contains('analiz')) {
      return AdvisorIntent.soilAnalysis;
    }
    if (text.contains('hasat')) return AdvisorIntent.harvest;
    if (text.contains('ekim') || text.contains('dikim')) {
      return AdvisorIntent.sowingOrPlanting;
    }
    if (text.contains('ilac') ||
        text.contains('leke') ||
        text.contains('hastalik')) {
      return AdvisorIntent.disease;
    }
    return AdvisorIntent.general;
  }

  AdvisorAnswer? _appDataAnswer({
    required String question,
    required AdvisorAppContext? appContext,
  }) {
    final text = _normalize(question);
    if (!_containsAny(text, const [
      'kactarlam',
      'tarlalarim',
      'kayitlitarl',
      'hangitarl',
      'hangiurun',
      'urunlerim',
      'neektim',
      'ektiklerim',
      'tarlalarimilistele',
    ])) {
      return null;
    }

    final fields = appContext?.fields ?? const <AdvisorFieldSummary>[];
    if (fields.isEmpty) {
      return AdvisorAnswer(
        originalQuestion: question,
        intent: AdvisorIntent.general,
        confidence: AdvisorConfidence.limited,
        shortAnswer:
            'Uygulamada kayıtlı tarla görünmüyor. İlk kayıt için Tarlalarım ekranındaki Yeni Tarla Çiz düğmesini kullanın.',
        sections: const [
          AdvisorAnswerSection(
            title: 'Ne yapmalı',
            bullets: [
              'Alt menüden Tarlalarım ekranını açın.',
              'Yeni Tarla Çiz ile haritada köşe noktalarını işaretleyip alanı kaydedin.',
              'Tarla kaydedilince takvim, günlük rehber, harita ve maliyet ekranlarında kullanılabilir.',
            ],
          ),
        ],
        sources: const [
          AdvisorSource(
            id: 'app.local.fields',
            title: 'Kayıtlı tarla verileri',
            institution: 'Uygulama içi kayıtlar',
            sourceType: 'app_module',
            isTrusted: true,
          ),
        ],
        safetyNote:
            'Bu yanıt yalnız uygulamadaki yerel kayıt durumunu açıklar; tarımsal uygulama kararı değildir.',
      );
    }

    final totalArea = fields
        .map((field) => field.areaDekar ?? 0)
        .fold<double>(0, (sum, area) => sum + area);
    final fieldLines = fields.take(8).map((field) {
      final crop = field.cropName == null ? '' : ' - ${field.cropName}';
      final area = field.areaDekar == null
          ? ''
          : ' (${field.areaDekar!.toStringAsFixed(2)} da)';
      return '${field.fieldName}$crop$area';
    }).toList(growable: false);
    final cropNames = fields
        .map((field) => field.cropName?.trim() ?? '')
        .where((crop) => crop.isNotEmpty && crop != 'Bilinmiyor')
        .toSet()
        .toList(growable: false);

    return AdvisorAnswer(
      originalQuestion: question,
      intent: AdvisorIntent.general,
      confidence: AdvisorConfidence.limited,
      shortAnswer: totalArea > 0
          ? 'Uygulamada ${fields.length} kayıtlı tarla ve toplam yaklaşık ${totalArea.toStringAsFixed(2)} dekar alan görünüyor.'
          : 'Uygulamada ${fields.length} kayıtlı tarla görünüyor.',
      sections: [
        AdvisorAnswerSection(
          title: 'Kayıtlı bilgiler',
          bullets: fieldLines,
        ),
        if (cropNames.isNotEmpty)
          AdvisorAnswerSection(
            title: 'Ürünler',
            bullets: ['Kayıtlarda görünen ürünler: ${cropNames.join(', ')}.'],
          ),
        const AdvisorAnswerSection(
          title: 'Ne yapmalı',
          bullets: [
            'Tarla kartına dokunarak ürün yerleşimi, günlük rehber, tarla günlüğü ve maliyet ekranlarına geçebilirsiniz.',
            'Detaylı canlı tavsiye için Danışmana Sor ekranında ilgili tarlayı seçerek tekrar sorun.',
          ],
        ),
      ],
      sources: const [
        AdvisorSource(
          id: 'app.local.fields',
          title: 'Kayıtlı tarla verileri',
          institution: 'Uygulama içi kayıtlar',
          sourceType: 'app_module',
          isTrusted: true,
        ),
      ],
      safetyNote:
          'Bu yanıt uygulamadaki kayıt özetidir; ürün, ilaç, gübre veya sulama uygulaması için kaynaklı tarım yanıtı ayrıca gerekir.',
    );
  }

  AdvisorAnswer? _appHelpAnswer(String question) {
    final normalized = _normalize(question);
    final hasAppCue = _isAppUsageQuestion(normalized);
    _AppHelpTopic? best;
    var bestScore = 0;

    for (final topic in _appHelpTopics) {
      var score = 0;
      for (final term in topic.terms) {
        if (normalized.contains(_normalize(term))) score += 10;
      }
      if (normalized.contains(_normalize(topic.title))) score += 12;
      if (hasAppCue) score += 3;
      if (score > bestScore) {
        best = topic;
        bestScore = score;
      }
    }

    if (best == null || bestScore < (hasAppCue ? 10 : 18)) return null;

    return AdvisorAnswer(
      originalQuestion: question,
      intent: AdvisorIntent.general,
      confidence: AdvisorConfidence.limited,
      shortAnswer:
          '${best.title} için uygulama içindeki yol: ${best.navigation}.',
      sections: [
        AdvisorAnswerSection(title: 'Ne yapmalı', bullets: best.actions),
        AdvisorAnswerSection(title: 'Neden', bullets: best.reasons),
      ],
      sources: [
        AdvisorSource(
          id: best.id,
          title: best.title,
          institution: 'Uygulama içi ekran envanteri',
          sourceType: 'app_module',
          reliability: 'local',
          isTrusted: true,
        ),
      ],
      safetyNote:
          'Bu yanıt uygulama kullanımı içindir. Tarımsal teşhis, ilaç, doz veya kesin uygulama kararı için yalnız kaynaklı tarım yanıtları esas alınmalıdır.',
    );
  }

  bool _isAppUsageQuestion(String normalizedText) {
    return _containsAny(normalizedText, const [
      'nasil',
      'nerede',
      'nereden',
      'hangiekran',
      'hangibolum',
      'ekran',
      'menu',
      'uygulama',
      'acilir',
      'acarim',
      'bulurum',
      'kullan',
      'kayit',
      'ekle',
      'ciz',
      'sil',
      'takip',
      'goster',
      'yardim',
      'ozellik',
      'neyapar',
      'neler',
    ]);
  }

  bool _containsAny(String normalizedText, List<String> needles) {
    for (final needle in needles) {
      if (normalizedText.contains(_normalize(needle))) return true;
    }
    return false;
  }

  TurkiyeCropGuide? _detectGuide(
    String question,
    AdvisorFieldContext? fieldContext,
  ) {
    final direct = TurkiyeCropGuides.lookup(question);
    if (direct != null) return direct;
    if (fieldContext == null) return null;
    if (fieldContext.cropNames.length == 1) {
      return TurkiyeCropGuides.lookup(fieldContext.cropNames.first);
    }
    for (final cropName in fieldContext.cropNames) {
      if (_normalize(question).contains(_normalize(cropName))) {
        return TurkiyeCropGuides.lookup(cropName);
      }
    }
    return null;
  }

  List<_AdvisorKnowledgeItem> _fieldItems(
    AdvisorFieldContext? context,
    AdvisorIntent intent,
  ) {
    if (context == null) return const [];
    final out = <_AdvisorKnowledgeItem>[];
    for (final rec in context.recommendations) {
      if (rec.sourceRefs.isEmpty) continue;
      if (!_fieldRecommendationMatches(rec, intent)) continue;
      out.add(_AdvisorKnowledgeItem(
        title: rec.title,
        action: _sanitize(rec.actionHint),
        reason: _sanitize(rec.reasonText),
        sourceRefs: rec.sourceRefs,
        score: 100,
      ));
    }
    return out.take(3).toList(growable: false);
  }

  bool _fieldRecommendationMatches(
    AdvisorFieldRecommendation rec,
    AdvisorIntent intent,
  ) {
    final text = _normalize(
      '${rec.title} ${rec.reasonText} ${rec.actionHint} ${rec.activityType ?? ''}',
    );
    switch (intent) {
      case AdvisorIntent.irrigation:
        return text.contains('sula') || text.contains('water');
      case AdvisorIntent.fertilization:
      case AdvisorIntent.soilAnalysis:
        return text.contains('gubre') ||
            text.contains('besle') ||
            text.contains('toprak');
      case AdvisorIntent.disease:
      case AdvisorIntent.pest:
      case AdvisorIntent.weed:
        return text.contains('gozlem') ||
            text.contains('hastalik') ||
            text.contains('zarar') ||
            text.contains('bku') ||
            text.contains('bkü');
      case AdvisorIntent.harvest:
        return text.contains('hasat');
      case AdvisorIntent.sowingOrPlanting:
        return text.contains('ekim') || text.contains('dikim');
      case AdvisorIntent.weatherWarning:
        return text.contains('don') ||
            text.contains('sicak') ||
            text.contains('yagmur') ||
            text.contains('ruzgar');
      case AdvisorIntent.general:
        return true;
    }
  }

  List<_AdvisorKnowledgeItem> _recommendationItems(
    TurkiyeCropGuide guide,
    AdvisorIntent intent,
  ) {
    final out = <_AdvisorKnowledgeItem>[];
    for (final rec in CropRecommendationsService.recommendationsFor(guide)) {
      if (!_categoryMatches(rec.category, intent)) continue;
      out.add(_AdvisorKnowledgeItem(
        title: rec.title,
        action: _sanitize(rec.action),
        reason: _sanitize(rec.reason ?? ''),
        sourceRefs: rec.sources,
        score: 70,
        requiresBkuCheck: rec.requiresBkuCheck,
      ));
    }
    return out;
  }

  bool _categoryMatches(TavsiyeKategori category, AdvisorIntent intent) {
    switch (intent) {
      case AdvisorIntent.irrigation:
        return category == TavsiyeKategori.sulama;
      case AdvisorIntent.fertilization:
      case AdvisorIntent.soilAnalysis:
        return category == TavsiyeKategori.besleme;
      case AdvisorIntent.disease:
      case AdvisorIntent.pest:
      case AdvisorIntent.weed:
        return category == TavsiyeKategori.koruma ||
            category == TavsiyeKategori.bku;
      case AdvisorIntent.harvest:
        return category == TavsiyeKategori.hasat;
      case AdvisorIntent.sowingOrPlanting:
        return category == TavsiyeKategori.ekim;
      case AdvisorIntent.weatherWarning:
        return category == TavsiyeKategori.bolge ||
            category == TavsiyeKategori.sulama;
      case AdvisorIntent.general:
        return category == TavsiyeKategori.ekim ||
            category == TavsiyeKategori.sulama ||
            category == TavsiyeKategori.koruma;
    }
  }

  List<_AdvisorKnowledgeItem> _guideItems(
    TurkiyeCropGuide guide,
    AdvisorIntent intent,
  ) {
    if (intent == AdvisorIntent.irrigation) {
      return [
        _AdvisorKnowledgeItem(
          title: 'Sulama özeti',
          action: _sanitize(guide.irrigationSummary),
          reason:
              'Sulama notu ürün rehberindeki Türkiye kaynaklı değerlerden alınır.',
          sourceRefs: guide.sourceRefs,
          score: 55,
        ),
      ];
    }
    if (intent == AdvisorIntent.fertilization ||
        intent == AdvisorIntent.soilAnalysis) {
      return [
        _AdvisorKnowledgeItem(
          title: 'Besleme özeti',
          action: _sanitize(guide.fertilizerSummary),
          reason:
              'Toprak analizi olmadan kesin gübre miktarı önerilmez; rehber genel yön verir.',
          sourceRefs: guide.sourceRefs,
          score: 55,
        ),
      ];
    }
    if (intent == AdvisorIntent.disease ||
        intent == AdvisorIntent.pest ||
        intent == AdvisorIntent.weed) {
      return guide.pests.take(2).map((pest) {
        return _AdvisorKnowledgeItem(
          title: pest.name,
          action:
              'Önce düzenli gözlem yapın; eşik ve belirti doğrulanmadan kimyasal uygulama kararı vermeyin.',
          reason: _sanitize(
            '${pest.symptoms} ${pest.monitoring} ${pest.integratedControl}',
          ),
          sourceRefs: guide.sourceRefs,
          score: 55,
          requiresBkuCheck: true,
        );
      }).toList(growable: false);
    }
    if (intent == AdvisorIntent.harvest) {
      return [
        _AdvisorKnowledgeItem(
          title: 'Hasat ve kalite',
          action: _sanitize(guide.harvestQualityNotes),
          reason: 'Hasat aralığı: ${guide.harvestWindow}.',
          sourceRefs: guide.sourceRefs,
          score: 55,
        ),
      ];
    }
    if (intent == AdvisorIntent.sowingOrPlanting) {
      return [
        _AdvisorKnowledgeItem(
          title: 'Ekim / dikim',
          action: _sanitize(guide.plantingTip),
          reason: 'Ekim aralığı: ${guide.sowingWindow}.',
          sourceRefs: guide.sourceRefs,
          score: 55,
        ),
      ];
    }
    return [
      _AdvisorKnowledgeItem(
        title: guide.cropName,
        action: _sanitize(guide.summary),
        reason: _sanitize(guide.regionNote),
        sourceRefs: guide.sourceRefs,
        score: 40,
      ),
    ];
  }

  List<_AdvisorKnowledgeItem> _v2Items(
    TurkishCropsRepository repo,
    TurkiyeCropGuide guide,
    AdvisorIntent intent,
    String question,
  ) {
    final stableId = _stableIdForGuide(guide);
    if (stableId == null) return const [];
    final bundle = repo.findV2ByStableId(stableId);
    if (bundle == null) return const [];

    final records = _v2Records(bundle, intent);
    final out = <_AdvisorKnowledgeItem>[];
    for (final record in records) {
      final title = _firstText(record, const [
        'name_tr',
        'label_tr',
        'title',
        'phase',
        'id',
      ]);
      if (title == null) continue;
      final sources = _sourceRefs(record);
      if (sources.isEmpty) continue;
      final action = _firstText(record, const [
            'summary',
            'recommendation',
            'action',
            'notes',
          ]) ??
          _fallbackAction(intent);
      final reason = _evidenceText(record);
      out.add(_AdvisorKnowledgeItem(
        title: title,
        action: _sanitize(action),
        reason: _sanitize(reason),
        sourceRefs: sources,
        score: _normalize('$title $reason').contains(_normalize(question))
            ? 90
            : 50,
        requiresBkuCheck: record['requires_bku_check'] == true,
      ));
    }
    return out;
  }

  List<Map<String, dynamic>> _v2Records(
    CropV2Bundle bundle,
    AdvisorIntent intent,
  ) {
    switch (intent) {
      case AdvisorIntent.disease:
        return bundle.diseases;
      case AdvisorIntent.pest:
        return bundle.pests;
      case AdvisorIntent.weed:
        return bundle.weeds;
      case AdvisorIntent.irrigation:
      case AdvisorIntent.weatherWarning:
        return bundle.irrigationRules;
      case AdvisorIntent.fertilization:
      case AdvisorIntent.soilAnalysis:
        return bundle.fertilizerRules;
      case AdvisorIntent.sowingOrPlanting:
      case AdvisorIntent.harvest:
        return bundle.growthStages;
      case AdvisorIntent.general:
        return bundle.evidence;
    }
  }

  AdvisorAnswer _buildAnswer({
    required String question,
    required AdvisorIntent intent,
    required String? cropName,
    required List<String> signals,
    required List<_AdvisorKnowledgeItem> items,
    required TurkishCropsRepository repo,
    bool fromField = false,
  }) {
    final sources = _trustedSources(
      items.expand((item) => item.sourceRefs).toList(growable: false),
      repo,
    );
    if (!sources.any((source) => source.isTrusted)) {
      return AdvisorAnswer.noVerifiedSource(
        question: question,
        intent: intent,
        cropName: cropName,
        understoodSignals: signals,
      );
    }

    final primary = items.first;
    final actions = items
        .map((item) => item.action)
        .where((text) => text.isNotEmpty)
        .toSet()
        .take(5)
        .toList(growable: false);
    final reasons = items
        .map((item) => item.reason)
        .where((text) => text.isNotEmpty)
        .toSet()
        .take(4)
        .toList(growable: false);
    final sections = <AdvisorAnswerSection>[
      AdvisorAnswerSection(
        title: 'Ne yapmalı',
        bullets: actions.isEmpty
            ? const ['Kaynaklı rehberdeki uygulama notlarını kontrol edin.']
            : actions,
      ),
      if (reasons.isNotEmpty)
        AdvisorAnswerSection(title: 'Neden', bullets: reasons),
      if (intent == AdvisorIntent.disease ||
          intent == AdvisorIntent.pest ||
          intent == AdvisorIntent.weed ||
          primary.requiresBkuCheck)
        const AdvisorAnswerSection(
          title: 'Güvenlik notu',
          bullets: [
            'Bitki koruma ürünü gerekiyorsa BKÜ veritabanında güncel ruhsat, etiket, doz ve hasada bekleme süresi kontrol edilmelidir.',
            'Kesin teşhis ve uygulama kararı için il/ilçe tarım müdürlüğü veya yetkili uzman desteği alınmalıdır.',
          ],
        ),
      if (intent == AdvisorIntent.fertilization ||
          intent == AdvisorIntent.soilAnalysis)
        const AdvisorAnswerSection(
          title: 'Toprak analizi',
          bullets: ['Toprak analizi olmadan kesin gübre miktarı önerilmez.'],
        ),
    ];

    final subject = cropName == null ? 'Sorunuz' : '$cropName için sorunuz';
    final contextText = fromField
        ? 'seçili tarladaki kaynaklı kayıtlarla'
        : 'kaynaklı Türkiye kayıtlarıyla';
    return AdvisorAnswer(
      originalQuestion: question,
      intent: intent,
      confidence: AdvisorConfidence.verified,
      cropName: cropName,
      shortAnswer:
          '$subject $contextText eşleştirildi. ${_sanitize(primary.title)} başlığındaki yönergeyi uygulamadan önce kaynak ve güvenlik notlarını kontrol edin.',
      sections: sections,
      sources: sources,
      understoodSignals: signals,
      safetyNote:
          'Bu yanıt yalnız uygulamadaki doğrulanmış kaynak kayıtlarından üretilir; kesin teşhis, marka, doz veya reçete yerine geçmez.',
    );
  }

  List<AdvisorSource> _trustedSources(
    List<String> refs,
    TurkishCropsRepository repo,
  ) {
    final out = <AdvisorSource>[];
    final seen = <String>{};
    for (final raw in refs) {
      final ref = raw.trim();
      if (ref.isEmpty) continue;
      final key = _normalize(ref);
      if (seen.contains(key)) continue;
      seen.add(key);

      if (ref.startsWith('source.')) {
        final source = repo.findSource(ref);
        if (source != null) {
          out.add(AdvisorSource(
            id: source.sourceId,
            title: source.title,
            institution: source.institution,
            sourceType: source.sourceType,
            url: source.url,
            reliability: source.reliability,
            isTrusted: _isTrustedSource(
              title: source.title,
              institution: source.institution,
              sourceType: source.sourceType,
              reliability: source.reliability,
            ),
          ));
          continue;
        }
      }

      out.add(AdvisorSource(
        id: ref.startsWith('source.') ? ref : 'ref.${seen.length}',
        title: ref,
        isTrusted: _isTrustedSource(title: ref),
      ));
    }
    return out;
  }

  bool _isTrustedSource({
    required String title,
    String? institution,
    String? sourceType,
    String? reliability,
  }) {
    final text = _normalize('$title ${institution ?? ''}');
    final trustedInstitution = text.contains('tagem') ||
        text.contains('tarimveorman') ||
        text.contains('bakanligi') ||
        text.contains('batem') ||
        text.contains('caykur') ||
        text.contains('bku') ||
        text.contains('bitkikoruma');
    if (sourceType == null && reliability == null && institution == null) {
      return trustedInstitution;
    }
    final allowedType = sourceType == 'official' ||
        sourceType == 'research_institute' ||
        sourceType == 'public_agency';
    final highReliability = reliability == null || reliability == 'high';
    return (trustedInstitution || allowedType) && highReliability;
  }

  List<String> _sourceRefs(Map<String, dynamic> record) {
    final out = <String>{};
    final sourceIds = record['source_ids'];
    if (sourceIds is List) {
      out.addAll(sourceIds.map((e) => e?.toString() ?? '').where(
            (text) => text.isNotEmpty,
          ));
    }
    final evidence = record['evidence'];
    if (evidence is List) {
      for (final item in evidence.whereType<Map>()) {
        final sourceId = item['source_id']?.toString();
        if (sourceId != null && sourceId.isNotEmpty) out.add(sourceId);
      }
    }
    return out.toList(growable: false);
  }

  String _evidenceText(Map<String, dynamic> record) {
    final evidence = record['evidence'];
    if (evidence is! List) return '';
    return evidence
        .whereType<Map>()
        .map((e) => e['evidence_text']?.toString() ?? '')
        .where((text) => text.trim().isNotEmpty)
        .take(2)
        .join(' ');
  }

  String _fallbackAction(AdvisorIntent intent) {
    if (intent == AdvisorIntent.disease ||
        intent == AdvisorIntent.pest ||
        intent == AdvisorIntent.weed) {
      return 'Belirtiyi kaydedin, yayılımı kontrol edin ve eşik doğrulanmadan kimyasal uygulama kararı vermeyin.';
    }
    if (intent == AdvisorIntent.irrigation) {
      return 'Sulama kararını toprak nemi, yağış ve ürün dönemine göre verin.';
    }
    if (intent == AdvisorIntent.fertilization ||
        intent == AdvisorIntent.soilAnalysis) {
      return 'Toprak analizi sonucuna göre besleme planı oluşturun.';
    }
    return 'Kaynaklı ürün rehberindeki notları kontrol edin.';
  }

  String? _firstText(Map<String, dynamic> record, List<String> keys) {
    for (final key in keys) {
      final value = record[key];
      if (value == null) continue;
      final text = value.toString().trim();
      if (text.isNotEmpty) return text;
    }
    return null;
  }

  String? _stableIdForGuide(TurkiyeCropGuide guide) {
    switch (guide.id) {
      case 'aycicegi':
        return 'crop.sunflower';
      case 'domates':
        return 'crop.tomato';
      case 'misir':
        return 'crop.corn';
      case 'portakal':
        return 'crop.orange';
      case 'cay':
        return 'crop.tea';
    }
    return null;
  }

  String _sanitize(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return trimmed;
    if (_hasUnsafeDoseOrChemical(trimmed)) {
      return 'Bu konuda doğrudan kimyasal ürün veya kesin doz verilmez; resmi BKÜ etiketi, toprak analizi ve uzman onayı gerekir.';
    }
    return trimmed;
  }

  bool _hasUnsafeDoseOrChemical(String text) {
    final lower = text.toLowerCase();
    const banned = [
      'fungisit',
      'insektisit',
      'akarisit',
      'mancozeb',
      'metalaksil',
      'spinosad',
      'triazol',
    ];
    if (banned.any(lower.contains)) return true;
    return RegExp(
      r'\b\d+([,.]\d+)?\s*(kg|g|ml|l)\s*/\s*(da|dekar)\b',
      caseSensitive: false,
    ).hasMatch(text);
  }

  String _normalize(String input) {
    return input
        .toLowerCase()
        .replaceAll('ı', 'i')
        .replaceAll('İ', 'i')
        .replaceAll('ğ', 'g')
        .replaceAll('ü', 'u')
        .replaceAll('ş', 's')
        .replaceAll('ö', 'o')
        .replaceAll('ç', 'c')
        .replaceAll(RegExp(r'[^a-z0-9]'), '');
  }
}

class _AppHelpTopic {
  final String id;
  final String title;
  final String navigation;
  final List<String> terms;
  final List<String> actions;
  final List<String> reasons;

  const _AppHelpTopic({
    required this.id,
    required this.title,
    required this.navigation,
    required this.terms,
    required this.actions,
    required this.reasons,
  });
}

const _appHelpTopics = [
  _AppHelpTopic(
    id: 'app.help.overview',
    title: 'Uygulama genel kapsamı',
    navigation:
        'Alt menüde Özet, Tarlalarım ve Takvim; diğer araçlar için Daha Fazla menüsü',
    terms: [
      'yardım',
      'özellik',
      'neler yapabiliyorsun',
      'uygulamada ne var',
      'uygulama',
      'her şey',
      'genel',
    ],
    actions: [
      'Tarla kaydı, hava durumu, takvim, sulama, günlük rehber, görüntü analizi, harita, kayıtlı veriler ve kaynaklı bitki rehberleri hakkında soru yazabilirsiniz.',
      'Uygulama kullanımı sorularında ekran yolunu ve yapılacak adımları gösterir.',
      'Tarımsal bilgi sorularında yalnız uygulamada kaynak kanıtı olan kayıtları kullanır.',
    ],
    reasons: [
      'Danışman uygulama ekran envanterini yerel olarak bilir; internet veya LLM gerekmez.',
      'Tarım iddiaları ile uygulama kullanım yönergeleri ayrı güvenlik kurallarıyla değerlendirilir.',
    ],
  ),
  _AppHelpTopic(
    id: 'app.help.fields',
    title: 'Tarlalarım ve tarla çizimi',
    navigation: 'Alt menü > Tarlalarım > Yeni Tarla Çiz',
    terms: [
      'tarla',
      'yeni tarla',
      'tarla çiz',
      'poligon',
      'gps',
      'konum',
      'alan',
      'dekar',
      'köşe',
    ],
    actions: [
      'Tarlalarım ekranına girin ve Yeni Tarla Çiz düğmesine basın.',
      'Haritada tarla köşelerini işaretleyip alanı kaydedin.',
      'Kayıt sonrası tarla kartına dokunarak detay, günlük rehber, takvim ve maliyet kayıtlarına geçin.',
    ],
    reasons: [
      'Tarla kaydı, uygulamadaki takvim, sulama, canlı tavsiye ve harita akışlarının ortak temelidir.',
      'Konum alınamazsa harita Türkiye merkezinden açılır; tarla elle bulunup çizilebilir.',
    ],
  ),
  _AppHelpTopic(
    id: 'app.help.field_detail',
    title: 'Tarla detayı ve ürün yerleşimi',
    navigation: 'Alt menü > Tarlalarım > bir tarla kartı',
    terms: [
      'tarla detayı',
      'ürün yerleştir',
      'bitki ek',
      'bölge',
      'zone',
      'sıra aralığı',
      'bitki aralığı',
      'sağlık durumu',
      'baktığı yön',
    ],
    actions: [
      'Tarla kartını açın ve ürün/bölge ekleme araçlarını kullanın.',
      'Ürün için sıra aralığı, bitki aralığı, ekim tarihi ve hasat gününü girin.',
      'Bitki veya bölge üzerinde işlem yaparak sağlık durumu, yön, silme ve çoklu seçim işlemlerini yönetin.',
    ],
    reasons: [
      'Tarla detayı ekranı tarla yönetiminin ana komuta merkezidir.',
      'Ürün yerleşimi ve aktivite kayıtları günlük rehberin daha doğru tavsiye üretmesini sağlar.',
    ],
  ),
  _AppHelpTopic(
    id: 'app.help.daily_guide',
    title: 'Günlük rehber ve yapılacaklar',
    navigation: 'Tarla detayı > Günlük Rehber veya Yapılacaklar bölümü',
    terms: [
      'günlük rehber',
      'bugün ne yapmalı',
      'yapılacak',
      'tavsiye',
      'canlı tavsiye',
      'görev',
      'iş listesi',
      'alarm',
    ],
    actions: [
      'İlgili tarlayı seçin ve Günlük Rehber ekranını açın.',
      'Sulama, gözlem, hasat, gübreleme ve hava uyarılarını öncelik sırasıyla kontrol edin.',
      'Bir işi yaptıktan sonra uygulama içinden aktivite olarak kaydedin; tavsiyeler buna göre yenilenir.',
    ],
    reasons: [
      'Günlük rehber tarla ürünleri, aktivite geçmişi, büyüme durumu ve hava/toprak bağlamını birleştirir.',
      'Kaynak referansı taşıyan canlı tavsiyeler Danışmana Sor ekranında seçili tarla bağlamı olarak da kullanılabilir.',
    ],
  ),
  _AppHelpTopic(
    id: 'app.help.irrigation',
    title: 'Akıllı sulama',
    navigation: 'Tarla detayı > Sulama veya Akıllı Sulama Programı',
    terms: [
      'sulama programı',
      'akıllı sulama',
      'su ver',
      'sulama',
      'eto',
      'fao',
      'yağmur',
      'su açığı',
    ],
    actions: [
      'Tarlayı açıp sulama programı veya günlük rehberdeki sulama kartını kontrol edin.',
      'Sulama yaptıysanız miktarı veya süreyi aktivite olarak kaydedin.',
      'Kesin sulama kararı için seçili tarla bağlamıyla Danışmana Sor ekranında tekrar sorun.',
    ],
    reasons: [
      'Sulama akışı tarla alanı, ürün su ihtiyacı, yağış ve kayıtlı sulama aktivitelerini birlikte değerlendirir.',
      'Hava/toprak verisi yoksa danışman bunu açıkça belirtir ve tahmin yürütmez.',
    ],
  ),
  _AppHelpTopic(
    id: 'app.help.calendar',
    title: 'Tarım takvimi',
    navigation: 'Alt menü > Takvim',
    terms: [
      'takvim',
      'etkinlik',
      'ekim tarihi',
      'hasat tarihi',
      'hatırlatma',
      'plan',
      'program',
    ],
    actions: [
      'Takvim ekranında ekim, hasat, sulama ve gözlem etkinliklerini tarih sırasıyla izleyin.',
      'Tarla detayında ürün ve aktivite bilgisi ekledikçe takvim kayıtları daha anlamlı hale gelir.',
      'Gelecek tarihli otomatik planları gerçek yapılmış işlem gibi kaydetmeyin; uygulama bunları ayrı değerlendirir.',
    ],
    reasons: [
      'Takvim, tarla yönetiminde zamanlamayı görünür hale getirir.',
      'Canlı rehber geçmiş ve planlanmış etkinlikleri ayırarak yanlış sulama/gübreleme hesabını önler.',
    ],
  ),
  _AppHelpTopic(
    id: 'app.help.camera',
    title: 'Görüntü analizi',
    navigation: 'Daha Fazla > Görüntü Analizi',
    terms: [
      'kamera',
      'fotoğraf',
      'görüntü',
      'analiz',
      'hastalık teşhisi',
      'bitki fotoğrafı',
      'yaprak fotoğrafı',
    ],
    actions: [
      'Görüntü Analizi ekranını açıp bitki fotoğrafını seçin veya çekin.',
      'Sonucu kesin teşhis kabul etmeyin; belirtileri tarla gözlemi ve uzman kontrolüyle doğrulayın.',
      'Geçmiş analizler Kayıtlı Verilerim ekranından kontrol edilebilir.',
    ],
    reasons: [
      'Görüntü analizi karar desteğidir; bitki koruma ürünü, doz veya reçete yerine geçmez.',
      'Hastalık ve zararlı kararlarında BKÜ ve il/ilçe müdürlüğü kontrolü gereklidir.',
    ],
  ),
  _AppHelpTopic(
    id: 'app.help.records',
    title: 'Kayıtlı veriler ve geçmiş',
    navigation: 'Daha Fazla > Kayıtlı Veriler',
    terms: [
      'kayıtlı veriler',
      'geçmiş',
      'analiz geçmişi',
      'çevre geçmişi',
      'raporlar',
      'kayıtlarım',
    ],
    actions: [
      'Kayıtlı Veriler ekranında analiz geçmişi ve çevre geçmişi sekmelerini kontrol edin.',
      'Tarla bazlı yapılan işleri görmek için ilgili tarlanın Tarla Günlüğü ekranını açın.',
      'Eski kayıtları karşılaştırırken tarih ve tarla adını kontrol edin.',
    ],
    reasons: [
      'Geçmiş kayıtlar çevrimdışı tutulur ve internet yokken de incelenebilir.',
      'Tarla günlüğü, canlı tavsiyelerin hangi işlerin yapıldığını anlamasına yardım eder.',
    ],
  ),
  _AppHelpTopic(
    id: 'app.help.guides',
    title: 'Kaynaklı bitki rehberleri ve tavsiyeler',
    navigation: 'Daha Fazla > Tavsiyeler veya Bitki Gelişim Rehberi',
    terms: [
      'tavsiyeler',
      'bitki gelişim rehberi',
      'türkiye bitkileri',
      'rehber',
      'ansiklopedi',
      'kaynak',
      'tagem',
      'batem',
      'çaykur',
    ],
    actions: [
      'Tavsiyeler ekranında öncelikli ürünler için kısa kaynaklı önerileri inceleyin.',
      'Bitki Gelişim Rehberi ekranında ekim, sulama, besleme, koruma ve hasat notlarını okuyun.',
      'Danışmana Sor ekranında ürün adını yazarak aynı kaynaklı bilgileri soru-cevap akışında kullanın.',
    ],
    reasons: [
      'Bu bölüm TAGEM, BATEM, ÇAYKUR, Bakanlık ve BKÜ referanslı kayıtları öne çıkarır.',
      'Kaynak yoksa danışman kesin tarımsal bilgi üretmez.',
    ],
  ),
  _AppHelpTopic(
    id: 'app.help.map',
    title: 'Harita merkezi',
    navigation: 'Daha Fazla > Harita Merkezi',
    terms: [
      'harita',
      'uydu',
      'poligon',
      'konum',
      'tarlayı haritada',
      'harita merkezi',
    ],
    actions: [
      'Harita Merkezi ekranında kayıtlı tarla poligonlarını harita üzerinde görüntüleyin.',
      'Yeni alan çizmek için Tarlalarım ekranındaki Yeni Tarla Çiz akışını kullanın.',
      'Konum izni yoksa tarla haritada elle bulunabilir.',
    ],
    reasons: [
      'Harita merkezi kayıtlı tarlaların mekansal kontrolü için kullanılır.',
      'Poligon bilgisi alan hesabı, planlama ve tarla detayı akışlarını besler.',
    ],
  ),
  _AppHelpTopic(
    id: 'app.help.soil',
    title: 'Toprak analizi ve gübreleme',
    navigation: 'Tarla detayı > Toprak/Gübreleme bölümleri',
    terms: [
      'toprak analizi',
      'npk',
      'gübre',
      'gübreleme',
      'ph',
      'kireç',
      'kükürt',
      'besleme',
    ],
    actions: [
      'Toprak analizi sonuçlarını tarla bağlamında değerlendirin.',
      'Analiz yoksa uygulama kesin gübre dozu vermemelidir.',
      'Besleme sorularında ürün ve seçili tarla bağlamı vererek danışmana tekrar sorun.',
    ],
    reasons: [
      'Gübre miktarı toprak analizi, ürün dönemi, alan ve önceki uygulamalara bağlıdır.',
      'Kaynaklı tarım politikası analizsiz kesin doz üretmeyi engeller.',
    ],
  ),
  _AppHelpTopic(
    id: 'app.help.costs',
    title: 'Gelir ve maliyet takibi',
    navigation: 'Tarla detayı > Cüzdan veya Maliyet ekranı',
    terms: [
      'maliyet',
      'gelir',
      'gider',
      'kar',
      'kâr',
      'cüzdan',
      'masraf',
      'satış',
      'hasılat',
    ],
    actions: [
      'İlgili tarlayı açın ve cüzdan/maliyet ekranına girin.',
      'Tohum, gübre, ilaç, işçilik ve diğer masrafları tarih ve tutarla kaydedin.',
      'Hasat ve satış sonrası gelir kayıtlarını ekleyerek tarla bazlı kâr/zarar takibi yapın.',
    ],
    reasons: [
      'Maliyet kayıtları tarla bazında tutulduğunda dekar başına maliyet ve dönemsel kârlılık izlenebilir.',
      'Bu bölüm finansal kayıt içindir; piyasa fiyatı veya yatırım tavsiyesi üretmez.',
    ],
  ),
  _AppHelpTopic(
    id: 'app.help.offline_sync',
    title: 'Çevrimdışı kullanım ve senkronizasyon',
    navigation: 'Uygulama genelinde otomatik; tarla kayıtları yerelde tutulur',
    terms: [
      'çevrimdışı',
      'internet yok',
      'offline',
      'senkron',
      'sync',
      'kuyruk',
      'bulut',
    ],
    actions: [
      'İnternet yokken tarla, aktivite ve yerel kayıt işlemlerine devam edin.',
      'Bağlantı geldiğinde uygulama senkronizasyon kuyruğunu arka planda işler.',
      'Senkron sorunlarında tarla detayı veya ilgili kayıt ekranındaki hata bilgisini kontrol edin.',
    ],
    reasons: [
      'Uygulama çevrimdışı öncelikli tasarlanmıştır.',
      'Yerel kayıtlar önce cihazda saklanır; bulut eşitlemesi bağlantı durumuna göre tamamlanır.',
    ],
  ),
  _AppHelpTopic(
    id: 'app.help.account',
    title: 'Hesap ve oturum',
    navigation: 'Daha Fazla menüsü > profil kartı veya Çıkış Yap',
    terms: [
      'hesap',
      'giriş',
      'çıkış',
      'misafir',
      'kayıt ol',
      'oturum',
      'şifre',
      'profil',
    ],
    actions: [
      'Daha Fazla menüsünü açarak profil durumunu kontrol edin.',
      'Misafir kullanımda çıkış/hesap oluşturma seçeneğiyle kalıcı hesaba geçin.',
      'Oturum kapatmak için aynı menüdeki Çıkış Yap satırını kullanın.',
    ],
    reasons: [
      'Misafir kullanım hızlı başlatır; kalıcı hesap eşitleme ve cihaz değişimi için daha uygundur.',
      'Kimlik doğrulama Firebase Auth tarafından yönetilir; şifre uygulamada düz metin saklanmaz.',
    ],
  ),
  _AppHelpTopic(
    id: 'app.help.market',
    title: 'Pazar ve paylaşım',
    navigation: 'Analiz sonucundan veya pazar/topluluk ekranından ilgili akış',
    terms: [
      'pazar',
      'ilan',
      'satış',
      'topluluk',
      'paylaş',
      'market',
      'alıcı',
    ],
    actions: [
      'Pazar ekranında ürün ilanı veya paylaşım akışını kullanın.',
      'Analiz sonucundan ilgili ürün/hastalık bilgisiyle pazar veya paylaşım ekranına geçilebilir.',
      'İlanda ürün, miktar ve açıklama bilgilerini net girin.',
    ],
    reasons: [
      'Pazar bölümü kayıt ve paylaşım kolaylığı sağlar; fiyat garantisi veya finansal tavsiye vermez.',
      'Kişisel bilgi paylaşırken dikkatli olunmalıdır.',
    ],
  ),
  _AppHelpTopic(
    id: 'app.help.harvest_seed',
    title: 'Tohum seçimi, ürün eşleştirme ve hasat tahmini',
    navigation:
        'İlgili araç ekranları veya tarla detayı içindeki ürün/hasat akışları',
    terms: [
      'tohum',
      'çeşit',
      'ürün tarla eşleştirme',
      'uygun ürün',
      'hasat tahmini',
      'hasat penceresi',
      'verim',
      'rekolte',
    ],
    actions: [
      'Tohum/çeşit seçimi için ürün bilgilerini ve toleransları karşılaştırın.',
      'Ürün-tarla eşleştirmede tarla koşulları ile bitki gereksinimlerini birlikte değerlendirin.',
      'Hasat tahmini sonucunu hava, gelişim evresi ve tarla gözlemiyle kontrol edin.',
    ],
    reasons: [
      'Bu araçlar karar desteği sağlar; kesin verim veya satış garantisi üretmez.',
      'Tarla verisi eksikse sonuçlar genel kabul ve kayıtlı parametrelerle sınırlı kalır.',
    ],
  ),
];

class _AdvisorKnowledgeItem {
  final String title;
  final String action;
  final String reason;
  final List<String> sourceRefs;
  final int score;
  final bool requiresBkuCheck;

  const _AdvisorKnowledgeItem({
    required this.title,
    required this.action,
    required this.reason,
    required this.sourceRefs,
    required this.score,
    this.requiresBkuCheck = false,
  });
}
