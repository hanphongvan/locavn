namespace Httm.XangDau.Api.Features.LeaderAi.Contracts;

/// <summary>
/// 1 series trong biểu đồ AI — Phase 1A chưa render thật, chỉ chuẩn hoá schema để UI mock.
/// </summary>
public sealed record AiChartSeriesDto(
    string Name,
    IReadOnlyList<decimal> Values);

/// <summary>
/// Mô tả biểu đồ trong response của AI (<c>data.chart</c>).
/// </summary>
public sealed record AiChartDataDto(
    string Type,
    string Title,
    IReadOnlyList<string> Categories,
    IReadOnlyList<AiChartSeriesDto> Series);
