"""
Proxy Endpoints — Paralı/secret 3rd-party API'ler için backend katmanı.

Mimarinin gereği: API anahtarları sadece backend ortamında kalır, Flutter
istemcisi bu anahtarlara dokunmaz. İstemci backend'e ham parametreler
(görüntü baytları, koordinat, sorgu) gönderir; backend dış servisi çağırıp
sadeleştirilmiş JSON döndürür.

Bu modül `main.py` tarafından `include_router` ile bağlanır.

Servisler:
  • Perenual    → bitki türü detayı (paid key)
  • Imagga      → görüntü etiketleme (paid key + secret)
  • PlantNet    → bitki tanıma (paid key)
  • Gemini      → görüntü tabanlı hastalık tanısı (paid key)
  • Agromonitoring → polygon + toprak verisi (paid key)
  • NASA POWER  → tarihi iklim verisi (key gerekmez ama harici)

Ayrıca üç deterministik metin üretici (rule_engine.dart paritesinde):
  • /api/analyze/field_plan
  • /api/analyze/weekly_comment
  • /api/analyze/environmental_report
"""

from __future__ import annotations

import base64
import os
from datetime import datetime
from typing import Any, Optional

import httpx
from fastapi import APIRouter, File, HTTPException, UploadFile, Form
from pydantic import BaseModel, Field

router = APIRouter(prefix="/api", tags=["proxy"])


# ─────────────────────────────────────────────────────────────────────────────
# ORTAM ANAHTARLARI — backend'in .env dosyasından okunur
# ─────────────────────────────────────────────────────────────────────────────

_PERENUAL_KEY = os.getenv("PERENUAL_API_KEY", "")
_IMAGGA_KEY = os.getenv("IMAGGA_API_KEY", "")
_IMAGGA_SECRET = os.getenv("IMAGGA_API_SECRET", "")
_PLANTNET_KEY = os.getenv("PLANTNET_API_KEY", "")
_GEMINI_KEY = os.getenv("GEMINI_API_KEY", "")
_AGRO_KEY = os.getenv("AGROMONITORING_API_KEY", "")

_HTTP_TIMEOUT = httpx.Timeout(25.0, connect=10.0)


def _require_key(value: str, name: str) -> None:
    if not value:
        raise HTTPException(
            status_code=503,
            detail=f"{name} backend tarafında yapılandırılmamış.",
        )


# ═════════════════════════════════════════════════════════════════════════════
# PERENUAL — bitki tür detayı
# ═════════════════════════════════════════════════════════════════════════════


@router.get("/proxy/plants/details", summary="Perenual — Bitki Detayı (proxy)")
async def perenual_details(
    common_name: str = "",
    scientific_name: str = "",
):
    """Perenual species-list + species/details + care-guide birleşik cevabı."""
    _require_key(_PERENUAL_KEY, "PERENUAL_API_KEY")
    if not common_name and not scientific_name:
        raise HTTPException(
            status_code=400,
            detail="common_name veya scientific_name parametrelerinden biri gerekli.",
        )

    query = common_name or scientific_name
    async with httpx.AsyncClient(timeout=_HTTP_TIMEOUT) as client:
        try:
            search_resp = await client.get(
                "https://perenual.com/api/v2/species-list",
                params={"key": _PERENUAL_KEY, "q": query},
            )
        except httpx.HTTPError as e:
            raise HTTPException(status_code=502, detail=f"Perenual erişilemedi: {e}")

        if search_resp.status_code != 200:
            raise HTTPException(
                status_code=502,
                detail=f"Perenual HTTP {search_resp.status_code}",
            )

        data_list = (search_resp.json() or {}).get("data") or []
        if not data_list:
            return {"success": True, "data": {}}

        # Bilimsel isim önceliğiyle en iyi eşleşmeyi bul
        species_id = data_list[0].get("id")
        if scientific_name:
            sci_first = scientific_name.lower().split()[0]
            for item in data_list:
                names = item.get("scientific_name") or []
                if any(sci_first in str(n).lower() for n in names):
                    species_id = item.get("id")
                    break

        if not species_id:
            return {"success": True, "data": {}}

        try:
            detail_resp = await client.get(
                f"https://perenual.com/api/v2/species/details/{species_id}",
                params={"key": _PERENUAL_KEY},
            )
        except httpx.HTTPError:
            return {"success": True, "data": {}}

        if detail_resp.status_code != 200:
            return {"success": True, "data": {}}
        d = detail_resp.json() or {}

        # Ham yanıtı uniform şekle indir
        result: dict[str, Any] = {
            "common_name": d.get("common_name") or common_name,
            "other_names": ", ".join(d.get("other_name") or []) or common_name,
            "type": d.get("type") or "Bilinmiyor",
            "cycle": d.get("cycle") or "Bilinmiyor",
            "watering": d.get("watering") or "Bilinmiyor",
            "watering_benchmark": d.get("watering_general_benchmark"),
            "sunlight": ", ".join(d.get("sunlight") or []) or "Tam güneş",
            "soil": ", ".join(d.get("soil") or []) or "Bilinmiyor",
            "growth_rate": d.get("growth_rate") or "Bilinmiyor",
            "maintenance": d.get("maintenance") or "Bilinmiyor",
            "care_level": d.get("care_level") or "Bilinmiyor",
            "description": d.get("description") or "",
            "indoor": d.get("indoor") or False,
            "flowers": d.get("flowers") or False,
            "flowering_season": d.get("flowering_season"),
            "fruiting_season": d.get("fruiting_season"),
            "harvest_season": d.get("harvest_season"),
            "harvest_method": d.get("harvest_method"),
            "edible_fruit": d.get("edible_fruit") or False,
            "edible_leaf": d.get("edible_leaf") or False,
            "medicinal": d.get("medicinal") or False,
            "poisonous_to_humans": d.get("poisonous_to_humans") or False,
            "poisonous_to_pets": d.get("poisonous_to_pets") or False,
            "drought_tolerant": d.get("drought_tolerant") or False,
            "salt_tolerant": d.get("salt_tolerant") or False,
            "invasive": d.get("invasive") or False,
            "tropical": d.get("tropical") or False,
            "pest_susceptibility": ", ".join(d.get("pest_susceptibility") or []) or None,
            "pruning_month": ", ".join(d.get("pruning_month") or []) or None,
            "hardiness_min": (d.get("hardiness") or {}).get("min"),
            "hardiness_max": (d.get("hardiness") or {}).get("max"),
            "origin": ", ".join(d.get("origin") or []) or None,
            "dimensions": d.get("dimensions"),
            "propagation": ", ".join(d.get("propagation") or []) or None,
        }

        # Bakım rehberi
        try:
            care_resp = await client.get(
                "https://perenual.com/api/species-care-guide-list",
                params={"species_id": species_id, "key": _PERENUAL_KEY},
            )
            if care_resp.status_code == 200:
                care_data = care_resp.json() or {}
                care_list = care_data.get("data") or []
                if care_list:
                    sections = care_list[0].get("section") or []
                    parts = []
                    for sec in sections:
                        t = (sec.get("type") or "").strip()
                        desc = (sec.get("description") or "").strip()
                        if desc:
                            parts.append(f"{_translate_care_type(t)}: {desc}")
                    if parts:
                        result["care_description"] = "\n\n".join(parts)
        except httpx.HTTPError:
            pass

        return {"success": True, "data": result}


