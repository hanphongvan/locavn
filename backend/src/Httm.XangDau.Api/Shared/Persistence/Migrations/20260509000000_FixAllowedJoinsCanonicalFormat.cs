using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Httm.XangDau.Api.Shared.Persistence.Migrations;

/// <summary>
/// Phase 5F — Fix TECH-DEBT-5E-001: chuẩn hoá <c>AiSchemaCatalog.AllowedJoinsJson</c>
/// từ format ngắn <c>{view, key}</c> (Phase 5C seed) sang canonical 5-field
/// <c>{targetEntity, onLeftColumn, onRightColumn, joinType}</c> khớp
/// <c>QueryPlan.JoinClause</c> Pydantic schema.
///
/// Created: 2026-05-09. Dependency: 20260508140000_SeedAiPhase5SchemaCatalog
/// (cần data Phase 5C đã seed).
/// </summary>
[DbContext(typeof(DmpPortalDbContext))]
[Migration("20260509000000_FixAllowedJoinsCanonicalFormat")]
public sealed class FixAllowedJoinsCanonicalFormat : Migration
{
    /// <inheritdoc />
    protected override void Up(MigrationBuilder migrationBuilder)
    {
        migrationBuilder.Sql(AiPhase5FFixAllowedJoinsSql.Up);
    }

    /// <inheritdoc />
    protected override void Down(MigrationBuilder migrationBuilder)
    {
        migrationBuilder.Sql(AiPhase5FFixAllowedJoinsSql.Down);
    }
}
