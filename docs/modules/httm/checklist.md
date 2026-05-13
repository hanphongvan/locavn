# HTTM Implementation Checklist

> **Single source of truth** để track tiến độ triển khai domain **HTTM – Hạ Tầng Thương Mại**.
> Mỗi lần hoàn thành 1 mục, đánh dấu `[x]` kèm `commit_hash` ngắn + ngày (YYYY-MM-DD).
> File này được cập nhật **trực tiếp khi merge PR**, không phải sau-cùng-mới-update.

## Format ký hiệu
- `[ ]` chưa làm
- `[~]` đang làm — kèm tên người phụ trách
- `[x]` xong — kèm commit hash + ngày, ví dụ: `[x] (8be2c49 · 2026-05-13)`
- `[!]` blocked — kèm lý do
- `[-]` huỷ / không làm — kèm lý do

---

## 0. Decisions đã chốt (anchor — không thay đổi nếu không có review)

| # | Quyết định | Ngày chốt |
|---|------------|-----------|
| D1 | DB **SQL Server `DMPPortal`** dùng chung toàn dự án, KHÔNG dùng PostgreSQL/PostGIS như spec gốc | 2026-05-13 |
| D2 | Schema HTTM viết bằng SQL Server T-SQL — file mới [`data-model-sqlserver.md`](./data-model-sqlserver.md) thay thế [`data-model.md`](./data-model.md) (deprecated) | 2026-05-13 |
| D3 | Truy cập DB **bắt buộc qua Stored Procedure** (Dapper/ADO.NET) — không EF cho nghiệp vụ | 2026-05-13 |
| D4 | Role dùng chung qua field `AspNetUsers.Loai`, mở rộng từ `AdminPortalLoaiRoleMapper`. Không tạo bảng role riêng | 2026-05-13 |
| D5 | Map provider: **Goong.io hoặc OSM**, có thể cấu hình runtime qua `system_configs` | 2026-05-13 |
| D6 | Phase 1 scope hẹp theo `implementation-plan.md`: chỉ CRUD HTTM facilities + map markers + catalogs đọc. Phiếu khảo sát thuộc Phase 2 | 2026-05-13 |
| D7 | Map provider phải verify Hoàng Sa/Trường Sa labels trước khi merge (compliance blocking) | 2026-05-13 |

### Mapping `AspNetUsers.Loai` (mở rộng)
| Loai | Role Name | Phạm vi | Trạng thái |
|------|-----------|---------|------------|
| 1 | `ADMIN` | Toàn hệ thống (Fuel + HTTM) | ✅ đã có |
| 3 | `TRADER` | Fuel — đầu mối | ✅ đã có |
| 4 | `STORE` | Fuel — cửa hàng | ✅ đã có |
| 5 | `PORTAL_USER` | Mobile consumer | ✅ đã có |
| 10 | `HTTM_ADMIN` | Quản trị riêng HTTM (full HTTM, không có quyền Fuel) | 🆕 Phase 1 |
| 11 | `BCT_STAFF` | Cán bộ Bộ Công Thương — toàn quốc, xem dữ liệu nhạy cảm | 🆕 Phase 1 |
| 12 | `SO_STAFF` | Cán bộ Sở — scope theo `province_codes[]`, không xem nhạy cảm | 🆕 Phase 1 |
| 13 | `UNIT_USER` | Đơn vị được khảo sát — chỉ thấy data của đơn vị mình | 🆕 Phase 2 (khi có Survey) |

> Quy ước: `Loai ∈ [10..19]` reserved cho domain HTTM. Tránh đụng độ với Fuel.

---

## Phase 1 — MVP Hồ sơ HTTM

**Mục tiêu**: CRUD `httm_facilities` đầy đủ trên Backend API + Admin Angular, có map markers nhẹ, audit log, phân quyền cơ bản.
**Estimated effort**: ~3 sprint.

### 1.1 Database — `backend/database/migrations/`

Naming convention: `YYYYMMDDHHMMSS_HttmXxx.sql` (theo pattern hiện tại).

