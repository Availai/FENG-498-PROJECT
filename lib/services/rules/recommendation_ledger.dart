import 'package:hive/hive.dart';

import 'recommendation.dart';

/// Bir tavsiyenin yaşam döngüsü. Cooldown ve cascade gate kararları için
/// kullanılır.
///
///   • [pending]      → ledger'da kayıt yok; kural ilk kez tetiklenebilir.
///   • [shown]        → kullanıcıya gösterildi; cooldown saati başladı.
///   • [acknowledged] → kullanıcı kartı açtı / detayı okudu (opsiyonel).
///   • [observed]     → "önce gözlem" yapıldı; bağımlı kurallar açılabilir.
///   • [executed]     → kullanıcı aksiyonu uyguladı (örn. suladı/ilaçladı).
///   • [expired]      → cooldown süresi geçti; yeniden tetiklenebilir.
enum RuleEngagementState {
  pending,
  shown,
  acknowledged,
  observed,
  executed,
  expired,
}

/// Tek satır ledger kaydı. Hive'da `Map<String, dynamic>` olarak saklanır.
class LedgerEntry {
  final RuleEngagementState state;
  final DateTime? shownAt;
  final DateTime? observedAt;
  final DateTime? executedAt;

  const LedgerEntry({
    required this.state,
    this.shownAt,
    this.observedAt,
    this.executedAt,
  });

  Map<String, dynamic> toMap() => {
        'state': state.name,
        if (shownAt != null) 'shown_at': shownAt!.millisecondsSinceEpoch,
        if (observedAt != null)
          'observed_at': observedAt!.millisecondsSinceEpoch,
        if (executedAt != null)
          'executed_at': executedAt!.millisecondsSinceEpoch,
      };

  /// Hive'dan gelen ham veriyi yorumla. Eski sürümde değer **doğrudan int**
  /// (epoch ms) idi → bu durumu `state: shown` + `shownAt` olarak ele al.
  static LedgerEntry? fromRaw(Object? raw) {
    if (raw == null) return null;
    if (raw is int) {
      return LedgerEntry(
        state: RuleEngagementState.shown,
        shownAt: DateTime.fromMillisecondsSinceEpoch(raw),
      );
    }
    if (raw is Map) {
      final stateName = raw['state'] as String?;
      final state = RuleEngagementState.values.firstWhere(
        (s) => s.name == stateName,
        orElse: () => RuleEngagementState.shown,
      );
      DateTime? read(String key) {
        final v = raw[key];
        return v is int ? DateTime.fromMillisecondsSinceEpoch(v) : null;
      }

      return LedgerEntry(
        state: state,
        shownAt: read('shown_at'),
        observedAt: read('observed_at'),
        executedAt: read('executed_at'),
      );
    }
    return null;
  }
}

/// Tavsiye motoru için "şu kural hangi yaşam döngüsü adımında" kayıt defteri.
///
/// Hive box `recommendation_ledger`. Her satır key = `ruleKey::targetKey`,
/// değer = [LedgerEntry.toMap()]. Eski `int` değerleri otomatik
/// [RuleEngagementState.shown] olarak okunur (geriye uyumluluk).
///
/// Cooldown penceresinde duran kayıtlar UI'a düşmez; kullanıcı
/// `clearOnActivities` listesindeki bir aktiviteyi yapınca silinir
/// — böylece tavsiye yeniden tetiklenebilir. Cascade gate motoru
/// [stateOf] üzerinden bağımlı kuralın `observed/executed` durumunu okur.
class RecommendationLedger {
  RecommendationLedger(this._box);

  static const boxName = 'recommendation_ledger';

  final Box _box;

  /// Hedef + ruleKey → stabil ledger anahtarı.
  static String keyFor({
    required String ruleKey,
    required RecommendationTarget target,
  }) {
    final crop = target.cropId ?? '-';
    final plant = target.plantInstanceId ?? '-';
    return '$ruleKey::${target.fieldId}::$crop::$plant';
  }

  LedgerEntry? _read(String key) => LedgerEntry.fromRaw(_box.get(key));

