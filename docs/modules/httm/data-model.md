# HTTM – Data Model & Schema (PostgreSQL — DEPRECATED)

> ⚠️ **FILE NÀY ĐÃ DEPRECATED — chỉ giữ để tham chiếu business rules / enum.**
>
> Lý do: project dùng **SQL Server `DMPPortal`** dùng chung toàn dự án, không phải PostgreSQL.
> Schema thực tế cho SQL Server: 👉 **[`data-model-sqlserver.md`](./data-model-sqlserver.md)**
> Decision log: [`checklist.md`](./checklist.md) — D1, D2 (2026-05-13).
>
> Các phần dưới đây vẫn hữu ích cho:
> - Tham chiếu **enum values** (`httm_type`, `status`, `image_type`, ...)
> - Tham chiếu **business constraints** (fill_rate 0–100, expiry warning < 30 ngày, ...)
> - So sánh khi cần convert spec PostgreSQL → SQL Server cho domain khác.

---

# (Bản gốc PostgreSQL — không implement)

> Schema PostgreSQL cho domain HTTM. Tất cả bảng đều có prefix `httm_` để tránh xung đột với các domain khác.

---

## Sơ đồ quan hệ (ERD tóm tắt)

```
users ──────────────────────────────────────────┐
  │                                             │
  │ created_by                                  │ created_by
  ▼                                             ▼
httm_surveys ──(approved)──► httm_facilities    │
  │                              │              │
  │ 1:many                       │ 1:many       │
  ▼                              ▼              │
httm_survey_histories     httm_audit_logs ◄─────┘
```

---

## Bảng: `httm_facilities` (Hồ sơ HTTM chính)

```sql
CREATE TABLE httm_facilities (
  id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  -- Thông tin cơ bản
  name                  VARCHAR(500) NOT NULL,
  httm_type             VARCHAR(50)  NOT NULL,  -- enum bên dưới
  status                VARCHAR(30)  NOT NULL DEFAULT 'active',

  -- Địa chỉ hành chính
  province_code         VARCHAR(10)  NOT NULL,  -- Mã tỉnh chuẩn ĐVHCVN
  district_code         VARCHAR(10),
  ward_code             VARCHAR(10),
  address_detail        TEXT,

  -- Vị trí địa lý (PostGIS)
  location              GEOMETRY(Point, 4326),  -- lng/lat WGS84
  gps_accuracy          VARCHAR(20),            -- 'exact'|'approximate'|'none'

  -- Quy mô
  land_area             NUMERIC(12,2),    -- m²
  floor_area            NUMERIC(12,2),    -- m² diện tích sàn KD
  floors                SMALLINT,
  stall_count           INTEGER,
  avg_stall_area        NUMERIC(8,2),     -- m² TB mỗi gian hàng
  parking_slots         INTEGER,

  -- Vận hành
  year_established      SMALLINT,
  year_renovated        SMALLINT,
  owner_name            VARCHAR(500),
  operator_name         VARCHAR(500),
  operator_user_id      UUID REFERENCES users(id),
  fill_rate             NUMERIC(5,2),     -- % 0-100
  vendor_count          INTEGER,

  -- Kinh doanh (chỉ BCT_STAFF+ xem)
  avg_rent_price        NUMERIC(15,2),    -- triệu/m²/tháng
  annual_revenue        NUMERIC(20,2),    -- tỷ VND

  -- Hạ tầng
  has_backup_power      BOOLEAN DEFAULT false,
  has_fire_protection   BOOLEAN DEFAULT false,
  building_quality      VARCHAR(30),      -- 'good'|'average'|'degraded'|'needs_renovation'

  -- Metadata
  source_survey_id      UUID REFERENCES httm_surveys(id),
  notes                 TEXT,
  created_by            UUID NOT NULL REFERENCES users(id),
  updated_by            UUID REFERENCES users(id),
  created_at            TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at            TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Index cho tìm kiếm thường dùng
CREATE INDEX idx_httm_facilities_province   ON httm_facilities(province_code);
CREATE INDEX idx_httm_facilities_type       ON httm_facilities(httm_type);
CREATE INDEX idx_httm_facilities_status     ON httm_facilities(status);
CREATE INDEX idx_httm_facilities_location   ON httm_facilities USING GIST(location);
CREATE INDEX idx_httm_facilities_name_fts   ON httm_facilities USING GIN(to_tsvector('simple', name));
```

