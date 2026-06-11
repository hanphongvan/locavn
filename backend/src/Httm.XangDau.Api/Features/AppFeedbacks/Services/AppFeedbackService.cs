using Httm.XangDau.Api.Features.AppFeedbacks.Contracts;
using Httm.XangDau.Api.Shared.Common;
using Httm.XangDau.Api.Shared.Persistence;
using Httm.XangDau.Api.Shared.Persistence.Entities;
using Microsoft.EntityFrameworkCore;

namespace Httm.XangDau.Api.Features.AppFeedbacks.Services;

public sealed class AppFeedbackService(DmpPortalDbContext db) : IAppFeedbackService
{
    public async Task<(CreateAppFeedbackResponseDto? Data, string? Error)> SubmitAsync(
        CreateAppFeedbackRequestDto request,
        string? userId,
        CancellationToken cancellationToken = default)
    {
        var err = AppFeedbackRequestValidator.ValidateSubmit(
            request.Category,
            request.Content,
            request.ContactEmail,
            request.ContactPhone,
            request.ImageUrls);
        if (err is not null)
            return (null, err);

        if (!string.IsNullOrWhiteSpace(userId))
        {
            var userExists = await db.AspNetUsers.AsNoTracking()
                .AnyAsync(u => u.Id == userId, cancellationToken);
            if (!userExists)
                userId = null; // token hợp lệ nhưng user không còn → coi như ẩn danh, không chặn góp ý.
        }

        var now = VietnamWallClock.Now;
        var feedback = new AppFeedback
        {
            UserId = string.IsNullOrWhiteSpace(userId) ? null : userId.Trim(),
            Category = request.Category,
            Content = request.Content.Trim(),
            ContactEmail = NullIfBlank(request.ContactEmail),
            ContactPhone = NullIfBlank(request.ContactPhone),
            AppVersion = NullIfBlank(request.AppVersion),
            Platform = NullIfBlank(request.Platform),
            CreatedAt = now,
            Status = AppFeedbackStatus.Pending,
        };

        if (request.ImageUrls is { Count: > 0 })
        {
            foreach (var raw in request.ImageUrls)
                feedback.Images.Add(new AppFeedbackImage { ImageUrl = raw.Trim() });
        }

        db.AppFeedbacks.Add(feedback);
        await db.SaveChangesAsync(cancellationToken);

        return (new CreateAppFeedbackResponseDto(feedback.Id, feedback.CreatedAt), null);
    }

    public async Task<(AdminAppFeedbackPageDto? Data, string? Error)> ListForAdminAsync(
        int skip,
        int take,
        CancellationToken cancellationToken = default)
    {
        if (take < 1)
            take = AppFeedbackRequestValidator.DefaultTake;

        var pageErr = AppFeedbackRequestValidator.ValidateListPagination(skip, take);
        if (pageErr is not null)
            return (null, pageErr);

        var total = await db.AppFeedbacks.AsNoTracking().CountAsync(cancellationToken);

        var rows = await db.AppFeedbacks.AsNoTracking()
            .Include(f => f.Images)
            .OrderByDescending(f => f.CreatedAt)
            .ThenByDescending(f => f.Id)
            .Skip(skip)
            .Take(take)
            .ToListAsync(cancellationToken);

        var items = rows.Select(f => new AdminAppFeedbackListItemDto(
            f.Id,
            f.Category,
            f.Content,
            f.ContactEmail,
            f.ContactPhone,
            f.AppVersion,
            f.Platform,
            f.UserId != null,
            f.CreatedAt,
            f.Status,
            f.Images.Count)).ToList();

        return (new AdminAppFeedbackPageDto(items, total, skip, take), null);
    }

    public async Task<(AdminAppFeedbackDetailDto? Data, string? Error, bool NotFound)> GetForAdminAsync(
        int id,
        CancellationToken cancellationToken = default)
    {
        if (id <= 0)
            return (null, "id must be a positive integer.", false);

        var row = await db.AppFeedbacks.AsNoTracking()
            .Include(f => f.Images)
            .FirstOrDefaultAsync(f => f.Id == id, cancellationToken);

        if (row is null)
            return (null, null, true);

        var images = row.Images
            .OrderBy(i => i.Id)
            .Select(i => new AppFeedbackImageDto(i.Id, i.ImageUrl))
            .ToList();

        return (new AdminAppFeedbackDetailDto(
            row.Id,
            row.Category,
            row.Content,
            row.ContactEmail,
            row.ContactPhone,
            row.AppVersion,
            row.Platform,
            row.UserId,
            row.CreatedAt,
            row.Status,
            images), null, false);
    }

    private static string? NullIfBlank(string? s) => string.IsNullOrWhiteSpace(s) ? null : s.Trim();
}
