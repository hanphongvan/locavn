using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Httm.XangDau.Api.Shared.Persistence.Migrations
{
    /// <inheritdoc />
    public partial class AddDemoDataStoredProcedures : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.Sql(DemoDataStoredProceduresSql.SpClear);
            migrationBuilder.Sql(DemoDataStoredProceduresSql.SpGeneratePrices);
            migrationBuilder.Sql(DemoDataStoredProceduresSql.SpGenerateInventory);
            migrationBuilder.Sql(DemoDataStoredProceduresSql.SpGenerateAll);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.Sql(DemoDataStoredProceduresSql.DropAll);
        }
    }
}
