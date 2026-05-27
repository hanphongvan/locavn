-- HTTM Phase 1 — §1.1.4: Seed danh mục (idempotent theo Type + Code).

IF OBJECT_ID(N'dbo.HttmCatalogs', N'U') IS NULL
    RETURN;

SET NOCOUNT ON;

DECLARE @Rows TABLE
(
    Type NVARCHAR(50) NOT NULL,
    Code NVARCHAR(100) NOT NULL,
    Name NVARCHAR(500) NOT NULL,
    NameEn NVARCHAR(500) NULL,
    ParentCode NVARCHAR(100) NULL,
    SortOrder SMALLINT NOT NULL
);

INSERT INTO @Rows (Type, Code, Name, NameEn, ParentCode, SortOrder)
VALUES
    (N'httm_types', N'market_grade1', N'Chợ hạng I', N'Grade I market', NULL, 10),
    (N'httm_types', N'market_grade2', N'Chợ hạng II', N'Grade II market', NULL, 20),
    (N'httm_types', N'market_grade3', N'Chợ hạng III', N'Grade III market', NULL, 30),
    (N'httm_types', N'supermarket_1', N'Siêu thị hạng I', N'Supermarket grade I', NULL, 40),
    (N'httm_types', N'supermarket_2', N'Siêu thị hạng II', N'Supermarket grade II', NULL, 50),
    (N'httm_types', N'supermarket_3', N'Siêu thị hạng III', N'Supermarket grade III', NULL, 60),
    (N'httm_types', N'mall', N'Trung tâm thương mại', N'Shopping mall', NULL, 70),
    (N'httm_types', N'wholesale_market', N'Chợ đầu mối', N'Wholesale market', NULL, 80),
    (N'httm_types', N'convenience_store', N'Cửa hàng tiện lợi', N'Convenience store', NULL, 90),
    (N'httm_types', N'other', N'Loại hình khác', N'Other', NULL, 100),
    (N'operation_statuses', N'active', N'Đang hoạt động', N'Active', NULL, 10),
    (N'operation_statuses', N'suspended', N'Tạm ngừng hoạt động', N'Suspended', NULL, 20),
    (N'operation_statuses', N'under_construction', N'Đang xây dựng / cải tạo', N'Under construction', NULL, 30),
    (N'operation_statuses', N'closed', N'Đã đóng cửa', N'Closed', NULL, 40),
    (N'building_quality', N'good', N'Tốt', N'Good', NULL, 10),
    (N'building_quality', N'average', N'Trung bình', N'Average', NULL, 20),
    (N'building_quality', N'degraded', N'Xuống cấp', N'Degraded', NULL, 30),
    (N'building_quality', N'needs_renovation', N'Cần cải tạo', N'Needs renovation', NULL, 40),
    (N'image_type', N'exterior', N'Mặt ngoài', N'Exterior', NULL, 10),
    (N'image_type', N'interior', N'Bên trong', N'Interior', NULL, 20),
    (N'image_type', N'infrastructure', N'Hạ tầng', N'Infrastructure', NULL, 30),
    (N'image_type', N'other', N'Khác', N'Other', NULL, 40),
    (N'license_type', N'business', N'Giấy phép kinh doanh', N'Business license', NULL, 10),
    (N'license_type', N'fire_protection', N'PCCC', N'Fire protection', NULL, 20),
    (N'license_type', N'food_safety', N'VSATTP', N'Food safety', NULL, 30),
    (N'license_type', N'other', N'Khác', N'Other', NULL, 40),
    (N'ownership_types', N'state', N'Nhà nước', N'State', NULL, 10),
    (N'ownership_types', N'private', N'Tư nhân', N'Private', NULL, 20),
    (N'ownership_types', N'cooperative', N'Hợp tác xã', N'Cooperative', NULL, 30),
    (N'ownership_types', N'joint_venture', N'Liên doanh', N'Joint venture', NULL, 40),
    (N'product_categories', N'fresh_food', N'Thực phẩm tươi sống', N'Fresh food', NULL, 10),
    (N'product_categories', N'dry_goods', N'Hàng khô', N'Dry goods', NULL, 20),
    (N'product_categories', N'apparel', N'May mặc', N'Apparel', NULL, 30),
    (N'product_categories', N'electronics', N'Điện tử', N'Electronics', NULL, 40),
    (N'product_categories', N'household', N'Đồ gia dụng', N'Household', NULL, 50);

INSERT INTO dbo.HttmCatalogs (Type, Code, Name, NameEn, ParentCode, SortOrder, IsActive, Metadata)
SELECT
    r.Type,
    r.Code,
    r.Name,
    r.NameEn,
    r.ParentCode,
    r.SortOrder,
    1,
    N'{}'
FROM @Rows AS r
WHERE NOT EXISTS (
    SELECT 1
    FROM dbo.HttmCatalogs AS c
    WHERE c.Type = r.Type
      AND c.Code = r.Code
);
GO
