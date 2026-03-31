# Akilli Tarim Asistani (Smart Agri)
## Proje Teklifi / Project Proposal

---

**Ders:** FENG 498 - Bitirme Projesi  
**Tarih:** Mart 2026  
**Versiyon:** 1.0  
**Platform:** Android / iOS / Web / Desktop (Flutter Cross-Platform)

---

## Icindekiler

1. [Yonetici Ozeti](#1-yonetici-ozeti)
2. [Problem Tanimi](#2-problem-tanimi)
3. [Cozum Onerisi](#3-cozum-onerisi)
4. [Mevcut Ozellikler](#4-mevcut-ozellikler)
5. [Planlanan Ozellikler](#5-planlanan-ozellikler)
6. [Sistem Mimarisi](#6-sistem-mimarisi)
7. [Veritabani Tasarimi](#7-veritabani-tasarimi)
8. [API Entegrasyonlari](#8-api-entegrasyonlari)
9. [Kullanici Arayuzu Tasarimi](#9-kullanici-arayuzu-tasarimi)
10. [Teknoloji Yigini](#10-teknoloji-yigini)
11. [Proje Zaman Cizelgesi](#11-proje-zaman-cizelgesi)
12. [Risk Analizi](#12-risk-analizi)
13. [Sonuc ve Gelecek Vizyon](#13-sonuc-ve-gelecek-vizyon)

---

## 1. Yonetici Ozeti

**Akilli Tarim Asistani**, yapay zeka destekli, konum tabanli ve gercek zamanli cevresel veri analizi yapan bir mobil tarim uygulamasidir. Uygulama, ciftcilere ve hobi bahcecilerine bitki teshisi, tarla analizi, ekim planlama, gubreleme takvimi ve haftalik hava durumu tahminleri gibi kapsamli tarimsal danismanlik hizmetleri sunar. Google Gemini AI, PlantNet, Imagga, Perenual, OpenWeatherMap, Open-Meteo, SoilGrids ve Agromonitoring gibi 9 farkli API'yi entegre ederek, kullanicinin konumuna ozel, veri odakli ve kisisellestirilmis tarim onerileri uretir. Firebase Firestore bulut veritabani ve Hive yerel veritabani ile hibrit bir veri katmani kullanilarak hem cevrimdisi hem cevrimici kullanim desteklenmektedir.

---

## 2. Problem Tanimi

### 2.1 Turkiye'de Tarimsal Zorluklar

Turkiye, 23.2 milyon hektar ekilebilir arazi ile onemli bir tarim ulkesi olmasina ragmen, kucuk ve orta olcekli ciftciler ciddi sorunlarla karsi karsiya kalmaktadir:

| Problem | Aciklama |
|---------|----------|
| **Bilgiye Erisim Eksikligi** | Ciftcilerin %65'i modern tarim tekniklerine ve guncel iklim verilerine erisememektedir. |
| **Yanlis Zamanlama** | Ekim, sulama ve gubreleme zamanlamasindaki hatalar verim kayiplarina yol acmaktadir. |
| **Toprak Analizi Yetersizligi** | Toprak pH, nem ve sicaklik olcumlerinin yapilamamasi nedeniyle yanlis urun secimi yapilmaktadir. |
| **Iklim Degisikligi** | Degisen hava kosullari, geleneksel tarim takvimlerini gecersiz kilmaktadir. |
| **Hastalik Tespiti** | Bitki hastaliklari ve zararlilari zamaninda tespit edilememekte, urun kaybi yasamaktadir. |
| **Dijital Okur-Yazarlik** | Mevcut tarim yazilimlari karmasik arayuzlere sahip olup, kucuk ciftciler icin erisilebilir degildir. |

### 2.2 Mevcut Cozumlerin Yetersizligi

Piyasadaki mevcut tarim uygulamalari genellikle su eksikliklere sahiptir:

- **Statik bilgi:** Sabit veri tabanlari kullanan uygulamalar, bolgesel kosula ve iklim farkliligina uyum saglayamamaktadir.
- **Tek katmanli analiz:** Yalnizca hava durumu veya yalnizca bitki teshisi yapan uygulamalar, butunlesik bir analiz sunamamaktadir.
- **Yuksek maliyet:** Profesyonel tarim yazilimlari kucuk ciftciler icin ekonomik olarak erisilebilir degildir.
- **Dil bariyeri:** Cogu uygulama Ingilizce olup, Turkce icerik ve Turkiye'ye ozgu tarimsal bilgi sunamamaktadir.

---

## 3. Cozum Onerisi

### 3.1 Genel Bakis

Akilli Tarim Asistani, yukaridaki problemleri su yaklasimlarla cozer:

```
+------------------------------------------------------------------+
|                    AKILLI TARIM ASISTANI                          |
|                                                                  |
|  +------------+  +----------+  +-----------+  +---------------+  |
|  | Yapay Zeka |  | Gercek   |  | Konum     |  | Coklu API     |  |
|  | Destekli   |  | Zamanli  |  | Tabanli   |  | Entegrasyonu  |  |
|  | Analiz     |  | Veri     |  | Kisisel-  |  | (9 Harici     |  |
|  | (Gemini)   |  | Akisi    |  | lestirme  |  |  Servis)      |  |
|  +------------+  +----------+  +-----------+  +---------------+  |
|                                                                  |
|  Sonuc: Kisisellestirilmis, Veri Odakli Tarim Danismanligi       |
+------------------------------------------------------------------+
```

### 3.2 Temel Degerler

1. **Yapay Zeka Destekli:** Google Gemini 2.5 Flash/Pro modelleri ile dogal dil isleme ve goruntu analizi.
2. **Gercek Zamanli:** 9 API'den anlik cevresel veri toplama (sicaklik, nem, pH, toprak nemi, ruzgar).
3. **Konum Tabanli:** GPS konum verisi ile bolgeye ozel oneriler.
4. **Hibrit Veri Katmani:** Firestore (bulut) + Hive (yerel) ile cevrimdisi/cevrimici destek.
5. **Turkce Odakli:** Tum icerik ve oneriler Turkce olarak sunulur.
6. **Erisilebilir:** Basit ve sezgisel arayuz, kucuk ciftcilerden profesyonel uretimcilere kadar herkes icin.

---

## 4. Mevcut Ozellikler

### 4.1 Ozet Paneli (Dashboard)

**Amac:** Kullanicinin bulundugu konumdaki anlik cevresel kosullari tek bir ekranda gorsellestirmek.

**Teknik Detaylar:**
- OpenWeatherMap API ile anlik sicaklik, nem ve ruzgar verisi
- SoilGrids API ile toprak pH degeri (0-5cm derinlik)
- Geolocator ve Geocoding paketleri ile konum tespiti ve adres cozumleme
- Hive veritabanina anlik verileri arsivleme ozelligi
- Glass-morphism (cam efekti) tasarimli kartlar ile modern UI
- Hava durumuna gore dinamik arka plan (gunesli/yagmurlu/bulutlu)
- Fade animasyonu ile akici veri yukleme

```
+-----------------------------------------------+
|            Anlik Cevre Analizi                 |
+-----------------------------------------------+
|                                               |
|   +---------------------------------------+   |
|   |  Konum: Kadikoy, Istanbul             |   |
|   |  Koor: 40.9823, 29.0507              |   |
|   +---------------------------------------+   |
|                                               |
|   +-----------------+ +-----------------+     |
|   | Sicaklik        | | Nem             |     |
|   | 24 C            | | %62             |     |
|   +-----------------+ +-----------------+     |
|                                               |
|   +-----------------+ +-----------------+     |
|   | Ruzgar          | | Toprak pH       |     |
|   | 3.2 m/s         | | 6.8             |     |
|   +-----------------+ +-----------------+     |
|                                               |
|   [====== BU ANALIZI ARSIVLE ======]          |
|                                               |
+-----------------------------------------------+
```

**Veri Akisi:**
```
Kullanici Ekrani Acar
        |
        v
    GPS Konum Al
        |
        +---> Geocoding (Adres Cozumle)
        |
        +---> OpenWeatherMap (Sicaklik, Nem, Ruzgar)
        |
        +---> SoilGrids (Toprak pH)
        |
        v
    Verileri Glass Kartlarda Goster
        |
        v
    [Arsivle] ---> Hive Box: 'agri_history'
```

---

### 4.2 Akilli Rehber (Growing Guide)

**Amac:** Kullanicinin yetistirmek istedigi bitki hakkinda konumuna, hava durumuna ve toprak kosullarina ozel detayli bir rehber sunmak.

**Teknik Detaylar:**
- Cift veri kaynagi: Firestore (ana veritabani) + Gemini AI (fallback)
- 7 gunluk hava tahmini entegrasyonu (Open-Meteo API)
- Toprak pH uyari sistemi (asidik/bazik toprak icin otomatik uyari)
- Hobi / Profesyonel olcek secimi
- Haftalik sulama plani (hava tahminlerine gore dinamik)
- Kusbakisi tarla gorsellestirme animasyonu (CustomPainter)

**Rehber Icerigi:**

| Bilgi Alani | Kaynak | Aciklama |
|-------------|--------|----------|
| Bilimsel ad, yasam dongusu | Firestore / Gemini | Bitkinin taksonomik bilgileri |
| Ideal sicaklik & pH araligi | Firestore / Gemini | Min-max deger araliklari |
| Gunes ihtiyaci | Firestore / Gemini | Saat cinsinden gunluk gunes |
| Ekim derinligi, sira/bitki arasi | Gemini AI | cm cinsinden olcumler |
| Sulama tipi ve takvimi | Gemini AI | Damla/yagmurlama + haftalik plan |
| Gubreleme programi | Gemini AI | NPK orani, uygulama zamani |
| Hastalik & zararli bilgisi | Firestore / Gemini | Onleme yontemleri ile |
| Companion planting | Gemini AI | Birlikte ekilecek/ekilmeyecek bitkiler |
| Bolgesel uygunluk skoru | Gemini AI | %0-100 uygunluk degerlendirmesi |
| 7 gunluk hava tahmini | Open-Meteo | Sicaklik, yagis, nem, ruzgar |

**Kusbakisi Tarla Gorsellestirme:**
```
+--------------------------------------------------+
|   Kusbakisi Tarla Gorunumu (CustomPainter)       |
+--------------------------------------------------+
|                                                  |
|  Faz 1: Tarla cercevesi cizilir                 |
|  Faz 2: Ekim siralari belirir (kesikli cizgi)   |
|  Faz 3: Bitkiler siralara yerlesir (yesil nok.) |
|  Faz 4: Sulama hatlari eklenir (mavi cizgi)     |
|  Faz 5: Gubre bantlari gosterilir (turuncu)     |
|                                                  |
|  [Ekim] [Sulama] [Gubre]  <-- Katman toggle     |
|                                                  |
|  --- Temsili 5m x 3m alan ---                   |
|                                                  |
|  . . . . . .    <50cm>                           |
|  |----|----|----|                                 |
|  . . . . . .    Sira arasi: 70cm                 |
|  ===mavi===     Sulama hatti                     |
|  . . . . . .                                     |
|  ///turuncu///  Gubre bandi: 15cm                |
|  . . . . . .                                     |
|                                                  |
+--------------------------------------------------+
```

---

### 4.3 Tarlalarim (My Crops)

**Amac:** Kullanicinin tarlalarini kaydedip yonetmesi, harita uzerinde alan hesaplamasi yapmasi ve tarla bazinda detayli analiz alabilmesi.

**Teknik Detaylar:**
- Hive veritabaninda CRUD (Olustur/Oku/Guncelle/Sil) tarla yonetimi
- Google Maps entegrasyonu ile haritada tarla siniri cizme
- Maps Toolkit ile polygon alan hesabi (dekar cinsinden)
- Her tarla icin konum, alan, ekili urun ve ekstra not kaydi
- Tarla detay ekraninda AI destekli ekim oneri sistemi

**Tarla Kayit Yapisi:**
```
+-------------------------------------------+
|  TARLALARIM                               |
+-------------------------------------------+
|                                           |
|  +-------------------------------------+ |
|  | Tarla: Bahce Arkasi                  | |
|  | Alan: 2.5 Dekar                      | |
|  | Urun: Domates                        | |
|  | Konum: 40.98, 29.05                  | |
|  | [Detay]  [Sil]                       | |
|  +-------------------------------------+ |
|                                           |
|  +-------------------------------------+ |
|  | Tarla: Dag Tarlasi                   | |
|  | Alan: 12 Dekar                       | |
|  | Urun: Bugday                         | |
|  | [Detay]  [Sil]                       | |
|  +-------------------------------------+ |
|                                           |
|  [Haritadan Tarla Ciz]  [+]              |
+-------------------------------------------+
```

**Harita Alan Hesaplama Akisi:**
```
Google Maps Ekrani
        |
        v
Kullanici Tarla Koselerni Isaretler (Polygon)
        |
        v
Maps Toolkit: computeArea(polygon)
        |
        v
Sonuc: X dekar (10,000 m2 = 1 dekar)
        |
        v
Hive Box: 'user_crops' a Kaydet
```

---

### 4.4 AI Kamera Analizi

**Amac:** Kamera veya galeriden yuklenen fotograflari yapay zeka ile analiz ederek bitki teshisi, tarla degerlendirmesi veya cevresel rapor sunmak.

**Teknik Detaylar:**
- 3 asamali analiz pipeline:
  1. **Gatekeeper (Imagga):** Fotograf icerigi siniflandirma (bitki mi? tarla mi? ilgisiz mi?)
  2. **Yonlendirme:** Icerige gore farkli analiz yoluna yonlendirme
  3. **Detayli Analiz:** PlantNet + Perenual (bitki) veya Gemini AI (tarla/ilgisiz)

**Analiz Senaryolari:**

```
                    Fotograf Yukleme
                          |
                          v
                 +------------------+
                 |   IMAGGA API     |
                 |   (Gatekeeper)   |
                 +--------+---------+
                          |
            +-------------+-------------+
            |             |             |
            v             v             v
     +-----------+  +-----------+  +-----------+
     |  BITKI    |  |   TARLA   |  |  ILGISIZ  |
     |  Senaryo  |  |  Senaryo  |  |  Senaryo  |
     +-----------+  +-----------+  +-----------+
            |             |             |
            v             v             v
     +-----------+  +-----------+  +-----------+
     | PlantNet  |  | CropRules |  | Gemini    |
     | Teshis    |  | Dinamik   |  | Vision    |
     |     |     |  | Oneriler  |  | + Bolge   |
     |     v     |  | (Gemini)  |  | Raporu    |
     | Perenual  |  +-----------+  +-----------+
     | Detaylar  |
     |     |     |
     |     v     |
     | Gemini    |
     | Fallback  |
     +-----------+
```

**Senaryo A - Bitki Teshisi:**
- PlantNet API ile botanik teshis (guvenilirlik yuzdesi ile)
- Perenual API ile detayli bilgi (sulama, gunes, toprak, hasat)
- Perenual bos donerse Gemini AI fallback
- Deterministik basari sansi hesaplama (formul bazli, LLM degil)
- Konum bazli sulama takvimi ve gubre onerisi

**Senaryo B - Tarla Analizi:**
- 4 API'den paralel cevresel veri toplama (timeout korumasli)
- Gemini AI ile en uygun 5 urun onerisi (uygunluk skoru ile)
- pH-bazli otomatik gubreleme recetesi
- Haftalik hava durumu etki analizi

**Senaryo C - Ilgisiz Fotograf:**
- Gemini Vision ile fotograf yorumu
- Bolgesel cevresel rapor sunumu (sensorden gelen verilerle)

---

### 4.5 Ortak Arsiv (Plant Database)

**Amac:** Gecmis AI analizlerini ve cevresel okumalari arsivleyerek kullanicinin tarimsal karar gecmisini takip etmesini saglamak.

**Teknik Detaylar:**
- Iki sekmeli arayuz: AI Analiz Gecmisi + Hizli Cevre Gecmisi
- Hive Box: `recognized_plants` (AI analizleri) ve `agri_history` (cevre okumalari)
- Tarih/saat damgali kayit sistemi
- Alt sayfa (Bottom Sheet) ile detayli goruntuleme

---

### 4.6 Kusbakisi Tarla Gorsellestirme

**Amac:** Kayitli tarlalarin yukaridan bakis gorunumunde bitkinin nasil dikildigini, sulama hatlarinin nereye dosendigi ve gubrelemenin nasil yapiladigini cm cinsinden olculerle animasyonlu gostermek.

**Teknik Detaylar:**
- `CustomPainter` ile canvas uzerinde cizim
- 5 fazli animasyon (tarla -> siralar -> bitkiler -> sulama -> gubre)
- `SegmentedButton` ile katman toggle (ekim/sulama/gubre)
- Olcu oklari ve etiketler (TextPainter ile)
- Temsili 5m x 3m pencere (performans icin max ~8 sira, ~12 bitki/sira)

---

## 5. Planlanan Ozellikler

### 5.1 Cevrimici Tarla Takibi

**Hedef:** Kullanicilarin tarlalarini gercek zamanli olarak buluttan takip edebilmesi.

**Teknik Plan:**
- Firebase Firestore ile tarla durumu senkronizasyonu
- Anlık veri akisi: sicaklik, nem, pH degisimleri
- Coklu cihaz destegi (telefon + tablet)
- Tarla bazinda zaman serisi verileri

```
+--------------------+     +------------------+     +-----------------+
|  Mobil Uygulama    | <-> |  Firebase        | <-> | Web Dashboard   |
|  (Saha Calismasi)  |     |  Firestore       |     | (Ofis Takibi)   |
+--------------------+     +------------------+     +-----------------+
         |                         |
         v                         v
   Sensorden Veri Al       Bulutta Sakla & Sync
```

### 5.2 Bildirim Sistemi

**Hedef:** Kritik tarimsal olaylarda kullaniciyi proaktif olarak bilgilendirmek.

**Teknik Plan:**
- `flutter_local_notifications` ile yerel bildirimler (halihazirda dependency'de mevcut)
- Firebase Cloud Messaging (FCM) ile push bildirimler
- Bildirim turleri:
  - Sulama hatirlatmasi (haftalik plana gore)
  - Don uyarisi (sicaklik 0 C altina dusunce)
  - Yagis uyarisi (asiri yagis beklentisi)
  - Gubreleme zamani hatirlatmasi
  - Hasat zamani bildirimi

```
Bildirim Akisi:
                                                        
  Open-Meteo API ---> Don Tespiti (< 0 C) ---> FCM Push ---> Kullanici
                                                        
  Sulama Takvimi ---> Gun Kontrolu ---------> Yerel -----> Kullanici
                                             Bildirim
                                                        
  Hasat Suresi ----> Countdown Timer -------> FCM Push ---> Kullanici
```

### 5.3 Saatlik Hava Analizi

**Hedef:** Haftalik tahmin ekraninda bir gune tiklandiginda, o gunun saat saat hava detayini gostermek.

**Teknik Plan:**
- Open-Meteo hourly API entegrasyonu
- Parametreler: `hourly=temperature_2m,relative_humidity_2m,precipitation,windspeed_10m`
- Saat bazli grafik gorsellestirme
- Sulama zamanlama onerisi (en uygun saat)

```
Haftalik Tahmin Ekrani:
+------+------+------+------+------+------+------+
| Pzt  | Sal  | Car  | Per  | Cum  | Cts  | Paz  |
| 22 C | 19 C | 24 C | 25 C | 20 C | 18 C | 21 C |
| 0 mm | 5 mm | 0 mm | 0 mm | 12mm | 8 mm | 2 mm |
+------+------+------+------+------+------+------+
         |
         v  (Tiklama)
+--------------------------------------------------+
|  SALI - Saatlik Detay                            |
+--------------------------------------------------+
|  06:00  15 C  %78  0mm   Sulama icin ideal saat  |
|  09:00  17 C  %65  0mm                           |
|  12:00  19 C  %52  2mm   Hafif yagis             |
|  15:00  20 C  %48  3mm   Yagis devam             |
|  18:00  18 C  %60  0mm                           |
|  21:00  16 C  %72  0mm                           |
+--------------------------------------------------+
```

### 5.4 Haftalik Tarla Raporu

**Hedef:** Her tarla icin otomatik haftalik ozet rapor olusturmak.

**Teknik Plan:**
- Haftalik veri birikimi: sicaklik trendi, toplam yagis, pH degisimi
- Gemini AI ile otomatik yorum ve oneri
- PDF export secenegi
- Karsilastirmali analiz (bu hafta vs. gecen hafta)

```
+--------------------------------------------------+
|  HAFTALIK TARLA RAPORU - Bahce Arkasi            |
|  22.03.2026 - 29.03.2026                         |
+--------------------------------------------------+
|                                                  |
|  Sicaklik Trendi:  18 C --> 24 C  (Yukselis)     |
|  Toplam Yagis:     12.5 mm                       |
|  Ort. Nem:         %58                           |
|  pH Degisimi:      6.7 --> 6.8 (Stabil)          |
|                                                  |
|  AI Yorumu:                                      |
|  "Sicaklik artisi domates icin olumlu. Yagis     |
|   yeterli, ek sulama gerekmeyebilir. pH stabil   |
|   ve ideal aralikta."                            |
|                                                  |
|  Oneriler:                                       |
|  - Yaprak gubresi uygulama zamani yaklasti        |
|  - Don riski yok, serada havalandirma acin       |
|                                                  |
+--------------------------------------------------+
```

### 5.5 Uydu Tabanli Canli Hava ve Bitki Sagligi Takibi

**Hedef:** Uydu goruntuleri ile bitki sagligi (NDVI) ve arazi durumunu izlemek.

**Teknik Plan:**
- Copernicus / Sentinel-2 uydu verileri
- NDVI (Normalized Difference Vegetation Index) hesaplama
- Harita uzerinde bitki sagligi renk kodlamasi
- Agromonitoring API uzerinden uydu goruntuleri

```
NDVI Renk Skalasi:
+--------------------------------------------------+
|                                                  |
|  0.0 -------- 0.3 -------- 0.6 -------- 1.0     |
|  [KIRMIZI]    [SARI]       [ACIK YESIL]  [KOYU  |
|  Ciplak       Zayif        Saglikli      YESIL] |
|  Toprak       Bitki        Bitki         Gur    |
|               Ortusu       Ortusu        Bitki  |
|                                                  |
+--------------------------------------------------+
```

### 5.6 Coklu Kullanici ve Paylasim

**Hedef:** Birden fazla kullanicinin tarla verilerini paylasabilmesi ve isbirligi yapabilmesi.

**Teknik Plan:**
- Firebase Authentication ile kullanici yonetimi
- Tarla bazinda paylasim izinleri
- Aile/ortaklik tarim destegi
- Topluluk bazli bilgi paylasimi

---

## 6. Sistem Mimarisi

### 6.1 Genel Mimari Diyagrami

```
+================================================================+
|                       SUNUM KATMANI                            |
|                    (Flutter Mobile App)                         |
|                                                                |
|  +--------+ +--------+ +--------+ +---------+ +--------+      |
|  | Ozet   | | Rehber | | Tarla  | | Kamera  | | Arsiv  |      |
|  | Paneli | | Ekrani | | Yonet. | | Analiz  | | Ekrani |      |
|  +---+----+ +---+----+ +---+----+ +----+----+ +---+----+      |
|      |          |          |           |           |            |
|      +----------+----------+-----------+-----------+            |
|                            |                                   |
+============================|===================================+
                             |
+============================|===================================+
|                    SERVIS KATMANI                               |
|                                                                |
|  +-----------------------------------------------------------+ |
|  |                    AgriService                             | |
|  |  (Tum API orchestration, veri donusumu, fallback mantigi) | |
|  +----+----------+----------+-----------+----------+----------+ |
|       |          |          |           |          |            |
|  +----+---+ +----+---+ +---+----+ +----+---+ +---+----+       |
|  |Location| |Weather | | Soil   | | Image  | | AI     |       |
|  |Utils   | |Service | |Service | |Analysis| |Engine  |       |
|  +--------+ +--------+ +--------+ +--------+ +--------+       |
|                                                                |
|  +-----------------------------------------------------------+ |
|  |                    CropRules                               | |
|  |  (Dinamik urun oneri motoru - Gemini AI tabanli)          | |
|  +-----------------------------------------------------------+ |
|                                                                |
+============================|===================================+
                             |
+============================|===================================+
|                    VERI KATMANI                                 |
|                                                                |
|  +------------------+              +-------------------------+ |
|  | YEREL (Hive)     |              | BULUT (Firebase)        | |
|  |                  |              |                         | |
|  | agri_history     |              | Firestore               | |
|  | user_crops       |     <--->    |   crops (koleksiyon)    | |
|  | recognized_plants|              |   users (planlanan)     | |
|  +------------------+              |   fields (planlanan)    | |
|                                    +-------------------------+ |
|                                                                |
+================================================================+
```

### 6.2 API Entegrasyon Akis Diyagrami

```
+================================================================+
|                     HARICI API KATMANI                          |
+================================================================+
|                                                                |
|  YAPAY ZEKA SERVISLERI           CEVRE VERI SERVISLERI         |
|  +--------------------+         +------------------------+     |
|  | Google Gemini AI   |         | OpenWeatherMap         |     |
|  | - Bitki rehberi    |         | - Anlik sicaklik       |     |
|  | - Tarla onerisi    |         | - Nem, ruzgar          |     |
|  | - Vision analizi   |         +------------------------+     |
|  | - Fallback bilgi   |                                        |
|  +--------------------+         +------------------------+     |
|                                 | Open-Meteo             |     |
|  +--------------------+         | - 7 gunluk tahmin      |     |
|  | PlantNet API       |         | - Saatlik tahmin       |     |
|  | - Bitki teshisi    |         +------------------------+     |
|  | - Botanik sinif.   |                                        |
|  +--------------------+         +------------------------+     |
|                                 | SoilGrids (ISRIC)     |     |
|  +--------------------+         | - Toprak pH            |     |
|  | Imagga API         |         | - 0-5cm derinlik       |     |
|  | - Goruntu etiket.  |         +------------------------+     |
|  | - Icerik sinif.    |                                        |
|  +--------------------+         +------------------------+     |
|                                 | Agromonitoring         |     |
|  +--------------------+         | - Toprak nem           |     |
|  | Perenual API       |         | - Toprak sicakligi     |     |
|  | - Bitki detaylari  |         | - Polygon olusturma    |     |
|  | - Bakim rehberi    |         +------------------------+     |
|  +--------------------+                                        |
|                                 +------------------------+     |
|                                 | Google Maps            |     |
|                                 | - Harita gorunumu      |     |
|                                 | - Alan hesaplama       |     |
|                                 +------------------------+     |
|                                                                |
+================================================================+
```

### 6.3 Veri Akis Mimari Desenleri

**Kullanilan Desenler:**

| Desen | Kullanim Alani | Aciklama |
|-------|----------------|----------|
| **Service Layer** | `AgriService` | Tum is mantigi tek bir servis sinifinda; ekranlar sadece UI |
| **Fallback Chain** | Bitki teshisi | Perenual -> Gemini AI (API bos donerse sonraki kaynaga gec) |
| **Parallel Fetch** | Cevre verileri | `Future.wait()` ile 4 API paralel cagirilir, timeout korumasli |
| **Gatekeeper** | Kamera analizi | Imagga ilk filtre, sonuca gore dallanma |
| **Hybrid Storage** | Veri katmani | Firestore (paylasilabilir) + Hive (hizli, cevrimdisi) |
| **Graceful Degradation** | Tum API cagrilari | Her API bagimsiz try-catch; birinin cokmesi sistemi durdurmaz |

---

## 7. Veritabani Tasarimi

### 7.1 Yerel Veritabani (Hive)

Hive, NoSQL key-value store olup Flutter'da yuksek performansli yerel depolama saglar.

```
+================================================================+
|                        HIVE BOXES                              |
+================================================================+
|                                                                |
|  BOX: agri_history                                             |
|  +----------------------------------------------------------+ |
|  | Key  | date (String)  | temp (String) | ph (String)      | |
|  |      | location (Str) |               |                  | |
|  +----------------------------------------------------------+ |
|  | Ornek: "23.03.2026 14:30" | "24 C" | "6.8" | "Kadikoy"  | |
|  +----------------------------------------------------------+ |
|                                                                |
|  BOX: user_crops                                               |
|  +----------------------------------------------------------+ |
|  | Key  | name (String)     | area (double)    | lat (dbl)  | |
|  |      | lng (double)      | crop (String)    | note (Str) | |
|  |      | points (List)     | date (String)    |            | |
|  +----------------------------------------------------------+ |
|                                                                |
|  BOX: recognized_plants                                        |
|  +----------------------------------------------------------+ |
|  | Key  | type (String)     | title (String)                | |
|  |      | description (Str) | date (String)                 | |
|  +----------------------------------------------------------+ |
|                                                                |
+================================================================+
```

### 7.2 Bulut Veritabani (Firebase Firestore)

```
+================================================================+
|                    FIRESTORE KOLEKSIYONLARI                     |
+================================================================+
|                                                                |
|  MEVCUT: crops (koleksiyon)                                    |
|  +----------------------------------------------------------+ |
|  | Dokuman ID: bitki adi (orn: "domates")                    | |
|  |                                                          | |
|  | scientific: String        | desc: String                 | |
|  | cycle: String             | sunlight: String              | |
|  | growth: String            | care: String                  | |
|  | indoor: Boolean           | drought: Boolean              | |
|  | ideal_temp_min: Number    | ideal_temp_max: Number        | |
|  | ideal_ph_min: Number      | ideal_ph_max: Number          | |
|  | sunlight_hours: Number    | harvest_days: Number          | |
|  | best_planting_months: Str | companion_plants: String      | |
|  | avoid_plants: String      | pest_prevention: String       | |
|  | planting_depth_cm: Number | row_spacing_cm: Number        | |
|  | plant_spacing_cm: Number  | seeds_per_dekar: Number       | |
|  | irrigation_type: String   | irrigation_line_spacing_cm: N | |
|  | irrigation_dripper_sp: N  | daily_water_liters: Number    | |
|  | fertilizer_band_cm: Num   | fertilizer_depth_cm: Number   | |
|  | fertilizer_type: String   | fertilizer_schedule: String   | |
|  | region_uygunluk: Number   | region_note: String           | |
|  | pruning: String           | pests: String                 | |
|  | planting_tip: String      |                               | |
|  +----------------------------------------------------------+ |
|                                                                |
|  PLANLANAN: users (koleksiyon)                                 |
|  +----------------------------------------------------------+ |
|  | Dokuman ID: Firebase Auth UID                             | |
|  | displayName: String       | email: String                 | |
|  | createdAt: Timestamp      | fields: Array<Reference>     | |
|  | preferences: Map          | notificationToken: String     | |
|  +----------------------------------------------------------+ |
|                                                                |
|  PLANLANAN: fields (koleksiyon)                                |
|  +----------------------------------------------------------+ |
|  | Dokuman ID: auto-generated                                | |
|  | ownerId: String (UID)    | name: String                   | |
|  | area_dekar: Number       | location: GeoPoint             | |
|  | polygon: Array<GeoPoint> | currentCrop: String            | |
|  | plantingDate: Timestamp  | soilHistory: Array<Map>        | |
|  | weatherHistory: Array    | sharedWith: Array<UID>         | |
|  +----------------------------------------------------------+ |
|                                                                |
|  PLANLANAN: notifications (koleksiyon)                         |
|  +----------------------------------------------------------+ |
|  | Dokuman ID: auto-generated                                | |
|  | userId: String           | type: String (frost/water/..) | |
|  | fieldId: String          | message: String                | |
|  | scheduledAt: Timestamp   | sent: Boolean                  | |
|  | createdAt: Timestamp     |                                | |
|  +----------------------------------------------------------+ |
|                                                                |
+================================================================+
```

### 7.3 ER Diyagrami

```
+============+       1:N       +=============+
|   users    | --------------> |   fields    |
+============+                 +=============+
| uid (PK)   |                 | id (PK)     |
| displayName|                 | ownerId(FK) |
| email      |                 | name        |
| preferences|                 | area_dekar  |
+============+                 | location    |
      |                        | currentCrop |
      | 1:N                    | polygon     |
      v                        +=============+
+=================+                  |
| notifications   |                  | 1:N
+=================+                  v
| id (PK)         |           +=============+
| userId (FK)     |           | soil_history|
| fieldId (FK)    |           +=============+
| type            |           | timestamp   |
| message         |           | ph          |
| scheduledAt     |           | moisture    |
| sent            |           | temp        |
+=================+           +=============+

+=============+       (Bagimsiz - Referans Veritabani)
|   crops     |
+=============+
| name (PK)   |
| scientific   |
| ideal_temp   |
| ideal_ph     |
| spacing      |
| irrigation   |
| ...          |
+=============+
```

---

## 8. API Entegrasyonlari

### 8.1 Google Gemini AI

| Ozellik | Deger |
|---------|-------|
| **Model** | gemini-2.5-flash (rehber) / gemini-2.5-pro (vision) |
| **Kullanim** | Bitki rehberi olusturma, tarla oneri motoru, goruntu analizi, fallback bilgi |
| **Entegrasyon** | `google_generative_ai` Flutter paketi |
| **Prompt Dili** | Turkce |
| **Cikti Formati** | Yapilandirilmis JSON |
| **Fallback** | Perenual API bos donerse devreye girer |

**Gemini Kullanim Alanlari:**
1. `getPlantGuide()` - Firestore'da bulunmayan bitkiler icin tam rehber
2. `getDynamicRecommendations()` - Tarla analizi icin 5 en uygun urun
3. `analyzeImage()` (Senaryo C) - Ilgisiz fotograf + bolge raporu
4. `_fetchAIPlantDetails()` - Perenual bos donerse bitki bilgisi

---

### 8.2 PlantNet API

| Ozellik | Deger |
|---------|-------|
| **Endpoint** | `https://my-api.plantnet.org/v2/identify/all` |
| **Kullanim** | Fotograftan bitki teshisi |
| **Metod** | POST (multipart/form-data) |
| **Cikti** | Bilimsel ad, aile, guvenilirlik skoru, yaygin adlar |
| **Parametre** | `organs=auto` (otomatik organ tespiti) |

---

### 8.3 Imagga API

| Ozellik | Deger |
|---------|-------|
| **Endpoint** | `https://api.imagga.com/v2/tags` |
| **Kullanim** | Goruntu icerik siniflandirma (gatekeeper) |
| **Metod** | POST (multipart, Basic Auth) |
| **Cikti** | En yuksek 15 etiket (Ingilizce) |
| **Karar Mantigi** | Bitki anahtar kelimeleri (12 adet) vs. tarla anahtar kelimeleri (14 adet) |

---

### 8.4 Perenual API

| Ozellik | Deger |
|---------|-------|
| **Endpoint** | `https://perenual.com/api/v2/species-list` + `species/details/{id}` + `species-care-guide-list` |
| **Kullanim** | Detayli bitki bilgisi (sulama, gunes, toprak, hasat, zararli) |
| **Metod** | GET |
| **Fallback** | Bos donerse Gemini AI devreye girer |
| **Veri Alanlari** | 30+ alan: cycle, watering, sunlight, hardiness, propagation, pest_susceptibility vb. |

---

### 8.5 Agromonitoring API

| Ozellik | Deger |
|---------|-------|
| **Endpoint** | `https://api.agromonitoring.com/agro/1.0/polygons` + `soil` |
| **Kullanim** | Toprak nem orani ve toprak sicakligi (10cm derinlik) |
| **Metod** | POST (polygon olustur) -> GET (toprak verisi) -> DELETE (polygon temizle) |
| **Not** | Free tier siniri nedeniyle her sorguda polygon olusturulup silinir |

---

### 8.6 OpenWeatherMap API

| Ozellik | Deger |
|---------|-------|
| **Endpoint** | `https://api.openweathermap.org/data/2.5/weather` |
| **Kullanim** | Anlik sicaklik, nem, ruzgar hizi, hava durumu aciklamasi |
| **Metod** | GET |
| **Parametreler** | `units=metric`, `lang=tr` |
| **Timeout** | 5-8 saniye |

---

### 8.7 Open-Meteo API

| Ozellik | Deger |
|---------|-------|
| **Endpoint** | `https://api.open-meteo.com/v1/forecast` |
| **Kullanim** | 7 gunluk hava tahmini (sicaklik, yagis, nem, ruzgar, hava kodu) |
| **Metod** | GET |
| **Maliyet** | Ucretsiz (API key gerektirmez) |
| **Planlanan** | Saatlik veri entegrasyonu (`hourly` parametresi) |

---

### 8.8 SoilGrids (ISRIC)

| Ozellik | Deger |
|---------|-------|
| **Endpoint** | `https://rest.isric.org/soilgrids/v2.0/properties/query` |
| **Kullanim** | Toprak pH degeri (H2O bazli, 0-5cm derinlik) |
| **Metod** | GET |
| **Timeout** | 10 saniye (yavas olabilir) |
| **Donusum** | Ham deger / 10.0 = gercek pH |

---

### 8.9 Google Maps

| Ozellik | Deger |
|---------|-------|
| **Paketler** | `google_maps_flutter` + `maps_toolkit` |
| **Kullanim** | Harita gorunumu, tarla siniri cizme, polygon alan hesabi |
| **Hesaplama** | `SphericalUtil.computeArea()` ile metrekare -> dekar donusumu |

---

## 9. Kullanici Arayuzu Tasarimi

### 9.1 Tasarim Sistemi

| Ozellik | Deger |
|---------|-------|
| **Framework** | Material Design 3 (Material You) |
| **Tema Rengi** | Yesil `#2E7D32` (Tarim konseptine uygun) |
| **Parlaklık** | Acik mod (Light) |
| **AppBar** | Merkezi baslik, yuzen (elevation: 0), yesil arka plan |
| **Navigasyon** | 5 sekmeli alt navigasyon cubugu (NavigationBar) |
| **Kartlar** | Yuvarlak koseli (12-20px radius), golge efektli |
| **Ozel Efekt** | Glass-morphism (BackdropFilter) Dashboard'da |

### 9.2 Renk Paleti

```
Ana Renk:      #2E7D32  (Koyu Yesil - Primary)
Vurgu:         #4CAF50  (Acik Yesil - Indicator)
Arka Plan:     #FFFFFF  (Beyaz - Background)
Metin:         #212121  (Koyu Gri - On Surface)
Hata:          #D32F2F  (Kirmizi - Error)
Uyari:         #FF8F00  (Turuncu Amber - Warning)
Bilgi:         #1976D2  (Mavi - Info)
```

### 9.3 Ekran Akis Diyagrami

```
+================================================================+
|                    UYGULAMA AKIS DIYAGRAMI                      |
+================================================================+
|                                                                |
|                    Uygulama Baslatma                           |
|                          |                                     |
|                    Firebase Init                               |
|                    Hive Init                                   |
|                    .env Yukle                                  |
|                          |                                     |
|                          v                                     |
|              +------------------------+                        |
|              | Ana Navigasyon Ekrani  |                        |
|              | (IndexedStack)         |                        |
|              +------------------------+                        |
|              |   |   |   |   |                                 |
|   +----------+   |   |   |   +----------+                     |
|   |              |   |   |              |                     |
|   v              v   |   v              v                     |
| +------+  +-------+  | +--------+  +--------+                |
| | Ozet |  |Rehber |  | |Kamera  |  | Arsiv  |                |
| |Paneli|  |Ekrani |  | |Ekrani  |  | Ekrani |                |
| +------+  +---+---+  | +---+----+  +--------+                |
|   |            |      |     |                                  |
|   v            v      |     v                                  |
| [Arsiv-  [Haftalik    |  [Analiz Sonuc Ekrani]                |
|  le]      Su Karti]   |     |                                  |
|           [Kusbakisi  |     +-> Bitki Detay                   |
|            Tarla]     |     +-> Tarla Rapor                   |
|                       |     +-> Cevre Rapor                   |
|                       v                                        |
|                 +----------+                                   |
|                 | Tarla    |                                   |
|                 | Yonetimi |                                   |
|                 +----+-----+                                   |
|                      |                                         |
|             +--------+--------+                                |
|             |                 |                                 |
|             v                 v                                 |
|      +------------+   +------------+                           |
|      | Harita Alan |   | Tarla      |                          |
|      | Hesaplama   |   | Detay      |                          |
|      +------------+   +------+-----+                           |
|                              |                                 |
|                              v                                 |
|                       [Urun Eslestirme]                        |
|                                                                |
+================================================================+
```

### 9.4 Temel Ekran Wireframe'leri

**Rehber Ekrani:**
```
+------------------------------------------+
| [<]  Akilli Tarim Rehberi                |
+------------------------------------------+
| +--------------------------------------+ |
| |  Ne yetistirmek istiyorsunuz?        | |
| |  [____Domates____________] [ARA]     | |
| |                                      | |
| |  Olcek: (o) Hobi  ( ) Profesyonel   | |
| +--------------------------------------+ |
|                                          |
| +--------------------------------------+ |
| |  DOMATES REHBERI                     | |
| |  Bilimsel: Solanum lycopersicum      | |
| |  Dongu: Tek Yillik                   | |
| |  Ideal: 18-30 C, pH 5.5-7.0         | |
| +--------------------------------------+ |
|                                          |
| +--------------------------------------+ |
| |  7 GUNLUK HAVA TAHMINI              | |
| |  [Pzt][Sal][Car][Per][Cum][Cts][Paz] | |
| |   22   19   24   25   20   18   21   | |
| +--------------------------------------+ |
|                                          |
| +--------------------------------------+ |
| |  HAFTALIK SULAMA PLANI               | |
| |  Pzt: 2.5L  "Normal sulama"         | |
| |  Sal: 1.0L  "Yagis var, azalt"      | |
| |  ...                                 | |
| +--------------------------------------+ |
|                                          |
| +--------------------------------------+ |
| |  KUSBAKISI TARLA GORUNUMU           | |
| |  [Animasyonlu Canvas]               | |
| +--------------------------------------+ |
+------------------------------------------+
| [Ozet] [Rehber] [Tarla] [Kamera] [Arsiv]|
+------------------------------------------+
```

---

## 10. Teknoloji Yigini

### 10.1 Istemci (Frontend)

| Kategori | Teknoloji | Versiyon | Kullanim Amaci |
|----------|-----------|----------|----------------|
| Framework | Flutter | 3.x | Cross-platform mobil uygulama |
| Dil | Dart | ^3.5.0 | Uygulama gelistirme dili |
| Tasarim | Material Design 3 | - | Modern UI/UX |
| Konum | geolocator | ^11.0.0 | GPS konum erisimi |
| Konum | geocoding | ^4.0.0 | Koordinat -> adres donusumu |
| Harita | google_maps_flutter | ^2.16.0 | Harita gorunumu ve polygon |
| Harita | maps_toolkit | ^3.1.0 | Alan hesaplama (computeArea) |
| Goruntu | image_picker | ^1.1.2 | Kamera ve galeri erisimi |
| Tarih | intl | ^0.20.2 | Tarih formatlama (dd.MM.yyyy) |
| Ceviri | translator | ^1.0.4+1 | Coklu dil destegi |
| Bildirim | flutter_local_notifications | ^17.0.0 | Yerel bildirimler |
| Ortam | flutter_dotenv | ^5.1.0 | .env dosyasindan API anahtarlari |

### 10.2 Backend / Bulut

| Kategori | Teknoloji | Versiyon | Kullanim Amaci |
|----------|-----------|----------|----------------|
| BaaS | Firebase | - | Bulut altyapisi |
| Veritabani | Cloud Firestore | ^6.2.0 | Bitki veritabani (bulut) |
| Auth | Firebase Core | ^4.6.0 | Firebase baslangic |
| Veritabani | Hive | ^2.2.3 | Yerel NoSQL depolama |
| Veritabani | hive_flutter | ^1.1.0 | Hive Flutter entegrasyonu |
| HTTP | http | ^1.2.0 | REST API cagrilari |

### 10.3 Yapay Zeka ve Harici API'ler

| Kategori | Teknoloji | Kullanim Amaci |
|----------|-----------|----------------|
| AI | Google Gemini 2.5 Flash/Pro | Metin ve goruntu analizi |
| AI | google_generative_ai ^0.4.6 | Gemini Flutter SDK |
| Bitki | PlantNet API | Fotograftan bitki teshisi |
| Goruntu | Imagga API | Goruntu siniflandirma |
| Bitki | Perenual API v2 | Detayli bitki bilgi veritabani |
| Toprak | Agromonitoring API | Toprak nem/sicaklik |
| Hava | OpenWeatherMap API | Anlik hava durumu |
| Hava | Open-Meteo API | 7 gunluk/saatlik tahmin |
| Toprak | SoilGrids (ISRIC) | Toprak pH haritalama |
| Harita | Google Maps Platform | Harita ve konum servisleri |

---

## 11. Proje Zaman Cizelgesi

### 11.1 Faz Plani

```
+================================================================+
|  FAZ  |  SURE    |  GOREVLER                                   |
+================================================================+
|       |          |                                              |
| F1    | Hafta    | ANALIZ & TASARIM                             |
|       | 1-2      | - Gereksinim analizi                        |
|       |          | - Sistem mimarisi tasarimi                   |
|       |          | - Veritabani sema tasarimi                   |
|       |          | - API arastirmasi ve degerlendirme            |
|       |          | - UI/UX wireframe tasarimi                   |
+-------+----------+----------------------------------------------+
|       |          |                                              |
| F2    | Hafta    | TEMEL ALTYAPI                                |
|       | 3-5      | - Flutter proje kurulumu                     |
|       |          | - Firebase entegrasyonu                      |
|       |          | - Hive yerel DB kurulumu                    |
|       |          | - Konum servisleri entegrasyonu              |
|       |          | - AgriService iskelet yapisi                 |
+-------+----------+----------------------------------------------+
|       |          |                                              |
| F3    | Hafta    | ANA OZELLIKLER - I                           |
|       | 6-9      | - Dashboard ekrani (hava, pH, nem)          |
|       |          | - Kamera analizi (Imagga + PlantNet)        |
|       |          | - Gemini AI entegrasyonu                    |
|       |          | - Analiz sonuc ekrani                       |
|       |          | - Perenual API entegrasyonu                 |
+-------+----------+----------------------------------------------+
|       |          |                                              |
| F4    | Hafta    | ANA OZELLIKLER - II                          |
|       | 10-12    | - Akilli Rehber ekrani                      |
|       |          | - 7 gunluk hava tahmini                     |
|       |          | - Tarlalarim (CRUD + Harita)                |
|       |          | - Ortak Arsiv ekrani                        |
|       |          | - CropRules dinamik oneri motoru            |
+-------+----------+----------------------------------------------+
|       |          |                                              |
| F5    | Hafta    | GELISMIS OZELLIKLER                          |
|       | 13-15    | - Kusbakisi tarla gorsellestirme             |
|       |          | - Haftalik sulama plani                     |
|       |          | - Saatlik hava analizi                      |
|       |          | - Bildirim sistemi                          |
|       |          | - Uydu tabanli bitki sagligi (NDVI)         |
+-------+----------+----------------------------------------------+
|       |          |                                              |
| F6    | Hafta    | TEST & OPTIMIZASYON                          |
|       | 16-17    | - Birim testler                             |
|       |          | - Entegrasyon testleri                      |
|       |          | - Performans optimizasyonu                  |
|       |          | - Kullanici kabul testleri                  |
|       |          | - Bug fix ve iyilestirmeler                 |
+-------+----------+----------------------------------------------+
|       |          |                                              |
| F7    | Hafta    | DAGITIM & DOKUMANTASYON                      |
|       | 18       | - Play Store / App Store hazirligi          |
|       |          | - Teknik dokumantasyon                      |
|       |          | - Kullanici kilavuzu                        |
|       |          | - Sunum hazirligi                           |
+-------+----------+----------------------------------------------+
```

### 11.2 Gantt Diyagrami

```
Hafta:  1  2  3  4  5  6  7  8  9  10 11 12 13 14 15 16 17 18
        |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |
F1 Analiz
        [=====]
F2 Altyapi
              [========]
F3 Ozellik-I
                       [============]
F4 Ozellik-II
                                    [========]
F5 Gelismis
                                             [========]
F6 Test
                                                      [=====]
F7 Dagitim
                                                            [==]
```

---

## 12. Risk Analizi

### 12.1 Teknik Riskler

| Risk | Olasilik | Etki | Onlem |
|------|----------|------|-------|
| **API Rate Limiting** | Yuksek | Orta | Her API icin bagimsiz try-catch, fallback zincirleri, Hive ile onbellekleme |
| **API Maliyet Artisi** | Orta | Yuksek | Open-Meteo (ucretsiz) gibi acilik kaynak alternatifleri, API kullanim izleme |
| **Ag Baglantisi Kaybi** | Yuksek | Orta | Hive ile cevrimdisi mod, son bilinen verileri gosterme |
| **Gemini API Yanitinin Bozuk JSON Donmesi** | Orta | Dusuk | Markdown temizleme, try-catch ile parse, varsayilan degerler |
| **Konum Izni Reddi** | Orta | Yuksek | Kullaniciya aciklayici mesaj, manuel konum girisi secenegi |
| **Buyuk Fotograf Dosyasi** | Dusuk | Orta | `imageQuality: 70`, `maxWidth/maxHeight: 1080` ile sıkistirma |

### 12.2 Operasyonel Riskler

| Risk | Olasilik | Etki | Onlem |
|------|----------|------|-------|
| **Yanlis Bitki Teshisi** | Orta | Yuksek | Guvenilirlik yuzdesi gosterimi, kullaniciya dogrulama imkani |
| **Yanlis Tarim Onerisi** | Dusuk | Yuksek | Deterministik hesaplamalar (formul bazli), AI ciktisini dogrulama |
| **Veri Gizliligi** | Dusuk | Yuksek | Konum verileri yalnizca API cagrilari icin kullanilir, yerel depolama |
| **Firebase Firestore Kotasi** | Orta | Orta | Okuma/yazma sayisini minimize etme, yerel onbellekleme |

### 12.3 Risk Azaltma Stratejileri

```
+--------------------------------------------------+
|            RISK AZALTMA PIRAMIDI                 |
+--------------------------------------------------+
|                                                  |
|              /\                                  |
|             /  \    ONLEME                       |
|            / API \   - Rate limit izleme         |
|           / Limit \  - Kullanim kotasi belirleme |
|          /________\                              |
|         /          \   TESPIT                    |
|        / Hata       \  - try-catch bloklari      |
|       / Yakalama     \ - Timeout korumalari      |
|      /________________\                          |
|     /                  \  KURTARMA               |
|    / Fallback           \ - Gemini fallback      |
|   / Zincirleri           \- Varsayilan degerler  |
|  /________________________\ - Hive onbellek     |
| /                          \                     |
|/ Graceful Degradation       \ DAYANIKLILIK      |
|  - Kismi veri ile calis      \                   |
|  - Kullaniciyi bilgilendir    \                  |
+--------------------------------------------------+
```

---

## 13. Sonuc ve Gelecek Vizyon

### 13.1 Sonuc

Akilli Tarim Asistani, modern yapay zeka teknolojilerini ve gercek zamanli cevresel verileri birlestirerek Turkiye'deki ciftcilere erisilebilir, kisisellestirilmis ve veri odakli bir tarim danismanlik platformu sunmayi hedeflemektedir. 9 farkli harici API entegrasyonu, hibrit veritabani mimarisi ve coklu fallback mekanizmalari ile guvenilir ve dayanikli bir sistem tasarlanmistir.

Projenin temel katkilari:
- **Butunlesik Analiz:** Tek bir uygulamada hava, toprak, bitki ve tarla analizinin birlestirilmesi
- **AI Destekli Karar:** Google Gemini AI ile kisisellestirilmis tarim onerileri
- **Deterministik Hesaplamalar:** Basari sansi, sulama takvimi ve gubre onerilerinin formul bazli hesaplanmasi
- **Coklu API Dayanikliligi:** Bir API'nin cokmesinin sistemi durdurmamasini saglayan bagimsiz hata yonetimi
- **Turkce Odakli:** Tum icerik ve onerilerin Turkce sunulmasi

### 13.2 Gelecek Vizyon

```
+================================================================+
|                    GELECEK YILLAR YONETIMI                     |
+================================================================+
|                                                                |
|  2026 Q3-Q4: TEMEL PLATFORM                                   |
|  - Mevcut ozelliklerin stabilizasyonu                         |
|  - Play Store / App Store yayini                              |
|  - Kullanici geri bildirim toplama                            |
|                                                                |
|  2027 Q1-Q2: AKILLI OZELLIKLER                                |
|  - IoT sensor entegrasyonu (nem, sicaklik sensoru)            |
|  - Drone goruntu analizi                                      |
|  - Makine ogrenimi ile hastalik erken uyari                   |
|  - Sesli asistan (Turkce dogal dil)                           |
|                                                                |
|  2027 Q3-Q4: EKOSISTEM                                        |
|  - Ciftci toplulugu platformu                                 |
|  - Pazar yeri entegrasyonu (urun alis/satis)                  |
|  - Sigorta sirketi entegrasyonu                               |
|  - Devlet tarim destek basvuru yonlendirme                    |
|                                                                |
|  2028+: OLCEKLEME                                              |
|  - Ortadogu ve Kuzey Afrika pazarlarina acilma                |
|  - Buyuk veri analitiği ile bolgesel tarim trendleri          |
|  - Karbon ayak izi hesaplama ve surdurulebilirlik raporu      |
|                                                                |
+================================================================+
```

---

## Ekler

### Ek A: Proje Dosya Yapisi

```
lib/
├── main.dart                          # Uygulama giris noktasi
├── firebase_options.dart              # Firebase yapilandirmasi
├── crop_rules.dart                    # Dinamik urun oneri motoru (Gemini)
│
├── screens/
│   ├── navigation_screen.dart         # Ana navigasyon (5 sekme)
│   ├── dashboard_screen.dart          # Ozet paneli
│   ├── growing_guide_screen.dart      # Akilli rehber
│   ├── my_crops_screen.dart           # Tarla yonetimi
│   ├── field_detail_screen.dart       # Tarla detay
│   ├── camera_screen.dart             # Kamera/galeri
│   ├── analysis_result_screen.dart    # Analiz sonuclari
│   ├── plant_database_screen.dart     # Arsiv (gecmis)
│   ├── map_area_calculator_screen.dart # Harita alan hesaplama
│   └── crop_field_match_screen.dart   # Urun-tarla eslestirme
│
├── services/
│   ├── agri_service.dart              # Ana API orchestration (1540+ satir)
│   └── crop_rules.dart                # Gemini tabanli oneri motoru
│
├── widgets/
│   ├── weekly_water_card.dart         # Haftalik sulama karti
│   ├── planting_visualization.dart    # Ekim gorsellestirme
│   ├── planting_stat_card.dart        # Istatistik karti
│   ├── top_down_field_painter.dart    # Kusbakisi CustomPainter
│   ├── top_down_field_view.dart       # Kusbakisi widget
│   └── root_painter.dart             # Kok sistemi animasyon
│
├── models/
│   └── crop_layer.dart                # Bitki katman modeli
│
└── utils/
    └── location_utils.dart            # Konum izin ve erisim
```

### Ek B: Ortam Degiskenleri (.env)

```
WEATHER_API_KEY=***
GEMINI_API_KEY=***
PLANTNET_API_KEY=***
IMAGGA_API_KEY=***
IMAGGA_API_SECRET=***
PERENUAL_API_KEY=***
AGROMONITORING_API_KEY=***
```

---

*Bu belge FENG 498 Bitirme Projesi kapsaminda hazirlanmistir.*  
*Son Guncelleme: Mart 2026*
