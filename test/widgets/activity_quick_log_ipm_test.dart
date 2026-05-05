import 'package:feng_498/widgets/activity_quick_log.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('sulama kaydi litre bosken kaydedilmez', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: ActivityQuickLog(
              fieldId: 'field-1',
              fieldAreaDekar: 1,
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Suladım'));
    await tester.pumpAndSettle();

    expect(find.text('Verilen su'), findsOneWidget);
    expect(find.textContaining('opsiyonel'), findsNothing);

    // Önerilen miktar prefill olmuş olabilir — boş litre senaryosu için temizle.
    await tester.enterText(find.widgetWithText(TextField, 'Örn. 1200'), '');
    await tester.pump();

    final saveButton = find.widgetWithText(ElevatedButton, 'Suladım');
    await tester.ensureVisible(saveButton);
    await tester.tap(saveButton);
    await tester.pump();

    expect(
      find.text('Sulama kaydı için verilen su miktarını litre olarak girin.'),
      findsOneWidget,
    );
  });

  testWidgets('aycicegi ilac katalogu esik dogrulanmadan gizlidir',
      (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: ActivityQuickLog(
              fieldId: 'field-1',
              cropId: 'crop-1',
              fieldAreaDekar: 2,
              fieldCrops: [
                {
                  'id': 'crop-1',
                  'name': 'Ayçiçeği',
                  'planted_date': '01.04.2026',
                  'row_spacing_cm': 70,
                  'plant_spacing_cm': 30,
                },
              ],
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('İlaçladım'));
    await tester.pumpAndSettle();

    expect(find.text('Ayçiçeği entegre mücadele kilidi'), findsOneWidget);
    expect(find.text('Fusilade Forte'), findsNothing);
    expect(find.textContaining('Kimyasal kapı kapalı'), findsOneWidget);
  });
}
