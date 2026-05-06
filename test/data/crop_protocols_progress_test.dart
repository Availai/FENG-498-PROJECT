import 'package:flutter_test/flutter_test.dart';

import 'package:feng_498/data/activity_types.dart';
import 'package:feng_498/data/crop_protocols.dart';

void main() {
  group('CropProtocols', () {
    test('Turkce ve ASCII adla protokol cozer, bilinmeyende null doner', () {
      expect(CropProtocols.resolveByName('domates'), isNotNull);
      expect(CropProtocols.resolveByName('MISIR'), isNotNull);
      expect(CropProtocols.resolveByName('m\u0131s\u0131r'), isNotNull);
      expect(CropProtocols.resolveByName('bilinmeyen'), isNull);
    });

    test('ProtocolStep beklenen tarih ve aktif pencereyi hesaplar', () {
      final protocol = CropProtocols.resolveByName('domates')!;
      final step = protocol.steps.first;
      final planted = DateTime(2026, 4, 1);

      expect(step.expectedDateFrom(planted),
          planted.add(Duration(days: step.dayOffset)));
      expect(
        step.isActiveOn(
          planted,
          now: planted.add(Duration(days: step.dayOffset)),
        ),
        isTrue,
      );
      expect(
        step.isActiveOn(
          planted,
          now: planted.add(Duration(days: step.dayOffset + 20)),
        ),
        isFalse,
      );
    });

    test('aktivite penceresi icindeki kaydi tamamlandi sayar', () {
      final protocol = CropProtocols.resolveByName('domates')!;
      final step = protocol.steps.firstWhere((s) => s.expectedActivity != null);
      final planted = DateTime(2026, 4, 1);
      final eventDate = planted.add(Duration(days: step.dayOffset + 2));

      final completed = step.isCompletedFor(
        [
          {
            'eventType': step.expectedActivity,
            'eventDate': eventDate.toIso8601String(),
          },
        ],
        planted,
      );
      final wrongType = step.isCompletedFor(
        [
          {
            'eventType': ActivityType.watering,
            'eventDate': eventDate.toIso8601String(),
          },
        ],
        planted,
      );

      expect(completed, isTrue);
      expect(wrongType, isFalse);
    });

    test('activeStep tamamlanmis adimi atlayip siradaki yakin adimi secer', () {
      final protocol = CropProtocols.resolveByName('domates')!;
      final planted = DateTime(2026, 4, 1);
      final firstWithActivity =
          protocol.steps.firstWhere((s) => s.expectedActivity != null);

      final active = protocol.activeStep(
        planted,
        [
          <String, dynamic>{
            'eventType': firstWithActivity.expectedActivity,
            'eventDate': planted
                .add(Duration(days: firstWithActivity.dayOffset + 1))
                .toIso8601String(),
          },
        ],
        now: planted.add(Duration(days: firstWithActivity.dayOffset)),
      );

      expect(active, isNotNull);
      expect(active, isNot(firstWithActivity));
    });
  });
}
