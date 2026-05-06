"""5 öncelikli bitki için v2 evidence kayıtlarını seed_plants.json'a yazar.

CLAUDE.md sec 0/10/12/14/17 sıkı uyumluluk:
- Evidence metinleri TAGEM/ÇAYKUR resmî PDF'lerinden bire-bir alıntı (PyMuPDF ile çıkarıldı).
- Hiçbir ilaç/aktif madde/doz tavsiyesi yok — sadece risk koşulu, belirti, kültürel önlem.
- Tüm hastalık ve hasta-tedavisi kuralları requires_bku_check + requires_expert_confirmation: true.
- v2_status="draft" — uzman/kullanıcı onayı sonrası "review" veya "approved" olur.

Şu an dolu: Domates (TAGEM Açık Alan Domates EM Talimatı, Ankara-2022).
İskelet bekleyen: Mısır, Ayçiçeği, Çay, Portakal — PDF'leri indirilip okunduğunda eklenir.

İdempotent: aynı evidence iki kez yazmaz, mevcut yapıyı güvenle günceller.

Kullanım:
    cd backend
    python data_pipeline/populate_priority_crops.py
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

SEED = Path(__file__).parent / "seed_plants.json"

# ─── DOMATES (crop.tomato) ────────────────────────────────────────────────
# Kaynak: TAGEM Açık Alan Domates Entegre Mücadele Teknik Talimatı, Ankara-2022.
# PyMuPDF ile sayfa numarası ve bölüm referansı doğrulandı.

TOMATO_DATA: dict = {
    "stable_id": "crop.tomato",
    "source_ids": [
        "source.tagem.tomato_open_field_ipm",
        "source.tagem.greenhouse_vegetables_ipm",
    ],
    "evidence": [
        {
            "source_id": "source.tagem.tomato_open_field_ipm",
            "page": 5,
            "section": "Önsöz",
            "evidence_text": "Ülkemizde domates yetiştiriciliği yaklaşık 1.800.000 da alanda yapılmakta ve 12.750.000 ton üretim gerçekleştirilmektedir (TUİK, 2018). Türkiye taze sebze ihracatının yaklaşık %57'sini oluşturan domates, sektörün öncüsü olmuştur.",
        },
        {
            "source_id": "source.tagem.tomato_open_field_ipm",
            "page": 6,
            "section": "Önsöz",
            "evidence_text": "Entegre mücadele talimatlarında; mekanik ve fiziksel mücadeleyi de içeren kültürel tedbirler, biyolojik mücadele, biyoteknik yöntemler, dayanıklı çeşitlerin kullanımı, genetik mücadele gibi kimyasal mücadeleye alternatif yöntemlere öncelik verilmektedir.",
        },
    ],
    "confidence": "medium",
    "diseases_v2": [
        {
            "id": "disease.tomato.late_blight",
            "name_tr": "Domates Mildiyösü",
            "scientific_name": "Phytophthora infestans (Mont.) de Bary",
            "source_ids": ["source.tagem.tomato_open_field_ipm"],
            "evidence": [
                {
                    "source_id": "source.tagem.tomato_open_field_ipm",
                    "page": 22,
                    "section": "6.2.1. Domates mildiyösü — Tanımı, yaşayışı ve hastalık belirtileri",
                    "evidence_text": "Bulaşmalar genellikle 16°C'de, epidemi ise 19-22°C'de ve orantılı nemin %80'nin üstünde bulunduğu koşullarda gerçekleşir.",
                },
                {
                    "source_id": "source.tagem.tomato_open_field_ipm",
                    "page": 22,
                    "section": "6.2.1. Domates mildiyösü",
                    "evidence_text": "Sıcaklık ve orantılı nem ne kadar elverişli olursa enfeksiyonlar o kadar çabuk (2-3 saat içinde) ve inkubasyon (kuluçka) süresi de o oranda kısa olmaktadır.",
                },
                {
                    "source_id": "source.tagem.tomato_open_field_ipm",
                    "page": 22,
                    "section": "6.2.1. Domates mildiyösü",
                    "evidence_text": "Hastalıklı bitkilerin yaprakları üzerinde önce küçük soluk yeşil veya sarımsı lekeler belirir. Hastalık ilerledikçe lekelerin rengi kahverengi veya siyaha dönüşür. Nemli havalarda ve 16-22°C sıcaklıkta yapraktaki lekelerin alt yüzeyinde beyaz veya kül renkli fungal bir örtü meydana gelir.",
                },
            ],
            "requires_bku_check": True,
            "requires_expert_confirmation": True,
            "control_methods_cultural": [
                "Hastalıklı bitki ve meyveler vejetasyon dönemi boyunca ve hasat bitiminde tarladan uzaklaştırılarak imha edilmelidir.",
                "Sık dikimden kaçınılmalıdır.",
                "Hastalığın her yıl epidemi oluşturduğu yörelerde sırık domates yetiştiriciliği yapılmalı, sıralar hakim rüzgar yönünde olmalıdır.",
            ],
        },
        {
            "id": "disease.tomato.early_blight",
            "name_tr": "Erken Yaprak Yanıklığı",
            "scientific_name": "Alternaria solani Ell. and Mart.",
            "source_ids": ["source.tagem.tomato_open_field_ipm"],
            "evidence": [
                {
                    "source_id": "source.tagem.tomato_open_field_ipm",
                    "page": 25,
                    "section": "6.2.2. Domates Erken Yaprak Yanıklığı",
                    "evidence_text": "Hastalık 6-34°C'lerde gelişebilmekle beraber optimum gelişme sıcaklığı 28-30°C'dir. Orantılı nemin yüksek olduğu koşullar hastalığın gelişimini teşvik eder.",
                },
                {
                    "source_id": "source.tagem.tomato_open_field_ipm",
                    "page": 25,
                    "section": "6.2.2. Domates Erken Yaprak Yanıklığı",
                    "evidence_text": "Etmen, fide döneminde kök çürüklüğü veya kök boğazı yanıklığı yapar. Daha sonraki dönemlerde ise yaprak, gövde ve meyvelerde lekeler halinde görülür. Bu lekeler iç içe halkalar halinde büyürler ve koyu gri bir renk alır.",
                },
            ],
            "requires_bku_check": True,
            "requires_expert_confirmation": True,
            "control_methods_cultural": [
                "Hastalıklı bitki ve meyveler vejetasyon dönemi boyunca ve hasat bitiminde tarladan uzaklaştırılarak imha edilmelidir.",
                "Fidelikler sık sık havalandırılmalıdır.",
                "Aşırı sulamadan kaçınılmalıdır.",
                "Sertifikalı tohum veya sağlıklı fide kullanılmalıdır.",
            ],
        },
    ],
    "pests_v2": [
        {
            "id": "pest.tomato.tuta_absoluta",
            "name_tr": "Domates güvesi",
            "scientific_name": "Tuta absoluta (Meyrick) (Lepidoptera: Gelechiidae)",
            "source_ids": ["source.tagem.tomato_open_field_ipm"],
            "evidence": [
                {
                    "source_id": "source.tagem.tomato_open_field_ipm",
                    "page": 15,
                    "section": "6.1.1. Domates güvesi — Tanımı, yaşayışı ve zarar şekli",
                    "evidence_text": "Domates güvesi domates yetiştiriciliğinde ana zararlı konumundadır. Larvaları domates bitkisinin kökü dışında tüm kısımlarında ve her döneminde zarar vermektedir.",
                },
                {
                    "source_id": "source.tagem.tomato_open_field_ipm",
                    "page": 16,
                    "section": "6.1.1. Domates güvesi",
                    "evidence_text": "Akdeniz iklimine sahip yerlerde hızla çoğalan zararlı seralarda yılda 9 döl verebilir. Çevre koşullarına bağlı olarak bir dölünü 29-38 günde tamamlar.",
                },
                {
                    "source_id": "source.tagem.tomato_open_field_ipm",
                    "page": 17,
                    "section": "6.1.1. Domates güvesi — Bölgesel biyoloji",
                    "evidence_text": "Orta Anadolu Bölgesi'nde açık alan domates yetiştiriciliğinde iklim koşullarına (ortalama sıcaklık 25°C) bağlı olarak ilk erginler mayıs ayının son haftası-haziran ayının ilk haftasında görülmektedir. Yılda 3-4 döl veren zararlı...",
                },
                {
                    "source_id": "source.tagem.tomato_open_field_ipm",
                    "page": 19,
                    "section": "6.1.1. Domates güvesi — Mücadelesi (Kimyasal mücadele eşiği)",
                    "evidence_text": "100 bitkiden 3'ü zararlının herhangi bir biyolojik dönemi ile bulaşık ise mücadeleye karar verilir.",
                },
            ],
            "control_methods_cultural": [
                "Fidelikler çift kapılı olmalı, giriş ve havalandırma açıklıkları zararlının giremeyeceği incelikte tül ile kapatılmalı.",
                "Zararlı ile bulaşık fideler ile üretime başlanmamalı.",
                "Üretim alanı ve çevresinde Solanaceae familyasına ait yabancı otlarla mücadele edilmeli.",
                "Hasat sonrası bitki artıkları imha edilmeli; tarlada kalan larva ve pupaları öldürmek için derin sürüm yapılmalıdır.",
                "Aşırı azotlu gübreleme ile aşırı sulamadan kaçınılmalıdır.",
                "Solanaceae familyasına bağlı olmayan ürünler ile münavebe yapılmalı.",
            ],
        },
        {
            "id": "pest.tomato.helicoverpa_armigera",
            "name_tr": "Yeşilkurt",
            "scientific_name": "Helicoverpa armigera (Hübn.) (Lep.: Noctuidae)",
            "source_ids": ["source.tagem.tomato_open_field_ipm"],
            "evidence": [
                {
                    "source_id": "source.tagem.tomato_open_field_ipm",
                    "page": 21,
                    "section": "6.1.2. Yeşilkurt — Tanımı, yaşayışı ve zarar şekli",
                    "evidence_text": "Polifag bir zararlıdır. Yumurtalarını yaprak, meyve ve taze sürgünlere tek tek bırakır. Bir dişi 700-1500 adet yumurta bırakabilir.",
                },
                {
                    "source_id": "source.tagem.tomato_open_field_ipm",
                    "page": 21,
                    "section": "6.1.2. Yeşilkurt",
                    "evidence_text": "Açık alanda domates yetiştiriciliğinde iklime bağlı olarak kıyı bölgelerde 3-4, iç bölgelerde 1-2 döl verebilir. Bir larva birden fazla meyvede delmek suretiyle zarar oluşturarak, meyvelerin çürümesine neden olur.",
                },
                {
                    "source_id": "source.tagem.tomato_open_field_ipm",
                    "page": 22,
                    "section": "6.1.2. Yeşilkurt — Mücadele eşiği",
                    "evidence_text": "Meyvedeki bulaşma oranı %5'e ulaştığında mücadele yapılmalıdır. Zararlı ile kimyasal mücadelede, domates güvesi de dikkate alınmalıdır.",
                },
            ],
            "control_methods_cultural": [
                "Tarla ve çevresinde yabancı ot temizliği yapılmalıdır.",
                "Zarar görmüş meyveler ortamdan uzaklaştırılmalıdır.",
                "Doğal düşmanların korunması için kimyasal ilaçlarda yan etkisi en az olan pestisitler tercih edilmelidir.",
            ],
        },
    ],
    "weeds_v2": [
        {
            "id": "weed.tomato.orobanche",
            "name_tr": "Canavar otu",
            "scientific_name": "Orobanche spp. (Orobanchaceae)",
            "source_ids": ["source.tagem.tomato_open_field_ipm"],
            "evidence": [
                {
                    "source_id": "source.tagem.tomato_open_field_ipm",
                    "page": 26,
                    "section": "6.3.1. Canavar otu",
                    "evidence_text": "Canavar otları tohumlarıyla çoğalan, tek yıllık, klorofili olmadığı için kendi besinini sentezleyemeyen tam parazit bitkilerdir. Tohumlar olumsuz çevre şartlarına oldukça dayanıklıdır. Bu sayede toprakta 10-12 yıl kadar canlılığını kaybetmeden kalabilir.",
                },
                {
                    "source_id": "source.tagem.tomato_open_field_ipm",
                    "page": 26,
                    "section": "6.3.1. Canavar otu",
                    "evidence_text": "Canavar otlarının oluşturduğu verim kaybı, bu parazitin yoğunluğuna bağlı olarak %5-100 arasında değişir. Ülkemizde 36 canavar otu türü bulunmasına karşın domates bitkisi Orobanche ramosa L. ve Orobanche aegyptiaca Pers. türlerinin konukçusudur.",
                },
                {
                    "source_id": "source.tagem.tomato_open_field_ipm",
                    "page": 27,
                    "section": "6.3.1. Canavar otu — Münavebe",
                    "evidence_text": "Yazlık kültür bitkilerinden mısır ve pamuk, kışlık kültür bitkilerinden buğday ve arpa canavar otunun konukçusu değildir. Daha önceden yoğun canavar otu olduğu bilinen tarlalara tekrar canavar otu konukçusu olan bitkiler 8-10 seneden önce ekilmemelidir.",
                },
                {
                    "source_id": "source.tagem.tomato_open_field_ipm",
                    "page": 27,
                    "section": "6.3.1. Canavar otu — Kimyasal mücadele",
                    "evidence_text": "Domateste canavar otuna karşı kullanılabilecek bitki koruma ürünü bulunmamaktadır.",
                },
            ],
            "control_methods_cultural": [
                "Bulaşık alanlarda kullanılan tarım alet ve makineleri başka bir alanda kullanılmadan önce temizlenmelidir.",
                "Temiz tohumluk ve fide kullanılmalı, sertifikalı tohumlar tercih edilmelidir.",
                "İyi yanmış hayvan gübresi kullanılmalıdır.",
                "Toplanan canavar otları derin çukurlara gömülmeli ya da yakılmalıdır; tarla içine bırakılmamalıdır.",
                "Sulama suyunun canavar otu tohumu içermemesine dikkat edilmelidir.",
                "8-10 yıl mısır/pamuk/buğday/arpa gibi konukçu olmayan ürünlerle münavebe yapılmalıdır.",
            ],
        },
    ],
    "rule_engine_rules": [
        {
            "id": "rule.tomato.disease.late_blight.high_humidity_temp",
            "crop_id": "crop.tomato",
            "category": "disease_risk",
            "priority": 90,
            "enabled": True,
            "conditions": [
                {"field": "crop_id", "operator": "equals", "value": "crop.tomato"},
                {"field": "average_temperature_c", "operator": "between", "value": [16, 22]},
                {"field": "relative_humidity_percent", "operator": "greater_or_equal", "value": 80},
            ],
            "result": {
                "risk_level": "high",
                "possible_problem_id": "disease.tomato.late_blight",
                "recommendations": [
                    "Yapraklarda 3-5 mm çapında kahverengi lekeleri kontrol edin (yaprak alt yüzeyinde beyaz/kül renkli mantar örtüsü hastalık kanıtıdır).",
                    "Hastalıklı bitki ve meyveleri tarladan uzaklaştırıp imha edin.",
                    "Sık dikimden ve aşırı sulamadan kaçının.",
                    "Kimyasal mücadele gerekiyorsa Tarım ve Orman Bakanlığı BKÜ veritabanında güncel ruhsatlı ürün, etiket dozu ve son ilaçlama-hasat aralığını kontrol edin.",
                ],
                "requires_expert_confirmation": True,
                "requires_bku_check": True,
            },
            "explanation": "Domates mildiyösü 16°C civarında bulaşma yapar; 19-22°C ortalama sıcaklık + %80 üstü orantılı nemde epidemi koşulları oluşur.",
            "confidence": "high",
            "evidence": [
                {
                    "source_id": "source.tagem.tomato_open_field_ipm",
                    "page": 22,
                    "section": "6.2.1. Domates mildiyösü",
                    "evidence_text": "Bulaşmalar genellikle 16°C'de, epidemi ise 19-22°C'de ve orantılı nemin %80'nin üstünde bulunduğu koşullarda gerçekleşir.",
                }
            ],
        },
        {
            "id": "rule.tomato.disease.early_blight.warm_humid",
            "crop_id": "crop.tomato",
            "category": "disease_risk",
            "priority": 80,
            "enabled": True,
            "conditions": [
                {"field": "crop_id", "operator": "equals", "value": "crop.tomato"},
                {"field": "average_temperature_c", "operator": "between", "value": [28, 30]},
                {"field": "relative_humidity_level", "operator": "equals", "value": "high"},
            ],
            "result": {
                "risk_level": "medium",
                "possible_problem_id": "disease.tomato.early_blight",
                "recommendations": [
                    "Yapraklarda iç içe halkalı koyu gri lekeleri kontrol edin.",
                    "Fidelikleri sık havalandırın, aşırı sulamadan kaçının.",
                    "Sertifikalı tohum veya sağlıklı fide kullanın.",
                    "Hastalıklı bitkileri tarladan uzaklaştırın.",
                    "Kimyasal mücadele gerekiyorsa BKÜ kontrolü ve uzman onayı alın.",
                ],
                "requires_expert_confirmation": True,
                "requires_bku_check": True,
            },
            "explanation": "Erken Yaprak Yanıklığı 6-34°C aralığında gelişir; optimum 28-30°C ve yüksek nemde teşvik edilir.",
            "confidence": "high",
            "evidence": [
                {
                    "source_id": "source.tagem.tomato_open_field_ipm",
                    "page": 25,
                    "section": "6.2.2. Domates Erken Yaprak Yanıklığı",
                    "evidence_text": "Hastalık 6-34°C'lerde gelişebilmekle beraber optimum gelişme sıcaklığı 28-30°C'dir. Orantılı nemin yüksek olduğu koşullar hastalığın gelişimini teşvik eder.",
                }
            ],
        },
        {
            "id": "rule.tomato.pest.tuta_absoluta.threshold_3pct",
            "crop_id": "crop.tomato",
            "category": "pest_risk",
            "priority": 95,
            "enabled": True,
            "conditions": [
                {"field": "crop_id", "operator": "equals", "value": "crop.tomato"},
                {"field": "tuta_absoluta_infested_plants_per_100", "operator": "greater_or_equal", "value": 3},
            ],
            "result": {
                "risk_level": "high",
                "possible_problem_id": "pest.tomato.tuta_absoluta",
                "recommendations": [
                    "Mücadele kararı alınmalıdır.",
                    "Bulaşık yaprak/meyveleri tarladan uzaklaştırın.",
                    "Solanaceae familyası dışı ürünlerle münavebe planlayın.",
                    "Aşırı azotlu gübreleme ve aşırı sulamadan kaçının.",
                    "Kimyasal mücadele gerekiyorsa BKÜ kontrolü, doğal düşman koruması ve uzman onayı alın.",
                ],
                "requires_expert_confirmation": True,
                "requires_bku_check": True,
            },
            "explanation": "TAGEM eşiği: 100 bitkiden 3'ü zararlının herhangi bir biyolojik dönemi ile bulaşık ise mücadele kararı alınır.",
            "confidence": "high",
            "evidence": [
                {
                    "source_id": "source.tagem.tomato_open_field_ipm",
                    "page": 19,
                    "section": "6.1.1. Domates güvesi — Mücadelesi",
                    "evidence_text": "100 bitkiden 3'ü zararlının herhangi bir biyolojik dönemi ile bulaşık ise mücadeleye karar verilir.",
                }
            ],
        },
        {
            "id": "rule.tomato.pest.helicoverpa.threshold_5pct",
            "crop_id": "crop.tomato",
            "category": "pest_risk",
            "priority": 85,
            "enabled": True,
            "conditions": [
                {"field": "crop_id", "operator": "equals", "value": "crop.tomato"},
                {"field": "helicoverpa_fruit_infestation_percent", "operator": "greater_or_equal", "value": 5},
            ],
            "result": {
                "risk_level": "high",
                "possible_problem_id": "pest.tomato.helicoverpa_armigera",
                "recommendations": [
                    "Mücadele kararı alınmalıdır.",
                    "Tarla ve çevresinde yabancı ot temizliği yapın.",
                    "Zarar görmüş meyveleri uzaklaştırın.",
                    "Domates güvesi (Tuta absoluta) ile birlikte değerlendirilmelidir.",
                    "Kimyasal mücadele gerekiyorsa doğal düşmanlara yan etkisi en az ürün seçilmeli; BKÜ kontrolü ve uzman onayı zorunludur.",
                ],
                "requires_expert_confirmation": True,
                "requires_bku_check": True,
            },
            "explanation": "TAGEM eşiği: meyvedeki bulaşma oranı %5'e ulaştığında Yeşilkurt mücadelesine başlanmalıdır.",
            "confidence": "high",
            "evidence": [
                {
                    "source_id": "source.tagem.tomato_open_field_ipm",
                    "page": 22,
                    "section": "6.1.2. Yeşilkurt — Mücadele",
                    "evidence_text": "Meyvedeki bulaşma oranı %5'e ulaştığında mücadele yapılmalıdır.",
                }
            ],
        },
    ],
    "v2_status": "draft",
    "missing_information": [
        "growth_stages[] — TAGEM yayını fenoloji bölümü ayrı, henüz çıkarılmadı.",
        "fertilizer_rules[] — toprak analizi koşullu kurallar henüz yazılmadı (CLAUDE.md sec 16 guardrail'lerine uygun).",
        "irrigation_rules[] — bölge + dönem bazlı sulama kuralları henüz yazılmadı.",
        "Diğer 11 zararlı (kırmızı örümcek, beyazsinekler, yaprakbiti, thrips, vb.) için pests_v2 kayıtları açılacak.",
        "14+ diğer hastalık (külleme, kurşuni küf, sclerotinia, septorya, bakteriyeller, virüsler) için diseases_v2 kayıtları açılacak.",
        "test_cases — her rule_engine_rule için pozitif/negatif örnek girdiler (CLAUDE.md sec 21).",
        "v2_status='draft' — uzman onayı sonrası 'review' veya 'approved' yapılacak.",
    ],
}


def _replace_or_keep(plant: dict, new_data: dict) -> bool:
    """Plant kaydında v2 alanlarını günceller. Returns True if changed."""
    changed = False
    for k, v in new_data.items():
        if plant.get(k) != v:
            plant[k] = v
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
    if not SEED.exists():
        print(f"[HATA] {SEED} yok.", file=sys.stderr)
        return 1

    data = json.loads(SEED.read_text(encoding="utf-8"))

    updates: dict[str, dict] = {
        "crop.tomato": TOMATO_DATA,
        # crop.corn / crop.sunflower / crop.tea / crop.orange — sırayla eklenecek.
    }

    changed_plants: list[str] = []
    for plant in data["plants"]:
        sid = plant.get("stable_id")
        if sid in updates:
            if _replace_or_keep(plant, updates[sid]):
                d = sum(len(plant.get(f, [])) for f in
                        ["evidence", "diseases_v2", "pests_v2",
                         "weeds_v2", "rule_engine_rules"])
                changed_plants.append(f"{plant['name_tr']:<10} ({sid}) -> {d} v2 kaydı")

    if not changed_plants:
        print("[OK] Değişiklik yok.")
        return 0

    SEED.write_text(_serialize(data), encoding="utf-8")
    print("== populate_priority_crops raporu ==")
    for line in changed_plants:
        print(f"  + {line}")
    print(f"\n[OK] {SEED.name} güncellendi.")
    print("Sonraki adım: python data_pipeline/validate_rule_pack.py")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
