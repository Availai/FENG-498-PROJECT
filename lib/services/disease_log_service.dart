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

class DiseaseLogEntry {
  const DiseaseLogEntry({
    required this.plantId,
    required this.cropId,
    required this.diseaseName,
    required this.cropName,
    required this.advice,
    required this.observedAt,
    required this.affectedCount,
    required this.resolved,
    required this.resolvedBy,
    required this.resolvedActiveIngredient,
    required this.resolvedAt,
    required this.recommendedTreatmentLine,
    required this.resolvedTreatmentLine,
    required this.resolvedDosePerDa,
    required this.resolvedDoseUnit,
    required this.resolvedMixtureLiters,
    required this.resolvedPreharvestDays,
  });

  final String plantId;
  final String? cropId;
  final String diseaseName;
  final String cropName;
  final DiseaseAdvice advice;
  final DateTime? observedAt;
  final int affectedCount;

  /// Doğru ilaç son 14 gün içinde uygulandıysa true.
  final bool resolved;

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

  /// Hasta bitki kayıtları + aktivite log → hastalık rehber girdileri.
  static List<DiseaseLogEntry> build({
    required List<FieldPlantInstance> plantInstances,
    required List<Map<String, dynamic>> activities,
  }) {
    final byDisease = <String, List<FieldPlantInstance>>{};
    for (final p in plantInstances) {
      if (p.healthStatus != 'diseased') continue;
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

      entries.add(DiseaseLogEntry(
        plantId: latest.id,
        cropId: latest.cropId,
        diseaseName: entry.key,
        cropName: latest.cropName,
        advice: advice,
        observedAt: observedAt,
        affectedCount: plants.length,
        resolved: resolution != null,
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
      ));
    }
    // Aktif olanlar üstte; çözümlenmiş olanlar altta.
    entries.sort((a, b) {
      if (a.resolved != b.resolved) return a.resolved ? 1 : -1;
      final ad = a.observedAt ?? DateTime(2000);
      final bd = b.observedAt ?? DateTime(2000);
      return bd.compareTo(ad);
    });
    return entries;
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
      final note = (act['note_text']?.toString() ?? '');

      final active = activeRaw.toLowerCase();
      final pesticide = pesticideRaw.toLowerCase();
      final target = targetRaw.toLowerCase();
      final lcNote = note.toLowerCase();

      final matchesActive = active.isNotEmpty &&
          activeTokens.any((t) => t.length > 2 && active.contains(t));
      final matchesPesticide = pesticide.isNotEmpty &&
          activeTokens.any((t) => t.length > 2 && pesticide.contains(t));
      final matchesTarget = target.isNotEmpty && target.contains(lcDisease);
      final matchesNote = lcNote.isNotEmpty && lcNote.contains(lcDisease);

      if (matchesActive ||
          matchesPesticide ||
          matchesTarget ||
          matchesNote) {
        final product = pesticideRaw.isNotEmpty
            ? pesticideRaw
            : (activeRaw.isNotEmpty ? activeRaw : 'İlaçlama');
        return _Resolution(
          product: product,
          activeIngredient: activeRaw.isEmpty ? null : activeRaw,
          date: date,
          dosePerDa:
              (metaMap['pesticide_dose_per_da'] as num?)?.toDouble(),
          doseUnit: metaMap['pesticide_dose_unit']?.toString(),
          mixtureLiters:
              (metaMap['mixture_liters'] as num?)?.toDouble(),
          preharvestDays:
              (metaMap['preharvest_interval_days'] as num?)?.toInt(),
        );
      }
    }
    return null;
  }

  /// "Metalaksil-M + Mancozeb — sistemik+koruyucu, 7 gün arayla 2 uygulama"
  /// → ['metalaksil-m', 'mancozeb']
  static Iterable<String> _extractActiveIngredients(String treatment) {
    final beforeDash = treatment.split('—').first.toLowerCase();
    final tokens = beforeDash
        .split(RegExp(r'[+,/]'))
        .map((s) => s.trim())
        .where((s) => s.length > 2);
    const stopwords = <String>{
      'not', 'veya', 've', 'sistemik', 'koruyucu', 'tedavi', 'gün',
      'arayla', 'uygulama', 'wp', 'wg', 'sc', 'ec', 'formülasyonu',
      'etiket', 'dozunda',
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
