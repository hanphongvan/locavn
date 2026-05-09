using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Httm.XangDau.Api.Shared.Persistence.Migrations;

/// <summary>
/// Phase 5G refinement — append 4 câu hỏi khẩu ngữ vào
/// <c>SampleQuestionsJson</c> của <c>head_office_inventory</c> +
/// <c>head_office_fund_balance</c>. Mục đích: bge-m3 embed match cao hơn
/// cho user câu kiểu "Còn bao nhiêu...", "Tồn ... còn lại...".
///
/// Created: 2026-05-10. Dependency:
/// - 20260508140000_SeedAiPhase5SchemaCatalog (cần data Phase 5C đã seed).
/// - Trigger <c>TR_AiSchemaCatalog_AfterUpsert</c> (Phase 5A) sẽ enqueue
///   AiReindexQueue → Phase 5G Python worker auto re-embed Qdrant.
/// </summary>
[DbContext(typeof(DmpPortalDbContext))]
[Migration("20260510010000_AppendColloquialSampleQuestions")]
public sealed class AppendColloquialSampleQuestions : Migration
{
    /// <inheritdoc />
    protected override void Up(MigrationBuilder migrationBuilder)
    {
        migrationBuilder.Sql(AiPhase5GColloquialSampleSql.Up);
    }

    /// <inheritdoc />
    protected override void Down(MigrationBuilder migrationBuilder)
    {
        migrationBuilder.Sql(AiPhase5GColloquialSampleSql.Down);
    }
}
