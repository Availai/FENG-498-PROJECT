enum AdvisorIntent {
  general,
  disease,
  pest,
  weed,
  irrigation,
  fertilization,
  soilAnalysis,
  harvest,
  sowingOrPlanting,
  weatherWarning,
}

extension AdvisorIntentLabel on AdvisorIntent {
  String get label {
    switch (this) {
      case AdvisorIntent.general:
        return 'Genel danışma';
      case AdvisorIntent.disease:
        return 'Hastalık belirtisi';
      case AdvisorIntent.pest:
        return 'Zararlı riski';
      case AdvisorIntent.weed:
        return 'Yabancı ot';
      case AdvisorIntent.irrigation:
        return 'Sulama';
      case AdvisorIntent.fertilization:
        return 'Gübreleme';
      case AdvisorIntent.soilAnalysis:
        return 'Toprak analizi';
      case AdvisorIntent.harvest:
        return 'Hasat';
      case AdvisorIntent.sowingOrPlanting:
        return 'Ekim / dikim';
      case AdvisorIntent.weatherWarning:
        return 'Hava uyarısı';
    }
  }
}

enum AdvisorConfidence {
  verified,
  limited,
  noVerifiedSource,
}

extension AdvisorConfidenceLabel on AdvisorConfidence {
  String get label {
    switch (this) {
      case AdvisorConfidence.verified:
        return 'Kaynaklı';
      case AdvisorConfidence.limited:
        return 'Sınırlı kaynak';
      case AdvisorConfidence.noVerifiedSource:
        return 'Doğrulanmış kayıt yok';
    }
  }
}

class AdvisorQuery {
  final String text;
  final AdvisorFieldContext? fieldContext;
  final AdvisorAppContext? appContext;

  const AdvisorQuery({
    required this.text,
    this.fieldContext,
    this.appContext,
  });
}

class AdvisorAppContext {
  final List<AdvisorFieldSummary> fields;

  const AdvisorAppContext({
    this.fields = const [],
  });
}

class AdvisorFieldSummary {
  final String fieldId;
  final String fieldName;
  final String? cropName;
  final double? areaDekar;

  const AdvisorFieldSummary({
    required this.fieldId,
    required this.fieldName,
    this.cropName,
    this.areaDekar,
  });
}

class AdvisorFieldContext {
  final String fieldId;
  final String fieldName;
  final List<String> cropNames;
  final List<AdvisorFieldRecommendation> recommendations;

  const AdvisorFieldContext({
    required this.fieldId,
    required this.fieldName,
    this.cropNames = const [],
    this.recommendations = const [],
  });
}

class AdvisorFieldRecommendation {
  final String title;
  final String reasonText;
  final String actionHint;
  final String? activityType;
  final List<String> sourceRefs;

  const AdvisorFieldRecommendation({
    required this.title,
    required this.reasonText,
    required this.actionHint,
    this.activityType,
    this.sourceRefs = const [],
  });
}

class AdvisorAnswer {
  final String originalQuestion;
  final AdvisorIntent intent;
  final AdvisorConfidence confidence;
  final String? cropName;
  final String shortAnswer;
  final List<AdvisorAnswerSection> sections;
  final List<AdvisorSource> sources;
  final List<String> understoodSignals;
  final String safetyNote;

  const AdvisorAnswer({
    required this.originalQuestion,
    required this.intent,
    required this.confidence,
    required this.shortAnswer,
    required this.sections,
    required this.sources,
    required this.safetyNote,
    this.cropName,
    this.understoodSignals = const [],
  });

  bool get hasVerifiedSources => sources.any((source) => source.isTrusted);

  factory AdvisorAnswer.noVerifiedSource({
    required String question,
    required AdvisorIntent intent,
    String? cropName,
    List<String> understoodSignals = const [],
  }) {
    return AdvisorAnswer(
      originalQuestion: question,
      intent: intent,
      confidence: AdvisorConfidence.noVerifiedSource,
      cropName: cropName,
      shortAnswer:
          'Bu konu için doğrulanmış Türkiye kaynaklı kayıt bulunamadı.',
      sections: const [
        AdvisorAnswerSection(
          title: 'Ne yapmalı',
          bullets: [
            'Kesin uygulama kararı vermeden önce il/ilçe tarım müdürlüğü veya yetkili ziraat mühendisine danışın.',
            'Bitki koruma ürünü gerekiyorsa yalnız BKÜ veritabanındaki güncel ruhsat, etiket ve bekleme süresi esas alınmalıdır.',
          ],
        ),
      ],
      sources: const [],
      understoodSignals: understoodSignals,
      safetyNote:
          'Uygulama kaynakta doğrulanmayan konuda tahmin üretmez; ilaç, doz ve kesin teşhis önerisi vermez.',
    );
  }
}

class AdvisorAnswerSection {
  final String title;
  final List<String> bullets;

  const AdvisorAnswerSection({
    required this.title,
    required this.bullets,
  });
}

class AdvisorSource {
  final String id;
  final String title;
  final String? institution;
  final String? sourceType;
  final String? url;
  final String? reliability;
  final String? evidenceText;
  final bool isTrusted;

  const AdvisorSource({
    required this.id,
    required this.title,
    required this.isTrusted,
    this.institution,
    this.sourceType,
    this.url,
    this.reliability,
    this.evidenceText,
  });

  String get displayTitle => institution == null || institution!.isEmpty
      ? title
      : '$institution — $title';
}
