/// Hastalık rehber log servisi.
///
/// Tarladaki hasta bitki kayıtlarını okur, her hastalık için Türkiye'nin
/// güvenilir kaynaklarından (TAGEM, Tarım Bakanlığı, bku.tarim.gov.tr) gelen
/// kimyasal mücadele önerilerini toplar ve son ilaçlama aktiviteleriyle
/// karşılaştırarak doğru ilaç uygulanmışsa "sorun çözüldü" durumu üretir.
library;

import '../data/activity_types.dart';
import '../data/app_database.dart';
import '../data/disease_advice.dart';

/// Bir hastalık girdisinin üç olası durumundan biri.
///
///   • [active]       — Bitki 'diseased' işaretli, tedavi başlatılmamış. Kırmızı.
///   • [inTreatment]  — Bitki 'treating' işaretli, tedavi planı sürüyor. Turuncu.
///   • [resolved]     — Son 14 gün içinde eşleşen aktif madde uygulanmış. Yeşil.
enum DiseaseEntryStatus { active, inTreatment, resolved }

class DiseaseLogEntry {
  const DiseaseLogEntry({
    required this.plantId,
    required this.cropId,
    required this.diseaseName,
    required this.cropName,
    required this.advice,
    required this.observedAt,
    required this.affectedCount,
    required this.status,
    required this.resolvedBy,
    required this.resolvedActiveIngredient,
    required this.resolvedAt,
    required this.recommendedTreatmentLine,
    required this.resolvedTreatmentLine,
    required this.resolvedDosePerDa,
    required this.resolvedDoseUnit,
    required this.resolvedMixtureLiters,
    required this.resolvedPreharvestDays,
    required this.treatmentStartedAt,
    required this.applicationsCompleted,
    required this.totalApplications,
    required this.intervalDays,
    required this.nextApplicationAt,
    required this.lastAppliedActiveIngredient,
  });

  final String plantId;
  final String? cropId;
  final String diseaseName;
  final String cropName;
  final DiseaseAdvice advice;
  final DateTime? observedAt;
  final int affectedCount;

  final DiseaseEntryStatus status;
  bool get resolved => status == DiseaseEntryStatus.resolved;
  bool get inTreatment => status == DiseaseEntryStatus.inTreatment;
  bool get active => status == DiseaseEntryStatus.active;

  /// Çözümü sağlayan ilacın ticari adı (varsa).
  final String? resolvedBy;

  /// Aktif madde — kullanıcıya hangi etken maddeyi uyguladığını gösterir.
  final String? resolvedActiveIngredient;
  final DateTime? resolvedAt;

  /// Aktif durumda ilk gösterilecek tedavi öneri satırı
  /// (DiseaseAdvice.chemicalTreatments içinden NOT olmayan ilk madde).
  final String? recommendedTreatmentLine;

  /// Çözüldü durumunda kullanıcı uygulamasıyla eşleşen tedavi satırı
  /// (uygulama aralığı/açıklamasını okumak için).
  final String? resolvedTreatmentLine;

  /// İlaçlama metadatasından alınan doz bilgileri (varsa).
  final double? resolvedDosePerDa;
  final String? resolvedDoseUnit;
  final double? resolvedMixtureLiters;
  final int? resolvedPreharvestDays;

  /// Tedavi başlangıç tarihi — ilk ilaçlama aktivitesinin tarihi.
  final DateTime? treatmentStartedAt;

  /// Şimdiye kadar yapılmış uygulama sayısı.
  final int applicationsCompleted;

  /// TAGEM standardına göre planlanan toplam uygulama sayısı.
  final int totalApplications;

  /// İki uygulama arası gün.
  final int intervalDays;

  /// Bir sonraki uygulama beklenen tarih (null ise plan tamamlanmış).
  final DateTime? nextApplicationAt;

  /// inTreatment durumunda son uygulanan aktif madde özeti.
  final String? lastAppliedActiveIngredient;

