using Httm.XangDau.Api.Features.Leader.Contracts;
using Httm.XangDau.Api.Features.Leader.Persistence;

namespace Httm.XangDau.Api.Features.Leader.Services;

/// <summary>
/// Orchestrate dashboard Leader Retail: SP raw → <see cref="LeaderRetailWarningRules"/> → response.
/// </summary>
public sealed class LeaderRetailService(ILeaderRetailDataAccess dataAccess) : ILeaderRetailService
{
    /// <inheritdoc />
    public async Task<LeaderRetailDashboardResponse> GetDashboardAsync(
        int? provinceId,
        bool? status,
        int? managingUnitId,
        CancellationToken cancellationToken = default)
    {
        var data = await dataAccess
            .GetDashboardAsync(provinceId, status, managingUnitId, cancellationToken)
            .ConfigureAwait(false);

        var warnings = LeaderRetailWarningRules.Evaluate(
            data.Stations,
            data.Provinces,
            DateTime.UtcNow);

        return new LeaderRetailDashboardResponse(
            data.Kpi,
            data.Provinces,
            warnings);
    }

    /// <inheritdoc />
    public async Task<LeaderRetailManagingUnitsResponse> GetManagingUnitsAsync(
        CancellationToken cancellationToken = default)
    {
        var items = await dataAccess.GetManagingUnitsAsync(cancellationToken).ConfigureAwait(false);
        return new LeaderRetailManagingUnitsResponse(items);
    }

    /// <inheritdoc />
    public async Task<LeaderRetailProvincesResponse> GetProvincesAsync(
        CancellationToken cancellationToken = default)
    {
        var items = await dataAccess.GetProvincesAsync(cancellationToken).ConfigureAwait(false);
        return new LeaderRetailProvincesResponse(items);
    }
}
