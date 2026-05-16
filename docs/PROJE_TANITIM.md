# Tarlam — Proje Tanıtım Dokümanı

**Proje Adı:** Tarlam — Türkiye Tarımı için Çevrimdışı Öncelikli, Açıklanabilir Karar Destek Sistemi
**Proje Kodu:** FENG-498 Senior Project
**Doküman Tarihi:** 2026-05-16
**Doküman Sürümü:** 1.0

---

## 1. Projenin Konusu ve Amacı

### 1.1 Konu

Tarlam; Türkiye'nin kırsal bölgelerindeki çiftçilere yönelik, **çevrimdışı öncelikli (offline-first)**, **deterministik kural motoruna dayalı** ve **açıklanabilir** bir tarımsal karar destek sistemidir. Sistem; Flutter tabanlı bir mobil uygulama, FastAPI tabanlı bir buluttarafı servis ve Tarım ve Orman Bakanlığı, TAGEM, üniversite ziraat fakülteleri gibi resmî kaynaklardan derlenmiş kanıta dayalı bir tarımsal bilgi katmanından oluşur.

Uygulama; tarla kayıt, ürün takvimi, hava durumu izleme, FAO Penman-Monteith tabanlı sulama planlaması, toprak analizine göre bitki uygunluk skorlama, hastalık/zararlı ön değerlendirmesi, gübreleme rehberliği ve çevrimdışı bitki ansiklopedisi gibi modüller içerir. 292 Türk bitkisini kapsayan yerel SQLite veri tabanı, internet bağlantısı olmadan da temel işlevlerin sürdürülmesini sağlar.

### 1.2 Amaç

Projenin temel amacı; düşük bant genişliğine sahip, internet erişimi istikrarsız olan Anadolu kırsalındaki çiftçilerin — yaş, dijital okuryazarlık düzeyi veya teknik altyapı sınırı olmaksızın — kullanabileceği, **resmî kaynaklara dayanan**, **aynı girdiye her zaman aynı çıktıyı veren** ve her önerisinin gerekçesini şeffaf biçimde sunan bir tarım yönetim aracını ortaya koymaktır.

Alt amaçlar:

1. **Tarımsal kararı veriden tahminden ayırmak.** Sistem, bir Büyük Dil Modeli (LLM) gibi serbest metin tahmini üretmez; resmî kaynaklardan derlenmiş, JSON şemasıyla doğrulanmış, sürümlü kural paketleri (rule pack) üzerinde çalışan bir kural motoruna dayanır.
2. **Çiftçi güvenliği için sıkı koruma çizgileri (guardrails) kurmak.** Toprak analizi olmadan kesin gübre miktarı önerilmez; ilaç tavsiyesi yalnızca aktif madde düzeyinde ve **mutlaka bku.tarim.gov.tr** yönlendirmesi ile sunulur; hastalık teşhisi her zaman "uzman onayı gerektirir" notuyla iletilir.
3. **Türkçe ve yaşa duyarlı arayüz** sağlamak: minimum 13 px tipografi, 48 dp dokunma hedefi, yüksek kontrast, sahada güneş altında okunabilirlik, tek bir İngilizce dize bile bırakmayan tutarlı yerelleştirme.
4. **Kullanıcı verisinin sahibinde kalmasını** sağlamak: tüm tarla, gözlem ve takvim verisi `farmerUid` bazlı izole edilir, Last-Write-Wins çatışma çözümlü senkronizasyon kuyruğu (SyncJobs outbox) ile bulutla eşlenir, çevrimdışıyken bile yerel olarak çalışmaya devam eder.

---

## 2. Projenin Özgün Değeri

### 2.1 Türkiye Tarımına Özgü Tasarım

Piyasadaki çoğu tarım uygulaması ya yurt dışı kaynaklı veridir (Avrupa veya ABD ürün-iklim profillerine göre kalibre edilmiştir) ya da Türkçeleştirilmiş bir kabuk üzerine kuruludur. Tarlam ise:

