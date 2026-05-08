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
- Field: 
+ Loai: 0 = Estimated Data (Số liệu ước tính) 1 = Official Finalized Data (Dữ liệu chốt chính thức)


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
| `Modified` | `datetime` | YES | NO | `` |  
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
## Stored Procedure: sp_Dashboard_Home_InventorySummary

### 1. Mục đích

Thủ tục `sp_Dashboard_Home_InventorySummary` dùng để lấy dữ liệu tổng hợp tồn kho, nhập xuất và cân đối nhập xuất nhiên liệu xăng dầu phục vụ màn hình Dashboard/Home.

Thủ tục trả về dữ liệu thống kê cho tất cả đơn vị đầu mối xăng dầu trong kỳ báo cáo gần nhất.

Dữ liệu mặc định lấy từ báo cáo đã chốt:

- `QT_TK_ThongKe.Loai = 1`: dữ liệu chốt/chính thức.
- `QT_TK_ThongKe.TrangThai = 5`: báo cáo đã hoàn thành.
- `DM_DonVi.CapDonViId = 235`: đơn vị đầu mối.

---

### 2. Tham số đầu vào

| Tham số | Kiểu dữ liệu | Mặc định | Mô tả |
|---|---|---|---|
| `@UserName` | `NVARCHAR(128)` | `NULL` | Tên đăng nhập người dùng |
| `@DonViId` | `NVARCHAR(50)` | `NULL` | Mã đơn vị |
| `@Period` | `NVARCHAR(20)` | `N'THANG'` | Kỳ báo cáo |
| `@Month` | `INT` | `NULL` | Tháng báo cáo |
| `@Year` | `INT` | `NULL` | Năm báo cáo |

---

### 3. Quy tắc xác định kỳ dữ liệu

Thủ tục tự xác định kỳ báo cáo gần nhất theo ngày hiện tại:

- Nếu ngày hiện tại `< 20`: lấy dữ liệu kỳ cách hiện tại 2 tháng.
- Nếu ngày hiện tại `>= 20`: lấy dữ liệu kỳ cách hiện tại 1 tháng.

Đồng thời thủ tục cũng lấy kỳ trước đó để tính tỷ lệ so sánh nhập/xuất.

---

### 4. Dữ liệu trả về

Thủ tục trả về 3 bảng kết quả.

---

## 4.1. Bảng tồn kho nhiên liệu

Trả về thống kê lượng tồn kho xăng dầu của tất cả đơn vị đầu mối trong kỳ gần nhất.

| Cột | Mô tả |
|---|---|
| `Ten` | Loại nhiên liệu |
| `Type` | Mã loại nhiên liệu |
| `SoNgay` | Số ngày có thể sử dụng |
| `GiaTri` | Số lượng tồn kho |
| `Dvt` | Đơn vị tính |

Ví dụ:

| Ten | Type | GiaTri | SoNgay | Dvt |
|---|---|---|---|---|
| XĂNG | xang | 120000 | 25 | m³ |
| DẦU | dau | 80000 | 20 | tấn |

---

## 4.2. Bảng nhập xuất nhiên liệu

Trả về lượng nhập xuất của từng loại nhiên liệu trong kỳ.

| Cột | Mô tả |
|---|---|
| `Ten` | Tên loại nhiên liệu |
| `Dvt` | Đơn vị tính |
| `Nhap` | Giá trị nhập |
| `Xuat` | Giá trị xuất |

---

## 4.3. Bảng cân đối nhập xuất

Trả về dữ liệu cân đối nhập xuất trong kỳ.

| Cột | Mô tả |
|---|---|
| `Ten` | Tên loại nhiên liệu |
| `Dvt` | Đơn vị tính |
| `GiaTri` | Giá trị tăng/giảm nhập xuất |

Ý nghĩa:

- `GiaTri > 0`: nhập nhiều hơn xuất.
- `GiaTri < 0`: xuất nhiều hơn nhập.

---

### 5. Công thức tính toán

#### Tổng tồn cuối kỳ

```sql
TongTon = SUM(So_14)
```

#### Tổng nhập

```sql
TongNhap = SUM(
    So_02 + So_03 + So_04 +
    So_05 + So_06 + So_07
)
```

#### Tổng xuất

```sql
TongXuat = SUM(
    So_08 + So_10 + So_11 +
    So_12 + So_13 + So_24
)
```

#### Bình quân sử dụng/ngày

```sql
BinhQuan = (TonDauKy + TongNhap - TonCuoiKy) / 30
```

#### Số ngày có thể sử dụng

```sql
SoNgay = TonCuoiKy / BinhQuan
```

#### Cân đối nhập xuất

```sql
GiaTri = TongNhap - TongXuat
```

---

### 6. Code thủ tục

```sql
CREATE PROCEDURE [dbo].[sp_Dashboard_Home_InventorySummary]
    @UserName NVARCHAR(128) = NULL,
    @DonViId NVARCHAR(50) = NULL,
    @Period NVARCHAR(20) = N'THANG',
    @Month INT = NULL,
    @Year INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @NgayHienTai DATE = GETDATE();
    DECLARE @NgayHienTaiTruoc DATE = GETDATE();

    DECLARE @Thang INT;
    DECLARE @Nam INT;

    DECLARE @ThangTruoc INT;
    DECLARE @NamTruoc INT;

    IF DAY(@NgayHienTai) < 20
    BEGIN
        SET @NgayHienTai = DATEADD(MONTH, -2, @NgayHienTai);
        SET @NgayHienTaiTruoc = DATEADD(MONTH, -3, @NgayHienTaiTruoc);
    END
    ELSE
    BEGIN
        SET @NgayHienTai = DATEADD(MONTH, -1, @NgayHienTai);
        SET @NgayHienTaiTruoc = DATEADD(MONTH, -2, @NgayHienTaiTruoc);
    END

    SET @Thang = MONTH(@NgayHienTai);
    SET @Nam = YEAR(@NgayHienTai);

    SET @ThangTruoc = MONTH(@NgayHienTaiTruoc);
    SET @NamTruoc = YEAR(@NgayHienTaiTruoc);

    /*
        Lấy dữ liệu báo cáo:
        - Loại = 1 (dữ liệu chốt)
        - TrangThai = 5 (đã hoàn thành)
        - CapDonViId = 235 (đầu mối)
    */

    /*
        Nhóm XĂNG:
        CT2, CT3, CT4, CT5, CT6, CT7, CT18

        Nhóm DẦU:
        CT8, CT9, CT10
    */

    /*
        Tổng tồn:
        So_14

        Tổng nhập:
        So_02 -> So_07

        Tổng xuất:
        So_08 + So_10 + So_11 + So_12 + So_13 + So_24
    */

    -- Result set 1: Tồn kho

    SELECT
        N'XĂNG' AS Ten,
        N'm³' AS Dvt,
        ROUND(@TongTon_Xang, 0) AS GiaTri,
        @SoNgay_Xang AS SoNgay,
        N'xang' AS Type

    UNION ALL

    SELECT
        N'DẦU',
        N'tấn',
        ROUND(@TongTon_Dau, 0),
        @SoNgay_Dau,
        N'dau';

    -- Result set 2: Nhập xuất

    SELECT
        N'XĂNG' AS Ten,
        N'm³' AS Dvt,
        ROUND(@TongNhap_Xang, 0) AS Nhap,
        ROUND(@TongXuat_Xang, 0) AS Xuat

    UNION ALL

    SELECT
        N'DẦU',
        N'tấn',
        ROUND(@TongNhap_Dau, 0),
        ROUND(@TongXuat_Dau, 0);

    -- Result set 3: Cân đối

    SELECT
        N'XĂNG' AS Ten,
        N'm³' AS Dvt,
        ROUND(@TongNhap_Xang - @TongXuat_Xang, 0) AS GiaTri

    UNION ALL

    SELECT
        N'DẦU',
        N'tấn',
        ROUND(@TongNhap_Dau - @TongXuat_Dau, 0);

END
```
## Stored Procedure: sp_Dashboard_Home_PriceSummary

### 1. Mục đích

Thủ tục `sp_Dashboard_Home_PriceSummary` dùng để trả về dữ liệu biến động giá của các loại nhiên liệu xăng dầu phục vụ màn hình Dashboard/Home.

Thủ tục trả về 2 bảng dữ liệu:

1. Bảng giá nhiên liệu hiện tại.
2. Bảng danh sách giá của 7 lần thay đổi gần nhất.

Dữ liệu lấy từ báo cáo giá xăng dầu đã chốt:

- `QT_TK_ThongKe.Loai = 1`: dữ liệu chốt/chính thức.
- `QT_TK_ThongKe.TrangThai = 5`: báo cáo đã hoàn thành.
- `BaoCaoId = F115C290-543A-4E1B-8546-275A2CF8150E`.
- `ct.LoaiGia = 1`: loại giá bán.
- `ct.So_01 = 1`: dòng dữ liệu hợp lệ/đang áp dụng.
- Chỉ lấy dữ liệu có giá trị giá `So_04 > 0`.
- Chỉ lấy dữ liệu trong khoảng 3 tháng gần nhất.

Nguồn thủ tục: `sp_Dashboard_Home_PriceSummary`. :contentReference[oaicite:0]{index=0}

---

### 2. Tham số đầu vào

| Tham số | Kiểu dữ liệu | Mặc định | Mô tả |
|---|---|---|---|
| `@UserName` | `NVARCHAR(128)` | `NULL` | Tên đăng nhập người dùng, hiện chưa dùng để lọc dữ liệu |
| `@DonViId` | `NVARCHAR(50)` | `NULL` | Mã đơn vị, hiện phần lọc theo đơn vị đang được comment trong thủ tục |

---

### 3. Nguồn dữ liệu

Thủ tục lấy dữ liệu từ các bảng:

| Bảng | Mục đích |
|---|---|
| `QT_TK_ThongKe` | Bảng thông tin báo cáo thống kê |
| `QT_TK_ThongKeChiTiet` | Bảng chi tiết chỉ tiêu báo cáo |
| `TK_ChiTieuBaoCao` | Danh mục chỉ tiêu báo cáo, dùng để xác định loại nhiên liệu |

---

### 4. Nhóm chỉ tiêu nhiên liệu

| Mã chỉ tiêu | ProductKey | Tên hiển thị |
|---|---|---|
| `CT4` | `RON95` | `RON 95-III` |
| `CT6` | `E5RON92` | `E5 RON 92-II` |
| `CT9` | `DIESEL005S` | `DIESEL 0.05S` |

Giá bán được lấy từ cột:

```sql
ct.So_04
```

Thời điểm định giá được lấy theo quy tắc:

```sql
ISNULL(ct.ThoiDiemDinhGia, tk.TuNgay)
```

---

### 5. Dữ liệu trả về

Thủ tục trả về 2 bảng kết quả.

---

## 5.1. Bảng 1: Giá nhiên liệu hiện tại

