# Database schema extensions (API / mobile)

Canonical long-form table documentation lives in [architecture/database.md](architecture/database.md).

## Quỹ bình ổn xăng dầu (Lãnh đạo — mobile / .NET API)

**Không có bảng riêng trong repo API.** Dữ liệu lấy từ CSDL DMPPortal hiện có:

- **`dbo.sp_Dashboard_FuelStabilizationFund`** — cùng nguồn với `DMPPortal` `DashboardController.GetFuelStabilizationFund` (Biểu 08, `BaoCaoId = 4C60DBAA-C69E-4878-B214-933D653D4F44`, kỳ `THANG`).
- **`DM_DonVi`** — địa chỉ và lọc đầu mối `CapDonViId = 235` (hằng `PetrolWholesaleConstants.CapDonViId`).

### HTTP (Leader JWT)

- `GET /api/leader/stabilization-fund/summary` — không query: máy chủ chọn **kỳ BC08 mới nhất** (giờ VN, mốc ngày trong tháng từ cấu hình).
- `GET /api/leader/stabilization-fund/summary?month=&year=` — kỳ cụ thể (cả hai tham số hợp lệ).
- `GET /api/leader/stabilization-fund/distributors` (tùy chọn `?month=&year=`) — cùng quy tắc.
- `GET /api/leader/stabilization-fund/distributors/{id}/history` (tùy chọn `?month=&year=`) — cùng quy tắc.

**Cấu hình độ trễ kỳ “mới nhất”:** bảng `dbo.AppSystemSettings` (`SettingKey`, `SettingValue`), seed `Leader.StabilizationFund.ReportCutoffDayOfMonth` = `20`. Nếu ngày hiện tại (VN) **lớn hơn** mốc thì kỳ mới nhất là **tháng trước**; ngược lại là **tháng trước nữa** (ví dụ mốc 20: 30/04 → tháng 3; 18/04 → tháng 2). Migration: `20260531140000_AddAppSystemSettings`.

### Gỡ bảng/SP tạm (nếu đã từng tạo trên DB)

Migration `20260531120000_DropPetroleumStabilizationFundLeaderArtifacts` chạy `DROP IF EXISTS` cho `PetroleumStabilizationFundReports` và các `sp_Leader_StabilizationFund_*` nếu còn sót từ bản build cũ.

Migration `20260530120000_AddPetroleumStabilizationFundReportsAndProcedures` được giữ dưới dạng **no-op** để chuỗi EF khớp DB đã apply; không tạo thêm đối tượng CSDL.

## Bán lẻ — Lãnh đạo (Lãnh đạo — mobile / .NET API)

**Không có bảng/cột mới.** Reuse `DM_DonVi` cho cửa hàng bán lẻ (`CapDonViId = 248`, hằng `PetrolRetailConstants.CapDonViId`) + `DM_Tinh` cho tỉnh.

### Schema impact (migration `20260601120000_AddLeaderRetailQueriesAndStoredProcedures`)

- **Bảng**: không thay đổi.
- **Cột**: không thay đổi.
- **Index**: không thay đổi.
- **Foreign key**: không thay đổi.
- **Stored procedure**: thêm 3 SP (idempotent qua `CREATE OR ALTER`):
  - `dbo.sp_LeaderRetail_GetDashboard(@ProvinceId INT NULL, @Status BIT NULL, @ManagingUnitId INT NULL, @RetailCapDonViId INT)` — 3 result set:
    1. KPI: `TotalStores`, `ActiveStores`, `PausedStores`.
    2. Ranking theo tỉnh: `ProvinceId`, `ProvinceCode`, `ProvinceName`, `TotalStores`, `ActiveStores`, `PausedStores`, `LastUpdatedAt`.
    3. Cửa hàng raw cho rule engine C# (`StationId`, `StationName`, `ProvinceId/Name`, `ManagingUnitId/Name`, `ViDo`, `KinhDo`, `TrangThai`, `Modified`).
  - `dbo.sp_LeaderRetail_GetManagingUnits(@RetailCapDonViId INT)` — `ManagingUnitId`, `ManagingUnitCode`, `ManagingUnitName`, `StoreCount` (chỉ đơn vị có cửa hàng bên dưới **và bản thân đơn vị quản lý cũng `CapDonViId = @RetailCapDonViId`** — fix `20260601140000_FixLeaderRetailManagingUnitsRequireRetailCapDonViId`).
  - `dbo.sp_LeaderRetail_GetProvinces(@RetailCapDonViId INT)` — `ProvinceId`, `ProvinceCode`, `ProvinceName`, `StoreCount`.

### HTTP (Leader JWT)