#### 1.1.1 Bảng & Index
- [x] `20260513100000_HttmFacilities_Create.sql` — bảng chính + index (province, type, status, GEOGRAPHY spatial) · 2026-05-13
- [x] `20260513100001_HttmFacilityProducts_Create.sql` — N-N mặt hàng KD · 2026-05-13
- [x] `20260513100002_HttmFacilityImages_Create.sql` — gallery · 2026-05-13
- [x] `20260513100003_HttmFacilityLicenses_Create.sql` — giấy phép pháp lý + trigger `tr_Httm_FacilityLicenses_ExpiryAlert30d` · 2026-05-13
- [x] `20260513100004_HttmAuditLogs_Create.sql` — nhật ký thay đổi · 2026-05-13
- [x] `20260513100005_HttmCatalogs_Create.sql` — danh mục hệ thống · 2026-05-13
- [x] `20260513100006_HttmFullTextIndex.sql` — FULLTEXT INDEX trên `Name` (catalog `FT_Httm`; skip nếu instance không cài FTS) · 2026-05-13

#### 1.1.2 Views
- [x] `20260513120000_HttmViews_Map.sql` — `vw_HttmFacility_Map` · 2026-05-13
- [x] `20260513120001_HttmViews_StatsByProvince.sql` — `vw_HttmStats_ByProvince` · 2026-05-13

#### 1.1.3 Stored Procedures (Phase 1)
- [x] `sp_Httm_Facility_Search` — trong `20260513121000_HttmStoredProcedures_Phase1.sql` · 2026-05-13
- [x] `sp_Httm_Facility_GetById` — cột `IsSensitiveVisible` theo tham số `@CanViewSensitive` · 2026-05-13
- [x] `sp_Httm_Facility_Insert` — `OUTPUT inserted.Id` · 2026-05-13
- [x] `sp_Httm_Facility_Update` — COALESCE partial + `@ClearLocation` · 2026-05-13
- [x] `sp_Httm_Facility_Delete` — HARD delete · 2026-05-13
- [x] `sp_Httm_Facility_GetMapData` — bounds + types + `TOP` tối đa 2000 · 2026-05-13
- [x] `sp_Httm_Facility_GetAuditLogs` — paging · 2026-05-13
- [x] `sp_Httm_FacilityImage_Insert` / `sp_Httm_FacilityImage_Delete` · 2026-05-13
- [x] `sp_Httm_FacilityLicense_GetByFacility` / `Upsert` / `Delete` · 2026-05-13
- [x] `sp_Httm_Catalog_GetByType` · 2026-05-13
- [x] `sp_Httm_AuditLog_Insert` · 2026-05-13

#### 1.1.4 Seed data
- [x] `20260513122000_HttmCatalogs_Seed.sql` — httm_types, operation_statuses, building_quality, image_type, license_type, ownership_types, product_categories · 2026-05-13
- [x] `20260513122001_HttmFacilities_SeedSample.sql` — 6 cơ sở HN/HCM (`Notes = __httm_seed__`, cần `AspNetUsers`) · 2026-05-13

#### 1.1.5 Cấu hình hệ thống cho Map
- [x] Keys trong `dbo.AppSystemSettings` (thay `system_configs` không tồn tại trong repo): `20260513122002_HttmAppSystemSettings_Map.sql`
  - `httm.map.provider` (default `osm`), `httm.map.goong_api_key` (placeholder rỗng — mã hoá do app/ops)
  - `httm.map.default_center_lng`, `httm.map.default_center_lat`, `httm.map.default_zoom` · 2026-05-13

---

### 1.2 Backend API — `backend/src/Httm.XangDau.Api/Features/Httm/`

Tuân theo pattern `Features/{Domain}/{Contracts,Controllers,Persistence,Services}/`.

#### 1.2.1 Cấu trúc folder
- [ ] Tạo `Features/Httm/` + `HttmDependencyInjection.cs`
- [ ] Subfolder: `Controllers/`, `Services/`, `Persistence/` (Repositories + SQL helper), `Contracts/` (DTOs + requests + responses), `Validators/`, `Authorization/`

#### 1.2.2 DTOs & Contracts (`Contracts/`)
- [ ] `HttmFacilityDto.cs` — full record
- [ ] `HttmFacilityListItemDto.cs` — light cho list/search
- [ ] `HttmFacilityCreateRequest.cs`
- [ ] `HttmFacilityUpdateRequest.cs` — partial (nullable fields)
- [ ] `HttmFacilitySearchQuery.cs` — query params
- [ ] `HttmMapFeatureDto.cs` — GeoJSON Feature
- [ ] `HttmMapFeatureCollectionResponse.cs`
- [ ] `HttmFacilityImageDto.cs`, `HttmFacilityLicenseDto.cs`
- [ ] `HttmAuditLogDto.cs`
- [ ] `HttmCatalogItemDto.cs`

