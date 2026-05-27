using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Httm.XangDau.Api.Shared.Persistence.Migrations;

/// <summary>HTTM Phase 2 — bảng <c>HttmSurveyCounters</c> sinh mã KS-{YEAR}-{PROVINCE}-{SEQ}.</summary>
[DbContext(typeof(DmpPortalDbContext))]
[Migration("20260513150000_HttmSurveyCountersCreate")]
public sealed class HttmSurveyCountersCreate : Migration
{
    protected override void Up(MigrationBuilder migrationBuilder) =>
        HttmSqlMigrations.Apply(migrationBuilder, "20260513150000_HttmSurveyCounters_Create");

    protected override void Down(MigrationBuilder migrationBuilder)
    {
        // Manual rollback: DROP TABLE dbo.HttmSurveyCounters;
    }
}
