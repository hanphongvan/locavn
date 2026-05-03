# Schema analysis (DMPPortal)

Source: **`docs/architecture/database.md`** only. The database lists **27 tables** in `dbo`. Foreign keys reference some lookup tables (for example `DM_QuanHuyen`, `DM_NoiCapGiayPhep`, `DM_HangHoa`, `DM_DonViTinh`, `DM_NhaCungCap`, `DM_XuatXu`) that **do not appear** in that document’s table list; those targets are noted where relevant but **no structure is invented** for them here.

---

## 1. Petrol station master data

**Related tables**

| Table | Role in this schema |
|--------|----------------------|
| `DM_DonVi` | Organizational unit: code, name, contact, address fields, hierarchy, status, optional license fields on the unit row. |
| `TK_QuanLyGiayPhep` | Per-unit license records (including note: `Loai` = 0 for petrol business license). |
| `TK_QuanLyKhoXangDau` | Fuel depot / tank farm row tied to `DM_DonVi` via `DonViId` (`TenKho`, address-like fields). |

**Related columns (representative)**

- **`DM_DonVi`**: `Id`, `Ma`, `Ten`, `TenTiengNuocNgoai`, `DienThoai`, `DiaChi`, `Email`, `DiaChiChiTiet`, `Tinh`, `Xa`, `CapTrenId`, `ThuocDonViId`, `TrangThai`, `VungMien`, `PhanLoaiId`, `LoaiHinh`, `SoGiayPhep`, `NgayCap`, `NgayHetHan`, `NoiCapId`, audit fields (`Created`, `Modified`, …).
- **`TK_QuanLyGiayPhep`**: `Id`, `DonViId`, `DonVi`, `SoGiayPhep`, `NgayCap`, `NgayHetHan`, `Loai`, `LoaiGiayPhepId`, `GhiChu`, `NgayThuHoi`, `LyDoThuHoi`, `DonViCapId`, audit fields.
- **`TK_QuanLyKhoXangDau`**: `Id`, `DonViId`, `TenKho`, `Tinh`, `Xa`, `DiaChiChiTiet`, `TongDungTich`, `LoaiKho`, `TenDonViSoHuu`, `DonViNgoai`, `GhiChu`, `SapXep`, audit fields.

**Assumptions / ambiguities**

- A **retail “petrol station”** is not a dedicated table name; it is plausibly modeled as **`DM_DonVi`** (with classification via `PhanLoaiId`, `LoaiHinh`, `Cap`, `CapDonViId`) and/or **`TK_QuanLyKhoXangDau`** for storage assets. **Domain confirmation** is required before treating every `DM_DonVi` row as a public-facing station.
- `DM_DonVi` duplicates some license-like columns (`SoGiayPhep`, `NgayCap`, `NgayHetHan`) while **`TK_QuanLyGiayPhep`** holds normalized license rows; precedence and sync rules are **not** described in the schema doc.

---

## 2. Coordinates / map location

**Related tables**

- **None** in `docs/architecture/database.md` expose latitude/longitude or equivalent geometry.

**Related columns**

- **Indirect location only**: textual and administrative keys, for example:
  - `DM_DonVi`: `DiaChi`, `DiaChiChiTiet`, `Tinh`, `Xa`
  - `TK_QuanLyKhoXangDau`: `Tinh`, `Xa`, `DiaChiChiTiet`
  - `QT_TK_ThongKeChiTiet02`: `DiaChiKho`, `Tinh`, `Huyen`, `Xa`, `SoNha` (as `nvarchar` location text, not coordinates)

**Assumptions / ambiguities**

- **Gap for map pins**: no documented numeric coordinate columns. Mapping requires another data source, a schema extension, or geocoding (product decision outside this file).

---

## 3. Station services

**Related tables**

- No table whose name or documented columns describe amenities (e.g. car wash, convenience store, EV charging).

**Related columns (possible encodings only — unverified)**

- **`DM_DonVi`**: `PhanLoaiId`, `LoaiHinh`, `TT`, `TN`, `UngPhep`, `ThemMoi` — all are opaque `int`/`bit` codes without value lists in `docs/architecture/database.md`.

**Assumptions / ambiguities**

