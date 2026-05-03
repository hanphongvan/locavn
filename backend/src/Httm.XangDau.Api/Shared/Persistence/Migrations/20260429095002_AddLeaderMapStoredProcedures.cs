using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Httm.XangDau.Api.Shared.Persistence.Migrations
{
    /// <inheritdoc />
    public partial class AddLeaderMapStoredProcedures : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.Sql(LeaderMapStoredProceduresSql.CreateDistributorUnitsList);
            migrationBuilder.Sql(LeaderMapStoredProceduresSql.CreateRetailStationsListByBounds);
            migrationBuilder.Sql(LeaderMapStoredProceduresSql.CreateBadReportsByStation);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.Sql("DROP PROCEDURE IF EXISTS dbo.sp_Leader_Map_BadReports_ByStation;");
            migrationBuilder.Sql("DROP PROCEDURE IF EXISTS dbo.sp_Leader_Map_RetailStations_ListByBounds;");
            migrationBuilder.Sql("DROP PROCEDURE IF EXISTS dbo.sp_Leader_Map_DistributorUnits_List;");
        }
    }
}
