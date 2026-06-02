# Tarlam — Infographic image-generation prompts

Three (+1 optional) ready-to-paste prompts to produce **Figure-1/2/3-quality colored
infographics** for the FENG 498 report. Paste into DALL·E / ChatGPT image / Gemini image /
Midjourney / Canva "Magic Media".

## How to use
- **DALL·E / ChatGPT / Gemini / Canva:** paste the whole prompt block (it can read full sentences + label lists).
- **Midjourney:** paste the prompt, then append the parameters line shown under each.
- After generating, the labels may render slightly garbled (image models misspell). If so, take
  the generated image into Canva/Figma/PowerPoint and **overlay the exact text labels** listed
  in each prompt's "EXACT TEXT" block — that guarantees a clean, examiner-ready figure.

## Shared style (every prompt repeats this so the 3 figures look like one set)
- Palette: deep agricultural green `#2E7D32`, light green `#E8F5E9`, soft mint `#C8E6C9`,
  warm amber accent `#F9A825`, neutral grey `#90A4AE`, near-white background `#F8FBF6`.
- Flat modern vector infographic, soft rounded cards, subtle long shadows, thin connector
  lines with arrowheads, generous whitespace, professional fintech/agritech style.
- 16:9 landscape, high resolution, crisp, presentation-grade.

---

## PROMPT 1 — Architecture Hero: "Bounded sensors → Deterministic core"  ★ primary

```
A clean, modern flat-vector infographic, 16:9 landscape, titled "Tarlam — Deterministic
Decision Core". Professional agritech style on a near-white background (#F8FBF6).

Left side: a friendly farmer icon with a smartphone, labelled "Farmer (offline-first, Turkish UI)".

A horizontal flow with arrows moving left to right.

CENTER (the visual hero, largest, glowing soft mint #C8E6C9 with a bold dark-green #2E7D32
border, slightly elevated with a soft shadow): a hexagon or rounded-square labelled
"DETERMINISTIC RULE ENGINE". Inside it, two small twin chips side by side labelled
"Dart (on-device)" and "Python (server)" connected by a small dashed amber link labelled
"behavioural parity".

TOP, feeding INTO the center with thin grey arrows: a row of small grey cards (neutral grey
#90A4AE) grouped under a faint dashed boundary labelled "Bounded External Sensors —
inputs only, never the decision": cards read "PlantNet", "Gemini Vision (severity %)",
"Imagga", "AgroMonitoring NDVI", "OpenWeatherMap", "SoilGrids". A small lock icon near them
labelled "key-isolating proxy".

RIGHT side, the engine outputs a single bold green arrow to a card stack labelled
"Result → Why? → To-do" with three small lines: a green check "Result", a lightbulb "Why?",
a checklist "To-do".

BOTTOM: a thin green data-flow ribbon reading
"official source → evidence-backed JSON → versioned rule pack → on-device engine →
explainable Turkish output".

Color palette: deep green #2E7D32, light green #E8F5E9, mint #C8E6C9, amber accent
#F9A825, grey #90A4AE. Flat vector, rounded cards, soft shadows, thin connector lines,
lots of whitespace, presentation-grade, crisp.
```
Midjourney params: `--ar 16:9 --style raw --v 6`

**EXACT TEXT (overlay these if the model misspells):**
Title: *Tarlam — Deterministic Decision Core*
Center: *DETERMINISTIC RULE ENGINE* · *Dart (on-device)* · *Python (server)* · *behavioural parity*
Sensors band: *Bounded External Sensors — inputs only, never the decision* · PlantNet · Gemini Vision (severity %) · Imagga · AgroMonitoring NDVI · OpenWeatherMap · SoilGrids · *key-isolating proxy*
Output: *Result → Why? → To-do*
Ribbon: *official source → evidence-backed JSON → versioned rule pack → on-device engine → explainable Turkish output*

---

## PROMPT 2 — Offline-First & Sync (phone ⇄ cloud, LWW outbox)

```
A clean, modern flat-vector infographic, 16:9 landscape, titled "Offline-First by Design".
Professional agritech style, near-white background (#F8FBF6), palette of deep green #2E7D32,
light green #E8F5E9, mint #C8E6C9, blue accent #4A90C2, grey #90A4AE.

LEFT: a large rounded device frame (smartphone) labelled "Android phone (~2 GB RAM)".
Inside it, stacked rounded cards in green tones: "SQLite (Drift)", "Hive cache",
"Dart Rule Engine", "292-crop dataset + rule packs". A bold badge over the phone reads
"WORKS WITH NO SIGNAL". A small grey wifi-off icon reinforces offline.

CENTER: a curved dashed arrow labelled "syncs only when online (≤10 s timeout)" connecting
the phone to the cloud. Along the arrow, a small queue/outbox icon labelled
"WorkManager outbox".

RIGHT: a cloud container labelled "FastAPI on Google Cloud Run (scale-to-zero)" with a small
database cylinder labelled "PostgreSQL + PostGIS". A small badge reads
"Last-Write-Wins (LWW)" with a tiny clock icon comparing two timestamps, one greyed out
labelled "stale → rejected".

BOTTOM caption strip in green: "Local-first storage + background outbox → core features never
freeze; conflicts resolved by timestamp."

Flat vector, rounded cards, soft shadows, thin connectors, generous whitespace, crisp,
presentation-grade.
```
Midjourney params: `--ar 16:9 --style raw --v 6`

