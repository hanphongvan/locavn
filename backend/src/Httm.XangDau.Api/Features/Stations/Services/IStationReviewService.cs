using Httm.XangDau.Api.Features.Stations.Contracts;

namespace Httm.XangDau.Api.Features.Stations.Services;

public interface IStationReviewService
{
    /// <returns>Error: not a petrol station / missing → treat as 404; validation → 400.</returns>
    Task<(StationReviewDto? Data, string? Error, bool NotFound)> CreateAsync(
        int stationId,
        CreateStationReviewRequestDto request,
        string? reviewerUserId,
        CancellationToken cancellationToken = default);

    Task<(StationReviewsPageDto? Data, string? Error, bool NotFound)> ListAsync(
        int stationId,
        int skip,
        int take,
        CancellationToken cancellationToken = default);

    Task<(StationRatingSummaryDto? Data, string? Error, bool NotFound)> GetRatingSummaryAsync(
        int stationId,
        CancellationToken cancellationToken = default);

    Task<(MyStationReviewsPageDto? Data, string? Error)> ListMineAsync(
        string reviewerUserId,
        int skip,
        int take,
        CancellationToken cancellationToken = default);
}