#### 1.2.3 Validators (`Validators/`) — FluentValidation
- [ ] `HttmFacilityCreateValidator.cs` — required: name, httm_type, province_code, status
- [ ] `HttmFacilityUpdateValidator.cs`
- [ ] `HttmFacilityImageUploadValidator.cs` — file ≤ 10MB, ext `jpg|jpeg|png|webp`

#### 1.2.4 Repositories (`Persistence/`)
- [ ] `IHttmFacilityRepository.cs` + `HttmFacilityRepository.cs` (Dapper, gọi SP)
- [ ] `IHttmCatalogRepository.cs` + `HttmCatalogRepository.cs`
- [ ] `IHttmAuditLogRepository.cs` + `HttmAuditLogRepository.cs`

#### 1.2.5 Services (`Services/`)
- [ ] `HttmFacilityService.cs` — orchestrate repo + audit + sensitive filter
- [ ] `HttmAuditService.cs` — wrapper ghi audit, capture `ip_address`, `user_agent`
- [ ] `HttmGeoScopeService.cs` — check `user.province_codes[] ⊇ facility.province_code`, raise `SCOPE_VIOLATION`
- [ ] `HttmSensitiveFieldFilter.cs` — strip `avg_rent_price`, `annual_revenue` cho non-BCT/non-ADMIN/non-HTTM_ADMIN
- [ ] `HttmMapDataService.cs` — bounds parse + clamp 2000 features
- [ ] `IHttmImageStorage.cs` — abstraction (MinIO/local), Phase 1 dùng local `/wwwroot/uploads/httm/`

#### 1.2.6 Controllers (`Controllers/`)
- [ ] `HttmFacilityController.cs` — `/api/httm/*` (CRUD, map-data, images, licenses, audit-logs)
- [ ] `HttmCatalogController.cs` — `/api/catalogs/{type}` (read-only Phase 1)
- [ ] Update `Geography` feature: kiểm tra có sẵn endpoint `provinces/districts/wards` chưa, nếu chưa thì thêm

#### 1.2.7 Authorization (`Authorization/`)
- [ ] Mở rộng `AdminPortalLoaiRoleMapper.cs`:
  ```csharp
  public const int LoaiHttmAdmin = 10;
  public const int LoaiBctStaff = 11;
  public const int LoaiSoStaff = 12;
  public const int LoaiUnitUser = 13;
  public const string HttmAdmin = "HTTM_ADMIN";
  public const string BctStaff = "BCT_STAFF";
  public const string SoStaff = "SO_STAFF";
  public const string UnitUser = "UNIT_USER";
  ```
  + cập nhật `MapRole()` và `IsFullSystemScope()` (Loai 1, 10 đều full HTTM scope; Loai 1 thêm Fuel)
- [ ] `[HttmGeoScopeAttribute]` filter — đọc `province_code` từ route/body, so với claim `province_codes`
- [ ] `[HttmSensitivePolicy]` — đính kèm DTO mapper, xoá field nhạy cảm trước khi serialize
- [ ] Policy DI: `policy.RequireRole("ADMIN","HTTM_ADMIN","BCT_STAFF")` cho sensitive endpoints

#### 1.2.8 Endpoints Phase 1
- [ ] `GET /api/httm` — search + filter + paging
- [ ] `POST /api/httm` — create (SO_STAFF+ trong tỉnh, HTTM_ADMIN+)
- [ ] `GET /api/httm/{id}` — detail (auto filter sensitive)
- [ ] `PUT /api/httm/{id}` — full update
- [ ] `PATCH /api/httm/{id}` — partial update (1 tab)
- [ ] `DELETE /api/httm/{id}` — ADMIN/HTTM_ADMIN only
- [ ] `GET /api/httm/map-data?bounds=...&types=...&province_code=...`
- [ ] `POST /api/httm/{id}/images` — multipart
- [ ] `DELETE /api/httm/{id}/images/{imgId}`
- [ ] `GET /api/httm/{id}/licenses`
- [ ] `POST /api/httm/{id}/licenses`
- [ ] `PUT /api/httm/{id}/licenses/{lid}`
- [ ] `DELETE /api/httm/{id}/licenses/{lid}`
- [ ] `GET /api/httm/{id}/audit-logs?page=&limit=`
- [ ] `GET /api/catalogs/{type}` — `httm_types|building_quality|...`
- [ ] `GET /api/catalogs/provinces` (nếu chưa có)
- [ ] `GET /api/catalogs/districts?province_code=`
- [ ] `GET /api/catalogs/wards?district_code=`

