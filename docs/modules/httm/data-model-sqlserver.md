# HTTM – Data Model & Schema (SQL Server)

> **Đây là tài liệu schema chính thức cho domain HTTM.**
> Sử dụng SQL Server `DMPPortal` dùng chung toàn dự án (Decision D1, D2 trong [`checklist.md`](./checklist.md)).
> File [`data-model.md`](./data-model.md) là bản PostgreSQL gốc (deprecated — chỉ dùng để tham chiếu enum/business rules).

---

## Quy ước SQL Server

| PostgreSQL (spec gốc) | SQL Server (thực tế) | Ghi chú |
|-----------------------|----------------------|---------|
| `UUID DEFAULT gen_random_uuid()` | `UNIQUEIDENTIFIER DEFAULT NEWSEQUENTIALID()` | `NEWSEQUENTIALID` cho clustered index perf; dùng `NEWID()` nếu cần ngẫu nhiên |
| `VARCHAR(N)` | `NVARCHAR(N)` | Vietnamese unicode |
| `TEXT` | `NVARCHAR(MAX)` | |
| `JSONB` | `NVARCHAR(MAX) CHECK (ISJSON(col)=1)` | Truy vấn qua `JSON_VALUE`, `JSON_QUERY` |
| `BOOLEAN` | `BIT` | |
| `TIMESTAMPTZ` | `DATETIMEOFFSET(7)` | Lưu kèm timezone |
| `NUMERIC(p,s)` | `DECIMAL(p,s)` | |
| `SMALLINT` / `INTEGER` | `SMALLINT` / `INT` | |
| `INET` | `VARCHAR(45)` | Đủ cho IPv6 |
| `GEOMETRY(Point, 4326)` | `GEOGRAPHY` | SQL Server native, SRID 4326 |
| `GIST(location)` | `SPATIAL INDEX ON (location)` | Spatial index |
| `GIN(to_tsvector(...))` | `FULLTEXT INDEX ON ...` | Full-text catalog |
| `ON DELETE CASCADE` | `ON DELETE CASCADE` | Same |

**Naming**: PascalCase cho table, snake_case cho cột là pattern hỗn hợp đang dùng trong project. Schema HTTM sẽ thống nhất **PascalCase cho table, PascalCase cho cột** để đồng bộ với entity .NET. Tên cũ `httm_*` (snake) trong spec gốc → đổi thành `Httm*`.

| Spec gốc (snake) | SQL Server (Pascal) |
|------------------|---------------------|
| `httm_facilities` | `HttmFacilities` |
| `httm_facility_products` | `HttmFacilityProducts` |
| `httm_facility_images` | `HttmFacilityImages` |
| `httm_facility_licenses` | `HttmFacilityLicenses` |
| `httm_surveys` | `HttmSurveys` |
| `httm_survey_histories` | `HttmSurveyHistories` |
| `httm_audit_logs` | `HttmAuditLogs` |
| `httm_catalogs` | `HttmCatalogs` |

---

## ERD tóm tắt

```
AspNetUsers (existing) ─────────────────────────────────┐
   │ CreatedBy                                          │
   ▼                                                    │
HttmSurveys ──(approved)──► HttmFacilities              │
   │                              │                     │
   │ 1:N                          │ 1:N                 │
   ▼                              ▼                     │
HttmSurveyHistories        HttmAuditLogs ◄──────────────┘
                                  ▲
                                  │
   HttmFacilityProducts ──────────┤
   HttmFacilityImages   ──────────┤
   HttmFacilityLicenses ──────────┘
```

---

## Bảng: `HttmFacilities` (Hồ sơ HTTM chính)

