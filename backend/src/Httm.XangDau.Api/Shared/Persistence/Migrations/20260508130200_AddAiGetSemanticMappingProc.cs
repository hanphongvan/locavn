using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Httm.XangDau.Api.Shared.Persistence.Migrations;

/// <summary>
/// Phase 5B — SP helper <c>sp_Ai_GetSemanticMapping</c> trả mapping + indicator groups
/// cho LLM Plan Generator (Phase 5E+) hoặc admin debug.
/// Section 14.2.3 của <c>docs/loca-ai-phase5.md</c>.
/// Created: 2026-05-08. Dependency: 20260508130100_SeedAiPhase5IndicatorGroup
/// (cần seed data 2 bảng).
/// </summary>
[DbContext(typeof(DmpPortalDbContext))]
[Migration("20260508130200_AddAiGetSemanticMappingProc")]
public sealed class AddAiGetSemanticMappingProc : Migration
{
    /// <inheritdoc />
    protected override void Up(MigrationBuilder migrationBuilder)
    {
        migrationBuilder.Sql(AiGetSemanticMappingProcSql.Create);
    }

    /// <inheritdoc />
    protected override void Down(MigrationBuilder migrationBuilder)
    {
        migrationBuilder.Sql(AiGetSemanticMappingProcSql.Drop);
    }
}
