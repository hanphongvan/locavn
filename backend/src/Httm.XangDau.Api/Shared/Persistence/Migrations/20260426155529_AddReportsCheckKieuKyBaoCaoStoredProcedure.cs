using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Httm.XangDau.Api.Shared.Persistence.Migrations
{
    /// <inheritdoc />
    public partial class AddReportsCheckKieuKyBaoCaoStoredProcedure : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.Sql(ReportsStoredProcedures.CheckKieuKyBaoCaoExists);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.Sql(
                """
                IF OBJECT_ID(N'dbo.sp_Reports_CheckKieuKyBaoCaoExists', N'P') IS NOT NULL
                    DROP PROCEDURE dbo.sp_Reports_CheckKieuKyBaoCaoExists;
                """);
        }
    }
}
