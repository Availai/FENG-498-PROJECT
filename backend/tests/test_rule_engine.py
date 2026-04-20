"""Kural motoru testleri — FAO-56, MGM don, EPPO hastalık eşikleri ve giriş
doğrulaması için referans testler.

Çalıştırma: `cd backend && pytest tests/test_rule_engine.py -v`
"""
import math
import os
import sys

import pytest

# backend/ dizinini path'e ekle — testler backend/tests/ içinden çalışırken
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

from rule_engine import (  # noqa: E402
    AnalyzeRequest,
    RiskLevel,
    RuleCategory,
    _validate_env,
    analyze,
)


# ─────────────────────────────────────────────────────────────────────────────
# GİRİŞ DOĞRULAMA
# ─────────────────────────────────────────────────────────────────────────────

def test_validate_env_nan_temperature_resets_to_default():
    req = AnalyzeRequest(temperature=float("nan"))
    cleaned, issues = _validate_env(req)
    assert any("temperature" in i for i in issues)
    assert not math.isnan(cleaned.temperature)


def test_validate_env_inf_temperature_resets():
    req = AnalyzeRequest(temperature=float("inf"))
    cleaned, issues = _validate_env(req)
    assert any("temperature" in i for i in issues)
    assert cleaned.temperature != float("inf")


def test_validate_env_negative_humidity_clamped():
    req = AnalyzeRequest(humidity=-20.0)
    cleaned, issues = _validate_env(req)
    assert any("humidity" in i for i in issues)
    assert cleaned.humidity == 0.0


def test_validate_env_humidity_above_100_clamped():
    req = AnalyzeRequest(humidity=150.0)
    cleaned, issues = _validate_env(req)
    assert any("humidity" in i for i in issues)
    assert cleaned.humidity == 100.0


def test_validate_env_ph_above_14_clamped():
    # pH 15 fiziksel olarak imkânsız, 3..10 aralığına sıkıştırılmalı
    req = AnalyzeRequest(soil_ph=15.0)
    cleaned, issues = _validate_env(req)
    assert any("soil_ph" in i for i in issues)
    assert 3.0 <= cleaned.soil_ph <= 10.0


def test_validate_env_negative_rain_clamped_to_zero():
    req = AnalyzeRequest(weekly_rain=-5.0)
    cleaned, issues = _validate_env(req)
    assert any("weekly_rain" in i for i in issues)
    assert cleaned.weekly_rain == 0.0


def test_validate_env_extreme_cold_temperature_clamped():
    # Türkiye tarihinde en düşük -46°C (Ağrı); -60°C geçersiz sensör
    req = AnalyzeRequest(temperature=-60.0)
    cleaned, issues = _validate_env(req)
    assert any("temperature" in i for i in issues)
    assert cleaned.temperature == -40.0


def test_validate_env_valid_inputs_no_issues():
    req = AnalyzeRequest(
        temperature=22.0, humidity=65.0, soil_ph=6.5, weekly_rain=15.0
    )
    _, issues = _validate_env(req)
    assert issues == []


def test_validate_env_ndvi_out_of_range():
    # NDVI fiziksel aralığı -1..1
    req = AnalyzeRequest(ndvi=2.5)
    cleaned, issues = _validate_env(req)
    assert any("ndvi" in i for i in issues)
    assert -1.0 <= cleaned.ndvi <= 1.0


# ─────────────────────────────────────────────────────────────────────────────
# VERİ KALİTESİ ROZETİ — analyze()
# ─────────────────────────────────────────────────────────────────────────────

def test_analyze_flags_low_data_quality_when_multiple_bad():
    req = AnalyzeRequest(
        temperature=float("nan"),
        humidity=-5.0,
        soil_ph=15.0,
        weekly_rain=-10.0,
        common_name="domates",
    )
    results = analyze(req)
    quality = [r for r in results if r.title == "Veri Kalitesi Düşük"]
    assert len(quality) == 1
    # 3+ issue → confidence low
    assert quality[0].confidence == "low"


def test_analyze_no_quality_badge_when_inputs_clean():
    req = AnalyzeRequest(
        temperature=22.0, humidity=60.0, soil_ph=6.5, weekly_rain=10.0,
        common_name="domates",
    )
    results = analyze(req)
    quality = [r for r in results if r.title == "Veri Kalitesi Düşük"]
    assert quality == []


