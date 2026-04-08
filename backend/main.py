# main.py
from fastapi import FastAPI, HTTPException, Header
from fastapi.responses import FileResponse
from pydantic import BaseModel, Field
from datetime import datetime, timezone
from typing import List, Optional, Any
from pathlib import Path
import asyncpg
import os

try:
    from dotenv import load_dotenv
    load_dotenv()
except ImportError:
    pass
try:
    from .rule_engine import analyze, AnalyzeRequest, RuleCategory, RiskLevel
except ImportError:
    from rule_engine import analyze, AnalyzeRequest, RuleCategory, RiskLevel

app = FastAPI(title="Smart Agri Backend API", version="1.0")


# âââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââ
# KURAL MOTORU ENDPOINTLERÄ°
# âââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââ

@app.post("/api/analyze/risks", summary="Risk Analizi â Kural Motoru")
async def analyze_risks(req: AnalyzeRequest):
    """
    Hava + toprak + bitki verilerini alÄ±r, deterministik kural motoruyla
    risk listesi dÃ¶ndÃ¼rÃ¼r. Gemini/LLM kullanÄ±lmaz.
    """
    results = analyze(req)
    return {
        "success": True,
        "count": len(results),
        "results": [r.model_dump() for r in results],
    }


@app.get("/api/health", summary="Servis SaÄlÄ±k KontrolÃ¼")
async def health():
    return {"status": "ok", "service": "Smart Agri Backend"}


# -----------------------------------------------------------------------------
# BASIT AUTH + SYNC UCLARI (MVP)
# -----------------------------------------------------------------------------
# Not: Uretimde Firebase Admin ile token dogrulamasi yapilmalidir.
# Bu MVP'de bearer token dogrudan kullanici anahtari olarak ele alinir.


def _require_bearer_user(authorization: Optional[str]) -> str:
    if not authorization or not authorization.startswith("Bearer "):
        raise HTTPException(status_code=401, detail="Authorization Bearer token gerekli.")
    token = authorization.split(" ", 1)[1].strip()
    if not token:
        raise HTTPException(status_code=401, detail="Gecersiz Bearer token.")
    return token


class SyncPushItem(BaseModel):
    id: int
    entity_type: str
    entity_id: str
    operation: str
    payload: Any = Field(default_factory=dict)
    updated_at: datetime
    attempt_count: int = 0


class SyncPushRequest(BaseModel):
    items: List[SyncPushItem] = Field(default_factory=list)
    client_time: Optional[datetime] = None


_sync_store: dict[str, dict[str, dict[str, dict[str, Any]]]] = {}


def _upsert_sync_record(user_key: str, item: SyncPushItem) -> bool:
    user_bucket = _sync_store.setdefault(user_key, {})
    entity_bucket = user_bucket.setdefault(item.entity_type, {})
    existing = entity_bucket.get(item.entity_id)

    incoming_updated_at = item.updated_at.astimezone(timezone.utc)
    if existing is not None:
        existing_updated_at = existing["updated_at"]
        if incoming_updated_at <= existing_updated_at:
            return False

    entity_bucket[item.entity_id] = {
        "entity_type": item.entity_type,
        "entity_id": item.entity_id,
        "operation": item.operation,
        "payload": item.payload,
        "updated_at": incoming_updated_at,
    }
    return True


@app.post("/api/sync/push", summary="Outbox batch push (LWW)")
async def sync_push(req: SyncPushRequest, authorization: Optional[str] = Header(default=None)):
    user_key = _require_bearer_user(authorization)

    completed_ids: List[int] = []
    failed_by_id: dict[str, str] = {}

    for item in req.items:
        accepted = _upsert_sync_record(user_key, item)
        if accepted:
            completed_ids.append(item.id)
        else:
            failed_by_id[str(item.id)] = "stale_update"

    return {
        "success": True,
        "completed_ids": completed_ids,
        "failed_by_id": failed_by_id,
        "server_time": datetime.now(timezone.utc).isoformat(),
    }


