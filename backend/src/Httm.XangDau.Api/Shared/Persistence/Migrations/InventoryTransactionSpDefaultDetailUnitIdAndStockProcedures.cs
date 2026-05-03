namespace Httm.XangDau.Api.Shared.Persistence.Migrations;

/// <summary>
/// SQL for <see cref="InventorySpDefaultDetailUnitIdAndStockQuantityBase"/> — optional <c>@DefaultDetailUnitId</c> on save/update XML parse;
/// inventory-current uses <c>QuantityForStock</c> hook (demo: equals line quantity; future: unit conversion).
/// </summary>
internal static class InventoryTransactionSpDefaultDetailUnitIdAndStockProcedures
{
    internal const string SaveWithDetails =
        """
        CREATE OR ALTER PROCEDURE dbo.sp_StoreAdmin_StationInventoryTransactionHeaders_SaveWithDetails
            @DonViId INT,
            @TransactionType INT,
            @TransactionDate DATETIME,
            @HeaderNote NVARCHAR(500) = NULL,
            @Actor NVARCHAR(100),
            @RetailCapDonViId INT,
            @RowsXml NVARCHAR(MAX),
            @DefaultDetailUnitId INT = NULL,
            @HeaderId INT OUTPUT
        AS
        BEGIN
            SET NOCOUNT ON;
            SET @HeaderId = NULL;

            IF @RowsXml IS NULL OR LTRIM(RTRIM(@RowsXml)) = N''
            BEGIN
                RAISERROR(N'Rows payload is required.', 16, 1);
                RETURN;
            END;

            IF @TransactionType NOT IN (1, -1)
            BEGIN
                RAISERROR(N'TransactionType must be 1 (nhập) or -1 (xuất).', 16, 1);
                RETURN;
            END;

            IF NOT EXISTS (SELECT 1 FROM dbo.DM_DonVi WHERE Id = @DonViId AND CapDonViId = @RetailCapDonViId)
            BEGIN
                RAISERROR(N'DonViId is not a valid retail store for this cap.', 16, 1);
                RETURN;
            END;

            IF @DefaultDetailUnitId IS NOT NULL
               AND (
                   @DefaultDetailUnitId < 1
                   OR NOT EXISTS (SELECT 1 FROM dbo.DM_DonViTinh AS u WHERE u.Id = @DefaultDetailUnitId))
            BEGIN
                RAISERROR(N'DefaultDetailUnitId must be NULL or a valid DM_DonViTinh id.', 16, 1);
                RETURN;
            END;

            CREATE TABLE #Rows (
                ProductId INT NOT NULL,
                Quantity DECIMAL(18, 3) NOT NULL,
                Amount DECIMAL(18, 2) NULL,
                Note NVARCHAR(500) NULL,
                UnitId INT NOT NULL);

            DECLARE @x XML;
            BEGIN TRY
                SET @x = CAST(LTRIM(RTRIM(@RowsXml)) AS XML);
            END TRY
            BEGIN CATCH
                RAISERROR(N'Rows payload is not valid XML.', 16, 1);
                RETURN;
            END CATCH;

            INSERT INTO #Rows (ProductId, Quantity, Amount, Note, UnitId)
            SELECT
                T.c.value('@productId', 'INT'),
                T.c.value('@quantity', 'DECIMAL(18,3)'),
                CASE WHEN T.c.exist('@amount') = 1 THEN T.c.value('@amount', 'DECIMAL(18,2)') END,
                NULLIF(LTRIM(RTRIM(T.c.value('@note', 'NVARCHAR(500)'))), N''),
                COALESCE(
                    NULLIF(CASE WHEN T.c.exist('@unitId') = 1 THEN TRY_CAST(T.c.value('@unitId', 'INT') AS INT) END, 0),
                    NULLIF(@DefaultDetailUnitId, 0))
            FROM @x.nodes('/rows/r') AS T(c);

            IF NOT EXISTS (SELECT 1 FROM #Rows)
            BEGIN
                RAISERROR(N'No valid rows in payload.', 16, 1);
                RETURN;
            END;

            IF EXISTS (SELECT 1 FROM #Rows WHERE ProductId IS NULL OR Quantity IS NULL)
            BEGIN
                RAISERROR(N'Each row must have productId and quantity.', 16, 1);
                RETURN;
            END;

            IF EXISTS (SELECT 1 FROM #Rows WHERE UnitId IS NULL OR UnitId < 1)
            BEGIN
                RAISERROR(N'Each row must include a valid unitId attribute (or pass @DefaultDetailUnitId).', 16, 1);
                RETURN;
            END;

            IF EXISTS (SELECT 1 FROM #Rows WHERE Quantity <= 0)
            BEGIN
                RAISERROR(N'Each quantity must be > 0.', 16, 1);
                RETURN;
            END;

            IF EXISTS (SELECT 1 FROM #Rows WHERE Amount IS NOT NULL AND Amount < 0)
            BEGIN
                RAISERROR(N'Each amount must be >= 0 when provided.', 16, 1);
                RETURN;
            END;

            IF EXISTS (
                SELECT r.ProductId
                FROM #Rows r
                GROUP BY r.ProductId
                HAVING COUNT(1) > 1)
            BEGIN
                RAISERROR(N'Duplicate productId in the same submission.', 16, 1);
                RETURN;
            END;

            IF EXISTS (
                SELECT 1
                FROM #Rows r
                WHERE NOT EXISTS (SELECT 1 FROM dbo.FuelProducts fp WHERE fp.Id = r.ProductId))
            BEGIN
                RAISERROR(N'One or more productId values do not exist.', 16, 1);
                RETURN;
            END;

            IF EXISTS (
                SELECT 1
                FROM #Rows r
                WHERE NOT EXISTS (SELECT 1 FROM dbo.DM_DonViTinh u WHERE u.Id = r.UnitId))
            BEGIN
                RAISERROR(N'One or more unitId values do not exist in DM_DonViTinh.', 16, 1);
                RETURN;
            END;

            DECLARE @Now DATETIME = SYSUTCDATETIME();

            BEGIN TRANSACTION;
            BEGIN TRY
                INSERT INTO dbo.StationInventoryTransactionHeaders (
                    DonViId,
                    TransactionType,
                    TransactionDate,
                    Note,
                    Created,
                    CreatedBy,
                    Modified,
                    ModifiedBy)
                VALUES (
                    @DonViId,
                    @TransactionType,
                    @TransactionDate,
                    NULLIF(LTRIM(RTRIM(@HeaderNote)), N''),
                    @Now,
                    @Actor,
                    @Now,
                    @Actor);

                SET @HeaderId = CAST(SCOPE_IDENTITY() AS INT);

                INSERT INTO dbo.StationInventoryTransactionDetails (HeaderId, ProductId, UnitId, Quantity, Amount, Note)
                SELECT @HeaderId, r.ProductId, r.UnitId, r.Quantity, r.Amount, r.Note
                FROM #Rows r;

                COMMIT TRANSACTION;
            END TRY
            BEGIN CATCH
                IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
                THROW;
            END CATCH;
        END;
        """;

