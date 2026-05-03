using Httm.XangDau.Api.Shared.Persistence;
using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Httm.XangDau.Api.Shared.Persistence.Migrations;

/// <summary>
/// Gỡ bảng <c>PetroleumStabilizationFundReports</c> và các <c>sp_Leader_StabilizationFund_*</c> nếu còn sót từ bản build cũ.
/// Quỹ bình ổn API chỉ đọc <c>dbo.sp_Dashboard_FuelStabilizationFund</c> (BC08).
/// </summary>
[DbContext(typeof(DmpPortalDbContext))]
[Migration("20260531120000_DropPetroleumStabilizationFundLeaderArtifacts")]
public sealed class DropPetroleumStabilizationFundLeaderArtifacts : Migration
{
    /// <inheritdoc />
    protected override void Up(MigrationBuilder migrationBuilder) =>
        migrationBuilder.Sql(
            """
            DROP PROCEDURE IF EXISTS dbo.sp_Leader_StabilizationFund_DistributorHistory;
            DROP PROCEDURE IF EXISTS dbo.sp_Leader_StabilizationFund_Distributors;
            DROP PROCEDURE IF EXISTS dbo.sp_Leader_StabilizationFund_Summary;
            DROP TABLE IF EXISTS dbo.PetroleumStabilizationFundReports;
            """);

    /// <inheritdoc />
    protected override void Down(MigrationBuilder migrationBuilder)
    {
    }
}
