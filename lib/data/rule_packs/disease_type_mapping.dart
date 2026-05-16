/// `FieldPlantInstances.diseaseType` kolonundaki Türkçe değerleri rule pack
/// `observed_symptom` fact anahtarlarına eşler (CLAUDE.md sec 15).
///
/// Kaynak liste: `lib/data/disease_types.dart` `DiseaseTypes.commonTurkish`
/// + `DiseasePickerSheet` üzerinden gelen serbest girişler.
///
/// Eşleşmeyen girişler `null` döner — kural tetiklenmez (sessiz davranış,
/// CLAUDE.md sec 28 "kaynaksız öneri verme" kuralına uyar).
///
/// ## Yeni hastalık türü eklenirse
///
/// 1. `DiseaseTypes.commonTurkish` listesine Türkçe adı ekleyin.
/// 2. Bu dosyaya bir `case` ekleyin → fact `observed_symptom` değeri.
/// 3. İlgili crop rule pack'inde o `observed_symptom` değerine bakan kural
///    var mı kontrol edin.
class DiseaseTypeMapping {
  DiseaseTypeMapping._();

  /// Türkçe diseaseType string → fact symptom key.
  /// FactBuilder bu çıktıyı `FactKeys.observedSymptom` alanına yazar.
  static String? toSymptomKey(String? trDiseaseType) {
    if (trDiseaseType == null || trDiseaseType.trim().isEmpty) return null;
    final n = _normalize(trDiseaseType);

    if (n.contains('yaprak lekes') || n.contains('septoria') ||
        n.contains('alternaria')) {
      return 'leaf_spot';
    }
    if (n.contains('mildiy') || n.contains('downy')) return 'downy_mildew';
    if (n.contains('kullem') || n.contains('powdery')) return 'powdery_mildew';
    if (n.contains('pas') || n.contains('rust')) return 'rust';
    if (n.contains('mozaik') || n.contains('virus') || n.contains('virüs')) {
      return 'mosaic_virus';
    }
    if (n.contains('bakteriyel') || n.contains('bacterial')) {
      return 'bacterial_blight';
    }
    if (n.contains('kok curukl') || n.contains('root rot')) return 'stem_rot';
    if (n.contains('sap curukl') || n.contains('stem rot')) return 'stem_rot';
    if (n.contains('bas curukl') || n.contains('head rot') ||
        n.contains('sclerotinia')) {
      return 'head_rot';
    }
    if (n.contains('kursuni kuf') || n.contains('grey mold') ||
        n.contains('botrytis')) {
      return 'grey_mold';
    }
    if (n.contains('antraknoz') || n.contains('anthracnose')) {
      return 'anthracnose';
    }
    if (n.contains('solgunluk') || n.contains('wilt') ||
        n.contains('verticillium') || n.contains('fusarium')) {
      return 'wilt';
    }
    return null;
  }

  /// Bilinmeyen/serbest text disease type → null (`exists` operatörü
  /// hâlâ doğrudur ama spesifik kural eşleşmesi olmaz).
  static String _normalize(String s) => s
      .toLowerCase()
      .replaceAll('ç', 'c')
      .replaceAll('ğ', 'g')
      .replaceAll('ı', 'i')
      .replaceAll('İ', 'i')
      .replaceAll('ö', 'o')
      .replaceAll('ş', 's')
      .replaceAll('ü', 'u')
      .trim();
}
