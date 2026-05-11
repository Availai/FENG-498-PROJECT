"""seed_plants.json + sources.json üzerinde guardrail doğrulaması.

CLAUDE.md sec 21 (Validation Kuralları) ve sec 17 (BKÜ Güvenlik Kuralları)
referans alınır. Hatalar non-zero exit code ile raporlanır; uyarılar bilgi
amaçlıdır.

Kullanım:
    cd backend
    python data_pipeline/validate_rule_pack.py
    python data_pipeline/validate_rule_pack.py --strict   # uyarılar da fail
"""
from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path

BASE = Path(__file__).parent
SEED = BASE / "seed_plants.json"
SOURCES = BASE / "sources.json"

ALLOWED_CONFIDENCE = {"high", "medium", "low"}
ALLOWED_V2_STATUS = {"pending_sources", "draft", "review", "approved"}
ALLOWED_SOURCE_TYPES = {
    "official", "research_institute", "university", "public_agency", "private"
}
ALLOWED_RELIABILITY = {"high", "medium", "low"}

STABLE_ID_RE = re.compile(r"^[a-z0-9_]+(\.[a-z0-9_]+)+$")


class Report:
    def __init__(self) -> None:
        self.errors: list[str] = []
        self.warnings: list[str] = []

    def err(self, msg: str) -> None:
        self.errors.append(msg)

    def warn(self, msg: str) -> None:
        self.warnings.append(msg)

    def summary(self, strict: bool) -> int:
        print(f"\n== Validation Raporu ==")
        print(f"Hata:   {len(self.errors)}")
        print(f"Uyarı:  {len(self.warnings)}")
        for e in self.errors:
            print(f"  [HATA] {e}")
        for w in self.warnings:
            print(f"  [UYARI] {w}")
        if self.errors:
            return 1
        if strict and self.warnings:
            return 2
        return 0


def _validate_stable_id(value: str, ctx: str, rep: Report) -> None:
    if not isinstance(value, str) or not STABLE_ID_RE.match(value):
        rep.err(f"{ctx}: stable_id formatı hatalı ('{value}'). "
                f"Beklenen: küçük harf, _ ve . — Türkçe karakter yok.")


def _validate_evidence_list(evidence: object, ctx: str,
                            known_source_ids: set[str], rep: Report) -> None:
    if not isinstance(evidence, list):
        rep.err(f"{ctx}: evidence dizisi bekleniyor.")
        return
    for i, ev in enumerate(evidence):
        sub = f"{ctx}.evidence[{i}]"
        if not isinstance(ev, dict):
            rep.err(f"{sub}: dict olmalı.")
            continue
        sid = ev.get("source_id")
        if not sid:
            rep.err(f"{sub}: source_id zorunlu.")
        elif sid not in known_source_ids:
            rep.err(f"{sub}: source_id '{sid}' sources.json'da yok.")
        if not ev.get("evidence_text"):
            rep.err(f"{sub}: evidence_text boş olamaz.")


def _validate_disease_or_pest(record: dict, kind: str, ctx: str,
                              known_source_ids: set[str], rep: Report) -> None:
    rid = record.get("id", "")
    _validate_stable_id(rid, f"{ctx}.id", rep)
    if not rid.startswith(f"{kind}."):
        rep.err(f"{ctx}.id: '{kind}.*' ile başlamalı (bulundu: '{rid}').")
    if not record.get("name_tr"):
        rep.err(f"{ctx}: name_tr boş olamaz.")
    _validate_evidence_list(record.get("evidence", []), ctx,
                            known_source_ids, rep)
    # CLAUDE.md sec 17/18 — BKÜ + uzman onayı guardrail'i hem disease hem pest
    # için zorunludur (zararlı içeren her tavsiye kimyasal mücadeleye
    # götürebilir). Eksik flag = hata.
    if kind in ("disease", "pest"):
        if record.get("requires_bku_check") is not True:
            rep.err(f"{ctx}: requires_bku_check=true zorunlu (sec 17).")
        if record.get("requires_expert_confirmation") is not True:
            rep.err(f"{ctx}: requires_expert_confirmation=true zorunlu (sec 18).")


