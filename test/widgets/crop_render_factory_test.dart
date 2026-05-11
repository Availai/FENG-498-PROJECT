import 'package:feng_498/widgets/crop_render_factory.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const surfaceArrowKey = ValueKey<String>('crop-facing-surface-arrow');

  testWidgets('yön seçilmiş bitkide baktığı yön yüzey oku gösterilir',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 180,
            height: 220,
            child: buildCropMarkerWidget(
              cropName: 'Ayçiçeği',
              cropColor: Colors.green,
              maturityPercent: 70,
              facingDirection: 'east',
            ),
          ),
        ),
      ),
    );

    expect(find.byKey(surfaceArrowKey), findsOneWidget);
    expect(find.byIcon(Icons.navigation_rounded), findsNothing);
  });

  testWidgets('yön seçilmemiş bitkide yüzey yön oku çizilmez', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 180,
            height: 220,
            child: buildCropMarkerWidget(
              cropName: 'Ayçiçeği',
              cropColor: Colors.green,
              maturityPercent: 70,
            ),
          ),
        ),
      ),
    );

    expect(find.byKey(surfaceArrowKey), findsNothing);
  });

  testWidgets('seçili bitkide yön için bitki görseli oynatılmaz',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 180,
            height: 220,
            child: buildCropMarkerWidget(
              cropName: 'Ayçiçeği',
              cropColor: Colors.green,
              maturityPercent: 70,
              facingDirection: 'east',
              isHighlighted: true,
            ),
          ),
        ),
      ),
    );

    expect(find.byType(AnimatedScale), findsNothing);
  });

  testWidgets('hover durumunda bitki görseli büyüme tepkisi verir',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 180,
            height: 220,
            child: buildCropMarkerWidget(
              cropName: 'Ayçiçeği',
              cropColor: Colors.green,
              maturityPercent: 70,
              facingDirection: 'east',
              isHighlighted: true,
              isHovered: true,
            ),
          ),
        ),
      ),
    );

    expect(find.byType(AnimatedScale), findsOneWidget);
  });
}
