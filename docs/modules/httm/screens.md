# HTTM – Mô Tả Chi Tiết 14 Màn Hình

> Tài liệu này mô tả từng màn hình: mục đích, bố cục, các trường dữ liệu, hành động, validation và ghi chú kỹ thuật.

---

## S1.1 – Màn hình Đăng nhập

**Route:** `/login`  
**Auth:** Public  
**Component:** `LoginPage`

### Bố cục
Trang đơn giản căn giữa, logo BCT + form đăng nhập.

### Trường nhập liệu
| Field | Type | Validation | Ghi chú |
|-------|------|-----------|---------|
| `username` | text | required, min 3 ký tự | Email hoặc mã cán bộ |
| `password` | password | required, min 8 ký tự | Toggle ẩn/hiện |
| `remember_me` | checkbox | optional | Lưu session 24h |
| `captcha` | widget | Bắt buộc sau 3 lần sai | Google reCAPTCHA v2 |

### Hành động
- **Đăng nhập thường:** POST `/api/auth/login` → nhận JWT → redirect theo role
- **Đăng nhập SSO:** Redirect tới `/api/auth/sso/bct` (OAuth2 SAML Bộ CT)
- **Quên mật khẩu:** Link → modal nhập email → POST `/api/auth/forgot-password`

### Logic redirect sau đăng nhập
```
ADMIN      → /admin/dashboard
BCT_STAFF  → /dashboard
SO_STAFF   → /dashboard  (data scope tự động lọc theo tỉnh)
UNIT_USER  → /surveys    (chỉ thấy phiếu của đơn vị mình)
```

### Xử lý lỗi
- Sai mật khẩu 1–2 lần: hiện thông báo thường
- Sai lần 3: hiện captcha
- Sai lần 5: khoá tài khoản 30 phút, gửi email thông báo

---

## S1.2 – Dashboard Tổng Quan

**Route:** `/dashboard`  
**Auth:** `BCT_STAFF`, `SO_STAFF`, `ADMIN`  
**Component:** `DashboardPage`

### Bố cục (4 khu vực)
```
┌─────────────────────────────────────────────┐
│  KPI Cards (4 thẻ)                          │
├──────────────────────┬──────────────────────┤
│  Biểu đồ cơ cấu HTTM │  Bản đồ minimap      │
├──────────────────────┴──────────────────────┤
│  Danh sách thông báo + nhiệm vụ cần làm     │
└─────────────────────────────────────────────┘
```

### KPI Cards
| Card | API | Ghi chú |
|------|-----|---------|
| Tổng HTTM trong phạm vi | `GET /api/httm/count` | Lọc theo `province_code` nếu là `SO_STAFF` |
| Phiếu KS chờ duyệt | `GET /api/surveys/count?status=submitted` | Chỉ hiện với `BCT_STAFF`+ |
| HTTM cập nhật 30 ngày | `GET /api/httm/count?updated_since=30d` | |
| Tỷ lệ có toạ độ GPS | `GET /api/httm/gps-coverage` | Trả về `{ total, with_gps, percentage }` |

### Biểu đồ
- Cơ cấu loại hình: Pie chart (recharts hoặc Chart.js)
- Phân bổ theo tỉnh: Horizontal bar chart, top 10
- Xu hướng 6 tháng: Line chart

### Thông báo
Lấy từ `GET /api/notifications?unread=true&limit=10`  
Click → đánh dấu đã đọc + redirect tới item liên quan.

---

## S2.1 – Danh Sách Phiếu Khảo Sát

**Route:** `/surveys`  
**Auth:** `BCT_STAFF`, `SO_STAFF`, `ADMIN`  
**Component:** `SurveyListPage`

### Bộ lọc (query params)
| Param | Type | Mô tả |
|-------|------|-------|
| `q` | string | Tìm theo tên đơn vị được KS |
| `status` | enum | `draft\|submitted\|reviewing\|approved\|rejected` |
| `province_code` | string | Mã tỉnh (63 tỉnh thành) |
| `httm_type` | enum | Loại hình HTTM |
| `date_from` / `date_to` | date | Khoảng thời gian tạo/nộp |
| `created_by` | uuid | ID người tạo |
| `page` / `limit` | int | Phân trang, mặc định limit=20 |

### Cột bảng
`Mã phiếu | Tên đơn vị | Tỉnh | Loại hình | Ngày tạo | Ngày nộp | Trạng thái | Người tạo | Hành động`

