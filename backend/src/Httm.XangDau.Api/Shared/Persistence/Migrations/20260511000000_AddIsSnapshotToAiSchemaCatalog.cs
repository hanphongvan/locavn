using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Httm.XangDau.Api.Shared.Persistence.Migrations;

/// <summary>
/// Phase 5H step 1 — thêm cột <c>IsSnapshot</c> vào <c>AiSchemaCatalog</c> +
/// set <c>1</c> cho <c>head_office_fund_balance</c>. Mục đích: AI Gateway
/// (Schema Retriever / Plan Generator / SqlBuilder) phân biệt snapshot vs
/// flow để tự filter kỳ gần nhất khi user không nhắc tháng.
///
/// Created: 2026-05-11. Dependency:
/// - 20260508140000_SeedAiPhase5SchemaCatalog (cần entity head_office_fund_balance đã seed).
/// - Trigger TR_AiSchemaCatalog_AfterUpsert sẽ enqueue AiReindexQueue → Phase 5G
///   Python worker auto re-embed Qdrant (snapshot flag không ảnh hưởng embedding
///   text nhưng vẫn re-publish để snapshot timestamp đồng bộ).
/// </summary>
[DbContext(typeof(DmpPortalDbContext))]
[Migration("20260511000000_AddIsSnapshotToAiSchemaCatalog")]
public sealed class AddIsSnapshotToAiSchemaCatalog : Migration
{
    /// <inheritdoc />
    protected override void Up(MigrationBuilder migrationBuilder)
    {
        migrationBuilder.Sql(AiPhase5HSnapshotFlagSql.Up);
    }

    /// <inheritdoc />
    protected override void Down(MigrationBuilder migrationBuilder)
    {
        migrationBuilder.Sql(AiPhase5HSnapshotFlagSql.Down);
    }
}
