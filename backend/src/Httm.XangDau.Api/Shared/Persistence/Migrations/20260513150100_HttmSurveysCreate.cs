using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Httm.XangDau.Api.Shared.Persistence.Migrations;

/// <summary>HTTM Phase 2 — bảng <c>HttmSurveys</c> + 8 cột JSON (Step1..Step7 + ConfirmerData) + FK có điều kiện sang facility.</summary>
[DbContext(typeof(DmpPortalDbContext))]
[Migration("20260513150100_HttmSurveysCreate")]
public sealed class HttmSurveysCreate : Migration
{
    protected override void Up(MigrationBuilder migrationBuilder) =>
        HttmSqlMigrations.Apply(migrationBuilder, "20260513150100_HttmSurveys_Create");

    protected override void Down(MigrationBuilder migrationBuilder)
    {
        // Manual rollback: DROP TABLE dbo.HttmSurveys;
    }
}
