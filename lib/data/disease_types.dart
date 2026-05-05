/// Türkiye'de yaygın bitki hastalıkları — manuel hastalık girişinde dropdown.
/// AI implementasyonu eklendiğinde teşhis sonucu da bu listede yer alıyor mu
/// diye eşleştirilebilir; eşleşmiyorsa "Diğer" altına serbest metin yazılır.
class DiseaseTypes {
  /// Yaygın hastalık adları — preset dropdown.
  static const List<String> commonTurkish = <String>[
    'Yaprak Lekesi',
    'Mildiyö',
    'Külleme',
    'Pas',
    'Mozaik Virüs',
    'Bakteriyel Yanıklık',
    'Kök Çürüklüğü',
    'Antraknoz',
    'Bilinmiyor',
  ];

  /// Listede olmayan bir hastalık serbest metin olarak girildiğinde kullanılır.
  static const String otherKey = 'Diğer';

  /// Sağlık durumu sabitleri — `FieldPlantInstances.healthStatus` sütunu.
  static const String statusHealthy = 'healthy';
  static const String statusDiseased = 'diseased';
  static const String statusTreating = 'treating';
  static const String statusDead = 'dead';

  /// Tanı kaynağı sabitleri — `FieldPlantInstances.diagnosisSource` sütunu.
  static const String sourceManual = 'manual';
  static const String sourceAiPending = 'ai_pending';
  static const String sourceAiCompleted = 'ai_completed';

  /// Sağlık durumu için Türkçe etiket — UI'da kullanılır.
  static String labelForStatus(String status) {
    switch (status) {
      case statusDiseased:
        return 'Hasta';
      case statusTreating:
        return 'Tedavi ediliyor';
      case statusDead:
        return 'Ölü';
      case statusHealthy:
      default:
        return 'Sağlıklı';
    }
  }
}
