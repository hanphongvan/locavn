using Httm.XangDau.Api.Shared.Persistence;
using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Httm.XangDau.Api.Shared.Persistence.Migrations;

/// <inheritdoc />
[DbContext(typeof(DmpPortalDbContext))]
[Migration("20260531140000_AddAppSystemSettings")]
public sealed class AddAppSystemSettings : Migration
{
    /// <inheritdoc />
    protected override void Up(MigrationBuilder migrationBuilder)
    {
        migrationBuilder.Sql(AppSystemSettingsSchemaSql.CreateAppSystemSettingsTable);
        migrationBuilder.Sql(AppSystemSettingsSchemaSql.SeedStabilizationFundCutoff);
    }

    /// <inheritdoc />
    protected override void Down(MigrationBuilder migrationBuilder) =>
        migrationBuilder.Sql(AppSystemSettingsSchemaSql.DropAppSystemSettingsTable);
}