- **292 Türk bitkisini kapsayan** ve `backend/data_pipeline/seed_plants.json` üzerinden üretilen `assets/data/turkish_crops.sqlite` ile tamamen yerel ürün veritabanı kullanır.
- Ürün uygunluk skorlamasını (`TurkishCrop.scoreFor`) sıcaklık + toprak pH'sı + haftalık yağış + ay (mevsim) dörtlüsüne göre üretir; sonuçta yalnızca puan değil, "neden bu puan verildi" gerekçe listesi de döner.
- Ana ürünler (ayçiçeği, çay, portakal, mısır, domates) için stabil kimlikler (`crop.sunflower`, `crop.tea`, `crop.orange`, `crop.corn`, `crop.tomato`) tanımlanmıştır; bu kimlikler kural paketleri, hastalık kayıtları ve operasyon takvimleri arasında köprü görevi görür.

### 2.2 Deterministik ve Açıklanabilir Karar Mimarisi

Tarlam'ı benzerlerinden ayıran en kritik mimari tercih, tarımsal zekânın bir LLM yanıtı değil, bir **deterministik kural motoru** tarafından üretilmesidir. Akış şu şekildedir:

```
Resmî kaynak → Kanıtlı extraction → JSON schema validation
→ Uzman kontrolü → Sürümlü rule pack → Yerel veritabanı
→ Deterministik rule engine → Açıklanabilir Türkçe çıktı
```

Bu mimarinin somut karşılıkları:

- Her kural; `id`, `priority`, `conditions[]`, `result.recommendations[]`, `evidence[]` ve `confidence` alanları taşır. Aynı `facts` + aynı rule pack her zaman aynı sonucu üretir.
- Sonuç kullanıcıya "Sonuç + Neden? + Yapılacaklar" üçlüsüyle gösterilir; çiftçi, sistemin neden bu öneriyi verdiğini madde madde görür.
- Kural paketleri sürümlüdür (`version: "2026.05.06"`) ve checksum ile bütünlük doğrulaması yapılır; eski sürüm rule pack'ler çalışmaya devam eder.

### 2.3 Güvenlik Çizgileri (Guardrails)

Tarımsal uygulamaların büyük çoğunluğu çiftçi sağlığını ve ürün güvenliğini ikincil tutar. Tarlam'da:

- **Gübreleme:** Toprak analizi (pH, EC, organik madde, NPK) girilmeden kesin gübre miktarı asla önerilmez; bunun yerine "önce toprak analizi yaptırın" yönlendirmesi ve `missing_information` raporu üretilir.
- **Bitki Koruma Ürünü (BKÜ):** Sistem **hiçbir koşulda ticari ürün markası** önermez. Yalnızca TAGEM Zirai Mücadele Teknik Talimatları'nda **açıkça yazılı** aktif maddeler (örn. "Metalaksil-M + Mancozeb") listelenir; her kayıt `requires_bku_check: true` ve `requires_expert_confirmation: true` bayrakları ile gelir; UI sıralaması kültürel → biyolojik → kimyasal + BKÜ uyarısı + güvenlik notu biçimindedir. Referans uygulama: [lib/data/disease_advice.dart](lib/data/disease_advice.dart).
- **Hastalık teşhisi:** "Kesin hastalık şudur" denmez; "uyumlu olabilir", "risk artmış olabilir" gibi olasılıksal dil kullanılır; her teşhis `matched_evidence[]` ile birlikte sunulur.

### 2.4 Çevrimdışı Öncelikli Mühendislik

Çoğu rakip ürün, internet kesilince kullanılamaz hale gelir. Tarlam:

- Drift (SQLite) + Hive yerel önbellek katmanını tüm modüllerde **birincil veri kaynağı** olarak kullanır.
- API çağrılarında 10 saniyelik sıkı timeout uygular ve her çağrı için **cached fallback** zorunludur.
- SyncJobs outbox mantığı, offline yapılan değişiklikleri kuyruğa yazıp internet geldiğinde Last-Write-Wins kuralıyla çözer; sonsuz loading veya veri kaybı yaşanmaz.
- WorkManager üzerinden arka plan görevleri (don/fırtına/yağış uyarıları) cihaz çevrimdışıyken bile yerel önbellek + son hava verisi üzerinden tetiklenebilir.

### 2.5 Akademik ve Mühendislik Katkısı

Senior proje bağlamında Tarlam; (a) tarımsal alan bilgisinin LLM tahmini yerine kanıtlı JSON + kural motoru ile modellenebileceğini, (b) Türkiye odaklı bir mobil tarım veri kümesinin (292 bitki + bölgesel kurallar) açıkça versiyonlanıp dağıtılabileceğini, (c) çevrimdışı öncelikli mimarinin uygulanabilir bir biçimini somut bir prototip üzerinde göstermektedir.