### Enum: `httm_type`
```
market_grade1       Chợ hạng I
market_grade2       Chợ hạng II
market_grade3       Chợ hạng III
supermarket_1       Siêu thị hạng I
supermarket_2       Siêu thị hạng II
supermarket_3       Siêu thị hạng III
mall                Trung tâm thương mại
wholesale_market    Chợ đầu mối
convenience_store   Cửa hàng tiện lợi / Bán lẻ hiện đại
other               Loại hình khác
```

### Enum: `status`
```
active              Đang hoạt động
suspended           Tạm ngừng hoạt động
under_construction  Đang xây dựng / cải tạo
closed              Đã đóng cửa
```

---

## Bảng: `httm_facility_products` (Mặt hàng KD chính)

```sql
CREATE TABLE httm_facility_products (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  facility_id   UUID NOT NULL REFERENCES httm_facilities(id) ON DELETE CASCADE,
  category_code VARCHAR(50) NOT NULL,   -- FK tới danh mục mặt hàng
  is_primary    BOOLEAN DEFAULT false,
  notes         TEXT
);
CREATE INDEX ON httm_facility_products(facility_id);
```

---

## Bảng: `httm_facility_images` (Hình ảnh)

```sql
CREATE TABLE httm_facility_images (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  facility_id   UUID NOT NULL REFERENCES httm_facilities(id) ON DELETE CASCADE,
  image_url     TEXT NOT NULL,          -- URL từ MinIO/S3
  image_type    VARCHAR(30) NOT NULL,   -- 'exterior'|'interior'|'infrastructure'|'other'
  caption       TEXT,
  taken_date    DATE,
  sort_order    SMALLINT DEFAULT 0,
  uploaded_by   UUID REFERENCES users(id),
  created_at    TIMESTAMPTZ DEFAULT NOW()
);
```

---

## Bảng: `httm_facility_licenses` (Giấy phép pháp lý)

```sql
CREATE TABLE httm_facility_licenses (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  facility_id     UUID NOT NULL REFERENCES httm_facilities(id) ON DELETE CASCADE,
  license_type    VARCHAR(50) NOT NULL,  -- 'business'|'fire_protection'|'food_safety'|'other'
  license_number  VARCHAR(200),
  issued_date     DATE,
  expiry_date     DATE,
  issued_by       VARCHAR(500),
  file_url        TEXT,                  -- File đính kèm
  notes           TEXT,
  created_at      TIMESTAMPTZ DEFAULT NOW()
);
-- Trigger: cảnh báo khi expiry_date còn < 30 ngày
```

---

## Bảng: `httm_surveys` (Phiếu khảo sát)

```sql
CREATE TABLE httm_surveys (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  survey_code     VARCHAR(50) UNIQUE,    -- KS-2026-HN-0001

  -- Trạng thái
  status          VARCHAR(20) NOT NULL DEFAULT 'draft',
  current_step    SMALLINT DEFAULT 1,

  -- Nội dung phiếu (lưu JSON theo từng bước)
  step1_data      JSONB DEFAULT '{}',    -- Thông tin bên khảo sát
  step2_data      JSONB DEFAULT '{}',    -- Thông tin đơn vị được KS
  step3_data      JSONB DEFAULT '{}',    -- Hiện trạng hoạt động
  step4_data      JSONB DEFAULT '{}',    -- Hạ tầng CNTT
  step5_data      JSONB DEFAULT '{}',    -- Nhu cầu quản lý
  step6_data      JSONB DEFAULT '{}',    -- Yêu cầu phần mềm
  step7_data      JSONB DEFAULT '{}',    -- Ý kiến đề xuất
  confirmer_data  JSONB DEFAULT '{}',    -- Thông tin xác nhận

  -- Liên kết
  province_code   VARCHAR(10),
  linked_facility_id UUID REFERENCES httm_facilities(id),

  -- Metadata
  created_by      UUID NOT NULL REFERENCES users(id),
  submitted_at    TIMESTAMPTZ,
  reviewed_by     UUID REFERENCES users(id),
  reviewed_at     TIMESTAMPTZ,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_httm_surveys_status      ON httm_surveys(status);
CREATE INDEX idx_httm_surveys_province    ON httm_surveys(province_code);
CREATE INDEX idx_httm_surveys_created_by  ON httm_surveys(created_by);
```

