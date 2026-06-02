# Tarlam report diagrams — draw.io

**6 separate files** (one diagram each — open any one directly, no tabs confusion):

| File | Report slot | Figure |
|------|-------------|--------|
| `fig4_usecase_user.drawio` | §3 "Use Case Diagram" (1st `[Paste here]`) | Figure 4 |
| `fig5_usecase_admin.drawio` | §3 "Use Case Diagram" (2nd `[Paste here]`) | Figure 5 |
| `fig6_class.drawio` | §3.5 Class Diagram `[Paste here]` | Figure 6 |
| `fig7_er.drawio` | Appendix D / §3.5 ER | Figure 7 |
| `fig8_seq_offline.drawio` | §3.5 Sequence (a) offline | Figure 8 |
| `fig9_seq_online.drawio` | §3.5 Sequence (b) online orchestration | Figure 9 |

> (Figure 3 — irrigation activity flow — you already have as an infographic, so I did not redo it.)

### Distinguished set — diagrams that carry the *thesis* (recommended additions)

The six above are the **required/standard** set (structure). These four argue the *architecture*
— add them where noted to lift the report from "complete" to "senior-engineer".

| File | Where to use | Figure | Why it matters |
|------|--------------|--------|----------------|
| `fig11_c4_container.drawio` | §1 / §3.5 (replace or pair with Fig 1) | Figure 11 | C4 container view: deterministic engine at the centre, sensors bounded — the actual architectural argument, not an inventory |
| `fig12_deployment.drawio` | §3.5.4 / §3.3 | Figure 12 | UML deployment: proves offline-first (NFR-1) + serverless (NFR-5) physically |
| `fig13_sync_state_machine.drawio` | §3.4.2 (risk) / §3.5 | Figure 13 | SyncJob LWW state machine: realises NFR-6 + the sync-conflict mitigation in Table 3.3 |
| `fig14_activity_evaluate.drawio` | §3.5.3 (next to pseudocode) | Figure 14 | `evaluate()` activity flow: shows determinism + guardrail flags at algorithm level |

All four were verified against real code (`rule_engine.py` `analyze()`/`_validate_env`,
`_upsert_sync_record`, `proxy_endpoints.py`, schema v11).

## Open  (IMPORTANT — open the file, do NOT paste XML)
1. Go to **https://app.diagrams.net** (or the VS Code "Draw.io Integration" extension).
2. **File → Open From → Device** → pick a `figN_*.drawio` file. The diagram loads directly.
3. Open each of the 6 files the same way (separate files = no missing pages).

> ⚠️ Do **not** use *Extras → Edit Diagram* and paste the whole XML — that loader only reads one
> `<diagram>` and silently drops the rest. Always **open the file**.

## Tweak (it's all editable — nothing is locked)
- Drag any box; arrows follow automatically.
- Double-click a box/edge to edit its text.
- Colours follow the Tarlam palette: **green `#2E7D32`** = Tarlam-owned/deterministic,
  **yellow `#F9A825`** = rule-engine domain, **grey `#90A4AE`** = external/bounded sensor.
- If a use-case page feels cramped, select all (Ctrl+A) → **Arrange → Layout → Vertical Tree**.

## Export — HARİKA clarity (do this per tab)
**File → Export as → SVG…** → uncheck "include a copy of my diagram", check **Transparent
Background** → Export. Insert the SVG in Word via *Insert → Pictures → This Device*. SVG is
vector → razor-sharp at any zoom and in the final PDF.

If your Word build refuses SVG: **File → Export as → PNG…**, set **Zoom 300%** (or DPI 300),
transparent background. That PNG is print-quality.

## Carmack rules these follow
- One flow direction per diagram; no decorative boxes.
- The thesis is visually unmissable in Fig8/Fig9: the **green deterministic engine** is the only
  thing that emits user-facing output; grey sensors only feed `facts`.
- All entities/fields are **real** (verified against `app_database.dart` schema v11, `rule_engine.py`,
  `proxy_endpoints.py`) — an examiner can grep the repo and find every name.
