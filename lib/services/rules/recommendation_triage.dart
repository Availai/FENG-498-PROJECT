import 'recommendation.dart';
import '../guide_engine.dart' show AlertSeverity;

/// Çiftçiye gösterilecek tavsiye listesini "bilgi bombardımanı"ndan
/// koruyan triage katmanı.
///
/// `LiveTodoService.generate()` zaten doğru sıralanmış (severity → gate →
/// specificity → origin → kaynak sayısı) ve dedup edilmiş bir liste
/// döndürür. Bu sınıf o listeyi alıp:
///
///  1. Her severity için kullanıcıya gösterilecek **maks N** uygular.
///  2. `critical` her zaman gösterilir (çiftçi sağlığı + verim için kritik).
///  3. `warning` ve `info` için ayrı eşikler.
///  4. Toplam tavsiye sert üst sınıra çekilir (örnek: 12).
///  5. Aşıkkar kalanların sayısını döner (UI 'daha fazla' bildirimi için).
///
/// **Tasarım kararı:** `LiveTodoService.generate()` çıktısı değiştirilmez —
/// her UI kendi triage politikasını seçer (dashboard kart → 3-5 maks,
/// todo paneli → 10-15 maks, tam liste için filtre uygulamaz).
class RecommendationTriage {
  /// Varsayılan kullanıcıya gösterim politikası. CLAUDE.md sec 4.4 + 5.4
  /// (yaşlı kullanıcı için anlaşılır, sahada anlık karar verme) ile uyumlu:
  /// bir ekranda 3 acil + 5 önemli + 3 izle = 11 tavsiye sert üst sınır.
  static const TriagePolicy defaultPolicy = TriagePolicy(
    maxCritical: 3,
    maxWarning: 5,
    maxInfo: 3,
    hardCap: 12,
  );

  /// Dashboard / hızlı bakış için — sadece 5 maks tavsiye.
  static const TriagePolicy compactPolicy = TriagePolicy(
    maxCritical: 2,
    maxWarning: 2,
    maxInfo: 1,
    hardCap: 5,
  );

  /// Detay paneli için (todo paneli) — kullanıcı açıkça "tümünü göster"
  /// istemeden önce kategori başına 10'a kadar.
  static const TriagePolicy expandedPolicy = TriagePolicy(
    maxCritical: 5,
    maxWarning: 10,
    maxInfo: 5,
    hardCap: 20,
  );

  /// Politikaya göre tavsiyeleri kırpar. Sıralama bozulmaz; sadece kuyrukta
  /// kalanlar çıkartılır. [hiddenCount] geriye saklanır → UI "daha fazla"
  /// rozeti gösterir.
  static TriageResult apply(
    List<Recommendation> input, {
    TriagePolicy policy = defaultPolicy,
  }) {
    if (input.isEmpty) {
      return const TriageResult(visible: [], hidden: 0);
    }
    final visible = <Recommendation>[];
    int critical = 0;
    int warning = 0;
    int info = 0;

    for (final r in input) {
      if (visible.length >= policy.hardCap) break;
      switch (r.severity) {
        case AlertSeverity.critical:
          if (critical >= policy.maxCritical) continue;
          visible.add(r);
          critical++;
          break;
        case AlertSeverity.warning:
          if (warning >= policy.maxWarning) continue;
          visible.add(r);
          warning++;
          break;
        case AlertSeverity.info:
          if (info >= policy.maxInfo) continue;
          visible.add(r);
          info++;
          break;
      }
    }

    return TriageResult(
      visible: visible,
      hidden: input.length - visible.length,
    );
  }
}

class TriagePolicy {
  final int maxCritical;
  final int maxWarning;
  final int maxInfo;

  /// Her durumda toplam tavsiye sayısı bunu aşamaz.
  final int hardCap;

  const TriagePolicy({
    required this.maxCritical,
    required this.maxWarning,
    required this.maxInfo,
    required this.hardCap,
  });
}

class TriageResult {
  final List<Recommendation> visible;

  /// Triage tarafından gizlenen tavsiye sayısı. UI "+N daha fazla"
  /// göstermek için kullanır.
  final int hidden;

  const TriageResult({
    required this.visible,
    required this.hidden,
  });

  bool get hasHidden => hidden > 0;
}
