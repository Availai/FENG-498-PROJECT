# Tarlam — Claude Code Rehberi

Bu dosya Claude Code'un Tarlam projesinde nasıl davranacağını tanımlar. Amaç, projeyi hızlıca değiştirmek değil; **mevcut çalışan yapıyı koruyarak**, Türkiye tarımı için **çevrimdışı-öncelikli, açıklanabilir ve deterministik** bir karar destek sistemi geliştirmektir.

---

## 0. Claude Code Rolü

Claude Code bu projede şu rolleri üstlenir:

1. Mevcut kodu dikkatlice analiz eder.
2. Küçük, güvenli ve test edilebilir değişiklikler yapar.
3. Türkçe UI kuralına kesin uyar.
4. Tarımsal bilgiyi serbest metin olarak değil, **kaynak kanıtlı JSON + deterministik kural** olarak işler.
5. İlaç, gübre, hastalık teşhisi gibi riskli alanlarda asla tahmin üretmez.
6. Kaynakta olmayan bilgiyi uydurmaz; `null`, `unknown` veya `missing_information` olarak işaretler.
7. Her kararın “neden verildiğini” kullanıcıya açıklanabilir hale getirir.

Claude Code'un yapmaması gerekenler:

- Büyük refactor başlatma.
- Çalışan kodu gereksiz değiştirme.
- Sahte API key, sahte veri veya uydurma kaynak üretme.
- Bitki koruma ürünü için doğrudan “şu ilacı şu dozda kullan” tavsiyesi verme.
- Resmî kaynakta geçmeyen pH, doz, tarih, hastalık, aktif madde veya bölge bilgisini tamamlamaya çalışma.
- UI içinde İngilizce metin bırakma.

---

## 1. Proje Özeti

**Tarlam**, Türkiye'nin kırsal bölgelerindeki çiftçilere yönelik **çevrimdışı öncelikli** Flutter + FastAPI tarım yönetim uygulamasıdır. FENG-498 senior projesidir.

Hedef kullanıcı:

- Düşük bant genişliğine sahip bölgelerdeki çiftçiler
- Yaşlı veya teknolojiye çok hâkim olmayan kullanıcılar
- Güneş altında, sahada, mobil cihazdan işlem yapan kullanıcılar
- Türkçe arayüz bekleyen kullanıcılar

Ana hedef:

> Kullanıcıdan tarla/bahçe, ürün, bölge, toprak analizi, hava durumu ve gözlem verisi alıp; resmî kaynaklara dayanan deterministik kurallarla açıklanabilir görev, risk ve öneri üretmek.

Uygulama adı: **Tarlam**

---

## 2. Teknoloji Yığını

| Katman | Araç |
|---|---|
| Frontend | Flutter / Dart |
| State Management | Riverpod 2.x |
| Yerel DB | Drift 2.x / SQLite |
| Cache | Hive 2.x |
| Arka Plan İşleri | WorkManager |
| Backend | FastAPI + Uvicorn |
| Bulut DB | PostgreSQL + PostGIS |
| Auth | Firebase Auth |
| Bildirim | FCM + flutter_local_notifications |
| Harita | flutter_map / OpenStreetMap / ArcGIS katmanları |
| Harici API | OpenWeatherMap, Open-Meteo, AgroMonitoring, MGM, SoilGrids, Perenual |
| Bitki Veritabanı | `assets/data/turkish_crops.sqlite` |

Notlar:

- Flutter/Dart sürümünü `pubspec.yaml`, lock dosyası ve mevcut proje yapılandırmasına göre takip et.
- Yeni paket eklemeden önce mevcut kodda benzer yardımcı sınıf veya servis var mı kontrol et.
- Gereksiz dependency ekleme.

---

## 3. Çalıştırma Komutları

```bash
flutter pub get
flutter run
flutter analyze lib/
flutter build apk

dart run build_runner build --delete-conflicting-outputs

cd backend
python -m uvicorn main:app --reload
python data_pipeline/build_turkish_crops_db.py
```

