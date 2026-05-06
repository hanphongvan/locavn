-- Companion script for EF Core migration `20260601120000_AddLeaderRetailQueriesAndStoredProcedures`.
-- Source of truth: Shared/Persistence/Migrations/LeaderRetailStoredProceduresSql.cs
--
-- Idempotent: SP body dùng `CREATE OR ALTER` (chạy lại an toàn);
-- `__EFMigrationsHistory` được insert có guard `IF NOT EXISTS` để khớp pattern EF.
-- Không bọc CREATE PROCEDURE trong IF/BEGIN/END (vi phạm rule first-in-batch của SQL Server) —
-- thay vào đó tách batch bằng `GO` giữa các CREATE OR ALTER.
--
-- Bảng/cột/index/FK bị ảnh hưởng: KHÔNG. Chỉ tạo/cập nhật 3 stored procedure.

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
    GROUP BY p.Id, p.Ma, p.Ten
    HAVING COUNT_BIG(s.Id) > 0
    ORDER BY p.Ten;
END;
GO

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
GO

IF NOT EXISTS (
    SELECT 1 FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260601120000_AddLeaderRetailQueriesAndStoredProcedures'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260601120000_AddLeaderRetailQueriesAndStoredProcedures', N'10.0.0');
END;
GO

COMMIT;
GO
