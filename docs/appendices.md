# APPENDICES

> Drop-in content for the FENG 498 final report. Every item below was extracted from the
> **actual codebase** (schema v11 in `lib/data/app_database.dart`, endpoints in
> `backend/main.py` + `backend/proxy_endpoints.py`, the test tree under `test/`). Where the
> report's earlier text disagreed with the code, the code wins — discrepancies are flagged.
>
> Each appendix below is meant to be pasted into the report; UML diagrams (App. A) are given
> as mermaid sources you render to PNG/SVG (see `final_report_references_and_diagrams.md`).

---

## Appendix A — Detailed UML Diagrams

Render the mermaid sources from `docs/final_report_references_and_diagrams.md` (§2) and paste
the exported PNG/SVG here. The set:

| Figure | Diagram | Source location |
|--------|---------|-----------------|
| A.1 | Use-case — User (Sign Up/In, Manage Fields, Suitability, Irrigation, Weather Alert, Disease Diagnosis, Treatment Task; «External APIs & DB» actor) | §2.1 mermaid |
| A.2 | Use-case — Admin (Sign In, Manage Accounts, API Traffic, Update Encyclopedia, Broadcast, Telemetry) | §2.2 mermaid |
| A.3 | Class diagram — entities + engine + services | §2.3 mermaid |
| A.4 | ER diagram — Drift v11 (client) + PostGIS (server) | §2.4 mermaid |
| A.5 | Sequence — offline disease assessment | §2.5 mermaid |
| A.6 | Sequence — online multi-API orchestration → deterministic diagnosis → sync | §2.6 mermaid |
| A.7 | Activity — FAO-56 14-day irrigation decision (this is report Figure 3) | §2.7 mermaid |

> Tooling note for the report: "UML sources authored in mermaid; rendered with mermaid.live;
> editable `.mmd` sources committed under `docs/`."

---

## Appendix B — Test Case Tables

**Totals (verified):** `flutter test` discovers **272 test cases across 50 test files** under
`test/`, plus backend `pytest` suites. (Count confirmed by enumerating `test(` / `testWidgets(`
declarations — 272 exactly, matching the report.)

### B.1 Client test suite (`flutter test`) — by area