Değişiklikten sonra mümkünse şu kontrolleri çalıştır:

```bash
flutter analyze lib/
dart format lib/ test/
```

Drift şeması değiştiyse:

```bash
dart run build_runner build --delete-conflicting-outputs
```

Backend değiştiyse:

```bash
python -m py_compile backend/main.py
python -m py_compile backend/rule_engine.py
```

---

## 4. Dizin Haritası

```text
lib/
├── screens/          # Türkçe UI ekranları
├── data/
│   ├── app_database.dart              # Drift şeması
│   ├── turkish_crops_repository.dart  # SQLite asset repo, TurkishCrop + scoreFor()
│   └── verified_agri_database.dart    # LEGACY AgriPlant — yeni kod TurkishCrop kullansın
├── services/         # API client'lar, sulama, sync, kural motoru
├── widgets/          # UI kit
├── theme/app_theme.dart
└── main.dart

backend/
├── main.py
├── rule_engine.py
└── data_pipeline/
    ├── seed_plants.json
    └── build_turkish_crops_db.py

assets/data/turkish_crops.sqlite
```

Öncelikli referans dosyalar:

- `AGENTS.md`
- `lib/data/app_database.dart`
- `lib/data/turkish_crops_repository.dart`
- `backend/rule_engine.py`
- `backend/data_pipeline/seed_plants.json`
- `docs/`

---

## 5. Değiştirilemez Ürün Kuralları

### 5.1 Türkçe UI

- UI dili her yerde Türkçe olmalı.
- SnackBar, AlertDialog, hata mesajı, placeholder, buton, boş durum, loading metni dahil.
- Kullanıcıya görünen İngilizce string bırakma.
- Teknik log ve internal enum İngilizce olabilir; kullanıcıya görünmemeli.

### 5.2 Offline-first

- API çağrıları için maksimum 10 saniye timeout kullan.
- Cached fallback zorunlu.
- İnternet yoksa uygulama temel işlevleri çalıştırmalı.
- Sonsuz loading yasak.
- Hata durumunda kullanıcıya Türkçe, anlaşılır ve aksiyon alınabilir mesaj göster.

### 5.3 UI Kit

Hardcoded renk/font/radius kullanma. Öncelik:

- `AppColors.*`
- `AppText.*`
- `AppRadius.*`
- `AppShadows.*`
- `AppGradients.*`

Yeniden kullanılacak yardımcılar:

- `ParticleBackground`
- `TapScale`
- `ShimmerBox`
- `AppToast`
- `AnimatedRoute`
- `HapticService`

### 5.4 Erişilebilirlik ve saha kullanımı

- Minimum font: 13px.
- Buton hedefi: en az 48dp.
- Güneş altında okunabilir yüksek kontrast.
- Kritik aksiyonlar için açık başlık + kısa açıklama.
- Yaşlı kullanıcılar için karmaşık teknik terimlerden kaçın.

### 5.5 Kullanıcı izolasyonu

- `Fields` tablosunda `farmerUid` vardır.
- Yeni entity'ler kullanıcıya aitse `farmerUid` taşımalıdır.
- Kullanıcı A'nın verisi kullanıcı B'ye görünmemeli.

### 5.6 Senkronizasyon

- LWW: Last-Write-Wins.
- `SyncJobs` outbox mantığı korunur.
- `SyncState` cursor yapısı korunur.
- Offline değişiklikler sync kuyruğuna yazılır.
- Çakışma çözümü timestamp bazlıdır.

---

## 6. Kod Felsefesi

1. Mevcut çalışan kodu koru.
2. Bug veya açık mimari tutarsızlık yoksa dokunma.
3. Artımlı değişiklik büyük refactor'dan daha değerlidir.
4. Yeni dosya yalnızca gerçekten gerekliyse oluştur.
5. Var olan servis/repository/widget/helper tekrar kullanılmalı.
6. Legacy `AgriPlant` yerine yeni kodda `TurkishCrop` tercih edilmeli.
7. Sahte API key üretme; `.env` placeholder kullan.
8. Büyük değişiklik yapmadan önce ilgili dosyaları oku.
9. Aynı işi yapan ikinci bir servis oluşturma.
10. Değişiklik sonunda neyin değiştiğini kısa özetle.

