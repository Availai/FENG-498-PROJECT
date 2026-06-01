/// B2 — Çift kural motoru parite testi (CLAUDE.md sec 22, 28).
///
/// Tarlam iki kural motoru taşır:
///   • Dart  : [OfflineRuleEngine] — çevrimdışı fallback
///   • Python : backend/rule_engine.py — kanonik (çevrimiçi)
///
/// CLAUDE.md sec 28 kırmızı çizgisi: "Flutter ve backend rule engine davranışı
/// ayrışacaksa" işlem yapmadan önce belirt. Bu test, ortak kategorilerde
/// (weather/irrigation/disease/pest/soil/season/compatibility/harvest) iki
/// motorun **aynı facts → aynı (category, level, title) imzası** ürettiğini
/// doğrular.
///
/// AKIŞ:
///   1. Python tarafı `test/fixtures/_py_parity_out.json` üretir
///      (backend/tests/test_rule_parity.py — pytest ile çalıştırılır).
///   2. Bu Dart testi aynı fixture'ı Dart motoruyla koşturur ve Python
///      çıktısıyla karşılaştırır.
///
/// BİLİNEN AYRIŞMALAR ([_knownDivergences]):
///   İki motor henüz tam eşit değil. Şu an belgelenmiş farklar allow-list'te.
///   Bu test **yeni** (belgelenmemiş) ayrışmaları yakalar — yani biri bir
///   motora kural ekleyip diğerini unutursa kırmızı verir. Bilinen farklar
///   kapandıkça allow-list'ten silinmelidir (hedef: liste boş).
///
/// Python çıktısı yoksa test atlanır (CI'da pytest önce koşmalıdır).
library;

import 'dart:convert';
import 'dart:io';

import 'package:feng_498/services/offline_rule_engine.dart';
import 'package:flutter_test/flutter_test.dart';

/// Henüz kapatılmamış, bilinen motor farkları. Her giriş:
///   `case_id::category|level|title`
/// Değer: hangi motorda var ('python' = Dart eksik, 'dart' = Python eksik).
///
/// Bu liste boşaldığında iki motor tam paritededir.
const Map<String, String> _knownDivergences = {
  // Python `_harvest_rules` her domates/tahılda "Hasat Kalite İpucu" üretir;
  // Dart `_harvestRules` daha dardır → Dart eksik.
  'don::harvest|info|Hasat Kalite İpucu — Domates': 'python',
  'mildiyo::harvest|info|Hasat Kalite İpucu — Domates': 'python',
  'yagmur_yakin::harvest|info|Hasat Kalite İpucu — Domates': 'python',
  'ideal::harvest|info|Hasat Kalite İpucu — Domates': 'python',
  'asit_toprak::harvest|info|Hasat Nem Oranı — Tahıl': 'python',
  // Python'da olan, Dart'ta bulunmayan ek hastalık kuralları.
  'asiri_yagis::disease|warning|Yağış Sonrası Patojen Baskısı': 'python',
  'mildiyo::disease|warning|Toprak Kaynaklı Patojen Riski': 'python',
  // `precip_prob_next3h` birim uyuşmazlığı: Python 0-1 bekler, Dart 0-100.
  // Python 80'i "aralık dışı" sayıp clamp'ler → "Veri Kalitesi Düşük" rozeti
  // çıkar ve "Yağmur Geliyor" kuralını kaçırır. Dart 0-100 ile doğru üretir.
  // NOT: Bu gerçek bir birim hatası; rapora ayrı bulgu olarak işlendi.
  'yagmur_yakin::weather|info|Veri Kalitesi Düşük': 'python',
  'yagmur_yakin::weather|warning|Sulama Yapma — Yağmur Geliyor': 'dart',
};

const Set<String> _sharedCategories = {
  'weather',
  'irrigation',
  'disease',
  'pest',
  'soil',
  'season',
  'compatibility',
  'harvest',
};

