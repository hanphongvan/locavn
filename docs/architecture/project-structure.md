# Recommended project structure (3-day demo)

This layout keeps the API, mobile app, and shared knowledge separate while staying small enough to ship in a few days.

## Monorepo root

```text
httm-xangdau/
├── docs/                          # Product + technical docs (keep updated)
│   ├── README_FOR_AI.md           # Entry point for AI assistants
│   ├── AI_WORKFLOW.md             # Git branch/PR + Cursor / Claude Code / Codex
│   ├── DEV_WORKFLOW.md            # Developer workflow (local setup, conventions)
│   ├── architecture/              # Overview, backend, database, schema notes
│   │   ├── overview.md
│   │   ├── project-structure.md   # this file
│   │   ├── backend.md
│   │   ├── database.md            # SQL Server DMPPortal reference (legacy name: db-schema)
│   │   ├── schema-analysis.md
│   │   └── schema-extension.md
│   ├── modules/                   # API/field mapping, phase scope, domain indexes
│   │   ├── api-mapping.md
│   │   ├── field-mapping.md
│   │   ├── phase-1-scope.md
│   │   ├── fuel/
│   │   │   └── README.md          # Domain index — retail / citizen app
│   │   └── httm/
│   │       ├── README.md          # Domain index — leadership / ministry views
│   │       ├── api-endpoints.md
│   │       ├── data-model.md
│   │       └── screens.md
│   ├── design/                    # Static design references (images, etc.)
│   │   └── login-reference.png
│   ├── standards/                 # Shared coding/process standards (placeholder until expanded)
│   └── prompts/                   # Per-tool AI guidance
│       ├── cursor.md
│       ├── codex.md
│       └── claude.md
├── backend/                       # ASP.NET Core 10 Web API
│   ├── src/
│   │   └── DmpPortal.Api/         # Single host project is enough for demo
│   │       ├── Program.cs
│   │       ├── appsettings.json
│   │       ├── appsettings.Development.json
│   │       ├── Controllers/       # Thin HTTP layer
│   │       ├── Models/            # EF entities or raw DTO shapes (match DB names)
│   │       ├── Data/              # DbContext, queries
│   │       ├── Services/          # Optional: orchestration if controllers grow
│   │       └── Mapping/           # Explicit DB column → API field maps
│   └── tests/
│       └── DmpPortal.Api.Tests/   # Optional for demo; smoke tests if time allows
├── mobile/                        # Flutter app
│   ├── lib/
│   │   ├── main.dart
│   │   ├── app/                   # Theme, routing, DI
│   │   ├── features/
│   │   │   ├── map/               # Station map (when coordinates available)
│   │   │   ├── stations/          # Lists, detail
│   │   │   ├── reports/         # Simple report screens
│   │   │   └── complaints/      # Only if storage is agreed
│   │   └── data/                  # API client, models mirroring API contracts
│   ├── pubspec.yaml
│   └── ...                        # android/, ios/, etc.
├── .gitignore
└── README.md                      # How to run API + app (add when code exists)
```

## Backend conventions (demo-sized)

- **One API project** under `backend/src/DmpPortal.Api` unless you hit a hard need to split.
- **Connection string** only in configuration (`appsettings*.json` + user secrets / env vars); never commit secrets.
- **Controllers** stay thin: validate input, call data layer, return DTOs.
- **Database access**: EF Core with `DbContext` *or* ADO.NET/Dapper for read-only queries — choose whichever is faster for your team; still **map only real columns**.
- **CORS**: configure explicitly for the Flutter dev origins you use (web/desktop debugging, local network devices).

## Mobile conventions (demo-sized)

- **Feature folders** under `lib/features/*` so map, stations, and reports do not tangle.
- **API layer** in `lib/data/` (single `ApiClient`, small repository classes per feature).
- **Models** should follow **API JSON contracts**, which in turn must trace back to **documented SQL columns** (via mapping notes in backend or OpenAPI descriptions).

## Shared contracts

- Prefer **OpenAPI** (Swashbuckle or built-in .NET OpenAPI) emitted from the Web API so Flutter can generate or hand-copy DTOs accurately.
- Any **rename** from database to JSON must be listed in one place (e.g. `backend/.../Mapping/README.md` or XML comments on DTOs) — still **no silent renames**.

## What not to add for the demo

- Multiple microservices, message buses, or Kubernetes manifests unless explicitly required.
- Generated “fake” seed data when the real database is available.
- New database objects without stakeholder sign-off (contradicts “existing DB” rule).

## Schema source of truth

All structural assumptions flow from **`docs/architecture/database.md`** until replaced by a fresher export from production or staging that you check in the same way.

## Backend data access rules

All backend data access must follow the architecture defined in:

👉 `docs/architecture/backend.md`

Important:
- APIs must call stored procedures for all data operations.
- Do not query database tables directly from code.