def _translate_care_type(t: str) -> str:
    return {
        "watering": "Sulama",
        "sunlight": "Güneş",
        "pruning": "Budama",
    }.get(t.lower(), t.title() or "Bakım")


# ═════════════════════════════════════════════════════════════════════════════
# IMAGGA — görüntü etiketleme (Gatekeeper)
# ═════════════════════════════════════════════════════════════════════════════


@router.post("/proxy/vision/imagga", summary="Imagga — Görüntü Etiketleme (proxy)")
async def imagga_tags(image: UploadFile = File(...)):
    """Görüntü baytlarını alır, Imagga'dan tag listesi döner."""
    _require_key(_IMAGGA_KEY, "IMAGGA_API_KEY")
    _require_key(_IMAGGA_SECRET, "IMAGGA_API_SECRET")

    creds = base64.b64encode(f"{_IMAGGA_KEY}:{_IMAGGA_SECRET}".encode()).decode()
    img_bytes = await image.read()

    async with httpx.AsyncClient(timeout=_HTTP_TIMEOUT) as client:
        try:
            resp = await client.post(
                "https://api.imagga.com/v2/tags",
                headers={"Authorization": f"Basic {creds}"},
                files={"image": (image.filename or "img.jpg", img_bytes)},
            )
        except httpx.HTTPError as e:
            raise HTTPException(status_code=502, detail=f"Imagga erişilemedi: {e}")

    if resp.status_code != 200:
        raise HTTPException(status_code=502, detail=f"Imagga HTTP {resp.status_code}")
    body = resp.json() or {}
    tags = (body.get("result") or {}).get("tags") or []
    flat = [(t.get("tag") or {}).get("en", "") for t in tags[:15]]
    return {
        "success": True,
        "tags": [t for t in flat if t],
    }


# ═════════════════════════════════════════════════════════════════════════════
# PLANTNET — tür tanıma
# ═════════════════════════════════════════════════════════════════════════════


@router.post("/proxy/vision/plantnet", summary="PlantNet — Tür Tanıma (proxy)")
async def plantnet_identify(image: UploadFile = File(...)):
    _require_key(_PLANTNET_KEY, "PLANTNET_API_KEY")

    img_bytes = await image.read()
    async with httpx.AsyncClient(timeout=_HTTP_TIMEOUT) as client:
        try:
            resp = await client.post(
                "https://my-api.plantnet.org/v2/identify/all",
                params={"api-key": _PLANTNET_KEY},
                files={"images": (image.filename or "img.jpg", img_bytes)},
                data={"organs": "auto"},
            )
        except httpx.HTTPError as e:
            raise HTTPException(status_code=502, detail=f"PlantNet erişilemedi: {e}")

    if resp.status_code == 429:
        raise HTTPException(status_code=429, detail="PlantNet günlük kota dolu")
    if resp.status_code in (401, 403):
        raise HTTPException(status_code=502, detail="PlantNet anahtarı reddedildi")
    if resp.status_code != 200:
        raise HTTPException(status_code=502, detail=f"PlantNet HTTP {resp.status_code}")

    return {"success": True, "data": resp.json()}


