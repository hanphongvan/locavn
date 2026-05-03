# Field mapping: SQL Server → proposed API DTOs

<!-- TODO(domain-split): Bảng mapping gồm cả trạm xăng (Fuel) và báo cáo thống kê (dùng chung HTTM); chưa tách file theo domain — ưu tiên giữ một nguồn cho đến khi product phân ranh giới API. -->

**Sources:** `docs/architecture/database.md`, `docs/architecture/schema-analysis.md`.

**Rules used here:** Every **database** table and column name matches the schema document. **Proposed DTO** names are API-facing PascalCase suggestions; they are not SQL columns. Where the schema provides no backing column, the row is marked **—** and called out as a **gap** or non-persisted request/response only.

Joins are described in **Notes** using exact column names (for example `DM_DonVi.Tinh` → `DM_Tinh.Id`).

---

## 1. Station summary for map

**Proposed DTO:** `StationMapSummaryDto` (one row per station-like `DM_DonVi`; alternative depot-centric slice could use `TK_QuanLyKhoXangDau` — not duplicated below).

| Table name | Database column | Proposed DTO field name | Notes / transformation rule |
|------------|-----------------|-------------------------|-------------------------------|
| `DM_DonVi` | `Id` | `DonViId` | Direct map; use as stable map/list identifier. |
| `DM_DonVi` | `Ma` | `Ma` | Direct map. |
| `DM_DonVi` | `Ten` | `Ten` | Direct map (display name). |
| `DM_DonVi` | `DiaChi` | `DiaChi` | Direct map. |
| `DM_DonVi` | `DiaChiChiTiet` | `DiaChiChiTiet` | Direct map. |
| `DM_DonVi` | `Tinh` | `TinhId` | Direct map; optional join: `DM_DonVi.Tinh` = `DM_Tinh.Id`. |
| `DM_DonVi` | `Xa` | `XaPhuongId` | Direct map; optional join: `DM_DonVi.Xa` = `DM_XaPhuong.Id`. |
| `DM_Tinh` | `Ten` | `TinhTen` | **Transformation:** left join when `DM_DonVi.Tinh` = `DM_Tinh.Id`; omit if join not performed. |
| `DM_XaPhuong` | `Ten` | `XaPhuongTen` | **Transformation:** left join when `DM_DonVi.Xa` = `DM_XaPhuong.Id`. |
| `DM_DonVi` | `TrangThai` | `TrangThai` | Direct map (`bit?`). |
| `DM_DonVi` | `VungMien` | `VungMien` | Direct map. |
| `DM_DonVi` | `PhanLoaiId` | `PhanLoaiId` | Direct map; semantics not in schema doc. |
| `DM_DonVi` | `LoaiHinh` | `LoaiHinh` | Direct map; semantics not in schema doc. |
| — | — | `Latitude` | **Gap:** no latitude column in `docs/architecture/database.md`. Do not fabricate; supply only from an approved non-documented source or omit. |
| — | — | `Longitude` | **Gap:** no longitude column in `docs/architecture/database.md`. Same as `Latitude`. |

---

## 2. Station detail

**Proposed DTO:** `StationDetailDto` (core unit = `DM_DonVi`; nested collections can use separate DTOs for child tables).

### 2.1 Organization unit

