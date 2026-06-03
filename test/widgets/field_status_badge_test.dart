import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:feng_498/services/field_state_service.dart';
import 'package:feng_498/services/guardrails/guardrail_limit.dart';
import 'package:feng_498/widgets/field_status_badge.dart';

void main() {
  CropFieldState state({
    double weeklyMm = 30,
    double targetMm = 34,
    DateTime? lastWater,
  }) =>
      CropFieldState(
        cropId: 'crop-1',
        cropName: 'Domates',
        areaDekar: 1,
        areaSqm: 1000,
        estimatedPlantCount: 100,
        weeklyWaterMm: weeklyMm,
        weeklyWaterLiters: weeklyMm * 1000,
        seasonalWaterMm: weeklyMm,
        seasonalWaterLiters: weeklyMm * 1000,
        weeklyWaterTargetMm: targetMm,
        lastWateredAt: lastWater,
        harvestedKg: 0,
        yieldKgPerDekar: 0,
      );

  Future<void> pump(WidgetTester tester, Widget child) async {
    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: SingleChildScrollView(child: child))),
    );
  }

  testWidgets('ideal su + uyarı yok → "Durum iyi" başlığı', (tester) async {
    final now = DateTime(2026, 6, 1);
    await pump(
      tester,
      FieldStatusBadge(
        state: state(
          weeklyMm: 30,
          lastWater: now.subtract(const Duration(days: 1)),
        ),
        activeVerdicts: const [],
        now: now,
      ),
    );
    expect(find.textContaining('Durum iyi'), findsOneWidget);
    expect(find.textContaining('dün'), findsOneWidget);
  });

  testWidgets('block uyarısı → "Dikkat gerekiyor" + gerekçe görünür',
      (tester) async {
    const verdict = GuardrailVerdict(
      axis: GuardrailAxis.water,
      level: GuardrailLevel.block,
      attemptedValue: 0,
      projectedTotal: 70,
      limitValue: 61,
      unit: 'mm/hafta',
      reasonTr: 'Bu hafta su miktarı çok yüksek.',
      recommendationTr: 'Sulamayı erteleyin.',
      sourceIds: [],
    );
    await pump(
      tester,
      FieldStatusBadge(
        state: state(weeklyMm: 70),
        activeVerdicts: const [verdict],
        now: DateTime(2026, 6, 1),
      ),
    );
    expect(find.textContaining('Dikkat gerekiyor'), findsOneWidget);
    expect(find.text('Bu hafta su miktarı çok yüksek.'), findsOneWidget);
    expect(find.text('Sulamayı erteleyin.'), findsOneWidget);
  });

  testWidgets('sulama kaydı yoksa Türkçe boş durum metni', (tester) async {
    await pump(
      tester,
      FieldStatusBadge(
        state: state(lastWater: null),
        activeVerdicts: const [],
        now: DateTime(2026, 6, 1),
      ),
    );
    expect(find.text('Henüz sulama kaydı yok'), findsOneWidget);
  });
}
