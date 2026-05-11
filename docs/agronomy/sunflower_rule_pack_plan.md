# Turkey-Focused Sunflower Rule Pack Plan

This is a planning document only. It does not define agronomic facts. Any value, threshold, disease, pest, province profile, calendar item, fertilizer rule, or weather trigger not already proven by an official source must stay as `TODO_SOURCE_BACKED`.

Although the first production target is sunflower, the asset-backed crop scope must cover the five PNG crops already present in `assets/crops/`: sunflower, corn, tomato, orange, and tea.

## Goal

Add a source-backed, deterministic rule pack system that can produce explainable Turkish agricultural advice offline. The first pack should be `crop.sunflower`; the same extraction and validation pipeline must also support the other four PNG priority crops:

| Crop | Stable ID | Existing PNG Asset |
|---|---|---|
| Aycicegi | `crop.sunflower` | `assets/crops/aycicegi.png` |
| Misir | `crop.corn` | `assets/crops/misir.png` |
| Domates | `crop.tomato` | `assets/crops/domates.png` |
| Portakal | `crop.orange` | `assets/crops/portakal.png` |
| Cay | `crop.tea` | `assets/crops/cay.png` |

## Current Relevant Files Discovered

Project guidance:
- `CLAUDE.md`: source of truth for deterministic rule packs, evidence, source metadata, BKU, fertilizer safety, offline-first behavior, and validation.
- `AGENTS.md`: short pointer to `CLAUDE.md`.

Crop database and source pipeline:
- `backend/data_pipeline/seed_plants.json`: existing curated crop source data; already contains v2 fields for priority crops.
- `backend/data_pipeline/sources.json`: existing source metadata registry.
- `backend/data_pipeline/build_turkish_crops_db.py`: builds `assets/data/turkish_crops.sqlite`.
- `backend/data_pipeline/validate_rule_pack.py`: existing validator for source references, evidence, stable IDs, BKU flags, expert-confirmation flags.
- `backend/data_pipeline/enforce_guardrails.py`: existing helper to enforce disease/pest BKU and expert flags.
- `assets/data/turkish_crops.sqlite`: generated asset DB.
- `assets/data/crop_images.json`: crop image mapping.
- `assets/data/pesticide_rei.json`: pesticide-related reference data asset; must not be used to bypass BKU checks.

Flutter crop data and rule structures:
- `lib/data/turkish_crops_repository.dart`: SQLite asset repository, source metadata access, v2 bundle access, JSON rule parsing support.
- `lib/core/rule_engine/rule.dart`
- `lib/core/rule_engine/rule_condition.dart`
- `lib/core/rule_engine/operators.dart`
- `lib/core/rule_engine/rule_engine.dart`
- `lib/core/rule_engine/rule_result.dart`
- `lib/data/supported_crops.dart`: five visible/priority crop names.
- `lib/data/sunflower_source_refs.dart`: existing central source-reference strings for sunflower.
- `lib/data/crop_ipm_rules.dart`: existing sunflower IPM rule objects and decision status model.
- `lib/services/rules/sunflower_rules.dart`: current hardcoded sunflower rule set.
- `lib/services/rules/crop_rule_set.dart`: crop-level deterministic recommendation abstraction.
- `lib/services/rules/recommendation.dart`: recommendation output model.
- `lib/services/rules/recommendation_ledger.dart`: recommendation cooldown/clearing support.
- `lib/services/rules/ipm_rule_runner.dart`: IPM runner.
- `lib/services/ipm_decision_service.dart`: IPM decision service.
- `lib/services/live_todo_service.dart`: combines directive and crop rule outputs.
- `lib/services/task_directive_service.dart`: current directive generator.
- `lib/services/weather_soil_service.dart`: environment snapshot inputs for rules.
- `lib/services/growth_engine.dart`: GDD/stress state for supported crops.
- `lib/services/field_state_service.dart`: crop area, plant count, and water accounting state.

