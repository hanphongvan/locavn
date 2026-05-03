using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Httm.XangDau.Api.Shared.Persistence.Migrations;

/// <inheritdoc />
public partial class AddStoreAdminStationProductPriceStoredProcedures : Migration
{
    /// <inheritdoc />
    protected override void Up(MigrationBuilder migrationBuilder)
    {
        migrationBuilder.Sql(
            """
            CREATE OR ALTER PROCEDURE dbo.sp_StoreAdmin_DonVi_IsRetailStore
                @DonViId INT,
                @RetailCapDonViId INT
            AS
            BEGIN
                SET NOCOUNT ON;
                IF EXISTS (SELECT 1 FROM dbo.DM_DonVi WHERE Id = @DonViId AND CapDonViId = @RetailCapDonViId)
                    SELECT CAST(1 AS BIT) AS Ok;
                ELSE
                    SELECT CAST(0 AS BIT) AS Ok;
            END;
            """);

        migrationBuilder.Sql(
            """
            CREATE OR ALTER PROCEDURE dbo.sp_StoreAdmin_FuelProduct_Exists
                @ProductId INT
            AS
            BEGIN
                SET NOCOUNT ON;
                IF EXISTS (SELECT 1 FROM dbo.FuelProducts WHERE Id = @ProductId)
                    SELECT CAST(1 AS BIT) AS Ok;
                ELSE
                    SELECT CAST(0 AS BIT) AS Ok;
            END;
            """);

        migrationBuilder.Sql(
            """
            CREATE OR ALTER PROCEDURE dbo.sp_StoreAdmin_FuelProducts_ListActiveForLookup
                @Search NVARCHAR(200) = NULL,
                @Take INT = 200,
                @DefaultsOnly BIT = 0
            AS
            BEGIN
                SET NOCOUNT ON;
                IF @Take < 1 SET @Take = 1;
                IF @Take > 500 SET @Take = 500;

                SELECT TOP (@Take)
                    fp.Id,
                    fp.Code,
                    fp.Name,
                    fp.UnitId,
                    fp.SortOrder
                FROM dbo.FuelProducts AS fp
                WHERE fp.IsActive = 1
                  AND (@DefaultsOnly = 0 OR fp.SortOrder IS NOT NULL)
                  AND (
                      @Search IS NULL
                      OR LTRIM(RTRIM(@Search)) = N''
                      OR fp.Code LIKE N'%' + @Search + N'%'
                      OR fp.Name LIKE N'%' + @Search + N'%'
                  )
                ORDER BY fp.SortOrder, fp.Name;
            END;
            """);

        migrationBuilder.Sql(
            """
            CREATE OR ALTER PROCEDURE dbo.sp_StoreAdmin_StationProductPrices_ListPaged
                @Skip INT,
                @Take INT,
                @DonViId INT = NULL,
                @ProductId INT = NULL,
                @IsCurrent BIT = NULL,
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

                SELECT
                    p.Id,
                    p.DonViId,
                    p.ProductId,
                    p.Price,
                    p.UnitId,
                    p.EffectiveDate,
                    p.IsCurrent,
                    p.Note
                INTO #Filtered
                FROM dbo.StationProductPrices AS p
                INNER JOIN dbo.DM_DonVi AS d ON d.Id = p.DonViId AND d.CapDonViId = @RetailCapDonViId
                WHERE (@DonViId IS NULL OR p.DonViId = @DonViId)
                  AND (@ProductId IS NULL OR p.ProductId = @ProductId)
                  AND (@IsCurrent IS NULL OR p.IsCurrent = @IsCurrent)
                  AND (
                      @DonViScopeCsv IS NULL
                      OR LTRIM(RTRIM(@DonViScopeCsv)) = N''
                      OR p.DonViId IN (SELECT Id FROM @ScopeIds)
                  );

                SELECT @TotalCount = COUNT(1) FROM #Filtered;

                SELECT
                    Id,
                    DonViId,
                    ProductId,
                    Price,
                    UnitId,
                    EffectiveDate,
                    IsCurrent,
                    Note
                FROM #Filtered
                ORDER BY EffectiveDate DESC, DonViId, ProductId
                OFFSET @Skip ROWS FETCH NEXT @Take ROWS ONLY;
            END;
            """);

        migrationBuilder.Sql(
            """
            CREATE OR ALTER PROCEDURE dbo.sp_StoreAdmin_StationProductPrices_ListByStore
                @DonViId INT,
                @RetailCapDonViId INT
            AS
            BEGIN
                SET NOCOUNT ON;

                SELECT
                    p.Id,
                    p.DonViId,
                    p.ProductId,
                    p.Price,
                    p.UnitId,
                    p.EffectiveDate,
                    p.IsCurrent,
                    p.Note
                FROM dbo.StationProductPrices AS p
                INNER JOIN dbo.DM_DonVi AS d ON d.Id = p.DonViId AND d.CapDonViId = @RetailCapDonViId
                WHERE p.DonViId = @DonViId
                ORDER BY p.EffectiveDate DESC, p.ProductId;
            END;
            """);

        migrationBuilder.Sql(
            """
            CREATE OR ALTER PROCEDURE dbo.sp_StoreAdmin_StationProductPrices_ListCurrentByStore
                @DonViId INT,
                @RetailCapDonViId INT
            AS
            BEGIN
                SET NOCOUNT ON;

                SELECT
                    p.Id,
                    p.DonViId,
                    p.ProductId,
                    p.Price,
                    p.UnitId,
                    p.EffectiveDate,
                    p.IsCurrent,
                    p.Note
                FROM dbo.StationProductPrices AS p
                INNER JOIN dbo.DM_DonVi AS d ON d.Id = p.DonViId AND d.CapDonViId = @RetailCapDonViId
                WHERE p.DonViId = @DonViId AND p.IsCurrent = 1
                ORDER BY p.ProductId;
            END;
            """);

        migrationBuilder.Sql(
            """
            CREATE OR ALTER PROCEDURE dbo.sp_StoreAdmin_StationProductPrices_GetById
                @Id INT,
                @RetailCapDonViId INT
            AS
            BEGIN
                SET NOCOUNT ON;

                SELECT TOP (1)
                    p.Id,
                    p.DonViId,
                    p.ProductId,
                    p.Price,
                    p.UnitId,
                    p.EffectiveDate,
                    p.IsCurrent,
                    p.Note,
                    p.Created,
                    p.CreatedBy,
                    p.Modified,
                    p.ModifiedBy
                FROM dbo.StationProductPrices AS p
                INNER JOIN dbo.DM_DonVi AS d ON d.Id = p.DonViId AND d.CapDonViId = @RetailCapDonViId
                WHERE p.Id = @Id;
            END;
            """);

        migrationBuilder.Sql(
            """
            CREATE OR ALTER PROCEDURE dbo.sp_StoreAdmin_StationProductPrices_ListLatestSubmission
                @DonViId INT,
                @RetailCapDonViId INT
            AS
            BEGIN
                SET NOCOUNT ON;

                IF NOT EXISTS (SELECT 1 FROM dbo.DM_DonVi WHERE Id = @DonViId AND CapDonViId = @RetailCapDonViId)
                    RETURN;

                DECLARE @MaxEd DATETIME;
                SELECT @MaxEd = MAX(p.EffectiveDate)
                FROM dbo.StationProductPrices AS p
                WHERE p.DonViId = @DonViId;

                IF @MaxEd IS NULL
                    RETURN;

                SELECT
                    p.ProductId,
                    p.Price,
                    p.UnitId,
                    p.Note,
                    p.EffectiveDate,
                    p.IsCurrent
                FROM dbo.StationProductPrices AS p
                INNER JOIN dbo.DM_DonVi AS d ON d.Id = p.DonViId AND d.CapDonViId = @RetailCapDonViId
                WHERE p.DonViId = @DonViId AND p.EffectiveDate = @MaxEd
                ORDER BY p.ProductId;
            END;
            """);

        migrationBuilder.Sql(
            """
            CREATE OR ALTER PROCEDURE dbo.sp_StoreAdmin_StationProductPrices_Insert
                @DonViId INT,
                @ProductId INT,
                @Price DECIMAL(18, 2),
                @UnitId INT = NULL,
                @EffectiveDate DATETIME,
                @IsCurrent BIT,
                @Note NVARCHAR(500) = NULL,
                @Actor NVARCHAR(100),
                @RetailCapDonViId INT,
                @NewId INT OUTPUT
            AS
            BEGIN
                SET NOCOUNT ON;
                SET @NewId = NULL;

                IF NOT EXISTS (SELECT 1 FROM dbo.DM_DonVi WHERE Id = @DonViId AND CapDonViId = @RetailCapDonViId)
                BEGIN
                    RAISERROR(N'DonViId is not a valid retail store for this cap.', 16, 1);
                    RETURN;
                END;

                IF NOT EXISTS (SELECT 1 FROM dbo.FuelProducts WHERE Id = @ProductId)
                BEGIN
                    RAISERROR(N'ProductId does not exist.', 16, 1);
                    RETURN;
                END;

                IF @Price < 0
                BEGIN
                    RAISERROR(N'Price must be >= 0.', 16, 1);
                    RETURN;
                END;

                DECLARE @Now DATETIME2(3) = SYSUTCDATETIME();

                BEGIN TRANSACTION;
                BEGIN TRY
                    IF @IsCurrent = 1
                    BEGIN
                        UPDATE dbo.StationProductPrices
                        SET IsCurrent = 0, Modified = @Now, ModifiedBy = @Actor
                        WHERE DonViId = @DonViId AND ProductId = @ProductId AND IsCurrent = 1;
                    END;

                    INSERT INTO dbo.StationProductPrices (
                        DonViId,
                        ProductId,
                        Price,
                        UnitId,
                        EffectiveDate,
                        IsCurrent,
                        Note,
                        Created,
                        CreatedBy,
                        Modified,
                        ModifiedBy)
                    VALUES (
                        @DonViId,
                        @ProductId,
                        @Price,
                        @UnitId,
                        @EffectiveDate,
                        @IsCurrent,
                        @Note,
                        @Now,
                        @Actor,
                        @Now,
                        @Actor);

                    SET @NewId = CAST(SCOPE_IDENTITY() AS INT);
                    COMMIT TRANSACTION;
                END TRY
                BEGIN CATCH
                    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
                    THROW;
                END CATCH;
            END;
            """);

        migrationBuilder.Sql(
            """
            CREATE OR ALTER PROCEDURE dbo.sp_StoreAdmin_StationProductPrices_Update
                @Id INT,
                @DonViId INT,
                @ProductId INT,
                @Price DECIMAL(18, 2),
                @UnitId INT = NULL,
                @EffectiveDate DATETIME,
                @IsCurrent BIT,
                @Note NVARCHAR(500) = NULL,
                @Actor NVARCHAR(100),
                @RetailCapDonViId INT
            AS
            BEGIN
                SET NOCOUNT ON;

                IF NOT EXISTS (
                    SELECT 1
                    FROM dbo.StationProductPrices AS p
                    INNER JOIN dbo.DM_DonVi AS d ON d.Id = p.DonViId AND d.CapDonViId = @RetailCapDonViId
                    WHERE p.Id = @Id)
                BEGIN
                    RAISERROR(N'Price row not found or not in retail store scope.', 16, 1);
                    RETURN;
                END;

                IF NOT EXISTS (SELECT 1 FROM dbo.DM_DonVi WHERE Id = @DonViId AND CapDonViId = @RetailCapDonViId)
                BEGIN
                    RAISERROR(N'DonViId is not a valid retail store for this cap.', 16, 1);
                    RETURN;
                END;

                IF NOT EXISTS (SELECT 1 FROM dbo.FuelProducts WHERE Id = @ProductId)
                BEGIN
                    RAISERROR(N'ProductId does not exist.', 16, 1);
                    RETURN;
                END;

                IF @Price < 0
                BEGIN
                    RAISERROR(N'Price must be >= 0.', 16, 1);
                    RETURN;
                END;

                DECLARE @Now DATETIME2(3) = SYSUTCDATETIME();

                BEGIN TRANSACTION;
                BEGIN TRY
                    IF @IsCurrent = 1
                    BEGIN
                        UPDATE dbo.StationProductPrices
                        SET IsCurrent = 0, Modified = @Now, ModifiedBy = @Actor
                        WHERE DonViId = @DonViId AND ProductId = @ProductId AND IsCurrent = 1 AND Id <> @Id;
                    END;

                    UPDATE dbo.StationProductPrices
                    SET
                        DonViId = @DonViId,
                        ProductId = @ProductId,
                        Price = @Price,
                        UnitId = @UnitId,
                        EffectiveDate = @EffectiveDate,
                        IsCurrent = @IsCurrent,
                        Note = @Note,
                        Modified = @Now,
                        ModifiedBy = @Actor
                    WHERE Id = @Id;

                    COMMIT TRANSACTION;
                END TRY
                BEGIN CATCH
                    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
                    THROW;
                END CATCH;
            END;
            """);

        migrationBuilder.Sql(
            """
            CREATE OR ALTER PROCEDURE dbo.sp_StoreAdmin_StationProductPrices_BatchInsert
                @DonViId INT,
                @EffectiveDate DATETIME,
                @IsCurrent BIT,
                @Actor NVARCHAR(100),
                @RetailCapDonViId INT,
                @RowsXml NVARCHAR(MAX)
            AS
            BEGIN
                SET NOCOUNT ON;

                IF @RowsXml IS NULL OR LTRIM(RTRIM(@RowsXml)) = N''
                BEGIN
                    RAISERROR(N'Rows payload is required.', 16, 1);
                    RETURN;
                END;

                IF NOT EXISTS (SELECT 1 FROM dbo.DM_DonVi WHERE Id = @DonViId AND CapDonViId = @RetailCapDonViId)
                BEGIN
                    RAISERROR(N'DonViId is not a valid retail store for this cap.', 16, 1);
                    RETURN;
                END;

                CREATE TABLE #Rows (
                    ProductId INT NOT NULL,
                    Price DECIMAL(18, 2) NOT NULL,
                    UnitId INT NULL,
                    Note NVARCHAR(500) NULL
                );

                DECLARE @x XML;
                BEGIN TRY
                    SET @x = CAST(LTRIM(RTRIM(@RowsXml)) AS XML);
                END TRY
                BEGIN CATCH
                    RAISERROR(N'Rows payload is not valid XML.', 16, 1);
                    RETURN;
                END CATCH;

                INSERT INTO #Rows (ProductId, Price, UnitId, Note)
                SELECT
                    T.c.value('@productId', 'INT'),
                    T.c.value('@price', 'DECIMAL(18,2)'),
                    T.c.value('@unitId', 'INT'),
                    NULLIF(LTRIM(RTRIM(T.c.value('@note', 'NVARCHAR(500)'))), N'')
                FROM @x.nodes('/rows/r') AS T(c);

                IF NOT EXISTS (SELECT 1 FROM #Rows)
                BEGIN
                    RAISERROR(N'No valid rows in payload.', 16, 1);
                    RETURN;
                END;

                IF EXISTS (SELECT 1 FROM #Rows WHERE ProductId IS NULL OR Price IS NULL)
                BEGIN
                    RAISERROR(N'Each row must have productId and price.', 16, 1);
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

                IF EXISTS (SELECT 1 FROM #Rows WHERE Price < 0)
                BEGIN
                    RAISERROR(N'Each price must be >= 0.', 16, 1);
                    RETURN;
                END;

                DECLARE @Now DATETIME2(3) = SYSUTCDATETIME();

                CREATE TABLE #CreatedIds (Id INT NOT NULL);

                BEGIN TRANSACTION;
                BEGIN TRY
                    IF @IsCurrent = 1
                    BEGIN
                        UPDATE p
                        SET IsCurrent = 0, Modified = @Now, ModifiedBy = @Actor
                        FROM dbo.StationProductPrices AS p
                        INNER JOIN #Rows AS r ON r.ProductId = p.ProductId
                        WHERE p.DonViId = @DonViId AND p.IsCurrent = 1;
                    END;

                    INSERT INTO dbo.StationProductPrices (
                        DonViId,
                        ProductId,
                        Price,
                        UnitId,
                        EffectiveDate,
                        IsCurrent,
                        Note,
                        Created,
                        CreatedBy,
                        Modified,
                        ModifiedBy)
                    OUTPUT INSERTED.Id INTO #CreatedIds (Id)
                    SELECT
                        @DonViId,
                        r.ProductId,
                        r.Price,
                        r.UnitId,
                        @EffectiveDate,
                        @IsCurrent,
                        r.Note,
                        @Now,
                        @Actor,
                        @Now,
                        @Actor
                    FROM #Rows AS r
                    ORDER BY r.ProductId;

                    SELECT Id FROM #CreatedIds ORDER BY Id;
                    COMMIT TRANSACTION;
                END TRY
                BEGIN CATCH
                    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
                    THROW;
                END CATCH;
            END;
            """);
    }

