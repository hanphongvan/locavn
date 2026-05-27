using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Httm.XangDau.Api.Shared.Persistence.Migrations;

/// <summary>HTTM Phase 1 — view <c>vw_HttmStats_ByProvince</c> (thống kê tổng hợp cho dashboard).</summary>
[DbContext(typeof(DmpPortalDbContext))]
[Migration("20260513120001_HttmViewsStatsByProvince")]
public sealed class HttmViewsStatsByProvince : Migration
{
    protected override void Up(MigrationBuilder migrationBuilder) =>
        HttmSqlMigrations.Apply(migrationBuilder, "20260513120001_HttmViews_StatsByProvince");

    protected override void Down(MigrationBuilder migrationBuilder)
    {
        // Manual rollback: DROP VIEW dbo.vw_HttmStats_ByProvince;
    }
}
