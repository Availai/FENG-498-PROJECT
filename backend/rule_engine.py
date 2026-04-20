"""
Kural Tabanlı Karar Motoru — FastAPI endpoint'leri için Python implementasyonu.
Dart tarafındaki lib/services/rule_engine.dart ile birebir aynı mantık.

Hastalık ve zararlı kuralları EPPO Global Database (https://gd.eppo.int) kod
referansları ile birlikte verilmiştir. EPPO kodları (Bayer kodları) Avrupa
Bitki Koruma Organizasyonu (European and Mediterranean Plant Protection
Organization) tarafından tanımlanan, tüm AB üye ülkelerinde tarımsal mevzuatta
kullanılan resmi standart taksonomi tanımlayıcılardır.
EPPO PP1 standartları: https://pp1.eppo.int
"""

import math
from enum import Enum
from typing import Optional
from pydantic import BaseModel


# EPPO Global Database kod referansları (Bayer codes)
# Kaynak: https://gd.eppo.int — bu kodlar AB tarımsal mevzuatında resmidir
EPPO_CODES = {
    # Hastalıklar
    "BOTRCI": "Botrytis cinerea (Gri küf) — domates, üzüm, çilek",
    "ALTESO": "Alternaria solani (Erken yanıklık) — domates, patates",
    "PHYTIN": "Phytophthora infestans (Geç yanıklık/Mildiyö) — patates, domates",
    "PUCCST": "Puccinia striiformis (Sarı pas) — buğday",
    "PUCCRT": "Puccinia recondita (Kahverengi pas) — buğday",
    "FUSASP": "Fusarium spp. (Solgunluk) — geniş konak",
    "RHIZSO": "Rhizoctonia solani (Kök çürüklüğü) — geniş konak",
    "PSDMSP": "Pseudomonas syringae (Bakteriyel benek) — domates, biber",
    # Zararlılar
    "TETRUR": "Tetranychus urticae (İki noktalı kırmızı örümcek)",
    "BEMITA": "Bemisia tabaci (Tütün beyazsineği)",
    "TRIAVA": "Trialeurodes vaporariorum (Sera beyazsineği)",
    "MYZUPE": "Myzus persicae (Şeftali yaprak biti)",
    "APHIGO": "Aphis gossypii (Pamuk yaprak biti)",
    "LPTNDE": "Leptinotarsa decemlineata (Colorado patates böceği)",
    "HELIAR": "Helicoverpa armigera (Yeşil kurt / koçan kurdu)",
    "TUTAAB": "Tuta absoluta (Domates pas akarı/güvesi)",
    "FRANOC": "Frankliniella occidentalis (Batı çiçek tripsi)",
}


# ─────────────────────────────────────────────────────────────────────────────
# MODELLER
# ─────────────────────────────────────────────────────────────────────────────

class RiskLevel(str, Enum):
    critical = "critical"
    warning = "warning"
    info = "info"
    ok = "ok"


class RuleCategory(str, Enum):
    disease = "disease"
    pest = "pest"
    irrigation = "irrigation"
    soil = "soil"
    weather = "weather"
    season = "season"
    compatibility = "compatibility"
    harvest = "harvest"
    geography = "geography"
    frost = "frost"
    rotation = "rotation"


class RuleResult(BaseModel):
    level: RiskLevel
    category: RuleCategory
    title: str
    message: str
    recommendation: str
    emoji: str = ""
    category_label: str = ""
    eppo_code: Optional[str] = None        # EPPO Global DB kod (varsa)
    source_ref: Optional[str] = None       # Bilimsel/resmi kaynak referansı
    # Veri kalitesi: input doğrulama veya yetersiz girdi sebebiyle güven düşükse
    # confidence 'medium' veya 'low' döner. UI bu değeri rozet olarak gösterir.
    confidence: str = "high"               # 'high' | 'medium' | 'low'

    def model_post_init(self, __context):
        emoji_map = {
            RiskLevel.critical: "🔴",
            RiskLevel.warning: "🟡",
            RiskLevel.info: "🔵",
            RiskLevel.ok: "🟢",
        }
        label_map = {
            RuleCategory.disease: "Hastalık",
            RuleCategory.pest: "Zararlı",
            RuleCategory.irrigation: "Sulama",
            RuleCategory.soil: "Toprak",
            RuleCategory.weather: "Hava",
            RuleCategory.season: "Mevsim",
            RuleCategory.compatibility: "Uyum",
            RuleCategory.harvest: "Hasat",
            RuleCategory.geography: "Coğrafya",
            RuleCategory.frost: "Zirai Don",
            RuleCategory.rotation: "Münavebe",
        }
        self.emoji = emoji_map[self.level]
        self.category_label = label_map[self.category]


class AnalyzeRequest(BaseModel):
    common_name: str = ""
    scientific_name: str = ""
    plant_details: dict = {}
    temperature: float = 20.0
    avg_weekly_temp: float = 20.0
    humidity: float = 60.0
    weekly_rain: float = 15.0
    soil_ph: float = 6.8
    soil_moisture: float = 0.25
    soil_temp_c: float = 15.0
    ndvi: float = 0.6
    wind_speed: float = 3.0
    month: int = 6
    precip_prob_next3h: float = 0.0

    # Türkiye coğrafyası için ek girdiler
    latitude: float = 39.9      # Ankara varsayılan
    longitude: float = 32.8
    slope_deg: float = 0.0      # tarla eğim açısı (0=düz, 30=dik yamaç)
    aspect_deg: float = 180.0   # bakı: 0=K, 90=D, 180=G, 270=B (G=güney)
    min_temp_c: float = 15.0    # son 24 saat min
    max_temp_c: float = 25.0    # son 24 saat max
    forecast_min_3day_c: float = 5.0  # önümüzdeki 3 gün min sıcaklık tahmini

    # ÇKS / münavebe geçmişi (son 3 yılın ürünleri, en yeni önce)
    crop_history: list[str] = []


# ─────────────────────────────────────────────────────────────────────────────
# KURAL MOTORU
# ─────────────────────────────────────────────────────────────────────────────

_SEVERITY_ORDER = {
    RiskLevel.critical: 0,
    RiskLevel.warning: 1,
    RiskLevel.info: 2,
    RiskLevel.ok: 3,
}


