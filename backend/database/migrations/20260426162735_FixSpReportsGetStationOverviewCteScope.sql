-- Matches EF migration 20260426162735_FixSpReportsGetStationOverviewCteScope.
-- Fixes: second result set referenced CTE "Stations" out of scope → Invalid object name 'Stations'.
-- Source of truth: Shared/Persistence/Migrations/ReportsStoredProcedures.cs → GetStationOverview

CREATE OR ALTER PROCEDURE dbo.sp_Reports_GetStationOverview
    @RetailCapDonViId INT,
    @DayOfWeek TINYINT,
    @NowTime TIME(0)
AS
BEGIN
    SET NOCOUNT ON;

    IF OBJECT_ID('tempdb..#Stations', 'U') IS NOT NULL
        DROP TABLE #Stations;

    SELECT d.Id, d.Tinh, d.TrangThai
    INTO #Stations
    FROM dbo.DM_DonVi AS d
    WHERE d.CapDonViId = @RetailCapDonViId;

    ;WITH OpenFlags AS (
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
        FROM #Stations AS s
    )
    SELECT
        (SELECT COUNT_BIG(*) FROM #Stations) AS TotalStations,
        (SELECT COUNT_BIG(*) FROM OpenFlags WHERE IsOpen = 1) AS OpenStations,
        (SELECT COUNT_BIG(*) FROM OpenFlags WHERE IsOpen = 0) AS ClosedStations;

    SELECT
        t.Ma AS ProvinceCode,
        t.Ten AS ProvinceName,
        COUNT_BIG(*) AS StationCount
    FROM #Stations AS s
    LEFT JOIN dbo.DM_Tinh AS t ON t.Id = s.Tinh
    GROUP BY t.Ma, t.Ten
    ORDER BY
        CASE WHEN t.Ten IS NULL THEN 1 ELSE 0 END,
        t.Ten,
        t.Ma;

    DROP TABLE #Stations;
END;
GO
