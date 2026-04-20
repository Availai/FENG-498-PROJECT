---
name: add-crop
description: Use this skill when the user asks to add a new Turkish plant/crop to the application's seed database — triggers like "seed_plants.json'a X bitkisini ekle", "yeni bitki ekle", "add crop". Fills all 21 required fields, inserts into seed_plants.json, rebuilds the SQLite asset.
---

# add-crop — Yeni Bitki Ekleme

## Amaç
`backend/data_pipeline/seed_plants.json`'a tek veya birden çok bitki ekler, sonra `build_turkish_crops_db.py` çalıştırarak `assets/data/turkish_crops.sqlite`'ı yeniler. Flutter uygulamasının 292+ bitki picker'ına yeni bitki böyle katılır.

## 21 Zorunlu Alan
Her yeni kayıt şu alanları içermelidir:

| Alan | Tip | Örnek |
|---|---|---|
| `name_tr` | string | "Amasya Elması" |
| `aliases` | string[] | ["amasya elma", "misket"] |
| `scientific_name` | string | "Malus domestica 'Amasya'" |
| `category` | enum | "Meyve" |
| `sowing_months` | int[] | [3, 4] |
| `harvest_months` | int[] | [9, 10] |
| `temp_min_c` | number | -15 |
| `temp_max_c` | number | 35 |
| `optimal_temp_c` | number | 20 |
| `water_need` | enum | "medium" |
| `sun_need` | enum | "full" |
| `soil_ph_min` | number | 6.0 |
| `soil_ph_max` | number | 7.0 |
| `soil_type` | string[] | ["tınlı", "killi-tınlı"] |
| `region_suitability` | string[] | ["İç Anadolu", "Karadeniz"] |
| `fertilizer_notes` | string | "Çiçeklenme öncesi NPK 15-15-15..." |
| `common_pests` | string[] | ["Elma içkurdu", "Yaprakbiti"] |
| `common_diseases` | string[] | ["Karaleke", "Monilya"] |
| `growing_tips` | string | "Soğuklama ihtiyacı 800-1000 saat..." |
| `days_to_harvest` | int | 150 |

## Kategori Listesi (Değiştirme!)
`Tahıl`, `Baklagil`, `Yağlı Tohum`, `Endüstri Bitkisi`, `Yem Bitkisi`, `Sebze`, `Meyve`, `Sert Kabuklu`, `Bahçe Otu`, `Tıbbi Bitki`, `Süs Bitkisi`.

## Enum Değerleri
- `water_need`: `low` / `medium` / `high`
- `sun_need`: `full` / `partial` / `shade`
- Aylar: 1-12 (Ocak=1)

## İş Akışı

### 1. Duplicate Kontrolü
`seed_plants.json` oku. `name_tr` veya `aliases` çakışması varsa kullanıcıya bildir ve sor: güncelle mi, iptal mi?

### 2. Eksik Alan Tespit
Kullanıcı sadece "elma ekle" dediyse: sen temel alanları (name_tr, category, aylar, sıcaklık, pH) doldurmaya çalış, BİLMEDİĞİN alanları kullanıcıya tek tek sor (özellikle `region_suitability`, `common_pests`, `common_diseases`). **Uydurma.**

### 3. JSON'a Ekleme
Edit ile `plants` array'inin sonuna ekle. Mevcut stil:
```json
{
  "name_tr": "...",
  "aliases": [...],
  "scientific_name": "...",
  "category": "...",
  "sowing_months": [...],
  "harvest_months": [...],
  "temp_min_c": ...,
  "temp_max_c": ...,
  "optimal_temp_c": ...,
  "water_need": "...",
  "sun_need": "...",
  "soil_ph_min": ...,
  "soil_ph_max": ...,
  "soil_type": [...],
  "region_suitability": [...],
  "fertilizer_notes": "...",
  "common_pests": [...],
  "common_diseases": [...],
  "growing_tips": "...",
  "days_to_harvest": ...
}
```

### 4. Build Script Çalıştır
```bash
cd backend && python data_pipeline/build_turkish_crops_db.py
```
Çıktıda `Seed bitki sayısı: N` ve `[OK] Asset kopyalandi` satırlarını doğrula.

### 5. Rapor
Kullanıcıya:
- Eklenen bitki sayısı
- Yeni toplam (önceki: 292 → yeni: N)
- Asset dosya yolu ve boyutu
- Flutter'ı yeniden başlatma gerektiği hatırlatması (`flutter run`).

## Uyarılar
- `seed_plants.json` UTF-8'dir — Türkçe karakterler direkt yazılır, escape edilmez.
- `aliases` içinde Türkçe aksansız varyasyonlar eklemek aramayı iyileştirir: "Amasya Elması" için `"amasya elma"`.
- `category` değeri Flutter tarafında `_colorForCategory` ile eşleşiyor — yeni kategori UYDURMA, 11 listeden seç.