- **Gap as “services catalog”**: nothing in the documented schema is labeled as services. Any mobile “services” feature needs a **domain dictionary** for those codes or external data.

---

## 4. Fuel prices

**Related tables**

| Table | Role |
|--------|------|
| `QT_TK_ThongKe` | Report header: period (`TuNgay`, `DenNgay`), unit (`don_vi_cap1`, …), report linkage (`BaoCaoId`), status fields. |
| `QT_TK_ThongKeChiTiet` | Report lines: indicator link `ChiTieuThongKeId` → `TK_ChiTieuBaoCao`, labels, many numeric slots `So_01` … `So_25`, plus `LoaiGia`, `ThoiDiemDinhGia`, `DonViTinhId`. |
| `QT_TK_ThongKeChiTiet02` | Alternate detail shape: `HangHoaId`, `SoLuong`, `GiaTri`, many `So_XX`, `DonViTinhId`, location text fields. |
| `QT_TK_ThongKeChiTiet_ChuyenDuLieu` (+ `Mau02`, `Mau05`, … `Mau08`) | Transferred/export-style numeric grids (`So_01`…), `TenThongKe`, `MaSo`, `DVT`, `DonViId`, `ThoiGian`, `KieuKyBaoCao`. |
| `TK_ChiTieuBaoCao` | Report indicator definitions: `MAREPORT`, `MA`, `TEN`, `CONGMASO`, `TENSQL`, tree hints (`Parent`, `Cap`), `DonViTinhId`, etc. |

**Related columns (high level)**

- Price **timing / type hints** (not self-explanatory): `LoaiGia`, `ThoiDiemDinhGia` on `QT_TK_ThongKeChiTiet`.
- **Values**: generic `So_XX`, `GiaTri`, `SoLuong`, `NongDoCon` where present — meaning depends on **`TK_ChiTieuBaoCao`** / report template.

**Assumptions / ambiguities**

- This is **statutory / internal reporting**, not necessarily a simple “current pump price per station” table. Which `So_XX` is price for which product requires **report-specific mapping** (often from business owners + `TK_ChiTieuBaoCao.TEN` / `MA`).

---

## 5. Fuel stock / inventory

**Related tables**

| Table | Role |
|--------|------|
| `TK_QuanLyKhoXangDau` | Depot master: capacity `TongDungTich`, type `LoaiKho`, link to `DonViId`. |
| `TK_QuanLyKhoXangDau_PhanBoDungTich` | Allocation of volume (`TongDungTich`, `BonBe`, `HinhThuc`, `TrangThai`, dates). |
| `TK_QuanLyKhoXangDau_TonKho` | Stock snapshot lines: `PhanBoId`, `Ngay`, `SoLuong`, `HeSo`, `GhiChu`. |
| `TK_QuanLyKhoXangDau_HopDong` | Contracts tied to `PhanBoId` (`SoHopDong`, date range). |
| `QT_TK_ThongKeChiTiet02` | Report lines with `SoLuong`, `HangHoaId`, `LoaiKho`, `DiaChiKho`, etc. |

**Related columns**

- **`TK_QuanLyKhoXangDau_TonKho`**: `SoLuong`, `Ngay`, `HeSo`, `GhiChu`, `PhanBoId`.
- **`TK_QuanLyKhoXangDau_PhanBoDungTich`**: `TongDungTich`, `TrangThai`, `BonBe`, `KhoId`.

**Assumptions / ambiguities**

- Model is **warehouse / allocation** oriented, not proven as “retail nozzle inventory” per station. `HangHoaId` in `QT_TK_ThongKeChiTiet02` references **`DM_HangHoa`** (table not detailed in this doc).

---

## 6. Stabilization fund

**Related tables**

- **No table or column name** in `docs/architecture/database.md` explicitly denotes a stabilization fund (e.g. “quỹ bình ổn”).

**Related columns**

- **None identifiable** without row-level metadata from `TK_ChiTieuBaoCao` / report templates: fund flows could theoretically appear as **unspecified** `So_XX` values on some report lines.

**Assumptions / ambiguities**

- **Treat as gap** for implementation until domain experts map specific `TK_ChiTieuBaoCao` indicators (or confirm absence in this database).

---

## 7. Price declarations