| # | Test file | Area / purpose |
|---|-----------|----------------|
| 1 | `test/services/rule_engine_parity_test.dart` | **Parity** — Dart engine ≡ Python engine for identical facts |
| 2 | `test/services/offline_rule_engine_test.dart` | Core offline engine evaluation, operator matching, priority sort |
| 3 | `test/services/offline_rule_engine_guardrail_test.dart` | **Guardrails** — no fertilizer dose without soil analysis; no chemical advice without BKÜ check |
| 4 | `test/services/fao_eto_service_test.dart` | FAO-56 Penman–Monteith ETo correctness |
| 5 | `test/services/irrigation_service_test.dart` | Irrigation scheduling (ETc, effective rain, net need) |
| 6 | `test/services/irrigation_cost_engine_test.dart` | Water-budget / cost accounting |
| 7 | `test/services/water_balance_engine_test.dart` | Daily soil-moisture balance over horizon |
| 8 | `test/services/water_accounting_test.dart` | Water bookkeeping aggregation |
| 9 | `test/services/crop_general_rules_test.dart` | Cross-crop general rule correctness |
| 10 | `test/services/sunflower_rules_test.dart` | Sunflower rule pack |
| 11 | `test/services/wheat_rules_test.dart` | Wheat rule pack |
| 12 | `test/data/crop_ipm_rules_test.dart` | IPM (cultural→biological→chemical) ordering |
| 13 | `test/services/ipm_rule_runner_test.dart` | IPM rule runner |
| 14 | `test/services/crop_rotation_advisor_test.dart` | Crop-rotation logic |
| 15 | `test/services/disease_diagnosis_service_test.dart` | Probabilistic disease assessment + `requires_expert_confirmation` |
| 16 | `test/services/yield_calculation_service_test.dart` | Yield estimation |
| 17 | `test/services/harvest_shift_estimator_test.dart` | Harvest-date estimation |
| 18 | `test/services/soil_fertilization_service_test.dart` | Soil-gated fertilization guidance |
| 19 | `test/services/fertilizer_dose_calculator_test.dart` | Dose calculator (guardrailed) |
| 20 | `test/services/growth_engine_test.dart` | GDD / phenology growth engine |
| 21 | `test/services/crop_state_service_test.dart` | Crop state (seedling/mature) resolution |
| 22 | `test/services/timing_window_test.dart` | Operation timing windows |
| 23 | `test/services/sync_service_test.dart` | Outbox + LWW orchestration |
| 24 | `test/services/repositories/sync_repository_test.dart` | Sync repository persistence |
| 25 | `test/services/api/sync_api_client_test.dart` | Sync API client (push/pull) |
| 26 | `test/services/repositories/weather_repository_test.dart` | Weather repo cache/fallback |
| 27 | `test/services/daily_guide_engine_weather_test.dart` | Daily-guide weather rules |
| 28 | `test/services/guide_engine_weather_test.dart` | Guide engine weather integration |
| 29 | `test/services/live_todo_service_test.dart` | Live to-do generation |
| 30 | `test/services/task_directive_service_test.dart` | Task directive engine |
| 31 | `test/services/alert_journal_service_test.dart` | Alert journaling |
| 32 | `test/services/recommendation_channels_test.dart` | Recommendation routing |
| 33 | `test/services/recommendation_triage_test.dart` | Recommendation prioritization |
| 34 | `test/services/verified_advisor_service_test.dart` | Verified advisor flow |
| 35 | `test/services/agri_sim_service_test.dart` | Agronomic simulation |
| 36 | `test/services/crop_schedule_seeder_test.dart` | Seed-to-harvest calendar seeding |
| 37 | `test/services/crop_daily_plan_test.dart` | Daily plan generation |
| 38 | `test/services/field_state_service_test.dart` | Field state aggregation |
| 39 | `test/services/crop_placement_test.dart` | In-field crop placement |
| 40 | `test/services/weather_soil_models_test.dart` | Weather/soil model parsing |
| 41 | `test/data/crop_setup_scenario_test.dart` | End-to-end crop setup scenario |
| 42 | `test/data/crop_protocols_progress_test.dart` | Protocol progress tracking |
| 43 | `test/data/turkiye_crop_guides_test.dart` | Turkish crop-guide content |
| 44 | `test/data/rule_packs_contract_test.dart` | **Rule-pack schema/contract** validation |
| 45 | `test/data/crop_images_asset_test.dart` | Crop image asset contract |
| 46 | `test/models/seed_and_crop_config_test.dart` | Seed/crop config models |
| 47 | `test/widgets/advisor_screen_test.dart` | Advisor screen rendering |
| 48 | `test/widgets/recommendation_card_test.dart` | Recommendation card UI |
| 49 | `test/widgets/crop_render_factory_test.dart` | Crop render factory |
| 50 | `test/widgets/activity_quick_log_ipm_test.dart` | Quick-log IPM widget |

### B.2 Backend test suite (`pytest`)

| Test file | Purpose |
|-----------|---------|
| `test_rule_engine.py` | Python reference engine correctness |
| `test_rule_parity.py` | Server side of the Dart↔Python parity guarantee |
| `test_sync_endpoints.py` | `/api/sync/push|pull|time` + LWW + in-memory fallback |

### B.3 Shared parity fixture

`test/fixtures/rule_parity_cases.json` — the canonical (facts → expected result) cases consumed
by **both** `rule_engine_parity_test.dart` and `test_rule_parity.py`. This single fixture is the
executable form of NFR-8 (determinism): identical facts + identical rule pack ⇒ identical output
on client and server.

