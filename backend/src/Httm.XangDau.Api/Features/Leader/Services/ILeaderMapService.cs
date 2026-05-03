using System.Security.Claims;
using Httm.XangDau.Api.Features.Leader.Contracts;

namespace Httm.XangDau.Api.Features.Leader.Services;

public interface ILeaderMapService
{
    Task<LeaderMapDistributorsResponse> GetDistributorsAsync(ClaimsPrincipal user, CancellationToken cancellationToken = default);

    Task<(LeaderMapDistributorInventoryResponse? Data, bool NotFound)> GetDistributorInventoryAsync(
        int donViId,
        ClaimsPrincipal user,
        CancellationToken cancellationToken = default);

    Task<LeaderHomeInventorySummaryResponse> GetInventorySummaryAsync(
        ClaimsPrincipal user,
        CancellationToken cancellationToken = default);

    Task<LeaderMapPricesResponse> GetPricesAsync(IReadOnlyList<int> stationIds, CancellationToken cancellationToken = default);

    Task<LeaderMapViolationsResponse> GetViolationsAsync(int stationId, CancellationToken cancellationToken = default);
}
