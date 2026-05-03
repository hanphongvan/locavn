using Httm.XangDau.Api.Features.BadReports.Contracts;

namespace Httm.XangDau.Api.Features.BadReports.Services;

public interface IBadReportService
{
    Task<(CreateBadReportResponseDto? Data, string? Error)> SubmitAsync(
        CreateBadReportRequestDto request,
        string? reporterUserId,
        CancellationToken cancellationToken = default);

    Task<(AdminBadReportPageDto? Data, string? Error)> ListForAdminAsync(
        int skip,
        int take,
        CancellationToken cancellationToken = default);

    Task<(AdminBadReportDetailDto? Data, string? Error, bool NotFound)> GetForAdminAsync(
        int id,
        CancellationToken cancellationToken = default);

    Task<(MyBadReportPageDto? Data, string? Error)> ListMineAsync(
        string reporterUserId,
        int skip,
        int take,
        CancellationToken cancellationToken = default);
}
