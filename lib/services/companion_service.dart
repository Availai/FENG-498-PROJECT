import 'package:flutter/material.dart';

// ── Tek bir uyarı ───────────────────────────────────────────────────────────
enum WarnLevel { error, warning, info }

class GardenWarning {
  final WarnLevel level;
  final String title;
  final String message;
  final IconData icon;

  const GardenWarning({
    required this.level,
    required this.title,
    required this.message,
    required this.icon,
  });

  Color get color {
    switch (level) {
      case WarnLevel.error:
        return Colors.red.shade700;
      case WarnLevel.warning:
        return Colors.orange.shade700;
      case WarnLevel.info:
        return Colors.blue.shade700;
    }
  }

  Color get bgColor {
    switch (level) {
      case WarnLevel.error:
        return Colors.red.shade50;
      case WarnLevel.warning:
        return Colors.orange.shade50;
      case WarnLevel.info:
        return Colors.blue.shade50;
    }
  }

  String get emoji {
    switch (level) {
      case WarnLevel.error:
        return '🚫';
      case WarnLevel.warning:
        return '⚠️';
      case WarnLevel.info:
        return '💡';
    }
  }
}

// ── Varsayılan ekim parametreleri ──────────────────────────────────────────
class CropDefaults {
  final String name;
  final String emoji;
  final double rowSpacingCm;
  final double plantSpacingCm;
  final double depthCm;
  final Color color;
  final double minTempC;
  final double maxTempC;
  final String season; // 'ilkbahar', 'yaz', 'sonbahar', 'kış', 'tüm yıl'

  const CropDefaults({
    required this.name,
    required this.emoji,
    required this.rowSpacingCm,
    required this.plantSpacingCm,
    required this.depthCm,
    required this.color,
    required this.minTempC,
    required this.maxTempC,
    required this.season,
  });

  /// Bu bitkinin 1 m² alanında kaç bitki sığar (makul yoğunluk)
  double get plantsPerM2 => (100 / rowSpacingCm) * (100 / plantSpacingCm);
}

// ── Kural tabanlı kural motoru ─────────────────────────────────────────────
class CompanionService {
  // ── Kötü komşuluklar (her iki yön de kapsanmış) ──────────────────────────
  static const Map<String, List<String>> _incompatible = {
    'Domates': ['Patates', 'Rezene', 'Lahana', 'Mısır', 'Arpa'],
    'Patates': ['Domates', 'Kabak', 'Salatalık', 'Ayçiçeği'],
    'Soğan': ['Fasulye', 'Bezelye', 'Mercimek'],
    'Sarımsak': ['Fasulye', 'Bezelye', 'Mercimek'],
    'Fasulye': ['Soğan', 'Sarımsak', 'Biber', 'Rezene', 'Pırasa'],
    'Bezelye': ['Soğan', 'Sarımsak', 'Rezene'],
    'Lahana': ['Domates', 'Çilek', 'Rezene', 'Dereotu'],
    'Rezene': ['Domates', 'Lahana', 'Fasulye', 'Bezelye', 'Biber', 'Salatalık'],
    'Ayçiçeği': ['Patates', 'Lahana'],
    'Biber': ['Fasulye', 'Rezene'],
    'Kabak': ['Patates', 'Ayçiçeği'],
    'Salatalık': ['Patates', 'Rezene', 'Aromatik bitkiler'],
    'Mısır': ['Domates', 'Kereviz'],
    'Çilek': ['Lahana', 'Rezene'],
    'Pırasa': ['Fasulye', 'Bezelye'],
  };

  // ── İyi komşuluklar ────────────────────────────────────────────────────
  static const Map<String, List<String>> _companions = {
    'Domates': ['Fesleğen', 'Havuç', 'Soğan', 'Maydanoz', 'Ispanak'],
    'Mısır': ['Fasulye', 'Kabak', 'Bezelye'],
    'Fasulye': ['Mısır', 'Kabak', 'Havuç', 'Çilek'],
    'Kabak': ['Mısır', 'Fasulye', 'Soğan'],
    'Havuç': ['Soğan', 'Sarımsak', 'Domates', 'Marul'],
    'Soğan': ['Havuç', 'Domates', 'Lahana', 'Patlıcan'],
    'Sarımsak': ['Havuç', 'Gül', 'Domates'],
    'Lahana': ['Soğan', 'Sarımsak', 'Nane', 'Kekik'],
    'Salatalık': ['Fasulye', 'Bezelye', 'Lahana', 'Marul'],
    'Fesleğen': ['Domates', 'Biber', 'Patlıcan'],
    'Çilek': ['Fasulye', 'Ispanak', 'Marul'],
    'Patates': ['Fasulye', 'Bezelye', 'Lahana', 'Nane'],
  };