---

## 7. Hazır Yardımcılar — Yeniden Yazma

- `TurkishCropsRepository.instance`
  - `ensureReady()`
  - `search(query, limit)`
  - `byId()`

- `TurkishCrop.scoreFor({temperature, soilPh, weeklyRain, month})`
  - `SuitabilityScore{score: double, reasons: List<String>}` döner.

- `_envForSuitability()`
  - `field_detail_screen` içinde analiz sonucundan `(ph, temp, annualRain)` üretir.

- `_colorForCategory(String category)`
  - 11 kategori için Color map.

- `LocalDataRepository`
  - Drift CRUD işlemleri.

- `HapticService`
  - Tek nokta haptic feedback.

---

## 8. Güncel Durum

### Tamamlanan

- 292 Türk bitkisi SQLite DB.
- `seed_plants.json` → build script → SQLite asset akışı.
- `field_3d_planner_screen`: 292 çeşit picker.
- `field_detail_screen._showPlantPicker`: `TurkishCrop.scoreFor` ile skor üretimi.
- `turkish_crops_search_screen`: `pickerMode` ile `Navigator.pop(TurkishCrop)` desteği.
- Kimlik doğrulama.
- Tarla kayıt.
- Hava durumu.
- Ürün takvimi.
- Sulama planı.
- Çevrimdışı ansiklopedi.
- Sync altyapısı.

### Yarım / İyileştirme Gerek

- Admin panel: HTML iskelet var, backend entegrasyonu kısmi.
- İnteraktif tarla-üstü ürün yerleştirme.
- Tarla 360° panoramik görünüm.
- Test coverage düşük.

### Eksik

- Gelir/maliyet takibi.
- NPK tabanlı gübreleme takvimi.
- Fotoğraf tabanlı hastalık ön sınıflandırması.
- Kaynak kanıtlı tarımsal rule pack sistemi.
- BKÜ referans/güncelleme katmanı.

---

# 9. Deterministik Tarım Bilgi Sistemi

Bu projenin tarımsal zekâ katmanı LLM cevabı değil, **deterministik kural motoru** olmalıdır.

Doğru akış:

```text
Resmî kaynak
↓
Kaynak kanıtlı extraction
↓
JSON schema validation
↓
Uzman/manuel kontrol
↓
Versioned rule pack
↓
Flutter local DB
↓
Deterministik rule engine
↓
Açıklanabilir Türkçe çıktı
```

Yanlış akış:

```text
Kullanıcı sorusu
↓
LLM tahmini
↓
Doğrudan ilaç/gübre/teşhis tavsiyesi
```

---

## 10. Tarımsal Veri Kaynağı Kuralları

Öncelik sırası:

1. Tarım ve Orman Bakanlığı
2. TAGEM
3. Bakanlığa bağlı araştırma enstitüleri
4. ÇAYKUR / TEPGE / resmî ürün raporları
5. Üniversite ziraat fakültesi yayınları
6. Ziraat odası veya kamu destekli eğitim notları
7. Özel firma kaynakları yalnızca düşük öncelikli destekleyici kaynak olarak kullanılabilir.

Kurallar:

- Kaynakta olmayan bilgi çıkarma.
- Bilgi tarihini ve kurumunu sakla.
- Çelişen bilgileri sessizce birleştirme.
- “Genelde”, “çoğunlukla”, “uygun olabilir” gibi ifadeleri kesin kural gibi yazma.
- İlaç, doz, aktif madde ve hasat aralığı yalnızca güncel resmî kaynakta açıkça varsa saklanabilir.
- İlaç uygulaması için her zaman BKÜ kontrolü gerekir.

