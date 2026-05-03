using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Httm.XangDau.Api.Shared.Persistence.Migrations
{
    /// <inheritdoc />
    public partial class ReportsSystemInventoryByProduct : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.Sql(
                """
                IF OBJECT_ID(N'dbo.sp_Reports_GetSystemInventoryByProduct', N'P') IS NOT NULL
                    DROP PROCEDURE dbo.sp_Reports_GetSystemInventoryByProduct;
                """);

            migrationBuilder.Sql(ReportsStoredProcedures.GetInventorySummary);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.Sql(
                """
                IF OBJECT_ID(N'dbo.sp_Reports_GetInventorySummary', N'P') IS NOT NULL
                    DROP PROCEDURE dbo.sp_Reports_GetInventorySummary;
                """);

            migrationBuilder.Sql(ReportsStoredProcedures.GetInventorySummary);
        }
    }
}
