using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Httm.XangDau.Api.Shared.Persistence.Migrations
{
    /// <inheritdoc />
    public partial class AddStationRatingsTablesAndProcedures : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.Sql(StationRatingSchemaSql.Tables);
            migrationBuilder.Sql(StationRatingStoredProceduresSql.Insert);
            migrationBuilder.Sql(StationRatingStoredProceduresSql.InsertImage);
            migrationBuilder.Sql(StationRatingStoredProceduresSql.GetSummary);
            migrationBuilder.Sql(StationRatingStoredProceduresSql.GetByStation);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.Sql(StationRatingStoredProceduresSql.DropProcedures);
            migrationBuilder.Sql(StationRatingStoredProceduresSql.DropTables);
        }
    }
}