Bảng này trả về giá bán hiện tại của từng loại nhiên liệu và phần trăm tăng/giảm so với kỳ giá liền trước.

| Cột | Mô tả |
|---|---|
| `Name` | Tên loại nhiên liệu, ví dụ: `RON 95-III`, `E5 RON 92-II`, `DIESEL 0.05S` |
| `Value` | Giá bán hiện tại |
| `Change` | Phần trăm tăng/giảm so với kỳ trước |
| `Class` | Class CSS dùng cho frontend |
| `Color` | Mã màu hiển thị trên frontend |

Ý nghĩa `Change`:

- `Change > 0`: giá tăng so với kỳ trước.
- `Change < 0`: giá giảm so với kỳ trước.
- `Change = 0`: giá không đổi hoặc không có dữ liệu kỳ trước để so sánh.

Công thức tính:

```sql
Change = (GiaHienTai - GiaKyTruoc) * 100.0 / GiaKyTruoc
```

Ví dụ dữ liệu trả về:

| Name | Value | Change |
|---|---:|---:|
| RON 95-III | 22000 | 1.25 |
| E5 RON 92-II | 21000 | -0.85 |
| DIESEL 0.05S | 19500 | 0.50 |

---

## 5.2. Bảng 2: Danh sách giá của 7 lần thay đổi gần nhất

Bảng này trả về dữ liệu giá của 7 kỳ định giá gần nhất để vẽ biểu đồ biến động giá.

| Cột | Mô tả |
|---|---|
| `Label` | Nhãn ngày định giá dạng `dd/MM`, dùng để hiển thị trên biểu đồ |
| `ThoiDiemDinhGia` | Ngày thay đổi/định giá |
| `Ron95` | Giá xăng RON 95 |
| `E5Ron92` | Giá xăng E5 RON 92 |
| `Diesel005S` | Giá dầu Diesel 0.05S |
| `NgayDinhGiaGanNhat` | Ngày định giá dạng `dd/MM/yyyy` |

Theo yêu cầu hiển thị frontend, có thể ánh xạ:

| Field frontend | Field từ thủ tục |
|---|---|
| `ThoiDiemDinhGia` | `ThoiDiemDinhGia` |
| `Ron95` | `Ron95` |
| `Ron92` | `E5Ron92` |
| `Diesel005S` | `Diesel005S` |

Lưu ý: trong thủ tục hiện tại tên cột trả về là `E5Ron92`, nếu frontend yêu cầu tên `Ron92` thì cần map ở DTO/API hoặc đổi alias trong SQL.

---

### 6. Logic xử lý chính

#### Bước 1: Lấy dữ liệu nguồn

Lấy dữ liệu giá trong 3 tháng gần nhất, chỉ lấy các mã chỉ tiêu `CT4`, `CT6`, `CT9`.

```sql
DECLARE @TuNgay DATE = DATEADD(MONTH, -3, GETDATE());
```

#### Bước 2: Chuẩn hóa mã nhiên liệu

```sql
CASE
    WHEN dm.MA = 'CT4' THEN 'RON95'
    WHEN dm.MA = 'CT6' THEN 'E5RON92'
    WHEN dm.MA = 'CT9' THEN 'DIESEL005S'
END AS ProductKey
```

#### Bước 3: Pivot dữ liệu

Chuyển dữ liệu từ dạng dòng sang dạng cột:

```sql
Ron95
E5Ron92
Diesel005S
```

#### Bước 4: Lấy 2 kỳ gần nhất

Dùng `ROW_NUMBER()` để xác định:

- `rn = 1`: kỳ giá hiện tại.
- `rn = 2`: kỳ giá trước đó.

#### Bước 5: Tính phần trăm tăng/giảm

```sql
Change = (CurPrice - PrevPrice) * 100.0 / PrevPrice
```

#### Bước 6: Lấy 7 kỳ gần nhất

Lấy `TOP 7` kỳ có đủ giá của cả 3 loại nhiên liệu:

```sql
WHERE Ron95 > 0
  AND E5Ron92 > 0
  AND Diesel005S > 0
```

---

### 7. Code thủ tục

```sql
CREATE PROCEDURE [dbo].[sp_Dashboard_Home_PriceSummary]
    @UserName NVARCHAR(128) = NULL,
    @DonViId NVARCHAR(50) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @BaoCaoId UNIQUEIDENTIFIER = 'F115C290-543A-4E1B-8546-275A2CF8150E';
    DECLARE @TuNgay DATE = DATEADD(MONTH, -3, GETDATE());

    --------------------------------------------------
    -- 1. SOURCE
    --------------------------------------------------
    ;WITH src AS
    (
        SELECT
            ISNULL(ct.ThoiDiemDinhGia, tk.TuNgay) AS ThoiDiemDinhGia,
            CASE
                WHEN dm.MA = 'CT4' THEN 'RON95'
                WHEN dm.MA = 'CT6' THEN 'E5RON92'
                WHEN dm.MA = 'CT9' THEN 'DIESEL005S'
            END AS ProductKey,
            ISNULL(ct.So_04, 0) AS GiaTri
        FROM QT_TK_ThongKe tk
        INNER JOIN QT_TK_ThongKeChiTiet ct
            ON tk.Id = ct.ThongKeId
        LEFT JOIN TK_ChiTieuBaoCao dm
            ON ct.ChiTieuThongKeId = dm.Id
        WHERE tk.BaoCaoId = @BaoCaoId
          AND tk.Loai = 1
          AND tk.TrangThai = 5
          AND dm.MA IN ('CT4', 'CT6', 'CT9')
          AND ct.LoaiGia = 1
          AND ct.So_01 = 1
          AND ISNULL(ct.ThoiDiemDinhGia, tk.TuNgay) >= @TuNgay
          AND ISNULL(ct.So_04, 0) > 0
          AND ISNULL(ct.ThoiDiemDinhGia, tk.TuNgay) <= GETDATE()

          -- Nếu cần lọc theo đơn vị thì mở lại điều kiện dưới:
          -- AND (
          --     @DonViId IS NULL
          --     OR @DonViId = ''
          --     OR CAST(tk.don_vi_cap1 AS NVARCHAR(50)) = @DonViId
          -- )
    )

    --------------------------------------------------
    -- 2. PIVOT DỮ LIỆU GIÁ
    --------------------------------------------------
    SELECT
        ThoiDiemDinhGia,
        MAX(CASE WHEN ProductKey = 'RON95'
                  AND GiaTri > 0 THEN GiaTri END) AS Ron95,
        MAX(CASE WHEN ProductKey = 'E5RON92'
                  AND GiaTri > 0 THEN GiaTri END) AS E5Ron92,
        MAX(CASE WHEN ProductKey = 'DIESEL005S'
                  AND GiaTri > 0 THEN GiaTri END) AS Diesel005S
    INTO #pivoted
    FROM src
    GROUP BY ThoiDiemDinhGia;

    --------------------------------------------------
    -- 3. LẤY 2 KỲ GẦN NHẤT ĐỂ SO SÁNH
    --------------------------------------------------
    ;WITH ranked AS
    (
        SELECT
            *,
            ROW_NUMBER() OVER (ORDER BY ThoiDiemDinhGia DESC) AS rn
        FROM #pivoted
        WHERE Ron95 > 0
          AND E5Ron92 > 0
          AND Diesel005S > 0
    )
    SELECT
        MAX(CASE WHEN rn = 1 THEN ThoiDiemDinhGia END) AS CurrentDate,
        MAX(CASE WHEN rn = 2 THEN ThoiDiemDinhGia END) AS PrevDate,

        MAX(CASE WHEN rn = 1 THEN Ron95 END) AS Cur_Ron95,
        MAX(CASE WHEN rn = 2 THEN Ron95 END) AS Prev_Ron95,

        MAX(CASE WHEN rn = 1 THEN E5Ron92 END) AS Cur_E5,
        MAX(CASE WHEN rn = 2 THEN E5Ron92 END) AS Prev_E5,

        MAX(CASE WHEN rn = 1 THEN Diesel005S END) AS Cur_Diesel,
        MAX(CASE WHEN rn = 2 THEN Diesel005S END) AS Prev_Diesel
    INTO #Compare
    FROM ranked;

    --------------------------------------------------
    -- 4. RESULT SET 1: GIÁ HIỆN TẠI
    --------------------------------------------------
    SELECT
        Name,
        Value,
        Change,
        Class,
        Color
    FROM
    (
        SELECT
            N'RON 95-III' AS Name,
            CAST(ISNULL(Cur_Ron95, 0) AS DECIMAL(18, 2)) AS Value,
            CAST(
                CASE
                    WHEN ISNULL(Prev_Ron95, 0) > 0
                    THEN (Cur_Ron95 - Prev_Ron95) * 100.0 / Prev_Ron95
                    ELSE 0
                END AS DECIMAL(18, 2)
            ) AS Change,
            N'fuel-blue' AS Class,
            N'#2563eb' AS Color
        FROM #Compare

        UNION ALL

        SELECT
            N'E5 RON 92-II',
            CAST(ISNULL(Cur_E5, 0) AS DECIMAL(18, 2)),
            CAST(
                CASE
                    WHEN ISNULL(Prev_E5, 0) > 0
                    THEN (Cur_E5 - Prev_E5) * 100.0 / Prev_E5
                    ELSE 0
                END AS DECIMAL(18, 2)
            ),
            N'fuel-green',
            N'#16a34a'
        FROM #Compare

        UNION ALL

        SELECT
            N'DIESEL 0.05S',
            CAST(ISNULL(Cur_Diesel, 0) AS DECIMAL(18, 2)),
            CAST(
                CASE
                    WHEN ISNULL(Prev_Diesel, 0) > 0
                    THEN (Cur_Diesel - Prev_Diesel) * 100.0 / Prev_Diesel
                    ELSE 0
                END AS DECIMAL(18, 2)
            ),
            N'fuel-purple',
            N'#9333ea'
        FROM #Compare
    ) t;

    --------------------------------------------------
    -- 5. RESULT SET 2: TIMELINE 7 KỲ GẦN NHẤT
    --------------------------------------------------
    SELECT
        *,
        CONVERT(NVARCHAR(50), ThoiDiemDinhGia, 103) AS NgayDinhGiaGanNhat
    FROM
    (
        SELECT TOP 7
            FORMAT(ThoiDiemDinhGia, 'dd/MM') AS Label,
            ThoiDiemDinhGia,
            CAST(Ron95 AS DECIMAL(18, 2)) AS Ron95,
            CAST(E5Ron92 AS DECIMAL(18, 2)) AS E5Ron92,
            CAST(Diesel005S AS DECIMAL(18, 2)) AS Diesel005S
        FROM #pivoted
        WHERE Ron95 > 0
          AND E5Ron92 > 0
          AND Diesel005S > 0
        ORDER BY ThoiDiemDinhGia DESC
    ) a
    ORDER BY ThoiDiemDinhGia ASC;

    --------------------------------------------------
    -- CLEANUP
    --------------------------------------------------
    DROP TABLE #Compare;
    DROP TABLE #pivoted;
END
```
## Stored Procedure: sp_Dashboard_FuelStabilizationFund

