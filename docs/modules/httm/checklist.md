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
- [x] Tạo `Features/Httm/` + `HttmDependencyInjection.cs` · 2026-05-13
- [x] Subfolder: `Controllers/`, `Services/`, `Persistence/`, `Contracts/`, `Validators/`, `Authorization/` (`.gitkeep`) · 2026-05-13

#### 1.2.2 DTOs & Contracts (`Contracts/`)
- [x] `HttmFacilityDto.cs` — full record (trong `HttmFacilityDtos.cs`) · 2026-05-13
- [x] `HttmFacilityListItemDto.cs` · 2026-05-13
- [x] `HttmFacilityCreateRequest.cs` · 2026-05-13
- [x] `HttmFacilityUpdateRequest.cs` — partial + `ClearLocation` · 2026-05-13
- [x] `HttmFacilitySearchQuery.cs` · 2026-05-13
- [x] `HttmMapDtos.cs` — `HttmMapPointGeometryDto`, `HttmMapFeatureDto`, `HttmMapFeaturePropertiesDto`, `HttmMapFeatureCollectionResponse` · 2026-05-13
- [x] `HttmFacilityImageDto.cs`, `HttmFacilityLicenseDto.cs` · 2026-05-13
- [x] `HttmAuditLogDto.cs` · 2026-05-13
- [x] `HttmCatalogItemDto.cs` · 2026-05-13

#### 1.2.3 Validators (`Validators/`) — FluentValidation
- [x] `HttmFacilityCreateValidator.cs` — required: name, httm_type, province_code, status · 2026-05-13
- [x] `HttmFacilityUpdateValidator.cs` · 2026-05-13
- [x] `HttmFacilityImageUploadValidator.cs` — file ≤ 10MB, ext `jpg|jpeg|png|webp` · 2026-05-13

#### 1.2.4 Repositories (`Persistence/`)
- [x] `IHttmFacilityRepository.cs` + `HttmFacilityRepository.cs` (Dapper, gọi SP) · 2026-05-13
- [x] `IHttmCatalogRepository.cs` + `HttmCatalogRepository.cs` · 2026-05-13
- [x] `IHttmAuditLogRepository.cs` + `HttmAuditLogRepository.cs` · 2026-05-13

#### 1.2.5 Services (`Services/`)
- [x] `HttmFacilityService.cs` — orchestrate repo + audit + sensitive filter · 2026-05-13
- [-] `HttmAuditService.cs` — không tách class; ghi audit + IP/UA trong `HttmFacilityService` qua `IHttmAuditLogRepository` · 2026-05-13
- [x] `HttmGeoScopeService.cs` — static helpers + claim `httm_province_codes` (không raise attribute; service trả 403) · 2026-05-13
- [-] `HttmSensitiveFieldFilter.cs` — không tách; strip trong `GetById`/`Search` mapping trong service · 2026-05-13
- [-] `HttmMapDataService.cs` — không tách; map-data trong `HttmFacilityService` + SP `sp_Httm_Facility_GetMapData` · 2026-05-13
- [x] `IHttmImageStorage.cs` + `LocalHttmImageStorage` — `/wwwroot/uploads/httm/` · 2026-05-13

#### 1.2.6 Controllers (`Controllers/`)
- [x] `HttmFacilityController.cs` — `/api/httm/*` (CRUD, map-data, images, licenses, audit-logs) · 2026-05-13
- [x] `HttmCatalogController.cs` — `/api/catalogs/{type}` + provinces/districts/wards (ủy quyền `IGeographyReadService`) · 2026-05-13
- [x] `Geography`: đã có `api/geography/...` (`GeographyController`); catalog mirror tại `api/catalogs/...` · 2026-05-13

#### 1.2.7 Authorization (`Authorization/`)
- [x] Mở rộng `AdminPortalLoaiRoleMapper.cs`:
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
- [-] `[HttmGeoScopeAttribute]` — chưa tách filter MVC; kiểm tra phạm vi trong `HttmFacilityService` · 2026-05-13
- [-] `[HttmSensitivePolicy]` — chưa; strip field nhạy cảm trong service/repo · 2026-05-13
- [-] Policy DI ASP.NET riêng — chưa; phân quyền theo `Loai` + claims trong service · 2026-05-13

