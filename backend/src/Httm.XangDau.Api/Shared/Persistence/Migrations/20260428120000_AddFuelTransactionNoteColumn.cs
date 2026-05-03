using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Httm.XangDau.Api.Shared.Persistence.Migrations;

/// <inheritdoc />
public partial class AddFuelTransactionNoteColumn : Migration
{
    /// <inheritdoc />
    protected override void Up(MigrationBuilder migrationBuilder)
    {
        migrationBuilder.Sql(FuelTransactionsNoteMigrationSql.AddNoteColumnIfMissing);
        migrationBuilder.Sql(FuelStoredProceduresSql.TransactionInsert);
    }

    /// <inheritdoc />
    protected override void Down(MigrationBuilder migrationBuilder)
    {
        // Khôi phục SP/cột cũ cần bản SQL riêng; giữ trống để tránh DB downgrade lỗi thứ tự.
    }
}
