using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Httm.XangDau.Api.Shared.Persistence.Migrations;

/// <summary>
/// Phase 5G — tạo bảng <c>AiIntentConfigs</c> lưu intent code admin đã promote
/// từ <c>AiCandidateIntents</c>. Section 12.2 của <c>docs/loca-ai-phase5.md</c>.
///
/// Created: 2026-05-10. Dependency: 20260508120000_AddAiPhase5Tables (cần
/// AiCandidateIntents đã tồn tại để FK <c>SourceCandidateId</c> trỏ đến).
/// </summary>
[DbContext(typeof(DmpPortalDbContext))]
[Migration("20260510000000_AddAiIntentConfigsTable")]
public sealed class AddAiIntentConfigsTable : Migration
{
    /// <inheritdoc />
    protected override void Up(MigrationBuilder migrationBuilder)
    {
        migrationBuilder.Sql(AiPhase5GIntentConfigsSql.Up);
    }

    /// <inheritdoc />
    protected override void Down(MigrationBuilder migrationBuilder)
    {
        migrationBuilder.Sql(AiPhase5GIntentConfigsSql.Down);
    }
}
