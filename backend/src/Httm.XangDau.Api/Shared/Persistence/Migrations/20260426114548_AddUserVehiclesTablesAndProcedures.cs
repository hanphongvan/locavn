using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Httm.XangDau.Api.Shared.Persistence.Migrations
{
    /// <inheritdoc />
    public partial class AddUserVehiclesTablesAndProcedures : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.Sql(UserVehiclesSchemaSql.Tables);
            migrationBuilder.Sql(UserVehiclesStoredProceduresSql.GetByUser);
            migrationBuilder.Sql(UserVehiclesStoredProceduresSql.GetById);
            migrationBuilder.Sql(UserVehiclesStoredProceduresSql.Create);
            migrationBuilder.Sql(UserVehiclesStoredProceduresSql.Update);
            migrationBuilder.Sql(UserVehiclesStoredProceduresSql.Delete);
            migrationBuilder.Sql(UserVehiclesStoredProceduresSql.SetDefault);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.Sql(UserVehiclesStoredProceduresSql.DropProcedures);
            migrationBuilder.Sql(UserVehiclesSchemaSql.DropTables);
        }
    }
}
