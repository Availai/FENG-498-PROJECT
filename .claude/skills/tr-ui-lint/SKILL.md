---
name: tr-ui-lint
description: Use when the user wants to audit Flutter source files for accidental English UI strings. Triggers like "UI metinlerini Türkçe kontrol et", "İngilizce string var mı", "Turkish UI audit". Scans Text(), SnackBar, AlertDialog, Tooltip, hintText, labelText, etc.
---

# tr-ui-lint — Türkçe UI Denetimi

## Amaç
Tarlam'ın "100% Türkçe UI" kuralını otomatik denetler. Flutter widget'larında gözden kaçmış İngilizce string'leri bulur.

## İş Akışı

### 1. Hedef Dosya(lar)
Kullanıcıdan hedef al:
- Tek dosya: `lib/screens/auth_screen.dart`
- Dizin: `lib/screens/`
- Tüm proje: `lib/`

Varsayılan: Kullanıcı `git status` sonrası değiştirilen dosyalar (varsa).

### 2. Şüpheli Pattern'ler (Grep)
Aşağıdaki regex'leri sırayla tara:

```
Text\(\s*['"][A-Z][a-zA-Z ]{3,}['"]
SnackBar\([\s\S]*?content:\s*Text\(\s*['"][A-Z]
AlertDialog\([\s\S]*?title:\s*Text\(\s*['"][A-Z]
(hintText|labelText|helperText):\s*['"][A-Z]
Tooltip\([\s\S]*?message:\s*['"][A-Z]
throw\s+Exception\(\s*['"][A-Z]
```

### 3. False-Positive Filtrele
Şunlar Türkçe sayılır / yok sayılır:
- Tek kelime kısa kodlar: `'OK'`, `'GPS'`, `'pH'`, `'NPK'`, `'UV'`, `'API'`
- URL, asset path: `'assets/...'`, `'https://...'`
- Identifier/key: `'userId'`, `'field_id'`
- Türkçe özel karakter içerenler: ş,ğ,ü,ı,ç,ö,İ,Ş,Ğ

Kalan bulgular gerçek İngilizce ihlal sayılır.

### 4. Rapor Formatı
```
📋 Türkçe UI Denetimi Raporu
────────────────────────────
lib/screens/foo_screen.dart:
  L42: Text('Save') → "Kaydet" ?
  L78: SnackBar(content: Text('Error loading')) → "Yükleme hatası" ?
  L103: hintText: 'Enter name' → "İsim girin" ?

lib/screens/bar_screen.dart:
  ✓ Temiz

Toplam: 3 bulgu / 2 dosya
```

### 5. Otomatik Düzeltme (Opsiyonel)
Kullanıcı "düzelt" derse:
- Her bulgu için Edit ile Türkçe karşılığı yaz.
- Bulgu çok uzunsa (>50 char) veya belirsizse kullanıcıya sor: "X için ne yazalım?"
- Her değişiklikten sonra `flutter analyze` koş, 0 hata doğrula.

## Kaçınılacaklar
- CamelCase identifier'ı ingilizce sanma: `fieldId`, `cropName` — parametre/field adları değiştirilmez.
- Code comment'lerdeki İngilizce — kod yorumu İngilizce kalabilir; sadece UI'da Türkçe zorunlu.
- Debug/log string'leri: `print('Loading')` → UI değil, atlanır (ama üretimde kaldırılmalı; ayrı bir konu).

## Çıktı Beklentisi
Kullanıcının elinde: dosya + satır + öneri listesi. Kullanıcı istediklerini kabul etsin, gerisini reddetsin.
