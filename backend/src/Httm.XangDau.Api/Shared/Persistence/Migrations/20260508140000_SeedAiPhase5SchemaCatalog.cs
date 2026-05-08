using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Httm.XangDau.Api.Shared.Persistence.Migrations;

/// <summary>
/// Phase 5C — Seed <c>AiSchemaCatalog</c> với 8 entity AI được phép truy vấn.
/// Section 8 của <c>docs/loca-ai-phase5.md</c>.
/// Created: 2026-05-08. Dependency: 20260508120000_AddAiPhase5Tables (cần bảng AiSchemaCatalog
/// + trigger TR_AiSchemaCatalog_AfterUpsert đã tạo Phase 5A để enqueue Qdrant re-index).
///
/// Mỗi INSERT fire trigger TR_AiSchemaCatalog_AfterUpsert → 8 row pending vào AiReindexQueue
/// để worker Python (Phase 5D) embed sample questions + description vào Qdrant.
/// </summary>
[DbContext(typeof(DmpPortalDbContext))]
[Migration("20260508140000_SeedAiPhase5SchemaCatalog")]
public sealed class SeedAiPhase5SchemaCatalog : Migration
{
    /// <inheritdoc />
    protected override void Up(MigrationBuilder migrationBuilder)
    {
        migrationBuilder.Sql(AiPhase5SeedSchemaCatalogSql.Seed);
    }

    /// <inheritdoc />
    protected override void Down(MigrationBuilder migrationBuilder)
    {
        migrationBuilder.Sql(AiPhase5SeedSchemaCatalogSql.Unseed);
    }
}