Flutter screens and widgets to reuse:
- `lib/screens/field_detail_screen.dart`
- `lib/screens/daily_guide_screen.dart`
- `lib/screens/crop_daily_plan_screen.dart`
- `lib/screens/todo_panel_screen.dart`
- `lib/screens/activity_panel_screen.dart`
- `lib/screens/crop_calendar_screen.dart`
- `lib/screens/soil_analysis_screen.dart`
- `lib/widgets/recommendation_card.dart`
- `lib/widgets/activity_quick_log.dart`
- `lib/widgets/disease_picker_sheet.dart`
- `lib/widgets/disease_advice_sheet.dart`

Animation and crop visuals:
- `assets/crops/aycicegi.png`
- `assets/crops/misir.png`
- `assets/crops/domates.png`
- `assets/crops/portakal.png`
- `assets/crops/cay.png`
- `lib/widgets/crop_render_factory.dart`
- `lib/widgets/crop_growth_sprite.dart`
- `lib/widgets/live_crop_growth.dart`
- `lib/screens/plant_zone_drawing_screen.dart`

Backend:
- `backend/main.py`: FastAPI endpoints and sync/admin infrastructure.
- `backend/rule_engine.py`: existing monolithic rule engine; must be audited before using for new rule packs because it contains direct advice patterns that may conflict with `CLAUDE.md`.
- `backend/RULE_ENGINE_AUDIT.md`: existing backend audit document.

Tests:
- `test/services/sunflower_rules_test.dart`
- `test/services/ipm_rule_runner_test.dart`
- `test/data/crop_ipm_rules_test.dart`
- `test/data/turkiye_crop_guides_test.dart`
- `test/services/live_todo_service_test.dart`
- `test/services/task_directive_service_test.dart`
- `test/services/fertilizer_dose_calculator_test.dart`
- `test/widgets/recommendation_card_test.dart`
- `backend/tests/test_rule_engine.py`

## Files To Update Instead Of Duplicating

Prefer extending these files instead of creating parallel systems:

- Use `backend/data_pipeline/sources.json` for source metadata.
- Use `backend/data_pipeline/seed_plants.json` for crop v2 data while the schema remains manageable.
- Use `backend/data_pipeline/validate_rule_pack.py` for validation, extending it rather than adding a second validator.
- Use `backend/data_pipeline/build_turkish_crops_db.py` to publish source-backed data to SQLite.
- Use `lib/data/turkish_crops_repository.dart` to read crop v2 bundles and source metadata.
- Use `lib/core/rule_engine/*` for JSON rule evaluation.
- Use `lib/services/rules/*` and `LiveTodoService` for recommendation integration.
- Use existing screens and widgets for advice display.
- Use `crop_render_factory.dart`, `crop_growth_sprite.dart`, and `live_crop_growth.dart` for visual/animation support.

Do not create a separate crop database, separate recommendation UI, separate Flutter rule engine, or separate source registry unless the existing files cannot represent the required source-backed structure.

## New Files Only If Truly Necessary

Potential future files, only after schema pressure proves they are needed:

- `backend/data_pipeline/rule_packs/crop_sunflower.json`
- `backend/data_pipeline/rule_packs/crop_corn.json`
- `backend/data_pipeline/rule_packs/crop_tomato.json`
- `backend/data_pipeline/rule_packs/crop_orange.json`
- `backend/data_pipeline/rule_packs/crop_tea.json`
- `backend/data_pipeline/rule_pack_schema.json`
- `lib/core/rule_engine/rule_pack_validator.dart`
- `test/core/rule_engine/rule_pack_validator_test.dart`
- `backend/tests/test_rule_pack_validation.py`

Do not add them in the first implementation phase if `seed_plants.json` plus `v2_data` remains sufficient.

## Source Metadata Strategy

Use `backend/data_pipeline/sources.json` as the only source registry.

Every source record must include:
- `id`
- `title`
- `institution`
- `source_type`
- `url`
- `publication_year`
- `retrieved_at`
- `reliability`
- `notes`

Priority order:
1. T.C. Tarim ve Orman Bakanligi
2. TAGEM
3. Ministry research institutes
4. CAYKUR / TEPGE / official crop reports
5. University agriculture faculty publications
6. Public agricultural education notes
7. Private sources only as low-priority supporting evidence

