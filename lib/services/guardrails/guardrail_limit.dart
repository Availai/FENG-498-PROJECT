/// Guardrail (aşırı girdi seti) — limit sözleşmesi ve yargı modeli.
///
/// Bu dosya **saf veri + enum** içerir; IO, takvim veya UI yoktur
/// (CLAUDE.md §22). Limitler yeni sabit uydurularak değil, projedeki
/// mevcut kaynaklı değerlerden (FAO-56 Kc, TurkiyeCropGuides sezon suyu,
/// NPK doz profilleri, TAGEM ortalamaları) **türetilerek** kurulur.
///
/// İki kademeli set stratejisi (kullanıcı kararı):
///   • softMax aşılırsa → [GuardrailLevel.warn]  : uyar + gerekçe, kayıt serbest.
///   • hardMax aşılırsa → [GuardrailLevel.block] : onay zorunlu ("Yine de kaydet").
library;

/// Aşımın hangi eksende olduğunu belirtir. Dahili enum (kullanıcıya görünmez).
enum GuardrailAxis {
  /// Sulama suyu (mm veya L). FAO-56 toprak su kapasitesi + sezon hedefi.
  water,

  /// Mevsimlik toplam azot (kg/dekar). §16 gübreleme güvenliği.
  nitrogen,

  /// Toprak tuzluluğu / EC kaynaklı yıkama-üstü risk. §16 EC kontrolü.
  salinity,

  /// İlaçlama sonrası sahaya yeniden girme aralığı (REI, saat). §17 BKÜ.
  pesticideReentry,
}

/// İki kademeli set seviyesi.
enum GuardrailLevel {
  /// Limit altında — hiçbir uyarı çizilmez, mevcut akış birebir korunur.
  ok,

  /// Yumuşak sınır aşıldı — turuncu uyarı + gerekçe; kayıt yine yapılabilir.
  warn,

  /// Sert sınır aşıldı — onay (AlertDialog) zorunlu; kullanıcı bilerek geçer.
  block,
}

/// Tek bir eksen için iki kademeli limit tanımı.
///
/// [softMax] ve [hardMax] aynı birimdedir ([unit]). [sourceIds] §12 kanıt
/// zincirini taşır; limit kaynağı belirsizse boş bırakılmaz, en azından
/// türetildiği mevcut kaynak referansı yazılır.
class GuardrailLimit {
  final GuardrailAxis axis;
  final double softMax;
  final double hardMax;
  final String unit;
  final List<String> sourceIds;

  /// Bu limit kesin bir tavan mı, yoksa yalnızca uyarı amaçlı genel bir
  /// referans mı? §16 gereği toprak analizi yokken azot için **kesin tavan
  /// konulamaz** → bu durumda [isAdvisoryOnly] true olur ve motor
  /// [GuardrailLevel.block] üretmez, en fazla [GuardrailLevel.warn] verir.
  final bool isAdvisoryOnly;

  const GuardrailLimit({
    required this.axis,
    required this.softMax,
    required this.hardMax,
    required this.unit,
    required this.sourceIds,
    this.isAdvisoryOnly = false,
  });
}

/// Bir aşım kontrolünün deterministik sonucu.
///
/// Aynı girdi → aynı [GuardrailVerdict] (CLAUDE.md §22). Hiçbir alan
/// kullanıcıya İngilizce sızdırılmaz; [reasonTr] ve [recommendationTr]
/// Türkçedir (§5.1).
class GuardrailVerdict {
  final GuardrailAxis axis;
  final GuardrailLevel level;

  /// Kullanıcının girmek istediği değer (örn. bu sulamanın mm'si).
  final double attemptedValue;

  /// Bu girdi eklenince ulaşılacak toplam (mevcut birikim + attempt).
  final double projectedTotal;

  /// Aşılan eşik (warn'da softMax, block'ta hardMax; ok'ta hardMax referansı).
  final double limitValue;

  final String unit;

  /// Tek satır Türkçe gerekçe (yaşlı kullanıcı için sade). Örn:
  /// "Bu hafta su hedefinin %185'ine ulaşıyor — kök bölgesi boğulabilir."
  final String reasonTr;

  /// Tek satır Türkçe aksiyon önerisi. Örn:
  /// "Bir sonraki sulamayı 2 gün erteleyin."
  final String recommendationTr;

  /// block → true; UI onay diyaloğu açar.
  bool get requiresConfirm => level == GuardrailLevel.block;

  final List<String> sourceIds;

  const GuardrailVerdict({
    required this.axis,
    required this.level,
    required this.attemptedValue,
    required this.projectedTotal,
    required this.limitValue,
    required this.unit,
    required this.reasonTr,
    required this.recommendationTr,
    required this.sourceIds,
  });

  /// Limit altında, sessiz geçiş — UI hiçbir şey çizmez.
  factory GuardrailVerdict.ok({
    required GuardrailAxis axis,
    required double attemptedValue,
    required double projectedTotal,
    required double limitValue,
    required String unit,
    List<String> sourceIds = const [],
  }) {
    return GuardrailVerdict(
      axis: axis,
      level: GuardrailLevel.ok,
      attemptedValue: attemptedValue,
      projectedTotal: projectedTotal,
      limitValue: limitValue,
      unit: unit,
      reasonTr: '',
      recommendationTr: '',
      sourceIds: sourceIds,
    );
  }

  /// Hedefe göre yüzde (UI rozetinde "%185" göstermek için). Limit 0 ise null.
  int? get percentOfLimit {
    if (limitValue <= 0) return null;
    return (projectedTotal / limitValue * 100).round();
  }
}
