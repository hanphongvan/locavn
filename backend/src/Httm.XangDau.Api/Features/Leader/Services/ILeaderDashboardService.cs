using Httm.XangDau.Api.Features.Leader.Contracts;

namespace Httm.XangDau.Api.Features.Leader.Services;

/// <summary>Aggregates leader dashboard reads (gasoline + oil only; no gas).</summary>
public interface ILeaderDashboardService
{
    /// <summary>Loads inventory, balance placeholders, map station markers, and derived alerts.</summary>
    Task<LeaderDashboardSnapshotDto> GetSnapshotAsync(CancellationToken cancellationToken = default);

    Task<IReadOnlyList<NationalInventorySummary>> GetNationalInventorySummariesAsync(
        CancellationToken cancellationToken = default);

    Task<IReadOnlyList<ImportExportSummary>> GetImportExportSummariesAsync(CancellationToken cancellationToken = default);

    Task<IReadOnlyList<BalanceSummary>> GetBalanceSummariesAsync(CancellationToken cancellationToken = default);

    Task<IReadOnlyList<MapInventoryMarker>> GetMapInventoryMarkersAsync(
        int skip,
        int take,
        CancellationToken cancellationToken = default);

    Task<IReadOnlyList<LeaderAlert>> GetAlertsAsync(CancellationToken cancellationToken = default);
}