### Badge trạng thái
```
draft       → màu xám     "Nháp"
submitted   → màu xanh    "Đã nộp"
reviewing   → màu vàng    "Đang duyệt"
approved    → màu xanh lá "Đã duyệt"
rejected    → màu đỏ      "Trả lại"
```

### Hành động theo role
| Hành động | UNIT_USER | SO_STAFF | BCT_STAFF | ADMIN |
|-----------|-----------|----------|-----------|-------|
| Xem | ✓ (chỉ của mình) | ✓ | ✓ | ✓ |
| Tạo mới | ✓ | ✓ | ✓ | ✓ |
| Sửa (draft/rejected) | ✓ | ✓ | ✓ | ✓ |
| Xoá (chỉ draft) | ✓ | ✓ | ✓ | ✓ |
| Duyệt / Trả lại | ✗ | ✗ | ✓ | ✓ |
| Export Excel | ✗ | ✓ | ✓ | ✓ |

### API
```
GET    /api/surveys              # Danh sách có filter + phân trang
POST   /api/surveys              # Tạo phiếu mới (trạng thái draft)
DELETE /api/surveys/:id          # Xoá (chỉ draft)
GET    /api/surveys/export       # Xuất Excel (query params như filter)
```

---

## S2.2 – Form Điền Phiếu Khảo Sát (6 bước)

**Route:** `/surveys/new` | `/surveys/:id/edit`  
**Auth:** Tất cả roles  
**Component:** `SurveyFormPage` → `SurveyStep[1-6]`

### Cấu trúc dữ liệu phiếu (JSON schema tóm tắt)
```json
{
  "id": "uuid",
  "status": "draft",
  "step1_surveyor": { "unit_name": "", "consultant": "", "members": [] },
  "step2_surveyed": { "unit_name": "", "address": "", "tax_code": "", "parent_org": "", "members": [] },
  "step3_general": {
    "unit_types": [],         // mảng enum
    "main_activities": [],    // mảng enum
    "operation_scope": "",
    "parent_unit": "",
    "sub_units": "",
    "legal_documents": [],    // mảng { index, content }
    "staff_count": null,
    "responsible_staff": [],
    "report_tool": [],        // mảng enum
    "report_send_method": []  // mảng enum
  },
  "step4_it": {
    "has_software": false,
    "software_list": [],      // mảng { name, description, integration }
    "desktop_count": null,
    "laptop_count": null,
    "server_description": "",
    "network_types": [],      // mảng enum
    "bandwidth": "",
    "security_measures": [],  // mảng enum
    "security_notes": ""
  },
  "step5_requirements": {
    "info_needs": [],         // mảng enum (18 loại)
    "search_criteria": [],    // mảng enum
    "map_requirements": [],   // mảng enum
    "digitize_processes": "",
    "required_reports": "",
    "required_lookups": ""
  },
  "step6_software_req": {
    "features": [],           // mảng enum (14 chức năng)
    "admin_features": [],
    "external_integrations": "",
    "utilities": [],
    "platforms": [],
    "other_notes": ""
  },
  "step7_opinions": {
    "difficulties": "",
    "advantages": "",
    "proposals": ""
  },
  "confirmer": {
    "name": "", "title": "",
    "reviewer_name": "", "reviewer_title": "",
    "confirmed_date": null
  }
}
```

### Yêu cầu kỹ thuật form
- **Auto-save:** Debounce 60 giây, gọi `PATCH /api/surveys/:id` với partial data
- **Validation:** Chỉ validate bước hiện tại khi nhấn "Tiếp theo"
- **Progress:** Lưu `current_step` vào localStorage và server
- **Nộp phiếu:** Validate toàn bộ 6 bước → POST `/api/surveys/:id/submit`
- **Preview:** Trước khi nộp, hiện modal read-only toàn bộ dữ liệu

### Trường bắt buộc (required) theo bước
```
Bước 1: surveyed.unit_name, surveyed.address
Bước 2: general.unit_types (min 1), general.main_activities (min 1)
Bước 3: (không có required)
Bước 4: (không có required)
Bước 5: (không có required)
Bước 6: confirmer.name, confirmer.confirmed_date
```

