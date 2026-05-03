using Httm.XangDau.Api.Features.StationRatings.Contracts;

namespace Httm.XangDau.Api.Features.StationRatings.Persistence;

public interface IStationRatingDataAccess
{
    Task<(int? RatingId, string? ErrorMessage)> InsertRatingWithImagesAsync(
        int stationId,
        int rating,
        string? comment,
        string? deviceId,
        string? createdBy,
        IReadOnlyList<string> imageUrls,
        CancellationToken cancellationToken = default);

    Task<StationRatingSummaryDto> GetSummaryAsync(int stationId, CancellationToken cancellationToken = default);

    Task<IReadOnlyList<StationRatingDto>> GetByStationAsync(int stationId, CancellationToken cancellationToken = default);
}
