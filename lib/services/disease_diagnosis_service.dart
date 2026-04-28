/// Bitki hastalığı teşhisi için soyut servis arayüzü.
///
/// Şu an aktif implementasyon [StubDiseaseDiagnosisService]; fotoğrafı kabul
/// eder ama hastalık türünü belirlemez (UI manuel girişe yönlendirir). İleride
/// `GeminiDiseaseDiagnosisService` eklenecek — `agri_service.dart`'taki mevcut
/// `analyzeImage` → `geminiDiagnose` boru hattını [DiseaseDiagnosis] yapısına
/// maple eder. UI tarafında hiçbir değişiklik gerekmez; sadece
/// [diseaseDiagnosisServiceProvider] (app_providers.dart) yeni implementasyona
/// döndürülür.
abstract class DiseaseDiagnosisService {
  Future<DiseaseDiagnosis> diagnose({
    required String imagePath,
    String? cropName,
    double? lat,
    double? lng,
  });
}

/// Teşhis sonucu — başarılı/başarısız her durumda dolar; başarısızsa
/// [diseaseType] null olur.
class DiseaseDiagnosis {
  const DiseaseDiagnosis({
    this.diseaseType,
    this.confidence,
    this.recommendation,
    required this.source,
    required this.diagnosedAt,
  });

  /// Belirlenen hastalık adı (örn. 'Mildiyö'). null = belirlenemedi.
  final String? diseaseType;

  /// Teşhisin güvenilirlik skoru 0..1 (AI sonucu için).
  final double? confidence;

  /// Çiftçiye gösterilecek kısa öneri metni (varsa).
  final String? recommendation;

  /// Kaynağı: 'stub' | 'gemini' | 'local-ml'.
  final String source;
  final DateTime diagnosedAt;
}

/// Şimdilik aktif olan implementasyon. Foto path'i alır, hiçbir şey yapmaz —
/// boş bir teşhis döner. UI tarafında "AI henüz aktif değil, hastalık türünü
/// manuel girin" mesajı gösterilir, kullanıcı dropdown ile seçer.
class StubDiseaseDiagnosisService implements DiseaseDiagnosisService {
  const StubDiseaseDiagnosisService();

  @override
  Future<DiseaseDiagnosis> diagnose({
    required String imagePath,
    String? cropName,
    double? lat,
    double? lng,
  }) async {
    return DiseaseDiagnosis(
      diseaseType: null,
      source: 'stub',
      diagnosedAt: DateTime.now(),
    );
  }
}