```sql
CREATE TABLE dbo.HttmFacilities (
  Id                    UNIQUEIDENTIFIER NOT NULL DEFAULT NEWSEQUENTIALID(),

  -- Thông tin cơ bản
  Name                  NVARCHAR(500)    NOT NULL,
  HttmType              VARCHAR(50)      NOT NULL,
  Status                VARCHAR(30)      NOT NULL CONSTRAINT DF_HttmFacilities_Status DEFAULT ('active'),

  -- Địa chỉ hành chính
  ProvinceCode          VARCHAR(10)      NOT NULL,
  DistrictCode          VARCHAR(10)      NULL,
  WardCode              VARCHAR(10)      NULL,
  AddressDetail         NVARCHAR(MAX)    NULL,

  -- Vị trí địa lý
  Location              GEOGRAPHY        NULL,            -- SRID 4326, POINT(lng lat)
  GpsAccuracy           VARCHAR(20)      NULL,            -- 'exact'|'approximate'|'none'

  -- Quy mô
  LandArea              DECIMAL(12, 2)   NULL,            -- m²
  FloorArea             DECIMAL(12, 2)   NULL,            -- m² sàn KD
  Floors                SMALLINT         NULL,
  StallCount            INT              NULL,
  AvgStallArea          DECIMAL(8, 2)    NULL,            -- m² TB
  ParkingSlots          INT              NULL,

  -- Vận hành
  YearEstablished       SMALLINT         NULL,
  YearRenovated         SMALLINT         NULL,
  OwnerName             NVARCHAR(500)    NULL,
  OperatorName          NVARCHAR(500)    NULL,
  OperatorUserId        UNIQUEIDENTIFIER NULL,            -- FK AspNetUsers.Id (lưu ý: AspNetUsers dùng NVARCHAR(450) cho Id mặc định — cần align)
  FillRate              DECIMAL(5, 2)    NULL,            -- % 0–100
  VendorCount           INT              NULL,

  -- Kinh doanh (sensitive — chỉ ADMIN/HTTM_ADMIN/BCT_STAFF xem)
  AvgRentPrice          DECIMAL(15, 2)   NULL,            -- triệu/m²/tháng
  AnnualRevenue         DECIMAL(20, 2)   NULL,            -- tỷ VND

  -- Hạ tầng
  HasBackupPower        BIT              NOT NULL CONSTRAINT DF_HttmFacilities_BackupPower DEFAULT (0),
  HasFireProtection     BIT              NOT NULL CONSTRAINT DF_HttmFacilities_FireProt    DEFAULT (0),
  BuildingQuality       VARCHAR(30)      NULL,            -- 'good'|'average'|'degraded'|'needs_renovation'

  -- Metadata
  SourceSurveyId        UNIQUEIDENTIFIER NULL,            -- FK HttmSurveys.Id (nullable)
  Notes                 NVARCHAR(MAX)    NULL,
  CreatedBy             NVARCHAR(450)    NOT NULL,        -- FK AspNetUsers.Id
  UpdatedBy             NVARCHAR(450)    NULL,
  CreatedAt             DATETIMEOFFSET(7) NOT NULL CONSTRAINT DF_HttmFacilities_CreatedAt DEFAULT (SYSDATETIMEOFFSET()),
  UpdatedAt             DATETIMEOFFSET(7) NOT NULL CONSTRAINT DF_HttmFacilities_UpdatedAt DEFAULT (SYSDATETIMEOFFSET()),

  CONSTRAINT PK_HttmFacilities PRIMARY KEY CLUSTERED (Id),
  CONSTRAINT FK_HttmFacilities_AspNetUsers_CreatedBy FOREIGN KEY (CreatedBy) REFERENCES dbo.AspNetUsers(Id),
  CONSTRAINT FK_HttmFacilities_AspNetUsers_UpdatedBy FOREIGN KEY (UpdatedBy) REFERENCES dbo.AspNetUsers(Id),
  CONSTRAINT CK_HttmFacilities_HttmType CHECK (HttmType IN (
    'market_grade1','market_grade2','market_grade3',
    'supermarket_1','supermarket_2','supermarket_3',
    'mall','wholesale_market','convenience_store','other'
  )),
  CONSTRAINT CK_HttmFacilities_Status CHECK (Status IN (
    'active','suspended','under_construction','closed'
  )),
  CONSTRAINT CK_HttmFacilities_FillRate CHECK (FillRate IS NULL OR (FillRate BETWEEN 0 AND 100))
);
GO

CREATE INDEX IX_HttmFacilities_ProvinceCode ON dbo.HttmFacilities(ProvinceCode);
CREATE INDEX IX_HttmFacilities_HttmType     ON dbo.HttmFacilities(HttmType);
CREATE INDEX IX_HttmFacilities_Status       ON dbo.HttmFacilities(Status);
CREATE INDEX IX_HttmFacilities_UpdatedAt    ON dbo.HttmFacilities(UpdatedAt DESC);
GO

-- Spatial index (yêu cầu bounding box)
CREATE SPATIAL INDEX SIX_HttmFacilities_Location ON dbo.HttmFacilities(Location)
USING GEOGRAPHY_GRID
WITH (
  GRIDS = (LEVEL_1 = MEDIUM, LEVEL_2 = MEDIUM, LEVEL_3 = MEDIUM, LEVEL_4 = MEDIUM),
  CELLS_PER_OBJECT = 16
);
GO

-- Full-text (cần FULLTEXT CATALOG đã tạo trước)
-- CREATE FULLTEXT CATALOG ftHttm AS DEFAULT;
CREATE FULLTEXT INDEX ON dbo.HttmFacilities(Name LANGUAGE 1066) -- 1066 = Vietnamese
KEY INDEX PK_HttmFacilities
WITH STOPLIST = SYSTEM, CHANGE_TRACKING AUTO;
GO
```

