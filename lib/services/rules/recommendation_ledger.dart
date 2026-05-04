import 'package:hive/hive.dart';

import 'recommendation.dart';

/// Tavsiye motoru için "şu kuralı en son ne zaman gösterdik" kayıt defteri.
///
/// Hive box `recommendation_ledger`. Her satır key = `ruleKey::targetKey`.
/// Değer `int` (epoch ms). Cooldown penceresinde duran kayıtlar UI'a düşmez;
/// kullanıcı `clearOnActivities` listesindeki bir aktiviteyi yapınca silinir
/// — böylece tavsiye yeniden tetiklenebilir.
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

  /// Cooldown'da mı? `cooldownHours == 0` ise her zaman false.
  bool isOnCooldown({
    required String ruleKey,
    required RecommendationTarget target,
    required int cooldownHours,
    DateTime? now,
  }) {
    if (cooldownHours <= 0) return false;
    final key = keyFor(ruleKey: ruleKey, target: target);
    final raw = _box.get(key);
    if (raw is! int) return false;
    final shownAt = DateTime.fromMillisecondsSinceEpoch(raw);
    final t = now ?? DateTime.now();
    final delta = t.difference(shownAt).inMinutes;
    return delta < cooldownHours * 60;
  }

  /// Tavsiye kullanıcıya gösterildi → ledger'a yaz.
  Future<void> markShown({
    required String ruleKey,
    required RecommendationTarget target,
    DateTime? at,
  }) async {
    final key = keyFor(ruleKey: ruleKey, target: target);
    await _box.put(key, (at ?? DateTime.now()).millisecondsSinceEpoch);
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
