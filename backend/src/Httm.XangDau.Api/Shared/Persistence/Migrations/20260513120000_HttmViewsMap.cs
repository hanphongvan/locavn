using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Httm.XangDau.Api.Shared.Persistence.Migrations;

/// <summary>HTTM Phase 1 — view <c>vw_HttmFacility_Map</c> (chiếu Lat/Lng từ GEOGRAPHY).</summary>
[DbContext(typeof(DmpPortalDbContext))]
[Migration("20260513120000_HttmViewsMap")]
public sealed class HttmViewsMap : Migration
{
    protected override void Up(MigrationBuilder migrationBuilder) =>
        HttmSqlMigrations.Apply(migrationBuilder, "20260513120000_HttmViews_Map");

    protected override void Down(MigrationBuilder migrationBuilder)
    {
        // Manual rollback: DROP VIEW dbo.vw_HttmFacility_Map;
    }
}