# ═════════════════════════════════════════════════════════════════════════════
# GEMINI — görüntüden hastalık tanısı
# ═════════════════════════════════════════════════════════════════════════════


_GEMINI_MODELS = ["gemini-2.0-flash", "gemini-2.0-flash-001"]


class GeminiDiagnoseRequest(BaseModel):
    image_b64: str = Field(..., description="JPEG bayt → base64")
    common_name: str = ""
    scientific_name: str = ""


@router.post("/proxy/vision/diagnose", summary="Gemini — Hastalık Tanısı (proxy)")
async def gemini_diagnose(req: GeminiDiagnoseRequest):
    _require_key(_GEMINI_KEY, "GEMINI_API_KEY")
    if not req.image_b64:
        raise HTTPException(status_code=400, detail="image_b64 gerekli.")

    species_ctx = (
        f"Tür: {req.common_name or req.scientific_name}"
        + (f" ({req.scientific_name})" if req.scientific_name and req.common_name else "")
        + "."
        if (req.common_name or req.scientific_name)
        else "Tür henüz tespit edilmedi — görsel belirtilere göre değerlendir."
    )
    prompt = f"""
Sen uzman bir bitki hastalıkları ve zararlıları tanı uzmanısın. {species_ctx}

Bu fotoğrafı incele ve tek bir JSON nesnesi döndür (markdown veya başka metin EKLEME).
Şema:
{{
  "present": bool,            // hastalık/zararlı var mı
  "name": "...",              // hastalık veya zararlı adı (Türkçe)
  "confidence": 0-100,        // güven yüzdesi
  "severity": "mild|moderate|severe|none",
  "symptoms": "...",          // gözlenen belirtiler (Türkçe)
  "treatment": "..."          // önerilen tedavi adımları (Türkçe)
}}
""".strip()

    payload = {
        "contents": [
            {
                "role": "user",
                "parts": [
                    {"text": prompt},
                    {"inline_data": {"mime_type": "image/jpeg", "data": req.image_b64}},
                ],
            }
        ],
        "generationConfig": {
            "temperature": 0.2,
            "responseMimeType": "application/json",
        },
    }

    async with httpx.AsyncClient(timeout=_HTTP_TIMEOUT) as client:
        last_err = "bilinmeyen hata"
        for model in _GEMINI_MODELS:
            url = f"https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent"
            try:
                resp = await client.post(
                    url,
                    params={"key": _GEMINI_KEY},
                    json=payload,
                )
            except httpx.HTTPError as e:
                last_err = str(e)
                continue
            if resp.status_code == 200:
                return {"success": True, "data": resp.json(), "model": model}
            last_err = f"HTTP {resp.status_code}"

    raise HTTPException(status_code=502, detail=f"Gemini erişilemedi: {last_err}")


# ═════════════════════════════════════════════════════════════════════════════
# AGROMONITORING — polygon + toprak verisi
# ═════════════════════════════════════════════════════════════════════════════


@router.get("/proxy/satellite/soil", summary="Agromonitoring — Toprak (proxy)")
async def agro_soil(lat: float, lng: float, offset_deg: float = 0.001):
    """Geçici polygon yaratır, soil cevabını çeker, polygon'u temizler.
    Sıkı timeout — istemci dashboard'unu bekletmesin. Cleanup async."""
    _require_key(_AGRO_KEY, "AGROMONITORING_API_KEY")

    import asyncio

    polygon = {
        "name": f"tarlam_temp_{int(datetime.utcnow().timestamp())}",
        "geo_json": {
            "type": "Feature",
            "properties": {},
            "geometry": {
                "type": "Polygon",
                "coordinates": [
                    [
                        [lng - offset_deg, lat - offset_deg],
                        [lng + offset_deg, lat - offset_deg],
                        [lng + offset_deg, lat + offset_deg],
                        [lng - offset_deg, lat + offset_deg],
                        [lng - offset_deg, lat - offset_deg],
                    ]
                ],
            },
        },
    }

    fast_timeout = httpx.Timeout(5.0, connect=3.0)
    client = httpx.AsyncClient(timeout=fast_timeout)
    try:
        try:
            create = await client.post(
                "https://api.agromonitoring.com/agro/1.0/polygons",
                params={"appid": _AGRO_KEY},
                json=polygon,
            )
        except httpx.HTTPError as e:
            await client.aclose()
            raise HTTPException(status_code=502, detail=f"Agromonitoring erişilemedi: {e}")

        if create.status_code not in (200, 201):
            await client.aclose()
            raise HTTPException(
                status_code=502,
                detail=f"Agromonitoring polygon HTTP {create.status_code}",
            )
        poly_id = (create.json() or {}).get("id")
        if not poly_id:
            await client.aclose()
            raise HTTPException(status_code=502, detail="Agromonitoring polygon ID dönmedi")

        try:
            soil = await client.get(
                "https://api.agromonitoring.com/agro/1.0/soil",
                params={"polyid": poly_id, "appid": _AGRO_KEY},
            )
        except httpx.HTTPError as e:
            # Async cleanup; istemciyi bekletme
            asyncio.create_task(_async_delete_polygon(poly_id))
            raise HTTPException(status_code=502, detail=f"Agromonitoring soil erişilemedi: {e}")

        # Cleanup'ı arka plana at — istemci anında soil cevabını alsın.
        asyncio.create_task(_async_delete_polygon(poly_id))

        if soil.status_code != 200:
            raise HTTPException(status_code=502, detail=f"Agromonitoring soil HTTP {soil.status_code}")
        sd = soil.json() or {}
        t10_k = float(sd.get("t10") or 288.15)
        moisture = float(sd.get("moisture") or 0.0)
        return {
            "success": True,
            "soil_temp_c": round(t10_k - 273.15, 2),
            "moisture": moisture,
        }
    finally:
        await client.aclose()