> **Most significant tests:** the guardrail suite (B.1 #3) and the parity suite (B.1 #1 / B.2) —
> they are the executable form of the project's safety and determinism guarantees.

---

## Appendix C — API Documentation

FastAPI app (`backend/main.py`) + proxy router (`backend/proxy_endpoints.py`, mounted under
`/api`). Interactive OpenAPI docs are auto-served at `/docs` (Swagger) and `/redoc`. All
client↔server calls are Bearer-authorized; admin endpoints additionally require an `X-Admin-Key`
header. Paid third-party keys live only in the proxy layer, never in the client.

### C.1 Core endpoints (`main.py`)

| Method | Path | Summary | Key request fields | Response (200) |
|--------|------|---------|--------------------|----------------|
| POST | `/api/analyze/risks` | Risk analysis via rule engine | facts (crop, env, weather, soil) | `RuleResult[]` (category, risk_level, recommendations[], evidence) |
| GET | `/api/health` | Service health check | — | `{status, ...}` |
| POST | `/api/sync/push` | Outbox batch push (LWW) | `items[]` (entity_type, entity_id, operation, payload, updated_at) | `{accepted, rejected}` (stale rejected) |
| GET | `/api/sync/time` | Server UTC time (trusted clock) | — | `{server_time_utc}` |
| GET | `/api/sync/pull` | Pull latest server records | `since` cursor, user key | `{records[]}` |
| POST | `/api/fields/create` | Create field (PostGIS polygon) | `firebase_uid`, `name`, `area_dekar`, `boundary[]{lat,lng}` | `{success, field_id}` |
| GET | `/api/fields/{farmer_uid}` | List a farmer's fields | path: `farmer_uid` | `[{id, name, area_dekar, center_lat, center_lng}]` (via ST_Centroid) |
| POST | `/api/fields/{field_id}/plant` | Add crop to field + compare | path: `field_id`; body: crop facts | suitability + comparison result |
| POST | `/api/irrigation/schedule` | Smart irrigation plan (7-day) | field/crop, weather, soil | daily irrigate/skip + reasons (FAO-56) |
| GET | `/api/admin/users` | List users + sync status | header: `X-Admin-Key` | `[{user_key, last_activity, ...}]` |
| GET | `/api/admin/traffic` | API traffic statistics | header: `X-Admin-Key` | `[{path, request_count}]` |
| GET | `/admin` | Web admin panel (HTML) | — | HTML |
| POST | `/api/admin/content` | Update encyclopedia content | header: `X-Admin-Key`; body: content | `{success}` |
| POST | `/api/admin/broadcast` | Broadcast notification | header: `X-Admin-Key`; body: message | `{notif_id}` |

### C.2 Proxy / external-sensor endpoints (`proxy_endpoints.py`, prefix `/api`)

| Method | Path | Bounded sensor / purpose |
|--------|------|--------------------------|
| GET | `/api/proxy/plants/details` | Perenual — plant detail |
| POST | `/api/proxy/vision/imagga` | Imagga — "is this a plant?" pre-filter |
| POST | `/api/proxy/vision/plantnet` | PlantNet — species/weed identification |
| POST | `/api/proxy/vision/diagnose` | Gemini — constrained numeric severity sensor |
| GET | `/api/proxy/satellite/soil` | AgroMonitoring — NDVI / soil |
| GET | `/api/proxy/climate/historical` | NASA POWER — historical climate |
| GET | `/api/proxy/soil/profile` | SoilGrids — soil profile |
| GET | `/api/proxy/environment/field` | Combined field environment data |
| GET | `/api/proxy/weather/hourly` | Hourly weather forecast |
| GET | `/api/proxy/fuel/prices` | Fuel/energy price (irrigation cost) |
| POST | `/api/analyze/crop_recommendations` | Deterministic crop recommendation |
| POST | `/api/analyze/field_plan` | Deterministic field planting plan |
| POST | `/api/analyze/weekly_comment` | Weekly field commentary |
| POST | `/api/analyze/environmental_report` | Environmental report |

> **Discrepancy fix for the report body:** §App. C originally listed `/api/proxy/*` generically and
> omitted the `/api/analyze/crop_recommendations|field_plan|weekly_comment|environmental_report`
> endpoints and the NASA POWER / SoilGrids / fuel-price sensors. Use the tables above — they are
> the actual route decorators. Also note the report mentions "EPDK (water/energy prices)"; the
> implemented route is `/api/proxy/fuel/prices` — confirm provider name before final text.

---

## Appendix D — Database Schema

### D.1 Client — Drift schema **v11**, 10 tables (`lib/data/app_database.dart`)

> Note: the report says "11 tables." The `@DriftDatabase` annotation registers **10** tables; the
> "11" likely counted generated companions or the schema *version*. **Schema version = 11;
> table count = 10.** Use "Drift schema v11 (10 tables + generated companions)" in the report.

| Table | Primary key | `farmerUid`? | Soft delete | Purpose |
|-------|-------------|--------------|-------------|---------|
| `Fields` | `id` | ✅ (nullable) | `deletedAt` | Field/garden: name, GPS, area (dekar/m²), polygon JSON |
| `FieldCrops` | `id` | — (via field) | `deletedAt` | Crop planting: zone, spacing, planted date, seedling flag |
| `CalendarEvents` | `id` | — (via field) | `deletedAt` | Operations: type, date, quantity/unit, recommended qty, photo, note |
| `CropGrowthStates` | `cropId` | — | — | Live growth: GDD, stage, water/N/K stress, biomass, yield mult. |
| `IrrigationPlans` | `id` | — (via field) | `deletedAt` | Scheduled irrigate/skip + reason + recommendation |
| `SuitabilityReports` | `id` | — (via field) | `deletedAt` | Suitability score + reasons JSON |
| `FieldPlantInstances` | `id` | ✅ (nullable) | `deletedAt` | Individual plants: health, disease, condition flags, facing |
| `PlantConditionEvents` | `id` | ✅ (nullable) | `deletedAt` | Per-plant observation audit log |
| `SyncJobs` | `id` (autoinc) | — | — | Outbox: entity, operation, payload, updatedAt, attempts, status |
| `SyncState` | `key` | — | — | Sync cursors / LWW state |

**User isolation:** user-owned tables carry `farmerUid` (Fields, FieldPlantInstances,
PlantConditionEvents); child tables inherit ownership through their `fieldId` foreign key
(`.references(Fields, #id)`). This enforces KVKK per-user isolation (CLAUDE.md §5.5).

### D.2 Server — PostgreSQL / PostGIS

Spatial + sync state. Field geometry stored as `geometry(POLYGON, 4326)` (WGS-84); queried via
`ST_GeomFromText`, `ST_Centroid`, `ST_X`/`ST_Y`.

```sql
-- farmers: identity mapping (Firebase UID → internal id)
CREATE TABLE farmers (
    id           SERIAL PRIMARY KEY,
    firebase_uid TEXT UNIQUE NOT NULL,
    full_name    TEXT
);

-- fields: field polygons (PostGIS)
CREATE TABLE fields (
    id         SERIAL PRIMARY KEY,
    farmer_id  INTEGER REFERENCES farmers(id),
    name       TEXT NOT NULL,
    area_dekar REAL,
    boundary   geometry(POLYGON, 4326)   -- WGS-84
);

-- sync_records: server-side LWW store (verbatim from main.py _ensure_sync_schema)
CREATE TABLE IF NOT EXISTS sync_records (
    user_key     TEXT NOT NULL,
    entity_type  TEXT NOT NULL,
    entity_id    TEXT NOT NULL,
    operation    TEXT NOT NULL,
    payload      JSONB NOT NULL DEFAULT '{}'::jsonb,
    updated_at   TIMESTAMPTZ NOT NULL,
    created_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
    PRIMARY KEY (user_key, entity_type, entity_id)
);
CREATE INDEX IF NOT EXISTS idx_sync_records_user_updated
    ON sync_records (user_key, updated_at);
```

**LWW conflict resolution** (`_upsert_sync_record`): an incoming record is applied only if its
`updated_at` is strictly newer than the stored one; otherwise it is rejected (stale). When no
PostgreSQL is configured (dev/CI), a graceful in-memory store (`SYNC_STORE=memory`) backs the
same logic so the app and tests run without a database.

> **Discrepancy fix:** the report's App. D mentions a `field_plants` server table; the implemented
> server tables are `farmers`, `fields`, and `sync_records` (per-plant data syncs through
> `sync_records` as a generic entity, not a dedicated server table). Adjust the report text.

---

## Appendix E — Source Code Reference

### E.1 Repository layout

```text
feng_498/
├── lib/
│   ├── main.dart
│   ├── core/rule_engine/        # engine primitives: rule, condition, result, operators
│   ├── data/
│   │   ├── app_database.dart            # Drift schema v11 (10 tables)
│   │   ├── turkish_crops_repository.dart # 292-crop SQLite asset repo, scoreFor()
│   │   └── rule_packs/                  # 5 priority-crop rule packs + DSL
│   │       ├── rule_pack_dsl.dart       # readable eq/between/gt/... builders
│   │       ├── corn_rule_pack.dart
│   │       ├── orange_rule_pack.dart
│   │       ├── sunflower_rule_pack.dart
│   │       ├── tea_rule_pack.dart
│   │       └── tomato_rule_pack.dart
│   ├── services/                # 70+ domain services (irrigation, FAO ETo, sync,
│   │   │                        #   disease, fertilization, harvest, cost, growth)
│   │   ├── offline_rule_engine.dart     # on-device deterministic engine
│   │   ├── fao_eto_service.dart         # FAO-56 ETo (client)
│   │   ├── irrigation_service.dart
│   │   ├── disease_diagnosis_service.dart
│   │   └── ...
│   ├── screens/                 # 40+ Turkish UI screens
│   ├── widgets/                 # UI kit (TapScale, ParticleBackground, AppToast, ...)
│   └── theme/app_theme.dart     # AppColors / AppText / AppRadius / AppShadows
│
├── backend/
│   ├── main.py                  # REST + sync + irrigation + admin (FastAPI)
│   ├── rule_engine.py           # Python reference engine (parity target)
│   ├── proxy_endpoints.py       # key-isolating proxy for all paid APIs
│   ├── agri_api.py              # Perenual integration
│   └── data_pipeline/
│       ├── seed_plants.json
│       └── build_turkish_crops_db.py    # → turkish_crops.sqlite
│
├── assets/data/turkish_crops.sqlite     # 292-plant local crop DB
│
└── test/                        # 272 cases / 50 files (flutter test) + pytest
    └── fixtures/rule_parity_cases.json  # shared Dart↔Python parity fixture
```

### E.2 Key implementation references

- **FAO-56 ETo (client):** `lib/services/fao_eto_service.dart` —
  `ETo = [0.408·Δ·Rn + γ·(900/(T+273))·u₂·(eₛ−eₐ)] / [Δ + γ·(1 + 0.34·u₂)]`; Hargreaves Rs
  approximation when measured radiation is absent; Kc by crop/stage (FAO-56 Table 12).
- **FAO-56 ETo (server):** `_fao_eto` in `backend/main.py` (parity target).
- **Deterministic engine:** `lib/core/rule_engine/` (primitives) + `offline_rule_engine.dart`;
  operators in `operators.dart` (equals, not_equals, greater/less[_or_equal], between, contains,
  in, not_in, exists, missing).
- **Rule-pack DSL:** `lib/data/rule_packs/rule_pack_dsl.dart` (`rule(...)`, `eq/between/gt/...`).
- **Suitability scoring:** `TurkishCrop.scoreFor({temperature, soilPh, weeklyRain, month})` →
  `SuitabilityScore{score, reasons[]}`.
- **Sync (LWW):** client `lib/services/sync_service.dart` + outbox `SyncJobs`; server
  `_upsert_sync_record` in `backend/main.py`.
- **Key isolation:** `backend/proxy_endpoints.py` (all paid keys server-side only).

### E.3 Build / run commands

```bash
# Client
flutter pub get
dart run build_runner build --delete-conflicting-outputs   # after Drift schema change
flutter run            # or: flutter build apk
flutter analyze lib/ && dart format lib/ test/
flutter test           # 272 cases / 50 files

# Backend
cd backend
python -m uvicorn main:app --reload
python data_pipeline/build_turkish_crops_db.py             # regenerate crop SQLite asset
pytest                                                     # rule engine + parity + sync

# Secrets via .env placeholders; no real keys committed.
```

---

## Summary of discrepancies to fix in the report body

1. **Table count:** "11 tables" → "Drift schema **v11**, **10** tables (+ generated companions)."
2. **Server tables:** App. D `field_plants` → server has `farmers`, `fields`, `sync_records`
   (per-plant data syncs as a generic `sync_records` entity).
3. **API list:** App. C add the four `/api/analyze/*` deterministic endpoints and the
   NASA POWER / SoilGrids / fuel-price proxy routes; sync path is `/api/sync/time` (not `/time`).
4. **"EPDK"** vs implemented `/api/proxy/fuel/prices` — confirm the actual provider name.
5. **Test count 272 / 50 files** — ✅ verified correct, keep as-is.
```
