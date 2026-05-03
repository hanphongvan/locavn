using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Httm.XangDau.Api.Shared.Persistence.Migrations
{
    /// <inheritdoc />
    public partial class FixStorePricesVnWallClock : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            // Audit Created/Modified: lưu giờ tường Việt Nam (datetime naive) thay vì mặt đồng hồ UTC của SYSUTCDATETIME().
            const string VnNow =
                "\nDECLARE @Now DATETIME2(3) = CONVERT(DATETIME2(3), SYSUTCDATETIME() AT TIME ZONE 'UTC' AT TIME ZONE 'SE Asia Standard Time');\n";

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

                """
                + VnNow
                + """
                    DECLARE @Actor50 NVARCHAR(50) = LEFT(ISNULL(@Actor, N''), 50);
                    DECLARE @HeaderId TABLE (Id INT NOT NULL);

                    BEGIN TRANSACTION;
                    BEGIN TRY
                        IF @IsCurrent = 1
                        BEGIN
                            UPDATE dbo.StationProductPrices
                            SET IsCurrent = 0, Modified = @Now, ModifiedBy = @Actor
                            WHERE DonViId = @DonViId AND ProductId = @ProductId AND IsCurrent = 1;

                            UPDATE dbo.StationPrices
                            SET IsActive = 0, Modified = @Now, ModifiedBy = @Actor50
                            WHERE DonViId = @DonViId AND IsActive = 1;
                        END;

                        INSERT INTO dbo.StationPrices (DonViId, ActiveDate, IsActive, Created, CreatedBy, Modified, ModifiedBy)
                        OUTPUT INSERTED.Id INTO @HeaderId
                        VALUES (@DonViId, @EffectiveDate, @IsCurrent, @Now, @Actor50, @Now, @Actor50);

                        DECLARE @StationPricesId INT = (SELECT TOP 1 Id FROM @HeaderId);

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
                            ModifiedBy,
                            StationPricesId)
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
                            @Actor,
                            @StationPricesId);

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

                """
                + VnNow
                + """
                    DECLARE @Actor50 NVARCHAR(50) = LEFT(ISNULL(@Actor, N''), 50);
                    DECLARE @StationPricesId INT =
                        (SELECT p.StationPricesId FROM dbo.StationProductPrices AS p WHERE p.Id = @Id);

                    BEGIN TRANSACTION;
                    BEGIN TRY
                        IF @IsCurrent = 1
                        BEGIN
                            UPDATE dbo.StationProductPrices
                            SET IsCurrent = 0, Modified = @Now, ModifiedBy = @Actor
                            WHERE DonViId = @DonViId AND ProductId = @ProductId AND IsCurrent = 1 AND Id <> @Id;

                            UPDATE dbo.StationPrices
                            SET IsActive = 0, Modified = @Now, ModifiedBy = @Actor50
                            WHERE DonViId = @DonViId AND IsActive = 1 AND Id <> @StationPricesId;
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

                        UPDATE dbo.StationPrices
                        SET
                            ActiveDate = @EffectiveDate,
                            IsActive = @IsCurrent,
                            Modified = @Now,
                            ModifiedBy = @Actor50
                        WHERE Id = @StationPricesId;

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

                """
                + VnNow
                + """
                    DECLARE @Actor50 NVARCHAR(50) = LEFT(ISNULL(@Actor, N''), 50);
                    CREATE TABLE #CreatedIds (Id INT NOT NULL);
                    DECLARE @HeaderIds TABLE (Id INT NOT NULL);

                    BEGIN TRANSACTION;
                    BEGIN TRY
                        IF @IsCurrent = 1
                        BEGIN
                            UPDATE dbo.StationProductPrices
                            SET IsCurrent = 0, Modified = @Now, ModifiedBy = @Actor
                            FROM dbo.StationProductPrices AS p
                            INNER JOIN #Rows AS r ON r.ProductId = p.ProductId
                            WHERE p.DonViId = @DonViId AND p.IsCurrent = 1;

                            UPDATE dbo.StationPrices
                            SET IsActive = 0, Modified = @Now, ModifiedBy = @Actor50
                            WHERE DonViId = @DonViId AND IsActive = 1;
                        END;

                        INSERT INTO dbo.StationPrices (DonViId, ActiveDate, IsActive, Created, CreatedBy, Modified, ModifiedBy)
                        OUTPUT INSERTED.Id INTO @HeaderIds
                        VALUES (@DonViId, @EffectiveDate, @IsCurrent, @Now, @Actor50, @Now, @Actor50);

                        DECLARE @StationPricesId INT = (SELECT TOP 1 Id FROM @HeaderIds);

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
                            ModifiedBy,
                            StationPricesId)
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
                            @Actor,
                            @StationPricesId
                        FROM #Rows AS r
                        ORDER BY r.ProductId;

                        SELECT @StationPricesId AS StationPricesId;
                        SELECT Id FROM #CreatedIds ORDER BY Id;
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
                CREATE OR ALTER PROCEDURE dbo.sp_StoreAdmin_StationPrices_Update
                    @Id INT,
                    @ActiveDate DATETIME,
                    @IsActive BIT,
                    @Actor NVARCHAR(100),
                    @RetailCapDonViId INT
                AS
                BEGIN
                    SET NOCOUNT ON;

                    IF NOT EXISTS (
                        SELECT 1
                        FROM dbo.StationPrices AS s
                        INNER JOIN dbo.DM_DonVi AS d ON d.Id = s.DonViId AND d.CapDonViId = @RetailCapDonViId
                        WHERE s.Id = @Id)
                    BEGIN
                        RAISERROR(N'StationPrices row not found or not in retail store scope.', 16, 1);
                        RETURN;
                    END;

                """
                + VnNow
                + """
                    DECLARE @Actor50 NVARCHAR(50) = LEFT(ISNULL(@Actor, N''), 50);

                    UPDATE dbo.StationPrices
                    SET
                        ActiveDate = @ActiveDate,
                        IsActive = @IsActive,
                        Modified = @Now,
                        ModifiedBy = @Actor50
                    WHERE Id = @Id;
                END;
                """);

            migrationBuilder.Sql(
                """
                CREATE OR ALTER PROCEDURE dbo.sp_StoreAdmin_StationPrices_UpdateBoardEditor
                    @StationPricesId INT,
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

                    IF NOT EXISTS (
                        SELECT 1
                        FROM dbo.StationPrices AS s
                        INNER JOIN dbo.DM_DonVi AS d ON d.Id = s.DonViId AND d.CapDonViId = @RetailCapDonViId
                        WHERE s.Id = @StationPricesId)
                    BEGIN
                        RAISERROR(N'StationPrices row not found or not in retail store scope.', 16, 1);
                        RETURN;
                    END;

                    DECLARE @DonViId INT =
                        (SELECT s.DonViId FROM dbo.StationPrices AS s WHERE s.Id = @StationPricesId);

                    CREATE TABLE #Rows (
                        LineId INT NOT NULL,
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

                    INSERT INTO #Rows (LineId, ProductId, Price, UnitId, Note)
                    SELECT
                        T.c.value('@id', 'INT'),
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

                    DECLARE @Expected INT =
                        (SELECT COUNT(1) FROM dbo.StationProductPrices WHERE StationPricesId = @StationPricesId);

                    IF (SELECT COUNT(1) FROM #Rows) <> @Expected
                    BEGIN
                        RAISERROR(N'Row count must match existing lines for this price board.', 16, 1);
                        RETURN;
                    END;

                    IF EXISTS (
                        SELECT 1
                        FROM #Rows AS r
                        LEFT JOIN dbo.StationProductPrices AS p ON p.Id = r.LineId AND p.StationPricesId = @StationPricesId
                        WHERE p.Id IS NULL)
                    BEGIN
                        RAISERROR(N'One or more line ids are invalid for this board.', 16, 1);
                        RETURN;
                    END;

                    IF EXISTS (SELECT 1 FROM #Rows WHERE ProductId IS NULL OR Price IS NULL OR LineId IS NULL)
                    BEGIN
                        RAISERROR(N'Each row must have id, productId and price.', 16, 1);
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

                """
                + VnNow
                + """
                    DECLARE @Actor50 NVARCHAR(50) = LEFT(ISNULL(@Actor, N''), 50);

                    BEGIN TRANSACTION;
                    BEGIN TRY
                        IF @IsCurrent = 1
                        BEGIN
                            UPDATE dbo.StationProductPrices
                            SET IsCurrent = 0, Modified = @Now, ModifiedBy = @Actor
                            WHERE DonViId = @DonViId AND IsCurrent = 1 AND StationPricesId <> @StationPricesId;

                            UPDATE dbo.StationPrices
                            SET IsActive = 0, Modified = @Now, ModifiedBy = @Actor50
                            WHERE DonViId = @DonViId AND IsActive = 1 AND Id <> @StationPricesId;
                        END;

                        UPDATE dbo.StationPrices
                        SET
                            ActiveDate = @EffectiveDate,
                            IsActive = @IsCurrent,
                            Modified = @Now,
                            ModifiedBy = @Actor50
                        WHERE Id = @StationPricesId;

                        UPDATE p
                        SET
                            ProductId = r.ProductId,
                            Price = r.Price,
                            UnitId = r.UnitId,
                            Note = r.Note,
                            EffectiveDate = @EffectiveDate,
                            IsCurrent = @IsCurrent,
                            Modified = @Now,
                            ModifiedBy = @Actor
                        FROM dbo.StationProductPrices AS p
                        INNER JOIN #Rows AS r ON r.LineId = p.Id
                        WHERE p.StationPricesId = @StationPricesId;

                        IF @@ROWCOUNT <> @Expected
                        BEGIN
                            RAISERROR(N'Line update count mismatch.', 16, 1);
                        END;

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

        }
    }
}