**Related tables**

| Table | Role |
|--------|------|
| `QT_TK_ThongKe` + `QT_TK_ThongKeChiTiet` (and/or `QT_TK_ThongKeChiTiet02`) | Structured reporting with periods and numeric slots; includes `LoaiGia`, `ThoiDiemDinhGia` on the first detail table. |
| `TK_GiaoBaoCao` | Assignment / schedule of reporting: `DonViGiaoId`, `BaoCaoId`, `KieuKyBaoCao`, period dates, `TuDongGiao`. |
| `TK_GiaoBaoCaoChiTiet` | Per-report assignment rows: `GiaoBaoCaoId`, `DonViId`. |
| `QT_TK_ChotSoLieu` | “Chốt số liệu” snapshot metadata: `Nam`, `NgayChot`, `don_vi_cap1`, `LoaiBaoCao`, `BaoCaoId`. |
| `TK_ChiTieuBaoCao` | Defines report line indicators that declared numbers attach to. |

**Related columns (examples)**

- `TK_GiaoBaoCao`: `NgayBatDauKyBC`, `NgayKetThucKyBC`, `TuNgay`, `DenNgay`, `Nam`, `ThangQuy`, `NgayMo`, `NgayDong`.
- `QT_TK_ThongKeChiTiet`: `LoaiGia`, `ThoiDiemDinhGia`, `So_01`…`So_25`, `ChiTieuThongKeId`.

**Assumptions / ambiguities**

- “Price declaration” in a **regulatory** sense may map to this reporting chain, but the schema does not label a single entity “declaration”; it is **report instances + lines**. Legal meaning requires **business mapping**.

---

## 8. Citizen complaints

**Related tables**

- **None** in the documented 27 tables.

**Related columns**

- **None.**

**Assumptions / ambiguities**

- **Gap**: no complaints, tickets, or citizen feedback storage appears in `docs/architecture/database.md`.

---

## 9. Administrative geography

**Related tables**

| Table | Role |
|--------|------|
| `DM_Tinh` | Province: `Id`, `Ma`, `Ten`, `TenTiengNuocNgoai`, `SapXep`, `VungMien`, audit fields. |
| `DM_XaPhuong` | Commune/ward: `Id`, `Ma`, `Ten`, `TinhId`, `QuanHuyenId`, `MaTinh`, audit fields. FK to `DM_Tinh`; FK to **`DM_QuanHuyen`** (not listed in the schema doc’s table inventory). |

**Related columns**

- **`DM_DonVi`**: `Tinh`, `Xa` — appear to be **foreign key integers** toward geography (conventionally `DM_Tinh.Id` / `DM_XaPhuong.Id`; not re-documented as FKs in the excerpt).
- **`TK_QuanLyKhoXangDau`**: `Tinh`, `Xa` — same pattern.

**Assumptions / ambiguities**

- **`DM_QuanHuyen`** is referenced by `DM_XaPhuong.QuanHuyenId` but is **not** one of the 27 documented tables; district-level labels cannot be read from this file alone.
- Whether `DM_DonVi.Tinh` / `Xa` always match `DM_Tinh` / `DM_XaPhuong` ids should be **validated in data**, not assumed.

---

## Summary: gaps (not covered or not identifiable)

| Business area | Status in `docs/architecture/database.md` |
|---------------|-------------------------------|
| Coordinates / map | **Gap** (no coordinate columns). |
| Station services (amenities) | **Gap** as explicit data; possible opaque codes on `DM_DonVi` only. |
| Stabilization fund | **Gap** by name; might be hidden in report numerics — needs domain mapping. |
| Citizen complaints | **Gap** (no tables). |
| District (`DM_QuanHuyen`) | **Not documented** in the 27-table list (only referenced by FK from `DM_XaPhuong`). |

---

## Other documented tables (cross-cutting)

- **ASP.NET Identity**: `AspNetUsers`, `AspNetRoles`, `AspNetUserRoles`, `AspNetUserClaims`, `AspNetUserLogins` — user and role management for the portal, not station master data.
- **Reporting export variants**: multiple `QT_TK_ThongKeChiTiet_ChuyenDuLieu_*` tables — same general pattern (transferred statistics), template-specific.