#### 1.2.8 Endpoints Phase 1
- [x] `GET /api/httm` — search + filter + paging · 2026-05-13
- [x] `POST /api/httm` — create (SO_STAFF+ trong tỉnh, HTTM_ADMIN+) · 2026-05-13
- [x] `GET /api/httm/{id}` — detail (auto filter sensitive) · 2026-05-13
- [x] `PUT /api/httm/{id}` — full update · 2026-05-13
- [x] `PATCH /api/httm/{id}` — partial update (1 tab) · 2026-05-13
- [x] `DELETE /api/httm/{id}` — ADMIN/HTTM_ADMIN only · 2026-05-13
- [x] `GET /api/httm/map-data` — query `west,south,east,north` + `types`, `provinceCode`, `maxRows` · 2026-05-13
- [x] `POST /api/httm/{id}/images` — multipart · 2026-05-13
- [x] `DELETE /api/httm/{id}/images/{imgId}` · 2026-05-13
- [x] `GET /api/httm/{id}/licenses` · 2026-05-13
- [x] `POST /api/httm/{id}/licenses` · 2026-05-13
- [x] `PUT /api/httm/{id}/licenses/{lid}` · 2026-05-13
- [x] `DELETE /api/httm/{id}/licenses/{lid}` · 2026-05-13
- [x] `GET /api/httm/{id}/audit-logs` — query `page`, `pageSize` · 2026-05-13
- [x] `GET /api/catalogs/{type}` — `httm_types|building_quality|...` · 2026-05-13
- [x] `GET /api/catalogs/provinces` · 2026-05-13
- [x] `GET /api/catalogs/districts?province_code=` · 2026-05-13
- [x] `GET /api/catalogs/wards?district_code=` · 2026-05-13

#### 1.2.9 DI & Swagger
- [x] `HttmDependencyInjection.cs` — `AddHttmFeature()` đăng ký repos, `IHttmFacilityService`, `IHttmImageStorage`, FluentValidation · 2026-05-13
- [x] Gọi `AddHttmFeature()` trong `FeatureDependencyInjection.cs` · 2026-05-13
- [x] OpenAPI: `GenerateDocumentationFile` + `IncludeXmlComments` trong `Program.cs`; xmldoc trên action `HttmFacilityController` / `HttmCatalogController` · 2026-05-13

---

### 1.3 Admin Angular — `admin/src/app/features/httm/`

#### 1.3.1 Cấu trúc
- [x] Tạo `features/httm/` + `httm.routes.ts` · 2026-05-13
- [x] Mount lazy route `path: 'httm'` trong `retail.routes.ts` (cùng shell đã đăng nhập) · 2026-05-13
- [x] Lazy-load `HTTM_ROUTES` + `HttmShellComponent` · 2026-05-13

#### 1.3.2 Models & Services
- [x] `models/httm-facility.model.ts` · 2026-05-13
- [x] `models/httm-map.model.ts` (GeoJSON types) · 2026-05-13
- [x] `services/httm-facility.service.ts` — CRUD, map-data, audit, licenses, upload ảnh · 2026-05-13
- [x] `services/httm-catalog.service.ts` · 2026-05-13
- [-] `services/httm-map.service.ts` — OSM/Goong tại client; chưa đọc `AppSystemSettings` (Goong preview dùng nền Carto) · 2026-05-13

#### 1.3.3 Guards & Interceptors
- [x] `guards/httm-scope.guard.ts` — `HTTM_PORTAL_ROLES` · 2026-05-13
- [x] `httm-scope-feedback.interceptor.ts` — 403 `/api/httm` + `MatSnackBar` · 2026-05-13

