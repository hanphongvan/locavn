using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Httm.XangDau.Api.Shared.Persistence.Migrations;

/// <inheritdoc />
/// <summary>
/// Hub store prices: optional <c>ProductId</c> on history list; current rows join <c>StationPrices</c> with
/// <c>IsActive = 1</c> and <c>ActiveDate &lt;= GETDATE()</c> (ngày áp dụng đã tới). Adds <c>StationPrices</c> list/get/update SPs.
/// </summary>
public partial class StorePriceHubStationPricesBoards : Migration
{
    /// <inheritdoc />
    protected override void Up(MigrationBuilder migrationBuilder)
    {
        migrationBuilder.Sql(@"
CREATE OR ALTER PROCEDURE dbo.sp_StoreAdmin_StationProductPrices_ListByStore
    @DonViId INT,
    @RetailCapDonViId INT,
    @ProductId INT = NULL
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
      AND (@ProductId IS NULL OR p.ProductId = @ProductId)
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
    WHERE p.DonViId = @DonViId
      AND s.IsActive = 1
      AND s.ActiveDate <= GETDATE()
    ORDER BY p.ProductId;
END;
");

        migrationBuilder.Sql(@"
CREATE OR ALTER PROCEDURE dbo.sp_StoreAdmin_StationPrices_ListPaged
    @Skip INT,
    @Take INT,
    @DonViId INT = NULL,
    @IsActive BIT = NULL,
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
        s.Id,
        s.DonViId,
        s.ActiveDate,
        s.IsActive,
        s.Created,
        s.CreatedBy,
        s.Modified,
        s.ModifiedBy
    INTO #Filtered
    FROM dbo.StationPrices AS s
    INNER JOIN dbo.DM_DonVi AS d ON d.Id = s.DonViId AND d.CapDonViId = @RetailCapDonViId
    WHERE (@DonViId IS NULL OR s.DonViId = @DonViId)
      AND (@IsActive IS NULL OR s.IsActive = @IsActive)
      AND (
          @DonViScopeCsv IS NULL
          OR LTRIM(RTRIM(@DonViScopeCsv)) = N''
          OR s.DonViId IN (SELECT Id FROM @ScopeIds)
      );

    SELECT @TotalCount = COUNT(1) FROM #Filtered;

    SELECT
        Id,
        DonViId,
        ActiveDate,
        IsActive,
        Created,
        CreatedBy,
        Modified,
        ModifiedBy
    FROM #Filtered
    ORDER BY ActiveDate DESC, DonViId, Id
    OFFSET @Skip ROWS FETCH NEXT @Take ROWS ONLY;
END;
");

        migrationBuilder.Sql(@"
CREATE OR ALTER PROCEDURE dbo.sp_StoreAdmin_StationPrices_GetById
    @Id INT,
    @RetailCapDonViId INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT TOP (1)
        s.Id,
        s.DonViId,
        s.ActiveDate,
        s.IsActive,
        s.Created,
        s.CreatedBy,
        s.Modified,
        s.ModifiedBy
    FROM dbo.StationPrices AS s
    INNER JOIN dbo.DM_DonVi AS d ON d.Id = s.DonViId AND d.CapDonViId = @RetailCapDonViId
    WHERE s.Id = @Id;
END;
");

        migrationBuilder.Sql(@"
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

    DECLARE @Now DATETIME2(3) = SYSUTCDATETIME();
    DECLARE @Actor50 NVARCHAR(50) = LEFT(ISNULL(@Actor, N''), 50);

    UPDATE dbo.StationPrices
    SET
        ActiveDate = @ActiveDate,
        IsActive = @IsActive,
        Modified = @Now,
        ModifiedBy = @Actor50
    WHERE Id = @Id;
END;
");
    }

    /// <inheritdoc />
    protected override void Down(MigrationBuilder migrationBuilder)
    {
    }
}
