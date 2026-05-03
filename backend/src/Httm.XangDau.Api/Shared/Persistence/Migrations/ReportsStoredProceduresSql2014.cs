namespace Httm.XangDau.Api.Shared.Persistence.Migrations;

/// <summary>
/// SQL Server 2014-compatible versions of stored procedures for Reports API (replaces CREATE OR ALTER with DROP + CREATE).
/// </summary>
internal static class ReportsStoredProceduresSql2014
{
    /// <summary>
    /// SQL Server 2014-compatible version of <c>dbo.sp_Reports_GetStationOverview</c>.
    /// </summary>
    internal const string GetStationOverview =
        """
        IF OBJECT_ID(N'dbo.sp_Reports_GetStationOverview', N'P') IS NOT NULL
            DROP PROCEDURE dbo.sp_Reports_GetStationOverview;
        GO

        CREATE PROCEDURE dbo.sp_Reports_GetStationOverview
            @RetailCapDonViId INT,
            @DayOfWeek TINYINT,
            @NowTime TIME(0)
        AS
        BEGIN
            SET NOCOUNT ON;

            ;WITH Stations AS (
                SELECT d.Id, d.Tinh, d.TrangThai
                FROM dbo.DM_DonVi AS d
                WHERE d.CapDonViId = @RetailCapDonViId
            ),
            OpenFlags AS (
                SELECT
                    s.Id,
                    CASE
                        WHEN (s.TrangThai IS NULL OR s.TrangThai = 1)
                             AND (
                                 NOT EXISTS (SELECT 1 FROM dbo.StationOperatingHours AS h0 WHERE h0.DonViId = s.Id)
                                 OR NOT EXISTS (
                                     SELECT 1
                                     FROM dbo.StationOperatingHours AS h1
                                     WHERE h1.DonViId = s.Id AND h1.DayOfWeek = @DayOfWeek
                                 )
                                 OR EXISTS (
                                     SELECT 1
                                     FROM dbo.StationOperatingHours AS h
                                     WHERE h.DonViId = s.Id
                                       AND h.DayOfWeek = @DayOfWeek
                                       AND h.IsClosedAllDay = CAST(0 AS bit)
                                       AND (
                                           (h.OpensAt IS NULL AND h.ClosesAt IS NULL)
                                           OR (
                                               h.OpensAt IS NOT NULL
                                               AND h.ClosesAt IS NOT NULL
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
                FROM Stations AS s
            )
            SELECT
                (SELECT COUNT_BIG(*) FROM Stations) AS TotalStations,
                (SELECT COUNT_BIG(*) FROM OpenFlags WHERE IsOpen = 1) AS OpenStations,
                (SELECT COUNT_BIG(*) FROM OpenFlags WHERE IsOpen = 0) AS ClosedStations;

            SELECT
                t.Ma AS ProvinceCode,
                t.Ten AS ProvinceName,
                COUNT_BIG(*) AS StationCount
            FROM Stations AS s
            LEFT JOIN dbo.DM_Tinh AS t ON t.Id = s.Tinh
            GROUP BY t.Ma, t.Ten
            ORDER BY
                CASE WHEN t.Ten IS NULL THEN 1 ELSE 0 END,
                t.Ten,
                t.Ma;
        END;
        """;