| Table name | Database column | Proposed DTO field name | Notes / transformation rule |
|------------|-----------------|-------------------------|-------------------------------|
| `DM_DonVi` | `Id` | `Id` | Direct map. |
| `DM_DonVi` | `Ma` | `Ma` | Direct map. |
| `DM_DonVi` | `Ten` | `Ten` | Direct map. |
| `DM_DonVi` | `TenTiengNuocNgoai` | `TenTiengNuocNgoai` | Direct map. |
| `DM_DonVi` | `DienThoai` | `DienThoai` | Direct map. |
| `DM_DonVi` | `DiaChi` | `DiaChi` | Direct map. |
| `DM_DonVi` | `Email` | `Email` | Direct map. |
| `DM_DonVi` | `Tinh` | `Tinh` | Direct map (int key). |
| `DM_DonVi` | `Xa` | `Xa` | Direct map (int key). |
| `DM_DonVi` | `DiaChiChiTiet` | `DiaChiChiTiet` | Direct map. |
| `DM_DonVi` | `CapTrenId` | `CapTrenId` | Direct map. |
| `DM_DonVi` | `Cap` | `Cap` | Direct map. |
| `DM_DonVi` | `ThuocDonViId` | `ThuocDonViId` | Direct map. |
| `DM_DonVi` | `TrangThai` | `TrangThai` | Direct map. |
| `DM_DonVi` | `VungMien` | `VungMien` | Direct map. |
| `DM_DonVi` | `PhanLoaiId` | `PhanLoaiId` | Direct map. |
| `DM_DonVi` | `LoaiHinh` | `LoaiHinh` | Direct map. |
| `DM_DonVi` | `SoGiayPhep` | `SoGiayPhep` | Direct map (on-unit license text). |
| `DM_DonVi` | `NgayCap` | `NgayCap` | Direct map (`datetime?`). |
| `DM_DonVi` | `NgayHetHan` | `NgayHetHan` | Direct map (`datetime?`). |
| `DM_DonVi` | `NoiCapId` | `NoiCapId` | Direct map; target `DM_NoiCapGiayPhep` not in 27-table doc. |
| `DM_Tinh` | `Ten` | `TinhTen` | Join `DM_DonVi.Tinh` = `DM_Tinh.Id`. |
| `DM_XaPhuong` | `Ten` | `XaPhuongTen` | Join `DM_DonVi.Xa` = `DM_XaPhuong.Id`. |
| `DM_XaPhuong` | `QuanHuyenId` | `QuanHuyenId` | Expose as opaque id; **no** `DM_QuanHuyen` columns in `docs/architecture/database.md`. |
| — | — | `Latitude` / `Longitude` | **Gap:** no coordinate columns in documented schema. |

### 2.2 Licenses (`TK_QuanLyGiayPhep`) — collection `Licenses[]`

| Table name | Database column | Proposed DTO field name | Notes / transformation rule |
|------------|-----------------|-------------------------|-------------------------------|
| `TK_QuanLyGiayPhep` | `Id` | `Id` | Direct map (`uniqueidentifier`). |
| `TK_QuanLyGiayPhep` | `DonViId` | `DonViId` | Filter / FK to `DM_DonVi.Id`. |
| `TK_QuanLyGiayPhep` | `DonVi` | `DonVi` | Direct map. |
| `TK_QuanLyGiayPhep` | `SoGiayPhep` | `SoGiayPhep` | Direct map. |
| `TK_QuanLyGiayPhep` | `NgayCap` | `NgayCap` | Direct map. |
| `TK_QuanLyGiayPhep` | `NgayHetHan` | `NgayHetHan` | Direct map. |
| `TK_QuanLyGiayPhep` | `Loai` | `Loai` | Direct map; schema note: `0` = petrol business license. |
| `TK_QuanLyGiayPhep` | `LoaiGiayPhepId` | `LoaiGiayPhepId` | Direct map. |
| `TK_QuanLyGiayPhep` | `GhiChu` | `GhiChu` | Direct map. |
| `TK_QuanLyGiayPhep` | `NgayThuHoi` | `NgayThuHoi` | Direct map. |
| `TK_QuanLyGiayPhep` | `LyDoThuHoi` | `LyDoThuHoi` | Direct map. |
| `TK_QuanLyGiayPhep` | `DonViCapId` | `DonViCapId` | Direct map. |

### 2.3 Fuel depots (`TK_QuanLyKhoXangDau`) — collection `KhoXangDau[]`

