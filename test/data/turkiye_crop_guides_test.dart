import 'package:feng_498/data/turkiye_crop_guides.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TurkiyeCropGuides', () {
    test('Türkçe karakterli ve karaktersiz aliasları çözer', () {
      expect(TurkiyeCropGuides.lookup('ayçiçeği')?.id, 'aycicegi');
      expect(TurkiyeCropGuides.lookup('aycicegi')?.id, 'aycicegi');
      expect(TurkiyeCropGuides.lookup('mısır')?.id, 'misir');
      expect(TurkiyeCropGuides.lookup('misir')?.id, 'misir');
      expect(TurkiyeCropGuides.lookup('domates')?.id, 'domates');
    });

    test('Üç ürün için teknik ölçüler doludur', () {
      for (final name in ['ayçiçeği', 'domates', 'mısır']) {
        final guide = TurkiyeCropGuides.lookup(name);
        expect(guide, isNotNull);
        expect(guide!.technicalMetrics, isNotEmpty);
        expect(guide.rowSpacingCm, greaterThan(0));
        expect(guide.plantSpacingCm, greaterThan(0));
        expect(guide.sowingDepthCm, greaterThan(0));
        expect(guide.sourceRefs, isNotEmpty);
      }
    });

    test('Her ürün büyüme aşaması, bölgesel takvim ve mücadele kaydı taşır', () {
      for (final guide in TurkiyeCropGuides.guides) {
        expect(guide.stages, isNotEmpty, reason: guide.cropName);
        expect(guide.pests, isNotEmpty, reason: guide.cropName);
        expect(guide.regionalCalendar, isNotEmpty, reason: guide.cropName);
        expect(guide.nutritionPlan, isNotEmpty, reason: guide.cropName);
      }
    });
  });
}
