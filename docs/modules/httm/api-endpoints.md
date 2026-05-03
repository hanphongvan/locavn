# HTTM – API Endpoints Reference

> Tất cả endpoint đều có prefix `/api/httm` trừ khi ghi rõ khác.  
> Auth header: `Authorization: Bearer <JWT>`  
> Response format chuẩn: `{ success: bool, data: ..., meta: { page, limit, total } }`

---

## Auth & Session

```
POST   /api/auth/login                  # Đăng nhập, trả JWT
POST   /api/auth/logout                 # Huỷ phiên
POST   /api/auth/refresh                # Làm mới token
POST   /api/auth/forgot-password        # Gửi OTP reset mật khẩu
POST   /api/auth/reset-password         # Đặt mật khẩu mới bằng OTP
GET    /api/auth/me                     # Thông tin người dùng hiện tại
GET    /api/auth/sso/bct                # Bắt đầu SSO flow Bộ CT
GET    /api/auth/sso/bct/callback       # SSO callback
```

---

## Dashboard & Thống kê nhanh

```
GET /api/dashboard/kpis
# Response: { httm_total, surveys_pending, httm_updated_30d, gps_coverage_pct }
# Query params: province_code (nếu SO_STAFF)

GET /api/dashboard/charts/httm-by-type
GET /api/dashboard/charts/httm-by-province?limit=10
GET /api/dashboard/charts/httm-trend?months=6

GET /api/notifications?unread=true&limit=10
POST /api/notifications/:id/read
POST /api/notifications/read-all
```

---

## Phiếu Khảo Sát `/api/surveys`

```
GET    /api/surveys
  Query: q, status, province_code, httm_type, date_from, date_to, created_by, page, limit
  Auth: BCT_STAFF, SO_STAFF, ADMIN (UNIT_USER chỉ thấy của mình)

POST   /api/surveys
  Body: { province_code, httm_type }   # Tạo phiếu mới rỗng, trả về { id, survey_code }
  Auth: Tất cả

GET    /api/surveys/:id
  Auth: Tất cả (kiểm tra quyền xem)

PATCH  /api/surveys/:id
  Body: Partial survey data (step1_data đến confirmer_data)
  Auth: Người tạo (nếu draft/rejected)
  Ghi chú: Auto-save, không thay đổi status

POST   /api/surveys/:id/submit
  Auth: Người tạo (nếu draft/rejected)
  Effect: status → 'submitted', ghi history

POST   /api/surveys/:id/approve
  Body: { notes? }
  Auth: BCT_STAFF, ADMIN
  Effect: status → 'approved'

POST   /api/surveys/:id/reject
  Body: { reason: string }   # Bắt buộc
  Auth: BCT_STAFF, ADMIN
  Effect: status → 'rejected'

DELETE /api/surveys/:id
  Auth: Người tạo (chỉ draft) hoặc ADMIN

GET    /api/surveys/:id/history
  Response: Array của httm_survey_histories

GET    /api/surveys/export
  Query: Giống GET /api/surveys
  Response: Excel file stream
  Auth: SO_STAFF+

POST   /api/surveys/import/validate
  Body: multipart/form-data, file=<Excel>
  Response: { valid_rows: [...], errors: [{ row, col, message }] }

POST   /api/surveys/import/confirm
  Body: { session_token }   # Token từ bước validate
  Response: { imported, skipped, errors }

GET    /api/surveys/import/template
  Response: Excel template download
```

---

## Hồ Sơ HTTM `/api/httm`

```
GET    /api/httm
  Query: q, httm_type, province_code, district_code, ward_code,
         status, area_min, area_max, stall_min, stall_max,
         year_from, year_to, page, limit
  Auth: BCT_STAFF, SO_STAFF, ADMIN

POST   /api/httm
  Body: httm_facility object (xem data-model.md)
  Auth: SO_STAFF+

GET    /api/httm/:id
  Auth: BCT_STAFF, SO_STAFF, ADMIN
  Ghi chú: Trường nhạy cảm (avg_rent_price, annual_revenue) chỉ trả về cho BCT_STAFF+

PUT    /api/httm/:id
  Body: Toàn bộ httm_facility
  Auth: SO_STAFF+ (trong tỉnh) hoặc ADMIN

PATCH  /api/httm/:id
  Body: Partial update (ví dụ chỉ 1 tab)
  Auth: SO_STAFF+ (trong tỉnh) hoặc ADMIN

DELETE /api/httm/:id
  Auth: ADMIN only

# Từ phiếu khảo sát đã duyệt
POST   /api/httm/from-survey/:survey_id
  Auth: BCT_STAFF, ADMIN
  Effect: Tạo facility từ dữ liệu phiếu đã approve

# Hình ảnh
POST   /api/httm/:id/images
  Body: multipart/form-data
  Auth: SO_STAFF+

DELETE /api/httm/:id/images/:image_id
  Auth: SO_STAFF+

# Giấy phép
GET    /api/httm/:id/licenses
POST   /api/httm/:id/licenses
PUT    /api/httm/:id/licenses/:license_id
DELETE /api/httm/:id/licenses/:license_id

# Audit log
GET    /api/httm/:id/audit-logs?page=&limit=

# Export
GET    /api/httm/export
  Query: Giống GET /api/httm
  Response: Excel file

# Dữ liệu bản đồ
GET    /api/httm/map-data
  Query: bounds=west,south,east,north&types=&province_code=
  Response: GeoJSON FeatureCollection
  Ghi chú: Clustering tự động khi có > 500 điểm trong viewport
```

