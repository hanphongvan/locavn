using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Httm.XangDau.Api.Shared.Persistence.Migrations;

/// <inheritdoc />
public partial class InventoryTransactionDetailsRequireUnitIdXmlAndUnitName : Migration
{
    /// <inheritdoc />
    protected override void Up(MigrationBuilder migrationBuilder)
    {
        migrationBuilder.Sql(InventoryTransactionDetailsRequireUnitIdXmlAndUnitNameProcedures.DonViTinhExists);
        migrationBuilder.Sql(InventoryTransactionDetailsRequireUnitIdXmlAndUnitNameProcedures.FuelProductUnitById);
        migrationBuilder.Sql(InventoryTransactionDetailsRequireUnitIdXmlAndUnitNameProcedures.SaveWithDetails);
        migrationBuilder.Sql(InventoryTransactionDetailsRequireUnitIdXmlAndUnitNameProcedures.UpdateWithDetails);
        migrationBuilder.Sql(InventoryTransactionDetailsRequireUnitIdXmlAndUnitNameProcedures.ListByHeaderId);
        migrationBuilder.Sql(InventoryTransactionDetailsRequireUnitIdXmlAndUnitNameProcedures.GetLatest);
    }

    /// <inheritdoc />
    protected override void Down(MigrationBuilder migrationBuilder) =>
        throw new InvalidOperationException(
            "Rolling back this migration is not supported automatically (replaces stored procedures). Restore the database from a backup taken before this migration was applied.");
}
