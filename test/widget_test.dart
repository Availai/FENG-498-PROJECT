// Temel smoke testi - Uygulamanın hatasız başladığını kontrol eder.
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:feng_498/main.dart';
import 'package:feng_498/services/app_providers.dart';

void main() {
  testWidgets('SmartAgriApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStateChangesProvider.overrideWith(
            (ref) => Stream<User?>.value(null),
          ),
        ],
        child: const SmartAgriApp(),
      ),
    );
    expect(find.byType(SmartAgriApp), findsOneWidget);
  });
}