@app.get("/api/sync/pull", summary="Sunucudan guncel kayitlari cek")
async def sync_pull(since: Optional[str] = None, authorization: Optional[str] = Header(default=None)):
    user_key = _require_bearer_user(authorization)

    since_dt: Optional[datetime] = None
    if since:
        try:
            since_clean = since.replace(" ", "+").replace("Z", "+00:00")
            since_dt = datetime.fromisoformat(since_clean).astimezone(timezone.utc)
        except Exception:
            raise HTTPException(status_code=400, detail="since parametresi ISO-8601 olmalidir.")

    user_bucket = _sync_store.get(user_key, {})
    out: List[dict[str, Any]] = []
    for entities in user_bucket.values():
        for rec in entities.values():
            updated_at = rec["updated_at"]
            if since_dt is not None and updated_at <= since_dt:
                continue
            out.append({
                "entity_type": rec["entity_type"],
                "entity_id": rec["entity_id"],
                "operation": rec["operation"],
                "payload": rec["payload"],
                "updated_at": updated_at.isoformat(),
            })

    out.sort(key=lambda x: x["updated_at"])

    return {
        "success": True,
        "items": out,
        "server_time": datetime.now(timezone.utc).isoformat(),
    }




# VeritabanÄ± baÄlantÄ± ayarÄ± (Kendi bilgilerine gÃ¶re gÃ¼ncelleyeceksin)
# DoÄru format: postgresql://kullanici_adi:sifre@localhost...
DATABASE_URL = os.getenv("DATABASE_URL", "postgresql://postgres:32542409@localhost:5432/smartagri")

# -- VERÄ° MODELLERÄ° (Flutter'dan gelecek JSON formatÄ±) --
class Coordinate(BaseModel):
    lat: float
    lng: float

class FieldCreateRequest(BaseModel):
    firebase_uid: str
    name: str
    area_dekar: float
    boundary: List[Coordinate]  # Flutter'dan gelen en az 4 kÃ¶Åe noktasÄ±

# -- API UÃ NOKTALARI (ENDPOINTS) --

@app.post("/api/fields/create", summary="Yeni Tarla Kaydet")
async def create_field(req: FieldCreateRequest):
    """
    Flutter'dan gelen 4 koordinatÄ± PostGIS Poligon formatÄ±na Ã§evirip veritabanÄ±na kaydeder.
    """
    # Poligonun kapanmasÄ± iÃ§in ilk noktanÄ±n en sona tekrar eklenmesi gerekir (PostGIS kuralÄ±)
    coords = req.boundary
    if len(coords) < 3:
        raise HTTPException(status_code=400, detail="Bir alan iÃ§in en az 3 nokta gereklidir.")
    
    # KoordinatlarÄ± "BOYLAM ENLEM" (LNG LAT) formatÄ±nda string'e Ã§eviriyoruz
    # Not: PostGIS her zaman X(Lng), Y(Lat) sÄ±rasÄ±nÄ± kullanÄ±r!
    polygon_points = ", ".join([f"{c.lng} {c.lat}" for c in coords])
    # Poligonu kapat
    polygon_points += f", {coords[0].lng} {coords[0].lat}"
    
    wkt_polygon = f"POLYGON(({polygon_points}))"

    try:
        conn = await asyncpg.connect(DATABASE_URL)
        
        # Ãnce Firebase UID'ye ait Ã§iftÃ§inin ID'sini bul
        farmer_id = await conn.fetchval(
            "SELECT id FROM farmers WHERE firebase_uid = $1", req.firebase_uid
        )
        if not farmer_id:
            # Gerekirse Ã§iftÃ§iyi otomatik oluÅtur
            farmer_id = await conn.fetchval(
                "INSERT INTO farmers (firebase_uid, full_name) VALUES ($1, $2) RETURNING id",
                req.firebase_uid, "Bilinmeyen ÃiftÃ§i"
            )

        # TarlayÄ± PostGIS dÃ¶nÃ¼ÅÃ¼mÃ¼ (ST_GeomFromText) ile kaydet
        query = """
            INSERT INTO fields (farmer_id, name, area_dekar, boundary)
            VALUES ($1, $2, $3, ST_GeomFromText($4, 4326))
            RETURNING id;
        """
        field_id = await conn.fetchval(query, farmer_id, req.name, req.area_dekar, wkt_polygon)
        await conn.close()
        
        return {"success": True, "message": "Tarla baÅarÄ±yla uydu aÄÄ±na eklendi!", "field_id": field_id}
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"VeritabanÄ± HatasÄ±: {str(e)}")

