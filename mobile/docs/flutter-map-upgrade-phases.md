# Flutter map-first upgrade (phased)

Roadmap for a **Google Maps–inspired**, **map-first** UX using **only real backend APIs** (no mock data when an endpoint exists). See `lib/features/map/presentation/map_shell_page.dart` and `station_map_preview_sheet.dart` for the current baseline.

---

## Current layout (Phase 1 today)

| Feature | Location | Backend |
|--------|----------|---------|
| Map shell | `features/map/presentation/` | `GET /api/stations/map`, filters, keyword discovery |
| Station markers | `map_station_map_body.dart`, `station_map_marker_bitmap.dart` | Map DTO `openStatus` / prices → tone |
| Bottom sheet | `station_map_preview_sheet.dart` | Map item + `GET /api/stations/{id}` |
| Station detail route | `features/station_detail/` | Same detail API |
| Search / filter | `map_search_sheet.dart`, `map_filter_sheet.dart`, `map_providers.dart` | List + map intersection for keyword |
| Reports | `features/reports/` | `GET /api/reports/overview` |
| More | `features/more/` | Navigation only |

**Not wired yet (backend exists):** nearest / cheapest / top-rated (`/api/stations/nearest|cheapest|top-rated`), reviews (`/api/stations/{id}/reviews`, rating summary), `POST /api/bad-reports` (private; no public list in app).

---

## Phase A — Discovery & polish (no new domains)

**Goals:** richer map affordances without new feature modules.

- **Markers:** refine `StationMapMarkerBitmap` (size, selection ring, optional price chip on marker — only if performance OK).
- **Bottom sheet:** tighten `showStationMapPreviewSheet` layout (peek height, scroll, “Open in full detail” as primary CTA); keep `stationDetailProvider` as single source of truth.
- **Open/closed:** already driven by `StationOpenTone` / `StationOpenStatusPill`; extend legend on map (small FAB or filter sheet footer) if needed.
- **Api surface:** add `ApiEndpoints` entries + thin `StationsApi` methods when implementing spotlight APIs (do not stub JSON).

---

## Phase B — Spotlight & reviews (new sub-features under existing modules)

**Goals:** quick wins from map chrome.

- **`features/map/data` + `presentation`:** “Discover” row or floating panel entries for **Nearest** / **Cheapest** / **Top rated** → call new `StationsApi` methods; show result as camera target + bottom sheet or dedicated sliver (no fake lists).
- **`features/stations/data`:** DTOs for `StationSpotlightDto`, review list page, `CreateStationReviewRequest` (mirror backend names).
- **`features/station_detail` or `features/reviews`:** optional tab/section “Đánh giá” loading `GET .../reviews` and summary; **empty states** when API returns empty (no placeholder stars).

Prefer **`features/reviews/`** only if the UI grows; otherwise keep review list widgets under `station_detail` to avoid over-fragmentation.

---

## Phase C — Bad report (single flow, no admin UI)

**Goals:** citizen path only.

- **`features/bad_reports/`** (small): form screen or modal from **More** or **station detail** sheet → `POST /api/bad-reports` with `stationId` optional; success snackbar only (no invented “ticket id” styling beyond API response).

Do **not** add admin bad-report list in the mobile app unless product asks (requires `X-Admin-Api-Key`).

---

## Phase D — Architecture hardening

- **Riverpod:** keep `stationsApiProvider`, `mapFiltersProvider`, `stationMapMarkersProvider`; add `stationSpotlightProvider.family` / `stationReviewsProvider.family` when APIs are used.
- **Routing:** `AppRoute` + `go_router` — add paths only when screens exist (`/discover/nearest`, etc.).
- **Theming:** centralize map chrome colors (sheet handle, FAB) in `shared/theme` for consistency with `AppTheme`.

---

## Principles (all phases)

1. **Real APIs only** — parse null/empty; show explicit empty/error UI.
2. **Feature-based** — map UI stays under `features/map/`; shared station models stay under `features/stations/`.
3. **Map-first** — any new entry point should default to opening or focusing the map, then sheet/detail.
4. **No fake data** — if an endpoint is missing, keep a “Sắp có” / disabled control with explanation, not fabricated rows.
