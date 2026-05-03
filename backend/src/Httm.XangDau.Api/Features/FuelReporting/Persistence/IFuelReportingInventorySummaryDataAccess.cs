using Httm.XangDau.Api.Features.FuelReporting.Contracts;

namespace Httm.XangDau.Api.Features.FuelReporting.Persistence;

/// <summary>
/// Dashboard / inventory-summary reads via SQL Server stored procedures only (see <c>docs/architecture/backend.md</c>).
/// </summary>
/// <remarks>
/// <para><b>Audit — APIs using this layer (mobile Dashboard + shared reports)</b></para>
/// <para>— <b>GET /api/reports/overview</b>: stock block via <c>FuelReportingReadService.GetInventorySummaryAsync</c> → <c>dbo.sp_Reports_GetInventorySummary</c> (and <c>dbo.sp_Reports_CheckKieuKyBaoCaoExists</c> when <c>kieuKyBaoCao</c> filter is set).</para>
/// <para>— <b>GET /api/inventory/summary</b>: same stored procedures; contract unchanged.</para>
/// <para><b>Elsewhere (not this interface)</b>: <c>GET /api/my-vehicles</c> uses <c>dbo.sp_UserVehicles_*</c>; greeting is JWT; Dashboard “gợi ý” uses only overview aggregates.</para>
/// </remarks>
public interface IFuelReportingInventorySummaryDataAccess
{
    /// <summary>Calls <c>dbo.sp_Reports_CheckKieuKyBaoCaoExists</c>.</summary>
    Task<bool> KieuKyBaoCaoExistsAsync(int id, CancellationToken cancellationToken = default);

    /// <summary>Calls <c>dbo.sp_Reports_GetInventorySummary</c>; maps result sets to <see cref="InventorySummaryResponseDto"/>.</summary>
    Task<InventorySummaryResponseDto> GetInventorySummaryAsync(int? kieuKyBaoCao, CancellationToken cancellationToken = default);
}