### 1. Mục đích

Thủ tục `sp_Dashboard_FuelStabilizationFund` dùng để lấy dữ liệu tồn quỹ bình ổn giá xăng dầu của các doanh nghiệp đầu mối phục vụ màn hình Dashboard.

Thủ tục trả về danh sách số dư quỹ bình ổn của từng doanh nghiệp đầu mối trong kỳ báo cáo gần nhất.

Dữ liệu được lấy từ báo cáo quỹ bình ổn xăng dầu đã chốt.

---

### 2. Tham số đầu vào

| Tham số | Kiểu dữ liệu | Mô tả |
|---|---|---|
| `@BaoCaoId` | `UNIQUEIDENTIFIER` | Id báo cáo quỹ bình ổn |
| `@Period` | `NVARCHAR(10)` | Loại kỳ báo cáo: `THANG`, `QUY`, `NAM` |
| `@Month` | `INT` | Tháng báo cáo |
| `@Quarter` | `INT` | Quý báo cáo |
| `@Year` | `INT` | Năm báo cáo |

Lưu ý:

Hiện tại thủ tục đang cố định lấy dữ liệu kỳ tháng gần nhất theo ngày hệ thống, phần lọc theo `@Period` đang được comment để mở rộng sau.

---

### 3. Quy tắc xác định kỳ dữ liệu

Thủ tục tự xác định kỳ dữ liệu gần nhất:

- Nếu ngày hiện tại `< 20`:
  - lấy dữ liệu cách hiện tại 2 tháng.
- Nếu ngày hiện tại `>= 20`:
  - lấy dữ liệu cách hiện tại 1 tháng.

Ví dụ:

| Ngày hiện tại | Kỳ dữ liệu lấy |
|---|---|
| 05/07/2026 | Tháng 05/2026 |
| 25/07/2026 | Tháng 06/2026 |

---

### 4. Nguồn dữ liệu

Thủ tục lấy dữ liệu từ các bảng:

| Bảng | Mục đích |
|---|---|
| `QT_TK_ThongKe` | Bảng báo cáo thống kê |
| `QT_TK_ThongKeChiTiet` | Bảng chi tiết báo cáo |
| `TK_ChiTieuBaoCao` | Danh mục chỉ tiêu báo cáo |
| `DM_DonVi` | Danh mục đơn vị đầu mối |

---

### 5. Điều kiện lọc dữ liệu

Dữ liệu được lọc theo:

| Điều kiện | Ý nghĩa |
|---|---|
| `tk.BaoCaoId = @BaoCaoId` | Báo cáo quỹ bình ổn |
| `tk.KieuKyBaoCao = 2` | Báo cáo tháng |
| `tk.ThangQuy = @Thang` | Tháng gần nhất |
| `tk.Nam = @Nam` | Năm gần nhất |
| `dm.MA = 'CT1'` | Chỉ tiêu tồn quỹ bình ổn |

---

### 6. Logic xử lý chính

#### Bước 1: Xác định kỳ báo cáo gần nhất

```sql
IF DAY(@NgayHienTai) < 20
BEGIN
    SET @NgayHienTai = DATEADD(MONTH, -2, @NgayHienTai);
END
ELSE
BEGIN
    SET @NgayHienTai = DATEADD(MONTH, -1, @NgayHienTai);
END
```

---

#### Bước 2: Tổng hợp tồn quỹ theo doanh nghiệp đầu mối

Giá trị tồn quỹ được lấy từ:

```sql
SUM(ISNULL(ct.So_08, 0))
```

Ý nghĩa:

| Trường | Ý nghĩa |
|---|---|
| `ct.So_08` | Giá trị tồn quỹ bình ổn tại đơn vị |

---

#### Bước 3: Lấy bản ghi mới nhất của từng đơn vị

Thủ tục sử dụng:

```sql
ROW_NUMBER() OVER (
    PARTITION BY tk.don_vi_cap1
    ORDER BY ISNULL(tk.Modified, tk.Created) DESC
)
```

Mục đích:

- Nếu một đơn vị có nhiều lần cập nhật báo cáo,
- hệ thống sẽ lấy bản ghi mới nhất.

---

### 7. Dữ liệu trả về

Thủ tục trả về 1 bảng dữ liệu gồm:

| Cột | Mô tả |
|---|---|
| `DonViId` | Id của đơn vị đầu mối |
| `TenDonVi` | Tên doanh nghiệp đầu mối |
| `SapXep` | Giá trị sắp xếp hiển thị |
| `TonQuy` | Số tiền tồn quỹ bình ổn tại đơn vị |

---

### 8. Ý nghĩa dữ liệu

| Trường | Ý nghĩa |
|---|---|
| `TonQuy > 0` | Quỹ bình ổn còn số dư |
| `TonQuy = 0` | Không còn tồn quỹ |
| `TonQuy < 0` | Âm quỹ bình ổn |

---

### 9. Ví dụ dữ liệu trả về

| DonViId | TenDonVi | SapXep | TonQuy |
|---|---|---:|---:|
| `A001` | Petrolimex | 1 | 1250000000 |
| `A002` | PV Oil | 2 | 870000000 |
| `A003` | Saigon Petro | 3 | -25000000 |

---

### 10. Code thủ tục

```sql
CREATE PROCEDURE [dbo].[sp_Dashboard_FuelStabilizationFund]
    @BaoCaoId UNIQUEIDENTIFIER,
    @Period NVARCHAR(10), -- THANG | QUY | NAM
    @Month INT,
    @Quarter INT,
    @Year INT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @NgayHienTai DATE = GETDATE();
    DECLARE @Thang INT;
    DECLARE @Nam INT;

    IF DAY(@NgayHienTai) < 20
    BEGIN
        SET @NgayHienTai = DATEADD(MONTH, -2, @NgayHienTai);
    END
    ELSE
    BEGIN
        SET @NgayHienTai = DATEADD(MONTH, -1, @NgayHienTai);
    END

    SET @Thang = MONTH(@NgayHienTai);
    SET @Nam = YEAR(@NgayHienTai);

    ;WITH base_data AS
    (
        SELECT
            tk.Id,
            tk.don_vi_cap1 AS DonViId,
            dv.Ten AS TenDonVi,
            dv.SapXep,

            SUM(ISNULL(ct.So_08, 0)) AS TonQuy,

            tk.Modified,
            tk.Created,

            ROW_NUMBER() OVER
            (
                PARTITION BY tk.don_vi_cap1
                ORDER BY ISNULL(tk.Modified, tk.Created) DESC,
                         tk.Created DESC
            ) AS rn

        FROM QT_TK_ThongKe tk

        INNER JOIN QT_TK_ThongKeChiTiet ct
            ON ct.ThongKeId = tk.Id

        INNER JOIN TK_ChiTieuBaoCao dm
            ON ct.ChiTieuThongKeId = dm.Id

        LEFT JOIN DM_DonVi dv
            ON dv.Id = tk.don_vi_cap1

        WHERE tk.BaoCaoId = @BaoCaoId

          AND tk.KieuKyBaoCao = 2
          AND tk.ThangQuy = @Thang
          AND tk.Nam = @Nam

          AND dm.MA = 'CT1'

          /*
          Có thể mở rộng lọc theo kỳ:

          AND (
                 (@Period = 'THANG'
                    AND tk.KieuKyBaoCao = 2
                    AND tk.ThangQuy = @Month
                    AND YEAR(tk.DenNgay) = @Year)

              OR (@Period = 'QUY'
                    AND tk.KieuKyBaoCao = 3
                    AND tk.ThangQuy = @Quarter
                    AND YEAR(tk.DenNgay) = @Year)

              OR (@Period = 'NAM'
                    AND tk.KieuKyBaoCao = 4
                    AND YEAR(tk.DenNgay) = @Year)
          )
          */

        GROUP BY
            tk.Id,
            tk.don_vi_cap1,
            dv.Ten,
            tk.Modified,
            tk.Created,
            dv.SapXep
    )

    SELECT
        DonViId,
        TenDonVi,
        SapXep,
        ROUND(TonQuy, 0) AS TonQuy
    FROM base_data
    WHERE rn = 1
    ORDER BY SapXep, TenDonVi;

END
```
## Stored Procedure: sp_Dashboard_Home_Bc05ImportByCountry

### 1. Mục đích

Thủ tục `sp_Dashboard_Home_Bc05ImportByCountry` dùng để lấy dữ liệu thống kê nhập khẩu nhiên liệu theo thị trường/quốc gia phục vụ Dashboard.

Thủ tục trả về dữ liệu cho biết các loại nhiên liệu:

- Xăng
- Dầu

được nhập khẩu từ quốc gia nào trong kỳ báo cáo.

Dữ liệu hỗ trợ:

- Dashboard nhập khẩu nhiên liệu.
- Biểu đồ phân tích thị trường nhập khẩu.
- Báo cáo phân tích nguồn cung nhiên liệu.

---

### 2. Ví dụ gọi thủ tục

```sql
EXEC sp_Dashboard_Home_Bc05ImportByCountry
    @BaoCaoId = '24BD5439-2CEB-4162-92D4-EBD165323475',
    @Period = N'THANG',
    @Thang = 3,
    @Nam = 2026,
    @KyBaoCao = NULL;
```

---

### 3. Tham số đầu vào

| Tham số | Kiểu dữ liệu | Mô tả |
|---|---|---|
| `@BaoCaoId` | `UNIQUEIDENTIFIER` | Id báo cáo nhập khẩu nhiên liệu |
| `@Period` | `NVARCHAR(10)` | Loại kỳ báo cáo: `THANG`, `QUY`, `NAM` |
| `@Thang` | `INT` | Tháng báo cáo |
| `@Nam` | `INT` | Năm báo cáo |
| `@KyBaoCao` | `INT` | Quý báo cáo nếu là kỳ quý |

---

### 4. Nguồn dữ liệu

Thủ tục lấy dữ liệu từ các bảng:

| Bảng | Mục đích |
|---|---|
| `QT_TK_ThongKe` | Bảng báo cáo thống kê |
| `QT_TK_ThongKeChiTiet` | Bảng chi tiết báo cáo |
| `TK_ChiTieuBaoCao` | Danh mục chỉ tiêu báo cáo |
| `DM_ThiTruong` | Danh mục quốc gia/thị trường nhập khẩu |

---

### 5. Điều kiện lọc dữ liệu

Dữ liệu được lọc theo:

| Điều kiện | Ý nghĩa |
|---|---|
| `tk.BaoCaoId = @BaoCaoId` | Báo cáo nhập khẩu |
| `tk.TrangThai = 5` | Báo cáo đã hoàn thành |
| `tk.Loai = 1` | Dữ liệu chốt/chính thức |
| `ct.Nhom = 1` | Dữ liệu nhóm nhập khẩu |
| `dm.Ma IN (...)` | Chỉ lấy các chỉ tiêu xăng dầu |

