"""seed_plants.json -> assets/data/turkish_crops.sqlite

Elle küratörlü bitki bilgi tabanını SQLite'a dönüştürür, Flutter asset
klasörüne kopyalar. Yetiştirme verisi (ekim/hasat ayı, su, güneş, pH,
bölge uyumu, hastalık, zararlı) tek dosyada.

Kullanım:
    cd backend
    python data_pipeline/build_turkish_crops_db.py
"""
from __future__ import annotations

import json
import shutil
import sqlite3
import unicodedata
from pathlib import Path


BASE = Path(__file__).parent
SEED = BASE / "seed_plants.json"
OUTPUT = BASE / "output" / "turkish_crops.sqlite"
ASSET_TARGET = BASE.parent.parent / "assets" / "data" / "turkish_crops.sqlite"


def normalize(text: str) -> str:
    if not text:
        return ""
    text = text.lower()
    for tr, en in (("ı", "i"), ("ğ", "g"), ("ü", "u"),
                   ("ş", "s"), ("ö", "o"), ("ç", "c")):
        text = text.replace(tr, en)
    text = unicodedata.normalize("NFD", text)
    text = "".join(c for c in text if unicodedata.category(c) != "Mn")
    return text.strip()


SCHEMA = """
CREATE TABLE IF NOT EXISTS crops (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name_tr TEXT NOT NULL,
  aliases TEXT,
  scientific_name TEXT,
  category TEXT NOT NULL,
  sowing_months TEXT,
  harvest_months TEXT,
  temp_min_c REAL,
  temp_max_c REAL,
  optimal_temp_c REAL,
  water_need TEXT,
  sun_need TEXT,
  soil_ph_min REAL,
  soil_ph_max REAL,
  soil_type TEXT,
  region_suitability TEXT,
  fertilizer_notes TEXT,
  common_pests TEXT,
  common_diseases TEXT,
  growing_tips TEXT,
  days_to_harvest INTEGER,
  search_key TEXT NOT NULL
);
CREATE INDEX IF NOT EXISTS idx_crops_search ON crops(search_key);
CREATE INDEX IF NOT EXISTS idx_crops_category ON crops(category);
CREATE INDEX IF NOT EXISTS idx_crops_name ON crops(name_tr);
"""


def _js(v) -> str | None:
    if v is None:
        return None
    return json.dumps(v, ensure_ascii=False)


def main() -> int:
    if not SEED.exists():
        print(f"[HATA] Seed dosyası yok: {SEED}")
        return 1

    data = json.loads(SEED.read_text(encoding="utf-8"))
    plants = data.get("plants", [])
    print(f"Seed bitki sayısı: {len(plants)}")

    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    if OUTPUT.exists():
        OUTPUT.unlink()

    conn = sqlite3.connect(OUTPUT)
    conn.executescript(SCHEMA)

    rows = []
    for p in plants:
        name = p["name_tr"]
        aliases = p.get("aliases", []) or []
        search_parts = [name] + list(aliases)
        search_key = " ".join(normalize(s) for s in search_parts if s)
        rows.append((
            name,
            _js(aliases) if aliases else None,
            p.get("scientific_name"),
            p["category"],
            _js(p.get("sowing_months")),
            _js(p.get("harvest_months")),
            p.get("temp_min_c"),
            p.get("temp_max_c"),
            p.get("optimal_temp_c"),
            p.get("water_need"),
            p.get("sun_need"),
            p.get("soil_ph_min"),
            p.get("soil_ph_max"),
            _js(p.get("soil_type")),
            _js(p.get("region_suitability")),
            p.get("fertilizer_notes"),
            _js(p.get("common_pests")),
            _js(p.get("common_diseases")),
            p.get("growing_tips"),
            p.get("days_to_harvest"),
            search_key,
        ))

    conn.executemany(
        """INSERT INTO crops
           (name_tr, aliases, scientific_name, category,
            sowing_months, harvest_months,
            temp_min_c, temp_max_c, optimal_temp_c,
            water_need, sun_need,
            soil_ph_min, soil_ph_max, soil_type,
            region_suitability, fertilizer_notes,
            common_pests, common_diseases, growing_tips,
            days_to_harvest, search_key)
           VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)""",
        rows,
    )
    conn.commit()
    conn.close()

    ASSET_TARGET.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(OUTPUT, ASSET_TARGET)

    print(f"\n[OK] SQLite uretildi  : {OUTPUT}")
    print(f"[OK] Asset kopyalandi : {ASSET_TARGET}")
    print(f"\nSonraki adım: flutter pub get && flutter run")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
