using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Httm.XangDau.Api.Shared.Persistence.Migrations;

/// <summary>HTTM Phase 2 — analytics SPs + bảng/SP <c>HttmReportTemplates</c> (báo cáo định kỳ + worker nhắc nộp).</summary>
[DbContext(typeof(DmpPortalDbContext))]
[Migration("20260514100000_HttmPhase2AnalyticsAndReportTemplates")]
public sealed class HttmPhase2AnalyticsAndReportTemplates : Migration
{
    protected override void Up(MigrationBuilder migrationBuilder) =>
        HttmSqlMigrations.Apply(migrationBuilder, "20260514100000_HttmPhase2_AnalyticsAndReportTemplates");

    protected override void Down(MigrationBuilder migrationBuilder)
    {
        // Manual rollback: DROP TABLE dbo.HttmReportTemplates; DROP PROCEDURE dbo.sp_HttmAnalytics_*;
    }
}