| Table name | Database column | Proposed DTO field name | Notes / transformation rule |
|------------|-----------------|-------------------------|-------------------------------|
| `TK_QuanLyKhoXangDau` | `Id` | `Id` | Direct map. |
| `TK_QuanLyKhoXangDau` | `DonViId` | `DonViId` | Filter by station `DM_DonVi.Id`. |
| `TK_QuanLyKhoXangDau` | `TenKho` | `TenKho` | Direct map. |
| `TK_QuanLyKhoXangDau` | `Tinh` | `Tinh` | Direct map. |
| `TK_QuanLyKhoXangDau` | `Xa` | `Xa` | Direct map. |
| `TK_QuanLyKhoXangDau` | `DiaChiChiTiet` | `DiaChiChiTiet` | Direct map. |
| `TK_QuanLyKhoXangDau` | `TongDungTich` | `TongDungTich` | Direct map. |
| `TK_QuanLyKhoXangDau` | `LoaiKho` | `LoaiKho` | Direct map; schema note on `0`/`1`. |
| `TK_QuanLyKhoXangDau` | `TenDonViSoHuu` | `TenDonViSoHuu` | Direct map. |
| `TK_QuanLyKhoXangDau` | `DonViNgoai` | `DonViNgoai` | Direct map. |
| `TK_QuanLyKhoXangDau` | `GhiChu` | `GhiChu` | Direct map. |
| `TK_QuanLyKhoXangDau` | `SapXep` | `SapXep` | Direct map. |

### 2.4 “Services”

| Table name | Database column | Proposed DTO field name | Notes / transformation rule |
|------------|-----------------|-------------------------|-------------------------------|
| `DM_DonVi` | `PhanLoaiId` | `PhanLoaiId` | Not labeled as “services” in schema; optional exposure only. |
| `DM_DonVi` | `LoaiHinh` | `LoaiHinh` | Same. |
| `DM_DonVi` | `TT` | `TT` | Opaque `int?`. |
| `DM_DonVi` | `TN` | `TN` | Opaque `int?`. |
| `DM_DonVi` | `UngPhep` | `UngPhep` | Opaque `bit?`. |
| `DM_DonVi` | `ThemMoi` | `ThemMoi` | Opaque `int?`. |
| — | — | *(named service flags)* | **Gap:** no amenity columns in documented schema. |

---

## 3. Fuel price summary

**Proposed DTO:** `FuelPriceSummaryDto` — one logical row per report header + detail line (or split header/line DTOs). Numeric meaning of `So_XX` **must** be defined per `TK_ChiTieuBaoCao` / report template (domain).

### 3.1 Report header

| Table name | Database column | Proposed DTO field name | Notes / transformation rule |
|------------|-----------------|-------------------------|-------------------------------|
| `QT_TK_ThongKe` | `Id` | `ThongKeId` | Direct map. |
| `QT_TK_ThongKe` | `TuNgay` | `TuNgay` | Direct map (`date?`). |
| `QT_TK_ThongKe` | `DenNgay` | `DenNgay` | Direct map (`date`). |
| `QT_TK_ThongKe` | `don_vi_cap1` | `DonViCap1Id` | Direct map; FK → `DM_DonVi.Id`. |
| `QT_TK_ThongKe` | `don_vi_cap2` | `DonViCap2Id` | Direct map. |
| `QT_TK_ThongKe` | `BaoCaoId` | `BaoCaoId` | Direct map. |
| `QT_TK_ThongKe` | `KieuKyBaoCao` | `KieuKyBaoCao` | Direct map. |
| `QT_TK_ThongKe` | `ThangQuy` | `ThangQuy` | Direct map. |
| `QT_TK_ThongKe` | `Loai` | `Loai` | Direct map. |
| `QT_TK_ThongKe` | `TrangThai` | `TrangThai` | Direct map. |
| `QT_TK_ThongKe` | `Chot` | `Chot` | Direct map. |

### 3.2 Report line (primary detail table)

