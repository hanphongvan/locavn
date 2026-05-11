using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Httm.XangDau.Api.Shared.Persistence.Migrations;

/// <summary>
/// Phase 5B — Seed <c>AiSemanticMapping</c> với 7 records ĐÃ CONFIRM với business.
/// Section 6.1 + 6.2 + 6.3 + 6.4 của <c>docs/loca-ai-phase5.md</c>.
/// Created: 2026-05-08. Dependency: 20260508120000_AddAiPhase5Tables (cần bảng AiSemanticMapping).
///
/// KHÔNG seed composite components (So_05/06/07, So_11/12/13/24) — composite đã hardcode
/// trong vw_AiHeadOfficeInventory; AI làm việc qua VIEW nên không cần biết thành phần lẻ.
/// </summary>
[DbContext(typeof(DmpPortalDbContext))]
[Migration("20260508130000_SeedAiPhase5SemanticMapping")]
public sealed class SeedAiPhase5SemanticMapping : Migration
{
    /// <inheritdoc />
    protected override void Up(MigrationBuilder migrationBuilder)
    {
        migrationBuilder.Sql(AiPhase5SeedSemanticMappingSql.Seed);
    }

    /// <inheritdoc />
    protected override void Down(MigrationBuilder migrationBuilder)
    {
        migrationBuilder.Sql(AiPhase5SeedSemanticMappingSql.Unseed);
    }
}
