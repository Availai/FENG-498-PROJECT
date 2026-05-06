"""5 öncelikli bitki için v2 evidence kayıtlarını seed_plants.json'a yazar.

CLAUDE.md sec 0/10/12/14/17 sıkı uyumluluk:
- Evidence metinleri TAGEM/ÇAYKUR resmî PDF'lerinden doğrulanmış alıntıdır.
- İlaç/aktif madde/doz uydurulmaz; BKÜ gerektiren yerde sadece kontrol
  zorunluluğu ve uzman onayı işaretlenir.
- Hastalık ve zararlı risk kuralları requires_expert_confirmation kullanır.
- v2_status="draft" — uzman/kullanıcı onayı sonrası "review" veya "approved" olur.

Kapsam: Domates, Mısır, Ayçiçeği, Portakal ve Çay için hastalık/zararlı,
fenolojik dönem, gübreleme, sulama ve özel çözüm kartlarını kaynak kanıtıyla
günceller. Çayda doğrulanmış hastalık profili olmadığı için hastalık adı
uydurulmaz; kaynaklı zararlı/toprak/sulama/hasat bilgileri uygulanır.

İdempotent: aynı id ikinci kez yazılmaz, mevcut yapı güvenle güncellenir.

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
        "İkincil domates hastalık/zararlılarının tamamı ayrı v2 profiline açılmadı; mevcut uygulama kapsamı mildiyö, erken yaprak yanıklığı, domates güvesi, yeşilkurt ve kaynaklı fizyolojik besleme/sulama riskleridir.",
        "test_cases — her rule_engine_rule için pozitif/negatif örnek girdiler eklenecek.",
        "v2_status='draft' — uzman onayı sonrası 'review' veya 'approved' yapılacak.",
    ],
}


# ─── MISIR (crop.corn) ────────────────────────────────────────────────────
# Kaynak: TAGEM Mısır Entegre Mücadele Teknik Talimatı, Ankara-2022.
# PyMuPDF ile sayfa numarası ve bölüm referansı doğrulandı.

CORN_DATA: dict = {
    "stable_id": "crop.corn",
    "source_ids": ["source.tagem.corn_ipm"],
    "evidence": [
        {
            "source_id": "source.tagem.corn_ipm",
            "page": 5,
            "section": "Önsöz",
            "evidence_text": "Mısır, Ülkemiz ekonomisi ve halkımızın beslenmesi için stratejik önemde bir ürün olup, hemen hemen tüm bölgelerimizde yetiştirilmektedir. Türkiye'de 2021 yılı TUİK verilerine göre toplam 12.889.076 dekar alanda tane ve silajlık mısır ekimi yapılarak 6.878.704 ton tanelik ve 27.309.962 ton ise silajlık mısır üretilmektedir.",
        },
        {
            "source_id": "source.tagem.corn_ipm",
            "page": 5,
            "section": "Önsöz",
            "evidence_text": "Mısır tarlalarında, tek başına veya birlikte zarar yapan, pek çok hastalık, zararlı ve yabancı ot türü bulunmaktadır. Bunlardan en önemlileri Mısır Koçankurdu ve Mısırkurdu gibi ana zararlılardır.",
        },
    ],
    "confidence": "medium",
    "diseases_v2": [
        {
            "id": "disease.corn.common_smut",
            "name_tr": "Mısır Rastığı",
            "scientific_name": "Ustilago maydis (DC) Corda",
            "source_ids": ["source.tagem.corn_ipm"],
            "evidence": [
                {
                    "source_id": "source.tagem.corn_ipm",
                    "page": 61,
                    "section": "7.2.1. Mısır Rastığı — Tanımı ve yaşayışı",
                    "evidence_text": "Mısır rastığı, bitkinin bütün toprak üstü aksamında (yaprak, sap, koçan ve tepe püskülünde) görülür. Özellikle genç, aktif gelişme dönemindeki bitkilerde çok şiddetlidir. Enfeksiyondan sonra parlak gri-beyaz ya da gümüşi renkte galler (ur) oluşur.",
                },
                {
                    "source_id": "source.tagem.corn_ipm",
                    "page": 62,
                    "section": "7.2.1. Mısır Rastığı — Epidemiyoloji",
                    "evidence_text": "Yağış, hastalığın gelişmesinde önemli bir etkendir. Yağışların yaz başlangıcında düştüğü yıllarda hastalık daha fazla görülür. Hafif yağıştan sonraki güneşli kuru ya da az bulutlu havalar hastalığın gelişimini artırır. Fungusun enfeksiyonu ve gal gelişmesi için, 18-21°C sıcaklıklar uygundur. Fazla azotlu gübre ya da çiftlik gübresi verilen alanlarda daha fazla görülür.",
                },
                {
                    "source_id": "source.tagem.corn_ipm",
                    "page": 62,
                    "section": "7.2.1. Mısır Rastığı — Mücadelesi (Kimyasal mücadele)",
                    "evidence_text": "Hastalığın kimyasal mücadelesi bulunmamaktadır.",
                },
            ],
            "requires_bku_check": True,
            "requires_expert_confirmation": True,
            "control_methods_cultural": [
                "Hastalıktan ari alanlardan alınan tohumlar kullanılmalıdır.",
                "Dayanıklı ya da toleranslı çeşitler kullanılmalıdır.",
                "Kültürel işlemler ya da ilaçlamalar sırasında mekanik zararlardan kaçınılmalıdır.",
                "Dengeli gübreleme yapılmalı, aşırı azot kullanılmamalıdır.",
                "Galler tam gelişmeden koparılıp, yakılmalıdır.",
                "Mısır rastığının çok zarar yaptığı yerlerde 3-4 yıllık ekim nöbeti uygulanmalıdır.",
                "Hastalıklı bitki artıkları hayvanlara yedirilmemeli, toplanarak derine gömülmeli ya da yakılmalıdır.",
                "Zararlılarla mücadele ederek, bitki yaralanmaları önlenmelidir.",
            ],
        },
        {
            "id": "disease.corn.fusarium_stalk_ear_rot",
            "name_tr": "Mısırda Sap, Kök ve Koçan Çürüklükleri (Fusarium kompleksi)",
            "scientific_name": "Fusarium moniliforme (=verticillioides) Sheldon, Fusarium graminearum Schwabe",
            "source_ids": ["source.tagem.corn_ipm"],
            "evidence": [
                {
                    "source_id": "source.tagem.corn_ipm",
                    "page": 63,
                    "section": "7.2.2. Mısırda Tohum, Kök, Kökboğazı, Sap ve Koçan Çürüklükleri",
                    "evidence_text": "Mısırda tohum, kök, kökboğazı, sap ve koçan çürüklüklerine öncelikle Pythium spp., Fusarium moniliforme (=verticilliodes), F. graminearum, Rhizoctonia spp. Macrophomina phaseolina, neden olurken Bipolaris maydis, B. pedicellatum, Colletotrichum graminicola, Aspergillus spp., Penicillium spp., Nigrospora oryzae, ve Cephalosporium maydis etmenleri de neden olabilir. Ayrıca bu funguslardan Fusarium türleri koçan ve tane çürüklüklerine de neden olarak mikotoksin oluşturabilir.",
                },
                {
                    "source_id": "source.tagem.corn_ipm",
                    "page": 63,
                    "section": "7.2.2. Mısırda Tohum/Kök/Sap Çürüklükleri",
                    "evidence_text": "Henüz çimlenmemiş veya çimlenen mısır tohumları; tohum çürüklüğü ve fide yanıklığını oluşturan toprak ve tohum kaynaklı birçok etmen tarafından enfekte edilebilir. Bu durum özellikle drenajı zayıf, aşırı killi, soğuk (10-13°C'den az) ve rutubetli topraklarda daha çok görülür.",
                },
                {
                    "source_id": "source.tagem.corn_ipm",
                    "page": 64,
                    "section": "7.2.2. Mısırda Sap Çürüklükleri — Fusarium spp.",
                    "evidence_text": "Bu etmenler kurak ve sıcak bölgelerde özellikle tepe püskülü çıkarma devresinde etkilidir. Fusarium sap çürüklüğünde bitkilerin boğum aralarında çürümeler ve koçan üzerinde ise fungusun pembemsi beyaz renkli misel kitlesi oluşur.",
                },
                {
                    "source_id": "source.tagem.corn_ipm",
                    "page": 65,
                    "section": "7.2.2. Mısırda Sap/Koçan Çürüklükleri — Verim kaybı",
                    "evidence_text": "Marmara, Karadeniz ve Akdeniz Bölgesi'nde bu hastalıklardan dolayı uygun iklim koşullarında bazı tarlalarda yaklaşık %20-30 oranında verim kayıpları oluşturabildiği gibi dolaylı olarak kalite kayıplarına da neden olabilir.",
                },
            ],
            "requires_bku_check": True,
            "requires_expert_confirmation": True,
            "control_methods_cultural": [
                "Sertifikalı tohum kullanılmalıdır.",
                "İyi bir tohum yatağı hazırlanmalı, ekim derinliği uygun olmalı, toprak sıcaklığı 13°C'den yüksek olmalıdır.",
                "Dayanıklı veya tolerant çeşitler tercih edilmelidir.",
                "Sap ve koçan yaralanmasından mümkün olduğu kadar kaçınılmalıdır.",
                "Gübreler toprak analizi sonuçlarına göre uygulanmalıdır.",
                "Hastalığın yoğun olduğu yerlerde münavebe uygulanmalıdır.",
                "Sık ekimden ve aşırı sulamadan kaçınılmalıdır.",
                "Hasat zamanında yapılmalı ve tarlada kalan bitki artıkları yok edilmelidir.",
            ],
        },
    ],
    "pests_v2": [
        {
            "id": "pest.corn.sesamia_nonagrioides",
            "name_tr": "Mısır Koçankurdu",
            "scientific_name": "Sesamia nonagrioides Lef., Sesamia cretica Led. (Lepidoptera: Noctuidae)",
            "source_ids": ["source.tagem.corn_ipm"],
            "evidence": [
                {
                    "source_id": "source.tagem.corn_ipm",
                    "page": 17,
                    "section": "6.1. Mısır Koçankurdu — Bölgesel döl sayısı",
                    "evidence_text": "Mısır Koçankurdu yurdumuzda Akdeniz, Ege, Marmara ve Güneydoğu Anadolu Bölgelerindeki mısır ekim alanlarında yaygın olup; Ege Bölgesinde 3 ve Akdeniz Bölgesinde yılda 4-5 döl verirler.",
                },
                {
                    "source_id": "source.tagem.corn_ipm",
                    "page": 18,
                    "section": "6.1. Mısır Koçankurdu — Verim kaybı",
                    "evidence_text": "Mısır Koçankurdu ile mücadele yapılmadığı takdirde, %80-100'e varan oranda ürün kaybı meydana gelebilmektedir.",
                },
                {
                    "source_id": "source.tagem.corn_ipm",
                    "page": 21,
                    "section": "6.1. Mısır Koçankurdu — Mücadele eşiği",
                    "evidence_text": "Ülkemizde, birinci ürün mısırlarda, genellikle zararlı yoğunluğu düşük olduğundan ilaçlamaya gerek duyulmamaktadır. Ancak, bulaşık bitki sayısı %5 ve üzerinde ise kimyasal mücadele uygulanmalıdır.",
                },
                {
                    "source_id": "source.tagem.corn_ipm",
                    "page": 21,
                    "section": "6.1. Mısır Koçankurdu — 2.ürün eşiği",
                    "evidence_text": "İkinci ürün mısırlarda, ışık tuzaklarında yakalanan ergin sayısı 5-10 adet/hafta olduğunda ve zararlıya ait ilk yumurta kümeleri görüldüğü andan itibaren ilk ilaçlamaya başlanır ve ovipozisyon süresine ve ilaçların etki süresine bağlı olarak 10-15 gün ara ile ikinci ve üçüncü ilaçlama yapılabilir.",
                },
            ],
            "control_methods_cultural": [
                "Hasat sonrası arta kalan mısır sapları ve kökleri parçalanıp imha edilmelidir.",
                "Tarla derin sürülerek, bitki artıklarında kışlayan larvaların derine gömülmesi sağlanmalıdır.",
                "İkinci ürün mısırda erken ekim Mısır Koçankurdu zararını azaltır.",
                "Yumurta parazitoiti Telenomus busseolae korunmalı; doğal düşmanların yoğun olduğu yerlerde kimyasal mücadeleden mümkün olduğunca kaçınılmalıdır.",
            ],
        },
        {
            "id": "pest.corn.ostrinia_nubilalis",
            "name_tr": "Mısırkurdu",
            "scientific_name": "Ostrinia nubilalis Hbn. (Lepidoptera: Crambidae)",
            "source_ids": ["source.tagem.corn_ipm"],
            "evidence": [
                {
                    "source_id": "source.tagem.corn_ipm",
                    "page": 24,
                    "section": "6.2. Mısırkurdu — Bölgesel döl sayısı",
                    "evidence_text": "Mısırkurdu, Karadeniz Bölgesinde 2, Ege ve Marmara Bölgelerinde 3 ve Akdeniz Bölgesinde 4 döl verebilmektedir.",
                },
                {
                    "source_id": "source.tagem.corn_ipm",
                    "page": 26,
                    "section": "6.2. Mısırkurdu — Trichogramma salımı",
                    "evidence_text": "Ostrinia nubilalis kelebekleri ışık tuzaklarında yakalandıktan ve tarlada zararlının yumurta paketi bulunduktan sonra ilk salım ve 7-10 gün sonra ikinci salım yapılmalıdır. Belirlenen salım planına göre, her salımda dekara 7.500 parazitoit gelecek şekilde uygulama yapılmalıdır.",
                },
                {
                    "source_id": "source.tagem.corn_ipm",
                    "page": 28,
                    "section": "6.2. Mısırkurdu — Mücadele eşiği",
                    "evidence_text": "Ülkemizde, birinci ürün mısırlarda, genellikle zararlı yoğunluğu düşük olduğundan ilaçlamaya gerek duyulmamaktadır. Ancak, bulaşık bitki sayısı %5 ve üzerinde ise kimyasal mücadele uygulanmalıdır.",
                },
                {
                    "source_id": "source.tagem.corn_ipm",
                    "page": 28,
                    "section": "6.2. Mısırkurdu — 2.ürün eşiği",
                    "evidence_text": "İkinci ürün mısırlarda, ışık tuzaklarında yakalanan ergin sayısı 10-15 adet/hafta olduğunda ve zararlıya ait ilk yumurta paketleri görüldüğü andan itibaren ilk ilaçlamaya başlanır.",
                },
            ],
            "control_methods_cultural": [
                "Hasat sonrası arta kalan mısır sapları ve kökleri parçalanıp imha edilmelidir.",
                "Tarla derin sürülerek, bitki artıklarında kışlayan larvaların derine gömülmesi sağlanır.",
                "İkinci ürün mısırda erken ekim Mısırkurdu zararını azaltır.",
                "Doğal düşmanların korunması için gelişigüzel ilaçlamalardan kaçınılmalıdır.",
            ],
        },
        {
            "id": "pest.corn.helicoverpa_armigera",
            "name_tr": "Yeşilkurt (Mısırda)",
            "scientific_name": "Helicoverpa armigera Hübner (Lepidoptera: Noctuidae)",
            "source_ids": ["source.tagem.corn_ipm"],
            "evidence": [
                {
                    "source_id": "source.tagem.corn_ipm",
                    "page": 44,
                    "section": "7.1.7. Yeşilkurt — Zarar şekli",
                    "evidence_text": "Tepe ve koçan püsküllerini keserek döllenmeye engel olan larvalar, koçanların seyrek daneli olmasına sebep olurlar. Ayrıca, süt olum döneminde larvalar, koçanın uç kısmında 3-5 cm'lik alandaki daneleri yiyerek zararlı olurlar. Bundan dolayı üründe verim ve kalite düşer.",
                },
                {
                    "source_id": "source.tagem.corn_ipm",
                    "page": 46,
                    "section": "7.1.7. Yeşilkurt — Mücadele eşiği",
                    "evidence_text": "Mısır koçan püskülü döneminde tarlanın 5 farklı yerinde aynı sıra üzerinde yanyana 5 bitkinin koçan püskülü üzerinde yapılan larva kontrolünde bitki başına ortalama 1 adet 1.-3. dönem larva belirlendiğinde ilaçlama yapılmalıdır.",
                },
            ],
            "control_methods_cultural": [
                "Hasattan sonra tarlalar sürülmelidir.",
                "Yabancı ot mücadelesi önemlidir.",
                "Doğal düşmanlar yeterli olduğunda kimyasal mücadeleye gerek duyulmamaktadır.",
            ],
        },
    ],
    "rule_engine_rules": [
        {
            "id": "rule.corn.disease.common_smut.warm_humid_high_n",
            "crop_id": "crop.corn",
            "category": "disease_risk",
            "priority": 80,
            "enabled": True,
            "conditions": [
                {"field": "crop_id", "operator": "equals", "value": "crop.corn"},
                {"field": "average_temperature_c", "operator": "between", "value": [18, 21]},
                {"field": "early_summer_rain_followed_by_sun", "operator": "equals", "value": True},
            ],
            "result": {
                "risk_level": "medium",
                "possible_problem_id": "disease.corn.common_smut",
                "recommendations": [
                    "Genç gelişme dönemindeki bitkilerde yaprak/sap/koçan/tepe püskülünde gri-beyaz galleri (ur) kontrol edin.",
                    "Galler tam olgunlaşmadan koparılıp yakılmalıdır.",
                    "Aşırı azotlu gübrelemeden kaçının; toprak analizine dayalı dengeli gübre verin.",
                    "Bulaşık alanlarda 3-4 yıllık ekim nöbeti uygulayın; bitki artıklarını derine gömün ya da yakın.",
                    "Hastalığın kimyasal mücadelesi bulunmamaktadır — kültürel önlemler tek seçenektir.",
                ],
                "requires_expert_confirmation": True,
                "requires_bku_check": False,
            },
            "explanation": "Mısır rastığı 18-21°C arasında ve hafif yağıştan sonra güneşli/az bulutlu havalarda epidemi yapar; aşırı azotlu gübreleme riski artırır.",
            "confidence": "high",
            "evidence": [
                {
                    "source_id": "source.tagem.corn_ipm",
                    "page": 62,
                    "section": "7.2.1. Mısır Rastığı",
                    "evidence_text": "Fungusun enfeksiyonu ve gal gelişmesi için, 18-21°C sıcaklıklar uygundur. Fazla azotlu gübre ya da çiftlik gübresi verilen alanlarda daha fazla görülür.",
                }
            ],
        },
        {
            "id": "rule.corn.disease.fusarium_seed_rot.cold_wet_soil",
            "crop_id": "crop.corn",
            "category": "disease_risk",
            "priority": 85,
            "enabled": True,
            "conditions": [
                {"field": "crop_id", "operator": "equals", "value": "crop.corn"},
                {"field": "growth_stage", "operator": "in", "value": ["sowing", "seedling"]},
                {"field": "soil_temperature_c", "operator": "less_than", "value": 13},
                {"field": "soil_moisture_level", "operator": "equals", "value": "high"},
            ],
            "result": {
                "risk_level": "high",
                "possible_problem_id": "disease.corn.fusarium_stalk_ear_rot",
                "recommendations": [
                    "Toprak sıcaklığı 13°C'nin üzerine çıkmadan ekim yapmayın.",
                    "Drenajı zayıf, aşırı killi alanlarda ekim derinliğini ve tav koşullarını gözden geçirin.",
                    "Sertifikalı, ilaçlı tohum kullanın.",
                    "Sık ekimden ve aşırı sulamadan kaçının.",
                    "Tohum ilaçlaması gerekiyorsa BKÜ veritabanında güncel ruhsatlı ürün kontrolü yapın.",
                ],
                "requires_expert_confirmation": True,
                "requires_bku_check": True,
            },
            "explanation": "Tohum ve fide çürüklüğü, drenajı zayıf, killi, soğuk (<13°C) ve rutubetli topraklarda Fusarium ve Pythium etmenleri tarafından yaygın görülür.",
            "confidence": "high",
            "evidence": [
                {
                    "source_id": "source.tagem.corn_ipm",
                    "page": 63,
                    "section": "7.2.2. Mısırda Tohum/Kök/Sap Çürüklükleri",
                    "evidence_text": "Bu durum özellikle drenajı zayıf, aşırı killi, soğuk (10-13°C'den az) ve rutubetli topraklarda daha çok görülür.",
                }
            ],
        },
        {
            "id": "rule.corn.disease.fusarium_stalk_rot.dry_hot_tasseling",
            "crop_id": "crop.corn",
            "category": "disease_risk",
            "priority": 80,
            "enabled": True,
            "conditions": [
                {"field": "crop_id", "operator": "equals", "value": "crop.corn"},
                {"field": "growth_stage", "operator": "equals", "value": "tasseling"},
                {"field": "climate_condition", "operator": "in", "value": ["dry_hot", "drought_stress"]},
            ],
            "result": {
                "risk_level": "medium",
                "possible_problem_id": "disease.corn.fusarium_stalk_ear_rot",
                "recommendations": [
                    "Boğum aralarında çürüme ve koçanlarda pembemsi-beyaz misel kitlesini kontrol edin.",
                    "Sap ve koçan yaralanmalarından kaçının (zararlı mücadelesini ihmal etmeyin).",
                    "Hasadı zamanında yapın; tarlada kalan bitki artıklarını yok edin.",
                    "Toprak analizine dayalı dengeli gübreleme yapın.",
                    "Kimyasal mücadele için BKÜ kontrolü ve uzman onayı alın.",
                ],
                "requires_expert_confirmation": True,
                "requires_bku_check": True,
            },
            "explanation": "Fusarium sap/koçan çürüklüğü kurak-sıcak bölgelerde özellikle tepe püskülü çıkarma devresinde aktiftir; mikotoksin riski oluşur.",
            "confidence": "high",
            "evidence": [
                {
                    "source_id": "source.tagem.corn_ipm",
                    "page": 64,
                    "section": "7.2.2. Mısırda Sap Çürüklükleri",
                    "evidence_text": "Bu etmenler kurak ve sıcak bölgelerde özellikle tepe püskülü çıkarma devresinde etkilidir.",
                }
            ],
        },
        {
            "id": "rule.corn.pest.sesamia.threshold_5pct",
            "crop_id": "crop.corn",
            "category": "pest_risk",
            "priority": 95,
            "enabled": True,
            "conditions": [
                {"field": "crop_id", "operator": "equals", "value": "crop.corn"},
                {"field": "crop_cycle", "operator": "equals", "value": "first_crop"},
                {"field": "sesamia_infested_plants_percent", "operator": "greater_or_equal", "value": 5},
            ],
            "result": {
                "risk_level": "high",
                "possible_problem_id": "pest.corn.sesamia_nonagrioides",
                "recommendations": [
                    "Mücadele kararı alınmalıdır.",
                    "Mücadeleden önce TAGEM 5.1 örnekleme yöntemine göre sayım doğrulaması yapın.",
                    "Hasat sonrası sap ve kök artıklarını parçalayıp imha edin; derin sürüm yapın.",
                    "Doğal düşman Telenomus busseolae korunmalı; ilaç seçiminde yan etki en az olan tercih edilmelidir.",
                    "Kimyasal mücadele gerekiyorsa BKÜ kontrolü, etiket dozu ve son ilaçlama-hasat aralığı zorunludur.",
                ],
                "requires_expert_confirmation": True,
                "requires_bku_check": True,
            },
            "explanation": "TAGEM eşiği: 1.ürün mısırda bulaşık bitki sayısı %5 ve üzerinde ise Mısır Koçankurdu kimyasal mücadelesi yapılır.",
            "confidence": "high",
            "evidence": [
                {
                    "source_id": "source.tagem.corn_ipm",
                    "page": 21,
                    "section": "6.1. Mısır Koçankurdu — Mücadele eşiği",
                    "evidence_text": "Ülkemizde, birinci ürün mısırlarda, genellikle zararlı yoğunluğu düşük olduğundan ilaçlamaya gerek duyulmamaktadır. Ancak, bulaşık bitki sayısı %5 ve üzerinde ise kimyasal mücadele uygulanmalıdır.",
                }
            ],
        },
        {
            "id": "rule.corn.pest.sesamia.second_crop_light_trap",
            "crop_id": "crop.corn",
            "category": "pest_risk",
            "priority": 90,
            "enabled": True,
            "conditions": [
                {"field": "crop_id", "operator": "equals", "value": "crop.corn"},
                {"field": "crop_cycle", "operator": "equals", "value": "second_crop"},
                {"field": "sesamia_light_trap_adults_per_week", "operator": "between", "value": [5, 10]},
                {"field": "sesamia_first_egg_mass_observed", "operator": "equals", "value": True},
            ],
            "result": {
                "risk_level": "high",
                "possible_problem_id": "pest.corn.sesamia_nonagrioides",
                "recommendations": [
                    "İlk ilaçlamaya başlanır; 10-15 gün ara ile 2. ve 3. ilaçlama yapılabilir.",
                    "Silajlık ve taze tüketim mısırlarda kimyasal mücadele önerilmemektedir.",
                    "İlaçlama bitki fenolojisine uygun yer aleti ile yapılmalıdır.",
                    "BKÜ veritabanında güncel ruhsatlı ürün, doz ve son ilaçlama-hasat aralığı kontrolü zorunludur.",
                ],
                "requires_expert_confirmation": True,
                "requires_bku_check": True,
            },
            "explanation": "TAGEM 2.ürün eşiği: ışık tuzakta 5-10 ergin/hafta + ilk yumurta kümesi gözleminde Mısır Koçankurdu mücadelesi başlatılır.",
            "confidence": "high",
            "evidence": [
                {
                    "source_id": "source.tagem.corn_ipm",
                    "page": 21,
                    "section": "6.1. Mısır Koçankurdu — 2.ürün eşiği",
                    "evidence_text": "İkinci ürün mısırlarda, ışık tuzaklarında yakalanan ergin sayısı 5-10 adet/hafta olduğunda ve zararlıya ait ilk yumurta kümeleri görüldüğü andan itibaren ilk ilaçlamaya başlanır.",
                }
            ],
        },
        {
            "id": "rule.corn.pest.ostrinia.threshold_5pct",
            "crop_id": "crop.corn",
            "category": "pest_risk",
            "priority": 95,
            "enabled": True,
            "conditions": [
                {"field": "crop_id", "operator": "equals", "value": "crop.corn"},
                {"field": "crop_cycle", "operator": "equals", "value": "first_crop"},
                {"field": "ostrinia_infested_plants_percent", "operator": "greater_or_equal", "value": 5},
            ],
            "result": {
                "risk_level": "high",
                "possible_problem_id": "pest.corn.ostrinia_nubilalis",
                "recommendations": [
                    "Mücadele kararı alınmalıdır.",
                    "Trichogramma evanescens / T. brassicae salımı (her salımda 7.500 parazitoit/dekar; 7-10 gün ara ile 2-3 salım) öncelikli alternatiftir.",
                    "Hasat sonrası sap ve kök artıklarını parçalayıp imha edin.",
                    "Kimyasal mücadele gerekiyorsa BKÜ kontrolü ve uzman onayı zorunludur.",
                ],
                "requires_expert_confirmation": True,
                "requires_bku_check": True,
            },
            "explanation": "TAGEM eşiği: 1.ürün mısırda bulaşık bitki sayısı %5 ve üzerinde ise Mısırkurdu mücadelesi yapılır.",
            "confidence": "high",
            "evidence": [
                {
                    "source_id": "source.tagem.corn_ipm",
                    "page": 28,
                    "section": "6.2. Mısırkurdu — Mücadele eşiği",
                    "evidence_text": "Ancak, bulaşık bitki sayısı %5 ve üzerinde ise kimyasal mücadele uygulanmalıdır.",
                }
            ],
        },
        {
            "id": "rule.corn.pest.ostrinia.second_crop_light_trap",
            "crop_id": "crop.corn",
            "category": "pest_risk",
            "priority": 90,
            "enabled": True,
            "conditions": [
                {"field": "crop_id", "operator": "equals", "value": "crop.corn"},
                {"field": "crop_cycle", "operator": "equals", "value": "second_crop"},
                {"field": "ostrinia_light_trap_adults_per_week", "operator": "between", "value": [10, 15]},
                {"field": "ostrinia_first_egg_pack_observed", "operator": "equals", "value": True},
            ],
            "result": {
                "risk_level": "high",
                "possible_problem_id": "pest.corn.ostrinia_nubilalis",
                "recommendations": [
                    "İlk ilaçlamaya başlanır; 10-15 gün ara ile 2. ve 3. ilaçlama yapılabilir.",
                    "Çevreye zararı az, mümkünse seçici ilaçlar kullanılmalıdır.",
                    "Silajlık ve taze tüketim mısırlarda kimyasal mücadele önerilmez.",
                    "BKÜ kontrolü ve uzman onayı zorunludur.",
                ],
                "requires_expert_confirmation": True,
                "requires_bku_check": True,
            },
            "explanation": "TAGEM 2.ürün eşiği: ışık tuzakta 10-15 ergin/hafta + ilk yumurta paketi gözleminde Mısırkurdu mücadelesi başlatılır.",
            "confidence": "high",
            "evidence": [
                {
                    "source_id": "source.tagem.corn_ipm",
                    "page": 28,
                    "section": "6.2. Mısırkurdu — 2.ürün eşiği",
                    "evidence_text": "İkinci ürün mısırlarda, ışık tuzaklarında yakalanan ergin sayısı 10-15 adet/hafta olduğunda ve zararlıya ait ilk yumurta paketleri görüldüğü andan itibaren ilk ilaçlamaya başlanır.",
                }
            ],
        },
        {
            "id": "rule.corn.pest.helicoverpa.silking_threshold",
            "crop_id": "crop.corn",
            "category": "pest_risk",
            "priority": 75,
            "enabled": True,
            "conditions": [
                {"field": "crop_id", "operator": "equals", "value": "crop.corn"},
                {"field": "growth_stage", "operator": "equals", "value": "silking"},
                {"field": "helicoverpa_avg_l1_l3_larvae_per_plant", "operator": "greater_or_equal", "value": 1},
            ],
            "result": {
                "risk_level": "high",
                "possible_problem_id": "pest.corn.helicoverpa_armigera",
                "recommendations": [
                    "İlaçlama yapılmalıdır.",
                    "Larvaların 1.-3. dönemlerinin geçmemesine dikkat edilmelidir.",
                    "Doğal düşman faunası göz önünde bulundurulmalıdır.",
                    "BKÜ kontrolü, doğal düşmanlara yan etkisi en az ürün ve uzman onayı zorunludur.",
                ],
                "requires_expert_confirmation": True,
                "requires_bku_check": True,
            },
            "explanation": "TAGEM eşiği: koçan püskülü döneminde 5x5=25 bitki kontrolünde bitki başına ortalama 1 adet 1.-3. dönem larva tespitinde Yeşilkurt mücadelesi yapılır.",
            "confidence": "high",
            "evidence": [
                {
                    "source_id": "source.tagem.corn_ipm",
                    "page": 46,
                    "section": "7.1.7. Yeşilkurt — Mücadele eşiği",
                    "evidence_text": "Mısır koçan püskülü döneminde tarlanın 5 farklı yerinde aynı sıra üzerinde yanyana 5 bitkinin koçan püskülü üzerinde yapılan larva kontrolünde bitki başına ortalama 1 adet 1.-3. dönem larva belirlendiğinde ilaçlama yapılmalıdır.",
                }
            ],
        },
    ],
    "v2_status": "draft",
    "missing_information": [
        "Mısırda ikincil hastalık/zararlı ve yabancı otların tamamı ayrı v2 profiline açılmadı; mevcut kapsam mısır rastığı, Fusarium kompleksi, koçankurdu, mısırkurdu, yeşilkurt ve kaynaklı su/besleme riskleridir.",
        "test_cases — her rule_engine_rule için pozitif/negatif örnek girdiler eklenecek.",
    ],
}


# ─── AYÇİÇEĞİ (crop.sunflower) ────────────────────────────────────────────
# Kaynak: TAGEM Ayçiçeği Entegre Mücadele Teknik Talimatı, Ankara-2022.

SUNFLOWER_DATA: dict = {
    "stable_id": "crop.sunflower",
    "source_ids": ["source.tagem.sunflower_ipm"],
    "evidence": [
        {
            "source_id": "source.tagem.sunflower_ipm",
            "page": 14,
            "section": "5.3. Yabancı Otların Örnekleme Yöntemleri",
            "evidence_text": "Ülkemizde ayçiçeği tarlalarında ilaçlı mücadele genellikle çıkış sonrası yapılmaktadır. Çıkış sonrası uygulamalarda mücadeleye başlama zamanı ve yabancı ot yoğunluğunu belirlemek amacıyla örneklemeler yapılmalıdır.",
        },
    ],
    "confidence": "medium",
    "diseases_v2": [
        {
            "id": "disease.sunflower.downy_mildew",
            "name_tr": "Ayçiçeği Mildiyösü (Köse Hastalığı)",
            "scientific_name": "Plasmopara halstedii (Farl.) Berl. & De Toni",
            "source_ids": ["source.tagem.sunflower_ipm"],
            "evidence": [
                {
                    "source_id": "source.tagem.sunflower_ipm",
                    "page": 20,
                    "section": "6.3.1. Ayçiçeği Mildiyösü — Tanımı, yaşayışı",
                    "evidence_text": "Hastalık etmeni obligat bir patojen olup toprak, tohum ve hava kaynaklıdır. Bitkilerin bodur kalmasına sebep olduğu için, 'Köse Hastalığı' olarak da bilinmektedir. Etmen, tohumda misel ve oospor, bitki artıklarında ise oospor olarak kışlar. Oosporlar toprakta 5-10 yıl canlılığını sürdürebilir.",
                },
                {
                    "source_id": "source.tagem.sunflower_ipm",
                    "page": 20,
                    "section": "6.3.1. Ayçiçeği Mildiyösü — Epidemiyoloji",
                    "evidence_text": "İlkbaharda 15-20°C sıcaklık ve nemli koşullarda zoosporangiumlar oluşur. Sistemik enfeksiyonlar tohumlar çimlendikten 2-3 hafta sonrasına kadar gerçekleşir. %70-80 nisbi nemde yaprakların altında oluşan fungal örtü (sporangium) yağmur ve rüzgârın etkisiyle dağılarak sekonder enfeksiyonları gerçekleştirirler.",
                },
                {
                    "source_id": "source.tagem.sunflower_ipm",
                    "page": 22,
                    "section": "6.3.1. Ayçiçeği Mildiyösü — Verim kaybı",
                    "evidence_text": "Bitkilerde %100'e varan ürün kaybına neden olabilmektedir. Ülkemizde başta Trakya bölgesi olmak üzere ayçiçeği tarımı yapılan hemen yer yerde bu hastalığa rastlamak mümkündür.",
                },
                {
                    "source_id": "source.tagem.sunflower_ipm",
                    "page": 23,
                    "section": "6.3.2. Ayçiçeği Mildiyösü — Mücadelesi",
                    "evidence_text": "Erken ekimden kaçınılmalı, toprak sıcaklığı 14-15°C ve üzerine ulaştığında ekim yapılmalıdır. Erken dönemde (2-6 yapraklı dönem) tarladaki hastalık oranı %30'un üzerine çıkarsa, böyle tarlaların sahipleri uyarılarak tarlaları, tekrar ekim için sürdürülmelidir.",
                },
            ],
            "requires_bku_check": True,
            "requires_expert_confirmation": True,
            "control_methods_cultural": [
                "Sertifikalı tohum kullanılmalıdır.",
                "Sık ekimden kaçınılmalıdır (dekara ortalama 350-450 g tohum yeterli).",
                "Ağır bulaşık alanlarda buğday ve pancar gibi bitkilerle 7 yıllık ekim nöbeti uygulanmalıdır.",
                "Düzenli yabancı ot savaşımı yapılmalıdır.",
                "Erken ekimden kaçınılmalı; toprak sıcaklığı 14-15°C üzerine ulaştığında ekim yapılmalıdır.",
                "Yüksek tolerant çeşitler tercih edilmelidir.",
                "Hastalıklı bitkiler ve hasat sonrası bitki artıkları sökülüp imha edilmelidir.",
                "2-6 yapraklı dönemde hastalık oranı %30'u aşarsa tarla tekrar sürülerek yenilenmelidir.",
            ],
        },
        {
            "id": "disease.sunflower.charcoal_rot",
            "name_tr": "Kömür Çürüklüğü Hastalığı (Özükuru)",
            "scientific_name": "Macrophomina phaseolina (Tassi) Goid",
            "source_ids": ["source.tagem.sunflower_ipm"],
            "evidence": [
                {
                    "source_id": "source.tagem.sunflower_ipm",
                    "page": 41,
                    "section": "7.2.1. Kömür Çürüklüğü — Tanımı, yaşayışı",
                    "evidence_text": "Macrophomina phaseolina, ayçiçeğinde kömür çürüklüğü hastalığına neden olan, toprak ve tohum kaynaklı fungal bir patojendir. Hastalık etmeni toprakta veya topraktaki bitki artıklarında, özellikle ayçiçeği saplarında mikrosklerot şeklinde kışlar. Fungus toprakta 2-15 yıl canlılığını sürdürebilir.",
                },
                {
                    "source_id": "source.tagem.sunflower_ipm",
                    "page": 41,
                    "section": "7.2.1. Kömür Çürüklüğü — Epidemiyoloji",
                    "evidence_text": "Hastalık toprak sıcaklığı yükseldiğinde ve kurak koşullarda iyi gelişir. Bununla birlikte bitkide meydana gelen su stresi ve açılan yaralar da hastalık şiddetinin artmasına neden olmaktadır.",
                },
                {
                    "source_id": "source.tagem.sunflower_ipm",
                    "page": 42,
                    "section": "7.2.1. Kömür Çürüklüğü — Mücadelesi (Kimyasal mücadele)",
                    "evidence_text": "Bu hastalığa karşı etkili bir kimyasal mücadele yöntemi bulunmamaktadır.",
                },
            ],
            "requires_bku_check": True,
            "requires_expert_confirmation": True,
            "control_methods_cultural": [
                "Hastalıktan ari tohum kullanılmalıdır.",
                "Hastalığın görüldüğü tarlalarda 2-3 yıl konukçusu olmayan bitkilerle münavebe yapılmalıdır.",
                "Tolerant çeşitler tercih edilmelidir.",
                "Özellikle sıcak aylarda bitkileri su stresine sokmayacak şekilde düzenli sulama yapılmalıdır.",
                "Hastalıklı bitki artıkları ortamdan uzaklaştırılmalıdır.",
                "Derin sürüm yapılarak mikrosklerotlar toprağa gömülmelidir.",
            ],
        },
        {
            "id": "disease.sunflower.phoma_black_stem",
            "name_tr": "Siyah Gövde Lekesi",
            "scientific_name": "Phoma macdonaldii Boerema",
            "source_ids": ["source.tagem.sunflower_ipm"],
            "evidence": [
                {
                    "source_id": "source.tagem.sunflower_ipm",
                    "page": 43,
                    "section": "7.2.2. Siyah Gövde Lekesi — Epidemiyoloji",
                    "evidence_text": "Hastalığın gelişmesi ve yayılmasında sıcaklık, nem ve yağış önemli faktörlerdir. Hastalık 20-30°C sıcaklık ve yüksek nemde hızlı gelişir. Çiçeklenme sonrasındaki yağışlar enfeksiyon şiddetini arttırır.",
                },
                {
                    "source_id": "source.tagem.sunflower_ipm",
                    "page": 43,
                    "section": "7.2.2. Siyah Gövde Lekesi — Verim kaybı",
                    "evidence_text": "Ayçiçeğinde siyah gövde lekesi hastalığı %10-30 oranında verim kaybına sebep olabilmektedir.",
                },
            ],
            "requires_bku_check": True,
            "requires_expert_confirmation": True,
            "control_methods_cultural": [
                "Hastalıktan ari kaliteli tohumluk kullanılmalıdır.",
                "Tolerant çeşitler tercih edilmelidir.",
                "Sık ekimden kaçınılmalıdır.",
                "2-3 yıllık ekim nöbeti yapılmalıdır.",
                "Hastalıklı bitki artıkları toplanmalı ve imha edilmelidir.",
                "Bitkilerin gövdesinde yara açılmasından kaçınılmalıdır.",
            ],
        },
        {
            "id": "disease.sunflower.rust",
            "name_tr": "Ayçiçeği Pası",
            "scientific_name": "Puccinia helianthii Schw.",
            "source_ids": ["source.tagem.sunflower_ipm"],
            "evidence": [
                {
                    "source_id": "source.tagem.sunflower_ipm",
                    "page": 44,
                    "section": "7.2.3. Ayçiçeği Pası — Epidemiyoloji",
                    "evidence_text": "Yağışlar veya çiy nedeniyle yaprak üzerinde oluşan nisbi nem ve 13-30°C arasında seyreden hava sıcaklıkları enfeksiyon için elverişli koşullardır. Enfeksiyon oluşumu için yaprağın minimum 2 saat süreyle ıslak kalması gereklidir. Hastalık için elverişli koşullarda üredial aşama 10-14 günde bir tekrarlanır.",
                },
                {
                    "source_id": "source.tagem.sunflower_ipm",
                    "page": 44,
                    "section": "7.2.3. Ayçiçeği Pası — Risk faktörü",
                    "evidence_text": "Geç dönemde ekilen duyarlı çeşitler genellikle erken ekime oranla hastalıktan daha çok etkilenir. Yağlık çeşitler genellikle yaygın pas ırklarına karşı çerezlik çeşitlere oranla daha iyi direnç göstermektedir.",
                },
            ],
            "requires_bku_check": True,
            "requires_expert_confirmation": True,
            "control_methods_cultural": [
                "Hastalığa tolerant çeşitler ekilmelidir.",
                "Geç dönem enfeksiyonları önlemek için erken ekim yapılmalıdır.",
                "Tarlada görülen hastalıklı bitkiler ve hasat sonrası bitki artıkları tarladan uzaklaştırılarak imha edilmelidir.",
                "Yabani ayçiçeği türleriyle ve Asteraceae familyasına ait yabancı otlarla mücadele edilmelidir.",
                "Aşırı azotlu gübrelemeden ve sık ekimden kaçınılmalıdır.",
                "Hastalığın görüldüğü alanlarda 3 yıllık ekim nöbeti uygulanmalıdır.",
            ],
        },
    ],
    "pests_v2": [
        {
            "id": "pest.sunflower.agrotis",
            "name_tr": "Bozkurt (Ayçiçeğinde)",
            "scientific_name": "Agrotis ipsilon (Hufn.), Agrotis segetum (Schiff.) (Lepidoptera: Noctuidae)",
            "source_ids": ["source.tagem.sunflower_ipm"],
            "evidence": [
                {
                    "source_id": "source.tagem.sunflower_ipm",
                    "page": 16,
                    "section": "6.1. Bozkurt — Zarar şekli",
                    "evidence_text": "Sonraki dönemlerde, sadece geceleri toprak yüzüne çıkarak genç körpe bitkileri kök boğazından kesmek veya kemirmek suretiyle bitkinin kırılıp, kurumasına neden olurlar. Popülâsyonun yüksek olduğu yıllarda ekimin yenilenmesini gerektirecek kadar zararlı olabilirler.",
                },
                {
                    "source_id": "source.tagem.sunflower_ipm",
                    "page": 17,
                    "section": "6.1.3. Bozkurt — Mücadele eşiği",
                    "evidence_text": "Ayçiçeği çıkışından sonra 2-4 yapraklı olduğu dönemde, bitkilerin bozkurt larvası tarafından kesilip, kesilmediği saptanmalı ve 3 metrelik sıra üzerinde en az iki kesik bitkiye rastlandığında veya m²'de toprakta en az bir larva bulunduğunda ilaçlamaya geçilmelidir.",
                },
            ],
            "control_methods_cultural": [
                "Sonbaharda ayçiçeği tarlalarının sürülmesi kışlayan bozkurtların ölümüne neden olur.",
                "İlkbaharın başından itibaren tarlalarda yabancı ot mücadelesi yapılmalıdır (yabancı otlar bozkurtların yumurta bırakacağı konukçudur).",
            ],
        },
        {
            "id": "pest.sunflower.helicoverpa_armigera",
            "name_tr": "Yeşilkurt (Ayçiçeğinde)",
            "scientific_name": "Helicoverpa armigera (Hbn.) (Lepidoptera: Noctuidae)",
            "source_ids": ["source.tagem.sunflower_ipm"],
            "evidence": [
                {
                    "source_id": "source.tagem.sunflower_ipm",
                    "page": 18,
                    "section": "6.2.1. Yeşilkurt — Bölgesel döl",
                    "evidence_text": "Ege Bölgesi'nde yılda 3-5, Akdeniz Bölgesi'nde ise 5 döl vermektedir.",
                },
                {
                    "source_id": "source.tagem.sunflower_ipm",
                    "page": 20,
                    "section": "6.2.3. Yeşilkurt — İlaçlama zamanı",
                    "evidence_text": "Mücadele zamanının ve ilk ergin çıkışının belirlenebilmesi için, nisan sonu-mayıs başından itibaren 2 adet feromon tuzak/ha alana yerleştirilmelidir. İlk ergin görüldükten 5-10 gün sonra, 100 bitki kontrol edilerek yumurtadan çıkan larva yoğunluğu belirlenir. Kontroller sonucunda, 100 bitkinin 5'inde birinci dönem larva ya da ilk zarar belirtileri görüldüğünde kimyasal mücadeleye karar verilir.",
                },
            ],
            "control_methods_cultural": [
                "Baharda toprak iyi bir şekilde işlenerek kışlayan pupalar yok edilmeye çalışılmalıdır.",
                "Apanteles sp. doğal düşmanı korunmalı (Çukurova'da %60 etkinlik sağlayabilir).",
            ],
        },
    ],
    "weeds_v2": [
        {
            "id": "weed.sunflower.orobanche",
            "name_tr": "Canavar Otu Türleri",
            "scientific_name": "Orobanche cumana Wallr., Orobanche cernua Loefl.",
            "source_ids": ["source.tagem.sunflower_ipm"],
            "evidence": [
                {
                    "source_id": "source.tagem.sunflower_ipm",
                    "page": 26,
                    "section": "6.6.1. Canavar Otu — Tanımı",
                    "evidence_text": "Canavar otları emeçleriyle ayçiçeği bitkisinin köklerine tutunarak ihtiyacı olan su ve besin maddelerini almakta ve böylece ayçiçeğini zayıflatarak veriminin düşmesine neden olmaktadır. Ayçiçeği alanlarında en fazla sorun oluşturan canavar otu türleri Orobanche cernua Loefl. ve Orobanche cumana Wallr.'dır.",
                },
                {
                    "source_id": "source.tagem.sunflower_ipm",
                    "page": 28,
                    "section": "6.6.3. Canavar Otu — Mekanik mücadele",
                    "evidence_text": "Toprak bir kereliğine 45-50 cm derinliğinde sürüldüğü takdirde canavar otu bulaşıklığı %80-90 oranında azalmaktadır.",
                },
                {
                    "source_id": "source.tagem.sunflower_ipm",
                    "page": 28,
                    "section": "6.6.3. Canavar Otu — Kimyasal mücadele",
                    "evidence_text": "Ülkemizde canavar otuna karşı kimyasal mücadele yalnızca IMI (Imidazolinone grubu herbisitler (Clearfield®)) toleranslı ayçiçeği çeşitlerinde ruhsatlı herbisitlerle yapılmaktadır. Bu herbisitlerin, ayçiçeğinin 4-8 gerçek yapraklı olduğu dönemde çıkış sonrası olarak uygulaması tavsiye edilmektedir.",
                },
            ],
            "control_methods_cultural": [
                "Temiz tohumluk kullanılmalıdır.",
                "Münavebe uygulanmalıdır.",
                "İyi yanmış çiftlik gübresi kullanılmalıdır.",
                "Tarım alet ve makinaları ile canavarotu tohumlarını ve parçalarını bulaşık tarlalardan temiz tarlalara bulaştırmamaya dikkat edilmelidir.",
                "Canavarotuna karşı yüksek tolerant çeşitler kullanılmalıdır.",
                "Elle çekme küçük tarlalarda destek mücadele olarak uygulanır.",
                "Derin sürüm 45-50 cm yapılırsa bulaşıklık %80-90 azalır.",
            ],
        },
    ],
    "rule_engine_rules": [
        {
            "id": "rule.sunflower.disease.downy_mildew.cool_humid_seedling",
            "crop_id": "crop.sunflower",
            "category": "disease_risk",
            "priority": 95,
            "enabled": True,
            "conditions": [
                {"field": "crop_id", "operator": "equals", "value": "crop.sunflower"},
                {"field": "growth_stage", "operator": "in", "value": ["seedling", "two_to_six_leaves"]},
                {"field": "average_temperature_c", "operator": "between", "value": [15, 20]},
                {"field": "relative_humidity_percent", "operator": "greater_or_equal", "value": 70},
            ],
            "result": {
                "risk_level": "high",
                "possible_problem_id": "disease.sunflower.downy_mildew",
                "recommendations": [
                    "Yaprak alt yüzünde beyaz fungal örtü (sporangium) ve damar boyu klorozu kontrol edin; bodur/rozetleşmiş bitkilere dikkat edin.",
                    "Sertifikalı tohum kullanın; toprak sıcaklığı 14-15°C üzerine çıkmadan ekim yapmayın.",
                    "2-6 yapraklı dönemde hastalık oranı %30'u aşarsa tarla tekrar sürülerek yenilenmelidir.",
                    "Ağır bulaşık alanlarda buğday/pancar ile 7 yıllık ekim nöbeti uygulayın.",
                    "Tohum ilaçlaması gerekiyorsa BKÜ veritabanında güncel ruhsatlı ürün kontrolü yapın.",
                ],
                "requires_expert_confirmation": True,
                "requires_bku_check": True,
            },
            "explanation": "Plasmopara halstedii ilkbaharda 15-20°C ve %70-80 nisbi nemde sistemik enfeksiyon yapar; sistemik enfeksiyonlar çimlenmeden 2-3 hafta sonrasına kadar gerçekleşir.",
            "confidence": "high",
            "evidence": [
                {
                    "source_id": "source.tagem.sunflower_ipm",
                    "page": 20,
                    "section": "6.3.1. Ayçiçeği Mildiyösü",
                    "evidence_text": "İlkbaharda 15-20°C sıcaklık ve nemli koşullarda zoosporangiumlar oluşur. %70-80 nisbi nemde yaprakların altında oluşan fungal örtü (sporangium) yağmur ve rüzgârın etkisiyle dağılarak sekonder enfeksiyonları gerçekleştirirler.",
                }
            ],
        },
        {
            "id": "rule.sunflower.disease.charcoal_rot.hot_dry_water_stress",
            "crop_id": "crop.sunflower",
            "category": "disease_risk",
            "priority": 85,
            "enabled": True,
            "conditions": [
                {"field": "crop_id", "operator": "equals", "value": "crop.sunflower"},
                {"field": "soil_temperature_level", "operator": "equals", "value": "high"},
                {"field": "climate_condition", "operator": "in", "value": ["dry_hot", "drought_stress"]},
            ],
            "result": {
                "risk_level": "high",
                "possible_problem_id": "disease.sunflower.charcoal_rot",
                "recommendations": [
                    "Kök boğazı ve gövdede kahverengi-siyah lezyonları ve gövde içinde mikrosklerotları kontrol edin.",
                    "Sıcak aylarda bitkileri su stresine sokmayacak şekilde düzenli sulama yapın.",
                    "Hastalığa karşı etkili kimyasal mücadele yoktur — kültürel önlemler tek seçenektir.",
                    "Bulaşık tarlalarda 2-3 yıl konukçusu olmayan bitkilerle münavebe uygulayın.",
                    "Derin sürüm ile mikrosklerotları toprağa gömün.",
                ],
                "requires_expert_confirmation": True,
                "requires_bku_check": False,
            },
            "explanation": "Macrophomina phaseolina yüksek toprak sıcaklığı + kurak koşullarda iyi gelişir; su stresi ve yara hastalık şiddetini artırır. Mikrosklerotlar 2-15 yıl toprakta canlı kalır.",
            "confidence": "high",
            "evidence": [
                {
                    "source_id": "source.tagem.sunflower_ipm",
                    "page": 41,
                    "section": "7.2.1. Kömür Çürüklüğü",
                    "evidence_text": "Hastalık toprak sıcaklığı yükseldiğinde ve kurak koşullarda iyi gelişir. Bununla birlikte bitkide meydana gelen su stresi ve açılan yaralar da hastalık şiddetinin artmasına neden olmaktadır.",
                }
            ],
        },
        {
            "id": "rule.sunflower.disease.phoma_black_stem.warm_humid_post_flower",
            "crop_id": "crop.sunflower",
            "category": "disease_risk",
            "priority": 75,
            "enabled": True,
            "conditions": [
                {"field": "crop_id", "operator": "equals", "value": "crop.sunflower"},
                {"field": "growth_stage", "operator": "in", "value": ["flowering", "post_flowering"]},
                {"field": "average_temperature_c", "operator": "between", "value": [20, 30]},
                {"field": "relative_humidity_level", "operator": "equals", "value": "high"},
            ],
            "result": {
                "risk_level": "medium",
                "possible_problem_id": "disease.sunflower.phoma_black_stem",
                "recommendations": [
                    "Gövdede 4-5 cm uzunluğunda oval siyah lekeleri ve yaprak-gövde birleşim noktalarını kontrol edin.",
                    "Tolerant çeşit ve sertifikalı tohum kullanın; sık ekimden kaçının.",
                    "2-3 yıllık ekim nöbeti uygulayın.",
                    "Bitki gövdesinde yara açılmasından kaçının.",
                    "Kimyasal mücadele gerekiyorsa BKÜ kontrolü ve uzman onayı zorunludur.",
                ],
                "requires_expert_confirmation": True,
                "requires_bku_check": True,
            },
            "explanation": "Phoma macdonaldii 20-30°C + yüksek nemde hızlı gelişir; çiçeklenme sonrası yağışlar enfeksiyon şiddetini artırır.",
            "confidence": "high",
            "evidence": [
                {
                    "source_id": "source.tagem.sunflower_ipm",
                    "page": 43,
                    "section": "7.2.2. Siyah Gövde Lekesi",
                    "evidence_text": "Hastalık 20-30°C sıcaklık ve yüksek nemde hızlı gelişir. Çiçeklenme sonrasındaki yağışlar enfeksiyon şiddetini arttırır.",
                }
            ],
        },
        {
            "id": "rule.sunflower.disease.rust.leaf_wetness",
            "crop_id": "crop.sunflower",
            "category": "disease_risk",
            "priority": 80,
            "enabled": True,
            "conditions": [
                {"field": "crop_id", "operator": "equals", "value": "crop.sunflower"},
                {"field": "average_temperature_c", "operator": "between", "value": [13, 30]},
                {"field": "leaf_wetness_hours", "operator": "greater_or_equal", "value": 2},
            ],
            "result": {
                "risk_level": "medium",
                "possible_problem_id": "disease.sunflower.rust",
                "recommendations": [
                    "Yaprakların alt yüzünde tarçın renkli üredi püstüllerini ve etrafındaki klorotik haleleri kontrol edin.",
                    "Tolerant çeşit kullanın; geç ekimden kaçınarak erken ekim yapın.",
                    "Asteraceae yabancı otları ve yabani ayçiçeği türleri ile mücadele edin.",
                    "Aşırı azotlu gübrelemeden ve sık ekimden kaçının.",
                    "Kimyasal mücadele gerekiyorsa BKÜ kontrolü zorunludur.",
                ],
                "requires_expert_confirmation": True,
                "requires_bku_check": True,
            },
            "explanation": "Puccinia helianthii enfeksiyonu için 13-30°C ve yaprak ıslaklığının en az 2 saat sürmesi gerekir; uygun koşullarda üredial aşama 10-14 günde tekrar üretir.",
            "confidence": "high",
            "evidence": [
                {
                    "source_id": "source.tagem.sunflower_ipm",
                    "page": 44,
                    "section": "7.2.3. Ayçiçeği Pası",
                    "evidence_text": "13-30°C arasında seyreden hava sıcaklıkları enfeksiyon için elverişli koşullardır. Enfeksiyon oluşumu için yaprağın minimum 2 saat süreyle ıslak kalması gereklidir.",
                }
            ],
        },
        {
            "id": "rule.sunflower.pest.agrotis.cut_plant_threshold",
            "crop_id": "crop.sunflower",
            "category": "pest_risk",
            "priority": 95,
            "enabled": True,
            "conditions": [
                {"field": "crop_id", "operator": "equals", "value": "crop.sunflower"},
                {"field": "growth_stage", "operator": "equals", "value": "two_to_four_leaves"},
                {"field": "agrotis_cut_plants_per_3m_row", "operator": "greater_or_equal", "value": 2},
            ],
            "result": {
                "risk_level": "high",
                "possible_problem_id": "pest.sunflower.agrotis",
                "recommendations": [
                    "İlaçlamaya geçilmelidir.",
                    "Akşamüzeri zehirli yem (10 kg kepek + ilaç + 500 g şeker/pekmez, 5-6 kg/dekar) toprak tavlı iken bitki köklerine yakın yerlere serpilebilir.",
                    "Yabancı ot mücadelesi yapın (alternatif konukçu).",
                    "Sonbahar sürümü kışlayan bozkurtları öldürür.",
                    "BKÜ kontrolü, etiket dozu ve uzman onayı zorunludur.",
                ],
                "requires_expert_confirmation": True,
                "requires_bku_check": True,
            },
            "explanation": "TAGEM eşiği: ayçiçeği 2-4 yapraklı dönemde 3 metrelik sıra üzerinde en az 2 kesik bitki tespitinde Bozkurt mücadelesine karar verilir.",
            "confidence": "high",
            "evidence": [
                {
                    "source_id": "source.tagem.sunflower_ipm",
                    "page": 17,
                    "section": "6.1.3. Bozkurt — Mücadele eşiği",
                    "evidence_text": "Ayçiçeği çıkışından sonra 2-4 yapraklı olduğu dönemde, bitkilerin bozkurt larvası tarafından kesilip, kesilmediği saptanmalı ve 3 metrelik sıra üzerinde en az iki kesik bitkiye rastlandığında veya m²'de toprakta en az bir larva bulunduğunda ilaçlamaya geçilmelidir.",
                }
            ],
        },
        {
            "id": "rule.sunflower.pest.helicoverpa.larva_threshold_5pct",
            "crop_id": "crop.sunflower",
            "category": "pest_risk",
            "priority": 90,
            "enabled": True,
            "conditions": [
                {"field": "crop_id", "operator": "equals", "value": "crop.sunflower"},
                {"field": "helicoverpa_l1_larvae_per_100_plants", "operator": "greater_or_equal", "value": 5},
            ],
            "result": {
                "risk_level": "high",
                "possible_problem_id": "pest.sunflower.helicoverpa_armigera",
                "recommendations": [
                    "Kimyasal mücadeleye karar verilir.",
                    "İlk ergin görüldükten 5-10 gün sonra 100 bitki kontrolü ile larva yoğunluğu doğrulanmalıdır.",
                    "Feromon tuzak (2 adet/ha) ile uçuş takibi sürdürün.",
                    "Apanteles sp. doğal düşmanını koruyun (Çukurova'da %60'a kadar etkinlik).",
                    "BKÜ kontrolü, doğal düşmanlara yan etkisi en az ürün ve uzman onayı zorunludur.",
                ],
                "requires_expert_confirmation": True,
                "requires_bku_check": True,
            },
            "explanation": "TAGEM eşiği: 100 bitkinin 5'inde 1.dönem larva veya ilk zarar belirtileri görüldüğünde Yeşilkurt mücadelesine karar verilir.",
            "confidence": "high",
            "evidence": [
                {
                    "source_id": "source.tagem.sunflower_ipm",
                    "page": 20,
                    "section": "6.2.3. Yeşilkurt — İlaçlama zamanı",
                    "evidence_text": "Kontroller sonucunda, 100 bitkinin 5'inde birinci dönem larva ya da ilk zarar belirtileri görüldüğünde kimyasal mücadeleye karar verilir.",
                }
            ],
        },
        {
            "id": "rule.sunflower.weed.orobanche.deep_plowing_recommendation",
            "crop_id": "crop.sunflower",
            "category": "weed_management",
            "priority": 70,
            "enabled": True,
            "conditions": [
                {"field": "crop_id", "operator": "equals", "value": "crop.sunflower"},
                {"field": "field_orobanche_history", "operator": "equals", "value": True},
            ],
            "result": {
                "risk_level": "medium",
                "possible_problem_id": "weed.sunflower.orobanche",
                "recommendations": [
                    "Toprağı bir kereliğine 45-50 cm derinliğinde sürerek canavar otu tohumlarını derine gömün — bulaşıklık %80-90 azalır.",
                    "IMI/Clearfield toleranslı çeşit ekiyorsanız 4-8 gerçek yapraklı dönemde ruhsatlı herbisit uygulanabilir; etiket bilgilerine kesin uyulmalıdır.",
                    "Münavebe uygulanmalı; bulaşık alet/makinaları temiz tarlalara taşımamaya özen gösterin.",
                    "Yüksek tolerant çeşit ve iyi yanmış çiftlik gübresi kullanın.",
                    "Kimyasal mücadele için BKÜ veritabanında güncel ruhsatlı ürün kontrolü zorunludur.",
                ],
                "requires_expert_confirmation": True,
                "requires_bku_check": True,
            },
            "explanation": "Bulaşık alanlarda derin sürüm + tolerant çeşit + IMI ruhsatlı herbisit (yalnızca Clearfield çeşitlerde, 4-8 gerçek yapraklı dönemde) tek etkili kombinasyondur.",
            "confidence": "high",
            "evidence": [
                {
                    "source_id": "source.tagem.sunflower_ipm",
                    "page": 28,
                    "section": "6.6.3. Canavar Otu — Mekanik mücadele",
                    "evidence_text": "Toprak bir kereliğine 45-50 cm derinliğinde sürüldüğü takdirde canavar otu bulaşıklığı %80-90 oranında azalmaktadır.",
                }
            ],
        },
    ],
    "v2_status": "draft",
    "missing_information": [
        "Ayçiçeğinde ikincil zararlı ve yabancı otların tamamı ayrı v2 profiline açılmadı; mevcut kapsam ana hastalıklar, bozkurt/yeşilkurt, canavar otu ve kaynaklı bor/sulama riskleridir.",
        "test_cases — her rule_engine_rule için pozitif/negatif örnek girdiler eklenecek.",
    ],
}


# ─── PORTAKAL / TURUNÇGİL (crop.orange) ───────────────────────────────────
# Kaynak: TAGEM Turunçgil Entegre Mücadele Teknik Talimatı.
# Talimat tüm turunçgilleri (portakal/mandalina/limon/altıntop) kapsar; bu
# kayıtlar crop.orange için yazılmıştır.

ORANGE_DATA: dict = {
    "stable_id": "crop.orange",
    "source_ids": ["source.tagem.citrus_ipm"],
    "evidence": [
        {
            "source_id": "source.tagem.citrus_ipm",
            "page": 14,
            "section": "1.16. Bitki besin elementleri ile ilgili örnekleme",
            "evidence_text": "Yaprak örneklemesi yapılırken (haziran-eylül-ekim) meyvesiz sürgünün uçtan itibaren 2-4. yaprakları toplanır. Bir örnek, 20 da alanı temsil edecek şekilde 100 yaprak veya 50 g yaş ağırlıktaki yapraktan oluşmalıdır. Toprak örneklemesi yapılırken de bahçenin 8-10 farklı noktasından 0-30 cm derinlikten alınacak toprakların karıştırılmasıyla bir örnek oluşturulur.",
        },
    ],
    "confidence": "medium",
    "diseases_v2": [
        {
            "id": "disease.orange.mal_secco",
            "name_tr": "Uçkurutan",
            "scientific_name": "Phoma tracheiphila (Petri) L.A. Kantsch.-Gik.",
            "source_ids": ["source.tagem.citrus_ipm"],
            "evidence": [
                {
                    "source_id": "source.tagem.citrus_ipm",
                    "page": 66,
                    "section": "1.40. Uçkurutan — Tanımı, yaşayışı",
                    "evidence_text": "Hastalık etmeni kışı bulaşık sürgünlerin kabukları altında piknit şeklinde geçirir. İlkbaharda yağmurlu ve rüzgarlı havalarda yayılan konidiosporlar, stoma ve dallardaki yaralardan bitkiye girerek enfeksiyon yapar. 3°C'nin altında, 30°C'nin üzerinde aktivitesini yitirir. 35°C'de 5 günde, sporlar çimlenme yeteneklerini kaybederler.",
                },
                {
                    "source_id": "source.tagem.citrus_ipm",
                    "page": 66,
                    "section": "1.40. Uçkurutan — Enfeksiyon dönemi",
                    "evidence_text": "Uçkurutan hastalığının enfeksiyonları ekim-mart aylarında gerçekleşir. En fazla bulaşma ekim ayındadır. Belirtiler, enfeksiyondan 1-1,5 ay sonra görülür. Hastalık Akdeniz bölgesinde yaygın olup Ege bölgesinde de bulunmaktadır. Hastalığın konukçusu turunçgil olup limon en hassas türdür.",
                },
                {
                    "source_id": "source.tagem.citrus_ipm",
                    "page": 67,
                    "section": "1.40. Uçkurutan — Yeşil aksam ilaçlama",
                    "evidence_text": "Yeşil aksam ilaçlamaları: Ekim, aralık ve mart aylarında olmak üzere 3 kez yapılmalıdır. Toprak ilaçlamaları: Yeşil aksam ilaçlamasının yanı sıra bahçedeki ağır enfekteli ağaçlara, ekim ayında bir defa olmak üzere toprak ilaçlaması yapılmalıdır.",
                },
            ],
            "requires_bku_check": True,
            "requires_expert_confirmation": True,
            "control_methods_cultural": [
                "Bahçeye dikilecek fidanlar hastalıktan ari ve sertifikalı olmalıdır.",
                "Hastalıkla bulaşık bahçelerden üretim materyali alınmamalıdır.",
                "Hastalıklı sürgünler hastalıklı yerin yaklaşık 20 cm altından budanıp imha edilmelidir.",
                "Yara yerlerine aşı macunu sürülmeli; budama aletleri her kesimden sonra %10'luk sodyum hipoklorit çözeltisi ile dezenfekte edilmelidir.",
                "Don, dolu ve fırtına sonrası ağaçlar ilaçlanmalıdır (etmen yaralardan giriş yapar).",
            ],
        },
        {
            "id": "disease.orange.brown_rot",
            "name_tr": "Turunçgil meyvelerinde kahverengi çürüklük ve gövde zamklanması",
            "scientific_name": "Phytophthora citrophthora (Smith and Smith) Leonian",
            "source_ids": ["source.tagem.citrus_ipm"],
            "evidence": [
                {
                    "source_id": "source.tagem.citrus_ipm",
                    "page": 67,
                    "section": "1.41. Phytophthora — Tanımı, epidemiyoloji",
                    "evidence_text": "Hastalık etmeni toprak kökenli bir fungustur. Meyve enfeksiyonları ağaçların alt dallarındaki meyvelere, yağmurla sıçrayan zoosporlar tarafından gerçekleştirilir. Etmen, 5-32°C'de gelişebilmekte ve 24-28°C sıcaklıklarda optimum gelişme göstermektedir.",
                },
                {
                    "source_id": "source.tagem.citrus_ipm",
                    "page": 67,
                    "section": "1.41. Phytophthora — Belirtiler ve risk",
                    "evidence_text": "Hastanan meyvelerde kahverengi lekeler oluşur ve meyve zamanla derimsi bir görünüm kazanır. Etmenin gövde ve kalın dallarında gelişen enfeksiyonlar daha çok aşı yerinin üzerinde, gövde kabuğunda zamk akıntısı oluşturan büyük yaralar meydana getirir. Özellikle genç limon ağaçlarında Phytophthora hastalığının meydana getirdiği yara gövdeyi tamamen sararsa ağacın ölümüne neden olur.",
                },
            ],
            "requires_bku_check": True,
            "requires_expert_confirmation": True,
            "control_methods_cultural": [
                "Taban suyunun yüksek olduğu arazilerde turunçgil bahçesi tesis edilmemelidir; toprak drenajı yapılmalıdır.",
                "Fidanlar derin dikilmemeli, aşı yerleri toprak üstünden en az 20 cm yukarıda bırakılmalıdır.",
                "Özellikle limonlarda meyve enfeksiyonlarını önlemek için hasat sonbaharda yağmurlardan önce tamamlanmalıdır.",
                "Salma sulama yerine damla sulama tercih edilmeli, suyun kök boğazına değmesi engellenmelidir.",
                "Yara yerleri oluşursa aşı macunu ile kapatılmalıdır.",
                "Kök boğazı enfeksiyonlarında ilkbaharda kök boğazı açılarak güneşlendirilmeli ve havalandırılmalıdır.",
            ],
        },
    ],
    "pests_v2": [
        {
            "id": "pest.orange.planococcus_citri",
            "name_tr": "Turunçgil Unlubiti",
            "scientific_name": "Planococcus citri (Risso) (Hemiptera: Pseudococcidae)",
            "source_ids": ["source.tagem.citrus_ipm"],
            "evidence": [
                {
                    "source_id": "source.tagem.citrus_ipm",
                    "page": 14,
                    "section": "1.18. Turunçgil unlubiti — Biyoloji",
                    "evidence_text": "26±1°C sıcaklık ve %60-65 orantılı nemde ayda bir döl verir. Akdeniz Bölgesi turunçgil alanlarında yılda 4-5 döl vermektedir. Orantılı nemi yüksek, gölgeli ve sıcak yerler gelişmesi için en uygun alanlardır.",
                },
                {
                    "source_id": "source.tagem.citrus_ipm",
                    "page": 19,
                    "section": "1.18. Turunçgil unlubiti — Biyolojik mücadele eşikleri",
                    "evidence_text": "Mayıs ayı sonuna kadar %5 ağaç, haziran ayı sonuna kadar ise %8 ağaç veya meyve bulaşıklığı saptanırsa ağaç başına 2-3 adet C. montrouzieri ile 10 adet L. dactylopii salınması gerekir. Ağustos ayında gerek ağaç ve gerekse meyve bulaşıklığı %15 olursa ağaç başına 4-5 adet predatör ile 10 adet parazitoid verilir. Eylül ayında %20 ağaç ve meyve bulaşıklığı bulunan bahçeye iklim durumuna göre kasım sonuna kadar ağaç başına 10 adet predatör ve 20 adet parazitoid salımına devam edilir.",
                },
                {
                    "source_id": "source.tagem.citrus_ipm",
                    "page": 19,
                    "section": "1.18. Turunçgil unlubiti — Kimyasal mücadele",
                    "evidence_text": "Mayıs-temmuz aylarında %5 ağaç veya %10 meyve bulaşıklığı, temmuz-eylül ayları arasında ise %15-20 meyve bulaşıklığı saptandığında ilaçlamaya karar verilir.",
                },
            ],
            "control_methods_cultural": [
                "Bahçe temizliğine dikkat edilmeli; ilkbaharda çıkışlardan önce toprak işlemesi yapılmalıdır.",
                "Ağaç taçları birbirine temas etmemelidir; tekniğine uygun budama yapılmalıdır.",
                "Bahçedeki semizotu, sirken gibi konukçu yabancı otlarla ilkbahar mücadelesi yapılmalıdır.",
                "Karınca faaliyetinin olduğu bahçelerde gövdeye yapışkan madde sürülerek karıncalar engellenmelidir.",
                "Cryptolaemus montrouzieri ve Leptomastix dactylopii faydalıları korunmalı / salınmalıdır.",
            ],
        },
        {
            "id": "pest.orange.aonidiella_aurantii",
            "name_tr": "Turunçgil Kırmızı ve Sarı Kabuklubiti",
            "scientific_name": "Aonidiella aurantii (Mask.), Aonidiella citrina (Coq.) (Hemiptera: Diaspididae)",
            "source_ids": ["source.tagem.citrus_ipm"],
            "evidence": [
                {
                    "source_id": "source.tagem.citrus_ipm",
                    "page": 20,
                    "section": "1.19. Aonidiella spp. — Biyoloji",
                    "evidence_text": "Bir dişinin karnında açılan yumurtalardan 30-150 adet hareketli nimf çıkabilir. Bölgelere göre yılda 3-5 döl verebilirler. Doğu Akdeniz bölgesinde hakim tür Kırmızı kabuklubit, diğer bölgelerimizde ise Sarı kabuklubit'tir. Meyve, yaprak ve sürgünleri sokup emmek suretiyle kalite ve kantite kaybına neden olurlar.",
                },
            ],
            "control_methods_cultural": [
                "Bahçe içi havalandırma için tekniğine uygun budama.",
                "Aphytis melinus, Comperiella bifasciata gibi parazitoit doğal düşmanları korunmalıdır.",
                "Yazlık yağ uygulaması (kükürtlü preparat ile en az 1 ay arayla) düşük popülasyonlarda etkilidir.",
            ],
        },
        {
            "id": "pest.orange.ceratitis_capitata",
            "name_tr": "Akdeniz Meyvesineği",
            "scientific_name": "Ceratitis capitata Wied. (Diptera: Tephritidae)",
            "source_ids": ["source.tagem.citrus_ipm"],
            "evidence": [
                {
                    "source_id": "source.tagem.citrus_ipm",
                    "page": 23,
                    "section": "1.20. Akdeniz meyvesineği — Biyoloji",
                    "evidence_text": "Hava sıcaklıkları gün içerisinde 16°C ve üzerinde seyrettiğinde özellikle erkenci olan, olgunlaşma dönemine gelen, meyve kabuğundaki asitlik oranı larva gelişimi için uygun olan meyvelerde zarar yapmaya başlar. Dişilerin bıraktığı yumurtaların açılıp larvaların gelişebilmesi için sıcaklığı 16°C ve üzerinde olması gerekir.",
                },
                {
                    "source_id": "source.tagem.citrus_ipm",
                    "page": 24,
                    "section": "1.20. Akdeniz meyvesineği — Bölgesel döl ve yaygınlık",
                    "evidence_text": "Bu zararlı, Ege Bölgesi'nde yılda 6-8, Akdeniz Bölgesi'nde ise 10-12 döl verebilir. Erginler konukçunun bol bulunduğu ortamlarda 20-50 m uçar, besinin az olması durumunda ise 500-700 m uçabilir.",
                },
                {
                    "source_id": "source.tagem.citrus_ipm",
                    "page": 25,
                    "section": "1.20. Akdeniz meyvesineği — Verim kaybı ve karantina",
                    "evidence_text": "Karantina zararlısı olduğu için ihraç edilen turunçgil çeşitlerindeki zararı ülke ekonomisi yönünden çok önemlidir. Toleransı sıfır olduğundan, bu tür meyvelerin vuruklu ve bulaşık olması ihracaatımızı olumsuz yönde etkilenmektedir. Zarar oranı bölgelere göre %5-80 arasında değişmektedir.",
                },
                {
                    "source_id": "source.tagem.citrus_ipm",
                    "page": 26,
                    "section": "1.20. Akdeniz meyvesineği — Biyoteknik mücadele",
                    "evidence_text": "Akdeniz meyvesineği'ne karşı içerisinde cezbedici besin veya para-feromon bulunan değişik şekil ve boyutlarda yapılmış ruhsatlı tuzaklar, zararlının kitle halinde yakalanmasını sağlamak amacıyla kullanılmaktadır. Tuzaklar, meyvelerin vurma olgunluğuna gelmesinden bir ay önce firması tarafından önerilen dozda bahçeye asılır. Tuzaklar ağaçların güney, güney doğu yönüne, yerden 1.5-2 m yüksekliğe asılmalıdır.",
                },
            ],
            "control_methods_cultural": [
                "Yeni tesis edilecek bahçelerde zararlının konukçusu farklı meyve türleri ile karışık bahçe kurulmamalıdır.",
                "Bulaşık meyveler toplanıp kalın siyah çöp poşetleri içerisinde güneş altında 20-25 gün bekletilerek larvaların ölmesi sağlanmalıdır.",
                "Dökülen bulaşık meyveler toplanıp en az 50 cm derinliğinde çukurlara gömülmelidir.",
                "Hasat sonunda ağaç üzerinde meyve bırakılmamalıdır.",
                "İhraç edilen greyfurt ve limon meyvelerinde hasat sonrası soğuk uygulama zorunludur.",
                "Kitle Halinde Tuzakla Yakalama (KHTY) ile feromon/cezbedici tuzaklar kullanılmalıdır.",
                "SIT (Steril Böcek Salım) yöntemi geniş alan uygulamasında etkilidir.",
            ],
        },
    ],
    "rule_engine_rules": [
        {
            "id": "rule.orange.disease.mal_secco.autumn_winter_window",
            "crop_id": "crop.orange",
            "category": "disease_risk",
            "priority": 90,
            "enabled": True,
            "conditions": [
                {"field": "crop_id", "operator": "equals", "value": "crop.orange"},
                {"field": "month", "operator": "in", "value": [10, 11, 12, 1, 2, 3]},
                {"field": "average_temperature_c", "operator": "between", "value": [3, 30]},
                {"field": "rain_with_wind_recent", "operator": "equals", "value": True},
            ],
            "result": {
                "risk_level": "high",
                "possible_problem_id": "disease.orange.mal_secco",
                "recommendations": [
                    "Hastalıklı dalları, hastalıklı yerden 20 cm aşağıdan budayıp imha edin.",
                    "Yara yerlerine aşı macunu sürün; budama aletlerini her kesimden sonra %10 sodyum hipoklorit ile dezenfekte edin.",
                    "Don, dolu, fırtına sonrası ağaçlar ilaçlanmalıdır (etmen yaralardan giriş yapar).",
                    "Yeşil aksam ilaçlaması ekim, aralık ve mart aylarında 3 kez yapılır.",
                    "Sertifikalı, hastalıktan ari fidan kullanın.",
                    "Limon en hassas türdür; daha sıkı kontrol uygulayın.",
                    "Kimyasal mücadele için BKÜ veritabanında güncel ruhsatlı ürün kontrolü zorunludur.",
                ],
                "requires_expert_confirmation": True,
                "requires_bku_check": True,
            },
            "explanation": "Phoma tracheiphila enfeksiyonları ekim-mart aylarında gerçekleşir; en fazla bulaşma ekim ayındadır. 3°C-30°C aralığında aktif, yağmur+rüzgar etkisiyle yayılır.",
            "confidence": "high",
            "evidence": [
                {
                    "source_id": "source.tagem.citrus_ipm",
                    "page": 66,
                    "section": "1.40. Uçkurutan",
                    "evidence_text": "Uçkurutan hastalığının enfeksiyonları ekim-mart aylarında gerçekleşir. En fazla bulaşma ekim ayındadır.",
                }
            ],
        },
        {
            "id": "rule.orange.disease.brown_rot.autumn_rain",
            "crop_id": "crop.orange",
            "category": "disease_risk",
            "priority": 85,
            "enabled": True,
            "conditions": [
                {"field": "crop_id", "operator": "equals", "value": "crop.orange"},
                {"field": "month", "operator": "in", "value": [9, 10, 11]},
                {"field": "average_temperature_c", "operator": "between", "value": [5, 32]},
                {"field": "recent_heavy_rain", "operator": "equals", "value": True},
            ],
            "result": {
                "risk_level": "high",
                "possible_problem_id": "disease.orange.brown_rot",
                "recommendations": [
                    "Alt dallarda meyvelerde kahverengi çürüklüğü ve kabukta zamk akıntısını kontrol edin.",
                    "Sonbahar yağışlarından önce hasat tamamlanmalı (özellikle limonda).",
                    "Salma sulamadan damla sulamaya geçin; suyun kök boğazına değmesini engelleyin.",
                    "Yara yerlerine aşı macunu sürün; kök yaralanmasından kaçının.",
                    "Toprak drenajı kontrol edilmelidir.",
                    "Kimyasal mücadele gerekiyorsa BKÜ kontrolü, etiket dozu ve son ilaçlama-hasat aralığı zorunludur.",
                ],
                "requires_expert_confirmation": True,
                "requires_bku_check": True,
            },
            "explanation": "Phytophthora citrophthora 5-32°C arasında gelişir, optimum 24-28°C; meyve enfeksiyonu yağmurla sıçrayan zoosporlar yoluyla olur.",
            "confidence": "high",
            "evidence": [
                {
                    "source_id": "source.tagem.citrus_ipm",
                    "page": 67,
                    "section": "1.41. Phytophthora",
                    "evidence_text": "Etmen, 5-32°C'de gelişebilmekte ve 24-28°C sıcaklıklarda optimum gelişme göstermektedir.",
                }
            ],
        },
        {
            "id": "rule.orange.pest.planococcus.tree_threshold_5pct_may",
            "crop_id": "crop.orange",
            "category": "pest_risk",
            "priority": 90,
            "enabled": True,
            "conditions": [
                {"field": "crop_id", "operator": "equals", "value": "crop.orange"},
                {"field": "month", "operator": "between", "value": [5, 7]},
                {"field": "planococcus_infested_trees_percent", "operator": "greater_or_equal", "value": 5},
            ],
            "result": {
                "risk_level": "high",
                "possible_problem_id": "pest.orange.planococcus_citri",
                "recommendations": [
                    "Mücadele kararı alınır.",
                    "Biyolojik mücadele tercih edilmelidir: ağaç başına 2-3 adet C. montrouzieri + 10 adet L. dactylopii salınmalıdır.",
                    "Karınca faaliyetini önlemek için gövdeye yapışkan madde sürün.",
                    "Yoğun popülasyonda önce yazlık yağ uygulayıp 1 hafta sonra faydalı salımı yapın.",
                    "Kimyasal mücadeleye geçilirse BKÜ kontrolü, doğal düşmanlara seçici ürün ve uzman onayı zorunludur.",
                ],
                "requires_expert_confirmation": True,
                "requires_bku_check": True,
            },
            "explanation": "TAGEM eşiği: mayıs-temmuz aylarında %5 ağaç veya %10 meyve bulaşıklığı saptandığında Turunçgil unlubiti mücadelesine karar verilir.",
            "confidence": "high",
            "evidence": [
                {
                    "source_id": "source.tagem.citrus_ipm",
                    "page": 19,
                    "section": "1.18. Turunçgil unlubiti — Kimyasal mücadele",
                    "evidence_text": "Mayıs-temmuz aylarında %5 ağaç veya %10 meyve bulaşıklığı saptandığında ilaçlamaya karar verilir.",
                }
            ],
        },
        {
            "id": "rule.orange.pest.planococcus.fruit_threshold_15pct_aug",
            "crop_id": "crop.orange",
            "category": "pest_risk",
            "priority": 90,
            "enabled": True,
            "conditions": [
                {"field": "crop_id", "operator": "equals", "value": "crop.orange"},
                {"field": "month", "operator": "between", "value": [8, 9]},
                {"field": "planococcus_infested_fruits_percent", "operator": "greater_or_equal", "value": 15},
            ],
            "result": {
                "risk_level": "high",
                "possible_problem_id": "pest.orange.planococcus_citri",
                "recommendations": [
                    "Ağaç başına 4-5 adet predatör (C. montrouzieri) + 10 adet parazitoid (L. dactylopii) salımı yapılır.",
                    "Eylül %20 bulaşıklığa ulaşırsa kasım sonuna kadar 10 predatör + 20 parazitoid salımına devam edin.",
                    "Salımlar günün serin saatlerinde yapılmalıdır.",
                    "Kimyasal mücadeleye geçilirse BKÜ kontrolü ve uzman onayı zorunludur.",
                ],
                "requires_expert_confirmation": True,
                "requires_bku_check": True,
            },
            "explanation": "TAGEM eşiği: ağustos-eylül aylarında %15-20 meyve bulaşıklığında biyolojik mücadele dozu artırılır; kimyasal mücadele için aynı eşik geçerlidir.",
            "confidence": "high",
            "evidence": [
                {
                    "source_id": "source.tagem.citrus_ipm",
                    "page": 19,
                    "section": "1.18. Turunçgil unlubiti — Yoğun dönem",
                    "evidence_text": "Ağustos ayında gerek ağaç ve gerekse meyve bulaşıklığı %15 olursa ağaç başına 4-5 adet predatör ile 10 adet parazitoid verilir.",
                }
            ],
        },
        {
            "id": "rule.orange.pest.ceratitis.fruit_color_break_warm",
            "crop_id": "crop.orange",
            "category": "pest_risk",
            "priority": 95,
            "enabled": True,
            "conditions": [
                {"field": "crop_id", "operator": "equals", "value": "crop.orange"},
                {"field": "fruit_color_break", "operator": "equals", "value": True},
                {"field": "average_temperature_c", "operator": "greater_or_equal", "value": 16},
            ],
            "result": {
                "risk_level": "high",
                "possible_problem_id": "pest.orange.ceratitis_capitata",
                "recommendations": [
                    "Meyveler vurma olgunluğuna gelmeden 1 ay önce KHTY (Kitle Halinde Tuzakla Yakalama) tuzakları asılmalı (güney/güneydoğu yön, 1.5-2 m yükseklik).",
                    "Bulaşık meyveler toplanıp kalın siyah poşetlerde güneş altında 20-25 gün bekletilmelidir.",
                    "Dökülen meyveler en az 50 cm derinliğinde çukurlara gömülmelidir.",
                    "Hasat sonunda ağaçta meyve bırakılmamalıdır.",
                    "Karantina zararlısıdır; ihracat için hasat sonrası soğuk uygulama gerekir.",
                    "Kimyasal mücadele veya cezbet-öldür yöntemi için BKÜ kontrolü zorunludur.",
                ],
                "requires_expert_confirmation": True,
                "requires_bku_check": True,
            },
            "explanation": "Akdeniz meyvesineği 16°C üzeri sıcaklıklarda meyve vurma olgunluğunda zarar başlatır; karantina zararlısıdır ve toleransı sıfırdır.",
            "confidence": "high",
            "evidence": [
                {
                    "source_id": "source.tagem.citrus_ipm",
                    "page": 23,
                    "section": "1.20. Akdeniz meyvesineği",
                    "evidence_text": "Hava sıcaklıkları gün içerisinde 16°C ve üzerinde seyrettiğinde özellikle erkenci olan, olgunlaşma dönemine gelen, meyve kabuğundaki asitlik oranı larva gelişimi için uygun olan meyvelerde zarar yapmaya başlar.",
                }
            ],
        },
    ],
    "v2_status": "draft",
    "missing_information": [
        "Turunçgilde ikincil hastalık/zararlıların tamamı ayrı v2 profiline açılmadı; mevcut kapsam uçkurutan, Phytophthora, unlubiti, kabuklubiti, Akdeniz meyvesineği ve analiz/sulama güvenlik kurallarıdır.",
        "test_cases — her rule_engine_rule için pozitif/negatif örnek girdiler eklenecek.",
    ],
}


# ─── ÇAY (crop.tea) ───────────────────────────────────────────────────────
# Kaynak: ÇAYKUR Tarım Kısım Müdürlüğü Çay Tarımı Ders Notları 2025.
# Talimat hastalık-zararlı yanı sıra iklim/toprak/yetiştirme koşullarını
# detaylı verir. ÇAYKUR resmî tutumu: ekonomik boyutta hastalık-zararlı
# tespit edilmemiştir; kimyasal mücadele tavsiye edilmemektedir.

TEA_DATA: dict = {
    "stable_id": "crop.tea",
    "source_ids": ["source.caykur.tea_cultivation_lecture_notes_2025"],
    "evidence": [
        {
            "source_id": "source.caykur.tea_cultivation_lecture_notes_2025",
            "page": 28,
            "section": "10. Çay Zararlıları — Genel tutum",
            "evidence_text": "Bölgemizin sahip olduğu iklim şartları dolayısıyla günümüze değin çay plantasyon alanlarımızda ekonomik boyutta zarara sebep olabilecek herhangi bir hastalık ve zararlı tespit edilmemiştir. Ülkemizde çayda görülecek zararlıların mücadelesinde, çay tarımında uygulanmakta olan kültürel ve teknik uygulamalar yeterli olmaktadır. Bu nedenle ülkemiz şartlarında çay bahçelerinde görülen zararlılar ile kimyasal mücadele yayılmasına gerek kalmamaktadır.",
        },
        {
            "source_id": "source.caykur.tea_cultivation_lecture_notes_2025",
            "page": 12,
            "section": "5. Çay Bitkisinin Toprak İstekleri",
            "evidence_text": "Çay bitkisi kalsiyum sevmeyen bir bitkidir. Genellikle aktif kirecin iz miktarda bulunduğu topraklarda iyi gelişir. Bu yüzden çay bitkisi, gelişme ortamının asit tepkimeli olmasını ister. Çayın optimum gelişme göstereceği pH sınırları; 4.5-6'dır. Köklerin serbestçe büyüyeceği derinlik en az 2 m olmalı, toprağın en az 90 cm derinlikteki kısmı su ile doygun durumda bulunmamalıdır.",
        },
    ],
    "confidence": "medium",
    "diseases_v2": [],
    "pests_v2": [
        {
            "id": "pest.tea.parametriotis_theae",
            "name_tr": "Çay Filiz Güvesi",
            "scientific_name": "Parametriotis theae",
            "source_ids": ["source.caykur.tea_cultivation_lecture_notes_2025"],
            "evidence": [
                {
                    "source_id": "source.caykur.tea_cultivation_lecture_notes_2025",
                    "page": 28,
                    "section": "10.1.1. Çay Filiz Güvesi — Zarar şekli",
                    "evidence_text": "Çay filiz güvesi, yaprak ve sürgünlerde galeri açarak zarar yapmaktadır. Yumurtadan çıkan larvalar yaprağı alt yüzeyinden delerek iki epidermis arasına girmekte ve burada bir galeri açarak beslenmeye başlamaktadır. Yapraklarda 5'in üzerinde galeri bulunduğunda yaprak dökümü meydana gelebilmektedir. Zararlı yoğunluğuna bağlı olarak dekara ürün kaybı 20-190 kg arasında değişmektedir.",
                },
            ],
            "control_methods_cultural": [
                "ÇAYKUR resmî tutumu: kimyasal mücadele tavsiye edilmemektedir.",
                "Kültürel mücadele uygulanmalı; sürgün hasadı ile zararlı popülasyonu baskı altında tutulur.",
                "Doğal düşmanların korunması için bahçe kenarı yabancı ot temizliği yapılmalıdır.",
            ],
        },
        {
            "id": "pest.tea.chloropulvinaria_floccifera",
            "name_tr": "Çay Koşnili",
            "scientific_name": "Chloropulvinaria floccifera",
            "source_ids": ["source.caykur.tea_cultivation_lecture_notes_2025"],
            "evidence": [
                {
                    "source_id": "source.caykur.tea_cultivation_lecture_notes_2025",
                    "page": 28,
                    "section": "10.1.2. Koşnil — Zarar şekli",
                    "evidence_text": "Çay koşnilinin esas zararı salgıladığı tatlımsı madde üzerinde oluşan fumajinden dolayı olmaktadır. Bitkinin özellikle yapraklarını ve diğer kısımlarını kaplayan siyah ve isli görünüşlü fumajin tabakası özümlemeye ve solunuma engel olarak çay ocağının zayıflamasına ve verimden düşmesine neden olmaktadır. Genel olarak yılda ortalama %9 ürün kaybına neden olmaktadır.",
                },
            ],
            "control_methods_cultural": [
                "ÇAYKUR resmî tutumu: kimyasal mücadele tavsiye edilmemektedir.",
                "Tekniğine uygun budama ve hava sirkülasyonunun sağlanması.",
                "Doğal düşmanların korunması.",
            ],
        },
        {
            "id": "pest.tea.toxoptera_aurantii",
            "name_tr": "Çaylarda Siyah Turunçgil Yaprakbiti",
            "scientific_name": "Toxoptera aurantii",
            "source_ids": ["source.caykur.tea_cultivation_lecture_notes_2025"],
            "evidence": [
                {
                    "source_id": "source.caykur.tea_cultivation_lecture_notes_2025",
                    "page": 29,
                    "section": "10.1.3. Toxoptera aurantii — Yaşam döngüsü",
                    "evidence_text": "Kışı genelde yumurta olarak geçirirler, baharla birlikte çıkış ve zarar başlar. Yılda 10-15 döl verebilmektedir. İlkbahardan sonbahara kadarki dönemde bitkilerde bulunmakla birlikte daha çok ilkbahar ve sonbahar başlarında yoğun olarak görülmektedir. Özellikle yeni çıkan sürgünlerde beslenirler.",
                },
            ],
            "control_methods_cultural": [
                "ÇAYKUR resmî tutumu: kimyasal mücadele tavsiye edilmemektedir.",
                "Doğal düşmanların korunması ve etkinliğinin artırılması.",
                "Hasat ile zararlının baskı altında tutulması.",
            ],
        },
        {
            "id": "pest.tea.polyphagotarsonemus_latus",
            "name_tr": "Sarı Çay Akarı",
            "scientific_name": "Polyphagotarsonemus latus (Tarsonemidae)",
            "source_ids": ["source.caykur.tea_cultivation_lecture_notes_2025"],
            "evidence": [
                {
                    "source_id": "source.caykur.tea_cultivation_lecture_notes_2025",
                    "page": 29,
                    "section": "10.1.4. Sarı Çay Akarı — Biyoloji",
                    "evidence_text": "Sarı çay akarının popülâsyonu bir haftada, en uygun şartlarda (25°C sıcaklık ve yüksek nispi rutubet) yükselebilmektedir. Zararlının bütün yıl boyunca aktivitesi ve çoğalması devam eder. Kışın çoğalması biraz azalır. Nemli yerlerde sayıca çok fazla bulunurlar.",
                },
                {
                    "source_id": "source.caykur.tea_cultivation_lecture_notes_2025",
                    "page": 32,
                    "section": "10.1.4. Sarı Çay Akarı — Mücadele tutumu",
                    "evidence_text": "Sarı çay akarı ile mücadelede Gıda, Tarım ve Hayvancılık Bakanlığı Koruma ve Kontrol Genel Müdürlüğünce yayımlanan Zirai Mücadele Teknik Talimatında kimyasal mücadele tavsiye edilmemiştir. Sarı çay akarı için kimyasal mücadele yapılamayacağından, mücadele yöntemlerinden 'kültürel-biyolojik ve biyoteknik yöntemlere' ağırlık verilmesi gerekmektedir.",
                },
            ],
            "control_methods_cultural": [
                "Sarı çay akarının görüldüğü bitkilerde, zararlının bulunduğu yapraklar kesilerek çay bahçesinden uzaklaştırılmalı ve imha edilmelidir.",
                "Yabancı otlar temizlenerek çay bahçesinin dışında imha edilmelidir.",
                "Avcı akarların (Phytoseidae) korunması için kimyasal ilaçlama yapılmamalıdır.",
                "Bahçe kenarlarındaki tozlu alanlara karşı önlem alınmalı.",
                "Beyazsineklerin yoğun olduğu yerlerde sarı yapışkan tuzaklar kullanılmalıdır.",
                "Taze yaprak hasadı popülasyonu baskı altında tutar.",
            ],
        },
        {
            "id": "pest.tea.ricania_simulans",
            "name_tr": "Ricania simulans (Kelebek)",
            "scientific_name": "Ricania simulans Walker (Hemiptera: Ricaniidae)",
            "source_ids": ["source.caykur.tea_cultivation_lecture_notes_2025"],
            "evidence": [
                {
                    "source_id": "source.caykur.tea_cultivation_lecture_notes_2025",
                    "page": 32,
                    "section": "10.1.5. Ricania simulans — Yaşam döngüsü",
                    "evidence_text": "Zararlının doğada takibi neticesinde nimflerinin iklim şartlarına göre değişmekle beraber Mayıs ayından itibaren görüldüğü, erginlerin ise Temmuz ayından itibaren çıkmaya başladığı ve Ekim ayı sonuna kadar doğada bulundukları belirlenmiştir. Zararlı kışı yumurta döneminde geçirmekte ve yılda bir döl vermektedir.",
                },
                {
                    "source_id": "source.caykur.tea_cultivation_lecture_notes_2025",
                    "page": 33,
                    "section": "10.1.5. Ricania simulans — Mücadele",
                    "evidence_text": "Zararlı kış dönemini bahçelerin kenarlarındaki bitkilerde yumurta döneminde geçirmesi nedeniyle bir sonraki yıl Mayıs ayına kadar nimflerin çıkışından önce zararlının bir yıl önceden yoğun olarak bulunduğu bahçelerin kenarlarındaki özellikle yumurta bıraktığı bitkiler (çit bitkileri, çalı formundaki bitkiler, böğürtlen, çok yıllık otsu bitkiler vb) temizlenmelidir.",
                },
            ],
            "control_methods_cultural": [
                "Mayıs ayı öncesinde bahçe kenarlarındaki yumurtalı bitkiler (çit, çalı, böğürtlen, çok yıllık otsu) temizlenmelidir.",
                "Yumurta bırakılmış dallar mekanik olarak çıkarılıp imha edilmelidir.",
                "Çay sürgün hasadı ile populasyon doğal olarak düşmektedir.",
                "ÇAYKUR resmî tutumu: kimyasal mücadele tavsiye edilmemektedir.",
            ],
        },
    ],
    "rule_engine_rules": [
        {
            "id": "rule.tea.suitability.altitude_max",
            "crop_id": "crop.tea",
            "category": "suitability",
            "priority": 80,
            "enabled": True,
            "conditions": [
                {"field": "crop_id", "operator": "equals", "value": "crop.tea"},
                {"field": "elevation_m", "operator": "greater_than", "value": 1000},
            ],
            "result": {
                "risk_level": "medium",
                "possible_problem_id": None,
                "recommendations": [
                    "Türkiye'de çaylıklar en fazla 1000 m yüksekliğe kadar yayılır; klon fidanlarda ise 450-500 m rakımlara kadar iyi gelişme bildirilmiştir.",
                    "Bu yükseklik üstünde gelişme geriler — alanın çay yetiştiriciliğine uygunluğu uzmanca değerlendirilmelidir.",
                ],
                "requires_expert_confirmation": True,
                "requires_bku_check": False,
            },
            "explanation": "ÇAYKUR ders notlarına göre Türkiye'de çay 1000 m üzerinde verim düşer; klon fidanlar 450-500 m optimum.",
            "confidence": "high",
            "evidence": [
                {
                    "source_id": "source.caykur.tea_cultivation_lecture_notes_2025",
                    "page": 9,
                    "section": "3.2. Çay Bitkisinin Yetiştirilebildiği Yükseltiler",
                    "evidence_text": "Türkiye'deki çaylıklar en fazla 1000 m yüksekliğe kadar yayılmaktadır. Klon fidanlarla yapılan denemede, çay bitkisinin 450-500 m rakımlara kadar iyi gelişebildiği, daha yüksek rakımlarda ise gelişmenin gerilediği bildirilmektedir.",
                }
            ],
        },
        {
            "id": "rule.tea.suitability.temperature_range",
            "crop_id": "crop.tea",
            "category": "weather_warning",
            "priority": 75,
            "enabled": True,
            "conditions": [
                {"field": "crop_id", "operator": "equals", "value": "crop.tea"},
                {"field": "any_of_recent_days", "operator": "exists", "value": True},
                {"field": "min_observed_temp_c", "operator": "less_than", "value": 0},
            ],
            "result": {
                "risk_level": "high",
                "possible_problem_id": None,
                "recommendations": [
                    "Çay bitkisi -5°C'de genç sürgünler ve kambiyum donar; -6°C'de yapay koruma gerekir.",
                    "Don öncesi rüzgar kırıcı / gölgeleme / örtü gibi koruma uygulanmalıdır.",
                    "Don sonrası hasarlı sürgünlerde uçkurutan benzeri patojen riski için budama ile yara izolasyonu yapılmalıdır.",
                ],
                "requires_expert_confirmation": True,
                "requires_bku_check": False,
            },
            "explanation": "ÇAYKUR: -5°C kambiyum donar, -15°C bitki donar; min 14°C ortalama altı ekonomik tarım güçleşir.",
            "confidence": "high",
            "evidence": [
                {
                    "source_id": "source.caykur.tea_cultivation_lecture_notes_2025",
                    "page": 10,
                    "section": "4.2. Çayın Sıcaklık İsteği",
                    "evidence_text": "Çay bitkisi -15°C de donar, 40°C nin üzerindeki sıcaklıklarda ise yanarak kavrulur. Minimum sıcaklığın sık sık 0°C nin, ortalama sıcaklığınsa 14°C nin aşağısına indiği yerlerde ekonomik çay tarımı yapılması güçtür. -5°C de genç sürgünlerin hatta kambiyumun donduğu, -6°C de bitkinin yapay olarak korunması gerektiği bildirilmektedir.",
                }
            ],
        },
        {
            "id": "rule.tea.soil_analysis.ph_outside_range",
            "crop_id": "crop.tea",
            "category": "soil_analysis",
            "priority": 90,
            "enabled": True,
            "conditions": [
                {"field": "crop_id", "operator": "equals", "value": "crop.tea"},
                {"field": "soil_ph", "operator": "exists", "value": True},
                {"field": "soil_ph_outside_4_5_to_6", "operator": "equals", "value": True},
            ],
            "result": {
                "risk_level": "high",
                "possible_problem_id": None,
                "recommendations": [
                    "Çay bitkisi optimum pH 4.5-6.0 arasıdır; bu aralık dışında verim ve kalite düşer.",
                    "pH aşırı düşükse (asit karakterli amonyum sülfat fazla kullanımı) gübre rejimi gözden geçirilmelidir.",
                    "pH yüksekse alüminyum sülfat, düşükse sönmüş kireç ile uzman tavsiyesi doğrultusunda düzeltme yapılabilir (köklendirme tavası için belirtilen yöntem).",
                    "Toprak analizi yapılmadan kesin gübre miktarı önerilemez.",
                ],
                "requires_expert_confirmation": True,
                "requires_bku_check": False,
            },
            "explanation": "ÇAYKUR: çayın optimum pH aralığı 4.5-6.0; aşırı pH düşüşü tek yönlü amonyum sülfat kullanımından kaynaklanır.",
            "confidence": "high",
            "evidence": [
                {
                    "source_id": "source.caykur.tea_cultivation_lecture_notes_2025",
                    "page": 13,
                    "section": "5. Çay Bitkisinin Toprak İstekleri",
                    "evidence_text": "Çayın optimum gelişme göstereceği pH sınırları; 4.5-6'dır. Çay bitkisi asit toprakları sevmesine karşın, aşırı pH düşüşünden olumsuz etkilenir. pH'daki düşüşün, asit karakterli amonyum sülfat gübresinin aşırı dozda ve tek yönlü kullanılmasından kaynaklandığını bildirilmektedirler.",
                }
            ],
        },
        {
            "id": "rule.tea.fertilization.requires_soil_analysis",
            "crop_id": "crop.tea",
            "category": "fertilization",
            "priority": 85,
            "enabled": True,
            "conditions": [
                {"field": "crop_id", "operator": "equals", "value": "crop.tea"},
                {"field": "has_recent_soil_analysis", "operator": "equals", "value": False},
            ],
            "result": {
                "risk_level": "medium",
                "possible_problem_id": None,
                "recommendations": [
                    "Toprak analizi yokken kesin gübre miktarı önerilemez.",
                    "ÇAYKUR önerisi: Çiftlik gübresi açığını kapatmak için 25:5:10 N:P:K bileşimli özel çay gübresi 60-70 kg/dekar olarak uygulanır — ancak bu yalnızca toprak analizi yoksa fallback olarak kullanılmalıdır.",
                    "Önerinin üzerinde gübre çay verimi düşürür ve içme suyunu kirletir.",
                    "Asit pH'lı toprakta amonyum sülfat tek yönlü uygulanırsa potasyum kaybı ve pH düşüşü olur — dengeli gübreleme gerekir.",
                    "Toprak analizi sonuçlarına göre uzman tavsiyesi doğrultusunda gübreleme planlanmalıdır.",
                ],
                "requires_expert_confirmation": True,
                "requires_bku_check": False,
            },
            "explanation": "ÇAYKUR: Çay gübrelemesi öncelikle toprak analizi sonucuna göre yapılır; üreticiye toprak analizi yaptırması önerilir.",
            "confidence": "high",
            "evidence": [
                {
                    "source_id": "source.caykur.tea_cultivation_lecture_notes_2025",
                    "page": 13,
                    "section": "5. Çay Bitkisinin Toprak İstekleri",
                    "evidence_text": "Günümüzde ise üreticilerin yaptıracağı toprak analizleri sonucunda gerekli gübre miktarının toprağa verilmesinin daha uygun olduğu belirtilmektedir.",
                }
            ],
        },
        {
            "id": "rule.tea.pest.parametriotis.galleries_threshold",
            "crop_id": "crop.tea",
            "category": "pest_risk",
            "priority": 70,
            "enabled": True,
            "conditions": [
                {"field": "crop_id", "operator": "equals", "value": "crop.tea"},
                {"field": "parametriotis_galleries_per_leaf", "operator": "greater_than", "value": 5},
            ],
            "result": {
                "risk_level": "medium",
                "possible_problem_id": "pest.tea.parametriotis_theae",
                "recommendations": [
                    "Yaprak başına 5'in üzerinde galeri yaprak dökümüne yol açabilir; 20-190 kg/dekar verim kaybı riski vardır.",
                    "ÇAYKUR resmî tutumu kimyasal mücadele tavsiye etmemektedir.",
                    "Hasat zamanlaması ile zararlı popülasyonu baskı altında tutulur.",
                    "Bahçe kenarı yabancı ot temizliği yapılmalıdır.",
                ],
                "requires_expert_confirmation": True,
                "requires_bku_check": True,
            },
            "explanation": "ÇAYKUR eşiği: yapraklarda 5 üzeri galeri yaprak dökümüne neden olur.",
            "confidence": "high",
            "evidence": [
                {
                    "source_id": "source.caykur.tea_cultivation_lecture_notes_2025",
                    "page": 28,
                    "section": "10.1.1. Çay Filiz Güvesi",
                    "evidence_text": "Yapraklarda 5'in üzerinde galeri bulunduğunda yaprak dökümü meydana gelebilmektedir. Zararlı yoğunluğuna bağlı olarak dekara ürün kaybı 20-190 kg arasında değişmektedir.",
                }
            ],
        },
        {
            "id": "rule.tea.pest.yellow_mite.warm_humid_population_surge",
            "crop_id": "crop.tea",
            "category": "pest_risk",
            "priority": 75,
            "enabled": True,
            "conditions": [
                {"field": "crop_id", "operator": "equals", "value": "crop.tea"},
                {"field": "average_temperature_c", "operator": "greater_or_equal", "value": 25},
                {"field": "relative_humidity_level", "operator": "equals", "value": "high"},
            ],
            "result": {
                "risk_level": "medium",
                "possible_problem_id": "pest.tea.polyphagotarsonemus_latus",
                "recommendations": [
                    "Yaprakların alt yüzeyinde bronzlaşma, ana damar boyunca tırnaklanma görüldüğünde Sarı Çay Akarı şüphelenmelidir.",
                    "ÇAYKUR/Bakanlık talimatı: Sarı Çay Akarı için kimyasal mücadele tavsiye edilmemektedir.",
                    "Bulaşık yapraklar kesilip imha edilmelidir; yabancı otlar temizlenmelidir.",
                    "Avcı akarlar (Phytoseidae) için kimyasal ilaçlama yapılmamalıdır.",
                    "Beyazsineklerle birlikte yayılır; sarı yapışkan tuzak kullanılabilir.",
                ],
                "requires_expert_confirmation": True,
                "requires_bku_check": True,
            },
            "explanation": "ÇAYKUR: Sarı Çay Akarı popülasyonu 25°C ve yüksek nemde 1 hafta içinde patlayabilir; mücadele kültürel-biyolojiktir.",
            "confidence": "high",
            "evidence": [
                {
                    "source_id": "source.caykur.tea_cultivation_lecture_notes_2025",
                    "page": 29,
                    "section": "10.1.4. Sarı Çay Akarı",
                    "evidence_text": "Sarı çay akarının popülâsyonu bir haftada, en uygun şartlarda (25°C sıcaklık ve yüksek nispi rutubet) yükselebilmektedir.",
                }
            ],
        },
        {
            "id": "rule.tea.pest.ricania.spring_egg_cleanup",
            "crop_id": "crop.tea",
            "category": "pest_risk",
            "priority": 70,
            "enabled": True,
            "conditions": [
                {"field": "crop_id", "operator": "equals", "value": "crop.tea"},
                {"field": "month", "operator": "in", "value": [3, 4, 5]},
                {"field": "field_ricania_history", "operator": "equals", "value": True},
            ],
            "result": {
                "risk_level": "medium",
                "possible_problem_id": "pest.tea.ricania_simulans",
                "recommendations": [
                    "Mayıs ayı öncesinde bahçe kenarlarındaki yumurtalı çit bitkileri, çalılar, böğürtlen ve çok yıllık otsu bitkiler temizlenmelidir.",
                    "Yumurta bırakılmış yarı odunsu ince dallar mekanik olarak çıkarılıp imha edilmelidir.",
                    "ÇAYKUR resmî tutumu: kimyasal mücadele tavsiye edilmemektedir.",
                    "Zararlının takibinde Mayıs sonrası nimf çıkışı dikkate alınmalıdır.",
                ],
                "requires_expert_confirmation": True,
                "requires_bku_check": True,
            },
            "explanation": "ÇAYKUR: Ricania simulans kışı yumurta döneminde geçirir; nimf çıkışı (Mayıs) öncesinde bahçe kenarı yumurtalı bitkilerin temizliği etkili kültürel mücadeledir.",
            "confidence": "high",
            "evidence": [
                {
                    "source_id": "source.caykur.tea_cultivation_lecture_notes_2025",
                    "page": 33,
                    "section": "10.1.5. Ricania simulans — Mücadele",
                    "evidence_text": "Mayıs ayına kadar nimflerin çıkışından önce zararlının bir yıl önceden yoğun olarak bulunduğu bahçelerin kenarlarındaki özellikle yumurta bıraktığı bitkiler temizlenmelidir.",
                }
            ],
        },
    ],
    "v2_status": "draft",
    "missing_information": [
        "Çay için kaynaklı hastalık profili eklenmedi; ÇAYKUR kaynağı ekonomik boyutta hastalık/zararlı için kimyasal mücadele önermeyen kültürel yaklaşımı esas alıyor.",
        "weeds_v2[] — çay bahçelerinde kontrol edilen yabancı otlar listelenecek.",
        "test_cases — her rule_engine_rule için pozitif/negatif örnek girdiler eklenecek.",
        "Karadeniz Araştırma Enstitüsü ve Atatürk Çay Araştırma Enstitüsü kaynakları sources.json'a eklenmesi önerilir.",
    ],
}


def _rule(
    *,
    id: str,
    crop_id: str,
    category: str,
    priority: int,
    conditions: list[dict],
    recommendations: list[str],
    evidence: list[dict],
    risk_level: str = "medium",
    possible_problem_id: str | None = None,
    explanation: str,
    confidence: str = "high",
    requires_expert_confirmation: bool = True,
    requires_bku_check: bool = False,
) -> dict:
    return {
        "id": id,
        "crop_id": crop_id,
        "category": category,
        "priority": priority,
        "enabled": True,
        "conditions": [
            {"field": "crop_id", "operator": "equals", "value": crop_id},
            *conditions,
        ],
        "result": {
            "risk_level": risk_level,
            "possible_problem_id": possible_problem_id,
            "recommendations": recommendations,
            "requires_expert_confirmation": requires_expert_confirmation,
            "requires_bku_check": requires_bku_check,
        },
        "explanation": explanation,
        "confidence": confidence,
        "evidence": evidence,
    }


PRIORITY_COMPLETIONS: dict[str, dict] = {
    "crop.tomato": {
        "growth_stages": [
            {
                "key": "seedling",
                "label_tr": "Fide ve erken gelişme",
                "evidence": [
                    {
                        "source_id": "source.tagem.tomato_open_field_ipm",
                        "page": 12,
                        "section": "5.3. Hastalıkların örnekleme yöntemleri",
                        "evidence_text": "Fungal hastalıkların varlığı fide döneminden itibaren kontrol edilir.",
                    }
                ],
            },
            {
                "key": "flowering_fruit_set",
                "label_tr": "Çiçeklenme ve meyve tutumu",
                "evidence": [
                    {
                        "source_id": "source.tagem.tomato_open_field_ipm",
                        "page": 90,
                        "section": "7.3.3. Çiçekte ve yaprakta görülen fizyolojik bozukluklar",
                        "evidence_text": "Domates bitkisi uygun olmayan hava sıcaklıklarında çiçek döker. Gece sıcaklığının 21°C'den büyük veya 13°C'den küçük, gündüz sıcaklığının 32°C'den büyük olması halinde polen canlılığı ve tozlaşma özelliği kaybolduğu için döllenme olmaz ve çiçek kuruyarak dökülür.",
                    }
                ],
            },
            {
                "key": "fruit_development",
                "label_tr": "Meyve gelişimi",
                "evidence": [
                    {
                        "source_id": "source.tagem.tomato_open_field_ipm",
                        "page": 85,
                        "section": "7.3.2. Meyvede görülen fizyolojik bozukluklar",
                        "evidence_text": "Çiçek burnu çürüklüğü; bitkinin genetik özellikleri, iklim faktörü, bitki besleme ve sulama ile doğrudan ilişkilidir.",
                    }
                ],
            },
        ],
        "fertilizer_rules": [
            {
                "id": "fertilizer.tomato.soil_analysis_balance",
                "title": "Toprak analizine dayalı dengeli gübreleme",
                "summary": "Azot fazlası hastalık ve zararlı duyarlılığını artırır; fosfor, potasyum, kalsiyum ve mikro elementler gelişme dönemine göre dengelenmelidir.",
                "guardrail": "Toprak analizi olmadan net gübre miktarı verilmez.",
                "evidence": [
                    {
                        "source_id": "source.tagem.tomato_open_field_ipm",
                        "page": 59,
                        "section": "7.2.4. Solgunluk ve kök çürüklükleri — Kültürel önlemler",
                        "evidence_text": "Dengeli gübreleme ve iyi bakım yapılmalı, aşırı azotlu gübrelemeden kaçınılmalıdır. Toprak analizi sonuçlarına göre gübreleme yapılmalıdır.",
                    },
                    {
                        "source_id": "source.tagem.tomato_open_field_ipm",
                        "page": 80,
                        "section": "7.3.1. Azot",
                        "evidence_text": "Aşırı azotlu gübreleme sonucu bitkiler, hastalık ve zararlı etmenleri ile diğer abiyotik stres koşullarından daha çok etkilenir.",
                    },
                ],
            },
            {
                "id": "fertilizer.tomato.calcium_fruit_disorder",
                "title": "Çiçek burnu çürüklüğünde kalsiyum-su dengesi",
                "summary": "Meyve gelişiminde kalsiyum eksikliği, su stresi ve düzensiz sulama birlikte değerlendirilmelidir.",
                "guardrail": "Kalsiyum uygulaması toprak/pH/tuzluluk analizi ve uzman yorumu olmadan net dozla verilmez.",
                "evidence": [
                    {
                        "source_id": "source.tagem.tomato_open_field_ipm",
                        "page": 85,
                        "section": "7.3.2. Çiçek burnu çürüklüğü",
                        "evidence_text": "Aşırı azotlu gübrelemeden kaçınılmalıdır. Toprağın pH ve tuz düzeyi kontrol edilmelidir. Sulama düzensizlikleri ortadan kaldırılmalı, bitkiye yeterli miktarda ve sıklıkta su verilmeli, drenaj koşulları düzeltilmelidir.",
                    }
                ],
            },
        ],
        "irrigation_rules": [
            {
                "id": "irrigation.tomato.root_collar_drainage",
                "title": "Kök boğazında su birikimini önle",
                "summary": "Solgunluk ve kök çürüklüğü riskinde aşırı sulama, kök boğazında su birikimi ve zayıf drenaj ana risklerdir.",
                "evidence": [
                    {
                        "source_id": "source.tagem.tomato_open_field_ipm",
                        "page": 59,
                        "section": "7.2.4. Solgunluk ve kök çürüklükleri — Kültürel önlemler",
                        "evidence_text": "Aşırı sulamadan kaçınılmalı özellikle sulama suyunun kök boğazı çevresinde birikmesi önlenmeli, salma sulama yerine tercihen damla sulama yapılmalıdır.",
                    }
                ],
            },
            {
                "id": "irrigation.tomato.fruit_cracking_consistency",
                "title": "Meyve döneminde sulama dalgalanmasını azalt",
                "summary": "Kurak dönemden sonra gelen aşırı yağış veya sulama meyve çatlamasını artırır.",
                "evidence": [
                    {
                        "source_id": "source.tagem.tomato_open_field_ipm",
                        "page": 87,
                        "section": "7.3.2. Meyve çatlaması",
                        "evidence_text": "Sulamada dalgalanmalara izin verilmemelidir. Yaprak budaması meyve üzerine direk güneş ışığının gelmesini engelleyecek şekilde yapılmalıdır. Aşırı azotlu gübrelemeden kaçınılmalıdır.",
                    }
                ],
            },
        ],
        "rule_engine_rules": [
            _rule(
                id="rule.tomato.physiology.blossom_end_rot.water_calcium",
                crop_id="crop.tomato",
                category="physiological_risk",
                priority=82,
                conditions=[
                    {"field": "growth_stage", "operator": "equals", "value": "fruit_development"},
                    {"field": "irrigation_irregularity", "operator": "equals", "value": True},
                ],
                possible_problem_id="physiology.tomato.blossom_end_rot",
                recommendations=[
                    "Çiçek burnu çürüklüğü riski için sulama dalgalanmasını azaltın; kök bölgesinde yeterli ve sürekli nem hedefleyin.",
                    "Toprağın pH ve tuz düzeyini kontrol edin; kalsiyum eksikliği varsa analize göre uzman tavsiyesi alın.",
                    "Aşırı azotlu gübrelemeden kaçının.",
                ],
                evidence=[
                    {
                        "source_id": "source.tagem.tomato_open_field_ipm",
                        "page": 85,
                        "section": "7.3.2. Çiçek burnu çürüklüğü",
                        "evidence_text": "Sulama düzensizlikleri ortadan kaldırılmalı, bitkiye yeterli miktarda ve sıklıkta su verilmeli, drenaj koşulları düzeltilmelidir.",
                    }
                ],
                explanation="Domateste çiçek burnu çürüklüğü kalsiyum taşınımı, su stresi, pH/tuz ve besleme dengesi ile ilişkilidir.",
            ),
            _rule(
                id="rule.tomato.physiology.flower_drop.temperature_nitrogen",
                crop_id="crop.tomato",
                category="physiological_risk",
                priority=78,
                conditions=[
                    {"field": "growth_stage", "operator": "equals", "value": "flowering_fruit_set"},
                    {"field": "temperature_flower_drop_risk", "operator": "equals", "value": True},
                ],
                possible_problem_id="physiology.tomato.flower_drop",
                recommendations=[
                    "Çiçeklenmede gece 13°C altı veya 21°C üstü, gündüz 32°C üstü sıcaklıklar meyve tutumunu bozabilir.",
                    "Aşırı azotlu gübreleme yeşil aksamı artırıp meyve tutumunu azaltabilir; gübrelemeyi analizle dengeleyin.",
                    "Toprak nemini çok düşük ya da aşırı yüksek bırakmayın.",
                ],
                evidence=[
                    {
                        "source_id": "source.tagem.tomato_open_field_ipm",
                        "page": 90,
                        "section": "7.3.3. Çiçek dökülmesi",
                        "evidence_text": "Aşırı azotlu gübreleme ile aşırı yeşil aksam gelişimi meyve tutumunun azalmasına neden olabilir. Düşük veya aşırı toprak nemi bitki için stres faktörü oluşturduğu için çiçek dökümüne sebep olabilir.",
                    }
                ],
                explanation="Çiçek dökülmesi sıcaklık, bağıl nem, azot dengesi ve toprak nemi stresleriyle birlikte değerlendirilir.",
            ),
        ],
        "missing_information": [
            "İkincil domates hastalık/zararlılarının tamamı ayrı v2 profiline açılmadı; mevcut uygulama kapsamı mildiyö, erken yaprak yanıklığı, domates güvesi, yeşilkurt ve kaynaklı fizyolojik besleme/sulama riskleridir.",
            "test_cases — her rule_engine_rule için pozitif/negatif örnek girdiler eklenecek.",
            "v2_status='draft' — uzman onayı sonrası 'review' veya 'approved' yapılacak.",
        ],
    },
    "crop.corn": {
        "growth_stages": [
            {
                "key": "seedling",
                "label_tr": "Çimlenme-fide",
                "evidence": [
                    {
                        "source_id": "source.tagem.corn_ipm",
                        "page": 63,
                        "section": "7.2.2. Tohum ve fide çürüklüğü",
                        "evidence_text": "Henüz çimlenmemiş veya çimlenen mısır tohumları; tohum çürüklüğü ve fide yanıklığını oluşturan toprak ve tohum kaynaklı birçok etmen tarafından enfekte edilebilir.",
                    }
                ],
            },
            {
                "key": "tasseling",
                "label_tr": "Tepe püskülü",
                "evidence": [
                    {
                        "source_id": "source.tagem.corn_ipm",
                        "page": 64,
                        "section": "7.2.2. Fusarium spp.",
                        "evidence_text": "Bu etmenler kurak ve sıcak bölgelerde özellikle tepe püskülü çıkarma devresinde etkilidir.",
                    }
                ],
            },
            {
                "key": "silking",
                "label_tr": "Koçan püskülü",
                "evidence": [
                    {
                        "source_id": "source.tagem.corn_ipm",
                        "page": 46,
                        "section": "7.1.7. Yeşilkurt — Mücadele eşiği",
                        "evidence_text": "Mısır koçan püskülü döneminde tarlanın 5 farklı yerinde aynı sıra üzerinde yanyana 5 bitkinin koçan püskülü üzerinde yapılan larva kontrolünde bitki başına ortalama 1 adet 1.-3. dönem larva belirlendiğinde ilaçlama yapılmalıdır.",
                    }
                ],
            },
        ],
        "fertilizer_rules": [
            {
                "id": "fertilizer.corn.soil_analysis_fusarium_guardrail",
                "title": "Toprak analizine göre gübreleme",
                "summary": "Fusarium/kök-sap çürüklüğü baskısında gübreleme toprak analizine göre yapılmalı; aşırı azot ve sık ekimden kaçınılmalıdır.",
                "guardrail": "Analiz yoksa net NPK miktarı verilmez.",
                "evidence": [
                    {
                        "source_id": "source.tagem.corn_ipm",
                        "page": 66,
                        "section": "7.2.2. Mısırda kök/sap/koçan çürüklükleri — Kültürel önlemler",
                        "evidence_text": "Gübreler toprak analizi sonuçlarına göre uygulanmalıdır. Hastalığın yoğun olduğu yerlerde münavebe uygulanmalıdır. Sık ekimden ve aşırı sulamadan kaçınılmalıdır.",
                    }
                ],
            },
            {
                "id": "fertilizer.corn.aphid_leafhopper_nitrogen",
                "title": "Aşırı azotu zararlı baskısıyla birlikte değerlendir",
                "summary": "Yaprakbiti ve yaprakpirelerinde aşırı azotlu gübreleme ile aşırı sulama zararlı baskısını artıran yönetim riskleridir.",
                "guardrail": "Azot artırımı zararlı gözlemi ve toprak analizi olmadan önerilmez.",
                "evidence": [
                    {
                        "source_id": "source.tagem.corn_ipm",
                        "page": 51,
                        "section": "7.1.9. Yaprakbitleri — Kültürel önlemler",
                        "evidence_text": "Sık ekim, aşırı azotlu gübreleme ve aşırı sulamadan kaçınılmalıdır.",
                    },
                    {
                        "source_id": "source.tagem.corn_ipm",
                        "page": 60,
                        "section": "8.1.13. Yaprakpireleri — Kültürel önlemler",
                        "evidence_text": "Aşırı sulama ve aşırı azotlu gübre kullanımından kaçınılmalıdır.",
                    },
                ],
            },
        ],
        "irrigation_rules": [
            {
                "id": "irrigation.corn.seedling_cold_wet_soil",
                "title": "Soğuk ve rutubetli toprakta ekim/sulama riski",
                "summary": "10-13°C altı, drenajı zayıf ve rutubetli topraklarda tohum-fide çürüklüğü artar.",
                "evidence": [
                    {
                        "source_id": "source.tagem.corn_ipm",
                        "page": 63,
                        "section": "7.2.2. Tohum/kök/kökboğazı çürüklükleri",
                        "evidence_text": "Bu durum özellikle drenajı zayıf, aşırı killi, soğuk (10-13°C'den az) ve rutubetli topraklarda daha çok görülür.",
                    }
                ],
            },
            {
                "id": "irrigation.corn.spider_mite_water_stress",
                "title": "Kırmızı örümcekte su stresini önle",
                "summary": "Kırmızı örümcek riskinde bitki su stresine sokulmamalı ve sulama zamanı izlenmelidir.",
                "evidence": [
                    {
                        "source_id": "source.tagem.corn_ipm",
                        "page": 54,
                        "section": "7.1.10. Kırmızı Örümcekler — Kültürel mücadele",
                        "evidence_text": "Bitkinin su stresine girmesi önlenmelidir ve sulama zamanına dikkat edilmelidir.",
                    }
                ],
            },
        ],
        "rule_engine_rules": [
            _rule(
                id="rule.corn.pest.spider_mite.water_stress",
                crop_id="crop.corn",
                category="pest_risk",
                priority=72,
                conditions=[
                    {"field": "water_stress", "operator": "equals", "value": True},
                    {"field": "average_temperature_c", "operator": "greater_or_equal", "value": 25},
                ],
                possible_problem_id="pest.corn.tetranychus",
                recommendations=[
                    "Alt yaprakların alt yüzünde ağlanma, sararma ve kurumayı kontrol edin.",
                    "Bitkiyi su stresine sokmayın; sulama zamanını düzenleyin.",
                    "Doğal düşmanların korunması esastır; kaynak, kimyasal mücadeleyi önermemektedir.",
                ],
                evidence=[
                    {
                        "source_id": "source.tagem.corn_ipm",
                        "page": 54,
                        "section": "7.1.10. Kırmızı Örümcekler",
                        "evidence_text": "Bitkinin su stresine girmesi önlenmelidir ve sulama zamanına dikkat edilmelidir. Doğal düşmanların bu zararlıyı baskı altında tutması nedeni ile kimyasal mücadeleye gerek görülmemektedir.",
                    }
                ],
                explanation="Mısırda kırmızı örümcekler su stresi ve sıcak-kuru koşullarda izlenmelidir; kimyasal öneri yerine kültürel ve biyolojik koruma öne çıkar.",
                requires_bku_check=True,
            ),
            _rule(
                id="rule.corn.pest.leafhopper.nitrogen_irrigation_excess",
                crop_id="crop.corn",
                category="pest_risk",
                priority=70,
                conditions=[
                    {"field": "excess_nitrogen_or_irrigation", "operator": "equals", "value": True},
                    {"field": "leafhopper_adults_per_plant", "operator": "greater_or_equal", "value": 13},
                ],
                possible_problem_id="pest.corn.leafhopper",
                recommendations=[
                    "Tarla içi ve kenarındaki konukçu yabancı otları kontrol edin.",
                    "Aşırı sulama ve aşırı azotlu gübre kullanımından kaçının.",
                    "Eşik üstü durumda BKÜ kontrolü ve uzman onayı olmadan kimyasal mücadeleye geçmeyin.",
                ],
                evidence=[
                    {
                        "source_id": "source.tagem.corn_ipm",
                        "page": 60,
                        "section": "8.1.13. Yaprakpireleri — Mücadelesi",
                        "evidence_text": "Aşırı sulama ve aşırı azotlu gübre kullanımından kaçınılmalıdır. ... Zyginidia pullula'nın ekonomik zarar eşiği 13 ergin/bitki olarak belirlenmiştir.",
                    }
                ],
                explanation="Yaprakpireleri için kaynak kültürel önlemi ve 13 ergin/bitki eşiğini birlikte verir.",
                requires_bku_check=True,
            ),
        ],
        "missing_information": [
            "Mısırda ikincil hastalık/zararlı/yabancı otların tamamı ayrı v2 profiline açılmadı; mevcut kapsam ana zararlılar, Fusarium/rastık ve kaynaklı sulama-gübreleme riskleridir.",
            "test_cases — her rule_engine_rule için pozitif/negatif örnek girdiler eklenecek.",
        ],
    },
    "crop.sunflower": {
        "growth_stages": [
            {
                "key": "V0",
                "label_tr": "Kotiledon dönemi",
                "evidence": [
                    {
                        "source_id": "source.tagem.sunflower_ipm",
                        "page": 69,
                        "section": "EK-2 Ayçiçeğinin Fenolojik Dönemleri",
                        "evidence_text": "V0 Kotiledon dönemidir. Çimlenme sonrası fidenin toprak üstünde gözüktüğü ve gerçek yaprakların yeni oluşmaya başladığı dönemdir.",
                    }
                ],
            },
            {
                "key": "R1",
                "label_tr": "Tomurcuk başlangıcı",
                "evidence": [
                    {
                        "source_id": "source.tagem.sunflower_ipm",
                        "page": 69,
                        "section": "EK-2 Ayçiçeğinin Fenolojik Dönemleri",
                        "evidence_text": "R1 Çiçek tomurcuklarının 0.5-2.0 cm olduğu ve yaprak sayısının 8-12 arasında değiştiği dönemdir.",
                    }
                ],
            },
            {
                "key": "R5",
                "label_tr": "Çiçeklenme",
                "evidence": [
                    {
                        "source_id": "source.tagem.sunflower_ipm",
                        "page": 70,
                        "section": "EK-2 Ayçiçeğinin Fenolojik Dönemleri",
                        "evidence_text": "R5.1: Çiçeklenmenin başlangıç evresidir. Gerçek çiçekler %10 gözükmeye başlar. R5.5: Gerçek çiçeklerin %50'sinin açtığı dönemdir. R5.9: Gerçek çiçeklerin %90'ının açtığı dönemdir.",
                    }
                ],
            },
            {
                "key": "R9",
                "label_tr": "Fizyolojik olgunluk başlangıcı",
                "evidence": [
                    {
                        "source_id": "source.tagem.sunflower_ipm",
                        "page": 70,
                        "section": "EK-2 Ayçiçeğinin Fenolojik Dönemleri",
                        "evidence_text": "R9 Brakteler sarı ve kahverengiye dönmeye başlamıştır. Bu dönem fizyolojik olgunluk başlangıcı olarak kabul edilir.",
                    }
                ],
            },
        ],
        "fertilizer_rules": [
            {
                "id": "fertilizer.sunflower.boron_guardrail",
                "title": "Bor noksanlığı ve toksisitesini birlikte kontrol et",
                "summary": "Ayçiçeği bor noksanlığına duyarlıdır; ancak yüksek bor da toksisite yapar. Sulama suyu ve önceki bor uygulamaları sorgulanmalıdır.",
                "guardrail": "Bor uygulaması toprak/yaprak analizi olmadan net dozla önerilmez.",
                "evidence": [
                    {
                        "source_id": "source.tagem.sunflower_ipm",
                        "page": 50,
                        "section": "7.4. Fizyolojik Hastalıklar — Bor Noksanlığı",
                        "evidence_text": "Ayçiçeği bitkilerinde suyun köklerden bitkinin üst kısımlarına taşınmasında önemli rol oynayan bor elementine olan ihtiyaç özellikle kurak şartlarda daha da artar.",
                    },
                    {
                        "source_id": "source.tagem.sunflower_ipm",
                        "page": 51,
                        "section": "7.4. Fizyolojik Hastalıklar — Bor Toksisitesi",
                        "evidence_text": "Bor toksisitesini düzeltmek için sadece yüksek bor içeren sulama suyu veya aşırı bor gübrelemesinden kaçınmak yeterli olmayıp, kireç ve azotlu gübre özellikle de kalsiyum nitrat uygulaması yapılmalıdır.",
                    },
                ],
            },
            {
                "id": "fertilizer.sunflower.nitrogen_oil_guardrail",
                "title": "Azotu verim ve yağ oranı dengesiyle planla",
                "summary": "Kaynak kuru koşulda hedeflenen verim için azot bilgisini verir; fazla azot yağ oranını düşürebilir.",
                "guardrail": "Bölge, sulama ve toprak analizi olmadan kesin azot miktarı önerilmez.",
                "evidence": [
                    {
                        "source_id": "source.tagem.sunflower_ipm",
                        "page": 52,
                        "section": "7.4. Fizyolojik Hastalıklar — Azot Noksanlığı",
                        "evidence_text": "Ayçiçeğinde yapılan araştırmalar, genelde 8-12 kg/da saf azot uygulaması, kuru şartlarda hedeflenen 250-300 kg/da tane verimi için yeterli olduğunu göstermektedir. Ancak sulu koşullarda bu oranı arttırılması ... şarttır. Yapılan fazla azotlu gübrelemenin tanedeki yağ oranını %2,5-3,8 oranında azalttığı görülmüştür.",
                    }
                ],
            },
        ],
        "irrigation_rules": [
            {
                "id": "irrigation.sunflower.charcoal_rot_water_stress",
                "title": "Sıcak aylarda su stresini azalt",
                "summary": "Kömür çürüklüğü ve bor noksanlığı riskinde sıcak-kurak dönemde düzenli sulama koruyucu önlemdir.",
                "evidence": [
                    {
                        "source_id": "source.tagem.sunflower_ipm",
                        "page": 42,
                        "section": "7.2.1. Kömür Çürüklüğü — Kültürel önlemler",
                        "evidence_text": "Özellikle sıcak aylarda bitkileri su stresine sokmayacak şekilde düzenli sulama yapılmalıdır.",
                    }
                ],
            },
            {
                "id": "irrigation.sunflower.boron_toxicity_water_quality",
                "title": "Sulama suyunda bor riskini izle",
                "summary": "Yüksek bor içeren sulama suyu bor toksisitesine yol açabilir; su analizi önemlidir.",
                "evidence": [
                    {
                        "source_id": "source.tagem.sunflower_ipm",
                        "page": 50,
                        "section": "7.4. Fizyolojik Hastalıklar — Bor Toksisitesi",
                        "evidence_text": "Ayçiçeğinde nadir görünen bor toksisitesi daha çok, sulama suyundaki yüksek bor konsantrasyonu veya rotasyonda bir önceki bitkiye uygulanan aşırı bor gübrelemesi vb. uygulamalar sonucu ortaya çıkar.",
                    }
                ],
            },
        ],
        "rule_engine_rules": [
            _rule(
                id="rule.sunflower.physiology.boron_drought",
                crop_id="crop.sunflower",
                category="physiological_risk",
                priority=76,
                conditions=[
                    {"field": "drought_stress", "operator": "equals", "value": True},
                    {"field": "boron_symptom_observed", "operator": "equals", "value": True},
                ],
                possible_problem_id="physiology.sunflower.boron_disorder",
                recommendations=[
                    "Bor noksanlığı ile kalsiyum/bakır eksikliği ve mekanik zararı karıştırmayın; belirtiyi fotoğraf + uzman gözlemiyle doğrulayın.",
                    "Sulama suyu ve önceki bor gübrelemesi geçmişini kontrol edin.",
                    "Toprak/yaprak analizi olmadan bor uygulaması yapmayın; yüksek bor toksisite oluşturabilir.",
                ],
                evidence=[
                    {
                        "source_id": "source.tagem.sunflower_ipm",
                        "page": 50,
                        "section": "7.4. Bor Noksanlığı",
                        "evidence_text": "Ayçiçeği her ne kadar bor noksanlığına aşırı duyarlı ise de, yüksek oranda bor oranları da bitkiye toksik etki yapar.",
                    }
                ],
                explanation="Ayçiçeğinde bor hem noksanlık hem toksisite açısından hassastır; kaynak, kuraklık ve sulama suyu borunu birlikte ele alır.",
            ),
            _rule(
                id="rule.sunflower.disease.charcoal_rot.water_stress_guard",
                crop_id="crop.sunflower",
                category="disease_risk",
                priority=84,
                conditions=[
                    {"field": "average_temperature_c", "operator": "greater_or_equal", "value": 28},
                    {"field": "water_stress", "operator": "equals", "value": True},
                ],
                possible_problem_id="disease.sunflower.charcoal_rot",
                recommendations=[
                    "Kök boğazı ve gövdede kömürleşme/mikrosklerot belirtisini kontrol edin.",
                    "Sıcak aylarda bitkiyi su stresine sokmayacak düzenli sulama planlayın.",
                    "Hastalıklı bitki ve hasat artıklarını tarladan uzaklaştırın.",
                ],
                evidence=[
                    {
                        "source_id": "source.tagem.sunflower_ipm",
                        "page": 42,
                        "section": "7.2.1. Kömür Çürüklüğü — Kültürel önlemler",
                        "evidence_text": "Özellikle sıcak aylarda bitkileri su stresine sokmayacak şekilde düzenli sulama yapılmalıdır.",
                    }
                ],
                explanation="Kömür çürüklüğü sıcak ve su stresi koşullarında yönetim uyarısı gerektirir.",
                requires_bku_check=True,
            ),
        ],
        "missing_information": [
            "Ayçiçeğinde ikincil zararlı ve yabancı otların tamamı ayrı v2 profiline açılmadı; mevcut kapsam ana hastalıklar, bozkurt/yeşilkurt, canavar otu ve kaynaklı bor/sulama riskleridir.",
            "test_cases — her rule_engine_rule için pozitif/negatif örnek girdiler eklenecek.",
        ],
    },
    "crop.orange": {
        "growth_stages": [
            {
                "key": "pre_bloom",
                "label_tr": "Çiçeklenme öncesi tomurcuk",
                "evidence": [
                    {
                        "source_id": "source.tagem.citrus_ipm",
                        "page": 11,
                        "section": "1.8. Göz ile inceleme yöntemi",
                        "evidence_text": "Fenolojik döneme bağlı olarak, çiçeklenme öncesinde tomurcuk, çiçeklenme döneminde çiçek, daha sonra yaprak ve meyve üzerinde bulunan böcekler, zararlı ve yararlı akarlar ve yenikler sayılır.",
                    }
                ],
            },
            {
                "key": "bloom",
                "label_tr": "Çiçeklenme",
                "evidence": [
                    {
                        "source_id": "source.tagem.citrus_ipm",
                        "page": 11,
                        "section": "1.8. Göz ile inceleme yöntemi",
                        "evidence_text": "Fenolojik döneme bağlı olarak, çiçeklenme öncesinde tomurcuk, çiçeklenme döneminde çiçek, daha sonra yaprak ve meyve üzerinde bulunan böcekler, zararlı ve yararlı akarlar ve yenikler sayılır.",
                    }
                ],
            },
            {
                "key": "fruit_leaf_monitoring",
                "label_tr": "Yaprak ve meyve izleme",
                "evidence": [
                    {
                        "source_id": "source.tagem.citrus_ipm",
                        "page": 11,
                        "section": "1.8. Göz ile inceleme yöntemi",
                        "evidence_text": "Vejetasyon süresince 1-2 hafta aralıklarla yapılır. Bunun için, bahçeyi temsil edecek şekilde 10 ağaç seçilir ve bu ağaçların her birinden 10'ar olmak üzere, toplam 100 adet bitki örneği ... sayılır.",
                    }
                ],
            },
        ],
        "fertilizer_rules": [
            {
                "id": "fertilizer.orange.leaf_soil_sampling",
                "title": "Yaprak ve toprak analizine göre gübreleme",
                "summary": "Dengeli beslenme ve noksanlık takibi için eylül-ekimde 4-7 aylık yapraklar ve 0-30 cm toprak örneği ile analiz yapılmalıdır.",
                "guardrail": "Analiz olmadan turunçgil için net gübre miktarı önerilmez.",
                "evidence": [
                    {
                        "source_id": "source.tagem.citrus_ipm",
                        "page": 13,
                        "section": "1.16. Bitki besin elementleri ile ilgili örnekleme yöntemleri",
                        "evidence_text": "Turunçgil ağaçlarının dengeli beslenmeleri ve bitki besin elementleri noksanlıklarının belirlenmesi için, yaprak ve toprak analizleri yaptırılması gerekir.",
                    },
                    {
                        "source_id": "source.tagem.citrus_ipm",
                        "page": 14,
                        "section": "1.16. Bitki besin elementleri ile ilgili örnekleme yöntemleri",
                        "evidence_text": "Alınan yaprak ve toprak örnekleri gerekli bilgileri taşıyan etiketleriyle birlikte analize gönderilir ve öneriler doğrultusunda gübreleme uygulamaları yapılır.",
                    },
                ],
            },
        ],
        "irrigation_rules": [
            {
                "id": "irrigation.orange.nematode_sampling_after_irrigation",
                "title": "Sulama sonrası örnekleme zamanını doğru seç",
                "summary": "Nematod/kök örnekleri için sulamayı izleyen üçüncü gün daha uygundur; örnekler serin korunmalıdır.",
                "evidence": [
                    {
                        "source_id": "source.tagem.citrus_ipm",
                        "page": 12,
                        "section": "1.11. Nematodlar için örnekleme yöntemleri",
                        "evidence_text": "Kurulu bahçelerden örnek almak için en uygun zaman nisan-mayıs aylarıdır. Sulamayı izleyen üçüncü günde örneklerin alınması daha uygundur.",
                    }
                ],
            },
            {
                "id": "irrigation.orange.phytophthora_root_collar",
                "title": "Kök boğazını ıslak bırakma",
                "summary": "Phytophthora/kahverengi çürüklük riskinde drenaj ve kök boğazı su temasını önlemek ana kültürel önlemdir.",
                "evidence": [
                    {
                        "source_id": "source.tagem.citrus_ipm",
                        "page": 67,
                        "section": "1.41. Phytophthora — Mücadelesi",
                        "evidence_text": "Salma sulama yerine damla sulama tercih edilmeli, suyun kök boğazına değmesi engellenmelidir.",
                    }
                ],
            },
        ],
        "rule_engine_rules": [
            _rule(
                id="rule.orange.nutrition.leaf_soil_analysis_due",
                crop_id="crop.orange",
                category="soil_analysis",
                priority=72,
                conditions=[
                    {"field": "month", "operator": "in", "value": [9, 10]},
                    {"field": "has_recent_leaf_soil_analysis", "operator": "equals", "value": False},
                ],
                recommendations=[
                    "Eylül-ekim döneminde meyvesiz sürgünün uçtan 2-4. yapraklarından yaprak örneği alın.",
                    "0-30 cm toprak örneğini 8-10 farklı noktadan karıştırarak oluşturun.",
                    "Gübreleme önerisini analiz sonucuna göre planlayın.",
                ],
                evidence=[
                    {
                        "source_id": "source.tagem.citrus_ipm",
                        "page": 14,
                        "section": "1.16. Bitki besin elementleri",
                        "evidence_text": "Bir örnek, 20 da alanı temsil edecek şekilde 100 yaprak veya 50 g yaş ağırlıktaki yapraktan oluşmalıdır. Toprak örneklemesi yapılırken de bahçenin 8-10 farklı noktasından 0-30 cm derinlikten alınacak toprakların karıştırılmasıyla bir örnek oluşturulur.",
                    }
                ],
                explanation="Turunçgil gübreleme kararı yaprak ve toprak analizine bağlanır; doz uygulama önerisi analizsiz verilmez.",
            ),
            _rule(
                id="rule.orange.irrigation.phytophthora.root_collar_wet",
                crop_id="crop.orange",
                category="disease_risk",
                priority=83,
                conditions=[
                    {"field": "root_collar_wet", "operator": "equals", "value": True},
                    {"field": "recent_heavy_rain", "operator": "equals", "value": True},
                ],
                possible_problem_id="disease.orange.brown_rot",
                recommendations=[
                    "Kök boğazında zamk akıntısı ve alt meyvelerde kahverengi çürüklük belirtisini kontrol edin.",
                    "Drenajı iyileştirin; salma sulama yerine damla sulama tercih edin.",
                    "Suyun kök boğazına değmesini engelleyin.",
                ],
                evidence=[
                    {
                        "source_id": "source.tagem.citrus_ipm",
                        "page": 67,
                        "section": "1.41. Phytophthora — Mücadelesi",
                        "evidence_text": "Fidanlar derin dikilmemeli, aşı yerleri toprak üstünden en az 20 cm yukarıda bırakılmalıdır. ... Salma sulama yerine damla sulama tercih edilmeli, suyun kök boğazına değmesi engellenmelidir.",
                    }
                ],
                explanation="Phytophthora toprak/su sıçraması ve kök boğazı ıslaklığıyla ilişkilidir; kültürel önlem drenaj ve sulama biçimidir.",
                requires_bku_check=True,
            ),
        ],
        "missing_information": [
            "Turunçgilde ikincil hastalık/zararlıların tamamı ayrı v2 profiline açılmadı; mevcut kapsam uçkurutan, Phytophthora, unlubiti, kabuklubiti, Akdeniz meyvesineği ve analiz/sulama güvenlik kurallarıdır.",
            "test_cases — her rule_engine_rule için pozitif/negatif örnek girdiler eklenecek.",
        ],
    },
    "crop.tea": {
        "growth_stages": [
            {
                "key": "dormant_bud",
                "label_tr": "Dormant tomurcuk",
                "evidence": [
                    {
                        "source_id": "source.caykur.tea_cultivation_lecture_notes_2025",
                        "page": 21,
                        "section": "7.4.5. Çay sürgününün oluşum safhaları",
                        "evidence_text": "Tomurcuk dormant durumdan aktif duruma geçerken, sırası ile; Pulcuk (katafil), janam yaprak, balık yaprak ve normal yapraklar oluşur.",
                    }
                ],
            },
            {
                "key": "shoot_growth",
                "label_tr": "Sürgün gelişimi",
                "evidence": [
                    {
                        "source_id": "source.caykur.tea_cultivation_lecture_notes_2025",
                        "page": 22,
                        "section": "7.4.6. Sürgünlerin oluşumu ve gelişimi",
                        "evidence_text": "Çay Bitkisinde Sürgünlerin Oluşumu ve Gelişimi; genetik karakterine, bölge ekolojisine, kültürel uygulamalara ve toprak yapısına bağlı olarak farklılık gösterir.",
                    }
                ],
            },
            {
                "key": "harvest_flush",
                "label_tr": "Hasat sürgünü",
                "evidence": [
                    {
                        "source_id": "source.caykur.tea_cultivation_lecture_notes_2025",
                        "page": 22,
                        "section": "8. Hasat",
                        "evidence_text": "Yaş çay ürünü; çay bitkisi üzerindeki genç sürgünlerin ucundan itibaren, tepe tomurcuğu ve tepe tomurcuğunu takip eden birinci ve ikinci yapraktan müteşekkil, körpe, taze ve lif vermeyen ... filizden ibarettir.",
                    }
                ],
            },
        ],
        "fertilizer_rules": [
            {
                "id": "fertilizer.tea.soil_analysis_npk_balance",
                "title": "Toprak analizine göre N:P:K dengesi",
                "summary": "Çayda tek yönlü amonyum sülfat pH düşüşü ve potasyum kaybı oluşturabilir; analizle dengeli gübreleme gerekir.",
                "guardrail": "Toprak analizi olmadan net gübre miktarı verilmez.",
                "evidence": [
                    {
                        "source_id": "source.caykur.tea_cultivation_lecture_notes_2025",
                        "page": 13,
                        "section": "5. Çay Bitkisinin Toprak İstekleri",
                        "evidence_text": "Günümüzde ise üreticilerin yaptıracağı toprak analizleri sonucunda gerekli gübre miktarının toprağa verilmesinin daha uygun olduğu belirtilmektedir.",
                    },
                    {
                        "source_id": "source.caykur.tea_cultivation_lecture_notes_2025",
                        "page": 13,
                        "section": "5. Çay Bitkisinin Toprak İstekleri",
                        "evidence_text": "pH'daki düşüşün, asit karakterli amonyum sülfat gübresinin aşırı dozda ve tek yönlü kullanılmasından kaynaklandığını bildirilmektedirler.",
                    },
                ],
            },
        ],
        "irrigation_rules": [
            {
                "id": "irrigation.tea.rainfall_minimum",
                "title": "Yıllık yağış eşiği altında sulama gerekir",
                "summary": "Çayda vejetasyon boyunca düzenli yağış esastır; yıllık 1150 mm altı sulamayı zorunlu kılar, Türkiye koşullarında normal gelişme için 2000 mm ve düzenli dağılım bildirilmiştir.",
                "evidence": [
                    {
                        "source_id": "source.caykur.tea_cultivation_lecture_notes_2025",
                        "page": 12,
                        "section": "4.3. Çayın Yağış İsteği",
                        "evidence_text": "Genellikle yıllık 1800 mm, aylık ile 150 mm yağış alan çay alanlarında verimde sürekliliğin sağlandığı, yıllık yağışın 1150 mm den daha az olduğu yerlerde sulama yapılmasının zorunlu olduğu bildirilmektedir.",
                    }
                ],
            },
            {
                "id": "irrigation.tea.drainage_root_zone",
                "title": "90 cm kök bölgesinde su doygunluğu istemez",
                "summary": "Çay asit ve derin toprak ister; 90 cm kök bölgesi sürekli suya doygun olmamalıdır.",
                "evidence": [
                    {
                        "source_id": "source.caykur.tea_cultivation_lecture_notes_2025",
                        "page": 13,
                        "section": "5. Çay Bitkisinin Toprak İstekleri",
                        "evidence_text": "Köklerin serbestçe büyüyeceği derinlik en az 2 m olmalı, toprağın en az 90 cm derinlikteki kısmı su ile doygun durumda bulunmamalıdır.",
                    }
                ],
            },
        ],
        "rule_engine_rules": [
            _rule(
                id="rule.tea.irrigation.rainfall_below_1150",
                crop_id="crop.tea",
                category="irrigation",
                priority=82,
                conditions=[
                    {"field": "annual_rain_mm", "operator": "less_than", "value": 1150},
                ],
                recommendations=[
                    "Yıllık yağış 1150 mm altındaysa çayda sulama zorunlu kabul edilir.",
                    "Vejetasyon döneminde düzenli ve hafif yağış hedeflenir; hızlı ve aşırı yağış istenmez.",
                    "Sulama planını drenajla birlikte değerlendirin; kök bölgesini sürekli suya doygun bırakmayın.",
                ],
                evidence=[
                    {
                        "source_id": "source.caykur.tea_cultivation_lecture_notes_2025",
                        "page": 12,
                        "section": "4.3. Çayın Yağış İsteği",
                        "evidence_text": "Yıllık yağışın 1150 mm den daha az olduğu yerlerde sulama yapılmasının zorunlu olduğu bildirilmektedir.",
                    }
                ],
                explanation="Çay su ihtiyacı yıllık ve vejetasyon içi yağış düzenine bağlıdır; düşük yağışta sulama gerekir.",
            ),
            _rule(
                id="rule.tea.harvest.two_leaves_one_bud",
                crop_id="crop.tea",
                category="harvest_quality",
                priority=76,
                conditions=[
                    {"field": "shoot_stage", "operator": "equals", "value": "harvest_ready"},
                ],
                recommendations=[
                    "Hasatta tepe tomurcuğu + birinci ve ikinci körpe yaprak standardını koruyun.",
                    "Hasadı erken yapmak ürün miktarını azaltır; geç yapmak ürünü kartlaştırıp kaliteyi bozar.",
                    "Hasat sonrası ocakta yeterli olgun yaprak bırakın.",
                ],
                evidence=[
                    {
                        "source_id": "source.caykur.tea_cultivation_lecture_notes_2025",
                        "page": 22,
                        "section": "8. Hasat",
                        "evidence_text": "Hasatta iki yaprak bir tomurcuğun istenmesinin temel amacı, bu yaprakların, çayın kalitesini etkileyen unsurlar olan kafein ve polifenol kapsamlarının yüksek olmasının yanında, işleme için fiziksel yapılarının da çok uygun bulunmasıdır.",
                    }
                ],
                explanation="Çayda kalite, doğru sürgün standardı ve doğru hasat zamanına bağlıdır.",
            ),
        ],
        "missing_information": [
            "Çay için kaynaklı hastalık profili eklenmedi; ÇAYKUR kaynağı ekonomik boyutta hastalık/zararlı için kimyasal mücadele önermeyen kültürel yaklaşımı esas alıyor.",
            "weeds_v2[] — çay bahçelerinde kontrol edilen yabancı otlar ayrı profillere açılacak.",
            "test_cases — her rule_engine_rule için pozitif/negatif örnek girdiler eklenecek.",
            "Karadeniz Araştırma Enstitüsü ve Atatürk Çay Araştırma Enstitüsü kaynakları sources.json'a eklenmesi önerilir.",
        ],
    },
}


def _merge_by_id(base: list | None, extra: list | None) -> list:
    out = list(base or [])
    seen = {item.get("id") for item in out if isinstance(item, dict)}
    for item in extra or []:
        if not isinstance(item, dict):
            out.append(item)
            continue
        item_id = item.get("id")
        if item_id and item_id in seen:
            out = [
                item if isinstance(old, dict) and old.get("id") == item_id else old
                for old in out
            ]
        else:
            out.append(item)
            if item_id:
                seen.add(item_id)
    return out


def _with_completion(base: dict) -> dict:
    sid = base.get("stable_id")
    extra = PRIORITY_COMPLETIONS.get(sid, {})
    if not extra:
        return base
    merged = dict(base)
    for key, value in extra.items():
        if key in {"growth_stages", "fertilizer_rules", "irrigation_rules", "rule_engine_rules"}:
            merged[key] = _merge_by_id(merged.get(key), value)
        else:
            merged[key] = value
    return merged


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
        "crop.tomato": _with_completion(TOMATO_DATA),
        "crop.corn": _with_completion(CORN_DATA),
        "crop.sunflower": _with_completion(SUNFLOWER_DATA),
        "crop.orange": _with_completion(ORANGE_DATA),
        "crop.tea": _with_completion(TEA_DATA),
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