| Table name | Database column | Proposed DTO field name | Notes / transformation rule |
|------------|-----------------|-------------------------|-------------------------------|
| `QT_TK_ThongKeChiTiet` | `Id` | `ChiTietId` | Direct map. |
| `QT_TK_ThongKeChiTiet` | `ThongKeId` | `ThongKeId` | Direct map; links to header. |
| `QT_TK_ThongKeChiTiet` | `ChiTieuThongKeId` | `ChiTieuThongKeId` | Direct map; FK → `TK_ChiTieuBaoCao.Id`. |
| `QT_TK_ThongKeChiTiet` | `MaSo` | `MaSo` | Direct map. |
| `QT_TK_ThongKeChiTiet` | `TenThongKe` | `TenThongKe` | Direct map. |
| `QT_TK_ThongKeChiTiet` | `LoaiGia` | `LoaiGia` | Direct map; semantics not in schema doc. |
| `QT_TK_ThongKeChiTiet` | `ThoiDiemDinhGia` | `ThoiDiemDinhGia` | Direct map. |
| `QT_TK_ThongKeChiTiet` | `DonViTinhId` | `DonViTinhId` | Direct map. |
| `QT_TK_ThongKeChiTiet` | `So_01` … `So_25` | `So_01` … `So_25` | Direct map each column; **do not** rename to “Price” without domain mapping per indicator. |

### 3.3 Indicator definition (for labels / units)

| Table name | Database column | Proposed DTO field name | Notes / transformation rule |
|------------|-----------------|-------------------------|-------------------------------|
| `TK_ChiTieuBaoCao` | `Id` | `ChiTieuId` | Join on `QT_TK_ThongKeChiTiet.ChiTieuThongKeId` = `TK_ChiTieuBaoCao.Id`. |
| `TK_ChiTieuBaoCao` | `MAREPORT` | `MAREPORT` | Direct map. |
| `TK_ChiTieuBaoCao` | `MA` | `MA` | Direct map. |
| `TK_ChiTieuBaoCao` | `TEN` | `TEN` | Direct map. |
| `TK_ChiTieuBaoCao` | `CONGMASO` | `CONGMASO` | Direct map. |
| `TK_ChiTieuBaoCao` | `DonViTinhId` | `ChiTieuDonViTinhId` | Direct map; FK target `DM_DonViTinh` not in 27-table doc. |

### 3.4 Alternate detail shape (optional second DTO)

| Table name | Database column | Proposed DTO field name | Notes / transformation rule |
|------------|-----------------|-------------------------|-------------------------------|
| `QT_TK_ThongKeChiTiet02` | `ThongKeId` | `ThongKeId` | Same header `QT_TK_ThongKe`. |
| `QT_TK_ThongKeChiTiet02` | `HangHoaId` | `HangHoaId` | Direct map; `DM_HangHoa` not in 27-table doc. |
| `QT_TK_ThongKeChiTiet02` | `SoLuong` | `SoLuong` | Direct map. |
| `QT_TK_ThongKeChiTiet02` | `GiaTri` | `GiaTri` | Direct map; not proven to be “unit price” without domain. |
| `QT_TK_ThongKeChiTiet02` | `NongDoCon` | `NongDoCon` | Direct map. |
| `QT_TK_ThongKeChiTiet02` | `So_01` … `So_25` | `So_01` … `So_25` | Direct map. |

---

## 4. Inventory / stock summary

**Proposed DTOs:** `InventoryDepotSummaryDto` (depot + latest or aggregated stock), `InventoryTonKhoLineDto` (snapshot lines).

### 4.1 Depot

| Table name | Database column | Proposed DTO field name | Notes / transformation rule |
|------------|-----------------|-------------------------|-------------------------------|
| `TK_QuanLyKhoXangDau` | `Id` | `KhoId` | Direct map. |
| `TK_QuanLyKhoXangDau` | `DonViId` | `DonViId` | Link to `DM_DonVi.Id`. |
| `TK_QuanLyKhoXangDau` | `TenKho` | `TenKho` | Direct map. |
| `TK_QuanLyKhoXangDau` | `TongDungTich` | `TongDungTich` | Capacity-style field. |
| `TK_QuanLyKhoXangDau` | `LoaiKho` | `LoaiKho` | Direct map. |

