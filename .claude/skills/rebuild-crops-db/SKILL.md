---
name: rebuild-crops-db
description: Use when the user manually edited seed_plants.json and wants to regenerate assets/data/turkish_crops.sqlite. Triggers like "crops DB'yi rebuild et", "SQLite'ı yenile", "bitki veritabanı güncelle".
---

# rebuild-crops-db — Bitki SQLite'ını Yeniden Üret

## Amaç
`backend/data_pipeline/seed_plants.json` → `assets/data/turkish_crops.sqlite` dönüşümünü tek adımda yapar.

## İş Akışı

### 1. Seed JSON Doğrulaması
```bash
python -c "import json; d=json.load(open('backend/data_pipeline/seed_plants.json',encoding='utf-8')); print('TOTAL:',len(d['plants']))"
```
JSON parse hatası varsa, kullanıcıya satır numarasıyla bildir ve dur.

### 2. Build Script Çalıştır
```bash
cd backend && python data_pipeline/build_turkish_crops_db.py
```

### 3. Çıktıyı Parse Et
Beklenen çıktı örneği:
```
Seed bitki sayısı: 292
[OK] SQLite uretildi  : .../output/turkish_crops.sqlite
[OK] Asset kopyalandi : .../assets/data/turkish_crops.sqlite
```
"Seed bitki sayısı: N" → N'yi yakala.

### 4. Asset Dosyasını Doğrula
```bash
ls -la assets/data/turkish_crops.sqlite
```
Dosya var mı + timestamp güncel mi kontrol et.

### 5. Flutter Uyarısı
SQLite bir Flutter asset'i olduğundan, uygulama çalışırken değişiklik yansımaz. Kullanıcıya söyle:
> "Flutter uygulaması açıksa yeniden başlat (`flutter run`) — asset değişikliği hot reload ile gelmez."

Eğer `build/` klasöründe önceden cache'lenmişse:
```bash
flutter clean && flutter pub get
```
gerekebilir.

## Hata Durumları
- **Python bulunamadı**: `python3` dene, olmazsa kullanıcıya venv activate'i hatırlat.
- **Script çalıştı ama asset kopyalanmadı**: `assets/data/` dizini yoksa oluştur, script'i tekrar çalıştır.
- **Seed JSON parse hatası**: Kullanıcıya hata satır+sütun bilgisiyle rapor et; `seed_plants.json`'ı elle düzeltmesini iste.

## Özet Rapor Formatı
```
✓ Seed parsed: 292 bitki
✓ SQLite generated: backend/data_pipeline/output/turkish_crops.sqlite
✓ Asset copied: assets/data/turkish_crops.sqlite (148 KB)
→ Flutter'ı yeniden başlat.
```
