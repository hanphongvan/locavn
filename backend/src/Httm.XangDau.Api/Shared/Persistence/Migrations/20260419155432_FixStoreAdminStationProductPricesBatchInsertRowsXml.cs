using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Httm.XangDau.Api.Shared.Persistence.Migrations;

/// <inheritdoc />
/// <summary>
/// Replaces JSON + OPENJSON in batch insert (requires SQL 2016 + compat 130+) with XML + .nodes()
/// so older SQL Server / lower compatibility_level still work (stored procedure first per docs/architecture/backend.md).
/// </summary>
public partial class FixStoreAdminStationProductPricesBatchInsertRowsXml : Migration
{
    /// <inheritdoc />
    protected override void Up(MigrationBuilder migrationBuilder)
    {
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
    }
}