### 4.2 Allocation (`TK_QuanLyKhoXangDau_PhanBoDungTich`)

| Table name | Database column | Proposed DTO field name | Notes / transformation rule |
|------------|-----------------|-------------------------|-------------------------------|
| `TK_QuanLyKhoXangDau_PhanBoDungTich` | `Id` | `PhanBoId` | Direct map. |
| `TK_QuanLyKhoXangDau_PhanBoDungTich` | `KhoId` | `KhoId` | Direct map. |
| `TK_QuanLyKhoXangDau_PhanBoDungTich` | `BonBe` | `BonBe` | Direct map. |
| `TK_QuanLyKhoXangDau_PhanBoDungTich` | `TongDungTich` | `TongDungTichPhanBo` | Direct map; same column name as depot — disambiguate in DTO name only. |
| `TK_QuanLyKhoXangDau_PhanBoDungTich` | `TrangThai` | `TrangThai` | Direct map. |
| `TK_QuanLyKhoXangDau_PhanBoDungTich` | `HinhThuc` | `HinhThuc` | Direct map; schema note `0`/`1`. |

### 4.3 Stock snapshot (`TK_QuanLyKhoXangDau_TonKho`)

| Table name | Database column | Proposed DTO field name | Notes / transformation rule |
|------------|-----------------|-------------------------|-------------------------------|
| `TK_QuanLyKhoXangDau_TonKho` | `Id` | `TonKhoId` | Direct map. |
| `TK_QuanLyKhoXangDau_TonKho` | `PhanBoId` | `PhanBoId` | Direct map. |
| `TK_QuanLyKhoXangDau_TonKho` | `Ngay` | `Ngay` | Direct map. |
| `TK_QuanLyKhoXangDau_TonKho` | `SoLuong` | `SoLuong` | Direct map. |
| `TK_QuanLyKhoXangDau_TonKho` | `HeSo` | `HeSo` | Direct map. |
| `TK_QuanLyKhoXangDau_TonKho` | `GhiChu` | `GhiChu` | Direct map. |

### 4.4 Report-based inventory lines (optional)

| Table name | Database column | Proposed DTO field name | Notes / transformation rule |
|------------|-----------------|-------------------------|-------------------------------|
| `QT_TK_ThongKeChiTiet02` | `LoaiKho` | `LoaiKho` | Direct map. |
| `QT_TK_ThongKeChiTiet02` | `DiaChiKho` | `DiaChiKho` | Direct map. |
| `QT_TK_ThongKeChiTiet02` | `SoLuong` | `SoLuong` | Direct map. |
| `QT_TK_ThongKeChiTiet02` | `HangHoaId` | `HangHoaId` | Direct map. |

---

## 5. Overview report

**Proposed DTO:** `ReportOverviewDto` (high-level reporting period / assignment / lock). Combine only fields needed for a dashboard; below lists authoritative sources.

### 5.1 Report instance (statistics)

| Table name | Database column | Proposed DTO field name | Notes / transformation rule |
|------------|-----------------|-------------------------|-------------------------------|
| `QT_TK_ThongKe` | `Id` | `ThongKeId` | Direct map. |
| `QT_TK_ThongKe` | `TuNgay` | `TuNgay` | Direct map. |
| `QT_TK_ThongKe` | `DenNgay` | `DenNgay` | Direct map. |
| `QT_TK_ThongKe` | `don_vi_cap1` | `DonViCap1Id` | Direct map. |
| `QT_TK_ThongKe` | `BaoCaoId` | `BaoCaoId` | Direct map. |
| `QT_TK_ThongKe` | `KieuKyBaoCao` | `KieuKyBaoCao` | Direct map. |
| `QT_TK_ThongKe` | `TrangThai` | `TrangThai` | Direct map. |
| `QT_TK_ThongKe` | `Chot` | `Chot` | Direct map. |
| `QT_TK_ThongKe` | `ThoiGianGui` | `ThoiGianGui` | Direct map. |

