namespace Httm.XangDau.Api.Features.Account.Contracts;

/// <summary>GET <c>/api/account/activity-summary</c> — thống kê nhanh tab Tài khoản.</summary>
public sealed record AccountActivitySummaryDto(
    int ReviewsCount,
    int ReportsCount,
    int FuelTransactionsCount);
