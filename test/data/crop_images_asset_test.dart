import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('crop image map only points to existing PNG assets', () {
    final raw = File('assets/data/crop_images.json').readAsStringSync();
    final decoded = jsonDecode(raw) as Map<String, dynamic>;

    expect(decoded, containsPair('Ayçiçeği', 'aycicegi.png'));
    expect(decoded, containsPair('Çay', 'cay.png'));
    expect(decoded, containsPair('Portakal', 'portakal.png'));
    expect(decoded, containsPair('Mısır', 'misir.png'));
    expect(decoded, containsPair('Domates', 'domates.png'));

    for (final filename in decoded.values.cast<String>()) {
      expect(filename.endsWith('.png'), isTrue);
      expect(File('assets/crops/$filename').existsSync(), isTrue);
    }
  });
}