### Enum: `HttmType`
| Code | Tên tiếng Việt |
|------|----------------|
| `market_grade1` | Chợ hạng I |
| `market_grade2` | Chợ hạng II |
| `market_grade3` | Chợ hạng III |
| `supermarket_1` | Siêu thị hạng I |
| `supermarket_2` | Siêu thị hạng II |
| `supermarket_3` | Siêu thị hạng III |
| `mall` | Trung tâm thương mại |
| `wholesale_market` | Chợ đầu mối |
| `convenience_store` | Cửa hàng tiện lợi / Bán lẻ hiện đại |
| `other` | Loại hình khác |

### Enum: `Status`
| Code | Tên tiếng Việt |
|------|----------------|
| `active` | Đang hoạt động |
| `suspended` | Tạm ngừng hoạt động |
| `under_construction` | Đang xây dựng / cải tạo |
| `closed` | Đã đóng cửa |

---

## Bảng: `HttmFacilityProducts` (Mặt hàng KD chính)

```sql
CREATE TABLE dbo.HttmFacilityProducts (
  Id            UNIQUEIDENTIFIER NOT NULL DEFAULT NEWSEQUENTIALID(),
  FacilityId    UNIQUEIDENTIFIER NOT NULL,
  CategoryCode  VARCHAR(50)      NOT NULL,
  IsPrimary     BIT              NOT NULL CONSTRAINT DF_HttmFacilityProducts_IsPrimary DEFAULT (0),
  Notes         NVARCHAR(MAX)    NULL,

  CONSTRAINT PK_HttmFacilityProducts PRIMARY KEY CLUSTERED (Id),
  CONSTRAINT FK_HttmFacilityProducts_HttmFacilities FOREIGN KEY (FacilityId)
    REFERENCES dbo.HttmFacilities(Id) ON DELETE CASCADE
);
CREATE INDEX IX_HttmFacilityProducts_FacilityId ON dbo.HttmFacilityProducts(FacilityId);
GO
```

---

## Bảng: `HttmFacilityImages`