  List<String> get chemicalSuggestions => advice.chemicalTreatments;
  List<String> get organicSuggestions => advice.organicTreatments;
  List<String> get sources => advice.sources;
  String get urgency => advice.urgency;
  String get pathogenType => advice.pathogenType;
}

class DiseaseLogService {
  const DiseaseLogService();

  /// İlaçlamanın tedavi sayılması için maksimum süre (gözlem sonrası).
  static const Duration resolutionWindow = Duration(days: 14);

  /// Hasta veya tedavideki bitki kayıtları + aktivite log → hastalık rehber
  /// girdileri. Üç durum üretebilir: [DiseaseEntryStatus.active] (kırmızı),
  /// [DiseaseEntryStatus.inTreatment] (turuncu), [DiseaseEntryStatus.resolved]
  /// (yeşil).
  static List<DiseaseLogEntry> build({
    required List<FieldPlantInstance> plantInstances,
    required List<Map<String, dynamic>> activities,
  }) {
    final byDisease = <String, List<FieldPlantInstance>>{};
    for (final p in plantInstances) {
      // 'diseased' = aktif kırmızı, 'treating' = sürmekte olan tedavi (turuncu).
      // 'healthy', 'dead', 'removed' bu raporun konusu değil.
      if (p.healthStatus != 'diseased' && p.healthStatus != 'treating') {
        continue;
      }
      final d = p.diseaseType?.trim();
      if (d == null || d.isEmpty) continue;
      byDisease.putIfAbsent(d, () => <FieldPlantInstance>[]).add(p);
    }
    if (byDisease.isEmpty) return const <DiseaseLogEntry>[];

    final entries = <DiseaseLogEntry>[];
    for (final entry in byDisease.entries) {
      final plants = entry.value..sort(_byObservedDesc);
      final latest = plants.first;
      final observedAt =
          latest.lastObservedAt ?? latest.healthChangedAt ?? latest.updatedAt;
      final advice = DiseaseAdvice.forName(entry.key);

      final resolution = _findResolution(
        diseaseName: entry.key,
        cropId: latest.cropId,
        treatments: advice.chemicalTreatments,
        activities: activities,
        observedAt: observedAt,
      );

      // Aktif iken çiftçiye gösterilecek ilk öneri (NOT satırlarını atla).
      final recommendedLine = advice.chemicalTreatments.firstWhere(
        (t) => !t.trim().toLowerCase().startsWith('not'),
        orElse: () => '',
      );

      // Çözüldü durumda hangi tedavi satırına eşleştiğini bul — uygulama
      // aralığı/açıklamasını oradan okuyacağız.
      String? resolvedLine;
      if (resolution != null) {
        final activeLc =
            (resolution.activeIngredient ?? resolution.product).toLowerCase();
        for (final t in advice.chemicalTreatments) {
          if (t.trim().toLowerCase().startsWith('not')) continue;
          final tokens = _extractActiveIngredients(t);
          if (tokens.any((tok) => tok.length > 2 && activeLc.contains(tok))) {
            resolvedLine = t;
            break;
          }
        }
        resolvedLine ??= recommendedLine.isEmpty ? null : recommendedLine;
      }

      // Tedavi planı bilgilerini ilaçlama aktivitelerinden topla — bitki
      // 'treating' durumda veya en az bir spraying log varsa.
      final anyTreating = plants.any((p) => p.healthStatus == 'treating');
      final plan = _buildTreatmentProgress(
        diseaseName: entry.key,
        cropId: latest.cropId,
        treatments: advice.chemicalTreatments,
        activities: activities,
        observedAt: observedAt,
      );

      // Durum makinesi:
      //   resolved varsa → resolved (yeşil)
      //   yoksa ve bitki 'treating' veya en az 1 uygulama yapılmışsa → inTreatment
      //   diğer → active
      final DiseaseEntryStatus status;
      if (resolution != null) {
        status = DiseaseEntryStatus.resolved;
      } else if (anyTreating || plan.applicationsCompleted > 0) {
        status = DiseaseEntryStatus.inTreatment;
      } else {
        status = DiseaseEntryStatus.active;
      }

      entries.add(DiseaseLogEntry(
        plantId: latest.id,
        cropId: latest.cropId,
        diseaseName: entry.key,
        cropName: latest.cropName,
        advice: advice,
        observedAt: observedAt,
        affectedCount: plants.length,
        status: status,
        resolvedBy: resolution?.product,
        resolvedActiveIngredient: resolution?.activeIngredient,
        resolvedAt: resolution?.date,
        recommendedTreatmentLine:
            recommendedLine.isEmpty ? null : recommendedLine,
        resolvedTreatmentLine: resolvedLine,
        resolvedDosePerDa: resolution?.dosePerDa,
        resolvedDoseUnit: resolution?.doseUnit,
        resolvedMixtureLiters: resolution?.mixtureLiters,
        resolvedPreharvestDays: resolution?.preharvestDays,
        treatmentStartedAt: plan.startedAt,
        applicationsCompleted: plan.applicationsCompleted,
        totalApplications: plan.totalApplications,
        intervalDays: plan.intervalDays,
        nextApplicationAt: plan.nextApplicationAt,
        lastAppliedActiveIngredient: plan.lastActiveIngredient,
      ));
    }
    // Sıralama: aktif (kırmızı) en üstte, tedavide (turuncu) ortada,
    // çözümlenmiş (yeşil) en altta. Aynı durumda son gözlem yeni olan üstte.
    int rank(DiseaseEntryStatus s) => switch (s) {
          DiseaseEntryStatus.active => 0,
          DiseaseEntryStatus.inTreatment => 1,
          DiseaseEntryStatus.resolved => 2,
        };
    entries.sort((a, b) {
      final cmp = rank(a.status).compareTo(rank(b.status));
      if (cmp != 0) return cmp;
      final ad = a.observedAt ?? DateTime(2000);
      final bd = b.observedAt ?? DateTime(2000);
      return bd.compareTo(ad);
    });
    return entries;
  }