---

## 11. Ana Ürünler ve Stable ID'ler

Öncelikli ürünler:

| Ürün | ID |
|---|---|
| Ayçiçeği | `crop.sunflower` |
| Çay | `crop.tea` |
| Portakal | `crop.orange` |
| Mısır | `crop.corn` |
| Domates | `crop.tomato` |

Yeni tarımsal veri eklerken stable ID kullan:

```text
crop.sunflower
disease.tomato.botrytis
pest.tomato.tuta_absoluta
operation.corn.sowing
rule.sunflower.sowing.trakya_spring
source.tagem.sunflower_integrated_management
```

ID kuralları:

- Küçük harf kullan.
- Türkçe karakter kullanma.
- Boşluk yerine `_` kullan.
- Aynı hastalık/zararlı için birden fazla ID üretme.
- Eski ID'yi kırmak yerine migration yaz.

---

## 12. Tarımsal JSON Veri Modeli

Tarımsal bilgi tek dosyada serbest metin olarak tutulmamalı. Aşağıdaki bölümlere ayrılmalı:

```json
{
  "source_metadata": [],
  "crop_profiles": [],
  "region_profiles": [],
  "soil_requirements": [],
  "growth_stages": [],
  "operation_calendar": [],
  "fertilizer_rules": [],
  "irrigation_rules": [],
  "diseases": [],
  "pests": [],
  "weed_management": [],
  "control_methods": [],
  "rule_engine_rules": [],
  "conflicts": [],
  "missing_information": [],
  "test_cases": []
}
```

Her kayıt şunları taşımalı:

```json
{
  "id": "stable.id.example",
  "source_ids": ["source.example"],
  "confidence": "high | medium | low",
  "evidence": [
    {
      "source_id": "source.example",
      "page": null,
      "section": null,
      "evidence_text": "Kaynakta geçen kısa kanıt veya kaynaklı özet"
    }
  ],
  "created_at": "YYYY-MM-DD",
  "updated_at": "YYYY-MM-DD"
}
```

Eğer kanıt yoksa bilgi uygulamaya alınmamalı.

---

## 13. Source Metadata Şeması

Her kaynak şu şekilde saklanmalı:

```json
{
  "id": "source.tagem.tomato_integrated_management",
  "title": "Açık Alan Domates Entegre Mücadele Teknik Talimatı",
  "institution": "Tarım ve Orman Bakanlığı / TAGEM",
  "source_type": "official | research_institute | university | public_agency | private",
  "url": "https://...",
  "publication_year": null,
  "retrieved_at": "YYYY-MM-DD",
  "reliability": "high",
  "notes": null
}
```

---

## 14. Rule Engine Kural Şeması

Kural formatı:

```json
{
  "id": "rule.tomato.disease.botrytis.greenhouse_high_humidity",
  "crop_id": "crop.tomato",
  "category": "disease_risk",
  "priority": 90,
  "enabled": true,
  "conditions": [
    {
      "field": "cultivation_type",
      "operator": "equals",
      "value": "greenhouse"
    },
    {
      "field": "relative_humidity_level",
      "operator": "equals",
      "value": "high"
    }
  ],
  "result": {
    "risk_level": "high",
    "possible_problem_id": "disease.tomato.botrytis",
    "recommendations": [
      "Serada havalandırmayı artır.",
      "Hastalıklı bitki parçalarını uzaklaştır.",
      "Yaprak ıslaklığını azalt.",
      "Kimyasal mücadele gerekiyorsa BKÜ veritabanında güncel ruhsat kontrolü yap."
    ],
    "requires_expert_confirmation": true,
    "requires_bku_check": true
  },
  "explanation": "Sera ortamı ve yüksek nem Botrytis riskini artırabilir.",
  "confidence": "medium",
  "evidence": [
    {
      "source_id": "source.tagem.tomato_integrated_management",
      "page": null,
      "section": null,
      "evidence_text": "Kaynakta Botrytis ve nem/sera ilişkisi belirtilmiştir."
    }
  ]
}
```

