using Httm.XangDau.Api.Features.Leader.Contracts;

namespace Httm.XangDau.Api.Features.Leader.Persistence;

public interface ILeaderStabilizationFundDataAccess
{
    Task<StabilizationFundSummaryResponse> GetSummaryAsync(
        int month,
        int year,
        int reportCutoffDayOfMonth,
        CancellationToken cancellationToken = default);

    Task<IReadOnlyList<StabilizationFundDistributorRowDto>> GetDistributorsAsync(
        int month,
        int year,
        CancellationToken cancellationToken = default);

    Task<IReadOnlyList<StabilizationFundHistoryRowDto>> GetDistributorHistoryAsync(
        int distributorId,
        int endMonth,
        int endYear,
        CancellationToken cancellationToken = default);
}
