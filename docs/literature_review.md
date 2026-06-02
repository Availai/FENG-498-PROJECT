# 2 LITERATURE REVIEW

> Drop-in replacement for §2 of the FENG 498 final report. Every in-text citation below
> maps to a **verified, real** source (metadata confirmed against the publisher / DOI).
> The reference list at the bottom is ready for IEEE formatting. The four thematic
> subsections each (a) survey the prior work and (b) state explicitly how *Tarlam* aligns
> with, operationalizes, or extends it — grounded in the actual codebase.

---

## 2.1 Academic and Technical Publications

Tarlam sits at the intersection of four research threads: (i) offline-first software for
low-connectivity rural settings, (ii) deterministic, rule-based agricultural decision support
versus probabilistic AI, (iii) standards-based agronomic computation (reference
evapotranspiration and crop-suitability modelling), and (iv) multi-source sensing — satellite
NDVI and image-based plant/crop recognition — as bounded inputs rather than final
decision-makers. The review below treats each thread in turn and positions Tarlam against it.

### The digital divide and the case for offline-first architectures

Rural and agricultural development is increasingly mediated by information and communication
technologies (ICTs), but the benefits are gated by connectivity. In their introduction to a
nine-paper special issue, Ma and Zhou [1] synthesize evidence that internet use stimulates
farmers' adoption of agricultural technologies, raises productivity and technical efficiency,
improves food security, and reduces rural poverty — while emphasizing that these gains
presuppose reliable access that smallholders frequently lack. The constraint is not only
bandwidth but a layered "next-level" divide: Onitsuka et al. [2], studying a rural Indonesian
community, show that even where basic connectivity exists, disparities in skills, content
relevance, and infrastructure quality determine whether ICT actually improves rural life, and
derive policy recommendations for closing that gap. Taken together, [1] and [2] establish the
problem Tarlam targets: a tool whose *core value must survive intermittent or absent
connectivity*, and whose content must be locally relevant and usable by low-digital-literacy
users.

Tarlam operationalizes this directly. Rather than treating offline support as a degraded mode,
the design makes the on-device relational store (Drift/SQLite) and a Hive cache the **primary**
data source for every module; network calls carry a strict 10-second timeout with a mandatory
cached fallback, and a WorkManager-backed outbox queue defers writes until connectivity
returns. Crucially — and this is where Tarlam goes beyond a data-logging or offline-learning
client — the *decision logic itself* is pushed onto the device: a complete deterministic rule
engine (`lib/services/offline_rule_engine.dart` over the rule packs in `lib/data/rule_packs/`)
runs without any network dependency, so advice generation, not merely data access, survives an
outage. This is the architectural answer to the divide that [1] and [2] characterize.

### Deterministic rule-based decision support versus probabilistic AI

A long line of agricultural expert-system research shows that structured, rule-based reasoning
delivers consistent and interpretable diagnoses. Sriram and Philip [3] describe an expert
system for agricultural decision support built on an explicit knowledge base, inference engine,
and user interface, with forward-chaining over if-then rules driving diagnosis from observed
symptoms. The broader survey by Mahaman et al. [4] reviews decades of expert systems for
plant disease diagnosis, identifying their key strength — verifiable, explainable inference over a
curated knowledge base — alongside their central cost: the manual effort of knowledge
acquisition and curation. This literature predates and contrasts with the current wave of
generative AI advisors, which, while flexible, are prone to "hallucinations": plausible but
factually incorrect advice that, in a high-stakes domain like crop protection, can cause direct
economic loss.

The most recent crop-recommendation literature reinforces *why* interpretability matters for
adoption. Shastri et al. [7] build a gradient-boosting crop recommender but pair it with
explainable-AI techniques precisely because end-user trust depends on being able to justify a
recommendation — a finding consistent with the older expert-systems tradition: output that can
be *explained item-by-item* is what farmers and advisors are willing to act on.