# Türkiye tarımında makul fiziksel sınırlar. Kaynak: MGM iklim normalleri
# 1991-2020 (https://mgm.gov.tr/veridegerlendirme/il-ve-ilceler-istatistik.aspx)
# ve Tarım Orman Bakanlığı Toprak ve Bitki Analiz Rehberi (2021).
_LIMITS = {
    "temperature": (-40.0, 55.0),      # °C; en düşük: Ağrı/Karaköse -45.6; en yüksek: Cizre 48.8
    "avg_weekly_temp": (-35.0, 50.0),
    "humidity": (0.0, 100.0),          # %
    "weekly_rain": (0.0, 500.0),       # mm/hafta; aşırı yağış üst sınırı
    "soil_ph": (3.0, 10.0),            # pH; ekim yapılabilir dışı: < 3 veya > 10
    "soil_moisture": (0.0, 1.0),       # fraction 0..1
    "soil_temp_c": (-20.0, 60.0),
    "ndvi": (-1.0, 1.0),               # NDVI teknik aralığı
    "wind_speed": (0.0, 60.0),         # m/s; 60+ hortum/fırtına
    "month": (1, 12),
    "precip_prob_next3h": (0.0, 1.0),
    "latitude": (35.0, 43.0),          # Türkiye enlem aralığı
    "longitude": (25.0, 45.5),         # Türkiye boylam aralığı
    "slope_deg": (0.0, 60.0),
    "aspect_deg": (0.0, 360.0),
    "min_temp_c": (-45.0, 50.0),
    "max_temp_c": (-40.0, 55.0),
    "forecast_min_3day_c": (-45.0, 50.0),
}


def _validate_env(req: "AnalyzeRequest") -> tuple["AnalyzeRequest", list[str]]:
    """Sensör veya API verisinin defansif doğrulaması.

    Neden: Donmuş/bozuk sensör NaN, negatif veya fiziksel olarak imkânsız değer
    döndürebilir. Çiftçi bu motora koşulsuz güveniyor; sessiz `max(0, ...)`
    maskesiyle hatalı öneri üretmek kabul edilemez.

    Davranış: Geçersiz değerleri güvenli varsayılana (sınırlara clamp veya
    Pydantic varsayılanına) çeker ve ilgili alanları issue listesine yazar.
    `analyze()` bu listeden düşük-güven RuleResult üretir.
    """
    issues: list[str] = []
    defaults = AnalyzeRequest()  # varsayılan değerler
    for field, (lo, hi) in _LIMITS.items():
        val = getattr(req, field)
        if val is None:
            issues.append(f"{field}: veri yok")
            setattr(req, field, getattr(defaults, field))
            continue
        if isinstance(val, float) and (math.isnan(val) or math.isinf(val)):
            issues.append(f"{field}: geçersiz (NaN/Inf)")
            setattr(req, field, getattr(defaults, field))
            continue
        if val < lo or val > hi:
            issues.append(f"{field}: aralık dışı ({val})")
            # clamp — yakın sınıra çek
            setattr(req, field, max(lo, min(hi, val)))
    return req, issues


def analyze(req: AnalyzeRequest) -> list[RuleResult]:
    results: list[RuleResult] = []
    # Giriş doğrulaması — geçersiz sensör verilerini sınıra çek, listele.
    req, _input_issues = _validate_env(req)
    name = req.common_name.lower()

    # Yetersiz girdi → kullanıcıya şeffaf veri-kalitesi rozeti ver.
    if _input_issues:
        conf = "low" if len(_input_issues) >= 3 else "medium"
        results.append(RuleResult(
            level=RiskLevel.info, category=RuleCategory.weather,
            title="Veri Kalitesi Düşük",
            message=(
                "Sensör veya hava API verilerinin bir kısmı eksik / aralık "
                "dışı: " + ", ".join(_input_issues[:4]) +
                ("..." if len(_input_issues) > 4 else "")
            ),
            recommendation=(
                "Önerilere temkinli yaklaşın; mümkünse sensör kalibrasyonunu "
                "veya internet bağlantısını kontrol edin."
            ),
            confidence=conf,
            source_ref="MGM iklim normalleri 1991-2020; sensör veri doğrulaması",
        ))

    results += _weather_rules(req.temperature, req.avg_weekly_temp,
                              req.humidity, req.weekly_rain,
                              req.wind_speed, req.precip_prob_next3h)
    results += _irrigation_rules(req.ndvi, req.soil_moisture,
                                 req.weekly_rain, req.precip_prob_next3h,
                                 req.plant_details, req.temperature)
    results += _disease_rules(name, req.temperature, req.humidity,
                              req.weekly_rain, req.soil_moisture, req.month)
    results += _pest_rules(name, req.temperature, req.humidity,
                           req.wind_speed, req.month)
    results += _soil_rules(req.soil_ph, req.soil_temp_c,
                           req.plant_details, req.month)
    results += _season_rules(name, req.month, req.plant_details)
    results += _compatibility_rules(req.temperature, req.avg_weekly_temp,
                                    req.soil_ph, req.weekly_rain,
                                    req.humidity, req.plant_details)
    results += _harvest_rules(name, req.plant_details)

    # Türkiye coğrafyasına özgü kurallar
    results += _turkey_geography_rules(
        req.latitude, req.longitude, req.slope_deg, req.aspect_deg, req.month
    )
    results += _diurnal_stress_rules(
        req.latitude, req.longitude, req.min_temp_c, req.max_temp_c, req.month, name
    )
    results += _agricultural_frost_rules(
        req.latitude, req.min_temp_c, req.forecast_min_3day_c, req.month, name
    )
    results += _crop_rotation_rules(req.crop_history, name)

    results.sort(key=lambda r: _SEVERITY_ORDER[r.level])
    return results


# ── 1. HAVA ───────────────────────────────────────────────────────────────────

