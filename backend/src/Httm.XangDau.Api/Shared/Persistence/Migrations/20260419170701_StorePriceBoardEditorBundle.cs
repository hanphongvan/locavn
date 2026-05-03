using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Httm.XangDau.Api.Shared.Persistence.Migrations;

/// <inheritdoc />
public partial class StorePriceBoardEditorBundle : Migration
{
    /// <inheritdoc />
    protected override void Up(MigrationBuilder migrationBuilder)
    {
        migrationBuilder.Sql(@"
CREATE OR ALTER PROCEDURE dbo.sp_StoreAdmin_StationPrices_GetBoardEditor
    @StationPricesId INT,
    @RetailCapDonViId INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT s.Id AS StationPricesId, s.DonViId, s.ActiveDate, s.IsActive
    FROM dbo.StationPrices AS s
    INNER JOIN dbo.DM_DonVi AS d ON d.Id = s.DonViId AND d.CapDonViId = @RetailCapDonViId
    WHERE s.Id = @StationPricesId;

    SELECT p.Id AS LineId, p.ProductId, p.Price, p.UnitId, p.Note
    FROM dbo.StationProductPrices AS p
    INNER JOIN dbo.DM_DonVi AS d ON d.Id = p.DonViId AND d.CapDonViId = @RetailCapDonViId
    WHERE p.StationPricesId = @StationPricesId
    ORDER BY p.ProductId;
END;
");

        migrationBuilder.Sql(@"
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

    DECLARE @Now DATETIME2(3) = SYSUTCDATETIME();
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
");
    }

    /// <inheritdoc />
    protected override void Down(MigrationBuilder migrationBuilder)
    {
    }
}