@app.get("/api/fields/{farmer_uid}", summary="ÃiftÃ§inin TarlalarÄ±nÄ± Getir")
async def get_farmer_fields(farmer_uid: str):
    """
    ÃiftÃ§inin kayÄ±tlÄ± tarlalarÄ±nÄ± ve merkez koordinatlarÄ±nÄ± (ST_Centroid) dÃ¶ndÃ¼rÃ¼r.
    """
    conn = await asyncpg.connect(DATABASE_URL)
    query = """
        SELECT f.id, f.name, f.area_dekar, 
               ST_Y(ST_Centroid(f.boundary)) as center_lat, 
               ST_X(ST_Centroid(f.boundary)) as center_lng
        FROM fields f
        JOIN farmers frm ON f.farmer_id = frm.id
        WHERE frm.firebase_uid = $1
    """
    rows = await conn.fetch(query, farmer_uid)
    await conn.close()
    
    return {"success": True, "fields": [dict(r) for r in rows]}
# -- YENÝ: TARLAYA BÝTKÝ EKME VE KARÞILAÞTIRMA --

try:
    from .agri_api import fetch_plant_details_from_perenual
except ImportError:
    from agri_api import fetch_plant_details_from_perenual

class PlantCropRequest(BaseModel):
    query: str  # Bitki adý
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

@app.post("/api/fields/{field_id}/plant", summary="Tarlaya Bitki Ek ve Karþýlaþtýr")
async def plant_crop(field_id: int, req: PlantCropRequest):
    """
    Belirli bir tarlaya bitki eklerken (örn: Domates), Perenual API'den detaylarý çeker (veya veritabanýndan),
    field_plants tablosuna kaydeder ve çevresel faktörlerle yapýlmýþ son derece kesin risk analizini döner.
    """
    conn = await asyncpg.connect(DATABASE_URL)
    try:
        query_text = "SELECT * FROM plants WHERE common_name ILIKE $1 OR scientific_name ILIKE $1 LIMIT 1"
        plant_record = await conn.fetchrow(query_text, f"%{req.query}%")
        
        plant_id = None
        plant_details_dict = {}

        if plant_record:
            plant_id = plant_record['id']
            plant_details_dict = dict(plant_record)
        else:
            fetched_data = await fetch_plant_details_from_perenual(req.query)
            if fetched_data:
                insert_query = """
                    INSERT INTO plants (scientific_name, common_name, family, cycle, watering, sunlight, 
                                        hardiness_min, hardiness_max, ideal_ph_min, ideal_ph_max, 
                                        ideal_temp_min, ideal_temp_max, care_level, disease_risks)
                    VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14)
                    RETURNING id
                """
                try:
                    plant_id = await conn.fetchval(insert_query, 
                        fetched_data['scientific_name'], fetched_data['common_name'], 
                        fetched_data['family'], fetched_data['cycle'], fetched_data['watering'], 
                        fetched_data['sunlight'], fetched_data['hardiness_min'], fetched_data['hardiness_max'],
                        fetched_data['ideal_ph_min'], fetched_data['ideal_ph_max'], 
                        fetched_data['ideal_temp_min'], fetched_data['ideal_temp_max'], 
                        fetched_data['care_level'], fetched_data['disease_risks']
                    )
                    plant_details_dict = fetched_data
                except Exception as e:
                    print("DB Insert Error:", e)
                    pass
        
        if plant_id:
            await conn.execute("INSERT INTO field_plants (field_id, plant_id) VALUES ($1, $2)", field_id, plant_id)
        
        await conn.close()

        analyze_req = AnalyzeRequest(
            common_name=plant_details_dict.get('common_name', req.query) if plant_details_dict else req.query,
            scientific_name=plant_details_dict.get('scientific_name', '') if plant_details_dict else '',
            plant_details=plant_details_dict if plant_details_dict else {},
            temperature=req.temperature,
            avg_weekly_temp=req.avg_weekly_temp,
            humidity=req.humidity,
            weekly_rain=req.weekly_rain,
            soil_ph=req.soil_ph,
            soil_moisture=req.soil_moisture,
            soil_temp_c=req.soil_temp_c,
            ndvi=req.ndvi,
            wind_speed=req.wind_speed,
            month=req.month,
            precip_prob_next3h=req.precip_prob_next3h
        )

        results = analyze(analyze_req)

        return {
            "success": True,
            "plant_info": plant_details_dict,
            "comparison_results": [r.model_dump() for r in results]
        }
        
    except Exception as e:
        await conn.close()
        raise HTTPException(status_code=500, detail=str(e))


