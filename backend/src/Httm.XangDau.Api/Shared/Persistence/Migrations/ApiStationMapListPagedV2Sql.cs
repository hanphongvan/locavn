namespace Httm.XangDau.Api.Shared.Persistence.Migrations;

/// <summary>
/// <c>GET /api/stations/map/v2</c> — v2 thêm filter <c>@FuelCode</c> (khớp <c>StationStoreServices.ServiceCode</c>
/// với <c>FuelProducts.Code</c>) và embed giá ngay trong SP (không gọi <c>fuelReporting</c> riêng): trả về
/// <c>PriceRon95</c>, <c>PriceDiesel</c>, và <c>PriceForSelectedFuel</c> (giá theo fuel mobile đang lọc).
/// </summary>
internal static class ApiStationMapListPagedV2Sql
{
    internal const string CreateProcedure =
        """
        CREATE OR ALTER PROCEDURE dbo.sp_Api_StationMap_ListPaged_V2
            @RetailCapDonViId INT,
            @DayOfWeek TINYINT,
            @NowTime TIME(0),
            @ProvinceCode NVARCHAR(20) = NULL,
            @DistrictQuanHuyenId INT = NULL,
            @Status NVARCHAR(20) = NULL,
            @Keyword NVARCHAR(200) = NULL,
            @FuelCode NVARCHAR(50) = NULL,
            @Skip INT = 0,
            @Take INT = 20
        AS
        BEGIN
            SET NOCOUNT ON;

            DECLARE @StatusNorm NVARCHAR(20) = LOWER(LTRIM(RTRIM(@Status)));
            IF @StatusNorm IS NULL OR @StatusNorm = N'' SET @StatusNorm = N'all';

            DECLARE @KwTrim NVARCHAR(200) = NULLIF(LTRIM(RTRIM(@Keyword)), N'');
            DECLARE @FuelTrim NVARCHAR(50) = NULLIF(LTRIM(RTRIM(@FuelCode)), N'');

            CREATE TABLE #Filtered (
                StationId INT NOT NULL,
                StationName NVARCHAR(500),
                StationMa NVARCHAR(100),
                Latitude FLOAT,
                Longitude FLOAT,
                ShortAddress NVARCHAR(MAX),
                TrangThai BIT,
                OpenTime TIME(0),
                CloseTime TIME(0)
            );

            ;WITH Base AS (
                SELECT
                    d.Id AS StationId,
                    d.Ten AS StationName,
                    d.Ma AS StationMa,
                    CAST(d.ViDo AS float) AS Latitude,
                    CAST(d.KinhDo AS float) AS Longitude,
                    NULLIF(LTRIM(RTRIM(COALESCE(d.DiaChiChiTiet, d.DiaChi))), N'') AS ShortAddress,
                    d.TrangThai,
                    d.OpenTime,
                    d.CloseTime
                FROM dbo.DM_DonVi AS d
                LEFT JOIN dbo.DM_Tinh AS t ON t.Id = d.Tinh
                LEFT JOIN dbo.DM_XaPhuong AS x ON x.Id = d.Xa
                WHERE d.CapDonViId = @RetailCapDonViId
                  AND d.ViDo IS NOT NULL AND d.KinhDo IS NOT NULL
                  AND d.ViDo >= -90 AND d.ViDo <= 90 AND d.KinhDo >= -180 AND d.KinhDo <= 180
                  AND NOT (d.ViDo = 0 AND d.KinhDo = 0)
                  AND (@ProvinceCode IS NULL OR t.Ma = @ProvinceCode)
                  AND (@DistrictQuanHuyenId IS NULL OR x.QuanHuyenId = @DistrictQuanHuyenId)
                  AND (
                      @KwTrim IS NULL
                      OR d.Ten           LIKE N'%' + @KwTrim + N'%'
                      OR d.Ma            LIKE N'%' + @KwTrim + N'%'
                      OR (d.DiaChiChiTiet IS NOT NULL AND d.DiaChiChiTiet LIKE N'%' + @KwTrim + N'%')
                      OR (d.DiaChi        IS NOT NULL AND d.DiaChi        LIKE N'%' + @KwTrim + N'%')
                      OR (d.SoGiayPhep    IS NOT NULL AND d.SoGiayPhep    LIKE N'%' + @KwTrim + N'%')
                  )
                  AND (
                      @FuelTrim IS NULL
                      OR EXISTS (
                          SELECT 1
                          FROM dbo.StationStoreServices AS sss
                          WHERE sss.DonViId = d.Id
                            AND sss.IsActive = CAST(1 AS bit)
                            AND sss.ServiceCode = @FuelTrim
                      )
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
            )
            INSERT INTO #Filtered (StationId, StationName, StationMa, Latitude, Longitude, ShortAddress, TrangThai, OpenTime, CloseTime)
            SELECT
                f.StationId,
                f.StationName,
                f.StationMa,
                f.Latitude,
                f.Longitude,
                f.ShortAddress,
                f.TrangThai,
                f.OpenTime,
                f.CloseTime
            FROM Flagged AS f
            WHERE @StatusNorm = N'all'
               OR (@StatusNorm = N'open' AND f.IsOpen = 1)
               OR (@StatusNorm = N'closed' AND f.IsOpen = 0);

            SELECT CASE WHEN @Skip = 0 THEN (SELECT COUNT_BIG(*) FROM #Filtered) ELSE CAST(0 AS bigint) END AS TotalCount;

            SELECT
                f.StationId,
                f.StationName,
                f.Latitude,
                f.Longitude,
                f.ShortAddress,
                f.TrangThai,
                f.OpenTime,
                f.CloseTime,
                (
                    SELECT TOP (1) sss.Price
                    FROM dbo.StationStoreServices AS sss
                    WHERE sss.DonViId = f.StationId
                      AND sss.IsActive = CAST(1 AS bit)
                      AND sss.ServiceCode = N'RON95'
                ) AS PriceRon95,
                (
                    SELECT TOP (1) sss.Price
                    FROM dbo.StationStoreServices AS sss
                    WHERE sss.DonViId = f.StationId
                      AND sss.IsActive = CAST(1 AS bit)
                      AND sss.ServiceCode = N'DIESEL'
                ) AS PriceDiesel,
                CASE
                    WHEN @FuelTrim IS NULL THEN CAST(NULL AS DECIMAL(18, 2))
                    ELSE (
                        SELECT TOP (1) sss.Price
                        FROM dbo.StationStoreServices AS sss
                        WHERE sss.DonViId = f.StationId
                          AND sss.IsActive = CAST(1 AS bit)
                          AND sss.ServiceCode = @FuelTrim
                    )
                END AS PriceForSelectedFuel
            FROM #Filtered AS f
            ORDER BY f.StationName, f.StationMa
            OFFSET @Skip ROWS FETCH NEXT @Take ROWS ONLY;

            DROP TABLE #Filtered;
        END;
        """;
}
