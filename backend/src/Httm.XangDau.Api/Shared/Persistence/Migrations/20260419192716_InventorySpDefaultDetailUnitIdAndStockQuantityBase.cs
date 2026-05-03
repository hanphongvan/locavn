using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Httm.XangDau.Api.Shared.Persistence.Migrations;

/// <inheritdoc />
public partial class InventorySpDefaultDetailUnitIdAndStockQuantityBase : Migration
{
    /// <inheritdoc />
    protected override void Up(MigrationBuilder migrationBuilder)
    {
        migrationBuilder.Sql(InventoryTransactionSpDefaultDetailUnitIdAndStockProcedures.SaveWithDetails);
        migrationBuilder.Sql(InventoryTransactionSpDefaultDetailUnitIdAndStockProcedures.UpdateWithDetails);
        migrationBuilder.Sql(InventoryTransactionSpDefaultDetailUnitIdAndStockProcedures.InventoryCurrentListPaged);
        migrationBuilder.Sql(InventoryTransactionSpDefaultDetailUnitIdAndStockProcedures.InventoryCurrentListByStore);
    }

    /// <inheritdoc />
    protected override void Down(MigrationBuilder migrationBuilder) =>
        throw new InvalidOperationException(
            "Rolling back this migration is not supported automatically (replaces stored procedures). Restore the database from a backup taken before this migration was applied.");
}
