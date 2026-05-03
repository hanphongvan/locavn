using Httm.XangDau.Api.Features.StationRatings.Contracts;

namespace Httm.XangDau.Api.Features.StationRatings.Services;

public interface IStationRatingService
{
    Task<CreateStationRatingApiResponse> CreateRatingAsync(
        CreateStationRatingRequest request,
        string? createdBy,
        CancellationToken cancellationToken = default);

    Task<(StationRatingSummaryDto? Data, string? Error)> GetRatingSummaryAsync(
        int stationId,
        CancellationToken cancellationToken = default);

    Task<(IReadOnlyList<StationRatingDto>? Data, string? Error)> GetRatingsByStationAsync(
        int stationId,
        CancellationToken cancellationToken = default);
}
