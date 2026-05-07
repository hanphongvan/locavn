using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Httm.XangDau.Api.Shared.Persistence.Migrations;

/// <summary>
/// Phase 2A — chuyển 4 SP <c>sp_Ai_*</c> từ mock VALUES (Phase 1A) sang query bảng thật.
/// Output schema không đổi (Section 11). <c>CREATE OR ALTER</c> nên rerun-safe.
/// </summary>
[DbContext(typeof(DmpPortalDbContext))]
[Migration("20260507120000_UpdateLeaderAiSpsToRealQueries")]
public sealed class UpdateLeaderAiSpsToRealQueries : Migration
{
    /// <inheritdoc />
    protected override void Up(MigrationBuilder migrationBuilder)
    {
        migrationBuilder.Sql(LeaderAiRealQueriesSql.CreateFuelInventorySummary);
        migrationBuilder.Sql(LeaderAiRealQueriesSql.CreateFuelPriceTrend);
        migrationBuilder.Sql(LeaderAiRealQueriesSql.CreateInventoryByHeadOffice);
        migrationBuilder.Sql(LeaderAiRealQueriesSql.CreateStationDensityByProvince);
    }

    /// <inheritdoc />
    protected override void Down(MigrationBuilder migrationBuilder)
    {
        // Khôi phục mock từ Phase 1A.
        migrationBuilder.Sql(LeaderAiFoundationSql.CreateMockProcedures);
        migrationBuilder.Sql(LeaderAiFoundationSql.CreateFuelPriceTrendMock);
        migrationBuilder.Sql(LeaderAiFoundationSql.CreateInventoryByHeadOfficeMock);
        migrationBuilder.Sql(LeaderAiFoundationSql.CreateStationDensityByProvinceMock);
    }
}