def _validate_rule_engine_rule(rule: dict, ctx: str,
                               known_source_ids: set[str], rep: Report) -> None:
    rid = rule.get("id", "")
    _validate_stable_id(rid, f"{ctx}.id", rep)
    if not rule.get("conditions") or not isinstance(rule["conditions"], list):
        rep.err(f"{ctx}: conditions[] zorunlu.")
    if not isinstance(rule.get("result"), dict):
        rep.err(f"{ctx}: result dict zorunlu.")
    _validate_evidence_list(rule.get("evidence", []), ctx,
                            known_source_ids, rep)
    cat = rule.get("category", "")
    # CLAUDE.md sec 17 — kimyasal kategorilerde BKÜ flag'i
    if cat in {"disease_risk", "pest_risk"}:
        result = rule.get("result", {})
        recs = " ".join(result.get("recommendations", []) if isinstance(result, dict) else [])
        if any(kw in recs.lower() for kw in ["doz", "ml/da", "g/da", "gr/da", "aktif madde"]):
            if result.get("requires_bku_check") is not True:
                rep.err(f"{ctx}: BKÜ ile ilgili anahtar kelime tespit edildi, "
                        f"requires_bku_check true olmalı (sec 17).")


def _as_num(value: object) -> float | None:
    if isinstance(value, bool):
        return 1.0 if value else 0.0
    if isinstance(value, (int, float)):
        return float(value)
    if isinstance(value, str):
        try:
            return float(value)
        except ValueError:
            return None
    return None


def _condition_matches(cond: dict, facts: dict) -> bool:
    field = cond.get("field")
    op = cond.get("operator", "equals")
    expected = cond.get("value")
    actual = facts.get(field)

    if op == "exists":
        return actual is not None
    if op == "missing":
        return actual is None
    if op == "equals":
        return actual == expected
    if op == "not_equals":
        return actual != expected
    if op == "greater_than":
        a, e = _as_num(actual), _as_num(expected)
        return a is not None and e is not None and a > e
    if op == "less_than":
        a, e = _as_num(actual), _as_num(expected)
        return a is not None and e is not None and a < e
    if op == "greater_or_equal":
        a, e = _as_num(actual), _as_num(expected)
        return a is not None and e is not None and a >= e
    if op == "less_or_equal":
        a, e = _as_num(actual), _as_num(expected)
        return a is not None and e is not None and a <= e
    if op == "between":
        if not isinstance(expected, list) or len(expected) != 2:
            return False
        a, lo, hi = _as_num(actual), _as_num(expected[0]), _as_num(expected[1])
        return a is not None and lo is not None and hi is not None and lo <= a <= hi
    if op == "contains":
        if isinstance(actual, list):
            return expected in actual
        if isinstance(actual, str) and isinstance(expected, str):
            return expected in actual
        return False
    if op == "in":
        return isinstance(expected, list) and actual in expected
    if op == "not_in":
        return isinstance(expected, list) and actual not in expected
    return False


def _rule_matches(rule: dict, facts: dict) -> bool:
    return all(_condition_matches(c, facts) for c in rule.get("conditions", []))


def _validate_test_cases(plant: dict, ctx: str, rep: Report) -> None:
    rules = {
        rule.get("id"): rule
        for rule in plant.get("rule_engine_rules", [])
        if isinstance(rule, dict) and rule.get("id")
    }
    if not rules:
        return

    cases = plant.get("test_cases")
    if not isinstance(cases, list) or not cases:
        rep.err(f"{ctx}.test_cases: her rule_engine_rule için test case zorunlu.")
        return

    by_rule: dict[str, set[bool]] = {rule_id: set() for rule_id in rules}
    seen_case_ids: set[str] = set()
    for i, case in enumerate(cases):
        sub = f"{ctx}.test_cases[{i}]"
        if not isinstance(case, dict):
            rep.err(f"{sub}: dict olmalı.")
            continue

        case_id = case.get("id", "")
        _validate_stable_id(case_id, f"{sub}.id", rep)
        if not str(case_id).startswith("test."):
            rep.err(f"{sub}.id: 'test.*' ile başlamalı.")
        if case_id in seen_case_ids:
            rep.err(f"{sub}.id: tekrarlanmış test id '{case_id}'.")
        seen_case_ids.add(case_id)

        rule_id = case.get("rule_id")
        if rule_id not in rules:
            rep.err(f"{sub}.rule_id: rule_engine_rules içinde yok ('{rule_id}').")
            continue

        facts = case.get("facts")
        if not isinstance(facts, dict):
            rep.err(f"{sub}.facts: dict olmalı.")
            continue
        expected = case.get("expected_match")
        if not isinstance(expected, bool):
            rep.err(f"{sub}.expected_match: bool olmalı.")
            continue

        actual = _rule_matches(rules[rule_id], facts)
        if actual != expected:
            rep.err(f"{sub}: beklenen eşleşme {expected}, hesaplanan {actual}.")
        by_rule[rule_id].add(expected)

    for rule_id, outcomes in by_rule.items():
        if outcomes != {False, True}:
            rep.err(f"{ctx}.test_cases: '{rule_id}' için pozitif ve negatif test zorunlu.")