async def _async_delete_polygon(poly_id: str) -> None:
    """Polygon temizliğini istemci response'undan bağımsız arka planda yapar."""
    try:
        async with httpx.AsyncClient(timeout=httpx.Timeout(8.0, connect=3.0)) as client:
            await client.delete(
                f"https://api.agromonitoring.com/agro/1.0/polygons/{poly_id}",
                params={"appid": _AGRO_KEY},
            )
    except Exception:
        pass


# ═════════════════════════════════════════════════════════════════════════════
# NASA POWER — tarihi iklim verisi (key gerekmez ama harici)
# ═════════════════════════════════════════════════════════════════════════════


@router.get("/proxy/climate/historical", summary="NASA POWER — Tarihi İklim (proxy)")
async def nasa_power(
    lat: float,
    lng: float,
    start: str,
    end: str,
    parameters: str = "T2M,PRECTOTCORR,RH2M,WS2M",
):
    """NASA POWER günlük noktasal verisi. start/end YYYYMMDD."""
    async with httpx.AsyncClient(timeout=_HTTP_TIMEOUT) as client:
        try:
            resp = await client.get(
                "https://power.larc.nasa.gov/api/temporal/daily/point",
                params={
                    "parameters": parameters,
                    "community": "AG",
                    "longitude": lng,
                    "latitude": lat,
                    "start": start,
                    "end": end,
                    "format": "JSON",
                },
            )
        except httpx.HTTPError as e:
            raise HTTPException(status_code=502, detail=f"NASA POWER erişilemedi: {e}")

    if resp.status_code != 200:
        raise HTTPException(status_code=502, detail=f"NASA POWER HTTP {resp.status_code}")
    return {"success": True, "data": resp.json()}


def _wmo_code_to_tr(code: int) -> str:
    if code == 0:
        return "açık"
    if code == 1:
        return "az bulutlu"
    if code == 2:
        return "parçalı bulutlu"
    if code == 3:
        return "kapalı"
    if code in (45, 48):
        return "sisli"
    if 51 <= code <= 57:
        return "çisenti"
    if 61 <= code <= 67:
        return "yağmurlu"
    if 71 <= code <= 77:
        return "karlı"
    if 80 <= code <= 82:
        return "sağanak"
    if 85 <= code <= 86:
        return "kar sağanağı"
    if code >= 95:
        return "gök gürültülü fırtına"
    return ""


async def _fetch_soil_profile(client: httpx.AsyncClient, lat: float, lng: float) -> dict[str, Any]:
    params: list[tuple[str, Any]] = [("lon", lng), ("lat", lat)]
    params += [("property", p) for p in ["phh2o", "ocd", "clay", "sand", "silt", "bdod", "cec", "nitrogen"]]
    params += [("depth", "0-5cm"), ("depth", "5-15cm"), ("value", "mean")]
    resp = await client.get(
        "https://rest.isric.org/soilgrids/v2.0/properties/query",
        params=params,
    )
    if resp.status_code != 200:
        raise HTTPException(status_code=502, detail=f"SoilGrids HTTP {resp.status_code}")
    layers = (((resp.json() or {}).get("properties") or {}).get("layers") or [])

    def mean(name: str) -> float:
        layer = next((l for l in layers if l.get("name") == name), None)
        if not layer:
            return 0.0
        vals = [((d.get("values") or {}).get("mean") or 0) for d in (layer.get("depths") or [])]
        vals = [float(v) for v in vals if v is not None]
        return sum(vals) / len(vals) if vals else 0.0

    ph_h2o = mean("phh2o")
    return {
        "ph_h2o": ph_h2o,
        "ph_real": ph_h2o / 10.0,
        "organic_carbon_gkg": mean("ocd"),
        "clay_gkg": mean("clay"),
        "sand_gkg": mean("sand"),
        "silt_gkg": mean("silt"),
        "bulk_density_kgm3": mean("bdod"),
        "cec_mmolkg": mean("cec"),
        "nitrogen_gkg": mean("nitrogen"),
    }


