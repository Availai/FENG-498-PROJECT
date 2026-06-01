"""B2 — Çift kural motoru parite üreteci (CLAUDE.md sec 22, 28).

Bu pytest dosyası backend `rule_engine.analyze`'ı ortak parite fixture'ı ile
çalıştırır ve ortak kategorilerdeki (category, level, title) imzalarını
`test/fixtures/_py_parity_out.json` dosyasına yazar. Dart tarafı
(`test/services/rule_engine_parity_test.dart`) bu çıktıyı okuyup kendi
motoruyla karşılaştırır.

Tek kaynak: `test/fixtures/rule_parity_cases.json` (facts listesi). İki motor
da AYNI facts ile çalışır; böylece "aynı girdi → aynı çıktı" determinizm
iddiası (CLAUDE.md sec 22) makinece doğrulanır.

CI sırası: önce bu pytest (çıktı üretir), sonra `flutter test` (karşılaştırır).
"""

import json
from pathlib import Path

try:
    from backend.rule_engine import analyze, AnalyzeRequest
except ImportError:
    from rule_engine import analyze, AnalyzeRequest


# Repo kökü: backend/tests/ -> backend/ -> repo
_REPO_ROOT = Path(__file__).resolve().parents[2]
_FIXTURE = _REPO_ROOT / "test" / "fixtures" / "rule_parity_cases.json"
_OUTPUT = _REPO_ROOT / "test" / "fixtures" / "_py_parity_out.json"


def _load_fixture():
    return json.loads(_FIXTURE.read_text(encoding="utf-8"))


def test_parity_fixture_exists():
    assert _FIXTURE.exists(), f"Parite fixture'ı yok: {_FIXTURE}"


def test_generate_python_parity_output():
    """Python motorunun ortak-kategori imzalarını üret ve diske yaz."""
    fx = _load_fixture()
    shared = set(fx["shared_categories"])
    out: dict[str, list[str]] = {}

    for case in fx["cases"]:
        results = analyze(AnalyzeRequest(**case["facts"]))
        signatures = sorted(
            {
                f"{r.category.value}|{r.level.value}|{r.title}"
                for r in results
                if r.category.value in shared
            }
        )
        out[case["id"]] = signatures

    _OUTPUT.write_text(
        json.dumps(out, ensure_ascii=False, indent=1),
        encoding="utf-8",
    )

    # Üretim sağlığı: en az bir vakada ortak-kategori sonucu olmalı.
    assert any(sigs for sigs in out.values()), "Hiç ortak-kategori sonucu yok."


def test_engine_deterministic_same_input_same_output():
    """Aynı facts iki kez çalıştırılınca aynı sonucu vermeli (CLAUDE.md 22)."""
    fx = _load_fixture()
    for case in fx["cases"]:
        a = analyze(AnalyzeRequest(**case["facts"]))
        b = analyze(AnalyzeRequest(**case["facts"]))
        sig_a = [(r.category.value, r.level.value, r.title) for r in a]
        sig_b = [(r.category.value, r.level.value, r.title) for r in b]
        assert sig_a == sig_b, f"Determinizm ihlali: {case['id']}"