### API
```
POST   /api/surveys                    # Tạo phiếu mới, trả về { id }
GET    /api/surveys/:id                # Lấy dữ liệu phiếu (để sửa tiếp)
PATCH  /api/surveys/:id                # Auto-save partial data
POST   /api/surveys/:id/submit         # Nộp chính thức
```

---

## S2.3 – Xem Chi Tiết Phiếu Khảo Sát

**Route:** `/surveys/:id`  
**Auth:** Tất cả roles (tuỳ quyền)  
**Component:** `SurveyDetailPage`

### Bố cục
- **Header:** Mã phiếu, tên đơn vị, badge trạng thái, metadata (người tạo, ngày nộp)
- **Nội dung:** Accordion 6 phần, mỗi phần hiện dữ liệu read-only
- **Sidebar phải:** Timeline duyệt + khung hành động

### Timeline duyệt
Lấy từ `GET /api/surveys/:id/history`  
Hiện các sự kiện: tạo, nộp, duyệt, trả lại kèm tên người thực hiện + ghi chú.

### Hành động
```
[Đã duyệt]  → Nút "Tạo hồ sơ HTTM"   POST /api/httm/from-survey/:id
[Bị trả lại] → Nút "Sửa phiếu"        → redirect S2.2
[Đang duyệt] → Nút "Duyệt" + "Trả lại" (chỉ BCT_STAFF+)
               POST /api/surveys/:id/approve
               POST /api/surveys/:id/reject  body: { reason: "" }
Mọi trạng thái → "Xuất PDF" | "Xuất Excel"
```

---

## S2.4 – Import Phiếu Hàng Loạt

**Route:** `/surveys/import`  
**Auth:** `SO_STAFF`, `BCT_STAFF`, `ADMIN`  
**Component:** `SurveyImportPage`

### Các bước (wizard)
1. Download template Excel (`GET /api/surveys/import/template`)
2. Upload file (`POST /api/surveys/import/validate` → trả danh sách lỗi)
3. Xem preview: bảng dữ liệu hợp lệ + bảng lỗi
4. Xác nhận import (`POST /api/surveys/import/confirm`)
5. Kết quả: X thành công, Y lỗi, link download file lỗi

### Xử lý lỗi import
- Lỗi validation trả về: `{ row: 5, col: "unit_name", error: "Bắt buộc" }`
- Cho phép import "bỏ qua dòng lỗi" (partial import)

---

## S3.1 – Danh Sách Hạ Tầng Thương Mại

**Route:** `/httm`  
**Auth:** `BCT_STAFF`, `SO_STAFF`, `ADMIN` (read-only: public portal)  
**Component:** `HttmListPage`

### Bộ lọc
| Param | Type | Mô tả |
|-------|------|-------|
| `q` | string | Tên HTTM (full-text search) |
| `httm_type` | enum | `market_grade1\|market_grade2\|market_grade3\|supermarket_1\|supermarket_2\|supermarket_3\|mall\|wholesale_market\|convenience_store` |
| `province_code` | string | |
| `district_code` | string | |
| `ward_code` | string | |
| `status` | enum | `active\|suspended\|under_construction\|closed` |
| `area_min` / `area_max` | float | Tổng diện tích m² |
| `stall_min` / `stall_max` | int | Số gian hàng |
| `year_from` / `year_to` | int | Năm đưa vào hoạt động |
| `view` | enum | `table\|grid\|map` | Chế độ hiển thị |

### API
```
GET  /api/httm           # Danh sách + filter + phân trang
POST /api/httm           # Tạo mới
GET  /api/httm/export    # Xuất Excel
GET  /api/httm/map-data  # Trả GeoJSON cho bản đồ
```

---

## S3.2 – Hồ Sơ Chi Tiết HTTM (7 Tab)

**Route:** `/httm/:id`  
**Auth:** Xem: tất cả nội bộ; Sửa: `SO_STAFF`+ (trong phạm vi tỉnh)  
**Component:** `HttmDetailPage`

### Tab 1 – Thông tin chung
```
Tên cơ sở HTTM (*)
Loại hình (*)           → dropdown từ danh mục
Tỉnh / Huyện / Xã (*)  → cascade dropdown
Địa chỉ chi tiết (*)
Năm đưa vào hoạt động
Tình trạng hoạt động (*)
Chủ đầu tư
Đơn vị quản lý
Diện tích đất (m²)
Diện tích sàn KD (m²)
Số gian hàng
Mặt hàng kinh doanh chính  → multi-select từ danh mục
Ghi chú
```

