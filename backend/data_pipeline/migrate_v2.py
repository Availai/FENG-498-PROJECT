"""seed_plants.json'a v2 yapısal alanlarını ekler — idempotent.

CLAUDE.md sec 11-14'e uygun olarak 5 öncelikli bitkiye stable_id ve boş
yapısal iskelet ekler. ASLA içerik UYDURMAZ — evidence/source_ids alanları
boş kalır, missing_information listesi neyin eksik olduğunu somut yazar.

v1 alanları olduğu gibi korunur — geriye dönük uyumluluk garanti.
Diğer 287 bitki dokunulmaz.

Kullanım:
    cd backend
    python data_pipeline/migrate_v2.py            # uygula
    python data_pipeline/migrate_v2.py --check    # sadece doğrula, yazma
"""
from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

# Windows cp1254 stdout'u Unicode karakterleri (ör. ç, ş) bozar.
try:
    sys.stdout.reconfigure(encoding="utf-8")  # type: ignore[attr-defined]
    sys.stderr.reconfigure(encoding="utf-8")  # type: ignore[attr-defined]
except Exception:
    pass

SEED = Path(__file__).parent / "seed_plants.json"

# CLAUDE.md sec 11 — Ana Ürünler ve Stable ID'ler
PRIORITY_CROPS: dict[str, str] = {
    "Domates": "crop.tomato",
    "Mısır": "crop.corn",
    "Ayçiçeği": "crop.sunflower",
    "Çay": "crop.tea",
    "Portakal": "crop.orange",
}

# v2 alan açıklamaları (_schema bloğuna gömülür, doğrulayıcı buradan okur)
V2_SCHEMA_DESCRIPTION: dict[str, object] = {
    "stable_id": "CLAUDE.md sec 11 — örn. crop.tomato. Küçük harf, _, Türkçe karakter yok.",
    "source_ids": "sources.json içindeki source.* id'lerine referans dizisi.",
    "evidence": "[{source_id, evidence_text, page|null, section|null}] — her v2 fact için zorunlu.",
    "confidence": ["high", "medium", "low"],
    "growth_stages": "[{key, label_tr, day_min, day_max, source_ids[], evidence[]}]",
    "diseases_v2": (
        "[{id: 'disease.{crop}.{name}', name_tr, "
        "evidence[], source_ids[], requires_bku_check: true, "
        "requires_expert_confirmation: true, control_methods[]}]"
    ),
    "pests_v2": (
        "[{id: 'pest.{crop}.{name}', name_tr, "
        "evidence[], source_ids[], control_methods[]}]"
    ),
    "fertilizer_rules": "CLAUDE.md sec 14 + sec 16 guardrail kurallarına uyan koşullu kayıtlar.",
    "irrigation_rules": "Koşullu sulama kayıtları (toprak/iklim/dönem).",
    "rule_engine_rules": "CLAUDE.md sec 14 — id, conditions[], result, evidence[].",
    "missing_information": "Doldurulması beklenen kanıt/alan listesi (somut Türkçe).",
    "v2_status": ["pending_sources", "draft", "review", "approved"],
}

V2_PRIORITY_REGISTRY = sorted(PRIORITY_CROPS.values())


def _missing_info_template(crop_name_tr: str) -> list[str]:
    """Her öncelikli bitki için somut, doldurulması gereken eksik kanıt listesi."""
    return [
        f"{crop_name_tr} için resmî kaynak listesi (sources.json'a TAGEM/Bakanlık/üniversite yayınları eklenmeli).",
        "evidence[] dizisi her v2 fact için kaynak metniyle birlikte doldurulacak.",
        "growth_stages[] — TAGEM fenoloji yayınından evre tabloları çıkarılacak.",
        "diseases_v2[] — common_diseases içindeki her hastalık 'disease.{crop}.{name}' stable id, evidence ve BKÜ flag'leriyle yapılandırılacak.",
        "pests_v2[] — common_pests içindeki her zararlı 'pest.{crop}.{name}' stable id ve evidence ile yapılandırılacak.",
        "fertilizer_rules[] — toprak analizi koşullu kurallar; CLAUDE.md sec 16 guardrail'leriyle.",
        "irrigation_rules[] — bölge + iklim + dönem koşullu sulama kuralları.",
        "rule_engine_rules[] — CLAUDE.md sec 14 formatında, evidence + test_cases ile.",
    ]


