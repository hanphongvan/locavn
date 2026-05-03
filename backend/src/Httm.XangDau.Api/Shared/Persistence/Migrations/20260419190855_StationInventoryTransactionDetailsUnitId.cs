using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Httm.XangDau.Api.Shared.Persistence.Migrations;

/// <inheritdoc />
public partial class StationInventoryTransactionDetailsUnitId : Migration
{
    /// <inheritdoc />
    protected override void Up(MigrationBuilder migrationBuilder)
    {
        migrationBuilder.AddColumn<int>(
            name: "UnitId",
            table: "StationInventoryTransactionDetails",
            type: "int",
            nullable: true);

        migrationBuilder.Sql(StationInventoryTransactionDetailsUnitIdProcedures.BackfillAndAlterNotNull);

        migrationBuilder.CreateIndex(
            name: "IX_StationInventoryTransactionDetails_UnitId",
            table: "StationInventoryTransactionDetails",
            column: "UnitId");

        migrationBuilder.AddForeignKey(
            name: "FK_StationInventoryTransactionDetails_DM_DonViTinh_UnitId",
            table: "StationInventoryTransactionDetails",
            column: "UnitId",
            principalTable: "DM_DonViTinh",
            principalColumn: "Id",
            onDelete: ReferentialAction.Restrict);

        migrationBuilder.Sql(StationInventoryTransactionDetailsUnitIdProcedures.SaveWithDetails);
        migrationBuilder.Sql(StationInventoryTransactionDetailsUnitIdProcedures.UpdateWithDetails);
        migrationBuilder.Sql(StationInventoryTransactionDetailsUnitIdProcedures.ListByHeaderId);
        migrationBuilder.Sql(StationInventoryTransactionDetailsUnitIdProcedures.GetLatest);
        migrationBuilder.Sql(StationInventoryTransactionDetailsUnitIdProcedures.InventoryCurrentListPaged);
        migrationBuilder.Sql(StationInventoryTransactionDetailsUnitIdProcedures.InventoryCurrentListByStore);
    }

    /// <inheritdoc />
    protected override void Down(MigrationBuilder migrationBuilder) =>
        throw new InvalidOperationException(
            "Rolling back this migration is not supported automatically (NOT NULL UnitId + stored procedures). Restore the database from a backup taken before this migration was applied.");
}