Rules:
- Do not extract facts without evidence.
- Do not silently merge conflicting sources.
- Do not upgrade broad prose into exact deterministic thresholds.
- Do not use OCR output unless manually checked.
- Store page, section, and short evidence text for every fact.
- Chemical-control records must keep `requires_bku_check: true`.
- Disease/pest diagnosis records must keep `requires_expert_confirmation: true`.

Known source metadata already present:
- `source.tagem.sunflower_ipm`
- `source.tagem.corn_ipm`
- `source.tagem.tomato_open_field_ipm`
- `source.tagem.greenhouse_vegetables_ipm`
- `source.tagem.citrus_ipm`
- `source.caykur.tea_cultivation_lecture_notes_2025`

Each of these still needs fact-level evidence review before rules are trusted.

## JSON Rule Pack Schema

Use a versioned JSON structure aligned with `CLAUDE.md`. Fields can live inside `seed_plants.json` v2 initially, or in separate `rule_packs/*.json` later.

```json
{
  "rule_pack_id": "rule_pack.sunflower.tr.v1",
  "version": "TODO_SEMVER_OR_DATE",
  "locale": "tr-TR",
  "crop_ids": ["crop.sunflower"],
  "source_metadata": [],
  "crop_profiles": [],
  "province_profiles": [],
  "region_profiles": [],
  "soil_requirements": [],
  "growth_stages": [],
  "operation_calendar": [],
  "fertilizer_rules": [],
  "irrigation_rules": [],
  "diseases": [],
  "pests": [],
  "weed_management": [],
  "control_methods": [],
  "weather_advice_rules": [],
  "rule_engine_rules": [],
  "animation_states": [],
  "conflicts": [],
  "missing_information": [],
  "test_cases": [],
  "checksum": "TODO_SHA256_AFTER_BUILD"
}
```

Every fact/rule item must use this evidence envelope:

```json
{
  "id": "TODO_STABLE_ID",
  "source_ids": ["TODO_SOURCE_ID"],
  "confidence": "high | medium | low",
  "evidence": [
    {
      "source_id": "TODO_SOURCE_ID",
      "page": null,
      "section": "TODO_SOURCE_SECTION",
      "evidence_text": "TODO_SOURCE_BACKED_SUMMARY"
    }
  ],
  "created_at": "TODO_YYYY-MM-DD",
  "updated_at": "TODO_YYYY-MM-DD"
}
```

Rule items must follow the existing `lib/core/rule_engine` model:

```json
{
  "id": "rule.sunflower.todo.v1",
  "crop_id": "crop.sunflower",
  "category": "TODO_CATEGORY",
  "priority": 0,
  "enabled": true,
  "conditions": [
    {
      "field": "TODO_FACT_FIELD",
      "operator": "equals",
      "value": "TODO_SOURCE_BACKED_VALUE"
    }
  ],
  "result": {
    "risk_level": "low | medium | high | critical",
    "possible_problem_id": "TODO_OR_NULL",
    "recommendations": ["TODO_SOURCE_BACKED_OR_SAFE_MISSING_INFO_TEXT"],
    "requires_expert_confirmation": true,
    "requires_bku_check": false
  },
  "explanation": "TODO_SOURCE_BACKED_EXPLANATION",
  "confidence": "low",
  "evidence": []
}
```

## Province/City Profile Strategy For 81 Turkish Provinces

Create a province profile layer, but do not fill agronomic values without official evidence.

Profile shape:

```json
{
  "id": "province.TODO_ASCII_NAME",
  "country": "TR",
  "province_code": "TODO_OFFICIAL_CODE",
  "name_tr": "TODO_PROVINCE_NAME",
  "region_id": "TODO_REGION_ID",
  "climate_profile": {
    "source_ids": [],
    "monthly_temperature_normals": "TODO_SOURCE_BACKED_OR_NULL",
    "monthly_rainfall_normals": "TODO_SOURCE_BACKED_OR_NULL",
    "frost_window": "TODO_SOURCE_BACKED_OR_NULL",
    "heat_risk_window": "TODO_SOURCE_BACKED_OR_NULL"
  },
  "crop_profiles": {
    "crop.sunflower": {
      "suitability": "TODO_SOURCE_BACKED_OR_UNKNOWN",
      "sowing_window": "TODO_SOURCE_BACKED_OR_NULL",
      "harvest_window": "TODO_SOURCE_BACKED_OR_NULL",
      "disease_pest_notes": "TODO_SOURCE_BACKED_OR_NULL",
      "missing_information": []
    }
  },
  "evidence": []
}
```

