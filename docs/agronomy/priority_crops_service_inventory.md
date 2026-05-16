# 5 Ana Ürün — Servis Bağlantı Envanteri

CLAUDE.md §11 öncelikli 5 ürünün (`crop.sunflower`, `crop.corn`,
`crop.tomato`, `crop.orange`, `crop.tea`) Tarlam servisleri ve veri
katmanları içindeki kapsama durumu. Bu rapor gübre, ilaç, sulama,
hastalık/zararlı ve takvim tavsiyelerinin **doğru anda doğru yerde**
verildiğinden emin olmak için çıkartıldı.

**Son güncelleme:** 2026-05-16

## Kapsam Matrisi

| Katman | Ayçiçeği | Çay | Portakal | Mısır | Domates |
|---|---|---|---|---|---|
| `CropRegistry` (stable_id) | ✅ | ✅ | ✅ | ✅ | ✅ |
| `CropPlaybook` (gübre/ilaç/su) | ✅ | ✅ | ✅ | ✅ | ✅ |
| `CropProtocol` (tek yıllık adım takvimi) | ✅ | — N/A | — N/A | ✅ | ✅ |
| `TurkiyeCropGuides` (rehber) | ✅ | ✅ | ✅ | ✅ | ✅ |
| `verified_advisor_service` name→stable_id | ✅ | ✅ | ✅ | ✅ | ✅ |
| `CropPlaybooks` ile UI bağlantısı (activity_quick_log) | ✅ | ✅ | ✅ | ✅ | ✅ |
| Declarative Rule Pack (BKÜ guardrail'li kurallar) | ✅ `SunflowerRulePack` | ❌ | ❌ | ❌ | ❌ |
| IPM Decision Service (kimyasal karar kapısı) | ✅ `SunflowerIpmRules` | ❌ | ❌ | ❌ | ❌ |
| Lifecycle ayrımı (UI'da tek yıllık vs çok yıllık) | ✅ tek yıllık | ✅ çok yıllık | ✅ çok yıllık | ✅ tek yıllık | ✅ tek yıllık |

**Notlar:**
- "N/A" → çok yıllık ürünler için `CropProtocol`'ün "120 günlük adım"
  modeli mantıken uygulanamaz; bu ürünler için `CropPlaybook` + her yıl
  tekrarlayan hasat penceresi (`harvest_months`) kullanılır.
- Aktivite kaydında (`activity_quick_log.dart`) gübre + ilaç picker'ları
  `_playbook != null` koşuluyla açılır; bu yüzden Portakal ve Çay için de
  picker'lar otomatik aktiftir.

## Mevcut Boşluklar

### Boşluk 1: Declarative rule pack
**Etki:** Sadece ayçiçeği için BKÜ guardrail'li, kanıtlı ve sürümlü
deterministik kurallar var. Diğer 4 ürünün IPM/sulama/gübreleme uyarıları
playbook tablolarından geliyor — bu da geçerli bilgidir ama "neden bu
öneri" gerekçesinin kaynak-evidence'a bağlanması için rule pack şart.

**Yol haritası referansı:** `docs/agronomy/sunflower_rule_pack_plan.md`
şablonu Mısır, Domates, Portakal, Çay için tekrarlanabilir.

### Boşluk 2: IPM Decision Service
**Etki:** `IpmDecisionService.supports()` ana 5 üründen sadece ayçiçeği
için `true` döner. Diğer 4 ürün aktivite kaydında "kimyasal kapısı"
(IPM gate) olmadan doğrudan picker görür. Playbook'taki PHI bilgisi
otomatik gösterilir ama önce kültürel/biyolojik mücadeleyi öneren
karar mantığı yok.

**Hafifletici unsur:** `CropPlaybook.pesticides` listesi BKÜ kontrolü
yönlendirmesi ve PHI bilgisi içerir (CLAUDE.md §17 uyumlu). Yani
çiftci yanlış bilgi almıyor — sadece IPM öncelik sıralaması zorlanmıyor.

### Boşluk 3: `disease_diagnosis_service` ürün farkındalığı
**Etki:** Servis hastalık ön tanı yapıyor ama ürün-spesifik
"semptom × ürün" eşleşmeleri yok. Bunun rule pack genişletmesiyle
çözülmesi planlı (`possible_problem_id: disease.tomato.botrytis` gibi).

## Sonraki Adımlar (Öncelik Sıralı)

1. **Çay rule pack** (`tea_rule_pack.dart`) — sadece 1 üretim bölgesi
   (Doğu Karadeniz), kültürel + biyolojik mücadelenin baskın olduğu,
   ÇAYKUR materyalleri yoğun. En düşük riskle başlanabilir.
2. **Portakal rule pack** (`orange_rule_pack.dart`) — TAGEM Turunçgil
   Entegre Mücadele Teknik Talimatı temelli.
3. **Mısır rule pack** (`corn_rule_pack.dart`) — koçan kurdu, mısır kurdu,
   yaprak hastalıkları.
4. **Domates rule pack** (`tomato_rule_pack.dart`) — CLAUDE.md §14
   örnek kuralı (botrytis × yüksek nem) burada hayata geçer.
5. **`IpmDecisionService`** her ürün için kültürel → biyolojik → kimyasal
   sıralı karar fonksiyonu döndürecek şekilde genişletilir.

Her rule pack için `docs/agronomy/sunflower_rule_pack_plan.md` şablonunu
takip edin: source extraction → JSON schema validation → uzman kontrolü
→ versioned pack → test case'ler.
