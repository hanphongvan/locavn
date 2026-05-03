using System.Data.Common;
using Httm.XangDau.Api.Features.StationRatings.Contracts;
using Httm.XangDau.Api.Features.StationRatings.Persistence;
using Microsoft.Data.SqlClient;

namespace Httm.XangDau.Api.Features.StationRatings.Services;

public sealed class StationRatingService(IStationRatingDataAccess data) : IStationRatingService
{
    private const int MaxImagesPerRating = 5;
    private const int MaxCommentLength = 500;

    /// <inheritdoc />
    public async Task<CreateStationRatingApiResponse> CreateRatingAsync(
        CreateStationRatingRequest request,
        string? createdBy,
        CancellationToken cancellationToken = default)
    {
        if (request.StationId <= 0)
            return new CreateStationRatingApiResponse(false, null, "Mã cây xăng không hợp lệ.");

        if (request.Rating is < 1 or > 5)
            return new CreateStationRatingApiResponse(false, null, "Điểm đánh giá phải từ 1 đến 5.");

        var comment = request.Comment?.Trim();
        if (comment is { Length: > MaxCommentLength })
            return new CreateStationRatingApiResponse(false, null, "Nội dung bình luận không được vượt quá 500 ký tự.");

        var deviceId = string.IsNullOrWhiteSpace(request.DeviceId) ? null : request.DeviceId.Trim();
        if (deviceId is { Length: > 100 })
            return new CreateStationRatingApiResponse(false, null, "Mã thiết bị không được vượt quá 100 ký tự.");

        var createdByTrim = string.IsNullOrWhiteSpace(createdBy) ? null : createdBy.Trim();
        if (createdByTrim is { Length: > 100 })
            createdByTrim = createdByTrim[..100];

        var images = request.Images ?? new List<string>();
        if (images.Count > MaxImagesPerRating)
            return new CreateStationRatingApiResponse(false, null, "Mỗi đánh giá chỉ được gửi tối đa 5 ảnh.");

        var normalizedUrls = new List<string>(images.Count);
        foreach (var raw in images)
        {
            if (raw is null)
                return new CreateStationRatingApiResponse(false, null, "Đường dẫn ảnh không hợp lệ.");

            var pathErr = StationRatingImagePathRules.ValidateImageUrl(raw);
            if (pathErr is not null)
                return new CreateStationRatingApiResponse(false, null, pathErr);
            normalizedUrls.Add(raw.Trim());
        }

        try
        {
            var (ratingId, err) = await data
                .InsertRatingWithImagesAsync(
                    request.StationId,
                    request.Rating,
                    string.IsNullOrEmpty(comment) ? null : comment,
                    deviceId,
                    createdByTrim,
                    normalizedUrls,
                    cancellationToken)
                .ConfigureAwait(false);

            if (ratingId is null)
                return new CreateStationRatingApiResponse(false, null, err ?? "Không thể lưu đánh giá.");

            return new CreateStationRatingApiResponse(true, ratingId, "Cảm ơn bạn đã đánh giá");
        }
        catch (SqlException)
        {
            return new CreateStationRatingApiResponse(false, null, "Đã xảy ra lỗi khi lưu đánh giá. Vui lòng thử lại sau.");
        }
        catch (DbException)
        {
            return new CreateStationRatingApiResponse(false, null, "Đã xảy ra lỗi khi lưu đánh giá. Vui lòng thử lại sau.");
        }
    }

    /// <inheritdoc />
    public async Task<(StationRatingSummaryDto? Data, string? Error)> GetRatingSummaryAsync(
        int stationId,
        CancellationToken cancellationToken = default)
    {
        if (stationId <= 0)
            return (null, "Mã cây xăng không hợp lệ.");

        try
        {
            var dto = await data.GetSummaryAsync(stationId, cancellationToken).ConfigureAwait(false);
            return (dto, null);
        }
        catch (SqlException)
        {
            return (null, "Không thể tải tóm tắt đánh giá.");
        }
        catch (DbException)
        {
            return (null, "Không thể tải tóm tắt đánh giá.");
        }
    }

    /// <inheritdoc />
    public async Task<(IReadOnlyList<StationRatingDto>? Data, string? Error)> GetRatingsByStationAsync(
        int stationId,
        CancellationToken cancellationToken = default)
    {
        if (stationId <= 0)
            return (null, "Mã cây xăng không hợp lệ.");

        try
        {
            var list = await data.GetByStationAsync(stationId, cancellationToken).ConfigureAwait(false);
            return (list, null);
        }
        catch (SqlException)
        {
            return (null, "Không thể tải danh sách đánh giá.");
        }
        catch (DbException)
        {
            return (null, "Không thể tải danh sách đánh giá.");
        }
    }
}