```sql
CREATE TABLE dbo.HttmFacilityImages (
  Id            UNIQUEIDENTIFIER NOT NULL DEFAULT NEWSEQUENTIALID(),
  FacilityId    UNIQUEIDENTIFIER NOT NULL,
  ImageUrl      NVARCHAR(2000)   NOT NULL,                    -- URL MinIO/S3/local
  ImageType     VARCHAR(30)      NOT NULL,                    -- 'exterior'|'interior'|'infrastructure'|'other'
  Caption       NVARCHAR(MAX)    NULL,
  TakenDate     DATE             NULL,
  SortOrder     SMALLINT         NOT NULL DEFAULT (0),
  UploadedBy    NVARCHAR(450)    NULL,
  CreatedAt     DATETIMEOFFSET(7) NOT NULL DEFAULT (SYSDATETIMEOFFSET()),

  CONSTRAINT PK_HttmFacilityImages PRIMARY KEY CLUSTERED (Id),
  CONSTRAINT FK_HttmFacilityImages_HttmFacilities FOREIGN KEY (FacilityId)
    REFERENCES dbo.HttmFacilities(Id) ON DELETE CASCADE,
  CONSTRAINT FK_HttmFacilityImages_AspNetUsers FOREIGN KEY (UploadedBy)
    REFERENCES dbo.AspNetUsers(Id),
  CONSTRAINT CK_HttmFacilityImages_Type CHECK (
    ImageType IN ('exterior','interior','infrastructure','other')
  )
);
CREATE INDEX IX_HttmFacilityImages_FacilityId_Sort
  ON dbo.HttmFacilityImages(FacilityId, SortOrder);
GO
```

---

## Bảng: `HttmFacilityLicenses` (Giấy phép pháp lý)

```sql
CREATE TABLE dbo.HttmFacilityLicenses (
  Id              UNIQUEIDENTIFIER NOT NULL DEFAULT NEWSEQUENTIALID(),
  FacilityId      UNIQUEIDENTIFIER NOT NULL,
  LicenseType     VARCHAR(50)      NOT NULL,                  -- 'business'|'fire_protection'|'food_safety'|'other'
  LicenseNumber   NVARCHAR(200)    NULL,
  IssuedDate      DATE             NULL,
  ExpiryDate      DATE             NULL,
  IssuedBy        NVARCHAR(500)    NULL,
  FileUrl         NVARCHAR(2000)   NULL,
  Notes           NVARCHAR(MAX)    NULL,
  CreatedAt       DATETIMEOFFSET(7) NOT NULL DEFAULT (SYSDATETIMEOFFSET()),

  CONSTRAINT PK_HttmFacilityLicenses PRIMARY KEY CLUSTERED (Id),
  CONSTRAINT FK_HttmFacilityLicenses_HttmFacilities FOREIGN KEY (FacilityId)
    REFERENCES dbo.HttmFacilities(Id) ON DELETE CASCADE,
  CONSTRAINT CK_HttmFacilityLicenses_Type CHECK (
    LicenseType IN ('business','fire_protection','food_safety','other')
  )
);
CREATE INDEX IX_HttmFacilityLicenses_FacilityId ON dbo.HttmFacilityLicenses(FacilityId);
CREATE INDEX IX_HttmFacilityLicenses_Expiry     ON dbo.HttmFacilityLicenses(ExpiryDate) WHERE ExpiryDate IS NOT NULL;
GO
```

> **Cảnh báo expiry**: implement ở service layer (cron job hoặc query lúc load). Không dùng SQL Trigger (rủi ro hiệu năng).

---

## Bảng: `HttmSurveys` (Phiếu khảo sát — Phase 2)

