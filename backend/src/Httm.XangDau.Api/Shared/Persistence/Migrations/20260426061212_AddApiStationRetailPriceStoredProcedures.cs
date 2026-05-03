using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Httm.XangDau.Api.Shared.Persistence.Migrations
{
    /// <inheritdoc />
    public partial class AddApiStationRetailPriceStoredProcedures : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.Sql(ApiStationRetailPricesStoredProceduresSql.MapPricesByDonViIds);
            migrationBuilder.Sql(ApiStationRetailPricesStoredProceduresSql.CheapestByProductCode);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.Sql(
                """
                IF OBJECT_ID(N'dbo.sp_Api_StationSpotlight_CheapestRetail', N'P') IS NOT NULL
                    DROP PROCEDURE dbo.sp_Api_StationSpotlight_CheapestRetail;
                IF OBJECT_ID(N'dbo.sp_Api_StationMapPrices_ByDonViIds', N'P') IS NOT NULL
                    DROP PROCEDURE dbo.sp_Api_StationMapPrices_ByDonViIds;
                """);
        }
    }
}