    internal const string UpdateWithDetails =
        """
        CREATE OR ALTER PROCEDURE dbo.sp_StoreAdmin_StationInventoryTransactionHeaders_UpdateWithDetails
            @HeaderId INT,
            @DonViId INT,
            @TransactionType INT,
            @TransactionDate DATETIME,
            @HeaderNote NVARCHAR(500) = NULL,
            @Actor NVARCHAR(100),
            @RetailCapDonViId INT,
            @RowsXml NVARCHAR(MAX),
            @DefaultDetailUnitId INT = NULL
        AS
        BEGIN
            SET NOCOUNT ON;

            IF @RowsXml IS NULL OR LTRIM(RTRIM(@RowsXml)) = N''
            BEGIN
                RAISERROR(N'Rows payload is required.', 16, 1);
                RETURN;
            END;

            IF @TransactionType NOT IN (1, -1)
            BEGIN
                RAISERROR(N'TransactionType must be 1 (nhập) or -1 (xuất).', 16, 1);
                RETURN;
            END;

            IF NOT EXISTS (
                SELECT 1
                FROM dbo.StationInventoryTransactionHeaders h
                INNER JOIN dbo.DM_DonVi dv ON dv.Id = h.DonViId AND dv.CapDonViId = @RetailCapDonViId
                WHERE h.Id = @HeaderId)
            BEGIN
                RAISERROR(N'Header not found or not a retail store for this cap.', 16, 1);
                RETURN;
            END;

            IF NOT EXISTS (SELECT 1 FROM dbo.DM_DonVi WHERE Id = @DonViId AND CapDonViId = @RetailCapDonViId)
            BEGIN
                RAISERROR(N'DonViId is not a valid retail store for this cap.', 16, 1);
                RETURN;
            END;

            IF @DefaultDetailUnitId IS NOT NULL
               AND (
                   @DefaultDetailUnitId < 1
                   OR NOT EXISTS (SELECT 1 FROM dbo.DM_DonViTinh AS u WHERE u.Id = @DefaultDetailUnitId))
            BEGIN
                RAISERROR(N'DefaultDetailUnitId must be NULL or a valid DM_DonViTinh id.', 16, 1);
                RETURN;
            END;

            CREATE TABLE #Rows (
                ProductId INT NOT NULL,
                Quantity DECIMAL(18, 3) NOT NULL,
                Amount DECIMAL(18, 2) NULL,
                Note NVARCHAR(500) NULL,
                UnitId INT NOT NULL);

            DECLARE @x XML;
            BEGIN TRY
                SET @x = CAST(LTRIM(RTRIM(@RowsXml)) AS XML);
            END TRY
            BEGIN CATCH
                RAISERROR(N'Rows payload is not valid XML.', 16, 1);
                RETURN;
            END CATCH;

            INSERT INTO #Rows (ProductId, Quantity, Amount, Note, UnitId)
            SELECT
                T.c.value('@productId', 'INT'),
                T.c.value('@quantity', 'DECIMAL(18,3)'),
                CASE WHEN T.c.exist('@amount') = 1 THEN T.c.value('@amount', 'DECIMAL(18,2)') END,
                NULLIF(LTRIM(RTRIM(T.c.value('@note', 'NVARCHAR(500)'))), N''),
                COALESCE(
                    NULLIF(CASE WHEN T.c.exist('@unitId') = 1 THEN TRY_CAST(T.c.value('@unitId', 'INT') AS INT) END, 0),
                    NULLIF(@DefaultDetailUnitId, 0))
            FROM @x.nodes('/rows/r') AS T(c);

            IF NOT EXISTS (SELECT 1 FROM #Rows)
            BEGIN
                RAISERROR(N'No valid rows in payload.', 16, 1);
                RETURN;
            END;

            IF EXISTS (SELECT 1 FROM #Rows WHERE UnitId IS NULL OR UnitId < 1)
            BEGIN
                RAISERROR(N'Each row must include a valid unitId attribute (or pass @DefaultDetailUnitId).', 16, 1);
                RETURN;
            END;

            IF EXISTS (SELECT 1 FROM #Rows WHERE ProductId IS NULL OR Quantity IS NULL OR Quantity <= 0)
            BEGIN
                RAISERROR(N'Each row must have productId and quantity > 0.', 16, 1);
                RETURN;
            END;

            IF EXISTS (SELECT 1 FROM #Rows WHERE Amount IS NOT NULL AND Amount < 0)
            BEGIN
                RAISERROR(N'Each amount must be >= 0 when provided.', 16, 1);
                RETURN;
            END;

            IF EXISTS (
                SELECT r.ProductId FROM #Rows r GROUP BY r.ProductId HAVING COUNT(1) > 1)
            BEGIN
                RAISERROR(N'Duplicate productId in the same submission.', 16, 1);
                RETURN;
            END;

            IF EXISTS (
                SELECT 1 FROM #Rows r
                WHERE NOT EXISTS (SELECT 1 FROM dbo.FuelProducts fp WHERE fp.Id = r.ProductId))
            BEGIN
                RAISERROR(N'One or more productId values do not exist.', 16, 1);
                RETURN;
            END;

            IF EXISTS (
                SELECT 1 FROM #Rows r
                WHERE NOT EXISTS (SELECT 1 FROM dbo.DM_DonViTinh u WHERE u.Id = r.UnitId))
            BEGIN
                RAISERROR(N'One or more unitId values do not exist in DM_DonViTinh.', 16, 1);
                RETURN;
            END;

            DECLARE @Now DATETIME = SYSUTCDATETIME();

            BEGIN TRANSACTION;
            BEGIN TRY
                DELETE d
                FROM dbo.StationInventoryTransactionDetails d
                WHERE d.HeaderId = @HeaderId;

                UPDATE dbo.StationInventoryTransactionHeaders
                SET DonViId = @DonViId,
                    TransactionType = @TransactionType,
                    TransactionDate = @TransactionDate,
                    Note = NULLIF(LTRIM(RTRIM(@HeaderNote)), N''),
                    Modified = @Now,
                    ModifiedBy = @Actor
                WHERE Id = @HeaderId;

                INSERT INTO dbo.StationInventoryTransactionDetails (HeaderId, ProductId, UnitId, Quantity, Amount, Note)
                SELECT @HeaderId, r.ProductId, r.UnitId, r.Quantity, r.Amount, r.Note
                FROM #Rows r;

                COMMIT TRANSACTION;
            END TRY
            BEGIN CATCH
                IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
                THROW;
            END CATCH;
        END;
        """;

