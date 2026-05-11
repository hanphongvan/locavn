using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Httm.XangDau.Api.Shared.Persistence.Migrations;

/// <summary>
/// Phase 5A — 5 trigger cache invalidation: bump <c>AiDataVersion.Version</c> khi nguồn dữ liệu đổi.
/// Section 10A.3 của <c>docs/loca-ai-phase5.md</c>.
/// Created: 2026-05-08. Dependency: 20260508120100_SeedAiPhase5BaoCaoConstants (cần AiDataVersion seeded).
/// Mỗi <c>CREATE OR ALTER TRIGGER</c> là batch riêng — gọi <c>migrationBuilder.Sql</c> từng cái.
/// </summary>
[DbContext(typeof(DmpPortalDbContext))]
[Migration("20260508120300_AddAiCacheInvalidationTriggers")]
public sealed class AddAiCacheInvalidationTriggers : Migration
{
    /// <inheritdoc />
    protected override void Up(MigrationBuilder migrationBuilder)
    {
        migrationBuilder.Sql(AiCacheInvalidationTriggersSql.TR_QT_TK_ThongKe_AfterUpdate);
        migrationBuilder.Sql(AiCacheInvalidationTriggersSql.TR_StationPrices_AfterUpsert);
        migrationBuilder.Sql(AiCacheInvalidationTriggersSql.TR_StationProductPrices_AfterUpsert);
        migrationBuilder.Sql(AiCacheInvalidationTriggersSql.TR_StationInventoryTransactionHeaders_AfterUpsert);
        migrationBuilder.Sql(AiCacheInvalidationTriggersSql.TR_StationRatings_AfterUpsert);
    }

    /// <inheritdoc />
    protected override void Down(MigrationBuilder migrationBuilder)
    {
        migrationBuilder.Sql(AiCacheInvalidationTriggersSql.DropAll);
    }
}