  /// TAGEM Zirai Mücadele Teknik Talimatlarına göre hastalığa özel uygulama
  /// aralığı (gün). disease_advice.dart içindeki chemicalTreatments
  /// metinleriyle tutarlıdır. (field_tracking_screen ile aynı sözlük.)
  static int defaultIntervalDays(String name) {
    final n = name.toLowerCase();
    if (n.contains('mildiyö') ||
        n.contains('fitoftora') ||
        n.contains('geç yanıklık')) {
      return 7;
    }
    if (n.contains('külleme') || n.contains('kulleme')) return 7;
    if (n.contains('pas')) return 7;
    if (n.contains('yaprak lekesi') || n.contains('cercospora')) return 10;
    if (n.contains('antraknoz')) return 7;
    if (n.contains('bakteriyel')) return 10;
    if (n.contains('kök çürüklüğü') || n.contains('kok curuklugu')) return 14;
    if (n.contains('kurşuni küf') || n.contains('botrytis')) return 7;
    if (n.contains('alternaria') || n.contains('erken yanıklık')) return 10;
    if (n.contains('fusarium')) return 14;
    if (n.contains('monilya') || n.contains('monilia')) return 10;
    if (n.contains('ateş yanıklığı') ||
        n.contains('ates yanikligi') ||
        n.contains('erwinia')) {
      return 7;
    }
    return 10;
  }