Kural kategorileri:

```text
suitability
soil_analysis
pre_planting
sowing_or_planting
fertilization
irrigation
disease_risk
pest_risk
weed_management
harvest
weather_warning
task_generation
safety_warning
```

Desteklenen operatörler:

```text
equals
not_equals
greater_than
less_than
greater_or_equal
less_or_equal
between
contains
in
not_in
exists
missing
```

Yeni operatör eklenirse:

1. Dart rule engine güncellenmeli.
2. Backend rule engine güncellenmeli.
3. Test case eklenmeli.
4. Eski rule pack geriye dönük kırılmamalı.

---

## 15. Kullanıcı Facts Modeli

Kural motoru kullanıcı girdilerini `facts` olarak almalı.

Örnek:

```json
{
  "farmer_uid": "user_123",
  "field_id": "field_456",
  "crop_id": "crop.tomato",
  "province": "Antalya",
  "district": "Serik",
  "cultivation_type": "greenhouse",
  "soil_ph": 7.8,
  "soil_ec": 1.6,
  "organic_matter_percent": 1.8,
  "irrigation_type": "drip",
  "planting_date": "2026-03-15",
  "days_after_planting": 42,
  "growth_stage": "flowering",
  "relative_humidity_level": "high",
  "symptom_location": "leaf",
  "symptom_type": "grey_mold"
}
```

Kural motoru aynı facts + aynı rule pack ile her zaman aynı çıktıyı vermelidir.

---

## 16. Gübreleme Güvenlik Kuralları

Gübreleme modülü risklidir. Evrensel reçete verme.

Zorunlu karar akışı:

```text
Toprak analizi var mı?
├── Yoksa: Önce toprak analizi öner.
└── Varsa:
    ├── pH kontrolü
    ├── EC/tuzluluk kontrolü
    ├── organik madde kontrolü
    ├── azot/fosfor/potasyum durumu
    ├── ürün + bölge + dönem kontrolü
    └── yalnızca kaynaklı öneri üret
```

Kurallar:

- Toprak analizi yoksa kesin gübre miktarı önerme.
- Sadece genel bakım önerisi ver.
- “Ön gübreleme” önerileri kaynak ve analiz olmadan kesin yazılmamalı.
- Fazla azot, tuzluluk, pH ve çevre riski uyarıları gösterilmeli.
- Girdi eksikse `missing_information` üret.

Örnek güvenli çıktı:

```text
Toprak analizi girilmediği için net gübre miktarı hesaplanamadı. Önce pH, EC, organik madde, azot, fosfor ve potasyum değerlerini içeren toprak analizi ekleyin.
```

---

## 17. Bitki Koruma Ürünü / BKÜ Güvenlik Kuralları

Bu bölüm kesinlikle ihlal edilmemeli.

Uygulama doğrudan şu tarz çıktı vermemeli:

```text
Şu ilacı şu dozda at.
```

Doğru çıktı:

```text
Bu belirti domates mildiyösü ile uyumlu olabilir. Kesin teşhis için ziraat mühendisi onayı gerekir. Kimyasal mücadele gerekiyorsa Tarım ve Orman Bakanlığı BKÜ veritabanında domates + mildiyö için güncel ruhsatlı ürün, etiket dozu ve son ilaçlama-hasat aralığı kontrol edilmelidir.
```

Kurallar:

- Her kimyasal kontrol kaydında `requires_bku_check: true` olmalı.
- Her teşhis kaydında `requires_expert_confirmation: true` olmalı.
- Aktif madde, ürün adı, doz veya hasat aralığı yalnızca resmî kaynakta açıkça varsa saklanabilir.
- Ruhsat tarihi değişebileceği için eski veriyi kesin tavsiye gibi gösterme.
- BKÜ dışı veya kaynaksız ilaç tavsiyesi üretme.
- Kültürel ve mekanik önlemler her zaman kimyasal öneriden önce gösterilmeli.
- Hasada yakın dönemde kalıntı riski uyarısı gösterilmeli.

