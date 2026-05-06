using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Httm.XangDau.Api.Shared.Persistence.Migrations;

/// <summary>
/// Phase 1A — Loca AI Leader Assistant Foundation: tạo 8 bảng <c>Ai*</c>,
/// seed 12 intent vào <c>AiIntentConfigs</c>, và 4 stored procedure mock.
/// Schema theo <c>docs/loca-ai-leader-v2.md</c> (Section 3 + 11).
/// </summary>
[DbContext(typeof(DmpPortalDbContext))]
[Migration("20260506120000_AddLeaderAiFoundationTables")]
public sealed class AddLeaderAiFoundationTables : Migration
{
    /// <inheritdoc />
    protected override void Up(MigrationBuilder migrationBuilder)
    {
        migrationBuilder.Sql(LeaderAiFoundationSql.CreateTables);
        migrationBuilder.Sql(LeaderAiFoundationSql.SeedIntents);
        migrationBuilder.Sql(LeaderAiFoundationSql.CreateMockProcedures);
        migrationBuilder.Sql(LeaderAiFoundationSql.CreateFuelPriceTrendMock);
        migrationBuilder.Sql(LeaderAiFoundationSql.CreateInventoryByHeadOfficeMock);
        migrationBuilder.Sql(LeaderAiFoundationSql.CreateStationDensityByProvinceMock);
    }

    /// <inheritdoc />
    protected override void Down(MigrationBuilder migrationBuilder)
    {
        migrationBuilder.Sql(LeaderAiFoundationSql.DropMockProcedures);
        migrationBuilder.Sql(LeaderAiFoundationSql.DropTables);
    }
}
