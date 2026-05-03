using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Httm.XangDau.Api.Shared.Persistence.Migrations;

/// <inheritdoc />
public partial class AddFuelTransactionsAndStoredProcedures : Migration
{
    /// <inheritdoc />
    protected override void Up(MigrationBuilder migrationBuilder)
    {
        migrationBuilder.Sql(FuelTransactionsSchemaSql.Tables);
        migrationBuilder.Sql(FuelStoredProceduresSql.GetCurrentVehicle);
        migrationBuilder.Sql(FuelStoredProceduresSql.GetMonthlySummary);
        migrationBuilder.Sql(FuelStoredProceduresSql.GetInsights);
        migrationBuilder.Sql(FuelStoredProceduresSql.GetTransactions);
        migrationBuilder.Sql(FuelStoredProceduresSql.TransactionInsert);
    }

    /// <inheritdoc />
    protected override void Down(MigrationBuilder migrationBuilder)
    {
        migrationBuilder.Sql(FuelStoredProceduresSql.DropProcedures);
        migrationBuilder.Sql(FuelTransactionsSchemaSql.DropTable);
    }
}
