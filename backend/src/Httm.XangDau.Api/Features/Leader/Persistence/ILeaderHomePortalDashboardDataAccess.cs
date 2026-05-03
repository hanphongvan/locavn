using Httm.XangDau.Api.Features.Leader.Contracts;

namespace Httm.XangDau.Api.Features.Leader.Persistence;

/// <summary>Legacy DMPPortal home dashboard stored procedures (gasoline + oil; Khí rows filtered out when present).</summary>
public interface ILeaderHomePortalDashboardDataAccess
{
    Task<LeaderHomeInventorySummaryResponse> GetInventorySummaryAsync(
        LeaderHomeDashboardRequest request,
        CancellationToken cancellationToken = default);

    Task<LeaderHomeNationalStockMovementResponse> GetNationalStockMovementAsync(
        LeaderHomeDashboardRequest request,
        CancellationToken cancellationToken = default);

    Task<LeaderHomePriceSummaryResponse> GetPriceSummaryAsync(
        LeaderHomeDashboardRequest request,
        CancellationToken cancellationToken = default);

    Task<LeaderHomeDistributorMapResponse> GetDistributorMapAsync(
        LeaderHomeDistributorMapRequest request,
        CancellationToken cancellationToken = default);

    /// <summary>
    /// <paramref name="fuelType"/>: <c>gasoline</c> (Xăng) hoặc <c>oil</c> (Dầu) — không Khí.
    /// <paramref name="statusGroup"/>: <c>all</c> | <c>safe</c> | <c>warning</c> | <c>critical</c> (lọc theo mã trạng thái từ SQL).
    /// </summary>
    Task<LeaderInventoryDetailResponse> GetInventoryDetailAsync(
        LeaderHomeDashboardRequest request,
        string fuelType,
        string? statusGroup,
        CancellationToken cancellationToken = default);
}
