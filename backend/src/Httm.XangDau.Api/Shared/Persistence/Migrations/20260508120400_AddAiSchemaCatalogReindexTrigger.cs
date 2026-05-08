using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Httm.XangDau.Api.Shared.Persistence.Migrations;

/// <summary>
/// Phase 5A — Trigger enqueue Qdrant re-index khi <c>AiSchemaCatalog</c> thay đổi.
/// Section 13A.3 của <c>docs/loca-ai-phase5.md</c>.
/// Created: 2026-05-08. Dependency: 20260508120000_AddAiPhase5Tables (cần AiSchemaCatalog + AiReindexQueue).
/// </summary>
[DbContext(typeof(DmpPortalDbContext))]
[Migration("20260508120400_AddAiSchemaCatalogReindexTrigger")]
public sealed class AddAiSchemaCatalogReindexTrigger : Migration
{
    /// <inheritdoc />
    protected override void Up(MigrationBuilder migrationBuilder)
    {
        migrationBuilder.Sql(AiReindexTriggerSql.TR_AiSchemaCatalog_AfterUpsert);
    }

    /// <inheritdoc />
    protected override void Down(MigrationBuilder migrationBuilder)
    {
        migrationBuilder.Sql(AiReindexTriggerSql.Drop);
    }
}
