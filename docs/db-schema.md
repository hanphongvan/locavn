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