- `GET /api/leader/retail/dashboard?provinceId=&status=&managingUnitId=` — KPI + ranking + cảnh báo (rule engine C#).
- `GET /api/leader/retail/managing-units` — dropdown filter "Đơn vị quản lý".
- `GET /api/leader/retail/provinces` — dropdown filter "Tỉnh".

### Quy ước trạng thái (đồng bộ `sp_Reports_GetStationOverview`)

- `DM_DonVi.TrangThai` `NULL` hoặc `1` ⇒ Hoạt động.
- `DM_DonVi.TrangThai = 0` ⇒ Tạm dừng.

### Cảnh báo / rule engine (C#, không nằm trong SP)

`Features/Leader/Services/LeaderRetailWarningRules.cs` — 5 rule độc lập trong scope `DM_DonVi`:

- `MISSING_COORDS`, `STALE_DATA`, `MISSING_MANAGING_UNIT` (per-station)
- `LOW_ACTIVE_RATE`, `HIGH_PAUSED_COUNT` (per-province)

Threshold gom 1 chỗ tại `LeaderRetailWarningThresholds.cs` (TODO: chuyển sang `AppSystemSettings` khi cần đổi không redeploy).

Reserved cho phase sau (cần JOIN bảng khác): `MISSING_PRICES` (`StationPrices`), `ABNORMAL_INVENTORY` (`QT_TK_ThongKe`).

## Loca AI Leader Assistant — Phase 1A foundation

### Migration `20260506120000_AddLeaderAiFoundationTables`

Foundation cho module Loca AI Leader (`POST /api/leader-ai/*`, chỉ user `Loai = 6`). Phase 1A chỉ tạo schema + SP mock; chưa kết nối AI Gateway thật. Tài liệu thiết kế đầy đủ: [`docs/loca-ai-leader-v2.md`](loca-ai-leader-v2.md) (Section 3 schema, Section 11 SP output).

#### 8 bảng mới (tất cả idempotent qua `IF OBJECT_ID IS NULL`)

| Bảng | Mục đích | Khoá ngoại | Index chính |
|---|---|---|---|
| `dbo.AiConversations` | Phiên hội thoại của user | — | `IX_AiConversations_UserId_CreatedAt` (filter `IsDeleted = 0`) |
| `dbo.AiMessages` | Mỗi message user/assistant/tool/system | `ConversationId → AiConversations.Id` | `IX_AiMessages_ConversationId_CreatedAt` |
| `dbo.AiConversationContexts` | State context theo hội thoại (lastIntent, lastRegion, ...) | `ConversationId → AiConversations.Id` | `IX_AiConversationContexts_ConversationId` |
| `dbo.AiResultSnapshots` | Cache kết quả tool để tái sử dụng | `ConversationId → AiConversations.Id` | `IX_AiResultSnapshots_ConversationId_ExpiresAt` |
| `dbo.AiToolLogs` | Log mọi tool call (input/output/duration) | — | `IX_AiToolLogs_UserId_CreatedAt` |
| `dbo.AiSecurityAuditLogs` | Log request bị Security Guard chặn | — | `IX_AiSecurityAuditLogs_UserId_CreatedAt` |
| `dbo.AiIntentConfigs` | Cấu hình intent theo `Loai` (bật/tắt không cần deploy) | — | `UQ_AiIntentConfigs_IntentCode` (UNIQUE) |
| `dbo.AiRateLimitLogs` | Counter request/phút·giờ·ngày cho rate limit | — | `IX_AiRateLimitLogs_UserId_WindowType_WindowStart` |

#### Seed data — `AiIntentConfigs`

12 intent Phase 1 (idempotent qua `NOT EXISTS`): `FUEL_INVENTORY_SUMMARY`, `FUEL_INVENTORY_BY_REGION`, `FUEL_INVENTORY_BY_HEAD_OFFICE`, `HEAD_OFFICE_LOW_STOCK_RANKING`, `FUEL_PRICE_TREND`, `IMPORT_EXPORT_SUMMARY`, `STATION_DENSITY_ANALYSIS`, `STATION_MAP_LAYER`, `GENERATE_LEADER_REPORT`, `LEADER_DASHBOARD_EXPLAIN`, `HELP_USAGE`, `UNKNOWN`. Tất cả `RequiredRoleLoai = 6`, `IsEnabled = 1`.

#### 4 stored procedure mock (Phase 1A — chưa query bảng tồn kho thật)

| SP | Tham số | Output schema |
|---|---|---|
| `dbo.sp_Ai_GetFuelInventorySummary` | `@RegionId INT NULL, @ProvinceId INT NULL, @FromDate DATE NULL, @ToDate DATE NULL, @FuelType NVARCHAR(100) NULL` | `FuelType, TotalStock, StockUnit, PreviousPeriodStock, ChangePercent, MinSafeStock, IsLowStock, RegionId, RegionName, AsOfDate` |
| `dbo.sp_Ai_GetFuelPriceTrend` | `@FuelType NVARCHAR(100) = 'RON95', @PeriodCount INT = 3` | `FuelType, PeriodIndex, PeriodLabel, EffectiveDate, Price, PriceUnit, ChangeFromPrev` |
| `dbo.sp_Ai_GetInventoryByHeadOffice` | `@RegionId INT NULL, @ProvinceId INT NULL, @FuelType NVARCHAR(100) = 'RON95', @Top INT = 20` | `HeadOfficeId, HeadOfficeCode, HeadOfficeName, FuelType, TotalStock, StockUnit, MinSafeStock, IsLowStock, RankNumber` |
| `dbo.sp_Ai_GetStationDensityByProvince` | `@RegionId INT NULL, @ProvinceId INT NULL` | `ProvinceId, ProvinceCode, ProvinceName, RegionId, RegionName, StationCount, AreaKm2, DensityPer100Km2, DensityCategory` |

> **Quy tắc bắt buộc (Section 13.1 tài liệu thiết kế):** AI Gateway không bao giờ truy cập DB trực tiếp. Mọi query data analytics phải đi qua SP whitelist này. Phase 1A — chỉ CRUD `AiConversations` / `AiMessages` / `AiRateLimitLogs` (state nội bộ, không phải data analytics) qua Dapper.

#### HTTP (Leader JWT, `Loai = 6`)

- `POST /api/leader-ai/chat` — chat chính, trả JSON đầy đủ.
- `POST /api/leader-ai/chat/stream` — SSE streaming (text/event-stream).
- `GET /api/leader-ai/conversations` — danh sách hội thoại chưa xoá.
- `GET /api/leader-ai/conversations/{id}` — chi tiết. `404` nếu không tìm thấy / khác user.
- `DELETE /api/leader-ai/conversations/{id}` — soft delete (`IsDeleted = 1`).
- `POST /api/leader-ai/report` — sinh báo cáo Markdown.
- `GET /api/leader-ai/health` — `[AllowAnonymous]`, không qua rate limit.

#### Cấu hình

- `AiGateway:BaseUrl` (`appsettings.json`), `AiGateway:InternalKey` (env var `AI_GATEWAY_INTERNAL_KEY` — không commit).
- `RateLimit:PerMinute = 5`, `RateLimit:PerHour = 20`, `RateLimit:PerDay = 50`.

### Migration `20260507120000_UpdateLeaderAiSpsToRealQueries` — Phase 2A

Chuyển 4 SP `sp_Ai_*` từ mock VALUES (Phase 1A) sang query bảng thật. **Output schema không đổi** (Section 11). `CREATE OR ALTER` nên rerun-safe.

**Mapping nghiệp vụ** (TODO domain expert review):

| SP | Nguồn dữ liệu chính | Field NULL ở Phase 2A |
|---|---|---|
| `sp_Ai_GetFuelInventorySummary` | `StationInventoryTransactionDetails` × `Headers` × `FuelProducts` × `DM_DonVi` | `PreviousPeriodStock`, `ChangePercent`, `MinSafeStock`, `RegionName` |
| `sp_Ai_GetFuelPriceTrend` | `StationProductPrices` AVG theo `EffectiveDate` × `FuelProducts.Code` | — (đầy đủ qua LAG window function) |
| `sp_Ai_GetInventoryByHeadOffice` | recursive CTE `DM_DonVi.CapTrenId` để resolve cấp đầu mối (`CapDonViId = 235`) | `MinSafeStock` |
| `sp_Ai_GetStationDensityByProvince` | `COUNT(DM_DonVi WHERE CapDonViId = 248)` retail theo `Tinh` | `AreaKm2`, `DensityPer100Km2`, `RegionName` |

`@WholesaleCap = 235` và `@RetailCap = 248` đang hard-code trong SP — Phase 3 sẽ chuyển sang `AppSystemSettings` để đổi không cần redeploy.

### Phase 2A — Internal endpoints (AI Gateway → .NET)

Layer 4 defense-in-depth — AI Gateway gọi 4 SP qua HTTP nội bộ thay vì connection string trực tiếp.

| Method | Endpoint | SP target | Auth |
|---|---|---|---|
| POST | `/internal/ai/fuel-inventory` | `sp_Ai_GetFuelInventorySummary` | `X-Internal-Key` |
| POST | `/internal/ai/fuel-price` | `sp_Ai_GetFuelPriceTrend` | `X-Internal-Key` |
| POST | `/internal/ai/head-office` | `sp_Ai_GetInventoryByHeadOffice` | `X-Internal-Key` |
| POST | `/internal/ai/station-density` | `sp_Ai_GetStationDensityByProvince` | `X-Internal-Key` |
| POST | `/internal/ai/log` | INSERT `AiToolLogs` (token usage Section 9) | `X-Internal-Key` |

`InternalKeyOnlyAttribute`: header phải khớp `AiGateway:InternalKey`. Config rỗng → 503 (chặn deploy nhầm), header sai/thiếu → 401, `[AllowAnonymous]` được tôn trọng.
