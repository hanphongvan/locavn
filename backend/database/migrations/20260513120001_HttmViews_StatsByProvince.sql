-- HTTM Phase 1 — §1.1.2: View thống kê theo tỉnh / loại / trạng thái.

CREATE OR ALTER VIEW dbo.vw_HttmStats_ByProvince
AS
SELECT
    f.ProvinceCode,
    f.HttmType,
    f.Status,
    COUNT_BIG(*) AS Total,
    AVG(CAST(f.FloorArea AS FLOAT)) AS AvgFloorArea,
    SUM(CAST(f.StallCount AS BIGINT)) AS TotalStalls
FROM dbo.HttmFacilities AS f
GROUP BY
    f.ProvinceCode,
    f.HttmType,
    f.Status;
GO
