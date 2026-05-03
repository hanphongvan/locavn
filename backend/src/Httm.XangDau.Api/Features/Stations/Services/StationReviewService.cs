using Httm.XangDau.Api.Features.Stations.Contracts;
using Httm.XangDau.Api.Shared.Common;
using Httm.XangDau.Api.Shared.Domain;
using Httm.XangDau.Api.Shared.Persistence;
using Httm.XangDau.Api.Shared.Persistence.Entities;
using Microsoft.EntityFrameworkCore;

namespace Httm.XangDau.Api.Features.Stations.Services;

public sealed class StationReviewService(DmpPortalDbContext db) : IStationReviewService
{
    public async Task<(StationReviewDto? Data, string? Error, bool NotFound)> CreateAsync(
        int stationId,
        CreateStationReviewRequestDto request,
        string? reviewerUserId,
        CancellationToken cancellationToken = default)
    {
        if (stationId <= 0)
            return (null, "stationId must be a positive integer.", false);

        if (!await IsPetrolStationAsync(stationId, cancellationToken))
            return (null, null, true);

        var comment = StationReviewRequestValidator.NormalizeComment(request.Comment);
        var err = StationReviewRequestValidator.ValidateCreate(request.Rating, comment, request.ImageUrls);
        if (err is not null)
            return (null, err, false);

        if (!string.IsNullOrWhiteSpace(reviewerUserId))
        {
            var uid = reviewerUserId.Trim();
            var userExists = await db.AspNetUsers.AsNoTracking()
                .AnyAsync(u => u.Id == uid, cancellationToken);
            if (!userExists)
                return (null, "reviewerUserId is not a valid AspNetUsers.Id.", false);
        }

        var now = VietnamWallClock.Now;
        var review = new StationReview
        {
            ReviewerUserId = string.IsNullOrWhiteSpace(reviewerUserId) ? null : reviewerUserId.Trim(),
            StationId = stationId,
            Rating = (byte)request.Rating,
            Comment = comment,
            CreatedAt = now,
        };

        if (request.ImageUrls is { Count: > 0 })
        {
            foreach (var raw in request.ImageUrls)
            {
                var url = raw.Trim();
                review.Images.Add(new StationReviewImage { ImageUrl = url });
            }
        }

        db.StationReviews.Add(review);
        await db.SaveChangesAsync(cancellationToken);

        var dto = await LoadReviewDtoAsync(review.Id, cancellationToken);
        return (dto, null, false);
    }

    public async Task<(StationReviewsPageDto? Data, string? Error, bool NotFound)> ListAsync(
        int stationId,
        int skip,
        int take,
        CancellationToken cancellationToken = default)
    {
        if (stationId <= 0)
            return (null, "stationId must be a positive integer.", false);

        if (take < 1)
            take = StationReadValidator.DefaultTake;

        var pageErr = StationReviewRequestValidator.ValidateListPagination(skip, take);
        if (pageErr is not null)
            return (null, pageErr, false);

        if (!await IsPetrolStationAsync(stationId, cancellationToken))
            return (null, null, true);

        var total = await db.StationReviews.AsNoTracking()
            .CountAsync(r => r.StationId == stationId, cancellationToken);

        var rows = await db.StationReviews.AsNoTracking()
            .AsSplitQuery()
            .Include(r => r.Images)
            .Where(r => r.StationId == stationId)
            .OrderByDescending(r => r.CreatedAt)
            .ThenByDescending(r => r.Id)
            .Skip(skip)
            .Take(take)
            .ToListAsync(cancellationToken);

        var items = rows.Select(ToDto).ToList();
        return (new StationReviewsPageDto(items, total, skip, take), null, false);
    }

