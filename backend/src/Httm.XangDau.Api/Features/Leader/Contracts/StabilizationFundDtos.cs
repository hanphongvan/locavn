namespace Httm.XangDau.Api.Features.Leader.Contracts;

public sealed record StabilizationFundMonthlyPointDto(int Year, int Month, decimal TotalBalance);

public sealed record StabilizationFundSummaryResponse(
    decimal TotalBalance,
    decimal ChangeFromPreviousMonth,
    int ReportedDistributorCount,
    int NotReportedDistributorCount,
    int AbnormalDistributorCount,
    IReadOnlyList<StabilizationFundMonthlyPointDto> MonthlyTrend,
    int ReportMonth,
    int ReportYear,
    int ReportCutoffDayOfMonth);

public sealed record StabilizationFundDistributorRowDto(
    int DistributorId,
    string DistributorName,
    string? Address,
    decimal? Balance,
    decimal? IncreaseAmount,
    decimal? DecreaseAmount,
    decimal? EndingBalance,
    int ReportMonth,
    int ReportYear,
    string ReportStatus,
    decimal? ChangeFromPreviousMonth,
    string? Note,
    DateTime? UpdatedAt);

public sealed record StabilizationFundDistributorsResponse(IReadOnlyList<StabilizationFundDistributorRowDto> Items);

public sealed record StabilizationFundHistoryRowDto(
    int Month,
    int Year,
    decimal BeginningBalance,
    decimal IncreaseAmount,
    decimal DecreaseAmount,
    decimal EndingBalance);

public sealed record StabilizationFundHistoryResponse(IReadOnlyList<StabilizationFundHistoryRowDto> Items);