@router.get("/proxy/soil/profile", summary="SoilGrids — Toprak Profili (proxy)")
async def soil_profile(lat: float, lng: float):
    async with httpx.AsyncClient(timeout=_HTTP_TIMEOUT) as client:
        return {"success": True, "data": await _fetch_soil_profile(client, lat, lng)}


@router.get("/proxy/environment/field", summary="Tarla Çevre Verisi (proxy)")
async def field_environment(lat: float, lng: float):
    # Daha kısa istemci timeout — dashboard'ı tutmasın.
    fast_timeout = httpx.Timeout(7.0, connect=4.0)
    async with httpx.AsyncClient(timeout=fast_timeout) as client:
        # Open-Meteo + SoilGrids'i PARALEL çek; SoilGrids genelde yavaş ama
        # ph yoksa varsayılana düşeriz, hava verisini bekletmesin.
        import asyncio

        weather_task = client.get(
            "https://api.open-meteo.com/v1/forecast",
            params={
                "latitude": lat,
                "longitude": lng,
                "current": "temperature_2m,relative_humidity_2m,precipitation,wind_speed_10m,cloud_cover,surface_pressure,weather_code",
                "hourly": "temperature_2m,precipitation,precipitation_probability,weather_code,wind_speed_10m,wind_direction_10m,relative_humidity_2m",
                "daily": "temperature_2m_max,temperature_2m_min,precipitation_sum,uv_index_max,wind_speed_10m_max",
                "wind_speed_unit": "ms",
                "forecast_days": 7,
                "timezone": "auto",
            },
        )
        soil_task = _fetch_soil_profile(client, lat, lng)

        try:
            weather, soil = await asyncio.gather(
                weather_task, soil_task, return_exceptions=True,
            )
        except httpx.HTTPError as e:
            raise HTTPException(status_code=502, detail=f"Open-Meteo erişilemedi: {e}")

        if isinstance(weather, BaseException):
            raise HTTPException(
                status_code=502, detail=f"Open-Meteo erişilemedi: {weather}",
            )
        if weather.status_code != 200:
            raise HTTPException(status_code=502, detail=f"Open-Meteo HTTP {weather.status_code}")

        if isinstance(soil, BaseException) or not isinstance(soil, dict):
            soil = {"ph_real": 6.8}

        body = weather.json() or {}
        cur = body.get("current") or {}
        daily = body.get("daily") or {}
        hourly = body.get("hourly") or {}

        daily_forecast: list[dict[str, Any]] = []
        temp_sum = 0.0
        rain_sum = 0.0
        for i, date in enumerate((daily.get("time") or [])[:7]):
            day_max = float((daily.get("temperature_2m_max") or [0])[i] or 0)
            day_min = float((daily.get("temperature_2m_min") or [0])[i] or 0)
            day_rain = float((daily.get("precipitation_sum") or [0])[i] or 0)
            temp_sum += (day_max + day_min) / 2.0
            rain_sum += day_rain
            daily_forecast.append({
                "date": date,
                "max": day_max,
                "min": day_min,
                "rain": day_rain,
                "uv": float((daily.get("uv_index_max") or [0])[i] or 0),
                "wind_max": float((daily.get("wind_speed_10m_max") or [0])[i] or 0),
            })

        hourly_forecast: list[dict[str, Any]] = []
        for i, t in enumerate((hourly.get("time") or [])[:24]):
            hourly_forecast.append({
                "time": t,
                "temp": float((hourly.get("temperature_2m") or [0])[i] or 0),
                "precip_mm": float((hourly.get("precipitation") or [0])[i] or 0),
                "precip_prob": int((hourly.get("precipitation_probability") or [0])[i] or 0),
                "code": int((hourly.get("weather_code") or [0])[i] or 0),
                "wind": float((hourly.get("wind_speed_10m") or [0])[i] or 0),
                "wind_dir": float((hourly.get("wind_direction_10m") or [0])[i] or 0),
                "humidity": int((hourly.get("relative_humidity_2m") or [0])[i] or 0),
            })

    # `soil` zaten yukarıda Open-Meteo ile paralel alındı.
    weather_code = int(cur.get("weather_code") or 0)
    return {
        "success": True,
        "temp": float(cur.get("temperature_2m") or 0),
        "humidity": float(cur.get("relative_humidity_2m") or 0),
        "wind": float(cur.get("wind_speed_10m") or 0),
        "current_precip": float(cur.get("precipitation") or 0),
        "current_cloud_cover": float(cur.get("cloud_cover") or 0),
        "current_pressure": float(cur.get("surface_pressure") or 0),
        "weather_code": weather_code,
        "weather_desc": _wmo_code_to_tr(weather_code),
        "ph": float(soil.get("ph_real") or 6.8),
        "avg_weekly_temp": round(temp_sum / max(1, len(daily_forecast)), 1),
        "total_weekly_rain": round(rain_sum, 1),
        "daily_forecast": daily_forecast,
        "hourly_forecast": hourly_forecast,
        "soil_profile": soil,
    }


