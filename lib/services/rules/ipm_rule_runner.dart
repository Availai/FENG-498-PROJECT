import '../../data/activity_types.dart';
import '../../data/crop_ipm_rules.dart';
import '../guide_engine.dart' show AlertSeverity;
import 'crop_rule_set.dart';
import 'recommendation.dart';

/// IPM (Entegre Zararlı Yönetimi) kurallarını canlı tavsiyelere dönüştüren
/// saf köprü.
///
/// Mantık (her [scoutingWindows] penceresi × her ürün için):
///   1. Ürün ekildi mi? `daysSincePlanted` bilinmiyorsa atla.
///   2. Pencere zamanı geldi mi? `dayOffset ± 7` gün içindeyiz mi?
///   3. Son 7 gün içinde **scouting kaydı** var mı?
///       • YOK  → "Tarlada gözlem yapın" tavsiyesi
///                (gate: actionable, command: scouting + subtype eşleşen).
///       • VAR + metadata.threshold_exceeded == true →
///                "Eşik aşıldı. Etiket dozunda piretroid grubu insektisit"
///                (gate: actionable, command: null — kullanıcı manuel kaydeder).
///       • VAR ama eşik flag yok → "Eşik altı / 2 gün sonra tekrar bak"
///                (gate: observeFirst, izleme).
///   4. Son 7 gün içinde **spraying** varsa kuralı bastır.
///
/// İlaç dozu YOK: yasal sebeple sadece kategori ipucu (`productCategoryHint`)
/// ve "BKÜ etiketine göre uygulayın" yönlendirmesi verilir.
///
/// `scoutingWindows` parametresi opsiyonel; verilmezse zaman penceresi
/// kontrolü atlanır ve ürünün tüm IPM kuralları her zaman değerlendirilir
/// (test ergonomisi).
class IpmRuleRunner {
  IpmRuleRunner._();

  /// Aktivite kaydının metadata'sından "eşik aşıldı" işaretini çıkar.
  /// Üst kullanıcı arayüzü scouting form'una bir checkbox eklediğinde,
  /// `metadata['threshold_exceeded'] = true` olarak loglanır.
  static bool _thresholdExceededIn(
    ActivityRecord rec,
    Map<String, dynamic>? Function(ActivityRecord) metadataExtractor,
  ) {
    final m = metadataExtractor(rec);
    if (m == null) return false;
    return m['threshold_exceeded'] == true;
  }

  /// Tek geçişte: pencere kontrolü + scouting/spraying durumu + threshold
  /// kontrolünden sonra `Recommendation` listesi döner. Kural yoksa boş.
  ///
  /// [windows] null ise dönem kontrolü yapılmaz; tüm kurallar değerlendirilir.
  /// [extractMetadata] aktivite metadata'sını okumak için opsiyonel callback;
  /// `RuleEvaluationContext.recentActivities` içindeki [ActivityRecord]
  /// metadata taşımıyor → ileride context zenginleştiğinde flag'i okumayı
  /// sağlar. Şimdilik null geçilirse threshold daima false sayılır.
  static List<Recommendation> run({
    required RuleEvaluationContext ctx,
    required List<CropIpmRule> rules,
    List<IpmScoutingWindow>? windows,
    Map<String, dynamic>? Function(ActivityRecord)? extractMetadata,
  }) {
    if (rules.isEmpty) return const [];
    final out = <Recommendation>[];

    final sprayedRecently = ctx.hasActivityWithin(
      type: ActivityType.spraying,
      window: const Duration(days: 7),
    );
    if (sprayedRecently) return const [];

    final days = ctx.crop.daysSincePlanted(ctx.now);
    if (days == null) return const [];

    // Aktif pencere → bu pencerede izlenecek pestKey kümesi.
    final activePestKeys = <String>{};
    if (windows == null || windows.isEmpty) {
      for (final r in rules) {
        activePestKeys.add(r.pestKey);
      }
    } else {
      for (final w in windows) {
        if ((days - w.dayOffset).abs() <= 7) {
          activePestKeys.addAll(w.pestKeys);
        }
      }
    }
    if (activePestKeys.isEmpty) return const [];

    for (final rule in rules) {
      if (!activePestKeys.contains(rule.pestKey)) continue;
      final rec = _evaluateRule(
        ctx: ctx,
        rule: rule,
        extractMetadata: extractMetadata,
      );
      if (rec != null) out.add(rec);
    }
    return out;
  }