Implementation strategy:
- Maintain exactly 81 province records when the province layer is introduced.
- Use stable ASCII IDs.
- Store official climate/crop evidence per province, not inferred region guesses.
- If a province has no source-backed sunflower profile, leave the crop profile as `unknown` and add `missing_information`.
- Weather-based advice may use live/cached weather facts for that field, but province default values must not be invented.
- Region-level fallback can only say "province-specific source is missing"; it must not create precise local calendars.

## Disease And Pest Rule Strategy For 5 PNG Crops

Scope is all five asset-backed crops, not only sunflower:
- `crop.sunflower`
- `crop.corn`
- `crop.tomato`
- `crop.orange`
- `crop.tea`

Strategy:
1. Use the existing source metadata entries for the five crops.
2. Extract disease and pest records only from official, reviewed sources.
3. Use stable IDs:
   - `disease.{crop}.{name}`
   - `pest.{crop}.{name}`
   - `rule.{crop}.disease.{name}.{condition}.v1`
   - `rule.{crop}.pest.{name}.{condition}.v1`
4. Store observation method, symptoms, monitoring window, cultural controls, biological controls, and chemical gate separately.
5. Keep chemical control behind BKU and expert-confirmation gates.
6. Existing hardcoded sunflower IPM structures can guide shape, but each fact must be revalidated against source evidence before being promoted into the pack.
7. Legacy fields like `common_pests`, `common_diseases`, and prose `fertilizer_notes` are not enough for deterministic rules unless backed by v2 evidence.

For every crop, unresolved sections must be explicit:

```json
{
  "missing_information": [
    "TODO_SOURCE_BACKED: disease list requires reviewed official source evidence.",
    "TODO_SOURCE_BACKED: pest thresholds require page/section evidence.",
    "TODO_SOURCE_BACKED: province-specific occurrence windows are missing."
  ]
}
```

## BKU Safety Guardrails

Mandatory rules:
- No output like "use this pesticide at this dose".
- Any chemical-control path must set `requires_bku_check: true`.
- Disease/pest diagnosis must set `requires_expert_confirmation: true`.
- Active ingredient, product name, dose, interval, or pre-harvest interval must not be shown as a recommendation unless it is officially sourced and still guarded by current BKU verification.
- If BKU status is unknown, output must stop at "BKU check required".
- Weather risk must never directly become pesticide advice.
- Cultural and mechanical controls must be shown before any chemical gate.
- Near-harvest residue risk messaging must be included only when source-backed or as a generic safety warning without product/dose detail.

Validator requirements:
- Fail if a pest/disease record lacks `requires_bku_check`.
- Fail if a pest/disease record lacks `requires_expert_confirmation`.
- Fail if a rule recommendation includes dose/product/active-ingredient language without explicit BKU gating.
- Fail if chemical text appears in UI-facing output from unsupported legacy engines.

## Fertilizer Safety Guardrails

Mandatory rules:
- No exact fertilizer dose without soil analysis and source-backed crop/period logic.
- If pH, EC, organic matter, N, P, or K are missing, return `missing_information`.
- Fertilizer advice must distinguish:
  - general observation/safety guidance
  - soil-analysis request
  - source-backed calculation
  - unavailable due to missing data
- Fertilizer rules must include source evidence and unit.
- Any economic/cost calculation must remain separate from agronomic dose decisions.

Existing files to align later:
- `lib/services/rules/fertilizer_dose_calculator.dart`
- `lib/services/soil_fertilization_service.dart`
- `lib/data/fertilizer_prices.dart`
- `test/services/fertilizer_dose_calculator_test.dart`

