namespace Httm.XangDau.Api.Features.Stations.Contracts;

/// <summary>POST <c>/api/stations/{id}/reviews</c> body.</summary>
public sealed record CreateStationReviewRequestDto(
    /// <summary>1–5 inclusive.</summary>
    int Rating,
    string? Comment,
    /// <summary>Optional HTTPS image URLs (max 10).</summary>
    IReadOnlyList<string>? ImageUrls);

public sealed record StationReviewImageDto(int Id, string ImageUrl);

public sealed record StationReviewDto(
    int Id,
    int StationId,
    int Rating,
    string? Comment,
    /// <summary>UTC timestamp.</summary>
    DateTime CreatedAt,
    IReadOnlyList<StationReviewImageDto> Images);

public sealed record StationReviewsPageDto(
    IReadOnlyList<StationReviewDto> Items,
    int TotalCount,
    int Skip,
    int Take);

/// <summary>Star histogram (1–5); zeros included for chart-friendly payloads.</summary>
public sealed record RatingStarBucketDto(byte Stars, int Count);

public sealed record StationRatingSummaryDto(
    int ReviewCount,
    /// <summary><c>null</c> when <see cref="ReviewCount"/> is 0.</summary>
    double? AverageRating,
    IReadOnlyList<RatingStarBucketDto> RatingDistribution);

/// <summary>GET <c>/api/my-reviews</c> — đánh giá do người dùng đã đăng nhập gửi (<c>ReviewerUserId</c> trên <c>StationReviews</c>).</summary>
public sealed record MyStationReviewListItemDto(
    int Id,
    int StationId,
    string StationName,
    int Rating,
    string? Comment,
    DateTime CreatedAt,
    int ImageCount);

public sealed record MyStationReviewsPageDto(
    IReadOnlyList<MyStationReviewListItemDto> Items,
    int TotalCount,
    int Skip,
    int Take);