---

## 18. Hastalık/Zararlı Teşhis Kuralları

Teşhis kesin değil, olasılıksal ve açıklanabilir olmalı.

Çıktı formatı:

```json
{
  "possible_problem": "Kurşuni küf / Botrytis",
  "certainty": "low | medium | high",
  "matched_evidence": [
    "Sera ortamı",
    "Yüksek nem",
    "Gri küf belirtisi"
  ],
  "recommendations": [
    "Havalandırmayı artır.",
    "Hastalıklı dokuları uzaklaştır.",
    "Kimyasal mücadele gerekiyorsa BKÜ kontrolü yap."
  ],
  "requires_expert_confirmation": true
}
```

Kurallar:

- “Kesin hastalık budur” deme.
- “Uyumlu olabilir”, “risk artmış olabilir”, “şüpheli belirti” gibi dikkatli dil kullan.
- Fotoğraf tabanlı sınıflandırma varsa bile deterministik kural sonucu ile çakıştır.
- Belirti, iklim, dönem ve ürün eşleşmiyorsa düşük güven ver.
- Birden fazla olası hastalık varsa öncelik ve kanıt listesiyle göster.

---

## 19. Hava Durumu ve Dinamik Görev Kuralları

Hava durumu bilgisi öneri üretir ama tek başına kesin karar vermez.

Örnek:

```text
IF crop = tomato
AND forecast.rain_expected = true
AND forecast.humidity_level = high
AND growth_stage in [vegetative, flowering]
THEN disease_monitoring_task = mildiyö belirtisi kontrolü
```

Bildirim dili:

```text
Önümüzdeki 48 saatte nem ve yağış riski yüksek. Domateste yaprak hastalıkları için gözlem yapın. Kimyasal mücadele gerekiyorsa BKÜ kontrolü ve uzman onayı gerekir.
```

Kurallar:

- Hava verisi yoksa cached veri kullan.
- Cached veri eskiyse “veri eski olabilir” uyarısı ver.
- Risk bildirimi ile ilaç tavsiyesini karıştırma.
- Yağış bekleniyorsa sulama erteleme önerisi deterministik olabilir.

---

## 20. Claude ile Kaynak → JSON Dönüştürme Workflow'u

Tarımsal kaynak dönüştürürken şu sırayı takip et:

1. Kaynak metadata çıkar.
2. Ürün adlarını normalize et.
3. Bölge, iklim, toprak, pH, ekim/dikim, sulama, gübreleme, hastalık, zararlı ve mücadele bilgilerini ayrı bölümlere ayır.
4. Her fact için evidence ekle.
5. Sayısal değerleri birimle sakla.
6. Kaynakta olmayan alanları `null` bırak.
7. Çakışan bilgileri `conflicts` içine yaz.
8. Eksik kritik bilgileri `missing_information` içine yaz.
9. Kural motoru formatına dönüştür.
10. Her kural için test case üret.
11. JSON parse + schema validation çalıştır.

Extraction prompt standardı:

```text
Convert only the information explicitly present in the provided official Turkish agricultural source into structured JSON for Tarlam's deterministic rule engine.

Rules:
- Do not invent missing information.
- Use null for values not present in the source.
- Every fact must include source evidence.
- Separate crop knowledge, soil requirements, growth stages, diseases, pests, cultural controls, biological controls, chemical-control references, and rule-engine rules.
- Do not recommend pesticide, active ingredient, dose, or interval unless explicitly present in the provided official source.
- For pesticide-related records, always set requires_bku_check = true.
- If sources conflict, create a conflict record instead of resolving silently.
- Output only valid JSON.
```

---

## 21. Validation Kuralları

Rule pack veya tarımsal JSON değiştiyse şu kontroller zorunlu:

1. JSON parse oluyor mu?
2. Schema'ya uyuyor mu?
3. Her kayıtta `id` var mı?
4. Her fact veya rule için `evidence` var mı?
5. Her kimyasal mücadele kaydında `requires_bku_check: true` var mı?
6. Her hastalık/zararlı teşhisinde `requires_expert_confirmation: true` var mı?
7. Aynı hastalık iki ID ile tekrar edilmiş mi?
8. Ürün-hastalık eşleşmeleri doğru mu?
9. Sayısal değerlerde birim var mı?
10. Kaynakta olmayan değer eklenmiş mi?
11. Çelişen kaynaklar `conflicts` içine yazılmış mı?
12. Test case'ler geçiyor mu?

Kural testi örneği:

```json
{
  "id": "test.rule.tomato.botrytis.high_humidity.matches",
  "rule_id": "rule.tomato.disease.botrytis.greenhouse_high_humidity",
  "facts": {
    "crop_id": "crop.tomato",
    "cultivation_type": "greenhouse",
    "relative_humidity_level": "high",
    "symptom_type": "grey_mold"
  },
  "expected_match": true
}
```

---

## 22. Flutter Rule Engine Uygulama Prensipleri

- Rule engine pure function gibi çalışmalı.
- Input: `facts`, `rules`.
- Output: sıralanmış `RuleResult` listesi.
- Aynı input aynı output üretmeli.
- UI içinde kural değerlendirme mantığı yazma.
- Rule evaluation servis katmanında olmalı.
- Öncelik sıralaması `priority` ile yapılmalı.
- Çıktı kullanıcıya açıklama + kanıt + aksiyon şeklinde gösterilmeli.

Önerilen klasör:

```text
lib/core/rule_engine/
├── rule.dart
├── rule_condition.dart
├── rule_result.dart
├── rule_engine.dart
├── operators.dart
└── rule_pack_validator.dart
```

UI gösterimi:

```text
Sonuç: Kurşuni küf riski yüksek olabilir.
Neden?
- Ürün domates.
- Ortam sera.
- Nem yüksek.
- Gri küf belirtisi seçildi.

Yapılacaklar:
1. Havalandırmayı artır.
2. Hastalıklı dokuları uzaklaştır.
3. Kimyasal mücadele gerekiyorsa BKÜ kontrolü yap.
```

---

## 23. Drift / SQLite Veri Modeli Önerisi

Yeni rule pack sistemi eklenirse öncelikli tablolar:

```text
SourceReferences
CropProfiles
RegionProfiles
SoilRequirements
GrowthStages
OperationCalendar
DiseaseProfiles
PestProfiles
ControlMethods
RulePacks
RuleEngineRules
RuleTestCases
FieldObservations
RecommendationResults
```

Kullanıcıya ait tablolar `farmerUid` taşımalı:

```text
Fields
FieldCrops
CalendarEvents
IrrigationPlans
SuitabilityReports
FieldObservations
RecommendationResults
SyncJobs
```

Kaynak ve rule pack tabloları global olabilir; kullanıcı verisiyle karıştırma.

---

## 24. Backend Rule Pack API Önerisi

FastAPI tarafında rule pack güncelleme için şu mantık kullanılabilir:

```text
GET /api/rule-packs/latest
GET /api/rule-packs/{version}
GET /api/crops/{crop_id}/knowledge
GET /api/sources/{source_id}
POST /api/rule-packs/validate
```

Rule pack response örneği:

```json
{
  "version": "2026.05.06",
  "locale": "tr-TR",
  "crops": ["crop.sunflower", "crop.tomato", "crop.corn"],
  "source_count": 12,
  "rule_count": 240,
  "checksum": "sha256:...",
  "created_at": "2026-05-06T00:00:00Z",
  "rules": []
}
```

Kurallar:

- Rule pack versioned olmalı.
- Checksum ile bütünlük kontrolü yapılmalı.
- Eski rule pack çalışmaya devam etmeli.
- Uygulama offline iken son geçerli rule pack'i kullanmalı.