## Weather-Based Dynamic Advice Strategy

Weather can create monitoring and timing advice, but not unsourced diagnosis or chemical treatment.

Inputs to reuse:
- `RuleEnvironmentSnapshot`
- `HourlyForecast`
- `GrowthSnapshot`
- `CropFieldState`
- cached weather/soil data from existing services

Rule behavior:
- If live weather is missing, use cached data only if freshness is known.
- If cached data is stale, include a Turkish stale-data warning.
- If a weather threshold is not source-backed, keep the rule disabled or mark `TODO_SOURCE_BACKED`.
- Weather can trigger:
  - scouting tasks
  - irrigation timing checks
  - harvest timing warnings
  - frost/heat/wind/rain safety warnings
  - "data missing" messages
- Weather must not trigger:
  - pesticide product advice
  - fertilizer dose advice
  - final disease diagnosis

## Animation Support Strategy

The rule pack should expose visual state metadata, but visuals must not invent agronomic stages.

Existing support:
- PNG markers for five priority crops live under `assets/crops/`.
- `crop_render_factory.dart` already renders crop markers and tries PNG before JPG fallback.
- `crop_growth_sprite.dart` has animated vector support for sunflower, corn, and tomato.
- `live_crop_growth.dart` maps growth/stress state to animation.

Plan:
1. Keep PNG asset rendering as the baseline for all five crops.
2. Add or update animation states only when source-backed growth stages exist.
3. Do not infer tea/orange growth stages from unrelated crops.
4. Use generic visual overlays for unsupported crop-specific animation:
   - stress tint
   - disease-pressure spots
   - harvest-ready highlight
   - selected/attention pulse
5. Tie animation state to deterministic facts:
   - `growth_stage`
   - `water_stress`
   - `nitrogen_stress`
   - `disease_pressure`
   - `harvest_ready`
6. Audit `assets/data/crop_images.json` before implementation because some priority crops map to `.jpg` while PNG files exist.

## Backend Integration Plan

Phase 1: pipeline only
- Extend `validate_rule_pack.py` for full rule-pack sections.
- Keep `sources.json` as registry.
- Keep `seed_plants.json` as initial storage unless separate versioned files become necessary.
- Build SQLite with `build_turkish_crops_db.py`.

Phase 2: backend read APIs
- Add read-only endpoints only after pipeline validation is stable:
  - `GET /api/rule-packs/latest`
  - `GET /api/rule-packs/{version}`
  - `GET /api/crops/{crop_id}/knowledge`
  - `POST /api/rule-packs/validate`
- Include version, checksum, source count, rule count, and locale.
- Return cached rule packs safely for offline-first Flutter sync.

Phase 3: backend rule evaluation
- Do not route the new pack through `backend/rule_engine.py` until guardrail parity is proven.
- Prefer a JSON-rule evaluator compatible with `lib/core/rule_engine/*`.
- Add parity tests between backend and Flutter for the same facts/rules.

## Flutter Integration Plan

Phase 1: read and display
- Use `TurkishCropsRepository.findV2ByStableId`.
- Use `TurkishCropsRepository.findSource` and `listSources` for source display.
- Keep screens unchanged except for consuming validated rule output.

Phase 2: deterministic evaluation
- Use `lib/core/rule_engine/*` for JSON rules.
- Map existing field/crop/weather/soil/activity data into facts.
- Feed results into the existing recommendation pipeline.
- Keep UI text Turkish.

Phase 3: live advice
- Integrate with `LiveTodoService` rather than adding a new recommendation service.
- Keep `Recommendation`, `RecommendationGate`, source refs, cooldown, and clear-on-activity behavior.
- Convert disease/pest advice into observe-first tasks unless BKU/expert gates are satisfied.

Phase 4: visuals
- Reuse crop PNGs and existing marker widgets.
- Add animation metadata only from source-backed growth stages.
- For tea/orange, use generic PNG/stress overlays until official phenology data is extracted.

## Test Plan

