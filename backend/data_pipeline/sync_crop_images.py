"""assets/crops/ klasöründeki PNG/JPG dosyalarını otomatik olarak
crop_images.json ile eşleştirir.

Nasıl çalışır:
  1. assets/crops/ içindeki tüm .png ve .jpg dosyalarını tarar.
  2. Her dosya adını normalize edip turkish_crops.sqlite'taki search_key
     sütunuyla karşılaştırır.
  3. Eşleşen kayıtlar için crop_images.json'a (Türkçe isim → dosya adı)
     girdi ekler veya günceller.
  4. .png dosyası varsa .jpg'ye tercih eder.

Kullanım:
    cd backend
    python data_pipeline/sync_crop_images.py

    # Sadece önizleme (yazma yok):
    python data_pipeline/sync_crop_images.py --dry-run
"""
from __future__ import annotations

import argparse
import json
import re
import sqlite3
import unicodedata
from pathlib import Path


BASE = Path(__file__).parent.parent.parent  # repo kökü
CROPS_DIR = BASE / "assets" / "crops"
IMAGES_JSON = BASE / "assets" / "data" / "crop_images.json"
SQLITE_PATH = BASE / "assets" / "data" / "turkish_crops.sqlite"


def normalize(text: str) -> str:
    text = text.lower()
    for tr, en in (
        ("ı", "i"), ("ğ", "g"), ("ü", "u"),
        ("ş", "s"), ("ö", "o"), ("ç", "c"),
    ):
        text = text.replace(tr, en)
    text = unicodedata.normalize("NFD", text)
    text = "".join(c for c in text if unicodedata.category(c) != "Mn")
    return re.sub(r"[^a-z0-9 ]", "", text).strip()


def filename_to_key(filename: str) -> str:
    stem = Path(filename).stem
    return normalize(stem.replace("-", " ").replace("_", " "))


def load_db_map() -> dict[str, str]:
    """search_key → name_tr haritası döndürür."""
    if not SQLITE_PATH.exists():
        print(f"[UYARI] SQLite bulunamadı: {SQLITE_PATH}")
        return {}
    conn = sqlite3.connect(SQLITE_PATH)
    cur = conn.cursor()
    cur.execute("SELECT name_tr, search_key FROM crops")
    rows = cur.fetchall()
    conn.close()
    result: dict[str, str] = {}
    for name_tr, search_key in rows:
        for part in (search_key or "").split():
            result.setdefault(part.strip(), name_tr)
    return result


def scan_crop_images() -> dict[str, str]:
    """Dosya adı → dosya adı (png öncelikli). Örn: 'portakal' → 'portakal.png'"""
    if not CROPS_DIR.exists():
        print(f"[HATA] Klasör bulunamadı: {CROPS_DIR}")
        return {}
    files: dict[str, str] = {}
    for f in CROPS_DIR.iterdir():
        if f.suffix.lower() not in (".png", ".jpg", ".jpeg"):
            continue
        key = filename_to_key(f.name)
        existing = files.get(key)
        # PNG dosyası varsa JPG'ye tercih et
        if existing is None or f.suffix.lower() == ".png":
            files[key] = f.name
    return files


def load_json() -> dict[str, str]:
    if not IMAGES_JSON.exists():
        return {}
    with open(IMAGES_JSON, encoding="utf-8") as fh:
        return json.load(fh)


def save_json(data: dict[str, str]) -> None:
    with open(IMAGES_JSON, "w", encoding="utf-8") as fh:
        json.dump(data, fh, ensure_ascii=False, indent=2)


def main(dry_run: bool = False) -> int:
    db_map = load_db_map()
    if not db_map:
        print("[HATA] Veritabanı boş veya bulunamadı.")
        return 1

    scan = scan_crop_images()
    current = load_json()

    added, updated = 0, 0

    for file_key, filename in scan.items():
        name_tr = db_map.get(file_key)
        if not name_tr:
            print(f"  [?] Eşleşme yok: {filename!r} (anahtar: {file_key!r})")
            continue

        existing_val = current.get(name_tr)
        if existing_val == filename:
            continue  # zaten güncel

        action = "GÜNCELLE" if existing_val else "EKLE"
        info = f" (onceki: {existing_val!r})" if existing_val else ""
        print(f"  [{action}] {name_tr!r} -> {filename!r}{info}")

        if not dry_run:
            current[name_tr] = filename
            if action == "EKLE":
                added += 1
            else:
                updated += 1

    if dry_run:
        print("\n[DRY-RUN] Hiçbir değişiklik yazılmadı.")
    else:
        save_json(current)
        print(f"\n[OK] crop_images.json güncellendi: +{added} yeni, ~{updated} güncellendi.")

    return 0


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--dry-run", action="store_true",
                        help="Değişiklikleri yaz, sadece göster.")
    args = parser.parse_args()
    raise SystemExit(main(dry_run=args.dry_run))