```sql
CREATE TABLE dbo.HttmSurveys (
  Id              UNIQUEIDENTIFIER NOT NULL DEFAULT NEWSEQUENTIALID(),
  SurveyCode      VARCHAR(50)      NOT NULL,                  -- KS-2026-HN-0001

  Status          VARCHAR(20)      NOT NULL CONSTRAINT DF_HttmSurveys_Status DEFAULT ('draft'),
  CurrentStep     SMALLINT         NOT NULL CONSTRAINT DF_HttmSurveys_Step DEFAULT (1),

  -- JSON payload từng bước (validate ISJSON)
  Step1Data       NVARCHAR(MAX)    NOT NULL CONSTRAINT DF_HttmSurveys_Step1 DEFAULT ('{}'),
  Step2Data       NVARCHAR(MAX)    NOT NULL CONSTRAINT DF_HttmSurveys_Step2 DEFAULT ('{}'),
  Step3Data       NVARCHAR(MAX)    NOT NULL CONSTRAINT DF_HttmSurveys_Step3 DEFAULT ('{}'),
  Step4Data       NVARCHAR(MAX)    NOT NULL CONSTRAINT DF_HttmSurveys_Step4 DEFAULT ('{}'),
  Step5Data       NVARCHAR(MAX)    NOT NULL CONSTRAINT DF_HttmSurveys_Step5 DEFAULT ('{}'),
  Step6Data       NVARCHAR(MAX)    NOT NULL CONSTRAINT DF_HttmSurveys_Step6 DEFAULT ('{}'),
  Step7Data       NVARCHAR(MAX)    NOT NULL CONSTRAINT DF_HttmSurveys_Step7 DEFAULT ('{}'),
  ConfirmerData   NVARCHAR(MAX)    NOT NULL CONSTRAINT DF_HttmSurveys_Conf  DEFAULT ('{}'),

  ProvinceCode    VARCHAR(10)      NULL,
  LinkedFacilityId UNIQUEIDENTIFIER NULL,

  CreatedBy       NVARCHAR(450)    NOT NULL,
  SubmittedAt     DATETIMEOFFSET(7) NULL,
  ReviewedBy      NVARCHAR(450)    NULL,
  ReviewedAt      DATETIMEOFFSET(7) NULL,
  CreatedAt       DATETIMEOFFSET(7) NOT NULL DEFAULT (SYSDATETIMEOFFSET()),
  UpdatedAt       DATETIMEOFFSET(7) NOT NULL DEFAULT (SYSDATETIMEOFFSET()),

  CONSTRAINT PK_HttmSurveys PRIMARY KEY CLUSTERED (Id),
  CONSTRAINT UQ_HttmSurveys_SurveyCode UNIQUE (SurveyCode),
  CONSTRAINT FK_HttmSurveys_AspNetUsers_CreatedBy FOREIGN KEY (CreatedBy) REFERENCES dbo.AspNetUsers(Id),
  CONSTRAINT FK_HttmSurveys_AspNetUsers_ReviewedBy FOREIGN KEY (ReviewedBy) REFERENCES dbo.AspNetUsers(Id),
  CONSTRAINT FK_HttmSurveys_HttmFacilities FOREIGN KEY (LinkedFacilityId) REFERENCES dbo.HttmFacilities(Id),
  CONSTRAINT CK_HttmSurveys_Status CHECK (Status IN ('draft','submitted','reviewing','approved','rejected')),
  CONSTRAINT CK_HttmSurveys_Step1Json CHECK (ISJSON(Step1Data) = 1),
  CONSTRAINT CK_HttmSurveys_Step2Json CHECK (ISJSON(Step2Data) = 1),
  CONSTRAINT CK_HttmSurveys_Step3Json CHECK (ISJSON(Step3Data) = 1),
  CONSTRAINT CK_HttmSurveys_Step4Json CHECK (ISJSON(Step4Data) = 1),
  CONSTRAINT CK_HttmSurveys_Step5Json CHECK (ISJSON(Step5Data) = 1),
  CONSTRAINT CK_HttmSurveys_Step6Json CHECK (ISJSON(Step6Data) = 1),
  CONSTRAINT CK_HttmSurveys_Step7Json CHECK (ISJSON(Step7Data) = 1),
  CONSTRAINT CK_HttmSurveys_ConfirmerJson CHECK (ISJSON(ConfirmerData) = 1)
);
CREATE INDEX IX_HttmSurveys_Status       ON dbo.HttmSurveys(Status);
CREATE INDEX IX_HttmSurveys_ProvinceCode ON dbo.HttmSurveys(ProvinceCode);
CREATE INDEX IX_HttmSurveys_CreatedBy    ON dbo.HttmSurveys(CreatedBy);
GO

-- Sau khi tạo bảng HttmFacilities, thêm FK ngược lại
ALTER TABLE dbo.HttmFacilities
ADD CONSTRAINT FK_HttmFacilities_HttmSurveys
  FOREIGN KEY (SourceSurveyId) REFERENCES dbo.HttmSurveys(Id);
GO
```

