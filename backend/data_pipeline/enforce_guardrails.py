"""seed_plants.json içindeki tüm zararlı/hastalık kayıtlarına BKÜ ve uzman
onayı flag'lerini ekler. CLAUDE.md sec 17/18 zorunluluğunu otomatik dayatır.

İdempotent: zaten doğru flag'i taşıyan kaydı dokunmaz. Validator hatası
düşene kadar tekrar çalıştırılabilir.

Kullanım:
    cd backend
    python data_pipeline/enforce_guardrails.py
    python data_pipeline/enforce_guardrails.py --dry-run   # değişikliği gösterir, yazmaz
"""
from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

try:
    sys.stdout.reconfigure(encoding="utf-8")  # type: ignore[attr-defined]
    sys.stderr.reconfigure(encoding="utf-8")  # type: ignore[attr-defined]
except Exception:
    pass

SEED = Path(__file__).parent / "seed_plants.json"

REQUIRED_FLAGS_DISEASE_PEST: dict = {
    "requires_bku_check": True,
    "requires_expert_confirmation": True,
}


def _ensure_flags(record: dict, flags: dict) -> bool:
    changed = False
    for k, v in flags.items():
        if record.get(k) is not v:
            record[k] = v
            changed = True
    return changed


def _serialize(data: dict) -> str:
    schema_str = json.dumps(data["_schema"], ensure_ascii=False, indent=2)
    schema_str = "\n".join(("  " + line if i > 0 else line)
                           for i, line in enumerate(schema_str.split("\n")))
    plant_lines = [
        json.dumps(p, ensure_ascii=False, separators=(",", ":"))
        for p in data["plants"]
    ]
    plants_block = ",\n".join("    " + line for line in plant_lines)
    return (
        "{\n"
        f'  "_schema": {schema_str},\n'
        '  "plants": [\n'
        f'{plants_block}\n'
        '  ]\n'
        '}\n'
    )


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--dry-run", action="store_true",
                        help="Sadece raporla, dosyaya yazma.")
    args = parser.parse_args()

    if not SEED.exists():
        print(f"[HATA] {SEED} yok.", file=sys.stderr)
        return 1

    data = json.loads(SEED.read_text(encoding="utf-8"))
    fixes: list[str] = []

    for plant in data.get("plants", []):
        name = plant.get("name_tr", "?")
        for field in ("diseases_v2", "pests_v2"):
            for i, rec in enumerate(plant.get(field, []) or []):
                if not isinstance(rec, dict):
                    continue
                rid = rec.get("id", f"#{i}")
                if _ensure_flags(rec, REQUIRED_FLAGS_DISEASE_PEST):
                    fixes.append(f"{name}.{field}[{i}] ({rid}) -> BKÜ + uzman flag eklendi")

    if not fixes:
        print("[OK] Tüm guardrail flag'leri zaten yerinde.")
        return 0

    print(f"== enforce_guardrails raporu ({len(fixes)} düzeltme) ==")
    for line in fixes:
        print(f"  + {line}")

    if args.dry_run:
        print("\n[DRY-RUN] Değişiklik yazılmadı.")
        return 0

    SEED.write_text(_serialize(data), encoding="utf-8")
    print(f"\n[OK] {SEED.name} güncellendi.")
    print("Sonraki adım: python data_pipeline/validate_rule_pack.py")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
