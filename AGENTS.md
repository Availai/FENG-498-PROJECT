# AGENTS.md — Akıllı Tarım Asistanı v2.0

## Proje Kimliği
Türkiye'nin kırsal bölgelerindeki çiftçilere yönelik, çevrimdışı öncelikli, kapsamlı bir tarım yönetim
ve rehberlik uygulaması. Ana hedef: internet erişimi istikrarsız olan Anadolu kırsalında her çiftçinin
kayıtsız şartsız kullanabileceği, eksiksiz bir tarla yönetim + bilgi sistemi.

## Teknoloji Yığını
| Katman | Araç |
|---|---|
| Frontend | Flutter (Dart) |
| State Management | Riverpod |
| Yerel Veritabanı | Drift (SQLite) |
| Önbellek / Tercihler | Hive |
| Arka Plan Sync | WorkManager |
| Backend | FastAPI + Uvicorn |
| Doğrulama | Pydantic |
| ORM | SQLAlchemy + GeoAlchemy2 |
| Bulut DB | PostgreSQL + PostGIS |
| Kimlik Doğrulama | Firebase Auth |
| Bildirimler | FCM + flutter_local_notifications |
| Harita | flutter_map (OpenStreetMap/ArcGIS tiles) |
| Hava API'leri | OpenWeatherMap, Open-Meteo, Agromonitoring, MGM |
| Toprak API | SoilGrids (ISRIC), Agromonitoring soil |
| Bitki API | Perenual |
| Görsel Sıkıştırma | flutter_image_compress (WebP) |

---

## Ürün Kuralları

### Dil ve UX
- Uygulama dili **her yerde Türkçe** olmalıdır. Tek bir İngilizce kelime bile kullanılmamalı (hata mesajları dahil).
- UI **yüksek kontrast, koyu/açık tonlar arasında net ayrım**, güneş altında okunabilir olmalı.
- Yazı boyutu minimum 13px; düğme boyutu minimum 48dp (parmak hedefi).
- **Düşük bant genişliği** varsayımı: görseller WebP, API çağrıları timeout korumalı, her ekranda offline fallback.
- Gereksiz animasyonlardan kaçınılmalı; anlamlı micro-interaction'lar tercih edilmeli.

### Kod Felsefesi
- **Mevcut çalışan kodu koru.** Bug veya mimari tutarsızlık yoksa dokunma.
- Modülleri genişlet, büyük yeniden yazımlar yapma.
- Artımlı değişiklikleri büyük refactor'lara tercih et.
- **Çevrimdışı-öncelikli davranış kesin gereksinimdir.**
- Sağlam hata yönetimi ve açık fallback durumları zorunlu.
- Paket/API key'lerini uydurma — .env yapılandırma dosyasındaki placeholder'ları kullan.

---

## Mevcut Modül Durumu (Güncel Envanter)

### ✅ Tamamlanan Modüller
| Modül | Dosya(lar) | Durum |
|---|---|---|
| Kimlik Doğrulama | auth_screen.dart, auth_repository.dart | E-posta/şifre + misafir giriş çalışıyor |
| Tarla Kayıt (Poligon çizim) | field_3d_planner_screen.dart, field_repository.dart | Harita üzerinde nokta koyarak poligon çiz, alan hesapla, kaydet |
| Tarla Kayıt (Anlık GPS) | my_crops_screen.dart → _showAddDialog | Manuel konum ekleme çalışıyor |
| Hava Durumu + Tahmin | dashboard_screen.dart, agri_service.dart, openweather_api.dart | OpenWeatherMap anlık + Open-Meteo 7 gün tahmin |
| Preventif Bildirimler | notification_service.dart, background_sync_service.dart | Don/fırtına/yağış/sıcak uyarıları (FAO/WMO/MGM eşikleri) |
| Ürün Takvimi | crop_calendar_screen.dart, calendar_repository.dart | Ekim/hasat/sulama etkinlikleri gösteriliyor |
| Bitki Uygunluk Raporu | verified_agri_database.dart, field_detail_screen.dart | 15+ bitki skorlama (sıcaklık + pH + yağış) |
| Akıllı Sulama | irrigation_service.dart, fao_eto_service.dart, irrigation_schedule_screen.dart | FAO Penman-Monteith ETo tabanlı 14 günlük plan |
| Çevrimdışı Ansiklopedi | offline_encyclopedia.dart, plant_cache_service.dart | 22 bitki derlemeli statik veri |
| Async Senkronizasyon | sync_service.dart, sync_repository.dart, sync_api_client.dart | Outbox + LWW çatışma çözümü + pull cycle |
| Backend API | backend/main.py, backend/rule_engine.py | FastAPI + SQLAlchemy CRUD + sync endpoint'leri |
| Admin Panel İskeleti | backend/admin_panel.html | Temel HTML panel |

