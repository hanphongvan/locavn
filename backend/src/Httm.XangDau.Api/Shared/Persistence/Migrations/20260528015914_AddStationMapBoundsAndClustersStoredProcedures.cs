using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Httm.XangDau.Api.Shared.Persistence.Migrations
{
    /// <inheritdoc />
    public partial class AddStationMapBoundsAndClustersStoredProcedures : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.Sql(ApiStationMapListByBoundsSql.CreateProcedure);
            migrationBuilder.Sql(ApiStationMapProvinceClustersSql.CreateProcedure);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.Sql("DROP PROCEDURE IF EXISTS dbo.sp_Api_StationMap_ProvinceClusters;");
            migrationBuilder.Sql("DROP PROCEDURE IF EXISTS dbo.sp_Api_StationMap_ListByBounds;");
        }
    }
}