#### 1.3.4 Pages
- [x] `pages/httm-list-page` — bảng + lọc + link bản đồ · 2026-05-13
- [x] `pages/httm-detail-page` — 7 tab (tab 2 chưa map picker; tab 6 gallery placeholder + upload) · 2026-05-13
  - [x] Tab 1–7 MVP · 2026-05-13
- [x] `pages/httm-create-page` — form đơn · 2026-05-13
- [x] `pages/httm-map-page` — Leaflet + API + nhãn Hoàng Sa/Trường Sa · 2026-05-13

#### 1.3.5 Shared components
- [x] `components/httm-filter-bar` — bọc `FilterPanel` · 2026-05-13
- [-] `components/httm-map` — chưa tách; logic trong `httm-map-page` · 2026-05-13
- [-] `components/httm-image-gallery` — placeholder (chưa API list ảnh) · 2026-05-13
- [x] `components/httm-license-card` · 2026-05-13
- [x] `components/httm-type-badge`, `httm-status-badge` · 2026-05-13
- [-] `components/httm-province-picker` — chưa; select tỉnh đơn · 2026-05-13

#### 1.3.6 Map provider compliance
- [x] Nhãn Hoàng Sa / Trường Sa trên bản đồ HTTM (`mountSeaIslandGeoLabels`, nền OSM/Carto) · 2026-05-13
- [x] `docs/architecture/map-providers.md` — tile URL + Goong placeholder + `AppSystemSettings` · 2026-05-13

#### 1.3.7 i18n
- [x] Nhãn UI tiếng Việt chủ đạo; mã API/catalog giữ theo backend · 2026-05-13

---

### 1.4 Testing

#### 1.4.1 Backend
- [x] xUnit `HttmFacilityServiceTests` — mock repo + portal; SO strip `AvgRentPrice`/`AnnualRevenue`; Search SO (mặc định tỉnh, 403 ngoài phạm vi, empty khi không claim) · 2026-05-13
- [x] xUnit `HttmGeoScopeServiceTests` — claim tỉnh + `CanAccessProvince` · 2026-05-13
- [x] xUnit `HttmFacilityControllerTests` — mock `IHttmFacilityService` (403/404) · 2026-05-13
- [-] Integration / SP test tự động — chưa · 2026-05-13

#### 1.4.2 Frontend
- [x] Karma `httm-facility.service.spec.ts` (HTTP mock) · 2026-05-13
- [-] E2E smoke — chưa · 2026-05-13

---

### 1.5 Documentation

- [x] `docs/architecture/database.md` — section **6. HTTM** · 2026-05-13
- [x] `docs/architecture/backend.md` — section **7. HTTM module** · 2026-05-13
- [x] `docs/architecture/map-providers.md` · 2026-05-13
- [x] `docs/modules/httm/README.md` — thêm link `map-providers.md` (đã có `data-model-sqlserver.md`) · 2026-05-13
- [x] `docs/modules/httm/api-endpoints.md` — status thực tế + `/api/catalogs` · 2026-05-13

---

### 1.6 Deliverable kiểm tra Phase 1 (Definition of Done)

- [~] Endpoint + DB thật — verify thủ công sau migration/seed · 2026-05-13
- [~] SO_STAFF + SCOPE — verify thủ công · 2026-05-13
- [~] Ẩn trường nhạy cảm với Loai=12 — verify thủ công · 2026-05-13
- [~] Angular list → detail → save → audit — verify thủ công · 2026-05-13
- [~] Clustering map khi zoom thấp — chưa implement · 2026-05-13
- [~] Goong tile thật — chưa; nhãn HS/TS có trên OSM/Carto · 2026-05-13
- [x] Swagger mô tả XML cho HTTM (`IncludeXmlComments`) · 2026-05-13
- [~] Ghi hash PR — cập nhật khi merge (mục Lịch sử) · 2026-05-13

---

## Phase 2 — Phiếu Khảo Sát + Public Map + Analytics

**Estimated effort**: ~4 sprint. Start sau khi Phase 1 Definition of Done.