### Tab 2 – Vị trí địa lý
```
Latitude / Longitude    → nhập tay hoặc click trên map picker
Địa chỉ đầy đủ (geocoded)
Gần tuyến đường         → multi-select
Ảnh vệ tinh             → hiện từ Mapbox/Google Maps
```

### Tab 3 – Hạ tầng & Quy mô
```
Số tầng
Diện tích gian hàng TB (m²)
Số chỗ đậu xe
Có hệ thống điện dự phòng   → boolean
Có hệ thống PCCC đạt chuẩn → boolean
Chất lượng công trình       → enum: tốt/trung bình/xuống cấp/cần cải tạo
Năm xây dựng / cải tạo gần nhất
```

### Tab 4 – Kinh doanh
```
Tỷ lệ lấp đầy (%)
Số tiểu thương / hộ KD
Giá thuê mặt bằng TB (triệu/m²/tháng)   → chỉ BCT_STAFF+ xem
Doanh thu ước tính (tỷ/năm)             → chỉ BCT_STAFF+ xem
Hình thức kinh doanh chính
```

### Tab 5 – Pháp lý & Giấy phép
```
Giấy phép KD: số, ngày cấp, ngày hết hạn, file đính kèm
Giấy chứng nhận PCCC: số, ngày cấp, hạn, file
Giấy chứng nhận VSATTP: (nếu có)
Cảnh báo hết hạn: hiện badge đỏ nếu còn < 30 ngày
```

### Tab 6 – Hình ảnh
```
Upload ảnh (multiple, max 10MB/ảnh, định dạng jpg/png/webp)
Phân loại ảnh: mặt ngoài / bên trong / hạ tầng / khác
Ngày chụp
Gallery lightbox khi click
```

### Tab 7 – Lịch sử thay đổi
```
Bảng audit log: Thời gian | Người thực hiện | Thao tác | Trường thay đổi | Giá trị cũ → mới
Lấy từ: GET /api/httm/:id/audit-logs
```

### API
```
GET    /api/httm/:id              # Lấy toàn bộ hồ sơ
PUT    /api/httm/:id              # Cập nhật toàn bộ
PATCH  /api/httm/:id              # Cập nhật một phần (tab cụ thể)
DELETE /api/httm/:id              # Xoá (chỉ ADMIN)
POST   /api/httm/:id/images       # Upload ảnh
DELETE /api/httm/:id/images/:imgId
GET    /api/httm/:id/audit-logs   # Lịch sử thay đổi
```

---

## S3.3 – Quản Lý Danh Mục

**Route:** `/admin/catalogs`  
**Auth:** `ADMIN`  
**Component:** `CatalogManagementPage`

### Danh mục cần quản lý
```
httm_types          Loại hình HTTM
product_categories  Danh mục mặt hàng
administrative      Đơn vị hành chính (tỉnh/huyện/xã) — thường import sẵn
operation_statuses  Trạng thái hoạt động
ownership_types     Loại hình sở hữu
```

### API
```
GET    /api/catalogs/:type           # Lấy danh sách
POST   /api/catalogs/:type           # Thêm mục
PUT    /api/catalogs/:type/:id       # Sửa
DELETE /api/catalogs/:type/:id       # Xoá (kiểm tra usage trước)
POST   /api/catalogs/:type/import    # Import từ Excel
GET    /api/catalogs/:type/export    # Xuất Excel
```

---

## S4.1 – Bản Đồ Nội Bộ (GIS)

**Route:** `/map`  
**Auth:** `BCT_STAFF`, `SO_STAFF`, `ADMIN`  
**Component:** `InternalMapPage`  
**Thư viện:** MapLibre GL JS hoặc Leaflet + PostGIS backend

### Layers
```
Mặc định bật:
  - layer_markets       Chợ (icon: 🏪, màu #E57373 hạng 1, #EF9A9A hạng 2, #FFCDD2 hạng 3)
  - layer_supermarkets  Siêu thị (icon: 🛒, màu #1565C0/1976D2/42A5F5 theo hạng)
  - layer_malls         Trung tâm thương mại (icon: 🏬, màu #6A1B9A)

Mặc định tắt:
  - layer_wholesale     Chợ đầu mối (màu #E65100)
  - layer_convenience   Cửa hàng tiện lợi (màu #2E7D32)
  - layer_heatmap       Heatmap mật độ
  - layer_boundaries    Ranh giới tỉnh/huyện
```

