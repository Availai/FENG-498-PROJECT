# AGENTS.md

## Project
This repository is an offline-first agricultural mobile application for Turkish-speaking users.
Main goal: provide a complete farming assistant for rural users with unstable internet.

## Stack
- Frontend: Flutter
- State management: Riverpod
- Local DB: Drift (SQLite)
- Local cache/preferences: Hive
- Background sync: WorkManager
- Backend: FastAPI, Uvicorn
- Validation: Pydantic
- ORM: SQLAlchemy, GeoAlchemy2
- Cloud DB: PostgreSQL + PostGIS

## Product rules
- App language must be Turkish.
- Existing working code must be preserved unless a bug or architectural inconsistency requires a change.
- Do not rewrite the whole project if a module can be extended safely.
- Prefer incremental changes over big refactors.
- Keep offline-first behavior as a hard requirement.
- UI must remain simple, high-contrast, and usable in direct sunlight.
- Assume low-bandwidth rural conditions.
- Prefer robust error handling and explicit fallback states.

## Functional scope
Implement or improve these modules only when requested:
- Authentication (email/password)
- Field/garden registration with polygon drawing or instant GPS
- Weather + forecast + historical precipitation
- Preventive notifications for frost / heavy rain / extreme events
- Crop calendar from seed to harvest
- Plant suitability report using soil + climate data
- Smart irrigation schedule using species + rainfall forecast
- Offline agricultural encyclopedia
- Async local-to-cloud synchronization
- Admin panel basics (user/account status, API traffic, content updates)

## Non-functional rules
- Must work without freezing when internet is lost.
- Local data entry must continue offline.
- Sync must use eventual consistency.
- Conflict resolution must use Last-Write-Wins (LWW) with timestamps.
- Compress photos to WebP before upload when relevant.
- Passwords must never be stored in plain text.
- API requests must be authenticated.

## Engineering rules
- Before coding, inspect current repository structure and identify what already exists.
- Reuse existing services, models, providers, repositories, and screens where possible.
- Create new files only when necessary.
- Keep file names and folder structure consistent with current project style.
- Add TODO comments only when something truly cannot be completed from current repo context.
- Do not invent fake API keys or secrets.
- Use environment/config placeholders for secrets.
- Prefer testable abstractions.

## Output rules
For each task:
1. First summarize current repo state briefly.
2. Then list a short implementation plan.
3. Then apply code changes.
4. Then show what changed by file.
5. Then list commands to run for verification.
6. If something is missing in the repo, state the exact missing piece instead of guessing.

## Definition of done
A task is done only if:
- code compiles logically within the existing architecture,
- new logic is connected to existing flow,
- edge cases and offline states are handled,
- Turkish UI text is used,
- no unnecessary rewrites are introduced.