@router.get("/proxy/weather/hourly", summary="Saatlik Hava Tahmini (proxy)")
async def hourly_weather(lat: float, lng: float):
    env = await field_environment(lat, lng)
    return {"success": True, "hourly_forecast": env.get("hourly_forecast", [])}


@router.get("/proxy/fuel/prices", summary="Akaryakıt Fiyatı (proxy)")
async def fuel_prices(city: str = "ISTANBUL"):
    async with httpx.AsyncClient(timeout=_HTTP_TIMEOUT) as client:
        try:
            resp = await client.get(f"https://hasanadiguzel.com.tr/api/akaryakit/sehir={city}")
        except httpx.HTTPError as e:
            raise HTTPException(status_code=502, detail=f"Akaryakıt verisi erişilemedi: {e}")
    if resp.status_code != 200:
        raise HTTPException(status_code=502, detail=f"Akaryakıt HTTP {resp.status_code}")
    return {"success": True, "data": resp.json(), "city": city}


class CropRecommendationRequest(BaseModel):
    temp: float
    ph: float
    avg_weekly_temp: float
    total_weekly_rain: float
    soil_moisture: float = 0.0
    soil_temp_c: float = 0.0


@router.post("/analyze/crop_recommendations", summary="Ürün Önerisi (deterministik)")
async def crop_recommendations(req: CropRecommendationRequest):
    candidates = [
        ("Domates", 15, 32, 5.5, 7.0, 10, 50, "İlkbahar-Yaz"),
        ("Biber", 18, 32, 5.5, 7.0, 10, 45, "İlkbahar-Yaz"),
        ("Patlıcan", 18, 35, 5.5, 7.0, 10, 45, "İlkbahar-Yaz"),
        ("Salatalık", 18, 30, 6.0, 7.0, 15, 50, "İlkbahar-Yaz"),
        ("Mısır", 18, 35, 5.8, 7.0, 15, 60, "Yaz"),
        ("Patates", 10, 22, 5.0, 6.5, 20, 60, "İlkbahar-Sonbahar"),
        ("Soğan", 10, 28, 6.0, 7.5, 10, 40, "İlkbahar-Sonbahar"),
        ("Buğday", 5, 22, 6.0, 7.5, 10, 40, "Sonbahar-İlkbahar"),
        ("Fasulye", 16, 30, 6.0, 7.0, 15, 50, "Yaz"),
        ("Ayçiçeği", 18, 35, 6.0, 7.5, 10, 40, "Yaz"),
    ]
    out: list[dict[str, Any]] = []
    for name, min_t, max_t, min_ph, max_ph, min_rain, max_rain, season in candidates:
        score = 100.0
        if req.avg_weekly_temp < min_t:
            score -= (min_t - req.avg_weekly_temp) * 4
        if req.avg_weekly_temp > max_t:
            score -= (req.avg_weekly_temp - max_t) * 4
        if req.ph < min_ph:
            score -= (min_ph - req.ph) * 12
        if req.ph > max_ph:
            score -= (req.ph - max_ph) * 12
        if req.total_weekly_rain < min_rain:
            score -= (min_rain - req.total_weekly_rain) * 1.5
        if req.total_weekly_rain > max_rain:
            score -= (req.total_weekly_rain - max_rain) * 1.5
        if req.soil_moisture > 0.45:
            score -= 10
        if req.soil_moisture < 0.10 and req.total_weekly_rain < 10:
            score -= 8
        score = max(0.0, min(100.0, score))
        out.append({
            "name": name,
            "season": season,
            "uygunluk": score,
            "info": f"{req.avg_weekly_temp:.1f}°C + pH {req.ph:.1f} koşullarında uygunluk skoru %{round(score)}.",
            "fertilizer": "Taban gübresi olarak dekara 20 kg 15-15-15 NPK önerilir.",
            "weather_impact": f"Haftalık yağış {round(req.total_weekly_rain)} mm.",
            "care_details": "Sıra arası ve bitki arası mesafeyi yerel ürün rehberine göre ayarlayın.",
        })
    out.sort(key=lambda x: x["uygunluk"], reverse=True)
    return {"success": True, "crops": out[:5]}


# ═════════════════════════════════════════════════════════════════════════════
# DETERMİNİSTİK METİN ÜRETİCİLER (rule_engine.dart paritesinde)
# ═════════════════════════════════════════════════════════════════════════════


_MONTHS_TR = [
    "", "Ocak", "Şubat", "Mart", "Nisan", "Mayıs", "Haziran",
    "Temmuz", "Ağustos", "Eylül", "Ekim", "Kasım", "Aralık",
]


def _season(month: int) -> str:
    if 3 <= month <= 5:
        return "İlkbahar"
    if 6 <= month <= 8:
        return "Yaz"
    if 9 <= month <= 11:
        return "Sonbahar"
    return "Kış"


