# Project overview

## Purpose

This repository supports a **three-day demo** of a nationwide **petrol station mobile application** for citizens. The goal is to show how a Flutter app (Android and iOS) can consume a thin **ASP.NET Core 10 Web API** layer over an **existing SQL Server** database, without pretending the schema was designed for mobile UX.

## Target experience (product)

- Nationwide stations on a map, with name, address, services, and coordinates.
- Fuel **price** and **stock** visibility where the database actually stores comparable data.
- **Simple reports** (aggregates or lists derived from real tables).
- **Citizen complaints** submission.

## Technical stack

| Layer | Choice |
|--------|--------|
| API | ASP.NET Core 10 Web API |
| Data | Existing SQL Server database (`DMPPortal` — see `docs/architecture/database.md`) |
| Mobile | Flutter (Android + iOS) |

## Data rules (non-negotiable)

These apply to all design and implementation work:

1. **The database already exists** — no assumed greenfield model.
2. **Do not invent tables or columns** — only use structures documented in `docs/architecture/database.md` (or verified against the live database with the same discipline).
3. **Do not silently rename fields** — API DTOs may use friendly names only if they are explicitly mapped from real column names and documented.
4. **If a product feature needs data that is not in the schema, call out the gap** in docs or API responses; do not fill gaps with mock data when real data or real integration is expected.
5. **Prefer minimal, safe changes** suitable for a demo (read-only APIs first, narrow queries, no destructive migrations unless explicitly approved).

## Schema reality check (demo planning)

The checked-in schema describes **reporting, organizational units, fuel depot management, and ASP.NET Identity** tables. Mapping product language to that schema is **not one-to-one**:

- **“Station”** likely corresponds to **`DM_DonVi`** (and related warehouse rows such as **`TK_QuanLyKhoXangDau`**) — exact business mapping must be confirmed with domain owners.
- **Map coordinates** — no latitude/longitude columns appear in the documented tables; **map pins are blocked until** coordinates exist in the database, are joined from another approved source, or product scope accepts address-only / geocoding (with explicit product approval).
- **Retail fuel price** — period-based statistics live under **`QT_TK_ThongKe`** / **`QT_TK_ThongKeChiTiet`** (e.g. `LoaiGia`, `ThoiDiemDinhGia`, `So_01`…); meaning of each column is **report-template specific** and needs a **mapping sheet** from `TK_ChiTieuBaoCao` / report type — not a single “pump price” column.
- **Stock** — **`TK_QuanLyKhoXangDau_TonKho`** stores `SoLuong` and `Ngay` per allocation (`PhanBoId`); interpret as “inventory snapshot” for demo, not necessarily public retail availability.
- **Services** — no dedicated “services offered” table/column is documented; **gap** unless encoded elsewhere.
- **Citizen complaints** — **no complaint table** in the documented schema; **gap** (demo options: out-of-band store, separate approved table outside this snapshot, or scope cut).

For the full table and column list, see **`docs/architecture/database.md`**.

## Documentation map

| Document | Role |
|----------|------|
| `docs/README_FOR_AI.md` | Entry for AI tools — domains, stack, mandatory rules |
| `docs/architecture/overview.md` | This file — goals, stack, rules, schema gaps |
| `docs/architecture/project-structure.md` | Recommended repo layout for the demo |
| `docs/architecture/backend.md` | Stored procedure–first API and data access rules |
| `docs/modules/phase-1-scope.md` | Phase 1 implementation note (scope only) |
| `docs/architecture/database.md` | Authoritative column-level reference for `DMPPortal` |
| `docs/architecture/schema-analysis.md` | Business-area narrative and schema gaps |
| `docs/architecture/schema-extension.md` | App-owned schema extensions (e.g. store admin) |
| `docs/modules/api-mapping.md` | Proposed API modules ↔ tables |
| `docs/modules/field-mapping.md` | SQL columns ↔ proposed DTO fields |
| `docs/modules/fuel/README.md` / `docs/modules/httm/README.md` | Domain indexes (retail vs leadership views) |
| `docs/prompts/*.md` | Per-tool AI prompts (Cursor, Codex, Claude) |

## Out of scope for this writing pass

No backend or Flutter code is generated yet; only documentation.