# ═══════════════════════════════════════════════════════════════════════════════
# AKILLI SULAMA PROGRAMI (Smart Irrigation Schedule) — FAO Penman-Monteith ETo
# ═══════════════════════════════════════════════════════════════════════════════
# Tur + yagis tahmini + toprak nemi -> 7 gunluk sulama plani.
# Karar mantigi rule_engine.analyze icindeki _irrigation_rules ve _weather_rules
# kategorilerinden uretilir + FAO-56 Penman-Monteith referans
# evapotranspirasyonu (ETo) ile bitki su ihtiyaci (ETc = Kc * ETo) hesaplanir.
#
# Kaynak: FAO Irrigation and Drainage Paper No. 56
# "Crop evapotranspiration — Guidelines for computing crop water requirements"
# Allen, Pereira, Raes, Smith (1998) — https://www.fao.org/3/X0490E/x0490e00.htm

import math as _math


def _fao_eto(t_max, t_min, rh_mean, wind_ms, lat_deg, day_of_year, elev_m=500):
    """
    FAO-56 Penman-Monteith referans evapotranspirasyon (mm/gun).
    Solar radyasyon Hargreaves yaklasimi (FAO-56 Eq. 50) ile hesaplanir.
    """
    t_mean = (t_max + t_min) / 2.0
    p = 101.3 * ((293.0 - 0.0065 * elev_m) / 293.0) ** 5.26  # Eq. 7
    gamma = 0.000665 * p                                     # Eq. 8

    es_tmax = 0.6108 * _math.exp((17.27 * t_max) / (t_max + 237.3))
    es_tmin = 0.6108 * _math.exp((17.27 * t_min) / (t_min + 237.3))
    es = (es_tmax + es_tmin) / 2.0
    ea = (es * rh_mean / 100.0)

    delta = (4098 * (0.6108 * _math.exp((17.27 * t_mean) / (t_mean + 237.3)))) \
            / (t_mean + 237.3) ** 2

    # Hargreaves Rs (Eq. 50) — solar radyasyon yoksa yaklaşık
    phi = lat_deg * _math.pi / 180.0
    decl = 0.409 * _math.sin((2 * _math.pi / 365.0) * day_of_year - 1.39)
    ws = _math.acos(max(-1, min(1, -_math.tan(phi) * _math.tan(decl))))
    dr = 1 + 0.033 * _math.cos((2 * _math.pi / 365.0) * day_of_year)
    ra = (24 * 60 / _math.pi) * 0.0820 * dr * (
        ws * _math.sin(phi) * _math.sin(decl) +
        _math.cos(phi) * _math.cos(decl) * _math.sin(ws)
    )
    rs = 0.16 * _math.sqrt(max(0.1, abs(t_max - t_min))) * ra
    rn = 0.77 * rs

    num = 0.408 * delta * rn + gamma * (900.0 / (t_mean + 273.0)) * wind_ms * (es - ea)
    den = delta + gamma * (1.0 + 0.34 * wind_ms)
    eto = num / den
    return max(0.0, eto)