def _weather_rules(temp, avg_temp, humidity, weekly_rain, wind, precip_prob):
    r = []

    if temp <= 0:
        r.append(RuleResult(
            level=RiskLevel.critical, category=RuleCategory.weather,
            title="Don Riski — Kritik",
            message="Sıcaklık 0°C'nin altına düştü. Don olayı gerçekleşiyor.",
            recommendation="Hassas bitkilerinizi hemen örtün. Seraların ısıtma sistemlerini devreye alın.",
        ))
    elif temp <= 3:
        r.append(RuleResult(
            level=RiskLevel.critical, category=RuleCategory.weather,
            title="Don Riski",
            message=f"Sıcaklık {temp:.1f}°C — donma eşiğine yakın.",
            recommendation="Bitkilerinizi örtü bezi ile örtün. Sulama gece değil sabah erken yapılsın.",
        ))

    if temp >= 40:
        r.append(RuleResult(
            level=RiskLevel.critical, category=RuleCategory.weather,
            title="Aşırı Sıcaklık — Isı Stresi",
            message=f"{temp:.1f}°C — çoğu kültür bitkisi için kritik eşik aşıldı.",
            recommendation="Sulama sıklığını artırın. Gündüz 12-16 arası tarla işi yapmaktan kaçının.",
        ))
    elif temp >= 36:
        r.append(RuleResult(
            level=RiskLevel.warning, category=RuleCategory.weather,
            title="Yüksek Sıcaklık Uyarısı",
            message=f"{temp:.1f}°C — yaprak yanığı ve su stresi riski arttı.",
            recommendation="Sulama saatini sabah 06:00-08:00 veya akşam 18:00-20:00 olarak ayarlayın.",
        ))

    if wind >= 15:
        r.append(RuleResult(
            level=RiskLevel.critical, category=RuleCategory.weather,
            title="Şiddetli Rüzgar",
            message=f"{wind:.1f} m/s rüzgar — bitki devrilme riski.",
            recommendation="Destek kazıklarını kontrol edin. Sera perdelerini tamamen kapatın.",
        ))
    elif wind >= 10:
        r.append(RuleResult(
            level=RiskLevel.warning, category=RuleCategory.weather,
            title="Kuvvetli Rüzgar",
            message=f"{wind:.1f} m/s rüzgar bekleniyor.",
            recommendation="İlaçlama ve gübreleme ertelensin. Sera perdelerini kapatın.",
        ))

    if precip_prob >= 70:
        r.append(RuleResult(
            level=RiskLevel.warning, category=RuleCategory.weather,
            title="Sulama Yapma — Yağmur Geliyor",
            message=f"Önümüzdeki 3 saatte yağış olasılığı %{round(precip_prob)}.",
            recommendation="Sulama ve ilaçlama ertelensin.",
        ))

    if weekly_rain > 80:
        r.append(RuleResult(
            level=RiskLevel.critical, category=RuleCategory.weather,
            title="Aşırı Yağış — Drenaj Sorunu",
            message=f"Haftalık {round(weekly_rain)} mm yağış — kök çürüklüğü riski.",
            recommendation="Drenaj kanallarını kontrol edin. Sulamayı tamamen durdurun.",
        ))
    elif weekly_rain > 50:
        r.append(RuleResult(
            level=RiskLevel.warning, category=RuleCategory.weather,
            title="Yüksek Yağış",
            message=f"Haftalık {round(weekly_rain)} mm yağış.",
            recommendation="Sulama haftaya kadar durdurulabilir. Fungisit uygulaması planlayın.",
        ))

    if weekly_rain < 3 and humidity < 30:
        r.append(RuleResult(
            level=RiskLevel.warning, category=RuleCategory.weather,
            title="Kurak Koşullar",
            message=f"Haftalık {round(weekly_rain)} mm yağış ve nem %{round(humidity)}.",
            recommendation="Damla sulama süresini %30 artırın. Mulçlama yapın.",
        ))

    return r


# ── 2. SULAMA ─────────────────────────────────────────────────────────────────

def _irrigation_rules(ndvi, soil_moisture, weekly_rain, precip_prob, plant, temp):
    r = []
    watering = str(plant.get("watering", "Average")).lower()
    drought = plant.get("drought_tolerant", False)

    # Sulama ihtiyacına ve kuraklık direncine göre tolerans ayarı
    crit_moisture_thresh = 0.12 if drought else 0.15
    warn_moisture_thresh = 0.17 if drought else 0.20

    if watering == "frequent":
        crit_moisture_thresh += 0.05
        warn_moisture_thresh += 0.05

    if ndvi < 0.4 and soil_moisture < crit_moisture_thresh:
        r.append(RuleResult(
            level=RiskLevel.critical, category=RuleCategory.irrigation,
            title="Acil Sulama Gerekli",
            message=f"NDVI: {ndvi:.2f} (bitki stres altında) + Toprak nemi: %{round(soil_moisture * 100)} (kritik düşük).",
            recommendation="En geç bugün sulama yapın. Damla sulama ile kök bölgesine yavaş ve derin sulama.",
        ))
    elif ndvi < 0.5 and soil_moisture < warn_moisture_thresh and weekly_rain < 10:
        r.append(RuleResult(
            level=RiskLevel.warning, category=RuleCategory.irrigation,
            title="Sulama Önerilir",
            message=f"NDVI: {ndvi:.2f} + Toprak nemi: %{round(soil_moisture * 100)} + Haftalık yağış {round(weekly_rain)} mm.",
            recommendation="Yarın veya öbür gün sulama planlayın. Sabah erken saatlerde tercih edin.",
        ))

    if soil_moisture > 0.50:
        r.append(RuleResult(
            level=RiskLevel.critical, category=RuleCategory.irrigation,
            title="Toprak Aşırı Nemli — Kök Çürüklüğü Riski",
            message=f"Toprak nemi %{round(soil_moisture * 100)} — kökler boğuluyor.",
            recommendation="Sulamayı derhal durdurun. Drenaj hendekleri açın.",
        ))
    elif soil_moisture > 0.40:
        r.append(RuleResult(
            level=RiskLevel.warning, category=RuleCategory.irrigation,
            title="Toprak Çok Nemli",
            message=f"Toprak nemi %{round(soil_moisture * 100)} — sulama azaltılmalı.",
            recommendation="En az 5 gün sulama yapmayın.",
        ))

    if ndvi >= 0.7 and 0.20 <= soil_moisture <= 0.40:
        r.append(RuleResult(
            level=RiskLevel.ok, category=RuleCategory.irrigation,
            title="Sulama Dengesi İdeal",
            message="NDVI yüksek, toprak nemi normal aralıkta.",
            recommendation="Mevcut sulama programını sürdürün.",
        ))

    return r


# ── 3. HASTALIK ───────────────────────────────────────────────────────────────