  static Recommendation? _evaluateRule({
    required RuleEvaluationContext ctx,
    required CropIpmRule rule,
    Map<String, dynamic>? Function(ActivityRecord)? extractMetadata,
  }) {
    final isPest = rule.type.toLowerCase().contains('zararl');
    final scoutingSubtype = isPest
        ? ActivitySubtype.pestObservation
        : ActivitySubtype.diseaseObservation;

    final scoutingWithin = const Duration(days: 7);
    final lastScouting = _lastObservationOf(
      ctx,
      subtype: scoutingSubtype,
    );
    final scoutedRecently = lastScouting != null &&
        ctx.now.difference(lastScouting.at) < scoutingWithin;

    // Hangi kural anahtarını kullanacağız — ileride ledger/cascade için.
    final ruleKey = 'ipm.${rule.cropKey}.${rule.pestKey}.v1';
    final target = RecommendationTarget.crop(
      fieldId: ctx.fieldId,
      cropId: ctx.crop.id,
    );

    final evidence = _evidenceFor(ctx, rule);

    if (!scoutedRecently) {
      // Senaryo A — gözlem yok: scouting tavsiyesi.
      return Recommendation(
        ruleKey: '$ruleKey.scout',
        severity: AlertSeverity.warning,
        target: target,
        title: '${rule.pestName} için tarla gözlemi',
        reasonText:
            '${rule.pestName} için izleme penceresi açık. Eşik doğrulanmadan kimyasal kaydı açılmaz.',
        reasonBullets: [
          'Belirti: ${rule.symptoms}',
          'Yöntem: ${rule.monitoringMethod}',
          'Eşik: ${rule.economicThreshold}',
          'Son 7 gün içinde gözlem kaydı yok',
        ],
        actionHint:
            'Köşegen/zikzak yürüyüşle örnekleyin; eşik aşıldıysa gözlem formunda işaretleyin.',
        gate: RecommendationGate.actionable,
        evidence: evidence,
        command: RecommendationCommand(
          activityType: ActivityType.scouting,
          subtype: scoutingSubtype,
          buttonLabel: 'Gözlem yaptım',
          metadata: {
            RecommendationMetadataKeys.ipmGate: 'observe_before_spray',
            'pest_key': rule.pestKey,
          },
        ),
        sourceRefs: rule.sourceRefs,
        clearOnActivities: [
          ClearOnActivity(
            activityType: ActivityType.scouting,
            subtype: scoutingSubtype,
            withinHours: 24 * 7,
          ),
        ],
        cooldownHours: 48,
        timing: const RecommendationTiming(
          descriptor: 'Sabah saatlerinde, çiy kalkmadan',
          source: 'agronomic',
        ),
      );
    }

    // Gözlem var → eşik aşıldı flag'ini ara.
    final thresholdExceeded = extractMetadata != null &&
        _thresholdExceededIn(lastScouting, extractMetadata);

    if (!thresholdExceeded) {
      // Senaryo B — gözlem var ama eşik altı: takip.
      return Recommendation(
        ruleKey: '$ruleKey.followup',
        severity: AlertSeverity.info,
        target: target,
        title: '${rule.pestName}: eşik altı, takip et',
        reasonText:
            'Son gözlemde eşik aşılmadı. ${rule.pestName} için izlemeye devam edin.',
        reasonBullets: [
          'Eşik: ${rule.economicThreshold}',
          'Kültürel önlem: ${rule.culturalControl}',
          'Bir sonraki kontrol için 2-3 gün',
        ],
        actionHint:
            '2-3 gün sonra aynı parsellerden örnekleyin; popülasyon artarsa kararı yenileyin.',
        gate: RecommendationGate.observeFirst,
        evidence: evidence,
        command: RecommendationCommand(
          activityType: ActivityType.scouting,
          subtype: scoutingSubtype,
          buttonLabel: 'Tekrar gözlem yaptım',
          metadata: {
            RecommendationMetadataKeys.ipmGate: 'follow_up',
            'pest_key': rule.pestKey,
          },
        ),
        sourceRefs: rule.sourceRefs,
        cooldownHours: 48,
      );
    }

    // Senaryo C — eşik aşıldı, kimyasal kapısı açıldı (doz YOK).
    return Recommendation(
      ruleKey: '$ruleKey.chemical',
      severity: AlertSeverity.critical,
      target: target,
      title: '${rule.pestName}: eşik aşıldı',
      reasonText:
          '${rule.pestName} eşik üzerinde. ${isPest ? "Piretroid grubu insektisit" : "Ruhsatlı fungisit"} BKÜ etiketine göre uygulayın.',
      reasonBullets: [
        'Eşik: ${rule.economicThreshold}',
        'Kapı: ${rule.chemicalGate}',
        'Marka/doz uygulamada: BKÜ etiketi + il/ilçe teknik önerisi',
        'Rüzgâr <4 m/s, sıcaklık <28°C penceresinde uygulayın',
      ],
      actionHint:
          'Resmi etiket dozunu uygulayın; uygulama sonrası tarihi gübreleme/sulama notu olarak kaydedin.',
      gate: RecommendationGate.actionable,
      evidence: evidence,
      command: RecommendationCommand(
        activityType: ActivityType.spraying,
        buttonLabel: 'İlaçladım',
        metadata: {
          RecommendationMetadataKeys.productCategoryHint:
              isPest ? 'piretroid grubu insektisit' : 'ruhsatlı fungisit',
          RecommendationMetadataKeys.preHarvestIntervalHint:
              'BKÜ etiketinde belirtilen hasat öncesi bekleme süresine uyun',
          RecommendationMetadataKeys.safetyWindowHours: 24,
          'pest_key': rule.pestKey,
          'threshold_referenced': rule.economicThreshold,
        },
      ),
      sourceRefs: rule.sourceRefs,
      dependsOn: ['$ruleKey.scout'],
      clearOnActivities: const [
        ClearOnActivity(
          activityType: ActivityType.spraying,
          withinHours: 24 * 7,
        ),
      ],
      cooldownHours: 24,
      timing: const RecommendationTiming(
        descriptor: 'Rüzgâr <4 m/s, sıcaklık <28°C, sakin saatlerde',
        source: 'agronomic',
      ),
    );
  }

  static List<RecommendationEvidence> _evidenceFor(
    RuleEvaluationContext ctx,
    CropIpmRule rule,
  ) {
    final out = <RecommendationEvidence>[
      RecommendationEvidence(label: 'Tür', value: rule.type),
      RecommendationEvidence(label: 'Eşik', value: rule.economicThreshold),
      RecommendationEvidence(
        label: 'İzleme penceresi',
        value: rule.observationWindow,
      ),
    ];
    final days = ctx.crop.daysSincePlanted(ctx.now);
    if (days != null) {
      out.add(RecommendationEvidence(label: 'Ekimden gün', value: '$days'));
    }
    final stage = ctx.growth?.stageKey;
    if (stage != null) {
      out.add(RecommendationEvidence(label: 'Evre', value: stage));
    }
    return out;
  }

  static ActivityRecord? _lastObservationOf(
    RuleEvaluationContext ctx, {
    required String subtype,
  }) {
    for (final a in ctx.recentActivities) {
      if (a.type == ActivityType.scouting && a.subtype == subtype) return a;
    }
    return null;
  }
}