# FAO-56 Table 12 — bitki katsayilari (Kc) — Turkce ad → (kc_init, kc_mid, kc_end, total_days)
FAO_KC = {
    "domates":      (0.60, 1.15, 0.80, 135),
    "biber":        (0.60, 1.05, 0.90, 125),
    "patlican":     (0.60, 1.05, 0.90, 130),
    "salatalik":    (0.60, 1.00, 0.75, 105),
    "kabak":        (0.50, 1.00, 0.80, 100),
    "karpuz":       (0.40, 1.00, 0.75, 100),
    "kavun":        (0.50, 1.05, 0.75, 100),
    "patates":      (0.50, 1.15, 0.75, 130),
    "sogan":        (0.70, 1.05, 0.75, 150),
    "havuc":        (0.70, 1.05, 0.95, 115),
    "lahana":       (0.70, 1.05, 0.95, 130),
    "fasulye":      (0.50, 1.05, 0.90, 90),
    "nohut":        (0.40, 1.00, 0.35, 95),
    "mercimek":     (0.40, 1.10, 0.30, 150),
    "bugday":       (0.70, 1.15, 0.40, 235),
    "arpa":         (0.30, 1.15, 0.25, 130),
    "misir":        (0.30, 1.20, 0.60, 150),
    "celtik":       (1.05, 1.20, 0.90, 150),
    "aycicegi":     (0.35, 1.15, 0.35, 130),
    "pamuk":        (0.35, 1.20, 0.60, 195),
    "sekerpancari": (0.35, 1.20, 0.70, 180),
    "yonca":        (0.40, 0.95, 0.90, 165),
    "uzum":         (0.30, 0.85, 0.45, 205),
    "zeytin":       (0.65, 0.70, 0.70, 365),
    "elma":         (0.60, 0.95, 0.75, 240),
}


def _normalize_crop(name: str) -> str:
    s = name.lower().strip()
    return (s.replace("ç", "c").replace("ğ", "g").replace("ı", "i")
             .replace("ö", "o").replace("ş", "s").replace("ü", "u"))


def _lookup_kc(crop_name: str, days_since_planted: int = 60):
    """Bitki adina ve ekim sonrasi gun sayisina gore Kc dondurur."""
    key = _normalize_crop(crop_name)
    spec = FAO_KC.get(key)
    if spec is None:
        for k, v in FAO_KC.items():
            if k in key or key in k:
                spec = v
                break
    if spec is None:
        return 1.0  # default
    kc_init, kc_mid, kc_end, total = spec
    pct = days_since_planted / total
    if pct < 0.20:
        return kc_init
    if pct < 0.75:
        return kc_mid
    return kc_end

class IrrigationDailyForecast(BaseModel):
    date: str                       # ISO yyyy-mm-dd
    temp_c: float
    humidity: float
    precip_mm: float                # gunluk toplam yagis (mm)
    precip_prob_pct: float = 0.0    # yagis olasiligi (0-100)
    wind_speed_ms: float = 0.0


class IrrigationScheduleRequest(BaseModel):
    common_name: str = ""
    plant_details: dict = Field(default_factory=dict)
    soil_ph: float = 6.8
    soil_moisture: float = 0.25
    soil_temp_c: float = 15.0
    ndvi: float = 0.6
    latitude: float = 39.0           # FAO ETo radyasyon hesabı için
    elevation_m: float = 500.0       # Penman-Monteith atmosferik basınç
    days_since_planted: int = 60     # Kc gelişim evresi seçimi için
    days: List[IrrigationDailyForecast] = Field(default_factory=list)


class IrrigationDayPlan(BaseModel):
    date: str
    should_irrigate: bool
    level: str                  # critical | warning | info | ok
    title: str
    reason: str
    recommendation: str
    estimated_mm: float = 0.0   # onerilen sulama miktari (mm)
    eto_mm: float = 0.0         # FAO referans evapotranspirasyon (mm/gun)
    etc_mm: float = 0.0         # Bitki su ihtiyaci ETc = Kc * ETo (mm/gun)
    kc: float = 1.0             # FAO-56 Tablo 12 bitki katsayisi