---

### 6. Phân loại nhiên liệu

#### Nhóm xăng

Các mã chỉ tiêu:

```sql
CT2
CT3
CT4
CT5
CT6
CT7
CT18
```

Được quy đổi thành:

```sql
xang
```

---

#### Nhóm dầu

Các mã chỉ tiêu:

```sql
CT8
CT9
CT10
```

Được quy đổi thành:

```sql
dau
```

---

### 7. Logic xác định kỳ báo cáo

#### Kỳ tháng

```sql
tk.KieuKyBaoCao = 2
```

Lọc theo:

```sql
tk.ThangQuy = @Thang
YEAR(tk.DenNgay) = @Nam
```

---

#### Kỳ quý

```sql
tk.KieuKyBaoCao = 3
```

Lọc theo:

```sql
tk.ThangQuy = @KyBaoCao
YEAR(tk.DenNgay) = @Nam
```

---

#### Kỳ năm

```sql
tk.KieuKyBaoCao = 4
```

Lọc theo:

```sql
YEAR(tk.DenNgay) = @Nam
```

---

### 8. Dữ liệu trả về

Thủ tục trả về 1 bảng dữ liệu.

| Cột | Mô tả |
|---|---|
| `LoaiNhienLieu` | Loại nhiên liệu: `xang`, `dau` |
| `Id` | Id thị trường/quốc gia |
| `TenNuoc` | Tên quốc gia nhập khẩu |
| `SoLuongThang` | Số lượng nhập trong kỳ |
| `SoLuongLuyKe` | Số lượng lũy kế |

---

### 9. Ý nghĩa dữ liệu

| Trường | Ý nghĩa |
|---|---|
| `LoaiNhienLieu = xang` | Dữ liệu nhập khẩu xăng |
| `LoaiNhienLieu = dau` | Dữ liệu nhập khẩu dầu |
| `TenNuoc` | Quốc gia cung cấp nhiên liệu |
| `SoLuongThang` | Tổng lượng nhập khẩu trong kỳ |
| `SoLuongLuyKe` | Tổng lượng nhập khẩu lũy kế |

---

### 10. Công thức tính toán

Giá trị nhập khẩu được lấy từ:

```sql
SUM(ISNULL(ct.So_01, 0))
```

Hiện tại:

```sql
SoLuongThang = SUM(ct.So_01)
SoLuongLuyKe = SUM(ct.So_01)
```

Lưu ý:

Trong thủ tục hiện tại:

- `SoLuongThang`
- `SoLuongLuyKe`

đang sử dụng cùng một công thức.

Có thể mở rộng sau để tính lũy kế thực tế theo nhiều kỳ.

---

### 11. Quy tắc sắp xếp dữ liệu

Dữ liệu được sắp xếp:

1. Các quốc gia có `Id` hợp lệ trước.
2. Theo `SoLuongLuyKe` giảm dần.

```sql
ORDER BY
    CASE WHEN tt.Id IS NOT NULL THEN 0 ELSE 1 END ASC,
    SoLuongLuyKe DESC
```

---

### 12. Ví dụ dữ liệu trả về

| LoaiNhienLieu | TenNuoc | SoLuongThang | SoLuongLuyKe |
|---|---|---:|---:|
| xang | Singapore | 125000 | 125000 |
| xang | Hàn Quốc | 95000 | 95000 |
| dau | Kuwait | 210000 | 210000 |
| dau | Malaysia | 185000 | 185000 |

---

### 13. Code thủ tục

```sql
CREATE PROCEDURE [dbo].[sp_Dashboard_Home_Bc05ImportByCountry]
    @BaoCaoId UNIQUEIDENTIFIER,
    @Period NVARCHAR(10),
    @Thang INT,
    @Nam INT,
    @KyBaoCao INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        CASE
            WHEN UPPER(ISNULL(dm.Ma, '')) IN
            (
                'CT2','CT3','CT4',
                'CT5','CT6','CT7','CT18'
            )
            THEN 'xang'

            WHEN UPPER(ISNULL(dm.Ma, '')) IN
            (
                'CT8','CT9','CT10'
            )
            THEN 'dau'

            ELSE ''
        END AS LoaiNhienLieu,

        tt.Id,

        ISNULL(tt.Ten, N'(Chưa xác định)') AS TenNuoc,

        SUM(ISNULL(ct.So_01, 0)) AS SoLuongThang,

        SUM(ISNULL(ct.So_01, 0)) AS SoLuongLuyKe

    FROM QT_TK_ThongKeChiTiet ct

    INNER JOIN QT_TK_ThongKe tk
        ON tk.Id = ct.ThongKeId

    INNER JOIN TK_ChiTieuBaoCao dm
        ON dm.Id = ct.ChiTieuThongKeId

    LEFT JOIN DM_ThiTruong tt
        ON tt.Id = ct.ThiTruongId

    WHERE tk.BaoCaoId = @BaoCaoId

      AND ct.Nhom = 1

      AND tk.TrangThai = 5

      AND tk.Loai = 1

      AND UPPER(ISNULL(dm.Ma, '')) IN
      (
          'CT2','CT3','CT4',
          'CT5','CT6','CT7','CT18',
          'CT8','CT9','CT10'
      )

      /*
      Có thể bật lại nếu muốn bắt buộc có thị trường:
      AND ct.ThiTruongId IS NOT NULL
      */

      AND
      (
            (
                @Period = 'QUY'
                AND tk.KieuKyBaoCao = 3
                AND tk.ThangQuy = @KyBaoCao
                AND YEAR(tk.DenNgay) = @Nam
            )

         OR (
                @Period = 'NAM'
                AND tk.KieuKyBaoCao = 4
                AND YEAR(tk.DenNgay) = @Nam
            )

         OR (
                @Period <> 'QUY'
                AND @Period <> 'NAM'
                AND tk.KieuKyBaoCao = 2
                AND tk.ThangQuy = @Thang
                AND YEAR(tk.DenNgay) = @Nam
            )
      )

    GROUP BY

        CASE
            WHEN UPPER(ISNULL(dm.Ma, '')) IN
            (
                'CT2','CT3','CT4',
                'CT5','CT6','CT7','CT18'
            )
            THEN 'xang'

            WHEN UPPER(ISNULL(dm.Ma, '')) IN
            (
                'CT8','CT9','CT10'
            )
            THEN 'dau'

            ELSE ''
        END,

        tt.Ten,
        tt.Id

    ORDER BY
        CASE WHEN tt.Id IS NOT NULL THEN 0 ELSE 1 END ASC,
        SoLuongLuyKe DESC;

END
```
## Stored Procedure: sp_Dashboard_Home_Bc05DomesticBySupplier

### 1. Mục đích

Thủ tục `sp_Dashboard_Home_Bc05DomesticBySupplier` dùng để lấy dữ liệu nhiên liệu nhập/mua từ các nhà máy sản xuất trong nước trong kỳ báo cáo.

Dữ liệu phục vụ Dashboard phân tích nguồn cung xăng dầu trong nước, cụ thể là sản lượng xăng/dầu lấy từ các nhà cung cấp nội địa như:

- Bình Sơn
- Nghi Sơn

---

### 2. Ví dụ gọi thủ tục

```sql
EXEC sp_Dashboard_Home_Bc05DomesticBySupplier
    @BaoCaoId = '24BD5439-2CEB-4162-92D4-EBD165323475',
    @Period = N'THANG',
    @Thang = 3,
    @Nam = 2026,
    @KyBaoCao = NULL;
```

---

### 3. Tham số đầu vào

| Tham số | Kiểu dữ liệu | Mô tả |
|---|---|---|
| `@BaoCaoId` | `UNIQUEIDENTIFIER` | Id báo cáo nguồn cung/nhiên liệu |
| `@Period` | `NVARCHAR(10)` | Loại kỳ báo cáo: `THANG`, `QUY`, `NAM` |
| `@Thang` | `INT` | Tháng báo cáo |
| `@Nam` | `INT` | Năm báo cáo |
| `@KyBaoCao` | `INT` | Quý báo cáo nếu `@Period = 'QUY'` |

---

### 4. Nguồn dữ liệu

Thủ tục lấy dữ liệu từ các bảng:

| Bảng | Mục đích |
|---|---|
| `QT_TK_ThongKe` | Bảng báo cáo thống kê |
| `QT_TK_ThongKeChiTiet` | Bảng chi tiết báo cáo |
| `TK_ChiTieuBaoCao` | Danh mục chỉ tiêu báo cáo |
| `DM_NhaCungCap` | Danh mục nhà cung cấp/nhà máy sản xuất trong nước |

---

### 5. Điều kiện lọc dữ liệu

Dữ liệu được lọc theo:

| Điều kiện | Ý nghĩa |
|---|---|
| `tk.BaoCaoId = @BaoCaoId` | Đúng báo cáo cần lấy dữ liệu |
| `ct.Nhom = 2` | Nhóm dữ liệu nhà cung cấp trong nước |
| `tk.Loai = 1` | Dữ liệu chốt/chính thức |
| `tk.TrangThai = 5` | Báo cáo đã hoàn thành |
| `ct.NhaCungCapId IS NOT NULL` | Chỉ lấy dữ liệu có nhà cung cấp |
| `ncc.Ten <> N'ĐẦU MỐI TRONG NƯỚC'` | Loại bỏ nhóm tổng hợp không phải nhà máy cụ thể |
| `ncc.Ten LIKE N'%bình sơn%' OR ncc.Ten LIKE N'%nghi sơn%'` | Chỉ lấy nhà máy Bình Sơn hoặc Nghi Sơn |

---

### 6. Phân loại nhiên liệu

#### Nhóm xăng

Các mã chỉ tiêu:

```sql
CT2
CT3
CT4
CT5
CT6
CT7
CT18
```

Được quy đổi thành:

```sql
xang
```

---

#### Nhóm dầu

Các mã chỉ tiêu:

```sql
CT8
CT9
CT10
```

Được quy đổi thành:

```sql
dau
```

---

### 7. Chuẩn hóa tên nhà cung cấp

Tên nhà cung cấp được chuẩn hóa để hiển thị thống nhất trên Dashboard.

```sql
CASE
    WHEN ncc.Ten LIKE N'%bình sơn%' THEN N'Bình Sơn'
    WHEN ncc.Ten LIKE N'%nghi sơn%' THEN N'Nghi Sơn'
    ELSE ncc.Ten
END
```

Ý nghĩa:

| Tên trong dữ liệu gốc | Tên hiển thị |
|---|---|
| Chứa `bình sơn` | `Bình Sơn` |
| Chứa `nghi sơn` | `Nghi Sơn` |
| Khác | Giữ nguyên tên gốc |

---

### 8. Logic xác định kỳ báo cáo

#### Kỳ tháng

```sql
tk.KieuKyBaoCao = 2
tk.ThangQuy = @Thang
YEAR(tk.DenNgay) = @Nam
```