### Trigger auto-generate `SurveyCode` (Phase 2)

```sql
-- Format: KS-{YYYY}-{PROVINCE_CODE}-{SEQ}
-- Ví dụ: KS-2026-HN-0001
-- Implement: dùng sequence per (year, province), KHÔNG dùng TRIGGER (rủi ro deadlock).
-- Đề xuất: tạo bảng phụ HttmSurveyCounters(Year, ProvinceCode, NextSeq)
--          và sinh code trong SP sp_Httm_Survey_Insert
CREATE TABLE dbo.HttmSurveyCounters (
  Year          SMALLINT     NOT NULL,
  ProvinceCode  VARCHAR(10)  NOT NULL,
  NextSeq       INT          NOT NULL DEFAULT (1),
  CONSTRAINT PK_HttmSurveyCounters PRIMARY KEY (Year, ProvinceCode)
);
GO
```

---

## Bảng: `HttmSurveyHistories` (Lịch sử duyệt phiếu)

```sql
CREATE TABLE dbo.HttmSurveyHistories (
  Id           UNIQUEIDENTIFIER NOT NULL DEFAULT NEWSEQUENTIALID(),
  SurveyId     UNIQUEIDENTIFIER NOT NULL,
  FromStatus   VARCHAR(20)      NULL,
  ToStatus     VARCHAR(20)      NOT NULL,
  Action       VARCHAR(50)      NOT NULL,                    -- 'create'|'save'|'submit'|'approve'|'reject'|'reopen'
  Notes        NVARCHAR(MAX)    NULL,
  PerformedBy  NVARCHAR(450)    NOT NULL,
  PerformedAt  DATETIMEOFFSET(7) NOT NULL DEFAULT (SYSDATETIMEOFFSET()),

  CONSTRAINT PK_HttmSurveyHistories PRIMARY KEY CLUSTERED (Id),
  CONSTRAINT FK_HttmSurveyHistories_HttmSurveys FOREIGN KEY (SurveyId)
    REFERENCES dbo.HttmSurveys(Id) ON DELETE CASCADE,
  CONSTRAINT FK_HttmSurveyHistories_AspNetUsers FOREIGN KEY (PerformedBy)
    REFERENCES dbo.AspNetUsers(Id)
);
CREATE INDEX IX_HttmSurveyHistories_SurveyId ON dbo.HttmSurveyHistories(SurveyId, PerformedAt DESC);
GO
```

---

## Bảng: `HttmAuditLogs` (Nhật ký thay đổi hồ sơ HTTM)

```sql
CREATE TABLE dbo.HttmAuditLogs (
  Id             UNIQUEIDENTIFIER NOT NULL DEFAULT NEWSEQUENTIALID(),
  FacilityId     UNIQUEIDENTIFIER NOT NULL,
  Action         VARCHAR(30)      NOT NULL,                  -- 'create'|'update'|'delete'|'image_upload'|'image_delete'|'license_change'
  ChangedFields  NVARCHAR(MAX)    NULL,                      -- JSON { field: { old, new } }
  PerformedBy    NVARCHAR(450)    NOT NULL,
  PerformedAt    DATETIMEOFFSET(7) NOT NULL DEFAULT (SYSDATETIMEOFFSET()),
  IpAddress      VARCHAR(45)      NULL,
  UserAgent      NVARCHAR(500)    NULL,

  CONSTRAINT PK_HttmAuditLogs PRIMARY KEY CLUSTERED (Id),
  CONSTRAINT FK_HttmAuditLogs_HttmFacilities FOREIGN KEY (FacilityId)
    REFERENCES dbo.HttmFacilities(Id) ON DELETE CASCADE,
  CONSTRAINT FK_HttmAuditLogs_AspNetUsers FOREIGN KEY (PerformedBy)
    REFERENCES dbo.AspNetUsers(Id),
  CONSTRAINT CK_HttmAuditLogs_ChangedFieldsJson
    CHECK (ChangedFields IS NULL OR ISJSON(ChangedFields) = 1)
);
CREATE INDEX IX_HttmAuditLogs_FacilityId  ON dbo.HttmAuditLogs(FacilityId, PerformedAt DESC);
CREATE INDEX IX_HttmAuditLogs_PerformedAt ON dbo.HttmAuditLogs(PerformedAt DESC);
GO
```