  // ── Bitki kataloğu ─────────────────────────────────────────────────────
  static final Map<String, CropDefaults> catalog = {
    'Domates': CropDefaults(
        name: 'Domates',
        emoji: '🍅',
        rowSpacingCm: 60,
        plantSpacingCm: 50,
        depthCm: 2,
        color: Colors.red,
        minTempC: 15,
        maxTempC: 35,
        season: 'yaz'),
    'Biber': CropDefaults(
        name: 'Biber',
        emoji: '🫑',
        rowSpacingCm: 50,
        plantSpacingCm: 40,
        depthCm: 1,
        color: Colors.orange,
        minTempC: 15,
        maxTempC: 33,
        season: 'yaz'),
    'Patlıcan': CropDefaults(
        name: 'Patlıcan',
        emoji: '🍆',
        rowSpacingCm: 70,
        plantSpacingCm: 50,
        depthCm: 1,
        color: Colors.purple,
        minTempC: 20,
        maxTempC: 35,
        season: 'yaz'),
    'Salatalık': CropDefaults(
        name: 'Salatalık',
        emoji: '🥒',
        rowSpacingCm: 80,
        plantSpacingCm: 50,
        depthCm: 2,
        color: Colors.lightGreen,
        minTempC: 18,
        maxTempC: 35,
        season: 'yaz'),
    'Kabak': CropDefaults(
        name: 'Kabak',
        emoji: '🎃',
        rowSpacingCm: 120,
        plantSpacingCm: 100,
        depthCm: 3,
        color: Colors.yellow.shade700,
        minTempC: 18,
        maxTempC: 38,
        season: 'yaz'),
    'Mısır': CropDefaults(
        name: 'Mısır',
        emoji: '🌽',
        rowSpacingCm: 70,
        plantSpacingCm: 25,
        depthCm: 5,
        color: Colors.amber,
        minTempC: 15,
        maxTempC: 38,
        season: 'yaz'),
    'Patates': CropDefaults(
        name: 'Patates',
        emoji: '🥔',
        rowSpacingCm: 70,
        plantSpacingCm: 30,
        depthCm: 10,
        color: Colors.brown,
        minTempC: 7,
        maxTempC: 25,
        season: 'ilkbahar'),
    'Soğan': CropDefaults(
        name: 'Soğan',
        emoji: '🧅',
        rowSpacingCm: 20,
        plantSpacingCm: 10,
        depthCm: 3,
        color: Colors.deepPurple,
        minTempC: 5,
        maxTempC: 28,
        season: 'ilkbahar'),
    'Sarımsak': CropDefaults(
        name: 'Sarımsak',
        emoji: '🧄',
        rowSpacingCm: 20,
        plantSpacingCm: 10,
        depthCm: 5,
        color: Colors.white70,
        minTempC: -5,
        maxTempC: 25,
        season: 'kış'),
    'Havuç': CropDefaults(
        name: 'Havuç',
        emoji: '🥕',
        rowSpacingCm: 25,
        plantSpacingCm: 5,
        depthCm: 1,
        color: Colors.deepOrange,
        minTempC: 7,
        maxTempC: 28,
        season: 'ilkbahar'),
    'Lahana': CropDefaults(
        name: 'Lahana',
        emoji: '🥬',
        rowSpacingCm: 60,
        plantSpacingCm: 50,
        depthCm: 1,
        color: Colors.green,
        minTempC: 5,
        maxTempC: 25,
        season: 'ilkbahar'),
    'Buğday': CropDefaults(
        name: 'Buğday',
        emoji: '🌾',
        rowSpacingCm: 15,
        plantSpacingCm: 5,
        depthCm: 4,
        color: Colors.amber.shade800,
        minTempC: 3,
        maxTempC: 32,
        season: 'sonbahar'),
    'Fasulye': CropDefaults(
        name: 'Fasulye',
        emoji: '🫘',
        rowSpacingCm: 50,
        plantSpacingCm: 10,
        depthCm: 4,
        color: Colors.teal,
        minTempC: 15,
        maxTempC: 32,
        season: 'yaz'),
    'Bezelye': CropDefaults(
        name: 'Bezelye',
        emoji: '🟢',
        rowSpacingCm: 40,
        plantSpacingCm: 5,
        depthCm: 3,
        color: Colors.lightGreen.shade700,
        minTempC: 5,
        maxTempC: 22,
        season: 'ilkbahar'),
    'Çilek': CropDefaults(
        name: 'Çilek',
        emoji: '🍓',
        rowSpacingCm: 35,
        plantSpacingCm: 30,
        depthCm: 2,
        color: Colors.pinkAccent,
        minTempC: 5,
        maxTempC: 28,
        season: 'ilkbahar'),
    'Kavun': CropDefaults(
        name: 'Kavun',
        emoji: '🍈',
        rowSpacingCm: 150,
        plantSpacingCm: 100,
        depthCm: 3,
        color: Colors.yellow.shade600,
        minTempC: 20,
        maxTempC: 40,
        season: 'yaz'),
    'Karpuz': CropDefaults(
        name: 'Karpuz',
        emoji: '🍉',
        rowSpacingCm: 200,
        plantSpacingCm: 100,
        depthCm: 3,
        color: Colors.green.shade600,
        minTempC: 22,
        maxTempC: 42,
        season: 'yaz'),
    'Fesleğen': CropDefaults(
        name: 'Fesleğen',
        emoji: '🌿',
        rowSpacingCm: 30,
        plantSpacingCm: 20,
        depthCm: 1,
        color: Colors.green.shade400,
        minTempC: 15,
        maxTempC: 35,
        season: 'yaz'),
    'Maydanoz': CropDefaults(
        name: 'Maydanoz',
        emoji: '🌱',
        rowSpacingCm: 20,
        plantSpacingCm: 10,
        depthCm: 1,
        color: Colors.lightGreen.shade400,
        minTempC: 5,
        maxTempC: 30,
        season: 'tüm yıl'),
    'Pırasa': CropDefaults(
        name: 'Pırasa',
        emoji: '🪴',
        rowSpacingCm: 30,
        plantSpacingCm: 15,
        depthCm: 3,
        color: Colors.green.shade700,
        minTempC: 2,
        maxTempC: 25,
        season: 'sonbahar'),
    'Ispanak': CropDefaults(
        name: 'Ispanak',
        emoji: '🥗',
        rowSpacingCm: 20,
        plantSpacingCm: 8,
        depthCm: 2,
        color: Colors.green.shade500,
        minTempC: 2,
        maxTempC: 20,
        season: 'ilkbahar'),
    'Marul': CropDefaults(
        name: 'Marul',
        emoji: '🥬',
        rowSpacingCm: 30,
        plantSpacingCm: 25,
        depthCm: 1,
        color: Colors.lightGreen.shade300,
        minTempC: 4,
        maxTempC: 22,
        season: 'ilkbahar'),
    'Rezene': CropDefaults(
        name: 'Rezene',
        emoji: '🌿',
        rowSpacingCm: 40,
        plantSpacingCm: 30,
        depthCm: 1,
        color: Colors.teal.shade300,
        minTempC: 5,
        maxTempC: 28,
        season: 'sonbahar'),
    'Ayçiçeği': CropDefaults(
        name: 'Ayçiçeği',
        emoji: '🌻',
        rowSpacingCm: 60,
        plantSpacingCm: 40,
        depthCm: 4,
        color: Colors.yellow,
        minTempC: 15,
        maxTempC: 40,
        season: 'yaz'),
  };