---

## Bản Đồ Công Khai (không cần auth)

```
GET /api/public/httm/map-data
  Query: bounds, types, province_code
  Response: GeoJSON (đã lọc trường nhạy cảm)

GET /api/public/httm/:id/summary
  Response: Thông tin cơ bản (không có doanh thu, pháp lý)
```

---

## Analytics `/api/analytics`

```
GET /api/analytics/httm-by-type?province_code=&status=
GET /api/analytics/httm-by-province?limit=10&httm_type=
GET /api/analytics/httm-trend?months=6&province_code=
GET /api/analytics/httm-density-map          # GeoJSON choropleth theo tỉnh
GET /api/analytics/top-provinces?limit=10
GET /api/analytics/httm-status-ratio?province_code=
GET /api/analytics/export/excel              # Query params như trên
GET /api/analytics/export/pdf
```

---

## Danh Mục `/api/catalogs`

```
GET    /api/catalogs/:type               # type: httm_types|product_categories|...
POST   /api/catalogs/:type               # Auth: ADMIN
PUT    /api/catalogs/:type/:id           # Auth: ADMIN
DELETE /api/catalogs/:type/:id           # Auth: ADMIN (kiểm tra usage)
POST   /api/catalogs/:type/import        # Auth: ADMIN
GET    /api/catalogs/:type/export        # Auth: ADMIN

# Đơn vị hành chính (thường chỉ đọc)
GET /api/catalogs/provinces
GET /api/catalogs/districts?province_code=
GET /api/catalogs/wards?district_code=
```

---

## Admin `/api/admin`

```
# Người dùng
GET    /api/admin/users?q=&role=&province_code=&page=
POST   /api/admin/users
PUT    /api/admin/users/:id
POST   /api/admin/users/:id/reset-password
POST   /api/admin/users/:id/lock
POST   /api/admin/users/:id/unlock

# Audit log hệ thống
GET /api/admin/audit-logs?user_id=&action=&from=&to=&page=

# Cấu hình hệ thống
GET /api/admin/configs
PUT /api/admin/configs/:key

# Tích hợp bên ngoài
GET    /api/admin/integrations
PUT    /api/admin/integrations/:name
POST   /api/admin/integrations/:name/test
GET    /api/admin/integrations/:name/logs
```

---

## Mã lỗi chuẩn

| HTTP | Code | Mô tả |
|------|------|-------|
| 400 | VALIDATION_ERROR | Dữ liệu đầu vào không hợp lệ |
| 401 | UNAUTHORIZED | Chưa đăng nhập |
| 403 | FORBIDDEN | Không có quyền |
| 403 | SCOPE_VIOLATION | Cố truy cập dữ liệu ngoài phạm vi tỉnh |
| 404 | NOT_FOUND | Tài nguyên không tồn tại |
| 409 | SURVEY_NOT_DRAFT | Phiếu không ở trạng thái cho phép sửa |
| 409 | ALREADY_LINKED | Phiếu đã được tạo hồ sơ HTTM |
| 422 | IMPORT_VALIDATION | Lỗi validate khi import Excel |
| 500 | INTERNAL_ERROR | Lỗi server |

---

## Ghi chú quan trọng

- **Phân cấp địa lý:** `SO_STAFF` chỉ truy cập được dữ liệu có `province_code` khớp với `user.province_codes[]`. Backend PHẢI enforce điều này, không phụ thuộc vào frontend.
- **Sensitive fields:** `avg_rent_price`, `annual_revenue` không được trả về trong response nếu role là `SO_STAFF` hoặc `UNIT_USER`.
- **Audit:** Mọi `POST/PUT/PATCH/DELETE` trên `/api/httm/:id` phải ghi vào `httm_audit_logs`.
- **GeoJSON:** Endpoint `/map-data` dùng PostGIS `ST_AsGeoJSON()` + spatial index. Đặt giới hạn `MAX 2000` features per request, ngoài ra dùng clustering.