---

## 3. Projenin Yaygın Etkisi

### 3.1 Sosyal Etki

- **Dijital uçurumun azaltılması:** Tarlam, dijital okuryazarlığı düşük yaşlı çiftçileri hedef alır. Minimum 13 px tipografi, 48 dp buton hedefi, sade gezinme ve yüksek kontrastlı tasarım; teknolojiye uzak kullanıcıları dışlamadan dijital tarıma dahil eder.
- **Bilgiye eşit erişim:** Bakanlık talimatları, TAGEM yayınları ve üniversite ziraat fakültesi kaynakları genellikle PDF biçiminde dağılmış durumdadır. Tarlam bu bilgileri sahada, çevrimdışı, Türkçe ve uygulanabilir bir biçimde her çiftçinin cebine taşır.
- **Çiftçi sağlığı:** Marka adı yerine aktif madde + BKÜ yönlendirmesi yaklaşımı ve "uzman onayı gerekir" uyarıları, bilinçsiz pestisit kullanımının azaltılmasına katkı sağlar.

### 3.2 Ekonomik Etki

- **Girdi maliyetinin düşürülmesi:** Toprak analizi tabanlı, kaynaklı gübre önerileri sayesinde gereksiz gübre kullanımı önlenir; FAO Penman-Monteith ETo tabanlı 14 günlük sulama planı ile su kullanımı optimize edilir.
- **Verim kaybı riski:** Don/fırtına/yağış/sıcaklık uyarıları (FAO/WMO/MGM eşiklerine göre), kritik dönemde alınmayan önlem nedeniyle yaşanan verim kayıplarını azaltma potansiyeline sahiptir.
- **Ürün-tarla uyumu:** Bölge + iklim + toprak skorlamasıyla, çiftçinin tarlasına uygun olmayan ürünü ekme riski en başta önlenir.

### 3.3 Çevresel Etki

- Aşırı sulamayı önleyen ETo tabanlı plan, su kaynaklarının korunmasına katkı sağlar.
- Aşırı gübrelemeyi engelleyen guardrail mantığı, nitrat sızıntısı ve toprak tuzlanması riskini düşürür.
- Direnç yönetimi önerileri (etken madde grubu rotasyonu) ve kültürel/biyolojik mücadelenin kimyasaldan önce sunulması, IPM (Entegre Zararlı Yönetimi) felsefesini saha kullanıcısına ulaştırır.

### 3.4 Akademik ve Açık Kaynak Etkisi

- Türkçe ve Türkiye tarımına özgü, kanıt referanslı bir rule pack şeması geliştirilmektedir; bu şema, ileride başka tarım uygulamaları veya akademik çalışmalar tarafından kullanılabilecek bir referans biçim sunar.
- 292 bitkiyi içeren `turkish_crops.sqlite` ve `seed_plants.json` derlemi, FENG-498 kapsamında üretilmiş orijinal bir veri kümesidir.
- Çevrimdışı öncelikli, deterministik karar destek mimarisinin bir referans uygulaması olarak gelecek senior projelere örnek oluşturmaktadır.

### 3.5 Politika ve Kurumsal Etki Potansiyeli

Tarlam'ın rule pack sistemi, ileride Tarım ve Orman Bakanlığı veya il/ilçe tarım müdürlükleri tarafından merkezi olarak güncellenebilecek bir formatta tasarlanmıştır (versioned + checksum'lı dağıtım). Bu, kurumsal bilginin sahaya iletilmesi için resmî bir kanal hâline gelme potansiyeli taşır.

---

## 4. Projenin Uygulanabilirliği

### 4.1 Teknolojik Uygulanabilirlik

Tarlam, **kanıtlanmış ve olgun teknolojiler** üzerine kurulmuştur:

| Katman | Teknoloji | Olgunluk |
|---|---|---|
| Mobil UI | Flutter / Dart | Üretim sınıfı, çoklu platform |
| State Management | Riverpod 2.x | Stabil, geniş topluluk |
| Yerel veritabanı | Drift 2.x (SQLite) | Mobil cihazlarda standart |
| Önbellek | Hive 2.x | Hızlı KV store |
| Arka plan | WorkManager | Android/iOS standart |
| Backend | FastAPI + Uvicorn | Olgun, asenkron |
| Bulut DB | PostgreSQL + PostGIS | Coğrafi veri için fiilî standart |
| Kimlik doğrulama | Firebase Auth | Yönetilen servis |
| Bildirim | FCM + flutter_local_notifications | Çapraz platform |
| Harita | flutter_map / OpenStreetMap | Açık kaynak, ücretsiz |

