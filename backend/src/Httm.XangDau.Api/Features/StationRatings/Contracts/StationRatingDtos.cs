using System.Text.Json.Serialization;

namespace Httm.XangDau.Api.Features.StationRatings.Contracts;

public sealed class CreateStationRatingRequest
{
    public int StationId { get; set; }

    public int Rating { get; set; }

    public string? Comment { get; set; }

    public string? DeviceId { get; set; }

    public List<string>? Images { get; set; }
}

public sealed record StationRatingSummaryDto(int StationId, double AvgRating, int TotalRatings);

public sealed record StationRatingDto(
    int Id,
    int Rating,
    string? Comment,
    DateTime CreatedAt,
    string? CreatedBy,
    IReadOnlyList<string> Images);

/// <summary>Uniform JSON for <c>POST /api/station-ratings</c> success and failure.</summary>
public sealed record CreateStationRatingApiResponse(
    [property: JsonPropertyName("success")] bool Success,
    [property: JsonPropertyName("id")] int? Id,
    [property: JsonPropertyName("message")] string Message);