    internal const string InventoryCurrentListPaged =
        """
        CREATE OR ALTER PROCEDURE dbo.sp_StoreAdmin_InventoryCurrent_ListPaged
            @Skip INT,
            @Take INT,
            @DonViId INT = NULL,
            @ProductId INT = NULL,
            @DonViScopeCsv NVARCHAR(MAX) = NULL,
            @RetailCapDonViId INT,
            @TotalCount INT OUTPUT
        AS
        BEGIN
            SET NOCOUNT ON;

            DECLARE @ScopeIds TABLE (Id INT PRIMARY KEY);

            IF @DonViScopeCsv IS NOT NULL AND LTRIM(RTRIM(@DonViScopeCsv)) <> N''
            BEGIN
                DECLARE @rest NVARCHAR(MAX) = LTRIM(RTRIM(@DonViScopeCsv));
                DECLARE @comma INT;
                DECLARE @piece NVARCHAR(50);

                WHILE LEN(@rest) > 0
                BEGIN
                    SET @comma = CHARINDEX(N',', @rest);
                    IF @comma = 0
                    BEGIN
                        SET @piece = @rest;
                        SET @rest = N'';
                    END
                    ELSE
                    BEGIN
                        SET @piece = LTRIM(RTRIM(LEFT(@rest, @comma - 1)));
                        SET @rest = LTRIM(RTRIM(SUBSTRING(@rest, @comma + 1, LEN(@rest))));
                    END;

                    IF LEN(@piece) > 0 AND TRY_CAST(@piece AS INT) IS NOT NULL
                    BEGIN
                        IF NOT EXISTS (SELECT 1 FROM @ScopeIds WHERE Id = TRY_CAST(@piece AS INT))
                            INSERT INTO @ScopeIds (Id) VALUES (TRY_CAST(@piece AS INT));
                    END;
                END;
            END;

            CREATE TABLE #Agg (
                DonViId INT NOT NULL,
                ProductId INT NOT NULL,
                CurrentQuantity DECIMAL(18, 4) NOT NULL,
                ProductCode NVARCHAR(4000) NOT NULL,
                ProductName NVARCHAR(4000) NOT NULL,
                UnitId INT NULL,
                UnitMa NVARCHAR(4000) NULL,
                UnitTen NVARCHAR(4000) NULL,
                LastTransactionDate DATETIME2(3) NOT NULL
            );

            ;WITH FilteredTx AS (
                SELECT
                    h.DonViId,
                    d.ProductId,
                    h.TransactionType,
                    h.TransactionDate,
                    DetailUnitId = d.UnitId,
                    ProductCatalogUnitId = fp.UnitId,
                    ResolvedUnitId = COALESCE(d.UnitId, fp.UnitId),
                    -- Demo: assume line quantity is already in one comparable base (no cross-unit conversion).
                    -- Future: multiply by dbo.fn_StoreAdmin_InventoryLineQtyToProductBase(d.ProductId, d.UnitId, fp.UnitId) when units differ.
                    QuantityForStock = CAST(d.Quantity AS DECIMAL(18, 4))
                FROM dbo.StationInventoryTransactionDetails AS d
                INNER JOIN dbo.StationInventoryTransactionHeaders AS h ON h.Id = d.HeaderId
                INNER JOIN dbo.FuelProducts AS fp ON fp.Id = d.ProductId
                INNER JOIN dbo.DM_DonVi AS dv ON dv.Id = h.DonViId AND dv.CapDonViId = @RetailCapDonViId
                WHERE (@DonViId IS NULL OR h.DonViId = @DonViId)
                  AND (@ProductId IS NULL OR d.ProductId = @ProductId)
                  AND (
                      @DonViScopeCsv IS NULL
                      OR LTRIM(RTRIM(@DonViScopeCsv)) = N''
                      OR h.DonViId IN (SELECT Id FROM @ScopeIds)
                  )
            ),
            Agg AS (
                SELECT
                    ft.DonViId,
                    ft.ProductId,
                    CurrentQuantity = SUM(CAST(ft.QuantityForStock AS DECIMAL(18, 4)) * CAST(ft.TransactionType AS DECIMAL(18, 4))),
                    ProductCode = MAX(ISNULL(fp.Code, N'')),
                    ProductName = MAX(ISNULL(fp.Name, N'')),
                    UnitId = MAX(ft.ResolvedUnitId),
                    UnitMa = MAX(u.Ma),
                    UnitTen = MAX(u.Ten),
                    LastTransactionDate = MAX(ft.TransactionDate)
                FROM FilteredTx AS ft
                INNER JOIN dbo.FuelProducts AS fp ON fp.Id = ft.ProductId
                LEFT JOIN dbo.DM_DonViTinh AS u ON u.Id = ft.ResolvedUnitId
                GROUP BY ft.DonViId, ft.ProductId
            )
            INSERT INTO #Agg (
                DonViId,
                ProductId,
                CurrentQuantity,
                ProductCode,
                ProductName,
                UnitId,
                UnitMa,
                UnitTen,
                LastTransactionDate)
            SELECT
                DonViId,
                ProductId,
                CurrentQuantity,
                ProductCode,
                ProductName,
                UnitId,
                UnitMa,
                UnitTen,
                LastTransactionDate
            FROM Agg;

            SELECT @TotalCount = COUNT(1) FROM #Agg;

            SELECT
                DonViId,
                ProductId,
                CurrentQuantity,
                ProductCode,
                ProductName,
                UnitId,
                UnitMa,
                UnitTen,
                LastTransactionDate
            FROM #Agg
            ORDER BY DonViId, ProductId
            OFFSET @Skip ROWS FETCH NEXT @Take ROWS ONLY;
        END;
        """;

