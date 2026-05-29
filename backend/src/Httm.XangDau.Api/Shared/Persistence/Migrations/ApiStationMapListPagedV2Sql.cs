namespace Httm.XangDau.Api.Shared.Persistence.Migrations;

/// <summary>
/// <c>GET /api/stations/map/v2</c> — v2 thêm:
/// 1. Filter <c>@FuelCode</c> (khớp <c>StationStoreServices.ServiceCode</c> với <c>FuelProducts.Code</c>).
/// 2. Embed giá ngay trong SP: trả về <c>PriceRon95</c>, <c>PriceDiesel</c>, <c>PriceForSelectedFuel</c>
///    (lấy từ <c>StationStoreServices.Price</c>; fallback về giá quốc gia gần nhất từ
///    <c>QT_TK_ThongKe</c> khi station chưa khai báo giá).
/// 3. Cột <c>Fuels</c> — danh sách service codes (active) cách nhau bằng dấu phẩy.
/// 4. <c>ParentDonViId</c> (CapTrenId), <c>HasTodayHours</c>, <c>TodayOpensAt</c>,
///    <c>TodayClosesAt</c>, <c>TodayIsClosedAllDay</c> — để client KHÔNG còn batch-query
///    <c>StationOperatingHours</c> và <c>DM_DonVi.CapTrenId</c> theo
///    <c>IN(@batch1..@batch1000)</c> nữa.
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

            -- Fallback giá quốc gia (gần nhất, có cả 3 sản phẩm RON95/E5/DIESEL trong cùng kỳ).
            DECLARE @gia_xang DECIMAL(18, 2);
            DECLARE @gia_dau DECIMAL(18, 2);

            DECLARE @BaoCaoId UNIQUEIDENTIFIER = 'F115C290-543A-4E1B-8546-275A2CF8150E';
            DECLARE @TuNgay DATE = DATEADD(MONTH, -3, GETDATE());

            ;WITH src AS
            (
                SELECT
                    ISNULL(ct.ThoiDiemDinhGia, tk.TuNgay) AS ThoiDiemDinhGia,
                    CASE
                        WHEN dm.MA = 'CT4' THEN 'RON95'
                        WHEN dm.MA = 'CT6' THEN 'E5RON92'
                        WHEN dm.MA = 'CT9' THEN 'DIESEL005S'
                    END AS ProductKey,
                    ISNULL(ct.So_04, 0) AS GiaTri
                FROM dbo.QT_TK_ThongKe tk
                INNER JOIN dbo.QT_TK_ThongKeChiTiet ct ON tk.Id = ct.ThongKeId
                LEFT JOIN dbo.TK_ChiTieuBaoCao dm ON ct.ChiTieuThongKeId = dm.Id
                WHERE tk.BaoCaoId = @BaoCaoId
                  AND tk.Loai = 1
                  AND tk.TrangThai = 5
                  AND dm.MA IN ('CT4', 'CT6', 'CT9')
                  AND ct.LoaiGia = 1
                  AND ct.So_01 = 1
                  AND ISNULL(ct.ThoiDiemDinhGia, tk.TuNgay) >= @TuNgay
                  AND ISNULL(ct.ThoiDiemDinhGia, tk.TuNgay) <= GETDATE()
                  AND ISNULL(ct.So_04, 0) > 0
            )
            SELECT
                ThoiDiemDinhGia,
                MAX(CASE WHEN ProductKey = 'RON95' AND GiaTri > 0 THEN GiaTri END) AS Ron95,
                MAX(CASE WHEN ProductKey = 'E5RON92' AND GiaTri > 0 THEN GiaTri END) AS E5Ron92,
                MAX(CASE WHEN ProductKey = 'DIESEL005S' AND GiaTri > 0 THEN GiaTri END) AS Diesel005S
            INTO #pivoted
            FROM src
            GROUP BY ThoiDiemDinhGia;

            ;WITH ranked AS
            (
                SELECT *,
                       ROW_NUMBER() OVER (ORDER BY ThoiDiemDinhGia DESC) AS rn
                FROM #pivoted
                WHERE Ron95 > 0 AND E5Ron92 > 0 AND Diesel005S > 0
            )
            SELECT
                MAX(CASE WHEN rn = 1 THEN Ron95 END) AS Cur_Ron95,
                MAX(CASE WHEN rn = 1 THEN Diesel005S END) AS Cur_Diesel
            INTO #Compare
            FROM ranked;

            SELECT TOP (1) @gia_xang = Cur_Ron95 FROM #Compare;
            SELECT TOP (1) @gia_dau = Cur_Diesel FROM #Compare;

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
                CloseTime TIME(0),
                ParentDonViId INT NULL
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
                    d.CloseTime,
                    d.CapTrenId AS ParentDonViId
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
            INSERT INTO #Filtered (StationId, StationName, StationMa, Latitude, Longitude, ShortAddress, TrangThai, OpenTime, CloseTime, ParentDonViId)
            SELECT
                f.StationId,
                f.StationName,
                f.StationMa,
                f.Latitude,
                f.Longitude,
                f.ShortAddress,
                f.TrangThai,
                f.OpenTime,
                f.CloseTime,
                f.ParentDonViId
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
                f.ParentDonViId,
                (
                    SELECT TOP (1) sss.Price
                    FROM dbo.StationStoreServices AS sss
                    WHERE sss.DonViId = f.StationId
                      AND sss.IsActive = CAST(1 AS bit)
                      AND sss.ServiceCode = N'RON95'
                ) AS PriceRon95_1,
                (
                    SELECT TOP (1) sss.Price
                    FROM dbo.StationStoreServices AS sss
                    WHERE sss.DonViId = f.StationId
                      AND sss.IsActive = CAST(1 AS bit)
                      AND sss.ServiceCode = N'DIESEL'
                ) AS PriceDiesel_1,
                CASE
                    WHEN @FuelTrim IS NULL THEN CAST(NULL AS DECIMAL(18, 2))
                    ELSE (
                        SELECT TOP (1) sss.Price
                        FROM dbo.StationStoreServices AS sss
                        WHERE sss.DonViId = f.StationId
                          AND sss.IsActive = CAST(1 AS bit)
                          AND sss.ServiceCode = @FuelTrim
                    )
                END AS PriceForSelectedFuel,
                -- Embed active service codes (cách nhau dấu phẩy) — client split để có
                -- ActiveServiceCodes mà không cần batch IN(@batch1..@batch1000) riêng.
                STUFF((
                    SELECT ',' + s.ServiceCode
                    FROM dbo.StationStoreServices AS s
                    WHERE s.DonViId = f.StationId
                      AND s.IsActive = CAST(1 AS bit)
                    ORDER BY s.ServiceCode
                    FOR XML PATH(''), TYPE
                ).value('.', 'NVARCHAR(MAX)'), 1, 1, '') AS Fuels,
                -- Today's StationOperatingHours (TOP 1) — client compute openNow + display.
                -- HasTodayHours=0 → no row for today; client treats as "unknown" (no override).
                CASE WHEN todayH.OpensAt IS NOT NULL
                          OR todayH.ClosesAt IS NOT NULL
                          OR todayH.IsClosedAllDay IS NOT NULL
                     THEN CAST(1 AS BIT) ELSE CAST(0 AS BIT) END AS HasTodayHours,
                todayH.OpensAt AS TodayOpensAt,
                todayH.ClosesAt AS TodayClosesAt,
                todayH.IsClosedAllDay AS TodayIsClosedAllDay
            INTO #tmptTam
            FROM #Filtered AS f
            OUTER APPLY (
                SELECT TOP (1) h.OpensAt, h.ClosesAt, h.IsClosedAllDay
                FROM dbo.StationOperatingHours h
                WHERE h.DonViId = f.StationId AND h.DayOfWeek = @DayOfWeek
                ORDER BY h.Id
            ) AS todayH
            ORDER BY f.StationName, f.StationMa
            OFFSET @Skip ROWS FETCH NEXT @Take ROWS ONLY;

            SELECT
                tt.StationId,
                tt.StationName,
                tt.Latitude,
                tt.Longitude,
                tt.ShortAddress,
                tt.TrangThai,
                tt.OpenTime,
                tt.CloseTime,
                tt.ParentDonViId,
                CASE WHEN tt.PriceRon95_1 IS NULL THEN @gia_xang ELSE tt.PriceRon95_1 END AS PriceRon95,
                CASE WHEN tt.PriceDiesel_1 IS NULL THEN @gia_dau ELSE tt.PriceDiesel_1 END AS PriceDiesel,
                tt.PriceForSelectedFuel,
                tt.Fuels,
                tt.HasTodayHours,
                tt.TodayOpensAt,
                tt.TodayClosesAt,
                tt.TodayIsClosedAllDay
            FROM #tmptTam tt;

            DROP TABLE #tmptTam;
            DROP TABLE #Filtered;
            DROP TABLE #pivoted;
            DROP TABLE #Compare;
        END;
        """;
}
