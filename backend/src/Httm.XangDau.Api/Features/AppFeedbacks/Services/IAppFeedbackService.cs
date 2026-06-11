using Httm.XangDau.Api.Features.AppFeedbacks.Contracts;

namespace Httm.XangDau.Api.Features.AppFeedbacks.Services;

public interface IAppFeedbackService
{
    Task<(CreateAppFeedbackResponseDto? Data, string? Error)> SubmitAsync(
        CreateAppFeedbackRequestDto request,
        string? userId,
        CancellationToken cancellationToken = default);

    Task<(AdminAppFeedbackPageDto? Data, string? Error)> ListForAdminAsync(
        int skip,
        int take,
        CancellationToken cancellationToken = default);

    Task<(AdminAppFeedbackDetailDto? Data, string? Error, bool NotFound)> GetForAdminAsync(
        int id,
        CancellationToken cancellationToken = default);
}
