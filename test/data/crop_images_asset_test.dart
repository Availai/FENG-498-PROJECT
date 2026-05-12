import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// 5 öncelikli ürün (Ayçiçeği, Çay, Portakal, Mısır, Domates) için PNG
/// asset'inin haritada ve diskte mevcut olduğunu doğrular. Diğer 220+ ürün
/// için runtime sprite-fallback (PNG→JPG→placeholder) yeterlidir; bu test
/// vitrin ürünleri kapsar.
void main() {
  test('öncelikli 5 ürün PNG asseti haritada ve diskte mevcut', () {
    final raw = File('assets/data/crop_images.json').readAsStringSync();
    final decoded = jsonDecode(raw) as Map<String, dynamic>;

    const priority = <String, String>{
      'Ayçiçeği': 'aycicegi.png',
      'Çay': 'cay.png',
      'Portakal': 'portakal.png',
      'Mısır': 'misir.png',
      'Domates': 'domates.png',
    };

    for (final entry in priority.entries) {
      expect(decoded, containsPair(entry.key, entry.value));
      expect(
        File('assets/crops/${entry.value}').existsSync(),
        isTrue,
        reason: 'assets/crops/${entry.value} diskte bulunamadı',
      );
    }
  });

  test('haritada tanımlı her girdi .png veya .jpg uzantısı kullanır', () {
    final raw = File('assets/data/crop_images.json').readAsStringSync();
    final decoded = jsonDecode(raw) as Map<String, dynamic>;

    for (final filename in decoded.values.cast<String>()) {
      final isImageExt = filename.endsWith('.png') || filename.endsWith('.jpg');
      expect(isImageExt, isTrue,
          reason: 'beklenmedik uzantı: $filename');
    }
  });
}