def validate_sources(sources_doc: dict, rep: Report) -> set[str]:
    known: set[str] = set()
    src_list = sources_doc.get("sources", [])
    if not isinstance(src_list, list):
        rep.err("sources.json: 'sources' dizisi yok veya hatalı.")
        return known
    for i, s in enumerate(src_list):
        ctx = f"sources[{i}]"
        if not isinstance(s, dict):
            rep.err(f"{ctx}: dict olmalı.")
            continue
        sid = s.get("id", "")
        _validate_stable_id(sid, f"{ctx}.id", rep)
        if not sid.startswith("source."):
            rep.err(f"{ctx}.id: 'source.*' ile başlamalı.")
        if sid in known:
            rep.err(f"{ctx}.id: tekrarlanmış id '{sid}'.")
        known.add(sid)
        if not s.get("title"):
            rep.err(f"{ctx}: title boş olamaz.")
        if s.get("source_type") not in ALLOWED_SOURCE_TYPES:
            rep.err(f"{ctx}.source_type: izinli değerlerden biri olmalı.")
        if s.get("reliability") not in ALLOWED_RELIABILITY:
            rep.err(f"{ctx}.reliability: high|medium|low olmalı.")
        if not s.get("url"):
            rep.warn(f"{ctx}: url boş — resmî yayın URL'si önerilir.")
        if not s.get("retrieved_at"):
            rep.warn(f"{ctx}: retrieved_at boş.")
    return known


