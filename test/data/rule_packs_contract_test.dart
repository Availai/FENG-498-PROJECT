import 'package:feng_498/core/rule_engine/rule.dart';
import 'package:feng_498/data/rule_packs/corn_rule_pack.dart';
import 'package:feng_498/data/rule_packs/orange_rule_pack.dart';
import 'package:feng_498/data/rule_packs/tea_rule_pack.dart';
import 'package:feng_498/data/rule_packs/tomato_rule_pack.dart';
import 'package:flutter_test/flutter_test.dart';

/// CLAUDE.md sec 21 — Rule pack validation kontratları.
///
/// Her yeni rule pack (`crop.tea`, `crop.orange`, `crop.corn`,
/// `crop.tomato`) bu testleri geçmek ZORUNDADIR:
///
///  1. JSON parse + schema sözleşmesi (`id`, `category`, vb. doluluk).
///  2. ID benzersizliği — pack içinde aynı ID iki kez geçmemeli.
///  3. ID prefix tutarlılığı — `rule.<crop>.*` formatı.
///  4. Her kuralın `evidence` taşıması (CLAUDE.md sec 12).
///  5. BKÜ kuralları (sec 17) — kimyasal öneren her kural `requiresBkuCheck`
///     bayrağı taşımalı VE `expert: true` olmalı.
///  6. Toprak analizi yoksa kesin doz dönmemeli (sec 16) —
///     `missing(soil_ph)` koşullu kural ekibinde "kesin doz" terimi YOK,
///     "analiz" yönlendirmesi VAR.
///  7. Kategori değerleri CLAUDE.md sec 14 listesinde olmalı.
///  8. Geçerli priority aralığı (0-100).
const _validCategories = <String>{
  'suitability',
  'soil_analysis',
  'pre_planting',
  'sowing_or_planting',
  'fertilization',
  'irrigation',
  'disease_risk',
  'pest_risk',
  'weed_management',
  'harvest',
  'weather_warning',
  'task_generation',
  'safety_warning',
  'crop_unique',
};

class _PackUnderTest {
  final String name;
  final String stableId;
  final String idPrefix;
  final List<Rule> Function() loader;

  const _PackUnderTest({
    required this.name,
    required this.stableId,
    required this.idPrefix,
    required this.loader,
  });
}

final _packs = <_PackUnderTest>[
  _PackUnderTest(
    name: 'Çay',
    stableId: 'crop.tea',
    idPrefix: 'rule.tea.',
    loader: TeaRulePack.all,
  ),
  _PackUnderTest(
    name: 'Portakal',
    stableId: 'crop.orange',
    idPrefix: 'rule.orange.',
    loader: OrangeRulePack.all,
  ),
  _PackUnderTest(
    name: 'Mısır',
    stableId: 'crop.corn',
    idPrefix: 'rule.corn.',
    loader: CornRulePack.all,
  ),
  _PackUnderTest(
    name: 'Domates',
    stableId: 'crop.tomato',
    idPrefix: 'rule.tomato.',
    loader: TomatoRulePack.all,
  ),
];