#### Kỳ quý

```sql
tk.KieuKyBaoCao = 3
tk.ThangQuy = @KyBaoCao
YEAR(tk.DenNgay) = @Nam
```

#### Kỳ năm

```sql
tk.KieuKyBaoCao = 4
YEAR(tk.DenNgay) = @Nam
```

---

### 9. Dữ liệu trả về

Thủ tục trả về 1 bảng dữ liệu.

| Cột | Mô tả |
|---|---|
| `LoaiNhienLieu` | Loại nhiên liệu: `xang`, `dau` |
| `TenNCC` | Tên đơn vị/nhà máy sản xuất trong nước |
| `SoLuongLuyKe` | Số lượng nhiên liệu nhập/mua từ nhà cung cấp trong kỳ |

---

### 10. Ý nghĩa dữ liệu

| Trường | Ý nghĩa |
|---|---|
| `LoaiNhienLieu = xang` | Dữ liệu xăng từ nhà máy trong nước |
| `LoaiNhienLieu = dau` | Dữ liệu dầu từ nhà máy trong nước |
| `TenNCC = Bình Sơn` | Sản lượng lấy từ Nhà máy lọc dầu Bình Sơn |
| `TenNCC = Nghi Sơn` | Sản lượng lấy từ Nhà máy lọc dầu Nghi Sơn |
| `SoLuongLuyKe` | Tổng sản lượng trong kỳ báo cáo |

---

### 11. Công thức tính toán

Số lượng được tính bằng tổng giá trị cột `So_01`:

```sql
SoLuongLuyKe = SUM(ISNULL(ct.So_01, 0))
```

---

### 12. Quy tắc sắp xếp dữ liệu

Dữ liệu được sắp xếp theo số lượng giảm dần:

```sql
ORDER BY SoLuongLuyKe DESC
```

---

### 13. Ví dụ dữ liệu trả về

| LoaiNhienLieu | TenNCC | SoLuongLuyKe |
|---|---|---:|
| xang | Bình Sơn | 125000 |
| dau | Nghi Sơn | 98000 |
| xang | Nghi Sơn | 76000 |
| dau | Bình Sơn | 64000 |

---

### 14. Code thủ tục

```sql
CREATE PROCEDURE [dbo].[sp_Dashboard_Home_Bc05DomesticBySupplier]
    @BaoCaoId UNIQUEIDENTIFIER,
    @Period NVARCHAR(10),
    @Thang INT,
    @Nam INT,
    @KyBaoCao INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        CASE
            WHEN UPPER(ISNULL(dm.Ma, '')) IN
            (
                'CT2','CT3','CT4',
                'CT5','CT6','CT7','CT18'
            )
            THEN 'xang'

            WHEN UPPER(ISNULL(dm.Ma, '')) IN
            (
                'CT8','CT9','CT10'
            )
            THEN 'dau'

            ELSE ''
        END AS LoaiNhienLieu,

        ISNULL
        (
            CASE
                WHEN ncc.Ten LIKE N'%bình sơn%' THEN N'Bình Sơn'
                WHEN ncc.Ten LIKE N'%nghi sơn%' THEN N'Nghi Sơn'
                ELSE ncc.Ten
            END,
            N'(Chưa xác định)'
        ) AS TenNCC,

        SUM(ISNULL(ct.So_01, 0)) AS SoLuongLuyKe

    FROM QT_TK_ThongKeChiTiet ct

    INNER JOIN QT_TK_ThongKe tk
        ON tk.Id = ct.ThongKeId

    INNER JOIN TK_ChiTieuBaoCao dm
        ON dm.Id = ct.ChiTieuThongKeId

    LEFT JOIN DM_NhaCungCap ncc
        ON ncc.Id = ct.NhaCungCapId

    WHERE tk.BaoCaoId = @BaoCaoId

      AND ct.Nhom = 2

      AND tk.Loai = 1

      AND tk.TrangThai = 5

      AND UPPER(ISNULL(dm.Ma, '')) IN
      (
          'CT2','CT3','CT4',
          'CT5','CT6','CT7','CT18',
          'CT8','CT9','CT10'
      )

      AND ct.NhaCungCapId IS NOT NULL

      AND
      (
            (
                @Period = 'QUY'
                AND tk.KieuKyBaoCao = 3
                AND tk.ThangQuy = @KyBaoCao
                AND YEAR(tk.DenNgay) = @Nam
            )

         OR (
                @Period = 'NAM'
                AND tk.KieuKyBaoCao = 4
                AND YEAR(tk.DenNgay) = @Nam
            )

         OR (
                @Period <> 'QUY'
                AND @Period <> 'NAM'
                AND tk.KieuKyBaoCao = 2
                AND tk.ThangQuy = @Thang
                AND YEAR(tk.DenNgay) = @Nam
            )
      )

      AND ncc.Ten <> N'ĐẦU MỐI TRONG NƯỚC'

      AND
      (
          ncc.Ten LIKE N'%bình sơn%'
          OR ncc.Ten LIKE N'%nghi sơn%'
      )

    GROUP BY
        CASE
            WHEN UPPER(ISNULL(dm.Ma, '')) IN
            (
                'CT2','CT3','CT4',
                'CT5','CT6','CT7','CT18'
            )
            THEN 'xang'

            WHEN UPPER(ISNULL(dm.Ma, '')) IN
            (
                'CT8','CT9','CT10'
            )
            THEN 'dau'

            ELSE ''
        END,

        CASE
            WHEN ncc.Ten LIKE N'%bình sơn%' THEN N'Bình Sơn'
            WHEN ncc.Ten LIKE N'%nghi sơn%' THEN N'Nghi Sơn'
            ELSE ncc.Ten
        END

    ORDER BY SoLuongLuyKe DESC;

END
```
## Stored Procedure: sp_Dashboard_Home_RetailSummary

### 1. Mục đích

Thủ tục `sp_Dashboard_Home_RetailSummary` dùng để thống kê trạng thái hoạt động của các cửa hàng bán lẻ xăng dầu trên toàn hệ thống.

Dữ liệu phục vụ Dashboard tổng quan hệ thống bán lẻ xăng dầu.

Thủ tục trả về số lượng:

- Tổng số cửa hàng bán lẻ xăng dầu.
- Số cửa hàng đang hoạt động.
- Số cửa hàng tạm ngưng hoạt động.

---

### 2. Tham số đầu vào

Thủ tục không có tham số đầu vào.

```sql
EXEC sp_Dashboard_Home_RetailSummary
```

---

### 3. Nguồn dữ liệu

Thủ tục lấy dữ liệu từ bảng:

| Bảng | Mục đích |
|---|---|
| `DM_DonVi` | Danh mục đơn vị/cửa hàng xăng dầu |

---

### 4. Điều kiện lọc dữ liệu

Chỉ lấy dữ liệu các cửa hàng bán lẻ xăng dầu:

```sql
CapDonViId = 248
```

Ý nghĩa:

| CapDonViId | Loại đơn vị |
|---|---|
| `248` | Cửa hàng bán lẻ xăng dầu |

---

### 5. Logic xử lý

#### Tổng số cửa hàng

```sql
COUNT(1)
```

Đếm toàn bộ cửa hàng bán lẻ xăng dầu.

---

#### Số cửa hàng đang hoạt động

```sql
SUM(CASE WHEN TrangThai = 1 THEN 1 ELSE 0 END)
```

Ý nghĩa:

| Giá trị `TrangThai` | Trạng thái |
|---|---|
| `1` | Đang hoạt động |

---

#### Số cửa hàng tạm ngưng

```sql
SUM(
    CASE
        WHEN TrangThai = 0 OR TrangThai IS NULL
        THEN 1
        ELSE 0
    END
)
```

Ý nghĩa:

| Giá trị `TrangThai` | Trạng thái |
|---|---|
| `0` | Tạm ngưng |
| `NULL` | Chưa xác định trạng thái, mặc định tính là tạm ngưng |

---

### 6. Dữ liệu trả về

Thủ tục trả về 1 bảng dữ liệu gồm:

| Cột | Mô tả |
|---|---|
| `TongSo` | Tổng số cửa hàng xăng dầu (cửa hàng bán lẻ) |
| `DangHoatDong` | Số cửa hàng đang hoạt động |
| `TamNgung` | Số cửa hàng tạm ngưng hoạt động |

---

### 7. Ý nghĩa dữ liệu

| Trường | Ý nghĩa |
|---|---|
| `TongSo` | Tổng số cửa hàng bán lẻ xăng dầu |
| `DangHoatDong` | Các cửa hàng đang kinh doanh bình thường |
| `TamNgung` | Các cửa hàng ngừng hoạt động hoặc chưa cập nhật trạng thái |

---

### 8. Ví dụ dữ liệu trả về

| TongSo | DangHoatDong | TamNgung |
|---:|---:|---:|
| 17450 | 16820 | 630 |

---

### 9. Code thủ tục

```sql
CREATE PROCEDURE [dbo].[sp_Dashboard_Home_RetailSummary]
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        COUNT(1) AS TongSo,

        SUM
        (
            CASE
                WHEN TrangThai = 1
                THEN 1
                ELSE 0
            END
        ) AS DangHoatDong,

        SUM
        (
            CASE
                WHEN TrangThai = 0
                     OR TrangThai IS NULL
                THEN 1
                ELSE 0
            END
        ) AS TamNgung

    FROM DM_DonVi

    WHERE CapDonViId = 248;
END
```
## Stored Procedure: sp_Dashboard_Home_NationalInventoryDetailByUnit

### 1. Mục đích

Thủ tục `sp_Dashboard_Home_NationalInventoryDetailByUnit` dùng để trả về thông tin chi tiết tồn kho, nhập trong kỳ, xuất trong kỳ của các doanh nghiệp đầu mối xăng dầu.

Dữ liệu phục vụ màn hình Dashboard/Home khi người dùng cần xem chi tiết tồn kho xăng dầu theo từng doanh nghiệp đầu mối.

Thủ tục trả về dữ liệu theo kỳ báo cáo gần nhất, bao gồm:

- Tổng hợp tồn kho xăng/dầu toàn quốc.
- Tồn kho xăng/dầu theo từng đơn vị đầu mối.
- Chi tiết nhập - xuất - tồn của từng đơn vị đầu mối.

Dữ liệu mặc định lấy từ báo cáo đã chốt:

- `QT_TK_ThongKe.Loai = 1`: dữ liệu chốt/chính thức.
- `QT_TK_ThongKe.TrangThai = 5`: báo cáo đã hoàn thành.
- `DM_DonVi.CapDonViId = 235`: đơn vị đầu mối.
- `BaoCaoId = 70CDBFE1-9004-423B-88B0-3A9AD9711A78`.
- Không lấy các đơn vị có tên chứa `nhiên liệu bay`.

Nguồn thủ tục: `sp_Dashboard_Home_NationalInventoryDetailByUnit`. :contentReference[oaicite:0]{index=0}

---