def validate_priority_crops(seed_doc: dict, known_source_ids: set[str],
                            rep: Report) -> None:
    schema = seed_doc.get("_schema", {})
    expected = set(schema.get("v2_priority_crops", []))
    if not expected:
        rep.warn("_schema.v2_priority_crops listesi boş veya eksik.")
        return

    found_ids: set[str] = set()
    for plant in seed_doc.get("plants", []):
        if "stable_id" not in plant:
            continue
        ctx = f"plant[{plant.get('name_tr', '?')}]"
        sid = plant["stable_id"]
        _validate_stable_id(sid, f"{ctx}.stable_id", rep)
        found_ids.add(sid)

        # confidence
        conf = plant.get("confidence")
        if conf not in ALLOWED_CONFIDENCE:
            rep.err(f"{ctx}.confidence: {ALLOWED_CONFIDENCE} bekleniyor (bulundu: {conf}).")

        # v2_status
        status = plant.get("v2_status")
        if status not in ALLOWED_V2_STATUS:
            rep.err(f"{ctx}.v2_status: {ALLOWED_V2_STATUS} bekleniyor (bulundu: {status}).")

        # evidence (top-level)
        _validate_evidence_list(plant.get("evidence", []), ctx,
                                known_source_ids, rep)

        # source_ids referans bütünlüğü
        for s in plant.get("source_ids", []):
            if s not in known_source_ids:
                rep.err(f"{ctx}.source_ids: '{s}' sources.json'da yok.")

        # Hastalıklar / zararlılar / yabancı otlar — BKÜ guardrail
        for i, d in enumerate(plant.get("diseases_v2", [])):
            _validate_disease_or_pest(d, "disease",
                                      f"{ctx}.diseases_v2[{i}]",
                                      known_source_ids, rep)
        for i, p in enumerate(plant.get("pests_v2", [])):
            _validate_disease_or_pest(p, "pest",
                                      f"{ctx}.pests_v2[{i}]",
                                      known_source_ids, rep)
        for i, w in enumerate(plant.get("weeds_v2", [])):
            wid = w.get("id", "")
            _validate_stable_id(wid, f"{ctx}.weeds_v2[{i}].id", rep)
            if not wid.startswith("weed."):
                rep.err(f"{ctx}.weeds_v2[{i}].id: 'weed.*' ile başlamalı (bulundu: '{wid}').")
            if not w.get("name_tr"):
                rep.err(f"{ctx}.weeds_v2[{i}]: name_tr boş olamaz.")
            _validate_evidence_list(w.get("evidence", []),
                                    f"{ctx}.weeds_v2[{i}]",
                                    known_source_ids, rep)

        # Kurallar
        for i, r in enumerate(plant.get("rule_engine_rules", [])):
            _validate_rule_engine_rule(r, f"{ctx}.rule_engine_rules[{i}]",
                                       known_source_ids, rep)
        _validate_test_cases(plant, ctx, rep)

        # Fenoloji — her aşamada key + label_tr beklenir
        for i, gs in enumerate(plant.get("growth_stages", [])):
            sub = f"{ctx}.growth_stages[{i}]"
            if not isinstance(gs, dict):
                rep.err(f"{sub}: dict olmalı.")
                continue
            if not gs.get("key"):
                rep.err(f"{sub}: key boş olamaz.")
            if not (gs.get("label_tr") or gs.get("name_tr")):
                rep.err(f"{sub}: label_tr veya name_tr zorunlu.")

        # Gübreleme/sulama kuralları — kaynak gerektirir (sec 16)
        for i, r in enumerate(plant.get("fertilizer_rules", [])):
            sub = f"{ctx}.fertilizer_rules[{i}]"
            if not isinstance(r, dict):
                rep.err(f"{sub}: dict olmalı.")
                continue
            if not r.get("id"):
                rep.err(f"{sub}: id boş olamaz.")
            ev = r.get("evidence", [])
            if isinstance(ev, list) and ev:
                _validate_evidence_list(ev, sub, known_source_ids, rep)
            else:
                rep.warn(f"{sub}: evidence[] boş — kaynak kanıtı önerilir.")
        for i, r in enumerate(plant.get("irrigation_rules", [])):
            sub = f"{ctx}.irrigation_rules[{i}]"
            if not isinstance(r, dict):
                rep.err(f"{sub}: dict olmalı.")
                continue
            if not r.get("id"):
                rep.err(f"{sub}: id boş olamaz.")
            ev = r.get("evidence", [])
            if isinstance(ev, list) and ev:
                _validate_evidence_list(ev, sub, known_source_ids, rep)

        # approved durumdaysa kanıt zorunlu
        if status == "approved":
            if not plant.get("evidence"):
                rep.err(f"{ctx}: v2_status=approved ama evidence[] boş.")
            if not plant.get("source_ids"):
                rep.err(f"{ctx}: v2_status=approved ama source_ids[] boş.")
            if conf == "low":
                rep.warn(f"{ctx}: approved fakat confidence=low — gözden geçir.")

    missing = expected - found_ids
    if missing:
        rep.err(f"v2_priority_crops listesinde tanımlı ama plant kaydı bulunamayan stable_id'ler: {sorted(missing)}")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--strict", action="store_true",
                        help="Uyarılar da hata sayılır.")
    args = parser.parse_args()

    rep = Report()

    if not SEED.exists():
        print(f"[HATA] {SEED} yok.", file=sys.stderr)
        return 1
    if not SOURCES.exists():
        print(f"[HATA] {SOURCES} yok.", file=sys.stderr)
        return 1

    try:
        seed_doc = json.loads(SEED.read_text(encoding="utf-8"))
    except json.JSONDecodeError as e:
        print(f"[HATA] seed_plants.json parse edilemedi: {e}", file=sys.stderr)
        return 1
    try:
        sources_doc = json.loads(SOURCES.read_text(encoding="utf-8"))
    except json.JSONDecodeError as e:
        print(f"[HATA] sources.json parse edilemedi: {e}", file=sys.stderr)
        return 1

    known_source_ids = validate_sources(sources_doc, rep)
    validate_priority_crops(seed_doc, known_source_ids, rep)

    return rep.summary(args.strict)


if __name__ == "__main__":
    raise SystemExit(main())
