# API module mapping (proposed backend)

<!-- TODO(domain-split): Module list bao phủ DMPPortal chung; một số module phục vụ Fuel (stations, store-admin), một số phục vụ báo cáo HTTM — khi tách nhánh tài liệu, mirror hoặc liên kết từ docs/modules/fuel/ và httm/. -->

This document proposes **backend modules** for an ASP.NET Core Web API and maps each module to **real tables** listed in **`docs/architecture/database.md`**. No tables are invented. Modules that would only serve **gaps** (no supporting tables) are listed under **Deferred / external** rather than given fake persistence.

---

## Module overview

| Proposed module | Primary purpose | Tables used (from `docs/architecture/database.md`) |
|-----------------|-----------------|----------------------------------------|
| **Geography** | Provinces and communes/wards for labels and filters | `DM_Tinh`, `DM_XaPhuong` |
| **Organizations (stations / units)** | List/detail for organizational units that may represent stations | `DM_DonVi` |
| **Licenses** | Petrol (and other) business licenses per unit | `TK_QuanLyGiayPhep` |
| **Fuel depots** | Depots, allocations, contracts, stock snapshots | `TK_QuanLyKhoXangDau`, `TK_QuanLyKhoXangDau_PhanBoDungTich`, `TK_QuanLyKhoXangDau_HopDong`, `TK_QuanLyKhoXangDau_TonKho` |
| **Reporting — periods** | Report instances, periods, unit linkage | `QT_TK_ThongKe`, `QT_TK_ChotSoLieu` |
| **Reporting — detail** | Report lines and numeric values | `QT_TK_ThongKeChiTiet`, `QT_TK_ThongKeChiTiet02` |
| **Reporting — definitions** | Indicator metadata for interpreting lines | `TK_ChiTieuBaoCao` |
| **Reporting — assignment** | Who must file which report and when | `TK_GiaoBaoCao`, `TK_GiaoBaoCaoChiTiet` |
| **Reporting — exports** | Transferred / template-specific statistic tables | `QT_TK_ThongKeChiTiet_ChuyenDuLieu`, `QT_TK_ThongKeChiTiet_ChuyenDuLieu_Mau02`, `QT_TK_ThongKeChiTiet_ChuyenDuLieu_Mau05`, `QT_TK_ThongKeChiTiet_ChuyenDuLieu_Mau06`, `QT_TK_ThongKeChiTiet_ChuyenDuLieu_Mau07`, `QT_TK_ThongKeChiTiet_ChuyenDuLieu_Mau07a`, `QT_TK_ThongKeChiTiet_ChuyenDuLieu_Mau08` |
| **Identity (optional)** | Staff/admin authentication only if in scope | `AspNetUsers`, `AspNetRoles`, `AspNetUserRoles`, `AspNetUserClaims`, `AspNetUserLogins`, `PasswordResetTokens` (quên mật khẩu / email), `UserDataDeletionRequests` (yêu cầu xoá dữ liệu — ghi nhận) |
| **Station ratings (visitor)** | Đánh giá 1–5 sao, bình luận tùy chọn, đường dẫn ảnh (tối đa 5) | `StationRatings`, `StationRatingImages` — `StationId` → `DM_DonVi.Id` |

**Public API:** `POST /api/station-ratings`, `GET /api/station-ratings/summary/{stationId}`, `GET /api/station-ratings/station/{stationId}` — chỉ gọi stored procedure (`dbo.sp_StationRating_*`).

**Auth — quên / đặt lại mật khẩu (LocaVN):** `POST /api/auth/forgot-password` (phản hồi thống nhất, không lộ email), `POST /api/auth/reset-password` (token từ email, hash legacy giống `POST /api/auth/change-password`). Cấu hình `PasswordReset:WebResetPasswordBaseUrl`, SMTP (`Smtp:*`), rate limit IP trên hai endpoint.

**Quyền riêng tư (mobile / portal JWT):** `POST /api/user/request-delete-data` — body `{ requestType, scope, note }`, lưu `UserDataDeletionRequests` trạng thái `Pending`; không xoá dữ liệu ngay; trùng `Pending` → 409.

---

## Geography

**Tables:** `DM_Tinh`, `DM_XaPhuong`

**Notes:** `DM_XaPhuong.QuanHuyenId` references **`DM_QuanHuyen`**, which is **not** included in the 27-table schema document. District endpoints would require that table to exist in the live DB **and** be added to the documented schema before treating it as contractual.

---

## Organizations (stations / units)

**Tables:** `DM_DonVi`

**Joins (same document only):** optional read-side join from `DM_DonVi.Tinh` → `DM_Tinh.Id` and `DM_DonVi.Xa` → `DM_XaPhuong.Id` if data integrity allows.

---

## Licenses

**Tables:** `TK_QuanLyGiayPhep`

**Joins:** `DonViId` → `DM_DonVi.Id`. `DonViCapId` targets `DM_NoiCapGiayPhep` (not in the 27-table list).

---

## Fuel depots