def _disease_rules(name, temp, humidity, weekly_rain, soil_moisture, month):
    r = []

    if "domates" in name and humidity > 80 and 20 <= temp <= 25:
        r.append(RuleResult(
            level=RiskLevel.critical, category=RuleCategory.disease,
            title="Yüksek Mantar (Fungus) Riski — Domates",
            message=f"Nem %{round(humidity)} + Sıcaklık {temp:.1f}°C — Botrytis ve Alternaria için ideal koşullar.",
            recommendation="Bakırlı fungisit uygulayın. Sulamayı sabah yapın.",
            eppo_code="BOTRCI / ALTESO",
            source_ref="EPPO PP1/152 — Botrytis ve Alternaria yönetimi",
        ))

    # Eşik kaynağı: Agrios "Plant Pathology" 5. baskı (2005) Tablo 11.3 —
    # geniş fungal patojenler için elverişli aralık: >85% RH + 18-28°C.
    if humidity > 85 and 18 <= temp <= 28:
        r.append(RuleResult(
            level=RiskLevel.warning, category=RuleCategory.disease,
            title="Genel Mantar Hastalık Riski",
            message=f"Nem %{round(humidity)} + {temp:.1f}°C — fungal hastalıklar için elverişli.",
            recommendation="Sabah sulaması yapın. Hava sirkülasyonu için budama düşünün.",
            source_ref="Agrios Plant Pathology 5e (2005) §11.3",
        ))

    if ("patates" in name or "domates" in name) and humidity > 85 and 10 <= temp <= 20:
        r.append(RuleResult(
            level=RiskLevel.critical, category=RuleCategory.disease,
            title="Mildiyö (Phytophthora) Riski",
            message=f"Nem %{round(humidity)} + {temp:.1f}°C — geç yanıklık için kritik.",
            recommendation="Profilaktik fungisit (Metalaksil veya Mancozeb) uygulayın.",
            eppo_code="PHYTIN",
            source_ref="EPPO PP1/2 — Phytophthora infestans",
        ))

    if ("buğday" in name) and humidity > 75 and 15 <= temp <= 25:
        r.append(RuleResult(
            level=RiskLevel.warning, category=RuleCategory.disease,
            title="Pas Hastalığı Riski — Buğday",
            message=f"Nem %{round(humidity)} + {temp:.1f}°C — sarı pas sporları yayılabilir.",
            recommendation="Triazol bazlı fungisit hazır bulundurun.",
            eppo_code="PUCCST",
            source_ref="EPPO PP1/26 — Puccinia striiformis (sarı pas)",
        ))

    if soil_moisture > 0.45 and temp > 20:
        r.append(RuleResult(
            level=RiskLevel.warning, category=RuleCategory.disease,
            title="Toprak Kaynaklı Patojen Riski",
            message=f"Yüksek toprak nemi (%{round(soil_moisture * 100)}) ve {temp:.1f}°C sıcaklık.",
            recommendation="Kök boğazı çürüklüğüne (Fusarium, Rhizoctonia vb.) karşı dikkatli olun. Sulamayı geçici olarak durdurun.",
            eppo_code="FUSASP / RHIZSO",
            source_ref="EPPO PP1/119 — Toprak kaynaklı fungal patojenler",
        ))

    # Eşik kaynağı: Tarım Orman Bakanlığı Zirai Mücadele Teknik Talimatları
    # (2019-2023) — >40 mm/hafta yağış + >80% RH = fungal spor patlaması
    # (bakınız: Bağ Hastalıkları Rehberi 2019).
    if weekly_rain > 40 and humidity > 80:
        r.append(RuleResult(
            level=RiskLevel.warning, category=RuleCategory.disease,
            title="Yağış Sonrası Patojen Baskısı",
            message=f"Haftalık {round(weekly_rain)} mm yağış ve yüksek nem yüzeyde fungal sporların hızla yayılmasına yol açabilir.",
            recommendation="Yağış bittikten sonra geniş spektrumlu koruyucu fungisit kullanmayı değerlendirin.",
            source_ref="T.C. Tarım Orman Bakanlığı Zirai Mücadele Teknik Talimatları (2019-2023)",
        ))

    return r


# ── 4. ZARARLI ────────────────────────────────────────────────────────────────

def _pest_rules(name, temp, humidity, wind, month):
    r = []

    if any(p in name for p in ["domates", "biber", "salatalık", "patlıcan"]) \
            and temp > 30 and humidity < 40:
        r.append(RuleResult(
            level=RiskLevel.warning, category=RuleCategory.pest,
            title="Kırmızı Örümcek Riski",
            message=f"{temp:.1f}°C + Düşük nem %{round(humidity)}.",
            recommendation="Yaprak altlarını kontrol edin. Kükürt bazlı akarisit uygulayın.",
            eppo_code="TETRUR",
            source_ref="EPPO PP1/200 — Tetranychus urticae mücadele",
        ))

    if 3 <= month <= 6 and 15 <= temp <= 25 and humidity >= 60:
        r.append(RuleResult(
            level=RiskLevel.info, category=RuleCategory.pest,
            title="Yaprak Biti (Aphid) Sezonu",
            message=f"Bahar sezonu ve {temp:.1f}°C — yaprak biti çoğalması için uygun.",
            recommendation="Sarı yapışkanlı tuzak kullanın.",
            eppo_code="MYZUPE / APHIGO",
            source_ref="EPPO PP1/252 — Aphidae yönetimi",
        ))

    if any(p in name for p in ["patates", "patlıcan"]) \
            and temp > 20 and 5 <= month <= 8:
        r.append(RuleResult(
            level=RiskLevel.warning, category=RuleCategory.pest,
            title="Colorado Böceği Riski",
            message=f"Yaz sezonu ve {temp:.1f}°C — Colorado böceği aktif.",
            recommendation="Yaprak altlarını günlük kontrol edin. Spinosad uygulayın.",
            eppo_code="LPTNDE",
            source_ref="EPPO PP1/12 — Leptinotarsa decemlineata",
        ))

    if "mısır" in name and temp > 25 and 6 <= month <= 9:
        r.append(RuleResult(
            level=RiskLevel.warning, category=RuleCategory.pest,
            title="Mısır Kurdu (Helicoverpa) Riski",
            message="Sıcak yaz — koçan kurdu aktif dönemde.",
            recommendation="Feromonlu tuzaklar kurun. Bacillus thuringiensis (Bt) kullanın.",
            eppo_code="HELIAR",
            source_ref="EPPO PP1/110 — Helicoverpa armigera",
        ))

    if wind < 2.0 and temp > 25 and humidity > 50:
        r.append(RuleResult(
            level=RiskLevel.warning, category=RuleCategory.pest,
            title="Durgun Hava — Zararlı Artış Riski",
            message=f"Rüzgar hızı düşük ({wind:.1f} m/s) ve hava sıcak. Beyazsinek ve kırmızı örümcek popülasyonu hızla artabilir.",
            recommendation="Böcek yoğunluğunu gözlemleyin. Seradaysanız havalandırmayı maksimuma çıkarın.",
        ))

    return r


# ── 5. TOPRAK ─────────────────────────────────────────────────────────────────