  /// Bir tedavi protokolünde planlanan toplam uygulama sayısı.
  static int defaultTotalApplications(String name) {
    final n = name.toLowerCase();
    if (n.contains('mozaik') || n.contains('virüs')) return 0; // kimyasalsız
    if (n.contains('mildiyö') ||
        n.contains('fitoftora') ||
        n.contains('geç yanıklık')) {
      return 3;
    }
    if (n.contains('külleme') || n.contains('kulleme')) return 3;
    if (n.contains('pas') || n.contains('antraknoz')) return 2;
    if (n.contains('kurşuni küf') || n.contains('botrytis')) return 3;
    if (n.contains('alternaria') || n.contains('erken yanıklık')) return 3;
    if (n.contains('fusarium')) return 1; // toprak kökenli, kimyasal sınırlı
    if (n.contains('monilya') || n.contains('monilia')) return 2;
    if (n.contains('ateş yanıklığı') ||
        n.contains('ates yanikligi') ||
        n.contains('erwinia')) {
      return 2;
    }
    if (n.contains('cercospora')) return 2;
    return 2;
  }

  /// İlaçlama aktivitelerinden tedavi ilerleme özetini çıkarır.
  static _TreatmentProgress _buildTreatmentProgress({
    required String diseaseName,
    required String? cropId,
    required List<String> treatments,
    required List<Map<String, dynamic>> activities,
    required DateTime? observedAt,
  }) {
    final activeTokens = <String>{};
    for (final t in treatments) {
      activeTokens.addAll(_extractActiveIngredients(t));
    }
    final lcDisease = diseaseName.toLowerCase();
    final intervalDays = defaultIntervalDays(diseaseName);
    final totalApplications = defaultTotalApplications(diseaseName);

    DateTime? startedAt;
    DateTime? lastAppliedAt;
    String? lastActive;
    var applied = 0;

    for (final act in activities) {
      if (act['type'] != ActivityType.spraying) continue;
      final date = act['date'];
      if (date is! DateTime) continue;
      if (observedAt != null && date.isBefore(observedAt)) continue;

      final meta = act['metadata'];
      final metaMap = meta is Map ? meta : const <dynamic, dynamic>{};
      final activeRaw = metaMap['active_ingredient']?.toString() ?? '';
      final pesticideRaw = metaMap['pesticide_name']?.toString() ?? '';
      final targetRaw = metaMap['target_pest']?.toString() ?? '';
      final note = act['note_text']?.toString() ?? '';
      final actCropId = act['crop_id']?.toString();

      final active = activeRaw.toLowerCase();
      final pesticide = pesticideRaw.toLowerCase();
      final target = targetRaw.toLowerCase();
      final lcNote = note.toLowerCase();

      // Aynı bitki/zone'a yapılmış olabilir veya tarla geneli.
      final cropMatches =
          actCropId == null || cropId == null || actCropId == cropId;
      if (!cropMatches) continue;

      final matchesActive = active.isNotEmpty &&
          activeTokens.any((t) => t.length > 2 && active.contains(t));
      final matchesPesticide = pesticide.isNotEmpty &&
          activeTokens.any((t) => t.length > 2 && pesticide.contains(t));
      final matchesTarget = target.isNotEmpty && target.contains(lcDisease);
      final matchesNote = lcNote.isNotEmpty && lcNote.contains(lcDisease);
      final matchesMetaDisease =
          metaMap['disease_name']?.toString().toLowerCase() == lcDisease;

      if (matchesActive ||
          matchesPesticide ||
          matchesTarget ||
          matchesNote ||
          matchesMetaDisease) {
        applied++;
        if (startedAt == null || date.isBefore(startedAt)) startedAt = date;
        if (lastAppliedAt == null || date.isAfter(lastAppliedAt)) {
          lastAppliedAt = date;
          lastActive = activeRaw.isNotEmpty
              ? activeRaw
              : (pesticideRaw.isNotEmpty ? pesticideRaw : null);
        }
      }
    }

    DateTime? nextAt;
    if (lastAppliedAt != null &&
        applied < totalApplications &&
        totalApplications > 0) {
      nextAt = lastAppliedAt.add(Duration(days: intervalDays));
    }

    return _TreatmentProgress(
      startedAt: startedAt,
      applicationsCompleted: applied,
      totalApplications: totalApplications,
      intervalDays: intervalDays,
      nextApplicationAt: nextAt,
      lastActiveIngredient: lastActive,
    );
  }

