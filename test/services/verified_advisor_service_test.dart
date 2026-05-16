import 'package:feng_498/models/advisor_models.dart';
import 'package:feng_498/services/verified_advisor_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final service = const VerifiedAdvisorService(loadRepository: false);

  test('serbest metinden urun, niyet ve belirti baglami cikarir', () async {
    final answer = await service.answer(
      const AdvisorQuery(text: 'Domateste yaprak lekesi var ne yapmalıyım?'),
    );

    expect(answer.intent, AdvisorIntent.disease);
    expect(answer.cropName, 'Domates');
    expect(answer.hasVerifiedSources, isTrue);
    expect(answer.understoodSignals.join(' '), contains('Yaprak lekesi'));
    expect(answer.sections.any((s) => s.title == 'Ne yapmalı'), isTrue);
  });

  test('kaynakli kayit varsa guvenilir kaynak listesi tasir', () async {
    final answer = await service.answer(
      const AdvisorQuery(text: 'Mısırı sulayayım mı?'),
    );

    expect(answer.intent, AdvisorIntent.irrigation);
    expect(answer.cropName, 'Mısır');
    expect(answer.hasVerifiedSources, isTrue);
    expect(answer.sources, isNotEmpty);
    expect(answer.sources.any((source) => source.isTrusted), isTrue);
  });

  test('kaynak yoksa tahmin uretmez', () async {
    final answer = await service.answer(
      const AdvisorQuery(text: 'Şeftalide hangi ilaç kullanılır?'),
    );

    expect(answer.confidence, AdvisorConfidence.noVerifiedSource);
    expect(answer.hasVerifiedSources, isFalse);
    expect(answer.shortAnswer, contains('doğrulanmış Türkiye kaynaklı kayıt'));
  });

  test('uygulama kullanimi sorusunda ekran yolu dondurur', () async {
    final answer = await service.answer(
      const AdvisorQuery(text: 'Yeni tarla nasıl çizerim?'),
    );

    expect(answer.confidence, AdvisorConfidence.limited);
    expect(answer.hasVerifiedSources, isTrue);
    expect(answer.shortAnswer, contains('Tarlalarım > Yeni Tarla Çiz'));
    expect(
      answer.sections.expand((s) => s.bullets).join(' '),
      contains('Haritada tarla köşelerini işaretleyip'),
    );
  });

  test('uygulamadaki kayitli tarla ozetini cevaplar', () async {
    final answer = await service.answer(
      const AdvisorQuery(
        text: 'Kaç tarlam var, hangi ürünler kayıtlı?',
        appContext: AdvisorAppContext(
          fields: [
            AdvisorFieldSummary(
              fieldId: 'field-1',
              fieldName: 'Kuzey Tarla',
              cropName: 'Domates',
              areaDekar: 2.5,
            ),
            AdvisorFieldSummary(
              fieldId: 'field-2',
              fieldName: 'Güney Tarla',
              cropName: 'Mısır',
              areaDekar: 4,
            ),
          ],
        ),
      ),
    );

    expect(answer.confidence, AdvisorConfidence.limited);
    expect(answer.shortAnswer, contains('2 kayıtlı tarla'));
    expect(answer.shortAnswer, contains('6.50 dekar'));
    expect(
      answer.sections.expand((s) => s.bullets).join(' '),
      allOf(contains('Kuzey Tarla'), contains('Domates'), contains('Mısır')),
    );
  });

  test('secilen tarla kaynakli canli tavsiyeyi onceliklendirir', () async {
    final answer = await service.answer(
      const AdvisorQuery(
        text: 'Bu hafta sulama gerekir mi?',
        fieldContext: AdvisorFieldContext(
          fieldId: 'field-1',
          fieldName: 'Kuzey Tarla',
          cropNames: ['Mısır'],
          recommendations: [
            AdvisorFieldRecommendation(
              title: 'Bugün 1200 L sula',
              reasonText: 'Haftalık su açığı var.',
              actionHint: 'Bugün serin saatte 1200 L sulama yap.',
              activityType: 'watering',
              sourceRefs: [
                'TAGEM Mısır Entegre Mücadele Teknik Talimatı',
              ],
            ),
          ],
        ),
      ),
    );

    expect(answer.hasVerifiedSources, isTrue);
    expect(
        answer.shortAnswer, contains('seçili tarladaki kaynaklı kayıtlarla'));
    expect(
      answer.sections.expand((s) => s.bullets).join(' '),
      contains('1200 L sulama'),
    );
  });

  test('kimyasal marka, aktif madde ve analizsiz doz donmez', () async {
    final answer = await service.answer(
      const AdvisorQuery(text: 'Domateste yaprak lekesi var hangi ilaç?'),
    );

    final text = [
      answer.shortAnswer,
      for (final section in answer.sections) ...section.bullets,
    ].join('\n').toLowerCase();

    const banned = [
      'fungisit',
      'insektisit',
      'akarisit',
      'mancozeb',
      'metalaksil',
      'spinosad',
      'triazol',
      'kg/da',
      'ml/da',
    ];
    expect(banned.where(text.contains), isEmpty);
    expect(text, contains('bkü'));
    expect(text, contains('uzman'));
  });
}