Pipeline tests:
- `sources.json` parses.
- every source ID is stable and unique.
- every fact/rule evidence source exists.
- every priority crop has stable ID and v2 status.
- every disease/pest record has BKU and expert flags.
- every rule has positive and negative test cases.
- missing province data produces `missing_information`, not inferred facts.

Flutter tests:
- `RuleEngine` operator and matching tests.
- JSON rule pack parsing tests.
- `TurkishCropsRepository` v2 bundle/source tests.
- `LiveTodoService` integration tests for rule output ordering, cooldown, and gates.
- Recommendation widget tests for Turkish text, source evidence, and BKU warning display.
- Animation state mapping tests for supported and unsupported crop-specific animations.

Backend tests:
- rule pack validation endpoint tests after endpoint creation.
- checksum/version tests.
- backend/Flutter parity tests for identical facts.
- regression tests blocking direct pesticide/fertilizer outputs from legacy engines.

Manual checks:
- run `python backend/data_pipeline/validate_rule_pack.py --strict`
- run `python backend/data_pipeline/build_turkish_crops_db.py`
- run `flutter analyze lib/`
- run relevant Dart tests
- run relevant backend tests

## Validation Checklist

Before any rule pack is approved:

- [ ] JSON parses.
- [ ] Schema validation passes.
- [ ] Stable IDs use lowercase ASCII, dots, and underscores only.
- [ ] Every source ID exists in `sources.json`.
- [ ] Every fact has evidence.
- [ ] Every disease/pest record has `requires_bku_check: true`.
- [ ] Every disease/pest diagnosis has `requires_expert_confirmation: true`.
- [ ] No rule invents missing data.
- [ ] No exact fertilizer dose appears without soil-analysis requirement.
- [ ] No pesticide product, active ingredient, dose, or interval is emitted without BKU guardrail.
- [ ] Weather rules are monitoring/timing rules, not treatment shortcuts.
- [ ] Province profile gaps are listed in `missing_information`.
- [ ] All five PNG priority crops are represented in the extraction scope.
- [ ] Offline fallback behavior is defined.
- [ ] Flutter and backend rule behavior are either proven equivalent or backend evaluation remains disabled for that pack.

## Missing Data Handling

Use these values consistently:
- `null`: source did not provide the value.
- `unknown`: the value is conceptually expected but not known yet.
- `TODO_SOURCE_BACKED`: official evidence must be extracted before use.
- `missing_information`: user-facing and validator-facing list of absent required facts.

Behavior:
- Missing facts must not be guessed.
- Rules with missing required facts must not fire unless the rule is explicitly a missing-data warning.
- UI should say what data is missing in Turkish.
- Backend should return safe empty/partial results rather than fabricated recommendations.
- Province-specific gaps should remain province-specific; do not fill them from broad regional assumptions.

## Risks

- Existing `backend/rule_engine.py` and `lib/services/offline_rule_engine.dart` contain direct recommendation patterns that may violate the newer guardrails.
- Existing hardcoded crop protocols/playbooks may contain values that are not yet connected to evidence envelopes.
- `crop_images.json` appears to reference JPG names for some crops that now have PNG files.
- PDF/OCR extraction can create false facts; manual review is required.
- Flutter and backend rule engines can drift unless a shared JSON schema and parity tests are enforced.
- Adding Drift tables or changing SQLite asset structure can break offline users if migration is not planned.
- Province-level rules for 81 provinces may be incomplete for a long time; incomplete data must remain explicit.
- Current working tree may already contain unrelated changes; implementation should start from a clean or intentionally isolated baseline.

## Safest Phased Implementation

1. Freeze current working tree and isolate unrelated changes.
2. Extend validation rules before adding new agronomic content.
3. Normalize source metadata for the five priority PNG crops.
4. Extract sunflower facts first into TODO-safe, evidence-backed JSON.
5. Add missing-information records for every unsupported sunflower field.
6. Repeat extraction for corn, tomato, orange, and tea using the same schema.
7. Build SQLite and verify Flutter can read v2 bundles.
8. Wire JSON rules into Flutter using existing `RuleEngine` and `LiveTodoService`.
9. Add backend read-only delivery after Flutter validation.
10. Add backend evaluation only after parity and guardrail tests pass.
