using Microsoft.AspNetCore.Http;

namespace Httm.XangDau.Api.Features.BadReports.Services;

/// <summary>Saves a validated image for bad reports and returns an absolute URL clients can pass to <c>POST /api/bad-reports</c> as <c>imageUrls</c>.</summary>
public interface IBadReportImageUploadService
{
    Task<(string? AbsoluteUrl, string? Error)> SaveAsync(
        IFormFile file,
        HttpRequest request,
        CancellationToken cancellationToken = default);
}
