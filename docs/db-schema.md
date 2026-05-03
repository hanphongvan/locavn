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
