-- Inventory map: dbo.sp_StoreAdmin_InventoryMap_ListByGroupCode
-- Demo phase — store list + stock for map UI. Re-run after changes (CREATE OR ALTER).
-- MapStores: dbo.DM_DonVi with CapDonViId = 248, ViDo and KinhDo NOT NULL.
--
-- PARAMETER
--   @GroupCode nvarchar(50) — XANG | DAU (case-insensitive).
--
-- RESULT SET (column names stable for Angular / Flutter)
--   StationId       int           DM_DonVi.Id
--   StationCode     nvarchar      DM_DonVi.Ma
--   StationName     nvarchar      DM_DonVi.Ten
--   Address         nvarchar      DiaChi + DiaChiChiTiet (trimmed), may be NULL
--   Latitude        float         DM_DonVi.ViDo
--   Longitude       float         DM_DonVi.KinhDo
--   CurrentQuantity decimal(18,4) Real SUM for group when detail data exists; else deterministic demo quantity (same Id+group → same value)
--   StockStatus     varchar(16)   out | low | normal (computed in SQL only)

CREATE OR ALTER PROCEDURE dbo.sp_StoreAdmin_InventoryMap_ListByGroupCode
    @GroupCode NVARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;

    IF @GroupCode IS NULL OR LTRIM(RTRIM(@GroupCode)) = N''
    BEGIN
        RAISERROR(N'groupCode is required (XANG or DAU).', 16, 1);
        RETURN;
    END;

    DECLARE @GroupNorm NVARCHAR(50) = UPPER(LTRIM(RTRIM(@GroupCode)));
    IF @GroupNorm NOT IN (N'XANG', N'DAU')
    BEGIN
        RAISERROR(N'groupCode must be XANG or DAU.', 16, 1);
        RETURN;
    END;

    DECLARE @RetailCapDonViId INT = 248;
    DECLARE @LowStockThreshold DECIMAL(18, 4) = CAST(500 AS DECIMAL(18, 4));

    ;WITH MapStores AS (
        SELECT dv.Id
        FROM dbo.DM_DonVi AS dv
        WHERE dv.CapDonViId = @RetailCapDonViId
          AND dv.ViDo IS NOT NULL
          AND dv.KinhDo IS NOT NULL
    ),
    Grp AS (
        SELECT g.Id
        FROM dbo.FuelProducts AS g
        WHERE UPPER(LTRIM(RTRIM(g.Code))) = @GroupNorm
    ),
    DownTree AS (
        SELECT fp.Id, fp.ParentId
        FROM dbo.FuelProducts AS fp
        INNER JOIN Grp AS r ON fp.ParentId = r.Id
        WHERE fp.IsActive = 1
        UNION ALL
        SELECT c.Id, c.ParentId
        FROM dbo.FuelProducts AS c
        INNER JOIN DownTree AS d ON c.ParentId = d.Id
        WHERE c.IsActive = 1
    ),
    LeafProducts AS (
        SELECT d.Id AS ProductId
        FROM DownTree AS d
        WHERE NOT EXISTS (SELECT 1 FROM dbo.FuelProducts AS ch WHERE ch.ParentId = d.Id)
    ),
    FilteredTx AS (
        SELECT
            h.DonViId,
            d.ProductId,
            h.TransactionType,
            CAST(d.Quantity AS DECIMAL(18, 4)) AS QuantityForStock
        FROM dbo.StationInventoryTransactionDetails AS d
        INNER JOIN dbo.StationInventoryTransactionHeaders AS h ON h.Id = d.HeaderId
        INNER JOIN dbo.DM_DonVi AS dv ON dv.Id = h.DonViId AND dv.CapDonViId = @RetailCapDonViId
        INNER JOIN MapStores AS ms ON ms.Id = h.DonViId
        INNER JOIN LeafProducts AS lp ON lp.ProductId = d.ProductId
    ),
    QtyByStore AS (
        SELECT
            ft.DonViId,
            CAST(SUM(ft.QuantityForStock * CAST(ft.TransactionType AS DECIMAL(18, 4))) AS DECIMAL(18, 4)) AS CurrentQuantity
        FROM FilteredTx AS ft
        GROUP BY ft.DonViId
    ),
    Rows AS (
        SELECT
            dv.Id AS StationId,
            dv.Ma AS StationCode,
            dv.Ten AS StationName,
            Address = NULLIF(
                LTRIM(RTRIM(CONCAT(ISNULL(dv.DiaChi, N''), N' ', ISNULL(dv.DiaChiChiTiet, N'')))),
                N''),
            Latitude = TRY_CONVERT(FLOAT, dv.ViDo),
            Longitude = TRY_CONVERT(FLOAT, dv.KinhDo),
            RealQty = q.CurrentQuantity,
            HasRealAgg = CASE WHEN q.DonViId IS NOT NULL THEN 1 ELSE 0 END,
            DemoQty = CAST(
                (ABS(CHECKSUM(dv.Id, BINARY_CHECKSUM(@GroupNorm))) % 9000) AS DECIMAL(18, 4)) / CAST(9.0 AS DECIMAL(18, 4))
        FROM dbo.DM_DonVi AS dv
        INNER JOIN MapStores AS ms ON ms.Id = dv.Id
        LEFT JOIN QtyByStore AS q ON q.DonViId = dv.Id
    )
    SELECT
        r.StationId,
        r.StationCode,
        r.StationName,
        r.Address,
        r.Latitude,
        r.Longitude,
        CurrentQuantity = CAST(
            CASE WHEN r.HasRealAgg = 1 THEN ISNULL(r.RealQty, CAST(0 AS DECIMAL(18, 4))) ELSE r.DemoQty END AS DECIMAL(18, 4)),
        StockStatus = CAST(
            CASE
                WHEN (CASE WHEN r.HasRealAgg = 1 THEN ISNULL(r.RealQty, CAST(0 AS DECIMAL(18, 4))) ELSE r.DemoQty END) <= 0
                    THEN N'out'
                WHEN (CASE WHEN r.HasRealAgg = 1 THEN ISNULL(r.RealQty, CAST(0 AS DECIMAL(18, 4))) ELSE r.DemoQty END) < @LowStockThreshold
                    THEN N'low'
                ELSE N'normal'
            END AS VARCHAR(16))
    FROM Rows AS r
    ORDER BY r.StationName, r.StationCode;
END;
