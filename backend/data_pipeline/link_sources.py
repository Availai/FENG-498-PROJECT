"""5 öncelikli bitkiye source_ids[] referansını ekler ve missing_information'ı
WebFetch OCR sınırlamasına göre günceller. evidence[] BOŞ kalır — kaynak
metni doğrulanmadan eklenmez (CLAUDE.md sec 0/10/12).

İdempotent: aynı source_id'leri tekrar eklemez.

Kullanım:
    cd backend
    python data_pipeline/link_sources.py
"""
from __future__ import annotations

import json
import sys
from pathlib import Path

try:
    sys.stdout.reconfigure(encoding="utf-8")  # type: ignore[attr-defined]
    sys.stderr.reconfigure(encoding="utf-8")  # type: ignore[attr-defined]
except Exception:
    pass

BASE = Path(__file__).parent
SEED = BASE / "seed_plants.json"

# stable_id -> bağlanacak source.* id listesi
LINKS: dict[str, list[str]] = {
    "crop.tomato": [
        "source.tagem.tomato_open_field_ipm",
        "source.tagem.greenhouse_vegetables_ipm",
    ],
    "crop.corn": [
        "source.tagem.corn_ipm",
    ],
    "crop.sunflower": [
        "source.tagem.sunflower_ipm",
    ],
    "crop.tea": [
        "source.caykur.tea_cultivation_lecture_notes_2025",
    ],
    "crop.orange": [
        "source.tagem.citrus_ipm",
    ],
}

# WebFetch OCR sınırlamasını açıkça belirten missing_information şablonu
def missing_info_for(name_tr: str, source_count: int) -> list[str]:
    return [
        f"{name_tr}: {source_count} resmî kaynak (TAGEM/ÇAYKUR) sources.json'a bağlandı; URL ve başlıklar WebSearch ile doğrulandı.",
        "evidence[] dizisi BOŞ — WebFetch otomatik OCR yapamadı (PDF taranmış görüntü). Bire-bir alıntılar manuel doldurulacak.",
        "Manuel evidence ekleme yöntemi: PDF'i indir, ilgili paragraf/tabloyu Türkçe alıntıla, source_id ile eşle, page/section belirt.",
        "growth_stages[] — TAGEM yayınındaki fenoloji tablolarından çıkarılacak (henüz okunmadı).",
        "diseases_v2[] — common_diseases içindeki her hastalık için: stable id, scientific_name, evidence (kaynak alıntısı), requires_bku_check=true, requires_expert_confirmation=true.",
        "pests_v2[] — common_pests için stable id + scientific_name + evidence yapılandırılacak.",
        "fertilizer_rules[] — toprak analizi koşullu kurallar (CLAUDE.md sec 16 guardrail'leri).",
        "irrigation_rules[] — bölge + iklim + dönem koşullu sulama kuralları.",
        "rule_engine_rules[] — CLAUDE.md sec 14 formatı; her kural test_cases[] ile birlikte.",
    ]


def main() -> int:
    if not SEED.exists():
        print(f"[HATA] {SEED} yok.", file=sys.stderr)
        return 1

    data = json.loads(SEED.read_text(encoding="utf-8"))

    changed: list[str] = []
    for plant in data["plants"]:
        sid = plant.get("stable_id")
        if sid not in LINKS:
            continue

        target_sources = LINKS[sid]
        existing = list(plant.get("source_ids", []))
        # birleştir, sıra koru, tekrarsız
        merged = existing + [s for s in target_sources if s not in existing]

        plant_changed = False
        if merged != existing:
            plant["source_ids"] = merged
            plant_changed = True

        new_missing = missing_info_for(plant["name_tr"], len(merged))
        if plant.get("missing_information") != new_missing:
            plant["missing_information"] = new_missing
            plant_changed = True

        # source_ids dolu ama evidence boşsa v2_status hâlâ pending_sources mantıklı.
        # Operatör evidence ekleyince 'draft' yapacak.
        if plant_changed:
            changed.append(f"{plant['name_tr']:<10} <- {len(merged)} kaynak")

    if not changed:
        print("[OK] Değişiklik yok.")
        return 0

    # Migrate v2 ile aynı kompakt format
    schema_str = json.dumps(data["_schema"], ensure_ascii=False, indent=2)
    schema_str = "\n".join(("  " + line if i > 0 else line)
                           for i, line in enumerate(schema_str.split("\n")))
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

    SEED.write_text(out, encoding="utf-8")
    print("== link_sources raporu ==")
    for line in changed:
        print(f"  + {line}")
    print(f"\n[OK] {SEED.name} güncellendi.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
