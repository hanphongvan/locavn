using Httm.XangDau.Api.Features.BadReports.Contracts;
using Httm.XangDau.Api.Shared.Common;
using Httm.XangDau.Api.Shared.Domain;
using Httm.XangDau.Api.Shared.Persistence;
using Httm.XangDau.Api.Shared.Persistence.Entities;
using Microsoft.EntityFrameworkCore;

namespace Httm.XangDau.Api.Features.BadReports.Services;

public sealed class BadReportService(DmpPortalDbContext db) : IBadReportService
{
    public async Task<(CreateBadReportResponseDto? Data, string? Error)> SubmitAsync(
        CreateBadReportRequestDto request,
        string? reporterUserId,
        CancellationToken cancellationToken = default)
    {
        var err = BadReportRequestValidator.ValidateSubmit(request.StationId, request.Content, request.ImageUrls);
        if (err is not null)
            return (null, err);

        var content = request.Content.Trim();
        int? stationId = request.StationId;
        if (stationId is { } sid)
        {
            var ok = await db.DmDonVis.AsNoTracking()
                .AnyAsync(d => d.Id == sid && d.CapDonViId == PetrolRetailConstants.CapDonViId, cancellationToken);
            if (!ok)
                return (null, "stationId does not reference a petrol retail unit (CapDonViId = 248).");
        }

        if (!string.IsNullOrWhiteSpace(reporterUserId))
        {
            var userExists = await db.AspNetUsers.AsNoTracking()
                .AnyAsync(u => u.Id == reporterUserId, cancellationToken);
            if (!userExists)
                return (null, "reporterUserId is not a valid AspNetUsers.Id.");
        }

        var now = VietnamWallClock.Now;
        var report = new StationBadReport
        {
            ReporterUserId = string.IsNullOrWhiteSpace(reporterUserId) ? null : reporterUserId.Trim(),
            StationId = stationId,
            Content = content,
            CreatedAt = now,
            Status = StationBadReportStatus.Pending,
        };

        if (request.ImageUrls is { Count: > 0 })
        {
            foreach (var raw in request.ImageUrls)
                report.Images.Add(new StationBadReportImage { ImageUrl = raw.Trim() });
        }

        db.StationBadReports.Add(report);
        await db.SaveChangesAsync(cancellationToken);

        return (new CreateBadReportResponseDto(report.Id, report.CreatedAt), null);
    }

    public async Task<(AdminBadReportPageDto? Data, string? Error)> ListForAdminAsync(
        int skip,
        int take,
        CancellationToken cancellationToken = default)
    {
        if (take < 1)
            take = BadReportRequestValidator.DefaultTake;

        var pageErr = BadReportRequestValidator.ValidateListPagination(skip, take);
        if (pageErr is not null)
            return (null, pageErr);

        var total = await db.StationBadReports.AsNoTracking().CountAsync(cancellationToken);

        var rows = await db.StationBadReports.AsNoTracking()
            .Include(r => r.Images)
            .OrderByDescending(r => r.CreatedAt)
            .ThenByDescending(r => r.Id)
            .Skip(skip)
            .Take(take)
            .ToListAsync(cancellationToken);

        var items = rows.Select(r => new AdminBadReportListItemDto(
            r.Id,
            r.StationId,
            r.Content,
            r.CreatedAt,
            r.Status,
            r.Images.Count)).ToList();

        return (new AdminBadReportPageDto(items, total, skip, take), null);
    }

    public async Task<(AdminBadReportDetailDto? Data, string? Error, bool NotFound)> GetForAdminAsync(
        int id,
        CancellationToken cancellationToken = default)
    {
        if (id <= 0)
            return (null, "id must be a positive integer.", false);

        var row = await db.StationBadReports.AsNoTracking()
            .Include(r => r.Images)
            .FirstOrDefaultAsync(r => r.Id == id, cancellationToken);

        if (row is null)
            return (null, null, true);

        var images = row.Images
            .OrderBy(i => i.Id)
            .Select(i => new BadReportImageDto(i.Id, i.ImageUrl))
            .ToList();

        return (new AdminBadReportDetailDto(
            row.Id,
            row.StationId,
            row.Content,
            row.CreatedAt,
            row.Status,
            images), null, false);
    }

    public async Task<(MyBadReportPageDto? Data, string? Error)> ListMineAsync(
        string reporterUserId,
        int skip,
        int take,
        CancellationToken cancellationToken = default)
    {
        if (string.IsNullOrWhiteSpace(reporterUserId))
            return (null, "reporterUserId is required.");

        var uid = reporterUserId.Trim();
        if (take < 1)
            take = BadReportRequestValidator.DefaultTake;

        var pageErr = BadReportRequestValidator.ValidateListPagination(skip, take);
        if (pageErr is not null)
            return (null, pageErr);

        var baseQuery = db.StationBadReports.AsNoTracking()
            .Where(r => r.ReporterUserId == uid);

        var total = await baseQuery.CountAsync(cancellationToken);

        var rows = await baseQuery
            .Include(r => r.Images)
            .OrderByDescending(r => r.CreatedAt)
            .ThenByDescending(r => r.Id)
            .Skip(skip)
            .Take(take)
            .ToListAsync(cancellationToken);

        var stationIds = rows.Where(r => r.StationId is { } sid).Select(r => r.StationId!.Value).Distinct().ToList();
        Dictionary<int, string> stationNames = new();
        if (stationIds.Count > 0)
        {
            stationNames = await db.DmDonVis.AsNoTracking()
                .Where(d => stationIds.Contains(d.Id))
                .ToDictionaryAsync(d => d.Id, d => d.Ten, cancellationToken);
        }

        var items = rows.Select(r => new MyBadReportListItemDto(
            r.Id,
            r.StationId,
            r.StationId is { } sid2 && stationNames.TryGetValue(sid2, out var ten) ? ten : null,
            r.Content,
            r.CreatedAt,
            r.Status,
            r.Images.Count)).ToList();

        return (new MyBadReportPageDto(items, total, skip, take), null);
    }
}
