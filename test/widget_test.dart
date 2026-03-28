// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:feng_498/main.dart';

void main() {
  testWidgets('SmartAgriApp temel widget testi', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const SmartAgriApp());

    // Uygulamanın başarıyla yüklendiğini ve temel bileşenlerin ekranda olduğunu doğrula.
    expect(find.text('Tarımsal Analiz (MVP)'), findsOneWidget);
    expect(find.text('Tarlayı Analiz Et'), findsOneWidget);
  });
}