Tüm bileşenler ücretsiz veya düşük maliyetli, açık kaynaklı veya yönetilen serbest katmanlara sahiptir. Donanım gereksinimi tarafında **2 GB RAM, Android 8.0+** seviyesinde düşük segment bir cihaz uygulamayı çalıştırabilir; bu, Anadolu kırsalındaki kullanıcı profiline uygundur.

### 4.2 Veri Uygulanabilirliği

Resmî tarımsal kaynaklar (TAGEM teknik talimatları, bakanlık yayınları, üniversite ziraat fakültesi materyalleri) açık erişimlidir. Tarlam'ın izlediği "kaynak → kanıtlı JSON → rule pack" iş akışı şunları sağlar:

- **Sıfırdan veri üretme zorunluluğu yoktur**; mevcut resmî dökümanlar kanıtla extract edilir.
- Her kayıtta `source_id`, `evidence_text`, `confidence` ve `updated_at` saklandığı için veri kalitesi sürdürülebilir biçimde izlenebilir.
- Çelişen kaynaklar `conflicts` listesine, eksik bilgiler `missing_information` listesine yazılır; bu, hem akademik şeffaflığı hem de operasyonel güveni destekler.

Mevcut durum itibarıyla 292 bitki kayıtlıdır, ana 5 ürün (ayçiçeği, çay, portakal, mısır, domates) için derinlemesine rule pack geliştirme planı yapılmıştır.

### 4.3 Operasyonel Uygulanabilirlik

- **Dağıtım:** APK olarak doğrudan dağıtılabilir veya Google Play üzerinden yayınlanabilir. Çevrimdışı çalışabildiği için, internet erişimi sınırlı bölgelerde dahi ilk kurulumdan sonra kullanılabilir.
- **Bakım:** Rule pack güncellemeleri **uygulama güncellemesinden bağımsız** olarak dağıtılabilir (`GET /api/rule-packs/latest`). Bu, bir bitki koruma ürünü ruhsatı veya bakanlık talimatı değiştiğinde, uygulamanın yeniden derlenmesi gerekmeden saha bilgisinin tazelenebilmesi anlamına gelir.
- **Çok kullanıcılı izolasyon:** `farmerUid` zorunluluğu sayesinde aynı arka uç birden çok çiftçiye, kooperatife veya ziraat odasına hizmet edebilir.

### 4.4 Yasal ve Etik Uygulanabilirlik

- Tarlam, "ilaç yazan bir uygulama" konumuna düşmekten **mimari düzeyde** kaçınır: BKÜ kararı her zaman bku.tarim.gov.tr otoritesine ve uzman görüşüne devredilir.
- Kullanıcı verisi `farmerUid` ile izole edilir; KVKK uyumlu bir veri sorumluluğu modeline taşınması doğrudandır.
- Açık kaynak bağımlılıkları MIT/BSD/Apache 2.0 lisansları çevresindedir; senior proje teslim ve akademik yayın akışıyla uyumludur.

### 4.5 Mevcut Çalışan Modüllerle İspatlanmış Uygulanabilirlik

Aşağıdaki modüller halihazırda çalışır durumdadır ve uygulanabilirliği saha düzeyinde doğrulanmıştır:

- Kimlik doğrulama (e-posta/şifre + misafir giriş)
- Tarla kayıt (poligon çizim + alan hesaplama)
- Hava durumu (OpenWeatherMap anlık + Open-Meteo 7 günlük)
- Preventif bildirimler (FAO/WMO/MGM eşiklerine göre)
- Ürün takvimi
- 292 bitkili Türk bitki veritabanı + uygunluk skorlama
- FAO Penman-Monteith ETo tabanlı 14 günlük sulama planı
- Offline ansiklopedi
- Async senkronizasyon (outbox + LWW)
- FastAPI backend (CRUD + sync endpoint'leri)

---

## 5. Projenin Gerçekleştirme Yöntemi

### 5.1 Mimari Yaklaşım

Tarlam üç ana katmandan oluşur:

**1) İstemci (Flutter mobil uygulama)**
- `lib/screens/`: Türkçe UI ekranları (kontrol paneli, tarla detayı, sulama planı, ürün takvimi, hastalık değerlendirme, ansiklopedi vb.)
- `lib/data/app_database.dart`: Drift şeması; `Fields`, `FieldCrops`, `CalendarEvents`, `IrrigationPlans`, `SyncJobs`, `SyncState` gibi tablolar
- `lib/data/turkish_crops_repository.dart`: 292 bitkili SQLite asset'ini yöneten singleton repository (`ensureReady()`, `search()`, `byId()`)
- `lib/services/`: Saf alan mantığı (sulama, FAO ETo, bildirim, sync, rule engine, hastalık değerlendirme, kontrol protokolleri vb.)
- `lib/widgets/`, `lib/theme/`: UI kiti (`AppColors`, `AppText`, `AppRadius`, `ParticleBackground`, `TapScale`, `ShimmerBox`, `AppToast`, `HapticService`)

**2) Sunucu (FastAPI backend)**
- `backend/main.py`: REST endpoint'leri, sync API, admin panel iskeleti
- `backend/rule_engine.py`: Sunucu tarafı kural motoru referansı
- `backend/data_pipeline/seed_plants.json` → `build_turkish_crops_db.py` → `assets/data/turkish_crops.sqlite`: Bitki verisi build pipeline'ı
- PostgreSQL + PostGIS: Bulut tarafı coğrafi veri ve kullanıcı verisi
- Firebase Auth: Kimlik doğrulama
- FCM: Push bildirimleri

**3) Bilgi Katmanı (Rule Packs)**
- `crop_profiles`, `region_profiles`, `soil_requirements`, `growth_stages`, `operation_calendar`, `fertilizer_rules`, `irrigation_rules`, `diseases`, `pests`, `control_methods`, `rule_engine_rules`, `conflicts`, `missing_information`, `test_cases` bölümlerinden oluşan, kanıt referanslı, sürümlü JSON paketleri.

### 5.2 Veri Akışı

```
[Çiftçi Girdisi]                              [Resmî Kaynaklar]
    │                                              │
    ▼                                              ▼
Flutter UI ────► Drift (SQLite)            Kanıtlı Extraction
    │              │                              │
    │              │                              ▼
    │              ▼                       JSON Schema Validation
    │         Yerel Cache                         │
    │              │                              ▼
    │              │                       Uzman Kontrolü
    │              │                              │
    │              ▼                              ▼
    │         Rule Engine ◄────── Versioned Rule Pack
    │              │                              ▲
    │              ▼                              │
    │     Açıklanabilir Çıktı                     │
    │     (Sonuç + Neden? + Yapılacaklar)        │
    │                                             │
    ▼                                             │
SyncJobs Outbox ────► FastAPI ────► PostgreSQL ──┘
       (LWW çatışma çözümü)
```

### 5.3 Geliştirme Süreci

1. **Analiz:** Hedef kullanıcı profili (kırsal Anadolu çiftçisi), bağlam (offline, güneş altında, yaşlı kullanıcı dahil) ve teknik kısıtlar (düşük bant genişliği, düşük segment cihaz) belirlendi.
2. **Mimari kararlar:** Flutter + Drift + Riverpod + FastAPI yığını seçildi; çevrimdışı öncelikli ve deterministik kural motoru ilkeleri sabitlendi.
3. **Çekirdek altyapı:** Kimlik doğrulama, tarla kayıt, hava durumu, ürün takvimi, sulama, sync sistemleri sırayla teslim edildi.
4. **Tarımsal veri katmanı:** `seed_plants.json` üzerinden 292 Türk bitkisi derlendi, `build_turkish_crops_db.py` ile SQLite asset üretildi, `turkish_crops_repository.dart` üzerinden mobil tarafa entegre edildi.
5. **Kural motoru iskeleti:** `lib/services/offline_rule_engine.dart`, `lib/services/crop_rules.dart`, `lib/services/ipm_decision_service.dart`, `lib/services/disease_diagnosis_service.dart`, `lib/services/soil_fertilization_service.dart` ile saha mantığı servis katmanına taşındı.
6. **Güvenlik çizgileri:** BKÜ guardrail mantığı `lib/data/disease_advice.dart` ve `lib/screens/treatment_protocol_screen.dart` üzerinden referans olarak gerçeklendi.
7. **Test ve doğrulama:** `flutter analyze`, `dart format`, `py_compile` ve guardrail testleri (toprak analizi olmadan gübre miktarı dönmesini, BKÜ kontrolü olmadan kimyasal tavsiye dönmesini engelleyen testler) öncelik listesine alındı.

