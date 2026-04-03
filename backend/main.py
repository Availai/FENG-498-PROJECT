# main.py
from fastapi import FastAPI, HTTPException, Header
from pydantic import BaseModel
from datetime import datetime, timezone
from typing import List, Optional, Any
import asyncpg
import os
try:
    from .rule_engine import analyze, AnalyzeRequest
except ImportError:
    from rule_engine import analyze, AnalyzeRequest

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
    payload: Any = {}
    updated_at: datetime
    attempt_count: int = 0


class SyncPushRequest(BaseModel):
    items: List[SyncPushItem] = []
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