@app.post("/api/irrigation/schedule", summary="Akilli Sulama Programi (7 Gun)")
async def irrigation_schedule(req: IrrigationScheduleRequest):
    """
    Bitki + tarla + 7 gunluk hava tahminini alir, her gun icin sulama karari uretir.
    Karar motoru rule_engine._irrigation_rules + _weather_rules uzerinden calisir.
    """
    if not req.days:
        raise HTTPException(status_code=400, detail="En az 1 gunluk tahmin gereklidir.")

    plant = req.plant_details or {}

    # FAO-56 Kc katsayisi (bitki + gelisim evresi)
    kc = _lookup_kc(req.common_name, days_since_planted=req.days_since_planted)

    plan: list[IrrigationDayPlan] = []
    running_soil_moisture = req.soil_moisture

    for day in req.days:
        try:
            day_dt = datetime.fromisoformat(day.date)
        except Exception:
            day_dt = datetime.now(timezone.utc)
        month = day_dt.month
        doy = day_dt.timetuple().tm_yday

        # FAO Penman-Monteith ETo ve bitki su ihtiyaci ETc
        # Tahmin verisinden tmax/tmin yerine ortalama ± varyasyon kullaniyoruz.
        t_avg = day.temp_c
        t_max = t_avg + 5.0
        t_min = t_avg - 5.0
        eto_mm = _fao_eto(
            t_max=t_max, t_min=t_min,
            rh_mean=day.humidity, wind_ms=day.wind_speed_ms,
            lat_deg=req.latitude, day_of_year=doy,
            elev_m=req.elevation_m,
        )
        etc_mm = eto_mm * kc

        analyze_req = AnalyzeRequest(
            common_name=req.common_name,
            plant_details=plant,
            temperature=day.temp_c,
            avg_weekly_temp=day.temp_c,
            humidity=day.humidity,
            weekly_rain=sum(d.precip_mm for d in req.days),
            soil_ph=req.soil_ph,
            soil_moisture=running_soil_moisture,
            soil_temp_c=req.soil_temp_c,
            ndvi=req.ndvi,
            wind_speed=day.wind_speed_ms,
            month=month,
            precip_prob_next3h=day.precip_prob_pct,
        )

        results = analyze(analyze_req)
        irr_results = [r for r in results if r.category == RuleCategory.irrigation]
        weather_block = [
            r for r in results
            if r.category == RuleCategory.weather and r.level in (RiskLevel.critical, RiskLevel.warning)
            and ("Yagmur" in r.title or "Yağmur" in r.title or "Aşırı Yağış" in r.title or "Yüksek Yağış" in r.title)
        ]

        should_irrigate = False
        title = "Sulama Gerekmiyor"
        reason = "Mevcut kosullarda toprak nemi yeterli."
        recommendation = "Bugun sulama yapmayin."
        level = "ok"
        estimated_mm = 0.0

        # Yagis bekleniyorsa veya yagis yuksekse sulama iptal
        if day.precip_mm >= 5 or day.precip_prob_pct >= 70 or weather_block:
            should_irrigate = False
            title = "Yagis Bekleniyor"
            reason = f"Tahmini yagis {day.precip_mm:.0f} mm (%{round(day.precip_prob_pct)} olasilik)."
            recommendation = "Sulamayi erteleyin. Drenaji kontrol edin."
            level = "info"
        elif irr_results:
            top = irr_results[0]
            level = top.level.value
            title = top.title
            reason = top.message
            recommendation = top.recommendation
            should_irrigate = top.level in (RiskLevel.critical, RiskLevel.warning) and "Cok Nemli" not in top.title and "Cürüklüğü" not in top.title and "Çürüklüğü" not in top.title
            if should_irrigate:
                # FAO-56: ETc - efektif yagis = net sulama ihtiyaci
                # Efektif yagis: yagisin yaklaşık %80'i bitkiye ulasir (USDA SCS)
                effective_rain = day.precip_mm * 0.80
                net_need = etc_mm - effective_rain
                estimated_mm = round(max(0.0, net_need), 1)

        # Toprak nemini iteratif guncelle: gunluk net = yagis + sulama - ETc
        net_water_mm = day.precip_mm + estimated_mm - etc_mm
        running_soil_moisture += net_water_mm * 0.003
        running_soil_moisture = max(0.05, min(0.6, running_soil_moisture))

        plan.append(IrrigationDayPlan(
            date=day.date,
            should_irrigate=should_irrigate,
            level=level,
            title=title,
            reason=reason,
            recommendation=recommendation,
            estimated_mm=estimated_mm,
            eto_mm=round(eto_mm, 2),
            etc_mm=round(etc_mm, 2),
            kc=round(kc, 2),
        ))

    total_mm = round(sum(p.estimated_mm for p in plan), 1)
    total_etc = round(sum(p.etc_mm for p in plan), 1)
    irrigation_days = sum(1 for p in plan if p.should_irrigate)

    return {
        "success": True,
        "summary": {
            "total_days": len(plan),
            "irrigation_days": irrigation_days,
            "total_water_mm": total_mm,
            "total_crop_demand_mm": total_etc,
            "kc_used": round(kc, 2),
            "method": "FAO-56 Penman-Monteith (Allen et al., 1998)",
        },
        "plan": [p.model_dump() for p in plan],
    }