**Tables:** `TK_QuanLyKhoXangDau`, `TK_QuanLyKhoXangDau_PhanBoDungTich`, `TK_QuanLyKhoXangDau_HopDong`, `TK_QuanLyKhoXangDau_TonKho`

**Joins:** `TK_QuanLyKhoXangDau.DonViId` → `DM_DonVi.Id`; allocation and stock chains follow documented FKs (`KhoId`, `PhanBoId`).

---

## Reporting — periods

**Tables:** `QT_TK_ThongKe`, `QT_TK_ChotSoLieu`

**Joins:** `QT_TK_ThongKe.don_vi_cap1` → `DM_DonVi.Id`; detail children use `ThongKeId` / `BaoCaoId` as documented.

---

## Reporting — detail

**Tables:** `QT_TK_ThongKeChiTiet`, `QT_TK_ThongKeChiTiet02`

**Joins:** `ThongKeId` → `QT_TK_ThongKe.Id`; `ChiTieuThongKeId` → `TK_ChiTieuBaoCao.Id`; `QT_TK_ThongKeChiTiet02` also references `DM_HangHoa`, `DM_NhaCungCap`, `DM_XuatXu` per global relationships (tables not in the 27-table doc).

---

## Reporting — definitions

**Tables:** `TK_ChiTieuBaoCao`

**Role:** Required to interpret `So_XX` / line labels safely for fuel price, declarations, or any stabilization-related numeric if domain maps them here.

---

## Reporting — assignment

**Tables:** `TK_GiaoBaoCao`, `TK_GiaoBaoCaoChiTiet`

**Role:** Scheduling and unit assignment for reporting cycles; pairs with period/detail modules for “declaration window” style APIs.

---

## Reporting — exports

**Tables:** all `QT_TK_ThongKeChiTiet_ChuyenDuLieu*` variants listed in `docs/architecture/database.md`

**Role:** Read-only APIs for pre-aggregated or transferred rows per template (`Mau02`, `Mau05`, …). Usually one template per integration after domain choice.

---

## Identity (optional)

**Tables:** `AspNetUsers`, `AspNetRoles`, `AspNetUserRoles`, `AspNetUserClaims`, `AspNetUserLogins`

**Role:** Internal portal users only; citizen-facing apps typically **do not** use these tables without a separate product decision.

---

## Deferred / external (no dedicated module on this schema alone)

| Concern | Reason |
|---------|--------|
| **Map coordinates** | No coordinate columns in `docs/architecture/database.md`. |
| **Station services (amenities)** | No explicit tables/columns; optional future use of undocumented code lists for `DM_DonVi` fields. |
| **Stabilization fund** | Not named in schema; may require indicator mapping via `TK_ChiTieuBaoCao` + expert input. |
| **Citizen complaints** | No tables in `docs/architecture/database.md`. |
| **District (`DM_QuanHuyen`)** | Not in documented table list. |

---

## Leader dashboard (mobile, `Loai == 6`)

**Auth:** Bearer JWT; claim **`Loai`** must be **`6`**. Same identity tables as portal users.

**Purpose:** Thay thế các lời gọi Angular cũ (`DMPPortal` `POST api/dashboard/*`, `POST api/bc02/get_bieudo_tonkho_daumoi`) bằng API ASP.NET Core mới — **chỉ xăng / dầu** (bản ghi `type = khi` từ SP tồn kho, nếu có, bị lọc bỏ ở tầng đọc).

| Route | Legacy portal | Stored procedure (khi có trên SQL Server) |
|--------|----------------|---------------------------------------------|
| `GET /api/leader/dashboard/snapshot` | — | Tổng hợp nội bộ (`sp_Reports_GetStationOverview`, `sp_Reports_GetInventorySummary`, …) |
| `POST /api/leader/home/inventory-summary` | `POST api/dashboard/inventory-summary` | `dbo.sp_Dashboard_Home_InventorySummary` |
| `POST /api/leader/home/national-stock-movement` | `POST api/dashboard/national-stock-movement` | `dbo.sp_Dashboard_Home_NationalStockMovement` |
| `POST /api/leader/home/price-summary` | `POST api/dashboard/price-summary` | `dbo.sp_Dashboard_Home_PriceSummary` |
| `POST /api/leader/home/distributor-map` | `POST api/bc02/get_bieudo_tonkho_daumoi` | `A_TienIch_BanDo_TonKho_DauMoi` (`Ma` / `LoaiXangDau`: `xang` \| `dau`) |

**Payload chung (inventory / national / price):** `userName`, `donViId`, `period` (`THANG` \| `QUY` \| `NAM`), `month`, `year` — server điền `userName` / `donViId` từ JWT nếu client bỏ trống.

**Khi SP chưa deploy:** phản hồi HTTP 200 với `dataSource: "unavailable"` và cấu trúc rỗng hoặc mặc định; mobile vẫn dùng `GET /api/reports/overview` làm lớp dự phòng.

---

## Reference

- Table/column detail: **`docs/architecture/database.md`**
- Product rules and phase scope: **`docs/architecture/overview.md`**, **`docs/modules/phase-1-scope.md`**
