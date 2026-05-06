/// Münavebe (crop rotation) danışmanı — yerel.
///
/// Backend `_crop_rotation_rules` ile aynı mantığı Flutter tarafında da
/// çalıştırır: 3 yıl üst üste tahıl → baklagil/ayçiçeği önerisi,
/// Solanaceae tekrarı uyarısı, ayçiçeğinin kendini izlemesi (Sclerotinia).
library;

class RotationAdvice {
  final String severity; // info, warning, critical
  final String title;
  final String message;
  final List<String> suggestedCrops;

  const RotationAdvice({
    required this.severity,
    required this.title,
    required this.message,
    this.suggestedCrops = const [],
  });
}

class CropRotationAdvisor {
  static const _grains = {
    'bugday',
    'arpa',
    'yulaf',
    'cavdar',
    'tritikale',
    'misir'
  };
  static const _solanaceae = {'domates', 'biber', 'patlıcan', 'patates'};
  static const _sunflower = 'aycicegi';

  static String _normalize(String s) => s
      .toLowerCase()
      .trim()
      .replaceAll('\u011f', 'g')
      .replaceAll('\u00fc', 'u')
      .replaceAll('\u015f', 's')
      .replaceAll('\u0131', 'i')
      .replaceAll('\u00f6', 'o')
      .replaceAll('\u00e7', 'c');

  /// [history]: son → ilk sırayla ürün listesi (en yeniden en eskiye).
  /// [next]: planlanan sonraki ürün (opsiyonel).
  static List<RotationAdvice> analyze({
    required List<String> history,
    String? next,
  }) {
    final list = <RotationAdvice>[];
    final h = history.map(_normalize).toList();
    final n = next != null ? _normalize(next) : null;
    final displayLast = history.isNotEmpty ? history.first.trim() : '';
    final displayNext = next?.trim() ?? '';

    // 3 yıl üst üste tahıl monokültürü
    if (h.length >= 3 &&
        _grains.contains(h[0]) &&
        _grains.contains(h[1]) &&
        _grains.contains(h[2])) {
      list.add(const RotationAdvice(
        severity: 'warning',
        title: 'Tahıl Monokültürü',
        message: '3 yıl üst üste tahıl ekimi toprak verimliliğini düşürür ve '
            'Gaeumannomyces graminis (kök yanıklığı) riskini artırır. '
            'Gelecek sezon baklagil veya ayçiçeği ekimi önerilir.',
        suggestedCrops: ['nohut', 'mercimek', 'fasulye', 'ayçiçeği', 'kanola'],
      ));
    }

    // Solanaceae tekrarı (domates-domates, biber-biber vb.)
    if (h.isNotEmpty &&
        n != null &&
        _solanaceae.contains(h[0]) &&
        _solanaceae.contains(n)) {
      list.add(RotationAdvice(
        severity: 'warning',
        title: 'Patlıcangiller Tekrarı',
        message:
            '$displayLast sonrası $displayNext ekimi — aynı familyadan ardışık ekim '
            'Verticillium, nematod (Meloidogyne spp.) ve Sclerotinia '
            'birikimi yapar. En az 3 yıl ara verin.',
        suggestedCrops: const ['buğday', 'mısır', 'fasulye', 'bakla'],
      ));
    }

    // Ayçiçeği kendini izleme
    if (h.isNotEmpty && n != null && h[0] == _sunflower && n == _sunflower) {
      list.add(const RotationAdvice(
        severity: 'critical',
        title: 'Ayçiçeği Kendini İzliyor',
        message:
            'Ayçiçeği ardışık ekimi Sclerotinia sclerotiorum (beyaz çürüklük) '
            've orobanş (canavar otu) patlamasına yol açar. Minimum 4 yıl ara.',
        suggestedCrops: ['buğday', 'arpa', 'nohut', 'mısır'],
      ));
    }

    return list;
  }
}