def _add_v2_skeleton(plant: dict, stable_id: str) -> bool:
    """Plant kaydına v2 alanlarını ekler. İdempotent — varsa dokunmaz.
    Returns True if changed."""
    if "stable_id" in plant:
        return False

    plant["stable_id"] = stable_id
    plant["source_ids"] = []
    plant["evidence"] = []
    plant["confidence"] = "low"
    plant["growth_stages"] = []
    plant["diseases_v2"] = []
    plant["pests_v2"] = []
    plant["fertilizer_rules"] = []
    plant["irrigation_rules"] = []
    plant["rule_engine_rules"] = []
    plant["missing_information"] = _missing_info_template(plant["name_tr"])
    plant["v2_status"] = "pending_sources"
    return True


def _ensure_schema_v2(schema: dict) -> bool:
    """_schema bloğuna v2 açıklamalarını ekler. İdempotent."""
    if "v2_optional_fields" in schema:
        return False
    schema["v2_optional_fields"] = V2_SCHEMA_DESCRIPTION
    schema["v2_priority_crops"] = V2_PRIORITY_REGISTRY
    return True


def _serialize(data: dict) -> str:
    """Mevcut kompakt formatı korur:
    - top-level pretty (2 boşluk indent)
    - _schema pretty
    - plants[] içindeki her bitki tek satırda."""
    schema_str = json.dumps(data["_schema"], ensure_ascii=False, indent=2)
    schema_str = "\n".join(("  " + line if i > 0 else line)
                           for i, line in enumerate(schema_str.split("\n")))

    # Plant satırları kompakt (boşluksuz separator) — orijinal seed_plants.json
    # formatı tek-satır-per-bitki: {"name_tr":"...","scientific_name":"..."}
    plant_lines = [
        json.dumps(p, ensure_ascii=False, separators=(",", ":"))
        for p in data["plants"]
    ]
    plants_block = ",\n".join("    " + line for line in plant_lines)

    out = "{\n"
    out += f'  "_schema": {schema_str},\n'
    out += '  "plants": [\n'
    out += plants_block
    out += "\n  ]\n"
    out += "}\n"
    return out


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--check", action="store_true",
                        help="Sadece doğrula, yazma yapma.")
    args = parser.parse_args()

    if not SEED.exists():
        print(f"[HATA] Seed dosyası yok: {SEED}", file=sys.stderr)
        return 1

    raw = SEED.read_text(encoding="utf-8")
    data = json.loads(raw)

    schema_changed = _ensure_schema_v2(data["_schema"])

    plants_changed: list[str] = []
    plants_already: list[str] = []
    found_priority: set[str] = set()

    for plant in data["plants"]:
        name = plant.get("name_tr")
        if name in PRIORITY_CROPS:
            found_priority.add(name)
            stable_id = PRIORITY_CROPS[name]
            if _add_v2_skeleton(plant, stable_id):
                plants_changed.append(f"{name} -> {stable_id}")
            else:
                plants_already.append(f"{name} ({plant.get('stable_id')})")

    missing_priority = set(PRIORITY_CROPS) - found_priority
    if missing_priority:
        print(f"[UYARI] Öncelikli bitki seed'de bulunamadı: {sorted(missing_priority)}",
              file=sys.stderr)

    print("== migrate_v2 raporu ==")
    print(f"_schema v2 eklendi:        {'evet' if schema_changed else 'zaten vardı'}")
    print(f"v2 iskeleti yenii eklenen: {len(plants_changed)}")
    for line in plants_changed:
        print(f"  + {line}")
    print(f"v2 iskeleti zaten var:     {len(plants_already)}")
    for line in plants_already:
        print(f"  = {line}")

    has_changes = schema_changed or bool(plants_changed)

    if args.check:
        if has_changes:
            print("\n[CHECK] Değişiklik gerekli — --check modunda yazılmadı.")
            return 2
        print("\n[CHECK] Tüm öncelikli bitkilerde v2 iskeleti hazır.")
        return 0

    if has_changes:
        SEED.write_text(_serialize(data), encoding="utf-8")
        print(f"\n[OK] {SEED.name} güncellendi.")
    else:
        print("\n[OK] Değişiklik yok, dosya dokunulmadı.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