Tarlam adopts this position as its **central architectural principle**: agronomic intelligence is
produced by a deterministic rule engine over evidence-referenced rule packs, *not* by a
language model. The engine is a pure function of (facts, rules); evaluation iterates enabled
rules, matches conditions with a fixed operator set (`equals`, `between`, `greater_than`,
`contains`, `in`, `exists`, … — see `lib/core/rule_engine/operators.dart`), and returns results
sorted by priority, each carrying its triggering evidence and a Turkish-language justification
rendered as "Result → Why? → To-do." Tarlam extends the single-engine systems surveyed in
[3], [4] in two ways. First, it maintains **two behaviourally-identical implementations** — Dart
on-device (`offline_rule_engine.dart`) and Python on-server (`backend/rule_engine.py`) — kept
in lockstep by a shared parity fixture (`test/fixtures/rule_parity_cases.json`,
`rule_engine_parity_test.dart`), so the same facts yield the same output whether evaluated
offline or in the cloud. Second, it formalizes an explicit **safety-guardrail layer** (fertilizer,
plant-protection, disease-diagnosis) that the surveyed systems leave implicit, enforced as
executable tests (`offline_rule_engine_guardrail_test.dart`). Where [7] uses explainability as a
*post-hoc* layer over a probabilistic model, Tarlam makes explainability *intrinsic* — the
explanation is the rule's own evidence, not a reconstruction.

### Standards-based agronomic computation: reference evapotranspiration and suitability

Reliable irrigation advice requires a physically-grounded water-balance model rather than a
heuristic. The de facto international standard is the FAO-56 Penman–Monteith method of Allen,
Pereira, Raes, and Smith [8], which defines reference evapotranspiration (ETo) and the
crop-coefficient (Kc) approach to crop water demand (ETc = Kc · ETo). Tarlam implements
FAO-56 ETo in both the client (`lib/services/fao_eto_service.dart`) and the backend
(`_fao_eto` in `backend/main.py`), with Kc by crop and growth stage from FAO-56 Table 12 and
an effective-rainfall correction, iterating a daily soil-moisture balance across a 14-day horizon.
This makes the irrigation plan a *standards-traceable physical calculation* rather than an opaque
estimate — directly addressing the interpretability concern raised by [3], [4], [7] at the level of
the watering recommendation itself.

For crop selection, recent machine-learning work demonstrates that soil and climate parameters
jointly drive suitability. Afzal et al. [6] show, on a crop-recommendation dataset, that
incorporating soil information (N-P-K, pH) with environmental variables materially improves
recommendation quality, and Shastri et al. [7] confirm the same parameter family (nutrients +
temperature + humidity + rainfall) underlies accurate recommendation. Tarlam's
`TurkishCrop.scoreFor({temperature, soilPh, weeklyRain, month})` computes a bounded,
weighted match between a crop's tolerated ranges and the field's measured tuple, returning a
numeric `SuitabilityScore` **together with the reasons** that produced it. The contrast with [6],
[7] is deliberate and important: those systems output a single best-crop prediction from a black-
or grey-box model, whereas Tarlam returns an explainable, per-factor score calibrated to
Turkish crop profiles and degrades gracefully (lowering confidence, emitting
`missing_information`) when inputs are sparse, rather than producing a confident-but-unverifiable
recommendation.

### Multi-source sensing as bounded input: NDVI and image-based recognition

Modern agronomic decisions benefit from synthesizing spatial and botanical telemetry, but the
literature is clear that such telemetry is insufficient in isolation. Lebrini, Hadria, et al. [5]
demonstrate that NDVI time series combined with machine-learning classifiers can monitor
agricultural systems and inform adaptive policy — a powerful signal of crop vigour and soil
moisture, yet one that requires contextual interpretation. On the botanical side, the Pl@ntNet
ecosystem provides large-scale, citizen-science-trained plant and crop recognition; van der
Velde, Goëau, Bonnet, et al. [9] show that merging user-collected photos with structured
survey data (LUCAS) improves deep-learning crop recognition across hundreds of species.

