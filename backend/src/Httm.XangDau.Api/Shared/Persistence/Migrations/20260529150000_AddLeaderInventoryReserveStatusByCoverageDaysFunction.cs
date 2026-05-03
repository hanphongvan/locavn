using Httm.XangDau.Api.Shared.Persistence;
using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Httm.XangDau.Api.Shared.Persistence.Migrations;

/// <inheritdoc />
[DbContext(typeof(DmpPortalDbContext))]
[Migration("20260529150000_AddLeaderInventoryReserveStatusByCoverageDaysFunction")]
public sealed class AddLeaderInventoryReserveStatusByCoverageDaysFunction : Migration
{
    /// <inheritdoc />
    protected override void Up(MigrationBuilder migrationBuilder) =>
        migrationBuilder.Sql(LeaderInventoryReserveStatusSql.CreateInventoryReserveStatusByCoverageDaysFunction);

    /// <inheritdoc />
    protected override void Down(MigrationBuilder migrationBuilder) =>
        migrationBuilder.Sql(LeaderInventoryReserveStatusSql.DropInventoryReserveStatusByCoverageDaysFunction);
}