    public async Task<(StationRatingSummaryDto? Data, string? Error, bool NotFound)> GetRatingSummaryAsync(
        int stationId,
        CancellationToken cancellationToken = default)
    {
        if (stationId <= 0)
            return (null, "stationId must be a positive integer.", false);

        if (!await IsPetrolStationAsync(stationId, cancellationToken))
            return (null, null, true);

        var count = await db.StationReviews.AsNoTracking()
            .CountAsync(r => r.StationId == stationId, cancellationToken);

        double? avg = null;
        if (count > 0)
        {
            avg = await db.StationReviews.AsNoTracking()
                .Where(r => r.StationId == stationId)
                .AverageAsync(r => (double)r.Rating, cancellationToken);
            avg = Math.Round(avg.Value, 2, MidpointRounding.AwayFromZero);
        }

        var buckets = new Dictionary<byte, int>();
        if (count > 0)
        {
            var groups = await db.StationReviews.AsNoTracking()
                .Where(r => r.StationId == stationId)
                .GroupBy(r => r.Rating)
                .Select(g => new { Stars = g.Key, C = g.Count() })
                .ToListAsync(cancellationToken);
            foreach (var g in groups)
                buckets[g.Stars] = g.C;
        }

        var distribution = Enumerable.Range(1, 5)
            .Select(s => new RatingStarBucketDto((byte)s, buckets.GetValueOrDefault((byte)s)))
            .ToList();

        return (new StationRatingSummaryDto(count, avg, distribution), null, false);
    }

    public async Task<(MyStationReviewsPageDto? Data, string? Error)> ListMineAsync(
        string reviewerUserId,
        int skip,
        int take,
        CancellationToken cancellationToken = default)
    {
        if (string.IsNullOrWhiteSpace(reviewerUserId))
            return (null, "reviewerUserId is required.");

        var uid = reviewerUserId.Trim();
        if (take < 1)
            take = StationReadValidator.DefaultTake;

        var pageErr = StationReviewRequestValidator.ValidateListPagination(skip, take);
        if (pageErr is not null)
            return (null, pageErr);

        var baseQuery = db.StationReviews.AsNoTracking()
            .Where(r => r.ReviewerUserId == uid);

        var total = await baseQuery.CountAsync(cancellationToken).ConfigureAwait(false);

        var rows = await baseQuery
            .Include(r => r.Images)
            .OrderByDescending(r => r.CreatedAt)
            .ThenByDescending(r => r.Id)
            .Skip(skip)
            .Take(take)
            .ToListAsync(cancellationToken)
            .ConfigureAwait(false);

        var stationIds = rows.Select(r => r.StationId).Distinct().ToList();
        Dictionary<int, string> names = new();
        if (stationIds.Count > 0)
        {
            names = await db.DmDonVis.AsNoTracking()
                .Where(d => stationIds.Contains(d.Id))
                .ToDictionaryAsync(d => d.Id, d => d.Ten, cancellationToken)
                .ConfigureAwait(false);
        }

        var items = rows.Select(r => new MyStationReviewListItemDto(
            r.Id,
            r.StationId,
            names.TryGetValue(r.StationId, out var ten) ? ten : $"Cây xăng #{r.StationId}",
            r.Rating,
            r.Comment,
            r.CreatedAt,
            r.Images.Count)).ToList();

        return (new MyStationReviewsPageDto(items, total, skip, take), null);
    }

    private async Task<bool> IsPetrolStationAsync(int stationId, CancellationToken cancellationToken) =>
        await db.DmDonVis.AsNoTracking()
            .AnyAsync(d => d.Id == stationId && d.CapDonViId == PetrolRetailConstants.CapDonViId, cancellationToken);

    private async Task<StationReviewDto?> LoadReviewDtoAsync(int reviewId, CancellationToken cancellationToken)
    {
        var row = await db.StationReviews.AsNoTracking()
            .Include(r => r.Images)
            .FirstOrDefaultAsync(r => r.Id == reviewId, cancellationToken);
        return row is null ? null : ToDto(row);
    }

    private static StationReviewDto ToDto(StationReview r) =>
        new(
            r.Id,
            r.StationId,
            r.Rating,
            r.Comment,
            r.CreatedAt,
            r.Images
                .OrderBy(i => i.Id)
                .Select(i => new StationReviewImageDto(i.Id, i.ImageUrl))
                .ToList());
}
