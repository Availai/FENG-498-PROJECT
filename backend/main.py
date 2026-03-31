# main.py
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from typing import List
import asyncpg
import os

app = FastAPI(title="Smart Agri Backend API", version="1.0")

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