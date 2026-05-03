namespace Httm.XangDau.Api.Features.StationRatings.Services;

/// <inheritdoc />
public sealed class StationRatingImageUploadPlaceholder : IStationRatingImageUploadService
{
    /// <inheritdoc />
    public ValueTask<string?> SaveRatingImageFromStreamAsync(
        Stream fileStream,
        string originalFileName,
        CancellationToken cancellationToken = default) =>
        ValueTask.FromResult<string?>(null);
}