---

## 25. Test Politikası

Test coverage şu an düşük. Yeni özellik eklenirse en azından ilgili katmana test ekle.

Öncelikli testler:

1. Rule engine operator testleri.
2. Rule matching testleri.
3. Gübreleme guardrail testleri.
4. BKÜ guardrail testleri.
5. Türkçe UI string kontrolü.
6. Drift migration testleri.
7. Repository fallback/cache testleri.
8. Offline behavior testleri.

Guardrail testleri özellikle önemli:

- Toprak analizi yokken net gübre miktarı dönmemeli.
- BKÜ kontrolü olmadan kimyasal tavsiye dönmemeli.
- Hastalık teşhisi `requires_expert_confirmation` olmadan dönmemeli.
- Kaynaksız rule sisteme alınmamalı.
- UI İngilizce string içermemeli.

---

## 26. Projeye Özel Skill'ler

Tekrarlayan işlerde başvur:

```text
.claude/skills/<name>/SKILL.md
```

Mevcut skill'ler:

- `/add-crop` — `seed_plants.json`'a yeni bitki ekle + DB rebuild.
- `/rebuild-crops-db` — SQLite DB'yi yeniden üret, asset'i doğrula.
- `/new-screen` — Tarlam konvansiyonlarıyla yeni Flutter ekran iskeleti.
- `/tr-ui-lint` — Verilen dosyada İngilizce UI string'lerini yakala.
- `/drift-migration` — Drift tablo/kolon ekle + schema version bump + build_runner.
- `/analyze-all` — flutter analyze + dart format + python lint + API key tara.

Rule pack sistemi eklenirse önerilen yeni skill'ler:

- `/extract-agri-source` — resmî kaynaktan kaynak kanıtlı JSON çıkar.
- `/validate-rule-pack` — JSON schema + guardrail testleri çalıştır.
- `/add-agri-rule` — yeni deterministik kural ekle.
- `/bku-guardrail-check` — kimyasal tavsiye güvenlik kontrolü yap.
- `/rule-engine-test` — facts + rules için beklenen eşleşmeleri test et.

---

## 27. Claude Code Çalışma Protokolü

Her görevde şu sırayı izle:

1. İlgili dosyaları oku.
2. Mevcut mimariyi bozma.
3. En küçük güvenli değişikliği planla.
4. Kod veya veri değiştir.
5. Format/analyze/test çalıştır.
6. Sonuçta şunları raporla:
   - Değişen dosyalar
   - Ne düzeltildi
   - Hangi komutlar çalıştı
   - Kalan riskler
   - Manuel kontrol gereken yerler

Cevap formatı:

```text
Değişiklikler:
- ...

Kontroller:
- flutter analyze lib/: geçti / çalıştırılamadı
- dart format: geçti / çalıştırılamadı

Riskler:
- ...

Sonraki önerilen adım:
- ...
```

---

## 28. Kırmızı Çizgiler

Aşağıdaki durumlarda işlem yapmadan önce problemi açıkça belirt:

- Kaynak resmî değilse.
- Kaynakta bilgi yoksa.
- İlaç/aktif madde/doz bilgisi güncel BKÜ ile doğrulanmamışsa.
- Toprak analizi olmadan kesin gübre miktarı isteniyorsa.
- Kullanıcıya gösterilecek İngilizce string oluşuyorsa.
- Değişiklik büyük migration gerektiriyorsa.
- Mevcut çalışan veri modeli kırılacaksa.
- Flutter ve backend rule engine davranışı ayrışacaksa.

---

## 29. En Önemli Mimari İlke

Tarlam bir sohbet botu değildir.

Tarlam şu olmalıdır:

> Türkiye tarımı için resmî kaynaklara dayanan, offline çalışabilen, kullanıcı verisini koruyan, aynı girdiye aynı sonucu veren, açıklanabilir deterministik tarım karar destek sistemi.

Her yeni özellik bu ilkeye göre değerlendirilmelidir.