# ═══════════════════════════════════════════════════════════════════════════════
# ADMIN PANEL ENDPOINTLERI
# ═══════════════════════════════════════════════════════════════════════════════
# Tum admin endpointleri X-Admin-Key header ile korunur.
# Admin anahtari cevresel degisken olarak ayarlanir.

ADMIN_API_KEY = os.getenv("ADMIN_API_KEY", "admin-secret-key-change-me")

# API trafik sayaci (in-memory, restart'ta sifirlanir)
_api_traffic: dict[str, int] = {}
_server_start_time = datetime.now(timezone.utc)


def _require_admin(x_admin_key: Optional[str]) -> None:
    """Admin isteklerini X-Admin-Key header ile dogrula."""
    if not x_admin_key or x_admin_key != ADMIN_API_KEY:
        raise HTTPException(status_code=403, detail="Gecersiz admin anahtari.")


@app.middleware("http")
async def track_api_traffic(request, call_next):
    """Her API istegini say — admin/traffic endpointi icin."""
    path = request.url.path
    _api_traffic[path] = _api_traffic.get(path, 0) + 1
    response = await call_next(request)
    return response


# ── GET /api/admin/users ──────────────────────────────────────────────────────

@app.get("/api/admin/users", summary="Kullanici Listesi ve Sync Durumu")
async def admin_list_users(x_admin_key: Optional[str] = Header(default=None)):
    """
    Tum kayitli kullanicilari, sync store'daki kayit sayilarini
    ve son aktivite zamanlarini doner.
    """
    _require_admin(x_admin_key)

    users = []
    for user_key, entities in _sync_store.items():
        total_records = 0
        entity_counts = {}
        latest_update = None

        for entity_type, records in entities.items():
            count = len(records)
            entity_counts[entity_type] = count
            total_records += count

            for rec in records.values():
                updated = rec.get("updated_at")
                if updated and (latest_update is None or updated > latest_update):
                    latest_update = updated

        users.append({
            "user_key": user_key,
            "total_synced_records": total_records,
            "entity_counts": entity_counts,
            "last_activity": latest_update.isoformat() if latest_update else None,
            "status": "active",
        })

    return {
        "success": True,
        "total_users": len(users),
        "users": users,
    }


# ── GET /api/admin/traffic ────────────────────────────────────────────────────

@app.get("/api/admin/traffic", summary="API Trafik Istatistikleri")
async def admin_traffic(x_admin_key: Optional[str] = Header(default=None)):
    """
    Sunucu baslatildigindan bu yana her endpoint icin istek sayisini doner.
    """
    _require_admin(x_admin_key)

    total_requests = sum(_api_traffic.values())
    sorted_endpoints = sorted(_api_traffic.items(), key=lambda x: x[1], reverse=True)

    uptime_seconds = (datetime.now(timezone.utc) - _server_start_time).total_seconds()

    return {
        "success": True,
        "server_start_time": _server_start_time.isoformat(),
        "uptime_seconds": int(uptime_seconds),
        "total_requests": total_requests,
        "endpoints": [
            {"path": path, "request_count": count}
            for path, count in sorted_endpoints
        ],
    }


# ── POST /api/admin/content ───────────────────────────────────────────────────