### 5.4 Kalite Kontrol Süreci

Her tarımsal JSON / rule pack değişikliği için zorunlu kontrol listesi:

1. JSON parse + schema validation geçer mi?
2. Her kayıtta `id` ve `evidence` var mı?
3. Her kimyasal mücadele kaydında `requires_bku_check: true` var mı?
4. Her hastalık/zararlı teşhisinde `requires_expert_confirmation: true` var mı?
5. Sayısal değerler birimle birlikte mi saklanıyor?
6. Çelişen kaynaklar `conflicts` listesine yazılmış mı?
7. Test case'ler (örn. `test.rule.tomato.botrytis.high_humidity.matches`) geçiyor mu?
8. Türkçe UI lint (`/tr-ui-lint`) İngilizce sızıntı yakalıyor mu?

### 5.5 Skill ve Otomasyon Altyapısı

Tekrarlayan görevler için projeye özgü skill'ler tanımlıdır:

- `/add-crop` — `seed_plants.json`'a yeni bitki ekle ve DB'yi rebuild et.
- `/rebuild-crops-db` — SQLite asset'ini yeniden üret.
- `/new-screen` — Tarlam konvansiyonlarıyla yeni Flutter ekran iskeleti oluştur.
- `/tr-ui-lint` — Verilen dosyada İngilizce UI string'lerini yakala.
- `/drift-migration` — Drift tablo/kolon ekle, schema version bump, build_runner çalıştır.
- `/analyze-all` — `flutter analyze` + `dart format` + Python lint + hardcoded API key tarama.

Planlanan ileri skill'ler: `/extract-agri-source`, `/validate-rule-pack`, `/add-agri-rule`, `/bku-guardrail-check`, `/rule-engine-test`.

### 5.6 Yol Haritası

**Tamamlanan:**
- 292 bitkili SQLite veritabanı + build pipeline
- Kimlik doğrulama, tarla kayıt, hava durumu, ürün takvimi
- FAO Penman-Monteith ETo tabanlı sulama planı
- Çevrimdışı ansiklopedi, sync altyapısı, FastAPI backend

**Yarım kalan / iyileştirilmesi gereken:**
- Admin panel backend entegrasyonu
- İnteraktif tarla üstü ürün yerleştirme (tap-to-place, sürükle-bırak)
- Tarla 360° panoramik görünüm
- Test kapsamının yükseltilmesi

**Eksik / planlanan:**
- Gelir/maliyet takibi
- NPK tabanlı gübreleme takvimi (toprak analizi girdili)
- Fotoğraf tabanlı hastalık ön sınıflandırması (deterministik kural ile çakıştırılarak)
- Kaynak kanıtlı rule pack sistemi (`/api/rule-packs/latest` ile sürümlü dağıtım)
- BKÜ referans/güncelleme katmanı

---

## 6. Sonuç

Tarlam; Türkiye tarımının özgün koşullarını (resmî kaynak çeşitliliği, kırsal internet kısıtı, çiftçi profili çeşitliliği, ürün-bölge-toprak çeşitliliği, BKÜ ruhsat dinamizmi) merkeze alarak tasarlanmış, **çevrimdışı öncelikli**, **deterministik**, **kanıt referanslı** ve **açıklanabilir** bir mobil karar destek sistemidir. Proje; bir sohbet botu yerine, aynı girdiye her zaman aynı çıktıyı veren ve her önerisinin gerekçesini madde madde gösteren bir mühendislik ürünü olmayı hedefler.

Mevcut çalışan modüller, seçilen teknoloji yığınının olgunluğu, hedef kitleye uygun arayüz kararları ve resmî kaynaklara dayalı veri yönetimi yaklaşımı; projenin teknolojik, ekonomik, sosyal ve yasal düzlemlerde uygulanabilir olduğunu somut biçimde göstermektedir. FENG-498 senior projesi olarak Tarlam, hem akademik bir referans uygulama hem de saha kullanım potansiyeli yüksek bir tarımsal araç olma niteliğini taşımaktadır.