### 2. Tham số đầu vào

| Tham số | Kiểu dữ liệu | Mặc định | Mô tả |
|---|---|---|---|
| `@UserName` | `NVARCHAR(128)` | `NULL` | Tên đăng nhập người dùng, hiện chưa dùng để lọc dữ liệu |
| `@DonViId` | `NVARCHAR(50)` | `NULL` | Mã đơn vị, hiện chưa dùng để lọc dữ liệu |
| `@Period` | `NVARCHAR(20)` | `N'THANG'` | Kỳ báo cáo, hiện thủ tục tự xác định kỳ tháng gần nhất |
| `@Month` | `INT` | `NULL` | Tháng báo cáo, hiện chưa dùng trực tiếp |
| `@Year` | `INT` | `NULL` | Năm báo cáo, hiện chưa dùng trực tiếp |

---

### 3. Quy tắc xác định kỳ dữ liệu

Thủ tục tự xác định kỳ báo cáo gần nhất theo ngày hệ thống:

- Nếu ngày hiện tại `< 20`: lấy dữ liệu kỳ cách hiện tại 2 tháng.
- Nếu ngày hiện tại `>= 20`: lấy dữ liệu kỳ cách hiện tại 1 tháng.

Sau đó thủ tục xác định thêm kỳ tháng trước để so sánh biến động tồn kho.

```sql
IF DAY(@NgayHienTai) < 20
    SET @NgayHienTai = DATEADD(MONTH, -2, @NgayHienTai);
ELSE
    SET @NgayHienTai = DATEADD(MONTH, -1, @NgayHienTai);
```

---

### 4. Nguồn dữ liệu

Thủ tục lấy dữ liệu từ các bảng:

| Bảng | Mục đích |
|---|---|
| `QT_TK_ThongKe` | Bảng báo cáo thống kê |
| `QT_TK_ThongKeChiTiet` | Bảng chi tiết báo cáo |
| `TK_ChiTieuBaoCao` | Danh mục chỉ tiêu báo cáo |
| `DM_DonVi` | Danh mục đơn vị đầu mối |

---

### 5. Điều kiện lọc dữ liệu

Dữ liệu kỳ hiện tại và kỳ trước được lọc theo:

| Điều kiện | Ý nghĩa |
|---|---|
| `dm.MAREPORT = '01'` | Báo cáo nhập xuất tồn |
| `tk.BaoCaoId = '70CDBFE1-9004-423B-88B0-3A9AD9711A78'` | Id báo cáo nhập xuất tồn xăng dầu |
| `tk.Loai = 1` | Dữ liệu chốt/chính thức |
| `tk.TrangThai = 5` | Báo cáo đã hoàn thành |
| `tk.KieuKyBaoCao = 2` | Báo cáo tháng |
| `dv.CapDonViId = 235` | Chỉ lấy doanh nghiệp đầu mối |
| `dv.Ten NOT LIKE N'%nhiên liệu bay%'` | Loại trừ đơn vị nhiên liệu bay |
| `tk.Nam = @Nam` | Năm báo cáo gần nhất |
| `tk.ThangQuy = @Thang` | Tháng báo cáo gần nhất |

---

### 6. Phân loại nhiên liệu

#### Nhóm xăng

Các mã chỉ tiêu:

```sql
CT2
CT3
CT4
CT5
CT6
CT7
CT18
```

Được tổng hợp thành nhóm xăng.

---

#### Nhóm dầu

Các mã chỉ tiêu:

```sql
CT8
CT9
CT10
```

Được tổng hợp thành nhóm dầu.

---

### 7. Công thức tính toán

#### Tồn đầu kỳ

```sql
TonDauKy = SUM(So_01)
```

#### Nhập trong kỳ

```sql
NhapTrongKy = SUM(
    So_02 + So_03 + So_04 +
    So_05 + So_06 + So_07
)
```

#### Xuất trong kỳ

```sql
XuatTrongKy = SUM(
    So_08 + So_10 + So_11 +
    So_12 + So_13 + So_24
)
```

#### Tồn cuối kỳ

```sql
TonCuoiKy = SUM(So_14)
```

#### Số ngày tồn/dự trữ

```sql
SoNgayTon = TonCuoiKy / ((TonDauKy + NhapTrongKy - TonCuoiKy) / SoNgayTrongThang)
```

Ý nghĩa:

- `TonDauKy + NhapTrongKy - TonCuoiKy` được xem là lượng xuất/tiêu thụ trong kỳ.
- Chia cho số ngày trong tháng để ra mức tiêu thụ bình quân ngày.
- Lấy tồn cuối kỳ chia cho mức tiêu thụ bình quân ngày để ra số ngày tồn/dự trữ.

---

### 8. Dữ liệu trả về

Thủ tục trả về 3 bảng dữ liệu.

---

## 8.1. Bảng 1: Tổng hợp tồn kho cả nước

Bảng này trả về thông tin tổng hợp tồn kho xăng dầu toàn quốc trong kỳ gần nhất.

| Cột | Mô tả |
|---|---|
| `SumXangCuoi` | Tổng tồn kho xăng cuối kỳ |
| `SumDauCuoi` | Tổng tồn kho dầu cuối kỳ |
| `TongTonCuoiGop` | Tổng tồn kho xăng + dầu cuối kỳ |
| `SoNgayTonXang` | Số ngày dự trữ của xăng |
| `SoNgayTonDau` | Số ngày dự trữ của dầu |
| `SoNgayTonTong` | Số ngày dự trữ gộp xăng và dầu |
| `DeltaPctXangVsThangTruoc` | Tỷ lệ % thay đổi tồn kho xăng so với tháng trước |
| `DeltaPctDauVsThangTruoc` | Tỷ lệ % thay đổi tồn kho dầu so với tháng trước |
| `AbsDeltaXangVsThangTruoc` | Chênh lệch tuyệt đối tồn kho xăng so với tháng trước |
| `AbsDeltaDauVsThangTruoc` | Chênh lệch tuyệt đối tồn kho dầu so với tháng trước |
| `DonViTonThap` | Số đơn vị có tồn kho thấp theo ngưỡng trong thủ tục |
| `DonViVuotMuc` | Số đơn vị có tồn kho vượt mức theo ngưỡng trong thủ tục |
| `ReportPeriodLabel` | Nhãn kỳ báo cáo, ví dụ: `Tháng 3/2026` |

Các trường chính cần dùng theo yêu cầu:

| Cột | Mô tả |
|---|---|
| `SumXangCuoi` | Tồn kho xăng |
| `SumDauCuoi` | Tồn kho dầu |
| `SoNgayTonXang` | Số ngày lượng tồn xăng đủ để cung ứng ra thị trường |
| `SoNgayTonDau` | Số ngày lượng tồn dầu đủ để cung ứng ra thị trường |

---

## 8.2. Bảng 2: Tồn kho xăng dầu theo đơn vị đầu mối

Bảng này chứa thông tin tồn kho xăng dầu của các đơn vị đầu mối ở kỳ mới nhất.

| Cột | Mô tả |
|---|---|
| `TenDonVi` | Tên đơn vị đầu mối |
| `TonCuoiKyXang` | Số tồn nhiên liệu xăng cuối kỳ |
| `TonCuoiKyDau` | Số tồn nhiên liệu dầu cuối kỳ |

Dữ liệu được sắp xếp theo:

```sql
ORDER BY SapXep
```

---

## 8.3. Bảng 3: Chi tiết nhập xuất tồn theo đơn vị đầu mối

Bảng này chứa chi tiết nhập - xuất - tồn trong kỳ mới nhất của từng đơn vị đầu mối.

| Cột | Mô tả |
|---|---|
| `TenDonVi` | Tên đơn vị đầu mối |
| `SapXep` | Thứ tự sắp xếp đơn vị |
| `TonDauKyXang` | Tồn đầu kỳ của xăng |
| `NhapTrongKyXang` | Nhập trong kỳ của xăng |
| `XuatTrongKyXang` | Xuất trong kỳ của xăng |
| `TonCuoiKyXang` | Tồn cuối kỳ của xăng |
| `TonDauKyDau` | Tồn đầu kỳ của dầu |
| `NhapTrongKyDau` | Nhập trong kỳ của dầu |
| `XuatTrongKyDau` | Xuất trong kỳ của dầu |
| `TonCuoiKyDau` | Tồn cuối kỳ của dầu |
| `SoNgayTonXang` | Số ngày dự trữ của xăng tại đơn vị |
| `SoNgayTonDau` | Số ngày dự trữ của dầu tại đơn vị |
| `SoNgayTonTong` | Số ngày dự trữ gộp xăng + dầu tại đơn vị |
| `SoVoiThangTruocPct` | Tỷ lệ % thay đổi tổng tồn kho so với tháng trước |

---

### 9. Ý nghĩa nghiệp vụ

| Nội dung | Ý nghĩa |
|---|---|
| Tồn kho cuối kỳ | Lượng nhiên liệu còn lại cuối kỳ báo cáo |
| Nhập trong kỳ | Tổng lượng nhiên liệu doanh nghiệp nhập/mua trong kỳ |
| Xuất trong kỳ | Tổng lượng nhiên liệu doanh nghiệp xuất/bán/cung ứng ra thị trường trong kỳ |
| Số ngày tồn | Số ngày lượng tồn hiện tại có thể đáp ứng nhu cầu cung ứng trung bình |
| Tỷ lệ so với tháng trước | Biến động tồn kho so với kỳ liền trước |

---

### 10. Code thủ tục