    /// <summary>
    /// SQL Server 2014-compatible version of <c>dbo.sp_Reports_GetInventorySummary</c>.
    /// </summary>
    internal const string GetInventorySummary =
        """
        IF OBJECT_ID(N'dbo.sp_Reports_GetInventorySummary', N'P') IS NOT NULL
            DROP PROCEDURE dbo.sp_Reports_GetInventorySummary;
        GO

        CREATE PROCEDURE dbo.sp_Reports_GetInventorySummary
            @KieuKyBaoCao INT = NULL
        AS
        BEGIN
            SET NOCOUNT ON;

            DECLARE @AnchorKieu INT = NULL;
            DECLARE @AnchorTu DATE = NULL;
            DECLARE @AnchorDen DATE = NULL;

            SELECT TOP (1)
                @AnchorKieu = t.KieuKyBaoCao,
                @AnchorTu = t.TuNgay,
                @AnchorDen = t.DenNgay
            FROM dbo.QT_TK_ThongKe AS t
            WHERE t.Loai = 1
              AND t.don_vi_cap1 IS NOT NULL
              AND (@KieuKyBaoCao IS NULL OR t.KieuKyBaoCao = @KieuKyBaoCao)
            ORDER BY t.DenNgay DESC, t.ThoiGianGui DESC, t.Id DESC;

            IF @AnchorDen IS NULL
            BEGIN
                SELECT
                    CAST(NULL AS INT) AS KieuKyBaoCaoId,
                    CAST(NULL AS NVARCHAR(100)) AS KieuKyMa,
                    CAST(NULL AS NVARCHAR(500)) AS KieuKyTen,
                    CAST(NULL AS DATE) AS TuNgay,
                    CAST(NULL AS DATE) AS DenNgay;

                SELECT
                    CAST(0 AS INT) AS ReportingStationCount,
                    CAST(0 AS INT) AS StockLineCount,
                    CAST(NULL AS DECIMAL(28, 3)) AS TotalSo01;

                SELECT
                    CAST(NULL AS INT) AS Nhom,
                    CAST(0 AS INT) AS LineCount,
                    CAST(NULL AS DECIMAL(28, 3)) AS SumSo01
                WHERE 1 = 0;

                RETURN;
            END;

            SELECT
                @AnchorKieu AS KieuKyBaoCaoId,
                (SELECT TOP (1) k.Ma FROM dbo.DM_KieuKyBaoCao AS k WHERE k.Id = @AnchorKieu) AS KieuKyMa,
                (SELECT TOP (1) k.Ten FROM dbo.DM_KieuKyBaoCao AS k WHERE k.Id = @AnchorKieu) AS KieuKyTen,
                @AnchorTu AS TuNgay,
                @AnchorDen AS DenNgay;

            DECLARE @TkIds TABLE (Id UNIQUEIDENTIFIER PRIMARY KEY);
            INSERT INTO @TkIds (Id)
            SELECT t.Id
            FROM dbo.QT_TK_ThongKe AS t
            WHERE t.Loai = 1
              AND t.don_vi_cap1 IS NOT NULL
              AND t.DenNgay = @AnchorDen
              AND (
                  (@AnchorKieu IS NULL AND t.KieuKyBaoCao IS NULL)
                  OR (@AnchorKieu IS NOT NULL AND t.KieuKyBaoCao = @AnchorKieu)
              )
              AND (
                  (@AnchorTu IS NULL AND t.TuNgay IS NULL)
                  OR (@AnchorTu IS NOT NULL AND t.TuNgay = @AnchorTu)
              );

            SELECT
                (
                    SELECT COUNT_BIG(DISTINCT t.don_vi_cap1)
                    FROM dbo.QT_TK_ThongKe AS t
                    INNER JOIN @TkIds AS i ON i.Id = t.Id
                    WHERE t.don_vi_cap1 IS NOT NULL
                ) AS ReportingStationCount,
                (
                    SELECT COUNT_BIG(*)
                    FROM dbo.QT_TK_ThongKeChiTiet AS l
                    INNER JOIN @TkIds AS i ON i.Id = l.ThongKeId
                    WHERE l.LoaiGia IS NULL
                      AND l.ThoiDiemDinhGia IS NULL
                      AND (l.So_01 IS NOT NULL OR l.So_02 IS NOT NULL OR l.So_03 IS NOT NULL)
                      AND (l.Xoa IS NULL OR l.Xoa = 0)
                ) AS StockLineCount,
                (
                    SELECT SUM(CAST(l.So_01 AS DECIMAL(28, 3)))
                    FROM dbo.QT_TK_ThongKeChiTiet AS l
                    INNER JOIN @TkIds AS i ON i.Id = l.ThongKeId
                    WHERE l.LoaiGia IS NULL
                      AND l.ThoiDiemDinhGia IS NULL
                      AND (l.So_01 IS NOT NULL OR l.So_02 IS NOT NULL OR l.So_03 IS NOT NULL)
                      AND (l.Xoa IS NULL OR l.Xoa = 0)
                ) AS TotalSo01;

            SELECT
                l.Nhom,
                COUNT_BIG(*) AS LineCount,
                SUM(CAST(l.So_01 AS DECIMAL(28, 3))) AS SumSo01
            FROM dbo.QT_TK_ThongKeChiTiet AS l
            INNER JOIN @TkIds AS i ON i.Id = l.ThongKeId
            WHERE l.LoaiGia IS NULL
              AND l.ThoiDiemDinhGia IS NULL
              AND (l.So_01 IS NOT NULL OR l.So_02 IS NOT NULL OR l.So_03 IS NOT NULL)
              AND (l.Xoa IS NULL OR l.Xoa = 0)
            GROUP BY l.Nhom
            ORDER BY l.Nhom;
        END;
        """;

    /// <summary>
    /// SQL Server 2014-compatible version of <c>dbo.sp_Reports_CheckKieuKyBaoCaoExists</c>.
    /// </summary>
    internal const string CheckKieuKyBaoCaoExists =
        """
        IF OBJECT_ID(N'dbo.sp_Reports_CheckKieuKyBaoCaoExists', N'P') IS NOT NULL
            DROP PROCEDURE dbo.sp_Reports_CheckKieuKyBaoCaoExists;
        GO

        CREATE PROCEDURE dbo.sp_Reports_CheckKieuKyBaoCaoExists
            @Id INT
        AS
        BEGIN
            SET NOCOUNT ON;

            SELECT CAST(
                       CASE
                           WHEN EXISTS (SELECT 1 FROM dbo.DM_KieuKyBaoCao WHERE Id = @Id) THEN 1
                           ELSE 0
                       END AS BIT) AS [Exists];
        END;
        """;
}