---

## Bảng: `HttmCatalogs` (Danh mục hệ thống)

```sql
CREATE TABLE dbo.HttmCatalogs (
  Id          UNIQUEIDENTIFIER NOT NULL DEFAULT NEWSEQUENTIALID(),
  [Type]      VARCHAR(50)      NOT NULL,                    -- 'httm_types'|'product_categories'|'building_quality'|...
  Code        VARCHAR(100)     NOT NULL,
  Name        NVARCHAR(500)    NOT NULL,
  NameEn      NVARCHAR(500)    NULL,
  ParentCode  VARCHAR(100)     NULL,
  SortOrder   SMALLINT         NOT NULL DEFAULT (0),
  IsActive    BIT              NOT NULL DEFAULT (1),
  Metadata    NVARCHAR(MAX)    NULL,                        -- JSON

  CONSTRAINT PK_HttmCatalogs PRIMARY KEY CLUSTERED (Id),
  CONSTRAINT UQ_HttmCatalogs_TypeCode UNIQUE ([Type], Code),
  CONSTRAINT CK_HttmCatalogs_MetadataJson CHECK (Metadata IS NULL OR ISJSON(Metadata) = 1)
);
CREATE INDEX IX_HttmCatalogs_Type_Active ON dbo.HttmCatalogs([Type], IsActive);
GO
```

### Catalog `Type` chuẩn
| Type | Mục đích |
|------|----------|
| `httm_types` | 10 loại hình HTTM |
| `httm_statuses` | 4 trạng thái hoạt động |
| `building_quality` | 4 mức chất lượng công trình |
| `gps_accuracy` | 3 mức chính xác GPS |
| `image_types` | 4 loại ảnh |
| `license_types` | 4 loại giấy phép |
| `ownership_types` | Loại hình sở hữu |
| `product_categories` | Danh mục mặt hàng KD (phân cấp) |

---

## Views

### `vw_HttmFacility_Map` — cho bản đồ
```sql
CREATE OR ALTER VIEW dbo.vw_HttmFacility_Map AS
SELECT
  f.Id,
  f.Name,
  f.HttmType,
  f.Status,
  f.ProvinceCode,
  f.StallCount,
  f.FloorArea,
  f.Location.Long AS Lng,
  f.Location.Lat  AS Lat,
  f.AddressDetail,
  (SELECT TOP(1) ImageUrl FROM dbo.HttmFacilityImages
    WHERE FacilityId = f.Id ORDER BY SortOrder ASC) AS CoverImage
FROM dbo.HttmFacilities f
WHERE f.Location IS NOT NULL
  AND f.Status <> 'closed';
GO
```

### `vw_HttmStats_ByProvince` — cho dashboard
```sql
CREATE OR ALTER VIEW dbo.vw_HttmStats_ByProvince AS
SELECT
  ProvinceCode,
  HttmType,
  Status,
  COUNT(*) AS Total,
  AVG(FloorArea) AS AvgFloorArea,
  SUM(StallCount) AS TotalStalls
FROM dbo.HttmFacilities
GROUP BY ProvinceCode, HttmType, Status;
GO
```

---

## Migration order

