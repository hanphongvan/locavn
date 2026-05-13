# Domain: HTTM – Hạ Tầng Thương Mại

> **Chỉ mục domain HTTM** – Claude Code đọc file này để hiểu phạm vi, màn hình, data model và các task còn lại của domain này, khi phân tách khỏi ứng dụng Fuel thuần.

## Mục lục nhanh

| File | Nội dung |
|------|----------|
| [`screens.md`](./screens.md) | 14 màn hình – mô tả chi tiết UI + chức năng |
| [`data-model-sqlserver.md`](./data-model-sqlserver.md) | ✅ **Schema chính thức (SQL Server)** — table, SP, view, index |
| [`data-model.md`](./data-model.md) | ⚠️ Deprecated — bản PostgreSQL gốc, chỉ tham chiếu enum & business rules |
| [`api-endpoints.md`](./api-endpoints.md) | Danh sách API endpoints theo module |
| [`implementation-plan.md`](./implementation-plan.md) | Scope Phase 1 chính thức (CRUD facilities, không bao gồm Survey) |
| [`checklist.md`](./checklist.md) | ✅ **Single source of truth tiến độ** — track Phase 1/2/3, đánh dấu khi merge |
| [`docs/architecture/database.md`](../../architecture/database.md) | Schema tổng thể toàn dự án (tham chiếu) |

---

## Tổng quan domain

**HTTM** (Hạ Tầng Thương Mại) là domain quản lý toàn bộ cơ sở hạ tầng thương mại quốc gia bao gồm chợ, siêu thị, trung tâm thương mại, chợ đầu mối, cửa hàng tiện lợi.

Chủ trì: **Cục Quản lý và Phát triển Thị trường Trong nước – Bộ Công Thương**

### Hai luồng nghiệp vụ chính

```
Luồng 1 – Thu thập dữ liệu (Phiếu khảo sát):
  Tạo phiếu → Điền form 6 bước → Nộp → Duyệt → Tạo hồ sơ HTTM

Luồng 2 – Quản lý hồ sơ:
  Hồ sơ HTTM → Cập nhật → Hiển thị bản đồ → Thống kê báo cáo
```

### 6 Module chức năng

| # | Module | Màn hình | Mô tả |
|---|--------|----------|-------|
| M1 | Auth & Phân quyền | S1.1, S1.2 | Đăng nhập, Dashboard |
| M2 | Phiếu Khảo Sát | S2.1–S2.4 | Thu thập dữ liệu từ đơn vị |
| M3 | Hồ Sơ HTTM | S3.1–S3.3 | CRUD hồ sơ chi tiết |
| M4 | Bản Đồ Số | S4.1, S4.2 | GIS nội bộ + public portal |
| M5 | Thống Kê / Báo Cáo | S5.1, S5.2 | Dashboard, xuất báo cáo |
| M6 | Quản Trị | S6.1 | Admin panel |

### Nhóm người dùng (mapping qua `AspNetUsers.Loai` — dùng chung toàn dự án)

| Loai | Role | Phạm vi dữ liệu | Trạng thái |
|------|------|-----------------|------------|
| 1 | `ADMIN` | Toàn hệ thống (Fuel + HTTM) | ✅ đã có |
| 10 | `HTTM_ADMIN` | Quản trị riêng HTTM (không có quyền Fuel) | 🆕 Phase 1 |
| 11 | `BCT_STAFF` | Cán bộ Bộ Công Thương — toàn quốc, xem dữ liệu nhạy cảm | 🆕 Phase 1 |
| 12 | `SO_STAFF` | Cán bộ Sở — scope theo `province_codes[]` được gán | 🆕 Phase 1 |
| 13 | `UNIT_USER` | Đơn vị được khảo sát — chỉ dữ liệu của đơn vị mình | 🆕 Phase 2 |

> Quy ước: `Loai ∈ [10..19]` reserved cho domain HTTM. Xem [`checklist.md`](./checklist.md) cho decision log đầy đủ.

---

## TODO / Backlog

> 📋 **Tiến độ chi tiết & checklist từng task** xem [`checklist.md`](./checklist.md) (single source of truth).
> Phần dưới đây là tóm tắt high-level cho người mới đọc.

### Phase 1 — MVP Hồ sơ HTTM (theo `implementation-plan.md` chính thức)
- **M3** – CRUD `HttmFacilities` (7 tab) + filter + paging + audit log
- **M3** – Upload ảnh + quản lý giấy phép (`HttmFacilityImages`, `HttmFacilityLicenses`)
- **M4** – Map markers nhẹ (`/api/httm/map-data` GeoJSON, ≤ 2000 features, clustering)
- **M1** – Mở rộng `AdminPortalLoaiRoleMapper`: thêm Loai 10 (HTTM_ADMIN), 11 (BCT_STAFF), 12 (SO_STAFF) + geo-scope theo tỉnh
- **M1** – Sensitive field filter (`AvgRentPrice`, `AnnualRevenue`)
- **M6** – Danh mục read-only `/api/catalogs/{type}`

### Phase 2 — Phiếu khảo sát + Public Map + Analytics
- **M2** – Phiếu khảo sát 6 bước (`HttmSurveys`) + auto-save 60s + workflow duyệt
- **M2** – Import/Export Excel hàng loạt + Loai 13 (UNIT_USER)
- **M4** – Public portal `/public/map` (no-auth, lọc sensitive)
- **M5** – Dashboard `/analytics` + 6 chart + export PDF/Excel
- **S5.2** – Report templates + cron nhắc nộp

### Phase 3 — Mở rộng
- Mobile app (Flutter) cho surveyor field work
- AI dự báo (tích hợp LocaAI + Qdrant)
- SSO Bộ Công Thương, cổng dịch vụ công, chữ ký số
- Open Data API công khai

---

## Quy tắc domain

- Mỗi HTTM phải có `ProvinceCode` (mã tỉnh chuẩn ĐVHCVN)
- Toạ độ GPS lưu dạng SQL Server `GEOGRAPHY` (SRID 4326), POINT(lng lat) — chi tiết: [`data-model-sqlserver.md`](./data-model-sqlserver.md)
- Trạng thái phiếu KS là enum: `draft | submitted | reviewing | approved | rejected`
- Trạng thái HTTM là enum: `active | suspended | under_construction | closed`
- Mọi thay đổi dữ liệu HTTM phải ghi audit log (bảng `HttmAuditLogs`)
- Dữ liệu nhạy cảm (`AvgRentPrice`, `AnnualRevenue`) chỉ `ADMIN`, `HTTM_ADMIN`, `BCT_STAFF` được xem
- Truy cập DB **bắt buộc qua Stored Procedure** (Dapper/ADO.NET); không EF cho nghiệp vụ — xem [`docs/architecture/backend.md`](../../architecture/backend.md)
- Map provider có thể cấu hình runtime: **Goong.io** hoặc **OSM** (config qua `system_configs`). Provider phải có nhãn Hoàng Sa/Trường Sa (compliance blocking)