class FieldPlanRequest(BaseModel):
    plant_name: str
    field_name: str
    ph: float
    avg_temp: float
    total_rain: float
    area_dekar: float
    month: int
    plant_details: dict = Field(default_factory=dict)


@router.post("/analyze/field_plan", summary="Tarla Ekim Planı (deterministik)")
async def analyze_field_plan(req: FieldPlanRequest):
    pd = req.plant_details or {}
    row_sp = int((pd.get("row_spacing_cm") or 60))
    plant_sp = int((pd.get("plant_spacing_cm") or 40))
    depth = int((pd.get("depth_cm") or 3))
    seeds = int((pd.get("seeds_per_dekar") or 500))
    harvest = int((pd.get("harvest_days") or 90))
    watering = str(pd.get("watering") or "Average")
    care = str(pd.get("care_description") or "")
    pests = str(pd.get("pest_susceptibility") or "Genel zararlı takibi")

    now = datetime.utcnow()
    harvest_date = now.fromtimestamp(now.timestamp() + harvest * 86400)
    season = _season(req.month)

    lines: list[str] = []
    lines.append(f"📋 {req.plant_name} — {req.field_name} Ekim Planı")
    lines.append(f"Tarih: {now.day} {_MONTHS_TR[req.month]} {now.year} | Mevsim: {season}")
    lines.append(f"Alan: {req.area_dekar:.1f} dekar\n")

    lines.append("🌱 1. TOPRAK HAZIRLIĞI")
    if req.ph < 5.5:
        lines.append(f"• pH {req.ph:.1f} — ZORUNLU: Ekimden 1 ay önce dekara 200 kg tarım kireci uygulayın.")
    elif req.ph > 7.5:
        lines.append(f"• pH {req.ph:.1f} — Dekara 20 kg elementel kükürt uygulayın.")
    else:
        lines.append(f"• pH {req.ph:.1f} ✅ toprak ideal aralıkta, kireçleme gerekmez.")
    lines.append("• Taban gübresi: Ekimden 5-7 gün önce dekara 20 kg 15-15-15 NPK uygulayın.")
    lines.append("• Derin sürüm (25-30 cm) ve diskaro ile toprak hazırlığı yapın.\n")

    lines.append("🌾 2. EKİM / DİKİM SÜRECİ")
    lines.append(f"• Ekim derinliği: {depth} cm")
    lines.append(f"• Sıra arası: {row_sp} cm | Bitki arası: {plant_sp} cm")
    lines.append(f"• Tohumluk/Fide: Dekara {seeds} adet")
    lines.append(f"• {req.area_dekar:.1f} dekar için toplam: {round(seeds * req.area_dekar)} adet fide/tohum")
    lines.append(
        f"• Tahmini hasat: {harvest_date.day} {_MONTHS_TR[harvest_date.month]} {harvest_date.year}\n"
    )

    lines.append("💧 3. SULAMA VE GÜBRELEME TAKVİMİ")
    lines.append(f"• Mevcut haftalık yağış: {round(req.total_rain)} mm")
    if watering.lower() == "frequent" and req.total_rain < 15:
        lines.append("• ⚠️ Bu bitki sık sulama ister — haftada 3 kez sabah erken sulama yapın.")
    elif watering.lower() == "minimum":
        lines.append("• Bu bitki az su ister — haftada 1 kez derin sulama yeterli.")
    else:
        lines.append("• Haftada 2 kez, sabah 06:00-08:00 arası sulama önerilir.")
    lines.append("• Gübre takvimi: Fide dönemi azot → çiçek dönemi fosfor → meyve dönemi potasyum.\n")

    lines.append("🌡️ 4. BAKIM VE HASTALIK TAKİBİ")
    if care and len(care) > 20:
        lines.append("\n".join(care.splitlines()[:6]))
    else:
        lines.append("• Düzenli gözlem: haftada 2 kez yaprak ve kök kontrolü.")
        lines.append(f"• Hassas olduğu zararlılar: {pests}")
    lines.append("")

    lines.append("🎯 5. HASAT BEKLENTİSİ")
    lines.append(f"• Ekim tarihinden ~{harvest} gün sonra hasat.")
    lines.append(f"• {req.area_dekar:.1f} dekar alandan beklenen verim:")
    plant_count = round((10000 * req.area_dekar) / max(1, row_sp * plant_sp))
    lines.append(f"  Toplam {plant_count} bitki × ortalama verim = tür bazlı hesap yapın.")
    lines.append("• Hasat sabah erken saatlerde, serin havada yapılmalıdır.")

    return {"success": True, "text": "\n".join(lines)}


class WeeklyCommentRequest(BaseModel):
    field_name: str
    temp: float
    avg_temp: float
    humidity: float
    wind: float
    ph: float
    soil_moisture: float
    soil_temp_c: float
    total_weekly_rain: float
    crops: list[dict] = Field(default_factory=list)
    month: int


