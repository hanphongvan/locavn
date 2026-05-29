-- HTTM dashboard — đếm số cơ sở hạ tầng thương mại "chưa cập nhật".
-- Định nghĩa: facility KHÔNG có bất kỳ bản ghi nào trong dbo.HttmFacilitySubmissions
-- (mọi status — pending/approved/rejected — đều được tính là "đã có đề xuất cập nhật").
-- Hỗ trợ scope theo CSV mã tỉnh (cho SO_STAFF nhiều tỉnh); NULL/empty = toàn quốc.

SET NOCOUNT ON;
GO

CREATE OR ALTER PROCEDURE dbo.sp_Httm_Analytics_FacilitiesNotUpdated
    @ProvinceCodes NVARCHAR(MAX) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF OBJECT_ID(N'dbo.HttmFacilities', N'U') IS NULL
       OR OBJECT_ID(N'dbo.HttmFacilitySubmissions', N'U') IS NULL
    BEGIN
        SELECT CAST(0 AS BIGINT) AS [Count];
        RETURN;
    END;

    DECLARE @UseCsv BIT = CASE
        WHEN @ProvinceCodes IS NOT NULL AND LEN(LTRIM(RTRIM(@ProvinceCodes))) > 0 THEN 1
        ELSE 0
    END;

    SELECT COUNT_BIG(1) AS [Count]
    FROM dbo.HttmFacilities AS f
    WHERE (
            @UseCsv = 0
            OR f.ProvinceCode IN (
                SELECT s.value
                FROM dbo.fn_Httm_SplitCsv(@ProvinceCodes) AS s
                WHERE s.value <> N''
            )
          )
      AND NOT EXISTS (
            SELECT 1
            FROM dbo.HttmFacilitySubmissions AS sub
            WHERE sub.FacilityId = f.Id
          );
END;
GO