### 5.2 Data lock / snapshot metadata

| Table name | Database column | Proposed DTO field name | Notes / transformation rule |
|------------|-----------------|-------------------------|-------------------------------|
| `QT_TK_ChotSoLieu` | `Id` | `ChotSoLieuId` | Direct map. |
| `QT_TK_ChotSoLieu` | `Nam` | `Nam` | Direct map. |
| `QT_TK_ChotSoLieu` | `NgayChot` | `NgayChot` | Direct map. |
| `QT_TK_ChotSoLieu` | `don_vi_cap1` | `DonViCap1Id` | Direct map. |
| `QT_TK_ChotSoLieu` | `LoaiBaoCao` | `LoaiBaoCao` | Direct map. |
| `QT_TK_ChotSoLieu` | `BaoCaoId` | `BaoCaoId` | Direct map. |

### 5.3 Report assignment to units

| Table name | Database column | Proposed DTO field name | Notes / transformation rule |
|------------|-----------------|-------------------------|-------------------------------|
| `TK_GiaoBaoCao` | `Id` | `GiaoBaoCaoId` | Direct map. |
| `TK_GiaoBaoCao` | `DonViGiaoId` | `DonViGiaoId` | Direct map. |
| `TK_GiaoBaoCao` | `BaoCaoId` | `BaoCaoId` | Direct map. |
| `TK_GiaoBaoCao` | `KieuKyBaoCao` | `KieuKyBaoCao` | Direct map. |
| `TK_GiaoBaoCao` | `Nam` | `Nam` | Direct map. |
| `TK_GiaoBaoCao` | `ThangQuy` | `ThangQuy` | Direct map. |
| `TK_GiaoBaoCao` | `TuNgay` | `TuNgay` | Direct map. |
| `TK_GiaoBaoCao` | `DenNgay` | `DenNgay` | Direct map. |
| `TK_GiaoBaoCao` | `NgayMo` | `NgayMo` | Direct map. |
| `TK_GiaoBaoCao` | `NgayDong` | `NgayDong` | Direct map. |
| `TK_GiaoBaoCao` | `TuDongGiao` | `TuDongGiao` | Direct map. |
| `TK_GiaoBaoCaoChiTiet` | `DonViId` | `DonViId` | Direct map; child of `TK_GiaoBaoCao`. |
| `TK_GiaoBaoCaoChiTiet` | `GiaoBaoCaoId` | `GiaoBaoCaoId` | Direct map. |

### 5.4 Transferred / export grids (template-specific)

Use **`QT_TK_ThongKeChiTiet_ChuyenDuLieu`** and **`QT_TK_ThongKeChiTiet_ChuyenDuLieu_Mau02`** … **`Mau08`** with the same column names as in schema (example from base table):

| Table name | Database column | Proposed DTO field name | Notes / transformation rule |
|------------|-----------------|-------------------------|-------------------------------|
| `QT_TK_ThongKeChiTiet_ChuyenDuLieu` | `DonViId` | `DonViId` | Direct map. |
| `QT_TK_ThongKeChiTiet_ChuyenDuLieu` | `ThoiGian` | `ThoiGian` | Direct map (`nvarchar`). |
| `QT_TK_ThongKeChiTiet_ChuyenDuLieu` | `KieuKyBaoCao` | `KieuKyBaoCao` | Direct map. |
| `QT_TK_ThongKeChiTiet_ChuyenDuLieu` | `TenThongKe` | `TenThongKe` | Direct map. |
| `QT_TK_ThongKeChiTiet_ChuyenDuLieu` | `MaSo` | `MaSo` | Direct map. |
| `QT_TK_ThongKeChiTiet_ChuyenDuLieu` | `DVT` | `DVT` | Direct map. |
| `QT_TK_ThongKeChiTiet_ChuyenDuLieu` | `So_01` … `So_20` | `So_01` … `So_20` | Per schema; Mau variants use same pattern up to `So_20` as documented. |