### 2.1 Database
- [x] `20260513150000_HttmSurveyCounters_Create.sql` — bảng đếm mã KS-{YEAR}-{PROVINCE}-{SEQ} · 2026-05-13
- [x] `20260513150100_HttmSurveys_Create.sql` — `HttmSurveys` + 8 cột JSON (`Step1`…`Step7`, `ConfirmerData`) + `HttmType`; FK `LinkedFacilityId` / `SourceSurveyId` có điều kiện · 2026-05-13
- [x] `20260513150200_HttmSurveyHistories_Create.sql` — `HttmSurveyHistories` · 2026-05-13
- [x] `20260513151000_HttmSurveyStoredProcedures_Phase2.sql` — SP Insert/Search/Get/Patch/Submit/Approve/Reject/Review/Delete/History + `sp_Httm_Facility_LinkSourceSurvey` · 2026-05-13

### 2.2 Backend
- [x] `Features/Surveys/` — mirror Httm (Controllers, Contracts, Persistence, Services, Validators, `SurveysDependencyInjection`) · 2026-05-13
- [x] Workflow: `draft|rejected` → `submitted` → `reviewing` → `approved|rejected` (SP + service) · 2026-05-13
- [x] `PATCH /api/surveys/{id}` — auto-save (idempotent COALESCE trong SP) · 2026-05-13
- [-] Import/Export Excel — chưa · 2026-05-13
- [x] `POST /api/httm/from-survey/{id}` — map JSON bước 1–2 + `LinkSourceSurvey` · 2026-05-13

### 2.3 Admin Angular
- [~] Module `features/surveys/` — list + chi tiết (7 bước JSON + confirmer), chưa FormArray wizard đầy đủ · 2026-05-14
- [~] Form 6-bước — dùng tab + JSON từng bước (thay thế tạm cho FormArray phức tạp) · 2026-05-14
- [x] Auto-save 60s (`debounceTime(60000)` trên `valueChanges`) · 2026-05-14
- [x] Preview modal (Material Dialog) trước khi thao tác nộp/duyệt (xem JSON) · 2026-05-14
- [x] Timeline duyệt (`GET .../history`) · 2026-05-14
- [-] Import wizard 5-step — chưa · 2026-05-14

### 2.4 Public Map Portal
- [x] `PublicHttmController` — `GET /api/public/httm/map-data`, `[AllowAnonymous]`, rate limit · 2026-05-14
- [x] Angular route `/public/map` — không shell admin, Leaflet + API công khai · 2026-05-14
- [x] Rate limiting policy `public-httm` (`Program.cs`) · 2026-05-14

### 2.5 Analytics
- [x] `Features/Analytics/` — 6 endpoint chart + `summary` · 2026-05-14
- [x] Export CSV tổng hợp (`GET .../export/summary.csv`) · 2026-05-14
- [-] Export PDF (QuestPDF) + Excel — chưa · 2026-05-14
- [x] Trang `/httm/analytics` (Chart.js) · 2026-05-14

### 2.6 Report Templates (S5.2)
- [x] CRUD report templates (`/api/httm-report-templates` + trang `/httm/report-templates`) · 2026-05-14
- [~] Nhắc nộp báo cáo — `ReportTemplateReminderWorker` (HostedService 12h + chạy lúc khởi động), log + `TouchReminder`; không dùng Quartz/Hangfire · 2026-05-14

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
| 2026-05-13 | Agent | §1.2.2 Contracts HTTM (`Features/Httm/Contracts/*.cs`) |
| 2026-05-13 | Agent | Git commit `ae06a82`: Phase 1 backend API HTTM (controllers, SP, DI) |
| 2026-05-13 | Agent | Git commit `cbc80f0`: Admin Angular HTTM §1.3 + portal Loai 10–12 |
| 2026-05-14 | Agent | Phase 2 tiếp: `public-httm` rate limit, `HttmPhase2Features` (analytics + report templates + worker), Angular surveys/public map/analytics/report-templates + nav |
