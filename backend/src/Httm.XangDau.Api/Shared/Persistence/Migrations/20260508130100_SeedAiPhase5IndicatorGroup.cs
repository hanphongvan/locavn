using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Httm.XangDau.Api.Shared.Persistence.Migrations;

/// <summary>
/// Phase 5B — Seed <c>AiIndicatorGroup</c> với 6 group head_office đã confirm.
/// Section 6.5 của <c>docs/loca-ai-phase5.md</c>.
/// Created: 2026-05-08. Dependency: 20260508120000_AddAiPhase5Tables (cần bảng AiIndicatorGroup).
/// SKIP retail station groups (Section 6.6) vì FuelProducts.Code chưa verify với business.
/// </summary>
[DbContext(typeof(DmpPortalDbContext))]
[Migration("20260508130100_SeedAiPhase5IndicatorGroup")]
public sealed class SeedAiPhase5IndicatorGroup : Migration
{
    /// <inheritdoc />
    protected override void Up(MigrationBuilder migrationBuilder)
    {
        migrationBuilder.Sql(AiPhase5SeedIndicatorGroupSql.Seed);
    }

    /// <inheritdoc />
    protected override void Down(MigrationBuilder migrationBuilder)
    {
        migrationBuilder.Sql(AiPhase5SeedIndicatorGroupSql.Unseed);
    }
}