---

## 6. Stabilization fund

**Proposed DTO:** *None backed by named columns in `docs/architecture/database.md`.*

| Table name | Database column | Proposed DTO field name | Notes / transformation rule |
|------------|-----------------|-------------------------|-------------------------------|
| — | — | — | **Gap:** no table or column in the documented schema identifies a stabilization fund. If a future domain mapping ties specific `TK_ChiTieuBaoCao` rows to fund amounts, reuse **`FuelPriceSummaryDto`** / report line mappings for those `So_XX` columns only after explicit sign-off. |

---

## 7. Price declarations

**Proposed DTOs:** `PriceDeclarationAssignmentDto` (from `TK_GiaoBaoCao` + `TK_GiaoBaoCaoChiTiet`), `PriceDeclarationReportDto` (from `QT_TK_ThongKe` + detail lines + indicators).

| Table name | Database column | Proposed DTO field name | Notes / transformation rule |
|------------|-----------------|-------------------------|-------------------------------|
| `TK_GiaoBaoCao` | `Id` | `GiaoBaoCaoId` | Assignment / window for declarations. |
| `TK_GiaoBaoCao` | `BaoCaoId` | `BaoCaoId` | Direct map. |
| `TK_GiaoBaoCao` | `KieuKyBaoCao` | `KieuKyBaoCao` | Direct map. |
| `TK_GiaoBaoCao` | `NgayBatDauKyBC` | `NgayBatDauKyBC` | Direct map. |
| `TK_GiaoBaoCao` | `NgayKetThucKyBC` | `NgayKetThucKyBC` | Direct map. |
| `TK_GiaoBaoCao` | `TuNgay` | `TuNgay` | Direct map. |
| `TK_GiaoBaoCao` | `DenNgay` | `DenNgay` | Direct map. |
| `TK_GiaoBaoCao` | `Nam` | `Nam` | Direct map. |
| `TK_GiaoBaoCao` | `ThangQuy` | `ThangQuy` | Direct map. |
| `TK_GiaoBaoCao` | `NgayMo` | `NgayMo` | Direct map. |
| `TK_GiaoBaoCao` | `NgayDong` | `NgayDong` | Direct map. |
| `TK_GiaoBaoCaoChiTiet` | `DonViId` | `DonViId` | Unit assigned to report. |
| `QT_TK_ThongKe` | `Id` | `ThongKeId` | Filed report instance. |
| `QT_TK_ThongKe` | `don_vi_cap1` | `DonViCap1Id` | Direct map. |
| `QT_TK_ThongKe` | `TuNgay` / `DenNgay` | `TuNgay` / `DenNgay` | Period of filed data. |
| `QT_TK_ThongKeChiTiet` | `LoaiGia` | `LoaiGia` | Direct map. |
| `QT_TK_ThongKeChiTiet` | `ThoiDiemDinhGia` | `ThoiDiemDinhGia` | Direct map. |
| `QT_TK_ThongKeChiTiet` | `ChiTieuThongKeId` | `ChiTieuThongKeId` | Link to indicator definition. |
| `QT_TK_ThongKeChiTiet` | `So_01` … `So_25` | `So_01` … `So_25` | Declared numeric slots; semantics via `TK_ChiTieuBaoCao`. |
| `QT_TK_ChotSoLieu` | `NgayChot` | `NgayChot` | Lock time for submitted statistics. |
| `QT_TK_ChotSoLieu` | `BaoCaoId` | `BaoCaoId` | Direct map. |

---

## 8. Citizen complaint request and response

**No persistence** in documented schema. Below maps **API contract only** (no SQL column).