```sql
CREATE PROCEDURE [dbo].[sp_Dashboard_Home_NationalInventoryDetailByUnit]
    @UserName NVARCHAR(128) = NULL,
    @DonViId NVARCHAR(50) = NULL,
    @Period NVARCHAR(20) = N'THANG',
    @Month INT = NULL,
    @Year INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    ------------------------------------------------------------
    -- 1. XÁC ĐỊNH THÁNG
    ------------------------------------------------------------
    DECLARE @NgayHienTai DATE = GETDATE();
    DECLARE @Thang INT;
    DECLARE @Nam INT;
    DECLARE @ThangTruoc INT;
    DECLARE @NamTruoc INT;

    IF DAY(@NgayHienTai) < 20
        SET @NgayHienTai = DATEADD(MONTH, -2, @NgayHienTai);
    ELSE
        SET @NgayHienTai = DATEADD(MONTH, -1, @NgayHienTai);

    SET @Thang = MONTH(@NgayHienTai);
    SET @Nam = YEAR(@NgayHienTai);

    DECLARE @NgayThangTruoc DATE = DATEADD(MONTH, -1, @NgayHienTai);
    SET @ThangTruoc = MONTH(@NgayThangTruoc);
    SET @NamTruoc = YEAR(@NgayThangTruoc);

    DECLARE @SoNgayTrongThang INT = DAY(EOMONTH(@NgayHienTai));

    ------------------------------------------------------------
    -- 2. DATA HIỆN TẠI
    ------------------------------------------------------------
    SELECT 
        dv.Ten TenDonVi,
        dv.SapXep,
        dm.Ma,

        SUM(So_01) So_01,
        SUM(So_02) So_02,
        SUM(So_03) So_03,
        SUM(So_04) So_04,
        SUM(So_05) So_05,
        SUM(So_06) So_06,
        SUM(So_07) So_07,
        SUM(So_08) So_08,
        SUM(So_10) So_10,
        SUM(So_11) So_11,
        SUM(So_12) So_12,
        SUM(So_13) So_13,
        SUM(So_14) So_14,
        SUM(So_24) So_24
    INTO #DATA
    FROM QT_TK_ThongKeChiTiet ct
    JOIN QT_TK_ThongKe tk ON tk.Id = ct.ThongKeId
    JOIN TK_ChiTieuBaoCao dm ON ct.ChiTieuThongKeId = dm.Id
    JOIN DM_DonVi dv ON tk.don_vi_cap1 = dv.Id AND dv.CapDonViId = 235
    WHERE 
        dm.MAREPORT = '01'
        AND tk.BaoCaoId = '70CDBFE1-9004-423B-88B0-3A9AD9711A78'
        AND tk.Loai = 1
        AND tk.TrangThai = 5
        AND tk.KieuKyBaoCao = 2
        AND dv.Ten NOT LIKE N'%nhiên liệu bay%'
        AND tk.Nam = @Nam AND tk.ThangQuy = @Thang
    GROUP BY dv.Ten, dv.SapXep, dm.Ma;

    ------------------------------------------------------------
    -- 3. DATA THÁNG TRƯỚC
    ------------------------------------------------------------
    SELECT 
        dv.Ten TenDonVi,
        dm.Ma,
        SUM(So_14) So_14
    INTO #DATA_PREV
    FROM QT_TK_ThongKeChiTiet ct
    JOIN QT_TK_ThongKe tk ON tk.Id = ct.ThongKeId
    JOIN TK_ChiTieuBaoCao dm ON ct.ChiTieuThongKeId = dm.Id
    JOIN DM_DonVi dv ON tk.don_vi_cap1 = dv.Id AND dv.CapDonViId = 235
    WHERE 
        dm.MAREPORT = '01'
        AND tk.BaoCaoId = '70CDBFE1-9004-423B-88B0-3A9AD9711A78'
        AND tk.Loai = 1
        AND tk.TrangThai = 5
        AND tk.KieuKyBaoCao = 2
        AND dv.Ten NOT LIKE N'%nhiên liệu bay%'
        AND tk.Nam = @NamTruoc AND tk.ThangQuy = @ThangTruoc
    GROUP BY dv.Ten, dm.Ma;

    ------------------------------------------------------------
    -- 4. BUILD #D
    ------------------------------------------------------------
    SELECT 
        TenDonVi,
        SapXep,

        SUM(CASE WHEN Ma IN ('CT2','CT3','CT4','CT5','CT6','CT7','CT18') THEN So_01 ELSE 0 END) AS TonDauKyXang,
        SUM(CASE WHEN Ma IN ('CT2','CT3','CT4','CT5','CT6','CT7','CT18')
            THEN (ISNULL(So_02,0)+ISNULL(So_03,0)+ISNULL(So_04,0)+ISNULL(So_05,0)+ISNULL(So_06,0)+ISNULL(So_07,0)) ELSE 0 END) AS NhapTrongKyXang,
        SUM(CASE WHEN Ma IN ('CT2','CT3','CT4','CT5','CT6','CT7','CT18')
            THEN (ISNULL(So_08,0)+ISNULL(So_10,0)+ISNULL(So_11,0)+ISNULL(So_12,0)+ISNULL(So_13,0)+ISNULL(So_24,0)) ELSE 0 END) AS XuatTrongKyXang,
        SUM(CASE WHEN Ma IN ('CT2','CT3','CT4','CT5','CT6','CT7','CT18') THEN So_14 ELSE 0 END) AS TonCuoiKyXang,

        SUM(CASE WHEN Ma IN ('CT8','CT9','CT10') THEN So_01 ELSE 0 END) AS TonDauKyDau,
        SUM(CASE WHEN Ma IN ('CT8','CT9','CT10')
            THEN (ISNULL(So_02,0)+ISNULL(So_03,0)+ISNULL(So_04,0)+ISNULL(So_05,0)+ISNULL(So_06,0)+ISNULL(So_07,0)) ELSE 0 END) AS NhapTrongKyDau,
        SUM(CASE WHEN Ma IN ('CT8','CT9','CT10')
            THEN (ISNULL(So_08,0)+ISNULL(So_10,0)+ISNULL(So_11,0)+ISNULL(So_12,0)+ISNULL(So_13,0)+ISNULL(So_24,0)) ELSE 0 END) AS XuatTrongKyDau,
        SUM(CASE WHEN Ma IN ('CT8','CT9','CT10') THEN So_14 ELSE 0 END) AS TonCuoiKyDau
    INTO #D
    FROM #DATA
    GROUP BY TenDonVi, SapXep;

    ------------------------------------------------------------
    -- 5. BUILD #D_PREV
    ------------------------------------------------------------
    SELECT 
        TenDonVi,
        SUM(CASE WHEN Ma IN ('CT2','CT3','CT4','CT5','CT6','CT7','CT18') THEN So_14 ELSE 0 END) AS XangPrev,
        SUM(CASE WHEN Ma IN ('CT8','CT9','CT10') THEN So_14 ELSE 0 END) AS DauPrev
    INTO #D_PREV
    FROM #DATA_PREV
    GROUP BY TenDonVi;

    ------------------------------------------------------------
    -- 6. KPI
    ------------------------------------------------------------
    SELECT 
        a.SumXangCuoi,
        a.SumDauCuoi,
        a.SumXangCuoi + a.SumDauCuoi AS TongTonCuoiGop,

        CASE 
            WHEN (a.SumXangDau + a.SumNhapXang - a.SumXangCuoi) = 0 THEN 0
            ELSE ROUND(
                a.SumXangCuoi 
                / (
                    (a.SumXangDau + a.SumNhapXang - a.SumXangCuoi) * 1.0 
                    / @SoNgayTrongThang
                )
            ,1)
        END AS SoNgayTonXang,

        CASE 
            WHEN (a.SumDauDau + a.SumNhapDau - a.SumDauCuoi) = 0 THEN 0
            ELSE ROUND(
                a.SumDauCuoi 
                / (
                    (a.SumDauDau + a.SumNhapDau - a.SumDauCuoi) * 1.0 
                    / @SoNgayTrongThang
                )
            ,1)
        END AS SoNgayTonDau,

        CASE 
            WHEN (a.SumXangDau + a.SumNhapXang - a.SumXangCuoi 
                + a.SumDauDau + a.SumNhapDau - a.SumDauCuoi) = 0 THEN 0
            ELSE ROUND(
                (a.SumXangCuoi + a.SumDauCuoi)
                / (
                    (a.SumXangDau + a.SumNhapXang - a.SumXangCuoi 
                    + a.SumDauDau + a.SumNhapDau - a.SumDauCuoi) * 1.0 
                    / @SoNgayTrongThang
                )
            ,1)
        END AS SoNgayTonTong,

        CASE WHEN ISNULL(b.SumXangPrev,0)=0 THEN 0
            ELSE ROUND((a.SumXangCuoi - b.SumXangPrev)*100.0 / b.SumXangPrev,2)
        END AS DeltaPctXangVsThangTruoc,

        CASE WHEN ISNULL(b.SumDauPrev,0)=0 THEN 0
            ELSE ROUND((a.SumDauCuoi - b.SumDauPrev)*100.0 / b.SumDauPrev,2)
        END AS DeltaPctDauVsThangTruoc,

        a.SumXangCuoi - ISNULL(b.SumXangPrev,0) AS AbsDeltaXangVsThangTruoc,
        a.SumDauCuoi - ISNULL(b.SumDauPrev,0) AS AbsDeltaDauVsThangTruoc,

        a.DonViTonThap,
        a.DonViVuotMuc,

        N'Tháng ' + CAST(@Thang AS NVARCHAR) + '/' + CAST(@Nam AS NVARCHAR) AS ReportPeriodLabel

    FROM (
        SELECT
            SUM(TonCuoiKyXang) AS SumXangCuoi,
            SUM(TonCuoiKyDau) AS SumDauCuoi,
            SUM(TonDauKyXang) AS SumXangDau,
            SUM(TonDauKyDau) AS SumDauDau,
            SUM(NhapTrongKyXang) AS SumNhapXang,
            SUM(NhapTrongKyDau) AS SumNhapDau,

            SUM(CASE WHEN TonCuoiKyXang < 200000 OR TonCuoiKyDau < 120000 THEN 1 ELSE 0 END) AS DonViTonThap,
            SUM(CASE WHEN TonCuoiKyXang > 270000 OR TonCuoiKyDau > 190000 THEN 1 ELSE 0 END) AS DonViVuotMuc
        FROM #D
    ) a
    LEFT JOIN (
        SELECT SUM(XangPrev) AS SumXangPrev, SUM(DauPrev) AS SumDauPrev
        FROM #D_PREV
    ) b ON 1=1;

    ------------------------------------------------------------
    -- 7. BIỂU ĐỒ
    ------------------------------------------------------------
    SELECT TenDonVi, TonCuoiKyXang, TonCuoiKyDau
    FROM #D
    ORDER BY SapXep;

    ------------------------------------------------------------
    -- 8. CHI TIẾT
    ------------------------------------------------------------
    SELECT 
        d.*,

        CASE 
            WHEN (d.TonDauKyXang + d.NhapTrongKyXang - d.TonCuoiKyXang) = 0 THEN 0
            ELSE ROUND(
                d.TonCuoiKyXang 
                / (
                    (d.TonDauKyXang + d.NhapTrongKyXang - d.TonCuoiKyXang) * 1.0 
                    / @SoNgayTrongThang
                )
            ,1)
        END AS SoNgayTonXang,

        CASE 
            WHEN (d.TonDauKyDau + d.NhapTrongKyDau - d.TonCuoiKyDau) = 0 THEN 0
            ELSE ROUND(
                d.TonCuoiKyDau 
                / (
                    (d.TonDauKyDau + d.NhapTrongKyDau - d.TonCuoiKyDau) * 1.0 
                    / @SoNgayTrongThang
                )
            ,1)
        END AS SoNgayTonDau,

        CASE 
            WHEN (d.TonDauKyXang + d.NhapTrongKyXang - d.TonCuoiKyXang 
                + d.TonDauKyDau + d.NhapTrongKyDau - d.TonCuoiKyDau) = 0 THEN 0
            ELSE ROUND(
                (d.TonCuoiKyXang + d.TonCuoiKyDau)
                / (
                    (d.TonDauKyXang + d.NhapTrongKyXang - d.TonCuoiKyXang 
                    + d.TonDauKyDau + d.NhapTrongKyDau - d.TonCuoiKyDau) * 1.0 
                    / @SoNgayTrongThang
                )
            ,1)
        END AS SoNgayTonTong,

        CASE 
            WHEN ISNULL(p.XangPrev + p.DauPrev, 0) = 0 THEN 0
            ELSE ROUND(
                ( (d.TonCuoiKyXang + d.TonCuoiKyDau) 
                - (ISNULL(p.XangPrev,0) + ISNULL(p.DauPrev,0)) )
                * 100.0 / NULLIF((ISNULL(p.XangPrev,0) + ISNULL(p.DauPrev,0)),0)
            ,2)
        END AS SoVoiThangTruocPct

    FROM #D d
    LEFT JOIN #D_PREV p 
        ON d.TenDonVi = p.TenDonVi

    ORDER BY (d.TonCuoiKyXang + d.TonCuoiKyDau) DESC;

END
```

