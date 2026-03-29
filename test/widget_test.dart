// Temel smoke testi - Uygulamanın hatasız başladığını kontrol eder.
import 'package:flutter_test/flutter_test.dart';
import 'package:feng_498/main.dart';

void main() {
  testWidgets('SmartAgriApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const SmartAgriApp());
    expect(find.byType(SmartAgriApp), findsOneWidget);
  });
}