@router.post("/analyze/weekly_comment", summary="Haftalık Tarla Yorumu")
async def analyze_weekly_comment(req: WeeklyCommentRequest):
    season = _season(req.month)
    suggested = ", ".join([str(c.get("name", "")) for c in req.crops[:5]])

    lines: list[str] = []
    lines.append("🌤️ HAFTALIK HAVA DEĞERLENDİRMESİ")
    lines.append(f"Tarla: {req.field_name} | {_MONTHS_TR[req.month]} — {season}")
    lines.append(
        f"Anlık: {req.temp:.1f}°C, Nem %{round(req.humidity)}, Rüzgar {req.wind:.1f} m/s"
    )
    lines.append(
        f"Haftalık ort: {req.avg_temp:.1f}°C | Yağış: {round(req.total_weekly_rain)} mm\n"
    )

    lines.append("🌱 BU HAFTA YAPILMASI GEREKENLER")
    if req.total_weekly_rain < 10:
        lines.append("• Sulama: Haftada 2-3 kez, sabah erken saatleri tercih edin.")
    elif req.total_weekly_rain > 40:
        lines.append("• Sulama: Bu hafta yağış yeterli — sulama yapmayın.")
        lines.append("• Drenaj kanallarını kontrol edin.")
    else:
        lines.append("• Sulama: Haftada 1-2 kez yeterli olacaktır.")
    if 18 <= req.avg_temp <= 30:
        lines.append("• Gübreleme: Bu hafta gübre uygulaması için uygun koşullar.")
    if 3 <= req.month <= 5:
        lines.append("• İlkbahar bakım: Yabancı ot kontrolü ve çapalama önerilir.")
    lines.append("")

    lines.append("🧪 TOPRAK VE GÜBRE DURUMU")
    if req.ph < 5.5:
        lines.append(f"⚠️ Toprak asidik (pH {req.ph:.1f}) — kireçleme gerekli.")
    elif req.ph > 7.5:
        lines.append(f"⚠️ Toprak bazik (pH {req.ph:.1f}) — kükürt uygulaması önerilir.")
    else:
        lines.append(f"✅ Toprak pH'ı ({req.ph:.1f}) ideal aralıkta.")
    lines.append(
        f"Toprak nemi: %{round(req.soil_moisture * 100)} | Toprak sıcaklığı: {req.soil_temp_c:.1f}°C\n"
    )

    lines.append("⚠️ RİSKLER")
    if req.humidity > 80 and 18 <= req.temp <= 28:
        lines.append("• Mantar hastalık riski yüksek — fungisit takibi yapın.")
    if req.temp > 35:
        lines.append("• Isı stresi — sulama sıklığını artırın, mulçlama yapın.")
    if req.temp < 5:
        lines.append("• Don riski — hassas bitkilerinizi koruyun.")
    if req.total_weekly_rain < 5 and req.humidity < 35:
        lines.append("• Kuraklık stresi — damla sulama sisteminizi kontrol edin.")
    lines.append("")

    lines.append("💡 ÖNERİLEN ÜRÜNLER")
    lines.append(f"Mevcut koşullara göre önerilen ürünler: {suggested}")

    return {"success": True, "text": "\n".join(lines)}


class EnvReportRequest(BaseModel):
    temp: float
    humidity: float
    weekly_rain: float
    ph: float
    soil_moisture: float = 0.0
    soil_temp_c: float = 0.0
    month: int


@router.post("/analyze/environmental_report", summary="Çevresel Rapor")
async def analyze_environmental_report(req: EnvReportRequest):
    season = _season(req.month)
    lines: list[str] = []
    lines.append(
        "Fotoğraf tarımsal bir içerik olarak tanımlanamadı. Ancak bulunduğunuz "
        "bölgedeki güncel tarımsal çevre şartları şu şekildedir:"
    )
    lines.append("")
    lines.append(f"📍 BÖLGE ÇEVRESİ — {_MONTHS_TR[req.month]} {season}")
    lines.append(f"🌡️ Anlık Sıcaklık: {req.temp:.1f}°C")
    lines.append(f"💧 Nem Oranı: %{round(req.humidity)}")
    lines.append(f"🌧️ Haftalık Yağış Beklentisi: {round(req.weekly_rain)} mm")
    lines.append(f"🌿 Toprak pH: {req.ph:.1f}")
    if req.soil_moisture > 0:
        lines.append(f"💦 Toprak Nem: %{round(req.soil_moisture * 100)}")
    if req.soil_temp_c > 0:
        lines.append(f"🌡️ Toprak Sıcaklığı: {req.soil_temp_c:.1f}°C")
    lines.append("")

    if 15 <= req.temp <= 28 and 40 <= req.humidity <= 70:
        lines.append("✅ Bölgeniz şu an tarımsal faaliyet için uygun koşullara sahip.")
    elif req.temp < 5:
        lines.append("⚠️ Soğuk koşullar — açık alanda hassas bitki yetiştiriciliği önerilmez.")
    elif req.temp > 36:
        lines.append("⚠️ Aşırı sıcak — sulama ve gölgeleme önlemleri alın.")

    if 6.0 <= req.ph <= 7.0:
        lines.append("✅ Toprak pH'ı çoğu sebze ve meyve için mükemmel aralıkta.")

    return {"success": True, "text": "\n".join(lines)}
