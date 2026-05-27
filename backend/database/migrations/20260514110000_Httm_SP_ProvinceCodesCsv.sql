-- HTTM Phase 1 — Bug #1 fix: sp_Httm_Facility_Search và sp_Httm_Facility_GetMapData
-- chấp nhận thêm @ProvinceCodes (CSV) để SO_STAFF có nhiều tỉnh có thể truy vấn toàn bộ
-- phạm vi được gán, thay vì chỉ tỉnh đầu tiên.
--
-- Quy tắc:
--   - Nếu @ProvinceCode (single) khác NULL -> ưu tiên lọc 1 mã (giữ hành vi cũ).
--   - Else nếu @ProvinceCodes (CSV) khác NULL/rỗng -> split rồi IN.
--   - Else không lọc theo tỉnh.

CREATE OR ALTER PROCEDURE dbo.sp_Httm_Facility_Search
    @Q NVARCHAR(200) = NULL,
    @HttmType NVARCHAR(50) = NULL,
    @ProvinceCode NVARCHAR(10) = NULL,
    @ProvinceCodes NVARCHAR(MAX) = NULL,
    @DistrictCode NVARCHAR(10) = NULL,
    @WardCode NVARCHAR(10) = NULL,
    @Status NVARCHAR(30) = NULL,
    @AreaMin DECIMAL(12, 2) = NULL,
    @AreaMax DECIMAL(12, 2) = NULL,
    @StallMin INT = NULL,
    @StallMax INT = NULL,
    @YearFrom SMALLINT = NULL,
    @YearTo SMALLINT = NULL,
    @Page INT = 1,
    @PageSize INT = 20
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Ps INT = CASE
        WHEN @PageSize < 1 THEN 20
        WHEN @PageSize > 100 THEN 100
        ELSE @PageSize
    END;
    DECLARE @Pg INT = CASE WHEN @Page < 1 THEN 1 ELSE @Page END;
    DECLARE @Off BIGINT = CAST(@Pg - 1 AS BIGINT) * CAST(@Ps AS BIGINT);

    DECLARE @Like NVARCHAR(400) = NULL;
    IF @Q IS NOT NULL AND LEN(LTRIM(RTRIM(@Q))) > 0
    BEGIN
        SET @Like = N'%' + REPLACE(REPLACE(REPLACE(LTRIM(RTRIM(@Q)), N'\', N'\\'), N'%', N'\%'), N'_', N'\_') + N'%';
    END;

    DECLARE @UseCsv BIT = CASE
        WHEN @ProvinceCode IS NULL
             AND @ProvinceCodes IS NOT NULL
             AND LEN(LTRIM(RTRIM(@ProvinceCodes))) > 0
        THEN 1 ELSE 0
    END;

    SELECT
        COUNT_BIG(*) OVER () AS TotalCount,
        f.Id,
        f.Name,
        f.HttmType,
        f.Status,
        f.ProvinceCode,
        f.DistrictCode,
        f.WardCode,
        f.AddressDetail,
        f.LandArea,
        f.FloorArea,
        f.StallCount,
        f.YearEstablished,
        f.UpdatedAt
    FROM dbo.HttmFacilities AS f
    WHERE (@HttmType IS NULL OR f.HttmType = @HttmType)
      AND (@ProvinceCode IS NULL OR f.ProvinceCode = @ProvinceCode)
      AND (
          @UseCsv = 0
          OR f.ProvinceCode IN (
              SELECT LTRIM(RTRIM(s.value))
              FROM STRING_SPLIT(@ProvinceCodes, N',') AS s
              WHERE LTRIM(RTRIM(s.value)) <> N''
          )
      )
      AND (@DistrictCode IS NULL OR f.DistrictCode = @DistrictCode)
      AND (@WardCode IS NULL OR f.WardCode = @WardCode)
      AND (@Status IS NULL OR f.Status = @Status)
      AND (
          @AreaMin IS NULL
          OR COALESCE(f.FloorArea, f.LandArea) IS NULL
          OR COALESCE(f.FloorArea, f.LandArea) >= @AreaMin
      )
      AND (
          @AreaMax IS NULL
          OR COALESCE(f.FloorArea, f.LandArea) IS NULL
          OR COALESCE(f.FloorArea, f.LandArea) <= @AreaMax
      )
      AND (@StallMin IS NULL OR f.StallCount IS NULL OR f.StallCount >= @StallMin)
      AND (@StallMax IS NULL OR f.StallCount IS NULL OR f.StallCount <= @StallMax)
      AND (@YearFrom IS NULL OR f.YearEstablished IS NULL OR f.YearEstablished >= @YearFrom)
      AND (@YearTo IS NULL OR f.YearEstablished IS NULL OR f.YearEstablished <= @YearTo)
      AND (
          @Like IS NULL
          OR f.Name LIKE @Like ESCAPE N'\'
      )
    ORDER BY f.UpdatedAt DESC, f.Id
    OFFSET @Off ROWS FETCH NEXT @Ps ROWS ONLY;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_Httm_Facility_GetMapData
    @BoundsWest FLOAT,
    @BoundsSouth FLOAT,
    @BoundsEast FLOAT,
    @BoundsNorth FLOAT,
    @Types NVARCHAR(400) = NULL,
    @ProvinceCode NVARCHAR(10) = NULL,
    @ProvinceCodes NVARCHAR(MAX) = NULL,
    @MaxRows INT = 2000
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Mr INT = CASE
        WHEN @MaxRows IS NULL OR @MaxRows < 1 THEN 2000
        WHEN @MaxRows > 2000 THEN 2000
        ELSE @MaxRows
    END;

    IF @BoundsSouth > @BoundsNorth OR @BoundsWest > @BoundsEast
    BEGIN
        RAISERROR(N'Bounds không hợp lệ (West<=East, South<=North).', 16, 1);
        RETURN;
    END;

    DECLARE @UseCsv BIT = CASE
        WHEN @ProvinceCode IS NULL
             AND @ProvinceCodes IS NOT NULL
             AND LEN(LTRIM(RTRIM(@ProvinceCodes))) > 0
        THEN 1 ELSE 0
    END;

    SELECT TOP (@Mr)
        f.Id,
        f.Name,
        f.HttmType,
        f.Status,
        f.ProvinceCode,
        f.AddressDetail,
        f.FloorArea,
        f.StallCount,
        f.Location.Long AS Lng,
        f.Location.Lat AS Lat
    FROM dbo.HttmFacilities AS f
    WHERE f.Location IS NOT NULL
      AND f.Status <> N'closed'
      AND f.Location.Lat BETWEEN @BoundsSouth AND @BoundsNorth
      AND f.Location.Long BETWEEN @BoundsWest AND @BoundsEast
      AND (@ProvinceCode IS NULL OR f.ProvinceCode = @ProvinceCode)
      AND (
          @UseCsv = 0
          OR f.ProvinceCode IN (
              SELECT LTRIM(RTRIM(s.value))
              FROM STRING_SPLIT(@ProvinceCodes, N',') AS s
              WHERE LTRIM(RTRIM(s.value)) <> N''
          )
      )
      AND (
          @Types IS NULL
          OR LTRIM(RTRIM(@Types)) = N''
          OR EXISTS (
              SELECT 1
              FROM STRING_SPLIT(@Types, N',') AS s
              WHERE LTRIM(RTRIM(s.value)) <> N''
                AND f.HttmType = LTRIM(RTRIM(s.value))
          )
      )
    ORDER BY f.UpdatedAt DESC, f.Id;
END;
GO