  static List<String> get cropNames => catalog.keys.toList()..sort();

  static CropDefaults? getDefaults(String name) => catalog[name];

  // ── Ana uyarı üretici ─────────────────────────────────────────────────
  static List<GardenWarning> generateWarnings({
    required List<Map<String, dynamic>> crops,
    required double fieldWidthM,
    required double fieldHeightM,
    double? currentTempC,
  }) {
    final warnings = <GardenWarning>[];
    if (crops.isEmpty) return warnings;

    final names = crops.map((c) => c['name'] as String).toList();
    final fieldAreaM2 = fieldWidthM * fieldHeightM;

    // 1. İnkompatible çiftler ───────────────────────────────────────────
    for (int i = 0; i < names.length; i++) {
      for (int j = i + 1; j < names.length; j++) {
        final a = names[i];
        final b = names[j];
        final badForA = _incompatible[a] ?? [];
        final badForB = _incompatible[b] ?? [];
        if (badForA.contains(b) || badForB.contains(a)) {
          warnings.add(GardenWarning(
            level: WarnLevel.error,
            title: '$a + $b uyumsuz!',
            message: '$a ve $b aynı tarlada yetiştirilmemeli. '
                'Ortak hastalık, kök rekabeti veya kimyasal inhibisyon '
                'her iki ürünün verimini ciddi şekilde düşürür.',
            icon: Icons.dangerous,
          ));
        }
      }
    }

    // 2. İyi komşular bildirimi ──────────────────────────────────────────
    for (int i = 0; i < names.length; i++) {
      for (int j = i + 1; j < names.length; j++) {
        final a = names[i];
        final b = names[j];
        final goodForA = _companions[a] ?? [];
        final goodForB = _companions[b] ?? [];
        if (goodForA.contains(b) || goodForB.contains(a)) {
          warnings.add(GardenWarning(
            level: WarnLevel.info,
            title: '$a + $b mükemmel komşu!',
            message:
                'Bu iki bitki birbirinin büyümesini destekler, zararlıları '
                'uzaklaştırır ve toprağı daha verimli kullanır.',
            icon: Icons.favorite,
          ));
        }
      }
    }

    // 3. Bölge çakışması ────────────────────────────────────────────────
    for (int i = 0; i < crops.length; i++) {
      for (int j = i + 1; j < crops.length; j++) {
        final aStart = (crops[i]['zone_start'] as num).toDouble();
        final aEnd = (crops[i]['zone_end'] as num).toDouble();
        final bStart = (crops[j]['zone_start'] as num).toDouble();
        final bEnd = (crops[j]['zone_end'] as num).toDouble();
        final overlapStart = aStart > bStart ? aStart : bStart;
        final overlapEnd = aEnd < bEnd ? aEnd : bEnd;
        if (overlapEnd > overlapStart + 0.02) {
          final overlapPct =
              ((overlapEnd - overlapStart) * 100).toStringAsFixed(0);
          warnings.add(GardenWarning(
            level: WarnLevel.warning,
            title:
                '${crops[i]['name']} ve ${crops[j]['name']} bölgeleri çakışıyor!',
            message:
                'İki bitkinin ekim bölgesi %$overlapPct oranında örtüşüyor. '
                'Bitkiler birbirinin kökleriyle rekabete girerek zayıflayabilir.',
            icon: Icons.layers_clear,
          ));
        }
      }
    }

    // 4. Çok kalabalık bölge ────────────────────────────────────────────
    for (final crop in crops) {
      final name = crop['name'] as String;
      final start = (crop['zone_start'] as num).toDouble();
      final end = (crop['zone_end'] as num).toDouble();
      final row = (crop['row_spacing_cm'] as num).toDouble();
      final plant = (crop['plant_spacing_cm'] as num).toDouble();
      final zoneW = fieldWidthM * (end - start);
      final rows = (fieldHeightM / (row / 100)).floor();
      final plantsPerRow = (zoneW / (plant / 100)).floor();
      final totalPlants = rows * plantsPerRow;
      final zoneAreaM2 = zoneW * fieldHeightM;

      final defaults = catalog[name];
      if (defaults != null && zoneAreaM2 > 0) {
        final density = totalPlants / zoneAreaM2;
        final maxDensity = defaults.plantsPerM2 * 1.3; // %30 tolerans
        if (density > maxDensity) {
          warnings.add(GardenWarning(
            level: WarnLevel.warning,
            title: '$name bölgesi fazla kalabalık!',
            message:
                '${zoneAreaM2.toStringAsFixed(0)} m² alana $totalPlants bitki '
                '(${density.toStringAsFixed(1)}/m²) sığdırılıyor. '
                'Önerilen: max ${defaults.plantsPerM2.toStringAsFixed(1)}/m². '
                'Sıra veya bitki aralığını artırın.',
            icon: Icons.density_large,
          ));
        }
      }
    }

    // 5. Çok dar bölge ─────────────────────────────────────────────────
    for (final crop in crops) {
      final name = crop['name'] as String;
      final start = (crop['zone_start'] as num).toDouble();
      final end = (crop['zone_end'] as num).toDouble();
      final row = (crop['row_spacing_cm'] as num).toDouble();
      final zoneW = fieldWidthM * (end - start);
      if (zoneW < (row / 100) * 2) {
        warnings.add(GardenWarning(
          level: WarnLevel.warning,
          title: '$name bölgesi çok dar!',
          message:
              'Bölge genişliği ${(zoneW * 100).toStringAsFixed(0)} cm iken '
              '$name için en az ${(row * 2).toStringAsFixed(0)} cm genişlik '
              'gerekiyor (2 sıra sığması için).',
          icon: Icons.width_normal,
        ));
      }
    }

    // 6. Toplam kapsama kontrolü ────────────────────────────────────────
    double totalCoverage = 0;
    for (final crop in crops) {
      final start = (crop['zone_start'] as num).toDouble();
      final end = (crop['zone_end'] as num).toDouble();
      totalCoverage += end - start;
    }
    if (totalCoverage < 0.5 && crops.isNotEmpty) {
      warnings.add(GardenWarning(
        level: WarnLevel.info,
        title: 'Tarlanın büyük kısmı boş',
        message: 'Ekim kapsamı tarlanın yalnızca '
            '${(totalCoverage * 100).toStringAsFixed(0)}%. '
            'Boş alanlara mevsime uygun örtü bitkisi veya gübre bitkisi (yonca, fiğ) ekleyebilirsiniz.',
        icon: Icons.space_dashboard,
      ));
    }

    // 7. Küçük tarla - büyük bitkiler ──────────────────────────────────
    for (final crop in crops) {
      final name = crop['name'] as String;
      final defaults = catalog[name];
      if (defaults != null) {
        final minAreaNeeded = defaults.rowSpacingCm /
            100 *
            defaults.plantSpacingCm /
            100 *
            4; // 4 bitki minimum
        if (fieldAreaM2 < minAreaNeeded) {
          warnings.add(GardenWarning(
            level: WarnLevel.warning,
            title: 'Tarla $name için küçük olabilir',
            message:
                '${fieldAreaM2.toStringAsFixed(0)} m² alan ${defaults.emoji} $name için '
                'oldukça dar. En az ${minAreaNeeded.toStringAsFixed(0)} m² önerilir.',
            icon: Icons.fullscreen_exit,
          ));
        }
      }
    }

    // 8. Hava durumu - sıcaklık uyarıları ─────────────────────────────
    if (currentTempC != null) {
      for (final crop in crops) {
        final name = crop['name'] as String;
        final defaults = catalog[name];
        if (defaults != null) {
          if (currentTempC < defaults.minTempC) {
            warnings.add(GardenWarning(
              level: WarnLevel.error,
              title: '$name için hava çok soğuk!',
              message: 'Anlık sıcaklık ${currentTempC.toStringAsFixed(1)}°C. '
                  '$name en az ${defaults.minTempC}°C ister. '
                  'Don riski varsa koruyucu örtü kullanın.',
              icon: Icons.ac_unit,
            ));
          } else if (currentTempC > defaults.maxTempC) {
            warnings.add(GardenWarning(
              level: WarnLevel.warning,
              title: '$name için hava çok sıcak!',
              message: 'Anlık sıcaklık ${currentTempC.toStringAsFixed(1)}°C. '
                  '$name max ${defaults.maxTempC}°C tolere eder. '
                  'Gölgeleme ve bol sulama uygulayın.',
              icon: Icons.thermostat,
            ));
          }
        }
      }
    }

    return warnings;
  }

  // ── Tahmini bitki sayısı ──────────────────────────────────────────────
  static int estimatePlantCount({
    required double fieldWidthM,
    required double fieldHeightM,
    required double zoneStart,
    required double zoneEnd,
    required double rowSpacingCm,
    required double plantSpacingCm,
  }) {
    final zoneW = fieldWidthM * (zoneEnd - zoneStart);
    final rows = (fieldHeightM / (rowSpacingCm / 100)).floor();
    final plantsPerRow = (zoneW / (plantSpacingCm / 100)).floor();
    return (rows * plantsPerRow).clamp(0, 999999);
  }
}
