/// YieldCalculationService — Kural Tabanlı Rekolte & Kâr Tahmini
///
/// Makine öğrenmesi içermez. Tamamen deterministik kurallara dayanır.
/// Dekar başı ideal verim değerleri baz alınır ve üç çarpan uygulanır:
///
///   tahminiRekolte = dekar × idealVerim × (suÇarpanı × sıcaklıkÇarpanı × gübreÇarpanı)
///   tahminiKâr     = (tahminiRekolte × satışFiyatı) − toplamMasraf
///
/// Çarpanlar:
///   • Su       — haftalık ihtiyaçtan her %10 eksiklik için 0.05 düşer (min 0.50).
///   • Sıcaklık — max sıcaklığın aşıldığı her gün için 0.02 düşer  (min 0.50).
///   • Gübre    — verilmediyse 0.80, verildiyse 1.00.
library;

import 'dart:math' as math;

// ─────────────────────────────────────────────────────────────────────────────
// VERİ MODELİ
// ─────────────────────────────────────────────────────────────────────────────

/// Hesaplama sonucunu taşır.
class YieldResult {
  /// Tahmini toplam rekolte (kg).
  final double tahminiRekolte;

  /// Tahmini net kâr (TL). Masraflar düşülmüş haliyle.
  final double tahminiKar;

  /// Uygulanan çarpanların detayları (debug / UI gösterimi için).
  /// Anahtarlar: 'su', 'sicaklik', 'gubre', 'bilesik'.
  final Map<String, double> carpanDetaylari;

  /// Kullanıcıya gösterilecek uyarı metinleri.
  /// Örn: "Su eksikliğinden %15 kayıp".
  final List<String> uyarilar;

  /// Temel ideal verim (kg/dekar) — seçilen bitkiye göre.
  final double idealVerimKgDekar;

  /// Girilen dekar × ideal verim (çarpansız teorik üst sınır).
  final double teorikMaxRekolte;

  const YieldResult({
    required this.tahminiRekolte,
    required this.tahminiKar,
    required this.carpanDetaylari,
    required this.uyarilar,
    required this.idealVerimKgDekar,
    required this.teorikMaxRekolte,
  });

  /// Teorik maksimuma göre başarı oranı (0.0–1.0).
  double get basariOrani =>
      teorikMaxRekolte > 0 ? (tahminiRekolte / teorikMaxRekolte) : 0.0;