def _soil_rules(ph, soil_temp, plant, month):
    r = []
    ideal_ph_min = float(plant.get("ideal_ph_min", 5.5))
    ideal_ph_max = float(plant.get("ideal_ph_max", 7.0))

    if ph < 5.0:
        r.append(RuleResult(
            level=RiskLevel.critical, category=RuleCategory.soil,
            title="Toprak Aşırı Asidik",
            message=f"pH {ph:.1f} — besin alımı bloke, alüminyum toksisitesi riski.",
            recommendation="Dekara 300-400 kg tarım kireci uygulayın.",
        ))
    elif ph < 5.5:
        r.append(RuleResult(
            level=RiskLevel.warning, category=RuleCategory.soil,
            title="Toprak Asidik — Kireçleme Önerisi",
            message=f"pH {ph:.1f} — çoğu kültür bitkisi için alt sınıra yakın.",
            recommendation="Dekara 150-200 kg tarım kireci uygulayın.",
        ))

    if ph > 8.0:
        r.append(RuleResult(
            level=RiskLevel.critical, category=RuleCategory.soil,
            title="Toprak Aşırı Bazik",
            message=f"pH {ph:.1f} — demir, çinko ve mangan alımı bloke.",
            recommendation="Dekara 30-50 kg elementel kükürt uygulayın.",
        ))
    elif ph > 7.5:
        r.append(RuleResult(
            level=RiskLevel.warning, category=RuleCategory.soil,
            title="Toprak Bazik",
            message=f"pH {ph:.1f} — mikro besin eksikliği riski.",
            recommendation="Asidik organik materyal ekleyin. Amonyum nitrat tercih edin.",
        ))

    if ph < ideal_ph_min - 0.3:
        r.append(RuleResult(
            level=RiskLevel.warning, category=RuleCategory.soil,
            title="pH Bitki İdeal Aralığının Altında",
            message=f"Bitki ideal pH {ideal_ph_min:.1f}-{ideal_ph_max:.1f} iken mevcut pH {ph:.1f}.",
            recommendation="Kireçleme yapın.",
        ))
    elif ph > ideal_ph_max + 0.3:
        r.append(RuleResult(
            level=RiskLevel.warning, category=RuleCategory.soil,
            title="pH Bitki İdeal Aralığının Üstünde",
            message=f"Bitki ideal pH {ideal_ph_min:.1f}-{ideal_ph_max:.1f} iken mevcut pH {ph:.1f}.",
            recommendation="Kükürt uygulaması ve asidik gübre ile pH düşürün.",
        ))

    if soil_temp < 8 and 3 <= month <= 5:
        r.append(RuleResult(
            level=RiskLevel.warning, category=RuleCategory.soil,
            title="Toprak Henüz Soğuk — Ekim Riski",
            message=f"Toprak sıcaklığı {soil_temp:.1f}°C — çimlenme yavaş olabilir.",
            recommendation="Siyah plastik mulç ile toprağı ısıtın. Fide kullanın.",
        ))
    elif 15 <= soil_temp <= 25:
        r.append(RuleResult(
            level=RiskLevel.ok, category=RuleCategory.soil,
            title="Toprak Sıcaklığı İdeal",
            message=f"{soil_temp:.1f}°C — çimlenme ve kök gelişimi için mükemmel.",
            recommendation="Ekim ve dikim için uygun koşullar.",
        ))

    return r


# ── 6. MEVSİM ─────────────────────────────────────────────────────────────────

def _season_rules(name, month, plant):
    r = []

    if plant.get("tropical") and month in (12, 1, 2):
        r.append(RuleResult(
            level=RiskLevel.critical, category=RuleCategory.season,
            title="Tropikal Bitki — Kış Dönemi",
            message="Bu bitki tropikal kökenli ve kış aylarına karşı hassas.",
            recommendation="Saksıdaysa içeri alın. Tarlada kalın örtü bezi kullanın.",
        ))

    if "buğday" in name and month in (10, 11):
        r.append(RuleResult(
            level=RiskLevel.ok, category=RuleCategory.season,
            title="Kışlık Buğday Ekim Zamanı",
            message="Ekim-Kasım kışlık buğday ekimi için ideal dönem.",
            recommendation="Ekim derinliği 4-5 cm. Dekara 20-22 kg tohumluk kullanın.",
        ))

    if any(p in name for p in ["domates", "biber", "patlıcan"]) and month in (12, 1, 2):
        r.append(RuleResult(
            level=RiskLevel.critical, category=RuleCategory.season,
            title="Açık Tarla Dışında Ekim Zamanı",
            message="Domates/biber/patlıcan soğuğa dayanmaz.",
            recommendation="Açık tarlada ekim yapılmamalı. Sera koşullarında ısıtma gereklidir.",
        ))

    if any(p in name for p in ["domates", "biber", "salatalık", "kabak"]) and 4 <= month <= 6:
        r.append(RuleResult(
            level=RiskLevel.ok, category=RuleCategory.season,
            title="İdeal Ekim/Dikim Zamanı",
            message="İlkbahar — bu bitki için en uygun dönem.",
            recommendation="Gece sıcaklıkları 10°C'nin üzerinde olduğunda dikimi yapın.",
        ))

    return r


# ── 7. UYUM ───────────────────────────────────────────────────────────────────

def _compatibility_rules(temp, avg_temp, ph, weekly_rain, humidity, plant):
    r = []
    if not plant:
        return r

    ideal_temp_min = float(plant.get("ideal_temp_min", 10))
    ideal_temp_max = float(plant.get("ideal_temp_max", 35))
    ideal_ph_min   = float(plant.get("ideal_ph_min", 5.5))
    ideal_ph_max   = float(plant.get("ideal_ph_max", 7.5))
    water_need     = float(plant.get("water_need_mm_week", 15))

    if ph < ideal_ph_min - 0.5:
        r.append(RuleResult(
            level=RiskLevel.warning, category=RuleCategory.compatibility,
            title="pH Uyumsuz — Çok Asidik",
            message=f"Tarla pH {ph:.1f}, bitki için ideal: {ideal_ph_min:.1f}-{ideal_ph_max:.1f}.",
            recommendation="Tarım kireci uygulayarak pH'ı yükseltin.",
        ))
    elif ph > ideal_ph_max + 0.5:
        r.append(RuleResult(
            level=RiskLevel.warning, category=RuleCategory.compatibility,
            title="pH Uyumsuz — Çok Bazik",
            message=f"Tarla pH {ph:.1f}, bitki için ideal: {ideal_ph_min:.1f}-{ideal_ph_max:.1f}.",
            recommendation="Kükürt uygulaması ile pH'ı düşürün.",
        ))
    else:
        r.append(RuleResult(
            level=RiskLevel.ok, category=RuleCategory.compatibility,
            title="pH Uyumlu",
            message=f"Tarla pH {ph:.1f} bitki için ideal aralıkta.",
            recommendation="pH değeri uygun, ek işlem gerekmez.",
        ))

    if avg_temp < ideal_temp_min - 3:
        r.append(RuleResult(
            level=RiskLevel.critical, category=RuleCategory.compatibility,
            title="Sıcaklık Uyumsuz — Çok Soğuk",
            message=f"Mevcut {avg_temp:.1f}°C, ideal minimum {ideal_temp_min:.0f}°C.",
            recommendation="Bu bitkiyi bu koşullarda yetiştirmeyin.",
        ))
    elif avg_temp < ideal_temp_min:
        r.append(RuleResult(
            level=RiskLevel.warning, category=RuleCategory.compatibility,
            title="Sıcaklık Biraz Düşük",
            message=f"Mevcut {avg_temp:.1f}°C, ideal min {ideal_temp_min:.0f}°C.",
            recommendation="Plastik mulç ile toprak ısısı artırılabilir.",
        ))
    elif ideal_temp_min <= avg_temp <= ideal_temp_max:
        r.append(RuleResult(
            level=RiskLevel.ok, category=RuleCategory.compatibility,
            title="Sıcaklık Uyumlu",
            message=f"{avg_temp:.1f}°C — bitki için ideal aralıkta.",
            recommendation="Sıcaklık koşulları mükemmel.",
        ))

    water_diff = abs(weekly_rain - water_need)
    if weekly_rain < water_need - 10:
        r.append(RuleResult(
            level=RiskLevel.warning, category=RuleCategory.compatibility,
            title="Su Açığı Var",
            message=f"Bitki haftada {round(water_need)} mm ister, yağış {round(weekly_rain)} mm.",
            recommendation=f"{round(water_need - weekly_rain)} mm eksik — sulama ile tamamlayın.",
        ))
    elif water_diff <= 10:
        r.append(RuleResult(
            level=RiskLevel.ok, category=RuleCategory.compatibility,
            title="Su Dengesi Uyumlu",
            message=f"Yağış ({round(weekly_rain)} mm) bitki ihtiyacını karşılıyor.",
            recommendation="Ek sulama gerekmeyebilir.",
        ))

    return r


