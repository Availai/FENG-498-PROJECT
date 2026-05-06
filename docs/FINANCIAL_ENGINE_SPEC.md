# Tarlam Financial Engine Specification

## 1. Amaç
Bu modül çiftçinin ürün bazında gelir-gider hesabını, dekar başı maliyetini, kg başı maliyetini, net kârını ve başa baş verimini hesaplar.

## 2. Temel Prensipler
- Fiyat uydurma yasaktır.
- Kullanıcı girdisi, resmî kaynak ve tahmini değer ayrı tutulur.
- Her hesap açıklanabilir olmalıdır.
- Her sonuçta kullanılan formül gösterilmelidir.
- Aynı girdi aynı sonucu üretmelidir.
- Güncel fiyatlar tarih damgası ile saklanmalıdır.

## 3. Maliyet Kategorileri
- Arazi hazırlığı
- Tohum/fide
- Gübre
- İlaç
- Sulama
- İşçilik
- Makine
- Mazot
- Elektrik
- Hasat
- Nakliye
- Depolama
- Sigorta
- Kira
- Amortisman
- Finansman
- Diğer giderler

## 4. Gelir Kategorileri
- Ürün satış geliri
- Devlet destekleri
- Yan ürün geliri
- Sigorta tazminatı
- Diğer gelirler

## 5. Ana Formüller
Toplam Gider = Değişken Giderler + Sabit Giderler

Brüt Gelir = Beklenen Verim × Satış Fiyatı

Net Kâr = Brüt Gelir + Destekler - Toplam Gider

Dekar Başı Maliyet = Toplam Gider / Dekar

Kg Başı Maliyet = Toplam Gider / Toplam Üretim Kg

Başa Baş Verim = Toplam Gider / Satış Fiyatı

Kâr Marjı = Net Kâr / Brüt Gelir