  @override
  String toString() {
    return 'YieldResult('
        'rekolte: ${tahminiRekolte.toStringAsFixed(1)} kg, '
        'kar: ${tahminiKar.toStringAsFixed(2)} TL, '
        'carpanlar: $carpanDetaylari, '
        'uyarilar: $uyarilar)';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SERVİS
// ─────────────────────────────────────────────────────────────────────────────

class YieldCalculationService {
  /// Bitki adına göre dekar başı ideal rekolte (kg).
  /// Anahtar normalize edilir (küçük harf, Türkçe karakter dönüşümü).
  /// Genişletmek için [registerCrop] kullanılabilir.
  static final Map<String, double> _idealVerimTablo = {
    // Yağlı tohumlar
    'ayciceği': 300,
    'ayciceg': 300,
    'sunflower': 300,

    // Tahıllar
    'bugday': 450,
    'wheat': 450,
    'arpa': 400,
    'barley': 400,
    'misir': 800,
    'maize': 800,
    'corn': 800,
    'celtik': 750,
    'pirinc': 750,
    'rice': 750,
    'yulaf': 350,

    // Baklagiller
    'nohut': 180,
    'mercimek': 200,
    'fasulye': 250,
    'bezelye': 300,

    // Endüstriyel
    'pamuk': 400,
    'tutun': 150,
    'seker pancari': 5500,
    'seker': 5500,

    // Sebze (yüksek verim)
    'domates': 6000,
    'biber': 3000,
    'patlican': 4000,
    'salatalik': 5000,
    'kabak': 4000,
    'karpuz': 4500,
    'kavun': 3500,

    // Kök & yumru
    'patates': 3500,
    'soğan': 3000,
    'sogan': 3000,
    'sarimsak': 1200,
    'havuc': 4000,
  };

  /// Yeni bir bitki ekle / üzerine yaz. UI seçiciden çağrılabilir.
  static void registerCrop(String ad, double idealVerimKgDekar) {
    _idealVerimTablo[_normalize(ad)] = idealVerimKgDekar;
  }

  /// Bilinen tüm bitki adlarını döndürür.
  static List<String> knownCrops() => _idealVerimTablo.keys.toList();

  // ── Sabitler (Kural Parametreleri) ──────────────────────────────────────

  static const double _suMinCarpan = 0.50;
  static const double _suCezaPer10Pct = 0.05;

  static const double _sicaklikMinCarpan = 0.50;
  static const double _sicaklikCezaPerGun = 0.02;

  static const double _gubreYokCarpan = 0.80;
  static const double _gubreVarCarpan = 1.00;

  // ── Ana Hesap Fonksiyonu ────────────────────────────────────────────────

  /// Rekolte ve kâr tahminini üretir.
  ///
  /// [bitkiTuru]           — örn. "ayçiçeği", "buğday", "domates".
  /// [dekar]               — tarla büyüklüğü (1 dekar = 1000 m²).
  /// [haftalikSuIhtiyaciMm]— bitkinin haftalık ihtiyacı (mm).
  /// [haftalikVerilenSuMm] — sulama + doğal yağış toplamı (mm).
  /// [maksSicaklikLimitC]  — bitkinin tolere ettiği üst sıcaklık (°C).
  /// [asilanGunSayisi]     — [maksSicaklikLimitC]'yi aşan gün sayısı.
  /// [gubreVerildiMi]      — gübre programı uygulandı mı?
  /// [satisFiyatiPerKg]    — pazar satış fiyatı (TL/kg).
  /// [toplamMasrafTl]      — tohum, işçilik, yakıt vb. toplam.
  /// [idealVerimOverride]  — tabloya güvenmek istemiyorsanız manuel değer.
  YieldResult hesapla({
    required String bitkiTuru,
    required double dekar,
    required double haftalikSuIhtiyaciMm,
    required double haftalikVerilenSuMm,
    required double maksSicaklikLimitC,
    required int asilanGunSayisi,
    required bool gubreVerildiMi,
    required double satisFiyatiPerKg,
    required double toplamMasrafTl,
    double? idealVerimOverride,
  }) {
    final uyarilar = <String>[];

    // 1) İDEAL VERİM (kg/dekar)
    final idealVerim = idealVerimOverride ??
        _lookupIdealVerim(bitkiTuru) ??
        _fallbackIdealVerim;

    if (idealVerimOverride == null && _lookupIdealVerim(bitkiTuru) == null) {
      uyarilar.add(
        '"$bitkiTuru" bilinmiyor; varsayılan $_fallbackIdealVerim kg/dekar kullanıldı.',
      );
    }

    // 2) SU ÇARPANI
    final suSonuc = _suCarpaniHesapla(
      ihtiyac: haftalikSuIhtiyaciMm,
      verilen: haftalikVerilenSuMm,
    );
    if (suSonuc.kayipYuzde > 0) {
      uyarilar.add(
        'Su eksikliğinden %${suSonuc.kayipYuzde.toStringAsFixed(0)} kayıp',
      );
    }

    // 3) SICAKLIK ÇARPANI
    final sicaklikSonuc = _sicaklikCarpaniHesapla(
      asilanGun: asilanGunSayisi,
    );
    if (sicaklikSonuc.kayipYuzde > 0) {
      uyarilar.add(
        'Sıcaklık stresinden %${sicaklikSonuc.kayipYuzde.toStringAsFixed(0)} kayıp '
        '(${maksSicaklikLimitC.toStringAsFixed(0)}°C üzerinde $asilanGunSayisi gün)',
      );
    }

    // 4) GÜBRE ÇARPANI
    final gubreC = gubreVerildiMi ? _gubreVarCarpan : _gubreYokCarpan;
    if (!gubreVerildiMi) {
      final kayip = ((1 - _gubreYokCarpan) * 100).toStringAsFixed(0);
      uyarilar.add('Gübre verilmediği için %$kayip kayıp');
    }

    // 5) BİLEŞİK ÇARPAN
    final bilesikC = suSonuc.carpan * sicaklikSonuc.carpan * gubreC;

    // 6) REKOLTE & KÂR
    final teorikMax = dekar * idealVerim;
    final tahminiRekolte = teorikMax * bilesikC;
    final tahminiKar = (tahminiRekolte * satisFiyatiPerKg) - toplamMasrafTl;

    if (tahminiKar < 0) {
      uyarilar.add(
        'Uyarı: Masraflar geliri aşıyor (zarar: '
        '${tahminiKar.abs().toStringAsFixed(2)} TL)',
      );
    }

    return YieldResult(
      tahminiRekolte: tahminiRekolte,
      tahminiKar: tahminiKar,
      carpanDetaylari: {
        'su': suSonuc.carpan,
        'sicaklik': sicaklikSonuc.carpan,
        'gubre': gubreC,
        'bilesik': bilesikC,
      },
      uyarilar: uyarilar,
      idealVerimKgDekar: idealVerim,
      teorikMaxRekolte: teorikMax,
    );
  }

  // ── Yardımcılar ─────────────────────────────────────────────────────────

  static const double _fallbackIdealVerim = 250;

  double? _lookupIdealVerim(String ad) {
    final key = _normalize(ad);
    return _idealVerimTablo[key];
  }

  /// Türkçe karakterleri sadeleştirip küçük harfe çevirir.
  static String _normalize(String s) {
    return s
        .trim()
        .toLowerCase()
        .replaceAll('ç', 'c')
        .replaceAll('ğ', 'g')
        .replaceAll('ı', 'i')
        .replaceAll('ö', 'o')
        .replaceAll('ş', 's')
        .replaceAll('ü', 'u');
  }

  /// Su çarpanı: her %10 eksiklik için 0.05 düşer, min 0.50.
  _CarpanSonuc _suCarpaniHesapla({
    required double ihtiyac,
    required double verilen,
  }) {
    if (ihtiyac <= 0) {
      return const _CarpanSonuc(carpan: 1.0, kayipYuzde: 0);
    }
    if (verilen >= ihtiyac) {
      return const _CarpanSonuc(carpan: 1.0, kayipYuzde: 0);
    }
    final eksiklikYuzde = ((ihtiyac - verilen) / ihtiyac) * 100.0;
    final ceza = (eksiklikYuzde / 10.0) * _suCezaPer10Pct;
    final carpan = math.max(_suMinCarpan, 1.0 - ceza);
    final kayip = (1.0 - carpan) * 100.0;
    return _CarpanSonuc(carpan: carpan, kayipYuzde: kayip);
  }

  /// Sıcaklık çarpanı: her aşıldığı gün için 0.02 düşer, min 0.50.
  _CarpanSonuc _sicaklikCarpaniHesapla({required int asilanGun}) {
    if (asilanGun <= 0) {
      return const _CarpanSonuc(carpan: 1.0, kayipYuzde: 0);
    }
    final ceza = asilanGun * _sicaklikCezaPerGun;
    final carpan = math.max(_sicaklikMinCarpan, 1.0 - ceza);
    final kayip = (1.0 - carpan) * 100.0;
    return _CarpanSonuc(carpan: carpan, kayipYuzde: kayip);
  }
}

/// Dahili — çarpan + kayıp yüzdesini tek sonuçta taşır.
class _CarpanSonuc {
  final double carpan;
  final double kayipYuzde;
  const _CarpanSonuc({required this.carpan, required this.kayipYuzde});
}
