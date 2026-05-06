-- Companion script for EF Core migration `20260601140000_FixLeaderRetailManagingUnitsRequireRetailCapDonViId`.
-- Source of truth: Shared/Persistence/Migrations/LeaderRetailStoredProceduresSql.cs
--
-- Mục đích: thêm điều kiện `p.CapDonViId = @RetailCapDonViId` vào `dbo.sp_LeaderRetail_GetManagingUnits`
-- — đơn vị quản lý cũng phải thuộc phân loại retail (CapDonViId = 248). Giảm cardinality từ ~8.177 đơn vị
-- (kèm parent organization khác) xuống đúng tập retail-classified managing units.
--
-- Idempotent: SP body dùng `CREATE OR ALTER`, `__EFMigrationsHistory` có guard `IF NOT EXISTS`.
-- Bảng/cột/index/FK bị ảnh hưởng: KHÔNG. Chỉ cập nhật stored procedure đã có.

BEGIN TRANSACTION;
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
      AND p.CapDonViId = @RetailCapDonViId
    GROUP BY p.Id, p.Ma, p.Ten
    HAVING COUNT_BIG(s.Id) > 0
    ORDER BY p.Ten;
END;
GO

IF NOT EXISTS (
    SELECT 1 FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260601140000_FixLeaderRetailManagingUnitsRequireRetailCapDonViId'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260601140000_FixLeaderRetailManagingUnitsRequireRetailCapDonViId', N'10.0.0');
END;
GO

COMMIT;
GO
