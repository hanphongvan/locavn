-- Companion script for EF Core migration `20260601130000_FixLeaderRetailDashboardCountTypes`.
-- Source of truth: Shared/Persistence/Migrations/LeaderRetailStoredProceduresSql.cs
--
-- Mục đích: sửa `dbo.sp_LeaderRetail_GetDashboard` — đổi `SUM(CASE WHEN ... THEN 1 ELSE 0 END)` (INT)
-- sang `COUNT_BIG(CASE WHEN ... THEN 1 END)` (BIGINT) cho `ActiveStores`/`PausedStores` ở cả KPI lẫn ranking.
-- Trước fix Dapper báo: "A parameterless default constructor or one matching signature
-- (System.Int64 TotalStores, System.Int32 ActiveStores, System.Int32 PausedStores) is required for
-- LeaderRetailKpiDto materialization".
--
-- Idempotent: SP body dùng `CREATE OR ALTER`, `__EFMigrationsHistory` có guard `IF NOT EXISTS`.
-- Bảng/cột/index/FK bị ảnh hưởng: KHÔNG. Chỉ cập nhật stored procedure đã có.

BEGIN TRANSACTION;
GO

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
GO

IF NOT EXISTS (
    SELECT 1 FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260601130000_FixLeaderRetailDashboardCountTypes'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260601130000_FixLeaderRetailDashboardCountTypes', N'10.0.0');
END;
GO

COMMIT;
GO
