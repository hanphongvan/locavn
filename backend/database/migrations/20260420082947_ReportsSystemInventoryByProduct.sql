-- Mirrors EF migration ReportsSystemInventoryByProduct.
-- Source of truth: Shared/Persistence/Migrations/ReportsStoredProcedures.cs

IF OBJECT_ID(N'dbo.sp_Reports_GetInventorySummary', N'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_Reports_GetInventorySummary;
GO

CREATE OR ALTER PROCEDURE dbo.sp_Reports_GetSystemInventoryByProduct
    @RetailCapDonViId INT
AS
BEGIN
    SET NOCOUNT ON;

    ;WITH FilteredTx AS (
        SELECT
            d.ProductId,
            h.TransactionType,
            h.TransactionDate,
            ResolvedUnitId = COALESCE(d.UnitId, fp.UnitId),
            QuantityForStock = CAST(d.Quantity AS DECIMAL(18, 4))
        FROM dbo.StationInventoryTransactionDetails AS d
        INNER JOIN dbo.StationInventoryTransactionHeaders AS h ON h.Id = d.HeaderId
        INNER JOIN dbo.FuelProducts AS fp ON fp.Id = d.ProductId
        INNER JOIN dbo.DM_DonVi AS dv ON dv.Id = h.DonViId AND dv.CapDonViId = @RetailCapDonViId
    )
    SELECT
        ft.ProductId,
        MAX(fp.Code) AS ProductCode,
        MAX(fp.Name) AS ProductName,
        SUM(CAST(ft.QuantityForStock AS DECIMAL(18, 4)) * CAST(ft.TransactionType AS DECIMAL(18, 4))) AS CurrentQuantity,
        MAX(ft.ResolvedUnitId) AS UnitId,
        MAX(u.Ma) AS UnitMa,
        MAX(u.Ten) AS UnitTen,
        MAX(ft.TransactionDate) AS LastTransactionDate
    FROM FilteredTx AS ft
    INNER JOIN dbo.FuelProducts AS fp ON fp.Id = ft.ProductId
    LEFT JOIN dbo.DM_DonViTinh AS u ON u.Id = ft.ResolvedUnitId
    GROUP BY ft.ProductId
    HAVING ABS(SUM(CAST(ft.QuantityForStock AS DECIMAL(18, 4)) * CAST(ft.TransactionType AS DECIMAL(18, 4)))) > 0.0000001
    ORDER BY MAX(fp.Name), ft.ProductId;
END;
GO
