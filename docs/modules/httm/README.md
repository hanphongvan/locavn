# Domain: HTTM – Hạ Tầng Thương Mại

> **Chỉ mục domain HTTM** – Claude Code đọc file này để hiểu phạm vi, màn hình, data model và các task còn lại của domain này, khi phân tách khỏi ứng dụng Fuel thuần.

## Mục lục nhanh

| File | Nội dung |
|------|----------|
| [`docs/modules/httm/screens.md`](./screens.md) | 14 màn hình – mô tả chi tiết UI + chức năng |
| [`docs/modules/httm/data-model.md`](./data-model.md) | Schema DB, quan hệ bảng, enum values |
| [`docs/modules/httm/api-endpoints.md`](./api-endpoints.md) | Danh sách API endpoints theo module |
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

### 4 Nhóm người dùng

| Role | Mã | Phạm vi dữ liệu |
|------|----|-----------------|
| Quản trị viên | `ADMIN` | Toàn hệ thống |
| Cán bộ BCT (Cấp TW) | `BCT_STAFF` | Toàn quốc |
| Cán bộ Sở (Cấp tỉnh) | `SO_STAFF` | Trong tỉnh được gán |
| Đơn vị được khảo sát | `UNIT_USER` | Chỉ dữ liệu của đơn vị mình |

---

## TODO / Backlog

### Giai đoạn 1 – MVP (ưu tiên cao)
- [ ] **M2** – Form phiếu khảo sát 6 bước với auto-save mỗi 60 giây
- [ ] **M2** – Luồng duyệt phiếu (submit → review → approve/reject)
- [ ] **M3** – CRUD hồ sơ HTTM (7 tab thông tin)
- [ ] **M3** – Import/Export Excel hàng loạt
- [ ] **M1** – Phân quyền theo role + phân cấp địa lý (tỉnh)
- [ ] **M5** – Dashboard KPI cơ bản (4 chỉ số + 3 biểu đồ)

### Giai đoạn 2
- [ ] **M4** – Bản đồ GIS nội bộ (PostGIS + MapLibre/Leaflet)
- [ ] **M4** – Public portal bản đồ (không cần đăng nhập)
- [ ] **M5** – Báo cáo động với bộ lọc đa chiều
- [ ] **M5** – Xuất PDF/PowerPoint
- [ ] Mobile App (Android/iOS)

### Giai đoạn 3
- [ ] Tích hợp AI dự báo nhu cầu HTTM
- [ ] Kết nối cổng dịch vụ công quốc gia
- [ ] Tích hợp chữ ký số
- [ ] Open Data API công khai

---

## Quy tắc domain

- Mỗi HTTM phải có `province_code` (mã tỉnh chuẩn ĐVHCVN)
- Toạ độ GPS lưu dạng PostGIS `geometry(Point, 4326)`
- Trạng thái phiếu KS là enum: `draft | submitted | reviewing | approved | rejected`
- Trạng thái HTTM là enum: `active | suspended | under_construction | closed`
- Mọi thay đổi dữ liệu HTTM phải ghi audit log (bảng `httm_audit_logs`)
- Dữ liệu nhạy cảm (doanh thu, lợi nhuận) chỉ `BCT_STAFF` và `ADMIN` được xem