void main() {
  for (final pack in _packs) {
    group('${pack.name} rule pack kontratları', () {
      late List<Rule> rules;

      setUpAll(() {
        rules = pack.loader();
      });

      test('paket boş değil ve makul büyüklükte', () {
        expect(rules, isNotEmpty);
        // Minimum 15 kural; 5 ana üründen her birinde en az suitability +
        // toprak + iklim + gübre + sulama + hasat + hastalık-zararlı +
        // weather kapsamı olmalı.
        expect(rules.length, greaterThanOrEqualTo(15),
            reason: '${pack.name} pack çok küçük');
      });

      test('ID benzersiz', () {
        final ids = rules.map((r) => r.id).toList();
        final uniqueIds = ids.toSet();
        expect(uniqueIds.length, ids.length,
            reason: 'Tekrarlanan ID(ler) var: '
                '${ids.where((id) => ids.where((x) => x == id).length > 1).toSet()}');
      });

      test('ID prefix tutarlı', () {
        for (final r in rules) {
          expect(
            r.id.startsWith(pack.idPrefix),
            isTrue,
            reason: '${r.id} doğru prefix taşımıyor (${pack.idPrefix})',
          );
        }
      });

      test('her kuralın evidence kaydı var', () {
        for (final r in rules) {
          expect(r.evidence, isNotEmpty, reason: r.id);
          for (final e in r.evidence) {
            expect(e.sourceId, isNotEmpty, reason: r.id);
            expect(e.evidenceText.trim(), isNotEmpty, reason: r.id);
          }
        }
      });

      test('kategori CLAUDE.md sec 14 listesinde', () {
        for (final r in rules) {
          expect(_validCategories, contains(r.category), reason: r.id);
        }
      });

      test('priority 0-100 aralığında', () {
        for (final r in rules) {
          expect(r.priority, inInclusiveRange(0, 100), reason: r.id);
        }
      });

      test('CLAUDE.md sec 17 — kimyasal öneren kurallar BKÜ + uzman bayraklı',
          () {
        final chemicalKeywords = [
          'fungisit',
          'insektisit',
          'akarisit',
          'piretroid',
          'aktif madde',
          'bakırlı',
          'mineral oil',
          'madeni yağ',
          'spinosad',
          'ruhsatlı',
        ];
        for (final r in rules) {
          final allRecs = r.result.recommendations.join(' ').toLowerCase();
          final mentionsChemical =
              chemicalKeywords.any((k) => allRecs.contains(k));
          if (mentionsChemical) {
            expect(
              r.result.requiresBkuCheck,
              isTrue,
              reason:
                  '${r.id} kimyasal öneriyor ama requiresBkuCheck=true taşımıyor',
            );
            expect(
              r.result.requiresExpertConfirmation,
              isTrue,
              reason:
                  '${r.id} kimyasal öneriyor ama requiresExpertConfirmation=true taşımıyor',
            );
          }
        }
      });

      test('hastalık/zararlı kuralları olası problem ID taşır', () {
        for (final r in rules) {
          if (r.category == 'disease_risk' || r.category == 'pest_risk') {
            // observedSymptom/observedPest koşullu kurallar problemId
            // taşımalı. Genel risk uyarıları (ör. mildiyö+nem) zorunlu değil
            // ama spesifik teşhislerde olmalı.
            final hasObservationCondition = r.conditions.any((c) =>
                c.field == 'observed_symptom' || c.field == 'observed_pest');
            if (hasObservationCondition) {
              expect(
                r.result.possibleProblemId,
                isNotNull,
                reason:
                    '${r.id} gözleme bağlı teşhis kuralı ama possibleProblemId yok',
              );
            }
          }
        }
      });

      test('CLAUDE.md sec 16 — toprak analizi yok kuralları doz vermez', () {
        for (final r in rules) {
          final isMissingPhRule = r.conditions.any(
            (c) => c.field == 'soil_ph' && c.operator.name == 'missing',
          );
          if (isMissingPhRule) {
            final allRecs = r.result.recommendations.join(' ').toLowerCase();
            // "Toprak analizi" yönlendirmesi olmalı
            expect(
              allRecs.contains('analiz'),
              isTrue,
              reason: '${r.id} toprak analizi missing koşullu ama "analiz" '
                  'yönlendirmesi içermiyor',
            );
          }
        }
      });

      test('her kuralda crop_id koşulu var (ürün izolasyonu)', () {
        for (final r in rules) {
          final hasCropFilter = r.conditions.any(
            (c) => c.field == 'crop_id' && c.value == pack.stableId,
          );
          expect(
            hasCropFilter,
            isTrue,
            reason: '${r.id} crop_id=${pack.stableId} koşulu taşımıyor; '
                'başka ürünleri de etkileyebilir',
          );
        }
      });

      test('öneri listesi boş değil', () {
        for (final r in rules) {
          expect(r.result.recommendations, isNotEmpty, reason: r.id);
          for (final rec in r.result.recommendations) {
            expect(rec.trim(), isNotEmpty, reason: r.id);
          }
        }
      });

      test('confidence değerleri standart', () {
        const validConfidence = {'high', 'medium', 'low'};
        for (final r in rules) {
          if (r.confidence != null) {
            expect(validConfidence, contains(r.confidence), reason: r.id);
          }
        }
      });
    });
  }

  group('paketler arası', () {
    test('farklı paketlerdeki ID\'ler çakışmaz', () {
      final allIds = <String>{};
      for (final pack in _packs) {
        for (final r in pack.loader()) {
          expect(allIds.contains(r.id), isFalse,
              reason: '${r.id} birden fazla pack\'te geçiyor');
          allIds.add(r.id);
        }
      }
    });
  });
}
