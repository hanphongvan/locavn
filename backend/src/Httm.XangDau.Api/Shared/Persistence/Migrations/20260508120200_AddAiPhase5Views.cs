using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Httm.XangDau.Api.Shared.Persistence.Migrations;

/// <summary>
/// Phase 5A — 8 view AI tiền xử lý EAV thành cột nghiệp vụ.
/// Section 7 của <c>docs/loca-ai-phase5.md</c>.
/// Created: 2026-05-08. Dependency: 20260508120100_SeedAiPhase5BaoCaoConstants.
/// Mỗi <c>CREATE OR ALTER VIEW</c> phải là statement đầu của batch — nên gọi
/// <c>migrationBuilder.Sql</c> riêng cho mỗi view.
/// </summary>
[DbContext(typeof(DmpPortalDbContext))]
[Migration("20260508120200_AddAiPhase5Views")]
public sealed class AddAiPhase5Views : Migration
{
    /// <inheritdoc />
    protected override void Up(MigrationBuilder migrationBuilder)
    {
        migrationBuilder.Sql(AiPhase5ViewsSql.HeadOfficeInventory);
        migrationBuilder.Sql(AiPhase5ViewsSql.HeadOfficePrice);
        migrationBuilder.Sql(AiPhase5ViewsSql.HeadOfficeFundBalance);
        migrationBuilder.Sql(AiPhase5ViewsSql.HeadOfficeImport);
        migrationBuilder.Sql(AiPhase5ViewsSql.HeadOfficeDomesticSupply);
        migrationBuilder.Sql(AiPhase5ViewsSql.StationPrice);
        migrationBuilder.Sql(AiPhase5ViewsSql.StationInventory);
        migrationBuilder.Sql(AiPhase5ViewsSql.StationRating);
    }

    /// <inheritdoc />
    protected override void Down(MigrationBuilder migrationBuilder)
    {
        migrationBuilder.Sql(AiPhase5ViewsSql.DropAllViews);
    }
}