    internal const string InventoryCurrentListByStore =
        """
        CREATE OR ALTER PROCEDURE dbo.sp_StoreAdmin_InventoryCurrent_ListByStore
            @DonViId INT,
            @RetailCapDonViId INT
        AS
        BEGIN
            SET NOCOUNT ON;

            ;WITH FilteredTx AS (
                SELECT
                    h.DonViId,
                    d.ProductId,
                    h.TransactionType,
                    h.TransactionDate,
                    DetailUnitId = d.UnitId,
                    ProductCatalogUnitId = fp.UnitId,
                    ResolvedUnitId = COALESCE(d.UnitId, fp.UnitId),
                    QuantityForStock = CAST(d.Quantity AS DECIMAL(18, 4))
                FROM dbo.StationInventoryTransactionDetails AS d
                INNER JOIN dbo.StationInventoryTransactionHeaders AS h ON h.Id = d.HeaderId
                INNER JOIN dbo.FuelProducts AS fp ON fp.Id = d.ProductId
                INNER JOIN dbo.DM_DonVi AS dv ON dv.Id = h.DonViId AND dv.CapDonViId = @RetailCapDonViId
                WHERE h.DonViId = @DonViId
            ),
            Agg AS (
                SELECT
                    ft.DonViId,
                    ft.ProductId,
                    CurrentQuantity = SUM(CAST(ft.QuantityForStock AS DECIMAL(18, 4)) * CAST(ft.TransactionType AS DECIMAL(18, 4))),
                    ProductCode = MAX(ISNULL(fp.Code, N'')),
                    ProductName = MAX(ISNULL(fp.Name, N'')),
                    UnitId = MAX(ft.ResolvedUnitId),
                    UnitMa = MAX(u.Ma),
                    UnitTen = MAX(u.Ten),
                    LastTransactionDate = MAX(ft.TransactionDate)
                FROM FilteredTx AS ft
                INNER JOIN dbo.FuelProducts AS fp ON fp.Id = ft.ProductId
                LEFT JOIN dbo.DM_DonViTinh AS u ON u.Id = ft.ResolvedUnitId
                GROUP BY ft.DonViId, ft.ProductId
            )
            SELECT
                DonViId,
                ProductId,
                CurrentQuantity,
                ProductCode,
                ProductName,
                UnitId,
                UnitMa,
                UnitTen,
                LastTransactionDate
            FROM Agg
            ORDER BY ProductId;
        END;
        """;
}