# ── 8. HASAT ──────────────────────────────────────────────────────────────────

def _harvest_rules(name, plant):
    r = []
    if "karpuz" in name or "kavun" in name:
        r.append(RuleResult(
            level=RiskLevel.info, category=RuleCategory.harvest,
            title="Hasat Kalite İpucu — Kavun/Karpuz",
            message="Olgunlaşma döneminde sulama azaltılırsa şeker oranı artar.",
            recommendation="Hasattan 10-14 gün önce sulamayı azaltın.",
        ))

    if "domates" in name:
        r.append(RuleResult(
            level=RiskLevel.info, category=RuleCategory.harvest,
            title="Hasat Kalite İpucu — Domates",
            message="Kızarma döneminde aşırı veya düzensiz sulama meyve çatlamasına yol açar.",
            recommendation="Hasat yaklaşırken sulama miktarını dengeleyin ve sabit tutun.",
        ))

    if "patates" in name or "soğan" in name:
        r.append(RuleResult(
            level=RiskLevel.info, category=RuleCategory.harvest,
            title="Hasat Hazırlığı — Yumrulu Bitki",
            message="Hasat öncesi toprağın hafif kuruması yumru kalitesini artırır ve depolama ömrünü uzatır.",
            recommendation="Hasattan 1-2 hafta önce sulamayı tamamen kesin.",
        ))

    if "buğday" in name or "arpa" in name:
        r.append(RuleResult(
            level=RiskLevel.info, category=RuleCategory.harvest,
            title="Hasat Nem Oranı — Tahıl",
            message="Dane neminin %14'ün altına düşmesi güvenli depolama için kritiktir.",
            recommendation="Hasadı kuru ve güneşli öğle saatlerinde, çiğ kalktıktan sonra gerçekleştirin.",
        ))

    if "mısır" in name:
        r.append(RuleResult(
            level=RiskLevel.info, category=RuleCategory.harvest,
            title="Hasat Zamanlaması — Mısır",
            message="Silajlık mısırda kuru madde oranı %30-35 olmalıdır. Danelik için nem %15 civarı idealdir.",
            recommendation="Koçanlardaki süt çizgisinin seviyesini kontrol ederek doğru hasat zamanını belirleyin.",
        ))

    return r


# ═════════════════════════════════════════════════════════════════════════════
# TÜRKİYE'YE ÖZGÜ KURALLAR
# Coğrafi konum (enlem/bakı/eğim), iç Anadolu stepi stresi, zirai don, münavebe
# ═════════════════════════════════════════════════════════════════════════════

import math


def _solar_declination_deg(month: int) -> float:
    """
    Kaba güneş deklinasyonu (her ayın 15'i için NOAA yaklaşımı).
    Kuzey yarımküre için + = yaz, - = kış.
    """
    # Yılın gününün kaba ortası (ayın 15'i)
    day_of_year = int((month - 1) * 30.4 + 15)
    # Cooper (1969) formülü: δ = 23.45 * sin(360/365 * (284 + n))
    return 23.45 * math.sin(math.radians(360.0 / 365.0 * (284 + day_of_year)))


def _day_length_hours(lat_deg: float, month: int) -> float:
    """Basit gün ışığı süresi (hours). Kutupsal uç değerleri clamp eder."""
    decl = math.radians(_solar_declination_deg(month))
    lat = math.radians(lat_deg)
    cos_h = -math.tan(lat) * math.tan(decl)
    cos_h = max(-1.0, min(1.0, cos_h))
    hour_angle = math.degrees(math.acos(cos_h))
    return 2.0 * hour_angle / 15.0


def _slope_sun_factor(lat_deg: float, slope_deg: float, aspect_deg: float, month: int) -> float:
    """
    Yamaç etkisi: eğimli ve farklı bakılı tarlaların düz zemine göre aldığı
    güneş radyasyonu oranı (dimensionless ~0.5-1.5).

    Mantık: Kuzey yarımkürede güneye bakan yamaç (aspect=180°) daha çok
    güneş alır; kuzeye bakan (aspect=0°/360°) daha az alır. Doğu/batı bakı
    simetrik olarak arada kalır. Matematiksel olarak öğle güneşinin yamaç
    normalinden geliş açısı kosinüsü kullanılır.
    """
    decl = _solar_declination_deg(month)
    # Güneşin öğle zenith açısı (düz zemin için)
    zenith_flat_deg = abs(lat_deg - decl)
    zenith_flat = math.radians(zenith_flat_deg)
    slope = math.radians(slope_deg)
    # Azimut sapması: güney bakıdan sapma. Kuzey yarımkürede güneye bakmak
    # optimaldir → 180° referansı.
    azimuth_offset = math.radians(abs(((aspect_deg - 180.0) + 180.0) % 360.0 - 180.0))

    # Yamaç normali ile güneş ışını arasındaki açının kosinüsü
    cos_theta = (
        math.cos(slope) * math.cos(zenith_flat)
        + math.sin(slope) * math.sin(zenith_flat) * math.cos(azimuth_offset)
    )
    # Negatif değer = güneş yamaca arkadan vuruyor → 0
    cos_theta = max(0.0, cos_theta)
    # Düz yüzeyin kosinüsüne göre normalize
    flat_cos = max(math.cos(zenith_flat), 0.01)
    return cos_theta / flat_cos