  static int _byObservedDesc(FieldPlantInstance a, FieldPlantInstance b) {
    final ad = a.lastObservedAt ?? a.healthChangedAt ?? a.updatedAt;
    final bd = b.lastObservedAt ?? b.healthChangedAt ?? b.updatedAt;
    return bd.compareTo(ad);
  }

  static _Resolution? _findResolution({
    required String diseaseName,
    required String? cropId,
    required List<String> treatments,
    required List<Map<String, dynamic>> activities,
    required DateTime? observedAt,
  }) {
    final cutoff = DateTime.now().subtract(resolutionWindow);
    final activeTokens = <String>{};
    for (final t in treatments) {
      activeTokens.addAll(_extractActiveIngredients(t));
    }
    final lcDisease = diseaseName.toLowerCase();
    final normDisease = _normalizeTr(lcDisease);

    for (final act in activities) {
      if (act['type'] != ActivityType.spraying) continue;
      final date = act['date'];
      if (date is! DateTime) continue;
      if (date.isBefore(cutoff)) continue;
      // Gözlemden önceki ilaçlamalar bu hastalığı çözmüş sayılmaz.
      if (observedAt != null && date.isBefore(observedAt)) continue;
      // Bitki bağı varsa aynı bitkiye yapılan uygulama önceliklidir, ama
      // tarla genelindeki ilaçlama da kabul edilir.
      // (cropId filtresi yok — tarla geneli ilaçlama yaygın senaryo.)

      final meta = act['metadata'];
      final metaMap = meta is Map ? meta : const <dynamic, dynamic>{};
      final activeRaw = metaMap['active_ingredient']?.toString() ?? '';
      final pesticideRaw = metaMap['pesticide_name']?.toString() ?? '';
      final targetRaw = metaMap['target_pest']?.toString() ?? '';
      final diseaseNameMetaRaw = metaMap['disease_name']?.toString() ?? '';
      final note = (act['note_text']?.toString() ?? '');

      final active = activeRaw.toLowerCase();
      final pesticide = pesticideRaw.toLowerCase();
      final target = targetRaw.toLowerCase();
      final diseaseMeta = diseaseNameMetaRaw.toLowerCase();
      final lcNote = note.toLowerCase();

      final matchesActive = active.isNotEmpty &&
          activeTokens.any((t) => t.length > 2 && active.contains(t));
      final matchesPesticide = pesticide.isNotEmpty &&
          activeTokens.any((t) => t.length > 2 && pesticide.contains(t));
      // İki yönlü + Türkçe normalize + alias eşleşmesi: playbook target metni
      // "Mildiyö (Phytophthora infestans)" iken hastalık adı "fitoftora" da
      // olsa eşleşsin.
      final matchesTarget =
          _diseaseLabelMatches(target, lcDisease, normDisease);
      final matchesDiseaseMeta =
          _diseaseLabelMatches(diseaseMeta, lcDisease, normDisease);
      final matchesNote = _diseaseLabelMatches(lcNote, lcDisease, normDisease);

      if (matchesActive ||
          matchesPesticide ||
          matchesTarget ||
          matchesDiseaseMeta ||
          matchesNote) {
        final product = pesticideRaw.isNotEmpty
            ? pesticideRaw
            : (activeRaw.isNotEmpty ? activeRaw : 'İlaçlama');
        return _Resolution(
          product: product,
          activeIngredient: activeRaw.isEmpty ? null : activeRaw,
          date: date,
          dosePerDa: (metaMap['pesticide_dose_per_da'] as num?)?.toDouble(),
          doseUnit: metaMap['pesticide_dose_unit']?.toString(),
          mixtureLiters: (metaMap['mixture_liters'] as num?)?.toDouble(),
          preharvestDays:
              (metaMap['preharvest_interval_days'] as num?)?.toInt(),
        );
      }
    }
    return null;
  }