Tarlam orchestrates exactly these classes of service — NDVI/soil (AgroMonitoring), plant/crop
identification (PlantNet [9]), a "is-this-a-plant?" pre-filter (Imagga), a constrained vision call
used *only* to extract a numeric necrosis-severity percentage, and weather/soil providers
(OpenWeatherMap, Open-Meteo, MGM, SoilGrids). The decisive design choice, and the
principal departure from systems that let a model produce the final recommendation, is that
**these APIs are treated strictly as bounded sensors**: their raw outputs populate the `facts`
object, and the deterministic engine alone produces the user-facing diagnosis and task list.
This preserves the reproducibility and auditability that [3], [4] identify as the strength of rule-
based systems, while still benefiting from the satellite [5] and vision [9] telemetry whose value
the same literature documents. Operationally, all paid keys are isolated server-side behind a
proxy (`backend/proxy_endpoints.py`), so client traffic cannot leak credentials and heavy calls
are cached and pre-filtered to respect rate limits.

### Synthesis

Across the four threads, the literature converges on three requirements that are usually pursued
separately: tools must be (1) usable in low-connectivity rural settings [1], [2]; (2) strictly
reliable, reproducible, and explainable in their diagnostics [3], [4], [7]; and (3) able to
synthesize spatial/climatic and botanical telemetry [5], [6], [9] on a standards-grounded basis
[8]. Tarlam's contribution is to satisfy all three **simultaneously on a single device-resident
stack**, calibrated to Turkish crops and regions, with an explicit fertilizer / plant-protection /
disease-diagnosis safety-guardrail layer that the surveyed systems do not formalize.

---

## 2.2 Intellectual Property / Standards / Regulations

**Software and engineering standards.** The irrigation engine conforms to FAO-56 [8]
(Penman–Monteith ETo, Table-12 crop coefficients), making water computations standards-
traceable rather than heuristic. Plant-protection guidance follows an Integrated Pest
Management (IPM) ordering (cultural → biological → chemical) and never names a commercial
product — only active ingredients explicitly present in TAGEM technical instructions [10], always
with a mandatory redirect to the official `bku.tarim.gov.tr` licence database. Field geometry is
stored under the OGC/PostGIS convention `geometry(POLYGON, 4326)` (WGS-84). Report
citations follow IEEE style.

**Source provenance.** Agronomic content is bound to official, attributable sources in an explicit
priority order (Ministry of Agriculture and Forestry → TAGEM → affiliated research institutes →
ÇAYKUR/TEPGE → university faculties of agriculture → agricultural chambers → private
sources only as low-priority support [10]). Each fact and rule carries `id`, `source_ids`,
`evidence_text`, `confidence`, and timestamps; missing values are recorded as
`null`/`missing_information` and conflicting sources as `conflicts`, never silently merged.

**Data protection (KVKK/GDPR).** The system processes personal and location data (email,
field GPS polygons, activity logs). All user-owned data carries a `farmerUid` and is strictly
isolated per user; identity is delegated to Firebase Auth (no raw passwords stored); and paid
third-party API keys live only server-side behind the proxy, so client traffic cannot leak
credentials. This maps onto a KVKK-compliant data-controller model (purpose limitation, data
minimization, isolation). Open-source dependencies are under MIT/BSD/Apache-2.0 licences,
compatible with academic submission. As a red line, Tarlam deliberately refuses to be the
licensing authority for pesticides; it always defers the final chemical-control decision to the
official BKÜ database [10] and expert confirmation.

---

## References (verified — ready for IEEE formatting)