```
backend/database/migrations/
  20260513_xxxxxx_HttmCatalogs_Create.sql          # 1. Catalogs trước (không phụ thuộc)
  20260513_xxxxxx_HttmCatalogs_Seed.sql            # 2. Seed enum data
  20260513_xxxxxx_HttmFacilities_Create.sql        # 3. Bảng chính
  20260513_xxxxxx_HttmFacilityProducts_Create.sql  # 4. FK → HttmFacilities
  20260513_xxxxxx_HttmFacilityImages_Create.sql    # 5.
  20260513_xxxxxx_HttmFacilityLicenses_Create.sql  # 6.
  20260513_xxxxxx_HttmAuditLogs_Create.sql         # 7.
  20260513_xxxxxx_HttmFacilities_Spatial.sql       # 8. Spatial + FullText index
  20260513_xxxxxx_HttmViews_Create.sql             # 9. Views

  # Phase 2
  20260601_xxxxxx_HttmSurveys_Create.sql
  20260601_xxxxxx_HttmSurveyHistories_Create.sql
  20260601_xxxxxx_HttmSurveyCounters_Create.sql
  20260601_xxxxxx_HttmFacilities_AddSurveyFK.sql

  # SP cho Phase 1 (file riêng cho dễ review)
  20260513_xxxxxx_sp_Httm_Facility_Search.sql
  20260513_xxxxxx_sp_Httm_Facility_GetById.sql
  20260513_xxxxxx_sp_Httm_Facility_Insert.sql
  20260513_xxxxxx_sp_Httm_Facility_Update.sql
  20260513_xxxxxx_sp_Httm_Facility_Delete.sql
  20260513_xxxxxx_sp_Httm_Facility_GetMapData.sql
  20260513_xxxxxx_sp_Httm_Facility_GetAuditLogs.sql
  20260513_xxxxxx_sp_Httm_FacilityImage_Crud.sql
  20260513_xxxxxx_sp_Httm_FacilityLicense_Crud.sql
  20260513_xxxxxx_sp_Httm_Catalog_GetByType.sql
  20260513_xxxxxx_sp_Httm_AuditLog_Insert.sql
```

---

## Lưu ý implementation

1. **`UNIQUEIDENTIFIER` vs `NVARCHAR(450)` cho FK đến `AspNetUsers.Id`**
   `AspNetUsers.Id` của ASP.NET Identity mặc định là `NVARCHAR(450)`. Mọi cột FK đến user (CreatedBy, UpdatedBy, PerformedBy, ...) đều phải dùng `NVARCHAR(450)`, KHÔNG dùng `UNIQUEIDENTIFIER`.

2. **`GEOGRAPHY` POINT khởi tạo**
   Trong SP:
   ```sql
   DECLARE @loc GEOGRAPHY = GEOGRAPHY::Point(@Lat, @Lng, 4326);
   --                                       ^^^^  ^^^^ — chú ý: Lat trước Lng!
   ```

3. **Bounding box query cho map**
   ```sql
   DECLARE @bbox GEOGRAPHY = GEOGRAPHY::STGeomFromText(
     'POLYGON((' + ... + '))', 4326);
   SELECT TOP (2000) Id, Location.Long AS Lng, Location.Lat AS Lat, ...
   FROM dbo.HttmFacilities WITH (INDEX(SIX_HttmFacilities_Location))
   WHERE Location.STIntersects(@bbox) = 1;
   ```

4. **JSON query** cho HttmSurveys (Phase 2):
   ```sql
   SELECT JSON_VALUE(Step2Data, '$.unit_name') AS UnitName
   FROM dbo.HttmSurveys WHERE Id = @Id;
   ```

5. **Audit log capture IP/UserAgent**: lấy từ `HttpContext` ở Service layer, truyền vào SP.

6. **Performance**: tránh `SELECT *`; mọi SP đều select cột rõ ràng để client biết contract.

7. **Cascade delete**: chỉ HARD delete khi ADMIN gọi. SO_STAFF/BCT_STAFF dùng `Status = 'closed'` (soft state).

---

## Reference

- File gốc PostgreSQL: [`data-model.md`](./data-model.md) (deprecated)
- API mapping: [`api-endpoints.md`](./api-endpoints.md)
- Màn hình: [`screens.md`](./screens.md)
- Checklist tiến độ: [`checklist.md`](./checklist.md)
- Pattern migration của project: [`backend/database/migrations/`](../../../backend/database/migrations/)
- Pattern SP của project: tìm các file `*_AddXxxStoredProcedure*.sql` trong cùng folder