  /// Cooldown'da mı? `cooldownHours == 0` ise her zaman false.
  /// `executed` veya `observed` durumlarında da cooldown başlamış sayılır
  /// (kullanıcı aksiyonu sonrası tekrar göstermek istemiyoruz).
  bool isOnCooldown({
    required String ruleKey,
    required RecommendationTarget target,
    required int cooldownHours,
    DateTime? now,
  }) {
    if (cooldownHours <= 0) return false;
    final key = keyFor(ruleKey: ruleKey, target: target);
    final entry = _read(key);
    if (entry == null) return false;
    final ref = entry.executedAt ?? entry.observedAt ?? entry.shownAt;
    if (ref == null) return false;
    final t = now ?? DateTime.now();
    return t.difference(ref).inMinutes < cooldownHours * 60;
  }

  /// Kuralın o andaki durumu — kayıt yoksa [RuleEngagementState.pending].
  RuleEngagementState stateOf({
    required String ruleKey,
    required RecommendationTarget target,
  }) {
    final key = keyFor(ruleKey: ruleKey, target: target);
    return _read(key)?.state ?? RuleEngagementState.pending;
  }

  /// Tavsiye kullanıcıya gösterildi → ledger'a yaz. Önceki gözlem/uygulama
  /// zamanları korunur (durum geriye gitmesin diye sadece state'i yükselt).
  Future<void> markShown({
    required String ruleKey,
    required RecommendationTarget target,
    DateTime? at,
  }) async {
    final key = keyFor(ruleKey: ruleKey, target: target);
    final prev = _read(key);
    final t = at ?? DateTime.now();
    // observed/executed daha "ileri" durumlar — onları geri çekme.
    final state =
        (prev?.state == RuleEngagementState.observed ||
                prev?.state == RuleEngagementState.executed)
            ? prev!.state
            : RuleEngagementState.shown;
    final entry = LedgerEntry(
      state: state,
      shownAt: t,
      observedAt: prev?.observedAt,
      executedAt: prev?.executedAt,
    );
    await _box.put(key, entry.toMap());
  }

  /// "Önce gözlem" tipi tavsiye için kullanıcı gözlemi tamamladı.
  /// Cascade gate motoru bağımlı kuralları açabilir.
  Future<void> markObserved({
    required String ruleKey,
    required RecommendationTarget target,
    DateTime? at,
  }) async {
    final key = keyFor(ruleKey: ruleKey, target: target);
    final prev = _read(key);
    final t = at ?? DateTime.now();
    final entry = LedgerEntry(
      state: RuleEngagementState.observed,
      shownAt: prev?.shownAt ?? t,
      observedAt: t,
      executedAt: prev?.executedAt,
    );
    await _box.put(key, entry.toMap());
  }

  /// Kullanıcı aksiyonu uyguladı (suladı/ilaçladı/gübreledi/hasat yaptı).
  Future<void> markExecuted({
    required String ruleKey,
    required RecommendationTarget target,
    DateTime? at,
  }) async {
    final key = keyFor(ruleKey: ruleKey, target: target);
    final prev = _read(key);
    final t = at ?? DateTime.now();
    final entry = LedgerEntry(
      state: RuleEngagementState.executed,
      shownAt: prev?.shownAt ?? t,
      observedAt: prev?.observedAt,
      executedAt: t,
    );
    await _box.put(key, entry.toMap());
  }

  /// Verilen aktivite tipi gerçekleştiğinde, `clearOnActivities` listesinde
  /// eşleşen tavsiyeyi ledger'dan temizler. Hangi tavsiyeleri etkilediğini
  /// bilmediğimiz için kuralı çağıran katman lookup yapar; burada sadece
  /// keyFor üzerinden silme servisi sunulur.
  Future<void> clear({
    required String ruleKey,
    required RecommendationTarget target,
  }) async {
    final key = keyFor(ruleKey: ruleKey, target: target);
    await _box.delete(key);
  }

  /// Belirli bir tarladaki TÜM ledger satırlarını temizler — bitki silindiğinde
  /// veya tarla silindiğinde çağrılır.
  Future<void> clearForField(String fieldId) async {
    final keysToRemove = _box.keys
        .where((k) => k.toString().contains('::$fieldId::'))
        .toList();
    for (final k in keysToRemove) {
      await _box.delete(k);
    }
  }
}