class ContentUpdateRequest(BaseModel):
    """Ansiklopedi veya genel icerik guncelleme istegi."""
    entity_type: str = Field(..., description="Icerik turu, ornegin 'encyclopedia'")
    entity_id: str = Field(..., description="Guncellenen kaydin kimliği")
    payload: dict[str, Any] = Field(default_factory=dict, description="Guncel icerik verisi")


@app.get("/admin", summary="Web Yonetim Paneli (HTML)")
async def admin_panel_page():
    """
    Admin yonetim panelini HTML olarak dondurur.
    Kullanici tarayicida X-Admin-Key girer; key localStorage'a kaydedilir.
    """
    html_path = Path(__file__).parent / "admin_panel.html"
    if not html_path.exists():
        raise HTTPException(status_code=404, detail="admin_panel.html bulunamadi.")
    return FileResponse(html_path, media_type="text/html")


@app.post("/api/admin/content", summary="Icerik Guncelleme (Ansiklopedi vs.)")
async def admin_update_content(
    req: ContentUpdateRequest,
    x_admin_key: Optional[str] = Header(default=None),
):
    """
    Admin panelinden ansiklopedi veya diger icerik verilerini gunceller.
    Guncelleme tum kullanicilarin pull cycle'inda dagitilir.
    """
    _require_admin(x_admin_key)

    now = datetime.now(timezone.utc)

    # Ozel 'admin' bucket'ina kaydet — tum kullanicilar pull ederken bu kayitlari alir
    admin_bucket = _sync_store.setdefault("__admin_content__", {})
    entity_bucket = admin_bucket.setdefault(req.entity_type, {})
    entity_bucket[req.entity_id] = {
        "entity_type": req.entity_type,
        "entity_id": req.entity_id,
        "operation": "upsert",
        "payload": req.payload,
        "updated_at": now,
    }

    return {
        "success": True,
        "message": f"Icerik guncellendi: {req.entity_type}/{req.entity_id}",
        "updated_at": now.isoformat(),
    }


# ── POST /api/admin/broadcast ─────────────────────────────────────────────────
# Toplu bildirim — admin bucket uzerinden tum kullanicilara dagitilir.
# Istemci sync pull cycle'inde bildirimi alip yerel notification olarak gosterir.

class BroadcastRequest(BaseModel):
    """Toplu bildirim istegi."""
    title: str = Field(..., min_length=1, max_length=120, description="Bildirim basligi")
    body: str = Field(..., min_length=1, max_length=500, description="Bildirim govdesi")
    target: str = Field(default="all", description="Hedef: 'all' veya kullanici anahtari")
    severity: str = Field(default="info", description="info | warning | critical")


@app.post("/api/admin/broadcast", summary="Toplu Bildirim Gonderme")
async def admin_broadcast(
    req: BroadcastRequest,
    x_admin_key: Optional[str] = Header(default=None),
):
    """
    Toplu bildirimi admin bucket'ina kaydeder. Istemciler sync pull cycle'inde
    bu bildirimleri cekip yerel olarak gosterir. Cevrimdisi kullanicilar
    bir sonraki sync'te alir.
    """
    _require_admin(x_admin_key)

    if req.severity not in ("info", "warning", "critical"):
        raise HTTPException(status_code=400, detail="severity: info|warning|critical")

    now = datetime.now(timezone.utc)
    notif_id = f"broadcast_{int(now.timestamp() * 1000)}"

    admin_bucket = _sync_store.setdefault("__admin_content__", {})
    notif_bucket = admin_bucket.setdefault("notifications", {})
    notif_bucket[notif_id] = {
        "entity_type": "notifications",
        "entity_id": notif_id,
        "operation": "upsert",
        "payload": {
            "id": notif_id,
            "title": req.title,
            "body": req.body,
            "severity": req.severity,
            "target": req.target,
            "sent_at": now.isoformat(),
        },
        "updated_at": now,
    }

    return {
        "success": True,
        "message": f"Bildirim kuyruga alindi: {notif_id}",
        "notification_id": notif_id,
        "sent_at": now.isoformat(),
    }