### Popup khi click điểm
```
Hiện: Tên | Loại hình | Địa chỉ | Diện tích | Trạng thái | Ảnh đại diện
Nút: "Xem hồ sơ đầy đủ" → /httm/:id
Nút: "Chỉnh sửa toạ độ" (drag marker)
```

### API cho bản đồ
```
GET /api/httm/map-data?bounds=lng1,lat1,lng2,lat2&types=...
# Trả GeoJSON FeatureCollection, chỉ trả điểm trong viewport
# Dùng clustering khi zoom < 10
```

---

## S4.2 – Bản Đồ Công Khai

**Route:** `/public/map`  
**Auth:** Không cần đăng nhập  
**Component:** `PublicMapPage`

Giống S4.1 nhưng:
- Ẩn: doanh thu, lợi nhuận, thông tin cán bộ, pháp lý
- Không có nút sửa/xoá/thêm
- Thêm nút "Chỉ đường" (mở Google Maps)
- API endpoint riêng: `GET /api/public/httm/map-data`

---

## S5.1 – Dashboard Phân Tích

**Route:** `/analytics`  
**Auth:** `BCT_STAFF`, `SO_STAFF`, `ADMIN`  
**Component:** `AnalyticsDashboardPage`

### Bộ lọc chung (áp dụng cho tất cả biểu đồ)
`Kỳ: tháng/quý/năm/tùy chỉnh` | `Vùng: toàn quốc/vùng/tỉnh` | `Loại hình HTTM`

### Biểu đồ & API
| Biểu đồ | API |
|---------|-----|
| Cơ cấu loại hình (pie) | `GET /api/analytics/httm-by-type` |
| Phân bổ theo tỉnh (bar) | `GET /api/analytics/httm-by-province` |
| Xu hướng theo thời gian (line) | `GET /api/analytics/httm-trend` |
| Bản đồ mật độ (choropleth) | `GET /api/analytics/httm-density-map` |
| Top 10 tỉnh | `GET /api/analytics/top-provinces` |
| Tỷ lệ hoạt động (donut) | `GET /api/analytics/httm-status-ratio` |

### Xuất
```
GET /api/analytics/export/excel
GET /api/analytics/export/pdf
```

---

## S5.2 – Quản Lý Biểu Mẫu Báo Cáo

**Route:** `/admin/report-templates`  
**Auth:** `BCT_STAFF`, `ADMIN`  
**Component:** `ReportTemplateManagementPage`

Chức năng:
- CRUD mẫu báo cáo định kỳ
- Gán mẫu cho tỉnh, thiết lập deadline
- Xem trạng thái nộp báo cáo (đã nộp / chưa nộp / trễ hạn) theo tỉnh
- Nhắc nhở tự động qua email (cron job)

```
GET    /api/report-templates
POST   /api/report-templates
PUT    /api/report-templates/:id
DELETE /api/report-templates/:id
GET    /api/report-templates/:id/submission-status   # Trạng thái theo tỉnh
POST   /api/report-templates/:id/send-reminder       # Gửi nhắc thủ công
```

---

## S6.1 – Quản Trị Hệ Thống

**Route:** `/admin`  
**Auth:** `ADMIN`  
**Component:** `AdminPage` (layout tab)

### Tab: Tài khoản người dùng
```
GET    /api/admin/users                 # Danh sách
POST   /api/admin/users                 # Tạo mới
PUT    /api/admin/users/:id             # Cập nhật (role, province, status)
POST   /api/admin/users/:id/reset-pw    # Reset mật khẩu
POST   /api/admin/users/:id/lock        # Khoá tài khoản
```

### Tab: Audit Log
```
GET /api/admin/audit-logs?user=&action=&from=&to=&page=
```

### Tab: Cấu hình hệ thống
- Lưu vào bảng `system_configs (key, value, description)`
- Key quan trọng: `session_timeout_hours`, `auto_save_interval_sec`, `smtp_*`, `map_default_center`

### Tab: Kết nối API ngoài
```
GET    /api/admin/integrations          # Danh sách kết nối
PUT    /api/admin/integrations/:name    # Cập nhật config
POST   /api/admin/integrations/:name/test  # Kiểm tra kết nối
GET    /api/admin/integrations/:name/logs  # Log giao dịch
```
