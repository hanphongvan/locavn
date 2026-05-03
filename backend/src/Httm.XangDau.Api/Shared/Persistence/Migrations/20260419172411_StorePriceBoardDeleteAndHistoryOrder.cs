using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Httm.XangDau.Api.Shared.Persistence.Migrations
{
    /// <inheritdoc />
    public partial class StorePriceBoardDeleteAndHistoryOrder : Migration
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
    INNER JOIN dbo.StationPrices AS s ON s.Id = p.StationPricesId
    WHERE p.DonViId = @DonViId
      AND (@ProductId IS NULL OR p.ProductId = @ProductId)
    ORDER BY s.ActiveDate DESC, p.ProductId, p.Id;
END;
");

            migrationBuilder.Sql(@"
CREATE OR ALTER PROCEDURE dbo.sp_StoreAdmin_StationPrices_Delete
    @Id INT,
    @RetailCapDonViId INT
AS
BEGIN
    SET NOCOUNT ON;

    DELETE s
    FROM dbo.StationPrices AS s
    INNER JOIN dbo.DM_DonVi AS d ON d.Id = s.DonViId AND d.CapDonViId = @RetailCapDonViId
    WHERE s.Id = @Id;

    IF @@ROWCOUNT = 0
        RAISERROR(N'StationPrices row not found or not in retail store scope.', 16, 1);
END;
");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.Sql("DROP PROCEDURE IF EXISTS dbo.sp_StoreAdmin_StationPrices_Delete;");

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
        }
    }
}
