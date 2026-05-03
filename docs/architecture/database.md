# Database Schema - DMPPortal

Tài liệu này được sinh từ file SQL Server schema script. Nội dung gồm danh sách bảng, cột, khóa chính, ràng buộc unique, giá trị mặc định và foreign key để Cursor AI có thể đọc hiểu CSDL chính xác hơn.

## Overview

- Database: `DMPPortal`
- Total tables: **32** (gồm `StationRatings` / `StationRatingImages`, `UserVehicles`, `FuelTransactions`, `UserDataDeletionRequests` cho tab Nhiên liệu mobile / quyền riêng tư)
- Total foreign keys: **25** (ước lượng; thêm `FuelTransactions.VehicleId` → `UserVehicles.Id`)

## Tables

- [AspNetRoles](#aspnetroles)
- [AspNetUserClaims](#aspnetuserclaims)
- [AspNetUserLogins](#aspnetuserlogins)
- [AspNetUserRoles](#aspnetuserroles)
- [AspNetUsers](#aspnetusers)
- [UserVehicles](#uservehicles)
- [FuelTransactions](#fueltransactions)
- [DM_DonVi](#dm-donvi)
- [DM_Tinh](#dm-tinh)
- [DM_XaPhuong](#dm-xaphuong)
- [QT_TK_ChotSoLieu](#qt-tk-chotsolieu)
- [QT_TK_ThongKe](#qt-tk-thongke)
- [QT_TK_ThongKeChiTiet](#qt-tk-thongkechitiet)
- [QT_TK_ThongKeChiTiet_ChuyenDuLieu](#qt-tk-thongkechitiet-chuyendulieu)
- [QT_TK_ThongKeChiTiet_ChuyenDuLieu_Mau02](#qt-tk-thongkechitiet-chuyendulieu-mau02)
- [QT_TK_ThongKeChiTiet_ChuyenDuLieu_Mau05](#qt-tk-thongkechitiet-chuyendulieu-mau05)
- [QT_TK_ThongKeChiTiet_ChuyenDuLieu_Mau06](#qt-tk-thongkechitiet-chuyendulieu-mau06)
- [QT_TK_ThongKeChiTiet_ChuyenDuLieu_Mau07](#qt-tk-thongkechitiet-chuyendulieu-mau07)
- [QT_TK_ThongKeChiTiet_ChuyenDuLieu_Mau07a](#qt-tk-thongkechitiet-chuyendulieu-mau07a)
- [QT_TK_ThongKeChiTiet_ChuyenDuLieu_Mau08](#qt-tk-thongkechitiet-chuyendulieu-mau08)
- [QT_TK_ThongKeChiTiet02](#qt-tk-thongkechitiet02)
- [TK_ChiTieuBaoCao](#tk-chitieubaocao)
- [TK_GiaoBaoCao](#tk-giaobaocao)
- [TK_GiaoBaoCaoChiTiet](#tk-giaobaocaochitiet)
- [TK_QuanLyGiayPhep](#tk-quanlygiayphep)
- [TK_QuanLyKhoXangDau](#tk-quanlykhoxangdau)
- [TK_QuanLyKhoXangDau_HopDong](#tk-quanlykhoxangdau-hopdong)
- [TK_QuanLyKhoXangDau_PhanBoDungTich](#tk-quanlykhoxangdau-phanbodungtich)
- [TK_QuanLyKhoXangDau_TonKho](#tk-quanlykhoxangdau-tonkho)
- [StationRatings](#stationratings)
- [StationRatingImages](#stationratingimages)

## AspNetRoles

- Schema: `dbo`
- Primary key: `Id`
- Unique constraints: _None detected_
- Foreign keys: **0**

| Column | Type | Null | Identity | Default | Notes |
|---|---|---|---|---|---|
| `Id` | `nvarchar(128)` | NO | NO | `newid()` | PK |
| `Name` | `nvarchar(256)` | NO | NO | `` |  |
| `Order` | `int` | YES | NO | `` |  |
| `IsLocal` | `bit` | YES | NO | `(0)` |  |
| `Khoa` | `uniqueidentifier` | YES | NO | `` |  |
| `Description` | `nvarchar(200)` | YES | NO | `` |  |
| `Created` | `datetime` | YES | NO | `` |  |
| `CreatedBy` | `nvarchar(50)` | YES | NO | `` |  |
| `Modified` | `datetime` | YES | NO | `` |  |
| `ModifiedBy` | `nvarchar(50)` | YES | NO | `` |  |
| `IdCu` | `int` | YES | NO | `` |  |

## AspNetUserClaims

- Schema: `dbo`
- Primary key: `Id`
- Unique constraints: _None detected_
- Foreign keys: **1**

| Column | Type | Null | Identity | Default | Notes |
|---|---|---|---|---|---|
| `Id` | `int` | NO | YES | `` | PK |
| `UserId` | `nvarchar(128)` | NO | NO | `` | FK → AspNetUsers.Id |
| `ClaimType` | `nvarchar(max)` | YES | NO | `` |  |
| `ClaimValue` | `nvarchar(max)` | YES | NO | `` |  |

### Relationships

- `AspNetUserClaims.UserId` → `AspNetUsers.Id` (`FK_dbo.AspNetUserClaims_dbo.AspNetUsers_UserId`)

## AspNetUserLogins

- Schema: `dbo`
- Primary key: `LoginProvider, ProviderKey, UserId`
- Unique constraints: _None detected_
- Foreign keys: **1**

| Column | Type | Null | Identity | Default | Notes |
|---|---|---|---|---|---|
| `LoginProvider` | `nvarchar(128)` | NO | NO | `` | PK |
| `ProviderKey` | `nvarchar(128)` | NO | NO | `` | PK |
| `UserId` | `nvarchar(128)` | NO | NO | `` | PK, FK → AspNetUsers.Id |

### Relationships

- `AspNetUserLogins.UserId` → `AspNetUsers.Id` (`FK_dbo.AspNetUserLogins_dbo.AspNetUsers_UserId`)

## AspNetUserRoles

- Schema: `dbo`
- Primary key: `UserId, RoleId`
- Unique constraints: _None detected_
- Foreign keys: **2**

| Column | Type | Null | Identity | Default | Notes |
|---|---|---|---|---|---|
| `UserId` | `nvarchar(128)` | NO | NO | `` | PK, FK → AspNetUsers.Id |
| `RoleId` | `nvarchar(128)` | NO | NO | `` | PK, FK → AspNetRoles.Id |

### Relationships

- `AspNetUserRoles.RoleId` → `AspNetRoles.Id` (`FK_dbo.AspNetUserRoles_dbo.AspNetRoles_RoleId`)
- `AspNetUserRoles.UserId` → `AspNetUsers.Id` (`FK_dbo.AspNetUserRoles_dbo.AspNetUsers_UserId`)

## AspNetUsers

- Schema: `dbo`
- Primary key: `Id`
- Unique constraints: _None detected_
- Foreign keys: **0**

| Column | Type | Null | Identity | Default | Notes |
|---|---|---|---|---|---|
| `Id` | `nvarchar(128)` | NO | NO | `` | PK |
| `DisplayName` | `nvarchar(255)` | YES | NO | `` |  |
| `Picture` | `nvarchar(255)` | YES | NO | `` |  |
| `Email` | `nvarchar(256)` | YES | NO | `` |  |
| `EmailConfirmed` | `bit` | NO | NO | `` |  |
| `PasswordHash` | `nvarchar(max)` | YES | NO | `` |  |
| `SecurityStamp` | `nvarchar(max)` | YES | NO | `` |  |
| `PasswordApp` | `nvarchar(200)` | YES | NO | `` |  |
| `PhoneNumber` | `nvarchar(max)` | YES | NO | `` |  |
| `PhoneNumberConfirmed` | `bit` | NO | NO | `` |  |
| `TwoFactorEnabled` | `bit` | NO | NO | `` |  |
| `LockoutEndDateUtc` | `datetime` | YES | NO | `` |  |
| `LockoutEnabled` | `bit` | NO | NO | `` |  |
| `AccessFailedCount` | `int` | NO | NO | `` |  |
| `UserName` | `nvarchar(256)` | NO | NO | `` |  |
| `Job` | `nvarchar(255)` | YES | NO | `` |  |
| `Department` | `nvarchar(255)` | YES | NO | `` |  |
| `ToChucId` | `uniqueidentifier` | YES | NO | `` |  |
| `PermissionToChucId` | `uniqueidentifier` | YES | NO | `` |  |
| `IsADUser` | `bit` | YES | NO | `` |  |
| `DonViId` | `int` | YES | NO | `` |  |
| `Loai` | `int` | YES | NO | `` |  |
| `NgonNguId` | `int` | YES | NO | `` |  |
| `CanBoId` | `int` | YES | NO | `` |  |

## PasswordResetTokens

- Schema: `dbo`
- Primary key: `Id` (identity)
- Foreign keys: **1** — `UserId` → `AspNetUsers.Id` (`FK_PasswordResetTokens_AspNetUsers_UserId`)
- API: `POST /api/auth/forgot-password`, `POST /api/auth/reset-password` (anonymous). Chỉ lưu **hash SHA-256** của token gửi qua email; token sống **30 phút**, **một lần** (`UsedAt`).

| Column | Type | Null | Identity | Default | Notes |
|---|---|---|---|---|---|
| `Id` | `int` | NO | YES | `` | PK |
| `UserId` | `nvarchar(128)` | NO | NO | `` | FK → `AspNetUsers.Id` (cùng kiểu với PK portal) |
| `TokenHash` | `nvarchar(256)` | NO | NO | `` | Hash token, không lưu token thô |
| `ExpiresAt` | `datetime2` | NO | NO | `` |  |
| `UsedAt` | `datetime2` | YES | NO | `` | Một lần: set khi đặt lại thành công |
| `CreatedAt` | `datetime2` | NO | NO | `` |  |
| `CreatedIp` | `nvarchar(50)` | YES | NO | `` |  |
| `UserAgent` | `nvarchar(500)` | YES | NO | `` |  |

Indexes: `IX_PasswordResetTokens_TokenHash`, `IX_PasswordResetTokens_UserId`, `IX_PasswordResetTokens_ExpiresAt`.

## UserDataDeletionRequests

- Schema: `dbo`
- Primary key: `Id` (identity)
- Foreign keys: **1** — `UserId` → `AspNetUsers.Id` (`FK_UserDataDeletionRequests_AspNetUsers_UserId`)
- API: `POST /api/user/request-delete-data` (JWT). Chỉ **ghi nhận** yêu cầu; trạng thái ban đầu `Pending`; không xoá dữ liệu tại endpoint. Nếu user đã có bản ghi `Pending` → HTTP 409 với `detail` tiếng Việt.

| Column | Type | Null | Identity | Default | Notes |
|---|---|---|---|---|---|
| `Id` | `int` | NO | YES | `` | PK |
| `UserId` | `nvarchar(128)` | NO | NO | `` | FK → `AspNetUsers.Id` |
| `RequestType` | `nvarchar(100)` | NO | NO | `` | Ví dụ `DELETE_PERSONAL_DATA` |
| `Scope` | `nvarchar(50)` | NO | NO | `` | Ví dụ `ALL` |
| `Note` | `nvarchar(2000)` | YES | NO | `` | Ghi chú từ client |
| `Status` | `nvarchar(32)` | NO | NO | `` | `Pending`, `Processing`, `Completed`, `Rejected` |
| `RequestedAt` | `datetime2` | NO | NO | `` | UTC khi tạo |
| `ProcessedAt` | `datetime2` | YES | NO | `` | Khi xử lý xong (tùy quy trình nội bộ) |
| `ProcessedBy` | `nvarchar(128)` | YES | NO | `` | User quản trị xử lý (nếu có) |

Indexes: `IX_UserDataDeletionRequests_UserId_Status` (composite).

## UserVehicles

- Schema: `dbo`
- Primary key: `Id`
- Foreign keys: **1** — `UserId` → `AspNetUsers.Id` (`FK_UserVehicles_AspNetUsers`)
- API: `GET/POST/PUT/DELETE /api/my-vehicles`, `POST /api/my-vehicles/{id}/set-default` (JWT `NameIdentifier` = `UserId`)

| Column | Type | Null | Identity | Default | Notes |
|---|---|---|---|---|---|
| `Id` | `int` | NO | YES | `` | PK |
| `UserId` | `nvarchar(128)` | NO | NO | `` | FK → `AspNetUsers.Id` |
| `LicensePlate` | `nvarchar(20)` | NO | NO | `` |  |
| `VehicleName` | `nvarchar(100)` | YES | NO | `` |  |
| `FuelType` | `nvarchar(50)` | YES | NO | `` |  |
| `FuelLevel` | `int` | YES | NO | `` | % bình xăng (ứng dụng) |
| `TotalKm` | `int` | YES | NO | `` |  |
| `Year` | `int` | YES | NO | `` | Năm sản xuất |
| `IsDefault` | `bit` | NO | NO | `0` | Tối đa một xe `1` mỗi `UserId` |
| `ImageUrl` | `nvarchar(500)` | YES | NO | `` |  |
| `CreatedDate` | `datetime` | NO | NO | `GETDATE()` |  |
| `UpdatedDate` | `datetime` | YES | NO | `` |  |

### Stored procedures (Dapper / API)

| Procedure | Mô tả ngắn |
|---|---|
| `dbo.sp_UserVehicles_GetByUser` | Danh sách theo user; `IsDefault` trước; tùy chọn tìm biển, lọc `FuelType`, phân trang (`@Page`, `@PageSize` = 0 là tất cả, tối đa 500/trang) |
| `dbo.sp_UserVehicles_GetById` | Một xe theo `@Id`, `@UserId` |
| `dbo.sp_UserVehicles_Create` | Thêm; xe đầu / khi chưa có mặc định → tự `IsDefault = 1`; nếu `@IsDefault = 1` thì reset các xe khác |
| `dbo.sp_UserVehicles_Update` | Cập nhật full field; một xe → luôn mặc định; bỏ mặc định khi còn xe khác → promote xe `Id` nhỏ nhất |
| `dbo.sp_UserVehicles_Delete` | Không xóa nếu chỉ còn một xe; xóa xe mặc định → promote mặc định khác rồi xóa |
| `dbo.sp_UserVehicles_SetDefault` | Reset `IsDefault` cả user, đặt `@Id` = 1 |

## FuelTransactions

- Schema: `dbo`
- Primary key: `Id`
- Foreign keys: **1** — `VehicleId` → `UserVehicles.Id` (`FK_FuelTransactions_UserVehicles`)
- API (JWT portal): `GET /api/fuel/current-vehicle`, `GET /api/fuel/summary`, `GET /api/fuel/insights`, `GET /api/fuel/transactions`, `POST /api/fuel/transactions` — **chỉ** qua Dapper + stored procedure (`FuelDataAccess` / `FuelController`).
- Xóa mềm: `IsDeleted = 1` (không xóa vật lý). `PricePerLiter` = `Amount / Liters` khi insert (tính trong `dbo.sp_FuelTransaction_Insert`).
- `UserId`: `nvarchar(128)` khớp `AspNetUsers.Id` (JWT `NameIdentifier`), **không** dùng kiểu `int` cho user.

| Column | Type | Null | Identity | Default | Notes |
|---|---|---|---|---|---|
| `Id` | `int` | NO | YES |  | PK |
| `UserId` | `nvarchar(128)` | NO | NO |  | Người tạo / sở hữu giao dịch |
| `VehicleId` | `int` | NO | NO |  | FK → `UserVehicles.Id` |
| `StationId` | `int` | YES | NO |  | Tham chiếu logic tới `DM_DonVi.Id` (trạm xăng) |
| `FuelTypeId` | `int` | YES | NO |  | Tham chiếu logic tới `FuelProducts.Id` |
| `Amount` | `decimal(18,2)` | NO | NO |  | Số tiền |
| `Liters` | `decimal(18,3)` | NO | NO |  | Số lít |
| `PricePerLiter` | `decimal(18,2)` | YES | NO |  | `Amount/Liters` |
| `Odometer` | `decimal(18,1)` | YES | NO |  | Công tơ mét (tùy chọn) |
| `TransactionDate` | `datetime` | NO | NO |  | Ngày đổ |
| `CreatedAt` | `datetime` | NO | NO | `GETDATE()` |  |
| `CreatedBy` | `nvarchar(100)` | YES | NO |  |  |
| `Note` | `nvarchar(500)` | YES | NO |  | Ghi chú giao dịch (mobile) |
| `IsDeleted` | `bit` | NO | NO | `0` |  |

### Stored procedures (Fuel / Dapper)

| Procedure | Mô tả ngắn |
|---|---|
| `dbo.sp_Fuel_GetCurrentVehicle` | `@UserId`, `@DeviceId` (dự phòng) — một dòng xe ưu tiên `IsDefault`, rồi `Id` |
| `dbo.sp_Fuel_GetMonthlySummary` | `@UserId`, `@VehicleId`, `@Month`, `@Year` — tổng tiền/lít, `CostPerKm` theo min/max `Odometer` trong tháng, % so tháng trước |
| `dbo.sp_Fuel_GetInsights` | Cùng tham số — `MainText`, `SavingText` (không trả gợi ý “đổ xăng buổi tối”) |
| `dbo.sp_Fuel_GetTransactions` | Phân trang `@PageIndex`, `@PageSize`; `StationName` từ `DM_DonVi.Ten`; `TotalCount` qua `COUNT(*) OVER()` |
| `dbo.sp_FuelTransaction_Insert` | Kiểm tra xe thuộc user, `Amount`/`Liters` > 0; tham số `@Note`; OUTPUT `@NewId`, `@ErrorMessage` |

### Migration

- `20260427103000_AddFuelTransactionsAndStoredProcedures` — tạo bảng + các SP trên (`FuelTransactionsSchemaSql`, `FuelStoredProceduresSql`).
- `20260428120000_AddFuelTransactionNoteColumn` — thêm cột `Note` (nếu thiếu) và cập nhật `sp_FuelTransaction_Insert` (`FuelTransactionsNoteMigrationSql`).

## DM_DonVi

- Schema: `dbo`
- Primary key: `Id`
- Unique constraints: `Ma`
- Foreign keys: **0**

| Column | Type | Null | Identity | Default | Notes |
|---|---|---|---|---|---|
| `Id` | `int` | NO | YES | `` | PK |
| `Ma` | `nvarchar(20)` | NO | NO | `` | UNIQUE |
| `Ten` | `nvarchar(200)` | NO | NO | `` |  |
| `TenTiengNuocNgoai` | `nvarchar(200)` | YES | NO | `` |  |
| `DienThoai` | `nvarchar(50)` | YES | NO | `` |  |
| `DiaChi` | `nvarchar(250)` | YES | NO | `` |  |
| `Email` | `nvarchar(50)` | YES | NO | `` |  |
| `SoTaiKhoan` | `nvarchar(30)` | YES | NO | `` |  |
| `SapXep` | `int` | YES | NO | `` |  |
| `UngPhep` | `bit` | YES | NO | `` |  |
| `CapTrenId` | `int` | YES | NO | `` |  |
| `Cap` | `int` | YES | NO | `` |  |
| `MaAo` | `nvarchar(500)` | YES | NO | `` |  |
| `CoCapCon` | `int` | YES | NO | `` |  |
| `CongThucId` | `int` | YES | NO | `` |  |
| `NgayThanhLap` | `datetime` | YES | NO | `` |  |
| `NgayGiaiThe` | `datetime` | YES | NO | `` |  |
| `TenKhongDau` | `nvarchar(200)` | YES | NO | `` |  |
| `ThuocDonViId` | `int` | YES | NO | `` |  |
| `PhanLoaiId` | `int` | YES | NO | `` |  |
| `PhanQuyen` | `int` | YES | NO | `` |  |
| `TT` | `int` | YES | NO | `` |  |
| `TN` | `int` | YES | NO | `` |  |
| `ThuocCap` | `int` | YES | NO | `` |  |
| `Created` | `datetime` | YES | NO | `` |  |
| `CreatedBy` | `nvarchar(100)` | YES | NO | `` |  |
| `Modified` | `datetime` | YES | NO | `` |  |
| `ModifiedBy` | `nvarchar(100)` | YES | NO | `` |  |
| `Version` | `timestamp` | YES | NO | `` |  |
| `Ky_ThuTruongDonVi` | `nvarchar(70)` | YES | NO | `` |  |
| `Ky_KeToanTruong` | `nvarchar(70)` | YES | NO | `` |  |
| `Ky_NguoiLapBaoCao` | `nvarchar(70)` | YES | NO | `` |  |
| `Ky_ThuKho` | `nvarchar(70)` | YES | NO | `` |  |
| `Ky_ThuQuy` | `nvarchar(70)` | YES | NO | `` |  |
| `IdGuid` | `uniqueidentifier` | YES | NO | `newid()` |  |
| `CapDonViId` | `int` | NO | NO | `` |  |
| `TrangThai` | `bit` | YES | NO | `` |  |
| `VungMien` | `int` | YES | NO | `` |  |
| `SoGiayPhep` | `nvarchar(200)` | YES | NO | `` |  |
| `NgayCap` | `datetime` | YES | NO | `` |  |
| `NgayHetHan` | `datetime` | YES | NO | `` |  |
| `Tinh` | `int` | YES | NO | `` |  |
| `Xa` | `int` | YES | NO | `` |  |
| `DiaChiChiTiet` | `nvarchar(500)` | YES | NO | `` |  |
| `NoiCapId` | `int` | YES | NO | `` |  |
| `LoaiHinh` | `int` | YES | NO | `` |  |
| `ThemMoi` | `int` | YES | NO | `` |  |
| `CapTrenText` | `nvarchar(500)` | YES | NO | `` |  |
| `ViDo` | `DECIMAL(9,6)` | YES | NO | `` |  |
| `KinhDo` | `DECIMAL(9,6)` | YES | NO | `` |  |

## DM_Tinh

- Schema: `dbo`
- Primary key: `Id`
- Unique constraints: `Ma`; `Ten`
- Foreign keys: **0**

| Column | Type | Null | Identity | Default | Notes |
|---|---|---|---|---|---|
| `Id` | `int` | NO | YES | `` | PK |
| `Ma` | `nvarchar(20)` | NO | NO | `` | UNIQUE |
| `Ten` | `nvarchar(100)` | NO | NO | `` | UNIQUE |
| `TenTiengNuocNgoai` | `nvarchar(100)` | YES | NO | `` |  |
| `SapXep` | `int` | YES | NO | `` |  |
| `Created` | `datetime` | YES | NO | `` |  |
| `CreatedBy` | `nvarchar(100)` | YES | NO | `` |  |
| `Modified` | `datetime` | YES | NO | `` |  |
| `ModifiedBy` | `nvarchar(100)` | YES | NO | `` |  |
| `Version` | `timestamp` | YES | NO | `` |  |
| `VungMien` | `int` | YES | NO | `` |  |

## DM_XaPhuong

- Schema: `dbo`
- Primary key: `Id`
- Unique constraints: _None detected_
- Foreign keys: **2**

| Column | Type | Null | Identity | Default | Notes |
|---|---|---|---|---|---|
| `Id` | `int` | NO | YES | `` | PK |
| `Ma` | `nvarchar(50)` | NO | NO | `` |  |
| `Ten` | `nvarchar(50)` | NO | NO | `` |  |
| `TenTiengNuocNgoai` | `nvarchar(50)` | YES | NO | `` |  |
| `QuanHuyenId` | `int` | YES | NO | `` | FK → DM_QuanHuyen.Id |
| `TinhId` | `int` | YES | NO | `` | FK → DM_Tinh.Id |
| `Created` | `datetime` | YES | NO | `` |  |
| `CreatedBy` | `nvarchar(100)` | YES | NO | `` |  |
| `Modified` | `datetime` | YES | NO | `` |  |
| `ModifiedBy` | `nvarchar(100)` | YES | NO | `` |  |
| `Version` | `timestamp` | YES | NO | `` |  |
| `MaTinh` | `nvarchar(50)` | YES | NO | `` |  |

### Relationships

- `DM_XaPhuong.QuanHuyenId` → `DM_QuanHuyen.Id` (`FK_DM_XaPhuong_DM_QuanHuyen`)
- `DM_XaPhuong.TinhId` → `DM_Tinh.Id` (`FK_DM_XaPhuong_DM_Tinh`)

## QT_TK_ChotSoLieu

- Schema: `dbo`
- Primary key: `Id`
- Unique constraints: _None detected_
- Foreign keys: **0**

| Column | Type | Null | Identity | Default | Notes |
|---|---|---|---|---|---|
| `Id` | `uniqueidentifier` | NO | NO | `` | PK |
| `Nam` | `int` | YES | NO | `` |  |
| `NgayChot` | `datetime` | YES | NO | `` |  |
| `don_vi_cap1` | `int` | YES | NO | `` |  |
| `LoaiBaoCao` | `int` | YES | NO | `` |  |
| `BaoCaoId` | `uniqueidentifier` | YES | NO | `` |  |
| `Created` | `datetime` | YES | NO | `` |  |
| `CreatedBy` | `nvarchar(50)` | YES | NO | `` |  |
| `Modified` | `datetime` | YES | NO | `` |  |
| `ModifiedBy` | `nvarchar(50)` | YES | NO | `` |  |

## QT_TK_ThongKe

- Schema: `dbo`
- Primary key: `Id`
- Unique constraints: `don_vi_cap1, BaoCaoId, KieuKyBaoCao, TuNgay, DenNgay, Loai`
- Foreign keys: **1**

| Column | Type | Null | Identity | Default | Notes |
|---|---|---|---|---|---|
| `Id` | `uniqueidentifier` | NO | NO | `` | PK |
| `TuNgay` | `date` | YES | NO | `` | UNIQUE |
| `DenNgay` | `date` | NO | NO | `` | UNIQUE |
| `don_vi_cap1` | `int` | YES | NO | `` | UNIQUE, FK → DM_DonVi.Id |
| `don_vi_cap2` | `int` | YES | NO | `` |  |
| `can_bo_lap` | `nvarchar(100)` | YES | NO | `` |  |
| `thu_truong_don_vi` | `nvarchar(100)` | YES | NO | `` |  |
| `BaoCaoId` | `uniqueidentifier` | YES | NO | `` | UNIQUE |
| `ThangQuy` | `int` | YES | NO | `` |  |
| `Loai` | `int` | NO | NO | `(0)` | UNIQUE |
| `Chot` | `bit` | YES | NO | `` |  |
| `KieuKyBaoCao` | `int` | YES | NO | `` | UNIQUE |
| `TrangThai` | `int` | YES | NO | `` |  |
| `Created` | `datetime` | YES | NO | `` |  |
| `CreatedBy` | `nvarchar(50)` | YES | NO | `` |  |
| `Modified` | `datetime` | YES | NO | `` |  |
| `ModifiedBy` | `nvarchar(50)` | YES | NO | `` |  |
| `ThoiHanTuNgay` | `datetime` | YES | NO | `` |  |
| `ThoiHanDenNgay` | `datetime` | YES | NO | `` |  |
| `don_vi_giao` | `int` | YES | NO | `` |  |
| `file_atach` | `int` | YES | NO | `` |  |
| `Xoa` | `int` | YES | NO | `` |  |
| `BaoCaoCuId` | `uniqueidentifier` | YES | NO | `` |  |
| `ThoiGianGui` | `datetime` | YES | NO | `` |  |

### Relationships

- `QT_TK_ThongKe.don_vi_cap1` → `DM_DonVi.Id` (`FK_QT_TK_ThongKe_DM_DonVi`)

## QT_TK_ThongKeChiTiet

- Schema: `dbo`
- Primary key: `Id`
- Unique constraints: _None detected_
- Foreign keys: **2**

| Column | Type | Null | Identity | Default | Notes |
|---|---|---|---|---|---|
| `Id` | `uniqueidentifier` | NO | NO | `` | PK |
| `ThongKeId` | `uniqueidentifier` | NO | NO | `` | FK → QT_TK_ThongKe.Id |
| `Nhom` | `int` | YES | NO | `` |  |
| `ThiTruongId` | `int` | YES | NO | `` |  |
| `ThiTruong` | `nvarchar(200)` | YES | NO | `` |  |
| `NhaCungCapId` | `int` | YES | NO | `` |  |
| `ChiTieuThongKeId` | `uniqueidentifier` | YES | NO | `` | FK → TK_ChiTieuBaoCao.Id |
| `MaSo` | `nvarchar(50)` | YES | NO | `` |  |
| `TenThongKe` | `nvarchar(1000)` | YES | NO | `` |  |
| `GhiChu` | `nvarchar(200)` | YES | NO | `` |  |
| `ThuTu` | `int` | YES | NO | `` |  |
| `ChaId` | `uniqueidentifier` | YES | NO | `` |  |
| `MaAo` | `nvarchar(200)` | YES | NO | `` |  |
| `InDam` | `int` | YES | NO | `` |  |
| `So_01` | `decimal(28, 3)` | YES | NO | `` |  |
| `So_02` | `decimal(28, 3)` | YES | NO | `` |  |
| `So_03` | `decimal(28, 3)` | YES | NO | `` |  |
| `So_04` | `decimal(28, 3)` | YES | NO | `` |  |
| `So_05` | `decimal(28, 3)` | YES | NO | `` |  |
| `So_06` | `decimal(28, 3)` | YES | NO | `` |  |
| `So_07` | `decimal(28, 3)` | YES | NO | `` |  |
| `So_08` | `decimal(28, 3)` | YES | NO | `` |  |
| `So_09` | `decimal(28, 3)` | YES | NO | `` |  |
| `So_10` | `decimal(28, 3)` | YES | NO | `` |  |
| `So_11` | `decimal(28, 3)` | YES | NO | `` |  |
| `So_12` | `decimal(28, 3)` | YES | NO | `` |  |
| `So_13` | `decimal(28, 3)` | YES | NO | `` |  |
| `So_14` | `decimal(28, 3)` | YES | NO | `` |  |
| `So_15` | `decimal(28, 3)` | YES | NO | `` |  |
| `So_16` | `decimal(28, 3)` | YES | NO | `` |  |
| `So_17` | `decimal(28, 3)` | YES | NO | `` |  |
| `So_18` | `decimal(28, 3)` | YES | NO | `` |  |
| `So_19` | `decimal(28, 3)` | YES | NO | `` |  |
| `So_20` | `decimal(28, 3)` | YES | NO | `` |  |
| `So_21` | `decimal(28, 3)` | YES | NO | `` |  |
| `So_22` | `decimal(28, 3)` | YES | NO | `` |  |
| `So_23` | `decimal(28, 3)` | YES | NO | `` |  |
| `So_24` | `decimal(28, 3)` | YES | NO | `` |  |
| `So_25` | `decimal(28, 3)` | YES | NO | `` |  |
| `GiayPhep_So` | `nvarchar(50)` | YES | NO | `` |  |
| `GiayPhep_NgayCap` | `datetime` | YES | NO | `` |  |
| `LoaiGia` | `int` | YES | NO | `` |  |
| `ThoiDiemDinhGia` | `datetime` | YES | NO | `` |  |
| `DonViTinhId` | `int` | YES | NO | `` |  |
| `Created` | `datetime` | YES | NO | `` |  |
| `CreatedBy` | `nvarchar(50)` | YES | NO | `` |  |
| `Modified` | `datetime` | YES | NO | `` |  |
| `ModifiedBy` | `nvarchar(50)` | YES | NO | `` |  |
| `Xoa` | `int` | YES | NO | `` |  |

### Relationships

- `QT_TK_ThongKeChiTiet.ChiTieuThongKeId` → `TK_ChiTieuBaoCao.Id` (`FK_QT_TK_ThongKeChiTiet_TK_ChiTieuBaoCao`)
- `QT_TK_ThongKeChiTiet.ThongKeId` → `QT_TK_ThongKe.Id` (`FK_TK_ThongKeChiTiet_TK_ThongKe`)

## QT_TK_ThongKeChiTiet_ChuyenDuLieu

- Schema: `dbo`
- Primary key: _None detected_
- Unique constraints: _None detected_
- Foreign keys: **0**

| Column | Type | Null | Identity | Default | Notes |
|---|---|---|---|---|---|
| `DonViId` | `int` | YES | NO | `` |  |
| `ThoiGian` | `nvarchar(200)` | YES | NO | `` |  |
| `KieuKyBaoCao` | `int` | YES | NO | `` |  |
| `Created` | `nvarchar(50)` | YES | NO | `` |  |
| `CreatedBy` | `nvarchar(50)` | YES | NO | `` |  |
| `TenThongKe` | `nvarchar(200)` | YES | NO | `` |  |
| `MaSo` | `nvarchar(50)` | YES | NO | `` |  |
| `DVT` | `nvarchar(200)` | YES | NO | `` |  |
| `So_01` | `decimal(18, 3)` | YES | NO | `` |  |
| `So_02` | `decimal(18, 3)` | YES | NO | `` |  |
| `So_03` | `decimal(18, 3)` | YES | NO | `` |  |
| `So_04` | `decimal(18, 3)` | YES | NO | `` |  |
| `So_05` | `decimal(18, 3)` | YES | NO | `` |  |
| `So_06` | `decimal(18, 3)` | YES | NO | `` |  |
| `So_07` | `decimal(18, 3)` | YES | NO | `` |  |
| `So_08` | `decimal(18, 3)` | YES | NO | `` |  |
| `So_09` | `decimal(18, 3)` | YES | NO | `` |  |
| `So_10` | `decimal(18, 3)` | YES | NO | `` |  |
| `So_11` | `decimal(18, 3)` | YES | NO | `` |  |
| `So_12` | `decimal(18, 3)` | YES | NO | `` |  |
| `So_13` | `decimal(18, 3)` | YES | NO | `` |  |
| `So_14` | `decimal(18, 3)` | YES | NO | `` |  |
| `So_15` | `decimal(18, 3)` | YES | NO | `` |  |
| `So_16` | `decimal(18, 3)` | YES | NO | `` |  |
| `So_17` | `decimal(18, 3)` | YES | NO | `` |  |
| `So_18` | `decimal(18, 3)` | YES | NO | `` |  |
| `So_19` | `decimal(18, 3)` | YES | NO | `` |  |
| `So_20` | `decimal(18, 3)` | YES | NO | `` |  |

## QT_TK_ThongKeChiTiet_ChuyenDuLieu_Mau02

- Schema: `dbo`
- Primary key: _None detected_
- Unique constraints: _None detected_
- Foreign keys: **0**

| Column | Type | Null | Identity | Default | Notes |
|---|---|---|---|---|---|
| `DonViId` | `int` | YES | NO | `` |  |
| `ThoiGian` | `nvarchar(200)` | YES | NO | `` |  |
| `KieuKyBaoCao` | `int` | YES | NO | `` |  |
| `Created` | `nvarchar(50)` | YES | NO | `` |  |
| `CreatedBy` | `nvarchar(50)` | YES | NO | `` |  |
| `TenThongKe` | `nvarchar(200)` | YES | NO | `` |  |
| `MaSo` | `nvarchar(50)` | YES | NO | `` |  |
| `DVT` | `nvarchar(200)` | YES | NO | `` |  |
| `So_01` | `decimal(18, 3)` | YES | NO | `` |  |
| `So_02` | `decimal(18, 3)` | YES | NO | `` |  |
| `So_03` | `decimal(18, 3)` | YES | NO | `` |  |
| `So_04` | `decimal(18, 3)` | YES | NO | `` |  |
| `So_05` | `decimal(18, 3)` | YES | NO | `` |  |
| `So_06` | `decimal(18, 3)` | YES | NO | `` |  |
| `So_07` | `decimal(18, 3)` | YES | NO | `` |  |
| `So_08` | `decimal(18, 3)` | YES | NO | `` |  |
| `So_09` | `decimal(18, 3)` | YES | NO | `` |  |
| `So_10` | `decimal(18, 3)` | YES | NO | `` |  |
| `So_11` | `decimal(18, 3)` | YES | NO | `` |  |
| `So_12` | `decimal(18, 3)` | YES | NO | `` |  |
| `So_13` | `decimal(18, 3)` | YES | NO | `` |  |
| `So_14` | `decimal(18, 3)` | YES | NO | `` |  |
| `So_15` | `decimal(18, 3)` | YES | NO | `` |  |
| `So_16` | `decimal(18, 3)` | YES | NO | `` |  |
| `So_17` | `decimal(18, 3)` | YES | NO | `` |  |
| `So_18` | `decimal(18, 3)` | YES | NO | `` |  |
| `So_19` | `decimal(18, 3)` | YES | NO | `` |  |
| `So_20` | `decimal(18, 3)` | YES | NO | `` |  |

## QT_TK_ThongKeChiTiet_ChuyenDuLieu_Mau05

- Schema: `dbo`
- Primary key: _None detected_
- Unique constraints: _None detected_
- Foreign keys: **0**

| Column | Type | Null | Identity | Default | Notes |
|---|---|---|---|---|---|
| `Nhom` | `int` | YES | NO | `` |  |
| `DonViId` | `int` | YES | NO | `` |  |
| `ThoiGian` | `nvarchar(200)` | YES | NO | `` |  |
| `KieuKyBaoCao` | `int` | YES | NO | `` |  |
| `Created` | `nvarchar(50)` | YES | NO | `` |  |
| `CreatedBy` | `nvarchar(50)` | YES | NO | `` |  |
| `TenThongKe` | `nvarchar(200)` | YES | NO | `` |  |
| `MaSo` | `nvarchar(50)` | YES | NO | `` |  |
| `DVT` | `nvarchar(200)` | YES | NO | `` |  |
| `ThiTruong` | `nvarchar(200)` | YES | NO | `` |  |
| `So_01` | `decimal(28, 3)` | YES | NO | `` |  |
| `So_02` | `decimal(28, 3)` | YES | NO | `` |  |
| `So_03` | `decimal(28, 3)` | YES | NO | `` |  |
| `So_04` | `decimal(28, 3)` | YES | NO | `` |  |
| `So_05` | `decimal(28, 3)` | YES | NO | `` |  |
| `So_06` | `decimal(28, 3)` | YES | NO | `` |  |
| `So_07` | `decimal(28, 3)` | YES | NO | `` |  |
| `So_08` | `decimal(28, 3)` | YES | NO | `` |  |
| `So_09` | `decimal(28, 3)` | YES | NO | `` |  |
| `So_10` | `decimal(28, 3)` | YES | NO | `` |  |
| `So_11` | `decimal(28, 3)` | YES | NO | `` |  |
| `So_12` | `decimal(28, 3)` | YES | NO | `` |  |
| `So_13` | `decimal(28, 3)` | YES | NO | `` |  |
| `So_14` | `decimal(28, 3)` | YES | NO | `` |  |
| `So_15` | `decimal(28, 3)` | YES | NO | `` |  |
| `So_16` | `decimal(28, 3)` | YES | NO | `` |  |
| `So_17` | `decimal(28, 3)` | YES | NO | `` |  |
| `So_18` | `decimal(28, 3)` | YES | NO | `` |  |
| `So_19` | `decimal(28, 3)` | YES | NO | `` |  |
| `So_20` | `decimal(28, 3)` | YES | NO | `` |  |

## QT_TK_ThongKeChiTiet_ChuyenDuLieu_Mau06

- Schema: `dbo`
- Primary key: _None detected_
- Unique constraints: _None detected_
- Foreign keys: **0**

| Column | Type | Null | Identity | Default | Notes |
|---|---|---|---|---|---|
| `Nhom` | `int` | YES | NO | `` |  |
| `DonViId` | `int` | YES | NO | `` |  |
| `ThoiGian` | `nvarchar(200)` | YES | NO | `` |  |
| `KieuKyBaoCao` | `int` | YES | NO | `` |  |
| `Created` | `nvarchar(50)` | YES | NO | `` |  |
| `CreatedBy` | `nvarchar(50)` | YES | NO | `` |  |
| `TenThongKe` | `nvarchar(200)` | YES | NO | `` |  |
| `MaSo` | `nvarchar(50)` | YES | NO | `` |  |
| `DVT` | `nvarchar(200)` | YES | NO | `` |  |
| `ThiTruong` | `nvarchar(200)` | YES | NO | `` |  |
| `So_01` | `decimal(28, 3)` | YES | NO | `` |  |
| `So_02` | `decimal(28, 3)` | YES | NO | `` |  |
| `So_03` | `decimal(28, 3)` | YES | NO | `` |  |
| `So_04` | `decimal(28, 3)` | YES | NO | `` |  |
| `So_05` | `decimal(28, 3)` | YES | NO | `` |  |
| `So_06` | `decimal(28, 3)` | YES | NO | `` |  |
| `So_07` | `decimal(28, 3)` | YES | NO | `` |  |
| `So_08` | `decimal(28, 3)` | YES | NO | `` |  |
| `So_09` | `decimal(28, 3)` | YES | NO | `` |  |
| `So_10` | `decimal(28, 3)` | YES | NO | `` |  |
| `So_11` | `decimal(28, 3)` | YES | NO | `` |  |
| `So_12` | `decimal(28, 3)` | YES | NO | `` |  |
| `So_13` | `decimal(28, 3)` | YES | NO | `` |  |
| `So_14` | `decimal(28, 3)` | YES | NO | `` |  |
| `So_15` | `decimal(28, 3)` | YES | NO | `` |  |
| `So_16` | `decimal(28, 3)` | YES | NO | `` |  |
| `So_17` | `decimal(28, 3)` | YES | NO | `` |  |
| `So_18` | `decimal(28, 3)` | YES | NO | `` |  |
| `So_19` | `decimal(28, 3)` | YES | NO | `` |  |
| `So_20` | `decimal(28, 3)` | YES | NO | `` |  |

## QT_TK_ThongKeChiTiet_ChuyenDuLieu_Mau07

- Schema: `dbo`
- Primary key: _None detected_
- Unique constraints: _None detected_
- Foreign keys: **0**

| Column | Type | Null | Identity | Default | Notes |
|---|---|---|---|---|---|
| `Nhom` | `int` | YES | NO | `` |  |
| `DonViId` | `int` | YES | NO | `` |  |
| `ThoiGian` | `nvarchar(200)` | YES | NO | `` |  |
| `KieuKyBaoCao` | `int` | YES | NO | `` |  |
| `Created` | `nvarchar(50)` | YES | NO | `` |  |
| `CreatedBy` | `nvarchar(50)` | YES | NO | `` |  |
| `TenThongKe` | `nvarchar(200)` | YES | NO | `` |  |
| `MaSo` | `nvarchar(50)` | YES | NO | `` |  |
| `DVT` | `nvarchar(200)` | YES | NO | `` |  |
| `ThiTruong` | `nvarchar(200)` | YES | NO | `` |  |
| `So_01` | `decimal(28, 3)` | YES | NO | `` |  |
| `So_02` | `decimal(28, 3)` | YES | NO | `` |  |
| `So_03` | `decimal(28, 3)` | YES | NO | `` |  |
| `So_04` | `decimal(28, 3)` | YES | NO | `` |  |
| `So_05` | `decimal(28, 3)` | YES | NO | `` |  |
| `So_06` | `decimal(28, 3)` | YES | NO | `` |  |
| `So_07` | `decimal(28, 3)` | YES | NO | `` |  |
| `So_08` | `decimal(28, 3)` | YES | NO | `` |  |
| `So_09` | `decimal(28, 3)` | YES | NO | `` |  |
| `So_10` | `decimal(28, 3)` | YES | NO | `` |  |
| `So_11` | `decimal(28, 3)` | YES | NO | `` |  |
| `So_12` | `decimal(28, 3)` | YES | NO | `` |  |
| `So_13` | `decimal(28, 3)` | YES | NO | `` |  |
| `So_14` | `decimal(28, 3)` | YES | NO | `` |  |
| `So_15` | `decimal(28, 3)` | YES | NO | `` |  |
| `So_16` | `decimal(28, 3)` | YES | NO | `` |  |
| `So_17` | `decimal(28, 3)` | YES | NO | `` |  |
| `So_18` | `decimal(28, 3)` | YES | NO | `` |  |
| `So_19` | `decimal(28, 3)` | YES | NO | `` |  |
| `So_20` | `decimal(28, 3)` | YES | NO | `` |  |

## QT_TK_ThongKeChiTiet_ChuyenDuLieu_Mau07a

- Schema: `dbo`
- Primary key: _None detected_
- Unique constraints: _None detected_
- Foreign keys: **0**

| Column | Type | Null | Identity | Default | Notes |
|---|---|---|---|---|---|
| `Nhom` | `int` | YES | NO | `` |  |
| `DonViId` | `int` | YES | NO | `` |  |
| `ThoiGian` | `nvarchar(200)` | YES | NO | `` |  |
| `KieuKyBaoCao` | `int` | YES | NO | `` |  |
| `Created` | `nvarchar(50)` | YES | NO | `` |  |
| `CreatedBy` | `nvarchar(50)` | YES | NO | `` |  |
| `TenThongKe` | `nvarchar(200)` | YES | NO | `` |  |
| `MaSo` | `nvarchar(50)` | YES | NO | `` |  |
| `DVT` | `nvarchar(200)` | YES | NO | `` |  |
| `ThiTruong` | `nvarchar(200)` | YES | NO | `` |  |
| `So_01` | `decimal(28, 3)` | YES | NO | `` |  |
| `So_02` | `decimal(28, 3)` | YES | NO | `` |  |
| `So_03` | `decimal(28, 3)` | YES | NO | `` |  |
| `So_04` | `decimal(28, 3)` | YES | NO | `` |  |
| `So_05` | `decimal(28, 3)` | YES | NO | `` |  |
| `So_06` | `decimal(28, 3)` | YES | NO | `` |  |
| `So_07` | `decimal(28, 3)` | YES | NO | `` |  |
| `So_08` | `decimal(28, 3)` | YES | NO | `` |  |
| `So_09` | `decimal(28, 3)` | YES | NO | `` |  |
| `So_10` | `decimal(28, 3)` | YES | NO | `` |  |
| `So_11` | `decimal(28, 3)` | YES | NO | `` |  |
| `So_12` | `decimal(28, 3)` | YES | NO | `` |  |
| `So_13` | `decimal(28, 3)` | YES | NO | `` |  |
| `So_14` | `decimal(28, 3)` | YES | NO | `` |  |
| `So_15` | `decimal(28, 3)` | YES | NO | `` |  |
| `So_16` | `decimal(28, 3)` | YES | NO | `` |  |
| `So_17` | `decimal(28, 3)` | YES | NO | `` |  |
| `So_18` | `decimal(28, 3)` | YES | NO | `` |  |
| `So_19` | `decimal(28, 3)` | YES | NO | `` |  |
| `So_20` | `decimal(28, 3)` | YES | NO | `` |  |

## QT_TK_ThongKeChiTiet_ChuyenDuLieu_Mau08

- Schema: `dbo`
- Primary key: _None detected_
- Unique constraints: _None detected_
- Foreign keys: **0**

| Column | Type | Null | Identity | Default | Notes |
|---|---|---|---|---|---|
| `Nhom` | `int` | YES | NO | `` |  |
| `DonViId` | `int` | YES | NO | `` |  |
| `ThoiGian` | `nvarchar(200)` | YES | NO | `` |  |
| `KieuKyBaoCao` | `int` | YES | NO | `` |  |
| `Created` | `nvarchar(50)` | YES | NO | `` |  |
| `CreatedBy` | `nvarchar(50)` | YES | NO | `` |  |
| `TenThongKe` | `nvarchar(200)` | YES | NO | `` |  |
| `MaSo` | `nvarchar(50)` | YES | NO | `` |  |
| `DVT` | `nvarchar(200)` | YES | NO | `` |  |
| `ThiTruong` | `nvarchar(200)` | YES | NO | `` |  |
| `So_01` | `decimal(28, 3)` | YES | NO | `` |  |
| `So_02` | `decimal(28, 3)` | YES | NO | `` |  |
| `So_03` | `decimal(28, 3)` | YES | NO | `` |  |
| `So_04` | `decimal(28, 3)` | YES | NO | `` |  |
| `So_05` | `decimal(28, 3)` | YES | NO | `` |  |
| `So_06` | `decimal(28, 3)` | YES | NO | `` |  |
| `So_07` | `decimal(28, 3)` | YES | NO | `` |  |
| `So_08` | `decimal(28, 3)` | YES | NO | `` |  |
| `So_09` | `decimal(28, 3)` | YES | NO | `` |  |
| `So_10` | `decimal(28, 3)` | YES | NO | `` |  |
| `So_11` | `decimal(28, 3)` | YES | NO | `` |  |
| `So_12` | `decimal(28, 3)` | YES | NO | `` |  |
| `So_13` | `decimal(28, 3)` | YES | NO | `` |  |
| `So_14` | `decimal(28, 3)` | YES | NO | `` |  |
| `So_15` | `decimal(28, 3)` | YES | NO | `` |  |
| `So_16` | `decimal(28, 3)` | YES | NO | `` |  |
| `So_17` | `decimal(28, 3)` | YES | NO | `` |  |
| `So_18` | `decimal(28, 3)` | YES | NO | `` |  |
| `So_19` | `decimal(28, 3)` | YES | NO | `` |  |
| `So_20` | `decimal(28, 3)` | YES | NO | `` |  |

## QT_TK_ThongKeChiTiet02

- Schema: `dbo`
- Primary key: `Id`
- Unique constraints: _None detected_
- Foreign keys: **4**

| Column | Type | Null | Identity | Default | Notes |
|---|---|---|---|---|---|
| `Id` | `uniqueidentifier` | NO | NO | `` | PK |
| `ThongKeId` | `uniqueidentifier` | NO | NO | `` | FK → QT_TK_ThongKe.Id |
| `Nhom` | `int` | YES | NO | `` |  |
| `XuatXuId` | `int` | YES | NO | `` | FK → DM_XuatXu.Id |
| `NhaCungCapId` | `int` | YES | NO | `` | FK → DM_NhaCungCap.Id |
| `HangHoaId` | `int` | YES | NO | `` | FK → DM_HangHoa.Id |
| `GhiChu` | `nvarchar(200)` | YES | NO | `` |  |
| `LoaiKho` | `int` | YES | NO | `` |  |
| `TenThongKe` | `nvarchar(200)` | YES | NO | `` |  |
| `MaSo` | `nvarchar(200)` | YES | NO | `` |  |
| `DiaChiKho` | `nvarchar(500)` | YES | NO | `` |  |
| `CONGMASO` | `nvarchar(100)` | YES | NO | `` |  |
| `ThuTu` | `int` | YES | NO | `` |  |
| `NongDoCon` | `decimal(28, 3)` | YES | NO | `` |  |
| `SoLuong` | `decimal(28, 3)` | YES | NO | `` |  |
| `GiaTri` | `decimal(28, 3)` | YES | NO | `` |  |
| `So_01` | `decimal(28, 3)` | YES | NO | `` |  |
| `So_02` | `decimal(28, 3)` | YES | NO | `` |  |
| `So_03` | `decimal(28, 3)` | YES | NO | `` |  |
| `So_04` | `decimal(28, 3)` | YES | NO | `` |  |
| `So_05` | `decimal(28, 3)` | YES | NO | `` |  |
| `So_06` | `decimal(28, 3)` | YES | NO | `` |  |
| `So_07` | `decimal(28, 3)` | YES | NO | `` |  |
| `So_08` | `decimal(28, 3)` | YES | NO | `` |  |
| `So_09` | `decimal(28, 3)` | YES | NO | `` |  |
| `So_10` | `decimal(28, 3)` | YES | NO | `` |  |
| `So_11` | `decimal(28, 3)` | YES | NO | `` |  |
| `So_12` | `decimal(28, 3)` | YES | NO | `` |  |
| `So_13` | `decimal(28, 3)` | YES | NO | `` |  |
| `So_14` | `decimal(28, 3)` | YES | NO | `` |  |
| `So_15` | `decimal(28, 3)` | YES | NO | `` |  |
| `So_16` | `decimal(28, 3)` | YES | NO | `` |  |
| `So_17` | `decimal(28, 3)` | YES | NO | `` |  |
| `So_18` | `decimal(28, 3)` | YES | NO | `` |  |
| `So_19` | `decimal(28, 3)` | YES | NO | `` |  |
| `So_20` | `decimal(28, 3)` | YES | NO | `` |  |
| `So_21` | `decimal(28, 3)` | YES | NO | `` |  |
| `So_22` | `decimal(28, 3)` | YES | NO | `` |  |
| `So_23` | `decimal(28, 3)` | YES | NO | `` |  |
| `So_24` | `decimal(28, 3)` | YES | NO | `` |  |
| `So_25` | `decimal(28, 3)` | YES | NO | `` |  |
| `DonViTinhId` | `int` | YES | NO | `` |  |
| `Created` | `datetime` | YES | NO | `` |  |
| `CreatedBy` | `nvarchar(50)` | YES | NO | `` |  |
| `Modified` | `datetime` | YES | NO | `` |  |
| `ModifiedBy` | `nvarchar(50)` | YES | NO | `` |  |
| `MaDoanhNghiep` | `nvarchar(200)` | YES | NO | `` |  |
| `DienThoai` | `nvarchar(50)` | YES | NO | `` |  |
| `Tinh` | `nvarchar(100)` | YES | NO | `` |  |
| `Huyen` | `nvarchar(100)` | YES | NO | `` |  |
| `Xa` | `nvarchar(200)` | YES | NO | `` |  |
| `SoNha` | `nvarchar(300)` | YES | NO | `` |  |
| `GiayXacNhan_So` | `nvarchar(200)` | YES | NO | `` |  |
| `GiayXacNhan_NgayCap` | `date` | YES | NO | `` |  |
| `GiayXacNhan_NoiCap` | `nvarchar(200)` | YES | NO | `` |  |
| `Xoa` | `int` | YES | NO | `` |  |
| `SoHuu` | `int` | YES | NO | `` |  |
| `GiayXacNhan_NgayHetHan` | `date` | YES | NO | `` |  |

### Relationships

- `QT_TK_ThongKeChiTiet02.HangHoaId` → `DM_HangHoa.Id` (`FK_QT_TK_ThongKeChiTiet02_DM_HangHoa`)
- `QT_TK_ThongKeChiTiet02.NhaCungCapId` → `DM_NhaCungCap.Id` (`FK_QT_TK_ThongKeChiTiet02_DM_NhaCungCap`)
- `QT_TK_ThongKeChiTiet02.XuatXuId` → `DM_XuatXu.Id` (`FK_QT_TK_ThongKeChiTiet02_DM_XuatXu`)
- `QT_TK_ThongKeChiTiet02.ThongKeId` → `QT_TK_ThongKe.Id` (`FK_TK_ThongKeChiTiet02_TK_ThongKe`)

## Global Relationships

- `AspNetUserClaims.UserId` → `AspNetUsers.Id`
- `AspNetUserLogins.UserId` → `AspNetUsers.Id`
- `AspNetUserRoles.RoleId` → `AspNetRoles.Id`
- `AspNetUserRoles.UserId` → `AspNetUsers.Id`
- `DM_XaPhuong.QuanHuyenId` → `DM_QuanHuyen.Id`
- `DM_XaPhuong.TinhId` → `DM_Tinh.Id`
- `QT_TK_ThongKe.don_vi_cap1` → `DM_DonVi.Id`
- `QT_TK_ThongKeChiTiet.ChiTieuThongKeId` → `TK_ChiTieuBaoCao.Id`
- `QT_TK_ThongKeChiTiet.ThongKeId` → `QT_TK_ThongKe.Id`
- `QT_TK_ThongKeChiTiet02.HangHoaId` → `DM_HangHoa.Id`
- `QT_TK_ThongKeChiTiet02.NhaCungCapId` → `DM_NhaCungCap.Id`
- `QT_TK_ThongKeChiTiet02.XuatXuId` → `DM_XuatXu.Id`
- `QT_TK_ThongKeChiTiet02.ThongKeId` → `QT_TK_ThongKe.Id`

## Suggested prompt for Cursor AI

```text
Read docs/architecture/database.md.

Tasks:
- Generate C# entity models
- Generate DTOs
- Generate repository/service layer
- Generate .NET Core API endpoints
- Generate Flutter models from exact database fields when needed

Rules:
- Use exact table and column names from schema.md
- Do not invent fields
- Respect primary keys, unique constraints, and foreign keys
```


## TK_ChiTieuBaoCao

- Schema: `dbo`
- Primary key: `Id`
- Unique constraints: `MAREPORT, IDCHITIEU`
- Foreign keys: **1**

| Column | Type | Null | Identity | Default | Notes |
|---|---|---|---|---|---|
| `Id` | `uniqueidentifier` | NO | NO | `` | PK |
| `IDCHITIEU` | `int` | YES | NO | `` |  |
| `MAREPORT` | `nvarchar(50)` | YES | NO | `` | UNIQUE |
| `MASTT` | `nvarchar(50)` | YES | NO | `` |  |
| `MA` | `nvarchar(100)` | YES | NO | `` |  |
| `TEN` | `nvarchar(1000)` | YES | NO | `` |  |
| `CONGMASO` | `nvarchar(300)` | YES | NO | `` |  |
| `INDEXORDER` | `int` | YES | NO | `` |  |
| `RECORDTYPE` | `int` | YES | NO | `` |  |
| `IDSTYLE` | `int` | YES | NO | `` |  |
| `IDNHOM` | `int` | YES | NO | `` |  |
| `STT` | `int` | YES | NO | `` |  |
| `QUYETDINH` | `nvarchar(50)` | YES | NO | `` |  |
| `THEOTHONGTU` | `nvarchar(50)` | YES | NO | `` |  |
| `CHUDAM` | `int` | YES | NO | `` |  |
| `TENSQL` | `nvarchar(300)` | YES | NO | `` |  |
| `TENNGOAINGU` | `nvarchar(300)` | YES | NO | `` |  |
| `Parent` | `uniqueidentifier` | YES | NO | `` |  |
| `Cap` | `int` | YES | NO | `` |  |
| `CoCapCon` | `int` | YES | NO | `` |  |
| `MaAo` | `nvarchar(200)` | YES | NO | `` |  |
| `Created` | `datetime` | YES | NO | `` |  |
| `CreatedBy` | `nvarchar(50)` | YES | NO | `` |  |
| `Modified` | `datetime` | YES | NO | `` |  |
| `ModifiedBy` | `nvarchar(50)` | YES | NO | `` |  |
| `Versions` | `timestamp` | YES | NO | `` |  |
| `CONGMASO2` | `nvarchar(300)` | YES | NO | `` |  |
| `HienThi` | `int` | YES | NO | `` |  |
| `DonViTinhId` | `int` | YES | NO | `` | FK → DM_DonViTinh.Id |
| `DonViTinh05Id` | `int` | YES | NO | `` |  |
| `DonViTinh02Id` | `int` | YES | NO | `` |  |

### Relationships

- `TK_ChiTieuBaoCao.DonViTinhId` → `DM_DonViTinh.Id` (`FK_TK_ChiTieuBaoCao_DM_DonViTinh`)

## TK_GiaoBaoCao

- Schema: `dbo`
- Primary key: `Id`
- Unique constraints: `BaoCaoId, KieuKyBaoCao`
- Foreign keys: **0**

| Column | Type | Null | Identity | Default | Notes |
|---|---|---|---|---|---|
| `Id` | `uniqueidentifier` | NO | NO | `` | PK |
| `DonViGiaoId` | `int` | YES | NO | `` |  |
| `BaoCaoId` | `uniqueidentifier` | YES | NO | `` | UNIQUE |
| `KieuKyBaoCao` | `int` | YES | NO | `` | UNIQUE |
| `NgayBatDauKyBC` | `datetime` | YES | NO | `` |  |
| `NgayKetThucKyBC` | `datetime` | YES | NO | `` |  |
| `TuNgay` | `datetime` | YES | NO | `` |  |
| `DenNgay` | `datetime` | YES | NO | `` |  |
| `Nam` | `int` | YES | NO | `` |  |
| `ThangQuy` | `int` | YES | NO | `` |  |
| `NgayMo` | `datetime` | YES | NO | `` |  |
| `NgayDong` | `datetime` | YES | NO | `` |  |
| `TuDongGiao` | `bit` | YES | NO | `` |  |
| `Created` | `datetime` | YES | NO | `` |  |
| `CreatedBy` | `nvarchar(50)` | YES | NO | `` |  |
| `Modified` | `datetime` | YES | NO | `` |  |
| `ModifiedBy` | `nvarchar(50)` | YES | NO | `` |  |

## TK_GiaoBaoCaoChiTiet

- Schema: `dbo`
- Primary key: `Id`
- Unique constraints: _None detected_
- Foreign keys: **1**

| Column | Type | Null | Identity | Default | Notes |
|---|---|---|---|---|---|
| `Id` | `uniqueidentifier` | NO | NO | `` | PK |
| `GiaoBaoCaoId` | `uniqueidentifier` | YES | NO | `` | FK → TK_GiaoBaoCao.Id |
| `DonViId` | `int` | YES | NO | `` |  |
| `Created` | `datetime` | YES | NO | `` |  |
| `CreatedBy` | `nvarchar(50)` | YES | NO | `` |  |
| `Modified` | `datetime` | YES | NO | `` |  |
| `ModifiedBy` | `nvarchar(50)` | YES | NO | `` |  |

### Relationships

- `TK_GiaoBaoCaoChiTiet.GiaoBaoCaoId` → `TK_GiaoBaoCao.Id` (`FK_TK_GiaoBaoCaoChiTiet_TK_GiaoBaoCao`, ON DELETE CASCADE)

## TK_QuanLyGiayPhep

- Schema: `dbo`
- Primary key: `Id`
- Unique constraints: `DonViId, SoGiayPhep, NgayCap`
- Foreign keys: **1**

| Column | Type | Null | Identity | Default | Notes |
|---|---|---|---|---|---|
| `Id` | `uniqueidentifier` | NO | NO | `` | PK |
| `DonViCapId` | `int` | YES | NO | `` | FK → DM_NoiCapGiayPhep.Id |
| `DonViId` | `int` | YES | NO | `` | UNIQUE |
| `DonVi` | `nvarchar(500)` | YES | NO | `` |  |
| `SoGiayPhep` | `nvarchar(50)` | YES | NO | `` | UNIQUE |
| `NgayCap` | `datetime` | YES | NO | `` | UNIQUE |
| `NgayHetHan` | `datetime` | YES | NO | `` |  |
| `Loai` | `int` | YES | NO | `` | 0 là giấy phép kd xăng dầu, 1 giấy phép kinh doanh rượu, 2 giấy phép kinh doanh thuốc lá |
| `LoaiGiayPhepId` | `int` | YES | NO | `` |  |
| `GhiChu` | `nvarchar(200)` | YES | NO | `` |  |
| `NgayThuHoi` | `datetime` | YES | NO | `` |  |
| `LyDoThuHoi` | `nvarchar(200)` | YES | NO | `` |  |
| `Created` | `datetime` | YES | NO | `` |  |
| `CreatedBy` | `nvarchar(50)` | YES | NO | `` |  |
| `Modified` | `datetime` | YES | NO | `` |  |
| `ModifiedBy` | `nvarchar(50)` | YES | NO | `` |  |

### Relationships

- `TK_QuanLyGiayPhep.DonViCapId` → `DM_NoiCapGiayPhep.Id` (`FK_TK_QuanLyGiayPhep_DM_NoiCapGiayPhep`)

## TK_QuanLyKhoXangDau

- Schema: `dbo`
- Primary key: `Id`
- Unique constraints: `DonViId, TenKho`
- Foreign keys: **1**

| Column | Type | Null | Identity | Default | Notes |
|---|---|---|---|---|---|
| `Id` | `uniqueidentifier` | NO | NO | `` | PK |
| `DonViId` | `int` | YES | NO | `` | UNIQUE, FK → DM_DonVi.Id |
| `TenKho` | `nvarchar(300)` | YES | NO | `` | UNIQUE |
| `Tinh` | `int` | YES | NO | `` |  |
| `Xa` | `int` | YES | NO | `` |  |
| `DiaChiChiTiet` | `nvarchar(500)` | YES | NO | `` |  |
| `TongDungTich` | `decimal(18, 3)` | YES | NO | `` |  |
| `LoaiKho` | `int` | YES | NO | `` | 0: kho sở hữu và cho thuê, 1 kho đi thuê |
| `TenDonViSoHuu` | `nvarchar(500)` | YES | NO | `` |  |
| `DonViNgoai` | `int` | YES | NO | `` |  |
| `GhiChu` | `nvarchar(200)` | YES | NO | `` |  |
| `SapXep` | `int` | YES | NO | `` |  |
| `Created` | `datetime` | YES | NO | `` |  |
| `CreatedBy` | `nvarchar(50)` | YES | NO | `` |  |
| `Modified` | `datetime` | YES | NO | `` |  |
| `ModifiedBy` | `nvarchar(50)` | YES | NO | `` |  |

### Relationships

- `TK_QuanLyKhoXangDau.DonViId` → `DM_DonVi.Id` (`FK_TK_QuanLyKhoXangDau_DM_DonVi`)

## TK_QuanLyKhoXangDau_HopDong

- Schema: `dbo`
- Primary key: `Id`
- Unique constraints: _None detected_
- Foreign keys: **1**

| Column | Type | Null | Identity | Default | Notes |
|---|---|---|---|---|---|
| `Id` | `uniqueidentifier` | NO | NO | `` | PK |
| `PhanBoId` | `uniqueidentifier` | YES | NO | `` | FK → TK_QuanLyKhoXangDau_PhanBoDungTich.Id |
| `SoHopDong` | `nvarchar(100)` | YES | NO | `` |  |
| `NgayBatDau` | `date` | YES | NO | `` |  |
| `NgayKetThuc` | `date` | YES | NO | `` |  |
| `GhiChu` | `nvarchar(200)` | YES | NO | `` |  |
| `Created` | `datetime` | YES | NO | `` |  |
| `CreatedBy` | `nvarchar(50)` | YES | NO | `` |  |
| `Modified` | `datetime` | YES | NO | `` |  |
| `ModifiedBy` | `nvarchar(50)` | YES | NO | `` |  |

### Relationships

- `TK_QuanLyKhoXangDau_HopDong.PhanBoId` → `TK_QuanLyKhoXangDau_PhanBoDungTich.Id` (`FK_TK_QuanLyKhoXangDau_HopDong_TK_QuanLyKhoXangDau_PhanBoDungTich`, ON DELETE CASCADE)

## TK_QuanLyKhoXangDau_PhanBoDungTich

- Schema: `dbo`
- Primary key: `Id`
- Unique constraints: _None detected_
- Foreign keys: **2**

| Column | Type | Null | Identity | Default | Notes |
|---|---|---|---|---|---|
| `Id` | `uniqueidentifier` | NO | NO | `` | PK |
| `KhoId` | `uniqueidentifier` | YES | NO | `` | FK → TK_QuanLyKhoXangDau.Id |
| `HinhThuc` | `int` | YES | NO | `` | 0: sử dụng nội bộ, 1: cho thuê |
| `ThuongNhanThueId` | `int` | YES | NO | `` | FK → DM_DonVi.Id |
| `BonBe` | `nvarchar(200)` | YES | NO | `` |  |
| `TongDungTich` | `decimal(18, 3)` | YES | NO | `` |  |
| `NgayBatDau` | `date` | YES | NO | `` |  |
| `NgayKetThuc` | `date` | YES | NO | `` |  |
| `TrangThai` | `int` | YES | NO | `` |  |
| `GhiChu` | `nvarchar(200)` | YES | NO | `` |  |
| `Created` | `datetime` | YES | NO | `` |  |
| `CreatedBy` | `nvarchar(50)` | YES | NO | `` |  |
| `Modified` | `datetime` | YES | NO | `` |  |
| `ModifiedBy` | `nvarchar(50)` | YES | NO | `` |  |

### Relationships

- `TK_QuanLyKhoXangDau_PhanBoDungTich.KhoId` → `TK_QuanLyKhoXangDau.Id` (`FK_TK_QuanLyKhoXangDau_PhanBoDungTich_TK_QuanLyKhoXangDau`)
- `TK_QuanLyKhoXangDau_PhanBoDungTich.ThuongNhanThueId` → `DM_DonVi.Id` (`FK_TK_QuanLyKhoXangDau_PhanBoDungTich_DM_DonVi`)

## TK_QuanLyKhoXangDau_TonKho

- Schema: `dbo`
- Primary key: `Id`
- Unique constraints: _None detected_
- Foreign keys: **1**

| Column | Type | Null | Identity | Default | Notes |
|---|---|---|---|---|---|
| `Id` | `uniqueidentifier` | NO | NO | `` | PK |
| `PhanBoId` | `uniqueidentifier` | YES | NO | `` | FK → TK_QuanLyKhoXangDau_PhanBoDungTich.Id |
| `Ngay` | `datetime` | YES | NO | `` |  |
| `SoLuong` | `decimal(18, 3)` | YES | NO | `` |  |
| `HeSo` | `int` | YES | NO | `` |  |
| `GhiChu` | `nvarchar(200)` | YES | NO | `` |  |
| `Created` | `datetime` | YES | NO | `` |  |
| `CreatedBy` | `nvarchar(50)` | YES | NO | `` |  |
| `Modified` | `datetime` | YES | NO | `` |  |
| `ModifiedBy` | `nvarchar(50)` | YES | NO | `` |  |

### Relationships

- `TK_QuanLyKhoXangDau_TonKho.PhanBoId` → `TK_QuanLyKhoXangDau_PhanBoDungTich.Id` (`FK_TK_QuanLyKhoXangDau_TonKho_TK_QuanLyKhoXangDau_PhanBoDungTich`, ON DELETE CASCADE)
---

## Table: DM_KieuKyBaoCao

| Column | Type | Nullable | Description |
|--------|------|----------|------------|
| Id | int | NOT NULL | Primary key |
| Ma | nvarchar(50) | NULL | Mã kiểu kỳ báo cáo |
| Ten | nvarchar(300) | NOT NULL | Tên kiểu kỳ báo cáo |
| tenantId | int | NULL | Tenant (đa đơn vị) |
| Parent | int | NULL | Id cha (phân cấp) |
| category | int | NULL | Nhóm phân loại |
| SapXep | int | NULL | Thứ tự sắp xếp |
| Created | datetime | NULL | Ngày tạo |
| CreatedBy | nvarchar(100) | NULL | Người tạo |
| Modified | datetime | NULL | Ngày sửa |
| ModifiedBy | nvarchar(100) | NULL | Người sửa |

### Primary Key
- PK_DM_KieuKyBaoCao: Id

### Relationships
- Parent → DM_KieuKyBaoCao.Id (self-reference)

### Business Notes
- Bảng dùng để định nghĩa các loại kỳ báo cáo (tháng, quý, năm…)
- Có hỗ trợ phân cấp (Parent)
- Dùng cho cấu hình báo cáo trong hệ thống
# STORE ADMIN SCHEMA EXTENSION (CỬA HÀNG XĂNG DẦU)

## DM_DonVi (Extended for Petrol Station)

- Schema: `dbo`
- Primary key: `Id`
- Notes: Reuse for petrol station where `CapDonViId = 248` (see `PetrolRetailConstants.CapDonViId` in API code)

### Additional Columns

| Column | Type | Null | Notes |
|---|---|---:|---|
| `OpenTime` | `time` | YES | Giờ mở cửa |
| `CloseTime` | `time` | YES | Giờ đóng cửa |

### Stored procedure: `dbo.sp_Station_Search`

- **API**: `GET /api/stations` — danh sách cửa hàng xăng dầu (`CapDonViId = 248`) và tìm theo từ khóa (Search Bar). Dữ liệu trang + `TotalCount` lấy qua thủ tục; snapshot giá (`StationPrices` / `StationProductPrices`) và xử lý `StationOperatingHours` theo ngày trong tuần vẫn ghép ở tầng ứng dụng (Dapper + dịch vụ hiện có), không đổi JSON response.
- **Tham số** (tất cả nullable an toàn theo contract API):

| Parameter | Type | Ý nghĩa |
|---|---|---|
| `@Keyword` | `nvarchar(200)` | Từ khóa (trim trong SP); `NULL` / rỗng = không lọc theo text |
| `@ProvinceMa` | `nvarchar(20)` | `DM_Tinh.Ma`; `NULL` = mọi tỉnh |
| `@QuanHuyenId` | `int` | `DM_XaPhuong.QuanHuyenId`; `NULL` = mọi quận/huyện |
| `@Status` | `nvarchar(20)` | `all` / `open` / `closed` (giờ VN + `StationOperatingHours`, cùng logic `sp_Reports_GetStationOverview`) |
| `@DayOfWeek` | `tinyint` | 0–6 (`System.DayOfWeek`) |
| `@NowTime` | `time(0)` | Giờ trong ngày (VN) để đánh giá mở/đóng |
| `@RetailCapDonViId` | `int` | Luôn `248` từ `PetrolRetailConstants.CapDonViId` |
| `@Skip` | `int` | Phân trang OFFSET |
| `@Take` | `int` | Phân trang FETCH |

- **Tập kết quả**:
  1. Một dòng: `TotalCount` (`bigint`) — tổng bản ghi sau mọi bộ lọc.
  2. Trang: `StationId`, `StationCode`, `StationName`, `AddressLine`, `ProvinceCode`, `ProvinceName`, `WardCode`, `WardName`, `DistrictId`, `LicenseNumber`, `IsActive`, `OpenTime`, `CloseTime` — khớp projection LINQ cũ; sắp xếp `ORDER BY Ten, Ma`.

- **Tìm kiếm text** (khi `@Keyword` khác rỗng): `LIKE N'%' + @Keyword + N'%'` trên `Ten`, `Ma`, `DiaChiChiTiet`, `DiaChi`, `SoGiayPhep` (cùng hành vi `Contains` trước đây).

- **Gợi ý index** (tùy tải, áp dụng sau khi đo): composite trên `DM_DonVi(CapDonViId)` kèm INCLUDE các cột tìm kiếm nếu cần tối ưu LIKE.

---

## FuelProducts

- Schema: `dbo`
- Primary key: `Id`
- Unique constraints: `Code`
- Foreign keys: **0 (logic FK to DM_DonViTinh)**

| Column | Type | Null | Identity | Default | Notes |
|---|---|---:|---:|---|---|
| `Id` | `int` | NO | YES |  | PK |
| `Code` | `nvarchar(50)` | NO | NO |  | UNIQUE |
| `Name` | `nvarchar(200)` | NO | NO |  |  |
| `ParentId` | `int` | YES | NO |  | Self reference |
| `UnitId` | `int` | YES | NO |  | DM_DonViTinh.Id |
| `IsActive` | `bit` | NO | NO |  |  |
| `SortOrder` | `int` | YES | NO |  |  |
| `Description` | `nvarchar(500)` | YES | NO |  |  |
| `Created` | `datetime` | NO | NO |  |  |
| `CreatedBy` | `nvarchar(100)` | YES | NO |  |  |
| `Modified` | `datetime` | NO | NO |  |  |
| `ModifiedBy` | `nvarchar(100)` | YES | NO |  |  |

---

## StationPrices

- Schema: `dbo`
- Primary key: `Id`
- Foreign keys: **0 (logic FK to DM_DonVi)** — `DonViId` → `DM_DonVi.Id`
- Relationship: **1 : N** với `StationProductPrices` qua `StationProductPrices.StationPricesId`
- **Cascade:** xóa một bản ghi `StationPrices` sẽ xóa tất cả dòng `StationProductPrices` tham chiếu (FK `ON DELETE CASCADE`).

Bảng giá theo lần áp dụng (thông tin chung một lần nhập/sửa giá cho cửa hàng): `ActiveDate` là ngày áp dụng bảng giá; `IsActive` đánh dấu bảng giá đang hiệu lực cho cửa hàng (ứng dụng admin gán khi lưu batch).

| Column | Type | Null | Identity | Default | Notes |
|---|---|---:|---:|---|---|
| `Id` | `int` | NO | YES |  | PK |
| `DonViId` | `int` | NO | NO |  | DM_DonVi.Id |
| `ActiveDate` | `datetime` | NO | NO |  | Ngày áp dụng bảng giá |
| `IsActive` | `bit` | NO | NO |  | Bảng giá áp dụng hiện tại |
| `Created` | `datetime` | NO | NO |  |  |
| `CreatedBy` | `nvarchar(50)` | YES | NO |  |  |
| `Modified` | `datetime` | NO | NO |  |  |
| `ModifiedBy` | `nvarchar(50)` | YES | NO |  |  |

---

## StationProductPrices

- Schema: `dbo`
- Primary key: `Id`
- Foreign keys: **`StationPricesId` → `StationPrices.Id` (ON DELETE CASCADE)**; logic FK tới `DM_DonVi`, `FuelProducts`, `DM_DonViTinh`

| Column | Type | Null | Identity | Default | Notes |
|---|---|---:|---:|---|---|
| `Id` | `int` | NO | YES |  | PK |
| `StationPricesId` | `int` | NO | NO |  | FK → `StationPrices.Id` (cascade delete) |
| `DonViId` | `int` | NO | NO |  | DM_DonVi.Id (denormalized; khớp header) |
| `ProductId` | `int` | NO | NO |  | FuelProducts.Id |
| `Price` | `decimal(18,2)` | NO | NO |  |  |
| `UnitId` | `int` | YES | NO |  | DM_DonViTinh.Id |
| `EffectiveDate` | `datetime` | NO | NO |  | Trùng `ActiveDate` của header khi lưu từ admin |
| `IsCurrent` | `bit` | NO | NO |  | Giá hiện hành theo mặt hàng |
| `Note` | `nvarchar(500)` | YES | NO |  | Ghi chú |
| `Created` | `datetime` | NO | NO |  |  |
| `CreatedBy` | `nvarchar(100)` | YES | NO |  |  |
| `Modified` | `datetime` | NO | NO |  |  |
| `ModifiedBy` | `nvarchar(100)` | YES | NO |  |  |

---

## StationInventoryTransactions (Legacy / deprecated)

- Schema: `dbo`
- **Status:** **Legacy / deprecated.** Bảng một dòng = một dòng sổ kho (đã dùng trước khi chuẩn hóa). Sau migration `StationInventoryTransactionHeadersAndDetails`, dữ liệu được chuyển sang cặp bảng header/detail và bảng này được **TRUNCATE** (giữ cấu trúc để tham chiếu / rollback thủ công, không còn dùng trong API).
- Primary key: `Id`
- Foreign keys: **0 (logic FK to DM_DonVi, FuelProducts)**

| Column | Type | Null | Identity | Default | Notes |
|---|---|---:|---:|---|---|
| `Id` | `int` | NO | YES |  | PK |
| `DonViId` | `int` | NO | NO |  | DM_DonVi.Id |
| `ProductId` | `int` | NO | NO |  | FuelProducts.Id |
| `Quantity` | `decimal(18,3)` | NO | NO |  |  |
| `Amount` | `decimal(18,2)` | YES | NO |  |  |
| `TransactionType` | `int` | NO | NO |  | 1: nhập, -1: xuất |
| `TransactionDate` | `datetime` | NO | NO |  |  |
| `Note` | `nvarchar(500)` | YES | NO |  | Ghi chú |
| `Created` | `datetime` | NO | NO |  |  |
| `CreatedBy` | `nvarchar(100)` | YES | NO |  |  |
| `Modified` | `datetime` | NO | NO |  |  |
| `ModifiedBy` | `nvarchar(100)` | YES | NO |  |  |

### Ghi chú migration (grouping)

- Khi đổ dữ liệu từ bảng legacy sang header/detail, các dòng legacy được **gom nhóm** theo: `DonViId`, `TransactionType`, `TransactionDate`, `Note`, `Created`, `CreatedBy`, `Modified`, `ModifiedBy` — mỗi nhóm tạo **một** `StationInventoryTransactionHeaders` và mỗi dòng legacy trong nhóm thành **một** `StationInventoryTransactionDetails` (`ProductId`, `Quantity`, `Amount`). Cột `Note` ở detail sau migration để **NULL** (legacy chỉ có ghi chú ở cấp “phiếu”, đã map vào header). Migration sau (`StationInventoryTransactionDetailsUnitId`) thêm cột **`UnitId`** (NOT NULL, FK `DM_DonViTinh`) và backfill cho các dòng đã có. Migration `InventoryTransactionDetailsRequireUnitIdXmlAndUnitName` siết chặt **`unitId`** trong XML lưu phiếu và bổ sung **`UnitName`** khi đọc danh sách chi tiết.
- **Giả định:** hai dòng legacy khác `ProductId` nhưng trùng toàn bộ khóa nhóm trên được coi là **cùng một phiếu** (đúng với mục tiêu chuẩn hóa). Nếu trùng khóa nhưng `ProductId` trùng nhau, sau migration vẫn là hai dòng detail (hợp lệ).

---

## StationInventoryTransactionHeaders

- Schema: `dbo`
- Primary key: `Id` (identity)
- Foreign keys: **0** (logic FK tới `DM_DonVi`; kiểm tra cửa hàng xăng dầu qua `CapDonViId` trong stored procedure)
- **Quan hệ:** 1 header có N dòng trong `StationInventoryTransactionDetails` (`HeaderId` → `Id`).

| Column | Type | Null | Identity | Default | Notes |
|---|---|---:|---:|---|---|
| `Id` | `int` | NO | YES |  | PK |
| `DonViId` | `int` | NO | NO |  | Cửa hàng (`DM_DonVi.Id`) |
| `TransactionType` | `int` | NO | NO |  | 1: nhập, -1: xuất |
| `TransactionDate` | `datetime` | NO | NO |  | Ngày giờ giao dịch (chung cho cả phiếu) |
| `Note` | `nvarchar(500)` | YES | NO |  | Ghi chú cấp phiếu |
| `Created` | `datetime` | NO | NO |  |  |
| `CreatedBy` | `nvarchar(100)` | YES | NO |  |  |
| `Modified` | `datetime` | NO | NO |  |  |
| `ModifiedBy` | `nvarchar(100)` | YES | NO |  |  |

### Relationships

- `StationInventoryTransactionDetails.HeaderId` → `StationInventoryTransactionHeaders.Id` (**ON DELETE CASCADE** trong EF / DB).

### Admin API (tham chiếu ứng dụng)

- `GET /api/admin/inventory-transactions/latest?donViId={id}` — trả về phiếu **mới nhất** (header + danh sách chi tiết) cho cửa hàng; chỉ gọi stored procedure `dbo.sp_StoreAdmin_StationInventoryTransactionHeaders_GetLatest` (không đọc bảng trực tiếp từ API).

---

## StationInventoryTransactionDetails

- Schema: `dbo`
- Primary key: `Id` (identity)
- Foreign keys:
  - **`HeaderId` → `StationInventoryTransactionHeaders.Id` (ON DELETE CASCADE)**
  - **`ProductId` → `FuelProducts.Id` (RESTRICT)**
  - **`UnitId` → `DM_DonViTinh.Id` (RESTRICT)**

| Column | Type | Null | Identity | Default | Notes |
|---|---|---:|---:|---|---|
| `Id` | `int` | NO | YES |  | PK |
| `HeaderId` | `int` | NO | NO |  | FK → header |
| `ProductId` | `int` | NO | NO |  | `FuelProducts.Id` |
| `UnitId` | `int` | NO | NO |  | Đơn vị tính (`DM_DonViTinh.Id`); dữ liệu cũ backfill theo `FuelProducts.UnitId` hoặc đơn vị lít trong `DM_DonViTinh` |
| `Quantity` | `decimal(18,3)` | NO | NO |  | Số lượng dòng |
| `Amount` | `decimal(18,2)` | YES | NO |  | Tiền (tùy chọn) |
| `Note` | `nvarchar(500)` | YES | NO |  | Ghi chú theo dòng |

### Relationships

- `HeaderId` → `StationInventoryTransactionHeaders.Id`
- `ProductId` → `FuelProducts.Id`
- `UnitId` → `DM_DonViTinh.Id`

### Admin API (chi tiết phiếu)

- `POST` / `PUT` `/api/admin/inventory-transactions` — payload JSON `details[]`: mỗi dòng gửi **`unitId`** (`DM_DonViTinh.Id`, bắt buộc) trừ khi **`useProductDefaultUnit`: true** thì API dùng `FuelProducts.UnitId` của `productId` (đổi số lượng giữa đơn vị: dự phòng). Lớp API gọi `dbo.sp_StoreAdmin_DM_DonViTinh_Exists` để xác thực id; khi dùng đơn vị mặc định sản phẩm thì đọc `dbo.sp_StoreAdmin_FuelProduct_UnitById`. Stored procedure `dbo.sp_StoreAdmin_StationInventoryTransactionHeaders_SaveWithDetails` / `UpdateWithDetails` yêu cầu XML mỗi phần tử `<r>` có **`unitId`** hợp lệ **hoặc** tham số tùy chọn **`@DefaultDetailUnitId`** (áp dụng khi thiếu/`0` trên từng `<r>`, phải là `DM_DonViTinh.Id` hợp lệ). API hiện không truyền `@DefaultDetailUnitId` (chỉ XML đủ `unitId`).
- Đọc chi tiết: `dbo.sp_StoreAdmin_StationInventoryTransactionDetails_ListByHeaderId` và tập kết quả chi tiết của `dbo.sp_StoreAdmin_StationInventoryTransactionHeaders_GetLatest` trả thêm cột hiển thị **`UnitName`** (`DM_DonViTinh.Ten`, `LEFT JOIN` theo `UnitId`).

---

## StationRatings

- Schema: `dbo`
- Primary key: `Id` (identity)
- Foreign keys: **`StationId` → `DM_DonVi.Id`**
- Unique constraints: _None_
- Ghi chú: `StationId` là đơn vị bán lẻ xăng dầu (`DM_DonVi.CapDonViId = 248`); logic ghi được kiểm trong `dbo.sp_StationRating_Insert`. Xóa mềm: `IsDeleted = 1` (API hiện không cập nhật cột này).

| Column | Type | Null | Identity | Default | Notes |
|---|---|---:|---:|---|---|
| `Id` | `int` | NO | YES |  | PK |
| `StationId` | `int` | NO | NO |  | FK → `DM_DonVi.Id` |
| `Rating` | `int` | NO | NO |  | CHECK 1–5 |
| `Comment` | `nvarchar(500)` | YES | NO |  |  |
| `DeviceId` | `nvarchar(100)` | YES | NO |  | Trùng `DeviceId` + `StationId` trong cùng ngày (theo `GETDATE()` trên SQL Server) bị chặn ở SP khi `DeviceId` không null |
| `CreatedBy` | `nvarchar(100)` | YES | NO |  |  |
| `CreatedAt` | `datetime` | NO | NO | `GETDATE()` |  |
| `IsDeleted` | `bit` | NO | NO | `(0)` |  |

### Stored procedures (ghi / đọc)

- `dbo.sp_StationRating_Insert` — thêm một bản ghi; OUTPUT `@RatingId`, `@ErrorMessage`.
- `dbo.sp_StationRating_GetSummary` — `AvgRating`, `TotalRatings` (chỉ `IsDeleted = 0`).
- `dbo.sp_StationRating_GetByStation` — hai tập kết quả: (1) đánh giá, (2) ảnh.

### Public API (tham chiếu)

- `POST /api/station-ratings` — gọi `sp_StationRating_Insert` rồi lặp `sp_StationRatingImage_Insert` trong transaction ADO.NET.
- `GET /api/station-ratings/summary/{stationId}` — `sp_StationRating_GetSummary`.
- `GET /api/station-ratings/station/{stationId}` — `sp_StationRating_GetByStation`.

---

## StationRatingImages

- Schema: `dbo`
- Primary key: `Id` (identity)
- Foreign keys: **`RatingId` → `StationRatings.Id`**

| Column | Type | Null | Identity | Default | Notes |
|---|---|---:|---:|---|---|
| `Id` | `int` | NO | YES |  | PK |
| `RatingId` | `int` | NO | NO |  | FK → `StationRatings.Id` |
| `ImageUrl` | `nvarchar(500)` | NO | NO |  | Đường dẫn lưu trữ (không base64) |
| `CreatedAt` | `datetime` | NO | NO | `GETDATE()` |  |

### Stored procedures (ghi)

- `dbo.sp_StationRatingImage_Insert` — một ảnh; OUTPUT `@ErrorMessage` khi `RatingId` không tồn tại hoặc đánh giá đã xóa mềm.

---

## Mobile Dashboard API (stored procedures)

Phần này ghi lại **các API backend mà màn hình Dashboard mobile (Flutter) thực sự gọi** và cách đọc CSDL (theo `docs/architecture/backend.md`). Các mục như “cây xăng uy tín / gần nhất / rẻ nhất”, biểu đồ 7 ngày, tổng chi phí nhiên liệu… **không có endpoint riêng** trên Dashboard hiện tại: UI dùng dữ liệu từ `GET /api/reports/overview` hoặc điều hướng sang bản đồ.

### Checklist API → stored procedure

| API route | Controller / service | Nguồn dữ liệu DB | Phương thức | Stored procedure | Trạng thái |
|-----------|----------------------|------------------|--------------|-------------------|------------|
| `GET /api/reports/overview` | `ReportsOverviewController` → `ReportsOverviewReadService` | `DM_DonVi`, `StationOperatingHours`, `DM_Tinh`; tồn kho báo cáo: `QT_TK_ThongKe`, `QT_TK_ThongKeChiTiet`, `DM_KieuKyBaoCao` | Dapper `CommandType.StoredProcedure` | `dbo.sp_Reports_GetStationOverview`; `dbo.sp_Reports_GetInventorySummary` | Đã dùng SP (phần tồn kho tổng hợp trước đây lặp logic LINQ trong `FuelReportingReadService` — đã chuyển sang gọi SP giống định nghĩa SQL sẵn có). |
| `GET /api/inventory/summary` | `InventoryReportsController` → `FuelReportingReadService` | Cùng pipeline tồn kho báo cáo như trên | Dapper | `dbo.sp_Reports_GetInventorySummary`; nếu có `kieuKyBaoCao`: `dbo.sp_Reports_CheckKieuKyBaoCaoExists` | Đồng bộ với overview (không đổi route/DTO). |
| `GET /api/my-vehicles` | `UserVehiclesController` → `UserVehicleService` | `UserVehicles`, `AspNetUsers`, … | Dapper | `dbo.sp_UserVehicles_GetByUser` (và các SP CRUD khác khi không phải Dashboard) | Đã dùng SP; không đổi. |
| Greeting / avatar | (JWT ở client) | — | — | — | Không gọi API profile riêng. |
| `GET /api/my-vehicles/fuel-product-options` | Chỉ form thêm/sửa xe | `FuelProducts` (qua SP module Store Admin) | SP | (theo `StoreAdminFuelProducts` — không tải khi chỉ mở Dashboard overview) | Ngoài phạm vi tải Dashboard mặc định. |
| `GET /api/fuel/current-vehicle` | `FuelController` → `FuelService` | `UserVehicles` | Dapper | `dbo.sp_Fuel_GetCurrentVehicle` | Tab Nhiên liệu (mobile). |
| `GET /api/fuel/summary` | `FuelController` | `FuelTransactions`, `UserVehicles` | Dapper | `dbo.sp_Fuel_GetMonthlySummary` |  |
| `GET /api/fuel/insights` | `FuelController` | `FuelTransactions`, `UserVehicles` | Dapper | `dbo.sp_Fuel_GetInsights` |  |
| `GET /api/fuel/transactions` | `FuelController` | `FuelTransactions`, `DM_DonVi` | Dapper | `dbo.sp_Fuel_GetTransactions` |  |
| `POST /api/fuel/transactions` | `FuelController` | `FuelTransactions` | Dapper | `dbo.sp_FuelTransaction_Insert` |  |
| `GET /api/leader/stabilization-fund/summary` | `LeaderStabilizationFundController` → `StabilizationFundReportPeriodResolver` + `LeaderStabilizationFundDataAccess` | `AppSystemSettings` (mốc ngày), `DM_DonVi`, BC08 qua `dbo.sp_Dashboard_FuelStabilizationFund` | Dapper | `dbo.sp_Dashboard_FuelStabilizationFund` | Lãnh đạo (`Loai = 6`); không query `month`/`year` → kỳ mới nhất theo VN + mốc ngày |
| `GET /api/leader/stabilization-fund/distributors` | Cùng | Cùng | Dapper | `dbo.sp_Dashboard_FuelStabilizationFund` |  |
| `GET /api/leader/stabilization-fund/distributors/{id}/history` | Cùng | Cùng | Dapper | Lặp gọi `dbo.sp_Dashboard_FuelStabilizationFund` theo tháng |  |

### `dbo.sp_Reports_CheckKieuKyBaoCaoExists` (mới)

- **Mục đích:** Kiểm tra `DM_KieuKyBaoCao.Id` tồn tại trước khi gọi `sp_Reports_GetInventorySummary` với tham số lọc — giữ cùng thông báo lỗi validation như trước (khi `kieuKyBaoCao` không hợp lệ).
- **Tham số:** `@Id INT` — khóa `DM_KieuKyBaoCao.Id`.
- **Kết quả:** Một dòng, cột `Exists` (bit): `1` nếu có bản ghi.
- **API liên quan:** `GET /api/inventory/summary?kieuKyBaoCao=…`, gián tiếp logic filter cho tổng hợp tồn (cùng service với overview).

### `dbo.sp_Reports_GetInventorySummary` (đã có sẵn)

- **Tham số:** `@KieuKyBaoCao INT = NULL`.
- **Kết quả:** 3 tập: (1) header kỳ báo cáo, (2) một dòng `ReportingStationCount` / `StockLineCount` / `TotalSo01`, (3) nhóm theo `Nhom` (`LineCount`, `SumSo01`).
- **API liên quan:** `GET /api/reports/overview` (khối stock), `GET /api/inventory/summary`.

### `dbo.sp_Reports_GetStationOverview` (đã có sẵn)

- **API liên quan:** `GET /api/reports/overview` (tổng / mở / đóng + `stationsByProvince`).
- **Sửa lỗi (CTE scope):** Bản đầu dùng CTE `Stations` rồi hai câu `SELECT` liên tiếp; câu thứ hai (`stationsByProvince`) nằm **ngoài** phạm vi CTE nên SQL Server báo `Invalid object name 'Stations'`. Phiên bản hiện tại dùng bảng tạm `#Stations` (đổ từ `DM_DonVi`) cho cả hai tập kết quả. Áp dụng qua migration `20260426162735_FixSpReportsGetStationOverviewCteScope` (và cùng nội dung trong `ReportsStoredProcedures.cs`).

### Ghi chú triển khai

- Sau khi thêm migration, chạy `dotnet ef database update` (hoặc file SQL tương ứng trong `backend/database/migrations/`) để tạo `dbo.sp_Reports_CheckKieuKyBaoCaoExists` và cập nhật `dbo.sp_Reports_GetStationOverview` trên SQL Server.
- **Dashboard API hiện dùng stored procedure cho toàn bộ truy vấn CSDL** trên các endpoint trên; không còn LINQ-to-Entities cho khối tổng hợp tồn kho trong `GetInventorySummaryAsync`.

---

## Inventory Calculation

- Tồn kho hiện tại (store admin): `SUM(QuantityForStock * TransactionType)` trong `dbo.sp_StoreAdmin_InventoryCurrent_ListPaged` / `ListByStore` — **demo**: `QuantityForStock = CAST(Quantity AS DECIMAL(18,4))` (giả định cùng hệ đơn vị); **sau này**: nhân hệ số quy đổi theo `DetailUnitId` / `ProductCatalogUnitId` khi có hàm/scalar UDF chuyển đơn vị. Kết quả trả về (cột) giữ nguyên so với bản trước.

---  