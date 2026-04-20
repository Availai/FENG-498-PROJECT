---
name: analyze-all
description: Use for a pre-commit full-project audit combining flutter analyze, dart format check, Python linting, TODO count, and hardcoded API key scan. Triggers like "commit öncesi kontrol", "analyze yap", "projeyi denetle", "audit".
---

# analyze-all — Tam Proje Denetimi

## Amaç
Commit/PR öncesinde tek komutla projenin sağlığını doğrular. 5 paralel kontrol + tek özet rapor.

## Kontroller

### 1. Flutter Statik Analiz
```bash
flutter analyze lib/
```
Beklenen: `No issues found!`

### 2. Dart Format
```bash
dart format --set-exit-if-changed lib/
```
Beklenen: exit 0 (değişiklik yok). Eğer çıktı varsa formatlanması gereken dosyaları listele.

### 3. Python Lint (Backend)
```bash
cd backend && python -m pyflakes main.py rule_engine.py data_pipeline/build_turkish_crops_db.py
```
pyflakes kuruluysa çalışır; yoksa kullanıcıya `pip install pyflakes` öner ve bu adımı atla.

### 4. TODO / FIXME Sayımı
```bash
grep -rn "TODO\|FIXME\|XXX" lib/ backend/ --include="*.dart" --include="*.py" | wc -l
```
Sayıyı rapor et; >20 ise kullanıcıyı "birikmiş teknik borç" diye uyar.

### 5. Hardcoded API Key Taraması
```bash
grep -rnE "(sk-[a-zA-Z0-9]{20,}|AIza[a-zA-Z0-9_-]{30,}|eyJ[a-zA-Z0-9_-]{20,}\.eyJ)" lib/ backend/ --include="*.dart" --include="*.py"
```
Beklenen: 0 eşleşme. Eşleşme varsa derhal kullanıcıya bildir — `.env` taşınması gerekiyor.

## İş Akışı
1. 5 kontrolü PARALEL çalıştır (tek mesajda çoklu Bash tool call).
2. Her biri bitince özet rapor üret:

```
📊 Tarlam — Pre-Commit Audit
─────────────────────────────
[1] Flutter analyze    : ✓ No issues
[2] Dart format        : ⚠ 2 file(s) need formatting
      → lib/screens/foo.dart
      → lib/services/bar.dart
[3] Python lint        : ✓ Clean
[4] TODO/FIXME count   : 12 (ok)
[5] API key scan       : ✓ No hardcoded keys

Genel durum: ⚠ 1 uyarı — commit öncesi formatlamayı koş:
  dart format lib/screens/foo.dart lib/services/bar.dart
```

3. Tüm kontroller temizse:
```
✅ Temiz — commit edilmeye hazır.
```

## Uyarılar
- Hatalar varsa **düzeltme ÖNERME, rapor et**; kullanıcı hangilerini düzelteceğine karar versin.
- Backend venv aktif değilse pyflakes bulunamaz — pragmatik olarak atla, kullanıcıyı bilgilendir.
- `flutter analyze` Dart sürümü sorunuyla bazen yanlış alarm verir; kullanıcıya `flutter doctor` hatırlat.

## Sık Soru: format otomatik düzeltilsin mi?
Kullanıcı "düzelt" derse:
```bash
dart format lib/
```
çalıştır. Aksi halde kesinlikle otomatik yazma yapma — commit öncesi denetimde kullanıcı diff'i kendisi görmek ister.