### ⚠️ Yarım Kalan / İyileştirilmesi Gereken Modüller

#### 1. İnteraktif Tarla Üstü Ürün Yerleştirme Sistemi
**Durum:** Basit bitki ekleme mevcut (zone_start/zone_end alanlarıyla), ama **kullanıcı tarlanın
neresine hangi ürünü yerleştireceğini elle seçemiyor**. Ürünler otomatik grid'e saçılıyor.

**Eksikler:**
- Tarla poligonu üzerinde elle dokunarak bölge belirleme (tap-to-place)
- Her ürün için kendine özgü görsel temsil (emoji yerine stilize vektör/ikon)
- Tarla içi bölge bölme (kuzey yarısı buğday, güney yarısı mısır gibi)
- Sürükle-bırak veya bölge boyama ile ürün yerleştirme
- Yerleştirme sonrası sıra aralığı ve bitki aralığı vizüalizasyonu

#### 2. Tarla 360° Panoramik İnceleme
**Durum:** Şu an FlutterMap 2D uydu görünümü var. Zoom/drag destekli.

**Eksikler:**
- Tarla poligonunun bir düzlem üzerinde 360° döndürülerek incelenmesi
- CustomPainter tabanlı pseudo-3D perspektif görünüm
- Açı kaydırıcı (slider) ile bakış açısı değişimi
- Ekili bitkilerin 3D perspektifte gösterimi
- Topografik yükseklik simülasyonu (opsiyonel)

#### 3. Ürün Bazlı Özelleştirilmiş Görüntüleme
**Durum:** Tüm bitkiler aynı emoji marker'larıyla gösteriliyor.

**Eksikler:**
- Her ürün ailesi için farklı render stili (tahıllar: paralel çizgiler, sebzeler: nokta-grid, meyveler: ağaç ikonu)
- Büyüme durumuna göre boyut değişimi (fide→olgun→hasat)
- Renk kodu lejandı
- Hasat zamanı gelmiş ürünlerde animasyonlu uyarı

#### 4. Çevrimdışı Ansiklopedinin Derinleştirilmesi
**Durum:** 22 bitki var ama bilgiler sınırlı.

**Eksikler:**
- Adım adım yetiştirme rehberi (ekim→fide→çiçeklenme→meyve→hasat)
- Hastalık ve zararlı tanıma rehberi (fotoğraflı)
- Bölgesel ekim takvimi (Akdeniz, İç Anadolu, Karadeniz vb.)
- Toprak iyileştirme rehberi
- Organik tarım yöntemleri bölümü
- Geleneksel Anadolu tarım bilgileri

#### 5. Admin Panel
**Durum:** Temel HTML şablonu var, backend entegrasyonu kısmi.

**Eksikler:**
- Kullanıcı yönetimi (hesap durumu, son giriş)
- API trafik istatistikleri
- İçerik güncelleme paneli (ansiklopedi maddeleri)
- Toplu bildirim gönderme

#### 6. Detaylı Toprak Analizi & Gübreleme
**Durum:** pH tabanlı basit tavsiye var.

**Eksikler:**
- NPK (azot-fosfor-potasyum) düzey gösterimi
- Toprak tipi tespiti ve uygun ürün eşleştirmesi
- Gübreleme takvimi (bitki bazlı, dönemsel)
- Kireçleme/kükürtleme hesaplayıcısı

#### 7. Gelir/Maliyet Takibi
**Durum:** Mevcut değil.

**Eksikler:**
- Ürün bazlı maliyet girişi (tohum, gübre, ilaç, işçilik)
- Hasat miktarı ve satış fiyatı girişi
- Dönemsel kâr/zarar raporu
- Dekara maliyet karşılaştırması

#### 8. Test Altyapısı
**Durum:** Test klasörü boş.

**Eksikler:**
- Unit testler (service, repository katmanları)
- Widget testleri (kritik ekranlar)
- Integration testleri (sync akışı)

---

## Fonksiyonel Kapsam (Tam Liste)

Aşağıdaki modüller talep edildiğinde uygulanmalı veya iyileştirilmelidir:

