# Tarlam — Claude Code Rehberi

## Proje Özeti
Türkiye'nin kırsal bölgelerindeki çiftçilere yönelik **çevrimdışı öncelikli** Flutter + FastAPI tarım yönetim uygulaması. FENG-498 senior projesi. Hedef kitle: düşük bant genişliği, yaşlı kullanıcılar, 100% Türkçe UI. Uygulama adı: **Tarlam**.

## Teknoloji Yığını
| Katman | Araç |
|---|---|
| Frontend | Flutter 3.5+ / Dart 3 |
| State | Riverpod 2.6 |
| Yerel DB | Drift 2.21 (SQLite) |
| Cache | Hive 2.2 |
| Arkaplan Sync | WorkManager |
| Backend | FastAPI + Uvicorn |
| Bulut DB | PostgreSQL + PostGIS |
| Auth | Firebase Auth |
| Bildirim | FCM + flutter_local_notifications |
| Harita | flutter_map (OSM/ArcGIS) |
| API | OpenWeatherMap, Open-Meteo, Agromonitoring, MGM, SoilGrids, Perenual |
| Bitki VT | `assets/data/turkish_crops.sqlite` (**292 Türk bitkisi**) |

## Çalıştırma Komutları
- `flutter pub get && flutter run` — emulator-5554'te debug
- `flutter analyze lib/` — statik kontrol
- `flutter build apk` — prod apk
- `cd backend && python -m uvicorn main:app --reload` — backend dev
- `cd backend && python data_pipeline/build_turkish_crops_db.py` — bitki SQLite'ı yeniden üret
- `dart run build_runner build --delete-conflicting-outputs` — Drift codegen

## Dizin Haritası
```
lib/
├── screens/          # 23 ekran, hepsi Türkçe UI
├── data/
│   ├── app_database.dart              # Drift şeması (Fields, FieldCrops, CalendarEvents, IrrigationPlans, SuitabilityReports, SyncJobs, SyncState)
│   ├── turkish_crops_repository.dart  # SQLite asset repo, 292 bitki, TurkishCrop + scoreFor()
│   └── verified_agri_database.dart    # LEGACY AgriPlant — yeni kod TurkishCrop kullansın
├── services/         # API client'lar, sulama, sync, kural motoru
├── widgets/          # UI kit: ParticleBackground, TapScale, ShimmerBox, AppToast, AnimatedRoute
├── theme/app_theme.dart               # AppColors, AppText, AppGradients, AppRadius, AppShadows
└── main.dart
backend/
├── main.py                            # FastAPI endpoint'leri
├── rule_engine.py                     # Deterministik tarım kuralları (44KB)
└── data_pipeline/
    ├── seed_plants.json               # Bitki veritabanı kaynağı (292 kayıt)
    └── build_turkish_crops_db.py      # JSON → SQLite dönüştürücü
assets/data/turkish_crops.sqlite       # build script çıktısı
```

## Ürün Kuralları
- **UI dili her yerde Türkçe** — SnackBar, AlertDialog, hata mesajları dahil. Tek İngilizce kelime bile yok.
- **Çevrimdışı-öncelikli**: API çağrıları max 10sn timeout, cached fallback zorunlu, indefinite loading yasak.
- **UI kit'e sadık kal**: Hardcoded renk/font koyma; `AppColors.*`, `AppText.*`, `AppRadius.*` kullan.
- **Widget'ları yeniden kullan**: ParticleBackground, TapScale, ShimmerBox, AppToast, AnimatedRoute, HapticService.
- **Per-user isolation**: Fields tablosunda `farmerUid` sütunu (Drift v3). Yeni entity'ler bu kolonu taşımalı.
- **LWW sync**: SyncJobs outbox + SyncState cursor; çatışma çözümü timestamp bazlı.
- **UX**: minimum 13px yazı, 48dp buton, yüksek kontrast (güneş altında okunabilirlik).

## Kod Felsefesi
- **Mevcut çalışan kodu koru.** Bug veya mimari tutarsızlık yoksa dokunma.
- Artımlı değişiklik > büyük refactor.
- `AgriPlant` (legacy, 15 bitki) yerine `TurkishCrop` (292 bitki DB) tercih et — yeni picker'lar oraya bağlı.
- Yeni dosya yalnızca mecbur kalınırsa.
- Sahte API key üretme — `.env` placeholder kullan.

## Hazır Yardımcılar (Yeni Yazma!)
- `TurkishCropsRepository.instance` — singleton, `ensureReady()` + `search(query, limit)` + `byId()`
- `TurkishCrop.scoreFor({temperature, soilPh, weeklyRain, month})` → `SuitabilityScore{score: double, reasons: List<String>}`
- `_envForSuitability()` (field_detail_screen) — analiz sonucundan `(ph, temp, annualRain)` üretir
- `_colorForCategory(String category)` — 11 kategori → Color map (field_detail_screen, field_3d_planner_screen)
- `LocalDataRepository` — Drift CRUD
- `HapticService` — tek nokta haptic feedback

## Güncel Durum (2026-04 itibarıyla)
### Tamamlanan
- ✅ 292 Türk bitkisi SQLite DB (seed_plants.json → build script → asset)
- ✅ `field_3d_planner_screen`: 292-çeşit picker (eski 5 bitkilik dropdown kaldırıldı)
- ✅ `field_detail_screen._showPlantPicker`: `TurkishCrop.scoreFor` ile skorluyor
- ✅ `turkish_crops_search_screen`: `pickerMode` ile Navigator.pop(TurkishCrop) desteği
- ✅ Kimlik doğrulama, tarla kayıt, hava durumu, ürün takvimi, sulama planı, çevrimdışı ansiklopedi (22 bitki), sync altyapısı

### Yarım / İyileştirme Gerek
- ⚠️ Admin panel: HTML iskelet var, backend entegrasyonu kısmi
- ⚠️ İnteraktif tarla-üstü ürün yerleştirme (tap-to-place)
- ⚠️ Tarla 360° panoramik görünüm
- ⚠️ Test coverage: `test/` boş (sadece widget_test.dart placeholder)

### Eksik
- ❌ Gelir/maliyet takibi
- ❌ NPK tabanlı gübreleme takvimi
- ❌ Fotoğraf tabanlı hastalık teşhisi

## Projeye Özel Skill'ler
Tekrarlayan işlerde başvur (`.claude/skills/<name>/SKILL.md`):
- `/add-crop` — seed_plants.json'a yeni bitki ekle + DB rebuild
- `/rebuild-crops-db` — SQLite DB'yi yeniden üret, asset'i doğrula
- `/new-screen` — Tarlam konvansiyonlarıyla yeni Flutter ekran iskeleti
- `/tr-ui-lint` — Verilen dosyada İngilizce UI string'lerini yakala
- `/drift-migration` — Drift tablo/kolon ekle + schema version bump + build_runner
- `/analyze-all` — flutter analyze + dart format + python lint + API key tara

## Referanslar
- Detaylı envanter + öncelik listesi: [AGENTS.md](AGENTS.md)
- Drift şeması detay: [lib/data/app_database.dart](lib/data/app_database.dart)
- Memory (otomatik): `C:\Users\Hp\.claude\projects\c--FENG-498-feng-498\memory\MEMORY.md`
- Dokümantasyon klasörü: [docs/](docs/)
