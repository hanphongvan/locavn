using Microsoft.AspNetCore.Http;

namespace Httm.XangDau.Api.Features.AppFeedbacks.Services;

public interface IAppFeedbackImageUploadService
{
    Task<(string? AbsoluteUrl, string? Error)> SaveAsync(
        IFormFile file,
        HttpRequest request,
        CancellationToken cancellationToken = default);
}
