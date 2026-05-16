import 'package:feng_498/screens/advisor_screen.dart';
import 'package:feng_498/services/verified_advisor_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> revealAnswer(WidgetTester tester, Finder finder) async {
    await tester.scrollUntilVisible(
      finder,
      260,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
  }

  Widget buildSubject() {
    return const ProviderScope(
      child: MaterialApp(
        home: AdvisorScreen(
          showFieldPicker: false,
          serviceOverride: VerifiedAdvisorService(loadRepository: false),
        ),
      ),
    );
  }

  testWidgets('Danışmana Sor ekranı açılır ve boş sorguda uyarır',
      (tester) async {
    await tester.pumpWidget(buildSubject());

    expect(find.text('Danışmana Sor'), findsOneWidget);
    expect(find.text('Sorununuzu veya isteğinizi yazın'), findsOneWidget);

    await tester.tap(find.text('Yanıtla'));
    await tester.pump();

    expect(find.text('Lütfen sorunuzu veya isteğinizi yazın.'), findsOneWidget);
  });

  testWidgets('kaynaklı sorguda cevap kartı ve kaynaklar görünür',
      (tester) async {
    await tester.pumpWidget(buildSubject());

    await tester.enterText(
      find.byType(TextField),
      'Domateste yaprak lekesi var',
    );
    await tester.tap(find.text('Yanıtla'));
    await tester.pumpAndSettle();

    await revealAnswer(tester, find.text('Kısa yanıt'));
    expect(find.text('Kısa yanıt'), findsOneWidget);
    expect(find.text('Ne yapmalı'), findsOneWidget);
    expect(find.text('Kaynaklar'), findsOneWidget);
    expect(find.textContaining('TAGEM'), findsWidgets);
  });

  testWidgets('uygulama sorusunda ekran yolu gösterir', (tester) async {
    await tester.pumpWidget(buildSubject());

    await tester.enterText(
      find.byType(TextField),
      'Maliyetleri nereden takip ederim?',
    );
    await tester.tap(find.text('Yanıtla'));
    await tester.pumpAndSettle();

    await revealAnswer(
      tester,
      find.textContaining('Tarla detayı > Cüzdan veya Maliyet ekranı'),
    );
    expect(find.textContaining('Gelir ve maliyet takibi'), findsWidgets);
    expect(find.textContaining('Tarla detayı > Cüzdan'), findsOneWidget);
    expect(find.text('Kaynaklar'), findsOneWidget);
  });

  testWidgets('kaynaksız sorguda doğrulanmış kayıt bulunamadı görünür',
      (tester) async {
    await tester.pumpWidget(buildSubject());

    await tester.enterText(
      find.byType(TextField),
      'Şeftalide hangi ilaç kullanılır?',
    );
    await tester.tap(find.text('Yanıtla'));
    await tester.pumpAndSettle();

    await revealAnswer(
      tester,
      find.textContaining('doğrulanmış Türkiye kaynaklı kayıt bulunamadı'),
    );
    expect(
      find.textContaining('doğrulanmış Türkiye kaynaklı kayıt bulunamadı'),
      findsOneWidget,
    );
    expect(find.text('Kaynaklar'), findsOneWidget);
  });
}
