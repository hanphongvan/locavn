namespace Httm.XangDau.Api.Shared.Persistence.Migrations;

/// <summary>
/// <c>GET /api/stations/map/clusters</c> — gom trạm bán lẻ theo tỉnh (centroid + count) cho zoom thấp.
/// Optional <c>@Keyword</c> (LIKE 5 cột giống <c>sp_Station_Search</c>) + <c>@Status</c> (open/closed).
/// Chỉ trả tỉnh có ≥ 1 trạm hợp lệ (có toạ độ + match filter).
/// </summary>
internal static class ApiStationMapProvinceClustersSql
{
    internal const string CreateProcedure =
        """
        CREATE OR ALTER PROCEDURE dbo.sp_Api_StationMap_ProvinceClusters
            @RetailCapDonViId INT,
            @DayOfWeek TINYINT,
            @NowTime TIME(0),
            @Status NVARCHAR(20) = NULL,
            @Keyword NVARCHAR(200) = NULL
        AS
        BEGIN
            SET NOCOUNT ON;

            DECLARE @StatusNorm NVARCHAR(20) = LOWER(LTRIM(RTRIM(@Status)));
            IF @StatusNorm IS NULL OR @StatusNorm = N'' SET @StatusNorm = N'all';

            DECLARE @KwTrim NVARCHAR(200) = NULLIF(LTRIM(RTRIM(@Keyword)), N'');

            ;WITH Base AS (
                SELECT
                    d.Id AS StationId,
                    t.Id AS ProvinceId,
                    t.Ma AS ProvinceCode,
                    t.Ten AS ProvinceName,
                    CAST(d.ViDo AS float) AS Latitude,
                    CAST(d.KinhDo AS float) AS Longitude,
                    d.TrangThai
                FROM dbo.DM_DonVi AS d
                INNER JOIN dbo.DM_Tinh AS t ON t.Id = d.Tinh
                WHERE d.CapDonViId = @RetailCapDonViId
                  AND d.ViDo IS NOT NULL AND d.KinhDo IS NOT NULL
                  AND d.ViDo >= -90 AND d.ViDo <= 90 AND d.KinhDo >= -180 AND d.KinhDo <= 180
                  AND NOT (d.ViDo = 0 AND d.KinhDo = 0)
                  AND (
                      @KwTrim IS NULL
                      OR d.Ten           LIKE N'%' + @KwTrim + N'%'
                      OR d.Ma            LIKE N'%' + @KwTrim + N'%'
                      OR (d.DiaChiChiTiet IS NOT NULL AND d.DiaChiChiTiet LIKE N'%' + @KwTrim + N'%')
                      OR (d.DiaChi        IS NOT NULL AND d.DiaChi        LIKE N'%' + @KwTrim + N'%')
                      OR (d.SoGiayPhep    IS NOT NULL AND d.SoGiayPhep    LIKE N'%' + @KwTrim + N'%')
                  )
            ),
            Flagged AS (
                SELECT
                    b.*,
                    CASE
                        WHEN (b.TrangThai IS NULL OR b.TrangThai = CAST(1 AS bit))
                             AND (
                                 NOT EXISTS (SELECT 1 FROM dbo.StationOperatingHours AS h0 WHERE h0.DonViId = b.StationId)
                                 OR NOT EXISTS (
                                     SELECT 1
                                     FROM dbo.StationOperatingHours AS h1
                                     WHERE h1.DonViId = b.StationId AND h1.DayOfWeek = @DayOfWeek
                                 )
                                 OR EXISTS (
                                     SELECT 1
                                     FROM dbo.StationOperatingHours AS h
                                     WHERE h.DonViId = b.StationId
                                       AND h.DayOfWeek = @DayOfWeek
                                       AND h.IsClosedAllDay = CAST(0 AS bit)
                                       AND (
                                           (h.OpensAt IS NULL AND h.ClosesAt IS NULL)
                                           OR (
                                               h.OpensAt IS NOT NULL AND h.ClosesAt IS NOT NULL
                                               AND (
                                                   (
                                                       h.ClosesAt >= h.OpensAt
                                                       AND h.OpensAt <= @NowTime
                                                       AND @NowTime <= h.ClosesAt
                                                   )
                                                   OR (
                                                       h.ClosesAt < h.OpensAt
                                                       AND (h.OpensAt <= @NowTime OR @NowTime <= h.ClosesAt)
                                                   )
                                               )
                                           )
                                       )
                                 )
                             )
                        THEN 1
                        ELSE 0
                    END AS IsOpen
                FROM Base AS b
            ),
            Eligible AS (
                SELECT
                    f.ProvinceId,
                    f.ProvinceCode,
                    f.ProvinceName,
                    f.Latitude,
                    f.Longitude
                FROM Flagged AS f
                WHERE @StatusNorm = N'all'
                   OR (@StatusNorm = N'open' AND f.IsOpen = 1)
                   OR (@StatusNorm = N'closed' AND f.IsOpen = 0)
            )
            SELECT
                e.ProvinceId,
                e.ProvinceCode,
                e.ProvinceName,
                COUNT_BIG(*) AS StationCount,
                AVG(e.Latitude)  AS CentroidLat,
                AVG(e.Longitude) AS CentroidLng
            FROM Eligible AS e
            GROUP BY e.ProvinceId, e.ProvinceCode, e.ProvinceName
            ORDER BY e.ProvinceName, e.ProvinceId;
        END;
        """;
}