def _turkey_geography_rules(latitude, longitude, slope_deg, aspect_deg, month):
    """
    Enlem + eğim + bakı kombinasyonundan güneşlenme tahmini yapar.
    Türkiye örnekleri: Karadeniz kıyısında kuzey yamaç (aspect~0) güneye göre
    ciddi dezavantajlı; Güneydoğu Anadolu'da güney yamaç aşırı ışınıma maruz.
    """
    r = []

    # Türkiye sınırları dışında (yaklaşık) ise coğrafya kuralı atla
    if not (35.5 <= latitude <= 42.5 and 25.5 <= longitude <= 45.0):
        return r

    day_hours = _day_length_hours(latitude, month)

    # 1) Temel gün ışığı bilgisi
    r.append(RuleResult(
        level=RiskLevel.info, category=RuleCategory.geography,
        title="Bölgesel Gün Işığı Süresi",
        message=(
            f"{latitude:.2f}°K enleminde bu ay günlük ışık süresi ~"
            f"{day_hours:.1f} saat. Fotosentez planlamasında referans alın."
        ),
        recommendation=(
            "Kısa gün (<10 sa): kış sebzeciliği için örtü altı düşünün. "
            "Uzun gün (>14 sa): yaz bitkilerinde ara sulama önerilir."
        ),
        source_ref="NOAA Solar Position Formula (Cooper 1969)",
    ))

    # 2) Eğim + bakı etkisi (yalnızca kayda değer bir eğim varsa)
    if slope_deg >= 5:
        factor = _slope_sun_factor(latitude, slope_deg, aspect_deg, month)
        pct = round((factor - 1.0) * 100)
        # Bakı yönü etiketleme
        if aspect_deg < 45 or aspect_deg >= 315:
            aspect_name = "kuzey"
        elif aspect_deg < 135:
            aspect_name = "doğu"
        elif aspect_deg < 225:
            aspect_name = "güney"
        else:
            aspect_name = "batı"

        if factor < 0.75:
            # Kuzey yamaç — Karadeniz bölgesinde tipik sorun
            level = RiskLevel.warning
            rec = (
                "Kuzey yamaç düz zemine göre güneş alımı çok düşük. "
                "Ürün seçiminde gölgeye dayanıklı türleri (çay, ıhlamur, fındık, "
                "bezelye) tercih edin. Hasat 7-14 gün gecikebilir."
            )
        elif factor > 1.25:
            # Güney yamaç — Güneydoğu Anadolu'da aşırı ışınım
            level = RiskLevel.info
            rec = (
                "Güney yamaç düz zemine göre güneş alımı yüksek. "
                "Yaprak yanığı riskine karşı mulçlama ve gölgeleme filesi "
                "kullanın. Sulamayı sabah erken yapın."
            )
        else:
            level = RiskLevel.ok
            rec = "Eğim/bakı kombinasyonu dengeli — özel önlem gerekmez."

        r.append(RuleResult(
            level=level, category=RuleCategory.geography,
            title=f"Yamaç Etkisi — {aspect_name.capitalize()} Bakı",
            message=(
                f"Eğim {slope_deg:.0f}°, {aspect_name} bakı. "
                f"Düz zemine göre güneşlenme farkı: %{pct:+d}."
            ),
            recommendation=rec,
            source_ref="Cosine law of illumination on inclined surfaces",
        ))

    return r


# ── İÇ ANADOLU DIURNAL STRES (GECE-GÜNDÜZ SICAKLIK FARKI) ─────────────────────

def _is_central_anatolia(lat: float, lon: float) -> bool:
    """İç Anadolu stepi yaklaşık sınırı (Konya, Ankara, Kayseri üçgeni)."""
    return 37.5 <= lat <= 40.5 and 31.0 <= lon <= 37.0


def _diurnal_stress_rules(latitude, longitude, min_c, max_c, month, name):
    r = []
    diurnal = max_c - min_c
    if diurnal <= 0:
        return r

    in_ic_anadolu = _is_central_anatolia(latitude, longitude)

    # İç Anadolu ilkbahar/yaz koşullarında 15°C üstü fark tipiktir ve çiçek
    # dökümüne, döllenme bozukluğuna yol açar (domates, biber, üzüm, fasulye).
    sensitive = any(k in name for k in ["domates", "biber", "üzüm", "fasulye", "patlıcan"])
    spring_summer = 4 <= month <= 9

    if in_ic_anadolu and diurnal >= 20 and spring_summer:
        r.append(RuleResult(
            level=RiskLevel.warning, category=RuleCategory.geography,
            title="İç Anadolu Stepi — Aşırı Gece/Gündüz Farkı",
            message=(
                f"Günlük sıcaklık farkı {diurnal:.0f}°C (min {min_c:.0f} / max {max_c:.0f}). "
                "İç Anadolu'da tipik ama bu ay sınırın üzerinde."
            ),
            recommendation=(
                "Çiçek dönemindeki bitkilerde döllenme bozukluğu ve çiçek dökümü "
                "riski var. Rüzgar kıran kullanın, akşam üzeri kısa süreli "
                "yaprak sulaması gece soğumasını ılımlılaştırır."
            ),
        ))
    elif in_ic_anadolu and diurnal >= 15 and sensitive and spring_summer:
        r.append(RuleResult(
            level=RiskLevel.info, category=RuleCategory.geography,
            title="Gece-Gündüz Farkı Uyarısı",
            message=(
                f"Hassas tür (${name}) için {diurnal:.0f}°C'lik diurnal fark "
                "ikinci derece streslidir."
            ),
            recommendation=(
                "Potasyum ağırlıklı yaprak gübresi stres toleransını artırır. "
                "Damla sulamayı akşam üstü yapın."
            ),
        ))
    elif diurnal >= 25:
        # İç Anadolu dışında bile aşırı ise uyarı ver
        r.append(RuleResult(
            level=RiskLevel.warning, category=RuleCategory.geography,
            title="Yüksek Diurnal Stres",
            message=f"Gece-gündüz farkı {diurnal:.0f}°C — bitki stresli.",
            recommendation="Sulama sıklığını artırın, rüzgar kıran yapın.",
        ))

    return r


# ── ZİRAİ DON ALARMI (MGM TARZI) ──────────────────────────────────────────────

