-- Companion script for EF migration 20260419190855_StationInventoryTransactionDetailsUnitId.
-- EF applies the same steps via MigrationBuilder; run this only for manual DBA review / idempotent ops.

IF COL_LENGTH(N'dbo.StationInventoryTransactionDetails', N'UnitId') IS NULL
BEGIN
    ALTER TABLE dbo.StationInventoryTransactionDetails ADD UnitId INT NULL;
END;

DECLARE @Liter INT = (
    SELECT TOP (1) Id
    FROM dbo.DM_DonViTinh
    WHERE UPPER(LTRIM(RTRIM(ISNULL(Ma, N'')))) IN (N'LIT', N'L', N'LITRE')
       OR LTRIM(RTRIM(ISNULL(Ten, N''))) IN (N'Lít', N'Lit')
    ORDER BY Id);
IF @Liter IS NULL
    SELECT TOP (1) @Liter = Id FROM dbo.DM_DonViTinh ORDER BY Id;
IF @Liter IS NULL
    THROW 50001, N'DM_DonViTinh is empty; cannot backfill UnitId.', 1;

UPDATE d
SET d.UnitId = COALESCE(fp.UnitId, @Liter)
FROM dbo.StationInventoryTransactionDetails AS d
INNER JOIN dbo.FuelProducts AS fp ON fp.Id = d.ProductId
WHERE d.UnitId IS NULL;

UPDATE dbo.StationInventoryTransactionDetails SET UnitId = @Liter WHERE UnitId IS NULL;

ALTER TABLE dbo.StationInventoryTransactionDetails ALTER COLUMN UnitId INT NOT NULL;

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_StationInventoryTransactionDetails_UnitId' AND object_id = OBJECT_ID(N'dbo.StationInventoryTransactionDetails'))
    CREATE NONCLUSTERED INDEX IX_StationInventoryTransactionDetails_UnitId ON dbo.StationInventoryTransactionDetails (UnitId);

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_StationInventoryTransactionDetails_DM_DonViTinh_UnitId')
    ALTER TABLE dbo.StationInventoryTransactionDetails WITH CHECK
    ADD CONSTRAINT FK_StationInventoryTransactionDetails_DM_DonViTinh_UnitId FOREIGN KEY (UnitId) REFERENCES dbo.DM_DonViTinh (Id);

-- Stored procedures are (re)created by the EF migration C# file (same bodies as application upgrade).
