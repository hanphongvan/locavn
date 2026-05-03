using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Httm.XangDau.Api.Shared.Persistence.Migrations
{
    /// <inheritdoc />
    public partial class AddStoreAdminInventoryMapStoredProcedure : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.Sql(InventoryMapStoredProcedures.ListByGroupCode);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.Sql(
                """
                IF OBJECT_ID(N'dbo.sp_StoreAdmin_InventoryMap_ListByGroupCode', N'P') IS NOT NULL
                    DROP PROCEDURE dbo.sp_StoreAdmin_InventoryMap_ListByGroupCode;
                """);
        }
    }
}
