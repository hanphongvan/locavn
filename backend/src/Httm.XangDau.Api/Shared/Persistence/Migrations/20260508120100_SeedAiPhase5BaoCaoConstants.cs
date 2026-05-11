using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Httm.XangDau.Api.Shared.Persistence.Migrations;

/// <summary>
/// Phase 5A — Seed <c>AiBaoCaoConstants</c> (4 báo cáo cố định) + <c>AiDataVersion</c>
/// (7 BaoCaoCode khởi tạo). Section 5.3 + 10A.3 của <c>docs/loca-ai-phase5.md</c>.
/// Created: 2026-05-08. Dependency: 20260508120000_AddAiPhase5Tables.
/// </summary>
[DbContext(typeof(DmpPortalDbContext))]
[Migration("20260508120100_SeedAiPhase5BaoCaoConstants")]
public sealed class SeedAiPhase5BaoCaoConstants : Migration
{
    /// <inheritdoc />
    protected override void Up(MigrationBuilder migrationBuilder)
    {
        migrationBuilder.Sql(AiPhase5SeedConstantsSql.SeedBaoCaoConstants);
        migrationBuilder.Sql(AiPhase5SeedConstantsSql.SeedDataVersion);
    }

    /// <inheritdoc />
    protected override void Down(MigrationBuilder migrationBuilder)
    {
        migrationBuilder.Sql(AiPhase5SeedConstantsSql.Unseed);
    }
}
