namespace Httm.XangDau.Api.Shared.Persistence.Migrations;

/// <summary>
/// Public API: <c>GET /api/stations</c> list + keyword search (Dapper; <c>docs/architecture/backend.md</c>).
/// Visitor open/closed rules align with <see cref="Httm.XangDau.Api.Features.Stations.Services.StationVisitorQueryFilters"/> and <c>dbo.sp_Reports_GetStationOverview</c>.
/// </summary>
internal static class ApiStationSearchStoredProceduresSql
{
    /// <summary>
    /// Result set 1: single row <c>TotalCount</c>. Result set 2: page rows (same shape as former LINQ projection).
    /// </summary>
    internal const string StationSearch =
        """
        CREATE OR ALTER PROCEDURE dbo.sp_Station_Search
            @Keyword NVARCHAR(200) = NULL,
            @ProvinceMa NVARCHAR(20) = NULL,
            @QuanHuyenId INT = NULL,
            @Status NVARCHAR(20) = NULL,
            @DayOfWeek TINYINT,
            @NowTime TIME(0),
            @RetailCapDonViId INT,
            @Skip INT,
            @Take INT
        AS
        BEGIN
            SET NOCOUNT ON;

            DECLARE @KwTrim NVARCHAR(200) = NULLIF(LTRIM(RTRIM(@Keyword)), N'');

            CREATE TABLE #Filtered (
                Id INT NOT NULL,
                Ma NVARCHAR(100),
                Ten NVARCHAR(500),
                AddressLine NVARCHAR(MAX),
                ProvinceCode NVARCHAR(20),
                ProvinceName NVARCHAR(100),
                WardCode NVARCHAR(20),
                WardName NVARCHAR(100),
                DistrictId INT,
                LicenseNumber NVARCHAR(100),
                IsActive BIT,
                OpenTime TIME(0),
                CloseTime TIME(0)
            );

            ;WITH Base AS (
                SELECT
                    d.Id,
                    d.Ma,
                    d.Ten,
                    ISNULL(d.DiaChiChiTiet, d.DiaChi) AS AddressLine,
                    t.Ma AS ProvinceCode,
                    t.Ten AS ProvinceName,
                    x.Ma AS WardCode,
                    x.Ten AS WardName,
                    x.QuanHuyenId AS DistrictId,
                    d.SoGiayPhep AS LicenseNumber,
                    d.TrangThai AS IsActive,
                    d.OpenTime,
                    d.CloseTime
                FROM dbo.DM_DonVi AS d
                LEFT JOIN dbo.DM_Tinh AS t ON t.Id = d.Tinh
                LEFT JOIN dbo.DM_XaPhuong AS x ON x.Id = d.Xa
                WHERE d.CapDonViId = @RetailCapDonViId
                  AND (@ProvinceMa IS NULL OR t.Ma = @ProvinceMa)
                  AND (@QuanHuyenId IS NULL OR x.QuanHuyenId = @QuanHuyenId)
                  AND (
                      @KwTrim IS NULL
                      OR d.Ten LIKE N'%' + @KwTrim + N'%'
                      OR d.Ma LIKE N'%' + @KwTrim + N'%'
                      OR (d.DiaChiChiTiet IS NOT NULL AND d.DiaChiChiTiet LIKE N'%' + @KwTrim + N'%')
                      OR (d.DiaChi IS NOT NULL AND d.DiaChi LIKE N'%' + @KwTrim + N'%')
                      OR (d.SoGiayPhep IS NOT NULL AND d.SoGiayPhep LIKE N'%' + @KwTrim + N'%')
                  )
            ),
            OpenFlags AS (
                SELECT
                    b.Id,
                    b.Ma,
                    b.Ten,
                    b.AddressLine,
                    b.ProvinceCode,
                    b.ProvinceName,
                    b.WardCode,
                    b.WardName,
                    b.DistrictId,
                    b.LicenseNumber,
                    b.IsActive,
                    b.OpenTime,
                    b.CloseTime,
                    CASE
                        WHEN (b.IsActive IS NULL OR b.IsActive = CAST(1 AS bit))
                             AND (
                                 NOT EXISTS (SELECT 1 FROM dbo.StationOperatingHours AS h0 WHERE h0.DonViId = b.Id)
                                 OR NOT EXISTS (
                                     SELECT 1
                                     FROM dbo.StationOperatingHours AS h1
                                     WHERE h1.DonViId = b.Id AND h1.DayOfWeek = @DayOfWeek
                                 )
                                 OR EXISTS (
                                     SELECT 1
                                     FROM dbo.StationOperatingHours AS h
                                     WHERE h.DonViId = b.Id
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
                    END AS IsVisitorOpen
                FROM Base AS b
            )
            INSERT INTO #Filtered (Id, Ma, Ten, AddressLine, ProvinceCode, ProvinceName, WardCode, WardName, DistrictId, LicenseNumber, IsActive, OpenTime, CloseTime)
            SELECT
                o.Id,
                o.Ma,
                o.Ten,
                o.AddressLine,
                o.ProvinceCode,
                o.ProvinceName,
                o.WardCode,
                o.WardName,
                o.DistrictId,
                o.LicenseNumber,
                o.IsActive,
                o.OpenTime,
                o.CloseTime
            FROM OpenFlags AS o
            WHERE (
                @Status IS NULL
                OR LTRIM(RTRIM(@Status)) = N''
                OR LOWER(LTRIM(RTRIM(@Status))) = N'all'
                OR (LOWER(LTRIM(RTRIM(@Status))) = N'open' AND o.IsVisitorOpen = 1)
                OR (LOWER(LTRIM(RTRIM(@Status))) = N'closed' AND o.IsVisitorOpen = 0)
            );

            SELECT COUNT_BIG(1) AS TotalCount
            FROM #Filtered;

            SELECT
                f.Id AS StationId,
                f.Ma AS StationCode,
                f.Ten AS StationName,
                f.AddressLine,
                f.ProvinceCode,
                f.ProvinceName,
                f.WardCode,
                f.WardName,
                f.DistrictId,
                f.LicenseNumber,
                f.IsActive,
                f.OpenTime,
                f.CloseTime
            FROM #Filtered AS f
            ORDER BY f.Ten, f.Ma
            OFFSET @Skip ROWS FETCH NEXT @Take ROWS ONLY;

            DROP TABLE #Filtered;
        END;
        """;
}