#### 1.2.9 DI & Swagger
- [ ] `HttmDependencyInjection.cs` — `AddHttmFeature()` đăng ký toàn bộ
- [ ] Gọi `AddHttmFeature()` trong `FeatureDependencyInjection.cs`
- [ ] Cập nhật OpenAPI tags + xmldoc cho mọi action

---

### 1.3 Admin Angular — `admin/src/app/features/httm/`

#### 1.3.1 Cấu trúc
- [ ] Tạo `features/httm/` + `httm.routes.ts`
- [ ] Mount vào `shell.routes.ts`: `path: 'httm'`
- [ ] Lazy-load module

#### 1.3.2 Models & Services
- [ ] `models/httm-facility.model.ts`
- [ ] `models/httm-map.model.ts` (GeoJSON types)
- [ ] `services/httm-facility.service.ts` — full CRUD
- [ ] `services/httm-catalog.service.ts`
- [ ] `services/httm-map.service.ts` — provider switch (Goong/OSM) từ `system_configs`

#### 1.3.3 Guards & Interceptors
- [ ] `guards/httm-scope.guard.ts` — kiểm role + province trước khi cho vào route
- [ ] Interceptor handle `SCOPE_VIOLATION` → toast tiếng Việt

#### 1.3.4 Pages
- [ ] `pages/httm-list/` (S3.1) — table + filter bar + map toggle button
- [ ] `pages/httm-detail/` (S3.2) — 7 tabs:
  - [ ] Tab 1: Thông tin chung
  - [ ] Tab 2: Vị trí địa lý (map picker)
  - [ ] Tab 3: Hạ tầng & quy mô
  - [ ] Tab 4: Kinh doanh (hide sensitive nếu non-BCT)
  - [ ] Tab 5: Pháp lý & giấy phép
  - [ ] Tab 6: Hình ảnh (gallery + upload)
  - [ ] Tab 7: Lịch sử thay đổi (audit log)
- [ ] `pages/httm-create/` — wizard hoặc single form
- [ ] `pages/httm-map/` (S4.1) — full map view

#### 1.3.5 Shared components
- [ ] `components/httm-filter-bar/` — tái dùng list + map
- [ ] `components/httm-map/` — wrapper Leaflet/Goong, provider-aware
- [ ] `components/httm-image-gallery/` — lightbox
- [ ] `components/httm-license-card/` — badge expiry warning
- [ ] `components/httm-type-badge/`, `httm-status-badge/`
- [ ] `components/httm-province-picker/` — cascade tỉnh/huyện/xã

#### 1.3.6 Map provider compliance
- [ ] **Verify Hoàng Sa/Trường Sa labels** trên cả 2 provider (Goong + OSM tile) — blocking, theo memory `compliance_map_provider`
- [ ] Document tile URL final ở `docs/architecture/map-providers.md`

#### 1.3.7 i18n
- [ ] Vietnamese labels — không hardcode tiếng Anh trong template

---

### 1.4 Testing

#### 1.4.1 Backend
- [ ] xUnit `HttmFacilityServiceTests` — mock repo, test sensitive filter
- [ ] xUnit `HttmGeoScopeServiceTests` — test SCOPE_VIOLATION
- [ ] Integration test `HttmFacilityController` — 1 happy path mỗi endpoint
- [ ] SP test bằng cách chạy LocalDB hoặc test container

#### 1.4.2 Frontend
- [ ] Karma test `httm-facility.service` (HTTP mock)
- [ ] E2E smoke (Playwright/Cypress): login → /httm → filter → click marker → detail

---

### 1.5 Documentation

- [ ] Cập nhật `docs/architecture/database.md` — thêm section "HTTM tables"
- [ ] Cập nhật `docs/architecture/backend.md` — thêm Features/Httm
- [ ] Tạo `docs/architecture/map-providers.md` — Goong + OSM config + tile URL
- [ ] Cập nhật `docs/modules/httm/README.md` — đổi link sang `data-model-sqlserver.md`
- [ ] Cập nhật `docs/modules/httm/api-endpoints.md` — note status code thực tế

