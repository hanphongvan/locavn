using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Httm.XangDau.Api.Shared.Persistence.Migrations;

/// <summary>HTTM Phase 2 — bảng <c>HttmSurveyHistories</c> (audit phiếu khảo sát: create/save/submit/approve/reject/reopen).</summary>
[DbContext(typeof(DmpPortalDbContext))]
[Migration("20260513150200_HttmSurveyHistoriesCreate")]
public sealed class HttmSurveyHistoriesCreate : Migration
{
    protected override void Up(MigrationBuilder migrationBuilder) =>
        HttmSqlMigrations.Apply(migrationBuilder, "20260513150200_HttmSurveyHistories_Create");

    protected override void Down(MigrationBuilder migrationBuilder)
    {
        // Manual rollback: DROP TABLE dbo.HttmSurveyHistories;
    }
}
