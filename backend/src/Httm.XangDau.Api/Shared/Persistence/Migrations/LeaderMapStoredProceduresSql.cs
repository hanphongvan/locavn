namespace Httm.XangDau.Api.Shared.Persistence.Migrations;

/// <summary>SP cho <c>GET /api/leader/map/*</c> — Lãnh đạo, bản đồ điều hành.</summary>
internal static class LeaderMapStoredProceduresSql
{
    /// <summary>Danh sách đơn vị đầu mối có tọa độ (metadata <c>DM_DonVi</c>).</summary>
    internal const string CreateDistributorUnitsList =
        """
        CREATE OR ALTER PROCEDURE dbo.sp_Leader_Map_DistributorUnits_List
            @WholesaleCapDonViId INT
        AS
        BEGIN
            SET NOCOUNT ON;
            SELECT
                d.Id,
                d.Ten AS TenDonVi,
                NULLIF(LTRIM(RTRIM(COALESCE(d.DiaChiChiTiet, d.DiaChi))), N'') AS DiaChi,
                CAST(d.KinhDo AS float) AS KinhDo,
                CAST(d.ViDo AS float) AS ViDo,
                NULLIF(LTRIM(RTRIM(d.LogoUrl)), N'') AS LogoUrl
            FROM dbo.DM_DonVi AS d
            WHERE d.CapDonViId = @WholesaleCapDonViId
              AND d.ViDo IS NOT NULL AND d.KinhDo IS NOT NULL
              AND d.ViDo >= -90 AND d.ViDo <= 90 AND d.KinhDo >= -180 AND d.KinhDo <= 180
              AND NOT (d.ViDo = 0 AND d.KinhDo = 0)
            ORDER BY d.Ten, d.Id;
        END;
        """;

    /// <summary>
    /// Hàm scalar: từ số ngày dự trữ (một nhiên liệu) → <c>0</c> an toàn, <c>1</c> cảnh báo, <c>2</c> nguy cơ.
    /// Đồng bộ lớp <c>LeaderMapDistributorReserveDisplayStatus</c> (API).
    /// </summary>
    internal const string CreateDistributorReserveDisplayStatusFunction =
        """
        CREATE OR ALTER FUNCTION dbo.fn_Leader_Map_DistributorReserveDisplayStatus (@Days INT NULL)
        RETURNS TINYINT
        AS
        BEGIN
            IF @Days IS NULL RETURN 1;
            IF @Days > 10 RETURN 0;
            IF @Days >= 5 AND @Days <= 10 RETURN 1;
            RETURN 2;
        END;
        """;

    /// <summary>Trạm bán lẻ trong khung nhìn bản đồ (cùng logic mở/đóng như <c>sp_Api_StationMap_ListPaged</c>).</summary>
    internal const string CreateRetailStationsListByBounds =
        """
        CREATE OR ALTER PROCEDURE dbo.sp_Leader_Map_RetailStations_ListByBounds
            @RetailCapDonViId INT,
            @DayOfWeek TINYINT,
            @NowTime TIME(0),
            @MinLat FLOAT,
            @MaxLat FLOAT,
            @MinLng FLOAT,
            @MaxLng FLOAT,
            @Status NVARCHAR(20) = NULL,
            @Skip INT = 0,
            @Take INT = 100
        AS
        BEGIN
            SET NOCOUNT ON;

            DECLARE @StatusNorm NVARCHAR(20) = LOWER(LTRIM(RTRIM(@Status)));
            IF @StatusNorm IS NULL OR @StatusNorm = N'' SET @StatusNorm = N'all';

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
                WHERE d.CapDonViId = @RetailCapDonViId
                  AND d.ViDo IS NOT NULL AND d.KinhDo IS NOT NULL
                  AND d.ViDo >= -90 AND d.ViDo <= 90 AND d.KinhDo >= -180 AND d.KinhDo <= 180
                  AND NOT (d.ViDo = 0 AND d.KinhDo = 0)
                  AND CAST(d.ViDo AS float) BETWEEN @MinLat AND @MaxLat
                  AND CAST(d.KinhDo AS float) BETWEEN @MinLng AND @MaxLng
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
                f.CloseTime
            FROM #Filtered AS f
            ORDER BY f.StationName, f.StationMa
            OFFSET @Skip ROWS FETCH NEXT @Take ROWS ONLY;

            DROP TABLE #Filtered;
        END;
        """;

    internal const string CreateBadReportsByStation =
        """
        CREATE OR ALTER PROCEDURE dbo.sp_Leader_Map_BadReports_ByStation
            @StationId INT
        AS
        BEGIN
            SET NOCOUNT ON;

            SELECT
                r.Id,
                r.Content,
                r.CreatedAt,
                CAST(r.Status AS tinyint) AS Status
            FROM dbo.StationBadReports AS r
            WHERE r.StationId = @StationId
            ORDER BY r.CreatedAt DESC, r.Id DESC;
        END;
        """;

    /// <summary>Một đầu mối theo <c>Id</c> (chỉ khi đúng <c>CapDonViId</c>).</summary>
    internal const string CreateDistributorUnitGetById =
        """
        CREATE OR ALTER PROCEDURE dbo.sp_Leader_Map_DistributorUnit_GetById
            @DonViId INT,
            @WholesaleCapDonViId INT
        AS
        BEGIN
            SET NOCOUNT ON;
            SELECT
                d.Id,
                d.Ten AS TenDonVi,
                NULLIF(LTRIM(RTRIM(COALESCE(d.DiaChiChiTiet, d.DiaChi))), N'') AS DiaChi,
                CAST(d.KinhDo AS float) AS KinhDo,
                CAST(d.ViDo AS float) AS ViDo,
                NULLIF(LTRIM(RTRIM(d.LogoUrl)), N'') AS LogoUrl
            FROM dbo.DM_DonVi AS d
            WHERE d.Id = @DonViId
              AND d.CapDonViId = @WholesaleCapDonViId
              AND d.ViDo IS NOT NULL AND d.KinhDo IS NOT NULL
              AND d.ViDo >= -90 AND d.ViDo <= 90 AND d.KinhDo >= -180 AND d.KinhDo <= 180
              AND NOT (d.ViDo = 0 AND d.KinhDo = 0);
        END;
        """;
}