---

## AI Phase 5 Schema (Schema-Aware Constrained Query Generation)

> Cập nhật 2026-05-08 — Phase 5A. Tham khảo chi tiết tại [`/docs/loca-ai-phase5.md`](../loca-ai-phase5.md).

Phase 5 cho phép LLM tự sinh truy vấn cho câu hỏi UNKNOWN của lãnh đạo, thông qua **JSON plan có cấu trúc** (KHÔNG phải SQL string) đi qua 7 lớp safety. Phase 5A đặt nền tảng database: 11 bảng metadata, 8 view AI, user `ai_readonly`, 6 trigger.

### 1. 11 bảng metadata `Ai*`

#### Catalog & Semantic (6 bảng — admin edit, log audit)

| Bảng | Mục đích |
|---|---|
| `AiSchemaCatalog` | Đăng ký entity AI được phép truy vấn (entityCode, baseView, allowedColumns/Filters/Aggregates JSON, sampleQuestions cho RAG, sensitivityLevel). |
| `AiSemanticMapping` | Dịch cột vật lý (`So_01..So_25`) sang ý nghĩa nghiệp vụ theo `BaoCaoId`. Cùng `So_04` có thể là Giá bán ở báo cáo giá hoặc Số lượng nhập ở báo cáo nguồn cung — khoá định danh ngữ nghĩa là `BaoCaoId`, không phải `MAREPORT`. |
| `AiBaoCaoConstants` | Quản lý tập trung 4 `BaoCaoId` cố định: `NhapXuatTon`, `GiaBan`, `NhapKhauNguonCung`, `QuyBinhOn`. Đã seed bởi migration `SeedAiPhase5BaoCaoConstants`. |
| `AiIndicatorGroup` | Gom nhóm chỉ tiêu (`TK_ChiTieuBaoCao.Ma`) thành nhóm nghiệp vụ: `fuel_gasoline` (CT2..CT7, CT18), `fuel_diesel` (CT8..CT10), `price_ron95` (CT4), v.v. (Phase 5B sẽ seed.) |
| `AiFuelCodeMapping` | Cross-mapping `Ma` (đầu mối) ↔ `FuelProducts.Code` (cửa hàng) cho câu hỏi cross-layer. |
| `AiUnitConversion` | Quy đổi đơn vị giữa 2 lớp: m³↔lít cho xăng, tấn↔lít cho dầu. |

#### Operations & Logs (6 bảng — runtime ghi)

| Bảng | Mục đích |
|---|---|
| `AiCandidateIntents` | Câu hỏi UNKNOWN đã giải quyết — fingerprint SHA256, usageCount, status (pending/approved/rejected/promoted). Self-improving loop ở Phase 5G. |
| `AiDynamicQueryLogs` | Log mọi dynamic query: PlanJson, GeneratedSql, SqlParameters, RowsReturned, DurationMs, Status, **ConfidenceScore** (DECIMAL 3,2). |
| `AiDataVersion` | Cache invalidation key — Version BIGINT bump bởi trigger khi nguồn dữ liệu đổi. 7 BaoCaoCode đã seed: 4 head office + 3 retail station. |
| `AiReindexQueue` | Queue cho worker Python (Phase 5D) reindex Qdrant khi `AiSchemaCatalog` thay đổi. Status: pending/processing/done/failed. |
| `AiAdminAuditLogs` | Audit mọi thay đổi metadata bởi admin (Action: create_entity, update_entity, promote_intent, ...). |
| `AiRateLimit` | Rate limit theo user × queryType (fixed_intent / dynamic) × WindowStart. |

### 2. 8 view AI

Tất cả view chỉ trả dữ liệu chốt (`Loai=1, TrangThai=5` cho lớp đầu mối) và lọc theo `BaoCaoId` cụ thể. AI chỉ được SELECT trên view, KHÔNG truy cập bảng gốc.

| View | Filter chuẩn | Cột nghiệp vụ chính |
|---|---|---|
| `vw_AiHeadOfficeInventory` | BaoCaoId NhapXuatTon + MAREPORT='01' + KieuKyBaoCao=2 + CapDonViId=235 + loại "nhiên liệu bay" | `TonDauKy=So_01`, `NhapTrongKy=So_05+So_06+So_07`, `XuatTrongKy=So_11+So_12+So_13+So_24`, `TonCuoiKy=So_14`. KHÔNG expose So_02..So_25 thô. |
| `vw_AiHeadOfficePrice` | BaoCaoId GiaBan + LoaiGia=1 + So_01=1 + So_04>0 + Ma IN (CT4, CT6, CT9) | `GiaBan=So_04`, `ProductCode` (RON95/E5RON92/DIESEL005S) |
| `vw_AiHeadOfficeFundBalance` | BaoCaoId QuyBinhOn + KieuKyBaoCao=2 + Ma='CT1' + ROW_NUMBER lấy bản mới nhất per (đơn vị, kỳ) | `TonQuyBinhOn=SUM(So_08)` |
| `vw_AiHeadOfficeImport` | BaoCaoId NhapKhauNguonCung + Nhom=1 + JOIN DM_ThiTruong | `SoLuong=So_01`, `ThiTruongTen` (Singapore, Hàn Quốc, ...) |
| `vw_AiHeadOfficeDomesticSupply` | BaoCaoId NhapKhauNguonCung + Nhom=2 + NhaCungCapId NOT NULL + loại "ĐẦU MỐI TRONG NƯỚC" | `SoLuong=So_01`, `NhaCungCapTen` chuẩn hoá Bình Sơn / Nghi Sơn |
| `vw_AiStationPrice` | StationPrices ⨝ StationProductPrices ⨝ DM_DonVi (CapDonViId=248) ⨝ FuelProducts | `Price`, `EffectiveDate`, `IsActive` |
| `vw_AiStationInventory` | StationInventoryTransactionHeaders ⨝ Details ⨝ DM_DonVi (CapDonViId=248) | `TransactionType` (1=nhập, -1=xuất), `Quantity`, `Amount` |
| `vw_AiStationRating` | StationRatings ⨝ DM_DonVi (CapDonViId=248) + IsDeleted=0 | `Rating` (1-5). **KHÔNG expose Comment** (PII level 3). |

### 3. User `ai_readonly` & DENY rules

User database riêng cho AI Gateway (Phase 5C+). Setup thủ công bởi DBA qua [`scripts/sql/setup_ai_readonly.sql`](../../scripts/sql/setup_ai_readonly.sql) (KHÔNG đưa vào EF migration vì password không commit).

- **GRANT SELECT**: 8 view AI + 6 lookup table (`DM_Tinh`, `DM_XaPhuong`, `DM_ThiTruong`, `DM_NhaCungCap`, `FuelProducts`, `DM_DonViTinh`).
- **DENY toàn DB**: `INSERT`, `UPDATE`, `DELETE`, `ALTER`, `EXECUTE`, `REFERENCES`.
- **DENY SELECT bảng gốc nhạy cảm**: `DM_DonVi`, `QT_TK_ThongKe`, `QT_TK_ThongKeChiTiet`, `QT_TK_ThongKeChiTiet02`, `AspNetUsers/Claims/Logins/Roles`, `AspNetRoles`, `StationRatings`, `StationRatingImages`, `UserVehicles`, `FuelTransactions`, `UserDataDeletionRequests`, `PasswordResetTokens`.
- Verify bằng [`scripts/sql/test_ai_readonly.sql`](../../scripts/sql/test_ai_readonly.sql).

### 4. Trigger

#### 4.1 Cache invalidation (5 trigger — Section 10A.3)

Khi nguồn dữ liệu đổi → bump `AiDataVersion.Version + 1` → cache key cũ trong Redis tự động không hit.

| Trigger | Bảng nguồn | BaoCaoCode bump |
|---|---|---|
| `TR_QT_TK_ThongKe_AfterUpdate` | `QT_TK_ThongKe` AFTER UPDATE | Map `BaoCaoId → BaoCaoCode` qua `AiBaoCaoConstants`; chỉ bump khi `TrangThai → 5` (báo cáo chuyển sang chốt) |
| `TR_StationPrices_AfterUpsert` | `StationPrices` AFTER INSERT, UPDATE | `StationPrice` |
| `TR_StationProductPrices_AfterUpsert` | `StationProductPrices` AFTER INSERT, UPDATE | `StationPrice` |
| `TR_StationInventoryTransactionHeaders_AfterUpsert` | `StationInventoryTransactionHeaders` AFTER INSERT, UPDATE | `StationInventory` |
| `TR_StationRatings_AfterUpsert` | `StationRatings` AFTER INSERT, UPDATE | `StationRating` |

#### 4.2 Re-index Qdrant (1 trigger — Section 13A.3)

| Trigger | Hành vi |
|---|---|
| `TR_AiSchemaCatalog_AfterUpsert` | INSERT vào `AiReindexQueue (EntityCode, RequestedAt, Status='pending')` cho mỗi entity vừa thay đổi. Worker Python (Phase 5D) poll mỗi 30s để embed lại schema vào Qdrant. |

### 5. Migrations đã tạo

Trong [`backend/src/Httm.XangDau.Api/Shared/Persistence/Migrations/`](../../backend/src/Httm.XangDau.Api/Shared/Persistence/Migrations/):

| Timestamp | Migration | Mô tả |
|---|---|---|
| `20260508120000` | `AddAiPhase5Tables` | 11 bảng `Ai*` + index (idempotent) |
| `20260508120100` | `SeedAiPhase5BaoCaoConstants` | MERGE seed 4 BaoCao + 7 DataVersion |
| `20260508120200` | `AddAiPhase5Views` | 8 view `vw_Ai*` (CREATE OR ALTER) |
| `20260508120300` | `AddAiCacheInvalidationTriggers` | 5 trigger bump `AiDataVersion` |
| `20260508120400` | `AddAiSchemaCatalogReindexTrigger` | 1 trigger enqueue Qdrant re-index |

Setup user database: chạy thủ công [`scripts/sql/setup_ai_readonly.sql`](../../scripts/sql/setup_ai_readonly.sql) sau khi 5 migration đã apply.
