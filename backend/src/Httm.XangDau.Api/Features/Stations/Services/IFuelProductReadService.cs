using Httm.XangDau.Api.Features.Stations.Contracts;

namespace Httm.XangDau.Api.Features.Stations.Services;

/// <summary>Public read API for the <c>FuelProducts</c> catalog used by mobile map filter.</summary>
public interface IFuelProductReadService
{
    /// <summary>
    /// Active leaves (nodes that do not appear as <c>ParentId</c> of any row) ordered by <c>SortOrder</c>.
    /// </summary>
    Task<IReadOnlyList<FuelProductLeafDto>> GetActiveLeavesAsync(CancellationToken cancellationToken = default);
}