**EXACT TEXT:**
Title: *Offline-First by Design*
Phone: *Android phone (~2 GB RAM)* · SQLite (Drift) · Hive cache · Dart Rule Engine · 292-crop dataset + rule packs · *WORKS WITH NO SIGNAL*
Arrow: *syncs only when online (≤10 s timeout)* · *WorkManager outbox*
Cloud: *FastAPI on Google Cloud Run (scale-to-zero)* · *PostgreSQL + PostGIS* · *Last-Write-Wins (LWW)* · *stale → rejected*
Caption: *Local-first storage + background outbox → core features never freeze; conflicts resolved by timestamp.*

---

## PROMPT 3 — Trust & Safety Guardrails (the ethical backbone)

```
A clean, modern flat-vector infographic, 16:9 landscape, titled "Safety Guardrails — Advice You
Can Trust". Professional agritech style, near-white background (#F8FBF6), palette of deep green
#2E7D32, light green #E8F5E9, amber #F9A825, warning red #D9534F (used sparingly), grey.

Layout: three vertical guardrail "lanes", each a tall rounded card with an icon at top, a
red-circle "blocked" state and a green "allowed" state.

LANE 1 — Fertilizer (icon: soil/NPK bag): top shows a red-crossed card "No exact dose without
a soil analysis"; below, a green card "With soil analysis → bounded, source-backed guidance".

LANE 2 — Plant protection / BKÜ (icon: spray bottle): red-crossed card "Never names a
commercial product"; green card "Active ingredient only + mandatory redirect to bku.tarim.gov.tr".

LANE 3 — Disease diagnosis (icon: magnifier on leaf): red-crossed card "Never says 'this is
definitely X'"; green card "Probabilistic + evidence list + 'requires expert confirmation'".

ACROSS THE TOP, a banner: "No hallucinations: every output is sourced, reproducible and
explainable." A small amber shield icon sits on the banner.

BOTTOM: a thin strip "Missing inputs → confidence lowered + 'missing_information', never
confident-but-wrong."

Flat vector, rounded cards, soft shadows, clear icons, professional, crisp, presentation-grade.
```
Midjourney params: `--ar 16:9 --style raw --v 6`

**EXACT TEXT:**
Title: *Safety Guardrails — Advice You Can Trust*
Banner: *No hallucinations: every output is sourced, reproducible and explainable.*
Lane 1: *Fertilizer* — *No exact dose without a soil analysis* / *With soil analysis → bounded, source-backed guidance*
Lane 2: *Plant protection (BKÜ)* — *Never names a commercial product* / *Active ingredient only + mandatory redirect to bku.tarim.gov.tr*
Lane 3: *Disease diagnosis* — *Never says "this is definitely X"* / *Probabilistic + evidence list + "requires expert confirmation"*
Bottom: *Missing inputs → confidence lowered + "missing_information", never confident-but-wrong.*

---

## PROMPT 4 (optional) — FAO-56 Smart Irrigation Pipeline

```
A clean, modern flat-vector infographic, 16:9 landscape, titled "Standards-Based Irrigation
(FAO-56)". Agritech style, near-white background, palette deep green #2E7D32, light green
#E8F5E9, blue #4A90C2 for water, amber #F9A825.

A left-to-right pipeline of 5 rounded step-cards connected by arrows:
1) "ETo — FAO-56 Penman–Monteith" (weather icon)
2) "ETc = Kc × ETo" (crop icon, Kc from FAO-56 Table 12)
3) "Effective rain = 0.8 × forecast" (rain cloud icon)
4) "Net need = ETc − effective rain" (calculator icon)
5) a decision diamond "Soil moisture below threshold?" branching to a green "IRRIGATE"
   card and a blue "SKIP" card.

To the right, a small 14-day bar chart labelled "14-day irrigate/skip plan" with green and
blue bars (reuse the existing Figure-3 chart style).

Bottom caption: "A physical, standards-traceable calculation — not a heuristic."

Flat vector, rounded cards, soft shadows, thin connectors, crisp, presentation-grade.
```
Midjourney params: `--ar 16:9 --style raw --v 6`

**EXACT TEXT:**
Title: *Standards-Based Irrigation (FAO-56)*
Steps: *ETo — FAO-56 Penman–Monteith* → *ETc = Kc × ETo* → *Effective rain = 0.8 × forecast* → *Net need = ETc − effective rain* → *Soil moisture below threshold?* → *IRRIGATE* / *SKIP*
Right: *14-day irrigate/skip plan*
Caption: *A physical, standards-traceable calculation — not a heuristic.*

---

## Recommended figure placement in the report
| Infographic | Report section | Suggested figure no. |
|-------------|----------------|----------------------|
| 1 Architecture Hero | §1 Introduction (high-level architecture) or replace Fig 1 | Figure 1 (hero) |
| 2 Offline-First & Sync | §3.3 Suggested Design / §3.4.2 risk | Figure 4 |
| 3 Trust & Safety Guardrails | §2.2 or §3.5.2 (standards/safety) | Figure 5 |
| 4 FAO-56 Irrigation (optional) | §3.5.1 (a) | replaces/【pairs with】Figure 3 |

> Tip for consistency: generate all from the **same tool in one session** so the visual style
> matches. Then drop them into Word as PNG (export at the highest resolution the tool offers).
> Keep the technical draw.io diagrams (Fig 6–14) for the UML/appendix sections — infographics
> are for the "hero" / explanatory slots, UML is for the rigorous slots. A strong report uses both.