    /// <inheritdoc />
    protected override void Down(MigrationBuilder migrationBuilder)
    {
        migrationBuilder.Sql("DROP PROCEDURE IF EXISTS dbo.sp_StoreAdmin_StationProductPrices_BatchInsert;");
        migrationBuilder.Sql("DROP PROCEDURE IF EXISTS dbo.sp_StoreAdmin_StationProductPrices_Update;");
        migrationBuilder.Sql("DROP PROCEDURE IF EXISTS dbo.sp_StoreAdmin_StationProductPrices_Insert;");
        migrationBuilder.Sql("DROP PROCEDURE IF EXISTS dbo.sp_StoreAdmin_StationProductPrices_ListLatestSubmission;");
        migrationBuilder.Sql("DROP PROCEDURE IF EXISTS dbo.sp_StoreAdmin_StationProductPrices_GetById;");
        migrationBuilder.Sql("DROP PROCEDURE IF EXISTS dbo.sp_StoreAdmin_StationProductPrices_ListCurrentByStore;");
        migrationBuilder.Sql("DROP PROCEDURE IF EXISTS dbo.sp_StoreAdmin_StationProductPrices_ListByStore;");
        migrationBuilder.Sql("DROP PROCEDURE IF EXISTS dbo.sp_StoreAdmin_StationProductPrices_ListPaged;");
        migrationBuilder.Sql("DROP PROCEDURE IF EXISTS dbo.sp_StoreAdmin_FuelProducts_ListActiveForLookup;");
        migrationBuilder.Sql("DROP PROCEDURE IF EXISTS dbo.sp_StoreAdmin_FuelProduct_Exists;");
        migrationBuilder.Sql("DROP PROCEDURE IF EXISTS dbo.sp_StoreAdmin_DonVi_IsRetailStore;");
    }
}