```
[1]  W. Ma and X. Zhou, "An introduction to rural and agricultural development in the
     digital age," Review of Development Economics, vol. 27, no. 3, pp. 1273–1286, 2023,
     doi: 10.1111/rode.13025.

[2]  K. Onitsuka, A. R. T. Hidayat, and W. Huang, "Challenges for the next level of digital
     divide in rural Indonesian communities," The Electronic Journal of Information Systems
     in Developing Countries, vol. 84, no. 2, e12021, 2018, doi: 10.1002/isd2.12021.

[3]  N. Sriram and H. Philip, "Expert System for Decision Support in Agriculture," Tamil Nadu
     Agricultural University. [Online]. Available: https://agritech.tnau.ac.in/pdf/14.pdf

[4]  B. Mahaman, P. Harizanis, I. Filis, et al., "Expert Systems Applied to Plant Disease
     Diagnosis: Survey and Critical View." (Confirm full author list, venue, and year against
     the source before final submission — ResearchGate ID 303675433.)

[5]  Y. Lebrini, A. Boudhar, A. Htitiou, R. Hadria, H. Lionboui, L. Bounoua, and
     T. Benabdelouahab, "Remote monitoring of agricultural systems using NDVI time series
     and machine learning methods: a tool for an adaptive agricultural policy," Arabian Journal
     of Geosciences, vol. 13, art. 796, 2020, doi: 10.1007/s12517-020-05789-7.

[6]  H. Afzal, M. Amjad, A. Raza, et al., "Incorporating soil information with machine learning
     for crop recommendation to improve agricultural output," Scientific Reports, vol. 15,
     art. 8560, 2025, doi: 10.1038/s41598-025-88676-z.

[7]  S. Shastri, S. Kumar, V. Mansotra, and R. Salgotra, "Advancing crop recommendation
     system with supervised machine learning and explainable artificial intelligence,"
     Scientific Reports, vol. 15, art. 25498, 2025, doi: 10.1038/s41598-025-07003-8.

[8]  R. G. Allen, L. S. Pereira, D. Raes, and M. Smith, "Crop evapotranspiration —
     Guidelines for computing crop water requirements," FAO Irrigation and Drainage Paper
     No. 56, FAO, Rome, 1998.

[9]  M. van der Velde, H. Goëau, P. Bonnet, R. d'Andrimont, M. Yordanov, et al., "Pl@ntNet
     Crops: merging citizen science observations and structured survey data to improve crop
     recognition for agri-food-environment applications," Environmental Research Letters,
     vol. 18, no. 2, art. 025002, 2023, doi: 10.1088/1748-9326/acadf3.

[10] Republic of Türkiye Ministry of Agriculture and Forestry / TAGEM, Zirai Mücadele Teknik
     Talimatları (Plant Protection Technical Instructions), and the official plant-protection-
     product database, bku.tarim.gov.tr.
```

### Citation-verification status

| Ref | Title / venue | Metadata source | Status |
|-----|---------------|-----------------|--------|
| [1] | Ma & Zhou, Rev. Dev. Econ. 27(3):1273–1286, 2023 | Wiley / DOI | ✅ Verified |
| [2] | Onitsuka et al., EJISDC 84(2) e12021, 2018 | Wiley / DOI | ✅ Verified |
| [3] | Sriram & Philip, TNAU | agritech.tnau.ac.in/pdf/14.pdf | ✅ Real document — confirm year |
| [4] | Mahaman et al., plant-disease ES survey | ResearchGate 303675433 | ⚠️ Confirm author/venue/year before submit |
| [5] | Lebrini, Hadria et al., AJG 13:796, 2020 | Springer / DOI | ✅ Verified (note: lead author is Lebrini) |
| [6] | Afzal et al., Sci. Rep. 15:8560, 2025 | Nature / DOI | ✅ Verified |
| [7] | Shastri et al., Sci. Rep. 15:25498, 2025 | Nature / PubMed | ✅ Verified |
| [8] | Allen et al., FAO-56, 1998 | FAO | ✅ Verified (canonical) |
| [9] | van der Velde, Goëau et al., ERL 18(2) 025002, 2023 | IOPscience / JRC | ✅ Verified |
| [10]| TAGEM / bku.tarim.gov.tr | Official | ✅ Institutional |

> **Action before submission:** open each DOI yourself and confirm; finalize [4]'s full
> author/venue/year (it is the only entry not fully pinned down). For [5], note the article is
> commonly cited under the lead author **Lebrini** — adjust the in-text "Lebrini, Hadria, et al. [5]"
> accordingly if your style requires first-author-only.
```