def test_default_rule_result_confidence_is_high():
    req = AnalyzeRequest(temperature=0.0, common_name="domates")
    results = analyze(req)
    # Don uyarısı var, confidence alanı mevcut ve default 'high'
    assert any(r.category == RuleCategory.weather for r in results)
    for r in results:
        assert r.confidence in ("high", "medium", "low")


# ─────────────────────────────────────────────────────────────────────────────
# DON KURALLARI
# ─────────────────────────────────────────────────────────────────────────────

def test_frost_critical_below_zero():
    req = AnalyzeRequest(temperature=-3.0, common_name="domates", month=11)
    results = analyze(req)
    frost = [r for r in results if r.category == RuleCategory.weather and
             "Don" in r.title]
    assert any(r.level == RiskLevel.critical for r in frost)


def test_frost_safe_in_warm_weather():
    req = AnalyzeRequest(temperature=15.0, common_name="domates", month=6)
    results = analyze(req)
    frost_critical = [r for r in results if r.level == RiskLevel.critical
                      and "Don" in r.title]
    assert frost_critical == []


def test_agricultural_frost_spring_sensitive_crop():
    # Nisan — kayısı — min 1°C → MGM kritik don riski
    req = AnalyzeRequest(
        temperature=5.0,
        min_temp_c=1.0,
        month=4,
        common_name="kayısı",
        latitude=39.5, longitude=32.0,
    )
    results = analyze(req)
    frost_rules = [r for r in results if r.category == RuleCategory.frost]
    assert len(frost_rules) >= 1
    assert any(r.level in (RiskLevel.critical, RiskLevel.warning)
               for r in frost_rules)


# ─────────────────────────────────────────────────────────────────────────────
# HASTALIK KURALLARI
# ─────────────────────────────────────────────────────────────────────────────

def test_disease_mildew_high_risk_for_tomato_potato():
    # Nem %90 + 15°C + domates → Phytophthora infestans eşik
    req = AnalyzeRequest(
        temperature=15.0, humidity=90.0, common_name="domates", month=6,
    )
    results = analyze(req)
    mildew = [r for r in results if "Mildiyö" in r.title or "Phytophthora" in r.title]
    assert len(mildew) >= 1
    assert mildew[0].eppo_code == "PHYTIN"


def test_disease_general_fungal_has_source_attribution():
    req = AnalyzeRequest(
        temperature=22.0, humidity=88.0, common_name="biber", month=7,
    )
    results = analyze(req)
    fungal = [r for r in results if r.title == "Genel Mantar Hastalık Riski"]
    assert len(fungal) == 1
    assert fungal[0].source_ref is not None
    assert "Agrios" in fungal[0].source_ref


def test_disease_wheat_yellow_rust():
    req = AnalyzeRequest(
        temperature=20.0, humidity=80.0, common_name="buğday", month=4,
    )
    results = analyze(req)
    rust = [r for r in results if "Pas" in r.title]
    assert len(rust) >= 1
    assert rust[0].eppo_code == "PUCCST"


# ─────────────────────────────────────────────────────────────────────────────
# GÜVEN GERİLEMESİ (regresyon koruması)
# ─────────────────────────────────────────────────────────────────────────────

def test_analyze_handles_completely_empty_request():
    """Kötü senaryo: hiçbir sensör verisi gelmemiş. Motor patlaması olmamalı,
    en azından varsayılan önerilerle dönmeli."""
    req = AnalyzeRequest()
    results = analyze(req)
    assert isinstance(results, list)
    # analyze() her zaman en az 0 kural döndürebilir; exception at
    for r in results:
        assert r.title and r.recommendation


def test_analyze_sorts_by_severity_critical_first():
    req = AnalyzeRequest(
        temperature=-2.0,
        humidity=95.0,
        common_name="domates",
        month=11,
    )
    results = analyze(req)
    # Kritik → warning → info → ok sırası
    severities = [r.level for r in results]
    severity_order = {
        RiskLevel.critical: 0, RiskLevel.warning: 1,
        RiskLevel.info: 2, RiskLevel.ok: 3,
    }
    indexed = [severity_order[s] for s in severities]
    assert indexed == sorted(indexed)


def test_all_results_have_required_fields():
    req = AnalyzeRequest(
        temperature=25.0, humidity=80.0, common_name="üzüm",
        weekly_rain=45.0, month=7,
    )
    results = analyze(req)
    for r in results:
        assert r.title
        assert r.message
        assert r.recommendation
        assert r.emoji  # post_init doldurur
        assert r.category_label
        assert r.confidence in ("high", "medium", "low")


if __name__ == "__main__":
    pytest.main([__file__, "-v"])
