# Rule Engine Audit — 2026-04-20

`backend/rule_engine.py` çiftçilere koşulsuz güven vaadi veren tavsiye motoru.
Bu doküman her eşiğin **kaynak atıfını**, bilinen kısıtları ve test kapsamını
özetler. Yeni kural eklendiğinde veya eşik güncellendiğinde bu dosya da
güncellenmelidir.

## Mimari Özet

- `analyze(req)` giriş: `AnalyzeRequest` (sıcaklık, nem, pH, NDVI, coğrafya…)
- Giriş önce `_validate_env` ile doğrulanır — NaN/Inf/aralık dışı değerler
  varsayılana çekilir ve `issues` listesine yazılır.
- Çok sayıda eksik girdi → motor "Veri Kalitesi Düşük" RuleResult döner ve
  downstream kurallara `confidence=medium|low` alanı yayılır.
- Kural blokları sırayla çalışır ve sonuçlar ciddiyete göre sıralanır
  (`critical → warning → info → ok`).

## Eşik Kaynakları (ana tablo)

| Kural Bloğu | Eşik | Kaynak |
|---|---|---|
| Don (weather) | `temp ≤ 0°C` kritik; `≤ 3°C` uyarı | MGM Zirai Don Erken Uyarı Sistemi |
| MGM don (frost) | `min ≤ 0`: don olayı; `0 < min ≤ 2`: risk | MGM Zirai Don Tahmin Haritası |
| Mildiyö (patates/domates) | `RH > 85 %` + `10 ≤ temp ≤ 20` | EPPO PP1/2 (Phytophthora infestans) |
| Botrytis/Alternaria (domates) | `RH > 80 %` + `20 ≤ temp ≤ 25` | EPPO PP1/152 |
| Genel mantar (tüm) | `RH > 85 %` + `18 ≤ temp ≤ 28` | Agrios "Plant Pathology" 5e (2005) §11.3 |
| Pas (buğday) | `RH > 75 %` + `15 ≤ temp ≤ 25` | EPPO PP1/26 (Puccinia striiformis) |
| Kök çürüklüğü | `soil_moisture > 0.45` + `temp > 20` | EPPO PP1/119 |
| Yağış-sonrası patojen | `weekly_rain > 40 mm` + `RH > 80 %` | Tarım Orman Bakanlığı Zirai Mücadele Teknik Talimatları (2019-2023) |
| Diurnal stres | `|max − min| ≥ 15°C` (hassas) / `≥ 25°C` (genel) | Allen et al. FAO-56 (1998) §3.3 |
| Coğrafya / iç Anadolu | 38-41°N × 30-36°E | MGM bölgesel iklim atlası 1991-2020 |
| Giriş sınırları | Sıcaklık −40..+55, pH 3..10, RH 0..100 | MGM iklim normalleri 1991-2020 |

## EPPO Kodu Dizini
`rule_engine.py` dosyasının tepesindeki `EPPO_CODES` sözlüğü AB tarımsal
mevzuatında resmi olan Bayer kodlarıyla birebir eşleşir. Kaynak:
https://gd.eppo.int

## Test Kapsamı

`backend/tests/test_rule_engine.py`:

- ✅ 9 giriş doğrulama testi (NaN, Inf, negatif, aralık dışı)
- ✅ 3 veri-kalitesi rozeti testi
- ✅ 3 don kuralı testi (kritik, güvenli, ilkbahar geç donu)
- ✅ 3 hastalık testi (mildiyö, genel fungal, buğday pası)
- ✅ 3 regresyon koruması (boş istek, şiddet sıralama, tüm alan dolu)

Çalıştırma:
```bash
cd backend
pip install -r requirements-dev.txt
pytest tests/test_rule_engine.py -v
```

## Bilinen Kısıtlar

1. **Bölge detayı zayıf** — sadece `_is_central_anatolia()` özelleşmiş. Akdeniz,
   Ege, Marmara, Karadeniz, Doğu/Güneydoğu Anadolu için generic kurallar
   kullanılıyor. Gelecek sprint: 7 coğrafi bölge için ayrı kalibrasyon.
2. **NDVI eşikleri** — `_irrigation_rules` içinde literatür atıfı yok. Kaynak
   eklenmeli (Tucker 1979 veya MODIS MOD13 rehberi).
3. **ÇKS/münavebe** — `_crop_rotation_rules` yerel bilgiyle sınırlı; TZOB
   teknik kılavuzlarıyla çapraz doğrulama gerekli.
4. **`confidence` UI tarafı** — backend her RuleResult'ta döndürür ama Flutter
   UI şimdilik sadece "Veri Kalitesi Düşük" başlığında açıkça gösteriyor.
   Her kart için rozet gelecek iş.
5. **Sensör kalibrasyonu** — motor sensör arızasını tespit edebilir (NaN/aralık
   dışı), ama "bias" (ör. +2°C sabit hata) tespit edemez. Saha karşılaştırması
   gelecek iş.

## Değişiklik Günlüğü

- **2026-04-20** — İlk audit pass:
  - `_validate_env` + 22 fiziksel sınır eklendi.
  - `RuleResult.confidence` alanı eklendi (default `high`).
  - "Veri Kalitesi Düşük" RuleResult üretimi.
  - 21 pytest testi + `requirements-dev.txt`.
  - Dart tarafında `TurkishCrop.scoreFor` NaN/Inf guard + confidence field.
  - Genel fungal ve yağış-sonrası patojen kurallarına kaynak atfı eklendi.
