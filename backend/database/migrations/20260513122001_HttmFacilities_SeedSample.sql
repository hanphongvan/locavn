-- HTTM Phase 1 — §1.1.4: Mẫu cơ sở Hà Nội / TP.HCM (chỉ khi chưa có seed và có ít nhất 1 user).

SET NOCOUNT ON;

IF OBJECT_ID(N'dbo.HttmFacilities', N'U') IS NULL
    RETURN;

IF EXISTS (
    SELECT 1
    FROM dbo.HttmFacilities AS f
    WHERE f.Notes = N'__httm_seed__'
)
    RETURN;

DECLARE @UserId NVARCHAR(128) =
(
    SELECT TOP (1)
        u.Id
    FROM dbo.AspNetUsers AS u
    ORDER BY u.UserName
);

IF @UserId IS NULL
BEGIN
    PRINT N'SKIP HttmFacilities seed: không có bản ghi dbo.AspNetUsers.';
    RETURN;
END;

DECLARE @F TABLE
(
    Name NVARCHAR(500) NOT NULL,
    HttmType NVARCHAR(50) NOT NULL,
    Status NVARCHAR(30) NOT NULL,
    ProvinceCode NVARCHAR(10) NOT NULL,
    Lat FLOAT NOT NULL,
    Lng FLOAT NOT NULL,
    FloorArea DECIMAL(12, 2) NULL,
    StallCount INT NULL
);

INSERT INTO @F (Name, HttmType, Status, ProvinceCode, Lat, Lng, FloorArea, StallCount)
VALUES
    (N'[DEV-SEED] Chợ Đồng Xuân', N'market_grade1', N'active', N'01', 21.0347, 105.8500, 12000, 2500),
    (N'[DEV-SEED] Siêu thị Vinmart Phạm Ngọc Thạch', N'supermarket_2', N'active', N'01', 21.0078, 105.8350, 3500, 120),
    (N'[DEV-SEED] TTTM Vincom Bà Triệu', N'mall', N'active', N'01', 21.0110, 105.8485, 45000, 180),
    (N'[DEV-SEED] Chợ Bến Thành', N'market_grade1', N'active', N'79', 10.7720, 106.6983, 13500, 3000),
    (N'[DEV-SEED] Siêu thị Co.opmart Nguyễn Thị Minh Khai', N'supermarket_2', N'active', N'79', 10.7840, 106.6880, 4200, 95),
    (N'[DEV-SEED] Cửa hàng tiện lợi GS25 Lê Lợi', N'convenience_store', N'active', N'79', 10.7735, 106.7012, 180, 8);

INSERT INTO dbo.HttmFacilities
(
    Name,
    HttmType,
    Status,
    ProvinceCode,
    DistrictCode,
    WardCode,
    AddressDetail,
    Location,
    GpsAccuracy,
    LandArea,
    FloorArea,
    Floors,
    StallCount,
    YearEstablished,
    OwnerName,
    CreatedBy,
    Notes,
    CreatedAt,
    UpdatedAt
)
SELECT
    f.Name,
    f.HttmType,
    f.Status,
    f.ProvinceCode,
    NULL,
    NULL,
    N'Seed tự động — xóa sau khi có dữ liệu thật.',
    geography::Point(f.Lat, f.Lng, 4326),
    N'approximate',
    f.FloorArea,
    f.FloorArea,
    1,
    f.StallCount,
    2010,
    N'__seed__',
    @UserId,
    N'__httm_seed__',
    SYSUTCDATETIME(),
    SYSUTCDATETIME()
FROM @F AS f;
GO
