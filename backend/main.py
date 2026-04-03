# main.py
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from typing import List
import asyncpg
import os
from rule_engine import analyze, AnalyzeRequest

app = FastAPI(title="Smart Agri Backend API", version="1.0")


# ─────────────────────────────────────────────────────────────────────────────
# KURAL MOTORU ENDPOINTLERİ
# ─────────────────────────────────────────────────────────────────────────────

@app.post("/api/analyze/risks", summary="Risk Analizi — Kural Motoru")
async def analyze_risks(req: AnalyzeRequest):
    """
    Hava + toprak + bitki verilerini alır, deterministik kural motoruyla
    risk listesi döndürür. Gemini/LLM kullanılmaz.
    """
    results = analyze(req)
    return {
        "success": True,
        "count": len(results),
        "results": [r.model_dump() for r in results],
    }


@app.get("/api/health", summary="Servis Sağlık Kontrolü")
async def health():
    return {"status": "ok", "service": "Smart Agri Backend"}



# Veritabanı bağlantı ayarı (Kendi bilgilerine göre güncelleyeceksin)
# Doğru format: postgresql://kullanici_adi:sifre@localhost...
DATABASE_URL = os.getenv("DATABASE_URL", "postgresql://postgres:32542409@localhost:5432/smartagri")

# -- VERİ MODELLERİ (Flutter'dan gelecek JSON formatı) --
class Coordinate(BaseModel):
    lat: float
    lng: float

class FieldCreateRequest(BaseModel):
    firebase_uid: str
    name: str
    area_dekar: float
    boundary: List[Coordinate]  # Flutter'dan gelen en az 4 köşe noktası

# -- API UÇ NOKTALARI (ENDPOINTS) --

@app.post("/api/fields/create", summary="Yeni Tarla Kaydet")
async def create_field(req: FieldCreateRequest):
    """
    Flutter'dan gelen 4 koordinatı PostGIS Poligon formatına çevirip veritabanına kaydeder.
    """
    # Poligonun kapanması için ilk noktanın en sona tekrar eklenmesi gerekir (PostGIS kuralı)
    coords = req.boundary
    if len(coords) < 3:
        raise HTTPException(status_code=400, detail="Bir alan için en az 3 nokta gereklidir.")
    
    # Koordinatları "BOYLAM ENLEM" (LNG LAT) formatında string'e çeviriyoruz
    # Not: PostGIS her zaman X(Lng), Y(Lat) sırasını kullanır!
    polygon_points = ", ".join([f"{c.lng} {c.lat}" for c in coords])
    # Poligonu kapat
    polygon_points += f", {coords[0].lng} {coords[0].lat}"
    
    wkt_polygon = f"POLYGON(({polygon_points}))"

    try:
        conn = await asyncpg.connect(DATABASE_URL)
        
        # Önce Firebase UID'ye ait çiftçinin ID'sini bul
        farmer_id = await conn.fetchval(
            "SELECT id FROM farmers WHERE firebase_uid = $1", req.firebase_uid
        )
        if not farmer_id:
            # Gerekirse çiftçiyi otomatik oluştur
            farmer_id = await conn.fetchval(
                "INSERT INTO farmers (firebase_uid, full_name) VALUES ($1, $2) RETURNING id",
                req.firebase_uid, "Bilinmeyen Çiftçi"
            )

        # Tarlayı PostGIS dönüşümü (ST_GeomFromText) ile kaydet
        query = """
            INSERT INTO fields (farmer_id, name, area_dekar, boundary)
            VALUES ($1, $2, $3, ST_GeomFromText($4, 4326))
            RETURNING id;
        """
        field_id = await conn.fetchval(query, farmer_id, req.name, req.area_dekar, wkt_polygon)
        await conn.close()
        
        return {"success": True, "message": "Tarla başarıyla uydu ağına eklendi!", "field_id": field_id}
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Veritabanı Hatası: {str(e)}")

@app.get("/api/fields/{farmer_uid}", summary="Çiftçinin Tarlalarını Getir")
async def get_farmer_fields(farmer_uid: str):
    """
    Çiftçinin kayıtlı tarlalarını ve merkez koordinatlarını (ST_Centroid) döndürür.
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
# -- YEN�: TARLAYA B�TK� EKME VE KAR�ILA�TIRMA --

from agri_api import fetch_plant_details_from_perenual

class PlantCropRequest(BaseModel):
    query: str  # Bitki ad�
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

@app.post("/api/fields/{field_id}/plant", summary="Tarlaya Bitki Ek ve Kar��la�t�r")
async def plant_crop(field_id: int, req: PlantCropRequest):
    """
    Belirli bir tarlaya bitki eklerken (�rn: Domates), Perenual API'den detaylar� �eker (veya veritaban�ndan),
    field_plants tablosuna kaydeder ve �evresel fakt�rlerle yap�lm�� son derece kesin risk analizini d�ner.
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