### Enum: `status` (phiếu)
```
draft         Nháp
submitted     Đã nộp (chờ duyệt)
reviewing     Đang xét duyệt
approved      Đã duyệt
rejected      Trả lại
```

### Trigger auto-generate `survey_code`
```sql
-- Format: KS-{YEAR}-{PROVINCE_CODE}-{SEQUENCE}
-- Ví dụ: KS-2026-HN-0001
```

---

## Bảng: `httm_survey_histories` (Lịch sử duyệt phiếu)

```sql
CREATE TABLE httm_survey_histories (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  survey_id   UUID NOT NULL REFERENCES httm_surveys(id) ON DELETE CASCADE,
  from_status VARCHAR(20),
  to_status   VARCHAR(20) NOT NULL,
  action      VARCHAR(50) NOT NULL,  -- 'create'|'save'|'submit'|'approve'|'reject'|'reopen'
  notes       TEXT,                  -- Ghi chú khi duyệt/trả lại
  performed_by UUID NOT NULL REFERENCES users(id),
  performed_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX ON httm_survey_histories(survey_id);
```

---

## Bảng: `httm_audit_logs` (Nhật ký thay đổi hồ sơ HTTM)

```sql
CREATE TABLE httm_audit_logs (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  facility_id   UUID NOT NULL REFERENCES httm_facilities(id) ON DELETE CASCADE,
  action        VARCHAR(30) NOT NULL,   -- 'create'|'update'|'delete'|'image_upload'
  changed_fields JSONB,                 -- { field_name: { old: ..., new: ... } }
  performed_by  UUID NOT NULL REFERENCES users(id),
  performed_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  ip_address    INET,
  user_agent    TEXT
);
CREATE INDEX ON httm_audit_logs(facility_id);
CREATE INDEX ON httm_audit_logs(performed_at DESC);
```

---

## Bảng: `httm_catalogs` (Danh mục hệ thống)

```sql
CREATE TABLE httm_catalogs (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  type        VARCHAR(50) NOT NULL,    -- 'httm_types'|'product_categories'|...
  code        VARCHAR(100) NOT NULL,
  name        VARCHAR(500) NOT NULL,
  name_en     VARCHAR(500),
  parent_code VARCHAR(100),            -- Cho danh mục phân cấp
  sort_order  SMALLINT DEFAULT 0,
  is_active   BOOLEAN DEFAULT true,
  metadata    JSONB DEFAULT '{}',
  UNIQUE(type, code)
);
CREATE INDEX ON httm_catalogs(type, is_active);
```

---

## Views hữu ích

```sql
-- View cho bản đồ (trả về GeoJSON-ready)
CREATE VIEW httm_map_view AS
SELECT
  f.id,
  f.name,
  f.httm_type,
  f.status,
  f.province_code,
  f.stall_count,
  f.floor_area,
  ST_X(f.location) AS lng,
  ST_Y(f.location) AS lat,
  f.address_detail,
  (SELECT image_url FROM httm_facility_images
   WHERE facility_id = f.id AND sort_order = 0 LIMIT 1) AS cover_image
FROM httm_facilities f
WHERE f.location IS NOT NULL
  AND f.status != 'closed';

-- View thống kê theo tỉnh
CREATE VIEW httm_stats_by_province AS
SELECT
  province_code,
  httm_type,
  status,
  COUNT(*) AS total,
  AVG(floor_area) AS avg_floor_area,
  SUM(stall_count) AS total_stalls
FROM httm_facilities
GROUP BY province_code, httm_type, status;
```

---

## Migrations gợi ý

```
migrations/
  001_create_httm_facilities.sql
  002_create_httm_surveys.sql
  003_create_httm_survey_histories.sql
  004_create_httm_audit_logs.sql
  005_create_httm_catalogs.sql
  006_create_httm_facility_products.sql
  007_create_httm_facility_images.sql
  008_create_httm_facility_licenses.sql
  009_create_httm_views.sql
  010_seed_httm_catalogs.sql
```
