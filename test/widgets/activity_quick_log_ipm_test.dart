import 'package:feng_498/widgets/activity_quick_log.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
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
