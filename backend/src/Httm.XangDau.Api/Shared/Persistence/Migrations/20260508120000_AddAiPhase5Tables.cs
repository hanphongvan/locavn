using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Httm.XangDau.Api.Shared.Persistence.Migrations;

/// <summary>
/// Phase 5A — Database Foundation cho Schema-Aware Constrained Query Generation.
/// 11 bảng metadata + index. Section 5 + 5.7 + 5.8 + 10A.3 + 13A.1 + 13A.3 + 13A.6
/// của <c>docs/loca-ai-phase5.md</c>.
/// Created: 2026-05-08. Dependency: Phase 1A baseline (LeaderAiFoundationSql) đã apply.
/// </summary>
[DbContext(typeof(DmpPortalDbContext))]
[Migration("20260508120000_AddAiPhase5Tables")]
public sealed class AddAiPhase5Tables : Migration
{
    /// <inheritdoc />
    protected override void Up(MigrationBuilder migrationBuilder)
    {
        migrationBuilder.Sql(AiPhase5SchemaSql.Tables);
    }

    /// <inheritdoc />
    protected override void Down(MigrationBuilder migrationBuilder)
    {
        migrationBuilder.Sql(AiPhase5SchemaSql.DropTables);
    }
}