void main() {
  final fixtureFile = File('test/fixtures/rule_parity_cases.json');
  final pyOutFile = File('test/fixtures/_py_parity_out.json');

  group('Çift kural motoru paritesi (B2)', () {
    test('fixture ve Python çıktısı mevcut', () {
      expect(fixtureFile.existsSync(), isTrue,
          reason: 'Parite fixture dosyası bulunamadı.');
    }, skip: !fixtureFile.existsSync());

    if (!pyOutFile.existsSync()) {
      test('Python parite çıktısı', () {},
          skip: 'Önce backend pytest koşmalı.');
      return;
    }

    final fx =
        jsonDecode(fixtureFile.readAsStringSync()) as Map<String, dynamic>;
    final py = jsonDecode(pyOutFile.readAsStringSync()) as Map<String, dynamic>;
    final cases = (fx['cases'] as List).cast<Map<String, dynamic>>();

    for (final c in cases) {
      final id = c['id'] as String;
      test('vaka: $id — beklenmedik ayrışma yok', () {
        final dart = _dartSignatures(
          (c['facts'] as Map).cast<String, dynamic>(),
        );
        final pySet = ((py[id] as List?) ?? const []).cast<String>().toSet();

        final onlyPython = pySet.difference(dart);
        final onlyDart = dart.difference(pySet);

        final unexpected = <String>[];
        for (final s in onlyPython) {
          if (_knownDivergences['$id::$s'] != 'python') {
            unexpected.add('[Python\'da var, Dart\'ta yok] $s');
          }
        }
        for (final s in onlyDart) {
          if (_knownDivergences['$id::$s'] != 'dart') {
            unexpected.add('[Dart\'ta var, Python\'da yok] $s');
          }
        }

        expect(
          unexpected,
          isEmpty,
          reason: 'Yeni motor ayrışması bulundu ($id). İki motoru hizalayın '
              'veya bilerek farklıysa _knownDivergences listesine ekleyin:\n'
              '${unexpected.join('\n')}',
        );
      });
    }

    test('_knownDivergences allow-list bayatlamadı', () {
      // Allow-list'teki bir giriş artık gerçekten ayrışmıyorsa (yani fark
      // kapandıysa) liste güncellenmeli — ölü allow-list determinizmi gizler.
      final stillDiverging = <String>{};
      for (final c in cases) {
        final id = c['id'] as String;
        final dart = _dartSignatures(
          (c['facts'] as Map).cast<String, dynamic>(),
        );
        final pySet = ((py[id] as List?) ?? const []).cast<String>().toSet();
        for (final s in pySet.difference(dart)) {
          stillDiverging.add('$id::$s');
        }
        for (final s in dart.difference(pySet)) {
          stillDiverging.add('$id::$s');
        }
      }
      final stale =
          _knownDivergences.keys.where((k) => !stillDiverging.contains(k));
      expect(stale, isEmpty,
          reason: 'Bu farklar artık yok — _knownDivergences\'tan silin:\n'
              '${stale.join('\n')}');
    });
  });
}

/// Verilen facts ile Dart motorunu çalıştırıp ortak-kategori imzalarını döner.
Set<String> _dartSignatures(Map<String, dynamic> f) {
  num n(String k, num d) => (f[k] as num?) ?? d;
  final res = OfflineRuleEngine.analyze(
    commonName: (f['common_name'] as String?) ?? '',
    scientificName: (f['scientific_name'] as String?) ?? '',
    temperature: n('temperature', 20).toDouble(),
    avgWeeklyTemp: n('avg_weekly_temp', 20).toDouble(),
    humidity: n('humidity', 60).toDouble(),
    weeklyRain: n('weekly_rain', 15).toDouble(),
    soilPh: n('soil_ph', 6.8).toDouble(),
    soilMoisture: n('soil_moisture', 0.25).toDouble(),
    soilTempC: n('soil_temp_c', 15).toDouble(),
    ndvi: n('ndvi', 0.6).toDouble(),
    windSpeed: n('wind_speed', 3).toDouble(),
    month: n('month', 6).toInt(),
    precipProbNext3h: n('precip_prob_next3h', 0).toDouble(),
  );
  return res
      .where((r) => _sharedCategories.contains(r.category.name))
      .map((r) => '${r.category.name}|${r.level.name}|${r.title}')
      .toSet();
}
