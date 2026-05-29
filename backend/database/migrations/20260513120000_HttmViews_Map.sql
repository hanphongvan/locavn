-- HTTM Phase 1 — §1.1.2: View bản đồ (lng/lat từ GEOGRAPHY + ảnh đại diện).

CREATE OR ALTER VIEW dbo.vw_HttmFacility_Map
AS
SELECT
    f.Id,
    f.Name,
    f.HttmType,
    f.Status,
    f.ProvinceCode,
    f.StallCount,
    f.FloorArea,
    CASE WHEN f.Location IS NOT NULL THEN f.Location.Long ELSE NULL END AS Lng,
    CASE WHEN f.Location IS NOT NULL THEN f.Location.Lat ELSE NULL END AS Lat,
    f.AddressDetail,
    (
        SELECT TOP (1)
            i.ImageUrl
        FROM dbo.HttmFacilityImages AS i
        WHERE i.FacilityId = f.Id
        ORDER BY
            i.SortOrder ASC,
            i.CreatedAt ASC
    ) AS CoverImageUrl
FROM dbo.HttmFacilities AS f
WHERE f.Location IS NOT NULL
  AND f.Status <> N'closed';
GO
