using Httm.XangDau.Api.Features.Reports.Contracts;

namespace Httm.XangDau.Api.Features.Reports.Services;

public interface IReportsOverviewReadService
{
    Task<ReportsOverviewDto> GetOverviewAsync(CancellationToken cancellationToken = default);
}
