# Phase 1 — implementation note (scope only)

<!-- TODO(domain-split): Doc này mô tả slice dọc chung (API + Flutter) cho cả nghiệp vụ Fuel; phần báo cáo/tổng hợp HTTM có thể chồng lấp — khi có spec riêng từng domain, liên kết rõ tới docs/modules/fuel/ và docs/modules/httm/. -->

Phase 1 is the **smallest vertical slice** that proves end-to-end value in **three days**: real SQL Server data, a minimal API, and a Flutter shell that reads it. Everything else waits on confirmed domain mapping or schema extensions.

## Goals (must achieve)

1. **Running ASP.NET Core 10 Web API** with a **read-only** connection to `DMPPortal`, using only tables/columns from `docs/architecture/database.md`.
2. **OpenAPI document** exposed for the implemented endpoints (so Flutter can align contracts).
3. **Flutter app** that calls the API, shows **one list screen** and **one detail screen** for the chosen “station” concept (see below), with clear loading/error states — **no mock JSON** when the database is reachable.

## In scope (concrete)

### A. Define the “station” record (documented choice)

Pick **one** primary entity for the demo list/detail, justified in code comments or a one-page note:

- **Default recommendation**: **`DM_DonVi`** as the public-facing org/station row (name `Ten`, address `DiaChi` / `DiaChiChiTiet`, province/ward keys `Tinh`, `Xa`, phone `DienThoai`, etc.), optionally joined to **`DM_Tinh`** / **`DM_XaPhuong`** for readable location text **only using existing FK columns** (`DM_XaPhuong.TinhId` → `DM_Tinh.Id`).

If the demo instead must emphasize **depots**, pivot the primary row to **`TK_QuanLyKhoXangDau`** joined to **`DM_DonVi`** via `DonViId` — still read-only, same rules.

### B. API endpoints (minimal)

- `GET` **list** with pagination (skip/take or page/pageSize) and optional text filter on columns that exist (e.g. `Ten`, `Ma` on `DM_DonVi`).
- `GET` **by id** returning the same shape with joined lookup names where already supported by schema.

Do **not** add write endpoints in phase 1 unless explicitly required and backed by real tables.

### C. Flutter (minimal)

- API base URL configurable (dev/stage).
- List + detail for the same DTO.
- No offline-first complexity; no fabricated station list.

## Explicitly out of scope for phase 1

| Item | Reason |
|------|--------|
| **Map with pins** | Documented schema does not include lat/long; adding coordinates requires confirmed data or approved external geocoding — not assumed here. |
| **Pump-level fuel price** | Price-like figures live in statistical report rows (`QT_TK_ThongKeChiTiet` + indicator metadata); needs a **signed mapping** from reporting experts before exposing meaningful “price” in the app. |
| **Retail “stock status”** | `TK_QuanLyKhoXangDau_TonKho` is warehouse-oriented; without business rules, showing it as “station stock” would mislead — defer to phase 2 with domain sign-off. |
| **Reports dashboard** | Requires choosing one report type and understanding `So_XX` columns; too heavy for day-one wiring. |
| **Citizen complaints** | No complaint table in `docs/architecture/database.md`; needs product decision (new table, external system, or cut from demo). |

## Phase 1 success criteria

- Stakeholders can **install the app**, open **list → detail**, and see **real** names and addresses from SQL Server.
- Developers can point to **exact table.column** sources for every field on screen.
- Gaps (map, price, complaints) are **documented**, not hidden behind mock data.

## Suggested day breakdown (optional)

| Day | Focus |
|-----|--------|
| 1 | API project, DB connectivity, first read-only endpoint + OpenAPI; verify data with SQL you can explain. |
| 2 | Second endpoint, joins for location labels, error handling; Flutter list + detail consuming live API. |
| 3 | Polish (pagination, empty states), demo script, and a short “known limitations” slide backed by this doc. |

## Handoff to phase 2 (not implemented now)

- Signed **data dictionary** for report indicators (`TK_ChiTieuBaoCao` / `QT_TK_ThongKeChiTiet`).
- Decision on **coordinates** (new columns, existing unpublished tables, or geocoding).
- Decision on **complaints** persistence.
- Then add map, one simple aggregate report, and stock/price views **only** with mapped columns.
