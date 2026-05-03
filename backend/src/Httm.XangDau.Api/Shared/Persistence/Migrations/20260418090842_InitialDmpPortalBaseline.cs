using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Httm.XangDau.Api.Shared.Persistence.Migrations;

/// <summary>
/// Baseline migration for an existing DMPPortal database: <see cref="Up"/> applies no DDL so
/// <c>Database.Migrate()</c> only records history on legacy installs. On an empty database,
/// <c>dbo.DM_DonVi</c> is created when the first migration that needs it runs (see
/// <c>AddStationOperatingHours</c>). Incremental app-owned tables belong in later migrations.
/// </summary>
public partial class InitialDmpPortalBaseline : Migration
{
    protected override void Up(MigrationBuilder migrationBuilder)
    {
    }

    protected override void Down(MigrationBuilder migrationBuilder)
    {
    }
}
