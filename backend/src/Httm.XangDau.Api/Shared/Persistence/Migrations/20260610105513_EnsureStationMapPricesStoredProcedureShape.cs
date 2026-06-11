using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Httm.XangDau.Api.Shared.Persistence.Migrations
{
    /// <summary>
    /// Re-applies <c>sp_Api_StationMapPrices_ByDonViIds</c> + <c>sp_Api_StationSpotlight_CheapestRetail</c>
    /// so they project DonViId, ProductCode, Price (not full <c>StationProductPrices</c> columns).
    /// Fixes Dapper materialization for the station map/detail/spotlight APIs.
    /// </summary>
    public partial class EnsureStationMapPricesStoredProcedureShape : Migration
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
        }
    }
}
