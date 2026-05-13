using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Httm.XangDau.Api.Shared.Persistence.Migrations;

/// <summary>
/// Phase 5J — optimize <c>sp_Ai_GetFuelInventorySummary</c> để giảm thời gian
/// execute từ ~10-15s (cold) xuống ~2-4s.
/// </summary>
/// <remarks>
/// <para>Vấn đề bản cũ (Phase 2A bugfix v2):</para>
/// <list type="number">
///   <item><description><b>CTE <c>BaseData</c> bị scan 2 lần</b>: <c>Curr</c> + <c>Prev</c>
///     đều SELECT từ CTE, SQL Server KHÔNG materialize → optimizer re-execute toàn bộ
///     JOIN 4-bảng × 2.</description></item>
///   <item><description><b>OR predicate chéo cột</b>:
///     <c>((Nam=@Nam AND ThangQuy=@Thang) OR (Nam=@NamTruoc AND ThangQuy=@ThangTruoc))</c>
///     thường khiến optimizer fallback scan thay vì 2 index seek.</description></item>
///   <item><description><b>JOIN <c>DM_DonVi</c> chỉ để filter <c>CapDonViId=235</c></b>:
///     forced cho mọi row của BaseData.</description></item>
/// </list>
/// <para>Optimize:</para>
/// <list type="bullet">
///   <item><description>Pre-filter <c>DM_DonVi</c> vào table variable <c>@DonViIds</c> (≤ vài chục rows)
///     → thay JOIN bằng <c>EXISTS</c>.</description></item>
///   <item><description><c>SELECT INTO #BaseData</c> + <c>UNION ALL</c> 2 cặp <c>(Nam, ThangQuy)</c>
///     → materialize 1 lần, mỗi nhánh dùng index seek riêng (eliminate OR pattern).</description></item>
///   <item><description><c>CREATE CLUSTERED INDEX</c> trên <c>#BaseData (Nam, ThangQuy, FuelGroup)</c>
///     → 2 GROUP BY sau đó dùng index scan thay vì hash aggregate.</description></item>
/// </list>
/// <para>Verify: chạy SP cũ vs mới với cùng input, output phải IDENTICAL
/// (cùng tập cột, cùng giá trị Xăng/Dầu × TonCuoi/PreviousPeriodStock/ChangePercent/...).</para>
/// </remarks>
[DbContext(typeof(DmpPortalDbContext))]
[Migration("20260602100000_OptimizeFuelInventorySummary")]
public sealed class OptimizeFuelInventorySummary : Migration
{
    /// <inheritdoc />
    protected override void Up(MigrationBuilder migrationBuilder)
    {
        // CREATE OR ALTER — idempotent, apply được cả trên DB cũ và DB mới.
        migrationBuilder.Sql(LeaderAiDashboardPatternSql.CreateFuelInventorySummary);
    }

    /// <inheritdoc />
    protected override void Down(MigrationBuilder migrationBuilder)
    {
        // Down() không khả thi trực tiếp vì constant đã chuyển sang version optimize.
        // Khôi phục: revert thủ công LeaderAiDashboardPatternSql.CreateFuelInventorySummary
        // về version Phase 2A bugfix v2 (CTE BaseData + OR predicate) trước khi rollback.
    }
}
