import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:feng_498/data/activity_types.dart';
import 'package:feng_498/services/guide_engine.dart' show AlertSeverity;
import 'package:feng_498/services/rules/recommendation.dart';
import 'package:feng_498/widgets/recommendation_card.dart';

void main() {
  testWidgets('tavsiye kartı komut, kaynak ve aksiyon butonu gösterir',
      (tester) async {
    final rec = Recommendation(
      ruleKey: 'test.water.v1',
      severity: AlertSeverity.critical,
      target: RecommendationTarget.crop(
        fieldId: 'field-1',
        cropId: 'crop-1',
      ),
      title: 'Bugün 2000 L sula',
      reasonText: 'Toprak nemi düşük.',
      reasonBullets: const ['Toprak nemi %18'],
      actionHint: 'Bugün 2000 L sulama yap.',
      evidence: const [
        RecommendationEvidence(label: 'Toprak nemi', value: '%18'),
      ],
      command: const RecommendationCommand(
        activityType: ActivityType.watering,
        quantity: 2000,
        quantityUnit: 'L',
        recommendedQuantity: 2000,
        buttonLabel: 'Suladım',
      ),
      sourceRefs: const [
        'TAGEM Ayçiçeği Tarımı Teknik Talimatı, 2019',
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: RecommendationCard(recommendation: rec),
          ),
        ),
      ),
    );

    expect(find.text('Bugün 2000 L sula'), findsOneWidget);
    expect(find.text('Suladım'), findsOneWidget);
    // Card kaynak rozetini kısaltır: 'TAGEM ...' → 'Resmi'. Hem TAGEM hem
    // de Trakya/Tarım ve Orman gibi resmi kaynaklar 'Resmi' etiketi alır.
    expect(find.text('Resmi'), findsOneWidget);
    expect(find.text('Neden'), findsOneWidget);
  });

  testWidgets('kilitli tavsiye uygulama butonu yerine kilit mesajı gösterir',
      (tester) async {
    final rec = Recommendation(
      ruleKey: 'test.spray.blocked.v1',
      severity: AlertSeverity.warning,
      target: RecommendationTarget.crop(
        fieldId: 'field-1',
        cropId: 'crop-1',
      ),
      title: 'İlaç kapısı kapalı',
      reasonText: 'Eşik doğrulanmadı.',
      actionHint: 'Önce gözlem yap.',
      gate: RecommendationGate.blocked,
      sourceRefs: const [
        'T.C. Tarım ve Orman Bakanlığı Bitki Koruma Ürünleri Veri Tabanı',
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: RecommendationCard(recommendation: rec),
          ),
        ),
      ),
    );

    expect(find.text('İlaç kapısı kapalı'), findsOneWidget);
    expect(find.textContaining('uygulanamaz'), findsOneWidget);
    expect(find.text('Kaydet'), findsNothing);
  });
}
