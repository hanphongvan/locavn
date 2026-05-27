using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Httm.XangDau.Api.Shared.Persistence.Migrations;

/// <summary>HTTM — SP <c>sp_Httm_Survey_GetHistory</c> trả thêm <c>PerformedByName</c> để UI hiển thị tên người thực hiện.</summary>
[DbContext(typeof(DmpPortalDbContext))]
[Migration("20260515110000_HttmSurveyGetHistoryWithUserName")]
public sealed class HttmSurveyGetHistoryWithUserName : Migration
{
    protected override void Up(MigrationBuilder migrationBuilder) =>
        HttmSqlMigrations.Apply(migrationBuilder, "20260515110000_HttmSurvey_GetHistory_WithUserName");

    protected override void Down(MigrationBuilder migrationBuilder)
    {
        // Không có Down — bản trước cũng là CREATE OR ALTER nên rollback chạy lại migration cũ là đủ.
    }
}