---

### 1.6 Deliverable kiểm tra Phase 1 (Definition of Done)

- [ ] Tất cả endpoint trả 200 với data thật từ SQL Server (không mock)
- [ ] Phân quyền hoạt động: tạo user Loai=12 (SO_STAFF) gán 1 tỉnh, login, không xem được tỉnh khác → 403 SCOPE_VIOLATION
- [ ] User Loai=12 không nhận được `avg_rent_price`, `annual_revenue` trong response (verify bằng curl/Swagger)
- [ ] Admin Angular: list → filter → detail → edit → save → audit log xuất hiện
- [ ] Map data: zoom in/out OK, ≤ 2000 points, clustering khi zoom < 10
- [ ] Goong + OSM toggle hoạt động, label Hoàng Sa/Trường Sa đầy đủ
- [ ] OpenAPI swagger render đầy đủ cho `/api/httm/*` và `/api/catalogs/*`
- [ ] Mọi PR đã merge có ghi commit hash vào checklist này

---

## Phase 2 — Phiếu Khảo Sát + Public Map + Analytics

**Estimated effort**: ~4 sprint. Start sau khi Phase 1 Definition of Done.

### 2.1 Database
- [ ] `*_HttmSurveys_Create.sql` — bảng + 8 cột `JSON` (NVARCHAR(MAX) + CHECK ISJSON)
- [ ] `*_HttmSurveyHistories_Create.sql`
- [ ] Trigger auto-generate `survey_code` format `KS-{YEAR}-{PROVINCE}-{SEQ}`
- [ ] SPs: Search/Get/Insert/Update/Submit/Approve/Reject/Delete/GetHistory/Export

### 2.2 Backend
- [ ] `Features/Surveys/` folder (mirror pattern Httm)
- [ ] Workflow state machine: `draft → submitted → reviewing → approved/rejected`
- [ ] Auto-save endpoint `PATCH /api/surveys/{id}` — debounce server-side (idempotent)
- [ ] Import/Export Excel (EPPlus hoặc ClosedXML)
- [ ] `POST /api/httm/from-survey/{id}` — transform approved survey → facility

### 2.3 Admin Angular
- [ ] Module `features/surveys/`
- [ ] Form 6-bước (Reactive Forms, `FormArray` cho members/sub_units)
- [ ] Auto-save 60s (RxJS `debounceTime`)
- [ ] Preview modal trước submit
- [ ] Timeline duyệt phiếu
- [ ] Import wizard 5-step

### 2.4 Public Map Portal
- [ ] `Controllers/PublicHttmController.cs` — no-auth, filter sensitive
- [ ] Angular route `/public/map` — public layout (không sidebar admin)
- [ ] Rate limiting cho endpoint public (chống scrape)

### 2.5 Analytics
- [ ] `Features/Analytics/` — 6 endpoint chart
- [ ] Export PDF (QuestPDF) + Excel
- [ ] Page `/analytics` với recharts hoặc ng2-charts

### 2.6 Report Templates (S5.2)
- [ ] CRUD report templates
- [ ] Cron job nhắc nộp báo cáo (Quartz.NET hoặc Hangfire)

---

## Phase 3 — Mở rộng

### 3.1 Mobile
- [ ] Flutter module HTTM trong `mobile/lib/features/httm/`
- [ ] Offline-first cho surveyor field work

### 3.2 AI
- [ ] Tích hợp LocaAI dự báo nhu cầu HTTM (thêm intent vào AI Gateway)
- [ ] Phân tích trend qua Qdrant embeddings

### 3.3 Tích hợp
- [ ] SSO Bộ Công Thương (`/api/auth/sso/bct` OAuth2/SAML)
- [ ] Cổng dịch vụ công quốc gia
- [ ] Chữ ký số (USB token hoặc remote signing)

### 3.4 Open Data
- [ ] Public API `/api/open-data/httm` — read-only, filtered, rate-limited
- [ ] Documentation theo chuẩn OpenAPI/Swagger public

---

## Lịch sử thay đổi checklist

| Ngày | Người | Thay đổi |
|------|-------|----------|
| 2026-05-13 | Claude | Khởi tạo checklist từ docs/modules/httm/* + 7 decisions D1-D7 |
| 2026-05-13 | Agent | Git commit `b5ec412`: §1.1.1–§1.1.5 (migrations SQL + cập nhật checklist) |