### 8.1 Request — `CitizenComplaintCreateRequest` (proposed)

| Table name | Database column | Proposed DTO field name | Notes / transformation rule |
|------------|-----------------|-------------------------|-------------------------------|
| — | — | `Subject` | **Not in DB**; required product field for a future store or external system. |
| — | — | `Body` | **Not in DB**; same. |
| — | — | `ReporterName` | **Not in DB**; optional. |
| — | — | `ReporterPhone` | **Not in DB**; optional. |
| — | — | `ReporterEmail` | **Not in DB**; optional. |
| — | — | `DonViId` | **Optional:** if complaint targets a station, use existing `DM_DonVi.Id` semantics; still **no complaint table** to insert into in this schema. |
| — | — | `TinhId` / `XaPhuongId` | **Optional** geography hints; could align with `DM_Tinh.Id` / `DM_XaPhuong.Id` if used as request validation only. |

### 8.2 Response — `CitizenComplaintCreateResponse` (proposed)

| Table name | Database column | Proposed DTO field name | Notes / transformation rule |
|------------|-----------------|-------------------------|-------------------------------|
| — | — | `Accepted` | **Not in DB**; API acknowledgment. |
| — | — | `Message` | **Not in DB**; human-readable status. |
| — | — | `TicketId` | **Gap:** no column to persist or return a ticket id from documented schema. |

---

## 9. Province / district / ward lookup

### 9.1 Province — `ProvinceLookupDto` from `DM_Tinh`

| Table name | Database column | Proposed DTO field name | Notes / transformation rule |
|------------|-----------------|-------------------------|-------------------------------|
| `DM_Tinh` | `Id` | `Id` | Direct map. |
| `DM_Tinh` | `Ma` | `Ma` | Direct map. |
| `DM_Tinh` | `Ten` | `Ten` | Direct map. |
| `DM_Tinh` | `TenTiengNuocNgoai` | `TenTiengNuocNgoai` | Direct map. |
| `DM_Tinh` | `SapXep` | `SapXep` | Direct map. |
| `DM_Tinh` | `VungMien` | `VungMien` | Direct map. |

### 9.2 Ward / commune — `WardLookupDto` from `DM_XaPhuong`

| Table name | Database column | Proposed DTO field name | Notes / transformation rule |
|------------|-----------------|-------------------------|-------------------------------|
| `DM_XaPhuong` | `Id` | `Id` | Direct map. |
| `DM_XaPhuong` | `Ma` | `Ma` | Direct map. |
| `DM_XaPhuong` | `Ten` | `Ten` | Direct map. |
| `DM_XaPhuong` | `TenTiengNuocNgoai` | `TenTiengNuocNgoai` | Direct map. |
| `DM_XaPhuong` | `TinhId` | `TinhId` | Direct map; FK → `DM_Tinh.Id`. |
| `DM_XaPhuong` | `QuanHuyenId` | `QuanHuyenId` | Direct map; **district name not in `docs/architecture/database.md`** (`DM_QuanHuyen` undefined here). |
| `DM_XaPhuong` | `MaTinh` | `MaTinh` | Direct map. |

### 9.3 District — `DistrictLookupDto`

| Table name | Database column | Proposed DTO field name | Notes / transformation rule |
|------------|-----------------|-------------------------|-------------------------------|
| — | — | — | **Gap:** `DM_QuanHuyen` is referenced by `DM_XaPhuong.QuanHuyenId` but **no** `DM_QuanHuyen` table or columns appear in `docs/architecture/database.md`. API may expose only `QuanHuyenId` as opaque int from `DM_XaPhuong` until schema doc includes `DM_QuanHuyen`. |

---

## Cross-reference

| Document | Use |
|----------|-----|
| `docs/architecture/database.md` | Authoritative columns and FKs |
| `docs/architecture/schema-analysis.md` | Business-area narrative and gaps |
| `docs/modules/api-mapping.md` | Backend module ↔ table grouping |