def _agricultural_frost_rules(latitude, min_c, forecast_min_3day_c, month, name):
    """
    MGM'nin Zirai Don Tahmin Haritası mantığıyla uyumlu uyarılar.
    İlkbahar geç donları (Nis-May) ve sonbahar erken donları (Eki-Kas) özellikle
    kritik. Türkiye'de tarımı tehdit eden en büyük iklim olaylarındandır.
    """
    r = []

    # MGM kriterleri: min ≤ 0°C = don olayı; 0 < min ≤ 2 = don riski
    is_spring_late = month in (4, 5)  # nisan-mayıs
    is_autumn_early = month in (10, 11)  # ekim-kasım
    is_winter = month in (12, 1, 2, 3)

    sensitive_spring = any(
        k in name for k in [
            "kayısı", "şeftali", "erik", "kiraz", "elma", "armut", "üzüm",
            "çilek", "badem", "ceviz",
        ]
    )
    sensitive_autumn = any(
        k in name for k in ["domates", "biber", "patlıcan", "fasulye", "kabak"]
    )

    # 24s içinde don olayı
    if min_c <= 0 and (is_spring_late or is_autumn_early):
        r.append(RuleResult(
            level=RiskLevel.critical, category=RuleCategory.frost,
            title="Zirai Don — Kritik (MGM Eşik)",
            message=(
                f"Min sıcaklık {min_c:.1f}°C — don olayı gerçekleşiyor. "
                f"{'İlkbahar geç donu' if is_spring_late else 'Sonbahar erken donu'} "
                "Türkiye'de en fazla zarar veren iklim olayıdır."
            ),
            recommendation=(
                "Duman siperi, sulu savunma (sprinkler), örtü bezi veya don "
                "mumu kullanın. Meyve ağaçlarında yağmurlama sulama çiçek "
                "dokularını 0°C'de tutar."
            ),
            source_ref="MGM Zirai Don Tahmin ve Erken Uyarı Sistemi",
        ))
    elif 0 < min_c <= 2 and (is_spring_late or is_autumn_early):
        lvl = RiskLevel.warning
        if (is_spring_late and sensitive_spring) or (is_autumn_early and sensitive_autumn):
            lvl = RiskLevel.critical
        r.append(RuleResult(
            level=lvl, category=RuleCategory.frost,
            title="Zirai Don Hassasiyeti",
            message=(
                f"Min sıcaklık {min_c:.1f}°C — MGM don riski eşiği (0-2°C)."
            ),
            recommendation=(
                "Gece sabahına doğru 04:00-06:00 saatlerinde radyasyon donu "
                "beklenir. Hassas ürünleri örtü altına alın, sera kapılarını "
                "kapalı tutun."
            ),
            source_ref="MGM Zirai Don Haritası",
        ))

    # 3 günlük tahmin ileri uyarı
    if forecast_min_3day_c <= 2 and min_c > 2:
        r.append(RuleResult(
            level=RiskLevel.info, category=RuleCategory.frost,
            title="Don Uyarısı — 3 Gün İleri",
            message=(
                f"Önümüzdeki 3 gün minimum {forecast_min_3day_c:.1f}°C'ye düşecek."
            ),
            recommendation=(
                "Don koruma malzemelerinizi (bez, mum, sprinkler) şimdiden "
                "hazırlayın. Sulama depolarını dolu tutun; ıslak toprak daha "
                "geç donar."
            ),
        ))

    # Kuzey Türkiye'de kış aylarında klasik uyarı
    if is_winter and latitude >= 39.5 and min_c <= -5:
        r.append(RuleResult(
            level=RiskLevel.warning, category=RuleCategory.frost,
            title="Şiddetli Kış Donu — Kuzey Türkiye",
            message=f"Min {min_c:.0f}°C. Kuzey illerimizde kök bölgesi donabilir.",
            recommendation=(
                "Meyve ağaçlarının kök boğazına samanlı toprak yığını yapın. "
                "Genç fidanlar için rüzgar kıran zorunludur."
            ),
        ))

    return r


# ── MÜNAVEBE (NÖBETLEŞE EKİM) KURALLARI ───────────────────────────────────────

def _crop_rotation_rules(crop_history, current_name):
    """
    ÇKS/yerel ajanda kayıtlarından beslenen münavebe motoru.
    2 yıl üst üste aynı familya → kök hastalıkları/nematod riski artar.
    Türkiye'de özellikle buğday monokültürü, Fusarium ve kök boğazı
    (Gaeumannomyces graminis) riskini çok artırır.
    """
    r = []
    if not crop_history or not current_name:
        return r

    history = [h.lower() for h in crop_history if isinstance(h, str)]
    curr = current_name.lower()

    # Yakın 2 yılın ürünlerini bak
    last1 = history[0] if len(history) >= 1 else ""
    last2 = history[1] if len(history) >= 2 else ""

    # Tahıl monokültürü — Türkiye'de en yaygın hata
    grains = ("buğday", "arpa", "yulaf", "çavdar", "tritikale")
    if curr.startswith(grains) and last1.startswith(grains) and last2.startswith(grains):
        r.append(RuleResult(
            level=RiskLevel.critical, category=RuleCategory.rotation,
            title="Kök Boğazı Hastalığı Riski — Tahıl Monokültürü",
            message=(
                f"Son 3 yıldır tahıl ekimi yapılmış ({last2} → {last1} → {curr}). "
                "Gaeumannomyces graminis ve Fusarium spp. toprakta birikmiştir."
            ),
            recommendation=(
                "Bu yıl baklagil (nohut, mercimek, fiğ) veya ayçiçeği ekmeniz "
                "verimi %20-35 artırır ve toprak azotunu bedava yeniler. "
                "Ege/Trakya'da ayçiçeği, İç Anadolu'da nohut/mercimek idealdir."
            ),
            eppo_code="GAEUGR",
            source_ref="TAGEM münavebe kılavuzu; FAO Crop Rotation Guide",
        ))
    elif curr.startswith(grains) and last1.startswith(grains):
        r.append(RuleResult(
            level=RiskLevel.warning, category=RuleCategory.rotation,
            title="Tahıl Münavebesi — 2. Yıl",
            message=f"Geçen yıl da tahıl ({last1}) ekilmiş. Bu yıl 3. yıla dikkat.",
            recommendation=(
                "Tahıl üst üste 2 yıl tolere edilebilir ama 3. yıl baklagil "
                "veya yağlı tohum (ayçiçeği/kolza) dönüşü şarttır."
            ),
        ))

    # Domates/patates/biber/patlıcan = Solanaceae familyası
    solanaceae = ("domates", "patates", "biber", "patlıcan")
    if any(s in curr for s in solanaceae) and any(s in last1 for s in solanaceae):
        r.append(RuleResult(
            level=RiskLevel.warning, category=RuleCategory.rotation,
            title="Solanaceae Üst Üste — Nematod ve Fusarium Riski",
            message=f"{last1} → {curr}: aynı familya üst üste.",
            recommendation=(
                "En az 3 yıl solanaceae dışı ekim yapın. Mısır, buğday veya "
                "yeşil gübre (fiğ) ile toprak temizlenir."
            ),
            eppo_code="MELGSP",  # Meloidogyne spp. (kök ur nematodu)
        ))

    # Ayçiçeği kendini takip etmesin — sklerotinia riski
    if "ayçiçek" in curr and "ayçiçek" in last1:
        r.append(RuleResult(
            level=RiskLevel.critical, category=RuleCategory.rotation,
            title="Ayçiçeğinde Sklerotinia Riski",
            message="Ayçiçeği üst üste iki yıl — toprakta Sclerotinia sclerotiorum birikir.",
            recommendation=(
                "En az 4 yıl ara verin. Bu yıl buğday veya mısır tercih edin."
            ),
            eppo_code="SCLESC",
        ))

    return r
