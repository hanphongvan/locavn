using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Httm.XangDau.Api.Shared.Persistence.Migrations;

/// <inheritdoc />
/// <summary>
/// Adds <c>StationPrices</c> header table, <c>StationProductPrices.StationPricesId</c> FK (cascade delete),
/// backfills existing rows, and refreshes store-admin price stored procedures.
/// </summary>
public partial class AddStationPricesAndProductPriceHeaderLink : Migration
{
    /// <inheritdoc />
    protected override void Up(MigrationBuilder migrationBuilder)
    {
        migrationBuilder.CreateTable(
            name: "StationPrices",
            columns: table => new
            {
                Id = table.Column<int>(type: "int", nullable: false).Annotation("SqlServer:Identity", "1, 1"),
                DonViId = table.Column<int>(type: "int", nullable: false),
                ActiveDate = table.Column<DateTime>(type: "datetime", nullable: false),
                IsActive = table.Column<bool>(type: "bit", nullable: false),
                Created = table.Column<DateTime>(type: "datetime", nullable: false),
                CreatedBy = table.Column<string>(type: "nvarchar(50)", maxLength: 50, nullable: true),
                Modified = table.Column<DateTime>(type: "datetime", nullable: false),
                ModifiedBy = table.Column<string>(type: "nvarchar(50)", maxLength: 50, nullable: true),
            },
            constraints: table => table.PrimaryKey("PK_StationPrices", x => x.Id));

        migrationBuilder.AddColumn<int>(
            name: "StationPricesId",
            table: "StationProductPrices",
            type: "int",
            nullable: true);

        migrationBuilder.Sql(@"
IF EXISTS (SELECT 1 FROM dbo.StationProductPrices)
BEGIN
    INSERT INTO dbo.StationPrices (DonViId, ActiveDate, IsActive, Created, CreatedBy, Modified, ModifiedBy)
    SELECT
        p.DonViId,
        p.EffectiveDate,
        CAST(CASE WHEN SUM(CASE WHEN p.IsCurrent = 1 THEN 1 ELSE 0 END) > 0 THEN 1 ELSE 0 END AS BIT),
        MIN(p.Created),
        NULL,
        MAX(p.Modified),
        NULL
    FROM dbo.StationProductPrices AS p
    GROUP BY p.DonViId, p.EffectiveDate;

    ;WITH ranked AS (
        SELECT s.Id,
               ROW_NUMBER() OVER (PARTITION BY s.DonViId ORDER BY s.ActiveDate DESC, s.Id DESC) AS rn
        FROM dbo.StationPrices AS s
    )
    UPDATE s
    SET s.IsActive = CAST(1 AS BIT)
    FROM dbo.StationPrices AS s
    INNER JOIN ranked AS r ON r.Id = s.Id AND r.rn = 1;

    UPDATE p
    SET p.StationPricesId = s.Id
    FROM dbo.StationProductPrices AS p
    INNER JOIN dbo.StationPrices AS s ON s.DonViId = p.DonViId AND s.ActiveDate = p.EffectiveDate;
END;
");

        migrationBuilder.AlterColumn<int>(
            name: "StationPricesId",
            table: "StationProductPrices",
            type: "int",
            nullable: false,
            oldClrType: typeof(int),
            oldType: "int",
            oldNullable: true);

        migrationBuilder.CreateIndex(
            name: "IX_StationProductPrices_StationPricesId",
            table: "StationProductPrices",
            column: "StationPricesId");

        migrationBuilder.AddForeignKey(
            name: "FK_StationProductPrices_StationPrices_StationPricesId",
            table: "StationProductPrices",
            column: "StationPricesId",
            principalTable: "StationPrices",
            principalColumn: "Id",
            onDelete: ReferentialAction.Cascade);

        ApplyStoreAdminStationProductPriceProcedures(migrationBuilder);
    }

    /// <inheritdoc />
    protected override void Down(MigrationBuilder migrationBuilder)
    {
        migrationBuilder.DropForeignKey(
            name: "FK_StationProductPrices_StationPrices_StationPricesId",
            table: "StationProductPrices");

        migrationBuilder.DropIndex(
            name: "IX_StationProductPrices_StationPricesId",
            table: "StationProductPrices");

        migrationBuilder.DropColumn(name: "StationPricesId", table: "StationProductPrices");

        migrationBuilder.DropTable(name: "StationPrices");
    }

    /// <summary>Each procedure must run in its own batch (SQL Server).</summary>
    private static void ApplyStoreAdminStationProductPriceProcedures(MigrationBuilder migrationBuilder)
    {
        migrationBuilder.Sql(@"
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
        p.Note,
        p.StationPricesId
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
        Note,
        StationPricesId
    FROM #Filtered
    ORDER BY EffectiveDate DESC, DonViId, ProductId
    OFFSET @Skip ROWS FETCH NEXT @Take ROWS ONLY;
END;
");

        migrationBuilder.Sql(@"
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
        p.Note,
        p.StationPricesId
    FROM dbo.StationProductPrices AS p
    INNER JOIN dbo.DM_DonVi AS d ON d.Id = p.DonViId AND d.CapDonViId = @RetailCapDonViId
    WHERE p.DonViId = @DonViId
    ORDER BY p.EffectiveDate DESC, p.ProductId;
END;
");

        migrationBuilder.Sql(@"
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
        p.Note,
        p.StationPricesId
    FROM dbo.StationProductPrices AS p
    INNER JOIN dbo.DM_DonVi AS d ON d.Id = p.DonViId AND d.CapDonViId = @RetailCapDonViId
    INNER JOIN dbo.StationPrices AS s ON s.Id = p.StationPricesId
    WHERE p.DonViId = @DonViId AND s.IsActive = 1
    ORDER BY p.ProductId;
END;
");

        migrationBuilder.Sql(@"
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
        p.StationPricesId,
        p.Created,
        p.CreatedBy,
        p.Modified,
        p.ModifiedBy
    FROM dbo.StationProductPrices AS p
    INNER JOIN dbo.DM_DonVi AS d ON d.Id = p.DonViId AND d.CapDonViId = @RetailCapDonViId
    WHERE p.Id = @Id;
END;
");

        migrationBuilder.Sql(@"
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
");

        migrationBuilder.Sql(@"
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
");

        migrationBuilder.Sql(@"
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
");

        migrationBuilder.Sql(@"
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
");
    }
}
