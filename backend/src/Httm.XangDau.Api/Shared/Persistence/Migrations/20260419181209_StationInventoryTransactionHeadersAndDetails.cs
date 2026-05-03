using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Httm.XangDau.Api.Shared.Persistence.Migrations
{
    /// <inheritdoc />
    public partial class StationInventoryTransactionHeadersAndDetails : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "StationInventoryTransactionHeaders",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    DonViId = table.Column<int>(type: "int", nullable: false),
                    TransactionType = table.Column<int>(type: "int", nullable: false),
                    TransactionDate = table.Column<DateTime>(type: "datetime", nullable: false),
                    Note = table.Column<string>(type: "nvarchar(500)", maxLength: 500, nullable: true),
                    Created = table.Column<DateTime>(type: "datetime", nullable: false),
                    CreatedBy = table.Column<string>(type: "nvarchar(100)", maxLength: 100, nullable: true),
                    Modified = table.Column<DateTime>(type: "datetime", nullable: false),
                    ModifiedBy = table.Column<string>(type: "nvarchar(100)", maxLength: 100, nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_StationInventoryTransactionHeaders", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "StationInventoryTransactionDetails",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    HeaderId = table.Column<int>(type: "int", nullable: false),
                    ProductId = table.Column<int>(type: "int", nullable: false),
                    Quantity = table.Column<decimal>(type: "decimal(18,3)", precision: 18, scale: 3, nullable: false),
                    Amount = table.Column<decimal>(type: "decimal(18,2)", precision: 18, scale: 2, nullable: true),
                    Note = table.Column<string>(type: "nvarchar(500)", maxLength: 500, nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_StationInventoryTransactionDetails", x => x.Id);
                    table.ForeignKey(
                        name: "FK_StationInventoryTransactionDetails_FuelProducts_ProductId",
                        column: x => x.ProductId,
                        principalTable: "FuelProducts",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_StationInventoryTransactionDetails_StationInventoryTransactionHeaders_HeaderId",
                        column: x => x.HeaderId,
                        principalTable: "StationInventoryTransactionHeaders",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "IX_StationInventoryTransactionDetails_HeaderId",
                table: "StationInventoryTransactionDetails",
                column: "HeaderId");

            migrationBuilder.CreateIndex(
                name: "IX_StationInventoryTransactionDetails_ProductId",
                table: "StationInventoryTransactionDetails",
                column: "ProductId");

            // --- Data migration (legacy flat → header/detail), then empty legacy table to avoid double-counting ---
            migrationBuilder.Sql(
                """
                IF EXISTS (SELECT 1 FROM sys.tables WHERE object_id = OBJECT_ID(N'dbo.StationInventoryTransactions', N'U'))
                   AND EXISTS (SELECT 1 FROM dbo.StationInventoryTransactions)
                BEGIN
                    INSERT INTO dbo.StationInventoryTransactionHeaders (
                        DonViId,
                        TransactionType,
                        TransactionDate,
                        Note,
                        Created,
                        CreatedBy,
                        Modified,
                        ModifiedBy)
                    SELECT DISTINCT
                        t.DonViId,
                        t.TransactionType,
                        t.TransactionDate,
                        t.Note,
                        t.Created,
                        t.CreatedBy,
                        t.Modified,
                        t.ModifiedBy
                    FROM dbo.StationInventoryTransactions AS t;

                    INSERT INTO dbo.StationInventoryTransactionDetails (HeaderId, ProductId, Quantity, Amount, Note)
                    SELECT
                        h.Id,
                        t.ProductId,
                        t.Quantity,
                        t.Amount,
                        CAST(NULL AS NVARCHAR(500))
                    FROM dbo.StationInventoryTransactions AS t
                    INNER JOIN dbo.StationInventoryTransactionHeaders AS h
                        ON h.DonViId = t.DonViId
                       AND h.TransactionType = t.TransactionType
                       AND h.TransactionDate = t.TransactionDate
                       AND ((h.Note IS NULL AND t.Note IS NULL) OR (h.Note = t.Note))
                       AND h.Created = t.Created
                       AND ((h.CreatedBy IS NULL AND t.CreatedBy IS NULL) OR (h.CreatedBy = t.CreatedBy))
                       AND h.Modified = t.Modified
                       AND ((h.ModifiedBy IS NULL AND t.ModifiedBy IS NULL) OR (h.ModifiedBy = t.ModifiedBy));

                    TRUNCATE TABLE dbo.StationInventoryTransactions;
                END;
                """);

            migrationBuilder.Sql(
                """
                CREATE OR ALTER PROCEDURE dbo.sp_StoreAdmin_StationInventoryTransactionHeaders_SaveWithDetails
                    @DonViId INT,
                    @TransactionType INT,
                    @TransactionDate DATETIME,
                    @HeaderNote NVARCHAR(500) = NULL,
                    @Actor NVARCHAR(100),
                    @RetailCapDonViId INT,
                    @RowsXml NVARCHAR(MAX),
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

                    CREATE TABLE #Rows (
                        ProductId INT NOT NULL,
                        Quantity DECIMAL(18, 3) NOT NULL,
                        Amount DECIMAL(18, 2) NULL,
                        Note NVARCHAR(500) NULL);

                    DECLARE @x XML;
                    BEGIN TRY
                        SET @x = CAST(LTRIM(RTRIM(@RowsXml)) AS XML);
                    END TRY
                    BEGIN CATCH
                        RAISERROR(N'Rows payload is not valid XML.', 16, 1);
                        RETURN;
                    END CATCH;

                    INSERT INTO #Rows (ProductId, Quantity, Amount, Note)
                    SELECT
                        T.c.value('@productId', 'INT'),
                        T.c.value('@quantity', 'DECIMAL(18,3)'),
                        CASE WHEN T.c.exist('@amount') = 1 THEN T.c.value('@amount', 'DECIMAL(18,2)') END,
                        NULLIF(LTRIM(RTRIM(T.c.value('@note', 'NVARCHAR(500)'))), N'')
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

                        INSERT INTO dbo.StationInventoryTransactionDetails (HeaderId, ProductId, Quantity, Amount, Note)
                        SELECT @HeaderId, r.ProductId, r.Quantity, r.Amount, r.Note
                        FROM #Rows r;

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
                CREATE OR ALTER PROCEDURE dbo.sp_StoreAdmin_StationInventoryTransactionHeaders_UpdateWithDetails
                    @HeaderId INT,
                    @DonViId INT,
                    @TransactionType INT,
                    @TransactionDate DATETIME,
                    @HeaderNote NVARCHAR(500) = NULL,
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

                    CREATE TABLE #Rows (
                        ProductId INT NOT NULL,
                        Quantity DECIMAL(18, 3) NOT NULL,
                        Amount DECIMAL(18, 2) NULL,
                        Note NVARCHAR(500) NULL);

                    DECLARE @x XML;
                    BEGIN TRY
                        SET @x = CAST(LTRIM(RTRIM(@RowsXml)) AS XML);
                    END TRY
                    BEGIN CATCH
                        RAISERROR(N'Rows payload is not valid XML.', 16, 1);
                        RETURN;
                    END CATCH;

                    INSERT INTO #Rows (ProductId, Quantity, Amount, Note)
                    SELECT
                        T.c.value('@productId', 'INT'),
                        T.c.value('@quantity', 'DECIMAL(18,3)'),
                        CASE WHEN T.c.exist('@amount') = 1 THEN T.c.value('@amount', 'DECIMAL(18,2)') END,
                        NULLIF(LTRIM(RTRIM(T.c.value('@note', 'NVARCHAR(500)'))), N'')
                    FROM @x.nodes('/rows/r') AS T(c);

                    IF NOT EXISTS (SELECT 1 FROM #Rows)
                    BEGIN
                        RAISERROR(N'No valid rows in payload.', 16, 1);
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

                        INSERT INTO dbo.StationInventoryTransactionDetails (HeaderId, ProductId, Quantity, Amount, Note)
                        SELECT @HeaderId, r.ProductId, r.Quantity, r.Amount, r.Note
                        FROM #Rows r;

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
                CREATE OR ALTER PROCEDURE dbo.sp_StoreAdmin_StationInventoryTransactionHeaders_ListPaged
                    @Skip INT,
                    @Take INT,
                    @DonViId INT = NULL,
                    @ProductId INT = NULL,
                    @TransactionType INT = NULL,
                    @TransactionDateFrom DATETIME = NULL,
                    @TransactionDateTo DATETIME = NULL,
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

                    CREATE TABLE #H (
                        Id INT NOT NULL PRIMARY KEY,
                        DonViId INT NOT NULL,
                        TransactionType INT NOT NULL,
                        TransactionDate DATETIME NOT NULL,
                        Note NVARCHAR(500) NULL,
                        Created DATETIME NOT NULL,
                        CreatedBy NVARCHAR(100) NULL,
                        Modified DATETIME NOT NULL,
                        ModifiedBy NVARCHAR(100) NULL,
                        LineCount INT NOT NULL);

                    INSERT INTO #H (
                        Id,
                        DonViId,
                        TransactionType,
                        TransactionDate,
                        Note,
                        Created,
                        CreatedBy,
                        Modified,
                        ModifiedBy,
                        LineCount)
                    SELECT
                        h.Id,
                        h.DonViId,
                        h.TransactionType,
                        h.TransactionDate,
                        h.Note,
                        h.Created,
                        h.CreatedBy,
                        h.Modified,
                        h.ModifiedBy,
                        LineCount = (
                            SELECT COUNT(1)
                            FROM dbo.StationInventoryTransactionDetails d0
                            WHERE d0.HeaderId = h.Id)
                    FROM dbo.StationInventoryTransactionHeaders h
                    INNER JOIN dbo.DM_DonVi dv ON dv.Id = h.DonViId AND dv.CapDonViId = @RetailCapDonViId
                    WHERE (@DonViId IS NULL OR h.DonViId = @DonViId)
                      AND (@TransactionType IS NULL OR h.TransactionType = @TransactionType)
                      AND (@TransactionDateFrom IS NULL OR h.TransactionDate >= @TransactionDateFrom)
                      AND (@TransactionDateTo IS NULL OR h.TransactionDate <= @TransactionDateTo)
                      AND (
                          @DonViScopeCsv IS NULL
                          OR LTRIM(RTRIM(@DonViScopeCsv)) = N''
                          OR h.DonViId IN (SELECT Id FROM @ScopeIds))
                      AND (
                          @ProductId IS NULL
                          OR EXISTS (
                              SELECT 1
                              FROM dbo.StationInventoryTransactionDetails d
                              WHERE d.HeaderId = h.Id AND d.ProductId = @ProductId));

                    SELECT @TotalCount = COUNT(1) FROM #H;

                    SELECT
                        Id,
                        DonViId,
                        TransactionType,
                        TransactionDate,
                        Note,
                        LineCount,
                        Created,
                        CreatedBy,
                        Modified,
                        ModifiedBy
                    FROM #H
                    ORDER BY TransactionDate DESC, Id DESC
                    OFFSET @Skip ROWS FETCH NEXT @Take ROWS ONLY;
                END;
                """);

            migrationBuilder.Sql(
                """
                CREATE OR ALTER PROCEDURE dbo.sp_StoreAdmin_StationInventoryTransactionHeaders_ListByStore
                    @DonViId INT,
                    @RetailCapDonViId INT,
                    @ProductId INT = NULL,
                    @TransactionType INT = NULL,
                    @TransactionDateFrom DATETIME = NULL,
                    @TransactionDateTo DATETIME = NULL
                AS
                BEGIN
                    SET NOCOUNT ON;

                    SELECT
                        h.Id,
                        h.DonViId,
                        h.TransactionType,
                        h.TransactionDate,
                        h.Note,
                        LineCount = (
                            SELECT COUNT(1)
                            FROM dbo.StationInventoryTransactionDetails d0
                            WHERE d0.HeaderId = h.Id),
                        h.Created,
                        h.CreatedBy,
                        h.Modified,
                        h.ModifiedBy
                    FROM dbo.StationInventoryTransactionHeaders h
                    INNER JOIN dbo.DM_DonVi dv ON dv.Id = h.DonViId AND dv.CapDonViId = @RetailCapDonViId
                    WHERE h.DonViId = @DonViId
                      AND (@ProductId IS NULL OR EXISTS (
                          SELECT 1 FROM dbo.StationInventoryTransactionDetails d
                          WHERE d.HeaderId = h.Id AND d.ProductId = @ProductId))
                      AND (@TransactionType IS NULL OR h.TransactionType = @TransactionType)
                      AND (@TransactionDateFrom IS NULL OR h.TransactionDate >= @TransactionDateFrom)
                      AND (@TransactionDateTo IS NULL OR h.TransactionDate <= @TransactionDateTo)
                    ORDER BY h.TransactionDate DESC, h.Id DESC;
                END;
                """);

            migrationBuilder.Sql(
                """
                CREATE OR ALTER PROCEDURE dbo.sp_StoreAdmin_StationInventoryTransactionHeaders_GetById
                    @HeaderId INT,
                    @RetailCapDonViId INT
                AS
                BEGIN
                    SET NOCOUNT ON;

                    SELECT
                        h.Id,
                        h.DonViId,
                        h.TransactionType,
                        h.TransactionDate,
                        h.Note,
                        h.Created,
                        h.CreatedBy,
                        h.Modified,
                        h.ModifiedBy
                    FROM dbo.StationInventoryTransactionHeaders h
                    INNER JOIN dbo.DM_DonVi dv ON dv.Id = h.DonViId AND dv.CapDonViId = @RetailCapDonViId
                    WHERE h.Id = @HeaderId;
                END;
                """);

            migrationBuilder.Sql(
                """
                CREATE OR ALTER PROCEDURE dbo.sp_StoreAdmin_StationInventoryTransactionDetails_ListByHeaderId
                    @HeaderId INT,
                    @RetailCapDonViId INT
                AS
                BEGIN
                    SET NOCOUNT ON;

                    IF NOT EXISTS (
                        SELECT 1
                        FROM dbo.StationInventoryTransactionHeaders h
                        INNER JOIN dbo.DM_DonVi dv ON dv.Id = h.DonViId AND dv.CapDonViId = @RetailCapDonViId
                        WHERE h.Id = @HeaderId)
                    BEGIN
                        RETURN;
                    END;

                    SELECT
                        d.Id,
                        d.HeaderId,
                        d.ProductId,
                        d.Quantity,
                        d.Amount,
                        d.Note
                    FROM dbo.StationInventoryTransactionDetails d
                    WHERE d.HeaderId = @HeaderId
                    ORDER BY d.Id;
                END;
                """);

            migrationBuilder.Sql(
                """
                CREATE OR ALTER PROCEDURE dbo.sp_StoreAdmin_StationInventoryTransactionHeaders_GetLatest
                    @DonViId INT = NULL,
                    @DonViScopeCsv NVARCHAR(MAX) = NULL,
                    @RetailCapDonViId INT
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

                    DECLARE @HId INT = NULL;

                    SELECT TOP (1) @HId = h.Id
                    FROM dbo.StationInventoryTransactionHeaders h
                    INNER JOIN dbo.DM_DonVi dv ON dv.Id = h.DonViId AND dv.CapDonViId = @RetailCapDonViId
                    WHERE (@DonViId IS NULL OR h.DonViId = @DonViId)
                      AND (
                          @DonViScopeCsv IS NULL
                          OR LTRIM(RTRIM(@DonViScopeCsv)) = N''
                          OR h.DonViId IN (SELECT Id FROM @ScopeIds))
                    ORDER BY h.TransactionDate DESC, h.Id DESC;

                    SELECT
                        h.Id,
                        h.DonViId,
                        h.TransactionType,
                        h.TransactionDate,
                        h.Note,
                        h.Created,
                        h.CreatedBy,
                        h.Modified,
                        h.ModifiedBy
                    FROM dbo.StationInventoryTransactionHeaders h
                    WHERE @HId IS NOT NULL AND h.Id = @HId;

                    SELECT
                        d.Id,
                        d.HeaderId,
                        d.ProductId,
                        d.Quantity,
                        d.Amount,
                        d.Note
                    FROM dbo.StationInventoryTransactionDetails d
                    WHERE @HId IS NOT NULL AND d.HeaderId = @HId
                    ORDER BY d.Id;
                END;
                """);

            migrationBuilder.Sql(
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
                        SELECT h.DonViId, d.ProductId, d.Quantity, h.TransactionType, h.TransactionDate
                        FROM dbo.StationInventoryTransactionDetails AS d
                        INNER JOIN dbo.StationInventoryTransactionHeaders AS h ON h.Id = d.HeaderId
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
                            CurrentQuantity = SUM(CAST(ft.Quantity AS DECIMAL(18, 4)) * CAST(ft.TransactionType AS DECIMAL(18, 4))),
                            ProductCode = MAX(ISNULL(fp.Code, N'')),
                            ProductName = MAX(ISNULL(fp.Name, N'')),
                            UnitId = MAX(fp.UnitId),
                            UnitMa = MAX(u.Ma),
                            UnitTen = MAX(u.Ten),
                            LastTransactionDate = MAX(ft.TransactionDate)
                        FROM FilteredTx AS ft
                        INNER JOIN dbo.FuelProducts AS fp ON fp.Id = ft.ProductId
                        LEFT JOIN dbo.DM_DonViTinh AS u ON u.Id = fp.UnitId
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
                """);

            migrationBuilder.Sql(
                """
                CREATE OR ALTER PROCEDURE dbo.sp_StoreAdmin_InventoryCurrent_ListByStore
                    @DonViId INT,
                    @RetailCapDonViId INT
                AS
                BEGIN
                    SET NOCOUNT ON;

                    ;WITH FilteredTx AS (
                        SELECT h.DonViId, d.ProductId, d.Quantity, h.TransactionType, h.TransactionDate
                        FROM dbo.StationInventoryTransactionDetails AS d
                        INNER JOIN dbo.StationInventoryTransactionHeaders AS h ON h.Id = d.HeaderId
                        INNER JOIN dbo.DM_DonVi AS dv ON dv.Id = h.DonViId AND dv.CapDonViId = @RetailCapDonViId
                        WHERE h.DonViId = @DonViId
                    ),
                    Agg AS (
                        SELECT
                            ft.DonViId,
                            ft.ProductId,
                            CurrentQuantity = SUM(CAST(ft.Quantity AS DECIMAL(18, 4)) * CAST(ft.TransactionType AS DECIMAL(18, 4))),
                            ProductCode = MAX(ISNULL(fp.Code, N'')),
                            ProductName = MAX(ISNULL(fp.Name, N'')),
                            UnitId = MAX(fp.UnitId),
                            UnitMa = MAX(u.Ma),
                            UnitTen = MAX(u.Ten),
                            LastTransactionDate = MAX(ft.TransactionDate)
                        FROM FilteredTx AS ft
                        INNER JOIN dbo.FuelProducts AS fp ON fp.Id = ft.ProductId
                        LEFT JOIN dbo.DM_DonViTinh AS u ON u.Id = fp.UnitId
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
                """);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.Sql("DROP PROCEDURE IF EXISTS dbo.sp_StoreAdmin_StationInventoryTransactionHeaders_SaveWithDetails;");
            migrationBuilder.Sql("DROP PROCEDURE IF EXISTS dbo.sp_StoreAdmin_StationInventoryTransactionHeaders_UpdateWithDetails;");
            migrationBuilder.Sql("DROP PROCEDURE IF EXISTS dbo.sp_StoreAdmin_StationInventoryTransactionHeaders_ListPaged;");
            migrationBuilder.Sql("DROP PROCEDURE IF EXISTS dbo.sp_StoreAdmin_StationInventoryTransactionHeaders_ListByStore;");
            migrationBuilder.Sql("DROP PROCEDURE IF EXISTS dbo.sp_StoreAdmin_StationInventoryTransactionHeaders_GetById;");
            migrationBuilder.Sql("DROP PROCEDURE IF EXISTS dbo.sp_StoreAdmin_StationInventoryTransactionDetails_ListByHeaderId;");
            migrationBuilder.Sql("DROP PROCEDURE IF EXISTS dbo.sp_StoreAdmin_StationInventoryTransactionHeaders_GetLatest;");

            migrationBuilder.Sql(
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
                        SELECT t.DonViId, t.ProductId, t.Quantity, t.TransactionType, t.TransactionDate
                        FROM dbo.StationInventoryTransactions AS t
                        INNER JOIN dbo.DM_DonVi AS dv ON dv.Id = t.DonViId AND dv.CapDonViId = @RetailCapDonViId
                        WHERE (@DonViId IS NULL OR t.DonViId = @DonViId)
                          AND (@ProductId IS NULL OR t.ProductId = @ProductId)
                          AND (
                              @DonViScopeCsv IS NULL
                              OR LTRIM(RTRIM(@DonViScopeCsv)) = N''
                              OR t.DonViId IN (SELECT Id FROM @ScopeIds)
                          )
                    ),
                    Agg AS (
                        SELECT
                            ft.DonViId,
                            ft.ProductId,
                            CurrentQuantity = SUM(CAST(ft.Quantity AS DECIMAL(18, 4)) * CAST(ft.TransactionType AS DECIMAL(18, 4))),
                            ProductCode = MAX(ISNULL(fp.Code, N'')),
                            ProductName = MAX(ISNULL(fp.Name, N'')),
                            UnitId = MAX(fp.UnitId),
                            UnitMa = MAX(u.Ma),
                            UnitTen = MAX(u.Ten),
                            LastTransactionDate = MAX(ft.TransactionDate)
                        FROM FilteredTx AS ft
                        INNER JOIN dbo.FuelProducts AS fp ON fp.Id = ft.ProductId
                        LEFT JOIN dbo.DM_DonViTinh AS u ON u.Id = fp.UnitId
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
                """);

            migrationBuilder.Sql(
                """
                CREATE OR ALTER PROCEDURE dbo.sp_StoreAdmin_InventoryCurrent_ListByStore
                    @DonViId INT,
                    @RetailCapDonViId INT
                AS
                BEGIN
                    SET NOCOUNT ON;

                    ;WITH FilteredTx AS (
                        SELECT t.DonViId, t.ProductId, t.Quantity, t.TransactionType, t.TransactionDate
                        FROM dbo.StationInventoryTransactions AS t
                        INNER JOIN dbo.DM_DonVi AS dv ON dv.Id = t.DonViId AND dv.CapDonViId = @RetailCapDonViId
                        WHERE t.DonViId = @DonViId
                    ),
                    Agg AS (
                        SELECT
                            ft.DonViId,
                            ft.ProductId,
                            CurrentQuantity = SUM(CAST(ft.Quantity AS DECIMAL(18, 4)) * CAST(ft.TransactionType AS DECIMAL(18, 4))),
                            ProductCode = MAX(ISNULL(fp.Code, N'')),
                            ProductName = MAX(ISNULL(fp.Name, N'')),
                            UnitId = MAX(fp.UnitId),
                            UnitMa = MAX(u.Ma),
                            UnitTen = MAX(u.Ten),
                            LastTransactionDate = MAX(ft.TransactionDate)
                        FROM FilteredTx AS ft
                        INNER JOIN dbo.FuelProducts AS fp ON fp.Id = ft.ProductId
                        LEFT JOIN dbo.DM_DonViTinh AS u ON u.Id = fp.UnitId
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
                """);

            migrationBuilder.DropTable(
                name: "StationInventoryTransactionDetails");

            migrationBuilder.DropTable(
                name: "StationInventoryTransactionHeaders");
        }
    }
}
