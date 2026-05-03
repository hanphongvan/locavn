namespace Httm.XangDau.Api.Features.StationRatings.Services;

/// <summary>
/// Placeholder for future multipart rating-image upload to disk/blob.
/// API v1 persists only validated relative paths supplied in <see cref="Contracts.CreateStationRatingRequest.Images"/>.
/// </summary>
public interface IStationRatingImageUploadService
{
    /// <summary>Returns a stored relative path, or <c>null</c> when upload is not configured (default).</summary>
    ValueTask<string?> SaveRatingImageFromStreamAsync(
        Stream fileStream,
        string originalFileName,
        CancellationToken cancellationToken = default);
}
