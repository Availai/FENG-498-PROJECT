"""
Kural Tabanlı Karar Motoru — FastAPI endpoint'leri için Python implementasyonu.
Dart tarafındaki lib/services/rule_engine.dart ile birebir aynı mantık.
"""

from enum import Enum
from typing import Optional
from pydantic import BaseModel


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


class RuleResult(BaseModel):
    level: RiskLevel
    category: RuleCategory
    title: str
    message: str
    recommendation: str
    emoji: str = ""
    category_label: str = ""

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


# ─────────────────────────────────────────────────────────────────────────────
# KURAL MOTORU
# ─────────────────────────────────────────────────────────────────────────────

_SEVERITY_ORDER = {
    RiskLevel.critical: 0,
    RiskLevel.warning: 1,
    RiskLevel.info: 2,
    RiskLevel.ok: 3,
}


def analyze(req: AnalyzeRequest) -> list[RuleResult]:
    results: list[RuleResult] = []
    name = req.common_name.lower()

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
        ))

    if humidity > 85 and 18 <= temp <= 28:
        r.append(RuleResult(
            level=RiskLevel.warning, category=RuleCategory.disease,
            title="Genel Mantar Hastalık Riski",
            message=f"Nem %{round(humidity)} + {temp:.1f}°C — fungal hastalıklar için elverişli.",
            recommendation="Sabah sulaması yapın. Hava sirkülasyonu için budama düşünün.",
        ))

    if ("patates" in name or "domates" in name) and humidity > 85 and 10 <= temp <= 20:
        r.append(RuleResult(
            level=RiskLevel.critical, category=RuleCategory.disease,
            title="Mildiyö (Phytophthora) Riski",
            message=f"Nem %{round(humidity)} + {temp:.1f}°C — geç yanıklık için kritik.",
            recommendation="Profilaktik fungisit (Metalaksil veya Mancozeb) uygulayın.",
        ))

    if ("buğday" in name) and humidity > 75 and 15 <= temp <= 25:
        r.append(RuleResult(
            level=RiskLevel.warning, category=RuleCategory.disease,
            title="Pas Hastalığı Riski — Buğday",
            message=f"Nem %{round(humidity)} + {temp:.1f}°C — sarı pas sporları yayılabilir.",
            recommendation="Triazol bazlı fungisit hazır bulundurun.",
        ))

    if soil_moisture > 0.45 and temp > 20:
        r.append(RuleResult(
            level=RiskLevel.warning, category=RuleCategory.disease,
            title="Toprak Kaynaklı Patojen Riski",
            message=f"Yüksek toprak nemi (%{round(soil_moisture * 100)}) ve {temp:.1f}°C sıcaklık.",
            recommendation="Kök boğazı çürüklüğüne (Fusarium, Rhizoctonia vb.) karşı dikkatli olun. Sulamayı geçici olarak durdurun.",
        ))

    if weekly_rain > 40 and humidity > 80:
        r.append(RuleResult(
            level=RiskLevel.warning, category=RuleCategory.disease,
            title="Yağış Sonrası Patojen Baskısı",
            message=f"Haftalık {round(weekly_rain)} mm yağış ve yüksek nem yüzeyde fungal sporların hızla yayılmasına yol açabilir.",
            recommendation="Yağış bittikten sonra geniş spektrumlu koruyucu fungisit kullanmayı değerlendirin.",
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
        ))

    if 3 <= month <= 6 and 15 <= temp <= 25 and humidity >= 60:
        r.append(RuleResult(
            level=RiskLevel.info, category=RuleCategory.pest,
            title="Yaprak Biti (Aphid) Sezonu",
            message=f"Bahar sezonu ve {temp:.1f}°C — yaprak biti çoğalması için uygun.",
            recommendation="Sarı yapışkanlı tuzak kullanın.",
        ))

    if any(p in name for p in ["patates", "patlıcan"]) \
            and temp > 20 and 5 <= month <= 8:
        r.append(RuleResult(
            level=RiskLevel.warning, category=RuleCategory.pest,
            title="Colorado Böceği Riski",
            message=f"Yaz sezonu ve {temp:.1f}°C — Colorado böceği aktif.",
            recommendation="Yaprak altlarını günlük kontrol edin. Spinosad uygulayın.",
        ))

    if "mısır" in name and temp > 25 and 6 <= month <= 9:
        r.append(RuleResult(
            level=RiskLevel.warning, category=RuleCategory.pest,
            title="Mısır Kurdu (Helicoverpa) Riski",
            message="Sıcak yaz — koçan kurdu aktif dönemde.",
            recommendation="Feromonlu tuzaklar kurun. Bacillus thuringiensis (Bt) kullanın.",
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
