using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Httm.XangDau.Api.Shared.Persistence.Migrations;

/// <summary>HTTM Phase 1 — seed cấu hình map provider vào <c>dbo.AppSystemSettings</c> (provider, goong_api_key, default center/zoom).</summary>
[DbContext(typeof(DmpPortalDbContext))]
[Migration("20260513122002_HttmAppSystemSettingsMap")]
public sealed class HttmAppSystemSettingsMap : Migration
{
    protected override void Up(MigrationBuilder migrationBuilder) =>
        HttmSqlMigrations.Apply(migrationBuilder, "20260513122002_HttmAppSystemSettings_Map");

    protected override void Down(MigrationBuilder migrationBuilder)
    {
        // Manual rollback: DELETE FROM dbo.AppSystemSettings WHERE [Key] LIKE 'httm.map.%';
    }
}