  /// Hastalık etiketi ile aktivite metadatasındaki bir metni karşılaştırır.
  ///
  /// İki yönlü alt-string + Türkçe karakter normalize + alias sözlüğü
  /// (botrytis ↔ kurşuni küf, fitoftora ↔ mildiyö, vb.) ile çalışır. Playbook
  /// ürün adlarındaki parantezli ekleri ve V2 trust DB'deki kısa isimleri
  /// kapsar.
  static bool _diseaseLabelMatches(
    String text,
    String lcDisease,
    String normDisease,
  ) {
    if (text.isEmpty) return false;
    final lc = text;
    final norm = _normalizeTr(text);
    if (lc.contains(lcDisease) || lcDisease.contains(lc)) return true;
    if (norm.contains(normDisease) || normDisease.contains(norm)) return true;
    // Alias eşleşmesi — sözlükte hastalık varyantlarını dolaş.
    for (final entry in _resolutionAliases.entries) {
      if (lcDisease.contains(entry.key)) {
        if (lc.contains(entry.value) ||
            norm.contains(_normalizeTr(entry.value))) {
          return true;
        }
      }
      if (lc.contains(entry.key)) {
        if (lcDisease.contains(entry.value) ||
            normDisease.contains(_normalizeTr(entry.value))) {
          return true;
        }
      }
    }
    return false;
  }

  static const Map<String, String> _resolutionAliases = {
    'botrytis': 'kurşuni küf',
    'kurşuni küf': 'botrytis',
    'fitoftora': 'mildiyö',
    'phytophthora': 'mildiyö',
    'geç yanıklık': 'mildiyö',
    'alternaria': 'erken yaprak yanıklığı',
    'erken yanıklık': 'alternaria',
    'fusarium': 'solgunluk',
    'monilia': 'monilya',
    'erwinia': 'ateş yanıklığı',
    'cercospora': 'yaprak lekesi',
  };

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

  /// "Metalaksil-M + Mancozeb — sistemik+koruyucu, 7 gün arayla 2 uygulama"
  /// → ['metalaksil-m', 'mancozeb']
  static Iterable<String> _extractActiveIngredients(String treatment) {
    final beforeDash = treatment.split('—').first.toLowerCase();
    final tokens = beforeDash
        .split(RegExp(r'[+,/]'))
        .map((s) => s.trim())
        .where((s) => s.length > 2);
    const stopwords = <String>{
      'not',
      'veya',
      've',
      'sistemik',
      'koruyucu',
      'tedavi',
      'gün',
      'arayla',
      'uygulama',
      'wp',
      'wg',
      'sc',
      'ec',
      'formülasyonu',
      'etiket',
      'dozunda',
    };
    return tokens.where((t) => !stopwords.contains(t));
  }
}

class _Resolution {
  const _Resolution({
    required this.product,
    required this.activeIngredient,
    required this.date,
    this.dosePerDa,
    this.doseUnit,
    this.mixtureLiters,
    this.preharvestDays,
  });

  final String product;
  final String? activeIngredient;
  final DateTime date;
  final double? dosePerDa;
  final String? doseUnit;
  final double? mixtureLiters;
  final int? preharvestDays;
}

class _TreatmentProgress {
  const _TreatmentProgress({
    required this.startedAt,
    required this.applicationsCompleted,
    required this.totalApplications,
    required this.intervalDays,
    required this.nextApplicationAt,
    required this.lastActiveIngredient,
  });

  final DateTime? startedAt;
  final int applicationsCompleted;
  final int totalApplications;
  final int intervalDays;
  final DateTime? nextApplicationAt;
  final String? lastActiveIngredient;
}