### Öncelik 1 — KRİTİK (Uygulamanın "rehber" olabilmesi için zorunlu)
1. **İnteraktif Tarla Üstü Ürün Yerleştirme** — Tarla poligonu üzerinde dokunarak ürün bölgesi seçme
2. **Tarla 360° İnceleme** — Seçilen tarlanın düzlem üzerinde 360° döndürülerek incelenmesi
3. **Ürün Bazlı Görsel Temsil** — Her ürüne özel render stili, büyüme fazına göre boyut
4. **Offline Ansiklopedi Derinleştirme** — Adım adım rehber, hastalık/zararlı tanıma, bölgesel takvim
5. **Türkçe UX Optimizasyonu** — Her köşede net, açıklayıcı Türkçe; çiftçi jargonu kullanılmalı

### Öncelik 2 — ÖNEMLİ
6. Gelir/Maliyet takibi
7. NPK tabanlı gübreleme takvimi
8. Admin panel tamamlama
9. Gelişmiş bildirimler (sulama hatırlatıcı, ilaçlama zamanı)
10. Crop rotation (nöbetleşe ekim) planlayıcısı

### Öncelik 3 — GELİŞTİRME
11. Fotoğraf tabanlı hastalık teşhisi
12. Pazar fiyatı entegrasyonu
13. Topluluk/forum özelliği
14. Test coverage (%80+ hedef)
15. Multi-dil desteği (Kürtçe, Arapça opsiyonel)

---

## Fonksiyonel Olmayan Kurallar

### Çevrimdışı Davranış
- İnternet olmadan uygulama **asla donmamalı**.
- Tüm yerel veri girişleri offline devam etmeli.
- Sync eventual consistency kullanmalı.
- Çatışma çözümü **LWW (Last-Write-Wins)** — timestamp bazlı.
- Sync kuyruğu Drift `SyncJobs` tablosunda, retry ile.

### Performans
- Fotoğraflar **yükleme öncesi WebP'ye sıkıştırılmalı**.
- API çağrıları **timeout korumalı** (max 10sn).
- Harita tile'ları cache'lenmeli (mümkünse).
- Büyük listelerde lazy loading kullanılmalı.

### Güvenlik
- Şifreler **asla** düz metin saklanmamalı (Firebase Auth yönetiyor).
- API istekleri **Firebase ID token** ile kimlik doğrulamalı.
- .env dosyasındaki key'ler versiyon kontrolüne dahil edilmemeli.

---

## Mühendislik Kuralları

### Kod Yazım Süreci
1. Mevcut repo yapısını incele — ne var ne yok tanımla.
2. Mevcut service/model/provider/repository/screen'leri **yeniden kullan**.
3. Yeni dosya yalnızca mecbur kalınırsa oluştur.
4. Dosya adları ve klasör yapısı mevcut stille tutarlı olsun.
5. TODO yalnızca gerçekten repo bağlamında çözülemeyecek durumlarda.
6. Sahte API key üretme — .env placeholder kullan.
7. Test edilebilir soyutlamalar tercih et.

