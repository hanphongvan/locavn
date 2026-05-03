using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Httm.XangDau.Api.Shared.Persistence.Migrations
{
    /// <inheritdoc />
    public partial class AddReportsStoredProcedures : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.Sql(ReportsStoredProcedures.GetStationOverview);
            migrationBuilder.Sql(ReportsStoredProcedures.GetInventorySummary);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.Sql(
                """
                IF OBJECT_ID(N'dbo.sp_Reports_GetInventorySummary', N'P') IS NOT NULL
                    DROP PROCEDURE dbo.sp_Reports_GetInventorySummary;
                IF OBJECT_ID(N'dbo.sp_Reports_GetStationOverview', N'P') IS NOT NULL
                    DROP PROCEDURE dbo.sp_Reports_GetStationOverview;
                """);
        }
    }
}
