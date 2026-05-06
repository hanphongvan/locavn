namespace Httm.XangDau.Api.Shared.Persistence.Migrations;

/// <summary>
/// SP cho <c>GET /api/leader/retail/*</c> — Lãnh đạo, dashboard cửa hàng bán lẻ.
/// Filter: tỉnh / trạng thái / đơn vị quản lý. Cảnh báo (warning rules) compute ở C# service,
/// SP chỉ trả dữ liệu thuần.
/// </summary>
/// <remarks>
/// Quy ước trạng thái <c>DM_DonVi.TrangThai</c> (đồng bộ với <c>sp_Reports_GetStationOverview</c>):
/// <list type="bullet">
///   <item><description><c>NULL</c> hoặc <c>1</c> ⇒ Hoạt động.</description></item>
///   <item><description><c>0</c> ⇒ Tạm dừng.</description></item>
/// </list>
/// </remarks>
internal static class LeaderRetailStoredProceduresSql
{
    /// <summary>
    /// Dashboard tổng hợp — 3 result set: KPI, ranking theo tỉnh, danh sách cửa hàng (raw cho rule engine C#).
    /// </summary>
    internal const string CreateGetDashboard =
        """
        CREATE OR ALTER PROCEDURE dbo.sp_LeaderRetail_GetDashboard
            @ProvinceId       INT = NULL,
            @Status           BIT = NULL,
            @ManagingUnitId   INT = NULL,
            @RetailCapDonViId INT
        AS
        BEGIN
            SET NOCOUNT ON;

            IF OBJECT_ID('tempdb..#RetailStations', 'U') IS NOT NULL
                DROP TABLE #RetailStations;

            SELECT
                s.Id,
                s.Ten,
                s.Tinh,
                s.CapTrenId,
                s.TrangThai,
                s.ViDo,
                s.KinhDo,
                s.Modified
            INTO #RetailStations
            FROM dbo.DM_DonVi AS s
            WHERE s.CapDonViId = @RetailCapDonViId
              AND (@ProvinceId IS NULL OR s.Tinh = @ProvinceId)
              AND (@ManagingUnitId IS NULL OR s.CapTrenId = @ManagingUnitId)
              AND (
                    @Status IS NULL
                 OR (@Status = 1 AND (s.TrangThai IS NULL OR s.TrangThai = 1))
                 OR (@Status = 0 AND s.TrangThai = 0)
              );

            -- (1) KPI tổng — sau khi đã áp filter.
            -- COUNT_BIG(...) đảm bảo kiểu BIGINT đồng nhất (Dapper match record `(long, long, long)`).
            SELECT
                COUNT_BIG(*) AS TotalStores,
                COUNT_BIG(CASE WHEN s.TrangThai IS NULL OR s.TrangThai = 1 THEN 1 END) AS ActiveStores,
                COUNT_BIG(CASE WHEN s.TrangThai = 0 THEN 1 END) AS PausedStores
            FROM #RetailStations AS s;

            -- (2) Ranking theo tỉnh
            SELECT
                t.Id AS ProvinceId,
                t.Ma AS ProvinceCode,
                t.Ten AS ProvinceName,
                COUNT_BIG(*) AS TotalStores,
                COUNT_BIG(CASE WHEN s.TrangThai IS NULL OR s.TrangThai = 1 THEN 1 END) AS ActiveStores,
                COUNT_BIG(CASE WHEN s.TrangThai = 0 THEN 1 END) AS PausedStores,
                MAX(s.Modified) AS LastUpdatedAt
            FROM #RetailStations AS s
            LEFT JOIN dbo.DM_Tinh AS t ON t.Id = s.Tinh
            GROUP BY t.Id, t.Ma, t.Ten
            ORDER BY
                CASE WHEN t.Ten IS NULL THEN 1 ELSE 0 END,
                t.Ten;

            -- (3) Cửa hàng raw — cho C# warning rule engine (thiếu toạ độ, dữ liệu cũ, chưa có quản lý, …)
            SELECT
                s.Id        AS StationId,
                s.Ten       AS StationName,
                s.Tinh      AS ProvinceId,
                t.Ten       AS ProvinceName,
                s.CapTrenId AS ManagingUnitId,
                p.Ten       AS ManagingUnitName,
                CAST(s.ViDo  AS float) AS ViDo,
                CAST(s.KinhDo AS float) AS KinhDo,
                s.TrangThai,
                s.Modified
            FROM #RetailStations AS s
            LEFT JOIN dbo.DM_Tinh AS t  ON t.Id = s.Tinh
            LEFT JOIN dbo.DM_DonVi AS p ON p.Id = s.CapTrenId;

            DROP TABLE #RetailStations;
        END;
        """;

    internal const string DropGetDashboard =
        "DROP PROCEDURE IF EXISTS dbo.sp_LeaderRetail_GetDashboard;";

    /// <summary>
    /// Danh sách đơn vị quản lý có cửa hàng bán lẻ bên dưới (loại NULL/orphan).
    /// Yêu cầu kép: <c>p.Id ∈ (CapTrenId của các retail rows)</c> AND <c>p.CapDonViId = @RetailCapDonViId</c>
    /// → bản thân managing unit cũng là phân loại retail (loại bỏ parent organization khác).
    /// </summary>
    internal const string CreateGetManagingUnits =
        """
        CREATE OR ALTER PROCEDURE dbo.sp_LeaderRetail_GetManagingUnits
            @RetailCapDonViId INT
        AS
        BEGIN
            SET NOCOUNT ON;

            SELECT
                p.Id  AS ManagingUnitId,
                p.Ma  AS ManagingUnitCode,
                p.Ten AS ManagingUnitName,
                COUNT_BIG(s.Id) AS StoreCount
            FROM dbo.DM_DonVi AS s
            INNER JOIN dbo.DM_DonVi AS p ON p.Id = s.CapTrenId
            WHERE s.CapDonViId = @RetailCapDonViId
              AND s.CapTrenId IS NOT NULL
              AND p.CapDonViId = @RetailCapDonViId
            GROUP BY p.Id, p.Ma, p.Ten
            HAVING COUNT_BIG(s.Id) > 0
            ORDER BY p.Ten;
        END;
        """;

    internal const string DropGetManagingUnits =
        "DROP PROCEDURE IF EXISTS dbo.sp_LeaderRetail_GetManagingUnits;";

    /// <summary>
    /// Danh sách tỉnh có cửa hàng bán lẻ + số lượng (cho dropdown filter mobile).
    /// </summary>
    internal const string CreateGetProvinces =
        """
        CREATE OR ALTER PROCEDURE dbo.sp_LeaderRetail_GetProvinces
            @RetailCapDonViId INT
        AS
        BEGIN
            SET NOCOUNT ON;

            SELECT
                t.Id  AS ProvinceId,
                t.Ma  AS ProvinceCode,
                t.Ten AS ProvinceName,
                COUNT_BIG(s.Id) AS StoreCount
            FROM dbo.DM_DonVi AS s
            INNER JOIN dbo.DM_Tinh AS t ON t.Id = s.Tinh
            WHERE s.CapDonViId = @RetailCapDonViId
            GROUP BY t.Id, t.Ma, t.Ten
            ORDER BY t.Ten;
        END;
        """;

    internal const string DropGetProvinces =
        "DROP PROCEDURE IF EXISTS dbo.sp_LeaderRetail_GetProvinces;";
}