### Mevcut Dosya Yapısı (Referans)
```
lib/
├── data/
│   ├── app_database.dart          # Drift schema (Fields, FieldCrops, CalendarEvents, IrrigationPlans, SuitabilityReports, SyncJobs, SyncState)
│   ├── app_database.g.dart        # Drift generated
│   ├── verified_agri_database.dart # 15+ AgriPlant tanımı (suitability scoring)
│   └── tagem_technical_specs.dart  # TAGEM teknik veriler
├── models/
│   ├── crop_layer.dart
│   ├── harvest_oracle_models.dart
│   └── seed_models.dart
├── screens/
│   ├── auth_screen.dart
│   ├── dashboard_screen.dart
│   ├── my_crops_screen.dart        # Tarla listesi + silme + tarla detaya geçiş
│   ├── field_detail_screen.dart    # 1858 satır — ana field command center
│   ├── field_3d_planner_screen.dart# Poligon çizim (yeni tarla)
│   ├── crop_calendar_screen.dart
│   ├── growing_guide_screen.dart
│   ├── camera_screen.dart
│   ├── navigation_screen.dart      # BottomAppBar + FAB
│   ├── irrigation_schedule_screen.dart
│   ├── harvest_oracle_screen.dart
│   ├── seed_selector_screen.dart
│   ├── crop_field_match_screen.dart
│   ├── satellite_weather_screen.dart
│   ├── map_hub_screen.dart
│   ├── sensor_data_screen.dart
│   ├── analysis_result_screen.dart
│   ├── plant_database_screen.dart  # AI analiz geçmişi + çevre geçmişi tabs
│   └── garden_manager_screen.dart
├── services/
│   ├── agri_service.dart           # OpenWeatherMap + Open-Meteo + SoilGrids + Perenual orkestrasyon
│   ├── agri_sim_service.dart
│   ├── anatolian_seed_db.dart
│   ├── companion_service.dart
│   ├── crop_rules.dart
│   ├── fao_eto_service.dart        # FAO Penman-Monteith ETo hesaplama
│   ├── harvest_oracle.dart
│   ├── irrigation_service.dart
│   ├── local_data_repository.dart  # Drift CRUD katmanı
│   ├── notification_service.dart   # FCM + local + hava eşik uyarıları
│   ├── offline_encyclopedia.dart   # 22 Türk bitkisi statik veri
│   ├── plant_cache_service.dart
│   ├── rule_engine.dart            # Deterministic tarım kuralları (44KB)
│   ├── sync_service.dart           # Push/Pull cycle + LWW
│   ├── sync_models.dart
│   ├── unified_weather_service.dart
│   ├── background_sync_service.dart# WorkManager periyodik görevler
│   ├── app_providers.dart          # Riverpod DI layer
│   ├── api/
│   │   ├── sync_api_client.dart
│   │   ├── openweather_api.dart
│   │   ├── agromonitoring_api.dart
│   │   ├── soilgrids_api.dart
│   │   ├── perenual_api.dart
│   │   └── mgm_api.dart
│   └── repositories/
│       ├── auth_repository.dart
│       ├── field_repository.dart
│       ├── calendar_repository.dart
│       ├── weather_repository.dart
│       └── sync_repository.dart
├── theme/
│   └── app_theme.dart              # AppColors, AppText, AppGradients, AppShadows, AppRadius
├── utils/
│   ├── db_seeder.dart
│   ├── image_compressor.dart
│   └── location_utils.dart
├── widgets/
│   ├── agri_matrix_painter.dart
│   ├── glass_panel.dart
│   ├── tech_3d_field_renderer.dart
│   ├── top_down_field_view.dart
│   ├── root_painter.dart
│   ├── weekly_water_card.dart
│   ├── planting_stat_card.dart
│   ├── bottom_sheet_content.dart
│   ├── ai_analysis_history_tab.dart
│   └── quick_environment_history_tab.dart
├── main.dart
└── firebase_options.dart

backend/
├── main.py                         # FastAPI endpoints + SQLAlchemy models
├── rule_engine.py                  # Server-side tarım kuralları
├── agri_api.py
├── admin_panel.html
├── requirements.txt
└── tests/
```

### Drift Veritabanı Şeması
- **Fields**: id, name, crop, date, latitude, longitude, areaDekar, areaSqm, polygonJson, timestamps, soft-delete
- **FieldCrops**: id, fieldId (FK), name, zoneStart, zoneEnd, rowSpacingCm, plantSpacingCm, colorValue, plantedDate, harvestDays, waterIntervalDays, timestamps, soft-delete
- **CalendarEvents**: id, fieldId (FK), cropId (FK), title, eventType, eventDate, source, metadataJson, timestamps, soft-delete
- **IrrigationPlans**: id, fieldId (FK), cropId (FK), scheduledDate, shouldIrrigate, reason, recommendation, timestamps, soft-delete
- **SuitabilityReports**: id, fieldId (FK), cropName, score, reportJson, timestamps, soft-delete
- **SyncJobs**: id (auto), entityType, entityId, operation, payloadJson, updatedAt, attemptCount, lastError, status
- **SyncState**: key, value, updatedAt

---

## Çıktı Kuralları

Her görev için:
1. Mevcut repo durumunu **kısaca** özetle.
2. Kısa bir uygulama planı listele.
3. Kod değişikliklerini uygula.
4. Dosya bazlı ne değiştiğini göster.
5. Doğrulama için çalıştırılacak komutları listele.
6. Repoda eksik bir parça varsa, tahmin etme — eksik parçayı açıkça belirt.

## Tamamlanmış Sayılma Kriterleri

Bir görev yalnızca şu koşullarda tamamlanmıştır:
- Kod mevcut mimari içinde mantıksal olarak derlenir.
- Yeni mantık mevcut akışa bağlanmıştır.
- Uç durumlar ve çevrimdışı durumlar ele alınmıştır.
- Türkçe UI metni kullanılmıştır.
- Gereksiz yeniden yazımlar yapılmamıştır.
- Her yeni ekran/widget, navigation_screen.dart veya ilgili parent'tan erişilebilirdir.